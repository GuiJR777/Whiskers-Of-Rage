class_name HitReactionDefinition
extends Resource


@export_category("Knockback")

@export_range(0.0, 50.0, 0.1)
var horizontal_speed: float = 0.0

@export_range(0.0, 50.0, 0.1)
var upward_speed: float = 0.0

@export_range(0.0, 100.0, 0.1)
var horizontal_deceleration: float = 20.0


@export_category("Knockdown")

@export
var causes_knockdown: bool = false

@export
var knockdown_effect: GameplayEffect


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if horizontal_speed < 0.0:
		errors.append(
			"HitReactionDefinition.horizontal_speed cannot be negative."
		)

	if upward_speed < 0.0:
		errors.append(
			"HitReactionDefinition.upward_speed cannot be negative."
		)

	if horizontal_deceleration < 0.0:
		errors.append(
			"HitReactionDefinition.horizontal_deceleration cannot be negative."
		)

	if causes_knockdown:
		if knockdown_effect == null:
			errors.append(
				"HitReactionDefinition with knockdown requires a knockdown_effect."
			)
		else:
			for effect_error: String in (
				knockdown_effect.validate()
			):
				errors.append(
					"Knockdown Effect: %s"
					% effect_error
				)

	return errors
