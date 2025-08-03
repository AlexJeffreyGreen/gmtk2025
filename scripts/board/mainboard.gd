class_name MainBoard
extends Node2D

@export var row_width : int = 6
@export var board_height : int = 10
@onready var board := $TileMapLayer

const TILE_WHITE = Vector2i(1, 0)
const TILE_BLACK = Vector2i(0, 0)
const TILE_AVAILBLE_SPACE = Vector2i(2, 0)
const TILE_ENEMY_SPACE = Vector2i(3, 0)
const TILE_SIZE = 64
const THRESHOLD = .3






##TEST
var chess_piece : PackedScene = preload("res://scenes/pieces/chess_piece.tscn")
var chess_piece_data : PieceData = preload("res://resources/pieces/pawn_white.tres")
var chess_enemy_piece_data : PieceData = preload("res://resources/pieces/pawn_black.tres")
var initial_player_piece_count : int = 4
##END TEST

var scroll_offset := 0.0
var speed := 64.0  # pixels per second
var target_scroll_offset : float = 0.0

var current_player_pieces : Array[ChessPiece]
var current_enemy_pieces : Array[ChessPiece]
var current_available_moves_for_selected_piece : Array[Vector2i]
#var current_board_tiles : Array[]

func _ready():
	GameManager.main_board_tile_map = self
	BoardManager.main_board_tile_map = self
	BoardManager.piece_spawner.new_spawned_enemy_wave.connect(redraw_pieces.bind())
	#BoardManager.upgrade_destroyed.connect(redraw_pieces.bind())
	position.x = get_viewport_rect().size.x / 2 - 192
	redraw_board()
	redraw_pieces(.2)

	
func generate_piece(spawn_position : Vector2i, chess_data : PieceData):
	var half_tile_size = board.tile_set.tile_size / 2
	var local_pos = board.map_to_local(spawn_position)
	var centered_pos = local_pos
	centered_pos.y -= 20
	var piece = chess_piece.instantiate() as ChessPiece
	piece.piece_data = chess_data
	piece.position = centered_pos  # Local position (not global!)
	piece.current_position = spawn_position
	current_player_pieces.append(piece)
	add_child(piece)


#
#func _process(delta):
	#scroll_offset += speed * delta
	#redraw_board()
func _process(delta: float) -> void:
	scroll_offset = lerp(scroll_offset, target_scroll_offset, .02)
	
	if abs(scroll_offset - target_scroll_offset) > THRESHOLD:
		redraw_board()
	elif scroll_offset != target_scroll_offset:
		scroll_offset = target_scroll_offset
		redraw_board()

	
func _input(event: InputEvent) -> void:
	pass
	#if Input.is_action_just_pressed("shoot"):
	#	_advance_x_rows(1)
	#if Input.is_action_just_pressed("select_piece"):
	#	get_tile_at_mouse_position()

func get_tile_at_mouse_position() -> void:
	var mouse_screen_pos = get_viewport().get_mouse_position()
	var mouse_local_pos = board.to_local(mouse_screen_pos)
	var tile_coords_at_mouse = board.local_to_map(mouse_local_pos)

func _advance_x_rows(row_count : int) -> void:
	target_scroll_offset += TILE_SIZE * row_count

func redraw_board() -> void:
	board.clear()
	var pixel_offset = int(scroll_offset) % TILE_SIZE
	board.position.y = pixel_offset

	for coord in BoardManager.all_available_board_positions:
		var tile_type = _get_tile_color_for_cell(coord)
		board.set_cell(coord, 0, tile_type, 0)
		#set_tile_coord_debug_text(coord)

#duplications in code, need to make generic
func redraw_pieces(piece_delay : float = .05) -> void:
	var ACC = 1
	for piece_key in BoardManager.pieces as Dictionary[Vector2i, ChessPiece]:
		var chess_piece = BoardManager.pieces[piece_key]
		var chess_position = piece_key
		var half_tile_size = board.tile_set.tile_size / 2
		var local_pos = board.map_to_local(chess_position)
		var global_pos = board.to_global(local_pos)
		if board.get_cell_tile_data(chess_position):
			chess_piece.global_position = global_pos
			chess_piece.piece_sprite.position.y = - 2
		ACC += 1
	ACC = 1
	for piece_key in BoardManager.upgrade_pieces as Dictionary[Vector2i, PieceUpgrade]:
		var upgrade_piece = BoardManager.upgrade_pieces[piece_key]
		var chess_position = piece_key
		var half_tile_size = board.tile_set.tile_size / 2
		var local_pos = board.map_to_local(chess_position)
		var global_pos = board.to_global(local_pos)
		if board.get_cell_tile_data(chess_position):
			upgrade_piece.global_position = global_pos
			upgrade_piece.upgrade_sprite.position.y = - 2
			upgrade_piece.piece_preview_sprite.position.y = -2
		ACC += 1

func _get_tile_color_for_cell(coord: Vector2i) -> Vector2i:
	var flip = coord.y % 2 == 0
	if flip:
		if coord.x % 2 != 0:
			return TILE_BLACK
		else:
			return TILE_WHITE
	else:
		if coord.x % 2 == 0:
			return TILE_BLACK
		else:
			return TILE_WHITE


func set_tile_coord_debug_text(coord : Vector2i) -> void:
	var local_pos = board.map_to_local(coord)
	var text_node : Label =Label.new()
	text_node.text = str(coord)
	text_node.add_theme_color_override("font_color", Color.BLACK)
	text_node.global_position = local_pos
	text_node.global_position.x = text_node.global_position.x - 20
	add_child(text_node)


func draw_available_moves_for_piece(avail_moves: Array[Vector2i], available_enemy_moves: Array[Vector2i]) -> void:
	redraw_board()
	for avail_move in avail_moves as Array[Vector2i]:
		board.set_cell(avail_move, 0, TILE_AVAILBLE_SPACE, 0)
	for avail_move in available_enemy_moves as Array[Vector2i]:
		board.set_cell(avail_move, 0, TILE_ENEMY_SPACE, 0)
	pass
		
func clear_available_moves() -> void:
	redraw_board()
	
	
