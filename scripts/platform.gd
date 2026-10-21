extends StaticBody2D
@export var width=1.0
@export var break_time=5.0
@onready var platform_shape: CollisionShape2D = $PlatformShape
@onready var detection_shape: CollisionShape2D = $DetectionArea/DetectionShape
@onready var timer: Timer = $DetectionArea/Timer
var timer_flag=false

func _ready() -> void:
	var scale_ratio= Vector2(width,1.0)
	platform_shape.apply_scale(scale_ratio)
	detection_shape.apply_scale(scale_ratio)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("palyer"):
		if !timer_flag:
			timer.start(break_time)

func _on_timer_timeout() -> void:
#	can add an animation/tween here
	queue_free()
