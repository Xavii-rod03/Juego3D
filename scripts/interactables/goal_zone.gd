extends Area3D
class_name GoalZone

## Zona de salida y meta del laberinto 3D.
## Al cruzar el jugador, emite la señal de victoria para finalizar la demostración.

signal goal_reached

var is_completed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_completed:
		return
	if body is Player or body.is_in_group("player"):
		is_completed = true
		emit_signal("goal_reached")
		print("[VICTORIA] ¡El jugador ha alcanzado la meta! Demostración completada.")
