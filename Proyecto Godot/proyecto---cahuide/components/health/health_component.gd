class_name HealthComponent
extends Node

## ====================================================================
## Proyecto Cahuide - HealthComponent Autónomo
## ====================================================================

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health: int = 20
var current_health: int

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func configure_from_stats(stats: CharacterStats) -> void:
	if stats != null:
		max_health = stats.max_health
		current_health = max_health
		health_changed.emit(current_health, max_health)

func apply_damage(amount: int) -> void:
	if current_health <= 0:
		return

	var applied := mini(amount, current_health)
	current_health = maxi(current_health - applied, 0)

	damaged.emit(applied)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return

	var before := current_health
	current_health = mini(current_health + maxi(amount, 0), max_health)
	var restored := current_health - before

	if restored > 0:
		healed.emit(restored)
		health_changed.emit(current_health, max_health)

func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
