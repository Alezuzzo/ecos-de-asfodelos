extends CanvasLayer

signal melhoria_selecionada(id_carta: String)

# Esta variável precisa ser preenchida no inspetor do Godot, array[].
# Arraste as três CardUI (CardChoice1, 2, 3) para cá no Inspetor.
@export var card_choices: Array[Control]

# Guarda os IDs das 3 cartas que estão sendo mostradas na tela.
var cartas_atuais = []

func _ready():
	# Verifica se as cartas foram ligadas
	if card_choices.size() == 3:
		for card_ui_node in card_choices:
			card_ui_node.card_chosen.connect(_on_card_chosen)
	else:
		print("ERRO CRÍTICO: Arraste as 3 instâncias de CardUI para a variável 'Card Choices' no Inspetor do nó TelaMelhorias!")

func preparar_e_mostrar():
	# Verificação de segurança
	if card_choices.size() < 3: return

	# Sorteia 3 cartas do nosso DB
	cartas_atuais = CardDB.sortear_cartas(3)
	if cartas_atuais.size() < 3: return
	
	# Configura cada uma das 3 CardUI na tela.
	for i in range(3):
		if card_choices[i]:
			# Garante que o container esteja visível.
			card_choices[i].show()
			
			# Envia os dados da carta sorteada para a UI correspondente.
			card_choices[i].set_card_data(cartas_atuais[i])
		else:
			print("Aviso: CardChoice", i+1, " não foi ligado no Inspetor.")
	
	# mostra a tela inteira
	show()

# Função chamada quando o sinal 'card_chosen' é recebido de qualquer uma das cartas.
func _on_card_chosen(id_carta: String):
	# Emite o sinal para a Arena saber qual carta foi escolhida.
	emit_signal("melhoria_selecionada", id_carta)
	
	# Esconde a tela e despausa o jogo para a próxima onda começar.
	hide()
	get_tree().paused = false
