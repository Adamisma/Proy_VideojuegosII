extends CharacterBody2D
class_name EnemyNavigator

## ====================================================================
## Laboratorio 08: Navegación, Pathfinding y Comportamientos Inteligentes
## ====================================================================
## Implementación completa de EnemyNavigator combinando:
## 1. Percepción: DetectionArea (proximidad) y SightRay (línea de visión).
## 2. Decisión: Máquina de Estados Finita (FSM) con IDLE, PATROL, CHASE, ATTACK, HURT, FLEE, RETURN, DEAD.
## 3. Navegación: NavigationAgent2D para cálculo y seguimiento de ruta en NavMesh 2D.
## 4. Evitación Local (Avoidance): RVO2 mediante velocity_computed para evitar colisiones entre agentes.
## 5. Steering Behaviours: Seek, Flee, Arrive y Wander integrados suavemente.
## 6. Retos de Ampliación: Evasión con vida baja (FLEE), línea visual de debug de ruta y NavigationLink2D.

# --- ENUM DE ESTADOS DE LA FSM (Sección 32) ---
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	FLEE,
	RETURN,
	DEAD
}

# --- CONFIGURACIÓN DE NAVEGACIÓN (Sección 11 y 17) ---
@export_category("Navigation")
@export var navigation_speed: float = 130.0
@export var target_refresh_interval: float = 0.20
@export var path_desired_distance: float = 12.0
@export var target_desired_distance: float = 18.0
@export var avoidance_enabled: bool = true

# --- COMPORTAMIENTOS Y STEERING (Secciones 26-32) ---
@export_category("Behaviour")
@export var flee_health_ratio: float = 0.30
@export var flee_distance: float = 240.0
@export var arrive_slowing_radius: float = 90.0
@export var wander_speed: float = 75.0
@export var wander_angle_change: float = 2.0
@export var attack_range_distance: float = 42.0
@export var lost_sight_grace_time: float = 1.2
@export var attack_cooldown: float = 1.0

# --- REFERENCIAS A NODOS INTERNOS ---
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var sight_ray: RayCast2D = $SightRay
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var debug_path_line: Line2D = $DebugPathLine
@onready var state_label: Label = $StateDebugLabel
@onready var alert_label: Label = $Visuals/AlertLabel
@onready var health_bar: ProgressBar = $OverheadHUD/HealthBar

# --- VARIABLES DE ESTADO Y MEMORIA ---
var current_state: EnemyState = EnemyState.IDLE
var player: CharacterBody2D = null
var home_position: Vector2
var navigation_target: Vector2
var has_navigation_target: bool = false

var target_refresh_left: float = 0.0
var state_timer: float = 0.0
var attack_cooldown_left: float = 0.0
var lost_sight_time_left: float = 0.0
var hurt_time_left: float = 0.0

var wander_angle: float = 0.0
var player_in_detection: bool = false
var is_fleeing_due_to_low_health: bool = false

func _ready() -> void:
	home_position = global_position
	wander_angle = randf_range(0.0, TAU)

	# Configuración inicial del NavigationAgent2D (Secciones 11-13 y 22)
	navigation_agent.max_speed = navigation_speed
	navigation_agent.path_desired_distance = path_desired_distance
	navigation_agent.target_desired_distance = target_desired_distance
	navigation_agent.avoidance_enabled = avoidance_enabled

	# Conexión de señales de navegación (Secciones 22 y 35)
	navigation_agent.velocity_computed.connect(_on_navigation_agent_velocity_computed)
	navigation_agent.link_reached.connect(_on_navigation_link_reached)

	# Sensores de percepción
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)

	# Componentes de combate
	if health:
		health.health_changed.connect(_on_health_changed)
		health.damaged.connect(_on_damaged)
		health.died.connect(_on_died)
		if health_bar:
			health_bar.max_value = health.max_health
			health_bar.value = health.current_health

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	_update_debug_ui()

	# Sección 13: Esperar un frame de física para sincronizar el NavigationServer
	await get_tree().physics_frame
	_change_state(EnemyState.PATROL)

