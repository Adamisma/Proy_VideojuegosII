extends CharacterBody2D
class_name EnemyDummy

## ====================================================================
## Laboratorio 11 - Sección 35: EnemyDummy Reutilizando Componentes y Resources
## ====================================================================
## Maniquí de entrenamiento refactorizado para consumir la arquitectura común:
## 1. CharacterStats (enemy_basic_stats.tres) desacopla la vida y resistencia.
## 2. HealthComponent compartido inicializado mediante configure_from_stats.
## 3. Shaders de daño y dissolve (Semana 10) preservados intactos.
## 4. Recompensa de puntuación integrada a GameState y EventBus al morir.

const HIT_FX_SCENE: PackedScene = preload("res://scenes/vfx/fx_hit.tscn")
const DEATH_BURST_SCENE: PackedScene = preload("res://scenes/vfx/fx_death_burst.tscn")
const DAMAGE_FLASH_MAT: Material = preload("res://materials/mat_damage_flash.tres")
const DISSOLVE_MAT: Material = preload("res://materials/mat_dissolve.tres")

# --- RECURSOS Y COMPONENTES (Sección 35) ---
@export_category("Architecture")
@export var stats: CharacterStats = preload("res://resources/stats/enemy_basic_stats.tres")
@export var gravity: float = 1200.0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var health_bar: ProgressBar = $OverheadHUD/HealthBar

var is_dead: bool = false
var flash_material: ShaderMaterial
var dissolve_material: ShaderMaterial

func _ready() -> void:
	# Sección 35 & 36: Configuración del componente de salud desde Resource
	if stats != null:
		health.configure_from_stats(stats)

	# Duplicar material por instancia para no mutar otros maniquíes
	if DAMAGE_FLASH_MAT:
		flash_material = DAMAGE_FLASH_MAT.duplicate() as ShaderMaterial
	if DISSOLVE_MAT:
		dissolve_material = DISSOLVE_MAT.duplicate() as ShaderMaterial

	if sprite and flash_material:
		sprite.material = flash_material

	# Conexión a señales locales del componente
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	if health_bar:
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	# Fricción para desacelerar tras recibir knockback
	velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
	move_and_slide()

## Integración con VFX y cámara al recibir impacto
func _on_hit_received(attack: AttackData, direction: Vector2) -> void:
	if is_dead:
		return

	velocity = direction * attack.knockback_force
	play_damage_flash()

	var is_crit: bool = attack.damage >= 25.0
	_spawn_hit_vfx(direction, is_crit)

	var camera := get_viewport().get_camera_2d() as MathCamera
	if camera:
		camera.trigger_shake(6.0 if is_crit else 4.0)

func play_damage_flash() -> void:
	if sprite == null or flash_material == null or is_dead:
		return

	flash_material.set_shader_parameter("flash_amount", 1.0)
	var tween := create_tween()
	tween.tween_method(
		func(val: float): flash_material.set_shader_parameter("flash_amount", val),
		1.0,
		0.0,
		0.15
	)

func _spawn_hit_vfx(direction: Vector2, is_crit: bool = false) -> void:
	var vfx_spawner := get_tree().root.find_child("VFXSpawner", true, false) as VFXSpawner
	var angle: float = direction.angle() if direction.length_squared() > 0.0001 else 0.0
	if vfx_spawner:
		var hit_effect := vfx_spawner.spawn_effect(HIT_FX_SCENE, global_position + Vector2(0, -10), angle) as FXHit
		if hit_effect:
			hit_effect.is_critical = is_crit
	else:
		var hit := HIT_FX_SCENE.instantiate() as FXHit
		hit.is_critical = is_crit
		get_parent().add_child(hit)
		hit.global_position = global_position + Vector2(0, -10)
		hit.orient_to_direction(direction)

func _on_health_changed(current: int, maximum: int) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current

## Muerte del maniquí con recompensa en GameState (Secciones 22 & 35)
func _on_died() -> void:
	if is_dead:
		return
	is_dead = true

	# Sumar puntuación a servicio global
	if GameState:
		GameState.add_score(50)

	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("HurtboxComponent/CollisionShape2D"):
		$HurtboxComponent/CollisionShape2D.set_deferred("disabled", true)
	if health_bar:
		health_bar.visible = false

	var camera := get_viewport().get_camera_2d() as MathCamera
	if camera:
		camera.trigger_shake(8.5)

	var vfx_spawner := get_tree().root.find_child("VFXSpawner", true, false) as VFXSpawner
	if vfx_spawner:
		vfx_spawner.spawn_effect(DEATH_BURST_SCENE, global_position)

	if sprite and dissolve_material:
		sprite.material = dissolve_material
		dissolve_and_remove(sprite)
	else:
		var tween := create_tween()
		tween.tween_property(visuals, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)

func dissolve_and_remove(target_sprite: CanvasItem) -> void:
	var mat := target_sprite.material as ShaderMaterial
	if mat == null:
		queue_free()
		return

	var tween := create_tween()
	tween.tween_method(
		func(val: float): mat.set_shader_parameter("threshold", val),
		0.0,
		1.0,
		0.85
	)
	tween.tween_callback(queue_free)
