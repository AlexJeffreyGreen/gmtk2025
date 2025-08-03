class_name ChessPiece extends Area2D

signal selected_piece(current_piece)
signal deselected_piece

@export var piece_data : PieceData
@onready var piece_sprite : Sprite2D = $"PieceSprite"

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
	#BoardManager.selected_piece_set.connect(selected_piece_set.bind())
	#set_selected_shader_value(0, 0.0)
	#elected_piece.connect(BoardManager.set_selected_piece.bind())
	#deselected_piece.connect(GameManager.deselect_piece.bind())
	#piece_sprite.material.

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

func _process(delta: float) -> void:
	pass
	#if self != GameManager.selected_piece:
	#	set_selected_shader_value(0, Color.WHITE)

func _on_mouse_entered() -> void:
	is_mouse_over = true
	
func _on_mouse_exited() -> void:
	is_mouse_over = false
	#if GameManager.selected_piece != self:
	#	set_selected_shader_value(0, Color.WHITE)

func set_selected_shader_value(width : int, color : Color) -> void:
	(piece_sprite.material as ShaderMaterial).set_shader_parameter("width" , width)
	(piece_sprite.material as ShaderMaterial).set_shader_parameter("color", color)


#func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if !is_enemy and Input.is_action_just_pressed("select_piece"):
		#if BoardManager.current_selected_piece == null and is_mouse_over:
			##print(current_position)	
			#set_selected_shader_value(1, Color.GREEN)
			#selected_piece.emit(self)
		#else:
			#set_selected_shader_value(0, Color.WHITE)
			



#func _input(event: InputEvent) -> void:
	#pass
	#if Input.is_action_just_pressed("select_piece") and GameManager.selected_piece == self and !is_mouse_over and !GameManager.is_mouse_at_available_move():
		##print("deselected piece")
		#deselected_piece.emit()
		#set_selected_shader_value(0, Color.WHITE) 
