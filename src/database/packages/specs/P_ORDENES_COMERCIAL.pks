--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_ORDENES_COMERCIAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_ORDENES_COMERCIAL" IS
-- Sub-Program Unit Declarations
TYPE P_CURSOR IS REF CURSOR;

PROCEDURE INSERTAR_HOC
 (P_OCO_BOL_MNEMONICO     IN HISTORICO_ORDENES_COMPRA.HOC_OCO_BOL_MNEMONICO%TYPE
 ,P_OCO_COC_CTO_MNEMONICO IN HISTORICO_ORDENES_COMPRA.HOC_OCO_COC_CTO_MNEMONICO%TYPE
 ,P_OCO_CONSECUTIVO       IN HISTORICO_ORDENES_COMPRA.HOC_OCO_CONSECUTIVO%TYPE
 ,P_FECHA                 IN HISTORICO_ORDENES_COMPRA.HOC_FECHA%TYPE
 ,P_CAMPO                 IN HISTORICO_ORDENES_COMPRA.HOC_CAMPO%TYPE
 ,P_USUARIO               IN HISTORICO_ORDENES_COMPRA.HOC_USUARIO%TYPE
 ,P_TERMINAL              IN HISTORICO_ORDENES_COMPRA.HOC_TERMINAL%TYPE
 ,P_ACCION                IN HISTORICO_ORDENES_COMPRA.HOC_ACCION%TYPE
 ,P_VALOR_ANTERIOR        IN HISTORICO_ORDENES_COMPRA.HOC_VALOR_ANTERIOR%TYPE
 ,P_VALOR_POSTERIOR       IN HISTORICO_ORDENES_COMPRA.HOC_VALOR_POSTERIOR%TYPE
 );
PROCEDURE INSERTAR_HOV
 (P_OVE_BOL_MNEMONICO     IN HISTORICO_ORDENES_VENTA.HOV_OVE_BOL_MNEMONICO%TYPE
 ,P_OVE_COC_CTO_MNEMONICO IN HISTORICO_ORDENES_VENTA.HOV_OVE_COC_CTO_MNEMONICO%TYPE
 ,P_OVE_CONSECUTIVO       IN HISTORICO_ORDENES_VENTA.HOV_OVE_CONSECUTIVO%TYPE
 ,P_FECHA                 IN HISTORICO_ORDENES_VENTA.HOV_FECHA%TYPE
 ,P_CAMPO                 IN HISTORICO_ORDENES_VENTA.HOV_CAMPO%TYPE
 ,P_USUARIO               IN HISTORICO_ORDENES_VENTA.HOV_USUARIO%TYPE
 ,P_TERMINAL              IN HISTORICO_ORDENES_VENTA.HOV_TERMINAL%TYPE
 ,P_ACCION                IN HISTORICO_ORDENES_VENTA.HOV_ACCION%TYPE
 ,P_VALOR_ANTERIOR        IN HISTORICO_ORDENES_VENTA.HOV_VALOR_ANTERIOR%TYPE
 ,P_VALOR_POSTERIOR       IN HISTORICO_ORDENES_VENTA.HOV_VALOR_POSTERIOR%TYPE
 );
PROCEDURE ANULACION_CANCELACION_ORDENES;
PROCEDURE ANULACION_VENTAS
 (P_OVE_BOL_MNEMONICO     IN ORDENES_VENTA.OVE_BOL_MNEMONICO%TYPE
 ,P_OVE_COC_CTO_MNEMONICO IN ORDENES_VENTA.OVE_COC_CTO_MNEMONICO%TYPE
 ,P_OVE_CONSECUTIVO       IN ORDENES_VENTA.OVE_CONSECUTIVO%TYPE
 ,P_OVE_EOC_MNEMONICO     IN ORDENES_VENTA.OVE_EOC_MNEMONICO%TYPE
 ,P_OVE_RAZON_ANU_CAN     IN ORDENES_VENTA.OVE_RAZON_ANU_CAN%TYPE);
/*************************************************
*** TOTAL POR BANCO DE DETALLES PAGOS ACH     ****
*************************************************/
TYPE r_banco_dpa IS RECORD
      (BAN_CODIGO NUMBER(5),
       BAN_NOMBRE VARCHAR2(40),
       GENERA_ARCHIVO VARCHAR2(1),
       NUMERO_PAGOS NUMBER(22,2),
       TOTAL_PAGOS  NUMBER(22,2));
type t_banco_dpa is TABLE OF r_banco_dpa INDEX BY BINARY_INTEGER;
PROCEDURE TraerBancoDPA (P_SUC NUMBER, 
                         P_NEG NUMBER, 
                         P_ODP NUMBER,
                         P_DPA IN OUT t_banco_dpa);
/****************************************************
*** TOTAL POR BANCO PARA EJECUCION DE TRB Y ACH  ****
****************************************************/
PROCEDURE TraerBancoEjecucion (P_DPA IN OUT t_banco_dpa);
FUNCTION BENEFICIARIO_CUENTA (P_CUENTA_DECEVAL    IN COMITENTES_DECEVAL.COD_CUD_CUENTA_DECEVAL%TYPE
                             ,P_TIPO              IN NUMBER) RETURN VARCHAR2;
