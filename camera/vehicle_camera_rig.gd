extends Node3D
class_name VehicleCameraRig

@export var camera_vehicle: Vehicle
@export var camera_height := 1.6

var direction: Vector3 = Vector3.FORWARD
@export_range(1, 10, 0.1) var smooth_speed := 2.5

@export var spring_arm: SpringArm3D
@export var camera: Camera3D

##To keep track of when the mouse is moved
#var mouse_moved := false
#var mouse_resetting := false
#@export var mouse_reset_time := 3
#var mouse_reset_delta: float

#old
var camera_reset_delta: float
var camera_reset_timeout: float = 3.0

## A signal to indicate to all and sundry that the camera has been spawned
signal camera_spawned(vehicle: Vehicle)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	assert(spring_arm, "Spring arm is not set %s!" % [self])
	assert(camera, "Camera is not set %s!" % [self])
	
	if camera_vehicle:
		# we allow nodes to load before initializing the camera
		call_deferred("initialize", [camera_vehicle])


func _physics_process(delta: float) -> void:
	if not camera_vehicle:
		return
	global_position = camera_vehicle.position + Vector3.UP * camera_height
	
	var current_velocity := camera_vehicle.linear_velocity
	current_velocity.y = 0
	if current_velocity.length_squared() > 9.0:
		direction = lerp(direction, current_velocity.normalized(), smooth_speed * delta)
		
	global_transform.basis = get_rotation_from_direction(direction)
	
	# if the camera is off-axis
	reset_camera_rotation(delta)


func _input(event: InputEvent) -> void:
	var mouse_movement = event as InputEventMouseMotion
	if mouse_movement:
		spring_arm.rotation_degrees.y -= mouse_movement.relative.x * 0.2
		spring_arm.rotation_degrees.x -= mouse_movement.relative.y * 0.2
		spring_arm.rotation_degrees.x = clamp(spring_arm.rotation_degrees.x, -75, 15)
		
		camera_reset_delta = 0


func initialize(vehicle: Vehicle) -> void:
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_vehicle = vehicle
	camera.current = true
	
	camera_spawned.emit(vehicle)
	
	if camera_vehicle:
		spring_arm.add_excluded_object(camera_vehicle)
	else:
		self.camera.current = false


func get_rotation_from_direction(look_direction: Vector3) -> Basis:
	look_direction = look_direction.normalized()
	var x_axis := look_direction.cross(Vector3.UP)
	return Basis(x_axis, Vector3.UP, -look_direction)


func reset_camera_rotation(delta: float) -> void:
	if not is_zero_approx(spring_arm.rotation.y):
		camera_reset_delta += delta
		
	if camera_reset_delta >= camera_reset_timeout:
		spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, 0.0, 5 * delta)
		if is_zero_approx(spring_arm.rotation.y):
			camera_reset_delta = 0
