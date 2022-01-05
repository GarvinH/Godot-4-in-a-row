extends Control

enum GridVal {EMPTY, YELLOW, RED};

const num_rows = 6;
const num_cols = 7;
const x_start = 200;
const y_start = 200;
const chip_radius = 45;
const grid_chip_gap = 10

# cols then rows
var grid : = [[]];

func _ready():
	grid = init_grid();

func init_grid() -> Array:
	var new_grid = [];
	for i in range(num_cols):
		var new_col = [];
		for j in range(num_rows):
			new_col.append(GridVal.EMPTY);
		new_grid.append(new_col)
		
	return new_grid;

func _draw():
	var width = 100*num_cols;
	var height = 100*num_rows;
	var x_end = x_start+width;
	var y_end = y_start+height;
	draw_rect(Rect2(x_start, y_start - grid_chip_gap, width + grid_chip_gap, height + grid_chip_gap), Color.blue)
	for i in range(num_cols):
		for j in range(num_rows):
			draw_circle(Vector2(x_start + grid_chip_gap + chip_radius*(i+1) + (chip_radius+grid_chip_gap)*i, y_end - grid_chip_gap - chip_radius * (j+1) - (chip_radius+grid_chip_gap)*j), chip_radius, Color.white)
