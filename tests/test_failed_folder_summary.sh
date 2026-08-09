#!/usr/bin/env bash

set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/music/invalid one" "$tmp/music/invalid two"
touch "$tmp/music/invalid one/unknown.mp3"
touch "$tmp/music/invalid two/also unknown.mp3"

cat >"$tmp/bin/exiftool" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/exiftool"

set +e
output=$(PATH="$tmp/bin:$PATH" "$repo/mp3trackprefix" --dry-run "$tmp/music" 2>&1)
status=$?
set -e

[[ $status -eq 1 ]]
[[ $output == *'Folders not processed correctly:'* ]]
[[ $output == *"  $tmp/music/invalid one"* ]]
[[ $output == *"  $tmp/music/invalid two"* ]]
[[ $(grep -Fxc "  $tmp/music/invalid one" <<<"$output") -eq 1 ]]
[[ $(grep -Fxc "  $tmp/music/invalid two" <<<"$output") -eq 1 ]]

printf 'failed folder summary tests passed\n'

# A fatal write failure must still produce the summary and must not prevent a
# later folder from being processed.
rm -rf "$tmp/music"
mkdir -p "$tmp/music/bad write" "$tmp/music/good write"
touch "$tmp/music/bad write/01 Song.mp3" "$tmp/music/good write/01 Song.mp3"
cat >"$tmp/bin/exiftool" <<'EOF'
#!/usr/bin/env bash
for arg; do
    case $arg in
        -Track) printf '1\n'; exit 0 ;;
        -Title) printf 'Song\n'; exit 0 ;;
        -Title=*)
            [[ ${!#} != *'/bad write/'* ]]
            exit
            ;;
    esac
done
exit 0
EOF
chmod +x "$tmp/bin/exiftool"

set +e
output=$(PATH="$tmp/bin:$PATH" "$repo/mp3trackprefix" "$tmp/music" 2>&1)
status=$?
set -e

[[ $status -eq 2 ]]
[[ $output == *"[ERROR] Failed to write TITLE: $tmp/music/bad write/01 Song.mp3"* ]]
[[ $output == *"[CHANGED] $tmp/music/good write"* ]]
[[ $output == *$'Folders not processed correctly:\n'"  $tmp/music/bad write"* ]]
[[ $output != *"  $tmp/music/good write"* ]]

printf 'write failure summary tests passed\n'
