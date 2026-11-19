import math
import struct
import wave
import os
from PIL import Image, ImageDraw

BASE_DIR = r"C:\Users\roy\.gemini\antigravity\scratch\cozy_haven"
SPRITES_DIR = os.path.join(BASE_DIR, "assets", "sprites")
UI_DIR = os.path.join(BASE_DIR, "assets", "ui")
SFX_DIR = os.path.join(BASE_DIR, "assets", "sfx")

# Palette definition (cozy, warm, vibrant pixel-art palette)
P = {
    "black": (24, 20, 37),
    "dark_brown": (68, 36, 52),
    "mid_brown": (138, 72, 54),
    "light_brown": (191, 111, 74),
    "sand": (230, 169, 120),
    "cream": (246, 214, 189),
    "spring_grass_light": (138, 194, 74),
    "spring_grass_dark": (90, 143, 44),
    "summer_grass_light": (98, 186, 68),
    "summer_grass_dark": (50, 128, 48),
    "fall_grass_light": (214, 144, 48),
    "fall_grass_dark": (153, 90, 30),
    "winter_grass_light": (225, 238, 245),
    "winter_grass_dark": (168, 190, 205),
    "tilled_dry": (115, 62, 42),
    "tilled_dry_dark": (84, 42, 28),
    "tilled_wet": (58, 28, 20),
    "tilled_wet_dark": (38, 16, 12),
    "water_light": (91, 190, 230),
    "water_mid": (48, 130, 204),
    "water_dark": (30, 75, 140),
    "wood_plank": (166, 107, 73),
    "wood_dark": (112, 65, 45),
    "stone_light": (160, 165, 175),
    "stone_dark": (105, 110, 125),
    
    # Items & Plants
    "red": (224, 60, 70),
    "pink": (242, 138, 160),
    "leaf_green": (78, 180, 72),
    "leaf_dark": (40, 115, 48),
    "yellow": (250, 205, 60),
    "orange": (245, 125, 45),
    "glow_blue": (80, 225, 255),
    "glow_purple": (175, 95, 245),
    "white": (255, 255, 255),
    
    # Metals
    "iron": (195, 200, 210),
    "iron_dark": (130, 135, 145),
    "gold": (245, 195, 45),
    "gold_dark": (185, 130, 25),
}

