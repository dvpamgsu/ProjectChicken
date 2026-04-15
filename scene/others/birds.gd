extends Node2D

var main

func _ready() -> void:
	main = get_node("/root/Main")
	global_position.x = main.rng.randf_range(-main.width/2-256, -main.width/2-32)
	global_position.y = main.rng.randf_range(-main.height/8*3, -main.height/8)

func _physics_process(delta: float) -> void:
	global_position.x += delta * 10.0
	if position.x > main.width:
		global_position.x = main.rng.randf_range(-main.width/2-256, -main.width/2-32)
		global_position.y = main.rng.randf_range(-main.height/8*3, -main.height/8)
	#print(position.x)
	
