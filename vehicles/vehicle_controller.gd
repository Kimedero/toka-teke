extends Node3D
class_name VehicleController

var VEHICLE_RESOURCE = load("res://vehicles/resources/vehicle_resource.tres")
var NAVIGATION_RESOURCE = preload("res://vehicles/resources/navigation_resource.tres")
var GAME_RESOURCE = preload("res://resources/game_resource.tres")

@onready var vehicle: Vehicle = get_parent()

@export var path_navigator: PathFollow3D
@export var min_navigator_offset: float = 4

var drive_input: float
var steer_input: float
var brake_input: float

var current_speed_kmph: float


@export_category("Speed Limiter")
## how many km/h above max_speed before force = 0
@export var speed_limiter_taper_zone: float = 2.0

@export_category("On Transition")
# the mode when the vehicle is on the transition path, about to join a connecting navigation path
var on_transition_path: bool = false

## the path to join next after going through a transition path
var next_navigation_path: Path3D
var transition_path: Path3D

## where to place the navigator in junctions
@export var vehicle_front_marker: Marker3D
## the distance from the middle of the vehicle to the vehicle front
var vehicle_front_distance: float

# FINAL PATH
@export_category("Final Path")
## the offset on the final path
var curr_final_path_offset: float
var on_final_path: bool = false
## the offset on the final navigation path at which we'll have arrived to the 
## target on mission target
var final_path_offset: float
var arrival_margin: float = 1.0

@export_category("Stoppage and Reversing")
## indicates when a vehicle is stopped when it's supposed to be moving
var prematurely_stopped: bool = false
## how long the vehicle has been stopped
var stop_delta: float
## how long to consider the vehicle prematurely stopped
@export var max_stop_time: float = 3 # in seconds
## the speed at which a vehicle is deemed to be stopped
@export var max_stoppage_speed: float = 3 # kmph

## when the vehicle is attemting to reverse out of a stoppage
var reversing: bool = false
## how long the vehicle has been reversing
var reverse_delta: float
## how long the vehicle to reverse
@export var max_reverse_time: float = 2 # in seconds

@export_category("Front Collision Processor`")
@export var front_collision_processor: FrontCollisionProcessor
## An array that controls the drive and brake input
var front_collision_factor_array: Array = [1, 0]
var collision_check_skip: int = 15 # 6
var collision_check_delta: int = 4

@export_category("Collision Avoidance Processor`")
@export var right_spring_arm: SpringArm3D
@export var left_spring_arm: SpringArm3D
var spring_arm_array: Array

func _ready() -> void:
	assert(path_navigator, "Path navigator is not set at %s" % [self])
	
	assert(vehicle_front_marker, "Vehicle front marker is not set at %s" % [self])
	vehicle_front_distance = vehicle.global_position.distance_to(self.vehicle_front_marker.global_position)
	
	assert(front_collision_processor, "Front collision processor is not set at %s" % [self])
	
	assert(right_spring_arm, "Right spring arm is not set at %s" % [self])
	assert(left_spring_arm, "Left spring arm is not set at %s" % [self])
	right_spring_arm.add_excluded_object(vehicle.get_rid())
	left_spring_arm.add_excluded_object(vehicle.get_rid())
	
	vehicle.vehicle_despawn.connect(on_vehicle_despawn)
	
	initialize_navigation()


func _process(_delta: float) -> void:
	collision_check_delta = wrapi(collision_check_delta+1, 0, collision_check_skip)
	if collision_check_delta == 0 and vehicle.distance_to_camera_squared < pow(50, 2):
		front_collision_factor_array = front_collision_processor.get_collision_factor_array()
	# rotating the front collision processor towards the direction the vehicle is steering towards
	front_collision_processor.rotation.y = steer_input * deg_to_rad(vehicle.max_steer_limit)


