@tool
class_name GameplayModifier
extends Resource

enum Operation {
	ADD,
	MULTIPLY,
	OVERRIDE,
}

@export var attribute: GameplayAttribute
@export var operation: Operation = Operation.ADD
@export var magnitude: float = 0.0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if attribute == null:
		errors.append("GameplayModifier.attribute cannot be null.")
	elif not attribute.validate().is_empty():
		errors.append("GameplayModifier.attribute must be a valid GameplayAttribute.")
	return errors

