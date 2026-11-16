class_name FOVSentinel
extends Node2D

## ====================================================================
## Laboratorio 09 - Sección 19 & 25: Campo de Visión (FOV) y Producto Punto
## ====================================================================
## Determina si un objetivo se encuentra dentro de un cono angular frontal de visión:
##   look · toward = |look| * |toward| * cos(α)
## Al estar ambos vectores normalizados (|look| = |toward| = 1):
##   look · toward = cos(α) >= cos(half_angle_degrees)
## Si el producto punto es mayor o igual al umbral, el ángulo α <= half_angle_degrees.

@export_category("FOV Configuration")
@export var half_angle_degrees: float = 45.0 ## Semi-ángulo del cono visual (cono total = 2 * 45° = 90°)
@export var vision_range: float = 220.0 ## Alcance radial máximo de visión en píxeles
@export var rotation_speed: float = 0.8 ## Velocidad de giro del centinela en rad/s

@export_category("Visual Appearance")
@export var idle_color: Color = Color(0.2, 0.8, 0.4, 0.25)
@export var alert_color: Color = Color(0.95, 0.25, 0.2, 0.4)
@export var body_color: Color = Color("#2A324B")

var facing_direction: Vector2 = Vector2.RIGHT
var target_in_sight: bool = false
var last_calculated_dot: float = 0.0
var threshold_cos: float = 0.0

func _ready() -> void:
	# Precalcular el umbral trigonométrico del cono
	threshold_cos = cos(deg_to_rad(half_angle_degrees))

func _physics_process(delta: float) -> void:
	# Rotación continua para escanear el entorno
	rotation += rotation_speed * delta
	facing_direction = Vector2.from_angle(rotation)

	# Evaluar visión respecto a la posición del mouse
	var mouse_pos := get_global_mouse_position()
	target_in_sight = check_target_fov(mouse_pos)
	queue_redraw()

## Verifica matemáticamente si un punto está dentro del cono visual y del rango de distancia
func check_target_fov(target_pos: Vector2) -> bool:
	var offset: Vector2 = target_pos - global_position
	var distance_squared: float = offset.length_squared()

	# Descartar si supera el alcance máximo
	if distance_squared > (vision_range * vision_range):
		last_calculated_dot = -1.0
		return false

	if distance_squared < 0.0001:
		last_calculated_dot = 1.0
		return true

	var look: Vector2 = facing_direction.normalized()
	var toward: Vector2 = offset.normalized()

	# Fórmula: Producto punto de vectores normalizados = cos(ángulo relativo)
	last_calculated_dot = look.dot(toward)
	threshold_cos = cos(deg_to_rad(half_angle_degrees))

	return last_calculated_dot >= threshold_cos

func _draw() -> void:
	# Dibujar el cuerpo del centinela
	draw_circle(Vector2.ZERO, 14.0, body_color)
	draw_line(Vector2.ZERO, Vector2(22.0, 0.0), Color.WHITE, 3.0)

	# Dibujar el cono de visión angular
	var cone_color := alert_color if target_in_sight else idle_color
	var arc_points: PackedVector2Array = [Vector2.ZERO]
	var steps := 24
	var start_ang := -deg_to_rad(half_angle_degrees)
	var end_ang := deg_to_rad(half_angle_degrees)

	for i in range(steps + 1):
		var ang := lerpf(start_ang, end_ang, float(i) / float(steps))
		arc_points.append(Vector2(cos(ang), sin(ang)) * vision_range)

	draw_colored_polygon(arc_points, cone_color)
	draw_arc(Vector2.ZERO, vision_range, start_ang, end_ang, steps, Color(cone_color.r, cone_color.g, cone_color.b, 0.9), 1.5)
