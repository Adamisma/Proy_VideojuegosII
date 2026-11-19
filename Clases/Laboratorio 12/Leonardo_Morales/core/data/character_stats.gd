class_name CharacterStats
extends Resource

## ====================================================================
## Laboratorio 11 - Sección 11: Custom Resource CharacterStats
## ====================================================================
## Define la plantilla de datos y estadísticas base para actores (Player, Enemy).
## Permite balancear valores en archivos .tres desde el Inspector sin tocar código.
## Regla: Se utiliza como plantilla inmutable durante gameplay (Sección 32).

@export_category("Health")
@export var max_health: int = 100

@export_category("Movement")
@export var move_speed: float = 260.0
@export var acceleration: float = 1500.0
@export var deceleration: float = 1900.0

@export_category("Combat")
@export var attack_damage: int = 20
@export var knockback_force: float = 220.0
