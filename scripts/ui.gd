extends CanvasLayer
class_name UI

@onready var power_indicator = $PowerIndicator
@onready var power_bar = get_node_or_null("PowerIndicator/PowerIndicator_PowerBarBackground#PowerBar")
@onready var power_text = get_node_or_null("PowerIndicator/PowerDisplay/PowerIndicator#PowerText")
@onready var player1_points = get_node_or_null("ScoreBox/Player1Score/Player1Container/Player1ScoreLabel")
@onready var player2_points = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2ScoreLabel")
@onready var player1_highlight = get_node_or_null("ScoreBox/Player1Score/Player1Highlight")
@onready var player2_highlight = get_node_or_null("ScoreBox/Player2Score/Player2Highlight")
@onready var current_player_indicator = get_node_or_null("CurrentPlayerIndicator")

# Adventure mode round/game display
var adventure_display: Label = null
var adventure_container: Control = null

# Dialogue system
var dialogue_timer: Timer = null

var max_bar_width: float = 180.0
var player1_score: int = 0
var player2_score: int = 0
var current_player: int = 1

# Font resources
var pixel_font: FontFile
var title_font: FontFile

func _ready():
	# Load the pixel font
	pixel_font = load("res://assets/Fonts/Peralta-Regular.ttf")
	title_font = load("res://assets/Fonts/LibertinusKeyboard-Regular.ttf")
	
	if power_indicator:
		power_indicator.visible = false
	
	# Apply font to existing UI elements
	apply_font_to_existing_elements()
	
	# Initialize player turn highlights
	update_player_highlights()

func apply_font_to_existing_elements():
	# Apply font to player labels and scores
	var player1_label = get_node_or_null("ScoreBox/Player1Score/Player1Container/Player1Label")
	if player1_label:
		apply_pixel_font_to_label(player1_label, 16)
	
	if player1_points:
		apply_font_to_label(player1_points, 48)
	
	var player2_label = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2Label")
	if player2_label:
		apply_pixel_font_to_label(player2_label, 16)
	
	if player2_points:
		apply_font_to_label(player2_points, 48)
	
	# Apply font to power indicator text
	if power_text:
		apply_pixel_font_to_label(power_text, 16)
	
	var power_label = get_node_or_null("PowerIndicator/PowerDisplay/PowerIndicator#PowerLabel")
	if power_label:
		apply_pixel_font_to_label(power_label, 16)

func apply_font_to_label(label: Label, size: int):
	if pixel_font and label:
		label.add_theme_font_override("font", title_font)
		label.add_theme_font_size_override("font_size", size)

func apply_title_font_to_label(label: Label, size: int):
	if pixel_font and label:
		label.add_theme_font_override("font", title_font)
		label.add_theme_font_size_override("font_size", size)

func apply_pixel_font_to_label(label: Label, size: int):
	if pixel_font and label:
		label.add_theme_font_override("font", pixel_font)
		label.add_theme_font_size_override("font_size", size)

func apply_font_to_button(button: Button, size: int):
	if pixel_font and button:
		button.add_theme_font_override("font", pixel_font)
		button.add_theme_font_size_override("font_size", size)

func show_power_indicator():
	if power_indicator:
		power_indicator.visible = true

func hide_power_indicator():
	if power_indicator:
		power_indicator.visible = false

func update_power(power_ratio: float):
	if not power_bar or not power_text:
		return
		
	# Clamp power ratio between 0 and 1
	power_ratio = clamp(power_ratio, 0.0, 1.0)
	
	# Update power bar width using offset_right instead of size.x
	var max_width = 180.0
	var new_width = power_ratio * max_width
	power_bar.offset_right = new_width
	
	# Update power bar color (green -> yellow -> red)
	if power_ratio < 0.5:
		# Green to yellow
		power_bar.color = Color(power_ratio * 2, 1, 0, 1)
	else:
		# Yellow to red
		power_bar.color = Color(1, (1 - power_ratio) * 2, 0, 1)
	
	# Update text
	var percentage = int(power_ratio * 100)
	power_text.text = str(percentage) + "%"

func add_score(player: int, points: int):
	if player == 1 and player1_points:
		player1_score += points
		player1_points.text = str(player1_score)
	elif player == 2 and player2_points:
		player2_score += points
		player2_points.text = str(player2_score)

func switch_player():
	current_player = 2 if current_player == 1 else 1
	if current_player_indicator:
		update_turn_indicator()
	
	# Update highlights
	update_player_highlights()

func get_current_player() -> int:
	return current_player

func set_current_player(player: int):
	current_player = player
	if current_player_indicator:
		update_turn_indicator()
	update_player_highlights()

func update_turn_indicator():
	if not current_player_indicator:
		return
		
	var game = get_parent()
	if game and game.game_mode == 2:  # Adventure mode
		if current_player == 1:
			current_player_indicator.text = "YOUR TURN"
			current_player_indicator.add_theme_color_override("font_color", Color.WHITE)
		else:
			current_player_indicator.text = "?????'s TURN"
			current_player_indicator.add_theme_color_override("font_color", Color.RED)
	else:
		current_player_indicator.text = "PLAYER " + str(current_player) + "'s TURN"
		current_player_indicator.add_theme_color_override("font_color", Color.WHITE)

func update_player_highlights():
	if player1_highlight and player2_highlight:
		if current_player == 1:
			player1_highlight.visible = true
			player2_highlight.visible = false
		else:
			player1_highlight.visible = false
			player2_highlight.visible = true

func reset_scores():
	player1_score = 0
	player2_score = 0
	if player1_points:
		player1_points.text = "0"
	if player2_points:
		player2_points.text = "0"
	current_player = 1
	if current_player_indicator:
		update_turn_indicator()
	update_player_highlights()

