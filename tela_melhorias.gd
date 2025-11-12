extends CanvasLayer

signal melhoria_selecionada(id_carta: String)

@export var card_choices: Array[Control]
var cartas_atuais = []

func _ready():
	if card_choices.size() == 3:
		for card_ui_node in card_choices:
			card_ui_node.card_chosen.connect(_on_card_chosen)
	else:
		print("ERRO: Arraste as 3 instâncias de CardUI para 'Card Choices' no Inspetor!")

func preparar_e_mostrar():
	if card_choices.size() < 3: return

	cartas_atuais = CardDB.sortear_cartas(3)
	if cartas_atuais.size() < 3: return

	for i in range(3):
		if card_choices[i]:
			card_choices[i].show()
			card_choices[i].set_card_data(cartas_atuais[i])

	show()

func _on_card_chosen(id_carta: String):
	emit_signal("melhoria_selecionada", id_carta)
	hide()
	get_tree().paused = false
