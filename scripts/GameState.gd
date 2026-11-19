extends Node

# ==============================================================================
# SPIRIT MEADOW - GAME STATE MANAGER (AUTOLOAD SINGLETON)
# ==============================================================================

signal time_tick(hour: int, minute: int)
signal day_passed(day: int, season_index: int, year: int)
signal season_changed(new_season_name: String)
signal inventory_updated
signal money_changed(new_amount: int)
signal stamina_changed(current: float, maximum: float)
signal show_notification(text: String, icon_texture: Texture2D)
signal start_dialogue(npc_name: String, portrait_tex: Texture2D, texts: Array)
signal open_fishing_minigame(fish_type: String)

enum Season { SPRING, SUMMER, FALL, WINTER }
const SEASON_NAMES = ["İlkbahar", "Yaz", "Sonbahar", "Kış"]
const SEASON_COLORS = [
	Color(0.95, 1.0, 0.95),  # Spring soft fresh
	Color(1.0, 0.98, 0.90),  # Summer warm golden
	Color(1.0, 0.92, 0.82),  # Fall amber
	Color(0.88, 0.94, 1.0)   # Winter cool frost
]

# Time settings
var current_minute: int = 0
var current_hour: int = 6
var current_day: int = 1
var current_season: int = Season.SPRING
var current_year: int = 1
var time_speed: float = 1.0 # 1 minute per real second at speed 1.0
var time_accum: float = 0.0
var is_time_paused: bool = false

# Player stats
var money: int = 500
var stamina: float = 100.0
var max_stamina: float = 100.0
var selected_hotbar_slot: int = 0

# Inventory: 30 slots (0..9 hotbar, 10..29 backpack)
# Each slot: {"id": String, "count": int} or null
var inventory: Array = []

# Farm Data: Vector2i -> Dictionary
# {"tilled": bool, "watered": bool, "crop_id": String, "growth_stage": int, "days_growing": int}
var farm_data: Dictionary = {}

