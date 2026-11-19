extends Node2D
# ==============================================================================
#  ÇAYIR VADİSİ (SPIRIT MEADOW) V3
#  Stardew Tarzı Çiftlik & Komşular + Aksiyon RPG (3 Boss, Zırh/Silah, Takla, Skill)
# ==============================================================================

const GameData = preload("res://scripts/GameData.gd")

const WORLD_W := 3600.0
const WORLD_H := 1600.0
const TILE_SIZE := 16
const TILE_COLS := 225
const TILE_ROWS := 100
const FARM_CELL := 24
const FARM_OX := 368.0
const FARM_OY := 464.0
const FARM_COLS := 10
const FARM_ROWS := 6

const SEASON_NAMES := ["İlkbahar", "Yaz", "Sonbahar", "Kış"]
const SAVE_PATH := "user://cayir_vadisi_save.json"
const SHADOW_X := 2224.0
const FORGE_POS := Vector2(1260, 505)
const WELL_POS := Vector2(530, 355)
const CRATE_POS := Vector2(590, 355)
const BOARD_POS := Vector2(1610, 515)
const FIRE_POS := Vector2(1610, 620)
const HOUSE_DOOR := Vector2(395, 355)

# Indoor Farmhouse Layout (480x336 cozy interior)
const HOUSE_RECT := Rect2(44, 114, 392, 190)
const HOUSE_EXIT_RECT := Rect2(212, 292, 56, 24)
const INT_BED_POS := Vector2(86, 154)
const INT_CHEST_POS := Vector2(134, 120)
const INT_BENCH_POS := Vector2(180, 124)
const INT_FIRE_POS := Vector2(236, 114)
const INT_KITCHEN_POS := Vector2(386, 132)
const INT_ALCHEMY_POS := Vector2(416, 198)
const INT_FORGE_POS := Vector2(78, 250)
const INT_DOG_BOWL := Vector2(168, 276)

# Warm Stardew UI Palette
const COL_INK := Color("2d1a0e")
const COL_INK_MUTED := Color("6e4326")
const COL_INK_GREEN := Color("246628")
const COL_INK_RED := Color("9c251c")
const COL_INK_GOLD := Color("8a5508")
const COL_CREAM := Color("fff2d4")
const COL_GOLD := Color("ffd66b")

const BOSS_ARENAS := [
	{"id": "grog", "pos": Vector2(1960, 195), "radius": 135.0, "label": "KUZEY HARABESİ — GROG (Sv.5)"},
	{"id": "korgath", "pos": Vector2(2680, 310), "radius": 155.0, "label": "KANLI MAHZEN — KORGATH (Sv.9)"},
	{"id": "malakor", "pos": Vector2(3260, 620), "radius": 175.0, "label": "CEHENNEM SUNAKI — MALAKOR (Sv.14)"},
	{"id": "void_emperor", "pos": Vector2(3400, 1100), "radius": 185.0, "label": "DERİN BOŞLUK BOYUTU — KADİM BOŞLUK HÜKÜMDARI (Sv.18)"},
]

const SEASON_MODS := [
	Color(0.98, 1.00, 0.96), # İlkbahar
	Color(1.00, 0.97, 0.89), # Yaz
	Color(0.99, 0.90, 0.80), # Sonbahar
	Color(0.88, 0.94, 1.00), # Kış
]

# ---------------- SPRITE REGISTRY & FONTS ----------------
var S := {}
var tex_cache := {}
var font_ui: Font
var font_bold: Font
var sfx := {}
var audio_pool: Array[AudioStreamPlayer] = []
var audio_idx := 0

# ---------------- SCENE NODES ----------------
var bg_layer: CanvasLayer
var bg_node: Node2D
var world: Node2D
var overlay_layer: CanvasLayer
var overlay: Node2D
var hud_layer: CanvasLayer
var hud: Node2D
var cam: Camera2D
var cmod: CanvasModulate
var light_tex: GradientTexture2D
var L_player: PointLight2D
var L_fire: PointLight2D
var L_farm: PointLight2D
var L_shrine: PointLight2D
var L_boss2: PointLight2D
var L_boss3: PointLight2D

# ---------------- WORLD TERRAIN & TIME STATE ----------------
var terrain_map: PackedByteArray
var t := 0.0
var season := 0
var day := 1
var year := 1
var hour := 7
var minute := 30
var time_acc := 0.0
var is_raining := false
var weather_particles: Array = []

# Game states: "title","play","inv","char","quest","social","dialog","gift","shop","tavern","alchemy","cook","smith","board","fishing","house_menu","chest","pause","dead"
var state := "title"
var title_sel := 0
var dead_t := 0.0
var cur_zone := ""
var shake := 0.0
var modal_sel := 0
var smith_tab := 0
var house_tab := 0
var seed_choice_idx := 0
var consumable_choice_idx := 0
var toast_msg := ""
var toast_t := 0.0
var toast_col := Color.WHITE

# ---------------- HOUSE INTERIOR & CUSTOMIZATION ----------------
var in_house := false
var house_fade := 0.0
var saved_outdoor_pos := Vector2(395, 377)
var house_upgrades := {}
var house_decor := {"floor": 0, "rug": 0, "wall": 0, "plants": true, "dining": true, "dog_corner": true, "wall_art": true}
var house_chest := {}
var well_rested := false

# ---------------- PLAYER, COMPANION, GEAR & SOCIAL ----------------
var p := {}
var dog := {}
var bone = null
var gear_bag: Array = []
var equipped := {"weapon": null, "armor": null, "shield": null, "ring": null}
var bag := {}
var npc_rel := {} # npc_id -> {pts, talked_today, gifted_today, gifts_given, reward_3, reward_6}
var active_npc_id := ""
var active_dialog := {"speaker": "", "role": "", "npc_id": "", "text": "", "after": ""}
var bosses_defeated := {} # boss_id -> bool
var boss_respawn_days := {} # boss_id -> day

# ---------------- ENTITIES & COMBAT ----------------
var farm_grid := {}
var animals: Array = []
var ground_drops: Array = []
var trees: Array = []
var rocks: Array = []
var forage_nodes: Array = []
var npcs: Array = []
var enemies: Array = []
var projectiles: Array = []
var lightning_zones: Array = []
var fxs: Array = []
var float_texts: Array = []
var fence_rects: Array[Rect2] = []
var solid_rects: Array[Rect2] = []
var clickable_rects: Array = []
var tree_spots_all: Array = []
var fishing := {"active": false, "fish": "fish_trout", "bar_y": 80.0, "bar_v": 0.0, "fish_y": 80.0, "fish_t": 80.0, "timer": 0.0, "prog": 35.0}
var story_step := 0
var story_prog := 0
var daily_quest := {}

# ---------------- TEST MODE ----------------
var test_mode := false
var test_timer := 0.0
var test_stage := 0

# ==============================================================================
#  INITIALIZATION & NODE SETUP
# ==============================================================================
func _ready() -> void:
	randomize()
	_setup_fonts()
	test_mode = OS.get_environment("SPIRIT_TEST") == "1"
	_build_terrain_map()
	_build_nodes()
	_build_sfx()
	_load_all_assets()
	_new_game()
	state = "title"
	title_sel = 0 if FileAccess.file_exists(SAVE_PATH) else 1
	get_tree().set_auto_accept_quit(false)
	if test_mode:
		print("[TEST] SPIRIT_TEST=1 V3 doğrulama başlıyor...")

func _setup_fonts() -> void:
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Trebuchet MS", "Tahoma", "Arial"])
	sf.font_weight = 600
	sf.oversampling = 2.0
	font_ui = sf

	var sb := SystemFont.new()
	sb.font_names = PackedStringArray(["Segoe UI", "Trebuchet MS", "Tahoma", "Arial"])
	sb.font_weight = 800
	sb.oversampling = 2.0
	font_bold = sb

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state != "title" and not test_mode:
			_save_game(true)
		get_tree().quit()

func _build_nodes() -> void:
	bg_layer = CanvasLayer.new()
	bg_layer.layer = -5
	add_child(bg_layer)
	bg_node = Node2D.new()
	bg_layer.add_child(bg_node)
	bg_node.draw.connect(_draw_bg)

	cmod = CanvasModulate.new()
	cmod.color = Color.WHITE
	add_child(cmod)

	world = Node2D.new()
	add_child(world)
	world.draw.connect(_draw_world)

	cam = Camera2D.new()
	cam.zoom = Vector2(2.0, 2.0)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(WORLD_W)
	cam.limit_bottom = int(WORLD_H)
	add_child(cam)
	cam.make_current()

	light_tex = GradientTexture2D.new()
	light_tex.width = 256
	light_tex.height = 256
	light_tex.fill = GradientTexture2D.FILL_RADIAL
	light_tex.fill_from = Vector2(0.5, 0.5)
	light_tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	light_tex.gradient = g

	L_player = _mk_light(Color(1.0, 0.94, 0.82), 0.55, 130.0)
	L_farm = _mk_light(Color(1.0, 0.80, 0.45), 0.75, 160.0)
	L_farm.position = Vector2(400, 360)
	L_fire = _mk_light(Color(1.0, 0.65, 0.30), 1.0, 210.0)
	L_fire.position = FIRE_POS
	L_shrine = _mk_light(Color(1.0, 0.85, 0.6), 0.0, 140.0)
	L_shrine.position = Vector2(340, 120)
	L_boss2 = _mk_light(Color(0.95, 0.25, 0.25), 0.95, 220.0)
	L_boss2.position = Vector2(2680, 310)
	L_boss3 = _mk_light(Color(1.0, 0.45, 0.18), 1.25, 260.0)
	L_boss3.position = Vector2(3260, 620)

	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 1
	overlay_layer.follow_viewport_enabled = true
	add_child(overlay_layer)
	overlay = Node2D.new()
	overlay_layer.add_child(overlay)
	overlay.draw.connect(_draw_overlay)

	hud_layer = CanvasLayer.new()
	hud_layer.layer = 2
	add_child(hud_layer)
	hud = Node2D.new()
	hud_layer.add_child(hud)
	hud.draw.connect(_draw_hud)

	for i in 12:
		var asp := AudioStreamPlayer.new()
		asp.volume_db = -8.0
		add_child(asp)
		audio_pool.append(asp)

