extends StateMachine
export onready var map = get_tree().get_root().get_node("Game/Map")

func _ready():
	add_state("idle")
	add_state("moving")
	add_state("engaging")
	add_state("attacking")
	add_state("dead")
	call_deferred("set_state", states.idle)

func _input(event):
	if parent.selected and state != states.dead:
		if Input.is_action_just_released("right_click"):
				var x = int(get_global_mouse_position().x/32)
				var y = int(get_global_mouse_position().y/32)
				var cells = map.cells
				if(x > 0 && y > 0 && cells.size() > x && cells[x].size() > y):
					parent.movement_target = cells[x][y]
					set_state(states.moving)

func _state_logic(delta):
	match state:
		states.idle:
			pass
		states.moving:
			parent.move_to_target(delta, parent.movement_target)
		states.engaging:
			parent.move_to_target(delta, parent.attack_target.position)
		states.attacking:
			pass
		states.dead:
			pass

func _enter_state(new_state, old_state):
	match state:
		states.idle:
			parent.sprite.frames = parent.idle_anim
		states.moving:
			parent.current_cell["Walkable"] = true
			if parent.global_position.x < parent.movement_target["X"] * 32:
				parent.sprite.flip_h = false
			elif parent.global_position.x > parent.movement_target["X"] * 32:
				parent.sprite.flip_h = true
		states.engaging:
			if parent.global_position.x < parent.movement_target["X"] * 32:
				parent.sprite.flip_h = false
			elif parent.global_position.x > parent.movement_target["X"] * 32:
				parent.sprite.flip_h = true
		states.attacking:
			print("Attacking")
			parent.sprite.frames = parent.attack_anim
		states.dead:
			parent.sprite.frames = parent.dead_anim
			
func _get_transition(delta):
	match state:
		states.idle:
			if parent.closest_possible_target() != null:
				parent.attack_target = parent.closest_possible_target()
				set_state(states.engaging)
		states.moving:
			parent.get_current_cell()
			if parent.current_cell == parent.movement_target:
				parent.current_cell["Walkable"] = false
				parent.movement_target = parent.position
				set_state(states.idle)
		states.engaging:
			if parent.closest_possible_target_within_range() != null:
				parent.attack_target = parent.closest_possible_target()
				set_state(states.attacking)
		states.attacking:
			pass
		states.dead:
			pass

func _on_StopTimer_timeout():
	if parent.get_slide_count():
		if parent.last_position.distance_to(parent.movement_target) < parent.position.distance_to(parent.movement_target) + parent.move_threshold:
			parent.movement_target = parent.position
			set_state(states.idle)
			print('Set Idle')
