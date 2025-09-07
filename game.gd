extends Node2D

@onready var table = $Table
@onready var balls_container = $Balls
@onready var cue_stick = $CueStick
@onready var ui = $UI

var cue_ball: RigidBody2D

# Audio system
var sfx_player: AudioStreamPlayer2D
var music_player: AudioStreamPlayer
var break_big_sound: AudioStream
var break_small_sound: AudioStream

# Audio buses
var master_bus: int
var music_bus: int
var sfx_bus: int

# Game state management
enum GameState { MENU, PLAYING, GAME_OVER }
enum GameOutcome { NONE, PLAYER1_WIN, PLAYER2_WIN, DRAW }
enum GameMode { PVP, PVC } # Player vs Player, Player vs CPU

var game_state: GameState = GameState.MENU
var game_outcome: GameOutcome = GameOutcome.NONE
var game_mode: GameMode = GameMode.PVP

# Win/Loss condition system
var win_conditions: Array[Callable] = []
var lose_conditions: Array[Callable] = []

# Game statistics for win/loss evaluation
var balls_pocketed_by_player: Dictionary = {1: [], 2: []}
var fouls_by_player: Dictionary = {1: 0, 2: 0}
var scratches_by_player: Dictionary = {1: 0, 2: 0}

func _ready() -> void:
	table.ball_pocketed.connect(_on_ball_pocketed)
	cue_stick.shot_taken.connect(_on_shot_taken)
	cue_stick.power_changed.connect(_on_power_changed)
	cue_stick.aiming_started.connect(_on_aiming_started)
	cue_stick.aiming_stopped.connect(_on_aiming_stopped)
	
	# Setup audio system
	setup_audio()
	
	# Show start menu first
	ui.show_start_menu()
	
	# Start monitoring for balls that fall off table
	start_ball_monitoring()
	
	# Setup table collision layers
	setup_table_physics()

func setup_audio():
	# Create audio buses
	setup_audio_buses()
	
	# Create audio players
	sfx_player = AudioStreamPlayer2D.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Load audio files
	break_big_sound = load("res://assets/audio/break_big.mp3")
	break_small_sound = load("res://assets/audio/break_small.mp3")
	
	# Set music volume to -12db and start background music
	set_music_volume(-12.0)
	start_background_music()

func setup_audio_buses():
	# Get existing bus indices
	master_bus = AudioServer.get_bus_index("Master")
	
	# Create Music bus if it doesn't exist
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(1)  # Add after Master (index 0)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.set_bus_send(1, "Master")  # Send to Master
		print("Created Music bus")
	music_bus = AudioServer.get_bus_index("Music")
	
	# Create SFX bus if it doesn't exist  
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus(2)  # Add after Music
		AudioServer.set_bus_name(2, "SFX") 
		AudioServer.set_bus_send(2, "Master")  # Send to Master
		print("Created SFX bus")
	sfx_bus = AudioServer.get_bus_index("SFX")
	
	print("Audio buses setup - Master:", master_bus, " Music:", music_bus, " SFX:", sfx_bus)
	
func start_game(mode: GameMode):
	game_mode = mode
	game_state = GameState.PLAYING
	setup_win_lose_conditions()
	spawn_cue_ball(table.get_cue_ball_spawn_position())
	setup_rack(table.get_rack_position())
	ui.update_game_mode_display(mode)
	
	# Switch to game music when starting a game
	switch_to_game_music()

func spawn_cue_ball(position: Vector2):
	# Prevent multiple cue balls
	if cue_ball and is_instance_valid(cue_ball):
		print("Cue ball already exists, not spawning another")
		return
	
	# Remove any existing cue balls from the scene
	for ball in balls_container.get_children():
		if ball.is_in_group("cue_ball"):
			ball.queue_free()
	
	var cue_ball_scene = preload("res://scenes/cue_ball.tscn")
	cue_ball = cue_ball_scene.instantiate()
	cue_ball.position = position
	cue_ball.gravity_scale = 0
	cue_ball.linear_damp = 1.0
	cue_ball.angular_damp = 1.0
	cue_ball.z_index = 1
	cue_ball.collision_layer = 1  # Ball layer
	cue_ball.collision_mask = 1   # Collides with other balls and rails
	cue_ball.add_to_group("balls")
	cue_ball.add_to_group("cue_ball")
	balls_container.add_child(cue_ball)
	
	print("Spawned new cue ball at ", position)

