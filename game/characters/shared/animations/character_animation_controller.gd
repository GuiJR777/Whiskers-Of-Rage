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

var _pending_action_state: StringName = &""


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
			% str(root_locomotion_state)
		)
		as AnimationNodeStateMachinePlayback
	)

	_action_playback = (
		animation_tree.get(
			"parameters/%s/playback"
			% str(root_action_state)
		)
		as AnimationNodeStateMachinePlayback
	)

	if _root_playback == null:
		push_error(
			"CharacterAnimationController could not find root playback."
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


func _process(_delta: float) -> void:
	if not _initialized:
		return

	if _pending_action_state != &"":
		_try_start_pending_action()


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

	# ========================================================================
	# Combo:
	# já estamos dentro da Action StateMachine.
	#
	# Attack01 -> Attack02 -> Attack03
	# ========================================================================

	if _action_active:
		_active_action_state = state_name
		_pending_action_state = &""

		if _action_playback.is_playing():
			_action_playback.travel(
				state_name,
				true
			)
		else:
			_action_playback.start(
				state_name,
				true
			)

		action_started.emit(
			state_name
		)

		return true

	# ========================================================================
	# Nova sequência:
	# Locomotion -> Action
	#
	# Primeiro pedimos ao Root para entrar em Action.
	# Só depois iniciamos o ataque.
	# ========================================================================

	_action_active = true

	_active_action_state = state_name

	_pending_action_state = state_name

	_enter_root_action_state()

	# Se o Root já conseguiu entrar imediatamente,
	# não precisamos esperar o próximo frame.
	_try_start_pending_action()

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

	_pending_action_state = &""

	# Não paramos a Action StateMachine.
	#
	# Apenas tiramos sua influência visual
	# voltando o Root para Locomotion.
	_apply_locomotion_state()

	_enter_root_locomotion_state()

	action_ended.emit(
		previous_state
	)


func is_action_active() -> bool:
	return _action_active


func get_active_action_state() -> StringName:
	return _active_action_state


# ============================================================================
# Root State Machine
# ============================================================================

func _enter_root_action_state() -> void:
	if _root_playback == null:
		return

	if not _root_playback.is_playing():
		_root_playback.start(
			root_action_state,
			true
		)
		return

	if (
		_root_playback.get_current_node()
		== root_action_state
	):
		return

	_root_playback.travel(
		root_action_state,
		true
	)


func _enter_root_locomotion_state() -> void:
	if _root_playback == null:
		return

	if not _root_playback.is_playing():
		_root_playback.start(
			root_locomotion_state,
			true
		)
		return

	if (
		_root_playback.get_current_node()
		== root_locomotion_state
	):
		return

	_root_playback.travel(
		root_locomotion_state,
		true
	)


func _try_start_pending_action() -> void:
	if not _action_active:
		return

	if _pending_action_state == &"":
		return

	if _root_playback == null:
		return

	if _action_playback == null:
		return

	# Muito importante:
	# só reiniciamos a Action StateMachine
	# quando o Root realmente chegou em Action.
	if (
		_root_playback.get_current_node()
		!= root_action_state
	):
		return

	var state_to_start := (
		_pending_action_state
	)

	_pending_action_state = &""

	# Isso é o "reset" que queríamos.
	#
	# Não precisa chamar stop().
	_action_playback.start(
		state_to_start,
		true
	)

	action_started.emit(
		state_to_start
	)


# ============================================================================
# AnimationTree Signals
# ============================================================================

func _on_action_state_finished(
	state_name: StringName
) -> void:
	if not _action_active:
		return

	# Attack01 pode emitir finished depois que
	# Attack02 já assumiu por causa do crossfade.
	if (
		state_name
		!= _active_action_state
	):
		return

	action_finished.emit(
		state_name
	)
