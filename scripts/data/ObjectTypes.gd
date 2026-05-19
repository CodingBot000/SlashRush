extends Node
class_name ObjectTypes

const ActionTypes := preload("res://scripts/data/ActionTypes.gd")
const ObjectRuleCatalog := preload("res://scripts/data/ObjectRuleCatalog.gd")
const ObjectVisualCatalog := preload("res://scripts/data/ObjectVisualCatalog.gd")

static func get_data(object_type: String) -> Dictionary:
	var data := ObjectRuleCatalog.get_rule(object_type)
	var visual_data := ObjectVisualCatalog.get_visual(object_type)
	for key in visual_data.keys():
		data[key] = visual_data[key]
	return data

static func get_spawn_type(spawn_count: int) -> String:
	var early_pattern := ["enemy_basic", "coin", "enemy_basic", "coin", "enemy_basic", "fever_orb"]
	var mid_pattern := ["enemy_basic", "coin", "enemy_fast", "heal", "enemy_basic", "coin", "enemy_fast"]
	var late_pattern := ["enemy_basic", "coin", "enemy_fast", "fever_orb", "enemy_armor", "heal", "bomb", "coin", "enemy_basic"]
	if spawn_count < 8:
		return early_pattern[spawn_count % early_pattern.size()]
	if spawn_count < 17:
		return mid_pattern[spawn_count % mid_pattern.size()]
	return late_pattern[spawn_count % late_pattern.size()]

static func get_action_hint(action: String) -> String:
	return ActionTypes.get_hint(action)
