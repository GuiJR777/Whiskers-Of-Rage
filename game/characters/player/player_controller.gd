class_name PlayerController
extends Node


@export_category("Pawn")

@export
var controlled_character: CharacterBody3D


@export_category("Components")

@export
var movement_component: MovementComponent

@export
var targeting_component: TargetingComponent


@export_category("Camera")

@export
var camera_override: Camera3D


func _physics_process(delta: float) -> void:
	if controlled_character == null:
		return

	if movement_component == null:
		return

	if not InputManager.is_gameplay_input_enabled():
		movement_component.stop(delta)
		return

	_process_movement(delta)


func _process_movement(delta: float) -> void:
	var input_vector := InputManager.get_move_vector()

	var move_direction := (
		_get_camera_relative_direction(
			input_vector
		)
	)

	var facing_direction := move_direction

	if (
		targeting_component != null
		and targeting_component.has_locked_target()
	):
		facing_direction = (
			_get_locked_target_direction()
		)

	movement_component.move_character(
		delta,
		move_direction,
		facing_direction
	)


func _get_camera_relative_direction(
	input_vector: Vector2
) -> Vector3:
	if input_vector.is_zero_approx():
		return Vector3.ZERO

	var camera := _get_active_camera()

	if camera == null:
		return Vector3(
			input_vector.x,
			0.0,
			input_vector.y
		)

	var camera_forward := (
		-camera.global_transform.basis.z
	)

	var camera_right := (
		camera.global_transform.basis.x
	)

	camera_forward.y = 0.0
	camera_right.y = 0.0

	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	var direction := (
		camera_right
		* input_vector.x
		+
		camera_forward
		* -input_vector.y
	)

	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	return direction


func _get_locked_target_direction() -> Vector3:
	if targeting_component == null:
		return Vector3.ZERO

	var target := (
		targeting_component.get_locked_target()
	)

	if target == null:
		return Vector3.ZERO

	var direction := (
		target.global_position
		- controlled_character.global_position
	)

	direction.y = 0.0

	if direction.is_zero_approx():
		return Vector3.ZERO

	return direction.normalized()


func _get_active_camera() -> Camera3D:
	if camera_override != null:
		return camera_override

	return get_viewport().get_camera_3d()
