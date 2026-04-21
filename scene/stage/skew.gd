extends Sprite2D

@export var timer_offset = 0.0
var timer = 0.0

func _ready() -> void:
	timer = timer_offset

func _physics_process(delta: float) -> void:
	timer += delta
	timer = wrapf(timer, 0.0, 12.0)
	skew = -PI/30.0 +  smooth_asymmetric_wave(timer, 0.4) * PI/12.0

func smooth_asymmetric_wave(time: float, rise_ratio: float = 0.3) -> float:
	# 1. 주기를 0~1 범위로 정규화 (TAU = 2 * PI)
	var t = time / 12.0
	
	var y: float
	if t < rise_ratio:
		# 올라가는 구간 (가파름)
		# 0 ~ rise_ratio 사이를 0 ~ 1로 변환 후 코사인 보간
		var local_t = t / rise_ratio
		y = (1.0 - cos(local_t * PI)) / 2.0
	else:
		# 내려가는 구간 (완만함)
		# rise_ratio ~ 1.0 사이를 1 ~ 0으로 변환 후 코사인 보간
		var local_t = (t - rise_ratio) / (1.0 - rise_ratio)
		y = (1.0 + cos(local_t * PI)) / 2.0
		
	return y
