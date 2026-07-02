@tool
extends EditorScript

# ground - building

# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	var selected_nodes_array = EditorInterface.get_selection().get_selected_nodes()
	for current_node in selected_nodes_array:
		#current_node.remove_from_group("building") # , true)
		if current_node is MeshInstance3D:
			var mesh_children_array = current_node.get_children()
			for child in mesh_children_array:
				if child is StaticBody3D:
					child.add_to_group("building" , true)
					child.owner = current_node.get_tree().edited_scene_root
					print("%s is it!" % [child])