# Items Database
var items_db: Dictionary = {
	# Tools
	"tool_hoe": { "name": "Demir Çapa", "type": "tool", "desc": "Toprağı çapalayarak ekime hazır hale getirir.", "sell": 0, "sheet_col": 0, "sheet_row": 0 },
	"tool_water": { "name": "Sulama Kabı", "type": "tool", "desc": "Çapalanmış toprağı sular. Ekinler her gün suya ihtiyaç duyar.", "sell": 0, "sheet_col": 1, "sheet_row": 0 },
	"tool_rod": { "name": "Bambu Olta", "type": "tool", "desc": "Su kenarında balık tutmaya yarar.", "sell": 0, "sheet_col": 2, "sheet_row": 0 },
	"tool_axe": { "name": "Oduncu Baltası", "type": "tool", "desc": "Ağaç ve çalıları budamaya yarar.", "sell": 0, "sheet_col": 3, "sheet_row": 0 },
	"tool_scythe": { "name": "Hasat Tırpanı", "type": "tool", "desc": "Olgunlaşmış ekinleri ve yabani otları toplar.", "sell": 0, "sheet_col": 4, "sheet_row": 0 },

	# Seeds
	"seed_strawberry": { "name": "Çilek Tohumu", "type": "seed", "crop_id": "strawberry", "season": Season.SPRING, "growth_days": 2, "desc": "İlkbahar için tatlı çilek tohumları.", "sell": 15, "sheet_col": 5, "sheet_row": 0 },
	"seed_corn": { "name": "Mısır Tohumu", "type": "seed", "crop_id": "corn", "season": Season.SUMMER, "growth_days": 3, "desc": "Yaz aylarında boy veren altın mısır tohumu.", "sell": 25, "sheet_col": 6, "sheet_row": 0 },
	"seed_pumpkin": { "name": "Balkabağı Tohumu", "type": "seed", "crop_id": "pumpkin", "season": Season.FALL, "growth_days": 3, "desc": "Sonbahara özgü dev tatlı balkabağı tohumu.", "sell": 40, "sheet_col": 7, "sheet_row": 0 },
	"seed_frostberry": { "name": "Buz Meyvesi Tohumu", "type": "seed", "crop_id": "frostberry", "season": Season.WINTER, "growth_days": 2, "desc": "Kışın dondurucu soğukta bile parıldayan mistik tohum.", "sell": 35, "sheet_col": 3, "sheet_row": 1 },

	# Crops (Harvested)
	"crop_strawberry": { "name": "Tatlı Çilek", "type": "crop", "stamina": 18, "desc": "Sulu ve mis kokulu ilkbahar çileği.", "sell": 55, "sheet_col": 0, "sheet_row": 1 },
	"crop_corn": { "name": "Altın Mısır", "type": "crop", "stamina": 22, "desc": "Güneşin enerjisiyle dolmuş leziz mısır koçanı.", "sell": 80, "sheet_col": 1, "sheet_row": 1 },
	"crop_pumpkin": { "name": "Dev Balkabağı", "type": "crop", "stamina": 35, "desc": "Ağır ve besleyici sonbahar hasadı.", "sell": 160, "sheet_col": 2, "sheet_row": 1 },
	"crop_frostberry": { "name": "Kristal Buz Meyvesi", "type": "crop", "stamina": 28, "desc": "Ağızda serinletici lezzet bırakan nadir kış meyvesi.", "sell": 125, "sheet_col": 3, "sheet_row": 1 },

	# Forageables
	"forage_mushroom_red": { "name": "Kırmızı Orman Mantarı", "type": "forage", "stamina": 12, "desc": "Ağaç diplerinde biten leziz yaban mantarı.", "sell": 35, "sheet_col": 4, "sheet_row": 1 },
	"forage_mushroom_glow": { "name": "Ay Işığı Mantarı", "type": "forage", "stamina": 30, "desc": "Geceleri masmavi parlayan sihirli mantar.", "sell": 90, "sheet_col": 5, "sheet_row": 1 },
	"forage_truffle": { "name": "Kara Trüf Mantarı", "type": "forage", "stamina": 40, "desc": "Toprağın derinliklerinden çıkan paha biçilemez mantar.", "sell": 200, "sheet_col": 6, "sheet_row": 1 },
	"forage_wood": { "name": "Meşe Odunu", "type": "material", "desc": "Çit ve yapı inşasında kullanılan sağlam odun.", "sell": 8, "sheet_col": 7, "sheet_row": 1 },

	# Fish
	"fish_trout": { "name": "Nehir Alabalığı", "type": "fish", "stamina": 20, "desc": "Hızlı ve berrak sularda yaşayan çevik balık.", "sell": 60, "sheet_col": 0, "sheet_row": 2 },
	"fish_sunfish": { "name": "Gökkuşağı Güneşbalığı", "type": "fish", "stamina": 25, "desc": "Yaz günlerinde parıldayan renkli balık.", "sell": 85, "sheet_col": 1, "sheet_row": 2 },
	"fish_eel": { "name": "Mistik Ay Müreni", "type": "fish", "stamina": 45, "desc": "Sadece akşam ve gece gölette beliren gizemli balık.", "sell": 175, "sheet_col": 2, "sheet_row": 2 },
	"fish_koi": { "name": "Kraliyet Altın Koi", "type": "fish", "stamina": 50, "desc": "Bereketi simgeleyen efsanevi balık.", "sell": 260, "sheet_col": 3, "sheet_row": 2 },

	# Special / Spirits
	"item_spirit_tear": { "name": "Orman Ruhu Özü", "type": "special", "stamina": 60, "desc": "Orman ruhlarının sevgisini kazananlara verilen kutsal damla.", "sell": 350, "sheet_col": 5, "sheet_row": 2 }
}

# Preloaded assets
var sfx_streams: Dictionary = {}
var items_sheet: Texture2D

func _ready() -> void:
	# Load item sheet texture
	if ResourceLoader.exists("res://assets/sprites/items.png"):
		items_sheet = load("res://assets/sprites/items.png")
	
	# Load SFX
	var sfx_names = ["hoe", "water", "seed", "harvest", "bite", "catch", "step", "blip", "click"]
	for s_name in sfx_names:
		var path = "res://assets/sfx/" + s_name + ".wav"
		if ResourceLoader.exists(path):
			sfx_streams[s_name] = load(path)
			
	init_inventory()

func init_inventory() -> void:
	inventory.clear()
	inventory.resize(30)
	for i in range(30):
		inventory[i] = null
		
	# Starting starter pack for the player!
	inventory[0] = { "id": "tool_hoe", "count": 1 }
	inventory[1] = { "id": "tool_water", "count": 1 }
	inventory[2] = { "id": "tool_rod", "count": 1 }
	inventory[3] = { "id": "seed_strawberry", "count": 8 }
	inventory[4] = { "id": "seed_corn", "count": 4 }
	inventory[5] = { "id": "forage_mushroom_red", "count": 3 }