func _physics_process(delta: float) -> void:
	# Actualización de temporizadores de enfriamiento
	if attack_cooldown_left > 0.0:
		attack_cooldown_left -= delta
	if state_timer > 0.0:
		state_timer -= delta

	# Evaluación de percepción continua (RayCast hacia el jugador)
	_process_perception(delta)

	# Ejecución de la lógica de estado activa
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
		EnemyState.FLEE:
			_update_flee(delta)
		EnemyState.RETURN:
			_update_return(delta)
		EnemyState.DEAD:
			velocity = Vector2.ZERO

	# Orientación visual según movimiento
	_update_facing()

	# Reto 44: Dibujo de ruta de navegación en pantalla
	_render_debug_path()
	_update_debug_ui()

# ====================================================================
# PERCEPCIÓN Y VISIBILIDAD (Sección 3 y Semana 7)
# ====================================================================
func _process_perception(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	if player_in_detection:
		sight_ray.target_position = sight_ray.to_local(player.global_position)
		sight_ray.force_raycast_update()

		if not sight_ray.is_colliding() or sight_ray.get_collider() == player:
			lost_sight_time_left = lost_sight_grace_time
		else:
			if lost_sight_time_left > 0.0:
				lost_sight_time_left -= delta
	else:
		if lost_sight_time_left > 0.0:
			lost_sight_time_left -= delta

func _has_line_of_sight_to_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	sight_ray.target_position = sight_ray.to_local(player.global_position)
	sight_ray.force_raycast_update()
	return not sight_ray.is_colliding() or sight_ray.get_collider() == player

# ====================================================================
# MÁQUINA DE ESTADOS FINITA (FSM) - Secciones 18, 19, 32
# ====================================================================
func _change_state(new_state: EnemyState) -> void:
	if current_state == new_state or current_state == EnemyState.DEAD:
		return

	# Salida del estado anterior
	match current_state:
		EnemyState.ATTACK:
			if hitbox:
				hitbox.end_attack()

	current_state = new_state

	# Entrada al nuevo estado
	match current_state:
		EnemyState.IDLE:
			animated_sprite.play("idle")
			state_timer = randf_range(1.0, 2.0)
			velocity = Vector2.ZERO
		EnemyState.PATROL:
			animated_sprite.play("walk")
			state_timer = randf_range(3.0, 5.0)
		EnemyState.CHASE:
			animated_sprite.play("run")
			if alert_label:
				_show_alert("!")
			target_refresh_left = 0.0
			if player != null:
				set_navigation_target(player.global_position)
		EnemyState.ATTACK:
			animated_sprite.play("attack")
			velocity = Vector2.ZERO
			state_timer = 0.4
			if hitbox:
				hitbox.begin_attack()
		EnemyState.HURT:
			animated_sprite.play("hurt")
			hurt_time_left = 0.25
		EnemyState.FLEE:
			animated_sprite.play("run")
			if alert_label:
				_show_alert("?!")
			target_refresh_left = 0.0
		EnemyState.RETURN:
			animated_sprite.play("walk")
			set_navigation_target(home_position)
		EnemyState.DEAD:
			animated_sprite.play("dead")
			velocity = Vector2.ZERO
			if hitbox:
				hitbox.end_attack()
			if hurtbox:
				hurtbox.set_deferred("monitoring", false)
				hurtbox.set_deferred("monitorable", false)
			collision_layer = 0
			collision_mask = 0

# --- LÓGICA POR ESTADO ---
func _update_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	if state_timer <= 0.0:
		_change_state(EnemyState.PATROL)

func _update_patrol(delta: float) -> void:
	if _can_start_chase():
		_change_state(EnemyState.CHASE)
		return

	# Deambulación orgánica suave (Wander - Sección 30)
	var desired: Vector2 = wander(delta)
	velocity = desired
	move_and_slide()

	if state_timer <= 0.0:
		_change_state(EnemyState.IDLE)

func _update_chase(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_change_state(EnemyState.RETURN)
		return

	# Reto 44: Enemigo con baja vida entra en FLEE
	if _should_flee():
		_change_state(EnemyState.FLEE)
		return

	var dist_to_player: float = global_position.distance_to(player.global_position)

	# Transición a ATTACK si está dentro del radio de golpe y tiene línea de visión
	if dist_to_player <= attack_range_distance and _has_line_of_sight_to_player() and attack_cooldown_left <= 0.0:
		_change_state(EnemyState.ATTACK)
		return

	# Pérdida de objetivo (fuera de detección y tiempo de gracia agotado)
	if not player_in_detection and lost_sight_time_left <= 0.0:
		_change_state(EnemyState.RETURN)
		return

	# Actualización periódica de la ruta calculada (Sección 17)
	_update_target_to_player(delta)
	_follow_navigation_path()

func _update_attack(_delta: float) -> void:
	# El ataque concluye al agotar su temporizador de animación
	if state_timer <= 0.0:
		if hitbox:
			hitbox.end_attack()
		attack_cooldown_left = attack_cooldown

		if _should_flee():
			_change_state(EnemyState.FLEE)
		elif _can_start_chase():
			_change_state(EnemyState.CHASE)
		else:
			_change_state(EnemyState.RETURN)

func _update_hurt(delta: float) -> void:
	hurt_time_left -= delta
	move_and_slide()
	if hurt_time_left <= 0.0:
		if _should_flee():
			_change_state(EnemyState.FLEE)
		elif _can_start_chase():
			_change_state(EnemyState.CHASE)
		else:
			_change_state(EnemyState.IDLE)

func _update_flee(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_change_state(EnemyState.RETURN)
		return

	# Si ya escapó a una distancia segura (> 350 px), puede intentar regresar a IDLE o patrulla
	var dist_to_player: float = global_position.distance_to(player.global_position)
	if dist_to_player > 360.0 and not is_fleeing_due_to_low_health:
		_change_state(EnemyState.RETURN)
		return

	# Cálculo de objetivo de huida en dirección opuesta (Sección 32)
	target_refresh_left -= delta
	if target_refresh_left <= 0.0:
		target_refresh_left = target_refresh_interval
		var escape_direction: Vector2 = player.global_position.direction_to(global_position)
		var escape_target: Vector2 = global_position + escape_direction * flee_distance
		set_navigation_target(escape_target)

	_follow_navigation_path()

func _update_return(_delta: float) -> void:
	if _can_start_chase() and not _should_flee():
		_change_state(EnemyState.CHASE)
		return

	_follow_navigation_path()

	if navigation_agent.is_navigation_finished() or global_position.distance_to(home_position) < target_desired_distance:
		velocity = Vector2.ZERO
		_change_state(EnemyState.IDLE)

func _can_start_chase() -> bool:
	if _should_flee():
		return false
	if player != null and is_instance_valid(player):
		return player_in_detection or lost_sight_time_left > 0.0
	return false

func _should_flee() -> bool:
	if health:
		return (health.current_health / health.max_health) <= flee_health_ratio
	return false

# ====================================================================
# NAVEGACIÓN Y SEGUIMIENTO DE RUTA (Secciones 14-16 y 23-24)
# ====================================================================
func set_navigation_target(target_pos: Vector2) -> void:
	navigation_target = target_pos
	navigation_agent.target_position = target_pos
	has_navigation_target = true

func _get_navigation_direction() -> Vector2:
	if navigation_agent.is_navigation_finished():
		return Vector2.ZERO
	var next_path_pos: Vector2 = navigation_agent.get_next_path_position()
	return global_position.direction_to(next_path_pos)

func _follow_navigation_path() -> void:
	if not has_navigation_target or navigation_agent.is_navigation_finished():
		if navigation_agent.avoidance_enabled:
			navigation_agent.velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO
			move_and_slide()
		return

	var direction: Vector2 = _get_navigation_direction()
	var desired_velocity: Vector2 = direction * navigation_speed

	# Si avoidance está activado, se solicita la velocidad segura al NavigationServer (Sección 23-24)
	if navigation_agent.avoidance_enabled:
		navigation_agent.velocity = desired_velocity
	else:
		velocity = desired_velocity
		move_and_slide()

## Callback de avoidance: El NavigationServer calcula 'safe_velocity' resolviendo agentes cercanos
func _on_navigation_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if not navigation_agent.avoidance_enabled:
		return
	if current_state == EnemyState.DEAD or current_state == EnemyState.ATTACK:
		velocity = Vector2.ZERO
		return
	velocity = safe_velocity
	move_and_slide()

func _update_target_to_player(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	target_refresh_left -= delta
	if target_refresh_left <= 0.0:
		target_refresh_left = target_refresh_interval
		set_navigation_target(player.global_position)

# ====================================================================
# RETO 44 & SECCIONES 34-35: ENLACES ESPECIALES (NavigationLink2D)
# ====================================================================
func _on_navigation_link_reached(details: Dictionary) -> void:
	var link_owner = details.get("owner", null)
	if link_owner != null:
		# Feedback visual y lógica especial (salto, teletransporte, etc.)
		_show_alert("LINK!")
		# Desplazamiento instantáneo o aceleración hacia el extremo del enlace
		var link_target: Vector2 = details.get("link_exit_position", global_position)
		if link_target != Vector2.ZERO:
			global_position = link_target

# ====================================================================
# STEERING BEHAVIOURS DIRECTOS (Secciones 26-31)
# ====================================================================
func seek(target_pos: Vector2, speed: float) -> Vector2:
	return global_position.direction_to(target_pos) * speed

func flee(threat_pos: Vector2, speed: float) -> Vector2:
	return threat_pos.direction_to(global_position) * speed

func arrive(target_pos: Vector2, max_spd: float, slowing_rad: float) -> Vector2:
	var to_target: Vector2 = target_pos - global_position
	var distance: float = to_target.length()
	if distance <= 0.001:
		return Vector2.ZERO
	var speed_factor: float = minf(distance / maxf(slowing_rad, 0.001), 1.0)
	return to_target.normalized() * max_spd * speed_factor

func wander(delta: float) -> Vector2:
	wander_angle += randf_range(-wander_angle_change, wander_angle_change) * delta
	return Vector2.from_angle(wander_angle) * wander_speed

# ====================================================================
# ORIENTACIÓN, DETECCIÓN Y COMBATE
# ====================================================================
func _update_facing() -> void:
	if abs(velocity.x) > 5.0:
		visuals.scale.x = -1.0 if velocity.x < 0.0 else 1.0

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player = body as CharacterBody2D
		player_in_detection = true
		lost_sight_time_left = lost_sight_grace_time
		if current_state != EnemyState.DEAD and current_state != EnemyState.HURT:
			if _should_flee():
				_change_state(EnemyState.FLEE)
			else:
				_change_state(EnemyState.CHASE)

func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_detection = false

func _on_hit_received(_attack: AttackData, hit_direction: Vector2) -> void:
	if current_state == EnemyState.DEAD:
		return
	velocity = hit_direction * 160.0
	_change_state(EnemyState.HURT)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.value = current
	if current / maximum <= flee_health_ratio and not is_fleeing_due_to_low_health:
		is_fleeing_due_to_low_health = true
		if current_state != EnemyState.DEAD:
			_change_state(EnemyState.FLEE)

func _on_damaged(_amount: float) -> void:
	# Flash visual de impacto
	var tween := create_tween()
	tween.tween_property(visuals, "modulate", Color(1.0, 0.2, 0.2), 0.08)
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.12)

func _on_died() -> void:
	_change_state(EnemyState.DEAD)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.2)
	await tween.finished
	queue_free()

func _show_alert(text: String) -> void:
	if alert_label:
		alert_label.text = text
		alert_label.visible = true
		var tween := create_tween()
		tween.tween_interval(0.8)
		tween.tween_callback(func(): alert_label.visible = false)

# ====================================================================
# INSTRUMENTACIÓN Y DEPURACIÓN VISUAL (Sección 40 y Reto 44)
# ====================================================================
func _render_debug_path() -> void:
	if debug_path_line == null:
		return
	if current_state == EnemyState.DEAD or navigation_agent.is_navigation_finished():
		debug_path_line.clear_points()
		return

	var current_path: PackedVector2Array = navigation_agent.get_current_navigation_path()
	if current_path.size() < 2:
		debug_path_line.clear_points()
		return

	debug_path_line.clear_points()
	for pt in current_path:
		debug_path_line.add_point(to_local(pt))

func _update_debug_ui() -> void:
	if state_label:
		var state_name: String = EnemyState.keys()[current_state]
		var dist: float = navigation_agent.distance_to_target() if has_navigation_target else 0.0
		var avoidance_str: String = "ON" if navigation_agent.avoidance_enabled else "OFF"
		state_label.text = "%s | D:%.0f | RVO:%s" % [state_name, dist, avoidance_str]

## Método público para conmutar avoidance en tiempo de ejecución (Demostración de QA)
func toggle_avoidance(enabled: bool) -> void:
	avoidance_enabled = enabled
	navigation_agent.avoidance_enabled = enabled
	_update_debug_ui()
