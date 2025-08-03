class_name CpuPlayer extends Node2D

const MOVE_TYPE_PRIORITY = {
	PossibleMove.MOVE_TYPE.CHECKMATE: 6,
	PossibleMove.MOVE_TYPE.CHECK: 5,
	PossibleMove.MOVE_TYPE.ATTACK: 4,
	PossibleMove.MOVE_TYPE.MOVE: 3,
	PossibleMove.MOVE_TYPE.ATTACK_UNDER_THREAT: 2,
	PossibleMove.MOVE_TYPE.MOVE_UNDER_THREAT: 1,
	PossibleMove.MOVE_TYPE.CHECK_UNDER_THREAT: 0
}

signal cpu_turn_ended

var move_timer : Timer
#var cpu_wait_for_board_move_timer : Timer


func _ready() -> void:
	BoardManager.cpu_turn_started.connect(_on_cpu_turn_started.bind())
	move_timer = Timer.new()
	move_timer.one_shot = true
	move_timer.autostart = false
	move_timer.wait_time = 1
	move_timer.timeout.connect(delay_cpu_move.bind())
	add_child(move_timer)
	
	
func delay_cpu_move() -> void:
	var all_possible_moves = BoardManager.get_all_possible_moves_for_cpu() as Array[PossibleMove]
	if all_possible_moves.is_empty():
		print("No more moves to make.")
		cpu_turn_ended.emit()
		return
	
	var grouped_moves : Dictionary = {}
	for move in all_possible_moves:
		var priority = MOVE_TYPE_PRIORITY.get(move.move_type, -1)
		if !grouped_moves.has(priority):
			grouped_moves[priority] = []
		grouped_moves[priority].append(move)
	
	var sorted_priorities = grouped_moves.keys()
	sorted_priorities.sort_custom(func(a, b): return int(a) > int(b))
	
	var best_move : PossibleMove
	for priority in sorted_priorities:
		var moves : Array = grouped_moves[priority]
		moves.sort_custom(func(a, b): return a.ranking > b.ranking)
		best_move = moves[0]
		break
		
	#a fallback to prevent no decisions for the cpu
	if best_move == null:
		best_move = all_possible_moves.pick_random()
	
	BoardManager.move_piece_to_valid_coord(best_move.coordinates_of_move, best_move.piece)
	cpu_turn_ended.emit()
	
func _on_cpu_turn_started() -> void:
	#if BoardManager.tweens_active > 0:
	#	BoardManager.board_movement_finished.connect(_start_move_timer.bind(), CONNECT_ONE_SHOT)
	#else:
	_start_move_timer()
		
func _start_move_timer() -> void:
	move_timer.start()

	

 
