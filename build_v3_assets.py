import io
import os
import re
import zipfile
from PIL import Image, ImageDraw, ImageEnhance

DL_DIR = r"C:\Users\roy\Downloads"
OUT_BASE = r"C:\Users\roy\.gemini\antigravity\scratch\cozy_haven\assets\real"

for sd in ["hero", "bosses", "mobs", "npcs", "env", "farm", "fx", "crops", "dog", "items"]:
    os.makedirs(os.path.join(OUT_BASE, sd), exist_ok=True)


def save_img(subdir, filename, im):
    path = os.path.join(OUT_BASE, subdir, filename)
    im.save(path)
    print(f"  [OK] {subdir}/{filename:30s} {im.size}")


def save_bytes(subdir, filename, data):
    path = os.path.join(OUT_BASE, subdir, filename)
    with open(path, "wb") as f:
        f.write(data)
    im = Image.open(io.BytesIO(data))
    print(f"  [OK] {subdir}/{filename:30s} {im.size}")


# ------------------------------------------------------------------------------
# 1. CLOTHED RPG HERO WITH 5 VISUAL ARMOR TIERS (Sunnyside Character Parts)
# ------------------------------------------------------------------------------
HERO_SKINS = [
    # 0: Starter Adventurer (Cobalt Blue tunic + Red scarf) - keep original
    None,
    # 1: Forest Ranger (Forest Green tunic + Warm Brown leather scarf)
    {
        "tunic_light": (54, 128, 68),
        "tunic_dark": (34, 82, 46),
        "scarf_hi": (205, 138, 72),
        "scarf_mid": (162, 98, 44),
        "scarf_dark": (110, 62, 28),
    },
    # 2: Iron Knight Plate (Bright Steel Silver + Royal Blue cape/scarf)
    {
        "tunic_light": (178, 192, 210),
        "tunic_dark": (116, 132, 152),
        "scarf_hi": (88, 160, 245),
        "scarf_mid": (50, 112, 210),
        "scarf_dark": (30, 72, 148),
    },
    # 3: Crimson Blood-Knight (Dark Obsidian + Crimson Blood-Red scarf)
    {
        "tunic_light": (64, 52, 74),
        "tunic_dark": (36, 28, 44),
        "scarf_hi": (245, 72, 86),
        "scarf_mid": (205, 34, 48),
        "scarf_dark": (132, 18, 30),
    },
    # 4: Legendary Demon-Slayer Paladin (Radiant Gold + Royal Violet scarf)
    {
        "tunic_light": (238, 194, 66),
        "tunic_dark": (174, 126, 28),
        "scarf_hi": (218, 108, 250),
        "scarf_mid": (172, 52, 216),
        "scarf_dark": (112, 28, 152),
    },
]


def recolor_base_layer(base_im, palette):
    if palette is None:
        return base_im.copy()
    im = base_im.copy()
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 64:
                continue
            # Dark outline / eyes (very dark near-black) -> keep untouched
            if r < 30 and g < 30 and b < 45:
                continue
            # Blue tunic pixels: b significantly greater than r, cool blue slate
            if b > r + 12 and r < 95 and g < 115:
                if b >= 82 or g >= 58:
                    px[x, y] = (*palette["tunic_light"], a)
                else:
                    px[x, y] = (*palette["tunic_dark"], a)
            # Red scarf/trim pixels on base layer ONLY (never touch peach skin tones where g >= 95!)
            elif r > 130 and g < 85 and b < 90:
                if r >= 225 and g >= 85:
                    px[x, y] = (*palette["scarf_hi"], a)
                elif r >= 200:
                    px[x, y] = (*palette["scarf_mid"], a)
                else:
                    px[x, y] = (*palette["scarf_dark"], a)
    return im


