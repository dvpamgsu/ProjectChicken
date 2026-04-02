extends Node2D

var lobby_id : int = 0
var peer : SteamMultiplayerPeer
var is_host : bool = false
var is_joining : bool = false

@onready var host_button: Button = $CanvasLayer/mainmenu/host_button
@onready var single_button: Button = $CanvasLayer/mainmenu/single_button


@onready var value_bounce: LineEdit = $CanvasLayer/debug/value_bounce
@onready var value_additional: LineEdit = $CanvasLayer/debug/value_additional
@onready var value_torque: LineEdit = $CanvasLayer/debug/value_torque
@onready var value_jump: LineEdit = $CanvasLayer/debug/value_jump

@onready var label_bounce: Label = $CanvasLayer/debug/Label_bounce
@onready var label_additional: Label = $CanvasLayer/debug/Label_additional
@onready var label_torque: Label = $CanvasLayer/debug/Label_torque
@onready var label_jump: Label = $CanvasLayer/debug/Label_jump



@onready var button_bounce: Button = $CanvasLayer/debug/Button_bounce
@onready var button_additional: Button = $CanvasLayer/debug/Button_additional
@onready var button_torque: Button = $CanvasLayer/debug/Button_torque
@onready var button_jump: Button = $CanvasLayer/debug/Button_jump
@onready var button_reset: Button = $CanvasLayer/debug/Button_reset

@onready var mainmenu: Node2D = $CanvasLayer/mainmenu

@onready var debug: Node2D = $CanvasLayer/debug
@onready var lobby: Node2D = $CanvasLayer/lobby
@onready var friend_lobbies: Node2D = $CanvasLayer/friend_lobbies
@onready var lobby_single: Node2D = $CanvasLayer/lobby_single


@onready var label_player_1: Label = $CanvasLayer/lobby/Label_player1
@onready var label_player_2: Label = $CanvasLayer/lobby/Label_player2
@onready var texture_rect_1: TextureRect = $CanvasLayer/lobby/TextureRect1
@onready var texture_rect_2: TextureRect = $CanvasLayer/lobby/TextureRect2

@onready var member_list: VBoxContainer = $CanvasLayer/friend_lobbies/ScrollContainer/MemberList

@onready var camera_2d: Camera2D = $Camera2D
@onready var cam_target: Node2D = $Cam_target

@onready var game_ui: Node2D = $CanvasLayer/Game_UI
@onready var label_win: Label = $CanvasLayer/Game_UI/LabelWin

@onready var local_button: Button = $CanvasLayer/mainmenu/local_Button
@onready var lobby_local: Node2D = $CanvasLayer/lobby_local


@export var stages = []

var width = 1152/2
var height = 648/2

var stage

var cam_bl_pos = Vector2.ZERO
var cam_tr_pos = Vector2.ZERO

#const PLAYER = preload("uid://w67rcx1afybq")
const PLAYER = preload("uid://bh58c7wn1bdd1")

var players = {}

enum STATE {MAIN, LOBBY, FRIEND_LOBBIES, GAME, GAMEWIN, LOBBY_SINGLE, GAME_SINGLE, GAMEWIN_SINGLE, LOBBY_LOCAL, GAME_LOCAL, GAMEWIN_LOCAL}
var state : STATE = STATE.MAIN

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		# 창 모드일 경우 전체화면으로 전환
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# 전체화면(또는 최대화 등)일 경우 다시 창 모드로 전환
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				camera_2d.zoom.x *= 1.1
				camera_2d.zoom.y = camera_2d.zoom.x
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				camera_2d.zoom.x *= 1.0/1.1
				camera_2d.zoom.y = camera_2d.zoom.x
		width = 1152.0 / camera_2d.zoom.x
		height = 648.0 / camera_2d.zoom.x
		$Camera2D/boundary1.position.x = -width/2.0
		$Camera2D/boundary2.position.x = width/2.0

