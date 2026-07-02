extends RayCast3D

@onready var vehicle: Vehicle = get_parent()

## reduces the number of upside down checks
var upside_down_check: int


func _physics_process(_delta: float) -> void:
	upside_down_check = wrapi(upside_down_check+1, 0, 30)
	if upside_down_check == 0:
		if self.is_colliding():
			vehicle.vehicle_upside_down = true
