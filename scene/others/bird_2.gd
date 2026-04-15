extends Sprite2D

enum STATE {arrive, stand, leave}
var state = STATE.arrive
var main
var mat : ShaderMaterial

func _ready() -> void:
	main = get_node("/root/Main")
	position.x = main.camera_2d.position.x + main.rng.randf_range(-main.width/2.0, main.width/2.0)
	position.y = -main.height/2.0 - 32
	speed_x = main.rng.randf_range(-30.0,30.0)
	frame = 1
	mat = material
	
var speed_x := 0.0
var stand_timer = 0.0
var stand_time
var frame_timer = 0
func _physics_process(delta: float) -> void:
	
	match state:
		STATE.arrive:
			position.x += speed_x*delta
			position.y += 100.0*delta
			if $RayCast2D.is_colliding():
				state = STATE.stand
				stand_timer = 0.0
				stand_time = main.rng.randf_range(5.0, 10.0)
				frame = 0
		STATE.stand:
			stand_timer += delta
			frame = 0
			if stand_timer > stand_time:
				speed_x = main.rng.randf_range(-30.0,30.0)
				state = STATE.leave
				frame = 1
		STATE.leave:
			position.x += speed_x*delta
			position.y -= 100.0*delta
			if position.y < -main.height/2.0-32:
				queue_free()
		
	match state:
		STATE.arrive, STATE.leave:
			if frame != 1 and frame != 2:
				frame = 1
			if speed_x > 0:
				flip_h = true
			else:
				flip_h = false
			frame_timer += delta
			if frame_timer > 0.125:
				frame = 3-frame
				frame_timer = 0.0
				
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
				var dist = global_position.distance_to(l.global_position)
				var local_pos:Vector2 = l.global_position - global_position
				
				local_pos = local_pos.rotated(-rotation)
				if flip_h:
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
		mat.set_shader_parameter("shadow_intensity", main.stage.shadow)


func _on_area_2d_body_entered(body: Node2D) -> void:
	speed_x = main.rng.randf_range(-30.0,30.0)
	state = STATE.leave
	frame = 1
