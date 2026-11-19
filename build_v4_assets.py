import io
import os
import zipfile
from PIL import Image, ImageDraw

DL_DIR = r"C:\Users\roy\Downloads"
OUT_BASE = r"C:\Users\roy\.gemini\antigravity\scratch\cozy_haven\assets\real"
UI_DIR = os.path.join(OUT_BASE, "ui")
INT_DIR = os.path.join(OUT_BASE, "interior")

os.makedirs(UI_DIR, exist_ok=True)
os.makedirs(INT_DIR, exist_ok=True)


def save_png(directory, name, im):
    path = os.path.join(directory, name)
    im.save(path)
    print(f"  [OK] {os.path.basename(directory)}/{name:26s} {im.size}")


def trim_crop(im, box, pad=0):
    sub = im.crop(box).convert("RGBA")
    bb = sub.getbbox()
    if bb is None:
        return sub
    x0 = max(0, bb[0] - pad)
    y0 = max(0, bb[1] - pad)
    x1 = min(sub.width, bb[2] + pad)
    y1 = min(sub.height, bb[3] + pad)
    return sub.crop((x0, y0, x1, y1))


# ------------------------------------------------------------------------------
# 1. STARDEW-STYLE 9-SLICE PIXEL UI PANELS + SUNNYSIDE UI ICONS
# ------------------------------------------------------------------------------
def make_9slice_box(size, outer, bevel_hi, bevel_mid, bevel_lo, seam, fill, studs=None, inset_edge=None):
    w, h = size
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()

    for y in range(h):
        for x in range(w):
            # Rounded 2px corner cutout for organic pixel-art feel
            cx = min(x, w - 1 - x)
            cy = min(y, h - 1 - y)
            if (cx == 0 and cy == 0) or (cx == 1 and cy == 0) or (cx == 0 and cy == 1):
                continue

            d = min(x, y, w - 1 - x, h - 1 - y)
            if d == 0 or (cx <= 1 and cy <= 1):
                px[x, y] = outer
            elif d == 1:
                px[x, y] = bevel_hi if (y == 1 or x == 1) else bevel_lo
            elif d in (2, 3, 4):
                px[x, y] = bevel_mid
            elif d == 5:
                px[x, y] = seam
            else:
                px[x, y] = fill

    # Inner parchment vignette / highlight along d==6
    if inset_edge is not None:
        for y in range(6, h - 6):
            for x in range(6, w - 6):
                if x == 6 or y == 6 or x == w - 7 or y == h - 7:
                    px[x, y] = inset_edge

    # Optional 4 brass corner studs inside wood frame
    if studs is not None:
        s_hi, s_lo = studs
        for sx, sy in [(3, 3), (w - 5, 3), (3, h - 5), (w - 5, h - 5)]:
            px[sx, sy] = s_hi
            px[sx + 1, sy] = s_hi
            px[sx, sy + 1] = s_lo
            px[sx + 1, sy + 1] = s_lo

    return im


