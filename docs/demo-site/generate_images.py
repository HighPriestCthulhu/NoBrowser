"""Draws the three original demo images (hills.png, fruit.png, tiles.png).

Usage: python3 generate_images.py <output-dir>   (needs Pillow)
"""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter
out = sys.argv[1]
random.seed(7)
W, H = 900, 600

def grad(c1, c2, vertical=True):
    im = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(im)
    n = H if vertical else W
    for i in range(n):
        t = i / (n - 1)
        c = tuple(int(c1[k] + (c2[k] - c1[k]) * t) for k in range(3))
        if vertical: d.line([(0, i), (W, i)], fill=c)
        else: d.line([(i, 0), (i, H)], fill=c)
    return im

# 1. Sunset hills
im = grad((255, 120, 60), (120, 40, 160))
d = ImageDraw.Draw(im)
d.ellipse([560, 140, 760, 340], fill=(255, 220, 80))
for k, col in enumerate([(230, 70, 110), (170, 40, 120), (90, 20, 90)]):
    pts = [(0, H)]
    for x in range(0, W + 1, 10):
        pts.append((x, 330 + k * 80 + 40 * math.sin(x / (90 + k * 30) + k)))
    pts.append((W, H))
    d.polygon(pts, fill=col)
im.save(f"{out}/hills.png")

# 2. Fruit bowl of circles
im = grad((250, 245, 230), (240, 225, 200))
d = ImageDraw.Draw(im)
d.pieslice([150, 250, 750, 650], 0, 180, fill=(40, 120, 200))
fruits = [((300, 300), 90, (230, 40, 50)), ((450, 260), 100, (255, 170, 0)),
          ((600, 300), 85, (110, 190, 60)), ((380, 200), 70, (150, 60, 180)),
          ((530, 190), 65, (250, 90, 140))]
for (x, y), r, c in fruits:
    d.ellipse([x - r, y - r, x + r, y + r], fill=c)
    d.ellipse([x - r * 0.5, y - r * 0.6, x - r * 0.1, y - r * 0.25], fill=tuple(min(255, v + 70) for v in c))
d.rectangle([150, 448, 750, 452], fill=(30, 90, 160))
im.save(f"{out}/fruit.png")

# 3. Abstract tiles
im = Image.new("RGB", (W, H), (20, 20, 30))
d = ImageDraw.Draw(im)
pal = [(0, 180, 200), (255, 90, 80), (255, 200, 40), (120, 80, 220), (60, 200, 120)]
s = 75
for gx in range(0, W, s):
    for gy in range(0, H, s):
        c = random.choice(pal)
        kind = random.randint(0, 2)
        if kind == 0: d.rectangle([gx + 6, gy + 6, gx + s - 6, gy + s - 6], fill=c)
        elif kind == 1: d.ellipse([gx + 6, gy + 6, gx + s - 6, gy + s - 6], fill=c)
        else: d.polygon([(gx + 6, gy + s - 6), (gx + s / 2, gy + 6), (gx + s - 6, gy + s - 6)], fill=c)
im.save(f"{out}/tiles.png")
