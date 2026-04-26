--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_FONDOS_WEB
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_FONDOS_WEB" IS
/* Verifica si se coloca el indicador del parametro 25 de los fondos en 0
   para habilitarlos en la colocacion de ordenes */

   TYPE O_CURSOR IS REF CURSOR;

PROCEDURE HABILITAR_FONDO;

PROCEDURE FINCOLOCACION
 (FONDO VARCHAR);

PROCEDURE CREAJOB
 (FONDO VARCHAR);

PROCEDURE RENTABILIDAD_FONDOS
   (P_FECHA      DATE);

FUNCTION RENTABILIDAD
   (P_FECHA      DATE
   ,P_FON_CODIGO VARCHAR2
   ,P_DIAS       NUMBER) RETURN NUMBER;

FUNCTION F_OBTENER_FECHA_CIERRE_FONDO(P_FON_CODIGO VARCHAR2) RETURN DATE;

FUNCTION F_VALOR_FONDO(P_FONDO FONDOS.FON_CODIGO%TYPE
                      ,P_FECHA DATE) RETURN VALORIZACIONES_FONDO.VFO_VALOR%TYPE;

PROCEDURE ObtenerCarterasColectivas(P_CODIGO IN VARCHAR2,
                        P_RAZON_SOCIAL IN VARCHAR2,
                        P_TIPO IN VARCHAR2,
                        P_TIPO_ADMINISTRACION IN VARCHAR2,
                        io_cursor OUT O_CURSOR);

PROCEDURE ObtenerCuentasCarteras(P_TID_CODIGO IN VARCHAR2,
                        P_NUM_IDEN IN VARCHAR2,
                        P_NUMERO_CUENTA_CORREDORES IN NUMBER,
                        P_FON_CODIGO IN VARCHAR2,
                        P_ESTADO IN VARCHAR2,
                        P_ENVIAR_EXTRACTO IN VARCHAR2,
                        io_cursor OUT O_CURSOR);

PROCEDURE ObtenerMovCuentasCarteras(P_TID_CODIGO IN VARCHAR2,
                        P_NUM_IDEN IN VARCHAR2,
                        P_NUMERO_CUENTA_CORREDORES IN NUMBER,
                        P_FON_CODIGO IN VARCHAR2,
                        P_CFO_CODIGO IN NUMBER,
                        P_FECHA_INICIAL IN DATE,
                        P_FECHA_FINAL IN DATE,
                        io_cursor OUT O_CURSOR);

PROCEDURE PrepararDatosExtractos(P_FECHA_DESDE IN DATE,
                                 P_FECHA_HASTA IN DATE,
                                 P_RETORNO OUT NUMBER);
/* ********************************************************* */
PROCEDURE PR_OBTENER_INF_DIARIA_FDOS (P_FECHA_CORTE VARCHAR2,
                                IO_CURSOR IN OUT O_CURSOR);
/* ********************************************************* */
PROCEDURE PR_OBTENER_DET_INF_DIARIA_FDOS (P_FECHA_CORTE VARCHAR2,
                                P_FON_CODIGO VARCHAR2,
                                IO_CURSOR IN OUT O_CURSOR);
/* ********************************************************* */
PROCEDURE PR_MARCAR_CARTA_EXONERACION(P_CLI_PER_NUM_IDEN VARCHAR2,
                                      P_CLI_PER_TID_CODIGO VARCHAR2,
                                      P_FON_CODIGO VARCHAR2,
                                      P_RADICACION VARCHAR2,
                                      P_EJECUTADO  IN OUT VARCHAR2);
/* ********************************************************* */
PROCEDURE PR_VALIDAR_PERFIL_RIESGO(P_CLI_PER_NUM_IDEN VARCHAR2,
                                      P_CLI_PER_TID_CODIGO VARCHAR2,
                                      P_FON_CODIGO VARCHAR2,
                                      P_TIPO_OPERACION VARCHAR2,
                                      P_VALIDO  IN OUT VARCHAR2);
/* ********************************************************* */

/****************************************************************/
PROCEDURE PR_OBTENER_RENT_DIARIA_FDOS (P_FECHA_CORTE   IN DATE,
                                       P_FONDO         IN VARCHAR2,
                                       IO_CURSOR       IN OUT O_CURSOR);


PROCEDURE PR_OBTENER_RET_DET_DIA_FDOS (P_FECHA_CORTE DATE,
                                       P_FON_CODIGO  VARCHAR2,
                                       IO_CURSOR     IN OUT O_CURSOR);
/****************************************************************/

/************************************************************************************************
  Author  : VAGTUD937 Extractos Inteligentes Control Rentabilidades
  Created : 27/06/2023
  Purpose : Este procedimiento contempla la lógica para notificar la generación de los extractos.
  *************************************************************************************************/
PROCEDURE PR_MAIL_RENTABILIDADES;
/* ********************************************************* */
  -- Author  : OSMBALLESTEROS
  -- Created : 10/01/2025 10:00:09 a. m.
  -- Purpose : VALIDA SI EXISTE EL CODIGO DEL FONDO

FUNCTION F_OBTENER_CODIGO_FONDO_PPAL(p_fondo  IN VARCHAR2)
RETURN VARCHAR2;

FUNCTION F_VALIDA_CODIGO_FONDO(P_CODIGO_FONDO VARCHAR2) RETURN varchar2;
/* ********************************************************* */
  -- Author  : OSMBALLESTEROS
  -- Created : 10/01/2025 10:00:09 a. m.
  -- Purpose : OBTIENE LOS DATOS DEL CLIENTE Y DEL FONDO, VALIDA QUE TENGA SALDO EN EL FONDO

PROCEDURE PR_OBTENER_CLIENTE_FONDO(P_TIPO_CORRESPONDENCIA VARCHAR2,
                             P_ESTADO_CLIENTE       VARCHAR2,
                             P_PRIORIDAD_ENVIO      NUMBER,
                             IO_CURSOR              OUT SYS_REFCURSOR);


END P_FONDOS_WEB;

/

  GRANT EXECUTE ON "PROD"."P_FONDOS_WEB" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_FONDOS_WEB" TO "RESOURCE";
