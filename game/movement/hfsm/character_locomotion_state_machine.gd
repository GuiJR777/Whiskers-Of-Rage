class_name CharacterLocomotionStateMachine
extends Node


signal state_entered(state_id: StringName)
signal state_exited(state_id: StringName)


@export_category("References")

@export
var body: CharacterBody3D

@export
var movement_component: MovementComponent


@export_category("Root States")

@export
var grounded_state: GroundedLocomotionState

@export
var airborne_state: AirborneLocomotionState


var move_direction: Vector3 = Vector3.ZERO

var facing_direction: Vector3 = Vector3.ZERO


var _active_root_state: LocomotionState

var _coyote_time_remaining: float = 0.0


func _ready() -> void:
	if body == null:
		push_error(
			"LocomotionHFSM requires a CharacterBody3D."
		)
		return

	if movement_component == null:
		push_error(
			"LocomotionHFSM requires a MovementComponent."
		)
		return

	if grounded_state == null:
		push_error(
			"LocomotionHFSM requires a Grounded state."
		)
		return

	if airborne_state == null:
		push_error(
			"LocomotionHFSM requires an Airborne state."
		)
		return

	grounded_state.setup(self)
	airborne_state.setup(self)

	_coyote_time_remaining = (
		movement_component.config.coyote_time
	)

	transition_root_state(
		grounded_state
	)


func tick(delta: float) -> void:
	if _active_root_state == null:
		return

	_update_coyote_time(delta)

	_active_root_state.physics_update(delta)


func set_movement_intent(
	p_move_direction: Vector3,
	p_facing_direction: Vector3
) -> void:
	move_direction = p_move_direction
	facing_direction = p_facing_direction


func request_jump() -> bool:
	if movement_component == null:
		return false

	var can_jump := (
		_active_root_state == grounded_state
		or _coyote_time_remaining > 0.0
	)

	if not can_jump:
		return false

	_coyote_time_remaining = 0.0

	movement_component.start_jump()

	transition_root_state(
		airborne_state
	)

	return true


func release_jump() -> void:
	if movement_component == null:
		return

	movement_component.cut_jump()


func transition_root_state(
	next_state: LocomotionState
) -> void:
	if next_state == null:
		return

	if _active_root_state == next_state:
		return

	if _active_root_state != null:
		_active_root_state.exit()

	_active_root_state = next_state

	_active_root_state.enter()


func notify_state_entered(
	state: LocomotionState
) -> void:
	if state == null:
		return

	state_entered.emit(
		state.state_id
	)


func notify_state_exited(
	state: LocomotionState
) -> void:
	if state == null:
		return

	state_exited.emit(
		state.state_id
	)


func get_active_state_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	var current_state := _active_root_state

	while current_state != null:
		if current_state.state_id != &"":
			result.append(
				current_state.state_id
			)

		current_state = (
			current_state.active_child
		)

	return result


func get_jump_buffer_time() -> float:
	if (
		movement_component == null
		or movement_component.config == null
	):
		return 0.15

	return (
		movement_component
		.config
		.jump_buffer_time
	)


func _update_coyote_time(delta: float) -> void:
	if (
		_active_root_state == grounded_state
		and body.is_on_floor()
	):
		_coyote_time_remaining = (
			movement_component
			.config
			.coyote_time
		)

		return

	_coyote_time_remaining = maxf(
		_coyote_time_remaining - delta,
		0.0
	)
