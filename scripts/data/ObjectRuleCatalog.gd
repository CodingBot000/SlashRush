extends RefCounted
class_name ObjectRuleCatalog

const ActionTypes := preload("res://scripts/data/ActionTypes.gd")

static func get_rule(object_type: String) -> Dictionary:
	match object_type:
		"enemy_basic":
			return {
				"required_action": ActionTypes.TAP,
				"is_good_item": false,
				"score": 100,
				"fever": 6,
				"damage": 1
			}
		"enemy_fast":
			return {
				"required_action": ActionTypes.DOUBLE_TAP,
				"is_good_item": false,
				"score": 150,
				"fever": 10,
				"damage": 1
			}
		"enemy_armor":
			return {
				"required_action": ActionTypes.LONG_TAP,
				"is_good_item": false,
				"score": 150,
				"fever": 10,
				"damage": 1
			}
		"coin":
			return {
				"required_action": ActionTypes.NO_INPUT,
				"is_good_item": true,
				"score": 20,
				"fever": 0,
				"damage": 0
			}
		"heal":
			return {
				"required_action": ActionTypes.NO_INPUT,
				"is_good_item": true,
				"score": 0,
				"fever": 0,
				"damage": 0
			}
		"fever_orb":
			return {
				"required_action": ActionTypes.NO_INPUT,
				"is_good_item": true,
				"score": 50,
				"fever": 25,
				"damage": 0
			}
		"bomb":
			return {
				"required_action": ActionTypes.TAP,
				"is_good_item": false,
				"score": 80,
				"fever": 4,
				"damage": 1
			}
		_:
			return get_rule("enemy_basic")
