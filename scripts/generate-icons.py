import struct, zlib, math, os

def encode_png(w, h, pixels):
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)
    raw = b''.join(b'\x00' + bytes([c for px in row for c in px]) for row in pixels)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')

def make_icon(size):
    w = h = size
    bg = (45, 90, 39)
    white = (255, 255, 255)
    cx, cy = w / 2.0, h / 2.0
    s = w / 192.0  # scale factor

    def in_roundrect(x, y, rx, ry, rw, rh, r):
        dx = max(abs(x - rx) - rw / 2 + r, 0)
        dy = max(abs(y - ry) - rh / 2 + r, 0)
        return dx * dx + dy * dy < r * r

    def in_ellipse(x, y, ex, ey, a, b, angle):
        cos_a, sin_a = math.cos(angle), math.sin(angle)
        dx, dy = x - ex, y - ey
        rx = dx * cos_a + dy * sin_a
        ry = -dx * sin_a + dy * cos_a
        return (rx / a) ** 2 + (ry / b) ** 2 < 1

    rows = []
    for y in range(h):
        row = []
        for x in range(w):
            # Leaf 1: upper-right ellipse, tilted
            l1 = in_ellipse(x, y, cx + 14*s, cy - 14*s, 42*s, 22*s, math.radians(-45))
            # Leaf 2: lower-left ellipse, tilted other way
            l2 = in_ellipse(x, y, cx - 14*s, cy + 14*s, 42*s, 22*s, math.radians(-45))
            # Stem: thin diagonal line
            dx, dy_ = x - cx, y - cy
            dist = abs(dx + dy_) / math.sqrt(2)
            on_stem = dist < 2.5*s and -30*s < dx - dy_ < 10*s
            row.append(white if (l1 or l2 or on_stem) else bg)
        rows.append(row)
    return encode_png(w, h, rows)

os.makedirs('icons', exist_ok=True)
for size in [180, 192, 512]:
    data = make_icon(size)
    path = f'icons/icon-{size}.png'
    with open(path, 'wb') as f:
        f.write(data)
    print(f'✓ {path} ({len(data):,} bytes)')
