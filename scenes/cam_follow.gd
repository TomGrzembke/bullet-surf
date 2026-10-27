extends Camera2D

@export var follow_obj : Node2D
@export var follow_offset : Vector2

func _physics_process(_delta):
	if follow_obj == null: return
	
	position.y = follow_obj.position.y + follow_offset.y 