def create_tiles():
    # 32x32 tiles, spritesheet of 8x4 tiles (256 x 128)
    sheet = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    def draw_grass(ox, oy, c_light, c_dark, flowers=None):
        draw.rectangle([ox, oy, ox+31, oy+31], fill=c_light)
        # grass blades
        for (gx, gy) in [(4, 6), (12, 18), (22, 8), (18, 24), (26, 20), (8, 26)]:
            draw.line([(ox+gx, oy+gy), (ox+gx, oy+gy+2)], fill=c_dark)
            draw.point((ox+gx-1, oy+gy+1), fill=c_dark)
        if flowers:
            for (fx, fy, col) in flowers:
                draw.rectangle([ox+fx, oy+fy, ox+fx+1, oy+fy+1], fill=col)
                draw.point((ox+fx, oy+fy-1), fill=P["white"])

    # Row 0: Spring Grass, Summer Grass, Autumn Grass, Winter Snow, Tilled Dry, Tilled Wet, Wood Floor, Stone Path
    draw_grass(0, 0, P["spring_grass_light"], P["spring_grass_dark"], [(6, 10, P["pink"]), (20, 22, P["yellow"])])
    draw_grass(32, 0, P["summer_grass_light"], P["summer_grass_dark"], [(10, 8, P["red"]), (24, 16, P["yellow"])])
    draw_grass(64, 0, P["fall_grass_light"], P["fall_grass_dark"], [(8, 14, P["orange"]), (22, 24, P["red"])])
    draw_grass(96, 0, P["winter_grass_light"], P["winter_grass_dark"], [(12, 12, P["glow_blue"])])

    # Tilled dry
    draw.rectangle([128, 0, 159, 31], fill=P["tilled_dry"])
    for y in range(4, 28, 6):
        draw.line([(130, y), (157, y)], fill=P["tilled_dry_dark"])
        draw.line([(130, y+1), (157, y+1)], fill=P["tilled_dry"])

    # Tilled wet
    draw.rectangle([160, 0, 191, 31], fill=P["tilled_wet"])
    for y in range(4, 28, 6):
        draw.line([(162, y), (189, y)], fill=P["tilled_wet_dark"])
        draw.point((170, y+2), fill=P["water_light"])
        draw.point((182, y+2), fill=P["water_light"])

    # Wood floor
    draw.rectangle([192, 0, 223, 31], fill=P["wood_plank"])
    for y in range(0, 32, 8):
        draw.line([(192, y), (223, y)], fill=P["wood_dark"])
        draw.point((198, y+4), fill=P["wood_dark"])
        draw.point((215, y+4), fill=P["wood_dark"])

    # Stone path
    draw.rectangle([224, 0, 255, 31], fill=P["spring_grass_light"])
    for (sx, sy, sw, sh) in [(226, 4, 12, 10), (240, 2, 12, 12), (228, 16, 11, 12), (242, 18, 10, 10)]:
        draw.rectangle([sx, sy, sx+sw, sy+sh], fill=P["stone_light"])
        draw.rectangle([sx, sy, sx+sw, sy+sh], outline=P["stone_dark"])

    # Row 1: Water (frame 0, 1), Fence, Well, Tree Trunk, Leaves, Bridge
    # Water 0
    draw.rectangle([0, 32, 31, 63], fill=P["water_mid"])
    for y in [38, 48, 56]:
        draw.line([(4, y), (14, y)], fill=P["water_light"])
        draw.line([(18, y+4), (28, y+4)], fill=P["water_light"])
    # Water 1 (sparkle)
    draw.rectangle([32, 32, 63, 63], fill=P["water_mid"])
    for y in [36, 46, 58]:
        draw.line([(8, y), (18, y)], fill=P["water_light"])
        draw.line([(2, y+4), (10, y+4)], fill=P["water_light"])
        draw.point((22, y+2), fill=P["white"])

    # Fence
    draw.rectangle([64, 32, 95, 63], fill=(0, 0, 0, 0))
    # Vertical posts
    draw.rectangle([68, 38, 74, 60], fill=P["wood_plank"], outline=P["wood_dark"])
    draw.rectangle([86, 38, 92, 60], fill=P["wood_plank"], outline=P["wood_dark"])
    # Horizontal rails
    draw.rectangle([64, 42, 95, 46], fill=P["wood_plank"], outline=P["wood_dark"])
    draw.rectangle([64, 52, 95, 56], fill=P["wood_plank"], outline=P["wood_dark"])

    # Water Well
    draw.rectangle([96, 32, 127, 63], fill=(0, 0, 0, 0))
    draw.ellipse([100, 42, 124, 62], fill=P["stone_light"], outline=P["stone_dark"])
    draw.ellipse([104, 46, 120, 58], fill=P["water_dark"])
    draw.point((108, 50), fill=P["water_light"])
    # Well roof posts & top
    draw.line([(102, 44), (102, 34)], fill=P["wood_dark"], width=2)
    draw.line([(122, 44), (122, 34)], fill=P["wood_dark"], width=2)
    draw.line([(98, 34), (126, 34)], fill=P["red"], width=3)

    # Shipping Bin
    draw.rectangle([128, 32, 159, 63], fill=(0, 0, 0, 0))
    draw.rectangle([132, 40, 156, 60], fill=P["wood_plank"], outline=P["wood_dark"])
    draw.rectangle([130, 36, 158, 42], fill=P["red"], outline=P["dark_brown"])
    draw.rectangle([142, 44, 146, 48], fill=P["gold"], outline=P["gold_dark"])

    # Bush / Tree
    draw.rectangle([160, 32, 191, 63], fill=(0, 0, 0, 0))
    draw.ellipse([162, 34, 189, 61], fill=P["leaf_green"], outline=P["leaf_dark"])
    draw.ellipse([166, 38, 178, 50], fill=P["spring_grass_light"])
    for (bx, by) in [(170, 52), (180, 42), (184, 50)]:
        draw.rectangle([bx, by, bx+2, by+2], fill=P["red"]) # berries in bush

    # Magical Shrine / Spirit Monument
    draw.rectangle([192, 32, 223, 63], fill=(0, 0, 0, 0))
    draw.rectangle([198, 46, 218, 62], fill=P["stone_dark"], outline=P["black"])
    draw.rectangle([202, 38, 214, 46], fill=P["stone_light"], outline=P["stone_dark"])
    # Glowing rune
    draw.line([(206, 50), (210, 50)], fill=P["glow_blue"], width=2)
    draw.line([(208, 48), (208, 58)], fill=P["glow_blue"], width=2)
    draw.point((204, 42), fill=P["glow_purple"])

    sheet.save(os.path.join(SPRITES_DIR, "tiles.png"))
    print("Tiles created.")

