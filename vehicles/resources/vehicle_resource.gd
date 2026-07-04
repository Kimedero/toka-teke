extends Resource
class_name VehicleResource

## Where general vehicle settings are stored

var GAME_RESOURCE = preload("res://resources/game_resource.tres")
var NAVIGATION_RESOURCE = preload("res://vehicles/resources/navigation_resource.tres")

var vehicle_spawn_node: Marker3D

var vehicle_camera: VehicleCameraRig

var spawned_vehicles_array: Array
@export var max_spawned_vehicles: int = 16

const EVO_6 = preload("res://vehicles/Meshes/Evo6/evo_6.tscn")
const FIAT_131 = preload("res://vehicles/Meshes/Fiat 131/fiat_131.tscn")
const SUV_1 = preload("res://vehicles/Meshes/MaVehicles/SUV1/suv_1.tscn")
const LAND_ROVER_DEFENDER_110 = preload("res://vehicles/Meshes/Land Rover Defender 110/land_rover_defender_110.tscn")

var vehicle_scenes_array: Array = [EVO_6, FIAT_131, SUV_1, LAND_ROVER_DEFENDER_110]

## how far away should a vehicle be able to spawn at
@export var max_vehicle_spawn_distance: float = 100 # 160
## how far away should a vehicle be able to despawn at
@export var vehicle_despawn_distance: float = 125 # 200

var last_vehicle_spawn_position: Vector3


# OBJECT SPAWNING
## the distance by which to shift a vehicle from the generated spawn position
@export var spawn_shift_distance: float = 3 # 4
## the distance from the end of the path at which we can still subtract a small distance to get a spawn direction
@export var spawn_direction_calculation_safe_offset: float = 0.1

func spawn_initial_vehicles() -> void:
	for vehicle_num: int in max_spawned_vehicles:
		#spawn_traffic(pick_random_vehicle_spawn_path())
		var _new_traffic_vehicle = spawn_vehicle_within_specific_radius(max_vehicle_spawn_distance)


func spawn_vehicle(vehicle_scene: PackedScene, vehicle_spawn_path: Path3D, vehicle_spawn_transform: Transform3D) -> Vehicle:
	var new_vehicle: Vehicle = vehicle_scene.instantiate()
	new_vehicle.current_navigation_path = vehicle_spawn_path
	
	vehicle_spawn_node.add_child(new_vehicle)
	new_vehicle.global_transform = vehicle_spawn_transform
	
	spawned_vehicles_array.append(new_vehicle)
	
	return new_vehicle


func spawn_vehicle_at_specific_point(vehicle_scene: PackedScene, spawn_path: Path3D, specific_point: Vector3) -> Vehicle:
	var spawn_transform: Transform3D = generate_specified_path_aligned_transform(spawn_path, specific_point)
	var new_vehicle = spawn_vehicle(vehicle_scene, spawn_path, spawn_transform)
	return new_vehicle


func spawn_vehicle_within_specific_radius(radius: float) -> Vehicle:
	## this is just to initialize spawn_pos and run the while loop below to find a suitable spawn path
	var spawn_pos: Vector3 = GAME_RESOURCE.current_camera.global_position
	#var player_vehicle_spring_arm: Node3D = vehicle_camera_rig.spring_arm
	
	# before spawning we make sure the spawn point is a ways from the vehicle and 
	# also not right in front of the player vehicle
	while spawn_pos.distance_squared_to(GAME_RESOURCE.current_camera.global_position) < pow(max_vehicle_spawn_distance * 0.5, 2) or spawn_pos.distance_squared_to(last_vehicle_spawn_position) <= pow(25, 2): # or NAVIGATION_RESOURCE.in_vision_cone(GAME_RESOURCE.current_camera, spawn_pos):
		spawn_pos = NAVIGATION_RESOURCE.get_random_point_in_radius(GAME_RESOURCE.current_camera.global_position, radius)
	
	#var facing: bool = in_vision_cone(player_vehicle_spring_arm, random_pos)
	#print("Spawn Dist: %s - In view cone: %s" % [player_vehicle.global_position.distance_to(random_pos), facing])
	#print_debug("Spawn Dist: %s - Spawn pos: %s" % [GAME_RESOURCE.current_camera.global_position.distance_to(spawn_pos), spawn_pos])
	
	var chosen_path_dict: Dictionary = NAVIGATION_RESOURCE.find_nearest_path_to_point(NAVIGATION_RESOURCE.vehicle_navigation_paths_array, spawn_pos)
	var new_traffic_vehicle := spawn_vehicle_at_specific_point(vehicle_scenes_array.pick_random(), chosen_path_dict.path, chosen_path_dict.point)
	new_traffic_vehicle.name = "TrafficVehicle_%s" % [new_traffic_vehicle.get_rid().get_id()]
	
	last_vehicle_spawn_position = spawn_pos
	
	return new_traffic_vehicle


