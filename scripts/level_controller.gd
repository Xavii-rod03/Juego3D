extends Node3D
class_name LevelController

## Gestor del Nivel de Laberinto 3D (Entrega 1)
## Coordina la interacción central:
## 1. El jugador recoge la Tarjeta de Acceso (KeyItem).
## 2. Se activa el mecanismo y se abre la compuerta de seguridad (DoorGate).
## 3. El jugador cruza la compuerta y alcanza la meta (GoalZone) completando el nivel.

@onready var hud: HUD = $HUD
@onready var door_gate: DoorGate = $Interactables/DoorGate
@onready var key_item: KeyItem = $Interactables/KeyItem
@onready var goal_zone: GoalZone = $Interactables/GoalZone
@onready var player: Player = $Player

func _ready() -> void:
	if is_instance_valid(key_item):
		key_item.key_collected.connect(_on_key_collected)
	if is_instance_valid(goal_zone):
		goal_zone.goal_reached.connect(_on_goal_reached)

func _on_key_collected() -> void:
	print("[SISTEMA] Notificación de llave recibida. Desbloqueando compuerta...")
	if is_instance_valid(hud):
		hud.set_key_collected()
	if is_instance_valid(door_gate):
		door_gate.open_door()

func _on_goal_reached() -> void:
	print("[SISTEMA] Meta alcanzada. Finalizando demostración...")
	if is_instance_valid(hud):
		hud.show_victory()
	# Liberar el cursor del ratón para comodidad del usuario
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
