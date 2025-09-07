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

var max_bar_width: float = 180.0
var player1_score: int = 0
var player2_score: int = 0
var current_player: int = 1

# Font resources
var pixel_font: FontFile

func _ready():
	# Load the pixel font
	pixel_font = load("res://assets/Fonts/PixelOperator8.ttf")
	
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
		apply_font_to_label(player1_label, 16)
	
	if player1_points:
		apply_font_to_label(player1_points, 16)
	
	var player2_label = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2Label")
	if player2_label:
		apply_font_to_label(player2_label, 16)
	
	if player2_points:
		apply_font_to_label(player2_points, 16)
	
	# Apply font to power indicator text
	if power_text:
		apply_font_to_label(power_text, 16)
	
	var power_label = get_node_or_null("PowerIndicator/PowerDisplay/PowerIndicator#PowerLabel")
	if power_label:
		apply_font_to_label(power_label, 16)

func apply_font_to_label(label: Label, size: int):
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
		current_player_indicator.text = "PLAYER " + str(current_player) + "'s TURN"
	
	# Update highlights
	update_player_highlights()

func get_current_player() -> int:
	return current_player

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
		current_player_indicator.text = "PLAYER 1's TURN"
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
	title_label.text = "BILLIARDS GAME"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font_to_label(title_label, 36)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	menu_container.add_child(title_label)
	
	# Add some spacing
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	menu_container.add_child(spacer1)
	
	var mode_label = Label.new()
	mode_label.text = "Select Game Mode:"
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	apply_font_to_label(mode_label, 20)
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
	
	var settings_button = Button.new()
	settings_button.text = "Settings"
	apply_font_to_button(settings_button, 18)
	settings_button.pressed.connect(_on_start_menu_settings)
	menu_container.add_child(settings_button)

func _on_pvp_selected():
	_start_game_with_mode(0) # PVP

func _on_pvc_selected():
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
	
	# Start the game
	var game = get_parent()
	game.start_game(mode)

func update_game_mode_display(mode):
	# Update player labels based on game mode
	if mode == 1: # PVC mode
		var player2_label = get_node_or_null("ScoreBox/Player2Score/Player2Container/Player2Label")
		if player2_label:
			player2_label.text = "CPU"

func set_final_scores(player1_result: String, player2_result: String):
	# Set final WIN/LOSE/DRAW text instead of numbers
	if player1_points:
		player1_points.text = player1_result
		apply_font_to_label(player1_points, 16)
		# Color the text based on result
		if player1_result == "WIN":
			player1_points.add_theme_color_override("font_color", Color.BLUE)
		elif player1_result == "LOSE":
			player1_points.add_theme_color_override("font_color", Color.RED)
		else: # DRAW
			player1_points.add_theme_color_override("font_color", Color.YELLOW)
	
	if player2_points:
		player2_points.text = player2_result
		apply_font_to_label(player2_points, 16)
		# Color the text based on result
		if player2_result == "WIN":
			player2_points.add_theme_color_override("font_color", Color.BLUE)
		elif player2_result == "LOSE":
			player2_points.add_theme_color_override("font_color", Color.RED)
		else: # DRAW
			player2_points.add_theme_color_override("font_color", Color.YELLOW)

func show_settings_menu():
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
	apply_font_to_label(title_label, 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(title_label)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer1)
	
	# Music volume slider
	var music_label = Label.new()
	music_label.text = "Music Volume"
	apply_font_to_label(music_label, 16)
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
	apply_font_to_label(sfx_label, 16)
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

func get_music_volume_display() -> float:
	# Convert actual dB to display value (0-40)
	var game = get_parent()
	var actual_db = AudioServer.get_bus_volume_db(game.music_bus)
	return actual_db + 52  # Convert from -52 to -12 range to 0 to 40 range

func get_sfx_volume() -> float:
	var game = get_parent()
	return AudioServer.get_bus_volume_db(game.sfx_bus)

func show_settings_menu_with_back():
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
	apply_font_to_label(title_label, 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	settings_container.add_child(title_label)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	settings_container.add_child(spacer1)
	
	# Music volume slider
	var music_label = Label.new()
	music_label.text = "Music Volume"
	apply_font_to_label(music_label, 16)
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
	apply_font_to_label(sfx_label, 16)
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
	
	# Reset the game
	var game = get_parent()
	if game and game.has_method("reset_game"):
		game.reset_game()

func _on_settings_back_to_start():
	# Remove settings overlay
	var overlay = get_node_or_null("SettingsOverlay")
	if overlay:
		overlay.queue_free()
	
	# Show start menu again
	show_start_menu()

func hide_game_over_menu():
	# Remove any existing play again overlay
	var overlay = get_node_or_null("PlayAgainOverlay")
	if overlay:
		overlay.queue_free()
