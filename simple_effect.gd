extends Sprite2D
@export var rate = 0.1
@onready var main = get_node("/root/Main")
@export var ma = false

func _ready():
	main.effects.append(self)

var timer = 0.0
func _process(delta: float) -> void:
	#if !is_multiplayer_authority():
		#return
	timer += delta
	if timer >= rate:
		while timer >= rate:
			timer -= rate
		if frame >= hframes - 1:
			queue_free()
		else:
			frame += 1	