func setup_rack(rack_position: Vector2):
	var ball_scenes = [
		preload("res://scenes/ball_1.tscn"),
		preload("res://scenes/ball_2.tscn"),
		preload("res://scenes/ball_3.tscn"),
		preload("res://scenes/ball_4.tscn"),
		preload("res://scenes/ball_5.tscn"),
		preload("res://scenes/ball_6.tscn"),
		preload("res://scenes/ball_7.tscn"),
		preload("res://scenes/ball_8.tscn"),
		preload("res://scenes/ball_9.tscn"),
		preload("res://scenes/ball_10.tscn"),
		preload("res://scenes/ball_11.tscn"),
		preload("res://scenes/ball_12.tscn"),
		preload("res://scenes/ball_13.tscn"),
		preload("res://scenes/ball_14.tscn"),
		preload("res://scenes/ball_15.tscn")
	]
	
	var ball_radius = 15.0
	var ball_spacing = 1.0
	var ball_diameter = ball_radius * 2 + ball_spacing
	
	# Standard 8-ball rack positions (horizontal triangle pointing toward cue ball)
	var rack_positions = [
		Vector2(0, 0),                                    # Ball 1 (front tip)
		Vector2(ball_diameter, -ball_radius),             # Ball 2 (second row left)
		Vector2(ball_diameter, ball_radius),              # Ball 3 (second row right)
		Vector2(ball_diameter * 2, -ball_diameter),       # Ball 4 (third row left)
		Vector2(ball_diameter * 2, 0),                    # Ball 5 (third row center)
		Vector2(ball_diameter * 2, ball_diameter),        # Ball 6 (third row right)
		Vector2(ball_diameter * 3, -ball_diameter * 1.5), # Ball 7 (fourth row)
		Vector2(ball_diameter * 3, -ball_radius),         # Ball 8 (fourth row)
		Vector2(ball_diameter * 3, ball_radius),          # Ball 9 (fourth row)
		Vector2(ball_diameter * 3, ball_diameter * 1.5),  # Ball 10 (fourth row)
		Vector2(ball_diameter * 4, -ball_diameter * 2),   # Ball 11 (fifth row)
		Vector2(ball_diameter * 4, -ball_diameter),       # Ball 12 (fifth row)
		Vector2(ball_diameter * 4, 0),                    # Ball 13 (fifth row)
		Vector2(ball_diameter * 4, ball_diameter),        # Ball 14 (fifth row)
		Vector2(ball_diameter * 4, ball_diameter * 2)     # Ball 15 (fifth row)
	]
	
	for i in range(ball_scenes.size()):
		var ball = ball_scenes[i].instantiate()
		ball.position = rack_position + rack_positions[i]
		ball.gravity_scale = 0
		ball.linear_damp = 1.0
		ball.angular_damp = 1.0
		ball.z_index = 1
		ball.collision_layer = 1  # Ball layer
		ball.collision_mask = 1   # Collides with other balls and rails
		ball.add_to_group("balls")
		balls_container.add_child(ball)

func _input(event):
	# Handle escape key to show settings
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Only show settings if one isn't already open
		if not ui.get_node_or_null("SettingsOverlay"):
			ui.show_settings_menu()
		return
	
	if game_state != GameState.PLAYING:
		return
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if cue_ball and is_instance_valid(cue_ball) and is_ball_stationary(cue_ball):
				# Check if it's CPU's turn in PVC mode
				if game_mode == GameMode.PVC and ui.get_current_player() == 2:
					return # Don't allow manual control of CPU player
				
				# Allow clicking anywhere on the table to start aiming
				cue_stick.start_aiming(cue_ball)
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click to cancel current aiming
			if cue_stick.is_aiming:
				cue_stick.cancel_aiming()

func _on_shot_taken(direction: Vector2, power: float):
	if cue_ball:
		# Play break sound based on power
		play_break_sound(power)
		
		var impulse = direction * power
		cue_ball.apply_central_impulse(impulse)
		
		# Wait for balls to stop, then potentially switch turns
		await get_tree().create_timer(3.0).timeout
		check_turn_switch()

func is_ball_stationary(ball: RigidBody2D) -> bool:
	return ball.linear_velocity.length() < 5.0

func check_turn_switch():
	# For now, simple turn switching after each shot
	# In a full billiards game, you'd check if the player pocketed a ball
	ui.switch_player()
	
	# If it's CPU's turn in PVC mode, trigger CPU action after ensuring balls are ready
	if game_mode == GameMode.PVC and ui.get_current_player() == 2:
		await get_tree().create_timer(0.5).timeout  # Brief pause
		if game_state == GameState.PLAYING:
			await ensure_balls_stationary()  # Wait for all balls to be stationary
			await get_tree().create_timer(1.0).timeout  # Thinking time
			if game_state == GameState.PLAYING:
				cpu_take_shot()

