class_name ItemDatabase
extends Resource

## ====================================================================
## Laboratorio 13 - Sección 28: Catálogo de Objetos (ItemDatabase)
## ====================================================================
## Permite mapear identificadores estables serializados (Strings/StringNames en JSON)
## hacia sus instancias correspondientes de ItemData con icono y descripción.

@export var items: Array[ItemData] = []

func get_item(item_id: StringName) -> ItemData:
	for item in items:
		if item != null and item.item_id == item_id:
			return item
	return null
