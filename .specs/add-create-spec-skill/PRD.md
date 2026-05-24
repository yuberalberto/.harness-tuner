## Problem Statement

El flujo SDD de harness-tuner no tiene enforcement. Un developer puede invocar `/to-prd`,
ver el PRD publicado, y saltar directo a implementación — sin pasar por `/to-issues` ni
`/tdd-cycle`. El resultado es trabajo sin descomposición en vertical slices ni ciclo TDD.

Adicionalmente, el output de la sesión de grilling es efímero: vive solo en el contexto
de conversación. Cuando la sesión es larga o se interrumpe, no hay forma de delegar la
escritura del PRD a un agente fresco. Finalmente, los issues usan IDs locales por spec
(`01`, `02`) que no permiten referencias cruzadas únicas entre specs.

## Solution

Un nuevo skill `/create-spec` que orquesta el flujo SDD completo con checkpoints HITL
explícitos. `grill-with-docs` produce un artefacto persistente `GRILL.md` por feature.
Los issues adoptan IDs globalmente únicos `NNN-NN` embebidos en nombres de carpeta y archivo.

## User Stories

1. Como developer, quiero invocar un único skill que me guíe desde el grilling hasta los
   issues, para no tener que recordar el orden correcto del flujo SDD.
2. Como developer, quiero confirmar explícitamente cada transición entre stages, para
   mantener control total del proceso sin avances automáticos.
3. Como developer, quiero que el mismo agente que grilla también escriba el PRD,
   para aprovechar el contexto acumulado sin necesidad de handoffs ni documentos intermedios.
4. Como developer, quiero referenciar un issue desde un commit o PR con un ID único como
   `003-02`, para ubicarlo sin ambigüedad independientemente de en qué spec vive.
5. Como developer, quiero que `/create-spec` sugiera `/tdd-cycle` al finalizar pero no
   lo ejecute, para decidir yo cuándo y en qué issue arrancar la implementación.
6. Como developer, quiero que las specs existentes (legacy) no sean renombradas, para no
   romper referencias en commits anteriores.
7. Como developer, quiero seguir pudiendo invocar `/grill-with-docs`, `/to-prd` y
   `/to-issues` de forma standalone, para casos donde no necesito el flujo completo.

## Implementation Decisions

- **Nuevo skill `create-spec`**: orquestador con dos stages ejecutados por el mismo agente.
  Stage 1: `grill-with-docs` → checkpoint HITL `[Y/n]` → `to-prd` → `PRD.md`.
  Stage 2: checkpoint HITL `[Y/n]` → `to-issues` → `issues/` + `INDEX.md`.
  Al terminar, sugiere `/tdd-cycle NNN-01` sin ejecutarlo.
  El mismo agente maneja grilling y PRD — no hay handoff ni artefacto intermedio.
  No se produce `GRILL.md`.

- **Modificación a `to-issues`**: adoptar el esquema de naming `NNN-slug` para carpetas
  de spec y `NNN-NN-slug.md` para archivos de issue. El número de spec (`NNN`) se
  auto-deriva contando los directorios numerados existentes en `.specs/` e incrementando
  en uno. Los issues legacy no se renombran.

- **Modificación a `sdd-process.md`**: actualizar la tabla de routing para que features
  nuevas apunten a `/create-spec` en lugar de la cadena manual. Los skills individuales
  permanecen en la tabla como opciones standalone.

- **Skills individuales sin modificar**: `grill-with-docs`, `to-prd`, `to-issues` quedan
  exactamente como están — sin cambios. Solo se invocan en secuencia desde `/create-spec`.

## Testing Decisions

- Los skills son archivos markdown — su comportamiento se verifica contra los criterios
  de aceptación, no con tests automatizados.
- Criterio principal: después de `/create-spec`, existen `.specs/NNN-slug/GRILL.md`,
  `PRD.md`, `INDEX.md`, y al menos un archivo `NNN-NN-slug.md` en `issues/`.
- Criterio de no-regresión: invocar `/to-prd`, `/to-issues`, `/grill-with-docs` de forma
  standalone produce el mismo resultado que antes.

## Out of Scope

- Renombrar specs legacy (`add-cascade-adapter`, `refactor-entire-harness-to-sdd+ddd+tdd`,
  `refactor-templates-naming`).
- Modificar `/tdd-cycle` — el skill no participa en `/create-spec`.
- Integración con issue trackers externos (GitHub Issues, Linear).
- Soporte diferenciado para `templates-cascade` — los skills del harness son agnósticos
  al agente IDE.

## Further Notes

`/grill-me` queda como la opción para exploración libre sin compromiso SDD. La línea
divisoria: si el resultado de la conversación va a producir código, usá `/create-spec`;
si es para explorar o pensar en voz alta, usá `/grill-me`.
