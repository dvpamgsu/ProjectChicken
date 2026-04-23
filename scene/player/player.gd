extends RigidBody2D

var player_name = ""
var id = 0

@export var alive = true
@export var corpse = false
@export var is_host_player = false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var col_1: CollisionShape2D = $col1
@onready var col_2: CollisionShape2D = $col2
@onready var col_3: CollisionShape2D = $col3
@onready var footpos: Node2D = $footpos

@onready var main:Node2D

@export var torque_power := 650.0
@export var jump_power := 300.0
@export var jump_torque_power := 8000.0

@onready var jumpcharge: TextureProgressBar = $jumpcharge

var mat : ShaderMaterial
var jump_timer = 0.0
const jump_time_max = 1.0

@export var hit_timer = 0.0

@export var flip_dir = 1

@export var bounce = 0.1
var spare_timer = 0.0
# 스크립트 상단에 쿨다운 변수를 추가해 주세요.
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
	
var char_code = 1
func basic_ready():
	#physics_material_override = physics_material_override.duplicate()
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	sprite_2d.material = sprite_2d.material.duplicate()
	mat = sprite_2d.material as ShaderMaterial
	#mat.set_shader_parameter("rim_thickness", 0.1)
	mat.set_shader_parameter("sprite_size", sprite_2d.get_rect().size)
	
	contact_monitor = true
	max_contacts_reported = 5
	max_dist = pow(pow(main.width,2.0)+pow(main.height,2.0), 0.5)
	
	if is_host_player:
		char_code = main.p1_code
	else:
		char_code = main.p2_code
		
	var name_code = ""
	if char_code < 10:
		name_code = "00"+str(char_code)
	else:
		name_code = "0"+str(char_code)
	name_code += ".png"
	sprite_2d.texture = load("res://texture/player/skin"+name_code)
	
func _ready() -> void:
	
	basic_ready()
	
	if is_multiplayer_authority():
		if main.is_host:
			#position = main.stage.spawn_1.position
			initial_pos = position
			flip_dir = 1
		else:
			#position = main.stage.spawn_2.position
			initial_pos = position
			flip_dir = -1
	#print(is_multiplayer_authority())
	if !is_multiplayer_authority():
		freeze = true
		jumpcharge.visible = false
	if name.to_int() != 1:
		flip_dir = -1
	
@export var sync_flip_h: bool = false
var target_check = false
var col_vector = Vector2.ZERO
var col_pos = Vector2.ZERO
@export var additional_force: float = 0.2 # 탄성 계수 (0.0 ~ 1.0 권장, 1.0 넘으면 에너지 창조)
@export var max_impulse: float = 2000.0   # 맵 밖 사출 방지용 한계치
var hit_cooldown: float = 0.0             # 중복 충격 방지 타이머