func _on_power_changed(power_ratio: float):
	ui.update_power(power_ratio)

func _on_aiming_started():
	ui.show_power_indicator()

func _on_aiming_stopped():
	ui.hide_power_indicator()

func _on_ball_pocketed(ball: RigidBody2D, pocket_name: String):
	var current_player = ui.get_current_player()
	
	if ball.is_in_group("cue_ball"):
		# Cue ball scratch - remove it immediately
		scratches_by_player[current_player] += 1
		fouls_by_player[current_player] += 1
		ui.add_score(current_player, -1)
		
		print("Cue ball scratched! Player ", current_player, " scratches: ", scratches_by_player[current_player])
		
		# Remove the old cue ball immediately
		ball.queue_free()
		cue_ball = null
		
		# Check for game end before respawning
		check_game_end()
		
		# Only respawn if game hasn't ended
		if game_state == GameState.PLAYING:
			await get_tree().create_timer(1.0).timeout
			spawn_cue_ball(table.get_cue_ball_spawn_position())
	else:
		# Regular ball pocketed
		var ball_number = get_ball_number(ball)
		balls_pocketed_by_player[current_player].append(ball_number)
		ui.add_score(current_player, 1)
		ball.queue_free()
		
		# Check for game end after each ball is pocketed
		check_game_end()

# Win/Loss Condition System
func setup_win_lose_conditions():
	# Basic 8-Ball style conditions - easily extensible
	add_win_condition(check_all_balls_pocketed_by_player)
	add_lose_condition(check_excessive_scratches)
	add_lose_condition(check_cue_ball_pocketed_on_8_ball)

func add_win_condition(condition: Callable):
	win_conditions.append(condition)

func add_lose_condition(condition: Callable):
	lose_conditions.append(condition)

func check_game_end():
	if game_state == GameState.GAME_OVER:
		return
	
	var current_player = ui.get_current_player()
	
	# Check lose conditions first (higher priority)
	for lose_condition in lose_conditions:
		var result = lose_condition.call()
		if result != GameOutcome.NONE:
			end_game(result)
			return
	
	# Check win conditions
	for win_condition in win_conditions:
		var result = win_condition.call()
		if result != GameOutcome.NONE:
			end_game(result)
			return

func end_game(outcome: GameOutcome):
	game_state = GameState.GAME_OVER
	game_outcome = outcome
	cue_stick.set_enabled(false)
	
	# Switch back to menu music when game ends
	switch_to_menu_music()
	
	# Update scores to show WIN/LOSE
	match outcome:
		GameOutcome.PLAYER1_WIN:
			ui.set_final_scores("WIN", "LOSE")
		GameOutcome.PLAYER2_WIN:
			ui.set_final_scores("LOSE", "WIN")
		GameOutcome.DRAW:
			ui.set_final_scores("DRAW", "DRAW")
	
	ui.show_game_end(outcome)

# Example Win/Loss Conditions - easily replaceable for different game modes
func check_all_balls_pocketed_by_player() -> GameOutcome:
	# Win if player pockets 8 or more balls (simplified 8-ball)
	if balls_pocketed_by_player[1].size() >= 8:
		return GameOutcome.PLAYER1_WIN
	elif balls_pocketed_by_player[2].size() >= 8:
		return GameOutcome.PLAYER2_WIN
	return GameOutcome.NONE

func check_excessive_scratches() -> GameOutcome:
	# Lose if player scratches even once
	print("Checking scratches - Player 1: ", scratches_by_player[1], " Player 2: ", scratches_by_player[2])
	if scratches_by_player[1] >= 1:
		print("Player 1 loses due to scratch!")
		return GameOutcome.PLAYER2_WIN
	elif scratches_by_player[2] >= 1:
		print("Player 2 loses due to scratch!")
		return GameOutcome.PLAYER1_WIN
	return GameOutcome.NONE

func check_cue_ball_pocketed_on_8_ball() -> GameOutcome:
	# This would be implemented when we have proper ball identification
	# For now, return NONE
	return GameOutcome.NONE

# Helper functions for game statistics
func get_remaining_balls() -> Array:
	var remaining = []
	for ball in balls_container.get_children():
		if not ball.is_in_group("cue_ball"):
			remaining.append(ball)
	return remaining

func get_ball_number(ball: RigidBody2D) -> int:
	# Extract ball number from scene name or node name
	var name = ball.scene_file_path
	if name:
		var regex = RegEx.new()
		regex.compile("ball_(\\d+)")
		var result = regex.search(name)
		if result:
			return result.get_string(1).to_int()
	return 0

