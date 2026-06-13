#!/usr/bin/env python3
"""
Batch thumbnail generator for Brain_Shell wallpapers.
Scans a directory (recursively) and generates thumbnails for
images, videos, and GIFs into a cache directory.

Improvements over original:
- Smart caching: only regenerates if source file is newer than thumbnail (mtime)
- Proxy directory structure mirrors wallpaper layout
- ImageMagick v7/v6 auto-detection
- Better quality with crop (PreserveAspectCrop equivalent)

Usage: python3 thumbgen_batch.py <wallpaper_dir> [--cache <dir>] [--size 200]
Output: JSON list of {original, thumbnail} objects
"""
import os
import sys
import json
import hashlib
import subprocess
import shutil
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

# ── Config ────────────────────────────────────────────────────────────────────
THUMBNAIL_SIZE = 200
MAX_WORKERS = 4
VIDEO_EXTS  = {'.mp4', '.webm', '.mkv', '.mov', '.avi'}
IMAGE_EXTS  = {'.jpg', '.jpeg', '.png', '.webp', '.tif', '.tiff', '.bmp'}
GIF_EXTS    = {'.gif'}

# ── Helpers ───────────────────────────────────────────────────────────────────
def file_hash(filepath):
    """Short stable hash of the absolute path."""
    return hashlib.md5(os.path.abspath(filepath).encode()).hexdigest()[:12]

def which(cmd):
    return shutil.which(cmd) is not None

_imagemagick_v7 = None

def is_imagemagick_v7():
    """Detect ImageMagick v7 (magick) vs v6 (convert). Cached."""
    global _imagemagick_v7
    if _imagemagick_v7 is not None:
        return _imagemagick_v7
    try:
        result = subprocess.run(["magick", "--version"], capture_output=True, text=True, timeout=5)
        _imagemagick_v7 = result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        _imagemagick_v7 = False
    return _imagemagick_v7

def generate_one(inp, out, size):
    """Generate a single thumbnail. Returns True on success."""
    ext = os.path.splitext(inp)[1].lower()
    is_video = ext in VIDEO_EXTS
    is_gif   = ext in GIF_EXTS

    try:
        if is_video:
            # Seek to 0.1s to avoid black frames, use crop for consistent aspect
            cmd = [
                "ffmpeg", "-y", "-ss", "00:00:00.100", "-i", inp,
                "-vframes", "1",
                "-vf", f"scale={size}:{size}:force_original_aspect_ratio=increase,"
                        f"crop={size}:{size}",
                "-q:v", "2", "-f", "image2", out
            ]
        elif is_gif:
            cmd = [
                "ffmpeg", "-y", "-i", inp,
                "-vframes", "1",
                "-vf", f"scale={size}:{size}:force_original_aspect_ratio=increase,"
                        f"crop={size}:{size}",
                "-q:v", "2", "-f", "image2", out
            ]
        else:
            if is_imagemagick_v7():
                cmd = ["magick", inp, "-resize", f"{size}x{size}^",
                       "-gravity", "center", "-extent", f"{size}x{size}",
                       "-quality", "80", "-strip", out]
            elif which("convert"):
                cmd = ["convert", inp, "-resize", f"{size}x{size}^",
                       "-gravity", "center", "-extent", f"{size}x{size}",
                       "-quality", "80", "-strip", out]
            else:
                cmd = [
                    "ffmpeg", "-y", "-i", inp,
                    "-vf", f"scale={size}:{size}:force_original_aspect_ratio=increase,"
                            f"crop={size}:{size}",
                    "-q:v", "2", "-f", "image2", out
                ]

        subprocess.run(cmd, capture_output=True, timeout=30)
        return os.path.exists(out) and os.path.getsize(out) > 0
    except Exception:
        return False

def needs_thumbnail(src_path, thumb_path):
    """Check if thumbnail needs regeneration based on mtime."""
    if not thumb_path.exists():
        return True
    try:
        src_mtime = os.path.getmtime(str(src_path))
        thumb_mtime = os.path.getmtime(str(thumb_path))
        return src_mtime > thumb_mtime
    except OSError:
        return True

# ── Main ──────────────────────────────────────────────────────────────────────
def scan_dir(root_dir):
    """Recursively find all supported media files, excluding hidden folders."""
    root = Path(root_dir).expanduser().resolve()
    if not root.exists():
        print(json.dumps({"error": f"Directory not found: {root_dir}"}))
        sys.exit(1)

    files = []
    for ext in IMAGE_EXTS | VIDEO_EXTS | GIF_EXTS:
        for f in root.rglob(f"*{ext}"):
            # Skip hidden folders
            rel = f.relative_to(root)
            if any(part.startswith(".") for part in rel.parts[:-1]):
                continue
            files.append(str(f))
        for f in root.rglob(f"*{ext.upper()}"):
            rel = f.relative_to(root)
            if any(part.startswith(".") for part in rel.parts[:-1]):
                continue
            files.append(str(f))

    return sorted(set(files))

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("wallpaper_dir")
    ap.add_argument("--cache", default=os.path.expanduser("~/.cache/Brain_Shell/thumbnails"))
    ap.add_argument("--size", type=int, default=THUMBNAIL_SIZE)
    ap.add_argument("--workers", type=int, default=MAX_WORKERS)
    args = ap.parse_args()

    cache_dir = Path(args.cache)
    cache_dir.mkdir(parents=True, exist_ok=True)

    files = scan_dir(args.wallpaper_dir)
    if not files:
        print(json.dumps([]))
        return

    # Build work list: (input_path, output_path)
    # Only generate thumbnails that are missing or outdated
    work = []
    for f in files:
        thumb_name = file_hash(f) + ".jpg"
        thumb_path = cache_dir / thumb_name
        if needs_thumbnail(f, thumb_path):
            work.append((f, str(thumb_path)))

    # Generate missing/outdated thumbnails in parallel
    lock = threading.Lock()
    results = {}
    processed = [0]

    def process(item):
        inp, out = item
        ok = generate_one(inp, out, args.size)
        with lock:
            results[inp] = out if ok else None
            processed[0] += 1

    if work:
        print(f"[thumbgen] {len(work)} of {len(files)} thumbnails need generation", file=sys.stderr)
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futures = [ex.submit(process, w) for w in work]
            for _ in as_completed(futures):
                pass
        print(f"[thumbgen] done ({processed[0]} processed)", file=sys.stderr)
    else:
        print("[thumbgen] all thumbnails up to date", file=sys.stderr)

    # Build output list — all files, with thumbnail paths
    output = []
    for f in files:
        thumb_name = file_hash(f) + ".jpg"
        thumb = str(cache_dir / thumb_name)
        output.append({
            "original": f,
            "thumbnail": thumb if os.path.exists(thumb) else None
        })

    print(json.dumps(output))

if __name__ == "__main__":
    main()
