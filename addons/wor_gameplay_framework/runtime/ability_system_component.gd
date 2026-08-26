class_name AbilitySystemComponent
extends Node

## Owns runtime tags, attribute values, and active gameplay effects for one actor.

const INVALID_EFFECT_HANDLE: int = 0
const INVALID_ABILITY_HANDLE: int = 0
const DEBUG_GROUP: StringName = &"wor_gas_ability_system_components"
const DEBUG_HISTORY_LIMIT: int = 10
const ACTIVATION_FAILURE_NOT_GRANTED: StringName = &"Ability.NotGranted"
const ACTIVATION_FAILURE_ALREADY_ACTIVE: StringName = &"Ability.AlreadyActive"
const ACTIVATION_FAILURE_REQUIRED_TAGS: StringName = &"Ability.RequiredTagsMissing"
const ACTIVATION_FAILURE_BLOCKED_TAGS: StringName = &"Ability.BlockedTagsPresent"
const ACTIVATION_FAILURE_COST: StringName = &"Ability.CostUnaffordable"
const ACTIVATION_FAILURE_COOLDOWN: StringName = &"Ability.CooldownActive"

signal attribute_changed(attribute_name: StringName, old_value: float, new_value: float)
signal tag_changed(tag_name: StringName, is_present: bool)
signal gameplay_effect_applied(handle: int, effect: GameplayEffect, stack_count: int)
signal gameplay_effect_removed(handle: int, effect: GameplayEffect)
signal gameplay_effect_stack_changed(handle: int, old_stacks: int, new_stacks: int)
signal ability_granted(handle: int, ability: GameplayAbility)
signal ability_revoked(handle: int, ability: GameplayAbility)
signal ability_activated(handle: int, ability: GameplayAbility, context: AbilityContext)
signal ability_ended(handle: int, ability: GameplayAbility)
signal ability_cancelled(handle: int, ability: GameplayAbility)
signal ability_activation_failed(handle: int, reason: StringName)
signal ability_task_started(handle: int, task: AbilityTask)
signal gameplay_event_received(event: GameplayEvent)

@export var initial_attribute_sets: Array[GameplayAttributeSet] = []
@export var initial_tags: Array[GameplayTag] = []
@export var initial_abilities: Array[GameplayAbility] = []
@export var initialize_on_ready: bool = true

var tags: GameplayTagContainer = GameplayTagContainer.new()

var _attribute_definitions: Dictionary = {}
var _base_attribute_values: Dictionary = {}
var _current_attribute_values: Dictionary = {}
var _active_effects: Dictionary = {}
var _next_effect_handle: int = 1
var _ability_specs: Dictionary = {}
var _next_ability_handle: int = 1
var _initialized: bool = false
var _debug_event_history: Array[Dictionary] = []
var _debug_lifecycle_warnings: Array[String] = []


func _init() -> void:
	tags.tag_added.connect(_on_tag_added)
	tags.tag_removed.connect(_on_tag_removed)


func _enter_tree() -> void:
	add_to_group(DEBUG_GROUP)


func _ready() -> void:
	if initialize_on_ready:
		initialize()


func _process(delta: float) -> void:
	advance_effects(delta)
	advance_abilities(delta)


func initialize() -> bool:
	if _initialized:
		return true
	for attribute_set: GameplayAttributeSet in initial_attribute_sets:
		if attribute_set == null:
			push_error("AbilitySystemComponent has a null initial AttributeSet.")
			return false
		var validation_errors := attribute_set.validate()
		if not validation_errors.is_empty():
			push_error("Invalid AttributeSet on AbilitySystemComponent: %s" % "; ".join(validation_errors))
			return false
		for attribute: GameplayAttribute in attribute_set.attributes:
			if not register_attribute(attribute):
				return false
	for tag: GameplayTag in initial_tags:
		if not tags.add_tag(tag):
			return false
	_initialized = true
	for ability: GameplayAbility in initial_abilities:
		if grant_ability(ability) == INVALID_ABILITY_HANDLE:
			return false
	_update_processing_state()
	return true


