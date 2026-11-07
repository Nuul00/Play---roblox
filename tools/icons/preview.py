# Превью нескольких иконок на тёмно-фиолетовом фоне: python preview.py out.png a.png b.png c.png
import sys
from PIL import Image
out, files = sys.argv[1], sys.argv[2:]
bg = Image.new('RGBA', (512 * len(files), 512), (60, 36, 120, 255))
for i, f in enumerate(files):
    bg.alpha_composite(Image.open(f).convert('RGBA').resize((512, 512)), (i * 512, 0))
bg.convert('RGB').resize((256 * len(files), 256)).save(out)
