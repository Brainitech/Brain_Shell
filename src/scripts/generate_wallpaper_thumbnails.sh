#!/usr/bin/env bash
#
# Brain Shell
# Copyright (C) 2026 Venkat Saahit Kamu (Brainitech)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

WALL_DIR="${1:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${2:-$HOME/.cache/Brain_Shell/thumbnails}"

# Expand tilde if passed literally
WALL_DIR="${WALL_DIR/#\~/$HOME}"
CACHE_DIR="${CACHE_DIR/#\~/$HOME}"

[ -d "$WALL_DIR" ] || exit 0
mkdir -p "$CACHE_DIR"

command -v magick >/dev/null 2>&1 || exit 0

export CACHE_DIR

generate_thumbnail() {
    local file="$1"
    [ -f "$file" ] || return 0

    local hash
    hash=$(printf '%s' "$file" | md5sum | cut -d' ' -f1)
    local thumb="$CACHE_DIR/${hash}.jpg"

    if [ ! -f "$thumb" ] || [ "$file" -nt "$thumb" ]; then
        local target="$file"
        if [[ "$file" == *.gif || "$file" == *.GIF ]]; then
            target="${file}[0]"
        fi
        magick "$target" -thumbnail "x720>" -quality 92 "$thumb" 2>/dev/null || true
    fi
}
export -f generate_thumbnail

find "$WALL_DIR" -maxdepth 1 -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o \
    -iname '*.gif' -o -iname '*.webp' \
\) -print0 | xargs -0 -n 1 -P 4 bash -c 'generate_thumbnail "$@"' _ 2>/dev/null || true