func _mk_light(col: Color, energy: float, radius: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_tex
	l.color = col
	l.energy = energy
	l.texture_scale = radius * 2.0 / 256.0
	add_child(l)
	return l

# ==============================================================================
#  PRECOMPUTED TERRAIN MAP (225 x 100 TILES)
# ==============================================================================
func _build_terrain_map() -> void:
	terrain_map = PackedByteArray()
	terrain_map.resize(TILE_COLS * TILE_ROWS)
	for gy in TILE_ROWS:
		var wy := gy * TILE_SIZE + 8.0
		for gx in TILE_COLS:
			var wx := gx * TILE_SIZE + 8.0
			var wpos := Vector2(wx, wy)
			var tid := 0 # 0: Meadow Grass
			if gy >= 71:
				tid = 5 # Water
			elif gy >= 68:
				tid = 4 # Lake Sand
			elif wpos.distance_to(Vector2(3260, 620)) < 185.0:
				# Boss 3 Demon Fortress
				if wpos.distance_to(Vector2(3260, 620)) < 68.0 and (absf(wx - 3260) < 28 or absf(wy - 620) < 28):
					tid = 10 # Rune grate
				elif absf(wy - 620) <= 24.0 and wx < 3260:
					tid = 9 # Royal carpet
				else:
					tid = 7 # Dungeon slate
			elif wpos.distance_to(Vector2(2680, 310)) < 165.0:
				# Boss 2 Blood Crypt
				tid = 8 if wpos.distance_to(Vector2(2680, 310)) < 85.0 else 7
			elif wpos.distance_to(Vector2(1960, 195)) < 138.0:
				# Boss 1 Ancient Ruins
				tid = 2 # Cobblestone ruin
			elif wx >= 1456 and wx < 1856 and wy >= 448 and wy < 784:
				tid = 3 if (wx >= 1568 and wx < 1664 and wy >= 560 and wy < 672) else 2
			elif wx >= 1220 and wx < 1330 and wy >= 475 and wy < 565:
				tid = 2 # Forge patio
			elif (wy >= 416 and wy < 464 and wx >= 380 and wx < 1456) \
				or (wx >= 376 and wx < 424 and wy >= 340 and wy < 464) \
				or (wx >= 688 and wx < 752 and wy >= 608 and wy < 1104) \
				or (wx >= 1856 and wx < 3080 and wy >= 576 and wy < 624) \
				or (wx >= 1570 and wx < 1630 and wy >= 200 and wy < 448) \
				or (wy >= 175 and wy < 220 and wx >= 1570 and wx < 1960) \
				or (wx >= 2656 and wx < 2704 and wy >= 310 and wy < 580):
				tid = 1 # Dirt path
			elif wx >= SHADOW_X:
				tid = 6 # Shadow forest grass
			terrain_map[gy * TILE_COLS + gx] = tid

# ==============================================================================
#  ASSET LOADING
# ==============================================================================
func _img(rel: String) -> Image:
	var full := ProjectSettings.globalize_path("res://assets/real/" + rel)
	if FileAccess.file_exists(full):
		var im := Image.load_from_file(full)
		if im != null:
			im.convert(Image.FORMAT_RGBA8)
			return im
	return null

func _tex(im: Image) -> ImageTexture:
	var id := im.get_instance_id()
	if not tex_cache.has(id):
		tex_cache[id] = ImageTexture.create_from_image(im)
	return tex_cache[id]

func _reg(key: String, rel: String, fw := 0, fh := 0, rect := Rect2i(), count := 0, auto_anchor := true, fixed_pivot := Vector2(-1, -1)) -> void:
	var im := _img(rel)
	if im == null:
		printerr("MISSING ASSET: ", rel)
		return
	var r := rect if rect.size != Vector2i.ZERO else Rect2i(Vector2i.ZERO, im.get_size())
	var h := fh if fh > 0 else r.size.y
	var w := fw if fw > 0 else (r.size.x if count == 1 else h)
	var n := count if count > 0 else maxi(1, r.size.x / w)
	var ax := w / 2.0
	var ay := float(h)
	if fixed_pivot.x >= 0.0:
		ax = fixed_pivot.x
		ay = fixed_pivot.y
	elif auto_anchor:
		var used := im.get_region(Rect2i(r.position, Vector2i(mini(w, im.get_width() - r.position.x), mini(h, im.get_height() - r.position.y)))).get_used_rect()
		if used.size.x > 0:
			ax = used.position.x + used.size.x / 2.0
			ay = float(used.end.y)
	S[key] = {"t": _tex(im), "ox": r.position.x, "oy": r.position.y, "fw": w, "fh": h, "n": n, "ax": ax, "ay": ay}

func _load_all_assets() -> void:
	# 1. Clothed RPG Hero (5 Armor Tiers x 12 Animations, fixed 96x64 pivot (48, 40)!)
	for tier in 5:
		for anim in ["idle", "walk", "run", "attack", "roll", "dig", "watering", "axe", "mining", "reeling", "hurt", "death"]:
			_reg("hero%d_%s" % [tier, anim], "hero/hero%d_%s.png" % [tier, anim], 96, 64, Rect2i(), 0, false, Vector2(48.0, 40.0))

	# 2. Animated Bosses (100x100, fixed pivot (50, 60))
	for bkey in ["demon", "blood"]:
		for anim in ["idle", "walk", "atk1", "atk2", "hurt", "death"]:
			_reg("%s_%s" % [bkey, anim], "bosses/%s_%s.png" % [bkey, anim], 100, 100, Rect2i(), 0, false, Vector2(50.0, 60.0))

	# 3. NPCs (6 Villagers)
	_reg("npc_peasant_idle", "npcs/peasant_idle.png", 64, 64)
	_reg("npc_peasant_walk", "npcs/peasant_walk.png", 64, 64)
	_reg("npc_tavern_idle", "npcs/tavern_a_idle.png", 64, 64)
	_reg("npc_tavern_walk", "npcs/tavern_a_walk.png", 64, 64)
	_reg("npc_tavern_b_idle", "npcs/tavern_b_idle.png", 64, 64)
	_reg("npc_tavern_b_walk", "npcs/tavern_b_walk.png", 64, 64)
	_reg("npc_wizard_idle", "npcs/wizard_idle.png", 32, 32)
	_reg("npc_wizard_walk", "npcs/wizard_run.png", 64, 64)
	_reg("npc_knight_idle", "npcs/knight_idle.png", 32, 32)
	_reg("npc_knight_walk", "npcs/knight_run.png", 64, 64)
	_reg("npc_rogue_idle", "npcs/rogue_idle.png", 32, 32)
	_reg("npc_rogue_walk", "npcs/rogue_run.png", 64, 64)

	# 4. Full Enemy Classes
	_reg("orc_idle", "mobs/orc_idle.png", 32, 32)
	_reg("orc_run", "mobs/orc_run.png", 64, 64)
	_reg("orc_death", "mobs/orc_death.png", 64, 64)
	_reg("orc_rog_idle", "mobs/orc_rog_idle.png", 32, 32)
	_reg("orc_rog_run", "mobs/orc_rog_run.png", 64, 64)
	_reg("orc_rog_death", "mobs/orc_rog_death.png", 64, 64)
	_reg("orc_sha_idle", "mobs/orc_sha_idle.png", 32, 32)
	_reg("orc_sha_run", "mobs/orc_sha_run.png", 64, 64)
	_reg("orc_sha_death", "mobs/orc_sha_death.png", 64, 64)
	_reg("orc_war_idle", "mobs/orc_war_idle.png", 32, 32)
	_reg("orc_war_run", "mobs/orc_war_run.png", 64, 64)
	_reg("orc_war_death", "mobs/orc_war_death.png", 96, 80)

	_reg("skel_idle", "mobs/skel_idle.png", 32, 32)
	_reg("skel_run", "mobs/skel_run.png", 64, 64)
	_reg("skel_death", "mobs/skel_death.png", 64, 64)
	_reg("skel_war_idle", "mobs/skel_war_idle.png", 32, 32)
	_reg("skel_war_run", "mobs/skel_war_run.png", 64, 64)
	_reg("skel_war_death", "mobs/skel_war_death.png", 64, 48)
	_reg("skel_mag_idle", "mobs/skel_mag_idle.png", 32, 32)
	_reg("skel_mag_run", "mobs/skel_mag_run.png", 64, 64)
	_reg("skel_mag_death", "mobs/skel_mag_death.png", 64, 64)
	_reg("skel_rog_idle", "mobs/skel_rog_idle.png", 32, 32)
	_reg("skel_rog_run", "mobs/skel_rog_run.png", 64, 64)
	_reg("skel_rog_death", "mobs/skel_rog_death.png", 64, 64)

	# Sunnyside World mobs (96x64 frames, foot pivot 48,40)
	for mob in ["sgob", "sskel"]:
		for anim in ["idle", "walk", "run", "hurt", "death"]:
			if FileAccess.file_exists(ProjectSettings.globalize_path("res://assets/real/mobs/%s_%s.png" % [mob, anim])):
				_reg("%s_%s" % [mob, anim], "mobs/%s_%s.png" % [mob, anim], 96, 64, Rect2i(), 0, false, Vector2(48.0, 40.0))
		_reg("%s_atk1" % mob, "mobs/%s_attack.png" % mob, 96, 64, Rect2i(), 0, false, Vector2(48.0, 40.0))
		_reg("%s_atk2" % mob, "mobs/%s_attack.png" % mob, 96, 64, Rect2i(), 0, false, Vector2(48.0, 40.0))

	# 5. Animals & Karabaş
	_reg("chicken", "farm/chicken_strip.png", 32, 32)
	_reg("cow", "farm/cow_strip.png", 32, 32)
	_reg("sheep", "farm/sheep_strip.png", 32, 32)
	_reg("dog_karabas", "dog/Dogs.png", 64, 64, Rect2i(0, 192, 384, 64), 6)
	_reg("bone", "dog/DogItems.png", 23, 15, Rect2i(5, 8, 23, 15), 1)

	# 6. Clean Buildings & V3 Stations
	_reg("house_farm", "farm/house_farm.png", 128, 134)
	_reg("house_shop", "farm/house_shop.png", 128, 134)
	_reg("house_tavern", "farm/house_tavern.png", 128, 134)
	_reg("windmill_tower", "farm/windmill_tower.png", 72, 112)
	_reg("windmill", "farm/windmill_strip.png", 112, 112, Rect2i(), 0, false, Vector2(56.0, 56.0))
	_reg("smoke", "farm/chimney_smoke_strip.png", 15, 37)
	_reg("well", "farm/well.png", 20, 25)
	_reg("scarecrow", "farm/scarecrow.png", 32, 50)
	_reg("bench", "farm/bench.png", 58, 32)
	_reg("fence_h", "farm/fence_h.png", 32, 16)
	_reg("crate", "crops/crate_base.png", 16, 16)
	_reg("crate_top", "crops/crate_top.png", 16, 14)

	_reg("station_cooking", "env/station_cooking.png", 70, 64)
	_reg("station_alchemy", "env/station_alchemy.png", 32, 64)
	_reg("station_forge", "env/station_forge.png", 92, 82)
	_reg("bonfire", "env/bonfire.png", 32, 32)
	_reg("fire", "env/fire.png", 32, 48)
	_reg("dungeon_pillar", "env/Dungeon_Tiles.png", 32, 48, Rect2i(0, 224, 32, 48), 1)
	_reg("dungeon_gate", "env/Dungeon_Tiles.png", 32, 48, Rect2i(32, 112, 32, 48), 1)
	_reg("dungeon_banner", "env/Dungeon_Props.png", 16, 32, Rect2i(48, 32, 16, 32), 1)

	# 7. Crops
	for cname in ["parsnip", "carrot", "potato", "sunflower", "pumpkin", "cabbage"]:
		for st in 6:
			_reg("crop_%s_%d" % [cname, st], "crops/%s_0%d.png" % [cname, st])
	_reg("drop_egg", "crops/egg.png")
	_reg("drop_milk", "crops/milk.png")

	# 8. Trees & Nature
	_reg("oak_spring", "env/oak_tree.png", 48, 96, Rect2i(0, 0, 48, 96), 1)
	_reg("oak_summer", "env/oak_tree.png", 48, 96, Rect2i(48, 0, 48, 96), 1)
	_reg("oak_fall", "env/oak_tree.png", 48, 96, Rect2i(0, 96, 48, 96), 1)
	_reg("oak_winter", "env/oak_tree.png", 48, 96, Rect2i(144, 0, 48, 96), 1)
	_reg("pine", "env/pine_tree.png", 54, 103, Rect2i(68, 9, 54, 103), 1)

	_reg("bush_spring", "env/Vegetation.png", 29, 27, Rect2i(2, 5, 29, 27), 1)
	_reg("bush_summer", "env/Vegetation.png", 29, 27, Rect2i(50, 5, 29, 27), 1)
	_reg("bush_fall", "env/Vegetation.png", 29, 27, Rect2i(98, 5, 29, 27), 1)
	_reg("bush_winter", "env/Vegetation.png", 29, 27, Rect2i(146, 5, 29, 27), 1)
	_reg("mush_red", "env/Vegetation.png", 11, 14, Rect2i(3, 353, 11, 14), 1)
	_reg("mush_glow", "env/Vegetation.png", 11, 14, Rect2i(19, 353, 11, 14), 1)
	for fi in 4:
		_reg("flower_%d" % fi, "env/Vegetation.png", 7, 6, Rect2i(53, 373 + fi * 16, 7, 6), 1)

	_reg("rock_stone", "env/Rocks.png", 26, 27, Rect2i(131, 19, 26, 27), 1)
	_reg("rock_copper", "env/Rocks.png", 26, 27, Rect2i(35, 19, 26, 27), 1)
	_reg("rock_crystal", "env/Rocks.png", 12, 25, Rect2i(146, 279, 12, 25), 1)

	# 9. Unified Terrain Strip (32 x 16x16)
	_reg("terrain", "env/terrain_tiles.png", 16, 16, Rect2i(), 32, false)

	# 10. VFX Strips
	for fxn in ["fx_sparkle", "fx_heart", "fx_splat", "fx_hit", "fx_coin", "fx_heal", "fx_smoke", "fx_explosion", "fx_lightning", "fx_buff", "fx_skull"]:
		_reg(fxn, "fx/%s.png" % fxn, 0, 0, Rect2i(), 0, false)
	_reg("fx_slash", "fx/fx_slash.png", 70, 25, Rect2i(), 7, false, Vector2(35.0, 12.5))

	# 11. Items & Atlas
	_reg("items", "items/items_curated.png", 16, 16, Rect2i(), 47, false)
	_reg("atlas", "items/items_atlas.png", 16, 16, Rect2i(), 32, false)

	# 12. V4 Warm Stardew UI Assets (9-slice panels & pixel icons)
	for pair in [
		["ui_parchment", "ui/panel_parchment.png"],
		["ui_card", "ui/panel_card.png"],
		["ui_card_sel", "ui/panel_card_sel.png"],
		["ui_wood_hud", "ui/panel_wood_hud.png"],
		["ui_slot", "ui/panel_slot.png"],
		["ui_slot_sel", "ui/panel_slot_sel.png"],
		["ui_confirm", "ui/ui_confirm.png"],
		["ui_cancel", "ui/ui_cancel.png"],
		["ui_heart", "ui/ui_heart.png"],
		["ui_chat", "ui/ui_chat.png"],
		["ui_alert", "ui/ui_alert.png"],
		["ui_watch", "ui/ui_watch.png"],
		["ui_disc", "ui/ui_disc.png"],
		["ui_sel_tl", "ui/ui_sel_tl.png"],
		["ui_sel_tr", "ui/ui_sel_tr.png"],
		["ui_sel_bl", "ui/ui_sel_bl.png"],
		["ui_sel_br", "ui/ui_sel_br.png"],
		["ui_label_l", "ui/ui_label_l.png"],
		["ui_label_m", "ui/ui_label_m.png"],
		["ui_label_r", "ui/ui_label_r.png"],
	]:
		_reg(pair[0], pair[1], 0, 0, Rect2i(), 1, false)

	# 13. V4 Interior House Assets
	_reg("int_floors", "interior/int_floors.png", 16, 16, Rect2i(), 8, false)
	for nw in ["int_wall_0", "int_wall_1", "int_wall_2", "rug_beige", "rug_green", "rug_royal"]:
		_reg(nw, "interior/%s.png" % nw, 0, 0, Rect2i(), 1, false)
	for nf in [
		"bed_single", "bed_double", "chest", "bookshelf", "table_round", "chair", "stool",
		"window", "door_int", "fireplace", "kitchen_stove", "kitchen_counter", "workbench",
		"plant_0", "plant_1", "plant_2", "painting", "trophy_wolf", "trophy_bear",
		"wall_sword", "wall_axe", "dog_bowl", "sunflower_pot"
	]:
		_reg(nf, "interior/%s.png" % nf, 0, 0, Rect2i(), 1, true)

# ==============================================================================
#  PROCEDURAL RETRO SFX
# ==============================================================================
const SR := 22050
func _synth(parts: Array) -> AudioStreamWAV:
	var total := 0.0
	for pp in parts:
		total = maxf(total, pp[5] + pp[2])
	var n := int(total * SR) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	for pp in parts:
		var start := int(pp[5] * SR)
		var ln := int(pp[2] * SR)
		var ph := 0.0
		var prev := 0.0
		var f0: float = pp[1]
		var f1: float = maxf(30.0, pp[1] + pp[4])
		for i in ln:
			var k := float(i) / ln
			ph += f0 * pow(f1 / f0, k) / SR
			var fr := fmod(ph, 1.0)
			var v := 0.0
			if pp[0] == "sq": v = 1.0 if fr < 0.5 else -1.0
			elif pp[0] == "saw": v = fr * 2.0 - 1.0
			elif pp[0] == "tri": v = 1.0 - 4.0 * absf(fr - 0.5)
			else:
				var r := randf() * 2.0 - 1.0
				v = (r - prev) * 0.7 if f0 > 1000.0 else r
				prev = r
			var j := start + i
			if j < n:
				buf[j] += v * pp[3] * pow(1.0 - k, 2.0) * 3.0
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 28000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.data = bytes
	return w

func _build_sfx() -> void:
	sfx["hoe"] = _synth([["noise", 700.0, 0.1, 0.14, -400.0, 0.0], ["sq", 110.0, 0.08, 0.08, -40.0, 0.0]])
	sfx["water"] = _synth([["noise", 1600.0, 0.18, 0.10, -800.0, 0.0], ["tri", 420.0, 0.15, 0.06, 220.0, 0.0]])
	sfx["seed"] = _synth([["noise", 2200.0, 0.07, 0.08, 0.0, 0.0]])
	sfx["harvest"] = _synth([["tri", 523.0, 0.08, 0.08, 0.0, 0.0], ["tri", 659.0, 0.08, 0.08, 0.0, 0.07], ["tri", 784.0, 0.14, 0.08, 0.0, 0.14]])
	sfx["coin"] = _synth([["sq", 987.0, 0.06, 0.05, 0.0, 0.0], ["sq", 1318.0, 0.12, 0.05, 0.0, 0.06]])
	sfx["bite"] = _synth([["sq", 880.0, 0.08, 0.08, 0.0, 0.0], ["sq", 1174.0, 0.12, 0.08, 0.0, 0.08]])
	sfx["catch"] = _synth([["tri", 523.0, 0.1, 0.08, 0.0, 0.0], ["tri", 659.0, 0.1, 0.08, 0.0, 0.1], ["tri", 784.0, 0.1, 0.08, 0.0, 0.2], ["tri", 1046.0, 0.25, 0.09, 0.0, 0.3]])
	sfx["bark"] = _synth([["saw", 500.0, 0.07, 0.07, -280.0, 0.0], ["saw", 460.0, 0.08, 0.06, -250.0, 0.10]])
	sfx["slash"] = _synth([["noise", 1900.0, 0.1, 0.12, 0.0, 0.0]])
	sfx["hit"] = _synth([["sq", 160.0, 0.08, 0.08, -90.0, 0.0], ["noise", 500.0, 0.05, 0.08, 0.0, 0.0]])
	sfx["blip"] = _synth([["tri", 720.0, 0.03, 0.04, 0.0, 0.0]])
	sfx["click"] = _synth([["tri", 440.0, 0.04, 0.05, 0.0, 0.0]])
	sfx["levelup"] = _synth([["sq", 523.0, 0.09, 0.06, 0.0, 0.0], ["sq", 659.0, 0.09, 0.06, 0.0, 0.09], ["sq", 784.0, 0.09, 0.06, 0.0, 0.18], ["sq", 1046.0, 0.3, 0.07, 0.0, 0.27], ["tri", 1568.0, 0.3, 0.05, 0.0, 0.27]])
	sfx["swing"] = _synth([["noise", 2600.0, 0.09, 0.07, 0.0, 0.0], ["tri", 300.0, 0.06, 0.04, -120.0, 0.0]])
	sfx["crit"] = _synth([["sq", 220.0, 0.1, 0.1, -120.0, 0.0], ["noise", 900.0, 0.08, 0.1, 0.0, 0.0], ["sq", 1320.0, 0.08, 0.05, 0.0, 0.03]])
	sfx["boss"] = _synth([["saw", 90.0, 0.6, 0.12, -40.0, 0.0], ["saw", 135.0, 0.6, 0.08, -60.0, 0.0]])
	sfx["roll"] = _synth([["noise", 1200.0, 0.12, 0.07, -700.0, 0.0], ["tri", 260.0, 0.1, 0.05, -100.0, 0.0]])
	sfx["heart"] = _synth([["tri", 659.0, 0.07, 0.07, 0.0, 0.0], ["tri", 988.0, 0.16, 0.08, 0.0, 0.07]])

func _play_sfx(key: String) -> void:
	if test_mode or not sfx.has(key):
		return
	var asp := audio_pool[audio_idx % audio_pool.size()]
	audio_idx += 1
	asp.stream = sfx[key]
	asp.play()

# ==============================================================================
#  NEW GAME WORLD SETUP
# ==============================================================================
func _new_game() -> void:
	season = 0
	day = 1
	year = 1
	hour = 7
	minute = 30
	is_raining = false
	story_step = 0
	story_prog = 0

	in_house = false
	house_fade = 0.0
	saved_outdoor_pos = HOUSE_DOOR + Vector2(0, 22)
	house_upgrades = {}
	house_decor = {"floor": 0, "rug": 0, "wall": 0, "plants": true, "dining": true, "dog_corner": true, "wall_art": true}
	house_chest = {"wood": 6, "stone": 4}
	house_tab = 0
	well_rested = false
	cur_zone = ""
	if cam != null:
		_apply_cam_mode()

	p = {
		"pos": Vector2(445, 415),
		"dir": "down",
		"flip": false,
		"anim": "idle",
		"at": 0.0,
		"act_t": 0.0,
		"hp": 110.0,
		"max_hp": 110.0,
		"stam": 100.0,
		"max_stam": 100.0,
		"gold": 450,
		"slot": 0, # 0:Silah, 1:Çapa, 2:Sulama, 3:Balta/Kazma, 4:Olta, 5:Tohum, 6:İksir, 7:Kemik
		"hoe_tier": 1,
		"water_tier": 1,
		"water_tank": 20,
		"water_max": 20,
		"speed_boost": 0.0,
		"atk_buff": 0.0,
		"def_buff": 0.0,
		"inv_t": 0.0,
		"level": 1,
		"xp": 0,
		"kills": 0,
		"boss_kills": 0,
		"regen_cd": 0.0,
		"atk_cd": 0.0,
		"roll_t": 0.0,
		"roll_cd": 0.0,
		"roll_dir": Vector2.RIGHT,
		"spin_cd": 0.0,
	}
	gear_bag.clear()
	equipped = {
		"weapon": _make_gear("weapon", 1, 0, 0),
		"armor": _make_gear("armor", 1, 0, 0),
		"shield": null,
		"ring": null,
	}
	bosses_defeated.clear()
	boss_respawn_days.clear()
	projectiles.clear()
	lightning_zones.clear()

	# Init Villager Relationships (Stardew 0..1000 pts = 10 Hearts)
	npc_rel.clear()
	npcs.clear()
	for v in GameData.VILLAGERS:
		npc_rel[v.id] = {
			"pts": 50,
			"talked_today": false,
			"gifted_today": false,
			"gifts_given": [],
			"reward_3": false,
			"reward_6": false,
		}
		var start_pos: Vector2 = v.schedule[0].pos
		npcs.append({
			"id": v.id,
			"name": v.name,
			"role": v.role,
			"sheet": v.sheet,
			"pos": start_pos,
			"goal": start_pos,
			"zone": v.schedule[0].zone,
			"face": -1 if start_pos.x > 1600 else 1,
			"moving": false,
			"t": randf() * 2.0,
		})

	_refresh_stats()
	p.hp = p.max_hp
	state = "play"

	dog = {
		"pos": Vector2(405, 425),
		"flip": false,
		"moving": false,
		"t": 0.0,
		"state": "follow",
		"happy": 0.0,
		"carry": false,
		"bite_cd": 0.0,
	}

	bag.clear()
	_add_bag("seed_parsnip", 6, true)
	_add_bag("seed_carrot", 4, true)
	_add_bag("seed_potato", 2, true)
	_add_bag("sunflower", 1, true)
	_add_bag("mush_red", 2, true)
	_add_bag("pot_growth", 1, true)
	_add_bag("pot_heal", 4, true)
	_add_bag("wood", 10, true)
	_add_bag("stone", 4, true)

	farm_grid.clear()
	for gy in range(FARM_ROWS):
		for gx in range(FARM_COLS):
			var c := Vector2i(gx, gy)
			if gx < 4 and gy < 3:
				var crop_id := ""
				var st := 0
				if gy == 0 and gx < 3:
					crop_id = "parsnip"
					st = 5
				elif gy == 1 and gx < 2:
					crop_id = "carrot"
					st = 3
				farm_grid[c] = {"tilled": true, "watered": (gy == 1), "crop": crop_id, "stage": st, "days": st}

	animals = [
		{"type": "chicken", "name": "Sarıkız", "pos": Vector2(690, 520), "goal": Vector2(740, 540), "flip": false, "t": 0.0, "wait": 1.0, "petted": false},
		{"type": "chicken", "name": "Pamuk", "pos": Vector2(760, 560), "goal": Vector2(710, 590), "flip": true, "t": 1.4, "wait": 0.5, "petted": false},
		{"type": "cow", "name": "Benekli", "pos": Vector2(820, 530), "goal": Vector2(880, 560), "flip": false, "t": 0.5, "wait": 1.5, "petted": false},
		{"type": "sheep", "name": "Kıvırcık", "pos": Vector2(740, 610), "goal": Vector2(830, 610), "flip": false, "t": 2.1, "wait": 1.0, "petted": false},
	]
	ground_drops.clear()
	ground_drops.append({"id": "egg", "sprite": "drop_egg", "pos": Vector2(715, 540), "t": 0.0})

	fence_rects = [
		Rect2(656, 464, 288, 14),
		Rect2(656, 656, 288, 14),
	]

	solid_rects = [
		Rect2(340, 290, 110, 50), # Farmhouse
		Rect2(205, 295, 60, 44),  # Windmill Tower
		Rect2(1224, 470, 72, 38), # Demirci Forge Stall
		Rect2(1410, 380, 110, 50), # Seed Shop
		Rect2(1710, 380, 110, 50), # Tavern
		Rect2(1596, 606, 28, 28),  # Village Bonfire
	]

	_spawn_world_nature()
	_spawn_daily_quest()
	_update_lights()
	_toast("Çayır Vadisi! [E] Evine Gir  •  [Q] Görev  •  [N] Komşular  •  [C] Ekipman", Color(1.0, 0.9, 0.5))

func _spawn_world_nature() -> void:
	_spawn_trees()
	_spawn_rocks()
	_respawn_forage()
	_spawn_enemies()

func _spawn_trees() -> void:
	trees.clear()
	tree_spots_all = [
		[140, 250, "oak"], [125, 480, "pine"], [155, 740, "oak"], [290, 880, "pine"],
		[1110, 260, "oak"], [1165, 650, "pine"], [1920, 535, "oak"], [1960, 780, "pine"],
		[1280, 155, "oak"], [1420, 200, "pine"], [1520, 150, "oak"], [1680, 150, "pine"],
		[1760, 280, "oak"], [2070, 350, "pine"], [1360, 290, "oak"], [1840, 345, "pine"],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7171
	var tries := 0
	while tries < 500 and tree_spots_all.size() < 120:
		tries += 1
		var tp := Vector2(rng.randf_range(SHADOW_X + 24, WORLD_W - 80), rng.randf_range(110, 1060))
		if absf(tp.y - 600) < 70 and tp.x < 3100:
			continue
		var in_arena := false
		for ar in BOSS_ARENAS:
			if tp.distance_to(ar.pos) < ar.radius + 55.0:
				in_arena = true
				break
		if in_arena:
			continue
		var ok := true
		for ts in tree_spots_all:
			if Vector2(ts[0], ts[1]).distance_to(tp) < 58.0:
				ok = false
				break
		if ok:
			tree_spots_all.append([tp.x, tp.y, "pine" if rng.randf() < 0.6 else "oak"])
	for ts in tree_spots_all:
		trees.append({"pos": Vector2(ts[0], ts[1]), "kind": ts[2], "hp": 3})

func _regrow_trees() -> void:
	for ts in tree_spots_all:
		var tp := Vector2(ts[0], ts[1])
		var exists := false
		for tr in trees:
			if tr.pos == tp:
				exists = true
				break
		if not exists and randf() < 0.35 and tp.distance_to(p.pos) > 120.0:
			trees.append({"pos": tp, "kind": ts[2], "hp": 3})

func _spawn_rocks() -> void:
	rocks.clear()
	var rock_spots := [
		[1340, 160, "stone"], [1410, 140, "copper"], [1510, 220, "copper"],
		[1640, 140, "stone"], [1740, 160, "copper"], [1830, 130, "crystal"],
		[1690, 255, "stone"], [1545, 275, "copper"],
		[2420, 180, "gold"], [2560, 960, "copper"], [2700, 130, "crystal"], [2860, 990, "gold"],
		[2350, 820, "stone"], [3000, 220, "crystal"], [3250, 980, "gold"], [3420, 220, "crystal"],
	]
	for rs in rock_spots:
		rocks.append({"pos": Vector2(rs[0], rs[1]), "kind": rs[2], "hp": 3 if rs[2] == "stone" else 4})

func _spawn_enemies() -> void:
	enemies.clear()
	var spots := [
		# Kuzey Ormanı (Sv.1-4)
		["goblin", 1360, 240], ["goblin", 1500, 210], ["orc_rogue", 1640, 170],
		["orc_shaman", 1745, 220], ["orc_rogue", 1830, 250],
		# Boss 1
		["boss_grog", 1960, 195],
		# Gölge Ormanı & Mahzen (Sv.5-9)
		["skeleton", 2320, 310], ["skel_warrior", 2390, 440], ["skel_rogue", 2440, 740],
		["skel_mage", 2540, 500], ["skel_warrior", 2680, 790], ["skel_rogue", 2520, 260],
		["skel_mage", 2820, 460], ["skel_warrior", 2890, 740],
		# Boss 2
		["boss_korgath", 2680, 310],
		# Cehennem Yolu (Sv.10-13)
		["shadow_knight", 2980, 490], ["hell_shaman", 3020, 730], ["shadow_knight", 3070, 580],
		# Boss 3
		["boss_malakor", 3260, 620],
	]
	for sp in spots:
		enemies.append(_make_enemy(sp[0], Vector2(sp[1], sp[2])))
	for e in enemies:
		if e.boss and day < boss_respawn_days.get(e.boss_id, 0):
			e.dead = true
			e.dead_t = 99.0
			e.respawn = 999999.0

func _make_enemy(kind: String, pos: Vector2) -> Dictionary:
	var d: Dictionary = GameData.ENEMY_DEFS[kind]
	var is_b: bool = d.get("boss", false)
	var lvl: int = d.lvl + (randi() % 2 if not is_b else 0)
	var sc_l: float = 1.0 + (lvl - d.lvl) * 0.14
	return {
		"kind": kind, "type": d.spr, "name": d.name, "lvl": lvl,
		"pos": pos, "home": pos, "hp": d.hp * sc_l, "max": d.hp * sc_l,
		"atk": d.atk * sc_l, "def": d.def, "spd": d.spd, "face": -1, "t": randf() * 2.0,
		"dead": false, "dead_t": 0.0, "hit_t": 0.0, "atk_cd": 0.0, "windup": 0.0,
		"kb": Vector2.ZERO, "aggro": false, "wander": pos, "wait": randf_range(0.5, 2.0),
		"moving": false, "respawn": 0.0, "boss": is_b, "boss_id": d.get("boss_id", ""),
		"ranged": d.get("ranged", false), "proj_col": d.get("proj_col", Color(0.75, 0.9, 1.0)),
		"slam_t": 0.0, "slam_cd": 4.2, "nova_cd": 6.0, "charge_t": 0.0, "charge_dir": Vector2.ZERO,
		"charge_cd": 5.5, "summoned_p2": false, "atk_anim_t": 0.0, "atk_anim": "atk1",
	}

func _respawn_forage() -> void:
	forage_nodes.clear()
	var m_spots := [Vector2(1280, 230), Vector2(1470, 280), Vector2(1630, 290), Vector2(1810, 260), Vector2(260, 620), Vector2(1150, 820)]
	for idx in m_spots.size():
		forage_nodes.append({"pos": m_spots[idx], "id": "mush_glow" if (idx % 2 == 1) else "mush_red"})

func _spawn_daily_quest() -> void:
	var pool := [
		{"title": "Meryem'in Kahvaltı Siparişi", "need_id": "egg", "need_cnt": 2, "reward": 150, "done": false},
		{"title": "Ozan'ın Gece İksiri", "need_id": "mush_glow", "need_cnt": 2, "reward": 190, "done": false},
		{"title": "Bram'ın Göl İsteği", "need_id": "fish_trout", "need_cnt": 1, "reward": 140, "done": false},
		{"title": "Ayla'nın Taze Hasat İsteği", "need_id": "parsnip", "need_cnt": 3, "reward": 170, "done": false},
		{"title": "Demir'in Cevher İhtiyacı", "need_id": "copper_ore", "need_cnt": 3, "reward": 210, "done": false},
	]
	daily_quest = pool[(day - 1) % pool.size()].duplicate()

# ==============================================================================
#  RPG STATS, GEAR, LOOT & FRIENDSHIP PERKS
# ==============================================================================
func _hearts(npc_id: String) -> int:
	if not npc_rel.has(npc_id):
		return 0
	return clampi(int(npc_rel[npc_id].pts / 100), 0, 10)

func _has_perk(npc_id: String, tier: int) -> bool:
	return _hearts(npc_id) >= tier

func _hero_skin_tier() -> int:
	var arm = equipped.get("armor", null)
	if arm == null:
		return 0
	return clampi(int(arm.get("skin", 0)), 0, 4)

func _xp_need(lv: int) -> int:
	return int(40.0 * pow(lv, 1.55)) + 20

func _stat_atk() -> float:
	var a: float = 6.0 + (p.level - 1) * 2.5
	if _has_perk("demir", 6):
		a += 4.0
	for k in ["weapon", "ring"]:
		var g = equipped.get(k, null)
		if g != null:
			a += g.atk + g.get("plus", 0) * 4
	if p.get("atk_buff", 0.0) > 0.0:
		a *= 1.25
	return a

func _stat_def() -> float:
	var d: float = (p.level - 1) * 0.9
	if _has_perk("demir", 6):
		d += 4.0
	for k in ["armor", "shield", "ring"]:
		var g = equipped.get(k, null)
		if g != null:
			d += g.def + g.get("plus", 0) * 2
	if p.get("def_buff", 0.0) > 0.0:
		d += 12.0
	return d

func _stat_crit() -> float:
	var c := 6.0 + (8.0 if _has_perk("ozan", 3) else 0.0)
	for k in equipped:
		var g = equipped[k]
		if g != null:
			c += g.crit
	return minf(c, 65.0)

func _stat_lifesteal() -> float:
	var ls := 0.0
	for k in equipped:
		var g = equipped[k]
		if g != null:
			ls += g.get("ls", 0)
	return ls

func _refresh_stats() -> void:
	var mh: float = 110.0 + (p.level - 1) * 14.0 + (30.0 if _has_perk("ozan", 6) else 0.0)
	for k in equipped:
		var g = equipped[k]
		if g != null:
			mh += g.hp + (g.get("plus", 0) * 12 if k == "armor" else 0)
	if well_rested:
		mh *= 1.15
	p.max_hp = mh
	p.hp = minf(p.hp, p.max_hp)

func _gain_xp(n: int, pos := Vector2.INF) -> void:
	if n <= 0:
		return
	p.xp += n
	_float_text((p.pos if pos == Vector2.INF else pos) + Vector2(0, -44), "+%d EXP" % n, Color(0.55, 0.85, 1.0))
	while p.xp >= _xp_need(p.level):
		p.xp -= _xp_need(p.level)
		p.level += 1
		_refresh_stats()
		p.hp = p.max_hp
		p.stam = p.max_stam
		_play_sfx("levelup")
		_spawn_fx("fx_sparkle", p.pos + Vector2(0, -16), 14.0, 1.5, Color(1.0, 0.9, 0.4))
		_spawn_fx("fx_buff", p.pos + Vector2(0, -12), 16.0, 0.85)
		_toast("SEVİYE ATLADIN! Seviye %d  (+14 Can, +2.5 Saldırı, +0.9 Savunma)" % p.level, Color(1.0, 0.85, 0.3))

func _roll_rarity(bonus := 0.0) -> int:
	var b := bonus + (15.0 if _has_perk("lina", 6) else 0.0)
	var r := randf() * 100.0 - b
	if r < 2.0: return 4
	if r < 7.5: return 3
	if r < 22.0: return 2
	if r < 48.0: return 1
	return 0

func _make_gear(slot: String, lvl: int, rarity := -1, base_idx := -1) -> Dictionary:
	if rarity < 0:
		rarity = _roll_rarity()
	var m: float = GameData.RARITY[rarity].mult
	var bases: Array = GameData.WEAPON_BASES
	if slot == "armor": bases = GameData.ARMOR_BASES
	elif slot == "shield": bases = GameData.SHIELD_BASES
	elif slot == "ring": bases = GameData.RING_BASES
	var bi := base_idx
	if bi < 0:
		var max_bi := bases.size() - (2 if slot == "weapon" else 1) # Keep boss-named axe at end for forging/boss
		bi = clampi(int((lvl - 1) / 2.0) + (1 if rarity >= 3 else 0) + randi_range(-1, 0), 0, max_bi)
	var base: Dictionary = bases[bi]
	var g := {
		"slot": slot, "name": base.name, "icon": base.icon, "rarity": rarity, "lvl": lvl,
		"atk": 0, "def": 0, "hp": 0, "crit": 0, "ls": base.get("ls", 0), "plus": 0,
		"skin": base.get("skin", 0),
	}
	if slot == "weapon":
		g.atk = int(round((4.0 + lvl * 2.2) * m * randf_range(0.92, 1.08)))
		if rarity >= 3:
			g.crit = 3 + rarity * 2
	elif slot == "armor":
		g.def = int(round((1.5 + lvl * 1.2) * m * randf_range(0.92, 1.08)))
		g.hp = int(round(lvl * 7.0 * m))
	elif slot == "shield":
		g.def = int(round((1.2 + lvl * 1.0) * m * randf_range(0.92, 1.08)))
		g.hp = int(round(lvl * 4.0 * m))
		if rarity >= 2:
			g.atk = int(round(lvl * 0.4 * m))
	else:
		g.crit = int(round(2.0 + lvl * 0.6 * m))
		g.atk = int(round(lvl * 0.8 * m))
		if rarity >= 2:
			g.hp = int(round(lvl * 4.0 * m))
		if rarity >= 4:
			g.ls = 3
	if rarity >= 4 and not g.name.begins_with("Efsanevi"):
		g.name = "Efsanevi " + g.name
	g.value = int((14 + lvl * 9) * m * m)
	return g

func _gear_power(g) -> float:
	if g == null:
		return 0.0
	return (g.atk + g.get("plus", 0) * 4) * 2.0 + (g.def + g.get("plus", 0) * 2) * 2.0 + g.hp * 0.45 + g.crit * 1.5 + g.get("ls", 0) * 3.0

func _gear_lines(g: Dictionary) -> String:
	var parts: Array = []
	var pl: int = g.get("plus", 0)
	if g.atk > 0 or (g.slot == "weapon" and pl > 0):
		parts.append("ATK +%d" % (g.atk + pl * 4))
	if g.def > 0 or (g.slot == "armor" and pl > 0):
		parts.append("DEF +%d" % (g.def + pl * 2))
	if g.hp > 0 or (g.slot == "armor" and pl > 0):
		parts.append("CAN +%d" % (g.hp + (pl * 12 if g.slot == "armor" else 0)))
	if g.crit > 0:
		parts.append("KRİT +%d%%" % g.crit)
	if g.get("ls", 0) > 0:
		parts.append("EMME %d%%" % g.ls)
	return "  ".join(PackedStringArray(parts))

func _gear_title(g: Dictionary) -> String:
	return g.name + (" +%d" % g.plus if g.get("plus", 0) > 0 else "")

func _spawn_drop(d: Dictionary, pos: Vector2) -> void:
	d["pos"] = pos
	d["t"] = 0.0
	d["z"] = 0.0
	d["vz"] = randf_range(75.0, 125.0)
	d["vel"] = Vector2(randf_range(-58, 58), randf_range(-34, 34))
	d["auto"] = true
	ground_drops.append(d)

func _drop_loot(e: Dictionary) -> void:
	var d: Dictionary = GameData.ENEMY_DEFS[e.kind]
	var gold: int = randi_range(d.gold[0], d.gold[1]) + e.lvl * 2
	var piles := 1 if gold < 40 else (4 if e.boss else 2)
	for i in piles:
		_spawn_drop({"kind": "gold", "amount": int(gold / piles), "icon": 45}, e.pos)
	for m in d.mats:
		if randf() < m[1]:
			_spawn_drop({"kind": "item", "id": m[0], "icon": GameData.ITEMS[m[0]].icon}, e.pos)
	if randf() < (0.6 if e.boss else 0.12):
		_spawn_drop({"kind": "item", "id": "pot_heal", "icon": GameData.ITEMS["pot_heal"].icon}, e.pos)
	var gear_rolls := 3 if e.boss else 1
	for i in gear_rolls:
		if randf() < d.gear:
			var slot: String = ["weapon", "armor", "shield", "ring"][randi() % 4]
			var rar := _roll_rarity(35.0 if e.boss else 0.0)
			if e.boss:
				rar = maxi(rar, 2 if e.boss_id == "grog" else (3 if e.boss_id == "korgath" else 4))
			var g := _make_gear(slot, e.lvl, rar)
			_spawn_drop({"kind": "gear", "gear": g, "icon": g.icon}, e.pos)

func _pickup_drop(gd: Dictionary) -> bool:
	match gd.get("kind", "item"):
		"gold":
			p.gold += gd.amount
			_float_text(p.pos + Vector2(0, -30), "+%d Altın" % gd.amount, Color(1.0, 0.85, 0.3))
			_play_sfx("coin")
		"gear":
			if gear_bag.size() >= 24:
				_toast("Ekipman çantası dolu (24)! [C] ile sat.", Color(1.0, 0.5, 0.5))
				return false
			var g: Dictionary = gd.gear
			gear_bag.append(g)
			_float_text(p.pos + Vector2(0, -36), "%s [%s]" % [g.name, GameData.RARITY[g.rarity].name], GameData.RARITY[g.rarity].col)
			_play_sfx("catch" if g.rarity >= 2 else "harvest")
			if g.rarity >= 2:
				_toast("%s GANİMET: %s  (%s)" % [GameData.RARITY[g.rarity].name.to_upper(), g.name, _gear_lines(g)], GameData.RARITY[g.rarity].col)
			if g.rarity >= 3:
				_spawn_fx("fx_sparkle", p.pos + Vector2(0, -16), 15.0, 1.1, GameData.RARITY[g.rarity].col)
		_:
			_add_bag(gd.id, 1)
			_play_sfx("harvest")
	return true

func _equip_gear(idx: int) -> void:
	if idx < 0 or idx >= gear_bag.size():
		return
	var g: Dictionary = gear_bag[idx]
	var old = equipped[g.slot]
	equipped[g.slot] = g
	gear_bag.remove_at(idx)
	if old != null:
		gear_bag.insert(idx, old)
	_refresh_stats()
	_play_sfx("catch")
	_toast("Kuşanıldı: %s" % _gear_title(g), GameData.RARITY[g.rarity].col)
	_advance_story(2, 1)

func _sell_gear(idx: int) -> void:
	if idx < 0 or idx >= gear_bag.size():
		return
	var g: Dictionary = gear_bag[idx]
	var val: int = g.value
	if _has_perk("lina", 3):
		val = int(round(val * 1.2))
	p.gold += val
	gear_bag.remove_at(idx)
	_play_sfx("coin")
	_toast("%s satıldı: +%d Altın" % [g.name, val], Color(1.0, 0.88, 0.35))

func _quick_heal() -> void:
	for id in ["pot_heal", "meal_warrior", "meal_breakfast", "meal_fish", "meal_stew", "meal_pie", "fish_trout", "egg", "milk", "carrot", "parsnip", "potato"]:
		if _has_bag(id):
			var ls := _get_consumable_list()
			consumable_choice_idx = ls.find(id)
			_consume_active_item()
			return
	_toast("İyileştirecek iksir veya yemek yok! Meryem'in Hanından Şifa İksiri al.", Color(1.0, 0.5, 0.5))

func _player_hurt(dmg: float, from: Vector2) -> void:
	if p.inv_t > 0 or p.roll_t > 0 or state != "play":
		return
	var real := maxf(1.0, dmg * randf_range(0.9, 1.1) - _stat_def() * 0.58)
	p.hp -= real
	p.inv_t = 0.68
	p.regen_cd = 6.0
	shake = 0.25
	var kb: Vector2 = (p.pos - from).normalized() * 16.0
	if _can_walk(p.pos + kb):
		p.pos += kb
	_play_sfx("hit")
	_spawn_fx("fx_hit", p.pos + Vector2(0, -14), 18.0, 0.7)
	_float_text(p.pos + Vector2(-10, -36), "-%d" % int(real), Color(1.0, 0.35, 0.35))
	if p.hp <= 0:
		_player_die()

func _player_die() -> void:
	p.hp = 0
	state = "dead"
	dead_t = 0.0
	projectiles.clear()
	lightning_zones.clear()
	_play_sfx("hit")

func _revive_player() -> void:
	var lost := mini(400, int(p.gold * 0.1))
	p.gold -= lost
	in_house = false
	well_rested = false
	_refresh_stats()
	_apply_cam_mode()
	p.pos = HOUSE_DOOR + Vector2(0, 18)
	dog.pos = p.pos + Vector2(-26, 8)
	dog.state = "follow"
	bone = null
	p.hp = p.max_hp * 0.65
	p.stam = p.max_stam * 0.75
	hour = mini(23, hour + 3)
	for e in enemies:
		if not e.dead:
			e.aggro = false
			e.pos = e.home
			e.hp = e.max
	state = "play"
	_toast("Bayıldın! Komşular seni çiftliğe taşıdı. (-%d Altın)" % lost, Color(1.0, 0.55, 0.5))

# ==============================================================================
#  BAG & QUEST HELPERS
# ==============================================================================
func _add_bag(id: String, cnt := 1, silent := false) -> void:
	if not GameData.ITEMS.has(id):
		return
	bag[id] = bag.get(id, 0) + cnt
	if not silent:
		_float_text(p.pos + Vector2(0, -34), "+%d %s" % [cnt, GameData.ITEMS[id].name], Color(0.7, 1.0, 0.7))

func _has_bag(id: String, cnt := 1) -> bool:
	return bag.get(id, 0) >= cnt

func _take_bag(id: String, cnt := 1) -> bool:
	if not _has_bag(id, cnt):
		return false
	bag[id] -= cnt
	if bag[id] <= 0:
		bag.erase(id)
	return true

func _toast(msg: String, col := Color.WHITE) -> void:
	toast_msg = msg
	toast_col = col
	toast_t = 3.8

func _float_text(pos: Vector2, txt: String, col := Color.WHITE) -> void:
	float_texts.append({"pos": pos, "s": txt, "c": col, "life": 1.4, "max": 1.4})

func _spawn_fx(fx_name: String, pos: Vector2, fps := 14.0, sc := 0.85, col := Color.WHITE) -> void:
	if not S.has(fx_name):
		return
	fxs.append({"n": fx_name, "pos": pos, "t": 0.0, "fps": fps, "sc": sc, "col": col})

func _advance_story(step_idx: int, amount := 1) -> void:
	if story_step != step_idx or story_step >= GameData.STORY_CHAPTERS.size():
		return
	story_prog += amount
	var ch: Dictionary = GameData.STORY_CHAPTERS[story_step]
	if story_prog >= ch.need:
		p.gold += ch.reward_gold
		_add_bag(ch.reward_item, ch.reward_cnt, true)
		_play_sfx("catch")
		_spawn_fx("fx_coin", p.pos + Vector2(0, -24), 16.0, 0.9)
		_toast("GÖREV TAMAM: %s (+%d Altın, +%d %s!)" % [ch.title, ch.reward_gold, ch.reward_cnt, GameData.ITEMS[ch.reward_item].name], Color(1.0, 0.88, 0.35))
		story_step += 1
		story_prog = 0

func _get_seed_list() -> Array:
	var out := []
	for k in bag.keys():
		if GameData.ITEMS.has(k) and GameData.ITEMS[k].type == "seed":
			out.append(k)
	out.sort()
	return out

func _get_consumable_list() -> Array:
	var out := []
	for k in bag.keys():
		if GameData.ITEMS.has(k) and GameData.ITEMS[k].type in ["food", "potion", "crop", "forage", "animal"]:
			out.append(k)
	out.sort()
	return out

func _active_seed_id() -> String:
	var ls := _get_seed_list()
	return "" if ls.is_empty() else ls[seed_choice_idx % ls.size()]

func _active_consumable_id() -> String:
	var ls := _get_consumable_list()
	return "" if ls.is_empty() else ls[consumable_choice_idx % ls.size()]

# ==============================================================================
#  MAIN LOOP (_process)
# ==============================================================================
func _process(delta: float) -> void:
	t += delta
	if toast_t > 0:
		toast_t -= delta
	if house_fade > 0.0:
		house_fade = maxf(0.0, house_fade - delta * 3.2)

	if test_mode:
		_run_automated_test(delta)

	for i in range(fxs.size() - 1, -1, -1):
		var f: Dictionary = fxs[i]
		f.t += delta
		var ss: Dictionary = S.get(f.n, {})
		if ss.is_empty() or int(f.t * f.fps) >= ss.n:
			fxs.remove_at(i)

	for i in range(float_texts.size() - 1, -1, -1):
		var ft: Dictionary = float_texts[i]
		ft.life -= delta
		if ft.life <= 0:
			float_texts.remove_at(i)

	if not in_house:
		_update_weather(delta)

	if state == "fishing":
		_update_fishing(delta)
	elif state == "play":
		_update_time(delta)
		_update_player(delta)
		_update_dog(delta)
		_update_npcs(delta)
		_update_animals(delta)
		if not in_house:
			_update_enemies(delta)
			_update_projectiles(delta)
			_update_lightnings(delta)
			_update_drops(delta)
			_update_zone()
	elif state == "dead":
		dead_t += delta
		if dead_t > 2.2:
			_revive_player()
	elif state == "title":
		_update_animals(delta)

	_update_lights()
	if state == "title":
		cam.position = Vector2(540 + sin(t * 0.12) * 140.0, 425 + cos(t * 0.09) * 35.0)
	elif in_house:
		cam.position = Vector2(240, 196)
	else:
		cam.position = p.pos + Vector2(0, -14)
	if shake > 0:
		shake -= delta
		cam.offset = Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5))
	else:
		cam.offset = Vector2.ZERO
	bg_node.queue_redraw()
	world.queue_redraw()
	overlay.queue_redraw()
	hud.queue_redraw()

func _update_time(delta: float) -> void:
	time_acc += delta
	if time_acc >= 2.0:
		time_acc = 0.0
		minute += 10
		if minute >= 60:
			minute = 0
			hour += 1
			if hour >= 24:
				_sleep_next_day("Gece yarısı oldu! Çiftlik evinde dinlendin.")

func _apply_cam_mode() -> void:
	if cam == null:
		return
	if in_house:
		cam.limit_left = -400
		cam.limit_top = -300
		cam.limit_right = 1000
		cam.limit_bottom = 800
		cam.zoom = Vector2(2.0, 2.0)
		cam.position = Vector2(240, 196)
	else:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = int(WORLD_W)
		cam.limit_bottom = int(WORLD_H)
		cam.zoom = Vector2(2.0, 2.0)

func _enter_house() -> void:
	saved_outdoor_pos = p.pos
	in_house = true
	house_fade = 1.0
	p.pos = Vector2(240, 274)
	p.dir = "up"
	p.anim = "idle"
	p.roll_t = 0.0
	p.act_t = 0.0
	dog.pos = Vector2(192, 260)
	dog.state = "follow"
	bone = null
	cur_zone = "ÇİFTLİK EVİ"
	_apply_cam_mode()
	cam.reset_smoothing()
	_play_sfx("click")

func _exit_house() -> void:
	in_house = false
	house_fade = 1.0
	p.pos = HOUSE_DOOR + Vector2(0, 22)
	p.dir = "down"
	p.anim = "idle"
	p.roll_t = 0.0
	p.act_t = 0.0
	dog.pos = p.pos + Vector2(-24, 8)
	dog.state = "follow"
	cur_zone = ""
	_apply_cam_mode()
	cam.position = p.pos + Vector2(0, -14)
	cam.reset_smoothing()
	_play_sfx("click")

func _sleep_next_day(msg := "Yeni bir güne uyandın!") -> void:
	hour = 7
	minute = 0
	day += 1
	well_rested = bool(house_upgrades.get("grand_home", false))
	_refresh_stats()
	p.hp = p.max_hp
	p.stam = p.max_stam
	in_house = true
	house_fade = 1.0
	p.pos = Vector2(126, 172)
	p.dir = "right"
	dog.pos = Vector2(182, 256)
	dog.state = "follow"
	bone = null
	cur_zone = "ÇİFTLİK EVİ"
	_apply_cam_mode()
	cam.reset_smoothing()

	if day > 28:
		day = 1
		season = (season + 1) % 4
		if season == 0:
			year += 1

	is_raining = randf() < 0.22
	for c in farm_grid.keys():
		var tile: Dictionary = farm_grid[c]
		if tile.crop != "" and tile.watered:
			tile.days += 1
			var req: int = GameData.ITEMS["seed_" + tile.crop].days
			tile.stage = mini(5, int(float(tile.days) / float(req) * 5.0))
		tile.watered = is_raining

	for a in animals:
		a.petted = false
		if a.type == "chicken" and ground_drops.size() < 12:
			ground_drops.append({"id": "egg", "sprite": "drop_egg", "pos": a.pos + Vector2(randf_range(-10, 10), randf_range(-6, 8)), "t": 0.0})
		elif a.type == "cow" and ground_drops.size() < 12:
			ground_drops.append({"id": "milk", "sprite": "drop_milk", "pos": a.pos + Vector2(randf_range(-10, 10), randf_range(-6, 8)), "t": 0.0})

	for vid in npc_rel.keys():
		npc_rel[vid].talked_today = false
		npc_rel[vid].gifted_today = false

	if _has_perk("ayla", 6):
		p.gold += 35

	_respawn_forage()
	_spawn_daily_quest()
	_spawn_rocks()
	_regrow_trees()
	projectiles.clear()
	lightning_zones.clear()
	for e in enemies:
		if not e.boss or day >= boss_respawn_days.get(e.boss_id, 0):
			e.merge(_make_enemy(e.kind, e.home), true)
	for i in range(ground_drops.size() - 1, -1, -1):
		var gd: Dictionary = ground_drops[i]
		if gd.get("kind", "") == "gold" or (gd.get("kind", "") == "item" and gd.get("auto", false)):
			ground_drops.remove_at(i)
	_play_sfx("harvest")
	_save_game(true)
	var rest_s := " (Dinlenmiş +%15 Can!)" if well_rested else ""
	_toast(msg + rest_s + (" (Yağmurlu Gün!)" if is_raining else "") + "  [Oyun kaydedildi]", Color(0.85, 0.95, 1.0))

