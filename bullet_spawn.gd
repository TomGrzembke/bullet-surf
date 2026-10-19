extends Node2D

# Spawns bullets at regular intervals from a spawn point
# Handles bullet wrapping requests from existing bullets
# Spawn interval and bullet velocity are controlled by difficulty manager

@export var bullet_holder : Node
@export var bullet_spawn_point : Node
@export var player_path: NodePath = NodePath("../Player")

@export var bullet_scene : PackedScene
@export var bullet_spawn_intervall_base := 0.55

var current_spawntime := 0.
var player: Node2D
var current_bullet_velocity := 200

func _ready():
	bullet_holder.child_entered_tree.connect(_on_bullet_added)
	for bullet in bullet_holder.get_children():
		_on_bullet_added(bullet)
	player = get_node(player_path)

func _on_bullet_added(node: Node):
	if node.has_signal("bullet_spawn_request"):
		node.bullet_spawn_request.connect(_spawn_wrapped_bullet)

func _spawn_wrapped_bullet(position: Vector2, velocity: Vector2):
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = position
	new_bullet.linear_velocity = velocity
	new_bullet.can_spawn_wrapped = false
	_set_bullet_velocity(new_bullet)
	bullet_holder.add_child(new_bullet)

func _process(delta):
	current_spawntime += delta
	if current_spawntime >= bullet_spawn_intervall_base:
		current_spawntime = 0
		_spawn_new_bullet()

func _spawn_new_bullet():
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = bullet_spawn_point.global_position
	_add_random_x_offset(new_bullet)
	_set_bullet_velocity(new_bullet)
	bullet_holder.add_child(new_bullet)

func _add_random_x_offset(bullet: RigidBody2D):
	var shape = $CollisionShape2D.shape
	var extents_x = shape.size.x / 2.0
	var random_x_offset = randf_range(-extents_x, extents_x)
	bullet.global_position.x += random_x_offset

func _set_bullet_velocity(bullet: RigidBody2D):
	if bullet.has_method("set_bullet_velocity"):
		bullet.set_bullet_velocity(current_bullet_velocity)

func set_spawn_interval(value: float):
	bullet_spawn_intervall_base = value

func set_current_bullet_velocity(value: float):
	current_bullet_velocity = value
