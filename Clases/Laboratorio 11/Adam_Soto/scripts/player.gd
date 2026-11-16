extends CharacterBody2D
class_name Player

## ====================================================================
## Laboratorio 11: Arquitectura Profesional y Sistemas Reutilizables
## ====================================================================
## Script refactorizado siguiendo los principios de Responsabilidad Única
## y Composición (Secciones 12, 14, 15, 17, 33 y 34 de la guía).
## - Delega cálculo de aceleración a MovementComponent.
## - Delega estado de salud y daño a HealthComponent.
## - Consume parámetros base desde el Custom Resource CharacterStats.
## - Consume configuración de armas desde WeaponData (Reto 43).
## - Emite eventos globales a EventBus sin conocer directamente la UI ni otros sistemas.

# --- SEÑALES LOCALES (Contratos jerárquicos) ---
signal player_died
signal respawn_requested
signal weapon_swapped(new_weapon: WeaponData)

# --- ESTADOS DE LA FSM (Semana 5 y 6) ---
enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	WALL_SLIDE,
	DASH,
	ATTACK,
	HURT,
	DEAD
}

# --- ARQUITECTURA & RECURSOS (Secciones 11, 12 y Reto 43) ---
@export_category("Architecture & Resources")
@export var stats: CharacterStats = preload("res://resources/stats/player_stats.tres")
@export var weapon: WeaponData = preload("res://resources/weapons/player_sword.tres")
@export var secondary_weapon: WeaponData = preload("res://resources/weapons/player_dagger.tres")

# --- CONFIGURACIÓN DE FÍSICAS AUXILIARES ---
@export_category("Jump")
@export var gravity: float = 1500.0
@export var jump_velocity: float = -520.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var jump_cut_multiplier: float = 0.45

@export_category("Wall")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_horizontal_speed: float = 320.0
@export var wall_jump_vertical_speed: float = -480.0

