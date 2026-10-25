extends CharacterBody2D

class_name Player

var gravity = 1000
var jump = 350
var run_speed = 150
var air_speed = 125
var ground_acceleration = 4000
var ground_decceleration  = 2000
var air_acceleration = 4000
var air_decceleration = 500

var slide_deccelraion = 300

@onready var movements: StateMachine = $movements
@onready var grapple_cooldown: Timer = $movements/grapple_cooldown
@onready var modification_timer: Timer = $modification_timer

var modification_cooldown = 10

func _physics_process(_delta: float) -> void:
	if InputManager.is_action_just_pressed("left_click") and grapple_cooldown.time_left == 0:
		var target = get_grapple_target()
		if target != Vector2.ZERO:
			current_grapple_target = target
			movements.change_state("grapple")

@onready var diee_timer: Timer = $diee_timer


func die():
	diee_timer.start()
	get_tree().paused = true



func _on_modification_timer_timeout() -> void:
	modification_timer.wait_time = modification_cooldown
	modification_timer.start()
	InputManager.randomize()



func _on_diee_timer_timeout() -> void:
	get_tree().paused = false
	position = GameManager.respawn_position
	GameManager.platform_respawn()










## code for auto grappling to hooks ________________________________


@export var grapple_height: float = 150      # The reach (length) of the targeting triangle
@export var grapple_base_width: float = 150.0   # The width of the triangle's base at max reach
@export var terrain_collision_layer: int = 0   # Ensure your TileMap is on this physics layer
@export var debug_show_cone: bool = true      # Toggle debug visualization for the triangle

var current_grapple_target: Vector2 = Vector2.ZERO

func get_grapple_target() -> Vector2:
	var player_pos = global_position
	var mouse_pos = get_global_mouse_position()
	
	if player_pos == mouse_pos:
		return Vector2.ZERO
		
	var dir = (mouse_pos - player_pos).normalized()
	var space_state = get_world_2d().direct_space_state
	
	# --- TASK 1: CHECK HOOKS INSIDE THE CUSTOM TRIANGLE ---
	var best_hook_pos = Vector2.ZERO
	var min_dist_to_centerline = INF
	
	for node in get_tree().get_nodes_in_group("hooks"):
		if not node is Node2D:
			continue
			
		var hook_pos = node.global_position # Exact node position
		var to_hook = hook_pos - player_pos
		
		# 1. Forward distance along aim direction (Height check)
		var forward_dist = to_hook.dot(dir)
		if forward_dist < 0 or forward_dist > grapple_height:
			continue
			
		# 2. Perpendicular distance from the centerline
		var perp_dist = abs(to_hook.cross(dir))
		
		# 3. Allowed width at this specific height
		var max_allowed_width = (forward_dist / grapple_height) * (grapple_base_width / 2.0)
		
		if perp_dist <= max_allowed_width:
			# 4. Line-of-Sight Check: Exclude player AND the hook itself so the ray passes through
			var los_query = PhysicsRayQueryParameters2D.create(player_pos, hook_pos)
			var exclude_list = [get_rid()]
			if node is CollisionObject2D:
				exclude_list.append(node.get_rid())
			los_query.exclude = exclude_list
			los_query.collision_mask = 1 << (terrain_collision_layer - 1)
			
			var los_result = space_state.intersect_ray(los_query)
			
			# If a wall blocks the path to the hook, skip it
			if los_result:
				continue
				
			# Choose the hook closest to the middle of the triangle
			if perp_dist < min_dist_to_centerline:
				min_dist_to_centerline = perp_dist
				best_hook_pos = hook_pos # Forces selection of the exact node position
				
	# If a valid hook was found in the triangle, return its exact node position
	if best_hook_pos != Vector2.ZERO:
		return best_hook_pos
		
	# --- TASK 2: FALLBACK TO TERRAIN RAYCAST (If no hooks found in triangle) ---
	var max_endpoint = player_pos + dir * grapple_height
	var query = PhysicsRayQueryParameters2D.create(player_pos, max_endpoint)
	query.exclude = [get_rid()]
	query.collision_mask = 1 << (terrain_collision_layer - 1)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
			
	return Vector2.ZERO

#---------
var is_grappling: bool = false

func _process(_delta: float) -> void:
	is_grappling = movements.current_state.name == "grapple"
	queue_redraw()

func _draw() -> void:
	# Draw Debug Triangle when aiming (holding left click)
	if debug_show_cone and InputManager.is_action_pressed("left_click") and movements.current_state.name != "grapple":
		var mouse_pos = get_global_mouse_position()
		var aim_dir = (mouse_pos - global_position).normalized()
		if aim_dir != Vector2.ZERO:
			var ortho = Vector2(-aim_dir.y, aim_dir.x)
			var half_width = grapple_base_width / 2.0
			
			# Calculate base corners of the triangle in world space
			var base_center = global_position + aim_dir * grapple_height
			var left_corner = base_center - ortho * half_width
			var right_corner = base_center + ortho * half_width
			
			# Convert to local space for rendering
			var local_left = to_local(left_corner)
			var local_right = to_local(right_corner)
			
			# Draw the targeting triangle lines in semi-transparent yellow
			draw_line(Vector2.ZERO, local_left, Color(1, 1, 0, 0.4), 1.5)
			draw_line(Vector2.ZERO, local_right, Color(1, 1, 0, 0.4), 1.5)
			draw_line(local_left, local_right, Color(1, 1, 0, 0.3), 1.5)

	# Draw Grapple Rope Line when active
	if is_grappling and current_grapple_target != Vector2.ZERO:
		var local_target = to_local(current_grapple_target)
		draw_line(Vector2.ZERO, local_target, Color(0.2, 0.8, 1.0), 3.5, true)
		draw_circle(local_target, 5.0, Color(1.0, 0.4, 0.2))
