--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_REPORTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_REPORTES" IS

/**  PROCEDIMIENTO PARA GUARDAR LA INFORMACION DE SALDOS DE FONDOS, SALDOS DECEVAL EN PESOS, SALDOS DCV EN PESOS
     EN LA TABLA SALDOS_CLIENTES, BASE PARA EL REPORTE RSTIPE . Si la hora es antes de las 6.00 am, corre procedimiento saldos_dia
     si es despues de las 6:00 am se corre el procedimiento para generar saldos a una fecha determinada  **/

PROCEDURE REPORTE_RSTIPE IS
   HORA_LIMITE VARCHAR2(8):= '06:00:00';   --HORA LIMITE PARA CORRER PROCEDIMIENTO DE SALDOS (dia de 24 horas)
   P_FECHA_HOY DATE;
   FECHA_A_PROCESAR DATE;

   CURSOR C_EXISTE (QFECHA DATE) IS
      SELECT 'S'
      FROM SALDOS_CLIENTES
      WHERE SCL_FECHA >= TRUNC(QFECHA)
        AND SCL_FECHA <  TRUNC(QFECHA+1);
   SINO VARCHAR2(1);

   YA_EXISTE  EXCEPTION;
BEGIN

   SELECT SYSDATE INTO P_FECHA_HOY FROM DUAL;
   FECHA_A_PROCESAR:= P_FECHA_HOY-1;
   OPEN C_EXISTE (FECHA_A_PROCESAR);
   FETCH C_EXISTE INTO SINO;
   IF C_EXISTE%FOUND THEN
      SINO := NVL(SINO,'N');
   ELSE
      SINO := 'N';
   END IF;
   CLOSE C_EXISTE;
   IF SINO = 'N' THEN
      IF TRUNC(FECHA_A_PROCESAR) = TRUNC(LAST_DAY(FECHA_A_PROCESAR)) THEN     --SOLO PARA FINES DE MES
         IF P_FECHA_HOY < TO_DATE(TO_CHAR(P_FECHA_HOY,'DD-MON-YYYY')||' '||HORA_LIMITE,'DD-MON-YYYY HH24:MI:SS') THEN
            P_REPORTES.SALDOS_HOY(FECHA_A_PROCESAR);
         ELSE
      	    P_REPORTES.SALDOS_FECHA(FECHA_A_PROCESAR);
         END IF;
      END IF;
   ELSE
      RAISE YA_EXISTE;
   END IF;
   -- PROCEDIMIENTO PARA VARIACION DE CARTERAS
   --P_COMERCIAL.GENERAR_SALDOS_CARTERAS(FECHA_A_PROCESAR);
EXCEPTION
	 WHEN YA_EXISTE THEN
	    P_MAIL.envio_mail_error('Proceso P_REPORTES.REPORTE_RSTIPE','Ya se gener¿ el saldo para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
	    RAISE_APPLICATION_ERROR(-20002,'Proceso P_REPORTES.REPORTE_RSTIPE: Ya se gener¿ el saldo para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso P_REPORTES.REPORTE_RSTIPE','Error en procedimiento REPORTE_RSTIPE: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento P_REPORTES.REPORTE_RSTIPE: '||substr(sqlerrm,1,80));

END REPORTE_RSTIPE;

/**  Procedimiento para generar los saldos de fondos, deceval y dcv a la fecha .
     Para saldo fondos, se toma el saldo inversion para los fondos abiertos por cliente
     Para saldo deceval se toma saldos disponible y en garantia de cuentas_fungible_clientes por la base monetaria de la fecha.
     Para saldo dcv se toman los titulos disponibles  en portafolio con localizacion dcv por la base monetaria del dia
     se guardan ¿nicamente los clientes que tuvieron algun tipo de saldo.  */

PROCEDURE SALDOS_HOY (P_FECHA IN DATE) IS

   CURSOR C_CONS IS
      SELECT NVL(MAX(SCL_CONSECUTIVO),0) CONS
      FROM SALDOS_CLIENTES;
   CONSECUTIVO NUMBER;
   CURSOR C_SALDO IS
      SELECT TRUNC(FECHA) FECHA ,
             CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             SUM(SALDO_FONDO_ABIERTOS) SALDO_FONDOS,
             SUM(SALDO_DECEVAL) SALDO_DECEVAL,
             SUM(SALDO_DCV) SALDO_DCV
      FROM  GL_SALDOS_CLIENTES
      GROUP BY TRUNC(FECHA),
               CLI_PER_NUM_IDEN,
               CLI_PER_TID_CODIGO
      HAVING SUM(SALDO_FONDO_ABIERTOS) != 0
          OR SUM(SALDO_DECEVAL) != 0
          OR SUM(SALDO_DCV)!= 0;
   R_SALDO C_SALDO%ROWTYPE;
BEGIN
	DELETE FROM GL_SALDOS_CLIENTES;
	 -- SALDO EN FONDOS
	 INSERT INTO GL_SALDOS_CLIENTES(
	    FECHA,
	    CLI_PER_NUM_IDEN,
      CLI_PER_TID_CODIGO,
      SALDO_FONDO_ABIERTOS,
      SALDO_DECEVAL,
      SALDO_DCV)
   SELECT P_FECHA,
          CFO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
          CFO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_cODIGO,
          DECODE(FON_BMO_MNEMONICO,'PESOS'
                                  ,NVL(CFO_SALDO_INVER,0)
                                  ,NVL(CFO_SALDO_INVER,0) * CBM1.CBM_VALOR) SALDO_FONDOS,
          0,0
   FROM CUENTAS_FONDOS,
        FONDOS,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE CFO_FON_CODIGO             = FON_CODIGO
     AND FON_BMO_MNEMONICO          = BMO_MNEMONICO
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_FECHA         < TRUNC(P_FECHA + 1)
                                         AND CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO)
     AND FON_TIPO                   = 'A';
   COMMIT;

   -- SALDO DECEVAL
	 INSERT INTO GL_SALDOS_CLIENTES (
	    FECHA,
	    CLI_PER_NUM_IDEN,
      CLI_PER_TID_CODIGO,
      SALDO_FONDO_ABIERTOS,
      SALDO_DECEVAL,
      SALDO_DCV)
   SELECT P_FECHA,
          CFC_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
          CFC_CCC_CLI_PER_TID_cODIGO CLI_PER_TID_CODIGO,
          0,
          (CFC_SALDO_CLIENTE * PEB_PRECIO_BOLSA) SALDO_DECEVAL,     --RENTA VARIABLE
          0
   FROM CUENTAS_FUNGIBLE_CLIENTE,
        CUENTAS_CLIENTE_CORREDORES,
        FUNGIBLES,
        ISINS,
        ISINS_ESPECIES,
        ESPECIES_NACIONALES,
        PRECIOS_ESPECIES_BOLSA PEB1
   WHERE CFC_CCC_CLI_PER_NUM_IDEN   = CCC_CLI_PER_NUM_IDEN
     AND CFC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
     AND CFC_CCC_NUMERO_CUENTA      = CCC_NUMERO_CUENTA
     AND CFC_FUG_ISI_MNEMONICO      = FUG_ISI_MNEMONICO
     AND CFC_FUG_MNEMONICO          = FUG_MNEMONICO
     AND FUG_ISI_MNEMONICO          = ISI_MNEMONICO
     AND ISE_ISI_MNEMONICO          = ISI_MNEMONICO
     AND ISE_ENA_MNEMONICO          = ENA_MNEMONICO
     AND PEB1.PEB_ENA_MNEMONICO     = ENA_MNEMONICO
     AND PEB1.PEB_FECHA             = (SELECT MAX(PEB2.PEB_FECHA)
                                       FROM PRECIOS_ESPECIES_BOLSA PEB2
                                       WHERE PEB2.PEB_ENA_MNEMONICO = ENA_MNEMONICO
                                         AND PEB2.PEB_FECHA         < TRUNC(P_FECHA) + 1)
     AND CFC_SALDO_CLIENTE          != 0
     AND CFC_ESTADO                 = 'A'
     AND FUG_TIPO                   = 'ACC'
     AND ISE_ENA_MNEMONICO          = (SELECT MAX(ISE_ENA_MNEMONICO)
                                       FROM ISINS_ESPECIES
                                       WHERE ISE_ISI_MNEMONICO = FUG_ISI_MNEMONICO)
   UNION ALL
   SELECT P_FECHA,
          CFC_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,                       -- RENTA FIJA
          CFC_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0,
          NVL(CFC_SALDO_CLIENTE,0) * CBM_VALOR SALDO_DECEVAL,
          0
   FROM CUENTAS_FUNGIBLE_CLIENTE,
        FUNGIBLES,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE CFC_FUG_ISI_MNEMONICO      = FUG_ISI_MNEMONICO
     AND CFC_FUG_MNEMONICO          = FUG_MNEMONICO
     AND FUG_TIPO                   = 'RF'
     AND FUG_BMO_MNEMONICO          = BMO_MNEMONICO
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO
                                         AND CBM2.CBM_FECHA < TRUNC(P_FECHA)+1);
   COMMIT;

   --SALDO DCV
	 INSERT INTO GL_SALDOS_CLIENTES (
	    FECHA,
	    CLI_PER_NUM_IDEN,
      CLI_PER_TID_CODIGO,
      SALDO_FONDO_ABIERTOS,
      SALDO_DECEVAL,
      SALDO_DCV)
   SELECT P_FECHA,
          TLO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,    -- RENTA VARIABLE
          TLO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0 SALDO_FONDOS,
          0 SALDO_DECEVAL,
          (NVL(TLO_CANTIDAD,0) * PEB1.PEB_PRECIO_BOLSA) VALOR_RENTA_VARIABLE
   FROM  TITULOS,
         ESPECIES_NACIONALES,
         PRECIOS_ESPECIES_BOLSA PEB1
   WHERE TLO_ENA_MNEMONICO          = ENA_MNEMONICO
     AND PEB1.PEB_ENA_MNEMONICO     = ENA_MNEMONICO
     AND PEB1.PEB_FECHA             = (SELECT MAX(PEB2.PEB_FECHA)
                                       FROM PRECIOS_ESPECIES_BOLSA PEB2
                                       WHERE PEB2.PEB_ENA_MNEMONICO = ENA_MNEMONICO
                                         AND PEB2.PEB_FECHA         < TRUNC(P_FECHA) + 1)
     AND TLO_ETC_MNEMONICO          IN ('DIS','GAR')
     AND TLO_LTI_MNEMONICO          = 'DV'
     AND TLO_PORTAFOLIO             = 'S'
   UNION ALL
   SELECT P_FECHA,
          TLO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,         --RENTA FIJA
          TLO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0 SALDO_FONDOS,
          0 SALDO_DECEVAL,
          (NVL(TLO_VALOR_NOMINAL,0) * CBM_VALOR) SALDO_DCV
   FROM TITULOS,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE TLO_BMO_MNEMONICO          = BMO_MNEMONICO
     AND TLO_TYPE                   = 'TFC'
     AND TLO_PORTAFOLIO             = 'S'
     AND TLO_ETC_MNEMONICO          IN ('DIS','GAR')
     AND TLO_LTI_MNEMONICO          =  'DV'
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO
                                         AND CBM2.CBM_FECHA < TRUNC(P_FECHA) + 1);
   COMMIT;


   OPEN C_CONS;
   FETCH C_CONS INTO CONSECUTIVO;
   CLOSE C_CONS;
   CONSECUTIVO := NVL(CONSECUTIVO,0);
   OPEN C_SALDO;
   FETCH C_SALDO INTO R_SALDO;
   WHILE C_SALDO%FOUND LOOP
      CONSECUTIVO := CONSECUTIVO + 1;
      INSERT INTO SALDOS_CLIENTES
         (SCL_CONSECUTIVO,
          SCL_FECHA,
          SCL_CLI_PER_NUM_IDEN,
          SCL_CLI_PER_TID_CODIGO,
          SCL_SALDO_FONDO_ABIERTOS,
          SCL_SALDO_DECEVAL,
          SCL_SALDO_DCV)
      VALUES
         (CONSECUTIVO,
          TRUNC(R_SALDO.FECHA),
          R_SALDO.CLI_PER_NUM_IDEN,
          R_SALDO.CLI_PER_TID_CODIGO,
          R_SALDO.SALDO_FONDOS,
          R_SALDO.SALDO_DECEVAL,
          R_SALDO.SALDO_DCV);
      FETCH C_SALDO INTO R_SALDO;
   END LOOP;
   CLOSE C_SALDO;
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso P_REPORTES.SALDOS_HOY:','Error en procedimiento SALDOS_HOY: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento P_REPORTES.SALDOS_HOY: '||substr(sqlerrm,1,80));
END SALDOS_HOY;

/**  Procedimiento para generar los saldos de fondos, deceval y dcv a una fecha dada.
     Para saldo fondos, se toma el saldo inversion para los fondos abiertos por cliente, se genera la informaci¿n desde movimientos_cuentas_fondos
         e historico_movimientos_fondos
     Para saldo deceval se toma saldos disponible y en garantia de cuentas_fungible_clientes por la base monetaria de la fecha.Tambien se verifica en titulos, historico_titulos
         con localizacion Deceval
     Para saldo dcv se toman los titulos disponibles  en portafolio con localizacion dcv por la base monetaria del dia. Se toma informacion de titulos e historico_titulos
     se guardan ¿nicamente los clientes que tuvieron algun tipo de saldo.  */

PROCEDURE SALDOS_FECHA (P_FECHA IN DATE) IS
   CURSOR C_FECHA_FDO IS
      SELECT CON_VALOR_DATE
      FROM CONSTANTES
      WHERE CON_MNEMONICO= 'FMF';
   FECHA_FONDO DATE := NULL;
   CURSOR C_CONS IS
      SELECT NVL(MAX(SCL_CONSECUTIVO),0) CONS
      FROM SALDOS_CLIENTES;
   CONSECUTIVO NUMBER;
   CURSOR C_SALDO IS
      SELECT TRUNC(FECHA) FECHA ,
             CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             SUM(SALDO_FONDO_ABIERTOS) SALDO_FONDOS,
             SUM(SALDO_DECEVAL) SALDO_DECEVAL,
             SUM(SALDO_DCV) SALDO_DCV
      FROM  GL_SALDOS_CLIENTES
      GROUP BY TRUNC(FECHA),
               CLI_PER_NUM_IDEN,
               CLI_PER_TID_CODIGO
      HAVING SUM(SALDO_FONDO_ABIERTOS) != 0
          OR SUM(SALDO_DECEVAL) != 0
          OR SUM(SALDO_DCV)!= 0;
   R_SALDO C_SALDO%ROWTYPE;


BEGIN
	 DELETE FROM GL_SALDOS_CLIENTES;
	 DELETE FROM GL_MAX_MCF;
	 -- SALDO EN FONDOS

	 OPEN C_FECHA_FDO;
	 FETCH C_FECHA_FDO INTO FECHA_FONDO;
	 CLOSE C_FECHA_FDO;
	 IF TRUNC(P_FECHA) >= TRUNC(FECHA_FONDO+1) THEN
	    INSERT INTO GL_MAX_MCF (
	       FECHA_DIA,
         MCF_CFO_CCC_CLI_PER_NUM_IDEN,
         MCF_CFO_CCC_CLI_PER_TID_CODIGO,
         MCF_CFO_CCC_NUMERO_CUENTA,
         MCF_CFO_FON_CODIGO,
         MCF_CFO_CODIGO,
         MCF_FECHA)
      SELECT TRUNC(MCF_FECHA) FECHA,
             MCF_CFO_CCC_CLI_PER_NUM_IDEN,
             MCF_CFO_CCC_CLI_PER_TID_CODIGO,
             MCF_CFO_CCC_NUMERO_CUENTA,
             MCF_CFO_FON_CODIGO,
             MCF_CFO_CODIGO,
             MAX(MCF_FECHA) MCF_FECHA
      FROM MOVIMIENTOS_CUENTAS_FONDOS
      WHERE MCF_FECHA >= TRUNC(P_FECHA)
        AND MCF_FECHA <  TRUNC(P_FECHA+1)
      GROUP BY TRUNC(MCF_FECHA),
               MCF_CFO_CCC_CLI_PER_NUM_IDEN,
               MCF_CFO_CCC_CLI_PER_TID_CODIGO,
               MCF_CFO_CCC_NUMERO_CUENTA,
               MCF_CFO_FON_CODIGO,
               MCF_CFO_CODIGO;
   /*ELSIF TRUNC(P_FECHA) <= TRUNC(FECHA_FONDO) THEN
	    INSERT INTO GL_MAX_MCF (
	       FECHA_DIA,
         MCF_CFO_CCC_CLI_PER_NUM_IDEN,
         MCF_CFO_CCC_CLI_PER_TID_CODIGO,
         MCF_CFO_CCC_NUMERO_CUENTA,
         MCF_CFO_FON_CODIGO,
         MCF_CFO_CODIGO,
         MCF_FECHA)
      SELECT TRUNC(HMF_FECHA) FECHA,
             HMF_CFO_CCC_CLI_PER_NUM_IDEN,
             HMF_CFO_CCC_CLI_PER_TID_CODIGO,
             HMF_CFO_CCC_NUMERO_CUENTA,
             HMF_CFO_FON_CODIGO,
             HMF_CFO_CODIGO,
             MAX(HMF_FECHA) HMF_FECHA
      FROM HISTORICOS_MOVIMIENTOS_FONDOS
      WHERE HMF_FECHA >= TRUNC(P_FECHA)
        AND HMF_FECHA <  TRUNC(P_FECHA+1)
      GROUP BY TRUNC(HMF_FECHA),
               HMF_CFO_CCC_CLI_PER_NUM_IDEN,
               HMF_CFO_CCC_CLI_PER_TID_CODIGO,
               HMF_CFO_CCC_NUMERO_CUENTA,
               HMF_CFO_FON_CODIGO,
               HMF_CFO_CODIGO;*/
   END IF;


	 /*INSERT INTO GL_SALDOS_CLIENTES(
	    FECHA,
	    CLI_PER_NUM_IDEN,
      CLI_PER_TID_CODIGO,
      SALDO_FONDO_ABIERTOS,
      SALDO_DECEVAL,
      SALDO_DCV)
   SELECT P_FECHA,
          CFO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
          CFO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_cODIGO,
          DECODE(FON_BMO_MNEMONICO,'PESOS'
                                  ,NVL(A.MCF_SALDO_INVER,0)
                                  ,NVL(A.MCF_SALDO_INVER,0) * CBM1.CBM_VALOR) SALDO_FONDOS,
          0,0
   FROM MOVIMIENTOS_CUENTAS_FONDOS A,
        CUENTAS_FONDOS B,
        GL_MAX_MCF C,
        FONDOS,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE A.MCF_CFO_CCC_CLI_PER_NUM_IDEN = B.CFO_CCC_CLI_PER_NUM_IDEN
     AND A.MCF_CFO_CCC_CLI_PER_TID_CODIGO = B.CFO_CCC_CLI_PER_TID_CODIGO
     AND A.MCF_CFO_CCC_NUMERO_CUENTA = B.CFO_CCC_NUMERO_CUENTA
     AND A.MCF_CFO_FON_CODIGO = B.CFO_FON_CODIGO
     AND A.MCF_CFO_CODIGO = B.CFO_CODIGO
     AND A.MCF_CFO_CCC_CLI_PER_NUM_IDEN = C.MCF_CFO_CCC_CLI_PER_NUM_IDEN
     AND A.MCF_CFO_CCC_CLI_PER_TID_CODIGO = C.MCF_CFO_CCC_CLI_PER_TID_CODIGO
     AND A.MCF_CFO_CCC_NUMERO_CUENTA = C.MCF_CFO_CCC_NUMERO_CUENTA
     AND A.MCF_CFO_FON_CODIGO = C.MCF_CFO_FON_CODIGO
     AND A.MCF_CFO_CODIGO = C.MCF_CFO_CODIGO
     AND A.MCF_FECHA = C.MCF_FECHA
     AND CFO_FON_CODIGO             = FON_CODIGO
     AND FON_BMO_MNEMONICO          = BMO_MNEMONICO
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_FECHA         < TRUNC(P_FECHA + 1)
                                         AND CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO)
     AND FON_TIPO                   = 'A'
     AND TRUNC(P_FECHA) >= TRUNC(FECHA_FONDO+1)
   UNION ALL                         ---DEL HISTORICO DE FONDOS
   SELECT P_FECHA,
          CFO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
          CFO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_cODIGO,
          DECODE(FON_BMO_MNEMONICO,'PESOS'
                                  ,NVL(HMF_SALDO_INVER,0)
                                  ,NVL(HMF_SALDO_INVER,0) * CBM1.CBM_VALOR) SALDO_FONDOS,
          0,0
   FROM HISTORICOS_MOVIMIENTOS_FONDOS HMF1,
        CUENTAS_FONDOS B,
        GL_MAX_MCF C,
        FONDOS,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE HMF1.HMF_CFO_CCC_CLI_PER_NUM_IDEN = CFO_CCC_CLI_PER_NUM_IDEN
     AND HMF1.HMF_CFO_CCC_CLI_PER_TID_CODIGO = CFO_CCC_CLI_PER_TID_CODIGO
     AND HMF1.HMF_CFO_CCC_NUMERO_CUENTA = CFO_CCC_NUMERO_CUENTA
     AND HMF1.HMF_CFO_FON_CODIGO = CFO_FON_CODIGO
     AND HMF1.HMF_CFO_CODIGO = CFO_CODIGO
     AND HMF1.HMF_CFO_CCC_CLI_PER_NUM_IDEN = C.MCF_CFO_CCC_CLI_PER_NUM_IDEN
     AND HMF1.HMF_CFO_CCC_CLI_PER_TID_CODIGO = C.MCF_CFO_CCC_CLI_PER_TID_CODIGO
     AND HMF1.HMF_CFO_CCC_NUMERO_CUENTA = C.MCF_CFO_CCC_NUMERO_CUENTA
     AND HMF1.HMF_CFO_FON_CODIGO = C.MCF_CFO_FON_CODIGO
     AND HMF1.HMF_CFO_CODIGO = C.MCF_CFO_CODIGO
     AND HMF1.HMF_FECHA = C.MCF_FECHA
     AND CFO_FON_CODIGO             = FON_CODIGO
     AND FON_BMO_MNEMONICO          = BMO_MNEMONICO
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_FECHA         < TRUNC(P_FECHA + 1)
                                         AND CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO)
     AND FON_TIPO                   = 'A'
     AND TRUNC(P_FECHA) <= TRUNC(FECHA_FONDO);*/


   COMMIT;

   -- SALDO DECEVAL
	 INSERT INTO GL_SALDOS_CLIENTES (
	    FECHA,
	    CLI_PER_NUM_IDEN,
      CLI_PER_TID_CODIGO,
      SALDO_FONDO_ABIERTOS,
      SALDO_DECEVAL,
      SALDO_DCV)
   SELECT P_FECHA,
          CFC_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
          CFC_CCC_CLI_PER_TID_cODIGO CLI_PER_TID_CODIGO,
          0,
          (MFU_SALDO_CLIENTE * PEB_PRECIO_BOLSA) SALDO_DECEVAL,     --RENTA VARIABLE
          0
   FROM MOVIMIENTOS_CUENTA_FUNGIBLE MFU,
        CUENTAS_FUNGIBLE_CLIENTE CFC,
        CUENTAS_CLIENTE_CORREDORES,
        FUNGIBLES,
        ISINS,
        ISINS_ESPECIES,
        ESPECIES_NACIONALES,
        PRECIOS_ESPECIES_BOLSA PEB1
   WHERE MFU.MFU_CFC_CUENTA_DECEVAL = CFC.CFC_CUENTA_DECEVAL
     AND MFU.MFU_CFC_FUG_ISI_MNEMONICO = CFC.CFC_FUG_ISI_MNEMONICO
     AND MFU.MFU_CFC_FUG_MNEMONICO  = CFC.CFC_FUG_MNEMONICO
     AND MFU.MFU_FECHA = (SELECT MAX(MFU1.MFU_FECHA)
                          FROM   MOVIMIENTOS_CUENTA_FUNGIBLE MFU1
                          WHERE  MFU1.MFU_CFC_FUG_ISI_MNEMONICO = CFC.CFC_FUG_ISI_MNEMONICO
                            AND  MFU1.MFU_CFC_FUG_MNEMONICO = CFC.CFC_FUG_MNEMONICO
                            AND  MFU1.MFU_CFC_CUENTA_DECEVAL = CFC.CFC_CUENTA_DECEVAL
                            AND  MFU1.MFU_FECHA < TRUNC(P_FECHA + 1))
     AND CFC_CCC_CLI_PER_NUM_IDEN   = CCC_CLI_PER_NUM_IDEN
     AND CFC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
     AND CFC_CCC_NUMERO_CUENTA      = CCC_NUMERO_CUENTA
     AND CFC_FUG_ISI_MNEMONICO      = FUG_ISI_MNEMONICO
     AND CFC_FUG_MNEMONICO          = FUG_MNEMONICO
     AND FUG_ISI_MNEMONICO          = ISI_MNEMONICO
     AND ISE_ISI_MNEMONICO          = ISI_MNEMONICO
     AND ISE_ENA_MNEMONICO          = ENA_MNEMONICO
     AND PEB1.PEB_ENA_MNEMONICO     = ENA_MNEMONICO
     AND PEB1.PEB_FECHA             = (SELECT MAX(PEB2.PEB_FECHA)
                                       FROM PRECIOS_ESPECIES_BOLSA PEB2
                                       WHERE PEB2.PEB_ENA_MNEMONICO = ENA_MNEMONICO
                                         AND PEB2.PEB_FECHA         < TRUNC(P_FECHA) + 1)
     AND MFU_SALDO_CLIENTE          != 0
     AND FUG_TIPO                   = 'ACC'
     AND ISE_ENA_MNEMONICO          = (SELECT MAX(ISE_ENA_MNEMONICO)
                                       FROM ISINS_ESPECIES
                                       WHERE ISE_ISI_MNEMONICO = FUG_ISI_MNEMONICO)
   UNION ALL
   SELECT P_FECHA,
          CFC_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,                       -- RENTA FIJA
          CFC_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0,
          NVL(MFU_SALDO_CLIENTE,0) * CBM_VALOR SALDO_DECEVAL,
          0
   FROM MOVIMIENTOS_CUENTA_FUNGIBLE MFU,
        CUENTAS_FUNGIBLE_CLIENTE CFC,
        FUNGIBLES,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE MFU.MFU_CFC_CUENTA_DECEVAL = CFC.CFC_CUENTA_DECEVAL
     AND MFU.MFU_CFC_FUG_ISI_MNEMONICO = CFC.CFC_FUG_ISI_MNEMONICO
     AND MFU.MFU_CFC_FUG_MNEMONICO  = CFC.CFC_FUG_MNEMONICO
     AND MFU.MFU_FECHA = (SELECT MAX(MFU1.MFU_FECHA)
                          FROM   MOVIMIENTOS_CUENTA_FUNGIBLE MFU1
                          WHERE  MFU1.MFU_CFC_FUG_ISI_MNEMONICO = CFC.CFC_FUG_ISI_MNEMONICO
                            AND  MFU1.MFU_CFC_FUG_MNEMONICO = CFC.CFC_FUG_MNEMONICO
                            AND  MFU1.MFU_CFC_CUENTA_DECEVAL = CFC.CFC_CUENTA_DECEVAL
                            AND  MFU1.MFU_FECHA < TRUNC(P_FECHA + 1))
     AND CFC_FUG_ISI_MNEMONICO      = FUG_ISI_MNEMONICO
     AND CFC_FUG_MNEMONICO          = FUG_MNEMONICO
     AND FUG_TIPO                   = 'RF'
     AND FUG_BMO_MNEMONICO          = BMO_MNEMONICO
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO
                                         AND CBM2.CBM_FECHA < TRUNC(P_FECHA)+1);
   COMMIT;

   --SALDO DCV
	 INSERT INTO GL_SALDOS_CLIENTES (
	    FECHA,
	    CLI_PER_NUM_IDEN,
      CLI_PER_TID_CODIGO,
      SALDO_FONDO_ABIERTOS,
      SALDO_DECEVAL,
      SALDO_DCV)
   SELECT P_FECHA,
          TLO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,    -- RENTA VARIABLE
          TLO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0 SALDO_FONDOS,
          0 SALDO_DECEVAL,
          (NVL(TLO_CANTIDAD,0) * PEB1.PEB_PRECIO_BOLSA) VALOR_RENTA_VARIABLE
   FROM  TITULOS,
         ESPECIES_NACIONALES,
         PRECIOS_ESPECIES_BOLSA PEB1
   WHERE TLO_ENA_MNEMONICO          = ENA_MNEMONICO
     AND PEB1.PEB_ENA_MNEMONICO     = ENA_MNEMONICO
     AND PEB1.PEB_FECHA             = (SELECT MAX(PEB2.PEB_FECHA)
                                       FROM PRECIOS_ESPECIES_BOLSA PEB2
                                       WHERE PEB2.PEB_ENA_MNEMONICO = ENA_MNEMONICO
                                         AND PEB2.PEB_FECHA         < TRUNC(P_FECHA) + 1)
     AND TLO_ETC_MNEMONICO          IN ('DIS','GAR')
     AND TLO_LTI_MNEMONICO          = 'DV'
     AND TLO_PORTAFOLIO             = 'S'
     AND TLO_TYPE                   = 'TVC'
     AND TLO_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1)
   UNION ALL
   SELECT P_FECHA,
          TLO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,    -- RENTA VARIABLE DEL HISTORICO
          TLO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0 SALDO_FONDOS,
          0 SALDO_DECEVAL,
          (NVL(HTC_CANTIDAD,0) * PEB1.PEB_PRECIO_BOLSA) VALOR_RENTA_VARIABLE
   FROM  TITULOS,
         HISTORICO_TITULOS_C HTC,
         ESPECIES_NACIONALES,
         PRECIOS_ESPECIES_BOLSA PEB1
   WHERE TLO_CODIGO = HTC.HTC_CODIGO
     AND TLO_ENA_MNEMONICO          = ENA_MNEMONICO
     AND PEB1.PEB_ENA_MNEMONICO     = ENA_MNEMONICO
     AND PEB1.PEB_FECHA             = (SELECT MAX(PEB2.PEB_FECHA)
                                       FROM PRECIOS_ESPECIES_BOLSA PEB2
                                       WHERE PEB2.PEB_ENA_MNEMONICO = ENA_MNEMONICO
                                         AND PEB2.PEB_FECHA         < TRUNC(P_FECHA) + 1)
     AND HTC_ETC_MNEMONICO          IN ('DIS','GAR')
     AND HTC_LTI_MNEMONICO              = 'DV'
     AND HTC_PORTAFOLIO             = 'S'
     AND HTC_TYPE                   = 'TVC'
     AND TLO_FECHA_ULTIMO_ESTADO >= TRUNC(P_FECHA + 1)
     AND HTC.HTC_FECHA_ULTIMO_ESTADO = (SELECT MAX(HTC1.HTC_FECHA_ULTIMO_ESTADO)
                                        FROM   HISTORICO_TITULOS_C   HTC1
                                        WHERE  HTC1.HTC_CODIGO = TLO_CODIGO
                                          AND  HTC1.HTC_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1))
   UNION ALL
   SELECT P_FECHA,
          TLO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,         --RENTA FIJA
          TLO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0 SALDO_FONDOS,
          0 SALDO_DECEVAL,
          (NVL(TLO_VALOR_NOMINAL,0) * CBM_VALOR) SALDO_DCV
   FROM TITULOS,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE TLO_BMO_MNEMONICO          = BMO_MNEMONICO
     AND TLO_TYPE                   = 'TFC'
     AND TLO_PORTAFOLIO             = 'S'
     AND TLO_ETC_MNEMONICO          IN ('DIS','GAR')
     AND TLO_LTI_MNEMONICO          =  'DV'
     AND TLO_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1)
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO
                                         AND CBM2.CBM_FECHA < TRUNC(P_FECHA) + 1)
   UNION ALL
   SELECT P_FECHA,
          TLO_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,         --RENTA FIJA
          TLO_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
          0 SALDO_FONDOS,
          0 SALDO_DECEVAL,
          (NVL(TLO_VALOR_NOMINAL,0) * CBM_VALOR) SALDO_DCV
   FROM TITULOS,
        HISTORICO_TITULOS_C HTC,
        BASES_MONETARIAS,
        COTIZACIONES_BASE_MONETARIAS CBM1
   WHERE TLO_CODIGO = HTC.HTC_CODIGO
     AND TLO_BMO_MNEMONICO          = BMO_MNEMONICO
     AND HTC_TYPE                   = 'TFC'
     AND HTC_PORTAFOLIO             = 'S'
     AND HTC_ETC_MNEMONICO          IN ('DIS','GAR')
     AND HTC_LTI_MNEMONICO          =  'DV'
     AND TLO_FECHA_ULTIMO_ESTADO >= TRUNC(P_FECHA + 1)
     AND HTC.HTC_FECHA_ULTIMO_ESTADO = (SELECT MAX(HTC1.HTC_FECHA_ULTIMO_ESTADO)
                                        FROM   HISTORICO_TITULOS_C   HTC1
                                        WHERE  HTC1.HTC_CODIGO = TLO_CODIGO
                                          AND  HTC1.HTC_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1))
     AND CBM1.CBM_BMO_MNEMONICO     = BMO_MNEMONICO
     AND CBM1.CBM_FECHA             = (SELECT MAX(CBM2.CBM_FECHA)
                                       FROM COTIZACIONES_BASE_MONETARIAS CBM2
                                       WHERE CBM2.CBM_BMO_MNEMONICO = BMO_MNEMONICO
                                         AND CBM2.CBM_FECHA < TRUNC(P_FECHA) + 1)
                                         ;
   COMMIT;


   OPEN C_CONS;
   FETCH C_CONS INTO CONSECUTIVO;
   CLOSE C_CONS;
   CONSECUTIVO := NVL(CONSECUTIVO,0);
   OPEN C_SALDO;
   FETCH C_SALDO INTO R_SALDO;
   WHILE C_SALDO%FOUND LOOP
      CONSECUTIVO := CONSECUTIVO + 1;
      INSERT INTO SALDOS_CLIENTES
         (SCL_CONSECUTIVO,
          SCL_FECHA,
          SCL_CLI_PER_NUM_IDEN,
          SCL_CLI_PER_TID_CODIGO,
          SCL_SALDO_FONDO_ABIERTOS,
          SCL_SALDO_DECEVAL,
          SCL_SALDO_DCV)
      VALUES
         (CONSECUTIVO,
          TRUNC(R_SALDO.FECHA),
          R_SALDO.CLI_PER_NUM_IDEN,
          R_SALDO.CLI_PER_TID_CODIGO,
          R_SALDO.SALDO_FONDOS,
          R_SALDO.SALDO_DECEVAL,
          R_SALDO.SALDO_DCV);
      FETCH C_SALDO INTO R_SALDO;
   END LOOP;
   CLOSE C_SALDO;
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso P_REPORTES.SALDOS_FECHA:','Error en procedimiento SALDOS_FECHA: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento P_REPORTES.SALDOS_HOY: '||substr(sqlerrm,1,80));
END SALDOS_FECHA;