@export_category("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45

# --- REFERENCIAS A COMPONENTES Y NODOS (Sección 15) ---
@onready var movement: MovementComponent = $MovementComponent
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_origin: Node2D = $AttackOrigin
@onready var sword_hitbox: HitboxComponent = $AttackOrigin/SwordHitbox
@onready var state_label: Label = $DebugLayer/Margin/Panel/HBox/StateLabel
@onready var dash_trail: GPUParticles2D = get_node_or_null("Visuals/DashTrail")

const LAND_DUST_SCENE: PackedScene = preload("res://scenes/vfx/fx_land_dust.tscn")

# --- VARIABLES DE ESTADO ---
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var can_attack: bool = true
var facing_direction: float = 1.0
var was_on_floor: bool = false
var ghost_trail_timer: float = 0.0

# Valores cacheados desde stats
var max_speed: float = 260.0
var acceleration: float = 1500.0
var deceleration: float = 1900.0

func _ready() -> void:
	# Sección 12 & 34: Inicialización mediante contratos de componentes y resources
	if stats != null:
		health.configure_from_stats(stats)
		movement.configure_from_stats(stats)
		max_speed = stats.move_speed
		acceleration = stats.acceleration
		deceleration = stats.deceleration

	if weapon != null:
		_apply_weapon_data(weapon)

	# Conexiones de señales
	animated_sprite.animation_finished.connect(_on_animation_finished)
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	_change_state(PlayerState.IDLE)
	_update_debug_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("switch_weapon") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		_swap_weapon()

func _physics_process(delta: float) -> void:
	_update_coyote_time(delta)
	_update_jump_buffer(delta)
	_update_dash(delta)

	_try_start_dash()

	# Movimiento y física (no aplicables si está muerto)
	if current_state != PlayerState.DEAD:
		if not is_dashing:
			_apply_gravity(delta)
			# Durante el ataque terrestre se frena el avance
			if current_state != PlayerState.ATTACK:
				_update_horizontal_movement(delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

			_try_jump()
			_try_wall_jump()
			_apply_jump_cut()
			_apply_wall_slide()

		move_and_slide()

	_check_landing_event()
	_update_state()
	_update_facing_from_input()

	if is_dashing:
		_process_dash_trail(delta)

	_update_debug_ui()

# ====================================================================
# SECCIÓN 17 & 34: DELEGACIÓN DE MOVIMIENTO A MOVEMENTCOMPONENT
# ====================================================================
func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if movement:
		velocity.x = movement.calculate_horizontal_velocity(velocity.x, direction, delta)
	else:
		var target_speed := direction * max_speed
		velocity.x = move_toward(velocity.x, target_speed, (acceleration if direction != 0.0 else deceleration) * delta)

# ====================================================================
# RETO 43: GESTIÓN Y CAMBIO DINÁMICO DE ARMAS (WeaponData)
# ====================================================================
func _swap_weapon() -> void:
	if secondary_weapon == null:
		return
	var temp := weapon
	weapon = secondary_weapon
	secondary_weapon = temp
	_apply_weapon_data(weapon)
	weapon_swapped.emit(weapon)

func _apply_weapon_data(data: WeaponData) -> void:
	if data == null or sword_hitbox == null:
		return
	# Duplicar AttackData si es necesario para evitar mutar el recurso base compartido
	if sword_hitbox.attack_data != null:
		sword_hitbox.attack_data.damage = data.damage
		sword_hitbox.attack_data.knockback_force = data.knockback_force

# ====================================================================
# FSM: PRIORIDADES DE ESTADOS (Secciones 12, 19 y 26)
# ====================================================================
func _update_state() -> void:
	if current_state == PlayerState.DEAD or current_state == PlayerState.HURT or current_state == PlayerState.ATTACK:
		return

	if is_dashing:
		_change_state(PlayerState.DASH)
		return

	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		_change_state(PlayerState.WALL_SLIDE)
		return

	if not is_on_floor():
		if velocity.y < 0.0:
			_change_state(PlayerState.JUMP)
		else:
			_change_state(PlayerState.FALL)
		return

	if abs(velocity.x) > 15.0:
		_change_state(PlayerState.RUN)
	else:
		_change_state(PlayerState.IDLE)

func _change_state(new_state: PlayerState) -> void:
	if new_state == current_state and current_state != PlayerState.IDLE:
		return

	_exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	_enter_state(current_state)

func _enter_state(state: PlayerState) -> void:
	_play_state_animation()

	match state:
		PlayerState.ATTACK:
			can_attack = false
			sword_hitbox.begin_attack()
		PlayerState.HURT:
			sword_hitbox.end_attack()
			can_attack = false
			if animation_player.has_animation("hurt_flash"):
				animation_player.play("hurt_flash")
			_play_invulnerability_feedback(0.35)
		PlayerState.DEAD:
			velocity = Vector2.ZERO
			sword_hitbox.end_attack()
			can_attack = false
			_handle_death_flow()
		PlayerState.JUMP:
			if animation_player.has_animation("jump_stretch"):
				animation_player.play("jump_stretch")

func _exit_state(state: PlayerState) -> void:
	match state:
		PlayerState.ATTACK:
			sword_hitbox.end_attack()
		PlayerState.DASH:
			visuals.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_:
			pass

func _play_state_animation() -> void:
	match current_state:
		PlayerState.IDLE: animated_sprite.play("idle")
		PlayerState.RUN: animated_sprite.play("run")
		PlayerState.JUMP: animated_sprite.play("jump")
		PlayerState.FALL: animated_sprite.play("fall")
		PlayerState.WALL_SLIDE: animated_sprite.play("wall_slide")
		PlayerState.DASH: animated_sprite.play("dash")
		PlayerState.ATTACK: animated_sprite.play("attack")
		PlayerState.HURT: animated_sprite.play("hurt")
		PlayerState.DEAD: animated_sprite.play("dead")

# ====================================================================
# COMBATE Y SEÑALES DESACOPLADAS (Secciones 18, 20 y 34)
# ====================================================================
func _try_attack() -> void:
	if not can_attack or current_state == PlayerState.DEAD or current_state == PlayerState.HURT:
		return
	_change_state(PlayerState.ATTACK)

func _on_animation_finished() -> void:
	match animated_sprite.animation:
		"attack":
			sword_hitbox.end_attack()
			can_attack = true
			_change_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)
		"hurt":
			can_attack = true
			_change_state(PlayerState.IDLE if is_on_floor() else PlayerState.FALL)

func _on_hit_received(attack: AttackData, direction: Vector2) -> void:
	if current_state == PlayerState.DEAD:
		return

	velocity = direction * attack.knockback_force
	_change_state(PlayerState.HURT)

func _on_health_changed(current: int, maximum: int) -> void:
	# Sección 20: Desacoplamiento total - notificación a EventBus
	if EventBus:
		EventBus.player_damaged.emit(current, maximum)

func _on_died() -> void:
	_change_state(PlayerState.DEAD)
	player_died.emit()
	# Sección 20: Notificación a nivel global sin acoplamiento
	if EventBus:
		EventBus.player_died.emit()

func _handle_death_flow() -> void:
	await get_tree().create_timer(1.2).timeout
	respawn_requested.emit()

func _play_invulnerability_feedback(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		visuals.visible = not visuals.visible
		await get_tree().create_timer(0.06).timeout
		elapsed += 0.06
	visuals.visible = true

func respawn_at(new_position: Vector2) -> void:
	global_position = new_position
	velocity = Vector2.ZERO
	if stats:
		health.configure_from_stats(stats)
	else:
		health.reset_health()
	can_attack = true
	visuals.visible = true
	visuals.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_change_state(PlayerState.IDLE)

# ====================================================================
# ORIENTACIÓN Y FÍSICAS DE LOCOMOCIÓN
# ====================================================================
func _update_facing_from_input() -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0 and current_state != PlayerState.ATTACK:
		animated_sprite.flip_h = direction < 0.0
		facing_direction = direction
		attack_origin.scale.x = facing_direction

func _check_landing_event() -> void:
	if is_on_floor() and not was_on_floor:
		if animation_player.has_animation("land_squash"):
			animation_player.play("land_squash")
		_spawn_land_dust()
	was_on_floor = is_on_floor()

func _spawn_land_dust() -> void:
	var vfx_spawner := get_tree().root.find_child("VFXSpawner", true, false) as VFXSpawner
	if vfx_spawner and LAND_DUST_SCENE:
		vfx_spawner.spawn_effect(LAND_DUST_SCENE, global_position + Vector2(0, 20))
	elif LAND_DUST_SCENE:
		var dust := LAND_DUST_SCENE.instantiate() as Node2D
		get_parent().add_child(dust)
		dust.global_position = global_position + Vector2(0, 20)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

func _apply_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func _apply_wall_slide() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		velocity.y = min(velocity.y, wall_slide_speed)

func _try_wall_jump() -> void:
	if jump_buffer_timer > 0.0 and is_on_wall() and not is_on_floor():
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed
		jump_buffer_timer = 0.0

func _try_start_dash() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and current_state != PlayerState.DEAD:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		if dash_trail:
			dash_trail.emitting = true

func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	if not is_dashing:
		return
	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0
	if dash_timer <= 0.0:
		is_dashing = false
		if dash_trail:
			dash_trail.emitting = false

func _process_dash_trail(delta: float) -> void:
	ghost_trail_timer -= delta
	if ghost_trail_timer <= 0.0:
		ghost_trail_timer = 0.04
		_spawn_ghost_sprite()

func _spawn_ghost_sprite() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.global_position = animated_sprite.global_position
	ghost.scale = animated_sprite.global_scale
	ghost.flip_h = animated_sprite.flip_h
	ghost.modulate = Color(0.4, 0.8, 1.0, 0.6)
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)

func _state_to_text() -> String:
	return PlayerState.keys()[current_state]

func _update_debug_ui() -> void:
	if not state_label:
		return
	var weapon_info := (" [%s]" % weapon.weapon_name) if weapon else ""
	state_label.text = _state_to_text() + weapon_info
	match current_state:
		PlayerState.IDLE: state_label.modulate = Color("#80d8ff")
		PlayerState.RUN: state_label.modulate = Color("#69f0ae")
		PlayerState.JUMP: state_label.modulate = Color("#ffd740")
		PlayerState.FALL: state_label.modulate = Color("#ffab40")
		PlayerState.WALL_SLIDE: state_label.modulate = Color("#40c4ff")
		PlayerState.DASH: state_label.modulate = Color("#ff4081")
		PlayerState.ATTACK: state_label.modulate = Color("#ff5252")
		PlayerState.HURT: state_label.modulate = Color("#b388ff")
		PlayerState.DEAD: state_label.modulate = Color("#9e9e9e")
