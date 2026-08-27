class_name MovementComponent
extends Node


@export_category("References")

@export
var body: CharacterBody3D

@export
var config: CharacterMovementConfig


var _gravity: float = 9.8


func _ready() -> void:
	if body == null:
		push_error(
			"MovementComponent requires a CharacterBody3D."
		)

	if config == null:
		push_error(
			"MovementComponent requires a CharacterMovementConfig."
		)

	_gravity = float(
		ProjectSettings.get_setting(
			"physics/3d/default_gravity",
			9.8
		)
	)


func move_character(
	delta: float,
	move_direction: Vector3,
	facing_direction: Vector3 = Vector3.ZERO
) -> void:
	if body == null or config == null:
		return

	_update_horizontal_velocity(
		move_direction,
		delta
	)

	_update_gravity(delta)

	var desired_facing := facing_direction

	if desired_facing.is_zero_approx():
		desired_facing = move_direction

	if not desired_facing.is_zero_approx():
		_rotate_towards(
			desired_facing,
			delta
		)

	body.move_and_slide()


func stop(delta: float) -> void:
	move_character(
		delta,
		Vector3.ZERO
	)


func _update_horizontal_velocity(
	direction: Vector3,
	delta: float
) -> void:
	var desired_direction := direction

	if desired_direction.length_squared() > 1.0:
		desired_direction = desired_direction.normalized()

	var target_velocity := Vector2(
		desired_direction.x,
		desired_direction.z
	) * config.move_speed

	var current_velocity := Vector2(
		body.velocity.x,
		body.velocity.z
	)

	var change_rate := config.acceleration

	if desired_direction.is_zero_approx():
		change_rate = config.deceleration

	current_velocity = current_velocity.move_toward(
		target_velocity,
		change_rate * delta
	)

	body.velocity.x = current_velocity.x
	body.velocity.z = current_velocity.y


func _update_gravity(delta: float) -> void:
	if body.is_on_floor():
		if body.velocity.y < 0.0:
			body.velocity.y = 0.0

		return

	body.velocity.y -= (
		_gravity
		* config.gravity_scale
		* delta
	)


func _rotate_towards(
	direction: Vector3,
	delta: float
) -> void:
	var flat_direction := direction

	flat_direction.y = 0.0

	if flat_direction.is_zero_approx():
		return

	flat_direction = flat_direction.normalized()

	var target_yaw := atan2(
		-flat_direction.x,
		-flat_direction.z
	)

	var rotation_weight := (
		1.0
		- exp(
			-config.rotation_speed
			* delta
		)
	)

	body.rotation.y = lerp_angle(
		body.rotation.y,
		target_yaw,
		rotation_weight
	)
