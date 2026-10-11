class_name Hazard
extends Area2D

## Obstáculo que daña al jugador o enemigos al contacto (HU05)

@export var damage: int = 25
@export var knockback_up: float = -350.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_direct_damage"):
		body.take_direct_damage(damage, Vector2(0, knockback_up))

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		hurtbox.take_damage(damage, Vector2(0, knockback_up))
