extends RefCounted
class_name ObjectVisualSet

const ObjectVisualCatalog := preload("res://scripts/data/ObjectVisualCatalog.gd")

var id := "stage_1_objects"
var overrides := {}

static func make_stage1():
	var visual_set = load("res://scripts/data/stage/ObjectVisualSet.gd").new()
	visual_set.id = "stage_1_objects"
	return visual_set

func get_visual(object_type: String) -> Dictionary:
	if overrides.has(object_type):
		return overrides[object_type].duplicate(true)
	return ObjectVisualCatalog.get_visual(object_type)
