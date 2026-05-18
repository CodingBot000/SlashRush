extends RefCounted
class_name HapticHooks

const HAPTIC_MANAGER_PATH := "/root/HapticManager"

static func vibrate_attack(owner: Node) -> void:
	var haptic_manager := _get_haptic_manager(owner)
	if haptic_manager != null and haptic_manager.has_method("vibrate_attack"):
		haptic_manager.vibrate_attack()

static func vibrate_player_hurt(owner: Node) -> void:
	var haptic_manager := _get_haptic_manager(owner)
	if haptic_manager != null and haptic_manager.has_method("vibrate_player_hurt"):
		haptic_manager.vibrate_player_hurt()

static func _get_haptic_manager(owner: Node) -> Node:
	if owner == null:
		return null
	return owner.get_node_or_null(HAPTIC_MANAGER_PATH)