func _physics_process(delta: float) -> void:
	current_speed_kmph = vehicle.linear_velocity.length() * 3.6
	$Label3D.text = "%d KM/H\nDrive: %.2f\nSteer: %.2f\nBrake: %.2f\nCamera Rot:Y -> %d\nReversing: %s" % [current_speed_kmph,
	drive_input,
	steer_input,
	brake_input,
	#GAME_RESOURCE.current_camera.get_parent().rotation_degrees.y,
	GAME_RESOURCE.current_camera.global_rotation_degrees.y,
	reversing,
	]
	
	if vehicle.mission_mode == Vehicle.MissionMode.Roam:
		if on_transition_path:
			# when we are on a transition path we move the path follower to right in-front of the vehicle
			path_navigator.progress = vehicle.current_navigation_path.curve.get_closest_offset(vehicle.global_position) + vehicle_front_distance
		else:
			# moving the navigating path follow forward with an offset
			path_navigator.progress = vehicle.current_navigation_path.curve.get_closest_offset(vehicle.global_position) + min_navigator_offset
		
		drive_input = 1.0
		steer_input = direction_to_angle(path_navigator.global_position)
		#brake_input = 0.0drak
		
		# what to when we get to the end of the path
		if is_zero_approx(1.0-path_navigator.progress_ratio):
			process_current_path_end(vehicle.current_navigation_path)
	elif vehicle.mission_mode == Vehicle.MissionMode.OnMission:
		pass
	
	stoppage_process(delta)
	
	front_collision_process()
	
	collision_avoidance_process()
	
	if on_transition_path:
		# if we are REALLY steering we should reduce speed at the junction
		if absf(steer_input) >= 0.1: # 0.05: # 0.2
			speed_limiter_process(10)
		else:
			speed_limiter_process(vehicle.max_speed * 0.64) # 8)
	else:
		speed_limiter_process(vehicle.max_speed)
	
	vehicle.engine_force = drive_input * vehicle.horse_power
	vehicle.steering = lerp_angle(vehicle.steering, steer_input * deg_to_rad(vehicle.max_steer_limit), 16 * delta)
	vehicle.brake = brake_input * vehicle.brake_power


func collision_avoidance_process() -> void:
	spring_arm_array = [1 - (left_spring_arm.get_hit_length() / left_spring_arm.spring_length), \
	1 - (right_spring_arm.get_hit_length() / right_spring_arm.spring_length)]
	steer_input -= (spring_arm_array[0] - spring_arm_array[1]) * 2.0


# called in order to recall the path navigator and despawn the vehicle right after
func on_vehicle_despawn(despawned_vehicle: Vehicle) -> void:
	path_navigator.reparent(self)
	VEHICLE_RESOURCE.spawned_vehicles_array.erase(despawned_vehicle)
	despawned_vehicle.queue_free()


func process_current_path_end(current_path: Path3D) -> void:
	match vehicle.mission_mode:
		Vehicle.MissionMode.Roam:
			pick_random_navigation_path_at_junction(current_path)
		Vehicle.MissionMode.OnMission:
			pick_specific_navigation_path_at_junction(current_path)


func pick_random_navigation_path_at_junction(curr_path: Path3D) -> void:
	# if vehicle is in a navigation path, when we get to the end of a path we 
	# should go switch to the on_transition_path mode
	if curr_path in NAVIGATION_RESOURCE.vehicle_navigation_paths_array:
		on_transition_path = true
		
		## an array of navigation paths connected to the current navigation path 
		## the vehicle is on, from which we can pick the next navigation path
		var connected_paths_array: Array = NAVIGATION_RESOURCE.connected_navigation_paths_dict[curr_path]
		
		# to avoid pesky U-turns
		if connected_paths_array.size() > 1:
			## the nearest navigation path to the current path we're on
			var twin_navigation_path: Path3D = NAVIGATION_RESOURCE.full_twin_navigation_paths_dict[curr_path]
			if twin_navigation_path in connected_paths_array:
				# we erase the nearest path to the current one we're on from the 
				# list of paths to choose from
				connected_paths_array.erase(twin_navigation_path)
		
		## random navigation path for vehicle to switch to 
		var random_next_navigation_path: Path3D = connected_paths_array.pick_random()
		
		# getting the transition path that connects the current navigation path 
		# to the random navigation path we have picked
		var connected_path_dict: Dictionary = NAVIGATION_RESOURCE.transition_paths_dict[curr_path]
		transition_path = connected_path_dict[random_next_navigation_path]
		
		next_navigation_path = random_next_navigation_path
	else:
		on_transition_path = false
	
	transfer_navigator_to_next_path(transition_path, next_navigation_path)


func pick_specific_navigation_path_at_junction(curr_path: Path3D) -> void:
	# if we're on a navigation path currently, and not on a transition path
	if curr_path in NAVIGATION_RESOURCE.navigation_paths_array:
		on_transition_path = true
		
		if not vehicle.on_mission_navigation_paths_array.is_empty():
			# BUG: sometimes there's a bug where most likely we erase a value in the 
			# array before we get to it - figure out a foolproof way to combat this
			var chosen_next_path: Path3D = vehicle.on_mission_navigation_paths_array[0]
			vehicle.on_mission_navigation_paths_array.erase(chosen_next_path)
			
			# we already have the next path lined up, as next on mission path
			var connected_path_dict: Dictionary = NAVIGATION_RESOURCE.transition_paths_dict[curr_path]
			transition_path = connected_path_dict[chosen_next_path]
			
			next_navigation_path = chosen_next_path
	else:
		on_transition_path = false
		
		# we check if the on mission navigation paths array size is at zero. At zero we're on the final path.
		if vehicle.on_mission_navigation_paths_array.is_empty():
			#print("Final Path: %s" % [next_navigation_path.name])
			process_final_path_to_mission_target(next_navigation_path)
			
	transfer_navigator_to_next_path(transition_path, next_navigation_path)


