class_name AbilityTask
extends RefCounted

## Cancelable runtime operation owned by one AbilitySpec activation.

enum State {
	CREATED,
	ACTIVE,
	COMPLETED,
	FAILED,
	CANCELLED,
}

signal completed(result: Variant)
signal failed(reason: String)
signal cancelled()

var owner_spec: AbilitySpec
var context: AbilityContext
var definition: AbilityTaskDefinition
var state: State = State.CREATED


func setup(
	task_owner: AbilitySpec,
	task_context: AbilityContext,
	task_definition: AbilityTaskDefinition
) -> void:
	owner_spec = task_owner
	context = task_context
	definition = task_definition


func start() -> void:
	if state != State.CREATED:
		push_error("AbilityTask.start can only be called once.")
		return
	state = State.ACTIVE
	_activate()


func tick(delta: float) -> void:
	if state == State.ACTIVE:
		_tick(delta)


func cancel() -> void:
	if state != State.CREATED and state != State.ACTIVE:
		return
	_cleanup()
	state = State.CANCELLED
	cancelled.emit()


func is_active() -> bool:
	return state == State.ACTIVE


func _complete(result: Variant = null) -> void:
	if state != State.ACTIVE:
		return
	_cleanup()
	state = State.COMPLETED
	completed.emit(result)


func _fail(reason: String) -> void:
	if state != State.ACTIVE:
		return
	_cleanup()
	state = State.FAILED
	failed.emit(reason)


func _activate() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func _cleanup() -> void:
	pass

