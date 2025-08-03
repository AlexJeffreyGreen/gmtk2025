class_name PieceData extends Resource

@export var texture : Texture2D
@export var demensions : Vector2i
@export var score_value : int
@export var name : String
@export var is_sliding_piece : bool
@export var piece_type : PIECE_TYPE

enum PIECE_TYPE {
	PAWN,
	KNIGHT,
	ROOK,
	BISHOP,
	QUEEN,
	KING
}

var moves :
	get:
		return DIRS[name]

const DIRS = {
	"pawn_white": {
		"move": [Vector2i(0, -1)],
		"double_move": Vector2i(0, -2),  # first move only
		"attack": [Vector2i(-1, -1), Vector2i(1, -1)]
	},
	"pawn_black": {
		"move": [Vector2i(0, 1)],
		"double_move": Vector2i(0, 2),
		"attack": [Vector2i(-1, 1), Vector2i(1, 1)]
	},
	"knight": {
		"move": [
			Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
			Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
		],
		"attack": [
			Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
			Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
		]
	},
	"bishop": { 
		"move" : [
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)
		], 
		"attack": [
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)
		]
	},
	"rook": {
		"move" : [
			Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)
		], 
		"attack": [
			Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)
		]
	},
	"queen": {
		"move": [
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
		],
		"attack": [
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
		]
	},
	"king": {
		"move": [
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
		], 
		"attack": [
			Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
			Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
		]
	}
}
