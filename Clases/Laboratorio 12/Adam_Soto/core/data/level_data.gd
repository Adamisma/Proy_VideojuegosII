class_name LevelData
extends Resource

## ====================================================================
## Laboratorio 12 - Sección 8: LevelData como Custom Resource
## ====================================================================
## Describe los metadatos de un nivel sin necesidad de instanciar su árbol.
## Permite a SceneFlow y SaveManager validar rutas, títulos y secuencias.

@export var level_id: StringName
@export var display_name: String
@export_file("*.tscn") var scene_path: String
@export var next_level_id: StringName
