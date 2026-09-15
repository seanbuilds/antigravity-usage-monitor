#!/usr/bin/env python3
"""
generate_icon_v1.py
v1 – Automated Apple-grade icon generator for Antigravity Usage Monitor.
Distinguishes the Dock icon from the native Antigravity IDE by compositing
an elegant circular telemetry gauge badge in the lower-right quadrant.
"""

import os
import sys
import math
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFilter

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
TMP_DIR = "/tmp/antigravity_icon_build"
ICONSET_DIR = os.path.join(TMP_DIR, "AntigravityUsage.iconset")
OUTPUT_ICNS = os.path.join(SCRIPT_DIR, "AntigravityAppIcon.icns")
APPICON_ICNS = os.path.join(SCRIPT_DIR, "AppIcon.icns")

def get_base_antigravity_icon():
    source_icns = "/Applications/Antigravity.app/Contents/Resources/icon.icns"
    if not os.path.exists(source_icns):
        home_app = os.path.expanduser("~/Applications/Antigravity.app/Contents/Resources/icon.icns")
        if os.path.exists(home_app):
            source_icns = home_app
        else:
            raise FileNotFoundError("Antigravity.app icon.icns not found in standard paths.")

    raw_iconset = os.path.join(TMP_DIR, "raw.iconset")
    if os.path.exists(raw_iconset):
        shutil.rmtree(raw_iconset)
    os.makedirs(raw_iconset, exist_ok=True)

    subprocess.run(["iconutil", "-c", "iconset", source_icns, "-o", raw_iconset], check=True)
    
    # Prefer highest available resolution
    for cand in ["icon_512x512@2x.png", "icon_512x512.png", "icon_256x256@2x.png"]:
        p = os.path.join(raw_iconset, cand)
        if os.path.exists(p):
            return Image.open(p).convert("RGBA")
    raise FileNotFoundError("Could not find high-resolution PNG in extracted iconset.")

def render_antigravity_usage_icon(base_img):
    # Upscale base to 1024x1024
    base1024 = base_img.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    # 2x supersampling for razor-sharp vector-grade rasterization
    S = 2
    canvas = base1024.resize((1024 * S, 1024 * S), Image.Resampling.LANCZOS)

    # Geometry for lower-right telemetry badge
    cx, cy = int(765 * S), int(775 * S)
    r_badge = int(145 * S)

    # Multi-stage drop shadow
    shadow_layer = Image.new("RGBA", (1024 * S, 1024 * S), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    sdraw.ellipse([cx - r_badge - 8*S, cy - r_badge + 6*S, cx + r_badge + 8*S, cy + r_badge + 22*S], fill=(0, 0, 0, 120))
    sdraw.ellipse([cx - r_badge - 4*S, cy - r_badge + 16*S, cx + r_badge + 4*S, cy + r_badge + 34*S], fill=(0, 0, 0, 90))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(14 * S))
    canvas = Image.alpha_composite(canvas, shadow_layer)

    draw = ImageDraw.Draw(canvas)

    # Outer white/platinum bezel (macOS standard companion style)
    draw.ellipse([cx - r_badge - 7*S, cy - r_badge - 7*S, cx + r_badge + 7*S, cy + r_badge + 7*S], fill=(248, 250, 252, 255))
    draw.ellipse([cx - r_badge - 1*S, cy - r_badge - 1*S, cx + r_badge + 1*S, cy + r_badge + 1*S], fill=(203, 213, 225, 255))

    # Dark graphite face
    draw.ellipse([cx - r_badge, cy - r_badge, cx + r_badge, cy + r_badge], fill=(15, 23, 42, 255))
    draw.ellipse([cx - r_badge + 4*S, cy - r_badge + 4*S, cx + r_badge - 4*S, cy + r_badge - 4*S], fill=(30, 41, 59, 255))
    draw.ellipse([cx - r_badge + 8*S, cy - r_badge + 8*S, cx + r_badge - 8*S, cy + r_badge - 8*S], fill=(15, 23, 42, 255))

    # Background track arc
    track_r = int(105 * S)
    box_track = [cx - track_r, cy - track_r, cx + track_r, cy + track_r]
    draw.arc(box_track, start=135, end=405, fill=(51, 65, 85, 255), width=int(14 * S))

    # High-contrast vibrant usage gradient arc (Cyan -> Blue -> Indigo)
    steps = 60
    start_angle = 135
    sweep = 210  # 135 to 345 deg (~78% quota indication)
    for i in range(steps):
        a1 = start_angle + (i * sweep) / steps
        a2 = start_angle + ((i + 1.2) * sweep) / steps
        t = i / steps
        if t < 0.5:
            sub_t = t * 2
            r = int(6 * (1 - sub_t) + 59 * sub_t)
            g = int(182 * (1 - sub_t) + 130 * sub_t)
            b = int(212 * (1 - sub_t) + 246 * sub_t)
        else:
            sub_t = (t - 0.5) * 2
            r = int(59 * (1 - sub_t) + 99 * sub_t)
            g = int(130 * (1 - sub_t) + 102 * sub_t)
            b = int(246 * (1 - sub_t) + 241 * sub_t)
        draw.arc(box_track, start=a1, end=a2, fill=(r, g, b, 255), width=int(14 * S))

    # Precision tick marks
    for deg in [135, 180, 225, 270, 315, 360, 405]:
        rad = math.radians(deg)
        t_in = track_r - int(20 * S)
        t_out = track_r - int(10 * S)
        x1 = cx + t_in * math.cos(rad)
        y1 = cy + t_in * math.sin(rad)
        x2 = cx + t_out * math.cos(rad)
        y2 = cy + t_out * math.sin(rad)
        draw.line([(x1, y1), (x2, y2)], fill=(148, 163, 184, 200), width=int(3 * S))

    # Telemetry needle pointing to 340 degrees
    n_angle = math.radians(340)
    n_len = track_r - int(6 * S)
    nx = cx + n_len * math.cos(n_angle)
    ny = cy + n_len * math.sin(n_angle)
    draw.line([(cx, cy), (nx, ny)], fill=(255, 255, 255, 255), width=int(5 * S))
    draw.ellipse([nx - 4*S, ny - 4*S, nx + 4*S, ny + 4*S], fill=(56, 189, 248, 255))

    # Precision center hub
    draw.ellipse([cx - 20*S, cy - 20*S, cx + 20*S, cy + 20*S], fill=(30, 41, 59, 255), outline=(203, 213, 225, 255), width=int(3*S))
    draw.ellipse([cx - 10*S, cy - 10*S, cx + 10*S, cy + 10*S], fill=(255, 255, 255, 255))

    master1024 = canvas.resize((1024, 1024), Image.Resampling.LANCZOS)
    return master1024

def build_iconset_and_icns(master1024):
    if os.path.exists(ICONSET_DIR):
        shutil.rmtree(ICONSET_DIR)
    os.makedirs(ICONSET_DIR, exist_ok=True)

    sizes = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for filename, sz in sizes:
        resized = master1024.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(ICONSET_DIR, filename), format="PNG")

    # Compile to ICNS
    subprocess.run(["iconutil", "-c", "icns", ICONSET_DIR, "-o", OUTPUT_ICNS], check=True)
    shutil.copyfile(OUTPUT_ICNS, APPICON_ICNS)
    print(f"==> Successfully generated {OUTPUT_ICNS} and {APPICON_ICNS}")

if __name__ == "__main__":
    os.makedirs(TMP_DIR, exist_ok=True)
    base = get_base_antigravity_icon()
    master = render_antigravity_usage_icon(base)
    build_iconset_and_icns(master)