func transfer_navigator_to_initial_path(initial_navigation_path: Path3D) -> void:
	vehicle.current_navigation_path = initial_navigation_path
	path_navigator.reparent(initial_navigation_path)
	path_navigator.progress_ratio = initial_navigation_path.curve.get_closest_offset(vehicle.global_position)
	vehicle.on_mission_navigation_paths_array.erase(initial_navigation_path)
	
	## if we have no more paths to switch to we're already on the final path which 
	# means we can start figuring out where to park at
	if vehicle.on_mission_navigation_paths_array.is_empty():
		#print("We are on the final path! Start think of how to park!")
		process_final_path_to_mission_target(initial_navigation_path)
	#print("current path after initial switch: %s - %s" % [vehicle.current_navigation_path.name, vehicle.on_mission_navigation_paths_array])


func transfer_navigator_to_next_path(incoming_transition_path: Path3D, next_main_path: Path3D) -> void:
	if on_transition_path:
		#vehicle.vehicle_at_junction.emit(true)
		
		vehicle.current_navigation_path = incoming_transition_path
	else:
		#vehicle.vehicle_at_junction.emit(false)
		
		vehicle.current_navigation_path = next_main_path
	path_navigator.reparent(vehicle.current_navigation_path)
	path_navigator.progress_ratio = 0


func process_final_path_to_mission_target(final_path: Path3D):
	final_path_offset = final_path.curve.get_closest_offset(vehicle.on_mission_target_pos)
	#print("On the final path! - %s - Final Offset: %s" % [final_path.name, final_path_offset])
	on_final_path = true


func direction_to_angle(target_position: Vector3) -> float:
	# we get the direction we want to head towards
	# there's an opportunity to shift the target_position to the left when passing a slower vehicle here
	var target_dir: Vector3 = vehicle.global_position.direction_to(target_position)
	# Guard against zero vector (vehicle is at target position)
	if target_dir.is_zero_approx():
		return 0.0
	var cross: Vector3 = vehicle.global_transform.basis.z.cross(target_dir)
	# cross is zero when basis.z and target_dir are parallel (already aligned)
	if cross.is_zero_approx():
		return 0.0
	return vehicle.global_transform.basis.y.dot(cross)


func speed_limiter_process(target_speed: float) -> void:
	var limit_factor: float = 1.0
	if current_speed_kmph >= target_speed:
		# How far past the cap are we?
		var speed_overshoot: float = current_speed_kmph - target_speed
		# Fade factor goes from 1 at max_speed ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ 0 at max_speed + taper_zone
		limit_factor = clamp(1.0 - (speed_overshoot / speed_limiter_taper_zone), 0.0, 1.0)
		drive_input *= limit_factor
		brake_input = 1 - limit_factor
		#return limit_factor
	#return limit_factor


func front_collision_process() -> void:
	drive_input = minf(drive_input, front_collision_factor_array[0])
	brake_input = maxf(brake_input, front_collision_factor_array[1])


func stoppage_process(delta: float) -> void:
	# if we're roaming or on-mission and not at the destination and not reversing 
	if (not reversing):
		# when the vehicle falls below a certain speed initially we start counting 
		# how long it has been stopped
		if current_speed_kmph <= max_stoppage_speed:
			stop_delta += delta
			#print("%s - %s" % [self.name, stop_delta])
		# if the speed goes above the stoppage speed we reset the counter
		else:
			stop_delta = 0
		
		# once we have been stopped for a set amount of time, we establish that 
		# we're prematurely stopped and start reversing
		if stop_delta >= max_stop_time: # and mission_vehicle:
			prematurely_stopped = true
			reversing = true
			#print("%s is prematurely stopped! - %.2f" % [self.name, stop_delta])
			stop_delta = 0
	
	reverse_process(delta)


func reverse_process(delta: float) -> void:
	# when in reverse  
	if reversing:
		# if there's nothing obstructing us from behind we drive backwards and 
		# also limit steering
		#if (not rear_collision_factor_bool):
			reverse_delta += delta
			
			drive_input *= -1
			steer_input = 0
			brake_input = 0
		## if we have obstacles behind the vehicle we brake hard and stop the reverse process
		#elif rear_collision_factor_bool:
			#brake_input = 4
			#
			#reset_reverse_process()
			#print("%s cancelled reversing as there was an obstacle back there!" % [self.name])
	# once we're done reversing we reset things
	else:
		reset_reverse_process()
	
	if reverse_delta >= max_reverse_time:
		reset_reverse_process()
		#print("%s reversing! - %s" % [self.name, reverse_delta])


func reset_reverse_process() -> void:
	reverse_delta = 0
	prematurely_stopped = false
	reversing = false


func initialize_navigation() -> void:
	path_navigator.reparent(vehicle.current_navigation_path)
