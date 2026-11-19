extends AnimatableBody2D
class_name DynamicCrate

## ====================================================================
## Laboratorio 08 - Sección 25 & Reto 44: Obstáculo Dinámico con NavigationObstacle2D
## ====================================================================
## Representa un elemento móvil del entorno que participa en la evitación local (Avoidance).
## Los NavigationAgent2D calculan una velocidad segura para rodearlo en tiempo real
## sin necesidad de reconstruir (re-bake) el NavigationPolygon completo.

@export var move_distance: float = 120.0
@export var move_speed: float = 40.0
@export var move_direction: Vector2 = Vector2.DOWN

@onready var nav_obstacle: NavigationObstacle2D = $NavigationObstacle2D

var initial_position: Vector2
var moving_forward: bool = true

func _ready() -> void:
	initial_position = global_position
	if nav_obstacle:
		nav_obstacle.avoidance_enabled = true
		nav_obstacle.radius = 36.0

func _physics_process(delta: float) -> void:
	var target_offset := move_direction.normalized() * (move_distance if moving_forward else 0.0)
	var target_pos := initial_position + target_offset

	global_position = global_position.move_toward(target_pos, move_speed * delta)

	if global_position.distance_to(target_pos) < 2.0:
		moving_forward = not moving_forward
