extends Node2D

## ====================================================================
## Laboratorio 09 - Sección 15 & 25: MathLab - Controlador Integrador
## ====================================================================
## Orquesta la simulación matemática interactiva en 2D:
## 1. Movimiento Orbital con 3 Satélites desfasados (θ_0 = 0°, 120°, 240°).
## 2. Movimiento Periódico Senoidal (WaveTrap).
## 3. Disparo Balístico Analítico hacia el cursor con protección de vector nulo.
## 4. Dos modos de gravedad seleccionables (Normal = 900 px/s², Baja/Lunar = 300 px/s²).
## 5. Visualizador predictivo de trayectoria parabólica (Line2D) conmutable (P).
## 6. Sacudida de cámara matemática exponencial multionda (Espacio).
## 7. Detección angular por Producto Punto en cono de visión (Sentinel FOV).

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/math_lab/ballistic_projectile.tscn")

@export_category("Ballistics")
@export var projectile_speed: float = 550.0 ## Rapidez escalar inicial del proyectil (px/s)
@export var gravity_normal: float = 900.0 ## Aceleración gravitatoria normal (px/s²)
@export var gravity_low: float = 300.0 ## Aceleración gravitatoria baja / lunar (px/s²)
@export var show_trajectory: bool = true ## Interruptor de visualización predictiva

@onready var launch_point: Marker2D = $LaunchPoint
@onready var game_camera: MathCamera = $Camera2D
@onready var orbit_center: Marker2D = $OrbitCenter
@onready var trajectory_line: Line2D = $TrajectoryLine
@onready var sentinel: FOVSentinel = $FOVSentinel
@onready var wave_trap: WaveTrap = $WaveTrap
@onready var telemetry_label: Label = $CanvasLayer/HUDPanel/TelemetryLabel
@onready var help_label: Label = $CanvasLayer/HelpLabel

var current_gravity: float = 900.0
var gravity_is_low: bool = false

func _ready() -> void:
	current_gravity = gravity_normal
	if trajectory_line:
		trajectory_line.visible = show_trajectory
	_update_telemetry()

func _unhandled_input(event: InputEvent) -> void:
	# Disparo balístico con botón izquierdo del mouse (Sección 14 y 15)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_fire_projectile()

	elif event is InputEventKey and event.pressed and not event.echo:
		# Espacio: Sacudida matemática de cámara (Sección 16)
		if event.keycode == KEY_SPACE:
			game_camera.trigger_shake(9.0)

		# Tecla G: Alternar gravedad entre Normal y Baja (Reto 25)
		elif event.keycode == KEY_G:
			gravity_is_low = not gravity_is_low
			current_gravity = gravity_low if gravity_is_low else gravity_normal
			_update_telemetry()

		# Tecla P: Alternar visualización de trayectoria (Reto 25)
		elif event.keycode == KEY_P:
			show_trajectory = not show_trajectory
			if trajectory_line:
				trajectory_line.visible = show_trajectory
			_update_telemetry()

		# Tecla R: Reiniciar laboratorio
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _physics_process(_delta: float) -> void:
	_update_trajectory_prediction()
	_update_telemetry()

## Dispara un proyectil con cálculo analítico hacia el mouse (Sección 14)
func _fire_projectile() -> void:
	var from_position: Vector2 = launch_point.global_position
	var target: Vector2 = get_global_mouse_position()
	var difference: Vector2 = target - from_position

	# Regla crítica: Comprobar que no sea vector nulo antes de normalizar
	if difference.length_squared() < 0.0001:
		return

	# Vector unitario de dirección por normalización: u = v / |v|
	var direction: Vector2 = difference.normalized()

	# Velocidad inicial: v_0 = direction * speed
	var initial_vel: Vector2 = direction * projectile_speed

	var projectile := PROJECTILE_SCENE.instantiate() as BallisticProjectile
	add_child(projectile)
	projectile.launch(
		from_position,
		initial_vel,
		Vector2(0.0, current_gravity)
	)

## Calcula en tiempo real los puntos de la parábola analítica para la línea predictiva (Reto 25)
func _update_trajectory_prediction() -> void:
	if not show_trajectory or trajectory_line == null:
		return

	var from_position: Vector2 = launch_point.global_position
	var target: Vector2 = get_global_mouse_position()
	var difference: Vector2 = target - from_position

	if difference.length_squared() < 0.0001:
		trajectory_line.clear_points()
		return

	var direction: Vector2 = difference.normalized()
	var v0: Vector2 = direction * projectile_speed
	var g_vec: Vector2 = Vector2(0.0, current_gravity)

	trajectory_line.clear_points()
	var steps := 32
	var total_time := 2.2 # segundos predichos en el trazador

	for i in range(steps + 1):
		var t := (float(i) / float(steps)) * total_time
		# Ecuación analítica de la trayectoria: p(t) = p_0 + v_0 * t + 0.5 * a * t²
		var pt := from_position + (v0 * t) + (0.5 * g_vec * (t * t))
		trajectory_line.add_point(pt)

func _update_telemetry() -> void:
	if telemetry_label == null:
		return

	var fov_status := "OBJETIVO EN CONO (!)" if (sentinel and sentinel.target_in_sight) else "DESPEJADO"
	var dot_val := sentinel.last_calculated_dot if sentinel else 0.0
	var thres_val := sentinel.threshold_cos if sentinel else 0.0

	var text := "=== TELEMETRÍA MATEMÁTICA EN TIEMPO REAL ===\n"
	text += "Gravedad: %.0f px/s² (%s) [Presiona 'G' para cambiar]\n" % [
		current_gravity,
		"BAJA/LUNAR" if gravity_is_low else "ESTÁNDAR"
	]
	text += "Predictor de Trayectoria: %s [Presiona 'P' para alternar]\n" % ["VISIBLE (ON)" if show_trajectory else "OCULTO (OFF)"]
	text += "Shake de Cámara: %.2f px (Frecuencias: 22 / 31 rad/s)\n" % game_camera.shake_strength
	text += "Centinela FOV: [%s] | Dot(look, toward): %.3f (Umbral: %.3f)\n" % [
		fov_status,
		dot_val,
		thres_val
	]
	text += "WaveTrap (MAS): Y: %.1f px | Avance X: %.1f px\n" % [
		(wave_trap.global_position.y - wave_trap.origin.y) if wave_trap else 0.0,
		(wave_trap.global_position.x - wave_trap.origin.x) if wave_trap else 0.0
	]

	telemetry_label.text = text
