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
	print(is_multiplayer_authority())
	if !is_multiplayer_authority():
		freeze = true
	if name.to_int() != 1:
		flip_dir = -1
	
@export var additional_force = 10.0
@export var sync_flip_h: bool = false
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	if !is_multiplayer_authority():
		return
	
	if !alive:
		linear_velocity = Vector2.ZERO
		angular_velocity = 0
		return
	
	#for i in state.get_contact_count():
		#var target = state.get_contact_collider_object(i)
		#if target is RigidBody2D and target.is_in_group("player"):
			#var my_vel = state.linear_velocity
			#var target_vel = target.linear_velocity
			#
			#var collision_normal = state.get_contact_local_normal(i)
			#var push_force = target_vel.length() * additional_force
			#state.linear_velocity += collision_normal * push_force
			
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
func _physics_process(delta: float) -> void:
	
	if !alter:
		for pk in main.players:
			var p = main.players[pk]
			if p == self:
				continue
			alter = p
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
		#position.y = 100000
		alive_timer = 0.0
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
	
	var direction = Input.get_axis("left", "right")
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
		
	if Input.is_action_just_pressed("jump"):
		jump_timer = 0.0
		$Sprite2D.frame = 1
		col_2.position.y = 9.0
		col_3.position.y = -12.0
	if Input.is_action_pressed("jump"):
		jump_timer += delta
		jump_timer = min(jump_timer, jump_time_max)
	if (floor_cnt > 0 or jump_cnt > 0) and Input.is_action_just_released("jump"):
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
	if Input.is_action_just_released("jump"):
		jump_timer = 0.0
		$Sprite2D.frame = 0
		col_2.position.y = 4.0
		col_3.position.y = -20.0
		
	physics_material_override.bounce = bounce
	
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
			
	# 낙사
	if position.y > main.cam_bl_pos.y:
		dead()
		
func set_flip(dir):
	flip_dir = dir
	col_2.position.x = dir*6.0
	sync_flip_h = false if dir > 0 else true
	
func set_initial_pos():
	if !is_multiplayer_authority():
		return
	var alter
	for pk in main.players:
		var p = main.players[pk]
		if p == self:
			continue
		alter = p
	var offsetX = 0
	if main.is_host:
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
	print("반영된 위치 (position): ", position)
	
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
			dead()


func _on_timer_rebirth_timeout() -> void:
	print("rebirth")
	if is_multiplayer_authority():
		initialize()
		alive = true
		collision_layer = 2
		collision_mask = 3
		$TimerDissolveBirth.start()
		#freeze = false # 다시 움직일 수 있도록 해제


func _on_area_2d_head_body_exited(body: Node2D) -> void:
	head_touch.erase(body)


func _on_timer_dissolve_die_timeout() -> void:
	set_initial_pos()
