@tool
extends Control

# PATH VISIBILITY
@onready var visibility_on_button: Button = $PathsVisibilityPanelContainer/PathsVisibility/VisibilityHBoxContainer/VisibilityOnButton
@onready var visibility_off_button: Button = $PathsVisibilityPanelContainer/PathsVisibility/VisibilityHBoxContainer/VisibilityOffButton

# CSG POLYGON GENERATION
@onready var generate_transition_paths_button: Button = $GenerateTransitionPathsPanelContainer/GenerateTransitionPaths/GenerateTransitionPathsButton
@onready var generate_transition_paths_spin_box: SpinBox = $GenerateTransitionPathsPanelContainer/GenerateTransitionPaths/HBoxContainer/GenerateTransitionPathsSpinBox
@onready var generate_transition_paths_width_spin_box: SpinBox = $GenerateTransitionPathsPanelContainer/GenerateTransitionPaths/VBoxContainer/GenerateTransitionPathsWidthHBoxContainer/GenerateTransitionPathsWidthSpinBox
@onready var generate_transition_paths_height_spin_box: SpinBox = $GenerateTransitionPathsPanelContainer/GenerateTransitionPaths/VBoxContainer/GenerateTransitionPathsHeightHBoxContainer/GenerateTransitionPathsHeightSpinBox
@onready var generate_transition_paths_color_picker_button: ColorPickerButton = $GenerateTransitionPathsPanelContainer/GenerateTransitionPaths/HBoxContainer2/GenerateTransitionPathsColorPickerButton

var connected_navigation_paths_dict: Dictionary

# CSG POLYGON
@onready var csg_polygon_width_spin_box: SpinBox = $CreateAndDeleteCSGPolygonsPanelContainer/CreateAndDeleteCSGPolygons/CSGPolygonHeightAndWeightHBoxContainer/CSGPolygonWidthSpinBox
@onready var csg_polygon_height_spin_box: SpinBox = $CreateAndDeleteCSGPolygonsPanelContainer/CreateAndDeleteCSGPolygons/CSGPolygonHeightAndWeightHBoxContainer2/CSGPolygonHeightSpinBox
@onready var csg_polygon_color_picker_button: ColorPickerButton = $CreateAndDeleteCSGPolygonsPanelContainer/CreateAndDeleteCSGPolygons/CSGPolygonColortHBoxContainer/CSGPolygonColorPickerButton
@onready var delete_csg_polygons_button: Button = $CreateAndDeleteCSGPolygonsPanelContainer/CreateAndDeleteCSGPolygons/DeleteCSGPolygonsButton
@onready var create_csg_polygons_button: Button = $CreateAndDeleteCSGPolygonsPanelContainer/CreateAndDeleteCSGPolygons/CreateCSGPolygonsButton

# CSG POLYGON MATERIAL
const SCROLLING_SHADER: Shader = preload("./shaders/scrolling_chevron.gdshader")
const CHEVRON_TEXTURE = preload("./shaders/chevron.png")

# REVERSING PATH DIRECTION
@onready var path_reverser_button: Button = $PathReverserPanelContainer/VBoxContainer/PathReverserButton

# PATH ADJUSTMENT
# PATH ADJUSTMENT BY
@onready var path_adjustment_by_spin_box: SpinBox = $AdjustPathPointsPanelContainer/AdjustPathPointsByVBoxContainer/AdjustPathPointsByHBoxContainer/PathAdjustmentBySpinBox
@onready var adjust_path_points_by_button: Button = $AdjustPathPointsPanelContainer/AdjustPathPointsByVBoxContainer/AdjustPathPointsByVBoxContainer/AdjustPathPointsByButton
# PATH ADJUSTMENT TO
@onready var path_adjustment_to_spin_box: SpinBox = $AdjustPathPointsPanelContainer/AdjustPathPointsByVBoxContainer/AdjustPathPointsToHBoxContainer/PathAdjustmentToSpinBox
@onready var adjust_path_points_to_button: Button = $AdjustPathPointsPanelContainer/AdjustPathPointsByVBoxContainer/AdjustPathPointsToVBoxContainer/AdjustPathPointsToButton

# SHORTENING PATH
@onready var path_shorten_by_spin_box: SpinBox = $ShortenPathByPanelContainer/ShortenPathByVBoxContainer/PathShortenByHBoxContainer/PathShortenBySpinBox
@onready var shorten_path_by_button: Button = $ShortenPathByPanelContainer/ShortenPathByVBoxContainer/ShortenPathByVBoxContainer/ShortenPathByButton

