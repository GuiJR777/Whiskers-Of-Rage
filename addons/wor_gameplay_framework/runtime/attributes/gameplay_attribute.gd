@tool
class_name GameplayAttribute
extends Resource

## Immutable attribute definition. Current values are owned by an ASC at runtime.

@export var attribute_name: StringName = &""
@export var default_value: float = 0.0
@export var minimum_value: float = -1.0e20
@export var maximum_value: float = 1.0e20


func clamp_value(value: float) -> float:
	return clampf(value, minimum_value, maximum_value)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if attribute_name == &"":
		errors.append("GameplayAttribute.attribute_name cannot be empty.")
	if minimum_value > maximum_value:
		errors.append("GameplayAttribute.minimum_value cannot exceed maximum_value.")
	return errors

