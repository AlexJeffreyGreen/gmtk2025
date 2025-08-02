extends Node

var chess_piece : PackedScene = preload("res://scenes/pieces/chess_piece.tscn")
var chess_piece_data : PieceData = preload("res://resources/pieces/pawn_white.tres")
var chess_enemy_piece_data : PieceData = preload("res://resources/pieces/pawn_black.tres")

var pieces = {}
var main_board_tile_map : MainBoard
var board_data : BoardData
var board_width : int = 6
var board_height : int = 20
var player_initial_spawn_points : Array[Vector2i] = [Vector2i(1,9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4,9)]
var enemy_initial_spawn_points : Array[Vector2i] = [Vector2i(1,2), Vector2i(2, 2), Vector2i(3,2), Vector2i(4,2)]

func _ready() -> void:
	board_data = BoardData.new()
	build_board()
	build_player_pieces()
	build_enemy_pieces()

func build_player_pieces() -> void:
	for spawn_position in player_initial_spawn_points as Array[Vector2i]:
		var new_chess_piece = chess_piece.instantiate() as ChessPiece
		new_chess_piece.current_position = spawn_position
		new_chess_piece.piece_data = chess_piece_data
		pieces.set(spawn_position, new_chess_piece)
		add_child(new_chess_piece)
	
func build_enemy_pieces() -> void:
	for spawn_position in enemy_initial_spawn_points as Array[Vector2i]:
		var new_chess_piece = chess_piece.instantiate() as ChessPiece
		new_chess_piece.current_position = spawn_position
		new_chess_piece.piece_data = chess_enemy_piece_data
		pieces.set(spawn_position, new_chess_piece)
		add_child(new_chess_piece)

	
func build_board() -> void:
	for y in range(-4, board_height + 4):
		for x in range(board_width):
			board_data.all_available_board_positions.append(Vector2i(x,y))
			pass
	#main_board_tile_map.redraw_board()

func is_within_board(current_pos : Vector2i) -> bool:
	return main_board_tile_map.get_cell_tile_data(current_pos) != null
	
func is_empty_or_enemy(current_pos: Vector2i) -> bool:
	return is_within_board(current_pos) or is_enemy(current_pos)
	
func is_enemy(current_pos: Vector2i) -> bool:
	return board_data.current_enemy_pieces.any(func(piece): return piece.current_position == current_pos)
	
func get_valid_moves_for_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	var moves : Array[Vector2i] = []
	for dir in GameManager.selected_piece.piece_data.moves["move"]:
		var current = chess_piece.current_position + dir
		if is_within_board(current) and is_empty_or_enemy(current):
			moves.append(current)
			if is_enemy(current):
				break
			current += dir
	#print(moves)
	return moves
	
func move_piece_to_selected_available_tile(selected_tile_coord : Vector2i) -> void:
	var local_pos_for_piece = main_board_tile_map.map_to_local(selected_tile_coord)
	var center_pos = local_pos_for_piece
	center_pos.y -= 20
	GameManager.selected_piece.position = center_pos
	GameManager.selected_piece.current_position = selected_tile_coord
	GameManager.selected_piece = null
	#GameManager.selected_piece.deselect_self()

class BoardData:
	var all_available_board_positions : Array[Vector2i]
	var all_current_player_pieces : Array[ChessPiece]
	var all_current_enemy_pieces : Array[ChessPiece]
