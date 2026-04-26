--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_ORDENES_FONDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_ORDENES_FONDOS" IS
/************************************************************************************
***   PROCEDIMIENTOS PARA ORDENES DE FONDOS:                                     ****
***             - Confirmacion                                                   ****
************************************************************************************/
TYPE lista_compartimentos IS RECORD
(FON_CODIGO           FONDOS.FON_CODIGO%TYPE
,PORCENTAJE           MVTOS_DIARIOS_COMPARTIMENTOS.MDC_PORCENTAJE%TYPE
,PORCENTAJE_COMISION  PARAMETROS_FONDOS.PFO_RANGO_MIN_NUMBER%TYPE);
TYPE t_lista_compartimentos IS TABLE OF lista_compartimentos  INDEX BY BINARY_INTEGER;
r_t_lista_compartimentos  t_lista_compartimentos;
   -- Procedimiento para confirmar la orden
PROCEDURE CONFIRMA_ORDEN
   (P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,P_COMPARTIMENTO                    VARCHAR2 DEFAULT NULL
   ,P_FON_PADRE_COMPARTIMENTO          VARCHAR2 DEFAULT NULL
   ,P_VALIDAR_MATRIZ                   VARCHAR2 DEFAULT NULL
   ,P_CONPENSA_APT                     VARCHAR2 DEFAULT NULL); --WGONZALEZ VAGTUD944-3
PROCEDURE VERIFICA_TRANSFERENCIA
   (P_OFO_OFO_SUC_CODIGO               NUMBER
   ,P_OFO_OFO_CONSECUTIVO              NUMBER
   ,P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,P_OFO_EOF_CODIGO                   VARCHAR2
   ,P_OFO_CFO_CCC_CLI_PER_NUM_IDEN     VARCHAR2
   ,P_TIPO                             IN  VARCHAR2
   ,P_COND                             OUT VARCHAR2);
PROCEDURE INSERTAR_MOVIMIENTO_CORREDORES
   (IDENTIFICACION                     VARCHAR2
   ,TIPO                               VARCHAR2
   ,CUENTA                             NUMBER
   ,MONTO                              NUMBER
   ,ORDEN_FONDOS                       NUMBER
   ,SUCURSAL                           NUMBER
   ,TIPO_MOVIMIENTO                    VARCHAR2);
PROCEDURE INSERTAR_MOVIMIENTO_CORREDORES(P_OFO_CFO_CCC_CLI_PER_NUM_IDEN    VARCHAR2
                                        ,P_OFO_CFO_CCC_CLI_PER_TID_CODI    VARCHAR2
                                        ,P_OFO_CFO_CCC_NUMERO_CUENTA       NUMBER
                                        ,P_OFO_CFO_FON_CODIGO              VARCHAR2
                                        ,P_OFO_CFO_CODIGO                  NUMBER
                                        ,MONTO                 NUMBER
                                        ,ORDEN_FONDOS          NUMBER
                                        ,SUCURSAL              NUMBER
                                        ,FECHA                 DATE
                                        ,TIPO_MOVIMIENTO       VARCHAR2);
PROCEDURE MOVIMIENTO_BANCARIO
   (P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,P_OFO_CFO_FON_CODIGO               VARCHAR2
   ,P_OFO_TTO_TOF_CODIGO               VARCHAR2
   ,P_EXC                              VARCHAR2
   ,P_TIPO                             VARCHAR2
   ,P_LLAMADO_FF_FG                    VARCHAR2 DEFAULT NULL
   ,P_FECHA_EJECUCION                  DATE     DEFAULT NULL
   ,P_COMPARTIMENTO_B                  VARCHAR2 DEFAULT NULL
   ,P_FON_PADRE_COMPARTIMENTO_B        VARCHAR2 DEFAULT NULL
   ,P_ESTADO                           VARCHAR2 DEFAULT 'APR'
   ,P_OFO_CANAL                        VARCHAR2 DEFAULT NULL
   ,P_CONPENSA_APT                     VARCHAR2 DEFAULT NULL); --WGONZALEZ VAGTUD944-3
PROCEDURE ABONO_CARGO_CUENTA
   (P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,P_OFO_CFO_CCC_CLI_PER_NUM_IDEN     VARCHAR2
   ,P_OFO_CFO_CCC_CLI_PER_TID_COD      VARCHAR2
   ,P_OFO_CFO_CCC_NUMERO_CUENTA        NUMBER
   ,P_OFO_CFO_FON_CODIGO               VARCHAR2
   ,P_OFO_CFO_CODIGO                   NUMBER
   ,P_EXC                              VARCHAR2
   ,P_TIPO                             VARCHAR2
   ,P_TIPO_MOVIMIENTO                  VARCHAR2
   ,P_LLAMADO_FF_FG                    VARCHAR2 DEFAULT NULL
   ,P_FECHA_EJECUCION                  DATE     DEFAULT NULL);
PROCEDURE TRASLADO_CLIENTE_EXEC
   (P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,P_OFO_CFO_CCC_CLI_PER_NUM_IDEN     VARCHAR2
   ,P_OFO_CFO_CCC_CLI_PER_TID_COD      VARCHAR2
   ,P_OFO_CFO_CCC_NUMERO_CUENTA        NUMBER
   ,P_OFO_CFO_FON_CODIGO               VARCHAR2
   ,P_OFO_CFO_CODIGO                   NUMBER
   ,P_VER_IMPUESTO                     IN OUT VARCHAR2);
FUNCTION MONTO_ORDENES_PAGO
   (P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,TIPO_FONDO                         VARCHAR2)
RETURN NUMBER;
PROCEDURE APROBAR_ORDENES_PAGO
   (P_OFO_SUC_CODIGO                   NUMBER
   ,P_OFO_CONSECUTIVO                  NUMBER
   ,P_TIPO_RETIRO                      VARCHAR2
   ,P_T0                               VARCHAR2);
PROCEDURE REINTEGRO_ADMON_COMISION
   (P_FON_CODIGO                       VARCHAR2
   ,P_FECHA_PROCESO                    DATE
   ,P_TIPO_PROCESO                     VARCHAR2
   ,P_VALOR_MOVIMIENTO                 OUT NUMBER);
