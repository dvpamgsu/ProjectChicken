extends "res://scene/player/player.gd"



func _enter_tree() -> void:
	pass

func _ready() -> void:
	basic_ready()
	
	#sprite_2d.material = sprite_2d.material.duplicate()
	jumpcharge.visible = false
	
	#position = main.stage.spawn_2.position
	initial_pos = position
	flip_dir = -1
	ai_target_position = position
	first_touch = false
	
	
	
var is_jump = false
var pre_jump = false
var is_left = false
var pre_left = false
var is_right = false
var pre_right = false

var ai_jump_timer = 0.0
var ai_target_timer = 0.0
var ai_target_position = Vector2.ZERO
var stuck_timer = 0.0
var first_touch = false
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
	
	#if fool_timer < 1.0:
		#fool_timer += delta
	#else:
		#fool_timer = 0.0
	#if fool_timer > 0.8:
		#return
	
	# calculate next target position
	$Polygon2D.global_position = ai_target_position
	#print(ai_target_position)
	var space_state = get_world_2d().direct_space_state
	var query
	var result
	var check = false
	if alter.alive and alter.alive_timer >= alive_timer - 0.5:
		check = true
	elif floor_cnt > 0:
		check = true
	#elif floor_cnt > 0 and !alter.alive:
		#check = true
		#pre_check_type = 2
	#elif floor_cnt > 0 and footpos.global_position.x < ai_target_position.x + 32:
		#check = true
		#pre_check_type = 3
	#else:
		#pre_check_type = 0
	ai_target_timer += delta
	if ai_target_timer > 0.1 and check:
		ai_target_timer = 0.0
		var last_y = 10000.0
		var cnt = 0.0
		var step = 8.0
		var x = footpos.global_position.x + flip_dir * step
		var dist = 10000
		if alter.alive and (alter.alive_timer >= alive_timer - 0.5 or flip_dir > 0):
			#x = ai_target_position.x + flip_dir * step
			dist = abs(alter.position.x-x)
		else:
			x = footpos.global_position.x + flip_dir * step * 6.0
		var flag = false
		while x > main.cam_bl_pos.x and x < main.cam_tr_pos.x:
			query = PhysicsRayQueryParameters2D.create(Vector2(x, -1000.0), Vector2(x, -1000.0) + Vector2.DOWN*3000.0)
			query.collision_mask = 1
			query.exclude = [get_rid()]
			result = space_state.intersect_ray(query)
			
			if result:
				#if last_y < 9999 and last_y > result.position.y + 8.0:
					#last_y = result.position.y
					#break
				if alter.alive and (alive_timer <= alter.alive_timer + 0.5 or flip_dir > 0) and abs(x - alter.position.x) < step:
					last_y = alter.position.y
					break
				#if flag:
					##print("!")
					#last_y = result.position.y
					#x += flip_dir * step * 2.0
					#break
				last_y = result.position.y
			else:
				flag = true
				if last_y < 9999:
					x -= flip_dir * step
					break
			x += flip_dir * step
			if alter.alive and alive_timer <= alter.alive_timer + 0.5 and abs(x-alter.position.x) > dist:
				x = alter.position.x
				last_y = alter.position.y
				break
			cnt += step
			if cnt > 256:
				break
		ai_target_position = Vector2(x, last_y)
	
	var way = -1
	if ai_target_position.x < footpos.global_position.x:
		way = -1
	else:
		way = 1
		
	var target_angle = 0.0
	var dist = (ai_target_position - footpos.global_position).length()
	var dist_val = min(dist, 300.0)/300.0
	if floor_cnt > 0:
		target_angle = way * PI / (24.0 + 12.0*(1.0-dist_val))
		if alter.alive and alter.alive_timer + 0.5 >= alive_timer:
			if dist < 32:
				target_angle = way * PI / 8.0
	else:
		if jump_cnt > 0 and dist_val > 0.1 and knee_cnt <= 0:
			target_angle = way * PI / (8.0 + 8.0*(0.9-dist_val))
		else:
			target_angle = way * PI / 24.0
	if !first_touch:
		target_angle = 0.0
			
	rotation = wrapf(rotation, -PI, PI)
	if flip_dir > 0:
		if rotation > target_angle + PI/40.0:
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
		elif rotation < target_angle - PI/40.0:
			is_right = true
			is_left = false
		else:
			is_right = false
			is_left = false
	
	if floor_cnt > 0:
		first_touch = true
		if ai_jump_timer < 0.4:
			is_jump = false
		elif ai_jump_timer < 0.4 + 1.0 * dist_val:
			is_jump = true
		elif way*rotation > PI/30.0:
			is_jump = false
			ai_jump_timer = 0.0
	elif floor_cnt <= 0 and jump_cnt > 0:
		#print(str(ai_jump_timer) + ", " + str(0.2 + 0.3 * pow(dist_val, 7)))
		if ai_jump_timer < 0.1:
			is_jump = false
		elif ai_jump_timer < 0.09 + 0.35 * pow(dist_val, 2):
			is_jump = true
		elif way*rotation > PI/30.0:
			is_jump = false
	else:
		if (floor_cnt <= 0 and jump_cnt <= 0):
			ai_jump_timer = 0.0
		is_jump = false
		
	if alive_timer < 1.0:
		is_jump = false
		
	if !is_jump and jump_cnt <= 0 and knee_cnt > 0:
		stuck_timer += delta
		if stuck_timer > 0.1:
			is_jump = true
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
		
	if ai_jump_timer < 2.0:
		ai_jump_timer += delta
	else:
		ai_jump_timer = 0.0
	
	pre_alter_alive = alter.alive
	
func _physics_process(delta: float) -> void:
	
	find_alter()
	check_flip()
	ai_process(delta)
	super(delta)
	
	pre_jump = is_jump
	
func get_flip():
	var _flip_dir = 1
	if alter.alive_timer + 0.5 < alive_timer:
		if position.distance_to(alter.position) < 128.0:
			if alter.position.x < position.x:
				_flip_dir = -1
			else:
				_flip_dir = 1
		else:
			_flip_dir = -1
	else:
		if alter.position.x < position.x:
			_flip_dir = -1
		else:
			_flip_dir = 1
	return _flip_dir
	
func get_direction():
	var direction = 0
	if is_left:
		direction += -1
	if is_right:
		direction += 1
	return direction
func _on_timer_rebirth_timeout() -> void:
	super()
	ai_target_position = position
	ai_jump_timer = 0.0
	stuck_timer = 0.0
	first_touch = false
	
	
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
	first_touch = true
	ai_jump_timer = 0.0

var knee_cnt = 0
func _on_area_2d_knee_body_entered(body: Node2D) -> void:
	knee_cnt += 1
	


func _on_area_2d_knee_body_exited(body: Node2D) -> void:
	knee_cnt -= 1