/**************************************************
*** MANEJO DE AGRUPACION DE ORDENES DE ACCIONES ***
**************************************************/
TYPE T_REGISTRO_ACCION IS RECORD
   (ACC_INICIALES_USUARIO                    VARCHAR2(3)
   ,ACC_TIPO_ORDEN                           VARCHAR2(1)
   ,ACC_FECHA                                DATE
   ,ACC_CONSECUTIVO                          NUMBER(8)
   ,ACC_BOL_MNEMONICO                        VARCHAR2(5)
   ,ACC_COC_CTO_MNEMONICO                    VARCHAR2(5)
   ,ACC_ENA_MNEMONICO                        VARCHAR2(15)
   ,ACC_TIPO_NOMINAL_O_PESOS                 VARCHAR2(1)
   ,ACC_NOMINAL_O_PESOS                      NUMBER(22,2)
   ,ACC_COMISION                             NUMBER
   ,ACC_CONDICION_PRECIO                     VARCHAR2(3)
   ,ACC_PRECIO_LIMITE_O_MARGEN               NUMBER(22,2)
   ,ACC_CRITERIOS_ADICIONALES                VARCHAR2(3)
   ,ACC_CANTIDAD_MINIMA                      NUMBER(22,2)
   ,ACC_VISIBLE                              VARCHAR2(1)
   ,ACC_PORCENTAJE_VISIBLE                   NUMBER(8,3)
   ,ACC_STOP                                 VARCHAR2(1)
   ,ACC_PRECIO_STOP                          NUMBER(22,2)
   ,ACC_VIO_MNEMONICO                        VARCHAR2(3)
   ,ACC_FECHA_PERMANENCIA                    DATE
   ,ACC_HORA_DURACION                        VARCHAR2(5)
   ,ACC_PERMITE_AGRUPAMIENTO                 VARCHAR2(1)
   ,ACC_LEO_CONSECUTIVO                      NUMBER(5)
   ,ACC_CONSECUTIVO_AGRUPAMIENTO             NUMBER(10)
   ,ACC_FECHA_RUEDA                          DATE);
TYPE T_ACCIONES IS TABLE OF T_REGISTRO_ACCION INDEX BY BINARY_INTEGER; 
TYPE T_REGISTRO_ACCION_AGRUPADO IS RECORD
   (ACC_TIPO_ORDEN                           VARCHAR2(1)
   ,ACC_ENA_MNEMONICO                        VARCHAR2(15)
   ,ACC_TIPO_NOMINAL_O_PESOS                 VARCHAR2(1)
   ,ACC_NOMINAL_O_PESOS                      NUMBER(22,2)
   ,ACC_CONDICION_PRECIO                     VARCHAR2(3)
   ,ACC_PRECIO_LIMITE_O_MARGEN               NUMBER(22,2)
   ,ACC_CRITERIOS_ADICIONALES                VARCHAR2(3)
   ,ACC_LEO_CONSECUTIVO                      NUMBER(5)
   ,ACC_CONSECUTIVO_AGRUPAMIENTO             NUMBER(10)
   ,ACC_TOTAL_AGRUPADAS                      NUMBER(6)
   ,ACC_CONSECUTIVO_PRIMERA                  NUMBER(8));
TYPE T_ACCIONES_AGRUPADO IS TABLE OF T_REGISTRO_ACCION_AGRUPADO INDEX BY BINARY_INTEGER;
PROCEDURE ORDENES_SIN_REGISTRAR
 (P_ORDENES_SUELTAS IN OUT T_ACCIONES
 ,P_ORDENES_AGRUPADAS IN OUT T_ACCIONES_AGRUPADO);
PROCEDURE ESTADO_ORDENES
 (P_ACC_CONSECUTIVO       IN ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
 ,P_ACC_BOL_MNEMONICO     IN ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
 ,P_ACC_COC_CTO_MNEMONICO IN ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
 ,P_ACC_TIPO_ORDEN        IN VARCHAR2
 ,P_REG_COM               IN VARCHAR2
 ,P_RESPUESTA             IN OUT VARCHAR2);
PROCEDURE CREAR_COMPLEMENTACION_ORDEN
 (P_CONSECUTIVO           IN ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
 ,P_BOL_MNEMONICO         IN ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
 ,P_COC_CTO_MNEMONICO     IN ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
 ,P_ESTADO_BOLSA          IN ORDENES_COMPRA.OCO_ESTADO_BOLSA%TYPE
 ,P_CANTIDAD              IN COMPLEMENTACIONES_ORDENES.CMO_CANTIDAD%TYPE
 ,P_NUMERO_OPERACION      IN COMPLEMENTACIONES_ORDENES.CMO_NUMERO_OPERACION%TYPE
 ,P_TIPO_ORDEN            IN VARCHAR2
 ,P_ACT_INS               IN VARCHAR2);
