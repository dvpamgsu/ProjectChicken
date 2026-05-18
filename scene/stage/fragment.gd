extends RigidBody2D

var force = Vector2.ZERO
var tq = 0
var g = 0.0
func _ready():
	g = gravity_scale
	gravity_scale = 0.0
	await get_tree().create_timer(0.1).timeout
	apply_central_impulse(force)
	apply_torque_impulse(tq)
	gravity_scale = g

func _physics_process(delta: float) -> void:
	if position.y >= 2000:
		queue_free()
