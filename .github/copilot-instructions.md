## Estandares generales Oracle/PLSQL
## Objetivo

Definir reglas claras, accionables y consistentes para que Copilot genere o modifique codigo PL/SQL con trazabilidad, calidad tecnica y alineacion a estandares del equipo.

## Modo de aplicacion

- MUST: regla obligatoria. Se debe cumplir siempre.
- SHOULD: recomendacion fuerte. Solo se omite si existe una justificacion tecnica valida.
- MAY: opcional.

Si hay conflicto entre reglas, aplicar este orden:
1. Instruccion corporativa vigente.
2. Requerimiento funcional del usuario.
3. Este documento.

## 1 Convenciones de nomenclatura

MUST:
- Paquetes: `P_NOMBRE`
- Procedimientos: `PR_NOMBRE`
- Funciones: `FN_NOMBRE`
- Cursores: `C_NOMBRE`
- Vistas: `VW_NOMBRE`
- Tablas globales: `GL_...`
- Tablas temporales: `TMP_...`
- Secuencias de PK: `SHORTTABLA_SEQ`
- PK: `SHORTTABLA_PK`
- FK: `SHORTHIJA_SHORTPADRE_FK`
- Indice FK: `SHORTHIJA_SHORTPADRE_FK_I`

## 2 Reglas de implementacion PL/SQL

MUST:
- Toda funcion/procedimiento debe estar dentro de un package.
- Todo codigo nuevo debe incluir comentario breve del objetivo (package, procedimiento o funcion).
- Eliminar codigo muerto. No dejar logica comentada.
- Mensajes al usuario en formato oracion, claros y accionables.
- No usar `SELECT *`. Listar columnas explicitas.
- Usar notacion nombrada al invocar parametros: `P_PARAM => VALOR`.
- Usar `%TYPE` cuando aplique definicion por modelo.
- Cerrar bloques con nombre explicito: `END PR_...;`, `END FN_...;`, `END P_...;`.

## 3 Manejo de errores y validaciones

MUST:
- Todo bloque de negocio debe tener `EXCEPTION WHEN OTHERS` preservando contexto del error.
- Todo procedimiento/funcion nuevo o modificado debe implementar trazabilidad con `P_TRAZA_CORE`.
- Triggers orientados a validacion, no a logica de negocio (salvo excepciones aprobadas).

## 4 Modelado de datos (cuando aplique)

MUST:
- Toda tabla permanente debe tener llave primaria.
- PK consecutiva con `NUMBER(10)` y nombre `SHORTTABLA_CONSECUTIVO`.
- Crear comentarios de columnas con descripcion funcional y valores permitidos cuando existan.
- Evitar `DEFAULT` en columnas. Definir valores en logica de negocio.
- Crear indices para FK y para columnas de fecha.

## 5 Entregables y mantenimiento

MUST:
- Mantener estructura de archivos de package en spec/body.
- Documentar entradas/salidas y descripcion breve en el diccionario de funcionalidades cuando se cree o modifique funcionalidad.
- Mantener coherencia con tablespaces, sinonimos y grants definidos por arquitectura.

## 6 Convencion de variables (PL/SQL)

### 6.1 Regla general

MUST:
- Toda variable inicia con prefijo por tipo semantico.
- Nombres en mayusculas con separador `_`.

### 6.2 Prefijos obligatorios

- `P_`: parametros de entrada/salida. Ej: `P_CLIENTE_ID`, `P_TX`.
- `N_`: variables numericas. Ej: `N_TOTAL_REGISTROS`, `N_ID_PROCESO`.
- `V_`: variables de texto. Ej: `V_MENSAJE`, `V_ESTADO`.
- `D_`: variables fecha. Ej: `D_FECHA_CORTE`.
- `TS_`: variables timestamp. Ej: `TS_INICIO`, `TS_FIN`.
- `B_`: variables booleanas. Ej: `B_EXISTE`, `B_PROCESADO`.
- `R_`: registros `%ROWTYPE`. Ej: `R_CLIENTE`.
- `T_`: colecciones/tablas PL/SQL. Ej: `T_CLIENTES`.
- `C_`: constantes. Ej: `C_ESTADO_ACTIVO`.
- `E_`: excepciones de negocio. Ej: `E_DATOS_INVALIDOS`.
- `G_`: variables globales de package body. Ej: `G_CACHE_ACTIVO`.

### 6.3 Reglas de declaracion

MUST:
- Declarar en el menor alcance posible.
- Evitar nombres genericos (`V1`, `X`, `TMP`, `AUX`).
- No reutilizar una variable para responsabilidades diferentes en el mismo bloque.
- Eliminar variables sin uso.
- Usar nombres compuestos funcionales de negocio. Ej: `N_SALDO_DISPONIBLE`, `V_CODIGO_RESPUESTA`.

### 6.4 Reglas de tipado

MUST:
- Preferir `%TYPE` para campos asociados a columnas.
- Usar `%ROWTYPE` para registros de fila completa.
- Usar `NUMBER(p,s)` para montos y datos de negocio persistidos.

SHOULD:
- Usar `PLS_INTEGER` para contadores e indices internos.

MUST NOT:
- Usar `VARCHAR2(4000)` por defecto. Definir longitud segun dominio.

### 6.5 Orden recomendado en la seccion declarativa

1. Cursores (`C_...`).
2. Registros (`R_...`).
3. Colecciones (`T_...`).
4. Constantes (`C_...`).
5. Variables escalares (`N_`, `V_`, `D_`, `TS_`, `B_`).
6. Variables de trazabilidad (`N_ID_PROCESO`, `N_TX`, `TS_INICIO`).
7. Excepciones (`E_...`).

### 6.6 Plantilla sugerida