func pick_random_position_on_path(spawn_path: Path3D) -> Vector3:
	# a function to pick a random position on a navigation path
	return Array(spawn_path.curve.get_baked_points()).pick_random()


func generate_shifted_position(curr_path: Path3D, pos: Vector3, spawn_shift: float) -> Vector3:
	var pos_offset: float = curr_path.curve.get_closest_offset(pos)
	var back_offset: float = maxf(pos_offset - spawn_direction_calculation_safe_offset, 0)
	var forward_offset: float = minf(pos_offset + spawn_direction_calculation_safe_offset, curr_path.curve.get_baked_length()) # path_length
	var back_pos: Vector3 = curr_path.curve.sample_baked(back_offset)
	var forward_pos :Vector3 = curr_path.curve.sample_baked(forward_offset)
	var direction: Vector3 = forward_pos.direction_to(back_pos)
	if direction == Vector3.ZERO:
		print("Dir: %s is zero!" % [direction])
	var cross: Vector3 = direction.normalized().cross(Vector3.UP)
	#if cross == Vector3.ZERO:
		#print("Cross: %s is zero!" % [cross])
	# we can also use some geometry calculations to ensure that in a curve the position can be adjusted
	# accordingly
	return pos + cross * spawn_shift


func generate_spawn_rotation(spawn_path: Path3D, spawn_pos: Vector3) -> Basis:
	# the idea is to move the progress by a few units forward and get the direction from that
	var closest_offset_on_path: float = spawn_path.curve.get_closest_offset(spawn_pos)
	# We make sure that if by shifting a few steps back on the curve we hit the 
	# start of the path we use it as the offset
	var back_offset: float = maxf(closest_offset_on_path - spawn_direction_calculation_safe_offset, 0)
	var forward_offset: float = minf(closest_offset_on_path + spawn_direction_calculation_safe_offset, spawn_path.curve.get_baked_length())
	var back_pos: Vector3 = spawn_path.curve.sample_baked(back_offset)
	var forward_pos :Vector3 = spawn_path.curve.sample_baked(forward_offset)
	
	#var position_with_small_offset_on_path: Vector3 = spawn_path.curve.sample_baked(closest_offset_on_path + 1)
	#var spawn_direction: Vector3 = spawn_pos.direction_to(position_with_small_offset_on_path)
	
	var spawn_direction: Vector3 = back_pos.direction_to(forward_pos)
	if spawn_direction == Vector3.ZERO:
		print("Spawn direction %s is zero!" % [spawn_direction])
	#print("New vehicle: %s - %s - %s" % [spawn_pos, position_with_small_offset_on_path, spawn_direction])
	return get_rotation_from_direction(spawn_direction).rotated(Vector3.UP, PI)


func get_rotation_from_direction(look_direction : Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis = look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)


func generate_random_path_aligned_transform(spawn_path: Path3D, spawn_shift: float = spawn_shift_distance) -> Transform3D:
	## A function that generates a random transform to the left of the chosen path at a random position, 
	## and the transform is aligned to the left of the path
	var random_pos_on_path: Vector3 = pick_random_position_on_path(spawn_path)
	var shifted_spawn_pos: Vector3 = generate_shifted_position(spawn_path, random_pos_on_path, spawn_shift)
	
	var new_basis := generate_spawn_rotation(spawn_path, random_pos_on_path)
	return Transform3D(new_basis, shifted_spawn_pos)


func generate_specified_path_aligned_transform(spawn_path: Path3D, specific_point: Vector3, spawn_shift: float = spawn_shift_distance) -> Transform3D:
	var specific_pos_on_path: Vector3 = spawn_path.curve.get_closest_point(specific_point)
	var shifted_spawn_pos: Vector3 = generate_shifted_position(spawn_path, specific_pos_on_path, spawn_shift)
	var new_basis := generate_spawn_rotation(spawn_path, specific_pos_on_path)
	return Transform3D(new_basis, shifted_spawn_pos)
