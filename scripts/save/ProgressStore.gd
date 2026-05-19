extends RefCounted
class_name ProgressStore

const ProgressState := preload("res://scripts/state/ProgressState.gd")

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "progress"

static func load_progress():
	var state := ProgressState.new()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return state

	state.best_score = int(config.get_value(SAVE_SECTION, "best_score", 0))
	state.total_coins = int(config.get_value(SAVE_SECTION, "coins", 0))
	state.selected_character_id = String(config.get_value(SAVE_SECTION, "selected_character_id", ProgressState.DEFAULT_SELECTED_CHARACTER_ID))
	state.cleared_stage_ids = _read_string_array(config.get_value(SAVE_SECTION, "cleared_stage_ids", []))
	return state

static func save_progress(state) -> void:
	if state == null:
		return
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "best_score", state.best_score)
	config.set_value(SAVE_SECTION, "coins", state.total_coins)
	config.set_value(SAVE_SECTION, "selected_character_id", state.selected_character_id)
	config.set_value(SAVE_SECTION, "cleared_stage_ids", state.cleared_stage_ids.duplicate())
	config.save(SAVE_PATH)

static func load_progress_dictionary() -> Dictionary:
	return load_progress().to_dictionary()

static func _read_string_array(value) -> Array:
	var result := []
	if value is Array or value is PackedStringArray:
		for item in value:
			var text := String(item)
			if not text.is_empty() and not result.has(text):
				result.append(text)
	return result
