extends Node2D

## ====================================================================
## Laboratorio 10 - Reto 41: Partículas de Muerte (Death Burst)
## ====================================================================
## Emisor de partículas one-shot enlazado a la muerte de entidades (estado DEAD).
## Se autodestruye al concluir su dispersión.

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	if particles:
		particles.finished.connect(_on_particles_finished)
		particles.restart()

func _on_particles_finished() -> void:
	queue_free()

