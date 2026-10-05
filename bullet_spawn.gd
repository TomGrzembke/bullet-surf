extends Node2D


@export var bullet_scene : PackedScene
@export var bullet_spawn_intervall_base := 0.55  # Base spawn interval
@export var bullet_holder : Node
@export var bullet_spawn_point : Node
@export var player_path: NodePath = NodePath("../Player")

var current_spawntime := 0.
var player: Node2D
var current_bullet_velocity := 200  # Default, will be updated by difficulty manager

func set_spawn_interval(value: float):
	bullet_spawn_intervall_base = value

func set_current_bullet_velocity(value: float):
	current_bullet_velocity = value

func _ready():
	# Listen for wrap spawn requests from bullets
	bullet_holder.child_entered_tree.connect(_on_bullet_added)

	# Connect to existing bullets
	for bullet in bullet_holder.get_children():
		_on_bullet_added(bullet)

	# Get player reference
	player = get_node(player_path)

func _on_bullet_added(node: Node):
	if node.has_signal("bullet_spawn_request"):
		node.bullet_spawn_request.connect(_spawn_wrapped_bullet)

func _spawn_wrapped_bullet(position: Vector2, velocity: Vector2):
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = position
	new_bullet.linear_velocity = velocity
	new_bullet.can_spawn_wrapped = false  # Wrapped bullets cannot spawn more

	# Set bullet velocity from current difficulty
	if new_bullet.has_method("set_bullet_velocity"):
		new_bullet.set_bullet_velocity(current_bullet_velocity)

	bullet_holder.add_child(new_bullet)

func _process(delta):
	current_spawntime += delta

	if current_spawntime >= bullet_spawn_intervall_base:
		current_spawntime = 0
		var new_bullet = bullet_scene.instantiate()
		new_bullet.global_position = bullet_spawn_point.global_position

		var shape = $CollisionShape2D.shape
		var extents_x = shape.size.x / 2.0
		var random_x_offset = randf_range(-extents_x, extents_x)
		new_bullet.global_position.x += random_x_offset

		# Set bullet velocity from current difficulty
		if new_bullet.has_method("set_bullet_velocity"):
			new_bullet.set_bullet_velocity(current_bullet_velocity)

		bullet_holder.add_child(new_bullet)
