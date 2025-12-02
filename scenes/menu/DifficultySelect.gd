extends Control

signal difficulty_selected(difficulty: String)

@onready var easy_button: Button = $Panel/VBox/EasyButton
@onready var normal_button: Button = $Panel/VBox/NormalButton
@onready var hard_button: Button = $Panel/VBox/HardButton
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	easy_button.pressed.connect(_on_easy_pressed)
	normal_button.pressed.connect(_on_normal_pressed)
	hard_button.pressed.connect(_on_hard_pressed)
	back_button.pressed.connect(_on_back_pressed)

	for btn in [easy_button, normal_button, hard_button, back_button]:
		if btn:
			btn.focus_mode = Control.FOCUS_ALL
			btn.mouse_entered.connect(func(): btn.grab_focus())

	normal_button.grab_focus()

func _on_easy_pressed() -> void:
	GameSettings.set_difficulty("easy")
	get_tree().change_scene_to_file("res://arena.tscn")

func _on_normal_pressed() -> void:
	GameSettings.set_difficulty("normal")
	get_tree().change_scene_to_file("res://arena.tscn")

func _on_hard_pressed() -> void:
	GameSettings.set_difficulty("hard")
	get_tree().change_scene_to_file("res://arena.tscn")

func _on_back_pressed() -> void:
	queue_free()
