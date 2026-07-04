extends VehicleBody3D
class_name Vehicle

var VEHICLE_RESOURCE = load("res://vehicles/resources/vehicle_resource.tres")
var GAME_RESOURCE = preload("res://resources/game_resource.tres")

enum MissionMode {Stop, Roam, OnMission, Park}
@export var mission_mode: MissionMode = MissionMode.Roam

## a flag to ensure vehilces on  mission never get despawned
var mission_vehicle: bool = false

@export var horse_power: float = 800 # 1000
@export var acceleration: float = 4
@export var max_steer_limit: float = 25 # 36
@export var steer_speed: float = 16
@export var brake_power: float = 320 # 400 # 250

@export_category("Speed Limiter")
var current_speed_kmph: float
@export var max_target_speed: float = 80 # 50 # 40 # 64 # 80 # 100 # in km/h 

@export_category("Navigation")
var current_navigation_path: Path3D

@export_category("Spawn and Despawn")
# CULL PARAMETERS
#var vehicle_camera: Camera3D
## the d-stance at which a mesh is hidden
@export var cull_distance: float = 10
## how many frames to skip before checking current camera distance
@export var cull_frame_skip: int = 4 # 24 # 6
## the current frame
@export var cull_frame_delta: int = 2

## vehicles should despawn when they're a certain distance from the camera
var distance_to_camera_squared: float

signal vehicle_despawn

@export_category("Entering Vehicle")
# to identify the vehicle with a player on board
var character_on_board: bool = false

@export_category("Vehicle Upside Down")
var vehicle_upside_down: bool = false


func _process(_delta: float) -> void:
	cull_frame_delta = wrapi(cull_frame_delta+1, 0, cull_frame_skip)
	if cull_frame_delta == 0: # and VEHICLE_MANAGEMENT_RESOURCE.vehicle_camera:
		distance_to_camera_squared = self.global_position.distance_squared_to(GAME_RESOURCE.current_camera.global_position)
			
		#print_debug(VEHICLE_RESOURCE.vehicle_despawn_distance)
		if distance_to_camera_squared > pow(VEHICLE_RESOURCE.vehicle_despawn_distance, 2):
			#print_debug("%s about to despawn!" % [self.name])
			vehicle_despawn.emit(self)
			VEHICLE_RESOURCE.spawn_vehicle_within_specific_radius(VEHICLE_RESOURCE.max_vehicle_spawn_distance)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if vehicle_upside_down:
		vehicle_upside_down = false
		state.angular_velocity.z = mass * 0.01
