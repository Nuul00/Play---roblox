# Убирает зелёный оттенок у ореола по краю иконки (свечение смешалось с зелёным фоном):
# в полосе шириной band пикселей от прозрачного края зелёный канал не выше max(R, B) + 10.
import sys
from PIL import Image, ImageFilter
path, band = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 36
im = Image.open(path).convert('RGBA')
alpha = im.getchannel('A')
holes = alpha.point(lambda a: 255 if a < 8 else 0)
near = holes.filter(ImageFilter.MaxFilter(band * 2 + 1))
px, nm = im.load(), near.load()
W, H = im.size
n = 0
for y in range(H):
    for x in range(W):
        if nm[x, y]:
            r, g, b, a = px[x, y]
            m = max(r, b)
            if a and g > m + 10:
                px[x, y] = (r, m + 10, b, a); n += 1
im.save(path); print(path, n)
