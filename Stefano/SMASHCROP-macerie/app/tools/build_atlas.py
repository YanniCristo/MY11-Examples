"""Un solo file per personaggio: 18 fotogrammi + 6 elementi in atlas.webp.

Uso: python3 tools/build_atlas.py <cartella con f_01..f_18.webp e e_1..e_6.webp> <atlas.webp> [qualita]
La disposizione deve restare uguale a SkinAtlas in lib/features/rubble/application/skin_assets.dart.
"""
import sys
from PIL import Image

FW, FH, PAD, COLS = 730, 470, 2, 5
CW, CH = FW + 2 * PAD, FH + 2 * PAD
EW, EGAP = 96, 4


def build(src, out, q):
    atlas = Image.new('RGBA', (COLS * CW, 4 * CH), (0, 0, 0, 0))
    for i in range(18):
        im = Image.open(f'{src}/f_{i + 1:02d}.webp').convert('RGBA')
        assert im.size == (FW, FH), im.size
        atlas.paste(im, ((i % COLS) * CW + PAD, (i // COLS) * CH + PAD))
    # elementi nella cella 18 (colonna 3, riga 3), in fila
    ex, ey = 3 * CW + PAD, 3 * CH + PAD
    for i in range(6):
        im = Image.open(f'{src}/e_{i + 1}.webp').convert('RGBA')
        assert im.size == (EW, EW), im.size
        atlas.paste(im, (ex + i * (EW + EGAP), ey))
    if q >= 100:
        atlas.save(out, 'WEBP', lossless=True, method=6)
    else:
        atlas.save(out, 'WEBP', quality=q, method=6, alpha_quality=100)


if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 90)
