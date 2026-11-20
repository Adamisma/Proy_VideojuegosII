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
@warning_ignore("unused_signal")
signal respawn_requested

const LAND_DUST_SCENE: PackedScene = preload("res://scenes/vfx/fx_land_dust.tscn")
const DAMAGE_FLASH_MAT: Material = preload("res://materials/mat_damage_flash.tres")
const FX_ATTACK_WAVE_SCENE: PackedScene = preload("res://scenes/vfx/fx_attack_wave.tscn")
const NET_ANIM_NAMES: PackedStringArray = [
	"idle", "walk", "run", "jump", "attack", "hurt", "dead", "transform", "detransform"
]
const NET_SYNC_INTERVAL: float = 0.04 # 25 Hz ligero para baja latencia LAN

# --- SKINS Y ANIMACIONES ---
@export_category("Skins & Animations")
@export var normal_frames: SpriteFrames = preload("res://scenes/player/player_frames.tres")
@export var sol_frames: SpriteFrames = preload("res://scenes/player/player_sol_frames.tres")

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
@export var jump_cut_multiplier: float = 0.65
@export var max_jump_hold_time: float = 0.28
@export var min_jump_velocity: float = -380.0

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

# Efectos visuales y audio
@onready var solar_sparks: CPUParticles2D = get_node_or_null("SolarSparks")
@onready var sfx_attack: AudioStreamPlayer2D = get_node_or_null("SFXAttack")
@onready var sfx_transform: AudioStreamPlayer2D = get_node_or_null("SFXTransform")
@onready var sfx_footsteps: AudioStreamPlayer2D = get_node_or_null("SFXFootsteps")

# --- VARIABLES DE ESTADO ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_jumping: bool = false
var jump_hold_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var attack_timer: float = 0.0
var shoot_timer: float = 0.0
var ghost_trail_timer: float = 0.0

var is_dashing: bool = false
var is_attacking: bool = false
var is_invulnerable: bool = false
var is_dead: bool = false
var is_transforming: bool = false
var was_on_floor: bool = false
var facing_direction: float = 1.0 # 1 derecha, -1 izquierda

# 0 = Piedra, 1 = Lanza
var current_ranged_weapon: int = 0
var flash_material: ShaderMaterial

# --- MULTIJUGADOR LAN (US-05) ---
var peer_id: int = 1
var player_slot: int = 1
var player_display_name: String = "Cahuide"
var character_id: String = "cahuide"
var base_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var ranged_damage_bonus: int = 0
var _base_max_speed: float = 260.0
var _base_melee_damage: int = 25
var _net_sync_accum: float = 0.0
var _net_target_pos: Vector2 = Vector2.ZERO
var _net_last_anim_idx: int = -1
var _net_last_facing: float = 1.0
var _name_tag: Label = null


func is_local_controlled() -> bool:
	if NetworkManager == null or not NetworkManager.is_multiplayer_active():
		return true
	return is_multiplayer_authority()


func configure_network_player(p_peer_id: int, p_name: String, p_char_id: String, p_slot: int) -> void:
	peer_id = p_peer_id
	player_display_name = p_name
	character_id = p_char_id
	player_slot = p_slot
	set_multiplayer_authority(p_peer_id)
	if is_inside_tree():
		_apply_network_setup()


