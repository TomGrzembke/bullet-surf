extends RigidBody2D

@export var jump_speed := 400  #pixels per second
@export var bullet_holder : Node
@export var attach_distance := 50  # Distance at which to attach to bullet

var is_jumping := false
var is_attached := false
var target_bullet: RigidBody2D
var attached_bullet: RigidBody2D
var jump_start_position: Vector2
var jump_duration: float
var jump_elapsed: float
var original_parent: Node
var attach_offset: Vector2

func _ready():
	if !bullet_holder:
		#print("ERROR: bullet_holder not set!")
		# Try to find bullet holder automatically
		var root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
		bullet_holder = root

	for bullet in bullet_holder.get_children():
		_connect_bullet_signals(bullet)

	bullet_holder.child_entered_tree.connect(_on_bullet_spawned)

func _connect_bullet_signals(bullet: Node):
	if bullet.has_signal("bullet_clicked"):
		bullet.bullet_clicked.connect(_on_bullet_clicked)

func _on_bullet_spawned(node: Node):
	_connect_bullet_signals(node)

func _on_bullet_clicked(bullet: RigidBody2D):
	# If attached, detach first
	if is_attached:
		_detach_from_bullet()

	if is_jumping:
		# Start new jump from current position to new bullet
		jump_to_bullet(bullet)
	else:
		jump_to_bullet(bullet)

func jump_to_bullet(bullet: RigidBody2D):
	is_jumping = true
	target_bullet = bullet
	jump_start_position = global_position

	# Calculate distance and duration for constant speed
	var distance = global_position.distance_to(bullet.global_position)
	jump_duration = distance / jump_speed
	jump_elapsed = 0.0

	# Disable physics during jump
	freeze = true

func _process(delta):
	if is_jumping and target_bullet:
		jump_elapsed += delta

		# Calculate progress (0.0 to 1.0)
		var progress = min(jump_elapsed / jump_duration, 1.0)

		# Interpolate position
		var target_pos = target_bullet.global_position
		global_position = jump_start_position.lerp(target_pos, progress)

		# Check if close enough to attach
		var distance = global_position.distance_to(target_bullet.global_position)
		if distance <= attach_distance:
			_attach_to_bullet(target_bullet)
			is_jumping = false
			target_bullet = null
			return

		# Check if jump complete
		if progress >= 1.0:
			_on_jump_complete()

func _on_jump_complete():
	is_jumping = false
	target_bullet = null
	freeze = false
	linear_velocity = Vector2.ZERO

func _attach_to_bullet(bullet: RigidBody2D):
	is_attached = true
	attached_bullet = bullet
	original_parent = get_parent()

	# Store the global position before reparenting
	var current_global_pos = global_position

	# Reparent player to bullet
	reparent(bullet)

	# Restore the global position after reparenting
	global_position = current_global_pos

	# Calculate offset for detachment later
	attach_offset = global_position - bullet.global_position

	freeze = true  # Disable physics while attached

func _detach_from_bullet():
	if !is_attached or !attached_bullet:
		return

	# Reparent back to original parent
	reparent(original_parent)
	global_position = attached_bullet.global_position + attach_offset

	is_attached = false
	attached_bullet = null
	original_parent = null
	freeze = false  # Re-enable physics
	linear_velocity = Vector2.ZERO
