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


# Input do próximo step que já foi aceito,
# mas ainda está aguardando as condições do combo.
var _next_step_queued: bool = false

var _queued_instigator: Node


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


# ============================================================================
# Public API
# ============================================================================

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

	# Nenhum combo ativo:
	# começa pelo primeiro step.
	if _current_step_index < 0:
		return _activate_step(
			0,
			instigator,
			false
		)

	# Combo já está no último step.
	if not _has_next_step():
		return false

	# Existe próximo ataque.
	#
	# Não precisamos esperar a Combo Window abrir
	# para aceitar o input.
	#
	# Guardamos a intenção e executamos assim que
	# HitConfirm + ComboWindow permitirem.
	_next_step_queued = true
	_queued_instigator = instigator

	_try_execute_queued_transition()

	return true


func is_combo_active() -> bool:
	return _current_step_index >= 0


func get_current_step_index() -> int:
	return _current_step_index


func is_combo_window_open() -> bool:
	return _combo_window_open


func has_hit_confirm() -> bool:
	return _hit_confirmed


func has_queued_next_step() -> bool:
	return _next_step_queued


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


func _try_execute_queued_transition() -> void:
	if not _next_step_queued:
		return

	if _current_step_index < 0:
		return

	if not _combo_window_open:
		return

	var current_step := (
		combo_definition
		.steps[_current_step_index]
	)

	if (
		current_step
		.requires_hit_confirm_to_advance
		and not _hit_confirmed
	):
		return

	var next_step_index := (
		_current_step_index + 1
	)

	if (
		next_step_index
		>= combo_definition.steps.size()
	):
		_clear_queued_input()
		return

	var instigator := _queued_instigator

	_clear_queued_input()

	var accepted := _activate_step(
		next_step_index,
		instigator,
		true
	)

	if not accepted:
		push_warning(
			"ComboComponent failed to activate combo step %d."
			% next_step_index
		)


func _has_next_step() -> bool:
	if _current_step_index < 0:
		return false

	return (
		_current_step_index + 1
		< combo_definition.steps.size()
	)


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

			# Caso a Combo Window já esteja aberta.
			call_deferred(
				"_try_execute_queued_transition"
			)

		WORGameplayTags.EVENT_COMBAT_COMBO_WINDOW_OPEN:
			_combo_window_open = true

			# Caso o jogador tenha apertado Attack
			# antes da janela abrir.
			call_deferred(
				"_try_execute_queued_transition"
			)

		WORGameplayTags.EVENT_COMBAT_COMBO_WINDOW_CLOSE:
			_combo_window_open = false

			# Não deixa input de uma janela antiga
			# escapar para outro momento do combo.
			_clear_queued_input()

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

	# Preferimos o AbilityContext.
	# É mais robusto que depender do payload.
	if (
		event.context != null
		and event.context.ability != null
		and event.context.ability.ability_tag != null
	):
		return (
			event.context
			.ability
			.ability_tag
			.tag_name
			== expected_tag
		)

	# Fallback para eventos antigos / externos.
	var payload_ability := StringName(
		str(
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
	# faz parte da transição normal do combo.
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

	if current_step == null:
		return false

	if current_step.ability_tag == null:
		return false

	return (
		current_step.ability_tag.tag_name
		== ability.ability_tag.tag_name
	)


# ============================================================================
# Reset
# ============================================================================

func _clear_queued_input() -> void:
	_next_step_queued = false
	_queued_instigator = null


func _reset_combo() -> void:
	if _current_step_index < 0:
		return

	_current_step_index = -1

	_combo_window_open = false
	_hit_confirmed = false

	_clear_queued_input()

	combo_ended.emit()
