class_name InputBufferEntry
extends RefCounted


var action: StringName
var timestamp: float
var buffer_window: float


func _init(
	p_action: StringName,
	p_timestamp: float,
	p_buffer_window: float
) -> void:
	action = p_action
	timestamp = p_timestamp
	buffer_window = p_buffer_window


func is_expired(current_time: float) -> bool:
	return current_time - timestamp > buffer_window
