--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_SALDOS_CLIENTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_SALDOS_CLIENTES" AS
  TYPE O_CURSOR IS REF CURSOR;
  /* TODO enter package declarations (types, exceptions, methods etc) here */
  FUNCTION  F_SALDO_EN_CANJE(P_CLI_PER_NUM_IDEN    VARCHAR2,
                             P_CLI_PER_TID_CODIGO  VARCHAR2,
                             P_NUMERO_CUENTA       NUMBER,
                             P_DIAS_CANJE          NUMBER) RETURN NUMBER;

  FUNCTION  F_PRUEBAS_SALDO_CANJE(P_CLI_PER_NUM_IDEN    VARCHAR2,
                             P_CLI_PER_TID_CODIGO  VARCHAR2,
                             P_NUMERO_CUENTA       NUMBER,
                             P_DIAS_CANJE          NUMBER,
                             P_FECHA_CANJE          DATE) RETURN NUMBER;                             
  FUNCTION  F_SALDO_EN_CANJE_INICIAL(P_CLI_PER_NUM_IDEN    VARCHAR2,
                                     P_CLI_PER_TID_CODIGO  VARCHAR2,
                                     P_NUMERO_CUENTA       NUMBER) RETURN NUMBER;
  FUNCTION  F_FECHA_HABIL(P_FECHA_INICIAL DATE,
                          P_DIAS          NUMBER DEFAULT NULL) RETURN DATE;

  PROCEDURE P_DIA_MCC_CANJE(P_CLI_PER_NUM_IDEN     IN VARCHAR2,
                             P_CLI_PER_TID_CODIGO  IN VARCHAR2,
                             P_NUMERO_CUENTA       IN NUMBER,
                             P_FECHA_MCC           IN OUT DATE,
                             P_FECHA_VALIDA        IN OUT VARCHAR2);
  PROCEDURE P_CALCULO_SALDOS_CANJE(P_TX IN NUMBER DEFAULT NULL);
  PROCEDURE P_SALDO_INICIAL_CANJE;

  PROCEDURE P_PRUEBA_SALDOS_CANJE(P_CLI_PER_NUM_IDEN   VARCHAR2 DEFAULT NULL,
                                  P_CLI_PER_TID_CODIGO VARCHAR2 DEFAULT NULL,
                                  P_NUMERO_CUENTA      NUMBER DEFAULT NULL, 
                                  P_FECHA_CANJE        DATE DEFAULT NULL);
  PROCEDURE P_SALDOS_CARTERA (P_FECHA_PROCESO                  IN DATE
                             ,P_SALDO_A_FAVOR_CARTERA          IN OUT NUMBER
                             ,P_SALDO_EN_CONTRA_CARTERA        IN OUT NUMBER
                             ,P_ADMINISTRACION_VALORES         IN OUT NUMBER);
--------------------------------------------------------------------------------     
  PROCEDURE PR_DISP_SALDOS_CLIENTE (P_CLI_PER_NUM_IDEN IN CLIENTES.CLI_PER_NUM_IDEN%TYPE,
                                  P_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE,
                                  io_cursor IN OUT O_CURSOR);
--------------------------------------------------------------------------------     
  PROCEDURE PR_NO_DISP_SALDOS_CLIENTE (P_CLI_PER_NUM_IDEN IN CLIENTES.CLI_PER_NUM_IDEN%TYPE,
                                  P_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE,
                                  io_cursor IN OUT O_CURSOR);
--------------------------------------------------------------------------------  
  PROCEDURE PR_OTROS_SALDOS_CLIENTE (P_CLI_PER_NUM_IDEN IN CLIENTES.CLI_PER_NUM_IDEN%TYPE,
                                  P_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE,
                                  io_cursor IN OUT O_CURSOR);
-------------------------------------------------------------------------------- 
  FUNCTION  FN_SALDO_GARANTIA(P_CLI_PER_NUM_IDEN    VARCHAR2,
                             P_CLI_PER_TID_CODIGO   VARCHAR2,
                             P_NUMERO_CUENTA        NUMBER,
                             P_FECHA                DATE) RETURN NUMBER;
-------------------------------------------------------------------------------- 
END P_SALDOS_CLIENTES;

/

  GRANT EXECUTE ON "PROD"."P_SALDOS_CLIENTES" TO "COE_RECURSOS";