var hp = 3

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# 1. 기본 상태 체크 (권한 및 생존)
	if !is_multiplayer_authority():
		return
	
	if !alive and !corpse:
		if $TimerDissolveDie.is_stopped():
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0
			rotation = 0
		return
	if alive and alive_timer < 0.1:
		state.linear_velocity.x = 0
		state.angular_velocity = 0
		rotation = 0
		

	# 2. 쿨다운 진행 (0.05~0.1초 정도의 아주 짧은 무적 시간)
	if hit_cooldown > 0:
		hit_cooldown -= state.step # 프레임 타임만큼 차감
		return

	var hit_applied = false

	# 3. 충돌 지점 전수 조사
	for i in state.get_contact_count():
		var target = state.get_contact_collider_object(i)
		
		# 상대방이 플레이어 그룹의 리지드바디인지 확인
		if target is RigidBody2D and target.is_in_group("player"):
			
			# [A] 벡터 수학: 충돌 법선과 상대 속도 추출
			var collision_normal = state.get_contact_local_normal(i)
			# target.lv는 동기화된 속도 변수, state.linear_velocity는 나의 현재 속도
			var relative_vel = target.lv - state.linear_velocity
			
			# [B] 내적(Dot Product): 서로 마주 보고 달려오는 속도 성분만 계산
			var approach_speed = relative_vel.dot(collision_normal)
			
			# [C] 판단: 서로 충분히 강하게 들이받는 상황인가?
			if approach_speed > 20.0: # 미세한 비비기 방지
				var contact_global_pos = state.get_contact_local_position(i)
				
				# 회전력(Torque) 제어: 중심에서 멀수록 회전하지만, 과도하지 않게 0.4~0.5 곱함
				var impulse_offset = (contact_global_pos - global_position) * 0.4
				
				# [D] 충격량 계산: 상대방의 속도를 '나를 밀어내는 방향'으로 변환
				# 에너지가 폭발하지 않도록 approach_speed를 베이스로 계산
				var impact_strength = clamp(approach_speed * additional_force, 0, max_impulse)
				var impulse = collision_normal * impact_strength
				
				# [E] 최종 힘 적용
				state.apply_impulse(impulse, impulse_offset)
				
				
				hit_applied = true
				break # 한 프레임에 여러 접촉점이 있어도 한 번만 처리

	# 4. 충격이 적용되었다면 아주 짧은 무적 시간 부여
	if hit_applied:
		hit_cooldown = 0.5 # 500ms (드르륵거리는 진동 및 에너지 중첩 방지)
			
			
	var t = state.transform
	
	var cam_x = main.camera_2d.global_position.x
	var min_x = cam_x - main.width / 2
	var max_x = cam_x + main.width / 2
	
	var cam_y = main.camera_2d.global_position.y
	var min_y = cam_y - main.height / 2
	var max_y = cam_y + main.height / 2

	#t.origin.x = clamp(t.origin.x, min_x, max_x)
	t.origin.y = max(t.origin.y, min_y)
	if is_host_player:
		t.origin.x = max(min_x, t.origin.x)
		if t.origin.x > max_x:
			dead()
	else:
		t.origin.x = min(max_x, t.origin.x)
		if t.origin.x < min_x:
			dead()

	#state.transform = t
			
	#print(state.linear_velocity)
	state.linear_velocity = state.linear_velocity.limit_length(300.0)
	
	if position.x < main.cam_bl_pos.x:
		position.x = main.cam_bl_pos.x
	if position.x > main.cam_tr_pos.x:
		position.x = main.cam_tr_pos.x
		
	check_landing(state)

@onready var foot_ray_cast_2d: RayCast2D = $Area2DFloor/FootRayCast2D
func gen_jump_effect():
	
	foot_ray_cast_2d.target_position = Vector2(0,15).rotated(-rotation)
	
	if !foot_ray_cast_2d.is_colliding():
		return
	var pos = foot_ray_cast_2d.get_collision_point() + Vector2(0,1)
	var rot = 0
	var e_code = "jump"
	var _flip_h = false
	if flip_dir == 1 and rotation < -PI/6.0:
		_flip_h = true
	if flip_dir == -1 and rotation < PI/6.0:
		_flip_h = true
	main.rpc_id(1, "gen_effect", e_code, pos, rot, _flip_h, 5)
	
@onready var jump_particle: CPUParticles2D = $JumpParticle
func gen_air_jump_effect():
	
	var pos = $Area2DFloor.global_position
	var rot = rotation
	var e_code = "airjump"
	var _flip_h = rotation <= 0.0
	main.rpc_id(1, "gen_effect", e_code, pos, rot, _flip_h, 5)
	
	if is_multiplayer_authority():
		gen_jump_particle.rpc()
		
func gen_hit1_effect():
	
	if alive_timer < 0.1:
		return
	var rot = main.rng.randf_range(-PI,PI)
	var e_code = "hit1"
	#var _flip_h = rotation <= 0.0
	main.rpc_id(1, "gen_effect", e_code, col_3.global_position, rot, true, 20)
	
func gen_hit2_effect(pos):
	
	if alive_timer < 0.1:
		return
	var rot = main.rng.randf_range(-PI,PI)
	var e_code = "hit2"
	#var _flip_h = rotation <= 0.0
	main.rpc_id(1, "gen_effect", e_code, pos, rot, true, 19)
	
@rpc("any_peer", "call_local", "reliable")
func gen_jump_particle():
	jump_particle.direction = Vector2.DOWN.rotated(rotation)
	jump_particle.restart()
	
	
const FEATHER = preload("uid://cdsi6nkkvir5s")
@onready var dead_particle: CPUParticles2D = $DeadParticle
func gen_dead_particle():
	
	dead_particle.restart()
	
	var f_num = main.rng.randi_range(20, 40)
	for i in range(0, f_num):
		var f = FEATHER.instantiate()
		var fx = main.rng.randf_range(-8,8)
		var fy = main.rng.randf_range(-8,8)
		f.position = position + Vector2(fx, fy)
		main.add_child(f)
	
