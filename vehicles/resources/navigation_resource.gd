extends Resource
class_name NavigationResource

# NAVIGATION PATHS
var vehicle_navigation_paths_array: Array

## a dictionary of each navigation path and what other navigation paths it's connected to at the end
var connected_navigation_paths_dict: Dictionary
## a dictionary of each navigation path and what other navigation paths it's connected to at the end, plus the distance between them 
var connected_navigation_paths_distances_dict: Dictionary

## how near a navigation path should be, to be considered as a viable connected path ->
## be careful that this number isn't too big as if it is, we can find bugs where 
## the vehicle doesn't know what path to pick next at junctions that are near each other
@export_range(0, 50, 5) var max_connected_navigation_path_distance: int = 21
## how near a navigation path's start and end should be, to be considered as a viable twin navigation path
@export_range(0, 20, 2)	var max_twin_distance: int = 12 # 10

## a dictionary that holds the nearest navigation path to half the navigation paths, for a-star path-finding
var twin_navigation_paths_dict: Dictionary
## a dictionary that holds the nearest navigation path to each navigation path
var full_twin_navigation_paths_dict: Dictionary

# TRANSITION PATHS
var transition_paths_array: Array

## a dictionary that holds what paths and what transition paths go to what other paths 
var transition_paths_dict: Dictionary

## how near a transition path's start or end should be to a navigation path be considered connected to it
@export_range(0, 5) var max_transition_path_to_navigation_path_distance = 2

# A STAR
# the node to query when navigating
var a_star: AStar3D

# DEBUG
var a_star_navigation_path: Path3D

## to show where the oon mission target position is
var target_marker: Marker3D

## the vision cone within which we can consider the vehilce to see the spawn pos
@export var vision_arc_cone: float = 120


func get_navigation_path(start_pos: Vector3, end_pos: Vector3) -> Array:
	var start_position: int = a_star.get_closest_point(start_pos)
	var end_position: int = a_star.get_closest_point(end_pos)
	return a_star.get_point_path(start_position, end_position)


func process_navigation_array(nav_start_pos: Vector3, nav_end_pos: Vector3) -> Array:
	# A function to process navigation path array to eliminate paths that go backwards 
	
	# first we generate a navigation path array
	var nav_path_array: Array = get_navigation_path(nav_start_pos, nav_end_pos)
	
	# we get the nearest path to the start and the end positions so that we can calculate a path that doesn't go backwards
	var nearest_path_and_pos_to_start_pos: Dictionary = find_nearest_path_to_point(twin_navigation_paths_dict.keys(), nav_start_pos)
	var nearest_path_and_pos_to_end_pos: Dictionary = find_nearest_path_to_point(twin_navigation_paths_dict.keys(), nav_end_pos)
	#print("Nearest start path: %s - Nearest end path: %s" % [nearest_path_and_pos_to_start_pos, nearest_path_and_pos_to_end_pos])
	
	# this is to ensure that we can always get at least two points on the array before trying to modify the array
	## nav path end
	if nav_path_array.size() >= 2:
		# we calculate straight line distance between the first and second points on a path, and also the second point and the start pos
		## the last entry in the nav path array
		var path_array_end: Vector3 = nav_path_array[nav_path_array.size()-1]
		## the second to last entry in the nav path array
		var path_array_next_to_end: Vector3 = nav_path_array[nav_path_array.size()-2]
		
		## the distance between the last entry on the nav path array and the second last entry
		var distance_from_end_to_next_to_end: float = path_array_next_to_end.distance_squared_to(path_array_end)
		var distance_from_next_to_end_to_nearest_path_pos_to_end: float = path_array_next_to_end.distance_squared_to(nearest_path_and_pos_to_end_pos.point)
		if distance_from_next_to_end_to_nearest_path_pos_to_end < distance_from_end_to_next_to_end:
			#print("Path Array: %s" % [path_array])
			nav_path_array.erase(path_array_end)
			#print("Dist 1: %s - Dist 2: %s - %s" % [distance_from_end_to_next_to_end, distance_from_next_to_end_to_nearest_path_pos_to_end, path_array])
			
	## nav path start
	if nav_path_array.size() >= 2:
		var path_array_start: Vector3 = nav_path_array[0]
		var path_array_next_to_start: Vector3 = nav_path_array[1]
		
		var distance_from_start_to_next_to_start: float = path_array_next_to_start.distance_squared_to(path_array_start)
		var distance_from_next_to_start_to_nearest_path_pos_to_start: float = path_array_next_to_start.distance_squared_to(nearest_path_and_pos_to_start_pos.point)
		if distance_from_next_to_start_to_nearest_path_pos_to_start < distance_from_start_to_next_to_start:
			#print("Path Array: %s" % [path_array])
			nav_path_array.erase(path_array_start)
			#print("Dist 1: %s - Dist 2: %s - %s" % [distance_from_start_to_next_to_start, distance_from_next_to_start_to_nearest_path_pos_to_start, path_array])
	
	# there might be one or two more states to considere here
		
	return nav_path_array


