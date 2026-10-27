# Handles player movement, jumping to bullets, and attachment logic
# Player jumps to bullets by clicking/tapping them, attaches temporarily,
# and the bullet breaks after a duration controlled by difficulty manager

extends RigidBody2D

@export var bullet_holder : Node

@export var jump_speed: float = 400
@export var attach_distance: float = 50
@export var bullet_break_time_base: float = 0.9
@export var auto_attach_range: float = 300
@export var auto_attach_enabled: bool = true

var is_jumping := false
var is_attached := false
var target_bullet: RigidBody2D
var attached_bullet: RigidBody2D
var jump_start_position: Vector2
var jump_duration: float
var jump_elapsed: float
var attach_offset: Vector2
var attach_time: float
var current_break_time: float
var is_mouse_held := false

func _ready():
	if !bullet_holder:
		var root = get_parent()
		bullet_holder = root.get_node("BulletHolder")

	for bullet in bullet_holder.get_children():
		_connect_bullet_signals(bullet)

	bullet_holder.child_entered_tree.connect(_on_bullet_spawned)

func _input(event):
	if !auto_attach_enabled: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_held = event.pressed

	if event is InputEventScreenTouch:
		is_mouse_held = event.pressed

func _physics_process(delta):
	_update_jump(delta)
	_update_attachment(delta)
	_update_auto_attach()

func _update_auto_attach():
	if !auto_attach_enabled: return
	if !is_mouse_held: return

	var nearest_bullet = _find_nearest_bullet_to_cursor()
	if nearest_bullet:
		jump_to_bullet(nearest_bullet)

