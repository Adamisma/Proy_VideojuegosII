class_name Hotbar
extends Control

## ====================================================================
## Laboratorio 13 - Sección 37: Hotbar de Acceso Rápido
## ====================================================================
## Muestra los primeros 5 slots del inventario en la parte inferior de la pantalla.
## Permite seleccionar y usar ítems mediante las teclas numéricas 1 a 5.

signal item_used_from_hotbar(slot_index: int)

@export var slot_scene: PackedScene = preload("res://ui/inventory/inventory_slot.tscn")
@export var item_database: ItemDatabase = preload("res://resources/items/item_database.tres")

@onready var slots_container: HBoxContainer = $MarginContainer/PanelContainer/HBoxContainer

var inventory: InventoryComponent = null
var selected_slot_index: int = 0
var slot_buttons: Array[InventorySlotUI] = []
var player_ref: Node = null

func _ready() -> void:
	_create_hotbar_slots()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _select_and_use(0)
			KEY_2: _select_and_use(1)
			KEY_3: _select_and_use(2)
			KEY_4: _select_and_use(3)
			KEY_5: _select_and_use(4)

func _create_hotbar_slots() -> void:
	slot_buttons.clear()
	for child in slots_container.get_children():
		child.queue_free()

	for i in range(5):
		var slot_ui := slot_scene.instantiate() as InventorySlotUI
		slots_container.add_child(slot_ui)
		slot_ui.slot_index = i
		slot_ui.slot_selected.connect(_on_slot_clicked)
		slot_buttons.append(slot_ui)

func bind_inventory(source: InventoryComponent, player: Node = null) -> void:
	inventory = source
	player_ref = player
	if not inventory.inventory_changed.is_connected(update_hotbar):
		inventory.inventory_changed.connect(update_hotbar)
	update_hotbar()

func update_hotbar() -> void:
	if inventory == null or slot_buttons.size() < 5:
		return

	for i in range(5):
		var slot_ui: InventorySlotUI = slot_buttons[i]
		if i >= inventory.slots.size():
			slot_ui.display(null, 0)
			continue

		var slot_data: Dictionary = inventory.slots[i]
		if slot_data.is_empty():
			slot_ui.display(null, 0)
			continue

		var item_id := StringName(slot_data.get("item_id", ""))
		var qty := int(slot_data.get("quantity", 0))
		var item_data: ItemData = item_database.get_item(item_id) if item_database else null
		slot_ui.display(item_data, qty)

func _select_and_use(index: int) -> void:
	selected_slot_index = index
	_use_slot(index)

func _on_slot_clicked(index: int) -> void:
	_use_slot(index)

func _use_slot(index: int) -> void:
	if inventory == null or index < 0 or index >= inventory.slots.size():
		return

	var slot_data: Dictionary = inventory.slots[index]
	if slot_data.is_empty():
		return

	var item_id := StringName(slot_data.get("item_id", ""))
	var item: ItemData = item_database.get_item(item_id) if item_database else null
	if item and item.consumable:
		if item.heal_amount > 0 and player_ref != null and "health" in player_ref:
			player_ref.health.heal(item.heal_amount)
		if item.score_amount > 0 and GameState:
			GameState.add_score(item.score_amount)

		inventory.consume_slot(index)
		item_used_from_hotbar.emit(index)
