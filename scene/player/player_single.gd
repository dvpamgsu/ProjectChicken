extends "res://scene/player/player.gd"

func _enter_tree() -> void:
	pass
	
func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	sprite_2d.material = sprite_2d.material.duplicate()
	mat = sprite_2d.material as ShaderMaterial
	
	position = main.stage.spawn_1.position
	initial_pos = position
	flip_dir = 1
	
	sprite_2d.texture = load("res://texture/player/skin001.png")
