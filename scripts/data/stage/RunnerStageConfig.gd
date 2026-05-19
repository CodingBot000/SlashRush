extends RefCounted
class_name RunnerStageConfig

const GameBalance := preload("res://scripts/data/GameBalance.gd")
const SpawnBalance := preload("res://scripts/spawn/SpawnBalance.gd")

var duration_seconds := SpawnBalance.STAGE_DURATION
var map_scroll_speed := GameBalance.MAP_SCROLL_SPEED
var ground_scroll_speed := GameBalance.GROUND_SCROLL_SPEED
var object_speed := GameBalance.OBJECT_SPEED
var fever_scroll_speed_multiplier := GameBalance.RUNNER_FEVER_SCROLL_SPEED_MULTIPLIER
var fever_object_speed_multiplier := GameBalance.RUNNER_FEVER_OBJECT_SPEED_MULTIPLIER
var fever_duration := SpawnBalance.FEVER_DURATION
var fever_spawn_interval_min := SpawnBalance.FEVER_SPAWN_INTERVAL_MIN
var fever_spawn_interval_max := SpawnBalance.FEVER_SPAWN_INTERVAL_MAX
var fever_rush_spawn_stop_before_end := SpawnBalance.FEVER_RUSH_SPAWN_STOP_BEFORE_END
var fever_rush_spawn_pause_duration := SpawnBalance.FEVER_RUSH_SPAWN_PAUSE_DURATION
var fever_recover_time := SpawnBalance.FEVER_RECOVER_TIME
var background_layers := []
var ground_texture_path := "res://assets/background/stage1/ground_tile_01.png"
var spawn_phases := []
var item_budget := {}
var good_item_min_interval := SpawnBalance.GOOD_ITEM_MIN_INTERVAL
var heal_min_interval := SpawnBalance.HEAL_MIN_INTERVAL
var fever_orb_min_interval := SpawnBalance.FEVER_ORB_MIN_INTERVAL
var fever_after_end_block_time := SpawnBalance.FEVER_AFTER_END_BLOCK_TIME
var heal_candidate_times := []
var fever_orb_windows := []
var coin_target_min := SpawnBalance.COIN_TARGET_MIN
var coin_target_max := SpawnBalance.COIN_TARGET_MAX
var armor_min_gap_before := SpawnBalance.ARMOR_MIN_GAP_BEFORE
var armor_min_gap_after := SpawnBalance.ARMOR_MIN_GAP_AFTER
var item_after_fast_min_gap := SpawnBalance.ITEM_AFTER_FAST_MIN_GAP
var fever_object_weights := {}

static func make_stage1():
	var config = load("res://scripts/data/stage/RunnerStageConfig.gd").new()
	config.background_layers = [
		{"name": "Sky", "kind": "sky", "texture": "res://assets/background/stage1/sky_static.png", "factor": 0.0},
		{"name": "CloudLayer", "kind": "cloud", "texture": "res://assets/background/stage1/cloud_01.png", "factor": 0.0128},
		{"name": "FarLayer", "kind": "image", "texture": "res://assets/background/stage1/far_mountains_01.png", "factor": 0.24, "z_index": -80, "fallback_color": Color.html("#94cbe6"), "fallback_base_y": 350.0, "fallback_height": 120.0, "y_offset": -120.0},
		{"name": "MidLayer", "kind": "image", "texture": "res://assets/background/stage1/mid_structures_01.png", "factor": 0.58, "z_index": -60, "fallback_color": Color.html("#5c7788"), "fallback_base_y": 430.0, "fallback_height": 95.0, "y_offset": -130.0},
		{"name": "NearLayer", "kind": "image", "texture": "res://assets/background/stage1/near_foreground_01.png", "factor": 1.12, "z_index": -40, "fallback_color": Color.html("#2c4a42"), "fallback_base_y": 515.0, "fallback_height": 58.0, "y_offset": -130.0}
	]
	config.spawn_phases = SpawnBalance.PHASES.duplicate(true)
	config.item_budget = SpawnBalance.ITEM_BUDGET.duplicate(true)
	config.heal_candidate_times = SpawnBalance.HEAL_CANDIDATE_TIMES.duplicate(true)
	config.fever_orb_windows = SpawnBalance.FEVER_ORB_WINDOWS.duplicate(true)
	config.fever_object_weights = SpawnBalance.FEVER_OBJECT_WEIGHTS.duplicate(true)
	return config
