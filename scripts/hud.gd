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
var key_item: Node3D = null
var goal_zone: Node3D = null
var has_key: bool = false

var current_fps_limit_index: int = 0
var fps_limits: Array[int] = [0, 30, 60] # 0 = Ilimitado
var elapsed_time: float = 0.0
var is_game_active: bool = true

func _ready() -> void:
	victory_panel.visible = false
	_update_fps_limit_display()
	_find_player()
	_find_targets()

func _find_player() -> void:
	if not is_inside_tree():
		return
	
	# Buscar al jugador en el grupo 'player' de forma segura
	player = get_tree().get_first_node_in_group("player") as Player
	if not player and get_parent():
		player = get_parent().get_node_or_null("Player") as Player
				
	if is_instance_valid(player):
		if not player.state_changed.is_connected(_on_player_state_changed):
			player.state_changed.connect(_on_player_state_changed)
		_update_state_display(player.get_current_state_name())

func _find_targets() -> void:
	if not is_inside_tree():
		return
	if not is_instance_valid(key_item):
		key_item = get_tree().get_first_node_in_group("key_item")
		if not key_item and get_parent():
			key_item = get_parent().get_node_or_null("Interactables/KeyItem")
	if not is_instance_valid(goal_zone):
		goal_zone = get_tree().get_first_node_in_group("goal_zone")
		if not goal_zone and get_parent():
			goal_zone = get_parent().get_node_or_null("Interactables/GoalZone")

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
		
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	
	if is_game_active:
		elapsed_time += delta
		var minutes = int(elapsed_time) / 60
		var seconds = int(elapsed_time) % 60
		var millis = int((elapsed_time - int(elapsed_time)) * 10)
		run_timer_label.text = "Tiempo: %02d:%02d.%d" % [minutes, seconds, millis]
		_update_objective_guide()
	
	if not is_instance_valid(player):
		_find_player()
	
	if is_instance_valid(player):
		var horiz_vel = Vector2(player.velocity.x, player.velocity.z).length()
		velocity_label.text = "H: %.2f m/s | Y: %.2f" % [horiz_vel, player.velocity.y]

func _update_objective_guide() -> void:
	if not is_instance_valid(player):
		return
	
	if not has_key:
		if not is_instance_valid(key_item):
			_find_targets()
		if is_instance_valid(key_item):
			var to_key = key_item.global_position - player.global_position
			var dist = int(Vector2(to_key.x, to_key.z).length())
			var dir_str = _get_direction_arrow(to_key)
			if dist <= 4:
				objective_label.text = "Objetivo: ¡Llave de Acceso aquí! Tómala"
				objective_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35))
			else:
				objective_label.text = "Objetivo: Llave de Acceso (a %dm al %s)" % [dist, dir_str]
				objective_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.40))
		else:
			objective_label.text = "Objetivo: Sigue la columna de luz hacia la Llave"
	else:
		if not is_instance_valid(goal_zone):
			_find_targets()
		if is_instance_valid(goal_zone):
			var to_goal = goal_zone.global_position - player.global_position
			var dist = int(Vector2(to_goal.x, to_goal.z).length())
			var dir_str = _get_direction_arrow(to_goal)
			if dist <= 4:
				objective_label.text = "¡Llegaste a la Meta! Cruza el círculo para finalizar"
				objective_label.add_theme_color_override("font_color", Color(0.40, 0.85, 0.60))
			else:
				objective_label.text = "Compuerta abierta. Meta al Sur (a %dm al %s)" % [dist, dir_str]
				objective_label.add_theme_color_override("font_color", Color(0.35, 0.75, 0.55))

func _get_direction_arrow(diff: Vector3) -> String:
	# En Godot: +X = Este, -X = Oeste, +Z = Sur, -Z = Norte
	var angle = atan2(diff.x, -diff.z) # 0 = Norte, PI/2 = Este, PI = Sur, -PI/2 = Oeste
	var deg = rad_to_deg(angle)
	if deg < 0:
		deg += 360.0
	
	if deg >= 337.5 or deg < 22.5:
		return "Norte"
	elif deg >= 22.5 and deg < 67.5:
		return "Noreste"
	elif deg >= 67.5 and deg < 112.5:
		return "Este"
	elif deg >= 112.5 and deg < 157.5:
		return "Sureste"
	elif deg >= 157.5 and deg < 202.5:
		return "Sur"
	elif deg >= 202.5 and deg < 247.5:
		return "Suroeste"
	elif deg >= 247.5 and deg < 292.5:
		return "Oeste"
	else:
		return "Noroeste"

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
	has_key = true
	key_status_label.text = "[ OBTENIDA ]"
	key_status_label.add_theme_color_override("font_color", Color(0.35, 0.75, 0.55))
	objective_label.text = "OBJETIVO: ¡Compuerta abierta! Dirígete a la Zona de Salida."
	objective_label.add_theme_color_override("font_color", Color(0.35, 0.75, 0.55))

func show_victory() -> void:
	is_game_active = false
	victory_panel.visible = true
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	var millis = int((elapsed_time - int(elapsed_time)) * 100)
	victory_time_label.text = "Tiempo final de recorrido: %02d:%02d.%02d" % [minutes, seconds, millis]