func _apply_network_setup() -> void:
	var is_lan := NetworkManager != null and NetworkManager.is_multiplayer_active()
	var local_ctrl := is_local_controlled()

	# Aplicar perfil de personaje elegido en el lobby
	if is_lan and NetworkManager:
		var char_data: Dictionary = NetworkManager.get_character_data(character_id)
		base_tint = char_data.get("tint", Color(1.0, 1.0, 1.0, 1.0))
		max_health = int(char_data.get("max_health", 20))
		health = max_health
		var speed_mult := float(char_data.get("speed_mult", 1.0))
		max_speed = _base_max_speed * speed_mult
		if movement:
			movement.max_speed = max_speed
		melee_damage = _base_melee_damage + int(char_data.get("melee_bonus", 0))
		if melee_hitbox and "damage" in melee_hitbox:
			melee_hitbox.damage = melee_damage
		ranged_damage_bonus = int(char_data.get("ranged_bonus", 0))
		current_ranged_weapon = int(char_data.get("start_weapon", 0))
		if animated_sprite:
			animated_sprite.modulate = base_tint
		_ensure_name_tag(char_data.get("badge_color", Color(1.0, 0.88, 0.3, 1.0)))

	# Solo el jugador controlado localmente activa su cámara
	if camera:
		camera.enabled = local_ctrl
		if local_ctrl:
			camera.make_current()

	_net_target_pos = global_position

	if local_ctrl:
		health_changed.emit(health, max_health)
		if EventBus:
			EventBus.player_damaged.emit(health, max_health)
			var w_name := "Lanza Inca" if current_ranged_weapon == 1 else "Piedra Ancestral"
			EventBus.ranged_weapon_swapped.emit(w_name)
		if is_lan and NetworkManager:
			NetworkManager.broadcast_local_health(health, max_health, is_dead)


func _ensure_name_tag(badge_color: Color) -> void:
	if _name_tag == null:
		_name_tag = Label.new()
		_name_tag.name = "PlayerNameTag"
		_name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_tag.position = Vector2(-70, -78)
		_name_tag.custom_minimum_size = Vector2(140, 22)
		_name_tag.add_theme_font_size_override("font_size", 13)
		_name_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_name_tag.add_theme_constant_override("outline_size", 3)
		add_child(_name_tag)
	_name_tag.text = "P%d · %s" % [player_slot, player_display_name]
	_name_tag.add_theme_color_override("font_color", badge_color)


func _ready() -> void:
	add_to_group("player")
	_base_max_speed = max_speed
	_base_melee_damage = melee_damage
	health = max_health

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

	# Configurar loop en pisadas y apagar chispas iniciales
	if sfx_footsteps and sfx_footsteps.stream is AudioStreamMP3:
		(sfx_footsteps.stream as AudioStreamMP3).loop = true

	if solar_sparks:
		solar_sparks.emitting = false

	_apply_network_setup()

func _physics_process(delta: float) -> void:
	if not is_local_controlled():
		_process_remote_puppet(delta)
		return

	if is_dead:
		_stop_footsteps()
		_send_network_state(delta)
		return

	if is_transforming:
		velocity = Vector2.ZERO
		_stop_footsteps()
		_send_network_state(delta)
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
	_update_footsteps()

	if is_dashing:
		_process_dash_ghost_trail(delta)

	_send_network_state(delta)

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
		var current_gravity := gravity
		# Salto variable proporcional: mientras suba y mantenga pulsado salto durante la ventana de impulso
		if is_jumping and velocity.y < 0.0:
			if Input.is_action_pressed("jump") and jump_hold_timer > 0.0:
				current_gravity *= 0.45 # Reduce gravedad para sustentar la elevación proporcional al tiempo presionado
			else:
				is_jumping = false
		velocity.y += current_gravity * delta

func _update_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		is_jumping = false
		jump_hold_timer = 0.0
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	if is_jumping and jump_hold_timer > 0.0:
		jump_hold_timer = max(0.0, jump_hold_timer - delta)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	attack_timer = max(0.0, attack_timer - delta)
	shoot_timer = max(0.0, shoot_timer - delta)

