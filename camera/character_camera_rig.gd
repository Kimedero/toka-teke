extends Node3D
class_name CharacterCameraRig

var GAME_RESOURCE = preload("res://resources/game_resource.tres")

signal camera_rotated(camera_rotation: Vector2)

@export_category("Character")
@export var character: Character

@export_category("Camera")
@export var main_camera: Camera3D

@export var default_fov: float = 75
@export var aim_fov: float = 45
@export var mouse_sensitivity: float = 0.5 # 0.8
@export var joypad_sensitivity: float = 1.25 # 2.5 # 4.0

@export var side_spring_arm: SpringArm3D
@export var back_spring_arm: SpringArm3D

@export_category("Aim")
signal aim_state(aim_state_bool: bool)
@export var aim_start_speed: float = 0.1
@export var aim_end_speed: float = 0.25


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	GAME_RESOURCE.current_camera = get_viewport().get_camera_3d()
	print_debug("Current camera: %s" % [GAME_RESOURCE.current_camera])
	
	assert(main_camera, "Main camera is not set at %s" % [self])
	
	assert(side_spring_arm, "Side spring arm is not set at %s" % [self])
	assert(back_spring_arm, "Back spring arm is not set at %s" % [self])
	
	# communicating beween camera rig and character mesh
	if character:
		initialize_character()


func initialize_character():
	side_spring_arm.add_excluded_object(character.get_rid())
	back_spring_arm.add_excluded_object(character.get_rid())
	
	aim_state.connect(character.character_mesh.on_character_camera_rig_aim_state)
	camera_rotated.connect(character.character_mesh.on_character_camera_rig_camera_rotated)


func _process(_delta: float) -> void:
	var joypad_motion = Input.get_vector("camera_left","camera_right","camera_forward","camera_back")
	if joypad_motion:
		joypad_rotation(joypad_motion * joypad_sensitivity)


func _input(event: InputEvent) -> void:
	var mouse_movement := event as InputEventMouseMotion
	if mouse_movement:
		mouse_rotation(mouse_movement)
	
	if Input.is_action_just_pressed("aim"):
		aim_process(true)
	if Input.is_action_just_released("aim"):
		aim_process()


func aim_process(aim_state_bool: bool = false) -> void:
	if character:
		var aim_tween := create_tween()
		
		if aim_state_bool:
			aim_tween.tween_property(main_camera, "fov", aim_fov, aim_start_speed)
		else:
			aim_tween.tween_property(main_camera, "fov", default_fov, aim_end_speed)
		
		aim_state.emit(aim_state_bool)


func mouse_rotation(mouse_movement: InputEventMouseMotion):
	#var mouse_rotation_delta: Vector2 = mouse_movement.screen_relative * mouse_sensitivity
	if character:
		camera_rotation(mouse_movement.screen_relative)


func joypad_rotation(joypad_motion: Vector2) -> void:
	if character:
		camera_rotation(joypad_motion, joypad_sensitivity)


func camera_rotation(rotation_motion: Vector2, controller_sensitivity: float = mouse_sensitivity) -> void:
	var mouse_rotation_delta: Vector2 = rotation_motion * controller_sensitivity
	character.rotation_degrees.y -= mouse_rotation_delta.x
	rotation_degrees.x -= mouse_rotation_delta.y
	rotation_degrees.x = clampf(rotation_degrees.x, -45, 60)
	
	#print("Cam Rot: %s - %s" % [main_camera.global_rotation_degrees.y, main_camera.global_basis])
	
	camera_rotated.emit(mouse_rotation_delta)
