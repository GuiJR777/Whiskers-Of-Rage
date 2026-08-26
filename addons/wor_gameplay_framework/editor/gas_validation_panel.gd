@tool
extends VBoxContainer

var _resource: Resource
var _heading: Label
var _details: Label


func setup(resource: Resource) -> void:
	_resource = resource
	_build_ui()
	if not _resource.changed.is_connected(_refresh):
		_resource.changed.connect(_refresh)
	_refresh()


func _exit_tree() -> void:
	if _resource != null and _resource.changed.is_connected(_refresh):
		_resource.changed.disconnect(_refresh)


func _build_ui() -> void:
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 14)
	add_child(_heading)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_details)
	var separator := HSeparator.new()
	add_child(separator)


func _refresh() -> void:
	if _resource == null or not _resource.has_method("validate"):
		return
	var validation_result: Variant = _resource.call("validate")
	var errors := PackedStringArray(validation_result) if validation_result is PackedStringArray else PackedStringArray()
	if errors.is_empty():
		_heading.text = "✓ Configuração válida"
		_heading.modulate = Color(0.45, 1.0, 0.55)
		_details.text = "O Resource atende às validações do framework."
	else:
		_heading.text = "⚠ %d problema(s) de configuração" % errors.size()
		_heading.modulate = Color(1.0, 0.65, 0.25)
		var lines := PackedStringArray()
		for error: String in errors:
			lines.append("• " + error)
		_details.text = "\n".join(lines)