# CPU Player Logic
func cpu_take_shot():
	if not cue_ball or not is_instance_valid(cue_ball):
		print("CPU shot cancelled - no cue ball")
		return
	
	if game_state != GameState.PLAYING:
		print("CPU shot cancelled - game not active")
		return
	
	# Find the closest ball to aim at
	var target_ball = find_closest_ball_to_cue()
	if not target_ball:
		print("CPU shot cancelled - no target ball found")
		return
	
	# Calculate direction from cue ball to target
	var cue_pos = cue_ball.global_position
	var target_pos = target_ball.global_position
	var direction = (target_pos - cue_pos).normalized()
	
	# Add some randomness to make CPU less perfect
	var angle_variation = randf_range(-0.2, 0.2) # Random angle variation
	direction = direction.rotated(angle_variation)
	
	# Random power between 60% and 85%
	var power_ratio = randf_range(0.6, 0.85)
	var power = power_ratio * 2500.0
	
	print("CPU taking shot - Target: ", target_ball.name, " Power: ", int(power_ratio * 100), "%")
	
	# Show cue stick animation for CPU
	await cpu_show_cue_stick_animation(direction, power_ratio)
	
	# Play break sound based on power
	play_break_sound(power)
	
	# Apply the shot
	cue_ball.apply_central_impulse(direction * power)
	
	# Wait for balls to stop, then potentially switch turns
	await wait_for_balls_to_stop()
	check_turn_switch()

func cpu_show_cue_stick_animation(shot_direction: Vector2, power_ratio: float):
	# Show cue stick with proper positioning and power indication
	cue_stick.cpu_show_aim(cue_ball, shot_direction, power_ratio)
	
	# Show power indicator
	ui.show_power_indicator()
	
	# Animate CPU "thinking" - adjusting aim and power slightly
	await cue_stick.cpu_thinking_animation(cue_ball, shot_direction, power_ratio)
	
	# Animate the cue stick moving forward to hit the ball
	await cue_stick.cpu_animate_shot(cue_ball, shot_direction, power_ratio)
	
	# Hide cue stick and power indicator
	cue_stick.cpu_hide()
	ui.hide_power_indicator()

func ensure_balls_stationary():
	var max_wait_time = 10.0  # Maximum time to wait
	var wait_time = 0.0
	var check_interval = 0.1
	
	while wait_time < max_wait_time:
		await get_tree().create_timer(check_interval).timeout
		wait_time += check_interval
		
		var all_stationary = true
		for ball in balls_container.get_children():
			if ball.is_in_group("balls") and not is_ball_stationary(ball):
				all_stationary = false
				break
		
		if all_stationary:
			print("All balls stationary after ", wait_time, " seconds")
			return
	
	print("Timeout waiting for balls to be stationary after ", max_wait_time, " seconds")

func wait_for_balls_to_stop():
	var max_wait_time = 8.0  # Maximum time to wait
	var wait_time = 0.0
	var check_interval = 0.1
	
	while wait_time < max_wait_time:
		await get_tree().create_timer(check_interval).timeout
		wait_time += check_interval
		
		var all_stationary = true
		for ball in balls_container.get_children():
			if ball.is_in_group("balls") and not is_ball_stationary(ball):
				all_stationary = false
				break
		
		if all_stationary:
			print("All balls stopped after ", wait_time, " seconds")
			return
	
	print("Timeout waiting for balls to stop after ", max_wait_time, " seconds")

