class_name CameraShake
extends Camera2D

## ====================================================================
## Proyecto Cahuide - Sacudida Paramétrica de Cámara (Juice)
## ====================================================================
## Solo se dispara al recibir daño Cahuide o al activar el Power-Up del Sol.

@export var decay: float = 2.4
@export var max_offset: Vector2 = Vector2(14.0, 10.0)
@export var max_roll: float = 0.05

var trauma: float = 0.0
var trauma_power: int = 2
var time_counter: float = 0.0

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		_shake(delta)
	else:
		offset = Vector2.ZERO
		rotation = 0.0

func trigger_shake(amount: float = 0.6) -> void:
	trauma = min(trauma + amount, 1.0)

func _shake(delta: float) -> void:
	time_counter += delta * 45.0
	var amount := pow(trauma, trauma_power)
	rotation = max_roll * amount * sin(time_counter * 1.3)
	offset.x = max_offset.x * amount * cos(time_counter)
	offset.y = max_offset.y * amount * sin(time_counter * 0.9)
