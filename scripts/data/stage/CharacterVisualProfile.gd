extends RefCounted
class_name CharacterVisualProfile

const DEFAULT_CHARACTER_ID := "player1"

var id := DEFAULT_CHARACTER_ID
var run_frame_paths := []
var idle_texture_path := "res://assets/sprites/samurai/idle/player_stand.png"
var damage_texture_path := "res://assets/sprites/samurai/damage/player_damage.png"
var dead_texture_path := "res://assets/sprites/samurai/dead/dead.png"
var sword_sheath_texture_path := "res://assets/sprites/samurai/run/sword_sheath.png"
var sword_slash_texture_path := "res://assets/sprites/samurai/run/sword_slash.png"

static func make_default():
	return make_for_character(DEFAULT_CHARACTER_ID)

static func make_for_character(character_id: String):
	var profile = load("res://scripts/data/stage/CharacterVisualProfile.gd").new()
	profile.id = character_id if not character_id.is_empty() else DEFAULT_CHARACTER_ID
	profile.run_frame_paths = [
		"res://assets/sprites/samurai/run/frame_01.png",
		"res://assets/sprites/samurai/run/frame_02.png",
		"res://assets/sprites/samurai/run/frame_03.png",
		"res://assets/sprites/samurai/run/frame_04.png"
	]
	return profile
