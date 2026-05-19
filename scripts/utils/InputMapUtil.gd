extends RefCounted
class_name InputMapUtil

static func add_action_if_missing(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

static func add_key_event(action_name: String, keycode: Key) -> void:
	if action_has_key(action_name, keycode):
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)

static func add_mouse_event(action_name: String, button_index: MouseButton) -> void:
	if action_has_mouse(action_name, button_index):
		return
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

static func action_has_key(action_name: String, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false

static func action_has_mouse(action_name: String, button_index: MouseButton) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return true
	return false

static func remove_mouse_event(action_name: String, button_index: MouseButton) -> void:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			InputMap.action_erase_event(action_name, event)
