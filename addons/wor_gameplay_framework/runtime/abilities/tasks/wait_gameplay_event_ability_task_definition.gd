@tool
class_name WaitGameplayEventAbilityTaskDefinition
extends AbilityTaskDefinition

@export var event_tag: GameplayTag
@export var exact_match: bool = false


func create_task(owner_spec: AbilitySpec, context: AbilityContext) -> AbilityTask:
	var task := WaitGameplayEventAbilityTask.new()
	task.setup(owner_spec, context, self)
	return task


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if event_tag == null or not event_tag.is_valid():
		errors.append("WaitGameplayEvent requires a valid event_tag.")
	return errors

