@tool
class_name AbilityTaskDefinition
extends Resource

## Immutable task configuration. Every activation creates a fresh AbilityTask runtime.


func create_task(_owner_spec: AbilitySpec, _context: AbilityContext) -> AbilityTask:
	push_error("AbilityTaskDefinition.create_task must be implemented by a concrete definition.")
	return null


func validate() -> PackedStringArray:
	return PackedStringArray()

