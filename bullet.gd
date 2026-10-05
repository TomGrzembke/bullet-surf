extends RigidBody2D

signal bullet_clicked(bullet: RigidBody2D)

@export var bullet_velocity := 200
@export var click_radius := 50  # Radius for click detection

func _ready():
	mouse_filter = MOUSE_FILTER_STOP  # Allow this node to receive mouse events

func _process(delta):
	linear_velocity.y = bullet_velocity

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			bullet_clicked.emit(self)
