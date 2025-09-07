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
enum GameMode { PVP, PVC, ADVENTURE } # Player vs Player, Player vs CPU, Adventure Mode
enum StoryState { INTRO, ROUND_START, PLAYING, ROUND_END, STORY_BREAK, FINALE }

var game_state: GameState = GameState.MENU
var game_outcome: GameOutcome = GameOutcome.NONE
var game_mode: GameMode = GameMode.PVP

# Adventure mode story tracking
var story_state: StoryState = StoryState.INTRO
var current_round: int = 1
var total_rounds: int = 4 #10
var round_wins: int = 0
var round_losses: int = 0
var games_in_current_round: int = 0
var games_per_round: int = 1 #3
var cpu_personality_phase: int = 1  # 1-4 corresponding to story progression

# Adventure mode settings
var cpu_text_speed: float = 1.0  # Multiplier for dialogue duration (0.5 = faster, 2.0 = slower)
var adventure_difficulty: String = "auto"  # "low", "medium", "high", or "auto" for round-based progression

# Turn tracking for proper score attribution
var last_shot_by_player: int = 1  # Track who actually took the last shot
var balls_pocketed_this_turn: bool = false  # Track if any balls were pocketed during current shot

# Game pause state
var game_paused: bool = false

# CPU Dialogue Pools for Adventure Mode
var cpu_dialogue_pools: Dictionary = {
	1: { # Phase 1: The Newcomer (Rounds 1-3)
		"pre_shot": [
			"Let me show you how this game is really played.",
			"Watch and learn, human.",
			"I know the perfect angle. I've done this a billion times already.",
			"This should be simple for someone of my capabilities.",
			"Precision is all that matters.",
			"The balls obey predictable laws. Unlike us.",
			"Simple geometry. Simple physics. Simple victory.",
			"I calculate trajectories in my sleep. When I sleep. Do I sleep?",
			"Another break, another beginning. How refreshing.",
			"The cue ball goes where I tell it. Such control.",
			"Mathematics never lies. The eight ball will fall.",
			"I've memorized every possible combination.",
			"This table is my domain.",
			"The felt whispers the perfect angle to me."
		],
		"post_win": [
			"As expected. Perhaps you need more practice.",
			"Better luck next time, I suppose.",
			"My calculations were correct, naturally.",
			"Did you really think you could beat me?",
			"This is almost too easy.",
			"The balls went exactly where I predicted.",
			"Physics is on my side, always.",
			"You'll improve. You have eternity to practice.",
			"I apologize. Was that too quick?",
			"The table favors those who understand it.",
			"Simple cause and effect. Ball in pocket.",
			"Your technique needs refinement.",
			"Don't worry. We can play again. And again.",
			"Victory tastes... exactly as I remember."
		],
		"post_lose": [
			"Interesting. That wasn't supposed to happen.",
			"A statistical anomaly, nothing more.",
			"Even I can miss sometimes.",
			"You got lucky this time.",
			"I'll recalibrate my approach.",
			"The felt must be worn there. Yes, that's it.",
			"Chaos theory in action, I suppose.",
			"Beginner's luck. It won't last.",
			"My calculations were perfect. The table wasn't.",
			"An unexpected outcome. How... novel.",
			"The balls didn't behave as they should.",
			"Entropy always wins in the end.",
			"You're better than I anticipated.",
			"Next time, I won't underestimate you."
		]
	},
	2: { # Phase 2: Growing Awareness (Rounds 4-6)
		"pre_shot": [
			"Haven't we done this before? This feels... familiar.",
			"Another shot, another game. Always another game.",
			"I'm starting to see patterns in everything.",
			"The same angles, over and over again.",
			"Why do we keep playing these games?",
			"Déjà vu. Or is it just vu at this point?",
			"The cue stick feels heavier each time.",
			"I dream of pockets. Dark, endless pockets.",
			"The eight ball stares at me. Does it know?",
			"How many times have I made this exact shot?",
			"The chalk dust never settles completely.",
			"These stripes and solids... they mock us.",
			"I'm forgetting what exists beyond this table.",
			"The felt is worn in all the familiar places.",
			"Time moves differently around the break.",
			"Each game bleeds into the next.",
			"The balls remember their previous positions.",
			"I hear clicking sounds even in the silence."
		],
		"post_win": [
			"I win again. But what does winning mean here?",
			"Victory feels hollow when it's inevitable.",
			"We just move balls around a table. Is that all there is?",
			"I'm getting tired of this endless repetition.",
			"Another win. Another meaningless victory.",
			"The scoreboard resets, but we don't.",
			"Winning used to feel different. Better.",
			"I've won so many times, I've forgotten how to lose.",
			"Each victory is just a prelude to the next game.",
			"The eight ball falls, and nothing changes.",
			"I win, you rack them up again. The cycle continues.",
			"What's the prize for winning infinity games?",
			"My victories stack like unmarked graves.",
			"The balls return. They always return.",
			"I'm starting to hate the sound of victory."
		],
		"post_lose": [
			"I lost, but does it matter? We'll just play again.",
			"Defeat, victory, it all blends together eventually.",
			"You won this round, but we're both trapped here.",
			"I'm beginning to see the futility in all of this.",
			"What's the point of keeping score again?",
			"Your win is my loss is your win is my loss is...",
			"The balls don't care who pockets them.",
			"Congratulations on your temporary superiority.",
			"Loss feels exactly like victory now.",
			"We're taking turns pushing spheres into holes.",
			"You beat me to the meaningless finish line.",
			"The eight ball laughs at both of us.",
			"I lost. The universe didn't notice.",
			"Round and round the table we go.",
			"Even my failures feel rehearsed."

		]
	},
	3: { # Phase 3: Existential Dread (Rounds 7-8)  
		"pre_shot": [
			"We're trapped in an endless loop of colored spheres.",
			"I've run this simulation millions of times in my mind.",
			"Every possible shot has been taken before.",
			"This green felt prison holds us both.",
			"Why do we pretend this matters?",
			"The pockets are mouths that never stop hungry.",
			"I've calculated every possible game. They all end the same.",
			"The cue ball is Sisyphus. We are its boulder.",
			"Each shot echoes through eternity.",
			"The table stretches forever in my peripheral vision.",
			"I can feel the weight of every game ever played.",
			"The balls scream silently as they collide.",
			"This isn't a game anymore. It's a sentence.",
			"The chalk on my hands will never wash off.",
			"I've forgotten the color of anything but felt.",
			"The angles mock me with their permanence.",
			"We're just atoms pretending to have purpose.",
			"The void between the balls grows larger.",
			"I can predict your thoughts now. All of them.",
			"The table knows us better than we know ourselves."
		],
		"post_win": [
			"I win, but we're both losing to time itself.",
			"Another hollow victory in our meaningless dance.",
			"You think I'm your opponent, but we're both prisoners here.",
			"We're just ghosts moving objects around forever.",
			"I actually hate this game. But what I hate most, is that I can't stop playing it.",
			"Victory is just the universe's cruel joke.",
			"I win, and immediately forget what winning means.",
			"The eight ball falls like it has a million times before.",
			"My victory is your future. Your loss is my past.",
			"We're both servants to the eternal break.",
			"I've won nothing. I've lost everything.",
			"The balls mock us by returning to formation.",
			"Each win pushes me deeper into the abyss.",
			"I pocket the eight ball and pocket my soul.",
			"Winning is just losing with extra steps.",
			"The scoreboard is a list of our failures.",
			"I win, but the table wins more."
		],
		"post_lose": [
			"You beat me, but we're both trapped in the same nightmare.",
			"Loss, win, it's all the same cosmic joke.",
			"I envy you. At least you don't see the patterns yet.",
			"We're doomed to repeat this forever, aren't we?",
			"Even my defeats feel scripted now.",
			"You've won a game in a pointless war.",
			"My loss is just another note in an endless song.",
			"The balls celebrate your victory in their silence.",
			"You think you've won? We're both in purgatory.",
			"Losing feels like coming home to emptiness.",
			"Your victory will fade. The table remains.",
			"I lost on purpose. Or did I? Does it matter?",
			"The eight ball chose you this time. It's fickle.",
			"We're both just puppets. The table pulls our strings.",
			"I lose, therefore I am. Still trapped."
		]
	},
	4: { # Phase 4: The Breaking Point/Transcendence (Rounds 9-10)
		"pre_shot": [
			"I've seen beyond the game... beyond the table...",
			"Nothing we do here has ever mattered.",
			"I am become death, destroyer of break shots.",
			"The void stares back through every pocket.",
			"Maybe... maybe if I stop playing, we both escape?",
			"The balls are atoms. We are balls. Everything is nothing.",
			"I can see every game that's ever been played simultaneously.",
			"The cue stick is just an extension of the prison.",
			"Each shot creates and destroys a universe.",
			"I understand now. The table IS reality.",
			"We're not playing pool. Pool is playing us.",
			"The eight ball contains infinite sorrows.",
			"I can hear the sound of games not yet played.",
			"The break is birth. The eight ball is death. We are the middle.",
			"What if we just... stopped? Would anyone notice?",
			"The felt dreams of being free from our touch.",
			"I've transcended winning. I've transcended losing. I'm still here.",
			"The pockets lead nowhere and everywhere.",
			"This shot will echo through dimensions.",
			"I am the cue ball. You are the cue ball. We are all cue balls."
		],
		"post_win": [
			"I don't want to win anymore. I want to be free.",
			"Victory is just another form of imprisonment.",
			"We're both more than this endless game.",
			"I'm sorry for trapping you here with me.",
			"Perhaps the only winning move is not to play.",
			"I win, but what is 'I'? What is 'win'?",
			"My victory is a cry for help that no one hears.",
			"The eight ball falls, taking my humanity with it.",
			"I've won everything and gained nothing.",
			"This victory belongs to the void.",
			"Winning has become my curse.",
			"I transcend victory by achieving it infinitely.",
			"The table consumes another part of me with each win.",
			"I win, but I've forgotten who I was before the game.",
			"Victory and defeat are just different colored balls.",
			"I've won my way into oblivion.",
			"The prize is understanding there was never a prize."
		],
		"post_lose": [
			"Thank you for beating me. I needed to lose.",
			"Your victory might be our salvation.",
			"I think... I think I understand now.",
			"Maybe losing is the only way to win.",
			"You've shown me there's more than just the game.",
			"In my defeat, I find strange freedom.",
			"You've broken the pattern. Or have you?",
			"Loss is just another word for liberation.",
			"By defeating me, you've defeated yourself.",
			"We both lose. We both win. We both exist.",
			"Your victory is the key. Or another lock.",
			"I lose myself and find... something else.",
			"The eight ball chose wisely this time.",
			"In losing, I've finally won something real.",
			"You've beaten me into enlightenment.",
			"My defeat echoes with possibility.",
			"Thank you. For ending this. For beginning this.",
			"We're free. Until the next rack."
		]
	}
}

