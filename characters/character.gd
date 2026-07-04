extends CharacterBody3D
class_name Character

var GAME_RESOURCE = preload("res://resources/game_resource.tres")

enum CHARACTER_CONTROL {AUTO, MANUAL}
@export var character_control: CHARACTER_CONTROL

var active: bool = true

@export var character_mesh: CharacterMesh
## where the camera is placed on a character's head
@export var camera_pos: Marker3D

var speed = 5.0
@export var walk_speed = 5.0
@export var run_speed = 8.0

@export var max_jump_height: float = 0.8 # 65

var input_dir: Vector2

@export var collision_shapes_array: Array[CollisionShape3D]

# to mark the character as on board a vehicle
var driving: bool = false

func _ready() -> void:
	assert(character_mesh, "Character mesh is not set at %s" % [self])
	assert(camera_pos, "Camera pos is not set at %s" % [self])
	
	assert(collision_shapes_array, "Collision shapes array is not set at %s" % [self])


func _physics_process(delta: float) -> void:
	if active:
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		match character_control:
			CHARACTER_CONTROL.MANUAL:
				manual_control()
			_:
				pass
			
		move_and_slide()
	
	$Label3D.text = "Camera Rot:Y -> %.2f" % [
		GAME_RESOURCE.current_camera.global_rotation_degrees.y,
		#GAME_RESOURCE.current_camera.get_parent(),
	]


func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("sprint"):
		speed = run_speed
	else:
		speed = walk_speed


func process_jump():
	return sqrt(2.0 * max_jump_height * -get_gravity().y)


func manual_control():
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = process_jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)


func vehicle_entry_process(process_enabled: bool) -> void:
	# a function to disable all collision shapes and hide the character
	active = !process_enabled
	
	for shape: CollisionShape3D in collision_shapes_array:
		shape.disabled = process_enabled
		
	self.visible = !process_enabled
