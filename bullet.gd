extends RigidBody2D

signal bullet_clicked(bullet: RigidBody2D)

@export var bullet_velocity := 200
@export var click_radius := 50  # Radius for click detection

var click_area: Area2D
var is_hovered := false

func _ready():
	# Create Area2D for click detection
	click_area = Area2D.new()
	click_area.name = "ClickArea"
	add_child(click_area)

	var collision = CollisionShape2D.new()
	collision.shape = CircleShape2D.new()
	collision.shape.radius = click_radius
	click_area.add_child(collision)

	# Make the area detect mouse input
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)

func _process(delta):
	linear_velocity.y = bullet_velocity

func _input(event):
	# Only process input if mouse is over THIS bullet
	if is_hovered and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Bullet clicked: ", name)
			bullet_clicked.emit(self)

func _on_mouse_entered():
	is_hovered = true
	# Highlight when hovered
	modulate = Color(1.5, 1.5, 1.5, 1)

func _on_mouse_exited():
	is_hovered = false
	modulate = Color(1, 1, 1, 1)
