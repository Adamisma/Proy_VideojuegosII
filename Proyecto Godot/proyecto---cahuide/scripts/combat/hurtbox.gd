class_name Hurtbox
extends Area2D

## Componente de Hurtbox para recibir daño
signal received_damage(amount: int, knockback: Vector2)

@export var is_enemy_hurtbox: bool = false
@export var invulnerability_time: float = 0.2

var is_invulnerable: bool = false
var _timer: float = 0.0

func _process(delta: float) -> void:
	if is_invulnerable:
		_timer -= delta
		if _timer <= 0.0:
			is_invulnerable = false

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable:
		print("Golpe ignorado por invulnerabilidad")
		return
	print("Hurtbox recibió una solicitud de daño: ", amount)
	
	if invulnerability_time > 0.0:
		is_invulnerable = true
		_timer = invulnerability_time
		
	received_damage.emit(amount, knockback)
