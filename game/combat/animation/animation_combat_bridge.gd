class_name AnimationCombatBridge
extends Node


# ============================================================================
# References
# ============================================================================

@export_category("References")

@export
var ability_system: AbilitySystemComponent

@export
var animation_controller: CharacterAnimationController


@export_category("Movement")

@export
var movement_component: MovementComponent


@export_category("Gameplay Events")

@export
var animation_finished_event_tag: GameplayTag

@export_category("Targeting")

@export
var targeting_component: TargetingComponent


@export_category("Hitboxes")

@export
var hitboxes: Array[HitboxComponent] = []


@export_category("Bindings")

@export
var bindings: Array[CombatAnimationBinding] = []


# ============================================================================
# Runtime
# ============================================================================

var _active_handle: int = (
	AbilitySystemComponent.INVALID_ABILITY_HANDLE
)

var _active_ability: GameplayAbility

var _active_binding: CombatAnimationBinding

var _active_context: AbilityContext

var _active_hitbox: HitboxComponent


var _combo_window_open: bool = false

var _preserve_animation_on_cancel: bool = false


# ============================================================================
# Godot Lifecycle
# ============================================================================

func _ready() -> void:
	if ability_system == null:
		push_error(
			"AnimationCombatBridge requires an AbilitySystemComponent."
		)
		return

	if animation_controller == null:
		push_error(
			"AnimationCombatBridge requires a CharacterAnimationController."
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

	animation_controller.action_finished.connect(
		_on_action_animation_finished
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
			% str(
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
# Animation Method Track API - Attack Motion
# ============================================================================

func apply_attack_motion(
	motion_id: StringName
) -> void:
	if _active_binding == null:
		return

	if movement_component == null:
		push_error(
			"AnimationCombatBridge requires a MovementComponent for attack motion."
		)
		return

	var attack := (
		_active_binding.attack_definition
	)

	if attack == null:
		return

	var motion := (
		attack.get_attack_motion(
			motion_id
		)
	)

	if motion == null:
		push_error(
			"Attack '%s' does not contain motion '%s'."
			% [
				str(attack.attack_id),
				str(motion_id),
			]
		)
		return

	var motion_direction := (
		_get_attack_motion_direction(
			attack
		)
	)

	movement_component.apply_forced_motion(
		motion_direction,
		motion.forward_speed,
		motion.upward_speed,
		motion.horizontal_deceleration
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

	# Nem toda Ability precisa ser uma Ability visual
	# controlada por este bridge.
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

	close_hitbox()

	if _combo_window_open:
		close_combo_window()

	_active_handle = handle
	_active_ability = ability
	_active_binding = binding
	
	_acquire_attack_target()

	_active_context = (
		context.duplicate_context()
		if context != null
		else AbilityContext.new()
	)

	var accepted := (
		animation_controller.play_action(
			binding.animation_name
		)
	)

	if not accepted:
		push_error(
			"AnimationCombatBridge could not play action state '%s'."
			% str(
				binding.animation_name
			)
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

func _on_action_animation_finished(
	state_name: StringName
) -> void:
	if _active_binding == null:
		return

	if (
		state_name
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
			"animation": str(
				state_name
			),
			"ability": str(
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
	cancelled: bool
) -> void:
	var preserve_animation := (
		cancelled
		and _preserve_animation_on_cancel
	)

	close_hitbox()

	if _combo_window_open:
		close_combo_window()

	if (
		not preserve_animation
		and animation_controller != null
		and _active_binding != null
	):
		animation_controller.end_action(
			_active_binding.animation_name
		)

	_preserve_animation_on_cancel = false

	_active_handle = (
		AbilitySystemComponent
		.INVALID_ABILITY_HANDLE
	)
	
	if targeting_component != null:
		targeting_component.clear_soft_target()

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
			"ability": str(
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

func _get_attack_motion_direction(
	attack: MeleeAttackDefinition
) -> Vector3:
	if (
		attack != null
		and attack.targeting != null
		and attack.targeting.redirect_attack_motion
		and targeting_component != null
		and targeting_component.has_soft_target()
	):
		var target_direction := (
			targeting_component
			.get_direction_to_facing_target()
		)

		if not target_direction.is_zero_approx():
			return target_direction

	return (
		movement_component
		.get_forward_direction()
	)

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
	
func _acquire_attack_target() -> void:
	if targeting_component == null:
		return

	if movement_component == null:
		return

	if _active_binding == null:
		return

	var attack := (
		_active_binding.attack_definition
	)

	if attack == null:
		return

	if attack.targeting == null:
		targeting_component.clear_soft_target()
		return

	var reference_direction := (
		movement_component
		.get_forward_direction()
	)

	targeting_component.acquire_soft_target(
		reference_direction,
		attack.targeting
	)

func apply_attack_magnetism() -> void:
	if _active_binding == null:
		return

	if movement_component == null:
		return

	if targeting_component == null:
		return

	if not targeting_component.has_soft_target():
		return

	var attack := (
		_active_binding.attack_definition
	)

	if attack == null:
		return

	var targeting := (
		attack.targeting
	)

	if targeting == null:
		return

	if not targeting.magnetism_enabled:
		return

	var target := (
		targeting_component.get_soft_target()
	)

	if target == null:
		return

	var body := (
		movement_component.body
	)

	if body == null:
		return

	var to_target := (
		target.global_position
		- body.global_position
	)

	to_target.y = 0.0

	var current_distance := (
		to_target.length()
	)

	if current_distance <= 0.001:
		return

	var travel_distance := (
		current_distance
		- targeting.stopping_distance
	)

	if travel_distance <= 0.0:
		return

	travel_distance = minf(
		travel_distance,
		targeting.maximum_magnetism_distance
	)

	var direction := (
		to_target.normalized()
	)

	# v² = 2ad
	#
	# Calculamos a velocidade inicial necessária
	# para que o Forced Motion desacelere
	# aproximadamente dentro da distância desejada.
	var speed := sqrt(
		2.0
		* targeting.magnetism_deceleration
		* travel_distance
	)

	speed = minf(
		speed,
		targeting.maximum_magnetism_speed
	)

	movement_component.apply_forced_motion(
		direction,
		speed,
		0.0,
		targeting.magnetism_deceleration
	)
