extends Node2D

var state: SnakeModel.State

# grid variables
## size in pixels of each rendered cell
const cell_size: int = 50

# movement variables
const up = Vector2(0, -1)
const down = Vector2(0, 1)
const left = Vector2(-1, 0)
const right = Vector2(1, 0)

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
	# earlier calls for background, later calls for foreground
	# colors from https://en.wikipedia.org/wiki/X11_color_names#Color_name_chart
	for box in state.boxes:
		drawCell(box, Color("chocolate"))
	for segment in state.snake:
		drawCell(segment, Color("cadet blue"))
# endregion

func drawCell(pos, color):
	draw_rect(
			Rect2(
				((pos * cell_size) + Vector2(0, cell_size)),
				Vector2(cell_size, cell_size)),
			color
		)

func new_game() -> void:
	get_tree().call_group("segments", "queue_free") # remove old segments
	const cells: int = 20
	var direction_queue: Array[Vector2] = [up]
	const start_pos = Vector2(9, 9)
	var snake: Array[Vector2] = SnakeModel.generate_snake(start_pos, -direction_queue[0], 3)
	state = SnakeModel.State.new(
		15,
		15,
		[],
		cells,
		direction_queue,
		SnakeModel.move_food(snake, cells),
		false,
		0,
		snake,
	)
	direction_queue = [up]
	
	$Hud.get_node("ScoreLabel").text = "Score: " + str(state.score)
	$Food.position = (state.food_pos * cell_size) + Vector2(0, cell_size)
	# start the game
	get_tree().paused = false
	$GameOverMenu.hide()
	$TickTimer.start()
	
func read_input() -> void:
	# update movement from keypresses
	var move_direction = state.direction_queue.back()
	if Input.is_action_just_pressed("move_down") and move_direction != up and move_direction != down:
		state.direction_queue.push_back(down)
	if Input.is_action_just_pressed("move_up") and move_direction != down and move_direction != up:
		state.direction_queue.push_back(up)
	if Input.is_action_just_pressed("move_left") and move_direction != right and move_direction != left:
		state.direction_queue.push_back(left)
	if Input.is_action_just_pressed("move_right") and move_direction != left and move_direction != right:
		state.direction_queue.push_back(right)

func _on_tick() -> void:
	var new_state = SnakeModel.tick(state)
	if new_state.game_over:
		end_game()
		return
	# Else update the visuals!
	if (new_state.food_pos != state.food_pos):
		state.food_pos = new_state.food_pos
		$Food.position = (state.food_pos * cell_size) + Vector2(0, cell_size)
	if (new_state.score != state.score):
		state.score = new_state.score
		$Hud.get_node("ScoreLabel").text = "Score: " + str(state.score)
	state = new_state
	queue_redraw()

func end_game() -> void:
	$GameOverMenu.show()
	$TickTimer.stop()
	get_tree().paused = true

func _on_game_over_menu_restart() -> void:
	new_game()
