extends CanvasLayer

# ==============================================================================
# SPIRIT MEADOW - COZY HUD & INTERFACE CONTROLLER
# ==============================================================================

@onready var season_icon: TextureRect = $TopRightHUD/Panel/Margin/VBox/SeasonRow/Icon
@onready var season_label: Label = $TopRightHUD/Panel/Margin/VBox/SeasonRow/SeasonLabel
@onready var time_label: Label = $TopRightHUD/Panel/Margin/VBox/TimeLabel
@onready var money_label: Label = $TopRightHUD/Panel/Margin/VBox/MoneyRow/MoneyLabel
@onready var stamina_bar: ProgressBar = $TopRightHUD/Panel/Margin/VBox/StaminaRow/StaminaBar
@onready var stamina_label: Label = $TopRightHUD/Panel/Margin/VBox/StaminaRow/StaminaLabel

# Hotbar
@onready var hotbar_container: HBoxContainer = $BottomHUD/HotbarContainer
@onready var active_item_name: Label = $BottomHUD/ActiveItemName

# Notification Toast
@onready var toast_panel: PanelContainer = $ToastNotification
@onready var toast_label: Label = $ToastNotification/Margin/HBox/ToastLabel
@onready var toast_icon: TextureRect = $ToastNotification/Margin/HBox/ToastIcon

# Full Inventory Modal
@onready var inventory_panel: Control = $InventoryModal
@onready var inventory_grid: GridContainer = $InventoryModal/Panel/Margin/VBox/Scroll/Grid
@onready var tooltip_name: Label = $InventoryModal/Panel/Margin/VBox/TooltipBox/ItemName
@onready var tooltip_desc: Label = $InventoryModal/Panel/Margin/VBox/TooltipBox/ItemDesc
@onready var tooltip_info: Label = $InventoryModal/Panel/Margin/VBox/TooltipBox/ItemInfo
@onready var eat_button: Button = $InventoryModal/Panel/Margin/VBox/TooltipBox/Buttons/EatButton

var season_textures: Array = []
var toast_timer: float = 0.0
var selected_inventory_slot: int = -1

func _ready() -> void:
	# Load season icons
	var s_names = ["spring", "summer", "fall", "winter"]
	for s in s_names:
		var p = "res://assets/ui/icon_" + s + ".png"
		if ResourceLoader.exists(p):
			season_textures.append(load(p))

	# Connect signals
	GameState.time_tick.connect(_on_time_tick)
	GameState.day_passed.connect(_on_day_passed)
	GameState.season_changed.connect(_on_season_changed)
	GameState.inventory_updated.connect(_on_inventory_updated)
	GameState.money_changed.connect(_on_money_changed)
	GameState.stamina_changed.connect(_on_stamina_changed)
	GameState.show_notification.connect(_on_show_notification)

	toast_panel.visible = false
	inventory_panel.visible = false

	setup_hotbar_ui()
	setup_inventory_grid()
	update_all_displays()

func _process(delta: float) -> void:
	if toast_panel.visible:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_panel.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.keycode == KEY_I or event.keycode == KEY_TAB:
			toggle_inventory()
		elif event.keycode == KEY_Z:
			# Fast sleep / advance to next day!
			GameState.sleep_and_new_day("Yatağında mışıl mışıl uyudun!")
		elif event.keycode == KEY_M:
			# Fast switch season cheat/showcase for testing!
			cheat_next_season()

func cheat_next_season() -> void:
	GameState.current_season = (GameState.current_season + 1) % 4
	GameState.emit_signal("season_changed", GameState.SEASON_NAMES[GameState.current_season])
	GameState.emit_signal("show_notification", "Mevsim değişti: " + GameState.SEASON_NAMES[GameState.current_season], null)

func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	GameState.is_time_paused = inventory_panel.visible
	GameState.play_sfx("click")
	if inventory_panel.visible:
		refresh_inventory_grid()

func update_all_displays() -> void:
	_on_time_tick(GameState.current_hour, GameState.current_minute)
	_on_day_passed(GameState.current_day, GameState.current_season, GameState.current_year)
	_on_money_changed(GameState.money)
	_on_stamina_changed(GameState.stamina, GameState.max_stamina)
	_on_inventory_updated()

func _on_time_tick(hour: int, minute: int) -> void:
	time_label.text = "%02d:%02d" % [hour, minute]

func _on_day_passed(day: int, season_index: int, _year: int) -> void:
	var s_name = GameState.SEASON_NAMES[season_index]
	season_label.text = "%s, %d. Gün" % [s_name, day]
	if season_index < season_textures.size() and season_textures[season_index] != null:
		season_icon.texture = season_textures[season_index]

func _on_season_changed(season_name: String) -> void:
	season_label.text = "%s, %d. Gün" % [season_name, GameState.current_day]
	var s_idx = GameState.current_season
	if s_idx < season_textures.size() and season_textures[s_idx] != null:
		season_icon.texture = season_textures[s_idx]

func _on_money_changed(amount: int) -> void:
	money_label.text = "%d Altın" % amount

func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	stamina_label.text = "%d / %d" % [int(current), int(maximum)]

func _on_show_notification(text: String, icon_tex: Texture2D) -> void:
	toast_label.text = text
	if icon_tex != null:
		toast_icon.texture = icon_tex
		toast_icon.visible = true
	else:
		toast_icon.visible = false

	toast_panel.visible = true
	toast_timer = 3.0

