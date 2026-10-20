#!/usr/bin/env python3
"""Draws the Todo1 app icon: a bold rounded checkbox with a tick on off-white.

Stdlib only. Writes an opaque 1024x1024 RGB PNG (App Store icons must not have alpha).
Usage: scripts/make_icon.py [output.png]
"""
import math
import struct
import sys
import zlib

SIZE = 1024
BACKGROUND = (0xFA, 0xF8, 0xF3)  # Paper theme background
INK = (0x1A, 0x1A, 0x1A)  # Paper theme accent

CENTER = SIZE / 2
BOX_HALF = 290.0
BOX_RADIUS = 96.0
STROKE = 68.0
TICK_RADIUS = 38.0
TICK = [(372.0, 522.0), (474.0, 626.0), (662.0, 404.0)]
DEFAULT_OUTPUT = "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"


def rounded_box(x, y):
    """Signed distance to a rounded square centred on the canvas."""
    qx = abs(x - CENTER) - (BOX_HALF - BOX_RADIUS)
    qy = abs(y - CENTER) - (BOX_HALF - BOX_RADIUS)
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    inside = min(max(qx, qy), 0.0)
    return outside + inside - BOX_RADIUS


def segment(x, y, a, b):
    """Distance from (x, y) to segment a-b."""
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)
    t = min(max(t, 0.0), 1.0)
    return math.hypot(x - (ax + t * dx), y - (ay + t * dy))


def coverage(x, y):
    ring = abs(rounded_box(x, y)) - STROKE / 2
    tick = min(segment(x, y, TICK[i], TICK[i + 1]) for i in range(len(TICK) - 1)) - TICK_RADIUS
    distance = min(ring, tick)
    return min(max(0.5 - distance, 0.0), 1.0)


def pixels():
    rows = bytearray()
    for py in range(SIZE):
        rows.append(0)  # PNG filter type: none
        y = py + 0.5
        for px in range(SIZE):
            a = coverage(px + 0.5, y)
            for bg, ink in zip(BACKGROUND, INK):
                rows.append(round(bg + (ink - bg) * a))
    return bytes(rows)


def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def write_png(path):
    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)  # 8-bit RGB, no alpha
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(pixels(), 9))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    write_png(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_OUTPUT)
