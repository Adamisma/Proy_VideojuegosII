class_name Relic
extends Area2D

## Reliquia Ancestral - Coleccionable y Meta del Nivel (HU05)

signal relic_collected(relic_node: Relic)

@export var score_value: int = 50

@onready var sprite: Sprite2D = $Sprite2D
var _collected: bool = false

func _ready() -> void:
	# Agregamos al grupo para que el nivel sepa cuántas reliquias hay en total
	add_to_group("relics")
	body_entered.connect(_on_body_entered)
	
	# Efecto de levitación continua
	if sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "position:y", -10.0, 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
		
	if body.is_in_group("player"):
		_collected = true
		
		# 1. Otorgar los +50 puntos de Score al HUD
		var hud = get_tree().get_first_node_in_group("hud")
		if not hud:
			hud = get_tree().current_scene.get_node_or_null("HUD")
			
		if hud and hud.has_method("add_score"):
			hud.add_score(score_value)
			
		# 2. Emitir señal a la lógica del nivel
		relic_collected.emit(self)
		
		# 3. Efecto visual de recolección y eliminación
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.3)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)
