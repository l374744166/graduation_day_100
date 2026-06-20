extends Node

const INITIAL_STATE := {
	"day": 1,
	"time_slot": "morning",
	"money": 3000,
	"mood": 70,
	"skill": 20,
	"relationship": 50,
	"pressure": 30,
	"self_identity": 40,
	"current_location": "dorm",
	"flags": {}
}

const CLAMPED_STATS := ["mood", "skill", "relationship", "pressure", "self_identity"]

var day: int = 1
var time_slot: String = "morning"
var money: int = 3000
var mood: int = 70
var skill: int = 20
var relationship: int = 50
var pressure: int = 30
var self_identity: int = 40
var current_location: String = "dorm"
var flags: Dictionary = {}

func reset() -> void:
	load_from_dict(INITIAL_STATE.duplicate(true))

func to_dict() -> Dictionary:
	return {
		"day": day,
		"time_slot": time_slot,
		"money": money,
		"mood": mood,
		"skill": skill,
		"relationship": relationship,
		"pressure": pressure,
		"self_identity": self_identity,
		"current_location": current_location,
		"flags": flags.duplicate(true)
	}

func load_from_dict(data: Dictionary) -> void:
	day = int(data.get("day", INITIAL_STATE["day"]))
	time_slot = str(data.get("time_slot", INITIAL_STATE["time_slot"]))
	money = int(data.get("money", INITIAL_STATE["money"]))
	mood = int(data.get("mood", INITIAL_STATE["mood"]))
	skill = int(data.get("skill", INITIAL_STATE["skill"]))
	relationship = int(data.get("relationship", INITIAL_STATE["relationship"]))
	pressure = int(data.get("pressure", INITIAL_STATE["pressure"]))
	self_identity = int(data.get("self_identity", INITIAL_STATE["self_identity"]))
	current_location = str(data.get("current_location", INITIAL_STATE["current_location"]))
	flags = data.get("flags", {}).duplicate(true)
	clamp_stats()

func apply_effects(effects: Dictionary) -> Dictionary:
	var actual_changes: Dictionary = {}
	var known_state := to_dict()
	for key in effects.keys():
		if not known_state.has(key):
			continue
		var before := int(get(key))
		set(key, before + int(effects[key]))
		if key in CLAMPED_STATS:
			set(key, clampi(int(get(key)), 0, 100))
		actual_changes[key] = int(get(key)) - before
	return actual_changes

func clamp_stats() -> void:
	for stat in CLAMPED_STATS:
		set(stat, clampi(int(get(stat)), 0, 100))

func get_time_slot_label() -> String:
	match time_slot:
		"morning":
			return "上午"
		"afternoon":
			return "下午"
		"night":
			return "晚上"
		_:
			return time_slot
