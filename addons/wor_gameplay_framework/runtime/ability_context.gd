class_name AbilityContext
extends RefCounted

## Transient data passed from a gameplay action to effects/calculations.

var instigator: Node
var source_asc: AbilitySystemComponent
var target_asc: AbilitySystemComponent
var ability: GameplayAbility
var world_position: Vector3 = Vector3.ZERO
var hit_direction: Vector3 = Vector3.ZERO
var hit_result: Dictionary = {}
var metadata: Dictionary = {}
var context_tags: GameplayTagContainer = GameplayTagContainer.new()
var is_back_attack: bool = false
var is_critical: bool = false
var source_object: Object


static func create(
	source: AbilitySystemComponent = null,
	target: AbilitySystemComponent = null,
	context_instigator: Node = null
) -> AbilityContext:
	var context := AbilityContext.new()
	context.source_asc = source
	context.target_asc = target
	context.instigator = context_instigator
	return context


func duplicate_context() -> AbilityContext:
	var copy := AbilityContext.new()
	copy.instigator = instigator
	copy.source_asc = source_asc
	copy.target_asc = target_asc
	copy.ability = ability
	copy.world_position = world_position
	copy.hit_direction = hit_direction
	copy.hit_result = hit_result.duplicate(true)
	copy.metadata = metadata.duplicate(true)
	for tag_name: StringName in context_tags.get_owned_tag_names():
		copy.context_tags.add_tag_name(tag_name, context_tags.get_tag_count(tag_name))
	copy.is_back_attack = is_back_attack
	copy.is_critical = is_critical
	copy.source_object = source_object
	return copy