def create_player():
    # 32x32 frames, 4 directions (Down, Up, Left, Right)
    # 4 columns: Idle, Walk1, Walk2, Action
    # 4 rows: Down (0), Up (1), Left (2), Right (3)
    sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    def draw_character(col, row, dir_name, state):
        ox = col * 32
        oy = row * 32

        # Shadow
        draw.ellipse([ox+8, oy+26, ox+24, oy+31], fill=(20, 20, 30, 80))

        # Leg offset for walk animation
        leg_l_y = 0
        leg_r_y = 0
        if state == "walk1":
            leg_l_y = -2
            leg_r_y = 1
        elif state == "walk2":
            leg_l_y = 1
            leg_r_y = -2

        # Pants / Legs
        draw.rectangle([ox+11, oy+20+leg_l_y, ox+14, oy+28], fill=P["water_dark"])
        draw.rectangle([ox+17, oy+20+leg_r_y, ox+20, oy+28], fill=P["water_dark"])
        # Shoes
        draw.rectangle([ox+10, oy+26+leg_l_y, ox+14, oy+29], fill=P["dark_brown"])
        draw.rectangle([ox+17, oy+26+leg_r_y, ox+21, oy+29], fill=P["dark_brown"])

        # Shirt & Overalls
        draw.rectangle([ox+10, oy+12, ox+21, oy+21], fill=P["red"]) # Red flannel shirt
        # Denim overall bib
        draw.rectangle([ox+12, oy+14, ox+19, oy+21], fill=P["water_mid"])
        # Suspender straps
        draw.line([(ox+12, oy+12), (ox+12, oy+14)], fill=P["water_mid"], width=1)
        draw.line([(ox+19, oy+12), (ox+19, oy+14)], fill=P["water_mid"], width=1)

        # Head & Face
        draw.rectangle([ox+10, oy+4, ox+21, oy+12], fill=P["cream"]) # skin
        
        if dir_name == "down":
            # Eyes
            draw.rectangle([ox+12, oy+8, ox+13, oy+10], fill=P["black"])
            draw.rectangle([ox+18, oy+9, ox+19, oy+10], fill=P["black"])
            # Blush
            draw.point((ox+11, oy+10), fill=P["pink"])
            draw.point((ox+20, oy+10), fill=P["pink"])
            # Smile
            draw.point((ox+15, oy+11), fill=P["dark_brown"])
            draw.point((ox+16, oy+11), fill=P["dark_brown"])
        elif dir_name == "up":
            # Back of head hair
            draw.rectangle([ox+10, oy+5, ox+21, oy+12], fill=P["mid_brown"])
        elif dir_name == "left":
            draw.rectangle([ox+11, oy+8, ox+12, oy+10], fill=P["black"])
            draw.point((ox+10, oy+10), fill=P["pink"])
        elif dir_name == "right":
            draw.rectangle([ox+19, oy+8, ox+20, oy+10], fill=P["black"])
            draw.point((ox+21, oy+10), fill=P["pink"])

        # Hair & Cozy Straw Hat!
        # Hair bangs
        draw.line([(ox+10, oy+4), (ox+21, oy+4)], fill=P["mid_brown"], width=2)
        # Straw hat brim
        draw.ellipse([ox+6, oy+1, ox+25, oy+7], fill=P["sand"], outline=P["light_brown"])
        # Straw hat crown
        draw.rectangle([ox+11, oy-1, ox+20, oy+3], fill=P["sand"], outline=P["light_brown"])
        # Hat ribbon
        draw.line([(ox+11, oy+2), (ox+20, oy+2)], fill=P["leaf_green"], width=1)

        # Action (tool use frame)
        if state == "action":
            # Hoe / tool swing visual
            draw.line([(ox+22, oy+8), (ox+28, oy+24)], fill=P["wood_dark"], width=2)
            draw.rectangle([ox+26, oy+22, ox+30, oy+26], fill=P["iron"])

    dirs = ["down", "up", "left", "right"]
    states = ["idle", "walk1", "idle", "walk2"]
    for row, d in enumerate(dirs):
        for col, s in enumerate(states):
            draw_character(col, row, d, s)

    sheet.save(os.path.join(SPRITES_DIR, "player.png"))
    print("Player created.")

