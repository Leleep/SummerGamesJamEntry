extends Area2D
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var killzone: Area2D = get_tree().get_first_node_in_group("killzone")
@onready var checkpoint_shape: CollisionShape2D = $CheckpointShape

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.respawn_position = spawn_point.global_position
		killzone.global_position.y = spawn_point.global_position.y + 48
		checkpoint_shape.set_deferred("disabled", true)
		
		var platforms = get_tree().get_nodes_in_group("breakable")
		var prev_platforms: Array[Platform] = []
		
		# Iterate through all nodes, but only process those that are specifically Platforms
		for node in platforms:
			if node is Platform: 
				if is_instance_valid(node) and node.global_position.y > spawn_point.global_position.y:
					prev_platforms.append(node)
					
		prev_platforms.sort_custom(sort_descending)
		
		for p: Platform in prev_platforms:
			if is_instance_valid(p):
				p.break_start()
			await get_tree().create_timer(0.5).timeout

func sort_descending(a: Platform, b: Platform) -> bool:
	return a.global_position.y > b.global_position.y