func show_game_end(outcome):
	# Create game end overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "GameEndOverlay"
	add_child(overlay)
	
	# Create centered container manually
	var end_container = VBoxContainer.new()
	end_container.anchor_left = 0.5
	end_container.anchor_top = 0.5
	end_container.anchor_right = 0.5
	end_container.anchor_bottom = 0.5
	end_container.offset_left = -200  # Half width of container
	end_container.offset_top = -100   # Half height of container
	end_container.offset_right = 200  # Half width of container
	end_container.offset_bottom = 100 # Half height of container
	overlay.add_child(end_container)
	
	var title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font_to_label(title_label, 48)
	
	var message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font_to_label(message_label, 24)
	
	match outcome:
		1: # PLAYER1_WIN
			title_label.text = "PLAYER 1 WINS!"
			title_label.add_theme_color_override("font_color", Color.GREEN)
			message_label.text = "Congratulations!"
		2: # PLAYER2_WIN  
			title_label.text = "PLAYER 2 WINS!"
			title_label.add_theme_color_override("font_color", Color.GREEN)
			message_label.text = "Congratulations!"
		3: # DRAW
			title_label.text = "DRAW!"
			title_label.add_theme_color_override("font_color", Color.YELLOW)
			message_label.text = "Great game!"
		_:
			title_label.text = "GAME OVER"
			message_label.text = ""
	
	end_container.add_child(title_label)
	end_container.add_child(message_label)
	
	var restart_button = Button.new()
	restart_button.text = "Play Again"
	apply_font_to_button(restart_button, 20)
	restart_button.pressed.connect(_on_restart_pressed)
	end_container.add_child(restart_button)
	
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 10)
	end_container.add_child(spacer4)
	
	var settings_button = Button.new()
	settings_button.text = "Settings"
	apply_font_to_button(settings_button, 20)
	settings_button.pressed.connect(_on_game_end_settings)
	end_container.add_child(settings_button)
	
	var spacer5 = Control.new()
	spacer5.custom_minimum_size = Vector2(0, 10)
	end_container.add_child(spacer5)
	
	var quit_button = Button.new()
	quit_button.text = "Quit"
	apply_font_to_button(quit_button, 20)
	quit_button.pressed.connect(_on_quit_pressed)
	end_container.add_child(quit_button)

func _on_restart_pressed():
	# Remove overlay
	var overlay = get_node_or_null("GameEndOverlay")
	if overlay:
		overlay.queue_free()
	
	# Reset game
	get_tree().reload_current_scene()

func _on_quit_pressed():
	# Quit the game
	get_tree().quit()

func show_start_menu():
	# Pause the game elements while showing the start menu
	#pause_game_elements()
	
	# Create start menu overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "StartMenuOverlay"
	add_child(overlay)
	
	# Create centered container manually
	var menu_container = VBoxContainer.new()
	menu_container.anchor_left = 0.5
	menu_container.anchor_top = 0.5
	menu_container.anchor_right = 0.5
	menu_container.anchor_bottom = 0.5
	menu_container.offset_left = -150  # Half width of container
	menu_container.offset_top = -120   # Half height of container
	menu_container.offset_right = 150  # Half width of container
	menu_container.offset_bottom = 120 # Half height of container
	overlay.add_child(menu_container)
	
	var title_label = Label.new()
	title_label.text = "Purgatory Pool"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_title_font_to_label(title_label, 36)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	menu_container.add_child(title_label)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	menu_container.add_child(spacer1)
	
	var mode_label = Label.new()
	mode_label.text = "Select Game Mode:"
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(mode_label, 20)
	mode_label.add_theme_color_override("font_color", Color.WHITE)
	menu_container.add_child(mode_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	menu_container.add_child(spacer2)
	
	var arcade_button = Button.new()
	arcade_button.text = "Arcade Mode"
	apply_font_to_button(arcade_button, 18)
	arcade_button.pressed.connect(_on_arcade_selected)
	menu_container.add_child(arcade_button)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	menu_container.add_child(spacer3)
	
	var adventure_button = Button.new()
	adventure_button.text = "Adventure Mode"
	adventure_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Golden color
	apply_font_to_button(adventure_button, 18)
	adventure_button.pressed.connect(_on_adventure_selected)
	menu_container.add_child(adventure_button)
	
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 10)
	menu_container.add_child(spacer4)
	
	var settings_button = Button.new()
	settings_button.text = "Settings"
	apply_font_to_button(settings_button, 18)
	settings_button.pressed.connect(_on_start_menu_settings)
	menu_container.add_child(settings_button)
	
	var spacer5 = Control.new()
	spacer5.custom_minimum_size = Vector2(0, 10)
	menu_container.add_child(spacer5)
	
	var credits_button = Button.new()
	credits_button.text = "Credits"
	apply_font_to_button(credits_button, 18)
	credits_button.pressed.connect(_on_credits_selected)
	menu_container.add_child(credits_button)
	
	var spacer6 = Control.new()
	spacer6.custom_minimum_size = Vector2(0, 10)
	menu_container.add_child(spacer6)
	
	var quit_button = Button.new()
	quit_button.text = "Quit Game"
	quit_button.add_theme_color_override("font_color", Color.RED)
	apply_font_to_button(quit_button, 18)
	quit_button.pressed.connect(_on_quit_game_selected)
	menu_container.add_child(quit_button)

func _on_arcade_selected():
	show_arcade_submenu()

func _on_adventure_selected():
	# Close main menu first
	var main_overlay = get_node_or_null("StartMenuOverlay")
	if main_overlay:
		main_overlay.queue_free()
	
	_start_game_with_mode(2) # ADVENTURE

func _on_credits_selected():
	# Close main menu first
	var main_overlay = get_node_or_null("StartMenuOverlay")
	if main_overlay:
		main_overlay.queue_free()
	
	# Show credits
	show_credits()