/**  PROCEDIMIENTO PARA GUARDAR LA INFORMACION DE CRITERIOS POR COMERCIAL, QUE SE USARAN PARA CALUCLO DE COSTOS DE AREAS EN VDXC
**/

PROCEDURE GENERAR_CRITERIOS_COMERCIAL (FDESDE DATE, FHASTA DATE) IS

   FECHA_A_PROCESAR DATE;
   P_FECHA_DESDE DATE;
   CURSOR C_EXISTE (QFECHA DATE) IS
      SELECT 'S'
      FROM CRITERIOS_COMERCIAL
      WHERE CRC_FECHA >= TRUNC(QFECHA)
        AND CRC_FECHA <  TRUNC(QFECHA+1);
   SINO VARCHAR2(1);

   YA_EXISTE  EXCEPTION;
BEGIN

   P_FECHA_DESDE := FDESDE;
   WHILE TRUNC(P_FECHA_DESDE) <= TRUNC(FHASTA) LOOP
      FECHA_A_PROCESAR := P_FECHA_DESDE;

      OPEN C_EXISTE (FECHA_A_PROCESAR);
      FETCH C_EXISTE INTO SINO;
      IF C_EXISTE%FOUND THEN
         SINO := NVL(SINO,'N');
      ELSE
         SINO := 'N';
      END IF;
      CLOSE C_EXISTE;
      IF SINO = 'N' THEN
         P_REPORTES.CRITERIOS_COMERCIAL(FECHA_A_PROCESAR);
      ELSE
         RAISE YA_EXISTE;
      END IF;

      P_FECHA_DESDE := P_FECHA_DESDE + 1;
      COMMIT;
   END LOOP;
   P_REPORTES.REPORTE_RSTIPE;
   P_COMERCIAL.GENERAR_SALDOS_CARTERAS(FECHA_A_PROCESAR);
EXCEPTION
	 WHEN YA_EXISTE THEN
	   -- P_MAIL.envio_mail_error('Proceso P_REPORTES.GENERAR_CRITERIOS_COMERCIAL','Ya se gener¿ el procedimiento para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
	    RAISE_APPLICATION_ERROR(-20002,'Proceso P_REPORTES.GENERAR_CRITERIOS_COMERCIAL: Ya se gener¿ el procedimiento para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
   WHEN OTHERS THEN
     -- P_MAIL.envio_mail_error('Proceso P_REPORTES.GENERAR_CRITERIOS_COMERCIAL','Error en procedimiento GENERAR_CRITERIOS_COMERCIAL: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento P_REPORTES.GENERAR_CRITERIOS_COMERCIAL: '||substr(sqlerrm,1,180));

END GENERAR_CRITERIOS_COMERCIAL;



PROCEDURE CRITERIOS_COMERCIAL (P_FECHA DATE) IS

   CURSOR C_CRI IS
      SELECT CRI_MNEMONICO
      FROM CRITERIOS
      WHERE CRI_DESARROLLADO = 'S';

   R_CRI C_CRI%ROWTYPE;

BEGIN
      OPEN C_CRI;
      FETCH C_CRI INTO R_CRI;
      WHILE C_CRI%FOUND LOOP
         IF R_CRI.CRI_MNEMONICO = 'NLRF' THEN
            -- NLRF       No Liquidaciones RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NLRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                    AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                    AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'RF'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND  LIC_CLASE_TRANSACCION = 'RF'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NLRV' THEN
            --NLRV       No Liquidaciones RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NLRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                    AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                    AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND  LIC_CLASE_TRANSACCION = 'ACC'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND  LIC_CLASE_TRANSACCION = 'ACC'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NUMLIQREP' THEN
            -- NUMLIQREP      No Liquidaciones REPOS
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NUMLIQREP',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                    AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                    AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_TIPO_OFERTA IN ('R','A')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_TIPO_OFERTA IN ('R','A')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NORF' THEN
            -- NORF       No Ordenes RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NORF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OVE_EOC_MNEMONICO  IN ('APL','PAP')
                    AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OVE_COC_CTO_MNEMONICO = 'RF'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OCO_EOC_MNEMONICO  IN ('APL','PAP')
                    AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OCO_COC_CTO_MNEMONICO = 'RF'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NORV' THEN
            -- NORV       No Ordenes RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NORV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OVE_EOC_MNEMONICO IN ('APL','PAP')
                    AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OVE_COC_CTO_MNEMONICO = 'ACC'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OCO_EOC_MNEMONICO IN  ('APL','PAP')
                    AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OCO_COC_CTO_MNEMONICO = 'ACC'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOOPCF' THEN
            -- NOOPCF       No Ordenes OPCF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM OPCF_CONTRATOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE PCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND PCC_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND PCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND PCC_EOC_MNEMONICO IN ('APL')
                    AND PCC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND PCC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NLIOPCF' THEN
            -- NLIOPCF	No. Liquidaciones OPCF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NLIOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM OPCF_LIQUIDACIONES,
                       OPCF_CONTRATOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE LOP_PCC_CONSECUTIVO = PCC_CONSECUTIVO
                    AND PCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND PCC_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND PCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LOP_ELI_MNEMONICO IN ('APL')
                    AND LOP_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LOP_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NLIRFYK' THEN
            -- NLIRFYK	No. Liquidaciones RF Yankees
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NLIRFYK',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                    AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                    AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'RF'
                    AND EXISTS (SELECT 'X'
                                FROM ESPECIES_NACIONALES
                                WHERE ENA_MNEMONICO = LIC_MNEMOTECNICO_TITULO
                                  AND ENA_YANKEE = 'S')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND  LIC_CLASE_TRANSACCION = 'RF'
                    AND EXISTS (SELECT 'X'
                                FROM ESPECIES_NACIONALES
                                WHERE ENA_MNEMONICO = LIC_MNEMOTECNICO_TITULO
                                  AND ENA_YANKEE = 'S')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NODIV' THEN
            -- NODIV	NO ORDENES CLIENTES DIV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NODIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                    AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                    AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                        OR
                        (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                         AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                         AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOINTDIV' THEN
            -- NOINTDIV	        NO ORDENES INTERBANCARIAS DIVISAS
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOINTDIV',
                   SUM(TOTAL)
            FROM (SELECT ORD_PER_NUM_IDEN NID_COM,
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DIVISAS
                  WHERE ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                    AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                    AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                        OR
                        (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                         AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                         AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')
                  GROUP BY ORD_PER_NUM_IDEN,
                           ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NICC' THEN
            -- NICC	No Ingresos CC
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NICC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRCC' THEN
            -- NRCC	No Retiros CC
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NIAPT' THEN
            -- NIAPT	No Ingresos APT
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NIAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRAPT' THEN
            -- NRAPT	No Retiros APT
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHRF' THEN
            -- NOPACHRF	No Ordenes de Pago ACH RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'RF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHERF' THEN
            -- NOPCHERF	No Ordenes de Pago CHE RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHERF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'RF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGRF' THEN
            -- NOPCHGRF	No Ordenes de Pago CHG RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'RF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSERF' THEN
            -- NOPPSERF	No Ordenes de Pago PSE RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSERF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'RF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCRF' THEN
            -- NOPTCCRF	No Ordenes de Pago TCC RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'RF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBRF' THEN
            -- NOPTRBRF	No Ordenes de Pago TRB RF
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'RF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NRECHERF' THEN
            -- NRECHERF	No Ordenes de  Recaudo CHE RF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECHERF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'RF'
                    AND OCO_COBRAR_CHEQUE = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NREPSERF' THEN
            -- NREPSERF	No Ordenes de  Recaudo PSE RF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NREPSERF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'RF'
                    AND OCO_COBRAR_SEBRA = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRETRBRF' THEN
            -- NRETRBRF	No Ordenes de  Recaudo TRB RF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRETRBRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'RF'
                    AND OCO_COBRAR_TRANSFERENCIA_BANCA = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRECEFRF' THEN
            -- NRECEFRF	No Ordenes de  Recaudo CEF RF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECEFRF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'RF'
                    AND OCO_COBRAR_CONSIGNA = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHRV' THEN
            -- NOPACHRV	No Ordenes de Pago ACH RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHERV' THEN
            -- NOPCHERV	No Ordenes de Pago CHE RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHERV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGRV' THEN
            -- NOPCHGRV	No Ordenes de Pago CHG RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSERV' THEN
            -- NOPPSERV	No Ordenes de Pago PSE RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSERV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCRV' THEN
            -- NOPTCCRV	No Ordenes de Pago TCC RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBRV' THEN
            -- NOPTRBRV	No Ordenes de Pago TRB RV
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NRECHERV' THEN
            -- NRECHERV	No Ordenes de  Recaudo CHE RV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECHERV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'ACC'
                    AND OCO_COBRAR_CHEQUE = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NREPSERV' THEN
            -- NREPSERV	No Ordenes de  Recaudo PSE RV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NREPSERV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'ACC'
                    AND OCO_COBRAR_SEBRA = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRETRBRV' THEN
            -- NRETRBRV	No Ordenes de  Recaudo TRB RV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRETRBRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'ACC'
                    AND OCO_COBRAR_TRANSFERENCIA_BANCA = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRECEFRV' THEN
            -- NRECEFRV	No Ordenes de  Recaudo CEF RV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECEFRV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_CLASE_TRANSACCION = 'ACC'
                    AND OCO_COBRAR_CONSIGNA = 'S'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO )
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHCC' THEN
            -- NOPACHCC	No Ordenes de Pago ACH CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHECC' THEN
            -- NOPCHECC	No Ordenes de Pago CHE CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHECC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGCC' THEN
            -- NOPCHGCC	No Ordenes de Pago CHG CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSECC' THEN
            -- NOPPSECC	No Ordenes de Pago PSE CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSECC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCCC' THEN
            -- NOPTCCCC	No Ordenes de Pago TCC CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBCC' THEN
            -- NOPTRBCC	No Ordenes de Pago TRB CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NRECHECC' THEN
            -- NRECHECC	No Ordenes de  Recaudo CHE CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECHECC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NREPSECC' THEN
            -- NREPSECC	No Ordenes de  Recaudo PSE CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NREPSECC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRETRBCC' THEN
            -- NRETRBCC	No Ordenes de  Recaudo TRB CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRETRBCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NRECEFCC' THEN
            -- NRECEFCC	No Ordenes de  Recaudo CEF CC

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECEFCC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'CEF'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHAPT' THEN
            -- NOPACHAPT	No Ordenes de Pago ACH APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHEAPT' THEN
            -- NOPCHEAPT	No Ordenes de Pago CHE APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHEAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGAPT' THEN
            -- NOPCHGAPT	No Ordenes de Pago CHG APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSEAPT' THEN
            -- NOPPSEAPT	No Ordenes de Pago PSE APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSEAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCAPT' THEN
            -- NOPTCCAPT	No Ordenes de Pago TCC APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBAPT' THEN
            -- NOPTRBAPT	No Ordenes de Pago TRB APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;




         ELSIF R_CRI.CRI_MNEMONICO = 'NRECHEAPT' THEN
            -- NRECHEAPT	No Ordenes de  Recaudo CHE APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECHEAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NREPSEAPT' THEN
            -- NREPSEAPT	No Ordenes de  Recaudo PSE APT


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NREPSEAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRETRBAPT' THEN
            -- NRETRBAPT	No Ordenes de  Recaudo TRB APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRETRBAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NRECEFAPT' THEN
            -- NRECEFAPT	No Ordenes de  Recaudo CEF APT

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECEFAPT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES,
                       ORDENES_RECAUDO
                  WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                    AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                    AND OFO_EOF_CODIGO = 'APR'
                    AND EXISTS (SELECT 'X'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ORR_TPA_MNEMONICO = 'CEF'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHDIV' THEN
            -- NOPACHDIV	No Ordenes de Pago ACH DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ODP_TPA_MNEMONICO = 'ACH'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

          ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHEDIV' THEN
            -- NOPCHEDIV	No Ordenes de Pago CHE DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHEDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ODP_TPA_MNEMONICO = 'CHE'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGDIV' THEN
            -- NOPCHGDIV	No Ordenes de Pago CHG DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ODP_TPA_MNEMONICO = 'CHG'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSEDIV' THEN
            -- NOPPSEDIV	No Ordenes de Pago PSE DIV


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSEDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ODP_TPA_MNEMONICO = 'PSE'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCDIV' THEN
            -- NOPTCCDIV	No Ordenes de Pago TCC DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ODP_TPA_MNEMONICO = 'TCC'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBDIV' THEN
            -- NOPTRBDIV	No Ordenes de Pago TRB DIV

           INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ODP_TPA_MNEMONICO = 'TRB'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRECHEDIV' THEN
            -- NRECHEDIV	No Ordenes de  Recaudo CHE DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECHEDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ORR_TPA_MNEMONICO = 'CHE'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ORR_TPA_MNEMONICO = 'CHE'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NREPSEDIV' THEN
            -- NREPSEDIV	No Ordenes de  Recaudo PSE DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NREPSEDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ORR_TPA_MNEMONICO = 'PSE'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ORR_TPA_MNEMONICO = 'PSE'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NRETRBDIV' THEN
            -- NRETRBDIV	No Ordenes de  Recaudo TRB DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRETRBDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ORR_TPA_MNEMONICO = 'TRB'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ORR_TPA_MNEMONICO = 'TRB'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRECEFDIV' THEN
            -- NRECEFDIV	No Ordenes de  Recaudo CEF DIV

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECEFDIV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ORR_TPA_MNEMONICO = 'CEF'
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ORR_TPA_MNEMONICO = 'CEF'
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHOPCF' THEN
            -- NOPACHOPCF	No Ordenes de Pago ACH OPCF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHEOPCF' THEN
            -- NOPCHEOPCF	No Ordenes de Pago CHE OPCF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHEOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGOPCF' THEN
            -- NOPCHGOPCF	No Ordenes de Pago CHG OPCF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSEOPCF' THEN
            -- NOPPSEOPCF	No Ordenes de Pago PSE OPCF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSEOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCOPCF' THEN
            -- NOPTCCOPCF	No Ordenes de Pago TCC OPCF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBOPCF' THEN
            -- NOPTRBOPCF	No Ordenes de Pago TRB OPCF

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBOPCF',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPACHAV' THEN
            -- NOPACHAV	No Ordenes de Pago ACH Admon Val

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPACHAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHEAV' THEN
            -- NOPCHEAV	No Ordenes de Pago CHE Admon Val


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHEAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOPCHGAV' THEN
            -- NOPCHGAV	No Ordenes de Pago CHG Admon Val

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPCHGAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'CHG'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPPSEAV' THEN
            -- NOPPSEAV	No Ordenes de Pago PSE Admon Val

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPPSEAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'PSE'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTCCAV' THEN
            -- NOPTCCAV	No Ordenes de Pago TCC Admon Val

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTCCAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TCC'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOPTRBAV' THEN
            -- NOPTRBAV	No Ordenes de Pago TRB Admon Val

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOPTRBAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'TRB'
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NCLIACT' THEN
            -- NCLIACT	No Clientes Activos y Activos Incompletos

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NCLIACT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(DISTINCT CLI_PER_NUM_IDEN||CLI_PER_TID_CODIGO) TOTAL
                  FROM CLIENTES A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
                    AND CCC_CLI_PER_TID_cODIGO = CLI_PER_TID_CODIGO
                    AND CLI_ECL_MNEMONICO IN ('ACC','ACI')
                    AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                             FROM CUENTAS_CLIENTE_CORREDORES C
                                             WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                               AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO)
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NCLIBLO' THEN
            -- NCLIBLO	No Clientes Bloqueados

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NCLIBLO',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(DISTINCT CLI_PER_NUM_IDEN||CLI_PER_TID_CODIGO) TOTAL
                  FROM CLIENTES A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
                    AND CCC_CLI_PER_TID_cODIGO = CLI_PER_TID_CODIGO
                    AND CLI_ECL_MNEMONICO IN ('BDJ','BAA')
                    AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                             FROM CUENTAS_CLIENTE_CORREDORES C
                                             WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                               AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO)
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NCLIINA' THEN
            -- NCLIINA	No Clientes Inactivos

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NCLIINA',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(DISTINCT CLI_PER_NUM_IDEN||CLI_PER_TID_CODIGO) TOTAL
                  FROM CLIENTES A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
                    AND CCC_CLI_PER_TID_cODIGO = CLI_PER_TID_CODIGO
                    AND CLI_ECL_MNEMONICO IN ('INA')
                    AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                             FROM CUENTAS_CLIENTE_CORREDORES C
                                             WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                               AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO)
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'CLINUE' THEN
            -- CLINUE	CLIENTES NUEVOS

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'CLINUE',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(DISTINCT CLI_PER_NUM_IDEN||CLI_PER_TID_CODIGO) TOTAL
                  FROM CLIENTES A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
                    AND CCC_CLI_PER_TID_cODIGO = CLI_PER_TID_CODIGO
                    AND CLI_ECL_MNEMONICO IN ('ACC','ACI')
                    AND CLI_FECHA_APERTURA >= TRUNC(P_FECHA)
                    AND CLI_FECHA_APERTURA <  TRUNC(P_FECHA) + 1
                    AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                             FROM CUENTAS_CLIENTE_CORREDORES C
                                             WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                               AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO)
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'CLIACT' THEN
            -- CLIACT	No Clientes Actualizados  : CLIENTES QUE PASARON DE INACTIVO A ACTIVO

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'CLIACT',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(DISTINCT CLI_PER_NUM_IDEN||CLI_PER_TID_CODIGO) TOTAL
                  FROM CLIENTES A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
                    AND CCC_CLI_PER_TID_cODIGO = CLI_PER_TID_CODIGO
                    AND CLI_ECL_MNEMONICO IN ('ACC','ACI')
                    AND CLI_FECHA_APERTURA >= TRUNC(P_FECHA)
                    AND CLI_FECHA_APERTURA <  TRUNC(P_FECHA) + 1
                    AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                             FROM CUENTAS_CLIENTE_CORREDORES C
                                             WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                               AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO)
                    AND EXISTS (SELECT 'X'
                                FROM CONTROL_ACTUALIZACIONES
                                WHERE CAC_FECHA_ACTUALIZACION >= TRUNC(P_FECHA)
                                  AND CAC_FECHA_ACTUALIZACION  < TRUNC(P_FECHA) + 1
                                  AND CAC_TABLA = 'CLIENTES'
                                  AND CAC_COLUMNA = 'CLI_ECL_MNEMONICO'
                                  AND CAC_VALOR_ANTERIOR = 'INA'
                                  AND CAC_VALOR_ACTUAL IN ('ACC','ACI'))
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NEXTGEN' THEN
            -- NEXTGEN	No Extractos Generados (Fdos, MCC)


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NEXTGEN',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(CEF_CONSECUTIVO) TOTAL
                  FROM CONTROL_EXTRACTOS_FONDOS A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CEF_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND CEF_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_cODIGO
                    AND CEF_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND CEF_FECHA >= TRUNC(P_FECHA)
                    AND CEF_FECHA <  TRUNC(P_FECHA) + 1
                  GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(CGX_CONSECUTIVO) TOTAL
                  FROM CONTROL_GENERACION_EXTRACTOS A,
                       CUENTAS_CLIENTE_CORREDORES B
                  WHERE CGX_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND CGX_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_cODIGO
                    AND CGX_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND CGX_FECHA >= TRUNC(P_FECHA)
                    AND CGX_FECHA <  TRUNC(P_FECHA) + 1
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERRFC' THEN
            -- NOIERRFC	No Ordenes Instrucci¿n Enviar/Recoger RF Compra

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERRFC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OCO_EOC_MNEMONICO  IN ('APL','PAP')
                    AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OCO_COC_CTO_MNEMONICO = 'RF'
                    AND (OCO_ENVIAR_FACTURA = 'S'
                         OR OCO_ENVIAR_CARTA_COMPROMISO = 'S'
                         OR OCO_ENVIAR_RECIBO_CUSTODIA = 'S'
                         OR OCO_ENVIAR_CARTA_CARRU_PLAZO = 'S'
                         OR OCO_RECOGER_CHEQUE = 'S')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERRFV' THEN
            -- NOIERRFV	No Ordenes Instrucci¿n Enviar/Recoger RF Venta

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERRFV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OVE_EOC_MNEMONICO  IN ('APL','PAP')
                    AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OVE_COC_CTO_MNEMONICO = 'RF'
                    AND (OVE_ENVIAR_FACTURA= 'S'
                         OR OVE_DINERO_CONTRA_TITULOS = 'S'
                         OR OVE_RECOGER_CARTA = 'S'
                         OR OVE_RECOGER_CERT_CAMARA = 'S')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERRVC' THEN
            -- NOIERRVC	No Ordenes Instrucci¿n Enviar/Recoger RV Compra

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERRVC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OCO_EOC_MNEMONICO  IN ('APL','PAP')
                    AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OCO_COC_CTO_MNEMONICO = 'ACC'
                    AND (OCO_ENVIAR_FACTURA = 'S'
                         OR OCO_ENVIAR_CARTA_COMPROMISO = 'S'
                         OR OCO_ENVIAR_RECIBO_CUSTODIA = 'S'
                         OR OCO_ENVIAR_CARTA_CARRU_PLAZO = 'S'
                         OR OCO_RECOGER_CHEQUE = 'S')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERRVV' THEN
            -- NOIERRVV	No Ordenes Instrucci¿n Enviar/Recoger RV Venta

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERRVV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OVE_EOC_MNEMONICO  IN ('APL','PAP')
                    AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                    AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                    AND OVE_COC_CTO_MNEMONICO = 'ACC'
                    AND (OVE_ENVIAR_FACTURA= 'S'
                         OR OVE_DINERO_CONTRA_TITULOS = 'S'
                         OR OVE_RECOGER_CARTA = 'S'
                         OR OVE_RECOGER_CERT_CAMARA = 'S')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERDIVC' THEN
            -- NOIERDIVC	No Ordenes Instruccion Enviar/Recoger Divisas Compra
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERDIVC',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ORD_TIPO_ORDEN = 'C'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ORD_TIPO_ORDEN = 'C'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')      --DILIGENCIA
                  GROUP BY ORD_PER_NUM_IDEN,
                           ORD_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ORD_TIPO_ORDEN = 'C'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ORD_TIPO_ORDEN = 'C'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERDIVV' THEN
            -- NOIERDIVV	No Ordenes Instrucci¿n Enviar/Recoger Divisas Venta
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERDIVV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ORD_TIPO_ORDEN = 'V'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                    AND ORD_EOF_CODIGO = 'APR'
                    AND ORD_TIPO_ORDEN = 'V'
                    AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                          AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                         OR
                         (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                          AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                          AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')      --DILIGENCIA
                  GROUP BY ORD_PER_NUM_IDEN,
                           ORD_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ORD_TIPO_ORDEN = 'V'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT ORD_PER_NUM_IDEN NID_COM,                  --INTERBANCARIAS
                         ORD_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_DIVISAS
                  WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                    AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND ORD_TIPO_ORDEN = 'V'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'X'
                                FROM TIPOS_MVTOS_DIVISAS
                                WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                  AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                 GROUP BY ORD_PER_NUM_IDEN,
                          ORD_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;



         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERCCI' THEN
            -- NOIERCCI	No Ordenes Instrucci¿n Enviar/Recoger CC Ingresos
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERCCI',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERCCV' THEN
            -- NOIERCCV	No Ordenes Instrucci¿n Enviar/Recoger CC Retiros

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERCCV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'F'
                                  AND FON_CODIGO NOT IN ('111111'))
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERAPTI' THEN
            -- NOIERAPTI	No Ordenes Instrucci¿n Enviar/Recoger APT Ingresos

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERAPTI',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERAPTV' THEN
            -- NOIERAPTV	No Ordenes Instrucci¿n Enviar/Recoger APT Retiros

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERAPTV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_RECAUDO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                    AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                         AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       ORDENES_FONDOS,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                    AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                    AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND OFO_EOF_CODIGO = 'APR'
                    AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND EXISTS (SELECT 'S'
                                FROM FONDOS
                                WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                  AND FON_TIPO = 'A'
                                  AND FON_TIPO_ADMINISTRACION = 'A')
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


         ELSIF R_CRI.CRI_MNEMONICO = 'NOIERAV' THEN
            -- NOIERAV	No Ordenes Instrucci¿n Enviar/Recoger Admon Valores RV


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOIERAV',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND (ODP_ENTREGAR_RECOGE = 'E'
                         OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NMOVDRA' THEN
            -- NMOVDRA	NO MOV ADMON VALORES RENDIM AMORT DIVIDENDOS


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NMOVDRA',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM MOVIMIENTOS_CUENTA_CORREDORES,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE MCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND MCC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND MCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND MCC_TMC_MNEMONICO in ('ABA','ABI','ABD','ABR','APFF')
                    AND MCC_FECHA >= TRUNC(P_FECHA)
                    AND MCC_FECHA < TRUNC(P_FECHA) + 1
                 GROUP BY CCC_PER_NUM_IDEN,
                          CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOMOVGART' THEN
            -- NOMOVGART	NO MOV GARANTIA DE TESORERIA

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOMOVGART',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM RECIBOS_DE_CAJA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND RCA_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND RCA_REVERSADO = 'N'
                    AND RCA_ES_CLIENTE = 'S'
                    AND RCA_COT_MNEMONICO IN ('GOPCF','RGCF','GOPCE','PGPCF','RGPCF','RGCE')
                    AND RCA_FECHA >= TRUNC(P_FECHA)
                    AND RCA_FECHA < TRUNC(P_FECHA) + 1
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_COT_MNEMONICO IN ('GOPCF','RGCF','GOPCE','PGPCF','RGPCF','RGCE')
                    AND ODP_ESTADO = 'APR'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NOMOVDCVG' THEN
            -- NOMOVDCVG	NO MOV DECEVAL GARANTIA


            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOMOVDCVG',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM MOVIMIENTOS_CUENTA_FUNGIBLE,
                       CUENTAS_FUNGIBLE_CLIENTE,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE MFU_CFC_CUENTA_DECEVAL = CFC_CUENTA_DECEVAL
                    AND MFU_CFC_FUG_ISI_MNEMONICO = CFC_FUG_ISI_MNEMONICO
                    AND MFU_CFC_FUG_MNEMONICO = CFC_FUG_MNEMONICO
                    AND CFC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND CFC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND CFC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND MFU_FECHA >= TRUNC(P_FECHA)
                    AND MFU_FECHA <  TRUNC(P_FECHA)+1
                    AND MFU_TFU_MNEMONICO IN ('DIGA','GADI','DIGAD','GADID','RDIG','RGDI','RDGE','RGED','DGES','GESD')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;

         ELSIF R_CRI.CRI_MNEMONICO = 'NRECAJ' THEN
            -- NRECAJ	No de Recibos de Caja

            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NRECAJ',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM RECIBOS_DE_CAJA,
                       CUENTAS_CLIENTE_CORREDORES
                  WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND RCA_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND RCA_REVERSADO = 'N'
                    AND RCA_ES_CLIENTE = 'S'
                    AND RCA_FECHA >= TRUNC(P_FECHA)
                    AND RCA_FECHA < TRUNC(P_FECHA) + 1
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;


      ELSIF R_CRI.CRI_MNEMONICO = 'NOOPPP' THEN
            -- NOOPPP No Operaciones de Posicion Propia
            INSERT INTO CRITERIOS_COMERCIAL(
                    CRC_FECHA,
                    CRC_PER_NUM_IDEN,
                    CRC_PER_TID_CODIGO,
                    CRC_CRI_MNEMONICO,
                    CRC_CANTIDAD)
            SELECT TRUNC(P_FECHA),
                   NID_COM,
                   TID_COM,
                   'NOOPPP',
                   SUM(TOTAL)
            FROM (SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA A,
                       LIQUIDACIONES_COMERCIAL B,
                       CUENTAS_CLIENTE_CORREDORES C
                  WHERE A.OVE_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                    AND A.OVE_COC_CTO_MNEMONICO = B.LIC_OVE_COC_CTO_MNEMONICO
                    AND A.OVE_CONSECUTIVO = B.LIC_OVE_CONSECUTIVO
                    AND A.OVE_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                    AND A.OVE_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                    AND A.OVE_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                    AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND B.LIC_CLASE_TRANSACCION = 'RF'
                    AND B.LIC_NIT_1 = '860079174'
                    AND C.CCC_NUMERO_CUENTA = 6    -- CUENTA DE RECURSOS PROPIOS DE CORREDORES
                  GROUP BY C.CCC_PER_NUM_IDEN,
                           C.CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA A,
                       LIQUIDACIONES_COMERCIAL B,
                       CUENTAS_CLIENTE_CORREDORES C
                  WHERE A.OCO_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                    AND A.OCO_COC_CTO_MNEMONICO = B.LIC_OCO_COC_CTO_MNEMONICO
                    AND A.OCO_CONSECUTIVO = B.LIC_OCO_CONSECUTIVO
                    AND A.OCO_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                    AND A.OCO_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                    AND A.OCO_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                    AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND B.LIC_CLASE_TRANSACCION = 'RF'
                    AND B.LIC_NIT_1 != '860079174'
                    AND EXISTS (SELECT 'X'
                                FROM ORDENES_VENTA D,
                                     LIQUIDACIONES_COMERCIAL E
                                WHERE D.OVE_BOL_MNEMONICO = E.LIC_BOL_MNEMONICO
                                  AND D.OVE_COC_CTO_MNEMONICO = E.LIC_OVE_COC_CTO_MNEMONICO
                                  AND D.OVE_CONSECUTIVO = E.LIC_OVE_CONSECUTIVO
                                  AND E.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                                  AND E.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                                  AND E.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                                  AND E.LIC_CLASE_TRANSACCION = 'RF'
                                  AND E.LIC_NIT_1 = '860079174'
                                  AND E.LIC_NUMERO_OPERACION = B.LIC_NUMERO_OPERACION
                                  AND E.LIC_TIPO_OPERACION = 'V')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA A,
                       LIQUIDACIONES_COMERCIAL B,
                       CUENTAS_CLIENTE_CORREDORES C
                  WHERE A.OCO_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                    AND A.OCO_COC_CTO_MNEMONICO = B.LIC_OCO_COC_CTO_MNEMONICO
                    AND A.OCO_CONSECUTIVO = B.LIC_OCO_CONSECUTIVO
                    AND A.OCO_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                    AND A.OCO_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                    AND A.OCO_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                    AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND B.LIC_CLASE_TRANSACCION = 'RF'
                    AND B.LIC_NIT_1 = '860079174'
                    AND C.CCC_NUMERO_CUENTA = 6    -- CUENTA DE RECURSOS PROPIOS DE CORREDORES
                  GROUP BY C.CCC_PER_NUM_IDEN,
                           C.CCC_PER_TID_CODIGO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN NID_COM,
                         CCC_PER_TID_CODIGO TID_COM,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA A,
                       LIQUIDACIONES_COMERCIAL B,
                       CUENTAS_CLIENTE_CORREDORES C
                  WHERE A.OVE_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                    AND A.OVE_COC_CTO_MNEMONICO = B.LIC_OVE_COC_CTO_MNEMONICO
                    AND A.OVE_CONSECUTIVO = B.LIC_OVE_CONSECUTIVO
                    AND A.OVE_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                    AND A.OVE_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                    AND A.OVE_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                    AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND B.LIC_CLASE_TRANSACCION = 'RF'
                    AND B.LIC_NIT_1 != '860079174'
                    AND EXISTS (SELECT 'X'
                                FROM ORDENES_COMPRA D,
                                     LIQUIDACIONES_COMERCIAL E
                                WHERE D.OCO_BOL_MNEMONICO = E.LIC_BOL_MNEMONICO
                                  AND D.OCO_COC_CTO_MNEMONICO = E.LIC_OCO_COC_CTO_MNEMONICO
                                  AND D.OCO_CONSECUTIVO = E.LIC_OCO_CONSECUTIVO
                                  AND E.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                                  AND E.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                                  AND E.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                                  AND E.LIC_CLASE_TRANSACCION = 'RF'
                                  AND E.LIC_NIT_1 = '860079174'
                                  AND E.LIC_NUMERO_OPERACION = B.LIC_NUMERO_OPERACION
                                  AND E.LIC_TIPO_OPERACION = 'C')
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO)
             GROUP BY NID_COM,
                      TID_COM;
      END IF;
      FETCH C_CRI INTO R_CRI;
   END LOOP;
   CLOSE C_CRI;
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
     -- P_MAIL.envio_mail_error('Proceso P_REPORTES.CRITERIOS_COMERCIAL','Error en procedimiento GENERAR_CRITERIOS_COMERCIAL: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento P_REPORTES.CRITERIOS_COMERCIAL: '||substr(sqlerrm,1,80));

END CRITERIOS_COMERCIAL;

/***********************Procedimientos Criterios**************************/

/**  Procedimiento para traer el numero de clientes activos y activos incompletos
**/
PROCEDURE CLIENTES_ACTIVOS_E_INCOMPLETOS (P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- NCLIACT	No Clientes Activos y Activos Incompletos

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta
              FROM CLIENTES A, CUENTAS_CLIENTE_CORREDORES B
              WHERE B.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
              AND B.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO
              AND A.CLI_ECL_MNEMONICO IN ('ACC','ACI')
              AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                       FROM CUENTAS_CLIENTE_CORREDORES C
                                       WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                       AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO));

END CLIENTES_ACTIVOS_E_INCOMPLETOS;

/**  Procedimiento para traer el numero de clientes bloqueados
**/
PROCEDURE CLIENTES_BLOQUEADOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- NCLIBLO	No Clientes Bloqueados

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta
              FROM CLIENTES A, CUENTAS_CLIENTE_CORREDORES B
              WHERE B.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
              AND B.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO
              AND A.CLI_ECL_MNEMONICO IN ('BDJ','BAA')
              AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                       FROM CUENTAS_CLIENTE_CORREDORES C
                                       WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                       AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO));

END CLIENTES_BLOQUEADOS;

