extends RefCounted
class_name StageDefinition

const RunnerStageConfig := preload("res://scripts/data/stage/RunnerStageConfig.gd")
const BossStageConfig := preload("res://scripts/data/stage/BossStageConfig.gd")
const CharacterVisualProfile := preload("res://scripts/data/stage/CharacterVisualProfile.gd")
const ObjectVisualSet := preload("res://scripts/data/stage/ObjectVisualSet.gd")

var id := ""
var display_name := ""
var runner_config: RunnerStageConfig
var boss_config: BossStageConfig
var character_profile: CharacterVisualProfile
var object_visual_set: ObjectVisualSet
var unlock_condition := {}
var next_stage_id := ""
