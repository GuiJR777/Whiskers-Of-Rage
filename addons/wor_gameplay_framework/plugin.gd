@tool
extends EditorPlugin

const CATALOG_SETTING: StringName = &"wor_gameplay_framework/tags/catalog_path"
const DEFAULT_CATALOG_PATH: String = "res://gameplay_tags.tres"
const DEBUG_AUTOLOAD_NAME: String = "WORGasRuntimeDebug"
const DEBUG_BRIDGE_PATH: String = "res://addons/wor_gameplay_framework/runtime/debug/gas_runtime_debug_bridge.gd"
const MainScreenScript := preload("res://addons/wor_gameplay_framework/editor/gas_editor_dock.gd")
const InspectorPluginScript := preload("res://addons/wor_gameplay_framework/editor/gas_inspector_plugin.gd")
const DebuggerPluginScript := preload("res://addons/wor_gameplay_framework/editor/gas_editor_debugger_plugin.gd")

var _dock: Control
var _inspector_plugin: EditorInspectorPlugin
var _debugger_plugin: EditorDebuggerPlugin


func _enter_tree() -> void:
	_ensure_project_settings()
	_remove_legacy_docks()
	if not ProjectSettings.has_setting("autoload/%s" % DEBUG_AUTOLOAD_NAME):
		add_autoload_singleton(DEBUG_AUTOLOAD_NAME, DEBUG_BRIDGE_PATH)
	_dock = MainScreenScript.new()
	_dock.setup(get_editor_interface())
	EditorInterface.get_editor_main_screen().add_child(_dock)
	_make_visible(false)
	_inspector_plugin = InspectorPluginScript.new()
	add_inspector_plugin(_inspector_plugin)
	_debugger_plugin = DebuggerPluginScript.new()
	_debugger_plugin.snapshots_received.connect(_dock.update_runtime_snapshots)
	_debugger_plugin.runtime_stopped.connect(func(_session_id: int) -> void:
		if _dock != null:
			_dock.clear_runtime_debugger()
	)
	add_debugger_plugin(_debugger_plugin)


func _exit_tree() -> void:
	if _debugger_plugin != null:
		remove_debugger_plugin(_debugger_plugin)
		_debugger_plugin = null
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null
	if _dock != null:
		if _dock.get_parent() != EditorInterface.get_editor_main_screen():
			remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if ProjectSettings.has_setting("autoload/%s" % DEBUG_AUTOLOAD_NAME):
		remove_autoload_singleton(DEBUG_AUTOLOAD_NAME)


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if _dock != null:
		_dock.visible = visible


func _get_plugin_name() -> String:
	return "GAS"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")


func _ensure_project_settings() -> void:
	if not ProjectSettings.has_setting(CATALOG_SETTING):
		ProjectSettings.set_setting(CATALOG_SETTING, DEFAULT_CATALOG_PATH)
	ProjectSettings.set_initial_value(CATALOG_SETTING, DEFAULT_CATALOG_PATH)
	ProjectSettings.add_property_info({
		"name": CATALOG_SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
	})


func _remove_legacy_docks() -> void:
	for control_variant: Variant in EditorInterface.get_base_control().find_children(
		"GAS",
		"Control",
		true,
		false
	):
		var control := control_variant as Control
		if control != null and control.get_parent() != null \
			and control.get_parent().get_class() == "EditorDock":
			remove_control_from_docks(control)
			control.queue_free()
