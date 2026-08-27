class_name ThirdPersonCameraController
extends Node


@export_category("References")

@export
var phantom_camera: Node3D


@export_category("Mouse")

@export_range(0.01, 1.0, 0.01)
var mouse_sensitivity: float = 0.10


@export_category("Gamepad")

@export_range(10.0, 500.0, 1.0)
var gamepad_rotation_speed: float = 140.0


@export_category("Rotation Limits")

@export_range(-89.9, 0.0, 0.1)
var min_pitch: float = -60.0

@export_range(0.0, 89.9, 0.1)
var max_pitch: float = 50.0


func _ready() -> void:
	if phantom_camera == null:
		push_error(
			"ThirdPersonCameraController requires a PhantomCamera3D."
		)
		return

	if not phantom_camera.has_method(
		"get_third_person_rotation_degrees"
	):
		push_error(
			"Assigned node is not a valid PhantomCamera3D."
		)
		return

	InputManager.capture_mouse()


func _process(delta: float) -> void:
	if phantom_camera == null:
		return

	_process_mouse()
	_process_gamepad(delta)


func _process_mouse() -> void:
	var mouse_delta: Vector2 = (
		InputManager.consume_mouse_delta()
	)

	if mouse_delta.is_zero_approx():
		return

	_rotate_camera(
		mouse_delta.x * mouse_sensitivity,
		mouse_delta.y * mouse_sensitivity
	)


func _process_gamepad(delta: float) -> void:
	var look_input: Vector2 = (
		InputManager.get_look_vector()
	)

	if look_input.is_zero_approx():
		return

	_rotate_camera(
		look_input.x
			* gamepad_rotation_speed
			* delta,

		look_input.y
			* gamepad_rotation_speed
			* delta
	)


func _rotate_camera(
	yaw_delta: float,
	pitch_delta: float
) -> void:
	var rotation_degrees: Vector3 = (
		phantom_camera.call(
			"get_third_person_rotation_degrees"
		)
	)

	# Vertical
	rotation_degrees.x -= pitch_delta

	rotation_degrees.x = clampf(
		rotation_degrees.x,
		min_pitch,
		max_pitch
	)

	# Horizontal
	rotation_degrees.y -= yaw_delta

	rotation_degrees.y = wrapf(
		rotation_degrees.y,
		0.0,
		360.0
	)

	phantom_camera.call(
		"set_third_person_rotation_degrees",
		rotation_degrees
	)
