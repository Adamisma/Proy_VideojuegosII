class_name HurtboxComponent
extends Area2D

## ====================================================================
## Proyecto Cahuide - HurtboxComponent con Invulnerabilidad y Números de Daño
## ====================================================================

signal hit_received(attack: AttackData, direction: Vector2)
signal invulnerability_changed(is_invulnerable: bool)

@export var health_component: HealthComponent
var is_invulnerable: bool = false

func receive_hit(attack: AttackData, hit_direction: Vector2) -> void:
	if is_invulnerable:
		return

	if health_component != null:
		health_component.apply_damage(attack.damage)

	hit_received.emit(attack, hit_direction)
	_spawn_floating_damage(attack.damage, attack.is_critical)
	_start_invulnerability(attack.invulnerability_time)

func _start_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return

	is_invulnerable = true
	invulnerability_changed.emit(true)

	await get_tree().create_timer(duration).timeout

	is_invulnerable = false
	invulnerability_changed.emit(false)

func _spawn_floating_damage(amount: int, is_crit: bool = false) -> void:
	var label := Label.new()
	label.text = "-%d" % amount
	label.modulate = Color(1.0, 0.85, 0.2, 1.0) if is_crit else Color(1.0, 0.3, 0.3, 1.0)
	label.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	label.z_index = 100
	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 28.0, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(label.queue_free)
