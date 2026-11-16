extends CharacterBody2D

## Controlador de plataformas 2D avanzado (Guía Lab 03 - Semana 3)
## Implementa aceleración, salto variable, coyote time, jump buffering, wall slide/jump y dash.

signal dash_cooldown_updated(remaining: float, total: float)
signal movement_state_changed(state_name: String)

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

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var _was_on_floor: bool = false

@export_category("Wall")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_horizontal_speed: float = 320.0
@export var wall_jump_vertical_speed: float = -480.0

@export_category("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var facing_direction: float = 1.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Orden de ejecución estricto (Guía Lab 03 - Sec. 16)
	_update_coyote_time(delta)
	_update_jump_buffer(delta)
	_update_dash(delta)

	if not is_dashing:
		_apply_gravity(delta)
		_update_horizontal_movement(delta)
		_try_jump()
		_try_wall_jump()
		_apply_jump_cut()
		_apply_wall_slide()

	_try_start_dash()
	move_and_slide()
	_check_landing_feedback()

## 1. Gravedad (Guía Sec. 5.1)
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

## 2. Movimiento horizontal e inercia (Guía Sec. 8)
func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * max_speed
	
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		facing_direction = sign(direction)
		if sprite:
			sprite.flip_h = (facing_direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

## 3. Coyote time: ventana para saltar tras dejar un borde (Guía Sec. 10)
func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

## 4. Jump buffering: anticipación de pulsación antes de tocar suelo (Guía Sec. 11)
func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

## 5. Salto con tolerancia (Guía Sec. 11 y 12)
func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		_apply_squash_and_stretch(Vector2(0.8, 1.25)) # Reto ampliación: estirar al saltar
		movement_state_changed.emit("Salto")

## 6. Salto variable (Jump cut al soltar botón) (Guía Sec. 9)
func _apply_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

## 7. Wall slide: fricción vertical contra paredes (Guía Sec. 13)
func _apply_wall_slide() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		velocity.y = min(velocity.y, wall_slide_speed)
		movement_state_changed.emit("Wall Slide")

## 8. Wall jump: impulso opuesto usando la normal del muro (Guía Sec. 14)
func _try_wall_jump() -> void:
	if jump_buffer_timer > 0.0 and is_on_wall() and not is_on_floor():
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		facing_direction = sign(velocity.x)
		if sprite:
			sprite.flip_h = (facing_direction < 0)
		_apply_squash_and_stretch(Vector2(0.85, 1.2))
		movement_state_changed.emit("Wall Jump")

## 9. Dash: impulso temporal horizontal con cooldown (Guía Sec. 15)
func _try_start_dash() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		_apply_squash_and_stretch(Vector2(1.35, 0.75)) # Efecto visual de velocidad
		movement_state_changed.emit("Dash")

func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)
	dash_cooldown_updated.emit(dash_cooldown_timer, dash_cooldown)

	if not is_dashing:
		return

	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0

	if dash_timer <= 0.0:
		is_dashing = false

## Reto de ampliación: Squash & Stretch procedural (Guía Sec. 24)
func _apply_squash_and_stretch(target_scale: Vector2) -> void:
	if not sprite:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "scale", target_scale, 0.08)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.12)

## Detección de aterrizaje para squash visual
func _check_landing_feedback() -> void:
	if is_on_floor() and not _was_on_floor and velocity.y >= 0.0:
		_apply_squash_and_stretch(Vector2(1.25, 0.8)) # Aplastamiento al tocar suelo
		movement_state_changed.emit("Suelo")
	_was_on_floor = is_on_floor()

## Helper para respawn tras caer al vacío (Guía Sec. 24)
func respawn(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
