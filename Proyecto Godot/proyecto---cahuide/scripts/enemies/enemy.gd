class_name Enemy
extends CharacterBody2D

## HU03 — Crear enemigos y comportamiento básico
## Controlador con AnimatedSprite2D y State Pattern / FSM

signal enemy_defeated(enemy_node: Enemy)

const DAMAGE_FLASH_MAT: Material = preload("res://materials/mat_damage_flash.tres")
const DISSOLVE_MAT: Material = preload("res://materials/mat_dissolve.tres")
const DEATH_BURST_SCENE: PackedScene = preload("res://scenes/vfx/fx_death_burst.tscn")
const HIT_SPARKS_SCENE: PackedScene = preload("res://scenes/vfx/fx_hit_sparks.tscn")
const ENEMY_ANIM_NAMES: PackedStringArray = ["idle", "walk", "run", "attack", "shoot", "hurt", "dead"]
const ENEMY_SYNC_INTERVAL: float = 0.05 # 20 Hz ligero desde el Host

@export_category("Enemy Stats (HU03)")
@export var enemy_name: String = "Soldado Español"
@export var max_health: int = 40
# Daño Melee por defecto: 1 punto (medio corazón)
@export var damage: int = 1
@export var score_value: int = 100 # Puntos otorgados al morir
@export var patrol_speed: float = 75.0
@export var chase_speed: float = 150.0
@export var gravity: float = 1200.0

@export_category("Combat & Ranged (HU04)")
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
@export var projectile_speed: float = 400.0
# Daño del Proyectil / Flecha: 2 puntos (1 corazón entero)
@export var ranged_damage: int = 2
@export var attack_cooldown: float = 1.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_machine: EnemyStateMachine = $StateMachine
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = get_node_or_null("Hitbox")
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var wall_detector: RayCast2D = $WallDetector

var health: int = 40
var direction: float = -1.0 # -1 izquierda, 1 derecha
var player: CharacterBody2D = null
var is_dead: bool = false
var _defeat_signal_emitted: bool = false
var flash_material: ShaderMaterial
var dissolve_material: ShaderMaterial

# Sincronización LAN (Host-Authoritative)
var _net_sync_accum: float = 0.0
var _net_target_pos: Vector2 = Vector2.ZERO
var _net_target_refresh: float = 0.0
var _closest_player_dist: float = 9999.0
var _last_synced_pos: Vector2 = Vector2.ZERO
var _last_synced_anim: int = -1
var _last_synced_hp: int = -1

func _is_network_client() -> bool:
	return NetworkManager != null and NetworkManager.is_multiplayer_active() and not multiplayer.is_server()

func _ready() -> void:
	add_to_group("enemies")

	# Aplicar multiplicadores de dificultad si estamos en partida LAN
	if NetworkManager and NetworkManager.is_multiplayer_active():
		var diff: Dictionary = NetworkManager.get_difficulty_data()
		max_health = maxi(10, int(round(float(max_health) * float(diff.get("enemy_hp_mult", 1.0)))))
		var spd_mult := float(diff.get("enemy_speed_mult", 1.0))
		patrol_speed *= spd_mult
		chase_speed *= spd_mult

	health = max_health
	_net_target_pos = global_position

	if DAMAGE_FLASH_MAT:
		flash_material = DAMAGE_FLASH_MAT.duplicate() as ShaderMaterial
		if animated_sprite:
			animated_sprite.material = flash_material
	if DISSOLVE_MAT:
		dissolve_material = DISSOLVE_MAT.duplicate() as ShaderMaterial
	
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	
	# Configurar Hitbox para ataque Melee (1 punto = medio corazón)
	if hitbox:
		hitbox.damage = damage
		hitbox.is_enemy_hitbox = true
		hitbox.monitoring = false
	
	# Conectar Hurtbox
	if hurtbox:
		hurtbox.is_enemy_hurtbox = true
		hurtbox.received_damage.connect(_on_received_damage)

	# En Cliente LAN: el Host es dueño de la IA, físicas y ataques; el Cliente solo interpola
	if _is_network_client():
		if state_machine:
			state_machine.set_process(false)
			state_machine.set_physics_process(false)
		if detection_area:
			detection_area.monitoring = false
		if attack_area:
			attack_area.monitoring = false
		set_facing(direction)
		return
		
	# Conectar áreas de detección
	if detection_area:
		detection_area.body_entered.connect(_on_player_entered_detection)
		detection_area.body_exited.connect(_on_player_exited_detection)
		
	if attack_area:
		attack_area.body_entered.connect(_on_player_entered_attack)
		attack_area.body_exited.connect(_on_player_exited_attack)
	
	# Iniciar State Machine
	if state_machine:
		state_machine.init(self)
		
	# Orientación inicial
	set_facing(direction)

