class_name PieceUpgradeData extends Resource

@export var upgrade_type : UPGRADE_TYPE
@export var texture : Texture2D
@export var piece_to_add : PieceData
@export var name : String
@export var rarity : int

enum UPGRADE_TYPE {
	RANK_UP,
	RANK_DOWN,
	ADD_PIECE
}

func get_piece_sprite(piece_data : PieceData) -> Texture2D:
	return piece_data.texture
	pass
