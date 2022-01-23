extends Control

class_name Game

enum GridVal {EMPTY, YELLOW, RED};

const num_rows = 6;
const num_cols = 7;
const x_start = 200;
const y_start = 200;
const chip_radius = 45;
const grid_chip_gap = 10
const width = 100*num_cols;
const height = 100*num_rows;
const x_end = x_start+width;
const y_end = y_start+height;

var is_starting_player : bool # starting player is yellow
var is_local_turn : bool

puppet var ready : bool = false setget puppet_ready_set # game is loaded
puppet var player_ready : bool = false setget puppet_player_ready_set# player is ready, used for replaying matches

var font : DynamicFont
var player_ready_font : DynamicFont #same font but smaller

# cols then rows
var grid : = [[]];

func _init(starting_player : bool, id : int):
	is_starting_player = starting_player
	is_local_turn = starting_player
	
	self.name = str(id)
	self.set_network_master(id)
	
func create_font(font_size : int) -> DynamicFont:
	var _font = DynamicFont.new()
	_font.font_data = load("res://Assets/Fonts/Noto_Sans/NotoSans-Regular.ttf")
	_font.size = font_size
	
	return _font

func _ready():
	grid = init_grid();
	
	font = create_font(64)
	player_ready_font = create_font(32)
	
	get_tree().set_pause(true)
	
	if (self.is_network_master()):
		ready = true
		
		# if the client's don't receive this, it doesn't matter
		# the server only really cares about receiving this
		# as it means we can send data without losing it
		rpc("puppet_ready_set", true)
		
puppet func puppet_ready_set(ready_value : bool):
	ready = ready_value
	
	Games.try_play()
		
puppet func puppet_player_ready_set(ready_value : bool):
	player_ready = ready_value
	
	Games.try_replay()
	
func start():
	start_game()
	rpc("start_game")
	
remote func start_game():
	get_tree().set_pause(false)
	
func _process(delta):
	update()

func init_grid() -> Array:
	var new_grid = [];
	for i in range(num_cols):
		var new_col = [];
		for j in range(num_rows):
			new_col.append(GridVal.EMPTY);
		new_grid.append(new_col)
		
	return new_grid;

func _draw():
	if self.is_network_master():
		draw_rect(Rect2(x_start, y_start - grid_chip_gap, width + grid_chip_gap, height + grid_chip_gap), Color.blue)
		for i in range(num_cols):
			if (is_local_turn and !someone_won()):
				var preview_chip_origin = _get_chip_origin(i, num_rows)
				var mouse_pos_x = get_viewport().get_mouse_position().x
				if (mouse_pos_x > preview_chip_origin.x - chip_radius and mouse_pos_x < preview_chip_origin.x + chip_radius):
					var preview_chip_color : Color = Color.yellow if is_starting_player else Color.red
					preview_chip_color.a = 0.5
					draw_circle(preview_chip_origin, chip_radius, preview_chip_color)
					if (Input.is_action_just_pressed("mouse_left")):
						var chip_color = GridVal.YELLOW if is_starting_player else GridVal.RED
						if (_play(i, chip_color)):
							rpc("_play", i, chip_color)
			
			for j in range(num_rows):
				var chip_color : Color;
				match grid[i][j]:
					GridVal.EMPTY:
						chip_color = Color.white;
					GridVal.YELLOW:
						chip_color = Color.yellow;
					GridVal.RED:
						chip_color = Color.red;
				
				draw_circle(_get_chip_origin(i,j), chip_radius, chip_color)
			
		if (someone_won()):
			var win_lose_text : String
			if (is_starting_player and Games.winner == GridVal.YELLOW or !is_starting_player and Games.winner == GridVal.RED):
				win_lose_text = "You win!"
			else:
				win_lose_text = "You lost."
			draw_string(font, Vector2(1000, 400), win_lose_text)
		else:
			if (get_tree().is_paused()):
				draw_string(font, Vector2(1000, 200), "Waiting for other")
				draw_string(font, Vector2(1000, 300), "player to load...")
			else:
				var player_turn_text : String = "Your turn." if is_local_turn else "Waiting for other player..."
				draw_string(font, Vector2(1000, 200), player_turn_text)
				
	if (someone_won()):
		draw_string(font, Vector2(1000, 625), "Play Again")
		
		var player_ready_text = "Ready" if player_ready else "Not Ready"
		if (self.is_network_master()):
			draw_string(player_ready_font, Vector2(1000, 700), "You: " + player_ready_text)
		else:
			draw_string(player_ready_font, Vector2(1000, 750), "Them: " + player_ready_text)

