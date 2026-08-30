class_name LocomotionAnimationBridge
extends Node


@export_category("References")

@export
var locomotion_state_machine: CharacterLocomotionStateMachine

@export
var animation_controller: CharacterAnimationController


@export_category("Animation States")

@export
var idle_state: StringName = &"idle"

@export
var move_state: StringName = &"move"

@export
var jump_state: StringName = &"jump"

@export
var fall_state: StringName = &"fall"


func _ready() -> void:
	if locomotion_state_machine == null:
		push_error(
			"LocomotionAnimationBridge requires a LocomotionHFSM."
		)
		return

	if animation_controller == null:
		push_error(
			"LocomotionAnimationBridge requires a CharacterAnimationController."
		)
		return

	locomotion_state_machine.state_entered.connect(
		_on_state_entered
	)

	call_deferred(
		"_sync_current_state"
	)


func _on_state_entered(
	state_id: StringName
) -> void:
	var animation_state := (
		_get_animation_state(
			state_id
		)
	)

	if animation_state == &"":
		return

	animation_controller.set_locomotion_state(
		animation_state
	)


func _sync_current_state() -> void:
	for state_id: StringName in (
		locomotion_state_machine
		.get_active_state_ids()
	):
		var animation_state := (
			_get_animation_state(
				state_id
			)
		)

		if animation_state == &"":
			continue

		animation_controller.set_locomotion_state(
			animation_state
		)


func _get_animation_state(
	state_id: StringName
) -> StringName:
	match state_id:
		&"Idle":
			return idle_state

		&"Moving":
			return move_state

		&"Jumping":
			return jump_state

		&"Falling":
			return fall_state

	return &""
