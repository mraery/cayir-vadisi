extends Node2D

# ==============================================================================
# SPIRIT MEADOW - FARM GRID & WORLD ENVIRONMENT
# ==============================================================================

const CELL_SIZE = 32
const GRID_WIDTH = 30
const GRID_HEIGHT = 17

var tiles_sheet: Texture2D
var crops_sheet: Texture2D

# Special interactive object rects in grid coordinates
var pond_cells: Array[Vector2i] = []
var shipping_bin_cell = Vector2i(18, 4)
var spirit_shrine_cell = Vector2i(22, 3)
var farm_house_rect = Rect2i(13, 1, 4, 3)

# Forageable items on ground: Vector2i -> item_id
var forage_spawns: Dictionary = {}

func _ready() -> void:
	if ResourceLoader.exists("res://assets/sprites/tiles.png"):
		tiles_sheet = load("res://assets/sprites/tiles.png")
	if ResourceLoader.exists("res://assets/sprites/crops.png"):
		crops_sheet = load("res://assets/sprites/crops.png")

	# Define pond area on the left
	for x in range(2, 7):
		for y in range(8, 14):
			pond_cells.append(Vector2i(x, y))

	# Initialize default tilled demo farm patch in center
	for x in range(12, 17):
		for y in range(7, 11):
			var pos = Vector2i(x, y)
			GameState.farm_data[pos] = {
				"tilled": true,
				"watered": false,
				"crop_id": "",
				"growth_stage": 0,
				"days_growing": 0
			}

	# Plant some initial crops for immediate joy!
	GameState.farm_data[Vector2i(12, 7)]["crop_id"] = "strawberry"
	GameState.farm_data[Vector2i(12, 7)]["growth_stage"] = 3 # Ready to harvest!
	GameState.farm_data[Vector2i(13, 7)]["crop_id"] = "strawberry"
	GameState.farm_data[Vector2i(13, 7)]["growth_stage"] = 2
	GameState.farm_data[Vector2i(14, 7)]["crop_id"] = "corn"
	GameState.farm_data[Vector2i(14, 7)]["growth_stage"] = 1

	spawn_seasonal_forage()
	GameState.day_passed.connect(_on_day_passed)
	GameState.season_changed.connect(_on_season_changed)

func spawn_seasonal_forage() -> void:
	forage_spawns.clear()
	# Spawn mushrooms and resources based on current season
	if GameState.current_season == GameState.Season.FALL or GameState.current_season == GameState.Season.SPRING:
		forage_spawns[Vector2i(24, 8)] = "forage_mushroom_red"
		forage_spawns[Vector2i(26, 12)] = "forage_mushroom_glow"
	else:
		forage_spawns[Vector2i(24, 8)] = "forage_wood"

	forage_spawns[Vector2i(8, 5)] = "forage_wood"
	forage_spawns[Vector2i(25, 4)] = "forage_mushroom_red"
	queue_redraw()

func _on_day_passed(_day: int, _season: int, _year: int) -> void:
	spawn_seasonal_forage()
	queue_redraw()

func _on_season_changed(_season_name: String) -> void:
	queue_redraw()

func is_water_tile(grid_pos: Vector2i) -> bool:
	return grid_pos in pond_cells

func is_solid(grid_pos: Vector2i) -> bool:
	# Water is solid to walk on
	if is_water_tile(grid_pos):
		return true
	# Farm house
	if farm_house_rect.has_point(grid_pos):
		return true
	# Shipping bin & Shrine
	if grid_pos == shipping_bin_cell or grid_pos == spirit_shrine_cell:
		return true
	# Bounds
	if grid_pos.x < 1 or grid_pos.x >= GRID_WIDTH - 1 or grid_pos.y < 1 or grid_pos.y >= GRID_HEIGHT - 1:
		return true
	return false

# Handle player action at a specific grid position
func interact_tile(grid_pos: Vector2i) -> bool:
	# 1. Check Foraging
	if forage_spawns.has(grid_pos):
		var item_id = forage_spawns[grid_pos]
		if GameState.add_item(item_id, 1):
			forage_spawns.erase(grid_pos)
			GameState.play_sfx("harvest")
			queue_redraw()
			return true

	# 2. Check Shipping Bin
	if grid_pos == shipping_bin_cell:
		sell_held_or_all_crops()
		return true

	# 3. Check Spirit Shrine
	if grid_pos == spirit_shrine_cell:
		interact_spirit_shrine()
		return true

	# 4. Check Water for Fishing
	var equipped = get_equipped_item()
	var equipped_id = equipped["id"] if equipped != null else ""

	if is_water_tile(grid_pos):
		if equipped_id == "tool_rod":
			start_fishing()
			return true
		elif equipped_id == "tool_water":
			GameState.emit_signal("show_notification", "Sulama kabını doldurdun!", null)
			GameState.play_sfx("water")
			return true
		else:
			GameState.emit_signal("show_notification", "Balık tutmak için Oltanı seç!", null)
			return false

	# 5. Check Mature Crop Harvest
	if GameState.farm_data.has(grid_pos):
		var tile = GameState.farm_data[grid_pos]
		if tile.get("crop_id", "") != "" and tile.get("growth_stage", 0) >= 3:
			harvest_crop(grid_pos, tile)
			return true

	# 6. Tools on Farm Ground
	if equipped_id == "tool_hoe":
		return till_tile(grid_pos)
	elif equipped_id == "tool_water":
		return water_tile(grid_pos)
	elif equipped_id.begins_with("seed_"):
		return plant_seed(grid_pos, equipped_id)

	return false

