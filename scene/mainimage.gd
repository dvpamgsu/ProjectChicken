extends Node2D

var main
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	main = get_node("/root/Main")

var timer = 0.0
var target_a = 1.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if main.state != main.STATE.MAIN:
		target_a = 0.0
	else:
		target_a = 1.0
		
	timer += delta
	timer = wrapf(timer, 0.0, 2.0)
	$title.position.y = -153 + sin(timer/2.0*TAU)*4.0
	
	$title.modulate.a += (target_a - $title.modulate.a) * delta
	$black.modulate.a += (1.0-target_a - $black.modulate.a) * delta
	
	if $title.modulate.a < 0.01 and target_a < 0.1:
		$title.modulate.a = 0.0


func _on_timer_timeout() -> void:
	if $comb.frame == 5:
		$comb.frame = 0
		$comb_f.frame = 0
	else:
		$comb.frame += 1
		$comb_f.frame += 1
