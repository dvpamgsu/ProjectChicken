extends Node2D

var main:Node2D
var cam:Camera2D

func _ready() -> void:
	main = get_node("/root/Main")
	cam = main.camera_2d
	scale.x = 1.0/cam.zoom.x
	scale.y = 1.0/cam.zoom.y
	pass

func _physics_process(delta: float) -> void:
	scale.x = 1.0/cam.zoom.x
	scale.y = 1.0/cam.zoom.y
	position = cam.position - Vector2(main.width/2.0,main.height/2.0)
	
