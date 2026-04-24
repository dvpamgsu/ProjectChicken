extends ColorRect
@export var factor = 1.0
var _offset := Vector2.ZERO

var main
var cam

@export var has_bound = false
@export var boundary_min_y = 0
@export var boundary_max_y = 0

func _ready() -> void:
	main = get_node("/root/Main")
	_offset = global_position
	cam = main.camera_2d

func _physics_process(delta: float) -> void:
	position.x = cam.position.x * (1.0-factor) + _offset.x
	position.y = cam.position.y * (1.0-factor) + _offset.y
	
	if has_bound:
		position.y = clamp(position.y, boundary_min_y, boundary_max_y)
