extends Node

@export var test_result: String = "PENDING"
@export var failures: PackedStringArray = []


func _ready() -> void:
	var result := EditorToolsM3TestSuite.run()
	failures = PackedStringArray(result)
	test_result = "PASS" if failures.is_empty() else "FAIL"
	print("EDITOR_TOOLS_M3_TESTS: %s" % test_result)
