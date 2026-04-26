--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_PAGOS_DIVIDENDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_PAGOS_DIVIDENDOS" IS

TYPE O_CURSOR IS REF CURSOR;

/***********************************************************************
 ***  Procedimientos para Pagos masivos de Dividendos                  **
 ********************************************************************* */
PROCEDURE INSERTA_ERROR_DIV
   (P_PROCESO         ERRORES_PROCESOS_DIVIDENDOS.EPD_PROCESO%TYPE
   ,P_ERROR           ERRORES_PROCESOS_DIVIDENDOS.EPD_ERROR%TYPE
   ,P_TABLA_ERROR     ERRORES_PROCESOS_DIVIDENDOS.EPD_TABLA%TYPE);

--------------------------------------------------------------------------------
PROCEDURE ObtenerInstPagoDividendos
   (P_TID_CODIGO    VARCHAR2 DEFAULT NULL
   ,P_NUM_IDEN      VARCHAR2 DEFAULT NULL
   ,P_NUMERO_CUENTA NUMBER DEFAULT NULL
   ,P_CONSECUTIVO   NUMBER DEFAULT NULL
   ,io_cursor       IN OUT O_CURSOR);
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
    P_USUARIO           		          VARCHAR2,
    P_TERMINAL           		          VARCHAR2,
    P_MEDIO_RECEPCION                 VARCHAR2,
    P_DETALLE_MEDIO_RECEPCION         VARCHAR2,
    P_TIPO_ORIGEN_PAGO                VARCHAR2,
    P_PAGAR_A                         VARCHAR2,
    P_MONTO                           NUMBER,
    P_FECHA_INICIO                    VARCHAR2,
    P_FECHA_FIN                       VARCHAR2,
    P_DIA_EJECUCION                   VARCHAR2,
    P_PERIODO                         VARCHAR2,
    P_CONSECUTIVO                     IN OUT NUMBER);
--------------------------------------------------------------------------------

PROCEDURE InsertarInstPagoDividendoDet
   (P_CLI_PER_NUM_IDEN                VARCHAR2,
    P_CLI_PER_TID_CODIGO              VARCHAR2,
    P_CCC_NUMERO_CUENTA               NUMBER,
    P_ENA_MNEMONICO                   VARCHAR2,
	  P_CONSECUTIVO                     NUMBER);

--------------------------------------------------------------------------------

PROCEDURE ObtenerInstPagoDividendoDet
   (P_CONSECUTIVO                     NUMBER,
    io_cursor  IN OUT O_CURSOR);

--------------------------------------------------------------------------------

PROCEDURE InactivarInstPagoDividendo
   (P_CONSECUTIVO                     NUMBER);

--------------------------------------------------------------------------------

PROCEDURE PROCESO_NOCTURNO;

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
   ,P_ODP_NEG                 IN OUT NUMBER);

--------------------------------------------------------------------------------

PROCEDURE ORDEN_FONDO_NOCTURNO
   (R_IPD INSTRUCCIONES_PAGOS_DIVIDENDOS%ROWTYPE
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
   ,P_DESCRIPCION         OUT VARCHAR2);


--------------------------------------------------------------------------------

PROCEDURE ABONO_CUENTA_NOCTURNO
   (P_CCC_CLI_PER_NUM_IDEN   VARCHAR2
   ,P_CCC_CLI_PER_TID_CODIGO VARCHAR2
   ,P_CCC_NUMERO_CUENTA      NUMBER
   ,P_SUC_CODIGO             NUMBER
   ,P_PER_NOMBRE_USUARIO     VARCHAR2
   ,P_CONSECUTIVO            NUMBER
   ,P_MONTO_POR_CAUSAR       NUMBER);

--------------------------------------------------------------------------------

PROCEDURE MARCAR_MCC_INSTRUCCION_PAGO
   (P_CLI_PER_NUM_IDEN VARCHAR2
   ,P_CLI_PER_TID_CODIGO VARCHAR2
   ,P_CCC_NUMERO_CUENTA NUMBER
   ,P_CONSECUTIVO NUMBER
   ,P_TIPO_INSTRUCCION_PAGO VARCHAR2);
--------------------------------------------------------------------------------

PROCEDURE MAIL_PERFIL_RIESGO;

--------------------------------------------------------------------------------
FUNCTION FN_SALDO_DIV_CLIENTE
   ( P_IPD_CONS INSTRUCCIONES_PAGOS_DIVIDENDOS.IPD_CONSECUTIVO%TYPE
    ) RETURN NUMBER;
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
                );