func _physics_process(delta: float) -> void:
	if NetworkManager == null or not NetworkManager.is_multiplayer_active():
		return

	if _is_network_client():
		if is_dead:
			return
		if global_position.distance_to(_net_target_pos) > 160.0:
			global_position = _net_target_pos
		else:
			global_position = global_position.lerp(_net_target_pos, clampf(delta * 16.0, 0.0, 1.0))
		return

	# En el Host: reevaluar jugador vivo más cercano y emitir snapshots ligeros
	_net_target_refresh += delta
	if _net_target_refresh >= 0.4 and not is_dead:
		_net_target_refresh = 0.0
		_refresh_closest_player()

	_net_sync_accum += delta
	# Area of Interest (AoI): Si está lejos de ambos jugadores (> 650px), sincronizar a 2.5 Hz (0.4s)
	# para ahorrar hasta un 80% de ancho de banda y CPU en móviles; a corta distancia sincroniza a 20 Hz
	var sync_interval := 0.4 if _closest_player_dist > 650.0 else ENEMY_SYNC_INTERVAL
	if _net_sync_accum >= sync_interval:
		_net_sync_accum = 0.0
		var anim_idx := _get_enemy_anim_index()
		# Si está lejos y no ha cambiado posición ni animación ni vida, descartar paquete redundante
		if _closest_player_dist > 650.0 and global_position.distance_to(_last_synced_pos) < 2.0 and anim_idx == _last_synced_anim and health == _last_synced_hp:
			return
		_last_synced_pos = global_position
		_last_synced_anim = anim_idx
		_last_synced_hp = health
		_rpc_sync_enemy_state.rpc(global_position, direction, anim_idx, health, is_dead)

func _refresh_closest_player() -> void:
	var best_player: CharacterBody2D = null
	var best_dist: float = 520.0 if is_ranged else 340.0
	_closest_player_dist = 9999.0
	for node in get_tree().get_nodes_in_group("player"):
		var p := node as CharacterBody2D
		if p == null or not is_instance_valid(p):
			continue
		var d := global_position.distance_to(p.global_position)
		if d < _closest_player_dist:
			_closest_player_dist = d
		if "is_dead" in p and p.is_dead:
			continue
		if d < best_dist:
			best_dist = d
			best_player = p
	if best_player != null:
		player = best_player
	elif player != null and ("is_dead" in player and player.is_dead):
		player = null

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func set_facing(new_dir: float) -> void:
	direction = new_dir
	if animated_sprite:
		# Si mirando a la derecha se ve al revés, cambia '>' por '<'
		animated_sprite.flip_h = (direction < 0)
	
	# Ajustar posición de RayCasts y Hitbox al encarar
	if floor_detector:
		floor_detector.position.x = direction * 28.0
	if wall_detector:
		wall_detector.target_position.x = direction * 35.0
	if hitbox:
		hitbox.position.x = direction * 32.0

func flip_direction() -> void:
	set_facing(-direction)

func is_at_edge_or_wall() -> bool:
	if is_on_wall():
		return true
	if wall_detector and wall_detector.is_colliding():
		return true
	if is_on_floor() and floor_detector and not floor_detector.is_colliding():
		return true
	return false