PROCEDURE P_SALDOS_NO_DISPONIBLES(P_FECHA_PROCESO DATE DEFAULT NULL);
PROCEDURE PR_ANULAR_PAGOS_TESORE ( P_TBC_SUC_CODIGO      TRANSFERENCIAS_BANCARIAS.TBC_SUC_CODIGO%TYPE,
                                   P_TBC_NEG_CONSECUTIVO TRANSFERENCIAS_BANCARIAS.TBC_NEG_CONSECUTIVO%TYPE,
                                   P_TBC_CONSECUTIVO     TRANSFERENCIAS_BANCARIAS.TBC_CONSECUTIVO%TYPE,
                                   P_MENSAJE             OUT VARCHAR2);
PROCEDURE PR_ANULAR_PAGOS_TESORE_AUTO ( P_TBC_SUC_CODIGO      TRANSFERENCIAS_BANCARIAS.TBC_SUC_CODIGO%TYPE,
                                       P_TBC_NEG_CONSECUTIVO TRANSFERENCIAS_BANCARIAS.TBC_NEG_CONSECUTIVO%TYPE,
                                       P_TBC_CONSECUTIVO     TRANSFERENCIAS_BANCARIAS.TBC_CONSECUTIVO%TYPE,
                                       P_RAZON_REVERSION     TRANSFERENCIAS_BANCARIAS.TBC_RAZON_REVERSION%TYPE,
                                       P_MENSAJE             OUT VARCHAR2);
FUNCTION  F_VALIDA_ORDENES_FONDOS(P_CLI_PER_NUM_IDEN   VARCHAR,
                                  P_CLI_PER_TID_CODIGO VARCHAR2,
                                  P_CCC_NUMERO_CUENTA  NUMBER,
                                  P_CFO_FON_CODIGO     VARCHAR2,
                                  P_CFO_CODIGO         NUMBER,
                                  P_FECHA              DATE) RETURN BOOLEAN;
PROCEDURE P_OBTIENE_PENALIZACION(P_FON_CODIGO       IN VARCHAR2
                                ,P_FECHA_INICIAL    IN DATE
                                ,P_FECHA_FINAL      IN DATE
                                ,P_PEN_CONSECUTIVO  OUT NUMBER
                                ,P_PEN_PORCENTAJE   OUT NUMBER);
PROCEDURE P_ACTUALIZA_PORCENTAJE(P_FON_CODIGO    IN VARCHAR2,
                                 P_FECHA_PROCESO IN DATE);
PROCEDURE P_CALCULO_PENALIZACION(P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2
                                ,P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN VARCHAR2
                                ,P_OFO_CFO_CCC_NUMERO_CUENTA      IN NUMBER
                                ,P_OFO_CFO_FON_CODIGO             IN VARCHAR2
                                ,P_OFO_CFO_CODIGO                 IN NUMBER
                                ,P_FECHA_PROCESO                  IN DATE
                                ,P_UNIDADES_MOVIMIENTO            IN NUMBER
                                ,P_TIPO_OPERACION                 IN VARCHAR2
                                ,P_VALOR_PENALIZACION             IN OUT NUMBER
                                ,P_UNIDADES_PENALIZACION          IN OUT NUMBER);
PROCEDURE P_UPD_PENALIZACION(P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2
                            ,P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN VARCHAR2
                            ,P_OFO_CFO_CCC_NUMERO_CUENTA      IN NUMBER
                            ,P_OFO_CFO_FON_CODIGO             IN VARCHAR2
                            ,P_OFO_CFO_CODIGO                 IN NUMBER
                            ,P_FECHA_PROCESO                  IN DATE
                            ,P_UNIDADES_MOVIMIENTO            IN NUMBER
                            ,P_TIPO_OPERACION                 IN VARCHAR2);
PROCEDURE P_INS_MOVIMIENTOS_FONDOS(P_FECHA_PROCESO                  IN DATE
                                  ,P_TIPO_ORDEN                     IN VARCHAR2
                                  ,P_OFO_SUC_CODIGO                 IN NUMBER
                                  ,P_OFO_CONSECUTIVO                IN NUMBER
                                  ,P_OFO_MONTO                      IN OUT NUMBER
                                  ,P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2
                                  ,P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN     VARCHAR2
                                  ,P_OFO_CFO_CCC_NUMERO_CUENTA      IN     NUMBER
                                  ,P_OFO_CFO_FON_CODIGO             IN     VARCHAR2
                                  ,P_OFO_CFO_CODIGO                 IN     NUMBER
                                  ,P_OFO_FECHA_EJECUCION            IN OUT DATE
                                  ,P_EXC                            IN OUT VARCHAR2
                                  ,P_OFO_MONTO_CARGO_ABONO_CUENTA   IN OUT NUMBER
                                  ,P_FECHA_ACTUALIZA_MCC            IN OUT DATE
                                  ,P_FECHA                          IN OUT DATE
                                  ,P_OFO_REGISTRO_AUTOMATICO        IN     VARCHAR2
                                  ,P_OFO_TTO_TOF_CODIGO             IN     VARCHAR2
                                  ,P_OFO_FECHA_CAPTURA              IN     DATE);
PROCEDURE INSERTAR_REGISTRO(      P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                  P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN VARCHAR2,
                                  P_OFO_CFO_CCC_NUMERO_CUENTA      IN NUMBER,
                                  P_OFO_CFO_FON_CODIGO             IN VARCHAR2,
                                  P_OFO_CFO_CODIGO                 IN NUMBER,
                                  P_OFO_FECHA_EJECUCION            IN OUT DATE,
                                  P_FECHA_ACTUALIZA_MCC            IN OUT DATE,
                                  P_OFO_TTO_TOF_CODIGO             IN VARCHAR2,
                                  P_FECHA                          IN OUT DATE,
                                  P_TMF_MNEMONICO               IN VARCHAR2,
                                  P_CAPITAL                     IN NUMBER,
                                  P_UNIDADES_MOVIMIENTO         IN NUMBER,
                                  P_RENDIMIENTOS_RF             IN NUMBER,
                                  P_RENDIMIENTOS_RV             IN NUMBER,
                                  P_RETEFUENTE_MOVIMIENTO       IN NUMBER,
                                  P_SALDO_RENDIMIENTOS_RF       IN NUMBER,
                                  P_SALDO_RENDIMIENTOS_RV       IN NUMBER,
                                  P_SALDO_RETEFUENTE            IN NUMBER,
                                  P_SALDO_CAPITAL               IN NUMBER,
                                  P_SALDO_INVER                 IN NUMBER,
                                  P_SALDO_UNIDADES              IN NUMBER,
                                  P_INTERESES_PAGADOS           IN NUMBER,
                                  P_SALDO_INTERESES_PAGADOS     IN NUMBER,
                                  P_SUC_CODIGO                  IN NUMBER,
                                  P_CONSECUTIVO                 IN NUMBER,
                                  P_TASA_PROMEDIO               IN NUMBER,
                                  P_TIPO_ORDEN                  IN VARCHAR2,
                                  P_AUTOMATICO          IN VARCHAR2,
                                  P_IND_SALTO                   IN VARCHAR2 DEFAULT NULL);
