--------------------------------------------------------
--  File created - Saturday-April-25-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_SALDOS_CLIENTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_SALDOS_CLIENTES" AS
  FUNCTION  F_SALDO_EN_CANJE(P_CLI_PER_NUM_IDEN   VARCHAR2,
                             P_CLI_PER_TID_CODIGO VARCHAR2,
                             P_NUMERO_CUENTA      NUMBER,
                             P_DIAS_CANJE         NUMBER) RETURN NUMBER IS                                 
                             
    v_fecha_valida   VARCHAR2(1);
    v_fecha_recibos  DATE;

    CURSOR saldo_canje IS
      SELECT sum(ccj_monto)
      FROM consignaciones_caja,
           recibos_de_caja
      WHERE ccj_rca_suc_codigo         = rca_suc_codigo           
        AND ccj_rca_neg_consecutivo    = rca_neg_consecutivo
        AND ccj_rca_consecutivo        = rca_consecutivo        
        AND ccj_fecha_consignacion_cheque IS NOT NULL
        AND ccj_tipo_consignacion = 'CHE'
        AND ccj_cheque_devuelto = 'N'
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(ccj_fecha_consignacion_cheque,
                                                  P_DIAS_CANJE)) >= trunc(rca_fecha) 
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(ccj_fecha_consignacion_cheque,P_DIAS_CANJE+1))= trunc(sysdate)
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA
        AND EXISTS(SELECT 'X'
                   FROM cheques_caja
                   WHERE cca_ccj_consecutivo = ccj_consecutivo
                     AND cca_fecha_reconsignacion   IS NULL);


    CURSOR saldo_cheques (P_FECHA_RECIBOS DATE) IS
       SELECT SUM(cca_monto)
       FROM cheques_caja,
           recibos_de_caja
      WHERE cca_rca_suc_codigo         = rca_suc_codigo           
        AND cca_rca_neg_consecutivo    = rca_neg_consecutivo
        AND cca_rca_consecutivo        = rca_consecutivo        
        AND cca_ccj_consecutivo        IS NULL
        AND cca_fecha_reconsignacion   IS NULL
        AND cca_consignado             = 'S'
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA
        AND trunc(rca_fecha)           >= trunc(P_FECHA_RECIBOS)
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(rca_fecha,P_DIAS_CANJE+1))= trunc(sysdate)
        AND NOT EXISTS(SELECT 'X'
                       FROM cheques_devueltos
                       WHERE cde_cca_consecutivo = cca_consecutivo);

    CURSOR saldo_cheques_reconsignacion(P_FECHA_RECIBOS DATE) IS
       SELECT SUM(cca_monto)
       FROM cheques_caja,
           recibos_de_caja
      WHERE cca_rca_suc_codigo         = rca_suc_codigo           
        AND cca_rca_neg_consecutivo    = rca_neg_consecutivo
        AND cca_rca_consecutivo        = rca_consecutivo        
        AND cca_ccj_consecutivo        IS NULL
        AND cca_fecha_reconsignacion   IS NOT NULL
        AND cca_consignado             = 'S'
        AND trunc(cca_fecha_reconsignacion) >= trunc(P_FECHA_RECIBOS)
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(cca_fecha_reconsignacion,P_DIAS_CANJE+1))= trunc(sysdate);

    CURSOR saldo_credito(P_FECHA_RECIBOS DATE) IS
      SELECT sum(mcc_monto_canje)
      FROM movimientos_cuenta_corredores
      WHERE mcc_ccc_cli_per_num_iden = P_CLI_PER_NUM_IDEN
        AND mcc_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND mcc_ccc_numero_cuenta = P_NUMERO_CUENTA
        AND mcc_tmc_mnemonico = 'CSC'
        AND mcc_fecha >= trunc(P_FECHA_RECIBOS)
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(mcc_fecha,P_DIAS_CANJE+1)) =  trunc(sysdate);


    v_saldo_canje    consignaciones_caja.ccj_monto%TYPE;
    v_saldo_cheque   cheques_caja.cca_monto%TYPE;
    v_saldo_cheque_r cheques_caja.cca_monto%TYPE;
    v_saldo_credito  movimientos_cuenta_corredores.mcc_monto_canje%TYPE;
  BEGIN
    v_saldo_canje  := 0;
    v_saldo_cheque := 0;
    v_saldo_cheque_r := 0;
    v_saldo_credito  := 0;
    OPEN saldo_canje;
    FETCH saldo_canje INTO v_saldo_canje;
    IF saldo_canje%NOTFOUND THEN
      v_saldo_canje := 0;
    END IF;
    CLOSE saldo_canje;
    v_saldo_canje := nvl(v_saldo_canje,0);

    P_DIA_MCC_CANJE(P_CLI_PER_NUM_IDEN      => P_CLI_PER_NUM_IDEN,
                      P_CLI_PER_TID_CODIGO  => P_CLI_PER_TID_CODIGO,
                      P_NUMERO_CUENTA       => P_NUMERO_CUENTA,
                      P_FECHA_MCC           => v_fecha_recibos,
                      P_FECHA_VALIDA        => v_fecha_valida);

    OPEN saldo_credito(v_fecha_recibos);
    FETCH saldo_credito INTO v_saldo_credito;
    IF saldo_credito%NOTFOUND THEN
      v_saldo_credito := 0;
    END IF;
    CLOSE saldo_credito;
    v_saldo_credito := nvl(v_saldo_credito,0);

    IF v_fecha_valida = 'S' THEN                    
      OPEN saldo_cheques(v_fecha_recibos);
      FETCH saldo_cheques INTO v_saldo_cheque;
      IF saldo_cheques%NOTFOUND THEN
        v_saldo_cheque := 0;
      END IF;
      CLOSE saldo_cheques ;
      v_saldo_cheque  := nvl(v_saldo_cheque ,0);

      OPEN saldo_cheques_reconsignacion(v_fecha_recibos);
      FETCH saldo_cheques_reconsignacion INTO v_saldo_cheque_r;
      IF saldo_cheques_reconsignacion%NOTFOUND THEN
        v_saldo_cheque_r := 0;
      END IF;
      CLOSE saldo_cheques_reconsignacion ;    
      v_saldo_cheque_r  := nvl(v_saldo_cheque_r ,0);    
    ELSE
      v_saldo_cheque    := 0;
      v_saldo_cheque_r  := 0;
    END IF;

    RETURN(v_saldo_canje+v_saldo_cheque+v_saldo_cheque_r+v_saldo_credito);
  END F_SALDO_EN_CANJE;


  FUNCTION  F_PRUEBAS_SALDO_CANJE(P_CLI_PER_NUM_IDEN    VARCHAR2,
                             P_CLI_PER_TID_CODIGO  VARCHAR2,
                             P_NUMERO_CUENTA       NUMBER,
                             P_DIAS_CANJE          NUMBER,
                             P_FECHA_CANJE         DATE) RETURN NUMBER IS
      v_fecha_valida   VARCHAR2(1);
    v_fecha_recibos  DATE;
    CURSOR saldo_canje IS
      SELECT sum(ccj_monto)
      FROM consignaciones_caja,
           recibos_de_caja
      WHERE ccj_rca_suc_codigo         = rca_suc_codigo           
        AND ccj_rca_neg_consecutivo    = rca_neg_consecutivo
        AND ccj_rca_consecutivo        = rca_consecutivo        
        AND ccj_fecha_consignacion_cheque IS NOT NULL
        AND ccj_tipo_consignacion = 'CHE'
        AND ccj_cheque_devuelto = 'N'
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(ccj_fecha_consignacion_cheque,
                                                  P_DIAS_CANJE)) >= trunc(rca_fecha) 
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(ccj_fecha_consignacion_cheque,P_DIAS_CANJE+1))= TRUNC(P_FECHA_CANJE)        
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA;
    CURSOR saldo_cheques (P_FECHA_RECIBOS DATE) IS
       SELECT SUM(cca_monto)
       FROM cheques_caja,
           recibos_de_caja
      WHERE cca_rca_suc_codigo         = rca_suc_codigo           
        AND cca_rca_neg_consecutivo    = rca_neg_consecutivo
        AND cca_rca_consecutivo        = rca_consecutivo        
        AND cca_ccj_consecutivo        IS NULL
        AND cca_fecha_reconsignacion   IS NULL
        AND cca_consignado             = 'S'
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA
        AND trunc(rca_fecha)           >= trunc(P_FECHA_RECIBOS)
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(rca_fecha,P_DIAS_CANJE+1))= TRUNC(P_FECHA_CANJE)
        AND NOT EXISTS(SELECT 'X'
                       FROM cheques_devueltos
                       WHERE cde_cca_consecutivo = cca_consecutivo);
    CURSOR saldo_cheques_reconsignacion(P_FECHA_RECIBOS DATE) IS
       SELECT SUM(cca_monto)
       FROM cheques_caja,
           recibos_de_caja
      WHERE cca_rca_suc_codigo         = rca_suc_codigo           
        AND cca_rca_neg_consecutivo    = rca_neg_consecutivo
        AND cca_rca_consecutivo        = rca_consecutivo        
        AND cca_ccj_consecutivo        IS NULL
        AND cca_fecha_reconsignacion   IS NOT NULL
        AND trunc(cca_fecha_reconsignacion) >= trunc(P_FECHA_RECIBOS)
        AND cca_consignado             = 'S'
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(cca_fecha_reconsignacion,P_DIAS_CANJE+1))= TRUNC(P_FECHA_CANJE);

    CURSOR saldo_credito(P_FECHA_RECIBOS DATE) IS
      SELECT sum(mcc_monto_canje)
      FROM movimientos_cuenta_corredores
      WHERE mcc_ccc_cli_per_num_iden = P_CLI_PER_NUM_IDEN
        AND mcc_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND mcc_ccc_numero_cuenta = P_NUMERO_CUENTA
        AND mcc_tmc_mnemonico = 'CSC'
        AND mcc_fecha >= trunc(P_FECHA_RECIBOS)
        AND trunc(P_SALDOS_CLIENTES.F_FECHA_HABIL(mcc_fecha,P_DIAS_CANJE+1)) = TRUNC(P_FECHA_CANJE);
    v_saldo_canje    consignaciones_caja.ccj_monto%TYPE;
    v_saldo_cheque   cheques_caja.cca_monto%TYPE;
    v_saldo_cheque_r cheques_caja.cca_monto%TYPE;
    v_saldo_credito  movimientos_cuenta_corredores.mcc_monto_canje%TYPE;
  BEGIN
