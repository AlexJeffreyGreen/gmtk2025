class_name ChessPiece extends Area2D

signal selected_piece(current_piece)
signal deselected_piece

@export var piece_data : PieceData
@onready var piece_sprite : Sprite2D = $"PieceSprite"

var current_position : Vector2i
var score_value : int :
	get:
		return piece_data.score_value


func _ready() -> void:
	_build_piece_from_data()
	_set_default_shader_values()
	selected_piece.connect(GameManager.set_selected_piece.bind())
	deselected_piece.connect(GameManager.deselect_piece.bind())
	
	
func _build_piece_from_data() -> void:
	if !piece_data:
		print("No piece data")
		return
	piece_sprite.texture = piece_data.texture

func _set_default_shader_values() -> void:
	piece_sprite.material.set("shader_parameter/type", 0)

		


func _on_mouse_entered() -> void:
	selected_piece.emit(self)

func _on_mouse_exited() -> void:
	deselected_piece.emit()
		
