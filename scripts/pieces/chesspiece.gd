class_name ChessPiece extends Node2D

@export var piece_data : PieceData
@onready var piece_sprite : Sprite2D = $"PieceSprite"

var current_position : Vector2i

var score_value : int :
	get:
		return piece_data.score_value


func _ready() -> void:
	_build_piece_from_data()
	
func _build_piece_from_data() -> void:
	if !piece_data:
		print("No piece data")
		return
	piece_sprite.texture = piece_data.texture


		
