class_name SnakeModel extends Node

class State:
	## Fixed delay in ticks between adding another box
	var box_delay: int
	## Remaining delay in ticks before adding another box
	## If zero, a box will be added this tick
	var box_time: int
	var boxes: Array[Vector2]
	var cells: int
	var direction_queue: Array[Vector2]
	var food_pos: Vector2
	var game_over: bool
	var score: int
	var snake: Array[Vector2]

	func _init(
		box_delay: int,
		box_time: int,
		boxes: Array[Vector2],
		cells: int,
		direction_queue: Array[Vector2],
		food_pos: Vector2,
		game_over: bool,
		score: int,
		snake: Array[Vector2],
	):
		self.box_delay = box_delay
		self.box_time = box_time
		self.boxes = boxes
		self.cells = cells
		self.direction_queue = direction_queue
		self.food_pos = food_pos
		self.game_over = game_over
		self.score = score
		self.snake = snake
	func duplicate() -> State:
		return State.new(
			box_delay,
			box_time,
			boxes.duplicate(),
			cells,
			direction_queue.duplicate(),
			food_pos,
			game_over,
			score,
			snake.duplicate(),
		)
		
## Generates a snake. Pure func
## start: start cell
## dir: normalized direction
## length: size of snake to generate
## returns Vector2[] of positions with head at `start`
static func generate_snake(start: Vector2, dir: Vector2, length: int) -> Array[Vector2]:
	var snake: Array[Vector2] = [];
	for i in range(length):
		snake.push_back(start + dir)
	return snake

## Moves the snake and returns the new state. Pure function.
## The snake moves one cell forward according to the direction_queue.
## If the snake hits a wall or bumps into itself, game_over is true.
## If the snake's head moves onto food:
## - Snake length increases by 1
## - Score increases by 1
## - Food is regenerated at a new position
static func tick(state: State) -> State:
	if (state.snake.size() == 0):
		return state
	var new_state = state.duplicate()
	# Remove the previous direction and jump straight to the next one
	if (new_state.direction_queue.size() > 1):
		new_state.direction_queue.pop_front()
	var move_direction: Vector2 = new_state.direction_queue.front()
	
	# use the snake_segments's previous position to move the segments
	var old_tail_pos: Vector2 = new_state.snake[-1]
	var new_head_pos: Vector2 = new_state.snake[0] + move_direction
	if check_game_over(new_state.snake, new_head_pos, new_state.cells):
		new_state.game_over = true
		return new_state
	move(new_head_pos, new_state.snake)
	# if should eat, eat!
	if (new_head_pos == new_state.food_pos):
		new_state.snake.push_back(old_tail_pos)
		new_state.score += 1
		new_state.food_pos = move_food(new_state.snake, new_state.cells)
	# place boxes
	if (new_state.box_time == 0):
		new_state.boxes.push_back(Vector2(randi_range(0, new_state.cells - 1), randi_range(0, new_state.cells - 1)))
		new_state.box_time = new_state.box_delay
	else:
		new_state.box_time -= 1
	return new_state

## pure
static func check_game_over(snake: Array[Vector2], new_head_pos: Vector2, cells: int) -> bool:
	if new_head_pos in snake:
		return true
	if new_head_pos.x < 0 \
	or new_head_pos.x >= cells \
	or new_head_pos.y < 0 \
	or new_head_pos.y >= cells:
		return true
	return false

## move all the segments along by one
## not pure
static func move(new_head_pos: Vector2, snake: Array[Vector2]) -> void:
	snake.push_front(new_head_pos)
	snake.pop_back()

## pure
static func move_food(snake: Array[Vector2], cells: int) -> Vector2:
	var regen_food = true
	var food_pos: Vector2
	while regen_food:
		regen_food = false
		food_pos = Vector2(randi_range(0, cells - 1), randi_range(0, cells - 1))
		for i in snake:
			if food_pos == i:
				regen_food = true
	return food_pos
