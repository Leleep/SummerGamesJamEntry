extends State

@onready var player:Player = get_parent().get_parent()
@onready var cayote_timer: Timer = $"../cayote_timer"
@onready var jump_buffer: Timer = $"../jump_buffer"

var speed
var air_speed 
var ground_acceleration
var ground_decceleration
var air_acceleration
var air_decceleration

var gravity
var cayote_switch = true

func enter():
	speed = player.run_speed
	air_speed = player.air_speed
	air_acceleration = player.air_acceleration
	air_decceleration = player.air_decceleration
	ground_acceleration = player.ground_acceleration
	ground_decceleration = player.ground_decceleration
	gravity = player.gravity

func physics_update(_delta:float):
	var dir = InputManager.get_axis("left","right")
	
	if not player.is_on_floor():
		if cayote_switch:
			cayote_timer.start()
			cayote_switch = false
		player.velocity.y += gravity*_delta
	else:
		if jump_buffer.time_left>0 :state_machine.change_state("jump")
		cayote_switch = true
	
	var going_fast = abs(player.run_speed)<abs(player.velocity.x)
	
	if dir!=0:
		if player.is_on_floor():
			if going_fast:
				player.velocity.x = move_toward(player.velocity.x,dir*speed,ground_decceleration*_delta)
			else:
				player.velocity.x = move_toward(player.velocity.x,dir*speed,ground_acceleration*_delta)
		else:
			if going_fast:
				player.velocity.x = move_toward(player.velocity.x,dir*air_speed,air_decceleration*_delta)
			else:
				player.velocity.x = move_toward(player.velocity.x,dir*air_speed,air_acceleration*_delta)
	else:
		state_machine.change_state('idle')
	player.move_and_slide()
	
	## transitions
	if InputManager.is_action_just_pressed('down'):
		state_machine.change_state('slide')
	if InputManager.is_action_just_pressed("jump") and (player.is_on_floor() or cayote_timer.time_left>0):
		state_machine.change_state("jump")
