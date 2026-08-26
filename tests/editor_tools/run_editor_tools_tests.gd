extends SceneTree

const DockScript := preload("res://addons/wor_gameplay_framework/editor/gas_editor_dock.gd")
const InspectorScript := preload("res://addons/wor_gameplay_framework/editor/gas_inspector_plugin.gd")
const DebuggerScript := preload("res://addons/wor_gameplay_framework/editor/gas_editor_debugger_plugin.gd")
const PluginScript := preload("res://addons/wor_gameplay_framework/plugin.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures := EditorToolsM3TestSuite.run()
	if DockScript == null or InspectorScript == null or DebuggerScript == null or PluginScript == null:
		failures.append("Editor tooling scripts must load successfully.")
	if failures.is_empty():
		print("EDITOR_TOOLS_M3_TESTS: PASS")
		quit(0)
		return
	for failure: String in failures:
		push_error(failure)
	print("EDITOR_TOOLS_M3_TESTS: FAIL (%d)" % failures.size())
	quit(1)
