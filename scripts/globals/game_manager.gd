extends Node

var selected_piece : ChessPiece


func _ready() -> void:
	pass

func set_selected_piece(new_selected_piece : ChessPiece) -> void:
	selected_piece = new_selected_piece
	print(new_selected_piece.name)

func deselect_piece() -> void:
	print("Removing " + selected_piece.name)
	selected_piece = null
	if !selected_piece:
		print("no selected piece")