func get_equipped_item():
	var slot = GameState.selected_hotbar_slot
	if slot >= 0 and slot < GameState.inventory.size():
		return GameState.inventory[slot]
	return null

func till_tile(grid_pos: Vector2i) -> bool:
	if is_solid(grid_pos):
		return false

	if not GameState.consume_stamina(3.0):
		return false

	if not GameState.farm_data.has(grid_pos):
		GameState.farm_data[grid_pos] = {
			"tilled": true,
			"watered": false,
			"crop_id": "",
			"growth_stage": 0,
			"days_growing": 0
		}
	else:
		GameState.farm_data[grid_pos]["tilled"] = true

	GameState.play_sfx("hoe")
	queue_redraw()
	return true

func water_tile(grid_pos: Vector2i) -> bool:
	if not GameState.farm_data.has(grid_pos) or not GameState.farm_data[grid_pos].get("tilled", false):
		return false

	if not GameState.consume_stamina(2.0):
		return false

	GameState.farm_data[grid_pos]["watered"] = true
	GameState.play_sfx("water")
	queue_redraw()
	return true

func plant_seed(grid_pos: Vector2i, seed_id: String) -> bool:
	if not GameState.farm_data.has(grid_pos) or not GameState.farm_data[grid_pos].get("tilled", false):
		GameState.emit_signal("show_notification", "Önce toprağı çapalaman gerek!", null)
		return false

	var tile = GameState.farm_data[grid_pos]
	if tile.get("crop_id", "") != "":
		GameState.emit_signal("show_notification", "Burada zaten bir ekin büyüyor!", null)
		return false

	var seed_info = GameState.items_db.get(seed_id, {})
	var crop_id = seed_info.get("crop_id", "")

	tile["crop_id"] = crop_id
	tile["growth_stage"] = 0
	tile["days_growing"] = 0

	GameState.remove_item(GameState.selected_hotbar_slot, 1)
	GameState.play_sfx("seed")
	queue_redraw()
	return true

func harvest_crop(grid_pos: Vector2i, tile: Dictionary) -> void:
	var crop_id = tile["crop_id"]
	var harvest_item_id = "crop_" + crop_id

	if GameState.add_item(harvest_item_id, 1):
		GameState.play_sfx("harvest")
		# Reset crop spot
		tile["crop_id"] = ""
		tile["growth_stage"] = 0
		tile["days_growing"] = 0
		# Chance to drop Spirit Tear as special twist!
		if randf() < 0.25:
			GameState.add_item("item_spirit_tear", 1)
			GameState.emit_signal("show_notification", "Hasat yaparken bir Orman Ruhu belirdi ve Ruh Özü bıraktı!", null)
		queue_redraw()

func start_fishing() -> void:
	if not GameState.consume_stamina(4.0):
		return

	# Choose fish depending on season and time
	var fish_choices = ["fish_trout", "fish_sunfish"]
	if GameState.current_hour >= 18 or GameState.current_hour < 6:
		fish_choices.append("fish_eel")
	if randf() < 0.15:
		fish_choices.append("fish_koi")

	var chosen_fish = fish_choices[randi() % fish_choices.size()]
	GameState.emit_signal("open_fishing_minigame", chosen_fish)

func sell_held_or_all_crops() -> void:
	var total_earned = 0
	var sold_count = 0

	for i in range(GameState.inventory.size()):
		var slot = GameState.inventory[i]
		if slot != null:
			var item_id = slot["id"]
			var data = GameState.items_db.get(item_id, {})
			var item_type = data.get("type", "")
			if item_type in ["crop", "fish", "forage", "material", "special"]:
				var price = data.get("sell", 0)
				var count = slot["count"]
				total_earned += price * count
				sold_count += count
				GameState.inventory[i] = null

	if total_earned > 0:
		GameState.add_money(total_earned)
		GameState.emit_signal("inventory_updated")
		GameState.play_sfx("harvest")
		GameState.emit_signal("show_notification", "Sevkiyat sandığı satıldı! +%d Altın (%d eşya)" % [total_earned, sold_count], null)
	else:
		GameState.emit_signal("show_notification", "Sevkiyat sandığına satılacak ekin/balık/mantar koymalısın.", null)