func _trigger_haptic(ms: int) -> void:
	if is_local_controlled() and (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		Input.vibrate_handheld(ms)

func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		is_jumping = true
		jump_hold_timer = max_jump_hold_time
		_trigger_haptic(20)
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
		is_jumping = true
		jump_hold_timer = max_jump_hold_time
		_trigger_haptic(25)
		facing_direction = sign(velocity.x)
		_update_facing()

func _apply_jump_cut() -> void:
	# Al soltar el botón de salto prematuramente mientras asciende, cortar la velocidad hacia arriba
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		is_jumping = false
		if velocity.y < min_jump_velocity:
			velocity.y = min_jump_velocity
		else:
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
		_trigger_haptic(25)

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
# CONTROL DE PISADAS Y MOVIMIENTO SONORO
# ====================================================================
func _update_footsteps() -> void:
	if sfx_footsteps == null:
		return

	# Las pisadas acompañan al movimiento en suelo excepto cuando se encuentra en el aire
	if is_on_floor() and abs(velocity.x) > 20.0 and not is_dashing and not is_attacking and not is_dead and not is_transforming:
		sfx_footsteps.pitch_scale = 1.15 if abs(velocity.x) > 180.0 else 0.95
		if not sfx_footsteps.playing:
			sfx_footsteps.play()
	else:
		if sfx_footsteps.playing:
			sfx_footsteps.stop()

func _stop_footsteps() -> void:
	if sfx_footsteps and sfx_footsteps.playing:
		sfx_footsteps.stop()

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
	_trigger_haptic(22)
	if animated_sprite:
		animated_sprite.play("attack")

	# Sonido de golpe acoplado a la acción
	if sfx_attack:
		sfx_attack.play()

	# Trazo / onda amarilla que acompaña al golpe
	_spawn_attack_wave()

	if NetworkManager and NetworkManager.is_multiplayer_active() and is_local_controlled():
		_rpc_remote_melee.rpc(facing_direction)

	if melee_hitbox:
		melee_hitbox.monitoring = true
		await get_tree().create_timer(0.22).timeout
		if is_instance_valid(melee_hitbox):
			melee_hitbox.monitoring = false

func _spawn_attack_wave() -> void:
	if FX_ATTACK_WAVE_SCENE:
		var wave := FX_ATTACK_WAVE_SCENE.instantiate() as Node2D
		get_parent().add_child(wave)
		wave.global_position = global_position + Vector2(facing_direction * 36.0, -4.0)
		if wave.has_method("setup"):
			wave.setup(facing_direction)

func _execute_ranged_attack() -> void:
	if current_ranged_weapon == 0:
		_throw_stone()
	else:
		_throw_spear()

func _throw_stone() -> void:
	if stone_projectile_scene == null:
		return
	shoot_timer = shoot_cooldown

	var spawn_pos := global_position + Vector2(facing_direction * 28.0, -10.0)
	var bonus_dmg: int = (10 if has_sol_powerup else 0) + ranged_damage_bonus
	_spawn_stone_instance(spawn_pos, facing_direction, bonus_dmg)

	if NetworkManager and NetworkManager.is_multiplayer_active() and is_local_controlled():
		_rpc_remote_projectile.rpc(0, spawn_pos, facing_direction, bonus_dmg)

func _spawn_stone_instance(spawn_pos: Vector2, dir_x: float, bonus_dmg: int) -> void:
	var stone := ProjectilePool.acquire(stone_projectile_scene, get_tree().current_scene, spawn_pos) as StoneProjectile
	if stone == null:
		return
	stone.damage = 15 + bonus_dmg
	stone.launch(Vector2(dir_x * stone_speed_x, stone_speed_y))

func _throw_spear() -> void:
	if spear_projectile_scene == null:
		return
	shoot_timer = shoot_cooldown + 0.15

	var spawn_pos := global_position + Vector2(facing_direction * 32.0, -8.0)
	var bonus_dmg: int = (15 if has_sol_powerup else 0) + ranged_damage_bonus
	_spawn_spear_instance(spawn_pos, facing_direction, bonus_dmg)

	if NetworkManager and NetworkManager.is_multiplayer_active() and is_local_controlled():
		_rpc_remote_projectile.rpc(1, spawn_pos, facing_direction, bonus_dmg)

func _spawn_spear_instance(spawn_pos: Vector2, dir_x: float, bonus_dmg: int) -> void:
	var spear := ProjectilePool.acquire(spear_projectile_scene, get_tree().current_scene, spawn_pos) as SpearProjectile
	if spear == null:
		return
	spear.damage = 30 + bonus_dmg
	spear.launch(Vector2(dir_x, 0.0))

# ====================================================================
# POWER-UP DEL SOL Y SKINS DINÁMICOS
# ====================================================================
func apply_powerup_sol() -> void:
	if is_transforming or is_dead:
		return

	var local_ctrl := is_local_controlled()
	if NetworkManager and NetworkManager.is_multiplayer_active() and local_ctrl:
		_rpc_remote_powerup_sol.rpc(sol_duration)

	# Pausa de movimiento e inmunidad estilo Super Mario durante la transformación
	is_transforming = true
	is_invulnerable = true
	is_dashing = false
	is_attacking = false
	velocity = Vector2.ZERO
	_stop_footsteps()

	if melee_hitbox:
		melee_hitbox.monitoring = false

	# Curación de 2 puntos (1 corazón)
	health = mini(health + 2, max_health)
	health_changed.emit(health, max_health)
	if local_ctrl:
		if EventBus:
			EventBus.player_damaged.emit(health, max_health)
		if NetworkManager and NetworkManager.is_multiplayer_active():
			NetworkManager.broadcast_local_health(health, max_health, false)

	# Sonido de transformación al transformarse
	if sfx_transform:
		sfx_transform.play()

	# Asegurar parámetros limpios en material para que la animación sea nítida
	if flash_material:
		flash_material.set_shader_parameter("flash_amount", 0.0)

	# Reproducción de la animación de transformación (a velocidad moderada)
	if animated_sprite:
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("transform"):
			animated_sprite.play("transform")
			await animated_sprite.animation_finished
		else:
			await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(1.0).timeout

	if is_dead:
		return

	# Asignar skin y sprites del modo Power Up Sol durante la duración activa
	if sol_frames and animated_sprite:
		animated_sprite.sprite_frames = sol_frames

	# Activar ligeras chispas amarillas como aura de poder activo
	if solar_sparks:
		solar_sparks.emitting = true

	# Culminar estado de transformación y reactivar control
	is_transforming = false
	is_invulnerable = false
	has_sol_powerup = true
	sol_timer = sol_duration

	if local_ctrl:
		if EventBus:
			EventBus.player_powerup_activated.emit(sol_duration)
		# Sacudida de cámara al completar la transformación solar
		_trigger_camera_shake(0.65)

	if animated_sprite:
		animated_sprite.modulate = base_tint
		animated_sprite.play("idle")

## Alias de compatibilidad por si se invoca como activate_power_up_sol
func activate_power_up_sol(duration: float = -1.0) -> void:
	if duration > 0.0:
		sol_duration = duration
	apply_powerup_sol()

func _update_sol_powerup(delta: float) -> void:
	if not has_sol_powerup:
		return

	sol_timer -= delta

	# Parpadeo sutil de advertencia en los últimos 3 segundos
	if sol_timer <= 3.0 and sol_timer > 0.0:
		var blink := fmod(sol_timer * 10.0, 2.0) > 1.0
		if animated_sprite and not is_invulnerable:
			animated_sprite.modulate = Color(1.8, 1.6, 0.8, 1.0) if blink else base_tint

	if sol_timer <= 0.0:
		_remove_sol_powerup()

func _remove_sol_powerup() -> void:
	if is_transforming or is_dead:
		return

	var local_ctrl := is_local_controlled()
	if NetworkManager and NetworkManager.is_multiplayer_active() and local_ctrl:
		_rpc_remote_remove_powerup_sol.rpc()

	# Pausa de movimiento estilo Mario durante la des-transformación
	is_transforming = true
	is_invulnerable = true
	is_dashing = false
	is_attacking = false
	velocity = Vector2.ZERO
	_stop_footsteps()

	if melee_hitbox:
		melee_hitbox.monitoring = false

	# Desactivar chispas del aura solar
	if solar_sparks:
		solar_sparks.emitting = false

	# Sonido de transformación al volver a la normalidad
	if sfx_transform:
		sfx_transform.play()

	# Asegurar colores limpios para reproducir la animación inversa
	if flash_material:
		flash_material.set_shader_parameter("flash_amount", 0.0)

	if animated_sprite:
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("detransform"):
			animated_sprite.play("detransform")
			await animated_sprite.animation_finished
		else:
			await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(1.0).timeout

	if is_dead:
		return

	# Volver a los sprites default de Cahuide
	if normal_frames and animated_sprite:
		animated_sprite.sprite_frames = normal_frames
	if animated_sprite:
		animated_sprite.modulate = base_tint
		animated_sprite.play("idle")

	has_sol_powerup = false
	is_transforming = false
	is_invulnerable = false

	if local_ctrl and EventBus:
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
	if is_invulnerable or is_dead or is_transforming:
		return

	# En multijugador: si el Host detecta daño sobre el jugador remoto, lo reenvía al dueño
	if NetworkManager and NetworkManager.is_multiplayer_active() and not is_local_controlled():
		if multiplayer.is_server():
			_rpc_apply_damage.rpc_id(get_multiplayer_authority(), amount, knockback)
		return

	var applied := _calculate_mitigated_damage(amount)
	if applied <= 0:
		return

	health = maxi(0, health - applied)
	health_changed.emit(health, max_health)

	if EventBus:
		EventBus.player_damaged.emit(health, max_health)

	if NetworkManager and NetworkManager.is_multiplayer_active():
		NetworkManager.broadcast_local_health(health, max_health, health <= 0)
		_rpc_remote_damage_fx.rpc()

	if knockback != Vector2.ZERO:
		velocity = knockback

	# Sacudida paramétrica de cámara al recibir daño según especificación
	_trigger_camera_shake(0.55)
	_trigger_haptic(55)

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
	if camera and camera.enabled and camera.has_method("trigger_shake"):
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
	is_transforming = false
	velocity = Vector2.ZERO
	_stop_footsteps()
	if solar_sparks:
		solar_sparks.emitting = false
	player_died.emit()
	if is_local_controlled():
		if NetworkManager and NetworkManager.is_multiplayer_active():
			NetworkManager.broadcast_local_health(0, max_health, true)
		elif EventBus:
			EventBus.player_died.emit()
	if animated_sprite:
		animated_sprite.play("dead")

func respawn_at(new_position: Vector2) -> void:
	global_position = new_position
	_net_target_pos = new_position
	velocity = Vector2.ZERO
	is_dead = false
	is_attacking = false
	is_invulnerable = false
	is_transforming = false
	has_sol_powerup = false
	_stop_footsteps()
	if solar_sparks:
		solar_sparks.emitting = false
	if normal_frames and animated_sprite:
		animated_sprite.sprite_frames = normal_frames
	health = max_health
	health_changed.emit(health, max_health)
	if is_local_controlled():
		if EventBus:
			EventBus.player_damaged.emit(health, max_health)
		if NetworkManager and NetworkManager.is_multiplayer_active():
			NetworkManager.broadcast_local_health(health, max_health, false)
			_rpc_remote_respawn.rpc(new_position)
	if animated_sprite:
		animated_sprite.visible = true
		animated_sprite.modulate = base_tint
		animated_sprite.play("idle")

# ====================================================================
# ANIMACIONES
# ====================================================================
func _update_animations() -> void:
	if is_dead or is_attacking or is_transforming or animated_sprite == null:
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

# ====================================================================
# SINCRONIZACIÓN DE RED LAN (Paquetes ligeros + Interpolación + RPCs)
# ====================================================================
func _get_current_anim_index() -> int:
	if animated_sprite == null:
		return 0
	var idx := NET_ANIM_NAMES.find(String(animated_sprite.animation))
	return idx if idx >= 0 else 0

func _send_network_state(delta: float) -> void:
	if NetworkManager == null or not NetworkManager.is_multiplayer_active():
		return
	_net_sync_accum += delta
	var anim_idx := _get_current_anim_index()
	var changed := (anim_idx != _net_last_anim_idx) or (facing_direction != _net_last_facing)
	if _net_sync_accum < NET_SYNC_INTERVAL and not changed:
		return
	_net_sync_accum = 0.0
	_net_last_anim_idx = anim_idx
	_net_last_facing = facing_direction
	var flags: int = (1 if has_sol_powerup else 0) | (2 if is_dashing else 0) | (4 if is_dead else 0)
	_rpc_sync_state.rpc(global_position, velocity, facing_direction, anim_idx, flags)

func _process_remote_puppet(delta: float) -> void:
	# Corrección instantánea si hay gran desincronización (ej. respawn o teletransporte)
	if global_position.distance_to(_net_target_pos) > 180.0:
		global_position = _net_target_pos
	else:
		global_position = global_position.lerp(_net_target_pos, clampf(delta * 18.0, 0.0, 1.0))

	if is_dashing:
		_process_dash_ghost_trail(delta)

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sync_state(pos: Vector2, vel: Vector2, facing: float, anim_idx: int, flags: int) -> void:
	_net_target_pos = pos
	velocity = vel
	facing_direction = facing
	_update_facing()

	var sol_flag := (flags & 1) != 0
	is_dashing = (flags & 2) != 0
	is_dead = (flags & 4) != 0

	if sol_flag != has_sol_powerup and not is_transforming:
		has_sol_powerup = sol_flag
		if animated_sprite:
			animated_sprite.sprite_frames = sol_frames if has_sol_powerup else normal_frames
		if solar_sparks:
			solar_sparks.emitting = has_sol_powerup

	if animated_sprite and anim_idx >= 0 and anim_idx < NET_ANIM_NAMES.size():
		var target_anim := NET_ANIM_NAMES[anim_idx]
		if animated_sprite.animation != target_anim and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(target_anim):
			animated_sprite.play(target_anim)

@rpc("authority", "call_remote", "reliable")
func _rpc_remote_melee(facing: float) -> void:
	facing_direction = facing
	_update_facing()
	if animated_sprite:
		animated_sprite.play("attack")
	if sfx_attack:
		sfx_attack.play()
	_spawn_attack_wave()
	# En el Host activamos brevemente el MeleeHitbox del cliente para validar daño contra enemigos
	if multiplayer.is_server() and melee_hitbox:
		melee_hitbox.monitoring = true
		await get_tree().create_timer(0.22).timeout
		if is_instance_valid(melee_hitbox):
			melee_hitbox.monitoring = false

@rpc("authority", "call_remote", "reliable")
func _rpc_remote_projectile(weapon_type: int, spawn_pos: Vector2, dir_x: float, bonus_dmg: int) -> void:
	if weapon_type == 0:
		_spawn_stone_instance(spawn_pos, dir_x, bonus_dmg)
	else:
		_spawn_spear_instance(spawn_pos, dir_x, bonus_dmg)

@rpc("authority", "call_remote", "reliable")
func _rpc_remote_powerup_sol(duration: float) -> void:
	sol_duration = duration
	apply_powerup_sol()

@rpc("authority", "call_remote", "reliable")
func _rpc_remote_remove_powerup_sol() -> void:
	_remove_sol_powerup()

@rpc("authority", "call_remote", "reliable")
func _rpc_remote_damage_fx() -> void:
	_play_damage_flash()
	if animated_sprite and not is_dead:
		animated_sprite.play("hurt")

@rpc("authority", "call_remote", "reliable")
func _rpc_remote_respawn(new_pos: Vector2) -> void:
	respawn_at(new_pos)

@rpc("any_peer", "call_local", "reliable")
func _rpc_apply_damage(amount: int, knockback: Vector2) -> void:
	# Solo aceptamos daño reenviado desde el Host (peer 1)
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	if is_local_controlled():
		take_direct_damage(amount, knockback)
