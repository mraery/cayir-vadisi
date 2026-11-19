extends Control

# ==============================================================================
# SPIRIT MEADOW - COZY DIALOGUE SYSTEM (NO TEXT OVERLAPPING GUARANTEED)
# ==============================================================================

@onready var panel: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/Margin/HBox/Portrait
@onready var name_label: Label = $PanelContainer/Margin/HBox/ContentVBox/NameLabel
@onready var text_label: Label = $PanelContainer/Margin/HBox/ContentVBox/TextLabel
@onready var next_hint: Label = $PanelContainer/Margin/HBox/ContentVBox/BottomRow/NextHint
@onready var gift_btn: Button = $PanelContainer/Margin/HBox/ContentVBox/BottomRow/GiftButton

var current_texts: Array = []
var text_index: int = 0
var active_npc_name: String = ""

func _ready() -> void:
	visible = false
	GameState.start_dialogue.connect(open_dialogue)
	if gift_btn:
		gift_btn.pressed.connect(_on_gift_pressed)

func open_dialogue(npc_name: String, portrait_tex: Texture2D, texts: Array) -> void:
	if texts.is_empty():
		return

	active_npc_name = npc_name
	current_texts = texts
	text_index = 0
	visible = true
	GameState.is_time_paused = true

	name_label.text = npc_name
	if portrait_tex != null:
		portrait_rect.texture = portrait_tex
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false

	show_current_page()

func show_current_page() -> void:
	text_label.text = current_texts[text_index]
	next_hint.text = "Sonraki >> (Tıkla / Boşluk)" if text_index < current_texts.size() - 1 else "Kapat [X]"
	GameState.play_sfx("blip")

func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_or_close()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_just_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		advance_or_close()
		get_viewport().set_input_as_handled()

func advance_or_close() -> void:
	text_index += 1
	if text_index < current_texts.size():
		show_current_page()
	else:
		close_dialogue()

func close_dialogue() -> void:
	visible = false
	GameState.is_time_paused = false
	GameState.play_sfx("click")

func _on_gift_pressed() -> void:
	var equipped = GameState.inventory[GameState.selected_hotbar_slot]
	if equipped != null and equipped.get("id", "") != "":
		var item_id = equipped["id"]
		var item_name = GameState.items_db[item_id]["name"]
		GameState.remove_item(GameState.selected_hotbar_slot, 1)
		GameState.play_sfx("harvest")
		text_label.text = "%s hediyeni çok beğendi! 'Teşekkür ederim, bu harika bir %s!'" % [active_npc_name.split(" ")[0], item_name]
		next_hint.text = "Kapat [X]"
		text_index = current_texts.size() # Close on next click
	else:
		GameState.emit_signal("show_notification", "Hediye etmek için hotbar'ında bir eşya seçmelisin!", null)