dbms_output.put_line('INICIO FUNCION');        
    v_saldo_canje  := 0;
    v_saldo_cheque := 0;
    v_saldo_cheque_r := 0;
    v_saldo_credito  := 0;
    OPEN saldo_canje;
    FETCH saldo_canje INTO v_saldo_canje;
    IF saldo_canje%NOTFOUND THEN
      v_saldo_canje := 0;
    END IF;
    CLOSE saldo_canje;
    v_saldo_canje := nvl(v_saldo_canje,0);
    P_DIA_MCC_CANJE(P_CLI_PER_NUM_IDEN      => P_CLI_PER_NUM_IDEN,
                      P_CLI_PER_TID_CODIGO  => P_CLI_PER_TID_CODIGO,
                      P_NUMERO_CUENTA       => P_NUMERO_CUENTA,
                      P_FECHA_MCC           => v_fecha_recibos,
                      P_FECHA_VALIDA        => v_fecha_valida);     
dbms_output.put_line('fecha mxccc :'||to_char(v_fecha_recibos));                      
dbms_output.put_line('v_fecha_valida :'||TO_CHAR(v_fecha_valida));

    OPEN saldo_credito(v_fecha_recibos);
    FETCH saldo_credito INTO v_saldo_credito;
    IF saldo_credito%NOTFOUND THEN
      v_saldo_credito := 0;
    END IF;
    CLOSE saldo_credito;
    v_saldo_credito := nvl(v_saldo_credito,0);
dbms_output.put_line('saldo credito :'||to_char(v_saldo_credito));      

    IF v_fecha_valida = 'S' THEN                    
      OPEN saldo_cheques(v_fecha_recibos);
      FETCH saldo_cheques INTO v_saldo_cheque;
      IF saldo_cheques%NOTFOUND THEN
        v_saldo_cheque := 0;
      END IF;
      CLOSE saldo_cheques ;
      v_saldo_cheque  := nvl(v_saldo_cheque ,0);
      OPEN saldo_cheques_reconsignacion(v_fecha_recibos);
      FETCH saldo_cheques_reconsignacion INTO v_saldo_cheque_r;
      IF saldo_cheques_reconsignacion%NOTFOUND THEN
        v_saldo_cheque_r := 0;
      END IF;
      CLOSE saldo_cheques_reconsignacion ;    
      v_saldo_cheque_r  := nvl(v_saldo_cheque_r ,0);          
    END IF;
    RETURN(v_saldo_canje+v_saldo_cheque+v_saldo_cheque_r+v_saldo_credito);
  END F_PRUEBAS_SALDO_CANJE;


  FUNCTION  F_SALDO_EN_CANJE_INICIAL(P_CLI_PER_NUM_IDEN  VARCHAR2,
                                     P_CLI_PER_TID_CODIGO VARCHAR2,
                                     P_NUMERO_CUENTA      NUMBER) RETURN NUMBER IS
    CURSOR saldo_cheques IS
       SELECT SUM(cca_monto) cca_monto
       FROM cheques_caja,
           recibos_de_caja
      WHERE cca_rca_suc_codigo         = rca_suc_codigo           
        AND cca_rca_neg_consecutivo    = rca_neg_consecutivo
        AND cca_rca_consecutivo        = rca_consecutivo        
        AND cca_ccj_consecutivo        IS NULL
        AND rca_reversado              = 'N'
        AND rca_es_cliente             = 'S'
        AND rca_ccc_cli_per_num_iden   = P_CLI_PER_NUM_IDEN
        AND rca_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
        AND rca_ccc_numero_cuenta      = P_NUMERO_CUENTA
        AND trunc(rca_fecha) >= TO_DATE('30-07-2007','DD-MM-YYYY');

    c_saldo_cheques saldo_cheques%ROWTYPE;    
    v_saldo_cheque NUMBER;
  BEGIN
    v_saldo_cheque := 0;
    OPEN saldo_cheques;
    FETCH saldo_cheques INTO c_saldo_cheques;
    CLOSE saldo_cheques;
    v_saldo_cheque := nvl(c_saldo_cheques.cca_monto,0);
    RETURN(v_saldo_cheque);    
    EXCEPTION WHEN OTHERS THEN 
      P_MAIL.ENVIO_MAIL_ERROR('Error ejecuntando F_SALDO_EN_CANJE_INICIAL ',SQLERRM);
      RAISE_APPLICATION_ERROR(-20001,'Error ejecuntando F_SALDO_EN_CANJE_INICIAL '||SQLERRM);
  END F_SALDO_EN_CANJE_INICIAL;  



  FUNCTION  F_FECHA_HABIL(P_FECHA_INICIAL DATE,
                          P_DIAS          NUMBER DEFAULT NULL) RETURN DATE IS
  /***************************************
    Objectivo : Funcion que retorna le fecha habil teniendo en cuenta los dias de canje
    Fecha : 26-jul-2007
    Corredorres Asociados S.A. - RHCL
    Parametros :
      * P_FECHA_INICIAL : Fecha a partir de la cual se calcula la fecha habil a retornar
      * P_DIAS : Numero de dias a calcular a partir de la fecha inicial
                 Valor igual NULL se calcula solo un dia
    ********************************************/  
    CURSOR c_dia_no_habil(p_fecha DATE) IS
      SELECT dnh_fecha
      FROM   dias_no_habiles
      WHERE  TRUNC(dnh_fecha) = TRUNC(p_fecha);
    v_cuenta       NUMBER;
    c_dia          c_dia_no_habil%rowtype;
    v_fecha        DATE;
  BEGIN
    v_fecha := TRUNC(P_FECHA_INICIAL);
    IF  P_DIAS IS NULL THEN
      WHILE TRUE LOOP
        v_cuenta := 0;
        FOR K IN C_DIA_NO_HABIL(v_fecha) LOOP
          v_cuenta := v_cuenta+1;
        END LOOP;
        IF nvl(v_cuenta,0) > 0 OR TO_CHAR(v_fecha,'D') IN (1,7) THEN
          v_fecha := v_fecha + 1;
        ELSE
          EXIT;
        END IF;
      END LOOP;
    ELSE
      FOR n IN 1..P_DIAS LOOP      
        WHILE TRUE LOOP
          v_cuenta := 0;
          FOR K IN C_DIA_NO_HABIL(v_fecha) LOOP
            v_cuenta := v_cuenta+1;
          END LOOP;
          IF nvl(v_cuenta,0) > 0 OR TO_CHAR(v_fecha,'D') IN (1,7) THEN
            v_fecha := v_fecha + 1;
          ELSE
            EXIT;
          END IF;
        END LOOP;
        IF P_DIAS != n THEN
          v_fecha := v_fecha + 1;
        END IF;
      END LOOP;
    END IF;
    RETURN trunc(v_fecha);
  END F_FECHA_HABIL;

  PROCEDURE P_DIA_MCC_CANJE(P_CLI_PER_NUM_IDEN    IN VARCHAR2,
                            P_CLI_PER_TID_CODIGO  IN VARCHAR2,
                            P_NUMERO_CUENTA       IN NUMBER,
                            P_FECHA_MCC           IN OUT DATE,
                            P_FECHA_VALIDA        IN OUT VARCHAR2) IS
  BEGIN
    DECLARE
       CURSOR C_FECHA IS 
          SELECT /*+ INDEX(MCC MCC_PK_I) */ trunc(mcc_fecha) 
          FROM   movimientos_cuenta_corredores mcc
          WHERE  mcc.mcc_ccc_cli_per_num_iden = P_CLI_PER_NUM_IDEN
          AND    mcc.mcc_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
          AND    mcc.mcc_ccc_numero_cuenta = P_NUMERO_CUENTA
          AND    MCC.MCC_FECHA > '30-JUL-2007'
          AND    MCC.MCC_SALDO_CANJE != 0
          ORDER BY MCC_CONSECUTIVO     ;
    BEGIN
       OPEN C_FECHA;
       FETCH C_FECHA INTO  P_FECHA_MCC;
       CLOSE C_FECHA;
