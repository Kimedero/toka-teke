@tool
extends VBoxContainer

# PATH REVERSING
@onready var path_reverser_button: Button = $PathReverserPanelContainer/VBoxContainer/PathReverserButton

# SPAWNING LANE PATHS
@onready var path_spawning_spin_box: SpinBox = $PathSpawningPanelContainer/VBoxContainer/HBoxContainer/PathSpawningSpinBox
@onready var path_spawning_button: Button = $PathSpawningPanelContainer/VBoxContainer/PathSpawningButton

#var spawned_lanes_node: Marker3D

var spawn_shift_distance: float = 4
var spawn_direction_calculation_safe_offset: float = 0.1

# DEBUG
const CHEVRON_TEXTURE = preload("./shaders/chevron.png")
const SCROLLING_SHADER = preload("./shaders/scrolling_chevron.gdshader")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path_reverser_button.pressed.connect(on_path_reverser_button_pressed)
	
	path_spawning_button.pressed.connect(on_path_spawning_button_pressed)


func on_path_reverser_button_pressed():
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Path3D:
			path_reverser(selected_node)
	

func path_reverser(path: Path3D):
	if path.curve:
		# an array of points on the path that we can reverse
		var path_points_array: Array = []
		var path_points_in_array: Array = []
		var path_points_out_array: Array = []
		var path_points_tilt_array: Array = []
		
		for idx in path.curve.point_count:
			var path_point: Vector3 = path.curve.get_point_position(idx)
			path_points_array.append(path_point)
			var path_point_in: Vector3 = path.curve.get_point_in(idx)
			path_points_in_array.append(path_point_in)
			var path_point_out: Vector3 = path.curve.get_point_out(idx)
			path_points_out_array.append(path_point_out)
			var path_points_tilt = path.curve.get_point_tilt(idx)
			path_points_tilt_array.append(path_points_tilt)
		
		path_points_array.reverse()
		path_points_in_array.reverse()
		path_points_out_array.reverse()
		path_points_tilt_array.reverse()
		
		for idx in path_points_array.size():
			path.curve.set_point_position(idx, path_points_array[idx])
			path.curve.set_point_in(idx, -path_points_in_array[idx])
			path.curve.set_point_out(idx, -path_points_out_array[idx])
			path.curve.set_point_tilt(idx, -path_points_tilt_array[idx])
		
	#var path_curve = path.curve
		print("Ting! %s - Array: %s - In: %s - Out: %s - Tilt: %s" % [path.name, path_points_array, path_points_in_array, path_points_out_array, path_points_tilt_array])
	else:
		print("No curve found for %s" % [path.name])


func on_path_spawning_button_pressed():
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	var spawn_node_root = EditorInterface.get_edited_scene_root() # .get_node("Navigation")
	var new_marker: Marker3D
	if not selected_nodes_array.is_empty(): # and (not spawned_lanes_node):
		new_marker = Marker3D.new()
		new_marker.name = "SpawnedLanePaths"
		spawn_node_root.add_child(new_marker)
		new_marker.owner = spawn_node_root.get_tree().edited_scene_root
		#spawned_lanes_node = new_marker
	for selected_node in selected_nodes_array:
		if selected_node is Path3D:
			var initial_left_path := spawn_lane_path(selected_node, new_marker)
			initial_left_path.name = "%s_Initial_Left_Path" % [selected_node.name]
			path_reverser(selected_node)
			var second_path := spawn_lane_path(selected_node, new_marker)
			second_path.name = "%s_Second_Path" % [selected_node.name]


func spawn_lane_path(path: Path3D, spawn_node: Marker3D) -> Path3D:
	# we create the first left path
	var initial_left_path := Path3D.new()
	#initial_left_path.name = "%s_Initial_Left_Path" % [path.name]
	spawn_node.add_child(initial_left_path)
	initial_left_path.owner = spawn_node.get_tree().edited_scene_root
	
	var new_initial_left_curve := Curve3D.new()
	initial_left_path.curve = new_initial_left_curve
	
	var new_csg_polygon := CSGPolygon3D.new()
	initial_left_path.add_child(new_csg_polygon)
	new_csg_polygon.owner = initial_left_path.get_tree().edited_scene_root
	new_csg_polygon.name = "GeneratedCSGPolygon3D"
	new_csg_polygon.mode = CSGPolygon3D.MODE_PATH
	new_csg_polygon.path_node =  NodePath("..")
	new_csg_polygon.path_simplify_angle = 1 # 	0
	var csg_polygon_width = 0.4
	var csg_polygon_height = 0.1
	new_csg_polygon.polygon = PackedVector2Array([
			Vector2(-csg_polygon_width * 0.5, 0),
			Vector2(-csg_polygon_width * 0.5, csg_polygon_height + 0.25),
			Vector2(csg_polygon_width * 0.5, csg_polygon_height),
			Vector2(csg_polygon_width * 0.5, 0),
			])
	var new_shader_material: ShaderMaterial = ShaderMaterial.new()
	new_shader_material.shader = SCROLLING_SHADER
	new_shader_material.set_shader_parameter("main_texture", CHEVRON_TEXTURE)
	new_shader_material.set_shader_parameter("extra_color", Color.ORANGE_RED) # Color.DEEP_SKY_BLUE)
	new_csg_polygon.material = new_shader_material
	
	for idx: int in path.curve.point_count:
		var path_point: Vector3 = path.curve.get_point_position(idx)
		##the point in and point out work but need some tweaking
		#var path_point_in: Vector3 = path.curve.get_point_in(idx)
		#var path_point_out: Vector3 = path.curve.get_point_out(idx)
		#var path_point_tilt: float = path.curve.get_point_tilt(idx)
		var shifted_path_point: Vector3 = generate_shifted_position(path, path_point, path_spawning_spin_box.value)
		new_initial_left_curve.add_point(shifted_path_point)
		#new_initial_left_curve.set_point_in(idx, path_point_in) # * path_spawning_spin_box.value)
		#new_initial_left_curve.set_point_out(idx, path_point_out) # * path_spawning_spin_box.value)
		#new_initial_left_curve.set_point_tilt(idx, path_point_tilt)
	return initial_left_path


func generate_shifted_position(curr_path: Path3D, pos: Vector3, spawn_shift: float) -> Vector3:
	var path_length: float = curr_path.curve.get_baked_length()
	var pos_offset: float = curr_path.curve.get_closest_offset(pos)
	var back_offset: float = maxf(pos_offset - spawn_direction_calculation_safe_offset, 0)
	var forward_offset: float = minf(pos_offset + spawn_direction_calculation_safe_offset, path_length)
	var back_pos: Vector3 = curr_path.curve.sample_baked(back_offset)
	var forward_pos :Vector3 = curr_path.curve.sample_baked(forward_offset)
	var direction: Vector3 = forward_pos.direction_to(back_pos)
	var cross: Vector3 = direction.normalized().cross(Vector3.UP)
	# we can also use some geometry calculations to ensure that in a curve the position can be adjusted
	# accordingly
	return pos + cross * spawn_shift
