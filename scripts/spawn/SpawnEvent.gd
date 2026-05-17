extends RefCounted
class_name SpawnEvent

var time: float
var type: String
var lane: int = 0
var meta: Dictionary = {}

func _init(_time: float, _type: String, _lane: int = 0, _meta: Dictionary = {}) -> void:
	time = _time
	type = _type
	lane = _lane
	meta = _meta
