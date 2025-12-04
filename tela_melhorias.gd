extends CanvasLayer

signal melhoria_selecionada(id_carta: String)

@export var card_choices: Array[Control]
var cartas_atuais = []
var selected_card_index: int = 1  # Começa com a carta do meio selecionada
var analog_cooldown: float = 0.0
const ANALOG_THRESHOLD = 0.5
const COOLDOWN_TIME = 0.3

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if card_choices.size() == 3:
		for card_ui_node in card_choices:
			card_ui_node.card_chosen.connect(_on_card_chosen)
	else:
		print("ERRO: Arraste as 3 instâncias de CardUI para 'Card Choices' no Inspetor!")

func _process(delta: float) -> void:
	if analog_cooldown > 0:
		analog_cooldown -= delta

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Navegação com analógico esquerdo
	var left_stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)

	if analog_cooldown <= 0:
		if left_stick_x > ANALOG_THRESHOLD:
			# Move para direita
			selected_card_index = clamp(selected_card_index + 1, 0, 2)
			update_card_selection()
			analog_cooldown = COOLDOWN_TIME
		elif left_stick_x < -ANALOG_THRESHOLD:
			# Move para esquerda
			selected_card_index = clamp(selected_card_index - 1, 0, 2)
			update_card_selection()
			analog_cooldown = COOLDOWN_TIME

	# Botão A seleciona a carta
	if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed:
		select_current_card()
		get_viewport().set_input_as_handled()

func update_card_selection():
	# Destaca a carta selecionada com escala
	for i in range(card_choices.size()):
		if card_choices[i]:
			if i == selected_card_index:
				# Carta selecionada fica maior
				var tween = create_tween()
				tween.tween_property(card_choices[i], "scale", Vector2(1.1, 1.1), 0.2)
				tween.tween_property(card_choices[i], "modulate", Color(1.2, 1.2, 1.2), 0.2)
				# Mostra a descrição da carta selecionada
				if card_choices[i].has_node("DescriptionLabel"):
					card_choices[i].get_node("DescriptionLabel").show()
			else:
				# Outras cartas voltam ao normal
				var tween = create_tween()
				tween.tween_property(card_choices[i], "scale", Vector2(1.0, 1.0), 0.2)
				tween.tween_property(card_choices[i], "modulate", Color(0.7, 0.7, 0.7), 0.2)
				# Esconde a descrição das cartas não selecionadas
				if card_choices[i].has_node("DescriptionLabel"):
					card_choices[i].get_node("DescriptionLabel").hide()

func select_current_card():
	if selected_card_index >= 0 and selected_card_index < card_choices.size():
		var selected_card = card_choices[selected_card_index]
		if selected_card and not selected_card.is_burning:
			selected_card.start_burn_effect()

func preparar_e_mostrar():
	if card_choices.size() < 3: return

	cartas_atuais = CardDB.sortear_cartas(3)
	if cartas_atuais.size() < 3: return

	for i in range(3):
		if card_choices[i]:
			card_choices[i].show()
			card_choices[i].set_card_data(cartas_atuais[i])

	# Reseta seleção para a carta do meio
	selected_card_index = 1
	update_card_selection()
	show()

func _on_card_chosen(id_carta: String):
	emit_signal("melhoria_selecionada", id_carta)
	hide()
	get_tree().paused = false
