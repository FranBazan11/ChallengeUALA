# Ualá Mobile Challenge — iOS

*Juan Francisco Bazan Carrizo — 6 de agosto de 2026*

> Este README se completa en el MR final (#9), una vez que el código y las decisiones de implementación existen. Hasta entonces queda como esqueleto para que la estructura de la entrega esté decidida desde el principio.

## Enfoque para el problema de búsqueda

*Pendiente — se completa en el MR #9, con la implementación ya cerrada.*

## Decisiones y supuestos

*Pendiente. Ver [docs/BITACORA.md](docs/BITACORA.md) para el registro incremental de decisiones a medida que se toman.*

## Estructura del proyecto

Un único proyecto Xcode (`ChallengeUALA.xcodeproj`, en la raíz del repo) con 3 módulos:

| Target | Tipo | Responsabilidad |
|---|---|---|
| `Cities` | Framework (macOS + iPhone) | Dominio agnóstico de plataforma: modelo de `City`, índice de búsqueda, protocolos (`FavoritesStore`), capa de red y presentación (`@Observable` view models, sin SwiftUI). Multiplataforma para poder correr su suite en macOS sin bootear el simulador — el loop rápido de TDD. |
| `CitiesiOS` | Framework (iPhone) | Solo vistas SwiftUI, que observan los view models de `Cities`. Separado del app target para que sus tests (snapshots incluidos) corran sin lanzar la app completa. |
| `ChallengeUALA` | App (iPhone) | Composition Root — el único lugar del proyecto que instancia y cablea dependencias concretas (SwiftData, URLSession, MapKit). |

Cada uno de los tres tiene su target de tests (`CitiesTests`, `CitiesiOSTests`, `ChallengeUALATests`), más `ChallengeUALAUITests` para los flujos end-to-end de la app ensamblada.

Dentro de `Cities`, los archivos se agrupan por boundary, y `CitiesTests` espeja la misma estructura:

```
Cities/
├── CityFeature/           Modelo de dominio y el contrato CityCatalogLoader
├── CitySearch/            Índice de búsqueda por prefijo y binary search
├── CityAPI/               Mapeo del JSON del catálogo, contrato HTTPClient y la implementación remota de CityCatalogLoader
├── CityAPIInfrastructure/ Implementación de HTTPClient con URLSession
├── CityPresentation/      View models observables de la lista y de la celda
└── CityFavorites/         Contrato de persistencia de favoritos
```

**Schemes:** `Cities`, `CitiesiOS` y `ChallengeUALA` son el loop de desarrollo día a día — cada uno corre solo su propia suite. `CI_iOS` es un scheme aparte que junta los 4 test targets de iOS (`CitiesTests` + `CitiesiOSTests` + `ChallengeUALATests` + `ChallengeUALAUITests`) en una sola corrida, que es lo que ejecuta el job de iOS del CI.

## Cómo correr los tests

Desde Xcode: seleccionar el scheme (`Cities`, `CitiesiOS` o `ChallengeUALA`) y `⌘U`. `Cities` corre en el destino "My Mac"; los otros dos necesitan un simulador de iOS.

Los targets de iOS declaran explícitamente que no soportan Mac Catalyst ni "Designed for iPhone", así que el selector de destinos solo ofrece opciones válidas para cada scheme. Con el scheme `Cities` activo (destino "My Mac") el editor marca `No such module` en los targets iOS-only: es el comportamiento esperado de un proyecto multiplataforma —esos targets no se construyen para ese destino— y se resuelve cambiando de scheme, no es un problema del proyecto.

Desde línea de comandos, los mismos comandos que ejecuta el CI:

```bash
# Core de dominio, en macOS, sin simulador
xcodebuild test -project ChallengeUALA.xcodeproj -scheme Cities \
  -destination 'platform=macOS' -testPlan Cities

# Los 4 targets de iOS juntos, en el simulador
xcodebuild test -project ChallengeUALA.xcodeproj -scheme CI_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -testPlan CI_iOS
```

El CI (`.github/workflows/CI.yml`) corre en cada push y pull request contra `master`, con estos mismos dos comandos.

## Documentación de proceso

- [docs/REQUISITOS.md](docs/REQUISITOS.md) — el enunciado del challenge
- [docs/USE-CASES.md](docs/USE-CASES.md) — historias, escenarios y checklist de cada tarea
- [docs/BITACORA.md](docs/BITACORA.md) — registro de decisiones por MR, incluido lo que se descartó
- [docs/PLAN-TECNICO.md](docs/PLAN-TECNICO.md) — plan técnico inicial (sujeto a revisión en el MR #9, una vez que este README contenga las decisiones finales)
