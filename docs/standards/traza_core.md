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