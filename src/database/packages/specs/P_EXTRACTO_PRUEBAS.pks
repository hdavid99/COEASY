--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_EXTRACTO_PRUEBAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_EXTRACTO_PRUEBAS" as

/************************************************************************************************
  Author  : VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  Created : 16/10/2020
  Purpose : Esta funcion permite identificar si un fondo tiene participaciones asociadas con el 
            parametro 71
*************************************************************************************************/
FUNCTION FN_VALIDAR_COMP (V_FON_CODIGO IN VARCHAR2) RETURN NUMBER;

PROCEDURE MAIL_EXTRACTO_CLIENTE;

PROCEDURE OPERACIONES;

PROCEDURE MAIL_PROCESO_EXTRACTO_FONDOS(P_TIPO_REPORTE  IN VARCHAR2,
                                       P_FECHA_INICIAL IN DATE DEFAULT NULL,
                                       P_FECHA_FINAL   IN DATE DEFAULT NULL);

PROCEDURE MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN     IN VARCHAR2 DEFAULT NULL,
                               P_CLI_PER_TID_CODIGO   IN VARCHAR2 DEFAULT NULL,
                               P_NUMERO_CUENTA        IN NUMBER   DEFAULT NULL,
                               P_FON_CODIGO           IN VARCHAR2 DEFAULT NULL,
                               P_FON_DESCRIPCION      IN VARCHAR2 DEFAULT NULL,
                               P_CUENTA_FONDO         IN NUMBER   DEFAULT NULL,
                               P_CADENA_ENVIO         IN VARCHAR2 DEFAULT NULL,
                               P_FECHA_PROCESO_INI    IN DATE     DEFAULT NULL,
                               P_FECHA_PROCESO_FIN    IN DATE     DEFAULT NULL,
                               P_CUENTA               IN VARCHAR2 DEFAULT NULL,
                               P_EXT_SECUENCIAL       IN NUMBER   DEFAULT NULL,
                               P_ERRORES              IN OUT      VARCHAR2,
                               P_FON_MNEMONICO        IN VARCHAR2 DEFAULT NULL,
                               P_ENVIO_MAIL           IN VARCHAR2 DEFAULT 'S', 
                               P_ENVIO_FTP            IN VARCHAR2 DEFAULT 'N',
                               P_REPROCESO            IN VARCHAR2 DEFAULT 'N',
                               P_TIPOREP              IN VARCHAR2 DEFAULT 'PARTICIPACION',
                               P_RANGREP              IN VARCHAR2 DEFAULT 'D');  

/************************************************************************************************
  Author  : VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  Created : 18/10/2020
  Purpose : Este procedimiento permite el reproceso de multicash fondos diario con las 
            condiciones historicas de generacion.
*************************************************************************************************/
PROCEDURE REP_MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   IN VARCHAR2 DEFAULT NULL,
                                   P_CLI_PER_TID_CODIGO IN VARCHAR2 DEFAULT NULL,
                                   P_NUMERO_CUENTA      IN NUMBER DEFAULT NULL,
                                   P_FON_CODIGO         IN VARCHAR2 DEFAULT NULL,
                                   P_CUENTA_FONDO       IN NUMBER DEFAULT NULL,
                                   P_FECHA_PROCESO      IN DATE DEFAULT NULL,
                                   P_EXT_SECUENCIAL     IN NUMBER DEFAULT NULL,
                                   P_EXT_CONSECUTIVO    IN NUMBER DEFAULT NULL,
                                   P_ERRORES            IN OUT VARCHAR2);

PROCEDURE MAIL_PROCESO_EXTRACTO_CUENTAS (P_TIPO_REPORTE  IN VARCHAR2,
                                         P_FECHA_INICIAL IN DATE DEFAULT NULL,
                                         P_FECHA_FINAL   IN DATE DEFAULT NULL);
PROCEDURE MAIL_EXTRACTO_CUENTAS(
                              P_CONV_CONSECUTIVO  IN NUMBER DEFAULT NULL,
                              P_ECP_TIPO_INFORME  IN VARCHAR2 DEFAULT NULL,
                              P_CADENA_ENVIO      IN VARCHAR2 DEFAULT NULL,
                              P_FECHA_PROCESO_INI IN DATE DEFAULT NULL,
                              P_FECHA_PROCESO_FIN IN DATE DEFAULT NULL,
                              P_TIPO_ENVIO        IN VARCHAR2 DEFAULT NULL,
                              P_ERRORES           IN OUT VARCHAR2,
                              P_ENVIO_MAIL        IN VARCHAR2 DEFAULT 'S', 
                              P_ENVIO_FTP         IN VARCHAR2 DEFAULT 'N',
                              P_REPROCESO         IN VARCHAR2 := 'N');
END P_EXTRACTO_PRUEBAS;

/

  GRANT EXECUTE ON "PROD"."P_EXTRACTO_PRUEBAS" TO "COE_RECURSOS";