PROCEDURE P_COLOCAR_ORDEN( P_CLI_TID_CODIGO       IN VARCHAR2,
                           P_CLI_NUM_IDEN         IN VARCHAR2,
                           P_USUARIO              IN VARCHAR2,
                           P_CUENTA_CORREDORES    IN NUMBER,
                           P_COLOCA_USUARIO       IN VARCHAR2,
                           P_COLOCA_TID_CODIGO    IN VARCHAR2,
                           P_COLOCA_NUM_IDEN      IN VARCHAR2,
                           P_COLOCA_TERMINAL      IN VARCHAR2,
                           P_DUENO_TID_CODIGO     IN VARCHAR2,
                           P_DUENO_NUM_IDEN       IN VARCHAR2,
                           P_ORDENANTE_TID_CODIGO IN VARCHAR2,
                           P_ORDENANTE_NUM_IDEN   IN VARCHAR2,
                           P_TIPO_ORDEN           IN VARCHAR2,
                           P_ESPECIE              IN VARCHAR2,
                           P_CANTIDAD             IN NUMBER,
                           P_FECHA_HORA           IN VARCHAR2,--IN DATE,
                           P_PORCENTAJE_COMISION  IN NUMBER,
                           P_VIG_TIPO_VIGENCIA    IN VARCHAR2,
                           P_VIG_FECHA_PERMANENCI IN VARCHAR2,--IN DATE,
                           P_VIG_HORA_PERMANENCIA IN VARCHAR2,
                           P_COND_PRECIO          IN VARCHAR2,
                           P_COND_PRECIO_LIMITIE  IN NUMBER,
                           P_COND_CRITERIOS_ADICI IN VARCHAR2,
                           P_COND_CANTIDAD_MINIMA IN NUMBER,
                           P_VIS_VISIBLE          IN NUMBER,
                           P_VIS_PORCENTAJE       IN NUMBER,
                           P_STOP_STOP            IN NUMBER,
                           P_STOP_PRECIO_STOP     IN NUMBER,
                           P_CONSOLIDAR           IN NUMBER,
                           P_CUENTA_DECEVAL       IN NUMBER,
                           P_TITULO_ORIGEN        IN VARCHAR2,
                           P_TITULO_CTA_DVAL      IN NUMBER,
                           P_TITULO_COD_FUNGIBLE  IN NUMBER,
                           P_TITULO_COD_ISIN      IN VARCHAR2,
                           P_INS_REC_MEDIO        IN VARCHAR2,
                           P_INS_REC_HORA         IN VARCHAR2,
                           P_INS_REC_DETALLE      IN VARCHAR2,
                           P_INS_ENV_FAX          IN NUMBER,
                           P_INS_ENV_NUM_FAX      IN VARCHAR2,
                           P_INS_ENV_DIRECCION    IN NUMBER,
                           P_INS_ENV_NUM_DIRECCION IN VARCHAR2,
                           P_INS_ENV_COD_CIUDAD    IN NUMBER,
                           P_INS_ENV_CONTACTO      IN VARCHAR,
                           P_CLI_PROFESIONAL       IN VARCHAR2,
                           P_OPX                   IN VARCHAR2,
                           P_CANTIDAD_INTENCION    IN NUMBER,
                           P_PRECIO_INTENCION      IN NUMBER,
                           P_COMISION_INTENCION    IN NUMBER,
                           P_IVA_ITENCION          IN NUMBER,
                           P_TOTAL_OPERACION_INT   IN NUMBER,
                           P_NETO_OPERACION_INT    IN NUMBER, 
                           P_FECHA_RECEPCION       IN VARCHAR2,
                           P_ABONO_CUENTA          IN VARCHAR2 DEFAULT NULL,
                           P_VALOR_ABONO_CUENTA    IN NUMBER DEFAULT NULL,
                           P_PAGAR_A_PAGO          IN VARCHAR2 DEFAULT NULL,
                           P_TIPO_IDEN_PAGO        IN VARCHAR2 DEFAULT NULL,
                           P_NUM_IDEN_PAGO         IN VARCHAR2 DEFAULT NULL,
                           P_TIPO_CUENTA_PAGO      IN VARCHAR2 DEFAULT NULL,
                           P_CODIGO_BANCO_PAGO     IN NUMBER DEFAULT NULL,
                           P_NUMERO_CUENTA_PAGO    IN VARCHAR2 DEFAULT NULL,
                           P_NOMBRE_CUENTA_PAGO    IN VARCHAR2 DEFAULT NULL,
                           P_VALOR_PAGO            IN NUMBER DEFAULT NULL,
                           P_CODIGO_INFORMADOR     IN VARCHAR2 DEFAULT NULL,
                           P_TID_CODIGO_INFORMADOR IN VARCHAR2 DEFAULT NULL,
                           P_NUM_IDEN_INFORMADOR   IN VARCHAR2 DEFAULT NULL,
                           P_NOMBRE_INFORMADOR     IN VARCHAR2 DEFAULT NULL,
                           P_CODIGO_OFICINA_INFOR  IN VARCHAR2 DEFAULT NULL,
                           P_FECHA_PRE_ORDEN_INFOR IN VARCHAR2 DEFAULT NULL, 
                           P_HORA_PRE_ORDEN_INFOR  IN VARCHAR2 DEFAULT NULL, 
                           P_OPA                   IN VARCHAR2 DEFAULT NULL,
                           P_TODO_NADA_OPA         IN VARCHAR2 DEFAULT NULL,
                           P_VENTA_CORTO           IN VARCHAR2 DEFAULT NULL,
                           P_ID_BOLSA              IN VARCHAR2 DEFAULT NULL,
                           P_ID_ORDEN              OUT NUMBER,
                           P_CLOB                  OUT CLOB,
                           /****WGONZALEZ******/
                           P_TIPO_ORDEN_COM        IN VARCHAR2 DEFAULT NULL,
                           P_SUBYACENTE            IN VARCHAR2 DEFAULT NULL,
                           P_TIPOS_SUBYACENTE      IN VARCHAR2 DEFAULT NULL,
                           P_NUMERO_FRONT          IN VARCHAR2 DEFAULT NULL,
                           P_NUMERO_XSTREAM        IN VARCHAR2 DEFAULT NULL,
                           P_CUENTA_CAMARA         IN VARCHAR2 DEFAULT NULL,
                           P_FECHA_VENCIDA         IN VARCHAR2 DEFAULT NULL,--IN DATE,
                           P_FECHA_VENCIMIENTO     IN VARCHAR2 DEFAULT NULL,--IN DATE,
                           P_GARANTIAS_DISPONIBLES IN NUMBER DEFAULT NULL,
                           P_GARANTIAS_REQUERIDAS  IN NUMBER DEFAULT NULL,
                           P_RENTABILIDAD          IN NUMBER DEFAULT NULL,
                           P_RECEPCION_USUARIO     IN VARCHAR2 DEFAULT NULL,
                           P_ENRUTA_USUARIO        IN VARCHAR2 DEFAULT NULL,
                           P_FINALIDAD             IN VARCHAR2 DEFAULT NULL,
                           P_MERCADO               IN VARCHAR2 DEFAULT NULL,
                           P_CTA_CRCC_CRUZADA      IN VARCHAR2 DEFAULT NULL,
                           P_PRECIO_PROMEDIO       IN NUMBER DEFAULT NULL,
                           P_OBSERVACION           IN VARCHAR2 DEFAULT NULL,
                           P_PUNTOS_FORWARD        IN NUMBER DEFAULT NULL,
                           P_NDF_FORWARD           IN NUMBER DEFAULT NULL,
                           P_CONCEPTO              IN VARCHAR2 DEFAULT NULL,
                           P_CLI_TID_CODIGO_REG    IN VARCHAR2 DEFAULT NULL,
                           P_CLI_NUM_IDEN_REG      IN VARCHAR2 DEFAULT NULL,
                           P_CUENTA_CORREDORES_REG IN NUMBER DEFAULT NULL,
                           P_CUENTA_CAMARA_REG     IN VARCHAR2 DEFAULT NULL,
                           P_OBSERVACION_REG       IN VARCHAR2 DEFAULT NULL,
                           P_CANAL_ORIGEN          IN VARCHAR2 DEFAULT NULL,
                           P_TIPO_COMISION         IN VARCHAR2 DEFAULT NULL,
                           P_ORDENANTE             IN VARCHAR2 DEFAULT NULL,
						   /* fdm  */
                           P_MAS_INSTRUCCIONES_PAGO IN VARCHAR2 DEFAULT NULL,
                           P_TIPO_INSTRUCCION       IN VARCHAR2 DEFAULT NULL,
                           P_FONDO                  IN VARCHAR2 DEFAULT NULL,
                           P_APORTE                 IN NUMBER DEFAULT NULL,
                           P_PAGAR_A                IN VARCHAR2 DEFAULT NULL,
                           P_TIPO_PAGO              IN VARCHAR2 DEFAULT NULL,
                           P_SUCURSAL               IN NUMBER DEFAULT NULL,
                           P_CRUCE                  IN VARCHAR2 DEFAULT NULL,
                           P_TERCERO_NOMBRE         IN VARCHAR2 DEFAULT NULL, /* info del tercero    */
                           P_TERCERO_TIPO_ID        IN VARCHAR2 DEFAULT NULL,
                           P_TERCERO_NUMERO_ID      IN VARCHAR2 DEFAULT NULL,
                           P_CONSIGNAR              IN VARCHAR2 DEFAULT NULL, /* consignar cheque  */ 
                           P_CONSIGNAR_BANCO        IN NUMBER DEFAULT NULL,
                           P_CONSIGNAR_CUENTA       IN VARCHAR2 DEFAULT NULL,
                           P_CONSIGNAR_TIPO_CUENTA  IN VARCHAR2 DEFAULT NULL,
                           P_TR_CUENTA_C_TIPO_ID    IN VARCHAR2 DEFAULT NULL, /* transferencia cta corredores  */ 
                           P_TR_CUENTA_C_NUM_ID     IN VARCHAR2 DEFAULT NULL,
                           P_TR_CUENTA_C_NUM_CUENTA IN VARCHAR2 DEFAULT NULL,
                           P_SEBRA_ID_CONTRAPARTE   IN VARCHAR2 DEFAULT NULL, /* pago sebra  */
                           P_SEBRA_OTRA_CUENTA      IN VARCHAR2 DEFAULT NULL,
                           P_SEBRA_ID_BANCO         IN NUMBER DEFAULT NULL,
                           P_SEBRA_NUMERO_CUENTA    IN VARCHAR2 DEFAULT NULL,
                           P_SEBRA_TIPO_CUENTA      IN VARCHAR2 DEFAULT NULL,
                           P_TR_BANC_ID_BANCO       IN NUMBER DEFAULT NULL,
                           P_TR_BANC_CUENTA         IN VARCHAR2 DEFAULT NULL,
                           P_TR_BANC_TIPO_CUENTA    IN VARCHAR2 DEFAULT NULL,
						   /*osjtorres RF*/
                           P_TASA_REGISTRO          IN NUMBER DEFAULT NULL,
                           P_ACH_ID_BANCO           IN NUMBER DEFAULT NULL,
                           P_ACH_CUENTA             IN VARCHAR2 DEFAULT NULL,
                           P_ACH_TIPO_CUENTA        IN VARCHAR2 DEFAULT NULL,
                           P_CUENTA_INSCRITA        IN VARCHAR2 DEFAULT NULL,
                           P_SOPORTE_FISICO         IN VARCHAR2 DEFAULT NULL,
						               --P_TITULO_CTA_DCV         IN NUMBER   DEFAULT NULL,
									   P_TITULO_CTA_DCV         IN VARCHAR2   DEFAULT NULL, --MIT DCV BANCO REPUBLICA
                           P_RECPROF_CONSECUTIVO    IN NUMBER   DEFAULT NULL);--Titulo cuenta DCV

