@tool
extends Control

@onready var format_transition_paths_button: Button = $VBoxContainer/PanelContainer/VBoxContainer/FormatTransitionPathsButton

var max_transition_path_points: float = 21

func _ready() -> void:
	format_transition_paths_button.pressed.connect(on_format_transition_paths_button_pressed)


func on_format_transition_paths_button_pressed() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		var fellow_transition_paths_dict: Dictionary
		if selected_node is Marker3D and "transition" in selected_node.name.to_lower():
			var trans_paths_array: Array = selected_node.get_children()
			#var original_trans_paths_array: Array = trans_paths_array.duplicate()
			#print("'%s' selected! - Paths: %s" % [selected_node.name, trans_paths_array.size()])
			
			for path_1: Path3D in trans_paths_array:
				for path_2: Path3D in trans_paths_array:
					if path_1 != path_2:
						var path_1_start_point: Vector3 = path_1.curve.get_point_position(0)
						var path_1_end_point: Vector3 = path_1.curve.get_point_position(path_1.curve.point_count - 1)
						
						var path_2_start_point: Vector3 = path_2.curve.get_point_position(0)
						var path_2_end_point: Vector3 = path_2.curve.get_point_position(path_2.curve.point_count - 1)
						
						var distance_path_1_start_path_2_start: float = path_1_start_point.distance_squared_to(path_2_start_point)
						var distance_path_1_start_path_2_end: float = path_1_start_point.distance_squared_to(path_2_end_point)
						
						if distance_path_1_start_path_2_start <= pow(max_transition_path_points, 2) and distance_path_1_start_path_2_end <= pow(max_transition_path_points, 2):
							print("%s - %s -> %s - %s" % [path_1.name, sqrt(distance_path_1_start_path_2_start), path_2.name, sqrt(distance_path_1_start_path_2_end)])
