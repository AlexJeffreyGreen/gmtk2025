extends Node


signal available_moves_change(moves)

var selected_piece : ChessPiece
var main_board : MainBoard

func _ready() -> void:
	pass

func set_selected_piece(new_selected_piece : ChessPiece) -> void:
	selected_piece = new_selected_piece
	var moves = main_board.get_valid_moves_for_piece(selected_piece) as Array[Vector2i]
	if moves:
		print("Available move: ", moves.size())
		available_moves_change.emit(moves)
		

func deselect_piece() -> void:
	print("Removing " + selected_piece.name)
	#selected_piece.deselect_self()
	selected_piece = null
	if !selected_piece:
		print("no selected piece")
	available_moves_change.emit(null)
		
func get_available_move_at_mouse():
	if selected_piece == null:
		return null
	var mouse_screen_pos = get_viewport().get_mouse_position()
	var mouse_local_pos = main_board.board.to_local(mouse_screen_pos)
	var tile_coords_at_mouse = main_board.board.local_to_map(mouse_local_pos)
	if (main_board.board.get_cell_tile_data(tile_coords_at_mouse) and main_board.current_available_moves_for_selected_piece.has(tile_coords_at_mouse)):
		return tile_coords_at_mouse
	else:
		return null
	#print("Tile at mouse:", tile_coords_at_mouse)
	#return main_board.current_available_moves_for_selected_piece.has(tile_coords_at_mouse)


	#print(board.current_available_moves_for_selected_piece)
	#if main_board.current_available_moves_for_selected_piece.has(tile_coords_at_mouse):
		#print("This is an available move: ", tile_coords_at_mouse)
		#return true
	#return false
