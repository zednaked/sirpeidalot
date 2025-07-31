extends AnimatedSprite2D




func _on_area_2d_body_entered(body: Node2D) -> void:
	Goblais.ouro += 1
	queue_free()
	pass # Replace with function body.
