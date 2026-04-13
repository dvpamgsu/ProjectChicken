extends Node2D

@onready var cam_bl: Node2D = $cam_bl
@onready var cam_tr: Node2D = $cam_tr
@onready var spawn_1: Node2D = $spawn1
@onready var spawn_2: Node2D = $spawn2


@onready var main = get_node("/root/Main")
@onready var lights: Node2D = $lights
@export var shadow = 0.0

@onready var player_1_label: Label = $ui/player1Label
@onready var player_2_label: Label = $ui/player2Label
@onready var profile_1: TextureRect = $ui/profile1
@onready var profile_2: TextureRect = $ui/profile2
@onready var frame_1: ColorRect = $ui/frame1
@onready var frame_2: ColorRect = $ui/frame2
@onready var alivetimer_1: TextureProgressBar = $ui/alivetimer1
@onready var alivetimer_2: TextureProgressBar = $ui/alivetimer2


@onready var way_chicken: Sprite2D = $ui/way_chicken

const MIKU = preload("uid://b1piejy83552g")
const TETO = preload("uid://dwnbqw3txwioa")

var p1
var p2

		
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
@onready var bar_1: ColorRect = $ui/bar1
@onready var bar_2: ColorRect = $ui/bar2

func _ready():
	way_chicken.scale.x = 0

func _process(delta: float) -> void:
	$background.position = main.camera_2d.global_position

	
	for l in lights.get_children():
		if l.is_fixed:
			l.global_position = main.camera_2d.global_position + l.offset
		
	ui_update(delta)

var target_way = 0
var cur_w = 0
var way_angle := 0.0
func ui_update(delta):
	
	if !p1 or !p2:
		for pk in main.players:
			var p = main.players[pk]
			if !p:
				continue
			if p.is_host_player:
				p1 = main.players[pk]
			else:
				p2 = main.players[pk]
	if p1 == null or p2 == null:
		return
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
	
	if player_1_label.text == "":
		player_1_label.text = p1.player_name
	if player_2_label.text == "":
		player_2_label.text = p2.player_name
		
	if p1.id != 0 and !profile_1.texture:
		profile_1.texture = main.get_steam_avatar(p1.id)
		alivetimer_1.texture = profile_1.texture
	elif p1.id == 0 and !profile_1.texture:
		profile_1.texture = MIKU
		alivetimer_1.texture_progress = profile_1.texture
	if p2.id != 0 and !profile_2.texture:
		profile_2.texture = main.get_steam_avatar(p2.id)
		alivetimer_2.texture = profile_2.texture
	elif p2.id == 0 and !profile_2.texture:
		profile_2.texture = TETO
		alivetimer_2.texture_progress = profile_2.texture
		
	if profile_1.texture:
		#if p1.corpse:
			#var timer : Timer = p1.timer_corpse
			#alivetimer_1.value = 100.0
			#alivetimer_1.tint_progress.a = 0.5*(1.0-timer.time_left/timer.wait_time)
		if !p1.alive:
			var timer : Timer = p1.timer_rebirth
			alivetimer_1.value = (timer.time_left/timer.wait_time)*100.0
		else:
			#alivetimer_1.tint_progress.a = 0
			alivetimer_1.value = 0
	if profile_2.texture:
		#if p2.corpse:
			#var timer : Timer = p1.timer_corpse
			#alivetimer_2.value = 100.0
			#alivetimer_2.tint_progress.a = 0.5*(1.0-timer.time_left/timer.wait_time)
		if !p2.alive:
			var timer : Timer = p2.timer_rebirth
			alivetimer_2.value = (timer.time_left/timer.wait_time)*100.0
		else:
			#alivetimer_2.tint_progress.a = 0
			alivetimer_2.value = 0
		
	mat1 = frame_1.material as ShaderMaterial
	mat1.set_shader_parameter("fire_length", progress_value/100.0*0.14)
	mat2 = frame_2.material as ShaderMaterial
	mat2.set_shader_parameter("fire_length", (100-progress_value)/100.0*0.14)
	
	if p1.alive_timer > p2.alive_timer + 0.5 or (p1.alive and !p2.alive):
		if target_way == -1:
			cur_w = 1
		target_way = 1
	elif p2.alive_timer > p1.alive_timer + 0.5 or (p2.alive and !p1.alive):
		target_way = -1
		if target_way == 1:
			cur_w = 1
	else:
		target_way = 0
		
	var target_way_angle = target_way * PI/2.0
	
	var alpha = -50.0/1.0*sin(way_angle-target_way_angle)
	cur_w = cur_w + alpha*delta
	cur_w *= 0.99
	way_angle += cur_w*delta
	
	way_chicken.scale.x = sin(way_angle)
	way_angle = wrapf(way_angle, -PI, PI)

func get_relative_value(x):
	return clamp(100.0*(x-cam_bl.global_position.x)/(cam_tr.global_position.x - cam_bl.global_position.x), 0, 100)
	
