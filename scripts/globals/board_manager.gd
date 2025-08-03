extends Node

var chess_piece : PackedScene = preload("res://scenes/pieces/chess_piece.tscn")
var piece_upgrade : PackedScene = preload("res://scenes/upgrades/piece_upgrade.tscn")
var piece_upgrade_manifest : PieceUpgradeManifest = preload("res://resources/upgrades/index.tres")
var all_available_piece_upgrades : Array[PieceUpgradeData]

var piece_data_collection : Array[PieceData] = [
		preload("res://resources/pieces/pawn_white.tres"), 
		preload("res://resources/pieces/knight_white.tres"),
		preload("res://resources/pieces/rook_white.tres"),
		preload("res://resources/pieces/bishop_white.tres"),
		preload("res://resources/pieces/queen_white.tres"),
	]



var pieces = {}
var upgrade_pieces = {}
var all_available_board_positions : Array[Vector2i]
var current_selected_piece : ChessPiece
var main_board_tile_map : MainBoard
var cpu : CpuPlayer
var piece_spawner : PieceSpawner
var board_width : int = 6
var board_height : int = 10
var player_initial_spawn_points : Array[Vector2i] = [Vector2i(1,9), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4,9)]
var enemy_initial_spawn_points : Array[Vector2i] = [Vector2i(1,3), Vector2i(2, 4), Vector2i(3,4), Vector2i(4,3)]
var valid_movement_moves : Array[Vector2i]
var valid_attacking_moves : Array[Vector2i]
var rows_advanced : int = 0
var advance_row_timer : Timer
var piece_deletion_timer : Timer
var pieces_are_moveable : bool = true
var piece_to_delete : ChessPiece


enum CURRENT_TURN {
	PLAYER,
	CPU
}

var current_turn : CURRENT_TURN
var previously_moved_pieces : Array[ChessPiece]
var piece_cache_threshold : int = 2

signal selected_piece_set(piece_selected)
signal piece_removed
signal cpu_turn_started
signal board_movement_finished
signal upgrade_piece_destroyed
#signal player_turn_started


func _ready() -> void:
#	board_data = BoardData.new()
	all_available_piece_upgrades = piece_upgrade_manifest.piece_collection
	build_board()
	cpu = preload("res://scripts/board/cpu_player.gd").new()
	add_child(cpu)
	cpu.cpu_turn_ended.connect(GameManager.evaluate_game_state.bind())
	
	piece_spawner = preload("res://scripts/board/piece_spawner.gd").new()
	add_child(piece_spawner)
	
	
	piece_removed.connect(GameManager.evaluate_game_state.bind())
	
	advance_row_timer = Timer.new()
	advance_row_timer.one_shot = true
	advance_row_timer.wait_time = 1
	advance_row_timer.timeout.connect(advance_row_timeout.bind())
	add_child(advance_row_timer)
	
	piece_deletion_timer = Timer.new()
	piece_deletion_timer.one_shot = true
	piece_deletion_timer.wait_time = .25
	piece_deletion_timer.timeout.connect(delay_piece_deletion_timeout.bind())
	add_child(piece_deletion_timer)
	

	

	
func spawn_piece(selected_piece_data : PieceData, coords : Vector2i, is_enemy : bool = false) -> void:
	var new_chess_piece = chess_piece.instantiate() as ChessPiece
	new_chess_piece.current_position = coords
	new_chess_piece.piece_data = selected_piece_data
	new_chess_piece.is_enemy = is_enemy
	new_chess_piece.chess_piece_advances_offscreen.connect(remove_piece_at.bind())
	pieces.set(coords, new_chess_piece)
	add_child(new_chess_piece)
	
func spawn_upgrade(coords: Vector2i) -> void:
	var piece_upgrade = piece_upgrade.instantiate() as PieceUpgrade
	piece_upgrade.piece_upgrade_data = get_weighted_random_resource()
	piece_upgrade.current_position = coords
	upgrade_pieces.set(coords, piece_upgrade)
	add_child(piece_upgrade)

func get_weighted_random_resource() -> PieceUpgradeData:
	var total_weight : float = 0.0
	var weights = []
	for upgrade in all_available_piece_upgrades:
		var weight = 1.0 / float(upgrade.rarity)
		weights.append(weight)
		total_weight += weight
	var rand = randf() * total_weight
	var cumulative = 0.0
	for i in range(all_available_piece_upgrades.size()):
		cumulative += weights[i]
		if rand < cumulative:
			return all_available_piece_upgrades[i]
	return all_available_piece_upgrades[-1]
		
	