def create_items():
    # 16x16 or 32x32 item icons. Let's make 32x32 icons in an 8x4 sheet (256x128)
    sheet = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    def draw_item_bg(x, y):
        pass # transparent

    # 1. Tools: Hoe (0,0), Watering Can (1,0), Fishing Rod (2,0), Axe (3,0), Scythe (4,0)
    # Hoe
    draw.line([(8, 24), (22, 10)], fill=P["wood_dark"], width=2)
    draw.polygon([(20, 6), (26, 12), (24, 15), (18, 9)], fill=P["iron"], outline=P["iron_dark"])
    # Watering can (32, 0)
    draw.rectangle([40, 14, 54, 26], fill=P["water_mid"], outline=P["water_dark"])
    draw.line([(54, 18), (60, 10)], fill=P["water_dark"], width=2) # spout
    draw.ellipse([58, 8, 62, 12], fill=P["water_light"]) # sprinkler head
    draw.line([(42, 14), (42, 8), (50, 8), (50, 14)], fill=P["water_dark"], width=2) # handle
    draw.point((56, 20), fill=P["water_light"])
    # Fishing Rod (64, 0)
    draw.line([(70, 26), (88, 6)], fill=P["wood_plank"], width=2)
    draw.line([(88, 6), (92, 18)], fill=P["white"], width=1) # line
    draw.ellipse([90, 18, 94, 22], fill=P["red"]) # bobber
    # Axe (96, 0)
    draw.line([(104, 24), (118, 8)], fill=P["wood_dark"], width=2)
    draw.polygon([(114, 6), (124, 6), (120, 14), (112, 12)], fill=P["iron"], outline=P["iron_dark"])
    # Scythe (128, 0)
    draw.line([(136, 26), (146, 8)], fill=P["wood_dark"], width=2)
    draw.arc([140, 4, 156, 20], start=180, end=330, fill=P["iron"], width=3)

    # 2. Seeds & Bags: Strawberry Seeds (160, 0), Corn Seeds (192, 0), Pumpkin Seeds (224, 0)
    def draw_seed_bag(ox, oy, color):
        draw.polygon([(ox+10, oy+12), (ox+22, oy+12), (ox+24, oy+26), (ox+8, oy+26)], fill=P["sand"], outline=P["light_brown"])
        draw.line([(ox+10, oy+12), (ox+22, oy+12)], fill=P["mid_brown"], width=2)
        draw.ellipse([ox+13, oy+16, ox+19, oy+22], fill=color)

    draw_seed_bag(160, 0, P["red"]) # Strawberry
    draw_seed_bag(192, 0, P["yellow"]) # Corn
    draw_seed_bag(224, 0, P["orange"]) # Pumpkin

    # 3. Harvested Crops: Strawberry (0, 32), Corn (32, 32), Pumpkin (64, 32), Frostberry (96, 32)
    # Strawberry
    draw.polygon([(10, 42), (22, 42), (16, 56)], fill=P["red"], outline=P["dark_brown"])
    for (sx, sy) in [(13, 45), (18, 46), (15, 50)]:
        draw.point((sx, sy), fill=P["yellow"])
    draw.polygon([(12, 42), (16, 38), (20, 42)], fill=P["leaf_green"]) # leaf top

    # Corn
    draw.rectangle([42, 40, 52, 56], fill=P["yellow"], outline=P["gold_dark"])
    draw.polygon([(38, 48), (44, 58), (42, 44)], fill=P["leaf_green"])
    draw.polygon([(56, 48), (50, 58), (52, 44)], fill=P["leaf_green"])

    # Pumpkin
    draw.ellipse([70, 40, 90, 58], fill=P["orange"], outline=P["dark_brown"])
    draw.line([(76, 40), (76, 58)], fill=P["fall_grass_dark"])
    draw.line([(84, 40), (84, 58)], fill=P["fall_grass_dark"])
    draw.rectangle([78, 36, 82, 42], fill=P["leaf_dark"]) # stem

    # Frostberry (Winter special crop!)
    draw.polygon([(106, 44), (112, 38), (118, 44), (112, 54)], fill=P["glow_blue"], outline=P["white"])
    draw.point((112, 44), fill=P["white"])
    draw.point((112, 48), fill=P["water_light"])

    # 4. Forageables: Chanterelle Mushroom (128, 32), Bioluminescent Glowcap (160, 32), Wild Truffle (192, 32), Wood Log (224, 32)
    # Red Chanterelle
    draw.rectangle([140, 48, 144, 58], fill=P["cream"]) # stem
    draw.ellipse([134, 40, 150, 50], fill=P["red"]) # cap
    for (mx, my) in [(138, 43), (144, 42), (146, 46)]:
        draw.point((mx, my), fill=P["white"])

    # Glowing Mooncap Mushroom
    draw.rectangle([172, 48, 176, 58], fill=P["winter_grass_light"])
    draw.ellipse([166, 40, 182, 50], fill=P["glow_purple"])
    draw.point((172, 44), fill=P["glow_blue"])
    draw.point((176, 43), fill=P["white"])

    # Wild Truffle
    draw.ellipse([198, 46, 214, 58], fill=P["dark_brown"], outline=P["black"])
    draw.point((204, 50), fill=P["mid_brown"])

    # Wood Log
    draw.rectangle([230, 46, 250, 56], fill=P["wood_plank"], outline=P["wood_dark"])
    draw.ellipse([228, 46, 234, 56], fill=P["light_brown"], outline=P["wood_dark"])

    # 5. Fish: River Trout (0, 64), Rainbow Sunfish (32, 64), Mystic Moon-Eel (64, 64), Golden Koi (96, 64)
    # Trout
    draw.ellipse([6, 74, 24, 84], fill=P["stone_light"], outline=P["stone_dark"])
    draw.polygon([(22, 79), (28, 73), (28, 85)], fill=P["stone_dark"])
    draw.point((9, 77), fill=P["black"])
    draw.point((14, 78), fill=P["pink"])

    # Sunfish
    draw.ellipse([38, 72, 54, 86], fill=P["yellow"], outline=P["orange"])
    draw.polygon([(52, 79), (60, 72), (60, 86)], fill=P["red"])
    draw.point((42, 77), fill=P["black"])

    # Mystic Moon-Eel
    draw.arc([68, 72, 88, 88], start=45, end=270, fill=P["glow_blue"], width=4)
    draw.polygon([(86, 75), (92, 72), (90, 80)], fill=P["glow_purple"])
    draw.point((72, 84), fill=P["white"])

    # Golden Koi
    draw.ellipse([102, 74, 120, 84], fill=P["gold"], outline=P["gold_dark"])
    draw.polygon([(118, 79), (124, 73), (124, 85)], fill=P["orange"])
    draw.point((105, 77), fill=P["black"])

    # Stone / Ore
    draw.polygon([(134, 84), (142, 72), (152, 76), (150, 86), (138, 88)], fill=P["stone_light"], outline=P["stone_dark"])

    # Spirit Tear / Essence (Unique Game Mechanic Item!)
    draw.polygon([(174, 72), (168, 82), (174, 88), (180, 82)], fill=P["glow_blue"], outline=P["white"])
    draw.point((174, 78), fill=P["white"])

    sheet.save(os.path.join(SPRITES_DIR, "items.png"))
    print("Items created.")

