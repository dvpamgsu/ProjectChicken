extends Node2D

enum DIRECTION {LEFT, RIGHT}
@export var direction := DIRECTION.LEFT
@export var length := 3

@export var BELT_SPRITES = []

var parts = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var s
	
	for i in range(length):
		s = Sprite2D.new()
		if i == 0:
			if direction == DIRECTION.RIGHT:
				s.texture = BELT_SPRITES[0]
			else:
				s.texture = BELT_SPRITES[2]
		elif i == length-1:
			if direction == DIRECTION.RIGHT:
				s.texture = BELT_SPRITES[2]
			else:
				s.texture = BELT_SPRITES[0]
		else:
			s.texture = BELT_SPRITES[1]
		s.hframes = 4
		s.position.x = -16.0*float(length)/2.0 + 8.0 + i * 16.0
		s.position.y = 8.0
		if direction == DIRECTION.LEFT:
			s.flip_h = true
		add_child(s)
		parts.append(s)

var timer = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if timer > 0.08:
		for p in parts:
			if p.frame == p.hframes - 1:
				p.frame = 0
			else:
				p.frame += 1
		timer -= 0.08
