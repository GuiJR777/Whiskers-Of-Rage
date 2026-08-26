@tool
extends VBoxContainer

var _snapshots_by_path: Dictionary = {}
var _selector: OptionButton
var _status: Label
var _tree: Tree


func _ready() -> void:
	_build_ui()


func update_snapshots(_session_id: int, snapshots: Array) -> void:
	var selected_path := _selector.get_item_text(_selector.selected) \
		if _selector != null and _selector.selected >= 0 else ""
	_snapshots_by_path.clear()
	for snapshot_variant: Variant in snapshots:
		if snapshot_variant is Dictionary:
			var snapshot: Dictionary = snapshot_variant
			_snapshots_by_path[String(snapshot.get("path", "Unknown ASC"))] = snapshot
	_refresh_selector(selected_path)


func clear_runtime() -> void:
	_snapshots_by_path.clear()
	_refresh_selector("")


func _build_ui() -> void:
	if _selector != null:
		return
	var heading := Label.new()
	heading.text = "ASC Runtime Debugger"
	heading.add_theme_font_size_override("font_size", 16)
	add_child(heading)
	_status = Label.new()
	_status.text = "Execute uma cena para receber snapshots dos ASCs."
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_selector = OptionButton.new()
	_selector.disabled = true
	_selector.item_selected.connect(_on_asc_selected)
	add_child(_selector)
	_tree = Tree.new()
	_tree.columns = 2
	_tree.set_column_title(0, "Campo")
	_tree.set_column_title(1, "Valor")
	_tree.column_titles_visible = true
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.custom_minimum_size = Vector2(0.0, 320.0)
	add_child(_tree)


func _refresh_selector(previous_path: String) -> void:
	if _selector == null:
		return
	_selector.clear()
	var paths: Array[String] = []
	for path_variant: Variant in _snapshots_by_path.keys():
		paths.append(String(path_variant))
	paths.sort()
	for path: String in paths:
		_selector.add_item(path)
	_selector.disabled = paths.is_empty()
	_status.text = "Nenhum ASC encontrado na cena em execução." if paths.is_empty() \
		else "%d ASC(s) recebidos do runtime." % paths.size()
	if paths.is_empty():
		_tree.clear()
		return
	var selected_index := paths.find(previous_path)
	_selector.select(maxi(selected_index, 0))
	_show_snapshot(_snapshots_by_path[paths[maxi(selected_index, 0)]])


func _on_asc_selected(index: int) -> void:
	if index >= 0:
		_show_snapshot(_snapshots_by_path.get(_selector.get_item_text(index), {}))


func _show_snapshot(snapshot: Dictionary) -> void:
	_tree.clear()
	var root := _tree.create_item()
	_add_rows(root, "Attributes", snapshot.get("attributes", []), ["name", "base", "current"])
	_add_rows(root, "Tags", snapshot.get("tags", []), ["name", "count"])
	_add_rows(root, "Abilities", snapshot.get("abilities", []), ["handle", "tag", "state", "cooldown_remaining"])
	_add_rows(root, "Cooldowns", snapshot.get("cooldowns", []), ["ability", "remaining"])
	_add_rows(root, "Active Effects", snapshot.get("active_effects", []), ["handle", "id", "remaining", "stacks"])
	_add_rows(root, "Recent Events", snapshot.get("recent_events", []), ["tag", "payload_keys"])
	_add_rows(root, "Lifecycle Warnings", snapshot.get("lifecycle_warnings", []), [])


func _add_rows(parent: TreeItem, title: String, rows: Array, fields: Array[String]) -> void:
	var section := _tree.create_item(parent)
	section.set_text(0, "%s (%d)" % [title, rows.size()])
	section.set_selectable(0, false)
	section.set_selectable(1, false)
	for row_variant: Variant in rows:
		var item := _tree.create_item(section)
		if row_variant is Dictionary:
			var row: Dictionary = row_variant
			item.set_text(0, String(row.get(fields[0], "")) if not fields.is_empty() else "")
			var values: PackedStringArray = []
			for field_index: int in range(1, fields.size()):
				values.append("%s=%s" % [fields[field_index], str(row.get(fields[field_index], ""))])
			item.set_text(1, ", ".join(values))
		else:
			item.set_text(0, String(row_variant))
