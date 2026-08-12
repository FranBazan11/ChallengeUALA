# Use Cases

*Juan Francisco Bazan Carrizo — 6 de agosto de 2026*

Este documento es el contrato de cada historia antes de escribir código, y el checklist de avance mientras se implementa. Cada historia deriva de un punto de [REQUISITOS.md](REQUISITOS.md). Ningún checkbox se tilda sin que el test correspondiente esté pasando.

---

## MR #1 — Walking skeleton (infraestructura)

*No es una historia de usuario — no deriva de un punto puntual de [REQUISITOS.md](REQUISITOS.md). Es la base técnica sin la cual ninguna historia siguiente puede empezar: el proyecto Xcode, sus targets, y un test verde por target que prueba que la infraestructura funciona (compila, linkea, carga en el test runner, corre desde CI) — no prueba dominio.*

### Checklist

- [x] Proyecto `ChallengeUALA.xcodeproj` con 7 targets: `ChallengeUALA`, `ChallengeUALATests`, `ChallengeUALAUITests`, `Cities`, `CitiesTests`, `CitiesiOS`, `CitiesiOSTests`
- [x] `Cities` es multiplataforma (macOS + iPhone) — su suite corre en macOS sin simulador
- [x] `CitiesiOS` y `ChallengeUALA` corren en iOS Simulator
- [x] `ChallengeUALA` linkea y embebe `Cities.framework` y `CitiesiOS.framework`
- [x] `CitiesiOSTests` es independiente del target `ChallengeUALA` (sin host app, sin dependencia de build)
- [x] Un test real por target, no un stub vacío: `Cities` y `CitiesiOS` verifican que su bundle está cargado en el proceso; `ChallengeUALATests` verifica el bundle identifier de la app; `ChallengeUALAUITests` verifica que la app lanza en el simulador
- [x] Schemes compartidos (`ChallengeUALA`, `Cities`, `CitiesiOS`) + scheme `CI_iOS` con test plan combinado (`CitiesTests` + `CitiesiOSTests` + `ChallengeUALATests` + `ChallengeUALAUITests`)
- [x] CI en GitHub Actions: job macOS (`-scheme Cities`) + job iOS (`-scheme CI_iOS`), ambos verificados en local con los comandos exactos que corre el workflow

---

## Historia 1 — Filtrar ciudades por prefijo

**Como** usuario del catálogo
**Quiero** filtrar la lista escribiendo un prefijo
**Para** encontrar una ciudad puntual entre 200.000 sin scrollear

### Escenarios

- **Dado** el catálogo cargado, **cuando** escribo `"Al"`, **entonces** veo solo las ciudades cuyo nombre empieza con `Al`, ordenadas por ciudad y después país
- **Dado** el catálogo cargado, **cuando** escribo `"al"` en minúscula, **entonces** obtengo exactamente el mismo resultado que con `"Al"`
- **Dado** el catálogo cargado, **cuando** el filtro queda vacío, **entonces** veo el catálogo completo, ordenado
- **Dado** el catálogo cargado, **cuando** escribo un prefijo sin coincidencias, **entonces** veo el estado vacío
- **Dado** que estoy escribiendo, **cuando** agrego o borro un carácter, **entonces** la lista se actualiza con cada cambio, sin trabarse
- **Dado** que el teclado está abierto porque toqué el filtro, **cuando** toco cualquier otra parte de la pantalla o scrolleo la lista, **entonces** el teclado se esconde y el texto del filtro se conserva

### Use Case: Search Cities By Prefix

**Data (input):** prefix

**Curso primario (happy path):**
1. El sistema normaliza el prefijo a minúsculas
2. El sistema ubica el rango de coincidencias en el índice ordenado
3. El sistema entrega el slice de resultados, ya ordenado alfabéticamente

**Curso alternativo — prefijo vacío:**
1. El sistema entrega el catálogo completo, ya ordenado

**Curso alternativo — sin coincidencias:**
1. El sistema entrega una lista vacía

**Curso alternativo — input inválido (whitespace, símbolos, acentos, string extremadamente largo):**
1. El sistema normaliza igual que cualquier otro input y busca coincidencias literales
2. No hay ningún input que produzca un crash o una excepción no controlada

### Checklist

