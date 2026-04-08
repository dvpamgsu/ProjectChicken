extends "res://scene/player/player.gd"

func _enter_tree() -> void:
	pass
	
func _ready() -> void:
	basic_ready()
	
	#position = main.stage.spawn_1.position
	initial_pos = position
	flip_dir = 1
	
	sprite_2d.texture = load("res://texture/player/skin001.png")