PROCEDURE RECALCULO_MONTO_ORDEN(P_SALDO                          IN     NUMBER
                               ,P_OFO_SUC_CODIGO                 IN     NUMBER
                               ,P_OFO_CONSECUTIVO                IN     NUMBER
                               ,P_OFO_MONTO                      IN     NUMBER
                               ,P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN     VARCHAR2
                               ,P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN     VARCHAR2
                               ,P_OFO_CFO_CCC_NUMERO_CUENTA      IN     NUMBER
                               ,P_OFO_CFO_FON_CODIGO             IN     VARCHAR2
                               ,P_OFO_CFO_CODIGO                 IN     NUMBER
                               ,P_OFO_FECHA_CAPTURA              IN     DATE
                               ,P_VALOR_IMPUESTO                 IN     NUMBER
                               ,P_VALOR_PENALIZACION             IN     NUMBER
                               ,P_UNIDADES_PENALIZACION          IN     NUMBER
                               ,P_VER_IMPUESTO                   IN     VARCHAR2
                               ,P_VFO_VALOR                      IN     NUMBER
                               ,P_OFO_MONTO_ORDEN                IN OUT NUMBER
                               ,P_OFO_MONTO_CARGO_ABONO_CUENTA   IN OUT NUMBER
                               ,P_IMPUESTO_ABONO_CUENTA          IN OUT NUMBER
                               ,P_IMPUESTO_PAGOS                 IN OUT NUMBER
                               ,P_OFO_MONTO_ORDEN_UNIDADES       IN OUT NUMBER
                               ,P_IMPUESTO_ABONO_CUENTA_UNIDAD   IN OUT NUMBER
                               ,P_IMPUESTO_PAGOS_UNIDADES        IN OUT NUMBER
                               ,P_TIENE_SEGUNDO                  IN     VARCHAR2
                               ,P_RENDIMIENTOS                   IN     NUMBER);
PROCEDURE P_CALCULO_IMPUESTOS(P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN     VARCHAR2
                             ,P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN     VARCHAR2
                             ,P_OFO_CFO_CCC_NUMERO_CUENTA      IN     NUMBER
                             ,P_OFO_CFO_FON_CODIGO             IN     VARCHAR2
                             ,P_OFO_CFO_CODIGO                 IN     NUMBER
                             ,P_OFO_CONSECUTIVO                IN     NUMBER
                             ,P_OFO_SUC_CODIGO                 IN     NUMBER
                             ,P_MONTO_ABONO_CUENTA             IN     NUMBER
                             ,P_VALOR_IMPUESTOS                IN OUT NUMBER
                             ,P_VALOR_IBA                      IN OUT NUMBER  --  4XMIL ORDENES DE PAGO
                             ,P_VALOR_IBC                      IN OUT NUMBER); -- 4XMIL ABONO CUENTA
PROCEDURE P_TOPES_INV_COMPARTIMENTOS(P_FON_CODIGO        VARCHAR2,
                                     P_SALARIO_MINIMO    NUMBER,
                                     P_MINIMO_INVERSION  OUT NUMBER,
                                     P_MAXIMO_INVERSION  OUT NUMBER,
                                     P_VALIDA_SIN_TOPE   OUT VARCHAR2);
PROCEDURE P_ORDEN_REDIMIR_TRAMO (P_OFO_CFO_CCC_CLI_PER_NUM_IDEN   IN     VARCHAR2
                                ,P_OFO_CFO_CCC_CLI_PER_TID_CODI   IN     VARCHAR2
                                ,P_OFO_CFO_CCC_NUMERO_CUENTA      IN     NUMBER
                                ,P_OFO_CFO_FON_CODIGO             IN     VARCHAR2
                                ,P_OFO_CFO_CODIGO                 IN     NUMBER
                                ,P_VFO_VALOR_UNIDAD               IN     NUMBER
                                ,P_EXC                            IN     VARCHAR2
                                ,P_VER_IMPUESTO                   IN     VARCHAR2
                                ,P_OFO_SUC_CODIGO                 IN     NUMBER
                                ,P_OFO_CONSECUTIVO                IN     NUMBER
                                ,P_CON_VALOR                      IN     NUMBER
                                ,P_OFO_FECHA_EJECUCION            IN OUT DATE
                                ,P_FECHA_ACTUALIZA_MCC            IN OUT DATE
                                ,P_FECHA                          IN OUT DATE);
PROCEDURE P_VALIDA_PARAMETROS_COMP (P_FON_CODIGO          IN VARCHAR
                                   ,P_PAR_CODIGO          IN NUMBER
                                   ,P_PFO_RANGO_MIN_CHAR  IN OUT VARCHAR2);
PROCEDURE P_RETORNA_FONDOS_COM  (P_FECHA_EJECUCION      DATE,
                                 P_FON_PADRE            VARCHAR2,
                                 P_LISTA_FONDO_COMP     IN OUT P_ORDENES_FONDOS.t_lista_compartimentos);
PROCEDURE P_PORCENTAJE_COMPARTIMENTO(P_FECHA_EJECUCION DATE DEFAULT NULL,P_FONDO VARCHAR2,P_FON_PADRE VARCHAR2);
PROCEDURE P_MOVIMIENTOS_COMPARTIMENTOS(P_FECHA_EJECUCION DATE DEFAULT NULL,P_FONDO_PADRE VARCHAR2);
PROCEDURE VERIF_ABONO_CARGO_CUENTA
   (IDENTIFICACION                     VARCHAR2
   ,TIPO                               VARCHAR2
   ,CUENTA                             NUMBER
   ,MONTO                              NUMBER
   ,ORDEN_FONDOS                       NUMBER
   ,SUCURSAL                           NUMBER
   ,TIPO_MOVIMIENTO                    VARCHAR2);
PROCEDURE VERIF_ABONO_CARGO_CUENTA_PENAL
   (IDENTIFICACION                     VARCHAR2
   ,TIPO                               VARCHAR2
   ,CUENTA                             NUMBER
   ,MONTO                              NUMBER
   ,ORDEN_FONDOS                       NUMBER
   ,SUCURSAL                           NUMBER
   ,TIPO_MOVIMIENTO                    VARCHAR2);
