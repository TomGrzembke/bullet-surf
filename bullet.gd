extends RigidBody2D

signal bullet_clicked(bullet: RigidBody2D)
signal bullet_spawn_request(position: Vector2, velocity: Vector2)

@export var bullet_velocity_max := 350
@export var bullet_velocity_min := 200

@export var click_radius := 50  # Radius for click detection
@export var wrap_buffer := 100  # Distance outside screen before wrapping (smaller = quicker wrap)

var bullet_velocity := 0
var click_area: Area2D
var is_hovered := false
var camera: Camera2D
var can_spawn_wrapped := true  # Only original bullets can spawn wrapped bullets
var has_spawned_wrapped := false  # Track if this bullet already spawned a wrapped one
var has_been_clicked := false  # Track if this bullet has been clicked

func _ready():
	bullet_velocity = randf_range(bullet_velocity_min, bullet_velocity_max)
	# Create Area2D for click detection
	click_area = Area2D.new()
	click_area.name = "ClickArea"
	add_child(click_area)

	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = click_radius
	click_area.add_child(collision)

	# Make the area detect mouse input
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)

	# Find the camera
	camera = get_viewport().get_camera_2d()

func _process(delta):
	linear_velocity.y = bullet_velocity
	_check_screen_wrap()

func _check_screen_wrap():
	if !camera: return

	var viewport_size = get_viewport_rect().size
	var screen_bottom = camera.global_position.y + viewport_size.y / 2
	var screen_top = camera.global_position.y - viewport_size.y / 2
	var screen_left = camera.global_position.x - viewport_size.x / 2
	var screen_right = camera.global_position.x + viewport_size.x / 2

	# Wrap vertically (bottom to top)
	#if global_position.y > screen_bottom + click_radius:
	#	global_position.y = screen_top - click_radius
	# Wrap vertically (top to bottom)
	#elif global_position.y < screen_top - click_radius:
	#	global_position.y = screen_bottom + click_radius

	# Wrap horizontally (right to left) - spawn new bullet on left
	if can_spawn_wrapped and !has_spawned_wrapped and global_position.x > screen_right + wrap_buffer:
		var spawn_pos = Vector2(screen_left - wrap_buffer, global_position.y)
		bullet_spawn_request.emit(spawn_pos, linear_velocity)
		has_spawned_wrapped = true
	# Wrap horizontally (left to right) - spawn new bullet on right
	elif can_spawn_wrapped and !has_spawned_wrapped and global_position.x < screen_left - wrap_buffer:
		var spawn_pos = Vector2(screen_right + wrap_buffer, global_position.y)
		bullet_spawn_request.emit(spawn_pos, linear_velocity)
		has_spawned_wrapped = true

func _input(event):
	# Only process input if mouse is over THIS bullet and hasn't been clicked yet
	if is_hovered and !has_been_clicked and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			has_been_clicked = true
			bullet_clicked.emit(self)

func _on_mouse_entered():
	is_hovered = true
	# Highlight when hovered
	modulate = Color(1.5, 1.5, 1.5, 1)

func _on_mouse_exited():
	is_hovered = false
	modulate = Color(1, 1, 1, 1)
