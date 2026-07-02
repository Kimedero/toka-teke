extends ShapeCast3D
class_name FrontCollisionProcessor

@export var vehicle: Vehicle

@export var shape_cast_length: float = 8 # 10 # 8 # 6 # 8 # 12 # 4
## the distance to allow in front of the vehicle 
@export var collision_buffer_length: float = 2 # 1.5

@export var collision_check_factor: float = 0.64

var collision_check_skip: int = 6
var collision_check_delta: int = 5

func _ready() -> void:
	assert(vehicle, "Vehicle is not set at %s!" % [self])
	
	self.add_exception_rid(vehicle.get_rid())
	self.target_position.z = shape_cast_length


# the higher the factor is, the less the vehicle is obstructed
func collision_factor_process() -> float:
	var collision_length: float = get_current_shapecast_length()
	var actual_collision_length: float = maxf(collision_length - collision_buffer_length, 0)
	var collision_factor: float = actual_collision_length / (shape_cast_length - collision_buffer_length)
	return collision_factor


func get_current_shapecast_length() -> float:
	if self.is_colliding() and self.get_collider(0) is Vehicle:
		return self.get_collision_point(0).distance_to(self.global_position)
	return shape_cast_length


func get_collision_factor_array() -> Array:
	var hit_length: float = get_hit_length()
	
	var unused_length: float = shape_cast_length * collision_check_factor
	var used_length: float = shape_cast_length * (1 - collision_check_factor)
	
	# as the hit length becomes shorter, we reduce the drive input up to zero
	# at the collision check factor point
	var drive_factor: float = maxf(hit_length - unused_length, 0.0)
	# at 10 -> 0
	# at 6.4 -> 1
	
	# after the hit length becomes shorter than the set maximum unused length, we 
	# increase the braking very quickly -> NOT SURE: the higher the number the faster to brake
	var max_braking_length: float = unused_length * 0.5 # 0.64
	
	var braking_factor = clampf(hit_length - unused_length, -max_braking_length, 0.0)
	# at 6.4 -> 0
	# at 3.2 -> 1
	
	# we multiply the braking so it's instant
	return [absf(drive_factor / used_length), absf(braking_factor / max_braking_length) * 4]
	#return [pow(drive_factor / used_length, 1.5), absf(braking_factor / max_braking_length)] # soft exponential slowdown


func get_hit_length() -> float:
	if self.is_colliding():
		for idx in self.get_collision_count():
			#if (get_collider(idx) is VehicleBody3D or get_collider(idx) is CharacterBody3D):
			var collider := self.get_collider(idx)
			if collider is VehicleBody3D or collider is CharacterBody3D or collider.is_in_group("building") or collider.is_in_group("wall"):
				#if collider.is_in_group("building"):
					#print("%s just hit a building - %s" % [vehicle.name, collider.get_parent().name])
				return self.global_position.distance_to(self.get_collision_point(idx))
	return shape_cast_length