def build_ui_assets():
    print("=== Building V4 Stardew-Style UI Textures ===")
    # 1. Parchment Main Modal Frame (48x48, clean 12px 9-slice margin)
    parch = make_9slice_box(
        (48, 48),
        outer=(44, 24, 14, 255),
        bevel_hi=(212, 152, 92, 255),
        bevel_mid=(146, 86, 44, 255),
        bevel_lo=(92, 50, 24, 255),
        seam=(64, 34, 18, 255),
        fill=(244, 226, 188, 255),
        studs=((246, 206, 102, 255), (176, 122, 38, 255)),
        inset_edge=(226, 200, 152, 255),
    )
    save_png(UI_DIR, "panel_parchment.png", parch)

    # 2. Inner Card (Warm Tan Cream)
    card = make_9slice_box(
        (48, 48),
        outer=(130, 82, 46, 255),
        bevel_hi=(248, 232, 196, 255),
        bevel_mid=(214, 174, 120, 255),
        bevel_lo=(168, 120, 72, 255),
        seam=(188, 144, 92, 255),
        fill=(235, 211, 164, 255),
        studs=None,
        inset_edge=(245, 228, 188, 255),
    )
    save_png(UI_DIR, "panel_card.png", card)

    # 3. Highlighted Golden Card / Active Tab / Hover Button
    card_sel = make_9slice_box(
        (48, 48),
        outer=(148, 84, 20, 255),
        bevel_hi=(255, 244, 186, 255),
        bevel_mid=(232, 168, 60, 255),
        bevel_lo=(182, 114, 28, 255),
        seam=(204, 138, 42, 255),
        fill=(250, 230, 172, 255),
        studs=None,
        inset_edge=(255, 245, 208, 255),
    )
    save_png(UI_DIR, "panel_card_sel.png", card_sel)

    # 4. Compact Dark Walnut Wood HUD Frame (Sleek translucent-friendly dark espresso wood)
    wood_hud = make_9slice_box(
        (48, 48),
        outer=(32, 18, 10, 255),
        bevel_hi=(212, 154, 92, 255),
        bevel_mid=(132, 78, 40, 255),
        bevel_lo=(78, 42, 22, 255),
        seam=(42, 24, 14, 255),
        fill=(54, 33, 22, 238),
        studs=((240, 194, 88, 255), (168, 114, 34, 255)),
        inset_edge=(76, 48, 30, 238),
    )
    save_png(UI_DIR, "panel_wood_hud.png", wood_hud)

    # 5. Hotbar / Inventory Slot (Normal + Selected)
    slot_n = make_9slice_box(
        (48, 48),
        outer=(56, 32, 18, 255),
        bevel_hi=(184, 132, 82, 255),
        bevel_mid=(132, 86, 50, 255),
        bevel_lo=(88, 54, 30, 255),
        seam=(96, 62, 34, 255),
        fill=(206, 166, 118, 242),
        studs=None,
        inset_edge=(178, 138, 90, 242),
    )
    save_png(UI_DIR, "panel_slot.png", slot_n)

    slot_s = make_9slice_box(
        (48, 48),
        outer=(124, 72, 14, 255),
        bevel_hi=(255, 236, 132, 255),
        bevel_mid=(242, 184, 56, 255),
        bevel_lo=(186, 122, 26, 255),
        seam=(196, 136, 38, 255),
        fill=(248, 226, 168, 255),
        studs=None,
        inset_edge=(255, 242, 198, 255),
    )
    save_png(UI_DIR, "panel_slot_sel.png", slot_s)

    # 6. Extract Real Sunnyside UI Icons & Ribbon Pieces
    zpath = os.path.join(DL_DIR, "Sunnyside_World_ARCHIVED_ASSETS.zip")
    want = {
        "confirm": "ui_confirm.png",
        "cancel": "ui_cancel.png",
        "expression_love": "ui_heart.png",
        "expression_chat": "ui_chat.png",
        "expression_alerted": "ui_alert.png",
        "stopwatch": "ui_watch.png",
        "itemdisc_01": "ui_disc.png",
        "selectbox_tl": "ui_sel_tl.png",
        "selectbox_tr": "ui_sel_tr.png",
        "selectbox_bl": "ui_sel_bl.png",
        "selectbox_br": "ui_sel_br.png",
        "label_left": "ui_label_l.png",
        "label_middle": "ui_label_m.png",
        "label_right": "ui_label_r.png",
    }
    with zipfile.ZipFile(zpath, "r") as outer:
        with zipfile.ZipFile(io.BytesIO(outer.read("BETA Sunnyside World - Tileset_GameMaker.zip")), "r") as nz:
            names = sorted(nz.namelist())
            for folder, out_name in want.items():
                prefix = f"Sunnyside World - Tileset/sprites/{folder}/"
                matched = [n for n in names if n.startswith(prefix) and n.endswith(".png") and "/layers/" not in n]
                if not matched:
                    raise FileNotFoundError(f"Missing Sunnyside UI folder: {folder}")
                im = Image.open(io.BytesIO(nz.read(matched[0]))).convert("RGBA")
                save_png(UI_DIR, out_name, im)