func register_attribute(attribute: GameplayAttribute) -> bool:
	if attribute == null:
		push_error("AbilitySystemComponent.register_attribute received null.")
		return false
	var validation_errors := attribute.validate()
	if not validation_errors.is_empty():
		push_error("Cannot register invalid attribute: %s" % "; ".join(validation_errors))
		return false
	if _attribute_definitions.has(attribute.attribute_name):
		push_error("Attribute '%s' is already registered on this ASC." % String(attribute.attribute_name))
		return false
	_attribute_definitions[attribute.attribute_name] = attribute
	var initial_value := attribute.clamp_value(attribute.default_value)
	_base_attribute_values[attribute.attribute_name] = initial_value
	_current_attribute_values[attribute.attribute_name] = initial_value
	return true


func has_attribute(attribute_name: StringName) -> bool:
	return _attribute_definitions.has(attribute_name)


func get_attribute_value(attribute_name: StringName, fallback: float = NAN) -> float:
	return _current_attribute_values.get(attribute_name, fallback)


func get_base_attribute_value(attribute_name: StringName, fallback: float = NAN) -> float:
	return _base_attribute_values.get(attribute_name, fallback)


func set_base_attribute_value(attribute_name: StringName, value: float) -> bool:
	var definition: GameplayAttribute = _attribute_definitions.get(attribute_name)
	if definition == null:
		push_error("Cannot set unknown attribute '%s'." % String(attribute_name))
		return false
	_base_attribute_values[attribute_name] = definition.clamp_value(value)
	_recalculate_current_attributes()
	return true


func has_tag(tag: GameplayTag, exact_match: bool = false) -> bool:
	return tags.has_tag(tag, exact_match)


func has_tag_name(tag_name: StringName, exact_match: bool = false) -> bool:
	return tags.has_tag_name(tag_name, exact_match)


func grant_ability(ability: GameplayAbility) -> int:
	if not _ensure_initialized():
		return INVALID_ABILITY_HANDLE
	if ability == null:
		push_error("AbilitySystemComponent.grant_ability received null.")
		return INVALID_ABILITY_HANDLE
	var validation_errors := ability.validate()
	if not validation_errors.is_empty():
		push_error("Cannot grant invalid GameplayAbility: %s" % "; ".join(validation_errors))
		return INVALID_ABILITY_HANDLE
	var handle := _next_ability_handle
	_next_ability_handle += 1
	var spec := AbilitySpec.new()
	spec.setup(handle, ability, self)
	spec.task_started.connect(_on_ability_task_started.bind(handle))
	spec.lifecycle_warning.connect(_on_ability_lifecycle_warning.bind(handle))
	_ability_specs[handle] = spec
	ability_granted.emit(handle, ability)
	return handle


func revoke_ability(handle: int) -> bool:
	var spec: AbilitySpec = _ability_specs.get(handle)
	if spec == null:
		return false
	if spec.is_active():
		spec.cancel(true)
	if spec.cooldown_handle != INVALID_EFFECT_HANDLE:
		remove_active_effect(spec.cooldown_handle)
		spec.cooldown_handle = INVALID_EFFECT_HANDLE
	_ability_specs.erase(handle)
	ability_revoked.emit(handle, spec.definition)
	_update_processing_state()
	return true


func get_ability_spec(handle: int) -> AbilitySpec:
	return _ability_specs.get(handle)


func get_ability_handles() -> Array[int]:
	var handles: Array[int] = []
	for handle_variant: Variant in _ability_specs.keys():
		handles.append(handle_variant as int)
	handles.sort()
	return handles


func get_active_ability_handles() -> Array[int]:
	var handles: Array[int] = []
	for handle: int in get_ability_handles():
		var spec: AbilitySpec = _ability_specs[handle]
		if spec.is_active():
			handles.append(handle)
	return handles


func can_activate_ability(handle: int) -> StringName:
	var spec: AbilitySpec = _ability_specs.get(handle)
	if spec == null:
		return ACTIVATION_FAILURE_NOT_GRANTED
	if spec.is_active():
		return ACTIVATION_FAILURE_ALREADY_ACTIVE
	var ability := spec.definition
	if not tags.has_all(ability.activation_required_tags):
		return ACTIVATION_FAILURE_REQUIRED_TAGS
	if tags.has_any(ability.activation_blocked_tags):
		return ACTIVATION_FAILURE_BLOCKED_TAGS
	if _is_ability_on_cooldown(spec):
		return ACTIVATION_FAILURE_COOLDOWN
	if not _can_afford_cost(ability.cost_effect):
		return ACTIVATION_FAILURE_COST
	return &""


