class_name AbilitySpec
extends RefCounted

## Per-ASC runtime state for a granted GameplayAbility Resource.

enum State {
	GRANTED,
	ACTIVATING,
	ACTIVE,
	ENDING,
	ENDED,
	CANCELLED,
}

signal task_started(task: AbilityTask)
signal lifecycle_warning(message: String)

var handle: int = 0
var definition: GameplayAbility
var owner_asc: AbilitySystemComponent
var state: State = State.GRANTED
var context: AbilityContext
var active_task: AbilityTask
var task_index: int = -1
var cooldown_handle: int = AbilitySystemComponent.INVALID_EFFECT_HANDLE


func setup(spec_handle: int, ability: GameplayAbility, owner: AbilitySystemComponent) -> void:
	handle = spec_handle
	definition = ability
	owner_asc = owner


func is_active() -> bool:
	return state == State.ACTIVATING or state == State.ACTIVE or state == State.ENDING


func begin_activation(activation_context: AbilityContext) -> void:
	context = activation_context
	task_index = -1
	active_task = null
	state = State.ACTIVE
	_start_next_task()


func advance(delta: float) -> void:
	if state == State.ACTIVE and active_task != null:
		active_task.tick(delta)


func cancel(force: bool = false) -> bool:
	if not is_active():
		return false
	if not force and not definition.can_be_cancelled:
		return false
	if active_task != null:
		active_task.cancel()
	else:
		owner_asc._finish_ability_spec(self, true)
	return true


func finalize(cancelled_activation: bool) -> void:
	if active_task != null:
		_disconnect_active_task()
		active_task.cancel()
	active_task = null
	context = null
	task_index = -1
	state = State.CANCELLED if cancelled_activation else State.ENDED


func _start_next_task() -> void:
	if state != State.ACTIVE:
		return
	task_index += 1
	if task_index >= definition.tasks.size():
		owner_asc._finish_ability_spec(self, false)
		return
	var task_definition := definition.tasks[task_index]
	active_task = task_definition.create_task(self, context)
	if active_task == null:
		var message := "Ability task %d failed to create a runtime instance." % task_index
		push_error(message)
		lifecycle_warning.emit(message)
		owner_asc._finish_ability_spec(self, true)
		return
	active_task.completed.connect(_on_task_completed)
	active_task.failed.connect(_on_task_failed)
	active_task.cancelled.connect(_on_task_cancelled)
	task_started.emit(active_task)
	active_task.start()


func _disconnect_active_task() -> void:
	if active_task.completed.is_connected(_on_task_completed):
		active_task.completed.disconnect(_on_task_completed)
	if active_task.failed.is_connected(_on_task_failed):
		active_task.failed.disconnect(_on_task_failed)
	if active_task.cancelled.is_connected(_on_task_cancelled):
		active_task.cancelled.disconnect(_on_task_cancelled)


func _on_task_completed(_result: Variant) -> void:
	_disconnect_active_task()
	active_task = null
	_start_next_task()


func _on_task_failed(reason: String) -> void:
	var message := "Ability task failed: %s" % reason
	push_warning(message)
	lifecycle_warning.emit(message)
	_disconnect_active_task()
	active_task = null
	owner_asc._finish_ability_spec(self, true)


func _on_task_cancelled() -> void:
	_disconnect_active_task()
	active_task = null
	owner_asc._finish_ability_spec(self, true)