func _on_quit_game_selected():
	# Close main menu first
	var main_overlay = get_node_or_null("StartMenuOverlay")
	if main_overlay:
		main_overlay.queue_free()
	
	# Quit the game
	get_tree().quit()

func _on_pvp_selected():
	# Close arcade submenu first
	var arcade_overlay = get_node_or_null("ArcadeMenuOverlay")
	if arcade_overlay:
		arcade_overlay.queue_free()
	
	_start_game_with_mode(0) # PVP

func _on_pvc_selected():
	# Close arcade submenu first
	var arcade_overlay = get_node_or_null("ArcadeMenuOverlay")
	if arcade_overlay:
		arcade_overlay.queue_free()
	
	_start_game_with_mode(1) # PVC

func _on_start_menu_settings():
	# Check if settings is already open
	if get_node_or_null("SettingsOverlay"):
		return
		
	# Remove start menu first
	var start_overlay = get_node_or_null("StartMenuOverlay")
	if start_overlay:
		start_overlay.queue_free()
	
	# Show settings menu with back button
	show_settings_menu_with_back()

func _on_game_end_settings():
	# Check if settings is already open
	if get_node_or_null("SettingsOverlay"):
		return
	show_settings_menu()

func _start_game_with_mode(mode: int):
	# Remove start menu
	var overlay = get_node_or_null("StartMenuOverlay")
	if overlay:
		overlay.queue_free()
	
	# Resume the game
	resume_game_elements()
	
	# Start the game
	var game = get_parent()
	game.start_game(mode)


func set_final_scores(player1_result: String, player2_result: String):
	# Set final WIN/LOSE/DRAW text instead of numbers
	if player1_points:
		player1_points.text = player1_result
		apply_pixel_font_to_label(player1_points, 16)
		# Color the text based on result
		if player1_result == "WIN":
			player1_points.add_theme_color_override("font_color", Color.BLUE)
		elif player1_result == "LOSE":
			player1_points.add_theme_color_override("font_color", Color.RED)
		else: # DRAW
			player1_points.add_theme_color_override("font_color", Color.YELLOW)
	
	if player2_points:
		player2_points.text = player2_result
		apply_pixel_font_to_label(player2_points, 16)
		# Color the text based on result
		if player2_result == "WIN":
			player2_points.add_theme_color_override("font_color", Color.BLUE)
		elif player2_result == "LOSE":
			player2_points.add_theme_color_override("font_color", Color.RED)
		else: # DRAW
			player2_points.add_theme_color_override("font_color", Color.YELLOW)

func show_settings_menu():
	# Don't pause game elements for settings menu - we don't want to dim music
	# when user is adjusting volume settings
	
	# Create settings overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "SettingsOverlay"
	add_child(overlay)
	
	# Create centered container manually
	var settings_container = VBoxContainer.new()
	settings_container.anchor_left = 0.5
	settings_container.anchor_top = 0.5
	settings_container.anchor_right = 0.5
	settings_container.anchor_bottom = 0.5
	settings_container.offset_left = -200  # Half width of container
	settings_container.offset_top = -150   # Half height of container
	settings_container.offset_right = 200  # Half width of container
	settings_container.offset_bottom = 150 # Half height of container
	overlay.add_child(settings_container)
	
	var title_label = Label.new()
	title_label.text = "SETTINGS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(title_label, 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(title_label)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer1)
	
	# Music volume slider
	var music_label = Label.new()
	music_label.text = "Music Volume"
	apply_pixel_font_to_label(music_label, 16)
	music_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(music_label)
	
	var music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 40
	music_slider.step = 1
	music_slider.value = get_music_volume_display()
	music_slider.custom_minimum_size = Vector2(300, 20)
	music_slider.value_changed.connect(_on_music_volume_changed_display)
	settings_container.add_child(music_slider)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer2)
	
	# SFX volume slider
	var sfx_label = Label.new()
	sfx_label.text = "Sound Effects Volume"
	apply_pixel_font_to_label(sfx_label, 16)
	sfx_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = -40
	sfx_slider.max_value = 0
	sfx_slider.step = 1
	sfx_slider.value = get_sfx_volume()
	sfx_slider.custom_minimum_size = Vector2(300, 20)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	settings_container.add_child(sfx_slider)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer3)
	
	# CPU Text Speed slider (Adventure Mode)
	var cpu_speed_label = Label.new()
	cpu_speed_label.text = "CPU Text Speed (Adventure Mode)"
	apply_pixel_font_to_label(cpu_speed_label, 16)
	cpu_speed_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(cpu_speed_label)
	
	var cpu_speed_slider = HSlider.new()
	cpu_speed_slider.min_value = 0.25
	cpu_speed_slider.max_value = 3.0
	cpu_speed_slider.step = 0.25
	cpu_speed_slider.value = get_cpu_text_speed()
	cpu_speed_slider.custom_minimum_size = Vector2(300, 20)
	cpu_speed_slider.value_changed.connect(_on_cpu_text_speed_changed)
	settings_container.add_child(cpu_speed_slider)
	
	var spacer3b = Control.new()
	spacer3b.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer3b)
	
	# Adventure Mode Difficulty setting
	var difficulty_label = Label.new()
	difficulty_label.text = "Adventure Mode Difficulty"
	apply_pixel_font_to_label(difficulty_label, 16)
	difficulty_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(difficulty_label)
	
	var difficulty_container = HBoxContainer.new()
	settings_container.add_child(difficulty_container)
	
	var low_button = Button.new()
	low_button.text = "Low"
	low_button.toggle_mode = true
	apply_font_to_button(low_button, 14)
	low_button.toggled.connect(_on_difficulty_button_toggled.bind("low", low_button))
	difficulty_container.add_child(low_button)
	
	var medium_button = Button.new()
	medium_button.text = "Medium"
	medium_button.toggle_mode = true
	apply_font_to_button(medium_button, 14)
	medium_button.toggled.connect(_on_difficulty_button_toggled.bind("medium", medium_button))
	difficulty_container.add_child(medium_button)
	
	var high_button = Button.new()
	high_button.text = "High"
	high_button.toggle_mode = true
	apply_font_to_button(high_button, 14)
	high_button.toggled.connect(_on_difficulty_button_toggled.bind("high", high_button))
	difficulty_container.add_child(high_button)
	
	var auto_button = Button.new()
	auto_button.text = "Auto"
	auto_button.toggle_mode = true
	apply_font_to_button(auto_button, 14)
	auto_button.toggled.connect(_on_difficulty_button_toggled.bind("auto", auto_button))
	difficulty_container.add_child(auto_button)
	
	# Set current difficulty button as pressed
	var current_difficulty = get_adventure_difficulty()
	match current_difficulty:
		"low":
			low_button.button_pressed = true
		"medium":
			medium_button.button_pressed = true
		"high":
			high_button.button_pressed = true
		"auto":
			auto_button.button_pressed = true
	
	var spacer3c = Control.new()
	spacer3c.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer3c)
	
	# Add Reset Game button if currently in a game
	var game = get_parent()
	if game and game.has_method("get_game_state") and game.get_game_state() == 1:  # GameState.PLAYING
		var reset_button = Button.new()
		reset_button.text = "Reset Game"
		reset_button.add_theme_color_override("font_color", Color.RED)
		apply_font_to_button(reset_button, 18)
		reset_button.pressed.connect(_on_reset_game)
		settings_container.add_child(reset_button)
		
		var spacer4 = Control.new()
		spacer4.custom_minimum_size = Vector2(0, 10)
		settings_container.add_child(spacer4)
		
		var quit_to_menu_button = Button.new()
		quit_to_menu_button.text = "Quit to Menu"
		quit_to_menu_button.add_theme_color_override("font_color", Color.ORANGE)
		apply_font_to_button(quit_to_menu_button, 18)
		quit_to_menu_button.pressed.connect(_on_quit_to_menu)
		settings_container.add_child(quit_to_menu_button)
		
		var spacer5 = Control.new()
		spacer5.custom_minimum_size = Vector2(0, 10)
		settings_container.add_child(spacer5)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	apply_font_to_button(close_button, 18)
	close_button.pressed.connect(_on_settings_close)
	settings_container.add_child(close_button)

