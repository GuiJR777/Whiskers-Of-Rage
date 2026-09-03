class_name AttackTargetingDefinition
extends Resource


@export_category("Acquisition")

@export
var enabled: bool = true

@export_range(0.0, 20.0, 0.1)
var acquisition_range: float = 5.0

@export_range(0.0, 180.0, 1.0)
var max_angle_degrees: float = 65.0


@export_category("Scoring")

@export_range(0.0, 1.0, 0.05)
var angle_weight: float = 0.65

@export_range(0.0, 1.0, 0.05)
var distance_weight: float = 0.35


@export_category("Facing")

@export
var face_target_during_attack: bool = true


@export_category("Attack Motion")

@export
var redirect_attack_motion: bool = true


@export_category("Magnetism")

@export
var magnetism_enabled: bool = true

@export_range(0.0, 5.0, 0.05)
var stopping_distance: float = 1.15

@export_range(0.0, 5.0, 0.05)
var maximum_magnetism_distance: float = 1.5

@export_range(0.0, 50.0, 0.1)
var maximum_magnetism_speed: float = 8.0

@export_range(0.0, 100.0, 0.1)
var magnetism_deceleration: float = 30.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if acquisition_range <= 0.0:
		errors.append(
			"AttackTargetingDefinition.acquisition_range must be greater than zero."
		)

	if (
		angle_weight <= 0.0
		and distance_weight <= 0.0
	):
		errors.append(
			"AttackTargetingDefinition requires at least one scoring weight."
		)

	if stopping_distance < 0.0:
		errors.append(
			"AttackTargetingDefinition.stopping_distance cannot be negative."
		)

	if maximum_magnetism_distance < 0.0:
		errors.append(
			"AttackTargetingDefinition.maximum_magnetism_distance cannot be negative."
		)

	if maximum_magnetism_speed < 0.0:
		errors.append(
			"AttackTargetingDefinition.maximum_magnetism_speed cannot be negative."
		)

	if magnetism_deceleration < 0.0:
		errors.append(
			"AttackTargetingDefinition.magnetism_deceleration cannot be negative."
		)

	return errors
