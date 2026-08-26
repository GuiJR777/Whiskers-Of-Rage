@tool
class_name ApplyEffectAbilityTaskDefinition
extends AbilityTaskDefinition

enum TargetPolicy {
	OWNER,
	CONTEXT_TARGET,
	CONTEXT_SOURCE,
}

@export var effect: GameplayEffect
@export var target_policy: TargetPolicy = TargetPolicy.CONTEXT_TARGET


func create_task(owner_spec: AbilitySpec, context: AbilityContext) -> AbilityTask:
	var task := ApplyEffectAbilityTask.new()
	task.setup(owner_spec, context, self)
	return task


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if effect == null:
		errors.append("ApplyEffect requires a GameplayEffect.")
		return errors
	for effect_error: String in effect.validate():
		errors.append("ApplyEffect: %s" % effect_error)
	return errors

