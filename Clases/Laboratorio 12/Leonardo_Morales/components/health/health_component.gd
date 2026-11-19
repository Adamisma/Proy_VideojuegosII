class_name HealthComponent
extends Node

## ====================================================================
## Laboratorio 11 - Sección 14 & 36: HealthComponent Refactorizado
## ====================================================================
## Componente autónomo y desacoplado para gestión de vida y daño.
## Puede inicializarse directamente o configurarse desde un Resource CharacterStats.
## Emite señales sin conocer quién las escucha (Player, Enemy, HUD, Analytics).

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

## Sección 14 & 36: Contrato de inicialización mediante Resource
func configure_from_stats(stats: CharacterStats) -> void:
	assert(stats != null, "HealthComponent requiere stats.")
	max_health = stats.max_health
	current_health = max_health
	health_changed.emit(current_health, max_health)

## Sección 14: Aplicación robusta de daño con control de umbral
func apply_damage(amount: int) -> void:
	if current_health <= 0:
		return

	var applied := mini(amount, current_health)
	current_health = maxi(current_health - applied, 0)

	damaged.emit(applied)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		died.emit()

## Alias para compatibilidad con llamadas de combate anteriores
func take_damage(amount: float) -> void:
	apply_damage(int(amount))

## Sección 14: Curación protegida contra rebasamiento
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
