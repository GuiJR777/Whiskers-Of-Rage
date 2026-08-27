class_name PlayerController
extends Node


@export_category("Pawn")

@export
var controlled_character: CharacterBody3D


@export_category("Locomotion")

@export
var locomotion_state_machine: CharacterLocomotionStateMachine

@export
var targeting_component: TargetingComponent


@export_category("Combat")

@export
var light_attack_hitbox: HitboxComponent

@export
var light_attack_definition: MeleeAttackDefinition


@export_category("Camera")

@export
var camera_override: Camera3D


func _ready() -> void:
	if locomotion_state_machine == null:
		push_error(
			"PlayerController requires a LocomotionHFSM."
		)
		return

	InputManager.register_buffered_action(
		InputManager.JUMP,
		locomotion_state_machine.get_jump_buffer_time()
	)

	if light_attack_definition != null:
		InputManager.register_buffered_action(
			InputManager.LIGHT_ATTACK,
			light_attack_definition.input_buffer_time
		)


func _physics_process(delta: float) -> void:
	if controlled_character == null:
		return

	if locomotion_state_machine == null:
		return

	var move_direction := Vector3.ZERO
	var facing_direction := Vector3.ZERO

	if InputManager.is_gameplay_input_enabled():
		var input_vector := (
			InputManager.get_move_vector()
		)

		move_direction = (
			_get_camera_relative_direction(
				input_vector
			)
		)

		facing_direction = move_direction

		if (
			targeting_component != null
			and targeting_component.has_locked_target()
		):
			facing_direction = (
				_get_locked_target_direction()
			)

		_process_jump_input()
		_process_combat_input()

	locomotion_state_machine.set_movement_intent(
		move_direction,
		facing_direction
	)

	locomotion_state_machine.tick(delta)


func _process_jump_input() -> void:
	if InputManager.has_buffered_action(
		InputManager.JUMP
	):
		var accepted := (
			locomotion_state_machine
			.request_jump()
		)

		if accepted:
			InputManager.consume_buffered_action(
				InputManager.JUMP
			)

	if InputManager.is_action_just_released(
		InputManager.JUMP
	):
		locomotion_state_machine.release_jump()


func _process_combat_input() -> void:
	if light_attack_hitbox == null:
		return

	if light_attack_definition == null:
		return

	if not InputManager.has_buffered_action(
		InputManager.LIGHT_ATTACK
	):
		return

	var accepted := (
		light_attack_hitbox
		.try_activate_attack(
			light_attack_definition
		)
	)

	if not accepted:
		return

	InputManager.consume_buffered_action(
		InputManager.LIGHT_ATTACK
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
