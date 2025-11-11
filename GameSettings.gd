extends Node

const CONFIG_FILE = "user://settings.cfg"
var config = ConfigFile.new()

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var err = config.load(CONFIG_FILE)
	if err == OK:
		# Carregar volume de música
		var music_vol = config.get_value("audio", "music_volume", 100.0)
		var volume_db = linear_to_db(music_vol / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

		# Carregar modo de tela
		var is_fullscreen = config.get_value("video", "fullscreen", true)
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# Configurações padrão na primeira execução
		save_default_settings()

func save_default_settings() -> void:
	config.set_value("audio", "music_volume", 100.0)
	config.set_value("audio", "sfx_volume", 100.0)
	config.set_value("video", "fullscreen", true)
	config.save(CONFIG_FILE)

	# Aplicar configurações padrão
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
