# Manages game difficulty scaling based on player height/distance
# Updates player jump speed, bullet velocity, spawn interval, and break time
# every configured checkpoint to progressively increase difficulty

extends Node

signal difficulty_updated(checkpoint: int, distance_m: float)

@export var player_path: NodePath = NodePath("../Player")
@export var bullet_holder_path: NodePath = NodePath("../BulletHolder")
@export var bullet_spawn_path: NodePath = NodePath("../BulletSpawn")

@export var checkpoint_distance_m := 25

@export var jump_speed_base := 300
@export var jump_speed_max := 800
@export var jump_speed_upgrade_curve: Curve
@export_range(1, 100) var jump_speed_curve_checkpoint_count := 20

@export var bullet_break_time_base := 1.3
@export var bullet_break_time_min := 0.3
@export var break_time_decrease_per_100m := 0.2

@export var bullet_velocity_base := 200
@export var bullet_velocity_max := 500
@export var velocity_increase_per_100m := 30

@export var spawn_interval_base := 0.55
@export var spawn_interval_min := 0.3
@export var interval_decrease_per_100m := 0.05

var player: Node2D
var bullet_holder: Node
var bullet_spawn: Node2D

var current_checkpoint := 0

func _ready():
	await get_tree().process_frame
	_initialize_node_references()
	_update_difficulty(0)

func _initialize_node_references():
	var root = get_parent()
	player = root.get_node("Player")
	bullet_holder = root.get_node("BulletHolder")
	bullet_spawn = root.get_node("BulletSpawn")

func _process(_delta):
	if !player: return

	var distance_m = abs(player.global_position.y) / 100
	var checkpoint = int(floor(distance_m / checkpoint_distance_m))

	while checkpoint > current_checkpoint:
		current_checkpoint += 1
		_update_difficulty(current_checkpoint)
		difficulty_updated.emit(current_checkpoint, distance_m)

func _update_difficulty(checkpoint: int):
	var new_velocity = _calculate_bullet_velocity(checkpoint)
	_update_player_difficulty(checkpoint)
	_update_bullet_velocities(new_velocity)
	_update_spawn_difficulty(checkpoint, new_velocity)

func _calculate_bullet_velocity(checkpoint: int) -> float:
	var velocity = bullet_velocity_base + (_get_progression_multiplier(checkpoint) * velocity_increase_per_100m)
	return min(velocity, bullet_velocity_max)

func _update_player_difficulty(checkpoint: int):
	if !player: return

	var new_jump_speed = _get_upgraded_jump_speed(checkpoint)
	if player.has_method("set_jump_speed"):
		player.set_jump_speed(new_jump_speed)

	var new_break_time = bullet_break_time_base - (_get_progression_multiplier(checkpoint) * break_time_decrease_per_100m)
	new_break_time = max(new_break_time, bullet_break_time_min)
	if player.has_method("set_bullet_break_time_base"):
		player.set_bullet_break_time_base(new_break_time)

func _update_bullet_velocities(velocity: float):
	if !bullet_holder:
		return

	for bullet in bullet_holder.get_children():
		if bullet.has_method("set_bullet_velocity"):
			bullet.set_bullet_velocity(velocity)

func _update_spawn_difficulty(checkpoint: int, velocity: float):
	if !bullet_spawn:
		return

	var new_interval = spawn_interval_base - (_get_progression_multiplier(checkpoint) * interval_decrease_per_100m)
	new_interval = max(new_interval, spawn_interval_min)
	if bullet_spawn.has_method("set_spawn_interval"):
		bullet_spawn.set_spawn_interval(new_interval)
	if bullet_spawn.has_method("set_current_bullet_velocity"):
		bullet_spawn.set_current_bullet_velocity(velocity)

func _get_progression_multiplier(checkpoint: int) -> float:
	return checkpoint * checkpoint_distance_m / 100.0

func _get_upgraded_jump_speed(checkpoint: int) -> float:
	var curve_progress = min(float(checkpoint) / jump_speed_curve_checkpoint_count, 1.0)
	var curve_multiplier = 1.0
	if jump_speed_upgrade_curve:
		curve_multiplier = jump_speed_upgrade_curve.sample_baked(curve_progress)
	return lerpf(jump_speed_base, jump_speed_max, clampf(curve_multiplier, 0.0, 1.0))
