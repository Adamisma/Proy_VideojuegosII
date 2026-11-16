class_name Player
extends CharacterBody2D

## ====================================================================
## Proyecto Cahuide - Controlador Principal Refactorizado
## ====================================================================
## - Arquitectura por componentes (MovementComponent, HealthComponent).
## - Armas a distancia alternables: Piedra Ancestral vs. Lanza Inca (tecla E).
## - Power-Up del Sol con soporte para intercambio de SpriteFrames (skins) y aura solar.
## - VFX: Flash de daño por shader, ghost trail en Dash y polvo al caer.
## - Cámara con sacudida paramétrica (solo al recibir daño y activar Power-Up).
## - Desacoplamiento total mediante EventBus.

signal health_changed(new_health: int, max_health: int)
signal player_died
signal respawn_requested

const LAND_DUST_SCENE: PackedScene = preload("res://scenes/vfx/fx_land_dust.tscn")
const DAMAGE_FLASH_MAT: Material = preload("res://materials/mat_damage_flash.tres")

# --- SKINS Y ANIMACIONES ---
@export_category("Skins & Animations")
@export var normal_frames: SpriteFrames = preload("res://scenes/player/player_frames.tres")
@export var sol_frames: SpriteFrames # Opcional: SpriteFrames con uniforme alternativo

# --- ESTADÍSTICAS Y SALUD ---
@export_category("Health")
@export var max_health: int = 20
var health: int = 20

# --- FÍSICAS Y LOCOMOCIÓN ---
@export_category("Locomotion")
@export var max_speed: float = 260.0
@export var acceleration: float = 1600.0
@export var deceleration: float = 1900.0
@export var gravity: float = 1350.0
@export var jump_velocity: float = -570.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var jump_cut_multiplier: float = 0.5

# --- PARED Y SALTO ---
@export_category("Wall Mechanics")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_horizontal_speed: float = 310.0
@export var wall_jump_vertical_speed: float = -620.0

# --- DASH ---
@export_category("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45

# --- COMBATE MELEE Y A DISTANCIA ---
@export_category("Combat")
@export var melee_damage: int = 25
@export var stone_projectile_scene: PackedScene = preload("res://scenes/projectiles/stone_projectile.tscn")
@export var spear_projectile_scene: PackedScene = preload("res://scenes/projectiles/spear_projectile.tscn")
@export var stone_speed_x: float = 430.0
@export var stone_speed_y: float = -380.0
@export var attack_cooldown: float = 0.38
@export var shoot_cooldown: float = 0.45

# --- POWER-UP DEL SOL ---
@export_category("Power-Up Sol")
@export var sol_duration: float = 15.0
var has_sol_powerup: bool = false
var sol_timer: float = 0.0

# --- REFERENCIAS A NODOS ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var camera: Camera2D = get_node_or_null("Camera2D")

# Componentes desacoplados (opcionales por inspección segura)
@onready var movement: MovementComponent = get_node_or_null("MovementComponent")
@onready var health_comp: HealthComponent = get_node_or_null("HealthComponent")

# --- VARIABLES DE ESTADO ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var shoot_timer: float = 0.0
var ghost_trail_timer: float = 0.0

var is_dashing: bool = false
var is_attacking: bool = false
var is_invulnerable: bool = false
var is_dead: bool = false
var was_on_floor: bool = false
var facing_direction: float = 1.0 # 1 derecha, -1 izquierda

# 0 = Piedra, 1 = Lanza
var current_ranged_weapon: int = 0
var flash_material: ShaderMaterial

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)

	if EventBus:
		EventBus.player_damaged.emit(health, max_health)

	if normal_frames and animated_sprite:
		animated_sprite.sprite_frames = normal_frames

	# Inicializar material de flash blanco
	if DAMAGE_FLASH_MAT:
		flash_material = DAMAGE_FLASH_MAT.duplicate() as ShaderMaterial
		if animated_sprite:
			animated_sprite.material = flash_material

	# Conexiones de combate
	if melee_hitbox:
		melee_hitbox.monitoring = false
	if hurtbox and hurtbox.has_signal("received_damage"):
		hurtbox.connect("received_damage", _on_received_damage)

	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_timers(delta)
	_update_sol_powerup(delta)
	_update_dash(delta)
	_try_start_dash()

	if not is_dashing:
		_apply_gravity(delta)
		_update_horizontal_movement(delta)
		_try_jump()
		_try_wall_jump()
		_apply_jump_cut()
		_apply_wall_slide()

	move_and_slide()

	_check_landing_dust()
	_handle_combat_inputs()
	_update_animations()

	if is_dashing:
		_process_dash_ghost_trail(delta)

# ====================================================================
# LOCOMOCIÓN Y FÍSICAS
# ====================================================================
func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if movement:
		velocity.x = movement.calculate_horizontal_velocity(velocity.x, direction, delta)
	else:
		var target_speed := direction * max_speed
		var rate: float = acceleration if direction != 0.0 else deceleration
		velocity.x = move_toward(velocity.x, target_speed, rate * delta)

	if direction != 0.0 and not is_attacking:
		facing_direction = sign(direction)
		_update_facing()