def build_hero_sprites():
    print("=== Building 5 Hero Armor Tier Sprites ===")
    anims = [
        ("IDLE", "idle", 9, False),
        ("WALKING", "walk", 8, False),
        ("RUN", "run", 8, False),
        ("ATTACK", "attack", 10, True),
        ("ROLL", "roll", 10, False),
        ("DIG", "dig", 13, True),
        ("WATERING", "watering", 5, True),
        ("AXE", "axe", 10, True),
        ("MINING", "mining", 10, True),
        ("REELING", "reeling", 13, True),
        ("HURT", "hurt", 8, False),
        ("DEATH", "death", 13, False),
    ]
    zpath = os.path.join(DL_DIR, "Sunnyside_World_ARCHIVED_ASSETS.zip")
    with zipfile.ZipFile(zpath, "r") as outer:
        with zipfile.ZipFile(io.BytesIO(outer.read("SUNNYSIDE_WORLD_CHARACTERS_PARTS_V0.3.1.zip")), "r") as nz:
            names = set(nz.namelist())
            for folder, anim, n, use_tools in anims:
                prefix = f"SUNNYSIDE_WORLD_CHARACTERS_PARTS_V0.3.1/{folder}/"
                b_key = f"{prefix}base_{anim}_strip{n}.png"
                h_key = f"{prefix}spikeyhair_{anim}_strip{n}.png"
                t_key = f"{prefix}tools_{anim}_strip{n}.png"
                if b_key not in names or h_key not in names:
                    raise FileNotFoundError(f"Missing hero strip: {b_key} or {h_key}")
                base_im = Image.open(io.BytesIO(nz.read(b_key))).convert("RGBA")
                hair_im = Image.open(io.BytesIO(nz.read(h_key))).convert("RGBA")
                tools_im = Image.open(io.BytesIO(nz.read(t_key))).convert("RGBA") if (use_tools and t_key in names) else None

                for tier_idx, pal in enumerate(HERO_SKINS):
                    recolored = recolor_base_layer(base_im, pal)
                    comp = Image.alpha_composite(recolored, hair_im)
                    if tools_im is not None:
                        comp = Image.alpha_composite(comp, tools_im)
                    save_img("hero", f"hero{tier_idx}_{anim}.png", comp)


# ------------------------------------------------------------------------------
# 2. REAL ANIMATED BOSSES (Tiny RPG Demon_A & Blood Monster_A)
# ------------------------------------------------------------------------------
def build_boss_sprites():
    print("=== Extracting Boss Sprites ===")
    zpath = os.path.join(DL_DIR, "Tiny RPG Character Asset Pack 02 v1.01-Free Demon_A&Blood Monster_A.zip")
    base = "Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/"
    mapping = [
        ("Demon_A/Demon_A with shadows/Demon_A_Idle.png", "demon_idle.png"),
        ("Demon_A/Demon_A with shadows/Demon_A_Walk.png", "demon_walk.png"),
        ("Demon_A/Demon_A with shadows/Demon_A_Attack01.png", "demon_atk1.png"),
        ("Demon_A/Demon_A with shadows/Demon_A_Attack02.png", "demon_atk2.png"),
        ("Demon_A/Demon_A with shadows/Demon_A_Hurt.png", "demon_hurt.png"),
        ("Demon_A/Demon_A with shadows/Demon_A_Death.png", "demon_death.png"),
        ("Blood Monster_A/Blood Monster_A with shadows/Blood Monster_A_Idle.png", "blood_idle.png"),
        ("Blood Monster_A/Blood Monster_A with shadows/Blood Monster_A_Walk.png", "blood_walk.png"),
        ("Blood Monster_A/Blood Monster_A with shadows/Blood Monster_A_Attack01.png", "blood_atk1.png"),
        ("Blood Monster_A/Blood Monster_A with shadows/Blood Monster_A_Attack02.png", "blood_atk2.png"),
        ("Blood Monster_A/Blood Monster_A with shadows/Blood Monster_A_Hurt.png", "blood_hurt.png"),
        ("Blood Monster_A/Blood Monster_A with shadows/Blood Monster_A_Death.png", "blood_death.png"),
    ]
    with zipfile.ZipFile(zpath, "r") as z:
        for src, dst in mapping:
            save_bytes("bosses", dst, z.read(base + src))


