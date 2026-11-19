# Çayır Vadisi — çim karolarını yeniden üretir (terrain_tiles.png içindeki 0..5 numaralı karolar).
# Eski çim iki farklı tonda düz yeşil olduğu için oyunda dama tahtası gibi görünüyordu.
# Bu betik tüm çim karolarını AYNI taban renkle, yumuşak doku + ot öbekleri + küçük çiçeklerle üretir.
# Kullanım: python improve_terrain.py   (proje klasörünün içinden çalıştırın)
import os
import random
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, "assets", "real", "env", "terrain_tiles.png")
BACKUP = os.path.join(HERE, "assets", "real", "env", "terrain_tiles_eski.png")

BASE = (110, 178, 76)
DARK = (92, 156, 66)
DARKER = (74, 132, 60)
LIGHT = (134, 194, 90)
FLOWERS = [(246, 240, 214), (250, 214, 110), (236, 150, 160)]


def tuft(px, x, y):
    # küçük "v" şeklinde ot öbeği (3x3)
    for dx, dy, col in [(0, 0, DARKER), (2, 0, DARKER), (1, 1, DARKER), (0, -1, DARK), (2, -1, DARK), (1, 0, LIGHT)]:
        xx, yy = (x + dx) % 16, (y + dy) % 16
        px[xx, yy] = (*col, 255)


def make_tile(seed, tufts, flowers):
    rnd = random.Random(seed)
    im = Image.new("RGBA", (16, 16), (*BASE, 255))
    px = im.load()
    # hafif dither dokusu (kenarlarda dikiş oluşmasın diye her karoda aynı yoğunluk)
    for _ in range(16):
        px[rnd.randrange(16), rnd.randrange(16)] = (*DARK, 255)
    for _ in range(8):
        px[rnd.randrange(16), rnd.randrange(16)] = (*LIGHT, 255)
    for _ in range(tufts):
        tuft(px, rnd.randrange(1, 13), rnd.randrange(2, 14))
    for _ in range(flowers):
        x, y = rnd.randrange(2, 14), rnd.randrange(2, 14)
        c = rnd.choice(FLOWERS)
        px[x, y] = (*c, 255)
        px[x, y + 1] = (*DARKER, 255)
    return im


def main():
    strip = Image.open(PATH).convert("RGBA")
    if not os.path.exists(BACKUP):
        strip.save(BACKUP)
    variants = [
        make_tile(11, 0, 0),
        make_tile(12, 0, 0),
        make_tile(13, 1, 0),
        make_tile(14, 1, 0),
        make_tile(15, 2, 0),
        make_tile(16, 1, 2),
    ]
    for i, t in enumerate(variants):
        strip.paste(t, (i * 16, 0))
    strip.save(PATH)
    print("Çim karoları güncellendi:", PATH)


if __name__ == "__main__":
    main()
