extends CharacterBody2D

## ====================================================================
## Laboratorio 05: Animaciones Profesionales y Máquinas de Estados (FSM)
## ====================================================================
## Implementación de FSM lógica desacoplada de la animación (Secciones 4, 10-17).
## La física decide el estado; la animación observa el estado y lo representa.

# --- ESTADOS DE LA FSM (Secciones 11 y 25) ---
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

# --- CONFIGURACIÓN DE FÍSICAS (Semana 3 & 4) ---
@export_category("Horizontal Movement")
@export var max_speed: float = 260.0
@export var acceleration: float = 1500.0
@export var deceleration: float = 1900.0

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

# --- REFERENCIAS A NODOS (Sección 7.1) ---
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_label: Label = $DebugLayer/Margin/Panel/HBox/StateLabel

# --- VARIABLES DE ESTADO Y TIMERS ---
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var facing_direction: float = 1.0
var was_on_floor: bool = false

# Timer interno para efecto de ghost trail durante DASH (Reto 33)
var ghost_trail_timer: float = 0.0

func _ready() -> void:
	# Conexión de señal para animaciones no cíclicas (Sección 27)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Inicializar en IDLE y reproducir animación inicial (Sección 8)
	_change_state(PlayerState.IDLE)
	_update_debug_ui()

func _unhandled_input(event: InputEvent) -> void:
	# Triggers de prueba rápida para estados de Semana 6 (Reto 33)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			_try_attack()
		elif event.keycode == KEY_K:
			take_damage()

func _physics_process(delta: float) -> void:
	# 1. Actualizar timers
	_update_coyote_time(delta)
	_update_jump_buffer(delta)
	_update_dash(delta)

	# 2. Entrada y disparo de Dash
	_try_start_dash()

	# 3. Físicas principales si no está en Dash (o estados de no interrupción)
	if not is_dashing and current_state != PlayerState.DEAD:
		_apply_gravity(delta)
		_update_horizontal_movement(delta)
		_try_jump()
		_try_wall_jump()
		_apply_jump_cut()
		_apply_wall_slide()

	# 4. Resolver colisiones
	move_and_slide()

	# 5. Detección de evento de aterrizaje (Sección 18.2)
	_check_landing_event()

	# 6. Actualizar estado lógico FSM (Sección 12 y 15)
	_update_state()

	# 7. Actualizar orientación visual sin afectar colisiones (Sección 9 y 16)
	_update_facing_from_input()

	# 8. Reto 33: Trail visual durante DASH
	if is_dashing:
		_process_dash_trail(delta)

	# 9. Actualizar instrumentación de depuración (Sección 29 & Reto 33)
	_update_debug_ui()

# ====================================================================
# FSM: EVALUACIÓN Y PRIORIDADES DE ESTADO (Sección 12 & 26)
# ====================================================================
func _update_state() -> void:
	# Estados con prioridad dominante absoluta (no cancelables por movimiento)
	if current_state == PlayerState.DEAD:
		return
	if current_state == PlayerState.HURT or current_state == PlayerState.ATTACK:
		return

	# Prioridad 1: Dash (se evalúa antes que caída/salto, Sección 12)
	if is_dashing:
		_change_state(PlayerState.DASH)
		return

	# Prioridad 2: Wall slide (en pared, no en suelo y cayendo)
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		_change_state(PlayerState.WALL_SLIDE)
		return

	# Prioridad 3: Estados aéreos (distinción por signo de velocidad vertical)
	if not is_on_floor():
		if velocity.y < 0.0:
			_change_state(PlayerState.JUMP)
		else:
			_change_state(PlayerState.FALL)
		return

	# Prioridad 4: Locomoción en suelo
	if abs(velocity.x) > 15.0:
		_change_state(PlayerState.RUN)
	else:
		_change_state(PlayerState.IDLE)

# ====================================================================
# FSM: TRANSICIONES Y ACCIONES DE ENTRADA / SALIDA (Sección 13 & 17)
# ====================================================================
func _change_state(new_state: PlayerState) -> void:
	if new_state == current_state and current_state != PlayerState.IDLE:
		return

	_exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	_enter_state(current_state)

func _enter_state(state: PlayerState) -> void:
	# Reproducir animación asignada al nuevo estado
	_play_state_animation()

	match state:
		PlayerState.JUMP:
			# Reto 33: Squash & stretch diferente para el salto
			if animation_player.has_animation("jump_stretch"):
				animation_player.play("jump_stretch")
		PlayerState.DASH:
			pass
		PlayerState.HURT:
			if animation_player.has_animation("hurt_flash"):
				animation_player.play("hurt_flash")

