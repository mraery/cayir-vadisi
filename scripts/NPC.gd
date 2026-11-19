extends CharacterBody2D

# ==============================================================================
# SPIRIT MEADOW - COZY NPC SYSTEM
# ==============================================================================

@export var npc_id: String = "ayla"
@export var npc_name: String = "Ayla (Bitkibilimci)"
@export var sprite_col: int = 0
@export var favorite_item: String = "crop_strawberry"

var npcs_sheet: Texture2D
var portrait_tex: Texture2D
var friendship_hearts: int = 1

func _ready() -> void:
	add_to_group("npcs")
	if ResourceLoader.exists("res://assets/sprites/npcs.png"):
		npcs_sheet = load("res://assets/sprites/npcs.png")
	var p_path = "res://assets/ui/portrait_" + npc_id + ".png"
	if ResourceLoader.exists(p_path):
		portrait_tex = load(p_path)

func interact() -> void:
	GameState.play_sfx("blip")
	var texts = get_dialogue_texts()
	GameState.emit_signal("start_dialogue", npc_name, portrait_tex, texts)

func get_dialogue_texts() -> Array:
	var season_name = GameState.SEASON_NAMES[GameState.current_season]
	
	if npc_id == "ayla":
		return [
			"Merhaba komşum! Çiftliğe yerleştiğin için o kadar mutluyum ki!",
			"Şu an %s mevsimindeyiz. Toprağı çapalamayı ve her gün düzenli sulamayı unutma." % season_name,
			"Eğer bana tatlı çilek veya kırmızı orman mantarı getirirsen çok sevinirim!"
		]
	elif npc_id == "bram":
		return [
			"Hey genç dostum! Deniz ve nehir bugün çok sakin görünüyor.",
			"Oltanı hazırla ve göletin kenarına geç. Akşam saatlerinde nadir Ay Müreni yakalayabilirsin!",
			"Sevkiyat sandığına koyduğun balıkları her gün satıp iyi altın kazanabilirsin."
		]
	elif npc_id == "pip":
		return [
			"*Pırıl pırıl parıldar ve minik yapraklarını sallar!*",
			"Ben bu vadinin ruhuyum... Çiftliğindeki ekinleri sevgiyle büyütürsen sana Ruh Özü bırakırım.",
			"Mabede Ruh Özü sunduğunda tüm tarlana bereket yağdırabilirim!"
		]

	return ["Selamlar! Vadide hayat çok huzurlu."]

func _draw() -> void:
	if npcs_sheet == null:
		return
	# Draw NPC sprite from sheet (col * 32, 0, 32, 32)
	var src = Rect2(sprite_col * 32, 0, 32, 32)
	draw_texture_rect_region(npcs_sheet, Rect2(-16, -16, 32, 32), src)

	# Draw small name tag above NPC
	var name_text = npc_name.split(" ")[0]
	draw_string(ThemeDB.fallback_font, Vector2(-20, -22), name_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(1, 1, 1, 0.9))
