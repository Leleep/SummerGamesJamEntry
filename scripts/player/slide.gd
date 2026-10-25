extends State

@onready var player:Player = get_parent().get_parent()
@onready var cayote_timer: Timer = $"../cayote_timer"
@onready var jump_buffer: Timer = $"../jump_buffer"

var gravity
var ground_decceleration

func enter():
	ground_decceleration = player.slide_deccelraion

func physics_update(_delta:float):
	var dir = InputManager.get_axis("left","right")
	
	if not InputManager.is_action_pressed('down'):
		if dir:
			state_machine.change_state('run')
		else:
			state_machine.change_state('idle')
	
	if not player.is_on_floor():
		state_machine.change_state('idle')
	
	player.velocity.x = move_toward(player.velocity.x,0,ground_decceleration*_delta)	
	player.move_and_slide()
	
	#transition
	if InputManager.is_action_just_pressed("jump") and (player.is_on_floor() or cayote_timer.time_left>0):
		state_machine.change_state("jump")
