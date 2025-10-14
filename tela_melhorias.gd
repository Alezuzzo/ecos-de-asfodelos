# tela_melhorias.gd
extends CanvasLayer

signal melhoria_selecionada(id_carta: String)

@export var card_choices: Array[Control]

var cartas_atuais = []

func _ready():
	print("TelaMelhorias: Cena pronta.")
	if card_choices.size() == 3:
		print("TelaMelhorias: Três instâncias de CardUI foram ligadas no editor. Conectando sinais...")
		for card_ui_node in card_choices:
			card_ui_node.card_chosen.connect(_on_card_chosen)
	else:
		print("!!!! ERRO CRÍTICO em _ready(): A variável 'Card Choices' no Inspetor não tem 3 elementos. Arraste as instâncias de CardUI para ela.")

func preparar_e_mostrar():
	print("--- Arena chamou preparar_e_mostrar() ---")
	
	if card_choices.size() < 3:
		print("!!!! FALHA: A função parou porque a variável 'Card Choices' não tem 3 elementos no Inspetor.")
		return

	print("TelaMelhorias: Sorteando cartas do CardDB...")
	cartas_atuais = CardDB.sortear_cartas(3)
	
	if cartas_atuais.size() < 3:
		print("!!!! FALHA: O CardDB não retornou 3 cartas. Verifique o script CardDB.gd.")
		return
	
	print("TelaMelhorias: Cartas sorteadas com sucesso. IDs:", cartas_atuais)
	print("TelaMelhorias: Configurando os dados de cada carta na UI...")
	for i in range(3):
		if card_choices[i]:
			card_choices[i].set_card_data(cartas_atuais[i])
		else:
			print("!!!! FALHA: A carta na posição", i, "não está ligada no Inspetor.")
			return
	
	print("TelaMelhorias: Configuração concluída. Tornando a tela visível agora!")
	show()

func _on_card_chosen(id_carta: String):
	print("TelaMelhorias: Carta '", id_carta, "' foi escolhida.")
	emit_signal("melhoria_selecionada", id_carta)
	hide()
	get_tree().paused = false
