---
name: task-mr
description: Use when implementing one of the project's numbered MRs (or any task with a checklist already in docs/USE-CASES.md) — the full cycle from branch to handoff, ending with the user reviewing and committing, never Claude.
---

# task-mr

El ciclo completo para implementar una tarea que ya tiene su use case escrito. Termina en una entrega para que el usuario revise y commitee — nunca en un commit hecho por Claude.

## Cuándo usarla

Al arrancar el trabajo de una tarea/MR. Si el use case todavía no existe en `docs/USE-CASES.md`, invocar primero la skill `use-case`.

## Pasos

1. **Confirmar el contrato.** Releer en [docs/USE-CASES.md](../../../docs/USE-CASES.md) la historia y el checklist de la tarea. Si algo no está claro o falta un curso alternativo, volver a la skill `use-case` antes de seguir.

2. **Crear la rama.**
   ```
   git switch master && git pull
   git switch -c feature/<slug-en-ingles>
   ```
   Crear la rama es lo único de git que hace Claude en este ciclo.

3. **TDD por cada ítem del checklist:** test que falla → implementación mínima que lo pone en verde → refactor sin romper nada. Cada archivo nuevo lleva el header de autoría que define `CLAUDE.md`. Nada de comentarios salvo la única excepción ya documentada ahí.

4. **Verificar antes de afirmar nada.** Correr la suite completa del/los target(s) tocados y leer el output real — no asumir que algo pasa porque "debería". Si hay UI involucrada, seguir además lo que pida el flujo de verificación de la skill `run` si está disponible.

5. **Tildar el checklist** en `docs/USE-CASES.md` — solo los ítems efectivamente cubiertos por un test que corrió y pasó.

6. **Escribir la entrada en `docs/BITACORA.md`**, arriba de todo (orden: más nueva primero). Formato: qué se construyó, qué se decidió y por qué, qué se descartó y por qué, qué sigue. La parte de "qué se descartó" no es opcional — es la que le muestra al reviewer que hubo evaluación de alternativas.

7. **Entregar, no commitear.** Dejar todo en el working tree, sin `git add`. Presentar al usuario:
   - Resumen de qué cambió y por qué
   - El output real de correr los tests
   - **La secuencia de commits propuesta** — nunca uno solo gigante. Cada commit de la lista con sus archivos exactos y su mensaje en español e imperativo, en el orden en que deberían aplicarse
   - La descripción del MR lista para pegar (qué / por qué / cómo verificarlo)

   El usuario revisa, decide si hace falta ajustar algo, y recién ahí va commiteando (y pushea al final).

## Señal de que algo se torció

Si en cualquier punto de esta skill parece natural correr `git add` o `git commit`, es señal de que la tarea ya está terminada y le toca al usuario — no una excusa para hacerlo.
