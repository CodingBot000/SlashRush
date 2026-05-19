extends RefCounted
class_name RunnerStageContext

const StageCatalog := preload("res://scripts/data/stage/StageCatalog.gd")
const CharacterVisualProfile := preload("res://scripts/data/stage/CharacterVisualProfile.gd")
const ObjectVisualSet := preload("res://scripts/data/stage/ObjectVisualSet.gd")

var stage_id := StageCatalog.DEFAULT_STAGE_ID
var runner_config
var character_profile
var object_visual_set
var start_score := 0
var start_coins := 0
var start_hp := 0

static func make_default():
	var stage = StageCatalog.get_default_stage()
	return from_stage(stage, null)

static func from_stage(stage, session_state):
	var context = load("res://scripts/game/runner/RunnerStageContext.gd").new()
	if stage != null:
		context.stage_id = String(stage.id)
		context.runner_config = stage.runner_config
		context.character_profile = stage.character_profile
		context.object_visual_set = stage.object_visual_set
	else:
		var default_stage = StageCatalog.get_default_stage()
		context.stage_id = String(default_stage.id)
		context.runner_config = default_stage.runner_config
		context.character_profile = default_stage.character_profile
		context.object_visual_set = default_stage.object_visual_set
	if context.character_profile == null:
		context.character_profile = CharacterVisualProfile.make_default()
	if context.object_visual_set == null:
		context.object_visual_set = ObjectVisualSet.make_stage1()
	if session_state != null:
		context.character_profile = CharacterVisualProfile.make_for_character(String(session_state.selected_character_id))
		context.start_score = int(session_state.current_score)
		context.start_coins = int(session_state.current_coins)
		context.start_hp = int(session_state.current_hp)
	return context
