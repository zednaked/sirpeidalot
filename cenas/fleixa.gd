extends Sprite2D

@export var speed := 200.0

var disparado := false
var target_position := Vector2.ZERO
var direcao := Vector2.ZERO

func shoot(target_pos: Vector2) -> void:
	visible = true
	disparado = true
	target_position = target_pos
	direcao = (target_position - global_position).normalized()
	# converte o ângulo do vetor (em rad) pra graus e ajusta -90°
	rotation_degrees = rad_to_deg(direcao.angle() - PI/2)

func _physics_process(delta: float) -> void:
	if disparado:
		global_position = global_position.move_toward(target_position, speed * delta)
		if global_position.distance_to(target_position) < 4.0 or $RayCast2D.is_colliding():
			if $RayCast2D.is_colliding() :
				queue_free()
				return
					
			#todo toma dano
			get_tree().get_first_node_in_group("player").take_damage(20)
			disparado = false
			queue_free()
