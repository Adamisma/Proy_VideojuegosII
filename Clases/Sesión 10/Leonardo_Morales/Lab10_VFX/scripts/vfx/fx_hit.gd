extends Node2D
class_name FXHit

## ====================================================================
## Laboratorio 10 - Sección 20 & 31: Efecto Compuesto FX_Hit
## ====================================================================
## Agrupa chispas, fragmentos (debris) y un destello de luz dinámica (PointLight2D).
## Controla la animación lumínica mediante Tween y se autodestruye al terminar.
## Reto 41: Soporta modo crítico con chispas ampliadas y destello cromático potenciado.

@export var is_critical: bool = false

@onready var sparks: GPUParticles2D = $Sparks
@onready var debris: GPUParticles2D = $Debris
@onready var flash_light: PointLight2D = $FlashLight

func _ready() -> void:
	if is_critical:
		_setup_critical()

	# Iniciar emisiones one-shot
	if sparks:
		sparks.restart()
	if debris:
		debris.restart()

	# Sección 20: Flash de luz en impactos
	_play_light_flash()

func _setup_critical() -> void:
	if flash_light:
		flash_light.color = Color(0.3, 0.85, 1.0) # Destello azul/cian para crítico
	if sparks:
		sparks.amount = 40
		sparks.lifetime = 0.45

func _play_light_flash() -> void:
	if flash_light == null:
		return

	flash_light.energy = 0.0
	flash_light.visible = true

	var peak_energy: float = 3.2 if is_critical else 2.2
	var tween := create_tween()
	
	# Entrada rápida de energía
	tween.tween_property(
		flash_light,
		"energy",
		peak_energy,
		0.04
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Salida rápida disipativa
	tween.tween_property(
		flash_light,
		"energy",
		0.0,
		0.14
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_callback(func(): flash_light.visible = false)

	# Programar autodestrucción segura al concluir el ciclo más largo
	var max_lifetime: float = maxf(sparks.lifetime if sparks else 0.35, debris.lifetime if debris else 0.4)
	get_tree().create_timer(max_lifetime + 0.1, false).timeout.connect(queue_free)

func orient_to_direction(direction: Vector2) -> void:
	if direction.length_squared() > 0.0001:
		rotation = direction.angle()