func _update_facing() -> void:
	if animated_sprite:
		animated_sprite.flip_h = (facing_direction < 0.0)
	if melee_hitbox:
		melee_hitbox.position.x = facing_direction * 38.0

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	attack_timer = max(0.0, attack_timer - delta)
	shoot_timer = max(0.0, shoot_timer - delta)

func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		if not is_attacking and animated_sprite:
			animated_sprite.play("jump")

func _apply_wall_slide() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		velocity.y = min(velocity.y, wall_slide_speed)

func _try_wall_jump() -> void:
	if jump_buffer_timer > 0.0 and is_on_wall() and not is_on_floor():
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_horizontal_speed
		velocity.y = wall_jump_vertical_speed
		jump_buffer_timer = 0.0
		facing_direction = sign(velocity.x)
		_update_facing()

func _apply_jump_cut() -> void:
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

func _check_landing_dust() -> void:
	if is_on_floor() and not was_on_floor:
		_spawn_land_dust()
	was_on_floor = is_on_floor()

func _spawn_land_dust() -> void:
	if LAND_DUST_SCENE:
		var dust := LAND_DUST_SCENE.instantiate() as Node2D
		get_parent().add_child(dust)
		dust.global_position = global_position + Vector2(0, 38)

# ====================================================================
# DASH CON GHOST TRAIL
# ====================================================================
func _try_start_dash() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and not is_dead:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown

func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	if not is_dashing:
		return

	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0

	if dash_timer <= 0.0:
		is_dashing = false

func _process_dash_ghost_trail(delta: float) -> void:
	ghost_trail_timer -= delta
	if ghost_trail_timer <= 0.0 and animated_sprite:
		ghost_trail_timer = 0.04
		_spawn_ghost_sprite()

func _spawn_ghost_sprite() -> void:
	var ghost := Sprite2D.new()
	var current_tex: Texture2D = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	if current_tex == null:
		return
	ghost.texture = current_tex
	ghost.global_position = animated_sprite.global_position
	ghost.scale = animated_sprite.global_scale
	ghost.flip_h = animated_sprite.flip_h
	ghost.modulate = Color(1.0, 0.85, 0.3, 0.6) if has_sol_powerup else Color(0.4, 0.7, 1.0, 0.5)
	ghost.z_index = z_index - 1
	get_parent().add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)

# ====================================================================
# COMBATE Y ARMAS A DISTANCIA (Piedra vs. Lanza)
# ====================================================================
func _handle_combat_inputs() -> void:
	# Alternar arma a distancia con [E]
	if Input.is_action_just_pressed("switch_weapon"):
		_swap_ranged_weapon()

	# Ataque cuerpo a cuerpo [J] / Clic Izquierdo
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0 and not is_attacking:
		_execute_melee_attack()

	# Ataque a distancia [K] / Clic Derecho
	if Input.is_action_just_pressed("shoot") and shoot_timer <= 0.0:
		_execute_ranged_attack()

	# Atajo secundario de piedra directa [L]
	if Input.is_action_just_pressed("stone_shoot") and shoot_timer <= 0.0:
		_throw_stone()

func _swap_ranged_weapon() -> void:
	current_ranged_weapon = 1 if current_ranged_weapon == 0 else 0
	var w_name: String = "Lanza Inca" if current_ranged_weapon == 1 else "Piedra Ancestral"
	if EventBus:
		EventBus.ranged_weapon_swapped.emit(w_name)

func _execute_melee_attack() -> void:
	attack_timer = attack_cooldown
	is_attacking = true
	if animated_sprite:
		animated_sprite.play("attack")

	if melee_hitbox:
		melee_hitbox.monitoring = true
		await get_tree().create_timer(0.22).timeout
		if is_instance_valid(melee_hitbox):
			melee_hitbox.monitoring = false

func _execute_ranged_attack() -> void:
	if current_ranged_weapon == 0:
		_throw_stone()
	else:
		_throw_spear()

func _throw_stone() -> void:
	if stone_projectile_scene == null:
		return
	shoot_timer = shoot_cooldown

	var stone := stone_projectile_scene.instantiate() as StoneProjectile
	if stone == null:
		return

	get_tree().current_scene.add_child(stone)
	stone.global_position = global_position + Vector2(facing_direction * 28.0, -10.0)

	var bonus_dmg: int = 10 if has_sol_powerup else 0
	stone.damage += bonus_dmg
	stone.launch(Vector2(facing_direction * stone_speed_x, stone_speed_y))

func _throw_spear() -> void:
	if spear_projectile_scene == null:
		return
	shoot_timer = shoot_cooldown + 0.15

	var spear := spear_projectile_scene.instantiate() as SpearProjectile
	if spear == null:
		return

	get_tree().current_scene.add_child(spear)
	spear.global_position = global_position + Vector2(facing_direction * 32.0, -8.0)

	var bonus_dmg: int = 15 if has_sol_powerup else 0
	spear.damage += bonus_dmg
	spear.launch(Vector2(facing_direction, 0.0))

