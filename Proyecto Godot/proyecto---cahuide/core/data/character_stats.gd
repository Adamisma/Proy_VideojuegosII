class_name CharacterStats
extends Resource

## ====================================================================
## Proyecto Cahuide - Resource de Estadísticas Base de Personajes
## ====================================================================

@export_category("Salud")
@export var max_health: int = 20

@export_category("Movimiento")
@export var move_speed: float = 260.0
@export var acceleration: float = 1600.0
@export var deceleration: float = 1900.0

@export_category("Combate")
@export var melee_damage: int = 25
@export var ranged_damage: int = 20
