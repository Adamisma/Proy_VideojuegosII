extends CharacterBody2D

## ====================================================================
## Laboratorio 07: IA de Enemigos y Máquinas de Estados (FSM)
## ====================================================================
## Arquitectura en tres capas (Sección 5):
## 1. Percepción: Area2D (rango), RayCast2D (SightRay, FloorRay, WallRay)
## 2. Decisión: FSM con prioridades y temporizadores (Secciones 6, 7, 36, 37)
## 3. Acción: velocity, AnimatedSprite2D, HitboxComponent y señales

# --- ENUM DE ESTADOS DE LA IA (Sección 6 y 12) ---
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	RETURN,
	DEAD
}

# --- CONFIGURACIÓN DE PATRULLAJE (Sección 11) ---
@export_category("Architecture")
@export var stats: CharacterStats

@export_category("Patrol")
@export var patrol_point_a: Marker2D
@export var patrol_point_b: Marker2D
@export var patrol_speed: float = 90.0
@export var patrol_tolerance: float = 8.0

# --- CONFIGURACIÓN DE MOVIMIENTO Y FÍSICA (Sección 17) ---
@export_category("Movement")
@export var chase_speed: float = 150.0
@export var return_speed: float = 110.0
@export var gravity: float = 1500.0
@export var return_tolerance: float = 10.0
@export var hurt_knockback: float = 220.0

# --- TEMPORIZADORES DE IA (Sección 37) ---
@export_category("Timers")
@export var idle_duration: float = 0.8
@export var lost_sight_grace_time: float = 0.75
@export var attack_cooldown: float = 1.0
@export var hurt_duration: float = 0.25

# --- REFERENCIAS A SENSORES Y COMPONENTES (Sección 8 y 13) ---
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_range: Area2D = $AttackRange
@onready var sight_ray: RayCast2D = $SightRay
@onready var floor_ahead_ray: RayCast2D = $FloorAheadRay
@onready var wall_ahead_ray: RayCast2D = $WallAheadRay

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var state_label: Label = $StateDebugLabel
@onready var alert_label: Label = $Visuals/AlertLabel
@onready var health_bar: ProgressBar = $OverheadHUD/HealthBar

# --- VARIABLES DE ESTADO Y MEMORIA ---
var current_state: EnemyState = EnemyState.IDLE
var current_patrol_target: Marker2D = null
var home_position: Vector2

var player: CharacterBody2D = null
var last_known_player_position: Vector2
var player_in_detection_area: bool = false
var player_in_attack_range: bool = false

var idle_time_left: float = 0.0
var lost_sight_time_left: float = 0.0
var attack_cooldown_left: float = 0.0
var hurt_time_left: float = 0.0

func _ready() -> void:
	if stats != null:
		health.configure_from_stats(stats)

	home_position = global_position
	current_patrol_target = patrol_point_b if patrol_point_b else patrol_point_a

	# Conexión de sensores de percepción (Sección 13 y 14)
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_range.body_entered.connect(_on_attack_range_body_entered)
	attack_range.body_exited.connect(_on_attack_range_body_exited)

	# Conexión de componentes de combate (Sección 26 y 29)
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	if health_bar:
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health

	if alert_label:
		alert_label.visible = false

	# Conectar animación terminada para ataques y daño
	animated_sprite.animation_finished.connect(_on_animation_finished)

	_enter_state(current_state)

# ====================================================================
# BUCLE CENTRAL DE FÍSICA Y ORQUESTACIÓN (Sección 30)
# ====================================================================
func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		_update_dead(delta)
		return

	_apply_gravity(delta)
	_update_perception(delta)
	_update_attack_cooldown(delta)

	# Orquestación de la FSM (Sección 30)
	match current_state:
		EnemyState.IDLE:
			_update_idle(delta)
		EnemyState.PATROL:
			_update_patrol(delta)
		EnemyState.CHASE:
			_update_chase(delta)
		EnemyState.ATTACK:
			_update_attack(delta)
		EnemyState.HURT:
			_update_hurt(delta)
		EnemyState.RETURN:
			_update_return(delta)

	move_and_slide()
	_update_debug_label()

# ====================================================================
# FSM: TRANSICIONES Y ACCIONES DE ENTRADA / SALIDA (Sección 12 y 31)
# ====================================================================
func _change_state(new_state: EnemyState) -> void:
	if new_state == current_state and current_state != EnemyState.IDLE:
		return

	_exit_state(current_state)
	current_state = new_state
	_enter_state(current_state)