var pre_is_touching_floor = false
var air_timer = 1.0
func check_landing(state):
	var itf = is_touching_floor(state)
	if itf:
		if !pre_is_touching_floor and air_timer > 0.1:
			var pos = last_contact_pos
			var rot = 0
			var e_code = "landing"
			var _flip_h = rotation > 0.0
			main.rpc_id(1, "gen_effect", e_code, pos, rot, _flip_h, 5)
		air_timer = 0.0
	else:
		if air_timer < 2.0:
			air_timer += state.step
	pre_is_touching_floor = itf

	
var last_contact_pos := Vector2.ZERO
func is_touching_floor(state: PhysicsDirectBodyState2D) -> bool:
	# 현재 발생한 모든 충돌 지점을 순회
	for i in range(state.get_contact_count()):
		# 충돌 지점의 법선(Normal) 벡터 확인
		# 법선은 충돌 면에서 수직으로 나오는 방향입니다.
		var normal = state.get_contact_local_normal(i)
		
		# 법선 벡터와 Vector2.UP을 내적(dot)하여 방향 비교
		# 결과값이 0.5보다 크면 바닥(위쪽을 향하는 면)으로 판단합니다.
		if normal.dot(Vector2.UP) > 0.5 and state.get_contact_local_position(i).y > 0:
			last_contact_pos = state.get_contact_collider_position(i)
			return true
			
	return false
	
var alter = null
@export var alive_timer = 0.0
var jump_cnt = 1
@export var dissolve_value = 0.0
func find_alter():
	if !alter:
		for pk in main.players:
			var p = main.players[pk]
			if p == self:
				continue
			alter = p
			#print(alter)
	
func shock_f(delta):
	var duration = 0.2      # 총 작동 시간
	var strength = 2000.0   # 회전 세기
	var damp_strength = 15.0 # 부드럽게 멈추게 하는 저항값
	if shock:
		# 1. 진행도 계산 (0.0 ~ 1.0)
		var t = clamp(shock_timer / duration, 0.0, 1.0)
		
		# 2. 감쇠 곡선 적용 (고도 내장 ease 함수)
		# -2.0 정도를 주면 처음엔 강하고 끝엔 아주 부드럽게 힘이 빠집니다.
		var curve = ease(1.0 - t, -2.0) 
		
		# 3. 방향 결정
		var r = wrapf(rotation, -PI, PI)
		var dir = -1 if r > 0 else 1
		
		# 4. 힘 계산 (기본 회전력 + 회전 속도에 비례하는 저항력)
		# angular_velocity를 빼주는 것이 '감쇠'의 핵심입니다.
		var final_force = (strength * curve) - (angular_velocity * damp_strength)
		
		# 5. 원래 방식대로 두 지점에 힘 적용 (오프셋 계산)
		var force_dir = transform.x * dir  # Vector2(cos(rotation), sin(rotation))와 동일
		var offset
		offset = transform.y * -20.0   # 물체의 '위' 방향으로 20만큼 오프셋
		
		apply_force(force_dir * final_force, offset)
		apply_force(-force_dir * final_force, -offset)
		apply_impulse(1.0*Vector2.UP, Vector2.ZERO)
	
		# 6. 타이머 관리
		shock_timer += delta
		if shock_timer >= duration:
			shock = false
			shock_timer = 0
	

var emitghost = false
var ghostTimer = 0.0
const ghostRate = 0.1
func set_ghost_state(delta):
	if !alive and !corpse:
		return
	if emitghost:
		ghostTimer += delta
		if ghostTimer > ghostRate:
			ghostTimer = wrapf(ghostTimer, 0.0, ghostRate)
			create_ghost.rpc()
	