func _update_weather(delta: float) -> void:
	var want_count := 55 if is_raining else (24 if season in [0, 2, 3] else 0)
	var center := cam.get_screen_center_position()
	while weather_particles.size() < want_count:
		weather_particles.append({
			"pos": Vector2(center.x + randf_range(-340, 340), center.y + randf_range(-200, 180)),
			"spd": Vector2(-40 if is_raining else randf_range(-18, 12), 260 if is_raining else randf_range(24, 48))
		})
	if weather_particles.size() > want_count:
		weather_particles.resize(want_count)
	for wp in weather_particles:
		wp.pos += wp.spd * delta
		if wp.pos.y > center.y + 200:
			wp.pos = Vector2(center.x + randf_range(-340, 340), center.y - 200)

func _update_player(delta: float) -> void:
	if p.inv_t > 0: p.inv_t -= delta
	if p.speed_boost > 0: p.speed_boost -= delta
	if p.atk_buff > 0: p.atk_buff -= delta
	if p.def_buff > 0: p.def_buff -= delta
	if p.atk_cd > 0: p.atk_cd -= delta
	if p.roll_cd > 0: p.roll_cd -= delta
	if p.spin_cd > 0: p.spin_cd -= delta

	if p.regen_cd > 0:
		p.regen_cd -= delta
	elif p.hp < p.max_hp:
		p.hp = minf(p.max_hp, p.hp + delta * (1.2 + p.max_hp * 0.012))

	if p.roll_t > 0:
		p.roll_t -= delta
		p.anim = "roll"
		p.at += delta
		var rnext: Vector2 = p.pos + p.roll_dir * 235.0 * delta
		if _can_walk(Vector2(rnext.x, p.pos.y)): p.pos.x = rnext.x
		if _can_walk(Vector2(p.pos.x, rnext.y)): p.pos.y = rnext.y
		return

	if p.act_t > 0:
		p.act_t -= delta
		p.at += delta
		return

	var mv := Vector2.ZERO
	if not test_mode:
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1

	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) or p.speed_boost > 0
	var spd := 142.0 if sprinting else 100.0
	if p.speed_boost > 0:
		spd = 168.0
	if _has_perk("bram", 6):
		spd *= 1.1

	if mv != Vector2.ZERO:
		mv = mv.normalized()
		if absf(mv.x) > 0.15:
			p.flip = mv.x < 0
		p.dir = "side" if absf(mv.x) > absf(mv.y) else ("down" if mv.y > 0 else "up")
		p.anim = "run" if sprinting else "walk"
		p.at += delta
		var next_pos: Vector2 = p.pos + mv * spd * delta
		if _can_walk(Vector2(next_pos.x, p.pos.y)):
			p.pos.x = next_pos.x
		if _can_walk(Vector2(p.pos.x, next_pos.y)):
			p.pos.y = next_pos.y
		if in_house and p.pos.y > 302.0 and absf(p.pos.x - 240.0) < 28.0:
			_exit_house()
	else:
		p.anim = "idle"
		p.at += delta

func _can_walk(pos: Vector2) -> bool:
	if in_house:
		var inside_floor := HOUSE_RECT.has_point(pos) or HOUSE_EXIT_RECT.has_point(pos)
		if not inside_floor:
			return false
		var boxes: Array[Rect2] = [
			Rect2(60, 108, 52, 46),   # Yatak
			Rect2(118, 106, 32, 18),  # Sandık
			Rect2(156, 106, 48, 20),  # Ev Düzenleme Masası
			Rect2(214, 106, 44, 18),  # Şömine
		]
		if house_upgrades.get("kitchen", false):
			boxes.append(Rect2(320, 108, 114, 22))
		if house_upgrades.get("alchemy", false):
			boxes.append(Rect2(396, 166, 38, 36))
		if house_upgrades.get("forge", false):
			boxes.append(Rect2(46, 214, 62, 42))
		if house_decor.get("dining", true):
			boxes.append(Rect2(272, 104, 42, 16))
			boxes.append(Rect2(308, 214, 40, 24))
		for br in boxes:
			if br.has_point(pos):
				return false
		return true

	if pos.x < 50 or pos.x > WORLD_W - 50 or pos.y < 60 or pos.y > WORLD_H - 50:
		return false
	var on_pier := Rect2(684, 1060, 76, 155).has_point(pos)
	if pos.y > 1130 and not on_pier:
		return false
	for r in solid_rects:
		if r.has_point(pos):
			return false
	for r in fence_rects:
		if r.has_point(pos):
			return false
	for tr in trees:
		var d: Vector2 = pos - tr.pos
		if absf(d.x) < 9.0 and d.y > -7.0 and d.y < 4.0:
			return false
	for rk in rocks:
		var d2: Vector2 = pos - rk.pos
		if absf(d2.x) < 10.0 and d2.y > -8.0 and d2.y < 3.0:
			return false
	return true

func _update_npcs(delta: float) -> void:
	for i in npcs.size():
		var n: Dictionary = npcs[i]
		n.t += delta
		var v: Dictionary = GameData.VILLAGERS[i]
		var target_wp: Dictionary = v.schedule[0]
		for wp in v.schedule:
			if hour >= wp.hour:
				target_wp = wp
		n.goal = target_wp.pos
		n.zone = target_wp.zone
		if active_npc_id == n.id and state in ["dialog", "gift"]:
			n.moving = false
			n.face = 1 if p.pos.x >= n.pos.x else -1
			continue
		var diff: Vector2 = n.goal - n.pos
		if diff.length() > 4.0:
			n.moving = true
			n.face = 1 if diff.x >= 0 else -1
			n.pos += diff.normalized() * 34.0 * delta
		else:
			n.moving = false
			if n.pos.distance_to(p.pos) < 85.0:
				n.face = 1 if p.pos.x >= n.pos.x else -1

func _update_dog(delta: float) -> void:
	dog.t += delta
	if dog.happy > 0: dog.happy -= delta
	if in_house:
		var spot: Vector2 = (INT_DOG_BOWL + Vector2(22, -4)) if house_decor.get("dog_corner", true) else (p.pos + Vector2(-26, 8))
		if dog.pos.distance_to(p.pos) > 125.0:
			spot = p.pos + Vector2(-24, 10)
		var to_d: Vector2 = spot - dog.pos
		if to_d.length() > 14.0:
			dog.moving = true
			dog.flip = to_d.x < 0
			var nd: Vector2 = dog.pos + to_d.normalized() * 68.0 * delta
			dog.pos = Vector2(clampf(nd.x, HOUSE_RECT.position.x + 10, HOUSE_RECT.end.x - 10), clampf(nd.y, HOUSE_RECT.position.y + 10, HOUSE_RECT.end.y - 10))
		else:
			dog.moving = false
		return
	if bone != null:
		if not bone.landed:
			bone.pos += bone.vel * delta
			bone.vel.y += 380.0 * delta
			bone.rot += delta * 14.0
			if bone.pos.y >= bone.ground_y:
				bone.landed = true
				bone.pos.y = bone.ground_y
		var to_b: Vector2 = bone.pos - dog.pos
		dog.moving = true
		dog.flip = to_b.x < 0
		if to_b.length() > 12.0:
			dog.pos += to_b.normalized() * 170.0 * delta
		else:
			bone = null
			dog.carry = true
			dog.state = "return"
			var hit_any := false
			for e in enemies:
				if not e.dead and e.pos.distance_to(dog.pos) < 75.0:
					_damage_enemy(e, 10.0 + p.level * 2.5, false, true)
					hit_any = true
			if hit_any:
				_play_sfx("bark")
				_float_text(dog.pos + Vector2(0, -24), "HAV! (Isırdı!)", Color(1.0, 0.8, 0.4))
			elif randf() < 0.45:
				_add_bag("truffle", 1)
				_play_sfx("bark")
				_spawn_fx("fx_sparkle", dog.pos, 16.0, 0.7)
		return

	if dog.state == "return":
		var to_p: Vector2 = p.pos - dog.pos
		dog.moving = true
		dog.flip = to_p.x < 0
		if to_p.length() > 26.0:
			dog.pos += to_p.normalized() * 140.0 * delta
		else:
			dog.carry = false
			dog.state = "follow"
			dog.happy = 1.5
			_spawn_fx("fx_heart", dog.pos + Vector2(0, -14), 16.0, 0.6)
		return

	if dog.bite_cd > 0: dog.bite_cd -= delta
	var foe = null
	var best := 105.0
	for e in enemies:
		if not e.dead and e.aggro and e.pos.distance_to(p.pos) < best:
			best = e.pos.distance_to(p.pos)
			foe = e
	if foe != null and dog.bite_cd <= 0:
		var to_e: Vector2 = foe.pos - dog.pos
		dog.moving = true
		dog.flip = to_e.x < 0
		if to_e.length() > 16.0:
			dog.pos += to_e.normalized() * 168.0 * delta
		else:
			dog.bite_cd = 1.5
			_damage_enemy(foe, 4.0 + p.level * 1.8, false, true)
			_play_sfx("bark")
		return

	var target: Vector2 = p.pos + Vector2(-28 if not p.flip else 28, 12)
	var diff: Vector2 = target - dog.pos
	if diff.length() > 20.0:
		dog.moving = true
		dog.flip = diff.x < 0
		dog.pos += diff.normalized() * (140.0 if diff.length() > 120.0 else 95.0) * delta
	else:
		dog.moving = false

func _update_animals(delta: float) -> void:
	for a in animals:
		a.t += delta
		var d: Vector2 = a.goal - a.pos
		if d.length() > 4.0:
			a.pos += d.normalized() * 18.0 * delta
			a.flip = d.x < 0
		else:
			a.wait -= delta
			if a.wait <= 0:
				a.wait = randf_range(1.2, 3.2)
				a.goal = Vector2(randf_range(680, 910), randf_range(490, 635))

func _enemy_can_walk(pos: Vector2) -> bool:
	if pos.x < 60 or pos.x > WORLD_W - 60 or pos.y < 70 or pos.y > 1100:
		return false
	for r in solid_rects:
		if r.has_point(pos):
			return false
	return true

func _update_enemies(delta: float) -> void:
	for e in enemies:
		e.t += delta
		if e.dead:
			e.dead_t += delta
			if e.respawn > 0:
				e.respawn -= delta
				if e.respawn <= 0 and e.home.distance_to(p.pos) > 260.0:
					e.merge(_make_enemy(e.kind, e.home), true)
				elif e.respawn <= 0:
					e.respawn = 3.0
			elif e.dead_t > 2.0 and not e.boss:
				e.respawn = 45.0 if e.home.x < SHADOW_X else 60.0
			continue

		if e.hit_t > 0: e.hit_t -= delta
		if e.atk_cd > 0: e.atk_cd -= delta
		if e.atk_anim_t > 0: e.atk_anim_t -= delta

		if e.kb.length() > 1.0:
			var np: Vector2 = e.pos + e.kb * delta
			if _enemy_can_walk(np):
				e.pos = np
			e.kb = e.kb.move_toward(Vector2.ZERO, 420.0 * delta)

		var dist: float = e.pos.distance_to(p.pos)
		var from_home: float = e.pos.distance_to(e.home)
		var aggro_r := 220.0 if e.boss else 135.0
		if not e.aggro and dist < aggro_r and state == "play":
			e.aggro = true
			if e.boss:
				_play_sfx("boss")
				_toast("%s UYANDI! (Sv.%d)" % [e.name, e.lvl], Color(1.0, 0.45, 0.32))
		if e.aggro and (from_home > (380.0 if e.boss else 300.0) or dist > 380.0):
			e.aggro = false

		e.moving = false
		var enraged: bool = e.boss and e.hp < e.max * 0.55

		# Boss 3 Phase 2 Minion Summon
		if e.boss_id == "malakor" and enraged and not e.summoned_p2:
			e.summoned_p2 = true
			_toast("MALAKOR ÖFKELENDİ! İskelet Muhafızlar çağrılıyor!", Color(1.0, 0.35, 0.3))
			_spawn_fx("fx_skull", e.pos + Vector2(0, -16), 14.0, 1.5, Color(1.0, 0.4, 0.3))
			for ox in [-70.0, 70.0]:
				var m := _make_enemy("skel_warrior", e.pos + Vector2(ox, 20))
				m.aggro = true
				enemies.append(m)

		# Telegraph Windup
		if e.windup > 0:
			e.windup -= delta
			if e.windup <= 0:
				if e.ranged:
					var dir: Vector2 = (p.pos + Vector2(0, -10) - (e.pos + Vector2(0, -14))).normalized()
					projectiles.append({"pos": e.pos + Vector2(0, -14), "vel": dir * 165.0, "dmg": e.atk, "life": 2.6, "col": e.proj_col})
					_play_sfx("blip")
				else:
					e.atk_anim = "atk1"
					e.atk_anim_t = 0.55
					if dist < 38.0 * (1.55 if e.boss else 1.0):
						_player_hurt(e.atk, e.pos)
			continue

		# Boss Slam AoE
		if e.slam_t > 0:
			e.slam_t -= delta
			if e.slam_t <= 0:
				shake = 0.5
				e.atk_anim = "atk2"
				e.atk_anim_t = 0.65
				if e.boss_id == "malakor":
					_spawn_fx("fx_explosion", e.pos, 16.0, 1.6)
				elif e.boss_id == "korgath":
					_spawn_fx("fx_splat", e.pos, 16.0, 2.0, Color(1.0, 0.25, 0.3))
				else:
					_spawn_fx("fx_smoke", e.pos, 14.0, 2.2)
				_play_sfx("hit")
				if dist < 84.0:
					_player_hurt(e.atk * 1.4, e.pos)
			continue

		# Boss 1 Charge Rush
		if e.charge_t > 0:
			e.charge_t -= delta
			if e.charge_t > 0.35:
				continue # telegraphing red line
			e.moving = true
			var cn: Vector2 = e.pos + e.charge_dir * 250.0 * delta
			if _enemy_can_walk(cn):
				e.pos = cn
			if e.pos.distance_to(p.pos) < 34.0:
				_player_hurt(e.atk * 1.25, e.pos)
				e.charge_t = 0.0
			continue

		if e.aggro:
			var dir2: Vector2 = (p.pos - e.pos).normalized()
			e.face = 1 if dir2.x >= 0 else -1
			if e.boss:
				var rate := 1.4 if enraged else 1.0
				e.slam_cd -= delta * rate
				e.nova_cd -= delta * rate
				e.charge_cd -= delta * rate
				if e.slam_cd <= 0 and dist < 120.0:
					e.slam_cd = randf_range(4.2, 6.0)
					e.slam_t = 0.85
					continue
				if e.boss_id == "grog" and e.charge_cd <= 0 and dist > 75.0 and dist < 210.0:
					e.charge_cd = 6.5
					e.charge_t = 1.05
					e.charge_dir = dir2
					continue
				if e.boss_id in ["korgath", "malakor"] and e.nova_cd <= 0:
					e.nova_cd = 5.2 if enraged else 6.8
					e.atk_anim = "atk2"
					e.atk_anim_t = 0.6
					var cnt := 8 if e.boss_id == "malakor" else 5
					var pcol := Color(1.0, 0.45, 0.15) if e.boss_id == "malakor" else Color(1.0, 0.25, 0.35)
					for k in cnt:
						var ang := k * TAU / float(cnt) + t * 0.5
						projectiles.append({"pos": e.pos + Vector2(0, -16), "vel": Vector2(cos(ang), sin(ang)) * 155.0, "dmg": e.atk * 0.75, "life": 2.4, "col": pcol})
					if e.boss_id == "malakor" and enraged:
						for lz in 3:
							var lp: Vector2 = p.pos + Vector2(randf_range(-55, 55), randf_range(-40, 40))
							lightning_zones.append({"pos": lp, "t": 0.9, "dmg": e.atk * 1.15})
					_play_sfx("boss")
					continue

			var want := 105.0 if e.ranged else 24.0 * (1.4 if e.boss else 1.0)
			if e.ranged and dist < 72.0:
				var away: Vector2 = e.pos - dir2 * e.spd * 0.8 * delta
				if _enemy_can_walk(away):
					e.pos = away
					e.moving = true
			elif dist > want:
				var step: Vector2 = e.pos + dir2 * e.spd * (1.18 if enraged else 1.0) * delta
				if _enemy_can_walk(step):
					e.pos = step
					e.moving = true
			elif e.atk_cd <= 0:
				e.windup = 0.32 if e.ranged else 0.42
				e.atk_cd = 1.8 if e.ranged else (1.15 if e.boss else 1.45)
		else:
			if e.pos.distance_to(e.wander) > 5.0:
				var wd: Vector2 = e.wander - e.pos
				var wn: Vector2 = e.pos + wd.normalized() * e.spd * 0.45 * delta
				if _enemy_can_walk(wn):
					e.pos = wn
					e.face = 1 if wd.x >= 0 else -1
					e.moving = true
				else:
					e.wander = e.pos
			else:
				e.wait -= delta
				if e.wait <= 0:
					e.wait = randf_range(1.4, 3.4)
					var cand: Vector2 = e.home + Vector2(randf_range(-48, 48), randf_range(-34, 34))
					if _enemy_can_walk(cand):
						e.wander = cand

func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var pr: Dictionary = projectiles[i]
		pr.pos += pr.vel * delta
		pr.life -= delta
		if pr.pos.distance_to(p.pos + Vector2(0, -10)) < 13.0:
			_player_hurt(pr.dmg, pr.pos)
			projectiles.remove_at(i)
		elif pr.life <= 0:
			projectiles.remove_at(i)

func _update_lightnings(delta: float) -> void:
	for i in range(lightning_zones.size() - 1, -1, -1):
		var lz: Dictionary = lightning_zones[i]
		lz.t -= delta
		if lz.t <= 0:
			_spawn_fx("fx_lightning", lz.pos, 16.0, 1.2)
			_spawn_fx("fx_explosion", lz.pos, 18.0, 0.75)
			_play_sfx("crit")
			shake = maxf(shake, 0.25)
			if p.pos.distance_to(lz.pos) < 34.0:
				_player_hurt(lz.dmg, lz.pos)
			lightning_zones.remove_at(i)

func _update_drops(delta: float) -> void:
	for i in range(ground_drops.size() - 1, -1, -1):
		var gd: Dictionary = ground_drops[i]
		gd.t += delta
		if gd.get("auto", false):
			if gd.get("z", 0.0) > 0 or gd.get("vz", 0.0) > 0:
				gd.pos += gd.vel * delta
				gd.z += gd.vz * delta
				gd.vz -= 340.0 * delta
				if gd.z <= 0:
					gd.z = 0.0
					gd.vz = 0.0
					gd.vel = Vector2.ZERO
			elif gd.t > 0.35:
				var d: float = p.pos.distance_to(gd.pos)
				if d < 58.0:
					gd.pos = gd.pos.move_toward(p.pos, 190.0 * delta)
				if d < 18.0 and _pickup_drop(gd):
					ground_drops.remove_at(i)

func _zone_name(pos: Vector2) -> String:
	for ar in BOSS_ARENAS:
		if pos.distance_to(ar.pos) < ar.radius + 35.0:
			return ar.label
	if pos.x >= 2950: return "CEHENNEM YOLU (Sv.10-14)"
	if pos.x >= SHADOW_X: return "GÖLGE ORMANI & MAHZEN (Sv.4-9)"
	if pos.y > 1050: return "GÜNEY GÖLÜ"
	if pos.y < 330 and pos.x > 1200: return "KUZEY ORMANI (Sv.1-4)"
	if pos.x > 1200: return "GÜL KÖYÜ MEYDANI"
	return "ÇAYIR ÇİFTLİĞİ"

func _update_zone() -> void:
	var z := _zone_name(p.pos)
	if z != cur_zone:
		var prev := cur_zone
		cur_zone = z
		if prev != "":
			var zcol := Color(0.85, 0.95, 1.0)
			if "GROG" in z or "KORGATH" in z or "MALAKOR" in z or "CEHENNEM" in z:
				zcol = Color(1.0, 0.45, 0.35)
			elif "GÖLGE" in z:
				zcol = Color(0.85, 0.6, 1.0)
			_toast(z, zcol)

# ==============================================================================
#  PLAYER ACTIONS, COMBAT SKILLS, DODGE ROLL & STARDEW INTERACTION
# ==============================================================================
func _facing_offset() -> Vector2:
	if p.dir == "up": return Vector2(0, -24)
	if p.dir == "down": return Vector2(0, 24)
	return Vector2(-24 if p.flip else 24, 0)

func _facing_farm_cell() -> Vector2i:
	var target: Vector2 = p.pos + _facing_offset()
	return Vector2i(int(floor((target.x - FARM_OX) / FARM_CELL)), int(floor((target.y - FARM_OY) / FARM_CELL)))

func _area_cells(center: Vector2i, tier: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if tier <= 1:
		cells.append(center)
	elif tier == 2:
		for d in [-1, 0, 1]:
			cells.append(center + Vector2i(d, 0))
	else:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				cells.append(center + Vector2i(dx, dy))
	return cells

func _dodge_roll() -> void:
	if state != "play" or p.roll_t > 0 or p.roll_cd > 0:
		return
	if in_house:
		_interact_nearest()
		return
	var mv := Vector2.ZERO
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): mv.x += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): mv.x -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): mv.y += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): mv.y -= 1
	if mv == Vector2.ZERO:
		mv = _facing_offset()
	p.roll_dir = mv.normalized()
	if absf(p.roll_dir.x) > 0.15:
		p.flip = p.roll_dir.x < 0
	p.roll_t = 0.34
	p.roll_cd = 0.85
	p.inv_t = maxf(p.inv_t, 0.36)
	p.at = 0.0
	_play_sfx("roll")
	_spawn_fx("fx_smoke", p.pos, 18.0, 0.65)

func _whirlwind_skill() -> void:
	if state != "play" or p.spin_cd > 0 or p.roll_t > 0 or in_house:
		return
	p.spin_cd = 4.0
	p.anim = "attack"
	p.act_t = 0.32
	p.at = 0.0
	_play_sfx("slash")
	_spawn_fx("fx_slash", p.pos + Vector2(0, -14), 18.0, 1.35, Color(1.0, 0.85, 0.35))
	_spawn_fx("fx_buff", p.pos + Vector2(0, -10), 22.0, 0.9, Color(1.0, 0.55, 0.2))
	var any := false
	for e in enemies:
		if not e.dead and (e.pos + Vector2(0, -10)).distance_to(p.pos) < 70.0:
			var crit := randf() * 100.0 < (_stat_crit() + 15.0)
			var dmg := _stat_atk() * 1.85 * (1.75 if crit else 1.0)
			e.kb = (e.pos - p.pos).normalized() * (45.0 if e.boss else 210.0)
			_damage_enemy(e, dmg, crit)
			any = true
	if any:
		shake = 0.15

func _use_hotbar_tool() -> void:
	if state != "play" or p.act_t > 0 or p.roll_t > 0:
		return
	if in_house:
		if p.slot == 6:
			_consume_active_item()
		else:
			_interact_nearest()
		return

	# Slot 0: Silah
	if p.slot == 0:
		if p.atk_cd > 0:
			return
		p.anim = "attack"
		p.act_t = 0.25
		p.at = 0.0
		p.atk_cd = 0.32
		_play_sfx("swing")
		var hit_pos: Vector2 = p.pos + _facing_offset() * 0.9 + Vector2(0, -8)
		var w = equipped.get("weapon", null)
		var rcol: Color = GameData.RARITY[w.rarity].col if w != null else Color.WHITE
		_spawn_fx("fx_slash", hit_pos, 20.0, 0.85, rcol)
		var any := false
		for e in enemies:
			if not e.dead and (e.pos + Vector2(0, -10)).distance_to(hit_pos) < 34.0 * (1.55 if e.boss else 1.0):
				var crit: bool = randf() * 100.0 < _stat_crit()
				var dmg := _stat_atk() * randf_range(0.9, 1.12) * (1.8 if crit else 1.0)
				e.kb = (e.pos - p.pos).normalized() * (32.0 if e.boss else 175.0)
				_damage_enemy(e, dmg, crit)
				any = true
		if any:
			shake = 0.08
		return

	# Slot 1: Çapa
	if p.slot == 1:
		p.anim = "dig"
		p.act_t = 0.30
		p.at = 0.0
		var center := _facing_farm_cell()
		var did := false
		for c in _area_cells(center, p.hoe_tier):
			if c.x >= 0 and c.x < FARM_COLS and c.y >= 0 and c.y < FARM_ROWS:
				if not farm_grid.has(c):
					farm_grid[c] = {"tilled": true, "watered": is_raining, "crop": "", "stage": 0, "days": 0}
					_spawn_fx("fx_smoke", Vector2(FARM_OX + c.x * FARM_CELL + 12, FARM_OY + c.y * FARM_CELL + 12), 16.0, 0.6)
					did = true
		if did:
			p.stam = maxf(0.0, p.stam - 2.0)
			_play_sfx("hoe")
			_advance_story(0, 1)
		return

	# Slot 2: Sulama Kabı
	if p.slot == 2:
		if p.pos.distance_to(WELL_POS) < 48.0 or p.pos.y > 1080.0:
			p.water_tank = p.water_max
			_play_sfx("water")
			_toast("Sulama kabı dolduruldu!", Color(0.5, 0.85, 1.0))
			return
		if p.water_tank <= 0:
			_toast("Sulama kabı boş! Kuyudan veya Gölden doldur.", Color(1.0, 0.5, 0.5))
			return
		p.anim = "watering"
		p.act_t = 0.30
		p.at = 0.0
		var center := _facing_farm_cell()
		var did := false
		for c in _area_cells(center, p.water_tier):
			if farm_grid.has(c) and farm_grid[c].tilled:
				farm_grid[c].watered = true
				_spawn_fx("fx_splat", Vector2(FARM_OX + c.x * FARM_CELL + 12, FARM_OY + c.y * FARM_CELL + 12), 18.0, 0.5, Color(0.35, 0.78, 1.0))
				did = true
		if did:
			p.water_tank = maxi(0, p.water_tank - 1)
			p.stam = maxf(0.0, p.stam - 1.5)
			_play_sfx("water")
			_advance_story(0, 1)
		return

	# Slot 3: Balta & Kazma
	if p.slot == 3:
		var hit_pos: Vector2 = p.pos + _facing_offset()
		for i in range(rocks.size() - 1, -1, -1):
			var r: Dictionary = rocks[i]
			if r.pos.distance_to(hit_pos) < 38.0:
				p.anim = "mining"
				p.act_t = 0.30
				p.at = 0.0
				r.hp -= 1
				_play_sfx("hit")
				_spawn_fx("fx_smoke", r.pos - Vector2(0, 10), 16.0, 0.7)
				if r.hp <= 0:
					_add_bag("stone", 2)
					if r.kind == "copper": _add_bag("copper_ore", 2)
					elif r.kind == "gold": _add_bag("gold_ore", 2)
					elif r.kind == "crystal":
						_add_bag("gold_ore", 1)
						_add_bag("spirit_crystal", 1)
					rocks.remove_at(i)
					_gain_xp(5)
				return
		for i in range(trees.size() - 1, -1, -1):
			var tr: Dictionary = trees[i]
			if tr.pos.distance_to(hit_pos) < 38.0:
				p.anim = "axe"
				p.act_t = 0.30
				p.at = 0.0
				tr.hp -= 1
				_play_sfx("hit")
				_spawn_fx("fx_smoke", tr.pos - Vector2(0, 16), 16.0, 0.7)
				if tr.hp <= 0:
					_add_bag("wood", 4)
					if randf() < 0.3: _add_bag("mush_red", 1)
					trees.remove_at(i)
					_gain_xp(3)
				return
		p.anim = "axe"
		p.act_t = 0.25
		p.at = 0.0
		return

	# Slot 4: Olta
	if p.slot == 4:
		if p.pos.y >= 1060.0:
			p.anim = "reeling"
			p.act_t = 0.35
			p.at = 0.0
			_start_fishing()
		else:
			_toast("Balık tutmak için Güney Gölü iskelesine git!", Color(0.6, 0.85, 1.0))
		return

	# Slot 5: Tohum Ekimi
	if p.slot == 5:
		var sid := _active_seed_id()
		if sid == "":
			_toast("Hiç tohumun kalmadı! Köydeki Ayla'dan tohum al.", Color(1.0, 0.7, 0.4))
			return
		var c := _facing_farm_cell()
		if farm_grid.has(c) and farm_grid[c].tilled and farm_grid[c].crop == "":
			farm_grid[c].crop = GameData.ITEMS[sid].crop
			farm_grid[c].stage = 0
			farm_grid[c].days = 0
			_take_bag(sid, 1)
			p.anim = "dig"
			p.act_t = 0.22
			p.at = 0.0
			_play_sfx("seed")
			_spawn_fx("fx_sparkle", Vector2(FARM_OX + c.x * FARM_CELL + 12, FARM_OY + c.y * FARM_CELL + 12), 18.0, 0.5)
			_advance_story(0, 1)
		else:
			_toast("Tohum ekmek için önce toprağı Çapala [2]!", Color(1.0, 0.85, 0.5))
		return

	# Slot 6: İksir / Yemek
	if p.slot == 6:
		_consume_active_item()
		return

	# Slot 7: Kemik
	if p.slot == 7:
		_throw_bone()
		return

func _consume_active_item() -> void:
	var cid := _active_consumable_id()
	if cid == "":
		_toast("Çantada tüketilecek yiyecek veya iksir yok.", Color(0.8, 0.8, 0.8))
		return
	var it: Dictionary = GameData.ITEMS[cid]
	if not _take_bag(cid, 1):
		return
	if cid == "pot_growth":
		var grown := 0
		for c in farm_grid.keys():
			if farm_grid[c].crop != "":
				farm_grid[c].stage = 5
				farm_grid[c].days = 5
				_spawn_fx("fx_sparkle", Vector2(FARM_OX + c.x * FARM_CELL + 12, FARM_OY + c.y * FARM_CELL + 12), 15.0, 0.7)
				grown += 1
		_play_sfx("catch")
		_toast("Bereket İksiri içildi! %d ekin hasada hazır!" % grown, Color(0.5, 1.0, 0.6))
	elif cid == "scroll_fireball":
		_play_sfx("hit")
		var hit_cnt := 0
		for e in enemies:
			if not e.dead and e.pos.distance_to(p.pos) < 220.0:
				_damage_enemy(e, 120.0 + p.level * 10.0, true)
				_spawn_fx("fx_explosion", e.pos - Vector2(0, 14), 16.0, 0.8, Color(1.0, 0.4, 0.1))
				hit_cnt += 1
				if hit_cnt >= 3:
					break
		_toast("Alev Topu Parşömeni patlatıldı! (%d düşman vuruldu)" % hit_cnt, Color(1.0, 0.45, 0.2))
		shake = 0.15
	elif cid == "scroll_frost":
		_play_sfx("swing")
		var frost_cnt := 0
		for e in enemies:
			if not e.dead and e.pos.distance_to(p.pos) < 260.0:
				_damage_enemy(e, 50.0 + p.level * 5.0, false)
				e.kb = (e.pos - p.pos).normalized() * 40.0
				_spawn_fx("fx_sparkle", e.pos - Vector2(0, 10), 16.0, 1.0, Color(0.4, 0.8, 1.0))
				frost_cnt += 1
		_toast("Buz Kasırgası! %d düşman donduruldu!" % frost_cnt, Color(0.4, 0.85, 1.0))
		shake = 0.10
	elif cid == "pot_rain":
		is_raining = true
		for c in farm_grid.keys():
			if farm_grid[c].tilled:
				farm_grid[c].watered = true
		_play_sfx("water")
		_toast("Yağmur Totemi çalıştı! Tüm tarla sulandı!", Color(0.5, 0.85, 1.0))
	else:
		p.hp = minf(p.max_hp, p.hp + it.get("hp", 20))
		p.stam = minf(p.max_stam, p.stam + it.get("stam", 25))
		if cid == "pot_spirit": p.speed_boost = 30.0
		if it.get("atk_buff", 0.0) > 0.0: p.atk_buff = it.atk_buff
		if it.get("def_buff", 0.0) > 0.0: p.def_buff = it.def_buff
		_play_sfx("harvest")
		_spawn_fx("fx_heal", p.pos + Vector2(0, -14), 16.0, 0.75)
		_toast("%s tüketildi!" % it.name, Color(0.6, 1.0, 0.6))