PROCEDURE P_ORDENACTUALIZARESTADO (P_TIPO_ORDEN   IN VARCHAR2,
                                   P_ID_ORDEN     IN NUMBER,
                                   P_ESTADO       IN VARCHAR2,
                                   P_USUARIO      IN VARCHAR2,                                 
                                   P_TID_CODIGO   IN VARCHAR2,                                 
                                   P_NUM_IDEN     IN VARCHAR2,
                                   P_TERMINAL     IN VARCHAR2);
PROCEDURE P_ORDEN_CANCELAR(P_TIPO_ORDEN   IN VARCHAR2,
                           P_ID_ORDEN     IN NUMBER,
                           P_FECHA        IN DATE,
                           P_MOTIVO       IN VARCHAR2,
                           P_USUARIO      IN VARCHAR2,                                 
                           P_TID_CODIGO   IN VARCHAR2,                                 
                           P_NUM_IDEN     IN VARCHAR2,
                           P_TERMINAL     IN VARCHAR2,
                           P_ERRORES      IN OUT NUMBER,
                           /**WGONZALEZ**/
                           P_INS_REC_HORA      IN VARCHAR2 DEFAULT NULL,        
                           P_INS_REC_MEDIO     IN VARCHAR2 DEFAULT NULL,
                           P_INS_REC_DETALLE   IN VARCHAR2 DEFAULT NULL,
                           P_CANAL_ORIGEN      IN VARCHAR2 DEFAULT NULL,
                           P_USUARIO_RECEPCION IN VARCHAR2 DEFAULT NULL);