func interact_spirit_shrine() -> void:
	# Check if player has Spirit Tear
	for i in range(GameState.inventory.size()):
		var slot = GameState.inventory[i]
		if slot != null and slot["id"] == "item_spirit_tear":
			GameState.remove_item(i, 1)
			GameState.play_sfx("harvest")
			GameState.restore_stamina(100.0)
			# Advance all growing crops by 1 full day immediately!
			for coord in GameState.farm_data.keys():
				var t = GameState.farm_data[coord]
				if t.get("crop_id", "") != "":
					t["growth_stage"] = min(3, t["growth_stage"] + 1)
			queue_redraw()
			GameState.emit_signal("show_notification", "Ruhlar Mabedi parıldadı! Orman bereketi tüm ekinleri hızla büyüttü!", null)
			return

	GameState.emit_signal("show_notification", "Antik Ruh Mabedi: Hasat yaparken bulabileceğin 'Ruh Özü' adarsan ekinleri kutsar.", null)

# ==============================================================================
# DRAWING ROUTINE
# ==============================================================================
func _draw() -> void:
	if tiles_sheet == null:
		return

	# 1. Draw base grass ground based on season
	var grass_col = GameState.current_season # 0: Spring, 1: Summer, 2: Fall, 3: Winter
	var grass_src = Rect2(grass_col * 32, 0, 32, 32)
	for gx in range(GRID_WIDTH):
		for gy in range(GRID_HEIGHT):
			draw_texture_rect_region(tiles_sheet, Rect2(gx * CELL_SIZE, gy * CELL_SIZE, CELL_SIZE, CELL_SIZE), grass_src)

	# 2. Draw Stone Path
	var stone_src = Rect2(7 * 32, 0, 32, 32)
	for py in range(4, 15):
		draw_texture_rect_region(tiles_sheet, Rect2(10 * CELL_SIZE, py * CELL_SIZE, CELL_SIZE, CELL_SIZE), stone_src)
	for px in range(10, 20):
		draw_texture_rect_region(tiles_sheet, Rect2(px * CELL_SIZE, 4 * CELL_SIZE, CELL_SIZE, CELL_SIZE), stone_src)

	# 3. Draw Pond
	var water_src = Rect2(0, 32, 32, 32)
	for p_cell in pond_cells:
		draw_texture_rect_region(tiles_sheet, Rect2(p_cell.x * CELL_SIZE, p_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), water_src)

	# 4. Draw Farm Plots (Tilled / Watered soil & Crops)
	var tilled_dry_src = Rect2(4 * 32, 0, 32, 32)
	var tilled_wet_src = Rect2(5 * 32, 0, 32, 32)

	for coord in GameState.farm_data.keys():
		var tile = GameState.farm_data[coord]
		if tile.get("tilled", false):
			var src = tilled_wet_src if tile.get("watered", false) else tilled_dry_src
			draw_texture_rect_region(tiles_sheet, Rect2(coord.x * CELL_SIZE, coord.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), src)

			# Draw Crop
			var crop_id = tile.get("crop_id", "")
			if crop_id != "" and crops_sheet != null:
				var crop_row = 0
				if crop_id == "corn": crop_row = 1
				elif crop_id == "pumpkin": crop_row = 2
				elif crop_id == "frostberry": crop_row = 3
				
				var stage = clamp(tile.get("growth_stage", 0), 0, 3)
				var crop_src = Rect2(stage * 32, crop_row * 32, 32, 32)
				draw_texture_rect_region(crops_sheet, Rect2(coord.x * CELL_SIZE, coord.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), crop_src)

	# 5. Draw Shipping Bin
	var bin_src = Rect2(4 * 32, 32, 32, 32)
	draw_texture_rect_region(tiles_sheet, Rect2(shipping_bin_cell.x * CELL_SIZE, shipping_bin_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), bin_src)

	# 6. Draw Spirit Shrine
	var shrine_src = Rect2(6 * 32, 32, 32, 32)
	draw_texture_rect_region(tiles_sheet, Rect2(spirit_shrine_cell.x * CELL_SIZE, spirit_shrine_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), shrine_src)

	# 7. Draw Farm House
	var wood_floor_src = Rect2(6 * 32, 0, 32, 32)
	for hx in range(farm_house_rect.position.x, farm_house_rect.end.x):
		for hy in range(farm_house_rect.position.y, farm_house_rect.end.y):
			draw_texture_rect_region(tiles_sheet, Rect2(hx * CELL_SIZE, hy * CELL_SIZE, CELL_SIZE, CELL_SIZE), wood_floor_src)
	# Draw house label
	draw_string(ThemeDB.fallback_font, Vector2(farm_house_rect.position.x * CELL_SIZE + 10, farm_house_rect.position.y * CELL_SIZE + 48), "Çiftlik Evi", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.2, 0.1, 0.05))

	# 8. Draw Forage items on ground
	for pos in forage_spawns.keys():
		var f_id = forage_spawns[pos]
		var tex = GameState.get_item_texture(f_id)
		if tex != null:
			draw_texture_rect(tex, Rect2(pos.x * CELL_SIZE, pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE), false)
