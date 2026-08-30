class_name CharacterAnimationController
extends Node


signal locomotion_state_changed(
	state_name: StringName
)

signal action_started(
	state_name: StringName
)

signal action_finished(
	state_name: StringName
)

signal action_ended(
	state_name: StringName
)


# ============================================================================
# References
# ============================================================================

@export_category("References")

@export
var animation_tree: AnimationTree


# ============================================================================
# AnimationTree State Machines
# ============================================================================

@export_category("Root States")

@export
var root_locomotion_state: StringName = &"Locomotion"

@export
var root_action_state: StringName = &"Action"


@export_category("Locomotion")

@export
var initial_locomotion_state: StringName = &"idle"


# ============================================================================
# Runtime
# ============================================================================

var _root_playback: AnimationNodeStateMachinePlayback

var _locomotion_playback: AnimationNodeStateMachinePlayback

var _action_playback: AnimationNodeStateMachinePlayback


var _desired_locomotion_state: StringName = &""

var _active_action_state: StringName = &""

var _action_active: bool = false

var _initialized: bool = false


# ============================================================================
# Godot Lifecycle
# ============================================================================

func _ready() -> void:
	if animation_tree == null:
		push_error(
			"CharacterAnimationController requires an AnimationTree."
		)
		return

	animation_tree.active = true

	_root_playback = (
		animation_tree.get(
			"parameters/playback"
		)
		as AnimationNodeStateMachinePlayback
	)

	_locomotion_playback = (
		animation_tree.get(
			"parameters/%s/playback"
			% String(root_locomotion_state)
		)
		as AnimationNodeStateMachinePlayback
	)

	_action_playback = (
		animation_tree.get(
			"parameters/%s/playback"
			% String(root_action_state)
		)
		as AnimationNodeStateMachinePlayback
	)

	if _root_playback == null:
		push_error(
			"CharacterAnimationController could not find root AnimationTree playback."
		)
		return

	if _locomotion_playback == null:
		push_error(
			"CharacterAnimationController could not find Locomotion playback."
		)
		return

	if _action_playback == null:
		push_error(
			"CharacterAnimationController could not find Action playback."
		)
		return

	_action_playback.state_finished.connect(
		_on_action_state_finished
	)

	call_deferred(
		"_initialize_playback"
	)


func _initialize_playback() -> void:
	_desired_locomotion_state = (
		initial_locomotion_state
	)

	_locomotion_playback.start(
		_desired_locomotion_state,
		true
	)

	_root_playback.start(
		root_locomotion_state,
		true
	)

	_initialized = true


# ============================================================================
# Locomotion
# ============================================================================

func set_locomotion_state(
	state_name: StringName
) -> void:
	if state_name == &"":
		return

	if (
		_desired_locomotion_state
		== state_name
	):
		return

	_desired_locomotion_state = (
		state_name
	)

	if _initialized:
		_apply_locomotion_state()

	locomotion_state_changed.emit(
		state_name
	)


func get_locomotion_state() -> StringName:
	return _desired_locomotion_state


func _apply_locomotion_state() -> void:
	if _locomotion_playback == null:
		return

	if _desired_locomotion_state == &"":
		return

	if not _locomotion_playback.is_playing():
		_locomotion_playback.start(
			_desired_locomotion_state,
			true
		)

		return

	if (
		_locomotion_playback.get_current_node()
		== _desired_locomotion_state
	):
		return

	_locomotion_playback.travel(
		_desired_locomotion_state,
		true
	)


# ============================================================================
# Actions
# ============================================================================

func play_action(
	state_name: StringName
) -> bool:
	if not _initialized:
		return false

	if state_name == &"":
		return false

	if _action_playback == null:
		return false

	var was_active := _action_active

	# Atualizamos primeiro para que o state_finished
	# da animação anterior de um crossfade seja ignorado.
	_action_active = true
	_active_action_state = state_name

	if was_active:
		_action_playback.travel(
			state_name,
			true
		)
	else:
		_action_playback.start(
			state_name,
			true
		)

		_root_playback.travel(
			root_action_state,
			true
		)

	action_started.emit(
		state_name
	)

	return true


func end_action(
	expected_state: StringName = &""
) -> void:
	if not _action_active:
		return

	if (
		expected_state != &""
		and expected_state
			!= _active_action_state
	):
		return

	var previous_state := (
		_active_action_state
	)

	_action_active = false
	_active_action_state = &""

	# Enquanto o ataque estava visualmente ativo,
	# a HFSM continuou atualizando esse estado.
	_apply_locomotion_state()

	_root_playback.travel(
		root_locomotion_state,
		true
	)

	action_ended.emit(
		previous_state
	)


func is_action_active() -> bool:
	return _action_active


func get_active_action_state() -> StringName:
	return _active_action_state


# ============================================================================
# AnimationTree Signals
# ============================================================================

func _on_action_state_finished(
	state_name: StringName
) -> void:
	if not _action_active:
		return

	# Durante Attack01 -> Attack02 existe crossfade.
	# Attack01 eventualmente emitirá state_finished,
	# mas neste momento Attack02 já é o estado ativo.
	if state_name != _active_action_state:
		return

	action_finished.emit(
		state_name
	)
