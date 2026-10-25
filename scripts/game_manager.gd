extends Node

var respawn_position
var player:Player

var platforms = []

func platform_respawn():
	for platform in platforms:
		platform.toggle(false)
		platform.timer.start()
		platform.timer.stop()