func _on_music_volume_changed_display(value: float):
	# Convert display value (0-40) to actual dB (-52 to -12)
	var actual_db = -52 + value
	var game = get_parent()
	game.set_music_volume(actual_db)

func _on_sfx_volume_changed(value: float):
	var game = get_parent()
	game.set_sfx_volume(value)

func _on_settings_close():
	var overlay = get_node_or_null("SettingsOverlay")
	if overlay:
		overlay.queue_free()
	
	# Don't resume game elements since we didn't pause them for settings

func get_music_volume_display() -> float:
	# Convert actual dB to display value (0-40)
	var game = get_parent()
	var actual_db = AudioServer.get_bus_volume_db(game.music_bus)
	return actual_db + 52  # Convert from -52 to -12 range to 0 to 40 range

func get_sfx_volume() -> float:
	var game = get_parent()
	return AudioServer.get_bus_volume_db(game.sfx_bus)

func get_cpu_text_speed() -> float:
	var game = get_parent()
	return game.get_cpu_text_speed()

func _on_cpu_text_speed_changed(value: float):
	var game = get_parent()
	game.set_cpu_text_speed(value)

func show_settings_menu_with_back():
	# Don't pause game elements for settings menu - we don't want to dim music
	# when user is adjusting volume settings
	
	# Create settings overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "SettingsOverlay"
	add_child(overlay)
	
	# Create centered container manually
	var settings_container = VBoxContainer.new()
	settings_container.anchor_left = 0.5
	settings_container.anchor_top = 0.5
	settings_container.anchor_right = 0.5
	settings_container.anchor_bottom = 0.5
	settings_container.offset_left = -200  # Half width of container
	settings_container.offset_top = -150   # Half height of container
	settings_container.offset_right = 200  # Half width of container
	settings_container.offset_bottom = 150 # Half height of container
	overlay.add_child(settings_container)
	
	var title_label = Label.new()
	title_label.text = "SETTINGS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(title_label, 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(title_label)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer1)
	
	# Music volume slider
	var music_label = Label.new()
	music_label.text = "Music Volume"
	apply_pixel_font_to_label(music_label, 16)
	music_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(music_label)
	
	var music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 40
	music_slider.step = 1
	music_slider.value = get_music_volume_display()
	music_slider.custom_minimum_size = Vector2(300, 20)
	music_slider.value_changed.connect(_on_music_volume_changed_display)
	settings_container.add_child(music_slider)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer2)
	
	# SFX volume slider
	var sfx_label = Label.new()
	sfx_label.text = "Sound Effects Volume"
	apply_pixel_font_to_label(sfx_label, 16)
	sfx_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = -40
	sfx_slider.max_value = 0
	sfx_slider.step = 1
	sfx_slider.value = get_sfx_volume()
	sfx_slider.custom_minimum_size = Vector2(300, 20)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	settings_container.add_child(sfx_slider)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer3)
	
	# CPU Text Speed slider (Adventure Mode)
	var cpu_speed_label = Label.new()
	cpu_speed_label.text = "CPU Text Speed (Adventure Mode)"
	apply_pixel_font_to_label(cpu_speed_label, 16)
	cpu_speed_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(cpu_speed_label)
	
	var cpu_speed_slider = HSlider.new()
	cpu_speed_slider.min_value = 0.25
	cpu_speed_slider.max_value = 3.0
	cpu_speed_slider.step = 0.25
	cpu_speed_slider.value = get_cpu_text_speed()
	cpu_speed_slider.custom_minimum_size = Vector2(300, 20)
	cpu_speed_slider.value_changed.connect(_on_cpu_text_speed_changed)
	settings_container.add_child(cpu_speed_slider)
	
	var spacer3b = Control.new()
	spacer3b.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer3b)
	
	# Adventure Mode Difficulty setting
	var difficulty_label = Label.new()
	difficulty_label.text = "Adventure Mode Difficulty"
	apply_pixel_font_to_label(difficulty_label, 16)
	difficulty_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(difficulty_label)
	
	var difficulty_container = HBoxContainer.new()
	settings_container.add_child(difficulty_container)
	
	var low_button = Button.new()
	low_button.text = "Low"
	low_button.toggle_mode = true
	apply_font_to_button(low_button, 14)
	low_button.toggled.connect(_on_difficulty_button_toggled.bind("low", low_button))
	difficulty_container.add_child(low_button)
	
	var medium_button = Button.new()
	medium_button.text = "Medium"
	medium_button.toggle_mode = true
	apply_font_to_button(medium_button, 14)
	medium_button.toggled.connect(_on_difficulty_button_toggled.bind("medium", medium_button))
	difficulty_container.add_child(medium_button)
	
	var high_button = Button.new()
	high_button.text = "High"
	high_button.toggle_mode = true
	apply_font_to_button(high_button, 14)
	high_button.toggled.connect(_on_difficulty_button_toggled.bind("high", high_button))
	difficulty_container.add_child(high_button)
	
	var auto_button = Button.new()
	auto_button.text = "Auto"
	auto_button.toggle_mode = true
	apply_font_to_button(auto_button, 14)
	auto_button.toggled.connect(_on_difficulty_button_toggled.bind("auto", auto_button))
	difficulty_container.add_child(auto_button)
	
	# Set current difficulty button as pressed
	var current_difficulty = get_adventure_difficulty()
	match current_difficulty:
		"low":
			low_button.button_pressed = true
		"medium":
			medium_button.button_pressed = true
		"high":
			high_button.button_pressed = true
		"auto":
			auto_button.button_pressed = true
	
	var spacer3c = Control.new()
	spacer3c.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer3c)
	
	# Add Reset Game button if currently in a game
	var game = get_parent()
	if game and game.has_method("get_game_state") and game.get_game_state() == 1:  # GameState.PLAYING
		var reset_button = Button.new()
		reset_button.text = "Reset Game"
		reset_button.add_theme_color_override("font_color", Color.RED)
		apply_font_to_button(reset_button, 18)
		reset_button.pressed.connect(_on_reset_game)
		settings_container.add_child(reset_button)
		
		var spacer4 = Control.new()
		spacer4.custom_minimum_size = Vector2(0, 10)
		settings_container.add_child(spacer4)
		
		var quit_to_menu_button = Button.new()
		quit_to_menu_button.text = "Quit to Menu"
		quit_to_menu_button.add_theme_color_override("font_color", Color.ORANGE)
		apply_font_to_button(quit_to_menu_button, 18)
		quit_to_menu_button.pressed.connect(_on_quit_to_menu)
		settings_container.add_child(quit_to_menu_button)
		
		var spacer5 = Control.new()
		spacer5.custom_minimum_size = Vector2(0, 10)
		settings_container.add_child(spacer5)
	
	# Back button (returns to start menu)
	var back_button = Button.new()
	back_button.text = "Back"
	apply_font_to_button(back_button, 18)
	back_button.pressed.connect(_on_settings_back_to_start)
	settings_container.add_child(back_button)

