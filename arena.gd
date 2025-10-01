extends Node2D

@export var cenas_inimigos: Array[PackedScene]
@export var cena_fonte_vida: PackedScene

# Vamos guardar a referência do nó do jogador nesta variável
var jogador_node = null

# Variáveis para controlar as ondas
var onda_atual = 0
var inimigos_vivos = 0
var base_inimigos_por_onda = 3

var tamanho_tela

func _ready():
	# Primeiro, pegamos a referência do jogador.
	jogador_node = $Jogador
	
	# Depois, conectamos o sinal do jogador ao HUD.
	jogador_node.saude_alterada.connect($HUD.atualizar_coracoes)
	
	# --- A SOLUÇÃO ESTÁ AQUI ---
	# Agora que sabemos que a conexão está feita, nós manualmente
	# mandamos o HUD se atualizar com a vida inicial do jogador.
	$HUD.atualizar_coracoes(jogador_node.saude_atual, jogador_node.saude_maxima)
	# --- FIM DA SOLUÇÃO ---
	
	# O resto da função continua normalmente.
	tamanho_tela = get_viewport_rect().size
	$TelaMelhorias.melhoria_selecionada.connect(_on_melhoria_selecionada)
	$StartTimer.start()
	$EventoTimer.start()

func iniciar_nova_onda():
	onda_atual += 1
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
		0: spawn_pos = Vector2(randf_range(0, tamanho_tela.x), -50)
		1: spawn_pos = Vector2(randf_range(0, tamanho_tela.x), tamanho_tela.y + 50)
		2: spawn_pos = Vector2(-50, randf_range(0, tamanho_tela.y))
		3: spawn_pos = Vector2(tamanho_tela.x + 50, randf_range(0, tamanho_tela.y))
			
	inimigo.global_position = spawn_pos
	
	# Usamos a nossa variável em vez de procurar o nó de novo
	inimigo.jogador = jogador_node
	
	add_child(inimigo)

func _on_evento_timer_timeout():
	if randf() < 0.3:
		var fonte = cena_fonte_vida.instantiate()
		fonte.global_position = Vector2(
			randf_range(50, tamanho_tela.x - 50),
			randf_range(50, tamanho_tela.y - 50)
		)
		add_child(fonte)
		print("FONTE DE VIDA APARECEU!")

func _on_inimigo_morreu():
	inimigos_vivos -= 1
	if inimigos_vivos <= 0:
		get_tree().paused = true
		$TelaMelhorias.show()

func _on_start_timer_timeout():
	iniciar_nova_onda()
	
func _on_melhoria_selecionada(tipo_melhoria: String):
	print("Melhoria selecionada: ", tipo_melhoria)
	
	# Usamos a nossa variável em vez de procurar o nó de novo
	if not jogador_node: return # Segurança extra

	match tipo_melhoria:
		"velocidade_tiro":
			jogador_node.cadencia_tiro = max(0.1, jogador_node.cadencia_tiro * 0.85)
		"velocidade_movimento":
			jogador_node.velocidade *= 1.15
		"dano_projetil":
			jogador_node.dano_projetil += 1
			
	iniciar_nova_onda()
