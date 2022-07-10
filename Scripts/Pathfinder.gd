extends Node2D
export onready var world = get_tree().get_root().get_node("Game/Map")
var astar = AStar2D.new()

func initiate():
	var walkable_points = get_walkable_points()
	astar_connect_walkable_cells(walkable_points)

func find_path(start, end):
	var start_point_index = calculate_point_index(start)
	var end_point_index = calculate_point_index(end)
	var point_path = astar.get_point_path(start_point_index, end_point_index)
	return point_path 
	
func get_walkable_points():
	var points = []
	for x in world.size.x:
		for y in world.size.y:
			var cell = world.cells[x][y]
			var cell_walkable = cell["Walkable"]
			if(cell_walkable != true):
				continue;
			var point = Vector2(x,y);
			var point_index = calculate_point_index(point)
			points.append(point)
			astar.add_point(point_index,point)
	
	return points
					
func astar_connect_walkable_cells(points_array):
	for point in points_array:
		var point_index = calculate_point_index(point)
		# For every cell in the map, we check the one to the top, right.
		# left and bottom of it. If it's in the map and not an obstalce,
		# We connect the current point with it
		var points_relative = PoolVector2Array([
			Vector2(point.x + 1, point.y),
			Vector2(point.x + 1, point.y + 1),
			Vector2(point.x + 1, point.y - 1),
			Vector2(point.x - 1, point.y),
			Vector2(point.x - 1, point.y + 1),
			Vector2(point.x - 1, point.y - 1),
			Vector2(point.x, point.y + 1),
			Vector2(point.x, point.y - 1)])
		for point_relative in points_relative:
			var point_relative_index = calculate_point_index(point_relative)

			if is_outside_map_bounds(point_relative):
				continue
			if not astar.has_point(point_relative_index):
				continue
			# Note the 3rd argument. It tells the astar_node that we want the
			# connection to be bilateral: from point A to B and B to A
			# If you set this value to false, it becomes a one-way path
			# As we loop through all points we can set it to false
			astar.connect_points(point_index, point_relative_index, false)

func calculate_point_index(point):
	return point.x + world.size.x * point.y
	
func is_outside_map_bounds(point):
	return point.x < 0 or point.y < 0 or point.x >= world.size.x or point.y >= world.size.y
