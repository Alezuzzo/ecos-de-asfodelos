# arena.gd
extends Node2D

@export var cenas_inimigos: Array[PackedScene]
@export var cena_fonte_vida: PackedScene
@export var cena_chefe: PackedScene
@export var game_over_screen_cena: PackedScene

# --- REFERÊNCIAS PARA OS PLAYERS DE MÚSICA ---
# Garanta que os nós 'MusicCombate' e 'BossMusicPlayer' existam na cena
@onready var music_combate = $MusicCombate
@onready var boss_music_player = $BossMusicPlayer
# ----------------------------------------------

# --- Variáveis de Estado ---
var jogador_node = null
var luta_contra_chefe_ativa = false # Flag principal de controle

# --- Variáveis das Ondas ---
var onda_atual = 0
var inimigos_vivos = 0
var base_inimigos_por_onda = 3
var onda_do_chefe = 5

var tamanho_da_tela: Vector2

#-----------------------------------------------------------------------------
# FUNÇÕES NATIVAS DO GODOT
#-----------------------------------------------------------------------------

func _ready():
	jogador_node = $YSortContainer/Jogador
	tamanho_da_tela = get_viewport_rect().size
	
	# Verifica se o jogador foi encontrado antes de tentar acessá-lo
	if is_instance_valid(jogador_node):
		jogador_node.hud = $HUD
		jogador_node.saude_alterada.connect($HUD.atualizar_coracoes)
		jogador_node.morreu.connect(_on_jogador_morreu)
		# Verifica se o HUD existe antes de atualizar
		if is_instance_valid($HUD):
			$HUD.atualizar_coracoes(jogador_node.saude_atual, jogador_node.saude_maxima)
	else:
		printerr("ERRO CRÍTICO em Arena _ready(): Nó Jogador não encontrado no caminho esperado ($YSortContainer/Jogador).")
		get_tree().quit() # Fecha o jogo se não encontrar o jogador

	# Verifica se a TelaMelhorias existe antes de conectar
	if is_instance_valid($TelaMelhorias):
		$TelaMelhorias.melhoria_selecionada.connect(_on_melhoria_selecionada)
	else:
		printerr("ERRO CRÍTICO em Arena _ready(): Nó TelaMelhorias não encontrado.")


	# Inicia os timers do jogo
	$StartTimer.start()
	$EventoTimer.start()
	
	# Inicia a música de combate (com verificação)
	if is_instance_valid(music_combate): music_combate.play()
	if is_instance_valid(boss_music_player): boss_music_player.stop()

#-----------------------------------------------------------------------------
# LÓGICA DAS ONDAS E INIMIGOS
#-----------------------------------------------------------------------------

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
	# Trava de segurança para ondas normais
	if luta_contra_chefe_ativa: return

	if not is_instance_valid(jogador_node):
		printerr("ERRO CRÍTICO: Tentativa de spawnar inimigo sem referência válida do jogador.")
		return

	var inimigo_escolhido = cenas_inimigos.pick_random()
	if not inimigo_escolhido: return
	
	var inimigo = inimigo_escolhido.instantiate()
	inimigo.connect("morreu", _on_inimigo_morreu)
	
	$YSortContainer.add_child(inimigo)
	
	var spawn_pos = Vector2()
	var borda = randi() % 4
	match borda:
		0: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), 50)
		1: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), tamanho_da_tela.y - 50)
		2: spawn_pos = Vector2(50, randf_range(50, tamanho_da_tela.y - 50))
		3: spawn_pos = Vector2(tamanho_da_tela.x - 50, randf_range(50, tamanho_da_tela.y - 50))
	inimigo.global_position = spawn_pos
	inimigo.jogador = jogador_node # Passa a referência

# --- FUNÇÃO EXCLUSIVA PARA O CHEFE ---
func spawnar_inimigo_para_chefe():
	if not is_instance_valid(jogador_node):
		printerr("ERRO CRÍTICO: Tentativa de spawnar inimigo PARA CHEFE sem referência válida do jogador.")
		return

	var inimigo_escolhido = cenas_inimigos.pick_random()
	if not inimigo_escolhido: return
	
	var inimigo = inimigo_escolhido.instantiate()
	inimigo.connect("morreu", _on_inimigo_morreu)
	
	$YSortContainer.add_child(inimigo)
	
	var spawn_pos = Vector2()
	var borda = randi() % 4
	match borda:
		0: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), 50)
		1: spawn_pos = Vector2(randf_range(50, tamanho_da_tela.x - 50), tamanho_da_tela.y - 50)
		2: spawn_pos = Vector2(50, randf_range(50, tamanho_da_tela.y - 50))
		3: spawn_pos = Vector2(tamanho_da_tela.x - 50, randf_range(50, tamanho_da_tela.y - 50))
	inimigo.global_position = spawn_pos
	inimigo.jogador = jogador_node
# --- FIM DA FUNÇÃO ---

#-----------------------------------------------------------------------------
# LÓGICA DO CHEFE
#-----------------------------------------------------------------------------

func iniciar_luta_chefe():
	print("--- O GUARDIÃO APARECEU! ---")
	luta_contra_chefe_ativa = true
	$EventoTimer.stop()
	
	if is_instance_valid(music_combate): music_combate.stop()
	if is_instance_valid(boss_music_player): boss_music_player.play()
	
	# Limpa inimigos normais ANTES de adicionar o chefe
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		if is_instance_valid(inimigo): # Segurança extra
			inimigo.queue_free()
		
	await get_tree().process_frame # Espera a limpeza
		
	var chefe = cena_chefe.instantiate()
	chefe.name = "Guardiao"
	chefe.position = tamanho_da_tela / 2
	chefe.jogador = jogador_node
	$YSortContainer.add_child(chefe)
	
	chefe.connect("morreu", _on_chefe_morreu)
	
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
		var hud_node = get_node_or_null("HUD") # Busca segura
		if is_instance_valid(hud_node) and hud_node.has_method("mostrar_notificacao"):
			hud_node.mostrar_notificacao("Baluarte da alma completo!")
		
#-----------------------------------------------------------------------------
# FUNÇÕES CONECTADAS A SINAIS (Callbacks)
#-----------------------------------------------------------------------------

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

#-----------------------------------------------------------------------------
# FUNÇÕES DE GAME OVER
#-----------------------------------------------------------------------------
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
			# --- CORREÇÃO AQUI: Usa 'in' em vez de 'has' ---
			if "vida_atual" in chefe and "vida_maxima" in chefe:
				# Evita divisão por zero se a vida máxima for zero (improvável, mas seguro)
				if chefe.vida_maxima > 0:
					var progresso_do_chefe = 1.0 - (float(chefe.vida_atual) / float(chefe.vida_maxima))
					progresso_percent = ((max_progresso - 1.0) + progresso_do_chefe) / max_progresso * 100.0
				else:
					progresso_percent = (max_progresso - 1.0) / max_progresso * 100.0 # Chefe derrotado
			# --- FIM DA CORREÇÃO ---
			else:
				print("AVISO: Nó Guardiao encontrado, mas sem variáveis vida_atual/vida_maxima.")
				progresso_percent = (max_progresso - 1.0) / max_progresso * 100.0
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
	var textura_inimigo = load("res://assets/gameover/boss1.png") # Verifique o caminho
	var citacao = '"Você parecia forte. Pena que sua alma agora é minha."'
	game_over_screen.setup_screen(progresso_percent, textura_inimigo, citacao)

func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().paused = false
	# Verifique se o caminho para o MainMenu está correto
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
