extends AnimatableBody2D

## Obstáculo móvil mediante AnimatableBody2D (Guía Lab 02 - Sec. 6.1 y Reto 18)
## Demuestra la diferencia entre StaticBody2D (estático) y AnimatableBody2D (cinemático controlado)

@export var move_distance: float = 300.0
@export var move_speed: float = 120.0

var _start_x: float = 0.0
var _direction: float = 1.0

func _ready() -> void:
	_start_x = position.x

func _physics_process(delta: float) -> void:
	position.x += _direction * move_speed * delta
	
	if abs(position.x - _start_x) >= move_distance:
		_direction *= -1.0
		position.x = _start_x + (_direction * move_distance)
