class_name HurtboxComponent
extends Area3D


@export_category("Gameplay")

@export
var ability_system: AbilitySystemComponent


func _ready() -> void:
	if ability_system == null:
		push_error(
			"HurtboxComponent requires an AbilitySystemComponent."
		)

	# Hurtbox não precisa procurar colisões.
	# Ela apenas precisa poder ser encontrada por Hitboxes.
	monitoring = false
	monitorable = true


func get_ability_system() -> AbilitySystemComponent:
	return ability_system
