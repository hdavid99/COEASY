--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_OPERACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_OPERACIONES" IS

/***********************************************************************
 ***  Procedimiento de Causacion Automatica de Operaciones Bursatiles  **
 ***  Se corre en el proceso Nocturno                                  **
********************************************************************* */
PROCEDURE CAUSACION_OP_BURSATIL_DIARIA;

PROCEDURE INSERTA_ERROR 
   (P_PROCESO         ERRORES_PROCESOS.ERP_PROCESO%TYPE    
   ,P_ERROR           ERRORES_PROCESOS.ERP_ERROR%TYPE        
   ,P_TABLA_ERROR     ERRORES_PROCESOS.ERP_TABLA_ERROR%TYPE);

PROCEDURE CAUSACION;

FUNCTION VALIDA_DIVISAS 
   (TIPO_OP        IN VARCHAR2
   ,P_CONS         ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
   ,P_CTO          ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
   ,P_BOL          ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
   ,P_MONEDA       ORDENES_COMPRA.OCO_MONEDA_COMPENSACION%TYPE
   ,P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
   ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
   ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
   ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
   ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
   ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
   ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
   ,P_FECHA_OP     LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE) RETURN VARCHAR2;

PROCEDURE ACTUALIZAR_SALDO_C
   (P_TIPO_CAUSACION IN VARCHAR2
   ,P_OCO_CONS       ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
   ,P_OCO_CTO        ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
   ,P_OCO_BOL        ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
	 ,TIPOPE           IN VARCHAR2
	 ,P_NUMID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
	 ,P_TIPID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
	 ,P_CTANUM         CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
	 ,P_MON_C          ORDENES_COMPRA.OCO_MONEDA_COMPENSACION%TYPE
   ,P_LIC_BOL        LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
   ,P_LIC_OP         LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
   ,P_LIC_FR         LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
   ,P_LIC_TIPO       LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
   ,P_FECHA_OP       LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE);

PROCEDURE ACTUALIZAR_SALDO_V
   (P_TIPO_CAUSACION IN VARCHAR2
   ,P_OVE_CONS   ORDENES_VENTA.OVE_CONSECUTIVO%TYPE
   ,P_OVE_CTO    ORDENES_VENTA.OVE_COC_CTO_MNEMONICO%TYPE
   ,P_OVE_BOL    ORDENES_VENTA.OVE_BOL_MNEMONICO%TYPE
   ,TIPOPE       IN VARCHAR2
   ,P_NUMID      CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
   ,P_TIPID      CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
   ,P_CTANUM     CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
   ,P_MON_C      ORDENES_VENTA.OVE_MONEDA_COMPENSACION%TYPE
   ,P_LIC_BOL    LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
   ,P_LIC_OP     LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
   ,P_LIC_FR     LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
   ,P_LIC_TIPO   LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
   ,P_FECHA_OP   LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE);

PROCEDURE INSERTA_MOV_DIVISAS 
   (TIPO_OP        IN VARCHAR2
   ,MONTO_A_CAUSAR IN NUMBER
   ,P_CONS         ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
   ,P_CTO          ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
   ,P_BOL          ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
   ,P_MONEDA       ORDENES_COMPRA.OCO_MONEDA_COMPENSACION%TYPE
   ,P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
   ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
   ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
   ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
   ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
   ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
   ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
   ,P_FECHA_OP     LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE);

PROCEDURE GENERAR_AJUSTE
   (P_MONTO        MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE
   ,P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
   ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
   ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
   ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
   ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
   ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
   ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE);

/******************************************************************************
 *** OPERACIONES PENDIENTES POR CUMPLIR  : alistamiento de precumplimiento  ****
******************************************************************************/
PROCEDURE VENTAS_POR_CUMPLIR 
   (P_CTO VARCHAR2
   ,P_ORI VARCHAR2);

/******************************************************************************
 *** COMPENSACION SEBRA EN LA FECHA : CALCULADO                             ****
******************************************************************************/
PROCEDURE COMPENSACION_SEBRA 
   (P_FECHA DATE
   ,P_FLAG  VARCHAR2 DEFAULT NULL);

/***************************************************************************************************
*** COMPENSACION SEBRA EN UNA FECHA : CUANDO YA ESTA GUARDADO EN LA TABLA COMPENSACION_SEBRA ****
************************************************************************************************/
PROCEDURE COMPENSACION_SEBRA_HCO 
   (P_FECHA   DATE
   ,P_NEGOCIO NUMBER DEFAULT NULL
   ,P_FLAG    VARCHAR2 DEFAULT NULL);

