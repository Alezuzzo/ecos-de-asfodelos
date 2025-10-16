# res://scenes/menu/PressStart.gd
extends Control

const MAIN_MENU := "res://scenes/menu/MainMenu.tscn"
@onready var ap: AnimationPlayer = $"PressLabel/AnimationPlayer"

var _can_accept := false

func _ready() -> void:
	# garante que a animação toca
	if ap and not ap.is_playing():
		ap.play("blink")
	# espera um pouquinho pra não pegar o F5
	await get_tree().create_timer(0.25).timeout
	_can_accept = true

func _unhandled_input(event: InputEvent) -> void:
	if not _can_accept:
		return
	if event.is_action_pressed("ui_accept"): # Enter/Espaço/Controle A
		get_tree().change_scene_to_file(MAIN_MENU)
	elif event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file(MAIN_MENU)
