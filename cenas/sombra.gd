extends ColorRect

func _process(_delta):
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 1) Obter posição do player no mundo
	var world_pos: Vector2 = player.global_position

	# 2) Converter para coordenada de tela em pixels
	#    usando get_viewport_transform() que incorpora o Camera2D :contentReference[oaicite:3]{index=3}
	var screen_pos: Vector2 = get_viewport_transform() * world_pos

	# 3) Pegar o tamanho real da viewport em pixels
	var vp_size: Vector2 = get_viewport().get_visible_rect().size  # w x h reais da tela :contentReference[oaicite:4]{index=4}

	# 4) Normalizar para 0..1 e passar ao shader
	var uv_pos: Vector2 = screen_pos / vp_size

	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("mask_position", uv_pos)  # método certo no Godot 4 :contentReference[oaicite:5]{index=5}
