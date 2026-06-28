extends VehicleBody3D
class_name Vehicle

var VEHICLE_RESOURCE = load("res://vehicles/resources/vehicle_resource.tres")
var GAME_RESOURCE = preload("res://resources/game_resource.tres")

enum MissionMode {Stop, Roam, OnMission, Park}
@export var mission_mode: MissionMode = MissionMode.Roam

## a flag to ensure vehilces on  mission never get despawned
var mission_vehicle: bool = false

@export var horse_power:= 1000
@export var max_steer_limit := 36
@export var steer_speed := 4
@export var brake_power := 100

@export_category("Speed Limiter")
@export var max_speed: float = 80 # 50 # 40 # 64 # 80 # 100 # in km/h 

@export_category("Navigation")
var current_navigation_path: Path3D

@export_category("Spawn and Despawn")
# CULL PARAMETERS
#var vehicle_camera: Camera3D
## the d-stance at which a mesh is hidden
@export var cull_distance: float = 10
## how many frames to skip before checking current camera distance
@export var cull_frame_skip: int = 24 # 6
## the current frame
@export var cull_frame_delta: int = 2

## vehicles should despawn when they're a certain distance from the camera
var distance_to_camera_squared: float

signal vehicle_despawn


func _process(_delta: float) -> void:
	cull_frame_delta = wrapi(cull_frame_delta+1, 0, cull_frame_skip)
	if cull_frame_delta == 0: # and VEHICLE_MANAGEMENT_RESOURCE.vehicle_camera:
		distance_to_camera_squared = self.global_position.distance_squared_to(GAME_RESOURCE.current_camera.global_position)
			
		#print_debug(VEHICLE_RESOURCE.vehicle_despawn_distance)
		#if VEHICLE_RESOURCE.vehicle_despawn_distance:
		if distance_to_camera_squared > pow(VEHICLE_RESOURCE.vehicle_despawn_distance, 2):
			print_debug("%s about to despawn!" % [self.name])
			vehicle_despawn.emit(self)
			VEHICLE_RESOURCE.spawn_vehicle_within_specific_radius(VEHICLE_RESOURCE.max_vehicle_spawn_distance)