```sql
PROCEDURE PR_EJEMPLO(
    P_CLIENTE_ID IN CLIENTES.CLIENTE_ID%TYPE,
    P_TX         IN NUMBER DEFAULT NULL
) IS
    C_ESTADO_ACTIVO CONSTANT VARCHAR2(1) := 'A';

    N_ID_PROCESO NUMBER;
    N_TX         NUMBER;
    TS_INICIO    TIMESTAMP := SYSTIMESTAMP;

    N_TOTAL      NUMBER(12,2);
    V_MENSAJE    VARCHAR2(500);
    B_EXISTE     BOOLEAN := FALSE;

    R_CLIENTE    CLIENTES%ROWTYPE;

    E_NEGOCIO EXCEPTION;
BEGIN
    NULL;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END PR_EJEMPLO;
```
## 7) Constraints

MUST:
- PK: `SHORTtabla_PK`.
- FK: `SHORTtablahija_SHORTtablapapa_FK`.
- UK: `SHORTtabla_NOMBRE_UK`.
- Validar que columnas heredadas conserven misma definicion y orden de la PK de la tabla padre.
- Para otros constraints usar: `AVCON_SHORTtabla_PRIMERALETRACOLUMNA_00X`, con consecutivo desde `000`.

## 8) Indices

MUST:
- Toda FK debe tener indice `SHORTtablahija_SHORTtablapapa_FK_I`.
- Para indices no FK usar `SHORTtabla_NOMBRE_I`.
- Crear indices en `INDICES_COEASY`, excepto para objetos de `MOVIMIENTOS_CUENTAS_FONDOS` y `ORDENES_FONDOS`, que van en `INDICES_MVTOS_FONDOS`.
- Crear siempre indice para columnas de fecha.

SHOULD:
- Verificar que columnas heredadas conserven misma definicion y orden de la PK de la tabla padre.


## 1) Trazabilidad obligatoria con P_TRAZA_CORE

### 1.1 Alcance

MUST: Todo procedimiento o funcion nuevo/modificado debe implementar trazas con `P_TRAZA_CORE`.

### 1.2 Componentes clave

- `FN_ID_PROCESO`: obtiene el ID del proceso parametrizado.
- `FN_TRAE_TX`: conserva o genera el consecutivo de transaccion.
- `PR_REGISTRAR_TRAZA`: registra trazas en transaccion autonoma.
- `FN_DURACION_MS`: calcula la duracion en milisegundos.

### 1.3 Firma estandar

MUST: incluir parametro de transaccion para propagar contexto.

```sql
PROCEDURE PR_NOMBRE_PROCEDIMIENTO(
    -- Otros parametros
    P_TX IN NUMBER DEFAULT NULL
);
```

### 1.4 Variables locales obligatorias

MUST: declarar al menos estas variables en el bloque declarativo.

```sql
N_ID_PROCESO NUMBER;
N_TX         NUMBER;
TS_INICIO    TIMESTAMP := SYSTIMESTAMP;
```

### 1.5 Inicializacion obligatoria

MUST: inicializar proceso y transaccion al inicio del `BEGIN`.

```sql
N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('PAQUETE.PR_PROCEDIMIENTO');
N_TX         := P_TRAZA_CORE.FN_TRAE_TX(P_TX);
```

### 1.6 Tipos de traza

MUST: registrar trazas en estos momentos:
- `I` (Inicio): inmediatamente despues de inicializar `N_TX`.
- `F` (Fin): antes del `END` o `RETURN` exitoso, con duracion.
- `E` (Error): dentro de `EXCEPTION WHEN OTHERS`.

MAY: usar `T` para hitos intermedios cuando la logica lo requiera.

### 1.7 Plantilla base

```sql
PROCEDURE PR_EJEMPLO_ESTANDAR(P_TX IN NUMBER DEFAULT NULL) IS
    N_ID_PROCESO NUMBER;
    N_TX         NUMBER;
    TS_INICIO    TIMESTAMP := SYSTIMESTAMP;
BEGIN
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('NOMBRE_PAQUETE.PR_EJEMPLO_ESTANDAR');
    N_TX         := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(
        P_ID             => N_ID_PROCESO,
        P_TIPO_EJECUCION => 'I',
        P_MENSAJE        => 'INICIO del proceso PR_EJEMPLO_ESTANDAR.',
        P_TX             => N_TX
    );

    -- Logica de negocio

    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(
        P_ID             => N_ID_PROCESO,
        P_TIPO_EJECUCION => 'F',
        P_MENSAJE        => 'FIN del proceso PR_EJEMPLO_ESTANDAR finalizado correctamente.',
        P_TX             => N_TX,
        P_DURACION_MS    => P_TRAZA_CORE.FN_DURACION_MS(TS_INICIO)
    );

EXCEPTION
    WHEN OTHERS THEN
        P_TRAZA_CORE.PR_REGISTRAR_TRAZA(
            P_ID             => N_ID_PROCESO,
            P_TIPO_EJECUCION => 'E',
            P_MENSAJE        => 'ERROR en PR_EJEMPLO_ESTANDAR. SQLERRM: ' || SQLERRM ||
                                ' - BACKTRACE: ' || SYS.DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            P_TX             => N_TX,
            P_DURACION_MS    => P_TRAZA_CORE.FN_DURACION_MS(TS_INICIO)
        );
        RAISE;
END PR_EJEMPLO_ESTANDAR;
```

### 1.8 Reglas complementarias de trazas

- MUST: propagar `N_TX` en llamados a subprocedimientos.
- Info: `PR_REGISTRAR_TRAZA` usa `PRAGMA AUTONOMOUS_TRANSACTION`.
- Info: si no existe proceso parametrizado, el sistema registra `DESCONOCIDO` segun logica interna.