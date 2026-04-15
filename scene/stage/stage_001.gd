extends "res://scene/stage/stage.gd"

const BIRD_2 = preload("uid://djtleyejpnr2j")

var bird2timer = 10.0
func _stage_process(delta):
	bird2timer += delta
	if bird2timer > 15.0:
		var b2 = BIRD_2.instantiate()
		add_child(b2)
		bird2timer = 0.0
