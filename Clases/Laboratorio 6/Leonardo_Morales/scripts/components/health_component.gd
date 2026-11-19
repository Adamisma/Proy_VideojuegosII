class_name HealthComponent
extends Node

## ====================================================================
## Laboratorio 06 - Sección 9 & 27: HealthComponent
## ====================================================================
## Administra la vida actual, máxima y eventos de daño, curación y muerte.
## Totalmente desacoplado: No maneja animaciones ni elimina nodos directamente.

signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	# Notificar a los observadores (HUD) el estado inicial
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return

	var applied_damage := min(amount, current_health)
	current_health -= applied_damage

	damaged.emit(applied_damage)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if current_health <= 0.0:
		return

	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

## Sección 27: Restauración completa para flujo de respawn
func reset_health() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