func _throw_bone() -> void:
	if bone != null or in_house:
		return
	var d_x := -1.0 if p.flip else 1.0
	if p.dir == "up": d_x = 0.0
	var vel := Vector2(d_x * 210.0, -140.0 if p.dir != "up" else -220.0)
	bone = {"pos": p.pos + Vector2(0, -16), "vel": vel, "ground_y": p.pos.y + (40.0 if p.dir == "down" else (-40.0 if p.dir == "up" else 0.0)), "landed": false, "rot": 0.0}
	_play_sfx("bark")

func _damage_enemy(e: Dictionary, dmg: float, crit := false, from_dog := false) -> void:
	if e.dead:
		return
	var real := maxf(1.0, dmg - e.def * 0.5)
	e.hp -= real
	e.hit_t = 0.16
	e.aggro = true
	if not e.boss and not from_dog:
		e.windup = 0.0
		e.atk_cd = maxf(e.atk_cd, 0.45)
	var ls := _stat_lifesteal()
	if ls > 0 and not from_dog:
		p.hp = minf(p.max_hp, p.hp + real * (ls / 100.0))
	_play_sfx("crit" if crit else "hit")
	_spawn_fx("fx_hit", e.pos + Vector2(0, -14), 18.0, 0.9 if crit else 0.7)
	if crit:
		_float_text(e.pos + Vector2(10, -40), "KRİTİK %d!" % int(real), Color(1.0, 0.9, 0.2))
	else:
		_float_text(e.pos + Vector2(10, -34), "%d" % int(real), Color(1.0, 0.95, 0.9) if not from_dog else Color(0.85, 0.7, 1.0))

	if e.hp <= 0:
		e.hp = 0
		e.dead = true
		e.dead_t = 0.0
		e.respawn = 0.0
		e.windup = 0.0
		e.slam_t = 0.0
		e.charge_t = 0.0
		p.kills += 1
		var d: Dictionary = GameData.ENEMY_DEFS[e.kind]
		var xp := int(d.xp * (1.0 + (e.lvl - d.lvl) * 0.18))
		if p.level > e.lvl + 5:
			xp = maxi(1, int(xp * 0.35))
		_spawn_fx("fx_smoke", e.pos - Vector2(0, 8), 14.0, 1.0)
		_drop_loot(e)
		_gain_xp(xp, e.pos)
		if e.boss:
			p.boss_kills += 1
			bosses_defeated[e.boss_id] = true
			boss_respawn_days[e.boss_id] = day + 3
			e.respawn = 999999.0
			shake = 0.65
			_play_sfx("levelup")
			_spawn_fx("fx_explosion", e.pos, 15.0, 1.4)
			_toast("BOSS ZAFERİ! %s YENİLDİ! (Ganimetlerini topla!)" % e.name, Color(1.0, 0.88, 0.3))
			if e.boss_id == "grog": _advance_story(4, 1)
			elif e.boss_id == "korgath": _advance_story(7, 1)
			elif e.boss_id == "malakor": _advance_story(9, 1)
		elif e.home.x >= SHADOW_X:
			_advance_story(6, 1)
		_advance_story(3, 1)

func _interact_nearest() -> bool:
	if state != "play":
		return false

	if in_house:
		if p.pos.distance_to(Vector2(240, 298)) < 36.0:
			_exit_house()
			return true
		if p.pos.distance_to(INT_BED_POS) < 52.0:
			_sleep_next_day("Yatağında mışıl mışıl uyudun!")
			return true
		if p.pos.distance_to(INT_CHEST_POS) < 42.0:
			state = "chest"
			_play_sfx("click")
			return true
		if p.pos.distance_to(INT_BENCH_POS) < 46.0:
			state = "house_menu"
			_play_sfx("click")
			return true
		if house_upgrades.get("kitchen", false) and p.pos.distance_to(INT_KITCHEN_POS) < 58.0:
			state = "cook"
			_play_sfx("click")
			return true
		if house_upgrades.get("alchemy", false) and p.pos.distance_to(INT_ALCHEMY_POS) < 46.0:
			state = "alchemy"
			_play_sfx("click")
			return true
		if house_upgrades.get("forge", false) and p.pos.distance_to(INT_FORGE_POS) < 52.0:
			state = "smith"
			smith_tab = 0
			_play_sfx("click")
			return true
		if dog.pos.distance_to(p.pos) < 50.0:
			_pet_karabas()
			return true
		return false

	var c := _facing_farm_cell()
	if farm_grid.has(c) and farm_grid[c].crop != "" and farm_grid[c].stage >= 5:
		var cid: String = farm_grid[c].crop
		_add_bag(cid, 1)
		if randf() < 0.25:
			_add_bag("spirit_crystal", 1)
		farm_grid[c].crop = ""
		farm_grid[c].stage = 0
		farm_grid[c].days = 0
		p.anim = "dig"
		p.act_t = 0.22
		p.at = 0.0
		_play_sfx("harvest")
		_spawn_fx("fx_sparkle", Vector2(FARM_OX + c.x * FARM_CELL + 12, FARM_OY + c.y * FARM_CELL + 12), 16.0, 0.7)
		_gain_xp(5)
		return true

	for i in range(ground_drops.size() - 1, -1, -1):
		var gd: Dictionary = ground_drops[i]
		if gd.pos.distance_to(p.pos) < 34.0:
			if _pickup_drop(gd):
				_spawn_fx("fx_sparkle", gd.pos, 16.0, 0.6)
				ground_drops.remove_at(i)
			return true

	for i in range(forage_nodes.size() - 1, -1, -1):
		var fn: Dictionary = forage_nodes[i]
		if fn.pos.distance_to(p.pos) < 34.0:
			_add_bag(fn.id, 1)
			_play_sfx("harvest")
			_spawn_fx("fx_sparkle", fn.pos, 16.0, 0.6)
			forage_nodes.remove_at(i)
			return true

	for a in animals:
		if a.pos.distance_to(p.pos) < 32.0:
			if not a.petted:
				a.petted = true
				_spawn_fx("fx_heart", a.pos + Vector2(0, -14), 16.0, 0.7)
				_play_sfx("harvest")
				_toast("%s sevindi! Seni çok seviyor ♥" % a.name, Color(1.0, 0.7, 0.8))
			return true

	if p.pos.distance_to(HOUSE_DOOR) < 40.0:
		_enter_house()
		return true
	if p.pos.distance_to(WELL_POS) < 38.0:
		p.water_tank = p.water_max
		_play_sfx("water")
		_toast("Sulama kabı kuyu suyuyla doldu!", Color(0.5, 0.85, 1.0))
		return true
	if p.pos.distance_to(CRATE_POS) < 38.0:
		_sell_all_produce()
		return true
	if p.pos.distance_to(FORGE_POS) < 48.0:
		state = "smith"
		smith_tab = 0
		_play_sfx("click")
		return true
	if p.pos.distance_to(BOARD_POS) < 44.0:
		state = "board"
		_play_sfx("click")
		return true

	for n in npcs:
		if n.pos.distance_to(p.pos) < 44.0:
			_open_villager_dialog(n.id)
			return true

	return false

func _pet_karabas() -> void:
	if dog.pos.distance_to(p.pos) < 55.0:
		dog.happy = 2.0
		p.stam = minf(p.max_stam, p.stam + 12.0)
		_spawn_fx("fx_heart", dog.pos + Vector2(0, -14), 16.0, 0.8)
		_play_sfx("bark")
		_toast("Karabaş kuyruğunu sallıyor! (+12 Enerji)", Color(1.0, 0.75, 0.85))

func _sell_all_produce() -> void:
	var earned := 0
	var sold_cnt := 0
	for id in bag.keys().duplicate():
		var it: Dictionary = GameData.ITEMS[id]
		if it.type in ["crop", "animal", "fish", "forage", "food", "loot"]:
			if id.begins_with("boss_trophy_"):
				continue # Keep boss trophies for smith forging unless manually sold
			var c: int = bag[id]
			var mult := 1.2 if (it.type == "fish" and _has_perk("bram", 3)) else 1.0
			earned += int(round(it.sell * c * mult))
			sold_cnt += c
			bag.erase(id)
	if earned > 0:
		p.gold += earned
		_play_sfx("coin")
		_spawn_fx("fx_coin", CRATE_POS - Vector2(0, 15), 15.0, 0.9)
		_toast("Sevkiyat Sandığı Satıldı: +%d Altın (%d ürün)!" % [earned, sold_cnt], Color(1.0, 0.88, 0.35))
	else:
		_toast("Satılacak ürün yok! Boss kupaları Demirci'de zırh dövmek için saklanır.", Color(0.85, 0.85, 0.85))

# ==============================================================================
#  STARDEW VALLEY-STYLE NEIGHBORS, DIALOGUE, GIFTS & PERKS
# ==============================================================================
func _villager_def(vid: String) -> Dictionary:
	for v in GameData.VILLAGERS:
		if v.id == vid:
			return v
	return GameData.VILLAGERS[0]

func _add_friendship(vid: String, pts: int) -> void:
	if not npc_rel.has(vid):
		return
	var r: Dictionary = npc_rel[vid]
	var old_h := _hearts(vid)
	r.pts = clampi(int(r.pts) + pts, 0, 1000)
	var new_h := _hearts(vid)
	var v := _villager_def(vid)
	if new_h > old_h:
		_play_sfx("heart")
		_toast("%s ile dostluğun %d♥ seviyesine yükseldi!" % [v.name, new_h], Color(1.0, 0.6, 0.78))
		if new_h >= 3 and not r.reward_3:
			r.reward_3 = true
			_refresh_stats()
			_toast("3♥ ÖZELLİK AÇILDI (%s): %s" % [v.name, v.perk3], Color(1.0, 0.88, 0.35))
		if new_h >= 6 and not r.reward_6:
			r.reward_6 = true
			_refresh_stats()
			_toast("6♥ EFSANE DOSTLUK (%s): %s" % [v.name, v.perk6], Color(1.0, 0.88, 0.35))

func _open_villager_dialog(vid: String) -> void:
	_play_sfx("blip")
	active_npc_id = vid
	var v := _villager_def(vid)
	var h := _hearts(vid)
	var greet_idx := mini(3, int(h / 2))
	var line: String = v.greetings[greet_idx]
	if p.boss_kills > 0 and randf() < 0.4:
		line = v.boss_line
	elif is_raining and randf() < 0.45:
		line = v.rain_line

	# Meryem 6♥ daily breakfast gift!
	if vid == "meryem" and _has_perk("meryem", 6) and not npc_rel[vid].talked_today:
		_add_bag("meal_breakfast", 1, true)
		line = "6♥ dostumuz gelmiş! Al bakalım, sıcacık Çiftlik Kahvaltısı benden hediye!"

	active_dialog = {
		"speaker": v.name,
		"role": v.role,
		"npc_id": vid,
		"text": line,
		"after": v.service,
	}
	state = "dialog"

func _do_talk_chat() -> void:
	if active_npc_id == "":
		return
	var r: Dictionary = npc_rel[active_npc_id]
	var v := _villager_def(active_npc_id)
	if not r.talked_today:
		r.talked_today = true
		_add_friendship(active_npc_id, 25)
		_advance_story(1, 1)
		_play_sfx("heart")
		for n in npcs:
			if n.id == active_npc_id:
				_spawn_fx("fx_heart", n.pos + Vector2(0, -26), 16.0, 0.8)
		active_dialog.text = "%s (+25 Dostluk!) — 'Seninle konuşmak günümü güzelleştiriyor!'" % v.greetings[mini(3, int(_hearts(active_npc_id) / 2))]
	else:
		active_dialog.text = "Bugün zaten uzun uzun sohbet ettik! İstersen bir hediye verebilir veya tezgahıma bakabilirsin."

func _give_gift_to_npc(item_id: String) -> void:
	if active_npc_id == "" or not _has_bag(item_id):
		return
	var r: Dictionary = npc_rel[active_npc_id]
	if r.gifted_today:
		_toast("Bugün bu komşuya zaten hediye verdin!", Color(1.0, 0.7, 0.4))
		return
	var v := _villager_def(active_npc_id)
	_take_bag(item_id, 1)
	r.gifted_today = true
	if not r.gifts_given.has(item_id):
		r.gifts_given.append(item_id)

	var pts := 15
	var reaction := "Teşekkür ederim, çok düşüncelisin."
	var fx_col := Color(0.85, 0.9, 1.0)
	if item_id == "mermaid_pendant":
		pts = 250
		reaction = "AMAN TANRIM! Denizkızı Tılsımı mı?! Evet, bin kere evet! Artık kaderimiz ve yolumuz bir! (Ebedi Bağ Kuruldu!)"
		fx_col = Color(1.0, 0.2, 0.8)
		_toast("%s ile Ebedi Bağ / Evlilik Bağı Kuruldu!" % v.name, Color(1.0, 0.3, 0.8))
	elif item_id == "bouquet":
		pts = 120
		reaction = "Bu çiçek buketi... Gözlerimin içine bakarak vermen beni o kadar mutlu etti ki! Kalbim seninle atıyor!"
		fx_col = Color(1.0, 0.3, 0.6)
		_toast("%s ile Romantik Bağ Güçlendi!" % v.name, Color(1.0, 0.5, 0.7))
	elif item_id in v.loved:
		pts = 80
		reaction = "VAAY! %s benim EN SEVDİĞİM şey! Çok teşekkürler! (+80 Dostluk)" % GameData.ITEMS[item_id].name
		fx_col = Color(1.0, 0.4, 0.6)
	elif item_id in v.liked:
		pts = 40
		reaction = "Harika! %s gerçekten çok hoşuma gitti! (+40 Dostluk)" % GameData.ITEMS[item_id].name
		fx_col = Color(0.6, 1.0, 0.6)
	else:
		reaction = "Ah, %s! Nazik hediyen için teşekkür ederim. (+15 Dostluk)" % GameData.ITEMS[item_id].name

	_add_friendship(active_npc_id, pts)
	_advance_story(1, 1)
	_play_sfx("heart")
	for n in npcs:
		if n.id == active_npc_id:
			_spawn_fx("fx_heart", n.pos + Vector2(0, -26), 16.0, 1.1, fx_col)
	active_dialog.text = reaction
	state = "dialog"

func _open_npc_service() -> void:
	if active_npc_id == "":
		return
	var svc: String = active_dialog.after
	if svc == "smith":
		smith_tab = 0
	state = svc
	_play_sfx("click")

# ==============================================================================
#  FISHING MINIGAME
# ==============================================================================
func _start_fishing() -> void:
	var pool := ["fish_trout", "fish_sun"]
	if hour >= 18 or hour < 6:
		pool.append("fish_eel")
	if randf() < 0.25:
		pool.append("fish_koi")
	fishing = {"active": true, "fish": pool[randi() % pool.size()], "bar_y": 80.0, "bar_v": 0.0, "fish_y": 75.0, "fish_t": 50.0, "timer": 0.5, "prog": 35.0}
	state = "fishing"
	_play_sfx("bite")

func _update_fishing(delta: float) -> void:
	var pull := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)
	fishing.bar_v = clampf(fishing.bar_v + (-280.0 if pull else 220.0) * delta, -220.0, 220.0)
	fishing.bar_y = clampf(fishing.bar_y + fishing.bar_v * delta, 0.0, 110.0)
	fishing.timer -= delta
	if fishing.timer <= 0:
		fishing.timer = randf_range(0.5, 1.2)
		fishing.fish_t = randf_range(8.0, 128.0)
	fishing.fish_y = move_toward(fishing.fish_y, fishing.fish_t, delta * 58.0)

	if (fishing.fish_y + 8.0) >= fishing.bar_y and (fishing.fish_y + 8.0) <= (fishing.bar_y + 40.0):
		fishing.prog += delta * 36.0
	else:
		fishing.prog -= delta * 18.0
	fishing.prog = clampf(fishing.prog, 0.0, 100.0)

	if fishing.prog >= 100.0:
		var fid: String = fishing.fish
		_add_bag(fid, 1)
		_play_sfx("catch")
		_spawn_fx("fx_sparkle", p.pos + Vector2(0, -16), 16.0, 0.9)
		_toast("BALIK YAKALADIN: %s!" % GameData.ITEMS[fid].name, Color(0.4, 0.95, 1.0))
		_gain_xp(14)
		_advance_story(5, 1)
		state = "play"
	elif fishing.prog <= 0.0:
		_play_sfx("click")
		_toast("Balık oltadan kaçtı...", Color(1.0, 0.5, 0.5))
		state = "play"

# ==============================================================================
#  INPUT HANDLING
# ==============================================================================
func _face_mouse() -> void:
	var mw: Vector2 = world.get_global_mouse_position()
	var d: Vector2 = mw - p.pos
	if d.length() < 4.0:
		return
	if absf(d.x) > 4.0:
		p.flip = d.x < 0
	if absf(d.x) > absf(d.y):
		p.dir = "side"
	else:
		p.dir = "down" if d.y > 0 else "up"

func _unhandled_input(event: InputEvent) -> void:
	if test_mode:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		var mpos := get_viewport().get_mouse_position()
		var right: bool = event.button_index == MOUSE_BUTTON_RIGHT
		for i in range(clickable_rects.size() - 1, -1, -1):
			var cr: Dictionary = clickable_rects[i]
			if cr.rect.has_point(mpos):
				_handle_ui_click(cr, right)
				return
		if right:
			if state == "play":
				if not _interact_nearest() and p.slot == 0:
					_whirlwind_skill()
			return
		if state == "play":
			if p.slot in [0, 3, 7]:
				_face_mouse()
			_use_hotbar_tool()
		elif state == "dialog":
			state = "play"
		return

	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var kc: int = event.keycode

	if state == "title":
		if kc in [KEY_W, KEY_UP]:
			title_sel = posmod(title_sel - 1, 3)
			_play_sfx("blip")
		elif kc in [KEY_S, KEY_DOWN]:
			title_sel = posmod(title_sel + 1, 3)
			_play_sfx("blip")
		elif kc in [KEY_ENTER, KEY_SPACE, KEY_E]:
			_title_choose(title_sel)
		return
	if state == "dead":
		return
	if state == "pause":
		if kc in [KEY_ESCAPE, KEY_P]:
			state = "play"
		elif kc in [KEY_W, KEY_UP]:
			modal_sel = posmod(modal_sel - 1, 3)
		elif kc in [KEY_S, KEY_DOWN]:
			modal_sel = posmod(modal_sel + 1, 3)
		elif kc in [KEY_ENTER, KEY_SPACE, KEY_E]:
			_pause_choose(modal_sel)
		return
	if kc == KEY_ESCAPE:
		if state == "play":
			state = "pause"
			modal_sel = 0
		elif state == "gift":
			state = "dialog"
		elif state != "fishing":
			state = "play"
		_play_sfx("click")
		return

	if state == "dialog":
		if kc == KEY_1: _do_talk_chat()
		elif kc == KEY_2: state = "gift"
		elif kc == KEY_3: _open_npc_service()
		elif kc in [KEY_E, KEY_SPACE, KEY_ENTER]:
			state = "play"
			_play_sfx("click")
		return

	if state == "gift":
		if kc in [KEY_E, KEY_I, KEY_N]:
			state = "dialog"
			_play_sfx("click")
		return

	if state in ["shop", "tavern", "alchemy", "cook", "smith", "board", "alchemy_shop", "fisher_trade", "loot_buyer"]:
		if kc in [KEY_E, KEY_I, KEY_TAB]:
			state = "play"
			_play_sfx("click")
		elif state == "smith" and kc == KEY_TAB:
			smith_tab = (smith_tab + 1) % 3
		elif kc >= KEY_1 and kc <= KEY_6:
			_execute_station_choice(kc - KEY_1)
		elif kc in [KEY_ENTER, KEY_SPACE] and state == "board":
			_handle_ui_click({"action": "turn_in_daily", "val": 0}, false)
		return

	if state == "inv":
		if kc in [KEY_I, KEY_TAB, KEY_E]: state = "play"
		elif kc == KEY_C: state = "char"
		elif kc == KEY_N: state = "social"
		return
	if state == "char":
		if kc in [KEY_C, KEY_E, KEY_TAB]: state = "play"
		elif kc == KEY_I: state = "inv"
		elif kc == KEY_N: state = "social"
		return
	if state == "quest":
		if kc in [KEY_Q, KEY_I, KEY_E]: state = "play"
		return
	if state == "social":
		if kc in [KEY_N, KEY_E, KEY_I]: state = "play"
		return
	if state == "house_menu":
		if kc in [KEY_B, KEY_E]:
			state = "play"
			_play_sfx("click")
		elif kc == KEY_TAB:
			house_tab = (house_tab + 1) % 2
			_play_sfx("click")
		return
	if state == "chest":
		if kc in [KEY_E, KEY_I]:
			state = "play"
			_play_sfx("click")
		return
	if state != "play":
		return

	# Play Mode Hotkeys
	if kc >= KEY_1 and kc <= KEY_8:
		var s_idx := kc - KEY_1
		if s_idx == 5 and p.slot == 5: seed_choice_idx += 1
		elif s_idx == 6 and p.slot == 6: consumable_choice_idx += 1
		p.slot = s_idx
		_play_sfx("click")
	elif kc == KEY_SPACE:
		_dodge_roll()
	elif kc == KEY_J:
		_use_hotbar_tool()
	elif kc == KEY_X:
		_whirlwind_skill()
	elif kc == KEY_E:
		_interact_nearest()
	elif kc == KEY_F:
		_pet_karabas()
	elif kc == KEY_R:
		_throw_bone()
	elif kc == KEY_H:
		_quick_heal()
	elif kc in [KEY_I, KEY_TAB]:
		state = "inv"
		_play_sfx("click")
	elif kc == KEY_C:
		state = "char"
		_play_sfx("click")
	elif kc == KEY_Q:
		state = "quest"
		_play_sfx("click")
	elif kc == KEY_N:
		state = "social"
		_play_sfx("click")
	elif kc == KEY_B and in_house:
		state = "house_menu"
		_play_sfx("click")
	elif kc == KEY_F5:
		_save_game()

func _title_choose(idx: int) -> void:
	_play_sfx("click")
	if idx == 0:
		if FileAccess.file_exists(SAVE_PATH) and _load_game():
			state = "play"
			cam.position = p.pos
			cam.reset_smoothing()
			_toast("Tekrar hoş geldin! Seviye %d" % p.level, Color(1.0, 0.9, 0.5))
		else:
			_toast("Kayıtlı oyun bulunamadı.", Color(1.0, 0.5, 0.5))
	elif idx == 1:
		_new_game()
		cam.position = p.pos
		cam.reset_smoothing()
	else:
		get_tree().quit()

func _pause_choose(idx: int) -> void:
	_play_sfx("click")
	if idx == 0:
		state = "play"
	elif idx == 1:
		_save_game()
		state = "play"
	else:
		_save_game(true)
		state = "title"
		title_sel = 0

func _handle_ui_click(cr: Dictionary, right := false) -> void:
	_play_sfx("click")
	match cr.action:
		"title": _title_choose(cr.val)
		"pause": _pause_choose(cr.val)
		"open_char": state = "char" if state != "char" else "play"
		"open_inv": state = "inv" if state != "inv" else "play"
		"open_quest": state = "quest" if state != "quest" else "play"
		"open_social": state = "social" if state != "social" else "play"
		"open_house_menu":
			if in_house:
				state = "house_menu" if state != "house_menu" else "play"
		"house_tab": house_tab = cr.val
		"build_upgrade": _build_house_upgrade(cr.val)
		"set_floor": _set_house_decor("floor", int(cr.val))
		"set_rug": _set_house_decor("rug", int(cr.val))
		"set_wall": _set_house_decor("wall", int(cr.val))
		"toggle_decor": _set_house_decor(cr.val, not bool(house_decor.get(cr.val, true)))
		"chest_store": _chest_store(cr.val)
		"chest_take": _chest_take(cr.val)
		"close_modal": state = "play"
		"smith_tab": smith_tab = cr.val
		"dlg_chat": _do_talk_chat()
		"dlg_gift": state = "gift"
		"dlg_service": _open_npc_service()
		"dlg_close": state = "play"
		"give_gift": _give_gift_to_npc(cr.val)
		"gear":
			if right: _sell_gear(cr.val)
			else: _equip_gear(cr.val)
		"unequip":
			var g = equipped[cr.val]
			if g != null:
				if gear_bag.size() >= 24:
					_toast("Ekipman çantası dolu!", Color(1.0, 0.5, 0.5))
				else:
					equipped[cr.val] = null
					gear_bag.append(g)
					_refresh_stats()
		"hotbar":
			var idx: int = cr.val
			if idx == 5 and p.slot == 5: seed_choice_idx += 1
			elif idx == 6 and p.slot == 6: consumable_choice_idx += 1
			p.slot = idx
		"station_pick": _execute_station_choice(cr.val)
		"select_seed":
			seed_choice_idx = cr.val
			p.slot = 5
			state = "play"
		"eat_item":
			var cid: String = cr.val
			var ls := _get_consumable_list()
			var idx := ls.find(cid)
			if idx >= 0:
				consumable_choice_idx = idx
				_consume_active_item()
		"turn_in_daily":
			if not daily_quest.done and _take_bag(daily_quest.need_id, daily_quest.need_cnt):
				daily_quest.done = true
				p.gold += daily_quest.reward
				_play_sfx("coin")
				_toast("Köy İlanı Tamamlandı! +%d Altın!" % daily_quest.reward, Color(1.0, 0.9, 0.3))
			else:
				_toast("Gerekli eşyalar henüz tamamlanmadı!", Color(1.0, 0.5, 0.5))

func _disc(vid: String, base_price: int) -> int:
	if _has_perk(vid, 3):
		return int(round(base_price * 0.85))
	return base_price

func _execute_station_choice(idx: int) -> void:
	if state == "shop":
		var shop_opts := [
			{"id": "seed_parsnip", "cnt": 2, "price": _disc("ayla", 30), "label": "Yaban Havucu Tohumu x2"},
			{"id": "seed_carrot", "cnt": 2, "price": _disc("ayla", 40), "label": "Havuç Tohumu x2"},
			{"id": "seed_potato", "cnt": 2, "price": _disc("ayla", 50), "label": "Patates Tohumu x2"},
			{"id": "seed_sunflower", "cnt": 2, "price": _disc("ayla", 70), "label": "Ayçiçeği Tohumu x2"},
			{"id": "seed_pumpkin", "cnt": 2, "price": _disc("ayla", 100), "label": "Balkabağı Tohumu x2"},
			{"id": "buy_chicken", "cnt": 1, "price": _disc("ayla", 200), "label": "Yeni Çiftlik Tavuğu"},
		]
		if idx < shop_opts.size():
			var o: Dictionary = shop_opts[idx]
			if p.gold >= o.price:
				p.gold -= o.price
				_play_sfx("coin")
				if o.id == "buy_chicken":
					animals.append({"type": "chicken", "name": "Civciv", "pos": Vector2(880, 610), "goal": Vector2(760, 560), "flip": false, "t": 0.0, "wait": 1.0, "petted": false})
					_toast("Çiftliğine yeni bir Tavuk katıldı!", Color(1.0, 0.9, 0.5))
				else:
					_add_bag(o.id, o.cnt)
			else:
				_toast("Yetersiz Altın!", Color(1.0, 0.5, 0.5))

	elif state == "tavern":
		var opts := [
			["pot_heal", 1, _disc("meryem", 35)],
			["pot_heal", 5, _disc("meryem", 160)],
			["pot_iron", 1, _disc("meryem", 95)],
			["meal_warrior", 1, _disc("meryem", 180)],
			["pot_spirit", 1, _disc("meryem", 140)],
		]
		if idx < opts.size():
			var o: Array = opts[idx]
			if p.gold >= o[2]:
				p.gold -= o[2]
				_add_bag(o[0], o[1])
				_play_sfx("coin")
			else:
				_toast("Yetersiz Altın!", Color(1.0, 0.5, 0.5))

	elif state == "alchemy_shop":
		var opts := [["pot_growth", 1, 110], ["pot_rain", 1, 130], ["pot_iron", 2, 160], ["pot_spirit", 1, 120]]
		if idx < opts.size():
			var o: Array = opts[idx]
			if p.gold >= o[2]:
				p.gold -= o[2]
				_add_bag(o[0], o[1])
				_play_sfx("coin")
			else:
				_toast("Yetersiz Altın!", Color(1.0, 0.5, 0.5))

	elif state == "fisher_trade":
		var opts := [["meal_fish", 1, 110], ["pot_heal", 2, 65], ["copper_ore", 2, 90]]
		if idx < opts.size():
			var o: Array = opts[idx]
			if p.gold >= o[2]:
				p.gold -= o[2]
				_add_bag(o[0], o[1])
				_play_sfx("coin")
			else:
				_toast("Yetersiz Altın!", Color(1.0, 0.5, 0.5))

	elif state == "loot_buyer":
		if idx == 0:
			var sum := 0
			var cnt := 0
			for id in bag.keys().duplicate():
				if GameData.ITEMS[id].type == "loot" and not id.begins_with("boss_trophy_"):
					var c: int = bag[id]
					sum += int(round(GameData.ITEMS[id].sell * 1.25 * c))
					cnt += c
					bag.erase(id)
			if sum > 0:
				p.gold += sum
				_play_sfx("coin")
				_toast("Lina tüm av ganimetlerini +%25 primle aldı: +%d Altın!" % sum, Color(1.0, 0.88, 0.35))
			else:
				_toast("Çantanda satılacak canavar ganimeti yok!", Color(0.85, 0.85, 0.85))
		elif idx == 1:
			var lv := maxi(2, p.level)
			if p.gold >= 320 and gear_bag.size() < 24:
				p.gold -= 320
				var slot: String = ["weapon", "armor", "shield", "ring"][randi() % 4]
				var g := _make_gear(slot, lv, maxi(2, _roll_rarity(25.0)))
				gear_bag.append(g)
				_play_sfx("catch")
				_toast("Gizemli Sandıktan Çıktı: %s!" % g.name, GameData.RARITY[g.rarity].col)
			else:
				_toast("320 Altın ve çantada yer gerekir!", Color(1.0, 0.5, 0.5))

	elif state == "alchemy":
		var recipes := [
			{"out": "pot_growth", "req": {"mush_red": 2, "parsnip": 1}},
			{"out": "pot_rain", "req": {"mush_glow": 1, "mush_red": 1}},
			{"out": "pot_spirit", "req": {"mush_glow": 1, "spirit_crystal": 1}},
			{"out": "pot_iron", "req": {"copper_ore": 1, "mush_red": 1}},
		]
		if idx < recipes.size():
			_craft_recipe(recipes[idx])

	elif state == "cook":
		var recipes := [
			{"out": "meal_breakfast", "req": {"egg": 1, "milk": 1}},
			{"out": "meal_fish", "req": {"fish_trout": 1, "wood": 2}},
			{"out": "meal_stew", "req": {"carrot": 1, "potato": 1}},
			{"out": "meal_pie", "req": {"pumpkin": 1, "egg": 1}},
			{"out": "meal_warrior", "req": {"fish_sun": 1, "carrot": 1}},
		]
		if idx < recipes.size():
			_craft_recipe(recipes[idx])

	elif state == "smith":
		_execute_smith_choice(idx)

