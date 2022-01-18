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

var winner : int = GridVal.EMPTY

# cols then rows
var grid : = [[]];

func _init(starting_player : bool):
	is_starting_player = starting_player
	is_local_turn = starting_player

func _ready():
	grid = init_grid();
	
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
			if (is_local_turn):
				var preview_chip_origin = _get_chip_origin(i, num_rows)
				var mouse_pos_x = get_viewport().get_mouse_position().x
				if (mouse_pos_x > preview_chip_origin.x - chip_radius and mouse_pos_x < preview_chip_origin.x + chip_radius):
					draw_circle(preview_chip_origin, chip_radius, Color.green)
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
					winner = chip_color
				
				return true
	return false
	
# Play on the board, then try to update other players
remote func _play(col: int, chip_color : int) -> bool:
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
		if (starting_col + i >= num_rows): # out of bounds
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
