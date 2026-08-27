class_name LocomotionGameplayBridge
extends Node


@export_category("References")

@export
var locomotion_state_machine: CharacterLocomotionStateMachine

@export
var ability_system: AbilitySystemComponent


var _granted_tags: Dictionary = {}


func _ready() -> void:
	if locomotion_state_machine == null:
		push_error(
			"LocomotionGameplayBridge requires a LocomotionHFSM."
		)
		return

	if ability_system == null:
		push_error(
			"LocomotionGameplayBridge requires an AbilitySystemComponent."
		)
		return

	locomotion_state_machine.state_entered.connect(
		_on_state_entered
	)

	locomotion_state_machine.state_exited.connect(
		_on_state_exited
	)

	call_deferred(
		"_sync_current_states"
	)


func _exit_tree() -> void:
	_clear_granted_tags()


func _on_state_entered(
	state_id: StringName
) -> void:
	var tag_name := (
		_get_gameplay_tag_for_state(
			state_id
		)
	)

	if tag_name == &"":
		return

	_grant_state_tag(
		state_id,
		tag_name
	)


func _on_state_exited(
	state_id: StringName
) -> void:
	_remove_state_tag(
		state_id
	)


func _sync_current_states() -> void:
	if locomotion_state_machine == null:
		return

	for state_id: StringName in (
		locomotion_state_machine
		.get_active_state_ids()
	):
		_on_state_entered(
			state_id
		)


func _grant_state_tag(
	state_id: StringName,
	tag_name: StringName
) -> void:
	if _granted_tags.has(state_id):
		return

	if not ability_system.tags.add_tag_name(
		tag_name
	):
		push_error(
			"LocomotionGameplayBridge failed to add tag '%s'."
			% String(tag_name)
		)

		return

	_granted_tags[state_id] = tag_name


func _remove_state_tag(
	state_id: StringName
) -> void:
	if not _granted_tags.has(state_id):
		return

	var tag_name: StringName = (
		_granted_tags[state_id]
	)

	ability_system.tags.remove_tag_name(
		tag_name
	)

	_granted_tags.erase(
		state_id
	)


func _clear_granted_tags() -> void:
	if not is_instance_valid(ability_system):
		_granted_tags.clear()
		return

	var state_ids: Array = (
		_granted_tags.keys()
	)

	for state_variant: Variant in state_ids:
		_remove_state_tag(
			StringName(state_variant)
		)


func _get_gameplay_tag_for_state(
	state_id: StringName
) -> StringName:
	match state_id:
		&"Grounded":
			return WORGameplayTags.STATE_GROUNDED

		&"Idle":
			return WORGameplayTags.STATE_IDLE

		&"Moving":
			return WORGameplayTags.STATE_MOVING

		&"Airborne":
			return WORGameplayTags.STATE_AIRBORNE

		&"Jumping":
			return WORGameplayTags.STATE_JUMPING

		&"Falling":
			return WORGameplayTags.STATE_FALLING

	return &""
