extends Node2D

## ====================================================================
## Laboratorio 10 - Sección 15: Polvo al Aterrizar (Land Dust)
## ====================================================================
## Emisor de partículas tipo burst corto que comunica peso e impacto con el suelo.
## Se autodestruye al terminar su emisión.

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	if particles:
		particles.finished.connect(_on_particles_finished)
		particles.restart()

func _on_particles_finished() -> void:
	queue_free()
