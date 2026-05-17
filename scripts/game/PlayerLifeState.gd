extends RefCounted
class_name PlayerLifeState

static func is_player_dead(hp: int, invincible: bool) -> bool:
	return hp <= 0 and not invincible

static func can_player_continue(hp: int, invincible: bool) -> bool:
	return not is_player_dead(hp, invincible)

static func show_dead_visual(player) -> void:
	if player != null and player.has_method("play_dead"):
		player.play_dead()