@rpc("any_peer", "call_local")
func create_ghost():
	# 1. 새로운 스프라이트 노드 생성 및 현재 모습 복제
	var ghost = Sprite2D.new()
	
	# 현재 캐릭터가 사용 중인 Sprite2D의 모든 정보를 그대로 가져옵니다.
	# ($Sprite2D 부분은 실제 캐릭터의 스프라이트 노드 이름으로 수정하세요)
	ghost.texture = $Sprite2D.texture
	ghost.hframes = $Sprite2D.hframes
	ghost.vframes = $Sprite2D.vframes
	ghost.frame = $Sprite2D.frame
	ghost.flip_h = $Sprite2D.flip_h  # ← 여기서 Flip이 완벽하게 해결됩니다.
	
	# 2. 위치 및 회전값 고정
	ghost.global_transform = $Sprite2D.global_transform
	
	# 3. 시각 효과 (잔상 느낌 주기)
	var f = main.rng.randf()
	if f < 0.5:
		ghost.modulate = Color(0.4, 0.8, 1.0, 0.6) # 약간 푸른빛이 도는 반투명
	else:
		ghost.modulate = Color(1.0, 0.4, 0.4, 0.6) # 약간 푸른빛이 도는 반투명
		
	ghost.z_index = z_index - 1              # 캐릭터보다 뒤에 표시
	
	# 4. 씬에 추가 (부모가 아닌 최상위 노드에 추가해야 캐릭터를 안 따라다님)
	get_tree().current_scene.add_child(ghost)
	
	# 5. 트윈(Tween)으로 서서히 사라지게 하기
	var ghost_tween = create_tween()
	# 0.4초 동안 투명도를 0으로 만들고, 완료되면 노드를 삭제함
	ghost_tween.tween_property(ghost, "modulate:a", 0.0, 0.4)
	ghost_tween.finished.connect(func(): ghost.queue_free())
	

