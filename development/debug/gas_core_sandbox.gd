extends Node

@onready var source_asc: AbilitySystemComponent = $SourceASC
@onready var target_asc: AbilitySystemComponent = $TargetASC


func _ready() -> void:
	var health := GameplayAttribute.new()
	health.attribute_name = &"Health"
	health.default_value = 100.0
	health.minimum_value = 0.0
	health.maximum_value = 100.0

	var attributes := GameplayAttributeSet.new()
	attributes.attributes = [health]
	source_asc.initial_attribute_sets = [attributes]
	target_asc.initial_attribute_sets = [attributes]
	if not source_asc.initialize() or not target_asc.initialize():
		push_error("GAS sandbox could not initialize its ASCs.")
		return

	var damage_modifier := GameplayModifier.new()
	damage_modifier.attribute = health
	damage_modifier.operation = GameplayModifier.Operation.ADD
	damage_modifier.magnitude = -20.0

	var damage_effect := GameplayEffect.new()
	damage_effect.effect_id = &"Effect.Damage.Sandbox"
	damage_effect.duration_policy = GameplayEffect.DurationPolicy.INSTANT
	damage_effect.modifiers = [damage_modifier]

	var context := AbilityContext.create(source_asc, target_asc, self)
	target_asc.apply_gameplay_effect(damage_effect, context)
	print("GAS_SANDBOX: source Health=%.1f, target Health=%.1f" % [
		source_asc.get_attribute_value(&"Health"),
		target_asc.get_attribute_value(&"Health"),
	])