func can_see_player() -> bool:
	return player != null and is_instance_valid(player)

func is_player_in_attack_range() -> bool:
	if not can_see_player():
		return false
	var dist = global_position.distance_to(player.global_position)
	if is_ranged:
		return dist <= 380.0
	return dist <= 75.0

func execute_attack() -> void:
	if is_ranged:
		_shoot_projectile()
	else:
		_execute_melee_attack()

func _execute_melee_attack() -> void:
	if hitbox:
		hitbox.damage = damage # Asegura el daño melee (1 de daño)
		hitbox.monitoring = true
		await get_tree().create_timer(0.28).timeout
		if is_instance_valid(hitbox):
			hitbox.monitoring = false

func _shoot_projectile() -> void:
	if not projectile_scene or not can_see_player():
		return

	var shoot_dir := (player.global_position - global_position).normalized()
	var spawn_pos := global_position + Vector2(direction * 40.0, -10.0)
	_spawn_enemy_projectile(spawn_pos, shoot_dir, projectile_speed, true)

	if NetworkManager and NetworkManager.is_multiplayer_active() and multiplayer.is_server():
		_rpc_spawn_enemy_projectile.rpc(spawn_pos, shoot_dir, projectile_speed)

func _spawn_enemy_projectile(spawn_pos: Vector2, shoot_dir: Vector2, spd: float, authoritative: bool) -> void:
	if not projectile_scene:
		return
	var proj := ProjectilePool.acquire(projectile_scene, get_tree().current_scene, spawn_pos) as Projectile
	if not proj:
		return
	proj.is_enemy_projectile = true
	proj.damage = ranged_damage if authoritative else 0
	proj.speed = spd
	proj.set_direction(shoot_dir)
	if not authoritative:
		# Visual en cliente; el Host aplica el daño real para evitar impactos duplicados
		proj.set_deferred("monitoring", false)
		proj.set_deferred("monitorable", false)

func _on_received_damage(amount: int, knockback: Vector2) -> void:
	if _is_network_client():
		return
	print(
		"[DAÑO ENEMIGO - HURTBOX] ",
		enemy_name,
		" | Cantidad recibida: ", amount
	)
	take_direct_damage(amount, knockback)

func take_direct_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if _is_network_client():
		return
	if is_dead or health <= 0:
		return

	var vida_anterior: int = health
	health = max(0, health - amount)

	print(
		"[DAÑO ENEMIGO] ", enemy_name,
		" | Daño recibido: ", amount,
		" | Vida anterior: ", vida_anterior,
		" | Vida actual: ", health
	)

	if health_bar:
		health_bar.value = health

	_play_damage_flash()
	_spawn_hit_sparks(knockback)

	if knockback != Vector2.ZERO:
		velocity.x = knockback.x
		velocity.y = min(velocity.y, knockback.y)

	if health <= 0:
		is_dead = true
		_spawn_death_burst()
		if state_machine:
			state_machine.transition_to("dead")
	else:
		if state_machine:
			state_machine.transition_to("hurt")

	if NetworkManager and NetworkManager.is_multiplayer_active() and multiplayer.is_server():
		_rpc_enemy_damaged.rpc(health, is_dead, knockback)

func _play_damage_flash() -> void:
	if flash_material:
		flash_material.set_shader_parameter("flash_amount", 1.0)
		var tween := create_tween()
		tween.tween_method(
			func(val: float): flash_material.set_shader_parameter("flash_amount", val),
			1.0, 0.0, 0.15
		)

func _spawn_hit_sparks(dir: Vector2) -> void:
	if HIT_SPARKS_SCENE:
		var sparks := HIT_SPARKS_SCENE.instantiate() as Node2D
		get_tree().current_scene.add_child(sparks)
		sparks.global_position = global_position + Vector2(0, -12)
		if sparks.has_method("orient_to_direction"):
			sparks.orient_to_direction(dir.normalized() if dir != Vector2.ZERO else Vector2.UP)

