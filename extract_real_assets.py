import os
import io
import re
import zipfile
from PIL import Image

DL_DIR = r"C:\Users\roy\Downloads"
OUT_BASE = r"C:\Users\roy\.gemini\antigravity\scratch\cozy_haven\assets\real"

SUBDIRS = ["player", "npcs", "mobs", "env", "crops", "farm", "dog", "fx", "items"]
for sd in SUBDIRS:
    os.makedirs(os.path.join(OUT_BASE, sd), exist_ok=True)


def save_bytes(subdir, filename, data):
    path = os.path.join(OUT_BASE, subdir, filename)
    with open(path, "wb") as f:
        f.write(data)


def extract_pixel_crawler():
    zpath = os.path.join(DL_DIR, "Pixel Crawler - Free Pack (Exterior 0.1).zip")
    with zipfile.ZipFile(zpath, "r") as z:
        prefix = "Pixel Crawler - Free Pack/"

        # 1. Player animations
        anims = [
            ("Idle_Base/Idle_Down-Sheet.png", "Idle_Down.png"),
            ("Idle_Base/Idle_Side-Sheet.png", "Idle_Side.png"),
            ("Idle_Base/Idle_Up-Sheet.png", "Idle_Up.png"),
            ("Walk_Base/Walk_Down-Sheet.png", "Walk_Down.png"),
            ("Walk_Base/Walk_Side-Sheet.png", "Walk_Side.png"),
            ("Walk_Base/Walk_Up-Sheet.png", "Walk_Up.png"),
            ("Run_Base/Run_Down-Sheet.png", "Run_Down.png"),
            ("Run_Base/Run_Side-Sheet.png", "Run_Side.png"),
            ("Run_Base/Run_Up-Sheet.png", "Run_Up.png"),
            ("Crush_Base/Crush_Down-Sheet.png", "Crush_Down.png"),
            ("Crush_Base/Crush_Side-Sheet.png", "Crush_Side.png"),
            ("Crush_Base/Crush_Up-Sheet.png", "Crush_Up.png"),
            ("Watering_Base/Watering_Down-Sheet.png", "Watering_Down.png"),
            ("Watering_Base/Watering_Side-Sheet.png", "Watering_Side.png"),
            ("Watering_Base/Watering_Up-Sheet.png", "Watering_Up.png"),
            ("Slice_Base/Slice_Down-Sheet.png", "Slice_Down.png"),
            ("Slice_Base/Slice_Side-Sheet.png", "Slice_Side.png"),
            ("Slice_Base/Slice_Up-Sheet.png", "Slice_Up.png"),
            ("Fishing_Base/Fishing_Down-Sheet.png", "Fishing_Down.png"),
            ("Fishing_Base/Fishing_Side-Sheet.png", "Fishing_Side.png"),
            ("Fishing_Base/Fishing_Up-Sheet.png", "Fishing_Up.png"),
            ("Collect_Base/Collect_Down-Sheet.png", "Collect_Down.png"),
            ("Collect_Base/Collect_Side-Sheet.png", "Collect_Side.png"),
            ("Collect_Base/Collect_Up-Sheet.png", "Collect_Up.png"),
        ]
        for src, dst in anims:
            save_bytes("player", dst, z.read(prefix + "Entities/Characters/Body_A/Animations/" + src))

        # 2. NPCs
        npcs = [
            ("Entities/Npc's/Citizen_F/Peasant_A/Idle/Idle-Sheet.png", "peasant_idle.png"),
            ("Entities/Npc's/Citizen_F/Peasant_A/Walk/Walk-Sheet.png", "peasant_walk.png"),
            ("Entities/Npc's/Citizen_F/Tavern_A/Idle/Idle_Side-Sheet.png", "tavern_a_idle.png"),
            ("Entities/Npc's/Citizen_F/Tavern_A/Walk/Walk_Side-Sheet.png", "tavern_a_walk.png"),
            ("Entities/Npc's/Wizzard/Idle/Idle-Sheet.png", "wizard_idle.png"),
            ("Entities/Npc's/Wizzard/Run/Run-Sheet.png", "wizard_run.png"),
            ("Entities/Npc's/Knight/Idle/Idle-Sheet.png", "knight_idle.png"),
            ("Entities/Npc's/Knight/Run/Run-Sheet.png", "knight_run.png"),
            ("Entities/Npc's/Rogue/Idle/Idle-Sheet.png", "rogue_idle.png"),
            ("Entities/Npc's/Rogue/Run/Run-Sheet.png", "rogue_run.png"),
        ]
        for src, dst in npcs:
            save_bytes("npcs", dst, z.read(prefix + src))

        # 3. Mobs
        mobs = [
            ("Entities/Mobs/Orc Crew/Orc/Idle/Idle-Sheet.png", "orc_idle.png"),
            ("Entities/Mobs/Orc Crew/Orc/Run/Run-Sheet.png", "orc_run.png"),
            ("Entities/Mobs/Orc Crew/Orc/Death/Death-Sheet.png", "orc_death.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Base/Idle/Idle-Sheet.png", "skel_idle.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Base/Run/Run-Sheet.png", "skel_run.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Base/Death/Death-Sheet.png", "skel_death.png"),
        ]
        for src, dst in mobs:
            save_bytes("mobs", dst, z.read(prefix + src))

        # 4. Environment, Trees, Rocks & Stations
        envs = [
            ("Environment/Tilesets/Floors_Tiles.png", "Floors_Tiles.png"),
            ("Environment/Tilesets/Water_tiles.png", "Water_tiles.png"),
            ("Environment/Props/Static/Vegetation.png", "Vegetation.png"),
            ("Environment/Props/Static/Rocks.png", "Rocks.png"),
            ("Environment/Props/Static/Farm.png", "Farm.png"),
            ("Environment/Props/Static/Resources.png", "Resources.png"),
            ("Environment/Props/Static/Tools.png", "Tools.png"),
            ("Environment/Structures/Buildings/Props.png", "Props.png"),
            ("Environment/Structures/Buildings/Roofs.png", "Roofs.png"),
            ("Environment/Structures/Buildings/Walls.png", "Walls.png"),
            ("Environment/Props/Static/Trees/Model_01/Size_03.png", "oak_tree.png"),
            ("Environment/Props/Static/Trees/Model_02/Size_04.png", "pine_tree.png"),
            ("Environment/Structures/Stations/Bonfire/Bonfire_01-Sheet.png", "bonfire.png"),
            ("Environment/Structures/Stations/Bonfire/Fire_01-Sheet.png", "fire.png"),
            ("Environment/Structures/Stations/Cooking Station/Cooker/Cooker_03-Sheet.png", "cooker.png"),
            ("Environment/Structures/Stations/Cooking Station/Grill/Grill_01-Sheet.png", "grill.png"),
            ("Environment/Structures/Stations/Furnace/Bricks_01-Sheet.png", "furnace.png"),
            ("Environment/Structures/Stations/Anvil/Anvil.png", "anvil.png"),
            ("Environment/Structures/Stations/Workbench/Workbench.png", "workbench.png"),
            ("Environment/Structures/Stations/Alchemy/Alchemy_Table_03-Sheet.png", "alchemy.png"),
        ]
        for src, dst in envs:
            save_bytes("env", dst, z.read(prefix + src))
    print("Pixel Crawler assets extracted.")


