---
name: mr-review
description: Use when a task-mr cycle has finished implementing and the working tree is ready for independent review before the user commits — dispatches specialized-lens subagents against the uncommitted diff, verifies the test suite is green, and hands off a Critical/Warning/Suggestion report.
---

# mr-review

Una revisión independiente del trabajo de una tarea, con varios lentes especializados en paralelo, antes de que el usuario lo commitee. No reemplaza a `task-mr` — corre sobre lo que `task-mr` deja en el working tree sin stagear (o sobre commits locales todavía sin pushear), y nunca commitea, pushea ni corrige código: solo audita y reporta.

## Cuándo usarla

Al terminar el ciclo de `task-mr` (o cualquier tarea con cambios en la rama actual), antes de que el usuario revise y commitee. También sirve como chequeo intermedio a mitad de una tarea larga — en ese caso el lente 6 todavía no tiene una secuencia de commits propuesta que auditar, y un checklist parcialmente tildado no es un hallazgo por sí solo.

## Pasos

### Fase 0 — Reunir contexto

1. **Ubicar la historia.** Leer la rama actual (`git branch --show-current`). Buscar en [docs/USE-CASES.md](../../../docs/USE-CASES.md) una historia cuyo título o use case comparta palabras clave con el slug de la rama (`feature/<slug>` → separar el slug por guiones). Un match es razonable cuando al menos dos palabras clave coinciden con una única historia y ninguna otra historia iguala esa cantidad. Ante empate o cero coincidencias, preguntar al usuario cuál es la historia — no adivinar. Esa historia y su checklist son el contrato de referencia de la revisión.

2. **Base branch.** Es `master`, siempre, sin preguntar. Confirmar con el usuario solo si el diff del paso 4 da vacío o con una forma que no tiene sentido para la tarea.

3. **Contexto de commits.** Correr:
   ```
   git rev-list --left-right --count master...HEAD
   ```
   El segundo número es cuántos commits tiene la rama que `master` no tiene. Si es mayor que cero, ya hay commits locales sin pushear — dato para el contexto de la Fase 1 y para el lente 6, no cambia cómo se arma el diff del paso siguiente.

4. **Armar el diff completo.** Un solo mecanismo cubre "todo sin commitear" y "ya hay commits locales" a la vez:
   - Trackeados: `git diff master -- .`. Comparar directo contra `master` (no `...HEAD`) ya incluye tanto los commits locales que pueda haber en la rama como los cambios sin commitear encima.
   - Untracked: `git status --porcelain=v1 | grep '^??'`, y leer el contenido completo de cada uno — son "archivo entero nuevo", no hay diff que generarles. Si algún untracked es muy grande (fixture o JSON de más de ~500 líneas), no volcar el contenido completo: anotar ruta, tamaño y un extracto representativo, para no inflar el contexto de los subagentes sin necesidad.
   - **Prohibido** usar `git add -N` o cualquier variante de `git add` para forzar que un untracked aparezca en un diff. [CLAUDE.md](../../../CLAUDE.md) prohíbe absolutamente que Claude corra `git add` bajo cualquier forma, y esta skill no es la excepción.

5. **Correr la suite real.** Mismo criterio que el paso 4 de `task-mr`: según qué carpetas tocó el diff (`Cities/`, `CitiesTests/` → scheme `Cities`; `CitiesiOS/`, `ChallengeUALA/` o sus test targets → scheme `CI_iOS`), correr los comandos reales documentados en [README.md](../../../README.md), por ejemplo:
   ```bash
   xcodebuild test -project ChallengeUALA.xcodeproj -scheme Cities \
     -destination 'platform=macOS' -testPlan Cities

   xcodebuild test -project ChallengeUALA.xcodeproj -scheme CI_iOS \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -testPlan CI_iOS
   ```
   Leer el output real — no confiar en que el autor dice que los tests pasan. Si el diff toca solo `docs/`/`README.md` sin código ni tests, correrlos no aporta nada y se puede omitir, anotándolo en el contexto compartido.

   Distinguir un **fallo de entorno** (simulador inexistente, DerivedData corrupto, build error no relacionado al diff) de un **test realmente rojo**. Solo un test rojo genuino es Critical bloqueante; un problema de entorno se reporta aparte, sin tratarlo como hallazgo de la revisión, pidiendo que se resuelva para poder verificar.

