class_name AttackMotionDefinition
extends Resource


@export_category("Identity")

@export
var motion_id: StringName = &""


@export_category("Motion")

@export_range(0.0, 30.0, 0.1)
var forward_speed: float = 0.0

@export_range(0.0, 30.0, 0.1)
var upward_speed: float = 0.0

@export_range(0.0, 100.0, 0.1)
var horizontal_deceleration: float = 25.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if motion_id == &"":
		errors.append(
			"AttackMotionDefinition.motion_id cannot be empty."
		)

	if forward_speed < 0.0:
		errors.append(
			"AttackMotionDefinition.forward_speed cannot be negative."
		)

	if upward_speed < 0.0:
		errors.append(
			"AttackMotionDefinition.upward_speed cannot be negative."
		)

	if horizontal_deceleration < 0.0:
		errors.append(
			"AttackMotionDefinition.horizontal_deceleration cannot be negative."
		)

	return errors
