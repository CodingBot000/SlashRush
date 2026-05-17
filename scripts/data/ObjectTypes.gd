extends Node
class_name ObjectTypes

const GameBalance := preload("res://scripts/data/GameBalance.gd")

static func get_data(object_type: String) -> Dictionary:
	match object_type:
		"enemy_basic":
			return {
				"required_action": "tap",
				"is_good_item": false,
				"score": 100,
				"fever": 6,
				"damage": 1,
				"color": Color.html("#d39a42"),
				"label": "T",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT * 0.9, GameBalance.PLAYER_RENDER_HEIGHT * 0.9),
				"shape": "box",
				"texture": "res://assets/objects/scarecrow2.png",
				"slice_texture": "res://assets/objects/scarecrow1.png"
			}
		"enemy_fast":
			return {
				"required_action": "double_tap",
				"is_good_item": false,
				"score": 150,
				"fever": 10,
				"damage": 1,
				"color": Color.html("#b87932"),
				"label": "2",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT * 0.62 * 0.75 * 0.9, GameBalance.PLAYER_RENDER_HEIGHT * 1.2 * 0.75 * 0.9),
				"shape": "diamond",
				"texture": "res://assets/objects/red_ghost2.png",
				"slice_texture": "res://assets/objects/red_ghost1.png"
			}
		"enemy_armor":
			return {
				"required_action": "long_tap",
				"is_good_item": false,
				"score": 150,
				"fever": 10,
				"damage": 1,
				"color": Color.html("#7c8da5"),
				"label": "H",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT * 1.05 * 0.9 * 0.9, GameBalance.PLAYER_RENDER_HEIGHT * 1.4 * 0.9 * 0.9),
				"shape": "box",
				"texture": "res://assets/objects/drum2.png",
				"slice_texture": "res://assets/objects/drum1.png"
			}
		"coin":
			return {
				"required_action": "no_input",
				"is_good_item": true,
				"score": 20,
				"fever": 0,
				"damage": 0,
				"color": Color.html("#ffd84a"),
				"label": "$",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/objects/coin.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		"heal":
			return {
				"required_action": "no_input",
				"is_good_item": true,
				"score": 0,
				"fever": 0,
				"damage": 0,
				"color": Color.html("#38d878"),
				"label": "+",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/objects/apple.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		"fever_orb":
			return {
				"required_action": "no_input",
				"is_good_item": true,
				"score": 50,
				"fever": 25,
				"damage": 0,
				"color": Color.html("#57b7ff"),
				"label": "F",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/items/fever_orb.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		"bomb":
			return {
				"required_action": "tap",
				"is_good_item": false,
				"score": 80,
				"fever": 4,
				"damage": 1,
				"color": Color.html("#181820"),
				"label": "!",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/objects/apple_rotten.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		_:
			return {
				"required_action": "tap",
				"is_good_item": false,
				"score": 100,
				"fever": 6,
				"damage": 1,
				"color": Color.html("#d39a42"),
				"label": "T",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT, GameBalance.PLAYER_RENDER_HEIGHT),
				"shape": "box",
				"texture": "res://assets/objects/scarecrow2.png",
				"slice_texture": "res://assets/objects/scarecrow1.png"
			}

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
	match action:
		"tap":
			return "TAP"
		"double_tap":
			return "TAP TAP"
		"long_tap":
			return "HOLD"
		"no_input":
			return "WAIT"
		_:
			return ""
