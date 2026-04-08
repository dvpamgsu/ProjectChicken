extends CharacterBody2D

var speed_damping = 0.95    # 공기 저항 (매 프레임 속도를 5%씩 감소)
var sway_speed = 3.0       # 좌우 흔들림 속도
var sway_amplitude = 50.0  # 좌우 흔들림 폭
var fall_speed = 30.0      # 낙하 속도

var time_passed = 0.0
var life_time = 0.0

# ... 기존 변수들 ...
var time_offset = 0.0 # 깃털마다 다른 시작 시간을 주기 위한 변수

func _ready() -> void:
	var main = get_node("/root/Main")
	var angle = main.rng.randf_range(-PI, 0.0)
	var speed = main.rng.randf_range(200, 500)
	velocity = Vector2.RIGHT.rotated(angle)*speed
	velocity.x *= 0.6
	sway_amplitude = main.rng.randf_range(5.0, 10.0)
	life_time = main.rng.randf_range(1.0, 2.0)
	
	# [추가] 각 깃털이 사인파의 서로 다른 지점에서 시작하도록 합니다.
	time_offset = main.rng.randf_range(0.0, TAU) 
	# [추가] 흔들리는 속도도 약간씩 다르게 하면 더 불규칙해 보입니다.
	sway_speed = main.rng.randf_range(2.5, 4.0)

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# 1. 감속 로직
	velocity.x = lerp(velocity.x, 0.0, 1.0 - pow(speed_damping, delta * 60))
	velocity.y = lerp(velocity.y, fall_speed, 1.0 - pow(speed_damping, delta * 60))
	
	# 2. 흔들림(Sway) 계산
	var sway = sin((time_passed * sway_speed) + time_offset) * sway_amplitude
	var final_velocity = velocity
	# 시간이 지날수록 흔들림이 서서히 나타나도록 보정
	final_velocity.x += sway * (1.0 - exp(-time_passed))
	
	# 3. 방향 전환 및 기울기 연출
	if abs(final_velocity.x) > 0.1:
		# 오른쪽으로 갈 때 flip_h = true (기본이 왼쪽이므로)
		$Sprite2D.flip_h = final_velocity.x > 0.0
		
		# 속도에 따른 기울기 계산
		# 속도가 빠를수록, 그리고 sway 값이 클수록 더 많이 기울어집니다.
		# 0.05 같은 상수를 조절해서 기울기 강도를 맞추세요.
		var target_rotation = final_velocity.x * 0.05
		
		# flip_h가 true(오른쪽)일 때는 이미지 기준이 반전되므로 회전 값도 반전
		if $Sprite2D.flip_h:
			target_rotation = -target_rotation
			
		# 회전값을 부드럽게 적용 (lerp_angle을 쓰면 툭툭 끊기지 않고 찰랑거립니다)
		$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, target_rotation, 20.0 * delta)
	
	# 4. 물리 이동 적용
	velocity = final_velocity
	move_and_slide()
	
	# 5. 수명 및 투명도 관리
	if time_passed > life_time:
		queue_free()
	else:
		$Sprite2D.modulate.a = (life_time - time_passed) / life_time
