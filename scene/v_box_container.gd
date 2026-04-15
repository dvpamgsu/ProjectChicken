extends VBoxContainer

@onready var list = $CharacterList
var current_profile_code := 1
@onready var current_profile: Button = $CurrentProfile
@onready var v_box_container: VBoxContainer = $CharacterList/VBoxContainer
@onready var select: Node2D = $".."


var main
var character_num = 2
var icons = []

func set_icon(code):
	current_profile.icon = icons[code-1]
	current_profile_code = code

func _ready():
	main = get_node("/root/Main")
	character_num = main.character_num
	list.visible = false # 처음에는 목록을 숨김
	
	for i in character_num:
		var _name = "chicken_profile" + str(i+1) + ".png"
		var tex = load("res://texture/player/" + _name)
		icons.append(tex)
		
		# 1. 버튼 생성 및 설정
		var b := Button.new()
		b.icon = tex
		b.size = Vector2(40, 40)
		#b.expand_icon = true # 아이콘 크기를 버튼에 맞게 조절 (선택사항)
		#b.custom_minimum_size = Vector2(0, 60) # 버튼의 최소 높이 설정 (선택사항)
		
		# 2. 버튼 클릭 시 실행될 함수 연결 (아이콘 정보를 함께 보냄)
		b.pressed.connect(_on_character_selected.bind(tex, i+1))
		
		# 3. v_box_container의 자식으로 추가
		v_box_container.add_child(b)

# 리스트 안의 캐릭터 버튼을 눌렀을 때 실행되는 함수
func _on_character_selected(selected_tex: Texture2D, code: int):
	# 1. 현재 프로필 버튼의 아이콘을 선택한 아이콘으로 변경
	current_profile.icon = selected_tex
	current_profile_code = code
	# 2. 리스트 숨기기
	list.visible = false
	select.emit_signal("changed")

# 메인 프로필 버튼을 눌렀을 때
func _on_current_profile_pressed():
	list.visible = !list.visible
