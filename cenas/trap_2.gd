extends Area2D
var cooldown = 0
#ficar um turno em cooldown

func _on_body_entered(body: Node2D) -> void:
	if !cooldown:
		for infeliz in get_overlapping_bodies():
			if "take_damage" in infeliz:
				if  infeliz.take_damage(50):
					print ("toasty")
				
			$animacao.play("lancachamasv")
			cooldown = 2
