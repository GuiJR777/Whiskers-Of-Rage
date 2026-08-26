@tool
class_name WaitSecondsAbilityTaskDefinition
extends AbilityTaskDefinition

@export_range(0.0, 3600.0, 0.01, "or_greater") var duration: float = 0.1


func create_task(owner_spec: AbilitySpec, context: AbilityContext) -> AbilityTask:
	var task := WaitSecondsAbilityTask.new()
	task.setup(owner_spec, context, self)
	return task


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if duration < 0.0:
		errors.append("WaitSeconds duration cannot be negative.")
	return errors

