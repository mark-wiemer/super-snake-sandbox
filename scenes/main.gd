extends Node2D

# game variables
var score: int

# grid variables
var cells: int = 20
var cell_size: int = 50

# food variables
var food_pos: Vector2

# snake_segments variables
var snake_data: Array[Vector2]
var snake_segments: Array[ColorRect]

# movement variables
var start_pos = Vector2(9, 9)
var up = Vector2(0, -1)
var down = Vector2(0, 1)
var left = Vector2(-1, 0)
var right = Vector2(1, 0)
var direction_queue: Array[Vector2] = [up]

# region Built-in functions
#* Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()

#* Called every frame
func _process(_delta) -> void:
	read_input()
	
func _input(_event) -> void:
	if Input.is_action_pressed("quit"):
		get_tree().quit()
		
func _draw() -> void:
	const color = Color(0.125093, 0.591511, 0, 1)
	for segment in snake_data:
		draw_rect(
			Rect2(
				((segment * cell_size) + Vector2(0, cell_size)),
				Vector2(cell_size, cell_size)),
			color
		)
	pass
# endregion

# region "New game" functions
func new_game() -> void:
	get_tree().paused = false
	get_tree().call_group("segments", "queue_free") # remove old segments
	$GameOverMenu.hide()
	score = 0
	$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	direction_queue = [up]
	generate_snake()
	food_pos = SnakeModel.move_food(snake_data, cells)
	$Food.position = (food_pos * cell_size) + Vector2(0, cell_size)
	start_game()

func generate_snake() -> void:
	snake_data = SnakeModel.generate_snake(start_pos, -direction_queue[0], 3)

func start_game() -> void:
	$TickTimer.start()
# endregion
	
func read_input() -> void:
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

func _on_tick() -> void:
	var new_state = SnakeModel.tick(SnakeModel.State.new(
		cells,
		direction_queue,
		food_pos,
		false,
		score,
		snake_data,
	))
	if new_state.game_over:
		end_game()
		return
	# Else update the visuals!	
	direction_queue = new_state.direction_queue
	if (new_state.food_pos != food_pos):
		food_pos = new_state.food_pos
		$Food.position = (food_pos * cell_size) + Vector2(0, cell_size)
	if (new_state.score != score):
		score = new_state.score
		$Hud.get_node("ScoreLabel").text = "Score: " + str(score)
	# currently only supports updating the snake length at most 1 each tick
	snake_data = new_state.snake
	queue_redraw()

func end_game() -> void:
	$GameOverMenu.show()
	$TickTimer.stop()
	get_tree().paused = true

func _on_game_over_menu_restart() -> void:
	new_game()
