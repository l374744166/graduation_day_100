extends Node

const LOCATIONS_PATH := "res://data/locations.json"

var locations: Array = []

func _ready() -> void:
	load_locations()

func load_locations() -> void:
	locations = _load_json_array(LOCATIONS_PATH)

func get_locations() -> Array:
	return locations

func get_location_name(location_id: String) -> String:
	for location in locations:
		if location.get("id", "") == location_id:
			return location.get("name", location_id)
	return location_id

func travel_to(location_id: String) -> void:
	GameState.current_location = location_id

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
