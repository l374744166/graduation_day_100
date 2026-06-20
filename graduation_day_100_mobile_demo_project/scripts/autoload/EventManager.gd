extends Node

const EVENTS_PATH := "res://data/events.json"

var events_by_day: Dictionary = {}

func _ready() -> void:
	load_events()

func load_events() -> void:
	events_by_day.clear()
	var events := _load_json_array(EVENTS_PATH)
	for event in events:
		events_by_day[int(event.get("day", 0))] = event

func get_event_for_day(day: int) -> Dictionary:
	return events_by_day.get(day, {})

func is_event_completed(day: int) -> bool:
	return bool(GameState.flags.get("event_day_%d" % day, false))

func should_trigger_event(day: int) -> bool:
	return day >= 1 and day <= 7 and get_event_for_day(day).size() > 0 and not is_event_completed(day)

func mark_event_completed(day: int) -> void:
	GameState.flags["event_day_%d" % day] = true

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
