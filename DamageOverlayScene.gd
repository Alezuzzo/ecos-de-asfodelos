# DamageOverlayScene.gd
extends CanvasLayer

@onready var vignette = $Vignette

func _ready():
	# Garante que começa invisível
	vignette.visible = false
	
	# MARRETA DE SEGURANÇA (Opcional, mas bom ter)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_damage_effect():
	# Garante visibilidade
	vignette.visible = true
	
	var material = vignette.material as ShaderMaterial
	if material:
		# Começa opaco
		material.set_shader_parameter("vignette_opacity", 1.0)
		
		# Anima até ficar transparente
		var tween = create_tween()
		tween.tween_method(
			func(valor): material.set_shader_parameter("vignette_opacity", valor),
			1.0, # Valor inicial
			0.0, # Valor final
			0.3  # Duração
		)
		# Esconde o retângulo no final
		tween.tween_callback(func(): vignette.visible = false)