/*  
       SELECT trunc(mcc_fecha) 
       INTO   P_FECHA_MCC
       FROM   movimientos_cuenta_corredores mcc
       WHERE  mcc.mcc_ccc_cli_per_num_iden = P_CLI_PER_NUM_IDEN
       AND    mcc.mcc_ccc_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
       AND    mcc.mcc_ccc_numero_cuenta = P_NUMERO_CUENTA
       AND    mcc.mcc_fecha = (SELECT MIN(mcc1.mcc_fecha)
                               FROM   movimientos_cuenta_corredores mcc1
                               WHERE  mcc1.mcc_ccc_cli_per_num_iden = mcc.mcc_ccc_cli_per_num_iden 
                               AND    mcc1.mcc_ccc_cli_per_tid_codigo = mcc.mcc_ccc_cli_per_tid_codigo 
                               AND    mcc1.mcc_ccc_numero_cuenta = mcc.mcc_ccc_numero_cuenta 
                               AND    mcc1.mcc_fecha >= '30-JUL-2007'
                               AND    mcc1.mcc_saldo_canje != 0);
       EXCEPTION WHEN OTHERS THEN P_FECHA_MCC := NULL;        
*/                 
    END;                               

    IF P_FECHA_MCC IS NULL THEN
      P_FECHA_VALIDA := 'N';
    ELSE   
      -- Fecha de inicio saldo en canje si es menor calculo los recibos desde  30-jul-2007
      IF TRUNC(P_FECHA_MCC) <= TO_DATE('01-08-2007','DD-MM-YYYY')  THEN
        P_FECHA_MCC := TO_DATE('30-07-2007','DD-MM-YYYY');
      END IF;  
      P_FECHA_VALIDA := 'S';
    END IF;                                 
  END P_DIA_MCC_CANJE;


 PROCEDURE P_CALCULO_SALDOS_CANJE(P_TX IN NUMBER DEFAULT NULL) IS
    /***************************************
    Objetivo : Paquete que recalcula los saldos en canje diariamente de los clientes 
                llamado en un proceso nocturno saldos_canje.sql
    Fecha : DICIEMBRE/2012
    Corredorres Asociados S.A. - 
    ********************************************/
   CURSOR C_CHEQUES IS
      SELECT CCA_CONSECUTIVO,
             CCA_RCA_SUC_CODIGO,
             CCA_RCA_NEG_CONSECUTIVO,
             CCA_RCA_CONSECUTIVO,
             RCA_CCC_CLI_PER_NUM_IDEN,
             RCA_CCC_CLI_PER_TID_CODIGO,
             RCA_CCC_NUMERO_CUENTA,
             CCA_FECHA_INICIO_CANJE,
             CCA_DIAS_CANJE,  
             CCA_FECHA_FIN_CANJE,
             CCA_MONTO
      FROM (SELECT CCA_CONSECUTIVO,
                   CCA_RCA_SUC_CODIGO,
                   CCA_RCA_NEG_CONSECUTIVO,
                   CCA_RCA_CONSECUTIVO,
                   RCA_CCC_CLI_PER_NUM_IDEN,
                   RCA_CCC_CLI_PER_TID_CODIGO,
                   RCA_CCC_NUMERO_CUENTA,
                   CCA_FECHA_INICIO_CANJE,
                   CCA_DIAS_CANJE,
                   CCA_FECHA_FIN_CANJE,
                   CCA_MONTO
            FROM   CHEQUES_CAJA,
                   RECIBOS_DE_CAJA,
                   CONSIGNACIONES_BANCARIAS,
                   CONSIGNACIONES_Y_CHEQUES
            WHERE  CCA_RCA_SUC_CODIGO  = RCA_SUC_CODIGO
            AND    CCA_RCA_NEG_CONSECUTIVO =RCA_NEG_CONSECUTIVO
            AND    CCA_RCA_CONSECUTIVO = RCA_CONSECUTIVO
            AND    CCA_CONSECUTIVO = CCH_CCA_CONSECUTIVO
            AND    CCH_COB_CONSECUTIVO = COB_CONSECUTIVO
            AND    CCH_COB_SUC_CODIGO = COB_SUC_CODIGO
            AND    CCH_COB_NEG_CONSECUTIVO = COB_NEG_CONSECUTIVO
            AND    RCA_ES_CLIENTE = 'S'            
            AND    NVL(RCA_REVERSADO,'N') = 'N'    
            AND    COB_REVERSADA = 'N'
            AND    CCH_DEVUELTO = 'N'
            AND    CCA_DIAS_CANJE > 0
            UNION ALL
            SELECT CCA_CONSECUTIVO,
                   CCJ_RCA_SUC_CODIGO,
                   CCJ_RCA_NEG_CONSECUTIVO,
                   CCJ_RCA_CONSECUTIVO,
                   RCA_CCC_CLI_PER_NUM_IDEN,
                   RCA_CCC_CLI_PER_TID_CODIGO,
                   RCA_CCC_NUMERO_CUENTA,
                   CCA_FECHA_INICIO_CANJE,
                   CCA_DIAS_CANJE,
                   CCA_FECHA_FIN_CANJE,
                   CCA_MONTO
            FROM   CHEQUES_CAJA,
                   CONSIGNACIONES_CAJA,
                   RECIBOS_DE_CAJA
           WHERE  CCJ_RCA_SUC_CODIGO  = RCA_SUC_CODIGO
           AND    CCJ_RCA_NEG_CONSECUTIVO = RCA_NEG_CONSECUTIVO
           AND    CCJ_RCA_CONSECUTIVO = RCA_CONSECUTIVO
           AND    CCJ_CONSECUTIVO = CCA_CCJ_CONSECUTIVO
           AND    RCA_ES_CLIENTE = 'S'
           AND    NVL(RCA_REVERSADO,'N') = 'N'
           AND    NVL(CCJ_CHEQUE_DEVUELTO,'N') = 'N'
           AND    CCA_CONSIGNADO = 'S'
           AND    CCA_DIAS_CANJE > 0)
      ORDER BY CCA_CONSECUTIVO;    

   R_CCA C_CHEQUES%ROWTYPE;
   DIAS NUMBER;

   CURSOR DIA_HABIL(P_FECHA DATE) IS
      SELECT 'X'
      FROM   dias_no_habiles
      WHERE  TRUNC(dnh_fecha) = TRUNC(p_fecha);
   P_FECHA_HOY DATE;
   ES_FESTIVO VARCHAR2(1):= 'N';
   DATO       VARCHAR2(1);

   P_NUM_INI NUMBER;
   P_NUM_FIN NUMBER; 
   N_ID_PROCESO NUMBER;
   N_TX NUMBER;
