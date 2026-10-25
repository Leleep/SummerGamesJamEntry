@tool
extends StaticBody2D
class_name Spike

@export_range(2, 50) var width: int = 2:
	set(value):
		width = value
		_update_size()
@export var break_time = 5.0
@export var breakable = false
@onready var platform_shape: CollisionShape2D = $PlatformShape
@onready var detection_shape: CollisionShape2D = $DetectionArea/DetectionShape
@onready var timer: Timer = $DetectionArea/Timer
@onready var platform_tiles: NinePatchRect = $PlatformTiles

var timer_flag = false
var breaking = false
var tile_size = 16
var thickness = 6

func _ready() -> void:
	_update_size()
	GameManager.platforms.append(self)

func _update_size() -> void:
	if not is_node_ready():
		return
	platform_shape.scale = Vector2(width, 1.0)
	detection_shape.scale = Vector2(width, 1.0)
	platform_tiles.size = Vector2(width * tile_size, thickness)
	platform_tiles.position = Vector2(-width * tile_size / 2.0, -thickness / 2.0)
	timer.wait_time = break_time

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()

func break_start():
	if breaking:
		return
	breaking=true
	if !timer_flag:
		timer_flag=true
		timer.start(break_time)

func _on_timer_timeout() -> void:
#	can add an animation/tween here
	if breakable:
		toggle(true)

func toggle(x:bool):
	platform_shape.set_deferred("disabled",x)
	detection_shape.set_deferred("disabled",x)
	set_deferred("visible",!x)
	set_deferred("breaking",x)
	set_deferred("timer_flag",x)
