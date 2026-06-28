class_name StateMachine
extends Node

@export var start_state: State
var state_map_dict: Dictionary
var current_state: State = null
var active: bool


func _ready() -> void:
	create_state_map()
	initialize_state(start_state)


func _physics_process(delta: float) -> void:
	current_state.process_state(delta)


func _input(event: InputEvent) -> void:
	current_state.input_state(event)


func create_state_map() -> void:
	for child: State in get_children():
		child.state_finished.connect(change_state)
		state_map_dict[child.name] = child
	#print("State map dict: %s" % [state_map_dict])


func initialize_state(state: State) -> void:
	set_active(true)
	current_state = state
	current_state.enter_state()


func set_active(active_value: bool) -> void:
	active = active_value
	set_physics_process(active_value)
	set_process_input(active_value)
	if not active:
		current_state = null


func change_state(state_name: String) -> void:
	if not active:
		return
	# Exiting out the old state
	current_state.exit_state()
	# Selecting the new state
	current_state = state_map_dict[state_name]
	current_state.enter_state()
