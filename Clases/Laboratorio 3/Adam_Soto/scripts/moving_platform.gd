extends AnimatableBody2D

## Plataforma móvil con AnimatableBody2D (Guía Lab 03 - Sec. 18 y Reto 24)
## Proporciona transporte de física seguro para el CharacterBody2D

@export var move_distance: float = 240.0
@export var speed: float = 90.0

var _start_x: float = 0.0
var _direction: float = 1.0

func _ready() -> void:
	_start_x = position.x

func _physics_process(delta: float) -> void:
	position.x += _direction * speed * delta
	
	if abs(position.x - _start_x) >= move_distance:
		_direction *= -1.0
		position.x = _start_x + (_direction * move_distance)
