extends "res://scene/player/player.gd"

func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	position = main.stage.spawn_1.position
	initial_pos = position
	flip_dir = 1
	
