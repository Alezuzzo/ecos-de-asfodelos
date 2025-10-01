# arena.gd
extends Node2D

@export var inimigo_cena: PackedScene

var tamanho_tela

func _ready():
	# Pega o tamanho da tela para saber onde spawnar os inimigos
	tamanho_tela = get_viewport_rect().size
	# Inicia o timer para spawnar o primeiro inimigo
	$SpawnTimer.start()

func _on_spawn_timer_timeout():
	# Cria uma instância do inimigo
	var inimigo = inimigo_cena.instantiate()
	
	# Define uma posição aleatória nas bordas da tela
	var spawn_pos = Vector2()
	var borda = randi() % 4 # 0=cima, 1=baixo, 2=esquerda, 3=direita
	match borda:
		0: # Cima
			spawn_pos = Vector2(randf_range(0, tamanho_tela.x), -50)
		1: # Baixo
			spawn_pos = Vector2(randf_range(0, tamanho_tela.x), tamanho_tela.y + 50)
		2: # Esquerda
			spawn_pos = Vector2(-50, randf_range(0, tamanho_tela.y))
		3: # Direita
			spawn_pos = Vector2(tamanho_tela.x + 50, randf_range(0, tamanho_tela.y))
			
	inimigo.global_position = spawn_pos
	
	# Passa a referência do jogador para o inimigo saber quem perseguir
	inimigo.jogador = $Jogador
	
	add_child(inimigo)
