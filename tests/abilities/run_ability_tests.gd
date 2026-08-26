extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_required_blocked_tags_and_revoke()
	_test_attack_lifecycle_cost_cooldown_and_effect()
	_test_unaffordable_cost_does_not_commit()
	_test_gameplay_event_wait_and_signal_cleanup()
	_test_cancel_active_ability_by_tag()
	if _failures.is_empty():
		print("ABILITY_M2_TESTS: PASS")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	print("ABILITY_M2_TESTS: FAIL (%d)" % _failures.size())
	quit(1)


func _test_required_blocked_tags_and_revoke() -> void:
	var grounded := _make_tag(&"State.Grounded")
	var stunned := _make_tag(&"State.Stunned")
	var active_tag := _make_tag(&"State.TestAbilityActive")
	var ability := _make_ability(&"Ability.Test.TagRules")
	ability.activation_required_tags = [grounded]
	ability.activation_blocked_tags = [stunned]
	ability.activation_owned_tags = [active_tag]
	ability.tasks = [_make_wait_seconds(10.0)]
	var asc := _make_asc([])
	var handle := asc.grant_ability(ability)
	_check(handle != AbilitySystemComponent.INVALID_ABILITY_HANDLE, "A valid ability must be granted.")
	_check(
		asc.can_activate_ability(handle) == AbilitySystemComponent.ACTIVATION_FAILURE_REQUIRED_TAGS,
		"Activation must report missing required tags."
	)
	asc.tags.add_tag(grounded)
	asc.tags.add_tag(stunned)
	_check(
		asc.can_activate_ability(handle) == AbilitySystemComponent.ACTIVATION_FAILURE_BLOCKED_TAGS,
		"Activation must report present blocked tags."
	)
	asc.tags.remove_tag(stunned)
	_check(asc.try_activate_ability(handle), "Ability must activate after tag requirements are satisfied.")
	_check(asc.has_tag(active_tag), "Activation-owned tag must remain while the ability is active.")
	_check(asc.revoke_ability(handle), "Revoking a granted ability must succeed.")
	_check(not asc.has_tag(active_tag), "Revoking an active ability must clean activation-owned tags.")
	_check(asc.get_ability_spec(handle) == null, "Revoked ability handle must no longer resolve.")


func _test_attack_lifecycle_cost_cooldown_and_effect() -> void:
	var stamina := _make_attribute(&"Stamina", 100.0, 0.0, 100.0)
	var health := _make_attribute(&"Health", 100.0, 0.0, 100.0)
	var source := _make_asc([stamina])
	var target := _make_asc([health])
	var attacking := _make_tag(&"State.Attacking")
	var cooldown_tag := _make_tag(&"Cooldown.Attack.Light")
	var cost := _make_instant_effect(
		&"Effect.Cost.LightAttack",
		[_make_modifier(stamina, GameplayModifier.Operation.ADD, -20.0)]
	)
	var cooldown := _make_duration_effect(&"Effect.Cooldown.LightAttack", 2.0, [], [cooldown_tag])
	var damage := _make_instant_effect(
		&"Effect.Damage.DummyAttack",
		[_make_modifier(health, GameplayModifier.Operation.ADD, -25.0)]
	)
	var ability := _make_ability(&"Ability.Attack.Light.Dummy")
	ability.activation_owned_tags = [attacking]
	ability.cost_effect = cost
	ability.cooldown_effect = cooldown
	ability.cooldown_commit_policy = GameplayAbility.CooldownCommitPolicy.ON_END
	ability.tasks = [_make_wait_seconds(0.5), _make_apply_effect(damage)]
	var handle := source.grant_ability(ability)
	var context := AbilityContext.create(source, target)
	var ended_count: Array[int] = [0]
	source.ability_ended.connect(func(_handle: int, _ability: GameplayAbility) -> void: ended_count[0] += 1)
	_check(source.try_activate_ability(handle, context), "Dummy attack must activate.")
	_check_float(source.get_attribute_value(&"Stamina"), 80.0, "Cost must commit once on activation.")
	_check_float(target.get_attribute_value(&"Health"), 100.0, "Damage must wait for its preceding task.")
	_check(source.has_tag(attacking), "Attack must grant State.Attacking while active.")
	source.advance_abilities(0.5)
	_check_float(target.get_attribute_value(&"Health"), 75.0, "ApplyEffect task must damage the context target.")
	_check(not source.has_tag(attacking), "Normal end must remove activation-owned tags.")
	_check(ended_count[0] == 1, "Normal lifecycle must emit ability_ended exactly once.")
	_check(source.has_tag(cooldown_tag), "Cooldown effect must grant its tag after normal end.")
	_check(
		source.can_activate_ability(handle) == AbilitySystemComponent.ACTIVATION_FAILURE_COOLDOWN,
		"Ability must be blocked while its cooldown effect is active."
	)
	source.advance_effects(2.1)
	_check(source.can_activate_ability(handle) == &"", "Ability must reactivate after cooldown expiration.")
	_check(source.revoke_ability(handle), "Ability with expired cooldown must revoke cleanly.")


