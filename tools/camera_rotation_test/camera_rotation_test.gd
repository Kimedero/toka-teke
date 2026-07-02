extends Node3D


@onready var cam_rig_1: Node3D = $CamRig1
@onready var cam_1_spring_arm_3d: SpringArm3D = $CamRig1/SpringArm3D
@onready var cam_1_camera_3d: Camera3D = $CamRig1/SpringArm3D/Camera3D

@onready var cam_rig_2: Node3D = $CamRig2
@onready var cam_2_spring_arm_3d: SpringArm3D = $CamRig2/SpringArm3D
@onready var cam_2_camera_3d: Camera3D = $CamRig2/SpringArm3D/Camera3D

@onready var info_label: Label = $infoLabel

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	cam_1_spring_arm_3d.global_rotation_degrees.y += delta * 16
	cam_2_spring_arm_3d.global_rotation_degrees.y -= delta * 12
	cam_2_camera_3d.global_rotation.y = cam_1_camera_3d.global_rotation.y
	
	info_label.text = "Camera rot:y: %d\nCamera global rot:y: %d\nSpring arm rot:y: %d\nSpring arm global rot:y: %d" % [
		cam_1_camera_3d.rotation_degrees.y,
		cam_1_camera_3d.global_rotation_degrees.y,
		cam_1_spring_arm_3d.rotation_degrees.y,
		cam_1_spring_arm_3d.global_rotation_degrees.y,
		]
