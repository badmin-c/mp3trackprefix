#!/usr/bin/env bash

set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/music/dotted" "$tmp/music/bracketed" \
    "$tmp/music/artist-track-title" "$tmp/music/track-suffix" "$tmp/music/compact-prefix"
touch "$tmp/music/dotted/01. Gang Starr - You know my steez.mp3"
touch "$tmp/music/bracketed/Pantera - The Great Southern Trendkill - [01] - The Great Southern Trendkill.mp3"
touch "$tmp/music/artist-track-title/Slipknot - 01 - 515.mp3"
touch "$tmp/music/track-suffix/Soul4Ya - Track 01.mp3"
touch "$tmp/music/compact-prefix/01-A Tribe Called Quest-Phony Rappers.mp3"

cat >"$tmp/bin/ffprobe" <<'EOF'
#!/usr/bin/env bash
# The fixtures intentionally have no tags, exercising filename-only fallback.
exit 0
EOF
chmod +x "$tmp/bin/ffprobe"
cat >"$tmp/bin/ffmpeg" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/ffmpeg"

output=$(PATH="$tmp/bin:$PATH" "$repo/mp3trackprefix" --dry-run "$tmp/music")

[[ $output == *'[DRY-RUN] 01. Gang Starr - You know my steez.mp3'* ]]
[[ $output == *'->    "01 Gang Starr - You know my steez"'* ]]
[[ $output == *'[DRY-RUN] Pantera - The Great Southern Trendkill - [01] - The Great Southern Trendkill.mp3'* ]]
[[ $output == *'->    "01 The Great Southern Trendkill"'* ]]
[[ $output == *'[DRY-RUN] Slipknot - 01 - 515.mp3'* ]]
[[ $output == *'->    "01 515"'* ]]
[[ $output == *'[DRY-RUN] Soul4Ya - Track 01.mp3'* ]]
[[ $output == *'->    "01 Soul4Ya"'* ]]
[[ $output == *'[DRY-RUN] 01-A Tribe Called Quest-Phony Rappers.mp3'* ]]
[[ $output == *'->    "01 A Tribe Called Quest-Phony Rappers"'* ]]
[[ $output != *'Missing track number:'* ]]
[[ $output == *'Warnings: 0'* ]]
[[ $output != *'Folders not processed correctly:'* ]]

printf 'filename fallback tests passed\n'
