class_name Projectile
extends Area2D

## HU04 — Sistema de disparos y proyectiles
## Implementación de proyectiles balísticos / a distancia

@export var speed: float = 480.0
@export var damage: int = 15
@export var lifetime: float = 3.0
@export var is_enemy_projectile: bool = false
@export var knockback_force: float = 180.0

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Ajustar rotación visual hacia la dirección
	_update_rotation()

func _physics_process(delta: float) -> void:
	# =========================================================================
	# Matemáticas aplicadas (HU04):
	# posición nueva = posición actual + dirección * velocidad * delta
	# =========================================================================
	global_position += direction * speed * delta
	
	# Control de distancia máxima / tiempo de vida
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	if new_direction != Vector2.ZERO:
		direction = new_direction.normalized()
		_update_rotation()

func _update_rotation() -> void:
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Si impacta contra terreno o estructuras sólidas
	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		_impact_and_destroy()
		return
	
	# Si impacta contra un CharacterBody2D directamente
	if body.has_method("take_direct_damage"):
		var is_target_player = body.is_in_group("player")
		# Proyectil enemigo daña al jugador; proyectil del jugador daña a enemigos
		if is_enemy_projectile and is_target_player:
			body.take_direct_damage(damage, direction * knockback_force)
			_impact_and_destroy()
			return
		elif not is_enemy_projectile and not is_target_player:
			body.take_direct_damage(damage, direction * knockback_force)
			_impact_and_destroy()
			return

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		# Evitar daño a aliados
		if hurtbox.is_enemy_hurtbox == is_enemy_projectile:
			return
		
		hurtbox.take_damage(damage, direction * knockback_force)
		_impact_and_destroy()

func _impact_and_destroy() -> void:
	# Efecto visual sencillo de impacto y destrucción (HU04)
	queue_free()
