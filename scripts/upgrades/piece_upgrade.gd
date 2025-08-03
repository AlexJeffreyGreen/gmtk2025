class_name PieceUpgrade extends Node2D

@export var piece_upgrade_data : PieceUpgradeData
@onready var upgrade_sprite: Sprite2D = $UpgradeSprite
@onready var piece_preview_sprite: Sprite2D = $PiecePreviewSprite

var current_position : Vector2i
var piece_selected : PieceData


func _ready() -> void:
	upgrade_sprite.texture = piece_upgrade_data.texture
	if piece_upgrade_data.piece_to_add:
		set_piece_select(piece_upgrade_data.piece_to_add)
	else:
		piece_preview_sprite.visible = false

func set_piece_select(piece_data : PieceData) -> void:
	piece_preview_sprite.texture = piece_data.texture