--------------------------------------------------------------------------------
PROCEDURE PR_QUITAR_MARCA_MCC
                ( P_ODP_CONS    ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_ODP_SUC     ORDENES_DE_PAGO.ODP_SUC_CODIGO%TYPE DEFAULT NULL
                 ,P_ODP_NEG     ORDENES_DE_PAGO.ODP_NEG_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_OFO_CONS    ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE DEFAULT NULL
                 ,P_OFO_SUC     ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE DEFAULT NULL
                );

--------------------------------------------------------------------------------


PROCEDURE PR_MARCAR_SALDO_CERO
              (P_CLI_PER_NUM_IDEN VARCHAR2
              ,P_CLI_PER_TID_CODIGO VARCHAR2
              ,P_CCC_NUMERO_CUENTA NUMBER);

FUNCTION FN_VALIDA_SALDO_AV (P_CLI_NUM_IDEN      IN  CLIENTES.CLI_PER_NUM_IDEN%TYPE
                            ,P_CLI_TID_CODIGO    IN  CLIENTES.CLI_PER_TID_CODIGO%TYPE
                            ,P_CUENTA            IN  CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE)
                            RETURN VARCHAR2;


FUNCTION FN_MONTO_MAX_ODP   (P_CLI_NUM_IDEN      IN  CLIENTES.CLI_PER_NUM_IDEN%TYPE
                            ,P_CLI_TID_CODIGO    IN  CLIENTES.CLI_PER_TID_CODIGO%TYPE)
                            RETURN NUMBER;

--------------------------------------------------------------------------------

PROCEDURE PROCESO_PAGOS_MASIVOS_DIV (P_SEC                IN NUMBER
                                    ,P_PER_NUM_IDEN       IN VARCHAR2
                                    ,P_PER_TID_CODIGO     IN VARCHAR2
                                    ,P_CCC_NUMERO_CUENTA  IN NUMBER
                                    ,P_FUG_ISI_MNEMONICO  IN VARCHAR2
                                    ,P_CLI_EXCENTO_DXM    IN VARCHAR2
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
                                      ,P_FAV_CONSECUTIVO IN NUMBER DEFAULT NULL);
                                      
--
PROCEDURE PROCESO_PAGOS_MASIVOS_DIV_M (P_SEC                IN NUMBER
                                    ,P_PER_NUM_IDEN       IN VARCHAR2
                                    ,P_PER_TID_CODIGO     IN VARCHAR2
                                    ,P_CCC_NUMERO_CUENTA  IN NUMBER
                                    ,P_FUG_ISI_MNEMONICO  IN VARCHAR2
                                    ,P_CLI_EXCENTO_DXM    IN VARCHAR2
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
                                      ,P_FAV_CONSECUTIVO IN NUMBER DEFAULT NULL);                                      
--

PROCEDURE PROCESO_PAGOS_MASIVOS_DIV ;

PROCEDURE ORDENES_PAGO_PROC_MASIVO (P_ORIGEN_CLIENTE VARCHAR2
                                   ,P_TIPO_ORDEN VARCHAR2 DEFAULT 'PAG'
                                   ,P_TIPO_EMISOR VARCHAR2 DEFAULT 'E');

PROCEDURE REPROCESO_PAGOS_MASIVOS_DIV;

PROCEDURE PR_PAGOS_MASIVOS_DIV_ECOPETROL;

PROCEDURE PR_PAMADI_AJUMAN;

PROCEDURE PR_PAMADI_AJUMAN (P_PROCESO_M VARCHAR2);

PROCEDURE PR_APLICA_RECHAZO (P_ODP_CONSECUTIVO      IN NUMBER
                            ,P_PEL_ODP_CONSECUTIVO  IN NUMBER
                            ,P_RPAE_CONSECUTIVO			IN NUMBER
                            ,P_INS								  IN VARCHAR2
                            ,P_CONSECUTIVO				  IN NUMBER);

FUNCTION FN_SALDO_ADMON_VALORES (P_CLI_NUM_IDEN      IN  CLIENTES.CLI_PER_NUM_IDEN%TYPE
                                 ,P_CLI_TID_CODIGO    IN  CLIENTES.CLI_PER_TID_CODIGO%TYPE
                                 ,P_CUENTA            IN  CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
                                 ,P_SALDO_RECALCULADO IN  VARCHAR2
                                 ,P_SALDO_ODP         OUT CUENTAS_CLIENTE_CORREDORES.CCC_SALDO_CAPITAL%TYPE) RETURN NUMBER;

END P_PAGOS_DIVIDENDOS;

/

  GRANT EXECUTE ON "PROD"."P_PAGOS_DIVIDENDOS" TO "COE_RECURSOS";
