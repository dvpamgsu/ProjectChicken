extends Node2D

@onready var cam_bl: Node2D = $cam_bl
@onready var cam_tr: Node2D = $cam_tr
@onready var spawn_1: Node2D = $spawn1
@onready var spawn_2: Node2D = $spawn2


@onready var main = get_node("/root/Main")
@onready var lights: Node2D = $lights
@export var shadow = 0.0

@onready var ui: Node2D = $ui
@onready var player_1_label: Label = $ui/player1Label
@onready var player_2_label: Label = $ui/player2Label
@onready var profile_1: TextureRect = $ui/profile1
@onready var profile_2: TextureRect = $ui/profile2
@onready var frame_1: ColorRect = $ui/frame1
@onready var frame_2: ColorRect = $ui/frame2
@onready var alivetimer_1: TextureProgressBar = $ui/alivetimer1
@onready var alivetimer_2: TextureProgressBar = $ui/alivetimer2

@onready var hp_1_1: Sprite2D = $ui/hp1_1
@onready var hp_1_2: Sprite2D = $ui/hp1_2
@onready var hp_1_3: Sprite2D = $ui/hp1_3
@onready var hp_2_1: Sprite2D = $ui/hp2_1
@onready var hp_2_2: Sprite2D = $ui/hp2_2
@onready var hp_2_3: Sprite2D = $ui/hp2_3

@onready var way_chicken: Sprite2D = $ui/way_chicken

const MIKU = preload("uid://b1piejy83552g")
const TETO = preload("uid://dwnbqw3txwioa")

var p1
var p2

var egg_cool1 = [0.0, 0.0, 0.0]
var egg_cool2 = [0.0, 0.0, 0.0]

		
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
var background_offset := Vector2.ZERO

@export var has_cloud = true
const CLOUD = preload("uid://y6r85jeua0is")
@export var cloud_modulate := Color.WHITE


@onready var background: Sprite2D = $background

func _ready():
	menu.visible = false
	way_chicken.scale.x = 0
	background_offset = $background.position
	
	var clouds_x = []
	if has_cloud:
		for i in 3:
			var c = CLOUD.instantiate()
			var x = 0
			while true:
				var flag = false
				for cx in clouds_x:
					if abs(cx - x) < 200:
						flag = true
				if !flag:
					break
				x = main.rng.randf_range(-main.width/2, main.width/2)
			clouds_x.append(x)
			c.position.x = x
			c.position.y = main.rng.randf_range(-main.height/8*3, -main.height/8)
			c.modulate = cloud_modulate
			background.add_child(c)
	
func _stage_process(delta):
	pass
	
var cloud_timer = 0.0
var cloud_time = 60.0
func _physics_process(delta: float) -> void:
	for i in range(3):
		if egg_cool1[i] > 0:
			egg_cool1[i] -= delta
		if egg_cool2[i] > 0:
			egg_cool2[i] -= delta
	
	$background.position = main.camera_2d.global_position + background_offset

	cloud_timer += delta
	if cloud_timer > cloud_time:
		var c = CLOUD.instantiate()
		c.position.x = -main.width/2 - 192
		c.position.y = main.rng.randf_range(-main.height/8*3, -main.height/8)
		c.modulate = cloud_modulate
		background.add_child(c)
		cloud_timer = 0.0
	
	for l in lights.get_children():
		if l.is_fixed:
			l.global_position = main.camera_2d.global_position + l.offset
			
	if main.state != main.STATE.GAME and main.state != main.STATE.GAMEWIN and Input.is_action_just_pressed("esc"):
		get_tree().paused = true
		menu.visible = true
		main.gen_zaworld.rpc(true)
		
	ui_update(delta)
	
	_stage_process(delta)

var target_way = 0
var cur_w = 0
var way_angle := 0.0

const FRAGMENT_1 = preload("uid://dre811xugl3tp")
const FRAGMENT_2 = preload("uid://d3m6rdj8ql0is")
const FRAGMENT_3 = preload("uid://cvivh7f3wbefc")

func rebirth(is_host):
	rebirth_rpc.rpc(is_host)
	
@rpc("any_peer", "call_local")
func rebirth_rpc(is_host):
	rebirth_anim(is_host, 3)
	
func rebirth_anim(is_host, num):
	if is_host:
		if num == 3:
			hp_1_3.rebirth()
		elif num == 2:
			hp_1_2.rebirth()
		elif num == 1:
			hp_1_1.rebirth()
	else:
		if num == 3:
			hp_2_3.rebirth()
		elif num == 2:
			hp_2_2.rebirth()
		elif num == 1:
			hp_2_1.rebirth()
	if num > 1:
		var tween = create_tween()
		tween.tween_property(self, "position", Vector2.ZERO, 0.3)
		tween.finished.connect(rebirth_anim.bind(is_host, num-1))

func gen_fragment(is_host, hp):
	gen_fragment_rpc.rpc(is_host, hp)

