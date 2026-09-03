class_name TargetableComponent
extends Node


const TARGETABLE_GROUP: StringName = &"wor_combat_targetable"


@export_category("References")

@export
var actor: Node3D

@export
var target_point: Node3D


@export_category("Targeting")

@export
var enabled: bool = true

@export_range(-10.0, 10.0, 0.01)
var priority_bonus: float = 0.0


func _enter_tree() -> void:
	add_to_group(
		TARGETABLE_GROUP
	)


func _exit_tree() -> void:
	remove_from_group(
		TARGETABLE_GROUP
	)


func is_targetable() -> bool:
	return (
		enabled
		and actor != null
		and is_instance_valid(actor)
	)


func get_actor() -> Node3D:
	if not is_targetable():
		return null

	return actor


func get_target_position() -> Vector3:
	if (
		target_point != null
		and is_instance_valid(target_point)
	):
		return target_point.global_position

	if actor != null:
		return actor.global_position

	return Vector3.ZERO
