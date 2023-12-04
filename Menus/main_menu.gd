extends Control

func _ready():
#	Connect all signals related to connecting to the servers
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_connect_pressed():
	%Connect.disabled = true
	
#	Start the multiplayer plugin
	GDSync.start_multiplayer()

func _on_quit_pressed():
	get_tree().quit()

func connected():
#	Connected! Continue on to the customization screen
	%Connect.disabled = true
	get_tree().change_scene_to_file("res://Menus/player_customization_menu.tscn")

func connection_failed(error : int):
#	Connection failed. Display the possible error messages
	%Connect.disabled = false
	%Message.modulate = Color.INDIAN_RED
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			%Message.text = "The public or private key you entered were invalid."
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			%Message.text = "Unable to connect, please check your internet connection."
