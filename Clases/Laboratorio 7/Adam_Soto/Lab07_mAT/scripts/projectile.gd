extends Area2D

@export var speed: float = 600.0
var direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# El proyectil avanza en línea recta usando el vector unitario de dirección
	global_position += direction * speed * delta

# Función para configurar la dirección inicial desde el jugador
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

# Opcional: Destruir el proyectil si sale de la pantalla o choca con algo (puedes ajustarlo luego)
func _on_body_entered(body: Node2D) -> void:
	# Aquí podrías programar daño si choca con un enemigo
	queue_free()
