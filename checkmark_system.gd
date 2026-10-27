extends Node2D

# Manages milestone checkmark spawning and positioning
# Spawns checkmarks at regular height intervals and syncs them to camera

@export var player_path: NodePath = NodePath("../Player")
@export var world_parent_path: NodePath = NodePath("..")

@export var pixels_per_meter := 100
@export var milestone_mark := 100
@export var spawn_distance := 500
@export var cleanup_distance := 1000

@export var checkmark_scene: PackedScene

var player: Node2D
var camera: Camera2D
var world_parent: Node
var spawned_milestones := {}
var milestone_checkmarks := {}
var initial_height: float
var has_started := false

func _ready():
	player = get_node(player_path)
	camera = player.get_node("Camera2D")
	world_parent = get_node(world_parent_path)
	initial_height = player.global_position.y

func _process(_delta):
	_manage_milestone_checkmarks()

func _manage_milestone_checkmarks():
	if !checkmark_scene: return
	if !world_parent: return
	if !is_instance_valid(player): return

	if !has_started:
		if abs(player.global_position.y - initial_height) <= 50:
			return
		has_started = true

	var player_y = player.global_position.y
	var camera_x = 0.0
	if camera:
		camera_x = camera.global_position.x

	var current_milestone = int(floor(abs(player_y) / (milestone_mark * pixels_per_meter)))

	_spawn_ahead_milestones(current_milestone, camera_x)
	_sync_checkmarks_to_camera(camera_x)
	_cleanup_old_milestones(player_y)

func _spawn_ahead_milestones(current_milestone: int, camera_x: float):
	for i in range(current_milestone + 1, current_milestone + 5):
		if spawned_milestones.has(i): continue

		var checkmark = _spawn_checkmark_for_milestone(i, camera_x)
		if !checkmark: continue

		spawned_milestones[i] = true
		milestone_checkmarks[i] = checkmark

func _sync_checkmarks_to_camera(camera_x: float):
	for milestone in milestone_checkmarks.keys():
		var checkmark = milestone_checkmarks[milestone]
		if is_instance_valid(checkmark):
			checkmark.global_position.x = camera_x

func _cleanup_old_milestones(player_y: float):
	for milestone in milestone_checkmarks.keys():
		var checkmark = milestone_checkmarks[milestone]
		if !is_instance_valid(checkmark):
			milestone_checkmarks.erase(milestone)
			spawned_milestones.erase(milestone)
			continue

		if player_y - checkmark.global_position.y > cleanup_distance:
			checkmark.queue_free()
			milestone_checkmarks.erase(milestone)
			spawned_milestones.erase(milestone)

func _spawn_checkmark_for_milestone(milestone_num: int, camera_x: float):
	var checkmark = checkmark_scene.instantiate()
	var meters = milestone_num * milestone_mark
	var y_position = -meters * pixels_per_meter
	checkmark.global_position = Vector2(camera_x, y_position)
	world_parent.add_child(checkmark)
	return checkmark
