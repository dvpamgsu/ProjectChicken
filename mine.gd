extends Area2D

var respawn_timer = 0.0
var respawn_time = 5.0

func _on_body_entered(body: Node2D) -> void:
	if visible:
		body.apply_central_impulse(((body.position-position).normalized() + Vector2.UP*0.1) * 2500.0)
		respawn_timer = 0.0
		visible = false
		for p in players:
			p.particle_timer = 0.5

func _physics_process(delta: float) -> void:
	if !visible:
		respawn_timer += delta
		if respawn_timer > respawn_time:
			visible = true

var players = []

func _on_area_2d_body_entered(body: Node2D) -> void:
	players.append(body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	players.erase(body)
