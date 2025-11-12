extends Node2D

@export var cenas_inimigos: Array[PackedScene]
@export var cena_fonte_vida: PackedScene
@export var cena_chefe: PackedScene
@export var game_over_screen_cena: PackedScene
@export var victory_screen_cena: PackedScene

@export_category("MODO TESTE")
@export var MODO_TESTE_ATIVADO = false

@onready var music_combate = $MusicCombate
@onready var boss_music_player = $BossMusicPlayer

var jogador_node = null
var luta_contra_chefe_ativa = false

var onda_atual = 0
var inimigos_vivos = 0
var base_inimigos_por_onda = 3
var onda_do_chefe = 5

var tamanho_da_tela: Vector2

func _ready():
	jogador_node = get_node_or_null("YSortContainer/Jogador")
	tamanho_da_tela = get_viewport_rect().size

	if is_instance_valid(jogador_node):
		var hud_node = get_node_or_null("HUD")
		if is_instance_valid(hud_node):
			jogador_node.hud = hud_node
			jogador_node.saude_alterada.connect(hud_node.atualizar_coracoes)
			hud_node.atualizar_coracoes(jogador_node.saude_atual, jogador_node.saude_maxima)
		else:
			printerr("ERRO CRÍTICO em Arena _ready(): Nó HUD não encontrado.")

		jogador_node.morreu.connect(_on_jogador_morreu)
	else:
		printerr("ERRO CRÍTICO em Arena _ready(): Nó Jogador não encontrado no caminho esperado ($YSortContainer/Jogador).")
		get_tree().quit()

	var tela_melhorias_node = get_node_or_null("TelaMelhorias")
	if is_instance_valid(tela_melhorias_node):
		tela_melhorias_node.melhoria_selecionada.connect(_on_melhoria_selecionada)
	else:
		printerr("ERRO CRÍTICO em Arena _ready(): Nó TelaMelhorias não encontrado.")

	if MODO_TESTE_ATIVADO:
		print("⚠️ MODO TESTE ATIVADO - Iniciando luta contra o chefe!")
		call_deferred("iniciar_luta_chefe")
	else:
		var start_timer = get_node_or_null("StartTimer")
		if is_instance_valid(start_timer): start_timer.start()
		var evento_timer = get_node_or_null("EventoTimer")
		if is_instance_valid(evento_timer): evento_timer.start()

		# Loop manual para compatibilidade com HTML5/Itch.io
		if is_instance_valid(music_combate):
			music_combate.play()
			if not music_combate.finished.is_connected(music_combate.play):
				music_combate.finished.connect(music_combate.play)
		if is_instance_valid(boss_music_player):
			boss_music_player.stop()
			if not boss_music_player.finished.is_connected(boss_music_player.play):
				boss_music_player.finished.connect(boss_music_player.play)


func iniciar_nova_onda():
	if is_instance_valid(jogador_node):
		jogador_node.baluarte_usado_na_onda = false

	onda_atual += 1

	if onda_atual == onda_do_chefe:
		call_deferred("iniciar_luta_chefe")
		return

	print("--- INICIANDO ONDA ", onda_atual, " ---")
	var quantidade_a_spawnar = base_inimigos_por_onda + (onda_atual * 2)
	inimigos_vivos = quantidade_a_spawnar

	call_deferred("_spawn_inimigos_em_loop", quantidade_a_spawnar)

func _spawn_inimigos_em_loop(quantidade):
	for i in range(quantidade):
		if luta_contra_chefe_ativa: return
		spawnar_inimigo()
		await get_tree().create_timer(0.3).timeout

func spawnar_inimigo():
	if luta_contra_chefe_ativa: return
	if not is_instance_valid(jogador_node): return

	var inimigo_escolhido = cenas_inimigos.pick_random()
	if not inimigo_escolhido: return

	var inimigo = inimigo_escolhido.instantiate()
	inimigo.connect("morreu", _on_inimigo_morreu)

	var ysort_container = get_node_or_null("YSortContainer")
	if is_instance_valid(ysort_container):
		ysort_container.add_child(inimigo)
	else:
		printerr("ERRO em spawnar_inimigo: YSortContainer não encontrado.")
		return

	var spawn_pos = Vector2()
	var borda = randi() % 4
	match borda:
		0: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), 50)
		1: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), tamanho_da_tela.y - 50)
		2: spawn_pos = Vector2(50, randf_range(50, tamanho_da_tela.y - 50))
		3: spawn_pos = Vector2(tamanho_da_tela.x - 50, randf_range(50, tamanho_da_tela.y - 50))
	inimigo.global_position = spawn_pos
	inimigo.jogador = jogador_node

