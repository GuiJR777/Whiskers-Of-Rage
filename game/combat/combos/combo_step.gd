class_name ComboStep
extends Resource


@export
var ability_tag: GameplayTag


@export
var requires_hit_confirm_to_advance: bool = true


func validate() -> PackedStringArray:
	var errors := PackedStringArray()

	if (
		ability_tag == null
		or not ability_tag.is_valid()
	):
		errors.append(
			"ComboStep requires a valid ability_tag."
		)

	return errors
