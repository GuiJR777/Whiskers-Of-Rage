class_name CharacterMovementConfig
extends Resource


@export_category("Ground Movement")

@export_range(0.0, 30.0, 0.1)
var move_speed: float = 6.0

@export_range(0.0, 100.0, 0.1)
var acceleration: float = 30.0

@export_range(0.0, 100.0, 0.1)
var deceleration: float = 40.0

@export_range(0.0, 30.0, 0.1)
var rotation_speed: float = 12.0


@export_category("Air Movement")

@export_range(0.0, 1.0, 0.05)
var air_control: float = 0.8


@export_category("Jump")

@export_range(0.1, 10.0, 0.1)
var jump_height: float = 2.2

@export_range(0.05, 2.0, 0.05)
var time_to_apex: float = 0.4

@export_range(1.0, 5.0, 0.1)
var fall_gravity_multiplier: float = 1.6

@export_range(0.0, 1.0, 0.05)
var jump_cut_multiplier: float = 0.45


@export_category("Jump Forgiveness")

@export_range(0.0, 0.5, 0.01)
var coyote_time: float = 0.12

@export_range(0.0, 0.5, 0.01)
var jump_buffer_time: float = 0.15


func get_jump_gravity() -> float:
	if time_to_apex <= 0.0:
		return 0.0

	return (
		2.0
		* jump_height
		/ (time_to_apex * time_to_apex)
	)


func get_jump_velocity() -> float:
	if time_to_apex <= 0.0:
		return 0.0

	return (
		2.0
		* jump_height
		/ time_to_apex
	)


func get_fall_gravity() -> float:
	return (
		get_jump_gravity()
		* fall_gravity_multiplier
	)
