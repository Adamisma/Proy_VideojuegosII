extends CharacterBody2D

## Controlador de movimiento del Player (Guía Lab 01 - Sec. 6.6 y 6.7)
@export var speed: float = 250.0

func _physics_process(_delta: float) -> void:
	# Construcción de vector normalizado a partir de las acciones del Input Map
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	
	velocity = direction * speed
	move_and_slide()
	
	# Límite visual de pantalla (Guía Lab 01 - Sec. 6.7: Resolución 1280x720)
	position.x = clamp(position.x, 32.0, 1248.0)
	position.y = clamp(position.y, 32.0, 688.0)
