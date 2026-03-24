extends "res://scene/player/player.gd"



func _enter_tree() -> void:
	pass

func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	position = main.stage.spawn_2.position
	initial_pos = position
	flip_dir = -1
	
var is_jump = false
var pre_jump = false
var is_left = false
var pre_left = false
var is_right = false
var pre_right = false

var ai_jump_timer = 0.0
var ai_fool_timer = 0.0
var stuck_timer = 0.0
func ai_process(delta: float):
	
	if !alive:
		return
	
	var way = -1
	if alter.alive:
		if alive_timer > alter.alive_timer + 0.5:
			way = -1
		else:
			if alter.position.x < position.x:
				way = -1
			else:
				way = 1
	else:
		way = -1
		
	var target_angle
	if floor_cnt > 0:
		target_angle = way * PI / 30.0
	else:
		if jump_cnt > 0:
			target_angle = way * PI / 8.0
		else:
			target_angle = way * PI / 30.0
			
	#var space_state = get_world_2d().direct_space_state
	#var st = global_position + flip_dir*Vector2.RIGHT*256.0
	#var query = PhysicsRayQueryParameters2D.create(st + Vector2.UP*50.0, st + Vector2.DOWN*500.0)
	#query.collision_mask = 1 # 바닥 레이어
	#query.exclude = [get_rid()] # 자기 자신 제외
	#
	#var result = space_state.intersect_ray(query)
	#if !result:
		#target_angle = way*PI/30.0
	
	rotation = wrapf(rotation, -PI, PI)
	if rotation > target_angle + PI/60.0:
		is_left = true
		is_right = false
	elif rotation < target_angle - PI/60.0:
		is_right = true
		is_left = false
	else:
		is_right = false
		is_left = false
	
	
	
	stuck_timer += delta
	if stuck_timer >= 2.0:
		stuck_timer = 0.0
		is_jump = true
	elif (floor_cnt > 0 or jump_cnt > 0) and ai_jump_timer < 0.5:
		if floor_cnt>0 or floor_cnt <= 0:
			is_jump = true
			stuck_timer = 0.0
		else:
			is_jump = false
	else:
		if (floor_cnt <= 0 and jump_cnt <= 0):
			ai_jump_timer = 0.0
		is_jump = false
	if ai_jump_timer < 0.6:
		ai_jump_timer += delta
	else:
		ai_jump_timer = 0.0
	
	
func _physics_process(delta: float) -> void:
	
	find_alter()
	
	ai_process(delta)
	
	sprite_2d.flip_h = sync_flip_h
	
	var mat = sprite_2d.material as ShaderMaterial
	mat.set_shader_parameter("dissolve_value", dissolve_value)
	
	if !$TimerDissolveDie.is_stopped():
		dissolve_value = 1.0-$TimerDissolveDie.time_left/$TimerDissolveDie.wait_time
	if !$TimerDissolveBirth.is_stopped():
		dissolve_value = $TimerDissolveBirth.time_left/$TimerDissolveBirth.wait_time
	
	if end:
		freeze = true
		return
		
	if !alive:
		jump_cnt = 0
		ai_jump_timer = -0.5
		is_jump = false
		alive_timer = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		return
	else:
		alive_timer += delta
		
	for b in head_touch:
		var space_state = get_world_2d().direct_space_state
	
		# 충돌한 지점의 '각도'를 알기 위함입니다.
		var query = PhysicsRayQueryParameters2D.create(col_3.global_position, col_3.global_position + Vector2(0, 10))
		query.collision_mask = 1 # 바닥 레이어
		query.exclude = [get_rid()] # 자기 자신 제외
	
		var result = space_state.intersect_ray(query)
	
		if result:
			# result.normal이 (0, -1)에 가깝다면 그것은 '바닥'의 윗면입니다.
			if result.normal.dot(Vector2.UP) > 0.7: 
				# dot product가 0.7 이상이면 대략 45도 미만의 평평한 바닥임을 의미
				dead()
				return	
	
	rotation = wrapf(rotation, -PI, PI)
	
	var direction = Vector2.ZERO
	if is_left:
		direction.x += -1
	if is_right:
		direction.x += 1
	#var rp = clampf(abs(rotation), PI/2.0, PI) * 50.0
	#apply_torque(direction * torque_power)
	
	var force_dir = Vector2(cos(rotation), sin(rotation))
	var offset = Vector2(cos(rotation-PI/2.0), sin(rotation-PI/2.0))*16.0
	apply_force(force_dir*direction*torque_power, offset)
	apply_force(-force_dir*direction*torque_power, -offset)
	
	if floor_cnt > 0 or forced:
		# air
		#center_of_mass = Vector2(0, 24)
		angular_damp = 15.0
	else:
		#center_of_mass = Vector2.ZERO
		angular_damp = 10.0
		
	if !pre_jump and is_jump:
		jump_timer = 0.0
		$Sprite2D.frame = 1
		col_2.position.y = 9.0
		col_3.position.y = -12.0
	if is_jump:
		jump_timer += delta
		jump_timer = min(jump_timer, jump_time_max)
	if (floor_cnt > 0 or jump_cnt > 0) and pre_jump and !is_jump:
		var jump_dir = Vector2(cos(rotation-PI/2.0), sin(rotation-PI/2.0))
		if floor_cnt <= 0:
			#PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
			apply_impulse(jump_power*jump_dir*(jump_timer+0.5))
		if floor_cnt > 0:
			apply_impulse(jump_power*jump_dir*(jump_timer+0.5))
			var r = sign(rotation)*min(abs(rotation),PI/8.0)
			apply_torque_impulse(-r*jump_torque_power)
		if floor_cnt <= 0:
			jump_cnt -= 1
	if pre_jump and !is_jump:
		jump_timer = 0.0
		$Sprite2D.frame = 0
		col_2.position.y = 4.0
		col_3.position.y = -20.0
		
	physics_material_override.bounce = bounce
	
	check_flip()

	if position.y > main.cam_bl_pos.y:
		dead()
		
	
	pre_jump = is_jump
	pre_left = is_left
	pre_right = is_right
