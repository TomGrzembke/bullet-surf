extends Node2D

var camera: Camera2D
var squares: Array[Sprite2D]
var pattern_height: float
@export var loop_buffer := 500  # Distance to wrap ahead of camera

func _ready():
	# Get all square children and sort by Y position
	for child in get_children():
		if child is Sprite2D:
			squares.append(child)

	# Sort squares by Y position (lowest Y first)
	squares.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)

	# Find the camera
	camera = get_viewport().get_camera_2d()

	# Calculate pattern height based on spacing between squares
	if squares.size() >= 2:
		# Calculate average spacing between consecutive squares
		var total_spacing = 0.0
		for i in range(squares.size() - 1):
			total_spacing += squares[i + 1].global_position.y - squares[i].global_position.y
		pattern_height = total_spacing / (squares.size() - 1) * squares.size()
	elif squares.size() == 1:
		var square_height = squares[0].get_rect().size.y * squares[0].scale.y
		pattern_height = square_height

func _process(delta):
	if !camera or squares.size() == 0:
		return

	var camera_y = camera.global_position.y
	var viewport_height = get_viewport_rect().size.y

	# Loop each square
	for square in squares:
		var square_y = square.global_position.y

		# If square is above camera (with buffer), move it below
		if square_y < camera_y - viewport_height / 2 - loop_buffer:
			square.global_position.y += pattern_height
		# If square is below camera (with buffer), move it above
		elif square_y > camera_y + viewport_height / 2 + loop_buffer:
			square.global_position.y -= pattern_height
