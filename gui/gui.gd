extends Control

var VEHICLE_RESOURCE = preload("res://vehicles/resources/vehicle_resource.tres")

@onready var vehicle_info_label: Label = $VBoxContainer/vehicleInfoLabel

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	vehicle_info_label.text = "Spawned Vehicles: %s" % [VEHICLE_RESOURCE.spawned_vehicles_array.size()]
