extends CharacterBody2D

# ==============================================================================
# SPIRIT MEADOW - PLAYER CONTROLLER
# ==============================================================================

const SPEED = 140.0
const CELL_SIZE = 32

var player_sheet: Texture2D
var facing_dir: Vector2 = Vector2.DOWN
var anim_frame: int = 0
var anim_timer: float = 0.0
var is_acting: bool = false
var act_timer: float = 0.0

@onready var farm_grid: Node2D = get_parent().get_node_or_null("FarmGrid")

func _ready() -> void:
	if ResourceLoader.exists("res://assets/sprites/player.png"):
		player_sheet = load("res://assets/sprites/player.png")
	position = Vector2(11 * CELL_SIZE + 16, 6 * CELL_SIZE + 16)

func _process(delta: float) -> void:
	if is_acting:
		act_timer -= delta
		if act_timer <= 0:
			is_acting = false
		queue_redraw()
		return

	# Movement
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1.0

	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		velocity = input_vector * SPEED
		facing_dir = input_vector
		anim_timer += delta * 8.0
		if anim_timer >= 1.0:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 4
			GameState.play_sfx("step")
	else:
		velocity = Vector2.ZERO
		anim_frame = 0

	move_and_slide()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			GameState.selected_hotbar_slot = event.keycode - KEY_1
			GameState.emit_signal("inventory_updated")
			GameState.play_sfx("click")
		elif event.keycode == KEY_0:
			GameState.selected_hotbar_slot = 9
			GameState.emit_signal("inventory_updated")
			GameState.play_sfx("click")
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			perform_action()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Only perform action if click is in game world (not on UI)
		perform_action()

func get_facing_grid_cell() -> Vector2i:
	var forward_pos = position + facing_dir * 28.0
	return Vector2i(int(forward_pos.x / CELL_SIZE), int(forward_pos.y / CELL_SIZE))

func perform_action() -> void:
	if is_acting:
		return

	var target_cell = get_facing_grid_cell()

	# Check NPC interaction first
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.position.distance_to(position) < 48.0:
			npc.interact()
			return

	if farm_grid != null:
		var acted = farm_grid.interact_tile(target_cell)
		if acted:
			is_acting = true
			act_timer = 0.2

func _draw() -> void:
	if player_sheet == null:
		return

	# Draw target cell selector indicator box on ground
	var target_cell = get_facing_grid_cell()
	var target_screen_pos = to_local(Vector2(target_cell.x * CELL_SIZE, target_cell.y * CELL_SIZE))
	draw_rect(Rect2(target_screen_pos.x, target_screen_pos.y, CELL_SIZE, CELL_SIZE), Color(1, 1, 1, 0.35), false, 2.0)

	# Determine row based on facing direction
	var row = 0 # Down
	if abs(facing_dir.x) > abs(facing_dir.y):
		row = 3 if facing_dir.x > 0 else 2 # Right or Left
	else:
		row = 0 if facing_dir.y > 0 else 1 # Down or Up

	var col = anim_frame
	if is_acting:
		col = 3 # Tool action frame

	var src_rect = Rect2(col * 32, row * 32, 32, 32)
	draw_texture_rect_region(player_sheet, Rect2(-16, -16, 32, 32), src_rect)
