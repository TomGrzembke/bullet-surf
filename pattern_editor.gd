# Pattern editor for designing bullet patterns visually
# Uses actual bullet nodes for preview and saves/loads patterns as resources

@tool
extends Node2D

@export var bullet_scene: PackedScene
@export var settings: UnitSettings
@export var preview_settings: PreviewSettings
@export var start_point: Node2D
@export var current_pattern: BulletPattern

var pattern_bullets := []

func _ready():
	if Engine.is_editor_hint():
		_load_pattern()

func _process(_delta):
	if Engine.is_editor_hint():
		_sync_bullets_to_start_point()

func _sync_bullets_to_start_point():
	if !start_point: return
	var start_pos = start_point.global_position
	
	for bullet in pattern_bullets:
		if is_instance_valid(bullet):
			var offset = bullet.get_meta("pattern_offset", Vector2.ZERO)
			bullet.global_position = start_pos + offset

@export_tool_button("Add Bullet") var add_bullet_action = add_bullet
@export_tool_button("Remove Last Bullet") var remove_last_bullet_action = remove_last_bullet
@export_tool_button("Clear All Bullets") var clear_bullets_action = clear_bullets
@export_tool_button("Save Pattern") var save_pattern_action = save_pattern
@export_tool_button("Load Pattern") var load_pattern_action = load_pattern

func add_bullet():
	var bullet = bullet_scene.instantiate()
	if start_point:
		bullet.global_position = start_point.global_position
	bullet.set_meta("pattern_offset", Vector2.ZERO)
	add_child(bullet)
	bullet.set_owner(get_tree().edited_scene_root)
	pattern_bullets.append(bullet)

func remove_last_bullet():
	if pattern_bullets.is_empty(): return
	var bullet = pattern_bullets.pop_back()
	if is_instance_valid(bullet):
		bullet.queue_free()

func clear_bullets():
	for bullet in pattern_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()
	pattern_bullets.clear()

func save_pattern():
	var offsets: Array[Vector2] = []

	var start_pos = Vector2.ZERO
	if start_point:
		start_pos = start_point.global_position

	for child in get_children():
		if child is RigidBody2D:
			var offset = child.global_position - start_pos
			offsets.append(offset)

	if offsets.is_empty(): return

	var pattern = BulletPattern.new()
	pattern.set("bullet_offsets", offsets)

	if current_pattern:
		_save_as_new_or_override(pattern)
	else:
		_save_with_name_dialog(pattern)

func _save_as_new_or_override(pattern: BulletPattern):
	var dialog = ConfirmationDialog.new()
	dialog.title = "Pattern already exists"
	dialog.dialog_text = "Save as new pattern or override current?"
	dialog.get_ok_button().hide()
	dialog.get_cancel_button().hide()
	dialog.add_button("Cancel", false, "cancel")
	dialog.add_button("Save New", false, "new")
	dialog.add_button("Override", false, "override")
	dialog.custom_action.connect(_on_dialog_action.bind(pattern, dialog))
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

func _on_dialog_action(action, pattern, dialog):
	dialog.queue_free()
	if action == "new":
		_on_save_new(pattern)
	elif action == "override":
		_on_override_pattern(pattern)
	elif action == "cancel":
		pass

func _on_override_pattern(pattern: BulletPattern):
	current_pattern.set("bullet_offsets", pattern.bullet_offsets)
	ResourceSaver.save(current_pattern, current_pattern.resource_path)
	print("Pattern overridden with %d bullets" % pattern.bullet_offsets.size())

func _on_save_new(pattern: BulletPattern):
	_save_with_name_dialog(pattern)

func _save_with_name_dialog(pattern: BulletPattern):
	var dialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.tres", "Pattern Resources")
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.current_dir = "res://patterns"
	dialog.current_file = "my_pattern.tres"
	dialog.file_selected.connect(_on_name_selected.bind(pattern, dialog))
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

func _on_name_selected(path, pattern, dialog):
	dialog.queue_free()
	pattern.set("bullet_offsets", pattern.bullet_offsets)
	ResourceSaver.save(pattern, path)
	current_pattern = load(path) as BulletPattern
	notify_property_list_changed()
	print("Pattern saved to %s with %d bullets" % [path, pattern.bullet_offsets.size()])

func load_pattern():
	var dialog = EditorFileDialog.new()
	dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.tres", "Pattern Resources")
	dialog.access = EditorFileDialog.ACCESS_RESOURCES
	dialog.file_selected.connect(_on_pattern_file_selected.bind(dialog))
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

func _on_pattern_file_selected(path, dialog):
	dialog.queue_free()
	var pattern = load(path) as BulletPattern
	if !pattern: return

	current_pattern = pattern
	clear_bullets()

	var start_pos = Vector2.ZERO
	if start_point:
		start_pos = start_point.global_position

	for offset in pattern.bullet_offsets:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = start_pos + offset
		bullet.set_meta("pattern_offset", offset)
		add_child(bullet)
		bullet.set_owner(get_tree().edited_scene_root)
		pattern_bullets.append(bullet)

	print("Pattern loaded with %d bullets" % pattern.bullet_offsets.size())

func _load_pattern():
	pass
