extends Node3D
class_name BenchmarkDOD

## Gestor de la Variante 2: Orientada a Datos (DOD)
## Utiliza estructuras contiguas de memoria (PackedVector3Array) y actualización centralizada.
##
## ACLARACIÓN CONCEPTUAL CLAVE (REQUERIMIENTO DE TAREA 2):
## Esta implementación es "Data-Oriented Design" (DOD) y NO un ECS completo.
## Es DOD porque agrupa los datos en arreglos planos contiguos (Structure of Arrays)
## y los procesa en un único bucle lineal, maximizando la coherencia espacial y eliminando
## las llamadas virtuales por entidad. No es ECS porque no existe un registro genérico
## de componentes, entidades desacopladas por identificador ni consultas por arquetipo.

@export var entity_count: int = 1000
@export var bounds: Vector3 = Vector3(25.0, 15.0, 25.0)

# Datos contiguos en memoria (PackedVector3Array almacena vectores contiguos en C++)
var positions: PackedVector3Array = PackedVector3Array()
var velocities: PackedVector3Array = PackedVector3Array()

var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh
var shared_mesh: BoxMesh
var shared_material: StandardMaterial3D

func init_benchmark(count: int, seed_value: int) -> void:
	entity_count = count
	_clear_data()
	
	# Usar exactamente la misma semilla que la variante OO para idéntico estado inicial
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	positions.resize(entity_count)
	velocities.resize(entity_count)
	
	# Configurar MultiMesh para idéntica carga geométrica y material
	shared_mesh = BoxMesh.new()
	shared_mesh.size = Vector3(0.5, 0.5, 0.5)
	shared_material = StandardMaterial3D.new()
	shared_material.albedo_color = Color(0.25, 0.65, 0.95, 1.0)
	shared_material.roughness = 0.5
	shared_mesh.material = shared_material
	
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = shared_mesh
	multimesh.instance_count = entity_count
	
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)
	
	for i in range(entity_count):
		var pos = Vector3(
			rng.randf_range(-bounds.x, bounds.x),
			rng.randf_range(1.0, bounds.y),
			rng.randf_range(-bounds.z, bounds.z)
		)
		var vel = Vector3(
			rng.randf_range(-6.0, 6.0),
			rng.randf_range(-4.0, 4.0),
			rng.randf_range(-6.0, 6.0)
		)
		if vel.length_squared() < 0.1:
			vel = Vector3(3.0, 2.0, 3.0)
			
		positions[i] = pos
		velocities[i] = vel
		multimesh.set_instance_transform(i, Transform3D(Basis(), pos))

## Ejecuta la actualización centralizada en arrays planos y retorna el tiempo
## exacto en microsegundos consumido por el bloque instrumentado.
func simulate_step(delta: float) -> int:
	var t0 = Time.get_ticks_usec()
	
	var bx = bounds.x
	var by = bounds.y
	var bz = bounds.z
	
	# Bucle lineal centralizado sobre arreglos de datos planos
	for i in range(entity_count):
		var p = positions[i]
		var v = velocities[i]
		
		# Regla de movimiento idéntica
		p += v * delta
		
		# Rebote en límites 3D
		if abs(p.x) > bx:
			v.x = -v.x
			p.x = sign(p.x) * bx
		if p.y < 0.5:
			v.y = abs(v.y)
			p.y = 0.5
		elif p.y > by:
			v.y = -abs(v.y)
			p.y = by
		if abs(p.z) > bz:
			v.z = -v.z
			p.z = sign(p.z) * bz
			
		positions[i] = p
		velocities[i] = v
		
		# Actualizar transformación en el buffer de MultiMesh
		multimesh.set_instance_transform(i, Transform3D(Basis(), p))
		
	var t1 = Time.get_ticks_usec()
	return t1 - t0

func cleanup() -> void:
	_clear_data()

func _clear_data() -> void:
	if is_instance_valid(multimesh_instance):
		multimesh_instance.queue_free()
	positions.clear()
	velocities.clear()