# ------------------------------------------------------------------------------
# 2. COTTAGE INTERIOR FLOORS, WALLS, FURNITURE & DECOR (Pixel Crawler + Sunnyside)
# ------------------------------------------------------------------------------
def build_interior_assets():
    print("=== Building V4 Cottage Interior Assets ===")
    zpath = os.path.join(DL_DIR, "Pixel Crawler - Free Pack (Exterior 0.1).zip")
    with zipfile.ZipFile(zpath, "r") as z:
        iw = Image.open(io.BytesIO(z.read("Pixel Crawler - Free Pack/Environment/Structures/Buildings/Interior/Interior_Walls_01.png"))).convert("RGBA")
        ip = Image.open(io.BytesIO(z.read("Pixel Crawler - Free Pack/Environment/Structures/Buildings/Interior/Interior_Props_01.png"))).convert("RGBA")
        wb = Image.open(io.BytesIO(z.read("Pixel Crawler - Free Pack/Environment/Structures/Stations/Workbench/Workbench.png"))).convert("RGBA")

    # 1. Floor Strip (4 styles x 2 variants = 8 x 16x16 = 128x16)
    # Verified on grid_int_walls.png y=576..640
    floor_coords = [
        (16, 592), (32, 592),   # 0: Meşe Tahta
        (176, 592), (192, 592), # 1: Balıksırtı Parke
        (96, 592), (112, 592),  # 2: Taş Döşeme
        (256, 592), (272, 592), # 3: Altın Çam
    ]
    fstrip = Image.new("RGBA", (len(floor_coords) * 16, 16), (0, 0, 0, 0))
    for i, (fx, fy) in enumerate(floor_coords):
        tile = iw.crop((fx, fy, fx + 16, fy + 16))
        fstrip.paste(tile, (i * 16, 0))
    save_png(INT_DIR, "int_floors.png", fstrip)

    # 2. Wall Strips (clean interior wall face without black top cap)
    save_png(INT_DIR, "int_wall_0.png", iw.crop((496, 94, 544, 128)))
    save_png(INT_DIR, "int_wall_1.png", iw.crop((400, 94, 448, 128)))
    save_png(INT_DIR, "int_wall_2.png", iw.crop((112, 92, 160, 128)))

    # 3. Clean Trimmed Furniture & Props
    props = {
        "bed_single.png": trim_crop(ip, (0, 288, 32, 344)),
        "bed_double.png": trim_crop(ip, (32, 288, 80, 344)),
        "chest.png": trim_crop(ip, (176, 66, 208, 96)),
        "bookshelf.png": trim_crop(ip, (48, 96, 96, 146)),
        "table_round.png": trim_crop(ip, (80, 0, 114, 44)),
        "chair.png": trim_crop(ip, (64, 0, 80, 32)),
        "stool.png": trim_crop(ip, (96, 62, 112, 82)),
        "window.png": trim_crop(ip, (174, 170, 224, 212)),
        "door_int.png": trim_crop(ip, (226, 206, 268, 258)),
        "fireplace.png": trim_crop(ip, (270, 48, 322, 146)),
        "kitchen_stove.png": trim_crop(ip, (112, 0, 144, 54)),
        "kitchen_counter.png": trim_crop(ip, (112, 224, 210, 256)),
        "workbench.png": trim_crop(wb, (44, 56, 102, 114)),
        "rug_beige.png": trim_crop(ip, (448, 320, 496, 368)),
        "rug_green.png": trim_crop(ip, (334, 334, 384, 384)),
        "plant_0.png": trim_crop(ip, (16, 345, 34, 384)),
        "plant_1.png": trim_crop(ip, (34, 345, 50, 384)),
        "plant_2.png": trim_crop(ip, (66, 345, 82, 384)),
        "painting.png": trim_crop(ip, (80, 320, 100, 340)),
        "trophy_wolf.png": trim_crop(ip, (544, 0, 576, 28)),
        "trophy_bear.png": trim_crop(ip, (576, 0, 608, 28)),
        "wall_sword.png": trim_crop(ip, (96, 256, 130, 274)),
        "wall_axe.png": trim_crop(ip, (130, 256, 164, 274)),
    }
    for fname, im in props.items():
        save_png(INT_DIR, fname, im)

    # 4. Sunnyside Royal Carpet, Dog Bowl & Sunflower Pot
    ts = Image.open(os.path.join(OUT_BASE, "farm/tileset_sunnyside.png")).convert("RGBA")
    save_png(INT_DIR, "rug_royal.png", trim_crop(ts, (644, 560, 685, 608)))
    save_png(INT_DIR, "dog_bowl.png", trim_crop(ts, (800, 512, 816, 528)))
    save_png(INT_DIR, "sunflower_pot.png", trim_crop(ts, (832, 510, 848, 528)))


