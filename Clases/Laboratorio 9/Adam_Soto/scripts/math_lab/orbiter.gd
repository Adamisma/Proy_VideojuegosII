class_name Orbiter
extends Node2D

## ====================================================================
## Laboratorio 09 - Sección 10 & 25: Movimiento Orbital Paramétrico
## ====================================================================
## Implementa la cinemática de una órbita elíptica/circular mediante ecuaciones paramétricas:
##   x(θ) = c_x + r_x * cos(θ)
##   y(θ) = c_y + r_y * sin(θ)
## donde θ avanza de forma continua con velocidad angular: θ(t) = θ_0 + ω * t.

@export_category("Orbital Motion")
@export var center: Marker2D
@export_range(20.0, 400.0, 1.0) var radius_x: float = 175.0
@export_range(20.0, 400.0, 1.0) var radius_y: float = 85.0
@export var angular_speed: float = 1.2 ## Velocidad angular en radianes por segundo (ω)
@export var initial_phase: float = 0.0 ## Fase inicial en radianes (θ_0) para desfase de satélites (Reto 25)

@export_category("Visual Appearance")
@export var body_color: Color = Color("#EDAE49")
@export var ring_color: Color = Color("#183E64")
@export var body_radius: float = 13.0

var angle_radians: float = 0.0

func _ready() -> void:
	# Inicializar el ángulo con la fase inicial configurada
	angle_radians = initial_phase

func _physics_process(delta: float) -> void:
	if center == null:
		return

	# Fórmula: Integración angular independiente de la tasa de frames (FPS)
	# Δθ = ω * Δt; se normaliza en [0, TAU) usando wrapf para preservar precisión numérica
	angle_radians = wrapf(angle_radians + angular_speed * delta, 0.0, TAU)

	# Ecuación paramétrica de la elipse centrada en 'center.global_position'
	# Radio mayor / menor controlan la excentricidad; si radius_x == radius_y, es una circunferencia perfecta.
	global_position = center.global_position + Vector2(
		cos(angle_radians) * radius_x,
		sin(angle_radians) * radius_y
	)

func _draw() -> void:
	# Renderizado procedimental vectorial sin dependencia de assets externos
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius + 3.0, 0.0, TAU, 32, ring_color, 2.0)
