# Laboratorio 08: Navegación 2D y Pathfinding con NavigationServer2D

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab08_NavigationAI`  

---

## 🎯 Objetivo de la Sesión
Implementar búsqueda inteligente de caminos (*Pathfinding*) en dos dimensiones utilizando el subsistema de navegación nativo de Godot 4 (`NavigationServer2D`), polígonos de navegación navegables (`NavigationRegion2D`) y el nodo agente (`NavigationAgent2D`).

---

## 🛠️ Implementaciones Realizadas

1. **Malla de Navegación (`NavigationRegion2D`):**
   - Horneado (*baking*) de polígonos navegables sobre el escenario de plataformas y obstáculos.
   - Definición de zonas transitables para enemigos terrestres y aéreos.

2. **Integración de `NavigationAgent2D`:**
   - Asignación del nodo agente a cada enemigo.
   - Configuración de parámetros: `path_desired_distance`, `target_desired_distance`, `path_max_distance`.
   - Consulta periódica del siguiente punto del camino mediante `get_next_path_position()`.

3. **Evasión de Obstáculos Dinámica (*RVO / Avoidance*):**
   - Configuración de capas y radios de evitación (`radius`, `neighbor_distance`).
   - Envío de velocidad deseada con `set_velocity()` y respuesta segura a la señal `velocity_computed` para evitar que múltiples enemigos se superpongan entre sí al perseguir al jugador.

---

## 💡 Conceptos Clave Aprendidos
- **Diferencia entre RayCasts simples y Pathfinding:** Los RayCasts sirven para reacciones inmediatas de corto alcance; la navegación con NavMesh permite a los enemigos rodear laberintos y estructuras complejas sin quedarse atascados.
- **Asincronía en NavigationServer2D:** En Godot 4, el cálculo de rutas se procesa de forma optimizada en hilos de navegación dedicados del motor.
