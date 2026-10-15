class_name Player
extends CharacterBody2D

## Controlador de Cahuide con AnimatedSprite2D y animaciones fluidas

signal health_changed(new_health: int, max_health: int)
signal player_died

@export_category("Health & Stats")
# 20 de salud total = 10 corazones (cada corazón maneja 2 puntos: vacío, medio, lleno)
@export var max_health: int = 20
var health: int = 20

@export_category("Horizontal Movement")
@export var max_speed: float = 260.0
@export var acceleration: float = 1600.0
@export var deceleration: float = 1900.0

@export_category("Jump")
@export var gravity: float = 1350.0
@export var jump_velocity: float = -570.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var jump_cut_multiplier: float = 0.5

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

@export_category("Wall")
@export var wall_slide_speed: float = 110.0
@export var wall_jump_horizontal_speed: float = 310.0
@export var wall_jump_vertical_speed: float = -620.0

@export_category("Dash")
@export var dash_speed: float = 650.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.45

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

@export_category("Combat")
@export var melee_damage: int = 25
@export var shoot_damage: int = 20
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
@export var attack_cooldown: float = 0.4
@export var shoot_cooldown: float = 0.5

var attack_timer: float = 0.0
var shoot_timer: float = 0.0
var facing_direction: float = 1.0 # 1 derecha, -1 izquierda
var is_invulnerable: bool = false
var is_attacking: bool = false
var is_dead: bool = false

# --- POWER-UP DEL SOL ---
var has_sol_powerup: bool = false
@export var sol_duration: float = 15.0 # Duración actualizada a 15 segundos
var sol_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var melee_hitbox: Hitbox = $MeleeHitbox
@onready var hurtbox: Hurtbox = $Hurtbox

# PROYECTIL - PIEDRA #
@export var stone_projectile_scene: PackedScene
@export var stone_speed_x: float = 420.0
@export var stone_speed_y: float = -380.0
@export var stone_cooldown: float = 0.8

var stone_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)
	
	if melee_hitbox:
		melee_hitbox.damage = melee_damage
		melee_hitbox.is_enemy_hitbox = false
		melee_hitbox.monitoring = false
		
	if hurtbox:
		hurtbox.is_enemy_hurtbox = false
		hurtbox.received_damage.connect(_on_received_damage)
		
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_animation_finished)
		animated_sprite.play("idle")

func apply_powerup_sol() -> void:
	has_sol_powerup = true
	sol_timer = sol_duration
	
	# Curamos 2 puntos (1 corazón) si está herido, pero sin alterar max_health para no romper el HUD
	health = min(health + 2, max_health)
	health_changed.emit(health, max_health)
	
	# Modulación dorada resplandeciente
	if animated_sprite:
		animated_sprite.modulate = Color(2.2, 1.8, 0.4, 1.0)

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
	
	_handle_combat_inputs()
	_update_animations()

func _update_sol_powerup(delta: float) -> void:
	if not has_sol_powerup:
		return
		
	sol_timer -= delta
	
	# Parpadeo de advertencia cuando quedan 3 segundos o menos
	if sol_timer <= 3.0 and sol_timer > 0.0:
		var blink = fmod(sol_timer * 10.0, 2.0) > 1.0
		if animated_sprite and not is_invulnerable:
			animated_sprite.modulate = Color(2.5, 2.0, 0.5, 1.0) if blink else Color(1, 1, 1, 1)
	
	# Fin del efecto al llegar a 0
	if sol_timer <= 0.0:
		_remove_sol_powerup()

func _remove_sol_powerup() -> void:
	has_sol_powerup = false
	
	# Restablecer tono normal
	if animated_sprite and not is_invulnerable:
		animated_sprite.modulate = Color(1, 1, 1, 1)
		
	# Quitar la resistencia extra otorgada
	max_health = max(1, max_health - 1)
	health = min(health, max_health)
	health_changed.emit(health, max_health)

func _update_timers(delta: float) -> void:
	_update_coyote_time(delta)
	_update_jump_buffer(delta)
	attack_timer = max(0.0, attack_timer - delta)
	shoot_timer = max(0.0, shoot_timer - delta)
	stone_timer = maxf(0.0, stone_timer - delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _update_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * max_speed
	
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		facing_direction = sign(direction)
		_update_facing()
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _update_facing() -> void:
	if animated_sprite:
		animated_sprite.flip_h = (facing_direction < 0)
	if melee_hitbox:
		melee_hitbox.position.x = facing_direction * 38.0

func _update_animations() -> void:
	if is_dead or is_attacking:
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
	if animated_sprite.animation == "attack":
		is_attacking = false
	elif animated_sprite.animation == "hurt":
		is_attacking = false

func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

func _update_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		if not is_attacking:
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

func _try_start_dash() -> void:
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and not is_dead:
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1.8, 1.8, 2.0, 0.5), 0.08)
		var restore_color = Color(2.2, 1.8, 0.4, 1.0) if has_sol_powerup else Color(1, 1, 1, 1)
		tween.tween_property(animated_sprite, "modulate", restore_color, 0.08)

