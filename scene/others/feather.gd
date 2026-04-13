extends CharacterBody2D

# --- 사용자가 제공한 초기 수치 복구 ---
var speed_damping = 0.85    # 공기 저항 (매 프레임 속도를 5%씩 감소)
var sway_speed = 3.0       # 좌우 흔들림 속도
var sway_amplitude = 50.0  # 좌우 흔들림 폭 (ready에서 5~10으로 재설정됨)
var fall_speed = 30.0      # 낙하 속도

var time_passed = 0.0
var life_time = 0.0
var time_offset = 0.0

func _ready() -> void:
	var main = get_node("/root/Main")
	
	# 1. 초기 속도 설정: 전 방향(0 ~ TAU)으로 원형 확산
	var angle = main.rng.randf_range(0.0, TAU)
	# 기존에 주신 속도 범위 (400 ~ 700)
	var speed = main.rng.randf_range(600, 800)
	velocity = Vector2.RIGHT.rotated(angle) * speed
	
	# 2. 수치 설정: 사용자가 주신 범위 적용
	sway_amplitude = main.rng.randf_range(5.0, 10.0)
	life_time = main.rng.randf_range(1.0, 2.0)
	
	# 3. 다양성 부여
	time_offset = main.rng.randf_range(0.0, TAU) 
	sway_speed = main.rng.randf_range(2.5, 4.0)
	
	# 초기 회전값 랜덤
	$Sprite2D.rotation = main.rng.randf_range(0.0, TAU)

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# 1. 중력 개입 계수
	# 발사 후 약 0.6초부터 중력이 서서히 개입하도록 설정
	var gravity_factor = smoothstep(0.6, 1.2, time_passed) 
	
	# 2. 감속 로직 (사용자의 speed_damping 0.95 적용)
	var damp_val = 1.0 - pow(speed_damping, delta * 60)
	
	# x축 감속
	velocity.x = lerp(velocity.x, 0.0, damp_val)
	
	# y축 로직 분리: 초반에는 퍼지는 힘 유지, 이후 낙하로 전이
	if gravity_factor < 0.1:
		velocity.y = lerp(velocity.y, 0.0, damp_val)
	else:
		var target_vy = lerp(0.0, fall_speed, gravity_factor)
		velocity.y = lerp(velocity.y, target_vy, damp_val)
	
	# 3. 흔들림(Sway) 계산
	var sway = sin((time_passed * sway_speed) + time_offset) * sway_amplitude
	var final_velocity = velocity
	# 중력이 적용될 때(힘을 잃을 때) 흔들림이 나타나도록 함
	final_velocity.x += sway * gravity_factor
	
	# 4. 방향 전환 및 기울기 연출
	if abs(final_velocity.x) > 0.1:
		# 요청사항: 오른쪽으로 갈 때 flip_h = true
		$Sprite2D.flip_h = final_velocity.x > 0.0
		
		# 속도에 따른 동적 기울기 (0.05 상수는 시각적 취향에 따라 조절)
		var target_rotation = final_velocity.x * 0.05
		if $Sprite2D.flip_h:
			target_rotation = -target_rotation
			
		# 찰랑거리는 부드러운 회전 (20.0 * delta)
		$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, target_rotation, 20.0 * delta)
	
	# 5. 물리 이동 적용
	velocity = final_velocity
	move_and_slide()
	
	# 6. 수명 및 투명도 관리
	if time_passed > life_time:
		queue_free()
	else:
		# 사용자가 주신 투명도 공식 적용
		$Sprite2D.modulate.a = (life_time - time_passed) / life_time