BEGIN
   --se asigna el consecutivo del proceso(tabla PARAMETRIZACION_PROCESOS)
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_SALDOS_CLIENTES.P_CALCULO_SALDOS_CANJE');

    --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio proceso P_SALDOS_CLIENTES.P_CALCULO_SALDOS_CANJE. Fecha Proceso: verificacion de saldos en canje ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);

   SELECT SYSDATE INTO P_FECHA_HOY FROM DUAL;
   IF TO_CHAR(P_FECHA_HOY,'D') IN ('1','7') THEN
      ES_FESTIVO := 'S';
   ELSE
      OPEN DIA_HABIL(P_FECHA_HOY);
      FETCH DIA_HABIL INTO DATO;
      IF DIA_HABIL%FOUND THEN
         ES_FESTIVO := 'S';
      END IF;
      CLOSE DIA_HABIL;
   END IF;
   IF ES_FESTIVO = 'N' THEN
      OPEN C_CHEQUES;
      FETCH C_CHEQUES INTO R_CCA;
      WHILE C_CHEQUES%FOUND LOOP
         DIAS := 0;
         DIAS := P_WEB_EXTRACTO.DIA_HABIL(TRUNC(P_FECHA_HOY),TRUNC(R_CCA.CCA_FECHA_FIN_CANJE));
         IF DIAS < 0 THEN
            DIAS := 0;
         END IF;
         UPDATE CHEQUES_CAJA
         SET CCA_DIAS_CANJE = DIAS
         WHERE CCA_CONSECUTIVO = R_CCA.CCA_CONSECUTIVO;
         IF DIAS <= 0 THEN
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
                  ,MCC_MONTO_ADMON_VALORES
                  ,MCC_MONTO_CANJE
                  ,MCC_SUC_CODIGO
                  ,MCC_NEG_CONSECUTIVO
                  ,MCC_RCA_CONSECUTIVO)
               VALUES(
                  MCC_SEQ.NEXTVAL
                 ,R_CCA.RCA_CCC_CLI_PER_NUM_IDEN
                 ,R_CCA.RCA_CCC_CLI_PER_TID_CODIGO
                 ,R_CCA.RCA_CCC_NUMERO_CUENTA
                 ,SYSDATE 
                 ,'ASC'  --AFECTACION SALDOS EN CANJE CHEQUES    
                 ,0
                 ,0
                 ,0
                 ,0
                 ,-R_CCA.CCA_MONTO
                 ,R_CCA.CCA_RCA_SUC_CODIGO
                 ,R_CCA.CCA_RCA_NEG_CONSECUTIVO
                 ,R_CCA.CCA_RCA_CONSECUTIVO);
         END IF;   
         FETCH C_CHEQUES INTO R_CCA;
      END LOOP;
      CLOSE C_CHEQUES;
      COMMIT;
   END IF;   
  --Registra Traza
  P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'F',
                                    'Fin proceso P_SALDOS_CLIENTES.P_CALCULO_SALDOS_CANJE. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
  COMMIT; 
EXCEPTION 
    WHEN OTHERS THEN
      --Registra Traza ERROR
      P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                      'E',
                                      'Error ejecutando P_SALDOS_CLIENTES.P_CALCULO_SALDOS_CANJE :'||R_CCA.RCA_CCC_CLI_PER_NUM_IDEN||
                                      '-'||R_CCA.RCA_CCC_CLI_PER_TID_CODIGO||'-'||R_CCA.RCA_CCC_NUMERO_CUENTA||
                                      ' CONSECUTIVO CHEQUE: '||R_CCA.CCA_CONSECUTIVO||' Fecha: ' ||
                                      TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss') || ' ' ||
                                      SUBSTR(SQLERRM, 1, 150),
                                      N_TX);
END P_CALCULO_SALDOS_CANJE; 



  PROCEDURE P_SALDO_INICIAL_CANJE IS
  /***************************************
    Objectivo : Paquete que calcula el  saldo inicial en canje de los clientes 
    Fecha : 31-jul-2007
    Corredorres Asociados S.A. - RHCL
    ********************************************/
    CURSOR cuentas IS
      SELECT ccc_cli_per_num_iden
            ,ccc_cli_per_tid_codigo
            ,ccc_numero_cuenta
      FROM cuentas_cliente_corredores
      WHERE EXISTS(SELECT 'X'
                  FROM recibos_de_caja
                  WHERE rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                    AND rca_ccc_cli_per_tiD_codigo= ccc_cli_per_tid_codigo
                    AND rca_ccc_numero_cuenta = ccc_numero_cuenta
                    AND rca_reversado              = 'N'
                    AND rca_es_cliente             = 'S'        
                    AND trunc(rca_fecha) >= TO_DATE('30-07-2007','DD-MM-YYYY'));                   

--      WHERE ccc_saldo_canje > 0;
    CURSOR c_constante_canje IS
      SELECT con_valor
      FROM constantes
      WHERE con_mnemonico = 'DCC';      
    v_mensaje_error  VARCHAR2(250);      
    v_monto_canje    NUMBER;
    c_cuentas        cuentas%ROWTYPE;
    v_error          EXCEPTION;
  BEGIN
    OPEN cuentas;
    FETCH cuentas INTO c_cuentas;
    WHILE cuentas%FOUND LOOP
      v_monto_canje  := 0;
      DBMS_OUTPUT.PUT_LINE('calculanod :'||c_cuentas.ccc_cli_per_num_iden||'-'||c_cuentas.ccc_cli_per_tid_codigo);
      v_monto_canje := p_saldos_clientes.f_saldo_en_canje_inicial(p_cli_per_num_iden   => c_cuentas.ccc_cli_per_num_iden,
                                                          p_cli_per_tid_codigo => c_cuentas.ccc_cli_per_tid_codigo,
                                                          p_numero_cuenta      => c_cuentas.ccc_numero_cuenta);
      IF v_monto_canje > 0 THEN                                                          
        INSERT INTO movimientos_cuenta_corredores
           (mcc_consecutivo
           ,mcc_ccc_cli_per_num_iden        
           ,mcc_ccc_cli_per_tid_codigo      
           ,mcc_ccc_numero_cuenta           
           ,mcc_fecha
           ,mcc_tmc_mnemonico
           ,mcc_monto              
           ,mcc_monto_a_plazo      
           ,mcc_monto_a_contado    
           ,mcc_monto_admon_valores
           ,mcc_monto_canje)
        VALUES(
            mcc_seq.nextval
           ,c_cuentas.ccc_cli_per_num_iden
           ,c_cuentas.ccc_cli_per_tid_codigo
           ,c_cuentas.ccc_numero_cuenta
           ,SYSDATE
           ,'CSC'  --CREDITO SALDO INICIAL EN CANJE
           ,0
           ,0
           ,0
           ,0
           ,v_monto_canje);
      END IF;
      FETCH cuentas INTO c_cuentas;
    END LOOP;
    CLOSE cuentas;
    COMMIT;
    EXCEPTION 
    WHEN v_error THEN
      P_MAIL.ENVIO_MAIL_ERROR('Error P_SALDO_INICIAL_CANJE v_error ',v_mensaje_error);
      RAISE_APPLICATION_ERROR(-20002,'Error :'||v_mensaje_error);
    WHEN OTHERS THEN
      P_MAIL.ENVIO_MAIL_ERROR('Error others P_SALDO_INICIAL_CANJE ',SQLERRM);
      RAISE_APPLICATION_ERROR(-20001,'Error ejecuntando P_SALDO_INICIAL_CANJE '||SQLERRM);
  END P_SALDO_INICIAL_CANJE ;

  /*********PROCEDIMIENTO DE PRUEBAS*************/
  PROCEDURE P_PRUEBA_SALDOS_CANJE(P_CLI_PER_NUM_IDEN   VARCHAR2 DEFAULT NULL,
                                  P_CLI_PER_TID_CODIGO VARCHAR2 DEFAULT NULL,
                                  P_NUMERO_CUENTA      NUMBER DEFAULT NULL, 
                                  P_FECHA_CANJE        DATE DEFAULT NULL) IS
