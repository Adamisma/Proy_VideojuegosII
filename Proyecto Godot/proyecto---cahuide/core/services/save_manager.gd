extends Node

## ====================================================================
## Proyecto Cahuide - SaveManager (Persistencia Versionada Segura)
## ====================================================================
## Guarda y carga el progreso (nivel, checkpoint, score, reliquias) en JSON.

signal save_started
signal save_finished(success: bool)
signal load_started
signal load_finished(success: bool)

const SAVE_PATH: String = "user://cahuide_save.json"
const BACKUP_PATH: String = "user://cahuide_save_backup.json"
const CURRENT_VERSION: int = 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	save_started.emit()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: No se pudo abrir save para escritura.")
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
		push_warning("SaveManager: Archivo corrupto. Intentando backup...")
		if FileAccess.file_exists(BACKUP_PATH):
			return _load_from_backup()
		load_finished.emit(false)
		return false

	var success := _apply_save_data(parsed)
	load_finished.emit(success)
	return success

func _load_from_backup() -> bool:
	var b_file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if b_file == null:
		return false
	var b_content := b_file.get_as_text()
	b_file.close()

	var b_parsed = JSON.parse_string(b_content)
	if typeof(b_parsed) == TYPE_DICTIONARY:
		return _apply_save_data(b_parsed)
	return false

func _build_save_data() -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"level_id": String(GameState.current_level_id),
		"checkpoint_id": String(GameState.active_checkpoint_id),
		"score": GameState.score,
		"enemies_killed": GameState.enemies_killed,
		"collected_relics": GameState.collected_relics.map(func(id: StringName): return String(id))
	}

func _apply_save_data(data: Dictionary) -> bool:
	var level_id := StringName(data.get("level_id", "level_01"))
	GameState.current_level_id = level_id
	GameState.active_checkpoint_id = StringName(data.get("checkpoint_id", ""))
	GameState.score = maxi(int(data.get("score", 0)), 0)
	GameState.enemies_killed = maxi(int(data.get("enemies_killed", 0)), 0)

	GameState.collected_relics.clear()
	var raw_relics = data.get("collected_relics", [])
	if typeof(raw_relics) == TYPE_ARRAY:
		for r in raw_relics:
			var s_r := StringName(str(r))
			if s_r not in GameState.collected_relics:
				GameState.collected_relics.append(s_r)

	return true

func delete_save() -> bool:
	var d1 := true
	var d2 := true
	if FileAccess.file_exists(SAVE_PATH):
		var p1 := ProjectSettings.globalize_path(SAVE_PATH)
		d1 = (DirAccess.remove_absolute(p1) == OK)
	if FileAccess.file_exists(BACKUP_PATH):
		var p2 := ProjectSettings.globalize_path(BACKUP_PATH)
		d2 = (DirAccess.remove_absolute(p2) == OK)
	return d1 and d2

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
		"level_id": parsed.get("level_id", "level_01"),
		"score": parsed.get("score", 0),
		"checkpoint_id": parsed.get("checkpoint_id", ""),
		"timestamp": parsed.get("timestamp", ""),
		"relics_count": parsed.get("collected_relics", []).size()
	}