func _ready() -> void:
	
	width = 1152.0 / camera_2d.zoom.x
	height = 648.0 / camera_2d.zoom.x
	mainmenu.visible = true
	debug.visible = false
	lobby.visible = false
	friend_lobbies.visible = false
	game_ui.visible = false
	lobby_single.visible = false
	lobby_local.visible = false
	
	label_players.append(label_player_1)
	label_players.append(label_player_2)
	texture_players.append(texture_rect_1)
	texture_players.append(texture_rect_2)
	
	print("Steam initialized: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	# 로비 멤버의 데이터(레디 등)가 변경되었을 때 발생
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	# 로비 멤버가 들어오거나 나갔을 때 발생
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_remove_player)
	
	await get_tree().create_timer(1.0).timeout
	_check_steam_launch_args()
	
	$Camera2D/boundary1.position.x = -width/2.0
	$Camera2D/boundary2.position.x = width/2.0

func _on_peer_connected(id: int) -> void:
	# 새로운 유저가 접속하면 서버가 그 유저에게 Steam ID를 물어봄
	if not player_ids.has(id):
		player_ids.append(id)
	print("현재 접속된 Peer IDs: ", player_ids)	



func _check_steam_launch_args():
	# Steam API를 통해 전달된 실행 커맨드라인 전체를 가져옵니다.
	var cmd_line = Steam.getLaunchCommandLine()
	print("전달된 커맨드라인: ", cmd_line)
	
	if "+connect_lobby" in cmd_line:
		var parts = cmd_line.split(" ")
		for i in range(parts.size()):
			# 인자 배열에서 키워드를 찾고 그 다음 인자인 ID를 추출합니다.
			if parts[i] == "+connect_lobby" and i + 1 < parts.size():
				var lobby_id = parts[i + 1].to_int()
				if lobby_id > 0:
					print("로비 ID 발견, 참여 시도: ", lobby_id)
					join_lobby(lobby_id)
				break
	
func _on_lobby_join_requested(lobby_id: int, _friend_id: int):
	# 친구 참여 요청 시 로그를 남기고 즉시 참여 플래그를 세웁니다.
	print("스팀 오버레이를 통해 참여 요청됨. ID: ", lobby_id)
	
	is_joining = true 
	join_lobby(lobby_id)
	
var player_ids = []
func _on_player_connected(id: int):
	if not multiplayer.is_server():
		return
		
@rpc("any_peer", "call_local", "reliable")
func win(num):
	if state != STATE.GAME:
		return
	print("win " + str(num))
	state = STATE.GAMEWIN
	var p1 = null
	var p2 = null
	for pk in players:
		var p = players[pk]
		if !p:
			continue
		if p.is_host_player:
			p1 = players[pk]
		else:
			p2 = players[pk]
			
	for id in players:
		var p:Node2D = players[id]
		p.set_deferred_thread_group("freeze", true)
		p.end = true
		print("freeze " + str(id))
	game_ui.visible = true
	if num == 1:
		var member_name = Steam.getFriendPersonaName(peer.get_steam_id_for_peer_id(p1.name.to_int()))
		label_win.text = member_name + " won"
	else:
		var member_name = Steam.getFriendPersonaName(peer.get_steam_id_for_peer_id(p2.name.to_int()))
		label_win.text = member_name + " won"
	$TimerWin.start()
	
	