func try_activate_ability(
	handle: int,
	activation_context: AbilityContext = null
) -> bool:
	if not _ensure_initialized():
		return false
	var failure_reason := can_activate_ability(handle)
	if failure_reason != &"":
		_record_debug_warning("Ability %d activation failed: %s" % [handle, String(failure_reason)])
		ability_activation_failed.emit(handle, failure_reason)
		return false
	var spec: AbilitySpec = _ability_specs[handle]
	var ability := spec.definition
	var context := activation_context.duplicate_context() \
		if activation_context != null else AbilityContext.new()
	if context.source_asc == null:
		context.source_asc = self
	context.ability = ability
	spec.state = AbilitySpec.State.ACTIVATING
	_cancel_abilities_matching_tags(ability.cancel_abilities_with_tags, handle)
	if ability.cost_effect != null:
		var cost_context := context.duplicate_context()
		cost_context.target_asc = self
		apply_gameplay_effect(ability.cost_effect, cost_context)
	for activation_tag: GameplayTag in ability.activation_owned_tags:
		tags.add_tag(activation_tag)
	if ability.cooldown_commit_policy == GameplayAbility.CooldownCommitPolicy.ON_ACTIVATION:
		_commit_ability_cooldown(spec, context)
	ability_activated.emit(handle, ability, context)
	spec.begin_activation(context)
	_update_processing_state()
	return true


func cancel_ability(handle: int, force: bool = false) -> bool:
	var spec: AbilitySpec = _ability_specs.get(handle)
	if spec == null:
		return false
	return spec.cancel(force)


func send_gameplay_event(event: GameplayEvent) -> bool:
	if event == null or not event.is_valid():
		push_error("AbilitySystemComponent.send_gameplay_event requires a valid event and tag.")
		return false
	if event.context == null:
		event.context = AbilityContext.create(null, self)
	elif event.context.target_asc == null:
		event.context.target_asc = self
	_record_debug_event(event)
	gameplay_event_received.emit(event)
	return true


func get_debug_snapshot() -> Dictionary:
	var attribute_rows: Array[Dictionary] = []
	var attribute_names: Array[StringName] = []
	for attribute_variant: Variant in _attribute_definitions.keys():
		attribute_names.append(attribute_variant as StringName)
	attribute_names.sort()
	for attribute_name: StringName in attribute_names:
		attribute_rows.append({
			"name": String(attribute_name),
			"base": float(_base_attribute_values[attribute_name]),
			"current": float(_current_attribute_values[attribute_name]),
		})

	var tag_rows: Array[Dictionary] = []
	for tag_name: StringName in tags.get_owned_tag_names():
		tag_rows.append({"name": String(tag_name), "count": tags.get_tag_count(tag_name)})

	var ability_rows: Array[Dictionary] = []
	var cooldown_rows: Array[Dictionary] = []
	for handle: int in get_ability_handles():
		var spec: AbilitySpec = _ability_specs[handle]
		var cooldown_remaining := 0.0
		if spec.cooldown_handle != INVALID_EFFECT_HANDLE:
			var cooldown := get_active_effect(spec.cooldown_handle)
			if cooldown != null:
				cooldown_remaining = cooldown.remaining_duration
				cooldown_rows.append({
					"ability": String(spec.definition.ability_tag.tag_name),
					"remaining": cooldown_remaining,
				})
		ability_rows.append({
			"handle": handle,
			"tag": String(spec.definition.ability_tag.tag_name),
			"state": String(AbilitySpec.State.find_key(spec.state)),
			"cooldown_remaining": cooldown_remaining,
		})

	var effect_rows: Array[Dictionary] = []
	for handle: int in get_active_effect_handles():
		var active_effect: ActiveGameplayEffect = _active_effects[handle]
		effect_rows.append({
			"handle": handle,
			"id": String(active_effect.definition.effect_id),
			"remaining": active_effect.remaining_duration,
			"stacks": active_effect.stack_count,
		})

	return {
		"instance_id": get_instance_id(),
		"path": String(get_path()) if is_inside_tree() else "<detached:%d>" % get_instance_id(),
		"attributes": attribute_rows,
		"tags": tag_rows,
		"abilities": ability_rows,
		"cooldowns": cooldown_rows,
		"active_effects": effect_rows,
		"recent_events": _debug_event_history.duplicate(true),
		"lifecycle_warnings": _debug_lifecycle_warnings.duplicate(),
	}


