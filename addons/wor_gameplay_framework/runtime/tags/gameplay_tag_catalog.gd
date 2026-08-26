@tool
class_name GameplayTagCatalog
extends Resource

## Project-level source of truth used by the tag editor and tag autocomplete.

@export var tags: Array[GameplayTag] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var known_names: Dictionary = {}
	for index: int in tags.size():
		var tag := tags[index]
		if tag == null:
			errors.append("Tag at index %d is null." % index)
			continue
		if not tag.is_valid():
			errors.append("Tag at index %d is invalid: '%s'." % [index, String(tag.tag_name)])
			continue
		if known_names.has(tag.tag_name):
			errors.append("Duplicate tag '%s'." % String(tag.tag_name))
		known_names[tag.tag_name] = true
	return errors


func get_tag(tag_name: StringName) -> GameplayTag:
	for tag: GameplayTag in tags:
		if tag != null and tag.tag_name == tag_name:
			return tag
	return null


func get_tag_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for tag: GameplayTag in tags:
		if tag != null and tag.is_valid():
			names.append(tag.tag_name)
	names.sort()
	return names


func add_tag_name(tag_name: StringName) -> bool:
	if not GameplayTag.is_valid_tag_name(tag_name) or get_tag(tag_name) != null:
		return false
	var tag := GameplayTag.new()
	tag.tag_name = tag_name
	tags.append(tag)
	emit_changed()
	return true


func remove_tag_name(tag_name: StringName) -> bool:
	for index: int in tags.size():
		var tag := tags[index]
		if tag != null and tag.tag_name == tag_name:
			tags.remove_at(index)
			emit_changed()
			return true
	return false


func rename_tag(old_name: StringName, new_name: StringName) -> bool:
	if get_tag(old_name) == null or not GameplayTag.is_valid_tag_name(new_name):
		return false
	var renamed_tags: Array[GameplayTag] = []
	var candidate_names: Dictionary = {}
	var old_prefix := String(old_name) + "."
	for tag: GameplayTag in tags:
		if tag == null:
			continue
		var current_name := String(tag.tag_name)
		if tag.tag_name != old_name and not current_name.begins_with(old_prefix):
			candidate_names[tag.tag_name] = true
	for tag: GameplayTag in tags:
		if tag == null:
			continue
		var current_name := String(tag.tag_name)
		if tag.tag_name != old_name and not current_name.begins_with(old_prefix):
			continue
		var suffix := current_name.trim_prefix(String(old_name))
		var candidate := StringName(String(new_name) + suffix)
		if candidate_names.has(candidate):
			return false
		candidate_names[candidate] = true
		renamed_tags.append(tag)
	for tag: GameplayTag in renamed_tags:
		var suffix := String(tag.tag_name).trim_prefix(String(old_name))
		tag.tag_name = StringName(String(new_name) + suffix)
		tag.emit_changed()
	emit_changed()
	return true
