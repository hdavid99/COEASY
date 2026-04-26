--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_CONTABILIZAR_DIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_CONTABILIZAR_DIA" IS
/*TYPE procesos IS RECORD
( NUMERO_PROCESO   NUMBER,
  NEGOCIO          NUMBER);
TYPE r_procesos IS TABLE OF procesos INDEX BY BINARY_INTEGER;  
TYPE lista_negocio IS RECORD(
  NEGOCIO NUMBER(5));
TYPE r_lista_negocio IS TABLE OF lista_negocio INDEX BY BINARY_INTEGER;
-- Sub-Program Unit Declarations
*/
PROCEDURE P_CONTAB_DIA;
PROCEDURE P_CONTAB_DIA                (P_FECHA IN DATE );
PROCEDURE P_CONTAB_BANCOS             (P_FECHA IN DATE );
PROCEDURE P_CONTAB_BANCOS_EXTERIOR    (P_FECHA IN DATE );
PROCEDURE P_CONTAB_DIVISAS            (P_FECHA IN DATE );
PROCEDURE P_CONTAB_TERCEROS           (P_FECHA IN DATE );
PROCEDURE P_CONTAB_CLIENTES           (P_FECHA IN DATE );
PROCEDURE P_CONTAB_APTS               (P_FECHA IN DATE );
PROCEDURE P_CONTAB_FACTURAS           (P_FECHA IN DATE );
PROCEDURE P_CONTAB_APORTES_FONDOS     (P_FECHA IN DATE );
PROCEDURE P_CONTAB_INVERSIONES_FONDOS (P_FECHA IN DATE);
PROCEDURE P_CONTAB_POSPROPIA          (P_FECHA IN DATE
                                      ,P_PFO_PAR_CODIGO IN NUMBER
                                      ,P_DPP_TDP_MNEMONICO IN VARCHAR2);
PROCEDURE P_CONTAB_ADMON_VALORES      (P_FECHA IN DATE );
PROCEDURE P_CONTAB_INMOBILIARIO       (P_FECHA IN DATE );
PROCEDURE P_CONTAB_ING_EGR            (P_FECHA IN DATE );
PROCEDURE P_CONTAB_DERIVADOS_FONDOS   (P_FECHA IN DATE);
PROCEDURE P_CONTAB_FONDOS_RV          (P_FECHA IN DATE
                                      ,P_DPP_TDP_MNEMONICO IN VARCHAR2);

-- MES: Proyecto Divisas - se adicionan las dos nuevas dinamicas
PROCEDURE P_CONTAB_CBAN_EXTFON   (P_FECHA IN DATE);
PROCEDURE P_CONTAB_DIVISAS_FON   (P_FECHA IN DATE);
PROCEDURE P_CONTAB_COMPROM_FUT   (P_FECHA IN DATE);

-- VAGTUD881 - INVERSIONES INTERNACIONALES
PROCEDURE P_CONTAB_INVINT_FON   (P_FECHA IN DATE);

-- VAGTUD975-3 INVERSIONES EN CREDITOS - FONDOS
PROCEDURE P_CONTAB_CREDITOS_FON (P_FECHA IN DATE);

DESTINATARIOS  VARCHAR2(1000) := 'procesosnocturnos@corredores.com;'
   || 'crojas@corredores.com;aruiz@corredores.com;jmaldonado@corredores.com;'
   || 'evillareal@corredores.com;gerodriguezr@corredores.com';
--------------------------------------------
/************************************************************************************************
Purpose : Procedimiento utilizado para eliminar/depurar datos de log o trazabilidad generados en dinamicas x VAGTUS097444
Author  : Yorely Ortiz
Created : 19/07/2024
************************************************************************************************/     
 PROCEDURE P_DEP_DINAMICA_LOGS(P_NDIAS  IN NUMBER DEFAULT 183);

END P_CONTABILIZAR_DIA;

/

  GRANT EXECUTE ON "PROD"."P_CONTABILIZAR_DIA" TO "NOCTURNO";
