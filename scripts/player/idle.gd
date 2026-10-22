extends State

@onready var player:Player = get_parent().get_parent()
@onready var cayote_timer: Timer = $"../cayote_timer"
@onready var jump_buffer: Timer = $"../jump_buffer"

var gravity
var ground_decceleration
var air_decceleration

func enter():
	ground_decceleration = player.ground_decceleration
	air_decceleration = player.air_decceleration
	gravity = player.gravity

func physics_update(_delta:float):
	var dir = Input.get_axis("left","right")
	
	if not player.is_on_floor():
		player.velocity.y += gravity*_delta
		player.velocity.x = move_toward(player.velocity.x,0,air_decceleration*_delta)
	
	else:
		player.velocity.x = move_toward(player.velocity.x,0,ground_decceleration*_delta)
		
		if jump_buffer.time_left>0:
			state_machine.change_state("jump")
	
	player.move_and_slide()
	
	#transition
	if Input.is_action_pressed('shift'):
		state_machine.change_state('slide')
	if dir!=0:
		state_machine.change_state("run")
	elif Input.is_action_just_pressed("jump") and (player.is_on_floor() or cayote_timer.time_left>0):
		state_machine.change_state("jump")