PROCEDURE P_ORDEN_ANULAR  (P_TIPO_ORDEN   IN VARCHAR2,
                           P_ID_ORDEN     IN NUMBER,
                           P_FECHA        IN DATE,
                           P_MOTIVO       IN VARCHAR2,
                           P_USUARIO      IN VARCHAR2,                                 
                           P_TID_CODIGO   IN VARCHAR2,                                 
                           P_NUM_IDEN     IN VARCHAR2,
                           P_TERMINAL     IN VARCHAR2,
                           P_ERRORES      IN OUT NUMBER,
                           P_CANAL_ORIGEN IN VARCHAR2 DEFAULT NULL);                           
PROCEDURE P_COMPLEMENTACION (P_NUMERO_OPERACION  IN VARCHAR2,
                             P_NUMERO_FRACCION   IN NUMBER,
                             P_TIPO_ORDEN        IN VARCHAR2,                          
                             P_BOL_MNEMONICO     IN VARCHAR2,
                             P_ID_ORDEN          IN NUMBER,
                             P_USUARIO           IN VARCHAR2,                                 
                             P_TID_CODIGO        IN VARCHAR2,                                 
                             P_NUM_IDEN          IN VARCHAR2,
                             P_TERMINAL          IN VARCHAR2,
                             P_FECHA_PROCESO     IN VARCHAR2,                                                   
                             P_ERRORES           IN OUT NUMBER);
PROCEDURE P_NUMERACION_SUPER;
PROCEDURE P_NOTIFICAR_OPERACION( P_ID_ORDEN              IN NUMBER,
                                 P_BOL_MNEMONICO         IN VARCHAR2,
                                 P_COC_CTO_MNEMONICO     IN VARCHAR2,
                                 P_TIPO_OPERACION        IN VARCHAR2,
                                 P_CANTIDAD_TOTAL        IN NUMBER,
                                 P_PRECIO                IN NUMBER,
                                 P_COMISION              IN NUMBER,
                                 P_VALOR_TOTAL           IN NUMBER,
                                 P_IVA                   IN NUMBER,
                                 P_VALOR_NETO            IN NUMBER,
                                 P_FOLIO                 IN VARCHAR2,                                 
                                 P_FRACCION              IN NUMBER,
                                 P_CODIGO_XSTREAM        IN VARCHAR2,
                                 P_ENA_MNENMONICO        IN VARCHAR2,
                                 P_ERRORES               IN OUT NUMBER);

