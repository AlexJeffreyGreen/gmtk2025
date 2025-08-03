class_name PieceSpawner extends Node

var enemy_pieces : Array[PieceData] = [
		preload("res://resources/pieces/pawn_black.tres"), 
		preload("res://resources/pieces/knight_black.tres"),
		preload("res://resources/pieces/rook_black.tres"),
		preload("res://resources/pieces/bishop_black.tres"),
		preload("res://resources/pieces/queen_black.tres"),
	]
	
var player_pieces : Array[PieceData] = [
		preload("res://resources/pieces/pawn_white.tres"), 
		preload("res://resources/pieces/knight_white.tres"),
		preload("res://resources/pieces/rook_white.tres"),
		preload("res://resources/pieces/bishop_white.tres"),
		preload("res://resources/pieces/queen_white.tres"),
	]


var enemy_wave_manifest : SpawnWaveManifest = preload("res://resources/waves/index.tres")
var enemy_waves : Array[SpawnWave]
var enemy_king_piece : PieceData = preload("res://resources/pieces/king_black.tres")
var enemy_king_spawn_points : Array[Vector2i] = [Vector2i(1,1), Vector2i(2, 1), Vector2i(3,1), Vector2i(4,1)]
var enemy_spawn_points : Array[Vector2i] = [Vector2i(1,2), Vector2i(2, 2), Vector2i(3,2), Vector2i(4,2)]


var player_king_piece : PieceData = preload("res://resources/pieces/king_white.tres")	
var player_king_spawn_points : Array[Vector2i] = [Vector2i(1,7), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4,7)]
var player_spawn_points : Array[Vector2i] = [Vector2i(1,8), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4,8), Vector2i(1,9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(4,9)]

var current_wave : int = 0
var current_wave_score_target : int
var current_wave_score : int = 0
var enemy_pieces_current_spawned : Array = []
var previous_spawn_was_empty : bool = true
var initial_spawn : bool = false

var player_initial_spawn_collection : Array[String] = ["p", "p", "p", "p", "b", "n", "n", "b"]

signal new_spawned_enemy_wave

func _ready() -> void:	
	initial_spawn = true
	spawn_initial_player_wave()
	spawn_new_enemy_wave()

	BoardManager.board_movement_finished.connect(spawn_new_enemy_wave.bind())

func spawn_initial_player_wave() -> void:
	for i in range(min(player_initial_spawn_collection.size(), player_spawn_points.size())):
		var piece_code = player_initial_spawn_collection[i]
		var coords = player_spawn_points[i]
		var piece_data = get_piece_data_from_char(piece_code, true)
		if piece_data != null:
			BoardManager.spawn_piece(piece_data, coords)


func spawn_new_enemy_wave() -> void:
	if initial_spawn:
		initial_spawn = false
		var initial_wave : SpawnWave = enemy_wave_manifest.initial_wave
		for x in range(initial_wave.piece_coords.size()):
			var coords = initial_wave.piece_coords[x]
			var piece = get_piece_data_from_char(initial_wave.piece_layout[x])
			if coords != null and piece != null:
				spawn_enemy_piece(coords, piece)
	else:
		if !previous_spawn_was_empty:
			previous_spawn_was_empty = true
			return
		var random_wave : SpawnWave = enemy_wave_manifest.spawn_wave_collection.pick_random()
		previous_spawn_was_empty = false
		for x in range(random_wave.piece_coords.size()):# - BoardManager.pieces):
			var coords = random_wave.piece_coords[x]
			var piece = get_piece_data_from_char(random_wave.piece_layout[x])
			if coords != null and piece != null:
				spawn_enemy_piece(coords, piece)

	
	for x in range(4):
		var upgrade_position = BoardManager.all_available_board_positions.pick_random()
		if !BoardManager.pieces.has(upgrade_position):
			BoardManager.spawn_upgrade(upgrade_position)	
	pass
	new_spawned_enemy_wave.emit()

#func set_spawned_enemy_location()

func spawn_enemy_piece(coords : Vector2i, piece_data : PieceData) -> void:
	BoardManager.spawn_piece(piece_data, coords, true)
	
func get_king_spawn_position(is_player : bool) -> Vector2i:
	if is_player:
		return player_king_spawn_points.pick_random() 
	else:
		return enemy_king_spawn_points.pick_random()

func get_spawn_row_count_for_current_wave() -> int:
	if current_wave <= 3:
		return 1
	elif current_wave <= 5:
		return 2
	else:
		return 3

func get_piece_data_from_char(c : String, is_player : bool = false) -> PieceData:
	var collection = player_pieces if is_player else enemy_pieces
	match c.to_lower():
		"p": return find_piece_data(collection, PieceData.PIECE_TYPE.PAWN)
		"n": return find_piece_data(collection, PieceData.PIECE_TYPE.KNIGHT)
		"r": return find_piece_data(collection, PieceData.PIECE_TYPE.ROOK)
		"b": return find_piece_data(collection, PieceData.PIECE_TYPE.BISHOP)
		"q": return find_piece_data(collection, PieceData.PIECE_TYPE.QUEEN)
		"k": return player_king_piece if is_player else enemy_king_piece
		_: return null

func find_piece_data(pieces : Array, piece_enum : int) -> PieceData:
	for piece_data in pieces:
		if piece_data.piece_type == piece_enum:
			return piece_data
	return null
