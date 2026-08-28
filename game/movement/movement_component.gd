class_name MovementComponent
extends Node


@export_category("References")

@export
var body: CharacterBody3D

@export
var config: CharacterMovementConfig


var _locomotion_velocity: Vector2 = Vector2.ZERO

var _forced_horizontal_velocity: Vector2 = Vector2.ZERO

var _forced_horizontal_deceleration: float = 0.0


func _ready() -> void:
	if body == null:
		push_error(
			"MovementComponent requires a CharacterBody3D."
		)

	if config == null:
		push_error(
			"MovementComponent requires a CharacterMovementConfig."
		)


# ============================================================================
# Locomotion
# ============================================================================

func move_ground(
	delta: float,
	move_direction: Vector3,
	facing_direction: Vector3
) -> void:
	if not _is_valid():
		return

	_update_locomotion_velocity(
		move_direction,
		delta,
		1.0
	)

	_compose_horizontal_velocity()

	if not body.is_on_floor():
		_apply_gravity(delta)

	elif body.velocity.y < 0.0:
		body.velocity.y = 0.0

	_update_rotation(
		facing_direction,
		delta
	)

	body.move_and_slide()

	_decay_forced_motion(delta)


func move_air(
	delta: float,
	move_direction: Vector3,
	facing_direction: Vector3
) -> void:
	if not _is_valid():
		return

	_update_locomotion_velocity(
		move_direction,
		delta,
		config.air_control
	)

	_compose_horizontal_velocity()

	_apply_gravity(delta)

	_update_rotation(
		facing_direction,
		delta
	)

	body.move_and_slide()

	_decay_forced_motion(delta)


# ============================================================================
# Passive Movement
# ============================================================================

func move_passive(delta: float) -> void:
	if not _is_valid():
		return

	_update_locomotion_velocity(
		Vector3.ZERO,
		delta,
		1.0
	)

	_compose_horizontal_velocity()

	if not body.is_on_floor():
		_apply_gravity(delta)

	elif body.velocity.y < 0.0:
		body.velocity.y = 0.0

	body.move_and_slide()

	_decay_forced_motion(delta)


# ============================================================================
# Jump
# ============================================================================

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


# ============================================================================
# Forced Motion
# ============================================================================

func apply_forced_motion(
	direction: Vector3,
	horizontal_speed: float,
	upward_speed: float = 0.0,
	horizontal_deceleration: float = 20.0
) -> void:
	if not _is_valid():
		return

	var flat_direction := direction

	flat_direction.y = 0.0

	if (
		not flat_direction.is_zero_approx()
		and horizontal_speed > 0.0
	):
		flat_direction = (
			flat_direction.normalized()
		)

		_forced_horizontal_velocity = (
			Vector2(
				flat_direction.x,
				flat_direction.z
			)
			* horizontal_speed
		)

		_forced_horizontal_deceleration = (
			maxf(
				horizontal_deceleration,
				0.0
			)
		)

	if upward_speed > 0.0:
		body.velocity.y = maxf(
			body.velocity.y,
			upward_speed
		)


func clear_forced_motion() -> void:
	_forced_horizontal_velocity = (
		Vector2.ZERO
	)

	_forced_horizontal_deceleration = 0.0


func has_forced_motion() -> bool:
	return (
		not _forced_horizontal_velocity
			.is_zero_approx()
		or body.velocity.y > 0.01
	)


func get_forward_direction() -> Vector3:
	if body == null:
		return Vector3.FORWARD

	var forward := (
		-body.global_transform.basis.z
	)

	forward.y = 0.0

	if forward.is_zero_approx():
		return Vector3.FORWARD

	return forward.normalized()


# ============================================================================
# Horizontal Velocity
# ============================================================================

func _update_locomotion_velocity(
	direction: Vector3,
	delta: float,
	control_multiplier: float
) -> void:
	var desired_direction := direction

	if desired_direction.length_squared() > 1.0:
		desired_direction = (
			desired_direction.normalized()
		)

	var target_velocity := Vector2(
		desired_direction.x,
		desired_direction.z
	) * config.move_speed

	var change_rate := config.acceleration

	if desired_direction.is_zero_approx():
		change_rate = config.deceleration

	change_rate *= control_multiplier

	_locomotion_velocity = (
		_locomotion_velocity.move_toward(
			target_velocity,
			change_rate * delta
		)
	)


func _compose_horizontal_velocity() -> void:
	var final_velocity := (
		_locomotion_velocity
		+ _forced_horizontal_velocity
	)

	body.velocity.x = final_velocity.x
	body.velocity.z = final_velocity.y


func _decay_forced_motion(
	delta: float
) -> void:
	if (
		_forced_horizontal_velocity
		.is_zero_approx()
	):
		return

	_forced_horizontal_velocity = (
		_forced_horizontal_velocity.move_toward(
			Vector2.ZERO,
			_forced_horizontal_deceleration
			* delta
		)
	)


# ============================================================================
# Gravity
# ============================================================================

func _apply_gravity(delta: float) -> void:
	var gravity := (
		config.get_fall_gravity()
	)

	if body.velocity.y > 0.0:
		gravity = (
			config.get_jump_gravity()
		)

	body.velocity.y -= gravity * delta


# ============================================================================
# Rotation
# ============================================================================

func _update_rotation(
	direction: Vector3,
	delta: float
) -> void:
	var flat_direction := direction

	flat_direction.y = 0.0

	if flat_direction.is_zero_approx():
		return

	flat_direction = (
		flat_direction.normalized()
	)

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


# ============================================================================
# Validation
# ============================================================================

func _is_valid() -> bool:
	return (
		body != null
		and config != null
	)
