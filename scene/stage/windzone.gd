extends Area2D

@onready var color_rect: ColorRect = $ColorRect


var force = 50000.0

var timer = 0.0
const max_time = 1.5
func _physics_process(delta: float) -> void:
	pass
	#timer += delta
	#timer = wrapf(timer, 0.0, max_time)
	#force = 20000.0 + 5000.0*sin(timer/max_time*TAU)
	#color_rect.modulate.a = (force/25000.0)

func _on_body_entered(body: Node2D) -> void:
	if body.alive:
		body.is_wind = true
		body.wind = self
		


func _on_body_exited(body: Node2D) -> void:
	body.is_wind = false
