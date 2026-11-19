class_name InventoryComponent
extends Node

## ====================================================================
## Laboratorio 13 - Secciones 24 a 27, 36 & 40: InventoryComponent
## ====================================================================
## Administra el estado en runtime de los objetos del jugador (IDs y cantidades).
## Totalmente desacoplado de la interfaz gráfica y serializable a JSON.

signal inventory_changed
signal item_added(item_id: StringName, quantity: int)
signal item_used(item_id: StringName)

@export var max_slots: int = 20
var slots: Array[Dictionary] = []

func _ready() -> void:
	# Inicializar slots vacíos o importar desde GameState si ya existen datos
	if GameState and GameState.inventory_data.size() > 0:
		import_inventory(GameState.inventory_data)
	else:
		_initialize_empty_slots()

func _initialize_empty_slots() -> void:
	slots.clear()
	slots.resize(max_slots)
	for i in range(max_slots):
		slots[i] = {}

## Sección 25: Buscar un stack existente del mismo item
func _find_stack(item_id: StringName) -> int:
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if slot.is_empty():
			continue
		if StringName(slot.get("item_id", "")) == item_id:
			return i
	return -1

## Sección 26: Buscar el primer slot vacío
func _find_empty_slot() -> int:
	for i in range(slots.size()):
		if slots[i].is_empty():
			return i
	return -1

## Sección 27: Agregar objeto con apilamiento (Stacking)
func add_item(item: ItemData, quantity: int = 1) -> bool:
	if item == null:
		return false

	var amount: int = maxi(quantity, 1)
	var stack_index := _find_stack(item.item_id)

	if stack_index >= 0:
		var current_qty := int(slots[stack_index].get("quantity", 0))
		if current_qty + amount <= item.max_stack:
			slots[stack_index]["quantity"] = current_qty + amount
			_on_inventory_updated(item.item_id, amount)
			return true

	var empty_index := _find_empty_slot()
	if empty_index < 0:
		push_warning("InventoryComponent: Inventario lleno, no se pudo añadir: " + str(item.item_id))
		return false

	slots[empty_index] = {
		"item_id": String(item.item_id),
		"quantity": amount
	}
	_on_inventory_updated(item.item_id, amount)
	return true

## Sección 36: Consumir un objeto por su identificador
func consume_one(item_id: StringName) -> bool:
	var index := _find_stack(item_id)
	if index < 0:
		return false
	return consume_slot(index)

## Consumir directamente del índice de slot especificado
func consume_slot(index: int) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false

	var item_id := StringName(slots[index].get("item_id", ""))
	var quantity := int(slots[index].get("quantity", 0))

	quantity -= 1
	if quantity <= 0:
		slots[index] = {}
	else:
		slots[index]["quantity"] = quantity

	item_used.emit(item_id)
	_on_inventory_updated(item_id, -1)
	return true

func _on_inventory_updated(item_id: StringName, amount: int) -> void:
	if amount > 0:
		item_added.emit(item_id, amount)
	inventory_changed.emit()

	# Sincronizar automáticamente con GameState para persistencia
	if GameState:
		GameState.inventory_data = export_inventory()

## Sección 38: Exportar slots a estructura serializable compatible con JSON
func export_inventory() -> Array:
	var result: Array = []
	for slot in slots:
		if slot.is_empty():
			result.append({})
		else:
			result.append({
				"item_id": String(slot.get("item_id", "")),
				"quantity": int(slot.get("quantity", 0))
			})
	return result

## Sección 40: Importar slots serializados
func import_inventory(saved_slots: Array) -> void:
	slots.clear()
	slots.resize(max_slots)
	for i in range(max_slots):
		slots[i] = {}

	var count: int = mini(saved_slots.size(), max_slots)
	for i in range(count):
		var source = saved_slots[i]
		if typeof(source) != TYPE_DICTIONARY:
			continue
		var item_id := String(source.get("item_id", ""))
		var quantity := int(source.get("quantity", 0))
		if item_id == "" or quantity <= 0:
			continue
		slots[i] = {
			"item_id": item_id,
			"quantity": quantity
		}

	inventory_changed.emit()
