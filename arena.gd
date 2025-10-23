# arena.gd
extends Node2D

@export var cenas_inimigos: Array[PackedScene]
@export var cena_fonte_vida: PackedScene
@export var cena_chefe: PackedScene
@export var game_over_screen_cena: PackedScene

# --- REFERÊNCIAS PARA OS PLAYERS DE MÚSICA ---
@onready var music_combate = $MusicCombate
@onready var boss_music_player = $BossMusicPlayer
# ----------------------------------------------

# --- Variáveis de Estado ---
var jogador_node = null
var luta_contra_chefe_ativa = false

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
	# Pega referências importantes no início do jogo
	jogador_node = $YSortContainer/Jogador
	tamanho_da_tela = get_viewport_rect().size
	jogador_node.hud = $HUD
	
	# Conecta os sinais entre os diferentes componentes do jogo
	jogador_node.saude_alterada.connect($HUD.atualizar_coracoes)
	$TelaMelhorias.melhoria_selecionada.connect(_on_melhoria_selecionada)
	jogador_node.morreu.connect(_on_jogador_morreu)
	
	# Manda o HUD se desenhar pela primeira vez
	$HUD.atualizar_coracoes(jogador_node.saude_atual, jogador_node.saude_maxima)
	
	# Inicia os timers do jogo
	$StartTimer.start()
	$EventoTimer.start()
	
	# --- LÓGICA DE MÚSICA ADICIONADA ---
	# Garante que a música de combate normal comece
	music_combate.play()
	# Garante que a música do chefe não esteja tocando
	boss_music_player.stop()
	# ---------------------------------

#-----------------------------------------------------------------------------
# LÓGICA DAS ONDAS E INIMIGOS
#-----------------------------------------------------------------------------

func iniciar_nova_onda():
	if is_instance_valid(jogador_node):
		jogador_node.baluarte_usado_na_onda = false
	
	onda_atual += 1
	
	if onda_atual == onda_do_chefe:
		iniciar_luta_chefe()
		return
		
	print("--- INICIANDO ONDA ", onda_atual, " ---")
	var quantidade_a_spawnar = base_inimigos_por_onda + (onda_atual * 2)
	inimigos_vivos = quantidade_a_spawnar
	
	for i in range(quantidade_a_spawnar):
		spawnar_inimigo()
		await get_tree().create_timer(0.3).timeout

func spawnar_inimigo():
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

#-----------------------------------------------------------------------------
# LÓGICA DO CHEFE (COM MUDANÇA DE MÚSICA)
#-----------------------------------------------------------------------------

func iniciar_luta_chefe():
	print("--- O GUARDIÃO APARECEU! ---")
	luta_contra_chefe_ativa = true
	$EventoTimer.stop()
	
	# --- TROCA A MÚSICA ---
	music_combate.stop()
	boss_music_player.play()
	# -----------------------
	
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		inimigo.queue_free()
		
	var chefe = cena_chefe.instantiate()
	chefe.name = "Guardiao"
	chefe.position = tamanho_da_tela / 2
	chefe.jogador = jogador_node
	$YSortContainer.add_child(chefe)
	
	chefe.connect("morreu", _on_chefe_morreu)
	
func verificar_sinergias(jogador):
	if jogador.tem_baluarte_da_alma:
		return

	var cartas_necessarias = ["vontade_de_ferro", "guardiao_caido", "foco_do_penitente"]
	var tem_todas = true
	
	for id_carta in cartas_necessarias:
		if not id_carta in jogador.cartas_coletadas:
			tem_todas = false
			break
	
	if tem_todas:
		print("SINERGIA ATIVADA: Baluarte da Alma!")
		jogador.tem_baluarte_da_alma = true
		$HUD.mostrar_notificacao("Baluarte da Alma Ativado!")

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
			$CardActivationTimer.start()

func _on_card_activation_timer_timeout():
	get_tree().paused = true
	$CartomanteSprite.show()
	$TelaMelhorias.preparar_e_mostrar()

func _on_chefe_morreu():
	print("VITÓRIA! O Guardião foi libertado.")
	
	# --- PARA A MÚSICA DO CHEFE ---
	boss_music_player.stop()
	# ----------------------------
	
	get_tree().paused = true

func _on_melhoria_selecionada(id_carta: String):
	$CartomanteSprite.hide()
	if not is_instance_valid(jogador_node): return
	
	if not id_carta in jogador_node.cartas_coletadas:
		jogador_node.cartas_coletadas.append(id_carta)

	match id_carta:
		"vontade_de_ferro":
			jogador_node.aumentar_vida_maxima(2)
		"guardiao_caido":
			jogador_node.tem_guardiao_caido = true
		"foco_do_penitente":
			jogador_node.ativar_foco_penitente()
		"coroa_do_martir":
			jogador_node.ativar_coroa_do_martir()
			
	verificar_sinergias(jogador_node)
	iniciar_nova_onda()

func _on_start_timer_timeout():
	iniciar_nova_onda()
	
func _on_evento_timer_timeout():
	if randf() < 0.3:
		var fonte = cena_fonte_vida.instantiate()
		fonte.global_position = Vector2(randf_range(50, tamanho_da_tela.x - 50), randf_range(50, tamanho_da_tela.y - 50))
		add_child(fonte)
		print("FONTE DE VIDA APARECEU!")

#-----------------------------------------------------------------------------
# FUNÇÕES DE GAME OVER (COM CONTROLE DE MÚSICA)
#-----------------------------------------------------------------------------

func _on_jogador_morreu():
	get_tree().call_deferred("set_pause", true)
	
	# --- PARA A MÚSICA QUE ESTIVER TOCANDO ---
	if luta_contra_chefe_ativa:
		boss_music_player.stop()
	else:
		music_combate.stop()
	# ----------------------------------------
	
	var progresso_percent = 0.0
	var max_progresso = float(onda_do_chefe)
	
	if luta_contra_chefe_ativa:
		var chefe = $YSortContainer.get_node_or_null("Guardiao")
		if is_instance_valid(chefe):
			var progresso_do_chefe = 1.0 - (chefe.vida_atual / float(chefe.vida_maxima))
			progresso_percent = ((max_progresso - 1.0) + progresso_do_chefe) / max_progresso * 100.0
	else:
		progresso_percent = (float(onda_atual) - 1.0) / max_progresso * 100.0
		
	var game_over_screen = game_over_screen_cena.instantiate()
	add_child(game_over_screen)
	
	game_over_screen.retry_pressed.connect(_on_retry_pressed)
	game_over_screen.quit_pressed.connect(_on_quit_pressed)
	
	# SUBSTITUA PELOS SEUS ASSETS REAIS
	var textura_inimigo = load("res://assets/gameover/boss1.png")
	var citacao = '"Você parecia forte. Pena que sua alma agora é minha."'
	game_over_screen.setup_screen(progresso_percent, textura_inimigo, citacao)

func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene() # Reinicia a cena, _ready() cuidará da música

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
