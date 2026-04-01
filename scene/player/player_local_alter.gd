extends "res://scene/player/player.gd"

func _enter_tree() -> void:
	set_multiplayer_authority(1)
	
func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	var rim = main.stage.rim
	var shadow = main.stage.shadow
	var mat = sprite_2d.material as ShaderMaterial
	mat.set_shader_parameter("rim_intensity", rim)
	mat.set_shader_parameter("shadow_intensity", shadow)
	
	position = main.stage.spawn_2.position
	initial_pos = position
	flip_dir = -1
	

func _physics_process(delta: float) -> void:
	
	super(delta)
	
	
func get_jump():
	if Input.is_action_just_pressed("jump2"):
		return 1
	if Input.is_action_pressed("jump2"):
		return 2
	if Input.is_action_just_released("jump2"):
		return 3
	return 0
