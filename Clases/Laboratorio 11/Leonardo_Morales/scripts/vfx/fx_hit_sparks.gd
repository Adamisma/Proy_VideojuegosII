extends Node2D

## ====================================================================
## Laboratorio 10 - Sección 11 & 12: Chispas de Impacto One-Shot
## ====================================================================
## Emisor de partículas direccional de corta duración que se autodestruye
## al finalizar su ciclo de emisión para no saturar memoria.

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	if particles:
		particles.finished.connect(_on_particles_finished)
		particles.restart()

func _on_particles_finished() -> void:
	queue_free()

## Sección 12: Orientar partículas según el vector de impacto
func orient_to_direction(direction: Vector2) -> void:
	if direction.length_squared() < 0.0001:
		return
	rotation = direction.angle()

