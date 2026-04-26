--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_PROCESOS_NOCTURNOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_PROCESOS_NOCTURNOS" AS

  DESTINATARIOS VARCHAR2(1000) := 'procesosnocturnos@corredores.com';

  DESTINATARIOS_ADMON_VAL VARCHAR2(1000) := 'servicioalcliente@corredores.com';

  DESTINATARIOS_OPX VARCHAR2(1000) := 'jcarrillo@corredores.com;jvalencia@corredores.com;fchaves@corredores.com;grodriguez@corredores.com;procesosnocturnos@corredores.com';

  DESTINA_MACAULAY VARCHAR2(1000) := 'jparra@corredores.com;procesosnocturnos@corredores.com';

  DESTINATARIOS_CONF_ORDEN_FOND VARCHAR2(1000) := 'fondosdevalores@corredores.com';

  TYPE LISTA_CLI IS RECORD(
    PER_NUM_IDEN   VARCHAR2(15),
    PER_TID_CODIGO VARCHAR(3),
    TEXTO          VARCHAR2(2000));

  TYPE TYPE_LISTA_CLI IS TABLE OF LISTA_CLI INDEX BY BINARY_INTEGER;
  ARRAY_LISTA_CLI TYPE_LISTA_CLI;

  PROCEDURE P_SALDOS_DIARIOS_CLIENTES(FDESDE          IN DATE,
                                      FHASTA          IN DATE,
                                      P_NUM_IDEN      IN VARCHAR2,
                                      P_TID_CODIGO    IN VARCHAR2,
                                      P_NUMERO_CUENTA NUMBER,
                                      P_TX            IN NUMBER DEFAULT NULL);

  PROCEDURE P_SALDOS_DIARIOS_CLIENTES(FDESDE IN DATE,
                                      FHASTA IN DATE,
                                      P_TX   IN NUMBER DEFAULT NULL);

  PROCEDURE P_SALDOS_DIARIOS_FONDOS(FDESDE IN DATE,
                                    FHASTA IN DATE,
                                    P_TX   IN NUMBER DEFAULT NULL);

  PROCEDURE P_INSERT_SDF_MOVDIA(FECHA IN DATE, P_TX IN NUMBER DEFAULT NULL);

  FUNCTION P_FONDO_PADRE(P_NEGOCIO IN NUMBER) RETURN VARCHAR;

  PROCEDURE P_SALDOS_INCUMPLIDOS(P_FECHA DATE, P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE P_SALDOS_DIARIOS_DERIVADOS(FINICIO    IN DATE,
                                       FFIN       IN DATE,
                                       P_TEMPORAL IN VARCHAR2,
                                       P_TX       IN NUMBER DEFAULT NULL);

  PROCEDURE P_SALDOS_DIARIOS_DERIVADOS(FINICIO         IN DATE,
                                       FFIN            IN DATE,
                                       P_NUM_IDEN      IN VARCHAR2,
                                       P_TID_CODIGO    IN VARCHAR2,
                                       P_NUMERO_CUENTA IN VARCHAR2,
                                       P_TX            IN NUMBER DEFAULT NULL);

  PROCEDURE P_ACT_CONS_COLOCACION(P_VALOR VARCHAR2,
                                  P_TX    IN NUMBER DEFAULT NULL);

  /*********************************************************************************
  ***  Procedimiento que llama el  calculo de IMGF diario                         **
  ***  Se corre en el proceso Nocturno                                            **
  ***  se debe correr despues de las 12:00 no tiene limite de horario             **
  ***  Siempre evia mail al finalizar el proceso : con ERROR o EXITOSO            **
  ***  SE DEBE CORRER TODOS LOS DIAS                                              **
  ******************************************************************************* */
  PROCEDURE GENERAR_IMGF_DIARIO(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE P_NOC_PORTAFOLIO_FACTURAS;

  PROCEDURE P_NOC_PORTAFOLIO_FONDOS_RF;

  PROCEDURE P_NOC_PORTAFOLIO_FONDOS_RV;

  PROCEDURE P_CONFIRMA_ORDEN_FONDOS(FECHA_PROCESO DATE,
                                    P_SUC_CODIGO  NUMBER DEFAULT NULL,
                                    P_ORDEN       NUMBER DEFAULT NULL,
                                    P_TX          IN NUMBER DEFAULT NULL);

  PROCEDURE P_BORRADO_CENLINEA;

  PROCEDURE P_SALDOS_DIARIOS_DIVISAS(FINICIO IN DATE,
                                     FFIN    IN DATE,
                                     P_TX    IN NUMBER DEFAULT NULL);

  -- DEFINICION
  /**********************************************************************************
  ***  Procedimiento  PR_CUPOS_BANCOS para:                                        **
  ***  1. Guardar la informacion diaria de cupos de bancos y cuentas               **
  ***  2. Generar ordenes de pago de uso de cupo con que deben iniciar las cuentas **
  ***  se debe correr despues de las 12:00 no tiene limite de horario              **
  ***  Siempre evia mail al finalizar el proceso : con ERROR o EXITOSO             **
  ***  SE DEBE CORRER TODOS LOS DIAS                                               **
  ******************************************************************************** */
  PROCEDURE PR_CUPOS_BANCOS(P_FECHA IN DATE);

  PROCEDURE P_NOC_PORTAFOLIO_FONDOS_RF_PP;

  PROCEDURE P_NOC_PORTAFOLIO_FONDOS_RV_PP;

  PROCEDURE PR_DISTRIBUYE_PP_CCIAL(P_FECHA IN DATE,P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE PR_CRUCE_PAGOS_OPERACIONES;

  PROCEDURE PR_OPX_PORTAFOLIO;

  PROCEDURE PR_OPX_MOVIMIENTOS;

  PROCEDURE PR_CLIENTES_EXENTOS(P_ES_NOCTURNO IN VARCHAR2);

  PROCEDURE PR_TRANSFERENCIAS_CORLINE;

  PROCEDURE PR_PROCESOS_OPX;

  PROCEDURE PR_VINCULACION_BUKCOE;

  PROCEDURE PR_ACT_RENTAB_VOLATIL(P_TX IN NUMBER DEFAULT NULL);

  /***********************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.P_NOC_GARANTIAS_EFECTIVO                              **
  ***     realiza llamado a proceso que guarda diariamente las garantias en efectivo de clientes **
  ***     se debe enviar todos los dias: borra la informacion de la fecha y la vuenve a insertar **
  ***     debe correr antes de:                                                                  **
  ***         proceso de segmentacion  P_PROCESOS_NOCTURNOS.P_NOC_SEGMENTA_CLI                   **
  ***         procesos de CORLINE                                                                **
  /********************************************************************************************* */
  PROCEDURE PR_NOC_GARANTIAS_EFECTIVO(P_TX IN NUMBER DEFAULT NULL);

  /********************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.P_NOC_SEGMENTA_CLI                                            **
  ***     realiza llamado a proceso de segmentacion de clientes                                          **
  ***     se corre todos los dias pero se ejecuta s¿lo el sabado anterior a 01 de Enero y 01 de Julio    **
  /***************************************************************************************************** */
  PROCEDURE PR_NOC_SEGMENTA_CLI(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE PR_INACTIVA_COTRATO_DERIVADOS(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE CALCULO_DUR_MACAULAY;

  /***********************************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.PR_NOC_CONV_REC_PAGOS                                                        **
  ***     - realiza llamado a proceso  P_TESORERIA.PR_PAG_REC_DIA  : PROCEDIMIENTO NOCTURNO PARA CONTAR                 **
  ***       EL TOTAL DE RECAUDOS Y PAGOS DIARIOS POR BANCO POR CLIENTE DEL CONVENIO PARA CONVENIOS CON RECIPROCIDAD     **
  ***     -se corre todos los dias                                                                                      **
  /******************************************************************************************************************** */
  PROCEDURE PR_NOC_CONV_REC_PAGOS;

  /**************************************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.PR_NOC_CONTROL_CONVENIOS                                                        **
  ***     - realiza llamado a proceso  P_OPERACIONES.PR_CONTROL_CONVENIOS : PROCEDIMIENTO QUE CALCULA LOS COSTOS           **
  ***       ASOCIADOS AL CLIENTE Y AL CONVENIO, DIA A DIA PARA SER MOSTRADA EN LA FORMA COCOCO                             **
  ***     - se corre todos los dias                                                                                        **
  ***     - SE DEBE CORRER DESPUES DEL PROCESO NOCTURNO SALDOS_DIARIO                                                      **
  /*********************************************************************************************************************** */
  PROCEDURE PR_NOC_CONTROL_CONVENIOS;

  /******************************************************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.PR_NOC_CONV_TOTAL_BANCO                                                                         **
  ***     - realiza llamado a proceso  P_BANCOS.PR_TOTALES_TIPOS_BANCOS :PROCEDIMIENTO QUE CALCULA LOS COSTOS POR CONVENIO Y TIPO DE BANCO **
  ***     - se corre todos los dias                                                                                                        **
  /*************************************************************************************************************************************** */
  PROCEDURE PR_NOC_CONV_TOTAL_BANCO;

  /*****************************************************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.PR_FACTURA_CONVENIOS                                                                           **
  ***     - realiza llamado a proceso  P_BANCOSP_OPERACIONES.PR_FACTURACION_CONVENIOS :PROCEDIMIENTO PARA FACTURACION DIARIA DE CONVENIOS **
  ***     - se corre todos los dias                                                                                                       **
  ***     - DEBE CORRER DESPUES DE LOS PROCESOS NOCTURNOS:PR_NOC_CONV_REC_PAGOS,PR_NOC_CONTROL_CONVENIOS Y PR_NOC_CONV_TOTAL_BANCO        **
  /*************************************************************************************************************************************** */
  PROCEDURE PR_FACTURA_CONVENIOS;

  /*****************************************************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.PR_SALDOS_CMA                                                                           **
  ***     - realiza llamado a proceso  P_NOTIFICACION_CMA.PR_NOTIF_SALDOS :PROCEDIMIENTO PARA LA NOTIFICACI¿N DIARIA DE SALDOS A CMA **
  ***     - se corre todos los dias                                                                                                       **
  ***     -         **
  /*************************************************************************************************************************************** */
  PROCEDURE PR_SALDOS_CMA;

  /*****************************************************************************************************************************************
  ***  PROCEDIMIENTO  P_PROCESOS_NOCTURNOS.PR_BLOQUEA_CLI_PLV   **
  ***     - realiza llamado a proceso  PR_BLOQUEA_CLI_PLV.PR_BLOQUEA_CLI_PLV :PROCEDIMIENTO PARA BLOQUEAS CLIENTS INGRESADOS POR PLV      **
  ***     - se corre todos los dias                                                                                                       **
  ***     -         **
  /*************************************************************************************************************************************** */

  PROCEDURE PR_BLOQUEA_CLI_PLV;

  PROCEDURE PR_GENERACION_VISTAS_OPEN;

  PROCEDURE PR_MARCACION_ADMON_VAL;

  PROCEDURE MAIL_TID_CER_PENDIENTES_COMER(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE MAIL_TID_CER_PENDIENTES_COORD(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE P_NOC_FORMATO_519;

  PROCEDURE P_BORRADOS_DIARIOS(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE P_SALDOS_NO_DISPO_APE;

  PROCEDURE PR_LIMPIAR_INFOVALMER(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE PR_BORRAR_INF_PIP(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE P_NOC_FORMATO_230;

  PROCEDURE P_PORTAFOLIO_CLIENTES(P_FECHA DATE);

  PROCEDURE P_CONSULTA_PORTAFOLIO;

  PROCEDURE PR_MAIL_TRANS_VIGIA;

  PROCEDURE PR_GENERAR_GEACO;

  --------ENVIA DE EXTRACTOS DERIVADOS
  PROCEDURE PR_ENVIO_EXTRACTOS_DERIVADOS(P_FECHA  IN DATE,
                                         P_USERID IN VARCHAR2);

  -- PAGO RENDIMIENTOS FONDO INMOBILIARIO
  PROCEDURE PR_CONFIRMA_ORDEN_PRI(P_TX IN NUMBER DEFAULT NULL);

  -- NOTIFICACION PAGOS PROXIMOS FONDO MULTIESCALA
  PROCEDURE PR_NOTIFICACION_MULTIESCALA;

  /*******************************REPORTES NOCTURNOS*********************************/
  PROCEDURE PR_REPORTE_NEXT_DAY(P_USERID IN VARCHAR2);
  PROCEDURE PORTAFOLIO_VALORACION;
  PROCEDURE PR_REPORTE_COPORF_CD(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_COPORF_VL(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_REXCLS1_PP(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RECOFU(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RVALCO(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RPYGFO(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RECAFO(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RORRDS(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_LIFVES_FF(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_LIFVES_FG(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RCVTCR(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_CSVFO(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_COMFCP;
  PROCEDURE PR_REPORTE_CBNOCO;
  PROCEDURE PR_REPORTE_COMODE;
  PROCEDURE PR_REPORTE_ROPDER(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_REXCLF_MES(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_REXCLF_ACUM(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_REXCLS(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_REXCLS3(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RMOVBA(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RCMVTF(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RINVRV(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RREPRV(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RSINRV(P_USERID IN VARCHAR2);
  /******************PROCEDIMIENTO DE EJECUCI¿N DIARIA**************************/
  PROCEDURE PR_GENERA_REPORTES_DIARIO(P_USERID IN VARCHAR2);
  /******************PROCEDIMIENTO DE EJECUCI¿N MENSUAL**************************/
  PROCEDURE PR_GENERA_REPORTES_MENSUAL(P_USERID IN VARCHAR2);
  /*******************************FIN REPORTES NOCTURNOS*********************************/

  /*******************************INICIO REPORTES NOCTURNOS A2*********************************/
  PROCEDURE PR_REPORTE_RORRDS_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_REMOCL_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RTIPVE_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RMOVBA_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RMOVBA_CE_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RECACL_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RECACL_CON_A2(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RECADE_A2(P_USERID IN VARCHAR2);
  PROCEDURE PORTAFOLIO_VALORACION_A2;
  PROCEDURE OPERACIONES_ESPECIALES;
  PROCEDURE RMOVBA_S3(P_USERID IN VARCHAR2);
  PROCEDURE CONCILIACION_NEGOCIOS;
  PROCEDURE ROPEFE_S3(P_USERID IN VARCHAR2);
  PROCEDURE REPCUM(P_USERID IN VARCHAR2);
  PROCEDURE REMOCL(P_USERID IN VARCHAR2);
  PROCEDURE RCIDIV(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RPYGFO_3(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTES_FINACIERA(P_USERID IN VARCHAR2);
  PROCEDURE PR_GENERA_REPORTES_A2(P_USERID IN VARCHAR2);
  /*******************************INICIO REPORTES NOCTURNOS A2*********************************/

  PROCEDURE PR_NOTIFICA_VCTOS_SEMANAL;
  PROCEDURE PR_NOTIFICA_VCTO_ACT_DATOS;
  /*******************************INICIO SALDOS CUENTAS BANCARIAS LDA******************************/
  PROCEDURE PRC_SALDOS_DISPONIBLES_LVA;
  /*******************************FIN SALDOS CUENTAS BANCARIAS LDA******************************/
  PROCEDURE PR_NOTIFICA_SALDOS_FONDOS;
  /****************NOTIFICACION ORDENES DE COMPRA Y VENTA EN T3 ********************/
  PROCEDURE PR_NOTIFICAR_ORD_RF_RV(P_FECHA DATE);
  /************************************/
  PROCEDURE PR_GENERAR_ESTADISTICAS_SMS;
  --NOTIFICACION LIMITES SARIC
  PROCEDURE PR_LIMITES_SARIC;
  -- VALIDACION PARA PROCESO DE DILUCION DE RENDIMIENTOS FICI
  PROCEDURE P_VALIDA_APERTURA;
  --------------------------
  -------------------------------------------------DIN¿MICAS CONTABLES FASE 1------------------------------------------------------------------------------------
  PROCEDURE PR_REPORTE_RMOVRE_MES(P_USERID IN VARCHAR2);
  PROCEDURE PR_REPORTE_RMOVRE_ACUM(P_USERID IN VARCHAR2);
  PROCEDURE PR_GENERA_REPORTES_DINAMICAS(P_USERID IN VARCHAR2);

  -------------------------------------------------FIN DIN¿MICAS CONTABLES FASE 1------------------------------------------------------------------------------------
  /***************************************************************************************
  ************* PROCEDIMIENTO P_RECALCULO_SALDOS ****************
  ************* Se ejecuta diariamente********************************************************
  *****************************************************************************************/

  PROCEDURE P_RECALCULO_SALDOS;

  /***********************************************************************************************************************
  ***  PROCEDIMIENTO P_PROCESOS_NOCTURNOS.P_CALL_GENERA_CRUCE_PER_CAU                                                   **
  ***  VAGTUS043686.AjusteModuloCargueListas Cruce de listas de cautela                                                 **
  ***  Ejecucion: diario Hora: 0300Hrs                                                                                  **
  /**********************************************************************************************************************/
  PROCEDURE P_CALL_GENERA_CRUCE_PER_CAU;
  /***********************************************************************************************************************
  ***  PROCEDIMIENTO P_PROCESOS_NOCTURNOS.P_MAIL_CRUCE_CAU_FACT                                                         **
  ***  Proyecto Factoring VAGTUD876 - Env¿a correo sobre las coincidencias en las listas de cautela con Emisor/Pagador  **
  /**********************************************************************************************************************/
  PROCEDURE P_MAIL_CRUCE_CAU_FACT;
  /***********************************************************************************************************************
  ***  PROCEDIMIENTO P_PROCESOS_NOCTURNOS.P_ARCHIVO_PORTAFOLIO_FACT                                                     **
  ***  Proyecto Factoring VAGTUD876                                                                                     **
  /**********************************************************************************************************************/
  PROCEDURE P_ARCHIVO_PORTAFOLIO_FACT;
  /**********************************************************************************************************************/
  /***********************************************************************************************************************
  ***  PROCEDIMIENTO P_PROCESOS_NOCTURNOS.P_CALL_VERIFICA_CIERRE                                                        **
  ***  VAGTUS045614.ControlInformacionCierrePortafolios                                                                 **
  ***  Ejecucion: diario Hora: 0500Hrs                                                                                  **
  /**********************************************************************************************************************/
  PROCEDURE P_CALL_VERIFICA_CIERRE;
  /**********************************************************************************************************************/

  /***********************************************************************************************************************
  ***  PROCEDIMIENTO P_PROCESOS_NOCTURNOS.P_CALL_INACTIVAR_CLIENTES                                                     **
  ***  VAGTUS048046.AutomatizacionProcesoInactivacionClientes                                                           **
  ***  Ejecucion: Solo el primer d¿a h¿bil de cada mes a las 0300Hrs                                                    **
  /**********************************************************************************************************************/
  PROCEDURE P_CALL_INACTIVAR_CLIENTES;
  /**********************************************************************************************************************/

  /***********************************************************************************************************************
  ***  PROCEDIMIENTO P_PROCESOS_NOCTURNOS.P_CALL_GNRA_REPCIERRE                                                        **
  ***  VAGTUS045745.ReporteInformacionDavivienda                                                                **
  ***  Ejecucion: diario Hora: 0500Hrs                                                                                  **
  /**********************************************************************************************************************/
  PROCEDURE P_CALL_GNRA_REPCIERRE;
  /**********************************************************************************************************************/

  -------------------------------------REPORTES PLANO INTEGRADO V------------------------------------
  FUNCTION FECHA_ORIG_CUMPLI(P_TITULO NUMBER) RETURN DATE;
  FUNCTION VALORIZACION(P_FONDO  VARCHAR2,
                        P_TITULO NUMBER,
                        P_FECHA  DATE,
                        P_365    NUMBER,
                        P_BMO    VARCHAR2) RETURN NUMBER;
  PROCEDURE GENERA_RECOFU_TODOS;
  PROCEDURE GENERA_RECOFU_VENTAS_TODOS;
  PROCEDURE GENERA_RCOND;
  PROCEDURE P_EJECUTA_RCOND;
  FUNCTION DIAS_VENCIMIENTO(P_CUMPL    DATE,
                            P_FECHA    DATE,
                            P_CONTRATO VARCHAR2) RETURN NUMBER;
  FUNCTION PRECIO_MERCADO_TM1(P_CONTRATO VARCHAR2, P_FECHA DATE)
    RETURN NUMBER;
  FUNCTION PRECIO_MERCADO(P_CONTRATO VARCHAR2, P_FECHA DATE) RETURN NUMBER;
  FUNCTION VALOR_MERCADO(P_OBLIG    NUMBER,
                         P_DER      NUMBER,
                         P_CONTRATO NUMBER,
                         P_PUNTA    VARCHAR2) RETURN NUMBER;
  PROCEDURE P_EJECUTA_ROPDER;
  PROCEDURE PR_REPORTE_PYGFON(P_USERID IN VARCHAR2);
  PROCEDURE P_EJECUTA_INPOAD;
  PROCEDURE P_GENERA_SAMOBS;
  FUNCTION DIA_HABIL(FECOPE IN DATE, FECCUM IN DATE) RETURN NUMBER;
  FUNCTION VALOR_TIPO_OPERACION(INDICADOR_SWAP        VARCHAR2,
                                INDICADOR_CARRUSEL    VARCHAR2,
                                TIPO_OFERTA           VARCHAR2,
                                CONDICION_NEGOCIACION VARCHAR2,
                                FECHA_OPERACION       DATE,
                                FECHA_CUMPLIMIENTO    DATE,
                                CLASE_TRANSACCION     VARCHAR2) RETURN CHAR;
  FUNCTION VALORACION_PESOS(OVE_ENA_MNEMONICO VARCHAR2,
                            FECHA_VALORACION  DATE,
                            VALORACION_TM     NUMBER) RETURN NUMBER;
  FUNCTION IVA(TIPO_OPERACION   VARCHAR2,
               NUMERO_OPERACION NUMBER,
               NUMERO_FRACCION  NUMBER,
               BOL_MNEMONICO    VARCHAR2) RETURN NUMBER;
  FUNCTION RETEFTE(TIPO_OPERACION   VARCHAR2,
                   NUMERO_OPERACION NUMBER,
                   NUMERO_FRACCION  NUMBER,
                   BOL_MNEMONICO    VARCHAR2) RETURN NUMBER;
  FUNCTION PAQUETE(TIPO_OPERACION   VARCHAR2,
                   NUMERO_OPERACION NUMBER,
                   NUMERO_FRACCION  NUMBER,
                   BOL_MNEMONICO    VARCHAR2) RETURN VARCHAR2;
  FUNCTION ISIN(OVE_ENA_MNEMONICO VARCHAR2) RETURN VARCHAR2;
  PROCEDURE GENERA_OPEBOL_DIA;
  PROCEDURE GENERA_OPEBOL_CUMPLIR;
  PROCEDURE P_EJECUTA_OPEBOL;
  PROCEDURE PR_REPORTE_RCONRV(P_USERID IN VARCHAR2);
  PROCEDURE P_GENERA_REPORTES_RIESGOS(P_USERID IN VARCHAR2);
  PROCEDURE P_EJECUTA_RECOFU;
  PROCEDURE P_EJECUTA_ORDENES;
  PROCEDURE P_EJECUTA_CIDIDI;
  PROCEDURE PR_EJECUTA_FORMATO_531_GENERAL(P_FECHA DATE);
  PROCEDURE P_EJECUTA_REPGAR_BVC; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_EJECUTA_REPGAR_DCRCC; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_EJECUTA_REPGAR_REPOS; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_EJECUTA_REPGAR_DSCB; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_EJECUTA_REPGAR_PRORRATEO; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_EJECUTA_CODEOR2; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_EJECUTA_COORRE; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_CORREO_EXCESO_CONSUMO_LIMCOS; --CORREO LIMCOS PLANO INTEGRADO 5 PARTE B - JCALDERON
  PROCEDURE P_REOPRV; --REPORTES PLANO INTEGRADO 5 PARTE B - JCALDERON
  -------------------------------------FIN REPORTES PLANO INTEGRADO V------------------------------------
  PROCEDURE P_REVERSIONES_DAVIVIENDA;
  -------------------------------------INICIO P_CREA_PARTICION V------------------------------------

  PROCEDURE P_CREA_PARTICION;

  PROCEDURE P_CREA_SALDOS_FONDOS_PORTAL(P_FECHA_PROCESO DATE DEFAULT NULL);
  PROCEDURE P_CREA_SALDOS_CUENTAS_PORTAL(P_FECHA_PROCESO DATE DEFAULT NULL);
  PROCEDURE P_CREA_SALDOS_DERIVADOS_PORTAL(P_FECHA_PROCESO DATE DEFAULT NULL);

  PROCEDURE P_PROCESO_PRECIA(P_FECHA DATE);

  PROCEDURE P_LIMPIA_HISTORICO_SALDOS;

  PROCEDURE PR_BLOQUEO_USUARIO_NOCTURNO;

  PROCEDURE CALCULAR_SALDO(P_SALDO_INVER    IN OUT NUMBER,
                           P_SALDO_UNIDADES IN OUT NUMBER,
                           NUM_IDEN         VARCHAR2,
                           TID              VARCHAR2,
                           NUMERO_CUENTA    NUMBER,
                           FONDO            VARCHAR2,
                           APORTE           NUMBER);

  PROCEDURE P_COORRE_HISTORICO;

  PROCEDURE P_LIMITES_CLIENTES;

  PROCEDURE P_LIMCOS;
  PROCEDURE P_EJECUTA_VAPAEMI;

  ----------------------
  --REPORTES PARA CONTRALORIA
  ---------------------

  PROCEDURE PR_REPORTE_MOVIMIENTOS(P_FECHA DATE);
  PROCEDURE PR_REPORTE_RENTA_VARIABLE(P_FECHA DATE);
  PROCEDURE PR_REPORTE_RENTA_FIJA(P_FECHA DATE);
  PROCEDURE P_INSERT_PAG_EMISOR(P_FECHA         DATE,
                                P_ESPECIE       VARCHAR2,
                                P_ISIN          VARCHAR2,
                                P_VALOR_NOMINAL NUMBER,
                                P_VALOR_EMISOR  NUMBER,
                                P_VALOR_COEASY  NUMBER,
                                P_CUSTODIO      VARCHAR2,
                                P_FONDO         VARCHAR2);

  PROCEDURE P_EJECUTA_GARCLI; -- SORTIZ TRANSMISIONES SIMULTANEAS 2
  PROCEDURE P_GENERA_CORTOS; -- SORTIZ TRANSMISIONES SIMULTANEAS 2

  -- VAGTUD881-6 INVERSIONES INT FONDOS MUTUOS
  PROCEDURE PR_INVINT_OPFESTIVOS;

  --VAGTUS074466
  PROCEDURE PR_ACT_MICROINVERSIONISTA;

  --VAGTUS084938--Solucion Incidente
  PROCEDURE PR_ACT_ORDENES_RBDDNH;

  -------------------------------PLANO INTEGRADO 8 VAGTUD990----------------------------

  PROCEDURE P_EJECUTA_FIRECA;
  PROCEDURE P_EJECUTA_RFLVNF;
  PROCEDURE P_EJECUTA_REINEG;
  PROCEDURE P_EJECUTA_MANSIM;
  PROCEDURE P_EJECUTA_MANSIM_NEG;
  PROCEDURE P_EJECUTA_DATCLI;

  --INICIO VAGTUD978 - Arbitraje
  PROCEDURE OPCONTADO_INVINT_AUTO;
  PROCEDURE PORTAFOLIO_INVERSIONESINT;
  PROCEDURE PR_REPORTE_RECBEF(P_USERID IN VARCHAR2);
  -- FIN VAGTUD978 - Arbitraje

END P_PROCESOS_NOCTURNOS;

/

  GRANT EXECUTE ON "PROD"."P_PROCESOS_NOCTURNOS" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_PROCESOS_NOCTURNOS" TO "RESOURCE";
