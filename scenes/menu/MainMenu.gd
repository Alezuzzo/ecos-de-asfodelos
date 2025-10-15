extends Control

@onready var start_button: Button   = $Root/VBox/StartButton
@onready var options_button: Button = $Root/VBox/OptionsButton
@onready var quit_button: Button    = $Root/VBox/QuitButton

const GAME_SCENE := "res://arena.tscn"  # mude se sua cena do jogo estiver em outro caminho

func _ready() -> void:
	start_button.grab_focus()  # foco inicial para teclado/controle
	start_button.pressed.connect(_on_start)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)

func _on_start() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_options() -> void:
	_flash("OPTIONS (em breve)")  # troque pela sua tela de opções depois

func _on_quit() -> void:
	get_tree().quit()

func _flash(msg: String) -> void:
	var l := Label.new()
	l.text = msg
	l.modulate.a = 0.0
	add_child(l)
	l.global_position = Vector2(40, get_viewport_rect().size.y - 60)
	var t = create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.15)
	t.tween_interval(0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.2)
	await t.finished
	l.queue_free()
