# Handles bullet movement, click detection, and screen wrapping
# Bullets move vertically, can be clicked by player to jump to them,
# and wrap horizontally to spawn new bullets

extends RigidBody2D

signal bullet_clicked(bullet: RigidBody2D)
signal bullet_spawn_request(spawn_position: Vector2, velocity: Vector2)
signal bullet_despawn_request(bullet: RigidBody2D)
signal bullet_hit_ground(bullet: RigidBody2D)
signal bullet_despawning(bullet: RigidBody2D)
signal bullet_deactivating(bullet: RigidBody2D)
signal bullet_activating(bullet: RigidBody2D)

@export var wrap_buffer: float = 100

@export var bullet_velocity: float = 200

@onready var click_area: Area2D = $ClickArea
@onready var click_collision: CollisionShape2D = $ClickArea/CollisionShape2D

var is_hovered := false
var camera: Camera2D
var can_spawn_wrapped := true
var has_spawned_wrapped := false
var has_been_clicked := false
var click_time: float = 0.0
var click_reset_time: float = 3.0
var original_velocity: float = 0.0
var is_click_area_enabled := true
var is_in_use_by_player := false
var is_marked_for_pooling := false

func _ready():
	original_velocity = bullet_velocity
	_connect_click_area()
	body_entered.connect(_on_body_entered)
	camera = get_viewport().get_camera_2d()

func _connect_click_area():
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	click_area.input_event.connect(_on_area_input_event)

func _physics_process(delta):
	linear_velocity.y = bullet_velocity
	if _check_screen_wrap(): return

	_reset_click_cooldown(delta)
	_update_click_area()

func _reset_click_cooldown(delta):
	if !has_been_clicked: return
	click_time += delta
	if click_time >= click_reset_time:
		has_been_clicked = false
		click_time = 0.0

func _check_screen_wrap() -> bool:
	if !camera: return false
	var screen_bounds = _calculate_screen_bounds()

	if global_position.x > screen_bounds.right + wrap_buffer:
		_spawn_wrapped_bullet_left(screen_bounds)
		return true
	elif global_position.x < screen_bounds.left - wrap_buffer:
		_spawn_wrapped_bullet_right(screen_bounds)
		return true

	return false

func _update_click_area():
	if !camera: return

	var viewport_size = get_viewport_rect().size
	var click_radius = _get_click_radius()
	var is_in_camera_range = abs(global_position.x - camera.global_position.x) <= viewport_size.x / 2 + click_radius
	is_in_camera_range = is_in_camera_range and abs(global_position.y - camera.global_position.y) <= viewport_size.y / 2 + click_radius
	_set_click_area_enabled(is_in_camera_range)

func _get_click_radius() -> float:
	var shape = click_collision.shape
	if shape is CircleShape2D:
		return shape.radius

	return 0.0

func _set_click_area_enabled(is_enabled: bool):
	if is_click_area_enabled == is_enabled: return

	is_click_area_enabled = is_enabled
	click_area.set_deferred("input_pickable", is_enabled)
	click_collision.set_deferred("disabled", !is_enabled)

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
	request_despawn()

func _on_area_input_event(_viewport, event, _shape_idx):
	if has_been_clicked: return
	if !_is_click_press(event): return

	bullet_clicked.emit(self)

func _on_body_entered(body: Node):
	if !body.is_in_group("floor"): return

	if is_in_use_by_player:
		invert_velocity()
		return

	bullet_hit_ground.emit(self)
	request_despawn()

func _is_click_press(event) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed

	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	return false

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

func activate(spawn_position: Vector2, velocity: Vector2, can_wrap := true):
	bullet_activating.emit(self)
	global_position = spawn_position
	linear_velocity = velocity
	bullet_velocity = velocity.y
	original_velocity = velocity.y
	can_spawn_wrapped = can_wrap
	has_spawned_wrapped = false
	has_been_clicked = false
	click_time = 0.0
	visible = true
	freeze = false
	set_physics_process(true)
	_set_click_area_enabled(true)
	is_in_use_by_player = false
	is_marked_for_pooling = false

func mark_in_use():
	is_in_use_by_player = true

func can_be_pooled() -> bool:
	return !is_in_use_by_player

func request_despawn():
	bullet_despawn_request.emit(self)

func deactivate():
	is_marked_for_pooling = true
	linear_velocity = Vector2.ZERO
	visible = false
	freeze = true
	_set_click_area_enabled(false)
	set_physics_process(false)
	bullet_deactivating.emit(self)
	bullet_despawning.emit(self)
