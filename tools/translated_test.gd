@tool
extends Node3D

@onready var arrow_1: MeshInstance3D = $Arrow1
@onready var arrow_2: MeshInstance3D = $Arrow2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	arrow_2.global_transform = arrow_1.global_transform.translated_local(Vector3.LEFT * 2)
