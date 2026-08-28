class_name CombatAnimationBinding
extends Resource


@export_category("Ability")

@export
var ability_tag: GameplayTag


@export_category("Animation")

@export
var animation_name: StringName = &""

@export_range(0.0, 0.5, 0.01)
var transition_blend_time: float = 0.05


@export_category("Combat")

@export
var hitbox_id: StringName = &""

@export
var attack_definition: MeleeAttackDefinition


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if (
		ability_tag == null
		or not ability_tag.is_valid()
	):
		errors.append(
			"CombatAnimationBinding requires a valid ability_tag."
		)

	if animation_name == &"":
		errors.append(
			"CombatAnimationBinding requires an animation_name."
		)

	if hitbox_id == &"":
		errors.append(
			"CombatAnimationBinding requires a hitbox_id."
		)

	if attack_definition == null:
		errors.append(
			"CombatAnimationBinding requires an attack_definition."
		)
	else:
		for attack_error: String in (
			attack_definition.validate()
		):
			errors.append(
				"Attack: %s"
				% attack_error
			)

	return errors