func find_nearest_path_to_point(paths_arr: Array, point: Vector3) -> Dictionary:
	var nearest_distances_array: Array
	var nearest_distances_dict: Dictionary
	for path: Path3D in paths_arr:
		var nearest_point_on_path: Vector3 = path.curve.get_closest_point(point)
		var distance_from_point_to_point_on_path: float = flatten_vector3(nearest_point_on_path).distance_squared_to(flatten_vector3(point))
		nearest_distances_array.append(distance_from_point_to_point_on_path)
		nearest_distances_dict[distance_from_point_to_point_on_path] = {"path":path,"point":nearest_point_on_path}
	nearest_distances_array.sort()
	return nearest_distances_dict[nearest_distances_array[0]]


func flatten_vector3(vec3: Vector3) -> Vector3:
	return Vector3(vec3.x, 0, vec3.z)


func display_debug_path(nav_path_array: Array, start_pos: Vector3, end_pos: Vector3) -> void:
	a_star_navigation_path.curve.clear_points()
	a_star_navigation_path.curve.add_point(start_pos)
	for point: Vector3 in nav_path_array:
		a_star_navigation_path.curve.add_point(point)
	a_star_navigation_path.curve.add_point(end_pos)




func process_on_mission_target(curr_pos: Vector3, mission_pos: Vector3):
	var processed_navigation_array: Array = process_navigation_array(curr_pos, mission_pos)
	#NAVIGATION_RESOURCE.display_debug_path(processed_navigation_array, self.global_position, mission_target_pos)
	#print("Processed Array: %s - %s" % [processed_navigation_array.size(), processed_navigation_array])
	
	var on_mission_navigation_paths_array: Array = []
	on_mission_navigation_paths_array.clear()
	
	#we go through the processed navigation array and determine which path each point on it resides at.
	#Then we make an array of paths and 
	if processed_navigation_array.size() >= 2:
		for idx: int in (processed_navigation_array.size() - 1):
			var current_point: Vector3 = processed_navigation_array[idx]
			var next_point: Vector3 = processed_navigation_array[idx + 1]
			
			var nearest_path_dict = find_nearest_path_to_point(vehicle_navigation_paths_array, current_point)
			var next_path_dict = find_nearest_path_to_point(vehicle_navigation_paths_array, next_point)
			# to determine if we are moving forward or turning around and using the next nearest path we check if the two paths match and if they do we check if the offset goes up or down 
			#print("Point idx: %s - Curr: %s - %s - Next: %s - %s" % [idx + 1, current_point, nearest_path_dict.path.name, next_point, next_path_dict.path.name])
			var nearest_path: Path3D = nearest_path_dict.path
			var next_path: Path3D = next_path_dict.path
			if nearest_path == next_path:
				var nearest_path_offset: float = nearest_path.curve.get_closest_offset(current_point)
				var next_path_offset: float = nearest_path.curve.get_closest_offset(next_point)
				if next_path_offset > nearest_path_offset:
					if nearest_path not in on_mission_navigation_paths_array:
						on_mission_navigation_paths_array.append(nearest_path)
					#print("Paths match! - Nearest Offset: %s - Next Offset: %s - Path: %s" % [nearest_path_offset, next_path_offset, nearest_path.name])
				else:
					var twin_path: Path3D = full_twin_navigation_paths_dict[nearest_path]
					if twin_path not in on_mission_navigation_paths_array:
						on_mission_navigation_paths_array.append(twin_path)
					#print("Paths match! - Nearest Offset: %s - Next Offset: %s - Path: %s" % [nearest_path_offset, next_path_offset, twin_path.name])
			else:
				print("A path switch is needed here! %s" % [next_path.name])
				var next_path_twin: Path3D = full_twin_navigation_paths_dict[next_path]
				#print("Nearest Path: %s - %s" % [next_path, next_path_twin])
				# we check that nearest path connects to next path or its twin and append that
				if next_path in connected_navigation_paths_dict[nearest_path]:
					if not on_mission_navigation_paths_array.has(next_path):
						on_mission_navigation_paths_array.append(next_path)
				elif next_path_twin in connected_navigation_paths_dict[nearest_path]:
					if not on_mission_navigation_paths_array.has(next_path_twin):
						on_mission_navigation_paths_array.append(next_path_twin)
			# how do we find the best path to get us from current point to next point? 
			# we find the nearest path to each point and then compare which path
			
	print("On mission process complete! %s. On mission navigation paths array: %s" % [on_mission_navigation_paths_array.size(), on_mission_navigation_paths_array])
	# maybe we can have a switch here that now tells us we can start the mission
	#on_mission_navigation_ready = true


