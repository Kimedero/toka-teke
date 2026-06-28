extends Node3D
class_name CharacterMesh

@export var character: Character
@export var character_mesh: Node3D

@export var mesh_rotation_speed: float = 20 # * (1.0 / 60)

var character_aim_state: bool = false

func _ready() -> void:
	assert(character, "Character is not set at %s" % [self])
	
	assert(character_mesh, "Character mesh is not set at %s" % [self])


func _process(delta: float) -> void:
	if character_aim_state:
		mesh_direction(Vector2.UP, delta)
	else:
		if character.input_dir: # and not character_aim_state:
			mesh_direction(character.input_dir, delta)
		#print("Character Input Direction: %s" % [character.input_dir])
	


func on_character_camera_rig_camera_rotated(camera_rotation: Vector2) -> void:
	#print("Camera rotation: %s" % [camera_rotation])
	
	rotate_mesh(camera_rotation.x)


func rotate_mesh(mesh_rotation: float):
	character_mesh.rotation_degrees.y += mesh_rotation


func mesh_direction(input_direction: Vector2, delta: float) -> void:
	var angle: float = atan2(-input_direction.x, -input_direction.y)
	character_mesh.rotation.y = lerp_angle(character_mesh.rotation.y, angle, mesh_rotation_speed * delta)


func on_character_camera_rig_aim_state(aim_state_bool: bool) -> void:
	character_aim_state = aim_state_bool
	#if aim_state_bool:
		#mesh_direction(Vector2.UP) #.rotated(character_mesh.rotation.y))
	#print("Aim state: %s" % [aim_state_bool])
