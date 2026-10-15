
class_name StoneProjectile
extends Area2D

@export var gravity_strength: float = 900.0
@export var damage: int = 1
@export var knockback_force: float = 220.0
@export var lifetime: float = 3.0
@export var is_enemy_projectile: bool = false

var velocity: Vector2 = Vector2.ZERO
var _has_impacted: bool = false
var _time_alive: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity

func _physics_process(delta: float) -> void:
	if _has_impacted:
		return

	velocity.y += gravity_strength * delta
	global_position += velocity * delta

	# Girar la piedra según su movimiento.
	rotation = velocity.angle()

	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _has_impacted:
		return

	if body is TileMapLayer or body is StaticBody2D:
		_impact_and_destroy()
		return

	if body.has_method("take_direct_damage"):
		var is_player := body.is_in_group("player")

		if is_enemy_projectile == is_player:
			_has_impacted = true
			body.take_direct_damage(
				damage,
				velocity.normalized() * knockback_force
			)
			_impact_and_destroy()

func _on_area_entered(area: Area2D) -> void:
	if _has_impacted:
		return

	if area is Hurtbox:
		var hurtbox := area as Hurtbox

		# Evitar golpear al mismo bando.
		if hurtbox.is_enemy_hurtbox == is_enemy_projectile:
			return

		_has_impacted = true
		hurtbox.take_damage(
			damage,
			velocity.normalized() * knockback_force
		)
		_impact_and_destroy()

func _impact_and_destroy() -> void:
	_has_impacted = true
	queue_free()
