extends RefCounted
class_name StageCatalog

const StageDefinitionScript := preload("res://scripts/data/stage/StageDefinition.gd")
const RunnerStageConfig := preload("res://scripts/data/stage/RunnerStageConfig.gd")
const BossStageConfig := preload("res://scripts/data/stage/BossStageConfig.gd")
const CharacterVisualProfile := preload("res://scripts/data/stage/CharacterVisualProfile.gd")
const ObjectVisualSet := preload("res://scripts/data/stage/ObjectVisualSet.gd")

const DEFAULT_STAGE_ID := "stage_1"

static func get_default_stage():
	return get_stage(DEFAULT_STAGE_ID)

static func get_stage(stage_id: String):
	match stage_id:
		DEFAULT_STAGE_ID:
			return _make_stage1()
		_:
			return _make_stage1()

static func get_stage_ids() -> Array:
	return [DEFAULT_STAGE_ID]

static func _make_stage1():
	var stage = StageDefinitionScript.new()
	stage.id = DEFAULT_STAGE_ID
	stage.display_name = "Stage 1"
	stage.runner_config = RunnerStageConfig.make_stage1()
	stage.boss_config = BossStageConfig.make_stage1()
	stage.character_profile = CharacterVisualProfile.make_default()
	stage.object_visual_set = ObjectVisualSet.make_stage1()
	return stage
