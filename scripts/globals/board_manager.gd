extends Node

var chess_piece : PackedScene = preload("res://scenes/pieces/chess_piece.tscn")
var chess_piece_knight_data : PieceData = preload("res://resources/pieces/knight_white.tres")
var chess_piece_bishop_data : PieceData = preload("res://resources/pieces/bishop_white.tres")
var chess_piece_rook_data : PieceData = preload("res://resources/pieces/rook_white.tres")
var chess_piece_queen_data : PieceData = preload("res://resources/pieces/queen_white.tres")
var chess_piece_king_data : PieceData = preload("res://resources/pieces/king_white.tres")
var chess_piece_data : PieceData = preload("res://resources/pieces/pawn_white.tres")
var chess_enemy_piece_data : PieceData = preload("res://resources/pieces/pawn_black.tres")
var chess_enemy_knight_data : PieceData = preload("res://resources/pieces/knight_black.tres")

var pieces = {}
var all_available_board_positions : Array[Vector2i]
var current_selected_piece : ChessPiece
var main_board_tile_map : MainBoard
var cpu : CpuPlayer
var board_width : int = 6
var board_height : int = 20
var player_initial_spawn_points : Array[Vector2i] = [Vector2i(1,9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4,9)]
var enemy_initial_spawn_points : Array[Vector2i] = [Vector2i(2,8), Vector2i(4, 8), Vector2i(3,2), Vector2i(4,2)]
var valid_movement_moves : Array[Vector2i]
var valid_attacking_moves : Array[Vector2i]

enum CURRENT_TURN {
	PLAYER,
	CPU
}

var current_turn : CURRENT_TURN

signal selected_piece_set(piece_selected)
signal cpu_turn_started
signal player_turn_started


func _ready() -> void:
#	board_data = BoardData.new()
	build_board()
	build_player_pieces()
	build_enemy_pieces()
	cpu = preload("res://scripts/board/cpu_player.gd").new()
	add_child(cpu)


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
		new_chess_piece.piece_data = chess_enemy_knight_data
		new_chess_piece.is_enemy = true
		pieces.set(spawn_position, new_chess_piece)
		add_child(new_chess_piece)

	
func build_board() -> void:
	for y in range(-4, board_height + 4):
		for x in range(board_width):
			all_available_board_positions.append(Vector2i(x,y))
			pass
	#main_board_tile_map.redraw_board()

func is_within_board(current_pos : Vector2i) -> bool:
	return main_board_tile_map.board.get_cell_tile_data(current_pos) != null
	
func is_empty_or_enemy(current_pos: Vector2i) -> bool:
	return is_within_board(current_pos) or is_enemy(current_pos)

func is_empty(current_pos: Vector2i) -> bool:
	return is_within_board(current_pos) and !is_enemy(current_pos) and !is_player_piece(current_pos)
	
func is_enemy(current_pos: Vector2i) -> bool:
	if !pieces.has(current_pos):
		return false
	var piece = pieces[current_pos]
	if piece == null:
		pieces.erase(current_pos)  # Clean up the bad key
		return false
	return piece.is_enemy
	
func is_enemy_or_player_piece(current_pos : Vector2i) -> bool:
	if !pieces.has(current_pos):
		return false
	var piece = pieces[current_pos]
	if piece == null:
		pieces.erase(current_pos)  # Clean up the bad key
		return false
	return piece != null
	
func is_player_piece(current_pos : Vector2i) -> bool:
	if !pieces.has(current_pos):
		return false
	var piece = pieces[current_pos]
	if piece == null:
		pieces.erase(current_pos)  # Clean up the bad key
		return false
	return !piece.is_enemy

	
func get_valid_moves_for_selected_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	var moves : Array[Vector2i] = []
	var movement_moves : Array[Vector2i]
	for dir in chess_piece.piece_data.moves["move"]:
		var current = chess_piece.current_position + dir
		while is_within_board(current):
			if is_empty(current):
				movement_moves.append(current)
			else:
				break
			if not chess_piece.piece_data.is_sliding_piece:
				break
			current += dir	
	return movement_moves
	
