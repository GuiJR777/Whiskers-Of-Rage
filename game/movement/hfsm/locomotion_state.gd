class_name LocomotionState
extends Node


@export
var state_id: StringName


var machine: CharacterLocomotionStateMachine

var active_child: LocomotionState


func setup(
	p_machine: CharacterLocomotionStateMachine
) -> void:
	machine = p_machine

	for child: Node in get_children():
		var child_state := (
			child as LocomotionState
		)

		if child_state != null:
			child_state.setup(p_machine)


func enter() -> void:
	if machine != null:
		machine.notify_state_entered(self)


func exit() -> void:
	if active_child != null:
		active_child.exit()
		active_child = null


func physics_update(delta: float) -> void:
	if active_child != null:
		active_child.physics_update(delta)


func change_child(
	next_state: LocomotionState
) -> void:
	if active_child == next_state:
		return

	if active_child != null:
		active_child.exit()

	active_child = next_state

	if active_child != null:
		active_child.enter()
