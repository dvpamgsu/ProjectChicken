extends "res://scene/player/player.gd"

@onready var polygon_2d: Polygon2D = $Polygon2D
@onready var polygon_2d_2: Polygon2D = $Polygon2D2
@onready var polygon_2d_3: Polygon2D = $Polygon2D3



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
var emergency_jump = false
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
	
	var x1 = position.x + way * 16.0
	var y1 = position.y
	var x2 = x1
	var x_fall = position.x
	for i in range(128):
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
	for i in range(400):
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
			break
		x2 += way * 2.0
	var target_position = Vector2(x2 - way * 24.0, y2)
	if !flag:
		target_position += Vector2(way*48.0, 0.0)
	if alter_flag:
		target_position = alter.col_3.global_position
	
	x_fall = position.x
	for i in range(400):
		var query =PhysicsRayQueryParameters2D.create(Vector2(x_fall,-1000), Vector2(x_fall,-1000) + Vector2(0, 10000))
		query.collision_mask = 1
		var result = space_state.intersect_ray(query)
		if !result:
			break
		x_fall += way * 2.0
		
	polygon_2d.global_position = target_position
	polygon_2d_3.global_position = Vector2(x_fall, y2)
	
	for m in main.mines:
		if !m:
			continue
		if target_position.distance_to(m.global_position) < 8.0:
			target_position += way*Vector2(8.0, 0.0)
	
	var jump_dir = Vector2(cos(rotation-PI/2.0), sin(rotation-PI/2.0))
	var cur_impulse = jump_power*jump_dir*(ai_jump_timer+0.5)
	var predicted_land_pos = predict_landing_position(cur_impulse, target_position.y)
	polygon_2d_2.global_position = predicted_land_pos
	if floor_cnt > 0 and ai_jump_cool > 0.1:
		if ai_jump_timer < 1.0 and abs(x_fall - position.x) > 2.0:
			ai_jump_timer += delta
			is_jump = true
		else:
			if abs(x_fall - position.x) <= 2.0:
				emergency_jump = true
			ai_jump_cool = 0.0
			ai_jump_timer = 0.0
			is_jump = false
	elif jump_cnt > 0 and floor_cnt <= 0 and ai_jump_cool > 0.1:
		var off_flag = false
		if predicted_land_pos.distance_to(target_position) > 0.5 or ai_jump_timer < 0.2:
			off_flag = true
		if sign(target_position.x-predicted_land_pos.x)*sign(way) > 0:
			off_flag = true
		if ai_jump_timer > 0.8:
			off_flag = false
		if emergency_jump and ai_jump_timer > 0.2:
			emergency_jump = false
			off_flag = false
		if off_flag:
			is_jump = true
			ai_jump_timer += delta
			if target_position.x > predicted_land_pos.x:
				target_angle = PI/6.0
			elif target_position.x < predicted_land_pos.x:
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
			
	#if floor_cnt <= 0 and jump_cnt <= 0:
		#target_angle = 0.0
	
	rotation = wrapf(rotation, -PI, PI)
	if flip_dir > 0:
		if rotation > target_angle + PI/90.0:
			is_left = true
			is_right = false
		elif rotation < target_angle - PI/90.0:
			is_right = true
			is_left = false
		else:
			is_right = false
			is_left = false
	else:
		if rotation > target_angle + PI/90.0:
			is_left = true
			is_right = false
		elif rotation < target_angle - PI/90.0:
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
	
func predict_landing_position(impulse: Vector2, ground_y: float) -> Vector2:
	# 1. 힘(Impulse)이 가해진 직후의 초기 속도 계산
	# 공식: 속도 변화량 = 충격량 / 질량
	var initial_velocity = linear_velocity + (impulse / mass)
	
	# 2. 현재 위치와 중력 가속도 가져오기
	var start_pos = footpos.global_position
	# 프로젝트 설정의 기본 중력 값과 오브젝트의 중력 스케일을 곱함
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * gravity_scale
	
	# 3. Y축 기준, 착지 바닥까지 도달하는 데 걸리는 시간(t) 구하기
	# 근의 공식 (at^2 + bt + c = 0) 활용
	# 0.5 * gravity * t^2 + initial_velocity.y * t + (start_pos.y - ground_y) = 0
	
	var a = 0.5 * gravity
	var b = initial_velocity.y
	var c = start_pos.y - ground_y
	
	# 판별식 계산 (b^2 - 4ac)
	var discriminant = (b * b) - (4 * a * c)
	
	if discriminant < 0:
		# 판별식이 0보다 작으면 물리적으로 바닥에 도달할 수 없음 (예: 이미 바닥보다 아래에 있거나 위로만 날아감)
		return Vector2.ZERO 
		
	# 근의 공식 적용 (시간 t는 항상 양수여야 하므로 더 큰 값을 선택)
	var t1 = (-b + sqrt(discriminant)) / (2 * a)
	var t2 = (-b - sqrt(discriminant)) / (2 * a)
	var t = max(t1, t2)
	
	# 4. 구한 시간(t)을 X축 공식에 대입하여 최종 착지 위치 계산
	# 등속도 운동 가정 (공기 저항이 없다면 X축 가속도는 0)
	var landing_x = start_pos.x + (initial_velocity.x * t)
	
	return Vector2(landing_x, ground_y)
	
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
