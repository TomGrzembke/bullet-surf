extends Node2D


@export var bullet_scene : PackedScene
@export var bullet_spawn_intervall := 2.
@export var bullet_holder : Node
@export var bullet_spawn_point : Node



var current_spawntime := 0.

func _ready():
	# Listen for wrap spawn requests from bullets
	bullet_holder.child_entered_tree.connect(_on_bullet_added)

	# Connect to existing bullets
	for bullet in bullet_holder.get_children():
		_on_bullet_added(bullet)

func _on_bullet_added(node: Node):
	if node.has_signal("bullet_spawn_request"):
		node.bullet_spawn_request.connect(_spawn_wrapped_bullet)

func _spawn_wrapped_bullet(position: Vector2, velocity: Vector2):
	var new_bullet = bullet_scene.instantiate()
	new_bullet.global_position = position
	new_bullet.linear_velocity = velocity
	new_bullet.can_spawn_wrapped = false  # Wrapped bullets cannot spawn more
	bullet_holder.add_child(new_bullet)

func _process(delta):
	current_spawntime += delta

	if current_spawntime >= bullet_spawn_intervall:
		current_spawntime = 0
		var new_bullet = bullet_scene.instantiate()
		new_bullet.global_position = bullet_spawn_point.global_position

		var shape = $CollisionShape2D.shape
		var extents_x = shape.size.x / 2.0
		var random_x_offset = randf_range(-extents_x, extents_x)
		new_bullet.global_position.x += random_x_offset

		bullet_holder.add_child(new_bullet)