/**  Procedimiento para traer el numero de clientes bloqueados
**/
PROCEDURE CLIENTES_INACTIVOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- NCLIINA	No Clientes Inactivos

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta
              FROM CLIENTES A, CUENTAS_CLIENTE_CORREDORES B
              WHERE B.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
              AND B.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO
              AND A.CLI_ECL_MNEMONICO IN ('INA')
              AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                       FROM CUENTAS_CLIENTE_CORREDORES C
                                       WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                       AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO));

END CLIENTES_INACTIVOS;

/**  Procedimiento para traer el numero de liquidaciones por producto
**/

-- No Liquidaciones RV
PROCEDURE LIQUIDACIONES_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

   -- No Liquidaciones RV
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY  ComercialID,
                   ComercialTID,
                   ClienteID,
                   ClienteTID,
                   Cuenta,
                   Mesa;

END LIQUIDACIONES_RV;

-- NLRF       No Liquidaciones RF
PROCEDURE LIQUIDACIONES_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

   SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO )
       GROUP BY  ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END LIQUIDACIONES_RF;

-- NLIOPCF	No. Liquidaciones OPCF
PROCEDURE LIQUIDACIONES_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

       SELECT  ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM OPCF_LIQUIDACIONES,
                   OPCF_CONTRATOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE LOP_PCC_CONSECUTIVO = PCC_CONSECUTIVO
                AND PCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND PCC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND PCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LOP_ELI_MNEMONICO IN ('APL')
                AND LOP_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LOP_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END LIQUIDACIONES_OPCF;

-- NLIDE	No. Liquidaciones DERIVADOS
PROCEDURE LIQUIDACIONES_DE(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

       SELECT  ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDE' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM OPERACIONES_DE_DERIVADOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODE_LID_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODE_LID_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODE_LID_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODE_LID_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND ODE_LID_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END LIQUIDACIONES_DE;

-- NLIRFYK	No. Liquidaciones RF Yankees
PROCEDURE LIQUIDACIONES_RFY(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND EXISTS (SELECT 'X'
                            FROM ESPECIES_NACIONALES
                            WHERE ENA_MNEMONICO = LIC_MNEMOTECNICO_TITULO
                              AND ENA_YANKEE = 'S')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND EXISTS (SELECT 'X'
                            FROM ESPECIES_NACIONALES
                            WHERE ENA_MNEMONICO = LIC_MNEMOTECNICO_TITULO
                              AND ENA_YANKEE = 'S')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END LIQUIDACIONES_RFY;

/**  Procedimiento para traer el numero de ordenes por producto
**/

-- NORV       No Ordenes RV
PROCEDURE ORDENES_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OVE_EOC_MNEMONICO IN ('APL','PAP')
                AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OVE_COC_CTO_MNEMONICO = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OCO_EOC_MNEMONICO IN  ('APL','PAP')
                AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OCO_COC_CTO_MNEMONICO = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RV;

-- NOOPCF       No Ordenes OPCF
PROCEDURE ORDENES_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM OPCF_CONTRATOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE PCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND PCC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND PCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND PCC_EOC_MNEMONICO IN ('APL')
                AND PCC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND PCC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_OPCF;

-- NORF       No Ordenes RF
PROCEDURE ORDENES_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OVE_EOC_MNEMONICO  IN ('APL','PAP')
                AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OVE_COC_CTO_MNEMONICO = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OCO_EOC_MNEMONICO  IN ('APL','PAP')
                AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OCO_COC_CTO_MNEMONICO = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RF;


-- NODIV	NO ORDENES CLIENTES DIV
PROCEDURE ORDENES_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                    OR
                    (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                     AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                     AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_DI;

/**  Procedimiento para traer el numero de ordenes interbancarias por producto
**/
PROCEDURE ORDENES_INTERBANCARIAS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        -- NOINTDIV	        NO ORDENES INTERBANCARIAS DIVISAS
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_EOF_CODIGO = 'APR'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                    OR
                    (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                     AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                     AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')
              GROUP BY ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_INTERBANCARIAS;

/**  Procedimiento para traer el numero de ordenes de pago ACH por producto
**/

-- NOPACHRV	No Ordenes de Pago ACH RV
PROCEDURE ORDENES_PAGO_ACH_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'ACH'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_ACH_RV;

-- NOPACHRF	No Ordenes de Pago ACH RF
PROCEDURE ORDENES_PAGO_ACH_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
                SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'RF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'ACH'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_ACH_RF;

-- NOPACHCC	No Ordenes de Pago ACH CC
PROCEDURE ORDENES_PAGO_ACH_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'ACH'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_ACH_CC;

-- NOPACHAPT	No Ordenes de Pago ACH APT
PROCEDURE ORDENES_PAGO_ACH_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'ACH'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_ACH_APT;

-- NOPACHDIV	No Ordenes de Pago ACH DIV
PROCEDURE ORDENES_PAGO_ACH_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

          SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
                 SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
                FROM ORDENES_DE_PAGO,
                     ORDENES_DIVISAS,
                     CUENTAS_CLIENTE_CORREDORES,
                     (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                      FROM PERSONAS_CENTROS_PRODUCCION
                      WHERE PCP_PRINCIPAL= 'S') PCP
                WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                  AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                  AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                  AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                  AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                  AND ODP_ESTADO = 'APR'
                  AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                  AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                  AND EXISTS (SELECT 'X'
                              FROM TIPOS_MVTOS_DIVISAS
                              WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                  AND ODP_TPA_MNEMONICO = 'ACH'
                  AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                  AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                GROUP BY CCC_PER_NUM_IDEN,
                         CCC_PER_TID_CODIGO,
                         CCC_CLI_PER_NUM_IDEN,
                         CCC_CLI_PER_TID_CODIGO,
                         CCC_NUMERO_CUENTA,
                         PCP.PCP_CPR_MNEMONICO
                UNION ALL
                SELECT ORD_PER_NUM_IDEN ComercialID,
                       ORD_PER_TID_CODIGO ComercialTID,
                       ORD_CLI_PER_NUM_IDEN ClienteID,
                       ORD_CLI_PER_TID_CODIGO ClienteTID,
                       ORD_CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
                FROM ORDENES_DE_PAGO,
                     ORDENES_DIVISAS,
                     (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                      FROM PERSONAS_CENTROS_PRODUCCION
                      WHERE PCP_PRINCIPAL= 'S') PCP
                WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                  AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                  AND ODP_ESTADO = 'APR'
                  AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                  AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                  AND EXISTS (SELECT 'X'
                              FROM TIPOS_MVTOS_DIVISAS
                              WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                                AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                  AND ODP_TPA_MNEMONICO = 'ACH'
                  AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                  AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
               GROUP BY  ORD_PER_NUM_IDEN,
                         ORD_PER_TID_CODIGO,
                         ORD_CLI_PER_NUM_IDEN,
                         ORD_CLI_PER_TID_CODIGO,
                         ORD_CCC_NUMERO_CUENTA,
                         PCP.PCP_CPR_MNEMONICO)
           GROUP BY ComercialID,
                    ComercialTID,
                    ClienteID,
                    ClienteTID,
                    Cuenta,
                    Mesa;

END ORDENES_PAGO_ACH_DI;

-- NOPACHOPCF	No Ordenes de Pago ACH OPCF
PROCEDURE ORDENES_PAGO_ACH_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

          SELECT ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                  WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                  WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
                 SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
                FROM ORDENES_DE_PAGO,
                     CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
                WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                  AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                  AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                  AND ODP_ESTADO = 'APR'
                  AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                  AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                  AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                  AND ODP_TPA_MNEMONICO = 'ACH'
                  AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                  AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
               GROUP BY  CCC_PER_NUM_IDEN,
                         CCC_PER_TID_CODIGO,
                         CCC_CLI_PER_NUM_IDEN,
                         CCC_CLI_PER_TID_CODIGO,
                         CCC_NUMERO_CUENTA,
                         PCP.PCP_CPR_MNEMONICO)
           GROUP BY ComercialID,
                    ComercialTID,
                    ClienteID,
                    ClienteTID,
                    Cuenta,
                    Mesa;

END ORDENES_PAGO_ACH_OPCF;

-- NOPACHAV	No Ordenes de Pago ACH Admon Val
PROCEDURE ORDENES_PAGO_ACH_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

            SELECT ComercialID,
                   ComercialTID,
                   ClienteID,
                   ClienteTID,
                   Cuenta,
                   (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                    WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                    WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
                   SUM(TOTAL) Factor
            FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                         CCC_PER_TID_CODIGO ComercialTID,
                         CCC_CLI_PER_NUM_IDEN ClienteID,
                         CCC_CLI_PER_TID_CODIGO ClienteTID,
                         CCC_NUMERO_CUENTA Cuenta,
                         PCP.PCP_CPR_MNEMONICO Mesa,
                         COUNT(*) TOTAL
                  FROM ORDENES_DE_PAGO,
                       CUENTAS_CLIENTE_CORREDORES,
                       (SELECT  PCP_PER_NUM_IDEN,
                                PCP_PER_TID_CODIGO,
                                PCP_CPR_MNEMONICO,
                                PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                  WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND ODP_ESTADO = 'APR'
                    AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                    AND ODP_TPA_MNEMONICO = 'ACH'
                    AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                    AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                 GROUP BY  CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO,
                           CCC_CLI_PER_NUM_IDEN,
                           CCC_CLI_PER_TID_CODIGO,
                           CCC_NUMERO_CUENTA,
                           PCP.PCP_CPR_MNEMONICO)
             GROUP BY ComercialID,
                      ComercialTID,
                      ClienteID,
                      ClienteTID,
                      Cuenta,
                      Mesa;

END ORDENES_PAGO_ACH_ADVAL;

/**  Procedimiento para traer el numero de ordenes de pago CHE por producto
**/

-- NOPCHERV	No Ordenes de Pago CHE RV
PROCEDURE ORDENES_PAGO_CHE_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_RV;

-- NOPCHERF	No Ordenes de Pago CHE RF
PROCEDURE ORDENES_PAGO_CHE_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'RF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_RF;

-- NOPCHECC	No Ordenes de Pago CHE CC
PROCEDURE ORDENES_PAGO_CHE_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_CC;

-- NOPCHEAPT	No Ordenes de Pago CHE APT
PROCEDURE ORDENES_PAGO_CHE_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_APT;

-- NOPCHEDIV	No Ordenes de Pago CHE DIV
PROCEDURE ORDENES_PAGO_CHE_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_DI;

-- NOPCHEOPCF	No Ordenes de Pago CHE OPCF
PROCEDURE ORDENES_PAGO_CHE_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_OPCF;

-- NOPCHEAV	No Ordenes de Pago CHE Admon Val
PROCEDURE ORDENES_PAGO_CHE_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHE_ADVAL;

/**  Procedimiento para traer el numero de ordenes de pago CHG por producto
**/

-- NOPCHGRV	No Ordenes de Pago CHG RV
PROCEDURE ORDENES_PAGO_CHG_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_RV;

-- NOPCHGRF	No Ordenes de Pago CHG RF
PROCEDURE ORDENES_PAGO_CHG_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'RF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_RF;

-- NOPCHGCC	No Ordenes de Pago CHG CC
PROCEDURE ORDENES_PAGO_CHG_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_CC;

-- NOPCHGAPT	No Ordenes de Pago CHG APT
PROCEDURE ORDENES_PAGO_CHG_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_APT;

-- NOPCHGDIV	No Ordenes de Pago CHG DIV
PROCEDURE ORDENES_PAGO_CHG_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_DI;

-- NOPCHGOPCF	No Ordenes de Pago CHG OPCF
PROCEDURE ORDENES_PAGO_CHG_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_OPCF;

-- NOPCHGAV	No Ordenes de Pago CHG Admon Val
PROCEDURE ORDENES_PAGO_CHG_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'CHG'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_CHG_ADVAL;

/**  Procedimiento para traer el numero de ordenes de pago PSE por producto
**/

-- NOPPSERV	No Ordenes de Pago PSE RV
PROCEDURE ORDENES_PAGO_PSE_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_RV;

-- NOPPSERF	No Ordenes de Pago PSE RF
PROCEDURE ORDENES_PAGO_PSE_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'RF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_RF;

-- NOPPSECC	No Ordenes de Pago PSE CC
PROCEDURE ORDENES_PAGO_PSE_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_CC;

-- NOPPSEAPT	No Ordenes de Pago PSE APT
PROCEDURE ORDENES_PAGO_PSE_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_APT;

-- NOPPSEDIV	No Ordenes de Pago PSE DIV
PROCEDURE ORDENES_PAGO_PSE_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_DI;

-- NOPPSEOPCF	No Ordenes de Pago PSE OPCF
PROCEDURE ORDENES_PAGO_PSE_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_OPCF;

-- NOPPSEAV	No Ordenes de Pago PSE Admon Val
PROCEDURE ORDENES_PAGO_PSE_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_PSE_ADVAL;

/**  Procedimiento para traer el numero de ordenes de pago TCC por producto
**/

-- NOPTCCRV	No Ordenes de Pago TCC RV
PROCEDURE ORDENES_PAGO_TCC_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_RV;

-- NOPTCCRF	No Ordenes de Pago TCC RF
PROCEDURE ORDENES_PAGO_TCC_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'RF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_RF;

-- NOPTCCCC	No Ordenes de Pago TCC CC
PROCEDURE ORDENES_PAGO_TCC_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_CC;

-- NOPTCCAPT	No Ordenes de Pago TCC APT
PROCEDURE ORDENES_PAGO_TCC_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_APT;

-- NOPTCCDIV	No Ordenes de Pago TCC DIV
PROCEDURE ORDENES_PAGO_TCC_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_DI;

-- NOPTCCOPCF	No Ordenes de Pago TCC OPCF
PROCEDURE ORDENES_PAGO_TCC_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_OPCF;

-- NOPTCCAV	No Ordenes de Pago TCC Admon Val
PROCEDURE ORDENES_PAGO_TCC_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TCC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TCC_ADVAL;

/**  Procedimiento para traer el numero de ordenes de pago TRB por producto
**/

-- NOPTRBRV	No Ordenes de Pago TRB RV
PROCEDURE ORDENES_PAGO_TRB_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ACC'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_RV;

-- NOPTRBRF	No Ordenes de Pago TRB RF
PROCEDURE ORDENES_PAGO_TRB_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'RF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_RF;

-- NOPTRBCC	No Ordenes de Pago TRB CC
PROCEDURE ORDENES_PAGO_TRB_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_CC;

-- NOPTRBAPT	No Ordenes de Pago TRB APT
PROCEDURE ORDENES_PAGO_TRB_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_NPR_PRO_MNEMONICO = ODP_NPR_PRO_MNEMONICO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_APT;

-- NOPTRBDIV	No Ordenes de Pago TRB DIV
PROCEDURE ORDENES_PAGO_TRB_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_DI;

-- NOPTRBOPCF	No Ordenes de Pago TRB OPCF
PROCEDURE ORDENES_PAGO_TRB_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'OPCF'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_OPCF;

-- NOPTRBAV	No Ordenes de Pago TRB Admon Val
PROCEDURE ORDENES_PAGO_TRB_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_PAGO_TRB_ADVAL;

/**  Procedimiento para traer el numero de ordenes de recaudo CHE por producto
**/

-- NRECHERV	No Ordenes de  Recaudo CHE RV
PROCEDURE ORDENES_RECAUDO_CHE_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND OCO_COBRAR_CHEQUE = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CHE_RV;

-- NRECHERF	No Ordenes de  Recaudo CHE RF
PROCEDURE ORDENES_RECAUDO_CHE_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND OCO_COBRAR_CHEQUE = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CHE_RF;

-- NRECHECC	No Ordenes de  Recaudo CHE CC
PROCEDURE ORDENES_RECAUDO_CHE_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CHE_CC;

-- NRECHEAPT	No Ordenes de  Recaudo CHE APT
PROCEDURE ORDENES_RECAUDO_CHE_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CHE_APT;

-- NRECHEDIV	No Ordenes de  Recaudo CHE DIV
PROCEDURE ORDENES_RECAUDO_CHE_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ORR_TPA_MNEMONICO = 'CHE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ORR_TPA_MNEMONICO = 'CHE'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CHE_DI;

/**  Procedimiento para traer el numero de ordenes de recaudo PSE por producto
**/

-- NREPSERV	No Ordenes de  Recaudo PSE RV
PROCEDURE ORDENES_RECAUDO_PSE_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND OCO_COBRAR_SEBRA = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_PSE_RV;

-- NREPSERF	No Ordenes de  Recaudo PSE RF
PROCEDURE ORDENES_RECAUDO_PSE_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND OCO_COBRAR_SEBRA = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_PSE_RF;

-- NREPSECC	No Ordenes de  Recaudo PSE CC
PROCEDURE ORDENES_RECAUDO_PSE_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_PSE_CC;

-- NREPSEAPT	No Ordenes de  Recaudo PSE APT
PROCEDURE ORDENES_RECAUDO_PSE_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_PSE_APT;

-- NREPSEDIV	No Ordenes de  Recaudo PSE DIV
PROCEDURE ORDENES_RECAUDO_PSE_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ORR_TPA_MNEMONICO = 'PSE'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ORR_TPA_MNEMONICO = 'PSE'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_PSE_DI;

/**  Procedimiento para traer el numero de ordenes de recaudo TRB por producto
**/

-- NRETRBRV	No Ordenes de  Recaudo TRB RV
PROCEDURE ORDENES_RECAUDO_TRB_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND OCO_COBRAR_TRANSFERENCIA_BANCA = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_TRB_RV;

-- NRETRBRF	No Ordenes de  Recaudo TRB RF
PROCEDURE ORDENES_RECAUDO_TRB_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND OCO_COBRAR_TRANSFERENCIA_BANCA = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_TRB_RF;

-- NRETRBCC	No Ordenes de  Recaudo TRB CC
PROCEDURE ORDENES_RECAUDO_TRB_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_TRB_CC;

-- NRETRBAPT	No Ordenes de  Recaudo TRB APT
PROCEDURE ORDENES_RECAUDO_TRB_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_TRB_APT;

-- NRETRBDIV	No Ordenes de  Recaudo TRB DIV
PROCEDURE ORDENES_RECAUDO_TRB_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ORR_TPA_MNEMONICO = 'TRB'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ORR_TPA_MNEMONICO = 'TRB'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_TRB_DI;


/**  Procedimiento para traer el numero de ordenes de recaudo CEF por producto
**/

-- NRECEFRF	No Ordenes de  Recaudo CEF RF
PROCEDURE ORDENES_RECAUDO_CEF_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND OCO_COBRAR_CONSIGNA = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CEF_RF;

-- NRECEFRV	No Ordenes de  Recaudo CEF RV
PROCEDURE ORDENES_RECAUDO_CEF_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND OCO_COBRAR_CONSIGNA = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CEF_RV;

-- NRECEFCC	No Ordenes de  Recaudo CEF CC
PROCEDURE ORDENES_RECAUDO_CEF_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'CEF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CEF_CC;

-- NRECEFAPT	No Ordenes de  Recaudo CEF APT
PROCEDURE ORDENES_RECAUDO_CEF_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   ORDENES_RECAUDO,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORR_OFO_SUC_CODIGO = OFO_SUC_CODIGO
                AND ORR_OFO_CONSECUTIVO = OFO_CONSECUTIVO
                AND OFO_EOF_CODIGO = 'APR'
                AND EXISTS (SELECT 'X'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ORR_TPA_MNEMONICO = 'CEF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CEF_APT;

-- NRECEFDIV	No Ordenes de  Recaudo CEF DIV
PROCEDURE ORDENES_RECAUDO_CEF_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ORR_TPA_MNEMONICO = 'CEF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_EOF_CODIGO = 'APR'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ORR_TPA_MNEMONICO = 'CEF'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORDENES_RECAUDO_CEF_DI;

/**  Procedimiento para traer el numero de ordenes con instrucci¿n
     de env¿o/recoger - compra por producto
**/

-- No Ordenes Instrucci¿n Enviar/Recoger Compra RV
PROCEDURE ORD_INSTRUC_ENV_REC_COMPRA_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OCO_EOC_MNEMONICO  IN ('APL','PAP')
                AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OCO_COC_CTO_MNEMONICO = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND (OCO_ENVIAR_FACTURA = 'S'
                     OR OCO_ENVIAR_CARTA_COMPROMISO = 'S'
                     OR OCO_ENVIAR_RECIBO_CUSTODIA = 'S'
                     OR OCO_ENVIAR_CARTA_CARRU_PLAZO = 'S'
                     OR OCO_RECOGER_CHEQUE = 'S')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_COMPRA_RV;

-- NOIERRFC	No Ordenes Instrucci¿n Enviar/Recoger RF Compra
PROCEDURE ORD_INSTRUC_ENV_REC_COMPRA_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OCO_EOC_MNEMONICO  IN ('APL','PAP')
                AND OCO_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OCO_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OCO_COC_CTO_MNEMONICO = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND (OCO_ENVIAR_FACTURA = 'S'
                     OR OCO_ENVIAR_CARTA_COMPROMISO = 'S'
                     OR OCO_ENVIAR_RECIBO_CUSTODIA = 'S'
                     OR OCO_ENVIAR_CARTA_CARRU_PLAZO = 'S'
                     OR OCO_RECOGER_CHEQUE = 'S')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_COMPRA_RF;

-- NOIERDIVC	No Ordenes Instruccion Enviar/Recoger Divisas Compra
PROCEDURE ORD_INSTRUC_ENV_REC_COMPRA_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND ORD_TIPO_ORDEN = 'C'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_EOF_CODIGO = 'APR'
                AND ORD_TIPO_ORDEN = 'C'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ORR_INSTRUCCION_CHEQUE IN ('R')      --DILIGENCIA
              GROUP BY ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ORD_TIPO_ORDEN = 'C'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ORD_TIPO_ORDEN = 'C'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_COMPRA_DI;

/**  Procedimiento para traer el numero de ordenes con instrucci¿n
     de env¿o/recoger - venta por producto
**/

-- NOIERRFV	No Ordenes Instrucci¿n Enviar/Recoger RF Venta
PROCEDURE ORD_INSTRUC_ENV_REC_VENTA_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OVE_EOC_MNEMONICO  IN ('APL','PAP')
                AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OVE_COC_CTO_MNEMONICO = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND (OVE_ENVIAR_FACTURA= 'S'
                     OR OVE_DINERO_CONTRA_TITULOS = 'S'
                     OR OVE_RECOGER_CARTA = 'S'
                     OR OVE_RECOGER_CERT_CAMARA = 'S')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_VENTA_RF;

-- NOIERRVV	No Ordenes Instrucci¿n Enviar/Recoger RV Venta
PROCEDURE ORD_INSTRUC_ENV_REC_VENTA_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OVE_EOC_MNEMONICO  IN ('APL','PAP')
                AND OVE_FECHA_Y_HORA >= TRUNC(P_FECHA)
                AND OVE_FECHA_Y_HORA <  TRUNC(P_FECHA) + 1
                AND OVE_COC_CTO_MNEMONICO = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND (OVE_ENVIAR_FACTURA= 'S'
                     OR OVE_DINERO_CONTRA_TITULOS = 'S'
                     OR OVE_RECOGER_CARTA = 'S'
                     OR OVE_RECOGER_CERT_CAMARA = 'S')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_VENTA_RV;

-- NOIERDIVV	No Ordenes Instrucci¿n Enviar/Recoger Divisas Venta
PROCEDURE ORD_INSTRUC_ENV_REC_VENTA_DI(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ORD_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ORD_TIPO_ORDEN = 'V'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ORR_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
                AND ORD_EOF_CODIGO = 'APR'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ORD_TIPO_ORDEN = 'V'
                AND ((ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
                      AND ORD_FECHA_APROBACION < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NULL)
                     OR
                     (ORD_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                      AND ORD_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                      AND ORD_FECHA_CUMPLIMIENTO IS NOT NULL))
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND ORR_INSTRUCCION_CHEQUE IN ('R')      --DILIGENCIA
              GROUP BY ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ORD_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ORD_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ORD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ORD_TIPO_ORDEN = 'V'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'N')   -- ORDENES DE CLIENTES
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT ORD_PER_NUM_IDEN ComercialID,
                     ORD_PER_TID_CODIGO ComercialTID,
                     ORD_CLI_PER_NUM_IDEN ClienteID,
                     ORD_CLI_PER_TID_CODIGO ClienteTID,
                     ORD_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_DIVISAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ORD_SUC_CODIGO = ODP_ORD_SUC_CODIGO
                AND ORD_CONSECUTIVO = ODP_ORD_CONSECUTIVO
                AND ODP_ESTADO = 'APR'
                AND ORD_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND ORD_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ORD_TIPO_ORDEN = 'V'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'X'
                            FROM TIPOS_MVTOS_DIVISAS
                            WHERE TMD_MNEMONICO = ORD_TMD_MNEMONICO
                              AND TMD_MOVIMIENTO_INTERBANCARIO = 'S')   -- ORDENES INTERBANCARIAS
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
             GROUP BY  ORD_PER_NUM_IDEN,
                       ORD_PER_TID_CODIGO,
                       ORD_CLI_PER_NUM_IDEN,
                       ORD_CLI_PER_TID_CODIGO,
                       ORD_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_VENTA_DI;

/**  Procedimiento para traer el numero de ordenes con instrucci¿n
     de env¿o/recoger - ingresos por producto
**/

-- NOIERCCI	No Ordenes Instrucci¿n Enviar/Recoger CC Ingresos
PROCEDURE ORD_INSTRUC_ENV_REC_ING_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                     AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_ING_CC;

-- NOIERAPTI	No Ordenes Instrucci¿n Enviar/Recoger APT Ingresos
PROCEDURE ORD_INSTRUC_ENV_REC_ING_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                     AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_ING_APT;

/**  Procedimiento para traer el numero de ordenes con instrucci¿n
     de env¿o/recoger - retiros por producto
**/

-- NOIERCCV	No Ordenes Instrucci¿n Enviar/Recoger CC Retiros
PROCEDURE ORD_INSTRUC_ENV_REC_RET_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                     AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_RET_CC;

-- NOIERAPTV	No Ordenes Instrucci¿n Enviar/Recoger APT Retiros
PROCEDURE ORD_INSTRUC_ENV_REC_RET_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_RECAUDO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                     AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND ORR_INSTRUCCION_CHEQUE IN ('R')  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_SUC_CODIGO = ODP_OFO_SUC_CODIGO
                AND OFO_CONSECUTIVO = ODP_OFO_CONSECUTIVO
                AND OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_REC_RET_APT;

/**  Procedimiento para traer el numero de ordenes con instrucci¿n
     de env¿o/recoger - administracion valores
**/
PROCEDURE ORD_INSTRUC_ENV_RECOG_ADVAL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
   -- NOIERAV	No Ordenes Instrucci¿n Enviar/Recoger Admon Valores RV
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIAV' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ODP_NPR_PRO_MNEMONICO = 'ADVAL'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND (ODP_ENTREGAR_RECOGE = 'E'
                     OR ODP_CONSIGNAR = 'S' )  --DILIGENCIA
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END ORD_INSTRUC_ENV_RECOG_ADVAL;

/**  Procedimiento para traer el numero de movimientos para el producto administraci¿n de valores, en cuanto
     a los rendimientos en los dividendos
**/
PROCEDURE MOV_ADMON_RENDIM_DIVIDENDOS (P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- NMOVDRA	NO MOV ADMON VALORES RENDIM AMORT DIVIDENDOS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM MOVIMIENTOS_CUENTA_CORREDORES,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE MCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND MCC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND MCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND MCC_TMC_MNEMONICO in ('ABA','ABI','ABD','ABR','APFF')
                AND (MCC_FRF_FECHA IS NOT NULL OR MCC_FAF_FECHA IS NOT NULL OR MCC_FRC_FECHA IS NOT NULL OR MCC_FAC_FECHA IS NOT NULL)
                AND MCC_FECHA >= TRUNC(P_FECHA)
                AND MCC_FECHA < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa
      UNION ALL
      SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM MOVIMIENTOS_CUENTA_CORREDORES,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE MCC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND MCC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND MCC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND MCC_TMC_MNEMONICO in ('ABA','ABI','ABD','ABR','APFF')
                AND (MCC_FDF_FECHA IS NOT NULL OR MCC_FDC_FECHA IS NOT NULL)
                AND MCC_FECHA >= TRUNC(P_FECHA)
                AND MCC_FECHA < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END MOV_ADMON_RENDIM_DIVIDENDOS;

/**  Procedimiento para traer el numero de ingresos por producto
**/

-- NICC	No Ingresos CC
PROCEDURE INGRESOS_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                     AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'F'
                              AND FON_CODIGO NOT IN ('111111'))
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END INGRESOS_CC;

-- NIAPT	No Ingresos APT
PROCEDURE INGRESOS_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

          SELECT ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                  WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                  WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
                 SUM(TOTAL) Factor
          FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       COUNT(*) TOTAL
                FROM ORDENES_FONDOS,
                     CUENTAS_CLIENTE_CORREDORES,
                     (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                      FROM PERSONAS_CENTROS_PRODUCCION
                      WHERE PCP_PRINCIPAL= 'S') PCP
                WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                  AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                  AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                  AND OFO_EOF_CODIGO = 'APR'
                  AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                  AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                  AND OFO_TTO_TOF_CODIGO IN ('ING','INC')
                  AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                       AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                  AND EXISTS (SELECT 'S'
                              FROM FONDOS
                              WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                                AND FON_TIPO = 'A'
                                AND FON_TIPO_ADMINISTRACION = 'A')
               GROUP BY  CCC_PER_NUM_IDEN,
                         CCC_PER_TID_CODIGO,
                         CCC_CLI_PER_NUM_IDEN,
                         CCC_CLI_PER_TID_CODIGO,
                         CCC_NUMERO_CUENTA,
                         PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;
END INGRESOS_APT;

/**  Procedimiento para traer el numero de retiros por producto
**/

-- NRCC	No Retiros CC
PROCEDURE RETIROS_CC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARCC' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                   COUNT(*) TOTAL
            FROM ORDENES_FONDOS,
                 CUENTAS_CLIENTE_CORREDORES,
                 (SELECT  PCP_PER_NUM_IDEN,
                          PCP_PER_TID_CODIGO,
                          PCP_CPR_MNEMONICO,
                          PCP_PRINCIPAL
                  FROM PERSONAS_CENTROS_PRODUCCION
                  WHERE PCP_PRINCIPAL= 'S') PCP
            WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
              AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
              AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
              AND OFO_EOF_CODIGO = 'APR'
              AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
              AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
              AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                   AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
              AND EXISTS (SELECT 'S'
                          FROM FONDOS
                          WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                            AND FON_TIPO = 'A'
                            AND FON_TIPO_ADMINISTRACION = 'F'
                            AND FON_CODIGO NOT IN ('111111'))
           GROUP BY  CCC_PER_NUM_IDEN,
                     CCC_PER_TID_CODIGO,
                     CCC_CLI_PER_NUM_IDEN,
                     CCC_CLI_PER_TID_CODIGO,
                     CCC_NUMERO_CUENTA,
                     PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END RETIROS_CC;

-- NRAPT	No Retiros APT
PROCEDURE RETIROS_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PARAPT' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_FONDOS,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OFO_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OFO_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OFO_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND OFO_EOF_CODIGO = 'APR'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OFO_TTO_TOF_CODIGO IN ('RT','RP')
                AND (OFO_FECHA_EJECUCION >= TRUNC(P_FECHA)
                     AND OFO_FECHA_EJECUCION < TRUNC(P_FECHA) + 1)
                AND EXISTS (SELECT 'S'
                            FROM FONDOS
                            WHERE FON_CODIGO = OFO_CFO_FON_CODIGO
                              AND FON_TIPO = 'A'
                              AND FON_TIPO_ADMINISTRACION = 'A')
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;
END RETIROS_APT;

/**  Procedimiento para traer el numero de extractos generados
**/
PROCEDURE EXTRACTOS_GENERADOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
   -- NEXTGEN	No Extractos Generados (Fdos, MCC)
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'N/A' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(CEF_CONSECUTIVO) TOTAL
              FROM CONTROL_EXTRACTOS_FONDOS A,
                   CUENTAS_CLIENTE_CORREDORES B,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE CEF_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND CEF_CFO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_cODIGO
                AND CEF_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND CEF_FECHA >= TRUNC(P_FECHA)
                AND CEF_FECHA <  TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(CGX_CONSECUTIVO) TOTAL
              FROM CONTROL_GENERACION_EXTRACTOS A,
                   CUENTAS_CLIENTE_CORREDORES B,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE CGX_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND CGX_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_cODIGO
                AND CGX_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND CGX_FECHA >= TRUNC(P_FECHA)
                AND CGX_FECHA <  TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY  CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END EXTRACTOS_GENERADOS;

/**  Procedimiento para traer el numero de extractos generados
**/
PROCEDURE MOV_GARANTIA_TESORERIA_OPCF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
   -- NOMOVGART	NO MOV GARANTIA DE TESORERIA
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIOPCF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM RECIBOS_DE_CAJA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND RCA_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND RCA_REVERSADO = 'N'
                AND RCA_ES_CLIENTE = 'S'
                AND RCA_COT_MNEMONICO IN ('GOPCF')
                AND RCA_FECHA >= TRUNC(P_FECHA)
                AND RCA_FECHA < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_COT_MNEMONICO IN ('GOPCF')
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END MOV_GARANTIA_TESORERIA_OPCF;

/**  Procedimiento para traer el numero de extractos generados
**/
PROCEDURE MOV_GARANTIA_TESORERIA(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
   -- NOMOVGART	NO MOV GARANTIA DE TESORERIA
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'N/A' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM RECIBOS_DE_CAJA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND RCA_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND RCA_REVERSADO = 'N'
                AND RCA_ES_CLIENTE = 'S'
                AND RCA_COT_MNEMONICO IN ('RGCF','GOPCE','PGPCF','RGPCF','RGCE')
                AND RCA_FECHA >= TRUNC(P_FECHA)
                AND RCA_FECHA < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_COT_MNEMONICO IN ('RGCF','GOPCE','PGPCF','RGPCF','RGCE')
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END MOV_GARANTIA_TESORERIA;

/**  Procedimiento para traer el numero de movimientos deceval garantia
**/

-- NOMOVDCVG	NO MOV DECEVAL GARANTIA RF
PROCEDURE MOV_DECEVAL_GARANTIA_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM MOVIMIENTOS_CUENTA_FUNGIBLE,
                   CUENTAS_FUNGIBLE_CLIENTE,
                   CUENTAS_CLIENTE_CORREDORES,
                   FUNGIBLES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE MFU_CFC_CUENTA_DECEVAL = CFC_CUENTA_DECEVAL
                AND MFU_CFC_FUG_ISI_MNEMONICO = CFC_FUG_ISI_MNEMONICO
                AND MFU_CFC_FUG_MNEMONICO = CFC_FUG_MNEMONICO
                AND CFC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND CFC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND CFC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND MFU_FECHA >= TRUNC(P_FECHA)
                AND MFU_FECHA <  TRUNC(P_FECHA)+1
                AND MFU_TFU_MNEMONICO IN ('DIGA','GADI','DIGAD','GADID','RDIG','RGDI','RDGE','RGED','DGES','GESD')
                AND CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
                AND CFC_FUG_MNEMONICO = FUG_MNEMONICO
                AND FUG_TIPO = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END MOV_DECEVAL_GARANTIA_RF;

-- NOMOVDCVG	NO MOV DECEVAL GARANTIA RV
PROCEDURE MOV_DECEVAL_GARANTIA_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM MOVIMIENTOS_CUENTA_FUNGIBLE,
                   CUENTAS_FUNGIBLE_CLIENTE,
                   CUENTAS_CLIENTE_CORREDORES,
                   FUNGIBLES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE MFU_CFC_CUENTA_DECEVAL = CFC_CUENTA_DECEVAL
                AND MFU_CFC_FUG_ISI_MNEMONICO = CFC_FUG_ISI_MNEMONICO
                AND MFU_CFC_FUG_MNEMONICO = CFC_FUG_MNEMONICO
                AND CFC_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND CFC_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND CFC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND MFU_FECHA >= TRUNC(P_FECHA)
                AND MFU_FECHA <  TRUNC(P_FECHA)+1
                AND MFU_TFU_MNEMONICO IN ('DIGA','GADI','DIGAD','GADID','RDIG','RGDI','RDGE','RGED','DGES','GESD')
                AND CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
                AND CFC_FUG_MNEMONICO = FUG_MNEMONICO
                AND FUG_TIPO = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END MOV_DECEVAL_GARANTIA_RV;

/**  Procedimiento para traer el numero de liquidaciones cumplidas por deceval
**/

-- NLRF       No Liquidaciones RF
PROCEDURE LIQ_CUMPLIDAS_DCVAL_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_SUCURSAL_CUMPLIMIENTO = 'DVL'
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_SUCURSAL_CUMPLIMIENTO = 'DVL'
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO )
       GROUP BY  ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END LIQ_CUMPLIDAS_DCVAL_RF;

-- NLRF       No Liquidaciones RV
PROCEDURE LIQ_CUMPLIDAS_DCVAL_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_SUCURSAL_CUMPLIMIENTO = 'DVL'
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_SUCURSAL_CUMPLIMIENTO = 'DVL'
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO )
       GROUP BY  ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;


END LIQ_CUMPLIDAS_DCVAL_RV;

/**  Procedimiento para traer el numero de liquidaciones por producto a nivel de valor
**/

-- No Liquidaciones RV
PROCEDURE LIQUIDACIONES_VALOR_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     SUM(LIC_VOLUMEN_NETO_FRACCION) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     SUM(LIC_VOLUMEN_NETO_FRACCION) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'ACC'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
         GROUP BY  ComercialID,
                   ComercialTID,
                   ClienteID,
                   ClienteTID,
                   Cuenta,
                   Mesa;

END LIQUIDACIONES_VALOR_RV;

-- NLRF       No Liquidaciones RF
PROCEDURE LIQUIDACIONES_VALOR_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     SUM(LIC_VOLUMEN_NETO_FRACCION) TOTAL
              FROM ORDENES_VENTA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     SUM(LIC_VOLUMEN_NETO_FRACCION) TOTAL
              FROM ORDENES_COMPRA,
                   LIQUIDACIONES_COMERCIAL,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND LIC_CLASE_TRANSACCION = 'RF'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO )
       GROUP BY  ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END LIQUIDACIONES_VALOR_RF;

/**  Procedimiento para traer el numero de recibos de caja
**/
PROCEDURE RECIBOS_CAJA(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR
   -- NRECAJ	No de Recibos de Caja
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'N/A' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM RECIBOS_DE_CAJA,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND RCA_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND RCA_REVERSADO = 'N'
                AND RCA_ES_CLIENTE = 'S'
                AND RCA_FECHA >= TRUNC(P_FECHA)
                AND RCA_FECHA < TRUNC(P_FECHA) + 1
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO)
       GROUP BY  ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END RECIBOS_CAJA;

/**  Procedimiento para traer el numero de clientes nuevos
**/
PROCEDURE CLIENTES_NUEVOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- CLINUE	CLIENTES NUEVOS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta
              FROM CLIENTES A, CUENTAS_CLIENTE_CORREDORES B
              WHERE B.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
              AND B.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO
              AND A.CLI_ECL_MNEMONICO IN ('ACC','ACI')
              AND A.CLI_FECHA_APERTURA >= TRUNC(P_FECHA)
              AND A.CLI_FECHA_APERTURA <  TRUNC(P_FECHA) + 1
              AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                       FROM CUENTAS_CLIENTE_CORREDORES C
                                       WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                       AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO));

