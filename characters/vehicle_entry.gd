extends Area3D
class_name VehicleEntry

@export var character: Character

func _ready() -> void:
	assert(character, "Character is not set at %s" % [self])


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("enter_exit_vehicle"):
		var vehicles_nearby_array: Array = get_overlapping_bodies()
		for veh in vehicles_nearby_array:
			if veh is not Vehicle:
				vehicles_nearby_array.erase(veh)
		if not vehicles_nearby_array.is_empty():
			print("Found vehicles: %s!" % [vehicles_nearby_array])
		else:
			print("No vehicles found nearby!")