func _process(delta: float) -> void:
	if is_time_paused:
		return
		
	time_accum += delta * time_speed * 1.5 # 1 game minute every 0.67s real time
	if time_accum >= 1.0:
		time_accum -= 1.0
		advance_minute()

func advance_minute() -> void:
	current_minute += 10
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		
		# Energy slight recovery or exhaustion at late night
		if current_hour >= 26: # 2:00 AM - Player collapses to sleep!
			sleep_and_new_day("Gece 02:00 oldu ve yorgunluktan uyuyakaldın!")
			return

	emit_signal("time_tick", current_hour, current_minute)

func sleep_and_new_day(reason_text: String = "Yeni bir güne uyandın!") -> void:
	current_hour = 6
	current_minute = 0
	current_day += 1
	stamina = max_stamina
	emit_signal("stamina_changed", stamina, max_stamina)

	# 28 days per season
	if current_day > 28:
		current_day = 1
		current_season = (current_season + 1) % 4
		if current_season == Season.SPRING:
			current_year += 1
		emit_signal("season_changed", SEASON_NAMES[current_season])

	# Overnight farm crop update: watered crops grow!
	process_crops_overnight()

	emit_signal("day_passed", current_day, current_season, current_year)
	emit_signal("show_notification", reason_text, null)

func process_crops_overnight() -> void:
	for coord in farm_data.keys():
		var tile = farm_data[coord]
		if tile.get("watered", false) and tile.get("crop_id", "") != "":
			tile["days_growing"] = tile.get("days_growing", 0) + 1
			var crop_info = items_db.get("seed_" + tile["crop_id"], {})
			var req_days = crop_info.get("growth_days", 3)
			# Advance visual stage (0, 1, 2, 3 = mature)
			var stage = int(min(3, float(tile["days_growing"]) / float(req_days) * 3.0))
			tile["growth_stage"] = stage
		
		# Reset watering daily (needs to be watered again every day)
		tile["watered"] = false

func add_item(item_id: String, count: int = 1) -> bool:
	if not items_db.has(item_id):
		return false

	# Try to stack first
	for i in range(inventory.size()):
		if inventory[i] != null and inventory[i]["id"] == item_id:
			inventory[i]["count"] += count
			emit_signal("inventory_updated")
			emit_signal("show_notification", "+%d %s" % [count, items_db[item_id]["name"]], get_item_texture(item_id))
			return true

	# Find empty slot
	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = { "id": item_id, "count": count }
			emit_signal("inventory_updated")
			emit_signal("show_notification", "+%d %s" % [count, items_db[item_id]["name"]], get_item_texture(item_id))
			return true

	emit_signal("show_notification", "Çanta tamamen dolu!", null)
	return false

func remove_item(slot_index: int, count: int = 1) -> bool:
	if slot_index < 0 or slot_index >= inventory.size() or inventory[slot_index] == null:
		return false

	inventory[slot_index]["count"] -= count
	if inventory[slot_index]["count"] <= 0:
		inventory[slot_index] = null

	emit_signal("inventory_updated")
	return true

func consume_stamina(amount: float) -> bool:
	if stamina < amount:
		emit_signal("show_notification", "Çok yoruldun! Dinlenmen gerek.", null)
		return false
	stamina = max(0.0, stamina - amount)
	emit_signal("stamina_changed", stamina, max_stamina)
	return true

func restore_stamina(amount: float) -> void:
	stamina = min(max_stamina, stamina + amount)
	emit_signal("stamina_changed", stamina, max_stamina)

func add_money(amount: int) -> void:
	money += amount
	emit_signal("money_changed", money)
	emit_signal("show_notification", "+%d Altın!" % amount, null)

func get_item_texture(item_id: String) -> AtlasTexture:
	if not items_db.has(item_id) or items_sheet == null:
		return null
	var data = items_db[item_id]
	var col = data.get("sheet_col", 0)
	var row = data.get("sheet_row", 0)
	var atlas = AtlasTexture.new()
	atlas.atlas = items_sheet
	atlas.region = Rect2(col * 32, row * 32, 32, 32)
	return atlas

func play_sfx(sfx_name: String) -> void:
	if sfx_streams.has(sfx_name):
		var p = AudioStreamPlayer.new()
		p.stream = sfx_streams[sfx_name]
		p.volume_db = -4.0
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
