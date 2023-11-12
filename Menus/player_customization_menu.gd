extends Control

func _ready():
#	Make sure to handle disconnects!
	GDSync.disconnected.connect(disconnected)

func _on_back_pressed():
	GDSync.stop_multiplayer()

func disconnected():
#	Diconnected. Jump back to main menu
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")

func _on_continue_pressed():
	if %Username.text.length() == 0: return
	
#	Set the player's username so it may be displayed in lobbies and games.
	GDSync.set_player_username(%Username.text)
	
#	Set any other custom player data, in this case the player color
	GDSync.set_player_data("Color", %Color.color)
	
	get_tree().change_scene_to_file("res://Menus/lobby_browsing_menu.tscn")

