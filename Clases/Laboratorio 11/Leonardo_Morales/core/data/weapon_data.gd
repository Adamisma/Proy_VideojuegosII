class_name WeaponData
extends Resource

## ====================================================================
## Laboratorio 11 - Reto 43: Custom Resource WeaponData
## ====================================================================
## Desacopla la definición de armas y ataques en Resources configurables.
## Permite cambiar daño, retroceso, cadencia y VFX sin modificar scripts de actores.

@export var weapon_name: String = "Espada de Acero"
@export var damage: int = 25
@export var knockback_force: float = 240.0
@export var attack_cooldown: float = 0.35
@export var hit_vfx: PackedScene