func _on_reset_game():
	# Close settings menu first
	var overlay = get_node_or_null("SettingsOverlay")
	if overlay:
		overlay.queue_free()
	
	# Resume the game
	resume_game_elements()
	
	# Reset the game
	var game = get_parent()
	if game and game.has_method("reset_game"):
		game.reset_game()

func _on_quit_to_menu():
	# Close settings menu first
	var overlay = get_node_or_null("SettingsOverlay")
	if overlay:
		overlay.queue_free()
	
	# Resume the game
	resume_game_elements()
	
	# Stop the game and return to menu
	var game = get_parent()
	if game:
		# Reset game state to menu
		game.game_state = game.GameState.MENU
		game.game_mode = game.GameMode.PVP
		
		# Clear all balls
		for child in game.balls_container.get_children():
			child.queue_free()
		game.cue_ball = null
		
		# Disable cue stick
		game.cue_stick.set_enabled(false)
		
		# Reset scores to zero
		reset_scores()
		
		# Hide any overlays
		hide_game_over_menu()
		hide_power_indicator()
		hide_dialogue()
		hide_adventure_display()
		
		# Switch to menu music
		game.switch_to_menu_music()
		
		# Reset UI atmosphere to normal
		set_atmosphere_theme("normal")
		
		# Show main menu
		show_start_menu()

func _on_settings_back_to_start():
	# Remove settings overlay
	var overlay = get_node_or_null("SettingsOverlay")
	if overlay:
		overlay.queue_free()
	
	# Don't resume game elements since we didn't pause them for settings
	# Show start menu again
	
	# Show start menu again
	show_start_menu()

