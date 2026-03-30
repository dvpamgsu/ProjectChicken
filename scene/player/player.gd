extends RigidBody2D

@export var alive = true
@export var is_host_player = false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var col_1: CollisionShape2D = $col1
@onready var col_2: CollisionShape2D = $col2
@onready var col_3: CollisionShape2D = $col3

@onready var main

@export var torque_power := 650.0
@export var jump_power := 300.0
@export var jump_torque_power := 8000.0
var jump_timer = 0.0
const jump_time_max = 1.0

var flip_dir = 1

@export var bounce = 0.1
# 스크립트 상단에 쿨다운 변수를 추가해 주세요.
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	main = get_node("/root/Main")
	main.players[name.to_int()] = self
	if is_multiplayer_authority():
		if main.is_host:
			position = main.stage.spawn_1.position
			initial_pos = position
			flip_dir = 1
		else:
			position = main.stage.spawn_2.position
			initial_pos = position
			flip_dir = -1
	#print(is_multiplayer_authority())
	if !is_multiplayer_authority():
		freeze = true
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
	
	if !alive:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		return

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
	
		# 6. 타이머 관리
		shock_timer += delta
		if shock_timer >= duration:
			shock = false
			shock_timer = 0
	
@export var lv := Vector2.ZERO
var shock_timer = 0.0
func _physics_process(delta: float) -> void:
	
	find_alter()
	check_flip()
	#print(freeze)
	#print(position)
	sprite_2d.flip_h = sync_flip_h
	
	var mat = sprite_2d.material as ShaderMaterial
	mat.set_shader_parameter("dissolve_value", dissolve_value)
	
		
	if !is_multiplayer_authority():
		return
		
	lv = linear_velocity
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

	shock_f(delta)
		
	# 머리가 땅에 닿았는지 체크
	#for b in head_touch:
		#var space_state = get_world_2d().direct_space_state
	#
		## 충돌한 지점의 '각도'를 알기 위함입니다.
		#var query = PhysicsRayQueryParameters2D.create(col_3.global_position, col_3.global_position + Vector2(0, 10))
		#query.collision_mask = 1 # 바닥 레이어
		#query.exclude = [get_rid()] # 자기 자신 제외
	#
		#var result = space_state.intersect_ray(query)
	#
		#if result:
			## result.normal이 (0, -1)에 가깝다면 그것은 '바닥'의 윗면입니다.
			#if result.normal.dot(Vector2.UP) > 0.7: 
				## dot product가 0.7 이상이면 대략 45도 미만의 평평한 바닥임을 의미
				#hit()
				#return
		
	rotation = wrapf(rotation, -PI, PI)
	
	var direction
	direction = get_direction()
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
			#PhysicsServer2D.body_set_state(get_rid(), PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, Vector2.ZERO)
			apply_impulse(jump_power*jump_dir*(jump_timer+0.5))
		if floor_cnt > 0:
			apply_impulse(jump_power*jump_dir*(jump_timer+0.5))
			var r = sign(rotation)*min(abs(rotation),PI/8.0)
			apply_torque_impulse(-r*jump_torque_power)
		if floor_cnt <= 0:
			jump_cnt -= 1
	if jump_result == 0 or jump_result == 3:
		jump_timer = 0.0
		$Sprite2D.frame = 0
		col_2.position.y = 4.0
		col_3.position.y = -20.0
		
	physics_material_override.bounce = bounce
	
	# 낙사
	if position.y > main.cam_bl_pos.y:
		dead()
		
func check_flip():
	#print(name)
	for pk in main.players:
		var p2 = main.players[pk]
		if p2 == self:
			continue
		if !p2:
			continue
		if p2.position.x > position.x:
			set_flip(1.0)
		elif p2.position.x < position.x:
			set_flip(-1.0)
		if is_host_player and !alter.alive:
			set_flip(1.0)
		elif !is_host_player and !alter.alive:
			set_flip(-1.0)
		if is_host_player and alive_timer > alter.alive_timer+0.5:
			set_flip(1.0)
		elif !is_host_player and alive_timer > alter.alive_timer+0.5:
			set_flip(-1.0)
		
