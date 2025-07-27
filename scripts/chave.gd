extends StaticBody2D

# Esta função é chamada pelo jogador.
func collect():
	# Se este objeto for uma porta, atualiza a grade de navegação antes de desaparecer.
	if is_in_group("portas"):
		var turn_manager = get_tree().get_first_node_in_group("turn_manager")
		if turn_manager and turn_manager.has_method("update_walkable_area"):
			turn_manager.update_walkable_area(global_position)
			Eventos.emit_signal("log", "você abre a porta para mais coisas sombrias !")
	# O objeto (chave ou porta) se remove da cena.
	queue_free()
