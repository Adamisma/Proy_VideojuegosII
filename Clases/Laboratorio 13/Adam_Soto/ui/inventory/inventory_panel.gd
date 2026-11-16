class_name InventoryPanel
extends Control

## ====================================================================
## Laboratorio 13 - Secciones 29, 32 a 35: InventoryPanel
## ====================================================================
## Interfaz de visualización y uso de inventario tipo Grid.
## Desacoplada del almacenamiento interno del jugador mediante bind_inventory().

signal closed

@export var slot_scene: PackedScene = preload("res://ui/inventory/inventory_slot.tscn")
@export var item_database: ItemDatabase = preload("res://resources/items/item_database.tres")

@onready var grid: GridContainer = $CenterContainer/PanelContainer/VBoxContainer/Body/ScrollContainer/GridContainer
@onready var item_name_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body/DetailsPanel/Margin/VBox/ItemName
@onready var item_desc_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body/DetailsPanel/Margin/VBox/ItemDescription
@onready var use_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Body/DetailsPanel/Margin/VBox/UseButton
@onready var close_button: Button = $CenterContainer/PanelContainer/VBoxContainer/Header/CloseButton

var inventory: InventoryComponent = null
var current_selected_index: int = -1
var player_ref: Node = null

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_inventory)
	use_button.pressed.connect(_on_use_button_pressed)
	use_button.disabled = true

func bind_inventory(source: InventoryComponent, player: Node = null) -> void:
	inventory = source
	player_ref = player
	if not inventory.inventory_changed.is_connected(refresh):
		inventory.inventory_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if grid == null or inventory == null:
		return

	for child in grid.get_children():
		child.queue_free()

	for index in range(inventory.slots.size()):
		var slot_ui := slot_scene.instantiate() as InventorySlotUI
		grid.add_child(slot_ui)
		slot_ui.slot_index = index
		slot_ui.slot_selected.connect(_on_slot_selected)

		var slot_data: Dictionary = inventory.slots[index]
		if slot_data.is_empty():
			slot_ui.display(null, 0)
			continue

		var item_id := StringName(slot_data.get("item_id", ""))
		var qty := int(slot_data.get("quantity", 0))
		var item_data: ItemData = item_database.get_item(item_id) if item_database else null
		slot_ui.display(item_data, qty)

	# Actualizar detalles del slot seleccionado
	if current_selected_index >= 0 and current_selected_index < inventory.slots.size():
		_display_slot_details(current_selected_index)
	else:
		_clear_details()

func _on_slot_selected(index: int) -> void:
	current_selected_index = index
	_display_slot_details(index)

func _display_slot_details(index: int) -> void:
	if inventory == null or index < 0 or index >= inventory.slots.size() or inventory.slots[index].is_empty():
		_clear_details()
		return

	var item_id := StringName(inventory.slots[index].get("item_id", ""))
	var item: ItemData = item_database.get_item(item_id) if item_database else null
	if item == null:
		_clear_details()
		return

	item_name_label.text = item.display_name
	item_desc_label.text = item.description
	use_button.disabled = not item.consumable
	use_button.text = "Usar Objeto" if item.consumable else "No consumible"

func _clear_details() -> void:
	item_name_label.text = "Selecciona un objeto"
	item_desc_label.text = "Haz clic o navega con las flechas para ver los detalles del ítem."
	use_button.disabled = true
	use_button.text = "Usar Objeto"

func _on_use_button_pressed() -> void:
	if inventory == null or current_selected_index < 0:
		return

	var slot_data: Dictionary = inventory.slots[current_selected_index]
	if slot_data.is_empty():
		return

	var item_id := StringName(slot_data.get("item_id", ""))
	var item: ItemData = item_database.get_item(item_id) if item_database else null
	if item and item.consumable:
		# Aplicar efecto sobre el gameplay
		if item.heal_amount > 0 and player_ref != null and "health" in player_ref:
			player_ref.health.heal(item.heal_amount)
		if item.score_amount > 0 and GameState:
			GameState.add_score(item.score_amount)

		# Consumir del inventario
		inventory.consume_slot(current_selected_index)

## Sección 34: Apertura y cierre con foco automático
func open_inventory() -> void:
	visible = true
	refresh()
	if grid.get_child_count() > 0:
		var first_slot := grid.get_child(0) as Control
		if first_slot:
			first_slot.grab_focus()

func close_inventory() -> void:
	visible = false
	closed.emit()
