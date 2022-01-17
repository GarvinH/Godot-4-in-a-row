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

var is_starting_player : bool
var is_local_turn : bool

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
