class_name HitReactionComponent
extends Node


signal reaction_started(
	reaction: HitReactionDefinition
)

signal knockdown_applied()


@export_category("References")

@export
var ability_system: AbilitySystemComponent

@export
var movement_component: MovementComponent


func _ready() -> void:
	if ability_system == null:
		push_error(
			"HitReactionComponent requires an AbilitySystemComponent."
		)
		return

	if movement_component == null:
		push_error(
			"HitReactionComponent requires a MovementComponent."
		)
		return

	ability_system.gameplay_event_received.connect(
		_on_gameplay_event_received
	)


func _on_gameplay_event_received(
	event: GameplayEvent
) -> void:
	if event == null:
		return

	if not event.is_valid():
		return

	if (
		event.event_tag.tag_name
		!= WORGameplayTags.EVENT_COMBAT_HIT_RECEIVED
	):
		return

	var reaction_variant: Variant = (
		event.payload.get(
			"reaction",
			null
		)
	)

	var reaction := (
		reaction_variant
		as HitReactionDefinition
	)

	if reaction == null:
		return

	_apply_reaction(
		reaction,
		event.context
	)


func _apply_reaction(
	reaction: HitReactionDefinition,
	context: AbilityContext
) -> void:
	var direction := Vector3.ZERO

	if context != null:
		direction = (
			context.hit_direction
		)

	direction.y = 0.0

	movement_component.apply_forced_motion(
		direction,
		reaction.horizontal_speed,
		reaction.upward_speed,
		reaction.horizontal_deceleration
	)

	if (
		reaction.causes_knockdown
		and reaction.knockdown_effect != null
	):
		var effect_context := (
			context.duplicate_context()
			if context != null
			else AbilityContext.new()
		)

		effect_context.target_asc = (
			ability_system
		)

		ability_system.apply_gameplay_effect(
			reaction.knockdown_effect,
			effect_context
		)

		knockdown_applied.emit()

	reaction_started.emit(
		reaction
	)
