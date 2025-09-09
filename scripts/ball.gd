extends RigidBody2D
class_name Ball

@onready var animated_sprite = $AnimatedSprite2D
var velocity_threshold = 10.0  # Minimum velocity to consider ball as moving
var last_velocity = Vector2.ZERO
var use_smooth_rotation = true  # Enable smooth rotation instead of frame animation
var rotation_accumulator = 0.0

# Audio collision detection
signal ball_collision(collision_velocity: float)

func _ready():
    if use_smooth_rotation:
        # For smooth rotation, keep the sprite on the first frame
        animated_sprite.stop()
        animated_sprite.frame = 0
    else:
        # For frame animation
        animated_sprite.stop()
        animated_sprite.frame = 0
    
    # Enable contact monitoring for collision detection
    contact_monitor = true
    max_contacts_reported = 10
    body_entered.connect(_on_collision)

func _physics_process(delta):
    var current_velocity = linear_velocity
    var speed = current_velocity.length()
    
    if use_smooth_rotation:
        # Smooth rotation method with physics-based speed
        if speed > velocity_threshold:
            # Calculate rotation based on ball movement
            # Assuming ball radius is about 15 pixels
            var ball_radius = 15.0
            var rotation_speed = speed / ball_radius
            
            # Add velocity-based rotation multiplier for more dramatic effect on fast hits
            var velocity_multiplier = 1.0 + (speed / 300.0)  # Scales with ball speed
            rotation_speed *= velocity_multiplier
            
            # Accumulate rotation
            rotation_accumulator += rotation_speed * delta
            
            # Apply rotation to the sprite
            animated_sprite.rotation = rotation_accumulator
            
            # Add velocity-based scale pulsing - more dramatic for faster balls
            var pulse_intensity = 0.01 + (speed / 1000.0)  # Scales with velocity
            pulse_intensity = clamp(pulse_intensity, 0.01, 0.05)  # Limit the effect
            var pulse = 1.0 + sin(rotation_accumulator * 2.0) * pulse_intensity
            animated_sprite.scale = Vector2(pulse, pulse)
        else:
            # Gradually stop rotation and reset scale
            animated_sprite.scale = Vector2(1.0, 1.0)
    else:
        # Frame-based animation method with dynamic speed based on physics
        # Check if ball just started moving (was stopped, now moving)
        if speed > velocity_threshold and last_velocity.length() <= velocity_threshold:
            start_rolling_animation()
        
        # Check if ball just stopped (was moving, now stopped)
        elif speed <= velocity_threshold and last_velocity.length() > velocity_threshold:
            stop_rolling_animation()
        
        # Update animation speed based on velocity for realistic rolling
        if speed > velocity_threshold:
            # Calculate realistic animation speed based on ball physics
            # Higher velocity = faster frame rate for more realistic rolling effect
            var base_speed = 10.0  # Base animation speed from the sprite frames
            var velocity_multiplier = speed / 100.0  # Adjust this divisor to control sensitivity
            var dynamic_speed = base_speed * velocity_multiplier
            
            # Clamp the speed to reasonable bounds
            dynamic_speed = clamp(dynamic_speed, 2.0, 50.0)  # Min 2fps, Max 50fps
            
            animated_sprite.speed_scale = dynamic_speed / base_speed
    
    last_velocity = current_velocity

func start_rolling_animation():
    animated_sprite.play("default")

func stop_rolling_animation():
    animated_sprite.stop()
    animated_sprite.frame = 0  # Reset to first frame when stopped

func _on_collision(body: Node):
    if body.is_in_group("balls"):
        # Calculate collision velocity for sound intensity
        var collision_velocity = linear_velocity.length()
        if collision_velocity > 50.0:  # Only play sound for significant collisions
            ball_collision.emit(collision_velocity)