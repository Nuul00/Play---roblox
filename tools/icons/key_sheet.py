# Режет лист иконок ChatGPT на зелёном (#00FF00) фоне: убирает фон заливкой от краёв
# (зелень внутри иконок не трогается), чистит зелёную кайму, раскладывает по квадратам 512.
import sys
from collections import deque
from PIL import Image
src, outdir, names = sys.argv[1], sys.argv[2], sys.argv[3].split(',')
im = Image.open(src).convert('RGBA'); W, H = im.size; px = im.load()
def isg(c): r, g, b, a = c; return g > 150 and g - max(r, b) > 90
key = bytearray(W * H); q = deque()
for x in range(W): q.append((x, 0)); q.append((x, H - 1))
for y in range(H): q.append((0, y)); q.append((W - 1, y))
while q:
    x, y = q.pop(); i = y * W + x
    if key[i] or not isg(px[x, y]): continue
    key[i] = 1
    if x > 0: q.append((x - 1, y))
    if x < W - 1: q.append((x + 1, y))
    if y > 0: q.append((x, y - 1))
    if y < H - 1: q.append((x, y + 1))
for y in range(H):
    for x in range(W):
        i = y * W + x
        if key[i]: px[x, y] = (0, 0, 0, 0); continue
        n = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if 0 <= x + dx < W and 0 <= y + dy < H and key[(y + dy) * W + x + dx])
        if n:
            r, g, b, a = px[x, y]; m = max(r, b)
            if g > m + 20: g = m + 20
            px[x, y] = (r, g, b, 150 if n >= 2 else 220)
cols = [any(px[x, y][3] for y in range(0, H, 2)) for x in range(W)]
boxes = []; s = None
for x in range(W + 1):
    if x < W and cols[x]:
        s = x if s is None else s
    elif s is not None:
        if x - s > 40: boxes.append((s, x))
        s = None
print('boxes', boxes)
for (a, b), n in zip(boxes, names):
    crop = im.crop((a, 0, b, H)); crop = crop.crop(crop.getbbox())
    w, h = crop.size; S = max(w, h) + 24
    out = Image.new('RGBA', (S, S), (0, 0, 0, 0)); out.paste(crop, ((S - w) // 2, (S - h) // 2))
    out.resize((512, 512), Image.LANCZOS).save(f'{outdir}/{n}.png'); print('saved', n)
