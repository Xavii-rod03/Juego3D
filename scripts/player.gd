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
		
	# Emitir estado inicial
	emit_signal("state_changed", "", State.keys()[current_state])
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
		
		# Rotación vertical (Pitch) en el pivote, restringida para no dar la vuelta completa
		var pitch_change = -event.relative.y * mouse_sensitivity
		var current_pitch = camera_pivot.rotation_degrees.x
		var new_pitch = clamp(current_pitch + rad_to_deg(pitch_change), min_pitch, max_pitch)
		camera_pivot.rotation_degrees.x = new_pitch


## =============================================================================
## PASO 1: FÍSICA (_physics_process)
## -----------------------------------------------------------------------------
## EXPLICACIÓN DE USO DE 'DELTA':
## 1. Gravedad: La aceleración de la gravedad se aplica multiplicando por delta
##    (velocity.y -= gravity * delta) porque la aceleración es m/s^2 y queremos
##    el cambio de velocidad en este fotograma (m/s).
## 2. Aceleración / Fricción: Interpolamos la velocidad horizontal usando lerp
##    con un factor ponderado por delta (acceleration * delta) para que la respuesta
##    sea independiente de la tasa de fotogramas físicos.
## 3. Desplazamiento final: move_and_slide() en Godot 4 utiliza INTERNAMENTE
##    el delta de física para calcular el desplazamiento (position += velocity * delta).
##    ¡POR ESO NO SE DEBE MULTIPLICAR LA VELOCIDAD POR DELTA AL LLAMAR A move_and_slide()!
##    Hacerlo aplicaría el tiempo dos veces a la misma magnitud, reduciendo drásticamente
##    el movimiento según el framerate.
## =============================================================================
func _physics_process(delta: float) -> void:
	# 1. Obtener entradas de movimiento
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# 2. Calcular dirección relativa a la orientación horizontal de la cámara
	var cam_transform = camera_pivot.global_transform
	var forward = -cam_transform.basis.z
	var right = cam_transform.basis.x
	# Proyectar en el plano horizontal XZ
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	
	move_direction = (right * input_dir.x + forward * -input_dir.y).normalized()
	
	# 3. Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# Salto: Solo permitido cuando está sobre el suelo
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			_transition_to(State.JUMP)
	
	# 4. Aceleración horizontal e inercia / fricción
	var target_vel_x = move_direction.x * speed
	var target_vel_z = move_direction.z * speed
	
	var accel_factor = acceleration if move_direction.length_squared() > 0.001 else friction
	velocity.x = move_toward(velocity.x, target_vel_x, accel_factor * speed * delta)
	velocity.z = move_toward(velocity.z, target_vel_z, accel_factor * speed * delta)
	
	# 5. Ejecutar físicas y colisiones
	move_and_slide()
	
	# 6. Actualización y transiciones de la FSM
	_update_fsm_state()


## =============================================================================
## PASO 2: ACTUALIZACIÓN VISUAL (_process)
## -----------------------------------------------------------------------------
## Separada del paso de física. Aquí se interpola suavemente la orientación visual
## del personaje hacia la dirección de movimiento para evitar vibraciones (jittering).
## =============================================================================
func _process(delta: float) -> void:
	if visual_wrapper and move_direction.length_squared() > 0.01:
		# Calcular ángulo hacia donde mira el movimiento en radianes
		target_rotation_y = atan2(move_direction.x, move_direction.z)
		# Rotación interpolada suave usando lerp_angle
		visual_wrapper.rotation.y = lerp_angle(
			visual_wrapper.rotation.y,
			target_rotation_y,
			rotation_speed * delta
		)


## =============================================================================
## MÁQUINA DE ESTADOS FINITOS (FSM)
## -----------------------------------------------------------------------------
## Controla estados Idle, Walk y Jump con transiciones explícitas y registros legibles.
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
	
	# Registro legible en consola (cumple requerimiento 4)
	print("[FSM] Transición explícita: %s -> %s (Sobre suelo: %s, VelY: %.2f)" % [
		old_state_name, new_state_name, is_on_floor(), velocity.y
	])
	
	# Notificar a la interfaz HUD
	emit_signal("state_changed", old_state_name, new_state_name)


func get_current_state_name() -> String:
	return State.keys()[current_state]


## Configuración de respaldo por si el proyecto no tiene las acciones definidas en InputMap
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
