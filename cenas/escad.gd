extends Sprite2D



func _physics_process(delta: float) -> void:
	var n_inimigos_vivos :int = 0
	
	for inimigo in $"../inimigos".get_children():
		if inimigo.is_dead: n_inimigos_vivos += 1
		
	
	if n_inimigos_vivos == $"../inimigos".get_child_count():
		Eventos.emit_signal("log", "Todos Inimigos foram mortos !")
		visible = true
	

func _ready() -> void:
	if get_parent().name != "town":
		visible = false
		
	randomize()
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	
	if get_parent().name == "town":
		var dadodesafios : int = 0
		dadodesafios = randi_range(0,9)
		if dadodesafios < 3 :
			$Desafios1.visible = true
		elif  dadodesafios < 6 :
			$Desafios2.visible = true
		elif  dadodesafios < 9 :
			$Desafios3.visible = true
	else:	
		#get_tree().change_scene_to_file("res://cenas/mapa6.tscn")	
		
		$Desafios1.visible = true

func _on_button_pressed() -> void:
	if get_parent().name == "town":
		get_tree().change_scene_to_file("res://cenas/mapa6_1.tscn")	
	else:
		get_tree().change_scene_to_file("res://cenas/mapa6.tscn")	
	pass # Replace with function body.


func _on_button_2_pressed() -> void:
	$Desafios1.visible = false
	
	pass # Replace with function body.
