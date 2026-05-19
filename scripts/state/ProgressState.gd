extends RefCounted
class_name ProgressState

const DEFAULT_SELECTED_CHARACTER_ID := "player1"

var best_score := 0
var total_coins := 0
var selected_character_id := DEFAULT_SELECTED_CHARACTER_ID
var cleared_stage_ids := []

func to_dictionary() -> Dictionary:
	return {
		"best_score": best_score,
		"coins": total_coins,
		"selected_character_id": selected_character_id,
		"cleared_stage_ids": cleared_stage_ids.duplicate()
	}

func record_result(score: int, coins: int, cleared_stage_id: String = "") -> void:
	best_score = max(best_score, score)
	total_coins += max(0, coins)
	if not cleared_stage_id.is_empty() and not cleared_stage_ids.has(cleared_stage_id):
		cleared_stage_ids.append(cleared_stage_id)
