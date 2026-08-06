# Ualá Mobile Challenge — Plan Técnico (iOS)

*Complementa a [REQUISITOS.md](REQUISITOS.md) y al PDF original ([Mobile Challenge - Engineer - v0.8.pdf](Mobile%20Challenge%20-%20Engineer%20-%20v0.8.pdf)) — el enunciado. Este doc es el plan de ataque: desafíos, metodología y las decisiones técnicas ya resueltas para arrancar.*

> **Revisión aplicada** (para que estos catches no se pierdan en el camino):
> 1. La referencia al enunciado apuntaba a `Uala_Mobile_Challenge.md`, un archivo que no existe en este repo — corregida arriba.
> 2. `FavoriteCity` (SwiftData) estaba expuesto sin protocolo — se agregó `FavoritesStore` en §4 para no acoplar el dominio a SwiftData.
> 3. `CitySearchEntry` no era `Sendable` — se agregó, necesario si el índice cruza de un `Task` de background al `@MainActor` bajo Swift 6 strict concurrency.
> 4. Se agregó nota sobre `\u{FFFF}` vs `\u{10FFFF}` como cota superior del prefix range (§3.5) — la actual funciona para este dataset, pero vale dejar la decisión explícita.

## 1. Desafíos principales

1. **Índice de búsqueda sobre 200k ciudades.** Es el criterio de evaluación más explícito del enunciado. Resuelto con array ordenado + binary search — detalle en §3.
2. **Responsividad de la UI mientras se tipea.** Búsqueda en background (Task/actor), cancelando el Task anterior en cada nuevo carácter — sin esto, race conditions con resultados viejos pisando a los nuevos.
3. **Layout adaptativo portrait/landscape.** `verticalSizeClass`, no `horizontalSizeClass` — detalle en §5.
4. **Dónde vive el catálogo de 200k ciudades.** Memoria, no SwiftData — detalle en §4.
5. **Scope discipline en 6 días.** El riesgo no es falta de rigor — es sobre-ingeniería. Resuelto con MoSCoW — detalle en §2.

## 2. Metodología — MoSCoW + plan de 6 días

### 2.1 Qué es MoSCoW

Técnica de priorización para proyectos con tiempo fijo:

- **M**ust have — sin esto no hay entrega evaluable. No se toca.
- **S**hould have — importante, pero el proyecto sobrevive sin eso.
- **C**ould have — entra solo si sobra tiempo, cero costo si no entra.
- **W**on't have (this time) — declarado explícitamente afuera, para que no se cuele por goteo día a día.

Se arma una vez al principio y se revisa cada noche: si hay atraso, se cortan Could/Won't sin culpa, nunca un Must.

### 2.2 Plan de 6 días

| Día | Must-have |
|---|---|
| 1 | Domain model + parseo JSON + índice + tests (incluidos inputs inválidos) |
| 2 | Composition Root + ViewModel + List conectada al índice — probar con las 200k en Release, no solo Debug |
| 3 | Favoritos: persistencia del Set de IDs, toggle, filtro "solo favoritos" |
| 4 | MapKit + navegación adaptativa + info screen |
| 5 | UI tests + edge cases (sin resultados, sin favoritos, rotar a mitad de búsqueda) |
| 6 | README con las decisiones documentadas + buffer + limpieza del repo |

**Could-have** (solo si sobra tiempo; ninguno vale la pena si pone en riesgo un Must-have): fuente adicional en el info screen (URLSession contra una API pública sin key), labels de VoiceOver.

## 3. Motor de búsqueda

### 3.1 Por qué no `.filter(hasPrefix:)`

`.filter` recorre el array completo evaluando la condición en cada elemento — O(n) por cada búsqueda, sin importar cuánto se debouncee el input. Con 200k entries y alguien tipeando rápido, se nota.

### 3.2 El índice: `CitySearchEntry`

`searchKey` no es lo que el usuario tipea — es un dato precalculado, uno por cada ciudad del catálogo, armado una sola vez al cargar los datos. Lo que el usuario tipea (el prefix) se compara contra cada `searchKey` ya existente. `cityIndex` es el puntero de vuelta al `City` real.

```swift
struct CitySearchEntry: Sendable {
    let searchKey: String   // ej. "alabama, us" — lowercased, precalculado una vez
    let cityIndex: Int      // índice del City real en el array del catálogo
}
```

`Sendable` porque el índice se arma en background (parseo del JSON) y se lee desde el `@MainActor` ViewModel — sin la conformance, Swift 6 con strict concurrency no te deja cruzar ese límite.

La ganancia de precalcular `searchKey`: evita llamar `.lowercased()` repetidamente durante las comparaciones del sort y del binary search. `City` en sí no es un modelo pesado (pocos campos) — el ahorro real está ahí, no en "aligerar" el modelo.