END CLIENTES_NUEVOS;

/**  Procedimiento para traer el numero de liquidaciones repos por producto
**/
PROCEDURE LIQUIDACIONES_REPOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        -- NUMLIQREP      No Liquidaciones REPOS RF
            SELECT ComercialID,
                   ComercialTID,
                   ClienteID,
                   ClienteTID,
                   Cuenta,
                   (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                    WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                    WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
                   SUM(TOTAL) Factor
            FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                         CCC_PER_TID_CODIGO ComercialTID,
                         CCC_CLI_PER_NUM_IDEN ClienteID,
                         CCC_CLI_PER_TID_CODIGO ClienteTID,
                         CCC_NUMERO_CUENTA Cuenta,
                         PCP.PCP_CPR_MNEMONICO Mesa,
                         COUNT(*) TOTAL
                  FROM ORDENES_VENTA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES,
                       (SELECT  PCP_PER_NUM_IDEN,
                                PCP_PER_TID_CODIGO,
                                PCP_CPR_MNEMONICO,
                                PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                  WHERE OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
                    AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
                    AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OVE_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_TIPO_OFERTA IN ('R','A')
                    AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                    AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO,
                           CCC_CLI_PER_NUM_IDEN,
                           CCC_CLI_PER_TID_CODIGO,
                           CCC_NUMERO_CUENTA,
                           PCP.PCP_CPR_MNEMONICO
                  UNION ALL
                  SELECT CCC_PER_NUM_IDEN ComercialID,
                         CCC_PER_TID_CODIGO ComercialTID,
                         CCC_CLI_PER_NUM_IDEN ClienteID,
                         CCC_CLI_PER_TID_CODIGO ClienteTID,
                         CCC_NUMERO_CUENTA Cuenta,
                         PCP.PCP_CPR_MNEMONICO Mesa,
                         COUNT(*) TOTAL
                  FROM ORDENES_COMPRA,
                       LIQUIDACIONES_COMERCIAL,
                       CUENTAS_CLIENTE_CORREDORES,
                       (SELECT  PCP_PER_NUM_IDEN,
                                PCP_PER_TID_CODIGO,
                                PCP_CPR_MNEMONICO,
                                PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                  WHERE OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                    AND OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
                    AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
                    AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND OCO_CCC_cLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                    AND LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                    AND LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                    AND LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                    AND LIC_TIPO_OFERTA IN ('R','A')
                    AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                    AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                  GROUP BY CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO,
                           CCC_CLI_PER_NUM_IDEN,
                           CCC_CLI_PER_TID_CODIGO,
                           CCC_NUMERO_CUENTA,
                           PCP.PCP_CPR_MNEMONICO)
           GROUP BY  ComercialID,
                     ComercialTID,
                     ClienteID,
                     ClienteTID,
                     Cuenta,
                     Mesa;

END LIQUIDACIONES_REPOS;

/**  Procedimiento para traer el numero de clientes actualizados
**/
PROCEDURE CLIENTES_ACTUALIZADOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- CLIACT	No Clientes Actualizados  : CLIENTES QUE PASARON DE INACTIVO A ACTIVO

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta
              FROM CLIENTES A, CUENTAS_CLIENTE_CORREDORES B
              WHERE B.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
              AND B.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO
              AND A.CLI_ECL_MNEMONICO IN ('ACC','ACI')
              AND A.CLI_FECHA_APERTURA >= TRUNC(P_FECHA)
              AND A.CLI_FECHA_APERTURA <  TRUNC(P_FECHA) + 1
              AND EXISTS (SELECT 'X'
                                FROM CONTROL_ACTUALIZACIONES
                                WHERE CAC_FECHA_ACTUALIZACION >= TRUNC(P_FECHA)
                                  AND CAC_FECHA_ACTUALIZACION  < TRUNC(P_FECHA) + 1
                                  AND CAC_TABLA = 'CLIENTES'
                                  AND CAC_COLUMNA = 'CLI_ECL_MNEMONICO'
                                  AND CAC_VALOR_ANTERIOR = 'INA'
                                  AND CAC_VALOR_ACTUAL IN ('ACC','ACI'))
              AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                       FROM CUENTAS_CLIENTE_CORREDORES C
                                       WHERE C.CCC_CLI_PER_NUM_IDEN = A.CLI_PER_NUM_IDEN
                                       AND C.CCC_CLI_PER_TID_CODIGO = A.CLI_PER_TID_CODIGO));

END CLIENTES_ACTUALIZADOS;

/**  Procedimiento para traer el numero de operaciones posicion propia
**/
PROCEDURE LIQUIDACIONES_POSICION_PROPIA(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS
 -- CLIACT	No Clientes Actualizados  : CLIENTES QUE PASARON DE INACTIVO A ACTIVO

BEGIN
   OPEN io_cursor FOR
   -- NOOPPP No Operaciones de Posicion Propia
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OVE_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OVE_COC_CTO_MNEMONICO = B.LIC_OVE_COC_CTO_MNEMONICO
                AND A.OVE_CONSECUTIVO = B.LIC_OVE_CONSECUTIVO
                AND A.OVE_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OVE_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OVE_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'RF'
                AND B.LIC_NIT_1 = '860079174'
                AND C.CCC_NUMERO_CUENTA = 6    -- CUENTA DE RECURSOS PROPIOS DE CORREDORES
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OCO_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OCO_COC_CTO_MNEMONICO = B.LIC_OCO_COC_CTO_MNEMONICO
                AND A.OCO_CONSECUTIVO = B.LIC_OCO_CONSECUTIVO
                AND A.OCO_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OCO_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OCO_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'RF'
                AND B.LIC_NIT_1 != '860079174'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND EXISTS (SELECT 'X'
                            FROM ORDENES_VENTA D,
                                 LIQUIDACIONES_COMERCIAL E
                            WHERE D.OVE_BOL_MNEMONICO = E.LIC_BOL_MNEMONICO
                              AND D.OVE_COC_CTO_MNEMONICO = E.LIC_OVE_COC_CTO_MNEMONICO
                              AND D.OVE_CONSECUTIVO = E.LIC_OVE_CONSECUTIVO
                              AND E.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                              AND E.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                              AND E.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                              AND E.LIC_CLASE_TRANSACCION = 'RF'
                              AND E.LIC_NIT_1 = '860079174'
                              AND E.LIC_NUMERO_OPERACION = B.LIC_NUMERO_OPERACION
                              AND E.LIC_TIPO_OPERACION = 'V')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OCO_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OCO_COC_CTO_MNEMONICO = B.LIC_OCO_COC_CTO_MNEMONICO
                AND A.OCO_CONSECUTIVO = B.LIC_OCO_CONSECUTIVO
                AND A.OCO_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OCO_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OCO_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'RF'
                AND B.LIC_NIT_1 = '860079174'
                AND C.CCC_NUMERO_CUENTA = 6    -- CUENTA DE RECURSOS PROPIOS DE CORREDORES
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OVE_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OVE_COC_CTO_MNEMONICO = B.LIC_OVE_COC_CTO_MNEMONICO
                AND A.OVE_CONSECUTIVO = B.LIC_OVE_CONSECUTIVO
                AND A.OVE_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OVE_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OVE_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'RF'
                AND B.LIC_NIT_1 != '860079174'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND EXISTS (SELECT 'X'
                            FROM ORDENES_COMPRA D,
                                 LIQUIDACIONES_COMERCIAL E
                            WHERE D.OCO_BOL_MNEMONICO = E.LIC_BOL_MNEMONICO
                              AND D.OCO_COC_CTO_MNEMONICO = E.LIC_OCO_COC_CTO_MNEMONICO
                              AND D.OCO_CONSECUTIVO = E.LIC_OCO_CONSECUTIVO
                              AND E.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                              AND E.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                              AND E.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                              AND E.LIC_CLASE_TRANSACCION = 'RF'
                              AND E.LIC_NIT_1 = '860079174'
                              AND E.LIC_NUMERO_OPERACION = B.LIC_NUMERO_OPERACION
                              AND E.LIC_TIPO_OPERACION = 'C')
              GROUP BY     CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO,
                           CCC_CLI_PER_NUM_IDEN,
                           CCC_CLI_PER_TID_CODIGO,
                           CCC_NUMERO_CUENTA,
                           PCP.PCP_CPR_MNEMONICO)
           GROUP BY  ComercialID,
                     ComercialTID,
                     ClienteID,
                     ClienteTID,
                     Cuenta,
                     Mesa
      UNION ALL
      SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OVE_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OVE_COC_CTO_MNEMONICO = B.LIC_OVE_COC_CTO_MNEMONICO
                AND A.OVE_CONSECUTIVO = B.LIC_OVE_CONSECUTIVO
                AND A.OVE_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OVE_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OVE_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'ACC'
                AND B.LIC_NIT_1 = '860079174'
                AND C.CCC_NUMERO_CUENTA = 6    -- CUENTA DE RECURSOS PROPIOS DE CORREDORES
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OCO_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OCO_COC_CTO_MNEMONICO = B.LIC_OCO_COC_CTO_MNEMONICO
                AND A.OCO_CONSECUTIVO = B.LIC_OCO_CONSECUTIVO
                AND A.OCO_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OCO_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OCO_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'ACC'
                AND B.LIC_NIT_1 != '860079174'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND EXISTS (SELECT 'X'
                            FROM ORDENES_VENTA D,
                                 LIQUIDACIONES_COMERCIAL E
                            WHERE D.OVE_BOL_MNEMONICO = E.LIC_BOL_MNEMONICO
                              AND D.OVE_COC_CTO_MNEMONICO = E.LIC_OVE_COC_CTO_MNEMONICO
                              AND D.OVE_CONSECUTIVO = E.LIC_OVE_CONSECUTIVO
                              AND E.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                              AND E.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                              AND E.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                              AND E.LIC_CLASE_TRANSACCION = 'ACC'
                              AND E.LIC_NIT_1 = '860079174'
                              AND E.LIC_NUMERO_OPERACION = B.LIC_NUMERO_OPERACION
                              AND E.LIC_TIPO_OPERACION = 'V')
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_COMPRA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OCO_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OCO_COC_CTO_MNEMONICO = B.LIC_OCO_COC_CTO_MNEMONICO
                AND A.OCO_CONSECUTIVO = B.LIC_OCO_CONSECUTIVO
                AND A.OCO_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OCO_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OCO_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'ACC'
                AND B.LIC_NIT_1 = '860079174'
                AND C.CCC_NUMERO_CUENTA = 6    -- CUENTA DE RECURSOS PROPIOS DE CORREDORES
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO
              UNION ALL
              SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     COUNT(*) TOTAL
              FROM ORDENES_VENTA A,
                   LIQUIDACIONES_COMERCIAL B,
                   CUENTAS_CLIENTE_CORREDORES C,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE A.OVE_BOL_MNEMONICO = B.LIC_BOL_MNEMONICO
                AND A.OVE_COC_CTO_MNEMONICO = B.LIC_OVE_COC_CTO_MNEMONICO
                AND A.OVE_CONSECUTIVO = B.LIC_OVE_CONSECUTIVO
                AND A.OVE_CCC_CLI_PER_NUM_IDEN = C.CCC_CLI_PER_NUM_IDEN
                AND A.OVE_CCC_cLI_PER_TID_CODIGO = C.CCC_CLI_PER_TID_CODIGO
                AND A.OVE_CCC_NUMERO_CUENTA = C.CCC_NUMERO_CUENTA
                AND B.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                AND B.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                AND B.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                AND B.LIC_CLASE_TRANSACCION = 'ACC'
                AND B.LIC_NIT_1 != '860079174'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND EXISTS (SELECT 'X'
                            FROM ORDENES_COMPRA D,
                                 LIQUIDACIONES_COMERCIAL E
                            WHERE D.OCO_BOL_MNEMONICO = E.LIC_BOL_MNEMONICO
                              AND D.OCO_COC_CTO_MNEMONICO = E.LIC_OCO_COC_CTO_MNEMONICO
                              AND D.OCO_CONSECUTIVO = E.LIC_OCO_CONSECUTIVO
                              AND E.LIC_ELI_MNEMONICO IN  ('APL','OPL','OPA')
                              AND E.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
                              AND E.LIC_FECHA_OPERACION <  TRUNC(P_FECHA) + 1
                              AND E.LIC_CLASE_TRANSACCION = 'ACC'
                              AND E.LIC_NIT_1 = '860079174'
                              AND E.LIC_NUMERO_OPERACION = B.LIC_NUMERO_OPERACION
                              AND E.LIC_TIPO_OPERACION = 'C')
              GROUP BY     CCC_PER_NUM_IDEN,
                           CCC_PER_TID_CODIGO,
                           CCC_CLI_PER_NUM_IDEN,
                           CCC_CLI_PER_TID_CODIGO,
                           CCC_NUMERO_CUENTA,
                           PCP.PCP_CPR_MNEMONICO)
           GROUP BY  ComercialID,
                     ComercialTID,
                     ClienteID,
                     ClienteTID,
                     Cuenta,
                     Mesa;

END LIQUIDACIONES_POSICION_PROPIA;

