extends Sprite2D

var timer = 0.0
var main

func _ready() -> void:
	main = get_node("/root/Main")
	frame = main.rng.randi_range(0,3)
	
func _physics_process(delta: float) -> void:
	timer += delta
	if timer > 0.2:
		if frame == 3:
			frame = 0
		else:
			frame += 1
		while timer > 0.2:
			timer -= 0.2
	
