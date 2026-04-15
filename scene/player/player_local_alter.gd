extends "res://scene/player/player.gd"

func _enter_tree() -> void:
	pass
	
func _ready() -> void:
	basic_ready()
	
	#position = main.stage.spawn_2.position
	initial_pos = position
	flip_dir = -1
	
	
func get_direction():
	return Input.get_axis("left2", "right2")
func get_flip():
	if Input.is_action_just_pressed("flip2"):
		return flip_dir * -1
	return flip_dir
func get_jump():
	if Input.is_action_just_pressed("jump2"):
		return 1
	if Input.is_action_pressed("jump2"):
		return 2
	if Input.is_action_just_released("jump2"):
		return 3
	return 0
