extends Control

# Referências dos nós
@onready var music_slider: HSlider = $Root/VBox/MusicVolume/VolumeSlider
@onready var music_label: Label = $Root/VBox/MusicVolume/VolumeLabel
@onready var sfx_slider: HSlider = $Root/VBox/SFXVolume/VolumeSlider
@onready var sfx_label: Label = $Root/VBox/SFXVolume/VolumeLabel
@onready var fullscreen_button: Button = $Root/VBox/FullscreenToggle/ToggleButton
@onready var back_button: Button = $Root/VBox/BackButton/Button

@onready var arrow_music: Label = $Root/VBox/MusicVolume/Arrow
@onready var arrow_sfx: Label = $Root/VBox/SFXVolume/Arrow
@onready var arrow_fullscreen: Label = $Root/VBox/FullscreenToggle/Arrow
@onready var arrow_back: Label = $Root/VBox/BackButton/Arrow

const CONFIG_FILE = "user://settings.cfg"
var config = ConfigFile.new()

func _ready() -> void:
	# Carregar configurações salvas
	_load_settings()

	# Configurar setas
	for arrow in [arrow_music, arrow_sfx, arrow_fullscreen, arrow_back]:
		if arrow == null: continue
		if arrow.text.strip_edges() == "": arrow.text = "▶"
		arrow.visible = false
		if arrow.custom_minimum_size == Vector2.ZERO:
			arrow.custom_minimum_size = Vector2(32, 32)
		arrow.pivot_offset = arrow.size / 2.0
		arrow.resized.connect(func(): arrow.pivot_offset = arrow.size / 2.0)

	# Configurar sliders
	for slider in [music_slider, sfx_slider]:
		if slider == null: continue
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 5.0
		slider.focus_mode = Control.FOCUS_ALL
		slider.mouse_entered.connect(func(): slider.grab_focus())

	# Conectar sinais dos sliders
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Conectar foco dos sliders às setas
	music_slider.focus_entered.connect(func():
		arrow_music.visible = true
		_tint(music_label, Color(0.95, 0.85, 0.55))
	)
	music_slider.focus_exited.connect(func():
		arrow_music.visible = false
		_tint(music_label, Color.WHITE)
	)

	sfx_slider.focus_entered.connect(func():
		arrow_sfx.visible = true
		_tint(sfx_label, Color(0.95, 0.85, 0.55))
	)
	sfx_slider.focus_exited.connect(func():
		arrow_sfx.visible = false
		_tint(sfx_label, Color.WHITE)
	)

	# Configurar botões
	for btn in [fullscreen_button, back_button]:
		if btn == null: continue
		btn.flat = true
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_entered.connect(func(): btn.grab_focus())

	# Conectar foco dos botões às setas
	_wire_arrow(fullscreen_button, arrow_fullscreen)
	_wire_arrow(back_button, arrow_back)

	# Conectar ações dos botões
	fullscreen_button.pressed.connect(_on_fullscreen_toggle)
	back_button.pressed.connect(_on_back_pressed)

	# Atualizar labels iniciais
	_update_music_label(music_slider.value)
	_update_sfx_label(sfx_slider.value)
	_update_fullscreen_button()

	# Foco inicial
	music_slider.grab_focus()

func _wire_arrow(btn: Button, arrow: Label) -> void:
	if btn == null or arrow == null: return
	btn.focus_entered.connect(func():
		arrow.visible = true
		_tint(btn, Color(0.95, 0.85, 0.55))
	)
	btn.focus_exited.connect(func():
		arrow.visible = false
		_tint(btn, Color.WHITE)
	)

func _tint(node: CanvasItem, col: Color) -> void:
	var tw := create_tween()
	tw.tween_property(node, "modulate", col, 0.08)

func _on_music_volume_changed(value: float) -> void:
	var volume_db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)
	_update_music_label(value)
	_save_settings()

func _on_sfx_volume_changed(value: float) -> void:
	# Por enquanto, controla o mesmo bus Master
	# Se você criar um bus separado para SFX no AudioBus, pode usar aqui
	_update_sfx_label(value)
	_save_settings()

func _update_music_label(value: float) -> void:
	music_label.text = "MÚSICA: %d%%" % int(value)

func _update_sfx_label(value: float) -> void:
	sfx_label.text = "EFEITOS: %d%%" % int(value)

func _on_fullscreen_toggle() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_button()
	_save_settings()

func _update_fullscreen_button() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_button.text = "TELA CHEIA: SIM"
	else:
		fullscreen_button.text = "TELA CHEIA: NÃO"

func _on_back_pressed() -> void:
	queue_free()

func _save_settings() -> void:
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	config.set_value("video", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	config.save(CONFIG_FILE)

func _load_settings() -> void:
	var err = config.load(CONFIG_FILE)
	if err == OK:
		# Carregar volume de música
		var music_vol = config.get_value("audio", "music_volume", 100.0)
		music_slider.value = music_vol
		var volume_db = linear_to_db(music_vol / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

		# Carregar volume de SFX
		var sfx_vol = config.get_value("audio", "sfx_volume", 100.0)
		sfx_slider.value = sfx_vol

		# Carregar modo de tela
		var is_fullscreen = config.get_value("video", "fullscreen", true)
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		# Valores padrão
		music_slider.value = 100.0
		sfx_slider.value = 100.0
