extends Node

## ====================================================================
## Laboratorio 12 - Secciones 17 a 23, 26, 31 & Reto 41: SaveManager
## ====================================================================
## Servicio desacoplado para persistencia de datos en disco mediante JSON en user://.
## Incluye versionado, validación de integridad, normalización y copia de respaldo.

signal save_started
signal save_finished(success: bool)
signal load_started
signal load_finished(success: bool)

const SAVE_PATH: String = "user://savegame.json"
const BACKUP_PATH: String = "user://savegame_backup.json"
const CURRENT_SAVE_VERSION: int = 1

## Comprueba si existe un archivo de guardado físico en user://
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Guarda el estado actual de GameState en user://savegame.json de forma segura
func save_game() -> bool:
	save_started.emit()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: No se pudo abrir save para escritura en: " + SAVE_PATH)
		save_finished.emit(false)
		return false

	var save_dict := _build_save_data()
	var json_text := JSON.stringify(save_dict, "  ")
	file.store_string(json_text)
	file.close()

	# Reto 41: Generar copia de respaldo del último guardado exitoso
	_write_backup(json_text)

	save_finished.emit(true)
	return true

## Carga el archivo desde disco, valida tipos y versionado, y restaura GameState
func load_game() -> bool:
	load_started.emit()

	if not has_save():
		load_finished.emit(false)
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		load_finished.emit(false)
		return false

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: Formato JSON inválido o corrupto en save principal.")
		# Intentar rescatar desde backup si existe
		if FileAccess.file_exists(BACKUP_PATH):
			return _load_from_backup()
		load_finished.emit(false)
		return false

	var success: bool = _apply_save_data(parsed)
	load_finished.emit(success)
	return success

func _load_from_backup() -> bool:
	push_warning("SaveManager: Intentando recuperar partida desde backup...")
	var b_file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if b_file == null:
		return false
	var b_content := b_file.get_as_text()
	b_file.close()

	var b_parsed = JSON.parse_string(b_content)
	if typeof(b_parsed) == TYPE_DICTIONARY:
		return _apply_save_data(b_parsed)
	return false

## Construye el diccionario serializable a partir del estado actual de GameState
func _build_save_data() -> Dictionary:
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"level_id": String(GameState.current_level_id),
		"checkpoint_id": String(GameState.active_checkpoint_id),
		"score": GameState.score,
		"collected_items": GameState.collected_items.map(func(id: StringName): return String(id))
	}

## Aplica y valida rigurosamente los datos antes de inyectarlos en GameState
func _apply_save_data(data: Dictionary) -> bool:
	# Sección 33: Migración de versiones
	var version := int(data.get("save_version", 0))
	if version != CURRENT_SAVE_VERSION:
		data = _migrate_save(data)

	# Validación de existencia de nivel en el catálogo de SceneFlow (Sección 23)
	var level_id := StringName(data.get("level_id", ""))
	if not SceneFlow.has_level(level_id):
		push_warning("SaveManager: El archivo referencia un nivel inválido: " + String(level_id))
		return false

	# Inyección segura en GameState
	GameState.current_level_id = level_id
	GameState.active_checkpoint_id = StringName(data.get("checkpoint_id", ""))

	# Caso P06: Normalización de puntuación negativa a 0
	var raw_score := int(data.get("score", 0))
	GameState.score = maxi(raw_score, 0)

	# Carga de coleccionables persistentes sin duplicados
	GameState.collected_items.clear()
	var raw_items = data.get("collected_items", [])
	if typeof(raw_items) == TYPE_ARRAY:
		for item in raw_items:
			var s_item := StringName(str(item))
			if s_item not in GameState.collected_items:
				GameState.collected_items.append(s_item)

	return true

## Sección 33: Migración conceptual de saves antiguos
func _migrate_save(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 0))
	if version == 0:
		if not data.has("checkpoint_id"):
			data["checkpoint_id"] = ""
		data["save_version"] = 1
	return data

## Sección 26: Eliminar archivo de guardado físico
func delete_save() -> bool:
	var deleted_main := true
	var deleted_backup := true

	if FileAccess.file_exists(SAVE_PATH):
		var abs_main := ProjectSettings.globalize_path(SAVE_PATH)
		deleted_main = (DirAccess.remove_absolute(abs_main) == OK)

	if FileAccess.file_exists(BACKUP_PATH):
		var abs_backup := ProjectSettings.globalize_path(BACKUP_PATH)
		deleted_backup = (DirAccess.remove_absolute(abs_backup) == OK)

	return deleted_main and deleted_backup

func _write_backup(content: String) -> void:
	var b_file := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	if b_file != null:
		b_file.store_string(content)
		b_file.close()

## Obtiene metadatos legibles para la pantalla de título
func get_save_info() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return {
		"level_id": parsed.get("level_id", "Desconocido"),
		"score": parsed.get("score", 0),
		"checkpoint_id": parsed.get("checkpoint_id", "Inicial"),
		"timestamp": parsed.get("timestamp", "")
	}

# ====================================================================
# SECCIÓN 27: SERIALIZACIÓN Y DESERIALIZACIÓN DE VECTOR2
# ====================================================================
func vector2_to_data(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y
	}

func data_to_vector2(data: Dictionary) -> Vector2:
	return Vector2(
		float(data.get("x", 0.0)),
		float(data.get("y", 0.0))
	)