func spawnar_inimigo_para_chefe():
	if not is_instance_valid(jogador_node): return

	var inimigo_escolhido = cenas_inimigos.pick_random()
	if not inimigo_escolhido: return
	
	var inimigo = inimigo_escolhido.instantiate()
	inimigo.connect("morreu", _on_inimigo_morreu)
	
	var ysort_container = get_node_or_null("YSortContainer")
	if is_instance_valid(ysort_container):
		ysort_container.add_child(inimigo)
	else:
		printerr("ERRO em spawnar_inimigo_para_chefe: YSortContainer não encontrado.")
		return

	var spawn_pos = Vector2()
	var borda = randi() % 4
	match borda:
		0: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), 50)
		1: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), tamanho_da_tela.y - 50)
		2: spawn_pos = Vector2(50, randf_range(50, tamanho_da_tela.y - 50))
		3: spawn_pos = Vector2(tamanho_da_tela.x - 50, randf_range(50, tamanho_da_tela.y - 50))
	inimigo.global_position = spawn_pos
	inimigo.jogador = jogador_node

func iniciar_luta_chefe():
	print("--- O GUARDIÃO APARECEU! ---")
	luta_contra_chefe_ativa = true
	var evento_timer = get_node_or_null("EventoTimer")
	if is_instance_valid(evento_timer): evento_timer.stop()

	if is_instance_valid(music_combate): music_combate.stop()
	if is_instance_valid(boss_music_player): boss_music_player.play()

	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(inimigo): inimigo.queue_free()

	await get_tree().process_frame

	if not cena_chefe:
		printerr("ERRO CRÍTICO em iniciar_luta_chefe: Cena do Chefe não definida no Inspetor!")
		return
		
	var chefe = cena_chefe.instantiate()
	chefe.name = "Guardiao"
	chefe.position = tamanho_da_tela / 2
	chefe.jogador = jogador_node
	
	var ysort_container = get_node_or_null("YSortContainer")
	if is_instance_valid(ysort_container):
		ysort_container.add_child(chefe)
		chefe.connect("morreu", _on_chefe_morreu)
	else:
		printerr("ERRO CRÍTICO em iniciar_luta_chefe: YSortContainer não encontrado para adicionar o chefe.")

	
func verificar_sinergias(jogador):
	if not is_instance_valid(jogador): return
	if jogador.tem_baluarte_da_alma: return
	var cartas_necessarias = ["vontade_de_ferro", "guardiao_caido", "foco_do_penitente"]
	var tem_todas = true
	for id_carta in cartas_necessarias:
		if not id_carta in jogador.cartas_coletadas:
			tem_todas = false
			break
	if tem_todas:
		print("SINERGIA ATIVADA: Baluarte da Alma!")
		jogador.tem_baluarte_da_alma = true
		var hud_node = get_node_or_null("HUD")
		if is_instance_valid(hud_node) and hud_node.has_method("mostrar_notificacao"):
			hud_node.mostrar_notificacao("Baluarte da alma completo!")

func _on_inimigo_morreu():
	if luta_contra_chefe_ativa: return
	
	inimigos_vivos -= 1
	
	if inimigos_vivos <= 0:
		if onda_atual + 1 == onda_do_chefe:
			call_deferred("iniciar_nova_onda")
		else:
			var activation_timer = get_node_or_null("CardActivationTimer")
			if is_instance_valid(activation_timer): activation_timer.start()

func _on_card_activation_timer_timeout():
	get_tree().paused = true
	var cartomante_sprite = get_node_or_null("CartomanteSprite")
	if is_instance_valid(cartomante_sprite): cartomante_sprite.show()
	var tela_melhorias = get_node_or_null("TelaMelhorias")
	if is_instance_valid(tela_melhorias): tela_melhorias.preparar_e_mostrar()