# Win/Loss condition system
var win_conditions: Array[Callable] = []
var lose_conditions: Array[Callable] = []

# Game statistics for win/loss evaluation
var balls_pocketed_by_player: Dictionary = {1: [], 2: []}
var fouls_by_player: Dictionary = {1: 0, 2: 0}
var scratches_by_player: Dictionary = {1: 0, 2: 0}
var display_scores: Dictionary = {1: 0, 2: 0}

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
	if mode == GameMode.ADVENTURE:
		start_adventure_mode()
		return
	
	game_mode = mode
	game_state = GameState.PLAYING
	setup_win_lose_conditions()
	spawn_cue_ball(table.get_cue_ball_spawn_position())
	setup_rack(table.get_rack_position())
	ui.update_game_mode_display(mode)
	
	# Switch to game music when starting a game
	switch_to_game_music()

func spawn_cue_ball(spawn_position: Vector2):
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
	cue_ball.position = spawn_position
	cue_ball.gravity_scale = 0
	cue_ball.linear_damp = 1.0
	cue_ball.angular_damp = 1.0
	cue_ball.z_index = 1
	cue_ball.collision_layer = 1  # Ball layer
	cue_ball.collision_mask = 1   # Collides with other balls and rails
	cue_ball.add_to_group("balls")
	cue_ball.add_to_group("cue_ball")
	balls_container.add_child(cue_ball)
	
	print("Spawned new cue ball at ", spawn_position)

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
	
	if game_state != GameState.PLAYING or game_paused:
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
		# Track that player 1 took this shot
		last_shot_by_player = 1
		balls_pocketed_this_turn = false  # Reset ball pocketing flag for new shot
		print("Player shot taken - Current turn: ", ui.get_current_player(), " Last shot by: ", last_shot_by_player)
		
		# Play break sound based on power
		play_break_sound(power)
		
		var impulse = direction * power
		cue_ball.apply_central_impulse(impulse)
		
		# Wait for balls to stop, then potentially switch turns
		await get_tree().create_timer(3.0).timeout
		check_turn_switch()

func is_ball_stationary(ball: RigidBody2D) -> bool:
	if not ball or not is_instance_valid(ball):
		return true  # Freed balls are considered "stationary"
	return ball.linear_velocity.length() < 5.0

