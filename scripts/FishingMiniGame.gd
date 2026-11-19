extends Control

# ==============================================================================
# SPIRIT MEADOW - BALIK TUTMA MİNİ OYUNU
# ==============================================================================

@onready var game_panel: Panel = $CenterContainer/Panel
@onready var water_track: ColorRect = $CenterContainer/Panel/Track
@onready var catch_bar: ColorRect = $CenterContainer/Panel/Track/CatchBar
@onready var fish_icon: TextureRect = $CenterContainer/Panel/Track/FishIcon
@onready var progress_bar: ProgressBar = $CenterContainer/Panel/CatchProgress
@onready var info_label: Label = $CenterContainer/Panel/InfoLabel
@onready var status_label: Label = $CenterContainer/Panel/StatusLabel

const TRACK_HEIGHT = 200.0
const BAR_HEIGHT = 50.0

var is_fishing: bool = false
var target_fish_id: String = "fish_trout"

var bar_y: float = 100.0
var bar_velocity: float = 0.0
var fish_y: float = 100.0
var fish_target_y: float = 100.0
var fish_move_timer: float = 0.0

var catch_progress: float = 30.0 # 0 to 100

func _ready() -> void:
	visible = false
	GameState.open_fishing_minigame.connect(start_minigame)

func start_minigame(fish_id: String) -> void:
	target_fish_id = fish_id
	var fish_data = GameState.items_db.get(fish_id, {})
	var fish_name = fish_data.get("name", "Bilinmeyen Balık")

	info_label.text = "Oltaya bir %s takıldı! [Basılı Tut: Çek]" % fish_name
	status_label.text = "Yeşil çubuğu balığın üzerinde tut!"
	status_label.modulate = Color(1, 1, 0.6)

	fish_icon.texture = GameState.get_item_texture(fish_id)

	bar_y = 100.0
	bar_velocity = 0.0
	fish_y = 100.0
	fish_target_y = 100.0
	catch_progress = 35.0
	progress_bar.value = catch_progress

	is_fishing = true
	visible = true
	GameState.is_time_paused = true
	GameState.play_sfx("bite")

func _process(delta: float) -> void:
	if not is_fishing:
		return

	# Handle Player Bar Physics
	var pulling = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept")
	if pulling:
		bar_velocity -= 450.0 * delta # Pull UP (towards 0)
	else:
		bar_velocity += 350.0 * delta # Gravity DOWN

	bar_velocity = clamp(bar_velocity, -350.0, 350.0)
	bar_y += bar_velocity * delta
	bar_y = clamp(bar_y, 0.0, TRACK_HEIGHT - BAR_HEIGHT)
	catch_bar.position.y = bar_y

	# Handle Fish AI (wanders smoothly up and down)
	fish_move_timer -= delta
	if fish_move_timer <= 0.0:
		fish_move_timer = randf_range(0.6, 1.4)
		fish_target_y = randf_range(10.0, TRACK_HEIGHT - 24.0)

	fish_y = move_toward(fish_y, fish_target_y, delta * 90.0)
	fish_icon.position.y = fish_y

	# Check Collision: Is fish inside the catch bar?
	var fish_center = fish_y + 12.0
	var bar_top = bar_y
	var bar_bottom = bar_y + BAR_HEIGHT

	var is_inside = fish_center >= bar_top and fish_center <= bar_bottom

	if is_inside:
		catch_progress += delta * 32.0 # Filling meter
		catch_bar.color = Color(0.2, 0.85, 0.3, 0.8)
		status_label.text = "Harika gidiyorsun! Çekmeye devam et!"
		status_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		catch_progress -= delta * 20.0 # Dropping meter
		catch_bar.color = Color(0.9, 0.3, 0.3, 0.8)
		status_label.text = "Balık kaçıyor! Yeşil çubuğu balığa hizala!"
		status_label.modulate = Color(1.0, 0.4, 0.4)

	catch_progress = clamp(catch_progress, 0.0, 100.0)
	progress_bar.value = catch_progress

	# Check Win / Lose
	if catch_progress >= 100.0:
		win_fishing()
	elif catch_progress <= 0.0:
		lose_fishing()

func win_fishing() -> void:
	is_fishing = false
	GameState.play_sfx("catch")
	GameState.add_item(target_fish_id, 1)
	status_label.text = "TEBRİKLER! Balığı başarıyla yakaladın!"
	status_label.modulate = Color(0.3, 1.0, 0.3)
	await get_tree().create_timer(1.2).timeout
	close_minigame()

func lose_fishing() -> void:
	is_fishing = false
	GameState.play_sfx("click")
	status_label.text = "Balık misinayı koparıp kaçtı..."
	status_label.modulate = Color(0.9, 0.3, 0.3)
	await get_tree().create_timer(1.2).timeout
	close_minigame()

func close_minigame() -> void:
	visible = false
	GameState.is_time_paused = false

func _on_cancel_button_pressed() -> void:
	close_minigame()
