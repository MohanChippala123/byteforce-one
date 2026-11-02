#!/usr/bin/env bash

set -x
set -uo pipefail

EXTENSIONS=("mp3" "flac" "wav" "ogg" "mp4" "mkv" "avi" "webm" "iso" "appimage" "rom")
CATEGORIES=("Game" "AudioVideo" "Media" "Audio" "Video")

echo "by Extension: "
for ext in "${EXTENSIONS[@]}"; do
    echo "Extension: .$ext"
    find ~ -type f -iname "*.$ext" 2>/dev/null
done

echo ""
echo "by Category: "
for cat in "${CATEGORIES[@]}"; do
    echo "Category: $cat"
    grep -rnw -e "Categories=.*$cat" /usr/share/applications ~/.local/share/applications /var/lib/snapd/desktop/applications /var/lib/flatpak/exports/share/applications 2>/dev/null | cut -d: -f1 | sort -u
done