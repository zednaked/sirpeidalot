extends AnimatedSprite2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	play("chestgrandeabrindo")
	get_parent().get_node("Camera2D").shake(0.1, 5)
