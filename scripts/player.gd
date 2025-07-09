# player.gd
extends CharacterBody2D

# --- Signals ---
signal action_taken

# --- Constants ---
const TILE_SIZE = 16
const MOVE_SPEED = 15.0

# --- References ---
@onready var animated_sprite: AnimatedSprite2D = $animacao
@onready var interaction_ray: RayCast2D = $InteractionRayCast

# --- State ---
var can_act: bool = false
var is_moving: bool = false
var target_position: Vector2

func _ready():
	target_position = global_position
	add_to_group("player")

func _unhandled_input(event):
	if not can_act or is_moving:
		return

	if event.is_action_pressed("ui_accept"):
		_pass_turn()
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction.length() > 0:
		_try_move_or_attack(direction)

func _physics_process(delta):
	if global_position.distance_to(target_position) > 0.1:
		global_position = global_position.lerp(target_position, MOVE_SPEED * delta)
	else:
		global_position = target_position
		if is_moving:
			is_moving = false
			animated_sprite.play("idle")
			emit_signal("action_taken")

func _pass_turn():
	print_debug("Player passes the turn.")
	emit_signal("action_taken")

func _try_move_or_attack(direction: Vector2):
	if is_moving: return

	_update_animation_direction(direction)
	interaction_ray.target_position = direction * TILE_SIZE
	interaction_ray.force_raycast_update()

	var consumed_turn = false

	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		
		if collider.is_in_group("enemies"):
			print("Player attacks ", collider.name)
			collider.queue_free()
			consumed_turn = true
		
		elif collider is TileMapLayer and collider.name == "portas":
			var collision_point = interaction_ray.get_collision_point()
			var map_coords = collider.local_to_map(collider.to_local(collision_point))
			# CORRECTED: TileMapLayer.set_cell does not take a 'layer' argument.
			collider.set_cell(map_coords, -1)
			consumed_turn = true
			
	else:
		target_position = global_position + direction * TILE_SIZE
		is_moving = true
		#animated_sprite.play("walk")
		return

	if consumed_turn:
		emit_signal("action_taken")

func _update_animation_direction(direction: Vector2):
	if direction.x < -0.1:
		animated_sprite.flip_h = true
	elif direction.x > 0.1:
		animated_sprite.flip_h = false

func set_can_act(value: bool):
	can_act = value
	if can_act:
		print_debug("Player can now act.")
	else:
		print_debug("Player input disabled.")
