# Plan controlado para trazas de procesos nocturnos

## Objetivo
Construir un backlog auditable de procesos nocturnos para implementar trazas con `P_TRAZA_CORE` por oleadas, minimizando riesgo operativo.

## Archivos base
- Inventario editable: `docs/nocturnos/trazabilidad_nocturnos_inventario.csv`
- Origen de secuencia: `NocturnosSecuenciales/alldays.sh`

## Convenciones de estado sugeridas
- `pendiente`: proceso sin analisis tecnico
- `en-analisis`: se reviso package/procedimiento
- `listo-dev`: definido alcance de cambio
- `en-dev`: trazas en implementacion
- `en-pruebas`: validacion funcional y tecnica
- `implementado`: en rama integrada
- `n/a`: no aplica (ejemplo: scripts FTP)

## Criterios para priorizar
1. Criticidad operativa (impacto de falla).
2. Frecuencia de error historica.
3. Dependencias en cadena (procesos tempranos primero).
4. Facilidad de cambio (procedimientos encapsulados en package).

## Oleadas recomendadas
1. Oleada 1 (bajo riesgo): procesos con nombre `P_PAQUETE.PROCEDIMIENTO.sql` y sin dependencias complejas.
2. Oleada 2 (riesgo medio): wrappers como `OPERACIONES_DIARIAS.sql`, `COSTOS.sql`, `EXTRACTO.sql`.
3. Oleada 3 (alto impacto): cierres/aperturas y procesos de control global (`INICIO_*`, `FIN_*`, limpieza masiva).

## Checklist tecnico por proceso DB
1. Localizar package spec/body real del procedimiento invocado.
2. Verificar firma con `P_TX IN NUMBER DEFAULT NULL`.
3. Incluir variables de trazabilidad: `N_ID_PROCESO`, `N_TX`, `TS_INICIO`.
4. Registrar trazas `I`, `F`, `E` con `P_TRAZA_CORE.PR_REGISTRAR_TRAZA`.
5. Propagar `N_TX` a subllamados.
6. Validar `EXCEPTION WHEN OTHERS` con contexto (`SQLERRM`, `FORMAT_ERROR_BACKTRACE`).
7. Actualizar columna `estado_traza` y evidencia en `observacion`.

## Gobierno de cambios
- Limite por lote: maximo 5 procesos por PR.
- Evidencia minima por proceso: script afectado, package/body modificado, resultado de prueba.
- Rollback: conservar scripts de despliegue reversibles por paquete.

## Nota
Los scripts `FTP_*.sh` deben quedar inventariados para dependencia de secuencia, pero no llevan `P_TRAZA_CORE` dentro de PL/SQL.
