class_name WaveTrap
extends Node2D

## ====================================================================
## Laboratorio 09 - Sección 11: Movimiento Periódico y Oscilación Senoidal
## ====================================================================
## Modela un peligro ondulante combinando:
## 1. Desplazamiento horizontal lineal periódico con reaparición (wrap modular).
## 2. Oscilación vertical armónica simple gobernada por una función senoidal:
##      y(t) = A * sin(2π * f * t) = amplitude * sin(TAU * frequency_hz * t)

@export_category("Wave Mechanics")
@export var amplitude: float = 65.0 ## Amplitud de oscilación vertical en píxeles (A: cresta/valle)
@export var frequency_hz: float = 1.1 ## Frecuencia en Hercios / ciclos completos por segundo (f)
@export var speed_x: float = 115.0 ## Rapidez de avance horizontal en px/s (v_x)
@export var travel_distance: float = 900.0 ## Distancia total de recorrido antes de reiniciar el ciclo (L)

@export_category("Visual Appearance")
@export var outer_color: Color = Color("#35A4AE")
@export var inner_color: Color = Color.WHITE

var elapsed: float = 0.0
var origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	origin = global_position

func _physics_process(delta: float) -> void:
	elapsed += delta

	# Fórmula: Posición horizontal periódica mediante envoltura modular flotante (fposmod)
	# x(t) = (v_x * t) mod L
	var distance_x: float = fposmod(speed_x * elapsed, travel_distance)

	# Fórmula: Movimiento Armónico Simple (MAS) vertical
	# y(t) = A * sin(2π * f * t). Nótese que multiplicar por TAU (2π) convierte frecuencia en Hz a rad/s.
	var wave_y: float = amplitude * sin(TAU * frequency_hz * elapsed)

	# Superposición del vector resultante sobre el punto de origen
	global_position = origin + Vector2(distance_x, wave_y)

func _draw() -> void:
	# Dibujo vectorial procedimental del objeto oscilante
	draw_circle(Vector2.ZERO, 11.0, outer_color)
	draw_circle(Vector2.ZERO, 4.0, inner_color)