# ==============================================================================
# HOTBAR LOGIC
# ==============================================================================
func setup_hotbar_ui() -> void:
	for child in hotbar_container.get_children():
		child.queue_free()

	for i in range(10):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(40, 40)
		slot_btn.name = "Slot_%d" % i
		slot_btn.pressed.connect(_on_hotbar_slot_clicked.bind(i))

		var item_tex = TextureRect.new()
		item_tex.name = "Icon"
		item_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_tex.custom_minimum_size = Vector2(28, 28)
		item_tex.position = Vector2(6, 6)
		slot_btn.add_child(item_tex)

		var count_lbl = Label.new()
		count_lbl.name = "Count"
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_lbl.position = Vector2(0, 18)
		count_lbl.size = Vector2(36, 20)
		count_lbl.add_theme_font_size_override("font_size", 11)
		slot_btn.add_child(count_lbl)

		hotbar_container.add_child(slot_btn)

func _on_hotbar_slot_clicked(slot_idx: int) -> void:
	GameState.selected_hotbar_slot = slot_idx
	_on_inventory_updated()
	GameState.play_sfx("click")

func _on_inventory_updated() -> void:
	# Update Hotbar
	for i in range(10):
		var btn = hotbar_container.get_node_or_null("Slot_%d" % i) as Button
		if btn == null:
			continue

		var icon = btn.get_node("Icon") as TextureRect
		var count = btn.get_node("Count") as Label

		# Highlight active slot
		if i == GameState.selected_hotbar_slot:
			btn.modulate = Color(1.3, 1.2, 0.7)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

		var item_slot = GameState.inventory[i]
		if item_slot != null:
			var item_id = item_slot["id"]
			icon.texture = GameState.get_item_texture(item_id)
			count.text = str(item_slot["count"]) if item_slot["count"] > 1 else ""
		else:
			icon.texture = null
			count.text = ""

	# Update active item name
	var active_slot = GameState.inventory[GameState.selected_hotbar_slot]
	if active_slot != null:
		var item_data = GameState.items_db.get(active_slot["id"], {})
		active_item_name.text = item_data.get("name", "")
	else:
		active_item_name.text = "(Boş El)"

	if inventory_panel.visible:
		refresh_inventory_grid()

# ==============================================================================
# FULL BACKPACK INVENTORY MODAL
# ==============================================================================
func setup_inventory_grid() -> void:
	for child in inventory_grid.get_children():
		child.queue_free()

	for i in range(30):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(40, 40)
		slot_btn.pressed.connect(_on_inventory_item_selected.bind(i))

		var item_tex = TextureRect.new()
		item_tex.name = "Icon"
		item_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_tex.custom_minimum_size = Vector2(28, 28)
		item_tex.position = Vector2(6, 6)
		slot_btn.add_child(item_tex)

		var count_lbl = Label.new()
		count_lbl.name = "Count"
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_lbl.position = Vector2(0, 18)
		count_lbl.size = Vector2(36, 20)
		count_lbl.add_theme_font_size_override("font_size", 11)
		slot_btn.add_child(count_lbl)

		inventory_grid.add_child(slot_btn)

	eat_button.pressed.connect(_on_eat_pressed)

func refresh_inventory_grid() -> void:
	for i in range(30):
		var btn = inventory_grid.get_child(i) as Button
		if btn == null:
			continue
		var icon = btn.get_node("Icon") as TextureRect
		var count = btn.get_node("Count") as Label

		var item_slot = GameState.inventory[i]
		if item_slot != null:
			icon.texture = GameState.get_item_texture(item_slot["id"])
			count.text = str(item_slot["count"]) if item_slot["count"] > 1 else ""
		else:
			icon.texture = null
			count.text = ""

		if i == selected_inventory_slot:
			btn.modulate = Color(1.3, 1.2, 0.6)
		else:
			btn.modulate = Color(1, 1, 1)

func _on_inventory_item_selected(slot_idx: int) -> void:
	selected_inventory_slot = slot_idx
	refresh_inventory_grid()
	GameState.play_sfx("click")

	var item_slot = GameState.inventory[slot_idx]
	if item_slot == null:
		tooltip_name.text = "Boş Yuva"
		tooltip_desc.text = "Bu bölmede herhangi bir eşya yok."
		tooltip_info.text = ""
		eat_button.visible = false
		return

	var item_id = item_slot["id"]
	var data = GameState.items_db.get(item_id, {})

	tooltip_name.text = data.get("name", "Bilinmeyen")
	tooltip_desc.text = data.get("desc", "")

	var info_str = "Satış Değeri: %d Altın" % data.get("sell", 0)
	if data.has("stamina"):
		info_str += " | Enerji: +%d" % data["stamina"]
		eat_button.visible = true
		eat_button.text = "Tüket (+%d Enerji)" % data["stamina"]
	else:
		eat_button.visible = false

	tooltip_info.text = info_str

func _on_eat_pressed() -> void:
	if selected_inventory_slot < 0 or selected_inventory_slot >= GameState.inventory.size():
		return
	var item_slot = GameState.inventory[selected_inventory_slot]
	if item_slot == null:
		return

	var data = GameState.items_db.get(item_slot["id"], {})
	if data.has("stamina"):
		GameState.restore_stamina(data["stamina"])
		GameState.play_sfx("harvest")
		GameState.emit_signal("show_notification", "%s yedin! +%d Enerji" % [data["name"], data["stamina"]], null)
		GameState.remove_item(selected_inventory_slot, 1)
		_on_inventory_item_selected(selected_inventory_slot)

func _on_close_inventory_pressed() -> void:
	toggle_inventory()

func _on_sleep_btn_pressed() -> void:
	GameState.sleep_and_new_day("Yatağında güzel bir uyku çektin!")
