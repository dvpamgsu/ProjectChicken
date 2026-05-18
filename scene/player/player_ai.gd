extends "res://scene/player/player.gd"

@onready var polygon_2d: Polygon2D = $Polygon2D

var way = -1

func _enter_tree() -> void:
	pass

func _ready() -> void:
	basic_ready()
	
	#sprite_2d.material = sprite_2d.material.duplicate()
	jumpcharge.visible = false
	
	#position = main.stage.spawn_2.position
	initial_pos = position
	flip_dir = -1
	
	
	
var is_jump = false
var pre_jump = false
var is_left = false
var pre_left = false
var is_right = false
var pre_right = false

var ai_jump_timer = 0.0
var ai_jump_cool = 0.0
var stuck_timer = 0.0
var pre_alter_alive = true
var pre_check_type = 0

var fool_timer = 0.0
func ai_process(delta: float):
	
	if !alive:
		is_jump = false
		is_left = false
		is_right = false
		pre_jump = false
		pre_left = false
		pre_right = false
		return
	
	var alter_flag = false
	if alter.alive and (alter.alive_timer > alive_timer + 0.5 or abs(alter.alive_timer - alive_timer)<0.5):
		if alter.position.x < position.x:
			way = -1
		else:
			way = 1
		alter_flag = true
	else:
		way = -1
	
	var target_angle = 0.0
	if floor_cnt > 0:
		if way < 0:
			target_angle = -PI/18.0
		else:
			target_angle = PI/18.0
		
	
	var space_state = get_world_2d().direct_space_state
	
	var x1 = position.x
	var y1 = position.y
	var x2 = x1
	var x_fall = position.x
	for i in range(1000):
		var query = PhysicsRayQueryParameters2D.create(Vector2(x1,-1000), Vector2(x1,-1000) + Vector2(0, 10000))
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			y1 = result.position.y
			x2 = result.position.x + way * 4.0
			break
		x1 -= way * 2.0
	var y2 = y1
	var r_flag = false
	var flag = false
	for i in range(1000):
		var query =PhysicsRayQueryParameters2D.create(Vector2(x2,-1000), Vector2(x2,-1000) + Vector2(0, 10000))
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			r_flag = true
			if abs(result.position.y - y1) > 2.0:
				y2 = result.position.y
				break
		elif r_flag:
			flag = true
			x_fall = x2
			break
		x2 += way * 2.0
	var target_position = Vector2(x2 - way * 48.0, y2)
	if !flag:
		target_position += Vector2(way*96.0, 0.0)
	if alter_flag:
		target_position = alter.col_3.global_position
	polygon_2d.global_position = target_position
	
	var v0 = calculate_required_velocity(target_position, 0.8)
	var impulse = (v0 - linear_velocity)*mass
	if sign(x2-position.x) == sign(way):
		impulse *= 0.8
	
	var jump_dir = Vector2(cos(rotation-PI/2.0), sin(rotation-PI/2.0))
	var cur_impulse = jump_power*jump_dir*(ai_jump_timer+0.5)
	if floor_cnt > 0 and (ai_jump_cool > 0.2 or (flag and abs(x_fall - position.x)<32.0)):
		print(str(flag)+", "+str(x_fall)+", "+str(position.x))
		if ai_jump_timer < 1.0 and (!flag or abs(x_fall - position.x)>0.5):
			ai_jump_timer += delta
			is_jump = true
		else:
			ai_jump_cool = 0.0
			ai_jump_timer = 0.0
			is_jump = false
	elif jump_cnt > 0 and floor_cnt <= 0 and ai_jump_cool > 0.1:
		if cur_impulse.distance_to(impulse) > 0.5 and ai_jump_timer < 0.8:
			is_jump = true
			ai_jump_timer += delta
			if impulse.x > cur_impulse.x+0.1:
				target_angle = PI/6.0
			elif impulse.x < cur_impulse.x -0.1:
				target_angle = -PI/6.0
			else:
				ai_jump_timer = 0.9
		else:
			ai_jump_cool = 0.0
			ai_jump_timer = 0.0
			is_jump = false
	else:
		ai_jump_timer = 0.0
		if jump_cnt > 0:
			ai_jump_cool += delta
		else:
			ai_jump_cool = 0.0
			
	if floor_cnt <= 0 and jump_cnt <= 0:
		target_angle = 0.0
	
	rotation = wrapf(rotation, -PI, PI)
	if flip_dir > 0:
		if rotation > target_angle + PI/60.0:
			is_left = true
			is_right = false
		elif rotation < target_angle:
			is_right = true
			is_left = false
		else:
			is_right = false
			is_left = false
	else:
		if rotation > target_angle:
			is_left = true
			is_right = false
		elif rotation < target_angle - PI/60.0:
			is_right = true
			is_left = false
		else:
			is_right = false
			is_left = false
			
	
	if (floor_cnt <= 0 or !foot_ray_cast_2d.is_colliding()) and knee_cnt > 0:
		stuck_timer += delta
		if stuck_timer > 0.1 and stuck_timer < 0.2:
			is_jump = true
		elif stuck_timer >= 0.2:
			is_jump = false
	else:
		stuck_timer = 0.0
	
	pre_alter_alive = alter.alive
	
func calculate_required_velocity(target_pos: Vector2, duration: float) -> Vector2:
	var p0 = global_position
	var vt = target_pos
	var g = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale
	
	# x축: (target_x - start_x) / t
	var vx = (vt.x - p0.x) / duration
	
	# y축: (target_y - start_y - 0.5 * g * t^2) / t
	var vy = (vt.y - p0.y - 0.5 * g * duration * duration) / duration
	
	return Vector2(vx, vy)
	
func _physics_process(delta: float) -> void:
	
	find_alter()
	check_flip()
	ai_process(delta)
	super(delta)
	
	pre_jump = is_jump
	
func get_flip():
	return way
	
func get_direction():
	var direction = 0
	if is_left:
		direction += -1
	if is_right:
		direction += 1
	return direction
func _on_timer_rebirth_timeout() -> void:
	super()
	ai_jump_timer = 0.0
	stuck_timer = 0.0
	
	
func get_jump():
	if is_jump and !pre_jump:
		return 1
	if is_jump and pre_jump:
		return 2
	if !is_jump and pre_jump:
		return 3
	return 0
	
func _on_area_2d_floor_body_entered(body: Node2D) -> void:
	super(body)
	ai_jump_timer = 0.0

var knee_cnt = 0
func _on_area_2d_knee_body_entered(body: Node2D) -> void:
	knee_cnt += 1
	


func _on_area_2d_knee_body_exited(body: Node2D) -> void:
	knee_cnt -= 1
