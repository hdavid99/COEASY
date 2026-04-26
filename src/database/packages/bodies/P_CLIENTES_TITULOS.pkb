--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_CLIENTES_TITULOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_CLIENTES_TITULOS" IS  

PROCEDURE GENERAR_SALDOS_DIA IS
   -- ESTE PROCEDIMIENTO SE LLAMA DESDE EL CRON DE LOS NOCTURNOS
   -- SE GENERAN LOS SALDOS DECEVAL Y DCV PARA CLIENTES CON EL PROCEDIMIENTO CREAR_SALDOS_DIA.
   -- EL PROCESO CORRE SOLO SI SE REALIZA EN UNA HORA MENOR A LA HORA_LIMITE
   -- SI SE SUPERA LA HORA_LIMITE SE DEBE CORRER EL PROCESO CREAR_SALDOS_FECHA Y SE ENVIA COMO PARAMETRO LA FECHA QUE SE DEBE GENERAR.
   -- SI ES FIN DE MES SE GUARDA LA INFORMACION. SE BORRAN LOS DATOS PARA FECHA DIFERENTE A FIN DE MES

   HORA_LIMITE VARCHAR2(8):= '18:00:00';   --HORA LIMITE PARA CORRER CREAR_SALDOS_DIA (dia de 24 horas)
   P_FECHA_HOY DATE;
   FECHA_A_PROCESAR DATE;

   CURSOR C_EXISTE (QFECHA DATE) IS
      SELECT 'S'
      FROM HISTORICOS_SALDOS_TITULOS
      WHERE HST_FECHA >= TRUNC(QFECHA)
        AND HST_FECHA <  TRUNC(QFECHA+1);
   SINO VARCHAR2(1);        

   NO_PROCESO EXCEPTION;
   YA_EXISTE  EXCEPTION;
   P_NUM_INI  NUMBER;
   P_NUM_FIN  NUMBER; 

BEGIN

 P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.GENERAR_SALDOS_DIA','INI');
   SELECT SYSDATE INTO P_FECHA_HOY FROM DUAL;
   IF P_FECHA_HOY < TO_DATE(TO_CHAR(P_FECHA_HOY,'DD-MON-YYYY')||' '||HORA_LIMITE,'DD-MON-YYYY HH24:MI:SS') THEN
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
         P_CLIENTES_TITULOS.CREAR_SALDOS_DIA;
         -- PROCEDIMIENTO PARA VALORAR EL PORTAFOLIO
         P_CLIENTES_TITULOS.VALORAR_SALDOS_DIA(FECHA_A_PROCESAR);

         --BORRAR LA INFORMACION < A LA FECHA SI ES DIFERENTE A FIN DE MES
         ---P_CLIENTES_TITULOS.BORRAR_DIFERENTE_FIN_MES(FECHA_A_PROCESAR);

         --SE ENVIA MAIL CON TITULOS NO VALORADOS O QUE SE VALORAN POR TIR
         P_CLIENTES_TITULOS.MAIL_TITULOS_VALORADOS(FECHA_A_PROCESAR);

      ELSE
         RAISE YA_EXISTE;
      END IF;
   ELSE
      RAISE NO_PROCESO;
   END IF;

      -- BORRADO DE TABLAS DE VALORACION TMP CARGUES ANTERIORES : SE DEJA EL ULTIMO AÑO
   DELETE FROM TMP_MARGENES_VALORACION
   WHERE   TMV_FECHA_REGISTRO <= TRUNC(P_FECHA_HOY-365);  --  -8); 

   DELETE FROM TMP_CERO_CUPON_VALORACION
   WHERE CCV_FECHA_OPERACION <= TRUNC(P_FECHA_HOY-365);  --  -8);

   DELETE FROM TMP_BLOOMBERG_VALORACION
   WHERE TBV_FECHA_ARCHIVO <= TRUNC(P_FECHA_HOY-365);  --  -8);

   DELETE FROM TMP_PRECIOS_VALORACION
   WHERE TPV_FECHA_REGISTRO <= TRUNC(P_FECHA_HOY-365);  --  -8);

   DELETE FROM TMP_INDICES_VALORACION
   WHERE TIV_FECHA <= TRUNC(P_FECHA_HOY-365);  --  -8);

   P_MAIL.envio_mail_error('CREAR_SALDOS_DIA EXITOSO','Proceso de Generacion de Saldos de Titulos de Clientes EXITOSO');

   P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.GENERAR_SALDOS_DIA','FIN');

   COMMIT;  

EXCEPTION
     WHEN NO_PROCESO THEN
        P_MAIL.envio_mail_error('Proceso CREAR_SALDOS_DIA','Se supero la hora limite para correr el proceso CREAR_SALDOS_DIA. Se debe correr CREAR_SALDOS_FECHA en forma manual');
        RAISE_APPLICATION_ERROR(-20001,'Se supero la hora limite para correr el proceso CREAR_SALDOS_DIA. Se debe correr CREAR_SALDOS_FECHA en forma manual');
     WHEN YA_EXISTE THEN
        P_MAIL.envio_mail_error('Proceso CREAR_SALDOS_DIA','Ya se generó el saldo para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
        RAISE_APPLICATION_ERROR(-20002,'Ya se generó el saldo para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso CREAR_SALDOS_DIA','Error en procedimiento GENERAR_SALDOS_DIA: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento GENERAR_SALDOS_DIA: '||sqlerrm);

END GENERAR_SALDOS_DIA;

PROCEDURE CREAR_SALDOS_DIA IS
   -- PROCEDIMIENTO PARA GENERAR LOS SALDOS EN DECEVAL Y DCV POR CUENTA_CLIENTE_CORREDORES A LA FECHA

   FECHA DATE;
   CURSOR C_CONS IS
      SELECT NVL(MAX(HST_CONSECUTIVO),0) CONS
      FROM HISTORICOS_SALDOS_TITULOS;
   CONSECUTIVO NUMBER;

   CURSOR C_CFC IS
      SELECT CFC_CCC_CLI_PER_NUM_IDEN
            ,CFC_CCC_CLI_PER_TID_CODIGO
            ,CFC_CCC_NUMERO_CUENTA
            ,CFC_CUENTA_DECEVAL
            ,CFC_FUG_ISI_MNEMONICO
            ,CFC_FUG_MNEMONICO
            ,CFC_SALDO_DCVAL_DISPONIBLE
            ,CFC_SALDO_DCVAL_GARANTIA
            ,CFC_SALDO_DCVAL_EMBARGADO
            ,CFC_SALDO_DCVAL_GAR_REPO       
            ,CFC_SALDO_DCVAL_POR_CUMPLIR
            ,CFC_SALDO_COMPRA_X_CUMPLIR
            ,CFC_COSTO_PROMEDIO_COMPRA
            ,CFC_SALDO_DCVAL_TRANSITO_ING
            ,CFC_SALDO_DCVAL_TRANSITO_RET
            ,CFC_SALDO_DCVAL_GARANTIA_DER
            ,CFC_SALDO_TTV_COMPRA_FINAL
            ,CFC_SALDO_TTV_VENTA_FINAL
            ,CFC_SALDO_TTV_GARANT_RECEPTOR
            ,CFC_SALDO_TTV_GARANT_COLOCADOR
            ,CFC_SALDO_CRCC_RETARDO                            -- OMORA
      FROM CUENTAS_FUNGIBLE_CLIENTE
      WHERE (CFC_SALDO_DCVAL_DISPONIBLE != 0
         OR CFC_SALDO_DCVAL_GARANTIA   != 0
         OR CFC_SALDO_DCVAL_EMBARGADO != 0
         OR CFC_SALDO_DCVAL_GAR_REPO != 0
         OR CFC_SALDO_DCVAL_POR_CUMPLIR != 0
		     OR CFC_SALDO_COMPRA_X_CUMPLIR != 0 
         OR CFC_SALDO_DCVAL_TRANSITO_ING != 0
         OR CFC_SALDO_DCVAL_TRANSITO_RET != 0
         OR CFC_SALDO_DCVAL_GARANTIA_DER != 0
         OR CFC_SALDO_TTV_COMPRA_FINAL != 0
         OR CFC_SALDO_TTV_VENTA_FINAL != 0
         OR CFC_SALDO_TTV_GARANT_RECEPTOR != 0
         OR CFC_SALDO_TTV_GARANT_COLOCADOR != 0
         OR CFC_SALDO_CRCC_RETARDO != 0)                       -- OMORA
         AND NOT EXISTS (SELECT 'X'
                FROM ISINS_ESPECIES,
                     PARAMETROS_FONDOS
                WHERE ISE_ISI_MNEMONICO = CFC_FUG_ISI_MNEMONICO
                  AND ISE_ENA_MNEMONICO = PFO_RANGO_MIN_CHAR
                  AND PFO_PAR_CODIGO = 52);
   R_CFC C_CFC%ROWTYPE;       

   CURSOR C_TLO IS
      SELECT TLO_CCC_CLI_PER_NUM_IDEN
            ,TLO_CCC_CLI_PER_TID_CODIGO
            ,TLO_CCC_NUMERO_CUENTA
            ,TLO_TYPE
            ,TLO_ETC_MNEMONICO
            ,TLO_CODIGO
            ,TLO_CANTIDAD
            ,TLO_VALOR_NOMINAL
      FROM TITULOS TLO
      WHERE TLO.TLO_ETC_MNEMONICO IN ('DIS','GAR','TRI','TRR','GAD','GAI')
        AND TLO.TLO_LTI_MNEMONICO IN ('DV','FI')
        AND TLO.TLO_PORTAFOLIO = 'S'
        AND NOT EXISTS (SELECT 'X'
                        FROM PARAMETROS_FONDOS 
                        WHERE PFO_PAR_CODIGO = 52 
                          AND PFO_RANGO_MIN_CHAR = TLO_ENA_MNEMONICO);
   R_TLO C_TLO%ROWTYPE;
   VALOR_DISPONIBLE NUMBER;
   VALOR_GARANTIA NUMBER;
   VALOR_TRI NUMBER;
   VALOR_TRR  NUMBER;
   VALOR_GDER NUMBER;
   BORRAR VARCHAR2(1) := 'N';
BEGIN
     SELECT TRUNC(SYSDATE)-1 INTO FECHA FROM DUAL;

   OPEN C_CONS;
   FETCH C_CONS INTO CONSECUTIVO;
   CLOSE C_CONS;
   CONSECUTIVO := NVL(CONSECUTIVO,0);

   OPEN C_CFC;
   FETCH C_CFC INTO R_CFC;
   WHILE C_CFC%FOUND LOOP
         CONSECUTIVO := CONSECUTIVO + 1;
      INSERT INTO HISTORICOS_SALDOS_TITULOS
            (HST_CONSECUTIVO                
            ,HST_FECHA                      
            ,HST_CCC_CLI_PER_NUM_IDEN       
            ,HST_CCC_CLI_PER_TID_CODIGO
            ,HST_CCC_NUMERO_CUENTA          
            ,HST_SALDO_DISPONIBLE           
            ,HST_SALDO_GARANTIA             
            ,HST_SALDO_EMBARGO   
            ,HST_SALDO_GARANTIA_REPO
            ,HST_SALDO_POR_CUMPLIR             
			      ,HST_SALDO_CPR_X_CUMPLIR 
            ,HST_VALOR_TM_DISPONIBLE        
            ,HST_VALOR_TM_GARANTIA          
            ,HST_VALOR_TM_EMBARGO           
            ,HST_CFC_FUG_ISI_MNEMONICO      
            ,HST_CFC_FUG_MNEMONICO          
            ,HST_CFC_CUENTA_DECEVAL
            ,HST_COSTO_PROMEDIO_COMPRA
            ,HST_SALDO_TRANSITO_ING
            ,HST_SALDO_TRANSITO_RET
            ,HST_SALDO_GARANTIA_DER
            ,HST_VALOR_TM_GARREPO   
            ,HST_VALOR_TM_XCUMPLIR  
			      ,HST_VALOR_TM_CPR_X_CUMPLIR
            ,HST_VALOR_TM_TRANING   
            ,HST_VALOR_TM_TRANRET   
            ,HST_VALOR_TM_GARDER
            ,HST_CFC_SALDO_TTV_COMPRA_FINAL                                                                                                                                                                                  
            ,HST_CFC_SALDO_TTV_VENTA_FINAL                                                                                                                                                                                  
            ,HST_CFC_SALDO_TTV_GARANT_REC                                                                                                                                                               
            ,HST_CFC_SALDO_TTV_GARANT_COL
            ,HST_SALDO_RETARDO                                    -- OMORA
			,HST_VALOR_TM_RETARDO)                                -- OMORA
      VALUES (
             CONSECUTIVO
            ,FECHA
            ,R_CFC.CFC_CCC_CLI_PER_NUM_IDEN
            ,R_CFC.CFC_CCC_CLI_PER_TID_CODIGO
            ,R_CFC.CFC_CCC_NUMERO_CUENTA
            ,R_CFC.CFC_SALDO_DCVAL_DISPONIBLE
            ,R_CFC.CFC_SALDO_DCVAL_GARANTIA
            ,R_CFC.CFC_SALDO_DCVAL_EMBARGADO          
            ,R_CFC.CFC_SALDO_DCVAL_GAR_REPO       
            ,R_CFC.CFC_SALDO_DCVAL_POR_CUMPLIR
			      ,R_CFC.CFC_SALDO_COMPRA_X_CUMPLIR
            ,0
            ,0
            ,0
            ,R_CFC.CFC_FUG_ISI_MNEMONICO
            ,R_CFC.CFC_FUG_MNEMONICO
            ,R_CFC.CFC_CUENTA_DECEVAL
            ,R_CFC.CFC_COSTO_PROMEDIO_COMPRA
            ,R_CFC.CFC_SALDO_DCVAL_TRANSITO_ING   
            ,R_CFC.CFC_SALDO_DCVAL_TRANSITO_RET
            ,R_CFC.CFC_SALDO_DCVAL_GARANTIA_DER
            ,0
            ,0
            ,0
            ,0
            ,0
			      ,0
            ,R_CFC.CFC_SALDO_TTV_COMPRA_FINAL                                                                                                                                                                                  
            ,R_CFC.CFC_SALDO_TTV_VENTA_FINAL                                                                                                                                                                                  
            ,R_CFC.CFC_SALDO_TTV_GARANT_RECEPTOR                                                                                                                                                               
            ,R_CFC.CFC_SALDO_TTV_GARANT_COLOCADOR
            ,R_CFC.CFC_SALDO_CRCC_RETARDO                 -- OMORA
			,0);                                          -- OMORA
      FETCH C_CFC INTO R_CFC;
   END LOOP;      
   CLOSE C_CFC;

   OPEN C_TLO;
   FETCH C_TLO INTO R_TLO;
   WHILE C_TLO%FOUND LOOP
      CONSECUTIVO := CONSECUTIVO + 1;
      IF R_TLO.TLO_ETC_MNEMONICO IN ('DIS','GAI') THEN
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := R_TLO.TLO_CANTIDAD;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;
         ELSE
            VALOR_DISPONIBLE := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'GAR' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := R_TLO.TLO_CANTIDAD;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'TRI' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := R_TLO.TLO_CANTIDAD;
            VALOR_TRR := 0;
            VALOR_GDER := 0;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_TRR := 0;
            VALOR_GDER := 0;            
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'TRR' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA :=0;
            VALOR_TRI := 0;
            VALOR_TRR :=  R_TLO.TLO_CANTIDAD;
            VALOR_GDER := 0;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_GDER := 0;
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'GAD' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := R_TLO.TLO_CANTIDAD;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA :=0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER :=  R_TLO.TLO_VALOR_NOMINAL;
         END IF;
      ELSE
         VALOR_DISPONIBLE := 0;
         VALOR_GARANTIA := 0;
         VALOR_TRI := 0;
         VALOR_TRR := 0;
         VALOR_GDER := 0;
      END IF;       

      IF VALOR_DISPONIBLE != 0 OR VALOR_GARANTIA != 0 
         OR VALOR_TRI != 0 OR VALOR_TRR != 0 OR  VALOR_GDER != 0 	THEN
         INSERT INTO HISTORICOS_SALDOS_TITULOS
               (HST_CONSECUTIVO                
               ,HST_FECHA                      
               ,HST_CCC_CLI_PER_NUM_IDEN       
               ,HST_CCC_CLI_PER_TID_CODIGO
               ,HST_CCC_NUMERO_CUENTA          
               ,HST_SALDO_DISPONIBLE           
               ,HST_SALDO_GARANTIA             
               ,HST_SALDO_EMBARGO              
               ,HST_VALOR_TM_DISPONIBLE        
               ,HST_VALOR_TM_GARANTIA          
               ,HST_VALOR_TM_EMBARGO           
               ,HST_TLO_CODIGO
               ,HST_COSTO_PROMEDIO_COMPRA
               ,HST_SALDO_TRANSITO_ING 
               ,HST_SALDO_TRANSITO_RET 
               ,HST_SALDO_GARANTIA_DER 
               ,HST_VALOR_TM_GARREPO   
               ,HST_VALOR_TM_XCUMPLIR  
			         ,HST_VALOR_TM_CPR_X_CUMPLIR 
               ,HST_VALOR_TM_TRANING   
               ,HST_VALOR_TM_TRANRET   
               ,HST_VALOR_TM_GARDER
               ,HST_CFC_SALDO_TTV_COMPRA_FINAL                                                                                                                                                                                  
               ,HST_CFC_SALDO_TTV_VENTA_FINAL                                                                                                                                                                                  
               ,HST_CFC_SALDO_TTV_GARANT_REC                                                                                                                                                               
               ,HST_CFC_SALDO_TTV_GARANT_COL)
         VALUES (
                CONSECUTIVO
               ,FECHA
               ,R_TLO.TLO_CCC_CLI_PER_NUM_IDEN
               ,R_TLO.TLO_CCC_CLI_PER_TID_CODIGO
               ,R_TLO.TLO_CCC_NUMERO_CUENTA
               ,VALOR_DISPONIBLE
               ,VALOR_GARANTIA
               ,0
               ,0
               ,0
               ,0
               ,R_TLO.TLO_CODIGO
               ,0
               ,VALOR_TRI
               ,VALOR_TRR
               ,VALOR_GDER
               ,0
               ,0
               ,0
               ,0
               ,0
			         ,0
               ,0                                                                                                                                                                                  
               ,0                                                                                                                                                                                  
               ,0                                                                                                                                                               
               ,0);
      END IF;

      FETCH C_TLO INTO R_TLO;
   END LOOP;
   CLOSE C_TLO;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso CREAR_SALDO_DIA','Error en procedimiento SALDOS_TITULOS_CLIENTES: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20004,'Error en procedimiento SALDOS_TITULOS_CLIENTES: '||sqlerrm);
END CREAR_SALDOS_DIA; 


PROCEDURE BORRAR_DIFERENTE_FIN_MES
   (P_FECHA IN  DATE) IS
    ULT_FIN_MES DATE;     -- FECHA DEL ULTIMO FIN DE MES INGRESADO

   CURSOR C_FECHA IS
      SELECT DISTINCT HST_FECHA
      FROM HISTORICOS_SALDOS_TITULOS
      WHERE HST_FECHA >= TRUNC(ULT_FIN_MES + 1)
        AND HST_FECHA < TRUNC(P_FECHA);
   R_FECHA C_FECHA%ROWTYPE;            

BEGIN
   SELECT LAST_DAY(ADD_MONTHS(P_FECHA,-1)) INTO ULT_FIN_MES FROM DUAL;
   DBMS_OUTPUT.PUT_LINE(ULT_FIN_MES);
   DBMS_OUTPUT.PUT_LINE(P_FECHA);
   OPEN C_FECHA;
   FETCH C_FECHA INTO R_FECHA;
   WHILE C_FECHA%FOUND LOOP
      DELETE FROM HISTORICOS_SALDOS_TITULOS
      WHERE HST_FECHA >= TRUNC(R_FECHA.HST_FECHA)
        AND HST_FECHA <  TRUNC(R_FECHA.HST_FECHA+1);

         DBMS_OUTPUT.PUT_LINE('SE BORRARON REGISTROS DEL DIA '||TO_CHAR(R_FECHA.HST_FECHA,'DD-MON-YYYY'));
         COMMIT;
      FETCH C_FECHA INTO R_FECHA;
   END LOOP;
   CLOSE C_FECHA;
   COMMIT;
   -- BORRAR DE TABLAS DE VALORACION TMP CARGUES ANTERIORES : SE DEJAN UNICAMENTE 8 DIAS 
   DELETE FROM TMP_MARGENES_VALORACION
   WHERE   TMV_FECHA_REGISTRO <= TRUNC(P_FECHA-8); 

   DELETE FROM TMP_CERO_CUPON_VALORACION
   WHERE CCV_FECHA_OPERACION <= TRUNC(P_FECHA-8);

   DELETE FROM TMP_BLOOMBERG_VALORACION
   WHERE TBV_FECHA_ARCHIVO <= TRUNC(P_FECHA-8);

   DELETE FROM TMP_PRECIOS_VALORACION
   WHERE TPV_FECHA_REGISTRO <= TRUNC(P_FECHA-8);

   DELETE FROM TMP_INDICES_VALORACION
   WHERE TIV_FECHA <= TRUNC(P_FECHA-8);


EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso BORRAR_DIFERENTE_FIN_MES','Error en procedimiento BORRAR_DIFERENTE_FIN_MES: '||substr(sqlerrm,1,80));   
      RAISE_APPLICATION_ERROR(-20005,'Error en procedimiento BORRAR_DIFERENTE_FIN_MES: '||sqlerrm);          
END BORRAR_DIFERENTE_FIN_MES;

PROCEDURE CREAR_SALDOS_FECHA (P_FECHA IN DATE) IS
   CURSOR C_CONS IS
      SELECT NVL(MAX(HST_CONSECUTIVO),0) CONS
      FROM HISTORICOS_SALDOS_TITULOS;
   CONSECUTIVO NUMBER;

   CURSOR C_CFC IS 
      SELECT CFC_CCC_CLI_PER_NUM_IDEN 
            ,CFC_CCC_CLI_PER_TID_CODIGO
            ,CFC_CCC_NUMERO_CUENTA
            ,CFC_FUG_ISI_MNEMONICO
            ,CFC_FUG_MNEMONICO
            ,CFC_CUENTA_DECEVAL
            ,MFU_SALDO_DCVAL_DISPONIBLE
            ,MFU_SALDO_DCVAL_GARANTIA       
            ,MFU_SALDO_DCVAL_EMBARGADO
            ,MFU_SALDO_DCVAL_GAR_REPO
            ,MFU_SALDO_DCVAL_POR_CUMPLIR   
			      ,MFU_SALDO_COMPRA_X_CUMPLIR 
            ,MFU_COSTO_PROMEDIO_COMPRA
            ,MFU_SALDO_DCVAL_TRANSITO_ING
            ,MFU_SALDO_DCVAL_TRANSITO_RET
            ,MFU_SALDO_DCVAL_GARANTIA_DER
            ,MFU_SALDO_TTV_COMPRA_FINAL
            ,MFU_SALDO_TTV_VENTA_FINAL
            ,MFU_SALDO_TTV_GARANT_RECEPTOR
            ,MFU_SALDO_TTV_GARANT_COLOCADOR
            ,MFU_SALDO_CRCC_RETARDO                            -- OMORA
      FROM MOVIMIENTOS_CUENTA_FUNGIBLE MFU
          ,CUENTAS_FUNGIBLE_CLIENTE CFC
      WHERE MFU.MFU_CFC_CUENTA_DECEVAL = CFC.CFC_CUENTA_DECEVAL
        AND MFU.MFU_CFC_FUG_ISI_MNEMONICO = CFC.CFC_FUG_ISI_MNEMONICO
        AND MFU.MFU_CFC_FUG_MNEMONICO = CFC.CFC_FUG_MNEMONICO
        AND MFU.MFU_CONSECUTIVO = (SELECT MAX(MFU1.MFU_CONSECUTIVO)
                                   FROM   MOVIMIENTOS_CUENTA_FUNGIBLE MFU1
                                   WHERE  MFU1.MFU_CFC_FUG_ISI_MNEMONICO = CFC.CFC_FUG_ISI_MNEMONICO
                                     AND  MFU1.MFU_CFC_FUG_MNEMONICO = CFC.CFC_FUG_MNEMONICO
                                     AND  MFU1.MFU_CFC_CUENTA_DECEVAL = CFC.CFC_CUENTA_DECEVAL
                                     AND  MFU1.MFU_FECHA < TRUNC(P_FECHA + 1))
        AND (MFU.MFU_SALDO_DCVAL_DISPONIBLE != 0
             OR MFU.MFU_SALDO_DCVAL_GARANTIA   != 0
             OR MFU.MFU_SALDO_DCVAL_EMBARGADO != 0
             OR MFU.MFU_SALDO_DCVAL_GAR_REPO != 0
             OR MFU.MFU_SALDO_DCVAL_POR_CUMPLIR != 0
			 OR MFU.MFU_SALDO_COMPRA_X_CUMPLIR != 0
             OR MFU.MFU_SALDO_DCVAL_TRANSITO_ING != 0
             OR MFU.MFU_SALDO_DCVAL_TRANSITO_RET != 0
             OR MFU.MFU_SALDO_DCVAL_GARANTIA_DER != 0
             OR MFU.MFU_SALDO_CRCC_RETARDO != 0)               -- OMORA
        AND NOT EXISTS (SELECT 'X'
                        FROM ISINS_ESPECIES,
                             PARAMETROS_FONDOS
                        WHERE ISE_ISI_MNEMONICO = CFC_FUG_ISI_MNEMONICO
                          AND ISE_ENA_MNEMONICO = PFO_RANGO_MIN_CHAR
                          AND PFO_PAR_CODIGO = 52)
        AND NOT EXISTS (SELECT 1                               -- OMORA
                       FROM CUENTAS_CLIENTE_CORREDORES CCC
                       WHERE CCC.CCC_CLI_PER_NUM_IDEN = CFC.CFC_CCC_CLI_PER_NUM_IDEN
                         AND CCC.CCC_CLI_PER_TID_CODIGO = CFC.CFC_CCC_CLI_PER_TID_CODIGO
                         AND CCC.CCC_NUMERO_CUENTA = CFC.CFC_CCC_NUMERO_CUENTA
                         AND CCC.CCC_CUENTA_MASTER = 'S');
   R_CFC C_CFC%ROWTYPE;

   CURSOR C_TLO IS
      SELECT TLO.TLO_CCC_CLI_PER_NUM_IDEN 
            ,TLO.TLO_CCC_CLI_PER_TID_CODIGO
            ,TLO.TLO_CCC_NUMERO_CUENTA
            ,TLO_TYPE
            ,TLO.TLO_ETC_MNEMONICO
            ,TLO.TLO_CODIGO
            ,TLO.TLO_CANTIDAD
            ,TLO.TLO_VALOR_NOMINAL
      FROM  TITULOS TLO
      WHERE TLO.TLO_ETC_MNEMONICO IN ('DIS','GAR','TRI','TRR','GAD','GAI')
        AND TLO.TLO_LTI_MNEMONICO IN ('DV','FI')
        AND TLO.TLO_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1)
        AND TLO.TLO_PORTAFOLIO = 'S'
        AND NOT EXISTS (SELECT 'X'
                        FROM PARAMETROS_FONDOS 
                        WHERE PFO_PAR_CODIGO = 52 
                          AND PFO_RANGO_MIN_CHAR = TLO_ENA_MNEMONICO)
      UNION
      SELECT TLO.TLO_CCC_CLI_PER_NUM_IDEN
            ,TLO.TLO_CCC_CLI_PER_TID_CODIGO
            ,TLO.TLO_CCC_NUMERO_CUENTA
            ,TLO_TYPE
            ,HTC_ETC_MNEMONICO
            ,HTC_CODIGO
            ,HTC_CANTIDAD
            ,HTC_VALOR_NOMINAL
      FROM  TITULOS  TLO
           ,HISTORICO_TITULOS_C HTC
      WHERE TLO.TLO_CODIGO = HTC.HTC_CODIGO
        AND TLO.TLO_FECHA_ULTIMO_ESTADO >= TRUNC(P_FECHA + 1)
        AND HTC.HTC_ETC_MNEMONICO IN ('DIS','GAR','TRI','TRR','GAD','GAI')
        AND HTC.HTC_LTI_MNEMONICO IN ('DV','FI')
        AND HTC.HTC_PORTAFOLIO = 'S'
        AND NOT EXISTS (SELECT 'X'
                        FROM PARAMETROS_FONDOS 
                        WHERE PFO_PAR_CODIGO = 52 
                          AND PFO_RANGO_MIN_CHAR = TLO_ENA_MNEMONICO)
        AND HTC.HTC_FECHA_ULTIMO_ESTADO = (SELECT MAX(HTC1.HTC_FECHA_ULTIMO_ESTADO)
                                           FROM   HISTORICO_TITULOS_C   HTC1
                                           WHERE  HTC1.HTC_CODIGO = TLO.TLO_CODIGO
                                             AND  HTC1.HTC_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1));   
   R_TLO C_TLO%ROWTYPE;                                             

   VALOR_DISPONIBLE NUMBER;
   VALOR_GARANTIA NUMBER;
   VALOR_TRI NUMBER;
   VALOR_TRR  NUMBER;
   VALOR_GDER NUMBER;

