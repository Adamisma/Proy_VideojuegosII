class_name Hazard
extends Area2D

## Obstáculo que daña al jugador o enemigos al contacto (HU05)

@export var damage: int = 2
@export var enemy_damage: int = 15
@export var knockback_up: float = -420.0
@export var knockback_x: float = 140.0

var _target_cooldowns: Dictionary = {}
const DAMAGE_INTERVAL_MS: int = 400

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_apply_hazard_damage(body)

func _on_body_entered(body: Node2D) -> void:
	_apply_hazard_damage(body)

func _on_body_exited(body: Node2D) -> void:
	if body and is_instance_valid(body):
		_target_cooldowns.erase(body.get_instance_id())

func _apply_hazard_damage(body: Node2D) -> void:
	if body == null or not is_instance_valid(body):
		return
	if not body.has_method("take_direct_damage"):
		return

	# Control de intervalo para evitar daño excesivo por cada frame físico
	var body_id := body.get_instance_id()
	var now := Time.get_ticks_msec()
	if _target_cooldowns.has(body_id):
		if now - _target_cooldowns[body_id] < DAMAGE_INTERVAL_MS:
			return

	# En multijugador LAN:
	# - El Player remoto es procesado por su propio dueño local
	if body is Player and not body.is_local_controlled():
		return
	# - Los enemigos son procesados por el Host (dueño de la simulación de enemigos)
	if body is Enemy and NetworkManager and NetworkManager.is_multiplayer_active() and not multiplayer.is_server():
		return

	_target_cooldowns[body_id] = now

	var dir_x: float = sign(body.global_position.x - global_position.x)
	if dir_x == 0.0:
		dir_x = -1.0

	var applied_damage: int = enemy_damage if body is Enemy else damage
	var impulse := Vector2(dir_x * knockback_x, knockback_up)
	body.take_direct_damage(applied_damage, impulse)

func _on_area_entered(area: Area2D) -> void:
	if not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	var owner_node := hurtbox.get_parent()
	if owner_node == null or not is_instance_valid(owner_node):
		return

	var owner_id := owner_node.get_instance_id()
	var now := Time.get_ticks_msec()
	if _target_cooldowns.has(owner_id):
		if now - _target_cooldowns[owner_id] < DAMAGE_INTERVAL_MS:
			return

	if owner_node is Player and not owner_node.is_local_controlled():
		return
	if owner_node is Enemy and NetworkManager and NetworkManager.is_multiplayer_active() and not multiplayer.is_server():
		return

	_target_cooldowns[owner_id] = now

	var dir_x: float = sign(owner_node.global_position.x - global_position.x)
	if dir_x == 0.0:
		dir_x = -1.0

	var is_enemy := (owner_node is Enemy or hurtbox.is_enemy_hurtbox)
	var applied_damage: int = enemy_damage if is_enemy else damage
	var impulse := Vector2(dir_x * knockback_x, knockback_up)
	hurtbox.take_damage(applied_damage, impulse)