@rpc("any_peer", "call_local")
func gen_fragment_rpc(is_host, hp):
	var start_p = Vector2.ZERO
	if is_host:
		if hp == 3 and egg_cool1[2] <= 0:
			egg_cool1[2] = 0.4
			start_p = hp_1_3.global_position
			hp_1_3.crack()
		elif hp == 2 and egg_cool1[1] <= 0:
			egg_cool1[1] = 0.4
			start_p = hp_1_2.global_position
			hp_1_2.crack()
		elif hp == 1 and egg_cool1[0] <= 0:
			egg_cool1[0] = 0.4
			start_p = hp_1_1.global_position
			hp_1_1.crack()
	else:
		if hp == 3 and egg_cool2[2] <= 0:
			egg_cool2[2] = 0.4
			start_p = hp_2_3.global_position
			hp_2_3.crack()
		elif hp == 2 and egg_cool2[1] <= 0:
			egg_cool2[1] = 0.4
			start_p = hp_2_2.global_position
			hp_2_2.crack()
		elif hp == 1 and egg_cool2[0] <= 0:
			egg_cool2[0] = 0.4
			start_p = hp_2_1.global_position
			hp_2_1.crack()
			
	var f1 : RigidBody2D = FRAGMENT_1.instantiate()
	var f2 : RigidBody2D= FRAGMENT_2.instantiate()
	var f3 : RigidBody2D = FRAGMENT_3.instantiate()
	
	f1.position = start_p
	f2.position = start_p
	f3.position = start_p
	
	f1.force = Vector2.LEFT.rotated(main.rng.randf_range(PI/9.0,PI/6.0))*100.0
	f2.force = Vector2.UP.rotated(main.rng.randf_range(-PI/9.0,PI/9.0))*100.0
	f3.force = Vector2.RIGHT.rotated(main.rng.randf_range(-PI/6.0,-PI/9.0))*100.0
	
	f1.tq = main.rng.randf_range(-100,100)
	f2.tq = main.rng.randf_range(-100,100)
	f3.tq = main.rng.randf_range(-100,100)
	
	f1.scale = Vector2(1.2,1.2)
	f2.scale = Vector2(1.2,1.2)
	f3.scale = Vector2(1.2,1.2)
	
	main.call_deferred("add_child", f1)
	main.call_deferred("add_child", f2)
	main.call_deferred("add_child", f3)
	
func instance_death_gen_fragment(is_host, hp):
	if is_host:
		if p1 and p1.alive_timer < 0.5:
			return
	else:
		if p2 and p2.alive_timer < 0.5:
			return
	for i in range(hp, 0, -1):
		gen_fragment_rpc.rpc(is_host, i)
	
var egg_timer = 0.0
func ui_update(delta):
	
	if !p1 or !p2:
		for pk in main.players:
			var p = main.players[pk]
			if !p:
				continue
			if !p1 and p.is_host_player:
				p1 = p
				p1.hitted.connect(gen_fragment)
				p1.instance_death.connect(instance_death_gen_fragment)
				p1.rebirth.connect(rebirth)
			elif !p2:
				p2 = p
				p2.hitted.connect(gen_fragment)	
				p2.instance_death.connect(instance_death_gen_fragment)
				p2.rebirth.connect(rebirth)
	
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
		
	if !profile_1.texture:
		profile_1.texture = load("res://texture/player/chicken_profile" + str(main.p1_code) + ".png")
		print(main.p1_code)
		#alivetimer_1.texture_progress = profile_1.texture
	if !profile_2.texture:
		profile_2.texture = load("res://texture/player/chicken_profile" + str(main.p2_code) + ".png")
		#alivetimer_2.texture_progress = profile_2.texture
		
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
	
	#hp_1_3.frame = 0 if p1.hp >= 3 and p1.alive else 1
	#hp_1_2.frame = 0 if p1.hp >= 2 and p1.alive else 1
	#hp_1_1.frame = 0 if p1.alive else 1
	#hp_2_3.frame = 0 if p2.hp >= 3 and p2.alive else 1
	#hp_2_2.frame = 0 if p2.hp >= 2 and p2.alive else 1
	#hp_2_1.frame = 0 if p2.alive else 1
	
	var x = egg_timer / 2.0 * TAU
	egg_timer += delta
	egg_timer = wrapf(egg_timer, 0.0, 2.0)
	var h = 3.0
	hp_1_3.position.y = 124.0 + sin(x)*h
	hp_1_2.position.y = 124.0 + sin(x-0.4)*h
	hp_1_1.position.y = 124.0 + sin(x-0.8)*h
	hp_2_3.position.y = 124.0 + sin(x)*h
	hp_2_2.position.y = 124.0 + sin(x-0.4)*h
	hp_2_1.position.y = 124.0 + sin(x-0.8)*h

func get_relative_value(x):
	return clamp(100.0*(x-cam_bl.global_position.x)/(cam_tr.global_position.x - cam_bl.global_position.x), 0, 100)
	
@onready var menu: ColorRect = $CanvasLayer/menu	
func _on_button_resume_pressed() -> void:
	get_tree().paused = false
	main.gen_zaworld.rpc(false)
	menu.visible = false

func _on_button_exit_pressed() -> void:
	get_tree().paused = false
	main.gen_zaworld.rpc(false)
	main.to_title()
