extends RefCounted
class_name DebugFlagsAccess

const DEBUG_FLAGS_PATH := "/root/DebugFlags"

static func get_debug_flags(owner: Node) -> Node:
	if owner == null:
		return null
	return owner.get_node_or_null(DEBUG_FLAGS_PATH)

static func is_player_invincible(owner: Node) -> bool:
	var debug_flags := get_debug_flags(owner)
	return debug_flags != null and bool(debug_flags.player_invincible)

static func should_start_in_boss(owner: Node) -> bool:
	var debug_flags := get_debug_flags(owner)
	return debug_flags != null and bool(debug_flags.start_in_boss)
