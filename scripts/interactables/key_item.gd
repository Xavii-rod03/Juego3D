extends Area3D
class_name KeyItem

## Ítem interactivo central: Tarjeta de Acceso / Núcleo de Energía
## Al ser recogido por el jugador, notifica al gestor del nivel y se destruye.

signal key_collected

@export var rotation_speed: float = 2.5
@export var bob_speed: float = 3.0
@export var bob_height: float = 0.15

var initial_y: float = 0.0
var time_elapsed: float = 0.0
var collected: bool = false

@onready var visual_node: Node3D = $Visual

func _ready() -> void:
	initial_y = visual_node.position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if collected:
		return
	time_elapsed += delta
	# Rotación continua y flotación vertical suave
	visual_node.rotate_y(rotation_speed * delta)
	visual_node.position.y = initial_y + sin(time_elapsed * bob_speed) * bob_height

func _on_body_entered(body: Node3D) -> void:
	if collected:
		return
	if body is Player or body.is_in_group("player"):
		collected = true
		emit_signal("key_collected")
		print("[INTERACCIÓN] ¡Tarjeta de Acceso recogida por el jugador!")
		queue_free()
