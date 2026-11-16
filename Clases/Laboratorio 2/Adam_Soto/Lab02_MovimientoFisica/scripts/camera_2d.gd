extends Camera2D

## Cámara desacoplada con seguimiento exponencial (Guía Lab 02 - Sec. 13)
@export var target: Node2D
@export var follow_speed: float = 8.0

func _process(delta: float) -> void:
	if target == null:
		return

	# Interpolación exponencial dependiente del tiempo para suavidad independiente de framerate
	global_position = global_position.lerp(
		target.global_position,
		1.0 - exp(-follow_speed * delta)
	)
