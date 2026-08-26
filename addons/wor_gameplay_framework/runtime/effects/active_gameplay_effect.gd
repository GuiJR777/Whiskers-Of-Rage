class_name ActiveGameplayEffect
extends RefCounted

## Per-application runtime state. GameplayEffect Resources remain immutable.

var handle: int = 0
var definition: GameplayEffect
var context: AbilityContext
var remaining_duration: float = 0.0
var time_until_period: float = 0.0
var stack_count: int = 1


func initialize(
	effect_handle: int,
	effect_definition: GameplayEffect,
	effect_context: AbilityContext
) -> void:
	handle = effect_handle
	definition = effect_definition
	context = effect_context
	remaining_duration = effect_definition.duration
	time_until_period = effect_definition.period
	stack_count = 1


func refresh_duration() -> void:
	remaining_duration = definition.duration


func is_timed() -> bool:
	return definition.duration_policy == GameplayEffect.DurationPolicy.DURATION \
		or definition.duration_policy == GameplayEffect.DurationPolicy.PERIODIC