#func get_valid_moves_for_cpu_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	
func get_valid_attacking_moves_for_selected_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	var attacking_moves : Array[Vector2i]
	for dir in chess_piece.piece_data.moves["attack"]:
		var current = chess_piece.current_position + dir
		while is_within_board(current):
			if !chess_piece.is_enemy:
				if is_enemy(current):
					attacking_moves.append(current)
					break
			else:
				if is_player_piece(current):
					attacking_moves.append(current)
					break
			if not chess_piece.piece_data.is_sliding_piece:
				break
			current += dir
	return attacking_moves
	
	
func set_selected_piece(selected_piece : ChessPiece) -> void:
	if (pieces[selected_piece.current_position]):
		current_selected_piece = selected_piece as ChessPiece
		get_all_valid_potential_moves()
		current_selected_piece.set_selected_shader_value(1, Color.GREEN)
		
func get_all_valid_potential_moves() -> void:
	valid_movement_moves = get_valid_moves_for_selected_piece(current_selected_piece)
	valid_attacking_moves = get_valid_attacking_moves_for_selected_piece(current_selected_piece)
	for attacking_move in valid_attacking_moves:
		if valid_movement_moves.has(attacking_move):
			valid_movement_moves.erase(attacking_move)
	main_board_tile_map.draw_available_moves_for_piece(valid_movement_moves, valid_attacking_moves)
	
func move_piece_to_valid_coord(selected_coord : Vector2i, chess_piece : ChessPiece) -> void:
	var current_piece_coord = chess_piece.current_position

	# Don't allow moving to the same square
	if selected_coord == current_piece_coord:
		return

	# Handle attack if enemy present
	if pieces.has(selected_coord):
		var target_piece = pieces[selected_coord]
		if target_piece.is_enemy:
			score(target_piece.piece_data.score_value)
		#else:
			#clear_current_selection()
		#	return
		remove_piece_at(selected_coord)

	# Move piece to new position
	pieces[selected_coord] = pieces[current_piece_coord]
	pieces.erase(current_piece_coord)
	chess_piece.current_position = selected_coord

	#main_board_tile_map.re
	main_board_tile_map.redraw_pieces()
	# Reposition the visual representation
	#var local_pos = main_board_tile_map.board.map_to_local(selected_coord)
	#var global_pos = main_board_tile_map.board.to_global(local_pos)
	#global_pos.y -= 20  # adjust sprite Y if needed
#
	#if main_board_tile_map.board.get_cell_tile_data(selected_coord):
		#current_selected_piece.global_position = global_pos
	if current_selected_piece:
		clear_current_selection()
	main_board_tile_map.redraw_board()
	
func clear_current_selection() -> void:
	current_selected_piece.set_selected_shader_value(0, Color.WHITE)
	current_selected_piece = null
	clear_available_moves()
	#main_board_tile_map.redraw_board()	

func clear_available_moves() -> void:
	valid_attacking_moves.clear()
	valid_movement_moves.clear()

func remove_piece_at(coord: Vector2i) -> void:
	if pieces.has(coord):
		var piece = pieces[coord]
		if piece:
			piece.queue_free()
		pieces.erase(coord)


func score(score_val : int) -> void:
	print("scored: " , score_val)
	
