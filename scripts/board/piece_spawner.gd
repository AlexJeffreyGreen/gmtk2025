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


var enemy_wave_manifest : EnemyWaveManifest
var enemy_waves : Array[WavePreset]
var enemy_king_piece : PieceData = preload("res://resources/pieces/king_black.tres")
var enemy_king_spawn_points : Array[Vector2i] = [Vector2i(1,1), Vector2i(2, 1), Vector2i(3,1), Vector2i(4,1)]
var enemy_spawn_points : Array[Vector2i] = [Vector2i(1,2), Vector2i(2, 3), Vector2i(3,3), Vector2i(4,2)]


var player_king_piece : PieceData = preload("res://resources/pieces/king_white.tres")	
var player_king_spawn_points : Array[Vector2i] = [Vector2i(1,7), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4,7)]
var player_spawn_points : Array[Vector2i] = [Vector2i(1,9), Vector2i(2, 8), Vector2i(3, 8), Vector2i(4,9)]

var current_wave : int = 0
var current_wave_score_target : int
var current_wave_score : int = 0
var enemy_pieces_current_spawned : Array = []

func _ready() -> void:
	#enemy_wave_manifest = load("res://resources/waves/index.tres")
	#build_all_available_waves()
	spawn_initial_player_wave()
	#spawn_enemy_wave()

func build_all_available_waves() -> void:
	for path in enemy_wave_manifest.preset_wave_paths:
		var preset = load(path)
		if preset is WavePreset:
			enemy_waves.append(preset)
	enemy_waves.sort_custom(func(a, b): return int(a.difficulty_score) < int(b.difficulty_score) )

func spawn_initial_player_wave() -> void:
	if current_wave == 0:
		for x in range(4):
			var piece_data = player_pieces[0]#.filter(func(pd : PieceData): pd.piece_type == PieceData.PIECE_TYPE.PAWN)
			var coords = player_spawn_points[x]
			BoardManager.spawn_piece(piece_data, coords)

func spawn_enemy_wave() -> void:
	pass
		


func spawn_enemy_piece(piece_data : PieceData, coords : Vector2i) -> void:
	BoardManager.spawn_piece(piece_data, coords, true)
	
func get_king_spawn_position(is_player : bool) -> Vector2i:
	if is_player:
		return player_king_spawn_points.pick_random() 
	else:
		return enemy_king_spawn_points.pick_random()
