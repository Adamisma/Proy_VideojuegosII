extends Area2D

## ====================================================================
## Laboratorio 04 - Sección 16.2: Script del Hazard (Área de Peligro)
## ====================================================================
## Arquitectura desacoplada: El Hazard no conoce la lógica del nivel ni
## fuerza posiciones de respawn. Únicamente notifica al mundo mediante
## una señal cuando el jugador entra en contacto.

signal player_touched_hazard

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verifica que lo que entró a la trampa pertenezca al grupo "player"
	if body.is_in_group("player"):
		player_touched_hazard.emit()
