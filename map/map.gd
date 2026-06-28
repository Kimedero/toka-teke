extends Node3D

var NAVIGATION_RESOURCE = preload("res://vehicles/resources/navigation_resource.tres")

var VEHICLE_RESOURCE = preload("res://vehicles/resources/vehicle_resource.tres")
var CHARACTER_RESOURCE = preload("res://characters/resources/character_resource.tres")

@export var vehicle_spawn_node: Marker3D
@export var character_spawn_node: Marker3D

@export var vehicle_camera_rig: VehicleCameraRig
@export var character_camera_rig: CharacterCameraRig

@export var vehicle_navigation_paths_nodes_array: Array[Marker3D]
@export var vehicle_transition_paths_nodes_array: Array[Marker3D]

func _ready() -> void:
	assert(vehicle_spawn_node, "Vehicle spawn node is not set at %s" % [self])
	assert(character_spawn_node, "Character spawn node is not set at %s" % [self])
	
	assert(vehicle_camera_rig, "Vehicle camera rig is not set at %s" % [self])
	assert(character_camera_rig, "Character camera rig is not set at %s" % [self])
	
	VEHICLE_RESOURCE.vehicle_camera = vehicle_camera_rig
	CHARACTER_RESOURCE.character_camera = character_camera_rig
	
	assert(vehicle_navigation_paths_nodes_array, "Vehicle navigation paths nodes array is not set at %s" % [self])
	assert(vehicle_transition_paths_nodes_array, "Vehicle transition paths nodes array is not set at %s" % [self])
	
	# Navigation initialization
	var nav_paths_array: Array = []
	for marker: Marker3D in vehicle_navigation_paths_nodes_array:
		var marker_children_array: Array = marker.get_children()
		for path: Path3D in marker_children_array:
			nav_paths_array.append(path) 
	NAVIGATION_RESOURCE.process_navigation_paths(nav_paths_array)
	NAVIGATION_RESOURCE.process_twin_navigation_paths()
	var trans_paths_array: Array = []
	for marker: Marker3D in vehicle_transition_paths_nodes_array:
		var marker_children_array: Array = marker.get_children()
		for path: Path3D in marker_children_array:
			trans_paths_array.append(path)
	NAVIGATION_RESOURCE.process_transition_paths(trans_paths_array)
	
	character_initialize()
	
	VEHICLE_RESOURCE.vehicle_spawn_node = vehicle_spawn_node
	VEHICLE_RESOURCE.spawn_initial_vehicles()


func character_initialize() -> void:
	var _player_character: Character = CHARACTER_RESOURCE.spawn_player_character(Vector3.ZERO, 0, character_spawn_node)