def create_crops_growth():
    # 32x32 tiles for crop growth stages
    # 4 crops x 4 stages = 16 tiles (128 x 128)
    # Stage 0: Seed/Sprout, Stage 1: Small leaf, Stage 2: Flowering/Growing, Stage 3: Ready to Harvest
    sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    def draw_sprout(ox, oy):
        draw.line([(ox+16, oy+28), (ox+16, oy+22)], fill=P["leaf_dark"], width=2)
        draw.line([(ox+16, oy+22), (ox+13, oy+20)], fill=P["leaf_green"], width=2)
        draw.line([(ox+16, oy+22), (ox+19, oy+20)], fill=P["leaf_green"], width=2)

    def draw_mid(ox, oy, color=None):
        draw.line([(ox+16, oy+28), (ox+16, oy+18)], fill=P["leaf_dark"], width=2)
        draw.ellipse([ox+10, oy+16, ox+16, oy+22], fill=P["leaf_green"])
        draw.ellipse([ox+16, oy+16, ox+22, oy+22], fill=P["leaf_green"])
        if color:
            draw.ellipse([ox+14, oy+14, ox+18, oy+18], fill=color)

    # Row 0: Strawberry (Stages 0, 1, 2, 3)
    draw_sprout(0, 0)
    draw_mid(32, 0)
    draw_mid(64, 0, P["pink"])
    # Mature Strawberry bush
    draw.ellipse([98, 14, 124, 28], fill=P["leaf_green"], outline=P["leaf_dark"])
    draw.polygon([(104, 20), (108, 20), (106, 25)], fill=P["red"])
    draw.polygon([(114, 18), (118, 18), (116, 24)], fill=P["red"])
    draw.polygon([(110, 22), (114, 22), (112, 27)], fill=P["red"])

    # Row 1: Corn (Stages 0, 1, 2, 3)
    draw_sprout(0, 32)
    draw_mid(32, 32)
    draw.line([(80, 60), (80, 42)], fill=P["leaf_dark"], width=2)
    draw.ellipse([72, 44, 88, 56], fill=P["leaf_green"])
    # Mature tall corn
    draw.line([(112, 60), (112, 36)], fill=P["leaf_dark"], width=3)
    draw.ellipse([104, 40, 120, 54], fill=P["leaf_green"])
    draw.rectangle([110, 42, 115, 52], fill=P["yellow"], outline=P["gold_dark"])

    # Row 2: Pumpkin (Stages 0, 1, 2, 3)
    draw_sprout(0, 64)
    draw_mid(32, 64)
    draw.ellipse([70, 78, 86, 92], fill=P["leaf_green"])
    draw.ellipse([74, 82, 82, 90], fill=P["fall_grass_light"])
    # Mature Pumpkin
    draw.ellipse([100, 72, 124, 92], fill=P["orange"], outline=P["dark_brown"])
    draw.line([(106, 72), (106, 92)], fill=P["fall_grass_dark"])
    draw.line([(116, 72), (116, 92)], fill=P["fall_grass_dark"])
    draw.rectangle([110, 68, 114, 74], fill=P["leaf_dark"])

    # Row 3: Frostberry (Stages 0, 1, 2, 3)
    draw_sprout(0, 96)
    draw_mid(32, 96, P["water_light"])
    draw.ellipse([74, 108, 86, 120], fill=P["water_mid"])
    draw.point((80, 114), fill=P["white"])
    # Mature Glowing Frostberry
    draw.ellipse([102, 104, 122, 124], fill=P["glow_blue"], outline=P["white"])
    draw.ellipse([108, 108, 116, 118], fill=P["glow_purple"])
    draw.point((110, 112), fill=P["white"])

    sheet.save(os.path.join(SPRITES_DIR, "crops.png"))
    print("Crops created.")

