# Mobile Challenge - Ualá

Este es un único challenge que puede resolverse en Kotlin para Android, o Swift para iOS.

## Objetivo

El objetivo de esta asignación es evaluar las habilidades de resolución de problemas, el criterio de UX y la calidad de código. Considerá cómo lo abordarías a nivel producción al construirlo.

## Requisitos

Tenemos una lista de ciudades con alrededor de 200k entradas en formato JSON. Cada entrada contiene la siguiente información:

```json
{
  "country": "UA",
  "name": "Hurzuf",
  "_id": 707860,
  "coord": {
    "lon": 34.283333,
    "lat": 44.549999
  }
}
```

Tu tarea es:

- En la App, descargar la lista de ciudades desde este gist.
- Poder filtrar los resultados por un string de prefijo dado, siguiendo estos requisitos:
  - Seguir la definición de prefijo especificada en la sección de aclaraciones más abajo.
  - Optimizar para búsquedas rápidas. El tiempo de carga de la app no es tan importante.
  - La búsqueda no distingue entre mayúsculas y minúsculas (case insensitive).
- Mostrar estas ciudades en una lista scrolleable, en orden alfabético (primero la ciudad, después el país). Por lo tanto, "Denver, US" debería aparecer antes que "Sydney, Australia".
  - La UI debe ser lo más responsiva posible mientras se escribe en el filtro.
  - La lista debe actualizarse con cada carácter agregado/eliminado del filtro.
  - Permitir filtrar solo los favoritos.
- Cada celda de ciudad debe:
  - Mostrar la ciudad y el código de país como título.
  - Mostrar las coordenadas como subtítulo.
  - Mostrar y alternar (toggle) como favorito.
  - Al tocarla, navegar el mapa hacia las coordenadas de la ciudad.
  - Contener un botón que, al tocarlo, abra una pantalla de información sobre la ciudad seleccionada.
- Crear una pantalla de información para una Ciudad.
  - Incluir cualquier dato no mostrado en la lista.
  - Puede incluir datos de una fuente adicional.
  - Organizar la información de la forma que mejor se adapte a la experiencia de usuario.
- Crear una UI dinámica que siga los wireframes.
  - Por lo tanto, en modo vertical (portrait) deben usarse pantallas diferentes para la lista y el mapa, pero en modo horizontal (landscape) debe usarse una única pantalla.
- Permitir a los usuarios seleccionar ciudades favoritas.
  - Las ciudades favoritas deben recordarse entre lanzamientos de la app.
- Proveer tests unitarios que demuestren que tu algoritmo de búsqueda muestra los resultados correctos ante distintos inputs, incluyendo inputs inválidos.
- Proveer tests de UI/unitarios para las pantallas que hayas implementado.

## Criterios de Evaluación

- Proveer un README.md explicando tu enfoque para resolver el problema de búsqueda y cualquier otra decisión importante que hayas tomado o supuesto que hayas asumido durante la implementación.
- Podés preprocesar la lista en cualquier otra representación que consideres más eficiente para las búsquedas y la visualización. Proveer información de por qué esa representación es más eficiente en los comentarios del código.
- Están prohibidas las versiones pre-release (por ejemplo, beta) de IDEs, SDKs, etc.
- En Android la solución debe:
  - Ser compatible con la última API de Android.
  - Construir las Views con Jetpack Compose.
- En iOS la solución debe:
  - Ser compatible con la última versión de Swift.
  - Ser compatible con la última versión de iOS.
  - Estar prohibidas las librerías de terceros.
  - Construir las views usando SwiftUI.

## Aclaraciones

- Definimos un string de prefijo como: un substring que coincide con los caracteres iniciales del string objetivo. Por ejemplo, asumamos las siguientes entradas:
  - Alabama, US
  - Albuquerque, US
  - Anaheim, US
  - Arizona, US
  - Sydney, AU
- Si el prefijo dado es "A", deberían aparecer todas las ciudades excepto Sydney. Por el contrario, si el prefijo dado es "s", el único resultado debería ser "Sydney, AU".
- Si el prefijo dado es "Al", "Alabama, US" y "Albuquerque, US" son los únicos resultados.
- Si el prefijo dado es "Alb", entonces el único resultado es "Albuquerque, US".

## Contacto

Sentite libre de contactarnos si tenés alguna pregunta o necesitás una aclaración sobre cualquier parte de este challenge.

- ioschallenge@uala.com.ar
- androidchallenge@uala.com.ar

## Requisitos de Entrega (Submission)

- Usar un servicio hosteado para compartir el repositorio git de tu solución (GitHub, Gitlab) y permitir acceso público durante la revisión.
- Queremos ver el historial de versionado también.
- Por favor remové el acceso público una vez que te hayamos informado el resultado de la revisión.
- Incluir este documento como parte de tu entrega.

## Wireframes

El documento incluye wireframes (mockups) que ilustran el comportamiento esperado de la UI:

- **Pantalla en modo vertical (portrait) — Lista:** un campo de búsqueda ("filter") en la parte superior, seguido de una lista scrolleable de ciudades (City 1, City 2, City 3, ...). Al seleccionar una ciudad de la lista, se navega a una pantalla separada de mapa con un botón "Back" para volver.
- **Pantalla en modo horizontal (landscape):** una única pantalla dividida en dos paneles — la lista de ciudades con el campo de filtro a la izquierda, y el mapa mostrando la ubicación de la ciudad seleccionada a la derecha.

*(Las imágenes originales de los wireframes se encuentran en el PDF fuente: `Mobile Challenge - Engineer - v0.8.pdf`)*
