class_name Enemy
extends CharacterBody2D

## HU03 — Crear enemigos y comportamiento básico
## Controlador con AnimatedSprite2D y State Pattern / FSM

signal enemy_defeated(enemy_node: Enemy)

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
@onready var hitbox: Hitbox = $Hitbox
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var floor_detector: RayCast2D = $FloorDetector
@onready var wall_detector: RayCast2D = $WallDetector

var health: int = 40
var direction: float = -1.0 # -1 izquierda, 1 derecha
var player: CharacterBody2D = null

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	
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
		
	var proj = projectile_scene.instantiate() as Projectile
	if not proj:
		return
		
	proj.is_enemy_projectile = true
	proj.damage = ranged_damage # Se asigna 2 de daño (1 corazón entero)
	proj.speed = projectile_speed
	
	# Dirección apuntando hacia Cahuide
	var shoot_dir = (player.global_position - global_position).normalized()
	proj.set_direction(shoot_dir)
	
	# Aparecer delante del ballestero
	proj.global_position = global_position + Vector2(direction * 40.0, -10.0)
	
	get_tree().current_scene.add_child(proj)

func _on_received_damage(amount: int, knockback: Vector2) -> void:
	take_direct_damage(amount, knockback)

func take_direct_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if health <= 0:
		return
		
	health = max(0, health - amount)
	if health_bar:
		health_bar.value = health
		
	# Aplicar knockback físico
	if knockback != Vector2.ZERO:
		velocity.x = knockback.x
		velocity.y = min(velocity.y, knockback.y)
		
	# Cambiar a estado HURT o DEAD
	if health <= 0:
		_on_death()
		if state_machine:
			state_machine.transition_to("dead")
	else:
		if state_machine:
			state_machine.transition_to("hurt")

func _on_death() -> void:
	# Sumar el puntaje y la baja al HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if not hud:
		hud = get_tree().current_scene.get_node_or_null("HUD")
		
	if hud:
		if hud.has_method("add_score"):
			hud.add_score(score_value)
		if hud.has_method("add_enemy_defeated"):
			hud.add_enemy_defeated()

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

func emit_defeat() -> void:
	enemy_defeated.emit(self)

func _on_player_entered_detection(body: Node2D) -> void:
	if body.is_in_group("player") and body is CharacterBody2D:
		player = body as CharacterBody2D
		if state_machine and (state_machine.current_state is EnemyStateIdle or state_machine.current_state is EnemyStatePatrol):
			state_machine.transition_to("chase")

func _on_player_exited_detection(body: Node2D) -> void:
	pass

func _on_player_entered_attack(body: Node2D) -> void:
	if body == player:
		if state_machine and state_machine.current_state is EnemyStateChase:
			state_machine.transition_to("attack")

func _on_player_exited_attack(body: Node2D) -> void:
	pass
