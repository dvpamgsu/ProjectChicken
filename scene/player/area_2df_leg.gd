extends Area2D

var alive = true
@onready var player = get_parent().get_parent()

func _process(delta: float) -> void:
	alive = player.alive
