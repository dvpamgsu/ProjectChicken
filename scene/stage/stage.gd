extends Node2D

@onready var cam_bl: Node2D = $cam_bl
@onready var cam_tr: Node2D = $cam_tr
@onready var spawn_1: Node2D = $spawn1
@onready var spawn_2: Node2D = $spawn2


@onready var main = get_node("/root/Main")

func _on_area_2dp_1_body_entered(body: Node2D) -> void:
	#print("area1, " + str(body))
	if multiplayer.is_server():
		if body.is_host_player:
			main.win.rpc(1)


func _on_area_2dp_2_body_entered(body: Node2D) -> void:
	#print("area2, " + str(body))
	if !multiplayer.is_server():
		if !body.is_host_player:
			main.win.rpc(2)
