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
var is_dead: bool = false
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
	# A dead skeleton's turn is to do nothing and end immediately.
	if is_dead:
		emit_signal("action_taken")
		return

	var player_pos = turn_manager.get_player_position()
	var my_pos = global_position
	if my_pos.distance_to(player_pos) < TILE_SIZE * 1.5:
		_attack_player(player_pos - my_pos)
	else:
		_move_towards_player(player_pos)

# --- Combat Functions ---

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	print_debug("%s took %d damage, has %d health left." % [self.name, amount, health])
	if health <= 0:
		_die()

func _attack_player(direction: Vector2):
	_update_animation_direction(direction.normalized())
	var anim_name = "attack"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		if player_node.has_method("take_damage"):
			player_node.take_damage(damage)
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout
	animated_sprite.play("idle")
	emit_signal("action_taken")

# This function now only sets the state and starts the animation.
# It does NOT handle queue_free().
func _die():
	if is_dead: return
	is_dead = true
	print_debug("%s is dying." % self.name)
	if is_instance_valid(collision_shape):
		collision_shape.disabled = true
	
	animated_sprite.play("death")

# --- Movement and Helper Functions ---

func _move_towards_player(player_pos: Vector2):
	if not turn_manager:
		emit_signal("action_taken")
		return
	var path = turn_manager.calculate_path(global_position, player_pos)
	if path.size() > 1:
		target_position = path[1]
		is_moving = true
		_update_animation_direction((target_position - global_position).normalized())
		animated_sprite.play("walk")
	else:
		emit_signal("action_taken")

func _update_animation_direction(direction: Vector2):
	if direction.x < -0.1:
		animated_sprite.flip_h = true
	elif direction.x > 0.1:
		animated_sprite.flip_h = false

func set_turn_manager(manager):
	turn_manager = manager
