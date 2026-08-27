class_name TargetingComponent
extends Node


signal target_locked(target: Node3D)
signal target_unlocked(previous_target: Node3D)


var _current_target: Node3D


func lock_target(target: Node3D) -> void:
	if target == null:
		clear_target()
		return

	if _current_target == target:
		return

	_current_target = target

	target_locked.emit(
		_current_target
	)


func clear_target() -> void:
	if _current_target == null:
		return

	var previous_target := _current_target

	_current_target = null

	target_unlocked.emit(
		previous_target
	)


func has_locked_target() -> bool:
	return is_instance_valid(
		_current_target
	)


func get_locked_target() -> Node3D:
	if not has_locked_target():
		return null

	return _current_target
