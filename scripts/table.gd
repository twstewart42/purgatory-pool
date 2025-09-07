extends Node2D
class_name Table

@export var rail_bounce: float = 0.7
@export var pocket_radius: float = 25.0

@onready var pockets = $Pockets
@onready var ball_spawn = $BallSpawnPoints/CueBallSpawn
@onready var rack_position  = $BallSpawnPoints/RackPosition

signal ball_pocketed(ball, pocket_name)

func _ready() -> void:
	setup_pocket()
	setup_rails()

func setup_pocket():
	for pocket in pockets.get_children():
		if pocket is Area2D:
			pocket.body_entered.connect(_on_pocket_entered.bind(pocket))

func _on_pocket_entered(body: Node2D, pocket: Area2D):
	if body.is_in_group("balls"):
		ball_pocketed.emit(body, pocket.name)

func get_cue_ball_spawn_position() -> Vector2:
	return ball_spawn.global_position

func get_rack_position() -> Vector2:
	return rack_position.global_position

func setup_rails():
	for rail in $Rails.get_children():
		if rail is StaticBody2D:
			rail.set_physics_material_override(PhysicsMaterial.new())
			rail.physics_material_override.bounce = rail_bounce