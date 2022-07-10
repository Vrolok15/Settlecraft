extends Node2D

var dragging = false
var selected = []
var drag_start = Vector2.ZERO
var select_rectangle = RectangleShape2D.new()

onready var select_draw = $Map/YSort/SelectDraw
onready var map = $Map

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.pressed:
			for unit in selected:
				unit.collider.deselect()
			selected = []
			dragging = true
			drag_start = event.position
		elif dragging:
			dragging = false
			var drag_end = event.position
			select_draw.update_status(drag_start, drag_end, dragging)
			select_rectangle.extents = (drag_end - drag_start) / 2
			var space = get_world_2d().direct_space_state
			var query = Physics2DShapeQueryParameters.new()
			query.set_shape(select_rectangle)
			query.transform = Transform2D(0, (drag_end + drag_start) / 2)
			selected = space.intersect_shape(query)
			for unit in selected:
				if unit.collider.unit_owner == 1:
					pass
					unit.collider.select()
	if dragging:
		if event is InputEventMouseMotion:
			select_draw.update_status(drag_start, event.position, dragging)