# ------------------------------------------------------------------------------
# 3. PIXEL CRAWLER ENEMIES, 6TH VILLAGER (LINA), CLEAN STATIONS & WINDMILL TOWER
# ------------------------------------------------------------------------------
def build_pixel_crawler_v3():
    print("=== Extracting Pixel Crawler Mobs, Villager & Clean Stations ===")
    zpath = os.path.join(DL_DIR, "Pixel Crawler - Free Pack (Exterior 0.1).zip")
    p = "Pixel Crawler - Free Pack/"
    with zipfile.ZipFile(zpath, "r") as z:
        # Enemy variants
        mobs = [
            ("Entities/Mobs/Orc Crew/Orc - Warrior/Idle/Idle-Sheet.png", "orc_war_idle.png"),
            ("Entities/Mobs/Orc Crew/Orc - Warrior/Run/Run-Sheet.png", "orc_war_run.png"),
            ("Entities/Mobs/Orc Crew/Orc - Warrior/Death/Death-Sheet.png", "orc_war_death.png"),
            ("Entities/Mobs/Orc Crew/Orc - Rogue/Idle/Idle-Sheet.png", "orc_rog_idle.png"),
            ("Entities/Mobs/Orc Crew/Orc - Rogue/Run/Run-Sheet.png", "orc_rog_run.png"),
            ("Entities/Mobs/Orc Crew/Orc - Rogue/Death/Death-Sheet.png", "orc_rog_death.png"),
            ("Entities/Mobs/Orc Crew/Orc - Shaman/Idle/Idle-Sheet.png", "orc_sha_idle.png"),
            ("Entities/Mobs/Orc Crew/Orc - Shaman/Run/Run-Sheet.png", "orc_sha_run.png"),
            ("Entities/Mobs/Orc Crew/Orc - Shaman/Death/Death-Sheet.png", "orc_sha_death.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Warrior/Idle/Idle-Sheet.png", "skel_war_idle.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Warrior/Run/Run-Sheet.png", "skel_war_run.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Warrior/Death/Death-Sheet.png", "skel_war_death.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Mage/Idle/Idle-Sheet.png", "skel_mag_idle.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Mage/Run/Run-Sheet.png", "skel_mag_run.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Mage/Death/Death-Sheet.png", "skel_mag_death.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Rogue/Idle/Idle-Sheet.png", "skel_rog_idle.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Rogue/Run/Run-Sheet.png", "skel_rog_run.png"),
            ("Entities/Mobs/Skeleton Crew/Skeleton - Rogue/Death/Death-Sheet.png", "skel_rog_death.png"),
        ]
        for src, dst in mobs:
            save_bytes("mobs", dst, z.read(p + src))

        # 6th Villager: Lina (Tavern_B)
        save_bytes("npcs", "tavern_b_idle.png", z.read(p + "Entities/Npc's/Citizen_F/Tavern_B/Idle/Idle_Side-Sheet.png"))
        save_bytes("npcs", "tavern_b_walk.png", z.read(p + "Entities/Npc's/Citizen_F/Tavern_B/Walk/Walk_Side-Sheet.png"))

        # Clean Stations
        cooking_sheet = Image.open(io.BytesIO(z.read(p + "Environment/Structures/Stations/Cooking Station/Cooking Station.png"))).convert("RGBA")
        # Row 0, col 1: stone firepit + spit + fire (cleanly inside x=68..138, y=10..74)
        save_img("env", "station_cooking.png", cooking_sheet.crop((68, 10, 138, 74)))

        alc_sheet = Image.open(io.BytesIO(z.read(p + "Environment/Structures/Stations/Alchemy/Alchemy_Table_01-Sheet.png"))).convert("RGBA")
        # Row 0: 6 frames of 32x64 (192x64)
        save_img("env", "station_alchemy.png", alc_sheet.crop((0, 0, 192, 64)))

        anvil_sheet = Image.open(io.BytesIO(z.read(p + "Environment/Structures/Stations/Anvil/Anvil.png"))).convert("RGBA")
        # Middle iron blacksmith anvil & workbench stall (76..168, 30..112) -> 92x82
        save_img("env", "station_forge.png", anvil_sheet.crop((76, 30, 168, 112)))

        # Dungeon Tilesets & Props
        for dn in ["Environment/Tilesets/Dungeon_Tiles.png", "Environment/Tilesets/Wall_Tiles.png", "Environment/Props/Static/Dungeon_Props.png"]:
            save_bytes("env", os.path.basename(dn), z.read(p + dn))

        # Windmill Tower composite (64x104) matching house_farm aesthetic
        walls = Image.open(io.BytesIO(z.read(p + "Environment/Structures/Buildings/Walls.png"))).convert("RGBA")
        roofs = Image.open(io.BytesIO(z.read(p + "Environment/Structures/Buildings/Roofs.png"))).convert("RGBA")
        props = Image.open(io.BytesIO(z.read(p + "Environment/Structures/Buildings/Props.png"))).convert("RGBA")

        tower = Image.new("RGBA", (72, 112), (0, 0, 0, 0))
        # Warm timber wall tile (x=112..144, y=184..240 -> 32x56)
        w_mid = walls.crop((112, 184, 144, 240))
        w_left = walls.crop((0, 184, 16, 240))
        w_right = walls.crop((16, 184, 32, 240))
        # Tile lower & upper tower body across x=12..60 (width 48)
        for wy in [52, 28]:
            tower.paste(w_left, (8, wy), w_left)
            tower.paste(w_mid, (20, wy), w_mid)
            tower.paste(w_right, (48, wy), w_right)
        # Compact pitched brown gable roof (take left & right halves of brown roof and stitch to 72px width)
        r_left = roofs.crop((0, 6, 36, 62))
        r_right = roofs.crop((92, 6, 128, 62))
        tower.paste(r_left, (0, 0), r_left)
        tower.paste(r_right, (36, 0), r_right)
        # Ridge beam cap in center (flush with roof peak)
        r_cap = roofs.crop((60, 20, 68, 52))
        tower.paste(r_cap, (32, 14), r_cap)
        # Door & window
        door = props.crop((101, 29, 123, 64))
        win = props.crop((101, 64, 123, 94))
        tower.paste(door, (25, 76), door)
        tower.paste(win, (25, 42), win)
        save_img("farm", "windmill_tower.png", tower)


