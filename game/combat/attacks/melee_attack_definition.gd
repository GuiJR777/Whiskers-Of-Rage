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

@export
var hit_reaction: HitReactionDefinition


@export_category("Attack Motion")

@export
var attack_motions: Array[AttackMotionDefinition] = []

@export_category("Targeting")

@export
var targeting: AttackTargetingDefinition


func get_attack_motion(
	motion_id: StringName
) -> AttackMotionDefinition:
	for motion: AttackMotionDefinition in attack_motions:
		if motion == null:
			continue

		if motion.motion_id == motion_id:
			return motion

	return null


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
		for effect_error: String in (
			hit_effect.validate()
		):
			errors.append(
				"Hit Effect: %s"
				% effect_error
			)
	
	if targeting != null:
		for targeting_error: String in (
			targeting.validate()
		):
			errors.append(
				"Targeting: %s"
				% targeting_error
			)

	if hit_reaction != null:
		for reaction_error: String in (
			hit_reaction.validate()
		):
			errors.append(
				"Hit Reaction: %s"
				% reaction_error
			)

	var motion_ids: Dictionary = {}

	for index: int in attack_motions.size():
		var motion := attack_motions[index]

		if motion == null:
			errors.append(
				"Attack Motion %d is null."
				% index
			)
			continue

		for motion_error: String in (
			motion.validate()
		):
			errors.append(
				"Attack Motion %d: %s"
				% [
					index,
					motion_error,
				]
			)

		if motion_ids.has(
			motion.motion_id
		):
			errors.append(
				"Duplicate Attack Motion id '%s'."
				% String(
					motion.motion_id
				)
			)

		motion_ids[
			motion.motion_id
		] = true

	return errors
