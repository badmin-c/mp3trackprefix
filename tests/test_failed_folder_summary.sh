#!/usr/bin/env bash

set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/music/invalid one" "$tmp/music/invalid two"
touch "$tmp/music/invalid one/unknown.mp3"
touch "$tmp/music/invalid two/also unknown.mp3"

cat >"$tmp/bin/ffprobe" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/ffprobe"
cat >"$tmp/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/ffmpeg"

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
cat >"$tmp/bin/ffprobe" <<'EOF'
#!/usr/bin/env bash
[[ $* == *format_tags=Track* ]] && printf '1\n'
[[ $* == *format_tags=Title* ]] && printf 'Song\n'
exit 0
EOF
chmod +x "$tmp/bin/ffprobe"
cat >"$tmp/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
input=
while (($#)); do
    if [[ $1 == -i ]]; then input=$2; shift; fi
    output=$1
    shift
done
[[ $input != *'/bad write/'* ]] || exit 1
: >"$output"
EOF
chmod +x "$tmp/bin/ffmpeg"

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
