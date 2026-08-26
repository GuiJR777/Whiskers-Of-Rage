@tool
extends VBoxContainer

const TagEditorScript := preload("res://addons/wor_gameplay_framework/editor/gameplay_tag_editor.gd")
const ResourceBrowserScript := preload("res://addons/wor_gameplay_framework/editor/gas_resource_browser.gd")
const RuntimeDebuggerPanelScript := preload("res://addons/wor_gameplay_framework/editor/gas_runtime_debugger_panel.gd")
const GameplayAbilityScript := preload("res://addons/wor_gameplay_framework/runtime/abilities/gameplay_ability.gd")
const GameplayEffectScript := preload("res://addons/wor_gameplay_framework/runtime/effects/gameplay_effect.gd")
const GameplayAttributeScript := preload("res://addons/wor_gameplay_framework/runtime/attributes/gameplay_attribute.gd")

var _debugger_panel: VBoxContainer


func setup(editor_interface: EditorInterface) -> void:
	name = "GAS"
	custom_minimum_size = Vector2(340.0, 0.0)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)

	var tags := TagEditorScript.new()
	tags.name = "Tags"
	tabs.add_child(tags)
	tags.setup(editor_interface)

	_add_resource_tab(
		tabs,
		editor_interface,
		"Abilities",
		[&"GameplayAbility"],
		GameplayAbilityScript
	)
	_add_resource_tab(
		tabs,
		editor_interface,
		"Effects",
		[&"GameplayEffect"],
		GameplayEffectScript
	)
	_add_resource_tab(
		tabs,
		editor_interface,
		"Attributes",
		[&"GameplayAttribute", &"GameplayAttributeSet"],
		GameplayAttributeScript
	)

	var cues := VBoxContainer.new()
	cues.name = "Cues"
	var cues_label := Label.new()
	cues_label.text = "Gameplay Cues entram no M4. Esta navegação fica reservada para manter o workflow do dock."
	cues_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cues.add_child(cues_label)
	tabs.add_child(cues)

	_debugger_panel = RuntimeDebuggerPanelScript.new()
	_debugger_panel.name = "Debugger"
	tabs.add_child(_debugger_panel)


func update_runtime_snapshots(session_id: int, snapshots: Array) -> void:
	if _debugger_panel != null:
		_debugger_panel.update_snapshots(session_id, snapshots)


func clear_runtime_debugger() -> void:
	if _debugger_panel != null:
		_debugger_panel.clear_runtime()


func _add_resource_tab(
	tabs: TabContainer,
	editor_interface: EditorInterface,
	title: String,
	accepted_classes: Array[StringName],
	new_resource_script: Script
) -> void:
	var browser := ResourceBrowserScript.new()
	browser.name = title
	tabs.add_child(browser)
	browser.setup(editor_interface, title, accepted_classes, new_resource_script)