CURSOR cuentas IS
      SELECT ccc_cli_per_num_iden
            ,ccc_cli_per_tid_codigo
            ,ccc_numero_cuenta
      FROM cuentas_cliente_corredores
      WHERE ccc_saldo_canje > 0
        AND ccc_cli_per_num_iden = DECODE(P_CLI_PER_NUM_IDEN,NULL,ccc_cli_per_num_iden,P_CLI_PER_NUM_IDEN)
        AND ccc_cli_per_tid_codigo = DECODE(P_CLI_PER_TID_CODIGO,NULL,ccc_cli_per_tid_codigo,P_CLI_PER_TID_CODIGO)
        AND ccc_numero_cuenta = DECODE(P_NUMERO_CUENTA,NULL,ccc_numero_cuenta,P_NUMERO_CUENTA)
        AND NOT EXISTS(SELECT 'X'
                       FROM movimientos_cuenta_corredores
                       WHERE mcc_ccc_cli_per_num_iden   =ccc_cli_per_num_iden
                         AND mcc_ccc_cli_per_tid_codigo  = ccc_cli_per_tid_codigo     
                         AND mcc_ccc_numero_cuenta  = ccc_numero_cuenta
                         AND mcc_tmc_mnemonico = 'ASC'
                         AND TRUNC(MCC_FECHA) = TRUNC(P_FECHA_CANJE));

    CURSOR c_constante_canje IS
      SELECT con_valor
      FROM constantes
      WHERE con_mnemonico = 'DCC';      


    CURSOR c_dia_habil IS   
      SELECT count(*)
      FROM   dias_no_habiles
      WHERE  TRUNC(dnh_fecha) = TRUNC(SYSDATE);       

    v_mensaje_error  VARCHAR2(250);    
    v_monto_canje    NUMBER;
    v_cuenta_habil   NUMBER(1);
    v_fecha_mcc      DATE;
    c_cuentas        cuentas%ROWTYPE;
    v_dias_canje     constantes.con_valor%TYPE;
    v_error          EXCEPTION;
    v_fecha          DATE;
  BEGIN
    BEGIN
      OPEN c_dia_habil;
      FETCH c_dia_habil INTO v_cuenta_habil;
      CLOSE c_dia_habil;
      EXCEPTION WHEN OTHERS THEN  v_cuenta_habil := 0;
    END;

    IF nvl(v_cuenta_habil,0) > 0 OR TO_CHAR(p_fecha_canje,'D') IN (1,7) THEN
      v_dias_canje := 0;
    ELSE  
      v_dias_canje := 0;    
      OPEN c_constante_canje;
      FETCH c_constante_canje INTO v_dias_canje;
      IF c_constante_canje%NOTFOUND THEN
         v_mensaje_error := 'Constante dias de canje no existe en COEASY';
         RAISE v_error;
      END IF;
      CLOSE c_constante_canje;
      OPEN cuentas;
      FETCH cuentas INTO c_cuentas;
      WHILE cuentas%FOUND LOOP
        v_monto_canje := p_saldos_clientes.F_PRUEBAS_SALDO_CANJE(p_cli_per_num_iden   => c_cuentas.ccc_cli_per_num_iden,
                                                                 p_cli_per_tid_codigo => c_cuentas.ccc_cli_per_tid_codigo,
                                                                 p_numero_cuenta      => c_cuentas.ccc_numero_cuenta,
                                                                 p_dias_canje         => v_dias_canje,
                                                                 P_FECHA_CANJE        => P_FECHA_CANJE);
        v_monto_canje  := nvl(v_monto_canje,0);                                                   
        IF v_monto_canje > 0 THEN   
            SELECT SYSDATE INTO V_FECHA from dual;
            INSERT INTO movimientos_cuenta_corredores
               (mcc_consecutivo
               ,mcc_ccc_cli_per_num_iden        
               ,mcc_ccc_cli_per_tid_codigo      
               ,mcc_ccc_numero_cuenta           
               ,mcc_fecha
               ,mcc_tmc_mnemonico
               ,mcc_monto              
               ,mcc_monto_a_plazo      
               ,mcc_monto_a_contado    
               ,mcc_monto_admon_valores
               ,mcc_monto_canje)
            VALUES(
              mcc_seq.nextval
              ,c_cuentas.ccc_cli_per_num_iden
              ,c_cuentas.ccc_cli_per_tid_codigo
              ,c_cuentas.ccc_numero_cuenta
              ,V_FECHA--TO_DATE(TO_CHAR(P_FECHA_CANJE,'DD-MM-YYYY')||' 02:00:00','DD-MM-YYYY HH24:MI:SS')   
              ,'ASC'  --AFECTACION SALDOS EN CANJE CHEQUES    
              ,0
              ,0
              ,0
              ,0
              ,-v_monto_canje);
        END IF;
        FETCH cuentas INTO c_cuentas;
      END LOOP;
      CLOSE cuentas;
      COMMIT;
    END IF;
    EXCEPTION 
    WHEN v_error THEN
      RAISE_APPLICATION_ERROR(-20002,'Error :'||v_mensaje_error);
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,'Error ejecuntando P_SALDOS_CLIENTES '||SQLERRM);  
  END P_PRUEBA_SALDOS_CANJE;

PROCEDURE P_SALDOS_CARTERA(P_FECHA_PROCESO                  IN DATE
                          ,P_SALDO_A_FAVOR_CARTERA          IN OUT NUMBER
                          ,P_SALDO_EN_CONTRA_CARTERA        IN OUT NUMBER
                          ,P_ADMINISTRACION_VALORES         IN OUT NUMBER) AS
    CURSOR C_SALDOS (FECHA DATE) IS
      SELECT SUM(DECODE(SIGN(SDI_SALDO_CAPITAL+SDI_SALDO_BURSATIL),1,SDI_SALDO_CAPITAL+SDI_SALDO_BURSATIL,0)) SALDO_A_FAVOR_CARTERA
            ,SUM(DECODE(SIGN(SDI_SALDO_CAPITAL+SDI_SALDO_BURSATIL),-1,SDI_SALDO_CAPITAL+SDI_SALDO_BURSATIL,0)) SALDO_EN_CONTRA_CARTERA
            ,SUM(SDI_SALDO_ADMON_VALORES) ADMINISTRACION_VALORES
      FROM SALDOS_DIARIOS_CLIENTE
      WHERE SDI_FECHA_SALDO = TRUNC(FECHA);

    R_SALDOS C_SALDOS%ROWTYPE;
