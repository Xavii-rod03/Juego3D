extends CharacterBody3D
class_name Player

## Estados de la Máquina de Estados Finitos (FSM)
enum State {
	IDLE,
	WALK,
	JUMP
}

# --- Señales ---
signal state_changed(old_state_name: String, new_state_name: String)

# --- Constantes y Parámetros de Movimiento ---
@export_group("Movimiento y Física")
@export var speed: float = 6.0
@export var jump_velocity: float = 5.5
@export var acceleration: float = 12.0
@export var friction: float = 14.0
@export var rotation_speed: float = 12.0

@export_group("Cámara")
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -75.0
@export var max_pitch: float = 50.0

# --- Referencias a Nodos ---
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual_wrapper: Node3D = $VisualWrapper
@onready var anim_player: AnimationPlayer = $VisualWrapper/CharacterModel/AnimationPlayer

# --- Gravedad del motor ---
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# --- Variables de Estado ---
var current_state: State = State.IDLE
var target_rotation_y: float = 0.0
var input_dir: Vector2 = Vector2.ZERO
var move_direction: Vector3 = Vector3.ZERO


func _ready() -> void:
	# Asegurar configuración de acciones de entrada si no existen en project.godot
	_setup_fallback_inputs()
	
	# Capturar el cursor para control de cámara estilo tercera persona
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Inicializar rotación del modelo
	if visual_wrapper:
		target_rotation_y = visual_wrapper.rotation.y
		
	# Emitir estado inicial y reproducir animación Idle
	emit_signal("state_changed", "", State.keys()[current_state])
	_play_state_animation(State.IDLE)
	print("[FSM] Estado inicial: %s" % State.keys()[current_state])


func _unhandled_input(event: InputEvent) -> void:
	# Alternar captura del ratón con ESC o UI Cancel
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	# Control de cámara con mouse cuando está capturado
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		# Rotación horizontal (Yaw) en el pivote
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotación vertical (Pitch) en el pivote, restringida
		var pitch_change = -event.relative.y * mouse_sensitivity
		var current_pitch = camera_pivot.rotation_degrees.x
		var new_pitch = clamp(current_pitch + rad_to_deg(pitch_change), min_pitch, max_pitch)
		camera_pivot.rotation_degrees.x = new_pitch


## =============================================================================
## PASO 1: FÍSICA (_physics_process)
## -----------------------------------------------------------------------------
## EXPLICACIÓN DE USO DE 'DELTA' Y PREVENCIÓN DEL DOBLE TIEMPO:
## 1. Gravedad: velocity.y -= gravity * delta (aceleración m/s^2 a velocidad m/s).
## 2. Inercia / Fricción: move_toward() escalado con delta para consistencia de framerate.
## 3. move_and_slide(): En Godot 4.x toma directamente velocity e integra internamente
##    el delta de física (dx = v * dt). ¡NO se debe multiplicar velocity por delta
##    al llamar a move_and_slide()! Hacerlo aplicaría el tiempo dos veces.
## =============================================================================
func _physics_process(delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var cam_transform = camera_pivot.global_transform
	var forward = -cam_transform.basis.z
	var right = cam_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	
	move_direction = (right * input_dir.x + forward * -input_dir.y).normalized()
	
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			_transition_to(State.JUMP)
	
	# Aceleración horizontal e inercia / fricción
	var target_vel_x = move_direction.x * speed
	var target_vel_z = move_direction.z * speed
	
	var accel_factor = acceleration if move_direction.length_squared() > 0.001 else friction
	velocity.x = move_toward(velocity.x, target_vel_x, accel_factor * speed * delta)
	velocity.z = move_toward(velocity.z, target_vel_z, accel_factor * speed * delta)
	
	# Ejecutar físicas y colisiones
	move_and_slide()
	
	# Actualización y transiciones de la FSM
	_update_fsm_state()


## =============================================================================
## PASO 2: ACTUALIZACIÓN VISUAL (_process)
## -----------------------------------------------------------------------------
## La orientación del modelo se interpola suavemente con lerp_angle() en _process.
## La locomoción es in-place: el CharacterBody3D gestiona el desplazamiento
## en el mundo físico, mientras la animación se reproduce en su origen local.
## =============================================================================
func _process(delta: float) -> void:
	if visual_wrapper and move_direction.length_squared() > 0.01:
		target_rotation_y = atan2(move_direction.x, move_direction.z)
		visual_wrapper.rotation.y = lerp_angle(
			visual_wrapper.rotation.y,
			target_rotation_y,
			rotation_speed * delta
		)


## =============================================================================
## MÁQUINA DE ESTADOS FINITOS (FSM) Y ANIMACIÓN IN-PLACE
## =============================================================================
func _update_fsm_state() -> void:
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	match current_state:
		State.IDLE:
			if not is_on_floor():
				_transition_to(State.JUMP)
			elif horizontal_speed > 0.2:
				_transition_to(State.WALK)
				
		State.WALK:
			if not is_on_floor():
				_transition_to(State.JUMP)
			elif horizontal_speed <= 0.2:
				_transition_to(State.IDLE)
				
		State.JUMP:
			if is_on_floor():
				if horizontal_speed > 0.2:
					_transition_to(State.WALK)
				else:
					_transition_to(State.IDLE)


func _transition_to(new_state: State) -> void:
	if current_state == new_state:
		return
		
	var old_state_name = State.keys()[current_state]
	var new_state_name = State.keys()[new_state]
	
	current_state = new_state
	
	# Reproducir animación sincronizada con la FSM
	_play_state_animation(new_state)
	
	# Registro legible en consola
	print("[FSM] Transición explícita: %s -> %s (Sobre suelo: %s, VelY: %.2f)" % [
		old_state_name, new_state_name, is_on_floor(), velocity.y
	])
	
	emit_signal("state_changed", old_state_name, new_state_name)


func _play_state_animation(state: State) -> void:
	if not is_instance_valid(anim_player):
		return
	match state:
		State.IDLE:
			anim_player.play("idle", 0.2)
		State.WALK:
			anim_player.play("walk", 0.15)
		State.JUMP:
			anim_player.play("jump", 0.1)


func get_current_state_name() -> String:
	return State.keys()[current_state]


func _setup_fallback_inputs() -> void:
	var defaults = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"ui_cancel": [KEY_ESCAPE],
		"reset": [KEY_R]
	}
	
	for action_name in defaults:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in defaults[action_name]:
				var ev = InputEventKey.new()
				ev.physical_keycode = key_code
				InputMap.action_add_event(action_name, ev)
