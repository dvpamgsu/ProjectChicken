extends Node2D

@onready var cam_bl: Node2D = $cam_bl
@onready var cam_tr: Node2D = $cam_tr
@onready var spawn_1: Node2D = $spawn1
@onready var spawn_2: Node2D = $spawn2


@onready var main = get_node("/root/Main")


@export var rim = 0.0
@export var shadow = 0.0
@export var rim_thickness = 0.0

func _on_area_2dp_1_body_entered(body: Node2D) -> void:
	#print("area1, " + str(body))
	if (main.is_single_game or main.is_local_game) and body.name == "1":
		main.single_win(1)
		return
	if multiplayer.is_server():
		if body.is_host_player:
			main.win.rpc(1)


func _on_area_2dp_2_body_entered(body: Node2D) -> void:
	#print("area2, " + str(body))
	if (main.is_single_game or main.is_local_game) and body.name != "1":
		main.single_win(2)
		return
	if !multiplayer.is_server():
		if !body.is_host_player:
			main.win.rpc(2)
			

var target_progress_value = 50.0
var progress_value = 50.0
var progress_timer = 0.0
@onready var bar_1: ColorRect = $CanvasLayer/bar1
@onready var bar_2: ColorRect = $CanvasLayer/bar2


func _process(delta: float) -> void:
	$background.position = main.camera_2d.global_position
	var p1 = null
	var p2 = null
	for pk in main.players:
		var p = main.players[pk]
		if !p:
			continue
		if p.is_host_player:
			p1 = main.players[pk]
		else:
			p2 = main.players[pk]
	if p1.alive_timer > p2.alive_timer + 0.5:
		target_progress_value = get_relative_value(p1.footpos.global_position.x)
	elif p1.alive_timer + 0.5 < p2.alive_timer:
		target_progress_value = get_relative_value(p2.footpos.global_position.x)
	else:
		target_progress_value = get_relative_value((p1.footpos.global_position.x + p2.footpos.global_position.x)/2.0)
	
	progress_timer += delta
	if progress_timer > 0.1:
		progress_timer = 0.0
	
	progress_value += (target_progress_value - progress_value) * delta
	progress_value = clamp(progress_value, 0.0, 100.0)
	bar_1.scale.x = progress_value/50.0
	var mat1 = bar_1.material as ShaderMaterial
	mat1.set_shader_parameter("beam_thickness", 0.18 * (0.5 + bar_1.scale.x / 3.0))
	bar_2.scale.x = (progress_value-100.0)/50.0
	var mat2 = bar_2.material as ShaderMaterial
	mat2.set_shader_parameter("beam_thickness", 0.18 * (0.5 - bar_2.scale.x / 3.0))
		
func get_relative_value(x):
	return clamp(100.0*(x-cam_bl.global_position.x)/(cam_tr.global_position.x - cam_bl.global_position.x), 0, 100)
	
