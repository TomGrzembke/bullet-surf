# Level design tool to preview checkmark placement and grid
# Displays checkmarks at height intervals and a grid for bullet placement testing

@tool
extends Node2D

@export var settings: UnitSettings
@export var preview_settings: PreviewSettings
@export var checkmark_scene: PackedScene
@export var start_point: Node2D

@warning_ignore("unused_private_class_variable")
@export_tool_button("Redraw Preview") var _sync_btn = redraw_preview

func redraw_preview():
	refresh_preview()

var spawned_checkmarks := {}
var grid_lines := []

func _ready():
	if Engine.is_editor_hint():
		_spawn_visible_checkmarks()
		_spawn_grid()

func _process(_delta):
	if Engine.is_editor_hint():
		_spawn_visible_checkmarks()
		_spawn_grid()

func _spawn_visible_checkmarks():
	if !preview_settings.show_checkmarks: return
	if !checkmark_scene: return
	if !settings: return
	if !preview_settings: return

	var start_y = 0.0
	if start_point:
		start_y = start_point.global_position.y

	var start_milestone = int(floor(abs(start_y) / (preview_settings.milestone_mark * settings.pixels_per_meter)))

	for i in range(start_milestone, start_milestone + preview_settings.visible_range):
		if spawned_checkmarks.has(i): continue

		var checkmark = _spawn_checkmark_for_milestone(i)
		if !checkmark: continue

		spawned_checkmarks[i] = checkmark

func _spawn_checkmark_for_milestone(milestone_num: int):
	var checkmark = checkmark_scene.instantiate()
	var meters = milestone_num * preview_settings.milestone_mark
	var y_position = -meters * settings.pixels_per_meter
	var x_position = 0.0
	if start_point:
		x_position = start_point.global_position.x
	checkmark.global_position = Vector2(x_position, y_position)
	add_child(checkmark)
	return checkmark

func _spawn_grid():
	if !preview_settings.show_grid: return
	if !preview_settings: return

	_clear_grid()

	var start_pos = Vector2.ZERO
	if start_point:
		start_pos = start_point.global_position

	var grid_width = 2000.0
	var grid_height = preview_settings.visible_range * preview_settings.milestone_mark * settings.pixels_per_meter if settings else 2000.0

	for x in range(-grid_width, grid_width, preview_settings.grid_x_division):
		var line = Line2D.new()
		line.default_color = Color(1, 1, 1, 0.3)
		line.width = preview_settings.grid_line_width
		line.add_point(start_pos + Vector2(x, 0))
		line.add_point(start_pos + Vector2(x, -grid_height))
		add_child(line)
		grid_lines.append(line)

	for y in range(0, grid_height, preview_settings.grid_y_division):
		var line = Line2D.new()
		line.default_color = Color(1, 1, 1, 0.3)
		line.width = preview_settings.grid_line_width
		line.add_point(start_pos + Vector2(-grid_width, -y))
		line.add_point(start_pos + Vector2(grid_width, -y))
		add_child(line)
		grid_lines.append(line)

func _clear_grid():
	for line in grid_lines:
		if is_instance_valid(line):
			line.queue_free()
	grid_lines.clear()

func refresh_preview():
	for checkmark in spawned_checkmarks.values():
		if is_instance_valid(checkmark):
			checkmark.queue_free()
	spawned_checkmarks.clear()
	_clear_grid()
	_spawn_visible_checkmarks()
	_spawn_grid()