### Fase 1 — Contexto compartido

6. Escribir dos archivos en `/tmp` para que los subagentes de la Fase 2 no dupliquen este trabajo:
   - `/tmp/mr-review-diff.txt` — el resultado de `git diff master -- .`, seguido de un bloque por cada archivo untracked con su ruta y contenido (completo o extracto según el paso 4).
   - `/tmp/mr-review-context.md` — la historia y el checklist del paso 1, branch/base/ahead-behind del paso 3, el output real de los tests del paso 5, y — si ya existe en la conversación porque `task-mr` llegó a su paso 7 — la secuencia de commits propuesta y la descripción de MR. Si todavía no existe, anotar "no disponible todavía", no inventarla ni pedírsela al usuario.

### Fase 2 — Lentes en paralelo

7. Lanzar en un único mensaje varias invocaciones del tool `Agent` (`subagent_type: general-purpose`), una por lente, cada una ciega a las demás. Los seis son de **solo lectura**: no editan ni escriben ningún archivo, solo devuelven texto con sus hallazgos. La rúbrica es siempre la misma: [CLAUDE.md](../../../CLAUDE.md) (arquitectura, testing, git, estilo) y [docs/REQUISITOS.md](../../../docs/REQUISITOS.md) (criterios de evaluación del challenge). Prompt base común (reemplazar `<LENTE>` y `<FOCO>`):

   ```
   Sos un revisor de código especializado en un único lente: <LENTE>. Ignorá todo lo que no sea tu lente — otros revisores cubren el resto. No escribís ni editás ningún archivo, solo reportás.

   Leé primero /tmp/mr-review-context.md y /tmp/mr-review-diff.txt.

   Tu rúbrica es exclusivamente:
   - CLAUDE.md (arquitectura, testing, git, estilo del proyecto)
   - docs/REQUISITOS.md (criterios de evaluación del challenge)

   Tu foco específico: <FOCO>

   Para cada hallazgo: severidad (Critical/Warning/Suggestion), archivo y línea aproximada, qué está mal, por qué importa según la rúbrica, y qué pasaría si no se corrige (escenario concreto, no genérico). No reportes nada que no puedas señalar en un archivo real del diff. No repitas el diff ni resumas lo que ya está bien — solo lo que falla o es mejorable.

   Devolvé la lista de hallazgos como tu respuesta final.
   ```

   Los seis `<LENTE>` / `<FOCO>`:

   1. **Arquitectura y diseño Swift** — dependency rule (el dominio no depende de nada), Composition Root único, DI por initializer (nada de singletons ni estado global mutable), dónde vive cada protocolo (definido del lado interno, implementado del lado de afuera), Command-Query Separation, value types e inmutabilidad (`var` solo si se justifica), Swift API design guidelines (naming, access control, structs vs. classes, enums para modelar estados/errores en vez de optionals o bools sueltos), acoplamiento entre módulos (`Cities`, `CitiesiOS`, `ChallengeUALA`).
   2. **Performance** — eficiencia algorítmica real de cualquier claim de complejidad (por ejemplo, que el índice de 200k ciudades efectivamente hace binary search y no un recorrido lineal disfrazado), copias innecesarias de colecciones grandes, value vs. reference types en hot paths, trabajo redundante evitable.
   3. **Concurrencia** — manejo de threads en código async (`HTTPClient`, `URLSession`), dispatch a main/UI, retain cycles en closures (captura de `self`), condiciones de carrera, semántica de cancelación y de completion handlers.
   4. **Testing y disciplina TDD** — evidencia de rojo→verde→refactor en el diff, y conformidad exacta, ítem por ítem, con la sección "Estructura de un archivo de test" de `CLAUDE.md`: `makeSUT` como único lugar de construcción del SUT (con la excepción de structs, que no trackean leaks, y de mappers estáticos sin dependencias, que no necesitan `makeSUT`), factories de datos que devuelven `(model, json)`, aserciones repetidas extraídas a `expect(...)` con `file:`/`line:`, helpers `private` agrupados al final bajo `// MARK: - Helpers` y nunca en una `extension XCTestCase` global, `trackForMemoryLeaks` en las factories cuando el SUT es un reference type.
   5. **Estilo y convenciones del proyecto** — nombres explícitos sin abreviaturas, cero comentarios explicativos (la única excepción aprobada es el `///` sobre el tipo del índice de búsqueda de ciudades justificando la representación — cualquier otro comentario es un hallazgo), headers de autoría de Xcode correctos y con la fecha real del día de creación, cero librerías de terceros.
   6. **Bugs, cumplimiento del use case y proceso de entrega** — lógica incorrecta, edge cases o sad paths de la historia sin cubrir, ítems del checklist de `docs/USE-CASES.md` tildados sin un test real que los respalde (un ítem sin tildar todavía no es un hallazgo), y auditoría del propio proceso de `task-mr`: ¿hay entrada nueva en `docs/BITACORA.md` con qué se descartó y por qué (no es opcional)? Y — solo si el paso 6 encontró una secuencia de commits ya propuesta — ¿son varios commits chicos que dejan el proyecto compilando y la suite en verde en cada uno, o es "todo en un commit gigante"? Si todavía no hay secuencia propuesta, este último punto se omite sin marcarlo como hallazgo.

