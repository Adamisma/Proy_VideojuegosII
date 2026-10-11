class_name Hitbox
extends Area2D

## Componente de Hitbox para infligir daño
@export var damage: int = 10
@export var knockback_force: float = 200.0
@export var is_enemy_hitbox: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		# Evitar fuego amigo si pertenecen al mismo bando
		if hurtbox.is_enemy_hurtbox == is_enemy_hitbox:
			return
		
		var knock_dir = (hurtbox.global_position - global_position).normalized()
		var knockback = knock_dir * knockback_force
		hurtbox.take_damage(damage, knockback)
