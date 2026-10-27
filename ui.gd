# Handles UI display of height/travel distance and speed
# Updates height and speed labels based on player position

extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")

@export var pixels_per_meter := 100

@onready var height_label = $HeightLabel
@onready var speed_label = $SpeedLabel

var player: Node2D

func _ready():
	player = get_node(player_path)
	height_label.text = "Height: 0m"
	_update_speed_label()

func _process(_delta):
	if player and height_label:
		var height_meters = abs(player.global_position.y) / pixels_per_meter
		height_label.text = "Height: %1.fm" % height_meters
		_update_speed_label()

func _update_speed_label():
	if !player: return
	if !speed_label: return

	var jump_speed = player.get("jump_speed")
	if jump_speed == null: return

	var speed_kmh = float(jump_speed) / pixels_per_meter
	speed_label.text = "%.1f km/h" % speed_kmh
