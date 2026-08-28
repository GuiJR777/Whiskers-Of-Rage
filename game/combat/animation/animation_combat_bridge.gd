class_name AnimationCombatBridge
extends Node


@export_category("References")

@export
var ability_system: AbilitySystemComponent

@export
var animation_player: AnimationPlayer


@export_category("Gameplay Events")

@export
var animation_finished_event_tag: GameplayTag


@export_category("Hitboxes")

@export
var hitboxes: Array[HitboxComponent] = []


@export_category("Bindings")

@export
var bindings: Array[CombatAnimationBinding] = []


var _active_handle: int = (
	AbilitySystemComponent.INVALID_ABILITY_HANDLE
)

var _active_ability: GameplayAbility

var _active_binding: CombatAnimationBinding

var _active_context: AbilityContext

var _active_hitbox: HitboxComponent


var _combo_window_open: bool = false

var _preserve_animation_on_cancel: bool = false


func _ready() -> void:
	if ability_system == null:
		push_error(
			"AnimationCombatBridge requires an AbilitySystemComponent."
		)
		return

	if animation_player == null:
		push_error(
			"AnimationCombatBridge requires an AnimationPlayer."
		)
		return

	if (
		animation_finished_event_tag == null
		or not animation_finished_event_tag.is_valid()
	):
		push_error(
			"AnimationCombatBridge requires a valid animation finished event tag."
		)
		return

	ability_system.ability_activated.connect(
		_on_ability_activated
	)

	ability_system.ability_ended.connect(
		_on_ability_ended
	)

	ability_system.ability_cancelled.connect(
		_on_ability_cancelled
	)

	animation_player.animation_finished.connect(
		_on_animation_finished
	)


# ============================================================================
# Animation Method Track API - Hitbox
# ============================================================================

func open_hitbox() -> void:
	if _active_binding == null:
		return

	if _active_hitbox != null:
		_active_hitbox.deactivate()
		_active_hitbox = null

	var hitbox := (
		_get_hitbox(
			_active_binding.hitbox_id
		)
	)

	if hitbox == null:
		push_error(
			"AnimationCombatBridge cannot find hitbox '%s'."
			% String(
				_active_binding.hitbox_id
			)
		)

		return

	if not hitbox.activate_attack(
		_active_binding.attack_definition,
		_active_ability
	):
		return

	_active_hitbox = hitbox


func close_hitbox() -> void:
	if _active_hitbox == null:
		return

	_active_hitbox.deactivate()

	_active_hitbox = null


# ============================================================================
# Animation Method Track API - Combo
# ============================================================================

func open_combo_window() -> void:
	if _active_ability == null:
		return

	if _combo_window_open:
		return

	_combo_window_open = true

	_send_combat_event(
		WORGameplayTags
			.EVENT_COMBAT_COMBO_WINDOW_OPEN
	)


func close_combo_window() -> void:
	if not _combo_window_open:
		return

	_combo_window_open = false

	_send_combat_event(
		WORGameplayTags
			.EVENT_COMBAT_COMBO_WINDOW_CLOSE
	)


# ============================================================================
# Combo Transition
# ============================================================================

func prepare_combo_transition() -> void:
	_preserve_animation_on_cancel = true


func cancel_combo_transition() -> void:
	_preserve_animation_on_cancel = false


# ============================================================================
# Ability Lifecycle
# ============================================================================

func _on_ability_activated(
	handle: int,
	ability: GameplayAbility,
	context: AbilityContext
) -> void:
	var binding := (
		_find_binding(
			ability
		)
	)

	if binding == null:
		return

	var validation_errors := (
		binding.validate()
	)

	if not validation_errors.is_empty():
		push_error(
			"Invalid CombatAnimationBinding: %s"
			% "; ".join(
				validation_errors
			)
		)

		return

	if not animation_player.has_animation(
		binding.animation_name
	):
		push_error(
			"Animation '%s' was not found."
			% String(
				binding.animation_name
			)
		)

		return

	close_hitbox()

	if _combo_window_open:
		close_combo_window()

	_active_handle = handle
	_active_ability = ability
	_active_binding = binding

	_active_context = (
		context.duplicate_context()
		if context != null
		else AbilityContext.new()
	)

	animation_player.play(
		binding.animation_name,
		binding.transition_blend_time
	)


func _on_ability_ended(
	handle: int,
	_ability: GameplayAbility
) -> void:
	if handle != _active_handle:
		return

	_finish_active_ability(
		false
	)


func _on_ability_cancelled(
	handle: int,
	_ability: GameplayAbility
) -> void:
	if handle != _active_handle:
		return

	_finish_active_ability(
		true
	)


# ============================================================================
# Animation Lifecycle
# ============================================================================

func _on_animation_finished(
	animation_name: StringName
) -> void:
	if _active_binding == null:
		return

	if (
		animation_name
		!= _active_binding.animation_name
	):
		return

	close_hitbox()

	if _combo_window_open:
		close_combo_window()

	var event_context := (
		_active_context.duplicate_context()
		if _active_context != null
		else AbilityContext.new()
	)

	event_context.source_asc = (
		ability_system
	)

	event_context.target_asc = (
		ability_system
	)

	event_context.ability = (
		_active_ability
	)

	var event := GameplayEvent.create(
		animation_finished_event_tag,
		event_context,
		{
			"animation": String(
				animation_name
			),
			"ability": String(
				_active_ability
				.ability_tag
				.tag_name
			),
		}
	)

	ability_system.send_gameplay_event(
		event
	)


func _finish_active_ability(
	cancel_animation: bool
) -> void:
	var preserve_animation := (
		cancel_animation
		and _preserve_animation_on_cancel
	)

	close_hitbox()

	if _combo_window_open:
		close_combo_window()

	if (
		cancel_animation
		and not preserve_animation
		and animation_player.is_playing()
		and _active_binding != null
		and animation_player.current_animation
			== _active_binding.animation_name
	):
		animation_player.stop()

	_preserve_animation_on_cancel = false

	_active_handle = (
		AbilitySystemComponent
		.INVALID_ABILITY_HANDLE
	)

	_active_ability = null
	_active_binding = null
	_active_context = null


# ============================================================================
# Gameplay Events
# ============================================================================

func _send_combat_event(
	tag_name: StringName
) -> void:
	if ability_system == null:
		return

	if _active_ability == null:
		return

	var event_tag := GameplayTag.new()

	event_tag.tag_name = tag_name

	var event_context := (
		_active_context.duplicate_context()
		if _active_context != null
		else AbilityContext.new()
	)

	event_context.source_asc = (
		ability_system
	)

	event_context.target_asc = (
		ability_system
	)

	event_context.ability = (
		_active_ability
	)

	var event := GameplayEvent.create(
		event_tag,
		event_context,
		{
			"ability": String(
				_active_ability
				.ability_tag
				.tag_name
			),
		}
	)

	ability_system.send_gameplay_event(
		event
	)


# ============================================================================
# Lookups
# ============================================================================

func _find_binding(
	ability: GameplayAbility
) -> CombatAnimationBinding:
	if (
		ability == null
		or ability.ability_tag == null
	):
		return null

	for binding: CombatAnimationBinding in bindings:
		if (
			binding == null
			or binding.ability_tag == null
		):
			continue

		if (
			binding.ability_tag.tag_name
			== ability.ability_tag.tag_name
		):
			return binding

	return null


func _get_hitbox(
	hitbox_id: StringName
) -> HitboxComponent:
	for hitbox: HitboxComponent in hitboxes:
		if hitbox == null:
			continue

		if hitbox.hitbox_id == hitbox_id:
			return hitbox

	return null
