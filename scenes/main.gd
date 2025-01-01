extends Node

@export var snake_scene: PackedScene

# game variables
var score: int
var game_over = false

# grid variables
var cells: int = 20
var cell_size: int = 50

# food variables
var food_pos: Vector2
var regen_food: bool = true

# snake variables
var snake: Array[Vector2]
var snake_segments: Array[Node]

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
# endregion

# region "New game" functions
func new_game():
	game_over = false
	get_tree().paused = false
	get_tree().call_group("segments", "queue_free") # remove old segments
	snake_segments.clear() # clear the array of freed segments
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	direction_queue = [up]
	generate_snake()
	move_food()
	start_game()
	
func generate_snake():
	snake.clear()
	var initial_length = 3
	for i in range(initial_length):
		add_segment(start_pos + Vector2(0, initial_length - i))
		
func add_segment(pos):
	snake.push_front(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake_segments.push_front(SnakeSegment)

func remove_tail():
	snake.pop_back()
	snake_segments.pop_back().free()

func start_game():
	$MoveTimer.start()
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

func _on_move_timer_timeout():
	# Remove the previous direction and jump straight to the next one
	if (direction_queue.size() > 1):
		direction_queue.pop_front()
	var move_direction = direction_queue.front()

	# check and end game if needed
	var new_head_pos = snake[0] + move_direction
	var should_end_game = check_game_over(new_head_pos)
	if should_end_game:
		end_game()
		return

	# Game not over, let's move the snake
	move(new_head_pos)
	
func check_game_over(new_head_pos):
	# check if the snake has hit itself
	for i in snake:
		if new_head_pos == i:
			return true
	# check if snake went off-screen
	if new_head_pos.x < 0 or new_head_pos.x > cells - 1 or new_head_pos.y < 0 or new_head_pos.y > cells - 1:
		return true
	return false

# move all the segments along by one
func move(new_head_pos):
	# move the head
	add_segment(new_head_pos)

	# conditionally remove the tail
	if (on_food()):
		eat_food()
		move_food()
	else:
		remove_tail()

func on_food():
	return snake[0] == food_pos

# Add one to score
func eat_food():
	score += 1
	$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	
func move_food():
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake:
			if food_pos == i:
				regen_food = true
	$Food.position = (food_pos * cell_size) + Vector2(0, cell_size)
	regen_food = true

func end_game():
	game_over = true
	$GameOverMenu.show()
	$MoveTimer.stop()
	get_tree().paused = true

func _on_game_over_menu_restart():
	new_game()