BEGIN
   OPEN C_CONS;
   FETCH C_CONS INTO CONSECUTIVO;
   CLOSE C_CONS;
   CONSECUTIVO := NVL(CONSECUTIVO,0);

   OPEN C_CFC;
   FETCH C_CFC INTO R_CFC;
   WHILE C_CFC%FOUND LOOP
         CONSECUTIVO := CONSECUTIVO + 1;
      INSERT INTO HISTORICOS_SALDOS_TITULOS
            (HST_CONSECUTIVO                
            ,HST_FECHA                      
            ,HST_CCC_CLI_PER_NUM_IDEN       
            ,HST_CCC_CLI_PER_TID_CODIGO
            ,HST_CCC_NUMERO_CUENTA          
            ,HST_SALDO_DISPONIBLE           
            ,HST_SALDO_GARANTIA             
            ,HST_SALDO_EMBARGO              
            ,HST_SALDO_GARANTIA_REPO        
            ,HST_SALDO_POR_CUMPLIR          
			      ,HST_SALDO_CPR_X_CUMPLIR
            ,HST_VALOR_TM_DISPONIBLE        
            ,HST_VALOR_TM_GARANTIA          
            ,HST_VALOR_TM_EMBARGO           
            ,HST_CFC_FUG_ISI_MNEMONICO      
            ,HST_CFC_FUG_MNEMONICO          
            ,HST_CFC_CUENTA_DECEVAL
            ,HST_COSTO_PROMEDIO_COMPRA
            ,HST_SALDO_TRANSITO_ING
            ,HST_SALDO_TRANSITO_RET
            ,HST_SALDO_GARANTIA_DER
            ,HST_VALOR_TM_GARREPO   
            ,HST_VALOR_TM_XCUMPLIR  
			      ,HST_VALOR_TM_CPR_X_CUMPLIR 
            ,HST_VALOR_TM_TRANING   
            ,HST_VALOR_TM_TRANRET   
            ,HST_VALOR_TM_GARDER
            ,HST_CFC_SALDO_TTV_COMPRA_FINAL                                                                                                                                                                                  
            ,HST_CFC_SALDO_TTV_VENTA_FINAL                                                                                                                                                                                  
            ,HST_CFC_SALDO_TTV_GARANT_REC                                                                                                                                                               
            ,HST_CFC_SALDO_TTV_GARANT_COL
            ,HST_SALDO_RETARDO                                    -- OMORA
			,HST_VALOR_TM_RETARDO)                                -- OMORA
      VALUES (
             CONSECUTIVO
            ,P_FECHA
            ,R_CFC.CFC_CCC_CLI_PER_NUM_IDEN
            ,R_CFC.CFC_CCC_CLI_PER_TID_CODIGO
            ,R_CFC.CFC_CCC_NUMERO_CUENTA
            ,R_CFC.MFU_SALDO_DCVAL_DISPONIBLE
            ,R_CFC.MFU_SALDO_DCVAL_GARANTIA
            ,R_CFC.MFU_SALDO_DCVAL_EMBARGADO
            ,R_CFC.MFU_SALDO_DCVAL_GAR_REPO
            ,R_CFC.MFU_SALDO_DCVAL_POR_CUMPLIR                    
			      ,R_CFC.MFU_SALDO_COMPRA_X_CUMPLIR 
            ,0
            ,0
            ,0
            ,R_CFC.CFC_FUG_ISI_MNEMONICO
            ,R_CFC.CFC_FUG_MNEMONICO
            ,R_CFC.CFC_CUENTA_DECEVAL
            ,R_CFC.MFU_COSTO_PROMEDIO_COMPRA
            ,R_CFC.MFU_SALDO_DCVAL_TRANSITO_ING   
            ,R_CFC.MFU_SALDO_DCVAL_TRANSITO_RET
            ,R_CFC.MFU_SALDO_DCVAL_GARANTIA_DER
            ,0
            ,0
            ,0
            ,0
            ,0
			      ,0
            ,R_CFC.MFU_SALDO_TTV_COMPRA_FINAL                                                                                                                                                                                  
            ,R_CFC.MFU_SALDO_TTV_VENTA_FINAL                                                                                                                                                                                  
            ,R_CFC.MFU_SALDO_TTV_GARANT_RECEPTOR                                                                                                                                                               
            ,R_CFC.MFU_SALDO_TTV_GARANT_COLOCADOR
            ,R_CFC.MFU_SALDO_CRCC_RETARDO              -- OMORA
			,0);                                       -- OMORA

      FETCH C_CFC INTO R_CFC;
   END LOOP;      
   CLOSE C_CFC;

   OPEN C_TLO;
   FETCH C_TLO INTO R_TLO;
   WHILE C_TLO%FOUND LOOP
      CONSECUTIVO := CONSECUTIVO + 1;
      IF R_TLO.TLO_ETC_MNEMONICO IN ('DIS','GAI') THEN
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := R_TLO.TLO_CANTIDAD;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;            
         ELSE
            VALOR_DISPONIBLE := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;            
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'GAR' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := R_TLO.TLO_CANTIDAD;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;            
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := 0;            
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'TRI' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := R_TLO.TLO_CANTIDAD;
            VALOR_TRR := 0;
            VALOR_GDER := 0;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_TRR := 0;
            VALOR_GDER := 0;            
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'TRR' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA :=0;
            VALOR_TRI := 0;
            VALOR_TRR :=  R_TLO.TLO_CANTIDAD;
            VALOR_GDER := 0;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := R_TLO.TLO_VALOR_NOMINAL;
            VALOR_GDER := 0;
         END IF;
      ELSIF R_TLO.TLO_ETC_MNEMONICO = 'GAD' THEN         
         IF R_TLO.TLO_TYPE = 'TVC' THEN
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA := 0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER := R_TLO.TLO_CANTIDAD;
         ELSE
            VALOR_DISPONIBLE := 0;
            VALOR_GARANTIA :=0;
            VALOR_TRI := 0;
            VALOR_TRR := 0;
            VALOR_GDER :=  R_TLO.TLO_VALOR_NOMINAL;
         END IF;
      ELSE
         VALOR_DISPONIBLE := 0;
         VALOR_GARANTIA := 0;
         VALOR_TRI := 0;
         VALOR_TRR := 0;
         VALOR_GDER := 0;         
      END IF;       

      IF VALOR_DISPONIBLE !=0 OR VALOR_GARANTIA != 0 THEN
         INSERT INTO HISTORICOS_SALDOS_TITULOS
               (HST_CONSECUTIVO                
               ,HST_FECHA                      
               ,HST_CCC_CLI_PER_NUM_IDEN       
               ,HST_CCC_CLI_PER_TID_CODIGO
               ,HST_CCC_NUMERO_CUENTA          
               ,HST_SALDO_DISPONIBLE           
               ,HST_SALDO_GARANTIA             
               ,HST_SALDO_EMBARGO              
               ,HST_VALOR_TM_DISPONIBLE        
               ,HST_VALOR_TM_GARANTIA          
               ,HST_VALOR_TM_EMBARGO           
               ,HST_TLO_CODIGO
               ,HST_COSTO_PROMEDIO_COMPRA
               ,HST_SALDO_TRANSITO_ING 
               ,HST_SALDO_TRANSITO_RET 
               ,HST_SALDO_GARANTIA_DER 
               ,HST_VALOR_TM_GARREPO   
               ,HST_VALOR_TM_XCUMPLIR  
               ,HST_VALOR_TM_TRANING   
               ,HST_VALOR_TM_TRANRET   
               ,HST_VALOR_TM_GARDER )               
         VALUES (
                CONSECUTIVO
               ,P_FECHA
               ,R_TLO.TLO_CCC_CLI_PER_NUM_IDEN
               ,R_TLO.TLO_CCC_CLI_PER_TID_CODIGO
               ,R_TLO.TLO_CCC_NUMERO_CUENTA
               ,VALOR_DISPONIBLE
               ,VALOR_GARANTIA
               ,0
               ,0
               ,0
               ,0
               ,R_TLO.TLO_CODIGO
               ,0
               ,VALOR_TRI
               ,VALOR_TRR
               ,VALOR_GDER
               ,0
               ,0
               ,0
               ,0
               ,0
               );

      END IF;

      FETCH C_TLO INTO R_TLO;
   END LOOP;
   CLOSE C_TLO;
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso CREAR_SALDOS_FECHA','Error en procedimiento CREAR_SALDOS_FECHA: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20006,'Error en procedimiento CREAR_SALDOS_FECHA: '||sqlerrm);
END CREAR_SALDOS_FECHA;



-- COMPROMISOS DE COMPRA Y VENTA

PROCEDURE COMPROMISOS IS
   -- ESTE PROCEDIMIENTO SE LLAMA DESDE EL CRON DE LOS NOCTURNOS TITULOS. SQL
   -- SE GENERAN LOS COMPROMISOS DE COMPRA Y DE VENTA DE LOS CLIENTES (NO TIENE HORA LIMITE PARA CORRER)
   -- SI ES FIN DE MES SE GUARDA LA INFORMACION. SE BORRAN LOS DATOS PARA FECHA DIFERENTE A FIN DE MES

   P_FECHA_HOY DATE;
   FECHA_A_PROCESAR DATE;
   P_NUM_INI NUMBER;
   P_NUM_FIN NUMBER; 

   CURSOR C_EXISTE (QFECHA DATE) IS
      SELECT 'S'
      FROM HISTORICOS_COMPROMISOS_CLIENTE
      WHERE HCC_FECHA >= TRUNC(QFECHA)
        AND HCC_FECHA <  TRUNC(QFECHA+1);
   SINO VARCHAR2(1);        

   NO_PROCESO EXCEPTION;
   YA_EXISTE  EXCEPTION;
BEGIN
    P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.COMPROMISOS','INI');

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
      P_CLIENTES_TITULOS.CREAR_COMPROMISOS_FECHA(FECHA_A_PROCESAR);
      -- BORRAR LA INFORMACION < A LA FECHA SI ES DIFERENTE A FIN DE MES
      --P_CLIENTES_TITULOS.BORRAR_DIFERENTE_FIN_MES_COMP(FECHA_A_PROCESAR);
   ELSE
      RAISE YA_EXISTE;
   END IF;
   P_CLIENTES_TITULOS.OPERACIONES_CONTADO;   
   P_MAIL.envio_mail_error('COMPROMISOS EXITOSO','Proceso de Generacion de Compromisos de Clientes EXITOSO');

   P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.COMPROMISOS','FIN');

   COMMIT;

EXCEPTION
     WHEN YA_EXISTE THEN
        P_MAIL.envio_mail_error('Proceso COMPROMISOS','Ya se generaron los compromisos para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
        RAISE_APPLICATION_ERROR(-20007,'Ya se generaron los compromisos para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso COMPROMISOS','Error en procedimiento COMPROMISOS: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20008,'Error en procedimiento COMPROMISOS: '||sqlerrm);

END COMPROMISOS;



PROCEDURE CREAR_COMPROMISOS_FECHA (P_FECHA IN DATE) IS

   CURSOR C_CONS IS
      SELECT NVL(MAX(HCC_CONSECUTIVO),0) CONS
      FROM HISTORICOS_COMPROMISOS_CLIENTE;
   CONSECUTIVO NUMBER;

   CURSOR C_CCV IS
      SELECT  OCO_CCC_CLI_PER_NUM_IDEN,
              OCO_CCC_CLI_PER_TID_CODIGO,
              OCO_CCC_NUMERO_CUENTA,
              LIC_CLASE_TRANSACCION,
              DECODE(LIC_TIPO_OFERTA,'R','REPO','A','REPO','1','SIM','2','SIM','4','TTV','5','SIM','6','SIM') COND_NEGOCIACION,
              LIC_BOL_MNEMONICO,
              LIC_NUMERO_OPERACION,
              LIC_NUMERO_FRACCION,
              LIC_TIPO_OPERACION,
              LIC_CANTIDAD_FRACCION VALOR_NOMINAL,
              P_WEB_PORTAFOLIO.VALOR_NETO_LIQUIDACION(LIC_BOL_MNEMONICO, LIC_NUMERO_OPERACION-1, LIC_NUMERO_FRACCION, DECODE(LIC_TIPO_OPERACION,'C','V','V','C'),NULL) VALOR_INICIAL,
			  DECODE(LIC_TIPO_OFERTA,'4',LIC_VOLUMEN_FRACCION,LIC_VOLUMEN_NETO_FRACCION) VALOR_REGRESO
      FROM ORDENES_COMPRA,
           LIQUIDACIONES_COMERCIAL
      WHERE OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
        AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
        AND OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND LIC_TIPO_OFERTA IN ('R','A','2','4','6')
        AND LIC_SUCURSAL_CUMPLIMIENTO = 'DVL'
        AND TRUNC(LIC_FECHA_OPERACION) != TRUNC(LIC_FECHA_CUMPLIMIENTO)
        AND LIC_FECHA_OPERACION < TRUNC(P_FECHA + 1)
        AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA)))
        AND NOT EXISTS (SELECT 'X'
                        FROM MOVIMIENTOS_CUENTA_CORREDORES
                        WHERE MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND MCC_TMC_MNEMONICO IN ('COPC','COPV')
-- rhenao                          AND MCC_MCC_FECHA IS NULL
                          AND MCC_MCC_CONSECUTIVO IS NULL
                          AND MCC_FECHA < TRUNC(P_FECHA+1))
        AND  0 =  (SELECT NVL(SUM(MFU_MONTO_CLIENTE),0)
                   FROM MOVIMIENTOS_CUENTA_FUNGIBLE
                   WHERE MFU_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                     AND MFU_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                     AND MFU_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                     AND MFU_LIC_BOL_MNEMONICO   = LIC_BOL_MNEMONICO
                     AND MFU_FECHA < TRUNC(P_FECHA + 1))
        AND  (0 !=  (SELECT NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL 
                                 + MCC_MONTO_A_PLAZO + MCC_MONTO_A_CONTADO),0)
                     FROM    MOVIMIENTOS_CUENTA_CORREDORES
                     WHERE   MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                      AND    MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                      AND    MCC_LIC_BOL_MNEMONICO  = LIC_BOL_MNEMONICO
                      AND    MCC_FECHA < TRUNC(P_FECHA + 1)) OR LIC_TIPO_OFERTA = '4')
      UNION ALL
      SELECT  OCO_CCC_CLI_PER_NUM_IDEN,
              OCO_CCC_CLI_PER_TID_CODIGO,
              OCO_CCC_NUMERO_CUENTA,
              LIC_CLASE_TRANSACCION,
              DECODE(LIC_TIPO_OFERTA,'R','REPO','A','REPO','1','SIM','2','SIM','4','TTV','5','SIM','6','SIM') COND_NEGOCIACION,
              LIC_BOL_MNEMONICO,
              LIC_NUMERO_OPERACION,
              LIC_NUMERO_FRACCION,
              LIC_TIPO_OPERACION,
              LIC_CANTIDAD_FRACCION VALOR_NOMINAL,
              P_WEB_PORTAFOLIO.VALOR_NETO_LIQUIDACION(LIC_BOL_MNEMONICO, LIC_NUMERO_OPERACION-1, LIC_NUMERO_FRACCION, DECODE(LIC_TIPO_OPERACION,'C','V','V','C'),NULL) VALOR_INICIAL,
              DECODE(LIC_TIPO_OFERTA,'4',LIC_VOLUMEN_FRACCION,LIC_VOLUMEN_NETO_FRACCION) VALOR_REGRESO
      FROM ORDENES_COMPRA,
            LIQUIDACIONES_COMERCIAL
      WHERE OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
        AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
        AND OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND LIC_TIPO_OFERTA IN ('R','A','2','4','6')
        AND LIC_SUCURSAL_CUMPLIMIENTO = 'DCV'
        AND TRUNC(LIC_FECHA_OPERACION) != TRUNC(LIC_FECHA_CUMPLIMIENTO)
        AND LIC_FECHA_OPERACION < TRUNC(P_FECHA + 1)
        AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA)))
        AND NOT EXISTS (SELECT 'X'
                        FROM MOVIMIENTOS_CUENTA_CORREDORES
                        WHERE MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND MCC_TMC_MNEMONICO IN ('COPC','COPV')
-- rhenao                          AND MCC_MCC_FECHA IS NULL
                          AND MCC_MCC_CONSECUTIVO IS NULL
                          AND MCC_FECHA < TRUNC(P_FECHA+1))
        AND NOT EXISTS (SELECT 'X'
                        FROM    TITULOS
                        WHERE TLO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND TLO_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND TLO_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND TLO_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND TLO_FECHA_OPERACION < TRUNC(P_FECHA + 1))
        AND  (0 !=  (SELECT NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL 
                                 + MCC_MONTO_A_PLAZO + MCC_MONTO_A_CONTADO),0)
                     FROM    MOVIMIENTOS_CUENTA_CORREDORES
                     WHERE   MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                      AND    MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                      AND    MCC_LIC_BOL_MNEMONICO  = LIC_BOL_MNEMONICO
                      AND    MCC_FECHA < TRUNC(P_FECHA + 1)) OR LIC_TIPO_OFERTA IN ('4'))
      UNION ALL
      SELECT  OCO_CCC_CLI_PER_NUM_IDEN,
              OCO_CCC_CLI_PER_TID_CODIGO,
              OCO_CCC_NUMERO_CUENTA,
              LIC_CLASE_TRANSACCION,
              'PLZ'  COND_NEGOCIACION,
              LIC_BOL_MNEMONICO,
              LIC_NUMERO_OPERACION,
              LIC_NUMERO_FRACCION,
              LIC_TIPO_OPERACION,
              LIC_CANTIDAD_FRACCION VALOR_NOMINAL,
              LIC_VOLUMEN_NETO_FRACCION VALOR_INICIAL,
              --0 VALOR_INICIAL,
			  DECODE(LIC_TIPO_OFERTA,'4',LIC_VOLUMEN_FRACCION,LIC_VOLUMEN_NETO_FRACCION) VALOR_REGRESO
      FROM ORDENES_COMPRA,
           LIQUIDACIONES_COMERCIAL
      WHERE OCO_COC_CTO_MNEMONICO = LIC_OCO_COC_CTO_MNEMONICO
        AND OCO_CONSECUTIVO = LIC_OCO_CONSECUTIVO
        AND OCO_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND LIC_TIPO_OFERTA NOT IN ('R','A','1','2','4','5','6')
        AND LIC_SUCURSAL_CUMPLIMIENTO IN ('DCV','DVL')
        AND EXISTS (SELECT 'X'
                    FROM   MOVIMIENTOS_CUENTA_CORREDORES
                    WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                      AND  MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND  MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                      AND  MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION 
                      AND  MCC_MONTO_A_PLAZO != 0)
        AND TRUNC(LIC_FECHA_OPERACION) != TRUNC(LIC_FECHA_CUMPLIMIENTO)
        AND LIC_FECHA_OPERACION < TRUNC(P_FECHA + 1)
        AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA)))
        AND NOT EXISTS (SELECT 'X'
                        FROM MOVIMIENTOS_CUENTA_CORREDORES
                        WHERE MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND MCC_TMC_MNEMONICO IN ('COPC','COPV')
-- rhenao                          AND MCC_MCC_FECHA IS NULL
                          AND MCC_MCC_CONSECUTIVO IS NULL
                          AND MCC_FECHA < TRUNC(P_FECHA+1))
        AND  (0 !=  (SELECT NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL  
                                 + MCC_MONTO_A_PLAZO + MCC_MONTO_A_CONTADO),0)
                     FROM    MOVIMIENTOS_CUENTA_CORREDORES
                     WHERE   MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND    MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                      AND    MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                      AND    MCC_LIC_BOL_MNEMONICO  = LIC_BOL_MNEMONICO
                      AND    MCC_FECHA < TRUNC(P_FECHA + 1)) OR LIC_TIPO_OFERTA IN ('4'))
                          ;

   R_CCV C_CCV%ROWTYPE;


   -- COMPROMISOS VENTA VIGENTE
   CURSOR C_CVV IS
      SELECT  OVE_CCC_CLI_PER_NUM_IDEN,
              OVE_CCC_CLI_PER_TID_CODIGO,
              OVE_CCC_NUMERO_CUENTA,
              LIC_CLASE_TRANSACCION,    --SIMULTANEAS Y REPOS DECEVAL
              DECODE(LIC_TIPO_OFERTA,'R','REPO','A','REPO','1','SIM','2','SIM','4','TTV','5','SIM','6','SIM') COND_NEGOCIACION,
              LIC_BOL_MNEMONICO,
              LIC_NUMERO_OPERACION,
              LIC_NUMERO_FRACCION,
              LIC_TIPO_OPERACION,
              LIC_CANTIDAD_FRACCION VALOR_NOMINAL,
              P_WEB_PORTAFOLIO.VALOR_NETO_LIQUIDACION(LIC_BOL_MNEMONICO, LIC_NUMERO_OPERACION-1, LIC_NUMERO_FRACCION, DECODE(LIC_TIPO_OPERACION,'C','V','V','C'),NULL) VALOR_INICIAL,
              DECODE(LIC_TIPO_OFERTA,'4',LIC_VOLUMEN_FRACCION,LIC_VOLUMEN_NETO_FRACCION) VALOR_REGRESO
      FROM ORDENES_VENTA,
           LIQUIDACIONES_COMERCIAL
      WHERE OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
        AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
        AND OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND LIC_TIPO_OFERTA IN ('R','A','2','4','6')
        AND LIC_SUCURSAL_CUMPLIMIENTO = 'DVL'
        AND TRUNC(LIC_FECHA_OPERACION) != TRUNC(LIC_FECHA_CUMPLIMIENTO)
        AND LIC_FECHA_OPERACION < TRUNC(P_FECHA + 1)
        AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA)))
        AND NOT EXISTS (SELECT 'X'
                        FROM MOVIMIENTOS_CUENTA_CORREDORES
                        WHERE MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND MCC_TMC_MNEMONICO IN ('COPC','COPV')
-- rhenao                          AND MCC_MCC_FECHA IS NULL
                          AND MCC_MCC_CONSECUTIVO IS NULL
                          AND MCC_FECHA < TRUNC(P_FECHA+1))
        AND  0 =  (SELECT NVL(SUM(MFU_MONTO_CLIENTE),0)
                   FROM MOVIMIENTOS_CUENTA_FUNGIBLE
                   WHERE MFU_LIC_NUMERO_OPERACION_ES_VE = LIC_NUMERO_OPERACION
                     AND MFU_LIC_NUMERO_FRACCION_ES_VEN = LIC_NUMERO_FRACCION
                     AND MFU_LIC_TIPO_OPERACION_ES_VEND = LIC_TIPO_OPERACION
                     AND MFU_LIC_BOL_MNEMONICO_ES_VEND   = LIC_BOL_MNEMONICO
                     AND MFU_FECHA < TRUNC(P_FECHA + 1))
         AND  (0 !=  (SELECT NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL  
                                  + MCC_MONTO_A_PLAZO + MCC_MONTO_A_CONTADO),0)
                     FROM    MOVIMIENTOS_CUENTA_CORREDORES
                     WHERE  MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND       MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                       AND      MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                       AND      MCC_LIC_BOL_MNEMONICO  = LIC_BOL_MNEMONICO
                       AND      MCC_FECHA < TRUNC(P_FECHA + 1)) OR LIC_TIPO_OFERTA IN ('4'))
      UNION ALL
      SELECT  OVE_CCC_CLI_PER_NUM_IDEN,
              OVE_CCC_CLI_PER_TID_CODIGO,
              OVE_CCC_NUMERO_CUENTA,
              LIC_CLASE_TRANSACCION,    --SIMULTANEAS Y REPOS DCV
              DECODE(LIC_TIPO_OFERTA,'R','REPO','A','REPO','1','SIM','2','SIM','4','TTV','5','SIM','6','SIM') COND_NEGOCIACION,
              LIC_BOL_MNEMONICO,
              LIC_NUMERO_OPERACION,
              LIC_NUMERO_FRACCION,
              LIC_TIPO_OPERACION,
              LIC_CANTIDAD_FRACCION VALOR_NOMINAL,
              P_WEB_PORTAFOLIO.VALOR_NETO_LIQUIDACION(LIC_BOL_MNEMONICO, LIC_NUMERO_OPERACION-1, LIC_NUMERO_FRACCION, DECODE(LIC_TIPO_OPERACION,'C','V','V','C'),NULL) VALOR_INICIAL,
			  DECODE(LIC_TIPO_OFERTA,'4',LIC_VOLUMEN_FRACCION,LIC_VOLUMEN_NETO_FRACCION) VALOR_REGRESO
      FROM ORDENES_VENTA,
           LIQUIDACIONES_COMERCIAL
      WHERE OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
        AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
        AND OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND LIC_TIPO_OFERTA IN ('R','A','2','4','6')
        AND LIC_SUCURSAL_CUMPLIMIENTO = 'DCV'
        AND TRUNC(LIC_FECHA_OPERACION) != TRUNC(LIC_FECHA_CUMPLIMIENTO)
        AND LIC_FECHA_OPERACION < TRUNC(P_FECHA + 1)
        AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA)))
        AND NOT EXISTS (SELECT 'X'
                        FROM MOVIMIENTOS_CUENTA_CORREDORES
                        WHERE MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND MCC_TMC_MNEMONICO IN ('COPC','COPV')
-- rhenao                          AND MCC_MCC_FECHA IS NULL
                          AND MCC_MCC_CONSECUTIVO IS NULL
                          AND MCC_FECHA < TRUNC(P_FECHA+1))
        AND NOT EXISTS (SELECT 'X'
                        FROM    TITULOS
                        WHERE TLO_LIC_BOL_MNEMONICO_ES_VEN = LIC_BOL_MNEMONICO
                          AND TLO_LIC_NUMERO_OPERACION_ES_VE = LIC_NUMERO_OPERACION
                          AND TLO_LIC_NUMERO_FRACCION_ES_VEN = LIC_NUMERO_FRACCION
                          AND TLO_LIC_TIPO_OPERACION_ES_VEND = LIC_TIPO_OPERACION
                          AND TLO_FECHA_ULTIMO_ESTADO < TRUNC(P_FECHA + 1))
         AND  (0 !=  (SELECT NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL  
                                  + MCC_MONTO_A_PLAZO + MCC_MONTO_A_CONTADO),0)
                     FROM    MOVIMIENTOS_CUENTA_CORREDORES
                     WHERE  MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND       MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                       AND      MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                       AND      MCC_LIC_BOL_MNEMONICO  = LIC_BOL_MNEMONICO
                       AND      MCC_FECHA < TRUNC(P_FECHA + 1)) OR LIC_TIPO_OFERTA IN ('4'))
      UNION ALL     
      SELECT  OVE_CCC_CLI_PER_NUM_IDEN,
              OVE_CCC_CLI_PER_TID_CODIGO,
              OVE_CCC_NUMERO_CUENTA,
              LIC_CLASE_TRANSACCION,                      --OPCE DECEVAL Y DCV
              'PLZ' COND_NEGOCIACION,
              LIC_BOL_MNEMONICO,
              LIC_NUMERO_OPERACION,
              LIC_NUMERO_FRACCION,
              LIC_TIPO_OPERACION,
              LIC_CANTIDAD_FRACCION VALOR_NOMINAL,
              LIC_VOLUMEN_NETO_FRACCION VALOR_INICIAL,
              --0 VALOR_INICIAL, 
			  DECODE(LIC_TIPO_OFERTA,'4',LIC_VOLUMEN_FRACCION,P_WEB_PORTAFOLIO.VALOR_NETO_LIQUIDACION(LIC_BOL_MNEMONICO, LIC_NUMERO_OPERACION, LIC_NUMERO_FRACCION, LIC_TIPO_OPERACION,NULL)) VALOR_REGRESO			  
      FROM ORDENES_VENTA,
           LIQUIDACIONES_COMERCIAL
      WHERE OVE_COC_CTO_MNEMONICO = LIC_OVE_COC_CTO_MNEMONICO
        AND OVE_CONSECUTIVO = LIC_OVE_CONSECUTIVO
        AND OVE_BOL_MNEMONICO = LIC_BOL_MNEMONICO
        AND LIC_TIPO_OFERTA NOT IN ('R','A','1','2','4','5','6')
        AND EXISTS (SELECT 'X'
                    FROM   MOVIMIENTOS_CUENTA_CORREDORES
                    WHERE  MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                      AND  MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND  MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                      AND  MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION 
                      AND  MCC_MONTO_A_PLAZO != 0)
        AND LIC_SUCURSAL_CUMPLIMIENTO IN ('DCV','DVL')
        AND TRUNC(LIC_FECHA_OPERACION) != TRUNC(LIC_FECHA_CUMPLIMIENTO)
        AND LIC_FECHA_OPERACION < TRUNC(P_FECHA + 1)
        AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA)))
        AND NOT EXISTS (SELECT 'X'
                        FROM MOVIMIENTOS_CUENTA_CORREDORES
                        WHERE MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                          AND MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                          AND MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                          AND MCC_LIC_BOL_MNEMONICO = LIC_BOL_MNEMONICO
                          AND MCC_TMC_MNEMONICO IN ('COPC','COPV')
-- rhenao                          AND MCC_MCC_FECHA IS NULL
                          AND MCC_MCC_CONSECUTIVO IS NULL
                          AND MCC_FECHA < TRUNC(P_FECHA+1))
         AND  (0 !=  (SELECT NVL(SUM(MCC_MONTO + MCC_MONTO_BURSATIL  
                                  + MCC_MONTO_A_PLAZO + MCC_MONTO_A_CONTADO),0)
                     FROM    MOVIMIENTOS_CUENTA_CORREDORES
                     WHERE  MCC_LIC_NUMERO_OPERACION = LIC_NUMERO_OPERACION
                      AND       MCC_LIC_NUMERO_FRACCION = LIC_NUMERO_FRACCION
                       AND      MCC_LIC_TIPO_OPERACION = LIC_TIPO_OPERACION
                       AND      MCC_LIC_BOL_MNEMONICO  = LIC_BOL_MNEMONICO
                       AND      MCC_FECHA < TRUNC(P_FECHA + 1)) OR LIC_TIPO_OFERTA IN ('4'))
                          ;
   R_CVV C_CVV%ROWTYPE;


