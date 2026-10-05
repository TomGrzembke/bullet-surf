extends RigidBody2D

@export var jump_speed := 400  #pixels per second
@export var bullet_holder : Node

var is_jumping := false
var target_bullet: RigidBody2D
var jump_start_position: Vector2
var jump_duration: float
var jump_elapsed: float

func _ready():
	print("Player _ready() called")
	print("bullet_holder is: ", bullet_holder)

	if !bullet_holder:
		print("ERROR: bullet_holder not set!")
		# Try to find bullet holder automatically
		var root = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
		print("Root node: ", root.name)
		bullet_holder = root
		print("Auto-set bullet_holder to: ", bullet_holder.name)

	print("Player ready, connecting to bullets in: ", bullet_holder.name)
	print("Bullet holder children count: ", bullet_holder.get_child_count())

	for bullet in bullet_holder.get_children():
		print("Found child: ", bullet.name, " type: ", bullet.get_class())
		_connect_bullet_signals(bullet)

	bullet_holder.child_entered_tree.connect(_on_bullet_spawned)

func _connect_bullet_signals(bullet: Node):
	print("Checking bullet: ", bullet.name, " for signal")
	if bullet.has_signal("bullet_clicked"):
		print("Connecting to bullet: ", bullet.name)
		bullet.bullet_clicked.connect(_on_bullet_clicked)
	else:
		print("Bullet has no bullet_clicked signal: ", bullet.name)

func _on_bullet_spawned(node: Node):
	print("New bullet spawned: ", node.name)
	_connect_bullet_signals(node)

func _on_bullet_clicked(bullet: RigidBody2D):
	print("Player received bullet clicked signal from: ", bullet.name)
	if is_jumping:
		print("Already jumping, changing target to new bullet")
		# Start new jump from current position to new bullet
		jump_to_bullet(bullet)
	else:
		print("Starting jump to bullet")
		jump_to_bullet(bullet)

func jump_to_bullet(bullet: RigidBody2D):
	print("jump_to_bullet called")
	is_jumping = true
	target_bullet = bullet
	jump_start_position = global_position

	# Calculate distance and duration for constant speed
	var distance = global_position.distance_to(bullet.global_position)
	jump_duration = distance / jump_speed
	jump_elapsed = 0.0

	print("Distance: ", distance, " Duration: ", jump_duration)

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
	print("Jump complete")
	is_jumping = false
	target_bullet = null
	freeze = false
	linear_velocity = Vector2.ZERO
