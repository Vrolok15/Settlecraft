extends KinematicBody2D
class_name Unit
export var tile = {}
export var type = ""
export var unit_name = ""

#owner
export var unit_owner := 1

#movement
onready var map = get_tree().get_root().get_node("Game/Map")
var selected = false
var current_cell = {}

func place_at(x,y):
	current_cell["Unit"] = null
	current_cell = map.cells[x][y]
	map.cells[x][y]["Unit"] = self
	self.position = Vector2(current_cell["X"] * 32, current_cell["Y"] * 32)

func get_current_cell():
	var x = int(global_position.x/32)
	var y = int(global_position.y/32)
	var cells = map.cells
	current_cell = cells[x][y]
	current_cell["Walkable"] = false
	return current_cell

var movement_target = Vector2.ZERO
var previous_target = Vector2.ZERO
var velocity = Vector2.ZERO
var speed = 80
var target_max_dist = 1

var slide_count = 0
const move_threshold = 0.5
var last_position = Vector2.ZERO

#children
onready var stop_timer = $StopTimer
onready var sprite = $AnimatedSprite

#attacking
export var attack_range = 25
export var hp = 20
export var damage = 3
var possible_targets = []
var attack_target

#animations
export(SpriteFrames) var idle_anim = load("res://Anim/Units/Swordsman/SwordsmanIdle.tres")
export(SpriteFrames) var dead_anim = load("res://Anim/Units/Swordsman/SwordsmanDead.tres")
export(SpriteFrames) var attack_anim = load("res://Anim/Units/Swordsman/SwordsmanAttack.tres")

func _ready():
	pass
	
func move_to_target(delta, target_cell):
	velocity = Vector2.ZERO
	var cell_x = target_cell["X"]
	var cell_y = target_cell["Y"]
	var tar = Vector2(cell_x*32, cell_y*32)
	velocity = position.direction_to(tar) * speed
	if get_slide_count() and stop_timer.is_stopped():
		stop_timer.start()
		last_position = position
	velocity = move_and_slide(velocity)
	
func _draw():
	if selected:
		var end = Vector2(0, 0)
		var start = Vector2(32, 32)
		draw_rect(Rect2(end, start), Color(0, 183, 0), false)
	
func select():
	selected = true
	update()
	
func deselect():
	selected = false
	update()

func _on_VisionRange_body_entered(body):
	if body.is_in_group("units"):
		if body.unit_owner != unit_owner:
			possible_targets.append(body)
			print("Added units")

func _on_VisionRange_body_exited(body):
	if possible_targets.has(body):
		possible_targets.erase(body)
		
func _compare_distance(target_a, target_b):
	return position.distance_to(target_a.position) < position.distance_to(target_b.position)
	
func closest_possible_target() -> Unit:
	if possible_targets.size() > 0:
		possible_targets.sort_custom(self, "_compare_distance")
		return possible_targets[0]
	else:
		return null
		
func closest_possible_target_within_range() -> Unit:
	if(closest_possible_target().position.distance_to(position) < attack_range):
		return closest_possible_target()
	else:
		return null