func _update_dash(delta: float) -> void:
	dash_cooldown_timer = max(0.0, dash_cooldown_timer - delta)
	if not is_dashing:
		return
	
	dash_timer -= delta
	velocity.x = facing_direction * dash_speed
	velocity.y = 0.0
	
	if dash_timer <= 0.0:
		is_dashing = false

func _handle_combat_inputs() -> void:
	if Input.is_action_just_pressed("attack") and attack_timer <= 0.0 and not is_attacking:
		_execute_melee_attack()
		
	if Input.is_action_just_pressed("shoot"):
		if has_sol_powerup:
			_shoot_projectile()
		elif shoot_timer <= 0.0:
			_shoot_projectile()
			
	if Input.is_action_just_pressed("stone_shoot") and stone_timer <= 0.0:
		_throw_stone()
		
func _execute_melee_attack() -> void:
	attack_timer = attack_cooldown
	is_attacking = true
	animated_sprite.play("attack")
	
	if melee_hitbox:
		melee_hitbox.monitoring = true
		await get_tree().create_timer(0.22).timeout
		if is_instance_valid(melee_hitbox):
			melee_hitbox.monitoring = false

func _shoot_projectile() -> void:
	if not projectile_scene:
		return
		
	shoot_timer = shoot_cooldown
	
	var proj = projectile_scene.instantiate() as Projectile
	if not proj:
		return
		
	proj.is_enemy_projectile = false
	proj.damage = shoot_damage
	proj.speed = 520.0
	
	var shoot_dir = Vector2(facing_direction, 0.0)
	proj.set_direction(shoot_dir)
	
	proj.global_position = global_position + Vector2(facing_direction * 30.0, -10.0)
	get_tree().current_scene.add_child(proj)
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(2.8, 2.2, 0.8, 1), 0.08)
	var restore_color = Color(2.2, 1.8, 0.4, 1.0) if has_sol_powerup else Color(1, 1, 1, 1)
	tween.tween_property(animated_sprite, "modulate", restore_color, 0.12)


func _throw_stone() -> void:
	if stone_projectile_scene == null:
		return

	var stone := stone_projectile_scene.instantiate() as StoneProjectile
	if stone == null:
		return

	var direction := facing_direction
	get_tree().current_scene.add_child(stone)
	stone.global_position = global_position + Vector2(direction * 25.0, -10.0)
	stone.launch(Vector2(direction * stone_speed_x, stone_speed_y))
	stone_timer = stone_cooldown

	# Velocidad horizontal según la dirección de Cahuide.
	# La velocidad vertical negativa hace que la piedra suba.
	stone.launch(Vector2(
		direction * stone_speed_x,
		stone_speed_y
	))

func _on_received_damage(amount: int, knockback: Vector2) -> void:
	take_direct_damage(amount, knockback)

	# Si NO tiene el power-up activo, funciona normal:
	var final_damage = clamp(amount, 1, 2)
	take_direct_damage(final_damage, knockback)

func take_direct_damage(amount: int = 1, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or is_dead:
		return
		
	var damage_to_apply = amount
	
	# --- LÓGICA REFORZADA DEL POWER-UP DEL SOL ---
	if has_sol_powerup:
		# Si el daño es de espada/cuerpo a cuerpo (1 punto), INMUNE (0 daño)
		if amount <= 1:
			return
		# Si el daño es de flecha/proyectil (2 puntos o más), REDUCIR A MEDIO CORAZÓN (1 punto)
		else:
			damage_to_apply = 1
	else:
		# Daño normal del juego cuando no hay power-up
		damage_to_apply = clamp(amount, 1, 2)
		
	health = max(0, health - damage_to_apply)
	health_changed.emit(health, max_health)
	
	if knockback != Vector2.ZERO:
		velocity = knockback
		
	if health <= 0:
		_die()
		return
		
	is_attacking = false
	animated_sprite.play("hurt")
	
	is_invulnerable = true
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(2.5, 0.3, 0.3, 0.7), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color(2.5, 0.3, 0.3, 0.7), 0.1)
	
	var restore_color = Color(2.2, 1.8, 0.4, 1.0) if has_sol_powerup else Color(1, 1, 1, 1)
	tween.tween_property(animated_sprite, "modulate", restore_color, 0.1)
	
	await get_tree().create_timer(0.45).timeout
	is_invulnerable = false

func _die() -> void:
	is_dead = true
	player_died.emit()
	velocity = Vector2.ZERO
	animated_sprite.play("dead")
