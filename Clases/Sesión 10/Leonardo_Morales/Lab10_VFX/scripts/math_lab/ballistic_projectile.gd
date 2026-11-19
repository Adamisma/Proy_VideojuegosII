class_name BallisticProjectile
extends Node2D

## ====================================================================
## Laboratorio 09 - Sección 12 & 13: Proyectil Balístico Analítico
## ====================================================================
## Calcula la trayectoria cinemática bajo aceleración uniforme de forma analítica en función de la edad 't':
##   p(t) = p_0 + v_0 * t + 0.5 * a * t^2
## Ventaja frente al método incremental (Euler): No acumula errores numéricos de truncamiento
## y permite conocer la posición exacta en cualquier instante de tiempo sin derivas.

@export_category("Ballistic Parameters")
@export var lifetime: float = 3.5 ## Tiempo de vida máxima del proyectil en segundos antes de reciclarse
@export var debug_radius: float = 7.0 ## Radio visual del proyectil

@export_category("Visual Appearance")
@export var projectile_color: Color = Color("#E89042")
@export var core_color: Color = Color.WHITE

var origin: Vector2 = Vector2.ZERO
var initial_velocity: Vector2 = Vector2.ZERO
var acceleration: Vector2 = Vector2.ZERO
var age: float = 0.0
var launched: bool = false

## Inicializa las condiciones iniciales del proyectil independiente de otros proyectiles
func launch(
	from_position: Vector2,
	velocity_at_start: Vector2,
	gravity_vector: Vector2
) -> void:
	origin = from_position
	global_position = origin
	initial_velocity = velocity_at_start
	acceleration = gravity_vector
	age = 0.0
	launched = true
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not launched:
		return

	age += delta

	# Fórmula: Ecuación cinemática cuadrática de movimiento bajo aceleración constante
	# p(t) = p_0 + v_0 * t + 0.5 * a * t²
	global_position = origin + (initial_velocity * age) + (0.5 * acceleration * (age * age))

	# Orientar el proyectil tangencialmente a su vector de velocidad instantánea v(t) = v_0 + a * t
	var current_velocity: Vector2 = initial_velocity + (acceleration * age)
	if current_velocity.length_squared() > 0.001:
		rotation = current_velocity.angle()

	# Gestión del ciclo de vida para evitar acumulación y fugas de memoria
	if age >= lifetime:
		queue_free()

func _draw() -> void:
	# Representación gráfica vectorial de proyectil con núcleo brillante
	draw_circle(Vector2.ZERO, debug_radius, projectile_color)
	draw_circle(Vector2.ZERO, 2.5, core_color)