PROCEDURE INSERTAR_MOVIMIENTO_CORR_CAAB
   (IDENTIFICACION                     VARCHAR2
   ,TIPO                               VARCHAR2
   ,CUENTA                             NUMBER
   ,MONTO                              NUMBER
   ,ORDEN_FONDOS                       NUMBER
   ,SUCURSAL                           NUMBER
   ,TIPO_MOVIMIENTO                    VARCHAR2);
PROCEDURE LLENADO_GL_MAX_MCF
   (P_QUERY                            VARCHAR2);
PROCEDURE INSERTAR_MOV_TESORERIA_FONDOS
   (P_MTF_CBF_NUMERO_CUENTA            IN VARCHAR2
    ,P_MTF_CBF_BAN_CODIGO              IN NUMBER
    ,P_MTF_CBF_FON_CODIGO              IN VARCHAR2
    ,P_MTF_TTE_MNEMONICO               IN VARCHAR2
    ,P_MTF_FECHA                       IN DATE
    ,P_MTF_DEBITO                      IN NUMBER DEFAULT 0
    ,P_MTF_CREDITO                     IN NUMBER DEFAULT 0
    ,P_MTF_DESCRIPCION                 IN VARCHAR2
  ,P_VALIDA_CTA_UNICA                IN VARCHAR2 DEFAULT 'S'
   );


/**** NUEVAS FUNCIONALIDADES DE PAGO 19-ABR-2013***/
PROCEDURE PR_CREAR_APORTE
   ( P_CLI_NUM_IDEN        IN      CUENTAS_FONDOS.CFO_CCC_CLI_PER_NUM_IDEN%TYPE
    ,P_CLI_TID_CODIGO      IN      CUENTAS_FONDOS.CFO_CCC_CLI_PER_TID_CODIGO%TYPE
    ,P_CUENTA              IN      CUENTAS_FONDOS.CFO_CCC_NUMERO_CUENTA%TYPE
    ,P_FON_CODIGO          IN      CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE
    ,P_ENVIAR_EXTRACTO     IN      CUENTAS_FONDOS.CFO_ENVIAR_EXTRACTO%TYPE DEFAULT 'S'
    ,P_ENVIAR_REC_DERECHO  IN      CUENTAS_FONDOS.CFO_ENVIAR_REC_DERECHO%TYPE DEFAULT 'S'
    ,P_REFERIDO_FG         IN      CUENTAS_FONDOS.CFO_REFERIDO_FG%TYPE DEFAULT 'N'
    ,P_CFO_CODIGO          IN  OUT CUENTAS_FONDOS.CFO_CODIGO%TYPE
    ,P_OFDA_CODIGO         IN      OFICINAS_DAVIVIENDA.OFDA_CODIGO%TYPE DEFAULT NULL);



PROCEDURE PR_VALIDAR_COLOCACION_ORDEN
   ( P_CLI_NUM_IDEN        IN      CUENTAS_FONDOS.CFO_CCC_CLI_PER_NUM_IDEN%TYPE
    ,P_CLI_TID_CODIGO      IN      CUENTAS_FONDOS.CFO_CCC_CLI_PER_TID_CODIGO%TYPE
    ,P_CUENTA              IN      CUENTAS_FONDOS.CFO_CCC_NUMERO_CUENTA%TYPE
    ,P_APORTE              IN      CUENTAS_FONDOS.CFO_CODIGO%TYPE
    ,P_FON_CODIGO          IN      CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE
    ,P_TIPO_ORDEN          IN      ORDENES_FONDOS.OFO_TTO_TOF_CODIGO%TYPE
    ,P_MONTO_ORDEN         IN      ORDENES_FONDOS.OFO_MONTO%TYPE
    ,P_PRODUCTO            IN      PRODUCTOS.PRO_MNEMONICO%TYPE
    ,P_CANAL               IN      CANALES.CNL_CONSECUTIVO%TYPE DEFAULT NULL);

PROCEDURE PR_CREAR_ORDEN_FONDOS
   (P_SUCURSAL                   IN ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE
   ,P_CLI_NUM_IDEN               IN ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_NUM_IDEN%TYPE
   ,P_CLI_TID_CODIGO             IN ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_TID_CODIGO%TYPE
   ,P_CUENTA                     IN ORDENES_FONDOS.OFO_CFO_CCC_NUMERO_CUENTA%TYPE
   ,P_FON_CODIGO                 IN ORDENES_FONDOS.OFO_CFO_FON_CODIGO%TYPE
   ,P_CFO_CODIGO                 IN ORDENES_FONDOS.OFO_CFO_CODIGO%TYPE
   ,P_PER_NUM_IDEN               IN ORDENES_FONDOS.OFO_PER_NUM_IDEN%TYPE
   ,P_PER_TID_CODIGO             IN ORDENES_FONDOS.OFO_PER_TID_CODIGO%TYPE
   ,P_TOF_CODIGO                 IN ORDENES_FONDOS.OFO_TTO_TOF_CODIGO%TYPE
   ,P_TIT_CODIGO                 IN ORDENES_FONDOS.OFO_TTO_TIT_CODIGO%TYPE
   ,P_MONTO                      IN ORDENES_FONDOS.OFO_MONTO%TYPE
   ,P_CARGO_ABONO_CUENTA         IN ORDENES_FONDOS.OFO_CARGO_ABONO_CUENTA%TYPE
   ,P_MONTO_CARGO_ABONO_CUENTA   IN ORDENES_FONDOS.OFO_MONTO_CARGO_ABONO_CUENTA%TYPE
   ,P_MONTO_ABONO_CUENTA_DOLARES IN ORDENES_FONDOS.OFO_MONTO_ABONO_CUENTA_DOLARES%TYPE
   ,P_FECHA_EJECUCION            IN ORDENES_FONDOS.OFO_FECHA_EJECUCION%TYPE
   ,P_IMPRIME_REC_DERECHOS       IN ORDENES_FONDOS.OFO_IMPRIME_REC_DERECHOS%TYPE
   ,P_PER_NUM_IDEN_COLOCO        IN ORDENES_FONDOS.OFO_PER_NUM_IDEN_COLOCO%TYPE
   ,P_PER_TID_CODIGO_COLOCO      IN ORDENES_FONDOS.OFO_PER_TID_CODIGO_COLOCO%TYPE
   ,P_ORIGEN_RECURSOS            IN ORDENES_FONDOS.OFO_ORIGEN_RECURSOS%TYPE
   ,P_INSERTA_DAU                IN VARCHAR2 -- Las siguientes tres variables es para saber si se debe hacer
   ,P_INSERTA_ORR                IN VARCHAR2 -- insert en las tablas del short o no los valores con S o N
   ,P_INSERTA_DAA                IN VARCHAR2 -- no se coloco ordenes de pago porque tiene su propio modulo de creacion de orden
   ,P_PRODUCTO                   IN PRODUCTOS.PRO_MNEMONICO%TYPE
   ,P_ORDEN_ORIGEN               IN ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE
   ,P_ORDEN_FONDO                IN OUT ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE
   ,P_CARGO_ABONO_MNEMONICO      IN VARCHAR2 DEFAULT NULL
  ,P_PAGO_INMO                  IN VARCHAR2 DEFAULT NULL
   ,P_CANAL                     IN NUMBER DEFAULT NULL
   ,P_OFICINA                   IN NUMBER DEFAULT NULL
   ,P_TALON                     IN NUMBER DEFAULT NULL
   );