def create_npcs():
    # 2 NPC sprites (Ayla the herbalist, Bram the fisherman, and Pip the Forest Spirit!)
    # Sheet: 96 x 64
    sheet = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)

    # Ayla (0, 0) - Green dress, floral crown, brown hair, gentle smile
    draw.ellipse([8, 26, 24, 31], fill=(20, 20, 30, 80)) # shadow
    draw.polygon([(10, 28), (22, 28), (20, 16), (12, 16)], fill=P["leaf_green"]) # dress
    draw.rectangle([13, 14, 19, 18], fill=P["cream"]) # apron
    draw.rectangle([11, 6, 21, 14], fill=P["cream"]) # face
    draw.rectangle([13, 9, 14, 11], fill=P["black"])
    draw.rectangle([18, 9, 19, 11], fill=P["black"])
    draw.point((12, 11), fill=P["pink"])
    draw.point((20, 11), fill=P["pink"])
    # Flower crown
    draw.rectangle([10, 4, 22, 7], fill=P["mid_brown"]) # hair
    draw.point((12, 5), fill=P["pink"])
    draw.point((16, 4), fill=P["yellow"])
    draw.point((20, 5), fill=P["white"])

    # Bram (32, 0) - Fisherman with yellow raincoat, blue beanie, ginger beard
    draw.ellipse([40, 26, 56, 31], fill=(20, 20, 30, 80))
    draw.rectangle([42, 14, 54, 28], fill=P["yellow"], outline=P["gold_dark"]) # raincoat
    draw.rectangle([43, 6, 53, 14], fill=P["sand"]) # face
    draw.rectangle([43, 10, 53, 15], fill=P["orange"]) # big cozy beard!
    draw.rectangle([45, 8, 46, 10], fill=P["black"])
    draw.rectangle([50, 8, 51, 10], fill=P["black"])
    draw.rectangle([42, 3, 54, 7], fill=P["water_mid"]) # beanie
    draw.point((48, 2), fill=P["white"]) # pompom

    # Pip (64, 0) - Glowing Forest Spirit!
    draw.ellipse([70, 8, 90, 26], fill=P["glow_blue"])
    draw.ellipse([74, 12, 86, 22], fill=P["white"])
    # Cute big eyes
    draw.ellipse([75, 14, 78, 18], fill=P["black"])
    draw.ellipse([82, 14, 85, 18], fill=P["black"])
    draw.point((76, 15), fill=P["white"])
    draw.point((83, 15), fill=P["white"])
    # Sprout on head
    draw.line([(80, 8), (80, 4)], fill=P["leaf_green"], width=2)
    draw.ellipse([78, 2, 84, 5], fill=P["leaf_green"])

    sheet.save(os.path.join(SPRITES_DIR, "npcs.png"))
    print("NPCs created.")

def create_portraits():
    # 64x64 portrait images for dialogue
    for name, create_fn in [("ayla", draw_ayla_portrait), ("bram", draw_bram_portrait), ("pip", draw_pip_portrait)]:
        img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        create_fn(draw)
        img.save(os.path.join(UI_DIR, f"portrait_{name}.png"))
    print("Portraits created.")

def draw_ayla_portrait(draw):
    # Warm wooden border & cozy background
    draw.rectangle([2, 2, 61, 61], fill=P["cream"], outline=P["dark_brown"], width=2)
    # Hair
    draw.ellipse([14, 10, 50, 50], fill=P["mid_brown"])
    # Shoulders
    draw.ellipse([10, 42, 54, 75], fill=P["leaf_green"], outline=P["leaf_dark"])
    # Face
    draw.ellipse([20, 18, 44, 46], fill=P["cream"])
    # Big sparkling anime eyes
    draw.ellipse([24, 28, 28, 34], fill=P["spring_grass_dark"])
    draw.point((25, 29), fill=P["white"])
    draw.ellipse([36, 28, 40, 34], fill=P["spring_grass_dark"])
    draw.point((37, 29), fill=P["white"])
    # Blush
    draw.ellipse([22, 34, 27, 37], fill=P["pink"])
    draw.ellipse([37, 34, 42, 37], fill=P["pink"])
    # Gentle smile
    draw.arc([29, 36, 35, 41], start=0, end=180, fill=P["dark_brown"], width=2)
    # Floral crown
    for (fx, fy, col) in [(20, 16, P["pink"]), (28, 14, P["yellow"]), (36, 14, P["white"]), (44, 16, P["pink"])]:
        draw.ellipse([fx, fy, fx+5, fy+5], fill=col)

