# Bitácora

*Juan Francisco Bazan Carrizo — 6 de agosto de 2026*

Registro de cada MR cerrado, entradas más nuevas arriba. El objetivo es que quien revise el historial entienda no solo qué se construyó, sino qué se descartó y por qué.

---

## 2026-08-06 — MR #1: Scaffolding del proyecto Xcode (walking skeleton)

**Qué se construyó.** El proyecto Xcode (`ChallengeUALA.xcodeproj`) con los 3 targets definidos en el MR #0 y sus suites de tests: `Cities` (framework multiplataforma macOS + iPhone) con `CitiesTests`, `CitiesiOS` (framework iPhone) con `CitiesiOSTests`, y `ChallengeUALA` (app) con `ChallengeUALATests` y `ChallengeUALAUITests`. Un test real por target — no stubs vacíos — que prueba infraestructura: que cada framework carga su bundle en el proceso de test, que el bundle identifier de la app es el esperado, y que la app lanza en el simulador. Schemes compartidos (`ChallengeUALA`, `Cities`, `CitiesiOS`, `CI_iOS`) y CI en GitHub Actions con dos jobs (macOS e iOS), verificados en local con los comandos exactos que corre el workflow antes de escribirlo.

**Decisiones.**
- El proyecto lo creó el usuario desde la GUI de Xcode, no un `project.pbxproj` escrito a mano como se había planeado originalmente: un project file generado por Xcode es canónico y evita el riesgo de adivinar a mano el formato de `objectVersion 77` con `PBXFileSystemSynchronizedRootGroup` (carpetas sincronizadas). Claude guio cada wizard con los valores exactos y verificó con `xcodebuild` después de cada target agregado.
- `com.jfbazan` como prefijo de bundle ID, Team: None. Sin Team porque no hace falta firmar para compilar ni testear en el simulador, y porque el repo va a ser público para la revisión de Ualá — no tiene sentido dejar un Team ID personal grabado en un `pbxproj` público.
- `SWIFT_VERSION = 6.0` en los 7 targets (Xcode lo dejó en 5.0 por default): modo Swift 6 con concurrencia estricta, que es lo que ya asume `docs/PLAN-TECNICO.md` §3.2 al justificar `Sendable` en `CitySearchEntry`.
- `TARGETED_DEVICE_FAMILY` restringido a iPhone en los 7 targets (Xcode lo dejó en iPhone+iPad por default para `ChallengeUALA*` y `CitiesiOS*`): el challenge y los wireframes apuntan a iPhone (`PLAN-TECNICO.md` §5).
- Deployment target en 26.5 (la versión real del SDK instalado en la máquina), no 26.0 como se había estimado antes de crear el proyecto — 26.5 es lo que Xcode generó por default y cumple igual el pedido de "compatible con la última versión de iOS" sin inventar un número a mano.
- `CitiesiOSTests` con Host Application: None y sin dependencia de build hacia `ChallengeUALA`. Xcode había cableado ambas cosas automáticamente al crear el target — probablemente porque `ChallengeUALA` era la única app en el proyecto en ese momento — lo cual hubiera obligado a compilar la app entera para correr los tests de `CitiesiOS`, justo lo que el MR #0 quería evitar al separar `CitiesiOS` como framework propio (loop de TDD rápido). Se detectó revisando el pbxproj y se corrigió antes de seguir.
- CI con dos jobs: el de macOS usa el scheme `Cities` directamente: el de iOS usa un scheme nuevo, `CI_iOS`, con un test plan que junta los 4 test targets relevantes (`CitiesTests`, `CitiesiOSTests`, `ChallengeUALATests`, `ChallengeUALAUITests`) en una sola invocación de `xcodebuild`.
- Se sacaron los catálogos DocC (`Cities.docc`, `CitiesiOS.docc`) que Xcode genera por default en todo target de tipo framework: son placeholders con tokens de plantilla sin resolver, no aportan nada a un walking skeleton.

**Qué se descartó.**
- `project.pbxproj` escrito a mano: se había planeado así para evitar conflictos de merge en los próximos MRs, pero el usuario prefirió crear el proyecto él mismo desde Xcode con Claude guiando cada paso — más seguro que adivinar el formato de un archivo generado, y las carpetas sincronizadas (`PBXFileSystemSynchronizedRootGroup`, que Xcode aplica solo igual con `objectVersion 77`) ya resuelven el problema de diffs ruidosos que la escritura a mano buscaba evitar.
- Un scheme y test plan `CI_macOS` separados del scheme `Cities`: hubieran sido idénticos al `Cities.xctestplan` que Xcode ya autogeneró al conectar `CitiesTests` al scheme `Cities` (mismo target, mismo orden aleatorio, misma cobertura) — duplicar el archivo no agregaba nada.
- Swift Testing en vez de XCTest: es el default de los wizards de "New Target" en Xcode 26, pero las reglas de testing de `CLAUDE.md` (propagación de `file:`/`line:`, `trackForMemoryLeaks`) están escritas en idioma XCTest, y XCUITest solo existe ahí — se cambió a mano en cada wizard.
- Mantener `ContentView.swift` y `ChallengeUALAUITestsLaunchTests.swift` tal como los generó el template: el primero se reemplazó por un `Text("ChallengeUALA")` inline en `ChallengeUALAApp.swift` (un archivo menos para un placeholder que de todos modos se reemplaza en el MR de composición); el segundo se sacó por redundante con el único test de lanzamiento que ya cubre `ChallengeUALAUITests.swift`, y porque venía con comentarios de plantilla que violan la regla de "sin comentarios" de `CLAUDE.md`.

**Qué sigue.** MR #2: domain model de `City`, parseo del JSON del gist, y el índice de búsqueda (`CitySearchEntry`, `buildIndex`, `search(prefix:)`) con sus tests — el día 1 del plan técnico.

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
