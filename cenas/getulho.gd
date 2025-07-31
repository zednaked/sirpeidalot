extends AnimatedSprite2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	$venda.visible = true
	pass # Replace with function body.


func _on_button_pressed() -> void:
	$venda.visible = false
	pass # Replace with function body.