BEGIN

   OPEN C_CONS;
   FETCH C_CONS INTO CONSECUTIVO;
   CLOSE C_CONS;
   CONSECUTIVO := NVL(CONSECUTIVO,0);

   OPEN C_CCV;
   FETCH C_CCV INTO R_CCV;
   WHILE C_CCV%FOUND LOOP
         CONSECUTIVO := CONSECUTIVO + 1;
      INSERT INTO HISTORICOS_COMPROMISOS_CLIENTE
         (HCC_CONSECUTIVO,
          HCC_FECHA,
          HCC_TIPO,
          HCC_TIPO_COMPROMISO,
          HCC_CCC_CLI_PER_NUM_IDEN,
          HCC_CCC_CLI_PER_TID_CODIGO,
          HCC_CCC_NUMERO_CUENTA,
          HCC_LIC_BOL_MNEMONICO,
          HCC_LIC_NUMERO_OPERACION,
          HCC_LIC_NUMERO_FRACCION,
          HCC_LIC_TIPO_OPERACION,
          HCC_CNE_MNEMONICO,
          HCC_VALOR_NOMINAL,
          HCC_VALOR_INICIAL,
          HCC_VALOR_REGRESO)
       VALUES (
          CONSECUTIVO,
          TRUNC(P_FECHA),
          R_CCV.LIC_CLASE_TRANSACCION,
          'C',    --COMPROMISO DE COMPRA,
          R_CCV.OCO_CCC_CLI_PER_NUM_IDEN,
          R_CCV.OCO_CCC_CLI_PER_TID_CODIGO,
          R_CCV.OCO_CCC_NUMERO_CUENTA,
          R_CCV.LIC_BOL_MNEMONICO,
          R_CCV.LIC_NUMERO_OPERACION,
          R_CCV.LIC_NUMERO_FRACCION,
          R_CCV.LIC_TIPO_OPERACION,
          R_CCV.COND_NEGOCIACION,
          R_CCV.VALOR_NOMINAL,
          R_CCV.VALOR_INICIAL,
          R_CCV.VALOR_REGRESO);
       COMMIT;          
       FETCH C_CCV INTO R_CCV;
   END LOOP;
   CLOSE C_CCV;

   OPEN C_CVV;
   FETCH C_CVV INTO R_CVV;
   WHILE C_CVV%FOUND LOOP
         CONSECUTIVO := CONSECUTIVO + 1;
      INSERT INTO HISTORICOS_COMPROMISOS_CLIENTE
         (HCC_CONSECUTIVO,
          HCC_FECHA,
          HCC_TIPO,
          HCC_TIPO_COMPROMISO,
          HCC_CCC_CLI_PER_NUM_IDEN,
          HCC_CCC_CLI_PER_TID_CODIGO,
          HCC_CCC_NUMERO_CUENTA,
          HCC_LIC_BOL_MNEMONICO,
          HCC_LIC_NUMERO_OPERACION,
          HCC_LIC_NUMERO_FRACCION,
          HCC_LIC_TIPO_OPERACION,
          HCC_CNE_MNEMONICO,
          HCC_VALOR_NOMINAL,
          HCC_VALOR_INICIAL,
          HCC_VALOR_REGRESO)
       VALUES (
          CONSECUTIVO,
          TRUNC(P_FECHA),
          R_CVV.LIC_CLASE_TRANSACCION,
          'V',    --COMPROMISO DE VENTA,
          R_CVV.OVE_CCC_CLI_PER_NUM_IDEN,
          R_CVV.OVE_CCC_CLI_PER_TID_CODIGO,
          R_CVV.OVE_CCC_NUMERO_CUENTA,
          R_CVV.LIC_BOL_MNEMONICO,
          R_CVV.LIC_NUMERO_OPERACION,
          R_CVV.LIC_NUMERO_FRACCION,
          R_CVV.LIC_TIPO_OPERACION,
          R_CVV.COND_NEGOCIACION,
          R_CVV.VALOR_NOMINAL,
          R_CVV.VALOR_INICIAL,
          R_CVV.VALOR_REGRESO);
       COMMIT;                    
       FETCH C_CVV INTO R_CVV;
   END LOOP;
   CLOSE C_CVV;
   COMMIT;

   /****SE EJECUTA EL PROCESO DE VALORACIÓN DE LOS COMPROMISOS****/
   VALORAR_COMPROMISOS (P_FECHA);
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso CREAR_COMPROMISOS_FECHA','Error en procedimiento CREAR_COMPROMISOS_FECHA: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20009,'Error en procedimiento CREAR_COMPROMISOS_FECHA: '||sqlerrm);
END CREAR_COMPROMISOS_FECHA;

-- PROCEDIMIENTO PARA VALORACION DE COMPROMISOS
PROCEDURE VALORAR_COMPROMISOS (QFECHA DATE) IS

   CURSOR C_HCC IS
      SELECT HCC_CONSECUTIVO
      FROM HISTORICOS_COMPROMISOS_CLIENTE
      WHERE HCC_FECHA >= TRUNC(QFECHA)
        AND HCC_FECHA <  TRUNC(QFECHA+1)
        ORDER BY HCC_CONSECUTIVO;

   R_HCC C_HCC%ROWTYPE;    
   P_NUM_INI NUMBER;
   P_NUM_FIN NUMBER; 

BEGIN
 P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.VALORAR_COMPROMISOS','INI');
   OPEN C_HCC;
   FETCH C_HCC INTO R_HCC;
   WHILE C_HCC%FOUND LOOP
         P_CLIENTES_TITULOS.GENERAR_VALORACION_COMPROMISOS(QFECHA,R_HCC.HCC_CONSECUTIVO);
      FETCH C_HCC INTO R_HCC;
   END LOOP;
   CLOSE C_HCC;
   COMMIT;  
   P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.VALORAR_COMPROMISOS','FIN');

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso VALORAR_COMPROMISOS','Error en procedimiento VALORAR_COMPROMISOS: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20011,'Error en procedimiento COMPROMISOS: '||sqlerrm);
END VALORAR_COMPROMISOS; 


PROCEDURE GENERAR_VALORACION_COMPROMISOS (QFECHA DATE, P_CONSECUTIVO NUMBER) IS

  /************COMPROMISOS A LOS CUALES SE LES GENERARÁ LA VALORACIÓN**********/
   CURSOR C_HCC IS
      SELECT HCC_CONSECUTIVO,
             HCC_FECHA,
             HCC_TIPO,
             HCC_TIPO_COMPROMISO,
             HCC_CCC_CLI_PER_NUM_IDEN,
             HCC_CCC_CLI_PER_TID_CODIGO,
             HCC_CCC_NUMERO_CUENTA,
             HCC_LIC_BOL_MNEMONICO,
             HCC_LIC_NUMERO_OPERACION,
             HCC_LIC_NUMERO_FRACCION,
             HCC_LIC_TIPO_OPERACION,
             HCC_CNE_MNEMONICO,
             HCC_VALOR_NOMINAL,
             HCC_VALOR_INICIAL,
             HCC_VALOR_REGRESO
      FROM HISTORICOS_COMPROMISOS_CLIENTE
      WHERE HCC_FECHA >= TRUNC(QFECHA)
        AND HCC_FECHA <  TRUNC(QFECHA+1)
        AND HCC_CONSECUTIVO = P_CONSECUTIVO;
   R_HCC C_HCC%ROWTYPE;      

   /****************VALOR DE UNA MONEDA EN UN MOMENTO**************/
   CURSOR VALOR_MONEDA (BMO VARCHAR2) IS
       SELECT NVL(CBM_VALOR,0) CBM_VALOR
       FROM   COTIZACIONES_BASE_MONETARIAS
       WHERE  CBM_BMO_MNEMONICO = BMO
       AND    TRUNC(CBM_FECHA) = TRUNC(QFECHA);
   VALOR_BMO NUMBER;

   /*****************SUCURSAL DE CUMPLIMIENTO DONDE SE REALIZA LA OPERACIÓN****************/
   CURSOR SUCURSAL_CUMPLIMIENTO (P_LIC_NUMERO_OPERACION NUMBER, P_LIC_NUMERO_FRACCION NUMBER, P_LIC_TIPO_OPERACION VARCHAR2, P_LIC_BOL_MNEMONICO VARCHAR2) IS
       SELECT LIC_SUCURSAL_CUMPLIMIENTO
       FROM   LIQUIDACIONES_COMERCIAL
       WHERE  LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
       AND    LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
       AND    LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
       AND    LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO;
   SUCURSAL VARCHAR2(3);

   /*****************DATOS DEL FUNGIBLE Y DE LA CUENTA FUNGIBLE DEL CLIENTE******************/
   CURSOR C_DATOS_CUENTA_FUNGIBLE (P_LIC_NUMERO_OPERACION NUMBER, P_LIC_NUMERO_FRACCION NUMBER, P_LIC_TIPO_OPERACION VARCHAR2, P_LIC_BOL_MNEMONICO VARCHAR2) IS
      SELECT MFU_CFC_CUENTA_DECEVAL,
             MFU_CFC_FUG_ISI_MNEMONICO,
             MFU_CFC_FUG_MNEMONICO,
             FUG_TIPO,
             FUG_BMO_MNEMONICO,
             FUG_TITULO_PARTICIPATIVO,
             FUG_ENA_MNEMONICO ESPECIE,
             FUG_ESTADO,
             FUG_FECHA_EMISION,
             FUG_FECHA_EXPEDICION,
             FUG_FECHA_VENCIMIENTO,
             FUG_BASE_CALCULO,
             FUG_MODALIDAD_TASA,
             FUG_TASA_FACIAL *100 FUG_TASA_FACIAL,
             FUG_TRE_MNEMONICO,
             FUG_PUNTOS_ADICIONALES,
             FUG_PERIODICIDAD_TASA,
             FUG_TIPO_TES,
             FUG_AMORTIZABLE,
             FUG_CAPITALIZABLE,
             FUG_TIPO_PAGO_FLUJO,
             FUG_CODIGO_PERIODO
      FROM   MOVIMIENTOS_CUENTA_FUNGIBLE, FUNGIBLES
      WHERE  ((P_LIC_TIPO_OPERACION = 'V' 
      AND    MFU_LIC_NUMERO_OPERACION_ES_VE = P_LIC_NUMERO_OPERACION
      AND    MFU_LIC_NUMERO_FRACCION_ES_VEN = P_LIC_NUMERO_FRACCION
      AND    MFU_LIC_TIPO_OPERACION_ES_VEND = P_LIC_TIPO_OPERACION
      AND    MFU_LIC_BOL_MNEMONICO_ES_VEND = P_LIC_BOL_MNEMONICO)
      OR     (P_LIC_TIPO_OPERACION = 'C'
      AND    MFU_LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
      AND    MFU_LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
      AND    MFU_LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
      AND    MFU_LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO))
      AND    FUG_ISI_MNEMONICO = MFU_CFC_FUG_ISI_MNEMONICO
      AND    MFU_CFC_FUG_MNEMONICO = FUG_MNEMONICO;
   R_DCF C_DATOS_CUENTA_FUNGIBLE%ROWTYPE;   

   /******PRECIO EN BOLSA DE UNA ESPECIE, ACCIONES******/
   CURSOR PRECIO_ESPECIE (ENA VARCHAR2) IS
      SELECT PEB_PRECIO_BOLSA
      FROM   PRECIOS_ESPECIES_BOLSA A
      WHERE  PEB_ENA_MNEMONICO = ENA
      AND    PEB_FECHA = (SELECT MAX(PEB_FECHA )
                          FROM   PRECIOS_ESPECIES_BOLSA B
                          WHERE  B.PEB_ENA_MNEMONICO = ENA
                          AND    PEB_FECHA < TRUNC(QFECHA + 1));
   VALOR_ESPECIE NUMBER;

   /*****************DATOS DEL TITULO********************/
   CURSOR C_DATOS_TITULO (P_LIC_NUMERO_OPERACION NUMBER, P_LIC_NUMERO_FRACCION NUMBER, P_LIC_TIPO_OPERACION VARCHAR2, P_LIC_BOL_MNEMONICO VARCHAR2) IS
      SELECT TLO_CODIGO,
             TLO_TYPE,
             TLO_BMO_MNEMONICO,
             TLO_ENA_MNEMONICO,
             ENA_TITULO_PARTICIPATIVO,
             TLO_FECHA_OPERACION,
             TLO_TRE_MNEMONICO,
             TLO_FECHA_EMISION,
             TLO_FECHA_VENCIMIENTO,
             TLO_PUNTOS_ADICIONALES,
             TLO_VALOR_NOMINAL,
             TLO_TASA_FACIAL * 100  TLO_TASA_FACIAL,
             TLO_PERIODICIDAD_TASA,
             TLO_BASE_CALCULO,
             TLO_MODALIDAD_TASA,
             TLO_AMORTIZABLE,
             TLO_CAPITALIZABLE,
             TLO_TIPO_PAGO_FLUJO,
             TLO_CODIGO_PERIODO    
      FROM   TITULOS,
             ESPECIES_NACIONALES
      WHERE  ((P_LIC_TIPO_OPERACION = 'V' 
      AND    TLO_LIC_NUMERO_OPERACION_ES_VE = P_LIC_NUMERO_OPERACION
      AND    TLO_LIC_NUMERO_FRACCION_ES_VEN = P_LIC_NUMERO_FRACCION
      AND    TLO_LIC_TIPO_OPERACION_ES_VEND = P_LIC_TIPO_OPERACION
      AND    TLO_LIC_BOL_MNEMONICO_ES_VEN = P_LIC_BOL_MNEMONICO)
      OR     (P_LIC_TIPO_OPERACION = 'C'
      AND    TLO_LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
      AND    TLO_LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
      AND    TLO_LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
      AND    TLO_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO))      
      AND    TLO_ENA_MNEMONICO = ENA_MNEMONICO;
   R_DT C_DATOS_TITULO%ROWTYPE;

   /*****************ESPECIE DE LA OPERACIÓN****************/
   CURSOR ESPECIE_OPERACION (P_LIC_NUMERO_OPERACION NUMBER, P_LIC_NUMERO_FRACCION NUMBER, P_LIC_TIPO_OPERACION VARCHAR2, P_LIC_BOL_MNEMONICO VARCHAR2) IS
       SELECT LIC_MNEMOTECNICO_TITULO
       FROM   LIQUIDACIONES_COMERCIAL
       WHERE  LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
       AND    LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
       AND    LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
       AND    LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO;
   ESPECIE VARCHAR2(15);

   /**********VERIFICA SI LA ESPECIE DE LA OPERACIÓN SE ENCUENTRA CREADA******/
   CURSOR C_ENA (NEMO VARCHAR2) IS
      SELECT ENA_MNEMONICO,
             ENA_AMORTIZABLE,
             ENA_CAPITALIZABLE,
             ENA_BMO_MNEMONICO,
             ENA_TIPO_PAGO_FLUJO,
             ENA_TITULO_PARTICIPATIVO
      FROM   ESPECIES_NACIONALES
      WHERE  ENA_MNEMONICO = NEMO;
   R_ENA C_ENA%ROWTYPE;

   /**********CONSULTA DE LA INFORMACIÓN REQUERIDA DE LA LIQUIDACIÓN******/
   CURSOR LIQUIDACION_COMERCIAL (P_LIC_NUMERO_OPERACION NUMBER, P_LIC_NUMERO_FRACCION NUMBER, P_LIC_TIPO_OPERACION VARCHAR2, P_LIC_BOL_MNEMONICO VARCHAR2) IS
       SELECT LIC_CLASE_TRANSACCION,
              LIC_PERIODICIDAD,
              LIC_BASE_CALCULO_INTERES,
              LIC_MODALIDAD,
              LIC_TASA_REFERENCIA,
              LIC_PUNTOS_AJUSTE,
              LIC_MNEMOTECNICO_TITULO,
              LIC_FECHA_EMISION,
              LIC_FECHA_VENCIMIENTO,
              LIC_TASA_EMISION,
              LIC_FECHA_OPERACION,
              LIC_VOLUMEN_FRACCION,
              LIC_CANTIDAD_FRACCION
       FROM   LIQUIDACIONES_COMERCIAL
       WHERE  LIC_NUMERO_OPERACION = P_LIC_NUMERO_OPERACION
       AND    LIC_NUMERO_FRACCION = P_LIC_NUMERO_FRACCION
       AND    LIC_TIPO_OPERACION = P_LIC_TIPO_OPERACION
       AND    LIC_BOL_MNEMONICO = P_LIC_BOL_MNEMONICO;
   R_LIQ LIQUIDACION_COMERCIAL%ROWTYPE;

   /****CONSULTA LA ESPECIE CON BASE EN EL ISIN****/
   CURSOR C_ISE (ISIN VARCHAR2) IS
      SELECT ISE_ENA_MNEMONICO
      FROM   ISINS_ESPECIES
      WHERE  ISE_ISI_MNEMONICO = ISIN;
   R_ISE C_ISE%ROWTYPE;


   /*********VARIABLES********/
   FUNGIBLE             NUMBER := NULL;
   ISIN                 VARCHAR2(12) := NULL;
   CUENTA_DECEVAL       NUMBER := NULL;
   CODIGO_TITULO        NUMBER := NULL;
   TASA_VALORACION      NUMBER := NULL;
   TASA_DESCUENTO       NUMBER := NULL;
   INDICADOR_VALORACION VARCHAR2(2) := NULL;
   VALOR_TITULO_TM      NUMBER;
   DESC_ERROR           VARCHAR2(1000);
   NO_NEMO              EXCEPTION;
   PERIODICIDAD         NUMBER;         
   BASE_CALCULO         NUMBER;
   MODALIDAD            VARCHAR2(1);  
   TASA_REFERENCIA      VARCHAR2(10); 

