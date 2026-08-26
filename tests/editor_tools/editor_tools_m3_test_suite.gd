class_name EditorToolsM3TestSuite
extends RefCounted

var _failures: Array[String] = []


static func run() -> Array[String]:
	var suite := EditorToolsM3TestSuite.new()
	suite._test_tag_catalog_crud_and_validation()
	suite._test_asc_debug_snapshot()
	return suite._failures


func _test_tag_catalog_crud_and_validation() -> void:
	var catalog := GameplayTagCatalog.new()
	_check(catalog.add_tag_name(&"State.Stunned"), "Catalog must add a valid tag.")
	_check(not catalog.add_tag_name(&"State.Stunned"), "Catalog must reject duplicates.")
	_check(not catalog.add_tag_name(&"State..Broken"), "Catalog must reject invalid names.")
	_check(catalog.add_tag_name(&"State.Stunned.Light"), "Catalog must add a child tag.")
	var tag := catalog.get_tag(&"State.Stunned")
	_check(tag != null, "Added catalog tag must resolve.")
	_check(catalog.rename_tag(&"State.Stunned", &"State.Stunned.Heavy"), "Catalog must rename tags.")
	_check(tag.tag_name == &"State.Stunned.Heavy", "Rename must preserve the referenced Resource.")
	_check(
		catalog.get_tag(&"State.Stunned.Heavy.Light") != null,
		"Renaming a hierarchy root must rename its descendants."
	)
	_check(catalog.validate().is_empty(), "Valid catalog must have no validation errors.")
	_check(catalog.remove_tag_name(&"State.Stunned.Heavy"), "Catalog must remove a registered tag.")


func _test_asc_debug_snapshot() -> void:
	var health := GameplayAttribute.new()
	health.attribute_name = &"Health"
	health.default_value = 100.0
	health.minimum_value = 0.0
	health.maximum_value = 100.0
	var attribute_set := GameplayAttributeSet.new()
	attribute_set.attributes = [health]
	var asc := AbilitySystemComponent.new()
	asc.initialize_on_ready = false
	asc.initial_attribute_sets = [attribute_set]
	_check(asc.initialize(), "Snapshot ASC must initialize.")
	asc.tags.add_tag_name(&"State.Testing")
	asc.send_gameplay_event(GameplayEvent.create(_make_tag(&"Debug.Event.Test")))
	asc.try_activate_ability(999)
	var snapshot := asc.get_debug_snapshot()
	_check((snapshot.attributes as Array).size() == 1, "Snapshot must expose attributes.")
	_check((snapshot.tags as Array).size() == 1, "Snapshot must expose owned tags.")
	_check((snapshot.recent_events as Array).size() == 1, "Snapshot must expose recent events.")
	_check((snapshot.lifecycle_warnings as Array).size() == 1, "Snapshot must expose lifecycle warnings.")


func _make_tag(tag_name: StringName) -> GameplayTag:
	var tag := GameplayTag.new()
	tag.tag_name = tag_name
	return tag


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
