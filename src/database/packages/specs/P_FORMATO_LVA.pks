--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_FORMATO_LVA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_FORMATO_LVA" AS 

DESTINATARIOS  VARCHAR2(1000) := 'procesosnocturnos@corredores.com;stecnico@corredores.com'
   || 'gestionfics@corredores.com;transmisiones@corredores.com';


PROCEDURE PR_EJECUTA_LVA;

PROCEDURE PR_GENERA_ARCHIVO
         (P_FECHA IN DATE
         ,P_INDICADOR IN VARCHAR2);

END P_FORMATO_LVA;

/

  GRANT EXECUTE ON "PROD"."P_FORMATO_LVA" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_FORMATO_LVA" TO "COE_RECURSOS";