BEGIN
   OPEN C_HCC;
   FETCH C_HCC INTO R_HCC;
   WHILE C_HCC%FOUND LOOP

      VALOR_TITULO_TM       := 0;
      TASA_VALORACION       := NULL;
      TASA_DESCUENTO        := NULL;
      INDICADOR_VALORACION  := NULL;

      /********SE CONSULTA LA SUCURSAL DE CUMPLIMIENTO DE LA OPERACION*********/
      OPEN SUCURSAL_CUMPLIMIENTO(R_HCC.HCC_LIC_NUMERO_OPERACION, R_HCC.HCC_LIC_NUMERO_FRACCION, R_HCC.HCC_LIC_TIPO_OPERACION, R_HCC.HCC_LIC_BOL_MNEMONICO);
      FETCH SUCURSAL_CUMPLIMIENTO INTO SUCURSAL;
      IF SUCURSAL_CUMPLIMIENTO%FOUND THEN
         SUCURSAL := NVL(SUCURSAL, 'DVL');
      ELSE
         SUCURSAL :='DVL';
      END IF;
      CLOSE SUCURSAL_CUMPLIMIENTO;

      /*************EN CASO DE QUE LA SUCURSAL DE CUMPLIMIENTO SEA DECEVAL Y NO SEA UNA OPERACIÓN A PLAZO*****/
      IF SUCURSAL = 'DVL' AND R_HCC.HCC_CNE_MNEMONICO != 'PLZ' THEN

         /*****SE CONSULTAN LOS DATOS DE LA CUENTA CLIENTE FUNGIBLE CON BASE EN LA OPERACIÓN CONTRARIA (ANTERIOR)*****/
         BEGIN
            SELECT DECODE(R_HCC.HCC_LIC_TIPO_OPERACION, 'V', 'C', 'V') INTO R_HCC.HCC_LIC_TIPO_OPERACION
            FROM DUAL;         
         END;         
         OPEN C_DATOS_CUENTA_FUNGIBLE(R_HCC.HCC_LIC_NUMERO_OPERACION-1, R_HCC.HCC_LIC_NUMERO_FRACCION, R_HCC.HCC_LIC_TIPO_OPERACION, R_HCC.HCC_LIC_BOL_MNEMONICO);
         FETCH C_DATOS_CUENTA_FUNGIBLE INTO R_DCF;
         IF C_DATOS_CUENTA_FUNGIBLE%FOUND THEN
            FUNGIBLE       := R_DCF.MFU_CFC_FUG_MNEMONICO;
            ISIN           := R_DCF.MFU_CFC_FUG_ISI_MNEMONICO;
            CUENTA_DECEVAL := R_DCF.MFU_CFC_CUENTA_DECEVAL;    

            /******SE VERIFICA SI EL TITULO ES PARTICIPATIVO*****/
            IF NVL(R_DCF.FUG_TITULO_PARTICIPATIVO ,'N') = 'S' THEN

               IF R_DCF.FUG_BMO_MNEMONICO != 'PESOS' THEN
                  OPEN VALOR_MONEDA(R_DCF.FUG_BMO_MNEMONICO);
                  FETCH VALOR_MONEDA INTO VALOR_BMO;
                  IF VALOR_MONEDA%FOUND THEN
                     VALOR_BMO := NVL(VALOR_BMO,0);
                  ELSE
                     VALOR_BMO := 0;
                  END IF;
                  CLOSE VALOR_MONEDA;
                ELSE
                  VALOR_BMO := 1;       
                END IF;

                UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                SET  HCC_CFC_FUG_ISI_MNEMONICO   = ISIN
                     ,HCC_CFC_FUG_MNEMONICO      = FUNGIBLE
                     ,HCC_CFC_CUENTA_DECEVAL     = CUENTA_DECEVAL
                     ,HCC_INDICADOR_VALORACION   = 'PR'
                     ,HCC_VALOR_TM               = R_HCC.HCC_VALOR_NOMINAL * VALOR_BMO
                     ,HCC_VALOR_TITULO_TM        = VALOR_BMO
                WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;
            ELSE

                /******EN CASO DE QUE EL TIPO DE OPERACIÓN SEA DE RF******/
                IF R_DCF.FUG_TIPO = 'RF' THEN

                  OPEN C_ISE(ISIN);
                  FETCH C_ISE INTO R_ISE;
                  CLOSE C_ISE;

                  /****SE CORREN LOS FLUJOS PREVIAMENTE****/
                  CORRER_FLUJOS('N'
                       ,R_ISE.ISE_ENA_MNEMONICO
                       ,R_DCF.FUG_FECHA_EMISION
                       ,R_DCF.FUG_FECHA_VENCIMIENTO
                       ,R_DCF.FUG_AMORTIZABLE
                       ,R_DCF.FUG_CAPITALIZABLE
                       ,R_DCF.FUG_TRE_MNEMONICO
                       ,R_DCF.FUG_PUNTOS_ADICIONALES
                       ,R_DCF.FUG_TASA_FACIAL
                       ,R_DCF.FUG_TIPO_PAGO_FLUJO
                       ,R_DCF.FUG_CODIGO_PERIODO
                       ,R_DCF.FUG_PERIODICIDAD_TASA
                       ,R_DCF.FUG_MODALIDAD_TASA
                       ,R_DCF.FUG_BASE_CALCULO
                       ,QFECHA
                       ,1
                       ,1);                

                  --VALOR A TASA MERCADO EN LA BASE MONETARIA DEL TITULO
                  VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO ( P_TIPO            => 'FS'   -- FORMA A CALCULAR EN EL VALORIZADOR: FUNGIBLES GENERANDO FLUJOS
                                                                              ,P_ISIN            => ISIN
                                                                              ,P_FUNGIBLE        => FUNGIBLE
                                                                              ,P_VALOR_NOMINAL   => 1
                                                                              ,P_FECHA_VAL       => QFECHA
                                                                              ,P_TASA_VALORACION => TASA_VALORACION
                                                                              ,P_TASA_DESCUENTO  => TASA_DESCUENTO
                                                                              ,P_INDICADOR_VAL   => INDICADOR_VALORACION
                                                                            );            
                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;

                  IF R_DCF.FUG_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_DCF.FUG_BMO_MNEMONICO);
                     FETCH VALOR_MONEDA INTO VALOR_BMO;
                     IF VALOR_MONEDA%FOUND THEN
                        VALOR_BMO := NVL(VALOR_BMO,0);
                     ELSE
                        VALOR_BMO := 0;
                     END IF;
                     CLOSE VALOR_MONEDA;
                  ELSE
                     VALOR_BMO := 1;       
                  END IF;

                  UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                  SET  HCC_CFC_FUG_ISI_MNEMONICO   = ISIN
                       ,HCC_CFC_FUG_MNEMONICO      = FUNGIBLE
                       ,HCC_CFC_CUENTA_DECEVAL     = CUENTA_DECEVAL
                       ,HCC_INDICADOR_VALORACION   = INDICADOR_VALORACION
                       ,HCC_VALOR_TM               = R_HCC.HCC_VALOR_NOMINAL * VALOR_TITULO_TM * VALOR_BMO 
                       ,HCC_VALOR_TITULO_TM        = VALOR_TITULO_TM * VALOR_BMO
                       ,HCC_TASA_VALORACION        = TASA_VALORACION
                       ,HCC_TASA_DESCUENTO         = TASA_DESCUENTO
                  WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;

                /******EN CASO DE QUE EL TIPO DE OPERACIÓN SEA DE ACC******/
                ELSIF R_DCF.FUG_TIPO = 'ACC' THEN

                      OPEN PRECIO_ESPECIE(R_DCF.ESPECIE);
                      FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                      IF PRECIO_ESPECIE%NOTFOUND THEN
                         VALOR_ESPECIE := 0;
                      ELSE
                         VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                      END IF;
                      CLOSE PRECIO_ESPECIE;

                      UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                      SET  HCC_CFC_FUG_ISI_MNEMONICO   = ISIN
                           ,HCC_CFC_FUG_MNEMONICO      = FUNGIBLE
                           ,HCC_CFC_CUENTA_DECEVAL     = CUENTA_DECEVAL
                           ,HCC_INDICADOR_VALORACION   = 'PR'
                           ,HCC_VALOR_TM               = R_HCC.HCC_VALOR_NOMINAL * VALOR_ESPECIE
                           ,HCC_VALOR_TITULO_TM        = VALOR_ESPECIE
                      WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;
                END IF;
            END IF;

         END IF;
         CLOSE C_DATOS_CUENTA_FUNGIBLE;

      /*************EN CASO DE QUE LA SUCURSAL DE CUMPLIMIENTO SEA DCV Y NO SEA UNA OPERACIÓN A PLAZO*****/
      ELSIF SUCURSAL = 'DCV' AND R_HCC.HCC_CNE_MNEMONICO != 'PLZ' THEN

         /****************SE CONSULTA LA INFORMACIÓN RELACIONADA AL TITULO********/
         BEGIN
            SELECT DECODE(R_HCC.HCC_LIC_TIPO_OPERACION, 'V', 'C', 'V') INTO R_HCC.HCC_LIC_TIPO_OPERACION
            FROM DUAL;         
         END;      
         OPEN C_DATOS_TITULO(R_HCC.HCC_LIC_NUMERO_OPERACION-1, R_HCC.HCC_LIC_NUMERO_FRACCION, R_HCC.HCC_LIC_TIPO_OPERACION, R_HCC.HCC_LIC_BOL_MNEMONICO);
         FETCH C_DATOS_TITULO INTO R_DT;
         IF C_DATOS_TITULO%FOUND THEN
            CODIGO_TITULO := R_DT.TLO_CODIGO;         

            /******SE VERIFICA SI EL TITULO ES PARTICIPATIVO*****/
            IF NVL(R_DT.ENA_TITULO_PARTICIPATIVO,'N') = 'S' THEN

               IF R_DT.TLO_BMO_MNEMONICO != 'PESOS' THEN
                  OPEN VALOR_MONEDA(R_DT.TLO_BMO_MNEMONICO);
                  FETCH VALOR_MONEDA INTO VALOR_BMO;
                  IF VALOR_MONEDA%FOUND THEN
                     VALOR_BMO := NVL(VALOR_BMO,0);
                  ELSE
                     VALOR_BMO := 0;
                  END IF;
                  CLOSE VALOR_MONEDA;
                ELSE
                  VALOR_BMO := 1;       
                END IF;

                UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                SET  HCC_TLO_CODIGO              = CODIGO_TITULO
                     ,HCC_INDICADOR_VALORACION   = 'PR'
                     ,HCC_VALOR_TM               = R_HCC.HCC_VALOR_NOMINAL * VALOR_BMO
                     ,HCC_VALOR_TITULO_TM        = VALOR_BMO
                WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;
            ELSE

               /******EN CASO DE QUE EL TIPO DE OPERACIÓN SEA DE RF******/
               IF R_DT.TLO_TYPE = 'TFC' THEN

                  /****SE CORREN LOS FLUJOS PREVIAMENTE*****/
                  CORRER_FLUJOS('S'
                         ,R_DT.TLO_ENA_MNEMONICO
                         ,R_DT.TLO_FECHA_EMISION
                         ,R_DT.TLO_FECHA_VENCIMIENTO
                         ,R_DT.TLO_AMORTIZABLE
                         ,R_DT.TLO_CAPITALIZABLE
                         ,R_DT.TLO_TRE_MNEMONICO
                         ,R_DT.TLO_PUNTOS_ADICIONALES
                         ,R_DT.TLO_TASA_FACIAL
                         ,R_DT.TLO_TIPO_PAGO_FLUJO
                         ,R_DT.TLO_CODIGO_PERIODO
                         ,R_DT.TLO_PERIODICIDAD_TASA
                         ,R_DT.TLO_MODALIDAD_TASA
                         ,R_DT.TLO_BASE_CALCULO
                         ,QFECHA                        -- genera los flujos de la fecha valoracion en adelante
                         ,R_DT.TLO_VALOR_NOMINAL
                         ,R_DT.TLO_VALOR_NOMINAL);

                    -- VALOR DE TASA MERCADO EN LA BASE MONETARIA DEL TITULO
                  VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO ( P_TIPO            => 'TS'   -- FORMA A CALULAR EN EL VALORIZADOR : TITULOS CLIENTES GENERANDO FLUJOS
                                                                              ,P_TITULO          => CODIGO_TITULO
                                                                              ,P_FECHA_VAL       => QFECHA
                                                                              ,P_TASA_VALORACION => TASA_VALORACION
                                                                              ,P_TASA_DESCUENTO  => TASA_DESCUENTO
                                                                              ,P_INDICADOR_VAL   => INDICADOR_VALORACION
                                                                             );            
                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;

                  IF R_DT.TLO_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_DT.TLO_BMO_MNEMONICO);
                     FETCH VALOR_MONEDA INTO VALOR_BMO;
                     IF VALOR_MONEDA%FOUND THEN
                         VALOR_BMO := NVL(VALOR_BMO,0);
                     ELSE
                         VALOR_BMO := 0;
                     END IF;
                     CLOSE VALOR_MONEDA;
                  ELSE
                     VALOR_BMO := 1;       
                  END IF;

                  UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                  SET  HCC_TLO_CODIGO              = CODIGO_TITULO
                       ,HCC_INDICADOR_VALORACION   = INDICADOR_VALORACION
                       ,HCC_VALOR_TM               = VALOR_TITULO_TM * VALOR_BMO 
                       ,HCC_VALOR_TITULO_TM        = (VALOR_TITULO_TM * VALOR_BMO)/R_DT.TLO_VALOR_NOMINAL
                       ,HCC_TASA_VALORACION        = TASA_VALORACION
                       ,HCC_TASA_DESCUENTO         = TASA_DESCUENTO
                  WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;

                /******EN CASO DE QUE EL TIPO DE OPERACIÓN SEA DE ACC******/
                ELSIF R_DT.TLO_TYPE = 'ACC' THEN

                      OPEN PRECIO_ESPECIE(R_DT.TLO_ENA_MNEMONICO);
                      FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                      IF PRECIO_ESPECIE%NOTFOUND THEN
                         VALOR_ESPECIE := 0;
                      ELSE
                         VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                      END IF;
                      CLOSE PRECIO_ESPECIE;

                      UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                      SET  HCC_TLO_CODIGO              = CODIGO_TITULO
                           ,HCC_INDICADOR_VALORACION   = 'PR'
                           ,HCC_VALOR_TM               = R_HCC.HCC_VALOR_NOMINAL * VALOR_ESPECIE 
                           ,HCC_VALOR_TITULO_TM        = VALOR_ESPECIE
                      WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;
                END IF;
            END IF;
         END IF;
         CLOSE C_DATOS_TITULO;
      END IF;   

      /*************EN CASO DE QUE LA SUCURSAL DE CUMPLIMIENTO SEA DCV O DECEVAL Y SEA UNA OPERACIÓN A PLAZO O NO SE HAYA ENCONTRADO INFORMACIÓN PREVIAMENTE*****/
      IF SUCURSAL IN ('DCV', 'DVL') AND R_HCC.HCC_CNE_MNEMONICO = 'PLZ' OR (CODIGO_TITULO IS NULL AND CUENTA_DECEVAL IS NULL AND ISIN IS NULL AND FUNGIBLE IS NULL)   THEN

            OPEN ESPECIE_OPERACION(R_HCC.HCC_LIC_NUMERO_OPERACION, R_HCC.HCC_LIC_NUMERO_FRACCION, R_HCC.HCC_LIC_TIPO_OPERACION, R_HCC.HCC_LIC_BOL_MNEMONICO);
            FETCH ESPECIE_OPERACION INTO ESPECIE;
            IF ESPECIE_OPERACION%FOUND THEN
               ESPECIE := NVL(ESPECIE, '');
            ELSE
               ESPECIE :='';
            END IF;
            CLOSE ESPECIE_OPERACION;

            OPEN C_ENA(ESPECIE);
            FETCH C_ENA INTO R_ENA;
            IF C_ENA%NOTFOUND THEN
               RAISE NO_NEMO;           
            END IF;
            CLOSE C_ENA;

            /**********EN CASO DE QUE EL TITULO SEA PARTICIPATIVO*******/
            IF R_ENA.ENA_TITULO_PARTICIPATIVO = 'S' THEN

               IF R_ENA.ENA_BMO_MNEMONICO != 'PESOS' THEN
                  OPEN VALOR_MONEDA(R_ENA.ENA_BMO_MNEMONICO);
                  FETCH VALOR_MONEDA INTO VALOR_BMO;
                  IF VALOR_MONEDA%FOUND THEN
                     VALOR_BMO := NVL(VALOR_BMO,0);
                  ELSE
                     VALOR_BMO := 0;
                  END IF;
                  CLOSE VALOR_MONEDA;
               ELSE
                  VALOR_BMO := 1;       
               END IF;

               UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                  SET  HCC_INDICADOR_VALORACION   = INDICADOR_VALORACION
                       ,HCC_VALOR_TM               = VALOR_TITULO_TM * VALOR_BMO
                       ,HCC_VALOR_TITULO_TM        = VALOR_BMO
                       ,HCC_TASA_VALORACION        = TASA_VALORACION
                       ,HCC_TASA_DESCUENTO         = TASA_DESCUENTO
                  WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;
            ELSE

               /*****SE CONSULTAN LOS DATOS DE LA LIQUIDACIÓN CON BASE EN LA OPERACIÓN CONTRARIA (ANTERIOR)*****/
               BEGIN
                  SELECT DECODE(R_HCC.HCC_LIC_TIPO_OPERACION, 'V', 'C', 'V') INTO R_HCC.HCC_LIC_TIPO_OPERACION
                  FROM DUAL;         
               END;   
               OPEN LIQUIDACION_COMERCIAL(R_HCC.HCC_LIC_NUMERO_OPERACION-1, R_HCC.HCC_LIC_NUMERO_FRACCION, R_HCC.HCC_LIC_TIPO_OPERACION, R_HCC.HCC_LIC_BOL_MNEMONICO);
               FETCH LIQUIDACION_COMERCIAL INTO R_LIQ;
               CLOSE LIQUIDACION_COMERCIAL;            

               /******EN CASO DE QUE EL TIPO DE OPERACIÓN SEA DE RF******/
               IF R_LIQ.LIC_CLASE_TRANSACCION = 'RF' THEN

                  IF R_LIQ.LIC_PERIODICIDAD = 'N' THEN
                        PERIODICIDAD := NULL;
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'M' THEN
                        PERIODICIDAD := 30;
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'B' THEN
                        PERIODICIDAD := 60;            
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'T' THEN
                        PERIODICIDAD := 90;
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'C' THEN
                        PERIODICIDAD := 120;
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'S' THEN
                        PERIODICIDAD := 180;      
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'A' THEN
                        IF R_LIQ.LIC_BASE_CALCULO_INTERES = 'C' THEN 
                           PERIODICIDAD := 360;
                        ELSE
                           PERIODICIDAD := 365;
                        END IF;
                  ELSIF R_LIQ.LIC_PERIODICIDAD = 'P' THEN
                       IF R_LIQ.LIC_BASE_CALCULO_INTERES = 'C' THEN
                          PERIODICIDAD := P_FINANCIERO.DIAS360(TRUNC(R_LIQ.LIC_FECHA_VENCIMIENTO),TRUNC(R_LIQ.LIC_FECHA_EMISION));            
                       ELSE
                          PERIODICIDAD := P_FINANCIERO.DIAS_365(TRUNC(R_LIQ.LIC_FECHA_EMISION),TRUNC(R_LIQ.LIC_FECHA_VENCIMIENTO));            
                       END IF;
                  ELSIF R_LIQ.LIC_PERIODICIDAD = '0' THEN
                     PERIODICIDAD := 0;
                  ELSE
                     PERIODICIDAD := NULL;
                  END IF;

                  IF R_LIQ.LIC_BASE_CALCULO_INTERES = 'C' THEN
                     BASE_CALCULO := 360;
                  ELSE 
                     BASE_CALCULO := 365;
                  END IF;

                  IF R_LIQ.LIC_MODALIDAD = 'O' THEN
                     MODALIDAD := 'D';
                     PERIODICIDAD := 0;
                  ELSE
                     MODALIDAD := R_LIQ.LIC_MODALIDAD;
                  END IF;

                  IF NVL(R_LIQ.LIC_TASA_REFERENCIA,'0') = '0' THEN
                     TASA_REFERENCIA := NULL;
                  ELSE
                     TASA_REFERENCIA := P_TOOLS.FN_LIC_TASA_REFERENCIA(R_LIQ.LIC_TASA_REFERENCIA);
                     IF TASA_REFERENCIA = '0' THEN
                        TASA_REFERENCIA := NULL;
                     END IF;
                  END IF;

                  IF TASA_REFERENCIA IS NULL THEN
                     R_LIQ.LIC_PUNTOS_AJUSTE := NULL;
                  ELSE
                     IF R_LIQ.LIC_PUNTOS_AJUSTE IS NULL THEN
                        R_LIQ.LIC_PUNTOS_AJUSTE := 0;
                     END IF;
                  END IF;

                  /**** SE GENERAN LOS FLUJOS REQUERIDOS*********/
                  CORRER_FLUJOS( 'S'
                                 ,R_LIQ.LIC_MNEMOTECNICO_TITULO
                                 ,R_LIQ.LIC_FECHA_EMISION
                                 ,R_LIQ.LIC_FECHA_VENCIMIENTO
                                 ,R_ENA.ENA_AMORTIZABLE
                                 ,R_ENA.ENA_CAPITALIZABLE
                                 ,TASA_REFERENCIA
                                 ,R_LIQ.LIC_PUNTOS_AJUSTE
                                 ,R_LIQ.LIC_TASA_EMISION
                                 ,R_ENA.ENA_TIPO_PAGO_FLUJO
                                 ,R_LIQ.LIC_PERIODICIDAD||R_LIQ.LIC_MODALIDAD
                                 ,PERIODICIDAD
                                 ,MODALIDAD
                                 ,BASE_CALCULO
                                 ,R_LIQ.LIC_FECHA_OPERACION
                                 ,R_LIQ.LIC_VOLUMEN_FRACCION
                                 ,R_LIQ.LIC_CANTIDAD_FRACCION);

                  -- VALOR DE TASA MERCADO EN LA BASE MONETARIA DE LA LIQUIDACION      
                  VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO 
                                               ( P_TIPO => 'OT'   -- FORMA A CALULAR EN EL VALORIZADOR
                                                ,P_VALOR_NOMINAL      => R_LIQ.LIC_CANTIDAD_FRACCION
                                                ,P_FECHA_VAL          => QFECHA  -- FECHA VALORACION
                                                ,P_ENA_MNEMONICO      => R_LIQ.LIC_MNEMOTECNICO_TITULO   
                                                ,P_FECHA_EMISION      => R_LIQ.LIC_FECHA_EMISION
                                                ,P_FECHA_VENCIMIENTO  => R_LIQ.LIC_FECHA_VENCIMIENTO
                                                ,P_PERIODICIDAD_TASA  => PERIODICIDAD
                                                ,P_MODALIDAD_TASA     => MODALIDAD
                                                ,P_TASA_FACIAL        => R_LIQ.LIC_TASA_EMISION
                                                ,P_BMO_MNEMONICO      => R_ENA.ENA_BMO_MNEMONICO
                                                ,P_TRE_MNEMONICO      => TASA_REFERENCIA
                                                ,P_PUNTOS_ADICIONALES => R_LIQ.LIC_PUNTOS_AJUSTE
                                                ,P_BASE_CALCULO       => BASE_CALCULO
                                                ,P_TASA_VALORACION    => TASA_VALORACION
                                                ,P_TASA_DESCUENTO     => TASA_DESCUENTO
                                                ,P_INDICADOR_VAL      => INDICADOR_VALORACION
                                                );

                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;

                  IF R_ENA.ENA_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_ENA.ENA_BMO_MNEMONICO);
                     FETCH VALOR_MONEDA INTO VALOR_BMO;
                     IF VALOR_MONEDA%FOUND THEN
                        VALOR_BMO := NVL(VALOR_BMO,0);
                     ELSE
                        VALOR_BMO := 0;
                     END IF;
                     CLOSE VALOR_MONEDA;
                  ELSE
                     VALOR_BMO := 1;       
                  END IF;

                  UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                  SET  HCC_INDICADOR_VALORACION   = INDICADOR_VALORACION
                       ,HCC_VALOR_TM               = VALOR_TITULO_TM * VALOR_BMO 
                       ,HCC_VALOR_TITULO_TM        = (VALOR_TITULO_TM * VALOR_BMO)/R_LIQ.LIC_CANTIDAD_FRACCION
                       ,HCC_TASA_VALORACION        = TASA_VALORACION
                       ,HCC_TASA_DESCUENTO         = TASA_DESCUENTO
                  WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;   

            ELSIF R_LIQ.LIC_CLASE_TRANSACCION = 'ACC' THEN

                  OPEN PRECIO_ESPECIE(R_LIQ.LIC_MNEMOTECNICO_TITULO);
                  FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                  IF PRECIO_ESPECIE%NOTFOUND THEN
                     VALOR_ESPECIE := 0;
                  ELSE
                     VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                  END IF;
                  CLOSE PRECIO_ESPECIE;

                  UPDATE HISTORICOS_COMPROMISOS_CLIENTE
                  SET  HCC_INDICADOR_VALORACION   = 'PR'
                       ,HCC_VALOR_TM               = R_LIQ.LIC_CANTIDAD_FRACCION * VALOR_ESPECIE 
                       ,HCC_VALOR_TITULO_TM        = VALOR_ESPECIE
                  WHERE HCC_CONSECUTIVO            = R_HCC.HCC_CONSECUTIVO;
            END IF;      
        END IF;            
      END IF;
      FETCH C_HCC INTO R_HCC;
   END LOOP;
   CLOSE C_HCC;
   COMMIT;

EXCEPTION
     WHEN NO_NEMO THEN
      INSERT INTO HST_ERROR
             (HRR_FECHA,
              HRR_CONSECUTIVO,
              HRR_DESCRIPCION,
              HRR_ORIGEN)
      VALUES (QFECHA,  
              P_CONSECUTIVO,
              'NO ESTA CREADO EL NEMO EN COEASY '||ESPECIE,
              'HCC');
   WHEN OTHERS THEN
      DESC_ERROR := SUBSTR(sqlerrm,1,990);
      INSERT INTO HST_ERROR
             (HRR_FECHA,
              HRR_CONSECUTIVO,
              HRR_DESCRIPCION,
              HRR_ORIGEN)
      VALUES (QFECHA,  --SYSDATE,
              P_CONSECUTIVO,
              DESC_ERROR,
              'HCC');

END GENERAR_VALORACION_COMPROMISOS;  

PROCEDURE BORRAR_DIFERENTE_FIN_MES_COMP
   (P_FECHA IN  DATE) IS
    ULT_FIN_MES DATE;     -- FECHA DEL ULTIMO FIN DE MES INGRESADO

   CURSOR C_FECHA IS
      SELECT DISTINCT HCC_FECHA
      FROM HISTORICOS_COMPROMISOS_CLIENTE
      WHERE HCC_FECHA >= TRUNC(ULT_FIN_MES + 1)
        AND HCC_FECHA < TRUNC(P_FECHA);
   R_FECHA C_FECHA%ROWTYPE;            

BEGIN
   SELECT LAST_DAY(ADD_MONTHS(P_FECHA,-1)) INTO ULT_FIN_MES FROM DUAL;
   DBMS_OUTPUT.PUT_LINE(ULT_FIN_MES);
   DBMS_OUTPUT.PUT_LINE(P_FECHA);
   OPEN C_FECHA;
   FETCH C_FECHA INTO R_FECHA;
   WHILE C_FECHA%FOUND LOOP
      DELETE FROM HISTORICOS_COMPROMISOS_CLIENTE
      WHERE HCC_FECHA >= TRUNC(R_FECHA.HCC_FECHA)
        AND HCC_FECHA <  TRUNC(R_FECHA.HCC_FECHA+1);

         DBMS_OUTPUT.PUT_LINE('SE BORRARON REGISTROS DEL DIA '||TO_CHAR(R_FECHA.HCC_FECHA,'DD-MON-YYYY'));
         COMMIT;
      FETCH C_FECHA INTO R_FECHA;
   END LOOP;
   CLOSE C_FECHA;
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso BORRAR_DIFERENTE_FIN_MES_COMP','Error en procedimiento BORRAR_DIFERENTE_FIN_MES_COMP: '||substr(sqlerrm,1,80));   
      RAISE_APPLICATION_ERROR(-20010,'Error en procedimiento BORRAR_DIFERENTE_FIN_MES_COMP: '||sqlerrm);          
