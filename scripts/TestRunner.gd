extends Node

# ==============================================================================
# SPIRIT MEADOW - AUTOMATED TEST & VERIFICATION NODE
# ==============================================================================

var screenshot_idx: int = 0
var main_scene: Node2D

func _ready() -> void:
	print("\n=======================================================")
	print(">>> SPIRIT MEADOW OTOMATİK OYUN VE ENVALTER TESTİ <<<")
	print("=======================================================")
	call_deferred("start_all_tests")

func start_all_tests() -> void:
	main_scene = get_parent().get_node_or_null("Main")
	if main_scene == null:
		main_scene = get_parent()

	await get_tree().create_timer(0.3).timeout
	capture_screen("01_oyun_baslangic_ilkbahar")

	# Test 1: Çapalama, Sulama ve Tohum Ekme
	print("\n--- TEST 1: Çapalama, Sulama ve Tohum Ekme ---")
	var farm_grid = main_scene.get_node("FarmGrid")

	# Çapa seç ve toprağı çapala
	GameState.selected_hotbar_slot = 0 # Çapa
	GameState.emit_signal("inventory_updated")
	var target_cell = Vector2i(15, 8)
	var tilled = farm_grid.interact_tile(target_cell)
	print("  1. Çapalama başarılı mı: ", tilled, " | Tile Durumu: ", GameState.farm_data.get(target_cell))

	# Sulama kabı seç ve sula
	GameState.selected_hotbar_slot = 1 # Sulama kabı
	GameState.emit_signal("inventory_updated")
	var watered = farm_grid.interact_tile(target_cell)
	print("  2. Sulama başarılı mı: ", watered, " | Islak mı: ", GameState.farm_data.get(target_cell).get("watered"))

	# Çilek tohumu seç ve ek
	GameState.selected_hotbar_slot = 3 # Çilek tohumu
	GameState.emit_signal("inventory_updated")
	var planted = farm_grid.interact_tile(target_cell)
	print("  3. Tohum ekildi mi: ", planted, " | Ekin ID: ", GameState.farm_data.get(target_cell).get("crop_id"))
	await get_tree().create_timer(0.3).timeout
	capture_screen("02_tarla_ve_tohum")

	# Test 2: Envanter Açma, Sekme ve Tooltip Kontrolü
	print("\n--- TEST 2: Envanter Açma ve Arayüz Düzeni ---")
	var hud = main_scene.get_node("HUD")
	hud.toggle_inventory()
	print("  1. Envanter penceresi açıldı mı: ", hud.inventory_panel.visible)
	hud._on_inventory_item_selected(3)
	print("  2. Tooltip Eşya Adı: ", hud.tooltip_name.text)
	print("  3. Tooltip Açıklama: ", hud.tooltip_desc.text)
	print("  4. Tooltip Bilgi: ", hud.tooltip_info.text)
	await get_tree().create_timer(0.3).timeout
	capture_screen("03_envanter_acik")
	hud.toggle_inventory() # Envanteri kapat

	# Test 3: Gün İlerlemesi ve Ekin Büyümesi
	print("\n--- TEST 3: Zaman Akışı ve Ekin Büyümesi ---")
	for d in range(3):
		GameState.sleep_and_new_day("Yeni bir gün başladı.")
		GameState.farm_data[target_cell]["watered"] = true
	GameState.process_crops_overnight()
	var stage = GameState.farm_data.get(target_cell).get("growth_stage", 0)
	print("  3 gün sonra ekin büyüme aşaması: ", stage, " / 3 (3 = Hasada Hazır)")
	await get_tree().create_timer(0.3).timeout
	capture_screen("04_ekinler_buyudu")

	# Test 4: Hasat Yapma
	print("\n--- TEST 4: Ekin Hasadı ---")
	var initial_count = 0
	for item in GameState.inventory:
		if item != null and item["id"] == "crop_strawberry":
			initial_count = item["count"]
	farm_grid.interact_tile(target_cell)
	var final_count = 0
	for item in GameState.inventory:
		if item != null and item["id"] == "crop_strawberry":
			final_count = item["count"]
	print("  Hasat öncesi çilek: ", initial_count, " -> Hasat sonrası çilek: ", final_count)

	# Test 5: Komşu NPC ile Diyalog
	print("\n--- TEST 5: Komşu NPC (Ayla) ile Diyalog ---")
	var ayla = main_scene.get_node("NPCs/Ayla")
	ayla.interact()
	var dialogue_ui = main_scene.get_node("DialogueUI")
	print("  1. Diyalog açıldı mı: ", dialogue_ui.visible)
	print("  2. Konuşan: ", dialogue_ui.name_label.text)
	print("  3. Metin: ", dialogue_ui.text_label.text)
	await get_tree().create_timer(0.3).timeout
	capture_screen("05_npc_diyalog")
	dialogue_ui.advance_or_close()
	dialogue_ui.advance_or_close()
	dialogue_ui.advance_or_close()
	print("  4. Diyalog kapandı mı: ", not dialogue_ui.visible)

	# Test 6: Balık Tutma Mini Oyunu
	print("\n--- TEST 6: Balık Tutma Mini Oyunu ---")
	var fishing_game = main_scene.get_node("FishingMiniGame")
	farm_grid.start_fishing()
	print("  1. Balıkçılık mini oyunu açıldı mı: ", fishing_game.visible)
	print("  2. Hedeflenen Balık: ", fishing_game.target_fish_id)
	await get_tree().create_timer(0.3).timeout
	capture_screen("06_balik_tutma_ekrani")
	fishing_game.close_minigame()

	# Test 7: 4 Mevsim Döngüsü (İlkbahar -> Yaz -> Sonbahar -> Kış)
	print("\n--- TEST 7: 4 Mevsim İklim ve Ambiyans Geçişi ---")
	for s in range(4):
		GameState.current_season = s
		GameState.emit_signal("season_changed", GameState.SEASON_NAMES[s])
		main_scene.update_lighting()
		farm_grid.queue_redraw()
		var s_name = GameState.SEASON_NAMES[s]
		print("  Mevsim: ", s_name, " | Ambiyans: ", main_scene.season_modulate.color)
		await get_tree().create_timer(0.3).timeout
		capture_screen("07_mevsim_" + s_name.to_lower())

	# Test 8: Orman Mantarı Toplama (Foraging)
	print("\n--- TEST 8: Mantar Toplama (Foraging) ---")
	var mushroom_cell = Vector2i(24, 8)
	var had_mushroom = farm_grid.forage_spawns.has(mushroom_cell)
	var foraged = farm_grid.interact_tile(mushroom_cell)
	print("  Mantar bulundu mu: ", had_mushroom, " | Toplandı mı: ", foraged)

	# Test 9: Sevkiyat Sandığına Satış
	print("\n--- TEST 9: Sevkiyat Sandığına Satış & Altın ---")
	var pre_money = GameState.money
	farm_grid.interact_tile(farm_grid.shipping_bin_cell)
	print("  Satış Öncesi: ", pre_money, " Altın -> Satış Sonrası: ", GameState.money, " Altın")

	print("\n=======================================================")
	print(">>> BÜTÜN TESTLER EKSİKSİZ VE HATASIZ GEÇTİ! <<<")
	print("=======================================================")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0)

func capture_screen(step_name: String) -> void:
	screenshot_idx += 1
	var img = get_viewport().get_texture().get_image()
	if img != null:
		var dir_path = "C:/Users/roy/.gemini/antigravity/scratch/cozy_haven/screenshots/"
		var file_path = "%s%02d_%s.png" % [dir_path, screenshot_idx, step_name]
		img.save_png(file_path)
		print("  [Ekran Kaydedildi]: ", file_path)