# ------------------------------------------------------------------------------
# 4. LUSH TERRAIN TILES STRIP (32 tiles x 16x16 = 512x16) + FURROWED SOIL
# ------------------------------------------------------------------------------
def warm_soil_tile(wet=False):
    im = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    px = im.load()
    base = (82, 50, 32) if wet else (136, 94, 58)
    furrow = (58, 34, 22) if wet else (106, 68, 38)
    hi = (98, 62, 40) if wet else (154, 110, 72)
    for y in range(16):
        for x in range(16):
            if x == 0 or x == 15 or y == 0 or y == 15:
                px[x, y] = (*furrow, 255)
            elif y % 4 == 1:
                px[x, y] = (*furrow, 255)
            elif y % 4 == 2:
                px[x, y] = (*hi, 255) if (x + y) % 5 != 0 else (*base, 255)
            else:
                px[x, y] = (*base, 255) if (x * 7 + y * 13) % 11 != 0 else (*furrow, 255)
    return im


def build_terrain_tiles():
    print("=== Building Terrain Tiles Strip (32 x 16x16) ===")
    sunny = Image.open(os.path.join(OUT_BASE, "farm/tileset_sunnyside.png")).convert("RGBA")
    floors = Image.open(os.path.join(OUT_BASE, "env/Floors_Tiles.png")).convert("RGBA")
    water = Image.open(os.path.join(OUT_BASE, "env/Water_tiles.png")).convert("RGBA")
    dungeon = Image.open(os.path.join(OUT_BASE, "env/Dungeon_Tiles.png")).convert("RGBA")

    tiles = []
    # 0..5: Sunnyside lush meadow grass (0=clean base repeated for calm look + subtle tufts)
    g_coords = [(16, 16), (16, 16), (16, 32), (32, 32), (48, 32), (64, 32)]
    for gx, gy in g_coords:
        tiles.append(sunny.crop((gx, gy, gx + 16, gy + 16)))

    # 6..8: Warm earthy dirt path (from Floors_Tiles softened & slightly warmed)
    for i in range(3):
        t = floors.crop((176 + i * 16, 160, 192 + i * 16, 176))
        t = ImageEnhance.Brightness(t).enhance(1.12)
        tiles.append(t)

    # 9..11: Village cobblestone
    for i in range(3):
        tiles.append(floors.crop((96 + i * 16, 160, 112 + i * 16, 176)))

    # 12..14: Village plaza brick
    for i in range(3):
        tiles.append(floors.crop((256 + i * 16, 16, 272 + i * 16, 32)))

    # 15..16: Warm golden sand (Sunnyside)
    tiles.append(sunny.crop((112, 16, 128, 32)))
    tiles.append(sunny.crop((128, 16, 144, 32)))

    # 17..18: Sparkling azure water frames (Pixel Crawler rippled water brightened)
    tiles.append(ImageEnhance.Brightness(water.crop((16, 112, 32, 128))).enhance(1.12))
    tiles.append(ImageEnhance.Brightness(water.crop((16, 192, 32, 208))).enhance(1.12))

    # 19..20: Winter snow (solid snow row y=352 in Floors_Tiles)
    tiles.append(floors.crop((32, 352, 48, 368)))
    tiles.append(floors.crop((48, 352, 64, 368)))

    # 21..23: Dark mossy shadow forest grass
    for i in range(3):
        t = floors.crop((16 + i * 16, 160, 32 + i * 16, 176))
        t = ImageEnhance.Color(ImageEnhance.Brightness(t).enhance(0.82)).enhance(0.78)
        tiles.append(t)

    # 24..26: Dungeon slate floor (interior tiles without edge lip)
    for dx, dy in [(80, 16), (96, 16), (80, 32)]:
        tiles.append(dungeon.crop((dx, dy, dx + 16, dy + 16)))

    # 27: Bloodstained dungeon floor
    tiles.append(dungeon.crop((144, 192, 160, 208)))

    # 28: Royal crimson carpet tile
    tiles.append(dungeon.crop((86, 176, 102, 192)))

    # 29: Glowing crimson rune grate
    tiles.append(dungeon.crop((16, 304, 32, 320)))

    # 30..31: Furrowed farm soil dry & wet
    tiles.append(warm_soil_tile(False))
    tiles.append(warm_soil_tile(True))

    strip = Image.new("RGBA", (len(tiles) * 16, 16), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        strip.paste(t, (i * 16, 0))
    save_img("env", "terrain_tiles.png", strip)


# ------------------------------------------------------------------------------
# 5. EXTRA SUPER PIXEL EFFECTS (Guaranteed 1-row horizontal strips!)
# ------------------------------------------------------------------------------
def build_extra_fx():
    print("=== Stitching Extra Combat & Boss VFX Strips ===")
    zpath = os.path.join(DL_DIR, "Super Pixel Effects Gigapack (Free Version) v3.2.0.zip")
    targets = {
        "fx_explosion.png": "epic_explosion_001/epic_explosion_001_small_orange/",
        "fx_lightning.png": "lightning_strike_001/lightning_strike_001_small_violet/",
        "fx_slash.png": "directional_impact_002/directional_impact_002_small_white/",
        "fx_buff.png": "spell_attack_up_001/spell_attack_up_001_small_red/",
        "fx_skull.png": "stylized_skull_smoke_burst_001/stylized_skull_smoke_burst_001_small_white/",
    }
    with zipfile.ZipFile(zpath, "r") as z:
        names = z.namelist()
        for out_name, match_sub in targets.items():
            frames = sorted([n for n in names if "/PNG/" in n and match_sub in n and n.endswith(".png")])
            if not frames:
                raise FileNotFoundError(f"Missing FX folder in zip: {match_sub}")
            imgs = [Image.open(io.BytesIO(z.read(f))).convert("RGBA") for f in frames]
            fw, fh = imgs[0].size
            strip = Image.new("RGBA", (fw * len(imgs), fh), (0, 0, 0, 0))
            for i, im in enumerate(imgs):
                strip.paste(im, (i * fw, 0))
            save_img("fx", out_name, strip)


if __name__ == "__main__":
    build_hero_sprites()
    build_boss_sprites()
    build_pixel_crawler_v3()
    build_terrain_tiles()
    build_extra_fx()
    print("ALL V3 ASSETS BUILT SUCCESSFULLY!")