func build_board() -> void:
	for y in range(0, board_height + 4):
		for x in range(board_width):
			all_available_board_positions.append(Vector2i(x,y))
			pass
	#main_board_tile_map.redraw_board()

func is_within_board(current_pos : Vector2i, board : Dictionary = pieces) -> bool:
	return main_board_tile_map.board.get_cell_tile_data(current_pos) != null# and main_board_tile_map.board.get_cell_tile_data(current_pos + Vector2i(0, 1)) != null
	
func is_empty_or_enemy(current_pos: Vector2i, board : Dictionary = pieces) -> bool:
	return is_within_board(current_pos, board) or is_enemy(current_pos, board)

func is_empty(current_pos: Vector2i, board : Dictionary = pieces) -> bool:
	return is_within_board(current_pos, board) and !is_enemy(current_pos, board) and !is_player_piece(current_pos, board)
	
func is_enemy(current_pos: Vector2i, board : Dictionary = pieces) -> bool:
	if !board.has(current_pos):
		return false
	var piece = board[current_pos]
	if piece == null:
		board.erase(current_pos)  # Clean up the bad key
		return false
	return piece.is_enemy
	
func is_enemy_or_player_piece(current_pos : Vector2i, board : Dictionary = pieces) -> bool:
	if !board.has(current_pos):
		return false
	var piece = board[current_pos]
	if piece == null:
		board.erase(current_pos)  # Clean up the bad key
		return false
	return piece != null
	
func is_player_piece(current_pos : Vector2i, board : Dictionary = pieces) -> bool:
	if !board.has(current_pos):
		return false
	var piece = board[current_pos]
	if piece == null:
		board.erase(current_pos)  # Clean up the bad key
		return false
	return !piece.is_enemy

	
func get_valid_moves_for_selected_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	var moves : Array[Vector2i] = []
	for dir in chess_piece.piece_data.moves["move"]:
		var current = chess_piece.current_position + dir
		while is_within_board(current):
			if is_empty(current):
				moves.append(current)
			else:
				break
			if not chess_piece.piece_data.is_sliding_piece:
				break
			current += dir	
	return moves
	
#func get_valid_moves_for_cpu_piece(chess_piece : ChessPiece) -> Array[Vector2i]:

func get_valid_attacking_moves_for_selected_piece(chess_piece : ChessPiece, board : Dictionary = pieces) -> Array[Vector2i]:
	var attacking_moves : Array[Vector2i] = []
	for dir in chess_piece.piece_data.moves["attack"]:
		var current = chess_piece.current_position + dir
		while is_within_board(current, board):
			if board.has(current):
				var other_piece = board[current] as ChessPiece
				if chess_piece.is_enemy and other_piece and !other_piece.is_enemy:
					attacking_moves.append(current)
				elif !chess_piece.is_enemy and other_piece and other_piece.is_enemy:
					attacking_moves.append(current)
				# Regardless of who it is, break here to stop sliding
				break
			if not chess_piece.piece_data.is_sliding_piece:
				break
			current += dir
	return attacking_moves

	
#func get_valid_attacking_moves_for_selected_piece(chess_piece : ChessPiece, board : Dictionary = pieces) -> Array[Vector2i]:
	#var attacking_moves : Array[Vector2i]
	#for dir in chess_piece.piece_data.moves["attack"]:
		#var current = chess_piece.current_position + dir
		#while is_within_board(current, board):
			#if !chess_piece.is_enemy:
				#if is_enemy(current, board):
					#attacking_moves.append(current)
					#break
			#else:
				#if is_player_piece(current, board):
					#attacking_moves.append(current)
					#break
			#
			#if not chess_piece.piece_data.is_sliding_piece:
				#break
			#current += dir
	#return attacking_moves
	
	
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

	if selected_coord == current_piece_coord:
		return

	if pieces.has(selected_coord):
		var target_piece = pieces[selected_coord]
		if target_piece.is_enemy:
			score(target_piece.piece_data.score_value)
		remove_piece_at(selected_coord)

	pieces[selected_coord] = pieces[current_piece_coord]
	pieces.erase(current_piece_coord)
	
	if upgrade_pieces.has(selected_coord):
		var target_upgrade = upgrade_pieces[selected_coord] as PieceUpgrade
		if chess_piece.is_enemy:
			print("destroying upgrade")
		else:
			match(target_upgrade.piece_upgrade_data.upgrade_type):
				PieceUpgradeData.UPGRADE_TYPE.RANK_UP:
					chess_piece.rebuild_piece_data(upgrade_piece(chess_piece.piece_data))
					pass
				PieceUpgradeData.UPGRADE_TYPE.RANK_DOWN:
					chess_piece.rebuild_piece_data(downgrade_piece(chess_piece.piece_data))
					pass
				PieceUpgradeData.UPGRADE_TYPE.ADD_PIECE:
					add_new_piece(current_piece_coord, target_upgrade.piece_upgrade_data)
					pass
		remove_upgrade_piece_at(selected_coord, target_upgrade)
		
	chess_piece.current_position = selected_coord

	main_board_tile_map.redraw_pieces()

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
	var removed = false
	var is_enemy_piece_removed = false
	if pieces.has(coord):
		var piece = pieces[coord]
		if piece:
			removed = true
			if piece.is_enemy:
				is_enemy_piece_removed = true
			piece_to_delete = piece
			piece_deletion_timer.start()
			#piece.queue_free()

		pieces.erase(coord)
		piece_removed.emit()
	if removed:
		if current_selected_piece != null:
			clear_current_selection()
		if is_enemy_piece_removed:
			pieces_are_moveable = false
			advance_row_timer.start()