var navigation_paths_ends_dict: Dictionary
func process_navigation_paths(nav_paths_array: Array) -> void:
	# keeping track of the navigation paths
	vehicle_navigation_paths_array = nav_paths_array
	
	# storing where paths start and end points are, as a dictionary
	for path: Path3D in vehicle_navigation_paths_array:
		var path_start_position: Vector3 = path.curve.get_point_position(0)
		var path_end_position: Vector3 = path.curve.get_point_position(path.curve.point_count - 1)
		navigation_paths_ends_dict[path] = {
			"start_pos": path_start_position, 
			"end_pos": path_end_position }
	
	# we go through all path extremities and check how close one path's end is to the start of another path
	for path: Path3D in navigation_paths_ends_dict:
		## an array that holds all connected paths to a particular path
		var nearest_paths_array: Array = []
		## a dictionary that holds all connected paths to a particular path and the closest distance to each
		var nearest_paths_dict: Dictionary = {}
		for other_path: Path3D in navigation_paths_ends_dict:
			if path != other_path:
				var curr_path_end_pos: Vector3 = navigation_paths_ends_dict[path].end_pos
				var other_path_start_pos: Vector3 = navigation_paths_ends_dict[other_path].start_pos
				var closest_distance_to_other_path_start: float = curr_path_end_pos.distance_squared_to(other_path_start_pos)
				if closest_distance_to_other_path_start <= pow(max_connected_navigation_path_distance, 2.0):
					nearest_paths_array.append(other_path)
					nearest_paths_dict[other_path] = closest_distance_to_other_path_start
					#print("%s - %s - %s" % [path.name, other_path.name, path_distance])
		connected_navigation_paths_dict[path] = nearest_paths_array
		connected_navigation_paths_distances_dict[path] = nearest_paths_dict
		
	#if NAVIGATION_RESOURCE.connected_navigation_paths_dict.is_empty():
		#NAVIGATION_RESOURCE.connected_navigation_paths_dict = connected_navigation_paths_dict
	#if NAVIGATION_RESOURCE.connected_navigation_paths_distances_dict.is_empty():
		#NAVIGATION_RESOURCE.connected_navigation_paths_distances_dict = connected_navigation_paths_distances_dict
	print_debug("Connected Paths processed: %s - %s" % [connected_navigation_paths_dict.size(), connected_navigation_paths_distances_dict.size()])
		#print("Connected Paths: %s - %s" % [NAVIGATION_RESOURCE.connected_navigation_paths_dict.size(), connected_navigation_paths_dict])


## This function is to roughly find and store paths that go the exact opposite way from each other
func process_twin_navigation_paths() -> void:
	## an array to stop us from finding twins for already found paths
	var found_twin_navigation_paths_array: Array = []
	for path: Path3D in connected_navigation_paths_dict:
		var path_start_position: Vector3 = path.curve.get_point_position(0)
		var path_end_position: Vector3 = path.curve.get_point_position(path.curve.point_count-1)
		
		## a pre-calculated array of the other paths connected to this path
		var connected_navigation_paths_array: Array = connected_navigation_paths_dict[path]
		for connected_path: Path3D in connected_navigation_paths_array:
			var connected_path_start_position: Vector3 = connected_path.curve.get_point_position(0)
			var connected_path_end_position: Vector3 = connected_path.curve.get_point_position(connected_path.curve.point_count-1)
			
			var first_connected_path_distance: float = path_start_position.distance_squared_to(connected_path_end_position)
			var second_connected_path_distance: float = path_end_position.distance_squared_to(connected_path_start_position)
			
			# we measure if the start sand ends of each path come within a minimum distance and if 
			# so we can conclude these two paths are twins 
			if (first_connected_path_distance <= pow(max_twin_distance, 2)) and (second_connected_path_distance<= pow(max_twin_distance, 2)) and (path not in found_twin_navigation_paths_array):
				found_twin_navigation_paths_array.append(connected_path)
				twin_navigation_paths_dict[path] = connected_path
				
				## to make sure we can find all paths twins
				full_twin_navigation_paths_dict[path] = connected_path
				full_twin_navigation_paths_dict[connected_path] = path
				#print("path: %s - connected path: %s -> start dist: %s - end dist: %s" % [path.name, connected_path.name, sqrt(first_connected_path_distance), sqrt(second_connected_path_distance)])
	#if NAVIGATION_RESOURCE.full_twin_navigation_paths_dict.is_empty():
		##print("Full twin paths dict: %s" % [full_twin_navigation_paths_dict])
		#NAVIGATION_RESOURCE.full_twin_navigation_paths_dict = full_twin_navigation_paths_dict
	#if NAVIGATION_RESOURCE.twin_navigation_paths_dict.is_empty():
		#NAVIGATION_RESOURCE.twin_navigation_paths_dict = twin_navigation_paths_dict
	
	## A quick way to draw all the points in each path for debug purposes
	#if debug_on:
		#for path: Path3D in twin_navigation_paths_dict.keys():
			#for idx: int in path.curve.point_count:
				#var point: Vector3 = path.curve.get_point_position(idx)
				#spawn_marker(point, 4)
		
	print_debug("Twin Paths processed: %s - %s" % [twin_navigation_paths_dict.size(), full_twin_navigation_paths_dict.size()])


