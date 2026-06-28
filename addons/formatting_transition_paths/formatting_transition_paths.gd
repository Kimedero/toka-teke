@tool
extends EditorPlugin

var dock: EditorDock

const FORMATTING_TRANSITION_PATHS_PANEL = preload("./formatting_transition_paths_panel.tscn")


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	dock = EditorDock.new()
	dock.default_slot = EditorDock.DOCK_SLOT_RIGHT_BL
	
	dock.add_child(FORMATTING_TRANSITION_PATHS_PANEL.instantiate())
	
	add_dock(dock)


func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
