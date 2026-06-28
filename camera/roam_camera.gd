extends Camera3D

@export_range(1, 100) var speed: float = 50

var forward_back_input: float
var side_to_side_input: float
var up_down_input: float

func _process(delta: float) -> void:
	global_position.z += forward_back_input * speed * delta
	global_position.x += side_to_side_input * speed * delta
	global_position.y += up_down_input * speed * delta
	
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction := (transform.basis * Vector3(side_to_side_input * speed, 0, forward_back_input * speed)).normalized()
	#global_position = direction


func _input(_event: InputEvent) -> void:
	forward_back_input = Input.get_axis("accelerate","brake")
	side_to_side_input = Input.get_axis("camera_left","camera_right")
	up_down_input = Input.get_axis("camera_up","camera_down")

	