BEGIN   
  OPEN C_SALDOS(P_FECHA_PROCESO);
  FETCH C_SALDOS INTO R_SALDOS;
  IF C_SALDOS%NOTFOUND THEN
    P_SALDO_A_FAVOR_CARTERA   := 0;
    P_SALDO_EN_CONTRA_CARTERA := 0;
    P_ADMINISTRACION_VALORES  := 0;
  ELSE
    P_SALDO_A_FAVOR_CARTERA   := R_SALDOS.SALDO_A_FAVOR_CARTERA;
    P_SALDO_EN_CONTRA_CARTERA := R_SALDOS.SALDO_EN_CONTRA_CARTERA;
    P_ADMINISTRACION_VALORES  := R_SALDOS.ADMINISTRACION_VALORES;
  END IF;
  CLOSE C_SALDOS;
  EXCEPTION
    WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20110,'Error en P_SALDOS_CARTERA.P_SALDOS_CIETES '||SQLERRM);     
END P_SALDOS_CARTERA;
--------------------------------------------------------------------------------     
PROCEDURE PR_DISP_SALDOS_CLIENTE (P_CLI_PER_NUM_IDEN IN CLIENTES.CLI_PER_NUM_IDEN%TYPE,
                                  P_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE,
                                  io_cursor IN OUT O_CURSOR) AS

BEGIN
   OPEN io_cursor FOR
   SELECT MNEMONICO_DETALLE,
          BMO_MNEMONICO,
          TIPO_SALDO,
          DESCRIPCION,
          SUM(NOMINAL) NOMINAL,
          SUM(SALDO_PESOS) SALDO_PESOS
   FROM
         (SELECT 'CCC' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '1'   TIPO_SALDO,
                 'Saldo Ctas Corredores' DESCRIPCION,
                 CCC_SALDO_CAPITAL NOMINAL,
                 CCC_SALDO_CAPITAL SALDO_PESOS   
          FROM   CUENTAS_CLIENTE_CORREDORES
          WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL    
          SELECT 'CCC' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '2'   TIPO_SALDO,
                 'Saldo Ctas FIC''s' DESCRIPCION,
                 CCC_SALDO_CC NOMINAL,
                 CCC_SALDO_CC SALDO_PESOS  
          FROM   CUENTAS_CLIENTE_CORREDORES
          WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL       
          SELECT 'CCC' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '3'   TIPO_SALDO,
                 'Saldo Op. Burs¿til' DESCRIPCION,
                 CCC_SALDO_BURSATIL NOMINAL,
                 CCC_SALDO_BURSATIL SALDO_PESOS
          FROM   CUENTAS_CLIENTE_CORREDORES
          WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL       
          SELECT 'CCC' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '4'   TIPO_SALDO,
                 'Saldo Admon Valores' DESCRIPCION,
                 CCC_SALDO_ADMON_VALORES NOMINAL,     
                 CCC_SALDO_ADMON_VALORES SALDO_PESOS
          FROM   CUENTAS_CLIENTE_CORREDORES
          WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL
          SELECT 'DER' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '5'   TIPO_SALDO,
                 'Saldo Derivados' DESCRIPCION,
                 CDD_SALDO NOMINAL,
                 CDD_SALDO SALDO_PESOS
          FROM   CUENTAS_CLIENTES_DERIVADOS
          WHERE  CDD_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CDD_CCC_CLI_PER_TID_CODIGO =  P_CLI_PER_TID_CODIGO
          UNION ALL           
          SELECT 'SCM' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '6'   TIPO_SALDO,
                 'Saldo Monetizado' DESCRIPCION,
                 SCM_SALDO_MONETIZAR NOMINAL,
                 SCM_SALDO_MONETIZAR SALDO_PESOS
          FROM   SALDOS_CLIENTES_MONETIZAR
          WHERE  SCM_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    SCM_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL              
          SELECT 'CCOM' MNEMONICO_DETALLE,
                 CCOM_BMO_MNEMONICO BMO_MNEMONICO,
                 '7'   TIPO_SALDO,
                 'Saldo Otras Monedas' DESCRIPCION,
                 CCOM_SALDO NOMINAL,
                 CCOM_SALDO * CBM_VALOR * PMO_TASA_CONVERSION SALDO_PESOS
          FROM   CUENTAS_CLIENTES_OTRAS_MONEDAS,
                 POSICIONES_MONEDAS,
                 COTIZACIONES_BASE_MONETARIAS
          WHERE  CCOM_BMO_MNEMONICO = PMO_BMO_MNEMONICO
          AND    PMO_FECHA = (SELECT MAX(PMO_FECHA)
	                            FROM   POSICIONES_MONEDAS
	                            WHERE  PMO_BMO_MNEMONICO = CCOM_BMO_MNEMONICO
                              AND    PMO_FECHA >= TRUNC(SYSDATE - 3))
          AND    CBM_BMO_MNEMONICO = 'DOLAR'
	        AND    CBM_FECHA = (SELECT MAX(CBM_FECHA)
	                            FROM   COTIZACIONES_BASE_MONETARIAS
	                            WHERE  CBM_BMO_MNEMONICO = 'DOLAR'
                              AND    CBM_FECHA >= TRUNC(SYSDATE - 3))
          AND    CCOM_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCOM_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL
          SELECT 'DIV' MNEMONICO_DETALLE,
                       CDV_BMO_MNEMONICO BMO_MNEMONICO,
                       '7'   TIPO_SALDO,
                       'Saldo Otras Monedas' DESCRIPCION,
                       (CDV_SALDO_RESTRINGIDO + CDV_SALDO) NOMINAL,
                       (CDV_SALDO_RESTRINGIDO + CDV_SALDO) * CBM_VALOR SALDO_PESOS
          FROM   CUENTAS_CLIENTES_DIVISAS,
                 COTIZACIONES_BASE_MONETARIAS
          WHERE  CDV_BMO_MNEMONICO = CBM_BMO_MNEMONICO
          AND    CBM_FECHA = (SELECT MAX(CBM_FECHA)
                              FROM   COTIZACIONES_BASE_MONETARIAS
                              WHERE  CBM_BMO_MNEMONICO = 'DOLAR'
                              AND    CBM_FECHA >= TRUNC(SYSDATE - 3))
          AND    CDV_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CDV_CCC_CLI_PER_TID_CODIGO =  P_CLI_PER_TID_CODIGO) TMP
    GROUP BY MNEMONICO_DETALLE, BMO_MNEMONICO, TIPO_SALDO, DESCRIPCION
    ORDER BY DESCRIPCION;
END PR_DISP_SALDOS_CLIENTE;
--------------------------------------------------------------------------------  
PROCEDURE PR_NO_DISP_SALDOS_CLIENTE (P_CLI_PER_NUM_IDEN IN CLIENTES.CLI_PER_NUM_IDEN%TYPE,
                                  P_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE,
                                  io_cursor IN OUT O_CURSOR) AS

