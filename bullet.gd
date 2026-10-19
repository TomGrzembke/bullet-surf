# Handles bullet movement, click detection, and screen wrapping
# Bullets move vertically, can be clicked by player to jump to them,
# and wrap horizontally to spawn new bullets

extends RigidBody2D

signal bullet_clicked(bullet: RigidBody2D)
signal bullet_spawn_request(position: Vector2, velocity: Vector2)

@export var click_radius := 50
@export var wrap_buffer := 100

@export var bullet_velocity := 200

var click_area: Area2D
var is_hovered := false
var camera: Camera2D
var can_spawn_wrapped := true
var has_spawned_wrapped := false
var has_been_clicked := false
var click_time := 0.0
var click_reset_time := 3.0
var original_velocity := 0.0

func _ready():
	original_velocity = bullet_velocity
	_setup_click_area()
	camera = get_viewport().get_camera_2d()

func _setup_click_area():
	click_area = Area2D.new()
	click_area.name = "ClickArea"
	add_child(click_area)

	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = click_radius
	click_area.add_child(collision)

	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	click_area.input_event.connect(_on_area_input_event)
	click_area.input_pickable = true

func _physics_process(delta):
	linear_velocity.y = bullet_velocity
	_check_screen_wrap()
	_reset_click_cooldown(delta)

func _reset_click_cooldown(delta):
	if !has_been_clicked: return
	click_time += delta
	if click_time >= click_reset_time:
		has_been_clicked = false
		click_time = 0.0

func _check_screen_wrap():
	if !camera: return
	var screen_bounds = _calculate_screen_bounds()

	if global_position.x > screen_bounds.right + wrap_buffer:
		_spawn_wrapped_bullet_left(screen_bounds)
	elif global_position.x < screen_bounds.left - wrap_buffer:
		_spawn_wrapped_bullet_right(screen_bounds)

func _calculate_screen_bounds() -> Dictionary:
	var viewport_size = get_viewport_rect().size
	return {
		"left": camera.global_position.x - viewport_size.x / 2,
		"right": camera.global_position.x + viewport_size.x / 2
	}

func _spawn_wrapped_bullet_left(screen_bounds: Dictionary):
	if !can_spawn_wrapped: return
	if has_spawned_wrapped: return

	var spawn_pos = Vector2(screen_bounds.left - wrap_buffer, global_position.y)
	bullet_spawn_request.emit(spawn_pos, linear_velocity)
	has_spawned_wrapped = true

func _spawn_wrapped_bullet_right(screen_bounds: Dictionary):
	if !can_spawn_wrapped: return
	if has_spawned_wrapped: return

	var spawn_pos = Vector2(screen_bounds.right + wrap_buffer, global_position.y)
	bullet_spawn_request.emit(spawn_pos, linear_velocity)
	has_spawned_wrapped = true

func _input(event):
	if !is_hovered: return
	if has_been_clicked: return
	if !(event is InputEventMouseButton and event.pressed): return

	if event.button_index == MOUSE_BUTTON_LEFT:
		bullet_clicked.emit(self)

func _on_area_input_event(_viewport, event, _shape_idx):
	if has_been_clicked: return
	if !(event is InputEventMouseButton and event.pressed): return

	if event.button_index == MOUSE_BUTTON_LEFT:
		bullet_clicked.emit(self)

func _on_mouse_entered():
	is_hovered = true
	modulate = Color(1.5, 1.5, 1.5, 1)

func _on_mouse_exited():
	is_hovered = false
	modulate = Color(1, 1, 1, 1)

func set_on_cooldown():
	has_been_clicked = true
	click_time = 0.0

func set_bullet_velocity(velocity: float):
	bullet_velocity = velocity
	original_velocity = velocity

func invert_velocity():
	bullet_velocity = -bullet_velocity

func revert_velocity():
	bullet_velocity = original_velocity
