# Bitácora

*Juan Francisco Bazan Carrizo — 6 de agosto de 2026*

Registro de cada MR cerrado, entradas más nuevas arriba. El objetivo es que quien revise el historial entienda no solo qué se construyó, sino qué se descartó y por qué.

---

## 2026-08-06 — MR #0: Metodología y fundaciones del proyecto

**Qué se construyó.** La estructura de trabajo antes de escribir código: este documento, [USE-CASES.md](USE-CASES.md) con las 7 historias del challenge en formato narrativa + escenarios + use case + checklist, `CLAUDE.md` con las reglas de arquitectura/testing/git/estilo, y dos skills (`use-case`, `task-mr`) para no tener que repetir el proceso de memoria en cada tarea. También se reorganizaron los documentos existentes bajo `docs/` y se definió la estructura de 3 targets (`Cities`, `CitiesiOS`, `ChallengeUALA`) que va a alojar el código.

**Decisiones.**
- 3 targets en vez de 1: separar el core agnóstico de plataforma (`Cities`) permite correr su suite de tests en macOS, sin bootear el simulador — significativamente más rápido en cada iteración de TDD. El framework de UI (`CitiesiOS`) se separa del app target para que este último quede como Composition Root puro, y para que los snapshot tests de pantallas corran sin lanzar la app completa.
- `verticalSizeClass` en vez de `horizontalSizeClass` o `NavigationSplitView` para el layout adaptativo: en iPhones no-Plus/Pro-Max, `horizontalSizeClass` es siempre `.compact` sin importar la orientación, así que no distingue portrait de landscape. `verticalSizeClass` sí lo hace de forma consistente.
- Catálogo de 200k ciudades en memoria, favoritos en SwiftData detrás de un protocolo (`FavoritesStore`): el catálogo es reference data de solo lectura que se carga una vez; los favoritos son el único dato que el usuario edita y que necesita persistencia incremental entre sesiones.
- Índice de búsqueda por array ordenado + binary search, no trie: para prefix matching puro sobre datos que no cambian en runtime, un array de structs contiguo en memoria evita los cache misses de un trie con nodos dispersos en el heap, con menos código para mantener y testear.

**Qué se descartó.**
- Swift Package local en vez de framework targets: hubiera dado diffs más limpios en cada MR, pero se descartó porque con un solo desarrollador trabajando de forma secuencial el riesgo de conflictos en el project file es bajo, y los framework targets permiten separar explícitamente el target de UI iOS del core multiplataforma.
- Un target de UI unificado con el core: se descartó porque hubiera dejado el app target mezclando composición y presentación, y porque separar la UI en su propio framework es lo que habilita los snapshot tests aislados que pide el enunciado para las pantallas.
- Cache del catálogo a disco como MR propio: el enunciado aclara que el tiempo de carga no es una prioridad de evaluación, así que queda como *could-have* dentro del MR de la capa de API, no como trabajo garantizado.

**Qué sigue.** MR #1: scaffolding del proyecto Xcode — los 3 targets, schemes, test plan y CI, con un test trivial verde en cada uno (walking skeleton).
