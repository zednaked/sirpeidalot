# esqueleto.gd
extends CharacterBody2D

# --- Signals ---
signal action_taken

# --- Constants ---
const TILE_SIZE = 16
const MOVE_SPEED = 15.0

# --- Attributes ---
@export var health: int = 50
@export var damage: int = 10

# --- References ---
@onready var animated_sprite: AnimatedSprite2D = $animacao
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var player_node: Node2D = null
var turn_manager = null

# --- State ---
var is_moving: bool = false
var is_dead: bool = false # Prevents a dying skeleton from acting
var target_position: Vector2

func _ready():
	player_node = get_tree().get_first_node_in_group("player")
	target_position = global_position
	add_to_group("enemies")

func _physics_process(delta):
	if is_moving:
		if global_position.distance_to(target_position) > 0.1:
			global_position = global_position.lerp(target_position, MOVE_SPEED * delta)
		else:
			global_position = target_position
			is_moving = false
			animated_sprite.play("idle")
			emit_signal("action_taken")

func take_turn():
	# A dead skeleton cannot take a turn.
	if is_dead:
		emit_signal("action_taken") # End turn immediately
		return

	print_debug("--- Skeleton's Turn (%s) ---" % self.name)
	if not is_instance_valid(player_node):
		print_debug("Skeleton: Player not found. Ending turn.")
		emit_signal("action_taken")
		return

	var player_pos = turn_manager.get_player_position()
	var my_pos = global_position
	
	var distance_to_player = my_pos.distance_to(player_pos)

	if distance_to_player < TILE_SIZE * 1.5:
		print_debug("Skeleton: Player is adjacent. Attacking!")
		_attack_player(player_pos - my_pos)
	else:
		print_debug("Skeleton: Player is far. Moving towards player.")
		_move_towards_player(player_pos)

# --- Combat Functions ---

func take_damage(amount: int):
	# Can't take damage if already dead.
	if is_dead:
		return

	health -= amount
	print_debug("Skeleton took %d damage, has %d health left." % [amount, health])
	
	if health <= 0:
		_die()

func _attack_player(direction: Vector2):
	_update_animation_direction(direction.normalized())
	
	var anim_name = "attack"

	if animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.sprite_frames.get_animation_loop(anim_name):
			print_debug("!!! AVISO: A animação 'attack' está configurada para LOOP.")
		
		animated_sprite.play(anim_name)
		# Deal damage to the player
		if player_node.has_method("take_damage"):
			player_node.take_damage(damage)
		await animated_sprite.animation_finished
	else:
		print_debug("ERROR: Animation '%s' not found!" % anim_name)
		await get_tree().create_timer(0.5).timeout

	animated_sprite.play("idle")
	emit_signal("action_taken")

func _die():
	is_dead = true
	# Disable collision so the player can walk over the dying body
	if is_instance_valid(collision_shape):
		collision_shape.disabled = true
	
	var anim_name = "death"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		print_debug("Skeleton is dying. Playing death animation.")
		animated_sprite.play(anim_name)
		await animated_sprite.animation_finished
	else:
		print_debug("ERROR: 'death' animation not found. Skeleton will disappear immediately.")
	
	queue_free()

# --- Movement Functions ---

func _move_towards_player(player_pos: Vector2):
	if not turn_manager:
		print_debug("Skeleton: TurnManager not defined. Ending turn.")
		emit_signal("action_taken")
		return

	var path = turn_manager.calculate_path(global_position, player_pos)
	
	if path.size() > 1:
		var next_step = path[1]
		var direction = (next_step - global_position).normalized()
		
		print_debug("Skeleton: Path found. Moving to: ", next_step)
		target_position = next_step
		is_moving = true
		_update_animation_direction(direction)
		animated_sprite.play("walk")
	else:
		print_debug("Skeleton: No path found. Ending turn.")
		emit_signal("action_taken")

func _update_animation_direction(direction: Vector2):
	if direction.x < -0.1:
		animated_sprite.flip_h = true
	elif direction.x > 0.1:
		animated_sprite.flip_h = false

func set_turn_manager(manager):
	turn_manager = manager
