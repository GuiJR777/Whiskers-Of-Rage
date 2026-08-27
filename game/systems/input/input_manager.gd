extends Node


# ============================================================================
# Movement Actions
# ============================================================================

const MOVE_FORWARD: StringName = &"move_forward"
const MOVE_BACKWARD: StringName = &"move_backward"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"


# ============================================================================
# Camera Actions
# ============================================================================

const LOOK_UP: StringName = &"look_up"
const LOOK_DOWN: StringName = &"look_down"
const LOOK_LEFT: StringName = &"look_left"
const LOOK_RIGHT: StringName = &"look_right"


# ============================================================================
# Input Buffer
# ============================================================================

const DEFAULT_BUFFER_WINDOW: float = 0.15

var _buffer: Array[InputBufferEntry] = []
var _buffered_actions: Dictionary = {}


# ============================================================================
# Mouse
# ============================================================================

var _mouse_delta: Vector2 = Vector2.ZERO


# ============================================================================
# State
# ============================================================================

var _gameplay_input_enabled: bool = true


# ============================================================================
# Godot Lifecycle
# ============================================================================

func _process(_delta: float) -> void:
	_remove_expired_buffer_entries()


func _unhandled_input(event: InputEvent) -> void:
	if not _gameplay_input_enabled:
		return

	_process_mouse_event(event)
	_process_buffered_actions(event)


# ============================================================================
# Movement
# ============================================================================

func get_move_vector() -> Vector2:
	if not _gameplay_input_enabled:
		return Vector2.ZERO

	return Input.get_vector(
		MOVE_LEFT,
		MOVE_RIGHT,
		MOVE_FORWARD,
		MOVE_BACKWARD
	)


# ============================================================================
# Camera
# ============================================================================

func get_look_vector() -> Vector2:
	if not _gameplay_input_enabled:
		return Vector2.ZERO

	return Input.get_vector(
		LOOK_LEFT,
		LOOK_RIGHT,
		LOOK_UP,
		LOOK_DOWN
	)


func consume_mouse_delta() -> Vector2:
	var result := _mouse_delta

	_mouse_delta = Vector2.ZERO

	return result


func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ============================================================================
# Generic Input
# ============================================================================

func is_action_pressed(action: StringName) -> bool:
	if not _gameplay_input_enabled:
		return false

	if not InputMap.has_action(action):
		return false

	return Input.is_action_pressed(action)


func is_action_just_pressed(action: StringName) -> bool:
	if not _gameplay_input_enabled:
		return false

	if not InputMap.has_action(action):
		return false

	return Input.is_action_just_pressed(action)


func is_action_just_released(action: StringName) -> bool:
	if not _gameplay_input_enabled:
		return false

	if not InputMap.has_action(action):
		return false

	return Input.is_action_just_released(action)


# ============================================================================
# Gameplay Input State
# ============================================================================

func set_gameplay_input_enabled(enabled: bool) -> void:
	_gameplay_input_enabled = enabled

	if not enabled:
		_mouse_delta = Vector2.ZERO
		clear_buffer()


func is_gameplay_input_enabled() -> bool:
	return _gameplay_input_enabled


# ============================================================================
# Input Buffer Registration
# ============================================================================

func register_buffered_action(
	action: StringName,
	buffer_window: float = DEFAULT_BUFFER_WINDOW
) -> void:
	if not InputMap.has_action(action):
		push_warning(
			"InputManager: cannot register missing InputMap action '%s'."
			% action
		)
		return

	_buffered_actions[action] = maxf(buffer_window, 0.0)


func unregister_buffered_action(action: StringName) -> void:
	_buffered_actions.erase(action)
	clear_buffered_action(action)


# ============================================================================
# Input Buffer Query
# ============================================================================

func has_buffered_action(action: StringName) -> bool:
	_remove_expired_buffer_entries()

	for entry: InputBufferEntry in _buffer:
		if entry.action == action:
			return true

	return false


func consume_buffered_action(action: StringName) -> bool:
	_remove_expired_buffer_entries()

	for index: int in range(_buffer.size()):
		var entry := _buffer[index]

		if entry.action != action:
			continue

		_buffer.remove_at(index)

		return true

	return false


func clear_buffered_action(action: StringName) -> void:
	for index: int in range(_buffer.size() - 1, -1, -1):
		if _buffer[index].action == action:
			_buffer.remove_at(index)


func clear_buffer() -> void:
	_buffer.clear()


# ============================================================================
# Private
# ============================================================================

func _process_mouse_event(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	var mouse_event := event as InputEventMouseMotion

	_mouse_delta += mouse_event.relative


func _process_buffered_actions(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.echo:
			return

	for action_variant: Variant in _buffered_actions.keys():
		var action := StringName(action_variant)

		if not event.is_action_pressed(action):
			continue

		var buffer_window: float = float(
			_buffered_actions[action]
		)

		_add_buffer_entry(
			action,
			buffer_window
		)


func _add_buffer_entry(
	action: StringName,
	buffer_window: float
) -> void:
	# Mantemos apenas a entrada mais recente da mesma action.
	clear_buffered_action(action)

	_buffer.append(
		InputBufferEntry.new(
			action,
			_get_current_time(),
			buffer_window
		)
	)


func _remove_expired_buffer_entries() -> void:
	var current_time := _get_current_time()

	for index: int in range(_buffer.size() - 1, -1, -1):
		if _buffer[index].is_expired(current_time):
			_buffer.remove_at(index)


func _get_current_time() -> float:
	return Time.get_ticks_msec() * 0.001
