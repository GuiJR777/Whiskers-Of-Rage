class_name ComboComponent
extends Node


signal combo_started(
	combo_id: StringName
)

signal combo_step_changed(
	step_index: int,
	ability_tag: StringName
)

signal combo_ended()


@export_category("References")

@export
var ability_system: AbilitySystemComponent

@export
var animation_combat_bridge: AnimationCombatBridge


@export_category("Combo")

@export
var combo_definition: ComboDefinition


var _current_step_index: int = -1

var _combo_window_open: bool = false

var _hit_confirmed: bool = false

var _transition_in_progress: bool = false


func _ready() -> void:
	if ability_system == null:
		push_error(
			"ComboComponent requires an AbilitySystemComponent."
		)
		return

	if animation_combat_bridge == null:
		push_error(
			"ComboComponent requires an AnimationCombatBridge."
		)
		return

	if combo_definition == null:
		push_error(
			"ComboComponent requires a ComboDefinition."
		)
		return

	var validation_errors := (
		combo_definition.validate()
	)

	if not validation_errors.is_empty():
		push_error(
			"Invalid ComboDefinition: %s"
			% "; ".join(
				validation_errors
			)
		)

		return

	ability_system.gameplay_event_received.connect(
		_on_gameplay_event_received
	)

	ability_system.ability_cancelled.connect(
		_on_ability_cancelled
	)

	ability_system.ability_ended.connect(
		_on_ability_ended
	)


func get_input_buffer_time() -> float:
	if combo_definition == null:
		return 0.15

	return combo_definition.input_buffer_time


func try_request_input(
	action: StringName,
	instigator: Node
) -> bool:
	if combo_definition == null:
		return false

	if action != combo_definition.input_action:
		return false

	if _current_step_index < 0:
		return _activate_step(
			0,
			instigator,
			false
		)

	if not _combo_window_open:
		return false

	var current_step := (
		combo_definition
		.steps[_current_step_index]
	)

	if (
		current_step
		.requires_hit_confirm_to_advance
		and not _hit_confirmed
	):
		return false

	var next_step_index := (
		_current_step_index + 1
	)

	if (
		next_step_index
		>= combo_definition.steps.size()
	):
		return false

	return _activate_step(
		next_step_index,
		instigator,
		true
	)


func is_combo_active() -> bool:
	return _current_step_index >= 0


func get_current_step_index() -> int:
	return _current_step_index


func is_combo_window_open() -> bool:
	return _combo_window_open


func has_hit_confirm() -> bool:
	return _hit_confirmed


# ============================================================================
# Ability Activation
# ============================================================================

func _activate_step(
	step_index: int,
	instigator: Node,
	is_transition: bool
) -> bool:
	if (
		step_index < 0
		or step_index
			>= combo_definition.steps.size()
	):
		return false

	var step := (
		combo_definition.steps[
			step_index
		]
	)

	if (
		step == null
		or step.ability_tag == null
	):
		return false

	var context := AbilityContext.create(
		ability_system,
		null,
		instigator
	)

	if is_transition:
		_transition_in_progress = true

		animation_combat_bridge.prepare_combo_transition()

	var accepted := (
		ability_system
		.try_activate_ability_by_tag_name(
			step.ability_tag.tag_name,
			context
		)
	)

	if is_transition:
		animation_combat_bridge.cancel_combo_transition()

		_transition_in_progress = false

	if not accepted:
		return false

	var was_inactive := (
		_current_step_index < 0
	)

	_current_step_index = step_index

	_combo_window_open = false
	_hit_confirmed = false

	if was_inactive:
		combo_started.emit(
			combo_definition.combo_id
		)

	combo_step_changed.emit(
		_current_step_index,
		step.ability_tag.tag_name
	)

	return true


# ============================================================================
# Gameplay Events
# ============================================================================

func _on_gameplay_event_received(
	event: GameplayEvent
) -> void:
	if event == null:
		return

	if not event.is_valid():
		return

	if _current_step_index < 0:
		return

	if not _event_matches_current_step(
		event
	):
		return

	var event_name := (
		event.event_tag.tag_name
	)

	match event_name:
		WORGameplayTags.EVENT_COMBAT_HIT_CONFIRMED:
			_hit_confirmed = true

		WORGameplayTags.EVENT_COMBAT_COMBO_WINDOW_OPEN:
			_combo_window_open = true

		WORGameplayTags.EVENT_COMBAT_COMBO_WINDOW_CLOSE:
			_combo_window_open = false

		WORGameplayTags.EVENT_ANIMATION_ABILITY_FINISHED:
			_reset_combo()


func _event_matches_current_step(
	event: GameplayEvent
) -> bool:
	if (
		_current_step_index < 0
		or _current_step_index
			>= combo_definition.steps.size()
	):
		return false

	var expected_tag := (
		combo_definition
		.steps[_current_step_index]
		.ability_tag
		.tag_name
	)

	var payload_ability := StringName(
		String(
			event.payload.get(
				"ability",
				""
			)
		)
	)

	return payload_ability == expected_tag


# ============================================================================
# Ability Lifecycle
# ============================================================================

func _on_ability_cancelled(
	_handle: int,
	ability: GameplayAbility
) -> void:
	if not _matches_current_ability(
		ability
	):
		return

	# Attack01 sendo cancelado para Attack02
	# NÃO encerra o combo.
	if _transition_in_progress:
		return

	_reset_combo()


func _on_ability_ended(
	_handle: int,
	ability: GameplayAbility
) -> void:
	if not _matches_current_ability(
		ability
	):
		return

	_reset_combo()


func _matches_current_ability(
	ability: GameplayAbility
) -> bool:
	if ability == null:
		return false

	if ability.ability_tag == null:
		return false

	if _current_step_index < 0:
		return false

	var current_step := (
		combo_definition
		.steps[_current_step_index]
	)

	return (
		current_step.ability_tag.tag_name
		== ability.ability_tag.tag_name
	)


# ============================================================================
# Reset
# ============================================================================

func _reset_combo() -> void:
	if _current_step_index < 0:
		return

	_current_step_index = -1

	_combo_window_open = false
	_hit_confirmed = false

	combo_ended.emit()
