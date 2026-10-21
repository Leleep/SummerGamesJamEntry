extends Area2D
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var killzone: Area2D = get_tree().get_first_node_in_group("killzone")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.respawn_position=spawn_point.global_position
		killzone.global_position.y=spawn_point.global_position.y+72
