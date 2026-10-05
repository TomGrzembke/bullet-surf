extends CanvasLayer

@onready var height_label = $HeightLabel

@export var pixels_per_meter := 100  # 100 pixels = 1 meter
@export var player_path: NodePath = NodePath("../Player")
@export var checkmark_scene: PackedScene
@export var world_parent_path: NodePath = NodePath("..")  # Parent for world-space checkmarks
@export var spawn_distance := 500  # Distance in pixels ahead to spawn checkmarks
@export var cleanup_distance := 1000  # Distance behind to remove checkmarks

var player: Node2D
var camera: Camera2D
var world_parent: Node
var spawned_milestones := {}  # Track which milestones have been spawned
var milestone_checkmarks := {}  # Map milestone number to checkmark node
var initial_height: float
var has_started := false

func _ready():
	print("UI _ready() called")
	print("Player path: ", player_path)
	player = get_node(player_path)
	print("Player found: ", player != null)
	if height_label:
		print("HeightLabel found")
		height_label.text = "Height: 0m"

	# Get world parent for checkmarks
	world_parent = get_node(world_parent_path)

	# Get camera reference
	if player:
		camera = player.get_node("Camera2D")

	# Store initial height to prevent spawning at start
	if player:
		initial_height = player.global_position.y

func _process(delta):
	if player and height_label:
		# Calculate height in meters (negative Y is up in Godot)
		var height_meters = abs(player.global_position.y) / pixels_per_meter
		height_label.text = "Height: %.1fm" % height_meters

		# Spawn checkmarks ahead and cleanup behind
		_manage_milestone_checkmarks()

func _manage_milestone_checkmarks():
	if !checkmark_scene or !world_parent:
		return

	var player_y = player.global_position.y
	var camera_x = camera.global_position.x if camera else 0

	# Only start spawning after player has moved from initial position
	if !has_started:
		if abs(player_y - initial_height) > 50:  # 50 pixels movement threshold
			has_started = true
		else:
			return

	# Calculate which milestones should be visible
	var current_milestone = int(abs(player_y) / (100 * pixels_per_meter))

	# Spawn next few milestones ahead (only if not already spawned)
	for i in range(current_milestone + 1, current_milestone + 5):
		if !spawned_milestones.has(i):
			var checkmark = _spawn_checkmark_for_milestone(i, camera_x)
			if checkmark:
				spawned_milestones[i] = true
				milestone_checkmarks[i] = checkmark

	# Sync existing checkmarks to camera X position
	for milestone in milestone_checkmarks.keys():
		var checkmark = milestone_checkmarks[milestone]
		if is_instance_valid(checkmark):
			checkmark.global_position.x = camera_x

	# Cleanup old milestones behind player
	for milestone in milestone_checkmarks.keys():
		var checkmark = milestone_checkmarks[milestone]
		if !is_instance_valid(checkmark):
			milestone_checkmarks.erase(milestone)
			spawned_milestones.erase(milestone)
			continue

		var distance = player_y - checkmark.global_position.y
		if distance > cleanup_distance:
			checkmark.queue_free()
			milestone_checkmarks.erase(milestone)
			spawned_milestones.erase(milestone)

func _spawn_checkmark_for_milestone(milestone_num: int, camera_x: float):
	var checkmark = checkmark_scene.instantiate()

	# Calculate Y position for this milestone (negative because up is negative in Godot)
	var meters = milestone_num * 100
	var y_position = -meters * pixels_per_meter

	# Position checkmark at this milestone height, synced to camera X
	checkmark.global_position = Vector2(camera_x, y_position)

	world_parent.add_child(checkmark)

	return checkmark