def build_contact_sheet():
    out = r"C:\Users\roy\.gemini\antigravity\brain\672e91ef-6b1b-4237-8d21-dfa26ce4b783\scratch"
    os.makedirs(out, exist_ok=True)
    sheet = Image.new("RGBA", (860, 540), (36, 30, 26, 255))
    dr = ImageDraw.Draw(sheet)

    x, y = 12, 18
    for nm in ["panel_parchment.png", "panel_card.png", "panel_card_sel.png", "panel_wood_hud.png", "panel_slot.png", "panel_slot_sel.png"]:
        im = Image.open(os.path.join(UI_DIR, nm)).convert("RGBA").resize((96, 96), Image.NEAREST)
        sheet.paste(im, (x, y), im)
        dr.text((x, y + 100), nm.replace("panel_", "").replace(".png", ""), fill=(255, 230, 150))
        x += 120

    # Floors & walls
    fl = Image.open(os.path.join(INT_DIR, "int_floors.png")).convert("RGBA")
    fl2 = fl.resize((fl.width * 2, fl.height * 2), Image.NEAREST)
    sheet.paste(fl2, (12, 146), fl2)
    dr.text((12, 130), "Floors 0..3", fill=(180, 255, 180))
    for wi in range(3):
        wm = Image.open(os.path.join(INT_DIR, f"int_wall_{wi}.png")).convert("RGBA").resize((64, 64), Image.NEAREST)
        sheet.paste(wm, (320 + wi * 80, 140), wm)
        dr.text((320 + wi * 80, 124), f"Wall {wi}", fill=(180, 230, 255))

    # Furniture
    fx, fy, row_h = 12, 236, 0
    for fn in sorted(os.listdir(INT_DIR)):
        if fn.startswith("int_"):
            continue
        im = Image.open(os.path.join(INT_DIR, fn)).convert("RGBA")
        im2 = im.resize((im.width * 2, im.height * 2), Image.NEAREST) if max(im.size) <= 64 else im
        if fx + im2.width > 840:
            fx = 12
            fy += row_h + 22
            row_h = 0
        sheet.paste(im2, (fx, fy), im2)
        dr.text((fx, fy + im2.height + 2), fn.replace(".png", ""), fill=(240, 235, 220))
        fx += max(im2.width + 14, 72)
        row_h = max(row_h, im2.height)

    out_p = os.path.join(out, "v4_ui_interior_verify.png")
    sheet.save(out_p)
    print("Contact sheet saved:", out_p)


if __name__ == "__main__":
    build_ui_assets()
    build_interior_assets()
    build_contact_sheet()
    print("ALL V4 ASSETS BUILT SUCCESSFULLY!")
