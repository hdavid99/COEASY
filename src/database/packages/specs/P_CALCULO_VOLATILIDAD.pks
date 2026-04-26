--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_CALCULO_VOLATILIDAD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_CALCULO_VOLATILIDAD" IS

                                  
   FUNCTION F_VOLAT_ULT_MES
      (P_FECHA  IN DATE
      ,P_FONDO IN VARCHAR2
      )RETURN NUMBER;
   FUNCTION F_VOLAT_ULT_6MES
      (P_FECHA  IN DATE
      ,P_FONDO  IN VARCHAR2
      )RETURN NUMBER;
   FUNCTION F_VOLAT_ANO_CORRIDO
      (P_FECHA  IN DATE
      ,P_FONDO  IN VARCHAR2
      )RETURN NUMBER;
   FUNCTION F_VOLAT_ULT_ANO
      (P_FECHA  IN DATE
      ,P_FONDO  IN VARCHAR2
      )RETURN NUMBER;
   FUNCTION F_VOLAT_ULT_2ANO
      (P_FECHA  IN DATE
      ,P_FONDO  IN VARCHAR2
      )RETURN NUMBER;
   FUNCTION F_VOLAT_ULT_3ANO
      (P_FECHA  IN DATE
      ,P_FONDO  IN VARCHAR2
      )RETURN NUMBER;
   PROCEDURE INSERTAR_VOLATIL
      (FEC DATE
      ,P_TX IN NUMBER DEFAULT NULL);

END P_CALCULO_VOLATILIDAD;

/

  GRANT EXECUTE ON "PROD"."P_CALCULO_VOLATILIDAD" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_CALCULO_VOLATILIDAD" TO "COE_RECURSOS";
