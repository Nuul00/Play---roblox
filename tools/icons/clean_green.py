# Убирает остатки чистого зелёного фона внутри иконки (замкнутые «дырки»), если в предмете нет зелени.
# python clean_green.py a.png b.png ...
import sys
import numpy as np
from PIL import Image
for f in sys.argv[1:]:
    im = np.array(Image.open(f).convert('RGBA')).astype(int)
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    m = (g > 150) & (g > r + 60) & (g > b + 60)
    im[m, 3] = 0
    e = (g > r + 25) & (g > b + 25) & ~m
    im[e, 1] = np.maximum(r[e], b[e])
    Image.fromarray(im.astype('uint8')).save(f)
    print(f, int(m.sum()))
