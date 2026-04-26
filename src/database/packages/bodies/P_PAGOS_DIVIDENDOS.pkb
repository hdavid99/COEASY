--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_PAGOS_DIVIDENDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_PAGOS_DIVIDENDOS" IS

/**********************************************************************************
***  Procedimiento de Inserta errores en la tabla ERRORES_PROCESOS_DIVIDENDOS    **
******************************************************************************** */
  -- ----------------------------------------------------------------------- --
  -- -20/11/2017.Modificacion:Se agrega seguimiento para el proceso nocturno.
  -- ----------------------------------------------------------------------- --
PROCEDURE INSERTA_ERROR_DIV
   (P_PROCESO         ERRORES_PROCESOS_DIVIDENDOS.EPD_PROCESO%TYPE
   ,P_ERROR           ERRORES_PROCESOS_DIVIDENDOS.EPD_ERROR%TYPE
   ,P_TABLA_ERROR     ERRORES_PROCESOS_DIVIDENDOS.EPD_TABLA%TYPE) IS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
   INSERT INTO ERRORES_PROCESOS_DIVIDENDOS
      (EPD_CONSECUTIVO
      ,EPD_FECHA_ERROR
      ,EPD_PROCESO
      ,EPD_ERROR
      ,EPD_TABLA)
   VALUES
      (EPD_SEQ.NEXTVAL
      ,SYSDATE
      ,SUBSTR(P_PROCESO,1,200)
      ,substr(P_ERROR,1,500)
      ,SUBSTR(P_TABLA_ERROR,1,500));
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,SQLERRM);
END INSERTA_ERROR_DIV;

--------------------------------------------------------------------------------
PROCEDURE ObtenerInstPagoDividendos
   (P_TID_CODIGO    VARCHAR2  DEFAULT NULL
   ,P_NUM_IDEN      VARCHAR2 DEFAULT NULL
   ,P_NUMERO_CUENTA NUMBER DEFAULT NULL
   ,P_CONSECUTIVO   NUMBER DEFAULT NULL
   ,io_cursor       IN OUT O_CURSOR) IS
BEGIN
   OPEN IO_CURSOR FOR
      SELECT IPD_CONSECUTIVO,
             IPD_CCC_CLI_PER_NUM_IDEN,
             IPD_CCC_CLI_PER_TID_CODIGO,
             IPD_CCC_NUMERO_CUENTA,
             DECODE(IPD_ABONO_CUENTA,'S','AC',DECODE(IPD_TRASLADO_FONDOS,'S','TF',DECODE(IPD_PAGO,'S','P'))) AS IPD_TIPO_DESTINO_PAGO,
             IPD_SUC_CODIGO,
             DECODE(NVL(IPD_PAGAR_A,'C'),'C','S','T','N') IPD_ES_CLIENTE,
             IPD_A_NOMBRE_DE,
             IPD_BAN_CODIGO,
             IPD_NUM_CUENTA_CONSIGNAR,
             IPD_TCB_MNEMONICO,
             IPD_CFO_FON_CODIGO,
             IPD_CFO_CODIGO,
             IPD_NUM_IDEN_ACH,
             IPD_TID_CODIGO_ACH,
             IPD_TIPO_ORIGEN_PAGO ,
             IPD_PAGAR_A,
             IPD_MONTO_MINIMO IPD_MONTO
      FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE  ((IPD_CCC_CLI_PER_NUM_IDEN = P_NUM_IDEN
      AND      IPD_CCC_NUMERO_CUENTA = DECODE(P_NUMERO_CUENTA,-1,IPD_CCC_NUMERO_CUENTA,P_NUMERO_CUENTA))
      OR       IPD_CONSECUTIVO = P_CONSECUTIVO)
      AND    IPD_VISADO = 'S';
END ObtenerInstPagoDividendos;

--------------------------------------------------------------------------------

PROCEDURE InsertarInstPagoDividendos
   (P_CLI_PER_NUM_IDEN                VARCHAR2,
    P_CLI_PER_TID_CODIGO              VARCHAR2,
    P_CCC_NUMERO_CUENTA               NUMBER,
    P_TIPO_DESTINO_PAGO               VARCHAR2, --AC:Abono Cuenta, TF:Traslado Fondos, P: Pago
    P_SUC_CODIGO                      NUMBER,
    P_ES_CLIENTE                      VARCHAR2,
    P_NUM_IDEN                        VARCHAR2,
    P_TID_CODIGO                      VARCHAR2,
    P_NOMBRE                          VARCHAR2,
    P_BAN_CODIGO                      NUMBER,
    P_NUM_CUENTA_CONSIGNAR            VARCHAR2,
    P_TCB_MNEMONICO                   VARCHAR2,
    P_CFO_CCC_NUMERO_CUENTA           NUMBER,
    P_CFO_FON_CODIGO                  VARCHAR2,
    P_CFO_CODIGO                      NUMBER,
    P_USUARIO           		      VARCHAR2,
    P_TERMINAL           		      VARCHAR2,
    P_MEDIO_RECEPCION                 VARCHAR2,
    P_DETALLE_MEDIO_RECEPCION         VARCHAR2,
    P_TIPO_ORIGEN_PAGO                VARCHAR2,
    P_PAGAR_A                         VARCHAR2,
    P_MONTO                           NUMBER,
    P_FECHA_INICIO                    VARCHAR2,
    P_FECHA_FIN                       VARCHAR2,
    P_DIA_EJECUCION                   VARCHAR2,
    P_PERIODO                         VARCHAR2,
    P_CONSECUTIVO                     IN OUT NUMBER)
IS
   P_MONTO_MINIMO  NUMBER;
   V_EXISTE NUMBER(10) := 0;
   P_TAC_MNEMONICO VARCHAR2(5);

BEGIN
   SELECT COUNT(IPD_CCC_CLI_PER_NUM_IDEN)
   INTO   V_EXISTE
   FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
   WHERE  IPD_CONSECUTIVO = P_CONSECUTIVO;

   DELETE FROM INST_PAGOS_DIVIDENDOS_DETALLES
   WHERE IDD_IPD_CONSECUTIVO = P_CONSECUTIVO;

   IF P_TIPO_DESTINO_PAGO = 'TF' THEN
      SELECT TAC_MNEMONICO INTO P_TAC_MNEMONICO FROM TIPOS_ABONOS_CUENTAS
      WHERE  TAC_PRO_MNEMONICO IN (SELECT FON_NPR_PRO_MNEMONICO
                                   FROM   FONDOS
                                   WHERE  FON_CODIGO = P_CFO_FON_CODIGO)
      AND ROWNUM <= 1;
   ELSE
      P_TAC_MNEMONICO := NULL;
   END IF;

   IF V_EXISTE = 0 THEN
				SELECT IPD_SEQ.NEXTVAL INTO P_CONSECUTIVO FROM DUAL;

        INSERT INTO INSTRUCCIONES_PAGOS_DIVIDENDOS
           (IPD_CONSECUTIVO,
            IPD_CCC_CLI_PER_NUM_IDEN,
            IPD_CCC_CLI_PER_TID_CODIGO,
            IPD_CCC_NUMERO_CUENTA,
            IPD_ABONO_CUENTA,
            IPD_TRASLADO_FONDOS,
            IPD_PAGO,
            IPD_SUC_CODIGO,
            IPD_TPA_MNEMONICO,
            IPD_ES_CLIENTE,
            IPD_A_NOMBRE_DE,
            IPD_CONSIGNAR,
            IPD_ENTREGAR_RECOGE,
            IPD_ENVIA_FAX,
            IPD_CRUCE_CHEQUE,
            IPD_PER_NUM_IDEN,
            IPD_PER_TID_CODIGO,
            IPD_PAGAR_A,
            IPD_BAN_CODIGO,
            IPD_NUM_CUENTA_CONSIGNAR,
            IPD_TCB_MNEMONICO,
            IPD_DIRECCION_ENVIO_CHEQUE,
            IPD_AGE_CODIGO,
            IPD_PREGUNTAR_POR,
            IPD_FAX,
            IPD_OCL_CLI_PER_NUM_IDEN_RELAC,--1 ?
            IPD_OCL_CLI_PER_TID_CODIGO_REL,--2 ?
            IPD_CCC_CLI_PER_NUM_IDEN_TRANS,--3 ?
            IPD_CCC_CLI_PER_TID_CODIGO_TRA,--4 ?
            IPD_CCC_NUMERO_CUENTA_TRANSF,--5 ?
            IPD_CFO_CCC_NUMERO_CUENTA,--6 ?
            IPD_CFO_FON_CODIGO,
            IPD_CFO_CODIGO,
            IPD_TAC_MNEMONICO,
            IPD_MAS_INSTRUCCIONES,
            IPD_NUM_IDEN,
            IPD_TID_CODIGO,
            IPD_FECHA_REGISTRO,
            IPD_USUARIO_REGISTRO,
            IPD_TERMINAL_REGISTRO,
            IPD_FECHA_MODIFICACION,
            IPD_USUARIO_MODIFICACION,
            IPD_TERMINAL_MODIFICACION,
            IPD_NUM_IDEN_ACH,
            IPD_TID_CODIGO_ACH,
            IPD_NOMBRE_ACH,
            IPD_FAX_ACH,
            IPD_EMAIL,
            IPD_MEDIO_RECEPCION,
            IPD_DETALLE_MEDIO_RECEPCION,
            IPD_FECHA_RECEPCION,
            IPD_HORA_RECEPCION,
            IPD_DIGITO_CONTROL,--7 ?
            IPD_NUMERO_RADICACION,
            IPD_VISADO,
            IPD_TIPO_ORIGEN_PAGO,
            IPD_MONTO_MINIMO
            )
        VALUES
           (P_CONSECUTIVO,
            P_CLI_PER_NUM_IDEN,
            P_CLI_PER_TID_CODIGO,
            P_CCC_NUMERO_CUENTA,
            DECODE(P_TIPO_DESTINO_PAGO,'AC','S','N'),
            DECODE(P_TIPO_DESTINO_PAGO,'TF','S','N'),
            DECODE(P_TIPO_DESTINO_PAGO,'P','S','N'),
            P_SUC_CODIGO,
            DECODE(P_TIPO_DESTINO_PAGO,'P','ACH',NULL),
            'S',--Todos los pagos son a clientes 'S' pero pueden tener como beneficiario un tercero
            DECODE(P_TIPO_DESTINO_PAGO,'P',P_NOMBRE,NULL),
            'N',
            'R',
            'N',
            'RP',
            NULL,
            NULL,
            P_PAGAR_A,--DECODE(NVL(P_ES_CLIENTE,'S'),'S','C','N','T'),--TODO:Crear una nueva variable para determinar si el pago va dirigido a un tercero
            P_BAN_CODIGO,
            P_NUM_CUENTA_CONSIGNAR,
            P_TCB_MNEMONICO,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,--1
            NULL,--2
            NULL,--3
            NULL,--4
            NULL,--5
            P_CFO_CCC_NUMERO_CUENTA,--6
            P_CFO_FON_CODIGO,
            P_CFO_CODIGO,
            P_TAC_MNEMONICO,
            NULL,
            NULL,
            NULL,
            SYSDATE,
            P_USUARIO,
            P_TERMINAL,
            NULL,
            NULL,
            NULL,
            DECODE(P_TIPO_DESTINO_PAGO,'P',P_NUM_IDEN,NULL),
            DECODE(P_TIPO_DESTINO_PAGO,'P',P_TID_CODIGO,NULL),
            DECODE(P_TIPO_DESTINO_PAGO,'P',P_NOMBRE,NULL),
            NULL,
            NULL,
            P_MEDIO_RECEPCION,
            P_DETALLE_MEDIO_RECEPCION,
            SYSDATE,
            NULL,
            NULL,-- 7
            'Corredores en Linea',
            'S',
            P_TIPO_ORIGEN_PAGO,
            P_MONTO
           );
   ELSE
      UPDATE INSTRUCCIONES_PAGOS_DIVIDENDOS
      SET    IPD_CONSECUTIVO = P_CONSECUTIVO,
             IPD_ABONO_CUENTA =  DECODE(P_TIPO_DESTINO_PAGO,'AC','S','N'),
             IPD_TRASLADO_FONDOS = DECODE(P_TIPO_DESTINO_PAGO,'TF','S','N'),
             IPD_PAGO = DECODE(P_TIPO_DESTINO_PAGO,'P','S','N'),
             IPD_SUC_CODIGO = P_SUC_CODIGO,
             IPD_TPA_MNEMONICO = DECODE(P_TIPO_DESTINO_PAGO,'P','ACH',NULL),
             IPD_ES_CLIENTE = 'S',--Todos los pagos son a clientes 'S' pero pueden tener como beneficiario un tercero
             IPD_A_NOMBRE_DE = P_NOMBRE,
             IPD_PAGAR_A = P_PAGAR_A,--IPD_PAGAR_A = DECODE(NVL(P_ES_CLIENTE,'S'),'S','C','N','T'),--TODO:Crear una nueva variable para determinar si el pago va dirigido a un tercero
             IPD_BAN_CODIGO = P_BAN_CODIGO,
             IPD_NUM_CUENTA_CONSIGNAR = P_NUM_CUENTA_CONSIGNAR,
             IPD_TCB_MNEMONICO = P_TCB_MNEMONICO,
             IPD_CFO_FON_CODIGO = P_CFO_FON_CODIGO,
             IPD_CFO_CODIGO = P_CFO_CODIGO,
             IPD_TAC_MNEMONICO = P_TAC_MNEMONICO,
             IPD_FECHA_MODIFICACION = SYSDATE,
             IPD_USUARIO_MODIFICACION = P_USUARIO,
             IPD_TERMINAL_MODIFICACION = P_TERMINAL,
             IPD_NUM_IDEN_ACH = P_NUM_IDEN,
             IPD_TID_CODIGO_ACH = P_TID_CODIGO,
             IPD_NOMBRE_ACH = P_NOMBRE,
             IPD_MEDIO_RECEPCION = P_MEDIO_RECEPCION,
             IPD_DETALLE_MEDIO_RECEPCION = P_DETALLE_MEDIO_RECEPCION,
             IPD_TIPO_ORIGEN_PAGO = P_TIPO_ORIGEN_PAGO,
             IPD_NUMERO_RADICACION = 'Corredores en Linea',
             IPD_VISADO = 'S',
             IPD_MONTO_MINIMO = P_MONTO
      WHERE IPD_CONSECUTIVO = P_CONSECUTIVO;
   END IF;

   COMMIT;
END InsertarInstPagoDividendos;

--------------------------------------------------------------------------------

PROCEDURE InsertarInstPagoDividendoDet
   (P_CLI_PER_NUM_IDEN                VARCHAR2,
    P_CLI_PER_TID_CODIGO              VARCHAR2,
    P_CCC_NUMERO_CUENTA               NUMBER,
    P_ENA_MNEMONICO                   VARCHAR2,
    P_CONSECUTIVO                     NUMBER)
IS
BEGIN
   INSERT INTO INST_PAGOS_DIVIDENDOS_DETALLES
      (IDD_CONSECUTIVO,
       IDD_CCC_CLI_PER_NUM_IDEN,
       IDD_CCC_CLI_PER_TID_CODIGO,
       IDD_CCC_NUMERO_CUENTA,
       IDD_ENA_MNEMONICO,
       IDD_IPD_CONSECUTIVO)
   VALUES
      (IDD_SEQ.NEXTVAL,
       P_CLI_PER_NUM_IDEN,
       P_CLI_PER_TID_CODIGO,
       P_CCC_NUMERO_CUENTA,
       P_ENA_MNEMONICO,
       P_CONSECUTIVO);

END InsertarInstPagoDividendoDet ;
--------------------------------------------------------------------------------

PROCEDURE ObtenerInstPagoDividendoDet
   (P_CONSECUTIVO                     NUMBER,
    io_cursor  IN OUT O_CURSOR)
IS
BEGIN
   OPEN IO_CURSOR FOR
   SELECT IDD_CONSECUTIVO,
          IDD_CCC_CLI_PER_NUM_IDEN,
          IDD_CCC_CLI_PER_TID_CODIGO,
          IDD_CCC_NUMERO_CUENTA,
          IDD_ENA_MNEMONICO,
          IDD_IPD_CONSECUTIVO
   FROM   INST_PAGOS_DIVIDENDOS_DETALLES
   WHERE  IDD_IPD_CONSECUTIVO = P_CONSECUTIVO;
END ObtenerInstPagoDividendoDet;
--------------------------------------------------------------------------------

PROCEDURE InactivarInstPagoDividendo
   (P_CONSECUTIVO                     NUMBER)
IS
BEGIN
  DELETE FROM INST_PAGOS_DIVIDENDOS_DETALLES
  WHERE  IDD_IPD_CONSECUTIVO = P_CONSECUTIVO;

  COMMIT;

   DELETE FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
   WHERE  IPD_CONSECUTIVO = P_CONSECUTIVO;

  COMMIT;
END InactivarInstPagoDividendo;

--------------------------------------------------------------------------------

PROCEDURE PROCESO_NOCTURNO  IS

	 CURSOR INSTRUCCIONES IS
      SELECT IPD_CONSECUTIVO,
             IPD_CCC_CLI_PER_NUM_IDEN,
             IPD_CCC_CLI_PER_TID_CODIGO,
             IPD_CCC_NUMERO_CUENTA,
             IPD_TIPO_ORIGEN_PAGO,
             IPD_TIPO_EMISOR,
             IPD_MONTO_MINIMO,
             IPD_ABONO_CUENTA,
             IPD_TRASLADO_FONDOS,
             IPD_PAGO,
             IPD_SUC_CODIGO,
             IPD_TPA_MNEMONICO,
             IPD_ES_CLIENTE,
             IPD_A_NOMBRE_DE,
             IPD_CONSIGNAR,
             IPD_ENTREGAR_RECOGE,
             IPD_ENVIA_FAX,
             IPD_CRUCE_CHEQUE,
             IPD_PER_NUM_IDEN,
             IPD_PER_TID_CODIGO,
             IPD_PAGAR_A,
             IPD_BAN_CODIGO,
             IPD_NUM_CUENTA_CONSIGNAR,
             IPD_TCB_MNEMONICO,
             IPD_DIRECCION_ENVIO_CHEQUE,
             IPD_AGE_CODIGO,
             IPD_PREGUNTAR_POR,
             IPD_FAX,
             IPD_OCL_CLI_PER_NUM_IDEN_RELAC,
             IPD_OCL_CLI_PER_TID_CODIGO_REL,
             IPD_CCC_CLI_PER_NUM_IDEN_TRANS,
             IPD_CCC_CLI_PER_TID_CODIGO_TRA,
             IPD_CCC_NUMERO_CUENTA_TRANSF,
             IPD_CFO_CCC_NUMERO_CUENTA,
             IPD_CFO_FON_CODIGO,
             IPD_CFO_CODIGO,
             IPD_TAC_MNEMONICO,
             IPD_MAS_INSTRUCCIONES,
             IPD_NUM_IDEN,
             IPD_TID_CODIGO,
             IPD_FECHA_REGISTRO,
             IPD_USUARIO_REGISTRO,
             IPD_TERMINAL_REGISTRO,
             IPD_FECHA_MODIFICACION,
             IPD_USUARIO_MODIFICACION,
             IPD_TERMINAL_MODIFICACION,
             IPD_NUM_IDEN_ACH,
             IPD_TID_CODIGO_ACH,
             IPD_DIGITO_CONTROL,
             IPD_NOMBRE_ACH,
             IPD_FAX_ACH,
             IPD_EMAIL,
             IPD_MEDIO_RECEPCION,
             IPD_DETALLE_MEDIO_RECEPCION,
             IPD_FECHA_RECEPCION,
             IPD_HORA_RECEPCION,
             IPD_NUMERO_RADICACION,
             IPD_VISADO,
             IPD_FIC_CODIGO_BOLSA,
             IPD_FIC_PER_TID_CODIGO,
             IPD_FIC_PER_NUM_IDEN,
             IPD_GIRO_OTRA_CIUDAD
      FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE  IPD_VISADO = 'S'
      AND    IPD_ESTADO = 'A'
      AND    NVL(IPD_INSTRUCCION_POD,'N') != 'S'
      AND    ((IPD_TIPO_ORIGEN_PAGO = 'SB'
               AND EXISTS (SELECT 'X'
                          FROM CUENTAS_CLIENTE_CORREDORES
                          WHERE CCC_CLI_PER_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
                            AND CCC_CLI_PER_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
                            AND CCC_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
                            AND CCC_SALDO_BURSATIL > 0))
              OR
               (IPD_TIPO_ORIGEN_PAGO = 'SD'
                AND EXISTS (SELECT 'X'
                          FROM CUENTAS_CLIENTE_CORREDORES
                          WHERE CCC_CLI_PER_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
                            AND CCC_CLI_PER_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
                            AND CCC_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
                            AND CCC_SALDO_ADMON_VALORES > 0))
                OR (EXISTS (SELECT 'X'
                           FROM MOVIMIENTOS_CUENTA_CORREDORES
                           WHERE MCC_CCC_CLI_PER_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
                             AND MCC_CCC_CLI_PER_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
                             AND MCC_CCC_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
                             AND MCC_FECHA >= TRUNC(SYSDATE)
                             AND MCC_MONTO_ADMON_VALORES != 0
                             AND EXISTS (SELECT 'X'
                                         FROM CUENTAS_CLIENTE_CORREDORES
                                         WHERE CCC_CLI_PER_NUM_IDEN = MCC_CCC_CLI_PER_NUM_IDEN
                                           AND CCC_CLI_PER_TID_CODIGO = MCC_CCC_CLI_PER_TID_CODIGO
                                           AND CCC_NUMERO_CUENTA = MCC_CCC_NUMERO_CUENTA
                                           AND CCC_SALDO_ADMON_VALORES = 0))))
      ORDER BY IPD_CONSECUTIVO;

   CURSOR C_CUENTA
      (P_CLI_PER_NUM_IDEN    VARCHAR2
      ,P_CLI_PER_TID_CODIGO  VARCHAR2
      ,P_NUMERO_CUENTA       VARCHAR2) IS
      SELECT CCC_PER_NUM_IDEN
            ,CCC_PER_TID_CODIGO
            ,CCC_SALDO_ADMON_VALORES
            ,PER_SUC_CODIGO
            ,PER_NOMBRE_USUARIO
      FROM   CUENTAS_CLIENTE_CORREDORES
            ,PERSONAS
      WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
      AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
      AND    CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
      AND    CCC_PER_NUM_IDEN = PER_NUM_IDEN
      AND    CCC_PER_TID_CODIGO = PER_TID_CODIGO;
   CCC1   C_CUENTA%ROWTYPE;

   CURSOR CONSTANTE(P_CON_MNEMONICO VARCHAR2) is
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = P_CON_MNEMONICO;

   CURSOR C_PAGOS_COL (P_CLI_NUM_IDEN VARCHAR2, P_CLI_TID_CODIGO VARCHAR2, P_CUENTA NUMBER) IS
      SELECT 'S'
      FROM   ORDENES_DE_PAGO
      WHERE  ODP_NPR_PRO_MNEMONICO = 'ADVAL'
      AND    ODP_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    ODP_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    ODP_CCC_NUMERO_CUENTA = P_CUENTA
      AND    ODP_ESTADO IN ('COL','APR')
      AND    ODP_FECHA_EJECUCION >= TRUNC(SYSDATE-30)
      AND    ODP_CEG_CONSECUTIVO IS NULL
      AND    ODP_CGE_CONSECUTIVO IS NULL
      AND    ODP_TBC_CONSECUTIVO IS NULL
      AND    ODP_TCC_CONSECUTIVO IS NULL
      AND    NVL(ODP_ORDEN_MANUAL,'N') = 'N'
      AND    ODP_TERMINAL_VERIFICA != 'NOCTURNO';

   ODP1   C_PAGOS_COL%ROWTYPE;

   V_MCC_MONTO_AV              NUMBER := 0;
   V_CCC_SALDO_AV              NUMBER := 0;
   V_SALDO_ADMON_VALORES       NUMBER := 0;
   V_SALDO_BURSATIL            NUMBER := 0;
   V_SALDO_DIVIDENDOS          NUMBER := 0;
   V_MONTO_PAGO                NUMBER := 0;
   V_DIA_HABIL                 DATE := NULL;
   FECHA                       DATE;
   V_GIRO_PARCIAL              NUMBER := 0;
   COND                        VARCHAR2(1) := 'N';
   CREAR_PAGO                  VARCHAR2(1) := 'N';
   V_FONDO_COMPARTIMENTO       VARCHAR2(100);
   V_SALARIO_MINIMO            NUMBER;
   TOTAL_ODP                   NUMBER;
   R_INSTRUCCION               INSTRUCCIONES_PAGOS_DIVIDENDOS%ROWTYPE;
   BASE                        FONDOS.FON_BMO_MNEMONICO%TYPE;
   P_CLI_PER_NUM_IDEN          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
   P_CLI_PER_TID_CODIGO        CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
   P_NUMERO_CUENTA             CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;
   P_INSTRUCCION               INSTRUCCIONES_PAGOS_DIVIDENDOS.IPD_CONSECUTIVO%TYPE;
   P_ODP_CONS                  ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
   P_ODP_SUC                   ORDENES_DE_PAGO.ODP_SUC_CODIGO%TYPE;
   P_ODP_NEG                   ORDENES_DE_PAGO.ODP_NEG_CONSECUTIVO%TYPE;
   P_OFO_CONS                  ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE;
   P_OFO_SUC                   ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE;
   P_DESCRIPCION               VARCHAR2(200);
   V_SALDO_OK                  VARCHAR2(1);
   V_TOTAL_MAX                 NUMBER;
   ERRORSQL                    VARCHAR2(100);
   EXISTE_ODP                  EXCEPTION;
   EXISTE_OFO                  EXCEPTION;
   DIF_SALDO                   EXCEPTION;
   SIN_VR_ODP                  EXCEPTION;
   SALDO_NEGATIVO              EXCEPTION;
   P_NUM_INI                   NUMBER;
   P_NUM_FIN                   NUMBER;
   V_PROCESO                   VARCHAR2(200);   -- AJUSTE VAGTUD991

BEGIN

 V_PROCESO := 'REGINI';
 P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_PAGOS_DIVIDENDOS.PROCESO_NOCTURNO','INI');

   SELECT TRUNC(SYSDATE) INTO FECHA FROM DUAL;
   V_DIA_HABIL := TRUNC(P_TOOLS.SUMAR_HABILES_A_FECHA(FECHA - 1,1));

   -- proceso genera solo para dias habiles
   IF TRUNC(V_DIA_HABIL) = TRUNC(SYSDATE) THEN
      FOR INSTRUCCIONES_REC IN INSTRUCCIONES LOOP
         BEGIN
            V_PROCESO := 'INSREC';
            SAVEPOINT SV_INSTRUCCIONES;
            P_CLI_PER_NUM_IDEN   := INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN;
            P_CLI_PER_TID_CODIGO := INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO;
            P_NUMERO_CUENTA      := INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA;
            P_INSTRUCCION        := INSTRUCCIONES_REC.IPD_CONSECUTIVO;

            IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'SD' THEN
               V_PROCESO := 'TIPO-SD-VALSAV';
               V_SALDO_OK := P_PAGOS_DIVIDENDOS.FN_VALIDA_SALDO_AV
                                                     (INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                                      ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                                      ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA);

               IF V_SALDO_OK = 'N' THEN
                  RAISE DIF_SALDO;
               END IF;
            END IF;
            IF INSTRUCCIONES_REC.IPD_PAGO = 'S' THEN
               V_PROCESO := 'PAGO-S-FN_MONTO_MAX_ODP';
               V_MONTO_PAGO := 0;
               -- VALIDA EL MONTO MAXIMO DE LA ORDEN QUE SE PUEDE COLOCAR DIARIAMENTE POR CLIENTE
               V_TOTAL_MAX :=  P_PAGOS_DIVIDENDOS.FN_MONTO_MAX_ODP ( INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                                                    ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO);
               V_TOTAL_MAX := NVL(V_TOTAL_MAX,0);
               IF V_TOTAL_MAX <= 0 THEN
                  RAISE SIN_VR_ODP;
               END IF;
               -- CREA ORDEN DE PAGO
               -- VERIFICA EL ORIGEN DEL PAGO
               IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'SB' THEN
                  V_PROCESO := 'TIPO-SB-SALOPB';
                  V_SALDO_BURSATIL := P_ADMON_SALDOS.FN_SALDOS_OPE_BURSATIL
                                         (P_CLI_NUM_IDEN      => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                         ,P_CLI_TID_CODIGO    => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                         ,P_CUENTA            => INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                                         ,P_SALDO_ODP         => TOTAL_ODP);

                  V_PROCESO := 'TIPO-SB-VALSALOPB';
                  IF V_SALDO_BURSATIL < 0 THEN
                     V_SALDO_BURSATIL := 0;
                  ELSE
                     IF V_SALDO_BURSATIL > V_TOTAL_MAX THEN
                        V_SALDO_BURSATIL := V_TOTAL_MAX;
                     END IF;
                  END IF;
                  IF V_SALDO_BURSATIL > 0 THEN
                     V_PROCESO := 'TIPO-SB-SOBMC';
                     OPEN C_CUENTA(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                  ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                  ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA);
                     FETCH C_CUENTA INTO CCC1;
                     CLOSE C_CUENTA;
                     IF INSTRUCCIONES_REC.IPD_MONTO_MINIMO > 0 THEN
                        IF INSTRUCCIONES_REC.IPD_MONTO_MINIMO <= V_SALDO_BURSATIL THEN
                           V_MONTO_PAGO := V_SALDO_BURSATIL;
                        END IF;

                        IF V_MONTO_PAGO != 0  THEN
                           --Llama el procedimiento para crear la orden de pago
                           V_PROCESO := 'TIPO-SB-OPN';
                           P_PAGOS_DIVIDENDOS.ORDEN_PAGO_NOCTURNO
                                 (INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                 ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                 ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                                 ,INSTRUCCIONES_REC.IPD_CONSECUTIVO
                                 ,INSTRUCCIONES_REC.IPD_MONTO_MINIMO
                                 ,V_DIA_HABIL
                                 ,CCC1.CCC_PER_NUM_IDEN
                                 ,CCC1.CCC_PER_TID_CODIGO
                                 ,V_MONTO_PAGO
                                 ,CCC1.PER_NOMBRE_USUARIO
                                 ,'OB'
                                 ,P_ODP_CONS
                                 ,P_ODP_SUC
                                 ,P_ODP_NEG);
                           COMMIT;
                        END IF;
                     END IF;
                  END IF;
               END IF;
               IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'SD' THEN
                  V_PROCESO := 'TIPO-SD-SALAVA';
                  V_SALDO_ADMON_VALORES := P_ADMON_SALDOS.FN_SALDO_ADMON_VALORES
                                              (P_CLI_NUM_IDEN      => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                              ,P_CLI_TID_CODIGO    => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                              ,P_CUENTA            => INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                                              ,P_SALDO_RECALCULADO => 'N'
                                              ,P_SALDO_ODP         => TOTAL_ODP);

                  V_PROCESO := 'TIPO-SD-VALSALAVA';
                  IF V_SALDO_ADMON_VALORES < 0 THEN
                     V_SALDO_ADMON_VALORES := 0;
                  ELSE
                     IF V_SALDO_ADMON_VALORES > V_TOTAL_MAX THEN
                        V_SALDO_ADMON_VALORES := V_TOTAL_MAX;
                     END IF;
                  END IF;
                  IF V_SALDO_ADMON_VALORES > 0 THEN
                     V_PROCESO := 'TIPO-SD-SAVAMC';
                     -- NO SE PERMITE CREAR LA ORDEN SI YA EXISTE OTRA ODP QUE AFECTA EL SALDO DE ADMON VALORES
                     CREAR_PAGO := 'S';
                     OPEN C_PAGOS_COL(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN,
                                      INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO,
                                      INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA);
                     FETCH C_PAGOS_COL INTO ODP1;
                     IF C_PAGOS_COL%FOUND THEN
                        CREAR_PAGO := 'N';
                        CLOSE C_PAGOS_COL; -- newLinea-VAGTUS102769
                        RAISE EXISTE_ODP;
                     END IF;
                     CLOSE C_PAGOS_COL;

                     IF CREAR_PAGO = 'S' THEN
                        OPEN C_CUENTA(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                     ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                     ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA);
                        FETCH C_CUENTA INTO CCC1;
                        CLOSE C_CUENTA;
                        IF INSTRUCCIONES_REC.IPD_MONTO_MINIMO <= V_SALDO_ADMON_VALORES THEN
                           V_MONTO_PAGO := V_SALDO_ADMON_VALORES;
                        END IF;
                        IF CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO_PAGO,0) < 0 THEN
                           CREAR_PAGO := 'N';
                           RAISE SALDO_NEGATIVO;
                        END IF;
                        IF V_MONTO_PAGO > 0 THEN
                           --Llama el procedimiento para crear la orden de pago
                           V_PROCESO := 'TIPO-SD-OPN';
                           P_PAGOS_DIVIDENDOS.ORDEN_PAGO_NOCTURNO
                                    (INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                    ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                    ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                                    ,INSTRUCCIONES_REC.IPD_CONSECUTIVO
                                    ,INSTRUCCIONES_REC.IPD_MONTO_MINIMO
                                    ,V_DIA_HABIL
                                    ,CCC1.CCC_PER_NUM_IDEN
                                    ,CCC1.CCC_PER_TID_CODIGO
                                    ,V_MONTO_PAGO
                                    ,CCC1.PER_NOMBRE_USUARIO
                                    ,'ADVAL'
                                    ,P_ODP_CONS
                                    ,P_ODP_SUC
                                    ,P_ODP_NEG);

                           IF P_ODP_CONS IS NOT NULL THEN
                           -- MARCA LOS MOVIMIENTOS COMO PAGADOS
                              V_PROCESO := 'TIPO-SD-ODPMARCA';
                              P_PAGOS_DIVIDENDOS.MARCAR_MCC_INSTRUCCION_PAGO_N
                                       ( P_IPD_CONS              => INSTRUCCIONES_REC.IPD_CONSECUTIVO
                                        ,P_TIPO_INSTRUCCION_PAGO => 'PP'
                                        ,P_SALDO                 => V_MONTO_PAGO
                                        ,P_ODP_CONS              => P_ODP_CONS
                                        ,P_ODP_SUC               => P_ODP_SUC
                                        ,P_ODP_NEG               => P_ODP_NEG);
                           END IF;
                           COMMIT;
                        END IF;
                     END IF;
                  END IF;
               END IF;
            ELSE
               IF INSTRUCCIONES_REC.IPD_TRASLADO_FONDOS = 'S' THEN
                  V_MONTO_PAGO := 0;
                  -- CREA ORDEN DE FONDOS
                  IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'SB' THEN
                     V_PROCESO := 'TFS-TIPO-SB-SOPB';
                     V_SALDO_BURSATIL := P_ADMON_SALDOS.FN_SALDOS_OPE_BURSATIL
                                            (P_CLI_NUM_IDEN      => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                            ,P_CLI_TID_CODIGO    => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                            ,P_CUENTA            => INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                                            ,P_SALDO_ODP         => TOTAL_ODP);

                     IF V_SALDO_BURSATIL > 0 THEN
                        V_PROCESO := 'TFS-SB-SOPMC';
                        OPEN C_CUENTA(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                     ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                     ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA);
                        FETCH C_CUENTA INTO CCC1;
                        CLOSE C_CUENTA;

                        V_MONTO_PAGO := V_SALDO_BURSATIL;

                        SELECT FON_BMO_MNEMONICO INTO BASE
                        FROM   FONDOS
                        WHERE  FON_CODIGO = INSTRUCCIONES_REC.IPD_CFO_FON_CODIGO;

                         --Consulta la instruccion de pago a que se hace referencia
                        V_PROCESO := 'TFS-SB-INSTR';
                        SELECT IPD_CCC_CLI_PER_NUM_IDEN
						     , IPD_CCC_CLI_PER_TID_CODIGO
							 , IPD_CCC_NUMERO_CUENTA
							 , IPD_MONTO_MINIMO
							 , IPD_ABONO_CUENTA
							 , IPD_TRASLADO_FONDOS
							 , IPD_PAGO
							 , IPD_SUC_CODIGO
							 , IPD_TPA_MNEMONICO
							 , IPD_ES_CLIENTE
							 , IPD_A_NOMBRE_DE
							 , IPD_CONSIGNAR
							 , IPD_ENTREGAR_RECOGE
							 , IPD_ENVIA_FAX
							 , IPD_CRUCE_CHEQUE
							 , IPD_SEBRA_COMPENSADO
							 , IPD_PER_NUM_IDEN
							 , IPD_PER_TID_CODIGO
							 , IPD_PAGAR_A
							 , IPD_BAN_CODIGO
							 , IPD_NUM_CUENTA_CONSIGNAR
							 , IPD_TCB_MNEMONICO
							 , IPD_DIRECCION_ENVIO_CHEQUE
							 , IPD_AGE_CODIGO
							 , IPD_PREGUNTAR_POR
							 , IPD_FAX
							 , IPD_OCL_CLI_PER_NUM_IDEN_RELAC
							 , IPD_OCL_CLI_PER_TID_CODIGO_REL
							 , IPD_CCC_CLI_PER_NUM_IDEN_TRANS
							 , IPD_CCC_CLI_PER_TID_CODIGO_TRA
							 , IPD_CCC_NUMERO_CUENTA_TRANSF
							 , IPD_CFO_CCC_NUMERO_CUENTA
							 , IPD_CFO_FON_CODIGO
							 , IPD_CFO_CODIGO
							 , IPD_TAC_MNEMONICO
							 , IPD_MAS_INSTRUCCIONES
							 , IPD_NUM_IDEN
							 , IPD_TID_CODIGO
							 , IPD_FECHA_REGISTRO
							 , IPD_USUARIO_REGISTRO
							 , IPD_TERMINAL_REGISTRO
							 , IPD_FECHA_MODIFICACION
							 , IPD_USUARIO_MODIFICACION
							 , IPD_TERMINAL_MODIFICACION
							 , IPD_NUM_IDEN_ACH
							 , IPD_TID_CODIGO_ACH
							 , IPD_DIGITO_CONTROL
							 , IPD_NOMBRE_ACH
							 , IPD_FAX_ACH
							 , IPD_EMAIL
							 , IPD_MEDIO_RECEPCION
							 , IPD_DETALLE_MEDIO_RECEPCION
							 , IPD_FECHA_RECEPCION
							 , IPD_HORA_RECEPCION
							 , IPD_NUMERO_RADICACION
							 , IPD_VISADO
							 , IPD_TIPO_ORIGEN_PAGO
							 , IPD_CONSECUTIVO
							 , IPD_FIC_CODIGO_BOLSA
							 , IPD_FIC_PER_TID_CODIGO
							 , IPD_FIC_PER_NUM_IDEN
							 , IPD_GIRO_OTRA_CIUDAD
							 , IPD_TIPO_EMISOR
							 , IPD_ESTADO
							 , IPD_INSTRUCCION_POD
							 , IPD_FECHA_INACTIVACION
							 , IPD_HORA_INACTIVACION
							 , IPD_MEDIO_INACTIVACION
							 , IPD_USUARIO_INACTIVACION
							 , IPD_TERMINAL_INACTIVACION
							 , IPD_MOTIVO_INACTIVACION
						INTO   R_INSTRUCCION
                        FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
                        WHERE  IPD_CCC_CLI_PER_NUM_IDEN = INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                        AND    IPD_CCC_CLI_PER_TID_CODIGO = INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                        AND    IPD_CCC_NUMERO_CUENTA = INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                        AND    IPD_CONSECUTIVO = INSTRUCCIONES_REC.IPD_CONSECUTIVO;

                        --Consulta el compartimento
                        V_PROCESO := 'TFS-SB-VP70';
                        P_ORDENES_FONDOS.P_VALIDA_PARAMETROS_COMP
                              (P_FON_CODIGO          => INSTRUCCIONES_REC.IPD_CFO_FON_CODIGO
                              ,P_PAR_CODIGO          =>  70
                              ,P_PFO_RANGO_MIN_CHAR  => V_FONDO_COMPARTIMENTO);

                        V_FONDO_COMPARTIMENTO := NVL(V_FONDO_COMPARTIMENTO,'N');

                        --Salario minimo
                        IF NVL(V_FONDO_COMPARTIMENTO,'N') = 'S' THEN
                           V_PROCESO := 'TFS-SB-VSAM';
                           OPEN CONSTANTE(P_CON_MNEMONICO => 'SAM');
                           FETCH CONSTANTE INTO V_SALARIO_MINIMO;
                           CLOSE CONSTANTE;
                        END IF;

                        --Llama el procedimiento para crear la orden de fondo
                        V_PROCESO := 'TFS-SB-OFN';
                        P_PAGOS_DIVIDENDOS.ORDEN_FONDO_NOCTURNO
                              (R_INSTRUCCION
                              ,CCC1.PER_SUC_CODIGO --revisar se dejo Bogota principal
                              ,V_FONDO_COMPARTIMENTO
                              ,V_SALARIO_MINIMO
                              ,BASE
                              ,V_MONTO_PAGO
                              ,CCC1.CCC_PER_NUM_IDEN
                              ,CCC1.CCC_PER_TID_CODIGO
                              ,CCC1.PER_NOMBRE_USUARIO
                              ,'OB'
                              ,P_OFO_CONS
                              ,P_OFO_SUC
                              ,P_DESCRIPCION);
                        COMMIT;
                     END IF;
                  END IF;
                  IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'SD' THEN
                     V_PROCESO := 'TFS-TIPO-SD-SAVA';
                     V_SALDO_ADMON_VALORES := P_ADMON_SALDOS.FN_SALDO_ADMON_VALORES
                                                 (P_CLI_NUM_IDEN      => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                                 ,P_CLI_TID_CODIGO    => INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                                 ,P_CUENTA            => INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                                                 ,P_SALDO_RECALCULADO => 'N'
                                                 ,P_SALDO_ODP         => TOTAL_ODP);
                     IF V_SALDO_ADMON_VALORES > 0 THEN
                        V_PROCESO := 'TFS-SD-SAVMC';
                        OPEN C_CUENTA(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                                     ,INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                                     ,INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA);
                        FETCH C_CUENTA INTO CCC1;
                        CLOSE C_CUENTA;

                        V_MONTO_PAGO := V_SALDO_ADMON_VALORES;

                        SELECT FON_BMO_MNEMONICO INTO BASE
                        FROM   FONDOS
                        WHERE  FON_CODIGO = INSTRUCCIONES_REC.IPD_CFO_FON_CODIGO;

                        --Consulta la instruccion de pago a que se hace referencia
                        V_PROCESO := 'TFS-SD-INSTR';
                        SELECT IPD_CCC_CLI_PER_NUM_IDEN
						     , IPD_CCC_CLI_PER_TID_CODIGO
							 , IPD_CCC_NUMERO_CUENTA
							 , IPD_MONTO_MINIMO
							 , IPD_ABONO_CUENTA
							 , IPD_TRASLADO_FONDOS
							 , IPD_PAGO
							 , IPD_SUC_CODIGO
							 , IPD_TPA_MNEMONICO
							 , IPD_ES_CLIENTE
							 , IPD_A_NOMBRE_DE
							 , IPD_CONSIGNAR
							 , IPD_ENTREGAR_RECOGE
							 , IPD_ENVIA_FAX
							 , IPD_CRUCE_CHEQUE
							 , IPD_SEBRA_COMPENSADO
							 , IPD_PER_NUM_IDEN
							 , IPD_PER_TID_CODIGO
							 , IPD_PAGAR_A
							 , IPD_BAN_CODIGO
							 , IPD_NUM_CUENTA_CONSIGNAR
							 , IPD_TCB_MNEMONICO
							 , IPD_DIRECCION_ENVIO_CHEQUE
							 , IPD_AGE_CODIGO
							 , IPD_PREGUNTAR_POR
							 , IPD_FAX
							 , IPD_OCL_CLI_PER_NUM_IDEN_RELAC
							 , IPD_OCL_CLI_PER_TID_CODIGO_REL
							 , IPD_CCC_CLI_PER_NUM_IDEN_TRANS
							 , IPD_CCC_CLI_PER_TID_CODIGO_TRA
							 , IPD_CCC_NUMERO_CUENTA_TRANSF
							 , IPD_CFO_CCC_NUMERO_CUENTA
							 , IPD_CFO_FON_CODIGO
							 , IPD_CFO_CODIGO
							 , IPD_TAC_MNEMONICO
							 , IPD_MAS_INSTRUCCIONES
							 , IPD_NUM_IDEN
							 , IPD_TID_CODIGO
							 , IPD_FECHA_REGISTRO
							 , IPD_USUARIO_REGISTRO
							 , IPD_TERMINAL_REGISTRO
							 , IPD_FECHA_MODIFICACION
							 , IPD_USUARIO_MODIFICACION
							 , IPD_TERMINAL_MODIFICACION
							 , IPD_NUM_IDEN_ACH
							 , IPD_TID_CODIGO_ACH
							 , IPD_DIGITO_CONTROL
							 , IPD_NOMBRE_ACH
							 , IPD_FAX_ACH
							 , IPD_EMAIL
							 , IPD_MEDIO_RECEPCION
							 , IPD_DETALLE_MEDIO_RECEPCION
							 , IPD_FECHA_RECEPCION
							 , IPD_HORA_RECEPCION
							 , IPD_NUMERO_RADICACION
							 , IPD_VISADO
							 , IPD_TIPO_ORIGEN_PAGO
							 , IPD_CONSECUTIVO
							 , IPD_FIC_CODIGO_BOLSA
							 , IPD_FIC_PER_TID_CODIGO
							 , IPD_FIC_PER_NUM_IDEN
							 , IPD_GIRO_OTRA_CIUDAD
							 , IPD_TIPO_EMISOR
							 , IPD_ESTADO
							 , IPD_INSTRUCCION_POD
							 , IPD_FECHA_INACTIVACION
							 , IPD_HORA_INACTIVACION
							 , IPD_MEDIO_INACTIVACION
							 , IPD_USUARIO_INACTIVACION
							 , IPD_TERMINAL_INACTIVACION
							 , IPD_MOTIVO_INACTIVACION
						INTO   R_INSTRUCCION
                        FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
                        WHERE  IPD_CCC_CLI_PER_NUM_IDEN = INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN
                        AND    IPD_CCC_CLI_PER_TID_CODIGO = INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO
                        AND    IPD_CCC_NUMERO_CUENTA = INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA
                        AND    IPD_CONSECUTIVO = INSTRUCCIONES_REC.IPD_CONSECUTIVO;

                        --Consulta el compartimento
                        P_ORDENES_FONDOS.P_VALIDA_PARAMETROS_COMP
                              (P_FON_CODIGO          => INSTRUCCIONES_REC.IPD_CFO_FON_CODIGO
                              ,P_PAR_CODIGO          =>  70
                              ,P_PFO_RANGO_MIN_CHAR  => V_FONDO_COMPARTIMENTO);

                        V_FONDO_COMPARTIMENTO := NVL(V_FONDO_COMPARTIMENTO,'N');

                        --Salario minimo
                        IF NVL(V_FONDO_COMPARTIMENTO,'N') = 'S' THEN
                           V_PROCESO := 'TFS-SD-VSAM';
                           OPEN CONSTANTE(P_CON_MNEMONICO => 'SAM');
                           FETCH CONSTANTE INTO V_SALARIO_MINIMO;
                           CLOSE CONSTANTE;
                        END IF;
                        IF CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO_PAGO,0) < 0 THEN
                           CREAR_PAGO := 'N';
                           RAISE SALDO_NEGATIVO;
                        END IF;
                        --Llama el procedimiento para crear la orden de fondo
                        V_PROCESO := 'TFS-SD-OFN';
                        P_PAGOS_DIVIDENDOS.ORDEN_FONDO_NOCTURNO
                           (R_INSTRUCCION
                           ,CCC1.PER_SUC_CODIGO --revisar se dejo Bogota principal
                           ,V_FONDO_COMPARTIMENTO
                           ,V_SALARIO_MINIMO
                           ,BASE
                           ,V_MONTO_PAGO
                           ,CCC1.CCC_PER_NUM_IDEN
                           ,CCC1.CCC_PER_TID_CODIGO
                           ,CCC1.PER_NOMBRE_USUARIO
                           ,'ADVAL'
                           ,P_OFO_CONS
                           ,P_OFO_SUC
                           ,P_DESCRIPCION);

                        -- MARCA LOS MOVIMIENTOS COMO PAGADOS
                        IF P_OFO_CONS IS NOT NULL THEN
                           P_PAGOS_DIVIDENDOS.MARCAR_MCC_INSTRUCCION_PAGO_N
                                    ( P_IPD_CONS              => INSTRUCCIONES_REC.IPD_CONSECUTIVO
                                     ,P_TIPO_INSTRUCCION_PAGO => 'PP'
                                     ,P_SALDO                 => V_MONTO_PAGO
                                     ,P_OFO_CONS              => P_OFO_CONS
                                     ,P_OFO_SUC               => P_OFO_SUC);
                        END IF;
                        COMMIT;
                     END IF;
                  END IF;
               END IF;
            END IF;


   COMMIT;

         EXCEPTION
            WHEN DIF_SALDO THEN
               ROLLBACK TO SV_INSTRUCCIONES;
               P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- VALIDA SALDO'
                                                   ,P_ERROR       => 'CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||
                                                                    ' El saldo de los movimientos de MCC es diferente al saldo de Administracion Valores de CCC '
                                                   ,P_TABLA_ERROR => NULL);

            WHEN SIN_VR_ODP THEN
               ROLLBACK TO SV_INSTRUCCIONES;
               P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- VALIDA MONTO MAXIMO'
                                                   ,P_ERROR       => 'CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||' Instruccion:'||P_INSTRUCCION||
                                                                    ' No se ejecuta por que se cumplio el monto maximo diario por cliente para orden de pago'
                                                   ,P_TABLA_ERROR => NULL);

            WHEN EXISTE_ODP THEN
               ROLLBACK TO SV_INSTRUCCIONES;
               P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- ORDEN PAGO'
                                                   ,P_ERROR       => 'CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||
                                                                    ' Existen ordenes de pago en el producto Administracion Valores sin ejecutar '
                                                   ,P_TABLA_ERROR => NULL);

            WHEN EXISTE_OFO THEN
               ROLLBACK TO SV_INSTRUCCIONES;
               P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- ORDEN DE FONDOS'
                                                   ,P_ERROR       => 'CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||
                                                                    ' Existen ordenes de fondos provenientes del producto Administracion Valores  pendientes de aprobar'
                                                   ,P_TABLA_ERROR => NULL);
            WHEN SALDO_NEGATIVO THEN
               ROLLBACK TO SV_INSTRUCCIONES;
               P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- VALIDA SALDO'
                                                   ,P_ERROR       => 'CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||
                                                                    ' El monto de la orden excede el saldo de la cuenta corredores '
                                                   ,P_TABLA_ERROR => NULL);
            WHEN OTHERS THEN
               ROLLBACK TO SV_INSTRUCCIONES;
               ERRORSQL := SUBSTR(SQLERRM,1,80);
               P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PROCESO NOCTURNO-1-'
                                                   ,P_ERROR       => V_PROCESO||' CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||SUBSTR(SQLERRM,1,350)
                                                   ,P_TABLA_ERROR => NULL);
         END;
      END LOOP;
   END IF;
     V_PROCESO := 'REGFIN';
     P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_PAGOS_DIVIDENDOS.PROCESO_NOCTURNO','FIN');
EXCEPTION
   WHEN OTHERS THEN
       ROLLBACK;
       ERRORSQL := SUBSTR(SQLERRM,1,80);
       P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PROCESO NOCTURNO-2-'
                                           ,P_ERROR       => V_PROCESO||' CLIENTE '||P_CLI_PER_NUM_IDEN||'-'||P_CLI_PER_TID_CODIGO||'-'||P_NUMERO_CUENTA||' '||SUBSTR(SQLERRM,1,350)
                                           ,P_TABLA_ERROR => NULL);
END PROCESO_NOCTURNO;
--------------------------------------------------------------------------------
PROCEDURE ORDEN_PAGO_NOCTURNO
   (P_CCC_CLI_PER_NUM_IDEN    VARCHAR2
   ,P_CCC_CLI_PER_TID_CODIGO  VARCHAR2
   ,P_CCC_NUMERO_CUENTA       NUMBER
   ,P_CONSECUTIVO             NUMBER
   ,P_VR_MINIMO_ORDEN         NUMBER
   ,P_SIGUIENTE_HABIL         DATE
   ,P_CCC_PER_NUM_IDEN        VARCHAR2
   ,P_CCC_PER_TID_CODIGO      VARCHAR2
   ,P_MONTO_POR_CAUSAR        NUMBER
   ,P_PER_NOMBRE_USUARIO      VARCHAR2
   ,P_PRODUCTO                VARCHAR2
   ,P_ODP_CONS                IN OUT NUMBER
   ,P_ODP_SUC                 IN OUT NUMBER
   ,P_ODP_NEG                 IN OUT NUMBER)  IS

   P_GENERO  VARCHAR2(2);
   P_DETALLE VARCHAR2(100);

   CURSOR C_IPDX IS
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
            ,IPD_CCC_CLI_PER_TID_CODIGO
            ,IPD_CCC_NUMERO_CUENTA
            ,IPD_TAC_MNEMONICO
            ,IPD_SUC_CODIGO
            ,IPD_TPA_MNEMONICO
            ,IPD_A_NOMBRE_DE
            ,IPD_CONSIGNAR
            ,IPD_ENTREGAR_RECOGE
            ,IPD_ENVIA_FAX
            ,NVL(IPD_CRUCE_CHEQUE,'RP') IPD_CRUCE_CHEQUE   ---VALIDAR SI APLICA
            ,IPD_PER_NUM_IDEN
            ,IPD_PER_TID_CODIGO
            ,IPD_PAGAR_A
            ,IPD_BAN_CODIGO
            ,IPD_NUM_CUENTA_CONSIGNAR
            ,IPD_TCB_MNEMONICO
            ,IPD_DIRECCION_ENVIO_CHEQUE
            ,IPD_AGE_CODIGO
            ,IPD_PREGUNTAR_POR
            ,IPD_FAX
            ,IPD_OCL_CLI_PER_NUM_IDEN_RELAC
            ,IPD_OCL_CLI_PER_TID_CODIGO_REL
            ,IPD_CCC_CLI_PER_NUM_IDEN_TRANS
            ,IPD_CCC_CLI_PER_TID_CODIGO_TRA
            ,IPD_CCC_NUMERO_CUENTA_TRANSF
            ,IPD_MAS_INSTRUCCIONES
            ,IPD_NUM_IDEN
            ,IPD_TID_CODIGO
            ,IPD_MEDIO_RECEPCION
            ,IPD_DETALLE_MEDIO_RECEPCION
            ,IPD_HORA_RECEPCION
            ,IPD_FECHA_RECEPCION
            ,IPD_NUMERO_RADICACION
            ,IPD_NUM_IDEN_ACH
            ,IPD_TID_CODIGO_ACH
            ,IPD_NOMBRE_ACH
            ,IPD_DIGITO_CONTROL
            ,IPD_FAX_ACH
            ,IPD_EMAIL
            ,IPD_FIC_CODIGO_BOLSA
            ,IPD_FIC_PER_TID_CODIGO
            ,IPD_FIC_PER_NUM_IDEN
            ,IPD_GIRO_OTRA_CIUDAD
      FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE  IPD_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
      AND    IPD_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
      AND    IPD_CCC_NUMERO_CUENTA  = P_CCC_NUMERO_CUENTA
		  AND    IPD_CONSECUTIVO = P_CONSECUTIVO;
   R_IPDX C_IPDX%ROWTYPE;

   CURSOR C_IBA IS
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = 'IBA';

   CURSOR C_MAX IS
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = 'MXD';


   CURSOR C_ODP IS
      SELECT ABS(- SUM(ODP_MONTO_ORDEN) + SUM(ODP_MONTO_IMGF))
      FROM   ORDENES_DE_PAGO
      WHERE  ODP_NPR_PRO_MNEMONICO IN ('ADVAL','OB')
      AND    ODP_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
      AND    ODP_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
      AND    ODP_ESTADO IN ('COL','APR')
      AND    ODP_FECHA >= TRUNC(SYSDATE)
      AND    ODP_CEG_CONSECUTIVO IS NULL
      AND    ODP_CGE_CONSECUTIVO IS NULL
      AND    ODP_TBC_CONSECUTIVO IS NULL
      AND    ODP_TCC_CONSECUTIVO IS NULL
      AND    NVL(ODP_ORDEN_MANUAL,'N') = 'N'
      AND    ODP_TERMINAL_VERIFICA = 'NOCTURNO';
   MONTO_ODP NUMBER;


   CURSOR C_CLIENTE_EXCENTO (P_NID VARCHAR2, P_TID VARCHAR2) IS
      SELECT CLI_EXCENTO_DXM_FONDOS
      FROM   CLIENTES
      WHERE  CLI_PER_NUM_IDEN = P_NID
      AND    CLI_PER_TID_CODIGO = P_NID;

   P_MONTO_ORDEN1       ORDENES_DE_PAGO.ODP_MONTO_ORDEN%TYPE:= NULL;
   P_MONTO_IMGF1        ORDENES_DE_PAGO.ODP_MONTO_IMGF%TYPE := NULL;
   P_EXCENTO1           VARCHAR2(1) := NULL;
   P_IBA1               CONSTANTES.CON_VALOR%TYPE:= NULL;
   P_MAX1               CONSTANTES.CON_VALOR%TYPE:= NULL;
   CONSECUTIVO_ODP      ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
   FECHA1               DATE;

   CURSOR C_NUMERO IS
      SELECT DPA_SEQ.NEXTVAL
      FROM   DUAL;

   CONS_DPA                 NUMBER;
   NVOCONS	                NUMBER;
   P_ESTADO                 ORDENES_DE_PAGO.ODP_ESTADO%TYPE := NULL;
   P_APROBADA_POR           ORDENES_DE_PAGO.ODP_APROBADA_POR%TYPE := NULL;
   P_TERMINAL_VERIFICA      ORDENES_DE_PAGO.ODP_TERMINAL_VERIFICA%TYPE := NULL;
   P_VERIFICADO_COMERCIAL   ORDENES_DE_PAGO.ODP_VERIFICADO_COMERCIAL%TYPE := NULL;
   P_DILIGENCIADA_POR       ORDENES_DE_PAGO.ODP_DILIGENCIADA_POR%TYPE := NULL;
   P_FECHA_APROBACION       ORDENES_DE_PAGO.ODP_FECHA_APROBACION%TYPE := NULL;
   P_FECHA_VERIFICA         ORDENES_DE_PAGO.ODP_FECHA_VERIFICA%TYPE := NULL;
   P_FECHA_EJECUCION        ORDENES_DE_PAGO.ODP_FECHA_EJECUCION%TYPE := NULL;
   CONCEPTO                 ORDENES_DE_PAGO.ODP_COT_MNEMONICO%TYPE := NULL;
   ERRORSQL VARCHAR2(100);
   EXCEDE_MAXIMO EXCEPTION;
   V_PROCESO VARCHAR2(200);    -- AJUSTE VAGTUD991
BEGIN
   P_ODP_CONS  := NULL;
   P_ODP_SUC   := NULL;
   P_ODP_NEG   := NULL;

   V_PROCESO := 'IPDX';
   OPEN C_IPDX;
   FETCH C_IPDX INTO R_IPDX;
   CLOSE C_IPDX;

   V_PROCESO := 'ODPSEQ';
   SELECT ODP_SEQ.NEXTVAL INTO CONSECUTIVO_ODP FROM DUAL;
   P_ESTADO := 'APR';
   P_APROBADA_POR     := P_PER_NOMBRE_USUARIO;
   P_TERMINAL_VERIFICA := 'NOCTURNO';
   P_VERIFICADO_COMERCIAL := 'S';
   P_DILIGENCIADA_POR := P_PER_NOMBRE_USUARIO;
   SELECT SYSDATE INTO P_FECHA_APROBACION FROM DUAL;
   SELECT SYSDATE INTO P_FECHA_VERIFICA FROM DUAL;
   SELECT SYSDATE INTO P_FECHA_EJECUCION FROM DUAL;

   --.--  SANDRA MOTTA : 4XM
   V_PROCESO := 'IBA';
   OPEN C_IBA;
   FETCH C_IBA INTO P_IBA1;
   CLOSE C_IBA;
   P_IBA1 := NVL(P_IBA1,0);

   V_PROCESO := 'CLIEXE';
   OPEN C_CLIENTE_EXCENTO(P_CCC_CLI_PER_NUM_IDEN
                         ,P_CCC_CLI_PER_TID_CODIGO);
   FETCH C_CLIENTE_EXCENTO INTO P_EXCENTO1;
   CLOSE C_CLIENTE_EXCENTO;
   P_EXCENTO1 := NVL(P_EXCENTO1,'N');

   IF (R_IPDX.IPD_PAGAR_A = 'C' AND
       R_IPDX.IPD_TPA_MNEMONICO IN ('CHE','CHG') AND
       R_IPDX.IPD_CRUCE_CHEQUE IN ('CA')) OR
      (R_IPDX.IPD_PAGAR_A = 'C' AND
       R_IPDX.IPD_TPA_MNEMONICO = 'TRB') OR
      (R_IPDX.IPD_PAGAR_A = 'C' AND
       R_IPDX.IPD_TPA_MNEMONICO = 'PSE' AND R_IPDX.IPD_NUM_CUENTA_CONSIGNAR IS NOT NULL) OR
      (R_IPDX.IPD_PAGAR_A = 'C' AND
       R_IPDX.IPD_TPA_MNEMONICO = 'ACH') OR
      (R_IPDX.IPD_TPA_MNEMONICO = 'TCC' AND
       P_CCC_CLI_PER_NUM_IDEN = R_IPDX.IPD_CCC_CLI_PER_NUM_IDEN_TRANS AND
       P_CCC_CLI_PER_TID_CODIGO = R_IPDX.IPD_CCC_CLI_PER_TID_CODIGO_TRA) OR
      (NVL(P_EXCENTO1,'N')) = 'S' THEN
      V_PROCESO := 'IFRIPDX';
      P_MONTO_ORDEN1  := P_MONTO_POR_CAUSAR;
      P_MONTO_IMGF1   := 0;
   ELSE
      V_PROCESO := 'ELRIPDX';
      P_MONTO_ORDEN1  := ROUND(P_MONTO_POR_CAUSAR / (1 + P_IBA1),2);
      P_MONTO_IMGF1   := -ROUND(P_MONTO_ORDEN1 * P_IBA1,2);
   END IF;

   V_PROCESO := 'MONTOODP';
   MONTO_ODP := 0;
   OPEN C_ODP;
   FETCH C_ODP INTO MONTO_ODP;
   CLOSE C_ODP;
   MONTO_ODP := NVL(MONTO_ODP,0);

   V_PROCESO := 'PMAX';
   OPEN C_MAX;
   FETCH C_MAX INTO P_MAX1;
   CLOSE C_MAX;
   P_MAX1 := NVL(P_MAX1,0);

   V_PROCESO := 'VALMONTO';
   IF MONTO_ODP + ABS(-P_MONTO_ORDEN1+P_MONTO_IMGF1)  > P_MAX1 THEN
      RAISE EXCEDE_MAXIMO;
   END IF;

   V_PROCESO := 'VALPROD';
   IF P_PRODUCTO = 'OB' THEN
      CONCEPTO := 'PVT';
   ELSIF P_PRODUCTO = 'ADVAL' THEN
      CONCEPTO := 'PADMV';
   END IF;


   V_PROCESO := 'INSODP';
   INSERT INTO ORDENES_DE_PAGO
      (ODP_CONSECUTIVO
      ,ODP_SUC_CODIGO
      ,ODP_NEG_CONSECUTIVO
      ,ODP_FECHA
      ,ODP_COLOCADA_POR
      ,ODP_TPA_MNEMONICO
      ,ODP_ESTADO
      ,ODP_ES_CLIENTE
      ,ODP_COT_MNEMONICO
      ,ODP_A_NOMBRE_DE
      ,ODP_FECHA_EJECUCION
      ,ODP_CONSIGNAR
      ,ODP_ENTREGAR_RECOGE
      ,ODP_ENVIA_FAX
      ,ODP_SOBREGIRO
      ,ODP_CRUCE_CHEQUE
      ,ODP_MONTO_ORDEN
      ,ODP_MONTO_IMGF
      ,ODP_NPR_PRO_MNEMONICO
      ,ODP_APROBADA_POR
      ,ODP_FECHA_APROBACION
      ,ODP_CCC_CLI_PER_NUM_IDEN
      ,ODP_CCC_CLI_PER_TID_CODIGO
      ,ODP_CCC_NUMERO_CUENTA
      ,ODP_PER_NUM_IDEN
      ,ODP_PER_TID_CODIGO
      ,ODP_PAGAR_A
      ,ODP_BAN_CODIGO
      ,ODP_NUM_CUENTA_CONSIGNAR
      ,ODP_TCB_MNEMONICO
      ,ODP_DIRECCION_ENVIO_CHEQUE
      ,ODP_AGE_CODIGO
      ,ODP_PREGUNTAR_POR
      ,ODP_FAX
      ,ODP_FECHA_VERIFICA
      ,ODP_TERMINAL_VERIFICA
      ,ODP_PER_NUM_IDEN_ES_DUENO
      ,ODP_PER_TID_CODIGO_ES_DUENO
      ,ODP_VERIFICADO_COMERCIAL
      ,ODP_TAC_MNEMONICO
      ,ODP_OCL_CLI_PER_NUM_IDEN_RELAC
      ,ODP_OCL_CLI_PER_TID_CODIGO_REL
      ,ODP_CCC_CLI_PER_NUM_IDEN_TRANS
      ,ODP_CCC_CLI_PER_TID_CODIGO_TRA
      ,ODP_CCC_NUMERO_CUENTA_TRANSFIE
      ,ODP_MAS_INSTRUCCIONES
      ,ODP_NUM_IDEN
      ,ODP_TID_CODIGO
      ,ODP_DILIGENCIADA_POR
      ,ODP_MEDIO_RECEPCION
      ,ODP_DETALLE_MEDIO_RECEPCION
      ,ODP_HORA_RECEPCION
      ,ODP_FECHA_RECEPCION
      ,ODP_NUMERO_RADICACION
      ,ODP_FIC_CODIGO_BOLSA
      ,ODP_FIC_PER_TID_CODIGO
      ,ODP_FIC_PER_NUM_IDEN
      ,ODP_GIRO_OTRA_CIUDAD
      ,ODP_FORMA_CARGUE_ACH)
   VALUES
      (CONSECUTIVO_ODP
      ,R_IPDX.IPD_SUC_CODIGO
      ,2
      ,SYSDATE
      ,P_PER_NOMBRE_USUARIO
      ,R_IPDX.IPD_TPA_MNEMONICO
      ,P_ESTADO
      ,'S'
      ,CONCEPTO
      ,R_IPDX.IPD_A_NOMBRE_DE
      ,P_FECHA_EJECUCION
      ,R_IPDX.IPD_CONSIGNAR
      ,R_IPDX.IPD_ENTREGAR_RECOGE
      ,R_IPDX.IPD_ENVIA_FAX
      ,'N'
      ,R_IPDX.IPD_CRUCE_CHEQUE
      ,P_MONTO_ORDEN1
      ,P_MONTO_IMGF1
      ,P_PRODUCTO
      ,P_APROBADA_POR
      ,P_FECHA_APROBACION
      ,P_CCC_CLI_PER_NUM_IDEN
      ,P_CCC_CLI_PER_TID_CODIGO
      ,P_CCC_NUMERO_CUENTA
      ,R_IPDX.IPD_PER_NUM_IDEN
      ,R_IPDX.IPD_PER_TID_CODIGO
      ,R_IPDX.IPD_PAGAR_A
      ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX.IPD_BAN_CODIGO)
      ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX.IPD_NUM_CUENTA_CONSIGNAR)
      ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX.IPD_TCB_MNEMONICO)
      ,R_IPDX.IPD_DIRECCION_ENVIO_CHEQUE
      ,R_IPDX.IPD_AGE_CODIGO
      ,R_IPDX.IPD_PREGUNTAR_POR
      ,R_IPDX.IPD_FAX
      ,P_FECHA_VERIFICA
      ,P_TERMINAL_VERIFICA
      ,P_CCC_PER_NUM_IDEN
      ,P_CCC_PER_TID_CODIGO
      ,P_VERIFICADO_COMERCIAL
      ,R_IPDX.IPD_TAC_MNEMONICO
      ,R_IPDX.IPD_OCL_CLI_PER_NUM_IDEN_RELAC
      ,R_IPDX.IPD_OCL_CLI_PER_TID_CODIGO_REL
      ,R_IPDX.IPD_CCC_CLI_PER_NUM_IDEN_TRANS
      ,R_IPDX.IPD_CCC_CLI_PER_TID_CODIGO_TRA
      ,R_IPDX.IPD_CCC_NUMERO_CUENTA_TRANSF
      ,R_IPDX.IPD_MAS_INSTRUCCIONES
      ,R_IPDX.IPD_NUM_IDEN
      ,R_IPDX.IPD_TID_CODIGO
      ,P_DILIGENCIADA_POR
      ,R_IPDX.IPD_MEDIO_RECEPCION
      ,R_IPDX.IPD_DETALLE_MEDIO_RECEPCION
      ,R_IPDX.IPD_HORA_RECEPCION
      ,R_IPDX.IPD_FECHA_RECEPCION
      ,R_IPDX.IPD_NUMERO_RADICACION
      ,R_IPDX.IPD_FIC_CODIGO_BOLSA
      ,R_IPDX.IPD_FIC_PER_TID_CODIGO
      ,R_IPDX.IPD_FIC_PER_NUM_IDEN
      ,R_IPDX.IPD_GIRO_OTRA_CIUDAD
      ,'P');

   IF R_IPDX.IPD_TPA_MNEMONICO = 'ACH' AND
      R_IPDX.IPD_BAN_CODIGO IS NOT NULL AND
      R_IPDX.IPD_NUM_CUENTA_CONSIGNAR IS NOT NULL AND
      R_IPDX.IPD_TCB_MNEMONICO IS NOT NULL THEN

      V_PROCESO := 'ODPACH';
      OPEN C_NUMERO;
      FETCH C_NUMERO INTO CONS_DPA;
      CLOSE C_NUMERO;

      V_PROCESO := 'INSDPA';
      INSERT INTO DETALLES_PAGOS_ACH
         (DPA_CONSECUTIVO
         ,DPA_ODP_SUC_CODIGO
         ,DPA_ODP_NEG_CONSECUTIVO
         ,DPA_ODP_CONSECUTIVO
         ,DPA_NUM_IDEN
         ,DPA_TID_CODIGO
         ,DPA_NOMBRE
         ,DPA_BAN_CODIGO
         ,DPA_TCB_MNEMONICO
         ,DPA_NUMERO_CUENTA
         ,DPA_MONTO
         ,DPA_USUARIO
         ,DPA_FECHA
         ,DPA_TERMINAL
         ,DPA_REVERSADO
         ,DPA_DIGITO_CONTROL
         ,DPA_FAX
         ,DPA_EMAIL)
      VALUES
         (CONS_DPA
         ,R_IPDX.IPD_SUC_CODIGO
         ,2
         ,CONSECUTIVO_ODP
         ,R_IPDX.IPD_NUM_IDEN_ACH
         ,R_IPDX.IPD_TID_CODIGO_ACH
         ,NVL(R_IPDX.IPD_NOMBRE_ACH,R_IPDX.IPD_A_NOMBRE_DE)
         ,R_IPDX.IPD_BAN_CODIGO
         ,R_IPDX.IPD_TCB_MNEMONICO
         ,R_IPDX.IPD_NUM_CUENTA_CONSIGNAR
         ,P_MONTO_ORDEN1                        --.--P_MONTO_POR_CAUSAR
         ,P_PER_NOMBRE_USUARIO
         ,SYSDATE
         ,'NOCTURNO'
         ,'N'
         ,R_IPDX.IPD_DIGITO_CONTROL
         ,R_IPDX.IPD_FAX_ACH
         ,R_IPDX.IPD_EMAIL);
   END IF;

   V_PROCESO := 'DATRET';
   P_ODP_CONS  := CONSECUTIVO_ODP;
   P_ODP_SUC   := R_IPDX.IPD_SUC_CODIGO;
   P_ODP_NEG   := 2;

   P_GENERO := 'OK';
   P_DETALLE := 'ORDEN DE PAGO: SUC '||R_IPDX.IPD_SUC_CODIGO||' - NEG 2 - ORDEN '||CONSECUTIVO_ODP;

  -- COMMIT;

EXCEPTION
   WHEN EXCEDE_MAXIMO THEN
      P_ODP_CONS  := NULL;
      P_ODP_SUC   := NULL;
      P_ODP_NEG   := NULL;
      ROLLBACK;
      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- ORDEN PAGO'
                                          ,P_ERROR       => 'CLIENTE '||P_CCC_CLI_PER_NUM_IDEN||'-'||P_CCC_CLI_PER_TID_CODIGO||'-'||P_CCC_NUMERO_CUENTA||' '||
                                                                     '  Excede el monto maximo diario por cliente que de debe girar por instruccion permantente'
                                          ,P_TABLA_ERROR => NULL);

   WHEN OTHERS THEN
      ROLLBACK;
      P_ODP_CONS  := NULL;
      P_ODP_SUC   := NULL;
      P_ODP_NEG   := NULL;
      ERRORSQL := SUBSTR(SQLERRM,1,80);
      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS- ORDEN PAGO'
                                          ,P_ERROR       => V_PROCESO||' CLIENTE '||P_CCC_CLI_PER_NUM_IDEN||'-'||P_CCC_CLI_PER_TID_CODIGO||'-'||P_CCC_NUMERO_CUENTA||' '||SUBSTR(SQLERRM,1,350)
                                          ,P_TABLA_ERROR => NULL);

END ORDEN_PAGO_NOCTURNO;

PROCEDURE ORDEN_FONDO_NOCTURNO
   (R_IPD                 INSTRUCCIONES_PAGOS_DIVIDENDOS%ROWTYPE
   ,P_SUC_CODIGO          NUMBER
   ,P_FONDO_COMPARTIMENTO VARCHAR2
   ,P_SALARIO_MINIMO      NUMBER
   ,P_FON_BMO_MNEMONICO   VARCHAR2
   ,P_MONTO_POR_CAUSAR    NUMBER
   ,P_CCC_PER_NUM_IDEN    VARCHAR2
   ,P_CCC_PER_TID_CODIGO  VARCHAR2
   ,P_PER_NOMBRE_USUARIO  VARCHAR2
   ,P_PRODUCTO            VARCHAR2
   ,P_OFO_CONS            IN OUT NUMBER
   ,P_OFO_SUC             IN OUT NUMBER
   ,P_DESCRIPCION         OUT VARCHAR2
   ) IS

   CURSOR OFO_CONSECUTIVO IS
      SELECT OFO_SEQ.NEXTVAL
      FROM DUAL;
   V_OFO_CONSECUTIVO ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE;

   -- AJUSTE VAGTUD991 - SE VALIDA LA PARTICIPACION ACTIVA DEL CLIENTE EN FONDO INTERES
   V_FON_CODIGO_ACT    CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE; -- AJUSTE VAGTUD991

   CURSOR PFO(P_PAR PARAMETROS.PAR_CODIGO%TYPE) IS
      SELECT PFO_RANGO_MIN_NUMBER
            ,PFO_RANGO_MAX_NUMBER
            ,PFO_RANGO_MIN_CHAR
      FROM   PARAMETROS_FONDOS
      WHERE  PFO_FON_CODIGO = V_FON_CODIGO_ACT      -- R_IPD.IPD_CFO_FON_CODIGO  -- AJUSTE VAGTUD991
      AND    PFO_PAR_CODIGO = P_PAR;
   R_PFO   PFO%ROWTYPE;
   R_PFO_I PFO%ROWTYPE;
   R_PFO_P PFO%ROWTYPE;
   -- VAGTUD991 - AJUSTE PROYECTO NUEVAS PARTICPACIONES F.INT
   V_FONDO_PPAL VARCHAR2(15);

   CURSOR ID_COLOCO IS
      SELECT PER_NUM_IDEN
            ,PER_TID_CODIGO
      FROM   PERSONAS
      WHERE  PER_NOMBRE_USUARIO = P_PER_NOMBRE_USUARIO;
   R_COLOCO ID_COLOCO%ROWTYPE;

   CURSOR SALDO_APORTE IS
      SELECT SUM(CFO_SALDO_INVER)
      FROM   CUENTAS_FONDOS
      WHERE  CFO_CCC_CLI_PER_NUM_IDEN = R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
      AND    CFO_CCC_CLI_PER_TID_CODIGO = R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
      AND    CFO_CCC_NUMERO_CUENTA =R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
      AND    CFO_FON_CODIGO LIKE V_FONDO_PPAL||'%'         -- VAGTUD991
      AND    CFO_CODIGO = R_IPD.IPD_CFO_CODIGO
      -- SE DESCARTA OMINUBUS
      AND    NOT EXISTS (
             SELECT 'S'
             FROM PARAMETROS_FONDOS
             WHERE PFO_FON_CODIGO = CFO_FON_CODIGO
             AND PFO_PAR_CODIGO = 115
             AND PFO_RANGO_MIN_CHAR = 'S')
      AND    CFO_SALDO_INVER > 0
      ;

   CURSOR C_COTIZACION IS
      SELECT CBM_VALOR
      FROM   COTIZACIONES_BASE_MONETARIAS
      WHERE  CBM_BMO_MNEMONICO = P_FON_BMO_MNEMONICO
      AND    TRUNC(CBM_FECHA)  = TRUNC(SYSDATE);

   CURSOR C_ORDENES_CLIENTE IS
      SELECT OFO_TTO_TOF_CODIGO
            ,OFO_EOF_CODIGO
      FROM   ORDENES_FONDOS
      WHERE  OFO_CFO_CCC_CLI_PER_NUM_IDEN = R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
      AND    OFO_CFO_CCC_CLI_PER_TID_CODIGO = R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
      AND    OFO_CFO_CCC_NUMERO_CUENTA = R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
      AND    OFO_CFO_FON_CODIGO = V_FON_CODIGO_ACT       -- R_IPD.IPD_CFO_FON_CODIGO -- AJUSTES VAGTUD991
      AND    OFO_CFO_CODIGO = R_IPD.IPD_CFO_CODIGO
      AND    OFO_EOF_CODIGO IN ('COL','APL')
      UNION
      SELECT OFO_TTO_TOF_CODIGO
            ,OFO_EOF_CODIGO
      FROM   ORDENES_FONDOS
      WHERE  OFO_CFO_CCC_CLI_PER_NUM_IDEN = R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
      AND    OFO_CFO_CCC_CLI_PER_TID_CODIGO = R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
      AND    OFO_CFO_CCC_NUMERO_CUENTA = R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
      AND    OFO_CFO_FON_CODIGO = V_FON_CODIGO_ACT       -- R_IPD.IPD_CFO_FON_CODIGO -- AJUSTES VAGTUD991
      AND    OFO_CFO_CODIGO = R_IPD.IPD_CFO_CODIGO
      AND    OFO_TTO_TOF_CODIGO = 'RT'
      AND    OFO_EOF_CODIGO IN ('CON');
   OFO1   C_ORDENES_CLIENTE%ROWTYPE;

   CURSOR C_TIPO_CARGO_CUENTA IS
      SELECT TIU_MNEMONICO
      FROM   TIPOS_CARGOS_CUENTAS
      WHERE  TIU_PRO_MNEMONICO = P_PRODUCTO;
   TIU1   C_TIPO_CARGO_CUENTA%ROWTYPE;

   CURSOR HORA_LIMITE(TIPO NUMBER, P_FONDO VARCHAR2)IS
      SELECT a.PFO_RANGO_MIN_CHAR
            ,A.PFO_RANGO_MAX_CHAR
      FROM   PARAMETROS_FONDOS A
      WHERE  A.PFO_FON_CODIGO = P_FONDO
      AND    A.PFO_PAR_CODIGO = TIPO;

   -- AJUSTE VAGTUD991 - VALIDACION CUENTA APT
   CURSOR C_APT IS
      SELECT CCC_CUENTA_APT
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
         AND CCC_NUMERO_CUENTA = R_IPD.IPD_CFO_CCC_NUMERO_CUENTA;
   V_ES_APT VARCHAR2(1);

   CURSOR C_EXISTE_APORTE IS
      SELECT 'S'
        FROM CUENTAS_FONDOS
       WHERE CFO_CCC_CLI_PER_NUM_IDEN = R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
         AND CFO_CCC_CLI_PER_TID_CODIGO = R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
         AND CFO_CCC_NUMERO_CUENTA = R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
         AND CFO_FON_CODIGO = V_FON_CODIGO_ACT
         AND CFO_CODIGO = R_IPD.IPD_CFO_CODIGO;
   V_EXISTE_APORTE VARCHAR2(1);

   V_ING_INC           ORDENES_FONDOS.OFO_TTO_TOF_CODIGO%TYPE;
   V_PAR_COD           PARAMETROS_FONDOS.PFO_PAR_CODIGO%TYPE;
   V_AUTORIZACION      ORDENES_FONDOS.OFO_AUTORIZACION%TYPE := 'S';
   COTIZACION          C_COTIZACION%ROWTYPE;
   SALDO_TOTAL_APORTE  NUMBER;
   ORDENES_INCREMENTO  NUMBER;
   ORDENES_RETIRO      NUMBER;
   V_MINIMO_INVERSION  NUMBER;
   V_MAXIMO_INVERSION  NUMBER;
   V_SIN_TOPE_MAXIMO   VARCHAR2(1);
   E_INGRESO           EXCEPTION;
   E_PARAMETRO         EXCEPTION;
   E_COLOCO            EXCEPTION;
   E_ERROR             EXCEPTION;
   E_ERRORM            EXCEPTION;
   E_ERRORC            EXCEPTION;
   E_ERROR_COT         EXCEPTION;
   E_ERROR_L           EXCEPTION;
   E_INGRESO_O         EXCEPTION;
   E_EXISTE_ORDEN      EXCEPTION;
   E_ERROR_CARGO       EXCEPTION;
   P_GENERO            VARCHAR2(2);
   P_DETALLE           VARCHAR2(100);
   ERRORSQL            VARCHAR2(200);
   PERFIL              VARCHAR2(10);
   PRODUCTO            FONDOS.FON_NPR_PRO_MNEMONICO%TYPE;
   NOMBRE_FONDO        FONDOS.FON_RAZON_SOCIAL%TYPE;
   NOMBRE_CLIENTE      VARCHAR2(60);
   AUTORIZADO          VARCHAR2(1);
   E_PERFIL_RIESGO     EXCEPTION;
   PERFIL_RIES         VARCHAR2(15);

   V_FECHA_EJECUCION DATE;
   HORA              HORA_LIMITE%ROWTYPE;

   E_PARAMETRO_P       EXCEPTION;   -- VAGTUD991
   NO_PART_ACT         EXCEPTION;   -- VAGTUD991
   NO_APO_APT_D        EXCEPTION;
   V_PROCESO           VARCHAR2(200);


BEGIN
   SAVEPOINT SV_FONDO_NOCTURNO;

   V_PROCESO := 'OFNINI';
   P_OFO_CONS :=  NULL;
   P_OFO_SUC  :=  NULL;

   -- SE OBTIENE LA PARTICIPACION DONDE SE VA A GENERAR LA ORDEN Y SOBRE ESA PARTICIPACION SE GENERAN LAS VALIDACIONES
   V_PROCESO := 'FONACT';
   V_FON_CODIGO_ACT := NULL;
   V_FON_CODIGO_ACT := P_RECAUDOS_DAVICASH.FN_PARTICIPACION_ACTIVA
                                          (P_CCC_CLI_PER_TID_CODIGO => R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
                                          ,P_CCC_CLI_PER_NUM_IDEN   => R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
                                          ,P_CCC_NUMERO_CUENTA      => R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
                                          ,P_CFO_FON_CODIGO         => R_IPD.IPD_CFO_FON_CODIGO
                                          ,P_CFO_CODIGO             => R_IPD.IPD_CFO_CODIGO);

   IF V_FON_CODIGO_ACT IS NULL THEN
      RAISE NO_PART_ACT;
   END IF;

   -- VAGTUD991 - SE BUSCA FONDO PRINCIPAL
   V_PROCESO := 'FONPPAL';
   V_FONDO_PPAL := R_IPD.IPD_CFO_FON_CODIGO;
   IF NVL(P_FONDO_COMPARTIMENTO,'N') = 'S' THEN
      OPEN PFO(71);
      FETCH PFO INTO R_PFO_P;
      IF PFO%NOTFOUND THEN
         CLOSE PFO;
         RAISE E_PARAMETRO_P;
      ELSE
         V_FONDO_PPAL := R_PFO_P.PFO_RANGO_MIN_CHAR;
      END IF;
      CLOSE PFO;
   END IF;

   -- MCANON SOLICITA QUE SI LA CUENTA ES APT EL INCREMENTO DEBE IRSE
   -- A LA PARTICIPACION DESIGNADA PARA FILIALES - PARTICIPACION D
   V_PROCESO := 'VALAPT';
   OPEN C_APT;
   FETCH C_APT INTO V_ES_APT;
   CLOSE C_APT;
   IF NVL(V_ES_APT,'N') = 'S' AND V_FONDO_PPAL = '800154697' THEN
      V_FON_CODIGO_ACT := '800154697-D';
      OPEN C_EXISTE_APORTE;
      FETCH C_EXISTE_APORTE INTO V_EXISTE_APORTE;
      CLOSE C_EXISTE_APORTE;
      IF NVL(V_EXISTE_APORTE,'N') != 'S' THEN
         RAISE NO_APO_APT_D;
      END IF;
   END IF;

   /* Se va a validar si existen ordenes posteriores sin confirmar o retiros totales confirmados. Caso en el cual no
     se coloca la orden y se insertar un error informando la situacion */
   V_PROCESO := 'VALORDCLI';
   OPEN C_ORDENES_CLIENTE;
   FETCH C_ORDENES_CLIENTE INTO OFO1;
   IF C_ORDENES_CLIENTE%FOUND THEN
      CLOSE C_ORDENES_CLIENTE;
      RAISE E_EXISTE_ORDEN;
   END IF;
   CLOSE C_ORDENES_CLIENTE;

   -- siempre es incremento
   V_ING_INC := 'INC';
   V_PAR_COD := 6;

   V_PROCESO := 'VALINC';
   OPEN PFO(V_PAR_COD);
   FETCH PFO INTO R_PFO;
   IF PFO%NOTFOUND THEN
      CLOSE PFO;
      RAISE E_PARAMETRO;
   ELSE
      IF V_ING_INC = 'ING' AND NVL(P_FONDO_COMPARTIMENTO,'N') = 'N'   THEN
         IF (NVL(P_MONTO_POR_CAUSAR, 0) < NVL(R_PFO.PFO_RANGO_MIN_NUMBER, 0) OR
             NVL(P_MONTO_POR_CAUSAR, 0) > NVL(R_PFO.PFO_RANGO_MAX_NUMBER, 0)) THEN
             V_AUTORIZACION := 'S';
             CLOSE PFO;
             RAISE E_INGRESO_O;
         END IF;
      ELSIF V_ING_INC = 'INC' THEN
         IF NVL(P_MONTO_POR_CAUSAR, 0) < NVL(R_PFO.PFO_RANGO_MIN_NUMBER, 0)  THEN
            CLOSE PFO;
            RAISE E_INGRESO;
         END IF;
      END IF;
   END IF;
   CLOSE PFO;

   /* validacion que el saldo del cliente debe ser al minimo del parametro 28*/
   V_PROCESO := 'VALSALAPO';
   OPEN SALDO_APORTE;
   FETCH SALDO_APORTE INTO SALDO_TOTAL_APORTE;
   CLOSE SALDO_APORTE;
   SALDO_TOTAL_APORTE := NVL(SALDO_TOTAL_APORTE,0);

   V_PROCESO := 'PFO28';
   OPEN PFO(28);
   FETCH PFO INTO R_PFO_I;
   IF PFO %NOTFOUND THEN
      CLOSE PFO;
      RAISE E_ERRORM;
   END IF;
   CLOSE PFO;

   V_PROCESO := 'VALMONINC';
   IF R_PFO_I.PFO_RANGO_MIN_NUMBER IS NOT NULL THEN
      IF P_FON_BMO_MNEMONICO != 'PESOS' THEN
         OPEN C_COTIZACION;
         FETCH C_COTIZACION INTO COTIZACION;
         IF C_COTIZACION%NOTFOUND THEN
            CLOSE C_COTIZACION; -- newLinea-VAGTUS102769
            RAISE E_ERROR_COT;
         END IF;
         CLOSE C_COTIZACION;

         IF NVL(ROUND(P_MONTO_POR_CAUSAR/COTIZACION.CBM_VALOR,2), 0) + SALDO_TOTAL_APORTE < R_PFO_I.PFO_RANGO_MIN_NUMBER  THEN
            RAISE E_ERROR;
         END IF;
      ELSE
         IF NVL(P_MONTO_POR_CAUSAR, 0) + SALDO_TOTAL_APORTE < R_PFO_I.PFO_RANGO_MIN_NUMBER  THEN
            RAISE E_ERROR;
         END IF;
      END IF;
   END IF;

   V_PROCESO := 'OFOSEQ';
   OPEN OFO_CONSECUTIVO;
   FETCH OFO_CONSECUTIVO INTO V_OFO_CONSECUTIVO;
   IF OFO_CONSECUTIVO%NOTFOUND THEN
      V_OFO_CONSECUTIVO := 1;
   END IF;
   CLOSE OFO_CONSECUTIVO;

   V_PROCESO := 'IDCOL';
   OPEN ID_COLOCO;
   FETCH ID_COLOCO INTO R_COLOCO;
   IF ID_COLOCO%NOTFOUND THEN
      CLOSE ID_COLOCO;
      RAISE E_COLOCO;
   END IF;
   CLOSE ID_COLOCO;

   --HROSAS, Req VAGTUD326 - Perfil Riesgo
   IF R_IPD.IPD_TRASLADO_FONDOS = 'S' THEN
      --Se Obtiene el FON_NPR_PRO_MNEMONICO del fondo
      V_PROCESO := 'TFSFON';
      SELECT F.FON_NPR_PRO_MNEMONICO, F.FON_RAZON_SOCIAL
      INTO   PRODUCTO, NOMBRE_FONDO
      FROM   FONDOS F
      WHERE  F.FON_CODIGO = R_IPD.IPD_CFO_FON_CODIGO;

      --Se Obtiene el perfi de riesgo del cliente
      V_PROCESO := 'TFSPER';
      SELECT C.CLI_PERFIL_RIESGO, P.PER_NOMBRE||' '||P.PER_PRIMER_APELLIDO||' '||P.PER_SEGUNDO_APELLIDO
      INTO   PERFIL, NOMBRE_CLIENTE
      FROM   CLIENTES C, PERSONAS P
      WHERE  C.CLI_PER_NUM_IDEN = P.PER_NUM_IDEN
      AND    C.CLI_PER_TID_CODIGO = P.PER_TID_CODIGO
      AND    C.CLI_PER_NUM_IDEN = R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
      AND    C.CLI_PER_TID_CODIGO = R_IPD.IPD_CCC_CLI_PER_TID_CODIGO;

      AUTORIZADO :=	P_CLIENTES.AutorizaColocacionOrdenPerfil(PRODUCTO,
                                                             'INC', --:BK_CUEFON.RG_OPERACION,
                                                             'NA',
                                                             'N',
                                                             PERFIL,
                                                             'N',
                                                             'N');
      IF AUTORIZADO = 'N' THEN
         RAISE E_PERFIL_RIESGO; --Se esta ingresando una orden que no corresponde al perfil de riesgo registrado para su cliente. Para poder continuar con el proceso de registro de esta operacion, debe modificar el perfil de su cliente
      END IF;
   END IF;
   --FIN HROSAS

   V_PROCESO := 'HRLIM';
   OPEN HORA_LIMITE(89,R_IPD.IPD_CFO_FON_CODIGO);
   FETCH HORA_LIMITE INTO HORA;
   IF TO_CHAR(SYSDATE,'HH24:MI') > HORA.PFO_RANGO_MAX_CHAR THEN
      V_FECHA_EJECUCION := TRUNC(P_TOOLS.SUMAR_HABILES_A_FECHA(sysdate,1)); --VAGTUS046880
   ELSE
      V_FECHA_EJECUCION := TRUNC(SYSDATE);
   END IF;
   CLOSE HORA_LIMITE;

   V_PROCESO := 'INSOFO';
   INSERT INTO ORDENES_FONDOS
      (OFO_CONSECUTIVO
      ,OFO_SUC_CODIGO
      ,OFO_CFO_CCC_CLI_PER_NUM_IDEN
      ,OFO_CFO_CCC_CLI_PER_TID_CODIGO
      ,OFO_CFO_CCC_NUMERO_CUENTA
      ,OFO_CFO_FON_CODIGO
      ,OFO_CFO_CODIGO
      ,OFO_EOF_CODIGO
      ,OFO_PER_NUM_IDEN
      ,OFO_PER_TID_CODIGO
      ,OFO_TTO_TOF_CODIGO
      ,OFO_TTO_TIT_CODIGO
      ,OFO_FECHA_CAPTURA
      ,OFO_MONTO
      ,OFO_CARGO_ABONO_CUENTA
      ,OFO_MONTO_CARGO_ABONO_CUENTA
      ,OFO_MONTO_ABONO_CUENTA_DOLARES
      ,OFO_FECHA_MODIFICACION
      ,OFO_MODIFICACION
      ,OFO_FECHA_EJECUCION
      ,OFO_IMPRIME_REC_DERECHOS
      ,OFO_PER_NUM_IDEN_COLOCO
      ,OFO_PER_TID_CODIGO_COLOCO
      ,OFO_REINVERSION
      ,OFO_AUTORIZACION
      ,OFO_ORIGEN_RECURSOS
      ,OFO_DESCRIPCION)
   VALUES
      (V_OFO_CONSECUTIVO
      ,P_SUC_CODIGO
      ,R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
      ,R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
      ,R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
      ,V_FON_CODIGO_ACT                  -- R_IPD.IPD_CFO_FON_CODIGO -- OFO_CFO_FON_CODIGO -- AJUSTE VAGTUD991
      ,R_IPD.IPD_CFO_CODIGO
      ,'APL'                             --OFO_EOF_CODIGO
      ,P_CCC_PER_NUM_IDEN
      ,P_CCC_PER_TID_CODIGO
      ,V_ING_INC                         --OFO_TTO_TOF_CODIGO
      ,'CAR'                             --OFO_TTO_TIT_CODIGO
      ,SYSDATE                           --OFO_FECHA_CAPTURA
      ,P_MONTO_POR_CAUSAR                --OFO_MONTO
      ,'S'                               --OFO_CARGO_ABONO_CUENTA
      ,P_MONTO_POR_CAUSAR                --OFO_MONTO_CARGO_ABONO_CUENTA
      ,NULL                              --OFO_MONTO_ABONO_CUENTA_DOLARES
      ,SYSDATE                           --OFO_FECHA_MODIFICACION
      ,P_PER_NOMBRE_USUARIO              --OFO_MODIFICACION
      ,V_FECHA_EJECUCION                    --OFO_FECHA_EJECUCION
      ,'S'                               --OFO_IMPRIME_REC_DERECHOS
      ,R_COLOCO.PER_NUM_IDEN             --OFO_PER_NUM_IDEN_COLOCO
      ,R_COLOCO.PER_TID_CODIGO           --OFO_PER_TID_CODIGO_COLOCO
      ,NULL                              --OFO_REINVERSION
      ,V_AUTORIZACION
      ,'I'
      ,'SYS_PROGRAMADO');

   V_PROCESO := 'CARCTA';
   OPEN C_TIPO_CARGO_CUENTA;
   FETCH C_TIPO_CARGO_CUENTA INTO TIU1;
   IF C_TIPO_CARGO_CUENTA%NOTFOUND THEN
      CLOSE C_TIPO_CARGO_CUENTA;
      RAISE E_ERROR_CARGO;
   END IF;
   CLOSE C_TIPO_CARGO_CUENTA;

   V_PROCESO := 'INSDAU';
   INSERT INTO DETALLES_CARGOS_CUENTAS
      (DAU_CONSECUTIVO
      ,DAU_SUC_CODIGO
      ,DAU_NEG_CONSECUTIVO
      ,DAU_TIU_MNEMONICO
      ,DAU_VALOR
      ,DAU_OFO_CONSECUTIVO
      ,DAU_OFO_SUC_CODIGO
      ,DAU_ORD_CONSECUTIVO
      ,DAU_ORD_SUC_CODIGO
      ,DAU_PCC_CONSECUTIVO)
   VALUES
      (DAU_SEQ.NEXTVAL
      ,P_SUC_CODIGO
      ,2
      ,TIU1.TIU_MNEMONICO
      ,P_MONTO_POR_CAUSAR
      ,V_OFO_CONSECUTIVO
      ,P_SUC_CODIGO
      ,NULL
      ,NULL
      ,NULL);


   IF P_PRODUCTO = 'ADVAL' THEN
      V_PROCESO := 'CAUADVAL';
      P_ADMON_SALDOS.PR_CAUSAR_ADMON_VALORES
         (P_CLI_NUM_IDEN    => R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
         ,P_CLI_TID_CODIGO  => R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
         ,P_CUENTA          => R_IPD.IPD_CCC_NUMERO_CUENTA
         ,P_MONTO           => P_MONTO_POR_CAUSAR
         ,P_MONTO_IMGF      => 0
         ,P_SUC_CODIGO      => P_SUC_CODIGO
         ,P_NEG_CONS        => 2
         ,P_INSERTA_DAA     => 'S'
         ,P_DAA_ODP         => 'DAA'
         ,P_TIPO_TAC        => R_IPD.IPD_TAC_MNEMONICO
         ,P_DAA_CONS        => NULL
         ,P_ODP_CONS        => NULL
         ,P_TRAS_FONDOS     => 'S'
         ,P_OFO_SUC_CODIGO  => P_SUC_CODIGO
         ,P_OFO_CONSECUTIVO => V_OFO_CONSECUTIVO
         ,P_FON_CODIGO      => V_FON_CODIGO_ACT    -- R_IPD.IPD_CFO_FON_CODIGO -- AJUSTES VAGTUD991
         ,P_CFO_CODIGO      => R_IPD.IPD_CFO_CODIGO
         ,P_CUD_DECEVAL     => NULL);
   ELSIF P_PRODUCTO = 'OB' THEN
      V_PROCESO := 'CAUOPBUR';
      P_ADMON_SALDOS.PR_CAUSAR_OPE_BURSATIL
         (P_CLI_NUM_IDEN    => R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
         ,P_CLI_TID_CODIGO  => R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
         ,P_CUENTA          => R_IPD.IPD_CCC_NUMERO_CUENTA
         ,P_MONTO           => P_MONTO_POR_CAUSAR
         ,P_MONTO_IMGF      => 0
         ,P_SUC_CODIGO      => P_SUC_CODIGO
         ,P_NEG_CONS        => 2
         ,P_INSERTA_DAA     => 'S'
         ,P_DAA_ODP         => 'DAA'
         ,P_TIPO_TAC        => R_IPD.IPD_TAC_MNEMONICO
         ,P_DAA_CONS        => NULL
         ,P_ODP_CONS        => NULL
         ,P_TRAS_FONDOS     => 'S'
         ,P_OFO_SUC_CODIGO  => P_SUC_CODIGO
         ,P_OFO_CONSECUTIVO => V_OFO_CONSECUTIVO
         ,P_FON_CODIGO      => V_FON_CODIGO_ACT    -- R_IPD.IPD_CFO_FON_CODIGO -- AJUSTES VAGTUD991
         ,P_CFO_CODIGO      => R_IPD.IPD_CFO_CODIGO
         ,P_PRO_MNEMONICO   => 'OB');
   END IF;

   IF R_IPD.IPD_CCC_NUMERO_CUENTA != R_IPD.IPD_CFO_CCC_NUMERO_CUENTA THEN
      V_PROCESO := 'MOVTRANS';
      P_ADMON_SALDOS.PR_MOVIMIENTOS_TRANSFERENCIA
                 (P_CLI_NUM_IDEN_ORI   =>  R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
                 ,P_CLI_TID_CODIGO_ORI =>  R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
                 ,P_CUENTA_ORI         =>  R_IPD.IPD_CCC_NUMERO_CUENTA
                 ,P_CLI_NUM_IDEN_DES   =>  R_IPD.IPD_CCC_CLI_PER_NUM_IDEN
                 ,P_CLI_TID_CODIGO_DES =>  R_IPD.IPD_CCC_CLI_PER_TID_CODIGO
                 ,P_CUENTA_DES         =>  R_IPD.IPD_CFO_CCC_NUMERO_CUENTA
                 ,P_MONTO              =>  P_MONTO_POR_CAUSAR
                 ,P_REVERSION          => 'N'
                 ,P_FONDO_CUENTA       => 'C');
   END IF;

   IF TRUNC(V_FECHA_EJECUCION) <= TRUNC(SYSDATE) THEN
      V_PROCESO := 'NOCCONFORD';
      P_PROCESOS_NOCTURNOS.P_CONFIRMA_ORDEN_FONDOS
      (FECHA_PROCESO      => SYSDATE
      ,P_SUC_CODIGO       => P_SUC_CODIGO
      ,P_ORDEN            => V_OFO_CONSECUTIVO);
   END IF;

   V_PROCESO := 'FINAL';
   P_OFO_CONS :=  V_OFO_CONSECUTIVO;
   P_OFO_SUC  :=  P_SUC_CODIGO;

   P_GENERO := 'OK';
   P_DETALLE := 'ORDEN FONDOS: SUC '||P_SUC_CODIGO||' - ORDEN '||V_OFO_CONSECUTIVO;


EXCEPTION
   WHEN E_INGRESO THEN
      ROLLBACK TO SV_FONDO_NOCTURNO; -- se modifica de ROLLBACK a ROLLBACK TO -- arreglo INC1333630
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('El monto de la orden, esta por fuera del rango para Incrementos del Fondo '|| V_FON_CODIGO_ACT,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'El monto de la orden, esta por fuera del rango para Incrementos del Fondo '|| R_IPD.IPD_CFO_FON_CODIGO
                       ,P_TABLA_ERROR => NULL);
   WHEN E_ERROR THEN
      ROLLBACK TO SV_FONDO_NOCTURNO; -- se modifica de ROLLBACK a ROLLBACK TO -- arreglo INC1333630
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('El valor de la orden es menor al saldo minimo del fondo ('||TO_CHAR(R_PFO_I.PFO_RANGO_MIN_NUMBER,'999,999,999,999,999.00'),1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'El valor de la orden es menor al saldo minimo del fondo ('||TO_CHAR(R_PFO_I.PFO_RANGO_MIN_NUMBER,'999,999,999,999,999.00')||')'
                       ,P_TABLA_ERROR => NULL);
   WHEN E_ERRORM THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No se encuentra valor de saldo minimo en el fondo',1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No se encuentra valor de saldo minimo en el fondo'
                       ,P_TABLA_ERROR => NULL);
   WHEN E_ERRORC THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('El valor de la orden es menor al saldo minimo del compartimento ('||TO_CHAR(V_MINIMO_INVERSION,'999,999,999,999,999.00')||')',1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'El valor de la orden es menor al saldo minimo del compartimento ('||TO_CHAR(V_MINIMO_INVERSION,'999,999,999,999,999.00')||')'
                       ,P_TABLA_ERROR => NULL);
   WHEN E_ERROR_COT THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No existe cotizacion para el fondo en este dia',1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No existe cotizacion para el fondo en este dia'
                       ,P_TABLA_ERROR => NULL);
   WHEN E_ERROR_L THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('Valor minimo de ingreso en el compartimento es:'||TO_CHAR(V_MINIMO_INVERSION,'999,999,999,999,999.00'),1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'Valor minimo de ingreso en el compartimento es:'||TO_CHAR(V_MINIMO_INVERSION,'999,999,999,999,999.00')
                       ,P_TABLA_ERROR => NULL);
   WHEN E_PARAMETRO THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No se encuentra parametro de Ingreso/Incremento para el fondo '||R_IPD.IPD_CFO_FON_CODIGO,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No se encuentra parametro de Ingreso/Incremento para el fondo '||R_IPD.IPD_CFO_FON_CODIGO
                       ,P_TABLA_ERROR => NULL);
   WHEN E_PARAMETRO_P THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No se encuentra parametro 71 para el fondo '||R_IPD.IPD_CFO_FON_CODIGO,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No se encuentra Fondo Principal para el fondo '||R_IPD.IPD_CFO_FON_CODIGO
                       ,P_TABLA_ERROR => NULL);

   -- AJUSTE VAGTUD991
   WHEN NO_PART_ACT THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No se encontro la participacion activa '||R_IPD.IPD_CONSECUTIVO,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No se encuentra la participacion activa '||R_IPD.IPD_CFO_FON_CODIGO
                       ,P_TABLA_ERROR => NULL);

   WHEN NO_APO_APT_D THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('Cuenta es APT no tiene cuenta en la participacion D '||R_IPD.IPD_CONSECUTIVO,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No tiene cuenta en la Part. D '||V_FON_CODIGO_ACT
                       ,P_TABLA_ERROR => NULL);
   ---
   WHEN E_COLOCO THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No se encontro identificacion para el usuario '||USER,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'No se encontro identificacion para el usuario '||USER
                       ,P_TABLA_ERROR => NULL);
   WHEN E_INGRESO_O THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('El monto de la Orden no puede ser menor a '||TO_CHAR(R_PFO.PFO_RANGO_MIN_NUMBER, '999,999,999,999,999.00')||
    			                    ' ni mayor a '||TO_CHAR(R_PFO.PFO_RANGO_MAX_NUMBER, '999,999,999,999,999.00'),1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                         'El monto de la Orden no puede ser menor a '||TO_CHAR(R_PFO.PFO_RANGO_MIN_NUMBER, '999,999,999,999,999.00')||
    			                               ' ni mayor a '||TO_CHAR(R_PFO.PFO_RANGO_MAX_NUMBER, '999,999,999,999,999.00')
                       ,P_TABLA_ERROR => NULL);
   WHEN E_EXISTE_ORDEN THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      IF OFO1.OFO_EOF_CODIGO IN ('COL','APL') THEN
         P_DESCRIPCION := SUBSTR('Cliente tiene una orden de ' || OFO1.OFO_TTO_TOF_CODIGO
                                            || ' en estado COLOCADO o APLAZADO en el fondo. No puede crear nueva orden',1,199);
         INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                          ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                            'Cliente tiene una orden de ' || OFO1.OFO_TTO_TOF_CODIGO
                                            || ' en estado COLOCADO o APLAZADO en el fondo. No puede crear nueva orden'
                           ,P_TABLA_ERROR => NULL);
      ELSE
         P_DESCRIPCION := SUBSTR('Cliente tiene una orden de ' || OFO1.OFO_TTO_TOF_CODIGO
                                            || ' en el fondo que tiene que ser ejecutada. No puede crear nueva orden',1,199);
         INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                          ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||
                                            'Cliente tiene una orden de ' || OFO1.OFO_TTO_TOF_CODIGO
                                            || ' en el fondo que tiene que ser ejecutada. No puede crear nueva orden'
                           ,P_TABLA_ERROR => NULL);
      END IF;
   WHEN E_PERFIL_RIESGO THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      SELECT DECODE(PERFIL,10,'MODERADO',20,'CONSERVADOR',30,'ARRIESGADO','NO_VALIDO')
      INTO   PERFIL_RIES
      FROM   DUAL;
      P_DESCRIPCION := SUBSTR('Se esta ingresando una orden que no corresponde al perfil de riesgo registrado para el cliente',1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'PERFIL RIESGO - CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||' '||
                                           'Se esta ingresando una orden que no corresponde al perfil de riesgo registrado para el cliente'
                       ,P_TABLA_ERROR => NULL);
   WHEN E_ERROR_CARGO THEN
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := SUBSTR('No se encontro el concepto de detalle cargo cuenta para el producto ' || P_PRODUCTO,1,199);
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGO PROGRAMADO - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => 'CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||' '||
                                         'No se encontro el concepto de detalle cargo cuenta para el producto ' || P_PRODUCTO
                       ,P_TABLA_ERROR => NULL);
   WHEN OTHERS THEN
      ERRORSQL := SUBSTR(SQLERRM,1,199);
      ROLLBACK TO SV_FONDO_NOCTURNO;
      P_OFO_CONS :=  NULL;
      P_OFO_SUC  :=  NULL;
      P_DESCRIPCION := ERRORSQL;
      INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS - ORDEN_FONDO_AUTOMATICA'
                       ,P_ERROR       => V_PROCESO||' CLIENTE '||R_IPD.IPD_CCC_CLI_PER_NUM_IDEN||'-'||R_IPD.IPD_CCC_CLI_PER_TID_CODIGO||'-'||R_IPD.IPD_CCC_NUMERO_CUENTA||' '||SUBSTR(SQLERRM,1,350)
                       ,P_TABLA_ERROR => NULL);
END ORDEN_FONDO_NOCTURNO;

--------------------------------------------------------------------------------

PROCEDURE ABONO_CUENTA_NOCTURNO ( P_CCC_CLI_PER_NUM_IDEN   VARCHAR2
                        ,P_CCC_CLI_PER_TID_CODIGO VARCHAR2
                        ,P_CCC_NUMERO_CUENTA      NUMBER
                        ,P_SUC_CODIGO         NUMBER
                        ,P_PER_NOMBRE_USUARIO VARCHAR2


                        ,P_CONSECUTIVO NUMBER
                        ,P_MONTO_POR_CAUSAR NUMBER)  IS

   P_GENERO VARCHAR2(2);
   P_DETALLE VARCHAR2(100);

   CURSOR C_IPD IS
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
            ,IPD_CCC_CLI_PER_TID_CODIGO
            ,IPD_CCC_NUMERO_CUENTA
            ,IPD_TAC_MNEMONICO
      FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE IPD_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
        AND IPD_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
        AND IPD_CCC_NUMERO_CUENTA  = P_CCC_NUMERO_CUENTA
		AND IPD_CONSECUTIVO = P_CONSECUTIVO;
   R_IPD C_IPD%ROWTYPE;

   CURSOR C_SALDO IS
      SELECT MCC_SALDO_ADMON_VALORES
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
      AND    MCC_FECHA < TRUNC(SYSDATE)
      ORDER BY MCC_CONSECUTIVO DESC;
   MCC1   C_SALDO%ROWTYPE;

   CURSOR C_MOVIMIENTO IS
      SELECT SUM(MCC_MONTO_ADMON_VALORES) ADMON
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
      AND    MCC_FECHA >= TRUNC(SYSDATE);

   FECHA1         DATE;
   CONSECUTIVO    NUMBER(10);
   TOTAL_SERVICIO NUMBER;
   TOTAL_DIA_ADMON  NUMBER;
   NVOCONS				  NUMBER;
   ERRORSQL VARCHAR2(100);
   YA_CAUSO EXCEPTION;
BEGIN
   P_GENERO := '';
   P_DETALLE := '';

	    OPEN C_IPD;
	    FETCH C_IPD INTO R_IPD;
	    CLOSE C_IPD;

      OPEN C_SALDO;
      FETCH C_SALDO INTO MCC1;
      CLOSE C_SALDO;
      MCC1.MCC_SALDO_ADMON_VALORES := NVL(MCC1.MCC_SALDO_ADMON_VALORES,0);

      OPEN C_MOVIMIENTO;
      FETCH C_MOVIMIENTO INTO TOTAL_DIA_ADMON;
      CLOSE C_MOVIMIENTO;
      TOTAL_DIA_ADMON := NVL(TOTAL_DIA_ADMON,0);

      MCC1.MCC_SALDO_ADMON_VALORES := MCC1.MCC_SALDO_ADMON_VALORES + TOTAL_DIA_ADMON;

      IF MCC1.MCC_SALDO_ADMON_VALORES < P_MONTO_POR_CAUSAR THEN
      	 P_GENERO := 'NO';
   	     P_DETALLE := 'El total de la causacion o parte de ella ya fue causada por otro usuario.';
   	     RAISE YA_CAUSO;
      END IF;


    SELECT DAA_SEQ.NEXTVAL INTO CONSECUTIVO FROM DUAL;
         INSERT INTO DETALLES_ABONOS_CUENTAS
            (     DAA_SUC_CODIGO
                 ,DAA_NEG_CONSECUTIVO
                 ,DAA_CONSECUTIVO
                 ,DAA_TAC_MNEMONICO
                 ,DAA_VALOR)
         VALUES ( P_SUC_CODIGO
                 ,2
                 ,CONSECUTIVO
                 ,R_IPD.IPD_TAC_MNEMONICO
                 ,P_MONTO_POR_CAUSAR);


         SELECT MCC_SEQ.NEXTVAL INTO NVOCONS FROM DUAL;

         INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
                 ( MCC_CONSECUTIVO
                  ,MCC_CCC_CLI_PER_NUM_IDEN
                  ,MCC_CCC_CLI_PER_TID_CODIGO
                  ,MCC_CCC_NUMERO_CUENTA
                  ,MCC_FECHA
                  ,MCC_TMC_MNEMONICO
                  ,MCC_MONTO
                  ,MCC_MONTO_A_CONTADO
                  ,MCC_MONTO_A_PLAZO
                  ,MCC_MONTO_ADMON_VALORES)
         values ( nvocons
                  ,P_CCC_CLI_PER_NUM_IDEN
                  ,P_CCC_CLI_PER_TID_CODIGO
                  ,P_CCC_NUMERO_CUENTA
                 ,SYSDATE
                 ,'CPDV'
                 ,P_MONTO_POR_CAUSAR
                 ,0
                 ,0
                 ,-P_MONTO_POR_CAUSAR);

         INSERT INTO PAGOS_ADMON_VALORES
                 (PAV_CONSECUTIVO
                 ,PAV_MONTO
                 ,PAV_ANULADO
                 ,PAV_MCC_CONSECUTIVO
                 ,PAV_DAA_SUC_CODIGO
                 ,PAV_DAA_NEG_CONSECUTIVO
                 ,PAV_DAA_CONSECUTIVO)
         VALUES ( PAV_SEQ.NEXTVAL
                 ,P_MONTO_POR_CAUSAR
                 ,'N'
                 ,NVOCONS
                 ,P_SUC_CODIGO
                 ,2
                 ,CONSECUTIVO);

         P_GENERO := 'OK';
         P_DETALLE := 'ABONO CUENTA';

         INSERT INTO PAGOS_AUTOMATICOS_DIVIDENDOS (
                     PAD_CONSECUTIVO
                    ,PAD_FECHA
                    ,PAD_TIPO
                    ,PAD_CCC_CLI_PER_NUM_IDEN
                    ,PAD_CCC_CLI_PER_TID_CODIGO
                    ,PAD_CCC_NUMERO_CUENTA
                    ,PAD_USUARIO
                    ,PAD_TERMINAL
                    ,PAD_DAA_CONSECUTIVO
                    ,PAD_DAA_SUC_CODIGO
                    ,PAD_DAA_NEG_CONSECUTIVO
                    )
         VALUES (  PAD_SEQ.NEXTVAL
                  ,SYSDATE
                  ,'A'
                  ,P_CCC_CLI_PER_NUM_IDEN
                  ,P_CCC_CLI_PER_TID_CODIGO
                  ,P_CCC_NUMERO_CUENTA
                  ,P_PER_NOMBRE_USUARIO
                  ,NVL(FN_TERMINAL,'NOCTURNO')
                  ,CONSECUTIVO
                  ,P_SUC_CODIGO
                  ,2);

        COMMIT;


EXCEPTION


   when ya_causo then
      --CLOSE C_CCC;
      ROLLBACK;
      inserta_error_div ( p_proceso     => 'PAGOS DIVIDENDOS - ABONO_CUENTA'
                         ,P_ERROR       => 'CLIENTE '||P_CCC_CLI_PER_NUM_IDEN||'-'||P_CCC_CLI_PER_TID_CODIGO||'-'||P_CCC_NUMERO_CUENTA||' '||
                                           'El total de la causacion o parte de ella ya fue causada por otro usuario.'
                         ,P_TABLA_ERROR => NULL);



   when others then
      --CLOSE C_CCC;
      ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);
      p_pagos_dividendos.inserta_error_div ( p_proceso     => 'PAGOS DIVIDENDOS - ABONO CUENTA'
                                            ,P_ERROR       => 'CLIENTE '||P_CCC_CLI_PER_NUM_IDEN||'-'||P_CCC_CLI_PER_TID_CODIGO||'-'||P_CCC_NUMERO_CUENTA||' '||SUBSTR(SQLERRM,1,350)
                                            ,P_TABLA_ERROR => NULL);

END ABONO_CUENTA_NOCTURNO;

--------------------------------------------------------------------------------

PROCEDURE MARCAR_MCC_INSTRUCCION_PAGO ( P_CLI_PER_NUM_IDEN VARCHAR2
                        ,P_CLI_PER_TID_CODIGO VARCHAR2
                        ,P_CCC_NUMERO_CUENTA NUMBER
                        ,P_CONSECUTIVO NUMBER
                        ,P_TIPO_INSTRUCCION_PAGO VARCHAR2
                    )
IS
	CURSOR DETALLES_INSTRUCCION (IPD_CONSECUTIVO NUMBER) IS
    SELECT IDD_ENA_MNEMONICO
    FROM INST_PAGOS_DIVIDENDOS_DETALLES
    WHERE IDD_IPD_CONSECUTIVO = IPD_CONSECUTIVO;

  R_DETALLES_INSTRUCCION  DETALLES_INSTRUCCION%ROWTYPE;
BEGIN
IF P_CONSECUTIVO = -1 THEN
    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
    SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
        MCC_FECHA_TIPO_INST_PAGO = SYSDATE
    WHERE MCC_CCC_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
            AND MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
            AND MCC_CCC_NUMERO_CUENTA      = P_CCC_NUMERO_CUENTA
            AND (EXISTS (SELECT 'X'
                         FROM TIPOS_MOVIMIENTO_CORREDORES
                         WHERE TMC_MNEMONICO = MCC_TMC_MNEMONICO
                           AND TMC_ANE_MNEMONICO IN ('AV','BI'))
                 OR ( MCC_TMC_MNEMONICO IN ('ABO','CAR')
                      AND (MCC_CFC_FUG_ISI_MNEMONICO  IS NOT NULL OR MCC_TLO_CODIGO IS NOT NULL)))
            AND NVL(MCC_TIPO_INSTRUCCION_PAGO,'N') = 'N';
  ELSE
    OPEN DETALLES_INSTRUCCION(IPD_CONSECUTIVO => P_CONSECUTIVO);
          FETCH DETALLES_INSTRUCCION INTO R_DETALLES_INSTRUCCION;
     IF DETALLES_INSTRUCCION%NOTFOUND THEN
        UPDATE MOVIMIENTOS_CUENTA_CORREDORES
        SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
            MCC_FECHA_TIPO_INST_PAGO = SYSDATE
        WHERE MCC_CCC_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
            AND MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
            AND MCC_CCC_NUMERO_CUENTA      = P_CCC_NUMERO_CUENTA
            AND (EXISTS (SELECT 'X'
                         FROM TIPOS_MOVIMIENTO_CORREDORES
                         WHERE TMC_MNEMONICO = MCC_TMC_MNEMONICO
                           AND TMC_ANE_MNEMONICO IN ('AV','BI'))
                 OR ( MCC_TMC_MNEMONICO IN ('ABO','CAR')
                      AND (MCC_CFC_FUG_ISI_MNEMONICO  IS NOT NULL OR MCC_TLO_CODIGO IS NOT NULL)))
            AND NVL(MCC_TIPO_INSTRUCCION_PAGO,'N') = 'N';
     ELSE
         CLOSE DETALLES_INSTRUCCION;
         FOR DETALLES_INSTRUCCION_REC IN
                 DETALLES_INSTRUCCION
                    (IPD_CONSECUTIVO => P_CONSECUTIVO) LOOP
            UPDATE MOVIMIENTOS_CUENTA_CORREDORES
            SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                MCC_FECHA_TIPO_INST_PAGO = SYSDATE
            WHERE MCC_CCC_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
                AND MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                AND MCC_CCC_NUMERO_CUENTA      = P_CCC_NUMERO_CUENTA
                AND (MCC_TMC_MNEMONICO IN ('ABD','ABO','CAR','ABRE','SAV','RIC','IAV')
                AND EXISTS (SELECT 'X'
                              FROM  FUNGIBLES
                              WHERE FUG_ISI_MNEMONICO = MCC_CFC_FUG_ISI_MNEMONICO
                                AND FUG_MNEMONICO = MCC_CFC_FUG_MNEMONICO
                                AND FUG_TIPO = 'ACC'
                                AND FUG_ENA_MNEMONICO = DETALLES_INSTRUCCION_REC.IDD_ENA_MNEMONICO))
                AND NVL(MCC_TIPO_INSTRUCCION_PAGO,'N') = 'N';
          END LOOP;
     END IF;
     CLOSE DETALLES_INSTRUCCION;
  END IF;
  COMMIT;
END MARCAR_MCC_INSTRUCCION_PAGO;

--------------------------------------------------------------------------------
--HROSAS, REQ VAGTUD326 - Perfil Riesgo
PROCEDURE MAIL_PERFIL_RIESGO IS
  MENSAJE VARCHAR2(400);
  DESTINATARIOS VARCHAR2(100);
  CONN                      UTL_SMTP.CONNECTION;
  DIRECCION                 VARCHAR2(1000);
  LINEA                     VARCHAR2(1000);
  SEPARADOR                 VARCHAR2(1) := ';';
  CRLF                      VARCHAR2(2) :=  CHR(13)||CHR(10);
  MSJ                       CLOB;
  BAND                      NUMBER := 0;
BEGIN

  MSJ:='En el proceso de Pagos Programados se esta generando ordenes de traslado a Fondos para clientes que no cumplen con el perfil de riesgo. Para poder generar la orden se debe modificar el perfil para los siguientes clientes:'||CRLF||CRLF;

  FOR I IN (SELECT E.EPD_TABLA
              FROM ERRORES_PROCESOS_DIVIDENDOS E
             WHERE E.EPD_FECHA_ERROR > TRUNC(SYSDATE)
               AND E.EPD_ERROR LIKE ('PERFIL RIESGO%'))LOOP
      MSJ := MSJ||I.EPD_TABLA||CRLF;
      BAND := 1;
  END LOOP;
  IF BAND = 1 THEN
    DIRECCION := 'cramirez@corredores.com,procesosnocturnos@corredores.com';
    CONN := P_MAIL.BEGIN_MAIL(SENDER => 'administrador@corredores.com',
                              RECIPIENTS => DIRECCION,
                              SUBJECT    => 'Pagos Programados - Ordenes de Traslados Canceladas por Perfil de Riesgo',
                              MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);

    P_MAIL.BEGIN_ATTACHMENT(CONN => CONN,
                            MIME_TYPE    => 'PRUEBA'||'/TXT',
                            INLINE       => TRUE,
                            FILENAME     => 'PRUEBA'||'.TXT',
                            TRANSFER_ENC => 'TEXT');

    LINEA := 'TIPO IDENT.';


    P_MAIL.WRITE_MB_TEXT(CONN,MSJ||CRLF);
    P_MAIL.END_ATTACHMENT( CONN => CONN );
    P_MAIL.END_MAIL( CONN => CONN );
  END IF;
END MAIL_PERFIL_RIESGO;
--FIN HROSAS


FUNCTION FN_SALDO_DIV_CLIENTE
   ( P_IPD_CONS INSTRUCCIONES_PAGOS_DIVIDENDOS.IPD_CONSECUTIVO%TYPE
    ) RETURN NUMBER IS

   CURSOR INSTRUCCIONES IS
      SELECT IPD_CONSECUTIVO,
             IPD_CCC_CLI_PER_NUM_IDEN,
             IPD_CCC_CLI_PER_TID_CODIGO,
             IPD_CCC_NUMERO_CUENTA,
             IPD_MONTO_MINIMO,
             IPD_TIPO_ORIGEN_PAGO,
             IPD_TIPO_EMISOR,
             IPD_GIRO_OTRA_CIUDAD
      FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE IPD_CONSECUTIVO = P_IPD_CONS;

  CURSOR DETALLES_INSTRUCCION IS
    SELECT DIPA_FUG_MNEMONICO ,DIPA_FUG_ISI_MNEMONICO
    FROM DETALLE_INSTRUCCIONES_PAGOS
    WHERE DIPA_IPD_CONSECUTIVO = P_IPD_CONS;

   CURSOR C_MCC_ALL (P_NID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER) IS
      SELECT SUM(MCC_MONTO_ADMON_VALORES)- SUM(MCC_MONTO_PAGADO) MCC_MONTO_ADMON_VALORES
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
        AND MCC_CCC_NUMERO_CUENTA = P_CTA
        AND (EXISTS (SELECT 'X'
                     FROM TIPOS_MOVIMIENTO_CORREDORES
                     WHERE TMC_MNEMONICO = MCC_TMC_MNEMONICO
                       AND TMC_MNEMONICO NOT IN ('MIGDA','MIGEC','MSADV')
                       AND TMC_ANE_MNEMONICO IN ('AV','BI'))
             OR ( MCC_TMC_MNEMONICO IN ('ABO','CAR')
                  AND MCC_CFC_FUG_ISI_MNEMONICO  IS NOT NULL))
        AND EXISTS (SELECT 'X'
                    FROM  FUNGIBLES
                    WHERE FUG_ISI_MNEMONICO = MCC_CFC_FUG_ISI_MNEMONICO
                      AND FUG_MNEMONICO = MCC_CFC_FUG_MNEMONICO
                      AND FUG_TIPO = 'ACC'
                    )
        AND NVL(MCC_PAGADO,'N') = 'N';
   MCC1 C_MCC_ALL%ROWTYPE;

   CURSOR C_MCC_ISIN (P_NID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_FUG NUMBER, P_ISIN VARCHAR2) IS
      SELECT SUM(MCC_MONTO_ADMON_VALORES) - SUM(MCC_MONTO_PAGADO) MCC_MONTO_ADMON_VALORES
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
        AND MCC_CCC_NUMERO_CUENTA = P_CTA
        AND (EXISTS (SELECT 'X'
                     FROM TIPOS_MOVIMIENTO_CORREDORES
                     WHERE TMC_MNEMONICO = MCC_TMC_MNEMONICO
                       AND TMC_MNEMONICO NOT IN ('MIGDA','MIGEC','MSADV')
                       AND TMC_ANE_MNEMONICO IN ('AV','BI'))
             OR ( MCC_TMC_MNEMONICO IN ('ABO','CAR')
                  AND MCC_CFC_FUG_ISI_MNEMONICO  IS NOT NULL))
        AND EXISTS (SELECT 'X'
                    FROM  FUNGIBLES
                    WHERE FUG_ISI_MNEMONICO = MCC_CFC_FUG_ISI_MNEMONICO
                      AND FUG_MNEMONICO = MCC_CFC_FUG_MNEMONICO
                      AND FUG_TIPO = 'ACC'
                    )
        AND NVL(MCC_PAGADO,'N') = 'N'
        AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
        AND MCC_CFC_FUG_MNEMONICO = P_FUG;
   MCC2 C_MCC_ISIN%ROWTYPE;

   V_MONTO_PAGO NUMBER := 0;
   V_MONTO_PAGO_PARCIAL NUMBER := 0;

BEGIN
   FOR INSTRUCCIONES_REC IN INSTRUCCIONES  LOOP
      V_MONTO_PAGO := 0;
      IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'DI' THEN
         IF INSTRUCCIONES_REC.IPD_TIPO_EMISOR = 'T' THEN
            OPEN C_MCC_ALL(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN,
                           INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO,
                           INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA) ;
            FETCH C_MCC_ALL INTO MCC1;
            CLOSE C_MCC_ALL;
            V_MONTO_PAGO := NVL(MCC1.MCC_MONTO_ADMON_VALORES, 0);
         ELSE
            FOR DETALLES_INSTRUCCION_REC IN DETALLES_INSTRUCCION  LOOP
               OPEN C_MCC_ISIN (INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN,
                                INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO,
                                INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA,
                                DETALLES_INSTRUCCION_REC.DIPA_FUG_MNEMONICO,
                                DETALLES_INSTRUCCION_REC.DIPA_FUG_ISI_MNEMONICO );
               FETCH C_MCC_ISIN INTO MCC2;
               CLOSE C_MCC_ISIN;
               V_MONTO_PAGO_PARCIAL := NVL(MCC2.MCC_MONTO_ADMON_VALORES, 0);
               V_MONTO_PAGO := V_MONTO_PAGO + V_MONTO_PAGO_PARCIAL;
            END LOOP;
         END IF;
      END IF;
   END LOOP;
   RETURN NVL(V_MONTO_PAGO,0);

END FN_SALDO_DIV_CLIENTE;
--------------------------------------------------------------------------------
PROCEDURE MARCAR_MCC_INSTRUCCION_PAGO_N
                ( P_IPD_CONS INSTRUCCIONES_PAGOS_DIVIDENDOS.IPD_CONSECUTIVO%TYPE
                 ,P_TIPO_INSTRUCCION_PAGO VARCHAR2
                 ,P_SALDO       NUMBER
                 ,P_ODP_CONS    ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_ODP_SUC     ORDENES_DE_PAGO.ODP_SUC_CODIGO%TYPE DEFAULT NULL
                 ,P_ODP_NEG     ORDENES_DE_PAGO.ODP_NEG_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_OFO_CONS    ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_OFO_SUC     ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE DEFAULT NULL
                 ,P_POD         VARCHAR2 DEFAULT 'N'
                 ,P_MDA_CONSECUTIVO MOVIMIENTOS_CLIENTE_DAVIVIENDA.MDA_CONSECUTIVO%TYPE DEFAULT NULL
                )
IS
   CURSOR INSTRUCCIONES IS
      SELECT IPD_CONSECUTIVO,
             IPD_CCC_CLI_PER_NUM_IDEN,
             IPD_CCC_CLI_PER_TID_CODIGO,
             IPD_CCC_NUMERO_CUENTA,
             IPD_MONTO_MINIMO,
             IPD_TIPO_ORIGEN_PAGO,
             IPD_TIPO_EMISOR,
             IPD_GIRO_OTRA_CIUDAD
      FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE IPD_CONSECUTIVO = P_IPD_CONS;

  CURSOR DETALLES_INSTRUCCION IS
    SELECT DIPA_FUG_MNEMONICO ,DIPA_FUG_ISI_MNEMONICO
    FROM DETALLE_INSTRUCCIONES_PAGOS
    WHERE DIPA_IPD_CONSECUTIVO = P_IPD_CONS
    ORDER BY DIPA_CONSECUTIVO;

   CURSOR C_MCC_ALL (P_NID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_TIPO VARCHAR2) IS
      SELECT MCC_CONSECUTIVO,
             MCC_MONTO_ADMON_VALORES,
             MCC_MONTO_PAGADO,
             MCC_TIPO_INSTRUCCION_PAGO,
             MCC_FECHA_TIPO_INST_PAGO
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
        AND MCC_CCC_NUMERO_CUENTA = P_CTA
        AND (EXISTS (SELECT 'X'
                     FROM TIPOS_MOVIMIENTO_CORREDORES
                     WHERE TMC_MNEMONICO = MCC_TMC_MNEMONICO
                       AND TMC_ANE_MNEMONICO IN ('AV','BI'))
             OR ( MCC_TMC_MNEMONICO IN ('ABO','CAR')
                  AND MCC_CFC_FUG_ISI_MNEMONICO  IS NOT NULL))
        AND EXISTS (SELECT 'X'
                    FROM  FUNGIBLES
                    WHERE FUG_ISI_MNEMONICO = MCC_CFC_FUG_ISI_MNEMONICO
                      AND FUG_MNEMONICO = MCC_CFC_FUG_MNEMONICO
                      AND FUG_TIPO = 'ACC'
                    )
        AND NVL(MCC_PAGADO,'N') = 'N'
      ORDER BY MCC_CONSECUTIVO ASC;
   MCC1 C_MCC_ALL%ROWTYPE;

   CURSOR C_MCC_ISIN (P_NID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_FUG NUMBER, P_ISIN VARCHAR2) IS
      SELECT MCC_CONSECUTIVO,
             MCC_MONTO_ADMON_VALORES,
             MCC_MONTO_PAGADO,
             MCC_TIPO_INSTRUCCION_PAGO,
             MCC_FECHA_TIPO_INST_PAGO
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
        AND MCC_CCC_NUMERO_CUENTA = P_CTA
        AND (EXISTS (SELECT 'X'
                     FROM TIPOS_MOVIMIENTO_CORREDORES
                     WHERE TMC_MNEMONICO = MCC_TMC_MNEMONICO
                       AND TMC_ANE_MNEMONICO IN ('AV','BI'))
             OR ( MCC_TMC_MNEMONICO IN ('ABO','CAR')
                  AND MCC_CFC_FUG_ISI_MNEMONICO  IS NOT NULL))
        AND EXISTS (SELECT 'X'
                    FROM  FUNGIBLES
                    WHERE FUG_ISI_MNEMONICO = MCC_CFC_FUG_ISI_MNEMONICO
                      AND FUG_MNEMONICO = MCC_CFC_FUG_MNEMONICO
                      AND FUG_TIPO = 'ACC'
                    )
        AND MCC_CFC_FUG_MNEMONICO = P_FUG
        AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
        AND NVL(MCC_PAGADO,'N') = 'N'
      ORDER BY MCC_CONSECUTIVO ASC;
   MCC2 C_MCC_ISIN%ROWTYPE;

   V_MONTO_PAGO NUMBER := 0;
   V_MONTO_PAGO_PARCIAL NUMBER := 0;
   SALDO NUMBER;
   MONTO_PENDIENTE NUMBER := 0;
   VALOR  NUMBER := 0;

BEGIN
   SALDO := NVL(P_SALDO,0);
   FOR INSTRUCCIONES_REC IN INSTRUCCIONES  LOOP
      V_MONTO_PAGO := 0;
      IF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'SD' THEN
         OPEN C_MCC_ALL(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN,
                        INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO,
                        INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA,
                        INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO) ;
         FETCH C_MCC_ALL INTO MCC1;
         WHILE C_MCC_ALL%FOUND LOOP
            VALOR := 0;
            IF NVL(MCC1.MCC_MONTO_PAGADO, 0) = 0 THEN
               VALOR := MCC1.MCC_MONTO_ADMON_VALORES;
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                   MCC_FECHA_TIPO_INST_PAGO = SYSDATE,
                   MCC_MONTO_PAGADO = VALOR
               WHERE MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;

               INSERT INTO MOVIMIENTOS_PAGOS_INSTRUCCION
                        ( MPIN_CONSECUTIVO
                         ,MPIN_MCC_CONSECUTIVO
                         ,MPIN_MONTO_PAGADO
                         ,MPIN_REVERSADO
                         ,MPIN_OFO_CONSECUTIVO
                         ,MPIN_OFO_SUC_CODIGO
                         ,MPIN_ODP_CONSECUTIVO
                         ,MPIN_ODP_SUC_CODIGO
                         ,MPIN_ODP_NEG_CONSECUTIVO
                         )
               VALUES(    MPIN_SEQ.NEXTVAL
                         ,MCC1.MCC_CONSECUTIVO
                         ,VALOR
                         ,'N'
                         ,P_OFO_CONS
                         ,P_OFO_SUC
                         ,P_ODP_CONS
                         ,P_ODP_SUC
                         ,P_ODP_NEG);
               SALDO := SALDO - VALOR;
            ELSE
               VALOR := MCC1.MCC_MONTO_ADMON_VALORES - NVL(MCC1.MCC_MONTO_PAGADO,0);
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                   MCC_FECHA_TIPO_INST_PAGO = SYSDATE,
                   MCC_MONTO_PAGADO = MCC_MONTO_PAGADO + VALOR
               WHERE MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;

               INSERT INTO MOVIMIENTOS_PAGOS_INSTRUCCION
                        ( MPIN_CONSECUTIVO
                         ,MPIN_MCC_CONSECUTIVO
                         ,MPIN_MONTO_PAGADO
                         ,MPIN_REVERSADO
                         ,MPIN_OFO_CONSECUTIVO
                         ,MPIN_OFO_SUC_CODIGO
                         ,MPIN_ODP_CONSECUTIVO
                         ,MPIN_ODP_SUC_CODIGO
                         ,MPIN_ODP_NEG_CONSECUTIVO)
               VALUES (   MPIN_SEQ.NEXTVAL
                         ,MCC1.MCC_CONSECUTIVO
                         ,VALOR
                         ,'N'
                         ,P_OFO_CONS
                         ,P_OFO_SUC
                         ,P_ODP_CONS
                         ,P_ODP_SUC
                         ,P_ODP_NEG);
                  SALDO := SALDO + VALOR;
            END IF;
            UPDATE MOVIMIENTOS_CUENTA_CORREDORES
            SET MCC_PAGADO = 'S'
            WHERE MCC_MONTO_PAGADO >= MCC_MONTO_ADMON_VALORES
              AND MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;
            FETCH C_MCC_ALL INTO MCC1;
         END LOOP;
         CLOSE C_MCC_ALL;
      ELSIF INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO = 'DI' THEN
         IF INSTRUCCIONES_REC.IPD_TIPO_EMISOR = 'T' THEN
            OPEN C_MCC_ALL(INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN,
                           INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO,
                           INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA,
                           INSTRUCCIONES_REC.IPD_TIPO_ORIGEN_PAGO) ;
            FETCH C_MCC_ALL INTO MCC1;
            WHILE C_MCC_ALL%FOUND  LOOP
               VALOR := 0;
               IF NVL(MCC1.MCC_MONTO_PAGADO, 0) = 0 THEN
                  VALOR := MCC1.MCC_MONTO_ADMON_VALORES;
                  UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                  SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                      MCC_FECHA_TIPO_INST_PAGO = SYSDATE,
                      MCC_MONTO_PAGADO = VALOR
                  WHERE MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;

                  INSERT INTO MOVIMIENTOS_PAGOS_INSTRUCCION
                        ( MPIN_CONSECUTIVO
                         ,MPIN_MCC_CONSECUTIVO
                         ,MPIN_MONTO_PAGADO
                         ,MPIN_REVERSADO
                         ,MPIN_OFO_CONSECUTIVO
                         ,MPIN_OFO_SUC_CODIGO
                         ,MPIN_ODP_CONSECUTIVO
                         ,MPIN_ODP_SUC_CODIGO
                         ,MPIN_ODP_NEG_CONSECUTIVO
                         ,MPIN_MDA_CONSECUTIVO)
                  VALUES( MPIN_SEQ.NEXTVAL
                         ,MCC1.MCC_CONSECUTIVO
                         ,VALOR
                         ,'N'
                         ,P_OFO_CONS
                         ,P_OFO_SUC
                         ,P_ODP_CONS
                         ,P_ODP_SUC
                         ,P_ODP_NEG
                         ,P_MDA_CONSECUTIVO);
                  SALDO := SALDO - VALOR;
               ELSE
                  VALOR := MCC1.MCC_MONTO_ADMON_VALORES - NVL(MCC1.MCC_MONTO_PAGADO,0);
                  UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                  SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                      MCC_FECHA_TIPO_INST_PAGO = SYSDATE,
                      MCC_MONTO_PAGADO = MCC_MONTO_PAGADO + VALOR
                  WHERE MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;

                  INSERT INTO MOVIMIENTOS_PAGOS_INSTRUCCION
                        ( MPIN_CONSECUTIVO
                         ,MPIN_MCC_CONSECUTIVO
                         ,MPIN_MONTO_PAGADO
                         ,MPIN_REVERSADO
                         ,MPIN_OFO_CONSECUTIVO
                         ,MPIN_OFO_SUC_CODIGO
                         ,MPIN_ODP_CONSECUTIVO
                         ,MPIN_ODP_SUC_CODIGO
                         ,MPIN_ODP_NEG_CONSECUTIVO
                         ,MPIN_MDA_CONSECUTIVO)
                  VALUES (MPIN_SEQ.NEXTVAL
                         ,MCC1.MCC_CONSECUTIVO
                         ,VALOR
                         ,'N'
                         ,P_OFO_CONS
                         ,P_OFO_SUC
                         ,P_ODP_CONS
                         ,P_ODP_SUC
                         ,P_ODP_NEG
                         ,P_MDA_CONSECUTIVO);
                  SALDO := SALDO + VALOR;
               END IF;
               IF P_POD = 'N' THEN
                 UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                 SET MCC_PAGADO = 'S'
                 WHERE MCC_MONTO_PAGADO >= MCC_MONTO_ADMON_VALORES
                    AND MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;
               ELSE
                 UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                 SET MCC_PAGADO = 'S', MCC_MDA_CONSECUTIVO = P_MDA_CONSECUTIVO
                 WHERE MCC_MONTO_PAGADO >= MCC_MONTO_ADMON_VALORES
                    AND MCC_CONSECUTIVO = MCC1.MCC_CONSECUTIVO;
               END IF;
               FETCH C_MCC_ALL INTO MCC1;
            END LOOP;
            CLOSE C_MCC_ALL;
         ELSE
            FOR DETALLES_INSTRUCCION_REC IN DETALLES_INSTRUCCION  LOOP
               OPEN C_MCC_ISIN (INSTRUCCIONES_REC.IPD_CCC_CLI_PER_NUM_IDEN,
                                INSTRUCCIONES_REC.IPD_CCC_CLI_PER_TID_CODIGO,
                                INSTRUCCIONES_REC.IPD_CCC_NUMERO_CUENTA,
                                DETALLES_INSTRUCCION_REC.DIPA_FUG_MNEMONICO,
                                DETALLES_INSTRUCCION_REC.DIPA_FUG_ISI_MNEMONICO );
               FETCH C_MCC_ISIN INTO MCC2;
               WHILE C_MCC_ISIN%FOUND  LOOP
                  IF NVL(MCC2.MCC_MONTO_PAGADO, 0) = 0 THEN
                     VALOR := MCC2.MCC_MONTO_ADMON_VALORES;
                     UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                     SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                         MCC_FECHA_TIPO_INST_PAGO = SYSDATE,
                         MCC_MONTO_PAGADO = MCC_MONTO_ADMON_VALORES
                     WHERE MCC_CONSECUTIVO = MCC2.MCC_CONSECUTIVO;
                     INSERT INTO MOVIMIENTOS_PAGOS_INSTRUCCION
                              ( MPIN_CONSECUTIVO
                               ,MPIN_MCC_CONSECUTIVO
                               ,MPIN_MONTO_PAGADO
                               ,MPIN_REVERSADO
                               ,MPIN_OFO_CONSECUTIVO
                               ,MPIN_OFO_SUC_CODIGO
                               ,MPIN_ODP_CONSECUTIVO
                               ,MPIN_ODP_SUC_CODIGO
                               ,MPIN_ODP_NEG_CONSECUTIVO
                               ,MPIN_MDA_CONSECUTIVO)
                     VALUES(    MPIN_SEQ.NEXTVAL
                               ,MCC2.MCC_CONSECUTIVO
                               ,VALOR
                               ,'N'
                               ,P_OFO_CONS
                               ,P_OFO_SUC
                               ,P_ODP_CONS
                               ,P_ODP_SUC
                               ,P_ODP_NEG
                               ,P_MDA_CONSECUTIVO);

                        SALDO := SALDO - VALOR;
                  ELSE
                     VALOR := MCC2.MCC_MONTO_ADMON_VALORES - NVL(MCC2.MCC_MONTO_PAGADO,0);
                     UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                     SET MCC_TIPO_INSTRUCCION_PAGO = P_TIPO_INSTRUCCION_PAGO,
                         MCC_FECHA_TIPO_INST_PAGO = SYSDATE,
                         MCC_MONTO_PAGADO = SALDO
                     WHERE MCC_CONSECUTIVO = MCC2.MCC_CONSECUTIVO;
                     INSERT INTO MOVIMIENTOS_PAGOS_INSTRUCCION
                              ( MPIN_CONSECUTIVO
                               ,MPIN_MCC_CONSECUTIVO
                               ,MPIN_MONTO_PAGADO
                               ,MPIN_REVERSADO
                               ,MPIN_OFO_CONSECUTIVO
                               ,MPIN_OFO_SUC_CODIGO
                               ,MPIN_ODP_CONSECUTIVO
                               ,MPIN_ODP_SUC_CODIGO
                               ,MPIN_ODP_NEG_CONSECUTIVO
                               ,MPIN_MDA_CONSECUTIVO)
                     VALUES(    MPIN_SEQ.NEXTVAL
                               ,MCC2.MCC_CONSECUTIVO
                               ,VALOR
                               ,'N'
                               ,P_OFO_CONS
                               ,P_OFO_SUC
                               ,P_ODP_CONS
                               ,P_ODP_SUC
                               ,P_ODP_NEG
                               ,P_MDA_CONSECUTIVO);
                     SALDO := SALDO - VALOR;
                  END IF;
                  IF P_POD = 'N' THEN
                    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                    SET MCC_PAGADO = 'S'
                    WHERE MCC_MONTO_PAGADO >= MCC_MONTO_ADMON_VALORES
                      AND MCC_CONSECUTIVO = MCC2.MCC_CONSECUTIVO;
                  ELSE
                    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
                    SET MCC_PAGADO = 'S', MCC_MDA_CONSECUTIVO = P_MDA_CONSECUTIVO
                    WHERE MCC_MONTO_PAGADO >= MCC_MONTO_ADMON_VALORES
                      AND MCC_CONSECUTIVO = MCC2.MCC_CONSECUTIVO;
                  END IF;
                  FETCH C_MCC_ISIN INTO MCC2;
               END LOOP;
               CLOSE C_MCC_ISIN;
            END LOOP;
         END IF;
      END IF;
   END LOOP;

END MARCAR_MCC_INSTRUCCION_PAGO_N;
---------------------------------------------------------------------------------------------------------
PROCEDURE PR_QUITAR_MARCA_MCC
                ( P_ODP_CONS    ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_ODP_SUC     ORDENES_DE_PAGO.ODP_SUC_CODIGO%TYPE DEFAULT NULL
                 ,P_ODP_NEG     ORDENES_DE_PAGO.ODP_NEG_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_OFO_CONS    ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_OFO_SUC     ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE DEFAULT NULL
                ) IS

   CURSOR C_VALIDA IS
      SELECT 'S'
      FROM ORDENES_DE_PAGO
      WHERE ODP_CONSECUTIVO = P_ODP_CONS
        AND ODP_SUC_CODIGO = P_ODP_SUC
        AND ODP_NEG_CONSECUTIVO = P_ODP_NEG
        AND EXISTS (SELECT 'X'
                    FROM MOVIMIENTOS_PAGOS_INSTRUCCION
                    WHERE MPIN_ODP_CONSECUTIVO = ODP_CONSECUTIVO
                      AND MPIN_ODP_SUC_CODIGO = ODP_SUC_CODIGO
                      AND MPIN_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
                      AND MPIN_REVERSADO = 'N')
       UNION
       SELECT 'S'
       FROM ORDENES_FONDOS
       WHERE OFO_CONSECUTIVO = P_OFO_CONS
         AND OFO_SUC_CODIGO = P_OFO_SUC
         AND EXISTS (SELECT 'X'
                     FROM MOVIMIENTOS_PAGOS_INSTRUCCION
                     WHERE MPIN_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                       AND MPIN_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                      AND MPIN_REVERSADO = 'N');
   SINO VARCHAR2(1);

   CURSOR C_MPIN IS
      SELECT MPIN_CONSECUTIVO,
             MPIN_MONTO_PAGADO,
             MPIN_REVERSADO,
             MPIN_MCC_CONSECUTIVO,
             MPIN_ODP_CONSECUTIVO
      FROM MOVIMIENTOS_PAGOS_INSTRUCCION
      WHERE MPIN_REVERSADO = 'N'
        AND (   (    P_ODP_CONS IS NOT NULL
                 AND MPIN_ODP_CONSECUTIVO = P_ODP_CONS
                 AND MPIN_ODP_SUC_CODIGO = P_ODP_SUC
                 AND MPIN_ODP_NEG_CONSECUTIVO = P_ODP_NEG)
             OR (    P_OFO_CONS IS NOT NULL
                 AND MPIN_OFO_CONSECUTIVO = P_OFO_CONS
                 AND MPIN_OFO_SUC_CODIGO = P_OFO_SUC));
   R_MPIN C_MPIN%ROWTYPE;

   CURSOR C_POD (P_ODP NUMBER) IS
     SELECT TIPM_MONTO_ODP + NVL(TIPM_MONTO_GMF,0) MONTO
           ,TIPM_NUM_IDEN
           ,TIPM_TID_CODIGO
           ,TIPM_NUMERO_CUENTA
           ,TIPM_ISIN
           ,TIPM_EMISOR
     FROM TMP_INSTRUCCIONES_PAGOS_MASIVO
     WHERE TIPM_FECHA >= TRUNC(SYSDATE-10)
     AND   TIPM_FECHA < TRUNC(SYSDATE+1)
     AND   TIPM_PROCESADO = 'S'
     AND   TIPM_TPA_MNEMONICO IN ('TRB','ACH')
     AND   TIPM_ESTADO = 'POK'
     AND   TIPM_ISIN IN ('COC04PA00016','COB51PA00076')
     AND   TIPM_ORIGEN_CLIENTE = 'DAV'
     AND   TIPM_ODP_CONSECUTIVO = P_ODP;
   POD C_POD%ROWTYPE;

   COND VARCHAR2(1);
BEGIN
   OPEN C_VALIDA;
   FETCH C_VALIDA INTO SINO;
   IF C_VALIDA%FOUND THEN
      SINO := NVL(SINO,'N');
   ELSE
      SINO := 'N';
   END IF;
   CLOSE C_VALIDA;
   IF SINO = 'S' THEN
      OPEN C_MPIN;
      FETCH C_MPIN INTO R_MPIN;
      WHILE C_MPIN%FOUND LOOP
         UPDATE MOVIMIENTOS_CUENTA_CORREDORES
         SET MCC_MONTO_PAGADO  = NVL(MCC_MONTO_PAGADO,0) - R_MPIN.MPIN_MONTO_PAGADO
         WHERE MCC_CONSECUTIVO = R_MPIN.MPIN_MCC_CONSECUTIVO;

         UPDATE MOVIMIENTOS_CUENTA_CORREDORES
         SET MCC_PAGADO = 'N'
         WHERE MCC_CONSECUTIVO = R_MPIN.MPIN_MCC_CONSECUTIVO
           AND MCC_MONTO_ADMON_VALORES != MCC_MONTO_PAGADO;

         UPDATE  MOVIMIENTOS_PAGOS_INSTRUCCION
         SET MPIN_REVERSADO = 'S'
         WHERE MPIN_CONSECUTIVO = R_MPIN.MPIN_CONSECUTIVO;

         FETCH C_MPIN INTO R_MPIN;
      END LOOP;
      CLOSE C_MPIN;

      IF P_ODP_CONS IS NOT NULL THEN
        OPEN C_POD(P_ODP_CONS);
        FETCH C_POD INTO POD;
        IF C_POD%FOUND THEN
          INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ORIGEN_CLIENTE
            )VALUES
            (TIPM_SEQ.NEXTVAL
            ,SYSDATE
            ,POD.TIPM_NUM_IDEN
            ,POD.TIPM_TID_CODIGO
            ,POD.TIPM_NUMERO_CUENTA
            ,NULL
            ,POD.MONTO
            ,0
            ,'N'
            ,'POD'
            ,POD.TIPM_ISIN
            ,POD.TIPM_EMISOR
            ,'AOK'
            ,'ALISTAMIENTO OK'
            ,'DAV'
            );
        END IF;
        CLOSE C_POD;
     END IF;
   END IF;
END;

-----------------------------
PROCEDURE PR_MARCAR_SALDO_CERO
              (P_CLI_PER_NUM_IDEN VARCHAR2
              ,P_CLI_PER_TID_CODIGO VARCHAR2
              ,P_CCC_NUMERO_CUENTA NUMBER) IS
CURSOR C_CCC IS
       SELECT CCC_CLI_PER_NUM_IDEN,
              CCC_CLI_PER_TID_CODIGO,
              CCC_NUMERO_CUENTA
       FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA;
   R_CCC C_CCC%ROWTYPE;

   CURSOR C_MAX (NID VARCHAR2, TID VARCHAR, CTA NUMBER) IS
      SELECT MAX(MCC_CONSECUTIVO) MCC_CONSECUTIVO
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = TID
        AND MCC_CCC_NUMERO_CUENTA = CTA
        AND MCC_MONTO_ADMON_VALORES != 0
        AND MCC_SALDO_ADMON_VALORES <= 0;
   R_MAX C_MAX%ROWTYPE;

   CURSOR C_CPDV (NID VARCHAR2, TID VARCHAR, CTA NUMBER,CONS NUMBER) IS
      SELECT MCC_CONSECUTIVO,
             MCC_MONTO,
             MCC_MONTO_ADMON_VALORES
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = TID
        AND MCC_CCC_NUMERO_CUENTA = CTA
        AND MCC_MONTO_ADMON_VALORES < 0
        AND MCC_CFC_FUG_ISI_MNEMONICO IS NULL
         AND MCC_CONSECUTIVO > CONS
         AND NVL(MCC_PAGADO,'N') = 'N'
     ORDER BY MCC_CONSECUTIVO ASC;
   R_CPDV C_CPDV%ROWTYPE;

   CURSOR C_MCC (NID VARCHAR2, TID VARCHAR, CTA NUMBER,CONS NUMBER) IS
      SELECT MCC_CONSECUTIVO,
             MCC_MONTO_ADMON_VALORES,
             MCC_MONTO_PAGADO
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = NID
        AND MCC_CCC_CLI_PER_TID_CODIGO = TID
        AND MCC_CCC_NUMERO_CUENTA = CTA
        AND MCC_MONTO_ADMON_VALORES > 0
        AND MCC_CFC_FUG_ISI_MNEMONICO IS NOT NULL
        AND NVL(MCC_PAGADO,'N') = 'N'
        AND MCC_CONSECUTIVO > CONS
     ORDER BY MCC_CONSECUTIVO ASC;

   R_MCC C_MCC%ROWTYPE;
   SALDO NUMBER := 0;
   VR_PAGADO NUMBER := 0;
BEGIN
   OPEN C_CCC;
   FETCH C_CCC INTO R_CCC;
   IF C_CCC%FOUND THEN
      OPEN C_MAX(R_CCC.CCC_CLI_PER_NUM_IDEN, R_CCC.CCC_CLI_PER_TID_CODIGO, R_CCC.CCC_NUMERO_CUENTA);
      FETCH C_MAX INTO R_MAX;
      IF C_MAX%FOUND THEN
         UPDATE MOVIMIENTOS_CUENTA_CORREDORES
         SET    MCC_TIPO_INSTRUCCION_PAGO = 'PM'
               ,MCC_FECHA_TIPO_INST_PAGO = SYSDATE
               ,MCC_MONTO_PAGADO = MCC_MONTO_ADMON_VALORES
               ,MCC_PAGADO = 'S'
         WHERE MCC_CCC_CLI_PER_NUM_IDEN = R_CCC.CCC_CLI_PER_NUM_IDEN
           AND MCC_CCC_CLI_PER_TID_CODIGO = R_CCC.CCC_CLI_PER_TID_CODIGO
           AND MCC_CCC_NUMERO_CUENTA = R_CCC.CCC_NUMERO_CUENTA
           AND MCC_MONTO_ADMON_VALORES != 0
           AND MCC_TIPO_INSTRUCCION_PAGO IS NULL
           AND NVL(MCC_PAGADO,'N') = 'N'
           AND MCC_CONSECUTIVO <= R_MAX.MCC_CONSECUTIVO;

         UPDATE MOVIMIENTOS_CUENTA_CORREDORES
         SET    MCC_MONTO_PAGADO = MCC_MONTO_ADMON_VALORES
               ,MCC_PAGADO = 'S'
         WHERE MCC_CCC_CLI_PER_NUM_IDEN = R_CCC.CCC_CLI_PER_NUM_IDEN
           AND MCC_CCC_CLI_PER_TID_CODIGO = R_CCC.CCC_CLI_PER_TID_CODIGO
           AND MCC_CCC_NUMERO_CUENTA = R_CCC.CCC_NUMERO_CUENTA
           AND MCC_MONTO_ADMON_VALORES != 0
           AND MCC_TIPO_INSTRUCCION_PAGO IS NOT NULL
           AND NVL(MCC_PAGADO,'N') = 'N'
           AND MCC_CONSECUTIVO <= R_MAX.MCC_CONSECUTIVO;

         OPEN C_CPDV(R_CCC.CCC_CLI_PER_NUM_IDEN, R_CCC.CCC_CLI_PER_TID_CODIGO, R_CCC.CCC_NUMERO_CUENTA, R_MAX.MCC_CONSECUTIVO);
         FETCH C_CPDV INTO R_CPDV;
         WHILE C_CPDV%FOUND  LOOP
            SALDO := -R_CPDV.MCC_MONTO_ADMON_VALORES;

            OPEN C_MCC(R_CCC.CCC_CLI_PER_NUM_IDEN, R_CCC.CCC_CLI_PER_TID_CODIGO, R_CCC.CCC_NUMERO_CUENTA, R_MAX.MCC_CONSECUTIVO);
            FETCH C_MCC INTO R_MCC;
            WHILE C_MCC%FOUND AND SALDO > 0 LOOP
               VR_PAGADO := R_MCC.MCC_MONTO_ADMON_VALORES - NVL(R_MCC.MCC_MONTO_PAGADO,0);
               IF VR_PAGADO > SALDO THEN
                  VR_PAGADO := SALDO;
               END IF;
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET MCC_MONTO_PAGADO = NVL(MCC_MONTO_PAGADO,0) + VR_PAGADO
               WHERE MCC_CONSECUTIVO = R_MCC.MCC_CONSECUTIVO;

               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET MCC_PAGADO = 'S'
               WHERE MCC_CONSECUTIVO = R_MCC.MCC_CONSECUTIVO
                 AND MCC_MONTO_ADMON_VALORES = NVL(MCC_MONTO_PAGADO,0);

               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET MCC_PAGADO = 'N'
               WHERE MCC_CONSECUTIVO = R_MCC.MCC_CONSECUTIVO
                 AND MCC_MONTO_ADMON_VALORES != NVL(MCC_MONTO_PAGADO,0);

               SALDO := SALDO - VR_PAGADO;
               FETCH C_MCC INTO R_MCC;
            END LOOP;
            CLOSE C_MCC;

            UPDATE MOVIMIENTOS_CUENTA_CORREDORES
            SET MCC_PAGADO = 'S',
                MCC_MONTO_PAGADO = MCC_MONTO_ADMON_VALORES
            WHERE MCC_CONSECUTIVO = R_CPDV.MCC_CONSECUTIVO;
            FETCH C_CPDV INTO R_CPDV;
         END LOOP;
         CLOSE C_CPDV;

      END IF;
      CLOSE C_MAX;
   END IF;
   COMMIT;
   CLOSE C_CCC;
END PR_MARCAR_SALDO_CERO;
----------------------------------------------------------------------------------------------------
FUNCTION FN_VALIDA_SALDO_AV
   (P_CLI_NUM_IDEN      IN  CLIENTES.CLI_PER_NUM_IDEN%TYPE
   ,P_CLI_TID_CODIGO    IN  CLIENTES.CLI_PER_TID_CODIGO%TYPE
   ,P_CUENTA            IN  CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE) RETURN VARCHAR2 IS

   CURSOR C_SALDO_CCC IS
      SELECT CCC_SALDO_ADMON_VALORES
      FROM   CUENTAS_CLIENTE_CORREDORES
      WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    CCC_NUMERO_CUENTA = P_CUENTA;
   CCC1   C_SALDO_CCC%ROWTYPE;

   CURSOR C_SALDO IS
      SELECT MCC_SALDO_ADMON_VALORES
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CUENTA
      AND    MCC_FECHA < TRUNC(SYSDATE)
      ORDER BY MCC_CONSECUTIVO DESC;
   MCC1   C_SALDO%ROWTYPE;

   CURSOR C_MOVIMIENTO IS
      SELECT SUM(MCC_MONTO_ADMON_VALORES)
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CUENTA
      AND    MCC_FECHA >= TRUNC(SYSDATE);

   TOTAL_DIA NUMBER;
   V_OK VARCHAR2(1);

BEGIN
      OPEN C_SALDO_CCC;
      FETCH C_SALDO_CCC INTO CCC1;
      CLOSE C_SALDO_CCC;

      OPEN C_SALDO;
      FETCH C_SALDO INTO MCC1;
      CLOSE C_SALDO;
      MCC1.MCC_SALDO_ADMON_VALORES := NVL(MCC1.MCC_SALDO_ADMON_VALORES, 0);

      OPEN C_MOVIMIENTO;
      FETCH C_MOVIMIENTO INTO TOTAL_DIA;
      CLOSE C_MOVIMIENTO;
      TOTAL_DIA := NVL(TOTAL_DIA, 0);

      MCC1.MCC_SALDO_ADMON_VALORES := MCC1.MCC_SALDO_ADMON_VALORES + TOTAL_DIA;

      IF CCC1.CCC_SALDO_ADMON_VALORES = MCC1.MCC_SALDO_ADMON_VALORES THEN
         V_OK := 'S';
      ELSE
         V_OK := 'N';
      END IF;
      RETURN(NVL(V_OK,'N'));
END FN_VALIDA_SALDO_AV;

FUNCTION FN_MONTO_MAX_ODP   (P_CLI_NUM_IDEN      IN  CLIENTES.CLI_PER_NUM_IDEN%TYPE
                            ,P_CLI_TID_CODIGO    IN  CLIENTES.CLI_PER_TID_CODIGO%TYPE)
                            RETURN NUMBER IS

  V_MAX_TOTAL   CUENTAS_CLIENTE_CORREDORES.CCC_SALDO_BURSATIL%TYPE;
  V_ODP         ORDENES_DE_PAGO.ODP_MONTO_ORDEN%TYPE;
  V_ODP_GMF     ORDENES_DE_PAGO.ODP_MONTO_IMGF%TYPE;

BEGIN
  V_MAX_TOTAL   := 0;
  V_ODP         := 0;
  V_ODP_GMF     := 0;

  SELECT NVL(CON_VALOR,0)     CCC_SALDO_BURSATIL
  INTO   V_MAX_TOTAL
  FROM CONSTANTES
  WHERE  CON_MNEMONICO = 'MXD';


   SELECT SUM(ODP_MONTO_ORDEN)
         ,SUM(ODP_MONTO_IMGF)
   INTO V_ODP, V_ODP_GMF
   FROM   ORDENES_DE_PAGO
   WHERE  ODP_NPR_PRO_MNEMONICO IN ('ADVAL','OB')
     AND  ODP_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
     AND  ODP_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
     AND  ODP_ESTADO IN ('COL','APR')
     AND  ODP_FECHA_EJECUCION >= TRUNC(SYSDATE)
     AND  ODP_CEG_CONSECUTIVO IS NULL
     AND  ODP_CGE_CONSECUTIVO IS NULL
     AND  ODP_TBC_CONSECUTIVO IS NULL
     AND  ODP_TCC_CONSECUTIVO IS NULL
     AND  NVL(ODP_ORDEN_MANUAL,'N') = 'N'
     AND  ODP_TERMINAL_VERIFICA = 'NOCTURNO';

   V_MAX_TOTAL := NVL(V_MAX_TOTAL,0) - NVL(V_ODP,0) + NVL(V_ODP_GMF,0);
   RETURN(NVL(V_MAX_TOTAL,0));
END FN_MONTO_MAX_ODP;

-----------------------------
-----------------------------
PROCEDURE PROCESO_PAGOS_MASIVOS_DIV (P_SEC IN NUMBER
                                    ,P_PER_NUM_IDEN IN VARCHAR2
                                    ,P_PER_TID_CODIGO IN VARCHAR2
                                    ,P_CCC_NUMERO_CUENTA IN NUMBER
                                    ,P_FUG_ISI_MNEMONICO IN VARCHAR2
                                    ,P_CLI_EXCENTO_DXM IN VARCHAR2
                                    ,P_IPD_TIPO_EMISOR    IN VARCHAR2
                                    ,P_IPD_CONSECUTIVO    IN NUMBER
                                    ,P_IPD_TPA_MNEMONICO  IN VARCHAR2
                                    ,P_IPD_BAN_CODIGO     IN NUMBER
                                    ,P_IPD_VISADO         IN VARCHAR2
                                    ,P_IPD_PAGO           IN VARCHAR2
                                    ,P_IPD_TRASLADO_FONDOS  IN VARCHAR2
                                    ,P_IPD_INSTRUCCION_POD  IN VARCHAR2
                                    ,P_IPD_PAGAR_A        IN VARCHAR2
                                    ,P_IPD_CRUCE_CHEQUE   IN VARCHAR2
                                    ,P_MONTO_MAX_POD      IN NUMBER
                                    ,P_MONTO_MAX_ACH      IN NUMBER
                                    ,P_TDD_IBA            IN NUMBER
                                    ,P_PER_SUC_CODIGO     IN NUMBER
                                    ,P_PER_NOMBRE_USUARIO IN VARCHAR2
                                    ,P_CCC_PER_NUM_IDEN   IN VARCHAR2
                                    ,P_CCC_PER_TID_CODIGO IN VARCHAR2
                                      ,P_FAV_CONSECUTIVO IN NUMBER DEFAULT NULL) IS

  P_CLI_PER_NUM_IDEN          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
  P_CLI_PER_TID_CODIGO        CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
  P_NUMERO_CUENTA             CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;


  -- CLIENTES CON ABD DEL DIA DEL ABONO Y QUE ESTAN PENDIENTES DE EJECUTAR EL PAGO MASIVO PARA EL ISIN ESPECIFICO
  CURSOR DIVIDENDOS_X_ISIN (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT  MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA , SUM (MONTO)MONTO, ISIN, EMISOR
    FROM (SELECT /*+ APPEND */ MCC_CCC_CLI_PER_NUM_IDEN
                ,MCC_CCC_CLI_PER_TID_CODIGO
                ,MCC_CCC_NUMERO_CUENTA
                ,SUM(MCC_MONTO_ADMON_VALORES) MONTO
                ,MCC_CFC_FUG_ISI_MNEMONICO ISIN
                ,FUG_ENA_MNEMONICO EMISOR
          FROM MOVIMIENTOS_CUENTA_CORREDORES, FUNGIBLES
          WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
            AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
            AND MCC_CCC_NUMERO_CUENTA = P_CTA
            AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
            AND MCC_CFC_FUG_MNEMONICO = FUG_MNEMONICO
            AND MCC_FECHA >= TRUNC(SYSDATE)
            AND MCC_FECHA < TRUNC(SYSDATE+1)
            AND MCC_TMC_MNEMONICO = 'ABD'
            AND MCC_PAGADO IS NULL
            AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
          GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, MCC_CFC_FUG_ISI_MNEMONICO, FUG_ENA_MNEMONICO
          UNION
          SELECT /*+ APPEND */ MCC.MCC_CCC_CLI_PER_NUM_IDEN,
                 MCC.MCC_CCC_CLI_PER_TID_CODIGO,
                 MCC.MCC_CCC_NUMERO_CUENTA,
                 SUM(MCC.MCC_MONTO_ADMON_VALORES) MONTO,
                 MCC.MCC_CFC_FUG_ISI_MNEMONICO ISIN,
                 FUG.FUG_ENA_MNEMONICO EMISOR
          FROM  MOVIMIENTOS_CUENTA_CORREDORES MCC, FUNGIBLES FUG, AJUSTES_CLIENTES ACL
          WHERE MCC.MCC_ACL_CONSECUTIVO = ACL.ACL_CONSECUTIVO
          AND   MCC.MCC_SUC_CODIGO = ACL.ACL_SUC_CODIGO
          AND   MCC.MCC_NEG_CONSECUTIVO = ACL.ACL_NEG_CONSECUTIVO
          AND   MCC.MCC_CFC_FUG_ISI_MNEMONICO = FUG.FUG_ISI_MNEMONICO
          AND   MCC.MCC_CFC_FUG_MNEMONICO = FUG.FUG_MNEMONICO
          AND 	MCC.MCC_CCC_CLI_PER_NUM_IDEN = P_ID
          AND		MCC.MCC_CCC_CLI_PER_TID_CODIGO = P_TID
          AND 	MCC.MCC_CCC_NUMERO_CUENTA = P_CTA
          AND   MCC.MCC_FECHA >= TRUNC(SYSDATE)
          AND   MCC.MCC_FECHA < TRUNC(SYSDATE+1)
          AND   MCC.MCC_PAGADO IS NULL
          AND   MCC.MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
          AND   MCC.MCC_CFC_FUG_ISI_MNEMONICO IN (SELECT PMI_ISIN
                                                  FROM PAGOS_MASIVOS_ISIN
                                                  WHERE PMI_FECHA >= TRUNC(SYSDATE-1)
                                                  AND PMI_FECHA < TRUNC(SYSDATE+1)
                                                  AND PMI_PAGADO = 'P')
          AND   ACL.ACL_CAJ_MNEMONICO IN (SELECT CAJ_MNEMONICO
                                          FROM CONCEPTOS_AJUSTES
                                          WHERE CAJ_TIPO_SALDO = 'ADVAL')
          GROUP BY MCC.MCC_CCC_CLI_PER_NUM_IDEN, MCC.MCC_CCC_CLI_PER_TID_CODIGO, MCC.MCC_CCC_NUMERO_CUENTA, MCC.MCC_CFC_FUG_ISI_MNEMONICO, FUG.FUG_ENA_MNEMONICO)
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, ISIN, EMISOR;
  REC_DIVIDENDOS_X_ISIN DIVIDENDOS_X_ISIN%ROWTYPE;

  -- INSTRUCCIONES DE PAGO ACTIVAS DE ORIGEN DE PAGO "DIVIDENDOS" PARA ISIN ESPECIFICO
  CURSOR INSTRUCCION_E (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT /*+ APPEND */ IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
    FROM INSTRUCCIONES_PAGOS_DIVIDENDOS, DETALLE_INSTRUCCIONES_PAGOS
    WHERE IPD_CONSECUTIVO = DIPA_IPD_CONSECUTIVO
      AND IPD_CCC_CLI_PER_NUM_IDEN = P_ID
      AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
      AND IPD_CCC_NUMERO_CUENTA = P_CTA
      AND IPD_TIPO_EMISOR = 'E'
      AND IPD_ESTADO = 'A'
      AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
      AND IPD_TIPO_ORIGEN_PAGO IN ('DI', 'SD')
      AND DIPA_FUG_ISI_MNEMONICO = P_ISIN;
  REC_INSTRUCCION_E INSTRUCCION_E%ROWTYPE;

  -- MONTO DEL SERVICIO - MOVIMIENTO SAV O IAV PARA LA FECHA DEL PAGO
  CURSOR MONTO_SERVICIO (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT /*+ APPEND */ NVL(SUM(MCC_MONTO_ADMON_VALORES),0) MONTO
    FROM MOVIMIENTOS_CUENTA_CORREDORES
    WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
      AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
      AND MCC_CCC_NUMERO_CUENTA = P_CTA
      AND MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_FDF_FECHA             IS NOT NULL
      AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
      AND MCC_TMC_MNEMONICO IN ('SAV','IAV')
      AND NVL(MCC_PAGADO,'N') = 'N';

  -- SORTIZ VAGTUD698-2
  -- IMPUESTOS ('RIC','RCR','ADI')
  CURSOR C_IMPUESTOS (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
       SELECT /*+ APPEND */ MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC_CFC_FUG_ISI_MNEMONICO ISIN
          ,FUG_ENA_MNEMONICO EMISOR
          ,MCC_TMC_MNEMONICO
    FROM MOVIMIENTOS_CUENTA_CORREDORES, FUNGIBLES
    WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
      AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
      AND MCC_CCC_NUMERO_CUENTA = P_CTA
      AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
      AND MCC_CFC_FUG_MNEMONICO = FUG_MNEMONICO
      AND MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_TMC_MNEMONICO IN ('RIC','RCR','ADI') -- ICA - CREE - OTROS
      AND MCC_PAGADO IS NULL
      AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, MCC_CFC_FUG_ISI_MNEMONICO, FUG_ENA_MNEMONICO,MCC_TMC_MNEMONICO;
  V_IMPUESTOS C_IMPUESTOS%ROWTYPE;

  -- RETEFUENTE ('RCC','RFR','RFD')
  CURSOR C_RETEFUENTE (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
       SELECT /*+ APPEND */ MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC_CFC_FUG_ISI_MNEMONICO ISIN
          ,FUG_ENA_MNEMONICO EMISOR
          ,MCC_TMC_MNEMONICO
    FROM MOVIMIENTOS_CUENTA_CORREDORES, FUNGIBLES
    WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
      AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
      AND MCC_CCC_NUMERO_CUENTA = P_CTA
      AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
      AND MCC_CFC_FUG_MNEMONICO = FUG_MNEMONICO
      AND MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_TMC_MNEMONICO IN ('RCC','RFR','RFD') -- RETEFUENTE
      AND MCC_PAGADO IS NULL
      AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, MCC_CFC_FUG_ISI_MNEMONICO, FUG_ENA_MNEMONICO,MCC_TMC_MNEMONICO;
  V_RETEFUENTE C_RETEFUENTE%ROWTYPE;
  -- FIN VAGTUD698-2

  -- CAE ('CAE')
  CURSOR C_CAE (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
       SELECT /*+ APPEND */ MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC_CFC_FUG_ISI_MNEMONICO ISIN
          ,FUG_ENA_MNEMONICO EMISOR
          ,MCC_TMC_MNEMONICO
    FROM MOVIMIENTOS_CUENTA_CORREDORES, FUNGIBLES
    WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
      AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
      AND MCC_CCC_NUMERO_CUENTA = P_CTA
      AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
      AND MCC_CFC_FUG_MNEMONICO = FUG_MNEMONICO
      AND MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_TMC_MNEMONICO = 'CAE'
      AND MCC_PAGADO IS NULL
      AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, MCC_CFC_FUG_ISI_MNEMONICO, FUG_ENA_MNEMONICO,MCC_TMC_MNEMONICO;
  V_CAE C_CAE%ROWTYPE;

  ERRORSQL         VARCHAR2(100);
  V_COMM           NUMBER := 0;
  V_TIPO_PAGO      VARCHAR2(5);
  V_MONTO_ABD      NUMBER := 0;
  --V_MONTO_ABD_NETO NUMBER := 0;
  V_MONTO_SERVICIO NUMBER := 0;
  V_MONTO_STR      NUMBER := 0;
  V_MONTO          NUMBER := 0;
  TOTAL_ODP        NUMBER := 0;
  V_MONTO_GMF      NUMBER := 0;
  V_MONTO_ORDEN1   NUMBER := 0;
  V_EXCENTO1       VARCHAR2(1) := NULL;
  V_IBA1           CONSTANTES.CON_VALOR%TYPE:= NULL;
  V_MONTO_MAX_ACH  NUMBER;
  V_MONTO_MAX_POD  NUMBER;
  P_ISIN           VARCHAR2(50);

  -- SORTIZ VAGTUD698-1
  V_MONTO_ICA   NUMBER;
  V_MONTO_CREE  NUMBER;
  V_MONTO_ADI   NUMBER;
  -- FIN SORTIZ

  CCC1_CCC_SALDO_ADMON_VALORES CUENTAS_CLIENTE_CORREDORES.CCC_SALDO_ADMON_VALORES%TYPE;

  V_RETEFTE         NUMBER := 0; -- SORTIZ VAGTUD698-2
  V_CAE_M           NUMBER := 0;
  V_IPD_TPA_MNEMONICO VARCHAR2(3);
BEGIN
   --Se identifican las instrucciones a ejecutar, si el cliente tuvo ABD en el SYSDATE.
   V_COMM := 0;
   V_IBA1           := P_TDD_IBA;
   V_MONTO_MAX_ACH  := P_MONTO_MAX_ACH;
   V_MONTO_MAX_POD  := P_MONTO_MAX_POD;


      V_COMM := V_COMM + 1;

      P_CLI_PER_NUM_IDEN   := NULL;
      P_CLI_PER_TID_CODIGO := NULL;
      P_NUMERO_CUENTA      := NULL;
      P_ISIN               := NULL;

      P_CLI_PER_NUM_IDEN   := P_PER_NUM_IDEN;
      P_CLI_PER_TID_CODIGO := P_PER_TID_CODIGO;
      P_NUMERO_CUENTA      := P_CCC_NUMERO_CUENTA;
      P_ISIN               := P_FUG_ISI_MNEMONICO;

      V_EXCENTO1 := NVL(P_CLI_EXCENTO_DXM,'N');

      V_IPD_TPA_MNEMONICO := NULL;

      V_IPD_TPA_MNEMONICO := P_IPD_TPA_MNEMONICO;

      -- SE CALCULA EL SALDO DE ADMON VALORES QUE TIENE EL CLIENTE
      CCC1_CCC_SALDO_ADMON_VALORES := P_PAGOS_DIVIDENDOS.FN_SALDO_ADMON_VALORES (P_CLI_NUM_IDEN      => P_CLI_PER_NUM_IDEN
                                                                                ,P_CLI_TID_CODIGO    => P_CLI_PER_TID_CODIGO
                                                                                ,P_CUENTA            => P_NUMERO_CUENTA
                                                                                ,P_SALDO_RECALCULADO => 'N'
                                                                                ,P_SALDO_ODP         => TOTAL_ODP);


      IF P_IPD_TIPO_EMISOR = 'T'
         AND P_IPD_PAGO = 'S'
         AND P_IPD_TRASLADO_FONDOS = 'N'
         AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN

         V_MONTO := 0;

         OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
         FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
         IF DIVIDENDOS_X_ISIN%FOUND THEN
            V_MONTO := 0;
            V_MONTO_SERVICIO := 0;

            OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
            FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
            CLOSE MONTO_SERVICIO;

            -- SORTIZ VAGTUD698-1
            V_IMPUESTOS := NULL;
            OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
            FETCH C_IMPUESTOS INTO V_IMPUESTOS;
            CLOSE C_IMPUESTOS;

            IF NVL(V_IMPUESTOS.MONTO,0) != 0 THEN
               IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
                  V_MONTO_ICA := V_IMPUESTOS.MONTO;
               ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
                  V_MONTO_CREE := V_IMPUESTOS.MONTO;
               ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
                  V_MONTO_ADI := V_IMPUESTOS.MONTO;
               END IF;
            ELSE
               V_MONTO_ICA := 0;
               V_MONTO_CREE := 0;
               V_MONTO_ADI := 0;
            END IF;

            V_MONTO_ICA := NVL(V_MONTO_ICA,0);
            V_MONTO_CREE := NVL(V_MONTO_CREE,0);
            V_MONTO_ADI := NVL(V_MONTO_ADI,0);
            -- FIN SORTIZ

            -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

        --REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --

        IF (P_IPD_PAGAR_A = 'C'
           AND V_IPD_TPA_MNEMONICO IN ('CHE','CHG')
           AND P_IPD_CRUCE_CHEQUE IN ('CA'))
            OR (P_IPD_PAGAR_A = 'C'
           AND V_IPD_TPA_MNEMONICO = 'TRB')
            OR (P_IPD_PAGAR_A = 'C'
           AND V_IPD_TPA_MNEMONICO = 'ACH')
            OR (NVL(V_EXCENTO1,'N')) = 'S' THEN

           --V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO; -- SORTIZ VAGTUD698-2
           V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M; -- SORTIZ VAGTUD698-2
           V_MONTO_GMF   := 0;
        ELSE
           --V_MONTO_ORDEN1 := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO) / (1 + V_IBA1),2); -- SORTIZ VAGTUD698-2
           V_MONTO_ORDEN1 := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) / (1 + V_IBA1),2); -- SORTIZ VAGTUD698-2
           V_MONTO_GMF    := ROUND(V_MONTO_ORDEN1 * V_IBA1,2);
        END IF;

        IF P_ISIN = 'COB51PA00076'
            AND P_IPD_BAN_CODIGO = 51
              AND V_IPD_TPA_MNEMONICO = 'TRB' THEN
          V_IPD_TPA_MNEMONICO := 'STR';
        ELSIF P_ISIN = 'COC04PA00016'
            AND P_IPD_BAN_CODIGO = 51
              AND V_IPD_TPA_MNEMONICO = 'TRB' THEN
          V_IPD_TPA_MNEMONICO := 'TBP';
        END IF;

        IF NVL(P_IPD_VISADO,'N') = 'S' THEN
          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')
                  ,SYSDATE
                  ,P_CLI_PER_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO
                  ,P_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN
                  ,P_CCC_PER_TID_CODIGO
                  ,P_PER_NOMBRE_USUARIO
                  ,0
                  ,0
                  ,'N'
                  ,V_IPD_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO
                  ,V_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'
                  ,'NO TIENE SALDO'
                  ,P_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))   --TIPM_FUENTE
                  ,36
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_TIPO_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')
                ,SYSDATE
                ,P_CLI_PER_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO
                ,P_NUMERO_CUENTA
                ,P_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN
                ,P_CCC_PER_TID_CODIGO
                ,P_PER_NOMBRE_USUARIO
                ,V_MONTO_ORDEN1
                ,V_MONTO_GMF
                ,'N'
                ,V_IPD_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO
                ,V_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'AOK'
                ,'ALISTAMIENTO OK'
                ,P_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR
                ,P_IPD_TIPO_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
								,V_CAE_M																			 -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  --TIPM_FUENTE
                ,37
                );
            ELSE
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')
                  ,SYSDATE
                  ,P_CLI_PER_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO
                  ,P_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN
                  ,P_CCC_PER_TID_CODIGO
                  ,P_PER_NOMBRE_USUARIO
                  ,0
                  ,0
                  ,'N'
                  ,V_IPD_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO
                  ,V_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'
                  ,'SALDO ADMON VALORES NEGATIVO'
                  ,P_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  --TIPM_FUENTE
                  ,38
                  );
            END IF;
          END IF;
        ELSE
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
              (TIPM_CONSECUTIVO
              ,TIPM_ORIGEN_CLIENTE
              ,TIPM_FECHA
              ,TIPM_NUM_IDEN
              ,TIPM_TID_CODIGO
              ,TIPM_NUMERO_CUENTA
              ,TIPM_IPD_CONSECUTIVO
              ,TIPM_NUM_IDEN_COMER
              ,TIPM_TID_CODIGO_COMER
              ,TIPM_USUARIO_COMER
              ,TIPM_MONTO_ODP
              ,TIPM_MONTO_GMF
              ,TIPM_PROCESADO
              ,TIPM_TPA_MNEMONICO
              ,TIPM_MONTO_ABD
              ,TIPM_MONTO_SERVICIO
              ,TIPM_MONTO_ABD_NETO
              ,TIPM_ESTADO
              ,TIPM_DESCRIPCION
              ,TIPM_ISIN
              ,TIPM_EMISOR
              ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
              ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
              ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
              ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
              ,TIPM_GRAVAMEN
              ,TIPM_FUENTE
              ,TIPM_ORDEN
              )VALUES
              (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
              ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
              ,SYSDATE                                       -- TIPM_FECHA
              ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
              ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
              ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
              ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
              ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
              ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
              ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
              ,0                                             -- TIPM_MONTO_ODP
              ,0                                             -- TIPM_MONTO_GMF
              ,'N'                                           -- TIPM_PROCESADO
              ,V_IPD_TPA_MNEMONICO             -- TIPM_TPA_MNEMONICO
              ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
              ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
              ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
              ,'INV'                                         -- TIPM_ESTADO
              ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
              ,P_ISIN                    -- TIPM_ISIN
              ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
              ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
              ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
              ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
              ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
              ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                      -- TIPM_FUENTE
              ,39
              );
        END IF;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'T'
      AND P_IPD_PAGO = 'N'
        AND P_IPD_TRASLADO_FONDOS = 'S'
          AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
    V_MONTO := 0;
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
      V_MONTO_SERVICIO := 0;
      OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
      CLOSE MONTO_SERVICIO;

        -- SORTIZ VAGTUD698-1
        V_IMPUESTOS := NULL;
        OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_IMPUESTOS INTO V_IMPUESTOS;
        CLOSE C_IMPUESTOS;

        IF NVL(V_IMPUESTOS.MONTO,0) != 0 THEN
           IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
              V_MONTO_ICA := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
              V_MONTO_CREE := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
              V_MONTO_ADI := V_IMPUESTOS.MONTO;
           END IF;
        ELSE
           V_MONTO_ICA := 0;
           V_MONTO_CREE := 0;
           V_MONTO_ADI := 0;
        END IF;

        V_MONTO_ICA := NVL(V_MONTO_ICA,0);
        V_MONTO_CREE := NVL(V_MONTO_CREE,0);
        V_MONTO_ADI := NVL(V_MONTO_ADI,0);
        -- FIN SORTIZ

        -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

				--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --

      IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'FON'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,NULL                                          -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                -- TIPM_FUENTE
                  ,40
                  );
      ELSE
        IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
          IF NVL(P_IPD_VISADO,'N') = 'S' THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'FON'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,NULL                                          -- TIPM_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
											,V_CAE_M																			 -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,41
                      );
            ELSE
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'FON'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'INV'                                         -- TIPM_ESTADO
                  ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,NULL                                          -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,42
                  );
            END IF;
        ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO                             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'FON'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,NULL                                          -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,43
                  );
        END IF;
      END IF;
     FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'E'
      AND P_IPD_PAGO = 'S'
        AND P_IPD_TRASLADO_FONDOS = 'N'
          AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
       V_MONTO := 0;
       V_MONTO_SERVICIO := 0;
       OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
       FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
       CLOSE MONTO_SERVICIO;

        -- SORTIZ VAGTUD698-1
        V_IMPUESTOS := NULL;
        OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_IMPUESTOS INTO V_IMPUESTOS;
        CLOSE C_IMPUESTOS;

        IF NVL(V_IMPUESTOS.MONTO,0) != 0 THEN
           IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
              V_MONTO_ICA := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
              V_MONTO_CREE := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
              V_MONTO_ADI := V_IMPUESTOS.MONTO;
           END IF;
        ELSE
           V_MONTO_ICA := 0;
           V_MONTO_CREE := 0;
           V_MONTO_ADI := 0;
        END IF;

        V_MONTO_ICA := NVL(V_MONTO_ICA,0);
        V_MONTO_CREE := NVL(V_MONTO_CREE,0);
        V_MONTO_ADI := NVL(V_MONTO_ADI,0);
        -- FIN SORTIZ

        -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

				--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --
      IF (P_IPD_PAGAR_A = 'C' AND
            V_IPD_TPA_MNEMONICO IN ('CHE','CHG') AND
              P_IPD_CRUCE_CHEQUE IN ('CA')) OR
      (P_IPD_PAGAR_A = 'C' AND
         V_IPD_TPA_MNEMONICO = 'TRB') OR
      (P_IPD_PAGAR_A = 'C' AND
         V_IPD_TPA_MNEMONICO = 'ACH') OR
      (NVL(V_EXCENTO1,'N')) = 'S' THEN
        --V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO; -- sortiz VAGTUD698-2
        V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M; -- sortiz VAGTUD698-2
        V_MONTO_GMF   := 0;
      ELSE
        --V_MONTO_ORDEN1  := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO) / (1 + V_IBA1),2);
        V_MONTO_ORDEN1  := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) / (1 + V_IBA1),2);
        V_MONTO_GMF   := ROUND(V_MONTO_ORDEN1 * V_IBA1,2);
      END IF;

      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'TRB'
          AND REC_INSTRUCCION_E.IPD_BAN_CODIGO =  51
            AND P_ISIN IN ('COB51PA00076','COC04PA00016') THEN

          IF P_ISIN = 'COB51PA00076' THEN
            REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'STR';
          ELSIF P_ISIN = 'COC04PA00016' THEN
            REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'TBP';
          END IF;

        END IF;

        IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'NTS'                                         -- TIPM_ESTADO
                ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
								,V_CAE_M																			 -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                ,44
                );
        ELSE
          IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
            IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'ACH' AND (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) > V_MONTO_MAX_ACH  THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'MAS'                                         -- TIPM_ESTADO
                  ,'MONTO ACH SUPERA EL M??XIMO PERMITIDO'        -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,45
                  );
            ELSE
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_TIPO_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
                    ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'AOK'                                         -- TIPM_ESTADO
                    ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1			   -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,46
                    );
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1	           -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,47
                    );
              END IF;
            END IF;
          ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'SAN'                                         -- TIPM_ESTADO
                ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
								,V_CAE_M																			 -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                ,48
                );
          END IF;
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,49
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'E'
     AND P_IPD_PAGO = 'N'
      AND P_IPD_TRASLADO_FONDOS = 'N'
      AND P_IPD_INSTRUCCION_POD = 'S' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA,P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
      V_MONTO := 0;
      V_MONTO_SERVICIO := 0;
      OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
      CLOSE MONTO_SERVICIO;

        -- SORTIZ VAGTUD698-1
        V_IMPUESTOS := NULL;
        OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_IMPUESTOS INTO V_IMPUESTOS;
        CLOSE C_IMPUESTOS;

        IF NVL(V_IMPUESTOS.MONTO,0) != 0  THEN
           IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
              V_MONTO_ICA := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
              V_MONTO_CREE := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
              V_MONTO_ADI := V_IMPUESTOS.MONTO;
           END IF;
        ELSE
           V_MONTO_ICA := 0;
           V_MONTO_CREE := 0;
           V_MONTO_ADI := 0;
        END IF;

        V_MONTO_ICA := NVL(V_MONTO_ICA,0);
        V_MONTO_CREE := NVL(V_MONTO_CREE,0);
        V_MONTO_ADI := NVL(V_MONTO_ADI,0);
        -- FIN SORTIZ

        -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

				--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --

      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF P_ISIN IN ('COB51PA00076','COC04PA00016','COE15PA00026') THEN
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'POD';
        ELSE
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := NULL;
        END IF;

        IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'POD' THEN

          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,50
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                IF (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_TIPO_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'POD'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                      ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1			 -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
											,V_CAE_M																			 -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,51
                      );
                ELSE
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
										,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'MPS'                                         -- TIPM_ESTADO
                    ,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,52
                    );
                END IF;
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,53
                    );
              END IF;
            ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1	         -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,54
                  );
            END IF;
          END IF;
        ELSE
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'CIN'                                         -- TIPM_ESTADO
                  ,'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP' -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,55
                  );
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
						,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,56
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  -- ojo nuevo
  ELSIF P_IPD_TIPO_EMISOR = 'E'
     AND P_IPD_PAGO = 'S'
      AND P_IPD_TRASLADO_FONDOS = 'N'
      AND P_IPD_INSTRUCCION_POD = 'S' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA,P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
      V_MONTO := 0;
      V_MONTO_SERVICIO := 0;
      OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
      CLOSE MONTO_SERVICIO;

        -- SORTIZ VAGTUD698-1
        V_IMPUESTOS := NULL;
        OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_IMPUESTOS INTO V_IMPUESTOS;
        CLOSE C_IMPUESTOS;

        IF NVL(V_IMPUESTOS.MONTO,0) != 0  THEN
           IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
              V_MONTO_ICA := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
              V_MONTO_CREE := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
              V_MONTO_ADI := V_IMPUESTOS.MONTO;
           END IF;
        ELSE
           V_MONTO_ICA := 0;
           V_MONTO_CREE := 0;
           V_MONTO_ADI := 0;
        END IF;

        V_MONTO_ICA := NVL(V_MONTO_ICA,0);
        V_MONTO_CREE := NVL(V_MONTO_CREE,0);
        V_MONTO_ADI := NVL(V_MONTO_ADI,0);
        -- FIN SORTIZ

        -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

				--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --

      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF P_ISIN IN ('COB51PA00076','COC04PA00016','COE15PA00026') THEN
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'POD';
        ELSE
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := NULL;
        END IF;
        IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'POD' THEN
          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,57
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                IF (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_TIPO_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'POD'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                      ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1			 -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
											,V_CAE_M																			 -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,58
                      );
                ELSE
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'MPS'                                         -- TIPM_ESTADO
                    ,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M 																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,59
                    );
                END IF;
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,60
                    );
              END IF;
            ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1	           -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,61
                  );
            END IF;
          END IF;
        ELSE
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'CIN'                                         -- TIPM_ESTADO
                  ,'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP' -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,62
                  );
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
						,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,63
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

   -- **************************************************************************
   -- **************************************************************************

  ELSIF  P_IPD_TIPO_EMISOR = 'T'
     AND P_IPD_PAGO = 'S'
      AND P_IPD_TRASLADO_FONDOS = 'N'
      AND P_IPD_INSTRUCCION_POD = 'S' THEN

    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA,P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
      V_MONTO := 0;
      V_MONTO_SERVICIO := 0;
      OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
      CLOSE MONTO_SERVICIO;

        -- SORTIZ VAGTUD698-1
        V_IMPUESTOS := NULL;
        OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_IMPUESTOS INTO V_IMPUESTOS;
        CLOSE C_IMPUESTOS;

        IF NVL(V_IMPUESTOS.MONTO,0) != 0  THEN
           IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
              V_MONTO_ICA := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
              V_MONTO_CREE := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
              V_MONTO_ADI := V_IMPUESTOS.MONTO;
           END IF;
        ELSE
           V_MONTO_ICA := 0;
           V_MONTO_CREE := 0;
           V_MONTO_ADI := 0;
        END IF;

        V_MONTO_ICA := NVL(V_MONTO_ICA,0);
        V_MONTO_CREE := NVL(V_MONTO_CREE,0);
        V_MONTO_ADI := NVL(V_MONTO_ADI,0);
        -- FIN SORTIZ

        -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

				--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --

          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,64
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                IF (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_TIPO_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'POD'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                      ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1				     -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
											,V_CAE_M																			 -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,65
                      );
                ELSE
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'MPS'                                         -- TIPM_ESTADO
                    ,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,66
                    );
                END IF;
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,67
                    );
              END IF;
            ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1	         -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
									,V_CAE_M																			 -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,68
                  );
            END IF;
          END IF;
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;
   -- fin nuevo

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'E'
      AND P_IPD_PAGO = 'N'
        AND P_IPD_TRASLADO_FONDOS = 'S'
          AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
      V_MONTO := 0;
      V_MONTO_SERVICIO := 0;
      OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
      CLOSE MONTO_SERVICIO;

        -- SORTIZ VAGTUD698-1
        V_IMPUESTOS := NULL;
        OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_IMPUESTOS INTO V_IMPUESTOS;
        CLOSE C_IMPUESTOS;

        IF NVL(V_IMPUESTOS.MONTO,0) != 0  THEN
           IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
              V_MONTO_ICA := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
              V_MONTO_CREE := V_IMPUESTOS.MONTO;
           ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
              V_MONTO_ADI := V_IMPUESTOS.MONTO;
           END IF;
        ELSE
           V_MONTO_ICA := 0;
           V_MONTO_CREE := 0;
           V_MONTO_ADI := 0;
        END IF;

        V_MONTO_ICA := NVL(V_MONTO_ICA,0);
        V_MONTO_CREE := NVL(V_MONTO_CREE,0);
        V_MONTO_ADI := NVL(V_MONTO_ADI,0);
        -- FIN SORTIZ

        -- SORTIZ VAGTUD698-2
        V_RETEFUENTE := NULL;
        OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_RETEFUENTE INTO V_RETEFUENTE;
        IF C_RETEFUENTE%FOUND THEN
           V_RETEFTE := V_RETEFUENTE.MONTO;
        ELSE
           V_RETEFTE := 0;
        END IF;
        CLOSE C_RETEFUENTE;
        V_RETEFTE := NVL(V_RETEFTE,0);
        -- FIN SORTIZ

				--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --

      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,'FON'                                         -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'NTS'                                         -- TIPM_ESTADO
                ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2              -- TIPM_RETEFUENTE
								,V_CAE_M																				-- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                          -- TIPM_FUENTE
                ,69
                );
        ELSE
          IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
            IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'FON'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'AOK'                                         -- TIPM_ESTADO
                    ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,70
                    );
            ELSE
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'FON'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
										,V_CAE_M																			 -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,71
                    );
            END IF;
          ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,'FON'                                         -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'SAN'                                         -- TIPM_ESTADO
                ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1		         -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
								,V_CAE_M																			 -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                ,72
                );
          END IF;
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,73
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSE
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
          IF DIVIDENDOS_X_ISIN%FOUND THEN

    --CLOSE DIVIDENDOS_X_ISIN;

    OPEN MONTO_SERVICIO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, NVL(P_ISIN,REC_DIVIDENDOS_X_ISIN.ISIN));
    FETCH MONTO_SERVICIO INTO V_MONTO_SERVICIO;
    CLOSE MONTO_SERVICIO;

    -- SORTIZ VAGTUD698-1
    V_IMPUESTOS := NULL;
    OPEN C_IMPUESTOS(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, NVL(P_ISIN,REC_DIVIDENDOS_X_ISIN.ISIN));
    FETCH C_IMPUESTOS INTO V_IMPUESTOS;
    CLOSE C_IMPUESTOS;

    IF NVL(V_IMPUESTOS.MONTO,0) != 0 THEN
       IF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RIC' THEN
          V_MONTO_ICA := V_IMPUESTOS.MONTO;
       ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'RCR' THEN
          V_MONTO_CREE := V_IMPUESTOS.MONTO;
       ELSIF V_IMPUESTOS.MCC_TMC_MNEMONICO = 'ADI' THEN
          V_MONTO_ADI := V_IMPUESTOS.MONTO;
       END IF;
    ELSE
       V_MONTO_ICA := 0;
       V_MONTO_CREE := 0;
       V_MONTO_ADI := 0;
    END IF;

    V_MONTO_ICA := NVL(V_MONTO_ICA,0);
    V_MONTO_CREE := NVL(V_MONTO_CREE,0);
    V_MONTO_ADI := NVL(V_MONTO_ADI,0);
    -- FIN SORTIZ

    -- SORTIZ VAGTUD698-2
    V_RETEFUENTE := NULL;
    OPEN C_RETEFUENTE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, NVL(P_ISIN,REC_DIVIDENDOS_X_ISIN.ISIN));
    FETCH C_RETEFUENTE INTO V_RETEFUENTE;
    IF C_RETEFUENTE%FOUND THEN
       V_RETEFTE := V_RETEFUENTE.MONTO;
    ELSE
       V_RETEFTE := 0;
    END IF;
    CLOSE C_RETEFUENTE;
    V_RETEFTE := NVL(V_RETEFTE,0);
    -- FIN SORTIZ

		--REGISTRO MOVIMIENTO (CAE)
        V_CAE := NULL;
        OPEN C_CAE(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, NVL(P_ISIN,REC_DIVIDENDOS_X_ISIN.ISIN));
        FETCH C_CAE INTO V_CAE;
        IF C_CAE%FOUND THEN
           V_CAE_M := V_CAE.MONTO;
        ELSE
           V_CAE_M := 0;
        END IF;
        CLOSE C_CAE;
        V_CAE_M := NVL(V_CAE_M,0);
        --
    V_MONTO_ORDEN1  := NVL(REC_DIVIDENDOS_X_ISIN.MONTO, 0) + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M; -- SORTIZ VAGTUD698-2
    V_MONTO_GMF     := 0;
    INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,NVL(REC_DIVIDENDOS_X_ISIN.MONTO, 0)                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,NVL(REC_DIVIDENDOS_X_ISIN.MONTO, 0)+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,NVL(P_ISIN,REC_DIVIDENDOS_X_ISIN.ISIN)                    -- TIPM_ISIN
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1	           -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,74
            );

            END IF;
            CLOSE DIVIDENDOS_X_ISIN;
  END IF;

  /*UPDATE MOVIMIENTOS_CUENTA_CORREDORES
     SET MCC_PAGADO = 'N'
   WHERE MCC_CONSECUTIVO = P_SEC;   */
   IF P_FAV_CONSECUTIVO IS NULL THEN
    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
     SET MCC_PAGADO = 'N'
    WHERE MCC_CONSECUTIVO = P_SEC;
   ELSIF P_FAV_CONSECUTIVO IS NOT NULL THEN
    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
     SET MCC_PAGADO = 'N'
    WHERE MCC_FAV_CONSECUTIVO = P_FAV_CONSECUTIVO
    AND NVL(MCC_PAGADO,'N') = 'N';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);

      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS'
                                          ,P_ERROR       => P_CLI_PER_NUM_IDEN||';'||P_CLI_PER_TID_CODIGO||';'||P_NUMERO_CUENTA||';'||'OTROSERRORES'||sqlerrm
                                          ,P_TABLA_ERROR => NULL);
END PROCESO_PAGOS_MASIVOS_DIV;

--
PROCEDURE PROCESO_PAGOS_MASIVOS_DIV_M (P_SEC IN NUMBER
                                    ,P_PER_NUM_IDEN IN VARCHAR2
                                    ,P_PER_TID_CODIGO IN VARCHAR2
                                    ,P_CCC_NUMERO_CUENTA IN NUMBER
                                    ,P_FUG_ISI_MNEMONICO IN VARCHAR2
                                    ,P_CLI_EXCENTO_DXM IN VARCHAR2
                                    ,P_IPD_TIPO_EMISOR    IN VARCHAR2
                                    ,P_IPD_CONSECUTIVO    IN NUMBER
                                    ,P_IPD_TPA_MNEMONICO  IN VARCHAR2
                                    ,P_IPD_BAN_CODIGO     IN NUMBER
                                    ,P_IPD_VISADO         IN VARCHAR2
                                    ,P_IPD_PAGO           IN VARCHAR2
                                    ,P_IPD_TRASLADO_FONDOS  IN VARCHAR2
                                    ,P_IPD_INSTRUCCION_POD  IN VARCHAR2
                                    ,P_IPD_PAGAR_A        IN VARCHAR2
                                    ,P_IPD_CRUCE_CHEQUE   IN VARCHAR2
                                    ,P_MONTO_MAX_POD      IN NUMBER
                                    ,P_MONTO_MAX_ACH      IN NUMBER
                                    ,P_TDD_IBA            IN NUMBER
                                    ,P_PER_SUC_CODIGO     IN NUMBER
                                    ,P_PER_NOMBRE_USUARIO IN VARCHAR2
                                    ,P_CCC_PER_NUM_IDEN   IN VARCHAR2
                                    ,P_CCC_PER_TID_CODIGO IN VARCHAR2
                                      ,P_FAV_CONSECUTIVO IN NUMBER DEFAULT NULL) IS

  P_CLI_PER_NUM_IDEN          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
  P_CLI_PER_TID_CODIGO        CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
  P_NUMERO_CUENTA             CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;


  -- CLIENTES CON ABD DEL DIA DEL ABONO Y QUE ESTAN PENDIENTES DE EJECUTAR EL PAGO MASIVO PARA EL ISIN ESPECIFICO
  CURSOR DIVIDENDOS_X_ISIN (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT  MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA , SUM (MONTO)MONTO, ISIN, EMISOR
    FROM (SELECT /*+ APPEND */ MCC_CCC_CLI_PER_NUM_IDEN
                ,MCC_CCC_CLI_PER_TID_CODIGO
                ,MCC_CCC_NUMERO_CUENTA
                ,SUM(MCC_MONTO_ADMON_VALORES) MONTO
                ,MCC_CFC_FUG_ISI_MNEMONICO ISIN
                ,FUG_ENA_MNEMONICO EMISOR
          FROM MOVIMIENTOS_CUENTA_CORREDORES, FUNGIBLES
          WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
            AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
            AND MCC_CCC_NUMERO_CUENTA = P_CTA
            AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
            AND MCC_CFC_FUG_MNEMONICO = FUG_MNEMONICO
            AND MCC_FECHA >= TRUNC(SYSDATE)
            AND MCC_FECHA < TRUNC(SYSDATE+1)
            AND MCC_TMC_MNEMONICO = 'ABD'
            AND MCC_PAGADO IS NULL
            AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
          GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, MCC_CFC_FUG_ISI_MNEMONICO, FUG_ENA_MNEMONICO
          UNION
          SELECT /*+ APPEND */ MCC.MCC_CCC_CLI_PER_NUM_IDEN,
                 MCC.MCC_CCC_CLI_PER_TID_CODIGO,
                 MCC.MCC_CCC_NUMERO_CUENTA,
                 SUM(MCC.MCC_MONTO_ADMON_VALORES) MONTO,
                 MCC.MCC_CFC_FUG_ISI_MNEMONICO ISIN,
                 FUG.FUG_ENA_MNEMONICO EMISOR
          FROM  MOVIMIENTOS_CUENTA_CORREDORES MCC, FUNGIBLES FUG, AJUSTES_CLIENTES ACL
          WHERE MCC.MCC_ACL_CONSECUTIVO = ACL.ACL_CONSECUTIVO
          AND   MCC.MCC_SUC_CODIGO = ACL.ACL_SUC_CODIGO
          AND   MCC.MCC_NEG_CONSECUTIVO = ACL.ACL_NEG_CONSECUTIVO
          AND   MCC.MCC_CFC_FUG_ISI_MNEMONICO = FUG.FUG_ISI_MNEMONICO
          AND   MCC.MCC_CFC_FUG_MNEMONICO = FUG.FUG_MNEMONICO
          AND   MCC.MCC_CCC_CLI_PER_NUM_IDEN = P_ID
          AND   MCC.MCC_CCC_CLI_PER_TID_CODIGO = P_TID
          AND   MCC.MCC_CCC_NUMERO_CUENTA = P_CTA
          AND   MCC.MCC_FECHA >= TRUNC(SYSDATE)
          AND   MCC.MCC_FECHA < TRUNC(SYSDATE+1)
          AND   MCC.MCC_PAGADO IS NULL
          AND   MCC.MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
          AND   MCC.MCC_CFC_FUG_ISI_MNEMONICO IN (SELECT PMI_ISIN
                                                  FROM PAGOS_MASIVOS_ISIN
                                                  WHERE PMI_FECHA >= TRUNC(SYSDATE-1)
                                                  AND PMI_FECHA < TRUNC(SYSDATE+1)
                                                  AND PMI_PAGADO = 'P')
          AND   ACL.ACL_CAJ_MNEMONICO IN (SELECT CAJ_MNEMONICO
                                          FROM CONCEPTOS_AJUSTES
                                          WHERE CAJ_TIPO_SALDO = 'ADVAL')
          GROUP BY MCC.MCC_CCC_CLI_PER_NUM_IDEN, MCC.MCC_CCC_CLI_PER_TID_CODIGO, MCC.MCC_CCC_NUMERO_CUENTA, MCC.MCC_CFC_FUG_ISI_MNEMONICO, FUG.FUG_ENA_MNEMONICO)
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, ISIN, EMISOR;
  REC_DIVIDENDOS_X_ISIN DIVIDENDOS_X_ISIN%ROWTYPE;

  -- INSTRUCCIONES DE PAGO ACTIVAS DE ORIGEN DE PAGO "DIVIDENDOS" PARA ISIN ESPECIFICO
  CURSOR INSTRUCCION_E (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT /*+ APPEND */ IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
    FROM INSTRUCCIONES_PAGOS_DIVIDENDOS, DETALLE_INSTRUCCIONES_PAGOS
    WHERE IPD_CONSECUTIVO = DIPA_IPD_CONSECUTIVO
      AND IPD_CCC_CLI_PER_NUM_IDEN = P_ID
      AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
      AND IPD_CCC_NUMERO_CUENTA = P_CTA
      AND IPD_TIPO_EMISOR = 'E'
      AND IPD_ESTADO = 'A'
      AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
      AND IPD_TIPO_ORIGEN_PAGO IN ('DI', 'SD')
      AND DIPA_FUG_ISI_MNEMONICO = P_ISIN;
  REC_INSTRUCCION_E INSTRUCCION_E%ROWTYPE;


  ERRORSQL         VARCHAR2(100);
  V_COMM           NUMBER := 0;
  V_TIPO_PAGO      VARCHAR2(5);
  V_MONTO_ABD      NUMBER := 0;
  --V_MONTO_ABD_NETO NUMBER := 0;
  V_MONTO_SERVICIO NUMBER := 0;
  V_MONTO_STR      NUMBER := 0;
  V_MONTO          NUMBER := 0;
  TOTAL_ODP        NUMBER := 0;
  V_MONTO_GMF      NUMBER := 0;
  V_MONTO_ORDEN1   NUMBER := 0;
  V_EXCENTO1       VARCHAR2(1) := NULL;
  V_IBA1           CONSTANTES.CON_VALOR%TYPE:= NULL;
  V_MONTO_MAX_ACH  NUMBER;
  V_MONTO_MAX_POD  NUMBER;
  P_ISIN           VARCHAR2(50);

  -- SORTIZ VAGTUD698-1
  V_MONTO_ICA   NUMBER := 0;
  V_MONTO_CREE  NUMBER := 0;
  V_MONTO_ADI   NUMBER := 0;
  -- FIN SORTIZ

  CCC1_CCC_SALDO_ADMON_VALORES CUENTAS_CLIENTE_CORREDORES.CCC_SALDO_ADMON_VALORES%TYPE;

  V_RETEFTE         NUMBER := 0; -- SORTIZ VAGTUD698-2
  V_CAE_M           NUMBER := 0;
  V_IPD_TPA_MNEMONICO VARCHAR2(3);
BEGIN
   --Se identifican las instrucciones a ejecutar, si el cliente tuvo ABD en el SYSDATE.
   V_COMM := 0;
   V_IBA1           := P_TDD_IBA;
   V_MONTO_MAX_ACH  := P_MONTO_MAX_ACH;
   V_MONTO_MAX_POD  := P_MONTO_MAX_POD;


      V_COMM := V_COMM + 1;

      P_CLI_PER_NUM_IDEN   := NULL;
      P_CLI_PER_TID_CODIGO := NULL;
      P_NUMERO_CUENTA      := NULL;
      P_ISIN               := NULL;

      P_CLI_PER_NUM_IDEN   := P_PER_NUM_IDEN;
      P_CLI_PER_TID_CODIGO := P_PER_TID_CODIGO;
      P_NUMERO_CUENTA      := P_CCC_NUMERO_CUENTA;
      P_ISIN               := P_FUG_ISI_MNEMONICO;

      V_EXCENTO1 := NVL(P_CLI_EXCENTO_DXM,'N');

      V_IPD_TPA_MNEMONICO := NULL;

      V_IPD_TPA_MNEMONICO := P_IPD_TPA_MNEMONICO;

      -- SE CALCULA EL SALDO DE ADMON VALORES QUE TIENE EL CLIENTE
      CCC1_CCC_SALDO_ADMON_VALORES := P_PAGOS_DIVIDENDOS.FN_SALDO_ADMON_VALORES (P_CLI_NUM_IDEN      => P_CLI_PER_NUM_IDEN
                                                                                ,P_CLI_TID_CODIGO    => P_CLI_PER_TID_CODIGO
                                                                                ,P_CUENTA            => P_NUMERO_CUENTA
                                                                                ,P_SALDO_RECALCULADO => 'N'
                                                                                ,P_SALDO_ODP         => TOTAL_ODP);


      IF P_IPD_TIPO_EMISOR = 'T'
         AND P_IPD_PAGO = 'S'
         AND P_IPD_TRASLADO_FONDOS = 'N'
         AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN

         V_MONTO := 0;

         OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
         FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
         IF DIVIDENDOS_X_ISIN%FOUND THEN
            V_MONTO := 0;
            V_MONTO_SERVICIO := 0;


        IF (P_IPD_PAGAR_A = 'C'
           AND V_IPD_TPA_MNEMONICO IN ('CHE','CHG')
           AND P_IPD_CRUCE_CHEQUE IN ('CA'))
            OR (P_IPD_PAGAR_A = 'C'
           AND V_IPD_TPA_MNEMONICO = 'TRB')
            OR (P_IPD_PAGAR_A = 'C'
           AND V_IPD_TPA_MNEMONICO = 'ACH')
            OR (NVL(V_EXCENTO1,'N')) = 'S' THEN

           --V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO; -- SORTIZ VAGTUD698-2
           V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M; -- SORTIZ VAGTUD698-2
           V_MONTO_GMF   := 0;
        ELSE
           --V_MONTO_ORDEN1 := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO) / (1 + V_IBA1),2); -- SORTIZ VAGTUD698-2
           V_MONTO_ORDEN1 := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) / (1 + V_IBA1),2); -- SORTIZ VAGTUD698-2
           V_MONTO_GMF    := ROUND(V_MONTO_ORDEN1 * V_IBA1,2);
        END IF;

        IF P_ISIN = 'COB51PA00076'
            AND P_IPD_BAN_CODIGO = 51
              AND V_IPD_TPA_MNEMONICO = 'TRB' THEN
          V_IPD_TPA_MNEMONICO := 'STR';
        ELSIF P_ISIN = 'COC04PA00016'
            AND P_IPD_BAN_CODIGO = 51
              AND V_IPD_TPA_MNEMONICO = 'TRB' THEN
          V_IPD_TPA_MNEMONICO := 'TBP';
        END IF;

        IF NVL(P_IPD_VISADO,'N') = 'S' THEN
          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')
                  ,SYSDATE
                  ,P_CLI_PER_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO
                  ,P_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN
                  ,P_CCC_PER_TID_CODIGO
                  ,P_PER_NOMBRE_USUARIO
                  ,0
                  ,0
                  ,'N'
                  ,V_IPD_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO
                  ,V_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'
                  ,'NO TIENE SALDO'
                  ,P_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))
                  ,76
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_TIPO_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')
                ,SYSDATE
                ,P_CLI_PER_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO
                ,P_NUMERO_CUENTA
                ,P_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN
                ,P_CCC_PER_TID_CODIGO
                ,P_PER_NOMBRE_USUARIO
                ,V_MONTO_ORDEN1
                ,V_MONTO_GMF
                ,'N'
                ,V_IPD_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO
                ,V_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'AOK'
                ,'ALISTAMIENTO OK'
                ,P_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR
                ,P_IPD_TIPO_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                ,V_CAE_M                                       -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))
                ,77
                );
            ELSE
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')
                  ,SYSDATE
                  ,P_CLI_PER_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO
                  ,P_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN
                  ,P_CCC_PER_TID_CODIGO
                  ,P_PER_NOMBRE_USUARIO
                  ,0
                  ,0
                  ,'N'
                  ,V_IPD_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO
                  ,V_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'
                  ,'SALDO ADMON VALORES NEGATIVO'
                  ,P_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))
                  ,78
                  );
            END IF;
          END IF;
        ELSE
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
              (TIPM_CONSECUTIVO
              ,TIPM_ORIGEN_CLIENTE
              ,TIPM_FECHA
              ,TIPM_NUM_IDEN
              ,TIPM_TID_CODIGO
              ,TIPM_NUMERO_CUENTA
              ,TIPM_IPD_CONSECUTIVO
              ,TIPM_NUM_IDEN_COMER
              ,TIPM_TID_CODIGO_COMER
              ,TIPM_USUARIO_COMER
              ,TIPM_MONTO_ODP
              ,TIPM_MONTO_GMF
              ,TIPM_PROCESADO
              ,TIPM_TPA_MNEMONICO
              ,TIPM_MONTO_ABD
              ,TIPM_MONTO_SERVICIO
              ,TIPM_MONTO_ABD_NETO
              ,TIPM_ESTADO
              ,TIPM_DESCRIPCION
              ,TIPM_ISIN
              ,TIPM_EMISOR
              ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
              ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
              ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
              ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
              ,TIPM_GRAVAMEN
              ,TIPM_FUENTE
              ,TIPM_ORDEN
              )VALUES
              (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
              ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
              ,SYSDATE                                       -- TIPM_FECHA
              ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
              ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
              ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
              ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
              ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
              ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
              ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
              ,0                                             -- TIPM_MONTO_ODP
              ,0                                             -- TIPM_MONTO_GMF
              ,'N'                                           -- TIPM_PROCESADO
              ,V_IPD_TPA_MNEMONICO             -- TIPM_TPA_MNEMONICO
              ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
              ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
              ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
              ,'INV'                                         -- TIPM_ESTADO
              ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
              ,P_ISIN                    -- TIPM_ISIN
              ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
              ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
              ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
              ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
              ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
              ,V_CAE_M                                       -- TIPM_GRAVAMEN
              ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
              ,79
              );
        END IF;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'T'
      AND P_IPD_PAGO = 'N'
        AND P_IPD_TRASLADO_FONDOS = 'S'
          AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
    V_MONTO := 0;
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN

      IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'FON'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,NULL                                          -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,80
                  );
      ELSE
        IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
          IF NVL(P_IPD_VISADO,'N') = 'S' THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'FON'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,NULL                                          -- TIPM_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                      ,V_CAE_M                                       -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,81
                      );
            ELSE
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO               -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'FON'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'INV'                                         -- TIPM_ESTADO
                  ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,NULL                                          -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,82
                  );
            END IF;
        ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,P_IPD_CONSECUTIVO                             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'FON'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,NULL                                          -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,83
                  );
        END IF;
      END IF;
     FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'E'
      AND P_IPD_PAGO = 'S'
        AND P_IPD_TRASLADO_FONDOS = 'N'
          AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN

       IF (P_IPD_PAGAR_A = 'C' AND
            V_IPD_TPA_MNEMONICO IN ('CHE','CHG') AND
              P_IPD_CRUCE_CHEQUE IN ('CA')) OR
      (P_IPD_PAGAR_A = 'C' AND
         V_IPD_TPA_MNEMONICO = 'TRB') OR
      (P_IPD_PAGAR_A = 'C' AND
         V_IPD_TPA_MNEMONICO = 'ACH') OR
      (NVL(V_EXCENTO1,'N')) = 'S' THEN
        --V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO; -- sortiz VAGTUD698-2
        V_MONTO_ORDEN1  := REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M; -- sortiz VAGTUD698-2
        V_MONTO_GMF   := 0;
      ELSE
        --V_MONTO_ORDEN1  := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO) / (1 + V_IBA1),2);
        V_MONTO_ORDEN1  := ROUND((REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) / (1 + V_IBA1),2);
        V_MONTO_GMF   := ROUND(V_MONTO_ORDEN1 * V_IBA1,2);
      END IF;

      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'TRB'
          AND REC_INSTRUCCION_E.IPD_BAN_CODIGO =  51
            AND P_ISIN IN ('COB51PA00076','COC04PA00016') THEN

          IF P_ISIN = 'COB51PA00076' THEN
            REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'STR';
          ELSIF P_ISIN = 'COC04PA00016' THEN
            REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'TBP';
          END IF;

        END IF;

        IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'NTS'                                         -- TIPM_ESTADO
                ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                ,V_CAE_M                                       -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                ,84
                );
        ELSE
          IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
            IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'ACH' AND (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) > V_MONTO_MAX_ACH  THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'MAS'                                         -- TIPM_ESTADO
                  ,'MONTO ACH SUPERA EL M??XIMO PERMITIDO'        -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,85
                  );
            ELSE
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_TIPO_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
                    ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'AOK'                                         -- TIPM_ESTADO
                    ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1        -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,86
                    );
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,87
                    );
              END IF;
            END IF;
          ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,REC_INSTRUCCION_E.IPD_TPA_MNEMONICO           -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'SAN'                                         -- TIPM_ESTADO
                ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                ,V_CAE_M                                       -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                ,88
                );
          END IF;
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
            ,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,89
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'E'
     AND P_IPD_PAGO = 'N'
      AND P_IPD_TRASLADO_FONDOS = 'N'
      AND P_IPD_INSTRUCCION_POD = 'S' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA,P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN

      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF P_ISIN IN ('COB51PA00076','COC04PA00016','COE15PA00026') THEN
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'POD';
        ELSE
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := NULL;
        END IF;

        IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'POD' THEN

          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,90
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                IF (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_TIPO_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'POD'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                      ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1      -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                      ,V_CAE_M                                       -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,91
                      );
                ELSE
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'MPS'                                         -- TIPM_ESTADO
                    ,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,92
                    );
                END IF;
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,93
                    );
              END IF;
            ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1          -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,94
                  );
            END IF;
          END IF;
        ELSE
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'CIN'                                         -- TIPM_ESTADO
                  ,'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP' -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,95
                  );
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
            ,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,96
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  -- ojo nuevo
  ELSIF P_IPD_TIPO_EMISOR = 'E'
     AND P_IPD_PAGO = 'S'
      AND P_IPD_TRASLADO_FONDOS = 'N'
      AND P_IPD_INSTRUCCION_POD = 'S' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA,P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN
      V_MONTO := 0;
      V_MONTO_SERVICIO := 0;


      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF P_ISIN IN ('COB51PA00076','COC04PA00016') THEN
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'POD';
        ELSE
          REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := NULL;
        END IF;
        IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'POD' THEN
          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,97
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                IF (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_TIPO_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'POD'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                      ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1      -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                      ,V_CAE_M                                       -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,98
                      );
                ELSE
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'MPS'                                         -- TIPM_ESTADO
                    ,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,99
                    );
                END IF;
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,100
                    );
              END IF;
            ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,101
                  );
            END IF;
          END IF;
        ELSE
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'CIN'                                         -- TIPM_ESTADO
                  ,'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP' -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,102
                  );
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
            ,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,103
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

   -- **************************************************************************
   -- **************************************************************************

  ELSIF  P_IPD_TIPO_EMISOR = 'T'
     AND P_IPD_PAGO = 'S'
      AND P_IPD_TRASLADO_FONDOS = 'N'
      AND P_IPD_INSTRUCCION_POD = 'S' THEN

    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA,P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN

          IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'NTS'                                         -- TIPM_ESTADO
                  ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,104
                  );
          ELSE
            IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                IF (REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                      (TIPM_CONSECUTIVO
                      ,TIPM_ORIGEN_CLIENTE
                      ,TIPM_FECHA
                      ,TIPM_NUM_IDEN
                      ,TIPM_TID_CODIGO
                      ,TIPM_NUMERO_CUENTA
                      ,TIPM_IPD_CONSECUTIVO
                      ,TIPM_NUM_IDEN_COMER
                      ,TIPM_TID_CODIGO_COMER
                      ,TIPM_USUARIO_COMER
                      ,TIPM_MONTO_ODP
                      ,TIPM_MONTO_GMF
                      ,TIPM_PROCESADO
                      ,TIPM_TPA_MNEMONICO
                      ,TIPM_MONTO_ABD
                      ,TIPM_MONTO_SERVICIO
                      ,TIPM_MONTO_ABD_NETO
                      ,TIPM_ESTADO
                      ,TIPM_DESCRIPCION
                      ,TIPM_ISIN
                      ,TIPM_EMISOR
                      ,TIPM_TIPO_EMISOR
                      ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                      ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                      ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                      ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                      ,TIPM_GRAVAMEN
                      ,TIPM_FUENTE
                      ,TIPM_ORDEN
                      )VALUES
                      (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                      ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                      ,SYSDATE                                       -- TIPM_FECHA
                      ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                      ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                      ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                      ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                      ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                      ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                      ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                      ,0                                             -- TIPM_MONTO_GMF
                      ,'N'                                           -- TIPM_PROCESADO
                      ,'POD'                                         -- TIPM_TPA_MNEMONICO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                      ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                      ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                      ,'AOK'                                         -- TIPM_ESTADO
                      ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                      ,P_ISIN                    -- TIPM_ISIN
                      ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                      ,P_IPD_TIPO_EMISOR               -- TIPM_TIPO_EMISOR
                      ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                      ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                      ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                      ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                      ,V_CAE_M                                       -- TIPM_GRAVAMEN
                      ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                      ,105
                      );
                ELSE
                  INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'MPS'                                         -- TIPM_ESTADO
                    ,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,106
                    );
                END IF;
              ELSE
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'POD'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,107
                    );
              END IF;
            ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
                  ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                  ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                  ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                  ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                  ,TIPM_GRAVAMEN
                  ,TIPM_FUENTE
                  ,TIPM_ORDEN
                  )VALUES
                  (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                  ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                  ,SYSDATE                                       -- TIPM_FECHA
                  ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                  ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                  ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                  ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                  ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                  ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                  ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                  ,0                                             -- TIPM_MONTO_ODP
                  ,0                                             -- TIPM_MONTO_GMF
                  ,'N'                                           -- TIPM_PROCESADO
                  ,'POD'                                         -- TIPM_TPA_MNEMONICO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                  ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                  ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                  ,'SAN'                                         -- TIPM_ESTADO
                  ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                  ,P_ISIN                    -- TIPM_ISIN
                  ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                  ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                  ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                  ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1          -- TIPM_OTROS_IMPUESTOS
                  ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                  ,V_CAE_M                                       -- TIPM_GRAVAMEN
                  ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                  ,108
                  );
            END IF;
          END IF;
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;
   -- fin nuevo

  -- ***************************************************************************
  -- ***************************************************************************
  ELSIF P_IPD_TIPO_EMISOR = 'E'
      AND P_IPD_PAGO = 'N'
        AND P_IPD_TRASLADO_FONDOS = 'S'
          AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    IF DIVIDENDOS_X_ISIN%FOUND THEN


      OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
      FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      IF INSTRUCCION_E%FOUND THEN
        IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
          INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,'FON'                                         -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'NTS'                                         -- TIPM_ESTADO
                ,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2              -- TIPM_RETEFUENTE
                ,V_CAE_M                                        -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                          -- TIPM_FUENTE
                ,109
                );
        ELSE
          IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
            IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'FON'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'AOK'                                         -- TIPM_ESTADO
                    ,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,110
                    );
            ELSE
              INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                    (TIPM_CONSECUTIVO
                    ,TIPM_ORIGEN_CLIENTE
                    ,TIPM_FECHA
                    ,TIPM_NUM_IDEN
                    ,TIPM_TID_CODIGO
                    ,TIPM_NUMERO_CUENTA
                    ,TIPM_IPD_CONSECUTIVO
                    ,TIPM_NUM_IDEN_COMER
                    ,TIPM_TID_CODIGO_COMER
                    ,TIPM_USUARIO_COMER
                    ,TIPM_MONTO_ODP
                    ,TIPM_MONTO_GMF
                    ,TIPM_PROCESADO
                    ,TIPM_TPA_MNEMONICO
                    ,TIPM_MONTO_ABD
                    ,TIPM_MONTO_SERVICIO
                    ,TIPM_MONTO_ABD_NETO
                    ,TIPM_ESTADO
                    ,TIPM_DESCRIPCION
                    ,TIPM_ISIN
                    ,TIPM_EMISOR
                    ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                    ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                    ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                    ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                    ,TIPM_GRAVAMEN
                    ,TIPM_FUENTE
                    ,TIPM_ORDEN
                    )VALUES
                    (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                    ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                    ,SYSDATE                                       -- TIPM_FECHA
                    ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                    ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                    ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                    ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                    ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                    ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                    ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                    ,0                                             -- TIPM_MONTO_ODP
                    ,0                                             -- TIPM_MONTO_GMF
                    ,'N'                                           -- TIPM_PROCESADO
                    ,'FON'                                         -- TIPM_TPA_MNEMONICO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                    ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                    ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                    ,'INV'                                         -- TIPM_ESTADO
                    ,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
                    ,P_ISIN                    -- TIPM_ISIN
                    ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                    ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                    ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                    ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                    ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                    ,V_CAE_M                                       -- TIPM_GRAVAMEN
                    ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                    ,111
                    );
            END IF;
          ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
            INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                (TIPM_CONSECUTIVO
                ,TIPM_ORIGEN_CLIENTE
                ,TIPM_FECHA
                ,TIPM_NUM_IDEN
                ,TIPM_TID_CODIGO
                ,TIPM_NUMERO_CUENTA
                ,TIPM_IPD_CONSECUTIVO
                ,TIPM_NUM_IDEN_COMER
                ,TIPM_TID_CODIGO_COMER
                ,TIPM_USUARIO_COMER
                ,TIPM_MONTO_ODP
                ,TIPM_MONTO_GMF
                ,TIPM_PROCESADO
                ,TIPM_TPA_MNEMONICO
                ,TIPM_MONTO_ABD
                ,TIPM_MONTO_SERVICIO
                ,TIPM_MONTO_ABD_NETO
                ,TIPM_ESTADO
                ,TIPM_DESCRIPCION
                ,TIPM_ISIN
                ,TIPM_EMISOR
                ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
                ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
                ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
                ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
                ,TIPM_GRAVAMEN
                ,TIPM_FUENTE
                ,TIPM_ORDEN
                )VALUES
                (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
                ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
                ,SYSDATE                                       -- TIPM_FECHA
                ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
                ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
                ,REC_INSTRUCCION_E.IPD_CONSECUTIVO             -- TIPM_IPD_CONSECUTIVO
                ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
                ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
                ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
                ,0                                             -- TIPM_MONTO_ODP
                ,0                                             -- TIPM_MONTO_GMF
                ,'N'                                           -- TIPM_PROCESADO
                ,'FON'                                         -- TIPM_TPA_MNEMONICO
                ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
                ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
                ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
                ,'SAN'                                         -- TIPM_ESTADO
                ,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
                ,P_ISIN                    -- TIPM_ISIN
                ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
                ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
                ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
                ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
                ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
                ,V_CAE_M                                       -- TIPM_GRAVAMEN
                ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
                ,112
                );
          END IF;
        END IF;
      ELSE
        INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_EMISOR
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,REC_DIVIDENDOS_X_ISIN.MONTO                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,REC_DIVIDENDOS_X_ISIN.MONTO+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,P_ISIN                    -- TIPM_ISIN
            ,REC_DIVIDENDOS_X_ISIN.EMISOR                  -- TIPM_EMISOR
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
            ,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,113
            );
      END IF;
      CLOSE INSTRUCCION_E;
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
    END IF;
    CLOSE DIVIDENDOS_X_ISIN;

  -- ***************************************************************************
  -- ***************************************************************************
  ELSE
    OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);
    FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
          IF DIVIDENDOS_X_ISIN%FOUND THEN

    --CLOSE DIVIDENDOS_X_ISIN;

    V_MONTO_ORDEN1  := NVL(REC_DIVIDENDOS_X_ISIN.MONTO, 0) + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M; -- SORTIZ VAGTUD698-2
    V_MONTO_GMF     := 0;
    INSERT /*+ APPEND_VALUES */ INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
            (TIPM_CONSECUTIVO
            ,TIPM_ORIGEN_CLIENTE
            ,TIPM_FECHA
            ,TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_PROCESADO
            ,TIPM_TPA_MNEMONICO
            ,TIPM_MONTO_ABD
            ,TIPM_MONTO_SERVICIO
            ,TIPM_MONTO_ABD_NETO
            ,TIPM_ESTADO
            ,TIPM_DESCRIPCION
            ,TIPM_ISIN
            ,TIPM_IMPUESTO_ICA  -- SORTIZ VAGTUD698-1
            ,TIPM_IMPUESTO_CREE -- SORTIZ VAGTUD698-1
            ,TIPM_OTROS_IMPUESTOS -- SORTIZ VAGTUD698-1
            ,TIPM_RETEFUENTE  -- SORTIZ VAGTUD698-2
            ,TIPM_GRAVAMEN
            ,TIPM_FUENTE
            ,TIPM_ORDEN
            )VALUES
            (TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
            ,DECODE(P_PER_SUC_CODIGO,11,'DAV','COR')    -- TIPM_ORIGEN_CLIENTE
            ,SYSDATE                                       -- TIPM_FECHA
            ,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
            ,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
            ,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
            ,NULL                                          -- TIPM_IPD_CONSECUTIVO
            ,P_CCC_PER_NUM_IDEN                         -- TIPM_NUM_IDEN_COMER
            ,P_CCC_PER_TID_CODIGO                       -- TIPM_TID_CODIGO_COMER
            ,P_PER_NOMBRE_USUARIO                       -- TIPM_USUARIO_COMER
            ,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
            ,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
            ,'N'                                           -- TIPM_PROCESADO
            ,NULL                                          -- TIPM_TPA_MNEMONICO
            ,NVL(REC_DIVIDENDOS_X_ISIN.MONTO, 0)                   -- TIPM_MONTO_ABD
            ,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
            ,NVL(REC_DIVIDENDOS_X_ISIN.MONTO, 0)+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
            ,'AOK'                                         -- TIPM_ESTADO
            ,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
            ,NVL(P_ISIN,REC_DIVIDENDOS_X_ISIN.ISIN)                    -- TIPM_ISIN
            ,V_MONTO_ICA  -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_ICA
            ,V_MONTO_CREE -- SORTIZ VAGTUD698-1            -- TIPM_IMPUESTO_CREE
            ,V_MONTO_ADI  -- SORTIZ VAGTUD698-1            -- TIPM_OTROS_IMPUESTOS
            ,V_RETEFTE -- SORTIZ VAGTUD698-2               -- TIPM_RETEFUENTE
            ,V_CAE_M                                       -- TIPM_GRAVAMEN
            ,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))                                         -- TIPM_FUENTE
            ,114
            );

            END IF;
            CLOSE DIVIDENDOS_X_ISIN;
  END IF;

  /*UPDATE MOVIMIENTOS_CUENTA_CORREDORES
     SET MCC_PAGADO = 'N'
   WHERE MCC_CONSECUTIVO = P_SEC;   */
   IF P_FAV_CONSECUTIVO IS NULL THEN
    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
     SET MCC_PAGADO = 'N'
    WHERE MCC_CONSECUTIVO = P_SEC;
   ELSIF P_FAV_CONSECUTIVO IS NOT NULL THEN
    UPDATE MOVIMIENTOS_CUENTA_CORREDORES
     SET MCC_PAGADO = 'N'
    WHERE MCC_FAV_CONSECUTIVO = P_FAV_CONSECUTIVO
    AND NVL(MCC_PAGADO,'N') = 'N';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);

      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS'
                                          ,P_ERROR       => P_CLI_PER_NUM_IDEN||';'||P_CLI_PER_TID_CODIGO||';'||P_NUMERO_CUENTA||';'||'OTROSERRORES'||sqlerrm
                                          ,P_TABLA_ERROR => NULL);
END PROCESO_PAGOS_MASIVOS_DIV_M;
--

PROCEDURE PROCESO_PAGOS_MASIVOS_DIV  IS

	P_CLI_PER_NUM_IDEN          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
	P_CLI_PER_TID_CODIGO        CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
	P_NUMERO_CUENTA             CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;

	TYPE O_CURSOR IS REF CURSOR;
	TDD TMP_PAGOS_DEPOSITOS_DCVAL%ROWTYPE;
	V_RID VARCHAR2(512);

	C_CURSOR O_CURSOR;
	V_SELECT VARCHAR2(4000);


	ERRORSQL         VARCHAR2(100);
	V_COMM           NUMBER := 0;
	V_TIPO_PAGO      VARCHAR2(5);
	V_MONTO_ABD      NUMBER := 0;
	V_MONTO_SERVICIO NUMBER := 0;
	V_MONTO_STR      NUMBER := 0;
	TOTAL_ODP        NUMBER := 0;
	V_MONTO_GMF      NUMBER := 0;
	V_MONTO_ORDEN1   NUMBER := 0;
	V_EXCENTO1       VARCHAR2(1) := NULL;
	V_IBA1           CONSTANTES.CON_VALOR%TYPE:= NULL;
	V_MONTO_MAX_ACH  NUMBER;
	V_MONTO_MAX_POD  NUMBER;
	P_ISIN           VARCHAR2(50);

	V_MONTO_ICA   NUMBER;
	V_MONTO_CREE  NUMBER;
	V_MONTO_ADI   NUMBER;

	CCC1_CCC_SALDO_ADMON_VALORES CUENTAS_CLIENTE_CORREDORES.CCC_SALDO_ADMON_VALORES%TYPE;

	V_RETEFTE         	NUMBER := 0;
	V_CAE_M           	NUMBER := 0;
	V_IPD_TPA_MNEMONICO VARCHAR2(3);

	P_IPD_TIPO_EMISOR 		TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TIPO_EMISOR%TYPE;
	P_IPD_PAGO 						TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_PAGO%TYPE;
	P_IPD_TRASLADO_FONDOS	TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TRASLADO_FONDOS%TYPE;
	P_IPD_INSTRUCCION_POD TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_INSTRUCCION_POD%TYPE;

		--VAGTUS046880
	  -- INSTRUCCIONES DE PAGO ACTIVAS DE ORIGEN DE PAGO "DIVIDENDOS" PARA ISIN ESPECIFICO
	CURSOR INSTRUCCION_E (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
		SELECT IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
		FROM INSTRUCCIONES_PAGOS_DIVIDENDOS, DETALLE_INSTRUCCIONES_PAGOS
		WHERE IPD_CONSECUTIVO = DIPA_IPD_CONSECUTIVO
		AND IPD_CCC_CLI_PER_NUM_IDEN = P_ID
		AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
		AND IPD_CCC_NUMERO_CUENTA = P_CTA
		AND IPD_TIPO_EMISOR = 'E'
		AND IPD_ESTADO = 'A'
		AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
		AND IPD_TIPO_ORIGEN_PAGO IN ('DI', 'SD')
		AND DIPA_FUG_ISI_MNEMONICO = P_ISIN;
  REC_INSTRUCCION_E INSTRUCCION_E%ROWTYPE;
  --VAGTUS046880
  V_CANT NUMBER := 0;
BEGIN

	V_SELECT := 'SELECT TDD_ISIN
							,TDD_FUNGIBLE
							,TDD_CUENTA_DCVAL
							,TDD_TIPO_DERECHO
							,TDD_FECHA
							,TDD_TID_CODIGO
							,TDD_NUM_IDEN
							,TDD_NOMBRE
							,TDD_CAPITAL
							,TDD_DIVIDENDOS
							,TDD_DIVIDENDOS_EN_ACCIONES
							,TDD_RENDIMIENTOS
							,TDD_ESTADO
							,TDD_MOTIVO
							,TDD_PROCESADO
							,TDD_CCC_CLI_PER_NUM_IDEN
							,TDD_CCC_CLI_PER_TID_CODIGO
							,TDD_CCC_NUMERO_CUENTA
							,-TDD_RETEFUENTE TDD_RETEFUENTE
							,TDD_ENAJENACION
							,TDD_ENA_MNEMONICO
							,TDD_ENA_YANKEE
							,TDD_FECHA_DIVIDENDO
							,TDD_VALOR_NOMINAL
							,TDD_FECHA_PAGO_DIVIDENDO
							,-TDD_OTROS_IMPUESTOS TDD_OTROS_IMPUESTOS
							,TDD_SALDO_COEASY
							,TDD_SOLUCION_INCONSISTENCIA
							,TDD_REMANENTES
							,-TDD_IMPUESTO_ICA TDD_IMPUESTO_ICA
							,-TDD_IMPUESTO_CREE TDD_IMPUESTO_CREE
							,-TDD_GRAVAMEN TDD_GRAVAMEN
							,TDD_RDI_TIPO
							,TDD_DSP_TOTAL
							,TDD_FUENTE
							,TDD_TDD
							,TDD_CRUCE
							,TDD_ACTUALIZADO
							,TDD_PROCESAR
							,TDD_CAMBIO_ISIN
							,TDD_CAMBIO_FECHA
							,TDD_CLI_EXCENTO_DXM
							,TDD_IPD_TIPO_EMISOR
							,TDD_IPD_CONSECUTIVO
							,TDD_IPD_TPA_MNEMONICO
							,TDD_IPD_BAN_CODIGO
							,TDD_IPD_VISADO
							,TDD_IPD_PAGO
							,TDD_IPD_TRASLADO_FONDOS
							,TDD_IPD_INSTRUCCION_POD
							,TDD_IPD_PAGAR_A
							,TDD_IPD_CRUCE_CHEQUE
							,TDD_MONTO_MAX_POD
							,TDD_MONTO_MAX_ACH
							,TDD_IBA
							,TDD_CCC_PER_NUM_IDEN
							,TDD_CCC_PER_TID_CODIGO
							,TDD_PDC_CONSECUTIVO
							,-TDD_TOTAL_SERVICIO TDD_TOTAL_SERVICIO
							,-TDD_VALOR_IVA TDD_VALOR_IVA
							,TDD_NOMBRE_COMERCIAL
							,ROWID RID
							FROM TMP_PAGOS_DEPOSITOS_DCVAL
              WHERE TDD_PROCESAR = ''S''
              AND TDD_ACTUALIZADO = ''S''
              AND TDD_CRUCE = ''S''
              AND TDD_ESTADO = ''OK''
              AND TDD_DIVIDENDOS != 0
              AND TDD_ENA_YANKEE = ''N''
              AND TDD_TIPO_DERECHO = 2';

	C_CURSOR  := NULL;
	TDD       := NULL;

	OPEN C_CURSOR FOR V_SELECT;
	LOOP
		TDD  := NULL;
		FETCH C_CURSOR INTO  TDD.TDD_ISIN
		,TDD.TDD_FUNGIBLE
		,TDD.TDD_CUENTA_DCVAL
		,TDD.TDD_TIPO_DERECHO
		,TDD.TDD_FECHA
		,TDD.TDD_TID_CODIGO
		,TDD.TDD_NUM_IDEN
		,TDD.TDD_NOMBRE
		,TDD.TDD_CAPITAL
		,TDD.TDD_DIVIDENDOS
		,TDD.TDD_DIVIDENDOS_EN_ACCIONES
		,TDD.TDD_RENDIMIENTOS
		,TDD.TDD_ESTADO
		,TDD.TDD_MOTIVO
		,TDD.TDD_PROCESADO
		,TDD.TDD_CCC_CLI_PER_NUM_IDEN
		,TDD.TDD_CCC_CLI_PER_TID_CODIGO
		,TDD.TDD_CCC_NUMERO_CUENTA
		,TDD.TDD_RETEFUENTE
		,TDD.TDD_ENAJENACION
		,TDD.TDD_ENA_MNEMONICO
		,TDD.TDD_ENA_YANKEE
		,TDD.TDD_FECHA_DIVIDENDO
		,TDD.TDD_VALOR_NOMINAL
		,TDD.TDD_FECHA_PAGO_DIVIDENDO
		,TDD.TDD_OTROS_IMPUESTOS
		,TDD.TDD_SALDO_COEASY
		,TDD.TDD_SOLUCION_INCONSISTENCIA
		,TDD.TDD_REMANENTES
		,TDD.TDD_IMPUESTO_ICA
		,TDD.TDD_IMPUESTO_CREE
		,TDD.TDD_GRAVAMEN
		,TDD.TDD_RDI_TIPO
		,TDD.TDD_DSP_TOTAL
		,TDD.TDD_FUENTE
		,TDD.TDD_TDD
		,TDD.TDD_CRUCE
		,TDD.TDD_ACTUALIZADO
		,TDD.TDD_PROCESAR
		,TDD.TDD_CAMBIO_ISIN
		,TDD.TDD_CAMBIO_FECHA
		,TDD.TDD_CLI_EXCENTO_DXM
		,TDD.TDD_IPD_TIPO_EMISOR
		,TDD.TDD_IPD_CONSECUTIVO
		,TDD.TDD_IPD_TPA_MNEMONICO
		,TDD.TDD_IPD_BAN_CODIGO
		,TDD.TDD_IPD_VISADO
		,TDD.TDD_IPD_PAGO
		,TDD.TDD_IPD_TRASLADO_FONDOS
		,TDD.TDD_IPD_INSTRUCCION_POD
		,TDD.TDD_IPD_PAGAR_A
		,TDD.TDD_IPD_CRUCE_CHEQUE
		,TDD.TDD_MONTO_MAX_POD
		,TDD.TDD_MONTO_MAX_ACH
		,TDD.TDD_IBA
		,TDD.TDD_CCC_PER_NUM_IDEN
		,TDD.TDD_CCC_PER_TID_CODIGO
		,TDD.TDD_PDC_CONSECUTIVO
		,TDD.TDD_TOTAL_SERVICIO
		,TDD.TDD_VALOR_IVA
		,TDD.TDD_NOMBRE_COMERCIAL
		,V_RID;
		EXIT WHEN C_CURSOR%NOTFOUND;
    V_CANT := V_CANT + 1;

		V_COMM := 0;
		V_IBA1           := NULL;
		V_MONTO_MAX_ACH  := NULL;
		V_MONTO_MAX_POD  := NULL;

		V_IBA1           := TDD.TDD_IBA;
		V_MONTO_MAX_ACH  := TDD.TDD_MONTO_MAX_ACH;
		V_MONTO_MAX_POD  := TDD.TDD_MONTO_MAX_POD;


		V_COMM := V_COMM + 1;

		P_CLI_PER_NUM_IDEN   := NULL;
		P_CLI_PER_TID_CODIGO := NULL;
		P_NUMERO_CUENTA      := NULL;
		P_ISIN               := NULL;

		P_CLI_PER_NUM_IDEN   := TDD.TDD_CCC_CLI_PER_NUM_IDEN;
		P_CLI_PER_TID_CODIGO := TDD.TDD_CCC_CLI_PER_TID_CODIGO;
		P_NUMERO_CUENTA      := TDD.TDD_CCC_NUMERO_CUENTA;
		P_ISIN               := TDD.TDD_ISIN;

		V_EXCENTO1 := NVL(TDD.TDD_CLI_EXCENTO_DXM,'N');

		V_IPD_TPA_MNEMONICO := NULL;

		V_IPD_TPA_MNEMONICO := TDD.TDD_IPD_TPA_MNEMONICO;

		-- SE CALCULA EL SALDO DE ADMON VALORES QUE TIENE EL CLIENTE
		CCC1_CCC_SALDO_ADMON_VALORES := P_PAGOS_DIVIDENDOS.FN_SALDO_ADMON_VALORES (P_CLI_NUM_IDEN      => P_CLI_PER_NUM_IDEN
                                                                              ,P_CLI_TID_CODIGO    => P_CLI_PER_TID_CODIGO
                                                                              ,P_CUENTA            => P_NUMERO_CUENTA
                                                                              ,P_SALDO_RECALCULADO => 'N'
                                                                              ,P_SALDO_ODP         => TOTAL_ODP);

		P_IPD_TIPO_EMISOR 		:= NULL;
		P_IPD_PAGO						:= NULL;
		P_IPD_TRASLADO_FONDOS	:= NULL;
		P_IPD_INSTRUCCION_POD	:= NULL;

		P_IPD_TIPO_EMISOR 		:= TDD.TDD_IPD_TIPO_EMISOR;
		P_IPD_PAGO						:= TDD.TDD_IPD_PAGO;
		P_IPD_TRASLADO_FONDOS	:= TDD.TDD_IPD_TRASLADO_FONDOS;
		P_IPD_INSTRUCCION_POD	:= TDD.TDD_IPD_INSTRUCCION_POD;


		IF P_IPD_TIPO_EMISOR = 'T'
		AND P_IPD_PAGO = 'S'
		AND P_IPD_TRASLADO_FONDOS = 'N'
		AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN


			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
				V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
				V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
				V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
				V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
				V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
				V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
--

			IF (TDD.TDD_IPD_PAGAR_A = 'C'
			AND V_IPD_TPA_MNEMONICO IN ('CHE','CHG')
			AND TDD.TDD_IPD_CRUCE_CHEQUE IN ('CA'))
			OR (TDD.TDD_IPD_PAGAR_A = 'C'
			AND V_IPD_TPA_MNEMONICO = 'TRB')
			OR (TDD.TDD_IPD_PAGAR_A = 'C'
			AND V_IPD_TPA_MNEMONICO = 'ACH')
			OR (NVL(V_EXCENTO1,'N')) = 'S' THEN

				V_MONTO_ORDEN1  := TDD.TDD_DIVIDENDOS + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M;
				V_MONTO_GMF   := 0;
			ELSE

				V_MONTO_ORDEN1 := ROUND((TDD.TDD_DIVIDENDOS + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) / (1 + V_IBA1),2);
				V_MONTO_GMF    := ROUND(V_MONTO_ORDEN1 * V_IBA1,2);
			END IF;

			IF P_ISIN = 'COB51PA00076'
			AND TDD.TDD_IPD_BAN_CODIGO = 51
			AND V_IPD_TPA_MNEMONICO = 'TRB' THEN
				V_IPD_TPA_MNEMONICO := 'STR';
			ELSIF P_ISIN = 'COC04PA00016'
			AND TDD.TDD_IPD_BAN_CODIGO = 51
			AND V_IPD_TPA_MNEMONICO = 'TRB' THEN
				V_IPD_TPA_MNEMONICO := 'TBP';
			END IF;

			IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
				IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR')
					,SYSDATE
					,P_CLI_PER_NUM_IDEN
					,P_CLI_PER_TID_CODIGO
					,P_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN
					,TDD.TDD_CCC_PER_TID_CODIGO
					,TDD.TDD_NOMBRE_COMERCIAL
					,0
					,0
					,'N'
					,V_IPD_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS
					,V_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'NTS'
					,'NO TIENE SALDO'
					,P_ISIN
					,TDD.TDD_ENA_MNEMONICO
					,V_MONTO_ICA
					,V_MONTO_CREE
					,V_MONTO_ADI
					,V_RETEFTE                                     -- TIPM_RETEFUENTE
					,V_CAE_M																			 -- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))
          ,1
					);
				ELSE
					IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_TIPO_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR')
						,SYSDATE
						,P_CLI_PER_NUM_IDEN
						,P_CLI_PER_TID_CODIGO
						,P_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN
						,TDD.TDD_CCC_PER_TID_CODIGO
						,TDD.TDD_NOMBRE_COMERCIAL
						,V_MONTO_ORDEN1
						,V_MONTO_GMF
						,'N'
						,V_IPD_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS
						,V_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'AOK'
						,'ALISTAMIENTO OK'
						,P_ISIN
						,TDD.TDD_ENA_MNEMONICO
						,P_IPD_TIPO_EMISOR
						,V_MONTO_ICA
						,V_MONTO_CREE
						,V_MONTO_ADI
						,V_RETEFTE                                     -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))
            ,2
						);
					ELSE
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR')
						,SYSDATE
						,P_CLI_PER_NUM_IDEN
						,P_CLI_PER_TID_CODIGO
						,P_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN
						,TDD.TDD_CCC_PER_TID_CODIGO
						,TDD.TDD_NOMBRE_COMERCIAL
						,0
						,0
						,'N'
						,V_IPD_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS
						,V_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'SAN'
						,'SALDO ADMON VALORES NEGATIVO'
						,P_ISIN
						,TDD.TDD_ENA_MNEMONICO
						,V_MONTO_ICA
						,V_MONTO_CREE
						,V_MONTO_ADI
						,V_RETEFTE                                     -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))
            ,3
						);
					END IF;
				END IF;
			ELSE
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                             -- TIPM_MONTO_ODP
				,0                                             -- TIPM_MONTO_GMF
				,'N'                                           -- TIPM_PROCESADO
				,V_IPD_TPA_MNEMONICO                           -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'INV'                                         -- TIPM_ESTADO
				,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
				,P_ISIN                                        -- TIPM_ISIN
				,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE                                     -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,4
				);
			END IF;

		-- ***************************************************************************
		-- ***************************************************************************
		ELSIF P_IPD_TIPO_EMISOR = 'T'
		AND P_IPD_PAGO = 'N'
		AND P_IPD_TRASLADO_FONDOS = 'S'
		AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN

			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
				V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
				V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
				V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
				V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
				V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
				V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
			--

			IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                             -- TIPM_MONTO_ODP
				,0                                             -- TIPM_MONTO_GMF
				,'N'                                           -- TIPM_PROCESADO
				,'FON'                                         -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'NTS'                                         -- TIPM_ESTADO
				,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
				,P_ISIN                                        -- TIPM_ISIN
				,NULL                                          -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE                                     -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,5
				);
			ELSE
				IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
					IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                       -- TIPM_USUARIO_COMER
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'FON'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'AOK'                                         -- TIPM_ESTADO
						,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
						,P_ISIN                                        -- TIPM_ISIN
						,NULL                                          -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                                     -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,6
						);
					ELSE
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,0                                             -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'FON'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'INV'                                         -- TIPM_ESTADO
						,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
						,P_ISIN                                        -- TIPM_ISIN
						,NULL                                          -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                                     -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,7
						);
					END IF;
				ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
					,SYSDATE                                       -- TIPM_FECHA
					,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
					,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
					,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
					,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
					,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
					,0                                             -- TIPM_MONTO_ODP
					,0                                             -- TIPM_MONTO_GMF
					,'N'                                           -- TIPM_PROCESADO
					,'FON'                                         -- TIPM_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
					,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'SAN'                                         -- TIPM_ESTADO
					,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
					,P_ISIN                                        -- TIPM_ISIN
					,NULL                                          -- TIPM_EMISOR
					,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
					,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
					,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
					,V_RETEFTE                                     -- TIPM_RETEFUENTE
					,V_CAE_M																			 -- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
          ,8
					);
				END IF;
			END IF;
		-- ***************************************************************************
		-- ***************************************************************************
		ELSIF P_IPD_TIPO_EMISOR = 'E'
		AND P_IPD_PAGO = 'S'
		AND P_IPD_TRASLADO_FONDOS = 'N'
		AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN
			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
				V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
				V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
				V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
				V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
				V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
				V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
			--

			IF (TDD.TDD_IPD_PAGAR_A = 'C' AND
			V_IPD_TPA_MNEMONICO IN ('CHE','CHG') AND
			TDD.TDD_IPD_CRUCE_CHEQUE IN ('CA')) OR
			(TDD.TDD_IPD_PAGAR_A = 'C' AND
			V_IPD_TPA_MNEMONICO = 'TRB') OR
			(TDD.TDD_IPD_PAGAR_A = 'C' AND
			V_IPD_TPA_MNEMONICO = 'ACH') OR
			(NVL(V_EXCENTO1,'N')) = 'S' THEN

				V_MONTO_ORDEN1  := TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M;
				V_MONTO_GMF   := 0;
			ELSE

				V_MONTO_ORDEN1  := ROUND((TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) / (1 + V_IBA1),2);
				V_MONTO_GMF   := ROUND(V_MONTO_ORDEN1 * V_IBA1,2);
			END IF;


			IF V_IPD_TPA_MNEMONICO = 'TRB'
			AND TDD.TDD_IPD_BAN_CODIGO =  51
			AND P_ISIN IN ('COB51PA00076','COC04PA00016') THEN

				IF P_ISIN = 'COB51PA00076' THEN
					V_IPD_TPA_MNEMONICO := 'STR';
				ELSIF P_ISIN = 'COC04PA00016' THEN
					V_IPD_TPA_MNEMONICO := 'TBP';
				END IF;

			END IF;

		OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, P_ISIN);--VAGTUS046880
		FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;--VAGTUS046880
		 IF INSTRUCCION_E%FOUND THEN--VAGTUS046880
			IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                             -- TIPM_MONTO_ODP
				,0                                             -- TIPM_MONTO_GMF
				,'N'                                           -- TIPM_PROCESADO
				,V_IPD_TPA_MNEMONICO                           -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'NTS'                                         -- TIPM_ESTADO
				,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
				,P_ISIN                                        -- TIPM_ISIN
				,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE                										 -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,9
				);
			ELSE
				IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
					IF V_IPD_TPA_MNEMONICO = 'ACH' AND (TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) > V_MONTO_MAX_ACH  THEN
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO             					 -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,0                                             -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,V_IPD_TPA_MNEMONICO                           -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'MAS'                                         -- TIPM_ESTADO
						,'MONTO ACH SUPERA EL M??XIMO PERMITIDO'       -- TIPM_DESCRIPCION
						,P_ISIN                    										 -- TIPM_ISIN
						,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                                     -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,10
						);
					ELSE
						IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
							INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
							(TIPM_CONSECUTIVO
							,TIPM_ORIGEN_CLIENTE
							,TIPM_FECHA
							,TIPM_NUM_IDEN
							,TIPM_TID_CODIGO
							,TIPM_NUMERO_CUENTA
							,TIPM_IPD_CONSECUTIVO
							,TIPM_NUM_IDEN_COMER
							,TIPM_TID_CODIGO_COMER
							,TIPM_USUARIO_COMER
							,TIPM_MONTO_ODP
							,TIPM_MONTO_GMF
							,TIPM_PROCESADO
							,TIPM_TPA_MNEMONICO
							,TIPM_MONTO_ABD
							,TIPM_MONTO_SERVICIO
							,TIPM_MONTO_ABD_NETO
							,TIPM_ESTADO
							,TIPM_DESCRIPCION
							,TIPM_ISIN
							,TIPM_EMISOR
							,TIPM_TIPO_EMISOR
							,TIPM_IMPUESTO_ICA
							,TIPM_IMPUESTO_CREE
							,TIPM_OTROS_IMPUESTOS
							,TIPM_RETEFUENTE
							,TIPM_GRAVAMEN
							,TIPM_FUENTE
              ,TIPM_ORDEN
							)VALUES
							(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
							,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
							,SYSDATE                                       -- TIPM_FECHA
							,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
							,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
							,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
							,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
							,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
							,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
							,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
							,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
							,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
							,'N'                                           -- TIPM_PROCESADO
							,V_IPD_TPA_MNEMONICO                           -- TIPM_TPA_MNEMONICO
							,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
							,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
							,'AOK'                                         -- TIPM_ESTADO
							,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
							,P_ISIN                                        -- TIPM_ISIN
							,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
							,P_IPD_TIPO_EMISOR                             -- TIPM_TIPO_EMISOR
							,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
							,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
							,V_MONTO_ADI  			   												 -- TIPM_OTROS_IMPUESTOS
							,V_RETEFTE                										 -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
							,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
              ,11
							);
						ELSE
							INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
							(TIPM_CONSECUTIVO
							,TIPM_ORIGEN_CLIENTE
							,TIPM_FECHA
							,TIPM_NUM_IDEN
							,TIPM_TID_CODIGO
							,TIPM_NUMERO_CUENTA
							,TIPM_IPD_CONSECUTIVO
							,TIPM_NUM_IDEN_COMER
							,TIPM_TID_CODIGO_COMER
							,TIPM_USUARIO_COMER
							,TIPM_MONTO_ODP
							,TIPM_MONTO_GMF
							,TIPM_PROCESADO
							,TIPM_TPA_MNEMONICO
							,TIPM_MONTO_ABD
							,TIPM_MONTO_SERVICIO
							,TIPM_MONTO_ABD_NETO
							,TIPM_ESTADO
							,TIPM_DESCRIPCION
							,TIPM_ISIN
							,TIPM_EMISOR
							,TIPM_IMPUESTO_ICA
							,TIPM_IMPUESTO_CREE
							,TIPM_OTROS_IMPUESTOS
							,TIPM_RETEFUENTE
							,TIPM_GRAVAMEN
							,TIPM_FUENTE
              ,TIPM_ORDEN
							)VALUES
							(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
							,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
							,SYSDATE                                       -- TIPM_FECHA
							,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
							,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
							,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
							,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
							,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
							,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
							,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
							,0                                             -- TIPM_MONTO_ODP
							,0                                             -- TIPM_MONTO_GMF
							,'N'                                           -- TIPM_PROCESADO
							,V_IPD_TPA_MNEMONICO                           -- TIPM_TPA_MNEMONICO
							,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
							,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
							,'INV'                                         -- TIPM_ESTADO
							,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
							,P_ISIN                                        -- TIPM_ISIN
							,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
							,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
							,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
							,V_MONTO_ADI  	                               -- TIPM_OTROS_IMPUESTOS
							,V_RETEFTE                                     -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
							,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
              ,12
							);
						END IF;
					END IF;
				ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
					,SYSDATE                                       -- TIPM_FECHA
					,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
					,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
					,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
					,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
					,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
					,0                                             -- TIPM_MONTO_ODP
					,0                                             -- TIPM_MONTO_GMF
					,'N'                                           -- TIPM_PROCESADO
					,V_IPD_TPA_MNEMONICO                  				 -- TIPM_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
					,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'SAN'                                         -- TIPM_ESTADO
					,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
					,P_ISIN                                        -- TIPM_ISIN
					,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
					,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
					,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
					,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
					,V_RETEFTE                                     -- TIPM_RETEFUENTE
					,V_CAE_M																			 -- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
          ,13
					);
				END IF;
			END IF;
		END IF;  --VAGTUS046880
		CLOSE INSTRUCCION_E; --VAGTUS046880

		-- ***************************************************************************
		-- ***************************************************************************
		ELSIF P_IPD_TIPO_EMISOR = 'E'
		AND P_IPD_PAGO = 'N'
		AND P_IPD_TRASLADO_FONDOS = 'N'
		AND P_IPD_INSTRUCCION_POD = 'S' THEN
			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
				V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
				V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
				V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
				V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
				V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
				V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
			--

			IF P_ISIN IN ('COB51PA00076','COC04PA00016','COE15PA00026') THEN
				V_IPD_TPA_MNEMONICO := 'POD';
			ELSE
				V_IPD_TPA_MNEMONICO := NULL;
			END IF;

			IF V_IPD_TPA_MNEMONICO = 'POD' THEN
				IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
					,SYSDATE                                       -- TIPM_FECHA
					,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
					,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
					,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
					,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
					,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
					,0                                             -- TIPM_MONTO_ODP
					,0                                             -- TIPM_MONTO_GMF
					,'N'                                           -- TIPM_PROCESADO
					,'POD'                                         -- TIPM_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
					,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'NTS'                                         -- TIPM_ESTADO
					,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
					,P_ISIN                    						  			 -- TIPM_ISIN
					,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
					,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
					,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
					,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
					,V_RETEFTE                                     -- TIPM_RETEFUENTE
					,V_CAE_M																			 -- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
          ,14
					);
				ELSE
					IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
						IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
							IF (TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
								INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
								(TIPM_CONSECUTIVO
								,TIPM_ORIGEN_CLIENTE
								,TIPM_FECHA
								,TIPM_NUM_IDEN
								,TIPM_TID_CODIGO
								,TIPM_NUMERO_CUENTA
								,TIPM_IPD_CONSECUTIVO
								,TIPM_NUM_IDEN_COMER
								,TIPM_TID_CODIGO_COMER
								,TIPM_USUARIO_COMER
								,TIPM_MONTO_ODP
								,TIPM_MONTO_GMF
								,TIPM_PROCESADO
								,TIPM_TPA_MNEMONICO
								,TIPM_MONTO_ABD
								,TIPM_MONTO_SERVICIO
								,TIPM_MONTO_ABD_NETO
								,TIPM_ESTADO
								,TIPM_DESCRIPCION
								,TIPM_ISIN
								,TIPM_EMISOR
								,TIPM_TIPO_EMISOR
								,TIPM_IMPUESTO_ICA
								,TIPM_IMPUESTO_CREE
								,TIPM_OTROS_IMPUESTOS
								,TIPM_RETEFUENTE
								,TIPM_GRAVAMEN
								,TIPM_FUENTE
                ,TIPM_ORDEN
								)VALUES
								(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
								,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
								,SYSDATE                                       -- TIPM_FECHA
								,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
								,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
								,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
								,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
								,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
								,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
								,TDD.TDD_NOMBRE_COMERCIAL                       -- TIPM_USUARIO_COMER
								,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
								,0                                             -- TIPM_MONTO_GMF
								,'N'                                           -- TIPM_PROCESADO
								,'POD'                                         -- TIPM_TPA_MNEMONICO
								,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
								,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
								,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
								,'AOK'                                         -- TIPM_ESTADO
								,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
								,P_ISIN                                 			 -- TIPM_ISIN
								,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
								,P_IPD_TIPO_EMISOR                      			 -- TIPM_TIPO_EMISOR
								,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
								,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
								,V_MONTO_ADI  			                           -- TIPM_OTROS_IMPUESTOS
								,V_RETEFTE                                     -- TIPM_RETEFUENTE
								,V_CAE_M																			 -- TIPM_GRAVAMEN
								,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
                ,15
								);
							ELSE
								INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
								(TIPM_CONSECUTIVO
								,TIPM_ORIGEN_CLIENTE
								,TIPM_FECHA
								,TIPM_NUM_IDEN
								,TIPM_TID_CODIGO
								,TIPM_NUMERO_CUENTA
								,TIPM_IPD_CONSECUTIVO
								,TIPM_NUM_IDEN_COMER
								,TIPM_TID_CODIGO_COMER
								,TIPM_USUARIO_COMER
								,TIPM_MONTO_ODP
								,TIPM_MONTO_GMF
								,TIPM_PROCESADO
								,TIPM_TPA_MNEMONICO
								,TIPM_MONTO_ABD
								,TIPM_MONTO_SERVICIO
								,TIPM_MONTO_ABD_NETO
								,TIPM_ESTADO
								,TIPM_DESCRIPCION
								,TIPM_ISIN
								,TIPM_EMISOR
								,TIPM_IMPUESTO_ICA
								,TIPM_IMPUESTO_CREE
								,TIPM_OTROS_IMPUESTOS
								,TIPM_RETEFUENTE
								,TIPM_GRAVAMEN
								,TIPM_FUENTE
                ,TIPM_ORDEN
								)VALUES
								(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
								,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
								,SYSDATE                                       -- TIPM_FECHA
								,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
								,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
								,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
								,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
								,TDD.TDD_CCC_PER_NUM_IDEN											 -- TIPM_NUM_IDEN_COMER
								,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
								,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
								,0                                             -- TIPM_MONTO_ODP
								,0                                             -- TIPM_MONTO_GMF
								,'N'                                           -- TIPM_PROCESADO
								,'POD'                                         -- TIPM_TPA_MNEMONICO
								,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
								,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
								,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
								,'MPS'                                         -- TIPM_ESTADO
								,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
								,P_ISIN                                        -- TIPM_ISIN
								,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
								,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
								,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
								,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
								,V_RETEFTE                                     -- TIPM_RETEFUENTE
								,V_CAE_M                                       -- TIPM_GRAVAMEN
								,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
                ,16
								);
							END IF;
						ELSE
							INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
							(TIPM_CONSECUTIVO
							,TIPM_ORIGEN_CLIENTE
							,TIPM_FECHA
							,TIPM_NUM_IDEN
							,TIPM_TID_CODIGO
							,TIPM_NUMERO_CUENTA
							,TIPM_IPD_CONSECUTIVO
							,TIPM_NUM_IDEN_COMER
							,TIPM_TID_CODIGO_COMER
							,TIPM_USUARIO_COMER
							,TIPM_MONTO_ODP
							,TIPM_MONTO_GMF
							,TIPM_PROCESADO
							,TIPM_TPA_MNEMONICO
							,TIPM_MONTO_ABD
							,TIPM_MONTO_SERVICIO
							,TIPM_MONTO_ABD_NETO
							,TIPM_ESTADO
							,TIPM_DESCRIPCION
							,TIPM_ISIN
							,TIPM_EMISOR
							,TIPM_IMPUESTO_ICA
							,TIPM_IMPUESTO_CREE
							,TIPM_OTROS_IMPUESTOS
							,TIPM_RETEFUENTE
							,TIPM_GRAVAMEN
							,TIPM_FUENTE
              ,TIPM_ORDEN
							)VALUES
							(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
							,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
							,SYSDATE                                       -- TIPM_FECHA
							,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
							,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
							,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
							,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
							,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
							,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
							,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
							,0                                             -- TIPM_MONTO_ODP
							,0                                             -- TIPM_MONTO_GMF
							,'N'                                           -- TIPM_PROCESADO
							,'POD'                                         -- TIPM_TPA_MNEMONICO
							,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
							,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
							,'INV'                                         -- TIPM_ESTADO
							,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
							,P_ISIN                                        -- TIPM_ISIN
							,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
							,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
							,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
							,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
							,V_RETEFTE                                     -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
							,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
              ,17
							);
						END IF;
					ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,0                                             -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'POD'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'SAN'                                         -- TIPM_ESTADO
						,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
						,P_ISIN                    										 -- TIPM_ISIN
						,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI  	          										 -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                										 -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,18
						);
					END IF;
				END IF;
			ELSE
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                             -- TIPM_MONTO_ODP
				,0                                             -- TIPM_MONTO_GMF
				,'N'                                           -- TIPM_PROCESADO
				,'POD'                                         -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'CIN'                                         -- TIPM_ESTADO
				,'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP' -- TIPM_DESCRIPCION
				,P_ISIN                    										 -- TIPM_ISIN
				,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE                                     -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,19
				);
			END IF;
-- ***************************************************************************
-- ***************************************************************************
-- ojo nuevo
		ELSIF P_IPD_TIPO_EMISOR = 'E'
		AND P_IPD_PAGO = 'S'
		AND P_IPD_TRASLADO_FONDOS = 'N'
		AND P_IPD_INSTRUCCION_POD = 'S' THEN
		V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
				V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
				V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
				V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
				V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
				V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
				V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);

			IF P_ISIN IN ('COB51PA00076','COC04PA00016','COE15PA00026') THEN
				V_IPD_TPA_MNEMONICO := 'POD';
			ELSE
				V_IPD_TPA_MNEMONICO := NULL;
			END IF;

			IF V_IPD_TPA_MNEMONICO = 'POD' THEN
				IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
					,SYSDATE                                       -- TIPM_FECHA
					,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
					,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
					,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
					,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
					,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
					,0                                             -- TIPM_MONTO_ODP
					,0                                             -- TIPM_MONTO_GMF
					,'N'                                           -- TIPM_PROCESADO
					,'POD'                                         -- TIPM_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
					,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'NTS'                                         -- TIPM_ESTADO
					,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
					,P_ISIN                    						  			-- TIPM_ISIN
					,TDD.TDD_ENA_MNEMONICO                  			-- TIPM_EMISOR
					,V_MONTO_ICA                                  -- TIPM_IMPUESTO_ICA
					,V_MONTO_CREE                                 -- TIPM_IMPUESTO_CREE
					,V_MONTO_ADI                                  -- TIPM_OTROS_IMPUESTOS
					,V_RETEFTE                                    -- TIPM_RETEFUENTE
					,V_CAE_M																			-- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV')) -- TIPM_FUENTE
          ,20
					);
				ELSE
					IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
						IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
							IF (TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
								INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
								(TIPM_CONSECUTIVO
								,TIPM_ORIGEN_CLIENTE
								,TIPM_FECHA
								,TIPM_NUM_IDEN
								,TIPM_TID_CODIGO
								,TIPM_NUMERO_CUENTA
								,TIPM_IPD_CONSECUTIVO
								,TIPM_NUM_IDEN_COMER
								,TIPM_TID_CODIGO_COMER
								,TIPM_USUARIO_COMER
								,TIPM_MONTO_ODP
								,TIPM_MONTO_GMF
								,TIPM_PROCESADO
								,TIPM_TPA_MNEMONICO
								,TIPM_MONTO_ABD
								,TIPM_MONTO_SERVICIO
								,TIPM_MONTO_ABD_NETO
								,TIPM_ESTADO
								,TIPM_DESCRIPCION
								,TIPM_ISIN
								,TIPM_EMISOR
								,TIPM_TIPO_EMISOR
								,TIPM_IMPUESTO_ICA
								,TIPM_IMPUESTO_CREE
								,TIPM_OTROS_IMPUESTOS
								,TIPM_RETEFUENTE
								,TIPM_GRAVAMEN
								,TIPM_FUENTE
                ,TIPM_ORDEN
								)VALUES
								(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
								,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
								,SYSDATE                                       -- TIPM_FECHA
								,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
								,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
								,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
								,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
								,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
								,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
								,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
								,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
								,0                                             -- TIPM_MONTO_GMF
								,'N'                                           -- TIPM_PROCESADO
								,'POD'                                         -- TIPM_TPA_MNEMONICO
								,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
								,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
								,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
								,'AOK'                                         -- TIPM_ESTADO
								,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
								,P_ISIN                    										 -- TIPM_ISIN
								,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
								,P_IPD_TIPO_EMISOR               							 -- TIPM_TIPO_EMISOR
								,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
								,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
								,V_MONTO_ADI  			      										 -- TIPM_OTROS_IMPUESTOS
								,V_RETEFTE                										 -- TIPM_RETEFUENTE
								,V_CAE_M																			 -- TIPM_GRAVAMEN
								,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
                ,21
								);
							ELSE
								INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
								(TIPM_CONSECUTIVO
								,TIPM_ORIGEN_CLIENTE
								,TIPM_FECHA
								,TIPM_NUM_IDEN
								,TIPM_TID_CODIGO
								,TIPM_NUMERO_CUENTA
								,TIPM_IPD_CONSECUTIVO
								,TIPM_NUM_IDEN_COMER
								,TIPM_TID_CODIGO_COMER
								,TIPM_USUARIO_COMER
								,TIPM_MONTO_ODP
								,TIPM_MONTO_GMF
								,TIPM_PROCESADO
								,TIPM_TPA_MNEMONICO
								,TIPM_MONTO_ABD
								,TIPM_MONTO_SERVICIO
								,TIPM_MONTO_ABD_NETO
								,TIPM_ESTADO
								,TIPM_DESCRIPCION
								,TIPM_ISIN
								,TIPM_EMISOR
								,TIPM_IMPUESTO_ICA
								,TIPM_IMPUESTO_CREE
								,TIPM_OTROS_IMPUESTOS
								,TIPM_RETEFUENTE
								,TIPM_GRAVAMEN
								,TIPM_FUENTE
                ,TIPM_ORDEN
								)VALUES
								(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
								,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
								,SYSDATE                                       -- TIPM_FECHA
								,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
								,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
								,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
								,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
								,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
								,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
								,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
								,0                                             -- TIPM_MONTO_ODP
								,0                                             -- TIPM_MONTO_GMF
								,'N'                                           -- TIPM_PROCESADO
								,'POD'                                         -- TIPM_TPA_MNEMONICO
								,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
								,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
								,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
								,'MPS'                                         -- TIPM_ESTADO
								,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
								,P_ISIN                    										 -- TIPM_ISIN
								,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
								,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
								,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
								,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
								,V_RETEFTE                										 -- TIPM_RETEFUENTE
								,V_CAE_M 																			 -- TIPM_GRAVAMEN
								,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
                ,22
								);
							END IF;
						ELSE
							INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
							(TIPM_CONSECUTIVO
							,TIPM_ORIGEN_CLIENTE
							,TIPM_FECHA
							,TIPM_NUM_IDEN
							,TIPM_TID_CODIGO
							,TIPM_NUMERO_CUENTA
							,TIPM_IPD_CONSECUTIVO
							,TIPM_NUM_IDEN_COMER
							,TIPM_TID_CODIGO_COMER
							,TIPM_USUARIO_COMER
							,TIPM_MONTO_ODP
							,TIPM_MONTO_GMF
							,TIPM_PROCESADO
							,TIPM_TPA_MNEMONICO
							,TIPM_MONTO_ABD
							,TIPM_MONTO_SERVICIO
							,TIPM_MONTO_ABD_NETO
							,TIPM_ESTADO
							,TIPM_DESCRIPCION
							,TIPM_ISIN
							,TIPM_EMISOR
							,TIPM_IMPUESTO_ICA
							,TIPM_IMPUESTO_CREE
							,TIPM_OTROS_IMPUESTOS
							,TIPM_RETEFUENTE
							,TIPM_GRAVAMEN
							,TIPM_FUENTE
              ,TIPM_ORDEN
							)VALUES
							(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
							,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
							,SYSDATE                                       -- TIPM_FECHA
							,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
							,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
							,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
							,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
							,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
							,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
							,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
							,0                                             -- TIPM_MONTO_ODP
							,0                                             -- TIPM_MONTO_GMF
							,'N'                                           -- TIPM_PROCESADO
							,'POD'                                         -- TIPM_TPA_MNEMONICO
							,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
							,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
							,'INV'                                         -- TIPM_ESTADO
							,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
							,P_ISIN                    										 -- TIPM_ISIN
							,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
							,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
							,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
							,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
							,V_RETEFTE                										 -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
							,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
              ,23
							);
						END IF;
					ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,0                                             -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'POD'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'SAN'                                         -- TIPM_ESTADO
						,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
						,P_ISIN                                        -- TIPM_ISIN
						,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI  	           										 -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                										 -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,24
						);
					END IF;
				END IF;
			ELSE
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                             -- TIPM_MONTO_ODP
				,0                                             -- TIPM_MONTO_GMF
				,'N'                                           -- TIPM_PROCESADO
				,'POD'                                         -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'CIN'                                         -- TIPM_ESTADO
				,'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP' -- TIPM_DESCRIPCION
				,P_ISIN                                        -- TIPM_ISIN
				,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE                										 -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,25
				);
			END IF;
-- **************************************************************************
-- **************************************************************************

		ELSIF  P_IPD_TIPO_EMISOR = 'T'
		AND P_IPD_PAGO = 'S'
		AND P_IPD_TRASLADO_FONDOS = 'N'
		AND P_IPD_INSTRUCCION_POD = 'S' THEN

			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
			V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
			V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
			V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
			V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
			V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
			V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
--

			IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                             -- TIPM_MONTO_ODP
				,0                                             -- TIPM_MONTO_GMF
				,'N'                                           -- TIPM_PROCESADO
				,'POD'                                         -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'NTS'                                         -- TIPM_ESTADO
				,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
				,P_ISIN                                        -- TIPM_ISIN
				,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE                                     -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,26
				);
			ELSE
				IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
					IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
						IF (TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M) < V_MONTO_MAX_POD THEN
							INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
							(TIPM_CONSECUTIVO
							,TIPM_ORIGEN_CLIENTE
							,TIPM_FECHA
							,TIPM_NUM_IDEN
							,TIPM_TID_CODIGO
							,TIPM_NUMERO_CUENTA
							,TIPM_IPD_CONSECUTIVO
							,TIPM_NUM_IDEN_COMER
							,TIPM_TID_CODIGO_COMER
							,TIPM_USUARIO_COMER
							,TIPM_MONTO_ODP
							,TIPM_MONTO_GMF
							,TIPM_PROCESADO
							,TIPM_TPA_MNEMONICO
							,TIPM_MONTO_ABD
							,TIPM_MONTO_SERVICIO
							,TIPM_MONTO_ABD_NETO
							,TIPM_ESTADO
							,TIPM_DESCRIPCION
							,TIPM_ISIN
							,TIPM_EMISOR
							,TIPM_TIPO_EMISOR
							,TIPM_IMPUESTO_ICA
							,TIPM_IMPUESTO_CREE
							,TIPM_OTROS_IMPUESTOS
							,TIPM_RETEFUENTE
							,TIPM_GRAVAMEN
							,TIPM_FUENTE
              ,TIPM_ORDEN
							)VALUES
							(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
							,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
							,SYSDATE                                       -- TIPM_FECHA
							,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
							,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
							,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
							,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
							,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
							,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
							,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
							,0                                             -- TIPM_MONTO_GMF
							,'N'                                           -- TIPM_PROCESADO
							,'POD'                                         -- TIPM_TPA_MNEMONICO
							,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
							,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
							,'AOK'                                         -- TIPM_ESTADO
							,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
							,P_ISIN                    										 -- TIPM_ISIN
							,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
							,P_IPD_TIPO_EMISOR                      			 -- TIPM_TIPO_EMISOR
							,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
							,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
							,V_MONTO_ADI  				     										 -- TIPM_OTROS_IMPUESTOS
							,V_RETEFTE                 										 -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
							,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
              ,27
							);
						ELSE
							INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
							(TIPM_CONSECUTIVO
							,TIPM_ORIGEN_CLIENTE
							,TIPM_FECHA
							,TIPM_NUM_IDEN
							,TIPM_TID_CODIGO
							,TIPM_NUMERO_CUENTA
							,TIPM_IPD_CONSECUTIVO
							,TIPM_NUM_IDEN_COMER
							,TIPM_TID_CODIGO_COMER
							,TIPM_USUARIO_COMER
							,TIPM_MONTO_ODP
							,TIPM_MONTO_GMF
							,TIPM_PROCESADO
							,TIPM_TPA_MNEMONICO
							,TIPM_MONTO_ABD
							,TIPM_MONTO_SERVICIO
							,TIPM_MONTO_ABD_NETO
							,TIPM_ESTADO
							,TIPM_DESCRIPCION
							,TIPM_ISIN
							,TIPM_EMISOR
							,TIPM_IMPUESTO_ICA
							,TIPM_IMPUESTO_CREE
							,TIPM_OTROS_IMPUESTOS
							,TIPM_RETEFUENTE
							,TIPM_GRAVAMEN
							,TIPM_FUENTE
              ,TIPM_ORDEN
							)VALUES
							(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
							,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
							,SYSDATE                                       -- TIPM_FECHA
							,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
							,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
							,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
							,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
							,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
							,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
							,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
							,0                                             -- TIPM_MONTO_ODP
							,0                                             -- TIPM_MONTO_GMF
							,'N'                                           -- TIPM_PROCESADO
							,'POD'                                         -- TIPM_TPA_MNEMONICO
							,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
							,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
							,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
							,'MPS'                                         -- TIPM_ESTADO
							,'MONTO POD SUPERA EL MAXIMO PERMITIDO'        -- TIPM_DESCRIPCION
							,P_ISIN                    										 -- TIPM_ISIN
							,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
							,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
							,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
							,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
							,V_RETEFTE                										 -- TIPM_RETEFUENTE
							,V_CAE_M																			 -- TIPM_GRAVAMEN
							,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
              ,28
							);
						END IF;
					ELSE
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,0                                             -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'POD'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'INV'                                         -- TIPM_ESTADO
						,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
						,P_ISIN                    										 -- TIPM_ISIN
						,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                										 -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,29
						);
					END IF;
				ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
					,SYSDATE                                       -- TIPM_FECHA
					,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
					,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
					,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
					,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
					,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
					,0                                             -- TIPM_MONTO_ODP
					,0                                             -- TIPM_MONTO_GMF
					,'N'                                           -- TIPM_PROCESADO
					,'POD'                                         -- TIPM_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
					,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'SAN'                                         -- TIPM_ESTADO
					,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
					,P_ISIN                                        -- TIPM_ISIN
					,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
					,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
					,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
					,V_MONTO_ADI  	         											 -- TIPM_OTROS_IMPUESTOS
					,V_RETEFTE                										 -- TIPM_RETEFUENTE
					,V_CAE_M																			 -- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
          ,30
					);
				END IF;
			END IF;
-- ***************************************************************************
-- ***************************************************************************
		ELSIF P_IPD_TIPO_EMISOR = 'E'
		AND P_IPD_PAGO = 'N'
		AND P_IPD_TRASLADO_FONDOS = 'S'
		AND NVL(P_IPD_INSTRUCCION_POD,'N') = 'N' THEN

			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
				V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
				V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
				V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
				V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
				V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
				V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
			--
			IF CCC1_CCC_SALDO_ADMON_VALORES = 0 THEN
				INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
				(TIPM_CONSECUTIVO
				,TIPM_ORIGEN_CLIENTE
				,TIPM_FECHA
				,TIPM_NUM_IDEN
				,TIPM_TID_CODIGO
				,TIPM_NUMERO_CUENTA
				,TIPM_IPD_CONSECUTIVO
				,TIPM_NUM_IDEN_COMER
				,TIPM_TID_CODIGO_COMER
				,TIPM_USUARIO_COMER
				,TIPM_MONTO_ODP
				,TIPM_MONTO_GMF
				,TIPM_PROCESADO
				,TIPM_TPA_MNEMONICO
				,TIPM_MONTO_ABD
				,TIPM_MONTO_SERVICIO
				,TIPM_MONTO_ABD_NETO
				,TIPM_ESTADO
				,TIPM_DESCRIPCION
				,TIPM_ISIN
				,TIPM_EMISOR
				,TIPM_IMPUESTO_ICA
				,TIPM_IMPUESTO_CREE
				,TIPM_OTROS_IMPUESTOS
				,TIPM_RETEFUENTE
				,TIPM_GRAVAMEN
				,TIPM_FUENTE
        ,TIPM_ORDEN
				)VALUES
				(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
				,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
				,SYSDATE                                       -- TIPM_FECHA
				,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
				,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
				,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
				,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
				,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
				,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
				,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
				,0                                          	 -- TIPM_MONTO_ODP
				,0                                          	 -- TIPM_MONTO_GMF
				,'N'                                        	 -- TIPM_PROCESADO
				,'FON'                                      	 -- TIPM_TPA_MNEMONICO
				,TDD.TDD_DIVIDENDOS                   				 -- TIPM_MONTO_ABD
				,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
				,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
				,'NTS'                                         -- TIPM_ESTADO
				,'NO TIENE SALDO'                              -- TIPM_DESCRIPCION
				,P_ISIN                                        -- TIPM_ISIN
				,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
				,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
				,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
				,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
				,V_RETEFTE               											 -- TIPM_RETEFUENTE
				,V_CAE_M																			 -- TIPM_GRAVAMEN
				,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
        ,31
				);
			ELSE
				IF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) >= 0 THEN
					IF NVL(TDD.TDD_IPD_VISADO,'N') = 'S' THEN
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M  -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'FON'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'AOK'                                         -- TIPM_ESTADO
						,'ALISTAMIENTO OK'                             -- TIPM_DESCRIPCION
						,P_ISIN                                        -- TIPM_ISIN
						,TDD.TDD_ENA_MNEMONICO                         -- TIPM_EMISOR
						,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI                                   -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                                     -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,32
						);
					ELSE
						INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
						(TIPM_CONSECUTIVO
						,TIPM_ORIGEN_CLIENTE
						,TIPM_FECHA
						,TIPM_NUM_IDEN
						,TIPM_TID_CODIGO
						,TIPM_NUMERO_CUENTA
						,TIPM_IPD_CONSECUTIVO
						,TIPM_NUM_IDEN_COMER
						,TIPM_TID_CODIGO_COMER
						,TIPM_USUARIO_COMER
						,TIPM_MONTO_ODP
						,TIPM_MONTO_GMF
						,TIPM_PROCESADO
						,TIPM_TPA_MNEMONICO
						,TIPM_MONTO_ABD
						,TIPM_MONTO_SERVICIO
						,TIPM_MONTO_ABD_NETO
						,TIPM_ESTADO
						,TIPM_DESCRIPCION
						,TIPM_ISIN
						,TIPM_EMISOR
						,TIPM_IMPUESTO_ICA
						,TIPM_IMPUESTO_CREE
						,TIPM_OTROS_IMPUESTOS
						,TIPM_RETEFUENTE
						,TIPM_GRAVAMEN
						,TIPM_FUENTE
            ,TIPM_ORDEN
						)VALUES
						(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
						,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
						,SYSDATE                                       -- TIPM_FECHA
						,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
						,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
						,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
						,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
						,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
						,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
						,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
						,0                                             -- TIPM_MONTO_ODP
						,0                                             -- TIPM_MONTO_GMF
						,'N'                                           -- TIPM_PROCESADO
						,'FON'                                         -- TIPM_TPA_MNEMONICO
						,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
						,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
						,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
						,'INV'                                         -- TIPM_ESTADO
						,'INSTRUCCION NO VISADA'                       -- TIPM_DESCRIPCION
						,P_ISIN                    										 -- TIPM_ISIN
						,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
						,V_MONTO_ICA 																	 -- TIPM_IMPUESTO_ICA
						,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
						,V_MONTO_ADI																	 -- TIPM_OTROS_IMPUESTOS
						,V_RETEFTE                										 -- TIPM_RETEFUENTE
						,V_CAE_M																			 -- TIPM_GRAVAMEN
						,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
            ,33
						);
					END IF;
				ELSIF CCC1_CCC_SALDO_ADMON_VALORES - NVL(TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M,0) < 0 THEN
					INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
					(TIPM_CONSECUTIVO
					,TIPM_ORIGEN_CLIENTE
					,TIPM_FECHA
					,TIPM_NUM_IDEN
					,TIPM_TID_CODIGO
					,TIPM_NUMERO_CUENTA
					,TIPM_IPD_CONSECUTIVO
					,TIPM_NUM_IDEN_COMER
					,TIPM_TID_CODIGO_COMER
					,TIPM_USUARIO_COMER
					,TIPM_MONTO_ODP
					,TIPM_MONTO_GMF
					,TIPM_PROCESADO
					,TIPM_TPA_MNEMONICO
					,TIPM_MONTO_ABD
					,TIPM_MONTO_SERVICIO
					,TIPM_MONTO_ABD_NETO
					,TIPM_ESTADO
					,TIPM_DESCRIPCION
					,TIPM_ISIN
					,TIPM_EMISOR
					,TIPM_IMPUESTO_ICA
					,TIPM_IMPUESTO_CREE
					,TIPM_OTROS_IMPUESTOS
					,TIPM_RETEFUENTE
					,TIPM_GRAVAMEN
					,TIPM_FUENTE
          ,TIPM_ORDEN
					)VALUES
					(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
					,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
					,SYSDATE                                       -- TIPM_FECHA
					,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
					,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
					,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
					,TDD.TDD_IPD_CONSECUTIVO                       -- TIPM_IPD_CONSECUTIVO
					,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
					,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
					,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
					,0                                             -- TIPM_MONTO_ODP
					,0                                             -- TIPM_MONTO_GMF
					,'N'                                           -- TIPM_PROCESADO
					,'FON'                                         -- TIPM_TPA_MNEMONICO
					,TDD.TDD_DIVIDENDOS                            -- TIPM_MONTO_ABD
					,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
					,TDD.TDD_DIVIDENDOS+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
					,'SAN'                                         -- TIPM_ESTADO
					,'SALDO ADMON VALORES NEGATIVO'                -- TIPM_DESCRIPCION
					,P_ISIN                    										 -- TIPM_ISIN
					,TDD.TDD_ENA_MNEMONICO                  			 -- TIPM_EMISOR
					,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
					,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
					,V_MONTO_ADI  		         										 -- TIPM_OTROS_IMPUESTOS
					,V_RETEFTE                                     -- TIPM_RETEFUENTE
					,V_CAE_M																			 -- TIPM_GRAVAMEN
					,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
          ,34
					);
				END IF;
			END IF;
-- ***************************************************************************
-- ***************************************************************************
		ELSE

			V_MONTO_SERVICIO := 0;

			V_MONTO_SERVICIO := TDD.TDD_TOTAL_SERVICIO + TDD.TDD_VALOR_IVA;

			IF TDD.TDD_IMPUESTO_ICA != 0 THEN
			V_MONTO_ICA := TDD.TDD_IMPUESTO_ICA;
			ELSE
			V_MONTO_ICA := 0;
			END IF;

			IF TDD.TDD_IMPUESTO_CREE != 0 THEN
			V_MONTO_CREE := TDD.TDD_IMPUESTO_CREE;
			ELSE
			V_MONTO_CREE := 0;
			END IF;

			IF TDD.TDD_OTROS_IMPUESTOS != 0 THEN
			V_MONTO_ADI := TDD.TDD_OTROS_IMPUESTOS;
			ELSE
			V_MONTO_ADI := 0;
			END IF;

			V_MONTO_ICA 	:= NVL(V_MONTO_ICA,0);
			V_MONTO_CREE 	:= NVL(V_MONTO_CREE,0);
			V_MONTO_ADI 	:= NVL(V_MONTO_ADI,0);

			V_RETEFTE := NULL;

			V_RETEFTE := TDD.TDD_RETEFUENTE;

			V_RETEFTE := NVL(V_RETEFTE,0);

			V_CAE_M := NULL;

			V_CAE_M := TDD.TDD_GRAVAMEN;

			V_CAE_M := NVL(V_CAE_M,0);
			--

			V_MONTO_ORDEN1  := NVL(TDD.TDD_DIVIDENDOS, 0) + V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M;
			V_MONTO_GMF     := 0;

			INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
			(TIPM_CONSECUTIVO
			,TIPM_ORIGEN_CLIENTE
			,TIPM_FECHA
			,TIPM_NUM_IDEN
			,TIPM_TID_CODIGO
			,TIPM_NUMERO_CUENTA
			,TIPM_IPD_CONSECUTIVO
			,TIPM_NUM_IDEN_COMER
			,TIPM_TID_CODIGO_COMER
			,TIPM_USUARIO_COMER
			,TIPM_MONTO_ODP
			,TIPM_MONTO_GMF
			,TIPM_PROCESADO
			,TIPM_TPA_MNEMONICO
			,TIPM_MONTO_ABD
			,TIPM_MONTO_SERVICIO
			,TIPM_MONTO_ABD_NETO
			,TIPM_ESTADO
			,TIPM_DESCRIPCION
			,TIPM_ISIN
			,TIPM_IMPUESTO_ICA
			,TIPM_IMPUESTO_CREE
			,TIPM_OTROS_IMPUESTOS
			,TIPM_RETEFUENTE
			,TIPM_GRAVAMEN
			,TIPM_FUENTE
      ,TIPM_ORDEN
			)VALUES
			(TIPM_SEQ.NEXTVAL                              -- TIPM_CONSECUTIVO
			,DECODE(TDD.TDD_IPD_BAN_CODIGO,51,'DAV','COR') -- TIPM_ORIGEN_CLIENTE
			,SYSDATE                                       -- TIPM_FECHA
			,P_CLI_PER_NUM_IDEN                            -- TIPM_NUM_IDEN
			,P_CLI_PER_TID_CODIGO                          -- TIPM_TID_CODIGO
			,P_NUMERO_CUENTA                               -- TIPM_NUMERO_CUENTA
			,NULL                                          -- TIPM_IPD_CONSECUTIVO
			,TDD.TDD_CCC_PER_NUM_IDEN                      -- TIPM_NUM_IDEN_COMER
			,TDD.TDD_CCC_PER_TID_CODIGO                    -- TIPM_TID_CODIGO_COMER
			,TDD.TDD_NOMBRE_COMERCIAL                      -- TIPM_USUARIO_COMER
			,V_MONTO_ORDEN1                                -- TIPM_MONTO_ODP
			,V_MONTO_GMF                                   -- TIPM_MONTO_GMF
			,'N'                                           -- TIPM_PROCESADO
			,NULL                                          -- TIPM_TPA_MNEMONICO
			,NVL(TDD.TDD_DIVIDENDOS, 0)                    -- TIPM_MONTO_ABD
			,V_MONTO_SERVICIO                              -- TIPM_MONTO_SERVICIO
			,NVL(TDD.TDD_DIVIDENDOS, 0)+V_MONTO_SERVICIO+V_MONTO_ICA+V_MONTO_CREE+V_MONTO_ADI+V_RETEFTE+V_CAE_M -- TIPM_MONTO_ABD_NETO
			,'AOK'                                         -- TIPM_ESTADO
			,'CLIENTE SIN INSTRUCCION'                     -- TIPM_DESCRIPCION
			,P_ISIN											                   -- TIPM_ISIN
			,V_MONTO_ICA                                   -- TIPM_IMPUESTO_ICA
			,V_MONTO_CREE                                  -- TIPM_IMPUESTO_CREE
			,V_MONTO_ADI  	           										 -- TIPM_OTROS_IMPUESTOS
			,V_RETEFTE                										 -- TIPM_RETEFUENTE
			,V_CAE_M																			 -- TIPM_GRAVAMEN
			,DECODE(P_ISIN, 'COC04PA00016', 'ECO', DECODE(P_ISIN, 'COE15PA00026', 'ISA', 'DAV'))  -- TIPM_FUENTE
      ,35
			);
		END IF;
	END LOOP;
	CLOSE C_CURSOR;
  COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		ERRORSQL := SUBSTR(SQLERRM,1,80);

		P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS 2'
																				,P_ERROR       => P_CLI_PER_NUM_IDEN||';'||P_CLI_PER_TID_CODIGO||';'||P_NUMERO_CUENTA||';'||'OTROSERRORES'||sqlerrm
																				,P_TABLA_ERROR => NULL);
END PROCESO_PAGOS_MASIVOS_DIV;

PROCEDURE ORDENES_PAGO_PROC_MASIVO (P_ORIGEN_CLIENTE VARCHAR2
                                   ,P_TIPO_ORDEN VARCHAR2 DEFAULT 'PAG'
                                   ,P_TIPO_EMISOR VARCHAR2 DEFAULT 'E') IS
  PRAGMA AUTONOMOUS_TRANSACTION;

   P_GENERO  VARCHAR2(2);
   P_DETALLE VARCHAR2(100);

   CURSOR C_IPDX IS
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
          ,IPD_CCC_CLI_PER_TID_CODIGO
          ,IPD_CCC_NUMERO_CUENTA
          ,IPD_TAC_MNEMONICO
          ,IPD_SUC_CODIGO
          ,IPD_TPA_MNEMONICO
          ,IPD_A_NOMBRE_DE
          ,IPD_CONSIGNAR
          ,IPD_ENTREGAR_RECOGE
          ,IPD_ENVIA_FAX
          ,NVL(IPD_CRUCE_CHEQUE,'RP') IPD_CRUCE_CHEQUE   ---VALIDAR SI APLICA
          ,IPD_PER_NUM_IDEN
          ,IPD_PER_TID_CODIGO
          ,IPD_PAGAR_A
          ,IPD_BAN_CODIGO
          ,IPD_NUM_CUENTA_CONSIGNAR
          ,IPD_TCB_MNEMONICO
          ,IPD_DIRECCION_ENVIO_CHEQUE
          ,IPD_AGE_CODIGO
          ,IPD_PREGUNTAR_POR
          ,IPD_FAX
          ,IPD_OCL_CLI_PER_NUM_IDEN_RELAC
          ,IPD_OCL_CLI_PER_TID_CODIGO_REL
          ,IPD_CCC_CLI_PER_NUM_IDEN_TRANS
          ,IPD_CCC_CLI_PER_TID_CODIGO_TRA
          ,IPD_CCC_NUMERO_CUENTA_TRANSF
          ,IPD_MAS_INSTRUCCIONES
          ,IPD_NUM_IDEN
          ,IPD_TID_CODIGO
          ,IPD_MEDIO_RECEPCION
          ,IPD_DETALLE_MEDIO_RECEPCION
          ,IPD_HORA_RECEPCION
          ,IPD_FECHA_RECEPCION
          ,IPD_NUMERO_RADICACION
          ,IPD_NUM_IDEN_ACH
          ,IPD_TID_CODIGO_ACH
          ,IPD_NOMBRE_ACH
          ,IPD_DIGITO_CONTROL
          ,IPD_FAX_ACH
          ,IPD_EMAIL
          ,IPD_FIC_CODIGO_BOLSA
          ,IPD_FIC_PER_TID_CODIGO
          ,IPD_FIC_PER_NUM_IDEN
          ,IPD_GIRO_OTRA_CIUDAD
          ,IPD_CONSECUTIVO
          ,TIPM_NUM_IDEN_COMER
          ,TIPM_TID_CODIGO_COMER
          ,TIPM_USUARIO_COMER
          ,TIPM_MONTO_ODP
          ,TIPM_MONTO_GMF
          ,TIPM_CONSECUTIVO
          ,IPD_CFO_FON_CODIGO
    FROM  TMP_INSTRUCCIONES_PAGOS_MASIVO, INSTRUCCIONES_PAGOS_DIVIDENDOS
    WHERE TIPM_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
      AND TIPM_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
      AND TIPM_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
      AND TIPM_IPD_CONSECUTIVO = IPD_CONSECUTIVO
      AND TIPM_ORIGEN_CLIENTE = P_ORIGEN_CLIENTE
      AND TIPM_TPA_MNEMONICO IN ('TRB','ACH','CHE')
      AND TIPM_ODP_CONSECUTIVO IS NULL
      AND NVL(TIPM_PROCESADO,'N') = 'N'
      AND TIPM_ESTADO = 'AOK'
      AND TIPM_MONTO_ODP > 0
      AND TIPM_FECHA >= TRUNC(SYSDATE)
      AND TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
      AND TIPM_PROCESAR = 'S'
      AND ((TIPM_TIPO_EMISOR = P_TIPO_EMISOR AND P_ORIGEN_CLIENTE = 'COR')
            OR P_ORIGEN_CLIENTE = 'DAV')
      AND EXISTS (SELECT 'X'
                 FROM CUENTAS_CLIENTE_CORREDORES
                 WHERE  CCC_CLI_PER_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
                 AND CCC_CLI_PER_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
                 AND CCC_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
                 AND CCC_SALDO_ADMON_VALORES >= TIPM_MONTO_ODP);
   R_IPDX C_IPDX%ROWTYPE;

   CURSOR C_IPDX2 IS
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
            ,IPD_CCC_CLI_PER_TID_CODIGO
            ,IPD_CCC_NUMERO_CUENTA
            ,IPD_TAC_MNEMONICO
            ,IPD_SUC_CODIGO
            ,IPD_TPA_MNEMONICO
            ,IPD_A_NOMBRE_DE
            ,IPD_CONSIGNAR
            ,IPD_ENTREGAR_RECOGE
            ,IPD_ENVIA_FAX
            ,NVL(IPD_CRUCE_CHEQUE,'RP') IPD_CRUCE_CHEQUE   ---VALIDAR SI APLICA
            ,IPD_PER_NUM_IDEN
            ,IPD_PER_TID_CODIGO
            ,IPD_PAGAR_A
            ,IPD_BAN_CODIGO
            ,IPD_NUM_CUENTA_CONSIGNAR
            ,IPD_TCB_MNEMONICO
            ,IPD_DIRECCION_ENVIO_CHEQUE
            ,IPD_AGE_CODIGO
            ,IPD_PREGUNTAR_POR
            ,IPD_FAX
            ,IPD_OCL_CLI_PER_NUM_IDEN_RELAC
            ,IPD_OCL_CLI_PER_TID_CODIGO_REL
            ,IPD_CCC_CLI_PER_NUM_IDEN_TRANS
            ,IPD_CCC_CLI_PER_TID_CODIGO_TRA
            ,IPD_CCC_NUMERO_CUENTA_TRANSF
            ,IPD_MAS_INSTRUCCIONES
            ,IPD_NUM_IDEN
            ,IPD_TID_CODIGO
            ,IPD_MEDIO_RECEPCION
            ,IPD_DETALLE_MEDIO_RECEPCION
            ,IPD_HORA_RECEPCION
            ,IPD_FECHA_RECEPCION
            ,IPD_NUMERO_RADICACION
            ,IPD_NUM_IDEN_ACH
            ,IPD_TID_CODIGO_ACH
            ,IPD_NOMBRE_ACH
            ,IPD_DIGITO_CONTROL
            ,IPD_FAX_ACH
            ,IPD_EMAIL
            ,IPD_FIC_CODIGO_BOLSA
            ,IPD_FIC_PER_TID_CODIGO
            ,IPD_FIC_PER_NUM_IDEN
            ,IPD_GIRO_OTRA_CIUDAD
            ,IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,TIPM_CONSECUTIVO
            ,IPD_CFO_FON_CODIGO
      FROM  TMP_INSTRUCCIONES_PAGOS_MASIVO, INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE TIPM_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
        AND TIPM_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
        AND TIPM_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
        AND TIPM_IPD_CONSECUTIVO = IPD_CONSECUTIVO
        AND TIPM_TPA_MNEMONICO = 'FON'
        AND NVL(TIPM_PROCESADO,'N') = 'N'
        AND TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
        AND IPD_CFO_FON_CODIGO IS NOT NULL
		AND TIPM_FECHA >= TRUNC(SYSDATE-5)
        AND TIPM_MONTO_ODP > 0
        AND EXISTS (SELECT 'X'
                   FROM CUENTAS_CLIENTE_CORREDORES
                   WHERE  CCC_CLI_PER_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
                   AND CCC_CLI_PER_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
                   AND CCC_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
                   AND CCC_SALDO_ADMON_VALORES >= TIPM_MONTO_ODP);
   R_IPDX2 C_IPDX2%ROWTYPE;

   CURSOR C_IPDX_CON IS
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
            ,IPD_CCC_CLI_PER_TID_CODIGO
            ,IPD_CCC_NUMERO_CUENTA
            ,IPD_TAC_MNEMONICO
            ,IPD_SUC_CODIGO
            ,IPD_TPA_MNEMONICO
            ,IPD_A_NOMBRE_DE
            ,IPD_CONSIGNAR
            ,IPD_ENTREGAR_RECOGE
            ,IPD_ENVIA_FAX
            ,NVL(IPD_CRUCE_CHEQUE,'RP') IPD_CRUCE_CHEQUE   ---VALIDAR SI APLICA
            ,IPD_PER_NUM_IDEN
            ,IPD_PER_TID_CODIGO
            ,IPD_PAGAR_A
            ,IPD_BAN_CODIGO
            ,IPD_NUM_CUENTA_CONSIGNAR
            ,IPD_TCB_MNEMONICO
            ,IPD_DIRECCION_ENVIO_CHEQUE
            ,IPD_AGE_CODIGO
            ,IPD_PREGUNTAR_POR
            ,IPD_FAX
            ,IPD_OCL_CLI_PER_NUM_IDEN_RELAC
            ,IPD_OCL_CLI_PER_TID_CODIGO_REL
            ,IPD_CCC_CLI_PER_NUM_IDEN_TRANS
            ,IPD_CCC_CLI_PER_TID_CODIGO_TRA
            ,IPD_CCC_NUMERO_CUENTA_TRANSF
            ,IPD_MAS_INSTRUCCIONES
            ,IPD_NUM_IDEN
            ,IPD_TID_CODIGO
            ,IPD_MEDIO_RECEPCION
            ,IPD_DETALLE_MEDIO_RECEPCION
            ,IPD_HORA_RECEPCION
            ,IPD_FECHA_RECEPCION
            ,IPD_NUMERO_RADICACION
            ,IPD_NUM_IDEN_ACH
            ,IPD_TID_CODIGO_ACH
            ,IPD_NOMBRE_ACH
            ,IPD_DIGITO_CONTROL
            ,IPD_FAX_ACH
            ,IPD_EMAIL
            ,IPD_FIC_CODIGO_BOLSA
            ,IPD_FIC_PER_TID_CODIGO
            ,IPD_FIC_PER_NUM_IDEN
            ,IPD_GIRO_OTRA_CIUDAD
            ,IPD_CONSECUTIVO
            ,TIPM_NUM_IDEN_COMER
            ,TIPM_TID_CODIGO_COMER
            ,TIPM_USUARIO_COMER
            ,TIPM_MONTO_ODP
            ,TIPM_MONTO_GMF
            ,IPD_CFO_FON_CODIGO
      FROM  VW_ALISTAMIENTO_CONSOLIDADO,INSTRUCCIONES_PAGOS_DIVIDENDOS
      WHERE TIPM_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
        AND TIPM_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
        AND TIPM_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
        AND TIPM_IPD_CONSECUTIVO = IPD_CONSECUTIVO
        AND TIPM_ORIGEN_CLIENTE = P_ORIGEN_CLIENTE
        AND TIPM_TPA_MNEMONICO IN ('TRB','ACH','CHE')
        AND TIPM_ODP_CONSECUTIVO IS NULL
        AND NVL(TIPM_PROCESADO,'N') = 'N'
        AND TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
        AND TIPM_MONTO_ODP > 0
        AND TIPM_FECHA >= TRUNC(SYSDATE)
        AND TIPM_FECHA < TRUNC(SYSDATE+1)
        AND TIPM_PROCESAR = 'S'
        AND (TIPM_TIPO_EMISOR = P_TIPO_EMISOR AND P_ORIGEN_CLIENTE = 'COR')
        AND EXISTS (SELECT 'X'
                     FROM CUENTAS_CLIENTE_CORREDORES
                     WHERE  CCC_CLI_PER_NUM_IDEN = IPD_CCC_CLI_PER_NUM_IDEN
                     AND CCC_CLI_PER_TID_CODIGO = IPD_CCC_CLI_PER_TID_CODIGO
                     AND CCC_NUMERO_CUENTA = IPD_CCC_NUMERO_CUENTA
                     AND CCC_SALDO_ADMON_VALORES >= TIPM_MONTO_ODP);
   R_IPDX_CON C_IPDX_CON%ROWTYPE;

   CURSOR C_IBA IS
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = 'IBA';

   CURSOR C_CUENTA
      (P_CLI_PER_NUM_IDEN    VARCHAR2
      ,P_CLI_PER_TID_CODIGO  VARCHAR2
      ,P_NUMERO_CUENTA       VARCHAR2) IS
      SELECT CCC_PER_NUM_IDEN
            ,CCC_PER_TID_CODIGO
            ,PER_SUC_CODIGO
            ,PER_NOMBRE_USUARIO
            ,CCC_SALDO_ADMON_VALORES
      FROM   CUENTAS_CLIENTE_CORREDORES
            ,PERSONAS
      WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
      AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
      AND    CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
      AND    CCC_PER_NUM_IDEN = PER_NUM_IDEN
      AND    CCC_PER_TID_CODIGO = PER_TID_CODIGO;
   CCC1   C_CUENTA%ROWTYPE;

   CURSOR C_CLIENTE_EXCENTO (P_NID VARCHAR2, P_TID VARCHAR2) IS
      SELECT CLI_EXCENTO_DXM_FONDOS
      FROM   CLIENTES
      WHERE  CLI_PER_NUM_IDEN = P_NID
      AND    CLI_PER_TID_CODIGO = P_NID;

   CURSOR C_SALDO_CCC IS
     SELECT CCC_SALDO_ADMON_VALORES
     FROM CUENTAS_CLIENTE_CORREDORES
     WHERE CCC_CLI_PER_NUM_IDEN = R_IPDX.IPD_CCC_CLI_PER_NUM_IDEN
     AND CCC_CLI_PER_TID_CODIGO = R_IPDX.IPD_CCC_CLI_PER_TID_CODIGO
     AND CCC_NUMERO_CUENTA = R_IPDX.IPD_CCC_NUMERO_CUENTA;
   SALDO_CCC C_SALDO_CCC%ROWTYPE;

   CURSOR CONSTANTE(P_CON_MNEMONICO VARCHAR2) is
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = P_CON_MNEMONICO;

   P_MONTO_ORDEN1       ORDENES_DE_PAGO.ODP_MONTO_ORDEN%TYPE:= NULL;
   P_MONTO_IMGF1        ORDENES_DE_PAGO.ODP_MONTO_IMGF%TYPE := NULL;
   P_EXCENTO1           VARCHAR2(1) := NULL;
   P_IBA1               CONSTANTES.CON_VALOR%TYPE:= NULL;
   CONSECUTIVO_ODP      ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
   FECHA1               DATE;

   CURSOR C_NUMERO IS
      SELECT DPA_SEQ.NEXTVAL
      FROM   DUAL;

   CONS_DPA                 NUMBER;
   NVOCONS	                NUMBER;
   P_ESTADO                 ORDENES_DE_PAGO.ODP_ESTADO%TYPE := NULL;
   P_APROBADA_POR           ORDENES_DE_PAGO.ODP_APROBADA_POR%TYPE := NULL;
   P_TERMINAL_VERIFICA      ORDENES_DE_PAGO.ODP_TERMINAL_VERIFICA%TYPE := NULL;
   P_VERIFICADO_COMERCIAL   ORDENES_DE_PAGO.ODP_VERIFICADO_COMERCIAL%TYPE := NULL;
   P_DILIGENCIADA_POR       ORDENES_DE_PAGO.ODP_DILIGENCIADA_POR%TYPE := NULL;
   P_FECHA_APROBACION       ORDENES_DE_PAGO.ODP_FECHA_APROBACION%TYPE := NULL;
   P_FECHA_VERIFICA         ORDENES_DE_PAGO.ODP_FECHA_VERIFICA%TYPE := NULL;
   P_FECHA_EJECUCION        ORDENES_DE_PAGO.ODP_FECHA_EJECUCION%TYPE := NULL;
   CONCEPTO                 ORDENES_DE_PAGO.ODP_COT_MNEMONICO%TYPE := NULL;
   ERRORSQL VARCHAR2(100);
   EXCEDE_MAXIMO EXCEPTION;

   V_CLI_PER_NUM_IDEN   CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
   V_CLI_PER_TID_CODIGO CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
   V_NUMERO_CUENTA      CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;

   V_SALDO_DIVIDENDOS NUMBER(22,2);
   V_COMM NUMBER := 0;

   V_ESTADO      VARCHAR2(3);
   V_DESCRIPCION VARCHAR2(200);
   P_DESCRIPCION VARCHAR2(200);

   V_CCC_SALDO_ADMON_VALORES NUMBER;
   TOTAL_ODP NUMBER;

   V_FONDO_COMPARTIMENTO VARCHAR2(100);
   V_SALARIO_MINIMO      NUMBER;
   BASE                  VARCHAR2(10);
   R_INSTRUCCION         INSTRUCCIONES_PAGOS_DIVIDENDOS%ROWTYPE;
   P_OFO_CONS NUMBER;
   P_OFO_SUC  NUMBER;
BEGIN
  IF P_TIPO_ORDEN = 'PAG' AND ((P_ORIGEN_CLIENTE = 'DAV') OR (P_ORIGEN_CLIENTE = 'COR' AND P_TIPO_EMISOR = 'E')) THEN
    OPEN C_IPDX;
    FETCH C_IPDX INTO R_IPDX;
    WHILE C_IPDX%FOUND LOOP
      BEGIN
       V_ESTADO := 'POK';
       V_DESCRIPCION := 'ORDEN DE PAGO GENERADA';

       V_COMM := V_COMM + 1;

       IF V_ESTADO = 'POK' THEN
         SELECT ODP_SEQ.NEXTVAL INTO CONSECUTIVO_ODP FROM DUAL;
         P_ESTADO := 'APR';
         P_APROBADA_POR     := R_IPDX.TIPM_USUARIO_COMER;
         P_TERMINAL_VERIFICA := 'NOCTURNO';
         P_VERIFICADO_COMERCIAL := 'S';
         P_DILIGENCIADA_POR := R_IPDX.TIPM_USUARIO_COMER;
         SELECT SYSDATE INTO P_FECHA_APROBACION FROM DUAL;
         SELECT SYSDATE INTO P_FECHA_VERIFICA FROM DUAL;
         SELECT SYSDATE INTO P_FECHA_EJECUCION FROM DUAL;

         --.--  SANDRA MOTTA : 4XM
         OPEN C_IBA;
         FETCH C_IBA INTO P_IBA1;
         CLOSE C_IBA;
         P_IBA1 := NVL(P_IBA1,0);

         OPEN C_CLIENTE_EXCENTO(R_IPDX.IPD_CCC_CLI_PER_NUM_IDEN
                               ,R_IPDX.IPD_CCC_CLI_PER_TID_CODIGO
                               );
         FETCH C_CLIENTE_EXCENTO INTO P_EXCENTO1;
         CLOSE C_CLIENTE_EXCENTO;
         P_EXCENTO1 := NVL(P_EXCENTO1,'N');

         P_MONTO_ORDEN1  := R_IPDX.TIPM_MONTO_ODP;
         P_MONTO_IMGF1   := R_IPDX.TIPM_MONTO_GMF;

         IF R_IPDX.IPD_TPA_MNEMONICO IN ('ACH','TRB') THEN
           R_IPDX.IPD_SUC_CODIGO := 1;
         END IF;

         INSERT INTO ORDENES_DE_PAGO
            (ODP_CONSECUTIVO
            ,ODP_SUC_CODIGO
            ,ODP_NEG_CONSECUTIVO
            ,ODP_FECHA
            ,ODP_COLOCADA_POR
            ,ODP_TPA_MNEMONICO
            ,ODP_ESTADO
            ,ODP_ES_CLIENTE
            ,ODP_COT_MNEMONICO
            ,ODP_A_NOMBRE_DE
            ,ODP_FECHA_EJECUCION
            ,ODP_CONSIGNAR
            ,ODP_ENTREGAR_RECOGE
            ,ODP_ENVIA_FAX
            ,ODP_SOBREGIRO
            ,ODP_CRUCE_CHEQUE
            ,ODP_MONTO_ORDEN
            ,ODP_MONTO_IMGF
            ,ODP_NPR_PRO_MNEMONICO
            ,ODP_APROBADA_POR
            ,ODP_FECHA_APROBACION
            ,ODP_CCC_CLI_PER_NUM_IDEN
            ,ODP_CCC_CLI_PER_TID_CODIGO
            ,ODP_CCC_NUMERO_CUENTA
            ,ODP_PER_NUM_IDEN
            ,ODP_PER_TID_CODIGO
            ,ODP_PAGAR_A
            ,ODP_BAN_CODIGO
            ,ODP_NUM_CUENTA_CONSIGNAR
            ,ODP_TCB_MNEMONICO
            ,ODP_DIRECCION_ENVIO_CHEQUE
            ,ODP_AGE_CODIGO
            ,ODP_PREGUNTAR_POR
            ,ODP_FAX
            ,ODP_FECHA_VERIFICA
            ,ODP_TERMINAL_VERIFICA
            ,ODP_PER_NUM_IDEN_ES_DUENO
            ,ODP_PER_TID_CODIGO_ES_DUENO
            ,ODP_VERIFICADO_COMERCIAL
            ,ODP_TAC_MNEMONICO
            ,ODP_OCL_CLI_PER_NUM_IDEN_RELAC
            ,ODP_OCL_CLI_PER_TID_CODIGO_REL
            ,ODP_CCC_CLI_PER_NUM_IDEN_TRANS
            ,ODP_CCC_CLI_PER_TID_CODIGO_TRA
            ,ODP_CCC_NUMERO_CUENTA_TRANSFIE
            ,ODP_MAS_INSTRUCCIONES
            ,ODP_NUM_IDEN
            ,ODP_TID_CODIGO
            ,ODP_DILIGENCIADA_POR
            ,ODP_MEDIO_RECEPCION
            ,ODP_DETALLE_MEDIO_RECEPCION
            ,ODP_HORA_RECEPCION
            ,ODP_FECHA_RECEPCION
            ,ODP_NUMERO_RADICACION
            ,ODP_FIC_CODIGO_BOLSA
            ,ODP_FIC_PER_TID_CODIGO
            ,ODP_FIC_PER_NUM_IDEN
            ,ODP_GIRO_OTRA_CIUDAD
            ,ODP_FORMA_CARGUE_ACH)
         VALUES
            (CONSECUTIVO_ODP
            ,R_IPDX.IPD_SUC_CODIGO
            ,2
            ,SYSDATE
            ,R_IPDX.TIPM_USUARIO_COMER
            ,R_IPDX.IPD_TPA_MNEMONICO
            ,P_ESTADO
            ,'S'
            ,'PADMV'
            ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',R_IPDX.IPD_NOMBRE_ACH,R_IPDX.IPD_A_NOMBRE_DE)
            ,P_FECHA_EJECUCION
            ,R_IPDX.IPD_CONSIGNAR
            ,R_IPDX.IPD_ENTREGAR_RECOGE
            ,R_IPDX.IPD_ENVIA_FAX
            ,'N'
            ,R_IPDX.IPD_CRUCE_CHEQUE
            ,P_MONTO_ORDEN1
            ,-P_MONTO_IMGF1
            ,'ADVAL'
            ,P_APROBADA_POR
            ,P_FECHA_APROBACION
            ,R_IPDX.IPD_CCC_CLI_PER_NUM_IDEN
            ,R_IPDX.IPD_CCC_CLI_PER_TID_CODIGO
            ,R_IPDX.IPD_CCC_NUMERO_CUENTA
            ,R_IPDX.IPD_PER_NUM_IDEN
            ,R_IPDX.IPD_PER_TID_CODIGO
            ,R_IPDX.IPD_PAGAR_A
            ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX.IPD_BAN_CODIGO)
            ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX.IPD_NUM_CUENTA_CONSIGNAR)
            ,DECODE(R_IPDX.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX.IPD_TCB_MNEMONICO)
            ,R_IPDX.IPD_DIRECCION_ENVIO_CHEQUE
            ,R_IPDX.IPD_AGE_CODIGO
            ,R_IPDX.IPD_PREGUNTAR_POR
            ,R_IPDX.IPD_FAX
            ,P_FECHA_VERIFICA
            ,P_TERMINAL_VERIFICA
            ,R_IPDX.TIPM_NUM_IDEN_COMER
            ,R_IPDX.TIPM_TID_CODIGO_COMER
            ,P_VERIFICADO_COMERCIAL
            ,R_IPDX.IPD_TAC_MNEMONICO
            ,R_IPDX.IPD_OCL_CLI_PER_NUM_IDEN_RELAC
            ,R_IPDX.IPD_OCL_CLI_PER_TID_CODIGO_REL
            ,R_IPDX.IPD_CCC_CLI_PER_NUM_IDEN_TRANS
            ,R_IPDX.IPD_CCC_CLI_PER_TID_CODIGO_TRA
            ,R_IPDX.IPD_CCC_NUMERO_CUENTA_TRANSF
            ,R_IPDX.IPD_MAS_INSTRUCCIONES
            ,R_IPDX.IPD_NUM_IDEN
            ,R_IPDX.IPD_TID_CODIGO
            ,P_DILIGENCIADA_POR
            ,R_IPDX.IPD_MEDIO_RECEPCION
            ,R_IPDX.IPD_DETALLE_MEDIO_RECEPCION
            ,R_IPDX.IPD_HORA_RECEPCION
            ,R_IPDX.IPD_FECHA_RECEPCION
            ,R_IPDX.IPD_NUMERO_RADICACION
            ,R_IPDX.IPD_FIC_CODIGO_BOLSA
            ,R_IPDX.IPD_FIC_PER_TID_CODIGO
            ,R_IPDX.IPD_FIC_PER_NUM_IDEN
            ,R_IPDX.IPD_GIRO_OTRA_CIUDAD
            ,'P');

         IF R_IPDX.IPD_TPA_MNEMONICO = 'ACH' AND
            R_IPDX.IPD_BAN_CODIGO IS NOT NULL AND
            R_IPDX.IPD_NUM_CUENTA_CONSIGNAR IS NOT NULL AND
            R_IPDX.IPD_TCB_MNEMONICO IS NOT NULL THEN

            OPEN C_NUMERO;
            FETCH C_NUMERO INTO CONS_DPA;
            CLOSE C_NUMERO;

            INSERT INTO DETALLES_PAGOS_ACH
               (DPA_CONSECUTIVO
               ,DPA_ODP_SUC_CODIGO
               ,DPA_ODP_NEG_CONSECUTIVO
               ,DPA_ODP_CONSECUTIVO
               ,DPA_NUM_IDEN
               ,DPA_TID_CODIGO
               ,DPA_NOMBRE
               ,DPA_BAN_CODIGO
               ,DPA_TCB_MNEMONICO
               ,DPA_NUMERO_CUENTA
               ,DPA_MONTO
               ,DPA_USUARIO
               ,DPA_FECHA
               ,DPA_TERMINAL
               ,DPA_REVERSADO
               ,DPA_DIGITO_CONTROL
               ,DPA_FAX
               ,DPA_EMAIL)
            VALUES
               (CONS_DPA
               ,R_IPDX.IPD_SUC_CODIGO
               ,2
               ,CONSECUTIVO_ODP
               ,R_IPDX.IPD_NUM_IDEN_ACH
               ,R_IPDX.IPD_TID_CODIGO_ACH
               ,NVL(R_IPDX.IPD_NOMBRE_ACH,R_IPDX.IPD_A_NOMBRE_DE)
               ,R_IPDX.IPD_BAN_CODIGO
               ,R_IPDX.IPD_TCB_MNEMONICO
               ,R_IPDX.IPD_NUM_CUENTA_CONSIGNAR
               ,P_MONTO_ORDEN1
               ,R_IPDX.TIPM_USUARIO_COMER
               ,SYSDATE
               ,'NOCTURNO'
               ,'N'
               ,R_IPDX.IPD_DIGITO_CONTROL
               ,R_IPDX.IPD_FAX_ACH
               ,R_IPDX.IPD_EMAIL);
         END IF;

         -- MARCA LOS MOVIMIENTOS COMO PAGADOS
         P_PAGOS_DIVIDENDOS.MARCAR_MCC_INSTRUCCION_PAGO_N (P_IPD_CONS              => R_IPDX.IPD_CONSECUTIVO
                                                          ,P_TIPO_INSTRUCCION_PAGO => 'PP'
                                                          ,P_SALDO                 => R_IPDX.TIPM_MONTO_ODP
                                                          ,P_ODP_CONS              => CONSECUTIVO_ODP
                                                          ,P_ODP_SUC               => R_IPDX.IPD_SUC_CODIGO
                                                          ,P_ODP_NEG               => 2);

         UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
         SET TIPM_PROCESADO = 'S'
            ,TIPM_ODP_CONSECUTIVO = CONSECUTIVO_ODP
            ,TIPM_ESTADO = V_ESTADO
            ,TIPM_DESCRIPCION = V_DESCRIPCION
         WHERE TIPM_CONSECUTIVO = R_IPDX.TIPM_CONSECUTIVO;
      ELSE
        UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
        SET TIPM_ESTADO = V_ESTADO
           ,TIPM_DESCRIPCION = V_DESCRIPCION
        WHERE TIPM_CONSECUTIVO = R_IPDX.TIPM_CONSECUTIVO;
      END IF;
      ----
      COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        V_ESTADO := 'ESY';
        V_DESCRIPCION := 'ERROR DEL SISTEMA: '||SUBSTR(SQLERRM,1,180);
        UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
        SET TIPM_ESTADO = V_ESTADO
           ,TIPM_DESCRIPCION = V_DESCRIPCION
        WHERE TIPM_CONSECUTIVO = R_IPDX.TIPM_CONSECUTIVO;
        COMMIT;
      END;
      FETCH C_IPDX INTO R_IPDX;
    END LOOP;
    CLOSE C_IPDX;
  ELSIF P_TIPO_ORDEN = 'PAG' AND (P_ORIGEN_CLIENTE = 'COR' AND P_TIPO_EMISOR = 'T') THEN
    OPEN C_IPDX_CON;
    FETCH C_IPDX_CON INTO R_IPDX_CON;
    WHILE C_IPDX_CON%FOUND LOOP
      BEGIN
       V_ESTADO := 'POK';
       V_DESCRIPCION := 'ORDEN DE PAGO CONSOLIDADA GENERADA';

       V_COMM := V_COMM + 1;

       IF V_ESTADO = 'POK' THEN
         SELECT ODP_SEQ.NEXTVAL INTO CONSECUTIVO_ODP FROM DUAL;
         P_ESTADO := 'APR';
         P_APROBADA_POR     := R_IPDX_CON.TIPM_USUARIO_COMER;
         P_TERMINAL_VERIFICA := 'NOCTURNO';
         P_VERIFICADO_COMERCIAL := 'S';
         P_DILIGENCIADA_POR := R_IPDX_CON.TIPM_USUARIO_COMER;
         SELECT SYSDATE INTO P_FECHA_APROBACION FROM DUAL;
         SELECT SYSDATE INTO P_FECHA_VERIFICA FROM DUAL;
         SELECT SYSDATE INTO P_FECHA_EJECUCION FROM DUAL;

         --.--  SANDRA MOTTA : 4XM
         OPEN C_IBA;
         FETCH C_IBA INTO P_IBA1;
         CLOSE C_IBA;
         P_IBA1 := NVL(P_IBA1,0);

         OPEN C_CLIENTE_EXCENTO(R_IPDX_CON.IPD_CCC_CLI_PER_NUM_IDEN
                               ,R_IPDX_CON.IPD_CCC_CLI_PER_TID_CODIGO
                               );
         FETCH C_CLIENTE_EXCENTO INTO P_EXCENTO1;
         CLOSE C_CLIENTE_EXCENTO;
         P_EXCENTO1 := NVL(P_EXCENTO1,'N');

         P_MONTO_ORDEN1  := R_IPDX_CON.TIPM_MONTO_ODP;
         P_MONTO_IMGF1   := R_IPDX_CON.TIPM_MONTO_GMF;

         IF R_IPDX_CON.IPD_TPA_MNEMONICO IN ('ACH','TRB') THEN
           R_IPDX_CON.IPD_SUC_CODIGO := 1;
         END IF;

         INSERT INTO ORDENES_DE_PAGO
            (ODP_CONSECUTIVO
            ,ODP_SUC_CODIGO
            ,ODP_NEG_CONSECUTIVO
            ,ODP_FECHA
            ,ODP_COLOCADA_POR
            ,ODP_TPA_MNEMONICO
            ,ODP_ESTADO
            ,ODP_ES_CLIENTE
            ,ODP_COT_MNEMONICO
            ,ODP_A_NOMBRE_DE
            ,ODP_FECHA_EJECUCION
            ,ODP_CONSIGNAR
            ,ODP_ENTREGAR_RECOGE
            ,ODP_ENVIA_FAX
            ,ODP_SOBREGIRO
            ,ODP_CRUCE_CHEQUE
            ,ODP_MONTO_ORDEN
            ,ODP_MONTO_IMGF
            ,ODP_NPR_PRO_MNEMONICO
            ,ODP_APROBADA_POR
            ,ODP_FECHA_APROBACION
            ,ODP_CCC_CLI_PER_NUM_IDEN
            ,ODP_CCC_CLI_PER_TID_CODIGO
            ,ODP_CCC_NUMERO_CUENTA
            ,ODP_PER_NUM_IDEN
            ,ODP_PER_TID_CODIGO
            ,ODP_PAGAR_A
            ,ODP_BAN_CODIGO
            ,ODP_NUM_CUENTA_CONSIGNAR
            ,ODP_TCB_MNEMONICO
            ,ODP_DIRECCION_ENVIO_CHEQUE
            ,ODP_AGE_CODIGO
            ,ODP_PREGUNTAR_POR
            ,ODP_FAX
            ,ODP_FECHA_VERIFICA
            ,ODP_TERMINAL_VERIFICA
            ,ODP_PER_NUM_IDEN_ES_DUENO
            ,ODP_PER_TID_CODIGO_ES_DUENO
            ,ODP_VERIFICADO_COMERCIAL
            ,ODP_TAC_MNEMONICO
            ,ODP_OCL_CLI_PER_NUM_IDEN_RELAC
            ,ODP_OCL_CLI_PER_TID_CODIGO_REL
            ,ODP_CCC_CLI_PER_NUM_IDEN_TRANS
            ,ODP_CCC_CLI_PER_TID_CODIGO_TRA
            ,ODP_CCC_NUMERO_CUENTA_TRANSFIE
            ,ODP_MAS_INSTRUCCIONES
            ,ODP_NUM_IDEN
            ,ODP_TID_CODIGO
            ,ODP_DILIGENCIADA_POR
            ,ODP_MEDIO_RECEPCION
            ,ODP_DETALLE_MEDIO_RECEPCION
            ,ODP_HORA_RECEPCION
            ,ODP_FECHA_RECEPCION
            ,ODP_NUMERO_RADICACION
            ,ODP_FIC_CODIGO_BOLSA
            ,ODP_FIC_PER_TID_CODIGO
            ,ODP_FIC_PER_NUM_IDEN
            ,ODP_GIRO_OTRA_CIUDAD
            ,ODP_FORMA_CARGUE_ACH)
         VALUES
            (CONSECUTIVO_ODP
            ,R_IPDX_CON.IPD_SUC_CODIGO
            ,2
            ,SYSDATE
            ,R_IPDX_CON.TIPM_USUARIO_COMER
            ,R_IPDX_CON.IPD_TPA_MNEMONICO
            ,P_ESTADO
            ,'S'
            ,'PADMV'
            ,DECODE(R_IPDX_CON.IPD_TPA_MNEMONICO,'ACH',R_IPDX_CON.IPD_NOMBRE_ACH,R_IPDX_CON.IPD_A_NOMBRE_DE)
            ,P_FECHA_EJECUCION
            ,R_IPDX_CON.IPD_CONSIGNAR
            ,R_IPDX_CON.IPD_ENTREGAR_RECOGE
            ,R_IPDX_CON.IPD_ENVIA_FAX
            ,'N'
            ,R_IPDX_CON.IPD_CRUCE_CHEQUE
            ,P_MONTO_ORDEN1
            ,-P_MONTO_IMGF1
            ,'ADVAL'
            ,P_APROBADA_POR
            ,P_FECHA_APROBACION
            ,R_IPDX_CON.IPD_CCC_CLI_PER_NUM_IDEN
            ,R_IPDX_CON.IPD_CCC_CLI_PER_TID_CODIGO
            ,R_IPDX_CON.IPD_CCC_NUMERO_CUENTA
            ,R_IPDX_CON.IPD_PER_NUM_IDEN
            ,R_IPDX_CON.IPD_PER_TID_CODIGO
            ,R_IPDX_CON.IPD_PAGAR_A
            ,DECODE(R_IPDX_CON.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX_CON.IPD_BAN_CODIGO)
            ,DECODE(R_IPDX_CON.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX_CON.IPD_NUM_CUENTA_CONSIGNAR)
            ,DECODE(R_IPDX_CON.IPD_TPA_MNEMONICO,'ACH',NULL,R_IPDX_CON.IPD_TCB_MNEMONICO)
            ,R_IPDX_CON.IPD_DIRECCION_ENVIO_CHEQUE
            ,R_IPDX_CON.IPD_AGE_CODIGO
            ,R_IPDX_CON.IPD_PREGUNTAR_POR
            ,R_IPDX_CON.IPD_FAX
            ,P_FECHA_VERIFICA
            ,P_TERMINAL_VERIFICA
            ,R_IPDX_CON.TIPM_NUM_IDEN_COMER
            ,R_IPDX_CON.TIPM_TID_CODIGO_COMER
            ,P_VERIFICADO_COMERCIAL
            ,R_IPDX_CON.IPD_TAC_MNEMONICO
            ,R_IPDX_CON.IPD_OCL_CLI_PER_NUM_IDEN_RELAC
            ,R_IPDX_CON.IPD_OCL_CLI_PER_TID_CODIGO_REL
            ,R_IPDX_CON.IPD_CCC_CLI_PER_NUM_IDEN_TRANS
            ,R_IPDX_CON.IPD_CCC_CLI_PER_TID_CODIGO_TRA
            ,R_IPDX_CON.IPD_CCC_NUMERO_CUENTA_TRANSF
            ,R_IPDX_CON.IPD_MAS_INSTRUCCIONES
            ,R_IPDX_CON.IPD_NUM_IDEN
            ,R_IPDX_CON.IPD_TID_CODIGO
            ,P_DILIGENCIADA_POR
            ,R_IPDX_CON.IPD_MEDIO_RECEPCION
            ,R_IPDX_CON.IPD_DETALLE_MEDIO_RECEPCION
            ,R_IPDX_CON.IPD_HORA_RECEPCION
            ,R_IPDX_CON.IPD_FECHA_RECEPCION
            ,R_IPDX_CON.IPD_NUMERO_RADICACION
            ,R_IPDX_CON.IPD_FIC_CODIGO_BOLSA
            ,R_IPDX_CON.IPD_FIC_PER_TID_CODIGO
            ,R_IPDX_CON.IPD_FIC_PER_NUM_IDEN
            ,R_IPDX_CON.IPD_GIRO_OTRA_CIUDAD
            ,'P');

         IF R_IPDX_CON.IPD_TPA_MNEMONICO = 'ACH' AND
            R_IPDX_CON.IPD_BAN_CODIGO IS NOT NULL AND
            R_IPDX_CON.IPD_NUM_CUENTA_CONSIGNAR IS NOT NULL AND
            R_IPDX_CON.IPD_TCB_MNEMONICO IS NOT NULL THEN

            OPEN C_NUMERO;
            FETCH C_NUMERO INTO CONS_DPA;
            CLOSE C_NUMERO;

            INSERT INTO DETALLES_PAGOS_ACH
               (DPA_CONSECUTIVO
               ,DPA_ODP_SUC_CODIGO
               ,DPA_ODP_NEG_CONSECUTIVO
               ,DPA_ODP_CONSECUTIVO
               ,DPA_NUM_IDEN
               ,DPA_TID_CODIGO
               ,DPA_NOMBRE
               ,DPA_BAN_CODIGO
               ,DPA_TCB_MNEMONICO
               ,DPA_NUMERO_CUENTA
               ,DPA_MONTO
               ,DPA_USUARIO
               ,DPA_FECHA
               ,DPA_TERMINAL
               ,DPA_REVERSADO
               ,DPA_DIGITO_CONTROL
               ,DPA_FAX
               ,DPA_EMAIL)
            VALUES
               (CONS_DPA
               ,R_IPDX_CON.IPD_SUC_CODIGO
               ,2
               ,CONSECUTIVO_ODP
               ,R_IPDX_CON.IPD_NUM_IDEN_ACH
               ,R_IPDX_CON.IPD_TID_CODIGO_ACH
               ,NVL(R_IPDX_CON.IPD_NOMBRE_ACH,R_IPDX_CON.IPD_A_NOMBRE_DE)
               ,R_IPDX_CON.IPD_BAN_CODIGO
               ,R_IPDX_CON.IPD_TCB_MNEMONICO
               ,R_IPDX_CON.IPD_NUM_CUENTA_CONSIGNAR
               ,P_MONTO_ORDEN1
               ,R_IPDX_CON.TIPM_USUARIO_COMER
               ,SYSDATE
               ,'NOCTURNO'
               ,'N'
               ,R_IPDX_CON.IPD_DIGITO_CONTROL
               ,R_IPDX_CON.IPD_FAX_ACH
               ,R_IPDX_CON.IPD_EMAIL);
         END IF;

         -- MARCA LOS MOVIMIENTOS COMO PAGADOS
         P_PAGOS_DIVIDENDOS.MARCAR_MCC_INSTRUCCION_PAGO_N (P_IPD_CONS              => R_IPDX_CON.IPD_CONSECUTIVO
                                                          ,P_TIPO_INSTRUCCION_PAGO => 'PP'
                                                          ,P_SALDO                 => R_IPDX_CON.TIPM_MONTO_ODP
                                                          ,P_ODP_CONS              => CONSECUTIVO_ODP
                                                          ,P_ODP_SUC               => R_IPDX_CON.IPD_SUC_CODIGO
                                                          ,P_ODP_NEG               => 2);

         UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
         SET TIPM_PROCESADO = 'S'
            ,TIPM_ODP_CONSECUTIVO = CONSECUTIVO_ODP
            ,TIPM_ESTADO = V_ESTADO
            ,TIPM_DESCRIPCION = V_DESCRIPCION
         WHERE TIPM_NUM_IDEN = R_IPDX_CON.IPD_CCC_CLI_PER_NUM_IDEN
           AND TIPM_TID_CODIGO = R_IPDX_CON.IPD_CCC_CLI_PER_TID_CODIGO
           AND TIPM_IPD_CONSECUTIVO = R_IPDX_CON.IPD_CONSECUTIVO
           AND TIPM_TPA_MNEMONICO = R_IPDX_CON.IPD_TPA_MNEMONICO
           AND TIPM_ESTADO = 'AOK'
           AND TIPM_PROCESADO = 'N'
           AND TIPM_TIPO_EMISOR = 'T';
      END IF;
      ----
      COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        V_ESTADO := 'ESY';
        V_DESCRIPCION := 'ERROR DEL SISTEMA: '||SUBSTR(SQLERRM,1,180);
        UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
        SET TIPM_ESTADO = V_ESTADO
           ,TIPM_DESCRIPCION = V_DESCRIPCION
        WHERE TIPM_NUM_IDEN = R_IPDX_CON.IPD_CCC_CLI_PER_NUM_IDEN
          AND TIPM_TID_CODIGO = R_IPDX_CON.IPD_CCC_CLI_PER_TID_CODIGO
          AND TIPM_IPD_CONSECUTIVO = R_IPDX_CON.IPD_CONSECUTIVO
          AND TIPM_TPA_MNEMONICO = R_IPDX_CON.IPD_TPA_MNEMONICO
          AND TIPM_ESTADO = 'AOK'
          AND TIPM_PROCESADO = 'N'
          AND TIPM_TIPO_EMISOR = 'T';
         COMMIT;
      END;
      FETCH C_IPDX_CON INTO R_IPDX_CON;
    END LOOP;
    CLOSE C_IPDX_CON;
  ELSIF P_TIPO_ORDEN = 'FON' THEN
    OPEN C_IPDX2;
    FETCH C_IPDX2 INTO R_IPDX2;
    WHILE C_IPDX2%FOUND LOOP
      BEGIN
        V_ESTADO := 'POK';
        V_DESCRIPCION := 'ORDEN DE FONDO GENERADA';

        IF V_ESTADO = 'POK' THEN
          OPEN C_CUENTA(R_IPDX2.IPD_CCC_CLI_PER_NUM_IDEN
                       ,R_IPDX2.IPD_CCC_CLI_PER_TID_CODIGO
                       ,R_IPDX2.IPD_CCC_NUMERO_CUENTA);
          FETCH C_CUENTA INTO CCC1;
          CLOSE C_CUENTA;

          SELECT FON_BMO_MNEMONICO
            INTO BASE
          FROM   FONDOS
          WHERE  FON_CODIGO = R_IPDX2.IPD_CFO_FON_CODIGO;

          --Consulta la instruccion de pago a que se hace referencia
          SELECT IPD_CCC_CLI_PER_NUM_IDEN
						     , IPD_CCC_CLI_PER_TID_CODIGO
							 , IPD_CCC_NUMERO_CUENTA
							 , IPD_MONTO_MINIMO
							 , IPD_ABONO_CUENTA
							 , IPD_TRASLADO_FONDOS
							 , IPD_PAGO
							 , IPD_SUC_CODIGO
							 , IPD_TPA_MNEMONICO
							 , IPD_ES_CLIENTE
							 , IPD_A_NOMBRE_DE
							 , IPD_CONSIGNAR
							 , IPD_ENTREGAR_RECOGE
							 , IPD_ENVIA_FAX
							 , IPD_CRUCE_CHEQUE
							 , IPD_SEBRA_COMPENSADO
							 , IPD_PER_NUM_IDEN
							 , IPD_PER_TID_CODIGO
							 , IPD_PAGAR_A
							 , IPD_BAN_CODIGO
							 , IPD_NUM_CUENTA_CONSIGNAR
							 , IPD_TCB_MNEMONICO
							 , IPD_DIRECCION_ENVIO_CHEQUE
							 , IPD_AGE_CODIGO
							 , IPD_PREGUNTAR_POR
							 , IPD_FAX
							 , IPD_OCL_CLI_PER_NUM_IDEN_RELAC
							 , IPD_OCL_CLI_PER_TID_CODIGO_REL
							 , IPD_CCC_CLI_PER_NUM_IDEN_TRANS
							 , IPD_CCC_CLI_PER_TID_CODIGO_TRA
							 , IPD_CCC_NUMERO_CUENTA_TRANSF
							 , IPD_CFO_CCC_NUMERO_CUENTA
							 , IPD_CFO_FON_CODIGO
							 , IPD_CFO_CODIGO
							 , IPD_TAC_MNEMONICO
							 , IPD_MAS_INSTRUCCIONES
							 , IPD_NUM_IDEN
							 , IPD_TID_CODIGO
							 , IPD_FECHA_REGISTRO
							 , IPD_USUARIO_REGISTRO
							 , IPD_TERMINAL_REGISTRO
							 , IPD_FECHA_MODIFICACION
							 , IPD_USUARIO_MODIFICACION
							 , IPD_TERMINAL_MODIFICACION
							 , IPD_NUM_IDEN_ACH
							 , IPD_TID_CODIGO_ACH
							 , IPD_DIGITO_CONTROL
							 , IPD_NOMBRE_ACH
							 , IPD_FAX_ACH
							 , IPD_EMAIL
							 , IPD_MEDIO_RECEPCION
							 , IPD_DETALLE_MEDIO_RECEPCION
							 , IPD_FECHA_RECEPCION
							 , IPD_HORA_RECEPCION
							 , IPD_NUMERO_RADICACION
							 , IPD_VISADO
							 , IPD_TIPO_ORIGEN_PAGO
							 , IPD_CONSECUTIVO
							 , IPD_FIC_CODIGO_BOLSA
							 , IPD_FIC_PER_TID_CODIGO
							 , IPD_FIC_PER_NUM_IDEN
							 , IPD_GIRO_OTRA_CIUDAD
							 , IPD_TIPO_EMISOR
							 , IPD_ESTADO
							 , IPD_INSTRUCCION_POD
							 , IPD_FECHA_INACTIVACION
							 , IPD_HORA_INACTIVACION
							 , IPD_MEDIO_INACTIVACION
							 , IPD_USUARIO_INACTIVACION
							 , IPD_TERMINAL_INACTIVACION
							 , IPD_MOTIVO_INACTIVACION
          INTO   R_INSTRUCCION
          FROM   INSTRUCCIONES_PAGOS_DIVIDENDOS
          WHERE  IPD_CCC_CLI_PER_NUM_IDEN = R_IPDX2.IPD_CCC_CLI_PER_NUM_IDEN
          AND    IPD_CCC_CLI_PER_TID_CODIGO = R_IPDX2.IPD_CCC_CLI_PER_TID_CODIGO
          AND    IPD_CCC_NUMERO_CUENTA = R_IPDX2.IPD_CCC_NUMERO_CUENTA
          AND    IPD_CONSECUTIVO = R_IPDX2.IPD_CONSECUTIVO;

          --Consulta el compartimento
          P_ORDENES_FONDOS.P_VALIDA_PARAMETROS_COMP (P_FON_CODIGO         => R_IPDX2.IPD_CFO_FON_CODIGO
                                                    ,P_PAR_CODIGO         =>  70
                                                    ,P_PFO_RANGO_MIN_CHAR => V_FONDO_COMPARTIMENTO);

          V_FONDO_COMPARTIMENTO := NVL(V_FONDO_COMPARTIMENTO,'N');

          --Salario minimo
          IF NVL(V_FONDO_COMPARTIMENTO,'N') = 'S' THEN
             OPEN CONSTANTE(P_CON_MNEMONICO => 'SAM');
             FETCH CONSTANTE INTO V_SALARIO_MINIMO;
             CLOSE CONSTANTE;
          END IF;

          --Llama el procedimiento para crear la orden de fondo
          P_PAGOS_DIVIDENDOS.ORDEN_FONDO_NOCTURNO
             (R_INSTRUCCION
             ,1
             ,V_FONDO_COMPARTIMENTO
             ,V_SALARIO_MINIMO
             ,BASE
             ,R_IPDX2.TIPM_MONTO_ODP
             ,CCC1.CCC_PER_NUM_IDEN
             ,CCC1.CCC_PER_TID_CODIGO
             ,R_IPDX2.TIPM_USUARIO_COMER
             ,'ADVAL'
             ,P_OFO_CONS
             ,P_OFO_SUC
             ,P_DESCRIPCION);

          IF P_OFO_CONS IS NOT NULL THEN
          -- MARCA LOS MOVIMIENTOS COMO PAGADOS
             P_PAGOS_DIVIDENDOS.MARCAR_MCC_INSTRUCCION_PAGO_N
                         ( P_IPD_CONS              => R_IPDX2.IPD_CONSECUTIVO
                          ,P_TIPO_INSTRUCCION_PAGO => 'PP'
                          ,P_SALDO                 => R_IPDX2.TIPM_MONTO_ODP
                          ,P_OFO_CONS              => P_OFO_CONS
                          ,P_OFO_SUC               => P_OFO_SUC);
             UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
             SET TIPM_PROCESADO = 'S'
                ,TIPM_ODP_CONSECUTIVO = CONSECUTIVO_ODP
                ,TIPM_ESTADO = V_ESTADO
                ,TIPM_DESCRIPCION = V_DESCRIPCION
             WHERE TIPM_CONSECUTIVO = R_IPDX2.TIPM_CONSECUTIVO;
          ELSE
            UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
            SET TIPM_ESTADO = 'ESY'
               ,TIPM_DESCRIPCION = P_DESCRIPCION
            WHERE TIPM_CONSECUTIVO = R_IPDX2.TIPM_CONSECUTIVO;
          END IF;
        END IF;
      END;
      FETCH C_IPDX2 INTO R_IPDX2;
    END LOOP;
    CLOSE C_IPDX2;
  END IF;
  COMMIT;
END ORDENES_PAGO_PROC_MASIVO;

PROCEDURE REPROCESO_PAGOS_MASIVOS_DIV IS

  P_CLI_PER_NUM_IDEN          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
  P_CLI_PER_TID_CODIGO        CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
  P_NUMERO_CUENTA             CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;

  CURSOR DIVIDENDOS IS
    SELECT TIPM_NUM_IDEN,
           TIPM_TID_CODIGO,
           TIPM_NUMERO_CUENTA,
           TIPM_CONSECUTIVO
    FROM   TMP_INSTRUCCIONES_PAGOS_MASIVO
    WHERE  TIPM_FECHA >= TRUNC(SYSDATE)
    AND    TIPM_FECHA < TRUNC(SYSDATE+1)
    --AND    TIPM_ESTADO IN ('AOK')
    GROUP BY TIPM_NUM_IDEN
            ,TIPM_TID_CODIGO
            ,TIPM_NUMERO_CUENTA
            ,TIPM_CONSECUTIVO;
  DIVIDENDOS_REC DIVIDENDOS%ROWTYPE;

  CURSOR DIVIDENDOS_X_ISIN (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER) IS
    SELECT MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC_CFC_FUG_ISI_MNEMONICO ISIN
          ,FUG_ENA_MNEMONICO EMISOR
    FROM MOVIMIENTOS_CUENTA_CORREDORES, FUNGIBLES
    WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
      AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
      AND MCC_CCC_NUMERO_CUENTA = P_CTA
      AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
      AND MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_TMC_MNEMONICO = 'ABD'
      AND MCC_PAGADO = 'N'
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN, MCC_CCC_CLI_PER_TID_CODIGO, MCC_CCC_NUMERO_CUENTA, MCC_CFC_FUG_ISI_MNEMONICO, FUG_ENA_MNEMONICO;
  REC_DIVIDENDOS_X_ISIN DIVIDENDOS_X_ISIN%ROWTYPE;

  CURSOR INSTRUCCION (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER) IS
    SELECT IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
          ,IPD_INSTRUCCION_POD
    FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
    WHERE IPD_CCC_CLI_PER_NUM_IDEN = P_ID
      AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
      AND IPD_CCC_NUMERO_CUENTA = P_CTA
      AND IPD_ESTADO = 'A'
      AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S')
      AND IPD_TIPO_ORIGEN_PAGO = 'DI';
  REC_INSTRUCCION INSTRUCCION%ROWTYPE;

  CURSOR INSTRUCCION_E (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
    FROM INSTRUCCIONES_PAGOS_DIVIDENDOS, DETALLE_INSTRUCCIONES_PAGOS
    WHERE IPD_CONSECUTIVO = DIPA_IPD_CONSECUTIVO
      AND IPD_CCC_CLI_PER_NUM_IDEN = P_ID
      AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
      AND IPD_CCC_NUMERO_CUENTA = P_CTA
      AND IPD_TIPO_EMISOR = 'E'
      AND IPD_ESTADO = 'A'
      AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S')
      AND IPD_TIPO_ORIGEN_PAGO = 'DI'
      AND DIPA_FUG_ISI_MNEMONICO = P_ISIN;
  REC_INSTRUCCION_E INSTRUCCION_E%ROWTYPE;

  CURSOR MONTO_ABD_NETO (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISIN VARCHAR2) IS
    SELECT SUM(MCC_MONTO_ADMON_VALORES) MONTO
    FROM MOVIMIENTOS_CUENTA_CORREDORES
    WHERE MCC_CCC_CLI_PER_NUM_IDEN = P_ID
      AND MCC_CCC_CLI_PER_TID_CODIGO = P_TID
      AND MCC_CCC_NUMERO_CUENTA = P_CTA
      AND MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_MDA_CONSECUTIVO       IS NULL
      AND MCC_FDF_FECHA             IS NOT NULL
      AND MCC_CFC_FUG_ISI_MNEMONICO = P_ISIN
      AND (EXISTS (SELECT 'X'
                   FROM TIPOS_MOVIMIENTO_CORREDORES
                   WHERE TMC_MNEMONICO    = MCC_TMC_MNEMONICO
                     AND TMC_MNEMONICO NOT IN ('MIGDA','MIGEC','MSADV')
                     AND TMC_ANE_MNEMONICO IN ('AV','BI'))
            OR ( MCC_TMC_MNEMONICO        IN ('ABO','CAR')
              AND MCC_CFC_FUG_ISI_MNEMONICO IS NOT NULL))
      AND EXISTS (SELECT 'X'
                  FROM FUNGIBLES
                  WHERE FUG_ISI_MNEMONICO = MCC_CFC_FUG_ISI_MNEMONICO
                  AND FUG_MNEMONICO       = MCC_CFC_FUG_MNEMONICO
                  AND FUG_TIPO            = 'ACC')
      AND NVL(MCC_PAGADO,'N') = 'N';

  CURSOR C_CUENTA
      (P_CLI_PER_NUM_IDEN    VARCHAR2
      ,P_CLI_PER_TID_CODIGO  VARCHAR2
      ,P_NUMERO_CUENTA       VARCHAR2) IS
      SELECT CCC_PER_NUM_IDEN
            ,CCC_PER_TID_CODIGO
            ,PER_SUC_CODIGO
            ,PER_NOMBRE_USUARIO
            ,CCC_SALDO_ADMON_VALORES
      FROM   CUENTAS_CLIENTE_CORREDORES
            ,PERSONAS
      WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
      AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
      AND    CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
      AND    CCC_PER_NUM_IDEN = PER_NUM_IDEN
      AND    CCC_PER_TID_CODIGO = PER_TID_CODIGO;
   CCC1   C_CUENTA%ROWTYPE;

  CURSOR MONTO_MAX_ACH IS
    SELECT CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'LAC';
  V_MONTO_MAX_ACH NUMBER;

  ERRORSQL         VARCHAR2(100);
  V_COMM           NUMBER;
  V_TIPO_PAGO      VARCHAR2(5);
  V_MONTO_ABD      NUMBER;
  V_MONTO_ABD_NETO NUMBER;
  V_MONTO_STR      NUMBER;
  V_MONTO          NUMBER;
  TOTAL_ODP        NUMBER;
BEGIN
  OPEN MONTO_MAX_ACH;
  FETCH MONTO_MAX_ACH INTO V_MONTO_MAX_ACH;
  CLOSE MONTO_MAX_ACH;

  --Se identifican las instrucciones a ejecutar, si el cliente tuvo ABD en el SYSDATE.
  OPEN DIVIDENDOS;
  FETCH DIVIDENDOS INTO DIVIDENDOS_REC;
  WHILE DIVIDENDOS%FOUND LOOP
    P_CLI_PER_NUM_IDEN   := DIVIDENDOS_REC.TIPM_NUM_IDEN;
    P_CLI_PER_TID_CODIGO := DIVIDENDOS_REC.TIPM_TID_CODIGO;
    P_NUMERO_CUENTA      := DIVIDENDOS_REC.TIPM_NUMERO_CUENTA;

    OPEN C_CUENTA(P_CLI_PER_NUM_IDEN
                 ,P_CLI_PER_TID_CODIGO
                 ,P_NUMERO_CUENTA);
    FETCH C_CUENTA INTO CCC1;
    CLOSE C_CUENTA;

    CCC1.CCC_SALDO_ADMON_VALORES := P_ADMON_SALDOS.FN_SALDO_ADMON_VALORES
                                          (P_CLI_NUM_IDEN      => P_CLI_PER_NUM_IDEN
                                          ,P_CLI_TID_CODIGO    => P_CLI_PER_TID_CODIGO
                                          ,P_CUENTA            => P_NUMERO_CUENTA
                                          ,P_SALDO_RECALCULADO => 'N'
                                          ,P_SALDO_ODP         => TOTAL_ODP);

    OPEN INSTRUCCION(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA);
    FETCH INSTRUCCION INTO REC_INSTRUCCION;
    IF INSTRUCCION%FOUND
      AND REC_INSTRUCCION.IPD_TIPO_EMISOR = 'T'
        AND REC_INSTRUCCION.IPD_PAGO = 'S'
          AND REC_INSTRUCCION.IPD_TRASLADO_FONDOS = 'N'
            AND NVL(REC_INSTRUCCION.IPD_INSTRUCCION_POD,'N') = 'N' THEN
      V_MONTO := 0;
      V_MONTO_ABD_NETO := 0;
      OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA);
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      WHILE DIVIDENDOS_X_ISIN%FOUND LOOP
        IF REC_DIVIDENDOS_X_ISIN.ISIN IN ('COB51PA00076','COC04PA00016')
            AND CCC1.PER_SUC_CODIGO = 11
              AND REC_INSTRUCCION.IPD_BAN_CODIGO = 51
                AND REC_INSTRUCCION.IPD_TPA_MNEMONICO = 'TRB' THEN
          V_MONTO := 0;
          V_MONTO_ABD_NETO := 0;
          OPEN MONTO_ABD_NETO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
          FETCH MONTO_ABD_NETO INTO V_MONTO_ABD_NETO;
          CLOSE MONTO_ABD_NETO;

          IF REC_DIVIDENDOS_X_ISIN.ISIN = 'COB51PA00076' THEN
            REC_INSTRUCCION.IPD_TPA_MNEMONICO := 'STR';
          ELSIF REC_DIVIDENDOS_X_ISIN.ISIN = 'COC04PA00016' THEN
            REC_INSTRUCCION.IPD_TPA_MNEMONICO := 'TBP';
          END IF;

          IF NVL(REC_INSTRUCCION.IPD_VISADO,'N') = 'S' THEN
            IF CCC1.CCC_SALDO_ADMON_VALORES = 0 THEN
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = 0
                 ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
                 ,TIPM_ESTADO = 'NTS'
                 ,TIPM_DESCRIPCION = 'NO TIENE SALDO'
                 ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                 ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            ELSE
              IF CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO_ABD_NETO,0) >= 0 THEN
                UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                SET TIPM_MONTO_ODP = V_MONTO_ABD_NETO
                   ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
                   ,TIPM_ESTADO = 'AOK'
                   ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                   ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                   ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                   ,TIPM_TIPO_EMISOR = REC_INSTRUCCION.IPD_TIPO_EMISOR
                WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
              ELSE
                UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                SET TIPM_MONTO_ODP = 0
                   ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
                   ,TIPM_ESTADO = 'SAN'
                   ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                   ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                   ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
              END IF;
            END IF;
          ELSE
            UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
            SET TIPM_MONTO_ODP = 0
               ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
               ,TIPM_ESTADO = 'INV'
               ,TIPM_DESCRIPCION = 'INSTRUCCION NO VISADA'
               ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
               ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
            WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
          END IF;
        ELSE
          V_MONTO_ABD_NETO := 0;
          OPEN MONTO_ABD_NETO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
          FETCH MONTO_ABD_NETO INTO V_MONTO_ABD_NETO;
          CLOSE MONTO_ABD_NETO;
          V_MONTO := V_MONTO + V_MONTO_ABD_NETO;
        END IF;
        FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      END LOOP;
      CLOSE DIVIDENDOS_X_ISIN;
      IF CCC1.CCC_SALDO_ADMON_VALORES = 0
        AND NVL(V_MONTO,0) > 0 THEN
        UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
        SET TIPM_MONTO_ODP = 0
           ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
           ,TIPM_ESTADO = 'NTS'
           ,TIPM_DESCRIPCION = 'NO TIENE SALDO'
           ,TIPM_ISIN = NULL
           ,TIPM_EMISOR = NULL
        WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
      ELSE
        IF NVL(V_MONTO,0) > 0 AND (CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO,0) >= 0) THEN
          IF REC_INSTRUCCION.IPD_TPA_MNEMONICO = 'ACH' AND V_MONTO > V_MONTO_MAX_ACH  THEN
            UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
            SET TIPM_MONTO_ODP = 0
               ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
               ,TIPM_ESTADO = 'MAS'
               ,TIPM_DESCRIPCION = 'MONTO ACH SUPERA EL MAXIMO PERMITIDO'
               ,TIPM_ISIN = NULL
               ,TIPM_EMISOR = NULL
            WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
          ELSE
            IF NVL(REC_INSTRUCCION.IPD_VISADO,'N') = 'S' THEN
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = V_MONTO
                 ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
                 ,TIPM_ESTADO = 'AOK'
                 ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                 ,TIPM_ISIN = NULL
                 ,TIPM_EMISOR = NULL
                 ,TIPM_TIPO_EMISOR = REC_INSTRUCCION.IPD_TIPO_EMISOR
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            ELSE
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = 0
                 ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
                 ,TIPM_ESTADO = 'INV'
                 ,TIPM_DESCRIPCION = 'INSTRUCCION NO VISADA'
                 ,TIPM_ISIN = NULL
                 ,TIPM_EMISOR = NULL
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            END IF;
          END IF;
        ELSE
          UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
          SET TIPM_MONTO_ODP = V_MONTO
             ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION.IPD_TPA_MNEMONICO
             ,TIPM_ESTADO = 'SAN'
             ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
             ,TIPM_ISIN = NULL
             ,TIPM_EMISOR = NULL
          WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
        END IF;
      END IF;
    ELSIF INSTRUCCION%FOUND
      AND REC_INSTRUCCION.IPD_TIPO_EMISOR = 'T'
        AND REC_INSTRUCCION.IPD_PAGO = 'N'
          AND REC_INSTRUCCION.IPD_TRASLADO_FONDOS = 'S'
            AND NVL(REC_INSTRUCCION.IPD_INSTRUCCION_POD,'N') = 'N' THEN
      V_MONTO := 0;
      V_MONTO_ABD_NETO := 0;
      OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA);
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      WHILE DIVIDENDOS_X_ISIN%FOUND LOOP
        V_MONTO_ABD_NETO := 0;
        OPEN MONTO_ABD_NETO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
        FETCH MONTO_ABD_NETO INTO V_MONTO_ABD_NETO;
        CLOSE MONTO_ABD_NETO;
        V_MONTO := V_MONTO + V_MONTO_ABD_NETO;
        FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      END LOOP;
      CLOSE DIVIDENDOS_X_ISIN;
      IF CCC1.CCC_SALDO_ADMON_VALORES = 0 THEN
        UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
        SET TIPM_MONTO_ODP = V_MONTO
           ,TIPM_TPA_MNEMONICO = 'FON'
           ,TIPM_ESTADO = 'NTS'
           ,TIPM_DESCRIPCION = 'NO TIENE SALDO'
           ,TIPM_ISIN = NULL
           ,TIPM_EMISOR = NULL
        WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
      ELSE
        IF NVL(V_MONTO,0) > 0 AND (CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO,0) >= 0) THEN
          IF NVL(REC_INSTRUCCION.IPD_VISADO,'N') = 'S' THEN
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = V_MONTO
                 ,TIPM_TPA_MNEMONICO = 'FON'
                 ,TIPM_ESTADO = 'AOK'
                 ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                 ,TIPM_ISIN = NULL
                 ,TIPM_EMISOR = NULL
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            ELSE
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = 0
                 ,TIPM_TPA_MNEMONICO = 'FON'
                 ,TIPM_ESTADO = 'INV'
                 ,TIPM_DESCRIPCION = 'INSTRUCCION NO VISADA'
                 ,TIPM_ISIN = NULL
                 ,TIPM_EMISOR = NULL
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            END IF;
        ELSE
          UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
          SET TIPM_MONTO_ODP = V_MONTO
             ,TIPM_TPA_MNEMONICO = 'FON'
             ,TIPM_ESTADO = 'SAN'
             ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
             ,TIPM_ISIN = NULL
             ,TIPM_EMISOR = NULL
          WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
        END IF;
      END IF;
    ELSIF INSTRUCCION%FOUND
      AND REC_INSTRUCCION.IPD_TIPO_EMISOR = 'E'
        AND REC_INSTRUCCION.IPD_PAGO = 'S'
          AND REC_INSTRUCCION.IPD_TRASLADO_FONDOS = 'N'
            AND NVL(REC_INSTRUCCION.IPD_INSTRUCCION_POD,'N') = 'N' THEN
      OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA);
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      WHILE DIVIDENDOS_X_ISIN%FOUND LOOP
        OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
        FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
        IF INSTRUCCION_E%FOUND THEN
          IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'TRB'
            AND REC_INSTRUCCION_E.IPD_BAN_CODIGO =  51
              AND REC_DIVIDENDOS_X_ISIN.ISIN IN ('COB51PA00076','COC04PA00016','COC04PA00024','COC04PA00032') THEN
                --AND CCC1.PER_SUC_CODIGO = 11

            IF REC_DIVIDENDOS_X_ISIN.ISIN = 'COB51PA00076' THEN
              REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'STR';
            ELSIF REC_DIVIDENDOS_X_ISIN.ISIN = 'COC04PA00016' THEN
              REC_INSTRUCCION_E.IPD_TPA_MNEMONICO := 'TBP';
            END IF;

          END IF;

          OPEN MONTO_ABD_NETO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
          FETCH MONTO_ABD_NETO INTO V_MONTO_ABD_NETO;
          CLOSE MONTO_ABD_NETO;
          IF CCC1.CCC_SALDO_ADMON_VALORES = 0 THEN
            UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
            SET TIPM_MONTO_ODP = 0
               ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION_E.IPD_TPA_MNEMONICO
               ,TIPM_ESTADO = 'NTS'
               ,TIPM_DESCRIPCION = 'NO TIENE SALDO'
               ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
               ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
            WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
          ELSE
            IF CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO_ABD_NETO,0) >= 0 THEN
              IF REC_INSTRUCCION_E.IPD_TPA_MNEMONICO = 'ACH' AND V_MONTO_ABD_NETO > V_MONTO_MAX_ACH  THEN
                UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                SET TIPM_MONTO_ODP = 0
                   ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION_E.IPD_TPA_MNEMONICO
                   ,TIPM_ESTADO = 'MAS'
                   ,TIPM_DESCRIPCION = 'MONTO ACH SUPERA EL MAXIMO PERMITIDO'
                   ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                   ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
              ELSE
                IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                  UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                  SET TIPM_MONTO_ODP = V_MONTO_ABD_NETO
                     ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION_E.IPD_TPA_MNEMONICO
                     ,TIPM_ESTADO = 'AOK'
                     ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                     ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                     ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                  WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
                ELSE
                  UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                  SET TIPM_MONTO_ODP = 0
                     ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION_E.IPD_TPA_MNEMONICO
                     ,TIPM_ESTADO = 'INV'
                     ,TIPM_DESCRIPCION = 'INSTRUCCION NO VISADA'
                     ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                     ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                  WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
                END IF;
              END IF;
            ELSE
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = 0
                 ,TIPM_TPA_MNEMONICO = REC_INSTRUCCION_E.IPD_TPA_MNEMONICO
                 ,TIPM_ESTADO = 'SAN'
                 ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                 ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                 ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            END IF;
          END IF;
        ELSE
          UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
          SET TIPM_MONTO_ODP = 0
             ,TIPM_TPA_MNEMONICO = NULL
             ,TIPM_ESTADO = 'AOK'
             ,TIPM_DESCRIPCION = 'CLIENTE SIN INSTRUCCION'
             ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
             ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
          WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
        END IF;
        CLOSE INSTRUCCION_E;
        FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      END LOOP;
      CLOSE DIVIDENDOS_X_ISIN;
    ELSIF INSTRUCCION%FOUND
      AND REC_INSTRUCCION.IPD_TIPO_EMISOR = 'E'
        AND REC_INSTRUCCION.IPD_PAGO = 'N'
          AND REC_INSTRUCCION.IPD_TRASLADO_FONDOS = 'S'
            AND NVL(REC_INSTRUCCION.IPD_INSTRUCCION_POD,'N') = 'N' THEN
      OPEN DIVIDENDOS_X_ISIN(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA);
      FETCH DIVIDENDOS_X_ISIN INTO REC_DIVIDENDOS_X_ISIN;
      WHILE DIVIDENDOS_X_ISIN%FOUND LOOP
        OPEN INSTRUCCION_E(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
        FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
        IF INSTRUCCION_E%FOUND THEN
          OPEN MONTO_ABD_NETO(P_CLI_PER_NUM_IDEN, P_CLI_PER_TID_CODIGO, P_NUMERO_CUENTA, REC_DIVIDENDOS_X_ISIN.ISIN);
          FETCH MONTO_ABD_NETO INTO V_MONTO_ABD_NETO;
          CLOSE MONTO_ABD_NETO;
          IF CCC1.CCC_SALDO_ADMON_VALORES = 0 THEN
            UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
            SET TIPM_MONTO_ODP = 0
               ,TIPM_TPA_MNEMONICO = 'FON'
               ,TIPM_ESTADO = 'NTS'
               ,TIPM_DESCRIPCION = 'NO TIENE SALDO'
               ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
               ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
            WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
          ELSE
            IF CCC1.CCC_SALDO_ADMON_VALORES - NVL(V_MONTO_ABD_NETO,0) >= 0 THEN
              IF NVL(REC_INSTRUCCION_E.IPD_VISADO,'N') = 'S' THEN
                UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                SET TIPM_MONTO_ODP = V_MONTO_ABD_NETO
                   ,TIPM_TPA_MNEMONICO = 'FON'
                   ,TIPM_ESTADO = 'AOK'
                   ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                   ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                   ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
              ELSE
                UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
                SET TIPM_MONTO_ODP = 0
                   ,TIPM_TPA_MNEMONICO = 'FON'
                   ,TIPM_ESTADO = 'INV'
                   ,TIPM_DESCRIPCION = 'INSTRUCCION NO VISADA'
                   ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                   ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
                WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
              END IF;
            ELSE
              UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
              SET TIPM_MONTO_ODP = 0
                 ,TIPM_TPA_MNEMONICO = 'FON'
                 ,TIPM_ESTADO = 'SAN'
                 ,TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
                 ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
                 ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
              WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
            END IF;
          END IF;
        ELSE
          UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
          SET TIPM_MONTO_ODP = 0
             ,TIPM_TPA_MNEMONICO = NULL
             ,TIPM_ESTADO = 'AOK'
             ,TIPM_DESCRIPCION = 'CLIENTE SIN INSTRUCCION'
             ,TIPM_ISIN = REC_DIVIDENDOS_X_ISIN.ISIN
             ,TIPM_EMISOR = REC_DIVIDENDOS_X_ISIN.EMISOR
          WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
        END IF;
        CLOSE INSTRUCCION_E;
        FETCH INSTRUCCION_E INTO REC_INSTRUCCION_E;
      END LOOP;
      CLOSE DIVIDENDOS_X_ISIN;
    ELSE
      UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
      SET TIPM_MONTO_ODP = 0
         ,TIPM_TPA_MNEMONICO = NULL
         ,TIPM_ESTADO = 'AOK'
         ,TIPM_DESCRIPCION = 'CLIENTE SIN INSTRUCCION'
         ,TIPM_ISIN = NULL
         ,TIPM_EMISOR = NULL
      WHERE TIPM_CONSECUTIVO = DIVIDENDOS_REC.TIPM_CONSECUTIVO;
    END IF;
    CLOSE INSTRUCCION;
    IF V_COMM = 100 THEN
      COMMIT;
      V_COMM := 0;
    END IF;
    FETCH DIVIDENDOS INTO DIVIDENDOS_REC;
  END LOOP;
  CLOSE DIVIDENDOS;
  COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);
      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS'
                                          ,P_ERROR       => P_CLI_PER_NUM_IDEN||';'||P_CLI_PER_TID_CODIGO||';'||P_NUMERO_CUENTA||';'||'OTROSERRORES'
                                          ,P_TABLA_ERROR => NULL);
END REPROCESO_PAGOS_MASIVOS_DIV;

PROCEDURE PR_PAGOS_MASIVOS_DIV_ECOPETROL IS

   P_CLI_PER_NUM_IDEN          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE;
   P_CLI_PER_TID_CODIGO        CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE;
   P_NUMERO_CUENTA             CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE;

   CURSOR C_TMP_DIV IS
      SELECT MCC_CCC_CLI_PER_NUM_IDEN
            ,MCC_CCC_CLI_PER_TID_CODIGO
            ,MCC_CCC_NUMERO_CUENTA
            ,MCC_CFC_FUG_ISI_MNEMONICO
            ,MONTO_ADMON_VALORES
            ,MONTO_SERVICIO
            ,MONTO_ICA
            ,MONTO_CREE
            ,MONTO_ADI
            ,MONTO_RTEFTE
            ,CCC_SALDO_ADMON_VALORES
            ,FUG_ENA_MNEMONICO
            ,CLI_EXENTO_DXM
            ,PER_SUC_CODIGO
            ,PER_NOMBRE_USUARIO
            ,IPD_EXISTE
            ,IPD_TIPO_EMISOR
            ,IPD_CONSECUTIVO
            ,IPD_TPA_MNEMONICO
            ,IPD_BAN_CODIGO
            ,IPD_VISADO
            ,IPD_PAGO
            ,IPD_TRASLADO_FONDOS
            ,IPD_INSTRUCCION_POD
            ,IPD_PAGAR_A
            ,IPD_CRUCE_CHEQUE
        FROM TMP_DIV_ECOPETROL
	  ORDER BY MCC_CCC_CLI_PER_NUM_IDEN,
             MCC_CCC_CLI_PER_TID_CODIGO,
             MCC_CCC_NUMERO_CUENTA,
             MCC_CFC_FUG_ISI_MNEMONICO;
   R_TMP_DIV C_TMP_DIV%ROWTYPE;

  CURSOR MONTO_MAX_ACH IS
    SELECT CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'LAC';
  V_MONTO_MAX_ACH NUMBER;

  CURSOR MONTO_MAX_POD IS
    SELECT CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'MMP';
  V_MONTO_MAX_POD NUMBER;

  CURSOR C_IBA IS
    SELECT CON_VALOR
    FROM   CONSTANTES
    WHERE  CON_MNEMONICO = 'IBA';


  V_MONTO_ICA   		NUMBER;
  V_MONTO_CREE  		NUMBER;
  V_MONTO_ADI   		NUMBER;
  V_IBA1        		CONSTANTES.CON_VALOR%TYPE:= NULL;
  V_COMM        		NUMBER := 0;
  V_SALDO_ADMON_VALORES NUMBER(22,2);
  V_MONTO				    NUMBER := 0;
  V_MONTO_SERVICIO	NUMBER := 0;
  V_MONTO_ODP       NUMBER := 0;
  V_MONTO_GMF       NUMBER := 0;

  ERRORSQL         VARCHAR2(100);

BEGIN
   DELETE FROM TMP_DIV_ECOPETROL;

   INSERT INTO TMP_DIV_ECOPETROL (
          MCC_CCC_CLI_PER_NUM_IDEN
         ,MCC_CCC_CLI_PER_TID_CODIGO
         ,MCC_CCC_NUMERO_CUENTA
         ,MCC_CFC_FUG_ISI_MNEMONICO
         ,MONTO_ADMON_VALORES
         ,FUG_ENA_MNEMONICO)
   SELECT MCC_CCC_CLI_PER_NUM_IDEN
         ,MCC_CCC_CLI_PER_TID_CODIGO
         ,MCC_CCC_NUMERO_CUENTA
         ,MCC_CFC_FUG_ISI_MNEMONICO
         ,SUM(MCC_MONTO_ADMON_VALORES)
         ,FUG_ENA_MNEMONICO EMISOR
     FROM MOVIMIENTOS_CUENTA_CORREDORES
         ,FUNGIBLES
    WHERE MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND MCC_TMC_MNEMONICO = 'ABD'
      AND MCC_PAGADO IS NULL
      AND MCC_CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
      AND MCC_CFC_FUG_ISI_MNEMONICO IN (SELECT PME_ISIN
                                          FROM PAGOS_MASIVOS_ISIN_ECOPETROL
                                         WHERE PME_FECHA >= TRUNC(SYSDATE-1)
                                           AND PME_FECHA < TRUNC(SYSDATE+1)
                                           AND PME_PAGADO = 'P')
    GROUP BY MCC_CCC_CLI_PER_NUM_IDEN,
             MCC_CCC_CLI_PER_TID_CODIGO,
             MCC_CCC_NUMERO_CUENTA,
             MCC_CFC_FUG_ISI_MNEMONICO,
             FUG_ENA_MNEMONICO;
   COMMIT;

   UPDATE TMP_DIV_ECOPETROL
      SET CLI_EXENTO_DXM = 'N'
         ,IPD_EXISTE = 'N'
         ,IPD_VISADO = 'N'
         ,ISIN = MCC_CFC_FUG_ISI_MNEMONICO
         ,EMISOR = FUG_ENA_MNEMONICO
         ,MONTO_SERVICIO = 0
         ,MONTO_ICA = 0
         ,MONTO_CREE = 0
         ,MONTO_ADI = 0
         ,MONTO_RTEFTE = 0
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,CASO = 0
         ,VERIFICADO = 'N';
   COMMIT;

   -- ACTUALIZANDO EXENTOS
   UPDATE TMP_DIV_ECOPETROL
   SET    CLI_EXENTO_DXM = 'S'
   WHERE (MCC_CCC_CLI_PER_NUM_IDEN,MCC_CCC_CLI_PER_TID_CODIGO) IN (
          SELECT CLI_PER_NUM_IDEN, CLI_PER_TID_CODIGO
	        FROM CLIENTES
	        WHERE NVL(CLI_EXCENTO_DXM_FONDOS,'N')= 'S');


   -- ACTUALIZANDO DATOS DEL COMERCIAL DE LA CUENTA
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
     SELECT CCC_CLI_PER_NUM_IDEN
	         ,CCC_CLI_PER_TID_CODIGO
	         ,CCC_NUMERO_CUENTA
	         ,CCC_PER_NUM_IDEN
	         ,CCC_PER_TID_CODIGO
       FROM CUENTAS_CLIENTE_CORREDORES) CCC
         ON (CCC.CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
        AND CCC.CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
		    AND CCC.CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA)
       WHEN MATCHED THEN UPDATE
        SET TT.CCC_PER_NUM_IDEN = CCC.CCC_PER_NUM_IDEN
           ,TT.CCC_PER_TID_CODIGO = CCC.CCC_PER_TID_CODIGO;
   COMMIT;

   -- ACTUALIZANDO DATOS DE SUCURSAL Y COMERCIAL
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
     SELECT PER_NUM_IDEN
           ,PER_TID_CODIGO
           ,PER_SUC_CODIGO
           ,PER_NOMBRE_USUARIO
       FROM PERSONAS) PP
         ON (PP.PER_NUM_IDEN = TT.CCC_PER_NUM_IDEN
        AND PP.PER_TID_CODIGO = TT.CCC_PER_TID_CODIGO)
       WHEN MATCHED THEN UPDATE
        SET TT.PER_SUC_CODIGO = PP.PER_SUC_CODIGO
           ,TT.PER_NOMBRE_USUARIO = PP.PER_NOMBRE_USUARIO;
   COMMIT;

   -- ACTUALIZANDO LOS DATOS DE INSTRUCCION DE PAGO
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
            ,IPD_CCC_CLI_PER_TID_CODIGO
            ,IPD_CCC_NUMERO_CUENTA
            ,IPD_TIPO_EMISOR
            ,IPD_CONSECUTIVO
            ,IPD_TPA_MNEMONICO
            ,IPD_BAN_CODIGO
            ,IPD_VISADO
            ,IPD_PAGO
            ,IPD_TRASLADO_FONDOS
            ,IPD_INSTRUCCION_POD
            ,IPD_PAGAR_A
            ,IPD_CRUCE_CHEQUE
        FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
       WHERE IPD_ESTADO = 'A'
         AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
         AND  IPD_TIPO_ORIGEN_PAGO = 'DI'
         AND (IPD_TIPO_EMISOR = 'T' OR
             (IPD_TIPO_EMISOR = 'E' AND
		          EXISTS (SELECT 'X'
                      FROM DETALLE_INSTRUCCIONES_PAGOS
                     WHERE DIPA_IPD_CONSECUTIVO = IPD_CONSECUTIVO
                       AND DIPA_FUG_ISI_MNEMONICO IN
				                   (SELECT PME_ISIN
                              FROM PAGOS_MASIVOS_ISIN_ECOPETROL
                             WHERE PME_FECHA >= TRUNC(SYSDATE-1)
                               AND PME_FECHA < TRUNC(SYSDATE+1)
							                 AND PME_PAGADO = 'P'
							             ))))
             ) IPD
          ON (IPD.IPD_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
         AND IPD.IPD_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
         AND IPD.IPD_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA)
        WHEN MATCHED THEN UPDATE
         SET TT.IPD_TIPO_EMISOR = IPD.IPD_TIPO_EMISOR
            ,TT.IPD_CONSECUTIVO = IPD.IPD_CONSECUTIVO
            ,TT.IPD_TPA_MNEMONICO = IPD.IPD_TPA_MNEMONICO
            ,TT.IPD_BAN_CODIGO = IPD.IPD_BAN_CODIGO
            ,TT.IPD_VISADO = IPD.IPD_VISADO
            ,TT.IPD_PAGO = IPD.IPD_PAGO
            ,TT.IPD_TRASLADO_FONDOS = IPD.IPD_TRASLADO_FONDOS
            ,TT.IPD_INSTRUCCION_POD = IPD.IPD_INSTRUCCION_POD
            ,TT.IPD_PAGAR_A = IPD.IPD_PAGAR_A
            ,TT.IPD_CRUCE_CHEQUE = IPD.IPD_CRUCE_CHEQUE
            ,TT.IPD_EXISTE = 'S';
   COMMIT;

   -- ACTUALIZANDO LOS DATOS DE INSTRUCCION DE PAGO
   -- CRUZADA CON EL DETALLE DE INSTRUCCIONES
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT IPD_CCC_CLI_PER_NUM_IDEN
            ,IPD_CCC_CLI_PER_TID_CODIGO
            ,IPD_CCC_NUMERO_CUENTA
            ,IPD_TIPO_EMISOR
            ,IPD_CONSECUTIVO
            ,IPD_TPA_MNEMONICO
            ,IPD_BAN_CODIGO
            ,IPD_VISADO
            ,IPD_PAGO
            ,IPD_TRASLADO_FONDOS
            ,IPD_INSTRUCCION_POD
            ,IPD_PAGAR_A
            ,IPD_CRUCE_CHEQUE
            ,DIPA_FUG_ISI_MNEMONICO
        FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
            ,DETALLE_INSTRUCCIONES_PAGOS
       WHERE IPD_CONSECUTIVO = DIPA_IPD_CONSECUTIVO
	       AND IPD_ESTADO = 'A'
		     AND IPD_TIPO_EMISOR = 'E'
         AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
         AND  IPD_TIPO_ORIGEN_PAGO = 'DI'
		     AND DIPA_FUG_ISI_MNEMONICO IN
				            (SELECT PME_ISIN	-- ** REVISAR TABLA QUE QUEDA Y FECHAS
                       FROM PAGOS_MASIVOS_ISIN_ECOPETROL
                      WHERE PME_FECHA >= TRUNC(SYSDATE-1)
                        AND PME_FECHA < TRUNC(SYSDATE+1)
							 AND PME_PAGADO = 'P')
		         ) IPD
          ON (IPD.IPD_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
         AND IPD.IPD_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
         AND IPD.IPD_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA
		     AND IPD.DIPA_FUG_ISI_MNEMONICO = TT.MCC_CFC_FUG_ISI_MNEMONICO)
        WHEN MATCHED THEN UPDATE
         SET TT.E_IPD_CONSECUTIVO = IPD.IPD_CONSECUTIVO
	          ,TT.E_IPD_TPA_MNEMONICO = IPD.IPD_TPA_MNEMONICO
	          ,TT.E_IPD_BAN_CODIGO = IPD.IPD_BAN_CODIGO
	          ,TT.E_IPD_VISADO = IPD.IPD_VISADO
	          ,TT.E_IPD_EXISTE = 'S';
   COMMIT;

   -- EXTRAYENDO LOS MOVIMIENTOS
   DELETE FROM TMP_MCC_DIV_ECOPETROL;
   INSERT INTO TMP_MCC_DIV_ECOPETROL (
          MCC_CONSECUTIVO
         ,MCC_CCC_CLI_PER_NUM_IDEN
         ,MCC_CCC_CLI_PER_TID_CODIGO
         ,MCC_CCC_NUMERO_CUENTA
         ,MCC_CFC_FUG_ISI_MNEMONICO
         ,MCC_FECHA
         ,MCC_FDF_FECHA
         ,MCC_TMC_MNEMONICO
         ,MCC_MONTO_ADMON_VALORES
         ,MCC_PAGADO
         )
   SELECT MCC_CONSECUTIVO
         ,MCC_CCC_CLI_PER_NUM_IDEN
         ,MCC_CCC_CLI_PER_TID_CODIGO
         ,MCC_CCC_NUMERO_CUENTA
         ,MCC_CFC_FUG_ISI_MNEMONICO
         ,MCC_FECHA
         ,MCC_FDF_FECHA
         ,MCC_TMC_MNEMONICO
         ,MCC_MONTO_ADMON_VALORES
         ,MCC_PAGADO
     FROM MOVIMIENTOS_CUENTA_CORREDORES M1
    WHERE MCC_FECHA >= TRUNC(SYSDATE)
      AND MCC_FECHA < TRUNC(SYSDATE+1)
      AND EXISTS (SELECT 'S'
                    FROM TMP_DIV_ECOPETROL T1
			             WHERE T1.MCC_CCC_CLI_PER_NUM_IDEN = M1.MCC_CCC_CLI_PER_NUM_IDEN
				             AND T1.MCC_CCC_CLI_PER_TID_CODIGO = M1.MCC_CCC_CLI_PER_TID_CODIGO
				             AND T1.MCC_CCC_NUMERO_CUENTA = M1.MCC_CCC_NUMERO_CUENTA
				             AND T1.MCC_CFC_FUG_ISI_MNEMONICO = M1.MCC_CFC_FUG_ISI_MNEMONICO);
   COMMIT;

   -- ACTUALIZANDO MONTO SERVICIO
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
	          ,NVL(SUM(MCC_MONTO_ADMON_VALORES),0) MONTO
        FROM TMP_MCC_DIV_ECOPETROL
       WHERE MCC_TMC_MNEMONICO IN ('SAV','IAV')
         AND NVL(MCC_PAGADO,'N') = 'N'
	       AND MCC_FDF_FECHA IS NOT NULL
	  GROUP BY MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
           ) MOV
	       ON (MOV.MCC_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
	      AND MOV.MCC_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
	      AND MOV.MCC_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA
	      AND MOV.MCC_CFC_FUG_ISI_MNEMONICO = TT.MCC_CFC_FUG_ISI_MNEMONICO)
	     WHEN MATCHED THEN UPDATE
	      SET TT.MONTO_SERVICIO = MOV.MONTO;
   COMMIT;

   -- ACTUALIZANDO IMPUESTOS ICA
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
			      ,NVL(SUM(MCC_MONTO_ADMON_VALORES),0) MONTO
        FROM TMP_MCC_DIV_ECOPETROL
	     WHERE MCC_TMC_MNEMONICO = 'RIC'
         AND MCC_PAGADO IS NULL
	  GROUP BY MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
           ) MOV
	       ON (MOV.MCC_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
	      AND MOV.MCC_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
	      AND MOV.MCC_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA
	      AND MOV.MCC_CFC_FUG_ISI_MNEMONICO = TT.MCC_CFC_FUG_ISI_MNEMONICO)
	     WHEN MATCHED THEN UPDATE
	      SET TT.MONTO_ICA = MOV.MONTO;
   COMMIT;

   -- ACTUALIZANDO IMPUESTOS CREE
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
			      ,NVL(SUM(MCC_MONTO_ADMON_VALORES),0) MONTO
        FROM TMP_MCC_DIV_ECOPETROL
	     WHERE MCC_TMC_MNEMONICO = 'RCR'
         AND MCC_PAGADO IS NULL
	  GROUP BY MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
           ) MOV
	       ON (MOV.MCC_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
	      AND MOV.MCC_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
	      AND MOV.MCC_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA
	      AND MOV.MCC_CFC_FUG_ISI_MNEMONICO = TT.MCC_CFC_FUG_ISI_MNEMONICO)
	     WHEN MATCHED THEN UPDATE
	      SET TT.MONTO_CREE = MOV.MONTO;
   COMMIT;

   -- ACTUALIZANDO IMPUESTOS OTROS
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
			      ,NVL(SUM(MCC_MONTO_ADMON_VALORES),0) MONTO
        FROM TMP_MCC_DIV_ECOPETROL
	     WHERE MCC_TMC_MNEMONICO = 'ADI'
         AND MCC_PAGADO IS NULL
	  GROUP BY MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
           ) MOV
	       ON (MOV.MCC_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
	      AND MOV.MCC_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
	      AND MOV.MCC_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA
	      AND MOV.MCC_CFC_FUG_ISI_MNEMONICO = TT.MCC_CFC_FUG_ISI_MNEMONICO)
	     WHEN MATCHED THEN UPDATE
	      SET TT.MONTO_ADI = MOV.MONTO;
   COMMIT;

   -- ACTUALIZANDO RTE FTE
   MERGE INTO TMP_DIV_ECOPETROL TT
   USING (
      SELECT MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
			      ,NVL(SUM(MCC_MONTO_ADMON_VALORES),0) MONTO
        FROM TMP_MCC_DIV_ECOPETROL
	     WHERE MCC_TMC_MNEMONICO IN ('RCC','RFR','RFD')
         AND MCC_PAGADO IS NULL
	  GROUP BY MCC_CCC_CLI_PER_NUM_IDEN
	          ,MCC_CCC_CLI_PER_TID_CODIGO
	          ,MCC_CCC_NUMERO_CUENTA
	          ,MCC_CFC_FUG_ISI_MNEMONICO
           ) MOV
	       ON (MOV.MCC_CCC_CLI_PER_NUM_IDEN = TT.MCC_CCC_CLI_PER_NUM_IDEN
	      AND MOV.MCC_CCC_CLI_PER_TID_CODIGO = TT.MCC_CCC_CLI_PER_TID_CODIGO
	      AND MOV.MCC_CCC_NUMERO_CUENTA = TT.MCC_CCC_NUMERO_CUENTA
	      AND MOV.MCC_CFC_FUG_ISI_MNEMONICO = TT.MCC_CFC_FUG_ISI_MNEMONICO)
	     WHEN MATCHED THEN UPDATE
	      SET TT.MONTO_ADI = MOV.MONTO;
   COMMIT;

   OPEN MONTO_MAX_ACH;
   FETCH MONTO_MAX_ACH INTO V_MONTO_MAX_ACH;
   CLOSE MONTO_MAX_ACH;

   OPEN MONTO_MAX_POD;
   FETCH MONTO_MAX_POD INTO V_MONTO_MAX_POD;
   CLOSE MONTO_MAX_POD;

   OPEN C_IBA;
   FETCH C_IBA INTO V_IBA1;
   CLOSE C_IBA;
   V_IBA1 := NVL(V_IBA1,0);

   -- CASO 1
   UPDATE TMP_DIV_ECOPETROL
	  SET MONTO_ODP = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
	     ,MONTO_GMF = 0
		   ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                  MCC_CCC_CLI_PER_NUM_IDEN
                                 ,MCC_CCC_CLI_PER_TID_CODIGO
                                 ,MCC_CCC_NUMERO_CUENTA
                                 ,'N')
	     ,CASO = 1
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'T'
	  AND IPD_PAGO = 'S'
	  AND IPD_TRASLADO_FONDOS = 'N'
	  AND IPD_INSTRUCCION_POD = 'N'
	  AND ((IPD_PAGAR_A = 'C' AND
	        IPD_TPA_MNEMONICO IN ('CHE','CHG') AND
		    IPD_CRUCE_CHEQUE IN ('CA')) OR
		   (IPD_PAGAR_A = 'C' AND
            IPD_TPA_MNEMONICO = 'TRB') OR
		   (IPD_PAGAR_A = 'C' AND
            IPD_TPA_MNEMONICO = 'ACH')  OR
		   (NVL(CLI_EXENTO_DXM,'N')='S'));
   COMMIT;

   -- CASO 1
   UPDATE TMP_DIV_ECOPETROL
	  SET MONTO_ODP = ROUND((MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE) / (1 + V_IBA1),2)
	     ,MONTO_GMF = ROUND((ROUND((MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE)/ (1 + V_IBA1),2)) * V_IBA1,2)
		   ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                  MCC_CCC_CLI_PER_NUM_IDEN
                                 ,MCC_CCC_CLI_PER_TID_CODIGO
                                 ,MCC_CCC_NUMERO_CUENTA
                                 ,'N')
	     ,CASO = 1
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'T'
	  AND IPD_PAGO = 'S'
	  AND IPD_TRASLADO_FONDOS = 'N'
	  AND IPD_INSTRUCCION_POD = 'N'
	  AND CASO = 0;
   COMMIT;

   -- CASO 2
   UPDATE TMP_DIV_ECOPETROL
	  SET CASO = 2
	     ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                  MCC_CCC_CLI_PER_NUM_IDEN
                                 ,MCC_CCC_CLI_PER_TID_CODIGO
                                 ,MCC_CCC_NUMERO_CUENTA
                                 ,'N')
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'T'
	  AND IPD_PAGO = 'S'
	  AND IPD_TRASLADO_FONDOS = 'S'
	  AND IPD_INSTRUCCION_POD = 'N'
	  AND CASO = 0;
   COMMIT;

   -- CASO 3
   UPDATE TMP_DIV_ECOPETROL
	  SET MONTO_ODP = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
	     ,MONTO_GMF = 0
		 ,CASO = 3
		 ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                    MCC_CCC_CLI_PER_NUM_IDEN
                                   ,MCC_CCC_CLI_PER_TID_CODIGO
                                   ,MCC_CCC_NUMERO_CUENTA
                                   ,'N')
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'E'
	  AND IPD_PAGO = 'S'
	  AND IPD_TRASLADO_FONDOS = 'N'
	  AND IPD_INSTRUCCION_POD = 'N'
	  AND ((IPD_PAGAR_A = 'C' AND
	        IPD_TPA_MNEMONICO IN ('CHE','CHG') AND
		      IPD_CRUCE_CHEQUE IN ('CA')) OR
		     (IPD_PAGAR_A = 'C' AND
          IPD_TPA_MNEMONICO = 'TRB') OR
		     (IPD_PAGAR_A = 'C' AND
          IPD_TPA_MNEMONICO = 'ACH')  OR
		     (NVL(CLI_EXENTO_DXM,'N')='S'));
   COMMIT;

   -- CASO 3
   UPDATE TMP_DIV_ECOPETROL
	  SET MONTO_ODP = ROUND((MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE) / (1 + V_IBA1),2)
	     ,MONTO_GMF = ROUND((ROUND((MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE)/ (1 + V_IBA1),2)) * V_IBA1,2)
		   ,CASO = 3
		   ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                  MCC_CCC_CLI_PER_NUM_IDEN
                                 ,MCC_CCC_CLI_PER_TID_CODIGO
                                 ,MCC_CCC_NUMERO_CUENTA
                                 ,'N')
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'E'
	  AND IPD_PAGO = 'S'
	  AND IPD_TRASLADO_FONDOS = 'N'
	  AND IPD_INSTRUCCION_POD = 'N'
	  AND CASO = 0;
   COMMIT;

   -- CASO 4
   UPDATE TMP_DIV_ECOPETROL
	  SET CASO = 4
	     ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                  MCC_CCC_CLI_PER_NUM_IDEN
                                 ,MCC_CCC_CLI_PER_TID_CODIGO
                                 ,MCC_CCC_NUMERO_CUENTA
                                 ,'N')
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'E'
	  AND IPD_PAGO = 'N'
	  AND IPD_TRASLADO_FONDOS = 'N'
	  AND IPD_INSTRUCCION_POD = 'S'
	  AND CASO = 0;
   COMMIT;

   -- CASO 5
   UPDATE TMP_DIV_ECOPETROL
	  SET CASO = 5
	     ,CCC_SALDO_ADMON_VALORES = P_ADMON_SALDOS.FN_SALDO_ADMON_DIV_ECOPETROL(
                                  MCC_CCC_CLI_PER_NUM_IDEN
                                 ,MCC_CCC_CLI_PER_TID_CODIGO
                                 ,MCC_CCC_NUMERO_CUENTA
                                 ,'N')
	WHERE IPD_EXISTE = 'S'
	  AND IPD_TIPO_EMISOR = 'E'
	  AND IPD_PAGO = 'N'
	  AND IPD_TRASLADO_FONDOS = 'S'
	  AND IPD_INSTRUCCION_POD = 'N'
	  AND CASO = 0;
   COMMIT;

   -- CASO 6. NO SE REQUIERE CALCULAR SALDO_ADMON_VALORES
   UPDATE TMP_DIV_ECOPETROL
	  SET CASO = 6
	WHERE CASO = 0;
   COMMIT;

   -- ACTUALIZANDO INSTRUCCIONES PARA LOS CASOS 3, 4
   UPDATE TMP_DIV_ECOPETROL
      SET E_IPD_TPA_MNEMONICO = 'TBP'
    WHERE CASO = 3
      AND   NVL(E_IPD_EXISTE,'N') = 'S'
      AND   E_IPD_TPA_MNEMONICO = 'TRB'
      AND   E_IPD_BAN_CODIGO = 51
      AND   PER_SUC_CODIGO = 11
      AND   MCC_CFC_FUG_ISI_MNEMONICO = 'COC04PA00016';

   UPDATE TMP_DIV_ECOPETROL
      SET E_IPD_TPA_MNEMONICO = NULL
    WHERE CASO = 4
      AND NVL(E_IPD_EXISTE,'N') = 'S';

	UPDATE TMP_DIV_ECOPETROL
      SET E_IPD_TPA_MNEMONICO = 'POD'
    WHERE CASO = 4
      AND   NVL(E_IPD_EXISTE,'N') = 'S'
      AND   MCC_CFC_FUG_ISI_MNEMONICO = 'COC04PA00016'
      AND   PER_SUC_CODIGO = 11;
   COMMIT;

   -- ACTUALIZANDO ESTADOS CASO1
   UPDATE TMP_DIV_ECOPETROL
   SET    ESTADO = 'NTS', DESCRIPCION = 'NO TIENE SALDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE  NVL(CCC_SALDO_ADMON_VALORES,0) = 0
     AND  CASO = 1
     AND  NVL(IPD_VISADO,'N') = 'S';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'ALISTAMIENTO OK'
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  NVL(IPD_VISADO,'N') = 'S'
     AND  CASO = 1;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'SAN', DESCRIPCION = 'SALDO ADMON VALORES NEGATIVO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  NVL(IPD_VISADO,'N') = 'S'
     AND  CASO = 1;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'INV', DESCRIPCION = 'INSTRUCCION NO VISADA'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE NVL(IPD_VISADO,'N') = 'N'
      AND CASO = 1;
   COMMIT;

   -- ACTUALIZANDO ESTADOS CASO 2
   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'NTS', DESCRIPCION = 'NO TIENE SALDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = 'FON'
         ,ISIN = NULL
         ,EMISOR = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE NVL(CCC_SALDO_ADMON_VALORES,0) = 0
      AND CASO = 2;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'ALISTAMIENTO OK'
         ,MONTO_ODP = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI+MONTO_RTEFTE
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = 'FON'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
      AND  NVL(IPD_VISADO,'N') = 'S'
      AND  CASO = 2;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'INV', DESCRIPCION = 'INSTRUCCION NO VISADA'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = 'FON'
         ,ISIN = NULL
         ,EMISOR = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  NVL(IPD_VISADO,'N') = 'N'
     AND  CASO = 2;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'SAN', DESCRIPCION = 'SALDO ADMON VALORES NEGATIVO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = 'FON'
         ,ISIN = NULL
         ,EMISOR = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 2;
   COMMIT;

   -- ACTUALIZANDO ESTADOS CASO 3
   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'NTS', DESCRIPCION = 'NO TIENE SALDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = E_IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE NVL(CCC_SALDO_ADMON_VALORES,0) = 0
      AND CASO = 3
      AND NVL(E_IPD_EXISTE,'N') = 'S';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'MAS', DESCRIPCION = 'MONTO ACH SUPERA EL MAXIMO PERMITIDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = E_IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE CASO = 3
      AND NVL(E_IPD_EXISTE,'N') = 'S'
      AND (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
      AND E_IPD_TPA_MNEMONICO = 'ACH'
      AND (MONTO_ADMON_VALORES + MONTO_SERVICIO) > V_MONTO_MAX_ACH;

   -- LOS QUE NO QUEDARON EN MAS Y QUE TIENEN VISADO VAN A AOK
   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'ALISTAMIENTO OK'
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = E_IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE CASO = 3
      AND NVL(E_IPD_EXISTE,'N') = 'S'
      AND (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
      AND VERIFICADO = 'N'
      AND NVL(E_IPD_VISADO,'N') = 'S';

   -- LOS QUE NO QUEDARON EN AOK Y QUE NO TIENEN VISADO VAN A INV
   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'INV', DESCRIPCION = 'INSTRUCCION NO VISADA'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = E_IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE CASO = 3
      AND NVL(E_IPD_EXISTE,'N') = 'S'
      AND (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
      AND NVL(E_IPD_VISADO,'N') = 'N';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'SAN', DESCRIPCION = 'SALDO ADMON VALORES NEGATIVO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = E_IPD_TPA_MNEMONICO
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 3
     AND  NVL(E_IPD_EXISTE,'N') = 'S';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'CLIENTE SIN INSTRUCCION' -- **** REVISAR
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE CASO = 3
      AND NVL(E_IPD_EXISTE,'N') = 'N'
      AND VERIFICADO = 'N';
   COMMIT;

   -- ACTUALIZANDO ESTADOS CASO 4
   UPDATE TMP_DIV_ECOPETROL
   SET ESTADO = 'NTS', DESCRIPCION = 'NO TIENE SALDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE NVL(CCC_SALDO_ADMON_VALORES,0) = 0
      AND CASO = 4
      AND NVL(E_IPD_EXISTE,'N') = 'S'
      AND E_IPD_TPA_MNEMONICO = 'POD';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'ALISTAMIENTO OK'
         ,MONTO_ODP = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  CASO = 4
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  E_IPD_TPA_MNEMONICO = 'POD'
     AND  NVL(E_IPD_VISADO,'N') = 'S'
     AND  (MONTO_ADMON_VALORES + MONTO_SERVICIO) < V_MONTO_MAX_POD;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'MPS', DESCRIPCION = 'MONTO POD SUPERA EL MAXIMO PERMITIDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  CASO = 4
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  E_IPD_TPA_MNEMONICO = 'POD'
     AND  NVL(E_IPD_VISADO,'N') = 'S'
     AND (MONTO_ADMON_VALORES + MONTO_SERVICIO) >= V_MONTO_MAX_POD;

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'INV', DESCRIPCION = 'INSTRUCCION NO VISADA'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  CASO = 4
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  E_IPD_TPA_MNEMONICO = 'POD'
     AND  NVL(E_IPD_VISADO,'N') = 'N';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'SAN', DESCRIPCION = 'SALDO ADMON VALORES NEGATIVO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 4
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  E_IPD_TPA_MNEMONICO = 'POD'
     AND  NVL(E_IPD_VISADO,'N') = 'N';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'CIN', DESCRIPCION = 'CLIENTE CON INSTRUCCION POD QUE NO ES DE BP'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 4
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  NVL(E_IPD_TPA_MNEMONICO,' ') != 'POD';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'CLIENTE SIN INSTRUCCION'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = NULL
         ,TPA_MNEMONICO = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 4
     AND  NVL(E_IPD_EXISTE,'N') = 'N';
   COMMIT;

  -- ACTUALIZA ESTADOS DEL CASO 5
    UPDATE TMP_DIV_ECOPETROL
       SET ESTADO = 'NTS', DESCRIPCION = 'NO TIENE SALDO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'FON'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE NVL(CCC_SALDO_ADMON_VALORES,0) = 0
      AND CASO = 5
      AND NVL(E_IPD_EXISTE,'N') = 'S';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'ALISTAMIENTO OK'
         ,MONTO_ODP = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'FON'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  CASO = 5
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  NVL(E_IPD_VISADO,'N') = 'S';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'INV', DESCRIPCION = 'INSTRUCCION NO VISADA'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = E_IPD_CONSECUTIVO
         ,TPA_MNEMONICO = 'POD'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) >= 0
     AND  CASO = 5
     AND  NVL(E_IPD_EXISTE,'N') = 'S'
     AND  NVL(E_IPD_VISADO,'N') = 'N';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'SAN', DESCRIPCION = 'SALDO ADMON VALORES NEGATIVO'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,TPA_MNEMONICO = 'FON'
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 5
     AND  NVL(E_IPD_EXISTE,'N') = 'S';

   UPDATE TMP_DIV_ECOPETROL
      SET ESTADO = 'AOK', DESCRIPCION = 'CLIENTE SIN INSTRUCCION'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = NULL
         ,TPA_MNEMONICO = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
   WHERE (CCC_SALDO_ADMON_VALORES - (MONTO_ADMON_VALORES + MONTO_SERVICIO)) < 0
     AND  CASO = 5
     AND  NVL(E_IPD_EXISTE,'N') = 'N';
   COMMIT;

  -- ACTUALIZA ESTADOS DEL CASO 6
  UPDATE TMP_DIV_ECOPETROL
     SET ESTADO = 'AOK', DESCRIPCION = 'CLIENTE SIN INSTRUCCION'
         ,MONTO_ODP = 0
         ,MONTO_GMF = 0
         ,PROCESADO = 'N'
         ,VERIFICADO = 'S'
         ,IPD_CONSECUTIVO = NULL
         ,TPA_MNEMONICO = NULL
         ,MONTO_ABD = MONTO_ADMON_VALORES
         ,MONTO_ABD_NETO = MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
    WHERE CASO = 6;


   INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO
                  (TIPM_CONSECUTIVO
                  ,TIPM_ORIGEN_CLIENTE
                  ,TIPM_FECHA
                  ,TIPM_NUM_IDEN
                  ,TIPM_TID_CODIGO
                  ,TIPM_NUMERO_CUENTA
                  ,TIPM_IPD_CONSECUTIVO
                  ,TIPM_NUM_IDEN_COMER
                  ,TIPM_TID_CODIGO_COMER
                  ,TIPM_USUARIO_COMER
                  ,TIPM_MONTO_ODP
                  ,TIPM_MONTO_GMF
                  ,TIPM_PROCESADO
                  ,TIPM_TPA_MNEMONICO
                  ,TIPM_MONTO_ABD
                  ,TIPM_MONTO_SERVICIO
                  ,TIPM_MONTO_ABD_NETO
                  ,TIPM_ESTADO
                  ,TIPM_DESCRIPCION
                  ,TIPM_ISIN
                  ,TIPM_EMISOR
				          ,TIPM_TIPO_EMISOR
                  ,TIPM_IMPUESTO_ICA
                  ,TIPM_IMPUESTO_CREE
                  ,TIPM_OTROS_IMPUESTOS
                  ,TIPM_RETEFUENTE
                  ,TIPM_FUENTE
                  )
   SELECT TIPM_SEQ.NEXTVAL
         ,TMPDIV.*
     FROM (SELECT DECODE(PER_SUC_CODIGO,11,'DAV','COR')
                  ,SYSDATE
                  ,MCC_CCC_CLI_PER_NUM_IDEN
                  ,MCC_CCC_CLI_PER_TID_CODIGO
                  ,MCC_CCC_NUMERO_CUENTA
                  ,IPD_CONSECUTIVO
                  ,CCC_PER_NUM_IDEN
                  ,CCC_PER_TID_CODIGO
                  ,PER_NOMBRE_USUARIO
                  ,MONTO_ODP
                  ,MONTO_GMF
                  ,PROCESADO
                  ,TPA_MNEMONICO
                  ,MONTO_ADMON_VALORES
                  ,MONTO_SERVICIO
                  ,MONTO_ADMON_VALORES + MONTO_SERVICIO + MONTO_ICA + MONTO_CREE + MONTO_ADI + MONTO_RTEFTE
                  ,ESTADO
                  ,DESCRIPCION
                  ,MCC_CFC_FUG_ISI_MNEMONICO
                  ,EMISOR
                  ,IPD_TIPO_EMISOR
                  ,MONTO_ICA
                  ,MONTO_CREE
                  ,MONTO_ADI
                  ,MONTO_RTEFTE
                  ,'ECO'		-- PARA DIFERENCIAR QUE VIENE POR ECOPETROL
            FROM   TMP_DIV_ECOPETROL) TMPDIV;

     UPDATE MOVIMIENTOS_CUENTA_CORREDORES MCC
        SET MCC_PAGADO = 'N'
      WHERE MCC_FECHA >= TRUNC(SYSDATE)
        AND MCC_FECHA < TRUNC(SYSDATE+1)
        AND MCC_TMC_MNEMONICO = 'ABD'
        AND MCC_PAGADO IS NULL
		AND EXISTS (
		    SELECT 'S'
			  FROM TMP_DIV_ECOPETROL TMP
			 WHERE TMP.MCC_CCC_CLI_PER_NUM_IDEN = MCC.MCC_CCC_CLI_PER_NUM_IDEN
			   AND TMP.MCC_CCC_CLI_PER_TID_CODIGO = MCC.MCC_CCC_CLI_PER_TID_CODIGO
			   AND TMP.MCC_CCC_NUMERO_CUENTA = MCC.MCC_CCC_NUMERO_CUENTA
			   AND TMP.MCC_CFC_FUG_ISI_MNEMONICO = MCC.MCC_CFC_FUG_ISI_MNEMONICO);
  COMMIT;

  EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);

      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PAGOS MASIVOS'
                                          ,P_ERROR       => P_CLI_PER_NUM_IDEN||';'||P_CLI_PER_TID_CODIGO||';'||P_NUMERO_CUENTA||';'||'OTROSERRORES'||sqlerrm
                                          ,P_TABLA_ERROR => NULL);

END PR_PAGOS_MASIVOS_DIV_ECOPETROL;

PROCEDURE PR_PAMADI_AJUMAN IS

  CURSOR C_MOV_AJUMAN  IS
    WITH P_IS AS (SELECT PMI_ISIN
                    FROM PAGOS_MASIVOS_ISIN
                   WHERE PMI_FECHA >= TRUNC(SYSDATE)
                     AND PMI_FECHA < TRUNC(SYSDATE+1)
                     AND PMI_PAGADO = 'P')
    SELECT /*+ APPEND */ MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC.MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO
    FROM  MOVIMIENTOS_CUENTA_CORREDORES MCC, AJUSTES_CLIENTES ACL, P_IS
    ,PERSONAS PER, CUENTAS_CLIENTE_CORREDORES CCC
    WHERE MCC.MCC_ACL_CONSECUTIVO = ACL.ACL_CONSECUTIVO
    AND  PER.PER_NUM_IDEN = CCC.CCC_PER_NUM_IDEN
    AND  PER.PER_TID_CODIGO = CCC.CCC_PER_TID_CODIGO
    AND  CCC.CCC_CLI_PER_NUM_IDEN = MCC.MCC_CCC_CLI_PER_NUM_IDEN
    AND  CCC.CCC_CLI_PER_TID_CODIGO = MCC.MCC_CCC_CLI_PER_TID_CODIGO
    AND   CCC_NUMERO_CUENTA = MCC.MCC_CCC_NUMERO_CUENTA
    AND   MCC.MCC_SUC_CODIGO = ACL.ACL_SUC_CODIGO
    AND   MCC.MCC_NEG_CONSECUTIVO = ACL.ACL_NEG_CONSECUTIVO
    AND   MCC.MCC_FECHA >= TRUNC(SYSDATE)
    AND   MCC.MCC_FECHA < TRUNC(SYSDATE+1)
    AND   MCC.MCC_PAGADO IS NULL
    AND   MCC_CFC_FUG_ISI_MNEMONICO IN (P_IS.PMI_ISIN)
    AND   ACL.ACL_CAJ_MNEMONICO IN (SELECT CAJ_MNEMONICO
                                    FROM CONCEPTOS_AJUSTES
                                    WHERE CAJ_TIPO_SALDO = 'ADVAL')
    GROUP BY  MCC.MCC_CCC_CLI_PER_NUM_IDEN
              ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
              ,MCC.MCC_CCC_NUMERO_CUENTA
              ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
              ,MCC.MCC_CFC_FUG_MNEMONICO
              ,MCC.MCC_CFC_CUENTA_DECEVAL
              ,MCC.MCC_FAV_CONSECUTIVO
              ,PER.PER_SUC_CODIGO
              ,PER.PER_NOMBRE_USUARIO;

    V_REG             C_MOV_AJUMAN%ROWTYPE;

  CURSOR P_TIPM (P_PER_NUM_IDEN VARCHAR2, P_PER_TID_CODIGO VARCHAR2, P_CCC_NUMERO_CUENTA NUMBER, P_FUG_ISI_MNEMONICO VARCHAR2 ) IS
    SELECT /*+ APPEND */ ROWID RID
    FROM TMP_INSTRUCCIONES_PAGOS_MASIVO
    WHERE TIPM_ORIGEN_CLIENTE IN ('COR','DAV')
    AND TIPM_PROCESADO = 'N'
    AND TIPM_FECHA >= TRUNC(SYSDATE)
    AND TIPM_FECHA < TRUNC(SYSDATE)+1
    AND TIPM_TIPO_EMISOR IN ('E','T')
    AND TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
    AND TIPM_NUM_IDEN = P_PER_NUM_IDEN
    AND TIPM_TID_CODIGO = P_PER_TID_CODIGO
    AND TIPM_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
    AND TIPM_ISIN = P_FUG_ISI_MNEMONICO;

  V_TIPM            P_TIPM%ROWTYPE;

  CURSOR C_SUCURSAL (XNIT VARCHAR2, XTIPO VARCHAR2, XCTA NUMBER) IS
      SELECT PER_SUC_CODIGO
            ,PER_NOMBRE_USUARIO
      FROM   PERSONAS
            ,CUENTAS_CLIENTE_CORREDORES
      WHERE  PER_NUM_IDEN = CCC_PER_NUM_IDEN
      AND    PER_TID_CODIGO = CCC_PER_TID_CODIGO
      AND    CCC_CLI_PER_NUM_IDEN = XNIT
      AND    CCC_CLI_PER_TID_CODIGO = XTIPO
      AND    CCC_NUMERO_CUENTA = XCTA;
   SUC1   C_SUCURSAL%ROWTYPE;

   -- INSTRUCCIONES DE PAGO ACTIVAS DE ORIGEN DE PAGO "DIVIDENDOS"
  CURSOR INSTRUCCION (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISI VARCHAR2) IS
    SELECT /*+ APPEND */ IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
          ,IPD_INSTRUCCION_POD
          ,IPD_PAGAR_A
          ,IPD_CRUCE_CHEQUE
    FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
    WHERE IPD_CCC_CLI_PER_NUM_IDEN = P_ID
      AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
      AND IPD_CCC_NUMERO_CUENTA = P_CTA
      AND IPD_ESTADO = 'A'
      AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
      AND IPD_TIPO_ORIGEN_PAGO IN ('DI', 'SD')
      AND (IPD_TIPO_EMISOR = 'T' OR
          (IPD_TIPO_EMISOR = 'E' AND EXISTS (SELECT 'X'
                                             FROM DETALLE_INSTRUCCIONES_PAGOS
                                             WHERE DIPA_IPD_CONSECUTIVO = IPD_CONSECUTIVO
                                             AND DIPA_FUG_ISI_MNEMONICO = P_ISI)));
  REC_INSTRUCCION INSTRUCCION%ROWTYPE;

  -- MONTO EN PESOS MAXIMO PAGO ACH
  CURSOR MONTO_MAX_ACH IS
    SELECT /*+ APPEND */ CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'LAC';
  V_MONTO_MAX_ACH NUMBER;

  -- MONTO MAXIMO PAGO POD
  CURSOR MONTO_MAX_POD IS
    SELECT /*+ APPEND */ CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'MMP';
  V_MONTO_MAX_POD NUMBER;

  -- CONTRIBUCION DEC. No 2331/98 --> 0,004
  CURSOR C_IBA IS
    SELECT /*+ APPEND */ CON_VALOR
    FROM   CONSTANTES
    WHERE  CON_MNEMONICO = 'IBA';

    V_IBA1           CONSTANTES.CON_VALOR%TYPE:= NULL;


  CURSOR C_CLIENTE (P_ISIN VARCHAR2, P_FUG_MNEMONICO NUMBER, P_CFC_CUENTA_DECEVAL NUMBER) IS
    SELECT CLI_EXCENTO_DXM_FONDOS
    FROM   PERSONAS
          ,CLIENTES
          ,CUENTAS_FUNGIBLE_CLIENTE
    WHERE  PER_NUM_IDEN           = CLI_PER_NUM_IDEN
    AND    PER_TID_CODIGO         = CLI_PER_TID_CODIGO
    AND    CLI_PER_NUM_IDEN       = CFC_CCC_CLI_PER_NUM_IDEN
    AND    CLI_PER_TID_CODIGO     = CFC_CCC_CLI_PER_TID_CODIGO
    AND    CFC_FUG_ISI_MNEMONICO  = P_ISIN
    AND    CFC_FUG_MNEMONICO      = P_FUG_MNEMONICO
    AND    CFC_CUENTA_DECEVAL     = P_CFC_CUENTA_DECEVAL;

   CLI1   C_CLIENTE%ROWTYPE;

   CURSOR C_ESTADO_CUENTA (P_PER_NUM_IDEN IN VARCHAR2, P_PER_TID_CODIGO IN VARCHAR2, P_NUMERO_CUENTA IN NUMBER) IS
    SELECT CCC_CUENTA_ACTIVA
          ,CCC_PER_NUM_IDEN
          ,CCC_PER_TID_CODIGO
    FROM  CUENTAS_CLIENTE_CORREDORES
    WHERE CCC_CLI_PER_NUM_IDEN    = P_PER_NUM_IDEN
    AND   CCC_CLI_PER_TID_CODIGO  = P_PER_TID_CODIGO
    AND   CCC_NUMERO_CUENTA       = P_NUMERO_CUENTA;
  CCC1   C_ESTADO_CUENTA%ROWTYPE;

  CURSOR C_HIST (P_ISIN IN VARCHAR2) IS
    SELECT ROWID RID
    FROM HISTORICO_CAPADV HCD
    WHERE HCD.HCD_MNEMONICO = (SELECT MAX(HCDN.HCD_MNEMONICO)
                                  FROM HISTORICO_CAPADV HCDN
                                  WHERE HCDN.HCD_ISIN = HCD.HCD_ISIN )
    AND TRUNC(HCD.HCD_FECHA_CARGUE) = TRUNC(SYSDATE)
    AND HCD.HCD_ISIN = P_ISIN;
  V_RID             VARCHAR2 (512);

  V_COMM            NUMBER := 0;
  ERRORSQL          VARCHAR2(2000);

  V_TDD_IPD_TIPO_EMISOR         TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TIPO_EMISOR%TYPE;
  V_TDD_IPD_CONSECUTIVO         TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_CONSECUTIVO%TYPE;
  V_TDD_IPD_TPA_MNEMONICO       TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TPA_MNEMONICO%TYPE;
  V_TDD_IPD_BAN_CODIGO          TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_BAN_CODIGO%TYPE;
  V_TDD_IPD_VISADO              TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_VISADO%TYPE;
  V_TDD_IPD_PAGO                TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_PAGO%TYPE;
  V_TDD_IPD_TRASLADO_FONDOS     TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TRASLADO_FONDOS%TYPE;
  V_TDD_IPD_INSTRUCCION_POD     TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_INSTRUCCION_POD%TYPE;
  V_TDD_IPD_PAGAR_A             TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_PAGAR_A%TYPE;
  V_TDD_IPD_CRUCE_CHEQUE        TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_CRUCE_CHEQUE%TYPE;
  V_TDD_CCC_PER_NUM_IDEN        TMP_PAGOS_DEPOSITOS_DCVAL.TDD_CCC_PER_NUM_IDEN%TYPE;
  V_TDD_CCC_PER_TID_CODIGO      TMP_PAGOS_DEPOSITOS_DCVAL.TDD_CCC_PER_TID_CODIGO%TYPE;
  V_TDD_CLI_EXCENTO_DXM         TMP_PAGOS_DEPOSITOS_DCVAL.TDD_CLI_EXCENTO_DXM%TYPE;
  V_FAV_CONSECUTIVO             FACTURAS_ADMON_VALORES.FAV_CONSECUTIVO%TYPE;

  V_ISIN                        VARCHAR2(30);

  TYPE O_CURSOR IS REF CURSOR;
  C_CURSOR O_CURSOR;
  V_SELECT VARCHAR2(4000);
BEGIN
  V_SELECT := 'WITH P_IS AS (SELECT PMI_ISIN
                    FROM PAGOS_MASIVOS_ISIN
                   WHERE PMI_FECHA >= TRUNC(SYSDATE)
                     AND PMI_FECHA < TRUNC(SYSDATE+1)
                     AND PMI_PAGADO = ''P'')
    SELECT /*+ APPEND */ MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC.MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO
    FROM  MOVIMIENTOS_CUENTA_CORREDORES MCC, AJUSTES_CLIENTES ACL, P_IS
    ,PERSONAS PER, CUENTAS_CLIENTE_CORREDORES CCC
    WHERE MCC.MCC_ACL_CONSECUTIVO = ACL.ACL_CONSECUTIVO
    AND  PER.PER_NUM_IDEN = CCC.CCC_PER_NUM_IDEN
    AND  PER.PER_TID_CODIGO = CCC.CCC_PER_TID_CODIGO
    AND  CCC.CCC_CLI_PER_NUM_IDEN = MCC.MCC_CCC_CLI_PER_NUM_IDEN
    AND  CCC.CCC_CLI_PER_TID_CODIGO = MCC.MCC_CCC_CLI_PER_TID_CODIGO
    AND   CCC_NUMERO_CUENTA = MCC.MCC_CCC_NUMERO_CUENTA
    AND   MCC.MCC_SUC_CODIGO = ACL.ACL_SUC_CODIGO
    AND   MCC.MCC_NEG_CONSECUTIVO = ACL.ACL_NEG_CONSECUTIVO
    AND   MCC.MCC_FECHA >= TRUNC(SYSDATE)
    AND   MCC.MCC_FECHA < TRUNC(SYSDATE+1)
    AND   MCC.MCC_PAGADO IS NULL
    AND   MCC_CFC_FUG_ISI_MNEMONICO IN (P_IS.PMI_ISIN)
    AND   ACL.ACL_CAJ_MNEMONICO IN (SELECT CAJ_MNEMONICO
                                    FROM CONCEPTOS_AJUSTES
                                    WHERE CAJ_TIPO_SALDO = ''ADVAL'')
GROUP BY  MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO';
  V_COMM := 0;

  C_CURSOR  := NULL;
  V_REG     := NULL;
  OPEN C_CURSOR FOR V_SELECT;
  LOOP
  FETCH C_CURSOR INTO V_REG.MCC_CCC_CLI_PER_NUM_IDEN
                      ,V_REG.MCC_CCC_CLI_PER_TID_CODIGO
                      ,V_REG.MCC_CCC_NUMERO_CUENTA
                      ,V_REG.MONTO
                      ,V_REG.MCC_CFC_FUG_ISI_MNEMONICO
                      ,V_REG.MCC_CFC_FUG_MNEMONICO
                      ,V_REG.MCC_CFC_CUENTA_DECEVAL
                      ,V_REG.MCC_FAV_CONSECUTIVO
                      ,V_REG.PER_SUC_CODIGO
                      ,V_REG.PER_NOMBRE_USUARIO;
  EXIT WHEN C_CURSOR%NOTFOUND;
    V_COMM := V_COMM + 1;
    OPEN P_TIPM (V_REG.MCC_CCC_CLI_PER_NUM_IDEN, V_REG.MCC_CCC_CLI_PER_TID_CODIGO, V_REG.MCC_CCC_NUMERO_CUENTA, V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
    FETCH P_TIPM INTO V_TIPM;
    IF P_TIPM%FOUND THEN
      UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
      SET TIPM_MONTO_ODP = TIPM_MONTO_ODP + V_REG.MONTO
      WHERE ROWID = V_TIPM.RID;
    ELSIF P_TIPM%NOTFOUND THEN
      --
      V_TDD_IPD_TIPO_EMISOR     := NULL;
      V_TDD_IPD_CONSECUTIVO     := NULL;
      V_TDD_IPD_TPA_MNEMONICO   := NULL;
      V_TDD_IPD_BAN_CODIGO      := NULL;
      V_TDD_IPD_VISADO          := NULL;
      V_TDD_IPD_PAGO            := NULL;
      V_TDD_IPD_TRASLADO_FONDOS := NULL;
      V_TDD_IPD_INSTRUCCION_POD := NULL;
      V_TDD_IPD_PAGAR_A         := NULL;
      V_TDD_IPD_CRUCE_CHEQUE    := NULL;
      OPEN INSTRUCCION(V_REG.MCC_CCC_CLI_PER_NUM_IDEN, V_REG.MCC_CCC_CLI_PER_TID_CODIGO, V_REG.MCC_CCC_NUMERO_CUENTA, V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
      FETCH INSTRUCCION INTO REC_INSTRUCCION;
        IF INSTRUCCION%FOUND THEN
          V_TDD_IPD_TIPO_EMISOR     := REC_INSTRUCCION.IPD_TIPO_EMISOR;
          V_TDD_IPD_CONSECUTIVO     := REC_INSTRUCCION.IPD_CONSECUTIVO;
          V_TDD_IPD_TPA_MNEMONICO   := REC_INSTRUCCION.IPD_TPA_MNEMONICO;
          V_TDD_IPD_BAN_CODIGO      := REC_INSTRUCCION.IPD_BAN_CODIGO;
          V_TDD_IPD_VISADO          := REC_INSTRUCCION.IPD_VISADO;
          V_TDD_IPD_PAGO            := REC_INSTRUCCION.IPD_PAGO;
          V_TDD_IPD_TRASLADO_FONDOS := REC_INSTRUCCION.IPD_TRASLADO_FONDOS;
          V_TDD_IPD_INSTRUCCION_POD := REC_INSTRUCCION.IPD_INSTRUCCION_POD;
          V_TDD_IPD_PAGAR_A         := REC_INSTRUCCION.IPD_PAGAR_A;
          V_TDD_IPD_CRUCE_CHEQUE    := REC_INSTRUCCION.IPD_CRUCE_CHEQUE;
        ELSIF INSTRUCCION%NOTFOUND THEN
          V_TDD_IPD_TIPO_EMISOR     := NULL;
          V_TDD_IPD_CONSECUTIVO     := NULL;
          V_TDD_IPD_TPA_MNEMONICO   := NULL;
          V_TDD_IPD_BAN_CODIGO      := NULL;
          V_TDD_IPD_VISADO          := NULL;
          V_TDD_IPD_PAGO            := NULL;
          V_TDD_IPD_TRASLADO_FONDOS := NULL;
          V_TDD_IPD_INSTRUCCION_POD := NULL;
          V_TDD_IPD_PAGAR_A         := NULL;
          V_TDD_IPD_CRUCE_CHEQUE    := NULL;
        END IF;
      CLOSE INSTRUCCION;

      OPEN MONTO_MAX_ACH;
      FETCH MONTO_MAX_ACH INTO V_MONTO_MAX_ACH;
      CLOSE MONTO_MAX_ACH;


      OPEN MONTO_MAX_POD;
      FETCH MONTO_MAX_POD INTO V_MONTO_MAX_POD;
      CLOSE MONTO_MAX_POD;

      OPEN C_IBA;
      FETCH C_IBA INTO V_IBA1;
      CLOSE C_IBA;
      V_IBA1 := NVL(V_IBA1,0);

      OPEN C_ESTADO_CUENTA (V_REG.MCC_CCC_CLI_PER_NUM_IDEN, V_REG.MCC_CCC_CLI_PER_TID_CODIGO, V_REG.MCC_CCC_NUMERO_CUENTA);
      FETCH C_ESTADO_CUENTA INTO CCC1;
      CLOSE C_ESTADO_CUENTA;
      V_TDD_CCC_PER_NUM_IDEN    := CCC1.CCC_PER_NUM_IDEN;
      V_TDD_CCC_PER_TID_CODIGO  := CCC1.CCC_PER_TID_CODIGO;

      OPEN C_CLIENTE (V_REG.MCC_CFC_FUG_ISI_MNEMONICO, V_REG.MCC_CFC_FUG_MNEMONICO, V_REG.MCC_CFC_CUENTA_DECEVAL);
      FETCH C_CLIENTE INTO CLI1;
      CLOSE C_CLIENTE;
      V_TDD_CLI_EXCENTO_DXM := CLI1.CLI_EXCENTO_DXM_FONDOS;

      V_RID := NULL;
      OPEN C_HIST (V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
      FETCH C_HIST INTO V_RID;
      CLOSE C_HIST;

      IF V_RID IS NOT NULL THEN
        UPDATE HISTORICO_CAPADV HCD
        SET HCD.HCD_CANTIDAD = HCD.HCD_CANTIDAD + 1, HCD.HCD_MONTO = HCD.HCD_MONTO + V_REG.MONTO
        WHERE ROWID = V_RID;
      END IF;
     --
      IF V_ISIN IS NULL OR V_ISIN != V_REG.MCC_CFC_FUG_ISI_MNEMONICO THEN
        P_PROCESO.PR_PROCESO_PAGOS_DIVIDENDOS ('ABO',V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
        V_ISIN := V_REG.MCC_CFC_FUG_ISI_MNEMONICO;
      END IF;
      --
      V_FAV_CONSECUTIVO := V_REG.MCC_FAV_CONSECUTIVO;
      P_PAGOS_DIVIDENDOS.PROCESO_PAGOS_MASIVOS_DIV (/*V_REG.MCC_CONSECUTIVO*/NULL
                                                    ,V_REG.MCC_CCC_CLI_PER_NUM_IDEN
                                                    ,V_REG.MCC_CCC_CLI_PER_TID_CODIGO
                                                    ,V_REG.MCC_CCC_NUMERO_CUENTA
                                                    ,V_REG.MCC_CFC_FUG_ISI_MNEMONICO
                                                    ,V_TDD_CLI_EXCENTO_DXM
                                                    ,V_TDD_IPD_TIPO_EMISOR
                                                    ,V_TDD_IPD_CONSECUTIVO
                                                    ,V_TDD_IPD_TPA_MNEMONICO
                                                    ,V_TDD_IPD_BAN_CODIGO
                                                    ,V_TDD_IPD_VISADO
                                                    ,V_TDD_IPD_PAGO
                                                    ,V_TDD_IPD_TRASLADO_FONDOS
                                                    ,V_TDD_IPD_INSTRUCCION_POD
                                                    ,V_TDD_IPD_PAGAR_A
                                                    ,V_TDD_IPD_CRUCE_CHEQUE
                                                    ,V_MONTO_MAX_POD
                                                    ,V_MONTO_MAX_ACH
                                                    ,V_IBA1
                                                    ,V_REG.PER_SUC_CODIGO
                                                    ,V_REG.PER_NOMBRE_USUARIO
                                                    ,V_TDD_CCC_PER_NUM_IDEN
                                                    ,V_TDD_CCC_PER_TID_CODIGO
                                                    ,V_FAV_CONSECUTIVO);
      --
    END IF;
    CLOSE P_TIPM;

    DELETE PAGOS_DEPOSITOS_DCVAL_NO
    WHERE PDD_FUNGIBLE = V_REG.MCC_CFC_FUG_MNEMONICO
    AND PDD_ISIN = V_REG.MCC_CFC_FUG_ISI_MNEMONICO
    AND PDD_CUENTA_DCVAL =  V_REG.MCC_CFC_CUENTA_DECEVAL;
    COMMIT;

  END LOOP;

  CLOSE C_CURSOR;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);

      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PR_PAMADI_AJUMAN'
                                          ,P_ERROR       => 'ERROR '||sqlerrm
                                          ,P_TABLA_ERROR => NULL);
END PR_PAMADI_AJUMAN;

PROCEDURE PR_PAMADI_AJUMAN (P_PROCESO_M IN VARCHAR2) IS

    CURSOR C_MOV_AJUMAN  IS
    WITH P_IS AS (SELECT PMI_ISIN
                    FROM PAGOS_MASIVOS_ISIN
                   WHERE PMI_FECHA >= TRUNC(SYSDATE)
                     AND PMI_FECHA < TRUNC(SYSDATE+1)
                     AND PMI_PAGADO = 'P')
    SELECT /*+ APPEND */ MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC.MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO
    FROM  MOVIMIENTOS_CUENTA_CORREDORES MCC, AJUSTES_CLIENTES ACL, P_IS
    ,PERSONAS PER, CUENTAS_CLIENTE_CORREDORES CCC
    WHERE MCC.MCC_ACL_CONSECUTIVO = ACL.ACL_CONSECUTIVO
    AND  PER.PER_NUM_IDEN = CCC.CCC_PER_NUM_IDEN
    AND  PER.PER_TID_CODIGO = CCC.CCC_PER_TID_CODIGO
    AND  CCC.CCC_CLI_PER_NUM_IDEN = MCC.MCC_CCC_CLI_PER_NUM_IDEN
    AND  CCC.CCC_CLI_PER_TID_CODIGO = MCC.MCC_CCC_CLI_PER_TID_CODIGO
    AND  CCC_NUMERO_CUENTA = MCC.MCC_CCC_NUMERO_CUENTA
    AND  MCC.MCC_SUC_CODIGO = ACL.ACL_SUC_CODIGO
    AND  MCC.MCC_NEG_CONSECUTIVO = ACL.ACL_NEG_CONSECUTIVO
    AND  MCC.MCC_FECHA >= TRUNC(SYSDATE)
    AND  MCC.MCC_FECHA < TRUNC(SYSDATE+1)
    AND  MCC.MCC_PAGADO IS NULL
    AND  MCC_CFC_FUG_ISI_MNEMONICO IN (P_IS.PMI_ISIN)
    AND  ACL.ACL_CAJ_MNEMONICO IN (SELECT CAJ_MNEMONICO
                                    FROM CONCEPTOS_AJUSTES
                                    WHERE CAJ_TIPO_SALDO = 'ADVAL')
GROUP BY  MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO

                                   ;
    V_REG             C_MOV_AJUMAN%ROWTYPE;

  CURSOR P_TIPM (P_PER_NUM_IDEN VARCHAR2, P_PER_TID_CODIGO VARCHAR2, P_CCC_NUMERO_CUENTA NUMBER, P_FUG_ISI_MNEMONICO VARCHAR2 ) IS
    SELECT /*+ APPEND */ ROWID RID
    FROM TMP_INSTRUCCIONES_PAGOS_MASIVO
    WHERE TIPM_ORIGEN_CLIENTE IN ('COR','DAV')
    AND TIPM_PROCESADO = 'N'
    AND TIPM_FECHA >= TRUNC(SYSDATE)
    AND TIPM_FECHA < TRUNC(SYSDATE)+1
    AND TIPM_TIPO_EMISOR IN ('E','T')
    AND TIPM_DESCRIPCION = 'ALISTAMIENTO OK'
    AND TIPM_NUM_IDEN = P_PER_NUM_IDEN
    AND TIPM_TID_CODIGO = P_PER_TID_CODIGO
    AND TIPM_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
    AND TIPM_ISIN = P_FUG_ISI_MNEMONICO;

  V_TIPM            P_TIPM%ROWTYPE;

  CURSOR C_SUCURSAL (XNIT VARCHAR2, XTIPO VARCHAR2, XCTA NUMBER) IS
      SELECT PER_SUC_CODIGO
            ,PER_NOMBRE_USUARIO
      FROM   PERSONAS
            ,CUENTAS_CLIENTE_CORREDORES
      WHERE  PER_NUM_IDEN = CCC_PER_NUM_IDEN
      AND    PER_TID_CODIGO = CCC_PER_TID_CODIGO
      AND    CCC_CLI_PER_NUM_IDEN = XNIT
      AND    CCC_CLI_PER_TID_CODIGO = XTIPO
      AND    CCC_NUMERO_CUENTA = XCTA;
   SUC1   C_SUCURSAL%ROWTYPE;

   -- INSTRUCCIONES DE PAGO ACTIVAS DE ORIGEN DE PAGO "DIVIDENDOS"
  CURSOR INSTRUCCION (P_ID VARCHAR2, P_TID VARCHAR2, P_CTA NUMBER, P_ISI VARCHAR2) IS
    SELECT /*+ APPEND */ IPD_TIPO_EMISOR
          ,IPD_CONSECUTIVO
          ,IPD_TPA_MNEMONICO
          ,IPD_BAN_CODIGO
          ,IPD_VISADO
          ,IPD_PAGO
          ,IPD_TRASLADO_FONDOS
          ,IPD_INSTRUCCION_POD
          ,IPD_PAGAR_A
          ,IPD_CRUCE_CHEQUE
    FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
    WHERE IPD_CCC_CLI_PER_NUM_IDEN = P_ID
      AND IPD_CCC_CLI_PER_TID_CODIGO = P_TID
      AND IPD_CCC_NUMERO_CUENTA = P_CTA
      AND IPD_ESTADO = 'A'
      AND (IPD_PAGO = 'S' OR IPD_TRASLADO_FONDOS = 'S' OR NVL(IPD_INSTRUCCION_POD,'N') = 'S')
      AND IPD_TIPO_ORIGEN_PAGO IN ('DI', 'SD')
      AND (IPD_TIPO_EMISOR = 'T' OR
          (IPD_TIPO_EMISOR = 'E' AND EXISTS (SELECT 'X'
                                             FROM DETALLE_INSTRUCCIONES_PAGOS
                                             WHERE DIPA_IPD_CONSECUTIVO = IPD_CONSECUTIVO
                                             AND DIPA_FUG_ISI_MNEMONICO = P_ISI)));
  REC_INSTRUCCION INSTRUCCION%ROWTYPE;

  -- MONTO EN PESOS MAXIMO PAGO ACH
  CURSOR MONTO_MAX_ACH IS
    SELECT /*+ APPEND */ CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'LAC';
  V_MONTO_MAX_ACH NUMBER;

  -- MONTO MAXIMO PAGO POD
  CURSOR MONTO_MAX_POD IS
    SELECT /*+ APPEND */ CON_VALOR
    FROM CONSTANTES
    WHERE CON_MNEMONICO = 'MMP';
  V_MONTO_MAX_POD NUMBER;

  -- CONTRIBUCION DEC. No 2331/98 --> 0,004
  CURSOR C_IBA IS
    SELECT /*+ APPEND */ CON_VALOR
    FROM   CONSTANTES
    WHERE  CON_MNEMONICO = 'IBA';

    V_IBA1           CONSTANTES.CON_VALOR%TYPE:= NULL;


  CURSOR C_CLIENTE (P_ISIN VARCHAR2, P_FUG_MNEMONICO NUMBER, P_CFC_CUENTA_DECEVAL NUMBER) IS
    SELECT CLI_EXCENTO_DXM_FONDOS
    FROM   PERSONAS
          ,CLIENTES
          ,CUENTAS_FUNGIBLE_CLIENTE
    WHERE  PER_NUM_IDEN           = CLI_PER_NUM_IDEN
    AND    PER_TID_CODIGO         = CLI_PER_TID_CODIGO
    AND    CLI_PER_NUM_IDEN       = CFC_CCC_CLI_PER_NUM_IDEN
    AND    CLI_PER_TID_CODIGO     = CFC_CCC_CLI_PER_TID_CODIGO
    AND    CFC_FUG_ISI_MNEMONICO  = P_ISIN
    AND    CFC_FUG_MNEMONICO      = P_FUG_MNEMONICO
    AND    CFC_CUENTA_DECEVAL     = P_CFC_CUENTA_DECEVAL;

   CLI1   C_CLIENTE%ROWTYPE;

   CURSOR C_ESTADO_CUENTA (P_PER_NUM_IDEN IN VARCHAR2, P_PER_TID_CODIGO IN VARCHAR2, P_NUMERO_CUENTA IN NUMBER) IS
    SELECT CCC_CUENTA_ACTIVA
          ,CCC_PER_NUM_IDEN
          ,CCC_PER_TID_CODIGO
    FROM  CUENTAS_CLIENTE_CORREDORES
    WHERE CCC_CLI_PER_NUM_IDEN    = P_PER_NUM_IDEN
    AND   CCC_CLI_PER_TID_CODIGO  = P_PER_TID_CODIGO
    AND   CCC_NUMERO_CUENTA       = P_NUMERO_CUENTA;
  CCC1   C_ESTADO_CUENTA%ROWTYPE;

  CURSOR C_HIST (P_ISIN IN VARCHAR2) IS
    SELECT ROWID RID
    FROM HISTORICO_CAPADV HCD
    WHERE HCD.HCD_MNEMONICO = (SELECT MAX(HCDN.HCD_MNEMONICO)
                                  FROM HISTORICO_CAPADV HCDN
                                  WHERE HCDN.HCD_ISIN = HCD.HCD_ISIN )
    AND TRUNC(HCD.HCD_FECHA_CARGUE) = TRUNC(SYSDATE)
    AND HCD.HCD_ISIN = P_ISIN;
  V_RID             VARCHAR2 (512);

  V_COMM            NUMBER := 0;
  ERRORSQL          VARCHAR2(2000);

  V_TDD_IPD_TIPO_EMISOR         TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TIPO_EMISOR%TYPE;
  V_TDD_IPD_CONSECUTIVO         TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_CONSECUTIVO%TYPE;
  V_TDD_IPD_TPA_MNEMONICO       TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TPA_MNEMONICO%TYPE;
  V_TDD_IPD_BAN_CODIGO          TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_BAN_CODIGO%TYPE;
  V_TDD_IPD_VISADO              TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_VISADO%TYPE;
  V_TDD_IPD_PAGO                TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_PAGO%TYPE;
  V_TDD_IPD_TRASLADO_FONDOS     TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_TRASLADO_FONDOS%TYPE;
  V_TDD_IPD_INSTRUCCION_POD     TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_INSTRUCCION_POD%TYPE;
  V_TDD_IPD_PAGAR_A             TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_PAGAR_A%TYPE;
  V_TDD_IPD_CRUCE_CHEQUE        TMP_PAGOS_DEPOSITOS_DCVAL.TDD_IPD_CRUCE_CHEQUE%TYPE;
  V_TDD_CCC_PER_NUM_IDEN        TMP_PAGOS_DEPOSITOS_DCVAL.TDD_CCC_PER_NUM_IDEN%TYPE;
  V_TDD_CCC_PER_TID_CODIGO      TMP_PAGOS_DEPOSITOS_DCVAL.TDD_CCC_PER_TID_CODIGO%TYPE;
  V_TDD_CLI_EXCENTO_DXM         TMP_PAGOS_DEPOSITOS_DCVAL.TDD_CLI_EXCENTO_DXM%TYPE;
  V_FAV_CONSECUTIVO             FACTURAS_ADMON_VALORES.FAV_CONSECUTIVO%TYPE;

  V_ISIN                        VARCHAR2(30);

  TYPE O_CURSOR IS REF CURSOR;
  C_CURSOR O_CURSOR;
  V_SELECT VARCHAR2(4000);
BEGIN
  V_SELECT := 'WITH P_IS AS (SELECT PMI_ISIN
                    FROM PAGOS_MASIVOS_ISIN
                   WHERE PMI_FECHA >= TRUNC(SYSDATE)
                     AND PMI_FECHA < TRUNC(SYSDATE+1)
                     AND PMI_PAGADO = ''P'')
    SELECT /*+ APPEND */ MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,SUM(MCC.MCC_MONTO_ADMON_VALORES) MONTO
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO
    FROM  MOVIMIENTOS_CUENTA_CORREDORES MCC, AJUSTES_CLIENTES ACL, P_IS
    ,PERSONAS PER, CUENTAS_CLIENTE_CORREDORES CCC
    WHERE MCC.MCC_ACL_CONSECUTIVO = ACL.ACL_CONSECUTIVO
    AND  PER.PER_NUM_IDEN = CCC.CCC_PER_NUM_IDEN
    AND  PER.PER_TID_CODIGO = CCC.CCC_PER_TID_CODIGO
    AND  CCC.CCC_CLI_PER_NUM_IDEN = MCC.MCC_CCC_CLI_PER_NUM_IDEN
    AND  CCC.CCC_CLI_PER_TID_CODIGO = MCC.MCC_CCC_CLI_PER_TID_CODIGO
    AND   CCC_NUMERO_CUENTA = MCC.MCC_CCC_NUMERO_CUENTA
    AND   MCC.MCC_SUC_CODIGO = ACL.ACL_SUC_CODIGO
    AND   MCC.MCC_NEG_CONSECUTIVO = ACL.ACL_NEG_CONSECUTIVO
    AND   MCC.MCC_FECHA >= TRUNC(SYSDATE)
    AND   MCC.MCC_FECHA < TRUNC(SYSDATE+1)
    AND   MCC.MCC_PAGADO IS NULL
    AND   MCC_CFC_FUG_ISI_MNEMONICO IN (P_IS.PMI_ISIN)
    AND   ACL.ACL_CAJ_MNEMONICO IN (SELECT CAJ_MNEMONICO
                                    FROM CONCEPTOS_AJUSTES
                                    WHERE CAJ_TIPO_SALDO = ''ADVAL'')
GROUP BY  MCC.MCC_CCC_CLI_PER_NUM_IDEN
          ,MCC.MCC_CCC_CLI_PER_TID_CODIGO
          ,MCC.MCC_CCC_NUMERO_CUENTA
          ,MCC.MCC_CFC_FUG_ISI_MNEMONICO
          ,MCC.MCC_CFC_FUG_MNEMONICO
          ,MCC.MCC_CFC_CUENTA_DECEVAL
          ,MCC.MCC_FAV_CONSECUTIVO
          ,PER.PER_SUC_CODIGO
          ,PER.PER_NOMBRE_USUARIO';
  V_COMM := 0;

  C_CURSOR  := NULL;
  V_REG     := NULL;
  OPEN C_CURSOR FOR V_SELECT;
  LOOP
  FETCH C_CURSOR INTO V_REG.MCC_CCC_CLI_PER_NUM_IDEN
                      ,V_REG.MCC_CCC_CLI_PER_TID_CODIGO
                      ,V_REG.MCC_CCC_NUMERO_CUENTA
                      ,V_REG.MONTO
                      ,V_REG.MCC_CFC_FUG_ISI_MNEMONICO
                      ,V_REG.MCC_CFC_FUG_MNEMONICO
                      ,V_REG.MCC_CFC_CUENTA_DECEVAL
                      ,V_REG.MCC_FAV_CONSECUTIVO
                      ,V_REG.PER_SUC_CODIGO
                      ,V_REG.PER_NOMBRE_USUARIO;
  EXIT WHEN C_CURSOR%NOTFOUND;
    V_COMM := V_COMM + 1;
    OPEN P_TIPM (V_REG.MCC_CCC_CLI_PER_NUM_IDEN, V_REG.MCC_CCC_CLI_PER_TID_CODIGO, V_REG.MCC_CCC_NUMERO_CUENTA, V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
    FETCH P_TIPM INTO V_TIPM;
    IF P_TIPM%FOUND THEN
      UPDATE TMP_INSTRUCCIONES_PAGOS_MASIVO
      SET TIPM_MONTO_ODP = TIPM_MONTO_ODP + V_REG.MONTO
      WHERE ROWID = V_TIPM.RID;
    ELSIF P_TIPM%NOTFOUND THEN
      --
      V_TDD_IPD_TIPO_EMISOR     := NULL;
      V_TDD_IPD_CONSECUTIVO     := NULL;
      V_TDD_IPD_TPA_MNEMONICO   := NULL;
      V_TDD_IPD_BAN_CODIGO      := NULL;
      V_TDD_IPD_VISADO          := NULL;
      V_TDD_IPD_PAGO            := NULL;
      V_TDD_IPD_TRASLADO_FONDOS := NULL;
      V_TDD_IPD_INSTRUCCION_POD := NULL;
      V_TDD_IPD_PAGAR_A         := NULL;
      V_TDD_IPD_CRUCE_CHEQUE    := NULL;
      OPEN INSTRUCCION(V_REG.MCC_CCC_CLI_PER_NUM_IDEN, V_REG.MCC_CCC_CLI_PER_TID_CODIGO, V_REG.MCC_CCC_NUMERO_CUENTA, V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
      FETCH INSTRUCCION INTO REC_INSTRUCCION;
        IF INSTRUCCION%FOUND THEN
          V_TDD_IPD_TIPO_EMISOR     := REC_INSTRUCCION.IPD_TIPO_EMISOR;
          V_TDD_IPD_CONSECUTIVO     := REC_INSTRUCCION.IPD_CONSECUTIVO;
          V_TDD_IPD_TPA_MNEMONICO   := REC_INSTRUCCION.IPD_TPA_MNEMONICO;
          V_TDD_IPD_BAN_CODIGO      := REC_INSTRUCCION.IPD_BAN_CODIGO;
          V_TDD_IPD_VISADO          := REC_INSTRUCCION.IPD_VISADO;
          V_TDD_IPD_PAGO            := REC_INSTRUCCION.IPD_PAGO;
          V_TDD_IPD_TRASLADO_FONDOS := REC_INSTRUCCION.IPD_TRASLADO_FONDOS;
          V_TDD_IPD_INSTRUCCION_POD := REC_INSTRUCCION.IPD_INSTRUCCION_POD;
          V_TDD_IPD_PAGAR_A         := REC_INSTRUCCION.IPD_PAGAR_A;
          V_TDD_IPD_CRUCE_CHEQUE    := REC_INSTRUCCION.IPD_CRUCE_CHEQUE;
        ELSIF INSTRUCCION%NOTFOUND THEN
          V_TDD_IPD_TIPO_EMISOR     := NULL;
          V_TDD_IPD_CONSECUTIVO     := NULL;
          V_TDD_IPD_TPA_MNEMONICO   := NULL;
          V_TDD_IPD_BAN_CODIGO      := NULL;
          V_TDD_IPD_VISADO          := NULL;
          V_TDD_IPD_PAGO            := NULL;
          V_TDD_IPD_TRASLADO_FONDOS := NULL;
          V_TDD_IPD_INSTRUCCION_POD := NULL;
          V_TDD_IPD_PAGAR_A         := NULL;
          V_TDD_IPD_CRUCE_CHEQUE    := NULL;
        END IF;
      CLOSE INSTRUCCION;

      OPEN MONTO_MAX_ACH;
      FETCH MONTO_MAX_ACH INTO V_MONTO_MAX_ACH;
      CLOSE MONTO_MAX_ACH;


      OPEN MONTO_MAX_POD;
      FETCH MONTO_MAX_POD INTO V_MONTO_MAX_POD;
      CLOSE MONTO_MAX_POD;

      OPEN C_IBA;
      FETCH C_IBA INTO V_IBA1;
      CLOSE C_IBA;
      V_IBA1 := NVL(V_IBA1,0);

      OPEN C_ESTADO_CUENTA (V_REG.MCC_CCC_CLI_PER_NUM_IDEN, V_REG.MCC_CCC_CLI_PER_TID_CODIGO, V_REG.MCC_CCC_NUMERO_CUENTA);
      FETCH C_ESTADO_CUENTA INTO CCC1;
      CLOSE C_ESTADO_CUENTA;
      V_TDD_CCC_PER_NUM_IDEN    := CCC1.CCC_PER_NUM_IDEN;
      V_TDD_CCC_PER_TID_CODIGO  := CCC1.CCC_PER_TID_CODIGO;

      OPEN C_CLIENTE (V_REG.MCC_CFC_FUG_ISI_MNEMONICO, V_REG.MCC_CFC_FUG_MNEMONICO, V_REG.MCC_CFC_CUENTA_DECEVAL);
      FETCH C_CLIENTE INTO CLI1;
      CLOSE C_CLIENTE;
      V_TDD_CLI_EXCENTO_DXM := CLI1.CLI_EXCENTO_DXM_FONDOS;

      V_RID := NULL;
      OPEN C_HIST (V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
      FETCH C_HIST INTO V_RID;
      CLOSE C_HIST;

      IF V_RID IS NOT NULL THEN
        UPDATE HISTORICO_CAPADV HCD
        SET HCD.HCD_CANTIDAD = HCD.HCD_CANTIDAD + 1, HCD.HCD_MONTO = HCD.HCD_MONTO + V_REG.MONTO
        WHERE ROWID = V_RID;
      END IF;
     --
      IF V_ISIN IS NULL OR V_ISIN != V_REG.MCC_CFC_FUG_ISI_MNEMONICO THEN
        P_PROCESO.PR_PROCESO_PAGOS_DIVIDENDOS ('ABO',V_REG.MCC_CFC_FUG_ISI_MNEMONICO);
        V_ISIN := V_REG.MCC_CFC_FUG_ISI_MNEMONICO;
      END IF;
      --
      V_FAV_CONSECUTIVO := V_REG.MCC_FAV_CONSECUTIVO;

      P_PAGOS_DIVIDENDOS.PROCESO_PAGOS_MASIVOS_DIV_M (/*V_REG.MCC_CONSECUTIVO*/NULL
                                                    ,V_REG.MCC_CCC_CLI_PER_NUM_IDEN
                                                    ,V_REG.MCC_CCC_CLI_PER_TID_CODIGO
                                                    ,V_REG.MCC_CCC_NUMERO_CUENTA
                                                    ,V_REG.MCC_CFC_FUG_ISI_MNEMONICO
                                                    ,V_TDD_CLI_EXCENTO_DXM
                                                    ,V_TDD_IPD_TIPO_EMISOR
                                                    ,V_TDD_IPD_CONSECUTIVO
                                                    ,V_TDD_IPD_TPA_MNEMONICO
                                                    ,V_TDD_IPD_BAN_CODIGO
                                                    ,V_TDD_IPD_VISADO
                                                    ,V_TDD_IPD_PAGO
                                                    ,V_TDD_IPD_TRASLADO_FONDOS
                                                    ,V_TDD_IPD_INSTRUCCION_POD
                                                    ,V_TDD_IPD_PAGAR_A
                                                    ,V_TDD_IPD_CRUCE_CHEQUE
                                                    ,V_MONTO_MAX_POD
                                                    ,V_MONTO_MAX_ACH
                                                    ,V_IBA1
                                                    ,V_REG.PER_SUC_CODIGO
                                                    ,V_REG.PER_NOMBRE_USUARIO
                                                    ,V_TDD_CCC_PER_NUM_IDEN
                                                    ,V_TDD_CCC_PER_TID_CODIGO
                                                      ,V_FAV_CONSECUTIVO);
      --
    END IF;
    CLOSE P_TIPM;

    DELETE PAGOS_DEPOSITOS_DCVAL_NO
    WHERE PDD_FUNGIBLE = V_REG.MCC_CFC_FUG_MNEMONICO
    AND PDD_ISIN = V_REG.MCC_CFC_FUG_ISI_MNEMONICO
    AND PDD_CUENTA_DCVAL =  V_REG.MCC_CFC_CUENTA_DECEVAL;
    COMMIT;

  END LOOP;

  CLOSE C_CURSOR;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
      ERRORSQL := SUBSTR(SQLERRM,1,80);

      P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PR_PAMADI_AJUMAN'
                                          ,P_ERROR       => 'ERROR '||sqlerrm
                                          ,P_TABLA_ERROR => NULL);
END PR_PAMADI_AJUMAN;

PROCEDURE PR_APLICA_RECHAZO (P_ODP_CONSECUTIVO      IN NUMBER
                            ,P_PEL_ODP_CONSECUTIVO  IN NUMBER
                            ,P_RPAE_CONSECUTIVO			IN NUMBER
														,P_INS								  IN VARCHAR2
														,P_CONSECUTIVO				  IN NUMBER) IS

  CURSOR C_ODP IS
    SELECT ODP_CCC_CLI_PER_NUM_IDEN, ODP_CCC_CLI_PER_TID_CODIGO, ODP_CCC_NUMERO_CUENTA, ODP_MONTO_ORDEN, ODP_BAN_CODIGO, ODP_TPA_MNEMONICO
    FROM ORDENES_DE_PAGO
    WHERE ODP_CONSECUTIVO = P_ODP_CONSECUTIVO;
  R_ODP C_ODP%ROWTYPE;

  CURSOR C_CCC (P_CLI_PER_NUM_IDEN VARCHAR2, P_CLI_PER_TID_CODIGO VARCHAR2, P_NUMERO_CUENTA NUMBER) IS
    SELECT CCC_PER_NUM_IDEN, CCC_PER_TID_CODIGO
    FROM CUENTAS_CLIENTE_CORREDORES
    WHERE CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
    AND CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND CCC_NUMERO_CUENTA = P_NUMERO_CUENTA;
  R_CCC C_CCC%ROWTYPE;

  CURSOR C_PER (P_PER_TID_CODIGO VARCHAR2, P_PER_NUM_IDEN VARCHAR2)  IS
    SELECT PER_MAIL_CORREDOR||(SELECT ';'||LISTAGG((SELECT PER_MAIL_CORREDOR
																										FROM FILTRO_COMERCIALES
																										WHERE PER_NUM_IDEN = ASC_PER_NUM_IDEN
																										AND PER_TID_CODIGO = ASC_PER_TID_CODIGO), ';') WITHIN GROUP (ORDER BY ASC_COM_PER_NUM_IDEN)
															FROM ASISTENTES_COMERCIALES
															WHERE ASC_COM_PER_NUM_IDEN = PER_NUM_IDEN
															AND ASC_COM_PER_TID_CODIGO = PER_TID_CODIGO)
		FROM FILTRO_COMERCIALES
		WHERE PER_NUM_IDEN = P_PER_NUM_IDEN
		AND PER_TID_CODIGO = P_PER_TID_CODIGO;
  V_MAIL CORREO_PD_COMERCIAL.CPDC_MAIL%TYPE;

  CURSOR C_CPA (P_PER_TID_CODIGO VARCHAR2, P_PER_NUM_IDEN VARCHAR2) IS
    SELECT CPA_MNEMONICO, CPA_CFC_FUG_ISI_MNEMONICO
    FROM CONVERTIR_PAGOS_POD
    WHERE CPA_PER_TID_CODIGO = P_PER_TID_CODIGO
    AND CPA_PER_NUM_IDEN = P_PER_NUM_IDEN;
  R_CPA C_CPA%ROWTYPE;

  CURSOR C_CFC (P_CCC_CLI_PER_NUM_IDEN VARCHAR2, P_CCC_CLI_PER_TID_CODIGO VARCHAR2, P_CCC_NUMERO_CUENTA NUMBER, P_FUG_ISI_MNEMONICO VARCHAR2) IS
    SELECT COUNT(1)CANT
    FROM CUENTAS_FUNGIBLE_CLIENTE
    WHERE CFC_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
    AND CFC_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
    AND CFC_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
    AND CFC_FUG_ISI_MNEMONICO = P_FUG_ISI_MNEMONICO;
  V_CANT    NUMBER;

  CURSOR C_PEL IS
    SELECT PEL_MONTO, PEL_CBA_BAN_CODIGO, PEL_CBA_NUMERO_CUENTA, PEL_ODP_CONSECUTIVO
    FROM CONCILIACIONES_PAGOS_ELECTRONI
    WHERE PEL_CONSECUTIVO = P_PEL_ODP_CONSECUTIVO;
  R_PEL C_PEL%ROWTYPE;

  CURSOR C_RPAE IS
    SELECT RPAE_MONTO, RPAE_BAN_CODIGO, RPAE_CODIGO_RESPUESTA
    FROM RESULTADOS_PAGOS_ELECTRONICOS
    WHERE RPAE_CONSECUTIVO = P_RPAE_CONSECUTIVO
    AND RPAE_CODIGO_RESPUESTA != '0000';
  R_RPAE C_RPAE%ROWTYPE;

  CURSOR C_CRDA (P_CRDA_CODIGO VARCHAR2)IS
    SELECT CRDA_CODIGO, NVL(CRDA_INAC_INSTRUCCION,'N')CRDA_INAC_INSTRUCCION
    FROM CODIGOS_RESPUESTA_DAVIVIENDA
    WHERE CRDA_CODIGO = P_CRDA_CODIGO;
  R_CRDA C_CRDA%ROWTYPE;

  CURSOR C_ISE (P_ISI_MNEMONICO VARCHAR2) IS
    SELECT ISE_ENA_MNEMONICO
    FROM ISINS_ESPECIES
    WHERE ISE_ISI_MNEMONICO = P_ISI_MNEMONICO;
  R_ISE C_ISE%ROWTYPE;

  CURSOR C_TIPM IS
    SELECT TIPM_ISIN
    FROM  TMP_INSTRUCCIONES_PAGOS_MASIVO
    WHERE TIPM_ODP_CONSECUTIVO = P_ODP_CONSECUTIVO;
  R_TIPM C_TIPM%ROWTYPE;

  ERRORSQL VARCHAR2(512);

BEGIN
	OPEN C_ODP;
  FETCH C_ODP INTO R_ODP;
  CLOSE C_ODP;

	IF R_ODP.ODP_TPA_MNEMONICO IN ('ACH', 'TRB') THEN
		OPEN C_CCC (R_ODP.ODP_CCC_CLI_PER_NUM_IDEN, R_ODP.ODP_CCC_CLI_PER_TID_CODIGO, R_ODP.ODP_CCC_NUMERO_CUENTA);
		FETCH C_CCC INTO R_CCC;
		CLOSE C_CCC;

		OPEN C_CPA (R_CCC.CCC_PER_TID_CODIGO, R_CCC.CCC_PER_NUM_IDEN);
		FETCH C_CPA INTO R_CPA;
		CLOSE C_CPA;

		IF R_CPA.CPA_MNEMONICO IS NULL THEN
			R_CPA.CPA_MNEMONICO := 9999;
		END IF;

		OPEN C_PER (R_CCC.CCC_PER_TID_CODIGO, R_CCC.CCC_PER_NUM_IDEN);
		FETCH C_PER INTO V_MAIL;
		CLOSE C_PER;

		IF INSTR(V_MAIL, ';', -1) = LENGTH(V_MAIL) THEN
			V_MAIL := SUBSTR (V_MAIL, 1, LENGTH(V_MAIL)-1);
		END IF;

		OPEN C_TIPM;
		FETCH C_TIPM INTO R_TIPM;
		CLOSE C_TIPM;

		OPEN C_CFC (R_ODP.ODP_CCC_CLI_PER_NUM_IDEN, R_ODP.ODP_CCC_CLI_PER_TID_CODIGO, R_ODP.ODP_CCC_NUMERO_CUENTA, NVL(R_CPA.CPA_CFC_FUG_ISI_MNEMONICO, R_TIPM.TIPM_ISIN)) ;
		FETCH C_CFC INTO V_CANT;
		CLOSE C_CFC;

		OPEN C_PEL;
		FETCH C_PEL INTO R_PEL;
		CLOSE C_PEL;

		OPEN C_RPAE;
		FETCH C_RPAE INTO R_RPAE;
		CLOSE C_RPAE;

		OPEN C_CRDA(R_RPAE.RPAE_CODIGO_RESPUESTA);
		FETCH C_CRDA INTO R_CRDA;
		CLOSE C_CRDA;

		OPEN C_ISE(NVL(R_CPA.CPA_CFC_FUG_ISI_MNEMONICO, R_TIPM.TIPM_ISIN)) ;
		FETCH C_ISE INTO R_ISE;
		CLOSE C_ISE;

		IF R_TIPM.TIPM_ISIN = R_CPA.CPA_CFC_FUG_ISI_MNEMONICO AND R_ODP.ODP_TPA_MNEMONICO IN ('TRB') THEN
			-- Generar pago POD, para que el cliente cobre por ventanilla
			INSERT INTO TMP_INSTRUCCIONES_PAGOS_MASIVO (TIPM_CONSECUTIVO
																								,TIPM_ORIGEN_CLIENTE
																								,TIPM_FECHA
																								,TIPM_NUM_IDEN
																								,TIPM_TID_CODIGO
																								,TIPM_NUMERO_CUENTA
																								,TIPM_IPD_CONSECUTIVO
																								,TIPM_MONTO_ODP
																								,TIPM_PROCESADO
																								,TIPM_TPA_MNEMONICO
																								,TIPM_ISIN
																								,TIPM_EMISOR
                                                ,TIPM_ORDEN
                                                ,TIPM_FUENTE
                                                ,TIPM_DESCRIPCION
																								)
			VALUES (TIPM_SEQ.NEXTVAL
							,NULL
							,SYSDATE+1
							,R_ODP.ODP_CCC_CLI_PER_NUM_IDEN
							,R_ODP.ODP_CCC_CLI_PER_TID_CODIGO
							,R_ODP.ODP_CCC_NUMERO_CUENTA
							,NULL
							,R_ODP.ODP_MONTO_ORDEN
							,'N'
							,'POD'
							,R_CPA.CPA_CFC_FUG_ISI_MNEMONICO
							,R_ISE.ISE_ENA_MNEMONICO
              ,75
              ,DECODE (R_CPA.CPA_CFC_FUG_ISI_MNEMONICO, 'COB51PA00076', 'DAV', 'COC04PA00016', 'ECO', 'COE15PA00026', 'DAV')
              ,'ALISTAMIENTO OK');
		END IF;

		IF R_CRDA.CRDA_INAC_INSTRUCCION = 'S' AND P_INS IS NOT NULL THEN
			UPDATE INSTRUCCIONES_PAGOS_DIVIDENDOS
			SET IPD_ESTADO = 'I',
					IPD_FECHA_INACTIVACION = TRUNC (SYSDATE),
					IPD_MOTIVO_INACTIVACION = 'Se inactivo el cliente. Formulario de actualizacion '||TO_CHAR(P_CONSECUTIVO),
					IPD_USUARIO_INACTIVACION = USER,
					IPD_TERMINAL_INACTIVACION = FN_TERMINAL
			WHERE ROWID = P_INS;

			IF SQL%ROWCOUNT = 0 THEN
				R_CRDA.CRDA_INAC_INSTRUCCION := 'N';
			END IF;
		ELSIF R_CRDA.CRDA_INAC_INSTRUCCION = 'S' AND P_INS IS NULL THEN
			R_CRDA.CRDA_INAC_INSTRUCCION := 'N';
		END IF;

		IF V_MAIL IS NOT NULL AND R_CCC.CCC_PER_NUM_IDEN IS NOT NULL AND R_CCC.CCC_PER_TID_CODIGO IS NOT NULL
				AND R_ODP.ODP_CCC_CLI_PER_TID_CODIGO IS NOT NULL
				AND R_ODP.ODP_CCC_CLI_PER_NUM_IDEN IS NOT NULL AND R_CRDA.CRDA_CODIGO IS NOT NULL THEN
			BEGIN
				INSERT INTO CORREO_PD_COMERCIAL(CPDC_MNEMONICO
																			,CPDC_CPA_MNEMONICO
																			,CPDC_CCC_PER_NUM_IDEN
																			,CPDC_CCC_PER_TID_CODIGO
																			,CPDC_PER_TID_CODIGO
																			,CPDC_PER_NUM_IDEN
																			,CPDC_BAN_CODIGO
																			,CPDC_VALOR
																			,CPDC_CRDA_CODIGO
																			,CPDC_CRDA_INAC_INSTRUCCION
																			,CPDC_MAIL
																			,CPDC_ESTADO
                                      ,CPDC_PEL_CONSECUTIVO
                                      ,CPDC_RPAE_CONSECUTIVO
                                      ,CPDC_ODP_CONSECUTIVO)
				VALUES (CPDC_SEQ.NEXTVAL
							,R_CPA.CPA_MNEMONICO
							,R_CCC.CCC_PER_NUM_IDEN							--COMERCIAL
							,R_CCC.CCC_PER_TID_CODIGO						--COMERCIAL
							,R_ODP.ODP_CCC_CLI_PER_TID_CODIGO		--CLIENTE
							,R_ODP.ODP_CCC_CLI_PER_NUM_IDEN			--CLIENTE
							,R_RPAE.RPAE_BAN_CODIGO							--TABLA RESULTADOS_PAGOS_ELECTRONICOS COD_BANCO
							,R_RPAE.RPAE_MONTO									--TABLA RESULTADOS_PAGOS_ELECTRONICOS MONTO
							,R_CRDA.CRDA_CODIGO                	--CODIGO RESPUESTA DAVIVIENDA
							,R_CRDA.CRDA_INAC_INSTRUCCION				--INDICA SI INACTIVA INSTRUCCION
							,V_MAIL															--MAIL
							,'P'                                --ESTADO
              ,P_PEL_ODP_CONSECUTIVO              --CONSECUTIVO CONCILIACIONES_PAGOS_ELECTRONI
              ,P_RPAE_CONSECUTIVO                 --CONSECUTIVO RESULTADOS_PAGOS_ELECTRONICOS
              ,P_ODP_CONSECUTIVO);                --CONSECUTIVO ORDENES_DE_PAGO
			EXCEPTION
				WHEN OTHERS THEN
					ERRORSQL := SUBSTR(SQLERRM,1,200);
					P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PR_APLICA_RECHAZO'
																							,P_ERROR       => 'ERROR '||SQLERRM
																							,P_TABLA_ERROR => 'CORREO_PD_COMERCIAL');
			END;
		ELSE
			P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PR_APLICA_RECHAZO'
																					,P_ERROR       => 'ERROR '||V_MAIL||' - '||R_CPA.CPA_MNEMONICO||' - '||R_CCC.CCC_PER_NUM_IDEN||' - '||
																														R_CCC.CCC_PER_TID_CODIGO||' - '||R_ODP.ODP_CCC_CLI_PER_TID_CODIGO ||' - '||
																														R_ODP.ODP_CCC_CLI_PER_NUM_IDEN||' - '||R_CRDA.CRDA_CODIGO
																					,P_TABLA_ERROR => 'CORREO_PD_COMERCIAL');
		END IF;
	END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ERRORSQL := SUBSTR(SQLERRM,1,200);
    P_PAGOS_DIVIDENDOS.INSERTA_ERROR_DIV(P_PROCESO     => 'PR_APLICA_RECHAZO'
                                        ,P_ERROR       => 'ERROR '||SQLERRM
                                        ,P_TABLA_ERROR => NULL);
END	PR_APLICA_RECHAZO;

FUNCTION FN_SALDO_ADMON_VALORES
   (P_CLI_NUM_IDEN      IN  CLIENTES.CLI_PER_NUM_IDEN%TYPE
   ,P_CLI_TID_CODIGO    IN  CLIENTES.CLI_PER_TID_CODIGO%TYPE
   ,P_CUENTA            IN  CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
   ,P_SALDO_RECALCULADO IN  VARCHAR2
   ,P_SALDO_ODP         OUT CUENTAS_CLIENTE_CORREDORES.CCC_SALDO_CAPITAL%TYPE) RETURN NUMBER IS

   CURSOR C_SALDO_CCC IS
      SELECT CCC_SALDO_ADMON_VALORES
      FROM   CUENTAS_CLIENTE_CORREDORES
      WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    CCC_NUMERO_CUENTA = P_CUENTA;
   CCC1   C_SALDO_CCC%ROWTYPE;

   CURSOR C_SALDO IS
      SELECT MCC_SALDO_ADMON_VALORES
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CUENTA
      AND    MCC_FECHA < TRUNC(SYSDATE)
      ORDER BY MCC_CONSECUTIVO DESC;
   MCC1   C_SALDO%ROWTYPE;

   CURSOR C_MOVIMIENTO IS
      SELECT SUM(MCC_MONTO_ADMON_VALORES)
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CUENTA
      AND    MCC_FECHA >= TRUNC(SYSDATE);

   CURSOR C_PAGOS_COL IS
      SELECT SUM(ODP_MONTO_ORDEN) TOTAL_ODP
            ,SUM(ODP_MONTO_IMGF)  TOTAL_ODP_GMF
      FROM   ORDENES_DE_PAGO
      WHERE  ODP_NPR_PRO_MNEMONICO = 'ADVAL'
      AND    ODP_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND    ODP_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND    ODP_CCC_NUMERO_CUENTA = P_CUENTA
      AND    ODP_ESTADO IN ('COL','APR')
      AND    ODP_FECHA_EJECUCION >= TRUNC(SYSDATE-30)
      AND    ODP_CEG_CONSECUTIVO IS NULL
      AND    ODP_CGE_CONSECUTIVO IS NULL
      AND    ODP_TBC_CONSECUTIVO IS NULL
      AND    ODP_TCC_CONSECUTIVO IS NULL
      AND    NVL(ODP_ORDEN_MANUAL,'N') = 'N';
   ODP1   C_PAGOS_COL%ROWTYPE;

   -- Recupera saldos pendientes por pagar en oficinas Davivienda
   CURSOR C_SALDOS_POD IS
      SELECT  SUM(MDA_VALOR_DIVIDENDO) MDA_VALOR_DIVIDENDO
      FROM MOVIMIENTOS_CLIENTE_DAVIVIENDA
      WHERE   MDA_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
      AND  MDA_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
      AND MDA_CCC_NUMERO_CUENTA = P_CUENTA
      AND MDA_ESTADO = 'P';
   POD  C_SALDOS_POD%ROWTYPE;

   -- Recupera las ordenes de fondo
   CURSOR C_ORDENES_FOND IS
    SELECT SUM(OFO_MONTO) OFO_MONTO
    FROM ORDENES_FONDOS
    WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_NUM_IDEN
    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_TID_CODIGO
    AND OFO_CFO_CCC_NUMERO_CUENTA = P_CUENTA
    AND OFO_TTO_TIT_CODIGO = 'CAR'
    AND OFO_EOF_CODIGO = 'APL'
    AND OFO_CARGO_ABONO_CUENTA = 'S'
    AND OFO_ORIGEN_RECURSOS = 'I'
    AND OFO_DESCRIPCION = 'SYS_PROGRAMADO'
    AND OFO_FECHA_CAPTURA >= TRUNC(SYSDATE)
    AND OFO_FECHA_CAPTURA < TRUNC(SYSDATE+1)
    AND EXISTS (SELECT 'X'
                FROM INSTRUCCIONES_PAGOS_DIVIDENDOS
                WHERE IPD_CCC_CLI_PER_NUM_IDEN = OFO_CFO_CCC_CLI_PER_NUM_IDEN
                AND IPD_CCC_CLI_PER_TID_CODIGO = OFO_CFO_CCC_CLI_PER_TID_CODIGO
                AND IPD_CFO_CCC_NUMERO_CUENTA = OFO_CFO_CCC_NUMERO_CUENTA
                AND IPD_TRASLADO_FONDOS = 'S'
                AND IPD_ESTADO = 'A');
   OFO C_ORDENES_FOND%ROWTYPE;

   TOTAL_DIA NUMBER;

BEGIN
   IF P_SALDO_RECALCULADO = 'S' THEN
      OPEN C_SALDO;
      FETCH C_SALDO INTO MCC1;
      CLOSE C_SALDO;
      MCC1.MCC_SALDO_ADMON_VALORES := NVL(MCC1.MCC_SALDO_ADMON_VALORES, 0);

      OPEN C_MOVIMIENTO;
      FETCH C_MOVIMIENTO INTO TOTAL_DIA;
      CLOSE C_MOVIMIENTO;
      TOTAL_DIA := NVL(TOTAL_DIA, 0);

      MCC1.MCC_SALDO_ADMON_VALORES := MCC1.MCC_SALDO_ADMON_VALORES + TOTAL_DIA;

      OPEN C_PAGOS_COL;
      FETCH C_PAGOS_COL INTO ODP1;
      CLOSE C_PAGOS_COL;

      OPEN C_SALDOS_POD;
      FETCH C_SALDOS_POD INTO POD;
      CLOSE  C_SALDOS_POD;

      OPEN C_ORDENES_FOND;
      FETCH C_ORDENES_FOND INTO OFO;
      CLOSE  C_ORDENES_FOND;

      MCC1.MCC_SALDO_ADMON_VALORES := MCC1.MCC_SALDO_ADMON_VALORES
                                    - NVL(ODP1.TOTAL_ODP,0)
                                    + NVL(ODP1.TOTAL_ODP_GMF,0)
                                    - NVL(POD.MDA_VALOR_DIVIDENDO,0)
                                    - NVL(OFO.OFO_MONTO,0);

      P_SALDO_ODP := ABS( - NVL(ODP1.TOTAL_ODP,0)
                          + NVL(ODP1.TOTAL_ODP_GMF,0)
                          - NVL(POD.MDA_VALOR_DIVIDENDO,0)
                        );
      RETURN(NVL(MCC1.MCC_SALDO_ADMON_VALORES,0));
   ELSE
      OPEN C_SALDO_CCC;
      FETCH C_SALDO_CCC INTO CCC1;
      CLOSE C_SALDO_CCC;

      OPEN C_PAGOS_COL;
      FETCH C_PAGOS_COL INTO ODP1;
      CLOSE C_PAGOS_COL;

      OPEN C_SALDOS_POD;
      FETCH C_SALDOS_POD INTO POD;
      CLOSE  C_SALDOS_POD;

      CCC1.CCC_SALDO_ADMON_VALORES := CCC1.CCC_SALDO_ADMON_VALORES
                                    - NVL(ODP1.TOTAL_ODP,0)
                                    + NVL(ODP1.TOTAL_ODP_GMF,0)
                                    - NVL(POD.MDA_VALOR_DIVIDENDO,0);

      P_SALDO_ODP := ABS( - NVL(ODP1.TOTAL_ODP,0)
                          + NVL(ODP1.TOTAL_ODP_GMF,0)
                          - NVL(POD.MDA_VALOR_DIVIDENDO,0)
                        );
      RETURN (NVL(CCC1.CCC_SALDO_ADMON_VALORES,0));
   END IF;
END FN_SALDO_ADMON_VALORES;

END P_PAGOS_DIVIDENDOS;

/

  GRANT EXECUTE ON "PROD"."P_PAGOS_DIVIDENDOS" TO "COE_RECURSOS";