func _execute_smith_choice(idx: int) -> void:
	if smith_tab == 0:
		# Silah & Zırh Satın Al
		var lv := maxi(2, p.level)
		var shop_gear := [
			["weapon", 2, 1, 180], # Bakır Kılıç (Kaliteli)
			["weapon", 3, 2, 420], # Altın/Çelik Kılıç (Nadir)
			["armor", 1, 1, 200],  # Deri Yelek (Kaliteli - Yeşil Görünüm!)
			["armor", 4, 2, 520],  # Zincir Zırh (Nadir - Çelik Şövalye Görünüm!)
			["shield", 0, 1, 160], # Ahşap Kalkan
			["shield", 3, 2, 440], # Şövalye Kalkanı
		]
		if idx < shop_gear.size():
			var sg: Array = shop_gear[idx]
			var price := _disc("demir", sg[3])
			if gear_bag.size() >= 24:
				_toast("Ekipman çantası dolu (24)!", Color(1.0, 0.5, 0.5))
			elif p.gold >= price:
				p.gold -= price
				var g := _make_gear(sg[0], lv, sg[2], sg[1])
				gear_bag.append(g)
				_play_sfx("coin")
				_toast("%s satın alındı! [C] ile kuşan!" % g.name, GameData.RARITY[g.rarity].col)
			else:
				_toast("Yetersiz Altın! (%d G)" % price, Color(1.0, 0.5, 0.5))

	elif smith_tab == 1:
		# Güçlendir (+1..+5) & Aletler
		if idx == 0:
			_upgrade_equipped_slot("weapon")
		elif idx == 1:
			_upgrade_equipped_slot("armor")
		elif idx == 2 and p.hoe_tier == 1:
			if p.gold >= _disc("demir", 150) and _has_bag("copper_ore", 3):
				p.gold -= _disc("demir", 150)
				_take_bag("copper_ore", 3)
				p.hoe_tier = 2
				_play_sfx("catch")
				_toast("Bakır Çapa Geliştirildi! Tek vuruşta 3 kare çapalar!", Color(1.0, 0.85, 0.3))
			else:
				_toast("Gereken: 150 Altın + 3 Bakır Cevheri!", Color(1.0, 0.5, 0.5))
		elif idx == 3 and p.hoe_tier == 2:
			if p.gold >= _disc("demir", 350) and _has_bag("gold_ore", 2):
				p.gold -= _disc("demir", 350)
				_take_bag("gold_ore", 2)
				p.hoe_tier = 3
				_play_sfx("catch")
				_toast("ALTIN ÇAPA! Artık 3x3 (9 kare) çapalar!", Color(1.0, 0.9, 0.3))
			else:
				_toast("Gereken: 350 Altın + 2 Altın Cevheri!", Color(1.0, 0.5, 0.5))
		elif idx == 4 and p.water_tier == 1:
			if p.gold >= _disc("demir", 150) and _has_bag("copper_ore", 3):
				p.gold -= _disc("demir", 150)
				_take_bag("copper_ore", 3)
				p.water_tier = 2
				p.water_max = 40
				p.water_tank = 40
				_play_sfx("catch")
				_toast("Bakır Sulama Kabı Geliştirildi! 3 kare sular!", Color(0.5, 0.88, 1.0))
			else:
				_toast("Gereken: 150 Altın + 3 Bakır Cevheri!", Color(1.0, 0.5, 0.5))

	elif smith_tab == 2:
		# Boss Ganimeti Efsanevi Set Dövme
		var forge_recipes := [
			{"slot": "weapon", "bi": 10, "rar": 3, "lvl": 6, "gold": 250, "mats": {"boss_trophy_orc": 1, "copper_ore": 3}},
			{"slot": "armor", "bi": 6, "rar": 3, "lvl": 10, "gold": 450, "mats": {"boss_trophy_blood": 1, "gold_ore": 3}},
			{"slot": "weapon", "bi": 9, "rar": 4, "lvl": 15, "gold": 800, "mats": {"boss_trophy_demon": 1, "spirit_crystal": 3}},
			{"slot": "armor", "bi": 8, "rar": 4, "lvl": 15, "gold": 800, "mats": {"boss_trophy_demon": 1, "ancient_skull": 2}},
		]
		if idx < forge_recipes.size():
			var fr: Dictionary = forge_recipes[idx]
			var cost_g := _disc("demir", fr.gold)
			if gear_bag.size() >= 24:
				_toast("Ekipman çantası dolu!", Color(1.0, 0.5, 0.5))
				return
			if p.gold < cost_g:
				_toast("Yetersiz Altın! (%d G)" % cost_g, Color(1.0, 0.5, 0.5))
				return
			for mk in fr.mats.keys():
				if not _has_bag(mk, fr.mats[mk]):
					_toast("Eksik malzeme: %d %s!" % [fr.mats[mk], GameData.ITEMS[mk].name], Color(1.0, 0.5, 0.5))
					return
			p.gold -= cost_g
			for mk in fr.mats.keys():
				_take_bag(mk, fr.mats[mk])
			var g := _make_gear(fr.slot, fr.lvl, fr.rar, fr.bi)
			gear_bag.append(g)
			_play_sfx("levelup")
			_spawn_fx("fx_sparkle", p.pos + Vector2(0, -16), 16.0, 1.1, GameData.RARITY[g.rarity].col)
			_toast("DÖVÜLDÜ: %s! [C] ile kuşan!" % g.name, GameData.RARITY[g.rarity].col)
			_advance_story(8, 1)

func _upgrade_cost(pl: int) -> Array:
	var cost_g := _disc("demir", 80 + pl * 110)
	var bones := 2 + pl * 2
	var ore_id := "copper_ore" if pl < 2 else "gold_ore"
	var ores := 2 + (pl if pl < 2 else pl - 1)
	return [cost_g, bones, ore_id, ores]

func _upgrade_equipped_slot(slot: String) -> void:
	var g = equipped.get(slot, null)
	if g == null:
		_toast("Önce bir %s kuşan [C]!" % ("Silah" if slot == "weapon" else "Zırh"), Color(1.0, 0.5, 0.5))
		return
	var pl: int = g.get("plus", 0)
	if pl >= 5:
		_toast("%s zaten maksimum (+5)!" % g.name, Color(1.0, 0.85, 0.35))
		return
	var c := _upgrade_cost(pl)
	if p.gold >= c[0] and _has_bag("monster_bone", c[1]) and _has_bag(c[2], c[3]):
		p.gold -= c[0]
		_take_bag("monster_bone", c[1])
		_take_bag(c[2], c[3])
		g.plus = pl + 1
		_refresh_stats()
		_play_sfx("levelup")
		_spawn_fx("fx_sparkle", p.pos + Vector2(0, -14), 15.0, 0.9)
		_toast("%s → +%d güçlendirildi!" % [g.name, g.plus], GameData.RARITY[g.rarity].col)
		_advance_story(8, 1)
	else:
		_toast("Gereken: %dG + %d Kemik + %d %s" % [c[0], c[1], c[3], GameData.ITEMS[c[2]].name], Color(1.0, 0.5, 0.5))

func _craft_recipe(rec: Dictionary) -> void:
	for k in rec.req.keys():
		if not _has_bag(k, rec.req[k]):
			_toast("Eksik malzeme: %s!" % GameData.ITEMS[k].name, Color(1.0, 0.5, 0.5))
			return
	for k in rec.req.keys():
		_take_bag(k, rec.req[k])
	_add_bag(rec.out, 1)
	_play_sfx("catch")
	_spawn_fx("fx_sparkle", p.pos + Vector2(0, -16), 16.0, 0.8)
	_toast("Üretildi: %s!" % GameData.ITEMS[rec.out].name, Color(0.5, 1.0, 0.7))
	_advance_story(5, 1)

func _house_upgrade_def(uid: String) -> Dictionary:
	for u in GameData.HOUSE_UPGRADES:
		if u.id == uid:
			return u
	return {}

func _build_house_upgrade(uid: String) -> void:
	if house_upgrades.get(uid, false):
		_toast("Bu geliştirme zaten kurulu!", Color(0.85, 0.9, 1.0))
		return
	var u: Dictionary = _house_upgrade_def(uid)
	if u.is_empty():
		return
	var min_lv: int = int(u.min_lvl)
	if p.level < min_lv:
		_toast("Seviye %d gerekli!" % min_lv, Color(1.0, 0.5, 0.5))
		return
	var need_boss: String = str(u.need_boss)
	if need_boss != "" and not bosses_defeated.get(need_boss, false):
		_toast("Önce Savaş Lordu Grog'u yenmelisin!", Color(1.0, 0.5, 0.5))
		return
	var cost_g: int = int(u.gold)
	if p.gold < cost_g:
		_toast("Yetersiz Altın! (%d G)" % cost_g, Color(1.0, 0.5, 0.5))
		return
	var mats: Dictionary = u.mats
	for mk in mats.keys():
		var need_cnt: int = int(mats[mk])
		if not _has_bag(mk, need_cnt):
			_toast("Eksik malzeme: %d %s!" % [need_cnt, GameData.ITEMS[mk].name], Color(1.0, 0.5, 0.5))
			return
	p.gold -= cost_g
	for mk in mats.keys():
		_take_bag(mk, int(mats[mk]))
	house_upgrades[uid] = true
	_play_sfx("levelup")
	_spawn_fx("fx_sparkle", p.pos + Vector2(0, -16), 14.0, 1.2, Color(1.0, 0.9, 0.4))
	_toast("%s evine kuruldu!" % u.name, Color(0.6, 1.0, 0.65))
	_advance_story(5, 1)

func _set_house_decor(field: String, val) -> void:
	house_decor[field] = val
	_play_sfx("blip")

func _chest_store(item_id: String) -> void:
	if not _take_bag(item_id, 1):
		return
	house_chest[item_id] = int(house_chest.get(item_id, 0)) + 1
	_play_sfx("blip")

func _chest_take(item_id: String) -> void:
	var have: int = int(house_chest.get(item_id, 0))
	if have <= 0:
		return
	house_chest[item_id] = have - 1
	if house_chest[item_id] <= 0:
		house_chest.erase(item_id)
	_add_bag(item_id, 1, true)
	_play_sfx("blip")

# ==============================================================================
#  WORLD DRAWING & DAY/NIGHT LIGHTING
# ==============================================================================
func _update_lights() -> void:
	if in_house:
		var h_f: float = hour + minute / 60.0
		var warm := Color(0.95, 0.90, 0.84, 1.0) if (h_f >= 6.0 and h_f < 19.0) else Color(0.70, 0.64, 0.60, 1.0)
		cmod.color = warm
		L_player.position = p.pos + Vector2(0, -14)
		L_player.energy = 0.22
		L_fire.position = INT_FIRE_POS - Vector2(0, 16)
		L_fire.energy = (1.15 if house_upgrades.get("grand_home", false) else 0.92) + sin(t * 9.0) * 0.1
		L_farm.position = Vector2(136, 92)
		L_farm.energy = 0.55 if (h_f >= 6.0 and h_f < 19.0) else 0.22
		L_shrine.position = Vector2(354, 92)
		L_shrine.energy = 0.55 if (h_f >= 6.0 and h_f < 19.0) else 0.22
		L_boss2.energy = 0.0
		L_boss3.energy = 0.0
		return

	var h_float := hour + minute / 60.0
	var base: Color = SEASON_MODS[season]
	var factor := 1.0
	if h_float >= 18.0:
		factor = lerpf(1.0, 0.48, clampf((h_float - 18.0) / 4.0, 0.0, 1.0))
	elif h_float < 7.0:
		factor = lerpf(0.58, 1.0, clampf((h_float - 5.0) / 2.0, 0.0, 1.0))
	if is_raining:
		factor *= 0.86
	cmod.color = Color(base.r * factor, base.g * factor, base.b * (factor * 0.94 + 0.06), 1.0)
	L_player.position = p.pos + Vector2(0, -16)
	L_player.energy = 0.28 if factor > 0.85 else 0.9
	L_farm.position = Vector2(400, 360)
	L_farm.energy = 0.75
	L_fire.position = FIRE_POS
	L_fire.energy = 0.95 + sin(t * 10.0) * 0.14
	L_shrine.energy = 0.0
	L_boss2.energy = 0.8 + sin(t * 5.0) * 0.15
	L_boss3.energy = 1.1 + sin(t * 7.0) * 0.18

func _draw_bg() -> void:
	var vs := get_viewport_rect().size
	bg_node.draw_rect(Rect2(Vector2.ZERO, vs), Color("160d08") if in_house else Color(0.11, 0.17, 0.12))

func _spr(c: CanvasItem, key: String, frame: int, pos: Vector2, opts := {}) -> void:
	if not S.has(key):
		return
	var ss: Dictionary = S[key]
	var f := posmod(frame, ss.n)
	var flip: bool = opts.get("flip", false)
	var sc: float = opts.get("sc", 1.0)
	var col: Color = opts.get("col", Color.WHITE)
	var px_step := 1.0
	if c != hud:
		if cam != null and cam.zoom.x > 0.0:
			px_step = 1.0 / cam.zoom.x
		sc = maxf(px_step, roundf(sc / px_step) * px_step)
	var w: float = ss.fw * sc
	var h: float = ss.fh * sc
	var x: float = roundf((pos.x - (ss.fw - ss.ax if flip else ss.ax) * sc) / px_step) * px_step
	var y: float = roundf((pos.y - ss.ay * sc) / px_step) * px_step
	var dst := Rect2(x, y, (-w if flip else w), h)
	var src := Rect2(ss.ox + f * ss.fw, ss.oy, ss.fw, ss.fh)
	c.draw_texture_rect_region(ss.t, dst, src, col)

func _tile_idx(c: CanvasItem, idx: int, pos: Vector2, col := Color.WHITE) -> void:
	if not S.has("terrain"):
		return
	c.draw_texture_rect_region(S["terrain"].t, Rect2(pos, Vector2(TILE_SIZE, TILE_SIZE)), Rect2(idx * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE), col)

func _shadow(c: CanvasItem, pos: Vector2, rx: float, alpha := 0.28) -> void:
	if rx > 30.0:
		alpha *= 0.55
	c.draw_set_transform(pos, 0.0, Vector2(1.0, 0.3 if rx > 30.0 else 0.42))
	c.draw_circle(Vector2.ZERO, rx, Color(0, 0, 0, alpha))
	c.draw_set_transform(Vector2.ZERO)

func _draw_house_interior() -> void:
	# Rich carved exterior cabin framing
	world.draw_rect(Rect2(20, 18, 440, 314), Color("24130a"))
	world.draw_rect(Rect2(26, 22, 428, 304), Color("4f2d19"))
	world.draw_rect(Rect2(30, 26, 420, 294), Color("2d190d"))

	# 1. Floor Tiles (16x16, 4 selectable styles in int_floors)
	var floor_idx: int = clampi(int(house_decor.get("floor", 0)), 0, 3)
	if S.has("int_floors"):
		var ftex: Texture2D = S["int_floors"].t
		for fy in range(104, 304, 16):
			for fx in range(32, 448, 16):
				var tile_id: int = floor_idx * 2 + (((int(fx) / 16) + (int(fy) / 16)) % 2)
				world.draw_texture_rect_region(ftex, Rect2(fx, fy, 16, 16), Rect2(tile_id * 16, 0, 16, 16))
	# Wainscoting shadow beneath back wall
	world.draw_rect(Rect2(32, 104, 416, 5), Color(0, 0, 0, 0.25))

	# 2. Back Wall Tiles (y = 28..104)
	var wall_idx: int = clampi(int(house_decor.get("wall", 0)), 0, 2)
	var wkey := "int_wall_%d" % wall_idx
	if S.has(wkey):
		var ws: Dictionary = S[wkey]
		for wx in range(32, 448, 48):
			var draw_w: float = minf(48.0, 448.0 - float(wx))
			world.draw_texture_rect_region(ws.t, Rect2(wx, 28, draw_w, 76), Rect2(0, 0, draw_w, ws.fh))
	# Timber wainscoting trim bar
	world.draw_rect(Rect2(32, 98, 416, 6), Color("5d361d"))
	world.draw_rect(Rect2(32, 97, 416, 2), Color("8b5832"))

	# 3. Shuttered Windows + Warm Sunlight Patches
	for win_x in [134.0, 354.0]:
		_spr(world, "window", 0, Vector2(win_x, 80), {"sc": 1.0})
		if hour >= 6 and hour < 19:
			world.draw_polygon(
				PackedVector2Array([Vector2(win_x - 16, 106), Vector2(win_x + 16, 106), Vector2(win_x + 26, 166), Vector2(win_x - 6, 166)]),
				PackedColorArray([Color(1.0, 0.94, 0.72, 0.14), Color(1.0, 0.94, 0.72, 0.14), Color(1.0, 0.92, 0.65, 0.02), Color(1.0, 0.92, 0.65, 0.02)])
			)

	# 4. Wall Art & Boss Trophies
	if house_decor.get("wall_art", true):
		_spr(world, "painting", 0, Vector2(72, 74), {"sc": 1.0})
		_spr(world, "wall_sword", 0, Vector2(414, 54), {"sc": 1.0})
		_spr(world, "wall_axe", 0, Vector2(414, 70), {"sc": 1.0})
	if bosses_defeated.get("grog", false):
		_spr(world, "trophy_wolf", 0, Vector2(194, 68), {"sc": 1.0})
	if bosses_defeated.get("korgath", false):
		_spr(world, "trophy_bear", 0, Vector2(288, 68), {"sc": 1.0})

	# 5. Center Floor Rug (exact integer 2x scale)
	var rug_idx: int = clampi(int(house_decor.get("rug", 0)), 0, 3)
	if rug_idx < 3:
		var rkeys := ["rug_beige", "rug_green", "rug_royal"]
		var rk: String = rkeys[rug_idx]
		if S.has(rk):
			var rs: Dictionary = S[rk]
			var rw: float = float(rs.fw) * 2.0
			var rh: float = float(rs.fh) * 2.0
			world.draw_texture_rect(rs.t, Rect2(240.0 - rw * 0.5, 212.0 - rh * 0.5, rw, rh), false)

	# 6. Threshold Exit Doormat & Bottom Doorframe
	world.draw_rect(Rect2(216, 294, 48, 12), Color("8c4d27"))
	world.draw_rect(Rect2(218, 296, 44, 8), Color("b87644"))
	world.draw_rect(Rect2(218, 304, 44, 24), Color("1e110a"))
	_spr(world, "door_int", 0, Vector2(240, 330), {"sc": 1.0})

	# 7. Y-Sorted Furniture, Upgraded Stations, Boss Sword Mantel, Karabas & Hero
	var items_y: Array = []
	items_y.append({"y": INT_FIRE_POS.y, "fn": func():
		_spr(world, "fireplace", 0, INT_FIRE_POS, {"sc": 1.0})
		_spr(world, "fire", int(t * 10), INT_FIRE_POS - Vector2(0, 6), {"sc": 0.5})
		if bosses_defeated.get("malakor", false):
			_spr(world, "wall_sword", 0, INT_FIRE_POS - Vector2(0, 60), {"sc": 1.0, "col": Color(1.4, 1.1, 0.45)})
	})

	var bed_k := "bed_double" if house_upgrades.get("grand_home", false) else "bed_single"
	items_y.append({"y": INT_BED_POS.y, "fn": func():
		_shadow(world, INT_BED_POS - Vector2(0, 2), 18.0, 0.2)
		_spr(world, bed_k, 0, INT_BED_POS, {"sc": 1.0})
	})
	items_y.append({"y": INT_CHEST_POS.y, "fn": func():
		_shadow(world, INT_CHEST_POS, 12.0, 0.22)
		_spr(world, "chest", 0, INT_CHEST_POS, {"sc": 1.0})
	})
	items_y.append({"y": INT_BENCH_POS.y, "fn": func():
		_shadow(world, INT_BENCH_POS, 18.0, 0.22)
		_spr(world, "workbench", 0, INT_BENCH_POS, {"sc": 1.0})
	})

	if house_upgrades.get("kitchen", false):
		items_y.append({"y": 124.0, "fn": func():
			_shadow(world, Vector2(368, 124), 30.0, 0.2)
			_spr(world, "kitchen_counter", 0, Vector2(368, 124), {"sc": 1.0})
			_spr(world, "kitchen_stove", 0, Vector2(430, 124), {"sc": 1.0})
		})
	if house_upgrades.get("alchemy", false):
		items_y.append({"y": INT_ALCHEMY_POS.y, "fn": func():
			_shadow(world, INT_ALCHEMY_POS, 14.0, 0.24)
			_spr(world, "station_alchemy", int(t * 7), INT_ALCHEMY_POS, {"sc": 1.0})
		})
	if house_upgrades.get("forge", false):
		items_y.append({"y": INT_FORGE_POS.y, "fn": func():
			_shadow(world, INT_FORGE_POS, 22.0, 0.24)
			_spr(world, "station_forge", 0, INT_FORGE_POS, {"sc": 0.5})
		})

	if house_decor.get("dining", true):
		items_y.append({"y": 114.0, "fn": func(): _spr(world, "bookshelf", 0, Vector2(290, 114), {"sc": 1.0})})
		items_y.append({"y": 234.0, "fn": func():
			_shadow(world, Vector2(332, 232), 16.0, 0.22)
			_spr(world, "chair", 0, Vector2(304, 234), {"sc": 1.0})
			_spr(world, "stool", 0, Vector2(360, 234), {"sc": 1.0})
			_spr(world, "table_round", 0, Vector2(332, 232), {"sc": 1.0})
			_spr(world, "sunflower_pot", 0, Vector2(332, 212), {"sc": 1.0})
		})

	if house_decor.get("plants", true):
		items_y.append({"y": 122.0, "fn": func(): _spr(world, "plant_0", 0, Vector2(44, 122), {"sc": 1.0})})
		items_y.append({"y": 290.0, "fn": func(): _spr(world, "plant_1", 0, Vector2(432, 290), {"sc": 1.0})})
		items_y.append({"y": 290.0, "fn": func(): _spr(world, "plant_2", 0, Vector2(50, 290), {"sc": 1.0})})

	if house_decor.get("dog_corner", true):
		items_y.append({"y": INT_DOG_BOWL.y, "fn": func(): _spr(world, "dog_bowl", 0, INT_DOG_BOWL, {"sc": 1.5})})

	items_y.append({"y": dog.pos.y, "fn": func():
		_shadow(world, dog.pos, 8.0, 0.24)
		var dfr := int(dog.t * 11) if dog.moving else 0
		_spr(world, "dog_karabas", dfr, dog.pos, {"flip": dog.flip, "sc": 0.68})
	})
	items_y.append({"y": p.pos.y, "fn": func():
		_shadow(world, p.pos, 10.0, 0.25)
		var tier := _hero_skin_tier()
		var pk := "hero%d_%s" % [tier, p.anim]
		if not S.has(pk): pk = "hero0_idle"
		var pfr := int(p.at * (18 if p.act_t > 0 else (11 if p.anim in ["walk", "run"] else 8)))
		_spr(world, pk, pfr, p.pos, {"flip": p.flip, "sc": 1.45})
	})

	items_y.sort_custom(func(a, b): return a.y < b.y)
	for item in items_y:
		item.fn.call()

	for f in fxs:
		_spr(world, f.n, int(f.t * f.fps), f.pos, {"sc": f.sc, "col": f.col})

func _draw_world() -> void:
	if in_house:
		_draw_house_interior()
		return
	var world_vs := get_viewport_rect().size / cam.zoom
	var view := Rect2(cam.get_screen_center_position() - world_vs / 2.0, world_vs).grow(96)

	var gx0 := maxi(0, int(floor(view.position.x / TILE_SIZE)))
	var gy0 := maxi(0, int(floor(view.position.y / TILE_SIZE)))
	var gx1 := mini(TILE_COLS, int(ceil(view.end.x / TILE_SIZE)))
	var gy1 := mini(TILE_ROWS, int(ceil(view.end.y / TILE_SIZE)))

	var grass_tint := Color(1.0, 1.0, 1.0)
	if season == 1: grass_tint = Color(1.05, 1.02, 0.88)
	elif season == 2: grass_tint = Color(1.12, 0.92, 0.68)

	# 1. Precomputed Lush Terrain Grid
	for gy in range(gy0, gy1):
		for gx in range(gx0, gx1):
			var tid: int = terrain_map[gy * TILE_COLS + gx]
			var pos := Vector2(gx * TILE_SIZE, gy * TILE_SIZE)
			var hsh := absi(gx * 73 + gy * 31)
			match tid:
				0: # Meadow Grass
					if season == 3:
						_tile_idx(world, 19 + (hsh % 2), pos)
					else:
						var g_var := 0 if (hsh % 7) < 4 else (2 + (hsh % 4))
						_tile_idx(world, g_var, pos, grass_tint)
				1: # Dirt Path
					_tile_idx(world, 6 + (hsh % 3), pos)
				2: # Village Cobble
					_tile_idx(world, 9 + (hsh % 3), pos)
				3: # Plaza Brick
					_tile_idx(world, 12 + (hsh % 3), pos)
				4: # Lake Sand
					_tile_idx(world, 15 + (hsh % 2), pos)
				5: # Animated Azure Water
					var wf := (int(t * 2.4) + ((gx + gy) % 2)) % 2
					_tile_idx(world, 17 + wf, pos)
				6: # Shadow Forest Grass
					if season == 3:
						_tile_idx(world, 19 + (hsh % 2), pos, Color(0.82, 0.86, 0.95))
					else:
						_tile_idx(world, 21 + (hsh % 3), pos, Color(0.88, 0.88, 0.98))
				7: # Dungeon Slate
					_tile_idx(world, 24 + (hsh % 3), pos)
				8: # Bloodstained Dungeon
					_tile_idx(world, 27 if (hsh % 3 == 0) else 24 + (hsh % 2), pos)
				9: # Royal Crimson Carpet
					_tile_idx(world, 28, pos)
				10: # Glowing Rune Grate
					_tile_idx(world, 29, pos)

	# Yol kenarı geçişleri: toprak yol ile çim arasındaki keskin cetvel çizgisini yumuşatır
	var fringe_col: Color = Color8(222, 230, 240) if season == 3 else Color8(110, 178, 76) * grass_tint
	var fringe_dark: Color = Color8(140, 92, 52)
	for gy in range(gy0, gy1):
		for gx in range(gx0, gx1):
			if terrain_map[gy * TILE_COLS + gx] != 1:
				continue
			var bx := gx * TILE_SIZE
			var by := gy * TILE_SIZE
			for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var nx: int = gx + d.x
				var ny: int = gy + d.y
				if nx < 0 or ny < 0 or nx >= TILE_COLS or ny >= TILE_ROWS:
					continue
				var nt: int = terrain_map[ny * TILE_COLS + nx]
				if nt != 0 and nt != 6:
					continue
				for i in 8:
					var hh := absi((gx * 131 + gy * 71 + i * 17 + d.x * 7 + d.y * 13) * 2654435) % 97
					var depth := 1 + (hh % 3)
					var along := i * 2
					var r: Rect2
					var rd: Rect2
					if d.y == -1:
						r = Rect2(bx + along, by, 2, depth)
						rd = Rect2(bx + along, by + depth, 2, 1)
					elif d.y == 1:
						r = Rect2(bx + along, by + TILE_SIZE - depth, 2, depth)
						rd = Rect2(bx + along, by + TILE_SIZE - depth - 1, 2, 1)
					elif d.x == -1:
						r = Rect2(bx, by + along, depth, 2)
						rd = Rect2(bx + depth, by + along, 1, 2)
					else:
						r = Rect2(bx + TILE_SIZE - depth, by + along, depth, 2)
						rd = Rect2(bx + TILE_SIZE - depth - 1, by + along, 1, 2)
					world.draw_rect(rd, fringe_dark)
					world.draw_rect(r, fringe_col)

	# Shoreline gentle foam highlights
	if view.end.y >= 1125 and view.position.y <= 1150:
		for wx in range(gx0 * TILE_SIZE, gx1 * TILE_SIZE, 32):
			var wave := sin(t * 2.5 + wx * 0.03) * 2.0
			world.draw_line(Vector2(wx + 2, 1137 + wave), Vector2(wx + 22, 1137 + wave), Color(0.88, 0.96, 1.0, 0.45), 1.5)

	# Wooden Pier at South Lake
	if view.intersects(Rect2(680, 1080, 84, 136)):
		world.draw_rect(Rect2(688, 1088, 64, 122), Color(0.46, 0.29, 0.16))
		for py in range(1092, 1206, 10):
			world.draw_rect(Rect2(691, py, 58, 7), Color(0.66, 0.44, 0.25))
		for px_p in [688, 746]:
			for py_p in [1120, 1165, 1202]:
				world.draw_rect(Rect2(px_p, py_p, 6, 10), Color(0.32, 0.19, 0.10))

	# Boss Arena Markings & Torches
	for ar in BOSS_ARENAS:
		if view.intersects(Rect2(ar.pos - Vector2(ar.radius + 30, ar.radius + 30), Vector2((ar.radius + 30) * 2, (ar.radius + 30) * 2))):
			var rcol := Color(0.9, 0.55, 0.25, 0.45) if ar.id == "grog" else (Color(0.95, 0.2, 0.25, 0.55) if ar.id == "korgath" else Color(1.0, 0.35, 0.15, 0.65))
			world.draw_arc(ar.pos, ar.radius - 12.0, 0, TAU, 64, rcol, 3.0)
			for ai in 8:
				var ang := ai * TAU / 8.0
				var pp: Vector2 = ar.pos + Vector2(cos(ang), sin(ang)) * (ar.radius - 10.0)
				world.draw_rect(Rect2(pp - Vector2(5, 13), Vector2(10, 15)), Color(0.28, 0.26, 0.34))
				world.draw_circle(pp - Vector2(0, 15), 3.2 + sin(t * 9.0 + ai) * 0.8, Color(1.0, 0.55, 0.2, 0.92))

	# Framed Wooden Garden Bed Border + Furrowed Soil Beds
	var farm_rect := Rect2(FARM_OX - 4, FARM_OY - 4, FARM_COLS * FARM_CELL + 8, FARM_ROWS * FARM_CELL + 8)
	if view.intersects(farm_rect.grow(16)):
		world.draw_rect(farm_rect, Color(0.34, 0.21, 0.12, 0.72), false, 3.0)
		for gy in range(FARM_ROWS):
			for gx in range(FARM_COLS):
				var c := Vector2i(gx, gy)
				var cx := FARM_OX + gx * FARM_CELL
				var cy := FARM_OY + gy * FARM_CELL
				if farm_grid.has(c) and farm_grid[c].tilled:
					var ti := 31 if farm_grid[c].watered else 30
					world.draw_texture_rect_region(S["terrain"].t, Rect2(cx + 1, cy + 1, FARM_CELL - 2, FARM_CELL - 2), Rect2(ti * TILE_SIZE, 0, TILE_SIZE, TILE_SIZE))
				else:
					# Boş tarla hücresi: debug ızgarası yerine hafif koyu çim lekesi + köşe işaretleri
					world.draw_rect(Rect2(cx + 1, cy + 1, FARM_CELL - 2, FARM_CELL - 2), Color(0.18, 0.30, 0.10, 0.10))
					var mk := Color(0.30, 0.20, 0.10, 0.35)
					world.draw_rect(Rect2(cx + 2, cy + 2, 2, 2), mk)
					world.draw_rect(Rect2(cx + FARM_CELL - 4, cy + FARM_CELL - 4, 2, 2), mk)

	# Farm Target Highlight
	if state == "play" and p.slot in [1, 2, 5]:
		var tc := _facing_farm_cell()
		var tier: int = p.hoe_tier if p.slot == 1 else (p.water_tier if p.slot == 2 else 1)
		for cell in _area_cells(tc, tier):
			if cell.x >= 0 and cell.x < FARM_COLS and cell.y >= 0 and cell.y < FARM_ROWS:
				world.draw_rect(Rect2(FARM_OX + cell.x * FARM_CELL, FARM_OY + cell.y * FARM_CELL, FARM_CELL, FARM_CELL), Color(1, 0.95, 0.45, 0.75), false, 1.5)

	# Pasture Fences & Meadow Accents
	for fx in range(656, 944, 32):
		_spr(world, "fence_h", 0, Vector2(fx + 16, 474))
		_spr(world, "fence_h", 0, Vector2(fx + 16, 666))

	var bush_key: String = ["bush_spring", "bush_summer", "bush_fall", "bush_winter"][season]
	for deco_p in [Vector2(290, 420), Vector2(305, 630), Vector2(620, 408), Vector2(1010, 390), Vector2(1140, 520), Vector2(1380, 690), Vector2(1890, 680)]:
		if view.has_point(deco_p):
			_shadow(world, deco_p, 11.0, 0.22)
			_spr(world, bush_key, 0, deco_p, {"sc": 0.9})
	for fl_i in 22:
		var fl_pos := Vector2(160 + ((fl_i * 197) % 1680), 210 + ((fl_i * 131) % 830))
		if view.has_point(fl_pos) and not farm_rect.grow(10).has_point(fl_pos):
			_spr(world, "flower_%d" % (fl_i % 4), 0, fl_pos, {"sc": 1.35})

	# Boss Lightning Strike Warning Rings
	for lz in lightning_zones:
		var pct := 1.0 - clampf(lz.t / 0.9, 0.0, 1.0)
		world.draw_circle(lz.pos, 34.0, Color(0.65, 0.35, 1.0, 0.16 + pct * 0.22))
		world.draw_arc(lz.pos, 34.0 * pct, 0, TAU, 32, Color(0.85, 0.6, 1.0, 0.85), 2.0)

	# 2. Y-Sorted Drawables with Soft Drop Shadows!
	var items_y: Array = []

	# Houses & Full Windmill Tower + Blades
	items_y.append({"y": 340.0, "fn": func():
		_shadow(world, Vector2(395, 340), 54.0, 0.26)
		_spr(world, "house_farm", 0, Vector2(395, 340))
		_spr(world, "smoke", int(t * 8), Vector2(442, 224))
	})
	items_y.append({"y": 340.0, "fn": func():
		_shadow(world, Vector2(235, 340), 32.0, 0.26)
		_spr(world, "windmill_tower", 0, Vector2(235, 340))
		_spr(world, "windmill", int(t * 7), Vector2(235, 256))
	})
	items_y.append({"y": 430.0, "fn": func():
		_shadow(world, Vector2(1465, 430), 54.0, 0.26)
		_spr(world, "house_shop", 0, Vector2(1465, 430))
	})
	items_y.append({"y": 430.0, "fn": func():
		_shadow(world, Vector2(1765, 430), 54.0, 0.26)
		_spr(world, "house_tavern", 0, Vector2(1765, 430))
	})

	# Dungeon Pillars & Banners at Boss 2 & Boss 3
	for dp in [Vector2(2565, 250), Vector2(2795, 250), Vector2(3135, 515), Vector2(3385, 515), Vector2(3135, 735), Vector2(3385, 735)]:
		if view.has_point(dp):
			items_y.append({"y": dp.y, "fn": func():
				_shadow(world, dp, 14.0, 0.35)
				_spr(world, "dungeon_pillar", 0, dp)
				_spr(world, "dungeon_banner", 0, dp + Vector2(0, -18))
			})

	# Clean Stations & Props
	items_y.append({"y": WELL_POS.y, "fn": func(): _shadow(world, WELL_POS, 12.0); _spr(world, "well", 0, WELL_POS)})
	items_y.append({"y": CRATE_POS.y, "fn": func(): _shadow(world, CRATE_POS, 12.0); _spr(world, "crate", 0, CRATE_POS, {"sc": 1.35}); _spr(world, "crate_top", 0, CRATE_POS - Vector2(0, 10), {"sc": 1.35})})
	items_y.append({"y": FORGE_POS.y, "fn": func(): _shadow(world, FORGE_POS, 28.0); _spr(world, "station_forge", 0, FORGE_POS, {"sc": 0.75})})
	items_y.append({"y": 490.0, "fn": func(): _shadow(world, Vector2(342, 490), 9.0); _spr(world, "scarecrow", 0, Vector2(342, 490), {"sc": 0.85})})
	items_y.append({"y": FIRE_POS.y, "fn": func(): _shadow(world, FIRE_POS, 14.0); _spr(world, "bonfire", int(t * 6), FIRE_POS, {"sc": 1.15}); _spr(world, "fire", int(t * 10), FIRE_POS - Vector2(0, 6))})
	items_y.append({"y": BOARD_POS.y, "fn": func(): _shadow(world, BOARD_POS, 20.0); _spr(world, "bench", 0, BOARD_POS, {"sc": 0.78})})

	# Crops
	for c in farm_grid.keys():
		var td: Dictionary = farm_grid[c]
		if td.crop != "":
			var cpos := Vector2(FARM_OX + c.x * FARM_CELL + 12, FARM_OY + c.y * FARM_CELL + 17)
			if view.has_point(cpos):
				var ck := "crop_%s_%d" % [td.crop, td.stage]
				items_y.append({"y": cpos.y, "fn": func(): _spr(world, ck, 0, cpos, {"sc": 1.3})})

	# Trees & Rocks & Forage
	var oak_key: String = ["oak_spring", "oak_summer", "oak_fall", "oak_winter"][season]
	for tr in trees:
		if view.has_point(tr.pos):
			var k: String = oak_key if tr.kind == "oak" else "pine"
			var tcol := Color(0.74, 0.72, 0.88) if tr.pos.x >= SHADOW_X else Color.WHITE
			items_y.append({"y": tr.pos.y, "fn": func(): _shadow(world, tr.pos, 16.0, 0.26); _spr(world, k, 0, tr.pos, {"col": tcol})})

	for rk in rocks:
		if view.has_point(rk.pos):
			var rkey: String = "rock_copper" if rk.kind == "gold" else "rock_" + rk.kind
			var rcol := Color(1.5, 1.25, 0.45) if rk.kind == "gold" else Color.WHITE
			items_y.append({"y": rk.pos.y, "fn": func(): _shadow(world, rk.pos, 10.0); _spr(world, rkey, 0, rk.pos, {"col": rcol})})

	for fn in forage_nodes:
		if view.has_point(fn.pos):
			items_y.append({"y": fn.pos.y, "fn": func(): _spr(world, fn.id, 0, fn.pos + Vector2(0, sin(t * 3.0 + fn.pos.x) * 1.5), {"sc": 1.2})})

	for gd in ground_drops:
		if view.has_point(gd.pos):
			if gd.has("sprite"):
				items_y.append({"y": gd.pos.y, "fn": func(): _spr(world, gd.sprite, 0, gd.pos + Vector2(0, sin(t * 4.0) * 1.5), {"sc": 1.15})})
			else:
				items_y.append({"y": gd.pos.y, "fn": func(): _draw_drop(gd)})

	# Animals
	for a in animals:
		if view.has_point(a.pos):
			items_y.append({"y": a.pos.y, "fn": func(): _shadow(world, a.pos, 8.0); _spr(world, a.type, int(a.t * 5), a.pos, {"flip": a.flip})})

	# NPCs
	for n in npcs:
		if view.has_point(n.pos):
			var nk: String = n.sheet + ("_walk" if n.moving else "_idle")
			var nfr := int(n.t * (8 if n.moving else 5))
			items_y.append({"y": n.pos.y, "fn": func(): _shadow(world, n.pos, 9.0); _spr(world, nk, nfr, n.pos, {"flip": n.face < 0})})

	# Enemies & Bosses
	for e in enemies:
		if view.has_point(e.pos):
			if e.dead and e.dead_t > 1.6:
				continue
			var st_anim := "idle"
			var fr := 0
			if e.dead:
				st_anim = "death"
				fr = mini(S[e.type + "_death"].n - 1, int(e.dead_t * 10))
			elif e.hit_t > 0 and S.has(e.type + "_hurt"):
				st_anim = "hurt"
				fr = int(e.t * 12)
			elif e.atk_anim_t > 0 and S.has(e.type + "_" + e.atk_anim):
				st_anim = e.atk_anim
				fr = int((0.65 - e.atk_anim_t) * 12)
			elif e.moving:
				st_anim = "walk" if S.has(e.type + "_walk") else "run"
				fr = int(e.t * 10)
			else:
				fr = int(e.t * 6)
			var ek := "%s_%s" % [e.type, st_anim]
			if not S.has(ek):
				ek = "%s_idle" % e.type
			var alpha := maxf(0.0, 1.0 - maxf(0.0, e.dead_t - 0.8) * 2.0) if e.dead else 1.0
			var tint: Color = GameData.ENEMY_DEFS[e.kind].tint
			var col := Color(tint.r, tint.g, tint.b, alpha)
			if e.hit_t > 0:
				col = Color(3.0, 3.0, 3.0, alpha)
			elif e.windup > 0 or e.slam_t > 0 or e.charge_t > 0.35:
				col = Color(2.2, 0.85, 0.65, alpha) if int(t * 16) % 2 == 0 else col
			var esc: float = GameData.ENEMY_DEFS[e.kind].sc
			items_y.append({"y": e.pos.y, "fn": func():
				_shadow(world, e.pos, 9.0 * esc, 0.32 * alpha)
				_spr(world, ek, fr, e.pos, {"flip": e.face < 0, "col": col, "sc": esc})
			})
			if e.slam_t > 0:
				var pr: float = 1.0 - e.slam_t / 0.85
				world.draw_circle(e.pos, 84.0, Color(1.0, 0.15, 0.1, 0.14 + pr * 0.2))
				world.draw_arc(e.pos, 84.0 * pr, 0, TAU, 40, Color(1.0, 0.35, 0.2, 0.8), 2.5)
			if e.charge_t > 0.35:
				world.draw_line(e.pos, e.pos + e.charge_dir * 190.0, Color(1.0, 0.25, 0.2, 0.65), 14.0)

	# Karabaş & Clothed Hero
	items_y.append({"y": dog.pos.y, "fn": func():
		_shadow(world, dog.pos, 8.0)
		var dfr := int(dog.t * 11) if dog.moving else 0
		_spr(world, "dog_karabas", dfr, dog.pos, {"flip": dog.flip, "sc": 0.68})
		if dog.carry:
			_spr(world, "bone", 0, dog.pos + Vector2(-10 if dog.flip else 10, -10), {"sc": 0.55})
	})

	items_y.append({"y": p.pos.y, "fn": func():
		_shadow(world, p.pos, 10.0)
		var tier := _hero_skin_tier()
		var pk := "hero%d_%s" % [tier, p.anim]
		if not S.has(pk): pk = "hero0_idle"
		var pfr := int(p.at * (16 if p.roll_t > 0 else (18 if p.act_t > 0 else (11 if p.anim in ["walk", "run"] else 8))))
		var col := Color(1, 1, 1, 0.55 if (p.inv_t > 0 and p.roll_t <= 0 and int(p.inv_t * 20) % 2 == 0) else 1.0)
		_spr(world, pk, pfr, p.pos, {"flip": p.flip, "col": col, "sc": 1.45})
	})

	items_y.sort_custom(func(a, b): return a.y < b.y)
	for item in items_y:
		item.fn.call()

	if bone != null:
		_spr(world, "bone", 0, bone.pos, {"sc": 0.65})
	for f in fxs:
		_spr(world, f.n, int(f.t * f.fps), f.pos, {"sc": f.sc, "col": f.col})
	for pr in projectiles:
		var pc: Color = pr.get("col", Color(0.75, 0.9, 1.0))
		world.draw_circle(pr.pos, 6.5, Color(pc.r, pc.g, pc.b, 0.28))
		world.draw_circle(pr.pos, 3.2, Color(pc.r, pc.g, pc.b, 0.95))