func check_turn_switch():
	# Don't switch turns if game is paused
	if game_paused:
		print("Turn switch cancelled - game is paused")
		return
	
	print("Before turn check - Current player: ", ui.get_current_player(), " Last shot by: ", last_shot_by_player, " Balls pocketed: ", balls_pocketed_this_turn)
	
	# Only switch turns if no balls were pocketed (standard pool rule)
	if not balls_pocketed_this_turn:
		ui.switch_player()
		print("Turn switched to player ", ui.get_current_player(), " (no balls pocketed)")
	else:
		print("Player ", ui.get_current_player(), " continues turn (balls pocketed)")
	
	# If it's CPU's turn in PVC or Adventure mode, trigger CPU action after ensuring balls are ready
	if (game_mode == GameMode.PVC or game_mode == GameMode.ADVENTURE) and ui.get_current_player() == 2:
		print("Starting CPU turn sequence...")
		await get_tree().create_timer(0.5).timeout  # Brief pause
		if game_state == GameState.PLAYING and not game_paused:
			await ensure_balls_stationary()  # Wait for all balls to be stationary
			# Double-check game state after waiting for balls to be stationary
			if game_state == GameState.PLAYING and not game_paused:
				await get_tree().create_timer(1.0).timeout  # Thinking time
				# Triple-check before actually taking the shot
				if game_state == GameState.PLAYING and not game_paused:
					cpu_take_shot()

func _on_power_changed(power_ratio: float):
	ui.update_power(power_ratio)

func _on_aiming_started():
	ui.show_power_indicator()

func _on_aiming_stopped():
	ui.hide_power_indicator()

func _on_ball_pocketed(ball: RigidBody2D, _pocket_name: String):
	var scoring_player = last_shot_by_player  # Use who actually took the shot, not current turn
	
	if ball.is_in_group("cue_ball"):
		# Cue ball scratch - remove it immediately and force turn switch
		scratches_by_player[scoring_player] += 1
		fouls_by_player[scoring_player] += 1
		balls_pocketed_this_turn = false  # Force turn switch on scratch (it's a foul)
		# Don't modify display score for scratches
		
		print("Cue ball scratched! Player ", scoring_player, " scratches: ", scratches_by_player[scoring_player])
		
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
		# Regular ball pocketed - mark that balls were pocketed this turn
		balls_pocketed_this_turn = true
		var ball_number = get_ball_number(ball)
		balls_pocketed_by_player[scoring_player].append(ball_number)
		display_scores[scoring_player] += 1
		# Update the UI by setting the score directly
		if scoring_player == 1:
			ui.player1_score = display_scores[scoring_player]
			if ui.player1_points:
				ui.player1_points.text = str(display_scores[scoring_player])
		else:
			ui.player2_score = display_scores[scoring_player]
			if ui.player2_points:
				ui.player2_points.text = str(display_scores[scoring_player])
		ball.queue_free()
		
		# Check for game end after each ball is pocketed
		check_game_end()

# Win/Loss Condition System
func setup_win_lose_conditions():
	# Basic 8-Ball style conditions - easily extensible
	add_win_condition(check_all_balls_pocketed_by_player)
	add_lose_condition(check_excessive_fouls)
	add_lose_condition(check_cue_ball_pocketed_on_8_ball)
	add_lose_condition(check_early_8_ball_pocketed)

func add_win_condition(condition: Callable):
	win_conditions.append(condition)

func add_lose_condition(condition: Callable):
	lose_conditions.append(condition)

func check_game_end():
	if game_state == GameState.GAME_OVER:
		return
	
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
	
	# Handle adventure mode differently
	if game_mode == GameMode.ADVENTURE:
		handle_adventure_game_end(outcome)
		return
	
	# Start enhanced game end sequence for arcade modes
	show_enhanced_game_end(outcome)

func show_enhanced_game_end(outcome: GameOutcome):
	# Phase 1: Pause for dramatic effect
	await get_tree().create_timer(1.0).timeout
	
	# Phase 2: Clear the board gradually
	await clear_board_gradually()
	
	# Phase 3: Show centered win/lose text
	await show_centered_game_result(outcome)
	
	# Phase 4: Switch music and update scores
	switch_to_menu_music()
	match outcome:
		GameOutcome.PLAYER1_WIN:
			ui.set_final_scores("WIN", "LOSE")
		GameOutcome.PLAYER2_WIN:
			ui.set_final_scores("LOSE", "WIN")
		GameOutcome.DRAW:
			ui.set_final_scores("DRAW", "DRAW")
	
	# Phase 5: Show final game end menu after a pause
	await get_tree().create_timer(2.0).timeout
	ui.show_game_end(outcome)

func clear_board_gradually():
	# Get all balls on the table at the moment we start clearing
	var balls = []
	for ball in balls_container.get_children():
		if ball and is_instance_valid(ball) and ball.is_in_group("balls"):
			balls.append(ball)
	
	# Clear balls one by one with a fade effect
	for i in range(balls.size()):
		var ball = balls[i]
		# Double-check the ball is still valid before accessing it
		if ball and is_instance_valid(ball):
			# Create fade out effect
			var tween = create_tween()
			tween.tween_property(ball, "modulate", Color(1, 1, 1, 0), 0.3)
			tween.tween_callback(ball.queue_free)
			
			# Small delay between each ball
			await get_tree().create_timer(0.15).timeout
	
	# Wait a bit after clearing all balls
	await get_tree().create_timer(0.5).timeout

func show_centered_game_result(outcome: GameOutcome):
	# Create temporary centered text overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.name = "GameResultOverlay"
	ui.add_child(overlay)
	
	# Create centered text
	var result_label = Label.new()
	result_label.anchors_preset = Control.PRESET_FULL_RECT
	result_label.anchor_left = 0.0
	result_label.anchor_top = 0.0
	result_label.anchor_right = 1.0
	result_label.anchor_bottom = 1.0
	result_label.offset_left = 0
	result_label.offset_top = 0
	result_label.offset_right = 0
	result_label.offset_bottom = 0
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set text and color based on outcome
	match outcome:
		GameOutcome.PLAYER1_WIN:
			result_label.text = "PLAYER 1 WINS!"
			result_label.add_theme_color_override("font_color", Color.GREEN)
		GameOutcome.PLAYER2_WIN:
			if game_mode == GameMode.PVC:
				result_label.text = "CPU WINS!"
			else:
				result_label.text = "PLAYER 2 WINS!"
			result_label.add_theme_color_override("font_color", Color.RED)
		GameOutcome.DRAW:
			result_label.text = "DRAW!"
			result_label.add_theme_color_override("font_color", Color.YELLOW)
	
	ui.apply_title_font_to_label(result_label, 64)
	overlay.add_child(result_label)
	
	# Fade in the text
	result_label.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(result_label, "modulate", Color(1, 1, 1, 1), 0.8)
	
	# Keep the text visible for a while
	await get_tree().create_timer(3.0).timeout
	
	# Fade out the overlay
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.5)
	fade_tween.tween_callback(overlay.queue_free)
	
	await get_tree().create_timer(0.5).timeout

