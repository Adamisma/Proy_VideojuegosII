class_name Steering
extends RefCounted

## ====================================================================
## Laboratorio 08 - Secciones 26-31: Steering Behaviours en 2D
## ====================================================================
## Biblioteca matemática reutilizable de comportamientos de dirección (Reynolds).
## Proporciona vectores de fuerza o velocidad deseada para dotar a los agentes
## de movimientos naturales y orgánicos (Seek, Flee, Arrive, Wander).

## Sección 27: Seek (Búsqueda / Persecución directa)
## Produce velocidad dirigida en línea recta hacia una posición objetivo.
static func seek(
	current_position: Vector2,
	target_position: Vector2,
	speed: float
) -> Vector2:
	return current_position.direction_to(target_position) * speed

## Sección 28: Flee (Huida / Evasión de amenaza)
## Produce velocidad en dirección opuesta a la posición de la amenaza.
static func flee(
	current_position: Vector2,
	threat_position: Vector2,
	speed: float
) -> Vector2:
	return threat_position.direction_to(current_position) * speed

## Sección 29: Arrive (Llegada suave con desaceleración progresiva)
## Reduce la velocidad gradualmente al entrar en 'slowing_radius', evitando
## frenadas bruscas o sobrepasos del objetivo.
static func arrive(
	current_position: Vector2,
	target_position: Vector2,
	max_speed: float,
	slowing_radius: float
) -> Vector2:
	var to_target: Vector2 = target_position - current_position
	var distance: float = to_target.length()
	if distance <= 0.001:
		return Vector2.ZERO

	var speed_factor: float = minf(distance / maxf(slowing_radius, 0.001), 1.0)
	return to_target.normalized() * max_speed * speed_factor

## Sección 30: Wander (Exploración / Deambulación orgánica controlada)
## Desplaza gradualmente el ángulo de movimiento para generar trayectorias
## fluidas y continuas sin ruido ni temblores en cada frame.
static func wander(
	current_angle: float,
	angle_change_rate: float,
	delta: float,
	wander_speed: float
) -> Dictionary:
	var new_angle: float = current_angle + randf_range(-angle_change_rate, angle_change_rate) * delta
	var velocity: Vector2 = Vector2.from_angle(new_angle) * wander_speed
	return {
		"angle": new_angle,
		"velocity": velocity
	}