def draw_bram_portrait(draw):
    draw.rectangle([2, 2, 61, 61], fill=P["winter_grass_light"], outline=P["dark_brown"], width=2)
    # Shoulders
    draw.ellipse([8, 40, 56, 75], fill=P["yellow"], outline=P["gold_dark"])
    # Face
    draw.ellipse([18, 18, 46, 46], fill=P["sand"])
    # Blue Beanie
    draw.rectangle([16, 8, 48, 20], fill=P["water_mid"])
    draw.ellipse([28, 4, 36, 10], fill=P["white"]) # pompom
    # Eyes & Eyebrows
    draw.line([(22, 24), (28, 26)], fill=P["orange"], width=2)
    draw.line([(36, 26), (42, 24)], fill=P["orange"], width=2)
    draw.rectangle([24, 27, 27, 30], fill=P["black"])
    draw.rectangle([37, 27, 40, 30], fill=P["black"])
    # Big friendly ginger beard
    draw.ellipse([18, 32, 46, 52], fill=P["orange"], outline=P["fall_grass_dark"])
    # Round nose
    draw.ellipse([29, 29, 35, 34], fill=P["light_brown"])

def draw_pip_portrait(draw):
    draw.rectangle([2, 2, 61, 61], fill=P["black"], outline=P["glow_purple"], width=2)
    # Glowing magical aura
    for r in range(24, 16, -2):
        draw.ellipse([32-r, 34-r, 32+r, 34+r], fill=(80, 225, 255, 40))
    # Body
    draw.ellipse([18, 20, 46, 48], fill=P["glow_blue"])
    draw.ellipse([22, 24, 42, 44], fill=P["white"])
    # Big sparkling cute eyes
    draw.ellipse([25, 28, 30, 36], fill=P["black"])
    draw.ellipse([34, 28, 39, 36], fill=P["black"])
    draw.point((26, 30), fill=P["white"])
    draw.point((35, 30), fill=P["white"])
    # Little blush dots
    draw.point((24, 36), fill=P["pink"])
    draw.point((40, 36), fill=P["pink"])
    # Sprout
    draw.line([(32, 20), (32, 10)], fill=P["leaf_green"], width=3)
    draw.ellipse([28, 6, 38, 12], fill=P["leaf_green"])

def create_ui_assets():
    # 1. Cozy 9-patch frame for dialogue and windows (48x48)
    frame = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    fdraw = ImageDraw.Draw(frame)
    # Outer dark wood border
    fdraw.rectangle([0, 0, 47, 47], fill=P["cream"], outline=P["dark_brown"], width=3)
    # Inner gold border
    fdraw.rectangle([3, 3, 44, 44], outline=P["sand"], width=1)
    # Corner rivets
    for (cx, cy) in [(4, 4), (43, 4), (4, 43), (43, 43)]:
        fdraw.point((cx, cy), fill=P["gold"])
    frame.save(os.path.join(UI_DIR, "panel_frame.png"))

    # 2. Hotbar slot (36x36)
    slot = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(slot)
    sdraw.rectangle([0, 0, 35, 35], fill=(40, 30, 25, 220), outline=P["sand"], width=2)
    slot.save(os.path.join(UI_DIR, "slot_normal.png"))

    # Selected slot (36x36) with glowing gold frame
    slot_sel = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    ssdraw = ImageDraw.Draw(slot_sel)
    ssdraw.rectangle([0, 0, 35, 35], fill=(60, 45, 30, 240), outline=P["gold"], width=3)
    ssdraw.rectangle([2, 2, 33, 33], outline=P["yellow"], width=1)
    slot_sel.save(os.path.join(UI_DIR, "slot_selected.png"))

    # 3. Season icons: 24x24
    for season, color, sym in [
        ("spring", P["pink"], "blossom"),
        ("summer", P["yellow"], "sun"),
        ("fall", P["orange"], "leaf"),
        ("winter", P["glow_blue"], "snowflake")
    ]:
        icon = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
        idraw = ImageDraw.Draw(icon)
        idraw.ellipse([2, 2, 21, 21], fill=color, outline=P["dark_brown"], width=2)
        if sym == "blossom":
            idraw.point((12, 12), fill=P["white"])
        elif sym == "sun":
            idraw.ellipse([8, 8, 15, 15], fill=P["red"])
        elif sym == "leaf":
            idraw.line([(8, 16), (16, 8)], fill=P["red"], width=2)
        elif sym == "snowflake":
            idraw.line([(12, 6), (12, 18)], fill=P["white"], width=2)
            idraw.line([(6, 12), (18, 12)], fill=P["white"], width=2)
        icon.save(os.path.join(UI_DIR, f"icon_{season}.png"))

    # 4. Heart icons for NPC friendship
    heart = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(heart)
    hdraw.polygon([(8, 14), (2, 8), (2, 4), (5, 2), (8, 4), (11, 2), (14, 4), (14, 8)], fill=P["red"], outline=P["dark_brown"])
    heart.save(os.path.join(UI_DIR, "heart_full.png"))

    # Empty heart
    heart_empty = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    hedraw = ImageDraw.Draw(heart_empty)
    hedraw.polygon([(8, 14), (2, 8), (2, 4), (5, 2), (8, 4), (11, 2), (14, 4), (14, 8)], fill=(60, 50, 50, 160), outline=P["dark_brown"])
    heart_empty.save(os.path.join(UI_DIR, "heart_empty.png"))

    # Coin icon (16x16)
    coin = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(coin)
    cdraw.ellipse([2, 2, 13, 13], fill=P["gold"], outline=P["gold_dark"], width=1)
    cdraw.rectangle([6, 5, 9, 10], fill=P["yellow"])
    coin.save(os.path.join(UI_DIR, "coin.png"))

    print("UI assets created.")

