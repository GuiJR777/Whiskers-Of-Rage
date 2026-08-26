extends Node

@onready var source_asc: AbilitySystemComponent = $SourceASC
@onready var target_asc: AbilitySystemComponent = $TargetASC


func _ready() -> void:
	var stamina := _make_attribute(&"Stamina", 100.0)
	var health := _make_attribute(&"Health", 100.0)
	_initialize_asc(source_asc, [stamina])
	_initialize_asc(target_asc, [health])

	var burning := _make_tag(&"Status.Burning")
	var damage_over_time := GameplayEffect.new()
	damage_over_time.effect_id = &"Effect.Status.Burning.Debug"
	damage_over_time.duration_policy = GameplayEffect.DurationPolicy.PERIODIC
	damage_over_time.duration = 300.0
	damage_over_time.period = 5.0
	damage_over_time.granted_tags = [burning]
	damage_over_time.modifiers = [_make_modifier(health, -2.0)]
	target_asc.apply_gameplay_effect(
		damage_over_time,
		AbilityContext.create(source_asc, target_asc, self)
	)

	var wait_task := WaitSecondsAbilityTaskDefinition.new()
	wait_task.duration = 300.0
	var ability := GameplayAbility.new()
	ability.ability_tag = _make_tag(&"Ability.Debug.Channel")
	ability.activation_owned_tags = [_make_tag(&"State.Debugging")]
	ability.tasks = [wait_task]
	var ability_handle := source_asc.grant_ability(ability)
	source_asc.try_activate_ability(
		ability_handle,
		AbilityContext.create(source_asc, target_asc, self)
	)
	source_asc.send_gameplay_event(GameplayEvent.create(
		_make_tag(&"Debug.Event.SandboxReady"),
		AbilityContext.create(source_asc, target_asc, self),
		{"milestone": "M3"}
	))

	var source_snapshot := source_asc.get_debug_snapshot()
	var target_snapshot := target_asc.get_debug_snapshot()
	print("EDITOR_TOOLS_M3_SANDBOX: source_abilities=%d, source_events=%d, target_effects=%d, target_tags=%d" % [
		(source_snapshot.abilities as Array).size(),
		(source_snapshot.recent_events as Array).size(),
		(target_snapshot.active_effects as Array).size(),
		(target_snapshot.tags as Array).size(),
	])


func _initialize_asc(asc: AbilitySystemComponent, attributes: Array[GameplayAttribute]) -> void:
	var attribute_set := GameplayAttributeSet.new()
	attribute_set.attributes = attributes
	asc.initial_attribute_sets = [attribute_set]
	if not asc.initialize():
		push_error("M3 sandbox failed to initialize an ASC.")


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


func _make_modifier(attribute: GameplayAttribute, magnitude: float) -> GameplayModifier:
	var modifier := GameplayModifier.new()
	modifier.attribute = attribute
	modifier.operation = GameplayModifier.Operation.ADD
	modifier.magnitude = magnitude
	return modifier
