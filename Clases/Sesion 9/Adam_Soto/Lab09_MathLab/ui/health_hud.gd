extends Control

## ====================================================================
## Laboratorio 06 - Sección 21: HUD de Vida Desacoplado
## ====================================================================
## Patrón reactivo: Escucha la señal health_changed del HealthComponent
## y actualiza la barra sin consultar al Player en cada frame.

@export var health_component: HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var hp_label: Label = $HealthBar/HPLabel

func _ready() -> void:
	if health_component == null:
		return
	health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(health_component.current_health, health_component.max_health)

func bind_health_component(target_health: HealthComponent) -> void:
	if health_component and health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.disconnect(_on_health_changed)

	health_component = target_health
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		_on_health_changed(health_component.current_health, health_component.max_health)

func _on_health_changed(current: float, maximum: float) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if hp_label:
		hp_label.text = "%d / %d HP" % [int(current), int(maximum)]