/************************************************************************************************************
 ****  PROCEDIMIENTO PARA ENVIAR MAIL A LOS COMERCIALES Y JEFES DE MESA CON LAS OPERACIONES DE VENTA       ***
 ****  QUE EN LA ORDEN ESTASN EXCEDA SALDO O SIN TITULO Y ESTA PENDIENTE POR DEFINIR COMO SECUBRE EL SALDO ***
 ****  PENDIENTE A TRAVES DE LA FORMA DE ALISTAMIENTO DE PRECUMPLIMIENTO - OPPECU                          ***
*************************************************************************************************************/
PROCEDURE MAIL_VTAS_PENDIENTES(P_TX IN NUMBER DEFAULT NULL);

/******************************************************************************
 *** Manejo de saldos Bancos : CALCULADO                                    ****
******************************************************************************/
PROCEDURE SALDOS_SEBRA 
   (P_FECHA   DATE
   ,P_NEGOCIO NUMBER
   ,P_CUENTA  VARCHAR2
   ,P_FLAG    VARCHAR2 DEFAULT NULL);

/******************************************************************************
 *** Manejo de CLIENTES SEBRA : CALCULADO                                    ****
******************************************************************************/                        
PROCEDURE CLIENTES_SEBRA 
   (P_FECHA   DATE
   ,P_NEGOCIO NUMBER
   ,P_CUENTA  VARCHAR2
   ,P_FLAG    VARCHAR2 DEFAULT NULL );    

FUNCTION FN_PORTAFOLIO 
   (P_CCC_CLI_PER_NUM_IDEN VARCHAR2
   ,P_CCC_CLI_PER_TID_CODIGO VARCHAR2)  RETURN VARCHAR2;

/******************************************************************************
*** Manejo de Consolidado de Bancos                                  ****
******************************************************************************/                          
PROCEDURE CONSOLIDACION_BANCOS (P_FECHA DATE);

PROCEDURE COMPENSACION_DIVISAS 
   (P_FECHA DATE
   ,P_TIPO VARCHAR2);

PROCEDURE COMPENSACION_DIVISAS_TES
   (P_FECHA DATE
   ,P_TIPO VARCHAR2);    

PROCEDURE REPOS  
   (P_FECHA DATE
   ,P_NEGOCIO NUMBER
   ,P_CUENTA VARCHAR2
   ,P_FLAG    VARCHAR2 DEFAULT NULL);

FUNCTION F_COMISION 
   (P_CCC_CLI_PER_NUM_IDEN VARCHAR2 
   ,P_CCC_CLI_PER_TID_CODIGO VARCHAR2)   RETURN NUMBER;

PROCEDURE COMPENSACION_DIVISAS_CLIENTES 
   (P_FECHA DATE);

PROCEDURE COMPENSACION_DIV_CLI_TES 
   (P_FECHA DATE);

PROCEDURE COMPENSACION_DIVISAS_UTIL_PERD 
   (P_FECHA DATE);

PROCEDURE COMPENSACION_DIVISAS_BANCOS  
   (P_FECHA DATE);

PROCEDURE PAGOS_FLUJOS_DECEVAL;

PROCEDURE CALCULO_CONTRAPARTE_CV(P_ESPECIE IN VARCHAR2,
                                   P_FONDO   IN VARCHAR2,
                                   P_FECHA_EX_DIVIDENDO  IN DATE,
                                   P_FECHA_DESDE  IN DATE,
                                   P_FECHA_HASTA  IN DATE);

PROCEDURE VISTA_CONTRAPARTES (P_ISIN IN VARCHAR2
                             ,P_ESPECIE IN VARCHAR2
                             ,P_ID_CONTRAPARTE IN VARCHAR2
                             ,P_TID_CONTRAPARTE IN VARCHAR2
                             ,P_TID_NOMBRE IN VARCHAR2
                             ,P_NOMINAL_COMPRAS IN NUMBER
                             ,P_NOMINAL_VENTAS IN NUMBER                  
                             ,P_FONDO IN VARCHAR2
                             ,P_FECHA IN DATE
                             ,P_TIPO_COBRO IN VARCHAR2
                             ,P_FDT_DIVIDENDO IN NUMBER
                             ,P_FECHA_EX_DIVIDENDO IN DATE
                             ,P_FECHA_DESDE  IN DATE
                             ,P_FECHA_HASTA  IN DATE
                             ,P_MONTO_NO_GRAV_ANT_2017 IN NUMBER
                             ,P_MONTO_NO_GRAV_POST_2017 IN NUMBER
                             ,P_MONTO_SI_GRAV_POST_2017 IN NUMBER
                             );
