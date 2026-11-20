class_name StoneProjectile
extends Area2D

## ====================================================================
## Proyecto Cahuide - Proyectil de Piedra (Tiro Parabólico y Balística)
## ====================================================================

const HIT_SPARKS_SCENE: PackedScene = preload("res://scenes/vfx/fx_hit_sparks.tscn")

@export var gravity_strength: float = 980.0
@export var damage: int = 15
@export var knockback_force: float = 240.0
@export var lifetime: float = 3.5
@export var is_enemy_projectile: bool = false
@export var tumble_speed: float = 8.0

var velocity: Vector2 = Vector2.ZERO
var _has_impacted: bool = false
var _time_alive: float = 0.0
var is_pooled: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func activate(pos: Vector2) -> void:
	global_position = pos
	_has_impacted = false
	_time_alive = 0.0
	rotation = 0.0
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	set_physics_process(true)

func recycle() -> void:
	_has_impacted = false
	_time_alive = 0.0
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_physics_process(false)

func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity

func _physics_process(delta: float) -> void:
	if _has_impacted:
		return

	velocity.y += gravity_strength * delta
	global_position += velocity * delta

	# Rotación rodante realista de la piedra en vuelo
	rotation += tumble_speed * delta * (1.0 if velocity.x >= 0.0 else -1.0)

	_time_alive += delta
	if _time_alive >= lifetime:
		if is_pooled:
			recycle()
		else:
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
	if is_pooled:
		recycle()
	else:
		queue_free()

func _spawn_hit_sparks() -> void:
	if HIT_SPARKS_SCENE:
		var sparks := HIT_SPARKS_SCENE.instantiate() as Node2D
		get_tree().current_scene.add_child(sparks)
		sparks.global_position = global_position
		if sparks.has_method("orient_to_direction"):
			sparks.orient_to_direction(-velocity.normalized())
