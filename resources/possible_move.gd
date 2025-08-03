class_name PossibleMove extends Resource

var ranking : int #the ranking of the move itself
var piece : ChessPiece #piece that will move
var coordinates_of_move : Vector2i
var move_type : MOVE_TYPE
	
enum MOVE_TYPE
{
	MOVE,
	ATTACK,
	CHECK,
	CHECK_UNDER_THREAT,
	CHECKMATE,
	ATTACK_UNDER_THREAT,
	MOVE_UNDER_THREAT	
}
