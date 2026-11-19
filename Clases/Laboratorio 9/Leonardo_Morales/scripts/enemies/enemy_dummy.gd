extends CharacterBody2D

## ====================================================================
## Laboratorio 06 - Sección 17 & Reto 33: EnemyDummy
## ====================================================================
## Objetivo de pruebas que recibe daño, knockback y muere.
## Demuestra el principio de composición: reutiliza HealthComponent y HurtboxComponent.

@export var gravity: float = 1200.0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var health_bar: ProgressBar = $OverheadHUD/HealthBar

var is_dead: bool = false

func _ready() -> void:
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	if health_bar:
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Fricción para desacelerar tras recibir knockback
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	move_and_slide()

func _on_hit_received(attack: AttackData, direction: Vector2) -> void:
	if is_dead:
		return

	# Aplicar Knockback según dirección del impacto (Sección 18)
	velocity = direction * attack.knockback_force

	# Flash rojizo en el sprite
	var tween := visuals.create_tween()
	visuals.modulate = Color(1.0, 0.2, 0.2, 1.0)
	tween.tween_property(visuals, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func _on_died() -> void:
	is_dead = true
	# Desactivar colisiones y físicas
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("HurtboxComponent/CollisionShape2D"):
		$HurtboxComponent/CollisionShape2D.set_deferred("disabled", true)

	# Animación de muerte mediante rotación y desvanecimiento
	var tween := create_tween()
	tween.parallel().tween_property(visuals, "rotation_degrees", 90.0, 0.3)
	tween.parallel().tween_property(visuals, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free)
