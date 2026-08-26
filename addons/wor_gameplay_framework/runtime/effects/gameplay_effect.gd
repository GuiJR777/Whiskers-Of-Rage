@tool
class_name GameplayEffect
extends Resource

enum DurationPolicy {
	INSTANT,
	DURATION,
	INFINITE,
	PERIODIC,
}

enum StackingPolicy {
	NONE,
	AGGREGATE_BY_SOURCE,
	AGGREGATE_BY_TARGET,
}

@export var effect_id: StringName = &""
@export var duration_policy: DurationPolicy = DurationPolicy.INSTANT
@export_range(0.0, 3600.0, 0.01, "or_greater") var duration: float = 0.0
@export_range(0.01, 3600.0, 0.01, "or_greater") var period: float = 1.0
@export var execute_period_on_application: bool = false
@export var modifiers: Array[GameplayModifier] = []
@export var granted_tags: Array[GameplayTag] = []
@export var stacking_policy: StackingPolicy = StackingPolicy.NONE
@export_range(1, 999, 1, "or_greater") var maximum_stacks: int = 1
@export var refresh_duration_on_reapplication: bool = true


func _validate_property(property: Dictionary) -> void:
	var property_name: StringName = property.name
	if property_name == &"duration" and duration_policy not in [
		DurationPolicy.DURATION,
		DurationPolicy.PERIODIC,
	]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property_name in [&"period", &"execute_period_on_application"] \
		and duration_policy != DurationPolicy.PERIODIC:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR
	if property_name in [&"maximum_stacks", &"refresh_duration_on_reapplication"] \
		and stacking_policy == StackingPolicy.NONE:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if effect_id == &"":
		errors.append("GameplayEffect.effect_id cannot be empty.")
	if duration_policy == DurationPolicy.DURATION and duration <= 0.0:
		errors.append("A Duration effect requires duration greater than zero.")
	if duration_policy == DurationPolicy.PERIODIC:
		if duration <= 0.0:
			errors.append("A Periodic effect requires duration greater than zero.")
		if period <= 0.0:
			errors.append("A Periodic effect requires period greater than zero.")
	if maximum_stacks < 1:
		errors.append("GameplayEffect.maximum_stacks must be at least one.")
	for index: int in modifiers.size():
		var modifier := modifiers[index]
		if modifier == null:
			errors.append("Modifier at index %d is null." % index)
			continue
		for modifier_error: String in modifier.validate():
			errors.append("Modifier %d: %s" % [index, modifier_error])
	for index: int in granted_tags.size():
		var tag := granted_tags[index]
		if tag == null:
			errors.append("Granted tag at index %d is null." % index)
		elif not tag.is_valid():
			errors.append("Granted tag at index %d is invalid." % index)
	return errors