func advance_abilities(delta: float) -> void:
	if delta <= 0.0:
		return
	for handle: int in get_active_ability_handles():
		var spec: AbilitySpec = _ability_specs.get(handle)
		if spec != null:
			spec.advance(delta)


func _finish_ability_spec(spec: AbilitySpec, cancelled_activation: bool) -> void:
	if spec == null or not spec.is_active():
		return
	spec.state = AbilitySpec.State.ENDING
	var ability := spec.definition
	var ending_context := spec.context
	for activation_tag: GameplayTag in ability.activation_owned_tags:
		tags.remove_tag(activation_tag)
	if ability.cooldown_commit_policy == GameplayAbility.CooldownCommitPolicy.ON_END:
		if not cancelled_activation or ability.apply_cooldown_on_cancel:
			_commit_ability_cooldown(spec, ending_context)
	spec.finalize(cancelled_activation)
	if cancelled_activation:
		ability_cancelled.emit(spec.handle, ability)
	else:
		ability_ended.emit(spec.handle, ability)
	_update_processing_state()


func apply_gameplay_effect(
	effect: GameplayEffect,
	effect_context: AbilityContext = null
) -> int:
	if not _ensure_initialized():
		return INVALID_EFFECT_HANDLE
	if effect == null:
		push_error("AbilitySystemComponent.apply_gameplay_effect received null.")
		return INVALID_EFFECT_HANDLE
	var validation_errors := effect.validate()
	if not validation_errors.is_empty():
		push_error("Cannot apply invalid GameplayEffect: %s" % "; ".join(validation_errors))
		return INVALID_EFFECT_HANDLE
	var context := effect_context if effect_context != null else AbilityContext.new()
	if context.target_asc == null:
		context.target_asc = self
	if effect.duration_policy == GameplayEffect.DurationPolicy.INSTANT:
		_apply_modifiers_to_base(effect.modifiers, 1)
		gameplay_effect_applied.emit(INVALID_EFFECT_HANDLE, effect, 1)
		return INVALID_EFFECT_HANDLE

	var existing := _find_stackable_effect(effect, context)
	if existing != null:
		var previous_stacks: int = existing.stack_count
		existing.stack_count = mini(existing.stack_count + 1, effect.maximum_stacks)
		if effect.refresh_duration_on_reapplication and existing.is_timed():
			existing.refresh_duration()
		if previous_stacks != existing.stack_count:
			gameplay_effect_stack_changed.emit(existing.handle, previous_stacks, existing.stack_count)
			if effect.duration_policy != GameplayEffect.DurationPolicy.PERIODIC:
				_recalculate_current_attributes()
		gameplay_effect_applied.emit(existing.handle, effect, existing.stack_count)
		return existing.handle

	var handle := _next_effect_handle
	_next_effect_handle += 1
	var active_effect := ActiveGameplayEffect.new()
	active_effect.initialize(handle, effect, context.duplicate_context())
	_active_effects[handle] = active_effect
	for granted_tag: GameplayTag in effect.granted_tags:
		tags.add_tag(granted_tag)
	if effect.duration_policy == GameplayEffect.DurationPolicy.PERIODIC:
		if effect.execute_period_on_application:
			_apply_modifiers_to_base(effect.modifiers, active_effect.stack_count)
	else:
		_recalculate_current_attributes()
	gameplay_effect_applied.emit(handle, effect, active_effect.stack_count)
	_update_processing_state()
	return handle


