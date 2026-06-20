extends Node

const ACTIONS_PATH := "res://data/actions.json"

var actions: Array = []

func _ready() -> void:
	load_actions()

func load_actions() -> void:
	actions = _load_json_array(ACTIONS_PATH)

func get_actions_for_state() -> Array:
	return actions

func get_action_by_id(action_id: String) -> Dictionary:
	for action in actions:
		if action.get("id", "") == action_id:
			return action
	return {}

func _load_json_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Missing JSON file: %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Expected JSON array at: %s" % path)
		return []
	return parsed
