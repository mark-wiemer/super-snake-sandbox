extends Node

@export var snake_segment_scene: PackedScene
# To avoid visual jitter, pre-render the "new tail"
var backup_segment: ColorRect

# game variables
var score: int
var game_over = false

# grid variables
var cells: int = 20
var cell_size: int = 50

# food variables
var food_pos: Vector2
var regen_food: bool = true

# snake_segments variables
var snake_data: Array
var snake_segments: Array

# movement variables
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var direction_queue = [up]

# region Built-in functions
#* Called when the node enters the scene tree for the first time.
func _ready():
	new_game()

#* Called every frame
func _process(_delta):
	read_input()
	
func _input(_event):
	if Input.is_action_pressed("quit"):
		get_tree().quit()
# endregion

# region "New game" functions
func new_game():
	game_over = false
	get_tree().paused = false
	get_tree().call_group("segments", "queue_free") # remove old segments
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	direction_queue = [up]
	generate_snake()
	move_food()
	start_game()

# Make backup_segment point to a new instance.
# Does not free the old backup_segment!
func reset_backup_segment():
	backup_segment = snake_segment_scene.instantiate()
	backup_segment.hide()
	add_child(backup_segment)

func generate_snake():
	snake_data.clear()
	snake_segments.clear()
	reset_backup_segment()
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))
		
func add_segment(pos):
	snake_data.append(pos)
	backup_segment.show()
	var SnakeSegment = backup_segment
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	snake_segments.append(SnakeSegment)
	reset_backup_segment()

func start_game():
	$TickTimer.start()
# endregion
	
func read_input():
	# update movement from keypresses
	var move_direction = direction_queue.back()
	if Input.is_action_just_pressed("move_down") and move_direction != up and move_direction != down:
		direction_queue.push_back(down)
	if Input.is_action_just_pressed("move_up") and move_direction != down and move_direction != up:
		direction_queue.push_back(up)
	if Input.is_action_just_pressed("move_left") and move_direction != right and move_direction != left:
		direction_queue.push_back(left)
	if Input.is_action_just_pressed("move_right") and move_direction != left and move_direction != right:
		direction_queue.push_back(right)

func _on_tick():
	# Remove the previous direction and jump straight to the next one
	if (direction_queue.size() > 1):
		direction_queue.pop_front()
	var move_direction = direction_queue.front()

	# use the snake_segments's previous position to move the segments
	var old_tail_pos = snake_data[-1]
	var new_head_pos = snake_data[0] + move_direction
	if check_game_over(new_head_pos):
		end_game()
		return
	move(new_head_pos)
	if (should_eat(new_head_pos)):
		eat_food(old_tail_pos)
		move_food()
	
func check_game_over(new_head_pos):
	if new_head_pos in snake_data:
		return true
	if new_head_pos.x < 0 \
			or new_head_pos.x >= cells \
			or new_head_pos.y < 0 \
			or new_head_pos.y >= cells:
		return true
	return false

# move all the segments along by one
func move(new_head_pos):
	snake_data.push_front(new_head_pos)
	snake_data.pop_back()
	for i in range(len(snake_data)):
		snake_segments[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)
			
func should_eat(new_head_pos):
	return new_head_pos == food_pos

func eat_food(old_tail_pos):
	add_segment(old_tail_pos)
	score += 1
	$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	
func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake_data:
			if food_pos == i:
				regen_food = true
	$Food.position = (food_pos * cell_size) + Vector2(0, cell_size)
	regen_food = true

func end_game():
	game_over = true
	$GameOverMenu.show()
	$TickTimer.stop()
	get_tree().paused = true

func _on_game_over_menu_restart():
	new_game()
