class_name TargetingComponent
extends Node


signal target_locked(
	target: Node3D
)

signal target_unlocked(
	previous_target: Node3D
)

signal soft_target_acquired(
	target: Node3D
)

signal soft_target_cleared(
	previous_target: Node3D
)


@export_category("References")

@export
var owner_actor: Node3D


var _current_target: Node3D

var _soft_target: Node3D


# ============================================================================
# Hard Lock
# ============================================================================

func lock_target(
	target: Node3D
) -> void:
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

	var previous_target := (
		_current_target
	)

	_current_target = null

	target_unlocked.emit(
		previous_target
	)


func has_locked_target() -> bool:
	return (
		_current_target != null
		and is_instance_valid(
			_current_target
		)
	)


func get_locked_target() -> Node3D:
	if not has_locked_target():
		return null

	return _current_target


# ============================================================================
# Soft Target
# ============================================================================

func acquire_soft_target(
	reference_direction: Vector3,
	definition: AttackTargetingDefinition
) -> Node3D:
	clear_soft_target()

	if owner_actor == null:
		return null

	if definition == null:
		return null

	if not definition.enabled:
		return null

	# Hard Lock sempre ganha.
	if has_locked_target():
		_soft_target = (
			_current_target
		)

		soft_target_acquired.emit(
			_soft_target
		)

		return _soft_target

	var flat_reference := (
		reference_direction
	)

	flat_reference.y = 0.0

	if flat_reference.is_zero_approx():
		flat_reference = (
			-owner_actor
			.global_transform
			.basis.z
		)

		flat_reference.y = 0.0

	if flat_reference.is_zero_approx():
		return null

	flat_reference = (
		flat_reference.normalized()
	)

	var best_target: Node3D = null
	var best_score: float = -INF

	var candidates := (
		get_tree().get_nodes_in_group(
			TargetableComponent
			.TARGETABLE_GROUP
		)
	)

	for candidate_node: Node in candidates:
		var candidate := (
			candidate_node
			as TargetableComponent
		)

		if candidate == null:
			continue

		if not candidate.is_targetable():
			continue

		var target_actor := (
			candidate.get_actor()
		)

		if target_actor == null:
			continue

		if target_actor == owner_actor:
			continue

		var to_target := (
			candidate.get_target_position()
			- owner_actor.global_position
		)

		to_target.y = 0.0

		var distance := (
			to_target.length()
		)

		if distance <= 0.001:
			continue

		if (
			distance
			> definition.acquisition_range
		):
			continue

		var direction := (
			to_target / distance
		)

		var dot_value := clampf(
			flat_reference.dot(
				direction
			),
			-1.0,
			1.0
		)

		var angle_radians := acos(
			dot_value
		)

		var angle_degrees := rad_to_deg(
			angle_radians
		)

		if (
			angle_degrees
			> definition.max_angle_degrees
		):
			continue

		var score := (
			_calculate_target_score(
				distance,
				angle_degrees,
				candidate.priority_bonus,
				definition
			)
		)

		if score <= best_score:
			continue

		best_score = score
		best_target = target_actor

	if best_target == null:
		return null

	_soft_target = best_target

	soft_target_acquired.emit(
		_soft_target
	)

	return _soft_target


func clear_soft_target() -> void:
	if _soft_target == null:
		return

	var previous_target := (
		_soft_target
	)

	_soft_target = null

	soft_target_cleared.emit(
		previous_target
	)


func has_soft_target() -> bool:
	return (
		_soft_target != null
		and is_instance_valid(
			_soft_target
		)
	)


func get_soft_target() -> Node3D:
	if not has_soft_target():
		return null

	return _soft_target


# ============================================================================
# Preferred Target
# ============================================================================

func has_facing_target() -> bool:
	return (
		has_locked_target()
		or has_soft_target()
	)


func get_facing_target() -> Node3D:
	if has_locked_target():
		return get_locked_target()

	return get_soft_target()


func get_direction_to_facing_target() -> Vector3:
	if owner_actor == null:
		return Vector3.ZERO

	var target := (
		get_facing_target()
	)

	if target == null:
		return Vector3.ZERO

	var direction := (
		target.global_position
		- owner_actor.global_position
	)

	direction.y = 0.0

	if direction.is_zero_approx():
		return Vector3.ZERO

	return direction.normalized()


# ============================================================================
# Scoring
# ============================================================================

func _calculate_target_score(
	distance: float,
	angle_degrees: float,
	priority_bonus: float,
	definition: AttackTargetingDefinition
) -> float:
	var distance_score := (
		1.0
		- clampf(
			distance
			/ definition.acquisition_range,
			0.0,
			1.0
		)
	)

	var angle_score: float = 1.0

	if definition.max_angle_degrees > 0.0:
		angle_score = (
			1.0
			- clampf(
				angle_degrees
				/ definition.max_angle_degrees,
				0.0,
				1.0
			)
		)

	var total_weight := (
		definition.angle_weight
		+ definition.distance_weight
	)

	if total_weight <= 0.0:
		return priority_bonus

	var score := (
		angle_score
		* definition.angle_weight
		+
		distance_score
		* definition.distance_weight
	)

	return (
		score / total_weight
		+ priority_bonus
	)
