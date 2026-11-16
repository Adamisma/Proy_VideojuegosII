class_name HurtboxComponent
extends Area2D

## ====================================================================
## Laboratorio 06 - Sección 10: HurtboxComponent
## ====================================================================
## Representa la zona vulnerable de una entidad.
## Recibe ataques, aplica el daño a su HealthComponent y maneja invulnerabilidad.

signal hit_received(attack: AttackData, direction: Vector2)
signal invulnerability_changed(is_invulnerable: bool)

@export var health_component: HealthComponent
var is_invulnerable: bool = false

func receive_hit(attack: AttackData, hit_direction: Vector2) -> void:
	if is_invulnerable:
		return

	if health_component == null:
		push_warning("Hurtbox without HealthComponent")
		return

	health_component.take_damage(attack.damage)
	hit_received.emit(attack, hit_direction)

	# Reto 33: Número flotante de daño
	_spawn_floating_damage_number(attack.damage)

	_start_invulnerability(attack.invulnerability_time)

func _start_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return

	is_invulnerable = true
	invulnerability_changed.emit(true)

	await get_tree().create_timer(duration).timeout

	is_invulnerable = false
	invulnerability_changed.emit(false)

## Reto 33: Efecto de texto de combate flotante al recibir daño
func _spawn_floating_damage_number(amount: float) -> void:
	var label := Label.new()
	label.text = "-%d" % int(amount)
	label.modulate = Color(1.0, 0.25, 0.25, 1.0) # Rojo intenso
	label.global_position = global_position + Vector2(randf_range(-12, 12), -24)
	label.z_index = 100
	get_tree().current_scene.add_child(label)

	var tween := label.create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 32.0, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)
