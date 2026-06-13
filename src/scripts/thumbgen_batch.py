#!/usr/bin/env python3
"""
Thumbnail Generator for Brain_Shell — mirrors NothingLess' approach.

Key design:
- Proxy directory structure: thumbnails mirror the wallpaper dir layout
- Deterministic paths: no hashes, no JSON maps — path is predictable
- Stale detection: only regenerates when source is newer than thumbnail
- Multithreaded: configurable workers, default 4

Output: writes thumbnails to cache dir. WallpaperService computes paths directly.
"""
import os
import sys
import subprocess
import shutil
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading

VIDEO_EXTS  = {'.mp4', '.webm', '.mkv', '.mov', '.avi'}
IMAGE_EXTS  = {'.jpg', '.jpeg', '.png', '.webp', '.tif', '.tiff', '.bmp'}
GIF_EXTS    = {'.gif'}
ALL_EXTS    = VIDEO_EXTS | IMAGE_EXTS | GIF_EXTS
THUMB_SIZE  = 256
MAX_WORKERS = 4

_im_v7: bool | None = None

def im_v7() -> bool:
    global _im_v7
    if _im_v7 is not None:
        return _im_v7
    try:
        r = subprocess.run(["magick", "--version"], capture_output=True, timeout=5)
        _im_v7 = r.returncode == 0
    except Exception:
        _im_v7 = False
    return _im_v7

def scan_dir(root: Path) -> list[Path]:
    """Recursively find media files, excluding hidden dirs."""
    files = []
    for ext in ALL_EXTS:
        for f in root.rglob(f"*{ext}"):
            rel = f.relative_to(root)
            if any(p.startswith(".") for p in rel.parts[:-1]):
                continue
            files.append(f)
    return sorted(set(files))

def thumb_path(file_path: Path, wall_dir: Path, cache_dir: Path) -> Path:
    """Deterministic thumbnail path that mirrors the wallpaper directory."""
    rel = file_path.relative_to(wall_dir)
    return cache_dir / rel.parent / (file_path.name + ".jpg")

def needs_update(src: Path, thumb: Path) -> bool:
    if not thumb.exists():
        return True
    try:
        return src.stat().st_mtime > thumb.stat().st_mtime
    except OSError:
        return True

def generate_one(inp: Path, out: Path) -> bool:
    ext = inp.suffix.lower()
    out.parent.mkdir(parents=True, exist_ok=True)

    try:
        if ext in VIDEO_EXTS:
            subprocess.run([
                "ffmpeg", "-y", "-ss", "00:00:00.100", "-i", str(inp),
                "-vframes", "1",
                "-vf", f"scale={THUMB_SIZE}:{THUMB_SIZE}:force_original_aspect_ratio=increase,crop={THUMB_SIZE}:{THUMB_SIZE}",
                "-q:v", "2", "-f", "image2", str(out)
            ], capture_output=True, timeout=30)
        elif ext in GIF_EXTS:
            subprocess.run([
                "ffmpeg", "-y", "-i", str(inp),
                "-vframes", "1",
                "-vf", f"scale={THUMB_SIZE}:{THUMB_SIZE}:force_original_aspect_ratio=increase,crop={THUMB_SIZE}:{THUMB_SIZE}",
                "-q:v", "2", "-f", "image2", str(out)
            ], capture_output=True, timeout=15)
        else:
            if im_v7():
                subprocess.run([
                    "magick", str(inp), "-resize", f"{THUMB_SIZE}x{THUMB_SIZE}^",
                    "-gravity", "center", "-extent", f"{THUMB_SIZE}x{THUMB_SIZE}",
                    "-quality", "85", "-strip", str(out)
                ], capture_output=True, timeout=15)
            elif shutil.which("convert"):
                subprocess.run([
                    "convert", str(inp), "-resize", f"{THUMB_SIZE}x{THUMB_SIZE}^",
                    "-gravity", "center", "-extent", f"{THUMB_SIZE}x{THUMB_SIZE}",
                    "-quality", "85", "-strip", str(out)
                ], capture_output=True, timeout=15)
            else:
                subprocess.run([
                    "ffmpeg", "-y", "-i", str(inp),
                    "-vf", f"scale={THUMB_SIZE}:{THUMB_SIZE}:force_original_aspect_ratio=increase,crop={THUMB_SIZE}:{THUMB_SIZE}",
                    "-q:v", "2", "-f", "image2", str(out)
                ], capture_output=True, timeout=15)

        return out.exists() and out.stat().st_size > 0
    except Exception:
        return False

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("wallpaper_dir")
    ap.add_argument("--cache", default=os.path.expanduser("~/.cache/Brain_Shell/thumbnails"))
    ap.add_argument("--size", type=int, default=THUMB_SIZE)
    ap.add_argument("--workers", type=int, default=MAX_WORKERS)
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    wall_dir = Path(args.wallpaper_dir).expanduser().resolve()
    cache_dir = Path(args.cache)

    if not wall_dir.exists():
        if not args.quiet:
            print(f"[thumbgen] directory not found: {wall_dir}", file=sys.stderr)
        return

    cache_dir.mkdir(parents=True, exist_ok=True)

    files = scan_dir(wall_dir)
    if not files:
        return

    work = []
    for f in files:
        tp = thumb_path(f, wall_dir, cache_dir)
        if needs_update(f, tp):
            work.append((f, tp))

    if not work:
        if not args.quiet:
            print(f"[thumbgen] all {len(files)} thumbnails up to date", file=sys.stderr)
        return

    if not args.quiet:
        print(f"[thumbgen] {len(work)}/{len(files)} need generation ({args.workers} workers)", file=sys.stderr)

    lock = threading.Lock()
    done = [0]
    failed = [0]

    def process(item):
        inp, out = item
        ok = generate_one(inp, out)
        with lock:
            done[0] += 1
            if not ok:
                failed[0] += 1

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = [ex.submit(process, w) for w in work]
        for _ in as_completed(futures):
            pass

    if not args.quiet:
        ok = done[0] - failed[0]
        print(f"[thumbgen] done: {ok} ok, {failed[0]} failed", file=sys.stderr)

if __name__ == "__main__":
    main()