func remove_upgrade_piece_at(coord: Vector2i, upgrade_piece : PieceUpgrade) -> void:
	var removed = false
	if upgrade_pieces.has(coord):
		var upgrade = upgrade_pieces[coord]
		if upgrade:
			removed = true
		upgrade_pieces.erase(coord)
		upgrade.queue_free()

func delay_piece_deletion_timeout() -> void:
	piece_to_delete.queue_free()
	piece_to_delete = null

func piece_advances_at(coord: Vector2i) -> void:
	#if pieces.has(coord):
	advance_row_timer.start()
	pieces_are_moveable = false
	
func advance_row_timeout() -> void:
	advance_board_by_x_rows()
	pieces_are_moveable = true

func score(score_val : int) -> void:
	print("scored: " , score_val)
	
func _input(event: InputEvent) -> void:
	if current_selected_piece:
		if Input.is_action_just_pressed("select_piece"):
			var position_at_mouse = get_tile_at_mouse_position()
			if valid_movement_moves.has(position_at_mouse) or valid_attacking_moves.has(position_at_mouse):
				move_piece_to_valid_coord(position_at_mouse, current_selected_piece)
				cpu_turn_started.emit()
			var piece_at_mouse = select_player_piece_at_mouse()
			if piece_at_mouse != null and current_selected_piece and piece_at_mouse != current_selected_piece and !piece_at_mouse.is_enemy:
				clear_current_selection()
				set_selected_piece(piece_at_mouse)
	else:
		if Input.is_action_just_pressed("select_piece"):
			var tmp_current_piece_at_mouse = select_player_piece_at_mouse()
			if tmp_current_piece_at_mouse && pieces_are_moveable:
				#can_select_piece = false
				set_selected_piece(tmp_current_piece_at_mouse)

		
var tweens_active = 0



