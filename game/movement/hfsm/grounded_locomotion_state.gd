class_name GroundedLocomotionState
extends LocomotionState


@export_category("Child States")

@export
var idle_state: LocomotionState

@export
var moving_state: LocomotionState


func enter() -> void:
	super.enter()

	_update_child_state()


func physics_update(delta: float) -> void:
	machine.movement_component.move_ground(
		delta,
		machine.move_direction,
		machine.facing_direction
	)

	if not machine.body.is_on_floor():
		machine.transition_root_state(
			machine.airborne_state
		)
		return

	_update_child_state()

	super.physics_update(delta)


func _update_child_state() -> void:
	if machine.move_direction.is_zero_approx():
		change_child(idle_state)
	else:
		change_child(moving_state)
