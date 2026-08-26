@tool
class_name GameplayAttributeSet
extends Resource

## Data-only collection used to initialize an ASC. It never stores runtime values.

@export var attributes: Array[GameplayAttribute] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var known_names: Dictionary = {}
	for index: int in attributes.size():
		var attribute := attributes[index]
		if attribute == null:
			errors.append("Attribute at index %d is null." % index)
			continue
		for attribute_error: String in attribute.validate():
			errors.append("Attribute '%s': %s" % [String(attribute.attribute_name), attribute_error])
		if known_names.has(attribute.attribute_name):
			errors.append("Duplicate attribute '%s'." % String(attribute.attribute_name))
		known_names[attribute.attribute_name] = true
	return errors

