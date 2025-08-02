extends Node2D
var numero_jogadores = 1


func _on_conectar_pressed() -> void:
	$Panel2.hide()
	$Panel.show()


func _on_timer_timeout() -> void:
	pass


func _on_voltar_pressed() -> void:
	$Panel2.show()
	$Panel.hide()


func _on_salas_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	
	pass # Replace with function body.


func _on_salas_item_activated(index: int) -> void:
	Goblais.nome =$Panel/salas.get_item_text(index)
	
	#tem que mudar de cena para _main.tscn
		
	$Panel.visible = false
	
	get_tree().change_scene_to_file("res://cenas/_main.tscn")

#func _on_criar_pressed() -> void:
#	iscriador = true	
#	start_game()
#	$propagador.send_scene_state()
#	$UI/Panel.visible = false

#func _on_conectar_pressed() -> void:
		
#	var event = {
#		"type": "join",
#		"source": Goblais.nome
#	}
#	$propagador.send_event(event)
#	$UI/Panel.visible = false


func _on_entrar_pressed() -> void:
	# carregar a cena e fazer o fetch
	# o correto era fazer um handshake para ver se da para entrar e depoius carregar
	Goblais.nome = $Panel/nome.text
	Goblais.modo = "join"
	#tem que mudar de cena para _main.tscn
		
	$Panel.visible = false
	
	get_tree().change_scene_to_file("res://cenas/_main.tscn")	


func _on_criar_pressed() -> void:
	
	Goblais.modo = "criar"
	$Panel.visible = false
	get_tree().change_scene_to_file("res://cenas/_main.tscn")
	


func _on_nome_text_changed(new_text: String) -> void:
	Goblais.nome = $Panel/nome.text
	pass # Replace with function body.


func _on_conectar_2_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/town.tscn")	
	pass # Replace with function body.


func _on_conectar_2_focus_entered() -> void:
	$bleep.play()
	pass # Replace with function body.


func _on_conectar_2_toggled(toggled_on: bool) -> void:
	$bleep.play()
	pass # Replace with function body.


func _on_conectar_2_mouse_entered() -> void:
	$bleep.play()
	pass # Replace with function body.


func _on_conectar_mouse_entered() -> void:
	$bleep.play()
	pass # Replace with function body.


func _on_setup_mouse_entered() -> void:
	$bleep.play()
	pass # Replace with function body.
