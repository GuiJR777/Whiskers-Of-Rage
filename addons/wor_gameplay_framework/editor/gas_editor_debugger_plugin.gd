@tool
extends EditorDebuggerPlugin

signal snapshots_received(session_id: int, snapshots: Array)
signal runtime_stopped(session_id: int)

const CAPTURE_PREFIX: String = "wor_gas"
const SNAPSHOT_MESSAGE: String = "wor_gas:snapshots"


func _has_capture(capture: String) -> bool:
	return capture == CAPTURE_PREFIX


func _capture(message: String, data: Array, session_id: int) -> bool:
	if message != SNAPSHOT_MESSAGE:
		return false
	var snapshots: Array = data[0] if not data.is_empty() and data[0] is Array else []
	snapshots_received.emit(session_id, snapshots)
	return true


func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	if session != null:
		session.stopped.connect(func() -> void: runtime_stopped.emit(session_id))
