# tela_melhorias.gd
extends CanvasLayer

# Sinal para avisar a Arena qual melhoria foi escolhida
signal melhoria_selecionada(tipo_melhoria: String)

func _on_botao_velocidade_tiro_pressed():
	emit_signal("melhoria_selecionada", "velocidade_tiro")
	finalizar_escolha()

func _on_botao_velocidade_movimento_pressed():
	emit_signal("melhoria_selecionada", "velocidade_movimento")
	finalizar_escolha()

func _on_botao_dano_projetil_pressed():
	emit_signal("melhoria_selecionada", "dano_projetil")
	finalizar_escolha()

# Função para esconder a tela, despausar o jogo e avisar a Arena
func finalizar_escolha():
	hide()
	get_tree().paused = false


func _on_button_pressed() -> void:
	pass # Replace with function body.