func show_arcade_submenu():
	# Remove main menu
	var main_overlay = get_node_or_null("StartMenuOverlay")
	if main_overlay:
		main_overlay.queue_free()
	
	# Game remains paused from start menu (don't call pause again)
	# Create arcade submenu overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.4)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "ArcadeMenuOverlay"
	add_child(overlay)
	
	# Create centered container manually
	var menu_container = VBoxContainer.new()
	menu_container.anchor_left = 0.5
	menu_container.anchor_top = 0.5
	menu_container.anchor_right = 0.5
	menu_container.anchor_bottom = 0.5
	menu_container.offset_left = -150  # Half width of container
	menu_container.offset_top = -120   # Half height of container
	menu_container.offset_right = 150  # Half width of container
	menu_container.offset_bottom = 120 # Half height of container
	overlay.add_child(menu_container)
	
	var title_label = Label.new()
	title_label.text = "ARCADE MODE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(title_label, 36)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	menu_container.add_child(title_label)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	menu_container.add_child(spacer1)
	
	var mode_label = Label.new()
	mode_label.text = "Select Game Mode:"
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(mode_label, 20)
	mode_label.add_theme_color_override("font_color", Color.WHITE)
	menu_container.add_child(mode_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	menu_container.add_child(spacer2)
	
	var pvp_button = Button.new()
	pvp_button.text = "Player vs Player"
	apply_font_to_button(pvp_button, 18)
	pvp_button.pressed.connect(_on_pvp_selected)
	menu_container.add_child(pvp_button)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 10)
	menu_container.add_child(spacer3)
	
	var pvc_button = Button.new()
	pvc_button.text = "Player vs CPU"
	apply_font_to_button(pvc_button, 18)
	pvc_button.pressed.connect(_on_pvc_selected)
	menu_container.add_child(pvc_button)
	
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 10)
	menu_container.add_child(spacer4)
	
	var back_button = Button.new()
	back_button.text = "Back"
	apply_font_to_button(back_button, 18)
	back_button.pressed.connect(_on_arcade_back)
	menu_container.add_child(back_button)

func _on_arcade_back():
	# Remove arcade menu
	var arcade_overlay = get_node_or_null("ArcadeMenuOverlay")
	if arcade_overlay:
		arcade_overlay.queue_free()
	
	# Show main menu again
	show_start_menu()

func hide_game_over_menu():
	# Remove any existing play again overlay
	var overlay = get_node_or_null("PlayAgainOverlay")
	if overlay:
		overlay.queue_free()

# Adventure Mode Dialogue System
func show_dialogue(speaker: String, text: String, duration: float = 3.0, color: Color = Color.WHITE):
	# Remove existing dialogue if any
	hide_dialogue()
	
	# Create dialogue overlay
	var overlay = Control.new()
	overlay.name = "DialogueOverlay"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)
	
	# Create dialogue container at bottom of screen
	var dialogue_container = VBoxContainer.new()
	dialogue_container.anchor_left = 0.1
	dialogue_container.anchor_top = 0.75
	dialogue_container.anchor_right = 0.9
	dialogue_container.anchor_bottom = 0.95
	dialogue_container.offset_left = 0
	dialogue_container.offset_top = 0
	dialogue_container.offset_right = 0
	dialogue_container.offset_bottom = 0
	overlay.add_child(dialogue_container)
	
	# Semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	dialogue_container.add_child(bg)
	
	# Speaker label
	var speaker_label = Label.new()
	speaker_label.text = speaker.to_upper()
	speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	apply_pixel_font_to_label(speaker_label, 14)
	speaker_label.add_theme_color_override("font_color", Color.YELLOW)
	dialogue_container.add_child(speaker_label)
	
	# Dialogue text
	var dialogue_label = Label.new()
	dialogue_label.text = text
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_pixel_font_to_label(dialogue_label, 16)
	dialogue_label.add_theme_color_override("font_color", color)
	dialogue_container.add_child(dialogue_label)
	
	# Auto-hide after duration
	if duration > 0:
		# Clean up any existing timer first
		if dialogue_timer:
			dialogue_timer.queue_free()
			dialogue_timer = null
		
		dialogue_timer = Timer.new()
		dialogue_timer.wait_time = duration
		dialogue_timer.one_shot = true
		dialogue_timer.timeout.connect(hide_dialogue)
		add_child(dialogue_timer)
		dialogue_timer.start()

func hide_dialogue():
	# Clean up the dialogue timer first
	if dialogue_timer:
		dialogue_timer.queue_free()
		dialogue_timer = null
	
	# Remove the dialogue overlay
	var overlay = get_node_or_null("DialogueOverlay")
	if overlay:
		overlay.queue_free()

func show_story_intro():
	var game = get_parent()
	var duration = 3.0 * game.get_cpu_text_speed()
	show_dialogue("??????", "Welcome. Would you like to play a game of pool? There's not much else to do here.", duration, Color.CYAN)

# Adventure Mode Atmosphere System
var current_atmosphere_theme: String = "normal"

func set_atmosphere_theme(theme: String):
	current_atmosphere_theme = theme
	apply_atmosphere_to_ui_elements()

func apply_atmosphere_to_ui_elements():
	var theme_color = Color.WHITE
	
	match current_atmosphere_theme:
		"normal":
			theme_color = Color.WHITE
		"dark":
			theme_color = Color(0.9, 0.8, 0.7)  # Slightly warmer/darker
		"void":
			theme_color = Color(0.7, 0.7, 0.8)  # Cool, desaturated
	
	# Apply theme to score box elements
	var score_box = get_node_or_null("ScoreBox")
	if score_box:
		score_box.modulate = theme_color
	
	# Apply theme to power indicator (use existing member variable)
	if power_indicator:
		power_indicator.modulate = theme_color

