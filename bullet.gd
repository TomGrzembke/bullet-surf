extends RigidBody2D


@export var bullet_velocity := 200


func _process(delta):
	$".".linear_velocity.y = bullet_velocity
