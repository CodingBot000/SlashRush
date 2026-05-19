extends RefCounted
class_name ObjectVisualCatalog

const GameBalance := preload("res://scripts/data/GameBalance.gd")

static func get_visual(object_type: String) -> Dictionary:
	match object_type:
		"enemy_basic":
			return {
				"color": Color.html("#d39a42"),
				"label": "T",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT * 0.9, GameBalance.PLAYER_RENDER_HEIGHT * 0.9),
				"shape": "box",
				"texture": "res://assets/objects/scarecrow2.png",
				"slice_texture": "res://assets/objects/scarecrow1.png"
			}
		"enemy_fast":
			return {
				"color": Color.html("#b87932"),
				"label": "2",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT * 0.62 * 0.75 * 0.9, GameBalance.PLAYER_RENDER_HEIGHT * 1.2 * 0.75 * 0.9),
				"shape": "diamond",
				"texture": "res://assets/objects/red_ghost2.png",
				"slice_texture": "res://assets/objects/red_ghost1.png"
			}
		"enemy_armor":
			return {
				"color": Color.html("#7c8da5"),
				"label": "H",
				"size": Vector2(GameBalance.PLAYER_RENDER_HEIGHT * 1.05 * 0.9 * 0.9, GameBalance.PLAYER_RENDER_HEIGHT * 1.4 * 0.9 * 0.9),
				"shape": "box",
				"texture": "res://assets/objects/drum2.png",
				"slice_texture": "res://assets/objects/drum1.png"
			}
		"coin":
			return {
				"color": Color.html("#ffd84a"),
				"label": "$",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/objects/coin.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		"heal":
			return {
				"color": Color.html("#38d878"),
				"label": "+",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/objects/apple.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		"fever_orb":
			return {
				"color": Color.html("#57b7ff"),
				"label": "F",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/items/fever_orb.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		"bomb":
			return {
				"color": Color.html("#181820"),
				"label": "!",
				"size": Vector2(GameBalance.PICKUP_RENDER_HEIGHT, GameBalance.PICKUP_RENDER_HEIGHT),
				"shape": "circle",
				"texture": "res://assets/objects/apple_rotten.png",
				"spawn_y_offset": -GameBalance.PICKUP_FLOAT_OFFSET
			}
		_:
			return get_visual("enemy_basic")
