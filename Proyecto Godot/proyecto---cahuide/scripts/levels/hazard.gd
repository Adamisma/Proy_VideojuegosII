class_name Hazard
extends Area2D

## Obstáculo que daña al jugador o enemigos al contacto (HU05)

@export var damage: int = 2
@export var knockback_up: float = -420.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_apply_hazard_damage(body)

func _on_body_entered(body: Node2D) -> void:
	_apply_hazard_damage(body)

func _apply_hazard_damage(body: Node2D) -> void:
	if body and body.has_method("take_direct_damage"):
		var dir_x: float = sign(body.global_position.x - global_position.x)
		if dir_x == 0.0:
			dir_x = -1.0
		body.take_direct_damage(damage, Vector2(dir_x * 160.0, knockback_up))

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		hurtbox.take_damage(damage, Vector2(0, knockback_up))