/**  Procedimiento para traer los costos AMV
**/
PROCEDURE COSTOS_AMV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(1 * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(1 * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
               WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                 AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                 AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                 AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                 AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                 AND OPC_FECHA >= TRUNC(P_FECHA)
                 AND OPC_FECHA < TRUNC(P_FECHA) + 1
                 AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                 AND OPC_PRO_MNEMONICO = 'ACC'
                 AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                 AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                 AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                 AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                 AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                 AND LIC_TIPO_OPERACION = 'V'
               GROUP BY DOP_PER_NUM_IDEN,
                        DOP_PER_TID_CODIGO,
                        OVE_CCC_CLI_PER_NUM_IDEN,
                        OVE_CCC_CLI_PER_TID_CODIGO,
                        OVE_CCC_NUMERO_CUENTA,
                        PCP.PCP_CPR_MNEMONICO,
                        DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(1 * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(1 * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
               WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                 AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                 AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                 AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                 AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                 AND OPC_FECHA >= TRUNC(P_FECHA)
                 AND OPC_FECHA < TRUNC(P_FECHA) + 1
                 AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                 AND OPC_PRO_MNEMONICO = 'ACC'
                 AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                 AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                 AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                 AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                 AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                 AND LIC_TIPO_OPERACION = 'C'
               GROUP BY DOP_PER_NUM_IDEN,
                        DOP_PER_TID_CODIGO,
                        OCO_CCC_CLI_PER_NUM_IDEN,
                        OCO_CCC_CLI_PER_TID_CODIGO,
                        OCO_CCC_NUMERO_CUENTA,
                        PCP.PCP_CPR_MNEMONICO,
                        DOP_PARTICIPACION_REAL)
        GROUP BY  ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa
        UNION ALL
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(1 * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(1 * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
               WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                 AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                 AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                 AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                 AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                 AND OPC_FECHA >= TRUNC(P_FECHA)
                 AND OPC_FECHA < TRUNC(P_FECHA) + 1
                 AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                 AND OPC_PRO_MNEMONICO = 'RF'
                 AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                 AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                 AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                 AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                 AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                 AND LIC_TIPO_OPERACION = 'V'
               GROUP BY DOP_PER_NUM_IDEN,
                        DOP_PER_TID_CODIGO,
                        OVE_CCC_CLI_PER_NUM_IDEN,
                        OVE_CCC_CLI_PER_TID_CODIGO,
                        OVE_CCC_NUMERO_CUENTA,
                        PCP.PCP_CPR_MNEMONICO,
                        DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(1 * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(1 * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
               WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                 AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                 AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                 AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                 AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                 AND OPC_FECHA >= TRUNC(P_FECHA)
                 AND OPC_FECHA < TRUNC(P_FECHA) + 1
                 AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                 AND OPC_PRO_MNEMONICO = 'RF'
                 AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                 AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                 AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                 AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                 AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                 AND LIC_TIPO_OPERACION = 'C'
               GROUP BY DOP_PER_NUM_IDEN,
                        DOP_PER_TID_CODIGO,
                        OCO_CCC_CLI_PER_NUM_IDEN,
                        OCO_CCC_CLI_PER_TID_CODIGO,
                        OCO_CCC_NUMERO_CUENTA,
                        PCP.PCP_CPR_MNEMONICO,
                        DOP_PARTICIPACION_REAL)
        GROUP BY  ComercialID,
                  ComercialTID,
                  ClienteID,
                  ClienteTID,
                  Cuenta,
                  Mesa;

END COSTOS_AMV;

/**  Procedimiento para traer los costos deceval administracion
**/
PROCEDURE COSTOS_DECEVAL_ADMINISTRACION(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     MCC_CCC_CLI_PER_NUM_IDEN ClienteID,
                     MCC_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     MCC_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    MOVIMIENTOS_CUENTA_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_MCC_CONSECUTIVO = MCC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND OPC_PRO_MNEMONICO = 'ADVAL'
                AND CPD_CSP_COS_MNEMONICO ='DAAV'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND (EXISTS (SELECT 'X'
                             FROM MOVIMIENTOS_CUENTA_CORREDORES,
                                  ESPECIES_NACIONALES
                             WHERE MCC_CONSECUTIVO = OPC_MCC_CONSECUTIVO
                             AND   MCC_ENA_MNEMONICO IS NOT NULL
                             AND   MCC_ENA_MNEMONICO = ENA_MNEMONICO
                             AND   ENA_TIPO_ESPECIE = 'V')
                     OR EXISTS (SELECT 'X'
                                FROM MOVIMIENTOS_CUENTA_CORREDORES,
                                     TITULOS
                                WHERE MCC_CONSECUTIVO = OPC_MCC_CONSECUTIVO
                                AND   MCC_TLO_CODIGO = TLO_CODIGO
                                AND   TLO_TYPE = 'TVC'))
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       MCC_CCC_CLI_PER_NUM_IDEN,
                       MCC_CCC_CLI_PER_TID_CODIGO,
                       MCC_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa
        UNION ALL
        /*RF*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     MCC_CCC_CLI_PER_NUM_IDEN ClienteID,
                     MCC_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     MCC_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    MOVIMIENTOS_CUENTA_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_MCC_CONSECUTIVO = MCC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND OPC_PRO_MNEMONICO = 'ADVAL'
                AND CPD_CSP_COS_MNEMONICO ='DAAV'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND (EXISTS (SELECT 'X'
                             FROM MOVIMIENTOS_CUENTA_CORREDORES,
                                  ESPECIES_NACIONALES
                             WHERE MCC_CONSECUTIVO = OPC_MCC_CONSECUTIVO
                             AND   MCC_ENA_MNEMONICO IS NOT NULL
                             AND   MCC_ENA_MNEMONICO = ENA_MNEMONICO
                             AND   ENA_TIPO_ESPECIE = 'F')
                     OR EXISTS (SELECT 'X'
                                FROM MOVIMIENTOS_CUENTA_CORREDORES,
                                     TITULOS
                                WHERE MCC_CONSECUTIVO = OPC_CONSECUTIVO
                                AND   MCC_TLO_CODIGO = TLO_CODIGO
                                AND   TLO_TYPE = 'TFC'))
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       MCC_CCC_CLI_PER_NUM_IDEN,
                       MCC_CCC_CLI_PER_TID_CODIGO,
                       MCC_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END COSTOS_DECEVAL_ADMINISTRACION;

/**  Procedimiento para traer los costos deceval administracion
**/
PROCEDURE COSTOS_DECEVAL_CUSTODIA(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     SUM(CSD_COSTO) TOTAL
              FROM  SALDOS_DIARIOS,
                    COSTOS_SALDOS_DIARIOS,
                    CUENTAS_CLIENTE_CORREDORES,
                    PERSONAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
             WHERE SAD_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
               AND SAD_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
               AND SAD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
               AND CCC_PER_NUM_IDEN = PER_NUM_IDEN
               AND CCC_PER_TID_CODIGO = PER_TID_CODIGO
               AND SAD_CONSECUTIVO = CSD_SAD_CONSECUTIVO
               AND SAD_FECHA >= TRUNC(P_FECHA)
               AND SAD_FECHA <  TRUNC(P_FECHA) + 1
               AND CSD_CSP_COS_MNEMONICO = 'DACUS'
               AND SAD_PRO_MNEMONICO = 'SDARV'
               AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
               AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY CCC_PER_NUM_IDEN,
                      CCC_PER_TID_CODIGO,
                      CCC_CLI_PER_NUM_IDEN,
                      CCC_CLI_PER_TID_CODIGO,
                      CCC_NUMERO_CUENTA,
                      PCP.PCP_CPR_MNEMONICO)
          GROUP BY  ComercialID,
                    ComercialTID,
                    ClienteID,
                    ClienteTID,
                    Cuenta,
                    Mesa
          UNION ALL
          /*RF*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     SUM(CSD_COSTO) TOTAL
              FROM  SALDOS_DIARIOS,
                    COSTOS_SALDOS_DIARIOS,
                    CUENTAS_CLIENTE_CORREDORES,
                    PERSONAS,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
             WHERE SAD_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
               AND SAD_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
               AND SAD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
               AND CCC_PER_NUM_IDEN = PER_NUM_IDEN
               AND CCC_PER_TID_CODIGO = PER_TID_CODIGO
               AND SAD_CONSECUTIVO = CSD_SAD_CONSECUTIVO
               AND SAD_FECHA >= TRUNC(P_FECHA)
               AND SAD_FECHA <  TRUNC(P_FECHA) + 1
               AND CSD_CSP_COS_MNEMONICO = 'DACUS'
               AND SAD_PRO_MNEMONICO = 'SDARF'
               AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
               AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
             GROUP BY CCC_PER_NUM_IDEN,
                      CCC_PER_TID_CODIGO,
                      CCC_CLI_PER_NUM_IDEN,
                      CCC_CLI_PER_TID_CODIGO,
                      CCC_NUMERO_CUENTA,
                      PCP.PCP_CPR_MNEMONICO)
          GROUP BY  ComercialID,
                    ComercialTID,
                    ClienteID,
                    ClienteTID,
                    Cuenta,
                    Mesa;

END COSTOS_DECEVAL_CUSTODIA;

/**  Procedimiento para traer los costos deceval operacion
**/
PROCEDURE COSTOS_DECEVAL_OPERACION(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
             WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
               AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
               AND OPC_FECHA >= TRUNC(P_FECHA)
               AND OPC_FECHA < TRUNC(P_FECHA) + 1
               AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
               AND CPD_CSP_COS_MNEMONICO = 'DAOP'
               AND OPC_PRO_MNEMONICO = 'ACC'
               AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
               AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
               AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
               AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
               AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
               AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
               AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
               AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
               AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
               AND LIC_TIPO_OPERACION = 'V'
             GROUP BY DOP_PER_NUM_IDEN,
                      DOP_PER_TID_CODIGO,
                      OVE_CCC_CLI_PER_NUM_IDEN,
                      OVE_CCC_CLI_PER_TID_CODIGO,
                      OVE_CCC_NUMERO_CUENTA,
                      PCP.PCP_CPR_MNEMONICO,
                      DOP_PARTICIPACION_REAL
             UNION ALL
             SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
             WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
               AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
               AND OPC_FECHA >= TRUNC(P_FECHA)
               AND OPC_FECHA < TRUNC(P_FECHA) + 1
               AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
               AND CPD_CSP_COS_MNEMONICO = 'DAOP'
               AND OPC_PRO_MNEMONICO = 'ACC'
               AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
               AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
               AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
               AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
               AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
               AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
               AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
               AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
               AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
               AND LIC_TIPO_OPERACION = 'C'
             GROUP BY DOP_PER_NUM_IDEN,
                      DOP_PER_TID_CODIGO,
                      OCO_CCC_CLI_PER_NUM_IDEN,
                      OCO_CCC_CLI_PER_TID_CODIGO,
                      OCO_CCC_NUMERO_CUENTA,
                      PCP.PCP_CPR_MNEMONICO,
                      DOP_PARTICIPACION_REAL)
        GROUP BY  ComercialID,
              ComercialTID,
              ClienteID,
              ClienteTID,
              Cuenta,
              Mesa
        UNION ALL
        /*RF*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
             WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
               AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
               AND OPC_FECHA >= TRUNC(P_FECHA)
               AND OPC_FECHA < TRUNC(P_FECHA) + 1
               AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
               AND CPD_CSP_COS_MNEMONICO = 'DAOP'
               AND OPC_PRO_MNEMONICO = 'RF'
               AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
               AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
               AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
               AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
               AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
               AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
               AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
               AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
               AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
               AND LIC_TIPO_OPERACION = 'V'
             GROUP BY DOP_PER_NUM_IDEN,
                      DOP_PER_TID_CODIGO,
                      OVE_CCC_CLI_PER_NUM_IDEN,
                      OVE_CCC_CLI_PER_TID_CODIGO,
                      OVE_CCC_NUMERO_CUENTA,
                      PCP.PCP_CPR_MNEMONICO,
                      DOP_PARTICIPACION_REAL
             UNION ALL
             SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
             WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
               AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
               AND OPC_FECHA >= TRUNC(P_FECHA)
               AND OPC_FECHA < TRUNC(P_FECHA) + 1
               AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
               AND CPD_CSP_COS_MNEMONICO = 'DAOP'
               AND OPC_PRO_MNEMONICO = 'RF'
               AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
               AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
               AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
               AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
               AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
               AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
               AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
               AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
               AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
               AND LIC_TIPO_OPERACION = 'C'
             GROUP BY DOP_PER_NUM_IDEN,
                      DOP_PER_TID_CODIGO,
                      OCO_CCC_CLI_PER_NUM_IDEN,
                      OCO_CCC_CLI_PER_TID_CODIGO,
                      OCO_CCC_NUMERO_CUENTA,
                      PCP.PCP_CPR_MNEMONICO,
                      DOP_PARTICIPACION_REAL)
        GROUP BY  ComercialID,
              ComercialTID,
              ClienteID,
              ClienteTID,
              Cuenta,
              Mesa;

END COSTOS_DECEVAL_OPERACION;

/**  Procedimiento para traer los costos pantalla MEC
**/
PROCEDURE COSTOS_PANTALLA_MEC(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'ACC'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'ACC'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa
        UNION ALL
        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'RF'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    COSTOS_OPERACIONES_DIARIAS,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'RF'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END COSTOS_PANTALLA_MEC;

/**  Procedimiento para traer los costos fogabol
**/
PROCEDURE COSTOS_FOGABOL(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR

        /*RV*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND OPC_PRO_MNEMONICO = 'ACC'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND OPC_PRO_MNEMONICO = 'ACC'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa
        UNION ALL
        /*RF*/
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM (SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OVE_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_VENTA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND OPC_PRO_MNEMONICO = 'RF'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(LIC_VOLUMEN_FRACCION * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM  OPERACIONES_DIARIAS,
                    DISTRIBUCION_OPERACIONES,
                    LIQUIDACIONES_COMERCIAL,
                    ORDENES_COMPRA,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND OPC_PRO_MNEMONICO = 'RF'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END COSTOS_FOGABOL;

PROCEDURE CLIENTES_APT(P_FECHA DATE, io_cursor IN OUT O_CURSOR)IS
 -- CLIAPT	No Clientes APT

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT 0 ComercialID, 'CC' ComercialTID, t.fon_codigo ClienteID, c.per_tid_codigo ClienteTID, nvl(ccc_numero_cuenta, 0) Cuenta
              from fondos t, personas c, cuentas_cliente_corredores
              where t.fon_tipo = 'A'
              and t.fon_tipo_administracion = 'A'
              and T.FON_ESTADO = ('A')
              and c.per_num_iden = t.fon_codigo
              and c.per_num_iden not in ('860006648', '8600066481', '8600066482') and ccc_cli_per_num_iden  (+) = c.per_num_iden
              and ccc_cli_per_tid_codigo  (+) = c.per_tid_codigo
              and ccc_cuenta_apt  (+)='S'
              UNION ALL
              SELECT 0 ComercialID, 'CC' ComercialTID, t.fon_codigo ClienteID, c.per_tid_codigo ClienteTID, ccc_numero_cuenta Cuenta
              from fondos t, personas c, cuentas_cliente_corredores
              where t.fon_tipo = 'A'
              and t.fon_tipo_administracion = 'A'
              and T.FON_ESTADO = ('A')
              and c.per_num_iden = t.fon_codigo
              and c.per_num_iden = '860006648' and ccc_cli_per_num_iden = c.per_num_iden
              and ccc_nombre_cuenta not like '%-%'
              and ccc_cli_per_tid_codigo  = c.per_tid_codigo
              and ccc_cuenta_apt ='S'
              UNION ALL
              SELECT 0 ComercialID, 'CC' ComercialTID, t.fon_codigo ClienteID, c.per_tid_codigo ClienteTID, ccc_numero_cuenta Cuenta
              from fondos t, personas c, cuentas_cliente_corredores
              where t.fon_tipo = 'A'
              and t.fon_tipo_administracion = 'A'
              and T.FON_ESTADO = ('A')
              and c.per_num_iden = t.fon_codigo
              and c.per_num_iden = '8600066481' and ccc_cli_per_num_iden = '860006648'
              and ccc_nombre_cuenta like '%- 1%'
              and ccc_cli_per_tid_codigo = c.per_tid_codigo
              and ccc_cuenta_apt='S'
              UNION ALL
              SELECT 0 ComercialID, 'CC' ComercialTID, t.fon_codigo ClienteID, c.per_tid_codigo ClienteTID, ccc_numero_cuenta Cuenta
              from fondos t, personas c, cuentas_cliente_corredores
              where t.fon_tipo = 'A'
              and t.fon_tipo_administracion = 'A'
              and T.FON_ESTADO = ('A')
              and c.per_num_iden = t.fon_codigo
              and c.per_num_iden = '8600066482' and ccc_cli_per_num_iden = '860006648'
              and ccc_nombre_cuenta like '%- 2%'
              and ccc_cli_per_tid_codigo = c.per_tid_codigo
              and ccc_cuenta_apt='S');


END CLIENTES_APT;

PROCEDURE CLIENTES_FONDOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR)IS
 -- CLIFONDOS	No Clientes Fondos

BEGIN
   OPEN io_cursor FOR
       SELECT  ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               'N/A' pMnemonico,
               1 Factor
        FROM (SELECT 0 ComercialID, 'CC' ComercialTID, t.fon_codigo ClienteID, c.per_tid_codigo ClienteTID, 0 Cuenta
              from fondos t, personas c
              where t.fon_tipo = 'A'
              and t.fon_tipo_administracion = 'F'
              and T.FON_ESTADO = ('A')
              AND T.FON_CODIGO NOT IN ('111111')
              AND T.FON_CODIGO NOT LIKE '%-%'
              and t.fon_codigo = c.per_num_iden);

END CLIENTES_FONDOS;

PROCEDURE COSTOS_MEC_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  ( SELECT DOP_PER_NUM_IDEN ComercialID,
                       DOP_PER_TID_CODIGO ComercialTID,
                       OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                       OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                       OVE_CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_OPERACIONES,
                       COSTOS_OPERACIONES_DIARIAS,
                       LIQUIDACIONES_COMERCIAL,
                       ORDENES_VENTA,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                   AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                   AND OPC_FECHA >= TRUNC(P_FECHA)
                   AND OPC_FECHA < TRUNC(P_FECHA) + 1
                   AND OPC_FECHA < TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                   AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                   AND CPD_CSP_COS_MNEMONICO = 'MEC'
                   AND OPC_PRO_MNEMONICO = 'RF'
                   AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                   AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                   AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                   AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                   AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                   AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                   AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                   AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                   AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                       DOP_PER_TID_CODIGO ComercialTID,
                       OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                       OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                       OVE_CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_OPERACIONES,
                       COSTOS_OPERACIONES_DIARIAS,
                       LIQUIDACIONES_COMERCIAL,
                       LIQUIDACIONES_CARGOS,
                       ORDENES_VENTA,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                   AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                   AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                   AND CPD_CSP_COS_MNEMONICO = 'MEC'
                   AND OPC_PRO_MNEMONICO = 'RF'
                   AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                   AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                   AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                   AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                   AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                   AND LIC_NUMERO_OPERACION = LCR_NUMERO_OPERACION
                   AND LIC_TIPO_OPERACION = LCR_TIPO_OPERACION
                   AND LIC_BOL_MNEMONICO = LCR_BOL_MNEMONICO
                   AND LCR_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                   AND LCR_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                   AND LCR_FECHA >= TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                   AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                   AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                   AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                   AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM   OPERACIONES_DIARIAS,
                     DISTRIBUCION_OPERACIONES,
                     COSTOS_OPERACIONES_DIARIAS,
                     LIQUIDACIONES_COMERCIAL,
                     ORDENES_COMPRA,
                    (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                     FROM PERSONAS_CENTROS_PRODUCCION
                     WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND OPC_FECHA < TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'RF'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
             UNION ALL
             SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM   OPERACIONES_DIARIAS,
                     DISTRIBUCION_OPERACIONES,
                     COSTOS_OPERACIONES_DIARIAS,
                     LIQUIDACIONES_COMERCIAL,
                     LIQUIDACIONES_CARGOS,
                     ORDENES_COMPRA,
                    (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                     FROM PERSONAS_CENTROS_PRODUCCION
                     WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'RF'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_NUMERO_OPERACION = LCR_NUMERO_OPERACION
                AND LIC_TIPO_OPERACION = LCR_TIPO_OPERACION
                AND LIC_BOL_MNEMONICO = LCR_BOL_MNEMONICO
                AND LCR_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                AND LCR_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                AND LCR_FECHA >= TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END COSTOS_MEC_RF;


PROCEDURE COSTOS_MEC_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  ( SELECT DOP_PER_NUM_IDEN ComercialID,
                       DOP_PER_TID_CODIGO ComercialTID,
                       OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                       OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                       OVE_CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_OPERACIONES,
                       COSTOS_OPERACIONES_DIARIAS,
                       LIQUIDACIONES_COMERCIAL,
                       ORDENES_VENTA,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                   AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                   AND OPC_FECHA >= TRUNC(P_FECHA)
                   AND OPC_FECHA < TRUNC(P_FECHA) + 1
                   AND OPC_FECHA < TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                   AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                   AND CPD_CSP_COS_MNEMONICO = 'MEC'
                   AND OPC_PRO_MNEMONICO = 'ACC'
                   AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                   AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                   AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                   AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                   AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                   AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                   AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                   AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                   AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
                UNION ALL
                SELECT DOP_PER_NUM_IDEN ComercialID,
                       DOP_PER_TID_CODIGO ComercialTID,
                       OVE_CCC_CLI_PER_NUM_IDEN ClienteID,
                       OVE_CCC_CLI_PER_TID_CODIGO ClienteTID,
                       OVE_CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_OPERACIONES,
                       COSTOS_OPERACIONES_DIARIAS,
                       LIQUIDACIONES_COMERCIAL,
                       LIQUIDACIONES_CARGOS,
                       ORDENES_VENTA,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                   AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                   AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                   AND CPD_CSP_COS_MNEMONICO = 'MEC'
                   AND OPC_PRO_MNEMONICO = 'ACC'
                   AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                   AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                   AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                   AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                   AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                   AND LIC_NUMERO_OPERACION = LCR_NUMERO_OPERACION
                   AND LIC_TIPO_OPERACION = LCR_TIPO_OPERACION
                   AND LIC_BOL_MNEMONICO = LCR_BOL_MNEMONICO
                   AND LCR_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                   AND LCR_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                   AND LCR_FECHA >= TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                   AND LIC_OVE_CONSECUTIVO  = OVE_CONSECUTIVO
                   AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO
                   AND LIC_BOL_MNEMONICO = OVE_BOL_MNEMONICO
                   AND LIC_TIPO_OPERACION = 'V'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OVE_CCC_CLI_PER_NUM_IDEN,
                       OVE_CCC_CLI_PER_TID_CODIGO,
                       OVE_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM   OPERACIONES_DIARIAS,
                     DISTRIBUCION_OPERACIONES,
                     COSTOS_OPERACIONES_DIARIAS,
                     LIQUIDACIONES_COMERCIAL,
                     ORDENES_COMPRA,
                    (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                     FROM PERSONAS_CENTROS_PRODUCCION
                     WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND OPC_FECHA >= TRUNC(P_FECHA)
                AND OPC_FECHA < TRUNC(P_FECHA) + 1
                AND OPC_FECHA < TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'ACC'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL
              UNION ALL
              SELECT DOP_PER_NUM_IDEN ComercialID,
                     DOP_PER_TID_CODIGO ComercialTID,
                     OCO_CCC_CLI_PER_NUM_IDEN ClienteID,
                     OCO_CCC_CLI_PER_TID_CODIGO ClienteTID,
                     OCO_CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     CASE WHEN DOP_PARTICIPACION_REAL = 0 THEN SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(CPD_COSTO * NVL(DOP_PARTICIPACION_REAL,0)/100) END TOTAL
              FROM   OPERACIONES_DIARIAS,
                     DISTRIBUCION_OPERACIONES,
                     COSTOS_OPERACIONES_DIARIAS,
                     LIQUIDACIONES_COMERCIAL,
                     LIQUIDACIONES_CARGOS,
                     ORDENES_COMPRA,
                    (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                     FROM PERSONAS_CENTROS_PRODUCCION
                     WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE OPC_CONSECUTIVO = DOP_OPC_CONSECUTIVO
                AND OPC_CONSECUTIVO = CPD_OPC_CONSECUTIVO
                AND (DOP_PARTICIPACION_REAL > 0 OR DOP_PARTICIPACION_ESTIMADA > 0)
                AND CPD_CSP_COS_MNEMONICO = 'MEC'
                AND OPC_PRO_MNEMONICO = 'ACC'
                AND DOP_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND DOP_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND OPC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                AND OPC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                AND OPC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                AND OPC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                AND LIC_NUMERO_OPERACION = LCR_NUMERO_OPERACION
                AND LIC_TIPO_OPERACION = LCR_TIPO_OPERACION
                AND LIC_BOL_MNEMONICO = LCR_BOL_MNEMONICO
                AND LCR_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
                AND LCR_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA) + 1
                AND LCR_FECHA >= TO_DATE('13-08-2012','DD-MM-YYYY')  --FECHA EN QUE LA BVC REPORTA LOS COSTOS POR FECHA DE CUMPLIMIENTO
                AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO
                AND LIC_OCO_COC_CTO_MNEMONICO = OCO_COC_CTO_MNEMONICO
                AND LIC_BOL_MNEMONICO = OCO_BOL_MNEMONICO
                AND LIC_TIPO_OPERACION = 'C'
              GROUP BY DOP_PER_NUM_IDEN,
                       DOP_PER_TID_CODIGO,
                       OCO_CCC_CLI_PER_NUM_IDEN,
                       OCO_CCC_CLI_PER_TID_CODIGO,
                       OCO_CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DOP_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END COSTOS_MEC_RV;

PROCEDURE REPLICAR_COSTOS_FONDOS(P_MES NUMBER, P_ANO NUMBER, P_DESCRIPCION VARCHAR2, P_VALOR NUMBER,
                                    P_USUARIO_CREACION VARCHAR2, P_TERMINAL_CREACION VARCHAR2,
                                    P_FECHA_CREACION DATE, P_USUARIO_MODIFICACION VARCHAR2,
                                    P_TERMINAL_MODIFICACION VARCHAR2, P_FECHA_MODIFICACION DATE,
                                    P_CODIGO_PRODUCTO VARCHAR2) IS

CURSOR C_PRODUCTO IS
      select FON_NPR_PRO_MNEMONICO
      from   FONDOS
      where  FON_CODIGO = P_CODIGO_PRODUCTO;
      PRODUCTO VARCHAR2(6);

BEGIN

   OPEN C_PRODUCTO;
   FETCH C_PRODUCTO INTO PRODUCTO;
   IF C_PRODUCTO%NOTFOUND THEN
      PRODUCTO := '';
   END IF;
   CLOSE C_PRODUCTO;

   DELETE FROM COSTOS_FONDOS
   WHERE CTF_ANO = P_ANO AND CTF_MES = P_MES AND CTF_FON_CODIGO = P_CODIGO_PRODUCTO
   AND CTF_PRO_MNEMONICO = PRODUCTO;

   INSERT INTO COSTOS_FONDOS (CTF_CONSECUTIVO, CTF_MES, CTF_ANO, CTF_DESCRIPCION_COSTO,
                              CTF_VALOR_COSTO, CTF_USUARIO_CREACION_A, CTF_TERMINAL_CREACION_A,
                              CTF_FECHA_CREACION, CTF_USUARIO_MODIFICACION_A, CTF_TERMINAL_MODIFICACION_A,
                              CTF_FECHA_MODIFICACION_A, CTF_PRO_MNEMONICO, CTF_FON_CODIGO)
   VALUES (CTF_SEQ.NEXTVAL, P_MES, P_ANO, P_DESCRIPCION, P_VALOR,
           P_USUARIO_CREACION, P_TERMINAL_CREACION,
           P_FECHA_CREACION, P_USUARIO_MODIFICACION,
           P_TERMINAL_MODIFICACION, P_FECHA_MODIFICACION,
           PRODUCTO, P_CODIGO_PRODUCTO);


END REPLICAR_COSTOS_FONDOS;

/**  Procedimiento para traer los aportes promedios al mes de cada cuenta cliente por cada fondo
**/
PROCEDURE APORTE_PROMEDIO_MES_FONDOS(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN

   IF TO_CHAR(P_FECHA, 'DD') = TO_CHAR(last_day(P_FECHA), 'DD') THEN
       OPEN io_cursor FOR
            SELECT ComercialID,
                   ComercialTID,
                   ClienteID,
                   ClienteTID,
                   Cuenta,
                   pMnemonico,
                   Round(SUM(SALDO)/
                   (SELECT COUNT(*)
                           FROM   saldos_diarios SADI
                           WHERE  SAD_CCC_CLI_PER_NUM_IDEN   = ClienteID
                           AND    SAD_CCC_CLI_PER_TID_CODIGO = ClienteTID
                           AND    SAD_CCC_NUMERO_CUENTA      = Cuenta
                           AND    SAD_PRO_MNEMONICO   = pMnemonico
                           AND    SAD_PER_TID_CODIGO = ComercialTID
                           AND    SAD_PER_NUM_IDEN = ComercialID
                           AND    SAD_FECHA >= to_date(('01-'||TO_CHAR(P_FECHA, 'mm')||'-'||TO_CHAR(P_FECHA, 'yyyy')),'dd-mm-yyyy')
                           AND    SAD_FECHA <  P_FECHA + 1),4) FACTOR
            FROM  (SELECT NVL(SAD_PER_TID_CODIGO, CCC_PER_TID_CODIGO) ComercialTID,
                          NVL(SAD_PER_NUM_IDEN, CCC_PER_NUM_IDEN) ComercialID,
                          SUM ( sad_saldo  * DECODE (FON_BMO_MNEMONICO, 'PESOS', 1,PROD.P_ULTIMOS_MOVIMIENTOS.P_ULTIMA_COTIZACION_MONEDA ( FON_BMO_MNEMONICO, SAD_FECHA ))) SALDO,
                          SAD_CCC_CLI_PER_NUM_IDEN ClienteID,
                          SAD_CCC_CLI_PER_TID_CODIGO ClienteTID,
                          SAD_CCC_NUMERO_CUENTA Cuenta,
                          SAD_PRO_MNEMONICO pMnemonico
                   FROM   saldos_diarios SAD, CUENTAS_CLIENTE_CORREDORES CCC, FONDOS
                   WHERE  SAD_CCC_CLI_PER_NUM_IDEN   = CCC_CLI_PER_NUM_IDEN
                   AND    SAD_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND    SAD_CCC_NUMERO_CUENTA      = CCC_NUMERO_CUENTA
                   AND    FON_TIPO                = 'A'
                   AND    FON_ESTADO              = 'A'
                   AND    FON_TIPO_ADMINISTRACION = 'F'
                   AND    FON_NPR_PRO_MNEMONICO   = SAD_PRO_MNEMONICO
                   AND    SAD_FECHA >= to_date(('01-'||TO_CHAR(P_FECHA, 'mm')||'-'||TO_CHAR(P_FECHA, 'yyyy')),'dd-mm-yyyy')
                   AND    SAD_FECHA <  P_FECHA + 1
                   GROUP BY NVL(SAD_PER_TID_CODIGO, CCC_PER_TID_CODIGO), NVL(SAD_PER_NUM_IDEN, CCC_PER_NUM_IDEN), SAD_CCC_CLI_PER_NUM_IDEN, SAD_CCC_CLI_PER_TID_CODIGO, SAD_CCC_NUMERO_CUENTA, SAD_PRO_MNEMONICO
                  HAVING COUNT(*)>0)
            GROUP BY ComercialID, ComercialTID, ClienteID, ClienteTID, Cuenta, pMnemonico;
    ELSE
        OPEN io_cursor FOR
        SELECT null ComercialID, null ComercialTID, null ClienteID, null ClienteTID, null Cuenta,
               null Mnemonico, null Factor FROM DUAL;

    END IF;
END APORTE_PROMEDIO_MES_FONDOS;


/**  Procedimiento para traer los recibos de caja transferencias sebra
**/
PROCEDURE RECIBOS_CAJA_TRANS_SEBRA(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'N/A' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  (SELECT CCC_PER_NUM_IDEN ComercialID,
                      CCC_PER_TID_CODIGO ComercialTID,
                      CCC_CLI_PER_NUM_IDEN ClienteID,
                      CCC_CLI_PER_TID_CODIGO ClienteTID,
                      CCC_NUMERO_CUENTA Cuenta,
                      PCP.PCP_CPR_MNEMONICO Mesa,
                      Count(*) Total
              FROM    RECIBOS_DE_CAJA,
                      TRANSFERENCIAS_CAJA T,
                      CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                And Rca_Ccc_Numero_Cuenta = Ccc_Numero_Cuenta
                AND RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
                AND RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO
                AND RCA_SUC_CODIGO = T.TRC_RCA_SUC_CODIGO
                AND RCA_REVERSADO = 'N'
                And Rca_Es_Cliente = 'S'
                And Rca_Fecha >= TRUNC(P_FECHA)
                And Rca_Fecha <  Trunc(P_Fecha) + 1
                AND T.TRC_TIPO = 'S'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                And Ccc_Per_Tid_Codigo = Pcp.Pcp_Per_Tid_Codigo (+)
                Group By Ccc_Per_Num_Iden,
                         Ccc_Per_Tid_Codigo,
                         Ccc_Cli_Per_Num_Iden,
                         CCC_CLI_PER_TID_CODIGO,
                         Ccc_Numero_Cuenta,
                         PCP.PCP_CPR_MNEMONICO)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END RECIBOS_CAJA_TRANS_SEBRA;


/**  Procedimiento para traer los recibos de caja transferencias bancarias
**/
PROCEDURE RECIBOS_CAJA_TRANS_BANCARIA(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'N/A' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  (SELECT CCC_PER_NUM_IDEN ComercialID,
                      CCC_PER_TID_CODIGO ComercialTID,
                      CCC_CLI_PER_NUM_IDEN ClienteID,
                      CCC_CLI_PER_TID_CODIGO ClienteTID,
                      CCC_NUMERO_CUENTA Cuenta,
                      PCP.PCP_CPR_MNEMONICO Mesa,
                      Count(*) Total
              FROM    RECIBOS_DE_CAJA,
                      TRANSFERENCIAS_CAJA T,
                      CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP
              WHERE RCA_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                And Rca_Ccc_Numero_Cuenta = Ccc_Numero_Cuenta
                AND RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
                AND RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO
                AND RCA_SUC_CODIGO = T.TRC_RCA_SUC_CODIGO
                AND RCA_REVERSADO = 'N'
                And Rca_Es_Cliente = 'S'
                And Rca_Fecha >= TRUNC(P_FECHA)
                And Rca_Fecha <  Trunc(P_Fecha) + 1
                AND T.TRC_TIPO = 'B'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                And Ccc_Per_Tid_Codigo = Pcp.Pcp_Per_Tid_Codigo (+)
                Group By Ccc_Per_Num_Iden,
                         Ccc_Per_Tid_Codigo,
                         Ccc_Cli_Per_Num_Iden,
                         CCC_CLI_PER_TID_CODIGO,
                         Ccc_Numero_Cuenta,
                         PCP.PCP_CPR_MNEMONICO)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END RECIBOS_CAJA_TRANS_BANCARIA;

/**  Procedimiento para traer los recibos de caja ACH
**/
PROCEDURE RECIBOS_CAJA_ACH(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                When Mesa = 25 Then 'PARCC' When Mesa = 29 Then 'PARAPT'
                When Mesa = 525 Then 'PIC' Else Case When Producto Like 'F%' Then 'PARCC'
                ELSE DECODE(Producto, 'ADVAL', 'PIAV', 'ACC', 'PIRV', 'RF', 'PIRF', 'DIV', 'PIDI', 'N/A') END END) pMnemonico,
               Sum(Total) Factor
        FROM  (SELECT CCC_PER_NUM_IDEN ComercialID,
                     CCC_PER_TID_CODIGO ComercialTID,
                     CCC_CLI_PER_NUM_IDEN ClienteID,
                     CCC_CLI_PER_TID_CODIGO ClienteTID,
                     CCC_NUMERO_CUENTA Cuenta,
                     PCP.PCP_CPR_MNEMONICO Mesa,
                     ODP_NPR_PRO_MNEMONICO Producto,
                     COUNT(DPA_CONSECUTIVO) TOTAL
              FROM ORDENES_DE_PAGO,
                   CUENTAS_CLIENTE_CORREDORES,
                   (SELECT  PCP_PER_NUM_IDEN,
                            PCP_PER_TID_CODIGO,
                            PCP_CPR_MNEMONICO,
                            PCP_PRINCIPAL
                    FROM PERSONAS_CENTROS_PRODUCCION
                    WHERE PCP_PRINCIPAL= 'S') PCP,
                    DETALLES_PAGOS_ACH
              WHERE ODP_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                AND ODP_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                AND ODP_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
                AND ODP_ESTADO = 'APR'
                AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
                AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA) + 1
                AND ODP_TPA_MNEMONICO = 'ACH'
                AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
                AND ODP_SUC_CODIGO = DPA_ODP_SUC_CODIGO
                AND ODP_NEG_CONSECUTIVO = DPA_ODP_NEG_CONSECUTIVO
                AND ODP_CONSECUTIVO = DPA_ODP_CONSECUTIVO
                AND DPA_REVERSADO = 'N'
             group by CCC_PER_NUM_IDEN, CCC_PER_TID_CODIGO, CCC_CLI_PER_NUM_IDEN, CCC_CLI_PER_TID_CODIGO, CCC_NUMERO_CUENTA, PCP.PCP_CPR_MNEMONICO, ODP_NPR_PRO_MNEMONICO)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa,
                 Producto;

END RECIBOS_CAJA_ACH;

PROCEDURE OPERACIONES_DIARIAS_RF(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRF' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  ( SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DIC_PARTICIPACION_REAL = 0 THEN SUM(NVL(DIC_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(NVL(DIC_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_CLIENTES,
                       CUENTAS_CLIENTE_CORREDORES,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DIC_OPC_CONSECUTIVO
                   AND OPC_FECHA >= TRUNC(P_FECHA)
                   AND OPC_FECHA < TRUNC(P_FECHA) + 1
                   AND (DIC_PARTICIPACION_REAL > 0 OR DIC_PARTICIPACION_ESTIMADA > 0)
                   AND (OPC_PRO_MNEMONICO = 'RF' OR OPC_PRO_MNEMONICO = 'PP')
                   AND ((DIC_CCC_NUMERO_CUENTA <> 0
                   AND DIC_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                   AND DIC_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND DIC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA)
                   OR  (DIC_CCC_NUMERO_CUENTA = 0
                   AND DIC_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                   AND DIC_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                            FROM  CUENTAS_CLIENTE_CORREDORES
                                            WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                                            AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO)
                   AND EXISTS (SELECT CCC_NUMERO_CUENTA
                               FROM  CUENTAS_CLIENTE_CORREDORES
                               WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                               AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO))
                   OR  (DIC_CCC_NUMERO_CUENTA = 0
                   AND CCC_CLI_PER_NUM_IDEN = '860079174'
                   AND CCC_CLI_PER_TID_CODIGO = 'NIT'
                   AND CCC_NUMERO_CUENTA = 3
                   AND NOT EXISTS (SELECT CCC_NUMERO_CUENTA
                                   FROM  CUENTAS_CLIENTE_CORREDORES
                                   WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                                   AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO)))
                   AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DIC_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END OPERACIONES_DIARIAS_RF;

PROCEDURE OPERACIONES_DIARIAS_RV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIRV' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  ( SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DIC_PARTICIPACION_REAL = 0 THEN SUM(NVL(DIC_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(NVL(DIC_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_CLIENTES,
                       CUENTAS_CLIENTE_CORREDORES,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DIC_OPC_CONSECUTIVO
                   AND OPC_FECHA >= TRUNC(P_FECHA)
                   AND OPC_FECHA < TRUNC(P_FECHA) + 1
                   AND (DIC_PARTICIPACION_REAL > 0 OR DIC_PARTICIPACION_ESTIMADA > 0)
                   AND OPC_PRO_MNEMONICO = 'ACC'
                   AND ((DIC_CCC_NUMERO_CUENTA <> 0
                   AND DIC_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                   AND DIC_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND DIC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA)
                   OR  (DIC_CCC_NUMERO_CUENTA = 0
                   AND DIC_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                   AND DIC_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                            FROM  CUENTAS_CLIENTE_CORREDORES
                                            WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                                            AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO)
                   AND EXISTS (SELECT CCC_NUMERO_CUENTA
                               FROM  CUENTAS_CLIENTE_CORREDORES
                               WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                               AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO))
                   OR  (DIC_CCC_NUMERO_CUENTA = 0
                   AND CCC_CLI_PER_NUM_IDEN = '860079174'
                   AND CCC_CLI_PER_TID_CODIGO = 'NIT'
                   AND CCC_NUMERO_CUENTA = 3
                   AND NOT EXISTS (SELECT CCC_NUMERO_CUENTA
                                   FROM  CUENTAS_CLIENTE_CORREDORES
                                   WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                                   AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO)))
                   AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DIC_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END OPERACIONES_DIARIAS_RV;

PROCEDURE OPERACIONES_DIARIAS_DIV(P_FECHA DATE, io_cursor IN OUT O_CURSOR) IS

BEGIN
   OPEN io_cursor FOR
        SELECT ComercialID,
               ComercialTID,
               ClienteID,
               ClienteTID,
               Cuenta,
               (CASE WHEN Mesa = 21 THEN 'PPPRF' WHEN Mesa = 23 THEN 'PPPDI'
                WHEN Mesa = 25 THEN 'PARCC' WHEN Mesa = 29 THEN 'PARAPT'
                WHEN Mesa = 525 THEN 'PIC' ELSE 'PIDI' END) pMnemonico,
               SUM(TOTAL) Factor
        FROM  ( SELECT CCC_PER_NUM_IDEN ComercialID,
                       CCC_PER_TID_CODIGO ComercialTID,
                       CCC_CLI_PER_NUM_IDEN ClienteID,
                       CCC_CLI_PER_TID_CODIGO ClienteTID,
                       CCC_NUMERO_CUENTA Cuenta,
                       PCP.PCP_CPR_MNEMONICO Mesa,
                       CASE WHEN DIC_PARTICIPACION_REAL = 0 THEN SUM(NVL(DIC_PARTICIPACION_ESTIMADA,0)/100) ELSE SUM(NVL(DIC_PARTICIPACION_REAL,0)/100) END TOTAL
                FROM   OPERACIONES_DIARIAS,
                       DISTRIBUCION_CLIENTES,
                       CUENTAS_CLIENTE_CORREDORES,
                       (SELECT  PCP_PER_NUM_IDEN,
                              PCP_PER_TID_CODIGO,
                              PCP_CPR_MNEMONICO,
                              PCP_PRINCIPAL
                        FROM PERSONAS_CENTROS_PRODUCCION
                        WHERE PCP_PRINCIPAL= 'S') PCP
                 WHERE OPC_CONSECUTIVO = DIC_OPC_CONSECUTIVO
                   AND OPC_FECHA >= TRUNC(P_FECHA)
                   AND OPC_FECHA < TRUNC(P_FECHA) + 1
                   AND (DIC_PARTICIPACION_REAL > 0 OR DIC_PARTICIPACION_ESTIMADA > 0)
                   AND OPC_PRO_MNEMONICO = 'DIV'
                   AND ((DIC_CCC_NUMERO_CUENTA <> 0
                   AND DIC_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                   AND DIC_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND DIC_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA)
                   OR  (DIC_CCC_NUMERO_CUENTA = 0
                   AND DIC_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                   AND DIC_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                   AND CCC_NUMERO_CUENTA = (SELECT MIN(CCC_NUMERO_CUENTA)
                                            FROM  CUENTAS_CLIENTE_CORREDORES
                                            WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                                            AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO)
                   AND EXISTS (SELECT CCC_NUMERO_CUENTA
                               FROM  CUENTAS_CLIENTE_CORREDORES
                               WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                               AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO))
                   OR  (DIC_CCC_NUMERO_CUENTA = 0
                   AND CCC_CLI_PER_NUM_IDEN = '860079174'
                   AND CCC_CLI_PER_TID_CODIGO = 'NIT'
                   AND CCC_NUMERO_CUENTA = 3
                   AND NOT EXISTS (SELECT CCC_NUMERO_CUENTA
                                   FROM  CUENTAS_CLIENTE_CORREDORES
                                   WHERE CCC_CLI_PER_NUM_IDEN = DIC_PER_NUM_IDEN
                                   AND   CCC_CLI_PER_TID_CODIGO = DIC_PER_TID_CODIGO)))
                   AND CCC_PER_NUM_IDEN = PCP.PCP_PER_NUM_IDEN (+)
                   AND CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO (+)
              GROUP BY CCC_PER_NUM_IDEN,
                       CCC_PER_TID_CODIGO,
                       CCC_CLI_PER_NUM_IDEN,
                       CCC_CLI_PER_TID_CODIGO,
                       CCC_NUMERO_CUENTA,
                       PCP.PCP_CPR_MNEMONICO,
                       DIC_PARTICIPACION_REAL)
        GROUP BY ComercialID,
                 ComercialTID,
                 ClienteID,
                 ClienteTID,
                 Cuenta,
                 Mesa;

END OPERACIONES_DIARIAS_DIV;

PROCEDURE P_DATOS_PERSONA
 (P_NUM_IDEN IN VARCHAR2
 ,P_TID_CODIGO IN VARCHAR2
 ,P_NOMBRES OUT VARCHAR2
 ,P_APELLIDO1 OUT VARCHAR2
 ,P_APELLIDO2 OUT VARCHAR2
 ,P_FECHAINGRESO OUT VARCHAR2
 ,P_SEXO OUT VARCHAR2
 ,P_ESTADOCIVIL OUT VARCHAR2
 ,P_MAIL OUT VARCHAR2
 ,P_USUARIO OUT VARCHAR2
 )
 IS
   CURSOR C_PERSONA IS
      SELECT  PER_NUM_IDEN PersonaID,
              INITCAP(PER_NOMBRE) Nombres,
              INITCAP(PER_PRIMER_APELLIDO) Apellido1,
              INITCAP(PER_SEGUNDO_APELLIDO) Apellido2,
              EXTRACT(MONTH FROM SYSDATE)||'/01/'||EXTRACT(YEAR FROM SYSDATE) AS FechaIngreso,
              DECODE(PER_SEXO,'F','FEM','M','MAS',PER_SEXO) AS Sexo,
              'SOL' AS EstadoCivil,
              PER_MAIL_CORREDOR AS Mail,
              PER_NOMBRE_USUARIO AS Usuario
      FROM    PERSONAS
      WHERE   PER_TID_CODIGO = P_TID_CODIGO
      AND     PER_NUM_IDEN = P_NUM_IDEN;
   PER1   C_PERSONA%ROWTYPE;
BEGIN
   OPEN C_PERSONA;
   FETCH C_PERSONA INTO PER1;
   IF C_PERSONA%FOUND THEN
      P_NOMBRES := PER1.Nombres;
      P_APELLIDO1 := PER1.Apellido1;
      P_APELLIDO2 := PER1.Apellido2;
      P_FECHAINGRESO := PER1.FechaIngreso;
      P_SEXO := PER1.Sexo;
      P_ESTADOCIVIL := PER1.EstadoCivil;
      P_MAIL := PER1.Mail;
      P_USUARIO := PER1.Usuario;
    ELSE
       P_NOMBRES := NULL;
      P_APELLIDO1 := NULL;
      P_APELLIDO2 := NULL;
      P_FECHAINGRESO := NULL;
      P_SEXO := NULL;
      P_ESTADOCIVIL := NULL;
      P_MAIL := NULL;
      P_USUARIO := NULL;
    END IF;
END P_DATOS_PERSONA;

PROCEDURE ASIGNACION_COSTO_CUMPLIMIENTO
  (
    P_FECHA DATE,
    io_cursor IN OUT O_CURSOR
  )

IS
  V_ValorTotalDistribucion NUMBER;
  V_CantidadTotalFraccion  NUMBER;
  V_TotalIndice            NUMBER;
  V_Diferencia             NUMBER;
  V_IDXFactor              NUMBER;
  V_valorFactor            NUMBER;
  V_CostoFijoTADM          NUMBER;
  V_Iva                    NUMBER;
  V_Gravamen               NUMBER;
  V_DiaHabil               VARCHAR2(5);
  V_PrimerDia              DATE;
  V_Fecha                  DATE;

BEGIN

  DELETE FROM TMP_ASIG_COSTO_CUMPLIMIENTO;
  COMMIT;

  INSERT INTO TMP_ASIG_COSTO_CUMPLIMIENTO(
      AÑO,
      MES,
      DIA,
      COMERCIALID,
      COMERCIALTID,
      CLIENTEID,
      CLIENTETID,
      PRODUCTOID,
      CUENTA,
      MESAID,
      FACTOR,
      INDICE_FACTOR,
      LIC_VOLUMEN_NETO_FRACCION,
      PARTICIPACION_REAL,
      TIPO_OPERACION,
      LIC_BOL_MNEMONICO,
      LIC_NUMERO_OPERACION
  )
 SELECT   EXTRACT(YEAR FROM LIC_FECHA_OPERACION) AÑO,
          EXTRACT(MONTH FROM LIC_FECHA_OPERACION) MES,
          EXTRACT(DAY FROM LIC_FECHA_OPERACION) DIA,
          NVL(DOP.DOP_PER_NUM_IDEN, OVE.OVE_PER_NUM_IDEN) ComercialID,
          NVL(DOP.DOP_PER_TID_CODIGO,OVE.OVE_PER_TID_CODIGO) ComercialTID,
          CCC.CCC_CLI_PER_NUM_IDEN ClienteID,
          CCC.CCC_CLI_PER_TID_CODIGO ClienteTID,
          PRO.PRO_CODIGO_CAP ProductoID,
          CCC.CCC_NUMERO_CUENTA Cuenta,
          CPR.CPR_MNEMONICO MesaID,
          0 AS FACTOR,
          0 AS INDICE_FACTOR,
          LIC.LIC_VOLUMEN_NETO_FRACCION,
          DOP.DOP_PARTICIPACION_REAL,
          DECODE(LIC_COD_CMSNSTA_CMPRDOR||LIC_COD_CMSNSTA_VNDDOR,'002002','CRUZADA','CONVENIDA') TIPO_OPERACION,
          LIC_BOL_MNEMONICO,
          LIC_NUMERO_OPERACION
    FROM  EMISORES EMI
          INNER JOIN ESPECIES_NACIONALES ENA
                  ON ENA.ENA_EMI_MNEMONICO = EMI.EMI_MNEMONICO
          INNER JOIN LIQUIDACIONES_COMERCIAL LIC
                  ON LIC.LIC_MNEMOTECNICO_TITULO    = ENA.ENA_MNEMONICO
          INNER JOIN ORDENES_VENTA OVE
                  ON LIC.LIC_BOL_MNEMONICO          = OVE.OVE_BOL_MNEMONICO
                 AND LIC.LIC_OVE_COC_CTO_MNEMONICO  = OVE.OVE_COC_CTO_MNEMONICO
                 AND LIC.LIC_OVE_CONSECUTIVO        = OVE.OVE_CONSECUTIVO
          INNER JOIN PRODUCTOS PRO
                ON OVE.OVE_COC_CTO_MNEMONICO  = PRO.PRO_MNEMONICO
          INNER JOIN PERSONAS PER1
                  ON OVE.OVE_PER_NUM_IDEN           = PER1.PER_NUM_IDEN
                 AND OVE.OVE_PER_TID_CODIGO         = PER1.PER_TID_CODIGO
          INNER JOIN CUENTAS_CLIENTE_CORREDORES CCC
                  ON OVE. OVE_CCC_CLI_PER_NUM_IDEN   = CCC.CCC_CLI_PER_NUM_IDEN
                 AND OVE.OVE_CCC_CLI_PER_TID_CODIGO =  CCC.CCC_CLI_PER_TID_CODIGO
                 AND OVE.OVE_CCC_NUMERO_CUENTA      =  CCC.CCC_NUMERO_CUENTA
          INNER JOIN PERSONAS_CENTROS_PRODUCCION  PCP
                  ON CCC.CCC_PER_NUM_IDEN           = PCP.PCP_PER_NUM_IDEN
                 AND CCC.CCC_PER_TID_CODIGO         = PCP.PCP_PER_TID_CODIGO
          INNER JOIN PERSONAS PER
                  ON CCC.CCC_PER_NUM_IDEN           = PER.PER_NUM_IDEN
                 AND CCC.CCC_PER_TID_CODIGO         = PER.PER_TID_CODIGO
          INNER JOIN CENTROS_PRODUCCION CPR
                  ON PCP.PCP_CPR_MNEMONICO          =  CPR.CPR_MNEMONICO
          LEFT  JOIN OPERACIONES_DIARIAS OPC
                  ON OPC.OPC_LIC_NUMERO_OPERACION    = LIC.LIC_NUMERO_OPERACION
                 AND OPC.OPC_LIC_NUMERO_FRACCION   =   LIC.LIC_NUMERO_FRACCION
                 AND OPC.OPC_LIC_TIPO_OPERACION    =   LIC.LIC_TIPO_OPERACION
                 AND OPC.OPC_LIC_BOL_MNEMONICO     =   LIC.LIC_BOL_MNEMONICO
          LEFT  JOIN DISTRIBUCION_OPERACIONES DOP
                  ON OPC.OPC_CONSECUTIVO = DOP.DOP_OPC_CONSECUTIVO
                 AND DOP.DOP_PARTICIPACION_REAL != 0
  WHERE   PCP_PRINCIPAL = 'S'
  AND     LIC_TIPO_OPERACION = 'V'
  AND     LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
  AND     LIC_FECHA_OPERACION < TRUNC(P_FECHA)+1
  AND     LIC.LIC_ELI_MNEMONICO IN ('OPL', 'OPA', 'APL')

  UNION

SELECT      EXTRACT(YEAR FROM LIC_FECHA_OPERACION) AÑO,
            EXTRACT(MONTH FROM LIC_FECHA_OPERACION) MES,
            EXTRACT(DAY FROM LIC_FECHA_OPERACION) DIA,
            NVL(DOP.DOP_PER_NUM_IDEN,OCO_PER_NUM_IDEN) ComercialID,
            NVL(DOP.DOP_PER_TID_CODIGO,OCO_PER_TID_CODIGO) ComercialTID,
            CCC. CCC_CLI_PER_NUM_IDEN ClienteID,
            CCC.CCC_CLI_PER_TID_CODIGO ClienteTID,
            PRO.PRO_CODIGO_CAP ProductoID,
            CCC.CCC_NUMERO_CUENTA Cuenta,
            CPR.CPR_MNEMONICO MesaID,
            0 AS FACTOR,
            0 INDICE_FACTOR,
            LIC.LIC_VOLUMEN_NETO_FRACCION,
            DOP.DOP.DOP_PARTICIPACION_REAL,
            DECODE(LIC_COD_CMSNSTA_CMPRDOR||LIC_COD_CMSNSTA_VNDDOR,'002002','CRUZADA','CONVENIDA') TIPO_OPERACION,
            LIC_BOL_MNEMONICO,
            LIC_NUMERO_OPERACION
    FROM    EMISORES EMI
            INNER JOIN ESPECIES_NACIONALES ENA
                    ON ENA.ENA_EMI_MNEMONICO          = EMI.EMI_MNEMONICO
            INNER JOIN LIQUIDACIONES_COMERCIAL LIC
                    ON LIC.LIC_MNEMOTECNICO_TITULO  = ENA.ENA_MNEMONICO
            INNER JOIN ORDENES_COMPRA OCO
                    ON LIC. LIC_BOL_MNEMONICO          = OCO.OCO_BOL_MNEMONICO
                   AND LIC.LIC_OCO_COC_CTO_MNEMONICO  = OCO.OCO_COC_CTO_MNEMONICO
                   AND LIC. LIC_OCO_CONSECUTIVO        = OCO.OCO_CONSECUTIVO
            INNER JOIN PRODUCTOS PRO
                  ON OCO.OCO_COC_CTO_MNEMONICO = PRO.PRO_MNEMONICO
            INNER JOIN PERSONAS PER2
                    ON OCO.OCO_PER_NUM_IDEN           = PER2.PER_NUM_IDEN
                   AND OCO.OCO_PER_TID_CODIGO         = PER2.PER_TID_CODIGO
            INNER JOIN CUENTAS_CLIENTE_CORREDORES CCC
                    ON OCO.OCO_CCC_CLI_PER_NUM_IDEN   = CCC.CCC_CLI_PER_NUM_IDEN
                   AND OCO.OCO_CCC_CLI_PER_TID_CODIGO = CCC.CCC_CLI_PER_TID_CODIGO
                   AND OCO.OCO_CCC_NUMERO_CUENTA      = CCC.CCC_NUMERO_CUENTA
            INNER JOIN PERSONAS PER
                    ON CCC.CCC_PER_NUM_IDEN           = PER.PER_NUM_IDEN
                   AND CCC.CCC_PER_TID_CODIGO         = PER.PER_TID_CODIGO
            INNER JOIN PERSONAS_CENTROS_PRODUCCION PCP
                    ON CCC.CCC_PER_NUM_IDEN           = PCP.PCP_PER_NUM_IDEN
                   AND CCC.CCC_PER_TID_CODIGO         = PCP. PCP_PER_TID_CODIGO
            INNER JOIN CENTROS_PRODUCCION CPR
                    ON PCP. PCP_CPR_MNEMONICO          = CPR.CPR_MNEMONICO
            LEFT  JOIN OPERACIONES_DIARIAS OPC
                    ON OPC.OPC_LIC_NUMERO_OPERACION    = LIC.LIC_NUMERO_OPERACION
                   AND OPC.OPC_LIC_NUMERO_FRACCION   =   LIC.LIC_NUMERO_FRACCION
                   AND OPC.OPC_LIC_TIPO_OPERACION    =   LIC.LIC_TIPO_OPERACION
                   AND OPC.OPC_LIC_BOL_MNEMONICO     =   LIC.LIC_BOL_MNEMONICO
            LEFT  JOIN DISTRIBUCION_OPERACIONES DOP
                    ON OPC.OPC_CONSECUTIVO = DOP.DOP_OPC_CONSECUTIVO
                   AND DOP.DOP_PARTICIPACION_REAL != 0
  WHERE   LIC.LIC_TIPO_OPERACION         = 'C'
  AND     PCP.PCP_PRINCIPAL              = 'S'
  AND     LIC.LIC_FECHA_OPERACION >= TRUNC(P_FECHA)
  AND     LIC.LIC_FECHA_OPERACION < TRUNC(P_FECHA) + 1
  AND     LIC.LIC_ELI_MNEMONICO IN ('OPL', 'OPA', 'APL');
  COMMIT;

  -- 2. APLICAR REGLAS DE NEGOCIO DE COSTOS FIJOS
  -- 2.1 OPERACIONES CONVENIDAS

  MERGE INTO TMP_ASIG_COSTO_CUMPLIMIENTO TMP
  USING (
          SELECT  DISTINCT COR.LIC_NUMERO_OPERACION
          FROM    (SELECT DISTINCT
                          LIC_NUMERO_OPERACION,
                          CLIENTEID,
                          CLIENTETID
                  FROM    TMP_ASIG_COSTO_CUMPLIMIENTO
                  WHERE   TIPO_OPERACION = 'CONVENIDA') COR
                  INNER JOIN TMP_ASIG_COSTO_CUMPLIMIENTO TMP
                          ON COR.LIC_NUMERO_OPERACION = TMP.LIC_NUMERO_OPERACION
                         AND COR.CLIENTEID = TMP.CLIENTEID
                         AND COR.CLIENTETID = TMP.CLIENTETID
        ) UPD
  ON    (      TMP.LIC_NUMERO_OPERACION = UPD.LIC_NUMERO_OPERACION
         AND   TMP.TIPO_OPERACION = 'CONVENIDA'
        )
  WHEN MATCHED THEN
  UPDATE SET TMP.INDICE_FACTOR = (200*TMP.PARTICIPACION_REAL)/100 ;
  COMMIT;

  -- 2.2 OPERACIONES CRUZADAS MESA ACCIONES BOGOTA

  MERGE INTO TMP_ASIG_COSTO_CUMPLIMIENTO TMP
  USING (
  SELECT  DISTINCT
          CLI.CLI_PER_TID_CODIGO,
          CLI.CLI_PER_NUM_IDEN
  FROM    CLIENTES CLI
          INNER JOIN TMP_ASIG_COSTO_CUMPLIMIENTO TAC
                  ON TAC.CLIENTETID = CLI.CLI_PER_TID_CODIGO
                 AND TAC.CLIENTEID = CLI.CLI_PER_NUM_IDEN
                 AND CLI_ADM_PORTAFOLIO_DCVAL = 'N'
                 AND CLI_ADM_PORTAFOLIO_DCV = 'N'
        ) UPD
  ON    (      TMP.CLIENTETID = UPD.CLI_PER_TID_CODIGO
         AND   TMP.CLIENTEID = UPD.CLI_PER_NUM_IDEN
         AND   TIPO_OPERACION = 'CRUZADA'
         AND   MESAID = '26'
         AND   LIC_BOL_MNEMONICO = 'COL'
        )
  WHEN MATCHED THEN
  UPDATE SET TMP.INDICE_FACTOR = (200*TMP.PARTICIPACION_REAL)/100 ;
  COMMIT;


  -- 2.3 OPERACIONES CRUZADAS MESA INSTITUCIONAL
  MERGE INTO TMP_ASIG_COSTO_CUMPLIMIENTO TMP
  USING (
  SELECT  DISTINCT
          TAC.LIC_NUMERO_OPERACION,
          CLI.CLI_PER_TID_CODIGO,
          CLI.CLI_PER_NUM_IDEN
  FROM    CLIENTES CLI
          INNER JOIN TMP_ASIG_COSTO_CUMPLIMIENTO TAC
                  ON TAC.CLIENTETID = CLI.CLI_PER_TID_CODIGO
                 AND TAC.CLIENTEID = CLI.CLI_PER_NUM_IDEN
                 AND CLI_ADM_PORTAFOLIO_DCVAL = 'N'
                 AND CLI_ADM_PORTAFOLIO_DCV = 'N'
        ) UPD
  ON    (      TMP.CLIENTETID = UPD.CLI_PER_TID_CODIGO
         AND   TMP.CLIENTEID = UPD.CLI_PER_NUM_IDEN
         AND   TMP.LIC_NUMERO_OPERACION = UPD.LIC_NUMERO_OPERACION
         AND   MESAID = '3'
         AND   TIPO_OPERACION = 'CRUZADA'
         AND   LIC_BOL_MNEMONICO = 'MEC'
        )
  WHEN MATCHED THEN
  UPDATE SET TMP.INDICE_FACTOR = (200*TMP.PARTICIPACION_REAL)/100 ;
  COMMIT;

  -- 2.4 OPERACIONES CRUZADAS MEC CLIENTES QUE OPERAN CON COASA

  MERGE INTO TMP_ASIG_COSTO_CUMPLIMIENTO TMP
  USING (
          SELECT  DISTINCT COR.LIC_NUMERO_OPERACION
          FROM    (SELECT DISTINCT
                          LIC_NUMERO_OPERACION,
                          CLIENTEID,
                          CLIENTETID
                  FROM    TMP_ASIG_COSTO_CUMPLIMIENTO
                  WHERE   TIPO_OPERACION = 'CRUZADA'
                  AND     LIC_BOL_MNEMONICO = 'MEC') COR
                  INNER JOIN TMP_ASIG_COSTO_CUMPLIMIENTO TMP
                          ON COR.LIC_NUMERO_OPERACION = TMP.LIC_NUMERO_OPERACION
                         AND COR.CLIENTEID = TMP.CLIENTEID
                         AND COR.CLIENTETID = TMP.CLIENTETID
        ) UPD
  ON    (      TMP.LIC_NUMERO_OPERACION = UPD.LIC_NUMERO_OPERACION
         AND   TMP.TIPO_OPERACION = 'CRUZADA'
         AND   TMP.CLIENTEID != '860079174'
         AND   TMP.LIC_BOL_MNEMONICO = 'MEC'
        )
  WHEN MATCHED THEN
  UPDATE SET TMP.INDICE_FACTOR = (200*TMP.PARTICIPACION_REAL)/100 ;
  COMMIT;


  -- 2.5 OPERACIONES COBRO DE CLIENTES CON JEFE DE MESA
  MERGE INTO TMP_ASIG_COSTO_CUMPLIMIENTO TMP
  USING (
          SELECT  DISTINCT
                  TAC.LIC_NUMERO_OPERACION,
                  CLIENTETID CLI_PER_TID_CODIGO,
                  CLIENTEID CLI_PER_NUM_IDEN
          FROM    TMP_ASIG_COSTO_CUMPLIMIENTO TAC
          WHERE   TAC.INDICE_FACTOR = 0
        ) UPD
  ON    (      TMP.CLIENTETID = UPD.CLI_PER_TID_CODIGO
         AND   TMP.CLIENTEID = UPD.CLI_PER_NUM_IDEN
         AND   TMP.LIC_NUMERO_OPERACION = UPD.LIC_NUMERO_OPERACION
         AND   TIPO_OPERACION = 'CRUZADA'
         AND   LIC_BOL_MNEMONICO = 'MEC'
         AND   TMP.CLIENTEID = '860079174'
         AND   MESAID IN ('3','21')
        /* AND   TMP.COMERCIALID IN ('52150370', '51975292') */-- SE DEBE PARAMETRIZAR
        )
  WHEN MATCHED THEN
  UPDATE SET TMP.INDICE_FACTOR = (200*TMP.PARTICIPACION_REAL)/100 ;
  COMMIT;


  -- 3. CALCULAR VALOR TOTAL DE DISTRIBUCI¿N
  SELECT
    (SELECT  ABS(SUM(MCB.MCB_MONTO)) AS MONTO
     FROM  MOVIMIENTOS_CUENTAS_BANCARIAS MCB
           INNER JOIN TIPOS_MOVIMIENTOS_BANCOS TMB
                   ON MCB.MCB_TMB_MNEMONICO   = TMB.TMB_MNEMONICO
    WHERE  TRUNC(MCB_FECHA)    >= TRUNC(P_FECHA)
    AND    TRUNC(MCB_FECHA)       < TRUNC(P_FECHA)+1
    AND    MCB_TMB_MNEMONICO     IN ('PCOM','RCOM','DBSC','DSSS')
    AND    MCB_CBA_BAN_CODIGO     = '0' --PARAMETRO
    AND    MCB_CBA_NUMERO_CUENTA IN ('62255500','62250063')
    )
  INTO V_ValorTotalDistribucion
  FROM DUAL;


    -- 3.1 SE CALCULA TARIFA ADMINISTRACION DE CUENTAS
    SELECT
      (SELECT CON_VALOR
       FROM CONSTANTES
       WHERE CON_MNEMONICO = 'CFB'
      )
    INTO V_CostoFijoTADM
    FROM DUAL;

   -- 3.2 SE CALCULA EL IVA
   SELECT
      (SELECT 1+CON_VALOR
       FROM   CONSTANTES
       WHERE  CON_MNEMONICO = 'IVA'
      )
    INTO V_Iva
    FROM DUAL;


    -- 3.3 SE CALCULA GRAVAMEN, SE SUMA VALOR IVA
    SELECT
    (
      SELECT  1+CON_VALOR
      FROM    CONSTANTES
      WHERE   CON_MNEMONICO = 'GMF'
    )
    INTO V_Gravamen
    FROM DUAL;

    -- ASIGNO VALOR P_FECHA(PARAMETRO ENTRADA) A VARIABLE V_FECHA
    V_FECHA:= P_FECHA;

    -- 3.4 Calculo Primer DIA del Mes
    SELECT TRUNC(V_FECHA,'MM') INTO V_PRIMERDIA  FROM DUAL;

    -- 3.5 SE VERIFICA PRIMER DIA HABIL DEL MES
    SELECT P_TOOLS.FN_ES_DIA_HABIL (V_PrimerDia) INTO V_DiaHabil FROM DUAL;


    -- CICLO PARA VALIDAR PRIMER DIA HABIL DEL MES
    WHILE V_DiaHabil ='N'
    LOOP
        V_PrimerDia := TRUNC(V_PrimerDia)+1;
        SELECT P_TOOLS.FN_ES_DIA_HABIL (V_PrimerDia) INTO V_DiaHabil FROM DUAL;
    END LOOP;


    -- VERIFICA SI EL DIA ES HABIL Y LA FECHA CORRESPONDE AL PRIMER DIA HABIL DEL MES
    --3.4 SE CALCULA VALOR TOTAL DISTRIBUCION , RESTANDO LA TARIFA DE ADMINISTRACION DE CUENTAS
    --IF TRUNC(V_FECHA) = TO_DATE('02-11-2017','DD-MM-YYYY') THEN
    IF TRUNC(V_FECHA) = TRUNC(V_PRIMERDIA) THEN
       V_ValorTotalDistribucion:= V_ValorTotalDistribucion - V_CostoFijoTADM;
    END IF;

    -- 3.5 SE CALCULAN IMPUESTOS
    V_ValorTotalDistribucion:= (V_ValorTotalDistribucion / V_Gravamen);

    V_ValorTotalDistribucion:= (V_ValorTotalDistribucion / V_Iva);

    DBMS_OUTPUT.PUT_LINE('VALOR DISTRIBUCION '|| V_ValorTotalDistribucion);

    SELECT  SUM(LIC_VOLUMEN_NETO_FRACCION *( DECODE(PARTICIPACION_REAL,NULL,1,PARTICIPACION_REAL) /100))
    INTO    V_CantidadTotalFraccion
    FROM    TMP_ASIG_COSTO_CUMPLIMIENTO;

    -- 4. AGREGACION DEL INDICE FACTOR
    SELECT  SUM(INDICE_FACTOR)
    INTO    V_TotalIndice
    FROM    TMP_ASIG_COSTO_CUMPLIMIENTO;


    -- 5. CALCULO DE DIFERENCIA DE TOTAL DE DISTRIBUCION MENOS TOTAL FRACCION
    V_Diferencia := V_ValorTotalDistribucion - V_TotalIndice ;

    -- 6. CALUCLO DE INDICE FACTOR
    V_IDXFactor := V_Diferencia / V_CantidadTotalFraccion;

    -- 7. CALCULO DE FACTOR DE DISTRIBUCION
    UPDATE  TMP_ASIG_COSTO_CUMPLIMIENTO
    SET     FACTOR = ((LIC_VOLUMEN_NETO_FRACCION *( DECODE(PARTICIPACION_REAL,NULL,1,PARTICIPACION_REAL) /100)) *V_IDXFactor) + INDICE_FACTOR;
    COMMIT;

    -- 8. SELECCION DE DATOS DE SALIDA DEL CURSOR
    OPEN io_cursor FOR
      SELECT  AÑO,
              MES,
              DIA,
              ComercialID,
              ComercialTID,
              ClienteID,
              ClienteTID,
              ProductoID,
              Cuenta,
              NULL MesaID,
              LIC_NUMERO_OPERACION Operacion,
              LIC_VOLUMEN_NETO_FRACCION MontoOrden,
              0 BancoID,
              NULL pMnemonico,
              NVL(Factor,0) Factor
      FROM    TMP_ASIG_COSTO_CUMPLIMIENTO;

END ASIGNACION_COSTO_CUMPLIMIENTO;


PROCEDURE ASIGNACION_COSTO_PAGOS_BANC(
    P_FECHA DATE,
    io_cursor IN OUT O_CURSOR)
IS
  V_valorFactor NUMBER;
BEGIN
-- 1. SELECCION DE DATOS DE SALIDA DEL CURSOR
OPEN io_cursor FOR
WITH  REGISTROS_CHEQUES AS (
SELECT  ODP.ODP_SUC_CODIGO SucursalID,
        NVL(PRO.PRO_CODIGO_CAP,17) ProductoID,
        PCP.PCP_CPR_MNEMONICO MesaID,
        DECODE(ODP.ODP_ES_CLIENTE,'S',ODP.ODP_CCC_CLI_PER_NUM_IDEN,ODP.ODP_PER_NUM_IDEN) ClienteID ,
        CCC.CCC_PER_NUM_IDEN ComercialID,
        ODP.ODP_CCC_NUMERO_CUENTA Cuenta,
        NULL OrigenNegocioID,
        EXTRACT(YEAR FROM CEG.CEG_FECHA) Año,
        EXTRACT(MONTH FROM CEG.CEG_FECHA) Mes,
        EXTRACT(DAY FROM CEG.CEG_FECHA) Dia,
        SYSDATE FechaEjecucion,
        NULL Ip,
        SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
        DECODE(ODP.ODP_ES_CLIENTE, 'S', ODP.ODP_CCC_CLI_PER_TID_CODIGO, ODP.ODP_PER_TID_CODIGO) ClienteTID,
        CCC.CCC_PER_TID_CODIGO ComercialTID,
        0 AS Factor,
        NULL AS pMnemonico,
        CEG.CEG_CBA_BAN_CODIGO AS BancoID, -- ODP.ODP_BAN_CODIGO AS BancoID,
        CASE WHEN ODP.ODP_BAN_CODIGO = CEG.CEG_CBA_BAN_CODIGO THEN 'TRB' ELSE ODP.ODP_TPA_MNEMONICO END AS Operacion,
        (ODP.ODP_MONTO_ORDEN * DECODE(DOP.DOP_PARTICIPACION_REAL,NULL,100,DOP.DOP_PARTICIPACION_REAL) /100) AS MontoOrden
FROM  FILTRO_PERSONAS PER
            ,SUCURSALES SUC
            ,NEGOCIOS NEG
            ,CONCEPTOS_TESORERIA COT
            ,AREAS_GEOGRAFICAS AGE
            ,PRODUCTOS PRO
            ,ORDENES_DE_PAGO ODP
            ,COMPROBANTES_DE_EGRESO CEG
            ,CUENTAS_CLIENTE_CORREDORES CCC
            ,PERSONAS_CENTROS_PRODUCCION  PCP
            ,CENTROS_PRODUCCION CPR
            ,OPERACIONES_DIARIAS OPC
            ,DISTRIBUCION_OPERACIONES DOP
WHERE   PER.PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND     PER.PER_TID_CODIGO(+) =CCC.CCC_PER_TID_CODIGO
AND    SUC.SUC_CODIGO = ODP.ODP_SUC_CODIGO
AND    NEG.NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
AND    COT.COT_MNEMONICO = ODP.ODP_COT_MNEMONICO
AND    AGE.AGE_CODIGO (+) = ODP.ODP_AGE_CODIGO
AND    PRO.PRO_MNEMONICO (+) = ODP.ODP_NPR_PRO_MNEMONICO
AND    ODP.ODP_SUC_CODIGO = CEG.CEG_SUC_CODIGO
AND    ODP.ODP_NEG_CONSECUTIVO = CEG.CEG_NEG_CONSECUTIVO
AND    ODP.ODP_CEG_CONSECUTIVO = CEG.CEG_CONSECUTIVO
AND    CEG.CEG_FECHA >= TRUNC(P_FECHA)
AND    CEG.CEG_FECHA < TRUNC(P_FECHA)+1
AND    CEG.CEG_REVERSADO = 'N'
AND    CCC.CCC_CLI_PER_NUM_IDEN (+)  =  ODP.ODP_CCC_CLI_PER_NUM_IDEN
AND    CCC.CCC_CLI_PER_TID_CODIGO (+) =  ODP.ODP_CCC_CLI_PER_TID_CODIGO
AND    CCC.CCC_NUMERO_CUENTA (+) =  ODP.ODP_CCC_NUMERO_CUENTA
AND    PCP.PCP_PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND    PCP.PCP_PER_TID_CODIGO (+)  = CCC.CCC_PER_TID_CODIGO
AND    PCP.PCP_PRINCIPAL (+) = 'S'
AND    PCP.PCP_CPR_MNEMONICO  = CPR.CPR_MNEMONICO (+)
AND    OPC.OPC_ODP_CONSECUTIVO(+) = ODP.ODP_CONSECUTIVO
AND    OPC.OPC_ODP_SUC_CODIGO(+) = ODP.ODP_SUC_CODIGO
AND    OPC.OPC_ODP_NEG_CONSECUTIVO(+) = ODP.ODP_NEG_CONSECUTIVO
AND    DOP.DOP_OPC_CONSECUTIVO(+)  = OPC.OPC_CONSECUTIVO),

REGISTROS_CHEQUES_GERENCIA AS (
SELECT    ODP.ODP_SUC_CODIGO SucursalID,
          NVL(PRO.PRO_CODIGO_CAP,17) ProductoID,
          PCP.PCP_CPR_MNEMONICO MesaID,
          DECODE(ODP.ODP_ES_CLIENTE,'S',ODP.ODP_CCC_CLI_PER_NUM_IDEN,ODP.ODP_PER_NUM_IDEN) ClienteID ,
          CCC.CCC_PER_NUM_IDEN ComercialID,
          ODP.ODP_CCC_NUMERO_CUENTA Cuenta,
          NULL OrigenNegocioID,
          EXTRACT(YEAR FROM CGE.CGE_FECHA) Año,
          EXTRACT(MONTH FROM CGE.CGE_FECHA) Mes,
          EXTRACT(DAY FROM CGE.CGE_FECHA) Dia,
          SYSDATE FechaEjecucion,
          NULL Ip,
          SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
          DECODE(ODP.ODP_ES_CLIENTE, 'S', ODP.ODP_CCC_CLI_PER_TID_CODIGO, ODP.ODP_PER_TID_CODIGO) ClienteTID,
          CCC.CCC_PER_TID_CODIGO ComercialTID,
          0 AS Factor,
          NULL AS pMnemonico,
          CGE.CGE_CBA_BAN_CODIGO AS BancoID, -- ODP.ODP_BAN_CODIGO AS BancoID,
          CASE WHEN ODP.ODP_BAN_CODIGO = CGE.CGE_CBA_BAN_CODIGO THEN 'TRB' ELSE ODP.ODP_TPA_MNEMONICO END AS Operacion,
          (ODP.ODP_MONTO_ORDEN * DECODE(DOP.DOP_PARTICIPACION_REAL,NULL,100,DOP.DOP_PARTICIPACION_REAL) /100) AS MontoOrden
FROM  FILTRO_PERSONAS PER
            ,SUCURSALES SUC
            ,NEGOCIOS NEG
            ,CONCEPTOS_TESORERIA COT
            ,AREAS_GEOGRAFICAS AGE
            ,PRODUCTOS PRO
            ,ORDENES_DE_PAGO ODP
            ,CHEQUES_GERENCIA CGE
            ,CUENTAS_CLIENTE_CORREDORES CCC
            ,PERSONAS_CENTROS_PRODUCCION PCP
            ,CENTROS_PRODUCCION CPR
            ,OPERACIONES_DIARIAS OPC
            ,DISTRIBUCION_OPERACIONES DOP
WHERE PER.PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND     PER.PER_TID_CODIGO(+) = CCC.CCC_PER_TID_CODIGO
AND   SUC.SUC_CODIGO = ODP.ODP_SUC_CODIGO
AND    NEG.NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
AND    COT.COT_MNEMONICO = ODP.ODP_COT_MNEMONICO
AND    AGE.AGE_CODIGO (+) = ODP.ODP_AGE_CODIGO
AND    PRO.PRO_MNEMONICO (+) = ODP.ODP_NPR_PRO_MNEMONICO
AND    ODP.ODP_SUC_CODIGO = CGE.CGE_SUC_CODIGO
AND    ODP.ODP_NEG_CONSECUTIVO = CGE.CGE_NEG_CONSECUTIVO
AND    ODP.ODP_CGE_CONSECUTIVO = CGE.CGE_CONSECUTIVO
AND    CGE.CGE_FECHA >= TRUNC(P_FECHA)
AND    CGE.CGE_FECHA < TRUNC(P_FECHA)+1
AND    CGE.CGE_REVERSADO = 'N'
AND    CCC.CCC_CLI_PER_NUM_IDEN (+)  =  ODP.ODP_CCC_CLI_PER_NUM_IDEN
AND    CCC.CCC_CLI_PER_TID_CODIGO (+) =  ODP.ODP_CCC_CLI_PER_TID_CODIGO
AND    CCC.CCC_NUMERO_CUENTA (+) =  ODP.ODP_CCC_NUMERO_CUENTA
AND    PCP.PCP_PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND    PCP.PCP_PER_TID_CODIGO (+)  = CCC.CCC_PER_TID_CODIGO
AND    PCP.PCP_PRINCIPAL (+) = 'S'
AND    PCP.PCP_CPR_MNEMONICO  = CPR.CPR_MNEMONICO (+)
AND    OPC.OPC_ODP_CONSECUTIVO(+) = ODP.ODP_CONSECUTIVO
AND    OPC.OPC_ODP_SUC_CODIGO(+) = ODP.ODP_SUC_CODIGO
AND    OPC.OPC_ODP_NEG_CONSECUTIVO(+) = ODP.ODP_NEG_CONSECUTIVO
AND    DOP.DOP_OPC_CONSECUTIVO(+)  = OPC.OPC_CONSECUTIVO   ),

REGISTROS_PSETRB AS (
SELECT  ODP.ODP_SUC_CODIGO SucursalID,
        NVL(PRO.PRO_CODIGO_CAP,17) ProductoID,
        PCP.PCP_CPR_MNEMONICO MesaID,
        DECODE(ODP.ODP_ES_CLIENTE,'S',ODP.ODP_CCC_CLI_PER_NUM_IDEN,ODP.ODP_PER_NUM_IDEN) ClienteID ,
        CCC.CCC_PER_NUM_IDEN ComercialID,
        DECODE(ODP_ES_CLIENTE,'S',ODP_CCC_NUMERO_CUENTA,NULL) Cuenta,
        NULL OrigenNegocioID,
        EXTRACT(YEAR FROM TBC.TBC_FECHA) Año,
        EXTRACT(MONTH FROM TBC.TBC_FECHA) Mes,
        EXTRACT(DAY FROM TBC.TBC_FECHA) Dia,
        SYSDATE FechaEjecucion,
        NULL Ip,
        SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
        DECODE(ODP.ODP_ES_CLIENTE, 'S', ODP.ODP_CCC_CLI_PER_TID_CODIGO, ODP.ODP_PER_TID_CODIGO) ClienteTID,
        CCC.CCC_PER_TID_CODIGO ComercialTID,
        0 AS Factor,
        NULL AS pMnemonico,
        ODP.ODP_BAN_CODIGO AS BancoID, -- ODP.ODP_CBA_BAN_CODIGO AS BancoID,
        ODP.ODP_TPA_MNEMONICO AS Operacion, -- CASE WHEN ODP.ODP_BAN_CODIGO = TBC.TBC_CBA_BAN_CODIGO THEN 'TRB' ELSE ODP.ODP_TPA_MNEMONICO END AS Operacion,
        (ODP.ODP_MONTO_ORDEN * DECODE(DOP.DOP_PARTICIPACION_REAL,NULL,100,DOP.DOP_PARTICIPACION_REAL) /100) AS MontoOrden
FROM  FILTRO_PERSONAS PER
             ,SUCURSALES SUC
            ,NEGOCIOS NEG
            ,CONCEPTOS_TESORERIA COT
            ,AREAS_GEOGRAFICAS AGE
            ,PRODUCTOS PRO
            ,ORDENES_DE_PAGO ODP
            ,TRANSFERENCIAS_BANCARIAS TBC
            ,CUENTAS_CLIENTE_CORREDORES CCC
            ,PERSONAS_CENTROS_PRODUCCION PCP
            ,CENTROS_PRODUCCION CPR
           ,OPERACIONES_DIARIAS OPC
            ,DISTRIBUCION_OPERACIONES DOP
WHERE  PER.PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND    PER.PER_TID_CODIGO(+) = CCC.CCC_PER_TID_CODIGO
AND    SUC.SUC_CODIGO = ODP.ODP_SUC_CODIGO
AND    NEG.NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
AND    COT.COT_MNEMONICO = ODP.ODP_COT_MNEMONICO
AND    AGE.AGE_CODIGO (+) = ODP.ODP_AGE_CODIGO
AND    PRO.PRO_MNEMONICO (+) = ODP.ODP_NPR_PRO_MNEMONICO
AND    ODP.ODP_SUC_CODIGO = TBC.TBC_SUC_CODIGO
AND    ODP.ODP_NEG_CONSECUTIVO = TBC.TBC_NEG_CONSECUTIVO
AND    ODP.ODP_TBC_CONSECUTIVO = TBC.TBC_CONSECUTIVO
AND    ODP.ODP_TPA_MNEMONICO <> 'ACH'
AND    TBC.TBC_FECHA >= TRUNC(P_FECHA)
AND    TBC.TBC_FECHA < TRUNC(P_FECHA)+1
AND    TBC.TBC_REVERSADO = 'N'
AND    CCC.CCC_CLI_PER_NUM_IDEN (+)  =  ODP.ODP_CCC_CLI_PER_NUM_IDEN
AND    CCC.CCC_CLI_PER_TID_CODIGO (+) =  ODP.ODP_CCC_CLI_PER_TID_CODIGO
AND    CCC.CCC_NUMERO_CUENTA (+) =  ODP.ODP_CCC_NUMERO_CUENTA
AND    PCP.PCP_PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND    PCP.PCP_PER_TID_CODIGO (+)  = CCC.CCC_PER_TID_CODIGO
AND    PCP.PCP_PRINCIPAL (+) = 'S'
AND    PCP.PCP_CPR_MNEMONICO  = CPR.CPR_MNEMONICO (+)
AND    OPC.OPC_ODP_CONSECUTIVO(+) = ODP.ODP_CONSECUTIVO
AND    OPC.OPC_ODP_SUC_CODIGO(+) = ODP.ODP_SUC_CODIGO
AND    OPC.OPC_ODP_NEG_CONSECUTIVO(+) = ODP.ODP_NEG_CONSECUTIVO
AND    DOP.DOP_OPC_CONSECUTIVO(+)=  OPC.OPC_CONSECUTIVO ),


REGISTROS_ACH AS (
SELECT  ODP.ODP_SUC_CODIGO SucursalID,
        NVL(PRO.PRO_CODIGO_CAP,17) ProductoID,
        PCP.PCP_CPR_MNEMONICO MesaID,
        DECODE(ODP.ODP_ES_CLIENTE,'S',ODP.ODP_CCC_CLI_PER_NUM_IDEN,ODP.ODP_PER_NUM_IDEN) ClienteID ,
        CCC.CCC_PER_NUM_IDEN ComercialID,
        DECODE(ODP_ES_CLIENTE,'S',ODP_CCC_NUMERO_CUENTA,NULL) Cuenta,
        NULL OrigenNegocioID,
        EXTRACT(YEAR FROM TBC.TBC_FECHA) Año,
        EXTRACT(MONTH FROM TBC.TBC_FECHA) Mes,
        EXTRACT(DAY FROM TBC.TBC_FECHA) Dia,
        SYSDATE FechaEjecucion,
        NULL Ip,
        SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
        DECODE(ODP.ODP_ES_CLIENTE, 'S', ODP.ODP_CCC_CLI_PER_TID_CODIGO, ODP.ODP_PER_TID_CODIGO) ClienteTID,
        CCC.CCC_PER_TID_CODIGO ComercialTID,
        0 AS Factor,
        NULL AS pMnemonico,
        TBC.TBC_CBA_BAN_CODIGO AS BancoID, -- Banco Origen,
        CASE WHEN DPA.DPA_BAN_CODIGO = TBC.TBC_CBA_BAN_CODIGO THEN 'TRB' ELSE ODP.ODP_TPA_MNEMONICO END AS Operacion,
        (DPA.DPA_MONTO * DECODE(DOP.DOP_PARTICIPACION_REAL,NULL,100,DOP.DOP_PARTICIPACION_REAL) /100) AS MontoOrden
FROM  FILTRO_PERSONAS PER
             ,SUCURSALES SUC
            ,NEGOCIOS NEG
            ,CONCEPTOS_TESORERIA COT
            ,AREAS_GEOGRAFICAS AGE
            ,PRODUCTOS PRO
            ,ORDENES_DE_PAGO ODP
            ,TRANSFERENCIAS_BANCARIAS TBC
            ,DETALLES_PAGOS_ACH DPA
            ,CUENTAS_CLIENTE_CORREDORES CCC
            ,PERSONAS_CENTROS_PRODUCCION PCP
            ,CENTROS_PRODUCCION CPR
            ,OPERACIONES_DIARIAS OPC
            ,DISTRIBUCION_OPERACIONES DOP
WHERE PER.PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND     PER.PER_TID_CODIGO(+) = CCC.CCC_PER_TID_CODIGO
AND    DPA.DPA_ODP_CONSECUTIVO 	= ODP.ODP_CONSECUTIVO
AND    DPA.DPA_ODP_SUC_CODIGO  	= ODP.ODP_SUC_CODIGO
AND    DPA.DPA_ODP_NEG_CONSECUTIVO 	= ODP.ODP_NEG_CONSECUTIVO
AND    SUC.SUC_CODIGO = ODP.ODP_SUC_CODIGO
AND    NEG.NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
AND    COT.COT_MNEMONICO = ODP.ODP_COT_MNEMONICO
AND    AGE.AGE_CODIGO (+) = ODP.ODP_AGE_CODIGO
AND    ODP.ODP_SUC_CODIGO = TBC.TBC_SUC_CODIGO
AND    ODP.ODP_NEG_CONSECUTIVO = TBC.TBC_NEG_CONSECUTIVO
AND    ODP.ODP_TBC_CONSECUTIVO = TBC.TBC_CONSECUTIVO
AND    ODP.ODP_TPA_MNEMONICO =  'ACH'
AND    PRO.PRO_MNEMONICO (+) = ODP.ODP_NPR_PRO_MNEMONICO
AND    TBC.TBC_FECHA >= TRUNC(P_FECHA)
AND    TBC.TBC_FECHA < TRUNC(P_FECHA)+1
AND    TBC.TBC_REVERSADO = 'N'
AND    DPA.DPA_REVERSADO = 'N'
AND    CCC.CCC_CLI_PER_NUM_IDEN (+)  =  ODP.ODP_CCC_CLI_PER_NUM_IDEN
AND    CCC.CCC_CLI_PER_TID_CODIGO (+) =  ODP.ODP_CCC_CLI_PER_TID_CODIGO
AND    CCC.CCC_NUMERO_CUENTA (+) =  ODP.ODP_CCC_NUMERO_CUENTA
AND    PCP.PCP_PER_NUM_IDEN (+) = CCC.CCC_PER_NUM_IDEN
AND    PCP.PCP_PER_TID_CODIGO (+)  = CCC.CCC_PER_TID_CODIGO
AND    PCP.PCP_PRINCIPAL (+) = 'S'
AND    PCP.PCP_CPR_MNEMONICO  = CPR.CPR_MNEMONICO (+)
AND    OPC.OPC_ODP_CONSECUTIVO(+) = ODP.ODP_CONSECUTIVO
AND    OPC.OPC_ODP_SUC_CODIGO(+) = ODP.ODP_SUC_CODIGO
AND    OPC.OPC_ODP_NEG_CONSECUTIVO(+) = ODP.ODP_NEG_CONSECUTIVO
AND    DOP.DOP_OPC_CONSECUTIVO(+)=  OPC.OPC_CONSECUTIVO )

SELECT  SucursalID
        ,ProductoID
        ,NULL MesaID
        ,ClienteID
        ,ComercialID
        ,Cuenta
        ,OrigenNegocioID
        ,Año
        ,Mes
        ,Dia
        ,FechaEjecucion
        ,Ip
        ,Usuario
        ,ClienteTID
        ,ComercialTID
        ,0 AS   Factor
        ,NULL AS   pMnemonico
        ,BancoID
        ,Operacion
        ,MontoOrden
FROM    REGISTROS_ACH
WHERE   ClienteID != '830120309' -- No se tiene encuenta convenio con CLAVE INTEGRAL
AND     ComercialID IS NOT NULL
UNION ALL
SELECT  SucursalID
        ,ProductoID
        ,NULL MesaID
        ,ClienteID
        ,ComercialID
        ,Cuenta
        ,OrigenNegocioID
        ,Año
        ,Mes
        ,Dia
        ,FechaEjecucion
        ,Ip
        ,Usuario
        ,ClienteTID
        ,ComercialTID
        ,0 AS   Factor
        ,NULL AS   pMnemonico
        ,BancoID
        ,Operacion
        ,MontoOrden
FROM    REGISTROS_CHEQUES
WHERE   ClienteID != '830120309' -- No se tiene encuenta convenio con CLAVE INTEGRAL
AND     ComercialID IS NOT NULL
UNION ALL
SELECT  SucursalID
        ,ProductoID
        ,NULL MesaID
        ,ClienteID
        ,ComercialID
        ,Cuenta
        ,OrigenNegocioID
        ,Año
        ,Mes
        ,Dia
        ,FechaEjecucion
        ,Ip
        ,Usuario
        ,ClienteTID
        ,ComercialTID
        ,0 AS   Factor
        ,NULL AS   pMnemonico
        ,BancoID
        ,Operacion
        ,MontoOrden
FROM    REGISTROS_CHEQUES_GERENCIA
WHERE   ClienteID != '830120309' -- No se tiene encuenta convenio con CLAVE INTEGRAL
AND     ComercialID IS NOT NULL
UNION ALL
SELECT  SucursalID
        ,ProductoID
        ,NULL MesaID
        ,ClienteID
        ,ComercialID
        ,Cuenta
        ,OrigenNegocioID
        ,Año
        ,Mes
        ,Dia
        ,FechaEjecucion
        ,Ip
        ,Usuario
        ,ClienteTID
        ,ComercialTID
        , 0 AS   Factor
        , NULL AS   pMnemonico
        ,BancoID
        ,Operacion
        ,MontoOrden
FROM    REGISTROS_PSETRB
WHERE   ClienteID != '830120309' -- No se tiene encuenta convenio con CLAVE INTEGRAL
AND     ComercialID IS NOT NULL;

END ASIGNACION_COSTO_PAGOS_BANC;


PROCEDURE ASIGNACION_COSTO_RECAUDOS_BANC(
    P_FECHA DATE,
    io_cursor IN OUT O_CURSOR)
IS
  V_valorFactor NUMBER;
BEGIN

  OPEN io_cursor FOR
  WITH DATOS_RECIBOS_CAJA AS (
  SELECT  RCA_SUC_CODIGO SucursalID,
          17 ProductoID,
          PCP.PCP_CPR_MNEMONICO MesaID,
          RCA_CCC_CLI_PER_NUM_IDEN ClienteID ,
          CCC.CCC_PER_NUM_IDEN ComercialID,
          RCA_CCC_NUMERO_CUENTA Cuenta,
          RCA_NEG_CONSECUTIVO OrigenNegocioID,
          TO_CHAR(RCA.RCA_FECHA,'YYYY') Año,
          TO_CHAR(RCA.RCA_FECHA,'MM') Mes,
          TO_CHAR(RCA.RCA_FECHA,'DD') Dia,
          SYSDATE FechaEjecucion,
          NULL Ip,
          SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
          RCA_CCC_CLI_PER_TID_CODIGO ClienteTID,
          CCC.CCC_PER_TID_CODIGO ComercialTID,
          COB.COB_CBA_BAN_CODIGO BancoID,
          DECODE(CCA.CCA_BAN_CODIGO,'0','PSE','CHE') Operacion,
          CCA.CCA_MONTO AS MontoOrden
        FROM    FILTRO_PERSONAS PER
        INNER JOIN RECIBOS_DE_CAJA RCA
                ON RCA.RCA_CCC_CLI_PER_NUM_IDEN = PER.PER_NUM_IDEN
               AND RCA.RCA_CCC_CLI_PER_TID_CODIGO = PER.PER_TID_CODIGO
        INNER JOIN CHEQUES_CAJA CCA
                ON CCA.CCA_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO
               AND CCA.CCA_RCA_SUC_CODIGO = RCA.RCA_SUC_CODIGO
               AND CCA.CCA_RCA_NEG_CONSECUTIVO = RCA.RCA_NEG_CONSECUTIVO
        INNER JOIN CONSIGNACIONES_Y_CHEQUES CCH
                ON CCA.CCA_CONSECUTIVO = CCH.CCH_CCA_CONSECUTIVO
        INNER JOIN CONSIGNACIONES_BANCARIAS COB
                ON COB.COB_CONSECUTIVO = CCH.CCH_COB_CONSECUTIVO
               AND COB.COB_SUC_CODIGO = CCH.CCH_COB_SUC_CODIGO
               AND COB.COB_NEG_CONSECUTIVO = CCH.CCH_COB_NEG_CONSECUTIVO
        INNER JOIN CUENTAS_CLIENTE_CORREDORES CCC
                ON CCC.CCC_CLI_PER_TID_CODIGO = RCA.RCA_CCC_CLI_PER_TID_CODIGO
               AND CCC.CCC_CLI_PER_NUM_IDEN = RCA.RCA_CCC_CLI_PER_NUM_IDEN
               AND CCC.CCC_NUMERO_CUENTA = RCA.RCA_CCC_NUMERO_CUENTA
        INNER JOIN PERSONAS_CENTROS_PRODUCCION PCP
                ON CCC.CCC_PER_NUM_IDEN   = PCP.PCP_PER_NUM_IDEN
               AND CCC.CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO
               AND PCP.PCP_PRINCIPAL = 'S'
        INNER JOIN CENTROS_PRODUCCION CPR
                ON PCP.PCP_CPR_MNEMONICO = CPR.CPR_MNEMONICO
  WHERE   RCA.RCA_ES_CLIENTE = 'S'
  AND     RCA.RCA_FECHA >= TRUNC(P_FECHA)
  AND     RCA.RCA_FECHA < TRUNC(P_FECHA)+1
  AND     RCA.RCA_REVERSADO = 'N'
  UNION ALL
  SELECT  RCA_SUC_CODIGO SucursalID ,
          17 ProductoID ,
          PCP.PCP_CPR_MNEMONICO MesaID ,
          RCA_CCC_CLI_PER_NUM_IDEN ClienteID ,
          CCC.CCC_PER_NUM_IDEN ComercialID ,
          RCA_CCC_NUMERO_CUENTA Cuenta ,
          RCA_NEG_CONSECUTIVO OrigenNegocioID ,
          TO_CHAR(RCA.RCA_FECHA,'YYYY') Año ,
          TO_CHAR(RCA.RCA_FECHA,'MM') Mes ,
          TO_CHAR(RCA.RCA_FECHA,'DD') Dia ,
          SYSDATE FechaEjecucion ,
          NULL Ip ,
          SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
          RCA_CCC_CLI_PER_TID_CODIGO ClienteTID ,
          CCC.CCC_PER_TID_CODIGO ComercialTID ,
          CCJ_CBA_BAN_CODIGO BancoID ,
          DECODE(CCJ.CCJ_CBA_BAN_CODIGO,'0','PSE','CON') Operacion,
          CCJ.CCJ_MONTO AS MontoOrden
  FROM    FILTRO_PERSONAS PER
          INNER JOIN RECIBOS_DE_CAJA RCA
                  ON RCA.RCA_CCC_CLI_PER_NUM_IDEN = PER.PER_NUM_IDEN
                 AND RCA.RCA_CCC_CLI_PER_TID_CODIGO = PER.PER_TID_CODIGO
          INNER JOIN CONSIGNACIONES_CAJA CCJ
                  ON CCJ.CCJ_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO
                 AND CCJ.CCJ_RCA_SUC_CODIGO = RCA.RCA_SUC_CODIGO
                 AND CCJ.CCJ_RCA_NEG_CONSECUTIVO = RCA.RCA_NEG_CONSECUTIVO
          INNER JOIN CUENTAS_CLIENTE_CORREDORES CCC
                  ON CCC.CCC_CLI_PER_TID_CODIGO = RCA.RCA_CCC_CLI_PER_TID_CODIGO
                 AND CCC.CCC_CLI_PER_NUM_IDEN = RCA.RCA_CCC_CLI_PER_NUM_IDEN
                 AND CCC.CCC_NUMERO_CUENTA = RCA.RCA_CCC_NUMERO_CUENTA
          INNER JOIN PERSONAS_CENTROS_PRODUCCION PCP
                  ON CCC.CCC_PER_NUM_IDEN   = PCP.PCP_PER_NUM_IDEN
                 AND CCC.CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO
                 AND PCP.PCP_PRINCIPAL = 'S'
          INNER JOIN CENTROS_PRODUCCION CPR
                  ON PCP.PCP_CPR_MNEMONICO = CPR.CPR_MNEMONICO
  WHERE   RCA_ES_CLIENTE = 'S'
  AND     RCA_FECHA >= TRUNC(P_FECHA)
  AND     RCA_FECHA < TRUNC(P_FECHA)+1
  AND     RCA_REVERSADO = 'N'
  UNION ALL
  SELECT  RCA_SUC_CODIGO SucursalID ,
          17 ProductoID ,
          PCP.PCP_CPR_MNEMONICO MesaID ,
          RCA_CCC_CLI_PER_NUM_IDEN ClienteID ,
          CCC.CCC_PER_NUM_IDEN ComercialID ,
          RCA_CCC_NUMERO_CUENTA Cuenta ,
          RCA_NEG_CONSECUTIVO OrigenNegocioID ,
          TO_CHAR(RCA.RCA_FECHA,'YYYY') Año ,
          TO_CHAR(RCA.RCA_FECHA,'MM') Mes ,
          TO_CHAR(RCA.RCA_FECHA,'DD') Dia ,
          SYSDATE FechaEjecucion ,
          NULL Ip ,
          SYS_CONTEXT ('USERENV', 'SESSION_USER') Usuario,
          RCA_CCC_CLI_PER_TID_CODIGO ClienteTID ,
          CCC.CCC_PER_TID_CODIGO ComercialTID ,
          TRC_CBA_BAN_CODIGO BancoID ,
          DECODE(TRC.TRC_CBA_BAN_CODIGO,'0','PSE','TRB') Operacion,
          TRC.TRC_MONTO AS MontoOrden
  FROM    FILTRO_PERSONAS PER
          INNER JOIN RECIBOS_DE_CAJA RCA
                  ON RCA.RCA_CCC_CLI_PER_NUM_IDEN = PER.PER_NUM_IDEN
                 AND RCA.RCA_CCC_CLI_PER_TID_CODIGO = PER.PER_TID_CODIGO
          INNER JOIN TRANSFERENCIAS_CAJA TRC
                  ON TRC.TRC_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO
                 AND TRC.TRC_RCA_SUC_CODIGO = RCA.RCA_SUC_CODIGO
                 AND TRC.TRC_RCA_NEG_CONSECUTIVO = RCA.RCA_NEG_CONSECUTIVO
          INNER JOIN CUENTAS_CLIENTE_CORREDORES CCC
                  ON CCC.CCC_CLI_PER_TID_CODIGO = RCA.RCA_CCC_CLI_PER_TID_CODIGO
                 AND CCC.CCC_CLI_PER_NUM_IDEN = RCA.RCA_CCC_CLI_PER_NUM_IDEN
                 AND CCC.CCC_NUMERO_CUENTA = RCA.RCA_CCC_NUMERO_CUENTA
          INNER JOIN PERSONAS_CENTROS_PRODUCCION PCP
                  ON CCC.CCC_PER_NUM_IDEN   = PCP.PCP_PER_NUM_IDEN
                 AND CCC.CCC_PER_TID_CODIGO = PCP.PCP_PER_TID_CODIGO
                 AND PCP.PCP_PRINCIPAL = 'S'
          INNER JOIN CENTROS_PRODUCCION CPR
                  ON PCP.PCP_CPR_MNEMONICO = CPR.CPR_MNEMONICO
  WHERE   RCA_ES_CLIENTE = 'S'
  AND     RCA_FECHA >= TRUNC(P_FECHA)
  AND     RCA_FECHA < TRUNC(P_FECHA)+1
  AND     RCA_REVERSADO = 'N')

  -- 2. SELECCION DE DATOS DE SALIDA DEL CURSOR
  SELECT  SucursalID ,
          ProductoID ,
          NULL MesaID ,
          ClienteID ,
          ComercialID ,
          Cuenta ,
          OrigenNegocioID ,
          Año ,
          Mes ,
          Dia ,
          FechaEjecucion ,
          Ip ,
          Usuario ,
          ClienteTID ,
          ComercialTID ,
          0 AS Factor ,
          NULL AS pMnemonico ,
          Operacion ,
          BancoID ,
          MontoOrden
  FROM    DATOS_RECIBOS_CAJA
  ORDER BY 1,2,3,4;

END ASIGNACION_COSTO_RECAUDOS_BANC;

PROCEDURE PR_RTIADV (P_FECHA DATE) IS

   CURSOR C_TMP IS
      SELECT DISTINCT CLASE
                     ,TIPO
                     ,ENA_MNEMONICO
      FROM   TMP_RTIADV_GROUP;
   TMP C_TMP%ROWTYPE;

   CURSOR C_ENA (P_ENA VARCHAR2) IS
      SELECT ENA_MNEMONICO
            ,ENA_DESCRIPCION
            ,ENA_CES_MNEMONICO
            ,CES_DESCRIPCION
            ,CTI_DESCRIPCION
            ,CES_CONT_ADMON_VALORES
      FROM   ESPECIES_NACIONALES
            ,CATEGORIAS_ESPECIES
            ,CLASES_TITULOS
      WHERE  ENA_MNEMONICO = P_ENA
      AND    ENA_CES_MNEMONICO = CES_MNEMONICO (+)
      AND    ENA_CTI_MNEMONICO = CTI_MNEMONICO (+);
   ENA C_ENA%ROWTYPE;

   CURSOR C_FON (P_FON VARCHAR2) IS
      SELECT FON_RAZON_SOCIAL
      FROM   FONDOS
      WHERE  FON_CODIGO = P_FON;
   V_FON VARCHAR2(150);

   V_CTI VARCHAR2(200);

   CURSOR C_ACC IS
      SELECT DISTINCT ENA_MNEMONICO
      --, TASA_VALORACION, VALOR_UNIDAD
      FROM   TMP_RTIADV_GROUP
      WHERE  CLASE = 'TIT'
      AND    TIPO = 'ACC';
   ACC C_ACC%ROWTYPE;

   CURSOR C_PRECIO_ESPECIE IS
      SELECT PEB_PRECIO_BOLSA
      FROM   PRECIOS_ESPECIES_BOLSA A
      WHERE  PEB_ENA_MNEMONICO = ACC.ENA_MNEMONICO
      AND    PEB_FECHA = (SELECT MAX(PEB_FECHA )
                          FROM   PRECIOS_ESPECIES_BOLSA B
                          WHERE  B.PEB_ENA_MNEMONICO = ACC.ENA_MNEMONICO
                          AND    PEB_FECHA < '01-ABR-2016');
   V_VALOR_UNIDAD       NUMBER(15);

BEGIN

   DELETE FROM TMP_RTIADV;
   DELETE FROM TMP_RTIADV_GROUP;

   -- 1
   INSERT INTO TMP_RTIADV (
          DEPOSITO
         ,CLASE
         ,ISIN_DECEVAL
         ,FUNGIBLE
         ,CUENTA_DECEVAL
         ,ENA_MNEMONICO
         ,TIPO_TASA
         ,TASA_FACIAL
         ,CLI_PER_NUM_IDEN
         ,CLI_PER_TID_CODIGO
         ,SALDO_DISPONIBLE
         ,SALDO_GARANTIA
         ,SALDO_EMBARGO
         ,SALDO_GARANTIA_REPO
         ,SALDO_POR_CUMPLIR
         ,SALDO_COMPRA_POR_CUMPLIR
         ,SALDO_TRANSITO_INGRESO
         ,SALDO_TRANSITO_RETIRO
         ,SALDO_GARANTIA_DERIVADOS
         ,VALOR_DISPONIBLE
         ,VALOR_GARANTIA
         ,VALOR_EMBARGO
         ,VALOR_GARANTIA_REPO
         ,VALOR_POR_CUMPLIR
         ,VALOR_COMPRA_POR_CUMPLIR
         ,VALOR_TRANSITO_INGRESO
         ,VALOR_TRANSITO_RETIRO
         ,VALOR_GARANTIA_DERIVADOS
         ,TASA_VALORACION
         ,MET_VALORACION
         ,CODIGO
         ,TIPO
         ,FECHA_EMISION
         ,FECHA_VENCIMIENTO
         ,MODALIDAD
         ,BASE
         ,PERIODICIDAD_TASA
         ,VALOR_COMPROMISO_COMPRA
         ,VALOR_COMPROMISO_VENTA
         ,VALOR_UNIDAD
         ,CUSTODIO
         ,INDICADOR_OPE)
   SELECT 'DCVAL'                           DEPOSITO
         ,'TIT'                             CLASE
         ,HST_CFC_FUG_ISI_MNEMONICO         ISIN_DECEVAL
         ,HST_CFC_FUG_MNEMONICO             FUNGIBLE
         ,HST_CFC_CUENTA_DECEVAL            CUENTA_DECEVAL
         ,FUG_ENA_MNEMONICO                 ENA_MNEMONICO
         ,DECODE(FUG_TRE_MNEMONICO,NULL
                ,DECODE(FUG_TASA_FACIAL,NULL,NULL,'FIJA')
                ,FUG_TRE_MNEMONICO)         TIPO_TASA
         ,DECODE(FUG_TRE_MNEMONICO,NULL
                ,DECODE(FUG_TASA_FACIAL,NULL,NULL,0,'0',TRIM(TO_CHAR(FUG_TASA_FACIAL,'990.999999')))
                ,FUG_TRE_MNEMONICO||' + '||FUG_PUNTOS_ADICIONALES)         TASA_FACIAL
	       ,HST_CCC_CLI_PER_NUM_IDEN          CLI_PER_NUM_IDEN
         ,HST_CCC_CLI_PER_TID_CODIGO        CLI_PER_TID_CODIGO
         ,HST_SALDO_DISPONIBLE              SALDO_DISPONIBLE
         ,HST_SALDO_GARANTIA                SALDO_GARANTIA
         ,HST_SALDO_EMBARGO                 SALDO_EMBARGO
         ,HST_SALDO_GARANTIA_REPO           SALDO_GARANTIA_REPO
         ,HST_SALDO_POR_CUMPLIR             SALDO_POR_CUMPLIR
         ,HST_SALDO_CPR_X_CUMPLIR           SALDO_COMPRA_POR_CUMPLIR
         ,HST_SALDO_TRANSITO_ING            SALDO_TRANSITO_INGRESO
         ,HST_SALDO_TRANSITO_RET            SALDO_TRANSITO_RETIRO
         ,HST_SALDO_GARANTIA_DER            SALDO_GARANTIA_DERIVADOS
         ,HST_VALOR_TM_DISPONIBLE           VALOR_DISPONIBLE
         ,HST_VALOR_TM_GARANTIA             VALOR_GARANTIA
         ,HST_VALOR_TM_EMBARGO              VALOR_EMBARGO
         ,HST_VALOR_TM_GARREPO              VALOR_GARANTIA_REPO
         ,HST_VALOR_TM_XCUMPLIR             VALOR_POR_CUMPLIR
         ,HST_VALOR_TM_CPR_X_CUMPLIR        VALOR_COMPRA_POR_CUMPLIR
         ,HST_VALOR_TM_TRANING              VALOR_TRANSITO_INGRESO
         ,HST_VALOR_TM_TRANRET              VALOR_TRANSITO_RETIRO
         ,HST_VALOR_TM_GARDER               VALOR_GARANTIA_DERIVADOS
         ,HST_TASA_VALORACION               TASA_VALORACION
	       ,HST_INDICADOR_VALORACION          MET_VALORACION
         ,NULL                              CODIGO
         ,FUG_TIPO                          TIPO
         ,FUG_FECHA_EMISION                 FECHA_EMISION
         ,FUG_FECHA_VENCIMIENTO             FECHA_VENCIMIENTO
         ,FUG_MODALIDAD_TASA                MODALIDAD
         ,FUG_BASE_CALCULO                  BASE
         ,FUG_PERIODICIDAD_TASA             PERIODICIDAD_TASA
         ,0                                 VALOR_COMPROMISO_COMPRA
         ,0                                 VALOR_COMPROMISO_VENTA
         ,0                                 VALOR_UNIDAD
         ,NVL(CUD_CUSTODIO,'N')             CUSTODIO
         ,'T'                               INDICADOR_OPE
   FROM   FUNGIBLES
         ,HISTORICOS_SALDOS_TITULOS
         ,CUENTAS_DECEVAL
   WHERE   FUG_ISI_MNEMONICO = HST_CFC_FUG_ISI_MNEMONICO
   AND     FUG_MNEMONICO = HST_CFC_FUG_MNEMONICO
   AND     HST_FECHA >= TRUNC(P_FECHA)
   AND     HST_FECHA < TRUNC(P_FECHA + 1)
   AND     HST_CFC_CUENTA_DECEVAL = CUD_CUENTA_DECEVAL
   UNION ALL                                                        --COMPROMISOS DE COMPRA - DECEVAL
   -- 2
   SELECT  'DCVAL'                           DEPOSITO
          ,'TIT'                             CLASE
          ,HCC_CFC_FUG_ISI_MNEMONICO         ISIN_DECEVAL
          ,HCC_CFC_FUG_MNEMONICO             FUNGIBLE
          ,HCC_CFC_CUENTA_DECEVAL            CUENTA_DECEVAL
          ,FUG_ENA_MNEMONICO                 ENA_MNEMONICO
          ,DECODE(FUG_TRE_MNEMONICO,NULL
	               ,DECODE(FUG_TASA_FACIAL,NULL,NULL,'FIJA')
			           ,FUG_TRE_MNEMONICO)         TIPO_TASA
          ,DECODE(FUG_TRE_MNEMONICO,NULL
                 ,DECODE(FUG_TASA_FACIAL,NULL,NULL,0,'0',TRIM(TO_CHAR(FUG_TASA_FACIAL,'990.999999')))
                 ,FUG_TRE_MNEMONICO||' + '||FUG_PUNTOS_ADICIONALES)         TASA_FACIAL
          ,HCC_CCC_CLI_PER_NUM_IDEN          CLI_PER_NUM_IDEN
          ,HCC_CCC_CLI_PER_TID_CODIGO        CLI_PER_TID_CODIGO
          ,0                                 SALDO_DISPONIBLE
          ,0                                 SALDO_GARANTIA
          ,0                                 SALDO_EMBARGO
          ,0                                 SALDO_GARANTIA_REPO
          ,0                                 SALDO_POR_CUMPLIR
          ,0                                 SALDO_COMPRA_POR_CUMPLIR
          ,0                                 SALDO_TRANSITO_INGRESO
          ,0                                 SALDO_TRANSITO_RETIRO
          ,0                                 SALDO_GARANTIA_DERIVADOS
          ,0                                 VALOR_DISPONIBLE
          ,0                                 VALOR_GARANTIA
          ,0                                 VALOR_EMBARGO
          ,0                                 VALOR_GARANTIA_REPO
          ,0                                 VALOR_POR_CUMPLIR
          ,0                                 VALOR_COMPRA_POR_CUMPLIR
          ,0                                 VALOR_TRANSITO_INGRESO
          ,0                                 VALOR_TRANSITO_RETIRO
          ,0                                 VALOR_GARANTIA_DERIVADOS
          ,NULL                              TASA_VALORACION
	        ,NULL                              MET_VALORACION
          ,NULL                              CODIGO
          ,FUG_TIPO                          TIPO
          ,FUG_FECHA_EMISION                 FECHA_EMISION
          ,FUG_FECHA_VENCIMIENTO             FECHA_VENCIMIENTO
          ,FUG_MODALIDAD_TASA                MODALIDAD
          ,FUG_BASE_CALCULO                  BASE
          ,FUG_PERIODICIDAD_TASA             PERIODICIDAD_TASA
          ,HCC_VALOR_NOMINAL                 VALOR_COMPROMISO_COMPRA
          ,0                                 VALOR_COMPROMISO_VENTA
          ,0                                 VALOR_UNIDAD
          ,NVL(CUD_CUSTODIO,'N')             CUSTODIO
          ,'C'                               INDICADOR_OPE
   FROM    FUNGIBLES
          ,HISTORICOS_COMPROMISOS_CLIENTE
          ,CUENTAS_DECEVAL
   WHERE   FUG_ISI_MNEMONICO = HCC_CFC_FUG_ISI_MNEMONICO
   AND     FUG_MNEMONICO = HCC_CFC_FUG_MNEMONICO
   AND     HCC_LIC_TIPO_OPERACION = 'C'
   AND     HCC_FECHA >= TRUNC(P_FECHA)
   AND     HCC_FECHA < TRUNC(P_FECHA + 1)
   AND     HCC_CFC_CUENTA_DECEVAL = CUD_CUENTA_DECEVAL
   UNION ALL                                                        --COMPROMISOS DE VENTAS - DECEVAL
   -- 3
   SELECT  'DCVAL'                           DEPOSITO
          ,'TIT'                             CLASE
          ,HCC_CFC_FUG_ISI_MNEMONICO         ISIN_DECEVAL
          ,HCC_CFC_FUG_MNEMONICO             FUNGIBLE
          ,HCC_CFC_CUENTA_DECEVAL            CUENTA_DECEVAL
          ,FUG_ENA_MNEMONICO                 ENA_MNEMONICO
          ,DECODE(FUG_TRE_MNEMONICO,NULL
                 ,DECODE(FUG_TASA_FACIAL,NULL,NULL,'FIJA')
                 ,FUG_TRE_MNEMONICO)         TIPO_TASA
          ,DECODE(FUG_TRE_MNEMONICO,NULL
                 ,DECODE(FUG_TASA_FACIAL,NULL,NULL,0,'0',TRIM(TO_CHAR(FUG_TASA_FACIAL,'990.999999')))
                 ,FUG_TRE_MNEMONICO||' + '||FUG_PUNTOS_ADICIONALES)         TASA_FACIAL
          ,HCC_CCC_CLI_PER_NUM_IDEN          CLI_PER_NUM_IDEN
          ,HCC_CCC_CLI_PER_TID_CODIGO        CLI_PER_TID_CODIGO
          ,0                                 SALDO_DISPONIBLE
          ,0                                 SALDO_GARANTIA
          ,0                                 SALDO_EMBARGO
          ,0                                 SALDO_GARANTIA_REPO
          ,0                                 SALDO_POR_CUMPLIR
          ,0                                 SALDO_COMPRA_POR_CUMPLIR
          ,0                                 SALDO_TRANSITO_INGRESO
          ,0                                 SALDO_TRANSITO_RETIRO
          ,0                                 SALDO_GARANTIA_DERIVADOS
          ,0                                 VALOR_DISPONIBLE
          ,0                                 VALOR_GARANTIA
          ,0                                 VALOR_EMBARGO
          ,0                                 VALOR_GARANTIA_REPO
          ,0                                 VALOR_POR_CUMPLIR
          ,0                                 VALOR_COMPRA_POR_CUMPLIR
          ,0                                 VALOR_TRANSITO_INGRESO
          ,0                                 VALOR_TRANSITO_RETIRO
          ,0                                 VALOR_GARANTIA_DERIVADOS
          ,NULL                              TASA_VALORACION
	        ,NULL                              MET_VALORACION
          ,NULL                              CODIGO
          ,FUG_TIPO                          TIPO
          ,FUG_FECHA_EMISION                 FECHA_EMISION
          ,FUG_FECHA_VENCIMIENTO             FECHA_VENCIMIENTO
          ,FUG_MODALIDAD_TASA                MODALIDAD
          ,FUG_BASE_CALCULO                  BASE
          ,FUG_PERIODICIDAD_TASA             PERIODICIDAD_TASA
          ,0                                 VALOR_COMPROMISO_COMPRA
          ,HCC_VALOR_NOMINAL                 VALOR_COMPROMISO_VENTA
          ,0                                 VALOR_UNIDAD
          ,NVL(CUD_CUSTODIO,'N')             CUSTODIO
          ,'C'                               INDICADOR_OPE
   FROM    FUNGIBLES
          ,HISTORICOS_COMPROMISOS_CLIENTE
          ,CUENTAS_DECEVAL
   WHERE   FUG_ISI_MNEMONICO = HCC_CFC_FUG_ISI_MNEMONICO
   AND     FUG_MNEMONICO = HCC_CFC_FUG_MNEMONICO
   AND     HCC_LIC_TIPO_OPERACION = 'V'
   AND     HCC_FECHA >= TRUNC(P_FECHA)
   AND     HCC_FECHA < TRUNC(P_FECHA + 1)
   AND     HCC_CFC_CUENTA_DECEVAL = CUD_CUENTA_DECEVAL
   UNION ALL
   -- 4
   SELECT  'DCV'                             DEPOSITO
          ,'TIT'                             CLASE
          ,NULL                              ISIN_DECEVAL
          ,NULL                              FUNGIBLE
          ,NULL                              CUENTA_DECEVAL
          ,TLO_ENA_MNEMONICO                 ENA_MNEMONICO
          ,DECODE(TLO_TRE_MNEMONICO,NULL
                 ,DECODE(TLO_TASA_FACIAL,NULL,NULL,'FIJA')
                 ,TLO_TRE_MNEMONICO)         TIPO_TASA
          ,DECODE(TLO_TRE_MNEMONICO,NULL
                 ,DECODE(TLO_TASA_FACIAL,NULL,NULL,0,'0',TRIM(TO_CHAR(TLO_TASA_FACIAL,'990.999999')))
                 ,TLO_TRE_MNEMONICO||' + '||TLO_PUNTOS_ADICIONALES)         TASA_FACIAL
	        ,HST_CCC_CLI_PER_NUM_IDEN          CLI_PER_NUM_IDEN
          ,HST_CCC_CLI_PER_TID_CODIGO        CLI_PER_TID_CODIGO
          ,HST_SALDO_DISPONIBLE              SALDO_DISPONIBLE
          ,HST_SALDO_GARANTIA                SALDO_GARANTIA
          ,HST_SALDO_EMBARGO                 SALDO_EMBARGO
          ,HST_SALDO_GARANTIA_REPO           SALDO_GARANTIA_REPO
          ,HST_SALDO_POR_CUMPLIR             SALDO_POR_CUMPLIR
          ,HST_SALDO_CPR_X_CUMPLIR           SALDO_COMPRA_POR_CUMPLIR
          ,HST_SALDO_TRANSITO_ING            SALDO_TRANSITO_INGRESO
          ,HST_SALDO_TRANSITO_RET            SALDO_TRANSITO_RETIRO
          ,HST_SALDO_GARANTIA_DER            SALDO_GARANTIA_DERIVADOS
          ,HST_VALOR_TM_DISPONIBLE           VALOR_DISPONIBLE
          ,HST_VALOR_TM_GARANTIA             VALOR_GARANTIA
          ,HST_VALOR_TM_EMBARGO              VALOR_EMBARGO
          ,HST_VALOR_TM_GARREPO              VALOR_GARANTIA_REPO
          ,HST_VALOR_TM_XCUMPLIR             VALOR_POR_CUMPLIR
          ,HST_VALOR_TM_CPR_X_CUMPLIR        VALOR_COMPRA_POR_CUMPLIR
          ,HST_VALOR_TM_TRANING              VALOR_TRANSITO_INGRESO
          ,HST_VALOR_TM_TRANRET              VALOR_TRANSITO_RETIRO
          ,HST_VALOR_TM_GARDER               VALOR_GARANTIA_DERIVADOS
          ,HST_TASA_VALORACION               TASA_VALORACION
	        ,HST_INDICADOR_VALORACION          MET_VALORACION
          ,TLO_REFERENCIA_DEPOSITO           CODIGO
          ,DECODE(TLO_TYPE,'TVC','ACC','RF') TIPO
          ,TLO_FECHA_EMISION                 FECHA_EMISION
          ,TLO_FECHA_VENCIMIENTO             FECHA_VENCIMIENTO
          ,TLO_MODALIDAD_TASA                MODALIDAD
          ,TLO_BASE_CALCULO                  BASE
          ,TLO_PERIODICIDAD_TASA             PERIODICIDAD_TASA
          ,0                                 VALOR_COMPROMISO_COMPRA
          ,0                                 VALOR_COMPROMISO_VENTA
          ,0                                 VALOR_UNIDAD
          ,NVL(TLO_CUSTODIO,'N')             CUSTODIO
          ,'T'                               INDICADOR_OPE
   FROM    TITULOS
          ,HISTORICOS_SALDOS_TITULOS
   WHERE   TLO_CODIGO = HST_TLO_CODIGO
   AND     HST_FECHA >= TRUNC(P_FECHA)
   AND     HST_FECHA < TRUNC(P_FECHA + 1)
   UNION ALL                       --COMPROMISOS DE COMPRA -DCV
   -- 5
   SELECT  'DCV'                             DEPOSITO
          ,'TIT'                             CLASE
          ,NULL                              ISIN_DECEVAL
          ,NULL                              FUNGIBLE
          ,NULL                              CUENTA_DECEVAL
          ,TLO_ENA_MNEMONICO                 ENA_MNEMONICO
          ,DECODE(TLO_TRE_MNEMONICO,NULL
                 ,DECODE(TLO_TASA_FACIAL,NULL,NULL,'FIJA')
                 ,TLO_TRE_MNEMONICO)         TIPO_TASA
          ,DECODE(TLO_TRE_MNEMONICO,NULL
                 ,DECODE(TLO_TASA_FACIAL,NULL,NULL,0,'0',TRIM(TO_CHAR(TLO_TASA_FACIAL,'990.999999')))
                 ,TLO_TRE_MNEMONICO||' + '||TLO_PUNTOS_ADICIONALES)         TASA_FACIAL
          ,HCC_CCC_CLI_PER_NUM_IDEN          CLI_PER_NUM_IDEN
          ,HCC_CCC_CLI_PER_TID_CODIGO        CLI_PER_TID_CODIGO
          ,0                                 SALDO_DISPONIBLE
          ,0                                 SALDO_GARANTIA
          ,0                                 SALDO_EMBARGO
          ,0                                 SALDO_GARANTIA_REPO
          ,0                                 SALDO_POR_CUMPLIR
          ,0                                 SALDO_COMPRA_POR_CUMPLIR
          ,0                                 SALDO_TRANSITO_INGRESO
          ,0                                 SALDO_TRANSITO_RETIRO
          ,0                                 SALDO_GARANTIA_DERIVADOS
          ,0                                 VALOR_DISPONIBLE
          ,0                                 VALOR_GARANTIA
          ,0                                 VALOR_EMBARGO
          ,0                                 VALOR_GARANTIA_REPO
          ,0                                 VALOR_POR_CUMPLIR
          ,0                                 VALOR_COMPRA_POR_CUMPLIR
          ,0                                 VALOR_TRANSITO_INGRESO
          ,0                                 VALOR_TRANSITO_RETIRO
          ,0                                 VALOR_GARANTIA_DERIVADOS
          ,NULL                              TASA_VALORACION
	        ,NULL                              MET_VALORACION
          ,TLO_REFERENCIA_DEPOSITO           CODIGO
          ,DECODE(TLO_TYPE,'TVC','ACC','RF') TIPO
          ,TLO_FECHA_EMISION                 FECHA_EMISION
          ,TLO_FECHA_VENCIMIENTO             FECHA_VENCIMIENTO
          ,TLO_MODALIDAD_TASA                MODALIDAD
          ,TLO_BASE_CALCULO                  BASE
          ,TLO_PERIODICIDAD_TASA             PERIODICIDAD_TASA
          ,HCC_VALOR_NOMINAL                 VALOR_COMPROMISO_COMPRA
          ,0                                 VALOR_COMPROMISO_VENTA
          ,0                                 VALOR_UNIDAD
          ,NVL(TLO_CUSTODIO,'N')             CUSTODIO
          ,'C'                               INDICADOR_OPE
   FROM    TITULOS
          ,HISTORICOS_COMPROMISOS_CLIENTE
   WHERE   TLO_CODIGO = HCC_TLO_CODIGO
   AND     HCC_LIC_TIPO_OPERACION = 'C'
   AND     HCC_FECHA >= TRUNC(P_FECHA)
   AND     HCC_FECHA < TRUNC(P_FECHA + 1)
   UNION ALL                       --COMPROMISOS DE VENTA -DCV
   -- 6
   SELECT  'DCV'                             DEPOSITO
          ,'TIT'                             CLASE
          ,NULL                              ISIN_DECEVAL
          ,NULL                              FUNGIBLE
          ,NULL                              CUENTA_DECEVAL
          ,TLO_ENA_MNEMONICO                 ENA_MNEMONICO
          ,DECODE(TLO_TRE_MNEMONICO,NULL
                 ,DECODE(TLO_TASA_FACIAL,NULL,NULL,'FIJA')
                 ,TLO_TRE_MNEMONICO)         TIPO_TASA
          ,DECODE(TLO_TRE_MNEMONICO,NULL
                 ,DECODE(TLO_TASA_FACIAL,NULL,NULL,0,'0',TRIM(TO_CHAR(TLO_TASA_FACIAL,'990.999999')))
                 ,TLO_TRE_MNEMONICO||' + '||TLO_PUNTOS_ADICIONALES)         TASA_FACIAL
          ,HCC_CCC_CLI_PER_NUM_IDEN          CLI_PER_NUM_IDEN
          ,HCC_CCC_CLI_PER_TID_CODIGO        CLI_PER_TID_CODIGO
          ,0                                 SALDO_DISPONIBLE
          ,0                                 SALDO_GARANTIA
          ,0                                 SALDO_EMBARGO
          ,0                                 SALDO_GARANTIA_REPO
          ,0                                 SALDO_POR_CUMPLIR
          ,0                                 SALDO_COMPRA_POR_CUMPLIR
          ,0                                 SALDO_TRANSITO_INGRESO
          ,0                                 SALDO_TRANSITO_RETIRO
          ,0                                 SALDO_GARANTIA_DERIVADOS
          ,0                                 VALOR_DISPONIBLE
          ,0                                 VALOR_GARANTIA
          ,0                                 VALOR_EMBARGO
          ,0                                 VALOR_GARANTIA_REPO
          ,0                                 VALOR_POR_CUMPLIR
          ,0                                 VALOR_COMPRA_POR_CUMPLIR
          ,0                                 VALOR_TRANSITO_INGRESO
          ,0                                 VALOR_TRANSITO_RETIRO
          ,0                                 VALOR_GARANTIA_DERIVADOS
          ,NULL                              TASA_VALORACION
	        ,NULL                              MET_VALORACION
          ,TLO_REFERENCIA_DEPOSITO           CODIGO
          ,DECODE(TLO_TYPE,'TVC','ACC','RF') TIPO
          ,TLO_FECHA_EMISION                 FECHA_EMISION
          ,TLO_FECHA_VENCIMIENTO             FECHA_VENCIMIENTO
          ,TLO_MODALIDAD_TASA                MODALIDAD
          ,TLO_BASE_CALCULO                  BASE
          ,TLO_PERIODICIDAD_TASA             PERIODICIDAD_TASA
          ,HCC_VALOR_NOMINAL                 VALOR_COMPROMISO_COMPRA
          ,0                                 VALOR_COMPROMISO_VENTA
          ,0                                 VALOR_UNIDAD
          ,NVL(TLO_CUSTODIO,'N')             CUSTODIO
          ,'C'                               INDICADOR_OPE
   FROM    TITULOS
          ,HISTORICOS_COMPROMISOS_CLIENTE
   WHERE   TLO_CODIGO = HCC_TLO_CODIGO
   AND     HCC_LIC_TIPO_OPERACION = 'V'
   AND     HCC_FECHA >= TRUNC(P_FECHA)
   AND     HCC_FECHA < TRUNC(P_FECHA + 1)
   UNION ALL   -- APORTES A FONDOS CON TITULOS PARTICIPATIVOS
   -- 7
   SELECT  'DCVAL'                           DEPOSITO
          ,'FTP'                             CLASE
          ,'TP'                              ISIN_DECEVAL
          ,NULL                              FUNGIBLE
          ,NULL                              CUENTA_DECEVAL
          ,FON_CODIGO                        ENA_MNEMONICO
          ,NULL                              TIPO_TASA
	        ,NULL                              TASA_FACIAL
          ,A.MCF_CFO_CCC_CLI_PER_NUM_IDEN    CLI_PER_NUM_IDEN
          ,A.MCF_CFO_CCC_CLI_PER_TID_CODIGO  CLI_PER_TID_CODIGO
          ,SUM(A.MCF_SALDO_UNIDADES)         SALDO_DISPONIBLE
          ,0                                 SALDO_GARANTIA
          ,0                                 SALDO_EMBARGO
          ,0                                 SALDO_GARANTIA_REPO
          ,0                                 SALDO_POR_CUMPLIR
          ,0                                 SALDO_COMPRA_POR_CUMPLIR
          ,0                                 SALDO_TRANSITO_INGRESO
          ,0                                 SALDO_TRANSITO_RETIRO
          ,0                                 SALDO_GARANTIA_DERIVADOS
          ,SUM(A.MCF_SALDO_UNIDADES) *   NVL(VFO.VFO_VALOR,0)  VALOR_DISPONIBLE
          ,0                                 VALOR_GARANTIA
          ,0                                 VALOR_EMBARGO
          ,0                                 VALOR_GARANTIA_REPO
          ,0                                 VALOR_POR_CUMPLIR
          ,0                                 VALOR_COMPRA_POR_CUMPLIR
          ,0                                 VALOR_TRANSITO_INGRESO
          ,0                                 VALOR_TRANSITO_RETIRO
          ,0                                 VALOR_GARANTIA_DERIVADOS
          ,NULL                              TASA_VALORACION
	        ,NULL                              MET_VALORACION
          ,NULL                              CODIGO
          ,'RF'                              TIPO
          ,NULL                              FECHA_EMISION
          ,NULL                              FECHA_VENCIMIENTO
          ,NULL                              MODALIDAD
          ,NULL                              BASE
          ,NULL                              PERIODICIDAD_TASA
          ,0                                 VALOR_COMPROMISO_COMPRA
          ,0                                 VALOR_COMPROMISO_VENTA
          ,NVL(VFO.VFO_VALOR,0)              VALOR_UNIDAD
          ,NULL                              CUSTODIO
          ,'T'                               INDICADOR_OPE
   FROM    MOVIMIENTOS_CUENTAS_FONDOS A,
           CUENTAS_FONDOS B,
           FONDOS F,
           CLIENTES CL,
           (SELECT E.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                   E.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                   E.MCF_CFO_CCC_NUMERO_CUENTA,
                   E.MCF_CFO_FON_CODIGO,
                   E.MCF_CFO_CODIGO,
                   MAX(E.MCF_CONSECUTIVO) MCF_CONSECUTIVO
            FROM   MOVIMIENTOS_CUENTAS_FONDOS E
            WHERE  EXISTS (
                   SELECT 'X'
                   FROM FONDOS F,
                        PARAMETROS_FONDOS G
                   WHERE F.FON_CODIGO = G.PFO_FON_CODIGO
                     AND G.PFO_PAR_CODIGO = '86'
                     AND NVL(G.PFO_RANGO_MIN_CHAR,'N') = 'S'
                     AND F.FON_CODIGO = E.MCF_CFO_FON_CODIGO)
            AND   E.MCF_FECHA >= TRUNC(P_FECHA - 5)
            AND   E.MCF_FECHA <  TRUNC(P_FECHA + 1)
            GROUP BY E.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                  E.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                  E.MCF_CFO_CCC_NUMERO_CUENTA,
                  E.MCF_CFO_FON_CODIGO,
                  E.MCF_CFO_CODIGO
           ) MCF1,
           (SELECT VFO_FON_CODIGO,
                   VFO_VALOR
            FROM   VALORIZACIONES_FONDO
            WHERE  VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
            AND    VFO_FECHA_VALORIZACION <  TRUNC(P_FECHA+1)
           ) VFO
   WHERE   A.MCF_CFO_CCC_CLI_PER_NUM_IDEN = B.CFO_CCC_CLI_PER_NUM_IDEN
   AND     A.MCF_CFO_CCC_CLI_PER_TID_CODIGO = B.CFO_CCC_CLI_PER_TID_CODIGO
   AND     A.MCF_CFO_CCC_NUMERO_CUENTA = B.CFO_CCC_NUMERO_CUENTA
   AND     A.MCF_CFO_FON_CODIGO = B.CFO_FON_CODIGO
   AND     A.MCF_CFO_CODIGO = B.CFO_CODIGO
   AND     B.CFO_FON_CODIGO = F.FON_CODIGO
   AND     B.CFO_CCC_CLI_PER_NUM_IDEN = CL.CLI_PER_NUM_IDEN
   AND     B.CFO_CCC_CLI_PER_TID_CODIGO = CL.CLI_PER_TID_CODIGO
   AND     NVL(CL.CLI_ADM_PORTAFOLIO_DCVAL,'N')  = 'S'
   AND     EXISTS (
           SELECT 'X'
           FROM FONDOS C,
                PARAMETROS_FONDOS D
           WHERE C.FON_CODIGO = D.PFO_FON_CODIGO
             AND D.PFO_PAR_CODIGO = '86'
             AND NVL(D.PFO_RANGO_MIN_CHAR,'N') = 'S'
             AND C.FON_CODIGO = B.CFO_FON_CODIGO
           )
   AND     A.MCF_CFO_CCC_CLI_PER_NUM_IDEN = MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN
   AND     A.MCF_CFO_CCC_CLI_PER_TID_CODIGO = MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO
   AND     A.MCF_CFO_CCC_NUMERO_CUENTA = MCF1.MCF_CFO_CCC_NUMERO_CUENTA
   AND     A.MCF_CFO_FON_CODIGO = MCF1.MCF_CFO_FON_CODIGO
   AND     A.MCF_CFO_CODIGO = MCF1.MCF_CFO_CODIGO
   AND     A.MCF_CONSECUTIVO =  MCF1.MCF_CONSECUTIVO
   AND     F.FON_CODIGO = VFO.VFO_FON_CODIGO (+)
   GROUP   BY A.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
           A.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
           F.FON_CODIGO,
           NVL(VFO.VFO_VALOR,0)
   HAVING SUM(A.MCF_SALDO_UNIDADES) != 0;

   INSERT INTO TMP_RTIADV_GROUP (
          DEPOSITO
         ,CLASE
         ,TIPO
         ,ISIN_DECEVAL
         ,FUNGIBLE
         ,ENA_MNEMONICO
         ,CUENTA_DECEVAL
         ,CUSTODIO
         ,CODIGO
         ,CLI_PER_NUM_IDEN
         ,CLI_PER_TID_CODIGO
         ,FECHA_EMISION
         ,FECHA_VENCIMIENTO
         ,TIPO_TASA
         ,TASA_FACIAL
         ,MODALIDAD
         ,BASE
         ,PERIODICIDAD_TASA
         ,TASA_VALORACION
         ,MET_VALORACION
         ,VALOR_UNIDAD
         ,SALDO_DISPONIBLE
         ,SALDO_GARANTIA
         ,SALDO_EMBARGO
         ,SALDO_GARANTIA_REPO
         ,SALDO_POR_CUMPLIR
         ,SALDO_COMPRA_POR_CUMPLIR
         ,SALDO_TRANSITO_INGRESO
         ,SALDO_TRANSITO_RETIRO
         ,SALDO_GARANTIA_DERIVADOS
         ,VALOR_DISPONIBLE
         ,VALOR_GARANTIA
         ,VALOR_EMBARGO
         ,VALOR_GARANTIA_REPO
         ,VALOR_POR_CUMPLIR
         ,VALOR_COMPRA_POR_CUMPLIR
         ,VALOR_TRANSITO_INGRESO
         ,VALOR_TRANSITO_RETIRO
         ,VALOR_GARANTIA_DERIVADOS
         ,VALOR_COMPROMISO_COMPRA
         ,VALOR_COMPROMISO_VENTA
         ,INDICADOR_OPE)
   SELECT DEPOSITO
         ,CLASE
         ,TIPO
         ,ISIN_DECEVAL
         ,FUNGIBLE
         ,ENA_MNEMONICO
         ,CUENTA_DECEVAL
         ,CUSTODIO
         ,CODIGO
         ,CLI_PER_NUM_IDEN
         ,CLI_PER_TID_CODIGO
         ,FECHA_EMISION
         ,FECHA_VENCIMIENTO
         ,TIPO_TASA
         ,TASA_FACIAL
         ,MODALIDAD
         ,BASE
         ,PERIODICIDAD_TASA
         ,TASA_VALORACION
         ,MET_VALORACION
         ,VALOR_UNIDAD
         ,SUM(SALDO_DISPONIBLE)              SALDO_DISPONIBLE
         ,SUM(SALDO_GARANTIA)                SALDO_GARANTIA
         ,SUM(SALDO_EMBARGO)                 SALDO_EMBARGO
         ,SUM(SALDO_GARANTIA_REPO)           SALDO_GARANTIA_REPO
         ,SUM(SALDO_POR_CUMPLIR)             SALDO_POR_CUMPLIR
         ,SUM(SALDO_COMPRA_POR_CUMPLIR)      SALDO_COMPRA_POR_CUMPLIR
         ,SUM(SALDO_TRANSITO_INGRESO)        SALDO_TRANSITO_INGRESO
         ,SUM(SALDO_TRANSITO_RETIRO)         SALDO_TRANSITO_RETIRO
         ,SUM(SALDO_GARANTIA_DERIVADOS)      SALDO_GARANTIA_DERIVADOS
         ,SUM(VALOR_DISPONIBLE)              VALOR_DISPONIBLE
         ,SUM(VALOR_GARANTIA)                VALOR_GARANTIA
         ,SUM(VALOR_EMBARGO)                 VALOR_EMBARGO
         ,SUM(VALOR_GARANTIA_REPO)           VALOR_GARANTIA_REPO
         ,SUM(VALOR_POR_CUMPLIR)             VALOR_POR_CUMPLIR
         ,SUM(VALOR_COMPRA_POR_CUMPLIR)      VALOR_COMPRA_POR_CUMPLIR
         ,SUM(VALOR_TRANSITO_INGRESO)        VALOR_TRANSITO_INGRESO
         ,SUM(VALOR_TRANSITO_RETIRO)         VALOR_TRANSITO_RETIRO
         ,SUM(VALOR_GARANTIA_DERIVADOS)      VALOR_GARANTIA_DERIVADOS
         ,SUM(VALOR_COMPROMISO_COMPRA)       VALOR_COMPROMISO_COMPRA
         ,SUM(VALOR_COMPROMISO_VENTA)        VALOR_COMPROMISO_VENTA
         ,INDICADOR_OPE
   FROM   TMP_RTIADV
   group by
   DEPOSITO,
   CLASE,
   TIPO,
   ISIN_DECEVAL,
   FUNGIBLE,
   ENA_MNEMONICO,
   CUENTA_DECEVAL,
   CUSTODIO, CODIGO,
   CLI_PER_NUM_IDEN,
   CLI_PER_TID_CODIGO,
   FECHA_EMISION,
   FECHA_VENCIMIENTO,
   TIPO_TASA,
   TASA_FACIAL,
   MODALIDAD,
   BASE,
   PERIODICIDAD_TASA,
   TASA_VALORACION,
   MET_VALORACION,
   VALOR_UNIDAD,
   INDICADOR_OPE;

   OPEN C_TMP;
   FETCH C_TMP INTO TMP;
   WHILE C_TMP%FOUND LOOP
      V_CTI := NULL;
      IF TMP.CLASE = 'TIT' THEN
         OPEN C_ENA(TMP.ENA_MNEMONICO);
         FETCH C_ENA INTO ENA;
         IF C_ENA%FOUND THEN
            IF TMP.TIPO = 'ACC' THEN
               V_CTI := ENA.CTI_DESCRIPCION;
            END IF;
            UPDATE TMP_RTIADV_GROUP
            SET    ENA_DESCRIPCION   = ENA.ENA_DESCRIPCION
                  ,ENA_CES_MNEMONICO = ENA.ENA_CES_MNEMONICO
                  ,CES_DESCRIPCION   = ENA.CES_DESCRIPCION
                  ,CTI_DESCRIPCION   = V_CTI
                  ,COD_CONTABLE      = ENA.CES_CONT_ADMON_VALORES
            WHERE  CLASE = 'TIT'
            AND    ENA_MNEMONICO = TMP.ENA_MNEMONICO;
         END IF;
         CLOSE C_ENA;
      ELSE
         OPEN C_FON(TMP.ENA_MNEMONICO);
         FETCH C_FON INTO V_FON;

         UPDATE TMP_RTIADV_GROUP
         SET    ENA_DESCRIPCION = ENA.ENA_DESCRIPCION
         WHERE  CLASE = 'FTP'
         AND    ENA_MNEMONICO = TMP.ENA_MNEMONICO;
         CLOSE C_FON;
      END IF;
      FETCH C_TMP INTO TMP;
   END LOOP;
   CLOSE C_TMP;

   OPEN C_ACC;
   FETCH C_ACC INTO ACC;
   WHILE C_ACC%FOUND LOOP
      V_VALOR_UNIDAD := NULL;
      OPEN C_PRECIO_ESPECIE;
      FETCH C_PRECIO_ESPECIE INTO V_VALOR_UNIDAD;
      IF C_PRECIO_ESPECIE%FOUND THEN
         UPDATE TMP_RTIADV_GROUP
         SET    TASA_VALORACION = V_VALOR_UNIDAD,
                VALOR_UNIDAD = V_VALOR_UNIDAD
         WHERE  CLASE = 'TIT'
         AND    TIPO = 'ACC'
         AND    ENA_MNEMONICO = ACC.ENA_MNEMONICO;
      END IF;
      CLOSE C_PRECIO_ESPECIE;

      FETCH C_ACC INTO ACC;
   END LOOP;
   CLOSE C_ACC;

   UPDATE TMP_RTIADV_GROUP
   SET    VALOR_UNIDAD = 0
   WHERE  CLASE = 'TIT'
   AND    TIPO = 'RF';

   UPDATE TMP_RTIADV_GROUP
   SET    TASA_VALORACION = NULL
   WHERE  CLASE = 'FTP';

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,'Error en proceso PR_RTIADV '||SQLERRM);

END PR_RTIADV;

PROCEDURE PR_GENERAR_XLSX (P_RUTA VARCHAR2, P_NOMBRE_ARCHIVO VARCHAR2, P_QUERY VARCHAR2,
                              P_CODIGO IN OUT VARCHAR2, P_RESPUESTA IN OUT VARCHAR2) IS
   P_CLOB            CLOB;
   P_HOST_NAME       VARCHAR2(200);
   L_HTTP_REQUEST   UTL_HTTP.REQ;
   L_HTTP_RESPONSE  UTL_HTTP.RESP;
   L_RAW_DATA       RAW(1536);--antes estaba en 512 crcastillo
   L_BUFFER_SIZE    NUMBER(10) := 1536;--antes estaba en 512
   L_STRING_REQUEST VARCHAR2(4000);
   L_SUBSTRING_MSG  VARCHAR2(1536);--antes estaba 1000
   P_VALOR          NUMBER;
   P_VALOR_DATE     DATE;
   P_VALOR_CHAR     VARCHAR2(200);

BEGIN
   P_TOOLS.CONSULTARCONSTANTE(
   P_CONSTANTE  => 'HSN',
   P_VALOR      => P_VALOR,
   P_VALOR_DATE => P_VALOR_DATE,
   P_VALOR_CHAR => P_VALOR_CHAR
   );

   IF NVL(P_VALOR_CHAR,' ') IS NULL THEN
      RAISE_APPLICATION_ERROR(-20900, 'No existe constante HNS HOST SERVICIOS NET');
   END IF;
      P_HOST_NAME := nvl(P_VALOR_CHAR,' ');
      P_CLOB := NULL;

   l_string_request := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
                            <soapenv:Header/>
                              <soapenv:Body>
                                <tem:GenerarXLSX>
                                   <tem:rutaDestino>'||P_RUTA||'</tem:rutaDestino>
                                   <tem:nombreArchivo>'||P_NOMBRE_ARCHIVO||'</tem:nombreArchivo>
                                   <tem:querySQL>'||P_QUERY||'</tem:querySQL>
                                </tem:GenerarXLSX>
                             </soapenv:Body>
                          </soapenv:Envelope>';
   UTL_HTTP.set_transfer_timeout(300);
   l_http_request := UTL_HTTP.begin_request(url => 'http://'||P_HOST_NAME||'/CorredoresServicesIntegracion/SrvCoeasy.svc', method => 'POST', http_version => utl_http.HTTP_VERSION_1_1);
   UTL_HTTP.set_header(l_http_request, 'Content-Type', 'text/xml; charset=utf-8');
   UTL_HTTP.set_header(l_http_request, 'SOAPAction', '"http://tempuri.org/ISrvCOEASY/GenerarXLSX"');
   UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_string_request));
   UTL_HTTP.set_header(l_http_request, 'Connection', 'Close');
   <<request_loop>>
   FOR i IN 0..CEIL(LENGTH(l_string_request) / l_buffer_size) - 1 LOOP
      l_substring_msg := SUBSTR(l_string_request, i * l_buffer_size + 1, l_buffer_size);
      BEGIN
         l_raw_data := utl_raw.cast_to_raw(l_substring_msg);
         UTL_HTTP.write_raw(r => l_http_request, data => l_raw_data);
      EXCEPTION
          WHEN NO_DATA_FOUND THEN
            EXIT request_loop;
      END;
   END LOOP request_loop;
   l_http_response := UTL_HTTP.get_response(l_http_request);

   BEGIN
      <<response_loop>>
      LOOP
         UTL_HTTP.READ_RAW(L_HTTP_RESPONSE, L_RAW_DATA, L_BUFFER_SIZE);
         P_CLOB := P_CLOB || UTL_RAW.cast_to_varchar2(l_raw_data);
      END LOOP response_loop;
      EXCEPTION
         WHEN UTL_HTTP.end_of_body THEN
            UTL_HTTP.end_response(l_http_response);
   END;

   IF l_http_request.private_hndl IS NOT NULL THEN
      UTL_HTTP.end_request(l_http_request);
   END IF;

   IF l_http_response.private_hndl IS NOT NULL THEN
      UTL_HTTP.end_response(l_http_response);
   END IF;

   IF (INSTR(P_CLOB,'<a:Codigo>0000</a:Codigo>') > 0) OR (INSTR(P_CLOB,'<a:Codigo>0001</a:Codigo>') > 0) THEN
      P_RESPUESTA  := NULL;
      P_CAB.ObtenerUnDato(P_CLOB ,'<a:Descripcion>' ,'</a:Descripcion>',P_RESPUESTA);
      P_CODIGO  := NULL;
      P_CAB.ObtenerUnDato(P_CLOB ,'<a:Codigo>' ,'</a:Codigo>',P_CODIGO);
   ELSE
      P_RESPUESTA  := 'ERROR EN EL LLAMADO AL WEB SERVICE';
      P_CODIGO  := '0001';
   END IF;
   EXCEPTION WHEN OTHERS THEN
		DBMS_OUTPUT.put_line(SQLERRM||'-'||SQLCODE);

END PR_GENERAR_XLSX;

PROCEDURE PR_GENERAR_XLSX_API (P_RUTA VARCHAR2, P_NOMBRE_ARCHIVO VARCHAR2, P_QUERY VARCHAR2,
                           P_CODIGO IN OUT VARCHAR2, P_RESPUESTA IN OUT VARCHAR2,P_NOM_HOJAS VARCHAR2 DEFAULT NULL) IS

   P_VALOR          NUMBER;
   P_VALOR_DATE     DATE;
   P_VALOR_CHAR     VARCHAR2(200);
   P_URL            VARCHAR2(500);
   P_BODY           VARCHAR2(10000);
   P_METODO         VARCHAR2(200);
   P_COD_RES        NUMBER;
   P_MSJ_RES        VARCHAR2(200);
   P_RESPUESTA_APP  CLOB;
   R_RUTA           VARCHAR2(200);
   V_DATA_BASE      VARCHAR2(200);
   V_ATRIBUTO       VARCHAR2(200);
BEGIN

   P_TOOLS.CONSULTARCONSTANTE( P_CONSTANTE  => 'AGE'
                              ,P_VALOR      => P_VALOR
                              ,P_VALOR_DATE => P_VALOR_DATE
                              ,P_VALOR_CHAR => P_VALOR_CHAR);

   IF NVL(P_VALOR_CHAR,' ') IS NULL THEN
        RAISE_APPLICATION_ERROR(-20901,'No existe parametro Api Generacion Excel');
   END IF;

   P_URL := NVL(P_VALOR_CHAR,' ');

   BEGIN
      SELECT NAME INTO V_DATA_BASE FROM V$database;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_DATA_BASE := NULL;
   END;

   IF P_NOM_HOJAS IS NOT NULL THEN
      V_ATRIBUTO := ',"SheetNames":"'||P_NOM_HOJAS||'"';
   ELSE
      V_ATRIBUTO := ',"SheetNames":"'||'Hoja1'||'"';
   END IF;

   --{"Path":"//nas/Presentaciones/testApi.xlsx","SqlCommand":"SELECT * FROM TMP_RNOCON"}
   IF P_RUTA IS NULL THEN
     R_RUTA := '\\NAS.corredor.local\Presentaciones\';
     P_BODY := '{"Path":"'||REPLACE(R_RUTA,'\','/')||P_NOMBRE_ARCHIVO||'.xlsx","SqlCommand":"'||P_QUERY||'"'||V_ATRIBUTO||',"DB":"'||V_DATA_BASE||'"}';
   ELSE
     P_BODY := '{"Path":"'||REPLACE(P_RUTA,'\','/')||P_NOMBRE_ARCHIVO||'.xlsx","SqlCommand":"'||P_QUERY||'"'||V_ATRIBUTO||',"DB":"'||V_DATA_BASE||'"}';
   END IF;

   begin
      -- Call the procedure
      prod.P_TOOLS.PR_CALL_REST_API(P_URL => P_URL,
                                    P_BODY => P_BODY,
                                    P_METODO => 'POST',
                                    P_COD_RES => P_COD_RES,
                                    P_MSJ_RES => P_MSJ_RES,
                                    P_RESPUESTA => P_RESPUESTA_APP);
      dbms_output.put_line('Procedimiento'||P_COD_RES||' '||P_MSJ_RES);
   end;

   if(P_COD_RES = 200) then
     P_CODIGO := '0000';
   else
     P_CODIGO := '0001';
   end if;

   P_RESPUESTA :=   P_MSJ_RES;

EXCEPTION WHEN OTHERS THEN
   DBMS_OUTPUT.put_line(SQLERRM||'-'||SQLCODE);

END PR_GENERAR_XLSX_API;

END;

/

  GRANT EXECUTE ON "PROD"."P_REPORTES" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_REPORTES" TO "NOCTURNO";
  GRANT EXECUTE ON "PROD"."P_REPORTES" TO "USR_CAP";
  GRANT DEBUG ON "PROD"."P_REPORTES" TO "M_GEREN_CONT_COORD_APT_CCY_FCP";
  GRANT EXECUTE ON "PROD"."P_REPORTES" TO "M_GEREN_CONT_COORD_APT_CCY_FCP";
