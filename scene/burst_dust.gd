extends RigidBody2D

@export var cs := GradientTexture1D.new()
@onready var main = get_node("/root/Main")
@onready var timer = main.rng.randf() * 0.2

func _ready() -> void:
	linear_velocity = Vector2.UP.rotated(main.rng.randf_range(-PI/2.0,PI/2.0))*main.rng.randf_range(50.0,1000.0)
	angular_velocity = main.rng.randf_range(-100.0,100.0)
	$Sprite2D.scale.x = main.rng.randf_range(1.0, 2.0)
	$Sprite2D.scale.y = $Sprite2D.scale.x
func _physics_process(delta: float) -> void:
	modulate = cs.gradient.sample(timer)
	timer += delta
	
	if timer > 1.0:
		queue_free()
