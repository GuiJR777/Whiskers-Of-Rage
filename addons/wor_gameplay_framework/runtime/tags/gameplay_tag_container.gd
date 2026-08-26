class_name GameplayTagContainer
extends RefCounted

## Runtime tag storage. Counts allow several independent systems to grant the same tag.

signal tag_added(tag_name: StringName)
signal tag_removed(tag_name: StringName)

var _tag_counts: Dictionary = {}


func add_tag(tag: GameplayTag, count: int = 1) -> bool:
	if tag == null:
		push_error("GameplayTagContainer.add_tag received a null tag.")
		return false
	return add_tag_name(tag.tag_name, count)


func add_tag_name(tag_name: StringName, count: int = 1) -> bool:
	if not GameplayTag.is_valid_tag_name(tag_name):
		push_error("GameplayTagContainer cannot add invalid tag '%s'." % String(tag_name))
		return false
	if count <= 0:
		push_error("GameplayTagContainer add count must be greater than zero.")
		return false
	var previous_count: int = _tag_counts.get(tag_name, 0)
	_tag_counts[tag_name] = previous_count + count
	if previous_count == 0:
		tag_added.emit(tag_name)
	return true


func remove_tag(tag: GameplayTag, count: int = 1) -> bool:
	if tag == null:
		push_error("GameplayTagContainer.remove_tag received a null tag.")
		return false
	return remove_tag_name(tag.tag_name, count)


func remove_tag_name(tag_name: StringName, count: int = 1) -> bool:
	if count <= 0:
		push_error("GameplayTagContainer remove count must be greater than zero.")
		return false
	var previous_count: int = _tag_counts.get(tag_name, 0)
	if previous_count <= 0:
		return false
	var new_count := maxi(previous_count - count, 0)
	if new_count == 0:
		_tag_counts.erase(tag_name)
		tag_removed.emit(tag_name)
	else:
		_tag_counts[tag_name] = new_count
	return true


func has_tag(tag: GameplayTag, exact_match: bool = false) -> bool:
	return tag != null and has_tag_name(tag.tag_name, exact_match)


func has_tag_name(tag_name: StringName, exact_match: bool = false) -> bool:
	if not GameplayTag.is_valid_tag_name(tag_name):
		return false
	if exact_match:
		return get_tag_count(tag_name) > 0
	for owned_variant: Variant in _tag_counts.keys():
		var owned_tag: StringName = owned_variant
		if GameplayTag.matches_tag_name(owned_tag, tag_name):
			return true
	return false


func has_all(tags: Array[GameplayTag], exact_match: bool = false) -> bool:
	for tag: GameplayTag in tags:
		if not has_tag(tag, exact_match):
			return false
	return true


func has_any(tags: Array[GameplayTag], exact_match: bool = false) -> bool:
	for tag: GameplayTag in tags:
		if has_tag(tag, exact_match):
			return true
	return false


func get_tag_count(tag_name: StringName) -> int:
	return _tag_counts.get(tag_name, 0)


func get_owned_tag_names() -> Array[StringName]:
	var result: Array[StringName] = []
	for tag_variant: Variant in _tag_counts.keys():
		result.append(tag_variant as StringName)
	result.sort()
	return result


func clear() -> void:
	var previous_tags := get_owned_tag_names()
	_tag_counts.clear()
	for tag_name: StringName in previous_tags:
		tag_removed.emit(tag_name)


func is_empty() -> bool:
	return _tag_counts.is_empty()

