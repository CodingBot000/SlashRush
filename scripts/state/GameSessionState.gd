extends RefCounted
class_name GameSessionState

const GameBalance := preload("res://scripts/data/GameBalance.gd")
const StageCatalog := preload("res://scripts/data/stage/StageCatalog.gd")
const ProgressState := preload("res://scripts/state/ProgressState.gd")

var run_id := 0
var stage_id := StageCatalog.DEFAULT_STAGE_ID
var selected_character_id := ProgressState.DEFAULT_SELECTED_CHARACTER_ID
var current_score := 0
var current_coins := 0
var current_hp := GameBalance.STARTING_HP
var phase := "runner"

func start_new_run(next_stage_id: String = StageCatalog.DEFAULT_STAGE_ID, character_id: String = ProgressState.DEFAULT_SELECTED_CHARACTER_ID) -> void:
	run_id += 1
	stage_id = next_stage_id
	selected_character_id = character_id
	current_score = 0
	current_coins = 0
	current_hp = GameBalance.STARTING_HP
	phase = "runner"

func apply_runner_payload(payload: Dictionary) -> void:
	current_score = int(payload.get("score", current_score))
	current_coins = int(payload.get("coins", current_coins))
	current_hp = int(payload.get("hp", current_hp))

func apply_boss_payload(payload: Dictionary) -> void:
	current_score = int(payload.get("score", current_score))
	current_coins = int(payload.get("coins", current_coins))
	current_hp = int(payload.get("hp", current_hp))