func update_game_mode_display(mode):
	# Update player labels based on game mode
	if mode == 2: # Adventure mode
		var player1_label = get_node_or_null("ScoreBox/Player1Score/Player1Container/Player1Label")
		if player1_label:
			player1_label.text = "YOU"
			player1_label.add_theme_color_override("font_color", Color.CYAN)
		
		var player2_label = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2Label")
		if player2_label:
			player2_label.text = "??????"
			player2_label.add_theme_color_override("font_color", Color.RED)
		
		# Show adventure mode round/game display
		show_adventure_display()
	elif mode == 1: # PVC mode  
		var player1_label = get_node_or_null("ScoreBox/Player1Score/Player1Container/Player1Label")
		if player1_label:
			player1_label.text = "PLAYER 1"
			player1_label.add_theme_color_override("font_color", Color.WHITE)
		
		var player2_label = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2Label")
		if player2_label:
			player2_label.text = "CPU"
			player2_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Hide adventure display for non-adventure modes
		hide_adventure_display()
	else: # PVP mode
		var player1_label = get_node_or_null("ScoreBox/Player1Score/Player1Container/Player1Label")
		if player1_label:
			player1_label.text = "PLAYER 1"
			player1_label.add_theme_color_override("font_color", Color.WHITE)
		
		var player2_label = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2Label")
		if player2_label:
			player2_label.text = "PLAYER 2"
			player2_label.add_theme_color_override("font_color", Color.WHITE)
		
		# Hide adventure display for non-adventure modes
		hide_adventure_display()

func get_adventure_difficulty() -> String:
	var game = get_parent()
	return game.get_adventure_difficulty()

func _on_difficulty_changed(difficulty: String):
	print("Difficulty changed to: ", difficulty)
	
	# Save the setting
	var game = get_parent()
	game.set_adventure_difficulty(difficulty)
	print("Adventure difficulty set to: ", game.get_adventure_difficulty())
	
	# Update button states in the current settings menu
	var overlay = get_node_or_null("SettingsOverlay")
	if overlay:
		# Find all HBoxContainers (difficulty containers) in the settings
		_update_difficulty_buttons_recursive(overlay, difficulty)

func _on_difficulty_button_toggled(pressed: bool, difficulty: String, _button: Button):
	# Only process when button is pressed (toggled on), ignore when toggled off
	if not pressed:
		return
		
	print("Difficulty button toggled: ", difficulty)
	_on_difficulty_changed(difficulty)

func _update_difficulty_buttons_recursive(node: Node, difficulty: String):
	# Look for HBoxContainer that contains difficulty buttons
	if node is HBoxContainer:
		var has_difficulty_buttons = false
		for child in node.get_children():
			if child is Button and child.text.to_lower() in ["low", "medium", "high", "auto"]:
				has_difficulty_buttons = true
				break
		
		if has_difficulty_buttons:
			print("Found difficulty button container, updating buttons")
			for child in node.get_children():
				if child is Button:
					child.button_pressed = (child.text.to_lower() == difficulty)
			return
	
	# Recursively search child nodes
	for child in node.get_children():
		_update_difficulty_buttons_recursive(child, difficulty)

# Game pause/resume system
var game_paused: bool = false
var original_music_volume: float = 0.0

func pause_game_elements():
	if game_paused:
		return
		
	game_paused = true
	var game = get_parent()
	if not game:
		return
	
	# Store original music volume and lower it
	original_music_volume = AudioServer.get_bus_volume_db(game.music_bus)
	AudioServer.set_bus_volume_db(game.music_bus, original_music_volume - 15.0)  # 15dB quieter
	
	# Disable cue stick
	if game.cue_stick:
		game.cue_stick.set_enabled(false)
	
	# Set a flag that prevents CPU from taking actions
	game.set_game_paused(true)

func resume_game_elements():
	if not game_paused:
		return
		
	game_paused = false
	var game = get_parent()
	if not game:
		return
	
	# Restore original music volume
	AudioServer.set_bus_volume_db(game.music_bus, original_music_volume)
	
	# Clear the pause flag and simply re-enable the cue stick
	game.set_game_paused(false)
	
	# Re-enable cue stick if game is playing (keep it simple)
	if game.cue_stick and game.game_state == game.GameState.PLAYING:
		game.cue_stick.set_enabled(true)
		print("Resumed game - Current player: ", get_current_player())
		
		# Check if CPU needs to resume its turn
		game.check_and_resume_cpu_turn()

# Adventure Mode Display Functions
func show_adventure_display():
	if adventure_container:
		adventure_container.visible = true
		return
	
	# Find the ScoreBox to position under it
	var score_box = get_node_or_null("ScoreBox")
	if not score_box:
		print("ScoreBox not found, cannot position adventure display")
		return
	
	# Create adventure display container with same styling as ScoreBox
	adventure_container = Control.new()
	adventure_container.name = "AdventureContainer"
	
	# Position directly under the ScoreBox
	adventure_container.anchor_left = score_box.anchor_left
	adventure_container.anchor_top = score_box.anchor_bottom
	adventure_container.anchor_right = score_box.anchor_right
	adventure_container.anchor_bottom = score_box.anchor_bottom
	adventure_container.offset_left = score_box.offset_left
	adventure_container.offset_top = score_box.offset_bottom + 10  # Small gap
	adventure_container.offset_right = score_box.offset_right
	adventure_container.offset_bottom = score_box.offset_bottom + 70  # Height for round/game info
	
	# Add background similar to ScoreBox
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)  # Match ScoreBox transparency
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	adventure_container.add_child(bg)
	
	# Create adventure display label
	adventure_display = Label.new()
	adventure_display.name = "AdventureDisplay"
	
	# Position within container
	adventure_display.anchor_left = 0.0
	adventure_display.anchor_top = 0.0
	adventure_display.anchor_right = 1.0
	adventure_display.anchor_bottom = 1.0
	adventure_display.offset_left = 10
	adventure_display.offset_top = 5
	adventure_display.offset_right = -10
	adventure_display.offset_bottom = -5
	
	# Style the label to match ScoreBox style
	adventure_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	adventure_display.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(adventure_display, 14)  # Slightly smaller than score text
	adventure_display.add_theme_color_override("font_color", Color.WHITE)
	
	adventure_container.add_child(adventure_display)
	add_child(adventure_container)
	update_adventure_display()