func remove_active_effect(handle: int) -> bool:
	var active_effect: ActiveGameplayEffect = _active_effects.get(handle)
	if active_effect == null:
		return false
	_active_effects.erase(handle)
	for granted_tag: GameplayTag in active_effect.definition.granted_tags:
		tags.remove_tag(granted_tag)
	if active_effect.definition.duration_policy != GameplayEffect.DurationPolicy.PERIODIC:
		_recalculate_current_attributes()
	gameplay_effect_removed.emit(handle, active_effect.definition)
	_update_processing_state()
	return true


func get_active_effect(handle: int) -> ActiveGameplayEffect:
	return _active_effects.get(handle)


func get_active_effect_handles() -> Array[int]:
	var handles: Array[int] = []
	for handle_variant: Variant in _active_effects.keys():
		handles.append(handle_variant as int)
	handles.sort()
	return handles


func advance_effects(delta: float) -> void:
	if delta <= 0.0 or _active_effects.is_empty():
		return
	var handles := get_active_effect_handles()
	for handle: int in handles:
		var active_effect: ActiveGameplayEffect = _active_effects.get(handle)
		if active_effect == null:
			continue
		var effect := active_effect.definition
		if effect.duration_policy == GameplayEffect.DurationPolicy.PERIODIC:
			var active_delta := minf(delta, maxf(active_effect.remaining_duration, 0.0))
			active_effect.time_until_period -= active_delta
			while active_effect.time_until_period <= 0.0 and active_delta > 0.0:
				_apply_modifiers_to_base(effect.modifiers, active_effect.stack_count)
				active_effect.time_until_period += effect.period
		if active_effect.is_timed():
			active_effect.remaining_duration -= delta
			if active_effect.remaining_duration <= 0.0:
				remove_active_effect(handle)


func _can_afford_cost(cost_effect: GameplayEffect) -> bool:
	if cost_effect == null:
		return true
	var deltas: Dictionary = {}
	for modifier: GameplayModifier in cost_effect.modifiers:
		if modifier == null or modifier.attribute == null:
			return false
		var attribute_name := modifier.attribute.attribute_name
		if not _attribute_definitions.has(attribute_name):
			return false
		deltas[attribute_name] = float(deltas.get(attribute_name, 0.0)) + modifier.magnitude
	for attribute_variant: Variant in deltas.keys():
		var attribute_name: StringName = attribute_variant
		var definition: GameplayAttribute = _attribute_definitions[attribute_name]
		var result: float = _base_attribute_values[attribute_name] + deltas[attribute_name]
		if result < definition.minimum_value:
			return false
	return true


func _is_ability_on_cooldown(spec: AbilitySpec) -> bool:
	if spec.cooldown_handle == INVALID_EFFECT_HANDLE:
		return false
	if get_active_effect(spec.cooldown_handle) == null:
		spec.cooldown_handle = INVALID_EFFECT_HANDLE
		return false
	return true


func _commit_ability_cooldown(spec: AbilitySpec, context: AbilityContext) -> void:
	if spec.definition.cooldown_effect == null:
		return
	var cooldown_context := context.duplicate_context() if context != null else AbilityContext.new()
	if cooldown_context.source_asc == null:
		cooldown_context.source_asc = self
	cooldown_context.target_asc = self
	spec.cooldown_handle = apply_gameplay_effect(spec.definition.cooldown_effect, cooldown_context)


func _cancel_abilities_matching_tags(
	tags_to_match: Array[GameplayTag],
	ignored_handle: int
) -> void:
	if tags_to_match.is_empty():
		return
	for handle: int in get_active_ability_handles():
		if handle == ignored_handle:
			continue
		var active_spec: AbilitySpec = _ability_specs[handle]
		for query_tag: GameplayTag in tags_to_match:
			if active_spec.definition.ability_tag.matches(query_tag):
				active_spec.cancel(false)
				break


func _ensure_initialized() -> bool:
	return _initialized or initialize()


