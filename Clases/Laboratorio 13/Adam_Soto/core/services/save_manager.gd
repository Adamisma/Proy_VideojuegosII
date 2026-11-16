extends Node

## ====================================================================
## Laboratorio 13 - Secciones 38 a 41: SaveManager con Persistencia de Inventario
## ====================================================================
## Administra la persistencia versionada (save_version: 2).
## Serializa nivel, checkpoint, score, items de mundo y slots de inventario en JSON.
## Incorpora tolerancia a fallos, backup automático y migraciones controladas (v1 -> v2).

signal save_started
signal save_finished(success: bool)
signal load_started
signal load_finished(success: bool)

const SAVE_PATH: String = "user://savegame.json"
const BACKUP_PATH: String = "user://savegame_backup.json"
const CURRENT_SAVE_VERSION: int = 2

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

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

	_write_backup(json_text)
	save_finished.emit(true)
	return true

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
		push_warning("SaveManager: Formato JSON inválido o corrupto.")
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

## Sección 39: Incluir inventario en el guardado
func _build_save_data() -> Dictionary:
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"level_id": String(GameState.current_level_id),
		"checkpoint_id": String(GameState.active_checkpoint_id),
		"score": GameState.score,
		"collected_items": GameState.collected_items.map(func(id: StringName): return String(id)),
		"inventory": GameState.inventory_data
	}

## Sección 23 & 40: Validar y restaurar datos
func _apply_save_data(data: Dictionary) -> bool:
	var version := int(data.get("save_version", 0))
	if version != CURRENT_SAVE_VERSION:
		data = _migrate_save(data)

	var level_id := StringName(data.get("level_id", ""))
	if not SceneFlow.has_level(level_id):
		push_warning("SaveManager: El archivo referencia un nivel inválido: " + String(level_id))
		return false

	GameState.current_level_id = level_id
	GameState.active_checkpoint_id = StringName(data.get("checkpoint_id", ""))

	var raw_score := int(data.get("score", 0))
	GameState.score = maxi(raw_score, 0)

	GameState.collected_items.clear()
	var raw_items = data.get("collected_items", [])
	if typeof(raw_items) == TYPE_ARRAY:
		for item in raw_items:
			var s_item := StringName(str(item))
			if s_item not in GameState.collected_items:
				GameState.collected_items.append(s_item)

	# Restaurar inventario persistido (Sección 40)
	var raw_inv = data.get("inventory", [])
	if typeof(raw_inv) == TYPE_ARRAY:
		GameState.inventory_data = raw_inv
	else:
		GameState.inventory_data = []

	return true

## Sección 41: Versionado y migración v1 -> v2
func _migrate_save(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 0))
	if version == 0:
		if not data.has("checkpoint_id"):
			data["checkpoint_id"] = ""
		version = 1

	if version == 1:
		if not data.has("inventory"):
			data["inventory"] = []
		data["save_version"] = 2

	return data

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
		"timestamp": parsed.get("timestamp", ""),
		"items_count": parsed.get("inventory", []).size()
	}
