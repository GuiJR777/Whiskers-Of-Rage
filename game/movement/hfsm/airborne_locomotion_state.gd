class_name AirborneLocomotionState
extends LocomotionState


@export_category("Child States")

@export
var jumping_state: LocomotionState

@export
var falling_state: LocomotionState


func enter() -> void:
	super.enter()

	_update_child_state()


func physics_update(delta: float) -> void:
	machine.movement_component.move_air(
		delta,
		machine.move_direction,
		machine.facing_direction
	)

	if machine.body.is_on_floor():
		machine.transition_root_state(
			machine.grounded_state
		)
		return

	_update_child_state()

	super.physics_update(delta)


func _update_child_state() -> void:
	if machine.movement_component.is_rising():
		change_child(jumping_state)
	else:
		change_child(falling_state)
