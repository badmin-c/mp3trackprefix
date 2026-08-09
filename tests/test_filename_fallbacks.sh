#!/usr/bin/env bash

set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/music/dotted" "$tmp/music/bracketed"
touch "$tmp/music/dotted/01. Gang Starr - You know my steez.mp3"
touch "$tmp/music/bracketed/Pantera - The Great Southern Trendkill - [01] - The Great Southern Trendkill.mp3"

cat >"$tmp/bin/exiftool" <<'EOF'
#!/usr/bin/env bash
# The fixtures intentionally have no tags, exercising filename-only fallback.
exit 0
EOF
chmod +x "$tmp/bin/exiftool"

output=$(PATH="$tmp/bin:$PATH" "$repo/mp3trackprefix" --dry-run "$tmp/music")

[[ $output == *'[DRY-RUN] 01. Gang Starr - You know my steez.mp3'* ]]
[[ $output == *'->    "01 Gang Starr - You know my steez"'* ]]
[[ $output == *'[DRY-RUN] Pantera - The Great Southern Trendkill - [01] - The Great Southern Trendkill.mp3'* ]]
[[ $output == *'->    "01 The Great Southern Trendkill"'* ]]
[[ $output != *'Missing track number:'* ]]
[[ $output == *'Warnings: 0'* ]]
[[ $output != *'Folders not processed correctly:'* ]]

printf 'filename fallback tests passed\n'
