# Spawns bullets at regular intervals from a spawn point
# Handles bullet wrapping requests from existing bullets
# Spawn interval and bullet velocity are controlled by difficulty manager

extends Node2D

@export var bullet_holder : Node
@export var bullet_spawn_point : Node
@export var player_path: NodePath = NodePath("../Player")

@export var bullet_scene : PackedScene
@export var bullet_spawn_interval_base: float = 0.55
@export var pool_distance_ratio: float = 2.0 / 3.0

@export var predetermined_patterns: Array[BulletPattern] = []
@export var random_pattern_pool: Array[BulletPattern] = []
@export var use_patterns: bool = true

@onready var bullet_pool: Node = $BulletPool

var current_spawntime: float = 0.0
var current_bullet_velocity: float = 200.0
var player: Node2D
var player_start_position: Vector2
var pattern_index: int = 0

func _ready():
	bullet_holder.child_entered_tree.connect(_on_bullet_added)
	for bullet in bullet_holder.get_children():
		_on_bullet_added(bullet)
	player = get_node(player_path)
	player_start_position = player.global_position

func _on_bullet_added(node: Node):
	if !node.has_signal("bullet_spawn_request"): return
	if !node.bullet_spawn_request.is_connected(_spawn_wrapped_bullet):
		node.bullet_spawn_request.connect(_spawn_wrapped_bullet)
	if !node.has_signal("bullet_despawn_request"): return
	if !node.bullet_despawn_request.is_connected(_return_bullet_to_pool):
		node.bullet_despawn_request.connect(_return_bullet_to_pool)

func _spawn_wrapped_bullet(spawn_position: Vector2, velocity: Vector2):
	var bullet = _acquire_bullet()
	bullet.activate(spawn_position, velocity, false)

func _process(delta):
	current_spawntime += delta
	if current_spawntime >= bullet_spawn_interval_base:
		current_spawntime = 0
		_spawn_new_bullet()

	_return_distant_bullets_to_pool()

func _spawn_new_bullet():
	if !is_instance_valid(bullet_spawn_point): return

	if use_patterns:
		_spawn_pattern()
	else:
		_spawn_single_bullet()

func _spawn_single_bullet():
	var bullet = _acquire_bullet()
	var spawn_position = bullet_spawn_point.global_position
	spawn_position.x += _get_random_x_offset()
	bullet.activate(spawn_position, Vector2(0, current_bullet_velocity))

func _spawn_pattern():
	var pattern = _get_next_pattern()
	if !pattern: return

	var spawn_base = bullet_spawn_point.global_position

	for offset in pattern.bullet_offsets:
		var bullet = _acquire_bullet()
		var spawn_position = spawn_base + offset
		bullet.activate(spawn_position, Vector2(0, current_bullet_velocity))

func _get_next_pattern() -> BulletPattern:
	if predetermined_patterns.is_empty() && random_pattern_pool.is_empty(): return null

	if pattern_index < predetermined_patterns.size():
		var pattern = predetermined_patterns[pattern_index]
		pattern_index += 1
		return pattern

	if random_pattern_pool.is_empty(): return null

	return random_pattern_pool.pick_random()

func _get_random_x_offset() -> float:
	var collision_shape = $CollisionShape2D
	if !is_instance_valid(collision_shape): return 0.0
	var shape = collision_shape.shape
	if !shape: return 0.0
	var extents_x = shape.size.x / 2.0
	return randf_range(-extents_x, extents_x)

func _acquire_bullet() -> RigidBody2D:
	if bullet_pool.get_child_count() > 0:
		var bullet = bullet_pool.get_child(0) as RigidBody2D
		bullet.reparent(bullet_holder)
		return bullet

	var new_bullet = bullet_scene.instantiate() as RigidBody2D
	bullet_holder.add_child(new_bullet)
	_on_bullet_added(new_bullet)
	return new_bullet

func _return_bullet_to_pool(bullet: RigidBody2D):
	if !is_instance_valid(bullet): return
	if bullet.has_method("can_be_pooled"):
		if !bullet.can_be_pooled():
			bullet.queue_free()
			return

	bullet.deactivate.call_deferred()
	bullet.reparent.call_deferred(bullet_pool)

func _return_distant_bullets_to_pool():
	if !player: return

	var player_height = max(player_start_position.y - player.global_position.y, 0.0)
	var pool_distance = player_height * pool_distance_ratio
	if pool_distance <= 0: return

	for node in bullet_holder.get_children():
		var bullet = node as RigidBody2D
		if !bullet: continue
		if !bullet.has_method("request_despawn"): continue
		var distance_under_player = bullet.global_position.y - player.global_position.y
		if distance_under_player < pool_distance: continue
		bullet.request_despawn()

func set_spawn_interval(value: float):
	bullet_spawn_interval_base = value

func set_current_bullet_velocity(value: float):
	current_bullet_velocity = value
