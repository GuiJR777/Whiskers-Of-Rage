class_name GameplayEvent
extends RefCounted

## Semantic runtime message dispatched locally by an AbilitySystemComponent.

var event_tag: GameplayTag
var context: AbilityContext
var payload: Dictionary = {}


static func create(
	tag: GameplayTag,
	event_context: AbilityContext = null,
	event_payload: Dictionary = {}
) -> GameplayEvent:
	var event := GameplayEvent.new()
	event.event_tag = tag
	event.context = event_context
	event.payload = event_payload.duplicate(true)
	return event


func is_valid() -> bool:
	return event_tag != null and event_tag.is_valid()