func _on_chefe_morreu():
	print("VITÓRIA! O Guardião foi libertado.")
	if is_instance_valid(boss_music_player): boss_music_player.stop()
	get_tree().paused = true

	if not victory_screen_cena:
		printerr("ERRO: Cena de Vitória não definida no Inspetor da Arena!")
		return

	var victory_screen = victory_screen_cena.instantiate()
	add_child(victory_screen)
	if victory_screen.has_signal("play_again_pressed"):
		victory_screen.play_again_pressed.connect(_on_play_again_pressed)
	if victory_screen.has_signal("quit_pressed"):
		victory_screen.quit_pressed.connect(_on_victory_quit_pressed)
	if victory_screen.has_method("mostrar_tela"):
		victory_screen.mostrar_tela()


func _on_melhoria_selecionada(id_carta: String):
	var cartomante_sprite = get_node_or_null("CartomanteSprite")
	if is_instance_valid(cartomante_sprite): cartomante_sprite.hide()
	if not is_instance_valid(jogador_node): return
	if not id_carta in jogador_node.cartas_coletadas:
		jogador_node.cartas_coletadas.append(id_carta)
	match id_carta:
		"vontade_de_ferro": jogador_node.aumentar_vida_maxima(2)
		"guardiao_caido": jogador_node.tem_guardiao_caido = true
		"foco_do_penitente": jogador_node.ativar_foco_penitente()
		"coroa_do_martir": jogador_node.ativar_coroa_do_martir()
	verificar_sinergias(jogador_node)
	iniciar_nova_onda()

func _on_start_timer_timeout():
	iniciar_nova_onda()
	
func _on_evento_timer_timeout():
	if luta_contra_chefe_ativa: return
	if randf() < 0.3:
		if not cena_fonte_vida: return
		var fonte = cena_fonte_vida.instantiate()
		fonte.global_position = Vector2(randf_range(50, tamanho_da_tela.x - 50), randf_range(50, tamanho_da_tela.y - 50))
		add_child(fonte)
		print("FONTE DE VIDA APARECEU!")

func _on_jogador_morreu():
	get_tree().call_deferred("set_pause", true)
	if luta_contra_chefe_ativa:
		if is_instance_valid(boss_music_player): boss_music_player.stop()
	else:
		if is_instance_valid(music_combate): music_combate.stop()
	
	var progresso_percent = 0.0
	var max_progresso = float(onda_do_chefe)
	if luta_contra_chefe_ativa:
		var chefe = $YSortContainer.get_node_or_null("Guardiao")
		if is_instance_valid(chefe):
			if "vida_atual" in chefe and "vida_maxima" in chefe:
				if chefe.vida_maxima > 0:
					var progresso_do_chefe = 1.0 - (float(chefe.vida_atual) / float(chefe.vida_maxima))
					progresso_percent = ((max_progresso - 1.0) + progresso_do_chefe) / max_progresso * 100.0
				else: progresso_percent = (max_progresso - 1.0) / max_progresso * 100.0
			else: progresso_percent = (max_progresso - 1.0) / max_progresso * 100.0
	else:
		progresso_percent = (float(onda_atual) - 1.0) / max_progresso * 100.0
		progresso_percent = max(0.0, progresso_percent)
	
	if not game_over_screen_cena:
		printerr("ERRO CRÍTICO: Cena de Game Over não definida no Inspetor da Arena!")
		return
		
	var game_over_screen = game_over_screen_cena.instantiate()
	add_child(game_over_screen)
	game_over_screen.retry_pressed.connect(_on_retry_pressed)
	game_over_screen.quit_pressed.connect(_on_quit_pressed)
	var textura_inimigo = load("res://assets/gameover/boss1.png") 
	var citacao = '"Você parecia forte. Pena que sua alma agora é minha."'
	game_over_screen.setup_screen(progresso_percent, textura_inimigo, citacao)

func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _on_play_again_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn") 

func _on_victory_quit_pressed():
	get_tree().quit()
