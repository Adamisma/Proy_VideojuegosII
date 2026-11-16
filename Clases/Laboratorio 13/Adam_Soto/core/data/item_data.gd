class_name ItemData
extends Resource

## ====================================================================
## Laboratorio 13 - Sección 22: ItemData como Custom Resource
## ====================================================================
## Describe las propiedades base e inmutables de un objeto del juego.
## Separa la definición (datos de catálogo) de la cantidad dinámica en el inventario.

@export var item_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var max_stack: int = 99
@export var consumable: bool = false
@export var heal_amount: int = 0
@export var score_amount: int = 0