# MOVE PATH POINTS
@onready var path_points_x_spin_box: SpinBox = $MovePathPointsContainer/MovePathPointsVBoxContainer/MovePathPointsHBoxContainer/PathPointsXSpinBox
@onready var path_points_y_spin_box: SpinBox = $MovePathPointsContainer/MovePathPointsVBoxContainer/MovePathPointsHBoxContainer/PathPointsYSpinBox
@onready var path_points_z_spin_box: SpinBox = $MovePathPointsContainer/MovePathPointsVBoxContainer/MovePathPointsHBoxContainer/PathPointsZSpinBox
@onready var move_path_points_by_button: Button = $MovePathPointsContainer/MovePathPointsVBoxContainer/MovePathPointsVBoxContainer/MovePathPointsByButton


func _ready() -> void:
	visibility_on_button.pressed.connect(_on_visibility_check_button_toggled.bind(true))
	visibility_off_button.pressed.connect(_on_visibility_check_button_toggled.bind(false))
	
	generate_transition_paths_button.pressed.connect(generate_transition_paths)
	
	create_csg_polygons_button.pressed.connect(create_csg_polygons)
	delete_csg_polygons_button.pressed.connect(delete_all_csg_polygons)
	
	path_reverser_button.pressed.connect(on_path_reverser_button_pressed)
	
	adjust_path_points_by_button.pressed.connect(on_adjust_path_points_button_by_pressed)
	adjust_path_points_to_button.pressed.connect(on_adjust_path_points_button_to_pressed)
	
	shorten_path_by_button.pressed.connect(on_shorten_path_by_button_pressed)
	
	move_path_points_by_button.pressed.connect(on_move_path_points_by_button_pressed)


func _on_visibility_check_button_toggled(toggled_on: bool) -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					for node_grand_child in node_child.get_children():
						toggle_csg_visibility(node_grand_child, toggled_on)
		# selected paths
		elif selected_node is Path3D:
			for selected_node_child in selected_node.get_children():
				toggle_csg_visibility(selected_node_child, toggled_on)
		elif selected_node is CSGPolygon3D:
			toggle_csg_visibility(selected_node, toggled_on)


func toggle_csg_visibility(csg_node: CSGPolygon3D, visibility: bool) -> void:
	if csg_node is CSGPolygon3D:
		var original_visibility: bool = csg_node.visible
		
		csg_node.visible = visibility


func generate_transition_paths() -> void:
	print("Starting transition paths generation...")
	var selected_nodes_array := EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			var parent_marker_node := generate_transition_path_hub(selected_node)
			print("Found a marker! - Parent Node: %s" % [parent_marker_node])
			process_paths(selected_node, parent_marker_node)
			#for sel_node_child in selected_node.get_children():
				#if sel_node_child is Path3D:
					##process_paths(sel_node_child, parent_marker_node)
					#print("Childs: %s" % [sel_node_child])
					#pass


func generate_transition_path_hub(sel_node: Marker3D) -> Marker3D:
	#print("Selected: %s - Parent: %s" % [sel_node.name, sel_node.get_parent().name])
	var node_parent: Node3D = sel_node.get_parent()
	
	var new_marker_3d := Marker3D.new()
	node_parent.add_child(new_marker_3d)
	new_marker_3d.name = "TransitionPaths"
	new_marker_3d.owner = node_parent.get_tree().edited_scene_root
	return new_marker_3d


