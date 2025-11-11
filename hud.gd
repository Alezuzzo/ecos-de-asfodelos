extends CanvasLayer

var tex_coracao_cheio = preload("res://assets/coracao_vida/coracao_cheio.png")
var tex_meio_coracao = preload("res://assets/coracao_vida/meio_coracao.png")
var tex_coracao_vazio = preload("res://assets/coracao_vida/coracao_vazio.png")

@onready var container_coracoes = $ContainerCoracoes
@onready var foco_timer_ui = $FocoTimerUI # Pega a referência da ProgressBar
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
	foco_timer_ui.value = progresso * 100.0

func atualizar_coracoes(saude_atual, saude_maxima):
	#Limpa os corações antigos que estavam na tela.
	for filho in container_coracoes.get_children():
		filho.queue_free()
	var total_de_containers = ceili(saude_maxima / 2.0)

	for i in range(total_de_containers):
		var valor_do_espaco = (i + 1) * 2

		var tr = TextureRect.new()

		if saude_atual >= valor_do_espaco:
			tr.texture = tex_coracao_cheio
		elif saude_atual == valor_do_espaco - 1:
			tr.texture = tex_meio_coracao
		else:
			tr.texture = tex_coracao_vazio

		container_coracoes.add_child(tr)

func _on_pause_button_pressed():
	# Busca o PauseMenu na arena e abre
	var arena = get_parent()
	if arena:
		var pause_menu = arena.get_node_or_null("PauseMenu")
		if pause_menu and pause_menu.has_method("toggle_pause"):
			pause_menu.toggle_pause()
