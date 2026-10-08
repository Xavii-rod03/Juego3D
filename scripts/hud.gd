extends CanvasLayer

@onready var state_label: Label = %StateValue
@onready var fps_label: Label = %FPSValue
@onready var velocity_label: Label = %VelValue
@onready var fps_limit_label: Label = %LimitValue

var player: Player = null
var current_fps_limit_index: int = 0
var fps_limits: Array[int] = [0, 30, 60] # 0 = Ilimitado


func _ready() -> void:
	# Buscar al jugador en el árbol
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Si no está en grupo, buscar por clase
		for node in get_tree().root.find_children("*", "CharacterBody3D", true, false):
			if node is Player:
				player = node
				break
				
	if player:
		player.state_changed.connect(_on_player_state_changed)
		_update_state_display(player.get_current_state_name())
	
	_update_fps_limit_display()


func _process(_delta: float) -> void:
	# Actualizar FPS
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	
	# Actualizar velocidad
	if player:
		var horiz_vel = Vector2(player.velocity.x, player.velocity.z).length()
		velocity_label.text = "H: %.2f m/s | Y: %.2f" % [horiz_vel, player.velocity.y]


func _unhandled_input(event: InputEvent) -> void:
	# Cambiar límite de FPS con F1 para realizar la prueba de aceptación 3
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			current_fps_limit_index = (current_fps_limit_index + 1) % fps_limits.size()
			var target_fps = fps_limits[current_fps_limit_index]
			Engine.max_fps = target_fps
			_update_fps_limit_display()
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()


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
		fps_limit_label.text = "%d FPS (Presiona F1 para alternar)" % limit