func find_closest_ball_to_cue() -> RigidBody2D:
	if not cue_ball or not is_instance_valid(cue_ball):
		return null
	
	var cue_pos = cue_ball.global_position
	var closest_ball: RigidBody2D = null
	var closest_distance = INF
	
	for ball in balls_container.get_children():
		if ball == cue_ball or not ball.is_in_group("balls"):
			continue
		
		var distance = cue_pos.distance_to(ball.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_ball = ball
	
	return closest_ball

# Audio functions
func play_break_sound(power: float):
	if not sfx_player:
		return
	
	# Calculate power percentage (assuming max power is 2500.0)
	var max_power = 2500.0
	var power_percentage = (power / max_power) * 100.0
	
	print("Playing break sound for power: ", int(power_percentage), "%")
	
	# Play big break sound for > 50% power, small break sound for <= 50%
	if power_percentage > 50.0:
		if break_big_sound:
			sfx_player.stream = break_big_sound
			sfx_player.play()
	else:
		if break_small_sound:
			sfx_player.stream = break_small_sound
			sfx_player.play()

func start_background_music():
	if not music_player:
		return
	
	var music_stream = load("res://assets/audio/startgame.mp3")
	if music_stream:
		music_player.stream = music_stream
		# Set the music to loop
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		music_player.play()
		print("Started menu background music: startgame.mp3 at -12db")

func switch_to_game_music():
	if not music_player:
		return
	
	var music_stream = load("res://assets/audio/startgame_loop.mp3")
	if music_stream:
		music_player.stream = music_stream
		# Set the music to loop
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		music_player.play()
		print("Switched to game background music: startgame_loop.mp3")

func switch_to_menu_music():
	if not music_player:
		return
	
	var music_stream = load("res://assets/audio/startgame.mp3")
	if music_stream:
		music_player.stream = music_stream
		# Set the music to loop
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		music_player.play()
		print("Switched to menu background music: startgame.mp3")

func play_background_music(music_file: String):
	if not music_player:
		return
	
	var music_stream = load("res://assets/audio/" + music_file)
	if music_stream:
		music_player.stream = music_stream
		music_player.play()
		print("Playing background music: ", music_file)

func stop_background_music():
	if music_player:
		music_player.stop()

func set_music_volume(volume_db: float):
	AudioServer.set_bus_volume_db(music_bus, volume_db)

func set_sfx_volume(volume_db: float):
	AudioServer.set_bus_volume_db(sfx_bus, volume_db)

func get_game_state() -> int:
	return game_state

func reset_game():
	# Reset game state
	game_state = GameState.PLAYING
	game_outcome = GameOutcome.NONE
	
	# Reset scores and statistics
	balls_pocketed_by_player = {1: [], 2: []}
	fouls_by_player = {1: 0, 2: 0}
	scratches_by_player = {1: 0, 2: 0}
	
	# Hide any existing overlays
	ui.hide_game_over_menu()
	ui.hide_power_indicator()
	
	# Reset UI to player 1
	ui.set_current_player(1)
	ui.update_score(1, 0)
	ui.update_score(2, 0)
	
	# Clear existing balls
	for child in balls_container.get_children():
		child.queue_free()
	
	# Wait one frame for cleanup then respawn everything
	await get_tree().process_frame
	
	# Respawn all balls in starting positions
	spawn_cue_ball(table.get_cue_ball_spawn_position())
	setup_rack(table.get_rack_position())
	
	# Disable cue stick during reset
	cue_stick.set_enabled(false)
	
	# Wait for balls to settle, then enable cue stick
	await ensure_balls_stationary()
	cue_stick.set_enabled(true)
	
	# Switch to game music
	switch_to_game_music()
	
	print("Game has been reset!")

# Ball monitoring system to prevent balls from leaving the table
func start_ball_monitoring():
	var monitor_timer = Timer.new()
	monitor_timer.wait_time = 0.5  # Check every half second
	monitor_timer.timeout.connect(_check_ball_positions)
	monitor_timer.autostart = true
	add_child(monitor_timer)

func _check_ball_positions():
	if game_state != GameState.PLAYING:
		return
	
	# Define table boundaries (adjust these values based on your table size)
	var table_bounds = Rect2(200, 100, 1400, 800)  # Approximate table area
	
	for ball in balls_container.get_children():
		if not ball or not is_instance_valid(ball):
			continue
		
		var ball_pos = ball.global_position
		
		# Check if ball is outside table bounds or moving too fast off-screen
		if not table_bounds.has_point(ball_pos) or ball_pos.x < -100 or ball_pos.x > 2000 or ball_pos.y < -100 or ball_pos.y > 1200:
			print("Ball escaped table bounds at position: ", ball_pos)
			
			if ball.is_in_group("cue_ball"):
				# Respawn cue ball at starting position
				print("Respawning cue ball")
				ball.queue_free()
				cue_ball = null
				await get_tree().process_frame
				spawn_cue_ball(table.get_cue_ball_spawn_position())
			else:
				# For numbered balls, move them back to a safe position near the rack
				print("Moving escaped ball back to table")
				var safe_position = table.get_rack_position() + Vector2(randf_range(-50, 50), randf_range(-50, 50))
				ball.global_position = safe_position
				ball.linear_velocity = Vector2.ZERO
				ball.angular_velocity = 0.0

func setup_table_physics():
	# Ensure all table rails have proper collision settings
	var rails_node = table.get_node_or_null("Rails")
	if rails_node:
		for rail in rails_node.get_children():
			if rail is StaticBody2D:
				rail.collision_layer = 1  # Same layer as balls
				rail.collision_mask = 1   # Interact with balls
				print("Setup physics for rail: ", rail.name)