/**************************************************
  ************** SEBRA CONTINGENCIA *****************
  ***************************************************/
  TYPE O_CURSOR IS REF CURSOR;
  PROCEDURE ORDENES_PAGO_SEBRA_REGISTRADAS
  (P_ODP_CONSECUTIVO IN ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE  
  ,P_ODP_SUC_CODIGO IN ORDENES_DE_PAGO.ODP_SUC_CODIGO%TYPE
  ,P_ODP_NEG_CONSECUTIVO IN ORDENES_DE_PAGO.ODP_NEG_CONSECUTIVO%TYPE
  ,P_ODP_OCU_CODIGO IN ORDENES_DE_PAGO.ODP_OCU_CODIGO%TYPE
  ,io_cursor IN OUT O_CURSOR);
  PROCEDURE NUM_ARCHIVO_CONTINGENCIA_SEBRA(io_cursor IN OUT O_CURSOR);
  PROCEDURE ACT_NUM_ARCHIVO_CONTI_PSE;
  PROCEDURE LEER_DATOS_SALIDA_BANREP
  (P_TSE_NUM_TRANSACCION IN NUMBER,
  P_TSE_TOTAL_TRANSACCIONES IN NUMBER,
  P_TSE_NUMERO_ORIGINADOR IN VARCHAR2,
  P_TSE_OPERACION_BANREP IN NUMBER,
  P_TSE_ESTADO IN VARCHAR2,
  P_TSE_CODIGO_ERROR IN VARCHAR2,
  P_TSE_DESCRIPCION_ERROR IN VARCHAR2,
  P_TSE_MONEDA IN VARCHAR2,
  P_TSE_CANTIDAD IN NUMBER,
  P_TSE_CODIGO_TRANSACCION IN NUMBER,
  P_TSE_TIPO IN NUMBER,
  P_TSE_OBSERVACIONES IN VARCHAR2,
  P_TSE_NIT_CTA_DEBITO IN VARCHAR2,
  P_TSE_SUCURSAL_CTA_DEBITO IN NUMBER,
  P_TSE_CTA_DEPOSITO_BR_DEB IN NUMBER,
  P_TSE_PORTAFOLIO_CTA_DEB IN NUMBER,
  P_TSE_CODIGO_MON_CTA_DEB IN VARCHAR2,
  P_TSE_ID_TERCERO_DEB IN VARCHAR2,
  P_TSE_NOMBRE_TERCERO_DEB IN VARCHAR2,
  P_TSE_ID_TERCERO_CRE IN VARCHAR2,
  P_TSE_NOMBRE_TERCERO_CRE IN VARCHAR2,
  P_TSE_NIT_CTA_CREDITO IN VARCHAR2,
  P_TSE_SUCURSAL_CTA_CREDITO IN NUMBER,
  P_TSE_CTA_DEPOSITO_BR_CRE IN NUMBER,
  P_TSE_PORTAFOLIO_CTA_CRE IN NUMBER,
  P_TSE_CODIGO_MON_CTA_CRE IN VARCHAR2);  

PROCEDURE P_NOTIFICAR_OPERACION_RF( P_ID_ORDEN           IN NUMBER,
                                    P_BOL_MNEMONICO      IN VARCHAR2,
                                    P_COC_CTO_MNEMONICO  IN VARCHAR2,
                                    P_FOLIO              IN VARCHAR2,
                                    P_TIPO               IN VARCHAR2,
                                    P_CANTIDAD           IN NUMBER,
                                    P_FECHA_HORA_REGIS   IN VARCHAR2,
                                    P_FECHA_CUMP_TITULO  IN VARCHAR2,
                                    P_PRECIO             IN NUMBER,
                                    P_DIAS_CUMPLIMIENTO  IN NUMBER,
                                    P_TASA               IN NUMBER,
                                    P_NEMOTECNICO        IN VARCHAR2,
                                    P_FECHA_EMISION      IN VARCHAR2,
                                    P_MERCADO            IN VARCHAR2,
                                    P_ISIN               IN VARCHAR2,
                                    P_NEMO_SERIALIZADO   IN VARCHAR2,
                                    P_TRADER             IN VARCHAR2,
                                    P_CODIGO_COM_VEN     IN VARCHAR2,
                                    P_UBICACION_TITULO   IN VARCHAR2,
                                    P_RUEDA              IN VARCHAR2,
                                    P_COD_FIRMA_CONTRA   IN VARCHAR2,
                                    P_TIPO_MER_PRI_SEC   IN VARCHAR2,
                                    P_PLAZO_REPO         IN VARCHAR2,
                                    P_MONEDA             IN VARCHAR2,
                                    P_VALOR_TOTAL        IN NUMBER,
                                    P_PRECIO_LIMPIO      IN NUMBER,
                                    P_FIJA_PRECIO        IN VARCHAR2,
                                    P_DVL_FISICO         IN VARCHAR2,
                                    P_ORIGEN_PUNTA       IN VARCHAR2,
                                    P_TIPO_OPERACION     IN VARCHAR2,
                                    P_TIPO_OPERACION_SER IN VARCHAR2,
                                    P_TIPO_OPERACION_CON IN VARCHAR2,
                                    P_PLAZO_LIQUIDACION  IN VARCHAR2,
                                    P_ESTADO_OPERACION   IN VARCHAR2,
                                    P_FUNGIBLE           IN NUMBER,
                                    P_TASA_REFERENCIA    IN VARCHAR2,
                                    P_PUNTOS_TASA        IN NUMBER,
                                    P_BASE_CALCULO       IN VARCHAR2,
                                    P_PER_PAGO_INTERESE  IN VARCHAR2,
                                    P_MODALIDAD          IN VARCHAR2,
                                    P_DURACION           IN VARCHAR2,
                                    P_NUM_DIAS_VENCI     IN NUMBER,
                                    P_FECHA_VENCIMI_TIT  IN VARCHAR2,
                                    P_PLAZO_EMI_DIAS     IN NUMBER, 
                                    P_TASA_EMISION       IN NUMBER,
                                    P_FECHA_MONEDA       IN VARCHAR2,
                                    P_TASA_REPO          IN NUMBER,
                                    P_MONTO_RECOMPRA     IN NUMBER,
                                    P_CANTIDAD_RECOMPRA  IN NUMBER,
                                    P_ESTADO_TITULO      IN VARCHAR2,
                                    P_TASA_TTV           IN NUMBER,
                                    P_HORA_REGISTRO      IN VARCHAR2,
                                    P_ERRORES            IN OUT NUMBER);   

