extends CharacterBody2D

const SPEED = 380.0

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	
	if !is_multiplayer_authority():
		return
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	move_and_slide()