def stitch_gm_sprite(nz, folder_name, out_subdir, out_name):
    yy_path = f"Sunnyside World/Sunnyside World - Gamemaker Studio/sprites/{folder_name}/{folder_name}.yy"
    frame_ids = []
    if yy_path in nz.namelist():
        txt = nz.read(yy_path).decode("utf-8", errors="ignore")
        # In GameMaker .yy, "frames":[ {"... "name":"<uuid>", ... } ] appear before keyframes or vice versa
        # Specifically look for SpriteFrame entries
        frame_ids = re.findall(r'"resourceType"\s*:\s*"GMSpriteFrame"[^}]*?"name"\s*:\s*"([0-9a-f-]+)"', txt, re.DOTALL)
        if not frame_ids:
            # Try order from KeyframeId
            frame_ids = re.findall(r'"KeyframeId"\s*:\s*\{\s*"name"\s*:\s*"([0-9a-f-]+)"', txt, re.DOTALL)

    base_dir = f"Sunnyside World/Sunnyside World - Gamemaker Studio/sprites/{folder_name}/"
    if not frame_ids:
        pngs = sorted([p for p in nz.namelist() if p.startswith(base_dir) and p.endswith(".png") and "/layers/" not in p and "__MACOSX" not in p])
    else:
        pngs = [base_dir + fid + ".png" for fid in frame_ids if (base_dir + fid + ".png") in nz.namelist()]

    imgs = [Image.open(io.BytesIO(nz.read(p))).convert("RGBA") for p in pngs]
    if not imgs:
        print(f"WARNING: No frames found for {folder_name}")
        return
    w, h = imgs[0].size
    strip = Image.new("RGBA", (w * len(imgs), h), (0, 0, 0, 0))
    for i, im in enumerate(imgs):
        strip.paste(im, (i * w, 0))
    strip.save(os.path.join(OUT_BASE, out_subdir, out_name))
    print(f"Stitched {out_name}: {len(imgs)} frames ({w}x{h}) -> {strip.size}")