func set_flip(dir):
	flip_dir = dir
	col_2.position.x = dir*6.0
	sync_flip_h = false if dir > 0 else true
	
func set_initial_pos():
	if !is_multiplayer_authority():
		return
	#var alter
	#for pk in main.players:
		#var p = main.players[pk]
		#if p == self:
			#continue
		#alter = p
	var offsetX = 0
	if main.is_host or is_host_player:
		offsetX = -240
	else:
		offsetX = 240
	initial_pos.x = alter.position.x + offsetX
	initial_pos.y = -1000
	
	var cnt = 0
	var space_state = get_world_2d().direct_space_state
	while true:
		var query = PhysicsRayQueryParameters2D.create(initial_pos, initial_pos + Vector2(0, 4000))
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if result:
			initial_pos = result.position
			break
		else:
			initial_pos.x += 4 * sign(offsetX)
		cnt += 1
		if cnt > 1000:
			break
	var sign = 0
	if initial_pos.x < main.cam_bl_pos.x + 16:
		initial_pos.x = main.cam_bl_pos.x + 240
		sign = 1
	if initial_pos.x > main.cam_tr_pos.x - 16:
		initial_pos.x = main.cam_tr_pos.x - 240
		sign = -1
	while sign!=0:
		var query = PhysicsRayQueryParameters2D.create(initial_pos, initial_pos + Vector2(0, 4000))
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
		collision_mask = 4
		$TimerRebirth.start()
		#set_deferred("freeze", true)
		alive = false
		$TimerDissolveDie.start()
		alive_timer = 0.0
		linear_velocity = Vector2.ZERO
		#set_initial_pos()
	
var initial_pos = Vector2.ZERO	
func initialize():
	if !is_multiplayer_authority():
		return
		
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	
	rotation = 0
	set_initial_pos()
	
var end = false

var floor_cnt = 0
func _on_area_2d_floor_body_entered(body: Node2D) -> void:
	floor_cnt += 1
	jump_cnt = 1
	
func _on_area_2d_floor_body_exited(body: Node2D) -> void:
	floor_cnt -= 1
	#jump_cnt = 2

var forced = false
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		forced = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		forced = false


var head_touch = []
func _on_area_2d_head_body_entered(body: Node2D) -> void:
	head_touch.append(body)
	# 1. 물리 서버 상태 가져오기
	var space_state = get_world_2d().direct_space_state
	
	# 2. 아주 짧은 레이 발사 (머리 위치에서 아래로 10픽셀만)
	# 충돌한 지점의 '각도'를 알기 위함입니다.
	var query = PhysicsRayQueryParameters2D.create(col_3.global_position, col_3.global_position + Vector2(0, 10))
	query.collision_mask = 1 # 바닥 레이어
	query.exclude = [get_rid()] # 자기 자신 제외
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# 3. 충돌한 면의 방향(Normal) 확인
		# result.normal이 (0, -1)에 가깝다면 그것은 '바닥'의 윗면입니다.
		if result.normal.dot(Vector2.UP) > 0.7: 
			# dot product가 0.7 이상이면 대략 45도 미만의 평평한 바닥임을 의미
			hit()
			
var shock = false
func hit():
	hp -= 1
	if hp <= 0:
		hp = 3
		dead()
	else:
		## 물체 기준 오른쪽으로 2미터 지점 (Local)
		#var local_pos = Vector2.UP * 20.0
		#local_pos = local_pos.rotated(rotation)
		## 로컬 방향을 현재 글로벌 회전값에 맞춰 변환 (오프셋만 필요하므로 basis 사용)
		#
		#apply_impulse(Vector2.UP * 400.0, local_pos)
		shock_timer = 0.0
		shock = true

func _on_timer_rebirth_timeout() -> void:
	#print("rebirth")
	if is_multiplayer_authority():
		initialize()
		shock = false
		alive = true
		collision_layer = 2
		collision_mask = 3
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