def create_sfx():
    sample_rate = 22050

    def write_wav(filename, samples):
        path = os.path.join(SFX_DIR, filename)
        with wave.open(path, "w") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(sample_rate)
            data = struct.pack(f"<{len(samples)}h", *samples)
            wav.writeframes(data)

    def generate_sound(duration_sec, fn):
        n_samples = int(duration_sec * sample_rate)
        samples = []
        for i in range(n_samples):
            t = i / sample_rate
            val = fn(t, duration_sec)
            val = max(-1.0, min(1.0, val))
            samples.append(int(val * 32767 * 0.8))
        return samples

    # 1. Dig / Hoe sound (crunchy low pitch thump)
    def sfx_hoe(t, dur):
        decay = math.exp(-t * 25)
        noise = (math.sin(t * 12345.67) % 1.0) * 2 - 1
        tone = math.sin(2 * math.pi * 90 * t)
        return decay * (0.6 * noise + 0.4 * tone)
    write_wav("hoe.wav", generate_sound(0.18, sfx_hoe))

    # 2. Water splash
    def sfx_water(t, dur):
        decay = math.exp(-t * 12)
        noise = (math.sin(t * 54321.12) % 1.0) * 2 - 1
        bubble = math.sin(2 * math.pi * (400 + 300 * math.sin(t * 60)) * t)
        return decay * (0.5 * noise + 0.5 * bubble)
    write_wav("water.wav", generate_sound(0.25, sfx_water))

    # 3. Seed rustle
    def sfx_seed(t, dur):
        decay = math.exp(-t * 30)
        noise = (math.sin(t * 8888.8) % 1.0) * 2 - 1
        return decay * noise * 0.5
    write_wav("seed.wav", generate_sound(0.12, sfx_seed))

    # 4. Harvest cheer / chime (pleasant two-tone arpeggio)
    def sfx_harvest(t, dur):
        decay = math.exp(-t * 8)
        f = 523.25 if t < 0.1 else (659.25 if t < 0.2 else 783.99)
        tone = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(4 * math.pi * f * t)
        return decay * tone * 0.6
    write_wav("harvest.wav", generate_sound(0.35, sfx_harvest))

    # 5. Fish bite exclamation alert ("Ding-dong!")
    def sfx_bite(t, dur):
        decay = math.exp(-t * 15)
        f = 880 if t < 0.08 else 1174
        tone = math.sin(2 * math.pi * f * t)
        return decay * tone * 0.7
    write_wav("bite.wav", generate_sound(0.2, sfx_bite))

    # 6. Catch success fanfare
    def sfx_catch(t, dur):
        decay = math.exp(-t * 5)
        note = int(t * 12)
        freqs = [523.25, 659.25, 783.99, 1046.50]
        f = freqs[min(len(freqs)-1, note)]
        tone = math.sin(2 * math.pi * f * t) + 0.2 * math.sin(4 * math.pi * f * t)
        return decay * tone * 0.7
    write_wav("catch.wav", generate_sound(0.45, sfx_catch))

    # 7. Step grass
    def sfx_step(t, dur):
        decay = math.exp(-t * 40)
        noise = (math.sin(t * 9999.0) % 1.0) * 2 - 1
        return decay * noise * 0.25
    write_wav("step.wav", generate_sound(0.08, sfx_step))

    # 8. Dialogue text blip
    def sfx_blip(t, dur):
        decay = math.exp(-t * 60)
        tone = math.sin(2 * math.pi * 480 * t)
        return decay * tone * 0.4
    write_wav("blip.wav", generate_sound(0.05, sfx_blip))

    # 9. Inventory toggle
    def sfx_click(t, dur):
        decay = math.exp(-t * 50)
        tone = math.sin(2 * math.pi * 320 * t)
        return decay * tone * 0.5
    write_wav("click.wav", generate_sound(0.06, sfx_click))

    print("SFX created.")

if __name__ == "__main__":
    create_tiles()
    create_player()
    create_items()
    create_crops_growth()
    create_npcs()
    create_portraits()
    create_ui_assets()
    create_sfx()
    print("All game assets generated successfully!")