TYPE O_CURSOR IS REF CURSOR;

PROCEDURE PR_TOTAL_CARGADO_GIRADO
   (P_LIC_NUMERO_OPERACION   IN NUMBER
   ,P_LIC_NUMERO_FRACCION    IN NUMBER
   ,P_LIC_TIPO_OPERACION     IN VARCHAR2
   ,P_LIC_BOL_MNEMONICO      IN VARCHAR2
   ,P_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2
   ,P_CCC_CLI_PER_TID_CODIGO IN VARCHAR2
   ,P_CCC_NUMERO_CUENTA      IN NUMBER
   ,P_PAGADA                 IN OUT VARCHAR2   
   ,P_NETO_GIRAR             IN OUT NUMBER
   ,P_TOTAL_GIRADO           IN OUT NUMBER);  

/*******************************************************************************************
***  Funcion calculo de comisiones unidad de fondos UDF  **
***************************************************************************************** */ 

FUNCTION FN_CALCULA_COMISION_UDF( 
TIPO VARCHAR2,
ENA VARCHAR2,
UNI_O_MON NUMBER
)
RETURN NUMBER;   

/*******************************************************************************************
***  Funcion que calcula el valor de la operacion para validar el valor maximo de operacion UdF - smorales
***************************************************************************************** */ 

FUNCTION FN_CALCULA_MONTO_UDF( 
P_TIPO VARCHAR2,
P_ENA VARCHAR2,
P_UNI_O_MON NUMBER
)
RETURN NUMBER;

/* **********************************************************************************************
***  Procedimiento que calcula informacion diaria para saber los costos asociados al convenio ***
***  Es llamado desde proceso nocturno y se debe correr despues de saldos_diarios             ***
********************************************************************************************** */ 
PROCEDURE PR_CONTROL_CONVENIOS (P_FECHA      IN DATE); 


/* *******************************************************************************************************
***  Procedimiento que llama el proceso de facturacion de convenios cuando el tipo de cobro es factura ***
***  Es llamado desde proceso nocturno                                                                 ***
******************************************************************************************************* */ 
PROCEDURE PR_FACTURACION_CONVENIOS (P_FECHA   IN DATE);

PROCEDURE PR_GENERA_AJUSTE_CFIC (
                          P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
                         ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
                         ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
                         ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                         ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                         ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
                         ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
                         ,P_MONTO        MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE
                         );


/*******************************************************************************************
***  Funcion calculo de comisiones unidad de fondos UDF   cuando se solicita cambio de la orden
***************************************************************************************** */ 

FUNCTION FN_COMISION_UDF_CAMBIO_ORDEN( 
P_PRECIO  NUMBER,
P_NOMINAL NUMBER
)
RETURN NUMBER;   

-- SORTIZ TRANSMISIONES
PROCEDURE P_CALCULA_DATOS(P_HINT VARCHAR2              
               ,P_EMISOR   VARCHAR2              
               ,P_ESPECIE  VARCHAR2              
               ,P_CONDICION_ESPECULATIVA VARCHAR2
               ,P_CONDICION  VARCHAR2            
               ,P_MERCADO  VARCHAR2              
               ,P_BOLSA  VARCHAR2);

PROCEDURE P_CUENTAS_BANCARIAS (P_FECHA DATE);
FUNCTION FN_SALDO_INICIAL (P_FECHA IN DATE, 
                           P_COD_BANCO IN NUMBER, 
                           P_CTA_BANCARIA IN VARCHAR2)   RETURN NUMBER;
FUNCTION FN_CHEQUES_X_COBRAR (P_FECHA         IN DATE, 
                              P_COD_BANCO     IN NUMBER, 
                              P_CTA_BANCARIA  IN VARCHAR2)   RETURN NUMBER;
FUNCTION FN_CHEQUES_GIRADOS ( P_FECHA         IN DATE, 
                              P_COD_BANCO     IN NUMBER, 
                              P_CTA_BANCARIA  IN VARCHAR2)   RETURN NUMBER;
FUNCTION FN_CUPO_INTRADIA (
                           P_FECHA         IN DATE, 
                           P_COD_BANCO     IN NUMBER, 
                           P_CTA_BANCARIA  IN VARCHAR2,
                           P_NEG_CONSECUTIVO IN NUMBER) RETURN NUMBER;





END P_OPERACIONES;

/

  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "JSUTACHA";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "SIS_SISTEMAS";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "YLADINO";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "SVELANDIA";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "AUD_AUDITORIA";
