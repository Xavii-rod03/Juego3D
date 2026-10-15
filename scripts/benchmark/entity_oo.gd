extends Node3D
class_name EntityOO

## Entidad individual para el Benchmark Orientado a Objetos (OO)
## Cada entidad es un objeto/nodo independiente con estado encapsulado.
## La actualización se ejecuta mediante llamada al método de instancia,
## demostrando la sobrecarga de indirección por punteros y llamadas polimórficas.

var velocity: Vector3 = Vector3.ZERO
var bounds: Vector3 = Vector3(25.0, 15.0, 25.0)

func setup(pos: Vector3, vel: Vector3, max_bounds: Vector3) -> void:
	position = pos
	velocity = vel
	bounds = max_bounds
	# Desactivamos _process nativo para permitir la medición instrumentada precisa
	# del bloque CPU sin mezclarlo con otros eventos del motor.
	set_process(false)

func update_step(delta: float) -> void:
	# Regla de movimiento idéntica para ambas variantes
	position += velocity * delta
	
	# Rebote en límites 3D
	if abs(position.x) > bounds.x:
		velocity.x = -velocity.x
		position.x = sign(position.x) * bounds.x
	if position.y < 0.5:
		velocity.y = abs(velocity.y)
		position.y = 0.5
	elif position.y > bounds.y:
		velocity.y = -abs(velocity.y)
		position.y = bounds.y
	if abs(position.z) > bounds.z:
		velocity.z = -velocity.z
		position.z = sign(position.z) * bounds.z
