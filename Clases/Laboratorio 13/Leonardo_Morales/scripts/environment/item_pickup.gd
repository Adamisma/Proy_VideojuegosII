class_name ItemPickup
extends Area2D

## ====================================================================
## Laboratorio 13 - Objeto Recogible en el Escenario (ItemPickup)
## ====================================================================
## Al entrar en contacto con el jugador:
## 1. Agrega el ItemData configurado al InventoryComponent.
## 2. Emite feedback de animación con Tween.
## 3. Desaparece del mundo sin bloquear el flujo de juego.

signal picked_up(item: ItemData, quantity: int)

@export var item: ItemData
@export var quantity: int = 1

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var visual_rect: ColorRect = get_node_or_null("VisualRect")

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if item != null:
		if sprite and item.icon:
			sprite.texture = item.icon
		if visual_rect:
			if item.item_id == &"potion_small":
				visual_rect.color = Color(1.0, 0.25, 0.35, 1.0) # Rojo poción
			elif item.item_id == &"key_blue":
				visual_rect.color = Color(0.3, 0.8, 1.0, 1.0) # Celeste llave
			else:
				visual_rect.color = Color(1.0, 0.85, 0.2, 1.0) # Dorado

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body.is_in_group("player"):
		return

	var inv := body.get_node_or_null("InventoryComponent") as InventoryComponent
	if inv == null:
		return

	if item == null:
		push_warning("ItemPickup sin ItemData asignado.")
		return

	var success := inv.add_item(item, quantity)
	if not success:
		return

	is_collected = true
	picked_up.emit(item, quantity)

	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.parallel().tween_property(self, "position:y", position.y - 25.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
