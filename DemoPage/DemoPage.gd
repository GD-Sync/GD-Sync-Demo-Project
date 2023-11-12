extends Node

enum INSTRUCTION_TYPES {KEYBOARD, JOYPAD}

@onready var demo_page_root: Control = $CanvasLayer/DemoPageRoot
@onready var resume_button: Button = $CanvasLayer/DemoPageRoot/Content/MarginContainer/Buttons/Resume
@onready var exit_button: Button = $CanvasLayer/DemoPageRoot/Content/MarginContainer/Buttons/Exit

@onready var _demo_mouse_mode: int


func _ready() -> void:
	_demo_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	resume_button.pressed.connect(resume_demo)
	exit_button.pressed.connect(exit)
	
	resume_demo()

func exit():
#	Leave the current lobby
	GDSync.leave_lobby()
	
#	Return to the lobby browser
	get_tree().change_scene_to_file("res://Menus/lobby_browsing_menu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			resume_demo()
		else:
			pause_demo()


func pause_demo() -> void:
	_demo_mouse_mode = Input.mouse_mode
	demo_page_root.show()
	var tween := create_tween()
	tween.tween_property(demo_page_root, "modulate", Color.WHITE, 0.3)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume_demo() -> void:
	var tween := create_tween()
	tween.tween_property(demo_page_root, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(demo_page_root.hide)
	Input.mouse_mode = _demo_mouse_mode
