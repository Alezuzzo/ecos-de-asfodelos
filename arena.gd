# arena.gd
extends Node2D

@export var cenas_inimigos: Array[PackedScene]
@export var cena_fonte_vida: PackedScene
@export var cena_chefe: PackedScene

# --- Variáveis de Estado ---
var jogador_node = null
var luta_contra_chefe_ativa = false

# --- Variáveis das Ondas ---
var onda_atual = 0
var inimigos_vivos = 0
var base_inimigos_por_onda = 3
var onda_do_chefe = 5

# --- NOME DA VARIÁVEL CORRIGIDO AQUI ---
var tamanho_da_tela: Vector2

#-----------------------------------------------------------------------------
# FUNÇÕES PRINCIPAIS DO GODOT
#-----------------------------------------------------------------------------

func _ready():
	# Pega referências importantes no início
	jogador_node = $Jogador
	
	# --- NOME DA VARIÁVEL CORRIGIDO AQUI ---
	tamanho_da_tela = get_viewport_rect().size
	
	# Conecta os sinais
	jogador_node.saude_alterada.connect($HUD.atualizar_coracoes)
	$TelaMelhorias.melhoria_selecionada.connect(_on_melhoria_selecionada)
	
	# Manda o HUD se desenhar pela primeira vez
	$HUD.atualizar_coracoes(jogador_node.saude_atual, jogador_node.saude_maxima)
	
	# Inicia os timers do jogo
	$StartTimer.start()
	$EventoTimer.start()

#-----------------------------------------------------------------------------
# LÓGICA DAS ONDAS E INIMIGOS
#-----------------------------------------------------------------------------

func iniciar_nova_onda():
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
	
	var spawn_pos = Vector2()
	var borda = randi() % 4
	match borda:
		# --- NOME DA VARIÁVEL CORRIGIDO AQUI ---
		0: spawn_pos = Vector2(randf_range(0, tamanho_da_tela.x), -50)
		1: spawn_pos = Vector2(randf_range(0, tamanho_da_tela.x), tamanho_da_tela.y + 50)
		2: spawn_pos = Vector2(-50, randf_range(0, tamanho_da_tela.y))
		3: spawn_pos = Vector2(tamanho_da_tela.x + 50, randf_range(0, tamanho_da_tela.y))
			
	inimigo.global_position = spawn_pos
	inimigo.jogador = jogador_node
	add_child(inimigo)

#-----------------------------------------------------------------------------
# LÓGICA DO CHEFE
#-----------------------------------------------------------------------------

func iniciar_luta_chefe():
	print("--- O GUARDIÃO APARECEU! ---")
	luta_contra_chefe_ativa = true
	$EventoTimer.stop()
	
	for inimigo in get_tree().get_nodes_in_group("inimigos"):
		inimigo.queue_free()
		
	var chefe = cena_chefe.instantiate()
	# --- NOME DA VARIÁVEL CORRIGIDO AQUI ---
	chefe.position = tamanho_da_tela / 2
	chefe.jogador = jogador_node
	add_child(chefe)
	
	chefe.connect("morreu", _on_chefe_morreu)

#-----------------------------------------------------------------------------
# FUNÇÕES CONECTADAS A SINAIS (Callbacks)
#-----------------------------------------------------------------------------

func _on_inimigo_morreu():
	if luta_contra_chefe_ativa: return
	
	inimigos_vivos -= 1
	print("Inimigo derrotado! Restam: ", inimigos_vivos)
	
	if inimigos_vivos <= 0:
		if onda_atual + 1 == onda_do_chefe:
			print("--- ONDA ", onda_atual, " COMPLETA! O CHEFE SE APROXIMA... ---")
			iniciar_nova_onda()
		else:
			print("--- ONDA ", onda_atual, " COMPLETA! ---")
			get_tree().paused = true
			$TelaMelhorias.show()

func _on_chefe_morreu():
	print("VITÓRIA! O Guardião foi libertado.")
	get_tree().paused = true

func _on_melhoria_selecionada(tipo_melhoria: String):
	if not jogador_node: return

	match tipo_melhoria:
		"velocidade_tiro":
			jogador_node.cadencia_tiro = max(0.1, jogador_node.cadencia_tiro * 0.85)
		"velocidade_movimento":
			jogador_node.velocidade *= 1.15
		"dano_projetil":
			jogador_node.dano_projetil += 1
			
	iniciar_nova_onda()

func _on_start_timer_timeout():
	iniciar_nova_onda()
	
func _on_evento_timer_timeout():
	if randf() < 0.3:
		var fonte = cena_fonte_vida.instantiate()
		# --- NOME DA VARIÁVEL CORRIGIDO AQUI ---
		fonte.global_position = Vector2(
			randf_range(50, tamanho_da_tela.x - 50),
			randf_range(50, tamanho_da_tela.y - 50)
		)
		add_child(fonte)
		print("FONTE DE VIDA APARECEU!")
