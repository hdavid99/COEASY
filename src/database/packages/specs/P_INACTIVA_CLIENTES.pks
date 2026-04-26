--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_INACTIVA_CLIENTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_INACTIVA_CLIENTES" IS
  PROCEDURE INACTIVAR_CLIENTES_UNICA_OP;
  
  FUNCTION VALIDA_SALDO (N_IDEN VARCHAR2,
                         T_IDEN VARCHAR2) RETURN VARCHAR2;
                         
  PROCEDURE INACTIVA_CLIENTE (N_IDEN VARCHAR2,
                              T_IDEN VARCHAR2);                     

END;

/