def extract_sunnyside():
    zpath = os.path.join(DL_DIR, "Sunnyside_World_ARCHIVED_ASSETS.zip")
    with zipfile.ZipFile(zpath, "r") as z:
        # 1. Crops
        with zipfile.ZipFile(io.BytesIO(z.read("SUNNYSIDE_WORLD_CROPS_V0.01 (1).zip")), "r") as nz:
            for p in nz.namelist():
                if p.endswith(".png") and "__MACOSX" not in p:
                    fname = os.path.basename(p)
                    save_bytes("crops", fname, nz.read(p))

        # 2. Buildings
        with zipfile.ZipFile(io.BytesIO(z.read("SUNNYSIDE_WORLD_BUILDINGS_V0.01.zip")), "r") as nz:
            save_bytes("farm", "buildings.png", nz.read("SUNNYSIDE_WORLD_BUILDINGS_V0.01.png"))

        # 3. Tileset Beta & Animated Farm Animals / Windmill / Well
        with zipfile.ZipFile(io.BytesIO(z.read("Sunnyside World_Tileset_Beta (1).zip")), "r") as nz:
            save_bytes("farm", "tileset_sunnyside.png", nz.read("Sunnyside World/spr_tileset_sunnysideworld.png"))
            stitch_gm_sprite(nz, "spr_deco_chicken_01", "farm", "chicken_strip.png")
            stitch_gm_sprite(nz, "spr_deco_cow", "farm", "cow_strip.png")
            stitch_gm_sprite(nz, "spr_deco_sheep_01", "farm", "sheep_strip.png")
            stitch_gm_sprite(nz, "spr_deco_pig_01", "farm", "pig_strip.png")
            stitch_gm_sprite(nz, "spr_deco_windmill", "farm", "windmill_strip.png")
            stitch_gm_sprite(nz, "spr_deco_well", "farm", "well.png")
            stitch_gm_sprite(nz, "spr_deco_flowers_house_01", "farm", "house_flowers.png")
            stitch_gm_sprite(nz, "spr_deco_firepit", "farm", "firepit.png")
            stitch_gm_sprite(nz, "spr_deco_barrel_water", "farm", "barrel_water.png")
            stitch_gm_sprite(nz, "chimneysmoke_01", "farm", "chimney_smoke_strip.png")
            stitch_gm_sprite(nz, "spr_deco_tree_01", "farm", "sunnyside_tree_01.png")
            stitch_gm_sprite(nz, "spr_deco_tree_02", "farm", "sunnyside_tree_02.png")
    print("Sunnyside assets extracted.")


def extract_dogs_and_fx():
    # Dogs
    with zipfile.ZipFile(os.path.join(DL_DIR, "DogMegaPackFree.zip"), "r") as z:
        save_bytes("dog", "Dogs.png", z.read("DogMegaPackFree/Dogs.png"))
        save_bytes("dog", "DogItems.png", z.read("DogMegaPackFree/DogItems.png"))

    # Super Pixel Effects
    with zipfile.ZipFile(os.path.join(DL_DIR, "Super Pixel Effects Gigapack (Free Version) v3.2.0.zip"), "r") as z:
        fx_map = {
            "fx_sparkle.png": "round_sparkle_burst_002/round_sparkle_burst_002_small_green/spritesheet.png",
            "fx_heart.png": "round_heart_burst_001/round_heart_burst_001_small_red/spritesheet.png",
            "fx_splat.png": "burst_splatter_001/burst_splatter_001_small_red/spritesheet.png",
            "fx_hit.png": "directional_impact_001/directional_impact_001_small_blue/spritesheet.png",
            "fx_coin.png": "directional_coin_burst_001/directional_coin_burst_001_small_yellow/spritesheet.png",
            "fx_heal.png": "spell_heal_001/spell_heal_001_small_red/spritesheet.png",
            "fx_smoke.png": "symmetrical_smoke_burst_001/symmetrical_smoke_burst_001_small_brown/spritesheet.png",
            "fx_lightning.png": "lightning_burst_001/lightning_burst_001_small_blue/spritesheet.png",
        }
        names = z.namelist()
        for dst, suffix in fx_map.items():
            matched = [n for n in names if n.endswith(suffix)]
            if matched:
                save_bytes("fx", dst, z.read(matched[0]))
            else:
                print("MISSING FX:", suffix)
    print("Dog and FX assets extracted.")


def extract_items():
    # Inspect & create an atlas sheet from items.zip (all non-empty 16x16 icons)
    with zipfile.ZipFile(os.path.join(DL_DIR, "items.zip"), "r") as z:
        # Sort numerically item1.png .. item1244.png
        item_files = {}
        for f in z.namelist():
            m = re.search(r"item(\d+)\.png$", f)
            if m and "__MACOSX" not in f:
                item_files[int(m.group(1))] = f
        sorted_nums = sorted(item_files.keys())
        # Save a preview contact sheet so we can visually inspect exact icon numbers!
        cols = 32
        rows = (len(sorted_nums) + cols - 1) // cols
        atlas = Image.new("RGBA", (cols * 16, rows * 16), (0, 0, 0, 0))
        for idx, num in enumerate(sorted_nums):
            im = Image.open(io.BytesIO(z.read(item_files[num]))).convert("RGBA")
            if im.size != (16, 16):
                im = im.resize((16, 16), Image.NEAREST)
            r = idx // cols
            c = idx % cols
            atlas.paste(im, (c * 16, r * 16))
        atlas.save(os.path.join(OUT_BASE, "items", "items_atlas.png"))
        print(f"Items atlas created: {len(sorted_nums)} items -> {atlas.size}")


if __name__ == "__main__":
    extract_pixel_crawler()
    extract_sunnyside()
    extract_dogs_and_fx()
    extract_items()
    print("ALL REAL ASSETS EXTRACTED SUCCESSFULLY!")