func _process(delta: float) -> void:
	
	#print(state)
	#print(lobby.visible)
	
	#if players.size() == 2:
		#for pk in players:
			#if players[pk]:			
				#label_bounce.text = str(players[pk].bounce)
				#label_additional.text = str(players[pk].additional_force)
				#label_torque.text = str(players[pk].torque_power)
				#label_jump.text = str(players[pk].jump_power)
				#break
			
	if stage:
		cam_bl_pos = stage.cam_bl.global_position
		cam_tr_pos = stage.cam_tr.global_position
		
	#if state != STATE.GAME and state != STATE.GAMEWIN and stage:
		#stage.queue_free()
		#stage = null

	if state != STATE.GAME and state != STATE.GAME_SINGLE and state != STATE.GAME_LOCAL:
		cam_target.position = Vector2.ZERO
		camera_2d.position = Vector2.ZERO		
		
		
	match state:
		STATE.MAIN:
			pass
		STATE.LOBBY:
			pass
		STATE.GAME, STATE.GAME_SINGLE, STATE.GAME_LOCAL:
			if state == STATE.GAME:
				if Input.is_action_just_pressed("debug1"):
					win.rpc(1)
				if Input.is_action_just_pressed("debug2"):
					win.rpc(2)
		
				if is_host:
					$Camera2D/boundary1.collision_layer = 1
					$Camera2D/boundary2.collision_layer = 8
				else:
					$Camera2D/boundary1.collision_layer = 8
					$Camera2D/boundary2.collision_layer = 1
			if state == STATE.GAME_SINGLE or state == STATE.GAME_LOCAL:
				$Camera2D/boundary1.collision_layer = 8
				$Camera2D/boundary2.collision_layer = 16
				
			camera_2d.position += (cam_target.position - camera_2d.position) * delta * 2.0
			
			var member_count
			if state == STATE.GAME:
				member_count = Steam.getNumLobbyMembers(lobby_id)
			else:
				member_count = 2
				
			if member_count == 2 and players.size() == 2:
				var pos_center = Vector2.ZERO
				var p1 = null
				var p2 = null
				#print(players)
				var alive_cnt = 0
				for pk in players:
					var p = players[pk]
					if !p:
						continue
					if p.is_host_player:
						p1 = players[pk]
					else:
						p2 = players[pk]
					if players[pk].alive:
						pos_center += players[pk].position
						alive_cnt += 1
				if p1 and p2:
					if alive_cnt == 2:
						pos_center /= alive_cnt
					else:
						if p1.alive:
							pos_center.x += width/4
						elif p2.alive:
							pos_center.x -= width/4
						else:
							pos_center.x = (p1.position.x + p2.position.x)/2
					
					cam_target.position.x = pos_center.x
					
					if p1.alive and p2.alive:
						if p1.position.x > p2.position.x:
							if p1.alive_timer > p2.alive_timer+0.5:
								cam_target.position.x = p1.position.x - width/6
							elif p1.alive_timer+0.5 < p2.alive_timer:
								cam_target.position.x = p2.position.x + width/6
					
					var space_state = get_world_2d().direct_space_state
					var query = PhysicsRayQueryParameters2D.create(Vector2(camera_2d.position.x, -1000), Vector2(camera_2d.position.x, 4000))
					query.collision_mask = 1
					var result = space_state.intersect_ray(query)
					if result:
						cam_target.position.y = result.position.y - 64
					
					cam_target.position.x = clamp(cam_target.position.x, cam_bl_pos.x + width/2, cam_tr_pos.x - width/2)
					cam_target.position.y = clamp(cam_target.position.y, cam_tr_pos.y + height/2, cam_bl_pos.y - height/2)
					
					if p1.position.x > cam_target.position.x + width/2:
						p1.dead()
					if p2.position.x < cam_target.position.x - width/2:
						p2.dead()
		
	if Input.is_action_just_pressed("fullscreen"):
		toggle_fullscreen()
			
func _on_lobby_data_update(l_id: int, member_id: int, success: int) -> void:
	# 데이터 변경 성공 시 UI 갱신
	if success:
		update_lobby_members_ui()

