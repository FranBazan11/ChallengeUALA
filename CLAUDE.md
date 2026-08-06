# Reglas del proyecto

Este documento rige cómo se trabaja en este repo. Se aplica a todo el trabajo, con o sin skill invocada.

## Proceso

- No se escribe código de producción antes de que el use case correspondiente esté redactado en [docs/USE-CASES.md](docs/USE-CASES.md). Usar la skill `use-case` para eso.
- Cerrar una tarea significa: checklist tildado en `docs/USE-CASES.md` + entrada nueva en `docs/BITACORA.md`. Ninguna tarea se considera terminada sin las dos cosas.
- Toda decisión no obvia se registra en la entrada de la bitácora correspondiente, especialmente lo que se descartó y por qué. Lo que aplica a la entrega final también sube al README.

## Arquitectura

- El dominio no depende de nada. Las dependencias apuntan siempre hacia adentro.
- Los frameworks (SwiftData, URLSession, MapKit, SwiftUI) viven en los bordes del sistema, detrás de un protocolo definido por el dominio — nunca al revés.
- Separar lógica específica de la app (use cases) de lógica agnóstica y reutilizable (policies, modelos de dominio).
- Un único Composition Root, en el app target. Ningún módulo instancia componentes de otro módulo.
- Inyección de dependencias por initializer. Prohibidos los singletons y el estado global mutable.
- Cada capa usa su propia representación de modelo cuando compartirla generaría acoplamiento (por ejemplo, DTOs de red distintos del modelo de dominio).
- Value types e inmutabilidad por defecto. Cada `var` se justifica; si puede ser `let`, es `let`.
- Command-Query Separation: un método consulta o produce efectos, nunca las dos cosas a la vez.

## Testing

- Test primero. Rojo → verde → refactor. Sin excepciones.
- Testear a través de la interfaz pública de cada módulo. `@testable import` solo en el app target, para ejercitar el Composition Root.
- Una aserción conceptual por test.
- Los helpers de test propagan `file:` y `line:` para que un fallo señale el call site, no el helper.
- Verificar ausencia de memory leaks en las factories de test (`trackForMemoryLeaks`).
- Cero lógica condicional dentro de un test — si un test necesita un `if`, son dos tests.

## Git

- **Claude nunca ejecuta `git add`, `git commit` ni `git push`.** El trabajo se deja completo en el working tree. Claude entrega: resumen de qué cambió y por qué, el output real de correr la suite de tests, y el mensaje de commit redactado en español e imperativo, listo para que el usuario lo revise y lo ejecute.
- Crear la rama de la tarea sí es parte del trabajo de Claude: una rama por tarea, `feature/<slug-en-ingles>`.
- **Un MR nunca es un commit gigante.** Se entrega dividido en varios commits chicos, cada uno una unidad lógica sola (un archivo nuevo, una capa, un movimiento de archivos, una limpieza) — nunca "todo lo de esta tarea" en un solo diff. Cada commit, individualmente, deja el proyecto compilando y con la suite entera en verde.
- Al entregar, Claude propone la secuencia completa: qué archivos van en cada commit y el mensaje de cada uno, en el orden en que deberían aplicarse.
- Mensajes de commit en español, en imperativo (`Agregar índice de búsqueda de ciudades`, no `Agregado` ni `Agregando`).
- Abrir el MR contra `master` es del usuario. Claude entrega la descripción estructurada (qué, por qué, cómo verificarlo) lista para pegar.
- Nunca proponer un merge con tests en rojo.

## Estilo

- Sin librerías de terceros — lo prohíbe el enunciado del challenge.
- Nombres explícitos. Sin abreviaturas.
- **Sin comentarios.** El código se explica solo: nombres que dicen la intención, funciones chicas, tipos que hacen irrepresentable lo inválido. Si aparece la tentación de escribir un comentario, es señal de renombrar o extraer una función, no de agregar texto.
- **Única excepción, y ninguna más sin aprobación del usuario:** un doc comment (`///`) sobre el tipo del índice de búsqueda, justificando por qué esa representación (array ordenado + binary search) es más eficiente que las alternativas. No es una concesión de estilo: el enunciado lo pide como criterio de evaluación explícito, y pide textualmente que la justificación vaya en el código:
  > *"You can preprocess the list into any other representation that you consider more efficient for searches and display. Provide information of why that representation is more efficient in the comments of the code."* — sección *Evaluation criteria*, ver [docs/REQUISITOS.md](docs/REQUISITOS.md)

## Autoría

- Todo archivo creado lleva un header con el nombre del autor y la fecha del día en que se crea.
- En Swift, el header estándar de Xcode:
  ```swift
  //
  //  CityCatalog.swift
  //  Cities
  //
  //  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
  //
  ```
- En Markdown, una línea de atribución debajo del título: `*Juan Francisco Bazan Carrizo — 6 de agosto de 2026*`
- Este header es metadata de autoría, no un comentario explicativo — no contradice la regla de "sin comentarios" de arriba.
