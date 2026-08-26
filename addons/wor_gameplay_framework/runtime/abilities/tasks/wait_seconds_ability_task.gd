class_name WaitSecondsAbilityTask
extends AbilityTask

var _remaining_seconds: float = 0.0


func _activate() -> void:
	var wait_definition := definition as WaitSecondsAbilityTaskDefinition
	_remaining_seconds = wait_definition.duration
	if _remaining_seconds <= 0.0:
		_complete()


func _tick(delta: float) -> void:
	_remaining_seconds -= maxf(delta, 0.0)
	if _remaining_seconds <= 0.0:
		_complete()