func _on_lobby_chat_update(l_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	# chat_state 2: 퇴장, 8: 연결 끊김, 16: 강퇴
	if chat_state == 2 or chat_state == 8 or chat_state == 16:
		var host_steam_id = Steam.getLobbyOwner(l_id)
		
		# 1. 만약 나간 사람이 호스트라면? (클라이언트 입장에서 방 터짐)
		if changed_id == host_steam_id:
			print("방장이 로비를 나갔습니다. 방을 폭파합니다.")
			_bomb_lobby()
		
		# 2. 게임 중인데 인원이 부족해졌다면? (2인 게임 기준)
		elif state == STATE.GAME:
			var member_count = Steam.getNumLobbyMembers(l_id)
			if member_count < 2:
				print("플레이어가 부족하여 로비로 돌아가거나 방을 터뜨립니다.")
				if stage:
					stage.queue_free()
					stage = null

				for pk in players:
					var p = players[pk]
					if p:
						p.queue_free()
						#var p_steam_id = peer.get_steam_id_for_peer_id(p.name.to_int())
					Steam.setLobbyMemberData(lobby_id, "ready", "0")
				_bomb_lobby()
		
		# 3. 로비 UI 갱신 (아직 방이 유지되는 경우)
		if state == STATE.LOBBY:
			update_lobby_members_ui()
			
@export var label_players = []
@export var texture_players = []
func update_lobby_members_ui() -> void:
	# 1. 기존 UI 목록 초기화 (VBoxContainer 등 사용 권장)
	#for child in $CanvasLayer/MemberList.get_children():
		#child.queue_free()
	
	# 2. 로비 인원 수 확인
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	
	var ready_count = 0
	
	for i in range(member_count):
		# 3. 멤버 ID 및 닉네임 가져오기
		var member_steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		var member_name = Steam.getFriendPersonaName(member_steam_id)
		
		# 4. 해당 멤버의 "ready" 데이터 읽기
		var ready_status = Steam.getLobbyMemberData(lobby_id, member_steam_id, "ready")
		
		label_players[i].text = member_name
		texture_players[i].texture = get_steam_avatar(member_steam_id)
		
		if ready_status == "1":
			label_players[i].modulate = Color.GREEN
			ready_count += 1
		else:
			label_players[i].modulate = Color.RED
		
	for i in range(member_count, 2):
		label_players[i].text = ""
		texture_players[i].texture = null
		
	
	if ready_count == 2 and player_ids.size() == 2:
		start_game.rpc()

@rpc("authority", "call_local")
func start_game() -> void:
	
	
	is_single_game = false
	is_local_game = false
	camera_2d.position = Vector2.ZERO
	if state != STATE.LOBBY:
		return
	lobby.visible = false
	state = STATE.GAME
	var s = stages[1].instantiate()
	add_child(s)
	stage = s
	if multiplayer.is_server():
		for id in player_ids:
			spawn_player(id)
	

func _bomb_lobby() -> void:
	print("로비 파괴 프로세스 시작...")
	
	# 1. Steam 로비 탈출
	if lobby_id > 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	
	# 2. 멀티플레이어 피어 초기화 (Offline모드로 전환)
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	
	# 단순히 null보다 OfflineMultiplayerPeer를 넣는 것이 로컬 권한(ID 1) 복구에 유리합니다.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	# 3. 인게임 노드 제거
	if stage:
		stage.queue_free()
		stage = null
	
	# 4. 플레이어 데이터 정리
	for pk in players.keys():
		var p = players[pk]
		if is_instance_valid(p):
			p.queue_free()
	players.clear()
	player_ids = [1] # 기본 ID 리셋
	
	# 5. UI 및 상태 복구
	state = STATE.MAIN
	lobby.visible = false
	friend_lobbies.visible = false
	mainmenu.visible = true

func get_steam_avatar(steam_id: int) -> ImageTexture:
	var image_handle = Steam.getMediumFriendAvatar(steam_id)
	
	if image_handle <= 0:
		return null
		
	var avatar_dict = Steam.getImageRGBA(image_handle)
	
	if avatar_dict.size() > 0:
		# 에러 방지를 위해 키 이름을 유연하게 체크합니다.
		# 어떤 버전은 'width'를 쓰고, 어떤 버전은 'size'를 씁니다.
		var width = 64
		var height = 64
		
		if avatar_dict.has("width"):
			width = avatar_dict["width"]
			height = avatar_dict["height"]
		elif avatar_dict.has("size"): # 일부 버전 대응
			width = avatar_dict["size"]
			height = avatar_dict["size"]
			
		# 실제 데이터가 들어있는 buffer 혹은 data 키 확인
		var buffer = PackedByteArray()
		if avatar_dict.has("buffer"):
			buffer = avatar_dict["buffer"]
		elif avatar_dict.has("data"):
			buffer = avatar_dict["data"]
		
		# 만약 여전히 buffer를 못 찾았다면 딕셔너리 자체가 데이터일 가능성이 있습니다.
		if buffer.is_empty() and avatar_dict is PackedByteArray:
			buffer = avatar_dict
		
		if buffer.is_empty():
			return null
			
		var image = Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, buffer)
		var texture = ImageTexture.create_from_image(image)
		return texture
		
	return null
	
func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 2)
	is_host = true
	player_ids = [1]
	
func _on_lobby_created(result : int, lobby_id : int):
	if result == Steam.RESULT_OK:
		self.lobby_id = lobby_id
		
		peer = SteamMultiplayerPeer.new()
		
		# peer.server_relay = true # 필요한 경우에만 사용 (기본값 추천)
		var error = peer.create_host(0) # 0은 기본 포트/채널 의미
		
		if error == OK:
			multiplayer.multiplayer_peer = peer
			# _on_lobby_created 안에서 신호를 또 연결하면 중복 실행될 수 있으므로 주의
			#_add_player(1) # 호스트 자신 추가
			
			
			Steam.setRichPresence("connect", "+connect_lobby " + str(lobby_id))
			Steam.setLobbyJoinable(lobby_id, true)
			Steam.setRichPresence("status", "playing")
			print("Lobby created, ID: ", lobby_id)
		
