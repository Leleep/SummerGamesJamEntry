class_name StateMachine extends Node

@export var initial_state:State

var current_state:State
var states:Dictionary[String,State] = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			child.state_machine = self
			states[child.name.to_lower()] = child
	
	if initial_state:
		initial_state.enter()
		current_state = initial_state 

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func change_state(state_name:String):
	var next_state:State = states[state_name.to_lower()]
	
	assert(next_state,"state not found: "+state_name)
	
	if current_state:
		current_state.exit()
	
	next_state.enter()
	current_state = next_state