func _enter_state(state: EnemyState) -> void:
	match state:
		EnemyState.IDLE:
			_enter_idle()
		EnemyState.PATROL:
			_enter_patrol()
		EnemyState.CHASE:
			_enter_chase()
		EnemyState.ATTACK:
			_enter_attack()
		EnemyState.HURT:
			_enter_hurt()
		EnemyState.RETURN:
			_enter_return()
		EnemyState.DEAD:
			_enter_dead()

func _exit_state(state: EnemyState) -> void:
	match state:
		EnemyState.ATTACK:
			hitbox.end_attack()
		_:
			pass

# ====================================================================
# ESTADO IDLE (Sección 19)
# ====================================================================
func _enter_idle() -> void:
	velocity.x = 0.0
	idle_time_left = idle_duration
	animated_sprite.play("idle")

func _update_idle(delta: float) -> void:
	idle_time_left -= delta

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	if idle_time_left <= 0.0:
		_change_state(EnemyState.PATROL)

# ====================================================================
# ESTADO PATROL (Sección 20)
# ====================================================================
func _enter_patrol() -> void:
	animated_sprite.play("walk")

func _update_patrol(_delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	if current_patrol_target == null:
		_change_state(EnemyState.IDLE)
		return

	_move_horizontally_toward(current_patrol_target.global_position.x, patrol_speed)

	# Evitar caer de plataformas o chocar muros (Sección 18)
	if _should_turn_around():
		_switch_patrol_target()
		return

	var distance_x := abs(global_position.x - current_patrol_target.global_position.x)
	if distance_x <= patrol_tolerance:
		_switch_patrol_target()
		_change_state(EnemyState.IDLE)

func _switch_patrol_target() -> void:
	if current_patrol_target == patrol_point_a:
		current_patrol_target = patrol_point_b
	else:
		current_patrol_target = patrol_point_a

# ====================================================================
# ESTADO CHASE (Sección 22)
# ====================================================================
func _enter_chase() -> void:
	animated_sprite.play("run")
	# Reto 42: Indicador visual de alerta (!)
	_trigger_alert_feedback()

func _update_chase(_delta: float) -> void:
	if player == null:
		_change_state(EnemyState.RETURN)
		return

	if _has_line_of_sight_to_player():
		last_known_player_position = player.global_position

	# Si está en rango y lo ve -> Atacar (Prioridad 3, Sección 36)
	if player_in_attack_range and _has_line_of_sight_to_player():
		_change_state(EnemyState.ATTACK)
		return

	# Si se perdió de vista y expiró el tiempo de memoria -> Regresar (Prioridad 5)
	if lost_sight_time_left <= 0.0:
		_change_state(EnemyState.RETURN)
		return

	# Perseguir hacia la última posición conocida
	_move_horizontally_toward(last_known_player_position.x, chase_speed)

# ====================================================================
# ESTADO ATTACK (Sección 24 y 25)
# ====================================================================
func _enter_attack() -> void:
	velocity.x = 0.0
	_start_attack()

func _update_attack(_delta: float) -> void:
	if player == null:
		_change_state(EnemyState.RETURN)
		return

	if not player_in_attack_range:
		_change_state(EnemyState.CHASE)
		return

	if attack_cooldown_left <= 0.0:
		_start_attack()

func _start_attack() -> void:
	attack_cooldown_left = attack_cooldown
	hitbox.begin_attack()
	animated_sprite.play("attack")

# ====================================================================
# ESTADO HURT (Sección 26 y 27)
# ====================================================================
func _enter_hurt() -> void:
	hitbox.end_attack()
	animated_sprite.play("hurt")

func _update_hurt(delta: float) -> void:
	hurt_time_left -= delta
	if hurt_time_left > 0.0:
		return

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
	else:
		_change_state(EnemyState.RETURN)

func _on_hit_received(attack: AttackData, direction: Vector2) -> void:
	if current_state == EnemyState.DEAD:
		return

	hurt_time_left = hurt_duration
	# Aplicar Knockback horizontal (Sección 27)
	velocity.x = direction.x * hurt_knockback
	_change_state(EnemyState.HURT)

# ====================================================================
# ESTADO RETURN (Sección 28)
# ====================================================================
func _enter_return() -> void:
	animated_sprite.play("walk")

func _update_return(_delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	_move_horizontally_toward(home_position.x, return_speed)

	if abs(global_position.x - home_position.x) <= return_tolerance:
		velocity.x = 0.0
		_change_state(EnemyState.IDLE)

# ====================================================================
# ESTADO DEAD (Sección 29)
# ====================================================================
func _on_died() -> void:
	_change_state(EnemyState.DEAD)

func _enter_dead() -> void:
	velocity = Vector2.ZERO
	detection_area.set_deferred("monitoring", false)
	attack_range.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)

	animated_sprite.play("dead")

	# Desvanecer y eliminar diferidamente tras observar la muerte
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(visuals, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _update_dead(_delta: float) -> void:
	pass

# ====================================================================
# PERCEPCIÓN: LÍNEA DE VISIÓN Y SENSORES (Secciones 14, 15, 16 y 18)
# ====================================================================
func _has_line_of_sight_to_player() -> bool:
	if player == null or not player_in_detection_area:
		return false

	sight_ray.target_position = sight_ray.to_local(player.global_position)
	sight_ray.force_raycast_update()

	if not sight_ray.is_colliding():
		return false

	return sight_ray.get_collider() == player

func _update_perception(delta: float) -> void:
	if _has_line_of_sight_to_player():
		last_known_player_position = player.global_position
		lost_sight_time_left = lost_sight_grace_time
	else:
		lost_sight_time_left = max(lost_sight_time_left - delta, 0.0)

func _can_start_chase() -> bool:
	return player != null and player_in_detection_area and _has_line_of_sight_to_player()

func _should_turn_around() -> bool:
	return not floor_ahead_ray.is_colliding() or wall_ahead_ray.is_colliding()

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body as CharacterBody2D
		player_in_detection_area = true

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_detection_area = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body == player or body.is_in_group("player"):
		player_in_attack_range = true

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = false

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		hitbox.end_attack()
		if player_in_attack_range and _has_line_of_sight_to_player():
			# Esperar cooldown en reposo o continuar
			pass
		else:
			_change_state(EnemyState.CHASE)

# ====================================================================
# ORIENTACIÓN VISUAL Y SENSORES DIRECCIONALES (Sección 32)
# ====================================================================
func _move_horizontally_toward(target_x: float, speed: float) -> void:
	var direction := sign(target_x - global_position.x)
	velocity.x = direction * speed
	_update_facing(direction)

func _update_facing(direction: float) -> void:
	if direction == 0.0:
		return

	var facing_left := direction < 0.0
	animated_sprite.flip_h = facing_left

	var sensor_sign := -1.0 if facing_left else 1.0
	wall_ahead_ray.target_position.x = abs(wall_ahead_ray.target_position.x) * sensor_sign
	floor_ahead_ray.position.x = abs(floor_ahead_ray.position.x) * sensor_sign
	hitbox.position.x = abs(hitbox.position.x) * sensor_sign

# ====================================================================
# AUXILIARES, TIMERS Y DEPURACIÓN (Sección 33 y 37)
# ====================================================================
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_attack_cooldown(delta: float) -> void:
	attack_cooldown_left = max(attack_cooldown_left - delta, 0.0)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

func _trigger_alert_feedback() -> void:
	if alert_label:
		alert_label.visible = true
		alert_label.modulate = Color(1.0, 0.9, 0.2, 1.0)
		var tween := alert_label.create_tween()
		tween.tween_property(alert_label, "position:y", alert_label.position.y - 10.0, 0.4)
		tween.parallel().tween_property(alert_label, "modulate:a", 0.0, 0.4)
		tween.tween_callback(func(): alert_label.visible = false; alert_label.position.y += 10.0)

func _update_debug_label() -> void:
	if not state_label:
		return

	state_label.text = EnemyState.keys()[current_state]

	match current_state:
		EnemyState.IDLE: state_label.modulate = Color("#80d8ff")
		EnemyState.PATROL: state_label.modulate = Color("#ffffff")
		EnemyState.CHASE: state_label.modulate = Color("#ffab40")
		EnemyState.ATTACK: state_label.modulate = Color("#ff5252")
		EnemyState.HURT: state_label.modulate = Color("#b388ff")
		EnemyState.RETURN: state_label.modulate = Color("#69f0ae")
		EnemyState.DEAD: state_label.modulate = Color("#9e9e9e")