func join_lobby(lobby_id : int):
	is_joining = true
	Steam.joinLobby(lobby_id)
	
	
func _on_lobby_joined(lobby_id : int, _permission : int, _locked : bool, response : int):
	print("로비 조인 신호 발생. 응답 코드: ", response)
	
	# response 1은 성공을 의미합니다.
	if response != 1:
		print("로비 접속 실패")
		is_joining = false
		return

	mainmenu.visible = false
	#lobby.visible = false
	friend_lobbies.visible = false
	
	self.lobby_id = lobby_id
	var host_id = Steam.getLobbyOwner(lobby_id)
	
	print("로비 주인(Host) Steam ID: ", host_id)
	
	# 이미 호스트라면(본인이 방을 만든 직후라면) 클라이언트를 생성할 필요가 없습니다.
	if Steam.getSteamID() == host_id:
		print("내가 호스트입니다. 클라이언트 생성을 건너뜁니다.")
		return

	# 클라이언트 Peer 생성
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	var error = peer.create_client(host_id, 0)
	
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("네트워크 연결 성공 (클라이언트)")
	else:
		print("네트워크 연결 실패: ", error)
		
	state = STATE.LOBBY
	friend_lobbies.visible = false
	lobby.visible = true
		
	is_joining = false
	

#func _add_player(id: int = 1):
	#if not multiplayer.is_server():
		#return
#
	#if has_node(str(id)):
		#return
		##
		

func spawn_player(id: int = 1):
	if has_node(str(id)):
		print("이미 존재하는 플레이어입니다: ", id)
		return
	var player = PLAYER.instantiate()
	player.name = str(id)
	#player.set_multiplayer_authority(id)
	var host_steam_id = Steam.getLobbyOwner(lobby_id)
	var member_steam_id = peer.get_steam_id_for_peer_id(id)
	if id == 1 or member_steam_id == host_steam_id:
		player.is_host_player = true
		if stage:
			player.position = stage.spawn_1.position
		print("host player spawned")
	else:
		player.is_host_player = false
		if stage:
			player.position = stage.spawn_2.position
		print("client player spawned")
	
	
	add_child(player, true)
	
	print("플레이어 스폰 완료 ID : " + str(id))
	
func _remove_player(id : int):
	#player_info.erase(id)
	if players.has(id):
		players.erase(id) # 딕셔너리에서 제거
		
	if has_node(str(id)):
		get_node(str(id)).queue_free()
		
	player_ids = [1]

func _on_host_button_pressed() -> void:
	host_lobby()
	host_button.release_focus()
	
	mainmenu.visible = false
	lobby.visible = true
	state = STATE.LOBBY
	
#func _on_id_prompt_text_changed(new_text: String) -> void:
	#join_button.disabled = (new_text.length()  == 0)

#func _on_join_button_pressed() -> void:
	#join_lobby(id_prompt.text.to_int())
	#join_button.release_focus()


# --- Bounce 수정 ---
func _on_button_bounce_pressed() -> void:
	var new_val = value_bounce.text.to_float()
	# 1. 모든 피어(서버+클라이언트)에게 이 함수를 실행하라고 보냄
	f_bounce.rpc(new_val)
	value_bounce.text = ""
	button_bounce.release_focus()

@rpc("any_peer", "call_local")
func f_bounce(new_val: float):
	# 2. 모든 유저의 컴퓨터에서 이 루프가 돌아감
	for pk in players:
		var p = players[pk]
		# 3. [중요] 각 유저는 '내가 주인인 캐릭터'만 수정함
		# 이렇게 해야 각자의 Synchronizer가 작동하여 네트워크 동기화가 발생함
		if p and p.is_multiplayer_authority():
			p.bounce = new_val

# --- Additional Force 수정 ---
func _on_button_additional_pressed() -> void:
	var new_val = value_additional.text.to_float()
	f_additional.rpc(new_val)
	value_additional.text = ""
	button_additional.release_focus()

