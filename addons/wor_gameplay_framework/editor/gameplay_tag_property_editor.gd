@tool
extends EditorProperty

const CATALOG_SETTING: StringName = &"wor_gameplay_framework/tags/catalog_path"

var _selector: OptionButton
var _catalog: GameplayTagCatalog


func _init() -> void:
	_selector = OptionButton.new()
	_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selector.item_selected.connect(_on_item_selected)
	add_child(_selector)
	_load_options()


func _update_property() -> void:
	var current := get_edited_object().get(get_edited_property()) as GameplayTag
	var current_name := current.tag_name if current != null else &""
	for index: int in _selector.item_count:
		if StringName(_selector.get_item_metadata(index)) == current_name:
			_selector.select(index)
			return
	_selector.select(0)


func _load_options() -> void:
	_selector.clear()
	_selector.add_item("<nenhuma>")
	_selector.set_item_metadata(0, &"")
	var catalog_path := String(ProjectSettings.get_setting(CATALOG_SETTING, "res://gameplay_tags.tres"))
	_catalog = ResourceLoader.load(catalog_path, "GameplayTagCatalog") as GameplayTagCatalog
	if _catalog == null:
		_selector.disabled = true
		_selector.tooltip_text = "Crie o catálogo no dock GAS > Tags."
		return
	for tag_name: StringName in _catalog.get_tag_names():
		_selector.add_item(String(tag_name))
		_selector.set_item_metadata(_selector.item_count - 1, tag_name)


func _on_item_selected(index: int) -> void:
	var tag_name := StringName(_selector.get_item_metadata(index))
	var value: GameplayTag = null if tag_name == &"" else _catalog.get_tag(tag_name)
	emit_changed(get_edited_property(), value)
