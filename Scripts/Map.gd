extends Node
class_name Map

"""
Procedurally generates the world map
"""

signal started
signal finished

onready var game = get_tree().get_root().get_node("Game")

enum CellType {Dirt, Water, Grass, Forest, Rock}

export var inner_size := Vector2(50,50)
export var perimeter_size := Vector2(5,5)
export var iterations := 10

export var land_chance = 0.1
export var rock_chance := 0.001
export var rock_neighbour_chance := 0.02
export var gold_chance := 0.0005
export var gold_neighbour_chance := 0.005
export var iron_chance := 0.0005
export var iron_neighbour_chance := 0.005
export var grass_chance := 0.001
export var grass_neighbour_chance := 0.5

export var river_chance := 0.01
export var river_turn_chance := 0.2
export var river_min_length := 100
export var river_max_length := 150
export var lake_neighbour_chance = 0.5

export var forest_iterations := 3
export var forest_chance := 0.012
export var forest_neighbour_chance := 0.45

enum RiverCell {StartWest, StartSouth, StartNorth, StartEast}
enum RiverDirection {West, East, South, North}
enum RiverMouth {WestToSouth, WestToNorth, WestToEast, SouthToWest, SouthToNorth, SouthToEast, NorthToWest, NorthToSouth, NorthToEast, EastToWest, EastToSouth, EastToNorth}

# Public variables
var world_name = ""
var size := inner_size + 2 * perimeter_size
var cells = []
var rivers = []
var lakes = []


# Private variables
var _rng = RandomNumberGenerator.new()
onready var _landmap = $Land
onready var _watermap = $Water
onready var _grassmap = $Grass
onready var _objectmap = $Objects
onready var _springmap = $Springs
onready var _gridmap = $Grid

func _ready():
	generate('Test555', 'S')
	pass # Replace with function body.
	
func generate(name, selected_size):
	world_name = name
	var world_seed = name + selected_size
	_rng.seed = world_seed.hash()
	if(selected_size=="S"):
		inner_size = Vector2(100,100)
	elif(selected_size=="M"):
		inner_size = Vector2(200,200)
	elif(selected_size=="L"):
		inner_size = Vector2(300,300)
	size = inner_size + 2 * perimeter_size
	for x in size.x:
			cells.append([])
			for y in size.y:
				cells[x].append({})
				cells[x][y]["Unit"] = null
				cells[x][y]["Type"] = "Water"
				cells[x][y]["LandType"] = "Dirt"				
				if(x > 5 && y > 5 && x < size.x - 5 && y < size.y - 5):
					cells[x][y]["Type"] = "Land"
				cells[x][y]["X"] = x
				cells[x][y]["Y"] = y
	for i in iterations:
		for x in size.x:
			for y in size.y:
				if(x < perimeter_size.x || y < perimeter_size.y || x > inner_size.x + perimeter_size.x || y > inner_size.y + perimeter_size.y):
					continue
				var rock_perc = _rng.randf()
				var gold_perc = _rng.randf()
				var iron_perc = _rng.randf()
				if((cells[x][y]["Type"] == "Land") && (rock_perc <= rock_chance || (_has_neighbour(x,y,"Rock") && rock_perc <= rock_neighbour_chance))):
					cells[x][y]["Type"] = "Rock"
				elif((cells[x][y]["Type"] == "Land") && (gold_perc <= gold_chance || (_has_neighbour(x,y,"Gold") && gold_perc <= gold_neighbour_chance))):
					cells[x][y]["Type"] = "Gold"
				elif((cells[x][y]["Type"] == "Land") && (iron_perc <= iron_chance || (_has_neighbour(x,y,"Iron") && iron_perc <= iron_neighbour_chance))):
					cells[x][y]["Type"] = "Iron"
	_generate_rivers()
	place_forests()
	_update_visuals()
	
func place_forests():
	for i in forest_iterations:
		for x in size.x - perimeter_size.x:
			for y in size.y - perimeter_size.y:
				if(cells[x][y]["Type"] == "Land"):
					var chance = _rng.randf()
					if(chance <= forest_chance && i == 0 || (chance <= forest_neighbour_chance && _has_direct_neighbour(x,y,"Forest"))):
						cells[x][y]["Type"] = "Forest"
	for i in forest_iterations:
		for x in size.x - perimeter_size.x:
			for y in size.y - perimeter_size.y:
				if(cells[x][y]["Type"] == "Land"):
					if( _has_direct_neighbour(x,y,"Forest") && _get_specific_direct_neighbours(x,y,"Forest").size() >= 3):
						cells[x][y]["Type"] = "Forest"