@rpc("any_peer", "call_local")
func f_additional(new_val: float):
	for pk in players:
		var p = players[pk]
		if p and p.is_multiplayer_authority():
			p.additional_force = new_val

# --- Torque Power 수정 ---
func _on_button_torque_pressed() -> void:
	var new_val = value_torque.text.to_float()
	f_torque.rpc(new_val)
	value_torque.text = ""
	button_torque.release_focus()

@rpc("any_peer", "call_local")
func f_torque(new_val: float):
	for pk in players:
		var p = players[pk]
		if p and p.is_multiplayer_authority():
			p.torque_power = new_val

# --- Jump Power 수정 ---
func _on_button_jump_pressed() -> void:
	var new_val = value_jump.text.to_float()
	f_jump.rpc(new_val)
	value_jump.text = ""
	button_jump.release_focus()

@rpc("any_peer", "call_local")
func f_jump(new_val: float):
	for pk in players:
		var p = players[pk]
		if p and p.is_multiplayer_authority():
			p.jump_power = new_val

# --- Initialize (Reset) 수정 ---
func _on_button_reset_pressed() -> void:
	initialize.rpc()
	button_reset.release_focus()

@rpc("any_peer", "call_local")
func initialize():
	for pk in players:
		var p = players[pk]
		if p and p.is_multiplayer_authority():
			p.initialize()
	
func _on_lobby_button_pressed() -> void:
	mainmenu.visible = false
	friend_lobbies.visible = true
	state = STATE.FRIEND_LOBBIES
	refresh_friends_lobbies()

func refresh_friends_lobbies() -> void:
	# 1. 온라인 상태인 친구 목록 가져오기 (IMMEDIATE: 현재 접속 중인 친구)
	var friend_count = Steam.getFriendCount(Steam.FRIEND_FLAG_IMMEDIATE)
	var my_app_id = Steam.getAppID()
	
	# UI 리스트 초기화 (예: ScrollContainer 내의 VBoxContainer)
	for child in member_list.get_children():
		child.queue_free()

	for i in range(friend_count):
		var steam_id = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var friend_name = Steam.getFriendPersonaName(steam_id)
		
		# 2. 해당 친구가 우리 게임을 하는지, 로비에 있는지 확인
		var game_info = Steam.getFriendGamePlayed(steam_id)
		
		# game_info 구조: {"id": AppID, "lobby": LobbyID, "ip": ..., "port": ...}
		if game_info.size() > 0 and game_info["id"] == my_app_id and game_info.has("lobby"):
			var lobby_id = game_info["lobby"]
			
			# 로비 ID가 유효하다면(0보다 크다면) UI 버튼 생성
			if lobby_id > 0:
				_create_friend_lobby_button(friend_name, lobby_id, steam_id)

func _create_friend_lobby_button(friend_name: String, lobby_id: int, steam_id: int) -> void:
	var h_box = HBoxContainer.new()
	
	# 친구 아바타 (이전에 만든 get_steam_avatar 함수 활용)
	var avatar_rect = TextureRect.new()
	avatar_rect.texture = get_steam_avatar(steam_id) # 캐싱 권장
	avatar_rect.custom_minimum_size = Vector2(32, 32)
	avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	# 친구 이름 레이블
	var name_label = Label.new()
	name_label.text = friend_name
	
	# 참여 버튼
	var join_btn = Button.new()
	join_btn.text = "JOIN"
	# 버튼 클릭 시 해당 lobby_id를 인자로 전달하여 join_lobby 실행
	join_btn.pressed.connect(func(): join_lobby(lobby_id))
	
	h_box.add_child(avatar_rect)
	h_box.add_child(name_label)
	h_box.add_child(join_btn)
	
	member_list.add_child(h_box)

func _on_button_ready_pressed() -> void:
	# 현재 상태 읽기 (기존에 1이었으면 0으로, 0이었으면 1로 토글)
	var my_steam_id = Steam.getSteamID()
	var current_status = Steam.getLobbyMemberData(lobby_id, my_steam_id, "ready")
	
	var new_status = "1" if current_status != "1" else "0"
	
	# Steam 서버에 내 레디 상태 저장 (문자열만 가능)
	Steam.setLobbyMemberData(lobby_id, "ready", new_status)
	
	print("내 레디 상태 변경 완료: ", new_status)
	# 로컬 UI는 아래 신호(lobby_data_update)를 통해 자동으로 갱신됩니다.


