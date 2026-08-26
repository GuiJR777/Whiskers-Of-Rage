@tool
extends VBoxContainer

var _editor_interface: EditorInterface
var _title: String
var _accepted_script_classes: Array[StringName] = []
var _new_resource_script: Script
var _list: ItemList
var _dialog: FileDialog
var _status: Label


func setup(
	editor_interface: EditorInterface,
	title: String,
	accepted_script_classes: Array[StringName],
	new_resource_script: Script
) -> void:
	_editor_interface = editor_interface
	_title = title
	_accepted_script_classes = accepted_script_classes
	_new_resource_script = new_resource_script
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var heading := Label.new()
	heading.text = _title
	heading.add_theme_font_size_override("font_size", 16)
	add_child(heading)
	var buttons := HBoxContainer.new()
	var create_button := Button.new()
	create_button.text = "Novo Resource"
	create_button.pressed.connect(_show_create_dialog)
	buttons.add_child(create_button)
	var refresh_button := Button.new()
	refresh_button.text = "Atualizar"
	refresh_button.pressed.connect(_refresh)
	buttons.add_child(refresh_button)
	add_child(buttons)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0.0, 320.0)
	_list.item_activated.connect(_open_item)
	add_child(_list)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_dialog = FileDialog.new()
	_dialog.access = FileDialog.ACCESS_RESOURCES
	_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_dialog.filters = PackedStringArray(["*.tres ; Godot Resource"])
	_dialog.file_selected.connect(_create_resource)
	add_child(_dialog)


func _refresh() -> void:
	_list.clear()
	var paths: Array[String] = []
	_collect_resource_paths("res://", paths)
	paths.sort()
	for path: String in paths:
		var resource := ResourceLoader.load(path)
		if resource == null or resource.get_script() == null:
			continue
		var script: Script = resource.get_script()
		if script.get_global_name() not in _accepted_script_classes:
			continue
		_list.add_item(path.trim_prefix("res://"))
		_list.set_item_metadata(_list.item_count - 1, path)
	_status.text = "%d Resource(s) encontrado(s). Dê duplo clique para editar no Inspector." % _list.item_count


func _collect_resource_paths(directory_path: String, result: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var path := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_resource_paths(path, result)
		elif entry.get_extension().to_lower() == "tres":
			result.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


func _show_create_dialog() -> void:
	_dialog.current_file = "new_%s.tres" % _title.to_snake_case()
	_dialog.popup_centered_ratio(0.55)


func _create_resource(path: String) -> void:
	var resource := _new_resource_script.new() as Resource
	if resource == null:
		_status.text = "Não foi possível instanciar o tipo configurado."
		return
	var save_error := ResourceSaver.save(resource, path)
	if save_error != OK:
		_status.text = "Falha ao salvar %s (erro %d)." % [path, save_error]
		return
	_editor_interface.get_resource_filesystem().scan()
	_refresh()
	_editor_interface.edit_resource(resource)


func _open_item(index: int) -> void:
	var resource := ResourceLoader.load(String(_list.get_item_metadata(index)))
	if resource != null:
		_editor_interface.edit_resource(resource)