func _test_unaffordable_cost_does_not_commit() -> void:
	var stamina := _make_attribute(&"Stamina", 10.0, 0.0, 100.0)
	var asc := _make_asc([stamina])
	var cost := _make_instant_effect(
		&"Effect.Cost.TooExpensive",
		[_make_modifier(stamina, GameplayModifier.Operation.ADD, -20.0)]
	)
	var ability := _make_ability(&"Ability.Test.TooExpensive")
	ability.cost_effect = cost
	var handle := asc.grant_ability(ability)
	_check(not asc.try_activate_ability(handle), "Unaffordable ability must not activate.")
	_check_float(asc.get_attribute_value(&"Stamina"), 10.0, "Rejected activation must not commit cost.")
	_check(
		asc.can_activate_ability(handle) == AbilitySystemComponent.ACTIVATION_FAILURE_COST,
		"Rejected activation must expose the cost failure reason."
	)


func _test_gameplay_event_wait_and_signal_cleanup() -> void:
	var asc := _make_asc([])
	var awaited_tag := _make_tag(&"Combat.Hit")
	var child_event_tag := _make_tag(&"Combat.Hit.Confirmed")
	var ability := _make_ability(&"Ability.Test.WaitEvent")
	ability.tasks = [_make_wait_event(awaited_tag)]
	var handle := asc.grant_ability(ability)
	_check(asc.try_activate_ability(handle), "Wait-event ability must activate.")
	_check(
		asc.gameplay_event_received.get_connections().size() == 1,
		"WaitGameplayEvent must connect exactly one listener."
	)
	asc.send_gameplay_event(GameplayEvent.create(child_event_tag))
	_check(not asc.get_ability_spec(handle).is_active(), "Matching child event must complete the ability.")
	_check(
		asc.gameplay_event_received.get_connections().is_empty(),
		"Completed WaitGameplayEvent must disconnect its signal."
	)
	asc.try_activate_ability(handle)
	asc.cancel_ability(handle)
	_check(
		asc.gameplay_event_received.get_connections().is_empty(),
		"Cancelled WaitGameplayEvent must disconnect its signal."
	)


func _test_cancel_active_ability_by_tag() -> void:
	var asc := _make_asc([])
	var attacking := _make_tag(&"State.Attacking")
	var attack_query := _make_tag(&"Ability.Attack")
	var attack := _make_ability(&"Ability.Attack.Heavy")
	attack.activation_owned_tags = [attacking]
	attack.tasks = [_make_wait_seconds(10.0)]
	var dodge := _make_ability(&"Ability.Movement.Dodge")
	dodge.cancel_abilities_with_tags = [attack_query]
	dodge.tasks = [_make_wait_seconds(1.0)]
	var attack_handle := asc.grant_ability(attack)
	var dodge_handle := asc.grant_ability(dodge)
	asc.try_activate_ability(attack_handle)
	_check(asc.try_activate_ability(dodge_handle), "Dodge must activate and request attack cancellation.")
	_check(
		asc.get_ability_spec(attack_handle).state == AbilitySpec.State.CANCELLED,
		"Matching active attack must enter Cancelled state."
	)
	_check(not asc.has_tag(attacking), "Cancelled attack must clean its activation tag.")
	asc.cancel_ability(dodge_handle, true)


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


func _make_instant_effect(
	effect_id: StringName,
	modifiers: Array[GameplayModifier]
) -> GameplayEffect:
	var effect := GameplayEffect.new()
	effect.effect_id = effect_id
	effect.duration_policy = GameplayEffect.DurationPolicy.INSTANT
	effect.modifiers = modifiers
	return effect


func _make_duration_effect(
	effect_id: StringName,
	duration: float,
	modifiers: Array[GameplayModifier],
	granted_tags: Array[GameplayTag]
) -> GameplayEffect:
	var effect := GameplayEffect.new()
	effect.effect_id = effect_id
	effect.duration_policy = GameplayEffect.DurationPolicy.DURATION
	effect.duration = duration
	effect.modifiers = modifiers
	effect.granted_tags = granted_tags
	return effect


func _make_ability(tag_name: StringName) -> GameplayAbility:
	var ability := GameplayAbility.new()
	ability.ability_tag = _make_tag(tag_name)
	return ability


func _make_wait_seconds(duration: float) -> WaitSecondsAbilityTaskDefinition:
	var task := WaitSecondsAbilityTaskDefinition.new()
	task.duration = duration
	return task


func _make_wait_event(event_tag: GameplayTag) -> WaitGameplayEventAbilityTaskDefinition:
	var task := WaitGameplayEventAbilityTaskDefinition.new()
	task.event_tag = event_tag
	return task


func _make_apply_effect(effect: GameplayEffect) -> ApplyEffectAbilityTaskDefinition:
	var task := ApplyEffectAbilityTaskDefinition.new()
	task.effect = effect
	task.target_policy = ApplyEffectAbilityTaskDefinition.TargetPolicy.CONTEXT_TARGET
	return task


func _make_asc(attributes: Array[GameplayAttribute]) -> AbilitySystemComponent:
	var asc := AbilitySystemComponent.new()
	asc.initialize_on_ready = false
	if not attributes.is_empty():
		var attribute_set := GameplayAttributeSet.new()
		attribute_set.attributes = attributes
		asc.initial_attribute_sets = [attribute_set]
	_check(asc.initialize(), "ASC initialization must succeed for valid definitions.")
	return asc


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _check_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures.append("%s Expected %.3f, got %.3f." % [message, expected, actual])
