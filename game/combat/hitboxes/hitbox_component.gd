class_name HitboxComponent
extends Area3D


signal activation_started(
	attack: MeleeAttackDefinition
)

signal activation_ended(
	attack: MeleeAttackDefinition
)

signal hit_confirmed(
	hurtbox: HurtboxComponent,
	context: AbilityContext
)


@export_category("Gameplay")

@export
var source_asc: AbilitySystemComponent

@export
var instigator: Node3D


var _active_attack: MeleeAttackDefinition

var _remaining_time: float = 0.0

var _is_active: bool = false

var _hit_targets: Dictionary = {}


func _ready() -> void:
	if source_asc == null:
		push_error(
			"HitboxComponent requires a source AbilitySystemComponent."
		)

	if instigator == null:
		push_error(
			"HitboxComponent requires an instigator."
		)

	monitoring = false

	area_entered.connect(
		_on_area_entered
	)

	set_physics_process(false)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	_remaining_time -= delta

	if _remaining_time <= 0.0:
		deactivate()


func try_activate_attack(
	attack: MeleeAttackDefinition
) -> bool:
	if _is_active:
		return false

	if attack == null:
		push_error(
			"HitboxComponent received a null attack."
		)
		return false

	var validation_errors := attack.validate()

	if not validation_errors.is_empty():
		push_error(
			"Cannot activate invalid melee attack: %s"
			% "; ".join(validation_errors)
		)
		return false

	if source_asc == null:
		return false

	_active_attack = attack

	_remaining_time = (
		attack.hitbox_active_time
	)

	_hit_targets.clear()

	_is_active = true

	set_physics_process(true)

	set_deferred(
		"monitoring",
		true
	)

	activation_started.emit(
		_active_attack
	)

	return true


func deactivate() -> void:
	if not _is_active:
		return

	var previous_attack := _active_attack

	_is_active = false
	_active_attack = null
	_remaining_time = 0.0

	_hit_targets.clear()

	set_physics_process(false)

	set_deferred(
		"monitoring",
		false
	)

	activation_ended.emit(
		previous_attack
	)


func is_active() -> bool:
	return _is_active


func _on_area_entered(
	area: Area3D
) -> void:
	if not _is_active:
		return

	if _active_attack == null:
		return

	var hurtbox := (
		area as HurtboxComponent
	)

	if hurtbox == null:
		return

	var target_asc := (
		hurtbox.get_ability_system()
	)

	if target_asc == null:
		return

	# Nunca acertar o próprio ASC.
	if target_asc == source_asc:
		return

	var target_id := (
		target_asc.get_instance_id()
	)

	# Um mesmo ataque só acerta
	# o mesmo ator uma vez.
	if _hit_targets.has(target_id):
		return

	_hit_targets[target_id] = true

	var context := AbilityContext.create(
		source_asc,
		target_asc,
		instigator
	)

	context.world_position = (
		hurtbox.global_position
	)

	context.hit_direction = (
		hurtbox.global_position
		- instigator.global_position
	).normalized()

	context.source_object = self

	target_asc.apply_gameplay_effect(
		_active_attack.hit_effect,
		context
	)

	hit_confirmed.emit(
		hurtbox,
		context
	)