func _find_nearest_bullet_to_cursor() -> RigidBody2D:
	var touch_pos = get_global_mouse_position()
	var viewport = get_viewport()
	if viewport.has_method("get_touches"):
		var touches = viewport.get_touches()
		if touches.size() > 0:
			touch_pos = touches[0].position

	var nearest: RigidBody2D = null
	var nearest_distance = auto_attach_range

	for node in bullet_holder.get_children():
		var bullet = node as RigidBody2D
		if !bullet: continue
		if !bullet.has_method("get"): continue
		if bullet.get("is_marked_for_pooling") && bullet.is_marked_for_pooling: continue
		if is_attached && bullet == attached_bullet: continue
		if bullet.get("is_in_use_by_player") && bullet.is_in_use_by_player: continue

		var distance = touch_pos.distance_to(bullet.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = bullet

	return nearest

func _update_jump(delta):
	if !is_jumping: return
	if !target_bullet: return

	if target_bullet.has_method("get") && target_bullet.get("is_marked_for_pooling"):
		if target_bullet.is_marked_for_pooling:
			_on_jump_complete()
			return

	jump_elapsed += delta

	var progress = min(jump_elapsed / jump_duration, 1.0)
	var target_pos = target_bullet.global_position
	global_position = jump_start_position.lerp(target_pos, progress)

	var distance = global_position.distance_to(target_bullet.global_position)
	if distance <= attach_distance:
		_attach_to_bullet(target_bullet)
		is_jumping = false
		target_bullet = null
		return

	if progress >= 1.0:
		_on_jump_complete()

func _update_attachment(delta):
	if !is_attached: return

	if is_instance_valid(attached_bullet):
		global_position = attached_bullet.global_position + attach_offset

	attach_time += delta
	current_break_time = _get_current_break_time()
	if attach_time >= current_break_time:
		_detach_from_bullet()

func _connect_bullet_signals(bullet: Node):
	if !bullet.has_signal("bullet_clicked"): return
	if bullet.bullet_clicked.is_connected(_on_bullet_clicked): return

	bullet.bullet_clicked.connect(_on_bullet_clicked)

	if !bullet.has_signal("bullet_hit_ground"): return

	if !bullet.has_signal("bullet_despawning"): return
	if bullet.bullet_despawning.is_connected(_on_bullet_despawning): return

	bullet.bullet_despawning.connect(_on_bullet_despawning)

	if !bullet.has_signal("bullet_deactivating"): return
	if bullet.bullet_deactivating.is_connected(_on_bullet_deactivating): return

	bullet.bullet_deactivating.connect(_on_bullet_deactivating)

	if !bullet.has_signal("bullet_activating"): return
	if bullet.bullet_activating.is_connected(_on_bullet_activating): return

	bullet.bullet_activating.connect(_on_bullet_activating)

func _on_bullet_spawned(node: Node):
	_connect_bullet_signals(node)

func _on_bullet_clicked(bullet: RigidBody2D):
	if is_attached:
		_detach_from_bullet(false)

	jump_to_bullet(bullet)

func _on_bullet_despawning(bullet: RigidBody2D):
	if is_attached and attached_bullet == bullet:
		_detach_from_bullet(false)

func _on_bullet_deactivating(bullet: RigidBody2D):
	if is_attached and attached_bullet == bullet:
		_detach_from_bullet(false)

func _on_bullet_activating(bullet: RigidBody2D):
	if is_attached and attached_bullet == bullet:
		_detach_from_bullet(false)

func jump_to_bullet(bullet: RigidBody2D):
	if bullet.has_method("get") && bullet.get("is_marked_for_pooling"):
		if bullet.is_marked_for_pooling:
			return

	if is_attached:
		_detach_from_bullet(false)

	is_jumping = true
	target_bullet = bullet
	jump_start_position = global_position

	var distance = global_position.distance_to(bullet.global_position)
	jump_duration = distance / jump_speed
	jump_elapsed = 0.0
	freeze = true

func _on_jump_complete():
	is_jumping = false
	target_bullet = null
	freeze = false
	linear_velocity = Vector2.ZERO

func _attach_to_bullet(bullet: RigidBody2D):
	is_attached = true
	attached_bullet = bullet
	attach_time = 0.0

	_mark_bullet_used(bullet)
	_mark_bullet_in_use(bullet)
	_invert_bullet_velocity(bullet)
	_calculate_attach_offset(jump_start_position)
	freeze = true

func _mark_bullet_used(bullet: RigidBody2D):
	if bullet.has_method("set_on_cooldown"):
		bullet.set_on_cooldown()

func _mark_bullet_in_use(bullet: RigidBody2D):
	if bullet.has_method("mark_in_use"):
		bullet.mark_in_use()

func _unmark_bullet_in_use():
	if attached_bullet.has_method("mark_in_use"):
		attached_bullet.is_in_use_by_player = false

func _invert_bullet_velocity(bullet: RigidBody2D):
	if bullet.has_method("invert_velocity"):
		bullet.invert_velocity()

func _calculate_attach_offset(start_position: Vector2):
	var offset_distance = 50.0
	var direction = (start_position - attached_bullet.global_position).normalized()
	attach_offset = direction * offset_distance

func _detach_from_bullet(remove_bullet := true):
	if !is_attached: return
	if !attached_bullet: return

	var bullet_to_remove = null
	if remove_bullet:
		bullet_to_remove = attached_bullet

	_revert_bullet_velocity()
	_unmark_bullet_in_use()
	_reset_player_state()

	if bullet_to_remove:
		if bullet_to_remove.has_method("request_despawn"):
			bullet_to_remove.request_despawn()
		else:
			bullet_to_remove.queue_free()

func _revert_bullet_velocity():
	if attached_bullet.has_method("revert_velocity"):
		attached_bullet.revert_velocity()

func _reset_player_state():
	is_attached = false
	attached_bullet = null
	set_deferred("freeze", false)
	linear_velocity = Vector2.ZERO

func _get_current_break_time() -> float:
	return bullet_break_time_base

func set_jump_speed(value: float):
	jump_speed = value

func set_bullet_break_time_base(value: float):
	bullet_break_time_base = value