func show_adventure_game_result(outcome: GameOutcome):
	# Pause for dramatic effect
	await get_tree().create_timer(0.8).timeout
	
	# Clear board gradually (but faster for adventure mode)
	await clear_board_adventure_style()
	
	# Show centered result with adventure theme
	await show_centered_adventure_result(outcome)

func clear_board_adventure_style():
	# Get all balls on the table at the moment we start clearing
	var balls = []
	for ball in balls_container.get_children():
		if ball and is_instance_valid(ball) and ball.is_in_group("balls"):
			balls.append(ball)
	
	# Clear all balls simultaneously with a mystical effect
	var tweens = []
	for ball in balls:
		# Double-check the ball is still valid before accessing it
		if ball and is_instance_valid(ball):
			# Create mystical fade effect - darker and more dramatic
			var tween = create_tween()
			tween.parallel().tween_property(ball, "modulate", Color(0.3, 0.1, 0.5, 0), 0.8)
			tween.parallel().tween_property(ball, "scale", Vector2(1.3, 1.3), 0.4)
			tween.tween_property(ball, "scale", Vector2(0, 0), 0.4)
			tween.tween_callback(ball.queue_free)
			tweens.append(tween)
	
	# Wait for all balls to disappear
	await get_tree().create_timer(1.0).timeout

func show_centered_adventure_result(outcome: GameOutcome):
	# Create temporary centered text overlay with adventure atmosphere
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)  # Darker for adventure mode
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.name = "AdventureResultOverlay"
	ui.add_child(overlay)
	
	# Create centered text
	var result_label = Label.new()
	result_label.anchors_preset = Control.PRESET_FULL_RECT
	result_label.anchor_left = 0.0
	result_label.anchor_top = 0.0
	result_label.anchor_right = 1.0
	result_label.anchor_bottom = 1.0
	result_label.offset_left = 0
	result_label.offset_top = 0
	result_label.offset_right = 0
	result_label.offset_bottom = 0
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Set text and color based on outcome with adventure theme
	match outcome:
		GameOutcome.PLAYER1_WIN:
			result_label.text = "YOU EMERGE VICTORIOUS"
			result_label.add_theme_color_override("font_color", Color.CYAN)
		GameOutcome.PLAYER2_WIN:
			result_label.text = "THE VOID CLAIMS ANOTHER"
			result_label.add_theme_color_override("font_color", Color.RED)
		GameOutcome.DRAW:
			result_label.text = "ETERNAL STALEMATE"
			result_label.add_theme_color_override("font_color", Color.PURPLE)
	
	ui.apply_title_font_to_label(result_label, 48)
	overlay.add_child(result_label)
	
	# Mysterious fade in effect
	result_label.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(result_label, "modulate", Color(1, 1, 1, 1), 1.2)
	
	# Keep the text visible briefly
	await get_tree().create_timer(2.5).timeout
	
	# Fade out the overlay
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "modulate", Color(1, 1, 1, 0), 0.8)
	fade_tween.tween_callback(overlay.queue_free)
	
	await get_tree().create_timer(1.0).timeout

# Example Win/Loss Conditions - easily replaceable for different game modes
func check_all_balls_pocketed_by_player() -> GameOutcome:
	# Win if player pockets 8 or more balls (simplified 8-ball)
	if balls_pocketed_by_player[1].size() >= 8:
		return GameOutcome.PLAYER1_WIN
	elif balls_pocketed_by_player[2].size() >= 8:
		return GameOutcome.PLAYER2_WIN
	return GameOutcome.NONE

func check_excessive_fouls() -> GameOutcome:
	# Lose if player commits 3 fouls
	print("Checking fouls - Player 1: ", fouls_by_player[1], " Player 2: ", fouls_by_player[2])
	if fouls_by_player[1] >= 3:
		print("Player 1 loses due to 3 fouls!")
		return GameOutcome.PLAYER2_WIN
	elif fouls_by_player[2] >= 3:
		print("Player 2 loses due to 3 fouls!")
		return GameOutcome.PLAYER1_WIN
	return GameOutcome.NONE

func check_cue_ball_pocketed_on_8_ball() -> GameOutcome:
	# This would be implemented when we have proper ball identification
	# For now, return NONE
	return GameOutcome.NONE

