--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_GRP_RELACIONADOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_GRP_RELACIONADOS" AS

  /* Descripcion: Paquete para la administracion de Grupos Relacionados
     Modulo Relacionado: GRPREL.fmb
     Fecha Creacion: 08/11/2017*/
   /* ********************************************************* */
  PROCEDURE PR_CLIENTES;   
  /* ********************************************************* */   
  PROCEDURE PR_CREA_GRUPOS(P_CLI_PER_NUM_IDEN VARCHAR2, P_CLI_PER_TID_CODIGO VARCHAR2);
 
  /* ********************************************************* */  
  PROCEDURE PR_ACTUALIZA_GRUPOS(P_FECHA DATE);
  

  
END P_GRP_RELACIONADOS;

/

  GRANT EXECUTE ON "PROD"."P_GRP_RELACIONADOS" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_GRP_RELACIONADOS" TO "SIS_SISTEMAS";