@export var lv := Vector2.ZERO
var shock_timer = 0.0
@export var particle_timer = 0.0
var max_dist
func _physics_process(delta: float) -> void:
	
	find_alter()
	check_flip()
	#print(freeze)
	#print(position)
	
	# [A] 공통 비주얼 업데이트 (권한 체크 위)
	if main and main.stage and main.stage.has_node("lights"):
		var lights = main.stage.lights.get_children()
		
		# .exe 호환성을 위해 PackedArray를 미리 생성
		var lcs = PackedColorArray()
		var lis = PackedFloat32Array()
		var loffsets = PackedVector2Array()

		# 반드시 8개를 꽉 채워서 보냅니다 (빌드 환경에서는 가변 배열이 위험함)
		for i in range(8):
			if i < lights.size():
				var l = lights[i]
				var dist = sprite_2d.global_position.distance_to(l.global_position)
				var local_pos:Vector2 = l.global_position - sprite_2d.global_position
				
				local_pos = local_pos.rotated(-rotation)
				if sprite_2d.flip_h:
					local_pos = local_pos.reflect(Vector2.UP)
					
				#if is_host_player:
					#print(local_pos)
				loffsets.append(local_pos)

				lcs.append(l.light_color)
				var intensity = l.intensity if l.is_fixed else l.intensity / max(dist, 1.0)
				lis.append(intensity)

			else:
				# 빈 슬롯은 0이 아닌 안전한 기본값으로 채움
				loffsets.append(Vector2.ZERO)
				lcs.append(Color(0,0,0,0))
				lis.append(0.0)

		
		# 매 프레임 set_shader_parameter 호출
		mat.set_shader_parameter("light_count", min(lights.size(), 8))
		mat.set_shader_parameter("light_offsets", loffsets)
		mat.set_shader_parameter("light_colors", lcs)
		mat.set_shader_parameter("light_intensities", lis)

		mat.set_shader_parameter("dissolve_amount", dissolve_value)
		mat.set_shader_parameter("shadow_intensity", main.stage.shadow)

	# [B] 피격 효과 (권한 체크 위)
	if hit_timer > 0.0:
		mat.set_shader_parameter("hit_strength", 0.175*(1.0+cos(PI+TAU*wrapf(hit_timer,0.0,0.2)/0.2)))
		physics_material_override.bounce = 1.0
	else:
		mat.set_shader_parameter("hit_strength", 0.0)
		physics_material_override.bounce = 0.0
	
	# 잔상 효과
	set_ghost_state(delta)
	
	#if is_host_player:
		#print(linear_velocity.length())
	if particle_timer > 0.0:
		if linear_velocity.length() < 100.0:
			hit_particle.emitting = false
		else:
			hit_particle.emitting = true
	else:
		hit_particle.emitting = false
	#print(hit_particle.emitting)
	
	if alive:
		mat.set_shader_parameter("whiten_strength", 0)
	
			
	#------------------------------------------------------------
	if !is_multiplayer_authority():
		return
	
	# 다시 원래대로 돌아오게 하고 싶다면
	# tween.tween_property(mat, "shader_parameter/whiten_strength", 0.0, 0.2).set_delay(0.1)
		
	sprite_2d.flip_h = sync_flip_h
	
	if hit_timer > 0.0:
		hit_timer -= delta
	else:
		hit_timer = 0.0
		
	
	if particle_timer > 0.0:
		particle_timer -= delta
	else:
		particle_timer = 0.0
		
	lv = linear_velocity
	if !$TimerDissolveDie.is_stopped():
		dissolve_value = 1.0-$TimerDissolveDie.time_left/$TimerDissolveDie.wait_time
	if !$TimerDissolveBirth.is_stopped():
		dissolve_value = $TimerDissolveBirth.time_left/$TimerDissolveBirth.wait_time
	if alive and $TimerDissolveBirth.is_stopped():
		dissolve_value = 0.0
	if !alive and corpse and position.y > main.cam_bl_pos.y:
		start_rebirth()
	
		
	if end:
		freeze = true
		return
		
		
	if !alive and !corpse:
		alive_timer = 0.0
		if $TimerDissolveDie.is_stopped():
			linear_velocity = Vector2.ZERO
			angular_velocity = 0
		jump_timer = 0.0
		$jumpcharge.value = 0
		jumpcharge.tint_under = Color(1,1,1,0)
		return
	elif alive:
		alive_timer += delta
		mat.set_shader_parameter("whiten_strength", 0)
	elif !alive:
		return

	shock_f(delta)
		
	rotation = wrapf(rotation, -PI, PI)
	
	var direction
	direction = get_direction()
	
	flip_dir = get_flip()
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
		
	var jump_result = get_jump()
	if (jump_result == 1 or jump_result == 2):
		$Sprite2D.frame = 1
		col_2.position.y = 9.0
		col_3.position.y = -12.0
		jump_timer += delta
		jump_timer = min(jump_timer, jump_time_max)
	if (floor_cnt > 0 or jump_cnt > 0) and jump_result == 3:
		var jump_dir = Vector2(cos(rotation-PI/2.0), sin(rotation-PI/2.0))
		if floor_cnt <= 0:
			gen_air_jump_effect()
			#PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
			apply_impulse(jump_power*jump_dir*(jump_timer+0.5))
		if floor_cnt > 0:
			gen_jump_effect()
			apply_impulse(jump_power*jump_dir*(jump_timer+0.5))
			var r = sign(rotation)*min(abs(rotation),PI/8.0)
			apply_torque_impulse(-r*jump_torque_power)
		if floor_cnt <= 0:
			jump_cnt -= 1
	if jump_result == 0 or jump_result == 3:
		if floor_cnt > 0:
			$Sprite2D.frame = 0
			col_2.position.y = 4.0
			col_3.position.y = -20.0
		else:
			$Sprite2D.frame = 2
			col_2.position.y = 4.0
			col_3.position.y = -24.0
		jump_timer = 0.0
		
	physics_material_override.bounce = bounce
	
	# 낙사
	if spare_timer < 1.0:
		spare_timer += delta
	if position.y > main.cam_bl_pos.y and spare_timer > 0.5:
		dead()
		
	# jump progress bar
	jumpcharge.value = jumpcharge.max_value * jump_timer / jump_time_max
	if jump_timer < 0.05:
		jumpcharge.tint_under = Color(1,1,1,0)
	else:
		jumpcharge.tint_under = Color(1,1,1,0.5)
	

		
func check_flip():
	#for pk in main.players:
		#var p2 = main.players[pk]
		#if p2 == self:
			#continue
		#if !p2:
			#continue
		#if p2.position.x > position.x:
			#set_flip(1.0)
		#elif p2.position.x < position.x:
			#set_flip(-1.0)
		#if is_host_player and !alter.alive:
			#set_flip(1.0)
		#elif !is_host_player and !alter.alive:
			#set_flip(-1.0)
		#if is_host_player and alive_timer > alter.alive_timer+0.5:
			#set_flip(1.0)
		#elif !is_host_player and alive_timer > alter.alive_timer+0.5:
			#set_flip(-1.0)
	set_flip(flip_dir)
	
func get_flip():
	if Input.is_action_just_pressed("flip"):
		return flip_dir*(-1)
	return flip_dir
		
