class_name MainBoard
extends Node2D

@export var row_width : int = 6
@export var board_height : int = 10
@onready var board := $TileMapLayer

const TILE_WHITE = Vector2i(1, 0)
const TILE_BLACK = Vector2i(0, 0)
const TILE_SIZE = 64
const THRESHOLD = .3


##TEST
var chess_piece : PackedScene = preload("res://scenes/pieces/chess_piece.tscn")
var chess_piece_data : PieceData = preload("res://resources/pieces/pawn_white.tres")
var chess_enemy_piece_data : PieceData = preload("res://resources/pieces/pawn_black.tres")
##END TEST

var scroll_offset := 0.0
var speed := 64.0  # pixels per second
var target_scroll_offset : float = 0.0

var current_player_pieces : Array[ChessPiece]
var current_enemy_pieces : Array[ChessPiece]

func _ready():
	position.x = get_viewport_rect().size.x / 2
	redraw_board()
	test_populate_chess_pieces()
	
func test_populate_chess_pieces() -> void:
	var used_cells = board.get_used_cells()  # `board` is a TileMapLayer
	for x in range(2):
		
		if used_cells.is_empty():
			print("No used cells found on the TileMapLayer.")
			return
			
		var half_tile_size = board.tile_set.tile_size / 2
		#print(half_tile_size)
		var random_index = randi_range(2, used_cells.size() - 2)
		var cell_coords = used_cells[random_index]#[min(randi() % used_cells.size() - 2]
		
		# Convert cell coords to local position in pixels
		var local_pos = board.map_to_local(cell_coords)

		# Center of the tile
		var tile_size = board.tile_set.tile_size
		var centered_pos = local_pos# + (tile_size + 8.0)
		centered_pos.y -= 8
		# Instance the chess piece and set its position
		var piece = chess_piece.instantiate() as ChessPiece
		piece.piece_data = chess_piece_data
		piece.position = centered_pos  # Local position (not global!)
		piece.current_position = cell_coords
		current_player_pieces.append(piece)
		
		# Add it to the *same parent* as the TileMapLayer
		add_child(piece)
		
	for x in range(2):
		var half_tile_size = board.tile_set.tile_size / 2
		#print(half_tile_size)
		var random_index = randi_range(2, used_cells.size() - 2)
		var cell_coords = used_cells[random_index]#[min(randi() % used_cells.size() - 2]
		
		# Convert cell coords to local position in pixels
		var local_pos = board.map_to_local(cell_coords)

		# Center of the tile
		var tile_size = board.tile_set.tile_size
		var centered_pos = local_pos# + (tile_size + 8.0)
		centered_pos.y -= 8
		# Instance the chess piece and set its position
		var piece = chess_piece.instantiate() as ChessPiece
		piece.piece_data = chess_enemy_piece_data
		piece.position = centered_pos  # Local position (not global!)
		piece.current_position = cell_coords
		current_enemy_pieces.append(piece)
		# Add it to the *same parent* as the TileMapLayer
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
		print("snapping")
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("shoot"):
		_advance_x_rows(1)
		#target_scroll_offset += TILE_SIZE 
		#slow_scroll_x_tiles(1)
		redraw_board()
		
func _advance_x_rows(row_count : int) -> void:
	target_scroll_offset += TILE_SIZE * row_count

func redraw_board():
	board.clear()

	var top_row_f = scroll_offset / TILE_SIZE
	var top_row_i = floori(top_row_f)
	var pixel_offset = int(scroll_offset) % TILE_SIZE

	for visual_y in range(-3, board_height + 2):
		var row_index = top_row_i + visual_y
		var tile_y = visual_y

		var flip = row_index % 2 == 0
		for x in range(-(row_width / 2) , row_width - (row_width / 2)):
			var tile = TILE_WHITE
			if flip:
				if x % 2 != 0: tile = TILE_BLACK
			else:
				if x % 2 == 0: tile = TILE_BLACK

			board.set_cell(Vector2i(x, tile_y), 0,tile,0)
	board.position.y = + pixel_offset

func is_within_board(current_pos : Vector2i) -> bool:
	return board.get_cell_tile_data(current_pos) != null
	
func is_empty_or_enemy(current_pos: Vector2i) -> bool:
	return is_within_board(current_pos) or is_enemy(current_pos)
	
func is_enemy(current_pos: Vector2i) -> bool:
	return current_enemy_pieces.any(func(piece): return piece.current_position == current_pos)
	
func get_valid_moves_for_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	var moves : Array[Vector2i] = []
	for dir in chess_piece.chess_piece_data.moves:
		var current = chess_piece.current_position + dir
		while is_within_board(current) and is_empty_or_enemy(current):
			moves.append(current)
			if is_enemy(current):
				break
			current += dir
	return moves
	
