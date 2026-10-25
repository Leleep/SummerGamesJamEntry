extends State

@onready var player:Player = get_parent().get_parent()
@onready var jump_buffer: Timer = $"../jump_buffer"

var jump 
var air_speed 
var gravity 
var air_acceleration
var air_decceleration
var jump_cut = false

func enter():
	jump = player.jump
	air_acceleration = player.air_acceleration
	air_decceleration = player.air_decceleration
	air_speed = player.air_speed
	gravity = player.gravity
	
	player.velocity.y = -jump
	jump_cut = false

func physics_update(_delta:float):
	var dir = InputManager.get_axis("left","right")
	if not (InputManager.is_action_pressed("jump") or jump_cut):
		if not jump_cut:
			player.velocity.y*=(0.6)
			jump_cut = true
			
	player.velocity.y+=gravity*_delta
	
	if jump_cut and InputManager.is_action_just_pressed("jump"):
		jump_buffer.start()
	
	if dir!=0:
		player.velocity.x = move_toward(player.velocity.x,dir*air_speed,air_acceleration*_delta)
	else:
		player.velocity.x = move_toward(player.velocity.x,0,air_decceleration*_delta)
	player.move_and_slide()
	
	##transition
	if player.is_on_floor():
		if not dir:
			state_machine.change_state("idle")
		else:
			state_machine.change_state("run")