END BORRAR_DIFERENTE_FIN_MES_COMP;


-- PROCEDIMIENTO PARA VALORACION DE PORTAFOLIO DIARIO DE LOS CLIENTES
PROCEDURE VALORAR_SALDOS_DIA (QFECHA DATE) IS

   CURSOR C_HST IS
      SELECT HST_CONSECUTIVO ,
             HST_FECHA ,
             HST_CCC_CLI_PER_NUM_IDEN ,
             HST_CCC_CLI_PER_TID_CODIGO ,
             HST_CCC_NUMERO_CUENTA ,
             HST_SALDO_DISPONIBLE ,
             HST_SALDO_GARANTIA ,
             HST_SALDO_EMBARGO ,
             HST_VALOR_TM_DISPONIBLE ,
             HST_VALOR_TM_GARANTIA ,
             HST_VALOR_TM_EMBARGO ,
             HST_CFC_FUG_ISI_MNEMONICO ,
             HST_CFC_FUG_MNEMONICO ,
             HST_CFC_CUENTA_DECEVAL ,
             HST_TLO_CODIGO ,
             HST_INDICADOR_VALORACION ,
             HST_TASA_VALORACION ,
             HST_TASA_DESCUENTO ,
             HST_SALDO_RETARDO ,                    -- OMORA
             HST_VALOR_TM_RETARDO                   -- OMORA
      FROM HISTORICOS_SALDOS_TITULOS
      WHERE HST_FECHA >= TRUNC(QFECHA)
        AND HST_FECHA <  TRUNC(QFECHA+1);
   R_HST C_HST%ROWTYPE;        

   DESC_ERROR VARCHAR2(1000);
BEGIN
   OPEN C_HST;
   FETCH C_HST INTO R_HST;
   WHILE C_HST%FOUND LOOP
         -- SE CREARAN LOS FLUJOS AL MOMENTO DE VALORAR
         P_CLIENTES_TITULOS.GENERAR_FLUJOS_HCO(QFECHA,R_HST.HST_CONSECUTIVO);
         GENERAR_VALORACION_TITULO(QFECHA,R_HST.HST_CONSECUTIVO);
      FETCH C_HST INTO R_HST;
   END LOOP;
   CLOSE C_HST;
   COMMIT;    
   /**************************************************************************************************************************
     PARA LOS TITULOS QUE NO VALORIZARON, SE ACTUALIZAN LOS VALORES DE TM CON EL VALOR_NOMINAL
     --- OJO!!!   ESTO ES UNICAMENTE POR PERIODO DE PRUEBAS Y MIESTRAS SE REALIZA LA REVISION DE LOS DATOS FACIALES
                  DE ESPECIES    Y FUNGIBLES                                                                            
   ********************************************************************************************************************* ***/
   /*UPDATE HISTORICOS_SALDOS_TITULOS
   SET HST_VALOR_TM_DISPONIBLE = HST_SALDO_DISPONIBLE
   WHERE HST_VALOR_TM_DISPONIBLE = 0
     AND HST_INDICADOR_VALORACION IS NULL;

   UPDATE HISTORICOS_SALDOS_TITULOS
   SET HST_VALOR_TM_GARANTIA = HST_SALDO_GARANTIA
   WHERE HST_VALOR_TM_GARANTIA = 0
     AND HST_INDICADOR_VALORACION IS NULL;

   UPDATE HISTORICOS_SALDOS_TITULOS
   SET HST_VALOR_TM_EMBARGO = HST_SALDO_EMBARGO
   WHERE HST_VALOR_TM_EMBARGO = 0
     AND HST_INDICADOR_VALORACION IS NULL;  */
   COMMIT;  
EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso VALORAR_SALDOS_DIA','Error en procedimiento VALORAR_SALDOS_DIA: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20011,'Error en procedimiento VALORAR_SALDOS_DIA: '||sqlerrm);
END VALORAR_SALDOS_DIA;    

PROCEDURE GENERAR_VALORACION_TITULO (QFECHA DATE, P_CONSECUTIVO NUMBER) IS
   CURSOR C_HST IS
      SELECT HST_CONSECUTIVO ,
             HST_FECHA ,
             HST_CCC_CLI_PER_NUM_IDEN ,
             HST_CCC_CLI_PER_TID_CODIGO ,
             HST_CCC_NUMERO_CUENTA ,
             HST_SALDO_DISPONIBLE ,
             HST_SALDO_GARANTIA ,
             HST_SALDO_EMBARGO ,
             HST_SALDO_GARANTIA_REPO,
             HST_SALDO_POR_CUMPLIR,
			       HST_SALDO_CPR_X_CUMPLIR,
             HST_SALDO_TRANSITO_ING,
             HST_SALDO_TRANSITO_RET,
             HST_SALDO_GARANTIA_DER ,         
             HST_VALOR_TM_DISPONIBLE ,
             HST_VALOR_TM_GARANTIA ,
             HST_VALOR_TM_EMBARGO ,
             HST_CFC_FUG_ISI_MNEMONICO ,
             HST_CFC_FUG_MNEMONICO ,
             HST_CFC_CUENTA_DECEVAL ,
             HST_TLO_CODIGO ,
             HST_INDICADOR_VALORACION ,
             HST_TASA_VALORACION ,
             HST_TASA_DESCUENTO ,
             HST_SALDO_RETARDO                                 -- OMORA
      FROM HISTORICOS_SALDOS_TITULOS
      WHERE HST_FECHA >= TRUNC(QFECHA)
        AND HST_FECHA <  TRUNC(QFECHA+1)
        AND HST_CONSECUTIVO = P_CONSECUTIVO;
   R_HST C_HST%ROWTYPE;        

   CURSOR C_FUG (ISI VARCHAR2, FUG NUMBER) IS
      SELECT FUG_TIPO,
             FUG_BMO_MNEMONICO,
             FUG_TITULO_PARTICIPATIVO,
             FUG_ENA_MNEMONICO ESPECIE
      FROM FUNGIBLES
      WHERE FUG_ISI_MNEMONICO = ISI;
   R_FUG C_FUG%ROWTYPE;                                          

   CURSOR C_TLO (NTIT NUMBER) IS
      SELECT TLO_TYPE,
             TLO_BMO_MNEMONICO,
             TLO_ENA_MNEMONICO,
             ENA_TITULO_PARTICIPATIVO
      FROM TITULOS,
           ESPECIES_NACIONALES
      WHERE TLO_ENA_MNEMONICO = ENA_MNEMONICO
        AND TLO_CODIGO = NTIT;
   R_TLO C_TLO%ROWTYPE;      

   CURSOR PRECIO_ESPECIE (ENA VARCHAR2) IS
      SELECT PEB_PRECIO_BOLSA
      FROM PRECIOS_ESPECIES_BOLSA A
      WHERE PEB_ENA_MNEMONICO = ENA
        AND PEB_FECHA = (SELECT MAX(PEB_FECHA )
                         FROM PRECIOS_ESPECIES_BOLSA B
                         WHERE B.PEB_ENA_MNEMONICO = ENA
                           AND PEB_FECHA < TRUNC(QFECHA + 1));
   VALOR_ESPECIE NUMBER;

    CURSOR VALOR_MONEDA (BMO VARCHAR2) IS
       SELECT NVL(CBM_VALOR,0) CBM_VALOR
       FROM COTIZACIONES_BASE_MONETARIAS
       WHERE CBM_BMO_MNEMONICO = BMO
         AND TRUNC(CBM_FECHA) = DECODE(BMO,'DOLAR',TRUNC(QFECHA+1),TRUNC(QFECHA));

   VALOR_BMO NUMBER;


   VALOR_TITULO_TM NUMBER;
   TASA_VALORACION NUMBER := NULL;
   TASA_DESCUENTO NUMBER := NULL;
   INDICADOR_VALORACION VARCHAR2(2) := NULL;
   DESC_ERROR VARCHAR2(1000);
BEGIN
   OPEN C_HST;
   FETCH C_HST INTO R_HST;
   WHILE C_HST%FOUND LOOP
       VALOR_TITULO_TM := 0;
       TASA_VALORACION := NULL;
       TASA_DESCUENTO  := NULL;
       INDICADOR_VALORACION  := NULL;

      IF R_HST.HST_CFC_FUG_ISI_MNEMONICO IS NOT NULL THEN
         OPEN C_FUG(R_HST.HST_CFC_FUG_ISI_MNEMONICO,
                    R_HST.HST_CFC_FUG_MNEMONICO);
         FETCH C_FUG INTO R_FUG;
         IF C_FUG%FOUND THEN
            dbms_output.put_line(r_hst.hst_cfc_fug_isi_mnemonico||'-***-'||r_fug.fug_tipo);
            IF NVL(R_FUG.FUG_TITULO_PARTICIPATIVO ,'N') = 'S' THEN   -- TITULOS PARTICIPATIVOS = valor_nominal * vr. unidad
              -- INICIO OMORA
              IF R_FUG.FUG_TIPO = 'ACC' THEN
                 -- SE BUSCA EL PRECIO DE LA ESPECIE RV EN PRECIOS_ESPECIES_BOLSA
                  OPEN PRECIO_ESPECIE(R_FUG.ESPECIE);
                  FETCH PRECIO_ESPECIE INTO VALOR_BMO;
                  IF PRECIO_ESPECIE%NOTFOUND THEN
                        VALOR_BMO := 0;
                  ELSE
                        VALOR_BMO := NVL(VALOR_BMO,0);
                  END IF;
                  CLOSE PRECIO_ESPECIE;              
              ELSE  
              -- FIN OMORA
               IF R_FUG.FUG_BMO_MNEMONICO != 'PESOS' THEN
                  OPEN VALOR_MONEDA(R_FUG.FUG_BMO_MNEMONICO);
                  FETCH VALOR_MONEDA INTO VALOR_BMO;
                  IF VALOR_MONEDA%FOUND THEN
                     VALOR_BMO := NVL(VALOR_BMO,0);
                  ELSE
                     VALOR_BMO := 0;
                  END IF;
                  CLOSE VALOR_MONEDA;
               ELSE
                  VALOR_BMO := 1;       
               END IF;
               END IF;
               UPDATE HISTORICOS_SALDOS_TITULOS
               SET  HST_VALOR_TM_DISPONIBLE   = HST_SALDO_DISPONIBLE * VALOR_BMO
                   ,HST_VALOR_TM_GARANTIA     = HST_SALDO_GARANTIA * VALOR_BMO
                   ,HST_VALOR_TM_EMBARGO      = HST_SALDO_EMBARGO * VALOR_BMO
                   ,HST_VALOR_TM_GARREPO      = HST_SALDO_GARANTIA_REPO * VALOR_BMO
                   ,HST_VALOR_TM_XCUMPLIR     = HST_SALDO_POR_CUMPLIR * VALOR_BMO
		        		   ,HST_VALOR_TM_CPR_X_CUMPLIR     = HST_SALDO_CPR_X_CUMPLIR * VALOR_BMO
                   ,HST_VALOR_TM_TRANING      = HST_SALDO_TRANSITO_ING  * VALOR_BMO
                   ,HST_VALOR_TM_TRANRET      = HST_SALDO_TRANSITO_RET * VALOR_BMO 
                   ,HST_VALOR_TM_GARDER       = HST_SALDO_GARANTIA_DER * VALOR_BMO          
                   ,HST_VALOR_TM_RETARDO      = HST_SALDO_RETARDO * VALOR_BMO				 -- OMORA
                   ,HST_INDICADOR_VALORACION  = 'PR'
                   ,HST_TASA_VALORACION       = ''
                   ,HST_TASA_DESCUENTO        = ''
               WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
            ELSE
               IF R_FUG.FUG_TIPO = 'RF' THEN
                    --VALOR A TASA MERCADO EN LA BASE MONETARIA DEL TITULO
                  VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO ( P_TIPO            => 'FS'   -- FORMA A CALCULAR EN EL VALORIZADOR: FUNGIBLES GENERANDO FLUJOS
                                                                        ,P_ISIN            => R_HST.HST_CFC_FUG_ISI_MNEMONICO
                                                                        ,P_FUNGIBLE        => R_HST.HST_CFC_FUG_MNEMONICO
                                                                        ,P_VALOR_NOMINAL   => 1
                                                                        ,P_FECHA_VAL       => QFECHA
                                                                        ,P_TASA_VALORACION => TASA_VALORACION
                                                                        ,P_TASA_DESCUENTO  => TASA_DESCUENTO
                                                                        ,P_INDICADOR_VAL   => INDICADOR_VALORACION
                                                                        );            
                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;

                  IF R_FUG.FUG_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_FUG.FUG_BMO_MNEMONICO);
                         FETCH VALOR_MONEDA INTO VALOR_BMO;
                         IF VALOR_MONEDA%FOUND THEN
                            VALOR_BMO := NVL(VALOR_BMO,0);
                         ELSE
                              VALOR_BMO := 0;
                         END IF;
                     CLOSE VALOR_MONEDA;
                      ELSE
                         VALOR_BMO := 1;       
                  END IF;

                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_DISPONIBLE   =  HST_SALDO_DISPONIBLE * VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_GARANTIA     =  HST_SALDO_GARANTIA * VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_EMBARGO      =  HST_SALDO_EMBARGO *  VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_GARREPO      =  HST_SALDO_GARANTIA_REPO *  VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_XCUMPLIR     =  HST_SALDO_POR_CUMPLIR *  VALOR_TITULO_TM * VALOR_BMO  
				          	  ,HST_VALOR_TM_CPR_X_CUMPLIR     =  HST_SALDO_CPR_X_CUMPLIR *  VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_TRANING      =  HST_SALDO_TRANSITO_ING  *  VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_TRANRET      =  HST_SALDO_TRANSITO_RET *  VALOR_TITULO_TM * VALOR_BMO  
                      ,HST_VALOR_TM_GARDER       =  HST_SALDO_GARANTIA_DER *  VALOR_TITULO_TM * VALOR_BMO  
					  ,HST_VALOR_TM_RETARDO      =  HST_SALDO_RETARDO * VALOR_TITULO_TM * VALOR_BMO           -- OMORA
                      ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                      ,HST_TASA_VALORACION       = TASA_VALORACION
                      ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;


               ELSIF R_FUG.FUG_TIPO = 'ACC' THEN
                  OPEN PRECIO_ESPECIE(R_FUG.ESPECIE);
                  FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                  IF PRECIO_ESPECIE%NOTFOUND THEN
                        VALOR_ESPECIE := 0;
                  ELSE
                        VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                  END IF;
                  CLOSE PRECIO_ESPECIE;
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_DISPONIBLE   = HST_SALDO_DISPONIBLE * VALOR_ESPECIE
                      ,HST_VALOR_TM_GARANTIA     = HST_SALDO_GARANTIA * VALOR_ESPECIE
                      ,HST_VALOR_TM_EMBARGO      = HST_SALDO_EMBARGO * VALOR_ESPECIE
                      ,HST_VALOR_TM_GARREPO      = HST_SALDO_GARANTIA_REPO * VALOR_ESPECIE
                      ,HST_VALOR_TM_XCUMPLIR     = HST_SALDO_POR_CUMPLIR * VALOR_ESPECIE
					            ,HST_VALOR_TM_CPR_X_CUMPLIR     = HST_SALDO_CPR_X_CUMPLIR * VALOR_ESPECIE
                      ,HST_VALOR_TM_TRANING      = HST_SALDO_TRANSITO_ING * VALOR_ESPECIE
                      ,HST_VALOR_TM_TRANRET      = HST_SALDO_TRANSITO_RET * VALOR_ESPECIE
                      ,HST_VALOR_TM_GARDER       = HST_SALDO_GARANTIA_DER * VALOR_ESPECIE
					  ,HST_VALOR_TM_RETARDO      = HST_SALDO_RETARDO * VALOR_ESPECIE            -- OMORA
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               END IF;
            END IF;
         END IF;
         CLOSE C_FUG;
      ELSIF R_HST.HST_TLO_CODIGO IS NOT NULL THEN
         OPEN C_TLO(R_HST.HST_TLO_CODIGO);
         FETCH C_TLO INTO R_TLO;
         IF C_TLO%FOUND THEN
            IF NVL(R_TLO.ENA_TITULO_PARTICIPATIVO,'N') = 'S' THEN
               IF R_TLO.TLO_BMO_MNEMONICO != 'PESOS' THEN
                  OPEN VALOR_MONEDA(R_TLO.TLO_BMO_MNEMONICO);
                    FETCH VALOR_MONEDA INTO VALOR_BMO;
                    IF VALOR_MONEDA%FOUND THEN
                       VALOR_BMO := NVL(VALOR_BMO,0);
                      ELSE
                            VALOR_BMO := 0;
                      END IF;
                  CLOSE VALOR_MONEDA;
                   ELSE
                      VALOR_BMO := 1;       
               END IF;
               IF R_HST.HST_SALDO_DISPONIBLE != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_DISPONIBLE   = HST_SALDO_DISPONIBLE * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_GARANTIA != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_GARANTIA     = HST_SALDO_GARANTIA * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_EMBARGO != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_EMBARGO     = HST_SALDO_EMBARGO * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_GARANTIA_REPO != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_GARREPO     = HST_SALDO_GARANTIA_REPO * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_POR_CUMPLIR != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_XCUMPLIR     = HST_SALDO_POR_CUMPLIR * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
			    ELSIF R_HST.HST_SALDO_CPR_X_CUMPLIR != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_CPR_X_CUMPLIR     = HST_SALDO_CPR_X_CUMPLIR * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_TRANSITO_ING != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_TRANING     = HST_SALDO_TRANSITO_ING * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_TRANSITO_RET != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_TRANRET     = HST_SALDO_TRANSITO_RET * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               ELSIF R_HST.HST_SALDO_GARANTIA_DER != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_GARDER         = HST_SALDO_GARANTIA_DER * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               -- OMORA
               ELSIF R_HST.HST_SALDO_RETARDO != 0 THEN
                  UPDATE HISTORICOS_SALDOS_TITULOS
                  SET  HST_VALOR_TM_RETARDO         = HST_SALDO_RETARDO * VALOR_BMO
                      ,HST_INDICADOR_VALORACION  = 'PR'
                      ,HST_TASA_VALORACION       = ''
                      ,HST_TASA_DESCUENTO        = ''
                  WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
               -- OMORA				  
               END IF;
            ELSE
               IF R_TLO.TLO_TYPE = 'TFC' THEN
                    -- VALOR DE TASA MERCADO EN LA BASE MONETARIA DEL TITULO
                  VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO ( P_TIPO            => 'TS'   -- FORMA A CALULAR EN EL VALORIZADOR : TITULOS CLIENTES GENERANDO FLUJOS
                                                                              ,P_TITULO          => R_HST.HST_TLO_CODIGO
                                                                              ,P_FECHA_VAL       => QFECHA
                                                                              ,P_TASA_VALORACION => TASA_VALORACION
                                                                              ,P_TASA_DESCUENTO  => TASA_DESCUENTO
                                                                              ,P_INDICADOR_VAL   => INDICADOR_VALORACION
                                                                             );            
                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;
                  IF R_TLO.TLO_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_TLO.TLO_BMO_MNEMONICO);
                         FETCH VALOR_MONEDA INTO VALOR_BMO;
                         IF VALOR_MONEDA%FOUND THEN
                            VALOR_BMO := NVL(VALOR_BMO,0);
                         ELSE
                              VALOR_BMO := 0;
                         END IF;
                     CLOSE VALOR_MONEDA;
                      ELSE
                         VALOR_BMO := 1;       
                  END IF;

                  dbms_output.put_line('titulo:'||r_hst.hst_tlo_codigo||'valor tm='||VALOR_TITULO_TM);                                                                          
                  IF R_HST.HST_SALDO_DISPONIBLE != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_DISPONIBLE   = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_GARANTIA != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_GARANTIA     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_EMBARGO != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_EMBARGO     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;

                  ELSIF R_HST. HST_SALDO_GARANTIA_REPO != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_GARREPO     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_POR_CUMPLIR != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_XCUMPLIR     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
				  ELSIF R_HST.HST_SALDO_CPR_X_CUMPLIR != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_CPR_X_CUMPLIR     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_TRANSITO_ING != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_TRANING     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_TRANSITO_RET != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_TRANRET     = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_GARANTIA_DER != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_GARDER        = VALOR_TITULO_TM * VALOR_BMO
                         ,HST_INDICADOR_VALORACION  = INDICADOR_VALORACION       
                         ,HST_TASA_VALORACION       = TASA_VALORACION
                         ,HST_TASA_DESCUENTO        = TASA_DESCUENTO
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  END IF;
               ELSIF R_TLO.TLO_TYPE = 'ACC' THEN
                  OPEN PRECIO_ESPECIE(R_TLO.TLO_ENA_MNEMONICO);
                  FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                  IF PRECIO_ESPECIE%NOTFOUND THEN
                        VALOR_ESPECIE := 0;
                  ELSE
                        VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                  END IF;
                  CLOSE PRECIO_ESPECIE;
                  IF R_HST.HST_SALDO_DISPONIBLE != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_DISPONIBLE   = HST_SALDO_DISPONIBLE * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_GARANTIA != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_GARANTIA     = HST_SALDO_GARANTIA * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_EMBARGO != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_EMBARGO     = HST_SALDO_EMBARGO * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_GARANTIA_REPO != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_GARREPO     = HST_SALDO_GARANTIA_REPO * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_POR_CUMPLIR != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_XCUMPLIR     = HST_SALDO_POR_CUMPLIR * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
				   ELSIF R_HST.HST_SALDO_CPR_X_CUMPLIR != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_CPR_X_CUMPLIR     = HST_SALDO_CPR_X_CUMPLIR * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_TRANSITO_ING != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_TRANING     = HST_SALDO_TRANSITO_ING * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_TRANSITO_RET != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_TRANRET    = HST_SALDO_TRANSITO_RET * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  ELSIF R_HST.HST_SALDO_GARANTIA_DER != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_GARDER         = HST_SALDO_GARANTIA_DER * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  -- OMORA
                  ELSIF R_HST.HST_SALDO_RETARDO != 0 THEN
                     UPDATE HISTORICOS_SALDOS_TITULOS
                     SET  HST_VALOR_TM_RETARDO         = HST_SALDO_RETARDO * VALOR_ESPECIE
                         ,HST_INDICADOR_VALORACION  = 'PR'
                         ,HST_TASA_VALORACION       = ''
                         ,HST_TASA_DESCUENTO        = ''
                     WHERE HST_CONSECUTIVO = R_HST.HST_CONSECUTIVO;
                  -- OMORA					 
                  END IF;
               END IF;
            END IF;
         END IF;
         CLOSE C_TLO;
      END IF;
      FETCH C_HST INTO R_HST;
   END LOOP;
   CLOSE C_HST;
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      DESC_ERROR := SUBSTR(sqlerrm,1,990);
      INSERT INTO HST_ERROR
             (HRR_FECHA,
              HRR_CONSECUTIVO,
              HRR_DESCRIPCION)
      VALUES (QFECHA,  --SYSDATE,
              P_CONSECUTIVO,
              DESC_ERROR);

END GENERAR_VALORACION_TITULO ;    

/**************************************************************************************************************
*** PROCEDIMIENTO PARA GENERAR LOS FLUJOS DE LA INFORMACION HISTORICA EN HST_SALDOS_TITULOS Y VALORAR.       ***
*** EN LA VALORACION DE LO HISTORICO SE VA GENERANDO FLUJOS Y CORRIENDO VALORACION. LOS FLUJOS NO SE GUARDAN ***
**  SE CORRE UNA UNICA VEZ                                                                                  ***
**************************************************************************************************************/
PROCEDURE  GENERAR_FLUJOS_HCO(V_FECHA DATE, V_CONS NUMBER) IS
   CURSOR C_HST1 IS
      SELECT  HST_CONSECUTIVO                
             ,HST_FECHA                      
             ,HST_CCC_CLI_PER_NUM_IDEN       
             ,HST_CCC_CLI_PER_TID_CODIGO
             ,HST_CCC_NUMERO_CUENTA          
             ,HST_SALDO_DISPONIBLE           
             ,HST_SALDO_GARANTIA             
             ,HST_SALDO_EMBARGO              
             ,HST_VALOR_TM_DISPONIBLE        
             ,HST_VALOR_TM_GARANTIA          
             ,HST_VALOR_TM_EMBARGO           
             ,HST_CFC_FUG_ISI_MNEMONICO      
             ,HST_CFC_FUG_MNEMONICO          
             ,HST_CFC_CUENTA_DECEVAL         
             ,HST_TLO_CODIGO                 
      FROM HISTORICOS_SALDOS_TITULOS
      WHERE HST_FECHA >= TRUNC(V_FECHA)
        AND HST_FECHA <  TRUNC(V_FECHA+1)
        AND HST_CONSECUTIVO = V_CONS;

   R_HST1 C_HST1%ROWTYPE;

   CURSOR C_FUG (ISIN VARCHAR2, FUG NUMBER) IS
      SELECT FUG_ISI_MNEMONICO      
             ,FUG_MNEMONICO          
             ,FUG_TIPO               
             ,FUG_ESTADO             
             ,FUG_BMO_MNEMONICO      
             ,FUG_FECHA_EMISION      
             ,FUG_FECHA_EXPEDICION   
             ,FUG_FECHA_VENCIMIENTO  
             ,FUG_BASE_CALCULO       
             ,FUG_MODALIDAD_TASA     
             ,FUG_TASA_FACIAL *100 FUG_TASA_FACIAL
             ,FUG_TRE_MNEMONICO   
             ,FUG_PUNTOS_ADICIONALES
             ,FUG_PERIODICIDAD_TASA  
             ,FUG_TIPO_TES        
             ,FUG_AMORTIZABLE
             ,FUG_CAPITALIZABLE
             ,FUG_TIPO_PAGO_FLUJO   
             ,FUG_CODIGO_PERIODO
      FROM FUNGIBLES
      WHERE FUG_ISI_MNEMONICO = ISIN
        AND FUG_MNEMONICO = FUG;
   R_FUG C_FUG%ROWTYPE;

   CURSOR C_ISE (ISIN VARCHAR2) IS
      SELECT ISE_ENA_MNEMONICO
      FROM ISINS_ESPECIES
      WHERE ISE_ISI_MNEMONICO = ISIN;
   R_ISE C_ISE%ROWTYPE;

   CURSOR C_TLO (CONS NUMBER) IS
      SELECT  TLO_TYPE                       
             ,TLO_ENA_MNEMONICO              
             ,TLO_FECHA_OPERACION            
             ,TLO_TRE_MNEMONICO              
             ,TLO_BMO_MNEMONICO              
             ,TLO_FECHA_EMISION              
             ,TLO_FECHA_VENCIMIENTO          
             ,TLO_PUNTOS_ADICIONALES         
             ,TLO_VALOR_NOMINAL              
             ,TLO_TASA_FACIAL * 100  TLO_TASA_FACIAL              
             ,TLO_PERIODICIDAD_TASA          
             ,TLO_BASE_CALCULO               
             ,TLO_MODALIDAD_TASA 
             ,TLO_AMORTIZABLE
             ,TLO_CAPITALIZABLE
             ,TLO_TIPO_PAGO_FLUJO
             ,TLO_CODIGO_PERIODO            
      FROM TITULOS
      WHERE TLO_CODIGO = CONS;
   R_TLO C_TLO%ROWTYPE;
   DESC_ERROR VARCHAR2(1000);
