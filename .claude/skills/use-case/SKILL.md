---
name: use-case
description: Use when a requirement from docs/REQUISITOS.md needs to become a use case before any production code is written — converts a raw requirement into narrative + scenarios + use case + contract + checklist in docs/USE-CASES.md.
---

# use-case

Convierte un requisito crudo en un contrato accionable, antes de tocar código de producción. `CLAUDE.md` prohíbe escribir producción sin este paso hecho.

## Cuándo usarla

Al arrancar cualquier tarea que agregue o cambie comportamiento observable. Si el requisito ya tiene su historia completa en `docs/USE-CASES.md`, no hace falta repetir esta skill — se pasa directo a `task-mr`.

## Pasos

1. **Releer el requisito exacto** en [docs/REQUISITOS.md](../../../docs/REQUISITOS.md). No trabajar de memoria ni de una paráfrasis previa.

2. **Escribir la narrativa.**
   ```
   Como <rol>
   Quiero <acción>
   Para <beneficio>
   ```

3. **Escribir los escenarios** en formato Dado/Cuando/Entonces. Cubrir el happy path y **los sad paths** — inputs inválidos, estados vacíos, ausencia de conectividad, lo que aplique. Un use case sin curso alternativo está incompleto.

4. **Redactar el use case** con esta forma:
   - **Data (input):** qué entra
   - **Curso primario (happy path):** pasos numerados, en términos de "el sistema hace X"
   - **Cursos alternativos (sad paths):** uno por cada desvío identificado en los escenarios

5. **Identificar el contrato.** Si la implementación va a necesitar un protocolo nuevo (un store, un loader, un client), nombrarlo ahora y decidir quién lo define — siempre el lado más interno (el dominio o el use case), nunca el lado de infraestructura.

6. **Si la historia toca infraestructura** (persistencia, red, disco), agregar un **inbox checklist**: la lista completa de casos que la implementación tiene que cubrir antes de considerarse lista (inserción a vacío, inserción a no-vacío, error simulado, lectura sin side-effects, etc.). Sirve de guía mientras se implementa y de checklist de cobertura al terminar.

7. **Volcar todo en `docs/USE-CASES.md`**, siguiendo la estructura de las historias ya existentes en ese archivo. Los checkboxes del checklist arrancan sin tildar — se tildan durante `task-mr`, no acá.

## Salida esperada

Una sección nueva (o ampliada) en `docs/USE-CASES.md`, con narrativa, escenarios, use case y checklist. Nada de código todavía.
