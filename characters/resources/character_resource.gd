extends Resource
class_name CharacterResource

var character_scene = preload("res://characters/character.tscn")

var character_camera: CharacterCameraRig

func spawn_character(character_spawn_position: Vector3, character_spawn_rotation_y: float, character_spawn_node: Marker3D, character_control: Character.CHARACTER_CONTROL) -> Character:
	var new_character: Character = character_scene.instantiate()
	new_character.character_control = character_control
	character_spawn_node.add_child(new_character)
	new_character.global_position = character_spawn_position
	new_character.rotation_degrees.y = character_spawn_rotation_y
	return new_character


func spawn_player_character(character_spawn_position: Vector3, character_spawn_rotation_y: float, character_spawn_node: Marker3D) -> Character:
	var new_player_character = spawn_character(character_spawn_position, character_spawn_rotation_y, character_spawn_node, Character.CHARACTER_CONTROL.MANUAL)
	new_player_character.name = "PlayerCharacter"
	
	# attaching the character camera
	character_camera.character = new_player_character
	character_camera.reparent(new_player_character.camera_pos)
	#character_camera.position = Vector3.ZERO
	character_camera.transform = Transform3D.IDENTITY
	character_camera.initialize_character()
	
	return new_player_character
