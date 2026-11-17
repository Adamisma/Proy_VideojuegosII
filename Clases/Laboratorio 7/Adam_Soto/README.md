# Laboratorio 07: Inteligencia Artificial Básica y Detección Vectorial

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyectos:** `Lab07_EnemyAI` y `Lab07_mAT`  

---

## 🎯 Objetivo de la Sesión
Diseñar la conducta autónoma de enemigos terrestres mediante percepción sensorial (visión, rango y abismos) combinada con cálculos matemáticos vectoriales para persecución, patrullaje y cambio de dirección.

---

## 🛠️ Implementaciones Realizadas

1. **Conductas de IA en `Lab07_EnemyAI`:**
   - **Patrulla con Waypoints:** El enemigo recorre una serie de puntos definidos en el escenario a velocidad constante, esperando brevemente en cada esquina.
   - **Detección de Abismos (`Ledge Detection`):** Empleo de nodos `RayCast2D` dirigidos hacia el suelo frente al enemigo. Al detectar la ausencia de suelo, invierte inmediatamente su dirección horizontal para no caer al vacío.
   - **Detección de Muros:** `RayCast2D` o comprobación de `is_on_wall()` para rebotar en obstáculos físicos.
   - **Rango de Visión (`Perception Area`):** `Area2D` frontal o circular que detecta la entrada del jugador (`body_entered`), transitando del estado de patrulla al estado de persecución (*Chase*).

2. **Matemáticas Aplicadas en `Lab07_mAT`:**
   - Cálculo del vector director normalizado hacia el jugador:  
     $$\vec{u} = \frac{\text{target\_pos} - \text{self\_pos}}{\|\text{target\_pos} - \text{self\_pos}\|}$$
   - Uso de la distancia euclidiana para determinar cuándo detener la persecución o iniciar un ataque a corta distancia.
   - Inversión de orientación de sprites según el signo de la velocidad horizontal.

---

## 💡 Conceptos Clave Aprendidos
- **RayCast2D para percepción táctica:** Permite predecir colisiones antes de que ocurran físicamente, fundamental para evitar que la IA caiga a la lava o acantilados.
- **Transición por Percepción:** La IA no debe saber mágicamente dónde está el jugador en todo momento; debe reaccionar a disparadores sensoriales creíbles.
