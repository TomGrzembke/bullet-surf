extends Node2D

# Creates an infinite scrolling background by repositioning sprites

var camera: Camera2D
var squares: Array[Sprite2D]
var pattern_height: float
@export var loop_buffer := 500

func _ready():
	_collect_squares()
	squares.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	camera = get_viewport().get_camera_2d()
	_calculate_pattern_height()

func _collect_squares():
	for child in get_children():
		if child is not Sprite2D: continue
		squares.append(child)

func _calculate_pattern_height():
	if squares.size() >= 2:
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

	for square in squares:
		var square_y = square.global_position.y

		if square_y < camera_y - viewport_height / 2 - loop_buffer:
			square.global_position.y += pattern_height
		elif square_y > camera_y + viewport_height / 2 + loop_buffer:
			square.global_position.y -= pattern_height
