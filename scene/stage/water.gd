extends ColorRect

var main
var mat = material as ShaderMaterial
@export var _y = 96.0
func _ready():
	main = get_node("/root/Main")

func _physics_process(delta: float) -> void:
	var y = _y
	y -= (main.camera_2d.position.y - main.height/2.0)
	y /= main.height
	y = clamp(y, 0.0, 1.0)
	mat.set_shader_parameter("water_line_y", y)