FUNCTION FN_TRASLADO_CLIENTE_EXEC(P_OFO_SUC_CODIGO            IN ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE
                              ,P_OFO_CONSECUTIVO              IN ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE
                              ,P_OFO_CFO_CCC_CLI_PER_NUM_IDEN IN ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_NUM_IDEN%TYPE
                              ,P_OFO_CFO_CCC_CLI_PER_TID_CODI IN ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_TID_CODIGO%TYPE
                              ,P_OFO_CFO_CCC_NUMERO_CUENTA    IN ORDENES_FONDOS.OFO_CFO_CCC_NUMERO_CUENTA%TYPE
                              ,P_OFO_CFO_FON_CODIGO           IN ORDENES_FONDOS.OFO_CFO_FON_CODIGO%TYPE
                              ,P_OFO_CFO_CODIGO               IN ORDENES_FONDOS.OFO_CFO_CODIGO%TYPE
                              ,P_PRODUCTO                     IN VARCHAR2 DEFAULT NULL
                              ,P_CANAL                        IN NUMBER DEFAULT NULL) RETURN CHAR;

PROCEDURE PR_CALCULO_GASTOS_OFO(P_CLI_PER_NUM_IDEN   IN  ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_NUM_IDEN%TYPE
                             ,P_CLI_PER_TID_CODIGO IN  ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_TID_CODIGO%TYPE
                             ,P_CUENTA             IN  ORDENES_FONDOS.OFO_CFO_CCC_NUMERO_CUENTA%TYPE
                             ,P_APORTE             IN  ORDENES_FONDOS.OFO_CFO_CODIGO%TYPE
                             ,P_FONDO              IN  ORDENES_FONDOS.OFO_CFO_FON_CODIGO%TYPE
                             ,P_MONTO              IN  ORDENES_FONDOS.OFO_MONTO%TYPE
                             ,P_OPERACION          IN  ORDENES_FONDOS.OFO_TTO_TOF_CODIGO%TYPE
                             ,P_TIPO_PAGO          IN  ORDENES_DE_PAGO.ODP_TPA_MNEMONICO%TYPE
                             ,P_MONTO_PAGO         IN  ORDENES_DE_PAGO.ODP_MONTO_ORDEN%TYPE
                             ,P_COSTOS_ORDEN       OUT ORDENES_FONDOS.OFO_MONTO%TYPE
                             ,P_PENALIZACION       OUT ORDENES_FONDOS.OFO_MONTO%TYPE);

FUNCTION FN_MONTO_GASTOS_OFO(P_SUCURSAL IN  ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE
                            ,P_ORDEN    IN  ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE
                            ,P_CONS     IN  CONSTANTES.CON_VALOR%TYPE) RETURN NUMBER;
PROCEDURE P_VALIDAR_MATRIZ
   (P_PFO_FON_CODIGO     in varchar2
   ,P_PFO_BAN_CODIGO     IN NUMBER
   ,P_MONTO              IN NUMBER
   ,P_HORAS              IN VARCHAR2
   ,P_OPERACION          in varchar2
   ,P_RESPUESTA_MONTO    in OUT varchar2
   ,P_RESPUESTA_HORAS    IN OUT VARCHAR2);


FUNCTION FN_DATABASE
RETURN VARCHAR2;


FUNCTION FN_DIA_TN
   (FECHA_CAPTURA                  DATE
   ,V_DIAS_PAGO                        NUMBER)
RETURN DATE;


PROCEDURE P_ENVIO_NOTIFICACION
   (P_TIPO_OFO     in varchar2
   ,P_ESTADO_OFO    IN VARCHAR2
   ,P_FONDO_OFO    IN VARCHAR2
   ,P_NUM_IDEN_OFO IN VARCHAR2
   ,P_TIP_CODIGO_OFO IN VARCHAR2
   ,P_MONTO_OFO      IN NUMBER
   ,P_CCC_NUM_CUENTA  IN VARCHAR2 );

PROCEDURE P_ENVIO_NOTIFICACION_NOCTURNO;

PROCEDURE PR_CREAR_APORTE_CONVENIO
   ( P_CLI_NUM_IDEN        IN      CUENTAS_FONDOS.CFO_CCC_CLI_PER_NUM_IDEN%TYPE
    ,P_CLI_TID_CODIGO      IN      CUENTAS_FONDOS.CFO_CCC_CLI_PER_TID_CODIGO%TYPE
    ,P_CUENTA              IN      CUENTAS_FONDOS.CFO_CCC_NUMERO_CUENTA%TYPE
    ,P_FON_CODIGO          IN      CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE
    ,P_ENVIAR_EXTRACTO     IN      CUENTAS_FONDOS.CFO_ENVIAR_EXTRACTO%TYPE DEFAULT 'S'
    ,P_ENVIAR_REC_DERECHO  IN      CUENTAS_FONDOS.CFO_ENVIAR_REC_DERECHO%TYPE DEFAULT 'S'
    ,P_REFERIDO_FG         IN      CUENTAS_FONDOS.CFO_REFERIDO_FG%TYPE DEFAULT 'N'
    ,P_CFO_CODIGO          IN  OUT CUENTAS_FONDOS.CFO_CODIGO%TYPE);


PROCEDURE P_VALOR_UNIDAD_COMPARTIMIENTO
    (P_FONDO        IN VARCHAR2,
    P_FECHA         IN DATE,
    VALOR_UNIDAD    OUT NUMBER,
    ACCION          OUT VARCHAR2);

PROCEDURE INSERT_MVTO_CORREDORES_ESPECIE
   (IDENTIFICACION                     VARCHAR2
   ,TIPO                               VARCHAR2
   ,CUENTA                             NUMBER
   ,MONTO                              NUMBER
   ,ORDEN_FONDOS                       NUMBER
   ,SUCURSAL                           NUMBER
   ,TIPO_MOVIMIENTO                    VARCHAR2);

