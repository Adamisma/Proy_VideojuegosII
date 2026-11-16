extends CharacterBody2D

## Controlador de jugador 2D con aceleración, fricción y colisiones (Guía Lab 02 - Sec. 8 y 11)

@export_category("Movement")
@export var max_speed: float = 320.0
@export var sprint_speed: float = 520.0 # Reto de ampliación: Sprint al mantener Shift
@export var acceleration: float = 1400.0
@export var deceleration: float = 1800.0

# Señal para alimentar el indicador HUD de velocidad en tiempo real
signal speed_updated(current_speed: float, is_sprinting: bool)

func _physics_process(delta: float) -> void:
	_update_movement(delta)
	move_and_slide()
	_inspect_collisions()
	
	var is_sprinting: bool = Input.is_action_pressed("sprint") and velocity.length() > 10.0
	speed_updated.emit(velocity.length(), is_sprinting)

func _update_movement(delta: float) -> void:
	# Construcción de vector normalizado a partir de las 4 acciones semánticas (Guía Sec. 8.2)
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	
	# Reto de ampliación: Sprint progresivo
	var current_target_speed := max_speed
	if Input.is_action_pressed("sprint"):
		current_target_speed = sprint_speed
		
	var target_velocity := input_direction * current_target_speed
	
	# Aceleración e inercia progresivas mediante move_toward (Guía Sec. 5.1 y 8.1)
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(
			target_velocity,
			acceleration * delta
		)
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			deceleration * delta
		)

func _inspect_collisions() -> void:
	## Detección programática de colisiones mediante get_slide_collision (Guía Sec. 11)
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider != null:
			# La normal representa el vector perpendicular a la superficie impactada
			# print("Colisión con: ", collider.name, " | Normal: ", collision.get_normal())
			pass