BEGIN
   OPEN C_HST1;
   FETCH C_HST1 INTO R_HST1;
   WHILE C_HST1%FOUND LOOP
      IF R_HST1.HST_CFC_FUG_MNEMONICO IS NOT NULL THEN
         OPEN C_FUG(R_HST1.HST_CFC_FUG_ISI_MNEMONICO, R_HST1.HST_CFC_FUG_MNEMONICO);
         FETCH C_FUG INTO R_FUG;
         CLOSE C_FUG;

         IF R_FUG.FUG_TIPO = 'RF' THEN
            OPEN C_ISE(R_HST1.HST_CFC_FUG_ISI_MNEMONICO);
            FETCH C_ISE INTO R_ISE;
            CLOSE C_ISE;

            CORRER_FLUJOS('N'
                       ,R_ISE.ISE_ENA_MNEMONICO
                       ,R_FUG.FUG_FECHA_EMISION
                       ,R_FUG.FUG_FECHA_VENCIMIENTO
                       ,R_FUG.FUG_AMORTIZABLE
                       ,R_FUG.FUG_CAPITALIZABLE
                       ,R_FUG.FUG_TRE_MNEMONICO
                       ,R_FUG.FUG_PUNTOS_ADICIONALES
                       ,R_FUG.FUG_TASA_FACIAL
                       ,R_FUG.FUG_TIPO_PAGO_FLUJO
                       ,R_FUG.FUG_CODIGO_PERIODO
                       ,R_FUG.FUG_PERIODICIDAD_TASA
                       ,R_FUG.FUG_MODALIDAD_TASA
                       ,R_FUG.FUG_BASE_CALCULO
                       ,V_FECHA
                       ,1
                       ,1);
         END IF;
      ELSIF R_HST1.HST_TLO_CODIGO IS NOT NULL THEN
         OPEN C_TLO(R_HST1.HST_TLO_CODIGO);
         FETCH C_TLO INTO R_TLO;
         CLOSE C_TLO;
         IF R_TLO.TLO_TYPE = 'TFC' THEN
            CORRER_FLUJOS('S'
                         ,R_TLO.TLO_ENA_MNEMONICO
                         ,R_TLO.TLO_FECHA_EMISION
                         ,R_TLO.TLO_FECHA_VENCIMIENTO
                         ,R_TLO.TLO_AMORTIZABLE
                         ,R_TLO.TLO_CAPITALIZABLE
                         ,R_TLO.TLO_TRE_MNEMONICO
                         ,R_TLO.TLO_PUNTOS_ADICIONALES
                         ,R_TLO.TLO_TASA_FACIAL
                         ,R_TLO.TLO_TIPO_PAGO_FLUJO
                         ,R_TLO.TLO_CODIGO_PERIODO
                         ,R_TLO.TLO_PERIODICIDAD_TASA
                         ,R_TLO.TLO_MODALIDAD_TASA
                         ,R_TLO.TLO_BASE_CALCULO
                         ,v_fecha                        -- genera los flujos de la fecha valoracion en adelante
                         ,R_TLO.TLO_VALOR_NOMINAL
                         ,R_TLO.TLO_VALOR_NOMINAL);

         END IF;
      END IF;
      FETCH C_HST1 INTO R_HST1;
   END LOOP;
   CLOSE C_HST1;

EXCEPTION
   WHEN OTHERS THEN
      DESC_ERROR := SUBSTR(sqlerrm,1,900);
      INSERT INTO HST_ERROR
             (HRR_FECHA,
              HRR_CONSECUTIVO,
              HRR_DESCRIPCION)
      VALUES (V_FECHA,
              V_CONS,
              DESC_ERROR);
END GENERAR_FLUJOS_HCO;



PROCEDURE OPERACIONES_CONTADO IS
   -- ESTE PROCEDIMIENTO SE LLAMA DESDE EL PROCEDIMIENTO P_CLIENTES_TITULOS.COMPROMISOS
   -- SE TOMA LA FOTO DE LAS OPERACIONES PENDIENTES DE CUMPLIR A LA FECHA. TIENE HORA LIMITE PARA CORRER. 
   -- SI CORRE DESPUES DE LA HORA LIMITE SE DEBE RECONSTRUIR HISTORICO
   -- SI ES FIN DE MES SE GUARDA LA INFORMACION. SE BORRAN LOS DATOS PARA FECHA DIFERENTE A FIN DE MES

   HORA_LIMITE VARCHAR2(8):= '20:00:00';     --HORA LIMITE PARA CORRER OPERACIONES_CONTADO (dia de 24 horas)
   P_FECHA_HOY DATE;
   FECHA_A_PROCESAR DATE;

   CURSOR C_EXISTE (QFECHA DATE) IS
      SELECT 'S'
      FROM LIQUIDACIONES_POR_CUMPLIR
      WHERE LPC_FECHA_CORTE >= TRUNC(QFECHA)
        AND LPC_FECHA_CORTE <  TRUNC(QFECHA+1);
   SINO VARCHAR2(1);        

   NO_PROCESO EXCEPTION;
   YA_EXISTE  EXCEPTION;
   P_NUM_INI NUMBER;
   P_NUM_FIN NUMBER; 
BEGIN
P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.OPERACIONES_CONTADO','INI');
   SELECT SYSDATE INTO P_FECHA_HOY FROM DUAL;
   IF P_FECHA_HOY < TO_DATE(TO_CHAR(P_FECHA_HOY,'DD-MON-YYYY')||' '||HORA_LIMITE,'DD-MON-YYYY HH24:MI:SS') THEN
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
         -- PROCEDIMIENTO PARA GUARDAR LAS OPERACIONES PENDIENTES DE CUMPLIR EN LA FECHA_A_PROCESAR
         P_CLIENTES_TITULOS.OPERACIONES_POR_CUMPLIR_HOY(FECHA_A_PROCESAR);

         -- PROCEDIMIENTO PARA VALORAR LAS OPERACIONES PENDIENTES DE CUMPLIR
         P_CLIENTES_TITULOS.VALORAR_OPERACIONES_CONTADO(FECHA_A_PROCESAR);

         --BORRAR LA INFORMACION < A LA FECHA SI ES DIFERENTE A FIN DE MES
         --P_CLIENTES_TITULOS.BORRAR_DIF_FIN_MES_OP_CONTADO(FECHA_A_PROCESAR);
      ELSE
         RAISE YA_EXISTE;
      END IF;
   ELSE
      RAISE NO_PROCESO;
   END IF;
  P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.OPERACIONES_CONTADO','FIN');

  COMMIT;

EXCEPTION
     WHEN NO_PROCESO THEN
        P_MAIL.envio_mail_error('Proceso OPERACIONES_CONTADO','Se supero la hora limite para correr el proceso OPERACIONES_POR_CUMPLIR');
        RAISE_APPLICATION_ERROR(-20001,'Se supero la hora limite para correr el proceso OPERACIONES_POR_CUMPLIR');
     WHEN YA_EXISTE THEN
        P_MAIL.envio_mail_error('Proceso OPERACIONES_CONTADO','Ya se corrio proceso OPERACIONES_CONTADO para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
        RAISE_APPLICATION_ERROR(-20002,'Ya se corrio proceso OPERACIONES_CONTADO para la fecha '||TO_CHAR(FECHA_A_PROCESAR,'DD-MON-YYYY'));
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso OPERACIONES_CONTADO','Error en procedimiento OPERACIONES_CONTADO: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20003,'Error en procedimiento OPERACIONES_CONTADO: '||sqlerrm);

END OPERACIONES_CONTADO;


PROCEDURE OPERACIONES_POR_CUMPLIR_HOY (P_FECHA IN DATE) IS

   CURSOR C_CONS IS
      SELECT NVL(MAX(LPC_CONSECUTIVO),0) CONS
      FROM LIQUIDACIONES_POR_CUMPLIR;
   CONSECUTIVO NUMBER;

   CURSOR C_LIC IS
      SELECT LIC_NUMERO_OPERACION            
            ,LIC_NUMERO_FRACCION             
            ,LIC_TIPO_OPERACION              
            ,LIC_BOL_MNEMONICO               
            ,LIC_ELI_MNEMONICO               
            ,LIC_NMRO_IMPRSNES_LQUDCION      
            ,LIC_OVE_CONSECUTIVO                    
            ,LIC_OVE_COC_CTO_MNEMONICO              
            ,LIC_OCO_CONSECUTIVO                    
            ,LIC_OCO_COC_CTO_MNEMONICO              
            ,LIC_MERCADO                            
            ,LIC_NIT_1                              
            ,LIC_OBSERVACIONES                      
            ,LIC_PLZO_CMPLMNTO_ESPCIAL              
            ,LIC_FECHA_CUMPLIMIENTO                 
            ,LIC_ESTADO                             
            ,LIC_REINVERSION                        
            ,LIC_RETENCION_FUENTE                   
            ,LIC_REFERENCIA_COMISIONISTA            
            ,LIC_RFRNCIA_SWAP_CMSNSTA               
            ,LIC_SERVICIO_BOLSA                     
            ,LIC_SERVICIO_BOLSA_VOLUMEN             
            ,LIC_NUMERO_FRACCIONES                  
            ,LIC_SERVICIO_BOLSA_OPERACION           
            ,LIC_FECHA_VENCIMIENTO                  
            ,LIC_PLAZO_LIQUIDACION                  
            ,LIC_FCHA_CMPLMNTO_ESPCIAL              
            ,LIC_MDLDAD_OPRCION_PLZO_ACCNES         
            ,LIC_FIJA_PRECIO_ACCIONES               
            ,LIC_MNEMOTECNICO_TITULO                
            ,LIC_MODALIDAD                          
            ,LIC_MODALIDAD_LIQUIDACION              
            ,LIC_INDICADOR_ORIGEN                   
            ,LIC_SUCURSAL_CUMPLIMIENTO              
            ,LIC_TIPO_OFERTA                        
            ,LIC_PLAZA_EXPEDICION                   
            ,LIC_PLAZA_UBICACION                    
            ,LIC_IDENTIFICACION_REMATE              
            ,LIC_PLAZO_EMISION                      
            ,LIC_TASA_REFERENCIA                    
            ,LIC_PUNTOS_AJUSTE                      
            ,LIC_TASA_EMISION                       
            ,LIC_BASE_CALCULO_INTERES               
            ,LIC_PERIODICIDAD                       
            ,LIC_COD_CMSNSTA_CMPRDOR                
            ,LIC_COD_CMSNSTA_VNDDOR                 
            ,LIC_CODIGO_OPERADOR_COMPRADOR          
            ,LIC_CODIGO_OPERADOR_VENDEDOR           
            ,LIC_CANTIDAD_TOTAL_OPERACION           
            ,LIC_PLAZO_VENCIMIENTO                  
            ,LIC_PORCENTAJE_PRECIO                  
            ,LIC_PRCNTJE_TSA_ADJDCCION              
            ,LIC_VOLUMEN_TOTAL                      
            ,LIC_PRECIO                             
            ,LIC_FECHA_EMISION                      
            ,LIC_NUMERO_FACTURA                     
            ,LIC_TRASLADO_RTE_FTE                   
            ,LIC_FECHA_OPERACION                    
            ,LIC_CLASE_TRANSACCION                  
            ,LIC_IDNTFCCION_PTRMNIO_AUT_1           
            ,LIC_TIPO_IDENTIFICACION_1              
            ,LIC_TIPO_IDENTIFICACION_2              
            ,LIC_NIT_2                              
            ,LIC_IDNTFCCION_PTRMNIO_AUT_2           
            ,LIC_TIPO_IDENTIFICACION_3              
            ,LIC_NIT_3                              
            ,LIC_IDNTFCCION_PTRMNIO_AUT_3           
            ,LIC_INDICADOR_CARRUSEL                 
            ,LIC_INDCDOR_TTLO_DCVAL_CMPRDOR         
            ,LIC_INDICADOR_OPERACION                
            ,LIC_PORCENTAJE_COMISION                
            ,LIC_VALOR_COMISION                     
            ,LIC_PRCNTJE_PRCIO_NTO_FRCCION          
            ,LIC_PRCNTJE_TSA_NTA_FRCCION            
            ,LIC_VOLUMEN_NETO_FRACCION              
            ,LIC_CODIGO_CONTACTO_COMERCIAL          
            ,LIC_INDICADOR_SWAP                     
            ,LIC_PORCENTAJE_TASA_REPO               
            ,LIC_PLAZO_REPO                         
            ,LIC_VALOR_CAPTACION_REPO               
            ,LIC_VOLUMEN_RECOMPRA_REPO              
            ,LIC_INDICADOR_PLAZA                    
            ,LIC_IDENTIFICADOR_PLAZA                
            ,LIC_CANTIDAD_FRACCION                  
            ,LIC_VOLUMEN_FRACCION                   
            ,LIC_FECHA_PACTO_CUMPLIMIENTO           
            ,LIC_COMPENSACION_ESPECIAL              
            ,LIC_HORA_GRABACION_NEGOCIO             
            ,LIC_ORIGEN_OPERACION                   
            ,LIC_PERIODO_EXDIVIDENDO                
            ,LIC_BASE_RETENCION_COBRO               
            ,LIC_PORCENTAJE_RET_COBRO               
            ,LIC_BASE_RETENCION_TRASLADO            
            ,LIC_PORCENTAJE_RET_TRASLADO            
            ,LIC_PORCENTAJE_IVA_COMISION            
            ,LIC_VALOR_IVA_COMISION                 
            ,LIC_TRASLADA_SERV_A_CLIENTE            
            ,LIC_OP_CON_RETEFTE_ENAJENA             
            ,LIC_FECHA_CONSTA_VENTA                 
            ,LIC_VALOR_CONSTA_VENTA                 
            ,LIC_GENERA_CONSTA_COMPRADOR            
            ,LIC_SERVICIO_BOLSA_FIJO                
            ,LIC_SERVICIO_BOLSA_VARIABLE            
            ,LIC_FECHA_VALORACION                   
            ,LIC_VALORACION_TM                      
            ,LIC_CONTRAPAGO_OPERACION               
            ,LIC_ENVIA_RETEFUENTE                   
            ,LIC_PROMOTOR_LIQUIDEZ                  
            ,LIC_TIPO_USO_TASA                      
            ,LIC_NEMO_LARGO                         
            ,LIC_CUMPLIMIENTO_PLENO                 
            ,LIC_INCONSISTENCIAS                    
            ,LIC_DESCUENTO                          
         FROM LIQUIDACIONES_COMERCIAL
         WHERE LIC_ELI_MNEMONICO IN ('APL','OPA','OPL')
           AND LIC_TIPO_OFERTA NOT IN ('R','A','1','2','3','4','5','6')
           AND LIC_FECHA_OPERACION < TRUNC(P_FECHA+1)
           AND ((LIC_FECHA_PACTO_CUMPLIMIENTO IS NULL
              AND LIC_FECHA_CUMPLIMIENTO >= TRUNC(P_FECHA+1))
              OR (LIC_FECHA_PACTO_CUMPLIMIENTO IS NOT NULL
                  AND LIC_FECHA_PACTO_CUMPLIMIENTO >= TRUNC(P_FECHA+1)));
   R_LIC C_LIC%ROWTYPE;

   CURSOR C_OVE (P_BOL  VARCHAR2,
                 P_CTO  VARCHAR2,
                 P_CONS NUMBER) IS
      SELECT  OVE_CCC_CLI_PER_TID_CODIGO     
             ,OVE_CCC_CLI_PER_NUM_IDEN       
             ,OVE_CCC_NUMERO_CUENTA                           
      FROM ORDENES_VENTA
      WHERE OVE_BOL_MNEMONICO = P_BOL
        AND OVE_COC_CTO_MNEMONICO = P_CTO
        AND OVE_CONSECUTIVO = P_CONS;
   R_OVE C_OVE%ROWTYPE;

   CURSOR C_OCO (P_BOL  VARCHAR2,
                 P_CTO  VARCHAR2,
                 P_CONS NUMBER) IS
      SELECT  OCO_CCC_CLI_PER_TID_CODIGO     
             ,OCO_CCC_CLI_PER_NUM_IDEN       
             ,OCO_CCC_NUMERO_CUENTA                           
      FROM ORDENES_COMPRA
      WHERE OCO_BOL_MNEMONICO = P_BOL
        AND OCO_COC_CTO_MNEMONICO = P_CTO
        AND OCO_CONSECUTIVO = P_CONS;
   R_OCO C_OCO%ROWTYPE;
   CCC_NID VARCHAR2(15);
   CCC_TID VARCHAR2(3);
   CCC_CTA NUMBER;        

   DIAS NUMBER;
   TIPO VARCHAR2(3);
