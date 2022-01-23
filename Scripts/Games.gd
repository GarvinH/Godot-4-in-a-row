extends Node

var winner : int = Game.GridVal.EMPTY

signal set_show_ready_toggle_button

func player_ready_toggle():
	var local_player : Game = get_node(str(get_tree().get_network_unique_id()))
	local_player.toggle_player_ready()

func emit_show_ready_toggle_signal(show_value: bool) -> void:
	emit_signal("set_show_ready_toggle_button", show_value)

func try_replay():
	if (_both_players_ready()):
		var local_player : Game = get_node(str(get_tree().get_network_unique_id()))
		local_player.reset_game()
		
func try_play():
	if (get_tree().is_network_server() and _both_ready()):
		var local_player : Game = get_node(str(get_tree().get_network_unique_id()))
		local_player.start()
	
func _both_players_ready() -> bool:
	for child in get_children():
		if (child is Game and !child.player_ready):
			return false
	return true

func _both_ready() -> bool:
	for child in get_children():
		if (child is Game and !child.ready):
			return false
	return true

func reset_all_players():
	for child in get_children():
		if (child is Game):
			child.reset_board_and_swap_start()
