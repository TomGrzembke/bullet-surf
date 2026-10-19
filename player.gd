# Handles player movement, jumping to bullets, and attachment logic
# Player jumps to bullets by clicking/tapping them, attaches temporarily,
# and the bullet breaks after a duration controlled by difficulty manager

extends RigidBody2D

@export var bullet_holder : Node

@export var jump_speed := 400
@export var attach_distance := 50
@export var bullet_break_time_base := 0.9

var is_jumping := false
var is_attached := false
var target_bullet: RigidBody2D
var attached_bullet: RigidBody2D
var jump_start_position: Vector2
var jump_duration: float
var jump_elapsed: float
var original_parent: Node
var attach_offset: Vector2
var attach_time: float
var current_break_time: float

func _ready():
	if !bullet_holder:
		var root = get_parent()
		bullet_holder = root.get_node("BulletHolder")

	for bullet in bullet_holder.get_children():
		_connect_bullet_signals(bullet)

	bullet_holder.child_entered_tree.connect(_on_bullet_spawned)

func _physics_process(delta):
	_update_jump(delta)
	_update_attachment(delta)

func _update_jump(delta):
	if !is_jumping: return
	if !target_bullet: return

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

	attach_time += delta
	current_break_time = _get_current_break_time()
	if attach_time >= current_break_time:
		_detach_from_bullet()

func _connect_bullet_signals(bullet: Node):
	if !bullet.has_signal("bullet_clicked"): return
	if bullet.bullet_clicked.is_connected(_on_bullet_clicked): return

	bullet.bullet_clicked.connect(_on_bullet_clicked)

func _on_bullet_spawned(node: Node):
	_connect_bullet_signals(node)

func _on_bullet_clicked(bullet: RigidBody2D):
	if is_attached:
		_detach_from_bullet(false)

	jump_to_bullet(bullet)

func jump_to_bullet(bullet: RigidBody2D):
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
	original_parent = get_parent()
	attach_time = 0.0

	_mark_bullet_used(bullet)
	_invert_bullet_velocity(bullet)
	_reparent_to_bullet(bullet)
	freeze = true

func _mark_bullet_used(bullet: RigidBody2D):
	if bullet.has_method("set_on_cooldown"):
		bullet.set_on_cooldown()

func _invert_bullet_velocity(bullet: RigidBody2D):
	if bullet.has_method("invert_velocity"):
		bullet.invert_velocity()

func _reparent_to_bullet(bullet: RigidBody2D):
	var current_global_pos = global_position
	reparent(bullet)
	global_position = current_global_pos
	attach_offset = global_position - bullet.global_position

func _detach_from_bullet(remove_bullet := true):
	if !is_attached: return
	if !attached_bullet: return

	var bullet_to_remove = attached_bullet if remove_bullet else null

	_revert_bullet_velocity()
	_reparent_to_original()
	_reset_player_state()

	if bullet_to_remove:
		if bullet_to_remove.has_method("request_despawn"):
			bullet_to_remove.request_despawn()
		else:
			bullet_to_remove.queue_free()

func _revert_bullet_velocity():
	if attached_bullet.has_method("revert_velocity"):
		attached_bullet.revert_velocity()

func _reparent_to_original():
	reparent(original_parent)
	global_position = attached_bullet.global_position + attach_offset

func _reset_player_state():
	is_attached = false
	attached_bullet = null
	original_parent = null
	freeze = false
	linear_velocity = Vector2.ZERO

func _get_current_break_time() -> float:
	return bullet_break_time_base

func set_jump_speed(value: float):
	jump_speed = value

func set_bullet_break_time_base(value: float):
	bullet_break_time_base = value