func _generate_rivers():
	for x in size.x - perimeter_size.x:
		for y in size.y - perimeter_size.y:
			if(cells[x][y]["Type"] == "Land" && !_has_neighbour(x,y,"Water") && !_has_neighbour(x,y,"River") && (_has_neighbour(x,y,"Rock") || _has_neighbour(x,y,"Gold") || _has_neighbour(x,y,"Iron"))):
				var chance = _rng.randf()
				if(chance <= river_chance):
					var river = _spawn_river(x,y)
					if(river):
						var river_length = _rng.randi_range(river_min_length, river_max_length)
						for i in river_length:
							var last_cell = river["Cells"][river["Cells"].size() - 1]
							var last_cell_x = last_cell["X"]
							var last_cell_y = last_cell["Y"]
							if(_has_direct_neighbour(last_cell_x,last_cell_y,"Water")):
								break
							elif(i < river_length && last_cell["Type"] == "River"):
								if(!_continue_river(river, last_cell_x,last_cell_y)):
									_spawn_lake(last_cell_x, last_cell_y)
									break
							elif(i == river_length - 1 && !_has_neighbour(x,y,"Water")):
								_spawn_lake(last_cell_x,last_cell_y)
								break
							
	return

func _continue_river(river, x,y):
	var turn_chance = _rng.randf()
	if(turn_chance <= river_turn_chance && !_has_neighbour(x,y,"Water") && _get_specific_neighbours(x,y,"River").size() <= 1):
		var new_direction = _rng.randi_range(0,3)
		if(new_direction == 0 && river["Original Direction"] != RiverDirection.East):
			river["Direction"] = new_direction
		elif(new_direction == 1 && river["Original Direction"] != RiverDirection.West):
			river["Direction"] = new_direction
		elif(new_direction == 2 && river["Original Direction"] != RiverDirection.North):
			river["Direction"] = new_direction
		elif(new_direction == 3 && river["Original Direction"] != RiverDirection.South):
			river["Direction"] = new_direction
	if(river["Direction"] == RiverDirection.West && _check_continue_river_spot(x,y,1,0)):
		_populate_continue_river_spot(river,x,y,1,0)
	elif(river["Direction"] == RiverDirection.East && _check_continue_river_spot(x,y,-1,0)):
		_populate_continue_river_spot(river,x,y,-1,0)
	elif(river["Direction"] == RiverDirection.North && _check_continue_river_spot(x,y,0,1)):
		_populate_continue_river_spot(river,x,y,0,1)
	elif(river["Direction"] == RiverDirection.South && _check_continue_river_spot(x,y,0,-1)):
		_populate_continue_river_spot(river,x,y,0,-1)
	else:
		return false
	return true
	
func _check_continue_river_spot(x,y,x_diff,y_diff):
	if(_get_neighbour(x-x_diff,y-y_diff) && _get_specific_neighbours(x-x_diff,y-y_diff,"River").size() <= 2 && _get_specific_neighbours(x-(x_diff*2),y-(y_diff*2),"River").size() <= 1 && cells[x-x_diff][y-y_diff]["Type"] != "River"):
		return true
	return false
		
func _populate_continue_river_spot(river,x,y,x_diff,y_diff):
	cells[x-x_diff][y-y_diff]["Type"] = "River"
	cells[x-x_diff][y-y_diff]["Direction"] = river["Direction"]
	river["Cells"].append(cells[x-x_diff][y-y_diff])

func _spawn_lake(x,y):
	var lake = {}
	lake["Cells"] = []
	var neighbours = _get_neighbours(x,y)
	for cell in neighbours:
		var cell_x = cell["X"]
		var cell_y = cell["Y"]
		if(cell["Type"] != "Water" && !_has_neighbour(cell_x, cell_y,"Water") && _get_specific_neighbours(cell_x, cell_y,"River").size() <= 2):
			cell["Type"] = "Lake"
			lake["Cells"].append(cell)
		_grow_lake(lake, cell_x, cell_y)
	var lake_cells = lake["Cells"]
	for cell in lake_cells:
		_grow_lake(lake, cell["X"], cell["Y"])