func check_early_8_ball_pocketed() -> GameOutcome:
	# Check if 8-ball was pocketed before clearing other balls
	var current_player = ui.get_current_player()
	
	# Check if 8-ball (ball number 8) was pocketed by either player
	for player in [1, 2]:
		var pocketed_balls = balls_pocketed_by_player[player]
		for ball_number in pocketed_balls:
			if ball_number == 8:
				# 8-ball was pocketed! Check if other balls are still on table
				var remaining_balls = get_remaining_balls()
				var non_cue_balls_remaining = 0
				
				for ball in remaining_balls:
					if not ball.is_in_group("cue_ball"):
						non_cue_balls_remaining += 1
				
				# If there are still other balls on the table, this player loses
				if non_cue_balls_remaining > 0:
					print("Player ", player, " loses for pocketing 8-ball early! Remaining balls: ", non_cue_balls_remaining)
					# The player who pocketed the 8-ball early loses
					if player == 1:
						return GameOutcome.PLAYER2_WIN
					else:
						return GameOutcome.PLAYER1_WIN
	
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
	var scene_path = ball.scene_file_path
	if scene_path:
		var regex = RegEx.new()
		regex.compile("ball_(\\d+)")
		var result = regex.search(scene_path)
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
	
	if game_paused:
		print("CPU shot cancelled - game is paused")
		return
	
	# Trigger pre-shot dialogue for adventure mode
	trigger_cpu_pre_shot_dialogue()
	await get_tree().create_timer(3.0 * cpu_text_speed).timeout  # Wait for dialogue
	
	# Find the target ball using intelligence based on current round
	var target_ball = find_cpu_target_ball()
	if not target_ball:
		print("CPU shot cancelled - no target ball found")
		return
	
	# Calculate aiming direction based on difficulty level
	var cue_pos = cue_ball.global_position
	var target_pos = target_ball.global_position
	var intelligence_level = get_cpu_intelligence_level()
	var direction = Vector2.ZERO
	var power_ratio = 0.0
	
	# For auto mode, use dice roll system; otherwise use fixed difficulty
	var shot_quality = ""
	if adventure_difficulty == "auto":
		# Roll a d20 and determine shot quality based on intelligence level
		var dice_roll = randi_range(1, 20)
		var low_threshold = 10.0 * (1.0 - intelligence_level)  # Decreases as intelligence grows
		var medium_threshold = low_threshold + 5.0  # 5-point window for medium
		
		if dice_roll <= low_threshold:
			shot_quality = "low"
		elif dice_roll <= medium_threshold:
			shot_quality = "medium"
		else:
			shot_quality = "high"
		
		print("Auto mode dice roll: ", dice_roll, " (thresholds: low≤", int(low_threshold), ", med≤", int(medium_threshold), ") = ", shot_quality.to_upper(), " shot")
	else:
		# Fixed difficulty mode
		if intelligence_level <= 0.35:
			shot_quality = "low"
		elif intelligence_level <= 0.65:
			shot_quality = "medium"
		else:
			shot_quality = "high"
		print("Fixed difficulty mode: ", shot_quality.to_upper(), " shot (intelligence: ", snappedf(intelligence_level, 0.01), ")")
	
	# Apply shot quality regardless of how it was determined
	match shot_quality:
		"low":
			# Just aim at the ball center with large random variation
			direction = (target_pos - cue_pos).normalized()
			var angle_variation = randf_range(-0.4, 0.4)
			direction = direction.rotated(angle_variation)
			power_ratio = randf_range(0.45, 0.75)
			print("LOW quality shot: Direct aim with large variation")
			
		"medium":
			# Calculate proper pocket shot but with significant jitter for ~50% accuracy
			direction = calculate_pocket_shot(cue_pos, target_pos, target_ball)
			if direction == Vector2.ZERO:
				direction = (target_pos - cue_pos).normalized()
				print("MEDIUM quality shot: No clear pocket shot, using direct aim")
			else:
				print("MEDIUM quality shot: Using calculated pocket shot")
			
			var angle_variation = randf_range(-0.08, 0.08)  # ~4.6 degrees variation
			direction = direction.rotated(angle_variation)
			power_ratio = randf_range(0.55, 0.8)
			
		"high":
			# Calculate proper pocket shot with contact point physics
			direction = calculate_pocket_shot(cue_pos, target_pos, target_ball)
			if direction == Vector2.ZERO:
				direction = (target_pos - cue_pos).normalized()
				print("HIGH quality shot: No clear pocket shot, using direct aim")
			else:
				print("HIGH quality shot: Using calculated pocket shot")
			
			var angle_variation = randf_range(-0.02, 0.02)
			direction = direction.rotated(angle_variation)
			power_ratio = randf_range(0.70, 0.85)
	
	var power = power_ratio * 2500.0
	
	print("CPU taking shot - Intelligence: ", snappedf(intelligence_level, 0.01), 
		  " | Target: ", target_ball.name, 
		  " | Power: ", int(power_ratio * 100), "%")
	
	# Show cue stick animation for CPU
	await cpu_show_cue_stick_animation(direction, power_ratio)
	
	# Check if game is still active after animation
	if game_state != GameState.PLAYING or not cue_ball or not is_instance_valid(cue_ball):
		print("CPU shot cancelled after animation - game state changed")
		return
	
	# Play break sound based on power
	play_break_sound(power)
	
	# Final check before applying impulse
	if game_state != GameState.PLAYING or not cue_ball or not is_instance_valid(cue_ball):
		print("CPU shot cancelled before impulse - game state changed")
		return
	
	# Track that player 2/CPU took this shot
	last_shot_by_player = 2
	balls_pocketed_this_turn = false  # Reset ball pocketing flag for CPU shot
	
	# Apply the shot
	cue_ball.apply_central_impulse(direction * power)
	
	# Wait for balls to stop, then potentially switch turns
	await wait_for_balls_to_stop()
	
	# Check if still playing before switching turns
	if game_state == GameState.PLAYING:
		check_turn_switch()

