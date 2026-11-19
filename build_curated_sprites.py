import os
import io
import re
import zipfile
from PIL import Image

DL_DIR = r"C:\Users\roy\Downloads"
BASE = r"C:\Users\roy\.gemini\antigravity\scratch\cozy_haven\assets\real"

# Curated item numbers from items.zip
CURATED_ITEMS = [
    94,    # 0: Wood/Iron Hoe
    99,    # 1: Copper Hoe
    97,    # 2: Gold Hoe
    1146,  # 3: Watering Can / Bucket (Silver)
    1147,  # 4: Watering Can / Bucket (Blue/Copper)
    1152,  # 5: Watering Can (Gold/Emerald)
    186,   # 6: Fishing Rod
    43,    # 7: Axe
    24,    # 8: Pickaxe
    4,     # 9: Iron Sword
    1164,  # 10: Dog Bone
    1021,  # 11: Seed Packet
    326,   # 12: Carrot
    329,   # 13: Potato
    335,   # 14: Pumpkin
    364,   # 15: Corn
    481,   # 16: Cabbage
    391,   # 17: Radish / Beetroot
    392,   # 18: Cauliflower
    339,   # 19: Wheat
    1029,  # 20: Sunflower
    431,   # 21: Strawberry
    338,   # 22: Egg
    370,   # 23: Milk
    328,   # 24: Red Mushroom
    389,   # 25: Blue Glow Mushroom
    327,   # 26: Brown Truffle Mushroom
    992,   # 27: Wood Log
    575,   # 28: Stone
    1132,  # 29: Copper Ore
    1134,  # 30: Gold Ore
    565,   # 31: Copper Bar
    567,   # 32: Gold Bar
    1044,  # 33: River Trout
    1069,  # 34: Rainbow Sunfish
    1051,  # 35: Golden Koi
    1056,  # 36: Mystic Moon Eel
    393,   # 37: Fried Egg Breakfast
    441,   # 38: Grilled Fish
    427,   # 39: Pumpkin Pie / Tart
    476,   # 40: Vegetable Stew
    901,   # 41: Growth Elixir (Bereket İksiri)
    903,   # 42: Rain Totem Potion (Yağmur İksiri)
    902,   # 43: Spirit Elixir (Ruh Şurubu)
    531,   # 44: Spirit Crystal (Ruh Kristali)
    1163,  # 45: Gold Coin Pile
    373,   # 46: Warm Tea / Coffee
]


def build_curated_items():
    with zipfile.ZipFile(os.path.join(DL_DIR, "items.zip"), "r") as z:
        item_files = {}
        for f in z.namelist():
            m = re.search(r"item(\d+)\.png$", f)
            if m and "__MACOSX" not in f:
                item_files[int(m.group(1))] = f

        strip = Image.new("RGBA", (len(CURATED_ITEMS) * 16, 16), (0, 0, 0, 0))
        for idx, num in enumerate(CURATED_ITEMS):
            im = Image.open(io.BytesIO(z.read(item_files[num]))).convert("RGBA")
            if im.size != (16, 16):
                im = im.resize((16, 16), Image.NEAREST)
            strip.paste(im, (idx * 16, 0))
        out_path = os.path.join(BASE, "items", "items_curated.png")
        strip.save(out_path)
        print(f"Saved {out_path} ({len(CURATED_ITEMS)} icons, {strip.size})")


def build_houses_and_props():
    roofs = Image.open(os.path.join(BASE, "env/Roofs.png")).convert("RGBA")
    walls = Image.open(os.path.join(BASE, "env/Walls.png")).convert("RGBA")
    props = Image.open(os.path.join(BASE, "env/Props.png")).convert("RGBA")
    farm_p = Image.open(os.path.join(BASE, "env/Farm.png")).convert("RGBA")

    # Exact clean bounding boxes verified from Props.png
    chimney = props.crop((4, 73, 28, 128))       # 24x55
    door_wood = props.crop((101, 29, 123, 64))   # 22x35
    door_arch = props.crop((133, 29, 155, 64))   # 22x35
    win_blue = props.crop((101, 64, 123, 94))    # 22x30
    win_green = props.crop((128, 64, 162, 94))   # 34x30
    flowerbox = props.crop((50, 154, 78, 171))   # 28x17
    bench = props.crop((83, 160, 141, 192))      # 58x32
    fence_h = props.crop((22, 240, 54, 256))     # 32x16

    def make_house(roof_box, wall_tile_box, filename, has_chimney=True, door_type="wood"):
        canvas = Image.new("RGBA", (128, 134), (0, 0, 0, 0))
        # Tile wall cleanly across 96px width (x=16..112, y=64..128)
        w_tile = walls.crop(wall_tile_box) # 32x56
        for wx in [16, 48, 80]:
            canvas.paste(w_tile, (wx, 64), w_tile)
            canvas.paste(w_tile, (wx, 74), w_tile)
        # Paste roof above wall (x=0, y=14)
        roof = roofs.crop(roof_box) # 128x80
        canvas.paste(roof, (0, 14), roof)
        if has_chimney:
            canvas.paste(chimney, (90, 0), chimney)
        # Door centered
        d = door_wood if door_type == "wood" else door_arch
        canvas.paste(d, (53, 95), d)
        # Windows
        if door_type == "wood":
            canvas.paste(win_blue, (22, 92), win_blue)
            canvas.paste(win_blue, (84, 92), win_blue)
        else:
            canvas.paste(win_green, (16, 92), win_green)
            canvas.paste(win_green, (78, 92), win_green)
        # Flowerboxes
        canvas.paste(flowerbox, (19, 117), flowerbox)
        canvas.paste(flowerbox, (81, 117), flowerbox)
        canvas.save(os.path.join(BASE, "farm", filename))
        print("Built", filename)

    # Farm house: Brown roof + warm horizontal wood log wall (walls x=0..32 is log edge, x=32..64 is middle log)
    make_house((0, 6, 128, 86), (112, 184, 144, 240), "house_farm.png", True, "wood")
    # Seed shop: Green roof + cream plaster wall (walls x=400..432)
    make_house((128, 6, 256, 86), (400, 184, 432, 240), "house_shop.png", False, "arch")
    # Tavern / Smithy: Brown roof + brick-trimmed plaster wall (walls x=496..528)
    make_house((0, 6, 128, 86), (496, 184, 528, 240), "house_tavern.png", True, "arch")

    # Scarecrow cleanly cropped (y=32..82 removes pot above it!)
    scare = farm_p.crop((240, 32, 272, 82))
    scare.save(os.path.join(BASE, "farm", "scarecrow.png"))
    bench.save(os.path.join(BASE, "farm", "bench.png"))
    fence_h.save(os.path.join(BASE, "farm", "fence_h.png"))
    print("Clean props saved!")


if __name__ == "__main__":
    build_curated_items()
    build_houses_and_props()
