extends PanelContainer

func _ready():
#	Connect events related to lobby creation
	GDSync.lobby_created.connect(lobby_created)
	GDSync.lobby_creation_failed.connect(lobby_creation_failed)

func _on_back_pressed():
	visible = false
	%CreateMessage.text = ""

func _on_create_pressed():
	GDSync.create_lobby(
		%LobbyName.text,
		%Password.text,
		%Visible.button_pressed,
		%PlayerLimit.value,
		{
			"Gamemode" : "Co-op"
		}
	)

func lobby_created(lobby_name : String):
#	Lobby created! After a lobby is created you can join it.
	%LobbyJoiner.join_instant(lobby_name, %Password.text)

func lobby_creation_failed(lobby_name : String, error : int):
#	Lobby failed to create. Display the error message.
	%CreateMessage.modulate = Color.INDIAN_RED
	match(error):
		ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS:
			%CreateMessage.text = "A lobby with the name "+lobby_name+" already exists."
		ENUMS.LOBBY_CREATION_ERROR.NAME_TOO_LONG:
			%CreateMessage.text = lobby_name+" is too long."
		ENUMS.LOBBY_CREATION_ERROR.NAME_TOO_SHORT:
			%CreateMessage.text = lobby_name+" is too short."
		ENUMS.LOBBY_CREATION_ERROR.PASSWORD_TOO_LONG:
			%CreateMessage.text = "The password for "+lobby_name+" is too long."
		ENUMS.LOBBY_CREATION_ERROR.TAGS_TOO_LARGE:
			%CreateMessage.text = "The tags have exceeded the 2048 byte limit."
		ENUMS.LOBBY_CREATION_ERROR.DATA_TOO_LARGE:
			%CreateMessage.text = "The data have exceeded the 2048 byte limit."
		ENUMS.LOBBY_CREATION_ERROR.ON_COOLDOWN:
			%CreateMessage.text = "Please wait a few seconds before creating another lobby."

