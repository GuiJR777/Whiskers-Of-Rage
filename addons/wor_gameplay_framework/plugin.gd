@tool
extends EditorPlugin

const CATALOG_SETTING: StringName = &"wor_gameplay_framework/tags/catalog_path"
const DEFAULT_CATALOG_PATH: String = "res://gameplay_tags.tres"
const DEBUG_AUTOLOAD_NAME: String = "WORGasRuntimeDebug"
const DEBUG_BRIDGE_PATH: String = "res://addons/wor_gameplay_framework/runtime/debug/gas_runtime_debug_bridge.gd"
const DockScript := preload("res://addons/wor_gameplay_framework/editor/gas_editor_dock.gd")
const InspectorPluginScript := preload("res://addons/wor_gameplay_framework/editor/gas_inspector_plugin.gd")
const DebuggerPluginScript := preload("res://addons/wor_gameplay_framework/editor/gas_editor_debugger_plugin.gd")

var _dock: Control
var _inspector_plugin: EditorInspectorPlugin
var _debugger_plugin: EditorDebuggerPlugin


func _enter_tree() -> void:
	_ensure_project_settings()
	if not ProjectSettings.has_setting("autoload/%s" % DEBUG_AUTOLOAD_NAME):
		add_autoload_singleton(DEBUG_AUTOLOAD_NAME, DEBUG_BRIDGE_PATH)
	_dock = DockScript.new()
	_dock.setup(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)
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
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	if ProjectSettings.has_setting("autoload/%s" % DEBUG_AUTOLOAD_NAME):
		remove_autoload_singleton(DEBUG_AUTOLOAD_NAME)


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
