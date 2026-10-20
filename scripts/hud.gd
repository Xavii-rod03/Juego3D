extends CanvasLayer
class_name HUD

@onready var state_label: Label = %StateValue
@onready var fps_label: Label = %FPSValue
@onready var velocity_label: Label = %VelValue
@onready var fps_limit_label: Label = %LimitValue
@onready var objective_label: Label = %ObjectiveLabel
@onready var key_status_label: Label = %KeyStatusLabel
@onready var run_timer_label: Label = %RunTimerLabel
@onready var victory_panel: PanelContainer = %VictoryPanel
@onready var victory_time_label: Label = %VictoryTimeLabel

var player: Player = null
var current_fps_limit_index: int = 0
var fps_limits: Array[int] = [0, 30, 60] # 0 = Ilimitado
var elapsed_time: float = 0.0
var is_game_active: bool = true

func _ready() -> void:
	victory_panel.visible = false
	_update_fps_limit_display()
	
	# Buscar al jugador en el árbol
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		for node in get_tree().root.find_children("*", "CharacterBody3D", true, false):
			if node is Player:
				player = node
				break
				
	if player:
		player.state_changed.connect(_on_player_state_changed)
		_update_state_display(player.get_current_state_name())

func _process(delta: float) -> void:
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	
	if is_game_active:
		elapsed_time += delta
		var minutes = int(elapsed_time) / 60
		var seconds = int(elapsed_time) % 60
		var millis = int((elapsed_time - int(elapsed_time)) * 10)
		run_timer_label.text = "Tiempo: %02d:%02d.%d" % [minutes, seconds, millis]
	
	if player:
		var horiz_vel = Vector2(player.velocity.x, player.velocity.z).length()
		velocity_label.text = "H: %.2f m/s | Y: %.2f" % [horiz_vel, player.velocity.y]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			current_fps_limit_index = (current_fps_limit_index + 1) % fps_limits.size()
			var target_fps = fps_limits[current_fps_limit_index]
			Engine.max_fps = target_fps
			_update_fps_limit_display()
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()
		elif event.keycode == KEY_B or event.keycode == KEY_F2:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/benchmark/benchmark_main.tscn")

func _on_player_state_changed(_old_state: String, new_state: String) -> void:
	_update_state_display(new_state)

func _update_state_display(state_name: String) -> void:
	state_label.text = state_name
	match state_name:
		"IDLE":
			state_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		"WALK":
			state_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
		"JUMP":
			state_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))

func _update_fps_limit_display() -> void:
	var limit = fps_limits[current_fps_limit_index]
	if limit == 0:
		fps_limit_label.text = "Sin límite (Ilimitado)"
	else:
		fps_limit_label.text = "%d FPS" % limit

func set_key_collected() -> void:
	key_status_label.text = "[ ✅ OBTENIDA ]"
	key_status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	objective_label.text = "OBJETIVO: ¡Compuerta abierta! Dirígete a la Zona de Salida."
	objective_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))

func show_victory() -> void:
	is_game_active = false
	victory_panel.visible = true
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	var millis = int((elapsed_time - int(elapsed_time)) * 100)
	victory_time_label.text = "Tiempo final de recorrido: %02d:%02d.%02d" % [minutes, seconds, millis]
