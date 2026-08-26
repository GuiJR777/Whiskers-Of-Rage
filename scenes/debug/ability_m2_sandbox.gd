extends Node

@onready var source_asc: AbilitySystemComponent = $SourceASC
@onready var target_asc: AbilitySystemComponent = $TargetASC


func _ready() -> void:
	var stamina := _make_attribute(&"Stamina", 100.0)
	var health := _make_attribute(&"Health", 100.0)
	_initialize_asc(source_asc, [stamina])
	_initialize_asc(target_asc, [health])

	var damage := _make_instant_effect(&"Effect.Damage.SandboxAttack", health, -25.0)
	var cost := _make_instant_effect(&"Effect.Cost.SandboxAttack", stamina, -20.0)
	var cooldown := GameplayEffect.new()
	cooldown.effect_id = &"Effect.Cooldown.SandboxAttack"
	cooldown.duration_policy = GameplayEffect.DurationPolicy.DURATION
	cooldown.duration = 1.0
	cooldown.granted_tags = [_make_tag(&"Cooldown.Attack.Sandbox")]

	var wait_task := WaitSecondsAbilityTaskDefinition.new()
	wait_task.duration = 0.1
	var damage_task := ApplyEffectAbilityTaskDefinition.new()
	damage_task.effect = damage
	damage_task.target_policy = ApplyEffectAbilityTaskDefinition.TargetPolicy.CONTEXT_TARGET

	var attack := GameplayAbility.new()
	attack.ability_tag = _make_tag(&"Ability.Attack.Sandbox")
	attack.activation_owned_tags = [_make_tag(&"State.Attacking")]
	attack.cost_effect = cost
	attack.cooldown_effect = cooldown
	attack.tasks = [wait_task, damage_task]

	var ability_handle := source_asc.grant_ability(attack)
	var activated := source_asc.try_activate_ability(
		ability_handle,
		AbilityContext.create(source_asc, target_asc, self)
	)
	source_asc.advance_abilities(0.1)
	var spec := source_asc.get_ability_spec(ability_handle)
	print("ABILITY_M2_SANDBOX: activated=%s, stamina=%.1f, target_health=%.1f, state=%s, cooldown=%s" % [
		activated,
		source_asc.get_attribute_value(&"Stamina"),
		target_asc.get_attribute_value(&"Health"),
		AbilitySpec.State.find_key(spec.state),
		source_asc.has_tag_name(&"Cooldown.Attack.Sandbox"),
	])


func _initialize_asc(asc: AbilitySystemComponent, attributes: Array[GameplayAttribute]) -> void:
	var attribute_set := GameplayAttributeSet.new()
	attribute_set.attributes = attributes
	asc.initial_attribute_sets = [attribute_set]
	if not asc.initialize():
		push_error("Ability M2 sandbox failed to initialize an ASC.")


func _make_tag(tag_name: StringName) -> GameplayTag:
	var tag := GameplayTag.new()
	tag.tag_name = tag_name
	return tag


func _make_attribute(attribute_name: StringName, default_value: float) -> GameplayAttribute:
	var attribute := GameplayAttribute.new()
	attribute.attribute_name = attribute_name
	attribute.default_value = default_value
	attribute.minimum_value = 0.0
	attribute.maximum_value = default_value
	return attribute


func _make_instant_effect(
	effect_id: StringName,
	attribute: GameplayAttribute,
	magnitude: float
) -> GameplayEffect:
	var modifier := GameplayModifier.new()
	modifier.attribute = attribute
	modifier.operation = GameplayModifier.Operation.ADD
	modifier.magnitude = magnitude
	var effect := GameplayEffect.new()
	effect.effect_id = effect_id
	effect.duration_policy = GameplayEffect.DurationPolicy.INSTANT
	effect.modifiers = [modifier]
	return effect

