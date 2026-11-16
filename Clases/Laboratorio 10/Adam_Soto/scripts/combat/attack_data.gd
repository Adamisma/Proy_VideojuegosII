class_name AttackData
extends Resource

## ====================================================================
## Laboratorio 06 - Sección 8: AttackData como Resource
## ====================================================================
## Parametriza las características de un golpe sin duplicar código.
## Permite definir múltiples armas, ataques pesados o mordeduras de enemigos.

@export var attack_name: String = "Basic Attack"
@export var damage: float = 10.0
@export var knockback_force: float = 280.0
@export var hitstun_time: float = 0.18
@export var invulnerability_time: float = 0.35
