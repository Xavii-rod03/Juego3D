extends Node3D
class_name BenchmarkOO

## Gestor de la Variante 1: Orientada a Objetos (OO)
## Crea 1 000 nodos EntityOO individuales, cada uno con su propio objeto MeshInstance3D.
## La actualización se ejecuta iterando sobre un Array de referencias a objetos,
## incurriendo en indirecciones por puntero y sobrecarga de despacho virtual en cada entidad.

@export var entity_count: int = 1000
@export var bounds: Vector3 = Vector3(25.0, 15.0, 25.0)

var entities: Array[EntityOO] = []
var shared_mesh: BoxMesh
var shared_material: StandardMaterial3D

func init_benchmark(count: int, seed_value: int) -> void:
	entity_count = count
	_clear_entities()
	
	# Usar exactamente la misma semilla para que ambas variantes comiencen
	# con idéntico estado inicial de posiciones y velocidades.
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	# Malla y material compartidos para asegurar idéntica carga visual
	shared_mesh = BoxMesh.new()
	shared_mesh.size = Vector3(0.5, 0.5, 0.5)
	shared_material = StandardMaterial3D.new()
	shared_material.albedo_color = Color(0.9, 0.35, 0.25, 1.0)
	shared_material.roughness = 0.5
	shared_mesh.material = shared_material
	
	entities.resize(entity_count)
	for i in range(entity_count):
		var entity = EntityOO.new()
		add_child(entity)
		
		# Componente visual hijo idéntico
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = shared_mesh
		entity.add_child(mesh_inst)
		
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
		# Evitar velocidad cero
		if vel.length_squared() < 0.1:
			vel = Vector3(3.0, 2.0, 3.0)
			
		entity.setup(pos, vel, bounds)
		entities[i] = entity

## Ejecuta la actualización de las 1 000 entidades y retorna el tiempo
## exacto en microsegundos consumido por el bloque instrumentado.
func simulate_step(delta: float) -> int:
	var t0 = Time.get_ticks_usec()
	for i in range(entity_count):
		entities[i].update_step(delta)
	var t1 = Time.get_ticks_usec()
	return t1 - t0

func cleanup() -> void:
	_clear_entities()

func _clear_entities() -> void:
	for entity in entities:
		if is_instance_valid(entity):
			entity.queue_free()
	entities.clear()
