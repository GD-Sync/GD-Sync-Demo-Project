extends Control

func _init():
#	Connect all signals for player joining and leaving. Also handle disconnects!
	GDSync.disconnected.connect(disconnected)
	GDSync.host_changed.connect(host_changed)
	GDSync.client_joined.connect(client_joined)
	GDSync.client_left.connect(client_left)
	
#	Expose this function to the plugin so it may be called remotely
	GDSync.expose_func(switch_scene)

func disconnected():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")

func _ready():
#	Show the start button only if this player is the host
	%Start.visible = GDSync.is_host()
	
#	Show the waiting button if not the host
	%Waiting.visible = !GDSync.is_host()

func host_changed(is_host : bool, _new_host_id : int):
#	Update the buttons if the host changes
#	This may happen if the current host leaves
	%Start.visible = is_host
	%Waiting.visible = !is_host

func client_joined(client_id : int):
#	If a player joins display their username and color
	var label : Label = Label.new()
	label.name = str(client_id)
	%PlayerList.add_child(label)
	
#	Get their username using their Client ID. Give an optinoal fallback for if "Username" does not exist
	label.text = GDSync.get_player_data(client_id, "Username", "Unkown")
	
#	Get their color using their Client ID. Give an optional fallback for if "Color" does not exist
	label.modulate = GDSync.get_player_data(client_id, "Color", Color.WHITE)
	
#	Update the current player count display
	%PlayerCount.text = str(GDSync.get_lobby_player_count())+"/"+str(GDSync.get_lobby_player_limit())

func client_left(client_id : int):
#	Remove the client that left from the list
	if %PlayerList.has_node(str(client_id)):
		%PlayerList.get_node(str(client_id)).queue_free()
	
#	Update the current player count display
	%PlayerCount.text = str(GDSync.get_lobby_player_count())+"/"+str(GDSync.get_lobby_player_limit())

func _on_start_pressed():
#	Close the lobby so that no new players can join
	GDSync.close_lobby()
	
#	Call the "switch_scene" function on all other clients in the lobby
	GDSync.call_func(switch_scene)
	
#	Make sure to call it for yourself!
	switch_scene()

func switch_scene():
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_leave_pressed():
#	Leave the current lobby and switch back to the lobby browser
	GDSync.leave_lobby()
	get_tree().change_scene_to_file("res://Menus/lobby_browsing_menu.tscn")
