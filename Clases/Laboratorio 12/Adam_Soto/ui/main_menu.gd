class_name MainMenu
extends Control

## ====================================================================
## Laboratorio 12 - Secciones 24, 25 & 35: Menú Principal con Persistencia
## ====================================================================
## Interfaz de inicio que gestiona el ciclo de vida de la partida:
## - "Nueva partida": Reinicia GameState, inicializa savegame.json y carga level_01.
## - "Continuar": Carga y valida el archivo desde user:// y restaura nivel y checkpoint.
## - "Eliminar partida": Borra el save físico de forma segura.

@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var new_game_btn: Button = $CenterContainer/VBoxContainer/Buttons/NewGameButton
@onready var continue_btn: Button = $CenterContainer/VBoxContainer/Buttons/ContinueButton
@onready var delete_save_btn: Button = $CenterContainer/VBoxContainer/Buttons/DeleteSaveButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var save_info_label: Label = $CenterContainer/VBoxContainer/SaveInfoLabel

func _ready() -> void:
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	delete_save_btn.pressed.connect(_on_delete_save_pressed)

	_update_ui_state()

func _update_ui_state() -> void:
	var has_save: bool = SaveManager.has_save() if SaveManager else false
	continue_btn.disabled = not has_save
	delete_save_btn.disabled = not has_save

	if has_save and SaveManager:
		var info: Dictionary = SaveManager.get_save_info()
		var lvl: String = info.get("level_id", "level_01")
		var score: int = info.get("score", 0)
		var cp: String = info.get("checkpoint_id", "")
		var cp_text := (" [CP: %s]" % cp) if cp != "" else ""
		save_info_label.text = "Progreso guardado: %s%s | Puntos: %d" % [lvl.to_upper(), cp_text, score]
		save_info_label.modulate = Color(0.4, 0.9, 1.0)
		status_label.text = "Partida lista para continuar."
		status_label.modulate = Color(0.3, 1.0, 0.45)
		continue_btn.grab_focus()
	else:
		save_info_label.text = "No se detectó ningún archivo de guardado."
		save_info_label.modulate = Color(0.65, 0.65, 0.65)
		status_label.text = "Inicia una Nueva Partida para comenzar."
		status_label.modulate = Color(0.85, 0.85, 0.85)
		new_game_btn.grab_focus()

## Sección 25: Nueva partida
func _on_new_game_pressed() -> void:
	if GameState:
		GameState.start_new_game()
	if SaveManager:
		SaveManager.save_game()

	var target_lvl := GameState.current_level_id if GameState else &"level_01"
	if SceneFlow:
		SceneFlow.go_to_level(target_lvl, 0.3)

## Sección 24: Continuar partida guardada
func _on_continue_pressed() -> void:
	if SaveManager == null or not SaveManager.load_game():
		_show_load_error()
		return

	var target_lvl := GameState.current_level_id if GameState else &"level_01"
	if SceneFlow:
		SceneFlow.go_to_level(target_lvl, 0.3)

## Sección 26: Eliminar partida guardada
func _on_delete_save_pressed() -> void:
	if SaveManager and SaveManager.delete_save():
		status_label.text = "Archivo de guardado eliminado exitosamente."
		status_label.modulate = Color(1.0, 0.75, 0.3)
		_update_ui_state()

func _show_load_error() -> void:
	status_label.text = "Error al leer el archivo de guardado (posible corrupción)."
	status_label.modulate = Color(1.0, 0.3, 0.3)