PROCEDURE P_SALDOS_NO_DISPONIBLES_APE(P_FECHA_PROCESO DATE DEFAULT NULL);

PROCEDURE PR_ENVIO_MAIL_UNID_APE (IDENTIFICACION VARCHAR2, TIPO VARCHAR2, F_DESBLOQUEO DATE);
/* ********************************************************* */
  PROCEDURE PR_ANULAR_ORDEN(
      P_OFO_SUC_CODIGO  NUMBER,
      P_OFO_CONSECUTIVO NUMBER,
      P_MENSAJE IN OUT VARCHAR2);
/* ********************************************************* */
  PROCEDURE PR_VALIDA_ANULACION(
      P_ORIGEN IN VARCHAR2,
      P_OFO_SUC_CODIGO  NUMBER,
      P_OFO_CONSECUTIVO NUMBER,
      P_FON_CODIGO      VARCHAR2,
      P_MENSAJE IN OUT VARCHAR2);
/* ********************************************************* */
  PROCEDURE PR_MOVIMIENTO_BANCARIO(
      P_TIPO            VARCHAR2,
      P_OFO_CONSECUTIVO NUMBER,
      P_OFO_SUC_CODIGO  NUMBER);
/* ********************************************************* */
  PROCEDURE PR_ABONO_CARGO_CUENTA(
      P_TIPO            VARCHAR2,
      P_OFO_CONSECUTIVO NUMBER,
      P_OFO_SUC_CODIGO  NUMBER );
/* ********************************************************* */
  PROCEDURE PR_INSERTAR_MOV_REVERSION(
      P_CLI_PER_NUM_IDEN   VARCHAR2 ,
      P_CLI_PER_TID_CODIGO VARCHAR2 ,
      P_NUMERO_CUENTA      NUMBER ,
      P_TOF_CODIGO         VARCHAR2 ,
      P_MONTO              NUMBER ,
      P_AACO_CACO          VARCHAR2 ,
      P_TMC_MNEMONICO      VARCHAR2 ,
      P_MCC_MONTO          NUMBER ,
      P_MCC_MONTO_CARTERA  NUMBER ,
      P_OFO_SUC_CODIGO     NUMBER ,
      P_OFO_CONSECUTIVO    NUMBER);
/* ********************************************************* */
  PROCEDURE PR_VERIF_PAGOS_ADMON_VALORES
    (
      P_OFO_SUC_CODIGO  NUMBER ,
      P_OFO_CONSECUTIVO NUMBER
    );
/* ********************************************************* */
  PROCEDURE PR_VERIF_PAGOS_DERIVADOS(
      P_OFO_SUC_CODIGO  NUMBER ,
      P_OFO_CONSECUTIVO NUMBER);
/* ********************************************************* */
  PROCEDURE PR_VERIF_PAGOS_DIVISAS(
      P_OFO_SUC_CODIGO  NUMBER ,
      P_OFO_CONSECUTIVO NUMBER);
/* ********************************************************* */
  PROCEDURE PR_VERIF_PAGOS_OPE_BURSATIL(
      P_OFO_SUC_CODIGO  NUMBER ,
      P_OFO_CONSECUTIVO NUMBER);
/* ********************************************************* */
  PROCEDURE PR_COMPENSAR_CARTERAS_DAV(P_OFO_CONSECUTIVO     NUMBER,
                             P_OFO_SUC_CODIGO               NUMBER,
                             P_OFO_FON_CODIGO               VARCHAR2,
                             P_OFO_CONSECUTIVO2             NUMBER,
                             P_OFO_SUC_CODIGO2              NUMBER,
                             P_OFO_FON_CODIGO2              VARCHAR2,
                             P_MONTO_COMPENSAR              NUMBER);
/* ********************************************************* */
 PROCEDURE PR_ANULAR_ORDEN_DAV(
      P_OFO_SUC_CODIGO  NUMBER,
      P_OFO_CONSECUTIVO NUMBER,
      P_MENSAJE IN OUT VARCHAR2);

/* ********************************************************* */
   -- MES - VAGTUD854 - INCREMENTOS FONDOS CON PACTO DE PERMANENCIA
   -- FUNCION QUE VALIDA SI UN FONDO TIENE PACTO DE PERMANENCIA FIJA
   FUNCTION FN_VALIDA_PACTO
           (P_FONDO     IN VARCHAR2
           ) RETURN VARCHAR2;

/* ********************************************************* */
   -- FUNCION QUE VALIDA SI ANTES DE GENERAR UN INCREMENTO EL APORTE SIGUE DISPONIBLE
   -- NO TIENE UNA ORDEN PENDIENTE
   FUNCTION FN_VALIDA_APORTE_PACTO
            (P_NID    IN VARCHAR2
        ,P_TID    IN VARCHAR2
        ,P_CTA    IN NUMBER
        ,P_FONDO  IN VARCHAR2
        ,P_APORTE   IN VARCHAR2
        ) RETURN VARCHAR2;

/* ********************************************************* */
PROCEDURE PR_DISPONIBLE_ANTICIPO (P_CFO_CCC_CLI_PER_NUM_IDEN VARCHAR2,
                                  P_CFO_CCC_CLI_PER_TID_CODIGO VARCHAR2,
                                  P_CFO_CCC_NUMERO_CUENTA NUMBER ,
                                  P_cfo_fon_codigo VARCHAR2,
                                  P_cfo_codigo NUMBER,
                                  P_BK_CUEFON_SALDO NUMBER,
                                  BK_CUEFON_DISPONIBLE_ANTICIPO out number,
                                  P_RETENCION_FUENTE OUT NUMBER );

FUNCTION FN_CALCULO_RETENCION_FUENTE (P_CFO_CCC_CLI_PER_NUM_IDEN VARCHAR2,
                                  P_CFO_CCC_CLI_PER_TID_CODIGO VARCHAR2,
                                  P_CFO_CCC_NUMERO_CUENTA NUMBER ,
                                  P_cfo_fon_codigo VARCHAR2,
                                  P_cfo_codigo NUMBER,
                                  P_BK_CUEFON_SALDO NUMBER) RETURN NUMBER;

