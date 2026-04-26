--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_COSTOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_COSTOS" AS

TYPE O_CURSOR IS REF CURSOR;
PROCEDURE GENERAR_COSTOS_DECEVAL (P_FDESDE IN DATE, P_FHASTA IN DATE, P_COSTO IN VARCHAR2);


PROCEDURE P_DIRECCION_CORRESPONDENCIA_E 
 (P_NUM_IDEN IN VARCHAR2
 ,P_TID_CODIGO IN VARCHAR2
 ,P_DIRECCION OUT VARCHAR2
 ,P_TELEFONO OUT VARCHAR2
 ,P_CIUDAD OUT VARCHAR2
 ,P_CIUDAD_DECEVAL  OUT NUMBER 
 ,P_DEPARTAMENTO_DECEVAL OUT NUMBER
 ,P_PAIS_DECEVAL OUT VARCHAR2
 ,P_PAIS OUT VARCHAR2
 ,P_EMAIL OUT VARCHAR2
 ,P_DEPARTAMENTO OUT VARCHAR2
 ,P_DANE OUT VARCHAR2
 );
 
/* *************************************************************************************************************************
*** PROCEDIMIENTO PARA CALCULAR LOS COSTOS MEC RESULTADO DE SERVICIO DE BOLSA FIJO Y VARIABLE
*** ES LLAMADO POR EL PROCESO NOCTURNO COSTOS.SQL
*** ESTE COSTO TIENE UN PROCEDIMIENTO APARTE PORQUE LOS COSTOS BVC SE ORIGINAN UN DIA DESPUES DEL CARGUE DE LIQUIDACION
***  las variables de entrada son producto y fecha : en que se corre la actualizacion de los costos bvc
************************************************************************************************************************ */
PROCEDURE PR_COSTOS_MEC (P_FECHA IN DATE,
                         P_PRODUCTO IN VARCHAR2);
 
END P_COSTOS;

/

  GRANT EXECUTE ON "PROD"."P_COSTOS" TO "COE_RECURSOS";
