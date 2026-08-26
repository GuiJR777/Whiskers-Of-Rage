@tool
extends EditorProperty

const CATALOG_SETTING: StringName = &"wor_gameplay_framework/tags/catalog_path"

var _catalog: GameplayTagCatalog
var _selector: OptionButton
var _list: ItemList


func _init() -> void:
	var root := VBoxContainer.new()
	add_child(root)
	var picker := HBoxContainer.new()
	_selector = OptionButton.new()
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.add_child(_selector)
	var add_button := Button.new()
	add_button.text = "Adicionar"
	add_button.pressed.connect(_add_selected_tag)
	picker.add_child(add_button)
	root.add_child(picker)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0.0, 90.0)
	_list.allow_reselect = true
	root.add_child(_list)
	var remove_button := Button.new()
	remove_button.text = "Remover selecionada"
	remove_button.pressed.connect(_remove_selected_tag)
	root.add_child(remove_button)
	_load_options()


func _update_property() -> void:
	_list.clear()
	var current: Variant = get_edited_object().get(get_edited_property())
	if current is Array:
		for tag_variant: Variant in current:
			var tag := tag_variant as GameplayTag
			_list.add_item(String(tag.tag_name) if tag != null else "<tag nula>")


func _load_options() -> void:
	_selector.clear()
	var catalog_path := String(ProjectSettings.get_setting(CATALOG_SETTING, "res://gameplay_tags.tres"))
	_catalog = ResourceLoader.load(catalog_path, "GameplayTagCatalog") as GameplayTagCatalog
	if _catalog == null:
		_selector.disabled = true
		_selector.tooltip_text = "Crie o catálogo no dock GAS > Tags."
		return
	for tag_name: StringName in _catalog.get_tag_names():
		_selector.add_item(String(tag_name))
		_selector.set_item_metadata(_selector.item_count - 1, tag_name)
	_selector.disabled = _selector.item_count == 0


func _add_selected_tag() -> void:
	if _catalog == null or _selector.selected < 0:
		return
	var selected_name := StringName(_selector.get_item_metadata(_selector.selected))
	var current: Array[GameplayTag] = []
	for tag_variant: Variant in get_edited_object().get(get_edited_property()):
		var tag := tag_variant as GameplayTag
		if tag != null:
			if tag.tag_name == selected_name:
				return
			current.append(tag)
	current.append(_catalog.get_tag(selected_name))
	emit_changed(get_edited_property(), current)


func _remove_selected_tag() -> void:
	var selected_indices := _list.get_selected_items()
	if selected_indices.is_empty():
		return
	var remove_index := selected_indices[0]
	var current: Array[GameplayTag] = []
	var source: Variant = get_edited_object().get(get_edited_property())
	for index: int in source.size():
		if index != remove_index:
			current.append(source[index] as GameplayTag)
	emit_changed(get_edited_property(), current)
