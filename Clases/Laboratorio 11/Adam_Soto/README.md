# Laboratorio 11: Arquitectura de Software y Patrones de Diseño

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab11_Architecture`  

---

## 🎯 Objetivo de la Sesión
Construir una arquitectura de código profesional, modular y de bajo acoplamiento para videojuegos en Godot 4, aplicando el patrón **Observer / Bus de Eventos (EventBus)** mediante Autoloads y gestionando el ciclo de vida del estado global con **GameState**.

---

## 🛠️ Implementaciones Realizadas

1. **Patrón Observer Global (`EventBus.gd`):**
   - Autoload centralizador de señales del juego:
     - Señales de jugador: `player_damaged(current_hp, max_hp)`, `player_died()`, `player_healed()`.
     - Señales de progreso: `score_changed(new_score)`, `checkpoint_activated(pos)`.
     - Señales de nivel: `level_completed()`, `game_paused(is_paused)`.
   - Permite que la UI, los enemigos y los sistemas de audio reaccionen a eventos sin tener referencias directas al nodo del jugador.

2. **Servicio de Estado Global (`GameState.gd`):**
   - Singleton responsable de mantener la información entre cambios de escenas:
     - Vidas restantes, monedas acumuladas, puntuación, tiempo transcurrido.
     - Métodos de manipulación segura y emisión de eventos automáticos al actualizar variables.

3. **Inyección de Dependencias y Modularidad:**
   - Separación estricta entre la capa de **Servicios Core**, la capa de **Entidades/Actores** y la capa de **Interfaz de Usuario (UI)**.

---

## 💡 Conceptos Clave Aprendidos
- **Problema del Acoplamiento Fuerte:** Si la UI depende directamente de `get_node("../Player")`, cualquier cambio en la estructura de la escena rompe el juego. Con `EventBus`, la UI simplemente se suscribe a `EventBus.player_damaged`.
- **Autoloads / Singletons:** En Godot se configuran en `project.godot` y residen en la raíz del árbol (`/root/`), existiendo permanentemente durante toda la sesión.
