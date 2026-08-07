# Bitácora

*Juan Francisco Bazan Carrizo — 6 de agosto de 2026*

Registro de cada MR cerrado, entradas más nuevas arriba. El objetivo es que quien revise el historial entienda no solo qué se construyó, sino qué se descartó y por qué.

---

## 2026-08-06 — MR #2: Domain model, mapeo del catálogo e índice de búsqueda

**Qué se construyó.** El núcleo de dominio del módulo `Cities`, sin una sola dependencia de framework: `City` (value type con `id`, `name`, `countryCode`, `latitude`, `longitude`), `CityCatalog` con su índice de búsqueda por prefijo, `CitySearchResults` como resultado de búsqueda, `lowerBound` como binary search genérico sobre arrays ordenados, y `CityCatalogMapper` que convierte los bytes del gist en el catálogo. 21 tests en `CitiesTests`, verdes en macOS y en el simulador de iOS. Antes de escribir código se partió la vieja Historia 2 en dos historias con checklist propio, porque mezclaba mapeo de datos con red y no permitía cerrar ninguna de las dos por separado.

Números medidos sobre 200.000 ciudades sintéticas, compilando el mismo código en `-O`:

| Operación | Tiempo |
|---|---|
| `buildIndex` (una sola vez, al cargar) | 12,9 ms |
| `search(prefix:)` — un tecleo | 0,36 µs |
| `search(prefix:)` + leer las 50 filas visibles | 0,63 µs |
| `search(prefix: "")` — catálogo completo | 0,011 µs |
| `filter(hasPrefix:)` equivalente, para comparar | 3.811 µs |

Unas 10.000 veces más rápido por tecleo que el `filter` lineal, a cambio de 13 ms pagados una única vez al arrancar — exactamente el trade-off que el enunciado autoriza al aclarar que el tiempo de carga no es prioritario.

**Decisiones.**
- **`search(prefix:)` devuelve `CitySearchResults`, no `ArraySlice<CitySearchEntry>`** como proponía `PLAN-TECNICO.md` §3.5. Las dos son zero-copy, pero `cityIndex` es un offset válido solo contra *ese* catálogo: expuesto en la API pública habilita `otroCatalogo.cities[entry.cityIndex]`, que compila, no crashea y devuelve la ciudad equivocada en silencio. Envolviéndolo, ese error deja de existir y `CitySearchEntry` puede ser `internal` — el módulo pasa de exponer 7 símbolos a exponer 3. Costo: 8 líneas.
- **La cota superior del rango es `\u{10FFFF}`, no `\u{FFFF}`** (§3.5 lo dejaba anotado como decisión pendiente). Se verificó con las comparaciones reales de Swift: una clave `"al<emoji>, xx"` cumple `hasPrefix("al")` pero **no** cumple `< "al\u{FFFF}"`, así que el centinela del BMP la dejaría fuera de los resultados. `\u{10FFFF}` no tiene ese agujero al mismo costo, y hay un test (`test_search_withCityNameOutsideBasicMultilingualPlane_matchesItsPrefix`) que lo fija.
- **`CityCatalog` es `struct`, no `final class`** como en §4: `CLAUDE.md` pide value types por defecto, y siendo struct de `let` el `Sendable` sale gratis para Swift 6 strict concurrency.
- **`countryCode`, `latitude`, `longitude`** en lugar de `country`, `lat`, `lon` (§4): `CLAUDE.md` prohíbe abreviaturas, y el JSON trae un código de país (`"UA"`), no un nombre. Los nombres del formato de red viven confinados en los `CodingKeys` del DTO privado del mapper.
- **El mapper recibe `Data`, no una URL ni una respuesta HTTP.** No sabe de dónde salieron los bytes, así que el cache del JSON a disco que `PLAN-TECNICO.md` §4 deja como *could-have* se puede agregar después sin tocar una línea del módulo `Cities`.
- **Todo o nada al mapear:** una sola entrada inválida entre entradas válidas hace fallar el mapeo completo. Un catálogo parcial presentado como completo es peor que un error visible, y hay un test dedicado a ese caso.
- **Sin `trackForMemoryLeaks`:** este MR no introduce ningún reference type, así que no hay instancia que trackear. El helper entra en el MR #3, con el cliente HTTP.
- El único `///` que permite `CLAUDE.md` quedó sobre `CitySearchEntry`, justificando la representación frente a `filter` y frente a un trie — es el criterio de evaluación que el enunciado pide textualmente en los comentarios del código.
- **Se eliminaron los destinos "Designed for iPhone" y Mac Catalyst, y se restauró Team: None.** Con el destino activo en *My Mac (Designed for iPhone)*, `ChallengeUALA` —que es iOS-only— no compila sin firmar, y para destrabarlo se terminó seleccionando un Development Team: Xcode grabó el Team ID personal en 6 configuraciones del `pbxproj`, justo lo que el MR #1 había evitado por tratarse de un repo que se publica para la revisión. Sacar el Team no alcanzaba: mientras el destino exista, el problema vuelve. Se apagaron `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD`, `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD` y `SUPPORTS_MACCATALYST` en los targets iOS, y se fijó `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` en `CitiesiOS` y `CitiesiOSTests`. Es la misma idea que se aplica al código: hacer irrepresentable lo inválido en vez de confiar en acordarse de no elegirlo. Verificado con `xcodebuild -showdestinations`: los schemes `ChallengeUALA`, `CitiesiOS` y `CI_iOS` quedaron sin ningún destino de macOS ni de Vision, y `Cities` conserva sus dos destinos de macOS **nativo** (`SDKROOT = macosx`), que es un mecanismo distinto y es lo que sostiene el loop de TDD sin simulador.
- **Se descartó configurar esos settings a nivel proyecto**, que era la idea inicial por ser un solo lugar en vez de doce. El editor de Build Settings muestra "No" en la columna del proyecto como valor por defecto, así que no hay nada que cambiar ahí y Xcode no escribe la línea — pero el build system igual resuelve `YES` en los targets de framework. La única vía que efectivamente lo escribe es la sección *Supported Destinations* de la pestaña General de cada target. Se detectó midiendo con `xcodebuild -showBuildSettings` en vez de confiar en lo que muestra el editor.
- **Se fijó en `CLAUDE.md` la estructura estándar de un archivo de test**, tomada del curso de Essential Developer: `makeSUT` como único lugar donde se construye el SUT, factories de datos que devuelven el par `(model, json)`, aserciones repetidas extraídas a un `expect(...)` que propaga `file:`/`line:`, y helpers `private` dentro de la clase que los usa bajo un `// MARK: - Helpers`. Se sumó a la sección de estilo una excepción explícita para `// MARK:` en tests: agrupa, no explica, así que no contradice la regla de "sin comentarios" — mismo argumento que ya vale para los headers de autoría. La regla se escribió antes de aplicarla, para que los MRs siguientes no vuelvan a improvisar la forma de cada archivo.
- **`CityCatalogMapperTests` no lleva `makeSUT`, y `CityCatalogSearchTests` sí.** El mapper es un `enum` estático sin dependencias: no hay instancia que construir ni que trackear, así que un `makeSUT` que solo devolviera la función sería ruido — la centralización va en `makeCity(...) -> (model, json)`, que deja los nombres del formato de red (`_id`, `coord`, `lat`, `lon`) escritos en un solo lugar del archivo e imposibilita que el JSON literal y el modelo esperado se desincronicen. `CityCatalog`, en cambio, sí es una instancia, así que ahí `makeSUT` aplica con dos sobrecargas (la de muestra y la que recibe ciudades) para que ningún test construya el catálogo por su cuenta y sin meter condicionales en el helper; sin `trackForMemoryLeaks` porque es un `struct` y un value type no puede leakear. Es el mismo criterio del curso, donde `FeedItemsMapperTests` no tiene `makeSUT` y `RemoteFeedLoaderTests` sí.
- **El módulo se organizó en carpetas por boundary** (`CityFeature`, `CitySearch`, `CityAPI`), con `CitiesTests` espejando la misma estructura. Se hizo ahora, con 10 archivos, en lugar de más adelante: es el momento más barato y los archivos de red del MR #3 nacen directamente en su carpeta. Al motor de búsqueda se le dio carpeta propia en vez de dejarlo junto al modelo, porque es la pieza que el enunciado pone como criterio de evaluación central y conviene que se encuentre de un vistazo — y porque `CLAUDE.md` pide separar los modelos de dominio de la lógica agnóstica reutilizable. Como los grupos del proyecto son `PBXFileSystemSynchronizedRootGroup` sin excepciones de membership, las subcarpetas se reflejan solas: `project.pbxproj` no registró ningún cambio y ambas suites siguieron verdes tras el movimiento.