func _grow_lake(lake, cell_x, cell_y):
	var lake_grow_chance = _rng.randf()
	if(lake_grow_chance <= lake_neighbour_chance):
		var cell_neighbours = _get_direct_neighbours(cell_x,cell_y)
		for neighbour in cell_neighbours:
			var nx = neighbour["X"]
			var ny = neighbour["Y"]
			var nchance = _rng.randf()
			if(nchance <= lake_neighbour_chance && neighbour["Type"] == "Land" && !_has_neighbour(nx,ny,"River") && !_has_neighbour(nx,ny,"Sea")):
				neighbour["Type"] = "Lake"
				lake["Cells"].append(neighbour)
				
func _spawn_river(x,y):
	if(_check_river_spot(x,y,1,0)):
		return _populate_river_spot(x,y,1,0)
	elif(_check_river_spot(x,y,-1,0)):
		return _populate_river_spot(x,y,-1,0)
	elif(_check_river_spot(x,y,0,1)):
		return _populate_river_spot(x,y,0,1)
	elif(_check_river_spot(x,y,0,-1)):
		return _populate_river_spot(x,y,0,-1)

func _check_river_spot(x,y,x_diff,y_diff):
	if((_get_neighbour(x+x_diff,y+y_diff) && _get_neighbour(x+x_diff,y+y_diff)["Type"] == "Rock" || _get_neighbour(x,y) && _get_neighbour(x,y)["Type"] == "Gold") && _get_neighbour(x-x_diff,y-y_diff) && _get_neighbour(x-x_diff,y-y_diff)["Type"] == "Land" && _get_neighbour(x-(x_diff * 2),y-(y_diff * 2)) && _get_neighbour(x-(x_diff * 2),y-(y_diff * 2))["Type"] == "Land"):
		return true
	return false

func _populate_river_spot(x,y,x_diff,y_diff):
	var river = {}
	if(y_diff == -1):
		river["Direction"] = RiverDirection.South
	elif(y_diff == 1):
		river["Direction"] = RiverDirection.North
	elif(x_diff == -1):
		river["Direction"] = RiverDirection.East
	elif(x_diff == 1):
		river["Direction"] = RiverDirection.West
	river["Original Direction"] = river["Direction"]
	cells[x][y]["Type"] = "Spring"
	cells[x][y]["Original Direction"] = river["Direction"]
	cells[x-x_diff][y-y_diff]["Type"] = "River"
	cells[x-x_diff][y-y_diff]["Direction"] = river["Direction"]
	cells[x-(x_diff * 2)][y-(y_diff * 2)]["Type"] = "River"
	cells[x-(x_diff * 2)][y-(y_diff * 2)]["Direction"] = river["Direction"]
	rivers.append(river)
	river["Cells"] = []
	river["Cells"].append(cells[x][y])
	river["Cells"].append(cells[x-x_diff][y-y_diff])
	river["Cells"].append(cells[x-(x_diff * 2)][y-(y_diff * 2)])
	return river

func _has_neighbour(x,y,type):
	var has_them = _has_direct_neighbour(x,y,type)
	if(y > 1 && y < cells[x].size() - 1 && x > 1 && x < cells.size() - 1 && (cells[x+1][y+1]["Type"] == type || cells[x+1][y-1]["Type"] == type || cells[x-1][y+1]["Type"] == type || cells[x-1][y+1]["Type"] == type)):
		return true
	return has_them
	
func _has_direct_neighbour(x,y,type):
	if(y > 1 && y < cells[x].size() - 1 && x > 1 && x < cells.size() - 1 && (cells[x+1][y]["Type"] == type || cells[x-1][y]["Type"] == type || cells[x][y+1]["Type"] == type || cells[x][y-1]["Type"] == type)):
		return true
	return false
	
func _get_neighbours(x,y):
	var neighbours = _get_direct_neighbours(x,y)
	if(x < cells.size() - 1 && y < cells.size() - 1):
		neighbours.append(cells[x+1][y+1])
	if(x < cells.size() - 1 && y > 1):
		neighbours.append(cells[x+1][y-1])
	if(x > 1 && y < cells.size() - 1):
		neighbours.append(cells[x-1][y+1])
	if(x > 1 && y > 1):
		neighbours.append(cells[x-1][y-1])
	
	return neighbours
	
func _get_direct_neighbours(x,y):
	var neighbours = []
	if(x < cells.size() - 1):
		neighbours.append(cells[x+1][y])
	if(x > 1):
		neighbours.append(cells[x-1][y])
	if(y < cells.size() - 1):
		neighbours.append(cells[x][y+1])
	if(y > 1):
		neighbours.append(cells[x][y-1])
	
	return neighbours

