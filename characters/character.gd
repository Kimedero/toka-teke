extends CharacterBody3D
class_name Character

enum CHARACTER_CONTROL {AUTO, MANUAL}
@export var character_control: CHARACTER_CONTROL

@export var character_mesh: CharacterMesh
## where the camera is placed on a character's head
@export var camera_pos: Marker3D

var speed = 5.0
@export var walk_speed = 5.0
@export var run_speed = 8.0

@export var max_jump_height: float = 0.8 # 65

var input_dir: Vector2

func _ready() -> void:
	assert(character_mesh, "Character mesh is not set at %s" % [self])
	assert(camera_pos, "Camera pos is not set at %s" % [self])

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match character_control:
		CHARACTER_CONTROL.MANUAL:
			manual_control()
		_:
			pass
		
	move_and_slide()


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