func process_paths(selected_node: Node3D, parent_marker: Marker3D) -> void:
	var navigation_paths_array: Array = selected_node.get_children()
	
	var navigation_paths_ends_dict: Dictionary = {}
	# storing where paths start and end points are, as a dictionary
	for path: Path3D in navigation_paths_array:
		var path_start_point: Vector3 = path.curve.get_point_position(0)
		var path_end_point: Vector3 = path.curve.get_point_position(path.curve.point_count - 1)
		navigation_paths_ends_dict[path] = {
			"start_pos": path_start_point, 
			"end_pos": path_end_point }
			
	# we go through all path extremities and check how close one path's end is to the start of another path
	#for path: Path3D in navigation_paths_ends_dict:
	for path: Path3D in navigation_paths_array:
		## an array that holds all connected paths to a particular path
		var nearest_paths_array: Array = []
		## a dictionary that holds all connected paths to a particular path and the closest distance to each
		var nearest_paths_dict: Dictionary = {}
		#for other_path: Path3D in navigation_paths_ends_dict:
		for other_path: Path3D in navigation_paths_array:
			if path != other_path:
				var curr_path_end_pos: Vector3 = navigation_paths_ends_dict[path].end_pos
				var other_path_start_pos: Vector3 = navigation_paths_ends_dict[other_path].start_pos
				var closest_distance_to_other_path_start: float = curr_path_end_pos.distance_squared_to(other_path_start_pos)
				var max_connected_navigation_path_distance: int = generate_transition_paths_spin_box.value
				if closest_distance_to_other_path_start <= pow(max_connected_navigation_path_distance, 2.0):
					print("%s - %s: closest_distance_to_other_path_start: %s" % [path.name, other_path.name, sqrt(closest_distance_to_other_path_start)])
					nearest_paths_array.append(other_path)
					nearest_paths_dict[other_path] = closest_distance_to_other_path_start
					#print("%s - %s - %s" % [path.name, other_path.name, path_distance])
		connected_navigation_paths_dict[path] = nearest_paths_array
		print(" - ")
		
	#print("Connected paths dict: %s" % [connected_navigation_paths_dict])
	for main_path: Path3D in connected_navigation_paths_dict.keys():
		for other_path: Path3D in connected_navigation_paths_dict[main_path]:
			generate_new_path(main_path, other_path, parent_marker)
			#generate_new_path_polygon(main_path, parent_marker)


func generate_new_path(main_path: Path3D, other_path: Path3D, parent_marker: Marker3D):
	print("Main path: %s - Other Path: %s - Marker: %s" % [main_path.name, other_path.name, parent_marker])
	var new_path := Path3D.new()
	parent_marker.add_child(new_path)
	new_path.owner = parent_marker.get_tree().edited_scene_root
	new_path.name = "%s_to_%s_Path3D" % [main_path.name, other_path.name]
	
	var main_path_end_pos: Vector3 = main_path.curve.get_point_position(main_path.curve.point_count - 1)
	var other_path_start_pos: Vector3 = other_path.curve.get_point_position(0)
	#var middle_point_pos: Vector3 = main_path_end_pos+(main_path_end_pos-other_path_start_pos)
	
	var new_curve_3d := Curve3D.new()
	new_curve_3d.add_point(main_path_end_pos)
	var paths_mid_point: Vector3 = (main_path_end_pos+other_path_start_pos) * 0.5
	new_curve_3d.add_point(paths_mid_point)
	new_curve_3d.add_point(other_path_start_pos)
	new_path.curve = new_curve_3d
	
	generate_new_path_polygon(new_path, generate_transition_paths_color_picker_button.color, generate_transition_paths_width_spin_box.value, generate_transition_paths_height_spin_box.value)


func create_csg_polygons() -> void:
	delete_all_csg_polygons()
	
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					generate_new_path_polygon(node_child, csg_polygon_color_picker_button.color, csg_polygon_width_spin_box.value, csg_polygon_height_spin_box.value)
		# selected paths
		elif selected_node is Path3D:
			generate_new_path_polygon(selected_node, csg_polygon_color_picker_button.color, csg_polygon_width_spin_box.value, csg_polygon_height_spin_box.value)


func delete_all_csg_polygons():
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					for node_grand_child in node_child.get_children():
						delete_selected_csg_polygons(node_grand_child)
		# selected paths
		elif selected_node is Path3D:
			for selected_node_child in selected_node.get_children():
				delete_selected_csg_polygons(selected_node_child)
		elif selected_node is CSGPolygon3D:
			delete_selected_csg_polygons(selected_node)


func generate_new_path_polygon(path_parent: Path3D, csg_polygon_color: Color, csg_polygon_width: float, csg_polygon_height: float):
	if path_parent is Path3D:
		var new_csg_polygon := CSGPolygon3D.new()
		path_parent.add_child(new_csg_polygon)
		new_csg_polygon.owner = path_parent.get_tree().edited_scene_root
		new_csg_polygon.name = "GeneratedCSGPolygon3D"
		
		new_csg_polygon.mode = CSGPolygon3D.MODE_PATH
		
		new_csg_polygon.path_node =  NodePath("..")
		
		new_csg_polygon.polygon = PackedVector2Array([
			Vector2(-csg_polygon_width * 0.5, 0),
			Vector2(-csg_polygon_width * 0.5, csg_polygon_height + 0.25),
			Vector2(csg_polygon_width * 0.5, csg_polygon_height),
			Vector2(csg_polygon_width * 0.5, 0),
			])
		
		var new_shader_material: ShaderMaterial = ShaderMaterial.new()
		new_shader_material.shader = SCROLLING_SHADER
		new_shader_material.set_shader_parameter("main_texture", CHEVRON_TEXTURE)
		new_shader_material.set_shader_parameter("extra_color", csg_polygon_color) # Color.DEEP_SKY_BLUE
		
		new_csg_polygon.material = new_shader_material


