class_name TouchControls
extends Control

## ====================================================================
## Proyecto Cahuide - Controles Táctiles Móviles Responsivos
## ====================================================================
## - En Android / Móvil: Se activan y muestran automáticamente.
## - En Windows / Desktop: Permanecen 100% ocultos por defecto.
## - Tecla de prueba en PC: Presiona F1 para alternar la visibilidad táctil.
## - En Menú de Pausa: Se ocultan automáticamente para dejar la UI limpia.

@export var force_desktop_touch: bool = false

@onready var movement_group: Control = get_node_or_null("MarginContainer/MovementGroup")
@onready var action_group: Control = get_node_or_null("MarginContainer/ActionGroup")
@onready var top_group: Control = get_node_or_null("MarginContainer/TopGroup")
@onready var margin_container: MarginContainer = get_node_or_null("MarginContainer")


func _ready() -> void:
	# Permitir procesar la tecla F1 incluso si otros nodos están pausados
	process_mode = Node.PROCESS_MODE_ALWAYS

	# El overlay no debe interceptar eventos de ratón/toque que no caigan en los botones
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ajustar márgenes según el área segura del dispositivo móvil (Notches / Isla dinámica)
	_apply_safe_area()

	# Reaccionar si cambia la resolución o rotación de pantalla
	if get_viewport():
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Notificación cuando se activa o desactiva la pausa
	if EventBus and EventBus.has_signal("game_paused"):
		EventBus.game_paused.connect(_on_game_paused)

	# Inicializar visibilidad según la plataforma de ejecución
	update_controls_visibility()


## Determina si la plataforma actual requiere controles táctiles en pantalla
func is_touch_enabled() -> bool:
	# 1. Si el desarrollador forzó la visualización en PC con F1
	if force_desktop_touch:
		return true

	# 2. Si estamos en PC / Escritorio (Windows, macOS, Linux): NUNCA mostrar táctil por defecto
	if OS.has_feature("pc") or OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linux"):
		return false

	# 3. Plataformas móviles nativas (Android, iOS)
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true

	# 4. Navegadores móviles
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true

	return false


## Actualiza la visibilidad respetando el estado de pausa y la plataforma
func update_controls_visibility() -> void:
	# Durante la pausa del juego, los controles táctiles SIEMPRE deben estar ocultos
	if get_tree() and get_tree().paused:
		_set_controls_visible(false)
	else:
		_set_controls_visible(is_touch_enabled())


func _set_controls_visible(p_visible: bool) -> void:
	visible = p_visible
	if margin_container:
		margin_container.visible = p_visible


func _unhandled_key_input(event: InputEvent) -> void:
	# Atajo de desarrollo: Tecla F1 alterna los controles táctiles en PC para pruebas
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		force_desktop_touch = not force_desktop_touch
		update_controls_visibility()
		var ui_ctrl := get_parent() as UIController
		if ui_ctrl:
			var msg := "Controles táctiles: ACTIVADOS (F1)" if force_desktop_touch else "Controles táctiles: OCULTOS (F1)"
			ui_ctrl.show_toast(msg, Color(0.3, 0.85, 1.0))
		get_viewport().set_input_as_handled()


func _on_viewport_size_changed() -> void:
	_apply_safe_area()


func _apply_safe_area() -> void:
	if not margin_container:
		return

	# Márgenes base para pantallas 16:9 y superiores
	var left_m: int = 24
	var right_m: int = 24
	var top_m: int = 18
	var bottom_m: int = 24

	# Si estamos en un dispositivo con notch / cutout, aplicar safe area nativa
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if screen_size.x > 0 and screen_size.y > 0 and safe_area != Rect2i():
		var safe_left: int = safe_area.position.x
		var safe_top: int = safe_area.position.y
		var safe_right: int = screen_size.x - (safe_area.position.x + safe_area.size.x)
		var safe_bottom: int = screen_size.y - (safe_area.position.y + safe_area.size.y)

		left_m = maxi(left_m, safe_left)
		right_m = maxi(right_m, safe_right)
		top_m = maxi(top_m, safe_top)
		bottom_m = maxi(bottom_m, safe_bottom)

	margin_container.add_theme_constant_override("margin_left", left_m)
	margin_container.add_theme_constant_override("margin_right", right_m)
	margin_container.add_theme_constant_override("margin_top", top_m)
	margin_container.add_theme_constant_override("margin_bottom", bottom_m)


func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		_set_controls_visible(false)
	else:
		update_controls_visibility()


## Permite alternar la visibilidad de los controles táctiles manualmente
func toggle_visibility() -> void:
	force_desktop_touch = not force_desktop_touch
	update_controls_visibility()
