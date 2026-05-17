extends RefCounted
class_name SpawnBalance

const STAGE_DURATION := 60.0

const PHASES := [
	{
		"name": "opening_buffer",
		"start": 0.0,
		"end": 8.0,
		"spawn_interval_min": 0.9,
		"spawn_interval_max": 1.2,
		"allowed_danger": ["enemy_basic", "bomb"],
		"allow_fast": false,
		"allow_armor": false
	},
	{
		"name": "basic_mix",
		"start": 8.0,
		"end": 18.0,
		"spawn_interval_min": 0.75,
		"spawn_interval_max": 1.0,
		"allowed_danger": ["enemy_basic", "bomb", "enemy_fast"],
		"allow_fast": true,
		"allow_armor": false
	},
	{
		"name": "input_pressure",
		"start": 18.0,
		"end": 30.0,
		"spawn_interval_min": 0.65,
		"spawn_interval_max": 0.9,
		"allowed_danger": ["enemy_basic", "bomb", "enemy_fast"],
		"allow_fast": true,
		"allow_armor": false
	},
	{
		"name": "armor_mix",
		"start": 30.0,
		"end": 42.0,
		"spawn_interval_min": 0.7,
		"spawn_interval_max": 1.0,
		"allowed_danger": ["enemy_basic", "bomb", "enemy_fast", "enemy_armor"],
		"allow_fast": true,
		"allow_armor": true
	},
	{
		"name": "high_pressure",
		"start": 42.0,
		"end": 52.0,
		"spawn_interval_min": 0.55,
		"spawn_interval_max": 0.8,
		"allowed_danger": ["enemy_basic", "bomb", "enemy_fast", "enemy_armor"],
		"allow_fast": true,
		"allow_armor": true
	},
	{
		"name": "final_wave",
		"start": 52.0,
		"end": 60.0,
		"spawn_interval_min": 0.5,
		"spawn_interval_max": 0.75,
		"allowed_danger": ["enemy_basic", "bomb", "enemy_fast", "enemy_armor"],
		"allow_fast": true,
		"allow_armor": true
	}
]

const ITEM_BUDGET := {
	"coin": 14,
	"fever_orb": 2,
	"heal": 2
}

const GOOD_ITEM_MIN_INTERVAL := 2.0
const HEAL_MIN_INTERVAL := 12.0
const FEVER_ORB_MIN_INTERVAL := 16.0
const FEVER_AFTER_END_BLOCK_TIME := 8.0

const HEAL_CANDIDATE_TIMES := [24.0, 42.0, 54.0]

const FEVER_ORB_WINDOWS := [
	{"start": 18.0, "end": 26.0},
	{"start": 42.0, "end": 52.0}
]

const COIN_TARGET_MIN := 10
const COIN_TARGET_MAX := 14

const ARMOR_MIN_GAP_BEFORE := 0.85
const ARMOR_MIN_GAP_AFTER := 0.85
const ITEM_AFTER_FAST_MIN_GAP := 0.65

const FEVER_DURATION := 5.5
const FEVER_SPAWN_INTERVAL_MIN := 0.12
const FEVER_SPAWN_INTERVAL_MAX := 0.22
const FEVER_RUSH_SPAWN_STOP_BEFORE_END := 1.0
const FEVER_RUSH_SPAWN_PAUSE_DURATION := 1.0
const FEVER_RECOVER_TIME := 0.8

const FEVER_OBJECT_WEIGHTS := {
	"enemy_basic": 75,
	"enemy_fast": 15,
	"bomb": 10
}