var transition_paths_ends_dict: Dictionary
func process_transition_paths(trans_paths_array: Array) -> void:
	transition_paths_array = trans_paths_array
	#NAVIGATION_RESOURCE.transition_paths_array = transition_paths_array
	
	# storing where paths start and end points are, as a dictionary
	for trans_path: Path3D in transition_paths_array:
		var path_start_position: Vector3 = trans_path.curve.get_point_position(0)
		var path_end_position: Vector3 = trans_path.curve.get_point_position(trans_path.curve.point_count - 1)
		transition_paths_ends_dict[trans_path] = {
			"start_pos": path_start_position, 
			"end_pos": path_end_position }
			
	for path: Path3D in connected_navigation_paths_dict.keys():
		var path_end_pos: Vector3 = navigation_paths_ends_dict[path].end_pos
		
		## a dictionary that holds what transition path each connected navigation path connects to
		var connected_path_transition_path_dict: Dictionary = {}
		for connected_path: Path3D in connected_navigation_paths_dict[path]:
			var connected_path_start_pos: Vector3 = navigation_paths_ends_dict[connected_path].start_pos
			
			# we scan through all transition paths and compare the distances between them and the 
			# start and end of connected navigation paths
			for trans_path: Path3D in transition_paths_ends_dict.keys():
				var trans_path_start_pos: Vector3 = transition_paths_ends_dict[trans_path].start_pos
				var trans_path_end_pos: Vector3 = transition_paths_ends_dict[trans_path].end_pos
				
				var path_end_to_trans_path_start_distance: float = path_end_pos.distance_squared_to(trans_path_start_pos)
				var trans_path_end_to_connected_path_start_distance: float = connected_path_start_pos.distance_squared_to(trans_path_end_pos)
				if (path_end_to_trans_path_start_distance <= pow(max_transition_path_to_navigation_path_distance, 2)) and (trans_path_end_to_connected_path_start_distance <= pow(max_transition_path_to_navigation_path_distance, 2)):
					connected_path_transition_path_dict[connected_path] = trans_path
					
		transition_paths_dict[path] = connected_path_transition_path_dict
		
	print_debug("Transition paths dict size: %s - %s" % [transition_paths_dict.size(), transition_paths_dict.keys().size()])


func pick_random_spawn_path(paths_array: Array) -> Path3D:
	# we go through the current paths and choose a random point to spawn something in
	var random_path: Path3D = paths_array.pick_random()
	return random_path


func get_random_point_in_radius(pos: Vector3, radius: float) -> Vector3:
	var angle: float = randf_range(0, TAU) # TAU is 2 * PI (a full circle)
	var distance: float = sqrt(randf()) * radius # sqrt avoids center-clumping
	
	var offset := Vector3(cos(angle), 0, sin(angle)) * distance
	return pos + offset


func in_vision_cone(camera_node: Node3D, target_position: Vector3) -> bool:
	var fwd_vector = -camera_node.global_basis.z
	var curr_pos: Vector3 = camera_node.global_position
	var dir_to_point: Vector3 = curr_pos.direction_to(target_position)
	return rad_to_deg(dir_to_point.angle_to(fwd_vector)) <= vision_arc_cone / 2.0