### 3.3 Construir el índice (una sola vez, al cargar)

El sort se hace una sola vez al arrancar la app (costo pagado una vez; para 200k, milisegundos). Cada letra tipeada dispara una búsqueda sobre el array ya ordenado — nunca se reordena durante la interacción.

```swift
extension CityCatalog {
    static func buildIndex(_ cities: [City]) -> [CitySearchEntry] {
        cities.enumerated()
            .map { index, city in
                CitySearchEntry(searchKey: "\(city.name), \(city.country)".lowercased(), cityIndex: index)
            }
            .sorted { $0.searchKey < $1.searchKey }
    }
}
```

> Nota: una versión anterior de este snippet (`.map { CitySearchEntry(..., cityIndex: $0) }` usando `$0`/`$1`) no compila — `.map` sobre `enumerated()` pasa un solo argumento tupla, no dos. La forma correcta es destructurar con nombres explícitos (`index, city in`), como arriba.

### 3.4 Binary search: `lowerBound`

En un array ordenado, en vez de mirar uno por uno, se mira el del medio y se descarta la mitad que no sirve. Con 200k elementos son ~18 pasos (log₂ 200.000 ≈ 18) contra hasta 200.000 comparaciones de un scan lineal.

```swift
extension Array {
    func lowerBound(where predicate: (Element) -> Bool) -> Index {
        var lo = startIndex, hi = endIndex
        while lo < hi {
            let mid = index(lo, offsetBy: distance(from: lo, to: hi) / 2)
            if predicate(self[mid]) { lo = index(after: mid) } else { hi = mid }
        }
        return lo
    }
}
```

`lowerBound` devuelve el primer índice donde el predicado deja de cumplirse. Como el array está ordenado, todo lo que cumple la condición queda agrupado al principio, así que existe una frontera exacta.

### 3.5 El rango del prefix: el truco `key + "\u{FFFF}"`

```swift
extension CityCatalog {
    func search(prefix: String) -> ArraySlice<CitySearchEntry> {
        guard !prefix.isEmpty else { return searchIndex[...] }
        let key = prefix.lowercased()
        let lo = searchIndex.lowerBound { $0.searchKey < key }
        let hi = searchIndex.lowerBound { $0.searchKey < key + "\u{FFFF}" }
        return searchIndex[lo..<hi]
    }
}
```

`\u{FFFF}` es el carácter Unicode más alto. `"al" + \u{FFFF}` es mayor que cualquier string real que empiece con "al" (después de "al", cualquier carácter normal es menor a `\u{FFFF}`), pero menor que cualquier string que se separe de "al" antes de terminarlo (como "anaheim" — ahí la comparación se decide en la 'n', nunca llega a tocar el `\u{FFFF}`). Es un tope artificial: "el final de todo lo que puede empezar con este prefijo, y nada más".

> **Nota:** `\u{FFFF}` alcanza para este dataset (nombres en ASCII/Latin, como "Hurzuf" del ejemplo del enunciado). Si en algún momento el catálogo pudiera tener nombres con caracteres fuera del Basic Multilingual Plane, `\u{10FFFF}` (el máximo real de Unicode) es la cota 100% a prueba de balas. Vale la pena dejar esto como decisión consciente en el README, no como asunción tácita.

**Ejemplo trazado** — catálogo `[Alabama, Albuquerque, Anaheim, Arizona, Sydney]` (ya ordenado), buscando prefix `"al"`:

*Buscando `lo`* (predicado: `searchKey < "al"`)

| lo, hi | mid → valor | ¿ < "al"? | acción |
|---|---|---|---|
| 0, 5 | 2 → anaheim, us | No | hi = 2 |
| 0, 2 | 1 → albuquerque, us | No | hi = 1 |
| 0, 1 | 0 → alabama, us | No | hi = 0 |
| 0, 0 | — | termina | **lo = 0** |

*Buscando `hi`* (predicado: `searchKey < "al" + \u{FFFF}`)

| lo, hi | mid → valor | ¿ < "al\u{FFFF}"? | acción |
|---|---|---|---|
| 0, 5 | 2 → anaheim, us | No | hi = 2 |
| 0, 2 | 1 → albuquerque, us | Sí | lo = 2 |
| 2, 2 | — | termina | **hi = 2** |

Rango final `[0, 2)` → índices 0 y 1 → **Alabama, Albuquerque** — coincide con el ejemplo del propio enunciado de Ualá para el prefix "Al".

### 3.6 Complejidad y por qué gana al trie

O(log n) para ubicar el rango + O(k) para devolverlo (k = cantidad de resultados). Como el array base ya está ordenado, el slice sale ordenado — no hace falta un sort en cada keystroke.