### Fase 3 — Deduplicar, verificar y entregar

8. Si el diff es chico (un archivo o menos de ~150 líneas en total), saltear el subagente deduplicador y consolidar los 6 outputs directo en el paso 9. Si es grande, lanzar un séptimo `Agent` (`subagent_type: general-purpose`) con los seis outputs pegados enteros en su prompt: su único trabajo es agrupar hallazgos que distintos lentes señalaron sobre el mismo problema (por ejemplo, un retain cycle que marcan a la vez Concurrencia y Arquitectura), quedándose con la redacción más específica y anotando qué lentes lo señalaron. No descarta nada por iniciativa propia.

9. **Con el resultado consolidado, el agente principal:**
   - Descarta ruido: hallazgos sin archivo/línea real, opiniones de estilo sin respaldo en `CLAUDE.md`, o algo que reabre una decisión ya registrada y justificada en `docs/BITACORA.md` sin evidencia nueva.
   - **Verifica cada Critical leyendo el archivo y la línea señalada** antes de darlo por válido. Un Critical que no se sostiene al leer el archivo se degrada a Warning o se descarta, con la razón anotada.
   - Si el paso 5 dio un test rojo genuino, ese Critical va primero en la lista, marcado como bloqueante.

10. **Escribir `/tmp/mr-review.md`** con el resultado final: los tres bloques (Critical / Warning / Suggestion), cada hallazgo con archivo, línea, descripción y lente(s) de origen, más una tabla resumen por lente. Nunca en la raíz del repo ni en ningún lugar del working tree del proyecto — es un output de la revisión, no algo para commitear.

11. **Entregar en el chat**, con el mismo criterio de entrega que `task-mr` — no un simple "revisá el archivo": el resumen de los Critical y Warning inline con archivo/línea y la razón, el estado real de los tests (verde o rojo, con el comando corrido), y la ruta al archivo completo (`/tmp/mr-review.md`) para el detalle y los Suggestions. Si hay al menos un Critical, decirlo explícito arriba de todo: **no proponer merge con esto así**.

## Señal de que algo se torció

Si en cualquier punto de esta skill aparece la tentación de corregir código en vez de reportarlo, de dar por buena la suite porque el autor dice que pasa, o de tildar algo en `docs/USE-CASES.md`, es señal de que se está mezclando esta skill con `task-mr` — `mr-review` audita y entrega un reporte, nunca implementa ni cierra la tarea.
