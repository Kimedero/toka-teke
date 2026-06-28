@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var selected_nodes_array: Array = EditorInterface.get_selection().get_selected_nodes()
	for selected_node in selected_nodes_array:
		if selected_node is Marker3D:
			for node in selected_node.get_children():
				if node is Path3D:
					if "Path0" in node.name:
						var new_string: String = node.name.replace("Path0", "SmallPlacePath0")
						node.name = new_string
