class_name MainBoard
extends Node2D

@export var row_width : int = 6
@export var board_height : int = 10
@export var player_spawning_coords : Array[Vector2i]
@export var enemy_spawning_coords : Array[Vector2i]
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
	position.x = get_viewport_rect().size.x / 2
	redraw_board()
	initialize_and_respawn()
	GameManager.main_board = self
	GameManager.available_moves_change.connect(draw_available_moves_for_piece.bind())
	
func initialize_and_respawn() -> void:
	var used_cells = board.get_used_cells()
	#for cell in used_cells as Array[Vector2i]:
		#set_tile_coord_debug_text(cell)
	for spawn_position in player_spawning_coords as Array[Vector2i]:
		generate_piece(spawn_position, chess_piece_data)
	
	for spawn_position in enemy_spawning_coords as Array[Vector2i]:
		generate_piece(spawn_position, chess_enemy_piece_data)
	
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
		#print("snapping")
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("shoot"):
		_advance_x_rows(1)
		redraw_board()
	if Input.is_action_just_pressed("select_piece"):
		print(GameManager.selected_piece)
		var selected_available_move = GameManager.get_available_move_at_mouse()
		if selected_available_move:
			move_piece_to_selected_available_tile(selected_available_move)
			#GameManager.selected_piece.deselected_piece.emit()


func move_piece_to_selected_available_tile(selected_tile_coord : Vector2i) -> void:
	var local_pos_for_piece = board.map_to_local(selected_tile_coord)
	var center_pos = local_pos_for_piece
	center_pos.y -= 20
	GameManager.selected_piece.position = center_pos
	GameManager.selected_piece.current_position = selected_tile_coord
	GameManager.selected_piece.deselected_piece.emit()
	#GameManager.selected_piece.deselect_self()
	
	#GameManager.selected_piece.current_position = selected_tile_coord
	
	#GameManager.selected_piece.
		
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
			#set_tile_coord_debug_text(Vector2i(x, tile_y))
			board.set_cell(Vector2i(x, tile_y), 0,tile,0)
	board.position.y = + pixel_offset

func set_tile_coord_debug_text(coord : Vector2i) -> void:
	var local_pos = board.map_to_local(coord)
	var text_node : Label =Label.new()
	text_node.text = str(coord)
	text_node.add_theme_color_override("font_color", Color.BLACK)
	text_node.global_position = local_pos
	text_node.global_position.x = text_node.global_position.x - 20
	add_child(text_node)

func is_within_board(current_pos : Vector2i) -> bool:
	return board.get_cell_tile_data(current_pos) != null
	
func is_empty_or_enemy(current_pos: Vector2i) -> bool:
	return is_within_board(current_pos) or is_enemy(current_pos)
	
func is_enemy(current_pos: Vector2i) -> bool:
	return current_enemy_pieces.any(func(piece): return piece.current_position == current_pos)
	
func get_valid_moves_for_piece(chess_piece : ChessPiece) -> Array[Vector2i]:
	var moves : Array[Vector2i] = []
	for dir in GameManager.selected_piece.piece_data.moves["move"]:
		var current = chess_piece.current_position + dir
		if is_within_board(current) and is_empty_or_enemy(current):
			moves.append(current)
			if is_enemy(current):
				break
			current += dir
	print(moves)
	return moves
	
func draw_available_moves_for_piece(avail_moves) -> void:
	if !avail_moves:
		return
	clear_available_moves()
	for coord in avail_moves:
		var desired_tile_cell = null
		if is_enemy(coord):
			desired_tile_cell = TILE_ENEMY_SPACE
		elif is_within_board(coord):
			desired_tile_cell = TILE_AVAILBLE_SPACE
		if !current_available_moves_for_selected_piece.has(coord):
			current_available_moves_for_selected_piece.append(coord)
		board.set_cell(coord, 0, desired_tile_cell, 0)
		
func clear_available_moves() -> void:
	print("clear available moves")
	#wildly horrible, but game jam?
	redraw_board()
	#for coord in current_available_moves_for_selected_piece as Array[Vector2i]:
	#	board.set_cell(coord, 0, TILE_WHITE, 0)
	current_available_moves_for_selected_piece.clear()
	
	
