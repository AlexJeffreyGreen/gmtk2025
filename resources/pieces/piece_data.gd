class_name PieceData extends Resource

@export var texture : Texture2D
@export var demensions : Vector2i
@export var score_value : int
@export var name : String

var moves :
	get:
		return DIRS[name]

const DIRS = {
	"pawn_white": {
		"move": [Vector2i(0, -1)],
		"double_move": Vector2i(0, -2),  # first move only
		"capture": [Vector2i(-1, -1), Vector2i(1, -1)]
	},
	"pawn_black": {
		"move": [Vector2i(0, 1)],
		"double_move": Vector2i(0, 2),
		"capture": [Vector2i(-1, 1), Vector2i(1, 1)]
	},
	"knight": [
		Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
		Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
	],
	"bishop": [
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)
	],
	"rook": [
		Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)
	],
	"queen": [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
	],
	"king": [
		Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
		Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
	]
}
