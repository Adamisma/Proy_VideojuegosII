extends Area2D

## ====================================================================
## Laboratorio 04 - Reto 26: Meta del Nivel
## ====================================================================
## Detecta la llegada del jugador al final del circuito y emite la señal
## 'goal_reached' para disparar el mensaje de victoria en el nivel y HUD.

signal goal_reached

var is_reached: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_reached:
		return
	if body.is_in_group("player"):
		is_reached = true
		goal_reached.emit()
