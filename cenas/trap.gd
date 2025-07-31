extends Area2D
var cooldown = 0 







func _on_body_entered(body: Node2D) -> void:
	if !cooldown:
		for infeliz in  get_overlapping_bodies():
			if "take_damage" in infeliz:
				if await infeliz.take_damage(2):
					print ("creu")
				$animacao.play("trapchao")
				cooldown = 2	
	
