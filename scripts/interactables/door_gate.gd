extends Node3D
class_name DoorGate

## Compuerta / Reja mágica estilo Kawaii
## Desciende y abre el paso hacia la meta cuando se recoge la estrella de acceso.

@export var is_open: bool = false
@export var open_speed: float = 2.0
@export var open_depth: float = 3.5

var target_y: float = 0.0
var initial_y: float = 0.0
var moving: bool = false

@onready var gate_body: StaticBody3D = $GateBody
@onready var gate_collision: CollisionShape3D = $GateBody/CollisionShape3D
@onready var status_light: OmniLight3D = $StatusLight
@onready var status_indicator: MeshInstance3D = $Indicator

var mat_locked: StandardMaterial3D
var mat_unlocked: StandardMaterial3D

func _ready() -> void:
	initial_y = gate_body.position.y
	target_y = initial_y
	
	mat_locked = StandardMaterial3D.new()
	mat_locked.albedo_color = Color(0.85, 0.45, 0.50) # Terracota rosado suave
	mat_locked.emission_enabled = true
	mat_locked.emission = Color(0.85, 0.45, 0.50)
	mat_locked.emission_energy_multiplier = 0.4
	
	mat_unlocked = StandardMaterial3D.new()
	mat_unlocked.albedo_color = Color(0.40, 0.75, 0.58) # Menta suave mate
	mat_unlocked.emission_enabled = true
	mat_unlocked.emission = Color(0.40, 0.75, 0.58)
	mat_unlocked.emission_energy_multiplier = 0.4
	
	_update_visuals()

func _process(delta: float) -> void:
	if moving:
		gate_body.position.y = move_toward(gate_body.position.y, target_y, open_speed * delta)
		if is_equal_approx(gate_body.position.y, target_y):
			moving = false
			if is_open:
				gate_collision.disabled = true
				print("[MECÁNICA] ¡Compuerta abierta y colisión desactivada!")

func open_door() -> void:
	if is_open:
		return
	is_open = true
	target_y = initial_y - open_depth
	moving = true
	_update_visuals()
	print("[MECÁNICA] Activando mecanismo: Abriendo compuerta...")

func _update_visuals() -> void:
	if is_open:
		if is_instance_valid(status_light):
			status_light.light_color = Color(0.45, 0.92, 0.72)
		if is_instance_valid(status_indicator):
			status_indicator.material_override = mat_unlocked
	else:
		if is_instance_valid(status_light):
			status_light.light_color = Color(1.0, 0.5, 0.62)
		if is_instance_valid(status_indicator):
			status_indicator.material_override = mat_locked
