extends Sprite2D

var speed := 0.5
var main

func _ready() -> void:
	main = get_node('/root/Main')
	frame = main.rng.randi_range(0, 2)
	flip_h = true if main.rng.randf() > 0.5 else false

func _physics_process(delta: float) -> void:
	position.x += speed * delta
	
	if speed > 0:
		if position.x > main.width/2 + get_rect().size.x:
			queue_free()
	elif speed < 0:
		if position.x < -main.width/2 - get_rect().size.x:
			queue_free()
