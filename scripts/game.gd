extends Node2D

@onready var table = $Table
@onready var balls_container = $Balls

func _ready() -> void:
    table.ball_pocketed.connect(_on_ball_pocketed)
    
    print("Cue ball spawn position: ", table.get_cue_ball_spawn_position())
    print("Rack position: ", table.get_rack_position())
    
    spawn_cue_ball(table.get_cue_ball_spawn_position())
    setup_rack(table.get_rack_position())

func spawn_cue_ball(position: Vector2):
    print("Spawning cue ball at position: ", position)
    var cue_ball_scene = preload("res://scenes/cue_ball.tscn")
    var cue_ball = cue_ball_scene.instantiate()
    cue_ball.position = position
    cue_ball.add_to_group("balls")
    cue_ball.add_to_group("cue_ball")
    balls_container.add_child(cue_ball)
    print("Cue ball spawned successfully")

func setup_rack(rack_position: Vector2):
    print("Setting up rack at position: ", rack_position)
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
    var row_offset = ball_radius * 2 + ball_spacing
    
    var ball_index = 0
    for row in range(5):
        for col in range(row + 1):
            if ball_index >= ball_scenes.size():
                break
            
            var ball = ball_scenes[ball_index].instantiate()
            var x_offset = col * (ball_radius * 2 + ball_spacing) - row * (ball_radius + ball_spacing/2)
            var y_offset = row * row_offset * 0.866
            
            ball.position = rack_position + Vector2(x_offset, y_offset)
            ball.add_to_group("balls")
            balls_container.add_child(ball)
            ball_index += 1

func _on_ball_pocketed(ball: RigidBody2D, pocket_name: String):
    print("Ball pocketed in " + pocket_name)
    ball.queue_free()