BEGIN
   OPEN C_CONS;
   FETCH C_CONS INTO CONSECUTIVO;
   CLOSE C_CONS;
   CONSECUTIVO := NVL(CONSECUTIVO,0);

   OPEN C_LIC;
   FETCH C_LIC INTO R_LIC;
   WHILE C_LIC%FOUND LOOP
         DIAS := P_CLIENTES_TITULOS.DIA_HABIL(R_LIC.LIC_FECHA_OPERACION
                                         , R_LIC.LIC_FECHA_CUMPLIMIENTO);

      IF (DIAS >= 6 AND R_LIC.LIC_CLASE_TRANSACCION = 'RF') OR
         (DIAS >= 7 AND R_LIC.LIC_CLASE_TRANSACCION = 'ACC') THEN
        TIPO := 'PLZ';
      ELSE
        TIPO := 'CON';
      END IF;      

      CCC_NID := NULL;
      CCC_TID := NULL;
      CCC_CTA := NULL;

         CONSECUTIVO := CONSECUTIVO + 1;
         IF R_LIC.LIC_TIPO_OPERACION = 'V' THEN
            OPEN C_OVE( R_LIC.LIC_BOL_MNEMONICO
                    ,R_LIC.LIC_OVE_COC_CTO_MNEMONICO
                    ,R_LIC.LIC_OVE_CONSECUTIVO);
            FETCH C_OVE INTO R_OVE;
            IF C_OVE%FOUND THEN
               CCC_NID := R_OVE.OVE_CCC_CLI_PER_NUM_IDEN;
               CCC_TID := R_OVE.OVE_CCC_CLI_PER_TID_CODIGO;
               CCC_CTA := R_OVE.OVE_CCC_NUMERO_CUENTA;
            END IF;   
            CLOSE C_OVE;
         ELSIF R_LIC.LIC_TIPO_OPERACION = 'C' THEN
            OPEN C_OCO( R_LIC.LIC_BOL_MNEMONICO
                    ,R_LIC.LIC_OCO_COC_CTO_MNEMONICO
                    ,R_LIC.LIC_OCO_CONSECUTIVO);
            FETCH C_OCO INTO R_OCO;
            IF C_OCO%FOUND THEN
               CCC_NID := R_OCO.OCO_CCC_CLI_PER_NUM_IDEN;
               CCC_TID := R_OCO.OCO_CCC_CLI_PER_TID_CODIGO;
               CCC_CTA := R_OCO.OCO_CCC_NUMERO_CUENTA;
            END IF;   
            CLOSE C_OCO;
         END IF;
         IF TIPO = 'CON' THEN
            INSERT INTO LIQUIDACIONES_POR_CUMPLIR
                   ( LPC_CONSECUTIVO                 
                 ,LPC_FECHA_CORTE                 
                 ,LPC_CCC_CLI_PER_NUM_IDEN        
                 ,LPC_CCC_CLI_PER_TID_CODIGO      
                 ,LPC_CCC_NUMERO_CUENTA           
                 ,LPC_LIC_BOL_MNEMONICO           
                 ,LPC_LIC_NUMERO_OPERACION        
                 ,LPC_LIC_NUMERO_FRACCION         
                 ,LPC_LIC_TIPO_OPERACION          
                 ,LPC_NMRO_IMPRSNES_LQUDCION             
                 ,LPC_ESTADO                             
                 ,LPC_FECHA_OPERACION                    
                 ,LPC_ORIGEN_OPERACION                   
                 ,LPC_CLASE_TRANSACCION                  
                 ,LPC_MNEMOTECNICO_TITULO                
                 ,LPC_COD_CMSNSTA_CMPRDOR                
                 ,LPC_COD_CMSNSTA_VNDDOR                 
                 ,LPC_CODIGO_OPERADOR_COMPRADOR          
                 ,LPC_CODIGO_OPERADOR_VENDEDOR           
                 ,LPC_CANTIDAD_TOTAL_OPERACION           
                 ,LPC_PLAZO_VENCIMIENTO                  
                 ,LPC_PORCENTAJE_PRECIO                  
                 ,LPC_PRCNTJE_TSA_ADJDCCION              
                 ,LPC_VOLUMEN_TOTAL                      
                 ,LPC_PRECIO                             
                 ,LPC_FECHA_EMISION                      
                 ,LPC_FECHA_VENCIMIENTO                  
                 ,LPC_PLAZO_EMISION                      
                 ,LPC_TASA_REFERENCIA                    
                 ,LPC_PUNTOS_AJUSTE                      
                 ,LPC_TASA_EMISION                       
                 ,LPC_BASE_CALCULO_INTERES               
                 ,LPC_PERIODICIDAD                       
                 ,LPC_MODALIDAD                          
                 ,LPC_REINVERSION                        
                 ,LPC_IDENTIFICACION_REMATE              
                 ,LPC_PLAZO_LIQUIDACION                  
                 ,LPC_FECHA_CUMPLIMIENTO                 
                 ,LPC_MDLDAD_OPRCION_PLZO_ACCNES         
                 ,LPC_FIJA_PRECIO_ACCIONES               
                 ,LPC_PERIODO_EXDIVIDENDO                
                 ,LPC_INDICADOR_ORIGEN                   
                 ,LPC_TIPO_OFERTA                        
                 ,LPC_MERCADO                            
                 ,LPC_INDICADOR_SWAP                     
                 ,LPC_RFRNCIA_SWAP_CMSNSTA               
                 ,LPC_PORCENTAJE_TASA_REPO               
                 ,LPC_PLAZO_REPO                         
                 ,LPC_VALOR_CAPTACION_REPO               
                 ,LPC_VOLUMEN_RECOMPRA_REPO              
                 ,LPC_SUCURSAL_CUMPLIMIENTO              
                 ,LPC_CANTIDAD_FRACCION                  
                 ,LPC_VOLUMEN_FRACCION                   
                 ,LPC_PORCENTAJE_COMISION                
                 ,LPC_VALOR_COMISION                     
                 ,LPC_PRCNTJE_PRCIO_NTO_FRCCION          
                 ,LPC_PRCNTJE_TSA_NTA_FRCCION            
                 ,LPC_VOLUMEN_NETO_FRACCION              
                 ,LPC_SERVICIO_BOLSA                     
                 ,LPC_SERVICIO_BOLSA_VOLUMEN             
                 ,LPC_SERVICIO_BOLSA_OPERACION           
                 ,LPC_SERVICIO_BOLSA_FIJO                
                 ,LPC_SERVICIO_BOLSA_VARIABLE            
                 ,LPC_CODIGO_CONTACTO_COMERCIAL          
                 ,LPC_NUMERO_FRACCIONES                  
                 ,LPC_REFERENCIA_COMISIONISTA            
                 ,LPC_TIPO_IDENTIFICACION_1              
                 ,LPC_NIT_1                              
                 ,LPC_IDNTFCCION_PTRMNIO_AUT_1           
                 ,LPC_TIPO_IDENTIFICACION_2              
                 ,LPC_NIT_2                              
                 ,LPC_IDNTFCCION_PTRMNIO_AUT_2           
                 ,LPC_TIPO_IDENTIFICACION_3              
                 ,LPC_NIT_3                              
                 ,LPC_IDNTFCCION_PTRMNIO_AUT_3           
                 ,LPC_INDICADOR_CARRUSEL                 
                 ,LPC_INDICADOR_OPERACION                
                 ,LPC_BASE_RETENCION_COBRO               
                 ,LPC_PORCENTAJE_RET_COBRO               
                 ,LPC_RETENCION_FUENTE                   
                 ,LPC_BASE_RETENCION_TRASLADO            
                 ,LPC_PORCENTAJE_RET_TRASLADO            
                 ,LPC_TRASLADO_RTE_FTE                   
                 ,LPC_PORCENTAJE_IVA_COMISION            
                 ,LPC_VALOR_IVA_COMISION                 
                 ,LPC_TRASLADA_SERV_A_CLIENTE            
                 ,LPC_OP_CON_RETEFTE_ENAJENA             
                 ,LPC_FECHA_CONSTA_VENTA                 
                 ,LPC_VALOR_CONSTA_VENTA                 
                 ,LPC_GENERA_CONSTA_COMPRADOR            
                 ,LPC_CONTRAPAGO_OPERACION               
                 ,LPC_ENVIA_RETEFUENTE                   
                 ,LPC_PROMOTOR_LIQUIDEZ                  
                 ,LPC_TIPO_USO_TASA                      
                 ,LPC_NEMO_LARGO                         
                 ,LPC_OBSERVACIONES                      
                 ,LPC_PLZO_CMPLMNTO_ESPCIAL              
                 ,LPC_FCHA_CMPLMNTO_ESPCIAL              
                 ,LPC_MODALIDAD_LIQUIDACION              
                 ,LPC_PLAZA_EXPEDICION                   
                 ,LPC_PLAZA_UBICACION                    
                 ,LPC_NUMERO_FACTURA                     
                 ,LPC_INDCDOR_TTLO_DCVAL_CMPRDOR         
                 ,LPC_INDICADOR_PLAZA                    
                 ,LPC_IDENTIFICADOR_PLAZA                
                 ,LPC_FECHA_PACTO_CUMPLIMIENTO           
                 ,LPC_COMPENSACION_ESPECIAL              
                 ,LPC_HORA_GRABACION_NEGOCIO             
                 ,LPC_FECHA_VALORACION                   
                 ,LPC_VALORACION_TM                      
                 ,LPC_CUMPLIMIENTO_PLENO                 
                 ,LPC_INCONSISTENCIAS                    
                 ,LPC_DESCUENTO)
         VALUES ( CONSECUTIVO
                 ,TRUNC(P_FECHA)
                 ,CCC_NID
                 ,CCC_TID
                 ,CCC_CTA           
                 ,R_LIC.LIC_BOL_MNEMONICO           
                 ,R_LIC.LIC_NUMERO_OPERACION        
                 ,R_LIC.LIC_NUMERO_FRACCION         
                 ,R_LIC.LIC_TIPO_OPERACION          
                 ,R_LIC.LIC_NMRO_IMPRSNES_LQUDCION             
                 ,R_LIC.LIC_ESTADO                             
                 ,R_LIC.LIC_FECHA_OPERACION                    
                 ,R_LIC.LIC_ORIGEN_OPERACION                   
                 ,R_LIC.LIC_CLASE_TRANSACCION                  
                 ,R_LIC.LIC_MNEMOTECNICO_TITULO                
                 ,R_LIC.LIC_COD_CMSNSTA_CMPRDOR                
                 ,R_LIC.LIC_COD_CMSNSTA_VNDDOR                 
                 ,R_LIC.LIC_CODIGO_OPERADOR_COMPRADOR          
                 ,R_LIC.LIC_CODIGO_OPERADOR_VENDEDOR           
                 ,R_LIC.LIC_CANTIDAD_TOTAL_OPERACION           
                 ,R_LIC.LIC_PLAZO_VENCIMIENTO                  
                 ,R_LIC.LIC_PORCENTAJE_PRECIO                  
                 ,R_LIC.LIC_PRCNTJE_TSA_ADJDCCION              
                 ,R_LIC.LIC_VOLUMEN_TOTAL                      
                 ,R_LIC.LIC_PRECIO                             
                 ,R_LIC.LIC_FECHA_EMISION                      
                 ,R_LIC.LIC_FECHA_VENCIMIENTO                  
                 ,R_LIC.LIC_PLAZO_EMISION                      
                 ,R_LIC.LIC_TASA_REFERENCIA                    
                 ,R_LIC.LIC_PUNTOS_AJUSTE                      
                 ,R_LIC.LIC_TASA_EMISION                       
                 ,R_LIC.LIC_BASE_CALCULO_INTERES               
                 ,R_LIC.LIC_PERIODICIDAD                       
                 ,R_LIC.LIC_MODALIDAD                          
                 ,R_LIC.LIC_REINVERSION                        
                 ,R_LIC.LIC_IDENTIFICACION_REMATE              
                 ,R_LIC.LIC_PLAZO_LIQUIDACION                  
                 ,R_LIC.LIC_FECHA_CUMPLIMIENTO                 
                 ,R_LIC.LIC_MDLDAD_OPRCION_PLZO_ACCNES         
                 ,R_LIC.LIC_FIJA_PRECIO_ACCIONES               
                 ,R_LIC.LIC_PERIODO_EXDIVIDENDO                
                 ,R_LIC.LIC_INDICADOR_ORIGEN                   
                 ,R_LIC.LIC_TIPO_OFERTA                        
                 ,R_LIC.LIC_MERCADO                            
                 ,R_LIC.LIC_INDICADOR_SWAP                     
                 ,R_LIC.LIC_RFRNCIA_SWAP_CMSNSTA               
                 ,R_LIC.LIC_PORCENTAJE_TASA_REPO               
                 ,R_LIC.LIC_PLAZO_REPO                         
                 ,R_LIC.LIC_VALOR_CAPTACION_REPO               
                 ,R_LIC.LIC_VOLUMEN_RECOMPRA_REPO              
                 ,R_LIC.LIC_SUCURSAL_CUMPLIMIENTO              
                 ,R_LIC.LIC_CANTIDAD_FRACCION                  
                 ,R_LIC.LIC_VOLUMEN_FRACCION                   
                 ,R_LIC.LIC_PORCENTAJE_COMISION                
                 ,R_LIC.LIC_VALOR_COMISION                     
                 ,R_LIC.LIC_PRCNTJE_PRCIO_NTO_FRCCION          
                 ,R_LIC.LIC_PRCNTJE_TSA_NTA_FRCCION            
                 ,R_LIC.LIC_VOLUMEN_NETO_FRACCION              
                 ,R_LIC.LIC_SERVICIO_BOLSA                     
                 ,R_LIC.LIC_SERVICIO_BOLSA_VOLUMEN             
                 ,R_LIC.LIC_SERVICIO_BOLSA_OPERACION           
                 ,R_LIC.LIC_SERVICIO_BOLSA_FIJO                
                 ,R_LIC.LIC_SERVICIO_BOLSA_VARIABLE            
                 ,R_LIC.LIC_CODIGO_CONTACTO_COMERCIAL          
                 ,R_LIC.LIC_NUMERO_FRACCIONES                  
                 ,R_LIC.LIC_REFERENCIA_COMISIONISTA            
                 ,R_LIC.LIC_TIPO_IDENTIFICACION_1              
                 ,R_LIC.LIC_NIT_1                              
                 ,R_LIC.LIC_IDNTFCCION_PTRMNIO_AUT_1           
                 ,R_LIC.LIC_TIPO_IDENTIFICACION_2              
                 ,R_LIC.LIC_NIT_2                              
                 ,R_LIC.LIC_IDNTFCCION_PTRMNIO_AUT_2           
                 ,R_LIC.LIC_TIPO_IDENTIFICACION_3              
                 ,R_LIC.LIC_NIT_3                              
                 ,R_LIC.LIC_IDNTFCCION_PTRMNIO_AUT_3           
                 ,R_LIC.LIC_INDICADOR_CARRUSEL                 
                 ,R_LIC.LIC_INDICADOR_OPERACION                
                 ,R_LIC.LIC_BASE_RETENCION_COBRO               
                 ,R_LIC.LIC_PORCENTAJE_RET_COBRO               
                 ,R_LIC.LIC_RETENCION_FUENTE                   
                 ,R_LIC.LIC_BASE_RETENCION_TRASLADO            
                 ,R_LIC.LIC_PORCENTAJE_RET_TRASLADO            
                 ,R_LIC.LIC_TRASLADO_RTE_FTE                   
                 ,R_LIC.LIC_PORCENTAJE_IVA_COMISION            
                 ,R_LIC.LIC_VALOR_IVA_COMISION                 
                 ,R_LIC.LIC_TRASLADA_SERV_A_CLIENTE            
                 ,R_LIC.LIC_OP_CON_RETEFTE_ENAJENA             
                 ,R_LIC.LIC_FECHA_CONSTA_VENTA                 
                 ,R_LIC.LIC_VALOR_CONSTA_VENTA                 
                 ,R_LIC.LIC_GENERA_CONSTA_COMPRADOR            
                 ,R_LIC.LIC_CONTRAPAGO_OPERACION               
                 ,R_LIC.LIC_ENVIA_RETEFUENTE                   
                 ,R_LIC.LIC_PROMOTOR_LIQUIDEZ                  
                 ,R_LIC.LIC_TIPO_USO_TASA                      
                 ,R_LIC.LIC_NEMO_LARGO                         
                 ,R_LIC.LIC_OBSERVACIONES                      
                 ,R_LIC.LIC_PLZO_CMPLMNTO_ESPCIAL              
                 ,R_LIC.LIC_FCHA_CMPLMNTO_ESPCIAL              
                 ,R_LIC.LIC_MODALIDAD_LIQUIDACION              
                 ,R_LIC.LIC_PLAZA_EXPEDICION                   
                 ,R_LIC.LIC_PLAZA_UBICACION                    
                 ,R_LIC.LIC_NUMERO_FACTURA                     
                 ,R_LIC.LIC_INDCDOR_TTLO_DCVAL_CMPRDOR         
                 ,R_LIC.LIC_INDICADOR_PLAZA                    
                 ,R_LIC.LIC_IDENTIFICADOR_PLAZA                
                 ,R_LIC.LIC_FECHA_PACTO_CUMPLIMIENTO           
                 ,R_LIC.LIC_COMPENSACION_ESPECIAL              
                 ,R_LIC.LIC_HORA_GRABACION_NEGOCIO             
                 ,R_LIC.LIC_FECHA_VALORACION                   
                 ,R_LIC.LIC_VALORACION_TM                      
                 ,R_LIC.LIC_CUMPLIMIENTO_PLENO                 
                 ,R_LIC.LIC_INCONSISTENCIAS                    
                 ,R_LIC.LIC_DESCUENTO);                 
      END IF;
      FETCH C_LIC INTO R_LIC;
   END LOOP;
   CLOSE C_LIC;
   COMMIT;
END OPERACIONES_POR_CUMPLIR_HOY;

PROCEDURE BORRAR_DIF_FIN_MES_OP_CONTADO
   (P_FECHA IN  DATE) IS
    ULT_FIN_MES DATE;     -- FECHA DEL ULTIMO FIN DE MES INGRESADO

   CURSOR C_FECHA IS
      SELECT DISTINCT LPC_FECHA_CORTE
      FROM LIQUIDACIONES_POR_CUMPLIR
      WHERE LPC_FECHA_CORTE >= TRUNC(ULT_FIN_MES + 1)
        AND LPC_FECHA_CORTE < TRUNC(P_FECHA);
   R_FECHA C_FECHA%ROWTYPE;            

BEGIN
   SELECT LAST_DAY(ADD_MONTHS(P_FECHA,-1)) INTO ULT_FIN_MES FROM DUAL;
   DBMS_OUTPUT.PUT_LINE(ULT_FIN_MES);
   DBMS_OUTPUT.PUT_LINE(P_FECHA);
   OPEN C_FECHA;
   FETCH C_FECHA INTO R_FECHA;
   WHILE C_FECHA%FOUND LOOP
      DELETE FROM LIQUIDACIONES_POR_CUMPLIR
      WHERE LPC_FECHA_CORTE >= TRUNC(R_FECHA.LPC_FECHA_CORTE)
        AND LPC_FECHA_CORTE <  TRUNC(R_FECHA.LPC_FECHA_CORTE+1);

         DBMS_OUTPUT.PUT_LINE('SE BORRARON REGISTROS DEL DIA '||TO_CHAR(R_FECHA.LPC_FECHA_CORTE,'DD-MON-YYYY'));
         COMMIT;
      FETCH C_FECHA INTO R_FECHA;
   END LOOP;
   CLOSE C_FECHA;
   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso BORRAR_DIF_FIN_MES_OP_CONTADO','Error en procedimiento BORRAR_DIF_FIN_MES_OP_CONTADO: '||substr(sqlerrm,1,80));   
      RAISE_APPLICATION_ERROR(-20010,'Error en procedimiento BORRAR_DIF_FIN_MES_OP_CONTADO: '||sqlerrm);          
END BORRAR_DIF_FIN_MES_OP_CONTADO;

-- PROCEDIMIENTO PARA VALORACION DE OPERACIONES DE CONTADO (DE LIQUIDACIONES_POR_CUMPLIR)
PROCEDURE VALORAR_OPERACIONES_CONTADO (QFECHA DATE) IS

   CURSOR C_LPC IS
      SELECT LPC_CONSECUTIVO,
             LPC_LIC_NUMERO_OPERACION,
             LPC_LIC_NUMERO_FRACCION,
             LPC_LIC_TIPO_OPERACION,
             LPC_LIC_BOL_MNEMONICO,
             LPC_MNEMOTECNICO_TITULO,
             LPC_FECHA_CUMPLIMIENTO,
             LPC_FECHA_EMISION,
             LPC_FECHA_VENCIMIENTO,
             LPC_FCHA_CMPLMNTO_ESPCIAL,
             LPC_VOLUMEN_FRACCION,
             LPC_CANTIDAD_FRACCION,
             LPC_PUNTOS_AJUSTE,
             LPC_TASA_EMISION,
             LPC_PERIODICIDAD,
             LPC_BASE_CALCULO_INTERES,
             LPC_MODALIDAD,
             LPC_TASA_REFERENCIA
      FROM LIQUIDACIONES_POR_CUMPLIR
      WHERE LPC_FECHA_CORTE >= TRUNC(QFECHA)
        AND LPC_FECHA_CORTE <  TRUNC(QFECHA+1);

   R_LPC C_LPC%ROWTYPE;        

BEGIN
   OPEN C_LPC;
   FETCH C_LPC INTO R_LPC;
   WHILE C_LPC%FOUND LOOP
         P_CLIENTES_TITULOS.GENERAR_VALORACION_LPC(QFECHA,R_LPC.LPC_CONSECUTIVO);
      FETCH C_LPC INTO R_LPC;
   END LOOP;
   CLOSE C_LPC;
   COMMIT;  
EXCEPTION
   WHEN OTHERS THEN
      P_MAIL.envio_mail_error('Proceso VALORAR_OPERACIONES_CONTADO','Error en procedimiento VALORAR_OPERACIONES_CONTADO: '||substr(sqlerrm,1,80));
      RAISE_APPLICATION_ERROR(-20011,'Error en procedimiento OPERACIONES_CONTADO: '||sqlerrm);
END VALORAR_OPERACIONES_CONTADO;    

PROCEDURE GENERAR_VALORACION_LPC (QFECHA DATE, P_CONSECUTIVO NUMBER) IS

   CURSOR C_LPC IS
      SELECT LPC_CONSECUTIVO,
             LPC_FECHA_CORTE,
             LPC_CCC_CLI_PER_NUM_IDEN,
             LPC_CCC_CLI_PER_TID_CODIGO,
             LPC_CCC_NUMERO_CUENTA,
             LPC_LIC_NUMERO_OPERACION,
             LPC_LIC_NUMERO_FRACCION,
             LPC_LIC_TIPO_OPERACION,
             LPC_LIC_BOL_MNEMONICO,
             LPC_MNEMOTECNICO_TITULO,
             LPC_FECHA_CUMPLIMIENTO,
             LPC_FECHA_EMISION,
             LPC_FECHA_VENCIMIENTO,
             LPC_FECHA_OPERACION,
             LPC_FCHA_CMPLMNTO_ESPCIAL,
             LPC_VOLUMEN_FRACCION,
             LPC_CANTIDAD_FRACCION,
             LPC_PUNTOS_AJUSTE,
             LPC_TASA_EMISION,
             LPC_PERIODICIDAD,
             LPC_BASE_CALCULO_INTERES,
             LPC_MODALIDAD,
             LPC_TASA_REFERENCIA,
             LPC_CLASE_TRANSACCION
      FROM LIQUIDACIONES_POR_CUMPLIR
      WHERE LPC_FECHA_CORTE >= TRUNC(QFECHA)
        AND LPC_FECHA_CORTE <  TRUNC(QFECHA+1)
        AND LPC_CONSECUTIVO = P_CONSECUTIVO;

   R_LPC C_LPC%ROWTYPE;        

   PERIODICIDAD NUMBER;         
   BASE_CALCULO NUMBER;
   MODALIDAD VARCHAR2(1);  
   TASA_REFERENCIA VARCHAR2(10);

   CURSOR C_ENA (NEMO VARCHAR2) IS
      SELECT ENA_MNEMONICO,
             ENA_AMORTIZABLE,
             ENA_CAPITALIZABLE,
             ENA_BMO_MNEMONICO,
             ENA_TIPO_PAGO_FLUJO,
             ENA_TITULO_PARTICIPATIVO
      FROM ESPECIES_NACIONALES
      WHERE ENA_MNEMONICO = NEMO;
   R_ENA C_ENA%ROWTYPE;

   CURSOR PRECIO_ESPECIE (ENA VARCHAR2) IS
      SELECT PEB_PRECIO_BOLSA
      FROM PRECIOS_ESPECIES_BOLSA A
      WHERE PEB_ENA_MNEMONICO = ENA
        AND PEB_FECHA = (SELECT MAX(PEB_FECHA )
                         FROM PRECIOS_ESPECIES_BOLSA B
                         WHERE B.PEB_ENA_MNEMONICO = ENA
                           AND PEB_FECHA < TRUNC(QFECHA + 1));
   VALOR_ESPECIE NUMBER;

    CURSOR VALOR_MONEDA (BMO VARCHAR2) IS
       SELECT NVL(CBM_VALOR,0) CBM_VALOR
       FROM COTIZACIONES_BASE_MONETARIAS
       WHERE CBM_BMO_MNEMONICO = BMO
         AND TRUNC(CBM_FECHA) = TRUNC(QFECHA);

   VALOR_BMO NUMBER;


   VALOR_TITULO_TM NUMBER;
   TASA_VALORACION NUMBER := NULL;
   TASA_DESCUENTO NUMBER := NULL;
   INDICADOR_VALORACION VARCHAR2(2) := NULL;
   DESC_ERROR VARCHAR2(1000);
   NO_NEMO EXCEPTION;
BEGIN
   OPEN C_LPC;
   FETCH C_LPC INTO R_LPC;
   WHILE C_LPC%FOUND LOOP
      VALOR_TITULO_TM := 0;
      TASA_VALORACION := NULL;
      TASA_DESCUENTO  := NULL;
      INDICADOR_VALORACION  := NULL;
      OPEN C_ENA(R_LPC.LPC_MNEMOTECNICO_TITULO);
      FETCH C_ENA INTO R_ENA;
      IF C_ENA%NOTFOUND THEN
         RAISE NO_NEMO;           
      END IF;
      CLOSE C_ENA;
      DBMS_OUTPUT.PUT_LINE('ENA='||R_LPC.LPC_MNEMOTECNICO_TITULO);
      DBMS_OUTPUT.PUT_LINE('TIPO='||R_LPC.LPC_CLASE_TRANSACCION);
      IF R_ENA.ENA_TITULO_PARTICIPATIVO = 'S' THEN
         IF R_ENA.ENA_BMO_MNEMONICO != 'PESOS' THEN
            OPEN VALOR_MONEDA(R_ENA.ENA_BMO_MNEMONICO);
                FETCH VALOR_MONEDA INTO VALOR_BMO;
                IF VALOR_MONEDA%FOUND THEN
                   VALOR_BMO := NVL(VALOR_BMO,0);
                ELSE
                      VALOR_BMO := 0;
                END IF;
            CLOSE VALOR_MONEDA;
             ELSE
                VALOR_BMO := 1;       
         END IF;
         UPDATE LIQUIDACIONES_POR_CUMPLIR
         SET LPC_FECHA_VALORACION       = QFECHA,
             LPC_VALORACION_TM          = VALOR_TITULO_TM * VALOR_BMO,
             LPC_INDICADOR_VALORACION   = INDICADOR_VALORACION,
             LPC_TASA_VALORACION        = TASA_VALORACION,
             LPC_TASA_DESCUENTO         = TASA_DESCUENTO
         WHERE LPC_CONSECUTIVO = R_LPC.LPC_CONSECUTIVO;
      ELSE      
         IF R_LPC.LPC_CLASE_TRANSACCION = 'RF' THEN
            IF R_LPC.LPC_PERIODICIDAD = 'N' THEN
                  PERIODICIDAD := NULL;
               ELSIF R_LPC.LPC_PERIODICIDAD = 'M' THEN
                  PERIODICIDAD := 30;
            ELSIF R_LPC.LPC_PERIODICIDAD = 'B' THEN
                  PERIODICIDAD := 60;            
               ELSIF R_LPC.LPC_PERIODICIDAD = 'T' THEN
                  PERIODICIDAD := 90;
               ELSIF R_LPC.LPC_PERIODICIDAD = 'C' THEN
                  PERIODICIDAD := 120;
               ELSIF R_LPC.LPC_PERIODICIDAD = 'S' THEN
                  PERIODICIDAD := 180;      
               ELSIF R_LPC.LPC_PERIODICIDAD = 'A' THEN
                  IF R_LPC.LPC_BASE_CALCULO_INTERES = 'C' THEN 
                     PERIODICIDAD := 360;
                  ELSE
                        PERIODICIDAD := 365;
                  END IF;
            ELSIF R_LPC.LPC_PERIODICIDAD = 'P' THEN
                 IF R_LPC.LPC_BASE_CALCULO_INTERES = 'C' THEN
                    PERIODICIDAD := P_FINANCIERO.DIAS360(TRUNC(R_LPC.LPC_FECHA_VENCIMIENTO),TRUNC(R_LPC.LPC_FECHA_EMISION));            
                 ELSE
                       PERIODICIDAD := P_FINANCIERO.DIAS_365(TRUNC(R_LPC.LPC_FECHA_EMISION),TRUNC(R_LPC.LPC_FECHA_VENCIMIENTO));            
                 END IF;
            ELSIF R_LPC.LPC_PERIODICIDAD = '0' THEN
               PERIODICIDAD := 0;
            ELSE
               PERIODICIDAD := NULL;
            END IF;

            IF R_LPC.LPC_BASE_CALCULO_INTERES = 'C' THEN
               BASE_CALCULO := 360;
            ELSE 
               BASE_CALCULO := 365;
            END IF;

            IF R_LPC.LPC_MODALIDAD = 'O' THEN
               MODALIDAD := 'D';
               PERIODICIDAD := 0;
            ELSE
               MODALIDAD := R_LPC.LPC_MODALIDAD;
            END IF;

            IF NVL(R_LPC.LPC_TASA_REFERENCIA,'0') = '0' THEN
               TASA_REFERENCIA := NULL;
            ELSE
               TASA_REFERENCIA := P_TOOLS.FN_LIC_TASA_REFERENCIA(R_LPC.LPC_TASA_REFERENCIA);
               IF TASA_REFERENCIA = '0' THEN
                  TASA_REFERENCIA := NULL;
               END IF;
            END IF;

            IF TASA_REFERENCIA IS NULL THEN
               R_LPC.LPC_PUNTOS_AJUSTE := NULL;
            ELSE
               IF R_LPC.LPC_PUNTOS_AJUSTE IS NULL THEN
                  R_LPC.LPC_PUNTOS_AJUSTE := 0;
               END IF;
            END IF;

            -- generar flujos
            CORRER_FLUJOS( 'S'
                           ,R_LPC.LPC_MNEMOTECNICO_TITULO
                           ,R_LPC.LPC_FECHA_EMISION
                           ,R_LPC.LPC_FECHA_VENCIMIENTO
                           ,R_ENA.ENA_AMORTIZABLE
                           ,R_ENA.ENA_CAPITALIZABLE
                           ,TASA_REFERENCIA
                           ,R_LPC.LPC_PUNTOS_AJUSTE
                           ,R_LPC.LPC_TASA_EMISION
                           ,R_ENA.ENA_TIPO_PAGO_FLUJO
                           ,R_LPC.LPC_PERIODICIDAD||R_LPC.LPC_MODALIDAD
                           ,PERIODICIDAD
                           ,MODALIDAD
                           ,BASE_CALCULO
                           ,R_LPC.LPC_FECHA_OPERACION
                           ,R_LPC.LPC_VOLUMEN_FRACCION
                           ,R_LPC.LPC_CANTIDAD_FRACCION);

            -- VALOR DE TASA MERCADO EN LA BASE MONETARIA DE LA LIQUIDACION

            VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO 
                                         ( P_TIPO => 'OT'   -- FORMA A CALULAR EN EL VALORIZADOR
                                          ,P_VALOR_NOMINAL      => R_LPC.LPC_CANTIDAD_FRACCION
                                          ,P_FECHA_VAL          => QFECHA  -- FECHA VALORACION
                                          ,P_ENA_MNEMONICO      => R_LPC.LPC_MNEMOTECNICO_TITULO   
                                          ,P_FECHA_EMISION      => R_LPC.LPC_FECHA_EMISION
                                          ,P_FECHA_VENCIMIENTO  => R_LPC.LPC_FECHA_VENCIMIENTO
                                          ,P_PERIODICIDAD_TASA  => PERIODICIDAD
                                          ,P_MODALIDAD_TASA     => MODALIDAD
                                          ,P_TASA_FACIAL        => R_LPC.LPC_TASA_EMISION
                                          ,P_BMO_MNEMONICO      => R_ENA.ENA_BMO_MNEMONICO
                                          ,P_TRE_MNEMONICO      => TASA_REFERENCIA
                                          ,P_PUNTOS_ADICIONALES => R_LPC.LPC_PUNTOS_AJUSTE
                                          ,P_BASE_CALCULO       => BASE_CALCULO
                                          ,P_TASA_VALORACION    => TASA_VALORACION
                                          ,P_TASA_DESCUENTO     => TASA_DESCUENTO
                                          ,P_INDICADOR_VAL      => INDICADOR_VALORACION
                                          );

            IF TASA_VALORACION > 9999999 THEN
               TASA_VALORACION := 0;
            END IF;
            IF TASA_DESCUENTO > 9999999 THEN
               TASA_DESCUENTO := 0;
            END IF;
            IF R_ENA.ENA_BMO_MNEMONICO != 'PESOS' THEN
               OPEN VALOR_MONEDA(R_ENA.ENA_BMO_MNEMONICO);
                   FETCH VALOR_MONEDA INTO VALOR_BMO;
                   IF VALOR_MONEDA%FOUND THEN
                      VALOR_BMO := NVL(VALOR_BMO,0);
                   ELSE
                         VALOR_BMO := 0;
                   END IF;
               CLOSE VALOR_MONEDA;
                ELSE
                   VALOR_BMO := 1;       
            END IF;

            UPDATE LIQUIDACIONES_POR_CUMPLIR
            SET LPC_FECHA_VALORACION       = QFECHA,
                LPC_VALORACION_TM          = VALOR_TITULO_TM * VALOR_BMO,
                LPC_INDICADOR_VALORACION   = INDICADOR_VALORACION,
                LPC_TASA_VALORACION        = TASA_VALORACION,
                LPC_TASA_DESCUENTO         = TASA_DESCUENTO
            WHERE LPC_CONSECUTIVO = R_LPC.LPC_CONSECUTIVO;

         ELSIF R_LPC.LPC_CLASE_TRANSACCION = 'ACC' THEN
            DBMS_OUTPUT.PUT_LINE('ENA='||R_LPC.LPC_MNEMOTECNICO_TITULO);    
            OPEN PRECIO_ESPECIE(R_LPC.LPC_MNEMOTECNICO_TITULO);
            FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
            IF PRECIO_ESPECIE%NOTFOUND THEN
                  VALOR_ESPECIE := 0;
            ELSE
                  VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
            END IF;
            CLOSE PRECIO_ESPECIE;
            DBMS_OUTPUT.PUT_LINE('VR ENA='||TO_CHAR(VALOR_ESPECIE));    
            UPDATE LIQUIDACIONES_POR_CUMPLIR
            SET LPC_FECHA_VALORACION       = QFECHA,
                LPC_VALORACION_TM          = R_LPC.LPC_CANTIDAD_FRACCION * VALOR_ESPECIE, 
                LPC_INDICADOR_VALORACION   = 'PR',
                LPC_TASA_VALORACION        = '',
                LPC_TASA_DESCUENTO         = ''
            WHERE LPC_CONSECUTIVO = R_LPC.LPC_CONSECUTIVO;
         END IF;
      END IF;
      FETCH C_LPC INTO R_LPC;
   END LOOP;
   CLOSE C_LPC;
   COMMIT;
