--------------------------------------------------------
--  File created - Saturday-April-25-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_OPERACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_OPERACIONES" IS

/*********************************************************************************
***  Procedimiento que llama la Causacion Automatica de Operaciones Bursatiles  **
***  Se corre en el proceso Nocturno                                            **
***  se debe correr despues de las 12:00 no tiene limite de horario             **
***  Siempre envia mail al finalizar el proceso : con ERROR o EXITOSO            **
***  SOLO SE DEBE CORRER EN DIAS HABILES                                        **
******************************************************************************* */
PROCEDURE CAUSACION_OP_BURSATIL_DIARIA is

   FECHA_HOY               DATE;

   CURSOR C_DNH IS
      SELECT DNH_FECHA
        FROM DIAS_NO_HABILES
       WHERE DNH_FECHA >= TRUNC(FECHA_HOY)
         AND DNH_FECHA < TRUNC(FECHA_HOY + 1);
   DNH C_DNH%ROWTYPE;

   CURSOR C_ERRORES IS
      SELECT COUNT(*) T
      FROM ERRORES_PROCESOS
      WHERE ERP_FECHA_ERROR >= TRUNC(FECHA_HOY)
        --AND ERP_PROCESO != 'P_OPERACIONES.INSERTA_MOV_DIVISAS';
      AND ERP_PROCESO NOT IN ('P_OPERACIONES.INSERTA_MOV_DIVISAS','P_BANCOS.PR_RECAUDOS_BANCOS','P_AVISOR.PR_INSERTAR_PAGOS');
   NUM_ERRORES NUMBER;


   -- VARIABLES PARA MAIL
   conn                    utl_smtp.connection;
   req                     utl_http.req;
   resp                    utl_http.resp;
   data                    RAW(200);
   NOM_ERROR               VARCHAR2(80);



BEGIN
   SELECT TRUNC(SYSDATE) INTO FECHA_HOY FROM DUAL;

   OPEN C_DNH;
   FETCH C_DNH INTO DNH;
   IF C_DNH%FOUND OR TO_CHAR(FECHA_HOY ,'D') IN ('7','1') THEN
      NULL;
   ELSE
      P_OPERACIONES.CAUSACION;

      -- verifica si se generaron errores
      OPEN C_ERRORES;
      FETCH C_ERRORES INTO NUM_ERRORES;
      CLOSE C_ERRORES;
      NUM_ERRORES := NVL(NUM_ERRORES,0);

	    IF NUM_ERRORES != 0 THEN
	       P_MAIL.ENVIO_MAIL_ERROR('P_OPERACIONES.CAUSACION_OP_BURSATIL_DIARIA  F A L L O !!!',' Se corrio procedimiento y genero errores. Verificar en la tabla ERRORES_PROCESO');
	    ELSE
         P_PROCESOS_NOCTURNOS.P_ACT_CONS_COLOCACION('S');
         P_MAIL.envio_mail_error('P_OPERACIONES.CAUSACION_OP_BURSATIL_DIARIA EXITOSA','Causacion diaria de operacion Bursatil : EXITOSA');
	    END IF;
	 END IF;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.ENVIO_MAIL_ERROR('P_OPERACIONES.CAUSACION_OP_BURSATIL_DIARIA FALLO',substr(sqlerrm,1,80));
END CAUSACION_OP_BURSATIL_DIARIA;


/***********************************************************************
***  Procedimiento de Inserta errores en la tabla ERRORES_PROCESOS    **
********************************************************************* */
PROCEDURE INSERTA_ERROR ( P_PROCESO         ERRORES_PROCESOS.ERP_PROCESO%TYPE
                         ,P_ERROR           ERRORES_PROCESOS.ERP_ERROR%TYPE
                         ,P_TABLA_ERROR     ERRORES_PROCESOS.ERP_TABLA_ERROR%TYPE) IS

BEGIN
   INSERT INTO ERRORES_PROCESOS (
           ERP_CONSECUTIVO
          ,ERP_FECHA_ERROR
          ,ERP_PROCESO
          ,ERP_ERROR
          ,ERP_TABLA_ERROR)
   VALUES( ERP_SEQ.NEXTVAL
          ,SYSDATE
          ,SUBSTR(P_PROCESO,1,200)
          ,P_ERROR
          ,SUBSTR(P_TABLA_ERROR,1,100)
          );
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('ERROR INSERTANTO ERRORES '||SQLERRM);
      RAISE_APPLICATION_ERROR(-20001,SQLERRM);
END INSERTA_ERROR;


/***********************************************************************
***  Procedimiento de Causacion Automatica de Operaciones Bursatiles  **
***  Se corre a la fecha : sysdate                                    **
********************************************************************* */

PROCEDURE CAUSACION IS
   CURSOR C_OCO IS
      -- OPERACIONES A PLAZO
      SELECT  'OPL' TIPO_CAUSACION
             ,OCO_CONSECUTIVO
             ,OCO_COC_CTO_MNEMONICO
             ,OCO_BOL_MNEMONICO
             ,OCO_CCC_CLI_PER_NUM_IDEN
             ,OCO_CCC_CLI_PER_TID_CODIGO
             ,OCO_CCC_NUMERO_CUENTA
             ,OCO_ENA_MNEMONICO
             ,OCO_TIPO_NOMINAL_O_PESOS
             ,OCO_FECHA_Y_HORA
             ,OCO_COC_CTE_MNEMONICO
             ,OCO_LTI_MNEMONICO
             ,OCO_PER_NUM_IDEN
             ,OCO_PER_TID_CODIGO
             ,OCO_PORTAFOLIO
             ,OCO_MONEDA_COMPENSACION
      FROM ORDENES_COMPRA
      WHERE  ( OCO_CONSECUTIVO
              ,OCO_COC_CTO_MNEMONICO
				      ,OCO_BOL_MNEMONICO) IN  (SELECT  LIC_OCO_CONSECUTIVO
                                              ,LIC_OCO_COC_CTO_MNEMONICO
                                              ,LIC_BOL_MNEMONICO
				                               FROM  LIQUIDACIONES_COMERCIAL
				                               WHERE LIC_ELI_MNEMONICO = 'OPL'
                                       AND   LIC_BOL_MNEMONICO IN ('MEC','COL','DVL')
				                               AND   LIC_TIPO_OPERACION = 'C'
				                               AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
                                       AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE)
                                       AND   NVL(LIC_ESTADO,'A') != 'G')
      UNION ALL
      -- OPERACIONES DE CONTADO
      SELECT  'CON' TIPO_CAUSACION
             ,OCO_CONSECUTIVO
             ,OCO_COC_CTO_MNEMONICO
             ,OCO_BOL_MNEMONICO
             ,OCO_CCC_CLI_PER_NUM_IDEN
             ,OCO_CCC_CLI_PER_TID_CODIGO
             ,OCO_CCC_NUMERO_CUENTA
             ,OCO_ENA_MNEMONICO
             ,OCO_TIPO_NOMINAL_O_PESOS
             ,OCO_FECHA_Y_HORA
             ,OCO_COC_CTE_MNEMONICO
             ,OCO_LTI_MNEMONICO
             ,OCO_PER_NUM_IDEN
             ,OCO_PER_TID_CODIGO
             ,OCO_PORTAFOLIO
             ,OCO_MONEDA_COMPENSACION
      FROM ORDENES_COMPRA
      WHERE ( OCO_CONSECUTIVO
 				     ,OCO_COC_CTO_MNEMONICO
				     ,OCO_BOL_MNEMONICO) IN  (SELECT  LIC_OCO_CONSECUTIVO
				                                     ,LIC_OCO_COC_CTO_MNEMONICO
				                                     ,LIC_BOL_MNEMONICO
				                              FROM  LIQUIDACIONES_COMERCIAL
				                              WHERE LIC_ELI_MNEMONICO != 'OPL'
				                              AND   LIC_BOL_MNEMONICO IN ('MEC','COL','DVL')
                                      AND   LIC_TIPO_OPERACION = 'C'
                                      AND   NVL(LIC_ESTADO,'A') != 'G'
                                      AND   ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
 				                                      AND   LIC_FECHA_CUMPLIMIENTO != LIC_FECHA_OPERACION
                                              AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
				                                      AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE))
                                             OR
                                             (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                                              AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
                                              AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) <= TRUNC(SYSDATE)))
				                              AND   ((LIC_TIPO_OFERTA NOT IN ('3','4')
                                              AND EXISTS (SELECT 'X'
                                                          FROM   MOVIMIENTOS_CUENTA_CORREDORES
                                                          WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                                                          AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                          AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                          AND    MCC_LIC_TIPO_OPERACION = 'C'
                                                          AND    MCC_MONTO_A_CONTADO != 0
                                                          AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'))  OR
                                             (LIC_TIPO_OFERTA IN ('3','4')
                                              AND EXISTS (SELECT 'X'
                                                          FROM   MOVIMIENTOS_CUENTA_CORREDORES
                                                          WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                                                          AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                          AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                          AND    MCC_LIC_TIPO_OPERACION = 'C'
                                                          AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'))));
   OCO1  C_OCO%ROWTYPE;

   CURSOR C_OVE IS
      -- OPERACIONES A PLAZO
      SELECT  'OPL' TIPO_CAUSACION
             ,OVE_CONSECUTIVO
             ,OVE_COC_CTO_MNEMONICO
             ,OVE_BOL_MNEMONICO
             ,OVE_CCC_CLI_PER_NUM_IDEN
             ,OVE_CCC_CLI_PER_TID_CODIGO
             ,OVE_CCC_NUMERO_CUENTA
             ,OVE_ENA_MNEMONICO
             ,OVE_TIPO_NOMINAL_O_PESOS
             ,OVE_FECHA_Y_HORA
             ,OVE_COC_CTE_MNEMONICO
             ,OVE_ORIGEN_FUNGIBLE
             ,OVE_TLO_CODIGO
             ,OVE_CFC_FUG_ISI_MNEMONICO
             ,OVE_CFC_FUG_MNEMONICO
             ,OVE_CFC_CUENTA_DECEVAL
             ,OVE_PER_NUM_IDEN
             ,OVE_PER_TID_CODIGO
             ,OVE_MONEDA_COMPENSACION
             ,OVE_ABONO_CUENTA
      FROM ORDENES_VENTA
      WHERE ( OVE_CONSECUTIVO
             ,OVE_COC_CTO_MNEMONICO
				     ,OVE_BOL_MNEMONICO) IN (SELECT  LIC_OVE_CONSECUTIVO
				                                    ,LIC_OVE_COC_CTO_MNEMONICO
                                            ,LIC_BOL_MNEMONICO
				                             FROM  LIQUIDACIONES_COMERCIAL
				                             WHERE LIC_ELI_MNEMONICO = 'OPL'
                                             AND   LIC_BOL_MNEMONICO IN ('MEC','COL','DVL')
                                             AND   LIC_TIPO_OPERACION = 'V'
                                             AND   NVL(LIC_ESTADO,'A') != 'G'
                                             AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
                                             AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE)
                                             AND   NOT EXISTS (SELECT 'X'
                                                               FROM VW_LIQUIDACIONES_NO_CAUSADAS
                                                               WHERE LNOC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                                 AND LNOC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                                 AND LNOC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                                                                 AND LNOC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO))
      UNION ALL
      SELECT  'CON' TIPO_CAUSACION
             ,OVE_CONSECUTIVO
             ,OVE_COC_CTO_MNEMONICO
             ,OVE_BOL_MNEMONICO
             ,OVE_CCC_CLI_PER_NUM_IDEN
             ,OVE_CCC_CLI_PER_TID_CODIGO
             ,OVE_CCC_NUMERO_CUENTA
             ,OVE_ENA_MNEMONICO
             ,OVE_TIPO_NOMINAL_O_PESOS
             ,OVE_FECHA_Y_HORA
             ,OVE_COC_CTE_MNEMONICO
             ,OVE_ORIGEN_FUNGIBLE
             ,OVE_TLO_CODIGO
             ,OVE_CFC_FUG_ISI_MNEMONICO
             ,OVE_CFC_FUG_MNEMONICO
             ,OVE_CFC_CUENTA_DECEVAL
             ,OVE_PER_NUM_IDEN
             ,OVE_PER_TID_CODIGO
             ,OVE_MONEDA_COMPENSACION
             ,OVE_ABONO_CUENTA
      FROM ORDENES_VENTA
      WHERE ( OVE_CONSECUTIVO
				     ,OVE_COC_CTO_MNEMONICO
				     ,OVE_BOL_MNEMONICO) IN (SELECT  LIC_OVE_CONSECUTIVO
				                                    ,LIC_OVE_COC_CTO_MNEMONICO
				                                    ,LIC_BOL_MNEMONICO
				                             FROM  LIQUIDACIONES_COMERCIAL
				                             WHERE LIC_ELI_MNEMONICO != 'OPL'
                                             AND   LIC_TIPO_OPERACION = 'V'
                                             AND   NVL(LIC_ESTADO,'A') != 'G'
                                             -- PARA VENTAS: SE EXCLUYEN LOS NEMOS QUE NO SE DEBEN CAUSAR
                                             AND   NOT EXISTS (SELECT 'X'
                                                               FROM VW_LIQUIDACIONES_NO_CAUSADAS
                                                               WHERE LNOC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                                 AND LNOC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                                 AND LNOC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                                                                 AND LNOC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO)
                                             AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
                                                           AND   LIC_FECHA_CUMPLIMIENTO != LIC_FECHA_OPERACION
                                                           AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
                                                           AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE))
                                                  OR
                                                 (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                                                  AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
                                                  AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) <= TRUNC(SYSDATE)))
                                             AND  ((LIC_TIPO_OFERTA NOT IN ('3','4')
                                                    AND EXISTS (SELECT 'X'
                                                                FROM   MOVIMIENTOS_CUENTA_CORREDORES
                                                                WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                                                                AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                                AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                                AND    MCC_LIC_TIPO_OPERACION = 'V'
                                                                AND    MCC_MONTO_A_CONTADO != 0
                                                                AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'))  OR
                                                   (LIC_TIPO_OFERTA IN ('3','4')
                                             AND EXISTS (SELECT 'X'
                                                        FROM   MOVIMIENTOS_CUENTA_CORREDORES
                                                        WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                                                        AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                        AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                        AND    MCC_LIC_TIPO_OPERACION = 'V'
                                                        AND    MCC_MONTO_A_CONTADO != 0
                                                        AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'))  OR
                                           (LIC_TIPO_OFERTA IN ('3','4')
                                            AND EXISTS (SELECT 'X'
                                                        FROM   MOVIMIENTOS_CUENTA_CORREDORES
                                                        WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                                                        AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                                                        AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                                                        AND    MCC_LIC_TIPO_OPERACION = 'V'
                                                        AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'))));
   OVE1  C_OVE%ROWTYPE;

   CURSOR C_LIC_COMPRA ( P_BOL        ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
                        ,P_OCO        ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
                        ,P_CTO        ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
                        ,P_TIPO_CAUSA VARCHAR2) IS
      SELECT  LIC_BOL_MNEMONICO
             ,LIC_NUMERO_OPERACION
             ,LIC_NUMERO_FRACCION
             ,LIC_TIPO_OPERACION
             ,LIC_FECHA_OPERACION
             ,LIC_TIPO_OFERTA
      FROM LIQUIDACIONES_COMERCIAL
      WHERE 'OPL' = P_TIPO_CAUSA
      AND   LIC_TIPO_OPERACION = 'C'
			AND   LIC_ELI_MNEMONICO = 'OPL'
      AND   NVL(LIC_ESTADO,'A') != 'G'
      AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
			AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE)
			AND   LIC_BOL_MNEMONICO         = P_BOL
      AND   LIC_OCO_CONSECUTIVO       = P_OCO
      AND   LIC_OCO_COC_CTO_MNEMONICO = P_CTO
      UNION ALL
      SELECT  LIC_BOL_MNEMONICO
             ,LIC_NUMERO_OPERACION
             ,LIC_NUMERO_FRACCION
             ,LIC_TIPO_OPERACION
             ,LIC_FECHA_OPERACION
             ,LIC_TIPO_OFERTA
      FROM LIQUIDACIONES_COMERCIAL
      WHERE 'CON' = P_TIPO_CAUSA
      AND   LIC_ELI_MNEMONICO = 'APL'
      AND   LIC_TIPO_OPERACION = 'C'
      AND   NVL(LIC_ESTADO,'A') != 'G'
      AND   ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
 			        AND   LIC_FECHA_CUMPLIMIENTO != LIC_FECHA_OPERACION
              AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
			        AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE))
             OR
             (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
              AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
              AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) <= TRUNC(SYSDATE)))
			 	      AND   EXISTS (SELECT 'X'
 				                    FROM   MOVIMIENTOS_CUENTA_CORREDORES
 				                    WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                            AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                            AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                            AND    MCC_LIC_TIPO_OPERACION = 'C'
				                    AND    MCC_MONTO_A_CONTADO != 0
				                    AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
                            --AND    (NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N')
                            --        OR LIC_TIPO_OFERTA IN ('3','4') 
                            )
			AND LIC_BOL_MNEMONICO         = P_BOL
      AND LIC_OCO_CONSECUTIVO       = P_OCO
      AND LIC_OCO_COC_CTO_MNEMONICO = P_CTO;
   LIC1 C_LIC_COMPRA%ROWTYPE;

   CURSOR C_LIC_VENTA ( P_BOL        ORDENES_VENTA.OVE_BOL_MNEMONICO%TYPE
                       ,P_OVE        ORDENES_VENTA.OVE_CONSECUTIVO%TYPE
                       ,P_CTO        ORDENES_VENTA.OVE_COC_CTO_MNEMONICO%TYPE
                       ,P_TIPO_CAUSA VARCHAR2) IS
      SELECT  LIC_BOL_MNEMONICO
             ,LIC_NUMERO_OPERACION
             ,LIC_NUMERO_FRACCION
             ,LIC_TIPO_OPERACION
             ,LIC_FECHA_OPERACION
             ,LIC_VOLUMEN_FRACCION
             ,LIC_TIPO_OFERTA
      FROM LIQUIDACIONES_COMERCIAL
      WHERE 'OPL' = P_TIPO_CAUSA
      AND   LIC_TIPO_OPERACION = 'V'
      AND   LIC_ELI_MNEMONICO = 'OPL'
      AND   NVL(LIC_ESTADO,'A') != 'G'
      AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
			AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE)
      -- PARA VENTAS: SE EXCLUYEN LOS NEMOS QUE NO SE DEBEN CAUSAR
      AND   NOT EXISTS (SELECT 'X'
                        FROM VW_LIQUIDACIONES_NO_CAUSADAS
                        WHERE LNOC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND LNOC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND LNOC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND LNOC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO)
			AND   LIC_BOL_MNEMONICO         = P_BOL
      AND   LIC_OVE_CONSECUTIVO       = P_OVE
      AND   LIC_OVE_COC_CTO_MNEMONICO = P_CTO
      UNION ALL
      SELECT  LIC_BOL_MNEMONICO
             ,LIC_NUMERO_OPERACION
             ,LIC_NUMERO_FRACCION
             ,LIC_TIPO_OPERACION
             ,LIC_FECHA_OPERACION
             ,LIC_VOLUMEN_FRACCION
             ,LIC_TIPO_OFERTA
      FROM LIQUIDACIONES_COMERCIAL
      WHERE 'CON' = P_TIPO_CAUSA
      AND  LIC_ELI_MNEMONICO = 'APL'
      AND  LIC_TIPO_OPERACION = 'V'
      AND  NVL(LIC_ESTADO,'A') != 'G'
      -- PARA VENTAS: SE EXCLUYEN LOS NEMOS QUE NO SE DEBEN CAUSAR
      AND   NOT EXISTS (SELECT 'X'
                        FROM VW_LIQUIDACIONES_NO_CAUSADAS
                        WHERE LNOC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND LNOC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND LNOC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND LNOC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO)
      AND  ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
 			       AND   LIC_FECHA_CUMPLIMIENTO != LIC_FECHA_OPERACION
			       AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
			       AND   TRUNC(LIC_FECHA_CUMPLIMIENTO) <= TRUNC(SYSDATE))
            OR
            (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
			       AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) >= TRUNC(SYSDATE) - 365
             AND   TRUNC(LIC_FECHA_PACTO_CUMPLIMIENTO) <= TRUNC(SYSDATE)))
			AND    EXISTS (SELECT 'X'
 			               FROM   MOVIMIENTOS_CUENTA_CORREDORES
			               WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                     AND    MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                     AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                     AND    MCC_LIC_TIPO_OPERACION = 'V'
			               AND    MCC_MONTO_A_CONTADO != 0
			               AND    NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
                     --AND    (NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N')
                     --        OR LIC_TIPO_OFERTA IN ('3','4')            
                     ) 
			AND LIC_BOL_MNEMONICO         = P_BOL
      AND LIC_OVE_CONSECUTIVO       = P_OVE
      AND LIC_OVE_COC_CTO_MNEMONICO = P_CTO;

   LIC2 C_LIC_VENTA%ROWTYPE;

 	 CURSOR C_MVTOS ( P_BOL   LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                   ,P_OP    LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                   ,P_FR    LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                   ,P_TIPO  LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE) IS
   SELECT 'X'
   FROM   MOVIMIENTOS_CUENTA_CORREDORES
   WHERE  NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
   AND    MCC_LIC_BOL_MNEMONICO = P_BOL
   AND    MCC_LIC_NUMERO_OPERACION = P_OP
   AND    MCC_LIC_NUMERO_FRACCION  = P_FR
   AND    MCC_LIC_TIPO_OPERACION   = P_TIPO;
   COND           VARCHAR2(1);

   CURSOR C_SIN_RADICADO (nOVE_CONSECUTIVO NUMBER) IS
   SELECT ODP_CONSECUTIVO, ODP_ESTADO, ODP_SOPORTE_FISICO, ODP_RADICADO_WM,
          ODP_TPA_MNEMONICO, ODP_VA_H2H, ODP_CALL_BACK, ODP_PAGAR_A, ODP_CALL_BACK_REALIZADA
   FROM   ORDENES_DE_PAGO 
   WHERE  ODP_OVE_CONSECUTIVO = nOVE_CONSECUTIVO
   AND    ODP_ESTADO IN ('COL','APR')
   AND    ODP_TBC_CONSECUTIVO IS NULL
   AND    ODP_CGE_CONSECUTIVO IS NULL
   AND    ODP_CEG_CONSECUTIVO IS NULL
   AND    ODP_TCC_CONSECUTIVO IS NULL;


   EXCEP_YA_CAUSO     EXCEPTION;
   EXCEP_YA_CAUSO_VTA EXCEPTION;
   ERRORSQL           VARCHAR2(350);
   APLICA_OP          VARCHAR2(1);
   PAGADA             VARCHAR2(1);
   NETO_GIRAR         NUMBER;
   TOTAL_GIRADO       NUMBER;
   nOrdenPago         ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
   cRequiere          VARCHAR2(1):='N';
   cODPEstado         ORDENES_DE_PAGO.ODP_ESTADO%TYPE;
   cRetirofondo       ORDENES_COMPRA.OCO_COBRAR_RETIRO_PARCIAL%TYPE;
   cIncrementoFondo   ORDENES_VENTA.OVE_INCREMENTO_FONDO%TYPE;
   cOCONoRegistraInstruccion ORDENES_COMPRA.OCO_NO_REGISTRA_INSTRUCCION%TYPE;
   cOVENoRegistraInstruccion ORDENES_VENTA.OVE_NO_REGISTRA_INSTRUCCION%TYPE;
   cSoporteFisico     ORDENES_DE_PAGO.ODP_SOPORTE_FISICO%TYPE;
   cRadicado          ORDENES_DE_PAGO.ODP_RADICADO_WM%TYPE;

BEGIN

	 -- CAUSACION OPERACIONES DE COMPRA
   OPEN C_OCO;
   FETCH C_OCO INTO OCO1;
   WHILE C_OCO%FOUND LOOP
   	  APLICA_OP := 'S';
   	  OPEN C_LIC_COMPRA ( OCO1.OCO_BOL_MNEMONICO
                         ,OCO1.OCO_CONSECUTIVO
                         ,OCO1.OCO_COC_CTO_MNEMONICO
                         ,OCO1.TIPO_CAUSACION);
   	  FETCH C_LIC_COMPRA INTO LIC1;
   	  WHILE C_LIC_COMPRA%FOUND LOOP
        BEGIN
          SELECT OCO_COBRAR_RETIRO_PARCIAL, OCO_NO_REGISTRA_INSTRUCCION
          INTO   cRetiroFondo, cOCONoRegistraInstruccion
          FROM   ORDENES_COMPRA
          WHERE  OCO_CONSECUTIVO = OCO1.OCO_CONSECUTIVO;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
               cRetiroFondo := 'N';
        END;  

        ---24/05/2020 invocar el correo si no tiene instruccion
        IF cOCONoRegistraInstruccion = 'S' THEN
           P_INSTRUCCIONES_ORDEN.PR_NOTIFICA_OCO_SIN_INSTRUC(LIC1.LIC_NUMERO_OPERACION);
        END IF;
          IF cRetiroFondo = 'S' THEN
             P_INSTRUCCIONES_ORDEN.PR_GENERA_ORDENES_FONDO_C(LIC1.LIC_NUMERO_OPERACION);
          END IF; 
        --
   	  	 APLICA_OP := P_OPERACIONES.VALIDA_DIVISAS( 'C'
                                                   ,OCO1.OCO_CONSECUTIVO
                                                   ,OCO1.OCO_COC_CTO_MNEMONICO
                                                   ,OCO1.OCO_BOL_MNEMONICO
                                                   ,OCO1.OCO_MONEDA_COMPENSACION
                                                   ,OCO1.OCO_CCC_CLI_PER_NUM_IDEN
                                                   ,OCO1.OCO_CCC_CLI_PER_TID_CODIGO
                                                   ,OCO1.OCO_CCC_NUMERO_CUENTA
                                                   ,LIC1.LIC_BOL_MNEMONICO
                                                   ,LIC1.LIC_NUMERO_OPERACION
                                                   ,LIC1.LIC_NUMERO_FRACCION
                                                   ,LIC1.LIC_TIPO_OPERACION
                                                   ,LIC1.LIC_FECHA_OPERACION
                                                  );
         IF APLICA_OP = 'S' THEN
            COND := NULL;
            OPEN C_MVTOS( OCO1.OCO_BOL_MNEMONICO
                         ,LIC1.LIC_NUMERO_OPERACION
                         ,LIC1.LIC_NUMERO_FRACCION
                         ,'C');
            FETCH C_MVTOS INTO COND;
            CLOSE C_MVTOS;
            IF NVL(COND,' ') = ' ' THEN
               RAISE EXCEP_YA_CAUSO;
            END IF;
            P_OPERACIONES.ACTUALIZAR_SALDO_C( P_TIPO_CAUSACION => OCO1.TIPO_CAUSACION,
                                           P_OCO_CONS       => OCO1.OCO_CONSECUTIVO,
                                           P_OCO_CTO        => OCO1.OCO_COC_CTO_MNEMONICO,
                                           P_OCO_BOL        => OCO1.OCO_BOL_MNEMONICO,
                                           TIPOPE           => 'C',
                                           P_NUMID          => OCO1.OCO_CCC_CLI_PER_NUM_IDEN,
                                           P_TIPID          => OCO1.OCO_CCC_CLI_PER_TID_CODIGO,
                                           P_CTANUM         => OCO1.OCO_CCC_NUMERO_CUENTA,
                                           P_MON_C          => OCO1.OCO_MONEDA_COMPENSACION,
                                           P_LIC_BOL        => LIC1.LIC_BOL_MNEMONICO,
                                           P_LIC_OP         => LIC1.LIC_NUMERO_OPERACION,
                                           P_LIC_FR         => LIC1.LIC_NUMERO_FRACCION,
                                           P_LIC_TIPO       => LIC1.LIC_TIPO_OPERACION,
                                           P_FECHA_OP       => LIC1.LIC_FECHA_OPERACION);
   	     END IF;
   	     FETCH C_LIC_COMPRA INTO LIC1;
   	  END LOOP;
   	  CLOSE C_LIC_COMPRA;
   	  COMMIT;
      FETCH C_OCO INTO OCO1;
   END LOOP;
   CLOSE C_OCO;

	 -- CAUSACION OPERACIONES DE VENTA
   OPEN C_OVE;
   FETCH C_OVE INTO OVE1;
   WHILE C_OVE%FOUND LOOP
   	  APLICA_OP := 'S';
   	  OPEN C_LIC_VENTA (  OVE1.OVE_BOL_MNEMONICO
                         ,OVE1.OVE_CONSECUTIVO
                         ,OVE1.OVE_COC_CTO_MNEMONICO
                         ,OVE1.TIPO_CAUSACION);
   	  FETCH C_LIC_VENTA INTO LIC2;
   	  WHILE C_LIC_VENTA%FOUND LOOP
        BEGIN
          SELECT OVE_INCREMENTO_FONDO, OVE_NO_REGISTRA_INSTRUCCION
          INTO   cIncrementoFondo, cOVENoRegistraInstruccion
          FROM   ORDENES_VENTA
          WHERE  OVE_CONSECUTIVO = OVE1.OVE_CONSECUTIVO;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
             cIncrementoFondo := 'N';
        END;
        ---24/05/2020 invocar el correo si no tiene instruccion
        IF cOVENoRegistraInstruccion = 'S' THEN
           P_INSTRUCCIONES_ORDEN.PR_NOTIFICA_OVE_SIN_INSTRUC(LIC2.LIC_NUMERO_OPERACION);
        END IF;
        --Buscamos si la operacion de venta tiene una orden de pago que teniendo ODP_SOPORTE_FISICO en S
        --el campo ODP_RADICADO_WM no tiene asignado un valor
        FOR SIN IN C_SIN_RADICADO (OVE1.OVE_CONSECUTIVO) LOOP
          IF SIN.ODP_SOPORTE_FISICO = 'S' AND SIN.ODP_RADICADO_WM IS NULL THEN
             P_INSTRUCCIONES_ORDEN.PR_NOTIFICA_SOPORTE_FISICO_OP(SIN.ODP_CONSECUTIVO, cRequiere);
          END IF;
---
              IF SIN.ODP_TPA_MNEMONICO = 'TRB' THEN
                BEGIN
                     P_VALIDA_VCB.PR_VALIDA_NO_ACH(SIN.ODP_CONSECUTIVO);
                EXCEPTION
                  WHEN OTHERS THEN
                      DBMS_OUTPUT.PUT_LINE('Error al invocar P_VALIDA_VCB.PR_VALIDA_NO_ACH para el consecutivo de la Orden de Pago '||' '||SIN.ODP_CONSECUTIVO||' '||SQLERRM);
                END;
              ELSIF SIN.ODP_TPA_MNEMONICO IN ('CHE','CHG','PSE','TCC') THEN
                BEGIN
                     P_VALIDA_VCB.PR_VALIDA_OTROS(SIN.ODP_CONSECUTIVO);
                EXCEPTION
                  WHEN OTHERS THEN
                      DBMS_OUTPUT.put_line('Error al invocar P_VALIDA_VCB.PR_VALIDA_OTROS para el consecutivo de la Orden de Pago '||' '||SIN.ODP_CONSECUTIVO||' '||SQLERRM);
                END;  
              END IF; 

---
          IF SIN.ODP_ESTADO = 'COL' THEN
             UPDATE ORDENES_DE_PAGO SET ODP_ESTADO = 'APR'
                                    WHERE ODP_CONSECUTIVO = SIN.ODP_CONSECUTIVO;
          END IF;
        END LOOP;
        ---

          IF cIncrementoFondo = 'S' THEN
             P_INSTRUCCIONES_ORDEN.PR_GENERA_ORDENES_FONDO_V(LIC2.LIC_NUMERO_OPERACION);
          END IF;
        --
             APLICA_OP := P_OPERACIONES.VALIDA_DIVISAS( 'V'
                                                       ,OVE1.OVE_CONSECUTIVO
                                                       ,OVE1.OVE_COC_CTO_MNEMONICO
                                                       ,OVE1.OVE_BOL_MNEMONICO
                                                       ,OVE1.OVE_MONEDA_COMPENSACION
                                                       ,OVE1.OVE_CCC_CLI_PER_NUM_IDEN
                                                       ,OVE1.OVE_CCC_CLI_PER_TID_CODIGO
                                                       ,OVE1.OVE_CCC_NUMERO_CUENTA
                                                       ,LIC2.LIC_BOL_MNEMONICO
                                                       ,LIC2.LIC_NUMERO_OPERACION
                                                       ,LIC2.LIC_NUMERO_FRACCION
                                                       ,LIC2.LIC_TIPO_OPERACION
                                                       ,LIC2.LIC_FECHA_OPERACION
                                                      );
             IF APLICA_OP = 'S' THEN
                COND := NULL;
                OPEN C_MVTOS( OVE1.OVE_BOL_MNEMONICO
                             ,LIC2.LIC_NUMERO_OPERACION
                             ,LIC2.LIC_NUMERO_FRACCION
                             ,'V');
                FETCH C_MVTOS INTO COND;
                CLOSE C_MVTOS;
                IF NVL(COND,' ') = ' ' THEN
                   RAISE EXCEP_YA_CAUSO_VTA;
                END IF;

                P_OPERACIONES.ACTUALIZAR_SALDO_V( P_TIPO_CAUSACION => OVE1.TIPO_CAUSACION,
                                                  P_OVE_CONS       => OVE1.OVE_CONSECUTIVO,
                                                  P_OVE_CTO        => OVE1.OVE_COC_CTO_MNEMONICO,
                                                  P_OVE_BOL        => OVE1.OVE_BOL_MNEMONICO,
                                                  TIPOPE           => 'V',
                                                  P_NUMID          => OVE1.OVE_CCC_CLI_PER_NUM_IDEN,
                                                  P_TIPID          => OVE1.OVE_CCC_CLI_PER_TID_CODIGO,
                                                  P_CTANUM         => OVE1.OVE_CCC_NUMERO_CUENTA,
                                                  P_MON_C          => OVE1.OVE_MONEDA_COMPENSACION,
                                                  P_LIC_BOL        => LIC2.LIC_BOL_MNEMONICO,
                                                  P_LIC_OP         => LIC2.LIC_NUMERO_OPERACION,
                                                  P_LIC_FR         => LIC2.LIC_NUMERO_FRACCION,
                                                  P_LIC_TIPO       => LIC2.LIC_TIPO_OPERACION,
                                                  P_FECHA_OP       => LIC2.LIC_FECHA_OPERACION);

                IF NVL(OVE1.OVE_MONEDA_COMPENSACION,'N') = 'U' THEN
                   UPDATE LIQUIDACIONES_COMERCIAL
                   SET    LIC_PAGADA = 'S'
                         ,LIC_NETO_A_GIRAR = LIC2.LIC_VOLUMEN_FRACCION
                         ,LIC_FALTANTE_A_GIRAR = 0
                   WHERE  LIC_NUMERO_OPERACION = LIC2.LIC_NUMERO_OPERACION
                   AND    LIC_NUMERO_FRACCION = LIC2.LIC_NUMERO_FRACCION
                   AND    LIC_TIPO_OPERACION = LIC2.LIC_TIPO_OPERACION
                   AND    LIC_BOL_MNEMONICO = LIC2.LIC_BOL_MNEMONICO;
                ELSE
                   IF OVE1.OVE_ABONO_CUENTA = 'S' THEN
                      P_OPERACIONES.PR_TOTAL_CARGADO_GIRADO
                         (P_LIC_NUMERO_OPERACION   => LIC2.LIC_NUMERO_OPERACION
                         ,P_LIC_NUMERO_FRACCION    => LIC2.LIC_NUMERO_FRACCION
                         ,P_LIC_TIPO_OPERACION     => LIC2.LIC_TIPO_OPERACION
                         ,P_LIC_BOL_MNEMONICO      => LIC2.LIC_BOL_MNEMONICO
                         ,P_CCC_CLI_PER_NUM_IDEN   => OVE1.OVE_CCC_CLI_PER_NUM_IDEN
                         ,P_CCC_CLI_PER_TID_CODIGO => OVE1.OVE_CCC_CLI_PER_TID_CODIGO
                         ,P_CCC_NUMERO_CUENTA      => OVE1.OVE_CCC_NUMERO_CUENTA
                         ,P_PAGADA                 => PAGADA
                         ,P_NETO_GIRAR             => NETO_GIRAR
                         ,P_TOTAL_GIRADO           => TOTAL_GIRADO);

                      UPDATE LIQUIDACIONES_COMERCIAL
                      SET    LIC_PAGADA = PAGADA
                            ,LIC_NETO_A_GIRAR = NETO_GIRAR
                            ,LIC_FALTANTE_A_GIRAR = NETO_GIRAR - TOTAL_GIRADO
                      WHERE  LIC_NUMERO_OPERACION = LIC1.LIC_NUMERO_OPERACION
                      AND    LIC_NUMERO_FRACCION = LIC1.LIC_NUMERO_FRACCION
                      AND    LIC_TIPO_OPERACION = LIC1.LIC_TIPO_OPERACION
                      AND    LIC_BOL_MNEMONICO = LIC1.LIC_BOL_MNEMONICO;
                   END IF;
                END IF;
             END IF;
             FETCH C_LIC_VENTA INTO LIC2;
   	  END LOOP;
   	  CLOSE C_LIC_VENTA;
   	  COMMIT;
      FETCH C_OVE INTO OVE1;
   END LOOP;
   CLOSE C_OVE;

EXCEPTION
   WHEN EXCEP_YA_CAUSO THEN
      ROLLBACK;
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.CAUSACION'
                     ,P_ERROR       => 'LA ORDEN DE COMPRA YA FUE CAUSADA: '||OCO1.OCO_BOL_MNEMONICO||'-'||OCO1.OCO_COC_CTO_MNEMONICO||'-'||OCO1.OCO_CONSECUTIVO
                     ,P_TABLA_ERROR => NULL);
      COMMIT;

   WHEN EXCEP_YA_CAUSO_VTA THEN
      ROLLBACK;
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.CAUSACION'
                     ,P_ERROR       => 'LA ORDEN DE VENTA YA FUE CAUSADA: '||OVE1.OVE_BOL_MNEMONICO||'-'||OVE1.OVE_COC_CTO_MNEMONICO||'-'||OVE1.OVE_CONSECUTIVO
                     ,P_TABLA_ERROR => NULL);
      COMMIT;

   WHEN OTHERS THEN
      ROLLBACK;
      errorsql := SUBSTR(SQLERRM,1,350);
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.CAUSACION'
                     ,P_ERROR       => SUBSTR('LIQUIDACION:'||OCO1.OCO_BOL_MNEMONICO||'-'||OCO1.OCO_COC_CTO_MNEMONICO||'-'||OCO1.OCO_CONSECUTIVO||'-'||ERRORSQL,1,500)
                     ,P_TABLA_ERROR => NULL);
      COMMIT;
END CAUSACION;

/*******************************************************************************************
***  Funcion para Validar si la cuenta de Divisas del cliente no tiene saldo suficiente   **
***  para cubrir la operacion de Yankkes                                                  **
***************************************************************************************** */
FUNCTION VALIDA_DIVISAS (TIPO_OP        IN VARCHAR2
                        ,P_CONS         ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
                        ,P_CTO          ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
                        ,P_BOL          ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
                        ,P_MONEDA       ORDENES_COMPRA.OCO_MONEDA_COMPENSACION%TYPE
                        ,P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
                        ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
                        ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
                        ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                        ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                        ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
                        ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
                        ,P_FECHA_OP     LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE
                        ) RETURN VARCHAR2 IS

   APLICA        VARCHAR2(1) := 'S';

   CURSOR C_CDV IS
      SELECT CDV_SALDO_RESTRINGIDO
      FROM CUENTAS_CLIENTES_DIVISAS
      WHERE CDV_CCC_CLI_PER_NUM_IDEN = P_NID
      AND   CDV_CCC_CLI_PER_TID_CODIGO = P_TID
      AND   CDV_CCC_NUMERO_CUENTA = P_CTA
      AND   CDV_BMO_MNEMONICO  = 'DOLAR';

   SALDO_R CUENTAS_CLIENTES_DIVISAS.CDV_SALDO_RESTRINGIDO%TYPE;

   CURSOR APLICADO ( BOL VARCHAR2
                    ,NUM_OP NUMBER
                    ,FRACC NUMBER
                    ,TIPO_OP VARCHAR2) IS
      SELECT LIC_VOLUMEN_FRACCION
            ,LIC_MNEMOTECNICO_TITULO
      FROM   LIQUIDACIONES_COMERCIAL
      WHERE  LIC_BOL_MNEMONICO = BOL
        AND  LIC_NUMERO_OPERACION = NUM_OP
        AND  LIC_NUMERO_FRACCION = FRACC
        AND  LIC_TIPO_OPERACION = TIPO_OP;
   LIC1   APLICADO%ROWTYPE;

   VALOR_APLICADO NUMBER;

   CURSOR TRM (FECHA DATE) IS
      SELECT CBM_VALOR
      FROM COTIZACIONES_BASE_MONETARIAS
      WHERE CBM_BMO_MNEMONICO = 'DOLAR'
        AND TRUNC(CBM_FECHA) = TRUNC(FECHA);

   CURSOR C_BASE_ESPECIE IS
      SELECT ENA_BMO_MNEMONICO
      FROM   ESPECIES_NACIONALES
      WHERE  ENA_MNEMONICO = LIC1.LIC_MNEMOTECNICO_TITULO;
   ENA1   C_BASE_ESPECIE%ROWTYPE;

   VALOR_TRM     NUMBER;
   MOVIMIENTO    VARCHAR2(6);
   VALOR         NUMBER;
   NO_TRM        EXCEPTION;
BEGIN
   APLICA := 'S';
   -- VALIDA SI SE CAUSA LA ORDEN DE YANKEES
   OPEN C_CDV;
   FETCH C_CDV INTO SALDO_R;
   IF C_CDV%NOTFOUND THEN
      SALDO_R := 0;
   END IF;
   CLOSE C_CDV;
   SALDO_R := NVL(SALDO_R,0);

   IF TIPO_OP = 'C' THEN
      IF NVL(P_MONEDA,'N') = 'U' THEN
         VALOR_APLICADO := 0;
         VALOR := 0;
         OPEN APLICADO(P_LIC_BOL,P_LIC_OP,P_LIC_FR,P_LIC_TIPO);
         FETCH APLICADO INTO LIC1;
         CLOSE APLICADO;

         OPEN C_BASE_ESPECIE;
         FETCH C_BASE_ESPECIE INTO ENA1;
         CLOSE C_BASE_ESPECIE;

         -- Se permite causar movimientos ya sean en especies con bases monetarios pesos y dolares
         IF NVL(ENA1.ENA_BMO_MNEMONICO,'PESOS') IN ('DOLAR', 'PESOS') THEN
            VALOR_APLICADO := NVL(LIC1.LIC_VOLUMEN_FRACCION,0)* (-1);

            OPEN TRM(P_FECHA_OP);
            FETCH TRM INTO VALOR_TRM;
            IF TRM%NOTFOUND THEN
               RAISE NO_TRM;
            END IF;
            CLOSE TRM;
            VALOR_TRM := NVL(VALOR_TRM,0);
            VALOR := VALOR_APLICADO;
            IF VALOR_TRM != 0 AND VALOR != 0 THEN
               VALOR := ROUND(VALOR/VALOR_TRM,2);
               IF  SALDO_R + VALOR < 0 THEN
                  APLICA := 'N';
               END IF;
            END IF;
         END IF;
      END IF;
   ELSIF TIPO_OP = 'V' THEN
      IF NVL(P_MONEDA,'N') = 'U' THEN
         VALOR_APLICADO := 0;
         VALOR := 0;
         OPEN APLICADO(P_LIC_BOL ,P_LIC_OP ,P_LIC_FR ,P_LIC_TIPO);
         FETCH APLICADO INTO LIC1;
         CLOSE APLICADO;

         VALOR_APLICADO := NVL(LIC1.LIC_VOLUMEN_FRACCION,0);

         OPEN C_BASE_ESPECIE;
         FETCH C_BASE_ESPECIE INTO ENA1;
         CLOSE C_BASE_ESPECIE;

         IF NVL(ENA1.ENA_BMO_MNEMONICO, ' ') IN ('DOLAR', 'PESOS') THEN
            OPEN TRM(P_FECHA_OP);
            FETCH TRM INTO VALOR_TRM;
            IF TRM%NOTFOUND THEN
               RAISE NO_TRM;
            END IF;
            CLOSE TRM;
            VALOR_TRM := NVL(VALOR_TRM,0);
            VALOR := VALOR_APLICADO;

            IF VALOR_TRM != 0 AND VALOR != 0 THEN
               VALOR := ROUND(VALOR/VALOR_TRM,2);

               IF  SALDO_R + VALOR < 0 THEN
                  APLICA := 'N';
               END IF;
            END IF;
         END IF;
      END IF;
   END IF;
   RETURN(NVL(APLICA,'N'));
EXCEPTION
   WHEN NO_TRM THEN
      RETURN('N');

   WHEN OTHERS THEN
      RETURN('N');

END VALIDA_DIVISAS;


/*******************************************************************************************
***  Procedimiento para Actualizar el saldo de los clientes que causan Ordenes de Compra  **
***************************************************************************************** */
PROCEDURE ACTUALIZAR_SALDO_C( P_TIPO_CAUSACION   IN VARCHAR2
                             ,P_OCO_CONS   ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
                             ,P_OCO_CTO    ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
                             ,P_OCO_BOL    ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
				   				           ,TIPOPE       IN VARCHAR2
				                     ,P_NUMID      CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
				                     ,P_TIPID      CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
				                     ,P_CTANUM     CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
				                     ,P_MON_C      ORDENES_COMPRA.OCO_MONEDA_COMPENSACION%TYPE
                             ,P_LIC_BOL    LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                             ,P_LIC_OP     LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                             ,P_LIC_FR     LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
                             ,P_LIC_TIPO   LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
                             ,P_FECHA_OP   LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE
                             ) IS

   CURSOR CAUSAR_OPEPLAZO_C IS
      SELECT SUM(MCC_MONTO_A_PLAZO) MONTO_A_CAUSAR
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
      AND    MCC_LIC_BOL_MNEMONICO = P_LIC_BOL
      AND    MCC_LIC_NUMERO_OPERACION = P_LIC_OP
      AND    MCC_LIC_NUMERO_FRACCION = P_LIC_FR
      AND    MCC_LIC_TIPO_OPERACION = P_LIC_TIPO;

   CURSOR CAUSAR_OPECONTADO_C IS
      SELECT SUM(MCC_MONTO_A_CONTADO) MONTO_A_CAUSAR
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
      AND    MCC_LIC_BOL_MNEMONICO = P_LIC_BOL
      AND    MCC_LIC_NUMERO_OPERACION = P_LIC_OP
      AND    MCC_LIC_NUMERO_FRACCION = P_LIC_FR
      AND    MCC_LIC_TIPO_OPERACION = P_LIC_TIPO;

  CURSOR MVTOS_C (BOL VARCHAR2,OPE NUMBER,FRA NUMBER,TIP VARCHAR2) IS
     SELECT MCC_FECHA
           ,MCC_CONSECUTIVO
     FROM   MOVIMIENTOS_CUENTA_CORREDORES
     WHERE  NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
     AND    MCC_LIC_BOL_MNEMONICO = BOL
     AND    MCC_LIC_NUMERO_OPERACION = OPE
     AND    MCC_LIC_NUMERO_FRACCION  = FRA
     AND    MCC_LIC_TIPO_OPERACION   = TIP;

  CURSOR C_LIQUIDACION IS
     SELECT DECODE(LIC_TIPO_OPERACION,'C', LIC_OCO_COC_CTO_MNEMONICO
                                     ,'V', LIC_OVE_COC_CTO_MNEMONICO)
     FROM LIQUIDACIONES_COMERCIAL
     WHERE LIC_NUMERO_OPERACION = P_LIC_OP
     AND LIC_NUMERO_FRACCION = P_LIC_FR
     AND LIC_TIPO_OPERACION = P_LIC_TIPO
     AND LIC_BOL_MNEMONICO = P_LIC_BOL;

   ERRORSQL VARCHAR2(350);
   V_TIPO_RENTA   VARCHAR2(5);

   CURSOR C_FIC IS
      SELECT 'S'
      FROM   CLIENTES_FICS_INTERMEDIARIOS
      WHERE  CFIC_CLI_PER_NUM_IDEN = P_NUMID
      AND    CFIC_CLI_PER_TID_CODIGO = P_TIPID
	  AND    CFIC_CUSTODIO           = 'S';
   V_FIC VARCHAR2(1);

   -- CALCULA EL VALOR DE LA OPERACION EN EL CASO DE UNA COMPRA
   CURSOR C_LIC IS
      SELECT ((LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE) +
              (LIC_VALOR_COMISION * P_WEB_EXTRACTO.PORCENTAJE_IVA_LIC (LIC_NIT_1,LIC_TIPO_IDENTIFICACION_1,LIC_FECHA_OPERACION))
             ) + (DECODE(NVL(LIC_VALOR_EXTEMPO,0),0,0,NULL,0,
                  DECODE(LIC_POSICION_EXTEMPO,'A',-LIC_VALOR_EXTEMPO,'S',LIC_VALOR_EXTEMPO,0))) MONTO
      FROM  LIQUIDACIONES_COMERCIAL
      WHERE LIC_NUMERO_OPERACION      = P_LIC_OP
      AND   LIC_NUMERO_FRACCION       = P_LIC_FR
      AND   LIC_BOL_MNEMONICO         = P_LIC_BOL
      AND   LIC_TIPO_OPERACION        = P_LIC_TIPO
      AND   LIC_NIT_1                 = P_NUMID
      AND   LIC_TIPO_IDENTIFICACION_1 = P_TIPID;

  CURSOR C_OPERACION IS
     SELECT LIC_TIPO_OFERTA
     FROM LIQUIDACIONES_COMERCIAL
     WHERE LIC_NUMERO_OPERACION = P_LIC_OP
     AND LIC_NUMERO_FRACCION = P_LIC_FR
     AND LIC_TIPO_OPERACION = P_LIC_TIPO
     AND LIC_BOL_MNEMONICO = P_LIC_BOL;

   V_VALOR_OP    NUMBER(22,2);
   V_OPERACION   VARCHAR2(1);

BEGIN
-- MES. SI EL CLIENTE ES FIC INTERMEDIARIO SE DEBE GENERAR AJUSTE
   V_FIC := 'N';
   OPEN C_FIC;
   FETCH C_FIC INTO V_FIC;
   CLOSE C_FIC;
   V_FIC := NVL(V_FIC,'N');
   -- SI ES CLIENTE FIC, TRAE EL VALOR DE LA OPERACION
   IF V_FIC = 'S' THEN
      OPEN C_LIC;
      FETCH C_LIC INTO V_VALOR_OP;
      CLOSE C_LIC;
   END IF;

   IF P_TIPO_CAUSACION = 'OPL' THEN
      FOR REG IN  CAUSAR_OPEPLAZO_C LOOP
      /* Se debe evaluar este tema para el proceso de las TTVs 2 de Febrero de 2018   
      OPEN C_OPERACION;
      FETCH C_OPERACION INTO V_OPERACION;
      CLOSE C_OPERACION;

         IF (NVL(REG.MONTO_A_CAUSAR,0) != 0 OR
             V_OPERACION = '4') THEN
       */
         IF NVL(REG.MONTO_A_CAUSAR,0) != 0 THEN
            OPEN C_LIQUIDACION;
						FETCH C_LIQUIDACION INTO V_TIPO_RENTA;
						CLOSE C_LIQUIDACION;
						V_TIPO_RENTA := NVL(V_TIPO_RENTA,' ');

            INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
               (MCC_CONSECUTIVO
               ,MCC_CCC_CLI_PER_NUM_IDEN
               ,MCC_CCC_CLI_PER_TID_CODIGO
               ,MCC_CCC_NUMERO_CUENTA
               ,MCC_FECHA
               ,MCC_TMC_MNEMONICO
               ,MCC_MONTO
               ,MCC_MONTO_A_PLAZO
               ,MCC_MONTO_A_CONTADO
               ,MCC_MONTO_BURSATIL
               ,MCC_LIC_NUMERO_OPERACION
               ,MCC_LIC_NUMERO_FRACCION
               ,MCC_LIC_TIPO_OPERACION
               ,MCC_LIC_BOL_MNEMONICO)
            VALUES
               (MCC_SEQ.NEXTVAL
               ,P_NUMID
               ,P_TIPID
               ,P_CTANUM
               ,SYSDATE
               ,'COPC'
               ,REG.MONTO_A_CAUSAR
               ,-REG.MONTO_A_CAUSAR
               ,0
               ,0
               ,P_LIC_OP
               ,P_LIC_FR
               ,P_LIC_TIPO
               ,P_LIC_BOL);

            UPDATE LIQUIDACIONES_COMERCIAL
            SET    LIC_ELI_MNEMONICO = 'OPA',
                   LIC_ESTADO = 'C'
            WHERE LIC_BOL_MNEMONICO = P_LIC_BOL
              AND LIC_NUMERO_OPERACION = P_LIC_OP
              AND LIC_NUMERO_FRACCION = P_LIC_FR
              AND LIC_TIPO_OPERACION = P_LIC_TIPO;

            FOR MOV IN MVTOS_C(P_LIC_BOL
                              ,P_LIC_OP
                              ,P_LIC_FR
                              ,P_LIC_TIPO) LOOP
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET    MCC_CAUSADO_CONT_O_PLAZO = 'S'
               WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_NUMID
               AND    MCC_CCC_CLI_PER_TID_CODIGO = P_TIPID
               AND    MCC_CCC_NUMERO_CUENTA = P_CTANUM
               AND    MCC_FECHA = MOV.MCC_FECHA
               AND    MCC_CONSECUTIVO = MOV.MCC_CONSECUTIVO;
            END LOOP;

         END IF;
         IF V_FIC = 'S' THEN
            P_OPERACIONES.PR_GENERA_AJUSTE_CFIC (
                                            P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,V_VALOR_OP);

         END IF;
         P_OPERACIONES.INSERTA_MOV_DIVISAS( 'C'
                                           ,REG.MONTO_A_CAUSAR
                                           ,P_OCO_CONS
                                           ,P_OCO_CTO
                                           ,P_OCO_BOL
                                           ,P_MON_C
                                           ,P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,P_FECHA_OP
                                           );
      END LOOP;
   ELSIF P_TIPO_CAUSACION != 'OPL' THEN
	    FOR REG IN  CAUSAR_OPECONTADO_C LOOP
          /* Se debe evaluar este tema para el proceso de las TTVs 2 de Febrero de 2018   
          OPEN C_OPERACION;
          FETCH C_OPERACION INTO V_OPERACION;
          CLOSE C_OPERACION;

         IF (NVL(REG.MONTO_A_CAUSAR,0) != 0 OR
             V_OPERACION = '4') THEN
         */ 
         IF NVL(REG.MONTO_A_CAUSAR,0) != 0 THEN
            OPEN C_LIQUIDACION;
						FETCH C_LIQUIDACION INTO V_TIPO_RENTA;
						CLOSE C_LIQUIDACION;
						V_TIPO_RENTA := NVL(V_TIPO_RENTA,' ');

            INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
               (MCC_CONSECUTIVO
               ,MCC_CCC_CLI_PER_NUM_IDEN
               ,MCC_CCC_CLI_PER_TID_CODIGO
               ,MCC_CCC_NUMERO_CUENTA
               ,MCC_FECHA
               ,MCC_TMC_MNEMONICO
               ,MCC_MONTO
               ,MCC_MONTO_A_CONTADO
               ,MCC_MONTO_A_PLAZO
               ,MCC_MONTO_BURSATIL
               ,MCC_LIC_NUMERO_OPERACION
               ,MCC_LIC_NUMERO_FRACCION
               ,MCC_LIC_TIPO_OPERACION
               ,MCC_LIC_BOL_MNEMONICO)
            VALUES
               (MCC_SEQ.NEXTVAL
               ,P_NUMID
               ,P_TIPID
               ,P_CTANUM
               ,SYSDATE
               ,'COPC'
               ,REG.MONTO_A_CAUSAR
               ,-REG.MONTO_A_CAUSAR
               ,0
               ,0
               ,P_LIC_OP
               ,P_LIC_FR
               ,P_LIC_TIPO
               ,P_LIC_BOL);

            UPDATE LIQUIDACIONES_COMERCIAL
            SET LIC_ESTADO = 'C'
            WHERE LIC_BOL_MNEMONICO = P_LIC_BOL
              AND LIC_NUMERO_OPERACION = P_LIC_OP
              AND LIC_NUMERO_FRACCION = P_LIC_FR
              AND LIC_TIPO_OPERACION = P_LIC_TIPO;

            FOR MOV IN MVTOS_C(P_LIC_BOL
                              ,P_LIC_OP
                              ,P_LIC_FR
                              ,P_LIC_TIPO) LOOP
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET    MCC_CAUSADO_CONT_O_PLAZO = 'S'
               WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_NUMID
               AND    MCC_CCC_CLI_PER_TID_CODIGO = P_TIPID
               AND    MCC_CCC_NUMERO_CUENTA = P_CTANUM
               AND    MCC_FECHA = MOV.MCC_FECHA
               AND    MCC_CONSECUTIVO = MOV.MCC_CONSECUTIVO;
            END LOOP;
         END IF;
         IF V_FIC = 'S' THEN
            P_OPERACIONES.PR_GENERA_AJUSTE_CFIC (
                                            P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,V_VALOR_OP);

         END IF;
         P_OPERACIONES.INSERTA_MOV_DIVISAS('C'
                                           ,REG.MONTO_A_CAUSAR
                                           ,P_OCO_CONS
                                           ,P_OCO_CTO
                                           ,P_OCO_BOL
                                           ,P_MON_C
                                           ,P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,P_FECHA_OP
                                           );
      END LOOP;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      errorsql := SUBSTR(SQLERRM,1,350);
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.ACTUALIZAR_SALDO_C'
                     ,P_ERROR       => SUBSTR('ORDEN:'||P_OCO_BOL||'-'||P_OCO_CTO||'-'||P_OCO_CONS||'-'||ERRORSQL,1,500)
                     ,P_TABLA_ERROR => NULL);
      COMMIT;
END ACTUALIZAR_SALDO_C;


/*******************************************************************************************
***  Procedimiento para Actualizar el saldo de los clientes que causan Ordenes de Venta   **
***************************************************************************************** */
PROCEDURE ACTUALIZAR_SALDO_V( P_TIPO_CAUSACION IN VARCHAR2,
                              P_OVE_CONS   ORDENES_VENTA.OVE_CONSECUTIVO%TYPE,
                              P_OVE_CTO    ORDENES_VENTA.OVE_COC_CTO_MNEMONICO%TYPE,
                              P_OVE_BOL    ORDENES_VENTA.OVE_BOL_MNEMONICO%TYPE,
				                      TIPOPE       IN VARCHAR2,
				                      P_NUMID      CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE,
				                      P_TIPID      CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE,
				                      P_CTANUM     CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE,
				                      P_MON_C      ORDENES_VENTA.OVE_MONEDA_COMPENSACION%TYPE,
                              P_LIC_BOL    LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE,
                              P_LIC_OP     LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE,
                              P_LIC_FR     LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE,
                              P_LIC_TIPO   LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE,
                              P_FECHA_OP   LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE) IS

   CURSOR CAUSAR_OPEPLAZO_V IS
      SELECT SUM(MCC_MONTO_A_PLAZO) MONTO_A_CAUSAR
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
      AND    MCC_LIC_BOL_MNEMONICO = P_LIC_BOL
      AND    MCC_LIC_NUMERO_OPERACION = P_LIC_OP
      AND    MCC_LIC_NUMERO_FRACCION = P_LIC_FR
      AND    MCC_LIC_TIPO_OPERACION = P_LIC_TIPO;

   CURSOR CAUSAR_OPECONTADO_V IS
      SELECT SUM(MCC_MONTO_A_CONTADO) MONTO_A_CAUSAR
      FROM   MOVIMIENTOS_CUENTA_CORREDORES
      WHERE  NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
      AND    MCC_LIC_BOL_MNEMONICO = P_LIC_BOL
      AND    MCC_LIC_NUMERO_OPERACION = P_LIC_OP
      AND    MCC_LIC_NUMERO_FRACCION = P_LIC_FR
      AND    MCC_LIC_TIPO_OPERACION = P_LIC_TIPO;

  CURSOR MVTOS_V (BOL VARCHAR2,OPE NUMBER,FRA NUMBER,TIP VARCHAR2) IS
     SELECT  MCC_FECHA
            ,MCC_CONSECUTIVO
     FROM    MOVIMIENTOS_CUENTA_CORREDORES
     WHERE   NVL(MCC_CAUSADO_CONT_O_PLAZO,'N') = 'N'
     AND     MCC_LIC_BOL_MNEMONICO = BOL
     AND     MCC_LIC_NUMERO_OPERACION = OPE
     AND     MCC_LIC_NUMERO_FRACCION = FRA
     AND     MCC_LIC_TIPO_OPERACION = TIP;

  CURSOR C_LIQUIDACION IS
     SELECT DECODE(LIC_TIPO_OPERACION,'C', LIC_OCO_COC_CTO_MNEMONICO
                                     ,'V', LIC_OVE_COC_CTO_MNEMONICO)
		 FROM LIQUIDACIONES_COMERCIAL
		 WHERE LIC_NUMERO_OPERACION = P_LIC_OP
		 AND LIC_NUMERO_FRACCION = P_LIC_FR
		 AND LIC_TIPO_OPERACION = P_LIC_TIPO
	   AND LIC_BOL_MNEMONICO = P_LIC_BOL;

   ERRORSQL VARCHAR2(350);
   V_TIPO_RENTA   VARCHAR2(5);

   -- MES
   CURSOR C_FIC IS
      SELECT 'S'
      FROM   CLIENTES_FICS_INTERMEDIARIOS
      WHERE  CFIC_CLI_PER_NUM_IDEN = P_NUMID
      AND    CFIC_CLI_PER_TID_CODIGO = P_TIPID
	  AND    CFIC_CUSTODIO           = 'S';
   V_FIC VARCHAR2(1);

    -- CALCULA EL VALOR DE LA OPERACION EN EL CASO DE UNA VENTA
   CURSOR C_LIC IS
      SELECT ((LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE) -
              (LIC_VALOR_COMISION * P_WEB_EXTRACTO.PORCENTAJE_IVA_LIC (LIC_NIT_1,LIC_TIPO_IDENTIFICACION_1,LIC_FECHA_OPERACION))
             ) + (DECODE(NVL(LIC_VALOR_EXTEMPO,0),0,0,NULL,0,
                  DECODE(LIC_POSICION_EXTEMPO,'A',-LIC_VALOR_EXTEMPO,'S',LIC_VALOR_EXTEMPO,0))) MONTO
      FROM  LIQUIDACIONES_COMERCIAL
      WHERE LIC_NUMERO_OPERACION      = P_LIC_OP
      AND   LIC_NUMERO_FRACCION       = P_LIC_FR
      AND   LIC_BOL_MNEMONICO         = P_LIC_BOL
      AND   LIC_TIPO_OPERACION        = P_LIC_TIPO
      AND   LIC_NIT_1                 = P_NUMID
      AND   LIC_TIPO_IDENTIFICACION_1 = P_TIPID;

  CURSOR C_OPERACION IS
     SELECT LIC_TIPO_OFERTA
     FROM LIQUIDACIONES_COMERCIAL
     WHERE LIC_NUMERO_OPERACION = P_LIC_OP
     AND LIC_NUMERO_FRACCION = P_LIC_FR
     AND LIC_TIPO_OPERACION = P_LIC_TIPO
     AND LIC_BOL_MNEMONICO = P_LIC_BOL;

   V_VALOR_OP NUMBER(22,2);
   V_OPERACION   VARCHAR2(1);

BEGIN
   -- MES. SI EL CLIENTE ES FIC INTERMEDIARIO SE DEBE GENERAR AJUSTE
   V_FIC := 'N';
   OPEN C_FIC;
   FETCH C_FIC INTO V_FIC;
   CLOSE C_FIC;
   V_FIC := NVL(V_FIC,'N');
   -- SI ES CLIENTE FIC, TRAE EL VALOR DE LA OPERACION
   IF V_FIC = 'S' THEN
      OPEN C_LIC;
      FETCH C_LIC INTO V_VALOR_OP;
      CLOSE C_LIC;
   END IF;

   IF P_TIPO_CAUSACION = 'OPL' THEN
      FOR REG IN CAUSAR_OPEPLAZO_V LOOP
          /* Se debe evaluar este tema para el proceso de las TTVs 2 de Febrero de 2018 
          OPEN C_OPERACION;
          FETCH C_OPERACION INTO V_OPERACION;
          CLOSE C_OPERACION;

         IF (NVL(REG.MONTO_A_CAUSAR,0) != 0 OR
            V_OPERACION = '4') THEN
         */
         IF NVL(REG.MONTO_A_CAUSAR,0) != 0 THEN
            OPEN C_LIQUIDACION;
            FETCH C_LIQUIDACION INTO V_TIPO_RENTA;
            CLOSE C_LIQUIDACION;
            V_TIPO_RENTA := NVL(V_TIPO_RENTA,' ');

            INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
               (MCC_CONSECUTIVO
               ,MCC_CCC_CLI_PER_NUM_IDEN
               ,MCC_CCC_CLI_PER_TID_CODIGO
               ,MCC_CCC_NUMERO_CUENTA
               ,MCC_FECHA
               ,MCC_TMC_MNEMONICO
               ,MCC_MONTO
               ,MCC_MONTO_A_PLAZO
               ,MCC_MONTO_A_CONTADO
               ,MCC_MONTO_BURSATIL
               ,MCC_LIC_NUMERO_OPERACION
               ,MCC_LIC_NUMERO_FRACCION
               ,MCC_LIC_TIPO_OPERACION
               ,MCC_LIC_BOL_MNEMONICO)
            VALUES
               (MCC_SEQ.NEXTVAL
               ,P_NUMID
               ,P_TIPID
               ,P_CTANUM
               ,SYSDATE
               ,'COPV'
               ,0
               ,-REG.MONTO_A_CAUSAR
               ,0
               ,REG.MONTO_A_CAUSAR
               ,P_LIC_OP
               ,P_LIC_FR
               ,P_LIC_TIPO
               ,P_LIC_BOL);

            UPDATE LIQUIDACIONES_COMERCIAL
            SET LIC_ELI_MNEMONICO = 'OPA',
                LIC_ESTADO = 'V'
            WHERE LIC_BOL_MNEMONICO = P_LIC_BOL
              AND LIC_NUMERO_OPERACION = P_LIC_OP
              AND LIC_NUMERO_FRACCION = P_LIC_FR
              AND LIC_TIPO_OPERACION = P_LIC_TIPO;

            FOR MOV IN MVTOS_V(P_LIC_BOL
                              ,P_LIC_OP
                              ,P_LIC_FR
                              ,P_LIC_TIPO) LOOP
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET    MCC_CAUSADO_CONT_O_PLAZO = 'S'
               WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_NUMID
               AND    MCC_CCC_CLI_PER_TID_CODIGO = P_TIPID
               AND    MCC_CCC_NUMERO_CUENTA = P_CTANUM
               AND    MCC_FECHA = MOV.MCC_FECHA
               AND    MCC_CONSECUTIVO = MOV.MCC_CONSECUTIVO;
            END LOOP;
         END IF;
         IF V_FIC = 'S' THEN
            P_OPERACIONES.PR_GENERA_AJUSTE_CFIC (
                                            P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,V_VALOR_OP);

         END IF;
         P_OPERACIONES.INSERTA_MOV_DIVISAS( 'V'
                                           ,REG.MONTO_A_CAUSAR
                                           ,P_OVE_CONS
                                           ,P_OVE_CTO
                                           ,P_OVE_BOL
                                           ,P_MON_C
                                           ,P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,P_FECHA_OP
                                           );
      END LOOP;
   ELSIF P_TIPO_CAUSACION != 'OPL' THEN
      FOR REG IN  CAUSAR_OPECONTADO_V LOOP
         /* Se debe evaluar este tema para el proceso de las TTVs 2 de Febrero de 2018
          OPEN C_OPERACION;
          FETCH C_OPERACION INTO V_OPERACION;
          CLOSE C_OPERACION;

         IF (NVL(REG.MONTO_A_CAUSAR,0) != 0 OR
             V_OPERACION = '4') THEN
         */
         IF NVL(REG.MONTO_A_CAUSAR,0) != 0 THEN   
            OPEN C_LIQUIDACION;
            FETCH C_LIQUIDACION INTO V_TIPO_RENTA;
            CLOSE C_LIQUIDACION;
            V_TIPO_RENTA := NVL(V_TIPO_RENTA,' ');

            INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
               (MCC_CONSECUTIVO
               ,MCC_CCC_CLI_PER_NUM_IDEN
               ,MCC_CCC_CLI_PER_TID_CODIGO
               ,MCC_CCC_NUMERO_CUENTA
               ,MCC_FECHA
               ,MCC_TMC_MNEMONICO
               ,MCC_MONTO
               ,MCC_MONTO_A_CONTADO
               ,MCC_MONTO_A_PLAZO
               ,MCC_MONTO_BURSATIL
               ,MCC_LIC_NUMERO_OPERACION
               ,MCC_LIC_NUMERO_FRACCION
               ,MCC_LIC_TIPO_OPERACION
               ,MCC_LIC_BOL_MNEMONICO)
            VALUES
               (MCC_SEQ.NEXTVAL
               ,P_NUMID
               ,P_TIPID
               ,P_CTANUM
               ,SYSDATE
               ,'COPV'
               ,0
               ,-REG.MONTO_A_CAUSAR
               ,0
               ,REG.MONTO_A_CAUSAR
               ,P_LIC_OP
               ,P_LIC_FR
               ,P_LIC_TIPO
               ,P_LIC_BOL);

            UPDATE LIQUIDACIONES_COMERCIAL
            SET LIC_ESTADO = 'V'
            WHERE LIC_BOL_MNEMONICO = P_LIC_BOL
              AND LIC_NUMERO_OPERACION = P_LIC_OP
              AND LIC_NUMERO_FRACCION = P_LIC_FR
              AND LIC_TIPO_OPERACION = P_LIC_TIPO;


            FOR MOV IN MVTOS_V(P_LIC_BOL
                              ,P_LIC_OP
                              ,P_LIC_FR
                              ,P_LIC_TIPO) LOOP
               UPDATE MOVIMIENTOS_CUENTA_CORREDORES
               SET    MCC_CAUSADO_CONT_O_PLAZO = 'S'
               WHERE  MCC_CCC_CLI_PER_NUM_IDEN = P_NUMID
               AND    MCC_CCC_CLI_PER_TID_CODIGO = P_TIPID
               AND    MCC_CCC_NUMERO_CUENTA = P_CTANUM
               AND    MCC_FECHA = MOV.MCC_FECHA
               AND    MCC_CONSECUTIVO = MOV.MCC_CONSECUTIVO;
            END LOOP;
         END IF;
         IF V_FIC = 'S' THEN
            P_OPERACIONES.PR_GENERA_AJUSTE_CFIC (
                                            P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,V_VALOR_OP);

         END IF;
         P_OPERACIONES.INSERTA_MOV_DIVISAS('V'
                                           ,REG.MONTO_A_CAUSAR
                                           ,P_OVE_CONS
                                           ,P_OVE_CTO
                                           ,P_OVE_BOL
                                           ,P_MON_C
                                           ,P_NUMID
                                           ,P_TIPID
                                           ,P_CTANUM
                                           ,P_LIC_BOL
                                           ,P_LIC_OP
                                           ,P_LIC_FR
                                           ,P_LIC_TIPO
                                           ,P_FECHA_OP
                                           );
      END LOOP;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      errorsql := SUBSTR(SQLERRM,1,350);
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.ACTUALIZAR_SALDO_V'
                     ,P_ERROR       => SUBSTR('ORDEN:'||P_OVE_BOL||'-'||P_OVE_CTO||'-'||P_OVE_CONS||'-'||ERRORSQL,1,500)
                     ,P_TABLA_ERROR => NULL);
      COMMIT;
END ACTUALIZAR_SALDO_V;


/*******************************************************************************************
***  Procedimiento para Inserta Movimientos de Causacion de Operaciones de Yankees        **
***************************************************************************************** */
PROCEDURE INSERTA_MOV_DIVISAS (TIPO_OP        IN VARCHAR2
                              ,MONTO_A_CAUSAR IN NUMBER
                              ,P_CONS         ORDENES_COMPRA.OCO_CONSECUTIVO%TYPE
                              ,P_CTO          ORDENES_COMPRA.OCO_COC_CTO_MNEMONICO%TYPE
                              ,P_BOL          ORDENES_COMPRA.OCO_BOL_MNEMONICO%TYPE
                              ,P_MONEDA       ORDENES_COMPRA.OCO_MONEDA_COMPENSACION%TYPE
                              ,P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
                              ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
                              ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
                              ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                              ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                              ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
                              ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
                              ,P_FECHA_OP     LIQUIDACIONES_COMERCIAL.LIC_FECHA_OPERACION%TYPE
                              ) IS


   CURSOR APLICADO (BOL VARCHAR2,
                    NUM_OP NUMBER,
                    FRACC NUMBER,
                    TIPO_OP VARCHAR2) IS
      SELECT LIC_VOLUMEN_FRACCION
            ,LIC_MNEMOTECNICO_TITULO
      FROM   LIQUIDACIONES_COMERCIAL
      WHERE  LIC_BOL_MNEMONICO = BOL
        AND  LIC_NUMERO_OPERACION = NUM_OP
        AND  LIC_NUMERO_FRACCION = FRACC
        AND  LIC_TIPO_OPERACION = TIPO_OP;
   LIC1   APLICADO%ROWTYPE;

   VALOR_APLICADO NUMBER;

   CURSOR RETE (BOL VARCHAR2,
                NUM_OP NUMBER,
                FRACC NUMBER,
                TIPO_OP VARCHAR2) IS
      SELECT MCC_MONTO_A_PLAZO+ MCC_MONTO_A_CONTADO
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_TMC_MNEMONICO = 'RFV'
        AND MCC_MCC_CONSECUTIVO IS NULL
        AND MCC_LIC_BOL_MNEMONICO = BOL
        AND MCC_LIC_NUMERO_OPERACION = NUM_OP
        AND MCC_LIC_NUMERO_FRACCION = FRACC
        AND MCC_LIC_TIPO_OPERACION = TIPO_OP;

   VALOR_RETE NUMBER;

   CURSOR TRM (FECHA DATE) IS
      SELECT CBM_VALOR
      FROM COTIZACIONES_BASE_MONETARIAS
      WHERE CBM_BMO_MNEMONICO = 'DOLAR'
        AND TRUNC(CBM_FECHA) = TRUNC(FECHA);

   CURSOR C_BASE_ESPECIE IS
      SELECT ENA_BMO_MNEMONICO
      FROM   ESPECIES_NACIONALES
      WHERE  ENA_MNEMONICO = LIC1.LIC_MNEMOTECNICO_TITULO;
   ENA1   C_BASE_ESPECIE%ROWTYPE;

   VALOR_TRM     NUMBER;
   MOVIMIENTO    VARCHAR2(6);
   VALOR         NUMBER;
   VALOR_OP      NUMBER;
   FECHA_ACT     DATE;
   ERRORSQL      VARCHAR2(350);
   NO_TRM        EXCEPTION;
BEGIN


   -- INSERTA MOVIMIENTOS A CLIENTES EN DIVISAS PARA YANKEES --
   IF TIPO_OP = 'C' THEN
      IF NVL(P_MONEDA,'N') = 'U' THEN

         VALOR_APLICADO := 0;
         VALOR := 0;
         OPEN APLICADO(P_LIC_BOL
                      ,P_LIC_OP
                      ,P_LIC_FR
                      ,P_LIC_TIPO);
         FETCH APLICADO INTO LIC1;
         CLOSE APLICADO;

         OPEN C_BASE_ESPECIE;
         FETCH C_BASE_ESPECIE INTO ENA1;
         CLOSE C_BASE_ESPECIE;

         -- Se permite causar movimientos ya sean en especies con bases monetarios pesos y dolares
         IF NVL(ENA1.ENA_BMO_MNEMONICO,'PESOS') IN ('DOLAR', 'PESOS') THEN

            VALOR_APLICADO := NVL(LIC1.LIC_VOLUMEN_FRACCION,0)* (-1);

            OPEN TRM(P_FECHA_OP);
            FETCH TRM INTO VALOR_TRM;
            IF TRM%NOTFOUND THEN
               RAISE NO_TRM;
            END IF;
            CLOSE TRM;
            VALOR_TRM := NVL(VALOR_TRM,0);

            VALOR := VALOR_APLICADO;
            MOVIMIENTO := 'CBNYAN';

            IF VALOR_TRM != 0 AND VALOR != 0 THEN
               VALOR := ROUND(VALOR/VALOR_TRM,2);

               P_SIGUIENTE_FECHA.SIGUIENTE_FECHA_MCD(P_NID
                                                    ,P_TID
                                                    ,P_CTA
                                                    ,'DOLAR'
                                                    ,FECHA_ACT);

               INSERT INTO MOVIMIENTOS_CUENTAS_DIVISAS
                  (MCD_FECHA
                  ,MCD_CDV_CCC_CLI_PER_NUM_IDEN
                  ,MCD_CDV_CCC_CLI_PER_TID_CODIGO
                  ,MCD_CDV_CCC_NUMERO_CUENTA
                  ,MCD_CDV_BMO_MNEMONICO
                  ,MCD_TDV_MNEMONICO
                  ,MCD_MONTO
                  ,MCD_MONTO_RESTRINGIDO
                  ,MCD_SALDO
                  ,MCD_SALDO_RESTRINGIDO
                  ,MCD_LIC_BOL_MNEMONICO
                  ,MCD_LIC_NUMERO_OPERACION
                  ,MCD_LIC_NUMERO_FRACCION
                  ,MCD_LIC_TIPO_OPERACION)
               VALUES
                  (FECHA_ACT
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,'DOLAR'
                  ,MOVIMIENTO
                  ,0
                  ,VALOR
                  ,0
                  ,0
                  ,P_LIC_BOL
                  ,P_LIC_OP
                  ,P_LIC_FR
                  ,P_LIC_TIPO);


               INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
                  (MCC_CONSECUTIVO
                  ,MCC_CCC_CLI_PER_NUM_IDEN
                  ,MCC_CCC_CLI_PER_TID_CODIGO
                  ,MCC_CCC_NUMERO_CUENTA
                  ,MCC_FECHA
                  ,MCC_TMC_MNEMONICO
                  ,MCC_MONTO
                  ,MCC_MONTO_A_PLAZO
                  ,MCC_MONTO_BURSATIL
                  ,MCC_MCD_FECHA
                  ,MCC_MCD_CDV_CCC_CLI_PER_NUM_ID
                  ,MCC_MCD_CDV_CCC_CLI_PER_TID_CO
                  ,MCC_MCD_CDV_CCC_NUMERO_CUENTA
                  ,MCC_MCD_CDV_BMO_MNEMONICO)
               VALUES
                  (MCC_SEQ.NEXTVAL
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,SYSDATE
                  ,'ACOM'
                  ,-MONTO_A_CAUSAR
                  ,0
                  ,0
                  ,SYSDATE
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,'DOLAR');
            END IF;
         END IF;
      END IF;
   ELSIF TIPO_OP = 'V' THEN
      IF NVL(P_MONEDA,'N') = 'U' THEN
         VALOR_APLICADO := 0;
         VALOR := 0;
         OPEN APLICADO(P_LIC_BOL
                      ,P_LIC_OP
                      ,P_LIC_FR
                      ,P_LIC_TIPO);

         FETCH APLICADO INTO LIC1;
         CLOSE APLICADO;

         VALOR_APLICADO := NVL(LIC1.LIC_VOLUMEN_FRACCION,0);

         OPEN C_BASE_ESPECIE;
         FETCH C_BASE_ESPECIE INTO ENA1;
         CLOSE C_BASE_ESPECIE;

         OPEN RETE(P_LIC_BOL
                  ,P_LIC_OP
                  ,P_LIC_FR
                  ,P_LIC_TIPO);
         FETCH RETE INTO VALOR_RETE;
         CLOSE RETE;
         VALOR_RETE := NVL(VALOR_RETE,0);
         VALOR_OP := VALOR_APLICADO + VALOR_RETE;

         IF NVL(ENA1.ENA_BMO_MNEMONICO, ' ') IN ('DOLAR', 'PESOS') THEN

            OPEN TRM(P_FECHA_OP);
            FETCH TRM INTO VALOR_TRM;
            IF TRM%NOTFOUND THEN
            	 RAISE NO_TRM;
            END IF;
            CLOSE TRM;
            VALOR_TRM := NVL(VALOR_TRM,0);

            VALOR := VALOR_APLICADO;
            MOVIMIENTO := 'VBNYAN';

            IF VALOR_TRM != 0 AND VALOR != 0 THEN
               VALOR := ROUND(VALOR/VALOR_TRM,2);

               P_SIGUIENTE_FECHA.SIGUIENTE_FECHA_MCD(P_NID
                                                    ,P_TID
                                                    ,P_CTA
                                                    ,'DOLAR'
                                                    ,FECHA_ACT);

               INSERT INTO MOVIMIENTOS_CUENTAS_DIVISAS
                  (MCD_FECHA
                  ,MCD_CDV_CCC_CLI_PER_NUM_IDEN
                  ,MCD_CDV_CCC_CLI_PER_TID_CODIGO
                  ,MCD_CDV_CCC_NUMERO_CUENTA
                  ,MCD_CDV_BMO_MNEMONICO
                  ,MCD_TDV_MNEMONICO
                  ,MCD_MONTO
                  ,MCD_MONTO_RESTRINGIDO
                  ,MCD_SALDO
                  ,MCD_SALDO_RESTRINGIDO
                  ,MCD_LIC_BOL_MNEMONICO
                  ,MCD_LIC_NUMERO_OPERACION
                  ,MCD_LIC_NUMERO_FRACCION
                  ,MCD_LIC_TIPO_OPERACION)
               VALUES
                  (FECHA_ACT
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,'DOLAR'
                  ,MOVIMIENTO
                  ,0
                  ,VALOR
                  ,0
                  ,0
                  ,P_LIC_BOL
                  ,P_LIC_OP
                  ,P_LIC_FR
                  ,P_LIC_TIPO);


               INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
                  (MCC_CONSECUTIVO
                  ,MCC_CCC_CLI_PER_NUM_IDEN
                  ,MCC_CCC_CLI_PER_TID_CODIGO
                  ,MCC_CCC_NUMERO_CUENTA
                  ,MCC_FECHA
                  ,MCC_TMC_MNEMONICO
                  ,MCC_MONTO
                  ,MCC_MONTO_A_PLAZO
                  ,MCC_MONTO_BURSATIL
                  ,MCC_MCD_FECHA
                  ,MCC_MCD_CDV_CCC_CLI_PER_NUM_ID
                  ,MCC_MCD_CDV_CCC_CLI_PER_TID_CO
                  ,MCC_MCD_CDV_CCC_NUMERO_CUENTA
                  ,MCC_MCD_CDV_BMO_MNEMONICO)
               VALUES
                  (MCC_SEQ.NEXTVAL
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,SYSDATE
                  ,'AVOM'
                  ,0
                  ,0
                  ,-MONTO_A_CAUSAR
                  ,FECHA_ACT
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,'DOLAR');
           END IF;

           IF VALOR_RETE != 0 THEN

             IF VALOR_TRM != 0 AND VALOR != 0 THEN
             	 INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
                  (MCC_CONSECUTIVO
                  ,MCC_CCC_CLI_PER_NUM_IDEN
                  ,MCC_CCC_CLI_PER_TID_CODIGO
                  ,MCC_CCC_NUMERO_CUENTA
                  ,MCC_FECHA
                  ,MCC_TMC_MNEMONICO
                  ,MCC_MONTO
                  ,MCC_MONTO_A_PLAZO
                  ,MCC_MONTO_BURSATIL
                  ,MCC_MCD_FECHA
                  ,MCC_MCD_CDV_CCC_CLI_PER_NUM_ID
                  ,MCC_MCD_CDV_CCC_CLI_PER_TID_CO
                  ,MCC_MCD_CDV_CCC_NUMERO_CUENTA
                  ,MCC_MCD_CDV_BMO_MNEMONICO)
               VALUES
                  (MCC_SEQ.NEXTVAL
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,SYSDATE
                  ,'RFV'
                  ,0
                  ,0
                  ,VALOR_RETE
                  ,FECHA_ACT
                  ,P_NID
                  ,P_TID
                  ,P_CTA
                  ,'DOLAR');
             END IF;
           END IF;
        ELSE
           IF VALOR_RETE != 0 THEN
              P_OPERACIONES.GENERAR_AJUSTE(VALOR_RETE,
                                           P_NID,
                                           P_TID,
                                           P_CTA,
                                           P_LIC_BOL,
                                           P_LIC_OP,
                                           P_LIC_FR,
                                           P_LIC_TIPO);
           END IF;
           NULL;
        END IF;

      END IF;
   END IF;
EXCEPTION
   WHEN NO_TRM THEN
   ROLLBACK;
   INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.INSERTA_MOV_DIVISAS'
                  ,P_ERROR       => SUBSTR('NO EXISTE TRM PARA LA FECHA : '||to_char(P_FECHA_OP,'DD-MON-YYYY')||' ORDEN:'||P_BOL||'-'||P_CTO||'-'||P_CONS,1,500)
                  ,P_TABLA_ERROR => NULL);
   COMMIT;

   WHEN OTHERS THEN
      ROLLBACK;
      errorsql := SUBSTR(SQLERRM,1,350);
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.INSERTA_MOV_DIVISAS'
                     ,P_ERROR       => SUBSTR(('ORDEN:'||P_BOL||'-'||P_CTO||'-'||P_CONS||'-'||ERRORSQL),1,400)
                     ,P_TABLA_ERROR => NULL);
      COMMIT;

END INSERTA_MOV_DIVISAS;

PROCEDURE GENERAR_AJUSTE( P_MONTO        MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE
                         ,P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
                         ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
                         ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
                         ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                         ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                         ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
                         ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
                         ) IS
   CURSOR CONSECUTIVO IS
      SELECT MAX(ACL_CONSECUTIVO) + 1
      FROM AJUSTES_CLIENTES
      WHERE ACL_SUC_CODIGO = 1
      AND   ACL_NEG_CONSECUTIVO = 2;

   V_CONSECUTIVO AJUSTES_CLIENTES.ACL_CONSECUTIVO%TYPE;
   V_OBSERVACIONES AJUSTES_CLIENTES.ACL_OBSERVACIONES%TYPE;
   ERRORSQL VARCHAR2(350);

BEGIN
   OPEN CONSECUTIVO;
   FETCH CONSECUTIVO INTO V_CONSECUTIVO;
   CLOSE CONSECUTIVO;

   V_OBSERVACIONES := 'RETENCION OPERACION - LIC. '||P_LIC_OP||' - '||P_LIC_FR||' - '||P_LIC_TIPO||' - '||P_LIC_BOL;

   INSERT INTO AJUSTES_CLIENTES
      (ACL_CONSECUTIVO
      ,ACL_SUC_CODIGO
      ,ACL_NEG_CONSECUTIVO
      ,ACL_CCC_CLI_PER_NUM_IDEN
      ,ACL_CCC_CLI_PER_TID_CODIGO
      ,ACL_CCC_NUMERO_CUENTA
      ,ACL_CAJ_MNEMONICO
      ,ACL_FECHA
      ,ACL_GENERADO_POR
      ,ACL_MONTO
      ,ACL_OBSERVACIONES)
   VALUES
      (V_CONSECUTIVO
      ,1
      ,2
      ,P_NID
      ,P_TID
      ,P_CTA
      ,'CRE' -- Cargo Retefuente
      ,SYSDATE
      ,'AUTOMATICO'
      ,ABS(P_MONTO)
      ,V_OBSERVACIONES);


   INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
      (MCC_CONSECUTIVO
      ,MCC_CCC_CLI_PER_NUM_IDEN
      ,MCC_CCC_CLI_PER_TID_CODIGO
      ,MCC_CCC_NUMERO_CUENTA
      ,MCC_FECHA
      ,MCC_TMC_MNEMONICO
      ,MCC_MONTO
      ,MCC_MONTO_A_CONTADO
      ,MCC_MONTO_A_PLAZO
      ,MCC_MONTO_BURSATIL
      ,MCC_MONTO_ADMON_VALORES
      ,MCC_SUC_CODIGO
      ,MCC_NEG_CONSECUTIVO
      ,MCC_ACL_CONSECUTIVO)
   VALUES
      (MCC_SEQ.NEXTVAL
      ,P_NID
      ,P_TID
      ,P_CTA
      ,SYSDATE
      ,'CAR'
      ,0
      ,0
      ,0
      ,ABS(P_MONTO) * -1
      ,0
      ,1
      ,2
      ,V_CONSECUTIVO);

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      errorsql := SUBSTR(SQLERRM,1,350);
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.GENERAR_AJUSTE'
                     ,P_ERROR       => SUBSTR('LIQUIDACION:'||P_LIC_BOL||'-'||P_LIC_OP||'-'||P_LIC_FR||'-'||P_LIC_TIPO||'-'||ERRORSQL,1,500)
                     ,P_TABLA_ERROR => NULL);
      COMMIT;

END GENERAR_AJUSTE;

PROCEDURE VENTAS_POR_CUMPLIR (P_CTO VARCHAR2, P_ORI VARCHAR2) IS

   CURSOR C_VENTA IS
      SELECT  VP_COC_CTO_MNEMONICO      VPC_COC_CTO_MNEMONICO
             ,VP_FECHA_CUMPLIMIENTO     VPC_FECHA_CUMPLIMIENTO
             ,VP_CCC_CLI_PER_NUM_IDEN   VPC_CCC_CLI_PER_NUM_IDEN
             ,VP_CCC_CLI_PER_TID_CODIGO VPC_CCC_CLI_PER_TID_CODIGO
             ,PER_NOMBRE                VPC_CCC_NOMBRE_CUENTA
             ,VP_ENA_MNEMONICO          VPC_ENA_MNEMONICO
             ,VP_CANTIDAD_FRACCION      VPC_CANTIDAD_FRACCION
             ,VP_PER_NUM_IDEN           VPC_PER_NUM_IDEN
             ,VP_PER_TID_CODIGO         VPC_PER_TID_CODIGO
             ,VP_PER_NOMBRE_USUARIO     VPC_PER_NOMBRE_USUARIO
             ,VP_PCP_CPR_MNEMONICO      VPC_PCP_CPR_MNEMONICO
      FROM LIC_POR_CUMPLIR VP,
           FILTRO_PERSONAS FP
      WHERE VP_COC_CTO_MNEMONICO = P_CTO
        AND VP_CCC_CLI_PER_NUM_IDEN = FP.PER_NUM_IDEN
        AND VP_CCC_CLI_PER_TID_CODIGO = FP.PER_TID_CODIGO
        AND EXISTS   (SELECT 'X'
                      FROM FILTRO_COMERCIALES PER
                      WHERE VP.VP_PER_NUM_IDEN = PER.PER_NUM_IDEN
                        AND VP.VP_PER_TID_CODIGO = PER.PER_TID_CODIGO)
        AND VP_LIC_SUCURSAL_CUMPLIM LIKE P_ORI;
   R_VENTA C_VENTA%ROWTYPE;

   CURSOR C_VENTA_DEP IS
      SELECT  VP_COC_CTO_MNEMONICO      VPC_COC_CTO_MNEMONICO
             ,VP_FECHA_CUMPLIMIENTO     VPC_FECHA_CUMPLIMIENTO
             ,VP_CCC_CLI_PER_NUM_IDEN   VPC_CCC_CLI_PER_NUM_IDEN
             ,VP_CCC_CLI_PER_TID_CODIGO VPC_CCC_CLI_PER_TID_CODIGO
             ,PER_NOMBRE                VPC_CCC_NOMBRE_CUENTA
             ,VP_ENA_MNEMONICO          VPC_ENA_MNEMONICO
             ,VP_CANTIDAD_FRACCION      VPC_CANTIDAD_FRACCION
             ,VP_PER_NUM_IDEN           VPC_PER_NUM_IDEN
             ,VP_PER_TID_CODIGO         VPC_PER_TID_CODIGO
             ,VP_PER_NOMBRE_USUARIO     VPC_PER_NOMBRE_USUARIO
             ,VP_PCP_CPR_MNEMONICO      VPC_PCP_CPR_MNEMONICO
      FROM VW_LIC_POR_CUMPLIR_DEPOSITO VP,
           FILTRO_PERSONAS FP
      WHERE VP_COC_CTO_MNEMONICO = P_CTO
        AND VP_CCC_CLI_PER_NUM_IDEN = FP.PER_NUM_IDEN
        AND VP_CCC_CLI_PER_TID_CODIGO = FP.PER_TID_CODIGO
        AND EXISTS   (SELECT 'X'
                      FROM FILTRO_COMERCIALES PER
                      WHERE VP.VP_PER_NUM_IDEN = PER.PER_NUM_IDEN
                        AND VP.VP_PER_TID_CODIGO = PER.PER_TID_CODIGO)
        AND VP_LIC_SUCURSAL_CUMPLIM LIKE P_ORI;
   R_VENTA_DEP C_VENTA_DEP%ROWTYPE;

   CURSOR C_COMPRA  (P_NID VARCHAR2,
                     P_TID VARCHAR2,
                     P_ENA VARCHAR2,
                     P_CUMPLE DATE) IS

      SELECT SUM(LIC.LIC_CANTIDAD_FRACCION)    CANTIDAD_FRACCION
      FROM LIQUIDACIONES_COMERCIAL LIC ,
           ORDENES_COMPRA OCO
      WHERE OCO_CONSECUTIVO                 = LIC_OCO_CONSECUTIVO
        AND OCO_COC_CTO_MNEMONICO           = LIC_OCO_COC_CTO_MNEMONICO
        AND OCO_BOL_MNEMONICO               = LIC_BOL_MNEMONICO
        AND LIC_FECHA_CUMPLIMIENTO          >= TRUNC(SYSDATE)
        AND LIC_FECHA_CUMPLIMIENTO          <= TRUNC(P_CUMPLE)
        AND OCO.OCO_CCC_CLI_PER_NUM_IDEN    = P_NID
        AND OCO.OCO_CCC_CLI_PER_TID_CODIGO  = P_TID
        AND OCO.OCO_ENA_MNEMONICO           = P_ENA;
   V_COMPRA NUMBER;


   CURSOR C_DISP (P_NID VARCHAR2,
                  P_TID VARCHAR2,
                  P_ENA VARCHAR2) IS
      SELECT SUM(SALDO_DISPONIBLE)
      FROM (  SELECT  NVL(SUM(CFC_SALDO_DCVAL_DISPONIBLE),0)+ NVL(SUM(CFC_SALDO_DCVAL_GAR_REPO),0) SALDO_DISPONIBLE
              FROM CUENTAS_FUNGIBLE_CLIENTE
                 , FUNGIBLES
                 , ISINS
                 , ISINS_ESPECIES
              WHERE CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
                AND CFC_FUG_MNEMONICO = FUG_MNEMONICO
                AND CFC_FUG_ISI_MNEMONICO = ISI_MNEMONICO
                AND ISI_MNEMONICO = ISE_ISI_MNEMONICO
                AND ISE_ENA_MNEMONICO = (SELECT  MIN(ISE_ENA_MNEMONICO)
                                         FROM    ISINS_ESPECIES
                                                ,ESPECIES_NACIONALES
                                         WHERE  ISE_ENA_MNEMONICO = ENA_MNEMONICO
                                           AND  ISE_ISI_MNEMONICO = CFC_FUG_ISI_MNEMONICO
                                           AND  ENA_ESTADO = 'A')
                AND (CFC_SALDO_DCVAL_DISPONIBLE > 0 OR CFC_SALDO_DCVAL_GAR_REPO > 0)
                AND FUG_ESTADO = 'A'
                AND CFC_CCC_CLI_PER_NUM_IDEN = P_NID
                AND CFC_CCC_CLI_PER_TID_CODIGO = P_TID
                AND ISE_ENA_MNEMONICO = P_ENA
              UNION
              SELECT SUM(TLO_VALOR_NOMINAL) SALDO_DISPONIBLE
              FROM TITULOS
              WHERE TLO_CCC_CLI_PER_NUM_IDEN = P_NID
                AND TLO_CCC_CLI_PER_TID_CODIGO = P_TID
                AND TLO_ENA_MNEMONICO = P_ENA
                AND TLO_ETC_MNEMONICO = 'DIS'
                AND TLO_PORTAFOLIO = 'S');

   V_DISP NUMBER;

   v_registro number;
BEGIN

   DELETE FROM VENTAS_POR_CUMPLIR;
   COMMIT;

   OPEN C_VENTA;
   FETCH C_VENTA INTO R_VENTA;
   WHILE C_VENTA%FOUND LOOP
      OPEN C_COMPRA(R_VENTA.VPC_CCC_CLI_PER_NUM_IDEN,
                    R_VENTA.VPC_CCC_CLI_PER_TID_CODIGO,
                    R_VENTA.VPC_ENA_MNEMONICO,
                    R_VENTA.VPC_FECHA_CUMPLIMIENTO);
      FETCH C_COMPRA INTO V_COMPRA;
      IF C_COMPRA%NOTFOUND THEN
         V_COMPRA := 0;
      END IF;
      CLOSE C_COMPRA;
      V_COMPRA := NVL(V_COMPRA,0);

      OPEN C_DISP(R_VENTA.VPC_CCC_CLI_PER_NUM_IDEN,
                  R_VENTA.VPC_CCC_CLI_PER_TID_CODIGO,
                  R_VENTA.VPC_ENA_MNEMONICO);
      FETCH C_DISP INTO V_DISP;
      IF C_DISP%NOTFOUND THEN
         V_DISP := 0;
      END IF;
      CLOSE C_DISP;
      V_DISP := NVL(V_DISP,0);
      IF R_VENTA.VPC_CANTIDAD_FRACCION - ( V_COMPRA + V_DISP) > 0 THEN
         INSERT INTO VENTAS_POR_CUMPLIR  --TABLA GLOBAL
            (  VPC_COC_MNEMONICO
              ,VPC_FECHA_CUMPLIMIENTO
              ,VPC_CLI_PER_NUM_IDEN
              ,VPC_CLI_PER_TID_CODIGO
              ,VPC_CLI_NOMBRE
              ,VPC_ENA_MNEMONICO
              ,VPC_CANTIDAD_FRACCION
              ,VPC_PER_NUM_IDEN
              ,VPC_PER_TID_CODIGO
              ,VPC_PER_NOMBRE_USUARIO
              ,VPC_CPR_MNEMONICO)
         VALUES ( R_VENTA.VPC_COC_CTO_MNEMONICO
   	          ,R_VENTA.VPC_FECHA_CUMPLIMIENTO
   	     	    ,R_VENTA.VPC_CCC_CLI_PER_NUM_IDEN
   	     	    ,R_VENTA.VPC_CCC_CLI_PER_TID_CODIGO
   	     	    ,R_VENTA.VPC_CCC_NOMBRE_CUENTA
   	     	    ,R_VENTA.VPC_ENA_MNEMONICO
   	     	    ,R_VENTA.VPC_CANTIDAD_FRACCION - ( V_COMPRA + V_DISP)
         	    ,R_VENTA.VPC_PER_NUM_IDEN
         	    ,R_VENTA.VPC_PER_TID_CODIGO
         	    ,R_VENTA.VPC_PER_NOMBRE_USUARIO
         	    ,R_VENTA.VPC_PCP_CPR_MNEMONICO );
         END IF;
      FETCH C_VENTA INTO R_VENTA;
   END LOOP;
   CLOSE C_VENTA;

   OPEN C_VENTA_DEP;
   FETCH C_VENTA_DEP INTO R_VENTA_DEP;
   WHILE C_VENTA_DEP%FOUND LOOP
      OPEN C_COMPRA(R_VENTA_DEP.VPC_CCC_CLI_PER_NUM_IDEN,
                    R_VENTA_DEP.VPC_CCC_CLI_PER_TID_CODIGO,
                    R_VENTA_DEP.VPC_ENA_MNEMONICO,
                    R_VENTA_DEP.VPC_FECHA_CUMPLIMIENTO);
      FETCH C_COMPRA INTO V_COMPRA;
      IF C_COMPRA%NOTFOUND THEN
         V_COMPRA := 0;
      END IF;
      CLOSE C_COMPRA;
      V_COMPRA := NVL(V_COMPRA,0);

      OPEN C_DISP(R_VENTA_DEP.VPC_CCC_CLI_PER_NUM_IDEN,
                  R_VENTA_DEP.VPC_CCC_CLI_PER_TID_CODIGO,
                  R_VENTA_DEP.VPC_ENA_MNEMONICO);
      FETCH C_DISP INTO V_DISP;
      IF C_DISP%NOTFOUND THEN
         V_DISP := 0;
      END IF;
      CLOSE C_DISP;
      V_DISP := NVL(V_DISP,0);
      IF R_VENTA_DEP.VPC_CANTIDAD_FRACCION - ( V_COMPRA + V_DISP) > 0 THEN
         INSERT INTO VENTAS_POR_CUMPLIR  --TABLA GLOBAL
            (  VPC_COC_MNEMONICO
              ,VPC_FECHA_CUMPLIMIENTO
              ,VPC_CLI_PER_NUM_IDEN
              ,VPC_CLI_PER_TID_CODIGO
              ,VPC_CLI_NOMBRE
              ,VPC_ENA_MNEMONICO
              ,VPC_CANTIDAD_FRACCION
              ,VPC_PER_NUM_IDEN
              ,VPC_PER_TID_CODIGO
              ,VPC_PER_NOMBRE_USUARIO
              ,VPC_CPR_MNEMONICO)
         VALUES (R_VENTA_DEP.VPC_COC_CTO_MNEMONICO
   	            ,R_VENTA_DEP.VPC_FECHA_CUMPLIMIENTO
   	     	    ,R_VENTA_DEP.VPC_CCC_CLI_PER_NUM_IDEN
   	     	    ,R_VENTA_DEP.VPC_CCC_CLI_PER_TID_CODIGO
   	     	    ,R_VENTA_DEP.VPC_CCC_NOMBRE_CUENTA
   	     	    ,R_VENTA_DEP.VPC_ENA_MNEMONICO
   	     	    ,R_VENTA_DEP.VPC_CANTIDAD_FRACCION - ( V_COMPRA + V_DISP)
         	    ,R_VENTA_DEP.VPC_PER_NUM_IDEN
         	    ,R_VENTA_DEP.VPC_PER_TID_CODIGO
         	    ,R_VENTA_DEP.VPC_PER_NOMBRE_USUARIO
         	    ,R_VENTA_DEP.VPC_PCP_CPR_MNEMONICO );
         END IF;
      FETCH C_VENTA_DEP INTO R_VENTA_DEP;
   END LOOP;
   CLOSE C_VENTA_DEP;
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002,'Error en procedimiento P_OPERACIONES.VENTAS_POR_CUMPLIR: '||sqlerrm);
END VENTAS_POR_CUMPLIR;


/******************************************************************************
 *** COMPENSACION SEBRA EN LA FECHA  : CALCULADA                           ****
 ******************************************************************************/
PROCEDURE COMPENSACION_SEBRA (P_FECHA DATE,p_flag VARCHAR2 DEFAULT NULL) IS

   CURSOR C_IVC IS
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = 'IVC';

   CURSOR C_COMP IS
      SELECT CRV_CONSECUTIVO
            ,CRV_FECHA
            ,CRV_OPERACIONES
            ,CRV_AJUSTE_OPER
            ,CRV_COMPENSA_OPER
            ,CRV_COMISIONES
            ,CRV_AJUSTE_COMIS
            ,CRV_COMPENSA_COMIS
            ,CRV_IVA
            ,CRV_AJUSTE_IVA
            ,CRV_COMPENSA_IVA
            ,CRV_SERVICIO_BOLSA
            ,CRV_AJUSTE_SERV
            ,CRV_COMPENSA_SERV
            ,CRV_CARGO_PUNTA
            ,CRV_AJUSTE_CXPT
            ,CRV_COMPENSA_CXPT
            ,CRV_NETO_COMPENSADO
            ,CRV_CONFIRMADO
      FROM COMPENSACIONES_RV
      WHERE CRV_FECHA >= TRUNC(P_FECHA)
        AND CRV_FECHA <  TRUNC(P_FECHA + 1);

   R_COMP C_COMP%ROWTYPE;
   HAY_CRV VARCHAR2(1) := 'N';


   CURSOR C_COMPRAS IS
      SELECT SUM(LIC_VOLUMEN_NETO_FRACCION) VALOR_OP,
             SUM(LIC_VALOR_COMISION) VALOR_COMISION,
             SUM(LIC_SERVICIO_BOLSA_FIJO) VALOR_BOLSA,
             SUM(LIC_SERVICIO_BOLSA_VARIABLE) CARGO_PUNTA,
             SUM(DECODE(LIC_VALOR_EXTEMPO,NULL,0,0,0,
                        DECODE(LIC_POSICION_EXTEMPO,'S',LIC_VALOR_EXTEMPO,'A',-LIC_VALOR_EXTEMPO)
                       )) EXTEMPO,
			       NVL(SUM(MONTO_MVTO),0) VALOR_IVA
      FROM OP_COMPENSA_RV A,
           (SELECT MCC_LIC_BOL_MNEMONICO,
                   MCC_LIC_NUMERO_OPERACION,
                   MCC_LIC_NUMERO_FRACCION,
                   MCC_LIC_TIPO_OPERACION,
                   NVL((MCC_MONTO + MCC_MONTO_A_CONTADO + MCC_MONTO_A_PLAZO +
                        MCC_MONTO_BURSATIL), 0) MONTO_MVTO
            FROM MOVIMIENTOS_CUENTA_CORREDORES B,
                 OP_COMPENSA_RV C
            WHERE B.MCC_LIC_NUMERO_OPERACION   = C.LIC_NUMERO_OPERACION
              AND B.MCC_LIC_NUMERO_FRACCION  = C.LIC_NUMERO_FRACCION
              AND B.MCC_LIC_TIPO_OPERACION   = C.LIC_TIPO_OPERACION
              AND B.MCC_LIC_BOL_MNEMONICO    = C.LIC_BOL_MNEMONICO
              AND B.MCC_MCC_CONSECUTIVO IS NULL
              AND B.MCC_TMC_MNEMONICO = 'IVAC') MOV
      WHERE A.LIC_NUMERO_OPERACION = MOV.MCC_LIC_NUMERO_OPERACION (+)
        AND A.LIC_NUMERO_FRACCION = MOV.MCC_LIC_NUMERO_FRACCION  (+)
        AND A.LIC_TIPO_OPERACION = MOV.MCC_LIC_TIPO_OPERACION  (+)
        AND A.LIC_BOL_MNEMONICO = MOV.MCC_LIC_BOL_MNEMONICO  (+)
        AND A.LIC_TIPO_OPERACION = 'C';
   R_COMPRAS C_COMPRAS%ROWTYPE;


   CURSOR C_VENTAS IS
      SELECT SUM(LIC_VOLUMEN_NETO_FRACCION) VALOR_OP,
             SUM(LIC_VALOR_COMISION) VALOR_COMISION,
             SUM(LIC_SERVICIO_BOLSA_FIJO) VALOR_BOLSA,
             SUM(LIC_SERVICIO_BOLSA_VARIABLE) CARGO_PUNTA,
             SUM(DECODE(LIC_VALOR_EXTEMPO,NULL,0,0,0,
                        DECODE(LIC_POSICION_EXTEMPO,'S',-LIC_VALOR_EXTEMPO,'A',LIC_VALOR_EXTEMPO)
                       )) EXTEMPO,
             NVL(SUM(MONTO_MVTO),0) VALOR_IVA
      FROM OP_COMPENSA_RV A,
           (SELECT MCC_LIC_BOL_MNEMONICO,
                   MCC_LIC_NUMERO_OPERACION,
                   MCC_LIC_NUMERO_FRACCION,
                   MCC_LIC_TIPO_OPERACION,
                   NVL((MCC_MONTO + MCC_MONTO_A_CONTADO + MCC_MONTO_A_PLAZO +
                        MCC_MONTO_BURSATIL), 0) MONTO_MVTO
            FROM MOVIMIENTOS_CUENTA_CORREDORES B,
                 OP_COMPENSA_RV C
            WHERE B.MCC_LIC_NUMERO_OPERACION   = C.LIC_NUMERO_OPERACION
              AND B.MCC_LIC_NUMERO_FRACCION  = C.LIC_NUMERO_FRACCION
              AND B.MCC_LIC_TIPO_OPERACION   = C.LIC_TIPO_OPERACION
              AND B.MCC_LIC_BOL_MNEMONICO    = C.LIC_BOL_MNEMONICO
              AND B.MCC_MCC_CONSECUTIVO IS NULL
              AND B.MCC_TMC_MNEMONICO = 'IVAV') MOV   -- IVAV : IVA COMISION BOLSA VENTA
      WHERE A.LIC_NUMERO_OPERACION = MOV.MCC_LIC_NUMERO_OPERACION (+)
        AND A.LIC_NUMERO_FRACCION = MOV.MCC_LIC_NUMERO_FRACCION  (+)
        AND A.LIC_TIPO_OPERACION = MOV.MCC_LIC_TIPO_OPERACION  (+)
        AND A.LIC_BOL_MNEMONICO = MOV.MCC_LIC_BOL_MNEMONICO  (+)
        AND A.LIC_TIPO_OPERACION = 'V';
   R_VENTAS C_VENTAS%ROWTYPE;


   CURSOR C_AJUSTE IS
      SELECT  MCC_TMC_MNEMONICO
             ,SUM(MCC_MONTO + MCC_MONTO_A_CONTADO + MCC_MONTO_A_PLAZO +
                  MCC_MONTO_BURSATIL) VALOR_AJ
      FROM MOVIMIENTOS_CUENTA_CORREDORES A,
           LIQUIDACIONES_COMERCIAL LIC
      WHERE MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
        AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
        AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
        AND LIC_BOL_MNEMONICO = 'COL'
        AND (( LIC.LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
           AND LIC.LIC_FECHA_CUMPLIMIENTO <  TRUNC(P_FECHA+1))
          OR
          (    LIC.LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
           AND LIC.LIC_FECHA_PACTO_CUMPLIMIENTO <  TRUNC(P_FECHA + 1)))
        AND MCC_FECHA >= TRUNC(P_FECHA)
        AND MCC_FECHA <  TRUNC(P_FECHA + 1)
        AND NOT EXISTS (SELECT 'X'
                        FROM OP_COMPENSA_RV B
                        WHERE  B.LIC_NUMERO_OPERACION = A.MCC_LIC_NUMERO_OPERACION
                          AND  B.LIC_NUMERO_FRACCION  = A.MCC_LIC_NUMERO_FRACCION
                          AND  B.LIC_TIPO_OPERACION   = A.MCC_LIC_TIPO_OPERACION
                          AND  B.LIC_BOL_MNEMONICO    = A.MCC_LIC_BOL_MNEMONICO)
          AND A.MCC_TMC_MNEMONICO IN ('RCOV','ACOV','RIVAV','RCOC','ACOC','RIVAC',
                                      'COV', 'IVAV','COC',  'IVAC')
      GROUP BY MCC_TMC_MNEMONICO;
   R_AJUSTE C_AJUSTE%ROWTYPE;


   AJ_OP_VENTA         MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE := 0;
   AJ_OP_COMPRA        MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE := 0;
   AJ_COM_VENTA        MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE := 0;
   AJ_COM_COMPRA       MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE := 0;
   AJ_IVA_COM_VENTA    MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE := 0;
   AJ_IVA_COM_COMPRA   MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE := 0;
   P_IVA  NUMBER;
   P_CRV_AJUSTE_SERV   NUMBER := 0;
   P_CRV_AJUSTE_CXPT   NUMBER := 0;
   P_CRV_OPERACIONES   NUMBER:= 0;
   P_CRV_COMISIONES    NUMBER:= 0;
   P_CRV_IVA           NUMBER:= 0;
   P_CRV_SERVICIO_BOLSA NUMBER:= 0;
   P_CRV_CARGO_PUNTA NUMBER:= 0;
   P_CRV_AJUSTE_OPER NUMBER:= 0;
   P_CRV_AJUSTE_COMIS NUMBER:= 0;
   P_CRV_AJUSTE_IVA NUMBER:= 0;
   P_COMPENSACION number:= 0;
   P_SIGNO number;
   P_SIGNO1 number;
   P_CRV_NETO_COMPENSADO number:= 0;
   P_CRV_NETO_COMPENSADO1 number:= 0;
   P_COMPENSACION1 number:= 0;



   -- RENTA FIJA
   CURSOR C_RF IS
      SELECT NID,
             TID,
             NOMBRE,
             COD,
             SUM(VR) VR
      FROM (SELECT  CF_NID_COMPRADOR           NID
                   ,CF_TID_COMPRADOR           TID
                   ,CF_NOMBRE_COMPRADOR        NOMBRE
                   ,CF_LIC_COD_CMSNSTA_CMPRDOR COD
                   ,SUM(CF_LIC_VOL_FRACCION)   VR
            FROM OP_COMPENSA_RF
            WHERE CF_LIC_TIPO_OPERACION = 'V'
            GROUP BY CF_NID_COMPRADOR
                    ,CF_TID_COMPRADOR
                    ,CF_NOMBRE_COMPRADOR
                    ,CF_LIC_COD_CMSNSTA_CMPRDOR
            UNION
            SELECT  CF_NID_VENDEDOR            NID
                   ,CF_TID_VENDEDOR            TID
                   ,CF_NOMBRE_VENDEDOR         NOMBRE
                   ,CF_LIC_COD_CMSNSTA_VNDDOR  COD
                   ,-SUM(CF_LIC_VOL_FRACCION)   VR
            FROM OP_COMPENSA_RF
            WHERE CF_LIC_TIPO_OPERACION = 'C'
            GROUP BY CF_NID_VENDEDOR
                    ,CF_TID_VENDEDOR
                    ,CF_NOMBRE_VENDEDOR
                    ,CF_LIC_COD_CMSNSTA_VNDDOR)
      GROUP BY NID, TID, NOMBRE, COD
      ORDER BY NID;
   R_RF C_RF%ROWTYPE;

   CURSOR C_COMP_RF (FIC_NID VARCHAR2, FIC_TID VARCHAR2, FIC_COD VARCHAR2) IS
      SELECT NID, TID, COD , SUM(VR) VR
      FROM   (    SELECT CPT_FIC_PER_NUM_IDEN   NID,
                         CPT_FIC_PER_TID_CODIGO TID,
                         CPT_FIC_CODIGO_BOLSA   COD,
                         SUM(CPT_MONTO)         VR
                  FROM COMPENSACIONES_PRODUCTOS,
                       ORDENES_DE_PAGO
                  WHERE CPT_ODP_CONSECUTIVO = ODP_CONSECUTIVO
                    AND CPT_ODP_SUC_CODIGO = ODP_SUC_CODIGO
                    AND CPT_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND CPT_FECHA >= TRUNC(P_FECHA)
                    AND CPT_FECHA <  TRUNC(P_FECHA +1)
                    AND CPT_PRO_MNEMONICO = 'RF'
                    AND CPT_FIC_PER_NUM_IDEN = FIC_NID
                    AND CPT_FIC_PER_TID_CODIGO = FIC_TID
                    AND CPT_FIC_CODIGO_BOLSA = FIC_COD
                  GROUP BY CPT_FIC_PER_NUM_IDEN,
                           CPT_FIC_PER_TID_CODIGO,
                           CPT_FIC_CODIGO_BOLSA
                  UNION ALL
                  SELECT CPT_FIC_PER_NUM_IDEN    NID,
                         CPT_FIC_PER_TID_CODIGO  TID,
                         CPT_FIC_CODIGO_BOLSA    COR,
                         SUM(CPT_MONTO)          VR
                  FROM COMPENSACIONES_PRODUCTOS,
                       RECIBOS_DE_CAJA
                  WHERE CPT_RCA_CONSECUTIVO = RCA_CONSECUTIVO
                    AND CPT_RCA_SUC_CODIGO = RCA_SUC_CODIGO
                    AND CPT_RCA_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
                    AND RCA_REVERSADO = 'N'
                    AND CPT_FECHA >= TRUNC(P_FECHA)
                    AND CPT_FECHA <  TRUNC(P_FECHA+1)
                    AND CPT_PRO_MNEMONICO = 'RF'
                    AND CPT_FIC_PER_NUM_IDEN = FIC_NID
                    AND CPT_FIC_PER_TID_CODIGO = FIC_TID
                    AND CPT_FIC_CODIGO_BOLSA = FIC_COD
                  GROUP BY CPT_FIC_PER_NUM_IDEN,
                           CPT_FIC_PER_TID_CODIGO,
                           CPT_FIC_CODIGO_BOLSA)
      GROUP BY NID, TID, COD;

   R_COMP_RF C_COMP_RF%ROWTYPE;

   CURSOR C_RFTOTAL IS
      SELECT CC_FECHA,
             CC_PRO_MNEMONICO,
             SUM(CC_COMPENSACION) CC_COMPENSACION,
             SUM(CC_COMPENSADO) CC_COMPENSADO,
             SUM(CC_PENDIENTE) CC_PENDIENTE
      FROM   GL_COMPENSACION_RF_CONTRAPARTE
      GROUP BY CC_FECHA,
             CC_PRO_MNEMONICO;
   R_RFTOTAL C_RFTOTAL%ROWTYPE;

BEGIN
	 DELETE FROM GL_COMPENSACION_RF_CONTRAPARTE;

	 DELETE FROM GL_COMPENSACION_SEBRA;
	 COMMIT;
   -- DATOS DE COMPENSACION SEBRA DEL PRODUCTO ACC

   OPEN C_IVC;
   FETCH C_IVC INTO P_IVA;
   CLOSE C_IVC;
   P_IVA := NVL(P_IVA,0);

   OPEN C_COMP;
   FETCH C_COMP INTO R_COMP;
   IF C_COMP%FOUND THEN
	    P_CRV_AJUSTE_SERV    := NVL(R_COMP.CRV_AJUSTE_SERV,0);
	    P_CRV_AJUSTE_CXPT    := NVL(R_COMP.CRV_AJUSTE_CXPT,0);
      HAY_CRV := 'S';
   ELSE
   	  P_CRV_AJUSTE_SERV    := 0;
   	  P_CRV_AJUSTE_CXPT    := 0;
      HAY_CRV := 'N';
   END IF;
   CLOSE C_COMP;

   OPEN C_COMPRAS;
   FETCH C_COMPRAS INTO R_COMPRAS;
   CLOSE C_COMPRAS;

   OPEN C_VENTAS;
   FETCH C_VENTAS INTO R_VENTAS;
   CLOSE C_VENTAS;

	 P_CRV_OPERACIONES    := (NVL(R_COMPRAS.VALOR_OP,0) + NVL(R_COMPRAS.EXTEMPO,0)) - (NVL(R_VENTAS.VALOR_OP,0) + NVL(R_VENTAS.EXTEMPO,0));
   P_CRV_COMISIONES     := -(NVL(R_COMPRAS.VALOR_COMISION,0) + NVL(R_VENTAS.VALOR_COMISION,0));
	 P_CRV_IVA            := NVL(R_COMPRAS.VALOR_IVA,0) + NVL(R_VENTAS.VALOR_IVA,0);
	 P_CRV_SERVICIO_BOLSA := NVL(R_COMPRAS.VALOR_BOLSA,0) + NVL(R_VENTAS.VALOR_BOLSA,0);
   P_CRV_SERVICIO_BOLSA := ROUND((P_CRV_SERVICIO_BOLSA + (P_CRV_SERVICIO_BOLSA * P_IVA)),2);
	 P_CRV_CARGO_PUNTA    := NVL(R_COMPRAS.CARGO_PUNTA,0) + NVL(R_VENTAS.CARGO_PUNTA,0);
   P_CRV_CARGO_PUNTA    := ROUND((P_CRV_CARGO_PUNTA + (P_CRV_CARGO_PUNTA * P_IVA)),2);


   OPEN C_AJUSTE;
   FETCH C_AJUSTE INTO R_AJUSTE;
   WHILE C_AJUSTE%FOUND LOOP
      IF R_AJUSTE.MCC_TMC_MNEMONICO IN ('RCPR','ACPR','CPR','RSECA','RSECS','SECA','SECS') THEN
         AJ_OP_COMPRA := AJ_OP_COMPRA + R_AJUSTE.VALOR_AJ;
      ELSIF R_AJUSTE.MCC_TMC_MNEMONICO IN ('RVEN','AVEN','VEN','RSEVA','RSEVS','SEVA','SEVS') THEN
         AJ_OP_VENTA := AJ_OP_VENTA + R_AJUSTE.VALOR_AJ;
      ELSIF R_AJUSTE.MCC_TMC_MNEMONICO IN ('RCOC','ACOC','COC') THEN
         AJ_COM_COMPRA := AJ_COM_COMPRA + R_AJUSTE.VALOR_AJ;
      ELSIF R_AJUSTE.MCC_TMC_MNEMONICO IN ('RCOV','ACOV','COV') THEN
         AJ_COM_VENTA := AJ_COM_VENTA + R_AJUSTE.VALOR_AJ;
      ELSIF R_AJUSTE.MCC_TMC_MNEMONICO IN ('RIVAC','IVAC') THEN
      	 AJ_IVA_COM_COMPRA := AJ_IVA_COM_COMPRA + R_AJUSTE.VALOR_AJ;
      ELSIF R_AJUSTE.MCC_TMC_MNEMONICO IN ('RIVAV','IVAV') THEN
      	 AJ_IVA_COM_VENTA := AJ_IVA_COM_VENTA + R_AJUSTE.VALOR_AJ;
      END IF;
      FETCH C_AJUSTE INTO R_AJUSTE;
   END LOOP;
   CLOSE C_AJUSTE;


   P_CRV_AJUSTE_OPER    := AJ_OP_COMPRA - AJ_OP_VENTA;
   P_CRV_AJUSTE_COMIS   := AJ_COM_COMPRA + AJ_COM_VENTA;
   P_CRV_AJUSTE_IVA     := AJ_IVA_COM_COMPRA + AJ_IVA_COM_VENTA;



   P_CRV_OPERACIONES    :=   NVL(P_CRV_OPERACIONES,0)   +  NVL(P_CRV_AJUSTE_OPER,0);
   P_CRV_COMISIONES     :=   NVL(P_CRV_COMISIONES,0)    +  NVL(P_CRV_AJUSTE_COMIS,0);
   P_CRV_IVA            :=   NVL(P_CRV_IVA ,0)          +  NVL(P_CRV_AJUSTE_IVA,0);
	 P_CRV_SERVICIO_BOLSA :=   NVL(P_CRV_SERVICIO_BOLSA,0)+  NVL(P_CRV_AJUSTE_SERV,0);
	 P_CRV_CARGO_PUNTA    :=   NVL(P_CRV_CARGO_PUNTA,0)   +  NVL(P_CRV_AJUSTE_CXPT,0);

   --P_COMPENSACION  := P_CRV_OPERACIONES + P_CRV_COMISIONES + P_CRV_IVA + P_CRV_SERVICIO_BOLSA + P_CRV_CARGO_PUNTA;
   P_COMPENSACION  := P_CRV_OPERACIONES + P_CRV_COMISIONES + P_CRV_SERVICIO_BOLSA + P_CRV_CARGO_PUNTA + NVL(P_CRV_AJUSTE_COMIS,0);


   IF HAY_CRV = 'N'  THEN
      R_COMP.CRV_NETO_COMPENSADO:= P_CRV_OPERACIONES;
   END IF;

   --
   SELECT INSTRB(P_COMPENSACION, '-', 1, 1) INTO P_SIGNO FROM DUAL;
      IF P_SIGNO = 1 THEN
         P_COMPENSACION1:=P_COMPENSACION * (-1);
      ELSE
         P_COMPENSACION1:=P_COMPENSACION * (-1);
      END IF;
         P_CRV_NETO_COMPENSADO1:= R_COMP.CRV_NETO_COMPENSADO;

      SELECT INSTRB (P_CRV_NETO_COMPENSADO, '-', 1, 1) INTO P_SIGNO1 FROM DUAL;
      IF P_SIGNO1 = 1 THEN
         P_CRV_NETO_COMPENSADO:=P_CRV_NETO_COMPENSADO1 * (-1);
      ELSE
         P_CRV_NETO_COMPENSADO:=P_CRV_NETO_COMPENSADO1 * (-1);
      END IF;
   IF P_FLAG IS NULL THEN
   INSERT INTO GL_COMPENSACION_SEBRA
           ( CS_FECHA
            ,CS_PRO_MNEMONICO
            ,CS_COMPENSACION
            ,CS_COMPENSADO
            ,	CS_PENDIENTE )
   VALUES (  P_FECHA
            ,'ACC'
            ,NVL(P_COMPENSACION1,0)
            ,NVL(P_CRV_NETO_COMPENSADO,0)
            ,NVL(P_COMPENSACION1,0) - NVL(P_CRV_NETO_COMPENSADO,0));
    ELSIF P_FLAG  = 'S' THEN
       INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
                                      ,GCB_CBA_BAN_CODIGO
                                      ,GCB_CBA_NUMERO_CUENTA
                                      ,GCB_COMPENSACION
                                      ,GCB_COMPENSADO
                                      ,GCB_PENDIENTE
                                      ,GCB_OPERACION)

        VALUES (P_FECHA
               ,0
               ,'62250063'
               ,NVL(P_COMPENSACION1,0)
               ,NVL(P_CRV_NETO_COMPENSADO,0)
               ,NVL(P_COMPENSACION1,0) - NVL(P_CRV_NETO_COMPENSADO,0)
               ,'ACC')  ;
    END IF;

   -- DATOS DE COMPENSACION SEBRA DEL PRODUCTO RF
   -- PARA INSERTAR EL DETALLADO POR CONTRAPARTE
   OPEN C_RF;
   FETCH C_RF INTO R_RF;
   WHILE C_RF%FOUND LOOP
      OPEN C_COMP_RF(R_RF.NID, R_RF.TID, R_RF.COD);
      FETCH C_COMP_RF INTO R_COMP_RF;
      IF C_COMP_RF%NOTFOUND THEN
         R_COMP_RF.VR := 0;
      END IF;
      CLOSE C_COMP_RF;

      INSERT INTO GL_COMPENSACION_RF_CONTRAPARTE
              ( CC_FECHA
               ,CC_PRO_MNEMONICO
               ,CC_COMPENSACION
               ,CC_COMPENSADO
               ,CC_PENDIENTE
               ,CC_FIC_PER_NUM_IDEN
               ,CC_FIC_PER_TID_CODIGO
               ,CC_FIC_CODIGO_BOLSA    )
      VALUES (  P_FECHA
               ,'RF'
               ,NVL(R_RF.VR,0)
               ,NVL(-R_COMP_RF.VR,0)
               ,NVL(R_RF.VR,0) + NVL(R_COMP_RF.VR,0)
               ,R_RF.NID
               ,R_RF.TID
               ,R_RF.COD
               );

      FETCH C_RF INTO R_RF;
   END LOOP;
   CLOSE C_RF;

   -- TOTAL RENTA FIJA : PARA TRAER EL DATO DE COMPENSACION SEBRA
   OPEN C_RFTOTAL;
   FETCH C_RFTOTAL INTO R_RFTOTAL;
   IF C_RFTOTAL%FOUND THEN
   IF p_flag IS NULL THEN
      INSERT INTO GL_COMPENSACION_SEBRA
           ( CS_FECHA
            ,CS_PRO_MNEMONICO
            ,CS_COMPENSACION
            ,CS_COMPENSADO
            ,CS_PENDIENTE )
      VALUES (R_RFTOTAL.CC_FECHA
             ,R_RFTOTAL.CC_PRO_MNEMONICO
             ,NVL(R_RFTOTAL.CC_COMPENSACION,0)
             ,NVL(R_RFTOTAL.CC_COMPENSADO,0)
             ,NVL(R_RFTOTAL.CC_PENDIENTE,0));
     ELSIF P_FLAG  = 'S' THEN
       INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
                                      ,GCB_CBA_BAN_CODIGO
                                      ,GCB_CBA_NUMERO_CUENTA
                                      ,GCB_COMPENSACION
                                      ,GCB_COMPENSADO
                                      ,GCB_PENDIENTE
                                      ,GCB_OPERACION)

        VALUES (R_RFTOTAL.CC_FECHA
               ,0
               ,'62250063'
               ,NVL(R_RFTOTAL.CC_COMPENSACION,0)
               ,NVL(R_RFTOTAL.CC_COMPENSADO,0)
               ,NVL(R_RFTOTAL.CC_PENDIENTE,0)
               ,R_RFTOTAL.CC_PRO_MNEMONICO)  ;
   END IF;

   END IF;
   CLOSE C_RFTOTAL;

   COMMIT;
END COMPENSACION_SEBRA;



PROCEDURE COMPENSACION_SEBRA_HCO (P_FECHA DATE, P_NEGOCIO NUMBER DEFAULT NULL, p_flag VARCHAR2 DEFAULT NULL) IS
   CURSOR C_CSE IS
      SELECT CSE_FECHA,
             CSE_PRO_MNEMONICO,
             CSE_VALOR,
             CSE_CRV_CONSECUTIVO,
             CSE_NEG_CONSECUTIVO
      FROM COMPENSACIONES_SEBRA
      WHERE CSE_FECHA >= TRUNC(P_FECHA)
        AND CSE_FECHA <  TRUNC(P_FECHA + 1)
        AND CSE_PRO_MNEMONICO IN ('ACC', 'RF')
        AND CSE_NEG_CONSECUTIVO =P_NEGOCIO;
    R_CSE C_CSE%ROWTYPE;


   CURSOR C_CSB IS
      SELECT 'X'
      FROM COMPENSACIONES_SEBRA
      WHERE CSE_FECHA >= TRUNC(P_FECHA)
        AND CSE_FECHA <  TRUNC(P_FECHA + 1)
        AND CSE_PRO_MNEMONICO = ('RF')
        AND CSE_NEG_CONSECUTIVO =P_NEGOCIO;

   CURSOR C_RF_HIS IS
   SELECT SUM (VR_COMPENSACION)VR_COMPENSACION

   FROM (

   SELECT P_FECHA,
          'RF',
          SUM(VR) VR_COMPENSACION,
          SUM(VR) VR_COMPENSADO,
          0 VR_PENDIENTE,
          NID,
          TID,
          COD
   FROM   (       SELECT CPT_FIC_PER_NUM_IDEN   NID,
                         CPT_FIC_PER_TID_CODIGO TID,
                         CPT_FIC_CODIGO_BOLSA   COD,
                         SUM(CPT_MONTO) *(-1)       VR
                  FROM COMPENSACIONES_PRODUCTOS,
                       ORDENES_DE_PAGO
                  WHERE CPT_ODP_CONSECUTIVO = ODP_CONSECUTIVO
                    AND CPT_ODP_SUC_CODIGO = ODP_SUC_CODIGO
                    AND CPT_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND CPT_FECHA >= TRUNC(P_FECHA)
                    AND CPT_FECHA <   TRUNC(P_FECHA)+1
                    AND CPT_PRO_MNEMONICO = 'RF'
                  GROUP BY CPT_FIC_PER_NUM_IDEN,
                           CPT_FIC_PER_TID_CODIGO,
                           CPT_FIC_CODIGO_BOLSA
                  UNION ALL
                  SELECT CPT_FIC_PER_NUM_IDEN    NID,
                         CPT_FIC_PER_TID_CODIGO  TID,
                         CPT_FIC_CODIGO_BOLSA    COR,
                         SUM(CPT_MONTO)  *(-1)         VR
                  FROM COMPENSACIONES_PRODUCTOS,
                       RECIBOS_DE_CAJA
                  WHERE CPT_RCA_CONSECUTIVO = RCA_CONSECUTIVO
                    AND CPT_RCA_SUC_CODIGO = RCA_SUC_CODIGO
                    AND CPT_RCA_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
                    AND RCA_REVERSADO = 'N'
                    AND CPT_FECHA >= TRUNC(P_FECHA)
                    AND CPT_FECHA <   TRUNC(P_FECHA)+1
                    AND CPT_PRO_MNEMONICO = 'RF'
                  GROUP BY CPT_FIC_PER_NUM_IDEN,
                           CPT_FIC_PER_TID_CODIGO,
                           CPT_FIC_CODIGO_BOLSA)
      GROUP BY P_FECHA, 'RF', 0, NID, TID, COD) ;




   P_COMPENSACION number:= 0;
   P_SIGNO number;
   P_SIGNO1 number;
   P_NETO_COMPENSADO1 NUMBER:= 0;
   P_NETO_COMPENSADO NUMBER:= 0;
   V_COMPENSADO NUMBER;
   V_EXISTE VARCHAR2(1);

BEGIN
	 DELETE FROM GL_COMPENSACION_SEBRA;

	 DELETE FROM GL_COMPENSACION_RF_CONTRAPARTE;

	 COMMIT;
   OPEN C_CSB;
	    FETCH C_CSB INTO V_EXISTE;
   CLOSE C_CSB;
  IF NVL(V_EXISTE,'Z') <> 'X' THEN
     INSERT INTO COMPENSACIONES_SEBRA
          (CSE_FECHA
          ,CSE_PRO_MNEMONICO
          ,CSE_VALOR
          ,CSE_CRV_CONSECUTIVO
          ,CSE_NEG_CONSECUTIVO)
     VALUES
           (P_FECHA
           ,'RF'
           ,0
           ,NULL
           ,P_NEGOCIO
           );
     COMMIT;
   END IF;

	 OPEN C_CSE;
	 FETCH C_CSE INTO R_CSE;
	 WHILE C_CSE%FOUND LOOP

      IF R_CSE.CSE_PRO_MNEMONICO = 'ACC' THEN
         P_NETO_COMPENSADO := NVL(R_CSE.CSE_VALOR,0);

         IF P_FLAG IS NULL THEN
           INSERT INTO GL_COMPENSACION_SEBRA
                 ( CS_FECHA
                  ,CS_PRO_MNEMONICO
                  ,CS_COMPENSACION
                  ,CS_COMPENSADO
                  ,CS_PENDIENTE
                  ,CS_CRV_CONSECUTIVO)
           VALUES (R_CSE.CSE_FECHA
                   ,R_CSE.CSE_PRO_MNEMONICO
                   ,P_NETO_COMPENSADO
                   ,P_NETO_COMPENSADO
                   ,0
                   ,R_CSE.CSE_CRV_CONSECUTIVO);
        ELSIF  P_FLAG = 'S' THEN
          INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
                                              ,GCB_CBA_BAN_CODIGO
                                              ,GCB_CBA_NUMERO_CUENTA
                                              ,GCB_COMPENSACION
                                              ,GCB_COMPENSADO
                                              ,GCB_PENDIENTE
                                              ,GCB_OPERACION)

           VALUES (R_CSE.CSE_FECHA
                ,0
                ,'62250063'
                ,P_NETO_COMPENSADO
                ,P_NETO_COMPENSADO
                ,0
                ,R_CSE.CSE_PRO_MNEMONICO
                )  ;
        END IF;
      ELSE
         IF P_FLAG IS NULL THEN
           INSERT INTO GL_COMPENSACION_SEBRA
                 ( CS_FECHA
                  ,CS_PRO_MNEMONICO
                  ,CS_COMPENSACION
                  ,CS_COMPENSADO
                  ,CS_PENDIENTE
                  ,CS_CRV_CONSECUTIVO)
           VALUES (R_CSE.CSE_FECHA
                   ,R_CSE.CSE_PRO_MNEMONICO
                   ,NVL(R_CSE.CSE_VALOR,0)
                   ,NVL(R_CSE.CSE_VALOR,0)
                   ,0
                   ,R_CSE.CSE_CRV_CONSECUTIVO);
          ELSIF P_FLAG = 'S' THEN
            INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
                                              ,GCB_CBA_BAN_CODIGO
                                              ,GCB_CBA_NUMERO_CUENTA
                                              ,GCB_COMPENSACION
                                              ,GCB_COMPENSADO
                                              ,GCB_PENDIENTE
                                              ,GCB_OPERACION)

           VALUES (R_CSE.CSE_FECHA
                ,0
                ,'62250063'
                ,NVL(R_CSE.CSE_VALOR,0)
                ,NVL(R_CSE.CSE_VALOR,0)
                ,0
                ,R_CSE.CSE_PRO_MNEMONICO
                )  ;
          END IF;


      END IF;

   OPEN C_RF_HIS;
	    FETCH C_RF_HIS INTO V_COMPENSADO;
   CLOSE C_RF_HIS;

    IF V_COMPENSADO <> R_CSE.CSE_VALOR AND  R_CSE.CSE_PRO_MNEMONICO = 'RF'  AND P_NEGOCIO = 2  THEN
      UPDATE COMPENSACIONES_SEBRA
         SET CSE_VALOR = V_COMPENSADO
         WHERE CSE_FECHA >= TRUNC(P_FECHA)
         AND CSE_FECHA <  TRUNC(P_FECHA + 1)
         AND CSE_PRO_MNEMONICO IN ('RF')
         AND CSE_NEG_CONSECUTIVO =P_NEGOCIO;
    END IF;

   FETCH C_CSE INTO R_CSE;
	 END LOOP;
	 CLOSE C_CSE;

	 IF p_flag IS NULL THEN
   INSERT INTO GL_COMPENSACION_RF_CONTRAPARTE
      (CC_FECHA,
       CC_PRO_MNEMONICO,
       CC_COMPENSACION,
       CC_COMPENSADO,
       CC_PENDIENTE,
       CC_FIC_PER_NUM_IDEN,
       CC_FIC_PER_TID_CODIGO,
       CC_FIC_CODIGO_BOLSA)
   SELECT P_FECHA,
          'RF',
          SUM(VR) VR_COMPENSACION,
          SUM(VR) VR_COMPENSADO,
          0 VR_PENDIENTE,
          NID,
          TID,
          COD
   FROM   (       SELECT CPT_FIC_PER_NUM_IDEN   NID,
                         CPT_FIC_PER_TID_CODIGO TID,
                         CPT_FIC_CODIGO_BOLSA   COD,
                         SUM(CPT_MONTO)  *(-1)       VR
                  FROM COMPENSACIONES_PRODUCTOS,
                       ORDENES_DE_PAGO
                  WHERE CPT_ODP_CONSECUTIVO = ODP_CONSECUTIVO
                    AND CPT_ODP_SUC_CODIGO = ODP_SUC_CODIGO
                    AND CPT_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
                    AND ODP_ESTADO = 'APR'
                    AND CPT_FECHA >= TRUNC(P_FECHA)
                    AND CPT_FECHA <  TRUNC(P_FECHA +1)
                    AND CPT_PRO_MNEMONICO = 'RF'
                  GROUP BY CPT_FIC_PER_NUM_IDEN, CPT_FIC_PER_TID_CODIGO, CPT_FIC_CODIGO_BOLSA
                  UNION ALL
                  SELECT CPT_FIC_PER_NUM_IDEN    NID,
                         CPT_FIC_PER_TID_CODIGO  TID,
                         CPT_FIC_CODIGO_BOLSA    COR,
                         SUM(CPT_MONTO)  *(-1)       VR
                  FROM COMPENSACIONES_PRODUCTOS,
                       RECIBOS_DE_CAJA
                  WHERE CPT_RCA_CONSECUTIVO = RCA_CONSECUTIVO
                    AND CPT_RCA_SUC_CODIGO = RCA_SUC_CODIGO
                    AND CPT_RCA_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
                    AND RCA_REVERSADO = 'N'
                    AND CPT_FECHA >= TRUNC(P_FECHA)
                    AND CPT_FECHA <  TRUNC(P_FECHA+1)
                    AND CPT_PRO_MNEMONICO = 'RF'
                  GROUP BY CPT_FIC_PER_NUM_IDEN,
                           CPT_FIC_PER_TID_CODIGO,
                           CPT_FIC_CODIGO_BOLSA)
      GROUP BY NID, TID, COD;


      INSERT INTO GL_DETALLE_OP_COMPENSA_RF (
                    CF_LIC_NUMERO_OPERACION
                   ,CF_LIC_NUMERO_FRACCION
                   ,CF_LIC_TIPO_OPERACION
                   ,CF_LIC_BOL_MNEMONICO
                   ,CF_LIC_VOL_NETO_FRACCION
                   ,CF_LIC_VOL_FRACCION
                   ,CF_LIC_CANTIDAD_FRACCION
                   ,CF_LIC_PRECIO
                   ,CF_LIC_VALOR_COMISION
                   ,CF_LIC_SERV_BOLSA_FIJO
                   ,CF_LIC_SERV_BOLSA_VARIABLE
                   ,CF_LIC_COD_CMSNSTA_CMPRDOR
                   ,CF_NID_CONTRAPARTE
                   ,CF_TID_CONTRAPARTE
                   ,CF_FIC_CODIGO_CONTRAPARTE
                   ,CF_NOMBRE_CONTRAPARTE
                   ,CF_LIC_COD_CMSNSTA_VNDDOR
                   ,CF_LIC_FECHA_OPERACION
                   ,CF_LIC_FECHA_CUMPLIMIENTO
                   ,CF_LIC_FECHA_PACTO_CUMPLIM
                   ,CF_LIC_MNEMOTECNICO_TITULO
                   ,CF_ENA_DESCRIPCION
                   ,CF_LIC_CLASE_TRANSACCION
                   ,CF_LIC_SUCURSAL_CUMPLIMIENTO
                   ,CF_TIPO_MEC
                   ,CF_OVE_CONSECUTIVO
                   ,CF_COC_CTO_MNEMONICO
                   ,CF_PER_NUM_IDEN
                   ,CF_PER_TID_CODIGO
                   ,CF_PER_NOMBRE_USUARIO  )
      SELECT LIC.LIC_NUMERO_OPERACION CF_LIC_NUMERO_OPERACION ,
             LIC.LIC_NUMERO_FRACCION CF_LIC_NUMERO_FRACCION ,
             LIC.LIC_TIPO_OPERACION CF_LIC_TIPO_OPERACION ,
             LIC.LIC_BOL_MNEMONICO CF_LIC_BOL_MNEMONICO ,
             LIC.LIC_VOLUMEN_NETO_FRACCION CF_LIC_VOL_NETO_FRACCION ,
             LIC.LIC_VOLUMEN_FRACCION CF_LIC_VOL_FRACCION ,
             LIC.LIC_CANTIDAD_FRACCION CF_LIC_CANTIDAD_FRACCION ,
             LIC.LIC_PRECIO CF_LIC_PRECIO ,
             LIC.LIC_VALOR_COMISION CF_LIC_VALOR_COMISION ,
             LIC.LIC_SERVICIO_BOLSA_FIJO CF_LIC_SERV_BOLSA_FIJO ,
             LIC.LIC_SERVICIO_BOLSA_VARIABLE CF_LIC_SERV_BOLSA_VARIABLE ,
             LIC.LIC_COD_CMSNSTA_CMPRDOR CF_LIC_COD_CMSNSTA_CMPRDOR ,
             CPT.CPT_FIC_PER_NUM_IDEN CF_NID_CONTRAPARTE,
             CPT.CPT_FIC_PER_TID_CODIGO CF_TID_CONTRAPARTE,
             CPT.CPT_FIC_CODIGO_BOLSA CF_FIC_CODIGO_CONTRAPARTE,
             PER1.PER_NOMBRE CF_NOMBRE_CONTRAPARTE,
             LIC.LIC_COD_CMSNSTA_VNDDOR CF_LIC_COD_CMSNSTA_VNDDOR ,
             LIC.LIC_FECHA_OPERACION CF_LIC_FECHA_OPERACION ,
             LIC.LIC_FECHA_CUMPLIMIENTO CF_LIC_FECHA_CUMPLIMIENTO ,
             LIC.LIC_FECHA_PACTO_CUMPLIMIENTO CF_LIC_FECHA_PACTO_CUMPLIM,
             LIC.LIC_MNEMOTECNICO_TITULO CF_LIC_MNEMOTECNICO_TITULO ,
             ENA.ENA_DESCRIPCION CF_ENA_DESCRIPCION,
             LIC.LIC_CLASE_TRANSACCION CF_LIC_CLASE_TRANSACCION,
             LIC.LIC_SUCURSAL_CUMPLIMIENTO CF_LIC_SUCURSAL_CUMPLIMIENTO,
             OVE.OVE_TIPO_MEC CF_TIPO_MEC,
             OVE.OVE_CONSECUTIVO CF_OVE_CONSECUTIVO ,
             OVE.OVE_COC_CTO_MNEMONICO CF_COC_CTO_MNEMONICO ,
             OVE.OVE_PER_NUM_IDEN_ES_DUENO CF_PER_NUM_IDEN ,
             OVE.OVE_PER_TID_CODIGO_ES_DUENO CF_PER_TID_CODIGO ,
             PER_NOMBRE_USUARIO CF_PER_NOMBRE_USUARIO
      FROM COMPENSACIONES_PRODUCTOS CPT,
           LIQUIDACIONES_COMERCIAL LIC ,
           ORDENES_VENTA OVE ,
           ESPECIES_NACIONALES ENA,
           PERSONAS PER,
           FILTRO_PERSONAS PER1,
           RECIBOS_DE_CAJA RCA
      WHERE CPT.CPT_LIC_NUMERO_OPERACION = LIC.LIC_NUMERO_OPERACION
        AND CPT.CPT_LIC_NUMERO_FRACCION = LIC.LIC_NUMERO_FRACCION
        AND CPT.CPT_LIC_TIPO_OPERACION = LIC.LIC_TIPO_OPERACION
        AND CPT.CPT_LIC_BOL_MNEMONICO =  LIC.LIC_BOL_MNEMONICO
        AND LIC.LIC_OVE_CONSECUTIVO       = OVE.OVE_CONSECUTIVO
        AND LIC.LIC_OVE_COC_CTO_MNEMONICO   = OVE.OVE_COC_CTO_MNEMONICO
        AND LIC.LIC_BOL_MNEMONICO           = OVE.OVE_BOL_MNEMONICO
        AND LIC.LIC_MNEMOTECNICO_TITULO     = ENA.ENA_MNEMONICO
        AND OVE.OVE_PER_NUM_IDEN_ES_DUENO   = PER.PER_NUM_IDEN (+)
        AND OVE.OVE_PER_TID_CODIGO_ES_DUENO = PER.PER_TID_CODIGO (+)
        AND CPT.CPT_FIC_PER_NUM_IDEN        = PER1.PER_NUM_IDEN
        AND CPT.CPT_FIC_PER_TID_CODIGO      = PER1.PER_TID_CODIGO
        AND CPT_RCA_CONSECUTIVO = RCA_CONSECUTIVO
        AND CPT_RCA_SUC_CODIGO = RCA_SUC_CODIGO
        AND CPT_RCA_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
        AND RCA_REVERSADO = 'N'
        AND CPT_FECHA >= TRUNC(P_FECHA)
        AND CPT_FECHA <  TRUNC(P_FECHA+1)
      UNION ALL
      SELECT LIC.LIC_NUMERO_OPERACION CF_LIC_NUMERO_OPERACION ,
             LIC.LIC_NUMERO_FRACCION CF_LIC_NUMERO_FRACCION ,
             LIC.LIC_TIPO_OPERACION CF_LIC_TIPO_OPERACION ,
             LIC.LIC_BOL_MNEMONICO CF_LIC_BOL_MNEMONICO ,
             LIC.LIC_VOLUMEN_NETO_FRACCION CF_LIC_VOL_NETO_FRACCION ,
             LIC.LIC_VOLUMEN_FRACCION CF_LIC_VOL_FRACCION ,
             LIC.LIC_CANTIDAD_FRACCION CF_LIC_CANTIDAD_FRACCION ,
             LIC.LIC_PRECIO CF_LIC_PRECIO ,
             LIC.LIC_VALOR_COMISION CF_LIC_VALOR_COMISION ,
             LIC.LIC_SERVICIO_BOLSA_FIJO CF_LIC_SERV_BOLSA_FIJO ,
             LIC.LIC_SERVICIO_BOLSA_VARIABLE CF_LIC_SERV_BOLSA_VARIABLE ,
             LIC.LIC_COD_CMSNSTA_CMPRDOR CF_LIC_COD_CMSNSTA_CMPRDOR ,
             CPT.CPT_FIC_PER_NUM_IDEN CF_NID_CONTRAPARTE,
             CPT.CPT_FIC_PER_TID_CODIGO CF_TID_CONTRAPARTE,
             CPT.CPT_FIC_CODIGO_BOLSA CF_FIC_CODIGO_CONTRAPARTE,
             PER1.PER_NOMBRE CF_NOMBRE_CONTRAPARTE,
             LIC.LIC_COD_CMSNSTA_VNDDOR CF_LIC_COD_CMSNSTA_VNDDOR ,
             LIC.LIC_FECHA_OPERACION CF_LIC_FECHA_OPERACION ,
             LIC.LIC_FECHA_CUMPLIMIENTO CF_LIC_FECHA_CUMPLIMIENTO ,
             LIC.LIC_FECHA_PACTO_CUMPLIMIENTO CF_LIC_FECHA_PACTO_CUMPLIM,
             LIC.LIC_MNEMOTECNICO_TITULO CF_LIC_MNEMOTECNICO_TITULO ,
             ENA.ENA_DESCRIPCION CF_ENA_DESCRIPCION,
             LIC.LIC_CLASE_TRANSACCION CF_LIC_CLASE_TRANSACCION,
             LIC.LIC_SUCURSAL_CUMPLIMIENTO CF_LIC_SUCURSAL_CUMPLIMIENTO,
             OCO.OCO_TIPO_MEC CF_TIPO_MEC,
             OCO.OCO_CONSECUTIVO CF_OCO_CONSECUTIVO ,
             OCO.OCO_COC_CTO_MNEMONICO CF_COC_CTO_MNEMONICO ,
             OCO.OCO_PER_NUM_IDEN_ES_DUENO CF_PER_NUM_IDEN ,
             OCO.OCO_PER_TID_CODIGO_ES_DUENO CF_PER_TID_CODIGO ,
             PER_NOMBRE_USUARIO CF_PER_NOMBRE_USUARIO
      FROM COMPENSACIONES_PRODUCTOS CPT,
           LIQUIDACIONES_COMERCIAL LIC ,
           ORDENES_COMPRA OCO ,
           ESPECIES_NACIONALES ENA,
           PERSONAS PER,
           FILTRO_PERSONAS PER1,
           ORDENES_DE_PAGO ODP
      WHERE CPT.CPT_LIC_NUMERO_OPERACION = LIC.LIC_NUMERO_OPERACION
        AND CPT.CPT_LIC_NUMERO_FRACCION = LIC.LIC_NUMERO_FRACCION
        AND CPT.CPT_LIC_TIPO_OPERACION = LIC.LIC_TIPO_OPERACION
        AND CPT.CPT_LIC_BOL_MNEMONICO =  LIC.LIC_BOL_MNEMONICO
        AND LIC.LIC_OCO_CONSECUTIVO       = OCO.OCO_CONSECUTIVO
        AND LIC.LIC_OCO_COC_CTO_MNEMONICO   = OCO.OCO_COC_CTO_MNEMONICO
        AND LIC.LIC_BOL_MNEMONICO           = OCO.OCO_BOL_MNEMONICO
        AND LIC.LIC_MNEMOTECNICO_TITULO     = ENA.ENA_MNEMONICO
        AND OCO.OCO_PER_NUM_IDEN_ES_DUENO   = PER.PER_NUM_IDEN (+)
        AND OCO.OCO_PER_TID_CODIGO_ES_DUENO = PER.PER_TID_CODIGO (+)
        AND CPT.CPT_FIC_PER_NUM_IDEN        = PER1.PER_NUM_IDEN
        AND CPT.CPT_FIC_PER_TID_CODIGO      = PER1.PER_TID_CODIGO
        AND CPT_ODP_CONSECUTIVO = ODP_CONSECUTIVO
        AND CPT_ODP_SUC_CODIGO = ODP_SUC_CODIGO
        AND CPT_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
        AND ODP_ESTADO = 'APR'
        AND CPT_FECHA >= TRUNC(P_FECHA)
        AND CPT_FECHA <  TRUNC(P_FECHA+1);
END IF;
   COMMIT;
END COMPENSACION_SEBRA_HCO;



/************************************************************************************************************
****  PROCEDIMIENTO PARA ENVIAR MAIL A LOS COMERCIALES Y JEFES DE MESA CON LAS OPERACIONES DE VENTA       ***
****  QUE EN LA ORDEN ESTASN EXCEDA SALDO O SIN TITULO Y ESTA PENDIENTE POR DEFINIR COMO SECUBRE EL SALDO ***
****  PENDIENTE A TRAVES DE LA FORMA DE ALISTAMIENTO DE PRECUMPLIMIENTO - OPPECU                          ***
*************************************************************************************************************/
PROCEDURE MAIL_VTAS_PENDIENTES(P_TX IN NUMBER DEFAULT NULL) IS

   P_FECHA              DATE;
   P_FECHA_CUMPLIMIENTO DATE;
   DIAS                 NUMBER;

   CURSOR C_DNH IS
      SELECT DNH_FECHA
        FROM DIAS_NO_HABILES
       WHERE DNH_FECHA >= TRUNC(P_FECHA)
         AND DNH_FECHA < TRUNC(P_FECHA + 1);
   DNH C_DNH%ROWTYPE;

   CURSOR C_PER (P_FCUMPLE DATE) IS
      SELECT DISTINCT  VP.VPC_PER_NUM_IDEN
                      ,VP.VPC_PER_TID_CODIGO
                      ,VP.VPC_PER_NOMBRE_USUARIO
                      ,VP.VPC_CPR_MNEMONICO
                      ,VP.PER_MAIL_CORREDOR
      FROM  (SELECT  VPC_COC_MNEMONICO
                    ,VPC_FECHA_CUMPLIMIENTO
                    ,VPC_CLI_PER_NUM_IDEN
                    ,VPC_CLI_PER_TID_CODIGO
                    ,VPC_CLI_NOMBRE
                    ,VPC_ENA_MNEMONICO
                    ,VPC_CANTIDAD_FRACCION
                    ,VPC_PER_NUM_IDEN
                    ,VPC_PER_TID_CODIGO
                    ,VPC_PER_NOMBRE_USUARIO
                    ,VPC_CPR_MNEMONICO
                    ,PER_MAIL_CORREDOR
                    ,NVL(SUM(APR_SALDO_LIBERAR),0) VR_LIBERADO
                    ,VPC_CANTIDAD_FRACCION - NVL(SUM(APR_SALDO_LIBERAR),0) SDO_PENDIENTE
             FROM VENTAS_POR_CUMPLIR VPC1,
                  PERSONAS,
                  CLIENTES,
                  ACCIONES_PRECUMPLIMIENTO APR4
             WHERE VPC1.VPC_PER_NUM_IDEN             = PER_NUM_IDEN
               AND VPC1.VPC_PER_TID_CODIGO           = PER_TID_CODIGO
               AND VPC_CLI_PER_NUM_IDEN              = CLI_PER_NUM_IDEN
               AND VPC_CLI_PER_TID_CODIGO            = CLI_PER_TID_CODIGO
               AND NVL(CLI_ADM_PORTAFOLIO_DCVAL,'N') = 'S'
               AND VPC1.VPC_CLI_PER_NUM_IDEN         = APR4.APR_CLI_PER_NUM_IDEN (+)
               AND VPC1.VPC_CLI_PER_TID_CODIGO       = APR4.APR_CLI_PER_TID_CODIGO (+)
               AND VPC1.VPC_ENA_MNEMONICO            = APR4.APR_ENA_MNEMONICO (+)
               AND VPC1.VPC_FECHA_CUMPLIMIENTO       = APR4.APR_FECHA_CUMPLIMIENTO (+)
               AND VPC_FECHA_CUMPLIMIENTO            >= TRUNC(P_FECHA)
               AND VPC_FECHA_CUMPLIMIENTO            <  TRUNC(P_FCUMPLE+1)
             GROUP BY VPC_COC_MNEMONICO
                     ,VPC_FECHA_CUMPLIMIENTO
                     ,VPC_CLI_PER_NUM_IDEN
                     ,VPC_CLI_PER_TID_CODIGO
                     ,VPC_CLI_NOMBRE
                     ,VPC_ENA_MNEMONICO
                     ,VPC_CANTIDAD_FRACCION
                     ,VPC_PER_NUM_IDEN
                     ,VPC_PER_TID_CODIGO
                     ,VPC_PER_NOMBRE_USUARIO
                     ,VPC_CPR_MNEMONICO
                     ,PER_MAIL_CORREDOR
             HAVING VPC_CANTIDAD_FRACCION - NVL(SUM(APR_SALDO_LIBERAR),0) > 0) VP ;
   R_PER C_PER%ROWTYPE;


   N VARCHAR2(20);

   CURSOR C_OPE (P_COR VARCHAR2, P_FCUMPLE DATE) IS
      SELECT  VPC_COC_MNEMONICO
             ,VPC_FECHA_CUMPLIMIENTO
             ,VPC_CLI_PER_NUM_IDEN
             ,VPC_CLI_PER_TID_CODIGO
             ,VPC_CLI_NOMBRE
             ,VPC_ENA_MNEMONICO
             ,VPC_CANTIDAD_FRACCION
             ,VPC_PER_NUM_IDEN
             ,VPC_PER_TID_CODIGO
             ,VPC_PER_NOMBRE_USUARIO
             ,VPC_CPR_MNEMONICO
             ,PER_MAIL_CORREDOR
             ,NVL(SUM(APR_SALDO_LIBERAR),0) VR_LIBERADO
             ,VPC_CANTIDAD_FRACCION - NVL(SUM(APR_SALDO_LIBERAR),0) SDO_PENDIENTE
      FROM VENTAS_POR_CUMPLIR VPC1,
           PERSONAS,
           CLIENTES,
           ACCIONES_PRECUMPLIMIENTO APR4
      WHERE VPC1.VPC_PER_NUM_IDEN             = PER_NUM_IDEN
        AND VPC1.VPC_PER_TID_CODIGO           = PER_TID_CODIGO
        AND VPC_CLI_PER_NUM_IDEN              = CLI_PER_NUM_IDEN
        AND VPC_CLI_PER_TID_CODIGO            = CLI_PER_TID_CODIGO
        AND NVL(CLI_ADM_PORTAFOLIO_DCVAL,'N') = 'S'
        AND VPC1.VPC_CLI_PER_NUM_IDEN         = APR4.APR_CLI_PER_NUM_IDEN (+)
        AND VPC1.VPC_CLI_PER_TID_CODIGO       = APR4.APR_CLI_PER_TID_CODIGO (+)
        AND VPC1.VPC_ENA_MNEMONICO            = APR4.APR_ENA_MNEMONICO (+)
        AND VPC1.VPC_FECHA_CUMPLIMIENTO       = APR4.APR_FECHA_CUMPLIMIENTO (+)
        AND VPC_FECHA_CUMPLIMIENTO            >= TRUNC(P_FECHA)
        AND VPC_FECHA_CUMPLIMIENTO            <  TRUNC(P_FCUMPLE+1)
        AND VPC_PER_NOMBRE_USUARIO            = P_COR
      GROUP BY VPC_COC_MNEMONICO
              ,VPC_FECHA_CUMPLIMIENTO
              ,VPC_CLI_PER_NUM_IDEN
              ,VPC_CLI_PER_TID_CODIGO
              ,VPC_CLI_NOMBRE
              ,VPC_ENA_MNEMONICO
              ,VPC_CANTIDAD_FRACCION
              ,VPC_PER_NUM_IDEN
              ,VPC_PER_TID_CODIGO
              ,VPC_PER_NOMBRE_USUARIO
              ,VPC_CPR_MNEMONICO
              ,PER_MAIL_CORREDOR
       HAVING VPC_CANTIDAD_FRACCION - NVL(SUM(APR_SALDO_LIBERAR),0) > 0;
   R_OPE C_OPE%ROWTYPE;


   conn      utl_smtp.connection;
   req       utl_http.req;
   resp      utl_http.resp;

   DIRECCION_ASESOR VARCHAR2(1000);
   DIRECCION_JEFE   VARCHAR2(1000);
   DIRECCION VARCHAR2(1000);
   FECHA DATE;
   v_bufline          VARCHAR2(4000);
   v_archivo_detalle  VARCHAR2(500);
   crlf               VARCHAR2(2) :=  CHR(13)||CHR(10);
   N_ID_PROCESO       NUMBER;
   N_TX               NUMBER;

BEGIN
	 SELECT SYSDATE INTO P_FECHA FROM DUAL;
   --se asigna el consecutivo del proceso(tabla PARAMETRIZACION_PROCESOS)
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_OPERACIONES.MAIL_VTAS_PENDIENTES');

    --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio proceso P_OPERACIONES.MAIL_VTAS_PENDIENTES. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);

   OPEN C_DNH;
   FETCH C_DNH INTO DNH;
   IF C_DNH%FOUND OR TO_CHAR(P_FECHA ,'D') IN ('7','1') THEN
      NULL;
   ELSE

      P_OPERACIONES.VENTAS_POR_CUMPLIR('ACC','DVL');

      -- MAIL PARA LOS COMERCIALES CUANDO FALTAN DOS DIAS PARA QUE SE CUMPLAN LAS OPERACIONES QUE FALTAN POR CUBRIR SALDO
      DIAS := 2;
      SELECT TRUNC(P_TOOLS.SUMAR_HABILES_A_FECHA(P_FECHA,DIAS)) INTO P_FECHA_CUMPLIMIENTO FROM DUAL;
      OPEN C_PER (P_FECHA_CUMPLIMIENTO);
      FETCH C_PER INTO R_PER;
      WHILE C_PER%FOUND LOOP
         SELECT TO_CHAR(SYSDATE,'DDMMYYYYHH24MISS')||'_'||lpad((1+ABS(MOD(dbms_random.random,99999))),5,'0') INTO N FROM DUAL;
         v_archivo_detalle := 'VPC_'||N;
         DIRECCION := R_PER.PER_MAIL_CORREDOR;
         DIRECCION := DIRECCION||';yladino@corredores.com;facosta@corredores.com;rgarcia@corredores.com;fmedina@corredores.com;jpena@corredores.com;riesgos@corredores.com;jnieto@corredores.com';

         conn := p_mail.begin_mail(
               sender     => 'administrador@corredores.com',
               recipients => DIRECCION,
               SUBJECT    => 'Faltantes de acciones para cumplimiento desde el '||
                             TO_CHAR(P_FECHA,'dd-Mon-yyyy')                     ||
                             ' al '                                             ||
                             TO_CHAR(P_FECHA_CUMPLIMIENTO,'dd-Mon-yyyy'),
               mime_type  => p_mail.MULTIPART_MIME_TYPE);


         p_mail.begin_attachment(conn         => conn,
                                 mime_type    => v_archivo_detalle||'/txt',
                                 inline       => TRUE,
                                 filename     => v_archivo_detalle||'.txt',
                                 transfer_enc => 'text');

         -- ENCABEZADOS
         v_bufline := 'RF/ACC'||';'||
                      'NUM IDENTIF CLIENTE'||';'||
                      'T IDENTIF CLIENTE'||';'||
                      'CLIENTE'||';'||
                      'ESPECIE'||';'||
                      'VALOR NOMINAL'||';'||
                      'FECHA CUMPLIMIENTO'||';'||
                      'SALDO POR CUBRIR'||';'||
                      'ASESOR';
         p_mail.write_mb_text(conn,v_bufline||CRLF);

         --OPERACIONES
         OPEN C_OPE(R_PER.VPC_PER_NOMBRE_USUARIO,P_FECHA_CUMPLIMIENTO);
         FETCH C_OPE INTO R_OPE;
         WHILE C_OPE%FOUND LOOP
            v_bufline := R_OPE.VPC_COC_MNEMONICO||';'||
                         R_OPE.VPC_CLI_PER_NUM_IDEN||';'||
                         R_OPE.VPC_CLI_PER_TID_CODIGO||';'||
                         R_OPE.VPC_CLI_NOMBRE||';'||
                         R_OPE.VPC_ENA_MNEMONICO||';'||
                         R_OPE.VPC_CANTIDAD_FRACCION||';'||
                         R_OPE.VPC_FECHA_CUMPLIMIENTO||';'||
                         R_OPE.SDO_PENDIENTE||';'||
                         R_OPE.VPC_PER_NOMBRE_USUARIO;
            p_mail.write_mb_text(conn,v_bufline||CRLF);

            FETCH C_OPE INTO R_OPE;
         END LOOP;
         CLOSE C_OPE;
         p_mail.end_attachment( conn => conn );
         p_mail.end_mail( conn => conn );
         FETCH C_PER INTO R_PER;
      END LOOP;
      CLOSE C_PER;

   END IF;


EXCEPTION
    WHEN OTHERS THEN
      -- P_MAIL.ENVIO_MAIL_ERROR('Error proceso P_OPERACIONES.MAIL_VTAS_PENDIENTES  ',SQLERRM);
     --Registra Traza
     P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'E',
                                    'Error proceso P_OPERACIONES.MAIL_VTAS_PENDIENTES. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
END MAIL_VTAS_PENDIENTES;

--HROSAS, REQ VAGTUD39-10
PROCEDURE SALDOS_SEBRA (P_FECHA DATE
                       ,P_NEGOCIO NUMBER
                       ,P_CUENTA VARCHAR2
                       ,p_flag VARCHAR2 DEFAULT NULL) IS
--Ordenes de pago que indican que salen recursos del SEBRA hacia Bancos Comerciales.
--Compensadas
CURSOR ODP_DESDE_SEBRA_COMPEN IS
  SELECT SUM(ODP_MONTO_ORDEN)
  FROM ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS, BANCOS
  WHERE BAN_CODIGO = ODP_BAN_CODIGO
    AND ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
    AND ODP_NEG_CONSECUTIVO = P_NEGOCIO
    AND ODP_PER_NUM_IDEN  in ('860079174', '8600791743') -- NIT CORREDORES
    AND ODP_PER_TID_CODIGO = 'NIT' --
    AND ODP_ES_CLIENTE = 'N'
    AND ODP_TPA_MNEMONICO IN ('PSE')
    AND ODP_COT_MNEMONICO = 'CSEDC'
    AND ODP_FECHA_EJECUCION > TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION <= TRUNC(P_FECHA + 1)
    AND ODP_TBC_CONSECUTIVO IS NOT NULL
    AND ODP_ESTADO = 'APR'
    AND TBC_CBA_BAN_CODIGO = 0 -- BANCO DE LA REPUBLICA
    AND TBC_CBA_NUMERO_CUENTA = P_CUENTA
    ;

--Compensadas otras cuentas
CURSOR ODP_DESDE_SEBRA_COMPEN_DIF IS
  SELECT SUM(ODP_MONTO_ORDEN)
  FROM ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS, BANCOS
  WHERE BAN_CODIGO = ODP_BAN_CODIGO
    AND ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
    AND ODP_NEG_CONSECUTIVO = P_NEGOCIO
    AND ODP_PER_NUM_IDEN  in ('860079174', '8600791743') -- NIT CORREDORES
    AND ODP_PER_TID_CODIGO = 'NIT' --
    AND ODP_ES_CLIENTE = 'N'
    AND ODP_TPA_MNEMONICO IN ('PSE')
    AND ODP_COT_MNEMONICO = 'CSEDC'
    AND ODP_FECHA_EJECUCION > TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION <= TRUNC(P_FECHA + 1)
    AND ODP_TBC_CONSECUTIVO IS NOT NULL
    AND ODP_ESTADO = 'APR'
    AND TBC_CBA_BAN_CODIGO = 0 -- BANCO DE LA REPUBLICA
    AND TBC_CBA_NUMERO_CUENTA <> P_CUENTA
    ;

--No compensadas
CURSOR ODP_DESDE_SEBRA_NO_COMPEN IS
  SELECT SUM(ODP_MONTO_ORDEN)
  FROM ORDENES_DE_PAGO
  WHERE ODP_NEG_CONSECUTIVO = P_NEGOCIO
    AND ODP_PER_NUM_IDEN  in ('860079174', '8600791743') -- NIT CORREDORES
    AND ODP_PER_TID_CODIGO = 'NIT'
    AND ODP_ES_CLIENTE = 'N'
    AND ODP_TPA_MNEMONICO IN ('PSE')
    AND ODP_COT_MNEMONICO = 'CSEDC'
    AND ODP_FECHA_EJECUCION > TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION <= TRUNC(P_FECHA + 1)
    AND ODP_ESTADO = 'APR'
    ;

--Ordenes de pago que indican que salen recursos de Bancos Comerciales hacia SEBRA.
CURSOR ODP_HACIA_SEBRA_COMPEN IS
  SELECT SUM(ODP_MONTO_ORDEN)
  FROM ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS, BANCOS
  WHERE BAN_CODIGO = TBC_CBA_BAN_CODIGO
    AND ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
    AND ODP_NEG_CONSECUTIVO = P_NEGOCIO
    AND ODP_PER_NUM_IDEN  in ('860079174', '8600791743') -- NIT CORREDORES
    AND ODP_PER_TID_CODIGO = 'NIT'
    AND ODP_ES_CLIENTE = 'N'
    AND ODP_TPA_MNEMONICO IN ('TRB')
    AND ODP_COT_MNEMONICO = 'CSEDC'
    AND ODP_FECHA_EJECUCION > TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION <= TRUNC(P_FECHA + 1)
    AND ODP_TBC_CONSECUTIVO IS NOT NULL
    AND ODP_ESTADO = 'APR'
    AND ODP_BAN_CODIGO = 0 -- BANCO DE LA REPUBLICA
    AND ODP_NUM_CUENTA_CONSIGNAR = P_CUENTA
    ;

CURSOR ODP_HACIA_SEBRA_NO_COMPEN IS
  SELECT SUM(ODP_MONTO_ORDEN)
  FROM ORDENES_DE_PAGO
  WHERE ODP_NEG_CONSECUTIVO = P_NEGOCIO
    AND ODP_PER_NUM_IDEN  in ('860079174', '8600791743') -- NIT CORREDORES
    AND ODP_PER_TID_CODIGO = 'NIT'
    AND ODP_ES_CLIENTE = 'N'
    AND ODP_TPA_MNEMONICO IN ('TRB')
    AND ODP_COT_MNEMONICO = 'CSEDC'
    AND ODP_FECHA_EJECUCION > TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION <= TRUNC(P_FECHA + 1)
    AND ODP_ESTADO = 'APR'
    AND ODP_NUM_CUENTA_CONSIGNAR = P_CUENTA;

P_DESDE_SEBRA_COMPEN     NUMBER;
P_DESDE_SEBRA_COMPEN_DIF NUMBER;
P_DESDE_SEBRA_NO_COMPEN  NUMBER;
P_HACIA_SEBRA_COMPEN     NUMBER;
P_HACIA_SEBRA_COMPEN_DIF NUMBER;
P_HACIA_SEBRA_NO_COMPEN  NUMBER;
P_SALDO_ESTIMADO         NUMBER;
P_SALDO_REAL             NUMBER;
P_SALDO_INICIAL          NUMBER;

BEGIN
 DELETE FROM GL_COMPENSACION_SEBRA WHERE CS_PRO_MNEMONICO =  'BCO';

  OPEN  ODP_DESDE_SEBRA_COMPEN;
  FETCH ODP_DESDE_SEBRA_COMPEN INTO P_DESDE_SEBRA_COMPEN;
  CLOSE ODP_DESDE_SEBRA_COMPEN;

  OPEN  ODP_DESDE_SEBRA_COMPEN_DIF;
  FETCH ODP_DESDE_SEBRA_COMPEN_DIF INTO P_DESDE_SEBRA_COMPEN_DIF;
  CLOSE ODP_DESDE_SEBRA_COMPEN_DIF;

  OPEN  ODP_DESDE_SEBRA_NO_COMPEN;
  FETCH ODP_DESDE_SEBRA_NO_COMPEN INTO P_DESDE_SEBRA_NO_COMPEN;
  CLOSE ODP_DESDE_SEBRA_NO_COMPEN;

  OPEN  ODP_HACIA_SEBRA_COMPEN;
  FETCH ODP_HACIA_SEBRA_COMPEN INTO P_HACIA_SEBRA_COMPEN;
  CLOSE ODP_HACIA_SEBRA_COMPEN;

  OPEN  ODP_HACIA_SEBRA_NO_COMPEN;
  FETCH ODP_HACIA_SEBRA_NO_COMPEN INTO P_HACIA_SEBRA_NO_COMPEN;
  CLOSE ODP_HACIA_SEBRA_NO_COMPEN;

  BEGIN
    SELECT SCC_SALDO_EN_BANCOS-SCC_MVTOS_NO_CONCILIADOS_BANCO+SCC_SALDO_MVTOS_NO_CONCILIADOS
      INTO P_SALDO_INICIAL
    FROM SALDOS_CTA_BANCARIA_CORREDORES
    WHERE SCC_CBA_BAN_CODIGO = 0
      AND SCC_CBA_NUMERO_CUENTA = P_CUENTA
      AND SCC_FECHA = TRUNC(P_FECHA)
      AND SCC_CONFIRMADO = 'S';
  EXCEPTION
     WHEN OTHERS THEN
      P_SALDO_INICIAL := 0;
  END;
 P_SALDO_ESTIMADO := NVL(P_SALDO_INICIAL,0) +  NVL(P_HACIA_SEBRA_NO_COMPEN,0)-NVL(P_DESDE_SEBRA_NO_COMPEN,0)+ nvl(P_DESDE_SEBRA_COMPEN_DIF,0);

 P_SALDO_REAL     := NVL(P_SALDO_INICIAL,0) + NVL(P_HACIA_SEBRA_COMPEN,0) - NVL(P_DESDE_SEBRA_COMPEN,0);


 IF p_flag IS NULL THEN
 INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
 VALUES (P_FECHA
        ,'BCO' -- BANCOS
        ,P_SALDO_ESTIMADO
        ,P_SALDO_REAL
        ,P_SALDO_ESTIMADO - P_SALDO_REAL);
ELSIF p_flag ='S' THEN

INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
                                      ,GCB_CBA_BAN_CODIGO
                                      ,GCB_CBA_NUMERO_CUENTA
                                      ,GCB_COMPENSACION
                                      ,GCB_COMPENSADO
                                      ,GCB_PENDIENTE
                                      ,GCB_OPERACION)

 VALUES (P_FECHA
        ,0
        ,P_CUENTA
        ,P_SALDO_ESTIMADO
        ,P_SALDO_REAL
        ,P_SALDO_ESTIMADO - P_SALDO_REAL
        ,'BAN'
        )  ;
END IF;
END SALDOS_SEBRA;


PROCEDURE CLIENTES_SEBRA (P_FECHA DATE
                         ,P_NEGOCIO NUMBER
                         ,P_CUENTA VARCHAR2
                         ,P_FLAG    VARCHAR2 DEFAULT NULL
                         ) IS

CURSOR ODP_SEBRA IS
  SELECT SUM(ODP_MONTO_ORDEN)
    FROM ORDENES_DE_PAGO, PARAMETROS_COMPENSACIONES
    WHERE  ODP_NEG_CONSECUTIVO = P_NEGOCIO
      AND  PPC_TIPO_COMPENSACION = ODP_NPR_PRO_MNEMONICO
      AND ODP_ES_CLIENTE = 'S'
      AND ODP_TPA_MNEMONICO IN ('PSE')
      AND ODP_COT_MNEMONICO     <> 'CSEDC'
      AND ODP_FECHA_EJECUCION >=  TRUNC(P_FECHA)
      AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA)+1
      AND ODP_ESTADO = 'APR'
      AND PPC_CBA_NUMERO_CUENTA_EJECUTA =P_CUENTA
      AND PPC_PRO_MNEMONICO = 'CLI'
      AND PPC_TIPO_CLIENTE = 'C';

CURSOR RCA_MANUAL IS
   SELECT SUM(TRC_MONTO)
      FROM  RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
      WHERE  RCA_FECHA  >= TRUNC(P_FECHA)
      AND RCA_FECHA < TRUNC(P_FECHA) +1
      AND RCA_NEG_CONSECUTIVO =P_NEGOCIO
      AND RCA_CONSECUTIVO    = TRC_RCA_CONSECUTIVO
      AND RCA_SUC_CODIGO     = TRC_RCA_SUC_CODIGO
      AND RCA_NEG_CONSECUTIVO= TRC_RCA_NEG_CONSECUTIVO
      AND RCA_OCO_CONSECUTIVO IS NULL
      AND TRC_CBA_NUMERO_CUENTA = P_CUENTA
      AND RCA_ES_CLIENTE = 'S'
      AND RCA_REVERSADO ='N'
      AND ((TRC_TIPO = 'B' AND TRC_CBA_BAN_CODIGO = 0)
           OR TRC_TIPO           ='S')
      AND RCA_CONSECUTIVO  NOT IN (SELECT ORR_RCA_CONSECUTIVO
                                   FROM ORDENES_RECAUDO
                                   WHERE ORR_RCA_CONSECUTIVO =RCA_CONSECUTIVO
                                   AND ORR_RCA_NEG_CONSECUTIVO =RCA_NEG_CONSECUTIVO
                                   AND ORR_RCA_SUC_CODIGO  =RCA_SUC_CODIGO
                                   AND RCA_FECHA  >= TRUNC(P_FECHA)
                                   AND RCA_FECHA < TRUNC(P_FECHA) +1
                                   );


CURSOR RCA_COMPENSADA IS
     SELECT SUM(ORD_VALOR_PESOS_NETOS ) VALOR
     FROM  ORDENES_DIVISAS
          ,ORDENES_RECAUDO, PERSONAS,PARAMETROS_COMPENSACIONES,PRODUCTOS,NEGOCIOS_PRODUCTOS
     WHERE ORD_CONSECUTIVO = ORR_ORD_CONSECUTIVO
     AND  ORD_SUC_CODIGO = ORR_SUC_CODIGO
     AND ORD_CLI_PER_NUM_IDEN = PER_NUM_IDEN
     AND ORD_CLI_PER_TID_CODIGO = PER_TID_CODIGO
     AND PRO_MNEMONICO = NPR_PRO_MNEMONICO
     AND  ORD_FECHA_COLOCACION >=trunc(P_FECHA)
     AND  ORD_FECHA_COLOCACION < TRUNC(P_FECHA)+1
     AND  ORR_TPA_MNEMONICO  = 'PSE'
     AND  ORD_EOF_CODIGO = 'APR'
     AND NPR_NEG_CONSECUTIVO = P_NEGOCIO
     AND PRO_MNEMONICO = 'DIV'
     AND PRO_ESTADO = 'A'
     AND PPC_PRO_MNEMONICO = 'CLI'
     AND PPC_TIPO_CLIENTE = 'C'
     AND PPC_TIPO_COMPENSACION = 'DIV'
     AND PPC_CBA_NUMERO_CUENTA_EJECUTA =P_CUENTA;



CURSOR RCA_COMPENSADA1 IS
    SELECT SUM(OFO_MONTO )VALOR
    FROM ORDENES_FONDOS, ORDENES_RECAUDO, PERSONAS, PARAMETROS_COMPENSACIONES,PRODUCTOS,NEGOCIOS_PRODUCTOS
     WHERE  OFO_CONSECUTIVO = ORR_OFO_CONSECUTIVO
     AND OFO_SUC_CODIGO = ORR_OFO_SUC_CODIGO
     AND  OFO_CFO_CCC_CLI_PER_NUM_IDEN = PER_NUM_IDEN
     AND OFO_CFO_CCC_CLI_PER_TID_CODIGO =PER_TID_CODIGO
      AND PRO_MNEMONICO = NPR_PRO_MNEMONICO
     AND OFO_FECHA_CAPTURA >= TRUNC(P_FECHA)
     AND OFO_FECHA_CAPTURA < TRUNC(P_FECHA)+1
     AND ORR_TPA_MNEMONICO  = 'PSE'
     AND OFO_EOF_CODIGO IN ('CON' ,'APR')
     AND ORR_NEG_CONSECUTIVO   = NPR_NEG_CONSECUTIVO
     AND PRO_MNEMONICO                  = NPR_PRO_MNEMONICO
     AND PPC_PRO_MNEMONICO = 'CLI'
     AND PPC_TIPO_CLIENTE = 'C'
     AND NPR_NEG_CONSECUTIVO = P_NEGOCIO
     AND PPC_CBA_NUMERO_CUENTA_EJECUTA =P_CUENTA
     AND PRO_ESTADO = 'A'
     AND PRO_MNEMONICO = PPC_TIPO_COMPENSACION;

CURSOR RCA_COMPENSADA2 IS
  SELECT  SUM (LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE   + ((NVL((LIC_VALOR_COMISION *(P_OPERACIONES.F_COMISION (OCO_CCC_CLI_PER_NUM_IDEN ,OCO_CCC_CLI_PER_TID_CODIGO))  ),0))  * 1))  VALOR
	FROM ORDENES_COMPRA , PERSONAS ,PARAMETROS_COMPENSACIONES,LIQUIDACIONES_COMERCIAL

  WHERE OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
  AND OCO_CCC_CLI_PER_NUM_IDEN = PER_NUM_IDEN
  AND OCO_CCC_CLI_PER_TID_CODIGO = PER_TID_CODIGO
  AND  LIC_ELI_MNEMONICO IN ('APL', 'OPA','OPL','REV')
  AND LIC_TIPO_OPERACION = 'C'
  AND OCO_COBRAR_SEBRA =  'S'
  AND OCO_COC_CTO_MNEMONICO='ACC'
  AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
  AND LIC_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA)+1
  AND PPC_TIPO_COMPENSACION = OCO_COC_CTO_MNEMONICO
  AND OCO_EOC_MNEMONICO IN ('APL', 'PAP','CAN')
  AND OCO_COBRAR_SEBRA =  'S'
	AND PPC_PRO_MNEMONICO = 'CLI'
  AND PPC_TIPO_CLIENTE = 'C'
  AND PPC_CBA_NUMERO_CUENTA_EJECUTA =P_CUENTA
  AND PPC_ESTADO = 'A'
  ;

CURSOR RCA_COMPENSADA3 IS
  SELECT SUM (LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE   + ((NVL((LIC_VALOR_COMISION * (P_OPERACIONES.F_COMISION (OCO_CCC_CLI_PER_NUM_IDEN ,OCO_CCC_CLI_PER_TID_CODIGO)) ),0))  * 1))  VALOR
	FROM ORDENES_COMPRA , PERSONAS ,PARAMETROS_COMPENSACIONES,LIQUIDACIONES_COMERCIAL
  WHERE OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
  AND OCO_CCC_CLI_PER_NUM_IDEN = PER_NUM_IDEN
  AND OCO_CCC_CLI_PER_TID_CODIGO = PER_TID_CODIGO
  AND  LIC_ELI_MNEMONICO IN ('APL', 'OPA','OPL','REV')
  AND LIC_TIPO_OPERACION = 'C'
  AND OCO_COBRAR_SEBRA =  'S'
  AND OCO_COC_CTO_MNEMONICO='RF'
  AND PPC_TIPO_COMPENSACION = OCO_COC_CTO_MNEMONICO
  AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
  AND LIC_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA)+1
  AND OCO_EOC_MNEMONICO IN ('APL', 'PAP', 'CAN')
  AND OCO_COBRAR_SEBRA =  'S'
	AND PPC_PRO_MNEMONICO = 'CLI'
  AND PPC_TIPO_CLIENTE = 'C'
  AND PPC_CBA_NUMERO_CUENTA_EJECUTA =P_CUENTA
  AND PPC_ESTADO = 'A'

  ;

CURSOR ODP_REVERSADAS IS
 SELECT SUM(ODP_MONTO_ORDEN)
 FROM ORDENES_Y_PAGOS_ANULADOS , TRANSFERENCIAS_BANCARIAS,ORDENES_DE_PAGO
        WHERE  OPA_ODP_CONSECUTIVO = ODP_CONSECUTIVO
        AND OPA_TBC_CONSECUTIVO =TBC_CONSECUTIVO
        AND TBC_FECHA_REVERSION >= TRUNC(P_FECHA)
        AND TBC_FECHA_REVERSION < TRUNC(P_FECHA)+1
        AND OPA_SUC_CODIGO = TBC_SUC_CODIGO
        AND OPA_NEG_CONSECUTIVO =TBC_NEG_CONSECUTIVO
        AND ODP_TPA_MNEMONICO     ='PSE'
        AND ODP_COT_MNEMONICO     <> 'CSEDC'
        AND ODP_ES_CLIENTE = 'S'
        AND ODP_BAN_CODIGO = 0 -- BANCO DE LA REPUBLICA
        AND ODP_NUM_CUENTA_CONSIGNAR = P_CUENTA
        AND OPA_NEG_CONSECUTIVO =P_NEGOCIO
        AND ODP_TBC_CONSECUTIVO  IS NULL;

CURSOR ODP_ANULADAS IS
 SELECT SUM(ODP_MONTO_ORDEN)
 FROM ORDENES_DE_PAGO, PARAMETROS_COMPENSACIONES
        WHERE
        ODP_FECHA_ANULACION >= TRUNC(P_FECHA)
        AND ODP_FECHA_ANULACION < TRUNC(P_FECHA)+1
        AND  PPC_TIPO_COMPENSACION = ODP_NPR_PRO_MNEMONICO
        AND ODP_TPA_MNEMONICO     ='PSE'
        AND ODP_COT_MNEMONICO     <> 'CSEDC'
        AND ODP_ES_CLIENTE = 'S'
        AND ODP_ESTADO = 'ANU'
        AND PPC_CBA_NUMERO_CUENTA_EJECUTA  =P_CUENTA
        AND ODP_NEG_CONSECUTIVO =P_NEGOCIO
        AND PPC_PRO_MNEMONICO = 'CLI'
        AND PPC_TIPO_CLIENTE = 'C';

CURSOR RCA_REV IS
   SELECT SUM(TRC_MONTO)
      FROM  RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
      WHERE  RCA_CONSECUTIVO    = TRC_RCA_CONSECUTIVO
      AND RCA_SUC_CODIGO     = TRC_RCA_SUC_CODIGO
      AND RCA_NEG_CONSECUTIVO= TRC_RCA_NEG_CONSECUTIVO
      AND RCA_ES_CLIENTE = 'S'
      AND RCA_REVERSADO      = 'S'
     AND RCA_FECHA_REVERSION  >= TRUNC(P_FECHA)
      AND RCA_FECHA_REVERSION < TRUNC(P_FECHA)+1
      AND RCA_NEG_CONSECUTIVO =P_NEGOCIO
      AND ((TRC_TIPO = 'B' AND TRC_CBA_BAN_CODIGO = 0)
           OR TRC_TIPO           ='S');

CURSOR ODP_SEBRA_COM IS
  SELECT SUM(ODP_MONTO_ORDEN)
  FROM ORDENES_DE_PAGO
  , TRANSFERENCIAS_BANCARIAS
  WHERE  ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
    AND ODP_NEG_CONSECUTIVO = P_NEGOCIO
    AND ODP_ES_CLIENTE = 'S'
    AND ODP_TPA_MNEMONICO IN ('PSE')
    AND ODP_COT_MNEMONICO     <> 'CSEDC'
    AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA + 1)
    AND ODP_ESTADO = 'APR'
    AND TBC_CBA_NUMERO_CUENTA = P_CUENTA
    AND ODP_TBC_CONSECUTIVO  IS NOT NULL;

CURSOR RCA_SEBRA_COM1 IS
SELECT SUM(TRC_MONTO)
      FROM  RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
      WHERE  RCA_CONSECUTIVO    = TRC_RCA_CONSECUTIVO
      AND RCA_SUC_CODIGO     = TRC_RCA_SUC_CODIGO
      AND RCA_NEG_CONSECUTIVO= TRC_RCA_NEG_CONSECUTIVO
      AND RCA_NEG_CONSECUTIVO =P_NEGOCIO
      AND RCA_FECHA  >= TRUNC(P_FECHA)
      AND RCA_FECHA < TRUNC(P_FECHA)+1
      AND TRC_CBA_NUMERO_CUENTA = P_CUENTA
      AND RCA_ES_CLIENTE = 'S'
      AND RCA_REVERSADO ='N'
      AND ((TRC_TIPO = 'B' AND TRC_CBA_BAN_CODIGO = 0)
           OR TRC_TIPO           ='S');

CURSOR C_RCA_MANUALES_RF IS
SELECT SUM (LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE   + ((NVL((LIC_VALOR_COMISION * (P_OPERACIONES.F_COMISION (OCO_CCC_CLI_PER_NUM_IDEN ,OCO_CCC_CLI_PER_TID_CODIGO)) ),0))  * 1))  VALOR
   FROM ORDENES_COMPRA , PERSONAS ,PARAMETROS_COMPENSACIONES,LIQUIDACIONES_COMERCIAL
      WHERE OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
      AND OCO_CCC_CLI_PER_NUM_IDEN = PER_NUM_IDEN
      AND OCO_CCC_CLI_PER_TID_CODIGO = PER_TID_CODIGO
      AND  OCO_CCC_CLI_PER_NUM_IDEN IN (SELECT DISTINCT (RCA_CCC_CLI_PER_NUM_IDEN)
                                          FROM   RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
                                             WHERE  RCA_FECHA  >= TRUNC(P_FECHA)
                                             AND RCA_FECHA     < TRUNC(P_FECHA) +1
                                             AND RCA_NEG_CONSECUTIVO =P_NEGOCIO
                                             AND RCA_CONSECUTIVO    = TRC_RCA_CONSECUTIVO
                                             AND RCA_SUC_CODIGO     = TRC_RCA_SUC_CODIGO
                                             AND  RCA_NEG_CONSECUTIVO= TRC_RCA_NEG_CONSECUTIVO
                                             and RCA_OCO_CONSECUTIVO IS NULL
                                             AND TRC_CBA_NUMERO_CUENTA = P_CUENTA
                                             AND RCA_ES_CLIENTE = 'S'
                                             AND RCA_REVERSADO ='N'
                                             AND ((TRC_TIPO = 'B' AND TRC_CBA_BAN_CODIGO = 0)
                                                   OR TRC_TIPO           ='S')
                                              AND RCA_CONSECUTIVO  NOT IN (SELECT ORR_RCA_CONSECUTIVO
                                                                           FROM ORDENES_RECAUDO
                                                                           WHERE ORR_RCA_CONSECUTIVO =RCA_CONSECUTIVO
                                                                           AND ORR_RCA_NEG_CONSECUTIVO =RCA_NEG_CONSECUTIVO
                                                                           AND ORR_RCA_SUC_CODIGO  =RCA_SUC_CODIGO
                                                                           AND RCA_FECHA  >= TRUNC(P_FECHA)
                                                                           AND RCA_FECHA < TRUNC(P_FECHA) +1
                                                                           ))
      AND  LIC_ELI_MNEMONICO IN ('APL', 'OPA','OPL','REV')
      AND LIC_TIPO_OPERACION = 'C'
      and OCO_COBRAR_SEBRA =  'S'
      AND OCO_COC_CTO_MNEMONICO IN('RF')
      AND PPC_TIPO_COMPENSACION = OCO_COC_CTO_MNEMONICO
      and LIC_FECHA_CUMPLIMIENTO >=  TRUNC(P_FECHA)
      AND LIC_FECHA_CUMPLIMIENTO <  TRUNC(P_FECHA)+ 1
      AND OCO_EOC_MNEMONICO IN ('APL', 'PAP', 'CAN')
      AND OCO_COBRAR_SEBRA =  'S'
      AND PPC_PRO_MNEMONICO = 'CLI'
      AND PPC_TIPO_CLIENTE = 'C'
      AND PPC_CBA_NUMERO_CUENTA_EJECUTA = P_CUENTA
      AND PPC_ESTADO = 'A'
      ;

CURSOR C_RCA_MANUALES_ACC IS
SELECT SUM (LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE   + ((NVL((LIC_VALOR_COMISION * (P_OPERACIONES.F_COMISION (OCO_CCC_CLI_PER_NUM_IDEN ,OCO_CCC_CLI_PER_TID_CODIGO)) ),0))  * 1))  VALOR
   FROM ORDENES_COMPRA , PERSONAS ,PARAMETROS_COMPENSACIONES,LIQUIDACIONES_COMERCIAL
      WHERE OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
      AND OCO_CCC_CLI_PER_NUM_IDEN = PER_NUM_IDEN
      AND OCO_CCC_CLI_PER_TID_CODIGO = PER_TID_CODIGO
      AND  OCO_CCC_CLI_PER_NUM_IDEN IN (SELECT DISTINCT (RCA_CCC_CLI_PER_NUM_IDEN)
                                          FROM   RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
                                             WHERE  RCA_FECHA  >= TRUNC(P_FECHA)
                                             AND RCA_FECHA     < TRUNC(P_FECHA) +1
                                             AND RCA_NEG_CONSECUTIVO =P_NEGOCIO
                                             AND RCA_CONSECUTIVO    = TRC_RCA_CONSECUTIVO
                                             AND RCA_SUC_CODIGO     = TRC_RCA_SUC_CODIGO
                                             AND  RCA_NEG_CONSECUTIVO= TRC_RCA_NEG_CONSECUTIVO
                                             and RCA_OCO_CONSECUTIVO IS NULL
                                             AND TRC_CBA_NUMERO_CUENTA = P_CUENTA
                                             AND RCA_ES_CLIENTE = 'S'
                                             AND RCA_REVERSADO ='N'
                                             AND ((TRC_TIPO = 'B' AND TRC_CBA_BAN_CODIGO = 0)
                                                   OR TRC_TIPO           ='S')
                                              AND RCA_CONSECUTIVO  NOT IN (SELECT ORR_RCA_CONSECUTIVO
                                                                           FROM ORDENES_RECAUDO
                                                                           WHERE ORR_RCA_CONSECUTIVO =RCA_CONSECUTIVO
                                                                           AND ORR_RCA_NEG_CONSECUTIVO =RCA_NEG_CONSECUTIVO
                                                                           AND ORR_RCA_SUC_CODIGO  =RCA_SUC_CODIGO
                                                                           AND RCA_FECHA  >= TRUNC(P_FECHA)
                                                                           AND RCA_FECHA < TRUNC(P_FECHA) +1
                                                                           ))
      AND  LIC_ELI_MNEMONICO IN ('APL', 'OPA','OPL','REV')
      AND LIC_TIPO_OPERACION = 'C'
      AND OCO_COBRAR_SEBRA =  'S'
      AND OCO_COC_CTO_MNEMONICO IN('ACC')
      AND PPC_TIPO_COMPENSACION = OCO_COC_CTO_MNEMONICO
      and LIC_FECHA_CUMPLIMIENTO >=  TRUNC(P_FECHA)
      AND LIC_FECHA_CUMPLIMIENTO <  TRUNC(P_FECHA)+ 1
      AND OCO_EOC_MNEMONICO IN ('APL', 'PAP', 'CAN')
      AND OCO_COBRAR_SEBRA =  'S'
      AND PPC_PRO_MNEMONICO = 'CLI'
      AND PPC_TIPO_CLIENTE = 'C'
      AND PPC_CBA_NUMERO_CUENTA_EJECUTA = P_CUENTA
      AND PPC_ESTADO = 'A'
      ;

P_ODP_SEBRA    NUMBER;
P_DESDE_SEBRA_NO_COMPEN NUMBER;
P_HACIA_SEBRA_COMPEN    NUMBER;
P_HACIA_SEBRA_NO_COMPEN NUMBER;
P_SALDO_ESTIMADO        NUMBER;
P_SALDO_REAL            NUMBER;
P_SALDO_INICIAL         NUMBER;
P_SALDO_ESTIMADO_TOTAL   NUMBER;
P_RCA_DESDE_SEBRA_COMPEN NUMBER;
P_RCA_DESDE_SEBRA_COMPEN1 NUMBER;
P_RCA_DESDE_SEBRA_COMPEN2 NUMBER;
P_REVERSADAS NUMBER;
P_ANULADAS NUMBER;
P_RCA_REV NUMBER;
P_ODP_SEBRA_COM NUMBER;
P_RCA_SEBRA_COM NUMBER;
P_RCA_SEBRA_COM1 NUMBER;
P_RCA_DESDE_SEBRA_COMPEN3 NUMBER;
P_RCA_MANUAL NUMBER;
P_IVA_COMISION NUMBER;
P_RCA_MANUALES_RF NUMBER;
P_RCA_MANUALES_ACC NUMBER;
P_ACC  NUMBER;
P_RF  NUMBER;


BEGIN
 DELETE FROM GL_COMPENSACION_SEBRA WHERE CS_PRO_MNEMONICO =  'CLI';

  OPEN  RCA_MANUAL;
  FETCH RCA_MANUAL INTO P_RCA_MANUAL;
  CLOSE RCA_MANUAL;

  OPEN  ODP_SEBRA;
  FETCH ODP_SEBRA INTO P_ODP_SEBRA;
  CLOSE ODP_SEBRA;

  OPEN  RCA_COMPENSADA;
  FETCH RCA_COMPENSADA INTO P_RCA_DESDE_SEBRA_COMPEN;
  CLOSE RCA_COMPENSADA;

  OPEN  RCA_COMPENSADA1;
  FETCH RCA_COMPENSADA1 INTO P_RCA_DESDE_SEBRA_COMPEN1;
  CLOSE RCA_COMPENSADA1;

  OPEN  ODP_REVERSADAS;
  FETCH ODP_REVERSADAS INTO P_REVERSADAS;
  CLOSE ODP_REVERSADAS;

  OPEN  ODP_ANULADAS;
  FETCH ODP_ANULADAS INTO P_ANULADAS;
  CLOSE ODP_ANULADAS;

  OPEN  RCA_REV;
  FETCH RCA_REV INTO P_RCA_REV;
  CLOSE RCA_REV;

  OPEN  ODP_SEBRA_COM;
  FETCH ODP_SEBRA_COM INTO P_ODP_SEBRA_COM;
  CLOSE ODP_SEBRA_COM;

  OPEN  RCA_SEBRA_COM1;
  FETCH RCA_SEBRA_COM1 INTO P_RCA_SEBRA_COM1;
  CLOSE RCA_SEBRA_COM1;


  IF P_NEGOCIO = 2 THEN

  OPEN  RCA_COMPENSADA2;
  FETCH RCA_COMPENSADA2 INTO P_RCA_DESDE_SEBRA_COMPEN2;
  CLOSE RCA_COMPENSADA2;

  OPEN  RCA_COMPENSADA3;
  FETCH RCA_COMPENSADA3 INTO P_RCA_DESDE_SEBRA_COMPEN3;
  CLOSE RCA_COMPENSADA3;


  OPEN  C_RCA_MANUALES_RF;
  FETCH C_RCA_MANUALES_RF INTO P_RCA_MANUALES_RF;
  CLOSE C_RCA_MANUALES_RF;

  OPEN  C_RCA_MANUALES_ACC;
  FETCH C_RCA_MANUALES_ACC INTO P_RCA_MANUALES_ACC;
  CLOSE C_RCA_MANUALES_ACC;

 P_ACC :=NVL(P_RCA_DESDE_SEBRA_COMPEN2,0) - NVL(P_RCA_MANUALES_ACC,0);
 P_RF :=NVL(P_RCA_DESDE_SEBRA_COMPEN3,0) - NVL( P_RCA_MANUALES_RF,0);

  END IF;

  P_SALDO_ESTIMADO := (NVL(P_RCA_MANUAL,0)- NVL(P_RCA_DESDE_SEBRA_COMPEN,0)-NVL(P_RCA_DESDE_SEBRA_COMPEN1,0))
                   + NVL(P_RCA_DESDE_SEBRA_COMPEN,0)
                   + NVL(P_RCA_DESDE_SEBRA_COMPEN1,0)
                   + NVL(P_ACC,0)
                   + NVL(P_RF,0)
                   + NVL(P_RCA_MANUALES_ACC,0) + NVL(P_RCA_MANUALES_RF,0)
                   - NVL(P_ODP_SEBRA,0)  ;
  P_SALDO_REAL     := NVL(P_RCA_SEBRA_COM1,0) -  NVL(P_ODP_SEBRA_COM,0);

  P_SALDO_ESTIMADO_TOTAL :=NVL(P_SALDO_ESTIMADO,0) - NVL(P_SALDO_REAL,0);


  IF NVL(P_SALDO_ESTIMADO_TOTAL,0) > 1 THEN
     P_SALDO_ESTIMADO := (NVL(P_RCA_MANUAL,0)- NVL(P_RCA_DESDE_SEBRA_COMPEN,0)-NVL(P_RCA_DESDE_SEBRA_COMPEN1,0))
                   + NVL(P_RCA_DESDE_SEBRA_COMPEN,0)
                   + NVL(P_RCA_DESDE_SEBRA_COMPEN1,0)
                   + NVL(P_ACC,0)
                   + NVL(P_RF,0)
                   - NVL(P_ODP_SEBRA,0);
     P_SALDO_REAL     := NVL(P_RCA_SEBRA_COM1,0) -  NVL(P_ODP_SEBRA_COM,0);

     P_SALDO_ESTIMADO_TOTAL :=NVL(P_SALDO_ESTIMADO,0) - NVL(P_SALDO_REAL,0);
  END IF;



 IF p_flag IS NULL THEN
 INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
 VALUES (P_FECHA
        ,'CLI' -- CLIENTES
        ,P_SALDO_ESTIMADO
        ,P_SALDO_REAL
        ,ABS(P_SALDO_ESTIMADO) - ABS(P_SALDO_REAL)  );
ELSIF p_flag ='S' THEN

INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
                                      ,GCB_CBA_BAN_CODIGO
                                      ,GCB_CBA_NUMERO_CUENTA
                                      ,GCB_COMPENSACION
                                      ,GCB_COMPENSADO
                                      ,GCB_PENDIENTE
                                      ,GCB_OPERACION)

 VALUES (P_FECHA
        ,0
        ,P_CUENTA
        ,P_SALDO_ESTIMADO
        ,P_SALDO_REAL
        ,ABS(P_SALDO_ESTIMADO) - ABS(P_SALDO_REAL)
        ,'CLI'
        )  ;
END IF;
END CLIENTES_SEBRA;



FUNCTION FN_PORTAFOLIO (P_CCC_CLI_PER_NUM_IDEN VARCHAR2 ,
												P_CCC_CLI_PER_TID_CODIGO VARCHAR2
                        )  RETURN VARCHAR2 IS

CURSOR C_PORTAFOLIO IS
  SELECT COUNT (0) CONT
   FROM TITULOS
  WHERE TLO_CCC_CLI_PER_NUM_IDEN =P_CCC_CLI_PER_NUM_IDEN
  AND TLO_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO;
  PEB1   C_PORTAFOLIO%ROWTYPE;

BEGIN
   OPEN C_PORTAFOLIO;
   FETCH C_PORTAFOLIO INTO PEB1;
   IF PEB1.CONT = 0 THEN
   RETURN ('NO');
   ELSE
   	RETURN ('SI');
   END IF;
   CLOSE C_PORTAFOLIO;

END FN_PORTAFOLIO;

PROCEDURE CONSOLIDACION_BANCOS (P_FECHA DATE) IS

CURSOR C_CUENTAS IS
SELECT DISTINCT PPC_CBA_NUMERO_CUENTA_EJECUTA, PPC_CBA_BAN_CODIGO_EJECUTA,CBA_NEG_CONSECUTIVO
  FROM   PARAMETROS_COMPENSACIONES,CUENTAS_BANCARIAS_CORREDORES
  WHERE  PPC_PRO_MNEMONICO = 'CLI'
  AND PPC_TIPO_CLIENTE = 'C'
  AND    CBA_ESTADO = 'A'
  AND    CBA_PROCESO_CONCILIACION = 'S'
  AND CBA_BAN_CODIGO =PPC_CBA_BAN_CODIGO_EJECUTA
  AND CBA_NUMERO_CUENTA =PPC_CBA_NUMERO_CUENTA_EJECUTA;
R_CUE  C_CUENTAS%ROWTYPE;

FECHA_HOY DATE;

BEGIN
SELECT SYSDATE INTO FECHA_HOY FROM DUAL;
      OPEN C_CUENTAS;
         FETCH C_CUENTAS INTO R_CUE;
         WHILE C_CUENTAS%FOUND LOOP
         SALDOS_SEBRA (P_FECHA
                       ,R_CUE.CBA_NEG_CONSECUTIVO
                       ,R_CUE.PPC_CBA_NUMERO_CUENTA_EJECUTA
                       ,'S');
         CLIENTES_SEBRA (P_FECHA
                         ,R_CUE.CBA_NEG_CONSECUTIVO
                         ,R_CUE.PPC_CBA_NUMERO_CUENTA_EJECUTA
                         ,'S')  ;
         REPOS (P_FECHA
                ,R_CUE.CBA_NEG_CONSECUTIVO
                ,R_CUE.PPC_CBA_NUMERO_CUENTA_EJECUTA
                ,'S')  ;



         FETCH C_CUENTAS INTO R_CUE;
         END LOOP;
         CLOSE C_CUENTAS;

IF TRUNC(P_FECHA) = TRUNC(FECHA_HOY) THEN
COMPENSACION_SEBRA(P_FECHA,'S');
ELSE
COMPENSACION_SEBRA_HCO(P_FECHA,R_CUE.CBA_NEG_CONSECUTIVO,'S');
END IF;
END CONSOLIDACION_BANCOS;

PROCEDURE REPOS (P_FECHA DATE
                ,P_NEGOCIO NUMBER
                ,P_CUENTA VARCHAR2
                ,P_FLAG    VARCHAR2 DEFAULT NULL
                ) IS
   --valor operaciones REPOS
   CURSOR C_OPER_CLI_REPO IS
      SELECT SUM(CRB_VALOR_CONSTITUIR)
      FROM   CONSTITUCIONES_REPOS
      WHERE  CRB_FECHA_CONSTITUIR >=TRUNC(P_FECHA)
        AND  CRB_FECHA_CONSTITUIR  < TRUNC(P_FECHA) + 1
        AND  CRB_NEG_CONSECUTIVO = P_NEGOCIO
        AND  CRB_ESTADO_FRONT <> 'ANU';

   -- valor compensado REPOS
   CURSOR C_COMP_CLI_REPO IS
      SELECT SUM(TRC_MONTO) MONTO
      FROM  RECIBOS_DE_CAJA,
            TRANSFERENCIAS_CAJA
      WHERE RCA_FECHA  >= TRUNC(P_FECHA)
        AND RCA_FECHA < TRUNC(P_FECHA) +1
        AND RCA_NEG_CONSECUTIVO =P_NEGOCIO
        AND RCA_COT_MNEMONICO = 'RCREP'
        AND RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
        AND RCA_SUC_CODIGO  = TRC_RCA_SUC_CODIGO
        AND RCA_NEG_CONSECUTIVO= TRC_RCA_NEG_CONSECUTIVO
        AND TRC_CBA_NUMERO_CUENTA = P_CUENTA
        AND RCA_ES_CLIENTE = 'N'
        AND RCA_REVERSADO ='N'
        AND ((TRC_TIPO = 'B' AND TRC_CBA_BAN_CODIGO = 0)
              OR TRC_TIPO ='S');

-------------------------REPOS POR CUMPLIR--------------

   --VALOR OPERACIONES REPOS_C
   CURSOR C_OPER_CLI_CUMPLIR IS
      SELECT -SUM(CRB_VALOR_CUMPLIMIENTO)
      FROM CONSTITUCIONES_REPOS
      WHERE CRB_FECHA_CUMPLIMIENTO >=TRUNC(P_FECHA)
        AND CRB_FECHA_CUMPLIMIENTO   < TRUNC(P_FECHA) + 1
        AND CRB_NEG_CONSECUTIVO = P_NEGOCIO
        AND CRB_ESTADO_FRONT <> 'ANU';

   --VALOR COMPENSADO REPOS_C
   CURSOR C_COMP_CLI_CUMPLIR IS
      SELECT -SUM(ODP_MONTO_ORDEN)
      FROM ORDENES_DE_PAGO,
           TRANSFERENCIAS_BANCARIAS
      WHERE  ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
        AND ODP_NEG_CONSECUTIVO = P_NEGOCIO
        AND ODP_ES_CLIENTE = 'N'
        AND ODP_TPA_MNEMONICO IN ('PSE')
        AND ODP_COT_MNEMONICO  =  'CRBR'
        AND ODP_CRB_COD_REPO IS NOT NULL
        AND ODP_FECHA_EJECUCION >= TRUNC(P_FECHA)
        AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA + 1)
        AND ODP_ESTADO = 'APR'
        AND TBC_CBA_NUMERO_CUENTA = P_CUENTA
        AND ODP_TBC_CONSECUTIVO  IS NOT NULL;

   P_C_COMP_FONDOS_REPO NUMBER;
   P_C_OPER_FONDOS_REPO NUMBER;
   P_C_OPER_CLI_REPO NUMBER;
   P_C_COMP_CLI_REPO NUMBER;
   P_C_OPER_FONDOS_CUMPLIR NUMBER;
   P_C_COMP_FONDOS_CUMPLIR NUMBER;
   P_C_OPER_CLI_CUMPLIR NUMBER;
   P_C_COMP_CLI_CUMPLIR NUMBER;
   P_SALDO_ESTIMADO_REPO  NUMBER;
   P_SALDO_ESTIMADO_CUMPLIR  NUMBER;
   P_SALDO_REAL_REPO         NUMBER;
   P_SALDO_REAL_CUMPLIR      number;
   P_C_VALOR_CLI_CUMPLIR     NUMBER;

BEGIN
   DELETE FROM GL_COMPENSACION_SEBRA WHERE CS_PRO_MNEMONICO =  'REPO';
   DELETE FROM GL_COMPENSACION_SEBRA WHERE CS_PRO_MNEMONICO =  'REPO_C';

   --REPOS
      --valor operaciones REPOS
      OPEN  C_OPER_CLI_REPO;
      FETCH C_OPER_CLI_REPO INTO P_C_OPER_CLI_REPO;
      CLOSE C_OPER_CLI_REPO;

      -- valor compensado REPOS
      OPEN  C_COMP_CLI_REPO;
      FETCH C_COMP_CLI_REPO INTO P_C_COMP_CLI_REPO;
      CLOSE C_COMP_CLI_REPO;

      P_SALDO_ESTIMADO_REPO    :=  NVL(P_C_OPER_CLI_REPO,0);
      P_SALDO_REAL_REPO       :=   NVL(P_C_COMP_CLI_REPO,0);

      IF p_flag IS NULL THEN
         INSERT INTO GL_COMPENSACION_SEBRA
                ( CS_FECHA,
                  CS_PRO_MNEMONICO,
                  CS_COMPENSACION,
                  CS_COMPENSADO,
                  CS_PENDIENTE)
         VALUES ( P_FECHA,
                  'REPO',
                  P_SALDO_ESTIMADO_REPO,
                  P_SALDO_REAL_REPO,
                  P_SALDO_ESTIMADO_REPO - P_SALDO_REAL_REPO);
      ELSIF p_flag ='S' THEN
         INSERT INTO GL_CONSOLIDACION_BANCOS
                ( GCB_FECHA,
                  GCB_CBA_BAN_CODIGO,
                  GCB_CBA_NUMERO_CUENTA,
                  GCB_COMPENSACION,
                  GCB_COMPENSADO,
                  GCB_PENDIENTE,
                  GCB_OPERACION)
         VALUES (P_FECHA,
                  0,
                  P_CUENTA,
                  P_SALDO_ESTIMADO_REPO,
                  P_SALDO_REAL_REPO,
                  P_SALDO_ESTIMADO_REPO - P_SALDO_REAL_REPO,
                  'REPO'
                  );
      END IF;

-------------------------REPOS POR CUMPLIR--------------
     --VALOR OPERACIONES REPOS_C
      OPEN  C_OPER_CLI_CUMPLIR;
      FETCH C_OPER_CLI_CUMPLIR INTO P_C_OPER_CLI_CUMPLIR;
      CLOSE C_OPER_CLI_CUMPLIR;

      --VALOR COMPENSADO REPOS_C
      OPEN  C_COMP_CLI_CUMPLIR;
      FETCH C_COMP_CLI_CUMPLIR INTO P_C_COMP_CLI_CUMPLIR;
      CLOSE C_COMP_CLI_CUMPLIR;

      P_SALDO_ESTIMADO_CUMPLIR :=  NVL(P_C_OPER_CLI_CUMPLIR,0);
      P_SALDO_REAL_CUMPLIR    :=   NVL(P_C_COMP_CLI_CUMPLIR,0);

      IF p_flag IS NULL THEN
         INSERT INTO GL_COMPENSACION_SEBRA
             (CS_FECHA,
              CS_PRO_MNEMONICO,
              CS_COMPENSACION,
              CS_COMPENSADO,
              CS_PENDIENTE)
         VALUES (P_FECHA,
              'REPO_C',
              P_SALDO_ESTIMADO_CUMPLIR,
              P_SALDO_REAL_CUMPLIR,
              P_SALDO_ESTIMADO_CUMPLIR - P_SALDO_REAL_CUMPLIR);

      ELSIF p_flag ='S' THEN
         INSERT INTO GL_CONSOLIDACION_BANCOS
             (GCB_FECHA,
              GCB_CBA_BAN_CODIGO,
              GCB_CBA_NUMERO_CUENTA,
              GCB_COMPENSACION,
              GCB_COMPENSADO,
              GCB_PENDIENTE,
              GCB_OPERACION)
         VALUES (P_FECHA,
              0,
              P_CUENTA,
              P_SALDO_ESTIMADO_CUMPLIR,
              P_SALDO_REAL_CUMPLIR,
              P_SALDO_ESTIMADO_CUMPLIR - P_SALDO_REAL_CUMPLIR,
              'REPO_C'
              );
      END IF;
END REPOS;


FUNCTION F_COMISION (P_CCC_CLI_PER_NUM_IDEN VARCHAR2 ,
                      P_CCC_CLI_PER_TID_CODIGO VARCHAR2
                    )

RETURN NUMBER IS

CURSOR C_EXCENTO_IVA(P_NUM_IDEN   VARCHAR2
                    ,P_TID_CODIGO VARCHAR2) IS
   SELECT CLI_EXCENTO_IVA
      FROM  CLIENTES
      WHERE  CLI_PER_NUM_IDEN = P_NUM_IDEN
      AND    CLI_PER_TID_CODIGO = P_TID_CODIGO;
   CLI1   C_EXCENTO_IVA%ROWTYPE;


CURSOR C_IVC IS
   SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = 'IVC';

P_IVA_COMISION NUMBER;
EXCENTO_IVA VARCHAR(2);

BEGIN

 OPEN C_EXCENTO_IVA (P_CCC_CLI_PER_NUM_IDEN,P_CCC_CLI_PER_TID_CODIGO);
	FETCH C_EXCENTO_IVA INTO EXCENTO_IVA;
	CLOSE C_EXCENTO_IVA;

	   IF EXCENTO_IVA= 'S' THEN
         P_IVA_COMISION := 0;
     ELSE
		        OPEN C_IVC;
		           FETCH C_IVC INTO P_IVA_COMISION;
		        CLOSE C_IVC;
		           P_IVA_COMISION := NVL(P_IVA_COMISION,0);

      END IF;
 RETURN P_IVA_COMISION;
END;

PROCEDURE COMPENSACION_DIVISAS (P_FECHA DATE, P_TIPO VARCHAR2) IS

--VLR OPERACIONES SPOT
  --Compras - Spot - CCD
  CURSOR COMPRAS_SPOT_CCD (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C'  ;

  --Ventas - Spot - CCD
  CURSOR VENTAS_SPOT_CCD (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C';

  --Compras - Spot - IMC
  CURSOR COMPRAS_SPOT_IMC (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL;

  --Ventas - Spot - IMC
  CURSOR VENTAS_SPOT_IMC (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL;

--VLR COMPENSADO SPOT -- ORDENES DIVISAS YA EJECUTADAS...
  --CAMARA ODP
  CURSOR COMPENSACION_CAMARA_COMPRAS (P_FECHA DATE) IS
    SELECT ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO
    WHERE ODP_PER_NUM_IDEN = '900118080' --CAMARA DE COMPEN. DE DIVISAS DE COLOMBIA
      AND ODP_PER_TID_CODIGO = 'NIT'
      AND ODP_TPA_MNEMONICO = 'PSE'
      AND ODP_COT_MNEMONICO = 'GCDIV'
      AND ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_ESTADO <> 'ANU'
      AND ODP_FECHA >= TRUNC(P_FECHA)
      AND ODP_FECHA <= TRUNC(P_FECHA+1);

  --CAMARA ORR
  CURSOR COMPENSACION_CAMARA_VENTAS (P_FECHA DATE) IS
    SELECT ORR_MONTO
    FROM ORDENES_RECAUDO
    WHERE ORR_PER_NUM_IDEN = '900118080' --CAMARA DE COMPEN. DE DIVISAS DE COLOMBIA
      AND ORR_PER_TID_CODIGO = 'NIT'
      AND ORR_TPA_MNEMONICO = 'PSE'
      AND ORR_COT_MNEMONICO = 'RCDIV'
      AND ORR_NEG_CONSECUTIVO = 8
      AND ORR_SUC_CODIGO = 1
      AND ORR_ESTADO <> 'ANU'
      AND ORR_FECHA >= TRUNC(P_FECHA)
      AND ORR_FECHA <= TRUNC(P_FECHA+1);

  --Compras - Spot - CCD
  CURSOR COMPRAS_SPOT_CCD_COMPEN_ODP (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C'
      AND ODC_ORDEN_COMPENSADA = 'S';

  CURSOR VENTAS_SPOT_CCD_COMPEN_ORR (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C'
      AND ODC_ORDEN_COMPENSADA = 'S';

  --Compras - Spot - IMC
  CURSOR COMPRAS_SPOT_IMC_COMPEN_ODP (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL
      AND ODC_ORDEN_COMPENSADA = 'S';

  CURSOR VENTAS_SPOT_IMC_COMPEN_ORR (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND TRUNC(ODC_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL
      AND ODC_ORDEN_COMPENSADA = 'S';



  V_SALDO_ESTIMADO NUMBER;
  V_SALDO_REAL     NUMBER;
  V_SALDO_INICIAL  NUMBER;
  V_SALDO_ESTIMADO_N NUMBER;
  V_SALDO_REAL_N     NUMBER;
  V_SALDO_INICIAL_N  NUMBER;
  V_COMPRAS_SPOT_CCD NUMBER;
  V_COMPRAS_SPOT_CCD_IVADES NUMBER;
  V_COMPRAS_SPOT_CCD_IVAVEN NUMBER;
  V_VENTAS_SPOT_CCD NUMBER;
  V_VENTAS_SPOT_CCD_IVADES NUMBER;
  V_VENTAS_SPOT_CCD_IVAVEN NUMBER;
  V_COMPRAS_SPOT_CCD_COMPEN_ODP NUMBER;
  V_VENTAS_SPOT_CCD_COMPEN_ORR NUMBER;
  V_COMPRAS_SPOT_CCD_COMPEN_IDE NUMBER;
  V_COMPRAS_SPOT_CCD_COMPEN_IVE NUMBER;
  V_VENTAS_SPOT_CCD_COMPEN_IDE NUMBER;
  V_VENTAS_SPOT_CCD_COMPEN_IVE NUMBER;
  V_COMPRAS_SPOT_IMC NUMBER;
  V_COMPRAS_SPOT_IMC_IVADES NUMBER;
  V_COMPRAS_SPOT_IMC_IVAVEN NUMBER;
  V_VENTAS_SPOT_IMC NUMBER;
  V_VENTAS_SPOT_IMC_IVADES NUMBER;
  V_VENTAS_SPOT_IMC_IVAVEN NUMBER;
  V_COMPRAS_SPOT_IMC_COMPEN_ODP NUMBER;
  V_VENTAS_SPOT_IMC_COMPEN_ORR NUMBER;
  V_COMPRAS_SPOT_IMC_COMPEN_IDE NUMBER;
  V_COMPRAS_SPOT_IMC_COMPEN_IVE NUMBER;
  V_VENTAS_SPOT_IMC_COMPEN_IDE NUMBER;
  V_VENTAS_SPOT_IMC_COMPEN_IVE NUMBER;
  V_COMPRAS_NEXTDAY_CCD NUMBER;
  V_VENTAS_NEXTDAY_CCD NUMBER;
  V_COMPRAS_NEXTDAY_CCD_COMPEN NUMBER;
  V_VENTAS_NEXTDAY_CCD_COMPEN NUMBER;
  V_COMPRAS_NEXTDAY_IMC NUMBER;
  V_VENTAS_NEXTDAY_IMC NUMBER;
  V_COMPRAS_NEXTDAY_IMC_COMPEN NUMBER;
  V_VENTAS_NEXTDAY_IMC_COMPEN NUMBER;

BEGIN
--VLR OPERACIONES
  --CCD
  IF P_TIPO = 'C' THEN

    OPEN COMPRAS_SPOT_CCD(P_FECHA);
    FETCH COMPRAS_SPOT_CCD INTO V_COMPRAS_SPOT_CCD, V_COMPRAS_SPOT_CCD_IVADES, V_COMPRAS_SPOT_CCD_IVAVEN;
    CLOSE COMPRAS_SPOT_CCD;

    OPEN VENTAS_SPOT_CCD(P_FECHA);
    FETCH VENTAS_SPOT_CCD INTO V_VENTAS_SPOT_CCD, V_VENTAS_SPOT_CCD_IVADES, V_VENTAS_SPOT_CCD_IVAVEN;
    CLOSE VENTAS_SPOT_CCD;

    OPEN COMPENSACION_CAMARA_COMPRAS(P_FECHA);
    FETCH COMPENSACION_CAMARA_COMPRAS INTO V_COMPRAS_SPOT_CCD_COMPEN_ODP;
    CLOSE COMPENSACION_CAMARA_COMPRAS;

    OPEN COMPENSACION_CAMARA_VENTAS(P_FECHA);
    FETCH COMPENSACION_CAMARA_VENTAS INTO V_VENTAS_SPOT_CCD_COMPEN_ORR;
    CLOSE COMPENSACION_CAMARA_VENTAS;

    OPEN COMPRAS_SPOT_CCD_COMPEN_ODP(P_FECHA);
    FETCH COMPRAS_SPOT_CCD_COMPEN_ODP INTO V_COMPRAS_SPOT_CCD_COMPEN_IDE,V_COMPRAS_SPOT_CCD_COMPEN_IVE;
    CLOSE COMPRAS_SPOT_CCD_COMPEN_ODP;

    OPEN VENTAS_SPOT_CCD_COMPEN_ORR(P_FECHA);
    FETCH VENTAS_SPOT_CCD_COMPEN_ORR INTO V_VENTAS_SPOT_CCD_COMPEN_IDE,V_VENTAS_SPOT_CCD_COMPEN_IVE;
    CLOSE VENTAS_SPOT_CCD_COMPEN_ORR;

    V_SALDO_ESTIMADO :=  -NVL(V_COMPRAS_SPOT_CCD,0) + NVL(V_VENTAS_SPOT_CCD,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_CCD_COMPEN_ODP,0)+NVL(V_VENTAS_SPOT_CCD_COMPEN_ORR,0);

    --SPOT
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_CS' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

    --SPOT IVA DESC
    V_SALDO_ESTIMADO := 0;
    V_SALDO_REAL     := 0;
    V_SALDO_ESTIMADO := -NVL(V_COMPRAS_SPOT_CCD_IVADES,0) + NVL(V_VENTAS_SPOT_CCD_IVADES,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_CCD_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IDE,0);
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_CS_ID' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

    --SPOT IVA VENTA
    V_SALDO_ESTIMADO := 0;
    V_SALDO_REAL     := 0;
    V_SALDO_ESTIMADO := -NVL(V_COMPRAS_SPOT_CCD_IVAVEN,0) + NVL(V_VENTAS_SPOT_CCD_IVAVEN,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_CCD_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IVE,0);
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_CS_IV' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

  --IMC
  ELSIF P_TIPO = 'I' THEN

    OPEN COMPRAS_SPOT_IMC(P_FECHA);
    FETCH COMPRAS_SPOT_IMC INTO V_COMPRAS_SPOT_IMC, V_COMPRAS_SPOT_IMC_IVADES, V_COMPRAS_SPOT_IMC_IVAVEN;
    CLOSE COMPRAS_SPOT_IMC;

    OPEN VENTAS_SPOT_IMC(P_FECHA);
    FETCH VENTAS_SPOT_IMC INTO V_VENTAS_SPOT_IMC, V_VENTAS_SPOT_IMC_IVADES, V_VENTAS_SPOT_IMC_IVAVEN;
    CLOSE VENTAS_SPOT_IMC;

    OPEN COMPRAS_SPOT_IMC_COMPEN_ODP(P_FECHA);
    FETCH COMPRAS_SPOT_IMC_COMPEN_ODP INTO V_COMPRAS_SPOT_IMC_COMPEN_ODP,V_COMPRAS_SPOT_IMC_COMPEN_IDE,V_COMPRAS_SPOT_IMC_COMPEN_IVE;
    CLOSE COMPRAS_SPOT_IMC_COMPEN_ODP;

    OPEN VENTAS_SPOT_IMC_COMPEN_ORR(P_FECHA);
    FETCH VENTAS_SPOT_IMC_COMPEN_ORR INTO V_VENTAS_SPOT_IMC_COMPEN_ORR,V_VENTAS_SPOT_IMC_COMPEN_IDE,V_VENTAS_SPOT_IMC_COMPEN_IVE;
    CLOSE VENTAS_SPOT_IMC_COMPEN_ORR;

    V_SALDO_ESTIMADO :=  -NVL(V_COMPRAS_SPOT_IMC,0) + NVL(V_VENTAS_SPOT_IMC,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_IMC_COMPEN_ODP,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_ORR,0);

    --SPOT
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_IS' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

    --SPOT IVA DESC
    V_SALDO_ESTIMADO := 0;
    V_SALDO_REAL     := 0;
    V_SALDO_ESTIMADO := -NVL(V_COMPRAS_SPOT_IMC_IVADES,0) + NVL(V_VENTAS_SPOT_IMC_IVADES,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_IMC_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IDE,0);
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_IS_ID' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

    --SPOT IVA VENTA
    V_SALDO_ESTIMADO := 0;
    V_SALDO_REAL     := 0;
    V_SALDO_ESTIMADO := -NVL(V_COMPRAS_SPOT_IMC_IVAVEN,0) + NVL(V_VENTAS_SPOT_IMC_IVAVEN,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_IMC_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IVE,0);
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_IS_IV' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

  END IF;
END COMPENSACION_DIVISAS;

PROCEDURE COMPENSACION_DIVISAS_TES (P_FECHA DATE, P_TIPO VARCHAR2) IS

--VLR OPERACIONES SPOT
  --Compras - Spot - CCD
  CURSOR COMPRAS_SPOT_CCD (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND ODC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
      AND ODC_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C'  ;

  --Ventas - Spot - CCD
  CURSOR VENTAS_SPOT_CCD (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND ODC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
      AND ODC_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C';

  --Compras - Spot - IMC
  CURSOR COMPRAS_SPOT_IMC (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND ODC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA)
      AND ODC_FECHA_CUMPLIMIENTO < TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL;

  --Ventas - Spot - IMC
  CURSOR VENTAS_SPOT_IMC (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS
    WHERE ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND ODC_FECHA_CUMPLIMIENTO = TRUNC(P_FECHA)
      AND ODC_FECHA_CUMPLIMIENTO = TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL;

--VLR COMPENSADO SPOT -- ORDENES DIVISAS YA EJECUTADAS...
  --CAMARA ODP
  CURSOR COMPENSACION_CAMARA_COMPRAS (P_FECHA DATE) IS
    SELECT ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS
    WHERE ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
      AND ODP_SUC_CODIGO = TBC_SUC_CODIGO
      AND ODP_NEG_CONSECUTIVO = TBC_NEG_CONSECUTIVO
      AND ODP_PER_NUM_IDEN = '900118080' --CAMARA DE COMPEN. DE DIVISAS DE COLOMBIA
      AND ODP_PER_TID_CODIGO = 'NIT'
      AND ODP_TPA_MNEMONICO = 'PSE'
      AND ODP_COT_MNEMONICO = 'GCDIV'
      AND ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_ESTADO <> 'ANU'
      AND ODP_TBC_CONSECUTIVO IS NOT NULL
      AND TBC_FECHA >= TRUNC(P_FECHA)
      AND TBC_FECHA <= TRUNC(P_FECHA+1);

  --CAMARA ORR
  CURSOR COMPENSACION_CAMARA_VENTAS (P_FECHA DATE) IS
    SELECT ORR_MONTO
    FROM ORDENES_RECAUDO, RECIBOS_DE_CAJA
    WHERE ORR_RCA_CONSECUTIVO = RCA_CONSECUTIVO
      AND ORR_RCA_SUC_CODIGO = RCA_SUC_CODIGO
      AND ORR_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
      AND ORR_PER_NUM_IDEN = '900118080' --CAMARA DE COMPEN. DE DIVISAS DE COLOMBIA
      AND ORR_PER_TID_CODIGO = 'NIT'
      AND ORR_TPA_MNEMONICO = 'PSE'
      AND ORR_COT_MNEMONICO = 'RCDIV'
      AND ORR_NEG_CONSECUTIVO = 8
      AND ORR_SUC_CODIGO = 1
      AND ORR_ESTADO <> 'ANU'
      AND ORR_RCA_CONSECUTIVO IS NOT NULL
      AND RCA_FECHA >= TRUNC(P_FECHA)
      AND RCA_FECHA <= TRUNC(P_FECHA+1);

  --Compras - Spot - CCD
  CURSOR COMPRAS_SPOT_CCD_COMPEN_ODP (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS, ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS
    WHERE ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
      AND ODP_SUC_CODIGO = TBC_SUC_CODIGO
      AND ODP_NEG_CONSECUTIVO = TBC_NEG_CONSECUTIVO
      AND ODC_ODP_CONSECUTIVO = ODP_CONSECUTIVO
      AND ODC_ODP_SUC_CODIGO = ODP_SUC_CODIGO
      AND ODC_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
      AND ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND TBC_FECHA >= TRUNC(P_FECHA)
      AND TBC_FECHA < TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C'
      AND ODC_ORDEN_COMPENSADA = 'S';

  CURSOR VENTAS_SPOT_CCD_COMPEN_ORR (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS, ORDENES_RECAUDO, RECIBOS_DE_CAJA
    WHERE ORR_RCA_CONSECUTIVO = RCA_CONSECUTIVO
      AND ORR_RCA_SUC_CODIGO = RCA_SUC_CODIGO
      AND ORR_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
      AND ODC_ORR_CONSECUTIVO = ORR_CONSECUTIVO
      AND ODC_ORR_SUC_CODIGO = ORR_SUC_CODIGO
      AND ODC_ORR_NEG_CONSECUTIVO = ORR_NEG_CONSECUTIVO
      AND ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND RCA_FECHA >= TRUNC(P_FECHA)
      AND RCA_FECHA <= TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO = 'C'
      AND ODC_ORDEN_COMPENSADA = 'S';

  --Compras - Spot - IMC
  CURSOR COMPRAS_SPOT_IMC_COMPEN_ODP (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS, ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS
    WHERE ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
      AND ODP_SUC_CODIGO = TBC_SUC_CODIGO
      AND ODP_NEG_CONSECUTIVO = TBC_NEG_CONSECUTIVO
      AND ODC_ODP_CONSECUTIVO = ODP_CONSECUTIVO
      AND ODC_ODP_SUC_CODIGO = ODP_SUC_CODIGO
      AND ODC_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
      AND ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'C'
      AND TBC_FECHA >= TRUNC(P_FECHA)
      AND TBC_FECHA < TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL
      AND ODC_ORDEN_COMPENSADA = 'S';

  CURSOR VENTAS_SPOT_IMC_COMPEN_ORR (P_FECHA DATE) IS
    SELECT SUM(ODC_VALOR_DOLARES*ODC_TASA_CAMBIO) VALOR_PESOS_NETOS, SUM(ODC_VALOR_IVA_DESCONTABLE)VALOR_IVA_DESCONTABLE, SUM(ODC_VALOR_IVA_VENTA) VALOR_IVA_VENTA
    FROM ORDENES_DIVISAS_PRECARGADAS, ORDENES_DIVISAS, ORDENES_RECAUDO, RECIBOS_DE_CAJA
    WHERE ORR_RCA_CONSECUTIVO = RCA_CONSECUTIVO
      AND ORR_RCA_SUC_CODIGO = RCA_SUC_CODIGO
      AND ORR_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
      AND ODC_ORR_CONSECUTIVO = ORR_CONSECUTIVO
      AND ODC_ORR_SUC_CODIGO = ORR_SUC_CODIGO
      AND ODC_ORR_NEG_CONSECUTIVO = ORR_NEG_CONSECUTIVO
      AND ODC_ORR_CONSECUTIVO = ORR_CONSECUTIVO
      AND ODC_ORR_SUC_CODIGO = ORR_SUC_CODIGO
      AND ODC_ORR_NEG_CONSECUTIVO = ORR_NEG_CONSECUTIVO
      AND ODC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
      AND ODC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
      AND ODC_TIPO_ORDEN = 'V'
      AND RCA_FECHA >= TRUNC(P_FECHA)
      AND RCA_FECHA <= TRUNC(P_FECHA+1)
      AND ODC_ESTADO <> 'ANU'
      AND ODC_BANDERA_METODO IS NULL
      AND ODC_ORDEN_COMPENSADA = 'S';

  V_SALDO_ESTIMADO NUMBER;
  V_SALDO_REAL     NUMBER;
  V_SALDO_INICIAL  NUMBER;
  V_SALDO_ESTIMADO_N NUMBER;
  V_SALDO_REAL_N     NUMBER;
  V_SALDO_INICIAL_N  NUMBER;
  V_COMPRAS_SPOT_CCD NUMBER;
  V_COMPRAS_SPOT_CCD_IVADES NUMBER;
  V_COMPRAS_SPOT_CCD_IVAVEN NUMBER;
  V_VENTAS_SPOT_CCD NUMBER;
  V_VENTAS_SPOT_CCD_IVADES NUMBER;
  V_VENTAS_SPOT_CCD_IVAVEN NUMBER;
  V_COMPRAS_SPOT_CCD_COMPEN_ODP NUMBER;
  V_VENTAS_SPOT_CCD_COMPEN_ORR NUMBER;
  V_COMPRAS_SPOT_CCD_COMPEN_IDE NUMBER;
  V_COMPRAS_SPOT_CCD_COMPEN_IVE NUMBER;
  V_VENTAS_SPOT_CCD_COMPEN_IDE NUMBER;
  V_VENTAS_SPOT_CCD_COMPEN_IVE NUMBER;
  V_COMPRAS_SPOT_IMC NUMBER;
  V_COMPRAS_SPOT_IMC_IVADES NUMBER;
  V_COMPRAS_SPOT_IMC_IVAVEN NUMBER;
  V_VENTAS_SPOT_IMC NUMBER;
  V_VENTAS_SPOT_IMC_IVADES NUMBER;
  V_VENTAS_SPOT_IMC_IVAVEN NUMBER;
  V_COMPRAS_SPOT_IMC_COMPEN_ODP NUMBER;
  V_VENTAS_SPOT_IMC_COMPEN_ORR NUMBER;
  V_COMPRAS_SPOT_IMC_COMPEN_IDE NUMBER;
  V_COMPRAS_SPOT_IMC_COMPEN_IVE NUMBER;
  V_VENTAS_SPOT_IMC_COMPEN_IDE NUMBER;
  V_VENTAS_SPOT_IMC_COMPEN_IVE NUMBER;

BEGIN
--VLR OPERACIONES
  --CCD
  IF P_TIPO = 'C' THEN

    OPEN COMPRAS_SPOT_CCD(P_FECHA);
    FETCH COMPRAS_SPOT_CCD INTO V_COMPRAS_SPOT_CCD, V_COMPRAS_SPOT_CCD_IVADES, V_COMPRAS_SPOT_CCD_IVAVEN;
    CLOSE COMPRAS_SPOT_CCD;

    OPEN VENTAS_SPOT_CCD(P_FECHA);
    FETCH VENTAS_SPOT_CCD INTO V_VENTAS_SPOT_CCD, V_VENTAS_SPOT_CCD_IVADES, V_VENTAS_SPOT_CCD_IVAVEN;
    CLOSE VENTAS_SPOT_CCD;

    OPEN COMPENSACION_CAMARA_COMPRAS(P_FECHA);
    FETCH COMPENSACION_CAMARA_COMPRAS INTO V_COMPRAS_SPOT_CCD_COMPEN_ODP;
    CLOSE COMPENSACION_CAMARA_COMPRAS;

    OPEN COMPENSACION_CAMARA_VENTAS(P_FECHA);
    FETCH COMPENSACION_CAMARA_VENTAS INTO V_VENTAS_SPOT_CCD_COMPEN_ORR;
    CLOSE COMPENSACION_CAMARA_VENTAS;

    OPEN COMPRAS_SPOT_CCD_COMPEN_ODP(P_FECHA);
    FETCH COMPRAS_SPOT_CCD_COMPEN_ODP INTO V_COMPRAS_SPOT_CCD_COMPEN_IDE,V_COMPRAS_SPOT_CCD_COMPEN_IVE;
    CLOSE COMPRAS_SPOT_CCD_COMPEN_ODP;

    OPEN VENTAS_SPOT_CCD_COMPEN_ORR(P_FECHA);
    FETCH VENTAS_SPOT_CCD_COMPEN_ORR INTO V_VENTAS_SPOT_CCD_COMPEN_IDE,V_VENTAS_SPOT_CCD_COMPEN_IVE;
    CLOSE VENTAS_SPOT_CCD_COMPEN_ORR;

    V_SALDO_ESTIMADO :=  -NVL(V_COMPRAS_SPOT_CCD,0) + NVL(V_VENTAS_SPOT_CCD,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_CCD_COMPEN_ODP,0)+NVL(V_VENTAS_SPOT_CCD_COMPEN_ORR,0);
    --V_SALDO_REAL     := NVL(V_COMPRAS_SPOT_CCD_COMPEN_ODP,0)-NVL(0,0);

    --SPOT
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_CS' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

    --SPOT IVA DESC
    V_SALDO_ESTIMADO := 0;
    V_SALDO_REAL     := 0;
    V_SALDO_ESTIMADO := -NVL(V_COMPRAS_SPOT_CCD_IVADES,0) + NVL(V_VENTAS_SPOT_CCD_IVADES,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_CCD_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IDE,0);
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_CS_ID' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

    --SPOT IVA VENTA
    V_SALDO_ESTIMADO := 0;
    V_SALDO_REAL     := 0;
    V_SALDO_ESTIMADO := -NVL(V_COMPRAS_SPOT_CCD_IVAVEN,0) + NVL(V_VENTAS_SPOT_CCD_IVAVEN,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_CCD_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IVE,0);
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_CS_IV' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);

  --IMC
  ELSIF P_TIPO = 'I' THEN

    OPEN COMPRAS_SPOT_IMC(P_FECHA);
    FETCH COMPRAS_SPOT_IMC INTO V_COMPRAS_SPOT_IMC, V_COMPRAS_SPOT_IMC_IVADES, V_COMPRAS_SPOT_IMC_IVAVEN;
    CLOSE COMPRAS_SPOT_IMC;

    OPEN VENTAS_SPOT_IMC(P_FECHA);
    FETCH VENTAS_SPOT_IMC INTO V_VENTAS_SPOT_IMC, V_VENTAS_SPOT_IMC_IVADES, V_VENTAS_SPOT_IMC_IVAVEN;
    CLOSE VENTAS_SPOT_IMC;

    OPEN COMPRAS_SPOT_IMC_COMPEN_ODP(P_FECHA);
    FETCH COMPRAS_SPOT_IMC_COMPEN_ODP INTO V_COMPRAS_SPOT_IMC_COMPEN_ODP,V_COMPRAS_SPOT_IMC_COMPEN_IDE,V_COMPRAS_SPOT_IMC_COMPEN_IVE;
    CLOSE COMPRAS_SPOT_IMC_COMPEN_ODP;

    OPEN VENTAS_SPOT_IMC_COMPEN_ORR(P_FECHA);
    FETCH VENTAS_SPOT_IMC_COMPEN_ORR INTO V_VENTAS_SPOT_IMC_COMPEN_ORR,V_VENTAS_SPOT_IMC_COMPEN_IDE,V_VENTAS_SPOT_IMC_COMPEN_IVE;
    CLOSE VENTAS_SPOT_IMC_COMPEN_ORR;

    V_SALDO_ESTIMADO :=  -NVL(V_COMPRAS_SPOT_IMC,0) + NVL(V_VENTAS_SPOT_IMC,0)-NVL(V_COMPRAS_SPOT_IMC_IVADES,0) + NVL(V_VENTAS_SPOT_IMC_IVADES,0)-NVL(V_COMPRAS_SPOT_IMC_IVAVEN,0) + NVL(V_VENTAS_SPOT_IMC_IVAVEN,0);
    V_SALDO_REAL     := -NVL(V_COMPRAS_SPOT_IMC_COMPEN_ODP,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_ORR,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IDE,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IVE,0);

    --SPOT
    INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                    ,CS_PRO_MNEMONICO
                                    ,CS_COMPENSACION
                                    ,CS_COMPENSADO
                                    ,CS_PENDIENTE)
    VALUES (P_FECHA
          ,'DIV_IS' -- BANCOS
          ,V_SALDO_ESTIMADO
          ,V_SALDO_REAL
          ,V_SALDO_ESTIMADO - V_SALDO_REAL);


  END IF;
  INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
          ,GCB_CBA_BAN_CODIGO
          ,GCB_CBA_NUMERO_CUENTA
          ,GCB_COMPENSACION
          ,GCB_COMPENSADO
          ,GCB_PENDIENTE
          ,GCB_OPERACION)
  VALUES (P_FECHA
         ,0
         ,'62255492'
         ,-NVL(V_COMPRAS_SPOT_CCD,0) + NVL(V_VENTAS_SPOT_CCD,0)-NVL(V_COMPRAS_SPOT_CCD_IVADES,0) + NVL(V_VENTAS_SPOT_CCD_IVADES,0)-NVL(V_COMPRAS_SPOT_CCD_IVAVEN,0) + NVL(V_VENTAS_SPOT_CCD_IVAVEN,0)-NVL(V_COMPRAS_SPOT_IMC,0) + NVL(V_VENTAS_SPOT_IMC,0)-NVL(V_COMPRAS_SPOT_IMC_IVADES,0) + NVL(V_VENTAS_SPOT_IMC_IVADES,0)-NVL(V_COMPRAS_SPOT_IMC_IVAVEN,0) + NVL(V_VENTAS_SPOT_IMC_IVAVEN,0)
         ,-NVL(V_COMPRAS_SPOT_CCD_COMPEN_ODP,0)+NVL(V_VENTAS_SPOT_CCD_COMPEN_ORR,0)-NVL(V_COMPRAS_SPOT_CCD_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IDE,0)-NVL(V_COMPRAS_SPOT_CCD_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IVE,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_ODP,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_ORR,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IDE,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IVE,0)
         ,(-NVL(V_COMPRAS_SPOT_CCD,0) + NVL(V_VENTAS_SPOT_CCD,0)-NVL(V_COMPRAS_SPOT_CCD_IVADES,0) + NVL(V_VENTAS_SPOT_CCD_IVADES,0)-NVL(V_COMPRAS_SPOT_CCD_IVAVEN,0) + NVL(V_VENTAS_SPOT_CCD_IVAVEN,0)-NVL(V_COMPRAS_SPOT_IMC,0) + NVL(V_VENTAS_SPOT_IMC,0)-NVL(V_COMPRAS_SPOT_IMC_IVADES,0) + NVL(V_VENTAS_SPOT_IMC_IVADES,0)-NVL(V_COMPRAS_SPOT_IMC_IVAVEN,0) + NVL(V_VENTAS_SPOT_IMC_IVAVEN,0))-(-NVL(V_COMPRAS_SPOT_CCD_COMPEN_ODP,0)+NVL(V_VENTAS_SPOT_CCD_COMPEN_ORR,0)-NVL(V_COMPRAS_SPOT_CCD_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IDE,0)-NVL(V_COMPRAS_SPOT_CCD_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_CCD_COMPEN_IVE,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_ODP,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_ORR,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_IDE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IDE,0)-NVL(V_COMPRAS_SPOT_IMC_COMPEN_IVE,0) + NVL(V_VENTAS_SPOT_IMC_COMPEN_IVE,0))
         ,'DIV')  ;
END COMPENSACION_DIVISAS_TES;

PROCEDURE COMPENSACION_DIVISAS_CLIENTES (P_FECHA DATE) IS
  CURSOR COMPRAS_DIF_PSE (P_FECHA DATE) IS
    SELECT (SELECT NVL(SUM(ORD_VALOR_PESOS_NETOS),0)
    FROM   ORDENES_DIVISAS ,
           TIPOS_MVTOS_DIVISAS,
           MOVIMIENTOS_CUENTA_CORREDORES
    WHERE  ORD_TMD_MNEMONICO = TMD_MNEMONICO
          AND  ORD_SUC_CODIGO = MCC_ORD_SUC_CODIGO
          AND  ORD_CONSECUTIVO = MCC_ORD_CONSECUTIVO
          AND  ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
          AND  ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
          AND  MCC_CONSECUTIVO =  (SELECT  MIN(MCC2.MCC_CONSECUTIVO)
                                   FROM     MOVIMIENTOS_CUENTA_CORREDORES MCC2
                                   WHERE  MCC2.MCC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
                                   AND       MCC2.MCC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
                                   AND       MCC2.MCC_FECHA >= TRUNC(P_FECHA)
                                   AND       MCC2.MCC_FECHA < TRUNC(P_FECHA+1))
          AND  0 != (SELECT  SUM(MCC2.MCC_MONTO + MCC2.MCC_MONTO_BURSATIL)
                     FROM     MOVIMIENTOS_CUENTA_CORREDORES MCC2
                     WHERE  MCC2.MCC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
                      AND       MCC2.MCC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
                      AND       MCC2.MCC_FECHA >= TRUNC(P_FECHA)
                      AND       MCC2.MCC_FECHA < TRUNC(P_FECHA+1))
          AND ORD_EOF_CODIGO NOT IN ('ANU','REV')
          AND  ORD_TIPO_ORDEN = 'C'
          AND  TMD_COMERCIAL_USUARIO = 'C'
          AND  MCC_FECHA >= TRUNC(P_FECHA)
          AND  MCC_FECHA <  TRUNC(P_FECHA+1)
          AND ORD_OME_CONSECUTIVO IS NULL    -- no se incluyen las operaciones entre mesas
          AND  EXISTS (SELECT 'X'
                       FROM ORDENES_DE_PAGO
                       WHERE ODP_ORD_SUC_CODIGO = ORD_SUC_CODIGO
                             AND ODP_ORD_CONSECUTIVO = ORD_CONSECUTIVO
                             AND ODP_TPA_MNEMONICO != 'PSE'
                             AND ODP_ESTADO != 'ANU')) +

      (SELECT NVL(SUM(ORD.ORD_VALOR_PESOS_NETOS),0)
        FROM   ORDENES_DIVISAS ORD,
             TIPOS_MVTOS_DIVISAS TMD
      WHERE ORD.ORD_TMD_MNEMONICO = TMD.TMD_MNEMONICO
            AND  ORD.ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
            AND  ORD.ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
            AND ORD_EOF_CODIGO NOT IN ('ANU','REV')
            AND  ORD.ORD_TIPO_ORDEN = 'C'
            AND  TMD.TMD_COMERCIAL_USUARIO = 'C'
            AND ORD_OME_CONSECUTIVO IS NULL    -- no se incluyen las operaciones entre mesas
            AND (NOT EXISTS (SELECT 'X'
                             FROM ORDENES_DE_PAGO
                             WHERE ODP_ORD_SUC_CODIGO = ORD.ORD_SUC_CODIGO
                               AND ODP_ORD_CONSECUTIVO = ORD.ORD_CONSECUTIVO
                               AND ODP_FECHA >= TRUNC(P_FECHA)
                               AND ODP_FECHA <  TRUNC(P_FECHA+1)
                               AND (ODP_FECHA_ANULACION IS NULL OR
                                    (ODP_FECHA_ANULACION IS NOT NULL AND
                                      ODP_FECHA_ANULACION >= TRUNC(P_FECHA+1))))) ) MONTO FROM DUAL;

  CURSOR COMPRAS_PSE_VENTAS (P_FECHA DATE) IS
   SELECT (SELECT nvl(sum(ORD_VALOR_PESOS_NETOS),0) MONTO_ABONO_CUENTA_S
    FROM   ORDENES_DIVISAS ,
                 TIPOS_MVTOS_DIVISAS,
                 MOVIMIENTOS_CUENTA_CORREDORES,
                 TIPOS_MOVIMIENTO_CORREDORES,
                 ORDENES_DE_PAGO
    WHERE ORD_TMD_MNEMONICO = TMD_MNEMONICO
          AND  ORD_SUC_CODIGO = MCC_ORD_SUC_CODIGO
          AND  ORD_CONSECUTIVO = MCC_ORD_CONSECUTIVO
          AND  MCC_TMC_MNEMONICO = TMC_MNEMONICO
          AND  ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
          AND  ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
          AND  ORD_EOF_CODIGO NOT IN ('ANU','REV')
          AND  ORD_TIPO_ORDEN = 'C'
          AND  TMD_COMERCIAL_USUARIO = 'C'
          AND  MCC_FECHA >= TRUNC(P_FECHA)
          AND  MCC_FECHA <  TRUNC(P_FECHA+1)
          AND MCC_ODP_CONSECUTIVO = ODP_CONSECUTIVO
          AND MCC_ODP_SUC_CODIGO = ODP_SUC_CODIGO
          AND MCC_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
          AND  ODP_ORD_SUC_CODIGO = ORD_SUC_CODIGO
          AND ODP_ORD_CONSECUTIVO = ORD_CONSECUTIVO
          AND ODP_TPA_MNEMONICO = 'PSE'
          AND ODP_ESTADO != 'ANU'
          AND ORD_OME_CONSECUTIVO IS NULL)     -- no se incluyen las operaciones entre mesas
    +
    (SELECT  NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL),0) MONTO_ABONO_CUENTA_S
    FROM   ORDENES_DIVISAS ,
           TIPOS_MVTOS_DIVISAS,
           MOVIMIENTOS_CUENTA_CORREDORES,
            TIPOS_MOVIMIENTO_CORREDORES
    WHERE  ORD_TMD_MNEMONICO = TMD_MNEMONICO
          AND  ORD_SUC_CODIGO = MCC_ORD_SUC_CODIGO
          AND  ORD_CONSECUTIVO = MCC_ORD_CONSECUTIVO
          AND  MCC_TMC_MNEMONICO = TMC_MNEMONICO
          AND  ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
          AND  ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
          AND  ORD_EOF_CODIGO NOT IN ('ANU','REV')
          AND  ORD_TIPO_ORDEN = 'V'
          AND  TMD_COMERCIAL_USUARIO = 'C'
          AND  MCC_FECHA >= TRUNC(P_FECHA)
          AND  MCC_FECHA <  TRUNC(P_FECHA+1)
          AND  MCC_TMC_MNEMONICO NOT IN ('IBC', 'RIBC')
          AND ORD_OME_CONSECUTIVO IS NULL) MONTO FROM DUAL;    -- no se incluyen las operaciones entre mesas

  CURSOR COMPENSACION_CLIENTES_DIVISAS IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0) ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO
    WHERE ODP_PER_NUM_IDEN = '8600791743'
      AND ODP_PER_TID_CODIGO = 'NIT'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_COT_MNEMONICO = 'GCDV'
      AND ODP_NEG_CONSECUTIVO = 2
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_ESTADO <> 'ANU'
      AND ODP_FECHA >= TRUNC(P_FECHA)
      AND ODP_FECHA <= TRUNC(P_FECHA+1)
      ;

  CURSOR COMPENSACION_DIVISAS_CLIENTES IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0) ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO
    WHERE ODP_PER_NUM_IDEN = '8600791743'
      AND ODP_PER_TID_CODIGO = 'NIT'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_COT_MNEMONICO = 'GCDIV'
      AND ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_ESTADO <> 'ANU'
      AND ODP_FECHA >= TRUNC(P_FECHA)
      AND ODP_FECHA <= TRUNC(P_FECHA+1)
      AND ODP_MAS_INSTRUCCIONES IS NULL
      ;

  V_COMPRAS_DIF_PSE    NUMBER;
  V_COMPRAS_PSE_VENTAS NUMBER;
  V_SALDO_REAL_CD      NUMBER;
  V_SALDO_REAL_DC      NUMBER;
BEGIN

  OPEN COMPRAS_DIF_PSE(P_FECHA);
  FETCH COMPRAS_DIF_PSE INTO V_COMPRAS_DIF_PSE;
  CLOSE COMPRAS_DIF_PSE;

  OPEN COMPRAS_PSE_VENTAS(P_FECHA);
  FETCH COMPRAS_PSE_VENTAS INTO V_COMPRAS_PSE_VENTAS;
  CLOSE COMPRAS_PSE_VENTAS;

  OPEN COMPENSACION_CLIENTES_DIVISAS;
  FETCH COMPENSACION_CLIENTES_DIVISAS INTO V_SALDO_REAL_CD;
  CLOSE COMPENSACION_CLIENTES_DIVISAS;

  OPEN COMPENSACION_DIVISAS_CLIENTES;
  FETCH COMPENSACION_DIVISAS_CLIENTES INTO V_SALDO_REAL_DC;
  CLOSE COMPENSACION_DIVISAS_CLIENTES;

  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'DICL'         --BANCOS
        ,V_COMPRAS_DIF_PSE
        ,0
        ,V_COMPRAS_DIF_PSE
        );
  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'CLDI'         --BANCOS
        ,V_COMPRAS_PSE_VENTAS
        ,V_SALDO_REAL_DC - V_SALDO_REAL_CD
        ,V_COMPRAS_PSE_VENTAS
        );
END COMPENSACION_DIVISAS_CLIENTES;

PROCEDURE COMPENSACION_DIV_CLI_TES (P_FECHA DATE) IS
  CURSOR COMPRAS_DIF_PSE (P_FECHA DATE) IS
    SELECT (SELECT NVL(SUM(ORD_VALOR_PESOS_NETOS),0)
    FROM   ORDENES_DIVISAS ,
           TIPOS_MVTOS_DIVISAS,
           MOVIMIENTOS_CUENTA_CORREDORES
    WHERE  ORD_TMD_MNEMONICO = TMD_MNEMONICO
          AND  ORD_SUC_CODIGO = MCC_ORD_SUC_CODIGO
          AND  ORD_CONSECUTIVO = MCC_ORD_CONSECUTIVO
          AND  ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
          AND  ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
          AND  MCC_CONSECUTIVO =  (SELECT  MIN(MCC2.MCC_CONSECUTIVO)
                                   FROM     MOVIMIENTOS_CUENTA_CORREDORES MCC2
                                   WHERE  MCC2.MCC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
                                   AND       MCC2.MCC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
                                   AND       MCC2.MCC_FECHA >= TRUNC(P_FECHA)
                                   AND       MCC2.MCC_FECHA < TRUNC(P_FECHA+1))
          AND  0 != (SELECT  SUM(MCC2.MCC_MONTO + MCC2.MCC_MONTO_BURSATIL)
                     FROM     MOVIMIENTOS_CUENTA_CORREDORES MCC2
                     WHERE  MCC2.MCC_ORD_SUC_CODIGO = ORD_SUC_CODIGO
                      AND       MCC2.MCC_ORD_CONSECUTIVO = ORD_CONSECUTIVO
                      AND       MCC2.MCC_FECHA >= TRUNC(P_FECHA)
                      AND       MCC2.MCC_FECHA < TRUNC(P_FECHA+1))
          AND ORD_EOF_CODIGO NOT IN ('ANU','REV')
          AND  ORD_TIPO_ORDEN = 'C'
          AND  TMD_COMERCIAL_USUARIO = 'C'
          AND  MCC_FECHA >= TRUNC(P_FECHA)
          AND  MCC_FECHA <  TRUNC(P_FECHA+1)
          AND ORD_OME_CONSECUTIVO IS NULL    -- no se incluyen las operaciones entre mesas
          AND  EXISTS (SELECT 'X'
                       FROM ORDENES_DE_PAGO
                       WHERE ODP_ORD_SUC_CODIGO = ORD_SUC_CODIGO
                             AND ODP_ORD_CONSECUTIVO = ORD_CONSECUTIVO
                             AND ODP_TPA_MNEMONICO != 'PSE'
                             AND ODP_ESTADO != 'ANU')) +

      (SELECT NVL(SUM(ORD.ORD_VALOR_PESOS_NETOS),0)
        FROM   ORDENES_DIVISAS ORD,
             TIPOS_MVTOS_DIVISAS TMD
      WHERE ORD.ORD_TMD_MNEMONICO = TMD.TMD_MNEMONICO
            AND  ORD.ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
            AND  ORD.ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
            AND ORD_EOF_CODIGO NOT IN ('ANU','REV')
            AND  ORD.ORD_TIPO_ORDEN = 'C'
            AND  TMD.TMD_COMERCIAL_USUARIO = 'C'
            AND ORD_OME_CONSECUTIVO IS NULL    -- no se incluyen las operaciones entre mesas
            AND (NOT EXISTS (SELECT 'X'
                             FROM ORDENES_DE_PAGO
                             WHERE ODP_ORD_SUC_CODIGO = ORD.ORD_SUC_CODIGO
                               AND ODP_ORD_CONSECUTIVO = ORD.ORD_CONSECUTIVO
                               AND ODP_FECHA >= TRUNC(P_FECHA)
                               AND ODP_FECHA <  TRUNC(P_FECHA+1)
                               AND (ODP_FECHA_ANULACION IS NULL OR
                                    (ODP_FECHA_ANULACION IS NOT NULL AND
                                      ODP_FECHA_ANULACION >= TRUNC(P_FECHA+1)))))) MONTO FROM DUAL;

  CURSOR COMPENSACION_CLIENTES_DIVISAS (P_FECHA DATE) IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0)
    FROM ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS
    WHERE ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
      AND ODP_SUC_CODIGO = TBC_SUC_CODIGO
      AND ODP_NEG_CONSECUTIVO = TBC_NEG_CONSECUTIVO
      AND ODP_PER_NUM_IDEN = '8600791743'
      AND ODP_PER_TID_CODIGO = 'NIT'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_COT_MNEMONICO = 'GCDV'
      AND ODP_NEG_CONSECUTIVO = 2
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_ESTADO <> 'ANU'
      AND ODP_TBC_CONSECUTIVO IS NOT NULL
      AND TBC_FECHA >= TRUNC(P_FECHA)
      AND TBC_FECHA <= TRUNC(P_FECHA+1);

  CURSOR COMPENSACION_DIVISAS_CLIENTES (P_FECHA DATE) IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0)
    FROM ORDENES_DE_PAGO, TRANSFERENCIAS_BANCARIAS
    WHERE ODP_TBC_CONSECUTIVO = TBC_CONSECUTIVO
      AND ODP_SUC_CODIGO = TBC_SUC_CODIGO
      AND ODP_NEG_CONSECUTIVO = TBC_NEG_CONSECUTIVO
      AND ODP_PER_NUM_IDEN = '8600791743'
      AND ODP_PER_TID_CODIGO = 'NIT'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_COT_MNEMONICO = 'GCDIV'
      AND ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_ESTADO <> 'ANU'
      AND ODP_TBC_CONSECUTIVO IS NOT NULL
      AND TBC_FECHA >= TRUNC(P_FECHA)
      AND TBC_FECHA <= TRUNC(P_FECHA+1);

  CURSOR COMPRAS_PSE_VENTAS (P_FECHA DATE) IS
   SELECT (SELECT nvl(sum(ORD_VALOR_PESOS_NETOS),0) MONTO_ABONO_CUENTA_S
    FROM   ORDENES_DIVISAS ,
                 TIPOS_MVTOS_DIVISAS,
                 MOVIMIENTOS_CUENTA_CORREDORES,
                 TIPOS_MOVIMIENTO_CORREDORES,
                 ORDENES_DE_PAGO
    WHERE ORD_TMD_MNEMONICO = TMD_MNEMONICO
          AND  ORD_SUC_CODIGO = MCC_ORD_SUC_CODIGO
          AND  ORD_CONSECUTIVO = MCC_ORD_CONSECUTIVO
          AND  MCC_TMC_MNEMONICO = TMC_MNEMONICO
          AND  ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
          AND  ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
          AND  ORD_EOF_CODIGO NOT IN ('ANU','REV')
          AND  ORD_TIPO_ORDEN = 'C'
          AND  TMD_COMERCIAL_USUARIO = 'C'
          AND  MCC_FECHA >= TRUNC(P_FECHA)
          AND  MCC_FECHA <  TRUNC(P_FECHA+1)
          AND MCC_ODP_CONSECUTIVO = ODP_CONSECUTIVO
          AND MCC_ODP_SUC_CODIGO = ODP_SUC_CODIGO
          AND MCC_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
          AND  ODP_ORD_SUC_CODIGO = ORD_SUC_CODIGO
          AND ODP_ORD_CONSECUTIVO = ORD_CONSECUTIVO
          AND ODP_TPA_MNEMONICO = 'PSE'
          AND ODP_ESTADO != 'ANU'
          AND ORD_OME_CONSECUTIVO IS NULL)     -- no se incluyen las operaciones entre mesas
    +
    (SELECT  NVL(SUM (MCC_MONTO + MCC_MONTO_BURSATIL),0) MONTO_ABONO_CUENTA_S
    FROM   ORDENES_DIVISAS ,
           TIPOS_MVTOS_DIVISAS,
           MOVIMIENTOS_CUENTA_CORREDORES,
            TIPOS_MOVIMIENTO_CORREDORES
    WHERE  ORD_TMD_MNEMONICO = TMD_MNEMONICO
          AND  ORD_SUC_CODIGO = MCC_ORD_SUC_CODIGO
          AND  ORD_CONSECUTIVO = MCC_ORD_CONSECUTIVO
          AND  MCC_TMC_MNEMONICO = TMC_MNEMONICO
          AND  ORD_FECHA_APROBACION >= TRUNC(P_FECHA)
          AND  ORD_FECHA_APROBACION <  TRUNC(P_FECHA+1)
          AND  ORD_EOF_CODIGO NOT IN ('ANU','REV')
          AND  ORD_TIPO_ORDEN = 'V'
          AND  TMD_COMERCIAL_USUARIO = 'C'
          AND  MCC_FECHA >= TRUNC(P_FECHA)
          AND  MCC_FECHA <  TRUNC(P_FECHA+1)
          AND  MCC_TMC_MNEMONICO NOT IN ('IBC', 'RIBC')
          AND ORD_OME_CONSECUTIVO IS NULL) MONTO FROM DUAL;    -- no se incluyen las operaciones entre mesas

  V_COMPRAS_DIF_PSE    NUMBER;
  V_COMPRAS_PSE_VENTAS NUMBER;
  V_SALDO_REAL_CD      NUMBER := 0;
  V_SALDO_REAL_DC      NUMBER := 0;
  VCS_COMPENSACION     NUMBER := 0;
  VCS_COMPENSADO       NUMBER := 0;
  P_SIGNO1             NUMBER;
BEGIN

  OPEN COMPRAS_DIF_PSE(P_FECHA);
  FETCH COMPRAS_DIF_PSE INTO V_COMPRAS_DIF_PSE;
  CLOSE COMPRAS_DIF_PSE;

  OPEN COMPRAS_PSE_VENTAS(P_FECHA);
  FETCH COMPRAS_PSE_VENTAS INTO V_COMPRAS_PSE_VENTAS;
  CLOSE COMPRAS_PSE_VENTAS;

  OPEN COMPENSACION_CLIENTES_DIVISAS(P_FECHA);
  FETCH COMPENSACION_CLIENTES_DIVISAS INTO V_SALDO_REAL_CD;
  CLOSE COMPENSACION_CLIENTES_DIVISAS;

  OPEN COMPENSACION_DIVISAS_CLIENTES(P_FECHA);
  FETCH COMPENSACION_DIVISAS_CLIENTES INTO V_SALDO_REAL_DC;
  CLOSE COMPENSACION_DIVISAS_CLIENTES;

  VCS_COMPENSACION := (NVL(V_COMPRAS_DIF_PSE,0) + NVL(V_COMPRAS_PSE_VENTAS,0));
  VCS_COMPENSADO := (NVL(V_SALDO_REAL_DC,0) - NVL(V_SALDO_REAL_CD,0) );

  SELECT INSTRB (VCS_COMPENSACION, '-', 1, 1) INTO P_SIGNO1 FROM DUAL;
  IF P_SIGNO1 = 1 THEN
     VCS_COMPENSACION:=VCS_COMPENSACION * (-1);
  ELSE
     VCS_COMPENSACION:=VCS_COMPENSACION * (-1);
  END IF;

  SELECT INSTRB (VCS_COMPENSADO, '-', 1, 1) INTO P_SIGNO1 FROM DUAL;
  IF P_SIGNO1 = 1 THEN
     VCS_COMPENSADO:=VCS_COMPENSADO * (-1);
  ELSE
     VCS_COMPENSADO:=VCS_COMPENSADO * (-1);
  END IF;


  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'CL'         --BANCOS
        ,VCS_COMPENSACION
        ,VCS_COMPENSADO
        ,VCS_COMPENSACION-VCS_COMPENSADO
        );
  ----
  INSERT INTO GL_CONSOLIDACION_BANCOS(GCB_FECHA
          ,GCB_CBA_BAN_CODIGO
          ,GCB_CBA_NUMERO_CUENTA
          ,GCB_COMPENSACION
          ,GCB_COMPENSADO
          ,GCB_PENDIENTE
          ,GCB_OPERACION)
  VALUES (P_FECHA
         ,0
         ,'62255492'
         ,VCS_COMPENSACION
         ,VCS_COMPENSADO
         ,VCS_COMPENSACION-VCS_COMPENSADO
         ,'DIV')  ;

END COMPENSACION_DIV_CLI_TES;

PROCEDURE COMPENSACION_DIVISAS_UTIL_PERD (P_FECHA DATE) IS
  CURSOR SALDOS_INICIALES IS
    SELECT A.CDI_FECHA_DIA
          ,A.CDI_FECHA_PROCESO
          ,A.CDI_INVENTARIO_INICIAL_USD
          ,A.CDI_INVENTARIO_INICIAL_PESOS
          ,A.CDI_COMPRAS_USD
          ,A.CDI_COMPRAS_PESOS
          ,A.CDI_VENTAS_USD
          ,A.CDI_VENTAS_PESOS
          ,A.CDI_INVENTARIO_FINAL_USD
          ,A.CDI_INVENTARIO_FINAL_PESOS
          ,A.CDI_VALOR_TPC_DIA
          ,A.CDI_UTILIDAD_OPERATIVA
          ,A.CDI_COMISION
          ,A.CDI_COMISION_COMERCIAL
          ,A.CDI_GASTOS_GIRO
          ,A.CDI_VALOR_TPC_DIA_CHEQUES
          ,A.CDI_VALOR_TPC_DIA_EFECTIVO
      FROM CIERRE_DIVISAS A
      WHERE TRUNC(A.CDI_FECHA_PROCESO) = (SELECT TRUNC(B.CDI_FECHA_PROCESO)
                                          FROM CIERRE_DIVISAS B
                                          WHERE TRUNC(B.CDI_FECHA_DIA) = TRUNC(P_FECHA));
  C_SALDOS_INICIALES          SALDOS_INICIALES%ROWTYPE;

  CURSOR C_TOTAL_VENTAS IS
    SELECT NVL(SUM(ORD_VALOR_DOLARES),0) ORD_TOTAL_USD
          ,NVL(SUM(ORD_VALOR_PESOS),0) ORD_TOTAL_PESOS
          ,NVL(SUM(ORD_VALOR_COMISION),0) ORD_TOTAL_COMISION
          ,NVL(SUM(ORD_COMISION_COMERCIAL),0) ORD_TOTAL_COMISION_COMERCIAL
          ,NVL(SUM(ORD_GASTOS_GIRO),0) ORD_TOTAL_GASTOS_GIRO
    FROM ORDENES_DIVISAS
    WHERE ORDENES_DIVISAS.ORD_EOF_CODIGO = 'APR' AND
    ORDENES_DIVISAS.ORD_TIPO_ORDEN = 'V'
    AND ((TRUNC(ORD_FECHA_COLOCACION) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) = 0)
    OR (TRUNC(ORD_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) IN (1,2,3))) ;
  TOTAL_VENTAS C_TOTAL_VENTAS%ROWTYPE;

  CURSOR C_TOTAL_COMPRAS IS
    SELECT NVL(SUM(ORD_VALOR_DOLARES),0) ORD_TOTAL_USD
          ,NVL(SUM(ORD_VALOR_PESOS),0) ORD_TOTAL_PESOS
          ,NVL(SUM(ORD_VALOR_COMISION),0) ORD_TOTAL_COMISION
          ,NVL(SUM(ORD_COMISION_COMERCIAL),0) ORD_TOTAL_COMISION_COMERCIAL
          ,NVL(SUM(ORD_GASTOS_GIRO),0) ORD_TOTAL_GASTOS_GIRO
    FROM ORDENES_DIVISAS
    WHERE ORDENES_DIVISAS.ORD_EOF_CODIGO = 'APR' AND
    ORDENES_DIVISAS.ORD_TIPO_ORDEN = 'C'
    AND ((TRUNC(ORD_FECHA_COLOCACION) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) = 0)
    OR (TRUNC(ORD_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) IN (1,2,3))) ;
  TOTAL_COMPRAS C_TOTAL_COMPRAS%ROWTYPE;

  CURSOR C_TOTAL_GASTOS IS
    SELECT NVL(SUM(ORD_VALOR_PESOS),0) ORD_TOTAL_PESOS
    FROM ORDENES_DIVISAS
    WHERE ORDENES_DIVISAS.ORD_EOF_CODIGO = 'APR' AND
    ORDENES_DIVISAS.ORD_TIPO_ORDEN = 'V'
    AND ((TRUNC(ORD_FECHA_COLOCACION) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) = 0)
    OR (TRUNC(ORD_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) IN (1,2,3)))
    AND ORD_TMD_MNEMONICO  = 'VEPYG';
  TOTAL_GASTOS C_TOTAL_GASTOS%ROWTYPE;

  CURSOR C_TOTAL_PERD_FOREX IS
    SELECT NVL(SUM(ORD_VALOR_PESOS),0) ORD_TOTAL_PESOS
    FROM ORDENES_DIVISAS
    WHERE ORDENES_DIVISAS.ORD_EOF_CODIGO = 'APR' AND
    ORDENES_DIVISAS.ORD_TIPO_ORDEN = 'V'
    AND ((TRUNC(ORD_FECHA_COLOCACION) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) = 0)
    OR (TRUNC(ORD_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) IN (1,2,3)))
    AND ORD_TMD_MNEMONICO  IN ('PVEFX','VROTM')
    AND ORD_ORIGEN_OPERACION = 'P';
  TOTAL_PERD_FOREX C_TOTAL_PERD_FOREX%ROWTYPE;

  CURSOR C_TOTAL_UTIL_OTRAS_MON IS
    SELECT NVL(SUM(ORD_VALOR_PESOS),0) ORD_TOTAL_PESOS
    FROM ORDENES_DIVISAS
    WHERE ORDENES_DIVISAS.ORD_EOF_CODIGO = 'APR' AND
    ORDENES_DIVISAS.ORD_TIPO_ORDEN = 'C'
    AND ((TRUNC(ORD_FECHA_COLOCACION) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) = 0)
    OR (TRUNC(ORD_FECHA_CUMPLIMIENTO) = TRUNC(P_FECHA)
         AND NVL(ORD_DIAS_NEXT_DAY,0) IN (1,2,3)))
    AND ORD_TMD_MNEMONICO IN ('COOTM','COPYG','UCOFX')
    AND ORD_ORIGEN_OPERACION = 'P';
  TOTAL_UTIL_OTRAS_MON C_TOTAL_UTIL_OTRAS_MON%ROWTYPE;

  CURSOR C_UTIPER_PARAME (P_PPC_TIPO VARCHAR2) IS
    SELECT PPC_COT_MNEMONICO
          ,PPC_CBA_BAN_CODIGO
          ,PPC_CBA_NUMERO_CUENTA
          ,PPC_PER_NUM_IDEN
          ,PPC_PER_TID_CODIGO
    FROM PARAMETROS_COMPENSACIONES
    WHERE PPC_PRO_MNEMONICO = 'DIV'
      AND PPC_TIPO_COMPENSACION = 'CDIUP'
      AND PPC_TIPO = P_PPC_TIPO;
  UTIPER_PARAME_RCA C_UTIPER_PARAME%ROWTYPE;
  UTIPER_PARAME_ODP C_UTIPER_PARAME%ROWTYPE;

  CURSOR C_ODP_UTIPER (P_PPC_PER_NUM_IDEN VARCHAR2
                      ,P_PPC_PER_TID_CODIGO VARCHAR2
                      ,P_PPC_CBA_BAN_CODIGO NUMBER
                      ,P_PPC_CBA_NUMERO_CUENTA VARCHAR2
                      ,P_PPC_COT_MNEMONICO VARCHAR2) IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0) ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_PER_NUM_IDEN = P_PPC_PER_NUM_IDEN
      AND ODP_PER_TID_CODIGO = P_PPC_PER_TID_CODIGO
      AND ODP_BAN_CODIGO = P_PPC_CBA_BAN_CODIGO
      AND ODP_NUM_CUENTA_CONSIGNAR = P_PPC_CBA_NUMERO_CUENTA
      AND ODP_COT_MNEMONICO = P_PPC_COT_MNEMONICO
      AND ODP_ESTADO = 'APR'
      AND ODP_FECHA >= TRUNC(P_FECHA)
      AND ODP_FECHA < TRUNC(P_FECHA+1)
      AND ODP_MAS_INSTRUCCIONES = 'UTI/PER';

  CURSOR C_RCA_UTIPER (P_PPC_PER_NUM_IDEN VARCHAR2
                      ,P_PPC_PER_TID_CODIGO VARCHAR2
                      ,P_PPC_CBA_BAN_CODIGO NUMBER
                      ,P_PPC_CBA_NUMERO_CUENTA VARCHAR2
                      ,P_PPC_COT_MNEMONICO VARCHAR2) IS
    SELECT NVL(SUM(ORR_MONTO),0) ORR_MONTO
    FROM ORDENES_RECAUDO
    WHERE ORR_NEG_CONSECUTIVO = 8
    AND ORR_PER_NUM_IDEN = P_PPC_PER_NUM_IDEN
    AND ORR_PER_TID_CODIGO = P_PPC_PER_TID_CODIGO
    AND ORR_COT_MNEMONICO = P_PPC_COT_MNEMONICO
    AND ORR_CBA_BAN_CODIGO = P_PPC_CBA_BAN_CODIGO
    AND ORR_CBA_NUMERO_CUENTA = P_PPC_CBA_NUMERO_CUENTA
    AND ORR_FECHA >= TRUNC(P_FECHA)
    AND ORR_FECHA < TRUNC(P_FECHA+1)
    AND ORR_OTRAS_INSTRUCCIONES = 'UTI/PER'
    AND ORR_ESTADO = 'APR';

  CURSOR C_IVACOM_PARAME (P_PPC_TIPO VARCHAR2) IS
    SELECT PPC_COT_MNEMONICO
          ,PPC_CBA_BAN_CODIGO
          ,PPC_CBA_NUMERO_CUENTA
          ,PPC_PER_NUM_IDEN
          ,PPC_PER_TID_CODIGO
    FROM PARAMETROS_COMPENSACIONES
    WHERE PPC_PRO_MNEMONICO = 'DIV'
      AND PPC_TIPO_COMPENSACION = 'CDICO'
      AND PPC_TIPO = P_PPC_TIPO;
  IVACOM_PARAME_RCA C_IVACOM_PARAME%ROWTYPE;
  IVACOM_PARAME_ODP C_IVACOM_PARAME%ROWTYPE;

  CURSOR C_ODP_IVACOM (P_PPC_PER_NUM_IDEN VARCHAR2
                      ,P_PPC_PER_TID_CODIGO VARCHAR2
                      ,P_PPC_CBA_BAN_CODIGO NUMBER
                      ,P_PPC_CBA_NUMERO_CUENTA VARCHAR2
                      ,P_PPC_COT_MNEMONICO VARCHAR2) IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0) ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_PER_NUM_IDEN = P_PPC_PER_NUM_IDEN
      AND ODP_PER_TID_CODIGO = P_PPC_PER_TID_CODIGO
      AND ODP_BAN_CODIGO = P_PPC_CBA_BAN_CODIGO
      AND ODP_NUM_CUENTA_CONSIGNAR = P_PPC_CBA_NUMERO_CUENTA
      AND ODP_COT_MNEMONICO = P_PPC_COT_MNEMONICO
      AND ODP_FECHA >= TRUNC(P_FECHA)
      AND ODP_FECHA < TRUNC(P_FECHA+1)
      AND ODP_ESTADO = 'APR'
      AND ODP_MAS_INSTRUCCIONES = 'IVACOM';

  CURSOR C_NEDI_PARAME (P_PPC_TIPO VARCHAR2) IS
    SELECT PPC_COT_MNEMONICO
          ,PPC_CBA_BAN_CODIGO
          ,PPC_CBA_NUMERO_CUENTA
          ,PPC_PER_NUM_IDEN
          ,PPC_PER_TID_CODIGO
    FROM PARAMETROS_COMPENSACIONES
    WHERE PPC_PRO_MNEMONICO = 'DIV'
      AND PPC_TIPO_COMPENSACION = 'CDNET'
      AND PPC_TIPO = P_PPC_TIPO;
  NEDI_PARAME_RCA C_NEDI_PARAME%ROWTYPE;
  NEDI_PARAME_ODP C_NEDI_PARAME%ROWTYPE;

  CURSOR C_ODP_NEDI (P_PPC_PER_NUM_IDEN VARCHAR2
                      ,P_PPC_PER_TID_CODIGO VARCHAR2
                      ,P_PPC_CBA_BAN_CODIGO NUMBER
                      ,P_PPC_CBA_NUMERO_CUENTA VARCHAR2
                      ,P_PPC_COT_MNEMONICO VARCHAR2) IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0) ODP_MONTO_ORDEN
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 8
      AND ODP_NPR_PRO_MNEMONICO = 'DIV'
      AND ODP_TPA_MNEMONICO = 'TRB'
      AND ODP_PER_NUM_IDEN = P_PPC_PER_NUM_IDEN
      AND ODP_PER_TID_CODIGO = P_PPC_PER_TID_CODIGO
      AND ODP_BAN_CODIGO = P_PPC_CBA_BAN_CODIGO
      AND ODP_NUM_CUENTA_CONSIGNAR = P_PPC_CBA_NUMERO_CUENTA
      AND ODP_COT_MNEMONICO = P_PPC_COT_MNEMONICO
      AND ODP_FECHA >= TRUNC(P_FECHA)
      AND ODP_FECHA < TRUNC(P_FECHA+1)
      AND ODP_ESTADO = 'APR'
      AND ODP_MAS_INSTRUCCIONES = 'NETODIV';

  CURSOR C_RCA_NEDI (P_PPC_PER_NUM_IDEN VARCHAR2
                     ,P_PPC_PER_TID_CODIGO VARCHAR2
                     ,P_PPC_CBA_BAN_CODIGO NUMBER
                     ,P_PPC_CBA_NUMERO_CUENTA VARCHAR2
                     ,P_PPC_COT_MNEMONICO VARCHAR2) IS
    SELECT NVL(SUM(ORR_MONTO),0) ORR_MONTO
    FROM ORDENES_RECAUDO
    WHERE ORR_NEG_CONSECUTIVO = 8
    AND ORR_PER_NUM_IDEN = P_PPC_PER_NUM_IDEN
    AND ORR_PER_TID_CODIGO = P_PPC_PER_TID_CODIGO
    AND ORR_COT_MNEMONICO = P_PPC_COT_MNEMONICO
    AND ORR_CBA_BAN_CODIGO = P_PPC_CBA_BAN_CODIGO
    AND ORR_CBA_NUMERO_CUENTA = P_PPC_CBA_NUMERO_CUENTA
    AND ORR_FECHA >= TRUNC(P_FECHA)
    AND ORR_FECHA < TRUNC(P_FECHA+1)
    AND ORR_ESTADO <> 'ANU'
    AND ORR_OTRAS_INSTRUCCIONES = 'NETODIV';

  --DECLARACIONES DEL BLOQUE CDI
  CDI_INVENTARIO_INICIAL_USD     CIERRE_DIVISAS.CDI_INVENTARIO_INICIAL_USD%TYPE;
  CDI_INVENTARIO_INICIAL_PESOS   CIERRE_DIVISAS.CDI_INVENTARIO_INICIAL_PESOS%TYPE;
  CDI_COMPRAS_USD                NUMBER;
  CDI_COMPRAS_PESOS              NUMBER;
  CDI_VENTAS_USD                 NUMBER;
  CDI_VENTAS_PESOS               NUMBER;
  CDI_INVENTARIO_FINAL_PESOS     NUMBER;
  CDI_UTILIDAD_OPERATIVA         NUMBER(22,2);
  CDI_COMISION                   NUMBER;
  CDI_INVENTARIO_FINAL_USD       NUMBER;
  CDI_TASA_VENTAS                NUMBER;
  CDI_GASTOS                     NUMBER;
  CDI_PERD_FOREX                 NUMBER;
  CDI_UTIL_OTRAS                 NUMBER;
  CDI_FECHA_PROCESO              DATE;
  V_IVA NUMBER;
  ODP_UTIPER NUMBER;
  RCA_UTIPER NUMBER;
  ODP_IVACOM NUMBER;
  ODP_NEDI NUMBER;
  RCA_NEDI NUMBER;

BEGIN
  CDI_FECHA_PROCESO := P_FECHA;

  -- DETERMINAR VALORES DEL INVENTARIO INICIAL
  OPEN SALDOS_INICIALES;
  FETCH SALDOS_INICIALES INTO C_SALDOS_INICIALES;
    IF SALDOS_INICIALES%FOUND THEN
  	  CDI_INVENTARIO_INICIAL_USD   := C_SALDOS_INICIALES.CDI_INVENTARIO_FINAL_USD;
      CDI_INVENTARIO_INICIAL_PESOS := C_SALDOS_INICIALES.CDI_INVENTARIO_FINAL_PESOS;
    --ELSE
  	--  RAISE_APPLICATION_ERROR(-20002,'No existe Inventario de moneda dia anterior');
    END IF;
  CLOSE SALDOS_INICIALES;

  OPEN C_TOTAL_VENTAS;
  FETCH C_TOTAL_VENTAS INTO TOTAL_VENTAS;
  CLOSE C_TOTAL_VENTAS;

  OPEN C_TOTAL_COMPRAS;
  FETCH C_TOTAL_COMPRAS INTO TOTAL_COMPRAS;
  CLOSE C_TOTAL_COMPRAS;

  OPEN C_TOTAL_GASTOS;
  FETCH C_TOTAL_GASTOS INTO TOTAL_GASTOS;
  CLOSE C_TOTAL_GASTOS;

  OPEN C_TOTAL_PERD_FOREX;
  FETCH C_TOTAL_PERD_FOREX INTO TOTAL_PERD_FOREX;
  CLOSE C_TOTAL_PERD_FOREX;

  OPEN C_TOTAL_UTIL_OTRAS_MON;
  FETCH C_TOTAL_UTIL_OTRAS_MON INTO TOTAL_UTIL_OTRAS_MON;
  CLOSE C_TOTAL_UTIL_OTRAS_MON;

  ---CALCULA UTILIDADES/PERDIDAS
  -- VALOR DE COMPRAS
  CDI_COMPRAS_USD   := NVL(TOTAL_COMPRAS.ORD_TOTAL_USD,0);
  CDI_COMPRAS_PESOS := NVL(TOTAL_COMPRAS.ORD_TOTAL_PESOS,0);

  -- VALOR DE VENTAS
  CDI_VENTAS_USD    := NVL(TOTAL_VENTAS.ORD_TOTAL_USD,0);
  CDI_VENTAS_PESOS  := NVL(TOTAL_VENTAS.ORD_TOTAL_PESOS,0);

  --TOTAL GASTOS
  CDI_GASTOS := NVL(TOTAL_GASTOS.ORD_TOTAL_PESOS,0);

  --TOTAL FOREX
  CDI_PERD_FOREX := NVL(TOTAL_PERD_FOREX.ORD_TOTAL_PESOS,0);
  CDI_UTIL_OTRAS := NVL(TOTAL_UTIL_OTRAS_MON.ORD_TOTAL_PESOS,0);

  IF NVL(CDI_VENTAS_USD,0) = 0 THEN
    CDI_TASA_VENTAS := CDI_VENTAS_PESOS / 1;
  ELSE
    CDI_TASA_VENTAS := CDI_VENTAS_PESOS / CDI_VENTAS_USD;
  END IF;

  -- VALORES INVENTARIO FINAL
  CDI_INVENTARIO_FINAL_USD   := CDI_INVENTARIO_INICIAL_USD + CDI_COMPRAS_USD - CDI_VENTAS_USD;
  IF (CDI_INVENTARIO_INICIAL_USD + CDI_COMPRAS_USD) = 0 THEN
    CDI_INVENTARIO_FINAL_PESOS := ((CDI_INVENTARIO_INICIAL_PESOS + CDI_COMPRAS_PESOS) / 1) * CDI_INVENTARIO_FINAL_USD;
    -- VALOR UTILIDAD OPERATIVA
    CDI_UTILIDAD_OPERATIVA := (CDI_TASA_VENTAS - (CDI_INVENTARIO_INICIAL_PESOS + CDI_COMPRAS_PESOS) / 1) * CDI_VENTAS_USD;
  ELSE
    CDI_INVENTARIO_FINAL_PESOS := ((CDI_INVENTARIO_INICIAL_PESOS + CDI_COMPRAS_PESOS) / (CDI_INVENTARIO_INICIAL_USD + CDI_COMPRAS_USD)) * CDI_INVENTARIO_FINAL_USD;
    -- VALOR UTILIDAD OPERATIVA
    CDI_UTILIDAD_OPERATIVA := (CDI_TASA_VENTAS - (CDI_INVENTARIO_INICIAL_PESOS + CDI_COMPRAS_PESOS) / (CDI_INVENTARIO_INICIAL_USD + CDI_COMPRAS_USD)) * CDI_VENTAS_USD;
  END IF;

  -- VALOR COMISION
  CDI_COMISION := NVL(TOTAL_COMPRAS.ORD_TOTAL_COMISION,0)+NVL(TOTAL_VENTAS.ORD_TOTAL_COMISION,0);

  --VLR COMPENSADO UTIPER
  OPEN C_UTIPER_PARAME ('RC');
  FETCH C_UTIPER_PARAME INTO UTIPER_PARAME_RCA;
  CLOSE C_UTIPER_PARAME;

  OPEN C_UTIPER_PARAME ('OP');
  FETCH C_UTIPER_PARAME INTO UTIPER_PARAME_ODP;
  CLOSE C_UTIPER_PARAME;

  OPEN C_ODP_UTIPER (UTIPER_PARAME_ODP.PPC_PER_NUM_IDEN ,UTIPER_PARAME_ODP.PPC_PER_TID_CODIGO, UTIPER_PARAME_ODP.PPC_CBA_BAN_CODIGO, UTIPER_PARAME_ODP.PPC_CBA_NUMERO_CUENTA, UTIPER_PARAME_ODP.PPC_COT_MNEMONICO);
  FETCH C_ODP_UTIPER INTO ODP_UTIPER;
  CLOSE C_ODP_UTIPER;

  ODP_UTIPER := NVL(ODP_UTIPER,0);

  OPEN C_RCA_UTIPER (UTIPER_PARAME_RCA.PPC_PER_NUM_IDEN ,UTIPER_PARAME_RCA.PPC_PER_TID_CODIGO, UTIPER_PARAME_RCA.PPC_CBA_BAN_CODIGO, UTIPER_PARAME_RCA.PPC_CBA_NUMERO_CUENTA, UTIPER_PARAME_RCA.PPC_COT_MNEMONICO);
  FETCH C_RCA_UTIPER INTO RCA_UTIPER;
  CLOSE C_RCA_UTIPER;

  RCA_UTIPER := NVL(RCA_UTIPER,0);

  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'UTPE'         --UTILIDADES/PERDIDAS
        ,-CDI_UTILIDAD_OPERATIVA - CDI_COMISION + CDI_GASTOS + CDI_PERD_FOREX - CDI_UTIL_OTRAS
        ,-ODP_UTIPER + RCA_UTIPER
        ,0
        );

  SELECT CON_VALOR
    INTO V_IVA
  FROM CONSTANTES
  WHERE CON_MNEMONICO = 'IVD';--IVA DIVISAS

  --VLR COMPENSADO IVACOM
  OPEN C_IVACOM_PARAME ('RC');
  FETCH C_IVACOM_PARAME INTO IVACOM_PARAME_RCA;
  CLOSE C_IVACOM_PARAME;

  OPEN C_IVACOM_PARAME ('OP');
  FETCH C_IVACOM_PARAME INTO IVACOM_PARAME_ODP;
  CLOSE C_IVACOM_PARAME;

  OPEN C_ODP_IVACOM (IVACOM_PARAME_ODP.PPC_PER_NUM_IDEN ,IVACOM_PARAME_ODP.PPC_PER_TID_CODIGO, IVACOM_PARAME_ODP.PPC_CBA_BAN_CODIGO, IVACOM_PARAME_ODP.PPC_CBA_NUMERO_CUENTA, IVACOM_PARAME_ODP.PPC_COT_MNEMONICO);
  FETCH C_ODP_IVACOM INTO ODP_IVACOM;
  CLOSE C_ODP_IVACOM;

  ODP_IVACOM := NVL(ODP_IVACOM,0);

  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'IVACO'         --IVA COMISION
        ,-CDI_COMISION * V_IVA
        ,-ODP_IVACOM
        ,0
        );

  --VLR COMPENSADO NETODIVISAS
  OPEN C_NEDI_PARAME ('RC');
  FETCH C_NEDI_PARAME INTO NEDI_PARAME_RCA;
  CLOSE C_NEDI_PARAME;

  OPEN C_NEDI_PARAME ('OP');
  FETCH C_NEDI_PARAME INTO NEDI_PARAME_ODP;
  CLOSE C_NEDI_PARAME;

  OPEN C_ODP_NEDI (NEDI_PARAME_ODP.PPC_PER_NUM_IDEN ,NEDI_PARAME_ODP.PPC_PER_TID_CODIGO, NEDI_PARAME_ODP.PPC_CBA_BAN_CODIGO, NEDI_PARAME_ODP.PPC_CBA_NUMERO_CUENTA, NEDI_PARAME_ODP.PPC_COT_MNEMONICO);
  FETCH C_ODP_NEDI INTO ODP_NEDI;
  CLOSE C_ODP_NEDI;

  ODP_NEDI := NVL(ODP_NEDI,0);

  OPEN C_RCA_NEDI (NEDI_PARAME_RCA.PPC_PER_NUM_IDEN ,NEDI_PARAME_RCA.PPC_PER_TID_CODIGO, NEDI_PARAME_RCA.PPC_CBA_BAN_CODIGO, NEDI_PARAME_RCA.PPC_CBA_NUMERO_CUENTA, NEDI_PARAME_RCA.PPC_COT_MNEMONICO);
  FETCH C_RCA_NEDI INTO RCA_NEDI;
  CLOSE C_RCA_NEDI;

  RCA_NEDI := NVL(RCA_NEDI,0);

  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'NEDI'         --NETO DIVISAS -- INV FINAL COP - INV INICIAL COP
        ,CDI_INVENTARIO_FINAL_PESOS - CDI_INVENTARIO_INICIAL_PESOS
        ,-ODP_NEDI + RCA_NEDI
        ,0
        );

END COMPENSACION_DIVISAS_UTIL_PERD;

PROCEDURE COMPENSACION_DIVISAS_BANCOS (P_FECHA DATE) IS
  CURSOR C_ODP_BANCOS_CLIENTES_SINCOMP IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0)
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 2
    AND ODP_NPR_PRO_MNEMONICO = 'DIV'
    AND ODP_ESTADO            = 'APR'
    AND ODP_FECHA  >= TRUNC(P_FECHA)
    AND ODP_FECHA  < TRUNC(P_FECHA+1);

  CURSOR C_ODP_BANCOS_CLIENTES_COMP IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0)
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 2
    AND ODP_NPR_PRO_MNEMONICO = 'DIV'
    AND ODP_ESTADO            = 'APR'
    AND ODP_FECHA_EJECUCION  >= TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION  < TRUNC(P_FECHA+1)
    AND (ODP_TBC_CONSECUTIVO IS NOT NULL
      OR ODP_CEG_CONSECUTIVO IS NOT NULL
      OR ODP_CGE_CONSECUTIVO IS NOT NULL);

  CURSOR C_ODP_BANCOS_DIVISAS_SINCOMP IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0)
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 8
    AND ODP_NPR_PRO_MNEMONICO = 'DIV'
    AND ODP_ESTADO            = 'APR'
    AND ODP_FECHA  >= TRUNC(P_FECHA)
    AND ODP_FECHA   < TRUNC(P_FECHA) +1;

  CURSOR C_ODP_BANCOS_DIVISAS_COMP IS
    SELECT NVL(SUM(ODP_MONTO_ORDEN),0)
    FROM ORDENES_DE_PAGO
    WHERE ODP_NEG_CONSECUTIVO = 8
    AND ODP_NPR_PRO_MNEMONICO = 'DIV'
    AND ODP_ESTADO            = 'APR'
    AND ODP_FECHA_EJECUCION  >= TRUNC(P_FECHA)
    AND ODP_FECHA_EJECUCION  < TRUNC(P_FECHA+1)
    AND (ODP_TBC_CONSECUTIVO IS NOT NULL
      OR ODP_CEG_CONSECUTIVO IS NOT NULL
      OR ODP_CGE_CONSECUTIVO IS NOT NULL);

  CURSOR C_RCA_BANCOS_CLIENTES IS
    SELECT NVL(SUM(MONTO_ORDEN),0)
    FROM VW_DIVISAS_BANCOS
    WHERE TIPO_ORDEN = 'RCA'
      AND TIPO_COMPENSACION = 'CLI'
      AND FECHA >= TRUNC(P_FECHA)
      AND FECHA < TRUNC(P_FECHA+1);

  CURSOR C_RCA_BANCOS_DIVISAS IS
    SELECT NVL(SUM(MONTO_ORDEN),0)
    FROM VW_DIVISAS_BANCOS
    WHERE TIPO_ORDEN = 'RCA'
      AND TIPO_COMPENSACION = 'DIV'
      AND FECHA >= TRUNC(P_FECHA)
      AND FECHA < TRUNC(P_FECHA+1);

  CURSOR C_ORDENES_SIN_COMPLEMENTAR IS
    SELECT P_ADMON_SALDOS.FN_SALDOS_POR_MONETIZAR
    FROM DUAL;

  CURSOR C_SALDO_X_COMPLEMENTAR_HOY IS
    SELECT CDI_SALDO_ORDENES_SIN_PAGOS
    FROM CIERRE_DIVISAS
    WHERE CDI_FECHA_PROCESO >= TRUNC(P_FECHA)
      AND CDI_FECHA_PROCESO < TRUNC(P_FECHA+1);

  CURSOR C_SALDO_X_COMPLEMENTAR_ANT IS
    SELECT CDI_SALDO_ORDENES_SIN_PAGOS
    FROM CIERRE_DIVISAS
    WHERE CDI_FECHA_PROCESO >= TRUNC(P_TOOLS.RESTAR_HABILES_A_FECHA(P_FECHA,1))
      AND CDI_FECHA_PROCESO < TRUNC(P_TOOLS.RESTAR_HABILES_A_FECHA(P_FECHA,1)+1);

  ODP_BANCOS_CLIENTES_SINCOMP NUMBER;
  ODP_BANCOS_CLIENTES_COMP    NUMBER;
  ODP_BANCOS_DIVISAS_SINCOMP  NUMBER;
  ODP_BANCOS_DIVISAS_COMP     NUMBER;
  RCA_BANCOS_CLIENTES         NUMBER;
  RCA_BANCOS_DIVISAS          NUMBER;
  ORDENES_SIN_COMPLEMENTAR    NUMBER;
  SALDO_COMPLEM_HOY           NUMBER;
  SALDO_COMPLEM_ANT           NUMBER;
  SALDO_COMPLEM               NUMBER;

BEGIN

  OPEN C_ODP_BANCOS_CLIENTES_SINCOMP;
  FETCH C_ODP_BANCOS_CLIENTES_SINCOMP INTO ODP_BANCOS_CLIENTES_SINCOMP;
  CLOSE C_ODP_BANCOS_CLIENTES_SINCOMP;

  OPEN C_ODP_BANCOS_CLIENTES_COMP;
  FETCH C_ODP_BANCOS_CLIENTES_COMP INTO ODP_BANCOS_CLIENTES_COMP;
  CLOSE C_ODP_BANCOS_CLIENTES_COMP;

  OPEN C_ODP_BANCOS_DIVISAS_SINCOMP;
  FETCH C_ODP_BANCOS_DIVISAS_SINCOMP INTO ODP_BANCOS_DIVISAS_SINCOMP;
  CLOSE C_ODP_BANCOS_DIVISAS_SINCOMP;

  OPEN C_ODP_BANCOS_DIVISAS_COMP;
  FETCH C_ODP_BANCOS_DIVISAS_COMP INTO ODP_BANCOS_DIVISAS_COMP;
  CLOSE C_ODP_BANCOS_DIVISAS_COMP;

  OPEN C_RCA_BANCOS_CLIENTES;
  FETCH C_RCA_BANCOS_CLIENTES INTO RCA_BANCOS_CLIENTES;
  CLOSE C_RCA_BANCOS_CLIENTES;

  OPEN C_RCA_BANCOS_DIVISAS;
  FETCH C_RCA_BANCOS_DIVISAS INTO RCA_BANCOS_DIVISAS;
  CLOSE C_RCA_BANCOS_DIVISAS;

  IF TRUNC(P_FECHA) = TRUNC(SYSDATE) THEN
    OPEN C_ORDENES_SIN_COMPLEMENTAR;
    FETCH C_ORDENES_SIN_COMPLEMENTAR INTO  ORDENES_SIN_COMPLEMENTAR;
    CLOSE C_ORDENES_SIN_COMPLEMENTAR;

    SALDO_COMPLEM_HOY := NVL(ORDENES_SIN_COMPLEMENTAR,0);
  ELSE
    OPEN C_SALDO_X_COMPLEMENTAR_HOY;
    FETCH C_SALDO_X_COMPLEMENTAR_HOY INTO SALDO_COMPLEM_HOY;
    CLOSE C_SALDO_X_COMPLEMENTAR_HOY;
  END IF;

  OPEN C_SALDO_X_COMPLEMENTAR_ANT;
  FETCH C_SALDO_X_COMPLEMENTAR_ANT INTO SALDO_COMPLEM_ANT;
  CLOSE C_SALDO_X_COMPLEMENTAR_ANT;

  SALDO_COMPLEM := SALDO_COMPLEM_HOY - SALDO_COMPLEM_ANT;

  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'CBCO'
        ,RCA_BANCOS_CLIENTES - ODP_BANCOS_CLIENTES_SINCOMP - SALDO_COMPLEM
        ,RCA_BANCOS_CLIENTES - ODP_BANCOS_CLIENTES_COMP - SALDO_COMPLEM
        ,0
        );

  INSERT INTO GL_COMPENSACION_SEBRA(CS_FECHA
                                  ,CS_PRO_MNEMONICO
                                  ,CS_COMPENSACION
                                  ,CS_COMPENSADO
                                  ,CS_PENDIENTE)
  VALUES (P_FECHA
        ,'DBCO'
        ,RCA_BANCOS_DIVISAS - ODP_BANCOS_DIVISAS_SINCOMP
        ,RCA_BANCOS_DIVISAS - ODP_BANCOS_DIVISAS_COMP
        ,0
        );

END COMPENSACION_DIVISAS_BANCOS;

  PROCEDURE PAGOS_FLUJOS_DECEVAL IS

BEGIN
  -- BORRA LA TABLA GL
  DELETE FROM GL_ISIN_RDI;

  -- LLENA LA TABLA GL
	INSERT INTO GL_ISIN_RDI (GIR_ISI_MNEMONICO, GIR_FECHA_EXDIVIDENDO)
	SELECT DISTINCT FUG_ISI_MNEMONICO, RDI_FECHA_EX_DIVIDENDO
	FROM RELOJ_DIVIDENDOS,
	     FUNGIBLES
	WHERE RDI_ISI_MNEMONICO = FUG_ISI_MNEMONICO
	AND FUG_ESTADO = 'A'
	AND FUG_TIPO = 'ACC'
	AND RDI_FECHA_PAGO_FINAL > '01-JUL-2013'
  AND NOT EXISTS (SELECT 'X'
                FROM CUENTAS_FUNGIBLE_CLIENTE,
                     FLUJOS_DIVIDENDO_FUNGIBLE
                WHERE CFC_FUG_ISI_MNEMONICO = FDF_FUG_ISI_MNEMONICO
                  AND CFC_FUG_MNEMONICO = FDF_FUG_MNEMONICO
                  AND FDF_ESTADO != 'C'
                  AND CFC_FECHA_ULTIMO_ABONO_DIV = RDI_FECHA_PAGO_INICIAL
                  AND CFC_FUG_ISI_MNEMONICO = FUG_ISI_MNEMONICO
                  AND CFC_FUG_MNEMONICO = FUG_MNEMONICO);

END PAGOS_FLUJOS_DECEVAL;

PROCEDURE CALCULO_CONTRAPARTE_CV(P_ESPECIE IN VARCHAR2,
                                 P_FONDO   IN VARCHAR2,
                                 P_FECHA_EX_DIVIDENDO  IN DATE,
                                 P_FECHA_DESDE  IN DATE,
                                 P_FECHA_HASTA  IN DATE) IS

  V_SELECT VARCHAR2(8000);
  V_WHERE  VARCHAR2(8000);
  V_SECUENCIA NUMBER;
  V_CURSOR  P_OPERACIONES.O_CURSOR;
  IO_CURSOR P_OPERACIONES.O_CURSOR;
  V_CFC    GL_CALCULO_CONTRAPARTE%ROWTYPE;
  P_FECHA DATE := P_FECHA_EX_DIVIDENDO+1;
  P_FECHA_C DATE := P_FECHA_EX_DIVIDENDO-3;

BEGIN
  V_SELECT := NULL;
  -- inventario union ventas
  V_SELECT := ' SELECT DISTINCT RDI_ISI_MNEMONICO RDI_ISI_MNEMONICO '||
              '       ,VRV_ENA_MNEMONICO PRF_ENA_MNEMONICO '||
              '       ,''860079174'' PRV_CLI_PER_NUM_IDEN '||
              '       ,''NIT'' PRV_CLI_PER_TID_CODIGO '||
              '       ,''CORREDORES ASOCIADOS'' PER_NOMBRE '||
              '       ,0 '||
              '       ,VRV_NUMERO_UNIDADES CANT_ACCIONES '||
              '       ,''INV'' TIPO_MOVIMIENTO '||
		          ' FROM VALORIZACIONES_RV, RELOJ_DIVIDENDOS '||
		          ' WHERE RDI_ENA_MNEMONICO = VRV_ENA_MNEMONICO '||
              '   AND TRUNC(VRV_FECHA) = (SELECT TRUNC(MAX(B.VRV_FECHA)) '||
              '                      FROM VALORIZACIONES_RV B '||
              '                     WHERE B.VRV_ENA_MNEMONICO = VRV_ENA_MNEMONICO '||
              '                       AND B.VRV_FON_CODIGO = VRV_FON_CODIGO '||
              '                       AND B.VRV_FECHA >= TRUNC(RDI_FECHA_EX_DIVIDENDO) '||
              '                       AND B.VRV_FECHA < TRUNC(RDI_FECHA_EX_DIVIDENDO + 1) '||
		          '                       AND B.VRV_FON_CODIGO = '||CHR(39)||P_FONDO||CHR(39)||
		          '                       AND VRV_ENA_MNEMONICO = '||CHR(39)||P_ESPECIE||CHR(39)||')'||
		          ' AND VRV_FON_CODIGO = '||CHR(39)||P_FONDO||CHR(39)||
		          ' AND VRV_ENA_MNEMONICO = '||CHR(39)||P_ESPECIE||CHR(39)||
              ' AND VRV_FECHA >= TRUNC(RDI_FECHA_EX_DIVIDENDO) '||
              ' AND VRV_FECHA < TRUNC(RDI_FECHA_PAGO_INICIAL + 1) '||
              ' AND VRV_TMT_MNEMONICO = ''VAR'' '||
		          ' AND TRUNC(RDI_FECHA_EX_DIVIDENDO) >= '||CHR(39)||P_FECHA_EX_DIVIDENDO||CHR(39)||
		          ' AND TRUNC(RDI_FECHA_EX_DIVIDENDO) < '||CHR(39)||P_FECHA||CHR(39);

  V_CURSOR := NULL;
  V_CFC    := NULL;
  OPEN V_CURSOR FOR V_SELECT;
  LOOP
    FETCH V_CURSOR INTO V_CFC.CALCO_ISI_MNEMONICO,
                        V_CFC.CALCO_ENA_MNEMONICO,
                        V_CFC.CALCO_CLI_PER_NUM_IDEN,
                        V_CFC.CALCO_CLI_PER_TID_CODIGO,
                        V_CFC.CALCO_PER_NOMBRE,
                        V_CFC.CALCO_NOMINAL_COMPRAS,
                        V_CFC.CALCO_NOMINAL_VENTAS,
                        V_CFC.CALCO_TIPO_MOVIMIENTO;


    EXIT WHEN v_cursor%notfound;


    INSERT INTO GL_CALCULO_CONTRAPARTE
        (CALCO_ISI_MNEMONICO
        ,CALCO_ENA_MNEMONICO
        ,CALCO_CLI_PER_NUM_IDEN
        ,CALCO_CLI_PER_TID_CODIGO
        ,CALCO_PER_NOMBRE
        ,CALCO_NOMINAL_COMPRAS
        ,CALCO_NOMINAL_VENTAS
        ,CALCO_TIPO_MOVIMIENTO
        )
    VALUES
      ( V_CFC.CALCO_ISI_MNEMONICO,
        V_CFC.CALCO_ENA_MNEMONICO,
        V_CFC.CALCO_CLI_PER_NUM_IDEN,
        V_CFC.CALCO_CLI_PER_TID_CODIGO,
        V_CFC.CALCO_PER_NOMBRE,
        V_CFC.CALCO_NOMINAL_COMPRAS,
        V_CFC.CALCO_NOMINAL_VENTAS,
        V_CFC.CALCO_TIPO_MOVIMIENTO
       );
  END LOOP;
  CLOSE V_CURSOR;

  -- compras
  V_SELECT := 'SELECT RDI_ISI_MNEMONICO'||
              ' ,PRF_ENA_MNEMONICO '||
              ' ,PRC_CLI_PER_NUM_IDEN '||
              ' ,PRC_CLI_PER_TID_CODIGO'||
              ' ,PER_NOMBRE '||
              ' ,DECODE(TFO_TYPE,''TRF'',TFO_VALOR_NOMINAL,TFO_CANTIDAD) '||
              ' ,0 '||
              ' ,''CRV'' TIPO_MOVIMIENTO '||
              ' FROM FILTRO_PERSONAS '||
              ' ,RELOJ_DIVIDENDOS'||
              ' ,MVTOS_ACCION'||
              ' ,TITULOS_FONDOS'||
              ' ,PREORDENES_COMPRA'||
              ' ,PREORDENES_FONDOS'||
              ' WHERE PER_NUM_IDEN = PRC_CLI_PER_NUM_IDEN '||
              ' AND PER_TID_CODIGO = PRC_CLI_PER_TID_CODIGO '||
              ' AND RDI_ENA_MNEMONICO = TFO_ENA_MNEMONICO'||
              ' AND TRUNC(RDI_FECHA_EX_DIVIDENDO) != '||CHR(39)||P_FECHA_EX_DIVIDENDO||CHR(39)||
              ' AND TRUNC(RDI_FECHA_PAGO_INICIAL) = '||CHR(39)||P_FECHA_DESDE||CHR(39)||
              ' AND TRUNC(RDI_FECHA_PAGO_FINAL) = '||CHR(39)||P_FECHA_HASTA||CHR(39)||
              ' AND MAC_TFO_FON_CODIGO = TFO_FON_CODIGO '||
              ' AND MAC_TFO_CODIGO = TFO_CODIGO '||
              ' AND MAC_TMT_MNEMONICO IN (''CRV'')'||
              ' AND MAC_FECHA >= TO_DATE('||CHR(39)||P_FECHA_EX_DIVIDENDO||CHR(39)||',''DD-MM-YYYY'')-3' ||
              ' AND MAC_FECHA < TO_DATE('||CHR(39)||P_FECHA_EX_DIVIDENDO||CHR(39)||',''DD-MM-YYYY'')+1'||
              ' AND TFO_PRC_CONSECUTIVO = PRC_CONSECUTIVO'||
              ' AND TFO_PRC_PRF_CONSECUTIVO = PRC_PRF_CONSECUTIVO'||
              ' AND TFO_FON_CODIGO = PRC_PRF_FON_CODIGO'||
              ' AND PRC_PRF_CONSECUTIVO = PRF_CONSECUTIVO '||
              ' AND PRC_PRF_FON_CODIGO = PRF_FON_CODIGO  '||
              ' AND PRF_ENA_MNEMONICO ='||CHR(39)||P_ESPECIE||CHR(39)||
              ' AND PRF_FON_CODIGO = '||CHR(39)||P_FONDO||CHR(39);

  V_CURSOR := NULL;
  V_CFC    := NULL;
  OPEN V_CURSOR FOR V_SELECT;
  LOOP
    FETCH V_CURSOR INTO V_CFC.CALCO_ISI_MNEMONICO,
                        V_CFC.CALCO_ENA_MNEMONICO,
                        V_CFC.CALCO_CLI_PER_NUM_IDEN,
                        V_CFC.CALCO_CLI_PER_TID_CODIGO,
                        V_CFC.CALCO_PER_NOMBRE,
                        V_CFC.CALCO_NOMINAL_COMPRAS,
                        V_CFC.CALCO_NOMINAL_VENTAS,
                        V_CFC.CALCO_TIPO_MOVIMIENTO;


    EXIT WHEN v_cursor%notfound;


    INSERT INTO GL_CALCULO_CONTRAPARTE
        (CALCO_ISI_MNEMONICO
        ,CALCO_ENA_MNEMONICO
        ,CALCO_CLI_PER_NUM_IDEN
        ,CALCO_CLI_PER_TID_CODIGO
        ,CALCO_PER_NOMBRE
        ,CALCO_NOMINAL_COMPRAS
        ,CALCO_NOMINAL_VENTAS
        ,CALCO_TIPO_MOVIMIENTO
        )
    VALUES
      ( V_CFC.CALCO_ISI_MNEMONICO,
        V_CFC.CALCO_ENA_MNEMONICO,
        V_CFC.CALCO_CLI_PER_NUM_IDEN,
        V_CFC.CALCO_CLI_PER_TID_CODIGO,
        V_CFC.CALCO_PER_NOMBRE,
        V_CFC.CALCO_NOMINAL_COMPRAS,
        V_CFC.CALCO_NOMINAL_VENTAS,
        V_CFC.CALCO_TIPO_MOVIMIENTO
       );
  END LOOP;
  CLOSE V_CURSOR;

END CALCULO_CONTRAPARTE_CV;

PROCEDURE VISTA_CONTRAPARTES (P_ISIN IN VARCHAR2
                             ,P_ESPECIE IN VARCHAR2
                             ,P_ID_CONTRAPARTE IN VARCHAR2
                             ,P_TID_CONTRAPARTE IN VARCHAR2
                             ,P_TID_NOMBRE IN VARCHAR2
                             ,P_NOMINAL_COMPRAS IN NUMBER
                             ,P_NOMINAL_VENTAS IN NUMBER
                             ,P_FONDO IN VARCHAR2
                             ,P_FECHA IN DATE
                             ,P_TIPO_COBRO IN VARCHAR2
                             ,P_FDT_DIVIDENDO IN NUMBER
                             ,P_FECHA_EX_DIVIDENDO IN DATE
                             ,P_FECHA_DESDE  IN DATE
                             ,P_FECHA_HASTA  IN DATE
                             ,P_MONTO_NO_GRAV_ANT_2017 IN NUMBER
                             ,P_MONTO_NO_GRAV_POST_2017 IN NUMBER
                             ,P_MONTO_SI_GRAV_POST_2017 IN NUMBER                             
                             ) IS

  CURSOR C_ESPECIES IS
      SELECT  ENA_DEPOSITO_EXTRANJERO
      FROM ESPECIES_NACIONALES
      WHERE ENA_MNEMONICO = P_ESPECIE;
  C_ESP  C_ESPECIES%ROWTYPE;

  V_SECUENCIA   NUMBER;

BEGIN
    OPEN C_ESPECIES;
    FETCH C_ESPECIES INTO C_ESP;
    CLOSE C_ESPECIES;

    SELECT INCO_SEQ.NEXTVAL INTO V_SECUENCIA FROM DUAL;

    INSERT INTO INVENTARIO_CONTRAPARTE
            (INCO_CONSECUTIVO
            ,INCO_FON_CODIGO
            ,INCO_ISI_MNEMONICO
            ,INCO_ENA_MNEMONICO
            ,INCO_CLI_PER_NUM_IDEN
            ,INCO_CLI_PER_TID_CODIGO
            ,INCO_PER_NOMBRE
            ,INCO_NOMINAL_COMPRAS
            ,INCO_NOMINAL_VENTAS
            ,INCO_FECHA
            ,INCO_TIPO_COBRO
            ,INCO_FDT_DIVIDENDO
            ,INCO_FECHA_EX_DIVIDENDO
            ,INCO_FECHA_INICIAL_PAGO
            ,INCO_FECHA_FINAL_PAGO
            ,INCO_ENA_DEPOSITO_EXTRANJERO
            ,INCO_MONTO_NO_GRAV_ANT_2017
            ,INCO_MONTO_NO_GRAV_POST_2017
            ,INCO_MONTO_SI_GRAV_POST_2017
            )
    VALUES  (V_SECUENCIA
           ,P_FONDO
           ,P_ISIN
           ,P_ESPECIE
           ,P_ID_CONTRAPARTE
           ,P_TID_CONTRAPARTE
           ,P_TID_NOMBRE
           ,P_NOMINAL_COMPRAS
           ,P_NOMINAL_VENTAS
           ,SYSDATE
           ,P_TIPO_COBRO
           ,P_FDT_DIVIDENDO
           ,P_FECHA_EX_DIVIDENDO
           ,P_FECHA_DESDE
           ,P_FECHA_HASTA
           ,NVL(C_ESP.ENA_DEPOSITO_EXTRANJERO,'N')
           ,P_MONTO_NO_GRAV_ANT_2017
           ,P_MONTO_NO_GRAV_POST_2017
           ,P_MONTO_SI_GRAV_POST_2017                     
           );

  COMMIT;

END VISTA_CONTRAPARTES;		

PROCEDURE PR_TOTAL_CARGADO_GIRADO
   (P_LIC_NUMERO_OPERACION   IN NUMBER
   ,P_LIC_NUMERO_FRACCION    IN NUMBER
   ,P_LIC_TIPO_OPERACION     IN VARCHAR2
   ,P_LIC_BOL_MNEMONICO      IN VARCHAR2
   ,P_CCC_CLI_PER_NUM_IDEN   IN VARCHAR2
   ,P_CCC_CLI_PER_TID_CODIGO IN VARCHAR2
   ,P_CCC_NUMERO_CUENTA      IN NUMBER
   ,P_PAGADA                 IN OUT VARCHAR2
   ,P_NETO_GIRAR             IN OUT NUMBER
   ,P_TOTAL_GIRADO           IN OUT NUMBER) IS

   CURSOR C_NETO_LIQUIDACION IS
      SELECT /*+ INDEX (MCC MCC_LIC_FK_I) */
             SUM(MCC_MONTO_BURSATIL) NETO
      FROM   MOVIMIENTOS_CUENTA_CORREDORES MCC
      WHERE  MCC_TMC_MNEMONICO IN ('VEN','TRV','INV','RFV','COV','COPV','APOV','IVAV','AOBR','SEVA','SEVS')
			AND		 MCC_MCC_CONSECUTIVO IS NULL
      AND    MCC_LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
      AND    MCC_LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
      AND    MCC_LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
      AND    MCC_LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO
      AND    MCC_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
      AND    MCC_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
      AND    MCC_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA;

   CURSOR C_TOTAL_GIRADO IS
      SELECT /*+ INDEX (PAL PAL_LIC_FK_I) */ SUM(PAL_MONTO)
      FROM   PAGOS_LIQUIDACIONES
      WHERE  PAL_LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
      AND    PAL_LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
      AND    PAL_LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
      AND    PAL_LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO
      AND    NVL(PAL_ESTADO_ASOCIACION,' ') NOT IN ('ANU','CBE');

   CURSOR C_IMGF IS
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = 'IBA';
   CON1   C_IMGF%ROWTYPE;

   CURSOR C_PAGOS_LIQUIDACIONES IS
      SELECT PAL_MONTO
            ,ODP_MONTO_ORDEN
            ,ODP_MONTO_IMGF
            ,DAA_VALOR
            ,DAA_VALOR_IMGF
      FROM   PAGOS_LIQUIDACIONES
            ,ORDENES_DE_PAGO
            ,DETALLES_ABONOS_CUENTAS
      WHERE  PAL_LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO
      AND    PAL_LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
      AND    PAL_LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
      AND    PAL_LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
      AND    PAL_ODP_CONSECUTIVO = ODP_CONSECUTIVO (+)
      AND    PAL_ODP_SUC_CODIGO = ODP_SUC_CODIGO (+)
      AND    PAL_ODP_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO (+)
      AND    PAL_DAA_CONSECUTIVO = DAA_CONSECUTIVO (+)
      AND    PAL_DAA_SUC_CODIGO = DAA_SUC_CODIGO (+)
      AND    PAL_DAA_NEG_CONSECUTIVO = DAA_NEG_CONSECUTIVO (+)
      AND    NVL(PAL_ESTADO_ASOCIACION,' ') NOT IN ('ANU','CBE')
      ORDER BY ODP_MONTO_IMGF, DAA_VALOR_IMGF;
   PAL1   C_PAGOS_LIQUIDACIONES%ROWTYPE;

   TOTAL_PAGOS NUMBER;
   TOTAL_IMGF  NUMBER;
BEGIN
   OPEN C_IMGF;
   FETCH C_IMGF INTO CON1;
   IF C_IMGF%NOTFOUND THEN
      CLOSE C_IMGF;
      RAISE_APPLICATION_ERROR(-20003,'No se pudo determinar el valor de la constante del GMF (IBA)');
   END IF;
   CLOSE C_IMGF;

   OPEN C_NETO_LIQUIDACION;
   FETCH C_NETO_LIQUIDACION INTO P_NETO_GIRAR;
   CLOSE C_NETO_LIQUIDACION;

   OPEN C_TOTAL_GIRADO;
   FETCH C_TOTAL_GIRADO INTO P_TOTAL_GIRADO;
   CLOSE C_TOTAL_GIRADO;

   P_NETO_GIRAR := NVL(P_NETO_GIRAR,0);
   P_TOTAL_GIRADO := NVL(P_TOTAL_GIRADO,0);

   IF P_NETO_GIRAR = P_TOTAL_GIRADO THEN
      P_PAGADA := 'S';
   ELSIF P_NETO_GIRAR > P_TOTAL_GIRADO THEN
      P_PAGADA := 'N';
   ELSIF P_NETO_GIRAR < P_TOTAL_GIRADO THEN
   	  P_PAGADA := 'S';
      INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
         (MCC_CONSECUTIVO
         ,MCC_CCC_CLI_PER_NUM_IDEN
         ,MCC_CCC_CLI_PER_TID_CODIGO
         ,MCC_CCC_NUMERO_CUENTA
         ,MCC_FECHA
         ,MCC_TMC_MNEMONICO
         ,MCC_MONTO
         ,MCC_MONTO_BURSATIL
         ,MCC_MONTO_A_PLAZO
         ,MCC_LIC_BOL_MNEMONICO
         ,MCC_LIC_NUMERO_OPERACION
         ,MCC_LIC_NUMERO_FRACCION
         ,MCC_LIC_TIPO_OPERACION
         ,MCC_CAUSADO_CONT_O_PLAZO)
      VALUES
         (MCC_SEQ.NEXTVAL
         ,P_CCC_CLI_PER_NUM_IDEN
         ,P_CCC_CLI_PER_TID_CODIGO
         ,P_CCC_NUMERO_CUENTA
         ,SYSDATE
         ,'AOBR'
         ,-(P_TOTAL_GIRADO - P_NETO_GIRAR)
         ,P_TOTAL_GIRADO - P_NETO_GIRAR
         ,0
         ,P_LIC_BOL_MNEMONICO
         ,P_LIC_NUMERO_OPERACION
         ,P_LIC_NUMERO_FRACCION
         ,P_LIC_TIPO_OPERACION
         ,'S');

      TOTAL_PAGOS := P_TOTAL_GIRADO - P_NETO_GIRAR;
      OPEN C_PAGOS_LIQUIDACIONES;
      FETCH C_PAGOS_LIQUIDACIONES INTO PAL1;
      WHILE C_PAGOS_LIQUIDACIONES%FOUND LOOP
         IF PAL1.PAL_MONTO >= TOTAL_PAGOS THEN
            IF PAL1.ODP_MONTO_ORDEN IS NOT NULL THEN
               TOTAL_IMGF := TOTAL_IMGF + TOTAL_PAGOS * CON1.CON_VALOR;
            END IF;
            EXIT;
         ELSE
            IF PAL1.ODP_MONTO_ORDEN IS NOT NULL THEN
               TOTAL_IMGF := TOTAL_IMGF + PAL1.PAL_MONTO * CON1.CON_VALOR;
            END IF;
            TOTAL_PAGOS := TOTAL_PAGOS - PAL1.PAL_MONTO;
         END IF;
         FETCH C_PAGOS_LIQUIDACIONES INTO PAL1;
      END LOOP;
      CLOSE C_PAGOS_LIQUIDACIONES;

      IF TOTAL_IMGF != 0 THEN
         INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
            (MCC_CONSECUTIVO
            ,MCC_CCC_CLI_PER_NUM_IDEN
            ,MCC_CCC_CLI_PER_TID_CODIGO
            ,MCC_CCC_NUMERO_CUENTA
            ,MCC_FECHA
            ,MCC_TMC_MNEMONICO
            ,MCC_MONTO
            ,MCC_MONTO_BURSATIL
            ,MCC_MONTO_A_PLAZO
            ,MCC_LIC_BOL_MNEMONICO
            ,MCC_LIC_NUMERO_OPERACION
            ,MCC_LIC_NUMERO_FRACCION
            ,MCC_LIC_TIPO_OPERACION
            ,MCC_CAUSADO_CONT_O_PLAZO)
         VALUES
            (MCC_SEQ.NEXTVAL
            ,P_CCC_CLI_PER_NUM_IDEN
            ,P_CCC_CLI_PER_TID_CODIGO
            ,P_CCC_NUMERO_CUENTA
            ,SYSDATE
            ,'IBC'
            ,-TOTAL_IMGF
            ,0
            ,0
            ,P_LIC_BOL_MNEMONICO
            ,P_LIC_NUMERO_OPERACION
            ,P_LIC_NUMERO_FRACCION
            ,P_LIC_TIPO_OPERACION
            ,'S');
      END IF;
   END IF;
END PR_TOTAL_CARGADO_GIRADO;


/*******************************************************************************************
***  Funcion calculo de comisiones unidad de fondos UDF  **
***************************************************************************************** */
FUNCTION FN_CALCULA_COMISION_UDF( TIPO VARCHAR2,
                                  ENA VARCHAR2,
                                  UNI_O_MON NUMBER
)
RETURN NUMBER
IS

 VALOR NUMBER(20);
 MONTO NUMBER(20);
 V_FIJA NUMBER(20);
 V_CUDF NUMBER(20,4);

CURSOR C_RANGO(UDF_RANGO NUMBER) IS
 SELECT UDF_RANGO_INICIAL,
        UDF_RANGO_FINAL,
        NVL(UDF_COMISION_FIJA,
        (UDF_COMISION_POR))COMISION
 FROM COMISIONES_UDF
 ORDER BY UDF_RANGO_INICIAL;

 VI NUMBER (20);
 VF NUMBER (20);
 VC NUMBER (20,4);
 COMISION NUMBER (20,4);
 --UDF_RANGO NUMBER (20) := MONTO;

BEGIN

  IF TIPO = 'N' THEN

    SELECT
      ROUND(PEB_PRECIO_BOLSA) INTO VALOR
    FROM PRECIOS_ESPECIES_BOLSA A,
        (SELECT MAX (PEB_FECHA) PEB_FECHA
         FROM PRECIOS_ESPECIES_BOLSA
         WHERE PEB_ENA_MNEMONICO = ENA )FECHA
    WHERE A.PEB_ENA_MNEMONICO = ENA
    AND   A.PEB_FECHA = FECHA.PEB_FECHA;

    MONTO := (UNI_O_MON * VALOR);
ELSE
    MONTO := UNI_O_MON ;
END IF;

---CALCULO DE COMISION

SELECT DISTINCT (UDF_COMISION_FIJA)
  INTO V_FIJA
FROM COMISIONES_UDF
WHERE UDF_COMISION_FIJA IS NOT NULL;

SELECT NVL(CON_VALOR,0)
INTO V_CUDF FROM CONSTANTES
WHERE CON_MNEMONICO = 'CUF';

OPEN C_RANGO(MONTO);
   LOOP
   FETCH C_RANGO
   INTO  VI
        ,VF
        ,VC;

    IF MONTO BETWEEN VI AND VF THEN
      IF V_FIJA = VC THEN
         COMISION := (VC*100)/MONTO  ;
      ELSE
         COMISION :=VC;
      END IF;
        ELSE
        	 NULL;
        END IF;
  EXIT WHEN C_RANGO%notfound;
  END LOOP;

  CLOSE C_RANGO;

  IF COMISION IS NULL THEN
   COMISION :=V_CUDF;
  END IF;

RETURN (COMISION);
END FN_CALCULA_COMISION_UDF;

/*******************************************************************************************
***  Funcion que calcula el valor de la operacion para validar el valor maximo de operacion UdF - smorales
***************************************************************************************** */

FUNCTION FN_CALCULA_MONTO_UDF( P_TIPO VARCHAR2,
                                  P_ENA VARCHAR2,
                                  P_UNI_O_MON NUMBER
)
RETURN NUMBER
IS

 V_VALOR NUMBER(20);
 V_MONTO NUMBER(20);


BEGIN

IF P_TIPO = 'N' THEN

    SELECT ROUND(PEB_PRECIO_BOLSA)
    INTO V_VALOR
    FROM PRECIOS_ESPECIES_BOLSA A,
        (SELECT MAX (PEB_FECHA) PEB_FECHA
         FROM PRECIOS_ESPECIES_BOLSA
         WHERE PEB_ENA_MNEMONICO = P_ENA
        )FECHA
    WHERE A.PEB_ENA_MNEMONICO = P_ENA
    AND   A.PEB_FECHA = FECHA.PEB_FECHA;

    V_MONTO := NVL((P_UNI_O_MON * V_VALOR),0);
ELSE
    V_MONTO := NVL(P_UNI_O_MON,0) ;


END IF;
RETURN (V_MONTO);

EXCEPTION
WHEN NO_DATA_FOUND THEN
NULL;

END FN_CALCULA_MONTO_UDF;

PROCEDURE PR_CONTROL_CONVENIOS (P_FECHA IN DATE) IS
   CURSOR C_CONV IS
      SELECT CONV_CONSECUTIVO,
             CONV_CFO_CCC_CLI_PER_NUM_IDEN,
             CONV_CFO_CCC_CLI_PER_TID_COD,
             CONV_CFO_CCC_NUMERO_CUENTA,
             CONV_DIA_CORTE,
             NVL(CONV_RECIPROCIDAD_PROM_DIA_M,0) CONV_RECIPROCIDAD_PROM_DIA_M,
             NVL(CONV_PORCENTAJE_EXENCION,0) CONV_PORCENTAJE_EXENCION,
             NVL(CONV_COMISION_CONVENIO,0) CONV_COMISION_CONVENIO
      FROM CONVENIOS
      WHERE CONV_ESTADO = 'A'
        AND CONV_TIPO_CONVENIO IN ('REC','RYP')
      ORDER BY CONV_CONSECUTIVO;
   R_CONV C_CONV%ROWTYPE;

   CURSOR C_SAD_PROMEDIO (P_CCC_CLI_PER_NUM_IDEN   VARCHAR,
                          P_CCC_CLI_PER_TID_CODIGO VARCHAR2,
                          P_CCC_NUMERO_CUENTA NUMBER,
                          P_FECHA1            DATE,
                          P_FECHA2            DATE) IS
      SELECT NVL(SUM(FON.SALDO),0) SALDO
      FROM (SELECT TRUNC(SAD_FECHA), NVL(SUM(SAD_SALDO),0) SALDO
            FROM SALDOS_DIARIOS
            WHERE SAD_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
              AND SAD_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
              AND SAD_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
              AND SAD_FECHA >= TRUNC(P_FECHA1)
              AND SAD_FECHA < TRUNC(P_FECHA2 + 1)
              AND SAD_PRO_MNEMONICO = 'FINT'
              AND EXISTS (SELECT 'X'
                          FROM FONDOS
                          WHERE FON_NPR_PRO_MNEMONICO = SAD_PRO_MNEMONICO
                            AND  FON_TIPO = 'A'
                            AND FON_ESTADO              = 'A'
                            AND FON_TIPO_ADMINISTRACION = 'F'
                            AND FON_CAPITAL_PRIVADO     = 'N'
                            AND FON_NOMBRE_CORTO  IS NOT NULL)
      GROUP BY TRUNC(SAD_FECHA)) FON;

   SALDO_FIC_PROMEDIO NUMBER;
   DIAS_PROMEDIO NUMBER;
   CURSOR C_SAD    (P_CCC_CLI_PER_NUM_IDEN   VARCHAR,
                    P_CCC_CLI_PER_TID_CODIGO VARCHAR2,
                    P_CCC_NUMERO_CUENTA NUMBER,
                    P_FECHA1            DATE) IS
      SELECT NVL(SUM(SAD_SALDO),0) SALDO
      FROM SALDOS_DIARIOS
      WHERE SAD_CCC_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
        AND SAD_CCC_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
        AND SAD_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
        AND SAD_FECHA >= TRUNC(P_FECHA1)
        AND SAD_FECHA < TRUNC(P_FECHA1 + 1)
        AND SAD_PRO_MNEMONICO = 'FINT'
        AND EXISTS (SELECT 'X'
                    FROM FONDOS
                    WHERE FON_NPR_PRO_MNEMONICO = SAD_PRO_MNEMONICO
                     AND  FON_TIPO = 'A'
                     AND FON_ESTADO              = 'A'
                     AND FON_TIPO_ADMINISTRACION = 'F'
                     AND FON_CAPITAL_PRIVADO     = 'N'
                     AND FON_NOMBRE_CORTO  IS NOT NULL);
   SALDO_FIC NUMBER;

   CURSOR C_PAGREC (P_CONV NUMBER) IS
      SELECT CONVENIO, SUM(COS.PAG) PAGOS, SUM(COS.REC) RECAUDOS
      FROM ( SELECT BAPC_CONV_CONSECUTIVO CONVENIO, BAPC_OPERACIONES PAG, 0 REC
             FROM BANCOS_PROMEDIOS_CONVENIOS
             WHERE BAPC_APLICA = 'S'
               AND BAPC_TPBC_TIPO_PROMEDIO = 'PAG'
               AND BAPC_CONV_CONSECUTIVO = P_CONV
             UNION  ALL
             SELECT BAPC_CONV_CONSECUTIVO CONVENIO, 0 PAG, BAPC_OPERACIONES REC
             FROM BANCOS_PROMEDIOS_CONVENIOS
             WHERE BAPC_APLICA = 'S'
               AND BAPC_TPBC_TIPO_PROMEDIO = 'REC'
               AND BAPC_CONV_CONSECUTIVO = P_CONV)  COS
      GROUP BY CONVENIO;
   R_PAGREC C_PAGREC%ROWTYPE;

   CURSOR C_COSTOS (P_CONV NUMBER) IS
      SELECT VCBT_CONV_CONSECUTIVO,
            SUM(VCBT_TOTAL_PAGOS) PAGOS,
            SUM(VCBT_PAGOS_PREFERENCIAL) PAGOS_PREFERENCIAL,
            SUM(VCBT_TOTAL_RECAUDOS) RECAUDOS,
            SUM(VCBT_RECAUDOS_PREFERENCIAL) RECAUDOS_PREFERENCIAL,
            SUM(VCBT_PAGOS_PLENA) PAGOS_PLENA,
            SUM(VCBT_RECAUDOS_PLENA) RECAUDOS_PLENA
      FROM VW_BANCOS_CONVENIOS_TOTAL
      WHERE VCBT_CONV_CONSECUTIVO = P_CONV
      GROUP BY VCBT_CONV_CONSECUTIVO;
   R_COSTOS C_COSTOS%ROWTYPE;

   PORC_CUMPLIMIENTO NUMBER := 0;
   P_PAGOS NUMBER := 0;
   P_PAGOS_ACT NUMBER := 0;
   PORC_PAGOS NUMBER := 0;
   P_PAGOS_PREFERENCIAL_ACT NUMBER := 0;
   P_RECAUDOS NUMBER := 0;
   P_RECAUDOS_ACT NUMBER := 0;
   PORC_RECAUDOS NUMBER := 0;
   P_RECAUDOS_PREFERENCIAL_ACT NUMBER := 0;
   COMISION_MES_COMERCIAL NUMBER := 0;
   COSTO_ASUMIDO_CONVENIO NUMBER := 0;
   COSTO_ASUMIDO_COMERCIAL NUMBER := 0;
   VALOR_NETO_REAL NUMBER := 0;
   COMISION_REAL NUMBER := 0;
   VALOR_CLIENTE NUMBER := 0;
   P_PAGOS_PLENA  NUMBER  :=0;
   P_RECAUDOS_PLENA NUMBER := 0;


   FECHA_INICIO DATE;
   FECHA_FIN    DATE;
   FECHA_C      DATE;
BEGIN
   DELETE FROM CONTROL_COMERCIAL_CONVENIOS
   WHERE CCCV_FECHA_CORTE >= TRUNC(P_FECHA)
     AND CCCV_FECHA_CORTE <  TRUNC(P_FECHA + 1);

   OPEN C_CONV;
   FETCH C_CONV INTO R_CONV;
   WHILE C_CONV%FOUND LOOP
      DELETE FROM GL_FECHAS;
      DIAS_PROMEDIO := 0;
      SALDO_FIC_PROMEDIO := 0;
      SALDO_FIC := 0;
      PORC_CUMPLIMIENTO := 0;
      P_PAGOS  := 0;
      P_PAGOS_ACT  := 0;
      PORC_PAGOS  := 0;
      P_PAGOS_PREFERENCIAL_ACT  := 0;
      P_RECAUDOS  := 0;
      P_RECAUDOS_ACT  := 0;
      PORC_RECAUDOS  := 0;
      P_RECAUDOS_PREFERENCIAL_ACT := 0;
      COMISION_MES_COMERCIAL  := 0;
      COSTO_ASUMIDO_CONVENIO  := 0;
      COSTO_ASUMIDO_COMERCIAL  := 0;
      VALOR_NETO_REAL  := 0;
      COMISION_REAL  := 0;
      VALOR_CLIENTE  := 0;

      --Edicion JJOA AGO52016 Promedios RCOCON

      IF R_CONV.CONV_DIA_CORTE IN (29,30,31) THEN
         FECHA_C := LAST_DAY(P_FECHA);
      ELSE
        FECHA_C := R_CONV.CONV_DIA_CORTE||'-'||TO_CHAR(P_FECHA,'MON-YYYY');
      END IF;

      IF TRUNC(FECHA_C) >= TRUNC(P_FECHA) THEN
         FECHA_INICIO := TRUNC(ADD_MONTHS(FECHA_C,-1))+1;
         FECHA_FIN := TRUNC(P_FECHA);
      ELSE
         FECHA_INICIO := TRUNC(FECHA_C)+1;
         FECHA_FIN := TRUNC(P_FECHA);
      END IF;


      -- SALDO_PROMEDIO

      DIAS_PROMEDIO := (TRUNC(FECHA_FIN) - TRUNC(FECHA_INICIO))+1;

      IF DIAS_PROMEDIO <= 0 THEN
         DIAS_PROMEDIO := 0;
      END IF;

      OPEN C_SAD_PROMEDIO (R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN ,
                           R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD,
                           R_CONV.CONV_CFO_CCC_NUMERO_CUENTA,
                           FECHA_INICIO,
                           FECHA_FIN );
      FETCH C_SAD_PROMEDIO INTO SALDO_FIC_PROMEDIO;
      IF C_SAD_PROMEDIO%FOUND THEN
         SALDO_FIC_PROMEDIO := NVL(SALDO_FIC_PROMEDIO,0);
      ELSE
         SALDO_FIC_PROMEDIO := 0;
      END IF;
      CLOSE C_SAD_PROMEDIO;

      IF DIAS_PROMEDIO!= 0 THEN
         SALDO_FIC_PROMEDIO := SALDO_FIC_PROMEDIO/DIAS_PROMEDIO;
      END IF;


      -- SALDO DE INVERSION
      OPEN C_SAD (R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN ,
                  R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD,
                  R_CONV.CONV_CFO_CCC_NUMERO_CUENTA,
                  FECHA_FIN );
      FETCH C_SAD INTO SALDO_FIC;
      IF C_SAD%FOUND THEN
         SALDO_FIC := NVL(SALDO_FIC,0);
      ELSE
         SALDO_FIC := 0;
      END IF;
      CLOSE C_SAD;

      -- PAGOS Y RECUADOS DEL CONVENIO
      OPEN C_PAGREC (R_CONV.CONV_CONSECUTIVO);
      FETCH C_PAGREC INTO R_PAGREC;
      IF C_PAGREC%FOUND THEN
         P_PAGOS := R_PAGREC.PAGOS;
         P_RECAUDOS := R_PAGREC.RECAUDOS;
      ELSE
         P_PAGOS := 0;
         P_RECAUDOS := 0;
      END IF;
      CLOSE C_PAGREC;
      P_PAGOS := NVL(P_PAGOS,0);
      P_RECAUDOS := NVL(P_RECAUDOS,0);


      -- PAGOS Y RECAUDOS DEL MES ACTUAL
      INSERT INTO GL_FECHAS VALUES (FECHA_INICIO, FECHA_FIN);

      OPEN C_COSTOS (R_CONV.CONV_CONSECUTIVO);
      FETCH C_COSTOS INTO R_COSTOS;
      IF C_COSTOS%FOUND THEN
         P_PAGOS_ACT := NVL(R_COSTOS.PAGOS,0);
         P_PAGOS_PREFERENCIAL_ACT := NVL(R_COSTOS.PAGOS_PREFERENCIAL,0);
         P_RECAUDOS_ACT := NVL(R_COSTOS.RECAUDOS,0);
         P_RECAUDOS_PREFERENCIAL_ACT := NVL(R_COSTOS.RECAUDOS_PREFERENCIAL,0);
         P_PAGOS_PLENA := NVL(R_COSTOS.PAGOS_PLENA,0);
         P_RECAUDOS_PLENA := NVL(R_COSTOS.RECAUDOS_PLENA,0);
      ELSE
         P_PAGOS_ACT := 0;
         P_PAGOS_PREFERENCIAL_ACT := 0;
         P_RECAUDOS_ACT := 0;
         P_RECAUDOS_PREFERENCIAL_ACT := 0;
         P_PAGOS_PLENA := 0;
         P_RECAUDOS_PLENA := 0;
      END IF;
      CLOSE C_COSTOS;
      P_PAGOS_ACT := NVL(P_PAGOS_ACT,0);
      P_PAGOS_PREFERENCIAL_ACT := NVL(P_PAGOS_PREFERENCIAL_ACT,0);
      P_RECAUDOS_ACT := NVL(P_RECAUDOS_ACT,0);
      P_RECAUDOS_PREFERENCIAL_ACT := NVL(P_RECAUDOS_PREFERENCIAL_ACT,0);

      IF  P_PAGOS != 0 THEN
         PORC_PAGOS := ROUND(P_PAGOS_ACT/P_PAGOS*100);
      END IF;
      IF  P_RECAUDOS != 0 THEN
         PORC_RECAUDOS := ROUND(P_RECAUDOS_ACT / P_RECAUDOS * 100);
      END IF;


      IF  NVL(R_CONV.CONV_RECIPROCIDAD_PROM_DIA_M,0) != 0 THEN
         PORC_CUMPLIMIENTO := ROUND((SALDO_FIC_PROMEDIO/NVL(R_CONV.CONV_RECIPROCIDAD_PROM_DIA_M,0) * 100),2);
      END IF;

      COMISION_MES_COMERCIAL := NVL(R_CONV.CONV_COMISION_CONVENIO,0);
      COMISION_MES_COMERCIAL := NVL(COMISION_MES_COMERCIAL,0);
      COMISION_MES_COMERCIAL := ((SALDO_FIC_PROMEDIO*(COMISION_MES_COMERCIAL/100))/360)*DIAS_PROMEDIO;

      COSTO_ASUMIDO_CONVENIO := (P_PAGOS_PREFERENCIAL_ACT +  P_RECAUDOS_PREFERENCIAL_ACT)* (R_CONV.CONV_PORCENTAJE_EXENCION/100);
      COSTO_ASUMIDO_COMERCIAL := (P_PAGOS_PREFERENCIAL_ACT +  P_RECAUDOS_PREFERENCIAL_ACT) - COSTO_ASUMIDO_CONVENIO;
      VALOR_NETO_REAL := NVL(COMISION_MES_COMERCIAL,0) - NVL(COSTO_ASUMIDO_COMERCIAL,0);
      IF DIAS_PROMEDIO != 0 AND SALDO_FIC_PROMEDIO != 0 THEN
         COMISION_REAL := ((VALOR_NETO_REAL*360/DIAS_PROMEDIO)/SALDO_FIC_PROMEDIO)*100;
      ELSE
         COMISION_REAL := 0;
      END IF;

      VALOR_CLIENTE := NVL(COSTO_ASUMIDO_CONVENIO,0) +  NVL(P_PAGOS_PLENA,0) + NVL(P_PAGOS_PLENA,0);

      INSERT INTO CONTROL_COMERCIAL_CONVENIOS
             ( CCCV_FECHA_CORTE ,
               CCCV_CONV_CONSECUTIVO,
               CCCV_CCC_CLI_PER_NUM_IDEN,
               CCCV_CCC_CLI_PER_TID_CODIGO,
               CCCV_CCC_NUMERO_CUENTA,
               CCCV_DIA_CORTE,
               CCCV_RECIPROCIDAD,
               CCCV_CONV_PORCENTAJE_EXENCION,
               CCCV_SALDO_PROMEDIO,
               CCCV_PORCENTAJE_CUMPLIMIENTO,
               CCCV_SALDO_INVERSION_DIA,
               CCCV_PAGOS_CONVENIO_MES,
               CCCV_PAGOS_MES_ACTUAL,
               CCCV_PORCENTAJE_PAGOS,
               CCCV_COSTO_CONVENIO_PAGOS,
               CCCV_RECAUDOS_CONVENIO_MES,
               CCCV_RECAUDOS_MES_ACTUAL,
               CCCV_PORCENTAJE_USO_RECAUDOS,
               CCCV_COSTO_CONVENIO_RECAUDOS,
               CCCV_COMISION_MES_COMERCIAL,
               CCCV_COSTO_ASUMIDO_CONVENIO,
               CCCV_COSTO_ASUMIDO_COMERCIAL,
               CCCV_VALOR_NETO_REAL,
               CCCV_COMISION_REAL,
               CCCV_VALOR_CLIENTE,
               CCCV_FECHA_INICIAL_CALCULO,
               CCCV_FECHA_FINAL_CALCULO)
      VALUES ( TRUNC(P_FECHA),
               R_CONV.CONV_CONSECUTIVO,
               R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN,
               R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD,
               R_CONV.CONV_CFO_CCC_NUMERO_CUENTA,
               R_CONV.CONV_DIA_CORTE,
               R_CONV.CONV_RECIPROCIDAD_PROM_DIA_M,
               R_CONV.CONV_PORCENTAJE_EXENCION,
               SALDO_FIC_PROMEDIO,
               PORC_CUMPLIMIENTO,
               SALDO_FIC,
               P_PAGOS,
               P_PAGOS_ACT,
               PORC_PAGOS,
               P_PAGOS_PREFERENCIAL_ACT,
               P_RECAUDOS,
               P_RECAUDOS_ACT,
               PORC_RECAUDOS,
               P_RECAUDOS_PREFERENCIAL_ACT,
               COMISION_MES_COMERCIAL,
               COSTO_ASUMIDO_CONVENIO,
               COSTO_ASUMIDO_COMERCIAL,
               VALOR_NETO_REAL,
               COMISION_REAL,
               VALOR_CLIENTE,
               FECHA_INICIO,
               FECHA_FIN);

      FETCH C_CONV INTO R_CONV;
   END LOOP;
   CLOSE C_CONV;
   COMMIT;
END PR_CONTROL_CONVENIOS;


PROCEDURE PR_FACTURACION_CONVENIOS (P_FECHA   IN DATE) IS

   FECHA          DATE;

   CURSOR C_GENERADO IS
      SELECT 'S'
      FROM FACTURAS_CODIGOS_BARRAS
      WHERE FACB_FECHA >= TRUNC(SYSDATE)
        AND FACB_FECHA < TRUNC(SYSDATE+1);
   SINO_PROCESO VARCHAR2(1);

   CURSOR C_CONVENIO IS
      SELECT  CONV_CONSECUTIVO
              ,CONV_CFO_CCC_CLI_PER_NUM_IDEN
              ,CONV_CFO_CCC_CLI_PER_TID_COD
              ,CONV_CFO_CCC_NUMERO_CUENTA
              ,CONV_CFO_FON_CODIGO
              ,CONV_CFO_CODIGO
              ,CCC_NOMBRE_CUENTA
              ,CONV_PERIODICIDAD_COBRO
              ,CONV_DIA_CORTE
              ,CONV_RADICADO
      FROM CONVENIOS,
           CUENTAS_CLIENTE_CORREDORES
      WHERE CONV_CFO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
        AND CONV_CFO_CCC_CLI_PER_TID_COD = CCC_CLI_PER_TID_CODIGO
        AND CONV_CFO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
        AND CONV_TIPO_CONVENIO IN ('TAP','RYP')
        AND CONV_ESTADO = 'A'
        AND (CONV_PERIODICIDAD_COBRO = 'D'
             OR CONV_PERIODICIDAD_COBRO = 'M' AND CONV_DIA_CORTE = TO_CHAR(P_FECHA,'DD'));
   R_CONV C_CONVENIO%ROWTYPE;

   CURSOR C_VALOR (P_CONV NUMBER) IS
      SELECT CCCV_VALOR_CLIENTE
      FROM CONTROL_COMERCIAL_CONVENIOS
      WHERE CCCV_CONV_CONSECUTIVO = P_CONV
        AND CCCV_FECHA_CORTE = TRUNC(P_FECHA);
   TOTAL_SERVICIO NUMBER;

   CURSOR C_CONSTANTE(P_MNEMONICO VARCHAR2) IS
      SELECT CON_VALOR
      FROM   CONSTANTES
      WHERE  CON_MNEMONICO = P_MNEMONICO;
   CON1   C_CONSTANTE%ROWTYPE;


   CURSOR C_RANGO_FACTURACION IS
      SELECT NFCB_NUMERO
            ,NFCB_FECHA_EXPEDICION
            ,NFCB_NUMERO_INICIAL
            ,NFCB_NUMERO_FINAL
            ,NVL(NFCB_NUMERO_ACTUAL,0)+1 NFCB_NUMERO_ACTUAL
            ,NFCB_ESTADO
      FROM   NUMEROS_FACTURAS_COD_BARRAS
      WHERE  NFCB_ESTADO = 'A'
      AND ROWNUM = 1
      ORDER BY NFCB_NUMERO ASC;
   RAD1   C_RANGO_FACTURACION%ROWTYPE;

   CURSOR C_PER (P_NUM_IDEN VARCHAR2,
                 P_TID_CODIGO VARCHAR2,
                 P_CUENTA NUMBER)   IS
      SELECT PER_SUC_CODIGO,
             PER_NUM_IDEN,
             PER_TID_CODIGO
      FROM CUENTAS_CLIENTE_CORREDORES,
           PERSONAS
      WHERE CCC_PER_NUM_IDEN = PER_NUM_IDEN
        AND CCC_PER_TID_CODIGO = PER_TID_CODIGO
        AND CCC_CLI_PER_NUM_IDEN = P_NUM_IDEN
        AND CCC_CLI_PER_TID_CODIGO = P_TID_CODIGO
        AND CCC_NUMERO_CUENTA = P_CUENTA;
   R_PER C_PER%ROWTYPE;

   V_OFO_CONSECUTIVO ORDENES_FONDOS.OFO_CONSECUTIVO%TYPE;


   CURSOR ID_COLOCO IS
      SELECT PER_NUM_IDEN
            ,PER_TID_CODIGO
      FROM   PERSONAS
      WHERE  PER_NOMBRE_USUARIO = USER;
   R_COLOCO ID_COLOCO%ROWTYPE;


   IVA            NUMBER;
   V_FACB_SEQ      NUMBER;
   VALOR_IVA      NUMBER;
   MONTO_MINIMO   NUMBER;

   P_SUCURSAL SUCURSALES.SUC_CODIGO%TYPE;
   P_PER_NUM_IDEN PERSONAS.PER_NUM_IDEN%TYPE;
   P_PER_TID_CODIGO PERSONAS.PER_TID_CODIGO%TYPE;

   V_ODP_CONSECUTIVO ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
   ERRORSQL             VARCHAR2(125);
   YA_GENERO      EXCEPTION;
   E_COMERCIAL    EXCEPTION;
   E_COLOCO    EXCEPTION;
BEGIN
   OPEN C_GENERADO;
   FETCH C_GENERADO INTO SINO_PROCESO;
   IF C_GENERADO%FOUND THEN
      SINO_PROCESO := NVL(SINO_PROCESO,'N');
   END IF;
   CLOSE C_GENERADO;
   IF SINO_PROCESO = 'S' THEN
      RAISE YA_GENERO;
   END IF;
   OPEN C_CONVENIO;
   FETCH C_CONVENIO INTO R_CONV;
   WHILE C_CONVENIO%FOUND LOOP
      OPEN C_VALOR (R_CONV.CONV_CONSECUTIVO);
      FETCH C_VALOR INTO TOTAL_SERVICIO;
      IF C_VALOR%FOUND THEN
         TOTAL_SERVICIO := NVL(TOTAL_SERVICIO,0);
      ELSE
         TOTAL_SERVICIO := 0;
      END IF;
      CLOSE C_VALOR;
      /************* GENERACION DE LA FACTURACION ********************/
      IF TOTAL_SERVICIO != 0 THEN
         OPEN C_CONSTANTE('IVA');
         FETCH C_CONSTANTE INTO IVA;
         IF C_CONSTANTE%NOTFOUND THEN
            CLOSE C_CONSTANTE;
            RAISE_APPLICATION_ERROR(-20016,'No se pudo encontrar la variable IVA - % IMPUESTO AL VALOR AGREGADO');
         END IF;
         CLOSE C_CONSTANTE;

         OPEN C_RANGO_FACTURACION;
         FETCH C_RANGO_FACTURACION INTO RAD1;
         IF C_RANGO_FACTURACION%NOTFOUND THEN
            CLOSE C_RANGO_FACTURACION;
            RAISE_APPLICATION_ERROR(-20016,'No existen rangos de facturacion activos');
         END IF;
         CLOSE C_RANGO_FACTURACION;

         IF NVL(RAD1.NFCB_NUMERO_ACTUAL,0) > RAD1.NFCB_NUMERO_FINAL THEN
            UPDATE NUMEROS_FACTURAS_COD_BARRAS
            SET NFCB_ESTADO = 'I'
            WHERE NFCB_NUMERO = RAD1.NFCB_NUMERO;

            OPEN C_RANGO_FACTURACION;
            FETCH C_RANGO_FACTURACION INTO RAD1;
            IF C_RANGO_FACTURACION%NOTFOUND THEN
               CLOSE C_RANGO_FACTURACION;
               RAISE_APPLICATION_ERROR(-20016,'No existen rangos de facturacion activos');
            END IF;
            CLOSE C_RANGO_FACTURACION;
         END IF;

         IF NVL(RAD1.NFCB_NUMERO_ACTUAL,0) > RAD1.NFCB_NUMERO_FINAL THEN
            RAISE_APPLICATION_ERROR(-20017,'Consecutivo de facturacion no disponible para el rango activo. Ingrese otro rango de facturacion');
         END IF;

         UPDATE NUMEROS_FACTURAS_COD_BARRAS
         SET    NFCB_NUMERO_ACTUAL = RAD1.NFCB_NUMERO_ACTUAL
         WHERE  NFCB_NUMERO = RAD1.NFCB_NUMERO;

         VALOR_IVA := ROUND(TOTAL_SERVICIO * IVA,2);
         SELECT FACB_SEQ.NEXTVAL INTO V_FACB_SEQ FROM DUAL;

         INSERT INTO FACTURAS_CODIGOS_BARRAS
               (  FACB_CONSECUTIVO
                 ,FACB_FECHA
                 ,FACB_GENERADO_POR
                 ,FACB_FECHA_CORTE
                 ,FACB_REVERSADA
                 ,FACB_NFCB_NUMERO
                 ,FACB_NUMERO_DIAN
                 ,FACB_TERMINAL_CAPTURA
                 ,FACB_COBRO_SERVICIO
                 ,FACB_VALOR_IVA
                 ,FACB_CONV_CONSECUTIVO)
         VALUES ( V_FACB_SEQ
                 ,SYSDATE
                 ,USER
                 ,SYSDATE
                 ,'N'
                 ,RAD1.NFCB_NUMERO
                 ,RAD1.NFCB_NUMERO_ACTUAL
                 ,FN_TERMINAL()
                 ,TOTAL_SERVICIO
                 ,VALOR_IVA
                 ,R_CONV.CONV_CONSECUTIVO);


         INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
               ( MCC_CONSECUTIVO
                ,MCC_CCC_CLI_PER_NUM_IDEN
                ,MCC_CCC_CLI_PER_TID_CODIGO
                ,MCC_CCC_NUMERO_CUENTA
                ,MCC_FECHA
                ,MCC_TMC_MNEMONICO
                ,MCC_MONTO
                ,MCC_MONTO_A_PLAZO
                ,MCC_MONTO_A_CONTADO
                ,MCC_MONTO_ADMON_VALORES
                ,MCC_MONTO_CARTERA
                ,MCC_FACB_CONSECUTIVO)
         VALUES (MCC_SEQ.NEXTVAL
                ,R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
                ,R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD
                ,R_CONV.CONV_CFO_CCC_NUMERO_CUENTA
                ,SYSDATE
                ,'FCOBA'
                ,0
                ,0
                ,0
                ,0
                ,-TOTAL_SERVICIO
                ,V_FACB_SEQ);

         INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
               ( MCC_CONSECUTIVO
                ,MCC_CCC_CLI_PER_NUM_IDEN
                ,MCC_CCC_CLI_PER_TID_CODIGO
                ,MCC_CCC_NUMERO_CUENTA
                ,MCC_FECHA
                ,MCC_TMC_MNEMONICO
                ,MCC_MONTO
                ,MCC_MONTO_A_PLAZO
                ,MCC_MONTO_A_CONTADO
                ,MCC_MONTO_ADMON_VALORES
                ,MCC_MONTO_CARTERA
                ,MCC_FACB_CONSECUTIVO)
         VALUES (MCC_SEQ.NEXTVAL
                ,R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
                ,R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD
                ,R_CONV.CONV_CFO_CCC_NUMERO_CUENTA
                ,SYSDATE
                ,'IVACB'
                ,0
                ,0
                ,0
                ,0
                ,-VALOR_IVA
                ,V_FACB_SEQ);

         --GENERA ORDEN DE FONDOS
         OPEN C_PER(R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
                   ,R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD
                   ,R_CONV.CONV_CFO_CCC_NUMERO_CUENTA);
         FETCH C_PER INTO R_PER;
         IF C_PER%NOTFOUND THEN
            CLOSE C_PER;
            RAISE E_COMERCIAL;
         ELSE
            P_SUCURSAL := R_PER.PER_SUC_CODIGO;
            P_PER_NUM_IDEN := R_PER.PER_NUM_IDEN;
            P_PER_TID_CODIGO := R_PER.PER_TID_CODIGO;
         END IF;
         CLOSE C_PER;

         OPEN ID_COLOCO;
         FETCH ID_COLOCO INTO R_COLOCO;
         IF ID_COLOCO%NOTFOUND THEN
            CLOSE ID_COLOCO;
            RAISE E_COLOCO;
         END IF;
         CLOSE ID_COLOCO;

         P_ORDENES_FONDOS.PR_CREAR_ORDEN_FONDOS
            (P_SUCURSAL                   => P_SUCURSAL
            ,P_CLI_NUM_IDEN               => R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
            ,P_CLI_TID_CODIGO             => R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD
            ,P_CUENTA                     => R_CONV.CONV_CFO_CCC_NUMERO_CUENTA
            ,P_FON_CODIGO                 => R_CONV.CONV_CFO_FON_CODIGO
            ,P_CFO_CODIGO                 => R_CONV.CONV_CFO_CODIGO
            ,P_PER_NUM_IDEN               => P_PER_NUM_IDEN
            ,P_PER_TID_CODIGO             => P_PER_TID_CODIGO
            ,P_TOF_CODIGO                 => 'RP'
            ,P_TIT_CODIGO                 => 'ABO'
            ,P_MONTO                      => TOTAL_SERVICIO+ VALOR_IVA
            ,P_CARGO_ABONO_CUENTA         => NULL
            ,P_MONTO_CARGO_ABONO_CUENTA   => NULL
            ,P_MONTO_ABONO_CUENTA_DOLARES => NULL
            ,P_FECHA_EJECUCION            => SYSDATE
            ,P_IMPRIME_REC_DERECHOS       => 'S'
            ,P_PER_NUM_IDEN_COLOCO        => R_COLOCO.PER_NUM_IDEN
            ,P_PER_TID_CODIGO_COLOCO      => R_COLOCO.PER_TID_CODIGO
            ,P_ORIGEN_RECURSOS            => 'I'
            ,P_INSERTA_DAU                => 'N'
            ,P_INSERTA_ORR                => 'N'
            ,P_INSERTA_DAA                => 'N'
            ,P_PRODUCTO                   => NULL
            ,P_ORDEN_ORIGEN               => NULL
            ,P_ORDEN_FONDO                => V_OFO_CONSECUTIVO);


         UPDATE FACTURAS_CODIGOS_BARRAS
         SET  FACB_OFO_SUC_CODIGO = P_SUCURSAL
             ,FACB_OFO_CONSECUTIVO = V_OFO_CONSECUTIVO
         WHERE FACB_CONSECUTIVO = V_FACB_SEQ;

         P_ORDEN_PAGO.PR_INSERTA_ORDEN_DE_PAGO (
                     P_ODP_SUC_CODIGO  => 1
                    ,P_ODP_NEG_CONSECUTIVO  => 4  --FINT
                    ,P_ODP_FECHA => SYSDATE
                    ,P_ODP_COLOCADA_POR => USER   --V_ODP_USUARIO
                    ,P_ODP_TPA_MNEMONICO => 'TRB'   --V_TPA_MNEMONICO
                    ,P_ODP_ESTADO => 'APR'
                    ,P_ODP_ES_CLIENTE => 'S'
                    ,P_ODP_COT_MNEMONICO => 'PCOV'
                    ,P_ODP_A_NOMBRE_DE  => 'CORREDORES DAVIVIENDA S.A.'
                    ,P_ODP_FECHA_EJECUCION => SYSDATE
                    ,P_ODP_CONSIGNAR => 'S'
                    ,P_ODP_ENTREGAR_RECOGE => 'R'
                    ,P_ODP_ENVIA_FAX => 'N'
                    ,P_ODP_SOBREGIRO  => 'N'
                    ,P_ODP_CRUCE_CHEQUE => 'NC'
                    ,P_ODP_MONTO_ORDEN => TOTAL_SERVICIO+ VALOR_IVA
                    ,P_ODP_MONTO_IMGF => 0
                    ,P_ODP_APROBADA_POR => USER
                    ,P_ODP_FECHA_APROBACION => SYSDATE
                    ,P_ODP_FORMA_DE_PAGO => 'P'
                    ,P_ODP_CCC_CLI_PER_NUM_IDEN => R_CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
                    ,P_ODP_CCC_CLI_PER_TID_CODIGO => R_CONV.CONV_CFO_CCC_CLI_PER_TID_COD
                    ,P_ODP_CCC_NUMERO_CUENTA => R_CONV.CONV_CFO_CCC_NUMERO_CUENTA
                    ,P_ODP_PAGAR_A => 'T'
                    ,P_ODP_PER_NUM_IDEN => NULL
                    ,P_ODP_PER_TID_CODIGO => NULL
                    ,P_ODP_BAN_CODIGO => 7
                    ,P_ODP_NUM_CUENTA_CONSIGNAR => '03007917432'
                    ,P_ODP_TCB_MNEMONICO	=> 'CCO'
                    ,P_ODP_OCL_CLI_PER_NUM_IDEN_R => NULL
                    ,P_ODP_OCL_CLI_PER_TID_CODIGO_R => NULL
                    ,P_ODP_CCC_CLI_PER_NUM_IDEN_T => NULL -- TRANSFERENCIA ENTRE CUENTAS
                    ,P_ODP_CCC_CLI_PER_TID_CODIGO_T => NULL    ---TRANSFERENCIA ENTRE CUENTAS
                    ,P_ODP_CCC_NUMERO_CUENTA_T  => NULL   --TRANSFERENCIA ENTRE CUENTAS
                    ,P_ODP_CBA_BAN_CODIGO =>  NULL
                    ,P_ODP_CBA_NUMERO_CUENTA => NULL
                    ,P_ODP_MAS_INSTRUCCIONES  => R_CONV.CONV_RADICADO
                    ,P_ODP_NUM_IDEN    => '860079174'
                    ,P_ODP_TID_CODIGO  => 'NIT'
                    ,P_ODP_NPR_PRO_MNEMONICO => 'FINT'
                    ,P_ODP_MEDIO_RECEPCION   => NULL
                    ,P_ODP_DETALLE_MEDIO_RECEPCION  => NULL
                    ,P_ODP_HORA_RECEPCION => NULL
                    ,P_ODP_PER_NUM_IDEN_ES_DUENO  => NULL
                    ,P_ODP_PER_TID_CODIGO_ES_DUENO  => NULL
                    ,P_ODP_FECHA_VERIFICA  => SYSDATE
                    ,P_ODP_TERMINAL_VERIFICA  => NULL
                    ,P_ODP_VERIFICADO_COMERCIAL  => NULL
                    ,P_ODP_DILIGENCIADA_POR   => NULL
                    ,P_ODP_CONSECUTIVO => V_ODP_CONSECUTIVO
                    ,P_DETALLE_ACH => 'N'
                    ,P_ODP_OFO_CONSECUTIVO => V_OFO_CONSECUTIVO
                    ,P_ODP_OFO_SUC_CODIGO => P_SUCURSAL
                    ,P_ODP_FORMA_CARGUE_ACH => NULL
                    ,P_ODP_CDD_CUENTA_CRCC => NULL);


         P_ORDENES_FONDOS.CONFIRMA_ORDEN
                   (P_OFO_SUC_CODIGO       => P_SUCURSAL
                   ,P_OFO_CONSECUTIVO      => V_OFO_CONSECUTIVO);

      END IF;
      FETCH C_CONVENIO INTO R_CONV;
   END LOOP;
   CLOSE C_CONVENIO;
   COMMIT;

   EXCEPTION
      WHEN YA_GENERO THEN
         ERRORSQL := ' ';
         ROLLBACK;
         P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.PR_FACTURACION_CONVENIOS'
                                      ,P_ERROR       => 'YA GENERO EL PROCESO PARA EL DIA: '||P_FECHA||' - '||ERRORSQL
                                      ,P_TABLA_ERROR => NULL);

      WHEN OTHERS THEN
         ERRORSQL := SUBSTR(SQLERRM,1,120);
         ROLLBACK;
         P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.PR_FACTURACION_CONVENIOS'
                                      ,P_ERROR       => 'ERROR : - '||ERRORSQL
                                      ,P_TABLA_ERROR => NULL);

END PR_FACTURACION_CONVENIOS;

PROCEDURE PR_GENERA_AJUSTE_CFIC(
                          P_NID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE
                         ,P_TID          CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE
                         ,P_CTA          CUENTAS_CLIENTE_CORREDORES.CCC_NUMERO_CUENTA%TYPE
                         ,P_LIC_BOL      LIQUIDACIONES_COMERCIAL.LIC_BOL_MNEMONICO%TYPE
                         ,P_LIC_OP       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_OPERACION%TYPE
                         ,P_LIC_FR       LIQUIDACIONES_COMERCIAL.LIC_NUMERO_FRACCION%TYPE
                         ,P_LIC_TIPO     LIQUIDACIONES_COMERCIAL.LIC_TIPO_OPERACION%TYPE
                         ,P_MONTO        MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE
                         ) IS
   CURSOR CONSECUTIVO IS
      SELECT MAX(ACL_CONSECUTIVO) + 1
      FROM   AJUSTES_CLIENTES
      WHERE  ACL_SUC_CODIGO = 1
      AND    ACL_NEG_CONSECUTIVO = 2;

   V_CONSECUTIVO     AJUSTES_CLIENTES.ACL_CONSECUTIVO%TYPE;
   V_OBSERVACIONES   AJUSTES_CLIENTES.ACL_OBSERVACIONES%TYPE;
   ERRORSQL          VARCHAR2(350);
   V_VALOR_AJU       AJUSTES_CLIENTES.ACL_MONTO%TYPE;
   V_VALOR_MCC       MOVIMIENTOS_CUENTA_CORREDORES.MCC_MONTO%TYPE;
   V_CAJ             VARCHAR2(3);
   V_TMC             VARCHAR2(5);

BEGIN
   OPEN CONSECUTIVO;
   FETCH CONSECUTIVO INTO V_CONSECUTIVO;
   CLOSE CONSECUTIVO;

   IF P_LIC_TIPO = 'C' THEN			-- COMPRA
      V_VALOR_AJU     := - P_MONTO;
      V_VALOR_MCC     := P_MONTO;
      V_CAJ           := 'OFA';
      V_TMC           := 'ABO';
      V_OBSERVACIONES := 'ABONO OPERACION FIC - LIC. '||P_LIC_OP||' - '||P_LIC_FR||' - '||P_LIC_TIPO||' - '||P_LIC_BOL;
   ELSE
      V_VALOR_AJU     := P_MONTO;
      V_VALOR_MCC     := - P_MONTO;
      V_CAJ           := 'OFC';
      V_TMC           := 'CAR';
      V_OBSERVACIONES := 'CARGUE OPERACION FIC - LIC. '||P_LIC_OP||' - '||P_LIC_FR||' - '||P_LIC_TIPO||' - '||P_LIC_BOL;
   END IF;

   INSERT INTO AJUSTES_CLIENTES
         (ACL_CONSECUTIVO
         ,ACL_SUC_CODIGO
         ,ACL_NEG_CONSECUTIVO
         ,ACL_CCC_CLI_PER_NUM_IDEN
         ,ACL_CCC_CLI_PER_TID_CODIGO
         ,ACL_CCC_NUMERO_CUENTA
         ,ACL_CAJ_MNEMONICO
         ,ACL_FECHA
         ,ACL_GENERADO_POR
         ,ACL_MONTO
         ,ACL_OBSERVACIONES)
   VALUES
         (V_CONSECUTIVO
         ,1
         ,2
         ,P_NID
         ,P_TID
         ,P_CTA
         ,V_CAJ
         ,SYSDATE
         ,'AUTOMATICO'
         ,ABS(V_VALOR_AJU)
         ,V_OBSERVACIONES);

   INSERT INTO MOVIMIENTOS_CUENTA_CORREDORES
         (MCC_CONSECUTIVO
         ,MCC_CCC_CLI_PER_NUM_IDEN
         ,MCC_CCC_CLI_PER_TID_CODIGO
         ,MCC_CCC_NUMERO_CUENTA
         ,MCC_FECHA
         ,MCC_TMC_MNEMONICO
         ,MCC_MONTO
         ,MCC_MONTO_A_CONTADO
         ,MCC_MONTO_A_PLAZO
         ,MCC_MONTO_BURSATIL
         ,MCC_MONTO_ADMON_VALORES
         ,MCC_SUC_CODIGO
         ,MCC_NEG_CONSECUTIVO
         ,MCC_ACL_CONSECUTIVO)
   VALUES
         (MCC_SEQ.NEXTVAL
         ,P_NID
         ,P_TID
         ,P_CTA
         ,SYSDATE
         ,V_TMC
         ,V_VALOR_MCC
         ,0
         ,0
         ,0
         ,0
         ,1
         ,2
         ,V_CONSECUTIVO);

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      errorsql := SUBSTR(SQLERRM,1,350);
      INSERTA_ERROR ( P_PROCESO     => 'P_OPERACIONES.PR_GENERA_AJUSTE_CFIC'
                     ,P_ERROR       => SUBSTR('LIQUIDACION:'||P_LIC_BOL||'-'||P_LIC_OP||'-'||P_LIC_FR||'-'||P_LIC_TIPO||'-'||ERRORSQL,1,500)
                     ,P_TABLA_ERROR => NULL);
      COMMIT;

END PR_GENERA_AJUSTE_CFIC;

/*******************************************************************************************
***  Funcion calculo de comisiones unidad de fondos UDF   cuando se solicita cambio de la orden
***************************************************************************************** */

FUNCTION FN_COMISION_UDF_CAMBIO_ORDEN( P_PRECIO NUMBER,
                                       P_NOMINAL NUMBER)
RETURN NUMBER IS

 V_VALOR NUMBER(20);
 V_MONTO ORDENES_VENTA.OVE_TOTAL_OPERACION_ACC%TYPE;
 V_FIJA  COMISIONES_UDF.UDF_COMISION_FIJA%TYPE;
 V_CUDF  CONSTANTES.CON_VALOR%TYPE;

CURSOR C_RANGO(UDF_RANGO NUMBER) IS
 SELECT UDF_RANGO_INICIAL,
        UDF_RANGO_FINAL,
        NVL(UDF_COMISION_FIJA,
        (UDF_COMISION_POR))COMISION
 FROM COMISIONES_UDF
 ORDER BY UDF_RANGO_INICIAL;

 V_VI COMISIONES_UDF.UDF_RANGO_INICIAL%TYPE;
 V_VF COMISIONES_UDF.UDF_RANGO_FINAL%TYPE;
 V_VC COMISIONES_UDF.UDF_COMISION_POR%TYPE;
 V_COMISION  ORDENES_VENTA.OVE_COMISION%TYPE;

BEGIN
   V_MONTO := 0;
   V_CUDF  := 0;
   V_MONTO := (P_NOMINAL * P_PRECIO);

   ---CALCULO DE COMISION

   SELECT DISTINCT (UDF_COMISION_FIJA)
   INTO V_FIJA
   FROM COMISIONES_UDF
   WHERE UDF_COMISION_FIJA IS NOT NULL;

   SELECT NVL(CON_VALOR,0)
   INTO V_CUDF FROM CONSTANTES
   WHERE CON_MNEMONICO = 'CUF';

   OPEN C_RANGO(V_MONTO);
   LOOP
      FETCH C_RANGO  INTO  V_VI
                          ,V_VF
                          ,V_VC;

    IF V_MONTO BETWEEN V_VI AND V_VF THEN
      IF V_FIJA = V_VC THEN
         V_COMISION := (V_VC*100)/V_MONTO  ;
      ELSE
         V_COMISION :=V_VC;
      END IF;
        ELSE
        	 NULL;
        END IF;
   EXIT WHEN C_RANGO%notfound;
   END LOOP;

   CLOSE C_RANGO;

   IF V_COMISION IS NULL THEN
     V_COMISION :=V_CUDF;
   END IF;

   RETURN (V_COMISION);
END FN_COMISION_UDF_CAMBIO_ORDEN;

PROCEDURE P_CALCULA_DATOS(P_HINT     VARCHAR2              
                         ,P_EMISOR   VARCHAR2              
                         ,P_ESPECIE  VARCHAR2              
                         ,P_CONDICION_ESPECULATIVA VARCHAR2
                         ,P_CONDICION  VARCHAR2            
                         ,P_MERCADO  VARCHAR2              
                         ,P_BOLSA  VARCHAR2) IS

   V_QUERY VARCHAR2(30000);
   v_archivo utl_file.file_type;
BEGIN 
   V_QUERY := 'INSERT INTO GL_DATOS_ROPEFE(BOL_MNEMONICO
                      ,NUMERO_OPERACION
                      ,NUMERO_FRACCION
                      ,TIPO_OPERACION
                      ,ELI_MNEMONICO
                      ,MERCADO
                      ,FECHA_CUMPLIMIENTO
                      ,SERVICIO_BOLSA_OPERACION
                      ,SERVICIO_BOLSA_VOLUMEN
                      ,FECHA_VENCIMIENTO
                      ,PERIODO
                      ,TASA
                      ,CANTIDAD_TOTAL_OPERACION
                      ,CANTIDAD_FRACCION
                      ,VOLUMEN_NETO_FRACCION
                      ,PRECIO
                      ,FECHA_EMISION
                      ,FECHA_OPERACION
                      ,PORCENTAJE_COMISION
                      ,VALOR_COMISION
                      ,OVE_ENA_MNEMONICO
                      ,ENA_DESCRIPCION
                      ,EMI_DESCRIPCION
                      ,CRUZCON
                      ,COM_VENDEDOR
                      ,LOCALIZACION
                      ,VIGENCIA_OP
                      ,CCC_CLI_PER_TID_CODIGO
                      ,CCC_CLI_PER_NUM_IDEN
                      ,CCC_NUMERO_CUENTA
                      ,CCC_NOMBRE_CUENTA
                      ,PER_INICIALES_USUARIO
                      ,PER_SUC_CODIGO
                      ,ORDEN
                      ,COR_ORDEN
                      ,TIPO_OPERACION_TO
                      ,FECHA_VALORACION
                      ,VALORACION_TM_1
                      ,IVA
                      ,RETEFTE
                      ,OVE_MONEDA_COMPENSACION
                      ,OVE_TIPO_MEC
                      ,CPR_MNEMONICO
                      ,CPR_DESCRIPCION
                      ,CCC_CUENTA_APT
                      ,VOLUMEN_NETO_INCLUIDO_IVA
                      ,HORA_GRABACION_NEGOCIO
                      ,ORIGEN_OPERACION
                      ,CODIGO_OPERADOR_COMPRADOR
                      ,CODIGO_OPERADOR_VENDEDOR
                      ,PLAZO_VENCIMIENTO
                      ,PORCENTAJE_PRECIO
                      ,PRCNTJE_TSA_ADJDCCION
                      ,PLAZO_EMISION
                      ,TASA_REFERENCIA
                      ,BASE_CALCULO_INTERES
                      ,REINVERSION
                      ,IDENTIFICACION_REMATE
                      ,PLAZO_LIQ
                      ,MOD_LIQUIDACION
                      ,FIJA_PRECIO_ACCIONES
                      ,PERIODO_EXDIVIDENDO
                      ,IND_ORIGEN
                      ,REF_SWAP
                      ,PORCENTAJE_TASA_REPO
                      ,PLAZO_REPO
                      ,VALOR_CAPTACION_REPO
                      ,VOLUMEN_RECOMPRA_REPO
                      ,SUCURSAL_CUMPLIMIENTO
                      ,VOLUMEN_FRACCION
                      ,PRCNTJE_PRCIO_NTO_FRCCION
                      ,NMRO_IMPRSNES_LQUDCION
                      ,CODIGO_CONTACTO_COMERCIAL
                      ,NUMERO_FRACCIONES
                      ,REFERENCIA_COMISIONISTA
                      ,TIPO_IDENTIFICACION_1
                      ,NIT_1
                      ,IDNTFCCION_PTRMNIO_AUT_1
                      ,TIPO_IDENTIFICACION_2
                      ,NIT_2
                      ,IDNTFCCION_PTRMNIO_AUT_2
                      ,TIPO_IDENTIFICACION_3
                      ,NIT_3
                      ,IDNTFCCION_PTRMNIO_AUT_3
                      ,IND_OPERACION
                      ,BASE_RETENCION_COBRO
                      ,PORCENTAJE_RET_COBRO
                      ,BASE_RETENCION_TRASLADO
                      ,PORCENTAJE_RET_TRASLADO
                      ,PORCENTAJE_IVA_COMISION
                      ,VALOR_IVA_COMISION
                      ,TRASLADA_SERV_A_CLIENTE
                      ,OP_CON_RETEFTE_ENAJENA
                      ,FECHA_CONSTA_VENTA
                      ,VALOR_CONSTA_VENTA
                      ,GENERA_CONSTA_COMPRADOR
                      ,CONTRAPAGO_OPERACION
                      ,ENVIA_RTEFTE
                      ,PROMOTOR_LIQUIDEZ
                      ,TIPO_USO_TASA
                      ,NEMO_LARGO
                      ,VALOR_EXTEMPO
                      ,POSICION_EXTEMPO
                      ,PAQUETE_BVC
                      ,REIV_PRIM
                      ,CTA_MARGEN
                      ,CANAL_ORIGEN
                      ,MEDIO_RECEPCION
                      ,COMERCIAL_ORDENA
                      ,ISIN
                      ,FECHA_RECEPCION 
                      ,HORA_RECEPCION 
                      ,DETALLE_MEDIO_RECEPCION
                      ,OBSERVACIONES
                      ,SEGMENTO
					  ,FECHA_REGISTRO
					  ,PERFIL_RIESGO
					  ,TIPO_IDENTIFICACION_4
					  ,NIT_4
					  ,INSTRUCCION_IMPARTIDA_POR
					  ,CALIFICA_RIESGO
					  )
              SELECT '||P_HINT||
                    ' LIC_BOL_MNEMONICO,
                      to_char(LIC_NUMERO_OPERACION),
                      LIC_NUMERO_FRACCION,
                      LIC_TIPO_OPERACION,
                      LIC_ELI_MNEMONICO,
                      LIC_MERCADO, 
                      LIC_FECHA_CUMPLIMIENTO,
                      DECODE(LIC_BOL_MNEMONICO,''COL'',LIC_SERVICIO_BOLSA_FIJO,LIC_SERVICIO_BOLSA_OPERACION)  LIC_SERVICIO_BOLSA_OPERACION,
                      DECODE(LIC_BOL_MNEMONICO,''COL'',LIC_SERVICIO_BOLSA_VARIABLE,LIC_SERVICIO_BOLSA_VOLUMEN) LIC_SERVICIO_BOLSA_VOLUMEN,
                      LIC_FECHA_VENCIMIENTO,
                      LIC_PERIODICIDAD||''.''||LIC_MODALIDAD PERIODO,
                      DECODE(LIC_TASA_EMISION,NULL,LIC_PUNTOS_AJUSTE,LIC_TASA_EMISION) TASA,
                      LIC_CANTIDAD_TOTAL_OPERACION,
                      LIC_CANTIDAD_FRACCION,
                      LIC_VOLUMEN_NETO_FRACCION,
                      LIC_PRECIO,LIC_FECHA_EMISION,
                      LIC_FECHA_OPERACION,
                      LIC_PORCENTAJE_COMISION,
                      LIC_VALOR_COMISION,
                      OVE_ENA_MNEMONICO,
                      ENA_DESCRIPCION,
                      EMI_DESCRIPCION,
                      DECODE(LIC_COD_CMSNSTA_CMPRDOR||LIC_COD_CMSNSTA_VNDDOR,''002002'',''CRUZADA'',''CONVENIDA'') CRUZCON,
                      DECODE(LIC_TIPO_OPERACION,''C'',LIC_COD_CMSNSTA_VNDDOR 
                                               ,''V'',LIC_COD_CMSNSTA_CMPRDOR) COM_VENDEDOR,
                      DECODE(OVE_LTI_MNEMONICO,''DA'',''DECEVAL'',''DV'',''DCV'',''FISICO'') LOCALIZACION,
                      DECODE(TRUNC(LIC_FECHA_CUMPLIMIENTO) - TRUNC(LIC_FECHA_OPERACION),0,''HOYXHOY'',1,''CONTADO'',
                           2,''CONTADO'',3,''CONTADO'',4,''CONTADO'',5,''CONTADO'',''PLAZO'') VIGENCIA_OP,
                      CCC_CLI_PER_TID_CODIGO,
                      CCC_CLI_PER_NUM_IDEN,
                      CCC_NUMERO_CUENTA, CCC_NOMBRE_CUENTA,
                      PER.PER_INICIALES_USUARIO, PER.PER_SUC_CODIGO,
                      LIC_OVE_CONSECUTIVO  ORDEN,
                      PER1.PER_INICIALES_USUARIO COR_ORDEN,
                      '''' TIPO_OPERACION_TO,
                      LIC_FECHA_VALORACION,
                      '''' VALORACION_TM_1,
                      '''' IVA,
                      '''' RETEFTE,
                      OVE_MONEDA_COMPENSACION,
                      DECODE(LIC_BOL_MNEMONICO,''MEC'',DECODE(OVE_TIPO_MEC,''MR'',''Mec Registro''
                                                                          ,''MT'',''Mec Transaccional''
                                                                          ,'' '')    
                                                                          ,NULL)  OVE_TIPO_MEC,
                      CPR_MNEMONICO,CPR_DESCRIPCION,
                      NVL(CCC_CUENTA_APT,''N'') CCC_CUENTA_APT,
                      ((LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE) +
                        DECODE(LIC_VALOR_EXTEMPO,NULL,0,0,0,
                          DECODE(LIC_POSICION_EXTEMPO,''S'',-LIC_VALOR_EXTEMPO,''A'',LIC_VALOR_EXTEMPO)) -
                       (LIC_VALOR_COMISION * P_WEB_EXTRACTO.PORCENTAJE_IVA_LIC (LIC_NIT_1,LIC_TIPO_IDENTIFICACION_1,LIC_FECHA_OPERACION)))  VOLUMEN_NETO_INCLUIDO_IVA,
                      LIC_HORA_GRABACION_NEGOCIO,
                      LIC_ORIGEN_OPERACION,
                      LIC_CODIGO_OPERADOR_COMPRADOR,
                      LIC_CODIGO_OPERADOR_VENDEDOR,
                      LIC_PLAZO_VENCIMIENTO,
                      LIC_PORCENTAJE_PRECIO,
                      LIC_PRCNTJE_TSA_ADJDCCION,
                      LIC_PLAZO_EMISION,
                      P_TOOLS.FN_LIC_TASA_REFERENCIA(LIC_TASA_REFERENCIA) TASA_REFERENCIA,
                      DECODE(LIC_BASE_CALCULO_INTERES,''N'',''NORMAL'',''C'',''COMERCIAL'',''D'',''BISIESTO'','' '') BASE_CALCULO_INTERES,
                      LIC_REINVERSION,
                      LIC_IDENTIFICACION_REMATE,
                      DECODE(SIGN(LIC_PLAZO_LIQUIDACION-6),-1,''CONTADO'',''PLAZO'') PLAZO_LIQ,
                      DECODE(LIC_MDLDAD_OPRCION_PLZO_ACCNES,''F'',''FINANCIERO'',''E'',''EFECTIVO'',''C'',''CONTADO'',''P'',''PLAZO'','' '') MOD_LIQUIDACION,
                      LIC_FIJA_PRECIO_ACCIONES,
                      LIC_PERIODO_EXDIVIDENDO,
                      DECODE(LIC_INDICADOR_ORIGEN,''P'',''CTA.PROPIA'',''R'',''REC.PROPIOS'',''T'',''TERCER0S'',''P'',''OF.PUNTA'',''M'',''MERCADO'',''E'',''COLECTIVAS'','' '') IND_ORIGEN,
                      DECODE(LIC_RFRNCIA_SWAP_CMSNSTA,''00000000'','' '',LIC_RFRNCIA_SWAP_CMSNSTA) REF_SWAP,
                      LIC_PORCENTAJE_TASA_REPO,
                      LIC_PLAZO_REPO,
                      LIC_VALOR_CAPTACION_REPO,
                      LIC_VOLUMEN_RECOMPRA_REPO,
                      LIC_SUCURSAL_CUMPLIMIENTO,
                      LIC_VOLUMEN_FRACCION,
                      LIC_PRCNTJE_PRCIO_NTO_FRCCION,
                      LIC_NMRO_IMPRSNES_LQUDCION,
                      LIC_CODIGO_CONTACTO_COMERCIAL,
                      LIC_NUMERO_FRACCIONES,
                      LIC_REFERENCIA_COMISIONISTA,
                      LIC_TIPO_IDENTIFICACION_1,
                      LIC_NIT_1,
                      LIC_IDNTFCCION_PTRMNIO_AUT_1,
                      LIC_TIPO_IDENTIFICACION_2,
                      LIC_NIT_2,
                      LIC_IDNTFCCION_PTRMNIO_AUT_2,
                      LIC_TIPO_IDENTIFICACION_3,
                      LIC_NIT_3,
                      LIC_IDNTFCCION_PTRMNIO_AUT_3,
                      DECODE(LIC_INDICADOR_OPERACION,''I'',''INGRESADA'',''M'',''MODIFICADA'',''A'',''ANULADA'','' '') IND_OPERACION,
                      LIC_BASE_RETENCION_COBRO,
                      LIC_PORCENTAJE_RET_COBRO,
                      LIC_BASE_RETENCION_TRASLADO,
                      LIC_PORCENTAJE_RET_TRASLADO,
                      LIC_PORCENTAJE_IVA_COMISION,
                      LIC_VALOR_IVA_COMISION,
                      LIC_TRASLADA_SERV_A_CLIENTE,
                      LIC_OP_CON_RETEFTE_ENAJENA,
                      LIC_FECHA_CONSTA_VENTA,
                      LIC_VALOR_CONSTA_VENTA,
                      LIC_GENERA_CONSTA_COMPRADOR,
                      LIC_CONTRAPAGO_OPERACION,
                      DECODE(LIC_ENVIA_RETEFUENTE,''A'',''RET.AF'',''C'',''RET.CNTRP'',''N'',''SIN.RET'','' '') ENVIA_RTEFTE,
                      LIC_PROMOTOR_LIQUIDEZ,
                      DECODE(LIC_TIPO_USO_TASA,''A'',''ACTUAL'',''P'',''PREVIA'','' '') TIPO_USO_TASA,
                      LIC_NEMO_LARGO,
                      LIC_VALOR_EXTEMPO,
                      LIC_POSICION_EXTEMPO,
                      '''' PAQUETE_BVC,
                      LIC_REIV_PRIM,
                      LIC_CTA_MARGEN,
                      DECODE(OVE_CANAL_ORIGEN,''S2'',''Home Broker''
                                         ,''ACC'',''@cciones Comisionista''
                                         ,''UDF'',''Coeasy Banca Patrimonial''
                                         ,''UDF-A'',''@cciones Banca Patrimonial''
                                         ,''S4'',''Pro Broker''
                                         ,''PLV'',''Oficina Red Banco''
                                         ,''Fix-I'',''Fix Instituc.- Pro Broker''
                                         ,''ACC-E'',''Acc. Etrade - Home Broker''
                                         ,''COEASY'') CANAL_ORIGEN,
                      DECODE(OVE_MEDIO_RECEPCION, ''TEL'',''EXTENSION'',
                                                  ''FAX'',''FAX'',
                                                  ''MSJ'',''MENSAJERIA INSTANTANEA'',
                                                  ''COE'',''CORREO ELECTRONICO'',
                                                  ''PSE'',''PRESENCIAL CON SOPORTE ESCRITO'',
                                                  ''INT'',''INTERNET'',
                                                  ''HOM'',''HOMEBROKER'',
                                                  ''PRO'',''PROBROKER'',
                                                  ''FIX'',''FIXBROKER'',
                                                  ''MIL'',''MILA'',
                                                  ''BLO'',''BLOOMBERG'',OVE_MEDIO_RECEPCION) MEDIO_RECEPCION,
                      (SELECT PER_NOMBRE_USUARIO
                         FROM FILTRO_COMERCIALES
                        WHERE PER_NUM_IDEN = OVE_PER_NUM_IDEN_ES_DUENO 
                          AND PER_TID_CODIGO = OVE_PER_TID_CODIGO_ES_DUENO) COMERCIAL_ORDENA,
                      '''' ISIN,
                      OVE_FECHA_RECEPCION FECHA_RECEPCION, 
                      OVE_HORA_RECEPCION HORA_RECEPCION, 
                      OVE_DETALLE_MEDIO_RECEPCION DETALLE_MEDIO_RECEPCION, 
                      OVE_OBSERVACIONES OBSERVACIONES,
                      (SELECT BSC_DESCRIPCION
                         FROM CLIENTES,
                              BI_SEGMENTACION_CLIENTES
                        WHERE CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                          AND CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                          AND BSC_MNEMONICO = CLI_BSC_MNEMONICO
                          AND BSC_BCC_MNEMONICO = CLI_BSC_BCC_MNEMONICO)  SEGMENTO,
					TO_CHAR(OVE_FECHA_Y_HORA,''DD-MM-YYYY HH24:MI:SS'') FECHA_REGISTRO,						  
					(SELECT NVL(P.PERI_DESCRIPCION,''N/A'')
					FROM    CLIENTES C,
					PERFILES_RIESGO P
					WHERE  C.CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
					AND        C.CLI_PER_NUM_IDEN    = CCC_CLI_PER_NUM_IDEN
					AND        C.CLI_PERFIL_RIESGO    = P.PERI_CONSECUTIVO(+)) PERFIL_RIESGO,
					OVE_RLC_PER_TID_CODIGO  RLC_PER_TID_CODIGO,
					OVE_RLC_PER_NUM_IDEN   RLC_PER_NUM_IDEN,
					(SELECT PER.PER_PRIMER_APELLIDO||'' ''|| PER.PER_SEGUNDO_APELLIDO||'' ''|| PER.PER_NOMBRE 
					FROM     PERSONAS_RELACIONADAS RLC, PERSONAS PER 
					WHERE  PER.PER_NUM_IDEN     = RLC.RLC_PER_NUM_IDEN
					AND 	       PER.PER_TID_CODIGO   = RLC.RLC_PER_TID_CODIGO
					AND        RLC.RLC_PER_NUM_IDEN   = OVE_RLC_PER_NUM_IDEN
					AND        RLC.RLC_PER_TID_CODIGO = OVE_RLC_PER_TID_CODIGO
					AND        RLC.RLC_CLI_PER_NUM_IDEN   = OVE_CCC_CLI_PER_NUM_IDEN
					AND        RLC.RLC_CLI_PER_TID_CODIGO = OVE_CCC_CLI_PER_TID_CODIGO
					AND        RLC.RLC_ROL_CODIGO IN (1,6,7) 
					AND        ROWNUM <=1)  ORDENANTE,
					DECODE(ENA_RIESGO_CORREDORES, ''NC'', ''No Comercializable'', ''N'', ''No Aplica'', ENA_RIESGO_CORREDORES) CALIFICA_RIESGO
               FROM EMISORES,
                    ESPECIES_NACIONALES,
                    PERSONAS PER, 
                    CUENTAS_CLIENTE_CORREDORES,
                    ORDENES_VENTA,
                    LIQUIDACIONES_COMERCIAL LIC,
                    PERSONAS PER1,
                    PERSONAS_CENTROS_PRODUCCION,
                    CENTROS_PRODUCCION
              WHERE EMI_MNEMONICO LIKE '||''''||P_EMISOR||''' 
                AND ENA_EMI_MNEMONICO = EMI_MNEMONICO
                AND ENA_MNEMONICO LIKE '||''''||P_ESPECIE||''' 
                AND LIC_MNEMOTECNICO_TITULO = ENA_MNEMONICO
                AND CCC_PER_NUM_IDEN = PER.PER_NUM_IDEN 
                AND CCC_PER_TID_CODIGO = PER.PER_TID_CODIGO '||
                P_CONDICION_ESPECULATIVA ||
              ' AND OVE_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN 
                AND OVE_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO 
                AND OVE_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA 
                AND OVE_PER_NUM_IDEN = PER1.PER_NUM_IDEN
                AND OVE_PER_TID_CODIGO = PER1.PER_TID_CODIGO
                AND LIC_BOL_MNEMONICO =  OVE_BOL_MNEMONICO 
                AND LIC_OVE_COC_CTO_MNEMONICO = OVE_COC_CTO_MNEMONICO  
                AND LIC_OVE_CONSECUTIVO =  OVE_CONSECUTIVO '||
                P_CONDICION ||
              ' AND LIC_TIPO_OPERACION = ''V''
                AND LIC_MERCADO LIKE '||''''||P_MERCADO||''' 
                AND LIC_BOL_MNEMONICO LIKE '||''''||P_BOLSA||''' 
                AND CCC_PER_NUM_IDEN = PCP_PER_NUM_IDEN
                AND CCC_PER_TID_CODIGO = PCP_PER_TID_CODIGO 
                AND PCP_PRINCIPAL = ''S''
                AND PCP_CPR_MNEMONICO = CPR_MNEMONICO
         UNION
         SELECT '||P_HINT||'
                LIC_BOL_MNEMONICO,
                to_char(LIC_NUMERO_OPERACION),
                LIC_NUMERO_FRACCION,
                LIC_TIPO_OPERACION,
                LIC_ELI_MNEMONICO,
                LIC_MERCADO,
                LIC_FECHA_CUMPLIMIENTO,
                DECODE(LIC_BOL_MNEMONICO,''COL'',LIC_SERVICIO_BOLSA_FIJO,LIC_SERVICIO_BOLSA_OPERACION)  LIC_SERVICIO_BOLSA_OPERACION,
                DECODE(LIC_BOL_MNEMONICO,''COL'',LIC_SERVICIO_BOLSA_VARIABLE,LIC_SERVICIO_BOLSA_VOLUMEN) LIC_SERVICIO_BOLSA_VOLUMEN,                          
                LIC_FECHA_VENCIMIENTO,
                LIC_PERIODICIDAD||''.''||LIC_MODALIDAD PERIODO,
                DECODE(LIC_TASA_EMISION,NULL,LIC_PUNTOS_AJUSTE,LIC_TASA_EMISION) TASA,
                LIC_CANTIDAD_TOTAL_OPERACION,
                LIC_CANTIDAD_FRACCION,
                LIC_VOLUMEN_NETO_FRACCION,
                LIC_PRECIO,LIC_FECHA_EMISION,
                LIC_FECHA_OPERACION,
                LIC_PORCENTAJE_COMISION,
                LIC_VALOR_COMISION,
                OCO_ENA_MNEMONICO,
                ENA_DESCRIPCION,
                EMI_DESCRIPCION,
                DECODE(LIC_COD_CMSNSTA_CMPRDOR||LIC_COD_CMSNSTA_VNDDOR,''002002'',''CRUZADA'',''CONVENIDA'') CRUZCON,
                LIC_COD_CMSNSTA_VNDDOR COM_VENDEDOR,
                DECODE(OCO_LTI_MNEMONICO,''DA'',''DECEVAL'',''DV'',''DCV'',''FISICO'') LOCALIZACION,
                DECODE(TRUNC(LIC_FECHA_CUMPLIMIENTO) - TRUNC(LIC_FECHA_OPERACION),0,''HOYXHOY'',1,''CONTADO'',
                     2,''CONTADO'',3,''CONTADO'',4,''CONTADO'',5,''CONTADO'',''PLAZO'') VIGENCIA_OP,
                CCC_CLI_PER_TID_CODIGO,
                CCC_CLI_PER_NUM_IDEN,
                CCC_NUMERO_CUENTA, CCC_NOMBRE_CUENTA,
                PER.PER_INICIALES_USUARIO, PER.PER_SUC_CODIGO,
                LIC_OCO_CONSECUTIVO ORDEN,
                PER2.PER_INICIALES_USUARIO COR_ORDEN,
                '''' TIPO_OPERACION_TO,
                LIC_FECHA_VALORACION,
                '''' VALORACION_TM_1,
                '''' IVA,
                '''' RETEFTE,
                OCO_MONEDA_COMPENSACION,
                DECODE(LIC_BOL_MNEMONICO,''MEC'',DECODE(OCO_TIPO_MEC,''MR'',''Mec Registro''
                                                                    ,''MT'',''Mec Transaccional''
                                                                    ,'' '')    
                                                                    ,NULL)  OCO_TIPO_MEC,
                CPR_MNEMONICO,CPR_DESCRIPCION,
                NVL(CCC_CUENTA_APT,''N'') CCC_CUENTA_APT,
                ((LIC_VOLUMEN_NETO_FRACCION + LIC_RETENCION_FUENTE + LIC_TRASLADO_RTE_FTE) +
                  DECODE(LIC_VALOR_EXTEMPO,NULL,0,0,0,
                                  DECODE(LIC_POSICION_EXTEMPO,''S'',LIC_VALOR_EXTEMPO,''A'',-LIC_VALOR_EXTEMPO)) +
                 (LIC_VALOR_COMISION * P_WEB_EXTRACTO.PORCENTAJE_IVA_LIC (LIC_NIT_1,LIC_TIPO_IDENTIFICACION_1,LIC_FECHA_OPERACION)))  VOLUMEN_NETO_INCLUIDO_IVA,
                LIC_HORA_GRABACION_NEGOCIO,
                LIC_ORIGEN_OPERACION,
                LIC_CODIGO_OPERADOR_COMPRADOR,
                LIC_CODIGO_OPERADOR_VENDEDOR,
                LIC_PLAZO_VENCIMIENTO,
                LIC_PORCENTAJE_PRECIO,
                LIC_PRCNTJE_TSA_ADJDCCION,
                LIC_PLAZO_EMISION,
                P_TOOLS.FN_LIC_TASA_REFERENCIA(LIC_TASA_REFERENCIA) TASA_REFERENCIA,
                DECODE(LIC_BASE_CALCULO_INTERES,''N'',''NORMAL'',''C'',''COMERCIAL'',''D'',''BISIESTO'','' '') BASE_CALCULO_INTERES,
                LIC_REINVERSION,
                LIC_IDENTIFICACION_REMATE,
                DECODE(SIGN(LIC_PLAZO_LIQUIDACION-6),-1,''CONTADO'',''PLAZO'') PLAZO_LIQ,
                DECODE(LIC_MDLDAD_OPRCION_PLZO_ACCNES,''F'',''FINANCIERO'',''E'',''EFECTIVO'',''C'',''CONTADO'',''P'',''PLAZO'','' '') MOD_LIQUIDACION,
                LIC_FIJA_PRECIO_ACCIONES,
                LIC_PERIODO_EXDIVIDENDO,
                DECODE(LIC_INDICADOR_ORIGEN,''P'',''CTA.PROPIA'',''R'',''REC.PROPIOS'',''T'',''TERCER0S'',''P'',''OF.PUNTA'',''M'',''MERCADO'',''E'',''COLECTIVAS'','' '') IND_ORIGEN,
                DECODE(LIC_RFRNCIA_SWAP_CMSNSTA,''00000000'','''',LIC_RFRNCIA_SWAP_CMSNSTA) REF_SWAP,
                LIC_PORCENTAJE_TASA_REPO,
                LIC_PLAZO_REPO,
                LIC_VALOR_CAPTACION_REPO,
                LIC_VOLUMEN_RECOMPRA_REPO,
                LIC_SUCURSAL_CUMPLIMIENTO,
                LIC_VOLUMEN_FRACCION,
                LIC_PRCNTJE_PRCIO_NTO_FRCCION,
                LIC_NMRO_IMPRSNES_LQUDCION,
                LIC_CODIGO_CONTACTO_COMERCIAL,
                LIC_NUMERO_FRACCIONES,
                LIC_REFERENCIA_COMISIONISTA,
                LIC_TIPO_IDENTIFICACION_1,
                LIC_NIT_1,
                LIC_IDNTFCCION_PTRMNIO_AUT_1,
                LIC_TIPO_IDENTIFICACION_2,
                LIC_NIT_2,
                LIC_IDNTFCCION_PTRMNIO_AUT_2,
                LIC_TIPO_IDENTIFICACION_3,
                LIC_NIT_3,
                LIC_IDNTFCCION_PTRMNIO_AUT_3,
                DECODE(LIC_INDICADOR_OPERACION,''I'',''INGRESADA'',''M'',''MODIFICADA'',''A'',''ANULADA'','' '') IND_OPERACION,
                LIC_BASE_RETENCION_COBRO,
                LIC_PORCENTAJE_RET_COBRO,
                LIC_BASE_RETENCION_TRASLADO,
                LIC_PORCENTAJE_RET_TRASLADO,
                LIC_PORCENTAJE_IVA_COMISION,
                LIC_VALOR_IVA_COMISION,
                LIC_TRASLADA_SERV_A_CLIENTE,
                LIC_OP_CON_RETEFTE_ENAJENA,
                LIC_FECHA_CONSTA_VENTA,
                LIC_VALOR_CONSTA_VENTA,
                LIC_GENERA_CONSTA_COMPRADOR,
                LIC_CONTRAPAGO_OPERACION,
                DECODE(LIC_ENVIA_RETEFUENTE,''A'',''RET.AF'',''C'',''RET.CNTRP'',''N'',''SIN.RET'','' '') ENVIA_RTEFTE,
                LIC_PROMOTOR_LIQUIDEZ,
                DECODE(LIC_TIPO_USO_TASA,''A'',''ACTUAL'',''P'',''PREVIA'','' '') TIPO_USO_TASA,
                LIC_NEMO_LARGO,
                LIC_VALOR_EXTEMPO,
                LIC_POSICION_EXTEMPO,
                '''' PAQUETE_BVC,
                LIC_REIV_PRIM,
                LIC_CTA_MARGEN,
                DECODE(OCO_CANAL_ORIGEN,''S2'',''Home Broker''
                                       ,''ACC'',''@cciones Comisionista''
                                       ,''UDF'',''Coeasy Banca Patrimonial''
                                       ,''UDF-A'',''@cciones Banca Patrimonial''
                                       ,''S4'',''Pro Broker''
                                       ,''PLV'',''Oficina Red Banco''
                                       ,''Fix-I'',''Fix Instituc.- Pro Broker''
                                       ,''ACC-E'',''Acc. Etrade - Home Broker''
                                       ,''COEASY'') CANAL_ORIGEN,
                DECODE(OCO_MEDIO_RECEPCION, ''TEL'',''EXTENSION'',
                                            ''FAX'',''FAX'',
                                            ''MSJ'',''MENSAJERIA INSTANTANEA'',
                                            ''COE'',''CORREO ELECTRONICO'',
                                            ''PSE'',''PRESENCIAL CON SOPORTE ESCRITO'',
                                            ''INT'',''INTERNET'',
                                            ''HOM'',''HOMEBROKER'',
                                            ''PRO'',''PROBROKER'',
                                            ''FIX'',''FIXBROKER'',
                                            ''MIL'',''MILA'',
                                            ''BLO'',''BLOOMBERG'',OCO_MEDIO_RECEPCION) MEDIO_RECEPCION,
                (SELECT PER_NOMBRE_USUARIO
                   FROM FILTRO_COMERCIALES
                  WHERE PER_NUM_IDEN = OCO_PER_NUM_IDEN_ES_DUENO 
                    AND PER_TID_CODIGO = OCO_PER_TID_CODIGO_ES_DUENO) COMERCIAL_ORDENA,
                '''' ISIN,
                OCO_FECHA_RECEPCION FECHA_RECEPCION, 
                OCO_HORA_RECEPCION HORA_RECEPCION,  
                OCO_DETALLE_MEDIO_RECEPCION DETALLE_MEDIO_RECEPCION,
                OCO_OBSERVACIONES OBSERVACIONES,
                (SELECT BSC_DESCRIPCION
                   FROM CLIENTES,
                        BI_SEGMENTACION_CLIENTES
                  WHERE CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                    AND CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
                    AND BSC_MNEMONICO = CLI_BSC_MNEMONICO
                    AND BSC_BCC_MNEMONICO = CLI_BSC_BCC_MNEMONICO)  SEGMENTO,
				TO_CHAR(OCO_FECHA_Y_HORA,''DD-MM-YYYY HH24:MI:SS'')  FECHA_REGISTRO,					
				(SELECT NVL(P.PERI_DESCRIPCION,''N/A'')
				FROM   CLIENTES C,  PERFILES_RIESGO P
				WHERE  C.CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
				AND    C.CLI_PER_NUM_IDEN   = CCC_CLI_PER_NUM_IDEN
				AND    C.CLI_PERFIL_RIESGO  = P.PERI_CONSECUTIVO(+)) PERFIL_RIESGO,
				OCO_RLC_PER_TID_CODIGO   RLC_PER_TID_CODIGO,
				OCO_RLC_PER_NUM_IDEN      RLC_PER_NUM_IDEN,
				(SELECT PER.PER_PRIMER_APELLIDO||'' ''|| PER.PER_SEGUNDO_APELLIDO||'' ''|| PER.PER_NOMBRE 
				FROM   PERSONAS_RELACIONADAS RLC, PERSONAS PER 
				WHERE  PER.PER_NUM_IDEN     = RLC.RLC_PER_NUM_IDEN
				AND    PER.PER_TID_CODIGO   = RLC.RLC_PER_TID_CODIGO
				AND    RLC.RLC_PER_NUM_IDEN   = OCO_RLC_PER_NUM_IDEN
				AND    RLC.RLC_PER_TID_CODIGO = OCO_RLC_PER_TID_CODIGO
				AND    RLC.RLC_CLI_PER_NUM_IDEN   = OCO_CCC_CLI_PER_NUM_IDEN
				AND    RLC.RLC_CLI_PER_TID_CODIGO = OCO_CCC_CLI_PER_TID_CODIGO
				AND    RLC.RLC_ROL_CODIGO IN (1,6,7) 
				AND    ROWNUM <=1) ORDENANTE,
				DECODE(ENA_RIESGO_CORREDORES, ''NC'', ''No Comercializable'', ''N'', ''No Aplica'', ENA_RIESGO_CORREDORES) CALIFICA_RIESGO
           FROM EMISORES,
                ESPECIES_NACIONALES,
                PERSONAS PER,
                CUENTAS_CLIENTE_CORREDORES,
                ORDENES_COMPRA,
                LIQUIDACIONES_COMERCIAL LIC,
                PERSONAS PER2,
                PERSONAS_CENTROS_PRODUCCION,
                CENTROS_PRODUCCION
          WHERE ENA_MNEMONICO LIKE '||''''||P_ESPECIE||''' 
            AND LIC_MNEMOTECNICO_TITULO = ENA_MNEMONICO
            AND EMI_MNEMONICO LIKE '||''''||P_EMISOR||''' 
            AND ENA_EMI_MNEMONICO = EMI_MNEMONICO
            AND CCC_PER_NUM_IDEN = PER.PER_NUM_IDEN 
            AND CCC_PER_TID_CODIGO = PER.PER_TID_CODIGO '||
            P_CONDICION_ESPECULATIVA ||
          ' AND OCO_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN 
            AND OCO_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO 
            AND OCO_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA 
            AND OCO_PER_NUM_IDEN = PER2.PER_NUM_IDEN
            AND OCO_PER_TID_CODIGO = PER2.PER_TID_CODIGO
            AND LIC_BOL_MNEMONICO   = OCO_BOL_MNEMONICO      
            AND LIC_OCO_COC_CTO_MNEMONICO =   OCO_COC_CTO_MNEMONICO   
            AND LIC_OCO_CONSECUTIVO  = OCO_CONSECUTIVO   '||
            P_CONDICION ||
          ' AND LIC_TIPO_OPERACION = ''C''
            AND LIC_MERCADO LIKE '||''''||P_MERCADO||''' 
            AND LIC_BOL_MNEMONICO LIKE '||''''||P_BOLSA||''' 
            AND CCC_PER_NUM_IDEN = PCP_PER_NUM_IDEN
            AND CCC_PER_TID_CODIGO = PCP_PER_TID_CODIGO 
            AND PCP_PRINCIPAL = ''S''
            AND PCP_CPR_MNEMONICO = CPR_MNEMONICO';

  v_archivo := utl_file.fopen ('TEMPSQL', 'test_utl_file.txt', 'w');
  utl_file.put_line (v_archivo, v_query);
  utl_file.fclose(v_archivo); 

   EXECUTE IMMEDIATE(V_QUERY);

   COMMIT;

END P_CALCULA_DATOS;

/********************************************************/
--SWIFT BANCOS - ESTIMACION SALDOS  SMORALES
/********************************************************/
PROCEDURE P_CUENTAS_BANCARIAS (P_FECHA DATE) IS 
 V_SALDO_INICIAL    NUMBER(22,2);
 V_CHEQUES_X_COBRAR NUMBER(22,2);
 V_CHEQUES_GIRADOS  NUMBER(22,2);
 V_CUPO_INTRADIA    NUMBER(22,2);
 V_SALDO_ESTIMADO   NUMBER(22,2);



 BEGIN 

 /*
 V_SALDO_INICIAL    := 0;
 V_CHEQUES_X_COBRAR := 0;
 V_CHEQUES_GIRADOS  := 0;
 V_CUPO_INTRADIA    := 0;
 V_SALDO_ESTIMADO   := 0;


 V_SALDO_INICIAL    := P_OPERACIONES.FN_SALDO_INICIAL (TRUNC(SYSDATE) , CBA.CBA_BAN_CODIGO,CBA.CBA_NUMERO_CUENTA); 
 V_CHEQUES_X_COBRAR := P_OPERACIONES.FN_CHEQUES_X_COBRAR(TRUNC(SYSDATE) , CBA.CBA_BAN_CODIGO,CBA.CBA_NUMERO_CUENTA);
 V_CHEQUES_GIRADOS  := P_OPERACIONES.FN_CHEQUES_GIRADOS(TRUNC(SYSDATE) , CBA.CBA_BAN_CODIGO,CBA.CBA_NUMERO_CUENTA);
 V_CUPO_INTRADIA    := P_OPERACIONES.FN_CUPO_INTRADIA(TRUNC(SYSDATE) , CBA.CBA_BAN_CODIGO,CBA.CBA_NUMERO_CUENTA,CBA.CBA_NEG_CONSECUTIVO);

 V_SALDO_ESTIMADO   := V_SALDO_INICIAL + V_CHEQUES_X_COBRAR +  V_CHEQUES_GIRADOS +  V_CUPO_INTRADIA ;            
 */             


    INSERT INTO TMP_SALDO_ESTIMADO 
    (  FECHA
      ,CBA_BAN_CODIGO                 
      ,BAN_NOMBRE                    
      ,CBA_NUMERO_CUENTA             
      ,CBA_SUC_CODIGO                 
      ,CBA_NEG_CONSECUTIVO           
      ,NEG_DESCRIPCION                
      ,CBA_TCB_MNEMONICO              
      ,CBA_ESTADO     

    ) SELECT    P_FECHA  
               ,CBA.CBA_BAN_CODIGO
               ,BAN.BAN_NOMBRE
               ,CBA.CBA_NUMERO_CUENTA
               ,CBA.CBA_SUC_CODIGO
               ,CBA.CBA_NEG_CONSECUTIVO
               ,NEG.NEG_DESCRIPCION
               ,CBA.CBA_TCB_MNEMONICO
               ,CBA.CBA_ESTADO

          FROM CUENTAS_BANCARIAS_CORREDORES CBA
               ,BANCOS BAN
               ,NEGOCIOS NEG
        WHERE  CBA.CBA_NEG_CONSECUTIVO = NEG.NEG_CONSECUTIVO
          AND  CBA.CBA_BAN_CODIGO = BAN.BAN_CODIGO
          AND  CBA.CBA_ESTADO = 'A'; 


END P_CUENTAS_BANCARIAS; 

FUNCTION FN_SALDO_INICIAL (P_FECHA IN DATE, 
                           P_COD_BANCO IN NUMBER, 
                           P_CTA_BANCARIA IN VARCHAR2)   RETURN NUMBER IS
   CURSOR C_SALDO IS
       SELECT SCC_SALDO_MVTOS_CONCILIADOS + SCC_SALDO_MVTOS_NO_CONCILIADOS SCC_SALDO
             ,SCC_FECHA
         FROM  SALDOS_CTA_BANCARIA_CORREDORES
        WHERE SCC_CBA_BAN_CODIGO = P_COD_BANCO 
          AND SCC_CBA_NUMERO_CUENTA = P_CTA_BANCARIA 
          AND SCC_FECHA < P_FECHA + 1 -- TRUNC(TO_DATE(P_FECHA,'DD-MON-YYYY') + 1)
          AND SCC_CONFIRMADO = 'S'
        ORDER BY SCC_FECHA DESC;
   SCC    C_SALDO%ROWTYPE;

   CURSOR C_MOVIMIENTOS IS
      SELECT SUM(MCB_MONTO)
        FROM MOVIMIENTOS_CUENTAS_BANCARIAS
       WHERE  MCB_CBA_BAN_CODIGO = P_COD_BANCO
         AND  MCB_CBA_NUMERO_CUENTA = P_CTA_BANCARIA
         AND  MCB_FECHA >= TRUNC(SCC.SCC_FECHA)
         AND  MCB_FECHA < P_FECHA ;-- TRUNC(TO_DATE(P_FECHA,'DD-MON-YYYY'));

   CURSOR C_MOVIMIENTOS1 IS
      SELECT SUM(MCB_MONTO)
        FROM MOVIMIENTOS_CUENTAS_BANCARIAS
       WHERE MCB_CBA_BAN_CODIGO = P_COD_BANCO
         AND MCB_CBA_NUMERO_CUENTA = P_CTA_BANCARIA
         AND MCB_FECHA < P_FECHA ; -- TRUNC(TO_DATE(P_FECHA,'DD-MON-YYYY'));
   MONTO  NUMBER;

BEGIN
   OPEN   C_SALDO;
   FETCH  C_SALDO INTO SCC;
   CLOSE  C_SALDO;

   IF SCC.SCC_FECHA IS NULL THEN
      OPEN  C_MOVIMIENTOS1;
      FETCH C_MOVIMIENTOS1 INTO MONTO;
      CLOSE C_MOVIMIENTOS1;
        RETURN NVL(MONTO,0);
   ELSE
      IF TRUNC(SCC.SCC_FECHA) = P_FECHA THEN
          -- TRUNC(TO_DATE(P_FECHA,'DD-MON-YYYY')) 
         RETURN NVL(SCC.SCC_SALDO,0);
      ELSE
         OPEN   C_MOVIMIENTOS;
         FETCH  C_MOVIMIENTOS INTO MONTO;
         CLOSE  C_MOVIMIENTOS;
            RETURN NVL(SCC.SCC_SALDO,0) + NVL(MONTO,0);
      END IF;
   END IF;

END FN_SALDO_INICIAL;

FUNCTION FN_CHEQUES_X_COBRAR (P_FECHA         IN DATE, 
                              P_COD_BANCO     IN NUMBER, 
                              P_CTA_BANCARIA  IN VARCHAR2)   RETURN NUMBER IS

   CURSOR C_CHEQUES_COBRAR IS 
	   SELECT  NVL(SUM(MCB_MONTO),0) VR_CHEQUES
	     FROM  MOVIMIENTOS_CUENTAS_BANCARIAS
				     ,COMPROBANTES_DE_EGRESO
				     ,TIPOS_MOVIMIENTOS_BANCOS
			WHERE  MCB_TMB_MNEMONICO = TMB_MNEMONICO
				AND  MCB_FECHA <= P_FECHA --TRUNC(:FILTRO.FECHA_OPERACION)
				AND  MCB_CEG_CONSECUTIVO = CEG_CONSECUTIVO  (+)
				AND  MCB_CBA_BAN_CODIGO = CEG_CBA_BAN_CODIGO (+)
				AND  MCB_CBA_NUMERO_CUENTA = CEG_CBA_NUMERO_CUENTA (+)
				AND  MCB_SUC_CODIGO = CEG_SUC_CODIGO (+)
				AND  MCB_NEG_CONSECUTIVO = CEG_NEG_CONSECUTIVO (+)
				AND  MCB_CBA_NUMERO_CUENTA = P_CTA_BANCARIA --:CBC.CBA_NUMERO_CUENTA
				AND  MCB_CBA_BAN_CODIGO = P_COD_BANCO --:CBC.CBA_BAN_CODIGO
				and  MCB_TMB_MNEMONICO IN ('PCHE', 'PCHET')
				AND  ((MCB_CONCILIADO = 'N')
				       OR (MCB_CONCILIADO = 'S'  
               AND MCB_FECHA_CONCILIACION >= P_FECHA + 1 ));-- TRUNC(:FILTRO.FECHA_OPERACION)+1)
   C_CHEQ_CON C_CHEQUES_COBRAR%ROWTYPE ; 

BEGIN

	OPEN  C_CHEQUES_COBRAR; 
	FETCH C_CHEQUES_COBRAR INTO C_CHEQ_CON;
	      RETURN(NVL(-(C_CHEQ_CON.VR_CHEQUES),0));
	CLOSE C_CHEQUES_COBRAR;

END FN_CHEQUES_X_COBRAR; 

FUNCTION FN_CHEQUES_GIRADOS ( P_FECHA         IN DATE, 
                              P_COD_BANCO     IN NUMBER, 
                              P_CTA_BANCARIA  IN VARCHAR2)   RETURN NUMBER IS 

   CURSOR C_CHEQUES_GIRADOS IS 
      SELECT    MCB.MCB_CBA_BAN_CODIGO     
               ,MCB.MCB_CBA_NUMERO_CUENTA 
               ,MCB.MCB_FECHA              
               ,MCB.MCB_TMB_MNEMONICO      
               ,MCB.MCB_MONTO MONTO             
               ,MCB.MCB_SUC_CODIGO                 
               ,MCB.MCB_NEG_CONSECUTIVO       
        FROM    MOVIMIENTOS_CUENTAS_BANCARIAS     MCB
               ,TIPOS_MOVIMIENTOS_BANCOS          TMB
			 WHERE    MCB.MCB_TMB_MNEMONICO = TMB.TMB_MNEMONICO  
			   AND    MCB.MCB_CBA_NUMERO_CUENTA = P_CTA_BANCARIA --:CBC.CBA_NUMERO_CUENTA
			   AND    MCB.MCB_CBA_BAN_CODIGO = P_COD_BANCO --:CBC.CBA_BAN_CODIGO
			--AND   MCB.MCB_NEG_CONSECUTIVO = :CBC.CBA_NEG_CONSECUTIVO
			   AND 	  MCB.MCB_FECHA >=  P_FECHA    --TRUNC(:FILTRO.FECHA_OPERACION)
			   AND    MCB.MCB_FECHA <   P_FECHA + 1;  --TRUNC(:FILTRO.FECHA_OPERACION +1);
	 R_CHEQ_GIR C_CHEQUES_GIRADOS%ROWTYPE;

	 SUM_DEBITOS NUMBER; 
	 SUM_CREDITOS NUMBER; 
	 TOT_CHEQ_GIR NUMBER;

BEGIN
	SUM_DEBITOS := 0;
  SUM_CREDITOS := 0;
	OPEN C_CHEQUES_GIRADOS; 
	FETCH C_CHEQUES_GIRADOS INTO R_CHEQ_GIR; 

	 WHILE C_CHEQUES_GIRADOS%FOUND LOOP
	 	  IF R_CHEQ_GIR.MONTO > 0 THEN 
	 	  	 SUM_CREDITOS := SUM_CREDITOS + R_CHEQ_GIR.MONTO; 
	 	  ELSIF R_CHEQ_GIR.MONTO < 0 THEN 
	 	  	 SUM_DEBITOS := SUM_DEBITOS + (-1 * R_CHEQ_GIR.MONTO);
	 	  ELSE	 
	 	  	 SUM_CREDITOS := SUM_CREDITOS + 0; 
	 	  	 SUM_DEBITOS := SUM_DEBITOS + 0;
	 	  END IF;	 
	 FETCH C_CHEQUES_GIRADOS INTO R_CHEQ_GIR;
   END LOOP;
  CLOSE C_CHEQUES_GIRADOS;	

	TOT_CHEQ_GIR := SUM_CREDITOS - SUM_DEBITOS;
	RETURN(NVL(TOT_CHEQ_GIR,0));

END FN_CHEQUES_GIRADOS;

FUNCTION FN_CUPO_INTRADIA (
                           P_FECHA         IN DATE, 
                           P_COD_BANCO     IN NUMBER, 
                           P_CTA_BANCARIA  IN VARCHAR2,
                           P_NEG_CONSECUTIVO IN NUMBER) RETURN NUMBER IS

   CURSOR C_VWCB IS
      SELECT  VWCB_NEG_CONSECUTIVO
             ,NEG_DESCRIPCION
             ,VWCB_CBA_BAN_CODIGO
             ,BAN_NOMBRE
             ,VWCB_CBA_NUMERO_CUENTA
             ,VWCB_CBA_CUPO_INTRADIA
        FROM  VW_CUPOS_BANCOS,
              BANCOS,
              NEGOCIOS
       WHERE  VWCB_CBA_BAN_CODIGO = BAN_CODIGO
         AND  VWCB_NEG_CONSECUTIVO = NEG_CONSECUTIVO
         AND  VWCB_CBA_NUMERO_CUENTA = P_CTA_BANCARIA
         AND  (P_NEG_CONSECUTIVO = 0 
                OR (P_NEG_CONSECUTIVO != 0 
                AND VWCB_NEG_CONSECUTIVO = P_NEG_CONSECUTIVO))
         AND  (TO_CHAR(P_COD_BANCO) = '%' 
               OR (TO_CHAR(P_COD_BANCO) != '%' 
               AND VWCB_CBA_BAN_CODIGO  = TO_NUMBER(P_COD_BANCO)));
   R_VWCB C_VWCB%ROWTYPE;        

   CURSOR C_CDCT IS
		      SELECT  CDCT_CONSECUTIVO
		             ,CDCT_NEG_CONSECUTIVO
		             ,NEG_DESCRIPCION
		             ,CDCT_CBA_BAN_CODIGO
		             ,BAN_NOMBRE
		             ,CDCT_CBA_NUMERO_CUENTA
		             ,CDCT_FECHA
		             ,CDCT_CUPO_INTRADIA
		      FROM CUPOS_DIARIOS_CUENTAS,
		           CUENTAS_BANCARIAS_CORREDORES,
		           NEGOCIOS,
		           BANCOS
		      WHERE CDCT_CBA_BAN_CODIGO = CBA_BAN_CODIGO
		        AND CDCT_CBA_NUMERO_CUENTA = CBA_NUMERO_CUENTA
		        AND CBA_NEG_CONSECUTIVO = NEG_CONSECUTIVO
		        AND CBA_BAN_CODIGO = BAN_CODIGO
		        AND CDCT_FECHA >= P_FECHA --TRUNC(:FILTRO.FECHA_OPERACION)
		        AND CDCT_FECHA <  P_FECHA + 1 --TRUNC(:FILTRO.FECHA_OPERACION+1)
		        AND CDCT_CBA_NUMERO_CUENTA = P_CTA_BANCARIA 
		        AND (P_NEG_CONSECUTIVO = 0 
                  OR(P_NEG_CONSECUTIVO != 0 
                  AND CDCT_NEG_CONSECUTIVO = P_NEG_CONSECUTIVO))
		        AND (TO_CHAR(P_COD_BANCO) = '%' 
                 OR (TO_CHAR(P_COD_BANCO) != '%' 
                 AND CDCT_CBA_BAN_CODIGO  = TO_NUMBER(P_COD_BANCO)));
   R_CDCT C_CDCT%ROWTYPE;

   CURSOR C_CDCT_TIPO IS
    SELECT CDCT_CONSECUTIVO    
      FROM CUPOS_DIARIOS_CUENTAS
     WHERE CDCT_FECHA >= P_FECHA  --TRUNC(:FILTRO.FECHA_OPERACION)
       AND CDCT_FECHA <  P_FECHA +1 ;  --TRUNC(:FILTRO.FECHA_OPERACION + 1);
   CONS NUMBER;       

   V_CUPO_INTRADIA NUMBER (22,2);
   V_TIPO   VARCHAR2 (3); 

BEGIN

   OPEN   C_CDCT_TIPO;
   FETCH  C_CDCT_TIPO INTO CONS;
     IF   C_CDCT_TIPO%FOUND THEN
            V_TIPO := 'OLD';
     ELSE 
            V_TIPO := 'NEW';
     END IF; 	
   CLOSE  C_CDCT_TIPO;

   IF V_TIPO = 'NEW' THEN   	
      OPEN C_VWCB;
      FETCH C_VWCB INTO R_VWCB;
      	V_CUPO_INTRADIA := R_VWCB.VWCB_CBA_CUPO_INTRADIA;
      CLOSE C_VWCB;
   ELSIF V_TIPO = 'OLD' THEN   	
      OPEN C_CDCT;
      FETCH C_CDCT INTO R_CDCT;
        	V_CUPO_INTRADIA := R_CDCT.CDCT_CUPO_INTRADIA;
      CLOSE C_CDCT;
   END IF;
   RETURN (V_CUPO_INTRADIA); 

END FN_CUPO_INTRADIA ;

END P_OPERACIONES;

/

  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "JSUTACHA";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "SIS_SISTEMAS";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "YLADINO";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "SVELANDIA";
  GRANT EXECUTE ON "PROD"."P_OPERACIONES" TO "AUD_AUDITORIA";
