extends Camera2D

export var speed := 20.0
export var zoom_speed := 20.0
export var zoom_margin := 0.1

export var zoom_min = 0.5
export var zoom_max = 1.5

var zooming = false
var zoom_pos = Vector2()
var zoom_factor = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var inp_x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	position.x = lerp(position.x, position.x + inp_x * speed * zoom.x, speed * delta)
	var inp_y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	position.y = lerp(position.y, position.y + inp_y * speed * zoom.y, speed * delta)
	
	zoom.x = lerp(zoom.x, zoom.x * zoom_factor, zoom_speed * delta)
	zoom.y = lerp(zoom.y, zoom.y * zoom_factor, zoom_speed * delta)
	
	zoom.x = clamp(zoom.x, zoom_min, zoom_max)
	zoom.y = clamp(zoom.y, zoom_min, zoom_max)
	
	if not zooming:
		zoom_factor = 1.0
	
	pass

func _input(event):
	if abs(zoom_pos.x - get_global_mouse_position().x) > zoom_margin:
		zoom_factor = 1.0
	if abs(zoom_pos.y - get_global_mouse_position().y) > zoom_margin:
		zoom_factor = 1.0
		
	if(event is InputEventMouseButton):
		if(event.is_pressed()):
			zooming = true
			if event.button_index == BUTTON_WHEEL_UP:
				zoom_factor -= 0.01 * zoom_speed
				zoom_pos = get_global_mouse_position()
			elif event.button_index == BUTTON_WHEEL_DOWN:
				zoom_factor += 0.01 * zoom_speed
				zoom_pos = get_global_mouse_position()
		else:
			zooming = false
