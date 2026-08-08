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

### Use Case: Toggle Favorite City

**Data (input):** id de la ciudad, estado deseado (favorita / no favorita)

**Curso primario (happy path):**
1. El sistema persiste el nuevo estado de favorito para esa ciudad
2. El sistema confirma el cambio

**Curso alternativo — toggle repetido sobre la misma ciudad:**
1. El sistema aplica el último estado solicitado, sin duplicar entradas

### Checklist

- [ ] Marcar una ciudad no favorita la deja favorita
- [ ] Desmarcar una ciudad favorita la deja no favorita
- [ ] El estado persiste entre instancias del store (simulando reinicio de la app)
- [ ] Alternar dos veces sobre la misma ciudad no genera estado inconsistente ni entradas duplicadas
- [ ] El ViewModel depende del protocolo `FavoritesStore`, no de SwiftData directamente

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

- [ ] Filtro de favoritos solo, sin prefijo
- [ ] Filtro de favoritos combinado con un prefijo
- [ ] Sin favoritos, el resultado es una lista vacía, no un error
- [ ] Desactivar el filtro vuelve a mostrar el catálogo completo (filtrado por prefijo si corresponde)

---

## Historia 6 — Ver la ciudad seleccionada en el mapa

**Como** usuario del catálogo
**Quiero** que al tocar una ciudad el mapa navegue a sus coordenadas
**Para** ubicarla geográficamente

### Escenarios

- **Dado** la lista de ciudades, **cuando** toco una ciudad, **entonces** el mapa centra su vista en las coordenadas de esa ciudad
- **Dado** que estoy en portrait, **cuando** toco una ciudad, **entonces** navego a una pantalla de mapa separada, con un botón para volver
- **Dado** que estoy en landscape, **cuando** toco una ciudad, **entonces** el mapa se actualiza en el panel derecho, sin navegar a otra pantalla

### Use Case: Show City On Map

**Data (input):** coordenadas de la ciudad seleccionada

**Curso primario (happy path):**
1. El sistema recibe las coordenadas de la ciudad seleccionada
2. El sistema centra el mapa en esas coordenadas

### Checklist

- [ ] Seleccionar una ciudad actualiza la región visible del mapa
- [ ] En portrait, seleccionar una ciudad navega a la pantalla de mapa
- [ ] En landscape, seleccionar una ciudad actualiza el panel de mapa sin navegar
- [ ] Volver desde el mapa en portrait conserva el estado del filtro y del scroll de la lista

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

### Use Case: Adapt Layout To Orientation

**Data (input):** clase de tamaño vertical del entorno

**Curso primario (happy path):**
1. El sistema evalúa la clase de tamaño vertical disponible
2. El sistema compone lista y mapa como pantallas separadas si es `.regular`, o como paneles de una sola pantalla si es `.compact`

### Checklist

- [ ] Snapshot en portrait: lista y mapa separados
- [ ] Snapshot en landscape: lista y mapa en paneles
- [ ] Rotar a mitad de búsqueda conserva el texto del filtro
- [ ] Rotar con una ciudad seleccionada conserva la selección

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

### Checklist

- [x] Estado inicial "cargando" antes de que la primera carga resuelva
- [x] Carga exitosa deja el estado en "cargado", con los resultados de búsqueda del prefijo vigente
- [x] Error de conectividad deja el estado en "error" con un mensaje
- [x] Datos inválidos deja el estado en "error" con un mensaje
- [x] Reintentar (una nueva llamada a cargar) puede resolver en "cargado" después de una falla previa
- [x] Cancelación no produce un estado de error

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
