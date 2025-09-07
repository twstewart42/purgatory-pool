extends Node2D
class_name CueStick

@onready var stick_sprite = $StickSprite

var target_ball: RigidBody2D
var is_aiming: bool = false
var is_enabled: bool = true
var max_power: float = 2500.0
var min_distance: float = 30.0
var max_distance: float = 400.0

signal shot_taken(direction: Vector2, power: float)
signal power_changed(power_ratio: float)
signal aiming_started()
signal aiming_stopped()

func _ready():
	visible = false
	z_index = 0

func start_aiming(ball: RigidBody2D):
	if not is_enabled:
		return
	target_ball = ball
	is_aiming = true
	visible = true
	
	# Position cue stick using CPU-style positioning
	var mouse_pos = get_global_mouse_position()
	var ball_pos = ball.global_position
	var initial_direction = (mouse_pos - ball_pos).normalized()
	var distance = ball_pos.distance_to(mouse_pos)
	
	distance = clamp(distance, min_distance, max_distance)
	
	# Position cue stick like CPU system - at calculated distance from ball
	var cue_length = 100.0  # Approximate length of cue stick sprite
	var stick_offset = initial_direction * (distance + cue_length/2)  # Position tip at proper distance
	global_position = ball_pos + stick_offset
	rotation = initial_direction.angle() + PI
	
	# Calculate and emit initial power
	var power_ratio = (distance - min_distance) / (max_distance - min_distance)
	power_changed.emit(power_ratio)
	
	aiming_started.emit()

func cancel_aiming():
	if not is_aiming:
		return
	
	is_aiming = false
	visible = false
	target_ball = null
	aiming_stopped.emit()

func _input(event):
	if not is_aiming or not target_ball:
		return
	
	if event is InputEventMouseMotion:
		update_aim(event.global_position)
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			shoot()

func update_aim(mouse_pos: Vector2):
	if not target_ball:
		return
	
	var ball_pos = target_ball.global_position
	var mouse_direction = (mouse_pos - ball_pos).normalized()
	var distance = ball_pos.distance_to(mouse_pos)
	
	distance = clamp(distance, min_distance, max_distance)
	
	# Calculate power ratio based on distance from ball
	var power_ratio = (distance - min_distance) / (max_distance - min_distance)
	
	# Position cue stick like CPU system - at calculated distance from ball
	var cue_length = 100.0  # Approximate length of cue stick sprite
	var stick_offset = mouse_direction * (distance + cue_length/2)  # Position tip at proper distance
	global_position = ball_pos + stick_offset
	
	# Point cue stick toward the ball (same as CPU)
	rotation = mouse_direction.angle() + PI
	
	power_changed.emit(power_ratio)

func shoot():
	if not target_ball:
		return
	
	var ball_pos = target_ball.global_position
	var mouse_pos = get_global_mouse_position()
	var mouse_direction = (mouse_pos - ball_pos).normalized()
	var distance = ball_pos.distance_to(mouse_pos)
	
	distance = clamp(distance, min_distance, max_distance)
	var power_ratio = (distance - min_distance) / (max_distance - min_distance)
	var power = power_ratio * max_power
	
	# Animate the shot like CPU system
	await player_animate_shot(mouse_direction, power_ratio)
	
	# Shot goes in opposite direction from where cue stick appears
	var shot_direction = -mouse_direction
	shot_taken.emit(shot_direction, power)
	
	is_aiming = false
	visible = false
	target_ball = null
	aiming_stopped.emit()

func player_animate_shot(direction: Vector2, power_ratio: float):
	if not target_ball:
		return
	
	# Calculate the forward position (closer to ball for impact)
	var ball_pos = target_ball.global_position
	var impact_distance = 25.0  # Distance from ball when "hitting"
	var cue_length = 100.0
	var impact_offset = direction * (impact_distance + cue_length/2)
	var impact_position = ball_pos + impact_offset
	
	# Create tween for smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate moving toward the ball
	var animation_speed = 0.15 + (power_ratio * 0.25)  # Faster animation for more power
	tween.tween_property(self, "global_position", impact_position, animation_speed)
	
	await tween.finished

func set_enabled(enabled: bool):
	is_enabled = enabled
	if not enabled:
		is_aiming = false
		visible = false
		target_ball = null

func cpu_show_aim(ball: RigidBody2D, direction: Vector2, power_ratio: float):
	target_ball = ball
	visible = true
	
	# Calculate distance based on power ratio
	var distance = min_distance + (power_ratio * (max_distance - min_distance))
	
	# Position cue stick BEHIND the cue ball (opposite direction from target)
	var cue_length = 100.0  # Approximate length of cue stick sprite
	var stick_offset = (-direction) * (distance + cue_length/2)  # Negative direction to put cue behind ball
	global_position = ball.global_position + stick_offset
	
	# Point cue stick toward the ball (toward the target direction)
	rotation = direction.angle()
	
	# Emit power change signal for UI update
	power_changed.emit(power_ratio)

func cpu_animate_shot(ball: RigidBody2D, direction: Vector2, power_ratio: float):
	if not target_ball:
		return
	
	# Calculate the impact position (close to ball from behind)
	var impact_distance = 25.0  # Distance from ball when "hitting"
	var cue_length = 100.0
	var impact_offset = (-direction) * (impact_distance + cue_length/2)  # Behind the ball
	var impact_position = ball.global_position + impact_offset
	
	# Create tween for smooth animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate moving toward the ball
	var animation_speed = 0.2 + (power_ratio * 0.3)  # Faster animation for more power
	tween.tween_property(self, "global_position", impact_position, animation_speed)
	
	await tween.finished

func cpu_thinking_animation(ball: RigidBody2D, base_direction: Vector2, power_ratio: float):
	if not target_ball:
		return
	
	var thinking_time = 1.0
	var elapsed = 0.0
	
	while elapsed < thinking_time:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
		# Create slight variations in aim direction (small wobble effect)
		var wobble_amount = 0.08  # Small adjustment range
		var time_factor = elapsed * 3.0  # Speed of wobble
		var wobble_x = sin(time_factor) * wobble_amount
		var wobble_y = cos(time_factor * 1.3) * wobble_amount * 0.5
		
		var adjusted_direction = base_direction + Vector2(wobble_x, wobble_y)
		adjusted_direction = adjusted_direction.normalized()
		
		# Calculate distance and position with slight power wobble
		var power_wobble = sin(time_factor * 2.0) * 0.03  # 3% power variation
		var current_power = clamp(power_ratio + power_wobble, 0.0, 1.0)
		var distance = min_distance + (current_power * (max_distance - min_distance))
		
		# Position cue stick BEHIND the ball (opposite direction from target)
		var cue_length = 100.0
		var stick_offset = (-adjusted_direction) * (distance + cue_length/2)  # Behind the ball
		global_position = ball.global_position + stick_offset
		rotation = adjusted_direction.angle()  # Point toward target
		
		# Update power indicator with wobble
		power_changed.emit(current_power)

func cpu_hide():
	visible = false
	target_ball = null
