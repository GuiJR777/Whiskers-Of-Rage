extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_hierarchical_tags_and_reference_counts()
	_test_attributes_and_instant_effect_between_two_ascs()
	_test_attribute_aggregation_order_and_clamping()
	_test_duration_cleanup()
	_test_infinite_effect_stacking()
	_test_periodic_effect()
	if _failures.is_empty():
		print("GAS_CORE_TESTS: PASS")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("GAS_CORE_TESTS: FAIL (%d)" % _failures.size())
	quit(1)


func _test_hierarchical_tags_and_reference_counts() -> void:
	var container := GameplayTagContainer.new()
	_check(container.add_tag_name(&"State.Stunned.Heavy"), "A valid tag should be added.")
	_check(container.has_tag_name(&"State.Stunned"), "Child tags must match their parent query.")
	_check(not container.has_tag_name(&"State.Stunned", true), "Exact matching must not match a parent.")
	container.add_tag_name(&"State.Stunned.Heavy")
	container.remove_tag_name(&"State.Stunned.Heavy")
	_check(container.has_tag_name(&"State.Stunned.Heavy", true), "Reference count must preserve shared grants.")
	container.remove_tag_name(&"State.Stunned.Heavy")
	_check(not container.has_tag_name(&"State.Stunned"), "The final removal must clear the tag.")


func _test_attributes_and_instant_effect_between_two_ascs() -> void:
	var health := _make_attribute(&"Health", 100.0, 0.0, 100.0)
	var attribute_set := _make_attribute_set([health])
	var source := _make_asc(attribute_set)
	var target := _make_asc(attribute_set)
	var damage := _make_effect(
		&"Effect.Damage.Test",
		GameplayEffect.DurationPolicy.INSTANT,
		[_make_modifier(health, GameplayModifier.Operation.ADD, -25.0)]
	)
	var context := AbilityContext.create(source, target)
	var handle := target.apply_gameplay_effect(damage, context)
	_check(handle == AbilitySystemComponent.INVALID_EFFECT_HANDLE, "Instant effects must not create active handles.")
	_check_float(target.get_attribute_value(&"Health"), 75.0, "Instant damage must change the target ASC.")
	_check_float(source.get_attribute_value(&"Health"), 100.0, "The source ASC must retain independent runtime state.")
	_check_float(health.default_value, 100.0, "Applying an effect must not mutate the Attribute Resource.")


func _test_duration_cleanup() -> void:
	var attack_power := _make_attribute(&"AttackPower", 10.0, 0.0, 999.0)
	var target := _make_asc(_make_attribute_set([attack_power]))
	var buff_tag := _make_tag(&"Status.PowerBuff")
	var buff := _make_effect(
		&"Effect.Buff.Power",
		GameplayEffect.DurationPolicy.DURATION,
		[_make_modifier(attack_power, GameplayModifier.Operation.ADD, 5.0)],
		[buff_tag]
	)
	buff.duration = 2.0
	var handle := target.apply_gameplay_effect(buff)
	_check(handle != AbilitySystemComponent.INVALID_EFFECT_HANDLE, "Duration effects must return a removable handle.")
	_check_float(target.get_attribute_value(&"AttackPower"), 15.0, "Duration modifier must be active immediately.")
	_check(target.has_tag(buff_tag), "Duration effect must grant its configured tag.")
	target.advance_effects(2.1)
	_check_float(target.get_attribute_value(&"AttackPower"), 10.0, "Expired duration modifier must be cleaned up.")
	_check(not target.has_tag(buff_tag), "Expired duration tag must be cleaned up.")
	_check(target.get_active_effect(handle) == null, "Expired effect handle must no longer resolve.")


func _test_attribute_aggregation_order_and_clamping() -> void:
	var speed := _make_attribute(&"MoveSpeed", 10.0, 0.0, 25.0)
	var target := _make_asc(_make_attribute_set([speed]))
	var additive := _make_effect(
		&"Effect.Speed.Add",
		GameplayEffect.DurationPolicy.INFINITE,
		[_make_modifier(speed, GameplayModifier.Operation.ADD, 5.0)]
	)
	var multiplier := _make_effect(
		&"Effect.Speed.Multiply",
		GameplayEffect.DurationPolicy.INFINITE,
		[_make_modifier(speed, GameplayModifier.Operation.MULTIPLY, 2.0)]
	)
	var override := _make_effect(
		&"Effect.Speed.Override",
		GameplayEffect.DurationPolicy.INFINITE,
		[_make_modifier(speed, GameplayModifier.Operation.OVERRIDE, 7.0)]
	)
	var additive_handle := target.apply_gameplay_effect(additive)
	var multiplier_handle := target.apply_gameplay_effect(multiplier)
	_check_float(target.get_attribute_value(&"MoveSpeed"), 25.0, "Add then multiply must respect the attribute maximum.")
	var override_handle := target.apply_gameplay_effect(override)
	_check_float(target.get_attribute_value(&"MoveSpeed"), 7.0, "Override must run after additive and multiplicative aggregation.")
	target.remove_active_effect(override_handle)
	_check_float(target.get_attribute_value(&"MoveSpeed"), 25.0, "Removing override must restore the aggregated value.")
	target.remove_active_effect(multiplier_handle)
	_check_float(target.get_attribute_value(&"MoveSpeed"), 15.0, "Removing multiplier must keep the additive modifier.")
	target.remove_active_effect(additive_handle)
	_check_float(target.get_attribute_value(&"MoveSpeed"), 10.0, "Removing all effects must restore the base value.")


