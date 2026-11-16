class_name WeaponData
extends Resource

## ====================================================================
## Proyecto Cahuide - Resource de Armas y Proyectiles
## ====================================================================

@export var weapon_id: StringName = &"stone"
@export var weapon_name: String = "Piedra Ancestral"
@export var description: String = "Lanzamiento parabólico con aturdimiento y caída gravitatoria."
@export var projectile_scene: PackedScene
@export var damage: int = 15
@export var speed: float = 460.0
@export var cooldown: float = 0.5
@export var icon: Texture2D