PROCEDURE PR_SALDO_MINIMO (P_CLI_PER_NUM_IDEN   VARCHAR2,
                           P_CLI_PER_TID_CODIGO VARCHAR2,
                           P_NUMERO_CUENTA      NUMBER,
                           P_FON_CODIGO         VARCHAR2,
                           P_CODIGO             NUMBER,
                           TOT_RET             OUT NUMBER,
                           DISPONIBLE_ANTICIPO OUT NUMBER,
                           RETE_FUENTE         OUT NUMBER,
                           SALDO_TOTAL_RETIRO  OUT NUMBER
                           );


/************************************************************************************************
  Author  : VAGTUD861-6.1. Participaciones - Redistribuci¿n de Rendimientos
  Created : 09/10/2020
  Purpose : Esta funcion permite determinar si algun proceso del cierre de fondos inicio
  *************************************************************************************************/
  FUNCTION FN_PROCESO_CIERRE (P_FONDO VARCHAR2,
                              P_FECHA DATE,
                              P_PROCESO NUMBER,
                              P_CAMPO VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;

/************************************************************************************************
  Author  : VAGTUD861-6.1. Participaciones - Redistribuci¿n de Rendimientos
  Created : 09/10/2020
  Purpose : Este procedure permite recalcular los porcentajes de participac¿n cuando existan reversiones
  *************************************************************************************************/
  PROCEDURE P_RECALCULO_PORCENTAJE_COMP (P_FONDO VARCHAR2,
                                         P_FECHA DATE);

/************************************************************************************************
  Author  : VAGTUD861-6.1. Participaciones - Movimientos Participaciones
  Created : 15/10/2020
  Purpose : Este procedure permite realizar los movimientos RTC, ITC cuando aplique el salto entre las participaciones
  *************************************************************************************************/
  PROCEDURE P_MVTOS_SALTO_PARTICIONES (P_CCC_CLI_PER_NUM_IDEN   CUENTAS_FONDOS.CFO_CCC_CLI_PER_NUM_IDEN%TYPE,
                                       P_CCC_CLI_PER_TID_CODIGO CUENTAS_FONDOS.CFO_CCC_CLI_PER_TID_CODIGO%TYPE,
                                       P_CCC_NUMERO_CUENTA      CUENTAS_FONDOS.CFO_CCC_NUMERO_CUENTA%TYPE,
                                       P_CFO_CODIGO             CUENTAS_FONDOS.CFO_CODIGO%TYPE,
                                       P_CFO_FON_CODIGO         CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE,
                                       P_CFO_FON_CODIGO_DES     CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE,
                                       P_FECHA_EJECUCION        DATE,
                                       P_ERROR                  IN OUT VARCHAR2,
                                       P_MENSAJE                IN OUT VARCHAR2);

/************************************************************************************************
  Author  : VAGTUD861-6.1. Participaciones - Movimientos Participaciones
  Created : 20/10/2020
  Purpose : Este procedure evalua los clientes y aportes para el salto de las participaciones
  *************************************************************************************************/
  PROCEDURE P_MOVIMIENTOS_COMPARTIMENTOS_J (P_FECHA_EJECUCION DATE DEFAULT NULL,
                                            P_FONDO_PADRE VARCHAR2,
                                            P_CODIGO  IN OUT VARCHAR2,          -- VAGTUD991
                                            P_MENSAJE IN OUT VARCHAR2           -- VAGTUD991
                                            );

  /************************************************************************************************
  Author  : VAGTUD861-SP06HU01.Identificaci¿nParticipaci¿nActivaDavicash
  Created : 14/01/2021
  Purpose : Esta funcion permite identificar la participacion activa de un fondo en funcion del
            saldo
  *************************************************************************************************/
  FUNCTION FN_GET_PARTICIPACION_ACT(P_CCC_CLI_PER_TID_CODIGO IN VARCHAR2,
                                    P_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                    P_CCC_NUMERO_CUENTA      IN NUMBER,
                                    P_CFO_FON_CODIGO         IN VARCHAR2,
                                    P_CFO_CODIGO             IN NUMBER) RETURN VARCHAR2;

/************************************************************************************************
  Author  : VAGTUD861-7.1. Reversion entre Participaciones
  Created : 20/01/2021
  Purpose : Este procedure tiene el calculo nuevo calculo de los rendimientos para las reversiones
  *************************************************************************************************/
  PROCEDURE P_CALCULO_REND_A_REVERSAR  (P_ORDEN          NUMBER,
                                        P_FECHA_PRO      DATE,
                                        P_MONTO          NUMBER DEFAULT NULL,
                                        P_RENDIMIENTOS   IN OUT NUMBER,
                                        P_UNIDADES       IN OUT NUMBER);

  -- VAGTUD941 -- PROCESO QUE GENERA LA LISTA DE ORDENES APLAZADAS CON FECHA DE EJECUCION A LA FECHA INDICADA
  PROCEDURE PR_ORDENES_APLAZADAS
           (P_FONDO        VARCHAR2
           ,P_FECHA        DATE
           ,P_OFO_EOF      VARCHAR2
           ,P_USUARIO      VARCHAR2
           );

  -- VAGTUD941 -- PROCESO QUE COMPENSA ORDENES APLAZADAS VALIDADAS EL DIA ANTERIOR
  PROCEDURE PR_COMPENSAR_CBF_OTN(P_TX IN NUMBER DEFAULT NULL);

  -- VAGTUD941 -- PROCESO QUE REALIZA EL TRASLADO DE LA COMPENSACION
  PROCEDURE PR_TRASLADAR_COMPENSACION
           (P_FONDO             IN VARCHAR2
           ,P_NEG               IN NUMBER
           ,P_PRO               IN VARCHAR2
           ,P_BANCO             IN NUMBER
           ,P_CUENTA_ORIGEN     IN VARCHAR2
           ,P_CUENTA_DESTINO    IN VARCHAR2
           ,P_MONTO_COMPENSAR   IN NUMBER
           ,P_FECHA_REGISTRO    IN DATE
           ,P_COMPENSADO        IN OUT VARCHAR2
           ,P_MENSAJE           IN OUT VARCHAR2);

  -- VAGTUD941 -- PROCESO QUE CALCULA LA FECHA DE EJECUCION PARA FONDOS QUE TIENEN ACTIVADO EL PARAMETRO 146
  -- CON DIAS DE RETIRO DEFINIDOS
  PROCEDURE PR_FECHA_EJECUCION
           (P_FONDO           IN VARCHAR2
           ,P_TIPO            IN VARCHAR2
           ,P_FECHA_ORDEN     IN DATE
           ,P_FECHA_GUARDAR   IN DATE
           ,P_FECHA_EJECUCION IN OUT DATE
           ,P_FECHA_ENTREGA   IN OUT DATE
           ,P_CODIGO          IN OUT VARCHAR2
           );

   -- VAGTUD941 -- PROGRAMA QUE CALCULA LOS DATOS DE CONSULTA DE INGRESOS Y EGRESOS
   -- SE LLAMA DESDE LA FORMA COINEG
   PROCEDURE PR_CALCULA_INEGOTN
            (P_FONDO         IN VARCHAR2
            ,P_INGT0         IN OUT NUMBER
            ,P_INGAPL        IN OUT NUMBER
            ,P_EGRT0         IN OUT NUMBER
            ,P_RPAPL         IN OUT NUMBER
            ,P_RTAPL         IN OUT NUMBER
            );

   -- VAGTUD941-2 PROGRAMA QUE PERMITE CREAR UNA ORDEN EN ESTADO APLAZADO
   -- SE INVOCA DESDE P_WEB_PAGOS_PSE
   PROCEDURE PR_CREAR_ORDEN_FONDOS_APL
            (P_SUCURSAL                   IN ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE
            ,P_CLI_NUM_IDEN               IN ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_NUM_IDEN%TYPE
            ,P_CLI_TID_CODIGO             IN ORDENES_FONDOS.OFO_CFO_CCC_CLI_PER_TID_CODIGO%TYPE
            ,P_CUENTA                     IN ORDENES_FONDOS.OFO_CFO_CCC_NUMERO_CUENTA%TYPE
            ,P_FON_CODIGO                 IN ORDENES_FONDOS.OFO_CFO_FON_CODIGO%TYPE
            ,P_CFO_CODIGO                 IN ORDENES_FONDOS.OFO_CFO_CODIGO%TYPE
            ,P_PER_NUM_IDEN               IN ORDENES_FONDOS.OFO_PER_NUM_IDEN%TYPE
            ,P_PER_TID_CODIGO             IN ORDENES_FONDOS.OFO_PER_TID_CODIGO%TYPE
            ,P_TOF_CODIGO                 IN ORDENES_FONDOS.OFO_TTO_TOF_CODIGO%TYPE
            ,P_TIT_CODIGO                 IN ORDENES_FONDOS.OFO_TTO_TIT_CODIGO%TYPE
            ,P_MONTO                      IN ORDENES_FONDOS.OFO_MONTO%TYPE
            ,P_CARGO_ABONO_CUENTA         IN ORDENES_FONDOS.OFO_CARGO_ABONO_CUENTA%TYPE
            ,P_MONTO_CARGO_ABONO_CUENTA   IN ORDENES_FONDOS.OFO_MONTO_CARGO_ABONO_CUENTA%TYPE
            ,P_MONTO_ABONO_CUENTA_DOLARES IN ORDENES_FONDOS.OFO_MONTO_ABONO_CUENTA_DOLARES%TYPE
            ,P_FECHA_EJECUCION            IN ORDENES_FONDOS.OFO_FECHA_EJECUCION%TYPE
            ,P_IMPRIME_REC_DERECHOS       IN ORDENES_FONDOS.OFO_IMPRIME_REC_DERECHOS%TYPE
            ,P_PER_NUM_IDEN_COLOCO        IN ORDENES_FONDOS.OFO_PER_NUM_IDEN_COLOCO%TYPE
            ,P_PER_TID_CODIGO_COLOCO      IN ORDENES_FONDOS.OFO_PER_TID_CODIGO_COLOCO%TYPE
            ,P_ORIGEN_RECURSOS            IN ORDENES_FONDOS.OFO_ORIGEN_RECURSOS%TYPE
            ,P_ORDEN_FONDO                IN OUT ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE
            );

   -- PROGRAMA INVOCADO DESDE EL PROCESO NOCTURNO QUE CONFIRMA LAS ORDENES APLAZADAS
   -- VALIDA SI EL ORIGEN ES DESDE EL BOTON PSE Y ACTUALIZA EL MOVIMIENTO EN MTF
   -- Y LO MARCA COMO ASIGNADO
   PROCEDURE PR_VALIDA_OFO_PSE
            (P_OFO                        IN ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE
            ,P_SUC                        IN ORDENES_FONDOS.OFO_SUC_CODIGO%TYPE
            );

   -- VAGTUD941-3 COMPENSACION DE FONDOS OTN CON PRODUCTOS
   PROCEDURE PR_COMPENSA_PROD_OTN(P_TX IN NUMBER DEFAULT NULL);

   -- VAGTUD941-3 COMPENSACION DE FONDOS OTN CON OTROS FICS
   PROCEDURE PR_COMPENSA_FICS_OTN(P_TX IN NUMBER DEFAULT NULL);

   -- VAGTUD991 - NUEVAS PARTICIPACIONES F.INTERES
   -- FUNCION QUE VALIDA SI EL FONDO TIENE SALTO ENTRE PARTICIPACIONES
   -- VAGTUD991
   FUNCTION FN_APLICA_SALTOS
           (P_FONDO VARCHAR2 -- FONDO PAPA
           ) RETURN VARCHAR;

   -- PROGRAMA QUE CALCULA LOS RANGOS DE LAS PARTICIPACIONES CON BASE EN LOS PARAMETROS 112 Y 113
   PROCEDURE P_TOPES_INV_COMPARTIMENTOS_J
            (P_FON_CODIGO        VARCHAR2
            ,P_SALARIO_MINIMO    NUMBER
            ,P_MINIMO_INVERSION  OUT NUMBER
            ,P_MAXIMO_INVERSION  OUT NUMBER
            ,P_VALIDA_SIN_TOPE   OUT VARCHAR2
            );

   FUNCTION FN_VALIDA_CARTA_EXO
           (P_NID    IN VARCHAR2
           ,P_TID    IN VARCHAR2
           ,P_FONDO  IN VARCHAR2
           ) RETURN VARCHAR2;

   FUNCTION FN_VALIDA_CARTA_ADH
           (P_NID    IN VARCHAR2
           ,P_TID    IN VARCHAR2
           ,P_FONDO  IN VARCHAR2
           ) RETURN VARCHAR2;

END;

/

  GRANT EXECUTE ON "PROD"."P_ORDENES_FONDOS" TO "M_OP_SOPORTE_PROFESIONAL";
  GRANT EXECUTE ON "PROD"."P_ORDENES_FONDOS" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_ORDENES_FONDOS" TO "M_AUX_OP_TESORERIA_MED";
  GRANT EXECUTE ON "PROD"."P_ORDENES_FONDOS" TO "M_J_OP_VAL_CTRL";