func advance_board_by_x_rows(y: int = 1) -> void:
	var new_pieces : Dictionary = {}
	var new_upgrades : Dictionary = {}
	var tweens_active = 0

	for pos in pieces.keys():
		var piece: ChessPiece = pieces[pos]
		var new_pos = pos + Vector2i(0, y)

		if is_within_board(new_pos):
			tweens_active += 1
			# Animate to the new global position
			var world_target_pos = main_board_tile_map.board.to_global(
				main_board_tile_map.board.map_to_local(new_pos)
			)
			var tween = get_tree().create_tween()
			tween.tween_property(piece, "global_position", world_target_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(.5)

			tween.finished.connect(func():
				piece.current_position = new_pos
				new_pieces[new_pos] = piece
				tweens_active -= 1
				if tweens_active == 0:
					pieces = new_pieces
					board_movement_finished.emit()
			)
		else:
			# Handle any pieces that fall off the board
			piece.queue_free()
			
	for upgrades_pos in upgrade_pieces.keys():
		var upgrade : PieceUpgrade = upgrade_pieces[upgrades_pos]
		var new_pos = upgrades_pos + Vector2i(0, y)
		if is_within_board(new_pos):
			tweens_active += 1
			# Animate to the new global position
			var world_target_pos = main_board_tile_map.board.to_global(
				main_board_tile_map.board.map_to_local(new_pos)
			)
			var tween = get_tree().create_tween()
			tween.tween_property(upgrade, "global_position", world_target_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_delay(.5)

			tween.finished.connect(func():
				upgrade.current_position = new_pos
				new_upgrades[new_pos] = upgrade
				tweens_active -= 1
				if tweens_active == 0:
					upgrade_pieces = new_upgrades
					board_movement_finished.emit()
			)
			
			
	#Handle empty tween case
	if tweens_active == 0:
		board_movement_finished.emit()

#func retween_global_position_for_spawn(coord : Vector2i) -> void:
	#var piece : ChessPiece = pieces[coord]
	#var world_target_pos = main_board_tile_map.board.to_global(
				#main_board_tile_map.board.map_to_local(coord)
			#)
	#var tween = get_tree().create_tween()
	#tween.tween_property(piece, "global_position", world_target_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			#


func _on_piece_tween_complete() -> void:
	tweens_active -= 1
	if tweens_active == 0:
		board_movement_finished.emit()

	
func select_player_piece_at_mouse() -> ChessPiece:
	var position_at_mouse = get_tile_at_mouse_position()
	if pieces.has(position_at_mouse) and pieces[position_at_mouse] != null:
		var tmp_current_piece_at_mouse = pieces[position_at_mouse]
		if !tmp_current_piece_at_mouse.is_enemy:
			return tmp_current_piece_at_mouse
	return null
			

func get_tile_at_mouse_position() -> Vector2i:
	var global_mouse_pos = main_board_tile_map.board.get_global_mouse_position()
	var local_mouse_pos = main_board_tile_map.board.to_local(global_mouse_pos)
	var tile_coords = main_board_tile_map.board.local_to_map(local_mouse_pos)
	tile_coords.y -= rows_advanced
	return tile_coords
	
func get_all_possible_moves_for_cpu() -> Array[PossibleMove]:
	var all_possible_moves : Array[PossibleMove]
	for piece in pieces as Dictionary[Vector2i, ChessPiece]:
		var current_piece : ChessPiece = pieces[piece]
		if !current_piece.is_enemy:
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
			#possible board control ranking
			if is_under_threat(target_position, pieces):
				move_score -= 1
				new_possible_move.move_type = PossibleMove.MOVE_TYPE.ATTACK_UNDER_THREAT
			
			if previously_moved_pieces.has(new_possible_move.piece):
				move_score -= new_possible_move.piece.score_value

			
			new_possible_move.ranking = move_score + new_possible_move.piece.score_value
			all_possible_moves.append(new_possible_move)
		
		for target_position in all_moves:
			var move_score : int = 0
			var new_possible_move = PossibleMove.new()
			new_possible_move.coordinates_of_move = target_position
			new_possible_move.move_type = PossibleMove.MOVE_TYPE.MOVE
			new_possible_move.piece = pieces[piece]
			var center_bonus : int = 0
			if target_position.x in [2,3,4,5] and target_position.y in [2,3,4,5]:
				center_bonus += 1
			
			var future_threat_bonus : int = 0
			if would_have_los_to_piece(current_piece, target_position):
				future_threat_bonus += 4
			
			if is_under_threat(target_position, pieces):
				move_score -= 1
				new_possible_move.move_type = PossibleMove.MOVE_TYPE.MOVE_UNDER_THREAT
			
			if previously_moved_pieces.has(new_possible_move.piece):
				move_score -= new_possible_move.piece.score_value
			
			move_score += center_bonus + future_threat_bonus + new_possible_move.piece.score_value
			new_possible_move.ranking = move_score
			all_possible_moves.append(new_possible_move)
			
			#possibly do multiple potential checks?
		
	return all_possible_moves

func would_have_los_to_piece(piece : ChessPiece, target_position: Vector2i) -> bool:
	var return_value : bool = false
	var simulated_board = pieces.duplicate(true)
	simulated_board.erase(piece.current_position)
	simulated_board[target_position] = piece
	
	#check if new board allows for LOS
	var attack_positions = get_valid_attacking_moves_for_selected_piece(piece, simulated_board)
	for pos in attack_positions:
		if simulated_board.has(pos):
			var other = simulated_board[pos]
			if other and !other.is_enemy:
				return_value = true
	simulated_board.clear()
	simulated_board = null
	return return_value
	
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
	
func upgrade_piece(current: PieceData) -> PieceData:
	var index = piece_data_collection.find(current)
	if index == -1 or index >= piece_data_collection.size() -1:
		return current
	return piece_data_collection[index + 1]

func downgrade_piece(current: PieceData) -> PieceData:
	var index = piece_data_collection.find(current)
	if index <= 0:
		return current
	return piece_data_collection[index - 1]
	
func add_new_piece(previous_coords: Vector2i, piece_upgrade : PieceUpgradeData):
	spawn_piece(piece_upgrade.piece_to_add, previous_coords)
