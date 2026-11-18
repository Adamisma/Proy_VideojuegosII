class_name UIController
extends CanvasLayer

## ====================================================================
## Proyecto Cahuide - UIController Orquestador Maestro (Desktop & Mobile)
## ====================================================================
## Centraliza HUD, Controles Táctiles Móviles, Menú de Pausa y Notificaciones Toasts.
## Garantiza compatibilidad multi-plataforma transparente:
## - En Windows / Desktop: Controles táctiles 100% ocultos (F1 para pruebas).
## - En Android / Mobile: Controles táctiles activos y visibles en pantalla.
## - Menú de Pausa totalmente independiente, accesible por tecla P, Escape o botón táctil.

@onready var pause_menu: PauseMenu = get_node_or_null("PauseMenu")
@onready var notification_layer: NotificationLayer = get_node_or_null("NotificationLayer")
@onready var touch_controls: TouchControls = get_node_or_null("TouchControls")


func _ready() -> void:
	# El CanvasLayer principal SIEMPRE debe estar visible para que sus componentes
	# (HUD, PauseMenu, Notificaciones) no queden ocultos si se desactivó el nodo en el editor
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	if pause_menu:
		pause_menu.visible = false
		pause_menu.resumed.connect(_on_pause_menu_resumed)

	if touch_controls:
		touch_controls.update_controls_visibility()

	# Suscripción a eventos para toasts discretos
	if EventBus:
		EventBus.relic_collected.connect(func(_rem: int, _tot: int):
			show_toast("+50 Puntos (Reliquia)", Color(1.0, 0.85, 0.3))
		)
		EventBus.checkpoint_activated.connect(func(_id: StringName):
			show_toast("Punto de Control Guardado", Color(0.3, 1.0, 0.45))
		)
		EventBus.player_powerup_activated.connect(func(_dur: float):
			show_toast("¡Poder del Sol Activado!", Color(1.0, 0.9, 0.2))
		)
		EventBus.ranged_weapon_swapped.connect(func(w_name: String):
			show_toast("Arma: %s" % w_name, Color(0.4, 0.85, 1.0))
		)


## Gestión de ciclo de vida móvil: Pausa automática al perder foco o recibir llamada
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_auto_pause_mobile()


func _auto_pause_mobile() -> void:
	if pause_menu and not pause_menu.visible:
		_toggle_pause()


func _unhandled_input(event: InputEvent) -> void:
	var is_pause_key := false
	if event.is_action_pressed("pause"):
		is_pause_key = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			is_pause_key = true

	if is_pause_key:
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if pause_menu:
		if pause_menu.visible:
			pause_menu.close_menu()
			if touch_controls:
				touch_controls.update_controls_visibility()
		else:
			if touch_controls:
				touch_controls.visible = false
			pause_menu.open_menu()


func _on_pause_menu_resumed() -> void:
	if touch_controls:
		touch_controls.update_controls_visibility()


func show_toast(msg: String, color: Color = Color(1.0, 0.85, 0.2)) -> void:
	if notification_layer:
		notification_layer.show_toast(msg, color)
