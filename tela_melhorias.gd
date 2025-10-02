# tela_melhorias.gd
extends CanvasLayer

signal melhoria_selecionada(id_carta: String)

# Esta variável PRECISA ser preenchida no Inspetor do Godot.
@export var botoes: Array[Button]

var cartas_atuais = []

func _ready():
	# Garante que temos 3 botões ligados antes de conectar os sinais
	if botoes.size() == 3:
		botoes[0].pressed.connect(_on_botao_pressionado.bind(0))
		botoes[1].pressed.connect(_on_botao_pressionado.bind(1))
		botoes[2].pressed.connect(_on_botao_pressionado.bind(2))
	else:
		print("ERRO CRÍTICO: Arraste os 3 nós de botão para a variável 'Botoes' no Inspetor do nó TelaMelhorias!")

func preparar_e_mostrar():
	# Verificação de segurança para garantir que os botões foram ligados no editor
	if botoes.size() < 3:
		print("ERRO: A tela de melhorias não pode ser mostrada porque os botões não foram ligados no Inspetor.")
		return

	cartas_atuais = CardDB.sortear_cartas(3)
	if cartas_atuais.size() < 3: return
	
	for i in range(3):
		var id_carta = cartas_atuais[i]
		var info_carta = CardDB.get_card_info(id_carta)
		var botao = botoes[i]
		
		if info_carta:
			botao.text = info_carta["nome"]
			
			if info_carta.has("tipo") and info_carta["tipo"] == "corrompida":
				botao.add_theme_color_override("font_color", Color.CRIMSON)
			else:
				botao.remove_theme_color_override("font_color")
	
	show()

func _on_botao_pressionado(indice_botao):
	emit_signal("melhoria_selecionada", cartas_atuais[indice_botao])
	hide()
	get_tree().paused = false