func delete_selected_csg_polygons(csg_polygon: Node) -> void:
	if csg_polygon is CSGPolygon3D:
		csg_polygon.queue_free()


func on_adjust_path_points_button_by_pressed() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					adjust_path_points_by(node_child, path_adjustment_by_spin_box.value)
		# selected paths
		elif selected_node is Path3D:
			adjust_path_points_by(selected_node, path_adjustment_by_spin_box.value)


func adjust_path_points_by(path: Path3D, adjustment_value: float) -> void:
	for idx in path.curve.point_count:
		var curr_point: Vector3 = path.curve.get_point_position(idx)
		#print("path: %s - %s" % [idx, curr_point])
		curr_point.y += adjustment_value
		path.curve.set_point_position(idx, curr_point)
		#print("path: %s - %s" % [idx, curr_point])
	#print("Selected path: %s adjusted by %s" % [path, adjustment_value])


func on_adjust_path_points_button_to_pressed() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					adjust_path_points_to(node_child, path_adjustment_to_spin_box.value)
		# selected paths
		elif selected_node is Path3D:
			adjust_path_points_to(selected_node, path_adjustment_to_spin_box.value)


func adjust_path_points_to(path: Path3D, adjustment_value: float) -> void:
	for idx in path.curve.point_count:
		var curr_point: Vector3 = path.curve.get_point_position(idx)
		print("path: %s - %s" % [idx, curr_point])
		curr_point.y = adjustment_value
		path.curve.set_point_position(idx, curr_point)
		print("path: %s - %s" % [idx, curr_point])
	
	print("Selected path: %s adjusted to %s" % [path, adjustment_value])


func on_shorten_path_by_button_pressed() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					shorten_path_by(node_child, path_shorten_by_spin_box.value)
		# selected paths
		elif selected_node is Path3D:
			shorten_path_by(selected_node, path_shorten_by_spin_box.value)


func shorten_path_by(curr_path: Path3D, shortening_value: float):
	var path_start_point: Vector3 = curr_path.curve.get_point_position(0)
	
	var end_pos_index: int = curr_path.curve.point_count - 1
	var path_end_point: Vector3 = curr_path.curve.get_point_position(end_pos_index)
	
	# shortening the path end - we start with this in order to not deal with array order
	var end_offset: float = curr_path.curve.get_closest_offset(path_end_point) - shortening_value
	var end_shortened_pos: Vector3 = curr_path.curve.sample_baked(end_offset)
	curr_path.curve.set_point_position(end_pos_index, end_shortened_pos)
	#curr_path.curve.add_point(end_shortened_pos)
	#curr_path.curve.remove_point(curr_path.curve.point_count - 1)
	
	# shortening the path start
	var start_offset: float = curr_path.curve.get_closest_offset(path_start_point) + shortening_value
	var start_shortened_pos: Vector3 = curr_path.curve.sample_baked(start_offset)
	curr_path.curve.set_point_position(0, start_shortened_pos)
	#curr_path.curve.add_point(start_shortened_pos)
	#curr_path.curve.remove_point(0)
	#print("Shortening %s by %s - Path start: %s - end: %s" % [curr_path.name, shortening_value, start_shortened_pos, end_shortened_pos])
	
	
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


func on_move_path_points_by_button_pressed() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	var move_path_points: Vector3 = Vector3(path_points_x_spin_box.value, path_points_y_spin_box.value, path_points_z_spin_box.value)
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			# The parent node where paths are stored
			var node_children_array: Array = selected_node.get_children()
			for node_child in node_children_array:
				if node_child is Path3D:
					move_path_points_by(node_child, move_path_points)
		# selected paths
		elif selected_node is Path3D:
			move_path_points_by(selected_node, move_path_points)


func move_path_points_by(curr_path: Path3D, move_points_value: Vector3) -> void:
	for idx: int in curr_path.curve.point_count:
		var curr_point: Vector3 = curr_path.curve.get_point_position(idx)
		curr_path.curve.set_point_position(idx, curr_point + move_points_value)
		print("Point %s - %s - %s" % [idx, curr_point, move_points_value])
	print("%s points shifted by %s" % [curr_path, move_points_value])