func _spawn_death_burst() -> void:
	if DEATH_BURST_SCENE:
		var burst := DEATH_BURST_SCENE.instantiate() as Node2D
		get_tree().current_scene.add_child(burst)
		burst.global_position = global_position + Vector2(0, -16)

func disable_collisions() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	if health_bar:
		health_bar.visible = false

func play_animation(anim_name: String) -> void:
	if not animated_sprite:
		return
		
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		# Fallback para ballestero si no tiene "run", usa "walk"
		if anim_name == "run" and animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")
			
	match anim_name:
		"hurt":
			# Destello de daño
			var tween = create_tween()
			tween.tween_property(animated_sprite, "modulate", Color(2.5, 0.4, 0.4, 1), 0.08)
			tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.15)
		"dead":
			animated_sprite.modulate = Color(0.8, 0.3, 0.3, 0.8)
		_:
			animated_sprite.modulate = Color(1, 1, 1, 1)

## Patrón Observador (Observer Pattern):
## El enemigo notifica su derrota mediante la señal 'enemy_defeated' sin acoplarse
## directamente a la UI o al HUD. Los controladores (Nivel o GameManager) se encargan del puntaje y bajas.
func emit_defeat() -> void:
	if _defeat_signal_emitted:
		return
	_defeat_signal_emitted = true
	enemy_defeated.emit(self)
	if GameState:
		GameState.register_enemy_kill(score_value)
		if NetworkManager and NetworkManager.is_multiplayer_active() and multiplayer.is_server():
			NetworkManager.host_broadcast_score(GameState.score, GameState.enemies_killed)
	elif EventBus:
		EventBus.enemy_defeated.emit(score_value)

func _get_enemy_anim_index() -> int:
	if animated_sprite == null:
		return 0
	var idx := ENEMY_ANIM_NAMES.find(String(animated_sprite.animation))
	return idx if idx >= 0 else 0

@rpc("authority", "call_remote", "unreliable_ordered")
func _rpc_sync_enemy_state(pos: Vector2, dir: float, anim_idx: int, hp: int, dead_flag: bool) -> void:
	_net_target_pos = pos
	set_facing(dir)
	health = hp
	if health_bar:
		health_bar.value = hp
	if animated_sprite and anim_idx >= 0 and anim_idx < ENEMY_ANIM_NAMES.size():
		var target_anim := ENEMY_ANIM_NAMES[anim_idx]
		if animated_sprite.animation != target_anim and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(target_anim):
			animated_sprite.play(target_anim)
	if dead_flag and not is_dead:
		is_dead = true
		disable_collisions()

@rpc("authority", "call_remote", "reliable")
func _rpc_enemy_damaged(new_hp: int, dead_flag: bool, knockback: Vector2) -> void:
	health = new_hp
	if health_bar:
		health_bar.value = new_hp
	_play_damage_flash()
	_spawn_hit_sparks(knockback)
	if dead_flag and not is_dead:
		is_dead = true
		disable_collisions()
		_spawn_death_burst()
		play_animation("dead")
		if EventBus:
			EventBus.enemy_defeated.emit(score_value)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.7)
		tween.tween_callback(queue_free)

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_enemy_projectile(spawn_pos: Vector2, shoot_dir: Vector2, spd: float) -> void:
	_spawn_enemy_projectile(spawn_pos, shoot_dir, spd, false)

func _on_player_entered_detection(body: Node2D) -> void:
	if body.is_in_group("player") and body is CharacterBody2D:
		player = body as CharacterBody2D
		if state_machine and (state_machine.current_state is EnemyStateIdle or state_machine.current_state is EnemyStatePatrol):
			state_machine.transition_to("chase")

func _on_player_exited_detection(_body: Node2D) -> void:
	pass

func _on_player_entered_attack(body: Node2D) -> void:
	if body == player:
		if state_machine and state_machine.current_state is EnemyStateChase:
			state_machine.transition_to("attack")

func _on_player_exited_attack(_body: Node2D) -> void:
	pass
