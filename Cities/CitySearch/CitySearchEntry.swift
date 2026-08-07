//
//  CitySearchEntry.swift
//  Cities
//
//  Created by Juan Francisco Bazan Carrizo on 06/08/2026.
//

/// Entrada del índice de búsqueda: el catálogo se preprocesa una sola vez en un array de
/// `CitySearchEntry` ordenado por `searchKey`, y cada búsqueda por prefijo se resuelve con
/// dos binary searches sobre ese array.
///
/// Por qué esta representación y no las alternativas, sobre 200.000 ciudades:
///
/// - **Contra `filter(hasPrefix:)`**: recorrer el catálogo entero es O(n) por tecleo, y el
///   enunciado pide que la lista se actualice con cada carácter agregado o borrado. Ubicar
///   el rango en el array ordenado es O(log n) — ~18 comparaciones contra hasta 200.000.
///
/// - **Contra un trie**: un trie de 200.000 entradas son nodos dispersos en el heap, y cada
///   paso del recorrido es un salto de puntero con cache miss potencial. Este array es
///   memoria contigua, así que el CPU prefetchea el bloque siguiente y el binary search
///   toca pocas líneas de caché. Para prefix matching exacto — no fuzzy, no autocompletado
///   difuso — el array gana, con mucho menos código para mantener y testear.
///
/// - **`searchKey` precalculada**: se arma una sola vez al construir el índice, y evita
///   llamar `lowercased()` en cada comparación del sort y de cada binary search posterior.
///
/// - **`cityIndex` en vez de la `City`**: la entrada pesa una `String` y un `Int`, así que
///   entran más entradas por línea de caché durante el descenso del binary search. La
///   `City` se resuelve recién al leer un resultado concreto.
///
/// El costo se paga una sola vez al cargar el catálogo, que es exactamente el trade-off que
/// el enunciado autoriza: *"Optimizar para búsquedas rápidas. El tiempo de carga de la app
/// no es tan importante."*
///
/// Como el array base ya está ordenado, el rango devuelto sale ordenado por ciudad y después
/// por país, sin reordenar nada en cada tecleo.
struct CitySearchEntry: Sendable {
    let searchKey: String
    let cityIndex: Int
}