func _test_infinite_effect_stacking() -> void:
	var defense := _make_attribute(&"Defense", 4.0, 0.0, 999.0)
	var target := _make_asc(_make_attribute_set([defense]))
	var armor := _make_effect(
		&"Effect.Equipment.Armor",
		GameplayEffect.DurationPolicy.INFINITE,
		[_make_modifier(defense, GameplayModifier.Operation.ADD, 2.0)]
	)
	armor.stacking_policy = GameplayEffect.StackingPolicy.AGGREGATE_BY_TARGET
	armor.maximum_stacks = 3
	var first_handle := target.apply_gameplay_effect(armor)
	var second_handle := target.apply_gameplay_effect(armor)
	target.apply_gameplay_effect(armor)
	target.apply_gameplay_effect(armor)
	_check(first_handle == second_handle, "Aggregated stacks must reuse the active effect handle.")
	_check(target.get_active_effect(first_handle).stack_count == 3, "Stacks must stop at maximum_stacks.")
	_check_float(target.get_attribute_value(&"Defense"), 10.0, "Stack count must scale persistent additive modifiers.")
	target.remove_active_effect(first_handle)
	_check_float(target.get_attribute_value(&"Defense"), 4.0, "Removing the handle must clean every aggregated stack.")


func _test_periodic_effect() -> void:
	var health := _make_attribute(&"Health", 50.0, 0.0, 50.0)
	var target := _make_asc(_make_attribute_set([health]))
	var poison := _make_effect(
		&"Effect.Debuff.Poison",
		GameplayEffect.DurationPolicy.PERIODIC,
		[_make_modifier(health, GameplayModifier.Operation.ADD, -5.0)]
	)
	poison.duration = 3.1
	poison.period = 1.0
	var handle := target.apply_gameplay_effect(poison)
	target.advance_effects(1.0)
	_check_float(target.get_attribute_value(&"Health"), 45.0, "Periodic effect must execute on its first period.")
	target.advance_effects(2.1)
	_check_float(target.get_attribute_value(&"Health"), 35.0, "Periodic effect must catch up deterministic elapsed periods.")
	_check(target.get_active_effect(handle) == null, "Periodic effect must expire after its duration.")


func _make_tag(tag_name: StringName) -> GameplayTag:
	var tag := GameplayTag.new()
	tag.tag_name = tag_name
	return tag


func _make_attribute(
	attribute_name: StringName,
	default_value: float,
	minimum_value: float,
	maximum_value: float
) -> GameplayAttribute:
	var attribute := GameplayAttribute.new()
	attribute.attribute_name = attribute_name
	attribute.default_value = default_value
	attribute.minimum_value = minimum_value
	attribute.maximum_value = maximum_value
	return attribute


func _make_attribute_set(attributes: Array[GameplayAttribute]) -> GameplayAttributeSet:
	var attribute_set := GameplayAttributeSet.new()
	attribute_set.attributes = attributes
	return attribute_set


func _make_modifier(
	attribute: GameplayAttribute,
	operation: GameplayModifier.Operation,
	magnitude: float
) -> GameplayModifier:
	var modifier := GameplayModifier.new()
	modifier.attribute = attribute
	modifier.operation = operation
	modifier.magnitude = magnitude
	return modifier


func _make_effect(
	effect_id: StringName,
	duration_policy: GameplayEffect.DurationPolicy,
	modifiers: Array[GameplayModifier],
	granted_tags: Array[GameplayTag] = []
) -> GameplayEffect:
	var effect := GameplayEffect.new()
	effect.effect_id = effect_id
	effect.duration_policy = duration_policy
	effect.modifiers = modifiers
	effect.granted_tags = granted_tags
	return effect


func _make_asc(attribute_set: GameplayAttributeSet) -> AbilitySystemComponent:
	var asc := AbilitySystemComponent.new()
	asc.initialize_on_ready = false
	asc.initial_attribute_sets = [attribute_set]
	_check(asc.initialize(), "ASC initialization must succeed for valid definitions.")
	return asc


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _check_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures.append("%s Expected %.3f, got %.3f." % [message, expected, actual])
