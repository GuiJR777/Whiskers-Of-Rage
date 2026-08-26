@tool
class_name GameplayTag
extends Resource

## Hierarchical semantic identifier such as State.Stunned or Ability.Attack.Light.

@export var tag_name: StringName = &""


func is_valid() -> bool:
	return GameplayTag.is_valid_tag_name(tag_name)


func matches(query: GameplayTag) -> bool:
	return query != null and GameplayTag.matches_tag_name(tag_name, query.tag_name)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not is_valid():
		errors.append("GameplayTag.tag_name must contain non-empty dot-separated segments.")
	return errors


static func is_valid_tag_name(value: StringName) -> bool:
	var text := String(value)
	if text.is_empty() or text.begins_with(".") or text.ends_with("."):
		return false
	for segment: String in text.split(".", true):
		if segment.strip_edges().is_empty() or segment != segment.strip_edges():
			return false
	return true


static func matches_tag_name(owned_tag: StringName, query_tag: StringName) -> bool:
	if not is_valid_tag_name(owned_tag) or not is_valid_tag_name(query_tag):
		return false
	var owned := String(owned_tag)
	var query := String(query_tag)
	return owned == query or owned.begins_with(query + ".")


func _to_string() -> String:
	return String(tag_name)

