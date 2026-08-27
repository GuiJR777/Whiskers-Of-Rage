class_name MeleeAttackDefinition
extends Resource


@export_category("Identity")

@export
var attack_id: StringName = &""


@export_category("Input")

@export_range(0.0, 0.5, 0.01)
var input_buffer_time: float = 0.15


@export_category("Gameplay")

@export
var hit_effect: GameplayEffect


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if attack_id == &"":
		errors.append(
			"MeleeAttackDefinition.attack_id cannot be empty."
		)

	if hit_effect == null:
		errors.append(
			"MeleeAttackDefinition.hit_effect cannot be null."
		)
	else:
		for effect_error: String in hit_effect.validate():
			errors.append(
				"Hit Effect: %s"
				% effect_error
			)

	return errors