PROCEDURE P_ACTUALIZAR_ENRUTAMIENTO (P_ID_ORDEN     IN NUMBER,
                                     P_TIPO_ORDEN   IN VARCHAR2,
                                     P_TID_CODIGO   IN VARCHAR2,                                 
                                     P_NUM_IDEN     IN VARCHAR2,
                                     P_ERRORES      IN OUT NUMBER);

PROCEDURE P_VALIDAR_SALDO_ETRADE(P_CODIGO_USUARIO        IN VARCHAR2,
                                 P_CUENTAS_CORREDORES    IN NUMBER,
                                 P_CLI_PER_NUM_IDEN      IN VARCHAR2,
                                 P_CLI_PER_TID_CODIGO    IN VARCHAR2,
                                 P_PER_NUM_IDEN          IN VARCHAR2,
                                 P_PER_TID_CODIGO        IN VARCHAR2,
                                 P_CLASE_ORDEN           IN VARCHAR2,
                                 P_TIPO_ORDEN            IN VARCHAR2,
                                 P_ESPECIE               IN VARCHAR2,
                                 P_CANTIDAD              IN NUMBER,
                                 P_PRECIO_ORDEN          IN NUMBER,
                                 P_FECHA_HORA            IN VARCHAR2,
                                 P_CUENTA_DECEVAL        IN NUMBER,
                                 P_NUMERO_ORDEN          IN NUMBER,
                                 P_FECHA_VIGENCIA        IN VARCHAR2 DEFAULT NULL,
                                 P_TID_CODIGO_COMERCIAL  IN VARCHAR2 DEFAULT NULL,                                 
                                 P_NUM_IDEN_COMERCIAL    IN VARCHAR2 DEFAULT NULL,
                                 P_ID_ORDEN              OUT NUMBER,
                                 P_CLOB                  OUT CLOB,
                                 /**WGONZALEZ**/
                                 P_VIG_TIPO_VIGENCIA       IN VARCHAR2 DEFAULT NULL,
                                 P_INS_REC_HORA            IN VARCHAR2 DEFAULT NULL,
                                 P_USUARIO                 IN VARCHAR2 DEFAULT NULL,
                                 P_COND_CANTIDAD_MINIMA    IN NUMBER DEFAULT NULL,
                                 P_COND_PRECIO_LIMITIE     IN NUMBER DEFAULT NULL,
                                 P_INS_REC_MEDIO           IN VARCHAR2 DEFAULT NULL,
                                 P_INS_REC_DETALLE         IN VARCHAR2 DEFAULT NULL,
                                 P_OBSERVACION             IN VARCHAR2 DEFAULT NULL,
                                 P_CANAL_ORIGEN            IN VARCHAR2 DEFAULT NULL,
                                 P_OBSERVACION_CORRECION   IN VARCHAR2 DEFAULT NULL,
                                 P_TIPO_COMISION           IN VARCHAR2 DEFAULT NULL,
                                 P_TIPO_ACTUALIZACION      IN VARCHAR2 DEFAULT NULL,
                                 P_ORDENANTE_TID_CODIGO    IN VARCHAR2 DEFAULT NULL,
                                 P_ORDENANTE_NUM_IDEN      IN VARCHAR2 DEFAULT NULL,
                                 P_ORDENANTE               IN VARCHAR2 DEFAULT NULL,
                                 P_USUARIO_RECEPCION       IN VARCHAR2 DEFAULT NULL,
                                 P_VALOR_COMISION          IN NUMBER DEFAULT NULL);

