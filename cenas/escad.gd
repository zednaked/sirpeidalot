extends Sprite2D

func _ready() -> void:
	randomize()
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	var dadodesafios : int = 0
	dadodesafios = randi_range(0,9)
	if dadodesafios < 3 :
		$Desafios1.visible = true
	elif  dadodesafios < 6 :
		$Desafios2.visible = true
	elif  dadodesafios < 9 :
		$Desafios3.visible = true
	
	#get_tree().change_scene_to_file("res://cenas/mapa6.tscn")	
	pass # Replace with function body.


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/mapa6.tscn")	
	pass # Replace with function body.


func _on_button_2_pressed() -> void:
	$Desafios1.visible = false
	$Desafios2.visible = false
	$Desafios3.visible = false
	
	pass # Replace with function body.