func _draw_drop(gd: Dictionary) -> void:
	var bob := sin(t * 4.0 + gd.pos.x) * 1.5 if gd.get("z", 0.0) <= 0.0 else 0.0
	var base: Vector2 = gd.pos
	var top := base - Vector2(0, 8 + gd.get("z", 0.0) + bob)
	_shadow(world, base, 5.0, 0.3)
	if gd.get("kind", "") == "gear":
		var rc: Color = GameData.RARITY[gd.gear.rarity].col
		var pulse := 0.55 + sin(t * 5.0) * 0.2
		world.draw_circle(top, 9.5, Color(rc.r, rc.g, rc.b, 0.25 * pulse + 0.1))
		if gd.gear.rarity >= 2:
			world.draw_rect(Rect2(top.x - 1.5, top.y - 46, 3, 46), Color(rc.r, rc.g, rc.b, 0.38 * pulse))
	_icon_at(world, gd.icon, Rect2(top - Vector2(6, 6), Vector2(12, 12)))

func _icon_at(c: CanvasItem, icon_idx: int, dst: Rect2, col := Color.WHITE) -> void:
	if icon_idx >= 1000:
		if S.has("atlas"):
			var ai := icon_idx - 1000
			c.draw_texture_rect_region(S["atlas"].t, dst, Rect2((ai % 32) * 16, int(ai / 32) * 16, 16, 16), col)
	elif S.has("items"):
		c.draw_texture_rect_region(S["items"].t, dst, Rect2(icon_idx * 16, 0, 16, 16), col)

func _draw_overlay() -> void:
	if in_house:
		return
	var world_vs := get_viewport_rect().size / cam.zoom
	var view := Rect2(cam.get_screen_center_position() - world_vs / 2.0, world_vs).grow(40)
	for wp in weather_particles:
		if is_raining:
			overlay.draw_line(wp.pos, wp.pos + Vector2(-3, 10), Color(0.6, 0.8, 1.0, 0.48), 1.0)
		elif season == 0:
			overlay.draw_circle(wp.pos, 1.6, Color(1.0, 0.78, 0.88, 0.72))
		elif season == 2:
			overlay.draw_rect(Rect2(wp.pos, Vector2(3, 2)), Color(0.95, 0.52, 0.2, 0.75))
		elif season == 3:
			overlay.draw_circle(wp.pos, 1.5, Color(0.95, 0.98, 1.0, 0.85))
	# Note: ALL world text labels & HP bars are drawn in _draw_hud() via _w2s() at crisp 1280x720!

func _get_context_prompt() -> String:
	if in_house:
		if p.pos.distance_to(Vector2(240, 298)) < 36.0: return "[E] Çiftliğe Çık"
		if p.pos.distance_to(INT_BED_POS) < 52.0: return "[E] Uyu ve Yeni Güne Geç"
		if p.pos.distance_to(INT_CHEST_POS) < 42.0: return "[E] Ev Sandığı"
		if p.pos.distance_to(INT_BENCH_POS) < 46.0: return "[E / B] Ev Düzenleme Masası"
		if house_upgrades.get("kitchen", false) and p.pos.distance_to(INT_KITCHEN_POS) < 58.0: return "[E] Ev Mutfağı (Yemek)"
		if house_upgrades.get("alchemy", false) and p.pos.distance_to(INT_ALCHEMY_POS) < 46.0: return "[E] Simya Masası"
		if house_upgrades.get("forge", false) and p.pos.distance_to(INT_FORGE_POS) < 52.0: return "[E] Kişisel Örs & Silahlık"
		if dog.pos.distance_to(p.pos) < 48.0: return "[F] Karabaş'ı Sev"
		return ""
	var c := _facing_farm_cell()
	if farm_grid.has(c) and farm_grid[c].crop != "" and farm_grid[c].stage >= 5:
		return "[E] Hasat Et (%s)" % GameData.ITEMS[farm_grid[c].crop].name
	for gd in ground_drops:
		if not gd.get("auto", false) and gd.pos.distance_to(p.pos) < 34.0 and GameData.ITEMS.has(gd.get("id", "")):
			return "[E] Topla (%s)" % GameData.ITEMS[gd.id].name
	for fn in forage_nodes:
		if fn.pos.distance_to(p.pos) < 34.0:
			return "[E] Mantar Topla"
	for a in animals:
		if a.pos.distance_to(p.pos) < 32.0 and not a.petted:
			return "[E] %s'ı Sev" % a.name
	if p.pos.distance_to(HOUSE_DOOR) < 40.0: return "[E] Çiftlik Evine Gir"
	if p.pos.distance_to(WELL_POS) < 38.0: return "[E] Suyu Doldur"
	if p.pos.distance_to(CRATE_POS) < 38.0: return "[E] Ürünleri Sat (Sevkiyat)"
	if p.pos.distance_to(FORGE_POS) < 48.0: return "[E] Demirci Örsü & Dükkan"
	if p.pos.distance_to(BOARD_POS) < 44.0: return "[E] Günlük Köy İlanları"
	for n in npcs:
		if n.pos.distance_to(p.pos) < 44.0:
			return "[E] %s ile Konuş" % n.name
	for e in enemies:
		if not e.dead and e.pos.distance_to(p.pos) < 140.0:
			return ""
	if dog.pos.distance_to(p.pos) < 48.0:
		return "[F] Karabaş'ı Sev"
	return ""

# ==============================================================================
#  CRISP 1280x720 HD UI, HUD, MINIMAP & MODALS
# ==============================================================================
func _w2s(wp: Vector2) -> Vector2:
	return (wp - cam.get_screen_center_position()) * cam.zoom + get_viewport_rect().size * 0.5

