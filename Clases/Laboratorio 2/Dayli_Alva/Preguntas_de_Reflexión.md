# Preguntas de reflexión

## 6. ¿Cuál es la diferencia entre un nodo y una escena?

Un nodo es un elemento individual que cumple una función específica, como mostrar una imagen, detectar colisiones o controlar al personaje. Una escena es un conjunto de nodos organizados que puede guardarse y reutilizarse.

## 7. ¿Por qué conviene instanciar una escena Collectible en vez de duplicar manualmente su lógica?

Porque permite reutilizar la misma estructura y lógica para crear varios objetos recolectables. De esta manera, no es necesario programar cada objeto individualmente y se pueden realizar cambios en la escena original de forma más sencilla.

## 8. ¿Qué problema evita Input Map frente a leer teclas directamente?

Evita depender de una tecla específica, ya que permite utilizar acciones como move_left o move_right y asignarles diferentes teclas o controles.

## 9. ¿Cuál es la responsabilidad de `_physics_process()`?

Se encarga de ejecutar la lógica relacionada con el movimiento y la física del personaje de forma periódica, como actualizar su velocidad y moverlo.

## 10. ¿Por qué es preferible emitir una señal desde Collectible en vez de modificar directamente el puntaje de Main?

Porque permite mantener separadas las responsabilidades. Collectible informa mediante una señal que fue recogido y Main se encarga de actualizar el puntaje. Esto hace que el código sea más organizado, reutilizable y fácil de modificar.

## 11. ¿Qué ventaja aporta identificar Player mediante un grupo?

Permite identificar al jugador mediante el grupo player sin depender de una ruta específica. Esto hace que el código sea más flexible y reutilizable.