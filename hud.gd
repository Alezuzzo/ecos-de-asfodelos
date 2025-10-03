# hud.gd
extends CanvasLayer

# Verifique se os caminhos para as suas imagens estão corretos
var tex_coracao_cheio = preload("res://assets/coracao_vida/coracao_cheio.png")
var tex_meio_coracao = preload("res://assets/coracao_vida/meio_coracao.png")
var tex_coracao_vazio = preload("res://assets/coracao_vida/coracao_vazio.png")

@onready var container_coracoes = $ContainerCoracoes
@onready var foco_timer_ui = $FocoTimerUI # Pega a referência da nossa ProgressBar
@onready var notificacao_label = $NotificacaoLabel
@onready var notificacao_timer = $NotificacaoTimer

func mostrar_notificacao(texto: String):
	notificacao_label.text = texto
	notificacao_label.show()
	notificacao_timer.start()

func _on_notificacao_timer_timeout():
	notificacao_label.hide()

func mostrar_timer_foco(visivel: bool):
	foco_timer_ui.visible = visivel

func atualizar_timer_foco(progresso: float):
	# O valor da ProgressBar vai de 0 a 100
	foco_timer_ui.value = progresso * 100.0

# --- ESTA É A FUNÇÃO ATUALIZADA ---
func atualizar_coracoes(saude_atual, saude_maxima):
	# 1. Limpa os corações antigos que estavam na tela.
	for filho in container_coracoes.get_children():
		filho.queue_free()
		
	# 2. Calcula o número total de "espaços" de coração que precisamos mostrar.
	# Ex: 6 de vida máxima / 2 = 3 espaços de coração.
	var total_de_containers = ceili(saude_maxima / 2.0)
	
	# 3. Agora, vamos percorrer cada espaço e decidir o que desenhar.
	for i in range(total_de_containers):
		# O valor de vida que este espaço representa.
		# O primeiro coração (i=0) representa até 2 de vida.
		# O segundo (i=1) representa até 4 de vida, e assim por diante.
		var valor_do_espaco = (i + 1) * 2
		
		var tr = TextureRect.new()
		
		if saude_atual >= valor_do_espaco:
			# Se nossa vida atual é maior ou igual ao valor do espaço, o coração está cheio.
			# Ex: vida=5, espaço=4 -> coração cheio.
			tr.texture = tex_coracao_cheio
		elif saude_atual == valor_do_espaco - 1:
			# Se nossa vida for exatamente 1 a menos que o valor do espaço, é meio coração.
			# Ex: vida=3, espaço=4 -> meio coração.
			tr.texture = tex_meio_coracao
		else:
			# Caso contrário, o coração está vazio.
			# Ex: vida=3, espaço=6 -> coração vazio.
			tr.texture = tex_coracao_vazio
			
		container_coracoes.add_child(tr)
