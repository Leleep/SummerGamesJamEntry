extends State

@onready var player:Player = get_parent().get_parent()

@onready var grapple_cooldown: Timer = $"../grapple_cooldown"
@onready var grapple_timer: Timer = $"../grapple_timer"
@onready var checkbox: Area2D = $"../../checkbox"

var target_position:Vector2
var grapple_acceleration = 1000
var max_speed = 300
var min_dist = 20

var init_length
var temp_switch = true

func enter():
	target_position = player.current_grapple_target
	init_length = player.global_position.distance_to(target_position)
	temp_switch = true
	grapple_timer.start()
	grapple_cooldown.start()


func physics_update(_delta:float):
	var distance = player.global_position.distance_to(target_position)
	var pull_dir = player.global_position.direction_to(target_position).normalized()
	var desired_velocity = pull_dir*max_speed*init_length
	
	player.velocity = player.velocity.lerp(desired_velocity,grapple_acceleration* _delta)
	player.velocity = player.velocity.limit_length(max_speed)
	player.move_and_slide()
	
	if distance<=min_dist:
		state_machine.change_state("idle")
		
	if InputManager.is_action_just_pressed("left_click"):
		if temp_switch: temp_switch = false
		else: state_machine.change_state('idle')

func exit():
	grapple_timer.start()
	grapple_timer.stop()

func _on_grapple_timer_timeout() -> void:
	state_machine.change_state('idle')


func _on_checkbox_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	state_machine.change_state('idle')