func set_flip(dir):
	flip_dir = dir
	col_2.position.x = dir*6.0
	sync_flip_h = false if dir > 0 else true
	
func set_initial_pos():
	if !is_multiplayer_authority():
		return
	set_flip(1 if is_host_player else -1)
	#var alter
	#for pk in main.players:
		#var p = main.players[pk]
		#if p == self:
			#continue
		#alter = p
	var offsetX = 0
	if is_host_player:
		offsetX = -240
	else:
		offsetX = 240
	initial_pos.x = alter.position.x + offsetX
	initial_pos.y = -5000
	
	var cnt = 0
	var space_state = get_world_2d().direct_space_state
	var flag = false
	while true:
		var query = PhysicsRayQueryParameters2D.create(initial_pos, initial_pos + Vector2(0, 10000))
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			initial_pos = result.position
			if flag:
				initial_pos.x += sign(offsetX) * 80
			break
		else:
			initial_pos.x += 4 * sign(offsetX)
			flag = true
		cnt += 1
		if cnt > 1000:
			break
	var sign = 0
	if initial_pos.x < main.cam_bl_pos.x + 16:
		initial_pos.x = main.cam_bl_pos.x + 240
		initial_pos.y = -5000
		sign = 1
	if initial_pos.x > main.cam_tr_pos.x - 16:
		initial_pos.x = main.cam_tr_pos.x - 240
		initial_pos.y = -5000
		sign = -1
	cnt = 0
	while sign!=0:
		var query = PhysicsRayQueryParameters2D.create(initial_pos, initial_pos + Vector2(0, 10000))
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			initial_pos = result.position
			break
		else:
			initial_pos.x += 4 * sign
		cnt += 1
		if cnt > 1000:
			break
	initial_pos.y -= 48
	
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	#PhysicsServer2D.body_set_state(
		#get_rid(),
		#PhysicsServer2D.BODY_STATE_TRANSFORM,
		#Transform2D(0, initial_pos)
	#)
	global_position = initial_pos
	
	#PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
	#PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY, 0.0)
	
	# 이제 출력하면 값이 일치하거나 매우 근접하게 나옵니다.
	#print("반영된 위치 (position): ", position)
	
func dead():
	if !alive:
		return
	if is_multiplayer_authority():
		collision_layer = 4
		collision_mask = 1
		alive = false
		corpse = true
		#$TimerCorpse.start()
		flash_white.rpc()
		jumpcharge.value = 0
		alive_timer = 0.0
		
	
var initial_pos = Vector2.ZERO	
func initialize():
	if !is_multiplayer_authority():
		return
		
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	air_timer = 1.0
	
	rotation = 0
	set_initial_pos()
	
var end = false

var floor_cnt = 0
func _on_area_2d_floor_body_entered(body: Node2D) -> void:
	floor_cnt += 1
	jump_cnt = 1
	
func _on_area_2d_floor_body_exited(body: Node2D) -> void:
	floor_cnt -= 1

var forced = false
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		forced = true
	
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, body.global_position)
		var query2 = PhysicsRayQueryParameters2D.create(body.global_position, global_position)
		# 자기 자신은 제외 (Area2D 등이 자기 자신과 부딪히는 것 방지)
		query.exclude = [get_rid()]
		query.collision_mask = 2
		var result = space_state.intersect_ray(query)
		query2.exclude = [body.get_rid()]
		query2.collision_mask = 2
		var result2 = space_state.intersect_ray(query2)
		
		if result and result2:
			var hit_point = result.position
			var hit_point2 = result2.position
			gen_hit2_effect((hit_point+hit_point2)/2.0)
		
func start_rebirth():
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	#set_ghost(false)
	timer_rebirth_start.rpc()
	
	corpse = false
	$TimerDissolveDie.start()
	#gen_dead_particle.rpc()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		forced = false
	


