extends "res://scene/player/player.gd"

func _enter_tree() -> void:
	set_multiplayer_authority(1)
	
func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	position = main.stage.spawn_2.position
	initial_pos = position
	flip_dir = -1
	

func _physics_process(delta: float) -> void:
	
	find_alter()
	#print(freeze)
	#print(position)
	sprite_2d.flip_h = sync_flip_h
	
	var mat = sprite_2d.material as ShaderMaterial
	mat.set_shader_parameter("dissolve_value", dissolve_value)
	
		
	if !is_multiplayer_authority():
		return
		
	if !$TimerDissolveDie.is_stopped():
		dissolve_value = 1.0-$TimerDissolveDie.time_left/$TimerDissolveDie.wait_time
	if !$TimerDissolveBirth.is_stopped():
		dissolve_value = $TimerDissolveBirth.time_left/$TimerDissolveBirth.wait_time
	
	
	if end:
		freeze = true
		return
		
	if !alive:
		alive_timer = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		return
	else:
		alive_timer += delta
		
	# 머리가 땅에 닿았는지 체크
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
	
	var direction = Input.get_axis("left2", "right2")
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
		
	if Input.is_action_just_pressed("jump2"):
		jump_timer = 0.0
		$Sprite2D.frame = 1
		col_2.position.y = 9.0
		col_3.position.y = -12.0
	if Input.is_action_pressed("jump2"):
		jump_timer += delta
		jump_timer = min(jump_timer, jump_time_max)
	if (floor_cnt > 0 or jump_cnt > 0) and Input.is_action_just_released("jump2"):
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
	if Input.is_action_just_released("jump2"):
		jump_timer = 0.0
		$Sprite2D.frame = 0
		col_2.position.y = 4.0
		col_3.position.y = -20.0
		
	physics_material_override.bounce = bounce
	
	check_flip()
	# 낙사
	if position.y > main.cam_bl_pos.y:
		dead()