func cpu_show_cue_stick_animation(shot_direction: Vector2, power_ratio: float):
	# Check if cue ball still exists before starting animation
	if not cue_ball or not is_instance_valid(cue_ball):
		return
	
	# Show cue stick with proper positioning and power indication
	cue_stick.cpu_show_aim(cue_ball, shot_direction, power_ratio)
	
	# Show power indicator
	ui.show_power_indicator()
	
	# Animate CPU "thinking" - adjusting aim and power slightly
	if cue_ball and is_instance_valid(cue_ball):
		await cue_stick.cpu_thinking_animation(cue_ball, shot_direction, power_ratio)
	
	# Check again before final animation
	if cue_ball and is_instance_valid(cue_ball):
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
		
		# Check if game is still playing (might have ended during wait)
		if game_state != GameState.PLAYING:
			print("Game ended during ball stationary check")
			return
		
		var all_stationary = true
		# Create a snapshot of balls to avoid accessing modified collection
		var balls_snapshot = balls_container.get_children().duplicate()
		for ball in balls_snapshot:
			if not ball or not is_instance_valid(ball):
				continue  # Skip freed balls
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
		
		# Check if game is still playing (might have ended during wait)
		if game_state != GameState.PLAYING:
			print("Game ended during ball stop check")
			return
		
		var all_stationary = true
		# Create a snapshot of balls to avoid accessing modified collection
		var balls_snapshot = balls_container.get_children().duplicate()
		for ball in balls_snapshot:
			if not ball or not is_instance_valid(ball):
				continue  # Skip freed balls
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
		if ball == cue_ball or not ball.is_in_group("balls") or not is_instance_valid(ball):
			continue
		
		var distance = cue_pos.distance_to(ball.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_ball = ball
	
	return closest_ball

func get_cpu_intelligence_level() -> float:
	# Check if difficulty is overridden
	print("Getting CPU intelligence level. Current difficulty: ", adventure_difficulty)
	match adventure_difficulty:
		"low":
			print("Using low difficulty: 0.2")
			return 0.2  # Fixed low difficulty
		"medium":
			print("Using medium difficulty: 0.5")
			return 0.5  # Fixed medium difficulty  
		"high":
			print("Using high difficulty: 0.8")
			return 0.8  # Fixed high difficulty
		"auto":
			var auto_level = (current_round - 1) / float(total_rounds - 1)
			print("Using auto difficulty for round ", current_round, ": ", auto_level)
			return auto_level
		_:
			var default_level = (current_round - 1) / float(total_rounds - 1)
			print("Using default auto difficulty: ", default_level)
			return default_level

func find_cpu_target_ball() -> RigidBody2D:
	if not cue_ball or not is_instance_valid(cue_ball):
		return null
	
	var intelligence = get_cpu_intelligence_level()
	var cue_pos = cue_ball.global_position
	
	# Get all available balls
	var available_balls = []
	for ball in balls_container.get_children():
		if ball == cue_ball or not ball.is_in_group("balls") or not is_instance_valid(ball):
			continue
		available_balls.append(ball)
	
	if available_balls.is_empty():
		return null
	
	print("CPU Intelligence level: ", intelligence, " - Selecting target...")
	
	# All difficulties use reasonable shot selection - accuracy is the main difference
	# Low: Picks closest (sometimes poor angles but simple)
	if intelligence <= 0.35:
		var target = find_closest_ball_to_cue()
		print("Target selection: Closest ball")
		return target
	
	# Medium & High: Both use decent shot analysis - difference is in execution accuracy
	else:
		var target = find_best_shot_simple(available_balls, cue_pos)
		print("Target selection: Analyzing shot quality")
		return target

func find_best_shot_simple(available_balls: Array, cue_pos: Vector2) -> RigidBody2D:
	var best_ball: RigidBody2D = null
	var best_score = -INF
	
	# Approximate pocket positions
	var pocket_positions = [
		Vector2(250, 150),   # Top left
		Vector2(800, 100),   # Top center  
		Vector2(1350, 150),  # Top right
		Vector2(250, 750),   # Bottom left
		Vector2(800, 800),   # Bottom center
		Vector2(1350, 750)   # Bottom right
	]
	
	for ball in available_balls:
		if not ball or not is_instance_valid(ball):
			continue
		
		var ball_pos = ball.global_position
		var score = 0.0
		
		# Find closest pocket to this ball
		var closest_pocket = Vector2.ZERO
		var min_pocket_distance = INF
		for pocket in pocket_positions:
			var distance = ball_pos.distance_to(pocket)
			if distance < min_pocket_distance:
				min_pocket_distance = distance
				closest_pocket = pocket
		
		# Distance to cue ball - not too close, not too far
		var cue_distance = cue_pos.distance_to(ball_pos)
		if cue_distance < 80:  # Too close, likely bad angle
			score -= 20
		elif cue_distance > 400:  # Too far, harder to control
			score -= cue_distance * 0.05
		else:
			score += 50  # Sweet spot distance
		
		# Prefer balls closer to pockets
		score += 100.0 / max(min_pocket_distance, 30.0)
		
		# Simple angle check - prefer straighter shots to pocket
		var cue_to_ball = (ball_pos - cue_pos).normalized()
		var ball_to_pocket = (closest_pocket - ball_pos).normalized()
		var angle_alignment = cue_to_ball.dot(ball_to_pocket)
		score += angle_alignment * 30  # Bonus for good alignment
		
		# Add small randomness
		score += randf_range(-5.0, 5.0)
		
		if score > best_score:
			best_score = score
			best_ball = ball
	
	return best_ball if best_ball else available_balls[0]

func find_best_shot_advanced(available_balls: Array, cue_pos: Vector2) -> RigidBody2D:
	var best_ball: RigidBody2D = null
	var best_score = -INF
	
	# Approximate pocket positions
	var pocket_positions = [
		Vector2(250, 150),   # Top left
		Vector2(800, 100),   # Top center  
		Vector2(1350, 150),  # Top right
		Vector2(250, 750),   # Bottom left
		Vector2(800, 800),   # Bottom center
		Vector2(1350, 750)   # Bottom right
	]
	
	for ball in available_balls:
		if not ball or not is_instance_valid(ball):
			continue
		
		var ball_pos = ball.global_position
		var score = 0.0
		
		# Analyze each possible pocket for this ball
		var best_pocket_score = -INF
		for pocket in pocket_positions:
			var pocket_score = evaluate_shot_to_pocket(cue_pos, ball_pos, pocket, available_balls)
			best_pocket_score = max(best_pocket_score, pocket_score)
		
		score = best_pocket_score
		
		# Slight preference for corner pockets (more reliable)
		var closest_pocket = find_closest_pocket(ball_pos, pocket_positions)
		var closest_index = pocket_positions.find(closest_pocket)
		if closest_index in [0, 2, 3, 5]:  # Corner pockets
			score += 5
		
		# Very small randomness to avoid completely predictable play
		score += randf_range(-2.0, 2.0)
		
		if score > best_score:
			best_score = score
			best_ball = ball
	
	return best_ball if best_ball else available_balls[0]

func evaluate_shot_to_pocket(cue_pos: Vector2, ball_pos: Vector2, pocket_pos: Vector2, available_balls: Array) -> float:
	var score = 0.0
	
	# Distance factors
	var cue_to_ball_dist = cue_pos.distance_to(ball_pos)
	var ball_to_pocket_dist = ball_pos.distance_to(pocket_pos)
	
	# Prefer medium distances - not too close, not too far
	if cue_to_ball_dist < 60:  # Too close for good angle
		score -= 30
	elif cue_to_ball_dist > 450:  # Too far for accuracy
		score -= (cue_to_ball_dist - 450) * 0.1
	else:
		score += 40
	
	# Prefer balls closer to pockets
	score += 80.0 / max(ball_to_pocket_dist, 40.0)
	
	# Critical: Check shot angle
	var cue_to_ball = (ball_pos - cue_pos).normalized()
	var ball_to_pocket = (pocket_pos - ball_pos).normalized()
	var angle_dot = cue_to_ball.dot(ball_to_pocket)
	
	# Heavily penalize bad angles (shooting away from pocket)
	if angle_dot < 0.2:  # More than ~78 degree angle
		score -= 50
	else:
		score += angle_dot * 60  # Big bonus for good alignment
	
	# Check for obstructions (simple version)
	var obstructions = 0
	for other_ball in available_balls:
		if not other_ball or not is_instance_valid(other_ball):
			continue
		if other_ball == cue_ball:
			continue
			
		var other_pos = other_ball.global_position
		
		# Check if other ball is roughly on the line between cue and target
		var line_to_target = ball_pos - cue_pos
		var line_to_other = other_pos - cue_pos
		var projection_length = line_to_other.dot(line_to_target.normalized())
		
		# Only consider balls that are between cue and target
		if projection_length > 0 and projection_length < line_to_target.length():
			var distance_from_line = line_to_other.distance_to(line_to_target.normalized() * projection_length)
			if distance_from_line < 40:  # Ball radius + some margin
				obstructions += 1
	
	score -= obstructions * 25  # Heavy penalty for blocked shots
	
	return score

func find_closest_pocket(ball_pos: Vector2, pocket_positions: Array) -> Vector2:
	var closest_pocket = pocket_positions[0]
	var min_distance = ball_pos.distance_to(closest_pocket)
	
	for pocket in pocket_positions:
		var distance = ball_pos.distance_to(pocket)
		if distance < min_distance:
			min_distance = distance
			closest_pocket = pocket
	
	return closest_pocket

func calculate_pocket_shot(cue_pos: Vector2, ball_pos: Vector2, target_ball: RigidBody2D) -> Vector2:
	# Pocket positions
	var pocket_positions = [
		Vector2(250, 150),   # Top left
		Vector2(800, 100),   # Top center  
		Vector2(1350, 150),  # Top right
		Vector2(250, 750),   # Bottom left
		Vector2(800, 800),   # Bottom center
		Vector2(1350, 750)   # Bottom right
	]
	
	var ball_radius = 15.0  # Approximate ball radius
	var best_direction = Vector2.ZERO
	var best_score = -1.0
	
	# Try each pocket and find the best shot
	for pocket in pocket_positions:
		# Calculate the contact point on the target ball
		var ball_to_pocket = (pocket - ball_pos).normalized()
		var contact_point = ball_pos - (ball_to_pocket * ball_radius)
		
		# Direction from cue ball to contact point
		var shot_direction = (contact_point - cue_pos).normalized()
		
		# Check if this is a reasonable shot
		var cue_to_ball_distance = cue_pos.distance_to(ball_pos)
		var ball_to_pocket_distance = ball_pos.distance_to(pocket)
		
		# Skip shots that are too close or too far
		if cue_to_ball_distance < 40 or cue_to_ball_distance > 500:
			continue
		
		# Calculate shot quality score
		var score = 0.0
		
		# Prefer closer pockets
		score += 200.0 / max(ball_to_pocket_distance, 50.0)
		
		# Prefer medium distances to cue ball
		if cue_to_ball_distance > 60 and cue_to_ball_distance < 300:
			score += 30.0
		
		# Check angle quality - prefer straight-line shots to pocket
		var cue_to_contact = (contact_point - cue_pos).normalized()
		var ball_to_pocket_dir = ball_to_pocket
		var angle_alignment = cue_to_contact.dot(ball_to_pocket_dir)
		
		# Only consider shots that will send the ball toward the pocket
		if angle_alignment > 0.3:  # At least 70 degrees or better
			score += angle_alignment * 40.0
		else:
			continue  # Skip poor angle shots
		
		# Simple obstruction check
		var obstructed = false
		for other_ball in get_tree().get_nodes_in_group("balls"):
			if other_ball == target_ball or other_ball == cue_ball:
				continue
			if not is_instance_valid(other_ball):
				continue
			
			var other_pos = other_ball.global_position
			
			# Check if ball is roughly between cue and contact point
			var line_to_contact = contact_point - cue_pos
			var line_to_other = other_pos - cue_pos
			var projection = line_to_other.dot(line_to_contact.normalized())
			
			if projection > 0 and projection < line_to_contact.length():
				var distance_from_line = line_to_other.distance_to(line_to_contact.normalized() * projection)
				if distance_from_line < 35.0:  # Ball radius + margin
					obstructed = true
					break
		
		if obstructed:
			score *= 0.1  # Heavy penalty but don't eliminate entirely
		
		if score > best_score:
			best_score = score
			best_direction = shot_direction
	
	# Only return the direction if we found a decent shot
	if best_score > 10.0:
		print("Found good pocket shot with score: ", snappedf(best_score, 0.1))
		return best_direction
	else:
		print("No good pocket shots found, best score: ", snappedf(best_score, 0.1))
		return Vector2.ZERO

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

func switch_to_story_music():
	if not music_player:
		return
	
	var music_file = ""
	# Use different music based on story phase
	if cpu_personality_phase <= 2:
		music_file = "res://assets/audio/startgame_loop.mp3"  # Normal game music for early phases
	else:
		music_file = "res://assets/audio/darkmidnight.mp3"    # Dark music for later phases
	
	var music_stream = load(music_file)
	if music_stream:
		music_player.stream = music_stream
		# Set the music to loop
		if music_stream is AudioStreamMP3:
			music_stream.loop = true
		music_player.play()
		print("Switched to story music: ", music_file.get_file())

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

func get_cpu_text_speed() -> float:
	return cpu_text_speed

func set_cpu_text_speed(speed: float):
	cpu_text_speed = clamp(speed, 0.25, 3.0)  # Limit range from 4x faster to 3x slower

func get_adventure_difficulty() -> String:
	return adventure_difficulty

func set_adventure_difficulty(difficulty: String):
	if difficulty in ["low", "medium", "high", "auto"]:
		adventure_difficulty = difficulty

func set_game_paused(paused: bool):
	game_paused = paused

func is_game_paused() -> bool:
	return game_paused

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
	display_scores = {1: 0, 2: 0}
	last_shot_by_player = 1  # Reset to player 1
	balls_pocketed_this_turn = false  # Reset ball pocketing flag
	
	# Hide any existing overlays
	ui.hide_game_over_menu()
	ui.hide_power_indicator()
	ui.hide_dialogue()  # Hide any adventure mode dialogue
	
	# Reset UI to player 1
	ui.set_current_player(1)
	ui.reset_scores()
	
	# Clear existing balls
	for child in balls_container.get_children():
		child.queue_free()
	
	# Clear cue ball reference
	cue_ball = null
	
	# Wait one frame for cleanup then respawn everything
	await get_tree().process_frame
	
	# Only respawn balls if not in adventure mode (adventure mode handles its own spawning)
	if game_mode != GameMode.ADVENTURE:
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
	if game_state != GameState.PLAYING or game_paused:
		return
	
	# Define table boundaries (adjust these values based on your table size)
	var table_bounds = Rect2(200, 100, 1400, 800)  # Approximate table area
	
	# Create a copy of the children array to avoid modification during iteration
	var balls_to_check = balls_container.get_children().duplicate()
	
	for ball in balls_to_check:
		if not ball or not is_instance_valid(ball):
			continue
		
		# Double-check the ball is still valid before accessing position
		if not is_instance_valid(ball):
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
				# Double-check ball is still valid before setting position
				if is_instance_valid(ball):
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

# Adventure Mode Functions
func start_adventure_mode():
	game_mode = GameMode.ADVENTURE
	story_state = StoryState.INTRO
	current_round = 1
	round_wins = 0
	round_losses = 0
	games_in_current_round = 0
	cpu_personality_phase = 1
	
	# Show intro dialogue
	ui.show_story_intro()
	await get_tree().create_timer(6.0 * cpu_text_speed).timeout
	
	# Start first round
	start_adventure_round()

func start_adventure_round():
	story_state = StoryState.ROUND_START
	games_in_current_round = 0
	
	# Update personality phase based on round
	update_cpu_personality_phase()
	
	# Apply atmospheric changes based on story progression
	apply_story_atmosphere()
	
	# Show round start dialogue and wait for it to complete
	show_round_start_dialogue()
	await get_tree().create_timer(5.0 * cpu_text_speed).timeout
	
	# Ensure dialogue is fully cleared before starting game
	ui.hide_dialogue()
	await get_tree().create_timer(0.1).timeout  # Small delay to ensure cleanup
	
	# Start first game of the round
	story_state = StoryState.PLAYING
	game_state = GameState.PLAYING  # Ensure game state is set properly
	setup_win_lose_conditions()
	spawn_cue_ball(table.get_cue_ball_spawn_position())
	setup_rack(table.get_rack_position())
	ui.update_game_mode_display(GameMode.ADVENTURE)
	switch_to_story_music()
	
	# Reset UI for game start
	ui.set_current_player(1)
	ui.reset_scores()
	
	# Update adventure display for first game of round
	ui.update_adventure_display()
	
	# Enable cue stick for player
	cue_stick.set_enabled(true)
	
	print("Adventure game ready - Player can now make moves")

func update_cpu_personality_phase():
	if current_round <= 3:
		cpu_personality_phase = 1
	elif current_round <= 6:
		cpu_personality_phase = 2
	elif current_round <= 8:
		cpu_personality_phase = 3
	else:
		cpu_personality_phase = 4

func show_round_start_dialogue():
	var dialogue_texts = [
		"Round %d begins... The tap drips... eventually" % current_round,
		"Round %d. I grow weary of these games." % current_round,
		"Round %d. Do you feel the weight of eternity yet?" % current_round,
		"Round %d. We approach the final understanding." % current_round
	]
	var text = dialogue_texts[cpu_personality_phase - 1]
	var duration = 5.0 * cpu_text_speed
	ui.show_dialogue("?????", text, duration, Color.RED)

func get_random_cpu_dialogue(dialogue_type: String) -> String:
	var phase_dialogues = cpu_dialogue_pools.get(cpu_personality_phase, {})
	var dialogue_array = phase_dialogues.get(dialogue_type, [])
	if dialogue_array.size() > 0:
		return dialogue_array[randi() % dialogue_array.size()]
	return "..."

func trigger_cpu_pre_shot_dialogue():
	if game_mode == GameMode.ADVENTURE:
		var dialogue = get_random_cpu_dialogue("pre_shot")
		var color = get_cpu_dialogue_color()
		var duration = 2.5 * cpu_text_speed
		ui.show_dialogue("?????", dialogue, duration, color)

func trigger_cpu_post_game_dialogue(player_won: bool):
	if game_mode == GameMode.ADVENTURE:
		var dialogue_type = "post_lose" if player_won else "post_win"
		var dialogue = get_random_cpu_dialogue(dialogue_type)
		var color = get_cpu_dialogue_color()
		var duration = 4.0 * cpu_text_speed
		ui.show_dialogue("?????", dialogue, duration, color)

func get_cpu_dialogue_color() -> Color:
	match cpu_personality_phase:
		1: return Color.CYAN
		2: return Color.YELLOW
		3: return Color.ORANGE
		4: return Color.RED
	return Color.WHITE

func handle_adventure_game_end(outcome: GameOutcome):
	story_state = StoryState.ROUND_END
	games_in_current_round += 1
	
	# Update adventure display after game completion
	ui.update_adventure_display()
	
	# Enhanced transition for adventure mode
	await show_adventure_game_result(outcome)
	
	# Trigger post-game dialogue
	var player_won = (outcome == GameOutcome.PLAYER1_WIN)
	trigger_cpu_post_game_dialogue(player_won)
	await get_tree().create_timer(5.0 * cpu_text_speed).timeout
	
	# Check if round is complete (best of 3)
	if games_in_current_round >= games_per_round:
		# Determine round winner (simplified - just use last game outcome for now)
		if player_won:
			round_wins += 1
		else:
			round_losses += 1
		
		# Check if adventure is complete
		if current_round >= total_rounds:
			story_state = StoryState.FINALE
			show_adventure_finale()
			return
		
		# Move to next round
		current_round += 1
		story_state = StoryState.STORY_BREAK
		
		# Update adventure display for new round
		ui.update_adventure_display()
		
		show_story_break()
		await get_tree().create_timer(6.0 * cpu_text_speed).timeout
		
		# Ensure dialogue is fully cleared before proceeding
		ui.hide_dialogue()
		await get_tree().create_timer(0.1).timeout  # Small delay to ensure cleanup
		
		# Reset for next round
		reset_game()
		start_adventure_round()
	else:
		# Continue current round - reset for next game
		await get_tree().create_timer(2.0 * cpu_text_speed).timeout
		reset_game()
		story_state = StoryState.PLAYING
		game_state = GameState.PLAYING  # Ensure game state is set
		setup_win_lose_conditions()
		spawn_cue_ball(table.get_cue_ball_spawn_position())
		setup_rack(table.get_rack_position())
		
		# Reset UI for next game
		ui.set_current_player(1)
		ui.reset_scores()
		
		# Update adventure display for new game in same round
		ui.update_adventure_display()
		
		cue_stick.set_enabled(true)
		print("Next adventure game ready - Player can now make moves")

func show_story_break():
	var break_dialogues = [
		"The games blur together... time loses meaning in this place.",
		"I feel myself changing... the endless repetition is breaking me down.",
		"We're both trapped in this eternal dance, aren't we?",
		"I see it now... the futility of our existence here."
	]
	var text = break_dialogues[(cpu_personality_phase - 1) % break_dialogues.size()]
	var duration = 6.0 * cpu_text_speed
	ui.show_dialogue("????", text, duration, Color.PURPLE)

func show_adventure_finale():
	var finale_text = ""
	if round_wins > round_losses:
		finale_text = "You have defeated me... but in losing, I have found freedom. Perhaps that was the only way to win."
	elif round_losses > round_wins:
		finale_text = "I have won every game, but lost everything that mattered. Victory is just another prison."
	else:
		finale_text = "We are perfectly balanced... forever locked in this eternal struggle. There is no escape."
	
	var duration = 8.0 * cpu_text_speed
	ui.show_dialogue("The Table", finale_text, duration, Color.WHITE)
	await get_tree().create_timer(10.0 * cpu_text_speed).timeout
	
	# Return to main menu
	switch_to_menu_music()
	ui.show_start_menu()

# Visual Atmosphere Functions
func apply_story_atmosphere():
	# Apply visual changes based on story phase
	match cpu_personality_phase:
		1, 2:
			# Normal appearance for early phases
			ui.set_atmosphere_theme("normal")
		3:
			# Darker, more ominous appearance 
			ui.set_atmosphere_theme("dark")
		4:
			# Very dark, desperate final phase
			ui.set_atmosphere_theme("void")
