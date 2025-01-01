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
var old_data: Array
var snake_data: Array
var snake: Array

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
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	direction_queue = [up]
	generate_snake()
	move_food()
	start_game()
	
func generate_snake():
	old_data.clear()
	snake_data.clear()
	snake.clear()
	for i in range(3):
		add_segment(start_pos + Vector2(0, i))
		
func add_segment(pos):
	snake_data.append(pos)
	var SnakeSegment = snake_scene.instantiate()
	SnakeSegment.position = (pos * cell_size) + Vector2(0, cell_size)
	add_child(SnakeSegment)
	snake.append(SnakeSegment)

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

	# use the snake's previous position to move the segments
	old_data = [] + snake_data
	snake_data[0] += move_direction
	check_out_of_bounds()
	check_self_eaten()
	if (game_over):
		return
	move()
	check_food_eaten()
	
# move all the segments along by one
func move():
	for i in range(len(snake_data)):
		if i > 0:
			snake_data[i] = old_data[i - 1]
		snake[i].position = (snake_data[i] * cell_size) + Vector2(0, cell_size)

func check_out_of_bounds():
	if snake_data[0].x < 0 or snake_data[0].x > cells - 1 or snake_data[0].y < 0 or snake_data[0].y > cells - 1:
		end_game()
		
func check_self_eaten():
	for i in range(1, len(snake_data)):
		if snake_data[0] == snake_data[i]:
			end_game()
			
func check_food_eaten():
	# if snake eats the food, add a segment and move the food
	if snake_data[0] == food_pos:
		score += 1
		$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
		add_segment(old_data[-1])
		move_food()
	
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
	$MoveTimer.stop()
	get_tree().paused = true

func _on_game_over_menu_restart():
	new_game()