var head_touch = []
func _on_area_2d_head_body_entered(body: Node2D) -> void:

	#print("X")	
	#if body.is_in_group("leg"):
		#hit()
		#return
	
	head_touch.append(body)
	# 1. 물리 서버 상태 가져오기
	var space_state = get_world_2d().direct_space_state
	
	# 2. 아주 짧은 레이 발사 (머리 위치에서 아래로 10픽셀만)
	# 충돌한 지점의 '각도'를 알기 위함입니다.
	var query = PhysicsRayQueryParameters2D.create(col_3.global_position, col_3.global_position + Vector2(0, 10))
	query.collision_mask = 1 # 바닥 레이어
	query.exclude = [get_rid()] # 자기 자신 제외
	
	var result = space_state.intersect_ray(query)
	
	if result and alive and (!body.is_in_group("player") or body.alive):
		# 3. 충돌한 면의 방향(Normal) 확인
		# result.normal이 (0, -1)에 가깝다면 그것은 '바닥'의 윗면입니다.
		if result.normal.dot(Vector2.UP) > 0.7: 
			# dot product가 0.7 이상이면 대략 45도 미만의 평평한 바닥임을 의미
			if hit_timer <= 0.0 and alive and hp > 1:
				shock_timer = 0.0
				shock = true
			gen_hit1_effect()
			hit()
			
var shock = false
@onready var hit_particle: CPUParticles2D = $HitParticle
@onready var timer_hit_ghost_emit: Timer = $TimerHitGhostEmit

var pre_hit_by_player = false
func hit(by_player = false, way = Vector2.ZERO):
	if !is_multiplayer_authority():
		return
	if alive_timer < 0.1:
		return
	if hit_timer > 0.0:
		return
	if !alive:
		return
	hp -= 1
	mat.set_shader_parameter("hit_strength", 0.35)
	set_ghost(true)
		#main.gen_crack.rpc(col_3.global_position + way * 4.0, way)
	hit_timer = 0.5
	var ptype = 1 if is_host_player else 2
	if hp <= 0:
		hp = 3
		#main.gen_crack.rpc(col_3.global_position)
		if by_player:
			main.request_hit_stop.rpc(true, ptype)
		dead()
	else:
		if by_player or (!timer_hit_ghost_emit.is_stopped() and pre_hit_by_player):
			main.request_hit_stop.rpc(false)
	timer_hit_ghost_emit.start()
	if by_player:
		main.gen_blast.rpc(col_3.global_position, way)
		#hit_particle.restart()
		#hit_particle.emitting = true
		particle_timer = 0.5
	pre_hit_by_player = by_player


@rpc("any_peer", "call_local", "reliable")
func timer_rebirth_start():
	$TimerRebirth.start()

@onready var timer_corpse: Timer = $TimerCorpse
@onready var timer_rebirth: Timer = $TimerRebirth
func _on_timer_rebirth_timeout() -> void:
	#print("rebirth")
	if is_multiplayer_authority():
		initialize()
		collision_layer = 2
		collision_mask = 3
		shock = false
		alive = true
		hp = 3
		$TimerDissolveBirth.start()
		#freeze = false # 다시 움직일 수 있도록 해제


func _on_area_2d_head_body_exited(body: Node2D) -> void:
	head_touch.erase(body)


func _on_timer_dissolve_die_timeout() -> void:
	set_initial_pos()
	
func get_direction():
	return Input.get_axis("left", "right")
	
func get_jump():
	if Input.is_action_just_pressed("jump"):
		return 1
	if Input.is_action_pressed("jump"):
		return 2
	if Input.is_action_just_released("jump"):
		return 3
	return 0


func _on_area_2d_head_area_entered(area: Area2D) -> void:
	if area.is_in_group("leg"):
		if alive and area.alive:
			var way = (global_position-area.global_position).normalized()
			hit(true, way)
			apply_impulse(way*500.0)
			
			gen_hit1_effect()
			
func set_ghost(is_on):
	emitghost = is_on
	pass


func _on_timer_hit_ghost_emit_timeout() -> void:
	set_ghost(false)


func _on_timer_corpse_timeout() -> void:
	pass
	

@rpc("any_peer", "call_local", "reliable")
func flash_white():
	timer_corpse.start()
	var tween = create_tween()
	mat.set_shader_parameter("whiten_strength", 0.0)
	# 0.2초 동안 서서히 하얀색으로 변함
	tween.tween_property(mat, "shader_parameter/whiten_strength", 1.0, 0.5)
	tween.tween_interval(0.0)
	
	if position.y < main.cam_bl_pos.y - 10:
		# 3. 기다린 후 특정 함수를 실행합니다.
		tween.tween_callback(explosion)
	
func explosion():
	gen_dead_particle()
	start_rebirth()
	
	
