extends Node2D

# ==============================================================================
# SPIRIT MEADOW - MAIN SCENE CONTROLLER (AMBIENCE & DAY/NIGHT)
# ==============================================================================

@onready var season_modulate: CanvasModulate = $SeasonModulate

func _ready() -> void:
	GameState.time_tick.connect(_on_time_tick)
	GameState.season_changed.connect(_on_season_changed)
	update_lighting()

func _on_time_tick(_hour: int, _minute: int) -> void:
	update_lighting()

func _on_season_changed(_season_name: String) -> void:
	update_lighting()

func update_lighting() -> void:
	if season_modulate == null:
		return

	var hour = GameState.current_hour + (GameState.current_minute / 60.0)
	var season_base = GameState.SEASON_COLORS[GameState.current_season]

	# Day/Night brightness factor
	var light_factor = 1.0
	if hour < 6.0 or hour >= 22.0:
		# Deep night
		light_factor = 0.45
	elif hour >= 6.0 and hour < 8.0:
		# Sunrise golden dawn
		light_factor = lerp(0.45, 1.0, (hour - 6.0) / 2.0)
	elif hour >= 18.0 and hour < 22.0:
		# Sunset to dusk
		light_factor = lerp(1.0, 0.45, (hour - 18.0) / 4.0)

	var final_color = Color(
		season_base.r * light_factor,
		season_base.g * light_factor,
		season_base.b * (light_factor * 0.95 + 0.05), # subtle blue moonlight tint at night
		1.0
	)

	season_modulate.color = final_color
