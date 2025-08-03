extends Node


signal available_moves_change(moves)

var selected_piece : ChessPiece
var main_board_tile_map : MainBoard

func _ready() -> void:
	BoardManager.player_turn_started.connect(evaluate_game_state.bind())
	
func evaluate_game_state() -> void:
	var at_least_one_move_is_available : bool
	for piece in BoardManager.pieces:
		var chess_piece = BoardManager.pieces[piece] as ChessPiece
		if !chess_piece.is_enemy:
			var available_attacks = BoardManager.get_valid_attacking_moves_for_selected_piece(chess_piece)
			var available_moves = BoardManager.get_valid_moves_for_selected_piece(chess_piece)
			if (available_attacks.size() > 0 or available_moves.size() > 0):
				at_least_one_move_is_available = true
	if at_least_one_move_is_available == false:
		print("You lose!")
