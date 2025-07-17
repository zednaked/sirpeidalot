# player.gd
extends CharacterBody2D

# --- Signals ---
signal action_taken

# --- Constants ---
const TILE_SIZE = 16
const MOVE_SPEED = 25.0

# --- Attributes ---
@export var debuff: PackedScene
@export var health: int = 100
@export var damage: int = 25
var has_key: bool = true

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

	for debuf in $debuffs.get_children():
		debuf.diminuitempo()
	for buf in $buffs.get_children():
		buf.diminuitempo()			
		
	if event.is_action_pressed("ui_accept"):
		_pass_turn()
		return

	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction.length() > 0:
		_try_move_or_attack(direction)

func _physics_process(delta):
	if is_moving:
		if global_position.distance_to(target_position) > 0.1:
			global_position = global_position.lerp(target_position, MOVE_SPEED * delta)
		else:
			global_position = target_position
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
		
		# --- ATTACK LOGIC ---
		if collider.is_in_group("enemies") and collider.has_method("take_damage"):
			print("Player attacks ", collider.name)
			
			$efeitos.play("attack")
			collider.take_damage(damage)
			#var filhodaputa = debuff.instantiate()
			
			#collider.get_node("efeitos").add_child(filhodaputa)
			#filhodaputa.position.x = 0
			#filhodaputa.position.y = 0
			consumed_turn = true
		
		# --- KEY PICKUP LOGIC ---
		elif collider.is_in_group("key"):
			_pickup_key(collider)
			consumed_turn = true
			
		# --- STAIRS INTERACTION LOGIC ---
		elif collider.is_in_group("stairs"):
			if has_key:
				if collider.has_method("interact"):
					collider.interact()
			else:
				print("The stairs are locked. You need a key.")
			consumed_turn = true # Interacting with stairs takes a turn
	
		elif collider.is_in_group ("drop"):
			target_position = global_position + direction * TILE_SIZE
			is_moving = true
			#sollider.get_parent()
			collider.get_parent().reparent(get_parent().get_node("UI/inventario/mochila"))
			consumed_turn = true
			
		elif collider is StaticBody2D and collider.is_in_group ("portas"):
			print_debug ("porta")
			#var collision_point = interaction_ray.get_collision_point()
			#var map_coords = collider.local_to_map(collider.to_local(collision_point))
			#collider.set_cell(map_coords, -1)
			collider.collect()
			consumed_turn = true
		elif collider is StaticBody2D and collider.is_in_group ("traps"):
			collider.collect()
			target_position = global_position + direction * TILE_SIZE
			is_moving = true
			animated_sprite.play("idle")			
			consumed_turn = true
			
	else:
		# --- MOVEMENT LOGIC ---
		target_position = global_position + direction * TILE_SIZE
		is_moving = true
		animated_sprite.play("idle")
		return

	if consumed_turn:
		emit_signal("action_taken")

func _pickup_key(key_node):
	if key_node.has_method("collect"):
		key_node.collect()
		has_key = true
		print("Player picked up the key!")

# --- Combat Functions ---

func take_damage(amount: int):
	health -= amount
	print_debug("Player took %d damage, has %d health left." % [amount, health])
	

# --- Helper Functions ---

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


func _on_efeitos_animation_finished() -> void:
	
	pass # Replace with function body.
