# Laboratorio 06: Arquitectura Basada en Componentes y Sistema de Combate

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab06_CombatComponents`  

---

## 🎯 Objetivo de la Sesión
Adoptar el paradigma de **Composición sobre Herencia** mediante una arquitectura basada en componentes modulares y reutilizables para salud, cajas de golpe (*Hitboxes*) y cajas de daño (*Hurtboxes*), aplicable tanto al jugador como a los enemigos.

---

## 🛠️ Implementaciones Realizadas

1. **`HealthComponent` (Componente de Salud):**
   - Atributos exportados: `max_health`, `current_health`.
   - Métodos: `take_damage(amount: int)` y `heal(amount: int)`.
   - Señales desacopladas: `health_changed(current, max)`, `damaged(amount)`, `died()`.

2. **`HitboxComponent` (Caja de Golpe - Ofensiva):**
   - Nodo derivado de `Area2D`.
   - Propiedades: `damage`, `knockback_force`, `knockback_direction`.
   - Capa de colisión ofensiva que detecta exclusivamente receptores válidos.

3. **`HurtboxComponent` (Caja de Daño - Defensiva):**
   - Nodo derivado de `Area2D` con temporizador de inmunidad (*i-frames* / `invulnerability_timer`).
   - Al detectar un `HitboxComponent`, transmite el impacto al `HealthComponent` local y aplica la fuerza de retroceso (*knockback*) al `CharacterBody2D`.
   - Emite señal `hit_received(hitbox)` para disparar efectos visuales y auditivos.

4. **Demostración de Reutilización:**
   - Integración idéntica del componente de salud y áreas de daño tanto en el avatar del héroe como en dummies/enemigos de práctica sin duplicar una sola línea de código.

---

## 💡 Conceptos Clave Aprendidos
- **Composición vs Herencia:** Si un enemigo necesita salud, simplemente se le agrega un nodo hijo `HealthComponent`; no es necesario heredar de una clase base compleja `DamageableEntity`.
- **Frames de Invulnerabilidad (I-Frames):** Esenciales para evitar que una sola colisión aplique daño múltiple durante cada frame físico del juego.
