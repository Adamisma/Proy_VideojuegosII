class_name HitboxComponent
extends Area2D

## ====================================================================
## Laboratorio 06 - Sección 11: HitboxComponent
## ====================================================================
## Representa la zona ofensiva de un ataque.
## Detecta Hurtboxes superpuestas, aplica AttackData y evita daño repetido
## en un mismo swing mediante la lista 'already_hit'.

@export var attack_data: AttackData
@export var source: Node2D

var already_hit: Array[HurtboxComponent] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = false

func begin_attack() -> void:
	already_hit.clear()
	monitoring = true

func end_attack() -> void:
	monitoring = false

func _on_area_entered(area: Area2D) -> void:
	if not area is HurtboxComponent:
		return

	var hurtbox := area as HurtboxComponent
	if hurtbox in already_hit:
		return

	if attack_data == null:
		return

	if hurtbox.is_invulnerable:
		return

	already_hit.append(hurtbox)

	var origin := source.global_position if source else global_position
	var direction := origin.direction_to(hurtbox.global_position)

	hurtbox.receive_hit(attack_data, direction)

	# Reto 33: Hit stop breve para impacto contundente (Sección 25)
	_trigger_hit_stop()

func _trigger_hit_stop() -> void:
	Engine.time_scale = 0.08
	await get_tree().create_timer(0.04, true, false, true).timeout
	Engine.time_scale = 1.0
