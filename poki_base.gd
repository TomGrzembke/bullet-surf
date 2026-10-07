extends Node

var input_count := 0

func _input(event):
	if input_count > 1: return
	if event is not InputEventMouseButton: return
	if event.pressed: return

	if input_count == 0:
		PokiSDK.gameplay_start()
	else:
		PokiSDK.gameplay_stop()

	input_count += 1
