class_name MovementComponent
extends Node


@export_category("References")

@export
var body: CharacterBody3D

@export
var config: CharacterMovementConfig


func _ready() -> void:
	if body == null:
		push_error(
			"MovementComponent requires a CharacterBody3D."
		)

	if config == null:
		push_error(
			"MovementComponent requires a CharacterMovementConfig."
		)


func move_ground(
	delta: float,
	move_direction: Vector3,
	facing_direction: Vector3
) -> void:
	if not _is_valid():
		return

	_update_horizontal_velocity(
		move_direction,
		delta,
		1.0
	)

	if not body.is_on_floor():
		_apply_gravity(delta)
	elif body.velocity.y < 0.0:
		body.velocity.y = 0.0

	_update_rotation(
		facing_direction,
		delta
	)

	body.move_and_slide()


func move_air(
	delta: float,
	move_direction: Vector3,
	facing_direction: Vector3
) -> void:
	if not _is_valid():
		return

	_update_horizontal_velocity(
		move_direction,
		delta,
		config.air_control
	)

	_apply_gravity(delta)

	_update_rotation(
		facing_direction,
		delta
	)

	body.move_and_slide()


func start_jump() -> void:
	if not _is_valid():
		return

	body.velocity.y = (
		config.get_jump_velocity()
	)


func cut_jump() -> void:
	if not _is_valid():
		return

	if body.velocity.y <= 0.0:
		return

	body.velocity.y *= (
		config.jump_cut_multiplier
	)


func is_rising() -> bool:
	if body == null:
		return false

	return body.velocity.y > 0.01


func is_falling() -> bool:
	if body == null:
		return false

	return body.velocity.y < -0.01


func _update_horizontal_velocity(
	direction: Vector3,
	delta: float,
	control_multiplier: float
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

	change_rate *= control_multiplier

	current_velocity = (
		current_velocity.move_toward(
			target_velocity,
			change_rate * delta
		)
	)

	body.velocity.x = current_velocity.x
	body.velocity.z = current_velocity.y


func _apply_gravity(delta: float) -> void:
	var gravity := config.get_fall_gravity()

	if body.velocity.y > 0.0:
		gravity = config.get_jump_gravity()

	body.velocity.y -= gravity * delta


func _update_rotation(
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


func _is_valid() -> bool:
	return (
		body != null
		and config != null
	)
