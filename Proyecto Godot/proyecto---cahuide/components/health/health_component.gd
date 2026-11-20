class_name HealthComponent
extends Node

## ====================================================================
## Proyecto Cahuide - HealthComponent Autónomo
## ====================================================================

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died
signal invulnerability_started
signal invulnerability_ended

@export var max_health: int = 20
@export var default_invulnerability_time: float = 0.0

var current_health: int
var is_invulnerable: bool = false
var _invuln_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	if is_invulnerable and _invuln_timer > 0.0:
		_invuln_timer -= delta
		if _invuln_timer <= 0.0:
			is_invulnerable = false
			invulnerability_ended.emit()

func configure_from_stats(stats: CharacterStats) -> void:
	if stats != null:
		max_health = stats.max_health
		current_health = max_health
		health_changed.emit(current_health, max_health)

func start_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return
	is_invulnerable = true
	_invuln_timer = duration
	invulnerability_started.emit()

func apply_damage(amount: int) -> void:
	if is_invulnerable or current_health <= 0 or amount <= 0:
		return

	var applied := mini(amount, current_health)
	current_health = maxi(current_health - applied, 0)

	damaged.emit(applied)
	health_changed.emit(current_health, max_health)

	if default_invulnerability_time > 0.0 and current_health > 0:
		start_invulnerability(default_invulnerability_time)

	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0 or amount <= 0:
		return

	var before := current_health
	current_health = mini(current_health + amount, max_health)
	var restored := current_health - before

	if restored > 0:
		healed.emit(restored)
		health_changed.emit(current_health, max_health)

func reset_health() -> void:
	is_invulnerable = false
	_invuln_timer = 0.0
	current_health = max_health
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func get_health_ratio() -> float:
	return float(current_health) / float(max_health) if max_health > 0 else 0.0
