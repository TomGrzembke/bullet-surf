extends RigidBody2D

@export var jump_speed := 400  #pixels per second
@export var bullet_holder : Node

var is_jumping := false
var target_bullet: RigidBody2D
var jump_start_position: Vector2
var jump_duration: float
var jump_elapsed: float

func _ready():
	if !bullet_holder: return

	for bullet in bullet_holder.get_children():
		_connect_bullet_signals(bullet)

		bullet_holder.child_entering_tree.connect(_on_bullet_spawned)

func _connect_bullet_signals(bullet: Node):
	if bullet.has_signal("bullet_clicked"):
		bullet.bullet_clicked.connect(_on_bullet_clicked)

func _on_bullet_spawned(node: Node):
	_connect_bullet_signals(node)

func _on_bullet_clicked(bullet: RigidBody2D):
	if is_jumping:
		return  # Already jumping, ignore new clicks

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

		# Check if jump complete
		if progress >= 1.0:
			_on_jump_complete()

func _on_jump_complete():
	is_jumping = false
	target_bullet = null
	freeze = false
	linear_velocity = Vector2.ZERO
