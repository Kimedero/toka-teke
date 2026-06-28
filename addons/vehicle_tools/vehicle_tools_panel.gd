@tool
extends Control

# VehicleBody
@onready var mass_spin_box: SpinBox = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/MassHBoxContainer/MassSpinBox

var new_physics_material: PhysicsMaterial
@onready var physics_material_check_box: CheckBox = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/PhysicsMaterialHBoxContainer/PMHBoxContainer/PhysicsMaterialCheckBox
@onready var pm_grid_container: GridContainer = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/PhysicsMaterialHBoxContainer/PMGridContainer
@onready var friction_spin_box: SpinBox = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/PhysicsMaterialHBoxContainer/PMGridContainer/FrictionHBoxContainer/FrictionSpinBox
@onready var rough_check_box: CheckBox = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/PhysicsMaterialHBoxContainer/PMGridContainer/RoughHBoxContainer/RoughCheckBox
@onready var bounce_spin_box: SpinBox = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/PhysicsMaterialHBoxContainer/PMGridContainer/BounceHBoxContainer/BounceSpinBox
@onready var absorbent_check_box: CheckBox = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/PhysicsMaterialHBoxContainer/PMGridContainer/AbsorbentHBoxContainer/AbsorbentCheckBox
@onready var comm_option_button: OptionButton = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/COMMHBoxContainer/COMMOptionButton

@onready var body_parameters_button: Button = $VehicleBodyPanelContainer/VehicleBodyVBoxContainer/BodyParametersButton

var physics_material_on := true

@onready var body_collision_shape_button: Button = $VehicleCollisionShapePanelContainer/VehicleCollisionShapeVBoxContainer/BodyCollisionShapeButton

# VehicleWheel
@onready var suspension_stiffness_spin_box: SpinBox = $VehicleWheelsPanelContainer/VehicleWheelsVBoxContainer/SuspensionStiffnessHBoxContainer/SuspensionStiffnessSpinBox
@onready var wheel_parameters_button: Button = $VehicleWheelsPanelContainer/VehicleWheelsVBoxContainer/WheelParametersButton


func _ready() -> void:
	physics_material_check_box.toggled.connect(on_physics_material_check_box_toggled)
	
	body_parameters_button.pressed.connect(set_body_general_parameters)
	
	body_collision_shape_button.pressed.connect(on_body_collision_shape_button_pressed)
	
	wheel_parameters_button.pressed.connect(on_wheel_parameters_button_pressed)


func on_physics_material_check_box_toggled(toggled_on: bool = true) -> void:
	pm_grid_container.visible = toggled_on
	
	if toggled_on:
		physics_material_on = true
	else:
		physics_material_on = false


func set_body_general_parameters() -> void:
	var selected_nodes_array := EditorInterface.get_selection().get_selected_nodes()
	if selected_nodes_array.is_empty():
		var root_node = EditorInterface.get_edited_scene_root()
		for node in root_node.get_children():
			if node is VehicleBody3D:
				apply_vehicle_bodyparams(node)
	else:
		for selected_node in selected_nodes_array:
			if selected_node is VehicleBody3D:
				apply_vehicle_bodyparams(selected_node)


func apply_vehicle_bodyparams(vehicle_body: VehicleBody3D):
	# mass
	vehicle_body.mass = mass_spin_box.value
	
	# physics material
	#if physics_material_check_box.button_pressed:
	if physics_material_on:
		new_physics_material = PhysicsMaterial.new()
		new_physics_material.friction = friction_spin_box.value
		new_physics_material.rough = rough_check_box.button_pressed
		new_physics_material.bounce = bounce_spin_box.value
		new_physics_material.absorbent = absorbent_check_box.button_pressed
		vehicle_body.physics_material_override = new_physics_material
	else:
		vehicle_body.physics_material_override = null
	
	# center of mass mode
	var comm_value: int = comm_option_button.get_selected_id()
	match comm_value:
		0:
			vehicle_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
		1:
			vehicle_body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	print("COMM: %s" % [comm_value, ])


func on_body_collision_shape_button_pressed() -> void:
	var root_node = EditorInterface.get_edited_scene_root()
	for node in root_node.get_children():
		if node is CollisionShape3D:
			node.queue_free()
		
		if node is MeshInstance3D and "body" in node.name.to_lower():
			var aabb: AABB = node.get_aabb()
			
			var new_collision_shape = CollisionShape3D.new()
			new_collision_shape.name = "%s_CollisionShape3D" % [node.name]
			
			var new_box_shape := BoxShape3D.new()
			new_collision_shape.shape = new_box_shape
			new_box_shape.size = aabb.size
			
			root_node.add_child(new_collision_shape)
			new_collision_shape.position = aabb.get_center()
			new_collision_shape.owner = root_node
			print("Body: %s - %s" % [node, aabb])


func on_wheel_parameters_button_pressed() -> void:
	var root_node = EditorInterface.get_edited_scene_root()
	for node in root_node.get_children():
		if node is VehicleWheel3D:
			set_wheel_general_parameters(node)
	#var selected_nodes_array := EditorInterface.get_selection().get_selected_nodes()
	#if selected_nodes_array.is_empty():
	#else:
		#for wheel in selected_nodes_array:
			#if wheel is VehicleWheel3D:
				#set_wheel_general_parameters(wheel)


func set_wheel_general_parameters(curr_wheel: VehicleWheel3D) -> void:
	curr_wheel.use_as_traction = true
	
	# detecting if the current wheel is the front wheel
	if curr_wheel.name.to_lower().begins_with("f"):
		curr_wheel.use_as_steering = true
		
	curr_wheel.suspension_stiffness = suspension_stiffness_spin_box.value
	
	if curr_wheel.get_child_count() > 0:
		# it's almost a given that the VehicleWheel has only one child which is the wheel mesh
		var wheel_mesh = curr_wheel.get_child(0)
		var new_wheel_radius: float
		if wheel_mesh is MeshInstance3D:
			var wheel_mesh_size: Vector3 = wheel_mesh.get_aabb().size
			if is_zero_approx(wheel_mesh_size.x - wheel_mesh_size.y):
				new_wheel_radius = wheel_mesh_size.x * 0.5
				curr_wheel.wheel_radius = new_wheel_radius
			elif is_zero_approx(wheel_mesh_size.x - wheel_mesh_size.z):
				new_wheel_radius = wheel_mesh_size.x * 0.5
				curr_wheel.wheel_radius = new_wheel_radius
			elif is_zero_approx(wheel_mesh_size.y - wheel_mesh_size.z):
				new_wheel_radius = wheel_mesh_size.y * 0.5
				curr_wheel.wheel_radius = new_wheel_radius
			else:
				print("No two sides of the wheel mesh match in size! Setting to biggest size")
				var wheel_sizes_array: Array = [wheel_mesh_size.x, wheel_mesh_size.y, wheel_mesh_size.z]
				curr_wheel.wheel_radius = wheel_sizes_array.max() * 0.5
			#print("new_wheel_radius: %s - %s  - %s" % [new_wheel_radius, wheel_mesh_size, wheel_mesh_size.x - wheel_mesh_size.z])
			#wheel_radius_label.text += "Whee: '%s' - Radius: %.3f\n" % [curr_wheel.name, new_wheel_radius]
			
	print("Wheel: %s" % [curr_wheel])