func _on_button_refresh_pressed() -> void:
	refresh_friends_lobbies()


func _on_timer_win_timeout() -> void:
	state = STATE.LOBBY
	if stage:
		stage.queue_free()
		stage = null
	for pk in players:
		var p = players[pk]
		if p:
			p.queue_free()
		#var p_steam_id = peer.get_steam_id_for_peer_id(p.name.to_int())
		Steam.setLobbyMemberData(lobby_id, "ready", "0")
		
		
	players.clear()
	#player_ids.clear() # ID 리스트도 초기화 필수
	mainmenu.visible = false
	friend_lobbies.visible = false
	game_ui.visible = false
	lobby.visible = true
	


func _on_single_button_pressed() -> void:
	mainmenu.visible = false
	lobby_single.visible = true
	state = STATE.LOBBY_SINGLE


func _on_single_start_button_pressed() -> void:
	lobby_single.visible = false
	state = STATE.GAME_SINGLE
	single_game_start()
	
const PLAYER_SINGLE = preload("uid://cwqqe8ake83qo")
const PLAYER_AI = preload("uid://c26cids0j3463")

var is_single_game = false
func single_game_start():
	
	is_single_game = true
	is_local_game = false
	camera_2d.position = Vector2.ZERO
	state = STATE.GAME_SINGLE
	var s = stages[1].instantiate()
	add_child(s)
	stage = s
	var p
	p = PLAYER_SINGLE.instantiate()
	p.name = "1"
	p.is_host_player = true
	add_child(p)
	p = PLAYER_AI.instantiate()
	p.name = "2"
	add_child(p)
	
func single_win(num):
	if state != STATE.GAME_SINGLE and state != STATE.GAME_LOCAL:
		return
	print("win " + str(num))
	if state == STATE.GAME_SINGLE:
		state = STATE.GAMEWIN_SINGLE
	else:
		state = STATE.GAMEWIN_LOCAL
	var p1 = null
	var p2 = null
	for pk in players:
		var p = players[pk]
		if !p:
			continue
		if p.is_host_player:
			p1 = players[pk]
		else:
			p2 = players[pk]
			
	for id in players:
		var p:Node2D = players[id]
		p.set_deferred_thread_group("freeze", true)
		p.end = true
		print("freeze " + str(id))
	game_ui.visible = true
	if num == 1:
		
		var member_name = Steam.getPersonaName()
		if state == STATE.GAMEWIN_LOCAL:
			member_name = "Player 1"
		label_win.text = member_name + " won"
	else:
		var member_name = "AI"
		if state == STATE.GAMEWIN_LOCAL:
			member_name = "Player 2"
		label_win.text = member_name + " won"
	$TimerWinSingle.start()
	
func _on_timer_win_single_timeout() -> void:
	if stage:
		stage.queue_free()
		stage = null
	for pk in players:
		var p = players[pk]
		if p:
			p.queue_free()
		
		
	players.clear()
	mainmenu.visible = false
	friend_lobbies.visible = false
	game_ui.visible = false
	if state == STATE.GAMEWIN_SINGLE:
		lobby_single.visible = true
		state = STATE.LOBBY_SINGLE
	else:
		lobby_local.visible = true
		state = STATE.LOBBY_LOCAL


func _on_local_button_pressed() -> void:
	mainmenu.visible = false
	lobby_local.visible = true
	state = STATE.LOBBY_LOCAL


func _on_local_start_button_pressed() -> void:
	lobby_local.visible = false
	state = STATE.GAME_LOCAL
	local_game_start()
	
const PLAYER_LOCAL_ALTER = preload("uid://bnw6ygsrlbhmt")	
var is_local_game = false
func local_game_start():
	
	is_local_game = true
	is_single_game = false
	camera_2d.position = Vector2.ZERO
	state = STATE.GAME_LOCAL
	var s = stages[1].instantiate()
	add_child(s)
	stage = s
	var p
	p = PLAYER_SINGLE.instantiate()
	p.name = "1"
	p.is_host_player = true
	add_child(p)
	p = PLAYER_LOCAL_ALTER.instantiate()
	p.name = "2"
	add_child(p)
	
