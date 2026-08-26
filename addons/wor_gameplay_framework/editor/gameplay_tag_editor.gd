@tool
extends VBoxContainer

const CATALOG_SETTING: StringName = &"wor_gameplay_framework/tags/catalog_path"

var _editor_interface: EditorInterface
var _catalog: GameplayTagCatalog
var _catalog_path: String
var _search: LineEdit
var _tree: Tree
var _tag_name: LineEdit
var _feedback: Label


func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_build_ui()
	_load_catalog()


func _build_ui() -> void:
	var heading := Label.new()
	heading.text = "Gameplay Tag Editor"
	heading.add_theme_font_size_override("font_size", 16)
	add_child(heading)
	var help := Label.new()
	help.text = "O catálogo preserva referências: renomear atualiza todos os Resources que usam a mesma tag."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar tag..."
	_search.text_changed.connect(func(_value: String) -> void: _rebuild_tree())
	add_child(_search)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.custom_minimum_size = Vector2(0.0, 260.0)
	_tree.item_selected.connect(_on_tree_item_selected)
	add_child(_tree)
	_tag_name = LineEdit.new()
	_tag_name.placeholder_text = "State.Stunned"
	_tag_name.text_submitted.connect(func(_value: String) -> void: _add_tag())
	add_child(_tag_name)
	var buttons := HBoxContainer.new()
	for definition: Dictionary in [
		{"label": "Adicionar", "callback": _add_tag},
		{"label": "Renomear", "callback": _rename_tag},
		{"label": "Remover", "callback": _remove_tag},
		{"label": "Recarregar", "callback": _load_catalog},
	]:
		var button := Button.new()
		button.text = definition.label
		button.pressed.connect(definition.callback)
		buttons.add_child(button)
	add_child(buttons)
	_feedback = Label.new()
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_feedback)


func _load_catalog() -> void:
	_catalog_path = String(ProjectSettings.get_setting(CATALOG_SETTING, "res://gameplay_tags.tres"))
	_catalog = ResourceLoader.load(_catalog_path, "GameplayTagCatalog") as GameplayTagCatalog
	if _catalog == null:
		_catalog = GameplayTagCatalog.new()
		var save_error := ResourceSaver.save(_catalog, _catalog_path)
		if save_error != OK:
			_set_feedback("Não foi possível criar o catálogo em %s (erro %d)." % [_catalog_path, save_error], true)
			return
	_set_feedback("Catálogo: %s" % _catalog_path, false)
	_rebuild_tree()


func _rebuild_tree() -> void:
	_tree.clear()
	if _catalog == null:
		return
	var root := _tree.create_item()
	var items_by_path: Dictionary = {}
	var query := _search.text.strip_edges().to_lower()
	for tag_name: StringName in _catalog.get_tag_names():
		var full_name := String(tag_name)
		if not query.is_empty() and query not in full_name.to_lower():
			continue
		var parent := root
		var current_path := ""
		for segment: String in full_name.split("."):
			current_path = segment if current_path.is_empty() else current_path + "." + segment
			var item: TreeItem = items_by_path.get(current_path)
			if item == null:
				item = _tree.create_item(parent)
				item.set_text(0, segment)
				item.set_metadata(0, current_path)
				items_by_path[current_path] = item
			parent = item
	for path_variant: Variant in items_by_path.keys():
		var path := StringName(path_variant)
		var item: TreeItem = items_by_path[path_variant]
		var is_registered := _catalog.get_tag(path) != null
		item.set_selectable(0, is_registered)
		if not is_registered:
			item.set_custom_color(0, Color(0.65, 0.65, 0.65))
	_tree.expand_all()


func _on_tree_item_selected() -> void:
	var item := _tree.get_selected()
	if item != null:
		_tag_name.text = String(item.get_metadata(0))


func _add_tag() -> void:
	var new_name := StringName(_tag_name.text.strip_edges())
	if not GameplayTag.is_valid_tag_name(new_name):
		_set_feedback("Tag inválida. Use segmentos não vazios separados por ponto.", true)
		return
	if not _catalog.add_tag_name(new_name):
		_set_feedback("A tag '%s' já existe." % String(new_name), true)
		return
	_save_and_refresh("Tag '%s' adicionada." % String(new_name))


func _rename_tag() -> void:
	var item := _tree.get_selected()
	if item == null:
		_set_feedback("Selecione uma tag registrada para renomear.", true)
		return
	var old_name := StringName(item.get_metadata(0))
	var new_name := StringName(_tag_name.text.strip_edges())
	if not _catalog.rename_tag(old_name, new_name):
		_set_feedback("Não foi possível renomear: destino inválido ou duplicado.", true)
		return
	_save_and_refresh("Tag '%s' renomeada para '%s'." % [String(old_name), String(new_name)])


func _remove_tag() -> void:
	var item := _tree.get_selected()
	if item == null:
		_set_feedback("Selecione uma tag registrada para remover.", true)
		return
	var tag_name := StringName(item.get_metadata(0))
	if not _catalog.remove_tag_name(tag_name):
		_set_feedback("A tag selecionada não está registrada no catálogo.", true)
		return
	_save_and_refresh("Tag '%s' removida do catálogo." % String(tag_name))


func _save_and_refresh(message: String) -> void:
	var validation_errors := _catalog.validate()
	if not validation_errors.is_empty():
		_set_feedback("Catálogo inválido: %s" % "; ".join(validation_errors), true)
		return
	var save_error := ResourceSaver.save(_catalog, _catalog_path)
	if save_error != OK:
		_set_feedback("Falha ao salvar o catálogo (erro %d)." % save_error, true)
		return
	_editor_interface.get_resource_filesystem().scan()
	_set_feedback(message, false)
	_rebuild_tree()


func _set_feedback(message: String, is_error: bool) -> void:
	_feedback.text = message
	_feedback.modulate = Color(1.0, 0.45, 0.45) if is_error else Color(0.65, 1.0, 0.65)