func _input(event: InputEvent) -> void:
	if current_selected_piece:
		if Input.is_action_just_pressed("select_piece"):
			var position_at_mouse = get_tile_at_mouse_position()
			print("Position at Moue ", position_at_mouse)
			if valid_movement_moves.has(position_at_mouse) or valid_attacking_moves.has(position_at_mouse):
				move_piece_to_valid_coord(position_at_mouse, current_selected_piece)
				cpu_turn_started.emit()
			var piece_at_mouse = select_player_piece_at_mouse()
			if piece_at_mouse != null and current_selected_piece and piece_at_mouse != current_selected_piece and !piece_at_mouse.is_enemy:
				clear_current_selection()
				set_selected_piece(piece_at_mouse)

			#if select_player_piece_at_mouse() != current_selected_piece and select_player_piece_at_mouse().is_e
	else:
		if Input.is_action_just_pressed("select_piece"):
			var tmp_current_piece_at_mouse = select_player_piece_at_mouse()
			if tmp_current_piece_at_mouse:
				set_selected_piece(tmp_current_piece_at_mouse)
	
	if Input.is_action_just_pressed("advance_row"):
		pass


func select_player_piece_at_mouse() -> ChessPiece:
	var position_at_mouse = get_tile_at_mouse_position()
	if pieces.has(position_at_mouse) and pieces[position_at_mouse] != null:
		var tmp_current_piece_at_mouse = pieces[position_at_mouse]
		if !tmp_current_piece_at_mouse.is_enemy:
			return tmp_current_piece_at_mouse
	return null
			

func get_tile_at_mouse_position() -> Vector2i:
	var mouse_screen_pos = get_viewport().get_mouse_position()
	var mouse_local_pos = main_board_tile_map.board.to_local(mouse_screen_pos)
	var tile_coords_at_mouse = main_board_tile_map.board.local_to_map(mouse_local_pos)
	return tile_coords_at_mouse
	
func get_all_possible_moves_for_cpu() -> Array[PossibleMove]:
	var all_possible_moves : Array[PossibleMove]
	for piece in pieces as Dictionary[Vector2i, ChessPiece]:
		var current_piece : ChessPiece = pieces[piece]
		if !current_piece.is_enemy:
			print("piece is not enemy")
			continue
		
		var all_attacks = get_valid_attacking_moves_for_selected_piece(current_piece)
		var all_moves = get_valid_moves_for_selected_piece(current_piece)
		
		for target_position in all_attacks:
			var move_score : int = 0
			var new_possible_move = PossibleMove.new()
			new_possible_move.coordinates_of_move = target_position
			new_possible_move.move_type = PossibleMove.MOVE_TYPE.ATTACK
			new_possible_move.piece = pieces[piece]
			
			if pieces[target_position] != null and pieces.has(target_position):
				var target_at_coords = pieces[target_position] as ChessPiece
				if target_at_coords and !target_at_coords.is_enemy:
					move_score += target_at_coords.piece_data.score_value
					print(move_score)
			#possible board control ranking
			if is_under_threat(target_position, pieces):
				print("is under threat")
				move_score -= 1
				new_possible_move.move_type = PossibleMove.MOVE_TYPE.ATTACK_UNDER_THREAT
				

			
			new_possible_move.ranking = move_score
			all_possible_moves.append(new_possible_move)
		
		for target_position in all_moves:
			var move_score : int = 0
			var new_possible_move = PossibleMove.new()
			new_possible_move.coordinates_of_move = target_position
			new_possible_move.move_type = PossibleMove.MOVE_TYPE.MOVE
			new_possible_move.piece = pieces[piece]
			
			if is_under_threat(target_position, pieces):
				move_score -= 1
				new_possible_move.move_type = PossibleMove.MOVE_TYPE.MOVE_UNDER_THREAT

			new_possible_move.ranking = move_score
			all_possible_moves.append(new_possible_move)
			
			#possibly do multiple potential checks?
		
	return all_possible_moves
	
func is_under_threat(possible_position : Vector2i, all_pieces: Dictionary) -> bool:
	for other_pieces in all_pieces:
		if !all_pieces.has(possible_position):
			return false
		var other_piece = all_pieces[possible_position]
		if !other_piece.is_enemy:
			continue
		var attack_moves = get_valid_attacking_moves_for_selected_piece(other_piece)
		if possible_position in attack_moves:
			return true
	return false
	

#func _process(delta: float) -> void:
	#print(current_selected_piece)