func _get_specific_neighbours(x,y,type):
	var neighbours = _get_specific_direct_neighbours(x,y,type)
	if(x < cells.size() - 1 && y < cells[x].size() - 1 && cells[x+1][y+1]["Type"] == type):
		neighbours.append(cells[x+1][y+1])
	if(x < cells.size() - 1 && y > 1 && cells[x+1][y-1]["Type"] == type):
		neighbours.append(cells[x+1][y-1])
	if(x > 1 && y < cells[x].size() - 1 && cells[x-1][y+1]["Type"] == type):
		neighbours.append(cells[x-1][y+1])
	if(x > 1 && y > 1 && cells[x-1][y-1]["Type"] == type):
		neighbours.append(cells[x-1][y-1])
	
	return neighbours
	
func _get_specific_direct_neighbours(x,y,type):
	var neighbours = []
	if(x < cells.size() - 1 && cells[x+1][y]["Type"] == type):
		neighbours.append(cells[x+1][y])
	if(x > 1 && cells[x-1][y]["Type"] == type):
		neighbours.append(cells[x-1][y])
	if(y < cells[x].size() - 1 && cells[x][y+1]["Type"] == type):
		neighbours.append(cells[x][y+1])
	if(y > 1 && cells[x][y-1]["Type"] == type):
		neighbours.append(cells[x][y-1])
	
	return neighbours
	
func _get_neighbour(x,y):
	if(y > 0 && y < cells[x].size() && x > 0 && x < cells.size()):
		return cells[x][y]
	return false

func _get_top_neighbour(x,y):
	return cells[x][y-1]

func _get_bottom_neighbour(x,y):
	return cells[x][y+1]

func _get_east_neighbour(x,y):
	return cells[x-1][y]

func _get_west_neighbour(x,y):
	return cells[x+1][y]

func _update_visuals():
	for x in size.x:
		for y in size.y:
			var cell = cells[x][y]
			_landmap.set_cell(x,y,0)
			cells[x][y]["Walkable"] = true
			var cell_type = cell["Type"]
			if(cell_type == "Water" || cell_type == "River" || cell_type == "Lake"):
				_watermap.set_cell(x,y,0)
				cells[x][y]["Walkable"] = false
			elif(cell_type == "Forest"):
				_objectmap.set_cell(x,y,0, false, false, false, _get_subtile_coord(0, _objectmap))
				cells[x][y]["Walkable"] = false
			elif(cell_type == "Rock"):
				_objectmap.set_cell(x,y,1, false, false, false, _get_subtile_coord(1, _objectmap))
				cells[x][y]["Walkable"] = false
			elif(cell_type == "Gold"):
				_objectmap.set_cell(x,y,2, false, false, false, _get_subtile_coord(2, _objectmap))
				cells[x][y]["Walkable"] = false
			elif(cell_type == "Iron"):
				_objectmap.set_cell(x,y,3, false, false, false, _get_subtile_coord(3, _objectmap))
				cells[x][y]["Walkable"] = false
			elif(cell_type == "Spring"):
				cells[x][y]["Walkable"] = false
				var direction = cell["Original Direction"]
				if(direction == RiverDirection.South):
					_springmap.set_cell(x,y,RiverCell.StartSouth)
				elif(direction == RiverDirection.North):
					_springmap.set_cell(x,y,RiverCell.StartNorth)
				elif(direction == RiverDirection.West):
					_springmap.set_cell(x,y,RiverCell.StartEast)
				elif(direction == RiverDirection.East):
					_springmap.set_cell(x,y,RiverCell.StartWest)
			var land_type = cell["LandType"]
			if(land_type == "Grass"):
				_grassmap.set_cell(x,y,0)
	_watermap.update_bitmask_region(Vector2(0,0), Vector2(size.x, size.y))
	_grassmap.update_bitmask_region(Vector2(0,0), Vector2(size.x, size.y))
	
func _get_subtile_coord(id, tilemap):
	var tiles = tilemap.tile_set
	var rect = tilemap.tile_set.tile_get_region(id)
	var x = randi() % int(rect.size.x / tiles.autotile_get_size(id).x)
	var y = randi() % int(rect.size.y / tiles.autotile_get_size(id).y)
	return Vector2(x, y)
	
func update_grid():
	for x in size.x:
		for y in size.y:
			if cells[x][y]["Walkable"]:
				_gridmap.set_cell(x,y,0)
			else:
				_gridmap.set_cell(x,y,1)