BEGIN
   OPEN io_cursor FOR
   SELECT MNEMONICO_DETALLE,
          BMO_MNEMONICO,
          TIPO_SALDO,
          DESCRIPCION,
          SUM(NOMINAL) NOMINAL,
          SUM(SALDO_PESOS) NOMINAL
   FROM
      (SELECT 'RECL' MNEMONICO_DETALLE,
              'COP' BMO_MNEMONICO,
              '1'   TIPO_SALDO,
              'Saldo en Remesas' DESCRIPCION,
              RECL_CCA_MONTO NOMINAL,
              RECL_CCA_MONTO SALDO_PESOS   
       FROM   VW_REMESAS_POR_LEGALIZAR
       WHERE  RECL_RCA_CCC_CLI_PER_NUM_IDEN =  P_CLI_PER_NUM_IDEN
       AND    RECL_RCA_CCC_CLI_PER_TID_COD  =  P_CLI_PER_TID_CODIGO
       UNION ALL    
       SELECT 'CCC' MNEMONICO_DETALLE,
              'COP' BMO_MNEMONICO,
              '2'   TIPO_SALDO,
              'Saldo Canje Corredores' DESCRIPCION,
              CCC_SALDO_CANJE NOMINAL,
              CCC_SALDO_CANJE SALDO_PESOS      
       FROM   CUENTAS_CLIENTE_CORREDORES
       WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       UNION ALL       
       SELECT 'CCC' MNEMONICO_DETALLE,
              'COP' BMO_MNEMONICO,
              '3'   TIPO_SALDO,
              'Saldo Canje FIC''s' DESCRIPCION,
              CCC_SALDO_CANJE_CC NOMINAL,
              CCC_SALDO_CANJE_CC SALDO_PESOS 
       FROM   CUENTAS_CLIENTE_CORREDORES
       WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       UNION ALL       
       SELECT 'GART' MNEMONICO_DETALLE,
              'COP' BMO_MNEMONICO,
              '4'   TIPO_SALDO,
              'Saldo Garant¿as' DESCRIPCION,
              VALOR_PESOS NOMINAL,     
              VALOR_PESOS SALDO_PESOS
       FROM   PROD.VW_WEB_GARANTIAS
       WHERE  CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND    CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       UNION ALL 
       SELECT 'RPF' MNEMONICO_DETALLE,
              'COP' BMO_MNEMONICO,
              '5'   TIPO_SALDO,
              'Saldo Ordenes Pendientes ' || FON_CODIGO DESCRIPCION,
              (SELECT ABS(MCF_UNIDADES_MOVIMIENTO)
               FROM   MOVIMIENTOS_CUENTAS_FONDOS
               WHERE  MCF_OFO_CONSECUTIVO = OFO_CONSECUTIVO
               AND    MCF_OFO_SUC_CODIGO = OFO_SUC_CODIGO
               AND    MCF_TMF_MNEMONICO = 'O') NOMINAL,              
              OFO_MONTO SALDO_PESOS
       FROM   ORDENES_FONDOS 
             ,FONDOS FONDOS 
       WHERE OFO_EOF_CODIGO IN ('APR','CON')
       AND   OFO_TTO_TOF_CODIGO IN ('RT','RP')
       AND   OFO_FECHA_EJECUCION < OFO_FECHA_CUMPLIMIENTO
       AND   OFO_FECHA_CUMPLIMIENTO >= TRUNC(SYSDATE - 100)
       AND   OFO_CFO_FON_CODIGO = FON_CODIGO
       AND   OFO_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND   OFO_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO) TMP
    group by MNEMONICO_DETALLE, BMO_MNEMONICO, TIPO_SALDO, DESCRIPCION
    ORDER BY DESCRIPCION;
END PR_NO_DISP_SALDOS_CLIENTE;
--------------------------------------------------------------------------------
PROCEDURE PR_OTROS_SALDOS_CLIENTE (P_CLI_PER_NUM_IDEN IN CLIENTES.CLI_PER_NUM_IDEN%TYPE,
                                  P_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE,
                                  io_cursor IN OUT O_CURSOR) AS

BEGIN
   OPEN io_cursor FOR
   SELECT MNEMONICO_DETALLE,
          BMO_MNEMONICO,
          TIPO_SALDO,
          DESCRIPCION,
          SUM(NOMINAL) NOMINAL,
          SUM(SALDO_PESOS) NOMINAL
   FROM
         (SELECT 'CFO' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '1'   TIPO_SALDO,
                 'Saldos Invertidos en FIC''s' DESCRIPCION,
                 CFO_SALDO_INVER NOMINAL,
                 CFO_SALDO_INVER SALDO_PESOS   
          FROM   CUENTAS_FONDOS
          WHERE  CFO_CCC_CLI_PER_NUM_IDEN =  P_CLI_PER_NUM_IDEN
          AND    CFO_CCC_CLI_PER_TID_CODIGO  =  P_CLI_PER_TID_CODIGO
          UNION ALL    
          SELECT 'CCC' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '2'   TIPO_SALDO,
                 'Saldo Op. De Contado pendientes por cumplir' DESCRIPCION,
                 CCC_SALDO_A_CONTADO NOMINAL,
                 CCC_SALDO_A_CONTADO SALDO_PESOS       
          FROM   CUENTAS_CLIENTE_CORREDORES
          WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          UNION ALL       
          SELECT 'CCC' MNEMONICO_DETALLE,
                 'COP' BMO_MNEMONICO,
                 '3'   TIPO_SALDO,
                 'Saldo Op. A Plazo pendientes por cumplir' DESCRIPCION,
                 CCC_SALDO_A_PLAZO NOMINAL,
                 CCC_SALDO_A_PLAZO SALDO_PESOS 
          FROM   CUENTAS_CLIENTE_CORREDORES
          WHERE  CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND    CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO) TMP
   GROUP BY MNEMONICO_DETALLE, BMO_MNEMONICO, TIPO_SALDO, DESCRIPCION
   ORDER BY DESCRIPCION;
