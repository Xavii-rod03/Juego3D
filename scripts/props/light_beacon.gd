extends Node3D
class_name LightBeacon

@export var beacon_color: Color = Color(0.0, 0.9, 1.0)
@export var light_energy: float = 2.2
@export var light_range: float = 7.0

@onready var bulb_mesh: MeshInstance3D = $Pillar/Bulb
@onready var omni_light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	if is_instance_valid(omni_light):
		omni_light.light_color = beacon_color
		omni_light.light_energy = light_energy
		omni_light.omni_range = light_range
		
	if is_instance_valid(bulb_mesh):
		var mat = StandardMaterial3D.new()
		mat.albedo_color = beacon_color
		mat.emission_enabled = true
		mat.emission = beacon_color
		mat.emission_energy_multiplier = 2.5
		bulb_mesh.material_override = mat
