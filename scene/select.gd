extends Node2D
@onready var character_selector: VBoxContainer = $CharacterSelector
@onready var current_profile: Button = $CharacterSelector/CurrentProfile

func enable_selector():
	current_profile.disabled = false
	character_selector.mouse_filter = Control.MOUSE_FILTER_PASS

func disable_selector():
	current_profile.disabled = true
	character_selector.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_icon(code):
	character_selector.set_icon(code)

signal changed