END PR_OTROS_SALDOS_CLIENTE;
-------------------------------------------------------------------------------- 
FUNCTION  FN_SALDO_GARANTIA(P_CLI_PER_NUM_IDEN    VARCHAR2,
                             P_CLI_PER_TID_CODIGO   VARCHAR2,
                             P_NUMERO_CUENTA        NUMBER,
                             P_FECHA                DATE) RETURN NUMBER IS
    CURSOR C_SALDO_GARANTIA IS
       SELECT SUM(VALOR_ODP) - SUM(VALOR_RCA) SALDO_GARANTIAS 
		      	 FROM (SELECT NVL(CCA_MONTO,0) VALOR_RCA, 
					                    0 VALOR_ODP
					             FROM   RECIBOS_DE_CAJA, 
					                    CHEQUES_CAJA 
					             WHERE  RCA_SUC_CODIGO= CCA_RCA_SUC_CODIGO  
					             AND    RCA_NEG_CONSECUTIVO = CCA_RCA_NEG_CONSECUTIVO  
					             AND    RCA_CONSECUTIVO = CCA_RCA_CONSECUTIVO 
                       AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					             AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
					             AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA 
					             AND    RCA_ES_CLIENTE = 'S' 
					             AND    RCA_REVERSADO = 'N' 
					             AND    RCA_COT_MNEMONICO = 'RGCE' 
					             AND    RCA_FECHA > TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					             AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					             AND    CCA_MONTO != 0 
					             UNION ALL 
					            SELECT NVL(CCJ_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					            FROM   RECIBOS_DE_CAJA, 
					                   CONSIGNACIONES_CAJA 
					            WHERE  RCA_SUC_CODIGO= CCJ_RCA_SUC_CODIGO 
					            AND    RCA_NEG_CONSECUTIVO = CCJ_RCA_NEG_CONSECUTIVO 
					            AND    RCA_CONSECUTIVO = CCJ_RCA_CONSECUTIVO 
                      AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					            AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					            AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCE' 
					            AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    CCJ_MONTO != 0 
					             UNION ALL 
					            SELECT NVL(TRC_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					            FROM   RECIBOS_DE_CAJA, 
					                   TRANSFERENCIAS_CAJA 
					            WHERE  RCA_SUC_CODIGO= TRC_RCA_SUC_CODIGO 
					            AND    RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO 
					            AND    RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO 
                      AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					            AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					            AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCE' 
					            AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    TRC_MONTO != 0 
					             UNION ALL 
					            SELECT NVL(RCA_MONTO_EN_EFECTIVO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					            FROM   RECIBOS_DE_CAJA 
					            WHERE  RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
                      AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                      AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCE'  
					            AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY') 
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    RCA_MONTO_EN_EFECTIVO != 0 
					             UNION ALL 
					            SELECT 0 VALOR_RCA, 
					                   NVL(ODP_MONTO_ORDEN,0) VALOR_ODP 
					            FROM   ORDENES_DE_PAGO 
					            WHERE ODP_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN 
					            AND   ODP_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO 
					            AND   ODP_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                      AND   ODP_ESTADO = 'APR' 
					            AND   ODP_ES_CLIENTE = 'S' 
					            AND   ODP_COT_MNEMONICO = 'GOPCE' 
					            AND   ODP_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND   ODP_FECHA_EJECUCION <  TRUNC(P_FECHA + 1)
					            AND   ODP_MONTO_ORDEN != 0 
					             UNION ALL 
					            SELECT NVL(CCA_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					            FROM   RECIBOS_DE_CAJA, 
					                    CHEQUES_CAJA 
					            WHERE  RCA_SUC_CODIGO= CCA_RCA_SUC_CODIGO  
					            AND    RCA_NEG_CONSECUTIVO = CCA_RCA_NEG_CONSECUTIVO  
					            AND    RCA_CONSECUTIVO = CCA_RCA_CONSECUTIVO 
                      AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					            AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					            AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCF' 
					            AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    CCA_MONTO != 0 
					             UNION ALL 
					            SELECT NVL(CCJ_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP 
					            FROM   RECIBOS_DE_CAJA, 
					                   CONSIGNACIONES_CAJA 
					            WHERE  RCA_SUC_CODIGO= CCJ_RCA_SUC_CODIGO 
					            AND    RCA_NEG_CONSECUTIVO = CCJ_RCA_NEG_CONSECUTIVO 
					            AND    RCA_CONSECUTIVO = CCJ_RCA_CONSECUTIVO
                      AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					            AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					            AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCF' 
					            AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    CCJ_MONTO != 0 
					             UNION ALL 
					            SELECT NVL(TRC_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					            FROM   RECIBOS_DE_CAJA, 
					                   TRANSFERENCIAS_CAJA 
					            WHERE  RCA_SUC_CODIGO= TRC_RCA_SUC_CODIGO 
					            AND    RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO 
					            AND    RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
                      AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					            AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					            AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCF' 
					            AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    TRC_MONTO != 0 
					             UNION ALL 
					            SELECT NVL(RCA_MONTO_EN_EFECTIVO,0) VALOR_RCA, 
					                   0 VALOR_ODP 
					            FROM   RECIBOS_DE_CAJA 
					            WHERE  RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					            AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                      AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                      AND    RCA_ES_CLIENTE = 'S' 
					            AND    RCA_REVERSADO = 'N' 
					            AND    RCA_COT_MNEMONICO = 'RGCF'  
					            AND    RCA_FECHA > TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					            AND    RCA_MONTO_EN_EFECTIVO != 0 
					             UNION ALL 
					            SELECT 0 VALOR_RCA, 
					                   NVL(ODP_MONTO_ORDEN,0) VALOR_ODP 
					            FROM   ORDENES_DE_PAGO 
					            WHERE ODP_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN 
					            AND   ODP_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO 
					            AND   ODP_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                      AND   ODP_ESTADO = 'APR' 
					            AND   ODP_ES_CLIENTE = 'S' 
					            AND   ODP_COT_MNEMONICO = 'GOPCF' 
					            AND   ODP_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					            AND   ODP_FECHA_EJECUCION <  TRUNC(P_FECHA + 1)
					            AND   ODP_MONTO_ORDEN != 0 
					             UNION ALL 
					            SELECT NVL(CCA_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					            FROM   RECIBOS_DE_CAJA, 
					                   CHEQUES_CAJA 
					            WHERE    RCA_SUC_CODIGO= CCA_RCA_SUC_CODIGO  
					              AND    RCA_NEG_CONSECUTIVO = CCA_RCA_NEG_CONSECUTIVO 
					              AND    RCA_CONSECUTIVO = CCA_RCA_CONSECUTIVO 
                        AND    RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					              AND    RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
					              AND    RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					              AND    RCA_ES_CLIENTE = 'S' 
					              AND    RCA_REVERSADO = 'N' 
					              AND    RCA_COT_MNEMONICO = 'DGDE' 
					              AND    RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					              AND    RCA_FECHA <  TRUNC(P_FECHA + 1)
					              AND    CCA_MONTO != 0 
					              UNION ALL 
					             SELECT NVL(CCJ_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					             FROM   RECIBOS_DE_CAJA, 
					                    CONSIGNACIONES_CAJA  
					             WHERE  RCA_SUC_CODIGO= CCJ_RCA_SUC_CODIGO 
					               AND  RCA_NEG_CONSECUTIVO = CCJ_RCA_NEG_CONSECUTIVO 
					               AND  RCA_CONSECUTIVO = CCJ_RCA_CONSECUTIVO
                         AND  RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					               AND  RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
					               AND  RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					               AND  RCA_ES_CLIENTE = 'S'  
					               AND  RCA_REVERSADO = 'N' 
					               AND  RCA_COT_MNEMONICO = 'DGDE'  
					               AND  RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
			               		 AND  RCA_FECHA <  TRUNC(P_FECHA + 1)
					               AND  CCJ_MONTO != 0 
					              UNION ALL 
					             SELECT NVL(TRC_MONTO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					             FROM   RECIBOS_DE_CAJA, 
					                    TRANSFERENCIAS_CAJA 
					             WHERE  RCA_SUC_CODIGO= TRC_RCA_SUC_CODIGO 
					               AND  RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO 
					               AND  RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
                         AND  RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
					               AND  RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
					               AND  RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
					               AND  RCA_ES_CLIENTE = 'S' 
					               AND  RCA_REVERSADO = 'N' 
					               AND  RCA_COT_MNEMONICO = 'DGDE'  
					               AND  RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')              
					               AND  RCA_FECHA <  TRUNC(P_FECHA + 1)
					               AND  TRC_MONTO != 0 
					              UNION ALL 
					             SELECT NVL(RCA_MONTO_EN_EFECTIVO,0) VALOR_RCA, 
					                   0 VALOR_ODP
					               FROM   RECIBOS_DE_CAJA 
					               WHERE  RCA_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
                           AND  RCA_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                           AND  RCA_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                           AND  RCA_ES_CLIENTE = 'S' 
					                 AND  RCA_REVERSADO = 'N' 
					                 AND  RCA_COT_MNEMONICO = 'DGDE' 
					                 AND  RCA_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					                 AND  RCA_FECHA <  TRUNC(P_FECHA + 1)
					                 AND  RCA_MONTO_EN_EFECTIVO != 0 
					               UNION ALL 
					              SELECT 0 VALOR_RCA, 
					                   NVL(ODP_MONTO_ORDEN,0) VALOR_ODP
					               FROM   ORDENES_DE_PAGO 
					               WHERE ODP_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN 
                           AND ODP_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO 
                           AND ODP_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                           AND ODP_ESTADO = 'APR' 
					                 AND ODP_ES_CLIENTE = 'S' 
					                 AND ODP_COT_MNEMONICO = 'CGDE' 
					                 AND ODP_FECHA >  TO_DATE('01-08-2006' ,'DD-MM-YYYY')
					                 AND ODP_FECHA_EJECUCION <  TRUNC(P_FECHA + 1)
					                 AND (ODP_CEG_CONSECUTIVO IS NOT NULL 
					                   OR ODP_CGE_CONSECUTIVO IS NOT NULL 
					                   OR ODP_TBC_CONSECUTIVO IS NOT NULL 
					                   OR ODP_TCC_CONSECUTIVO IS NOT NULL)  
					                 AND ODP_MONTO_ORDEN != 0 
					             ) GAR;

    V_SALDO_GARANTIA NUMBER;
  BEGIN
    V_SALDO_GARANTIA := 0;
    OPEN C_SALDO_GARANTIA;
    FETCH C_SALDO_GARANTIA INTO V_SALDO_GARANTIA;
    CLOSE C_SALDO_GARANTIA;
    V_SALDO_GARANTIA := nvl(V_SALDO_GARANTIA,0);
    RETURN(V_SALDO_GARANTIA);    
  END FN_SALDO_GARANTIA;  
-------------------------------------------------------------------------------- 
END P_SALDOS_CLIENTES;

/

  GRANT EXECUTE ON "PROD"."P_SALDOS_CLIENTES" TO "COE_RECURSOS";