EXCEPTION
     WHEN NO_NEMO THEN
      INSERT INTO HST_ERROR
             (HRR_FECHA,
              HRR_CONSECUTIVO,
              HRR_DESCRIPCION,
              HRR_ORIGEN)
      VALUES (QFECHA,  
              P_CONSECUTIVO,
              'NO ESTA CREADO EL NEMO EN COEASY '||R_LPC.LPC_MNEMOTECNICO_TITULO,
              'LPC');
   WHEN OTHERS THEN
      DESC_ERROR := SUBSTR(sqlerrm,1,990);
      INSERT INTO HST_ERROR
             (HRR_FECHA,
              HRR_CONSECUTIVO,
              HRR_DESCRIPCION,
              HRR_ORIGEN)
      VALUES (QFECHA,  --SYSDATE,
              P_CONSECUTIVO,
              DESC_ERROR,
              'LPC');

END GENERAR_VALORACION_LPC ;    


/***  PROCEDIMIENTO PARA ENVIAR MAIL CON TITULOS VALORADOS EN UNA FECHA QUE SE FUERON POR TIR O QUE NO VALORARON  ****/
PROCEDURE MAIL_TITULOS_VALORADOS (P_FECHA IN DATE) IS
   DIRECCION VARCHAR2(1000);
   TIPO1     VARCHAR2(2000);
   conn      utl_smtp.connection;
   req       utl_http.req;  
   resp      utl_http.resp;
   CRLF      VARCHAR2(2) :=  CHR(13)||CHR(10);  

   CURSOR C_HST IS
      SELECT HST_CCC_CLI_PER_NUM_IDEN    NUM_IDENTIFICACION
            ,HST_CCC_CLI_PER_TID_CODIGO  T_IDENTIFICACION
            ,HST_CCC_NUMERO_CUENTA       CUENTA
            ,HST_SALDO_DISPONIBLE        SALDO_DISPONIBLE
            ,HST_SALDO_GARANTIA          SALDO_GARANTIA
            ,HST_SALDO_EMBARGO           SALDO_EMBARGO
            ,HST_CFC_FUG_ISI_MNEMONICO   ISIN
            ,HST_CFC_FUG_MNEMONICO       FUNGIBLE
            ,HST_CFC_CUENTA_DECEVAL      CUENTA_DECEVAL
            ,HST_TLO_CODIGO              NUMERO_TITULO
            ,TLO_ENA_MNEMONICO           ESPECIE
            ,'SE VA POR TIR'             OBSERVACIONES
      FROM HISTORICOS_SALDOS_TITULOS,
           TITULOS
      WHERE HST_TLO_CODIGO = TLO_CODIGO (+)
      AND HST_FECHA >= TRUNC(SYSDATE-1)
      AND HST_INDICADOR_VALORACION = 'NV'
      union all
      SELECT HST_CCC_CLI_PER_NUM_IDEN nUM_IDENTIFICACION
            ,HST_CCC_CLI_PER_TID_CODIGO  T_IDENTIFICACION
            ,HST_CCC_NUMERO_CUENTA  CUENTA
            ,HST_SALDO_DISPONIBLE   SALDO_DISPONIBLE
            ,HST_SALDO_GARANTIA     SALDO_GARANTIA
            ,HST_SALDO_EMBARGO      SALDO_EMBARGO
            ,HST_CFC_FUG_ISI_MNEMONICO   ISIN
            ,HST_CFC_FUG_MNEMONICO     FUNGIBLE
            ,HST_CFC_CUENTA_DECEVAL    CUENTA_DECEVAL
            ,HST_TLO_CODIGO            NUMERO_TITULO
            ,TLO_ENA_MNEMONICO         ESPECIE
            ,SUBSTR(HRR_DESCRIPCION,67,96)  OBSERVACIONES
      FROM HISTORICOS_SALDOS_TITULOS,
           HST_ERROR,
           TITULOS
      WHERE HST_CONSECUTIVO = HRR_CONSECUTIVO
      AND HST_TLO_CODIGO = TLO_CODIGO (+)
      AND HST_FECHA >= TRUNC(SYSDATE-1)
      AND HST_INDICADOR_VALORACION is null;
   R_HST C_HST%ROWTYPE;

BEGIN

   CONN := P_MAIL.BEGIN_MAIL(SENDER     => 'administrador@corredores.com',
                             RECIPIENTS => 'dsantos@corredores.com;jtorres@corredores.com;jcruz@corredores.com;jarango@corredores.com;'
                                           ||'jaurregop@davivienda.com;marodriguezt@davivienda.com;'
                                           ||'lchernandezr@davivienda.com;elkin.castaneda@davivienda.com;'
                                           ||'jgrodriguez@davivienda.com;jjmartinez@davivienda.com',
                             subject    => 'Proceso de valoracion de titulos en COEASY : '||TO_CHAR(P_FECHA,'DD-MON-YYYY'),
                             mime_type  => p_mail.MULTIPART_MIME_TYPE);

   p_mail.begin_attachment(conn         => conn,
                           mime_type    => 'VALORADOS_'||TO_CHAR(P_FECHA,'DDMONYYYY')||'/txt',
                           inline       => TRUE,
                           filename     => 'VALORADOS_'||TO_CHAR(P_FECHA,'DDMONYYYY')||'.txt',
                           transfer_enc => 'text');      
   TIPO1 := 'NUM_IDENTIFICACION'||';'||
            'T_IDENTIFICACION'||';'||
            'CUENTA'||';'||
            'SALDO_DISPONIBLE'||';'||
            'SALDO_GARANTIA'||';'||
            'SALDO_EMBARGO'||';'||
            'ISIN'||';'||
            'FUNGIBLE'||';'||
            'CUENTA_DECEVAL'||';'||
            'NUMERO_TITULO'||';'||
            'ESPECIE'||';'||
            'OBSERVACIONES';
   p_mail.write_mb_text(conn,TIPO1||CRLF);

   OPEN C_HST;
   FETCH C_HST INTO R_HST;
   WHILE C_HST%FOUND LOOP                
      TIPO1 := R_HST.NUM_IDENTIFICACION||';'||
               R_HST.T_IDENTIFICACION||';'||
               TO_CHAR(R_HST.CUENTA)||';'||
               TO_CHAR(R_HST.SALDO_DISPONIBLE)||';'||
               TO_CHAR(R_HST.SALDO_GARANTIA)||';'||
               TO_CHAR(R_HST.SALDO_EMBARGO)||';'||
               R_HST.ISIN||';'||
               R_HST.FUNGIBLE||';'||
               TO_CHAR(R_HST.CUENTA_DECEVAL)||';'||
               TO_CHAR(R_HST.NUMERO_TITULO)||';'||
               R_HST.ESPECIE||';'||
               R_HST.OBSERVACIONES;
      p_mail.write_mb_text(conn,TIPO1||CRLF);
      FETCH C_HST INTO R_HST;
   END LOOP;
   CLOSE C_HST;
   p_mail.end_attachment( conn => conn );
   p_mail.end_mail( conn => conn );

EXCEPTION
      WHEN OTHERS THEN
         p_mail.write_mb_text(conn,'Error en generacion archivo :'||'VALORADOS_'||TO_CHAR(P_FECHA,'DDMONYYYY')||'.txt'||SQLERRM);
         p_mail.end_attachment( conn => conn );
         p_mail.end_mail( conn => conn );  
END  MAIL_TITULOS_VALORADOS;

FUNCTION DIA_HABIL(FECOPE IN DATE,
                   FECCUM IN DATE) RETURN NUMBER IS
   CURSOR DIAS(DINOHA DATE) IS 
      SELECT 'X'
      FROM   DIAS_NO_HABILES
      WHERE  DNH_FECHA = DINOHA; 
   DATO       VARCHAR2(1);
   CONTADOR   NUMBER;
   FECHA_OPE  DATE;
BEGIN
   CONTADOR := 0;
   FECHA_OPE := FECOPE;
   WHILE FECHA_OPE <= FECCUM LOOP  
      IF TO_CHAR(FECHA_OPE,'D') IN ('1','7') THEN 
         CONTADOR := CONTADOR + 1;
      ELSE 
         OPEN DIAS(FECHA_OPE);
         FETCH DIAS INTO DATO;
         IF DIAS%FOUND THEN
            CONTADOR := CONTADOR + 1;
         END IF;
         CLOSE DIAS; 
      END IF; 
      FECHA_OPE := FECHA_OPE + 1;
   END LOOP;
   CONTADOR := (FECCUM - FECOPE) - CONTADOR;
   RETURN (CONTADOR);
END;    

FUNCTION ObtenerValorDeMercado(P_FUG_MNEMONICO IN FUNGIBLES.FUG_MNEMONICO%TYPE,
            P_FUG_ISI_MNEMONICO IN FUNGIBLES.FUG_ISI_MNEMONICO%TYPE,
            P_TLO_CODIGO IN TITULOS.TLO_CODIGO%TYPE,
            P_FECHA_PROCESAR IN DATE,
            P_INDICADOR_VALORACION OUT VARCHAR2) RETURN NUMBER
IS
   CURSOR C_FUG (ISIN VARCHAR2, FUG NUMBER) IS
      SELECT /*+ INDEX(F FUG_PK) */  FUG_ISI_MNEMONICO      
             ,FUG_MNEMONICO          
             ,FUG_TIPO               
             ,FUG_ESTADO             
             ,FUG_BMO_MNEMONICO      
             ,FUG_FECHA_EMISION      
             ,FUG_FECHA_EXPEDICION   
             ,FUG_FECHA_VENCIMIENTO  
             ,FUG_BASE_CALCULO       
             ,FUG_MODALIDAD_TASA     
             ,FUG_TASA_FACIAL *100 FUG_TASA_FACIAL
             ,FUG_TRE_MNEMONICO   
             ,FUG_PUNTOS_ADICIONALES
             ,FUG_PERIODICIDAD_TASA  
             ,FUG_TIPO_TES        
             ,FUG_AMORTIZABLE
             ,FUG_CAPITALIZABLE
             ,FUG_TIPO_PAGO_FLUJO   
             ,FUG_CODIGO_PERIODO
             ,FUG_TITULO_PARTICIPATIVO
             ,(SELECT ISE_ENA_MNEMONICO
              FROM ISINS_ESPECIES ISI1
              WHERE ISE_ISI_MNEMONICO = ISIN
                AND ISE_ENA_MNEMONICO = (SELECT MIN(ISE_ENA_MNEMONICO)
                                     FROM ISINS_ESPECIES ISE2
                                     WHERE ISE_ISI_MNEMONICO = ISIN)) ESPECIE
      FROM FUNGIBLES F
      WHERE FUG_ISI_MNEMONICO = ISIN
        AND FUG_MNEMONICO = FUG;
   R_FUG C_FUG%ROWTYPE;

   CURSOR C_ISE (ISIN VARCHAR2) IS
      SELECT ISE_ENA_MNEMONICO
      FROM ISINS_ESPECIES
      WHERE ISE_ISI_MNEMONICO = ISIN;
   R_ISE C_ISE%ROWTYPE;

   CURSOR C_TLO (CONS NUMBER) IS
      SELECT  TLO_TYPE                       
             ,TLO_ENA_MNEMONICO              
             ,TLO_FECHA_OPERACION            
             ,TLO_TRE_MNEMONICO              
             ,TLO_BMO_MNEMONICO              
             ,TLO_FECHA_EMISION              
             ,TLO_FECHA_VENCIMIENTO          
             ,TLO_PUNTOS_ADICIONALES         
             ,TLO_VALOR_NOMINAL              
             ,TLO_TASA_FACIAL * 100  TLO_TASA_FACIAL              
             ,TLO_PERIODICIDAD_TASA          
             ,TLO_BASE_CALCULO               
             ,TLO_MODALIDAD_TASA 
             ,TLO_AMORTIZABLE
             ,TLO_CAPITALIZABLE
             ,TLO_TIPO_PAGO_FLUJO
             ,TLO_CODIGO_PERIODO
             ,ENA_TITULO_PARTICIPATIVO            
      FROM TITULOS
      INNER JOIN ESPECIES_NACIONALES ON TLO_ENA_MNEMONICO = ENA_MNEMONICO
      WHERE TLO_CODIGO = CONS;
   R_TLO C_TLO%ROWTYPE;

   CURSOR VALOR_MONEDA (BMO VARCHAR2) IS
       SELECT /*+ INDEX(C1 CBM_PK) */ NVL(CBM_VALOR,0) CBM_VALOR
       FROM COTIZACIONES_BASE_MONETARIAS C1
       WHERE CBM_BMO_MNEMONICO = BMO
       AND TRUNC(CBM_FECHA) = TRUNC(P_FECHA_PROCESAR);
   VALOR_BMO NUMBER;

   CURSOR PRECIO_ESPECIE (ENA VARCHAR2) IS
      SELECT /*+ INDEX(P1 PEB_PK) */  PEB_PRECIO_BOLSA
      FROM PRECIOS_ESPECIES_BOLSA P1
      WHERE P1.PEB_ENA_MNEMONICO = ENA
        AND P1.PEB_FECHA = (SELECT /*+ INDEX(P2 PEB_PK) */ MAX(PEB_FECHA)
                         FROM PRECIOS_ESPECIES_BOLSA P2
                         WHERE P2.PEB_ENA_MNEMONICO = ENA
                           AND P2.PEB_FECHA < TRUNC(P_FECHA_PROCESAR + 1));
   VALOR_ESPECIE NUMBER;

   VALOR_TITULO_TM NUMBER;
   TASA_VALORACION NUMBER := NULL;
   TASA_DESCUENTO NUMBER := NULL;

   V_RETORNAR NUMBER;
BEGIN
    IF P_FUG_MNEMONICO IS NOT NULL AND P_FUG_ISI_MNEMONICO IS NOT NULL THEN
         OPEN C_FUG(P_FUG_ISI_MNEMONICO, P_FUG_MNEMONICO);
         FETCH C_FUG INTO R_FUG;
         CLOSE C_FUG;

         IF NVL(R_FUG.FUG_TITULO_PARTICIPATIVO ,'N') = 'S' THEN   -- TITULOS PARTICIPATIVOS = valor_nominal * vr. unidad
               IF R_FUG.FUG_BMO_MNEMONICO != 'PESOS' THEN
                    OPEN VALOR_MONEDA(R_FUG.FUG_BMO_MNEMONICO);
                    FETCH VALOR_MONEDA INTO VALOR_BMO;
                    IF VALOR_MONEDA%FOUND THEN
                     VALOR_BMO := NVL(VALOR_BMO,0);
                    ELSE
                     VALOR_BMO := 0;
                    END IF;
                    CLOSE VALOR_MONEDA;
                   ELSE
                      VALOR_BMO := 1;       
               END IF;
               V_RETORNAR := VALOR_BMO;
               P_INDICADOR_VALORACION := 'PR';
         ELSE
             IF R_FUG.FUG_TIPO = 'RF' THEN
                OPEN C_ISE(P_FUG_ISI_MNEMONICO);
                FETCH C_ISE INTO R_ISE;
                CLOSE C_ISE;

                CORRER_FLUJOS('N'
                           ,R_ISE.ISE_ENA_MNEMONICO
                           ,R_FUG.FUG_FECHA_EMISION
                           ,R_FUG.FUG_FECHA_VENCIMIENTO
                           ,R_FUG.FUG_AMORTIZABLE
                           ,R_FUG.FUG_CAPITALIZABLE
                           ,R_FUG.FUG_TRE_MNEMONICO
                           ,R_FUG.FUG_PUNTOS_ADICIONALES
                           ,R_FUG.FUG_TASA_FACIAL
                           ,R_FUG.FUG_TIPO_PAGO_FLUJO
                           ,R_FUG.FUG_CODIGO_PERIODO
                           ,R_FUG.FUG_PERIODICIDAD_TASA
                           ,R_FUG.FUG_MODALIDAD_TASA
                           ,R_FUG.FUG_BASE_CALCULO
                           ,P_FECHA_PROCESAR
                           ,1
                           ,1);

                --VALOR A TASA MERCADO EN LA BASE MONETARIA DEL TITULO
                  VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO ( P_TIPO            => 'FS'   -- FORMA A CALCULAR EN EL VALORIZADOR: FUNGIBLES GENERANDO FLUJOS
                                                                        ,P_ISIN            => P_FUG_ISI_MNEMONICO
                                                                        ,P_FUNGIBLE        => P_FUG_MNEMONICO
                                                                        ,P_VALOR_NOMINAL   => 1
                                                                        ,P_FECHA_VAL       => P_FECHA_PROCESAR
                                                                        ,P_TASA_VALORACION => TASA_VALORACION
                                                                        ,P_TASA_DESCUENTO  => TASA_DESCUENTO
                                                                        ,P_INDICADOR_VAL   => P_INDICADOR_VALORACION
                                                                        );            
                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;

                  IF R_FUG.FUG_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_FUG.FUG_BMO_MNEMONICO);
                         FETCH VALOR_MONEDA INTO VALOR_BMO;
                         IF VALOR_MONEDA%FOUND THEN
                            VALOR_BMO := NVL(VALOR_BMO,0);
                         ELSE
                              VALOR_BMO := 0;
                         END IF;
                     CLOSE VALOR_MONEDA;
                      ELSE
                         VALOR_BMO := 1;       
                  END IF;
                  V_RETORNAR := VALOR_TITULO_TM * VALOR_BMO;

             ELSIF R_FUG.FUG_TIPO = 'ACC' THEN
                  OPEN PRECIO_ESPECIE(R_FUG.ESPECIE);
                  FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                  IF PRECIO_ESPECIE%NOTFOUND THEN
                        VALOR_ESPECIE := 0;
                  ELSE
                        VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                  END IF;
                  CLOSE PRECIO_ESPECIE;
                  V_RETORNAR := VALOR_ESPECIE;
                  P_INDICADOR_VALORACION := 'PR';
             END IF;
         END IF;
    ELSE
        OPEN C_TLO(P_TLO_CODIGO);
        FETCH C_TLO INTO R_TLO;
        CLOSE C_TLO;

        IF NVL(R_TLO.ENA_TITULO_PARTICIPATIVO,'N') = 'S' THEN
               IF R_TLO.TLO_BMO_MNEMONICO != 'PESOS' THEN
                  OPEN VALOR_MONEDA(R_TLO.TLO_BMO_MNEMONICO);
                    FETCH VALOR_MONEDA INTO VALOR_BMO;
                    IF VALOR_MONEDA%FOUND THEN
                       VALOR_BMO := NVL(VALOR_BMO,0);
                      ELSE
                            VALOR_BMO := 0;
                      END IF;
                  CLOSE VALOR_MONEDA;
                   ELSE
                      VALOR_BMO := 1;       
               END IF;
               V_RETORNAR := VALOR_BMO;
               P_INDICADOR_VALORACION := 'PR';
        ELSE
             IF R_TLO.TLO_TYPE = 'TFC' THEN
                CORRER_FLUJOS('S'
                             ,R_TLO.TLO_ENA_MNEMONICO
                             ,R_TLO.TLO_FECHA_EMISION
                             ,R_TLO.TLO_FECHA_VENCIMIENTO
                             ,R_TLO.TLO_AMORTIZABLE
                             ,R_TLO.TLO_CAPITALIZABLE
                             ,R_TLO.TLO_TRE_MNEMONICO
                             ,R_TLO.TLO_PUNTOS_ADICIONALES
                             ,R_TLO.TLO_TASA_FACIAL
                             ,R_TLO.TLO_TIPO_PAGO_FLUJO
                             ,R_TLO.TLO_CODIGO_PERIODO
                             ,R_TLO.TLO_PERIODICIDAD_TASA
                             ,R_TLO.TLO_MODALIDAD_TASA
                             ,R_TLO.TLO_BASE_CALCULO
                             ,P_FECHA_PROCESAR                        -- genera los flujos de la fecha valoracion en adelante
                             ,R_TLO.TLO_VALOR_NOMINAL
                             ,R_TLO.TLO_VALOR_NOMINAL);

                -- VALOR DE TASA MERCADO EN LA BASE MONETARIA DEL TITULO
                VALOR_TITULO_TM := P_VALORIZAR_TITULOS.ENVIAR_DATOS_TITULO ( P_TIPO            => 'TS'   -- FORMA A CALULAR EN EL VALORIZADOR : TITULOS CLIENTES GENERANDO FLUJOS
                                                                              ,P_TITULO          => P_TLO_CODIGO
                                                                              ,P_FECHA_VAL       => P_FECHA_PROCESAR
                                                                              ,P_TASA_VALORACION => TASA_VALORACION
                                                                              ,P_TASA_DESCUENTO  => TASA_DESCUENTO
                                                                              ,P_INDICADOR_VAL   => P_INDICADOR_VALORACION
                                                                             );            
                  IF TASA_VALORACION > 9999999 THEN
                     TASA_VALORACION := 0;
                  END IF;
                  IF TASA_DESCUENTO > 9999999 THEN
                     TASA_DESCUENTO := 0;
                  END IF;
                  IF R_TLO.TLO_BMO_MNEMONICO != 'PESOS' THEN
                     OPEN VALOR_MONEDA(R_TLO.TLO_BMO_MNEMONICO);
                         FETCH VALOR_MONEDA INTO VALOR_BMO;
                         IF VALOR_MONEDA%FOUND THEN
                            VALOR_BMO := NVL(VALOR_BMO,0);
                         ELSE
                              VALOR_BMO := 0;
                         END IF;
                     CLOSE VALOR_MONEDA;
                      ELSE
                         VALOR_BMO := 1;       
                  END IF;                                                    
                  V_RETORNAR := (VALOR_TITULO_TM * VALOR_BMO)/R_TLO.TLO_VALOR_NOMINAL;

             ELSIF R_TLO.TLO_TYPE = 'ACC' THEN
                  OPEN PRECIO_ESPECIE(R_TLO.TLO_ENA_MNEMONICO);
                  FETCH PRECIO_ESPECIE INTO VALOR_ESPECIE;
                  IF PRECIO_ESPECIE%NOTFOUND THEN
                        VALOR_ESPECIE := 0;
                  ELSE
                        VALOR_ESPECIE := NVL(VALOR_ESPECIE,0);
                  END IF;
                  CLOSE PRECIO_ESPECIE;
                  V_RETORNAR := VALOR_ESPECIE;
                  P_INDICADOR_VALORACION := 'PR';
             END IF; 

        END IF;
    END IF;

    RETURN V_RETORNAR;
END ObtenerValorDeMercado; 

FUNCTION ObtenerValorDeMercado(P_FUG_MNEMONICO IN FUNGIBLES.FUG_MNEMONICO%TYPE,
            P_FUG_ISI_MNEMONICO IN FUNGIBLES.FUG_ISI_MNEMONICO%TYPE,
            P_TLO_CODIGO IN TITULOS.TLO_CODIGO%TYPE,
            P_FECHA_PROCESAR IN DATE) RETURN NUMBER
IS          
    P_INDICADOR_VALORACION VARCHAR2(2);
BEGIN
    RETURN ObtenerValorDeMercado(P_FUG_MNEMONICO,
            P_FUG_ISI_MNEMONICO,
            P_TLO_CODIGO,
            P_FECHA_PROCESAR,
            P_INDICADOR_VALORACION);
END ObtenerValorDeMercado;

PROCEDURE EjecutarObtenerValorDeMercado(P_FUG_MNEMONICO IN FUNGIBLES.FUG_MNEMONICO%TYPE,
            P_FUG_ISI_MNEMONICO IN FUNGIBLES.FUG_ISI_MNEMONICO%TYPE,
            P_TLO_CODIGO IN TITULOS.TLO_CODIGO%TYPE,
            P_FECHA_PROCESAR IN DATE,
            P_VALOR_MERCADO OUT NUMBER,
            P_INDICADOR_VALORACION OUT VARCHAR2)
IS
    v_valor NUMBER;
BEGIN
    v_valor := P_CLIENTES_TITULOS.ObtenerValorDeMercado(
        P_FUG_MNEMONICO,
        P_FUG_ISI_MNEMONICO,
        P_TLO_CODIGO,
        P_FECHA_PROCESAR,
        P_INDICADOR_VALORACION);
    P_VALOR_MERCADO := ROUND(v_valor,15);
END EjecutarObtenerValorDeMercado;

PROCEDURE BorrarTemporalesBolsa
IS
BEGIN
    -- BORRADO DE TABLAS DE VALORACION TMP CARGUES ANTERIORES : SE DEJA EL ULTIMO AÑO
   DELETE FROM TMP_MARGENES_VALORACION
   WHERE   TMV_FECHA_REGISTRO <= TRUNC(SYSDATE-365);  --  -8); 

   DELETE FROM TMP_CERO_CUPON_VALORACION
   WHERE CCV_FECHA_OPERACION <= TRUNC(SYSDATE-365);  --  -8);

   DELETE FROM TMP_BLOOMBERG_VALORACION
   WHERE TBV_FECHA_ARCHIVO <= TRUNC(SYSDATE-365);  --  -8);

   DELETE FROM TMP_PRECIOS_VALORACION
   WHERE TPV_FECHA_REGISTRO <= TRUNC(SYSDATE-365);  --  -8);

   DELETE FROM TMP_INDICES_VALORACION
   WHERE TIV_FECHA <= TRUNC(SYSDATE-365);  --  -8);
END BorrarTemporalesBolsa;

END P_CLIENTES_TITULOS;

/

  GRANT EXECUTE ON "PROD"."P_CLIENTES_TITULOS" TO "COE_RECURSOS";
