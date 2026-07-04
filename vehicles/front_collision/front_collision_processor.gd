extends ShapeCast3D
class_name FrontCollisionProcessor

@export var vehicle: Vehicle

@export var vehicle_controller: VehicleController

@export var ray_length: float = 8 # 10 # 8 # 6 # 8 # 12 # 4
var hit_length: float
## what percentage of the shape cast from the start should count towards the start of collision detection
@export var safe_collision_pct: float = 0.64
## a percentage length from the part where we zero out the drive factor to where the shape cast starts 
@export var brake_factor_pct: float = 0.4 # 8

## the distance to allow in front of the vehicle 
@export var collision_buffer_length: float = 2 # 1.5

@export var collision_check_factor: float = 0.64

var collision_check_skip: int = 6
var collision_check_delta: int = 5

#var front_vehicle_speed_kmh: float

func _ready() -> void:
	assert(vehicle, "Vehicle is not set at %s!" % [self])
	assert(vehicle_controller, "Vehicle controller is not set at %s!" % [self])
	
	self.add_exception_rid(vehicle.get_rid())
	self.target_position = Vector3.BACK * ray_length


# the higher the factor is, the less the vehicle is obstructed
func collision_factor_process() -> float:
	var collision_length: float = get_current_shapecast_length()
	var actual_collision_length: float = maxf(collision_length - collision_buffer_length, 0)
	var collision_factor: float = actual_collision_length / (ray_length - collision_buffer_length)
	return collision_factor


func get_current_shapecast_length() -> float:
	if self.is_colliding() and self.get_collider(0) is Vehicle:
		return self.get_collision_point(0).distance_to(self.global_position)
	return ray_length


#func get_collision_factor_array() -> Array:
	#var hit_length: float = get_hit_length()
	#
	#var unused_length: float = ray_length * collision_check_factor
	#var used_length: float = ray_length * (1 - collision_check_factor)
	#
	## as the hit length becomes shorter, we reduce the drive input up to zero
	## at the collision check factor point
	#var drive_factor: float = maxf(hit_length - unused_length, 0.0)
	## at 10 -> 0
	## at 6.4 -> 1
	#
	## after the hit length becomes shorter than the set maximum unused length, we 
	## increase the braking very quickly -> NOT SURE: the higher the number the faster to brake
	#var max_braking_length: float = unused_length * 0.5 # 0.64
	#
	#var braking_factor = clampf(hit_length - unused_length, -max_braking_length, 0.0)
	## at 6.4 -> 0
	## at 3.2 -> 1
	#
	## we multiply the braking so it's instant
	##return [absf(drive_factor / used_length), absf(braking_factor / max_braking_length) * 4]
	#return [absf(drive_factor / used_length), absf(braking_factor / max_braking_length)]
	##return [pow(drive_factor / used_length, 1.5), absf(braking_factor / max_braking_length)] # soft exponential slowdown


func get_collision_factor_array() -> Array:
	hit_length = calculate_hit_length()
	return [get_drive_factor(), get_brake_factor()]


func calculate_hit_length() -> float:
	if self.is_colliding():
		for idx: int in self.get_collision_count():
			var collider: Object = self.get_collider(idx)
			if collider:
				var curr_hit_point: Vector3
				if collider is VehicleBody3D:
					## when we detect a vehicle in front we change the current target speed to its speed
					#front_vehicle_speed_kmh = collider.current_speed_kmph
					vehicle_controller.current_target_speed = minf(collider.current_speed_kmph, vehicle.max_target_speed)
				
					curr_hit_point = self.get_collision_point(idx)
					return self.global_position.distance_to(curr_hit_point)
				elif collider is CharacterBody3D:
					curr_hit_point = self.get_collision_point(idx)
					return self.global_position.distance_to(curr_hit_point)
				elif collider.is_in_group("building") or collider.is_in_group("wall"):
					print("%s - %s" % [vehicle.name, collider])
					curr_hit_point = self.get_collision_point(idx)
					return self.global_position.distance_to(curr_hit_point)
	vehicle_controller.current_target_speed = vehicle.max_target_speed
	return ray_length


func get_brake_factor() -> float:
	## the point at which drive is at 0
	var brake_start_point: float = ray_length * safe_collision_pct
	## the distance between the start of the shape cast and where drive is at 0
	var red_line_collision_point: float = brake_start_point * brake_factor_pct
	## the distance in consideration is from where the drive factor is zero'd out to where the brake factor is at maximums
	var modified_hit_length: float = maxf(minf(hit_length, brake_start_point), red_line_collision_point) - red_line_collision_point
	return maxf(1 - (modified_hit_length / red_line_collision_point), 0.0)


func get_drive_factor() -> float:
	# the point at which to cut off drive and apply brakes
	var red_line_collision_point: float = ray_length * safe_collision_pct
	## the distance at the end of the shape cast between which we apply full drive to zero drive
	var safe_collision_length: float = ray_length - red_line_collision_point
	
	var current_collision_length: float = maxf(hit_length - red_line_collision_point, 0)
	return current_collision_length / safe_collision_length


func get_hit_length() -> float:
	if self.is_colliding():
		for idx in self.get_collision_count():
			#if (get_collider(idx) is VehicleBody3D or get_collider(idx) is CharacterBody3D):
			var collider := self.get_collider(idx)
			if collider is VehicleBody3D or collider is CharacterBody3D or collider.is_in_group("building") or collider.is_in_group("wall"):
				#if collider.is_in_group("building"):
					#print("%s just hit a building - %s" % [vehicle.name, collider.get_parent().name])
				return self.global_position.distance_to(self.get_collision_point(idx))
	return ray_length