func _exit_state(state: PlayerState) -> void:
	match state:
		PlayerState.DASH:
			# Limpiar cualquier residuo visual del dash
			visuals.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_:
			pass

# ====================================================================
# ASOCIACIÓN ESTADO-ANIMACIÓN (Sección 14)
# ====================================================================
func _play_state_animation() -> void:
	match current_state:
		PlayerState.IDLE:
			animated_sprite.play("idle")
		PlayerState.RUN:
			animated_sprite.play("run")
		PlayerState.JUMP:
			animated_sprite.play("jump")
		PlayerState.FALL:
			animated_sprite.play("fall")
		PlayerState.WALL_SLIDE:
			animated_sprite.play("wall_slide")
		PlayerState.DASH:
			animated_sprite.play("dash")
		PlayerState.ATTACK:
			animated_sprite.play("attack")
		PlayerState.HURT:
			animated_sprite.play("hurt")
		PlayerState.DEAD:
			animated_sprite.play("dead")

# ====================================================================
# FIN DE ANIMACIONES NO CÍCLICAS (Sección 27)
# ====================================================================
func _on_animation_finished() -> void:
	if current_state == PlayerState.ATTACK:
		_change_state(PlayerState.IDLE)
	elif current_state == PlayerState.HURT:
		_change_state(PlayerState.IDLE)

# ====================================================================
# ORIENTACIÓN HORIZONTAL (Sección 9 y 16)
# ====================================================================
func _update_facing_from_input() -> void:
	# Permitir que el personaje mire hacia donde el jugador intenta moverse
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
		facing_direction = direction

# ====================================================================
# EVENTO DE ATERRIZAJE (Sección 18.2 & Reto 33)
# ====================================================================
func _check_landing_event() -> void:
	if is_on_floor() and not was_on_floor:
		# Dispara squash de aterrizaje sin convertir LAND en estado permanente
		if animation_player.has_animation("land_squash"):
			animation_player.play("land_squash")
	was_on_floor = is_on_floor()

# ====================================================================
# FÍSICA Y MOVIMIENTO (Mecánicas de Plataformas)
# ====================================================================
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * max_speed

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

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
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	if not is_dashing:
		return

	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0

	if dash_timer <= 0.0:
		is_dashing = false

# ====================================================================
# RETO 33: EFECTO DE ESTELA (GHOST TRAIL) DURANTE DASH
# ====================================================================
func _process_dash_trail(delta: float) -> void:
	ghost_trail_timer -= delta
	if ghost_trail_timer <= 0.0:
		ghost_trail_timer = 0.04
		_spawn_ghost_sprite()

func _spawn_ghost_sprite() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)
	ghost.global_position = animated_sprite.global_position
	ghost.scale = animated_sprite.global_scale
	ghost.flip_h = animated_sprite.flip_h
	ghost.modulate = Color(0.4, 0.8, 1.0, 0.6) # Tinte cian etéreo
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)

	# Desvanecer fantasma mediante Tween
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)

# ====================================================================
# PREPARACIÓN PARA SEMANA 6: ACCIONES DE PRUEBA
# ====================================================================
func _try_attack() -> void:
	if current_state != PlayerState.ATTACK and current_state != PlayerState.DEAD:
		_change_state(PlayerState.ATTACK)

func take_damage() -> void:
	if current_state != PlayerState.DEAD:
		_change_state(PlayerState.HURT)

# ====================================================================
# INSTRUMENTACIÓN DE DEPURACIÓN (Sección 29 & Reto 33)
# ====================================================================
func _state_to_text() -> String:
	return PlayerState.keys()[current_state]

func _update_debug_ui() -> void:
	if not state_label:
		return

	state_label.text = _state_to_text()

	# Reto 33: StateLabel con color diferente por estado
	match current_state:
		PlayerState.IDLE:
			state_label.modulate = Color("#80d8ff") # Celeste suave
		PlayerState.RUN:
			state_label.modulate = Color("#69f0ae") # Verde esmeralda
		PlayerState.JUMP:
			state_label.modulate = Color("#ffd740") # Amarillo dorado
		PlayerState.FALL:
			state_label.modulate = Color("#ffab40") # Naranja ámbar
		PlayerState.WALL_SLIDE:
			state_label.modulate = Color("#40c4ff") # Azul cian
		PlayerState.DASH:
			state_label.modulate = Color("#ff4081") # Magenta / Fucsia
		PlayerState.ATTACK:
			state_label.modulate = Color("#ff5252") # Rojo brillante
		PlayerState.HURT:
			state_label.modulate = Color("#b388ff") # Violeta
		PlayerState.DEAD:
			state_label.modulate = Color("#9e9e9e") # Gris ceniza
