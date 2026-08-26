@tool
extends EditorInspectorPlugin

const ValidationPanelScript := preload("res://addons/wor_gameplay_framework/editor/gas_validation_panel.gd")
const TagPropertyEditorScript := preload("res://addons/wor_gameplay_framework/editor/gameplay_tag_property_editor.gd")
const TagArrayPropertyEditorScript := preload("res://addons/wor_gameplay_framework/editor/gameplay_tag_array_property_editor.gd")


func _can_handle(object: Object) -> bool:
	return object is Resource and object.has_method("validate")


func _parse_begin(object: Object) -> void:
	var panel := ValidationPanelScript.new()
	panel.setup(object as Resource)
	add_custom_control(panel)


func _parse_property(
	_object: Object,
	type: Variant.Type,
	name: String,
	hint_type: PropertyHint,
	hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	if type == TYPE_OBJECT and hint_type == PROPERTY_HINT_RESOURCE_TYPE \
		and hint_string == "GameplayTag":
		var editor := TagPropertyEditorScript.new()
		add_property_editor(name, editor)
		return true
	if type == TYPE_ARRAY and "GameplayTag" in hint_string:
		var array_editor := TagArrayPropertyEditorScript.new()
		add_property_editor(name, array_editor)
		return true
	return false
