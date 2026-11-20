class_name ProjectilePool
extends RefCounted

## ====================================================================
## Proyecto Cahuide - Pool Centralizado de Proyectiles y VFX
## ====================================================================
## Reutiliza nodos de proyectiles para evitar recolección de basura (GC)
## y micro-tirones de fotogramas en Android y dispositivos de gama media.

static var _pools: Dictionary = {}

static func acquire(scene: PackedScene, parent: Node, spawn_pos: Vector2) -> Node2D:
	if scene == null:
		return null

	var key := scene.resource_path
	if not _pools.has(key):
		_pools[key] = []

	var pool: Array = _pools[key]
	var item: Node2D = null

	# Buscar una instancia dormida en el pool
	for inst in pool:
		if is_instance_valid(inst) and not inst.visible and not inst.is_physics_processing():
			item = inst
			break

	if item == null:
		item = scene.instantiate() as Node2D
		if "is_pooled" in item:
			item.is_pooled = true
		pool.append(item)
		if parent and is_instance_valid(parent):
			parent.add_child(item)
	elif item.get_parent() != parent and parent and is_instance_valid(parent):
		if item.get_parent():
			item.get_parent().remove_child(item)
		parent.add_child(item)

	if item.has_method("activate"):
		item.activate(spawn_pos)
	else:
		item.global_position = spawn_pos
		item.show()
		item.set_physics_process(true)

	return item


static func reset() -> void:
	_pools.clear()
