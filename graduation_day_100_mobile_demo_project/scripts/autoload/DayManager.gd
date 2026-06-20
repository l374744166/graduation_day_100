extends Node

const TIME_SLOTS := ["morning", "afternoon", "night"]

var last_day_summary: Dictionary = {}

func advance_after_action(action_name: String, action_changes: Dictionary) -> Dictionary:
	var summary := {
		"action_name": action_name,
		"action_changes": action_changes,
		"daily_changes": {},
		"previous_day": GameState.day,
		"new_day_started": false,
		"demo_finished": false
	}
	if GameState.time_slot == "night":
		summary["daily_changes"] = end_day()
		summary["new_day_started"] = true
		summary["demo_finished"] = GameState.day > 7
	else:
		var index := TIME_SLOTS.find(GameState.time_slot)
		GameState.time_slot = TIME_SLOTS[clampi(index + 1, 0, TIME_SLOTS.size() - 1)]
	last_day_summary = summary
	return summary

func end_day() -> Dictionary:
	var changes := {"money": -60}
	var pressure_change := 0
	GameState.money -= 60
	if GameState.money < 500:
		var before_pressure := GameState.pressure
		GameState.pressure = clampi(GameState.pressure + 5, 0, 100)
		pressure_change = GameState.pressure - before_pressure
	if pressure_change != 0:
		changes["pressure"] = pressure_change
	GameState.day += 1
	GameState.time_slot = "morning"
	return changes

func get_next_event() -> Dictionary:
	if EventManager.should_trigger_event(GameState.day):
		return EventManager.get_event_for_day(GameState.day)
	return {}
