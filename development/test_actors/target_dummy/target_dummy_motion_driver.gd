class_name TargetDummyMotionDriver
extends Node


@export
var movement_component: MovementComponent


func _physics_process(
	delta: float
) -> void:
	if movement_component == null:
		return

	movement_component.move_passive(
		delta
	)
