extends Area3D
class_name VehicleEntry

var GAME_RESOURCE = preload("res://resources/game_resource.tres")
var VEHICLE_RESOURCE = preload("res://vehicles/resources/vehicle_resource.tres")
var CHARACTER_RESOURCE = preload("res://characters/resources/character_resource.tres")

@export var character: Character

var chosen_vehicle: Vehicle

func _ready() -> void:
	#assert(character, "Character is not set at %s" % [self])
	pass


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("enter_exit_vehicle"):
		if not character.driving:
			var vehicles_nearby_array: Array = get_overlapping_bodies()
			for veh in vehicles_nearby_array:
				if veh is not Vehicle:
					vehicles_nearby_array.erase(veh)
				
			if not vehicles_nearby_array.is_empty():
				chosen_vehicle = choose_nearest_vehicle(vehicles_nearby_array)
				var vehicle_camera: Camera3D = VEHICLE_RESOURCE.vehicle_camera.camera
				GAME_RESOURCE.current_camera = vehicle_camera
				vehicle_camera.current = true
				
				chosen_vehicle.add_child(VEHICLE_RESOURCE.vehicle_camera)
				#VEHICLE_RESOURCE.vehicle_camera.reparent(chosen_vehicle)
				VEHICLE_RESOURCE.vehicle_camera.camera_vehicle = chosen_vehicle
				
				character.driving = true
				chosen_vehicle.character_on_board = true
				
				character.vehicle_entry_process(true)
				
				print("Found vehicles: %s - Chosen vehicle: %s!" % [vehicles_nearby_array, chosen_vehicle])
			else:
				print("No vehicles found nearby!")
		else:
			var current_camera_rotation_y: float = GAME_RESOURCE.current_camera.global_rotation_degrees.y
			
			var character_camera: Camera3D = CHARACTER_RESOURCE.character_camera.camera
			GAME_RESOURCE.current_camera = character_camera
			character_camera.current = true
			
			character.driving = false
			chosen_vehicle.character_on_board = false
			
			character.vehicle_entry_process(false)
			character.global_transform = chosen_vehicle.global_transform.translated_local((Vector3.RIGHT * 3.2) + (Vector3.UP))
			print("Character 1: %s" % [character.global_rotation_degrees.y])
			character.global_rotation.y = current_camera_rotation_y + PI * 0.5
			print("Character 2: %s" % [character.global_rotation_degrees.y])
			
			chosen_vehicle = null


func choose_nearest_vehicle(vehicles_array: Array) -> Vehicle:
	match vehicles_array.size():
		1:
			return vehicles_array[0]
		_:
			var distance_array: Array
			var distance_dict: Dictionary
			for veh: Vehicle in vehicles_array:
				var dist_to_player: float = character.global_position.distance_squared_to(veh.global_position)
				distance_array.append(dist_to_player)
				distance_dict[dist_to_player] = veh
			distance_array.sort()
			return distance_dict[distance_array[0]]
