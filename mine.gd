extends Area2D

var respawn_timer = 0.0
var respawn_time = 5.0

var main


const AUDIO_FX = preload("uid://cpkdy0uiqi7kt")
	
func _ready() -> void:
	main = get_node("/root/Main")
	main.mines.append(self)
	$AnimationPlayer.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if not body.is_multiplayer_authority():
		return
	explosion.rpc(body.global_position)

const BURST_DUST = preload("uid://clisncgduh61j")

const SFX_EXPLOSION = preload("uid://c1wo2kgie77ay")

@rpc("any_peer", "call_local")
func explosion(pos := Vector2.ZERO):
	if visible:
		var afx : AudioStreamPlayer = AUDIO_FX.instantiate()
		afx.stream = SFX_EXPLOSION
		afx.pitch_scale = main.rng.randf_range(0.5, 1.5)
		main.add_child(afx)
		respawn_timer = 0.0
		visible = false
		for p in players:
			p.mine_force = ((pos-position).normalized() + Vector2.UP*0.1) * 20000.0
			p.particle_timer = 0.5
		for i in range(100):
			var bd = BURST_DUST.instantiate()
			bd.position = global_position + Vector2(main.rng.randf_range(-16,16), main.rng.randf_range(-16,0))
			main.call_deferred("add_child", bd)
			main.request_hit_stop(false)
		

func _physics_process(delta: float) -> void:
	if !visible:
		respawn_timer += delta
		if respawn_timer > respawn_time:
			visible = true

var players = []

func _on_area_2d_body_entered(body: Node2D) -> void:
	players.append(body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	players.erase(body)