**Qué se descartó.**
- **Un trie.** 200.000 entradas son nodos dispersos en el heap y cada paso del recorrido es un salto de puntero con cache miss potencial; el array de structs es memoria contigua y el CPU prefetchea el bloque siguiente. Para prefix matching exacto —no fuzzy, no autocompletado difuso— el array gana con mucho menos código para mantener y testear, y sin librerías de terceros un trie a mano es superficie de bug propia.
- **`search(prefix:) -> [City]`.** Era la firma más simple de leer, pero copia una `City` por resultado en cada búsqueda: con el filtro vacío son 200.000 structs y ~400.000 retains sobre sus `String` en cada tecla, justo el escenario que el enunciado marca como criterio de evaluación.
- **Acotar el rango superior con un predicado `hasPrefix` en vez de un centinela.** También es correcto para todo Unicode, pero mezcla dos semánticas distintas: `<` compara escalares normalizados y `hasPrefix` trabaja a nivel de grapheme cluster. Se verificó que con marcas combinantes (`a`+`U+0301` frente a `á` precompuesta) ambas coinciden, pero usar `<` para las dos cotas mantiene una sola semántica, la misma con la que se ordenó el índice.
- **Guardar la `City` dentro de `CitySearchEntry`** en vez de un `cityIndex`. Habría evitado la indirección, pero engorda cada entrada del array y entran menos por línea de caché durante el descenso del binary search, que es el camino caliente.
- **Un test que verifique que `City` no es `Decodable`.** El checklist original lo pedía y es una propiedad de compilación, no de runtime: se reemplazó por un test que sí es observable — que el mapeo traduce `_id`/`coord`/`lon`/`lat` a `id`/`latitude`/`longitude`.

**Qué sigue.** MR #3: la capa de red — el protocolo `HTTPClient` definido por el dominio, su implementación con `URLSession` del lado de afuera, y el use case *Load City Catalog* que la combina con el mapeo de este MR (Historia 3).

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
