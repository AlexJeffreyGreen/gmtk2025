class_name ChessPiece extends Area2D

signal selected_piece(current_piece)
signal deselected_piece
signal chess_piece_fell_offscreen(current_position)
signal chess_piece_advances_offscreen(current_position)

@export var piece_data : PieceData
@onready var piece_sprite : Sprite2D = $"PieceSprite"
@onready var top_visible_on_screen_notifier: VisibleOnScreenNotifier2D = $TopVisibleOnScreenNotifier

#var selected_material : Material = preload("res://assets/material/chess_piece_material.tres")
var available_colors : Array[Color] = [Color.ORANGE, Color.RED, Color.BLUE]
var is_mouse_over : bool = false
var current_position : Vector2i
var score_value : int :
	get:
		return piece_data.score_value
var is_enemy : bool = false


func _ready() -> void:	
	_build_piece_from_data()
	_build_shader()
	global_position = Vector2(get_viewport_rect().size.x / 2, -50)
	if is_enemy:
		top_visible_on_screen_notifier.disconnect("screen_exited", _on_top_visible_on_screen_notifier_screen_exited)
	
#func move_to_spawned_position(world_target_pos : Vector2) -> void:

func _build_shader() -> void:
	var base_texture = piece_sprite.texture
	var new_texture = base_texture.duplicate(true)
	new_texture.resource_local_to_scene = true
	piece_sprite.texture = new_texture
	piece_sprite.material = null
	var shader = load("res://shaders/chess_piece.gdshader") # Don't duplicate
	var new_material = ShaderMaterial.new()
	new_material.shader = shader
	new_material.set_shader_parameter("width", 0)
	new_material.set_shader_parameter("pattern", 2)
	new_material.set_shader_parameter("inside", false)
	new_material.set_shader_parameter("color", Color.WHITE)
	piece_sprite.material = new_material

func _build_piece_from_data() -> void:
	if !piece_data:
		print("No piece data")
		return
	piece_sprite.texture = piece_data.texture

func rebuild_piece_data(chess_piece_data : PieceData) ->  void:
	piece_data = chess_piece_data
	_build_piece_from_data()

func _process(delta: float) -> void:
	pass

func _on_mouse_entered() -> void:
	is_mouse_over = true
	
func _on_mouse_exited() -> void:
	is_mouse_over = false

func set_selected_shader_value(width : int, color : Color) -> void:
	(piece_sprite.material as ShaderMaterial).set_shader_parameter("width" , width)
	(piece_sprite.material as ShaderMaterial).set_shader_parameter("color", color)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	pass # Replace with function body.

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	chess_piece_fell_offscreen.emit(current_position)

func _on_top_visible_on_screen_notifier_screen_exited() -> void:
	chess_piece_advances_offscreen.emit(current_position)
	#pass # Replace with function body.
