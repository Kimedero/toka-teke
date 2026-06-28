@tool
extends EditorPlugin

var dock: EditorDock

const VEHICLE_PARAMETERS = preload("./vehicle_tools_panel.tscn")

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	
	dock = EditorDock.new()
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_UL
	
	var vehicle_parameters_panel = VEHICLE_PARAMETERS.instantiate()
	dock.add_child(vehicle_parameters_panel)
	
	add_dock(dock)



func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_dock(dock)
	dock.queue_free()