func _txt(c: CanvasItem, pos: Vector2, s: String, sz: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER, outline := 3, bold := false) -> void:
	var f: Font = font_bold if bold else font_ui
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if outline > 0:
		c.draw_string_outline(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, outline, Color(0.03, 0.02, 0.05, col.a * 0.96))
	c.draw_string(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _wrap_text(s: String, sz: int, max_w: float) -> Array[String]:
	var lines: Array[String] = []
	var cur := ""
	for w in s.split(" "):
		var cand := w if cur == "" else cur + " " + w
		if font_ui.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > max_w:
			if cur != "": lines.append(cur)
			cur = w
		else:
			cur = cand
	if cur != "":
		lines.append(cur)
	return lines

func _draw_9slice(key: String, r: Rect2, m := 12.0, col := Color.WHITE) -> void:
	if not S.has(key):
		hud.draw_rect(r, Color("f0deb8") * col)
		return
	var tex: Texture2D = S[key].t
	var tw := float(S[key].fw)
	var th := float(S[key].fh)
	var rx := floorf(r.position.x)
	var ry := floorf(r.position.y)
	var rw := floorf(r.size.x)
	var rh := floorf(r.size.y)
	var mg := minf(m, minf(rw * 0.45, rh * 0.45))
	var cw := tw - 2.0 * m
	var ch := th - 2.0 * m
	var xs := [rx, rx + mg, rx + rw - mg, rx + rw]
	var ys := [ry, ry + mg, ry + rh - mg, ry + rh]
	var sxs := [0.0, m, m + cw, tw]
	var sys := [0.0, m, m + ch, th]
	for iy in 3:
		var dh: float = ys[iy + 1] - ys[iy]
		var sh: float = sys[iy + 1] - sys[iy]
		if dh <= 0.5 or sh <= 0.5:
			continue
		for ix in 3:
			var dw: float = xs[ix + 1] - xs[ix]
			var sw: float = sxs[ix + 1] - sxs[ix]
			if dw <= 0.5 or sw <= 0.5:
				continue
			hud.draw_texture_rect_region(tex, Rect2(xs[ix], ys[iy], dw, dh), Rect2(sxs[ix], sys[iy], sw, sh), col)

func _panel_parchment(r: Rect2, col := Color.WHITE) -> void:
	_draw_9slice("ui_parchment", r, 12.0, col)

func _panel_card(r: Rect2, selected := false, col := Color.WHITE) -> void:
	_draw_9slice("ui_card_sel" if selected else "ui_card", r, 10.0, col)

func _panel_wood(r: Rect2, col := Color.WHITE) -> void:
	_draw_9slice("ui_wood_hud", r, 10.0, col)

func _panel_slot(r: Rect2, selected := false) -> void:
	_draw_9slice("ui_slot_sel" if selected else "ui_slot", r, 8.0)
	if selected:
		if S.has("ui_sel_tl"): hud.draw_texture_rect(S["ui_sel_tl"].t, Rect2(r.position + Vector2(-2, -2), Vector2(10, 11)), false)
		if S.has("ui_sel_tr"): hud.draw_texture_rect(S["ui_sel_tr"].t, Rect2(Vector2(r.end.x - 8, r.position.y - 2), Vector2(10, 11)), false)
		if S.has("ui_sel_bl"): hud.draw_texture_rect(S["ui_sel_bl"].t, Rect2(Vector2(r.position.x - 2, r.end.y - 9), Vector2(10, 11)), false)
		if S.has("ui_sel_br"): hud.draw_texture_rect(S["ui_sel_br"].t, Rect2(r.end - Vector2(8, 9), Vector2(10, 11)), false)

func _panel(r: Rect2, border := Color("d4a85c"), fill := Color(0.09, 0.07, 0.12, 0.94)) -> void:
	if fill.r > 0.3:
		_panel_parchment(r)
	else:
		_panel_wood(r)
	if border != Color("d4a85c") and border != Color("b8965e"):
		hud.draw_rect(r.grow(-2), Color(border.r, border.g, border.b, 0.55), false, 1.5)

func _txt_ink(pos: Vector2, s: String, sz: int, col := COL_INK, align := HORIZONTAL_ALIGNMENT_LEFT, bold := false) -> void:
	var f: Font = font_bold if bold else font_ui
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	hud.draw_string(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)

func _draw_ui_tex(key: String, dst: Rect2, col := Color.WHITE) -> void:
	if S.has(key):
		hud.draw_texture_rect(S[key].t, dst, false, col)

func _draw_heart_row(pos: Vector2, filled: int, total := 10, sz := 16.0, gap := 19.0) -> void:
	for hi in total:
		var hr := Rect2(pos.x + hi * gap, pos.y, sz, sz * 0.9)
		if hi < filled:
			_draw_ui_tex("ui_heart", hr, Color(1.0, 0.92, 0.95))
		else:
			_draw_ui_tex("ui_heart", hr, Color(0.55, 0.42, 0.34, 0.35))

func _item_icon(icon_idx: int, dst: Rect2, col := Color.WHITE) -> void:
	_icon_at(hud, icon_idx, dst, col)

func _bar(pos: Vector2, w: float, h: float, pct: float, col: Color) -> void:
	hud.draw_rect(Rect2(pos - Vector2(1, 1), Vector2(w + 2, h + 2)), Color("261309"))
	hud.draw_rect(Rect2(pos, Vector2(w, h)), Color("3f2314"))
	var fw: float = w * clampf(pct, 0.0, 1.0)
	if fw > 0.5:
		hud.draw_rect(Rect2(pos, Vector2(fw, h)), col)
		hud.draw_rect(Rect2(pos, Vector2(fw, maxf(1.0, h * 0.32))), Color(1, 1, 1, 0.28))

func _draw_world_hd_labels(vs: Vector2) -> void:
	if state == "title":
		return
	if in_house:
		var int_labels := [
			[INT_BED_POS - Vector2(0, 44), "Yatak"],
			[INT_CHEST_POS - Vector2(0, 28), "Sandık"],
			[INT_BENCH_POS - Vector2(0, 36), "Ev Masası [B]"],
			[Vector2(240, 290), "Çıkış Kapısı"],
		]
		if house_upgrades.get("kitchen", false):
			int_labels.append([INT_KITCHEN_POS - Vector2(0, 48), "Ev Mutfağı"])
		if house_upgrades.get("alchemy", false):
			int_labels.append([INT_ALCHEMY_POS - Vector2(0, 48), "Simya Masası"])
		if house_upgrades.get("forge", false):
			int_labels.append([INT_FORGE_POS - Vector2(0, 44), "Kişisel Örs"])
		for lbl_it in int_labels:
			_txt(hud, _w2s(lbl_it[0]), lbl_it[1], 13, Color(1.0, 0.94, 0.72), HORIZONTAL_ALIGNMENT_CENTER, 3, true)
		for ft in float_texts:
			var fsp := _w2s(ft.pos + Vector2(0, -(ft.max - ft.life) * 16.0))
			var fc: Color = ft.c
			fc.a = minf(1.0, ft.life / ft.max * 2.0)
			_txt(hud, fsp, ft.s, 15, fc, HORIZONTAL_ALIGNMENT_CENTER, 3, true)
		if state == "play":
			var ipr := _get_context_prompt()
			if ipr != "":
				var psp := _w2s(p.pos + Vector2(0, -44))
				var ptw := font_bold.get_string_size(ipr, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 28.0
				_panel(Rect2(psp.x - ptw * 0.5, psp.y - 18, ptw, 28))
				_txt(hud, psp + Vector2(0, 1), ipr, 14, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)
		return
	var screen_rect := Rect2(Vector2(-80, -60), vs + Vector2(160, 120))

	# Villager Nameplates + Friendship Hearts
	for n in npcs:
		var sp := _w2s(n.pos + Vector2(0, -34))
		if screen_rect.has_point(sp):
			var h := _hearts(n.id)
			var lbl: String = "%s  %s" % [n.name, ("♥%d" % h) if h > 0 else ""]
			_txt(hud, sp, lbl, 14, Color(1.0, 0.94, 0.72), HORIZONTAL_ALIGNMENT_CENTER, 3, true)

	# Nearby Station Labels (only when close enough to reduce clutter)
	for st in [
		[Vector2(395, 200), "Çiftlik Evi"],
		[FORGE_POS - Vector2(0, 48), "Demirci Örsü"],
		[CRATE_POS - Vector2(0, 28), "Sevkiyat Sandığı"],
		[BOARD_POS - Vector2(0, 32), "Köy İlan Panosu"],
	]:
		if st[0].distance_to(p.pos) < 280.0:
			var sp := _w2s(st[0])
			_txt(hud, sp, st[1], 13, Color(0.84, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 3, true)

	# Zone Signposts (placed cleanly at zone entrances so they never overlap boss bars or HUD)
	for sg in [
		[Vector2(SHADOW_X - 24, 540), "GÖLGE ORMANI  →  (Sv.4+)", Color(0.85, 0.62, 1.0)],
		[Vector2(1600, 330), "↑ KUZEY ORMANI  (Sv.1-4)", Color(0.65, 1.0, 0.65)],
		[Vector2(1805, 175), "GROG'UN HARABESİ →", Color(1.0, 0.65, 0.35)],
		[Vector2(2510, 310), "KANLI MAHZEN →", Color(1.0, 0.4, 0.4)],
		[Vector2(3055, 555), "CEHENNEM SUNAKI →", Color(1.0, 0.35, 0.25)],
	]:
		if sg[0].distance_to(p.pos) < 350.0:
			_txt(hud, _w2s(sg[0]), sg[1], 14, sg[2], HORIZONTAL_ALIGNMENT_CENTER, 3, true)

	# Enemy HP Bars & Level Tags (Crisp HD!)
	for e in enemies:
		if not e.dead and not e.boss:
			var esc: float = GameData.ENEMY_DEFS[e.kind].sc
			var bar_h: float = float(GameData.ENEMY_DEFS[e.kind].get("bar", 34.0))
			var sp := _w2s(e.pos + Vector2(0, -bar_h * esc))
			if screen_rect.has_point(sp):
				var bw := 58.0
				_bar(Vector2(sp.x - bw * 0.5, sp.y), bw, 6, e.hp / e.max, Color(0.92, 0.24, 0.24))
				if e.aggro or e.pos.distance_to(p.pos) < 190.0:
					var diff: int = e.lvl - p.level
					var lc := Color(0.7, 1.0, 0.7) if diff <= -3 else (Color(1.0, 0.95, 0.7) if diff <= 1 else (Color(1.0, 0.6, 0.3) if diff <= 3 else Color(1.0, 0.35, 0.35)))
					_txt(hud, sp - Vector2(0, 6), "Sv.%d %s" % [e.lvl, e.name], 13, lc, HORIZONTAL_ALIGNMENT_CENTER, 3)

	# Floating Combat & Reward Numbers
	for ft in float_texts:
		var sp := _w2s(ft.pos + Vector2(0, -(ft.max - ft.life) * 16.0))
		var c: Color = ft.c
		c.a = minf(1.0, ft.life / ft.max * 2.0)
		_txt(hud, sp, ft.s, 15, c, HORIZONTAL_ALIGNMENT_CENTER, 3, true)

	# Context Interaction Prompt Pill above Hero
	if state == "play":
		var prompt := _get_context_prompt()
		if prompt != "":
			var sp := _w2s(p.pos + Vector2(0, -44))
			var tw := font_bold.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 28.0
			_panel_wood(Rect2(sp.x - tw * 0.5, sp.y - 18, tw, 28))
			_txt(hud, sp + Vector2(0, 1), prompt, 14, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

func _draw_hud() -> void:
	clickable_rects.clear()
	var vs := get_viewport_rect().size # 1280x720

	if state == "title":
		_draw_title(vs)
		return

	_draw_world_hd_labels(vs)

	# 1. Sleek Top-Left Wooden Hero Crest (276 x 94)
	_panel_wood(Rect2(12, 12, 276, 94))
	_draw_ui_tex("ui_disc", Rect2(20, 18, 48, 48))
	_spr(hud, "hero%d_idle" % _hero_skin_tier(), 0, Vector2(44, 58), {"sc": 1.35})
	hud.draw_rect(Rect2(20, 70, 48, 22), Color("28150c"))
	hud.draw_rect(Rect2(20, 70, 48, 22), Color("b8894f"), false, 1.5)
	_txt(hud, Vector2(44, 86), "Sv.%d" % p.level, 12, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

	_txt(hud, Vector2(76, 29), "Can", 12, Color("ffb8b0"), HORIZONTAL_ALIGNMENT_LEFT, 2, true)
	_bar(Vector2(114, 19), 160, 12, p.hp / p.max_hp, Color("d93b32"))
	_txt(hud, Vector2(194, 29), "%d/%d" % [int(ceil(p.hp)), int(p.max_hp)], 11, COL_CREAM, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

	_txt(hud, Vector2(76, 48), "Enerji", 12, Color("b6f0a5"), HORIZONTAL_ALIGNMENT_LEFT, 2, true)
	_bar(Vector2(114, 38), 160, 12, p.stam / p.max_stam, Color("48a842"))
	_txt(hud, Vector2(194, 48), "%d/%d" % [int(p.stam), int(p.max_stam)], 11, COL_CREAM, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

	_txt(hud, Vector2(76, 65), "EXP", 11, Color("a2d8ff"), HORIZONTAL_ALIGNMENT_LEFT, 2)
	_bar(Vector2(114, 56), 160, 9, float(p.xp) / _xp_need(p.level), Color("4c94e8"))
	_txt(hud, Vector2(194, 65), "%d/%d" % [p.xp, _xp_need(p.level)], 10, COL_CREAM, HORIZONTAL_ALIGNMENT_CENTER, 2)

	_item_icon(45, Rect2(74, 73, 18, 18))
	_txt(hud, Vector2(95, 88), "%d G" % p.gold, 14, COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT, 2, true)
	var stat_right := "ATK %d • DEF %d" % [int(_stat_atk()), int(_stat_def())]
	if well_rested:
		stat_right += " ★"
	_txt(hud, Vector2(276, 88), stat_right, 11, COL_CREAM, HORIZONTAL_ALIGNMENT_RIGHT, 2)

	# 2. Compact Top-Right Stardew Calendar & Watch + Active Quest Ribbon
	var cal_r := Rect2(vs.x - 278, 12, 266, 62)
	_panel_parchment(cal_r)
	_draw_ui_tex("ui_watch", Rect2(cal_r.position.x + 12, cal_r.position.y + 16, 22, 26))
	var w_txt := "Yağmurlu" if is_raining else "Güneşli"
	_txt_ink(cal_r.position + Vector2(42, 26), "%s %d. Gün  •  %02d:%02d" % [SEASON_NAMES[season], day, hour, minute], 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	var short_z := "ÇİFTLİK EVİ" if in_house else cur_zone.split(" (")[0].split(" —")[0]
	_txt_ink(cal_r.position + Vector2(42, 46), "%s  •  %s" % [w_txt, short_z], 12, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)

	var qr := Rect2(vs.x - 278, 78, 266, 44)
	_panel_wood(qr)
	_draw_ui_tex("ui_alert", Rect2(qr.position.x + 14, qr.position.y + 11, 9, 20))
	if story_step < GameData.STORY_CHAPTERS.size():
		var ch: Dictionary = GameData.STORY_CHAPTERS[story_step]
		_txt(hud, qr.position + Vector2(32, 20), "%s (%d/%d)" % [ch.title, story_prog, ch.need], 12, COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT, 2, true)
		var ql := _wrap_text(ch.desc, 11, 224.0)
		_txt(hud, qr.position + Vector2(32, 35), ql[0] if not ql.is_empty() else "", 11, COL_CREAM, HORIZONTAL_ALIGNMENT_LEFT, 2)
	else:
		_txt(hud, qr.position + Vector2(32, 27), "Tüm Hikaye Görevleri Tamam!", 13, COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT, 2, true)

	# 3. Top-Center Wooden Toast Ribbon
	if toast_t > 0 and state == "play":
		var tlines := _wrap_text(toast_msg, 13, 450.0)
		var tw: float = clampf(font_bold.get_string_size(tlines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 40.0, 220.0, 490.0)
		var th: float = 36.0 if tlines.size() == 1 else 56.0
		var tr := Rect2(vs.x * 0.5 - tw * 0.5, 14, tw, th)
		_panel_wood(tr)
		for ti in mini(2, tlines.size()):
			_txt(hud, Vector2(vs.x * 0.5, 36 + ti * 20), tlines[ti], 13, toast_col, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

	# 4. Bottom Carved Wooden Hotbar + Quick Menu Buttons
	var slot_sz := 46.0
	var gap := 5.0
	var menu_btns := [
		["[I]", "Çanta", Color("ffd66b"), "open_inv"],
		["[C]", "Ekipman", Color("ffd66b"), "open_char"],
		["[Q]", "Görev", Color("ffd66b"), "open_quest"],
		["[N]", "Komşu", Color("ff9eb5"), "open_social"],
	]
	if in_house:
		menu_btns.append(["[B]", "Evim", Color("95f08b"), "open_house_menu"])
	var total_w := (8 + menu_btns.size()) * (slot_sz + gap) + 8.0
	var hb_x := vs.x * 0.5 - total_w * 0.5
	var hb_y := vs.y - 66.0
	_panel_wood(Rect2(hb_x - 10, hb_y - 8, total_w + 16, slot_sz + 16))

	var w = equipped.get("weapon", null)
	var slot_icons := [
		[w.icon if w != null else 9, _gear_title(w) if w != null else "Silah", 1],
		[0 if p.hoe_tier == 1 else (1 if p.hoe_tier == 2 else 2), "Çapa", 1],
		[4 if p.water_tier == 1 else 5, "Sulama (%d/%d)" % [p.water_tank, p.water_max], 1],
		[7, "Balta/Kazma", 1],
		[6, "Olta", 1],
		[11, "Tohum", 0],
		[41, "İksir/Yemek", 0],
		[10, "Kemik", 1],
	]
	var active_seed := _active_seed_id()
	var active_cons := _active_consumable_id()
	if active_seed != "":
		slot_icons[5] = [GameData.ITEMS[active_seed].icon, GameData.ITEMS[active_seed].name, bag.get(active_seed, 0)]
	if active_cons != "":
		slot_icons[6] = [GameData.ITEMS[active_cons].icon, GameData.ITEMS[active_cons].name, bag.get(active_cons, 0)]

	for i in 8:
		var sr := Rect2(hb_x + i * (slot_sz + gap), hb_y, slot_sz, slot_sz)
		var sel: bool = (i == p.slot)
		_panel_slot(sr, sel)
		if i == 0 and w != null:
			var wc: Color = GameData.RARITY[w.rarity].col
			hud.draw_rect(sr.grow(-4), Color(wc.r, wc.g, wc.b, 0.22))
		_item_icon(slot_icons[i][0], Rect2(sr.position + Vector2(7, 7), Vector2(32, 32)))
		_txt_ink(sr.position + Vector2(6, 16), str(i + 1), 11, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		if i in [5, 6] and slot_icons[i][2] > 0:
			_txt(hud, sr.end - Vector2(5, 5), str(slot_icons[i][2]), 12, Color("a6ff96"), HORIZONTAL_ALIGNMENT_RIGHT, 2, true)
		clickable_rects.append({"rect": sr, "action": "hotbar", "val": i})

	if state == "play":
		var active_lbl: String = slot_icons[p.slot][1]
		var lw := font_bold.get_string_size(active_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 24.0
		_panel_wood(Rect2(vs.x * 0.5 - lw * 0.5, hb_y - 34, lw, 22))
		_txt(hud, Vector2(vs.x * 0.5, hb_y - 18), active_lbl, 13, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

	var bx0 := hb_x + 8 * (slot_sz + gap) + 8.0
	for mi in menu_btns.size():
		var mb: Array = menu_btns[mi]
		var br := Rect2(bx0 + mi * (slot_sz + gap), hb_y, slot_sz, slot_sz)
		_panel_card(br, mb[3] == "open_house_menu")
		_txt_ink(br.position + Vector2(slot_sz * 0.5, 22), mb[0], 13, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
		_txt_ink(br.position + Vector2(slot_sz * 0.5, 37), mb[1], 10, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
		clickable_rects.append({"rect": br, "action": mb[3], "val": 0})

	# 5. Live Minimap (Outdoors Play Only)
	if state == "play" and not in_house:
		_draw_minimap(vs)

	# 6. Active Boss HP Bar (above hotbar)
	if not in_house:
		for e in enemies:
			if e.boss and e.aggro and not e.dead:
				var bw := 480.0
				var by := hb_y - 82.0
				_panel_wood(Rect2(vs.x * 0.5 - bw * 0.5 - 14, by - 26, bw + 28, 48))
				_txt(hud, Vector2(vs.x * 0.5, by - 6), "%s  (Sv.%d)  —  %d / %d" % [e.name, e.lvl, int(ceil(e.hp)), int(e.max)], 14, Color("ffb59e"), HORIZONTAL_ALIGNMENT_CENTER, 2, true)
				_bar(Vector2(vs.x * 0.5 - bw * 0.5, by + 3), bw, 11, e.hp / e.max, Color("d92b2b"))
				break

	# 7. Active Modal Window (Mutually Exclusive)
	match state:
		"inv": _draw_inventory_modal(vs)
		"char": _draw_char_modal(vs)
		"quest": _draw_quest_modal(vs)
		"social": _draw_social_modal(vs)
		"dialog": _draw_dialog_modal(vs)
		"gift": _draw_gift_modal(vs)
		"house_menu": _draw_house_menu_modal(vs)
		"chest": _draw_chest_modal(vs)
		"shop": _draw_station_modal(vs, "AYLA'NIN TOHUM & ÇİFTLİK DÜKKANI", [
			["Yaban Havucu Tohumu x2", "%d Altın" % _disc("ayla", 30), "2 günde hızlı hasat"],
			["Havuç Tohumu x2", "%d Altın" % _disc("ayla", 40), "2 günde yetişir"],
			["Patates Tohumu x2", "%d Altın" % _disc("ayla", 50), "3 günde yetişir"],
			["Ayçiçeği Tohumu x2", "%d Altın" % _disc("ayla", 70), "Değerli yaz çiçeği (Komşular sever!)"],
			["Balkabağı Tohumu x2", "%d Altın" % _disc("ayla", 100), "4 günde dev hasat"],
			["Yeni Çiftlik Tavuğu", "%d Altın" % _disc("ayla", 200), "Her sabah yumurta verir!"],
		])
		"tavern": _draw_station_modal(vs, "MERYEM'İN HANI — İKSİR & YEMEK", [
			["Şifa İksiri x1", "%d Altın" % _disc("meryem", 35), "80 Can yeniler. Savaşta [H] ile iç."],
			["Şifa İksiri x5", "%d Altın" % _disc("meryem", 160), "Boss öncesi avantajlı paket!"],
			["Demir Deri İksiri", "%d Altın" % _disc("meryem", 95), "60 sn +12 Savunma verir."],
			["Savaşçı Güveci", "%d Altın" % _disc("meryem", 180), "85 Can + 60 sn %25 Saldırı gücü!"],
			["Ruh Şurubu", "%d Altın" % _disc("meryem", 140), "Can & Enerji fuller + 30 sn hız"],
		])
		"alchemy_shop": _draw_station_modal(vs, "BİLGE OZAN'IN SİMYA TEZGAHI", [
			["Bereket İksiri", "110 Altın", "Çiftlikteki tüm ekinleri anında olgunlaştırır"],
			["Yağmur Totemi", "130 Altın", "Yağmur yağdırır ve tüm tarlayı sular"],
			["Demir Deri İksiri x2", "160 Altın", "Boss savaşında +12 DEF zırh iksiri"],
			["Ruh Şurubu", "120 Altın", "Can & Enerji + Hız artışı"],
		])
		"fisher_trade": _draw_station_modal(vs, "KAPTAN BRAM'IN İSKELE TAKASI", [
			["Izgara Alabalık", "110 Altın", "55 Can, 60 Enerji"],
			["Şifa İksiri x2", "65 Altın", "Acil savaş şifası"],
			["Bakır Cevheri x2", "90 Altın", "Silah/alet geliştirmek için maden"],
		])
		"loot_buyer": _draw_station_modal(vs, "LİNA'NIN NADİR EŞYA PAZARI", [
			["Tüm Canavar Ganimetlerini Sat", "+%25 Primli", "Kemik, Gölge Özü ve Kafataslarını yüksek fiyata alır!"],
			["Gizemli Ekipman Sandığı", "320 Altın", "Garantili Nadir / Destansı / Efsanevi ekipman çıkar!"],
		])
		"alchemy": _draw_station_modal(vs, "EV SİMYA MASASI", [
			["Bereket İksiri", "2 Kırmızı Mantar + 1 Yaban Havucu", "Tüm ekinleri anında olgunlaştırır!"],
			["Yağmur Totemi", "1 Ay Işığı Mantarı + 1 Kırmızı Mantar", "Yağmur yağdırıp tarlayı sular!"],
			["Ruh Şurubu", "1 Ay Işığı Mantarı + 1 Ruh Kristali", "Can & Enerji fuller + Hız verir!"],
			["Demir Deri İksiri", "1 Bakır Cevheri + 1 Kırmızı Mantar", "60 sn +12 Savunma verir!"],
		])
		"cook": _draw_station_modal(vs, "EV MUTFAĞI & SICAK OCAK", [
			["Çiftlik Kahvaltısı", "1 Yumurta + 1 Süt", "65 Enerji | 130 Altına satılır"],
			["Izgara Alabalık", "1 Alabalık + 2 Odun", "60 Enerji | 145 Altına satılır"],
			["Sebze Güveci", "1 Havuç + 1 Patates", "75 Enerji | 170 Altına satılır"],
			["Altın Balkabağı Tartı", "1 Balkabağı + 1 Yumurta", "100 Enerji | Meryem buna bayılır!"],
			["Savaşçı Güveci", "1 Gökkuşağı Balığı + 1 Havuç", "85 Can + 60 sn %25 ATK artışı!"],
		])
		"smith": _draw_smith_modal(vs)
		"board": _draw_board_modal(vs)
		"fishing": _draw_fishing_modal(vs)
		"pause": _draw_pause(vs)
		"dead": _draw_dead(vs)

	if house_fade > 0.01:
		hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.05, 0.03, 0.02, house_fade))

func _draw_minimap(vs: Vector2) -> void:
	var mw := 176.0
	var mh := 92.0
	var mr := Rect2(vs.x - mw - 12, vs.y - mh - 12, mw, mh)
	_panel_wood(mr)
	var inner := Rect2(mr.position + Vector2(8, 8), mr.size - Vector2(16, 16))
	hud.draw_rect(inner, Color("244a26"))
	var sx := inner.size.x / WORLD_W
	var sy := inner.size.y / WORLD_H
	hud.draw_rect(Rect2(inner.position.x + SHADOW_X * sx, inner.position.y, (WORLD_W - SHADOW_X) * sx, 1088 * sy), Color("1e2230"))
	hud.draw_rect(Rect2(inner.position.x, inner.position.y + 1120 * sy, inner.size.x, (WORLD_H - 1120) * sy), Color("286299"))
	hud.draw_rect(Rect2(inner.position.x + 1456 * sx, inner.position.y + 448 * sy, 400 * sx, 336 * sy), Color("8a7652"))
	hud.draw_rect(Rect2(inner.position.x + FARM_OX * sx, inner.position.y + FARM_OY * sy, 240 * sx, 144 * sy), Color("7d522c"))
	for n in npcs:
		hud.draw_circle(inner.position + Vector2(n.pos.x * sx, n.pos.y * sy), 2.0, Color("7ef59a"))
	for ar in BOSS_ARENAS:
		var bp := inner.position + Vector2(ar.pos.x * sx, ar.pos.y * sy)
		var slain: bool = bosses_defeated.get(ar.id, false)
		hud.draw_circle(bp, 3.6, Color("66e872") if slain else Color("ff4438"))
	hud.draw_circle(inner.position + Vector2(p.pos.x * sx, p.pos.y * sy), 3.4, Color("ffe252"))
	_txt(hud, Vector2(mr.position.x + mw * 0.5, mr.position.y - 4), "Vadi Haritası", 11, COL_CREAM, HORIZONTAL_ALIGNMENT_CENTER, 2, true)

func _draw_title(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.06, 0.04, 0.02, 0.42))
	var plaque := Rect2(vs.x * 0.5 - 300, 82, 600, 128)
	_panel_wood(plaque)
	_panel_parchment(plaque.grow(-10))
	_txt_ink(Vector2(vs.x * 0.5, 144), "ÇAYIR VADİSİ", 48, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	_txt_ink(Vector2(vs.x * 0.5, 182), "Spirit Meadow  —  Çiftlik Yaşamı, Ev Dekorasyonu & Aksiyon RPG", 15, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

	var has_save := FileAccess.file_exists(SAVE_PATH)
	var opts := ["Devam Et", "Yeni Oyun", "Çıkış"]
	for i in 3:
		var br := Rect2(vs.x * 0.5 - 150, 248 + i * 64, 300, 50)
		var sel := i == title_sel
		var dis := i == 0 and not has_save
		_panel_card(br, sel)
		_txt_ink(br.position + Vector2(150, 32), opts[i], 19, COL_INK_MUTED if dis else COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
		clickable_rects.append({"rect": br, "action": "title", "val": i})

	_panel_wood(Rect2(vs.x * 0.5 - 450, vs.y - 84, 900, 62))
	_txt(hud, Vector2(vs.x * 0.5, vs.y - 56), "[WASD] Yürü   •   [Sol Tık] Saldır/Kullan   •   [Boşluk] Takla   •   [X] Dönen Kılıç   •   [E] Ev & Etkileşim", 14, COL_CREAM)
	_txt(hud, Vector2(vs.x * 0.5, vs.y - 34), "[I] Çanta   •   [C] Ekipman   •   [Q] Görev & Bosslar   •   [N] Komşular   •   [B] Ev Düzenle (Evde)", 14, COL_GOLD)

func _draw_pause(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 180, 185, 360, 275)
	_panel_parchment(r)
	_draw_modal_header(r, "DURAKLATILDI")
	var opts := ["Devam Et", "Kaydet", "Kaydet ve Ana Menü"]
	for i in 3:
		var br := Rect2(r.position.x + 36, r.position.y + 72 + i * 58, 288, 46)
		_panel_card(br, i == modal_sel)
		_txt_ink(br.position + Vector2(144, 30), opts[i], 16, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
		clickable_rects.append({"rect": br, "action": "pause", "val": i})

func _draw_dead(vs: Vector2) -> void:
	var a := clampf(dead_t / 1.2, 0.0, 0.85)
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.16, 0.0, 0.0, a))
	_txt(hud, Vector2(vs.x * 0.5, vs.y * 0.5 - 10), "BAYILDIN...", 42, Color(1.0, 0.4, 0.35, minf(1.0, dead_t)), HORIZONTAL_ALIGNMENT_CENTER, 4, true)
	_txt(hud, Vector2(vs.x * 0.5, vs.y * 0.5 + 30), "Köy komşuları seni çiftliğe taşıyor. (Altınının %10'u düştü)", 17, Color(1.0, 0.85, 0.8, minf(1.0, dead_t)))

func _draw_modal_header(r: Rect2, title: String, _title_col := COL_GOLD) -> void:
	var hdr := Rect2(r.position.x + 12, r.position.y + 10, r.size.x - 24, 40)
	hud.draw_rect(hdr, Color("3c2214"))
	hud.draw_rect(hdr, Color("7b4c2a"), false, 2.0)
	_txt(hud, hdr.position + Vector2(14, 27), title, 18, COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT, 2, true)
	var close_r := Rect2(hdr.end.x - 36, hdr.position.y + 4, 32, 32)
	_panel_card(close_r, false)
	_draw_ui_tex("ui_cancel", Rect2(close_r.position + Vector2(7, 7), Vector2(18, 18)))
	clickable_rects.append({"rect": close_r, "action": "close_modal", "val": 0})

func _draw_inventory_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 460, 74, 920, 560)
	_panel_parchment(r)
	_draw_modal_header(r, "SIRT ÇANTASI  (Altın: %d G)" % p.gold)

	var tab_r := Rect2(r.end.x - 216, r.position.y + 14, 158, 32)
	_panel_card(tab_r, false)
	_txt_ink(tab_r.position + Vector2(79, 21), "Ekipman [C] ▸", 13, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
	clickable_rects.append({"rect": tab_r, "action": "open_char", "val": 0})

	var keys := bag.keys()
	keys.sort_custom(func(x, y): return GameData.ITEMS[x].type + x < GameData.ITEMS[y].type + y)
	if keys.is_empty():
		_txt_ink(r.position + Vector2(460, 260), "Çantan şu an boş!", 18, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		var cols := 3
		for idx in mini(24, keys.size()):
			var id: String = keys[idx]
			var it: Dictionary = GameData.ITEMS[id]
			var cnt: int = bag[id]
			var cr := Rect2(r.position.x + 22 + (idx % cols) * 294, r.position.y + 62 + (idx / cols) * 56, 284, 50)
			_panel_card(cr, false)
			_item_icon(it.icon, Rect2(cr.position + Vector2(10, 9), Vector2(32, 32)))
			_txt_ink(cr.position + Vector2(50, 22), "%s x%d" % [it.name, cnt], 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
			var sub := "Satış: %dG" % it.sell if it.sell > 0 else "Malzeme"
			var scol := COL_INK_MUTED
			if it.type == "seed":
				sub = "Tıkla: Ekmek için seç"
				scol = COL_INK_GREEN
				clickable_rects.append({"rect": cr, "action": "select_seed", "val": _get_seed_list().find(id)})
			elif it.type in ["food", "potion", "crop", "forage", "animal"]:
				sub = "Tıkla: Tüket  |  %dG" % it.sell
				scol = COL_INK_GOLD
				clickable_rects.append({"rect": cr, "action": "eat_item", "val": id})
			_txt_ink(cr.position + Vector2(50, 40), sub, 12, scol, HORIZONTAL_ALIGNMENT_LEFT)

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Tıkla: Tohum seç veya Yemek/İksir tüket   |   Ürünleri Sevkiyat Sandığında sat   |   [I / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_gear_card(rr: Rect2, g, label: String) -> void:
	_panel_card(rr, false)
	if g == null:
		_txt_ink(rr.position + Vector2(14, 34), "%s: (boş)" % label, 14, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		return
	var rc: Color = GameData.RARITY[g.rarity].col
	var top_bar := Rect2(rr.position + Vector2(5, 5), Vector2(rr.size.x - 10, 23))
	hud.draw_rect(top_bar, Color("341f13"))
	_item_icon(g.icon, Rect2(rr.position + Vector2(10, 12), Vector2(32, 32)))
	_txt(hud, rr.position + Vector2(50, 22), _gear_title(g), 13, rc, HORIZONTAL_ALIGNMENT_LEFT, 1, true)
	_txt_ink(rr.position + Vector2(50, 44), "%s Sv.%d  •  %s" % [GameData.RARITY[g.rarity].name, g.lvl, _gear_lines(g)], 12, COL_INK, HORIZONTAL_ALIGNMENT_LEFT)

func _draw_char_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 500, 56, 1000, 600)
	_panel_parchment(r)
	_draw_modal_header(r, "KARAKTER & EKİPMAN")

	var lx := r.position.x + 24
	var prev_r := Rect2(lx, r.position.y + 62, 94, 94)
	_panel_wood(prev_r)
	hud.draw_rect(prev_r.grow(-7), Color("263624"))
	var tier := _hero_skin_tier()
	_spr(hud, "hero%d_idle" % tier, int(t * 7), prev_r.position + Vector2(47, 74), {"sc": 2.9})

	var sx := lx + 108
	var sy := r.position.y + 76
	_txt_ink(Vector2(sx, sy), "Seviye %d   (%d / %d EXP)" % [p.level, p.xp, _xp_need(p.level)], 15, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	_bar(Vector2(sx, sy + 8), 266, 9, float(p.xp) / _xp_need(p.level), Color("4c94e8"))
	var stats := [
		["Can / ATK", "%d/%d   •   ATK %d" % [int(p.hp), int(p.max_hp), int(_stat_atk())], COL_INK],
		["DEF / KRİT", "DEF %d   •   KRİT %d%%" % [int(_stat_def()), int(_stat_crit())], COL_INK_MUTED],
		["Av & Boss", "%d Canavar   •   %d Boss%s" % [p.kills, p.boss_kills, ("  •  Dinlenmiş ★" if well_rested else "")], COL_INK_GREEN if well_rested else COL_INK_MUTED],
	]
	for si in stats.size():
		_txt_ink(Vector2(sx, sy + 33 + si * 19), "%s: %s" % [stats[si][0], stats[si][1]], 13, stats[si][2], HORIZONTAL_ALIGNMENT_LEFT, si == 0)

	var eq_y := r.position.y + 174
	_txt_ink(Vector2(lx, eq_y), "KUŞANILAN EKİPMAN (Tıkla: Çıkar)", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	eq_y += 10
	for sl in [["weapon", "Silah"], ["armor", "Zırh"], ["shield", "Kalkan / Miğfer"], ["ring", "Yüzük / Tılsım"]]:
		var rr := Rect2(lx, eq_y, 394, 56)
		_draw_gear_card(rr, equipped.get(sl[0], null), sl[1])
		if equipped.get(sl[0], null) != null:
			clickable_rects.append({"rect": rr, "action": "unequip", "val": sl[0]})
		eq_y += 61

	var gx0 := r.position.x + 436
	_txt_ink(Vector2(gx0, r.position.y + 76), "EKİPMAN ÇANTASI (%d/24)" % gear_bag.size(), 15, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	if gear_bag.is_empty():
		_txt_ink(Vector2(gx0 + 270, r.position.y + 260), "Henüz ganimet yok. Canavar ve Boss avla!", 16, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	var mpos := get_viewport().get_mouse_position()
	var hover = null
	for i in mini(24, gear_bag.size()):
		var g: Dictionary = gear_bag[i]
		var cr := Rect2(gx0 + (i % 2) * 272, r.position.y + 88 + (i / 2) * 36, 264, 32)
		var rc: Color = GameData.RARITY[g.rarity].col
		var cur = equipped.get(g.slot, null)
		var better := _gear_power(g) > _gear_power(cur)
		hud.draw_rect(cr, Color("382114"))
		hud.draw_rect(cr, Color(rc.r, rc.g, rc.b, 0.85), false, 1.5)
		_item_icon(g.icon, Rect2(cr.position + Vector2(6, 4), Vector2(24, 24)))
		_txt(hud, cr.position + Vector2(36, 21), _gear_title(g), 12, rc, HORIZONTAL_ALIGNMENT_LEFT, 1, true)
		if better:
			_txt(hud, cr.end - Vector2(8, 10), "▲", 13, Color("66ff77"), HORIZONTAL_ALIGNMENT_RIGHT, 1, true)
		clickable_rects.append({"rect": cr, "action": "gear", "val": i})
		if cr.has_point(mpos):
			hover = g

	if hover != null:
		var tr := Rect2(gx0, r.end.y - 84, 538, 54)
		_panel_wood(tr)
		_txt(hud, tr.position + Vector2(12, 22), "%s [%s Sv.%d]   •   Satış: %dG" % [_gear_title(hover), GameData.RARITY[hover.rarity].name, hover.lvl, hover.value], 14, GameData.RARITY[hover.rarity].col, HORIZONTAL_ALIGNMENT_LEFT, 2, true)
		_txt(hud, tr.position + Vector2(12, 43), _gear_lines(hover), 13, COL_CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 14), "Sol Tık: Kuşan   |   Sağ Tık: Sat   |   ▲ = Mevcuttan güçlü   |   [C / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_quest_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 450, 62, 900, 585)
	_panel_parchment(r)
	_draw_modal_header(r, "GÖREV DEFTERİ & BOSS AVI REHBERİ")

	var lx := r.position.x + 24
	var story_box := Rect2(lx, r.position.y + 62, 852, 92)
	_panel_card(story_box, true)
	if story_step < GameData.STORY_CHAPTERS.size():
		var ch: Dictionary = GameData.STORY_CHAPTERS[story_step]
		_txt_ink(story_box.position + Vector2(16, 24), "ANA HİKAYE: %s" % ch.title, 16, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		var yln := 46.0
		for ln in _wrap_text(ch.desc, 14, 820.0):
			_txt_ink(story_box.position + Vector2(16, yln), ln, 14, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			yln += 19.0
		_txt_ink(story_box.position + Vector2(16, 78), "İlerleme: %d / %d   |   Ödül: %d Altın + %d %s" % [story_prog, ch.need, ch.reward_gold, ch.reward_cnt, GameData.ITEMS[ch.reward_item].name], 13, COL_INK_GREEN, HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		_txt_ink(story_box.position + Vector2(16, 48), "TEBRİKLER! Çayır Vadisi'nin Efsanevi Kahramanı Oldun!", 18, COL_INK_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)

	var daily_box := Rect2(lx, r.position.y + 166, 852, 62)
	_panel_card(daily_box, false)
	_txt_ink(daily_box.position + Vector2(16, 24), "GÜNLÜK KÖY İLANI: %s" % daily_quest.title, 15, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	var st_d := "TAMAMLANDI ✓" if daily_quest.done else "Gereken: %d %s  (Ödül: %d Altın) — Köy İlan Panosunda Teslim Et" % [daily_quest.need_cnt, GameData.ITEMS[daily_quest.need_id].name, daily_quest.reward]
	_txt_ink(daily_box.position + Vector2(16, 47), st_d, 13, COL_INK_GREEN if daily_quest.done else COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)

	var y := r.position.y + 254.0
	_txt_ink(Vector2(lx, y), "BOSS AVI TAKİPÇİSİ (3 BÖLGE BOSSU):", 16, COL_INK_RED, HORIZONTAL_ALIGNMENT_LEFT, true)
	y += 14.0
	for bi in GameData.BOSS_LIST.size():
		var b: Dictionary = GameData.BOSS_LIST[bi]
		var bd: Dictionary = GameData.ENEMY_DEFS[b.def]
		var slain: bool = bosses_defeated.get(b.id, false)
		var br := Rect2(lx + bi * 288, y, 276, 136)
		_panel_card(br, slain)
		hud.draw_rect(Rect2(br.position + Vector2(6, 6), Vector2(br.size.x - 12, 26)), Color("341f13"))
		_txt(hud, br.position + Vector2(14, 24), bd.name, 14, COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT, 1, true)
		_txt_ink(br.position + Vector2(14, 50), "Bölge: %s (Sv.%d)" % [b.zone, b.lvl], 13, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		var dlines := _wrap_text("Ganimet: " + b.drop, 12, 248.0)
		for di in dlines.size():
			_txt_ink(br.position + Vector2(14, 72 + di * 16), dlines[di], 12, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		if slain:
			_draw_ui_tex("ui_confirm", Rect2(br.position + Vector2(14, 108), Vector2(15, 14)))
			_txt_ink(br.position + Vector2(34, 120), "YENİLDİ (3 günde doğar)", 13, COL_INK_GREEN, HORIZONTAL_ALIGNMENT_LEFT, true)
		else:
			_txt_ink(br.position + Vector2(14, 120), "DURUM: BEKLİYOR ⚔", 13, COL_INK_RED, HORIZONTAL_ALIGNMENT_LEFT, true)

	_txt_ink(Vector2(lx, r.end.y - 44), "KONTROLLER: [WASD] Yürü | [Shift] Koş | [Sol Tık] Kullan/Saldır | [Boşluk] Takla | [X] Dönen Kılıç | [B] Evim (Evde)", 12, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "[Q / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_villager_portrait(pr: Rect2, vid: String) -> void:
	var v := _villager_def(vid)
	_panel_wood(pr)
	hud.draw_rect(pr.grow(-6), v.portrait_bg)
	var sh_key: String = v.sheet + "_idle"
	if S.has(sh_key):
		var ss: Dictionary = S[sh_key]
		var ratio := pr.size.y / 120.0
		var sc: float = (2.7 if ss.fh == 64 else 2.55) * ratio
		_spr(hud, sh_key, 0, pr.position + Vector2(pr.size.x * 0.5, pr.size.y * 0.90), {"sc": sc})

func _draw_dialog_modal(vs: Vector2) -> void:
	var vid: String = active_dialog.npc_id
	var v := _villager_def(vid)
	var h := _hearts(vid)
	var rel: Dictionary = npc_rel.get(vid, {"talked_today": false, "gifted_today": false})

	var r := Rect2(vs.x * 0.5 - 460, vs.y - 310, 920, 224)
	_panel_wood(r)
	_panel_parchment(r.grow(-8))
	_draw_villager_portrait(Rect2(r.position.x + 22, r.position.y + 22, 120, 120), vid)

	var tx := r.position.x + 158
	_txt_ink(Vector2(tx, r.position.y + 42), "%s  —  %s" % [v.name, v.role], 20, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	_draw_heart_row(Vector2(tx, r.position.y + 50), h, 10, 16.0, 19.0)
	_txt_ink(Vector2(tx + 198, r.position.y + 63), "(%d/10 Kalp)" % h, 13, COL_INK_RED, HORIZONTAL_ALIGNMENT_LEFT, true)

	var status_s := "Sohbet: %s   |   Hediye: %s" % ["✓" if rel.talked_today else "Hazır", "✓" if rel.gifted_today else "Hazır"]
	_txt_ink(Vector2(r.end.x - 26, r.position.y + 42), status_s, 13, COL_INK_GREEN, HORIZONTAL_ALIGNMENT_RIGHT, true)

	var lines := _wrap_text(active_dialog.text, 16, 724.0)
	for i in mini(3, lines.size()):
		_txt_ink(Vector2(tx, r.position.y + 96 + i * 24), lines[i], 16, COL_INK, HORIZONTAL_ALIGNMENT_LEFT)

	var btns := [
		["[1] Sohbet Et", "dlg_chat", "ui_chat"],
		["[2] Hediye Ver", "dlg_gift", "ui_heart"],
		["[3] " + v.service_label, "dlg_service", "ui_confirm"],
		["[E] Kapat", "dlg_close", "ui_cancel"],
	]
	for bi in btns.size():
		var b: Array = btns[bi]
		var br := Rect2(r.position.x + 22 + bi * 222, r.end.y - 58, 210, 38)
		_panel_wood(br)
		_draw_ui_tex(b[2], Rect2(br.position + Vector2(12, 11), Vector2(15, 15)))
		_txt(hud, br.position + Vector2(114, 24), b[0], 13, COL_CREAM, HORIZONTAL_ALIGNMENT_CENTER, 2, true)
		clickable_rects.append({"rect": br, "action": b[1], "val": 0})

func _draw_gift_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var v := _villager_def(active_npc_id)
	var rel: Dictionary = npc_rel.get(active_npc_id, {"gifts_given": []})
	var r := Rect2(vs.x * 0.5 - 420, 96, 840, 490)
	_panel_parchment(r)
	_draw_modal_header(r, "%s'YE HEDİYE SEÇ" % v.name.to_upper())

	var gift_keys := []
	for id in bag.keys():
		if GameData.ITEMS[id].type in ["crop", "animal", "fish", "forage", "food", "mat", "loot"] and not id.begins_with("boss_trophy_"):
			gift_keys.append(id)
	gift_keys.sort()

	if gift_keys.is_empty():
		_txt_ink(r.position + Vector2(420, 240), "Çantanda hediye edilebilecek eşya yok!", 17, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		for idx in mini(18, gift_keys.size()):
			var id: String = gift_keys[idx]
			var it: Dictionary = GameData.ITEMS[id]
			var cr := Rect2(r.position.x + 22 + (idx % 3) * 268, r.position.y + 62 + (idx / 3) * 62, 258, 54)
			_panel_card(cr, false)
			_item_icon(it.icon, Rect2(cr.position + Vector2(10, 11), Vector2(32, 32)))
			_txt_ink(cr.position + Vector2(48, 24), "%s x%d" % [it.name, bag[id]], 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
			var hint := "Tıkla: Hediye Ver"
			var hcol := COL_INK_MUTED
			if id in rel.gifts_given:
				if id in v.loved:
					hint = "★ EN SEVDİĞİ (+80)"
					hcol = COL_INK_RED
				elif id in v.liked:
					hint = "♥ SEVİYOR (+40)"
					hcol = COL_INK_GREEN
			_txt_ink(cr.position + Vector2(48, 43), hint, 12, hcol, HORIZONTAL_ALIGNMENT_LEFT, true)
			clickable_rects.append({"rect": cr, "action": "give_gift", "val": id})

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Doğru hediye vermek dostluk kalplerini hızla doldurur ve özel bonuslar açar!  |  [Esc] Geri", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_social_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 500, 56, 1000, 600)
	_panel_parchment(r)
	_draw_modal_header(r, "KÖY KOMŞULARI & DOSTLUK REHBERİ")

	for i in GameData.VILLAGERS.size():
		var v: Dictionary = GameData.VILLAGERS[i]
		var rel: Dictionary = npc_rel.get(v.id, {"pts": 0, "talked_today": false, "gifted_today": false, "gifts_given": []})
		var h := _hearts(v.id)
		var col_i := i % 2
		var row_i := int(i / 2)
		var cr := Rect2(r.position.x + 22 + col_i * 484, r.position.y + 60 + row_i * 168, 472, 156)
		_panel_card(cr, false)
		_draw_villager_portrait(Rect2(cr.position.x + 12, cr.position.y + 12, 86, 86), v.id)

		var tx := cr.position.x + 110
		_txt_ink(Vector2(tx, cr.position.y + 28), "%s  (%s)" % [v.name, v.role], 16, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_draw_heart_row(Vector2(tx, cr.position.y + 34), h, 10, 14.0, 16.0)
		var cur_loc := ""
		for n in npcs:
			if n.id == v.id: cur_loc = n.zone
		_txt_ink(Vector2(tx, cr.position.y + 66), "Konum: %s   |   Sohbet %s  Hediye %s" % [cur_loc, "✓" if rel.talked_today else "○", "✓" if rel.gifted_today else "○"], 12, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)

		var fav_names := []
		for gid in rel.gifts_given:
			if gid in v.loved:
				fav_names.append(GameData.ITEMS[gid].name)
		var fav_txt := "Favori: " + (", ".join(PackedStringArray(fav_names)) if not fav_names.is_empty() else "Henüz keşfedilmedi (hediye dene!)")
		_txt_ink(Vector2(tx, cr.position.y + 88), fav_txt, 12, COL_INK_RED, HORIZONTAL_ALIGNMENT_LEFT, true)
		_txt_ink(Vector2(cr.position.x + 14, cr.position.y + 120), "3♥: %s %s" % [v.perk3, "✓" if h >= 3 else ""], 12, COL_INK_GREEN if h >= 3 else COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT, h >= 3)
		_txt_ink(Vector2(cr.position.x + 14, cr.position.y + 140), "6♥: %s %s" % [v.perk6, "✓" if h >= 6 else ""], 12, COL_INK_GOLD if h >= 6 else COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT, h >= 6)

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Komşularla günlük sohbet et ve sevdikleri hediyeleri vererek güçlü kalıcı avantajlar aç!  |  [N / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_station_modal(vs: Vector2, title: String, rows: Array) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var h := 120.0 + rows.size() * 64.0
	var r := Rect2(vs.x * 0.5 - 390, vs.y * 0.5 - h * 0.5, 780, h)
	_panel_parchment(r)
	_draw_modal_header(r, title)
	_txt(hud, Vector2(r.end.x - 62, r.position.y + 36), "Altın: %d G" % p.gold, 15, COL_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 2, true)

	for i in rows.size():
		var row: Array = rows[i]
		var rr := Rect2(r.position.x + 22, r.position.y + 60 + i * 64, r.size.x - 44, 56)
		_panel_card(rr, false)
		_txt_ink(rr.position + Vector2(16, 24), "%d) %s" % [i + 1, row[0]], 16, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_txt_ink(rr.position + Vector2(16, 44), row[2], 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		_txt_ink(Vector2(rr.end.x - 16, rr.position.y + 34), row[1], 14, COL_INK_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, true)
		clickable_rects.append({"rect": rr, "action": "station_pick", "val": i})

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Tıkla veya [1-%d] Seç   |   [E / Esc] Kapat" % rows.size(), 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _smith_upgrade_row(slot: String) -> Array:
	var g = equipped.get(slot, null)
	var lbl := "Silah" if slot == "weapon" else "Zırh"
	if g == null:
		return ["%s Güçlendir" % lbl, "-", "Önce bir %s kuşan [C]" % lbl]
	var pl: int = g.get("plus", 0)
	if pl >= 5:
		return ["%s (MAKS)" % _gear_title(g), "-", "Ekipmanın en üst (+5) seviyede!"]
	var c := _upgrade_cost(pl)
	var bonus_txt := "+4 Saldırı gücü" if slot == "weapon" else "+2 Savunma ve +12 Can"
	return ["%s → +%d" % [_gear_title(g), pl + 1], "%dG + %d Kemik + %d %s" % [c[0], c[1], c[3], GameData.ITEMS[c[2]].name.split(" ")[0]], bonus_txt]

func _draw_smith_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 430, 66, 860, 570)
	_panel_parchment(r)
	_draw_modal_header(r, "DEMİRCİ ÖRSÜ — SİLAH, ZIRH & BOSS DÖVME")
	_txt(hud, Vector2(r.end.x - 62, r.position.y + 36), "Altın: %d G" % p.gold, 15, COL_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 2, true)

	var tabs := ["1. Silah & Zırh Dükkanı", "2. Güçlendir (+1..+5)", "3. Boss Ganimeti Dövme"]
	for ti in tabs.size():
		var tr := Rect2(r.position.x + 22 + ti * 274, r.position.y + 56, 266, 36)
		var sel := ti == smith_tab
		if sel:
			_panel_wood(tr)
			_txt(hud, tr.position + Vector2(133, 24), tabs[ti], 14, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)
		else:
			_panel_card(tr, false)
			_txt_ink(tr.position + Vector2(133, 24), tabs[ti], 14, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
		clickable_rects.append({"rect": tr, "action": "smith_tab", "val": ti})

	var rows := []
	if smith_tab == 0:
		rows = [
			["Bakır Kılıç (Kaliteli)", "%d Altın" % _disc("demir", 180), "Kuzey ormanı için keskin kılıç"],
			["Altın/Çelik Kılıç (Nadir)", "%d Altın" % _disc("demir", 420), "Yüksek saldırı güçlü usta kılıç"],
			["Deri Yelek (Kaliteli Zırh)", "%d Altın" % _disc("demir", 200), "Savunma + Can verir ve karakterini zırhlı gösterir!"],
			["Zincir Zırh (Nadir Zırh)", "%d Altın" % _disc("demir", 520), "Gümüş şövalye zırhı görünümü + güçlü DEF"],
			["Ahşap Kalkan (Kaliteli)", "%d Altın" % _disc("demir", 160), "Kalkan/Miğfer yuvasına ekstra DEF & Can"],
			["Şövalye Kalkanı (Nadir)", "%d Altın" % _disc("demir", 440), "Boss saldırılarına karşı sağlam koruma"],
		]
	elif smith_tab == 1:
		rows = [
			_smith_upgrade_row("weapon"),
			_smith_upgrade_row("armor"),
			["Bakır Çapa (Sv.2)", "%d Altın + 3 Bakır Cevheri" % _disc("demir", 150), "Tek vuruşta 3 kare çapalar!"],
			["Altın Çapa (Sv.3)", "%d Altın + 2 Altın Cevheri" % _disc("demir", 350), "Tek vuruşta 3x3 (9 kare) çapalar!"],
			["Bakır Sulama Kabı (Sv.2)", "%d Altın + 3 Bakır Cevheri" % _disc("demir", 150), "3 kare sular & 40 su kapasitesi!"],
		]
	else:
		rows = [
			["Grog'un Savaş Baltası (Destansı)", "%dG + 1 Ork Dişi + 3 Bakır" % _disc("demir", 250), "Boss 1 Ganimeti! Yüksek ATK + %2 Can Emme"],
			["Kan Şövalyesi Zırhı (Destansı)", "%dG + 1 Kan Kristali + 3 Altın" % _disc("demir", 450), "Boss 2 Ganimeti! Kızıl Şövalye görünümü + dev Can/DEF"],
			["İblis Biçen Alev Kılıcı (Efsanevi)", "%dG + 1 İblis Boynuzu + 3 Ruh Kr." % _disc("demir", 800), "Boss 3 Ganimeti! Oyunun en güçlü kılıcı (%4 Emme)"],
			["İblis Lordu Zırhı (Efsanevi)", "%dG + 1 İblis Boynuzu + 2 Kafatası" % _disc("demir", 800), "Boss 3 Ganimeti! Altın Paladin zırh görünümü"],
		]

	for i in rows.size():
		var row: Array = rows[i]
		var rr := Rect2(r.position.x + 22, r.position.y + 102 + i * 68, r.size.x - 44, 60)
		_panel_card(rr, false)
		_txt_ink(rr.position + Vector2(16, 24), "%d) %s" % [i + 1, row[0]], 15, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_txt_ink(rr.position + Vector2(16, 46), row[2], 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		_txt_ink(Vector2(rr.end.x - 16, rr.position.y + 35), row[1], 14, COL_INK_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, true)
		clickable_rects.append({"rect": rr, "action": "station_pick", "val": i})

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Sekme değiştir [Tab / Tıkla]   |   Satın Al/Döv [1-%d]   |   [E / Esc] Kapat" % rows.size(), 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_board_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 360, 175, 720, 300)
	_panel_parchment(r)
	_draw_modal_header(r, "GÜL KÖYÜ GÜNLÜK İLAN PANOSU")
	var card := Rect2(r.position.x + 24, r.position.y + 64, r.size.x - 48, 108)
	_panel_card(card, false)
	_txt_ink(card.position + Vector2(18, 28), daily_quest.title, 18, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	var have: int = bag.get(daily_quest.need_id, 0)
	_txt_ink(card.position + Vector2(18, 56), "İstenen: %d %s  (Çantanda: %d)" % [daily_quest.need_cnt, GameData.ITEMS[daily_quest.need_id].name, have], 15, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	_txt_ink(card.position + Vector2(18, 84), "Ödül: %d Altın" % daily_quest.reward, 15, COL_INK_GOLD, HORIZONTAL_ALIGNMENT_LEFT, true)
	var btn := Rect2(r.position.x + 210, r.position.y + 190, 300, 50)
	if daily_quest.done:
		_panel_card(btn, true)
		_txt_ink(btn.position + Vector2(150, 32), "Tamamlandı ✓", 16, COL_INK_GREEN, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		_panel_wood(btn)
		_txt(hud, btn.position + Vector2(150, 32), "Teslim Et (+%d Altın)" % daily_quest.reward, 16, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)
		clickable_rects.append({"rect": btn, "action": "turn_in_daily", "val": 0})
	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "[Enter] Teslim Et   |   [E / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_fishing_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.45))
	var r := Rect2(vs.x * 0.5 - 210, 120, 420, 470)
	_panel_parchment(r)
	_draw_modal_header(r, "BALIK AVI: %s" % GameData.ITEMS[fishing.fish].name)
	_txt_ink(Vector2(vs.x * 0.5, r.position.y + 74), "[Boşluk / Sol Tık Basılı Tut]", 14, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	var track := Rect2(vs.x * 0.5 - 64, r.position.y + 96, 68, 300)
	hud.draw_rect(track, Color("1a365c"))
	hud.draw_rect(track, Color("5a331c"), false, 3.0)
	hud.draw_rect(Rect2(track.position.x + 6, track.position.y + fishing.bar_y * 2.0, 56, 80), Color(0.32, 0.88, 0.45, 0.86))
	_item_icon(GameData.ITEMS[fishing.fish].icon, Rect2(track.position.x + 18, track.position.y + fishing.fish_y * 2.0, 32, 32))
	var prog_r := Rect2(track.end.x + 26, track.position.y, 26, 300)
	hud.draw_rect(prog_r, Color("2d1a0e"))
	hud.draw_rect(prog_r, Color("5a331c"), false, 2.0)
	var fh: float = 300.0 * fishing.prog / 100.0
	hud.draw_rect(Rect2(prog_r.position.x, prog_r.end.y - fh, 26, fh), Color("46bf52"))

func _draw_house_menu_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 450, 56, 900, 600)
	_panel_parchment(r)
	_draw_modal_header(r, "ÇİFTLİK EVİ — GELİŞTİRME & İÇ DEKORASYON")
	_txt(hud, Vector2(r.end.x - 62, r.position.y + 36), "Altın: %d G" % p.gold, 15, COL_GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 2, true)

	var htabs := ["1. Ev Geliştirmeleri (İstasyon Kur)", "2. Zemin, Duvar, Halı & Dekorasyon"]
	for ti in 2:
		var tr := Rect2(r.position.x + 22 + ti * 434, r.position.y + 56, 422, 36)
		var sel := ti == house_tab
		if sel:
			_panel_wood(tr)
			_txt(hud, tr.position + Vector2(211, 24), htabs[ti], 14, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)
		else:
			_panel_card(tr, false)
			_txt_ink(tr.position + Vector2(211, 24), htabs[ti], 14, COL_INK, HORIZONTAL_ALIGNMENT_CENTER, true)
		clickable_rects.append({"rect": tr, "action": "house_tab", "val": ti})

	if house_tab == 0:
		for i in GameData.HOUSE_UPGRADES.size():
			var u: Dictionary = GameData.HOUSE_UPGRADES[i]
			var uid: String = u.id
			var built: bool = bool(house_upgrades.get(uid, false))
			var cr := Rect2(r.position.x + 22, r.position.y + 104 + i * 112, 856, 102)
			_panel_card(cr, built)
			_txt_ink(cr.position + Vector2(18, 26), "%d) %s" % [i + 1, u.name], 16, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
			_txt_ink(cr.position + Vector2(18, 50), u.desc, 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)

			var min_lv: int = int(u.min_lvl)
			var need_boss: String = str(u.need_boss)
			var cost_g: int = int(u.gold)
			var mats: Dictionary = u.mats
			var ok_all: bool = p.level >= min_lv and p.gold >= cost_g and (need_boss == "" or bool(bosses_defeated.get(need_boss, false)))
			var mat_parts := PackedStringArray(["Sv.%d" % min_lv])
			if need_boss != "":
				mat_parts.append("Boss 1 Grog")
			mat_parts.append("%dG" % cost_g)
			for mk in mats.keys():
				var nc: int = int(mats[mk])
				var hc: int = bag.get(mk, 0)
				if hc < nc:
					ok_all = false
				mat_parts.append("%d %s (%d/%d)" % [nc, GameData.ITEMS[mk].name, mini(hc, nc), nc])
			var req_str := "Gereksinim: " + " • ".join(mat_parts)
			_txt_ink(cr.position + Vector2(18, 80), "Durum: Evde Aktif Kullanıma Hazır" if built else req_str, 12, COL_INK_GREEN if (built or ok_all) else COL_INK_RED, HORIZONTAL_ALIGNMENT_LEFT, true)

			var btn := Rect2(cr.end.x - 168, cr.position.y + 22, 150, 58)
			if built:
				_panel_card(btn, true)
				_draw_ui_tex("ui_confirm", Rect2(btn.position + Vector2(14, 21), Vector2(16, 15)))
				_txt_ink(btn.position + Vector2(84, 34), "KURULU", 15, COL_INK_GREEN, HORIZONTAL_ALIGNMENT_CENTER, true)
			elif ok_all:
				_panel_wood(btn)
				_txt(hud, btn.position + Vector2(75, 28), "İNŞA ET", 15, COL_GOLD, HORIZONTAL_ALIGNMENT_CENTER, 2, true)
				_txt(hud, btn.position + Vector2(75, 47), "%d Altın" % cost_g, 12, COL_CREAM, HORIZONTAL_ALIGNMENT_CENTER)
				clickable_rects.append({"rect": cr, "action": "build_upgrade", "val": uid})
			else:
				_panel_card(btn, false)
				_txt_ink(btn.position + Vector2(75, 29), "KİLİTLİ", 14, COL_INK_RED, HORIZONTAL_ALIGNMENT_CENTER, true)
				_txt_ink(btn.position + Vector2(75, 47), "Şartı Sağla", 11, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
				clickable_rects.append({"rect": btn, "action": "build_upgrade", "val": uid})
	else:
		var lx := r.position.x + 22
		# Floors
		_txt_ink(Vector2(lx, r.position.y + 114), "ZEMİN DÖŞEMESİ", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		var cur_fl: int = int(house_decor.get("floor", 0))
		for fi in GameData.HOUSE_FLOORS.size():
			var br := Rect2(lx + fi * 216, r.position.y + 124, 208, 44)
			_panel_card(br, cur_fl == fi)
			if S.has("int_floors"):
				hud.draw_texture_rect_region(S["int_floors"].t, Rect2(br.position + Vector2(10, 11), Vector2(22, 22)), Rect2(fi * 32, 0, 16, 16))
			_txt_ink(br.position + Vector2(38, 27), GameData.HOUSE_FLOORS[fi], 13, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, cur_fl == fi)
			clickable_rects.append({"rect": br, "action": "set_floor", "val": fi})

		# Rugs
		_txt_ink(Vector2(lx, r.position.y + 196), "ORTA HALI MODELİ", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		var cur_rg: int = int(house_decor.get("rug", 0))
		var rkeys := ["rug_beige", "rug_green", "rug_royal"]
		for ri in GameData.HOUSE_RUGS.size():
			var br := Rect2(lx + ri * 216, r.position.y + 206, 208, 44)
			_panel_card(br, cur_rg == ri)
			if ri < 3 and S.has(rkeys[ri]):
				hud.draw_texture_rect(S[rkeys[ri]].t, Rect2(br.position + Vector2(10, 11), Vector2(22, 22)), false)
			_txt_ink(br.position + Vector2(38 if ri < 3 else 16, 27), GameData.HOUSE_RUGS[ri], 13, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, cur_rg == ri)
			clickable_rects.append({"rect": br, "action": "set_rug", "val": ri})

		# Walls
		_txt_ink(Vector2(lx, r.position.y + 278), "DUVAR KAPLAMASI", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		var cur_wl: int = int(house_decor.get("wall", 0))
		for wi in GameData.HOUSE_WALLS.size():
			var br := Rect2(lx + wi * 288, r.position.y + 288, 280, 44)
			_panel_card(br, cur_wl == wi)
			var wkey := "int_wall_%d" % wi
			if S.has(wkey):
				hud.draw_texture_rect_region(S[wkey].t, Rect2(br.position + Vector2(10, 10), Vector2(24, 24)), Rect2(0, 0, 24, 24))
			_txt_ink(br.position + Vector2(42, 27), GameData.HOUSE_WALLS[wi], 13, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, cur_wl == wi)
			clickable_rects.append({"rect": br, "action": "set_wall", "val": wi})

		# Decor Toggles
		_txt_ink(Vector2(lx, r.position.y + 360), "İÇ MEKAN DEKORLARI (Ücretsiz Aç / Kapat)", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		for di in GameData.HOUSE_DECOR_TOGGLES.size():
			var td: Dictionary = GameData.HOUSE_DECOR_TOGGLES[di]
			var on: bool = bool(house_decor.get(td.id, true))
			var dr := Rect2(lx + (di % 2) * 432, r.position.y + 370 + int(di / 2) * 54, 424, 46)
			_panel_card(dr, on)
			_txt_ink(dr.position + Vector2(16, 29), td.name, 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
			if on:
				_draw_ui_tex("ui_confirm", Rect2(dr.end - Vector2(92, 30), Vector2(14, 14)))
				_txt_ink(dr.end - Vector2(14, 17), "AÇIK", 13, COL_INK_GREEN, HORIZONTAL_ALIGNMENT_RIGHT, true)
			else:
				_txt_ink(dr.end - Vector2(14, 17), "KAPALI", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_RIGHT, true)
			clickable_rects.append({"rect": dr, "action": "toggle_decor", "val": td.id})

		var tip := Rect2(lx, r.end.y - 76, 856, 36)
		_panel_card(tip, false)
		_txt_ink(tip.position + Vector2(428, 23), "İpucu: Yendiğin Boss'ların kupaları (Grog, Korgath, Malakor) evinin duvarında otomatik sergilenir!", 12, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Sekme değiştir [Tab / Tıkla]   |   Değişiklikler anında eve uygulanır   |   [B / E / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

func _draw_chest_modal(vs: Vector2) -> void:
	hud.draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.58))
	var r := Rect2(vs.x * 0.5 - 450, 74, 900, 560)
	_panel_parchment(r)
	_draw_modal_header(r, "EV SANDIĞI & DEPOLAMA")

	var lx := r.position.x + 22
	var rx := r.position.x + 462
	_txt_ink(Vector2(lx, r.position.y + 72), "SIRT ÇANTAN (Tıkla → Sandığa Koy)", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	_txt_ink(Vector2(rx, r.position.y + 72), "EV SANDIĞI (Tıkla → Çantana Al)", 14, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
	hud.draw_line(Vector2(r.position.x + 450, r.position.y + 58), Vector2(r.position.x + 450, r.end.y - 44), Color("b8894f"), 2.0)

	var bag_keys := bag.keys()
	bag_keys.sort()
	if bag_keys.is_empty():
		_txt_ink(Vector2(lx + 206, r.position.y + 260), "Sırt çantan boş!", 15, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	for i in mini(16, bag_keys.size()):
		var id: String = bag_keys[i]
		var it: Dictionary = GameData.ITEMS[id]
		var cr := Rect2(lx + (i % 2) * 208, r.position.y + 84 + int(i / 2) * 52, 202, 46)
		_panel_card(cr, false)
		_item_icon(it.icon, Rect2(cr.position + Vector2(8, 9), Vector2(28, 28)))
		_txt_ink(cr.position + Vector2(42, 21), it.name, 12, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_txt_ink(cr.position + Vector2(42, 38), "Adet: %d" % bag[id], 11, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		clickable_rects.append({"rect": cr, "action": "chest_store", "val": id})

	var chest_keys := house_chest.keys()
	chest_keys.sort()
	if chest_keys.is_empty():
		_txt_ink(Vector2(rx + 206, r.position.y + 260), "Sandık şu an boş.", 15, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	for i in mini(16, chest_keys.size()):
		var id: String = chest_keys[i]
		if not GameData.ITEMS.has(id):
			continue
		var it: Dictionary = GameData.ITEMS[id]
		var cr := Rect2(rx + (i % 2) * 208, r.position.y + 84 + int(i / 2) * 52, 202, 46)
		_panel_card(cr, false)
		_item_icon(it.icon, Rect2(cr.position + Vector2(8, 9), Vector2(28, 28)))
		_txt_ink(cr.position + Vector2(42, 21), it.name, 12, COL_INK, HORIZONTAL_ALIGNMENT_LEFT, true)
		_txt_ink(cr.position + Vector2(42, 38), "Sandıkta: %d" % int(house_chest[id]), 11, COL_INK_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		clickable_rects.append({"rect": cr, "action": "chest_take", "val": id})

	_txt_ink(Vector2(vs.x * 0.5, r.end.y - 16), "Eşyaya tıkla: Çanta ⇄ Ev Sandığı arası taşı   |   [E / I / Esc] Kapat", 13, COL_INK_MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)

# ==============================================================================
#  SAVE / LOAD SYSTEM (V4)
# ==============================================================================
func _active_save_path() -> String:
	return "user://cayir_vadisi_test_save.json" if test_mode else SAVE_PATH

func _save_game(silent := false, force := false) -> void:
	if test_mode and not force:
		return
	var fg := {}
	for c in farm_grid.keys():
		fg["%d,%d" % [c.x, c.y]] = farm_grid[c]
	var pd := p.duplicate()
	pd.pos = [p.pos.x, p.pos.y]
	pd.roll_dir = [p.roll_dir.x, p.roll_dir.y]
	var an: Array = []
	for a in animals:
		an.append({"type": a.type, "name": a.name})
	var data := {
		"v": 4, "season": season, "day": day, "year": year, "hour": hour, "minute": minute,
		"raining": is_raining, "p": pd, "bag": bag, "gear_bag": gear_bag, "equipped": equipped,
		"farm": fg, "animals": an, "story_step": story_step, "story_prog": story_prog,
		"daily": daily_quest, "npc_rel": npc_rel, "bosses_defeated": bosses_defeated,
		"boss_respawn_days": boss_respawn_days,
		"in_house": in_house, "saved_outdoor_pos": [saved_outdoor_pos.x, saved_outdoor_pos.y],
		"house_upgrades": house_upgrades, "house_decor": house_decor,
		"house_chest": house_chest, "well_rested": well_rested,
	}
	var f := FileAccess.open(_active_save_path(), FileAccess.WRITE)
	if f == null:
		_toast("Kayıt başarısız!", Color(1.0, 0.4, 0.4))
		return
	f.store_string(JSON.stringify(data))
	f.close()
	if not silent:
		_toast("Oyun kaydedildi.", Color(0.6, 1.0, 0.7))

func _fix_gear(g):
	if g == null or typeof(g) != TYPE_DICTIONARY:
		return null
	for k in ["rarity", "lvl", "atk", "def", "hp", "crit", "ls", "plus", "icon", "value", "skin"]:
		g[k] = int(g.get(k, 0))
	return g

func _load_game() -> bool:
	var f := FileAccess.open(_active_save_path(), FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	_new_game()
	season = int(data.get("season", 0))
	day = int(data.get("day", 1))
	year = int(data.get("year", 1))
	hour = int(data.get("hour", 7))
	minute = int(data.get("minute", 0))
	is_raining = bool(data.get("raining", false))
	var pd: Dictionary = data.get("p", {})
	for k in pd.keys():
		if p.has(k) and not (k in ["pos", "roll_dir"]):
			p[k] = pd[k]
	for k in ["gold", "slot", "hoe_tier", "water_tier", "water_tank", "water_max", "level", "xp", "kills", "boss_kills"]:
		p[k] = int(p.get(k, 0))
	var pp: Array = pd.get("pos", [445, 415])
	p.pos = Vector2(pp[0], pp[1])
	p.anim = "idle"
	p.act_t = 0.0
	p.roll_t = 0.0
	bag.clear()
	var b: Dictionary = data.get("bag", {})
	for k in b.keys():
		if GameData.ITEMS.has(k):
			bag[k] = int(b[k])
	gear_bag.clear()
	for g in data.get("gear_bag", []):
		var fg2 = _fix_gear(g)
		if fg2 != null:
			gear_bag.append(fg2)
	var eq: Dictionary = data.get("equipped", {})
	for k in ["weapon", "armor", "shield", "ring"]:
		equipped[k] = _fix_gear(eq.get(k, null))
	farm_grid.clear()
	var fgd: Dictionary = data.get("farm", {})
	for key in fgd.keys():
		var parts: PackedStringArray = key.split(",")
		var tile: Dictionary = fgd[key]
		tile.stage = int(tile.get("stage", 0))
		tile.days = int(tile.get("days", 0))
		farm_grid[Vector2i(int(parts[0]), int(parts[1]))] = tile
	var an: Array = data.get("animals", [])
	if not an.is_empty():
		animals.clear()
		for a in an:
			var ap := Vector2(randf_range(690, 900), randf_range(500, 630))
			animals.append({"type": a.type, "name": a.name, "pos": ap, "goal": ap, "flip": false, "t": randf(), "wait": 1.0, "petted": false})
	story_step = int(data.get("story_step", 0))
	story_prog = int(data.get("story_prog", 0))
	var dq = data.get("daily", null)
	if typeof(dq) == TYPE_DICTIONARY and dq.has("need_id"):
		daily_quest = dq
		daily_quest.need_cnt = int(dq.need_cnt)
		daily_quest.reward = int(dq.reward)
	var rel_d: Dictionary = data.get("npc_rel", {})
	for vid in rel_d.keys():
		if npc_rel.has(vid):
			npc_rel[vid].merge(rel_d[vid], true)
			npc_rel[vid].pts = int(npc_rel[vid].pts)
	bosses_defeated = data.get("bosses_defeated", {})
	var brd: Dictionary = data.get("boss_respawn_days", {})
	for k in brd.keys():
		boss_respawn_days[k] = int(brd[k])

	# Restore V4 House & Interior State
	in_house = bool(data.get("in_house", false))
	var sop: Array = data.get("saved_outdoor_pos", [395, 377])
	saved_outdoor_pos = Vector2(float(sop[0]), float(sop[1]))
	var hu: Dictionary = data.get("house_upgrades", {})
	for uk in hu.keys():
		house_upgrades[uk] = bool(hu[uk])
	var hd: Dictionary = data.get("house_decor", {})
	for dk in hd.keys():
		house_decor[dk] = hd[dk]
	for nk in ["floor", "rug", "wall"]:
		house_decor[nk] = int(house_decor.get(nk, 0))
	house_chest.clear()
	var hc: Dictionary = data.get("house_chest", {})
	for ck in hc.keys():
		if GameData.ITEMS.has(ck):
			house_chest[ck] = int(hc[ck])
	well_rested = bool(data.get("well_rested", false))
	if not _can_walk(p.pos):
		p.pos = Vector2(240, 272) if in_house else (HOUSE_DOOR + Vector2(0, 18))
	if in_house:
		dog.pos = Vector2(192, 260)
	_apply_cam_mode()
	_spawn_enemies()
	_refresh_stats()
	cur_zone = "ÇİFTLİK EVİ" if in_house else ""
	return true

# ==============================================================================
#  AUTOMATED V4 VERIFICATION & SCREENSHOT SUITE (SPIRIT_TEST=1)
# ==============================================================================
func _snap(filename: String) -> void:
	var dir := ProjectSettings.globalize_path("res://screenshots/")
	var im := get_viewport().get_texture().get_image()
	if im != null:
		im.save_png(dir + filename)
		print("[TEST SHOT] ", dir + filename)

func _run_automated_test(delta: float) -> void:
	test_timer += delta
	var T := [0.45, 0.95, 1.45, 1.95, 2.45, 2.95, 3.5, 4.05, 4.6, 5.2]
	if test_stage >= T.size() or test_timer < T[test_stage]:
		return
	match test_stage:
		0:
			state = "title"
		1:
			_snap("v4_01_title.png")
			state = "play"
			in_house = false
			_apply_cam_mode()
			p.pos = Vector2(405, 376)
			p.dir = "up"
			dog.pos = Vector2(368, 390)
			cam.position = p.pos + Vector2(0, -14)
			cam.reset_smoothing()
		2:
			_snap("v4_02_clean_farm.png")
			_enter_house()
			house_fade = 0.0
			p.pos = Vector2(190, 198)
			p.dir = "down"
			dog.pos = Vector2(168, 256)
			cam.position = Vector2(240, 196)
			cam.reset_smoothing()
		3:
			_snap("v4_03_house_starter.png")
			state = "house_menu"
			house_tab = 0
		4:
			_snap("v4_04_house_decorate_ui.png")
			house_upgrades = {"kitchen": true, "alchemy": true, "forge": true, "grand_home": true}
			house_decor["floor"] = 1
			house_decor["wall"] = 2
			house_decor["rug"] = 2
			bosses_defeated["grog"] = true
			bosses_defeated["korgath"] = true
			bosses_defeated["malakor"] = true
			well_rested = true
			_refresh_stats()
			state = "play"
			p.pos = Vector2(236, 206)
			p.dir = "down"
			dog.pos = Vector2(186, 268)
		5:
			_snap("v4_05_house_upgraded.png")
			_exit_house()
			house_fade = 0.0
			p.pos = Vector2(1480, 495)
			cam.position = p.pos + Vector2(0, -14)
			cam.reset_smoothing()
			_open_villager_dialog("ayla")
			_do_talk_chat()
			_give_gift_to_npc("sunflower")
		6:
			_snap("v4_06_stardew_dialog.png")
			state = "social"
		7:
			_snap("v4_07_neighbors_parchment.png")
			equipped["weapon"] = _make_gear("weapon", 10, 3, 8)
			equipped["armor"] = _make_gear("armor", 10, 3, 6)
			equipped["shield"] = _make_gear("shield", 10, 3, 4)
			equipped["ring"] = _make_gear("ring", 10, 4, 5)
			for r in 6:
				gear_bag.append(_make_gear(["weapon", "armor", "shield", "ring"][r % 4], 4 + r, r % 5))
			_refresh_stats()
			p.level = 9
			p.hp = p.max_hp
			state = "char"
		8:
			_snap("v4_08_character_parchment.png")
			state = "play"
			p.level = 14
			equipped["armor"] = _make_gear("armor", 14, 4, 8)
			_refresh_stats()
			p.hp = p.max_hp
			p.pos = Vector2(3190, 630)
			dog.pos = p.pos + Vector2(-24, 12)
			cam.position = p.pos + Vector2(0, -14)
			cam.reset_smoothing()
			lightning_zones.append({"pos": p.pos + Vector2(36, -16), "t": 0.6, "dmg": 10.0})
			for e in enemies:
				if e.boss_id == "malakor":
					e.aggro = true
					e.atk_anim = "atk2"
					e.atk_anim_t = 0.45
					e.hp = e.max * 0.5
		9:
			_snap("v4_09_boss_hud.png")
			_enter_house()
			house_chest["wood"] = 12
			_save_game(true, true)
			var lv: int = p.level
			var gb := gear_bag.size()
			var ok := _load_game()
			assert(ok, "Load game failed")
			assert(p.level == lv, "Level roundtrip mismatch")
			assert(gear_bag.size() == gb, "Gear bag roundtrip mismatch")
			assert(equipped.shield != null, "Shield roundtrip mismatch")
			assert(bosses_defeated.get("grog", false), "Boss defeated roundtrip mismatch")
			assert(_hearts("ayla") >= 1, "Villager relationship roundtrip mismatch")
			assert(house_upgrades.get("kitchen", false), "House kitchen roundtrip mismatch")
			assert(int(house_decor.get("rug", 0)) == 2, "House decor rug roundtrip mismatch")
			assert(int(house_chest.get("wood", 0)) == 12, "House chest roundtrip mismatch")
			assert(in_house == true, "in_house roundtrip mismatch")
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_active_save_path()))
			print("[TEST] ALL V4 CHECKS PASSED (lv=", p.level, " gear=", gear_bag.size(), " kitchen=", house_upgrades.get("kitchen", false), " rug=", house_decor.get("rug", -1), ")")
			get_tree().quit(0)
	test_stage += 1