- [x] `search(prefix:)` con prefijo que coincide con varias ciudades
- [x] Case insensitive: `"AL"`, `"al"`, `"Al"` producen el mismo resultado
- [x] Prefijo vacío devuelve el catálogo completo
- [x] Prefijo sin coincidencias devuelve una lista vacía
- [x] Whitespace, símbolos, acentos y strings largos no crashean y se resuelven de forma consistente
- [x] Orden final: ciudad y después país (`"Denver, US"` antes que `"Sydney, AU"`)
- [x] Cada carácter agregado o borrado actualiza la lista de forma síncrona — 0,36 µs medidos en el MR #2 sobre 200.000 ciudades hacen innecesario un `Task` por tecla
- [x] La cancelación aplica al `Task` de carga del catálogo, no a la búsqueda — ver Historia 9
- [x] Tocar fuera del campo de filtro esconde el teclado *(agregado en el MR #5)*
- [x] Esconder el teclado conserva el texto del filtro y los resultados vigentes *(agregado en el MR #5)*
- [x] Tocar **sobre la lista cargada** esconde el teclado — el caso que motivó el `simultaneousGesture`, y que con la lista ocupando casi toda la pantalla es lo que "tocar afuera" significa en la práctica *(agregado en el MR #8)*
- [x] Scrollear la lista cargada esconde el teclado *(agregado en el MR #8)*

---

## Historia 2 — Convertir los datos descargados en el catálogo

**Como** usuario de la app
**Quiero** que los datos que llegan del servidor se conviertan en ciudades válidas o en un error explícito
**Para** no ver nunca un catálogo incompleto presentado como si estuviera completo

### Escenarios

- **Dado** datos con el formato del gist, **cuando** se convierten, **entonces** obtengo una ciudad por cada entrada, con su id, nombre, código de país y coordenadas
- **Dado** una lista vacía, **cuando** se convierte, **entonces** obtengo un catálogo vacío, no un error
- **Dado** datos que no son el JSON esperado, **cuando** se intenta convertirlos, **entonces** obtengo un error, sin crash y sin catálogo parcial
- **Dado** una entrada a la que le falta un campo obligatorio, **cuando** se convierte, **entonces** obtengo un error — no una ciudad con datos inventados

### Use Case: Map City Catalog Data

**Data (input):** datos crudos del catálogo

**Curso primario (happy path):**
1. El sistema interpreta los datos con el formato acordado del catálogo
2. El sistema construye una ciudad de dominio por cada entrada
3. El sistema entrega el catálogo

**Curso alternativo — datos vacíos:**
1. El sistema entrega un catálogo vacío

**Curso alternativo — datos inválidos o incompletos:**
1. El sistema entrega un error de datos inválidos, sin crashear ni entregar un catálogo parcial

### Contrato

El mapeo recibe `Data` y no sabe de dónde salieron esos bytes: es indistinto si vienen de la red o del disco. Por eso no necesita ningún protocolo — es una función pura del módulo `Cities`, y la decisión de cachear el JSON a disco queda libre para más adelante sin tocar esta historia.

### Checklist

- [x] Datos con el formato del gist producen las ciudades esperadas
- [x] El mapeo traduce los nombres del formato de red (`_id`, `coord`, `lon`, `lat`) a los del dominio (`id`, `latitude`, `longitude`)
- [x] Lista vacía produce catálogo vacío, no error
- [x] Datos que no son el JSON esperado producen error, no crash
- [x] Entrada con un campo obligatorio faltante produce error, no una ciudad parcial
- [x] Una sola entrada inválida entre entradas válidas produce error, no un catálogo parcial

---

## Historia 3 — Cargar el catálogo remoto

**Como** usuario de la app
**Quiero** que la lista de 200.000 ciudades se descargue al iniciar
**Para** tener el catálogo completo disponible para buscar y favoritear

### Escenarios

- **Dado** que tengo conectividad, **cuando** abro la app, **entonces** el catálogo se descarga y queda disponible para búsqueda
- **Dado** que no tengo conectividad, **cuando** abro la app, **entonces** veo un error claro, sin crash
- **Dado** que el servidor responde con un código de estado inesperado, **cuando** se procesa la respuesta, **entonces** obtengo un error, no un catálogo vacío silencioso

### Use Case: Load City Catalog

**Data (input):** URL del gist

**Curso primario (happy path):**
1. El sistema pide los datos a la URL
2. El sistema valida la respuesta recibida
3. El sistema convierte los datos válidos en el catálogo (Historia 2)
4. El sistema entrega el catálogo

**Curso alternativo — sin conectividad:**
1. El sistema entrega un error de conectividad

**Curso alternativo — respuesta inválida:**
1. El sistema entrega un error de respuesta inválida, sin crashear

### Contrato

El módulo `Cities` define un protocolo `HTTPClient` con una única operación de obtención de datos por URL. Lo define el lado interno (el dominio); su implementación con `URLSession` vive del lado de afuera, en una carpeta de infraestructura propia dentro del mismo módulo — nunca al revés. El app target no la implementa: es el único que la instancia, como Composition Root.

### Checklist

- [x] Request a la URL correcta
- [x] Respuesta exitosa entrega los datos al mapeo de la Historia 2
- [x] Código de estado inesperado produce error, no crash
- [x] Error de red produce error, no crash
- [x] No hay side-effects si el request se completa después de que nadie lo espera
- [x] El cliente hace un GET a la URL pedida
- [x] Una respuesta que no es HTTP produce error
- [x] Una respuesta HTTP con datos entrega esos datos y esa respuesta
- [x] Una respuesta HTTP sin datos entrega datos vacíos, no un error

---

## Historia 4 — Marcar y desmarcar favoritos

**Como** usuario del catálogo
**Quiero** marcar ciudades como favoritas y que se recuerden
**Para** volver a encontrarlas rápido en la próxima sesión

### Escenarios

- **Dado** una ciudad en la lista, **cuando** toco su ícono de favorito, **entonces** queda marcada como favorita inmediatamente
- **Dado** una ciudad ya favorita, **cuando** toco su ícono de favorito, **entonces** se desmarca
- **Dado** que marqué una ciudad como favorita, **cuando** cierro y reabro la app, **entonces** sigue marcada como favorita
- **Dado** que la persistencia falla (disco lleno, store corrupto), **cuando** toco el ícono de favorito, **entonces** la estrella **no** queda marcada — la pantalla no me muestra como guardado algo que no se guardó

### Use Case: Toggle Favorite City

**Data (input):** id de la ciudad, estado deseado (favorita / no favorita)

**Curso primario (happy path):**
1. El sistema persiste el nuevo estado de favorito para esa ciudad
2. El sistema confirma el cambio

**Curso alternativo — toggle repetido sobre la misma ciudad:**
1. El sistema aplica el último estado solicitado, sin duplicar entradas

**Curso alternativo — falla la persistencia:**
1. El sistema no cambia el estado de favorito que tiene en memoria
2. El sistema deja la ciudad tal como estaba, sin inventar entradas ni borrar las existentes

**Curso alternativo — falla la lectura inicial de favoritos:**
1. El sistema arranca sin ningún favorito conocido, sin crashear

### Contrato

El módulo `Cities` define `FavoritesStore` con dos operaciones, **las dos capaces de fallar**: leer el conjunto de ids favoritos y fijar el estado de favorito de una ciudad. Lo define el dominio; la implementación con SwiftData vive en `CityFavoritesInfrastructure/`, y `InMemoryFavoritesStore` queda al lado como fallback.

El error es `throws` pelado, **no** typed throws como `CityCatalogLoadError`. Es el mismo criterio con el que la Historia 3 dejó `HTTPClient.get` sin acotar: es el borde con un framework de persistencia que falla de formas que no se pueden enumerar de antemano, y cerrar ese set sería prometer una garantía imposible de sostener.

Que la operación pueda fallar es lo que le permite al ViewModel no mentir: si la escritura no salió bien, el estado en memoria no se toca y la estrella no se prende.

### Checklist

- [x] Marcar una ciudad no favorita la deja favorita
- [x] Desmarcar una ciudad favorita la deja no favorita
- [x] El estado persiste entre instancias del store (simulando reinicio de la app)
- [x] Alternar dos veces sobre la misma ciudad no genera estado inconsistente ni entradas duplicadas
- [x] El ViewModel depende del protocolo `FavoritesStore`, no de SwiftData directamente
- [x] Un fallo al persistir deja la ciudad con el estado de favorito que ya tenía
- [x] Un fallo al persistir no cambia la lista visible cuando el filtro de favoritos está prendido
- [x] Un fallo al leer los favoritos al arrancar deja el sistema sin favoritos, sin crashear
- [x] El camino de persistencia que arma el Composition Root recuerda los favoritos entre lanzamientos

---

## Historia 5 — Filtrar solo favoritos

**Como** usuario del catálogo
**Quiero** ver solo mis ciudades favoritas
**Para** no perderlas entre 200.000 resultados

### Escenarios

- **Dado** que tengo ciudades favoritas, **cuando** activo el filtro "solo favoritos", **entonces** veo únicamente esas ciudades
- **Dado** que el filtro "solo favoritos" está activo, **cuando** además escribo un prefijo, **entonces** veo la intersección de ambos filtros
- **Dado** que no tengo ninguna ciudad favorita, **cuando** activo el filtro, **entonces** veo el estado vacío

### Use Case: Filter Favorite Cities

**Data (input):** flag "solo favoritos", prefijo actual

**Curso primario (happy path):**
1. El sistema aplica el filtro de prefijo sobre el catálogo
2. El sistema interseca el resultado con el conjunto de IDs favoritos
3. El sistema entrega la lista resultante

**Curso alternativo — sin favoritos:**
1. El sistema entrega una lista vacía

### Checklist

- [x] Filtro de favoritos solo, sin prefijo
- [x] Filtro de favoritos combinado con un prefijo
- [x] Sin favoritos, el resultado es una lista vacía, no un error
- [x] Desactivar el filtro vuelve a mostrar el catálogo completo (filtrado por prefijo si corresponde)

---

## Historia 6 — Ver la ciudad seleccionada en el mapa

**Como** usuario del catálogo
**Quiero** que al tocar una ciudad el mapa navegue a sus coordenadas
**Para** ubicarla geográficamente

### Escenarios

- **Dado** la lista de ciudades, **cuando** toco una ciudad, **entonces** el mapa centra su vista en las coordenadas de esa ciudad
- **Dado** que estoy en portrait, **cuando** toco una ciudad, **entonces** navego a una pantalla de mapa separada, con un botón para volver
- **Dado** que estoy en landscape, **cuando** toco una ciudad, **entonces** el mapa se actualiza en el panel derecho, sin navegar a otra pantalla
- **Dado** que estoy en landscape con una ciudad ya dibujada en el mapa, **cuando** toco otra ciudad de la lista, **entonces** el mapa se recentra en la nueva sin que yo haga nada más
- **Dado** que estoy en landscape y todavía no toqué ninguna ciudad, **cuando** miro el panel derecho, **entonces** veo una invitación a elegir una, no un mapa en cualquier lado

### Use Case: Show City On Map

**Data (input):** id de la ciudad tocada en la lista

**Curso primario (happy path):**
1. El sistema ubica la ciudad tocada entre los resultados visibles
2. El sistema entrega su título y sus coordenadas, ya listos para dibujar
3. El sistema centra el mapa en esas coordenadas, con un radio fijo alrededor

**Curso alternativo — todavía no hay ninguna ciudad seleccionada:**
1. El sistema no centra ningún mapa y muestra una invitación a elegir una ciudad

**Curso alternativo — la ciudad pedida no está entre los resultados visibles:**
1. El sistema no entrega datos de mapa y la selección vigente no cambia

### Contrato

El módulo `Cities` define `CityMapViewModel` en `CityPresentation/`: un struct inmutable con `id`, `title`, `latitude`, `longitude` y `spanInMeters`, construido desde una `City` — molde exacto de `CityCellViewModel`. **MapKit no entra a `Cities`**: la traducción a la región del mapa vive en `CitiesiOS`, del lado de afuera, igual que `URLSession` vive en `CityAPIInfrastructure` y SwiftData en `CityFavoritesInfrastructure`.

El radio va en **metros y no en grados**. Un grado de latitud mide siempre lo mismo, pero uno de longitud se encoge con el coseno de la latitud: la misma región expresada en grados se ve angosta cerca del ecuador y ancha cerca de los polos. En metros, el encuadre es el mismo para Hurzuf que para Ushuaia.

Quién resuelve la selección: `CityListViewModel.mapViewModel(for cityID:)`, una query pura sobre la ventana visible — un tap solo puede venir de una fila en pantalla, así que no hace falta recorrer el catálogo. Es lo que permite que `CitiesiOS` no instancie **ningún** tipo de `Cities`: la vista recibe view models ya armados y devuelve ids. La regla de *"ningún módulo instancia componentes de otro módulo"* pasa a estar sostenida por la forma de la API y no por disciplina.

No hace falta ningún protocolo nuevo: el mapa no carga datos, dibuja coordenadas que el catálogo ya tiene en memoria.

### Checklist

- [x] El view model de mapa arma el título combinando nombre y código de país
- [x] El view model de mapa conserva las coordenadas de la ciudad sin transformarlas
- [x] Pedir el view model de mapa de una ciudad visible entrega sus coordenadas
- [x] Pedir el view model de mapa de una ciudad fuera de la ventana visible no entrega nada
- [x] Pedir el view model de mapa antes de que el catálogo cargue no entrega nada
- [ ] Seleccionar una ciudad actualiza la región visible del mapa
- [ ] Seleccionar otra ciudad con el mapa ya dibujado lo recentra
- [x] Sin ciudad seleccionada, el mapa muestra la invitación a elegir una
- [x] En portrait, seleccionar una ciudad navega a la pantalla de mapa
- [x] En landscape, seleccionar una ciudad actualiza el panel de mapa sin navegar
- [x] Volver desde el mapa en portrait conserva el estado del filtro y del scroll de la lista

---

## Historia 7 — Ver la pantalla de información de una ciudad

**Como** usuario del catálogo
**Quiero** abrir una pantalla de detalle de la ciudad
**Para** ver información que no cabe en la celda de la lista

### Escenarios

- **Dado** una ciudad en la lista, **cuando** toco su botón de información, **entonces** se abre la pantalla de detalle de esa ciudad
- **Dado** la pantalla de detalle abierta, **cuando** la miro, **entonces** veo datos que no están en la celda de la lista

### Use Case: Show City Detail

**Data (input):** id de la ciudad seleccionada

**Curso primario (happy path):**
1. El sistema busca la ciudad por id en el catálogo
2. El sistema entrega los datos a mostrar en el detalle

### Checklist

- [ ] Tocar el botón de información abre el detalle de la ciudad correcta
- [ ] El detalle muestra datos adicionales a los de la celda de lista
- [ ] Snapshot del detalle en al menos un estado

---

## Historia 8 — Layout adaptativo portrait / landscape

**Como** usuario de la app
**Quiero** que la UI se adapte a la orientación del dispositivo
**Para** aprovechar mejor la pantalla en cada caso

### Escenarios

- **Dado** el dispositivo en portrait, **cuando** abro la app, **entonces** veo la lista y el mapa como pantallas separadas
- **Dado** el dispositivo en landscape, **cuando** abro la app, **entonces** veo la lista y el mapa como paneles de una única pantalla
- **Dado** que estoy a mitad de una búsqueda, **cuando** roto el dispositivo, **entonces** no pierdo el texto del filtro ni la selección actual
- **Dado** que el catálogo ya está cargado, **cuando** roto el dispositivo, **entonces** no vuelvo a ver el indicador de carga ni se descarga el catálogo de nuevo

### Use Case: Adapt Layout To Orientation

**Data (input):** clase de tamaño vertical del entorno

**Curso primario (happy path):**
1. El sistema evalúa la clase de tamaño vertical disponible
2. El sistema compone lista y mapa como pantallas separadas si es `.regular`, o como paneles de una sola pantalla si es `.compact`

**Curso alternativo — cambia la orientación con trabajo ya hecho:**
1. El sistema conserva el catálogo cargado, la consulta vigente y la ciudad seleccionada
2. El sistema recompone la pantalla sin volver a pedir el catálogo

### Contrato

**`verticalSizeClass`, no `horizontalSizeClass` ni `NavigationSplitView`**, por lo argumentado en [PLAN-TECNICO.md](PLAN-TECNICO.md) §5: en los iPhone que no son Plus/Pro Max, `horizontalSizeClass` es `.compact` en las dos orientaciones, y `NavigationSplitView` reacciona justamente a esa — se quedaría en una sola columna en landscape, que es lo contrario de lo que pide el enunciado.

`CityCatalogView` (`CitiesiOS`) es la vista **estable**: pública, reemplaza a `CityListView` como raíz que arma el Composition Root, y es dueña de la carga y de la ciudad seleccionada. Las dos cosas viven **fuera** del condicional de layout. No es prolijidad: una vista que aparece en dos ramas de un `if` cambia de identidad al rotar, y con la identidad se va su `@State` y se vuelve a disparar su `.task` — o sea, se perdería el filtro y se re-descargarían los ~10 MB del catálogo con spinner. Con la carga y la selección en la vista estable, rotar no puede perder ninguna de las dos.

Por la misma razón, el prefijo y el flag "solo favoritos" dejan de ser `@State` de la vista y suben a `CityListViewModel` como propiedades observables de solo lectura (`searchPrefix`, `showsFavoritesOnly`). La vista las lee y escribe por los comandos que ya existen (`search(prefix:)`, `setFavoritesOnly(_:)`) con un `Binding` armado a mano: una sola fuente de verdad en vez de dos sincronizadas por `.onChange`, CQS intacto —nada de `didSet` con efectos—, y sobreviven a la rotación porque las guarda el objeto que crea el Composition Root, no el árbol de vistas.

### Checklist

- [x] Snapshot en portrait: lista y mapa separados
- [x] Snapshot en landscape: lista y mapa en paneles
- [x] El prefijo vigente lo publica el view model, no la vista
- [x] El flag "solo favoritos" lo publica el view model, no la vista
- [x] Rotar a mitad de búsqueda conserva el texto del filtro
- [x] Rotar con una ciudad seleccionada conserva la selección
- [x] Rotar no vuelve a cargar el catálogo — verificado contra el gist real con un test de UI temporal, descartado después (ver la bitácora del MR #8)

---

## Historia 9 — Ver el catálogo mientras se carga

**Como** usuario de la app
**Quiero** ver el estado de la carga del catálogo
**Para** saber si la app está funcionando y poder reintentar si falla

### Escenarios

- **Dado** que abro la app, **cuando** el catálogo todavía no llegó, **entonces** veo un indicador de carga
- **Dado** que el catálogo terminó de cargar, **cuando** se actualiza el estado, **entonces** veo la lista de ciudades
- **Dado** que no tengo conectividad o el servidor responde mal, **cuando** la carga falla, **entonces** veo un mensaje de error claro y un botón para reintentar
- **Dado** que la carga falló, **cuando** toco "Reintentar", **entonces** vuelvo a ver el indicador de carga y se dispara una nueva carga
- **Dado** que estoy cargando, **cuando** la carga se cancela (por ejemplo, me voy de la pantalla), **entonces** no se muestra ningún error
- **Dado** que el catálogo tarda en mapearse e indexarse, **cuando** la carga está en curso, **entonces** la UI sigue respondiendo — el trabajo del loader no corre en el hilo de UI

### Use Case: Present City Catalog Load

**Data (input):** ninguno — se dispara al aparecer la pantalla o al reintentar

**Curso primario (happy path):**
1. El sistema marca el estado como "cargando"
2. El sistema pide el catálogo al `CityCatalogLoader`
3. El sistema marca el estado como "cargado", con el catálogo filtrado por el prefijo vigente

**Curso alternativo — error de conectividad o datos inválidos:**
1. El sistema marca el estado como "error", con un mensaje ya resuelto para mostrar
2. El sistema permite reintentar, lo que repite el curso primario

**Curso alternativo — cancelación:**
1. El sistema no marca el estado como "error"

### Contrato

El ViewModel depende del protocolo `CityCatalogLoader` (definido en `Cities/CityFeature/`, junto al modelo de dominio), no del tipo concreto `RemoteCityCatalogLoader` — así el test del ViewModel usa un stub en memoria, y la implementación de red se prueba aparte, como ya hace la Historia 3.

El requirement `load()` del protocolo lleva `@concurrent`: con `SWIFT_APPROACHABLE_CONCURRENCY` activo (`NonisolatedNonsendingByDefault`), una función `async` sin esa marca hereda el aislamiento de quien la llama, y quien llama a `load()` es `CityListViewModel`, que es `@MainActor`. `@concurrent` es el opt-in explícito para que el mapeo del JSON y la construcción del índice de búsqueda corran fuera del hilo de UI.

### Checklist

- [x] Estado inicial "cargando" antes de que la primera carga resuelva
- [x] Carga exitosa deja el estado en "cargado", con los resultados de búsqueda del prefijo vigente
- [x] Error de conectividad deja el estado en "error" con un mensaje
- [x] Datos inválidos deja el estado en "error" con un mensaje
- [x] Reintentar (una nueva llamada a cargar) puede resolver en "cargado" después de una falla previa
- [x] Cancelación no produce un estado de error
- [x] Cargar desde un llamador @MainActor no corre el trabajo del loader en el hilo de UI

---

## Historia 10 — Ver cada ciudad en la lista

**Como** usuario del catálogo
**Quiero** ver el nombre, país y coordenadas de cada ciudad en su celda
**Para** identificarla sin tener que abrir el detalle

### Escenarios

- **Dado** una ciudad del catálogo, **cuando** se muestra su celda, **entonces** veo "Ciudad, CC" como título y las coordenadas como subtítulo
- **Dado** una búsqueda con resultados, **cuando** se muestra la lista, **entonces** las celdas respetan el orden del índice
- **Dado** una búsqueda sin coincidencias, **cuando** se muestra la lista, **entonces** veo el estado vacío

### Use Case: Present City Cell

**Data (input):** una `City`

**Curso primario (happy path):**
1. El sistema arma el título combinando nombre y código de país
2. El sistema arma el subtítulo con latitud y longitud
3. El sistema entrega los datos ya listos para esa celda

### Checklist

- [x] El título combina nombre y código de país
- [x] El subtítulo muestra latitud y longitud
- [x] Dos ciudades con los mismos datos producen el mismo view model (`Equatable`)

---

## Historia 11 — Ver el catálogo sin conexión *(could-have, diferida)*

> **No deriva de [REQUISITOS.md](REQUISITOS.md).** El enunciado pide descargar el catálogo del gist y no menciona funcionamiento offline en ningún punto; es más, aclara explícitamente que *"el tiempo de carga de la app no es tan importante"*, que es justo el argumento principal a favor de cachear. Lo único que el enunciado sí exige sobre persistencia —*"las ciudades favoritas deben recordarse entre lanzamientos de la app"*— ya está cubierto por la Historia 4.
>
> Esta historia queda escrita porque el agujero se detectó al cerrar el MR #5 y no queremos que se pierda, no porque sea trabajo comprometido. Es un *could-have* en los términos de [PLAN-TECNICO.md](PLAN-TECNICO.md) §2: entra solo si sobra tiempo después de los must-have, y no se toca si pone en riesgo alguno de ellos.

**Como** usuario de la app
**Quiero** ver el catálogo y mis ciudades favoritas aunque no tenga conexión
**Para** poder usar la app en el subte, en un avión o con la red caída

### El problema concreto que resuelve

Hoy, sin conexión, la pantalla queda en el estado de error y no se ve **nada** — ni siquiera los favoritos ya guardados. No es que los favoritos se pierdan: están en SwiftData y se leen bien. Lo que falta es el catálogo. Como `FavoriteCity` guarda únicamente el `cityID`, sin catálogo no hay nombre ni coordenadas con qué dibujar una fila.

### Escenarios

- **Dado** que ya cargué el catálogo alguna vez, **cuando** abro la app sin conexión, **entonces** veo el catálogo cacheado y puedo buscar y filtrar favoritos con normalidad
- **Dado** que nunca cargué el catálogo, **cuando** abro la app sin conexión, **entonces** veo el mensaje de error con "Reintentar" — el mismo comportamiento de hoy
- **Dado** que tengo conexión, **cuando** la descarga termina bien, **entonces** el cache queda actualizado con lo recién descargado
- **Dado** que el cache está corrupto o incompleto, **cuando** intento leerlo, **entonces** se trata como si no existiera — nunca un crash ni un catálogo a medias presentado como completo
- **Dado** que tengo conexión, **cuando** la descarga falla a mitad de camino, **entonces** el cache anterior queda intacto, no pisado por datos parciales

### Use Case: Load City Catalog With Fallback

**Data (input):** ninguno — se dispara igual que la carga actual

**Curso primario (happy path):**
1. El sistema pide el catálogo remoto (Historia 3)
2. El sistema guarda el catálogo obtenido en el cache, reemplazando el anterior
3. El sistema entrega el catálogo

**Curso alternativo — falla la red y hay cache:**
1. El sistema recupera el catálogo del cache
2. El sistema entrega ese catálogo, sin marcar error

**Curso alternativo — falla la red y no hay cache (o está corrupto):**
1. El sistema entrega el error de conectividad, igual que hoy

**Curso alternativo — falla el guardado del cache:**
1. El sistema entrega igual el catálogo recién descargado — no cachear es degradación aceptable, no un error que valga la pena mostrarle al usuario

### Contrato

El módulo `Cities` define un `CityCatalogCache` con dos operaciones: guardar un catálogo y recuperarlo. Lo define el dominio; la implementación sobre `FileManager` vive del lado de afuera, en `CityCatalogCacheInfrastructure/` — el mismo split que ya usan `CityAPI` / `CityAPIInfrastructure` para la red.

La composición de "remoto con fallback al cache" es un `CityCatalogLoader` más, que envuelve a los otros dos y se arma en el Composition Root. Así ni el ViewModel ni `RemoteCityCatalogLoader` se enteran de que existe un cache: el ViewModel ya depende del protocolo `CityCatalogLoader` desde el MR #4, así que no cambia ni una línea.

El MR #2 dejó esto preparado a propósito al decidir que el mapper reciba `Data` y no una URL ni una respuesta HTTP — *"la decisión de cachear el JSON a disco queda libre para más adelante sin tocar esta historia"*.

**Qué se guarda:** el JSON crudo tal como llegó, no el catálogo indexado. El índice de búsqueda se reconstruye al cargar (12,9 ms medidos en el MR #2 sobre 200.000 ciudades), que es despreciable frente a la descarga de ~10 MB, y así el formato en disco es exactamente el mismo que el de la red — un solo mapper, un solo formato que mantener.

**Por qué NO se denormaliza `FavoriteCity`:** guardar nombre y coordenadas dentro de cada favorito haría visibles los favoritos offline con mucho menos trabajo, pero dejaría el resto de la app rota igual (sin catálogo no hay búsqueda ni lista) y metería una copia parcial del catálogo que puede desincronizarse del original. Se resuelve el problema de fondo o no se resuelve.

### Checklist

- [ ] Una carga remota exitosa guarda el catálogo en el cache
- [ ] Una carga remota exitosa entrega el catálogo aunque falle el guardado en cache
- [ ] Un error de red con cache disponible entrega el catálogo cacheado, sin error
- [ ] Un error de red sin cache entrega el error de conectividad
- [ ] Un cache con datos inválidos se trata como cache ausente, sin crash
- [ ] Un error de red con cache corrupto entrega el error de conectividad, no un catálogo parcial
- [ ] Guardar sobre un cache existente lo reemplaza, sin duplicar ni mezclar
- [ ] Recuperar del cache no produce side-effects (no lo borra, no lo reescribe)
- [ ] La cancelación durante la carga se propaga igual que en la Historia 3
- [ ] El ViewModel no cambia: sigue dependiendo solo de `CityCatalogLoader`
- [ ] Verificación de punta a punta con la red real cortada, después de una carga exitosa previa

---

## Historia 12 — Mantener la lista fluida con 200.000 resultados

**Deriva de [REQUISITOS.md](REQUISITOS.md):** *"La UI debe ser lo más responsiva posible mientras se escribe en el filtro"* y *"la lista debe actualizarse con cada carácter agregado/eliminado del filtro"*. Las Historias 1 y 5 dejaron esos dos requisitos correctos en resultado pero no en tiempo de respuesta.

**Como** usuario del catálogo
**Quiero** que la lista responda sin trabarse aunque haya 200.000 resultados
**Para** poder escribir y filtrar sin esperar a que la app se descongele

### El problema concreto que resuelve

Con el filtro de texto vacío, la búsqueda devuelve las 200.000 ciudades y el ViewModel se las entrega enteras a la `List`. Actualizar la lista obliga entonces a SwiftUI a resolver la identidad de la colección vieja y la nueva y a calcular el batch update contra el collection view que la respalda: un costo proporcional al tamaño de la colección **anterior**, pagado en el main thread.

Eso explica la forma exacta del síntoma. Escribiendo "Albuquerque" desde el filtro vacío, solo traba la "A" (200.000 → ~5.000); de la segunda letra en adelante se escribe fluido (~5.000 → ~700). Lo mismo con el switch "Solo favoritos" sin prefijo (200.000 → un puñado), y lo mismo al borrar hasta volver a filtro vacío.

No es el algoritmo de búsqueda: medido sobre 200.000 ciudades, tipear seis caracteres seguidos cuesta **0,37 ms en total** (~0,06 ms por tecla). El costo que se siente no está en el dominio.

### Escenarios

- **Dado** el filtro vacío con las 200.000 ciudades a la vista, **cuando** escribo el primer carácter, **entonces** la lista se actualiza sin trabarse
- **Dado** un prefijo escrito, **cuando** lo borro hasta dejar el filtro vacío, **entonces** la lista se actualiza sin trabarse
- **Dado** el filtro vacío, **cuando** activo o desactivo "Solo favoritos", **entonces** el switch cambia de posición al instante y la lista se actualiza sin trabarse
- **Dado** que scrolleé hasta el fondo de los resultados visibles, **cuando** sigo scrolleando, **entonces** aparecen más resultados sin cortes ni saltos
- **Dado** que scrolleé lejos del principio, **cuando** marco una ciudad como favorita, **entonces** la lista no vuelve al principio

### Use Case: Present Visible City Page

**Data (input):** prefijo actual, flag "solo favoritos", conjunto de IDs favoritos, pedido de más resultados

**Curso primario (happy path):**
1. El sistema resuelve los resultados que coinciden con la consulta vigente
2. El sistema entrega solo la primera página de esos resultados
3. El sistema recuerda cuántos resultados dejó visibles

**Curso alternativo — se pide más al llegar al final de lo visible:**
1. El sistema amplía la ventana visible en una página
2. El sistema entrega la ventana ampliada, sin recalcular la consulta

**Curso alternativo — se pide más con todos los resultados ya visibles:**
1. El sistema no cambia nada

**Curso alternativo — cambia la consulta (prefijo o flag de favoritos):**
1. El sistema vuelve a la primera página

**Curso alternativo — cambia solo el conjunto de favoritos (marcar/desmarcar):**
1. El sistema conserva la ventana visible — el usuario no pierde su lugar en la lista
2. Con el filtro de favoritos apagado, el sistema no vuelve a consultar el catálogo: entrega la misma página con el ícono de esa sola celda actualizado

### Contrato

La paginación es una decisión de presentación, no de dominio: `CityCatalog` sigue devolviendo el rango completo de coincidencias, y `CitySearchResults` solo suma la operación de acotarlo (`limited(to:)`), que se resuelve sobre el slice existente sin copiar entradas. `CityListViewModel` guarda el resultado completo puertas adentro y publica la ventana; la vista no decide cuándo pedir más, solo avisa qué fila apareció.

Lo que se publica es la ventana ya convertida en view models de celda, no el modelo de dominio *(desde el MR #8)*. Ese cruce entre resultados y favoritos pasa al lado testeado, y la vista deja de instanciar tipos de `Cities`. Consecuencia directa: como el ícono de favorito viaja adentro de la celda publicada, marcar un favorito con el filtro apagado **sí** vuelve a entregar la página. Lo que se sigue evitando, que es lo que importaba, es volver a consultar el catálogo.

Publicar la ventana no puede depender de su tamaño *(desde la corrección post-MR #8)*: lo que se guarda en `state` es una colección perezosa (`CityCellViewModels`) que envuelve `matchingResults.limited(to: visibleCount)` y arma cada `CityCellViewModel` recién cuando algo la indexa, no un `[CityCellViewModel]` construido con `.map` de antemano. Publicar cuesta O(1) sin importar si la ventana tiene 50 o 200.000 entradas. Lo que esto **no** resuelve: SwiftUI sigue diffeando la `List` contra la colección publicada anterior, y ese diff sí es proporcional al tamaño de la ventana — con scroll muy profundo y filtro vacío, ese costo queda abierto (ver Suggestion S1 de la revisión independiente).

**Por qué paginar y no debouncear.** Un debounce no elimina el trabajo, lo demora: la primera tecla seguiría pagando el diff de 200.000, solo que más tarde, y encima incumpliría *"la lista debe actualizarse con cada carácter"*. Paginar acota el costo de **toda** transición al tamaño de una página.

### Checklist

- [x] Una búsqueda con más resultados que el tamaño de página entrega solo la primera página
- [x] Pedir más sobre la última fila visible agrega la página siguiente
- [x] Pedir más sobre una fila que no es la última no cambia nada
- [x] Pedir más con todos los resultados ya visibles no cambia nada
- [x] Un prefijo nuevo vuelve la ventana a la primera página
- [x] Cambiar el flag "solo favoritos" vuelve la ventana a la primera página
- [x] Marcar un favorito con el filtro apagado conserva la ventana
- [x] Marcar un favorito con el filtro apagado cambia exactamente una celda de la página publicada *(reemplaza al ítem "no republica la lista" del MR #6, que dejó de ser cierto; ver la bitácora del MR #8)*
- [x] Marcar un favorito con el filtro apagado vuelve a entregar la página, que es lo que permite que el ícono cambie
- [x] Marcar un favorito con el filtro prendido conserva la ventana y actualiza la lista
- [x] `limited(to:)` acota respetando el orden, y con un tope mayor al total entrega todo
- [x] `limited(to:)` con un tope negativo entrega una lista vacía, no un crash
- [x] Un tamaño de página no positivo entrega igual una primera página y puede seguir creciendo
- [x] Verificación en la app real contra el gist: primera tecla, borrado hasta vacío, toggle sin prefijo y scroll hasta el fondo, sin trabas
- [x] Publicar la ventana no depende de su tamaño: 200.000 filas cuestan lo mismo que 50
