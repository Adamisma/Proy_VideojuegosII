extends CharacterBody2D
class_name PlayerTopDown

## ====================================================================
## Laboratorio 08 - Sección 7: Player Móvil en Vista Top-Down
## ====================================================================
## Controlador 2D omnidireccional diseñado para la arena de navegación.
## Permite al usuario desplazarse con libertad por el NavMesh y ejecutar ataques
## ofensivos para probar la reacción de los agentes (CHASE, FLEE, Avoidance).

@export_category("Movement")
@export var move_speed: float = 200.0

@export_category("Combat")
@export var attack_duration: float = 0.35

@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

var is_attacking: bool = false
var attack_time_left: float = 0.0

func _ready() -> void:
	add_to_group("player")
	if health:
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

func _physics_process(delta: float) -> void:
	if is_attacking:
		attack_time_left -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		move_and_slide()
		if attack_time_left <= 0.0:
			_end_attack()
		return

	# Ataque al presionar la acción configurada (Espacio, J o Clic izquierdo)
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump"):
		_start_attack()
		return

	# Movimiento Top-Down en 8 direcciones
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * move_speed
		animated_sprite.play("run")
		# Orientación horizontal del sprite
		if abs(input_vector.x) > 0.01:
			visuals.scale.x = -1.0 if input_vector.x < 0.0 else 1.0
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle")

	move_and_slide()

func _start_attack() -> void:
	is_attacking = true
	attack_time_left = attack_duration
	animated_sprite.play("attack")
	if hitbox:
		hitbox.begin_attack()

func _end_attack() -> void:
	is_attacking = false
	if hitbox:
		hitbox.end_attack()
	animated_sprite.play("idle")

func _on_hit_received(_attack: AttackData, hit_direction: Vector2) -> void:
	# Ligero retroceso al recibir impacto
	velocity = hit_direction * 120.0
	var tween := create_tween()
	tween.tween_property(visuals, "modulate", Color(1.0, 0.3, 0.3), 0.08)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

func _on_damaged(_amount: float) -> void:
	pass

func _on_died() -> void:
	animated_sprite.play("dead")
	set_physics_process(false)
