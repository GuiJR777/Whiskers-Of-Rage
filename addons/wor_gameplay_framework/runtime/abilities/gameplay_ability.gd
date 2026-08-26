@tool
class_name GameplayAbility
extends Resource

## Immutable, data-driven action definition granted to an ASC through an AbilitySpec.

enum CooldownCommitPolicy {
	ON_ACTIVATION,
	ON_END,
}

@export var ability_tag: GameplayTag
@export var activation_required_tags: Array[GameplayTag] = []
@export var activation_blocked_tags: Array[GameplayTag] = []
@export var activation_owned_tags: Array[GameplayTag] = []
@export var cancel_abilities_with_tags: Array[GameplayTag] = []
@export var can_be_cancelled: bool = true
@export var cost_effect: GameplayEffect
@export var cooldown_effect: GameplayEffect
@export var cooldown_commit_policy: CooldownCommitPolicy = CooldownCommitPolicy.ON_END
@export var apply_cooldown_on_cancel: bool = true
@export var tasks: Array[AbilityTaskDefinition] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if ability_tag == null or not ability_tag.is_valid():
		errors.append("GameplayAbility requires a valid ability_tag.")
	_validate_tags(activation_required_tags, "activation_required_tags", errors)
	_validate_tags(activation_blocked_tags, "activation_blocked_tags", errors)
	_validate_tags(activation_owned_tags, "activation_owned_tags", errors)
	_validate_tags(cancel_abilities_with_tags, "cancel_abilities_with_tags", errors)
	if cost_effect != null:
		for effect_error: String in cost_effect.validate():
			errors.append("Cost effect: %s" % effect_error)
		if cost_effect.duration_policy != GameplayEffect.DurationPolicy.INSTANT:
			errors.append("Cost effect must use the Instant duration policy.")
		if not cost_effect.granted_tags.is_empty():
			errors.append("Cost effect cannot grant persistent tags.")
		for modifier: GameplayModifier in cost_effect.modifiers:
			if modifier != null and (
				modifier.operation != GameplayModifier.Operation.ADD or modifier.magnitude > 0.0
			):
				errors.append("Cost modifiers must use ADD with a non-positive magnitude.")
	if cooldown_effect != null:
		for effect_error: String in cooldown_effect.validate():
			errors.append("Cooldown effect: %s" % effect_error)
		if cooldown_effect.duration_policy != GameplayEffect.DurationPolicy.DURATION:
			errors.append("Cooldown effect must use the Duration policy.")
	for index: int in tasks.size():
		var task_definition := tasks[index]
		if task_definition == null:
			errors.append("Task at index %d is null." % index)
			continue
		for task_error: String in task_definition.validate():
			errors.append("Task %d: %s" % [index, task_error])
	return errors


func _validate_tags(
	tags_to_validate: Array[GameplayTag],
	property_name: String,
	errors: PackedStringArray
) -> void:
	for index: int in tags_to_validate.size():
		var tag := tags_to_validate[index]
		if tag == null or not tag.is_valid():
			errors.append("%s contains an invalid tag at index %d." % [property_name, index])