func hide_adventure_display():
	if adventure_container:
		adventure_container.visible = false

func update_adventure_display():
	if not adventure_display:
		return
	
	var game = get_parent()
	if not game:
		return
	
	var round_text = "Round %d" % [game.current_round]
	var game_text = "Game %d" % [game.games_in_current_round + 1]
	
	adventure_display.text = round_text + "\n" + game_text
	
	# Update visibility based on game mode
	var is_adventure_mode = (game.game_mode == game.GameMode.ADVENTURE)
	if adventure_container:
		adventure_container.visible = is_adventure_mode

# Credits System
func show_credits():
	# Create credits overlay with dark background
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.name = "CreditsOverlay"
	add_child(overlay)
	
	# Create centered container manually
	var credits_container = VBoxContainer.new()
	credits_container.anchor_left = 0.5
	credits_container.anchor_top = 0.5
	credits_container.anchor_right = 0.5
	credits_container.anchor_bottom = 0.5
	credits_container.offset_left = -200  # Half width of container
	credits_container.offset_top = -100   # Half height of container
	credits_container.offset_right = 200  # Half width of container
	credits_container.offset_bottom = 100 # Half height of container
	overlay.add_child(credits_container)
	
	# Credits title
	var title_label = Label.new()
	title_label.text = "CREDITS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_title_font_to_label(title_label, 48)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	credits_container.add_child(title_label)
	
	# Add spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	credits_container.add_child(spacer1)
	
	# Game section
	var game_label = Label.new()
	game_label.text = "PURGATORY POOL"
	game_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(game_label, 24)
	game_label.add_theme_color_override("font_color", Color.YELLOW)
	credits_container.add_child(game_label)
	
	var by_label = Label.new()
	by_label.text = "By Stewpendous Studios"
	by_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(by_label, 16)
	by_label.add_theme_color_override("font_color", Color.WHITE)
	credits_container.add_child(by_label)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	credits_container.add_child(spacer2)
	
	# Development section
	var dev_label = Label.new()
	dev_label.text = "DEVELOPMENT"
	dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(dev_label, 20)
	dev_label.add_theme_color_override("font_color", Color.YELLOW)
	credits_container.add_child(dev_label)
	
	var dev_name = Label.new()
	dev_name.text = "Stew Stunes"
	dev_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(dev_name, 16)
	dev_name.add_theme_color_override("font_color", Color.WHITE)
	credits_container.add_child(dev_name)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	credits_container.add_child(spacer3)
	
	# Audio section
	var audio_label = Label.new()
	audio_label.text = "AUDIO"
	audio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(audio_label, 20)
	audio_label.add_theme_color_override("font_color", Color.YELLOW)
	credits_container.add_child(audio_label)
	
	var audio_name = Label.new()
	audio_name.text = "Stew Stunes"
	audio_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(audio_name, 16)
	audio_name.add_theme_color_override("font_color", Color.WHITE)
	credits_container.add_child(audio_name)
	
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 20)
	credits_container.add_child(spacer4)
	
	# Art section
	var art_label = Label.new()
	art_label.text = "ART & DESIGN"
	art_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(art_label, 20)
	art_label.add_theme_color_override("font_color", Color.YELLOW)
	credits_container.add_child(art_label)
	
	var art_credit = Label.new()
	art_credit.text = "Assets from https://opengameart.org/content/8-ball-pool-assets"
	art_credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_credit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_pixel_font_to_label(art_credit, 14)
	art_credit.add_theme_color_override("font_color", Color.WHITE)
	credits_container.add_child(art_credit)
	
	var spacer5 = Control.new()
	spacer5.custom_minimum_size = Vector2(0, 20)
	credits_container.add_child(spacer5)
	
	# Special Thanks section
	var thanks_label = Label.new()
	thanks_label.text = "SPECIAL THANKS"
	thanks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(thanks_label, 20)
	thanks_label.add_theme_color_override("font_color", Color.YELLOW)
	credits_container.add_child(thanks_label)
	
	var thanks_text = Label.new()
	thanks_text.text = "To Claude AI for helping code this\nin a weekend vs a month"
	thanks_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	thanks_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	apply_pixel_font_to_label(thanks_text, 14)
	thanks_text.add_theme_color_override("font_color", Color.WHITE)
	credits_container.add_child(thanks_text)
	
	var spacer6 = Control.new()
	spacer6.custom_minimum_size = Vector2(0, 30)
	credits_container.add_child(spacer6)
	
	# Back button
	var back_button = Button.new()
	back_button.text = "Back to Main Menu"
	apply_font_to_button(back_button, 20)
	back_button.pressed.connect(_on_credits_back)
	credits_container.add_child(back_button)

func create_credits_section(section_title: String, section_content: String) -> VBoxContainer:
	var section = VBoxContainer.new()
	
	# Section title
	var title = Label.new()
	title.text = section_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_pixel_font_to_label(title, 24)
	title.add_theme_color_override("font_color", Color.YELLOW)
	section.add_child(title)
	
	# Small spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	section.add_child(spacer)
	
	# Section content
	if section_content != "":
		var content = Label.new()
		content.text = section_content
		content.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		apply_pixel_font_to_label(content, 16)
		content.add_theme_color_override("font_color", Color.WHITE)
		section.add_child(content)
	
	return section

func _on_credits_back():
	# Remove credits overlay
	var overlay = get_node_or_null("CreditsOverlay")
	if overlay:
		overlay.queue_free()
	
	# Return to main menu
	show_start_menu()
