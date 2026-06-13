#!/usr/bin/env python3
"""thumbgen.py — thumbnail generator for Brain_Shell wallpapers.
Generates thumbnails for images, videos, and GIFs using FFmpeg.
Usage: python3 thumbgen.py <input_path> [output_path] [--size 256]
"""
import os, sys, subprocess

def generate_thumbnail(input_path, output_path=None, size=256):
    if not os.path.exists(input_path):
        print(f"ERROR: {input_path} not found", file=sys.stderr)
        return None

    ext = os.path.splitext(input_path)[1].lower()
    is_video = ext in ('.mp4', '.webm', '.mkv', '.mov', '.avi', '.gif')

    if output_path is None:
        base = os.path.splitext(os.path.basename(input_path))[0]
        output_path = f"/tmp/brain_thumb_{base}.jpg"

    if is_video:
        # Extract frame at 1 second or first frame for GIFs
        time_flag = "00:00:01" if ext != '.gif' else "00:00:00"
        cmd = [
            "ffmpeg", "-y",
            "-ss", time_flag,
            "-i", input_path,
            "-vframes", "1",
            "-vf", f"scale={size}:{size}:force_original_aspect_ratio=decrease,pad={size}:{size}:(ow-iw)/2:(oh-ih)/2",
            "-q:v", "2",
            output_path
        ]
    else:
        # Static image — resize with ImageMagick or ffmpeg
        if shutil_which("magick"):
            cmd = ["magick", input_path, "-resize", f"{size}x{size}^", "-gravity", "center", "-extent", f"{size}x{size}", "-quality", "80", "-strip", output_path]
        else:
            cmd = [
                "ffmpeg", "-y",
                "-i", input_path,
                "-vf", f"scale={size}:{size}:force_original_aspect_ratio=decrease,pad={size}:{size}:(ow-iw)/2:(oh-ih)/2",
                "-q:v", "2",
                output_path
            ]

    try:
        subprocess.run(cmd, capture_output=True, timeout=30)
        if os.path.exists(output_path) and os.path.getsize(output_path) > 0:
            print(output_path)
            return output_path
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)

    return None

def shutil_which(cmd):
    import shutil
    return shutil.which(cmd)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 thumbgen.py <input> [output] [--size 256]")
        sys.exit(1)

    inp = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else None
    size = 256
    for i, arg in enumerate(sys.argv):
        if arg == "--size" and i + 1 < len(sys.argv):
            size = int(sys.argv[i + 1])

    result = generate_thumbnail(inp, out, size)
    if result:
        print(result)
    else:
        sys.exit(1)
