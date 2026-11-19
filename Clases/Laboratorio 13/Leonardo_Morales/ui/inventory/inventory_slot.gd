class_name InventorySlotUI
extends Button

## ====================================================================
## Laboratorio 13 - Sección 31: Slot Visual de Inventario (InventorySlotUI)
## ====================================================================
## Representa un casillero individual en el Grid.
## Gestiona navegación por teclado/gamepad mediante foco nativo de Button.
## Se renombra la referencia del nodo hijo a item_icon para evitar
## colisión de nombres con la propiedad nativa Button.icon de Godot.

signal slot_selected(index: int)
@warning_ignore("unused_signal")
signal slot_activated(index: int)

@onready var item_icon: TextureRect = $Icon
@onready var quantity_label: Label = $QuantityLabel

var slot_index: int = -1

func _ready() -> void:
	focus_mode = FOCUS_ALL
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	slot_selected.emit(slot_index)

func display(item: ItemData, quantity: int) -> void:
	if item_icon == null:
		item_icon = get_node_or_null("Icon") as TextureRect
	if quantity_label == null:
		quantity_label = get_node_or_null("QuantityLabel") as Label

	if item == null:
		if item_icon:
			item_icon.texture = null
		if quantity_label:
			quantity_label.text = ""
		modulate = Color(0.7, 0.7, 0.7, 0.4)
		tooltip_text = ""
		return

	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if item_icon:
		item_icon.texture = item.icon
	if quantity_label:
		quantity_label.text = str(quantity) if quantity > 1 else ""

	tooltip_text = "%s\n%s" % [item.display_name, item.description]
