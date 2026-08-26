extends Node

## Debug-build-only bridge from live ASCs to the editor debugger plugin.

const MESSAGE_NAME: String = "wor_gas:snapshots"
const UPDATE_INTERVAL: float = 0.25

var _elapsed: float = 0.0


func _process(delta: float) -> void:
	if not EngineDebugger.is_active():
		return
	_elapsed += delta
	if _elapsed < UPDATE_INTERVAL:
		return
	_elapsed = 0.0
	var snapshots: Array[Dictionary] = []
	for node: Node in get_tree().get_nodes_in_group(AbilitySystemComponent.DEBUG_GROUP):
		if node is AbilitySystemComponent:
			snapshots.append((node as AbilitySystemComponent).get_debug_snapshot())
	snapshots.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("path", "")) < String(right.get("path", ""))
	)
	EngineDebugger.send_message(MESSAGE_NAME, [snapshots])