func _find_stackable_effect(
	effect: GameplayEffect,
	context: AbilityContext
) -> ActiveGameplayEffect:
	if effect.stacking_policy == GameplayEffect.StackingPolicy.NONE:
		return null
	for active_variant: Variant in _active_effects.values():
		var active: ActiveGameplayEffect = active_variant
		if active.definition != effect:
			continue
		if effect.stacking_policy == GameplayEffect.StackingPolicy.AGGREGATE_BY_TARGET:
			return active
		if effect.stacking_policy == GameplayEffect.StackingPolicy.AGGREGATE_BY_SOURCE:
			if active.context.source_asc == context.source_asc:
				return active
	return null


func _apply_modifiers_to_base(modifiers: Array[GameplayModifier], stack_count: int) -> void:
	for modifier: GameplayModifier in modifiers:
		var attribute_name := modifier.attribute.attribute_name
		if not _attribute_definitions.has(attribute_name):
			push_warning("Effect modifier skipped unknown attribute '%s'." % String(attribute_name))
			continue
		var value: float = _base_attribute_values[attribute_name]
		match modifier.operation:
			GameplayModifier.Operation.ADD:
				value += modifier.magnitude * stack_count
			GameplayModifier.Operation.MULTIPLY:
				value *= pow(modifier.magnitude, stack_count)
			GameplayModifier.Operation.OVERRIDE:
				value = modifier.magnitude
		var definition: GameplayAttribute = _attribute_definitions[attribute_name]
		_base_attribute_values[attribute_name] = definition.clamp_value(value)
	_recalculate_current_attributes()


func _recalculate_current_attributes() -> void:
	for attribute_variant: Variant in _attribute_definitions.keys():
		var attribute_name: StringName = attribute_variant
		var additive: float = 0.0
		var multiplier: float = 1.0
		var has_override: bool = false
		var override_value: float = 0.0
		for active_variant: Variant in _active_effects.values():
			var active: ActiveGameplayEffect = active_variant
			if active.definition.duration_policy == GameplayEffect.DurationPolicy.PERIODIC:
				continue
			for modifier: GameplayModifier in active.definition.modifiers:
				if modifier.attribute.attribute_name != attribute_name:
					continue
				match modifier.operation:
					GameplayModifier.Operation.ADD:
						additive += modifier.magnitude * active.stack_count
					GameplayModifier.Operation.MULTIPLY:
						multiplier *= pow(modifier.magnitude, active.stack_count)
					GameplayModifier.Operation.OVERRIDE:
						has_override = true
						override_value = modifier.magnitude
		var new_value: float = (_base_attribute_values[attribute_name] + additive) * multiplier
		if has_override:
			new_value = override_value
		var definition: GameplayAttribute = _attribute_definitions[attribute_name]
		new_value = definition.clamp_value(new_value)
		var old_value: float = _current_attribute_values.get(attribute_name, new_value)
		_current_attribute_values[attribute_name] = new_value
		if not is_equal_approx(old_value, new_value):
			attribute_changed.emit(attribute_name, old_value, new_value)


func _update_processing_state() -> void:
	var needs_processing := not get_active_ability_handles().is_empty()
	for active_variant: Variant in _active_effects.values():
		var active: ActiveGameplayEffect = active_variant
		if active.is_timed():
			needs_processing = true
			break
	set_process(needs_processing)


func _on_tag_added(tag_name: StringName) -> void:
	tag_changed.emit(tag_name, true)


func _on_tag_removed(tag_name: StringName) -> void:
	tag_changed.emit(tag_name, false)


func _on_ability_task_started(task: AbilityTask, handle: int) -> void:
	ability_task_started.emit(handle, task)


func _on_ability_lifecycle_warning(message: String, handle: int) -> void:
	_record_debug_warning("Ability %d: %s" % [handle, message])


func _record_debug_event(event: GameplayEvent) -> void:
	_debug_event_history.append({
		"tag": String(event.event_tag.tag_name),
		"payload_keys": event.payload.keys().map(func(key: Variant) -> String: return String(key)),
	})
	while _debug_event_history.size() > DEBUG_HISTORY_LIMIT:
		_debug_event_history.pop_front()


func _record_debug_warning(message: String) -> void:
	_debug_lifecycle_warnings.append(message)
	while _debug_lifecycle_warnings.size() > DEBUG_HISTORY_LIMIT:
		_debug_lifecycle_warnings.pop_front()