Un trie de 200k entries es nodos dispersos en el heap — cada paso de recorrido es un salto de puntero, cache miss potencial. Un array de structs es contiguo, el CPU prefetchea el bloque siguiente. Para prefix matching puro (no fuzzy, no autocomplete difuso) con prefijos cortos, el array gana limpio y con menos código — y sin libs de terceros permitidas, un trie a mano es más código para mantener y testear.

## 4. Arquitectura de datos: catálogo vs. favoritos

**Catálogo (200k ciudades): memoria, no SwiftData.** Es reference data estática y de solo lectura — se carga una vez al arrancar, nunca se edita. Meterla en SwiftData suma schema, fetch requests con predicates, y el overhead de `@Model` (reference type con change tracking) — todo costo sin beneficio, porque nunca hay un `UPDATE` sobre una ciudad.

```swift
struct City: Identifiable, Sendable {
    let id: Int
    let name: String
    let country: String
    let lat: Double
    let lon: Double
}

final class CityCatalog {
    let cities: [City]
    let searchIndex: [CitySearchEntry]

    init(cities: [City]) {
        self.cities = cities
        self.searchIndex = Self.buildIndex(cities)
    }
}
```

El JSON del gist se parsea una vez. Si conviene cachearlo a disco (para no re-descargar 200k registros en cada launch), eso es persistencia del JSON crudo vía `FileManager` — no un modelo relacional en SwiftData.

**Favoritos: sí van en SwiftData.** Son datos que el usuario crea/edita y que necesitan sobrevivir entre sesiones con cambios incrementales — exactamente el caso de uso para el que SwiftData está pensado.

```swift
import SwiftData

@Model
final class FavoriteCity {
    var cityID: Int
    init(cityID: Int) { self.cityID = cityID }
}
```

**No exponer `@Model`/`ModelContext` directo al ViewModel.** El dominio no debería saber si atrás hay SwiftData, UserDefaults o un archivo. Un protocolo chico alcanza:

```swift
protocol FavoritesStore {
    func loadFavoriteIDs() -> Set<Int>
    func setFavorite(_ cityID: Int, isFavorite: Bool)
}

final class SwiftDataFavoritesStore: FavoritesStore {
    private let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func loadFavoriteIDs() -> Set<Int> {
        let favorites = (try? context.fetch(FetchDescriptor<FavoriteCity>())) ?? []
        return Set(favorites.map(\.cityID))
    }

    func setFavorite(_ cityID: Int, isFavorite: Bool) {
        if isFavorite {
            context.insert(FavoriteCity(cityID: cityID))
        } else if let existing = try? context.fetch(
            FetchDescriptor<FavoriteCity>(predicate: #Predicate { $0.cityID == cityID })
        ).first {
            context.delete(existing)
        }
        try? context.save()
    }
}
```

El ViewModel depende de `FavoritesStore` (el protocolo), no de `SwiftDataFavoritesStore` ni de `ModelContext` — así el test del ViewModel usa un fake en memoria, y `SwiftDataFavoritesStore` se prueba aparte en un test de integración.

## 5. Layout adaptativo (portrait/landscape)

**`verticalSizeClass`, no `horizontalSizeClass`.** En iPhones que no son Plus/Pro Max, `horizontalSizeClass` es siempre `.compact` — portrait o landscape, no cambia. `verticalSizeClass` sí es consistente en todos los modelos: `.regular` en portrait, `.compact` en landscape.

```swift
@Environment(\.verticalSizeClass) private var vSizeClass

var body: some View {
    if vSizeClass == .compact {
        HStack { CityListView(...); MapView(...) }   // landscape: juntas
    } else {
        NavigationStack { CityListView(...) }         // portrait: separadas
    }
}
```

**Por qué no `NavigationSplitView`.** Es la opción "de manual" para list+detail, pero reacciona a `horizontalSizeClass`, no a vertical — en la mayoría de iPhones se queda en modo una-sola-columna incluso en landscape, y no resuelve el requisito del enunciado tal cual está pedido. Por eso el control manual con `verticalSizeClass` es la opción correcta acá. (En iPad el panorama es otro — `.regular`x`.regular` casi siempre en fullscreen — pero el challenge apunta a iPhone.)

## 6. Checklist para el README

Decisiones a documentar explícitamente (el enunciado las pide como "assumptions you made"):

- [ ] Por qué el índice es un array ordenado + binary search, y no un trie
- [ ] Por qué `searchKey` se precalcula una sola vez en vez de recalcular `.lowercased()` en cada comparación
- [ ] Por qué el catálogo vive en memoria y no en SwiftData
- [ ] Por qué SwiftData se usa solo para favoritos, y por qué está detrás de un protocolo `FavoritesStore`
- [ ] Por qué `verticalSizeClass` y no `horizontalSizeClass` / `NavigationSplitView`
- [ ] Cualquier assumption sobre el formato/encoding del JSON del gist (incluida la cota `\u{FFFF}` del prefix range)
