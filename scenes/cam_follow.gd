extends Camera2D

@export var follow_obj : Node2D
@export var follow_offset : Vector2
@export var smoothing_speed: float = 10.0

func _physics_process(delta):
	if follow_obj == null: return
	
	var target_y = follow_obj.global_position.y + follow_offset.y
	var step = smoothing_speed * delta
	
	if smoothing_speed == 0: 
		step = 1
		
	position.y = lerp(position.y, target_y,  step)
