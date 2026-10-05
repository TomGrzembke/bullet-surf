extends Node

signal difficulty_updated(checkpoint: int, distance_m: float)

@export var player_path: NodePath = NodePath("../Player")
@export var bullet_holder_path: NodePath = NodePath("../BulletHolder")
@export var bullet_spawn_path: NodePath = NodePath("../BulletSpawn")

# Player settings
@export var jump_speed_base := 300
@export var jump_speed_increase_per_100m := 20
@export var jump_speed_max := 800

@export var bullet_break_time_base := 1.3
@export var bullet_break_time_min := 0.3
@export var break_time_decrease_per_100m := 0.2

# Bullet settings
@export var bullet_velocity_base := 200
@export var bullet_velocity_max := 500
@export var velocity_increase_per_100m := 30

# Spawn settings
@export var spawn_interval_base := 0.55
@export var spawn_interval_min := 0.3
@export var interval_decrease_per_100m := 0.05

var player: Node2D
var bullet_holder: Node
var bullet_spawn: Node2D

var current_checkpoint := 0
var last_checkpoint_distance := 0.0

func _ready():
	# Wait for tree to be fully ready before getting nodes
	await get_tree().process_frame

	var root = get_parent()
	player = root.get_node("Player")
	bullet_holder = root.get_node("BulletHolder")
	bullet_spawn = root.get_node("BulletSpawn")

	print("DifficultyManager _ready: Player=", player, " BulletHolder=", bullet_holder, " BulletSpawn=", bullet_spawn)
	print("jump_speed_base=", jump_speed_base)

	# Apply initial difficulty
	_update_difficulty(0)

func _process(delta):
	if !player:
		return

	var distance_m = abs(player.global_position.y) / 100  # 100px = 1m
	var checkpoint = int(distance_m / 100)  # New checkpoint every 100m

	# Check if we've reached a new checkpoint
	if checkpoint > current_checkpoint:
		current_checkpoint = checkpoint
		_update_difficulty(checkpoint)
		difficulty_updated.emit(checkpoint, distance_m)

func _update_difficulty(checkpoint: int):
	# Calculate new bullet velocity (used by both bullets and spawn)
	var new_velocity = bullet_velocity_base + (checkpoint * velocity_increase_per_100m)
	new_velocity = min(new_velocity, bullet_velocity_max)

	# Update player jump speed
	if player:
		var new_jump_speed = jump_speed_base + (checkpoint * jump_speed_increase_per_100m)
		new_jump_speed = min(new_jump_speed, jump_speed_max)
		if player.has_method("set_jump_speed"):
			player.set_jump_speed(new_jump_speed)

		# Update player break time
		var new_break_time = bullet_break_time_base - (checkpoint * break_time_decrease_per_100m)
		new_break_time = max(new_break_time, bullet_break_time_min)
		if player.has_method("set_bullet_break_time_base"):
			player.set_bullet_break_time_base(new_break_time)

	# Update bullet velocity for all bullets
	if bullet_holder:
		for bullet in bullet_holder.get_children():
			if bullet.has_method("set_bullet_velocity"):
				bullet.set_bullet_velocity(new_velocity)

	# Update spawn interval and bullet velocity reference
	if bullet_spawn:
		var new_interval = spawn_interval_base - (checkpoint * interval_decrease_per_100m)
		new_interval = max(new_interval, spawn_interval_min)
		if bullet_spawn.has_method("set_spawn_interval"):
			bullet_spawn.set_spawn_interval(new_interval)
		if bullet_spawn.has_method("set_current_bullet_velocity"):
			bullet_spawn.set_current_bullet_velocity(new_velocity)

	print("Difficulty updated: Checkpoint ", checkpoint, " (", checkpoint * 100, "m)")
