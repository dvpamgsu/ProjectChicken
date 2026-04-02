extends "res://scene/player/player.gd"

func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	var rim = main.stage.rim
	var shadow = main.stage.shadow
	var rimt = main.stage.rim_thickness
	mat.set_shader_parameter("rim_intensity", rim)
	mat.set_shader_parameter("shadow_intensity", shadow)
	mat.set_shader_parameter("rim_thickness", rimt)
	
	position = main.stage.spawn_1.position
	initial_pos = position
	flip_dir = 1
	
