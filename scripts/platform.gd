extends StaticBody2D
@export var width=1.0
@export var break_time=5.0
@onready var platform_shape: CollisionShape2D = $PlatformShape
@onready var detection_shape: CollisionShape2D = $DetectionArea/DetectionShape
@onready var timer: Timer = $DetectionArea/Timer
var timer_flag=false
var tile_size=24

func _ready() -> void:
	platform_shape.scale=Vector2(width/tile_size,1.0)
	detection_shape.scale=Vector2(width/tile_size,1.0)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("palyer"):
		if !timer_flag:
			timer_flag=true
			timer.start(break_time)

func _on_timer_timeout() -> void:
#	can add an animation/tween here
	queue_free()
