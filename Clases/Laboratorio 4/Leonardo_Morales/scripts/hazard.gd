extends Area2D 

signal player_touched_hazard 

func _ready() -> void: 
	body_entered.connect(_on_body_entered) 

func _on_body_entered(body: Node2D) -> void: 
	# Verifica que lo que entró a la trampa sea el jugador
	if body.is_in_group("player"): 
		player_touched_hazard.emit() # Lanza la señal al aire
