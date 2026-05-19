extends RefCounted
class_name BossStageConfig

const GameBalance := preload("res://scripts/data/GameBalance.gd")

var boss_scene_path := "res://scenes/boss/RobotSamuraiBoss.tscn"
var boss_background_path := "res://assets/background/stage1/boss_background.png"
var boss_max_hp := GameBalance.BOSS_MAX_HP
var boss_fever_max := GameBalance.BOSS_FEVER_MAX
var boss_fever_duration := GameBalance.BOSS_FEVER_DURATION
var boss_fever_gain_per_success := GameBalance.BOSS_FEVER_GAIN_PER_SUCCESS
var success_score := 200
var fever_success_score := 400
var clear_bonus_score := 500
var phase_pattern_counts := {}
var hit_scrap_texture_paths := []

static func make_stage1():
	var config = load("res://scripts/data/stage/BossStageConfig.gd").new()
	config.phase_pattern_counts = {
		"phase_1": {"tap": 10, "double_tap": 8, "long_tap": 8, "no_input": 4},
		"phase_2": {"tap": 4, "double_tap": 11, "long_tap": 11, "no_input": 4}
	}
	config.hit_scrap_texture_paths = [
		"res://assets/boss/robot_samurai/scrap1.png",
		"res://assets/boss/robot_samurai/scrap2.png",
		"res://assets/boss/robot_samurai/scrap3.png",
		"res://assets/boss/robot_samurai/scrap4.png",
		"res://assets/boss/robot_samurai/scrap5.png",
		"res://assets/boss/robot_samurai/scrap6.png",
		"res://assets/boss/robot_samurai/scrap7.png"
	]
	return config