PROCEDURE P_ACTUALIZA_INTERFAZ_CMA (P_EJECUTA VARCHAR2,P_ERRORES OUT NUMBER);

PROCEDURE PR_COMPLEMENTA_OPERACIONES(P_ENA_MNEMONICO  VARCHAR2,
                                     P_TIPO_OPERACION VARCHAR2,
                                     P_MERCADO        VARCHAR2,
                                     P_CLASE_ORDEN   VARCHAR2, 
                                     P_CONSECUTIO    NUMBER DEFAULT NULL);


FUNCTION PRECIO_LIMITE_COMPRAS (CONSECUTIVO_HOC NUMBER, CONSECUTIVO_OCO NUMBER ) RETURN VARCHAR2 ;
FUNCTION PRECIO_LIMITE_VENTAS (CONSECUTIVO_HOV NUMBER, CONSECUTIVO_OVE NUMBER ) RETURN VARCHAR2 ;

PROCEDURE PR_CREAR_SALDO_CFC (P_CUENTA_DECEVAL     IN NUMBER,
                              P_ISIN               IN VARCHAR2,
                              P_FUNGIBLE           IN VARCHAR2,
                              P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                              P_CLI_PER_TID_CODIGO IN VARCHAR2,
                              P_CUENTA_CCC         IN NUMBER);

PROCEDURE PR_ISIN_VENTA_CORTO_ACC(P_ENA_MNEMONICO    IN  VARCHAR2,
                                  P_PER_NUM_IDEN     IN  VARCHAR2,
                                  P_PER_TID_CODIGO   IN  VARCHAR2,
                                  P_ISIN             OUT VARCHAR2,
                                  P_CREA_SALDO       OUT VARCHAR2,
                                  P_MENSAJE          OUT VARCHAR2);   

-- AJUSTE LEORV SMORALES
FUNCTION NOMINAL_ORIGEN (CONSECUTIVO NUMBER, TIPO_OPERACION VARCHAR2) RETURN NUMBER;
FUNCTION PRECIO_ORIGEN (CONSECUTIVO NUMBER, TIPO_OPERACION VARCHAR2) RETURN NUMBER;
FUNCTION FECH_PERMAN_ORIGEN (CONSECUTIVO NUMBER, TIPO_OPERACION VARCHAR2) RETURN VARCHAR2;

/**************************************************
*** CALCULO DEL VALOR NETO LIQUIDACION ***
**************************************************/

FUNCTION F_LIC_VALOR_NETO_CON_IVA(
    P_NUMERO_OPERACION 	 IN LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE,
    P_NUMERO_FRACCION  	 IN LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE,
    P_TIPO_OPERACION 	 IN LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE,
    P_BOL_MNEMONICO 	 IN LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
)
RETURN LIQUIDACIONES_COMERCIAL.LIC_VOLUMEN_NETO_FRACCION%TYPE;

PROCEDURE PR_ISIN_COMPRA_ACC(P_ENA_MNEMONICO    IN  VARCHAR2,
                             P_PER_NUM_IDEN     IN  VARCHAR2,
                             P_PER_TID_CODIGO   IN  VARCHAR2,
                             P_ISIN             OUT VARCHAR2,
                             P_CREA_SALDO       OUT VARCHAR2,
                             P_MENSAJE          OUT VARCHAR2);

PROCEDURE PR_ORDEN_A_COMPLEMENTAR(P_FOLIO_BOLSA          IN VARCHAR2
                                 ,P_CLI_PER_NUM_IDEN     IN VARCHAR2
                                 ,P_CLI_PER_TID_CODIGO   IN VARCHAR2
                                 ,P_CUENTA_DECEVAL       IN NUMBER
                                 ,P_ID_ORDEN             IN NUMBER
                                 ,P_TIPO_ORDEN           IN VARCHAR2
                                 ,P_PORCENTAJE_COMISION  IN NUMBER
                                 ,P_USUARIO_SAE          IN VARCHAR2
								 ,P_ESPECIAL_FIDUCIARIO  IN VARCHAR2 
                                 ,P_CANTIDAD             IN NUMBER
                                 ,P_PRECIO               IN NUMBER
                                 ,P_MNEMOTECNICO         IN VARCHAR2
                                 ,P_USUARIO              IN VARCHAR2
                                 ,P_NOMBRE               IN VARCHAR2
                                 ,P_APELLIDO             IN VARCHAR2
								 ,P_CANAL_ORIGEN         IN VARCHAR2
                                 ,P_VALOR_COMISION       IN NUMBER
                                 ,P_ERRORES              OUT NUMBER);

END P_ORDENES_COMERCIAL;

/

  GRANT EXECUTE ON "PROD"."P_ORDENES_COMERCIAL" TO "R_FIXBROKER";
  GRANT EXECUTE ON "PROD"."P_ORDENES_COMERCIAL" TO "M_OP_SOPORTE_JEFE";
  GRANT EXECUTE ON "PROD"."P_ORDENES_COMERCIAL" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_ORDENES_COMERCIAL" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_ORDENES_COMERCIAL" TO "NOCTURNO";