# ====================================================================
# POWER-UP DEL SOL Y SKINS DINÁMICOS
# ====================================================================
func apply_powerup_sol() -> void:
	has_sol_powerup = true
	sol_timer = sol_duration

	# Curación de 2 puntos (1 corazón)
	health = mini(health + 2, max_health)
	health_changed.emit(health, max_health)
	if EventBus:
		EventBus.player_damaged.emit(health, max_health)
		EventBus.player_powerup_activated.emit(sol_duration)

	# Sacudida de cámara al activar el Power-Up según especificación
	_trigger_camera_shake(0.65)

	# Intercambio de skin si existe sol_frames
	if sol_frames and animated_sprite:
		animated_sprite.sprite_frames = sol_frames
	elif animated_sprite:
		animated_sprite.modulate = Color(2.2, 1.8, 0.4, 1.0)

func _update_sol_powerup(delta: float) -> void:
	if not has_sol_powerup:
		return

	sol_timer -= delta

	# Parpadeo de advertencia en los últimos 3 segundos
	if sol_timer <= 3.0 and sol_timer > 0.0:
		var blink := fmod(sol_timer * 10.0, 2.0) > 1.0
		if animated_sprite and not is_invulnerable:
			animated_sprite.modulate = Color(2.5, 2.0, 0.5, 1.0) if blink else Color(1, 1, 1, 1)

	if sol_timer <= 0.0:
		_remove_sol_powerup()

func _remove_sol_powerup() -> void:
	has_sol_powerup = false
	if normal_frames and animated_sprite:
		animated_sprite.sprite_frames = normal_frames
	if animated_sprite and not is_invulnerable:
		animated_sprite.modulate = Color(1, 1, 1, 1)
	if EventBus:
		EventBus.player_powerup_ended.emit()

# ====================================================================
# GESTIÓN DE DAÑO, SHADERS Y MUERTE
# ====================================================================
func _on_received_damage(amount: int, knockback: Vector2) -> void:
	take_direct_damage(amount, knockback)

func _calculate_mitigated_damage(incoming: int) -> int:
	if has_sol_powerup:
		return 0 if incoming <= 1 else 1
	return clampi(incoming, 1, 2)

func take_direct_damage(amount: int = 1, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_dead:
		return

	var applied := _calculate_mitigated_damage(amount)
	if applied <= 0:
		return

	health = maxi(0, health - applied)
	health_changed.emit(health, max_health)

	if EventBus:
		EventBus.player_damaged.emit(health, max_health)

	if knockback != Vector2.ZERO:
		velocity = knockback

	# Sacudida paramétrica de cámara al recibir daño según especificación
	_trigger_camera_shake(0.55)

	# Flash blanco instantáneo por shader
	_play_damage_flash()

	if health <= 0:
		_die()
		return

	is_attacking = false
	if animated_sprite:
		animated_sprite.play("hurt")

	_start_invulnerability(0.45)

func _play_damage_flash() -> void:
	if flash_material:
		flash_material.set_shader_parameter("flash_amount", 1.0)
		var tween := create_tween()
		tween.tween_method(
			func(val: float): flash_material.set_shader_parameter("flash_amount", val),
			1.0, 0.0, 0.16
		)

func _trigger_camera_shake(intensity: float) -> void:
	if camera and camera.has_method("trigger_shake"):
		camera.trigger_shake(intensity)

func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	var elapsed := 0.0
	while elapsed < duration and not is_dead:
		if animated_sprite:
			animated_sprite.visible = not animated_sprite.visible
		await get_tree().create_timer(0.06).timeout
		elapsed += 0.06

	if animated_sprite:
		animated_sprite.visible = true
	is_invulnerable = false

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()
	if EventBus:
		EventBus.player_died.emit()
	if animated_sprite:
		animated_sprite.play("dead")

func respawn_at(new_position: Vector2) -> void:
	global_position = new_position
	velocity = Vector2.ZERO
	is_dead = false
	is_attacking = false
	is_invulnerable = false
	health = max_health
	health_changed.emit(health, max_health)
	if EventBus:
		EventBus.player_damaged.emit(health, max_health)
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate = Color(1, 1, 1, 1)
		animated_sprite.play("idle")

# ====================================================================
# ANIMACIONES
# ====================================================================
func _update_animations() -> void:
	if is_dead or is_attacking or animated_sprite == null:
		return

	if not is_on_floor():
		if animated_sprite.animation != "jump":
			animated_sprite.play("jump")
	elif abs(velocity.x) > 180.0:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	elif abs(velocity.x) > 10.0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _on_animation_finished() -> void:
	if animated_sprite and (animated_sprite.animation == "attack" or animated_sprite.animation == "hurt"):
		is_attacking = false
