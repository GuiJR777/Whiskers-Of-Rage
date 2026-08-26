class_name ApplyEffectAbilityTask
extends AbilityTask


func _activate() -> void:
	var apply_definition := definition as ApplyEffectAbilityTaskDefinition
	var target: AbilitySystemComponent
	match apply_definition.target_policy:
		ApplyEffectAbilityTaskDefinition.TargetPolicy.OWNER:
			target = owner_spec.owner_asc
		ApplyEffectAbilityTaskDefinition.TargetPolicy.CONTEXT_TARGET:
			target = context.target_asc
		ApplyEffectAbilityTaskDefinition.TargetPolicy.CONTEXT_SOURCE:
			target = context.source_asc
	if target == null:
		_fail("ApplyEffect could not resolve a target ASC from its target policy.")
		return
	var effect_context := context.duplicate_context()
	effect_context.target_asc = target
	var handle := target.apply_gameplay_effect(apply_definition.effect, effect_context)
	_complete(handle)

