extends RefCounted
class_name ActionTypes

const TAP := "tap"
const DOUBLE_TAP := "double_tap"
const LONG_TAP := "long_tap"
const NO_INPUT := "no_input"

static func matches(required: String, actual: String, fever_active: bool = false) -> bool:
	if fever_active:
		return true
	if required == actual:
		return true
	if required == TAP and actual == DOUBLE_TAP:
		return true
	return false

static func get_hint(action: String) -> String:
	match action:
		TAP:
			return "TAP"
		DOUBLE_TAP:
			return "TAP TAP"
		LONG_TAP:
			return "HOLD"
		NO_INPUT:
			return "WAIT"
		_:
			return ""
