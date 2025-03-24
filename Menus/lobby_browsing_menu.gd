extends Control

func _ready():
#	Make sure to handle disconnects!
	GDSync.disconnected.connect(disconnected)
	
	if GDSync.steam_integration_enabled():
		GDSync.steam_join_request.connect(_on_lobby_browser_join_pressed)

func disconnected():
#	Diconnected. Jump back to main menu
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Menus/player_customization_menu.tscn")

func _on_create_lobby_pressed():
	%LobbyCreator.visible = true

func _on_join_manual_pressed():
	%LobbyJoiner.join_manual()

func _on_lobby_browser_join_pressed(lobby_name : String, has_password : bool):
	if has_password:
		%LobbyJoiner.join_password_protected(lobby_name)
	else:
		%LobbyJoiner.join_instant(lobby_name)