func _get_chip_origin(col : int, row : int) -> Vector2:
	return Vector2(x_start + grid_chip_gap + chip_radius*(col+1) + (chip_radius+grid_chip_gap)*col, y_end - grid_chip_gap - chip_radius * (row+1) - (chip_radius+grid_chip_gap)*row)

# Play on the board
func play(col : int, chip_color : int) -> bool:
	if (col >= 0 and col < num_cols):	
		for i in range(num_rows):
			if (grid[col][i] == GridVal.EMPTY):
				grid[col][i] = chip_color
				is_local_turn = !is_local_turn
				
				if (_check_win(col, i)):
					Games.winner = chip_color
					
					
					# Tried to add a button to the Game Node,
					# but it seems like using class_name and having children
					# does not actually instantiate the children.
					# So this is the workaround.
					# Probably raise an issue on the Godot github page...
					Games.emit_show_ready_toggle_signal(true)
				
				return true
	return false
	
# Play on the board, then try to update other players
puppet func _play(col: int, chip_color : int) -> bool:
	var rtn = play(col, chip_color)
	if (rtn):
		for child in Games.get_children():
			if (child.get_name() != self.get_name()):
				child.play(col, chip_color)
	return rtn

func _check_win(col : int, row : int) -> bool:
	return _check_win_horizontal(col, row) or _check_win_vertical(col, row) or _check_win_diagonals(col, row)
	
func _check_win_horizontal(col: int, row: int) -> bool:
	var starting_col : int = col
	
	# go as far left as possible
	while (starting_col > 0 and grid[starting_col-1][row] == grid[col][row]):
		starting_col -= 1
		
	# count rightwards and make sure the next 4 are the same color
	for i in range(4):
		if (starting_col + i >= num_cols): # out of bounds
			return false
		if (grid[starting_col+i][row] != grid[col][row]):
			return false
	return true
	
func _check_win_vertical(col : int, row : int) -> bool:
	# must be at least at 4th row in order to have a vertical win (or the 3rd index in this case)
	if row > 2:
		for i in range(4):
			if (row - i < 0): # out of bounds
				return false
				
			# count downwards since a win can only happen from the top down
			if (grid[col][row-i] != grid[col][row]):
				return false
		return true
		
	return false

func _check_win_diagonals(col : int, row : int) -> bool:
	var win_diagonal_1 : = true #bottom left to top right
	var win_diagonal_2 : = true #top left to bottom right
	
	var starting_col : int = col
	var starting_row : int = row
	
	# checking bottom left to top right -----------------
	while (starting_col > 0 and starting_row > 0 and grid[starting_col-1][starting_row-1] == grid[col][row]):
		starting_col -= 1
		starting_row -= 1
		
	for i in range(4):
		if (starting_col + i >= num_cols or starting_row + i >= num_rows): # out of bounds
			win_diagonal_1 = false
		elif (grid[starting_col + i][starting_row + i] != grid[col][row]):
			win_diagonal_1 = false
			
	# checking top left to bottom right -----------------
	starting_col = col
	starting_row = row
	
	while (starting_col > 0 and starting_row + 1 < num_rows and grid[starting_col-1][starting_row+1] == grid[col][row]):
		starting_col -= 1
		starting_row += 1
		
	for i in range(4):
		if (starting_col + i >= num_cols or starting_row - i < 0):
			win_diagonal_2 = false
		elif (grid[starting_col + i][starting_row - i] != grid[col][row]):
			win_diagonal_2 = false
	
	return win_diagonal_1 or win_diagonal_2

func someone_won() -> bool:
	return Games.winner != GridVal.EMPTY

puppet func reset_game() -> void:
	ready = false
	rpc("puppet_ready_set", false)
	
	Games.reset_all_players()
	get_tree().set_pause(true)
	
	ready = true
	rpc("puppet_ready_set", true)
	player_ready = false
	rpc("puppet_player_ready_set", false)
	
	Games.try_play()
	
func reset_board_and_swap_start():
	grid = init_grid()
	is_starting_player = !is_starting_player
	is_local_turn = is_starting_player
	Games.winner = GridVal.EMPTY

func toggle_player_ready() -> void:
	player_ready = !player_ready
	rpc("puppet_player_ready_set", player_ready)
	
	Games.try_replay()
