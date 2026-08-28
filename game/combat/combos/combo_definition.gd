class_name ComboDefinition
extends Resource


@export_category("Identity")

@export
var combo_id: StringName = &""


@export_category("Input")

@export
var input_action: StringName = &"light_attack"

@export_range(0.0, 0.5, 0.01)
var input_buffer_time: float = 0.25


@export_category("Steps")

@export
var steps: Array[ComboStep] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if combo_id == &"":
		errors.append(
			"ComboDefinition.combo_id cannot be empty."
		)

	if input_action == &"":
		errors.append(
			"ComboDefinition.input_action cannot be empty."
		)

	if steps.is_empty():
		errors.append(
			"ComboDefinition requires at least one step."
		)

	for index: int in steps.size():
		var step := steps[index]

		if step == null:
			errors.append(
				"Combo step %d is null."
				% index
			)

			continue

		for step_error: String in step.validate():
			errors.append(
				"Step %d: %s"
				% [
					index,
					step_error,
				]
			)

	return errors
