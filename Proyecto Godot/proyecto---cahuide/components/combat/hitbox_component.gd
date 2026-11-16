class_name HitboxComponent
extends Area2D

## ====================================================================
## Proyecto Cahuide - HitboxComponent (Contrato de Daño y Empuje)
## ====================================================================

@export var attack_data: AttackData
@export var source: Node2D

func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)

func begin_attack() -> void:
	monitoring = true
	monitorable = true

func end_attack() -> void:
	monitoring = false
	monitorable = false

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as HurtboxComponent
	if hurtbox == null or hurtbox.is_invulnerable:
		return

	var origin: Vector2 = source.global_position if source else global_position
	var direction: Vector2 = origin.direction_to(hurtbox.global_position)

	var data: AttackData = attack_data
	if data == null:
		data = AttackData.new()

	hurtbox.receive_hit(data, direction)
