class_name WaitGameplayEventAbilityTask
extends AbilityTask

var _listening_asc: AbilitySystemComponent


func _activate() -> void:
	_listening_asc = owner_spec.owner_asc
	if _listening_asc == null:
		_fail("WaitGameplayEvent requires an owner ASC.")
		return
	_listening_asc.gameplay_event_received.connect(_on_gameplay_event_received)


func _cleanup() -> void:
	if _listening_asc != null \
		and _listening_asc.gameplay_event_received.is_connected(_on_gameplay_event_received):
		_listening_asc.gameplay_event_received.disconnect(_on_gameplay_event_received)
	_listening_asc = null


func _on_gameplay_event_received(event: GameplayEvent) -> void:
	var wait_definition := definition as WaitGameplayEventAbilityTaskDefinition
	if event == null or not event.is_valid():
		return
	var matches := event.event_tag.tag_name == wait_definition.event_tag.tag_name
	if not wait_definition.exact_match:
		matches = event.event_tag.matches(wait_definition.event_tag)
	if matches:
		_complete(event)

