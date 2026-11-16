class_name SpearProjectile
extends Area2D

## ====================================================================
## Proyecto Cahuide - Proyectil de Lanza Inca
## ====================================================================
## Tiro recto veloz de alta potencia y penetración con leve caída final.

const HIT_SPARKS_SCENE: PackedScene = preload("res://scenes/vfx/fx_hit_sparks.tscn")

@export var speed: float = 620.0
@export var damage: int = 30
@export var knockback_force: float = 320.0
@export var gravity_factor: float = 280.0
@export var lifetime: float = 2.5
@export var is_enemy_projectile: bool = false

var velocity: Vector2 = Vector2.ZERO
var _has_impacted: bool = false
var _time_alive: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	if _has_impacted:
		return

	# Leve caída por gravedad
	velocity.y += gravity_factor * delta
	global_position += velocity * delta

	# La lanza siempre apunta hacia su vector de movimiento
	rotation = velocity.angle()

	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _has_impacted:
		return

	if body is TileMap or body is TileMapLayer or body is StaticBody2D:
		_impact_and_destroy()
		return

	if body.has_method("take_direct_damage"):
		var is_player := body.is_in_group("player")
		if is_enemy_projectile == is_player:
			_has_impacted = true
			body.take_direct_damage(damage, velocity.normalized() * knockback_force)
			_impact_and_destroy()

func _on_area_entered(area: Area2D) -> void:
	if _has_impacted:
		return

	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		_has_impacted = true
		var atk := AttackData.new()
		atk.damage = damage
		atk.knockback_force = knockback_force
		atk.is_critical = true
		hurtbox.receive_hit(atk, velocity.normalized())
		_impact_and_destroy()
	elif area is Hurtbox:
		var hurtbox := area as Hurtbox
		if hurtbox.is_enemy_hurtbox != is_enemy_projectile:
			_has_impacted = true
			hurtbox.take_damage(damage, velocity.normalized() * knockback_force)
			_impact_and_destroy()

func _impact_and_destroy() -> void:
	_has_impacted = true
	_spawn_hit_sparks()
	queue_free()

func _spawn_hit_sparks() -> void:
	if HIT_SPARKS_SCENE:
		var sparks := HIT_SPARKS_SCENE.instantiate() as Node2D
		get_tree().current_scene.add_child(sparks)
		sparks.global_position = global_position
		if sparks.has_method("orient_to_direction"):
			sparks.orient_to_direction(-velocity.normalized())
