--------------------------------------------------------
--  File created - Saturday-April-25-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_GARANTIAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_GARANTIAS" IS
 PROCEDURE p_valor_garantia_opce(p_fecha_proceso  IN DATE,
                            p_datos_garantia OUT v_datos_refcur) IS
 v_query VARCHAR2(32767);
 BEGIN
   open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                            ccc_cli_per_tid_codigo,
                            ccc_numero_cuenta,
                            ccc_nombre_cuenta,
                            NVL((SELECT SUM(cca_monto)
                             FROM   recibos_de_caja,
                                    cheques_caja
                             WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                               AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                               AND    rca_consecutivo = cca_rca_consecutivo
                               AND    rca_es_cliente = 'S'
                               AND    rca_reversado = 'N'
                               AND    rca_cot_mnemonico in ('RGCE')     
                               AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                               AND    rca_fecha < trunc(p_fecha_proceso + 1)
                               AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                               AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                               AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_cheques,
                             NVL((SELECT sum(ccj_monto) 
                              FROM   recibos_de_caja,
                                     consignaciones_caja
                              WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                AND  rca_consecutivo = ccj_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCE')     
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_consignaciones_caja,
                             NVL((SELECT sum(trc_monto) 
                              FROM   recibos_de_caja,
                                     transferencias_caja
                              WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                AND  rca_consecutivo = trc_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCE')  
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_transferencias_caja,
                             NVL((SELECT sum(rca_monto_en_efectivo)
                              FROM   recibos_de_caja
                              WHERE  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCE')     
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_caja,
                             -nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'GOPCE'
                                AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0) odp
                          FROM cuentas_cliente_corredores
                          WHERE (nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'GOPCE'
                                AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0)-                                
                            (NVL((SELECT SUM(cca_monto)
                             FROM   recibos_de_caja,
                                    cheques_caja
                             WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                               AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                               AND    rca_consecutivo = cca_rca_consecutivo
                               AND    rca_es_cliente = 'S'
                               AND    rca_reversado = 'N'
                               AND    rca_cot_mnemonico in ('RGCE')     
                               AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                               AND    rca_fecha < trunc(p_fecha_proceso + 1)
                               AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                               AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                               AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                             NVL((SELECT sum(ccj_monto) 
                              FROM   recibos_de_caja,
                                     consignaciones_caja
                              WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                AND  rca_consecutivo = ccj_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCE')     
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                             NVL((SELECT sum(trc_monto) 
                              FROM   recibos_de_caja,
                                     transferencias_caja
                              WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                AND  rca_consecutivo = trc_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCE')  
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                             NVL((SELECT sum(rca_monto_en_efectivo)
                              FROM   recibos_de_caja
                              WHERE  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCE')     
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0)
                                )) != 0
                           ORDER BY  ccc_cli_per_num_iden,
                            ccc_cli_per_tid_codigo,
                            ccc_numero_cuenta,
                            ccc_nombre_cuenta;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE;
        open p_datos_garantia for SELECT null,null,null,null,null,null,null,null,null FROM dual WHERE 1=0;
   END p_valor_garantia_opce;

  PROCEDURE p_valor_garantia_opcf(p_fecha_proceso   IN  DATE,
                                 p_datos_garantia  OUT v_datos_refcur1) IS
  BEGIN
    open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                            ccc_cli_per_tid_codigo,
                            ccc_numero_cuenta,
                            ccc_nombre_cuenta,
                            NVL((SELECT SUM(cca_monto)
                             FROM   recibos_de_caja,
                                    cheques_caja
                             WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                               AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                               AND    rca_consecutivo = cca_rca_consecutivo
                               AND    rca_es_cliente = 'S'
                               AND    rca_reversado = 'N'
                               AND    rca_cot_mnemonico in ('RGCF')     
                               AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                               AND    rca_fecha < trunc(p_fecha_proceso + 1)
                               AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                               AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                               AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_cheques,
                             NVL((SELECT sum(ccj_monto) 
                              FROM   recibos_de_caja,
                                     consignaciones_caja
                              WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                AND  rca_consecutivo = ccj_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCF') 
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_consignaciones_caja,
                             NVL((SELECT sum(trc_monto) 
                              FROM   recibos_de_caja,
                                     transferencias_caja
                              WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                AND  rca_consecutivo = trc_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCF')      
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_transferencias_caja,
                             NVL((SELECT sum(rca_monto_en_efectivo)
                              FROM   recibos_de_caja
                              WHERE  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCF')          
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_caja,
                             -nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'GOPCF'
                                AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0) odp
                          FROM cuentas_cliente_corredores
                          WHERE (nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'GOPCF'
                                AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0)-
                                (
                            NVL((SELECT SUM(cca_monto)
                             FROM   recibos_de_caja,
                                    cheques_caja
                             WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                               AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                               AND    rca_consecutivo = cca_rca_consecutivo
                               AND    rca_es_cliente = 'S'
                               AND    rca_reversado = 'N'
                               AND    rca_cot_mnemonico in ('RGCF')     
                               AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                               AND    rca_fecha < trunc(p_fecha_proceso + 1)
                               AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                               AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                               AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                             NVL((SELECT sum(ccj_monto) 
                              FROM   recibos_de_caja,
                                     consignaciones_caja
                              WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                AND  rca_consecutivo = ccj_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCF') 
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                             NVL((SELECT sum(trc_monto) 
                              FROM   recibos_de_caja,
                                     transferencias_caja
                              WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                AND  rca_consecutivo = trc_rca_consecutivo
                                AND  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCF')      
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                             NVL((SELECT sum(rca_monto_en_efectivo)
                              FROM   recibos_de_caja
                              WHERE  rca_es_cliente = 'S'
                                AND  rca_reversado = 'N'
                                AND  rca_cot_mnemonico in ('RGCF')          
                                AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) 
                                )) != 0
                           ORDER BY  ccc_cli_per_num_iden,
                            ccc_cli_per_tid_codigo,
                            ccc_numero_cuenta,
                            ccc_nombre_cuenta;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE;
        open p_datos_garantia for SELECT null,null,null,null,null,null,null,null,null FROM dual WHERE 1=0;
  END p_valor_garantia_opcf;

PROCEDURE P_VALOR_GARANTIA_DER(p_fecha_proceso   IN  DATE,
                               p_datos_garantia  OUT v_datos_refcur2,
                               p_llamado         IN VARCHAR2 DEFAULT NULL,
                               P_TX              IN NUMBER DEFAULT NULL) IS

    V_VALOR_CHAR     VARCHAR2(200);
    V_VALOR          NUMBER;
    V_VALOR_DATE     DATE;
    V_FECHA_ORDEN    DATE;

    N_ID_PROCESO NUMBER;
    N_TX NUMBER;

BEGIN

 --se asigna el consecutivo del proceso(tabla PARAMETRIZACION_PROCESOS)
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_GARANTIAS.P_VALOR_GARANTIA_DER');

    --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio proceso P_GARANTIAS.P_VALOR_GARANTIA_DER. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
	IF P_LLAMADO IS NULL THEN
    BEGIN
      open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              ccc_numero_cuenta,
                              ccc_nombre_cuenta,
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGDE')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_cheques,
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_consignaciones_caja,
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_transferencias_caja,
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_caja,
                               -nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGDE'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0) odp
                            FROM cuentas_cliente_corredores
                            WHERE (nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGDE'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0)-
                                  (
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGDE')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) 
                                  )) != 0
                             ORDER BY  ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              ccc_numero_cuenta,
                              ccc_nombre_cuenta;  
       EXCEPTION
          WHEN OTHERS THEN
            RAISE;
            open p_datos_garantia for SELECT null,null,null,null,null,null,null,null,null FROM dual WHERE 1=0;                               
    END;
   ELSE
     P_TOOLS.CONSULTARCONSTANTE(
       P_CONSTANTE  => 'HCD',  
       P_VALOR      => V_VALOR,
       P_VALOR_DATE => V_VALOR_DATE,
       P_VALOR_CHAR => V_VALOR_CHAR
      );
      V_FECHA_ORDEN := p_fecha_proceso;

      V_FECHA_ORDEN := P_TOOLS.RESTAR_HABILES_A_FECHA(P_FECHA => V_FECHA_ORDEN,
                                                      P_DIAS  => 1);

      V_FECHA_ORDEN :=  TO_DATE(TO_CHAR(V_FECHA_ORDEN,'YYYY-MM-DD')||' '||V_VALOR_CHAR,'YYYY-MM-DD HH24:MI:SS');

      open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              ccc_numero_cuenta,
                              ccc_nombre_cuenta,
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGDE')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_cheques,
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_consignaciones_caja,
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_transferencias_caja,
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_caja,
                               -nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGDE'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < V_FECHA_ORDEN
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0) odp
                            FROM cuentas_cliente_corredores
                            WHERE  (nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGDE'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < V_FECHA_ORDEN    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0)-
                                  (
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGDE')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGDE')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1) 
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) 
                                  )) != 0
                             ;


   END IF;        

 -- Registrar traza FIN
  P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                'F',
                                'Fin P_GARANTIAS.P_VALOR_GARANTIA_DER. Fecha Proceso: ' ||
                                TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                N_TX);
	COMMIT;

END P_VALOR_GARANTIA_DER;                              


PROCEDURE P_VALOR_GARANTIA_CRCC(P_FECHA_PROCESO   IN  DATE,
                               p_datos_garantia  OUT v_datos_refcur5,
                               p_llamado         IN VARCHAR2 DEFAULT NULL) IS
    V_VALOR_CHAR     VARCHAR2(200);
    V_VALOR          NUMBER;
    V_VALOR_DATE     DATE;
    V_FECHA_ORDEN    DATE;
BEGIN
   IF P_LLAMADO IS NULL THEN
   BEGIN
      open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              CCC_NUMERO_CUENTA,
                              CCC_NOMBRE_CUENTA,
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGRCR')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)  
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_cheques,
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_consignaciones_caja,
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)  
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_transferencias_caja,
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)     
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                                  AND  RCA_CCC_NUMERO_CUENTA  = CCC_NUMERO_CUENTA),0) RC_CAJA    ,                          
                               -nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGRCR'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0) odp
                            FROM cuentas_cliente_corredores
                            WHERE (nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGRCR'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0)-
                                  (
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGRCR')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) 
                                  )) != 0
                             ORDER BY  ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              ccc_numero_cuenta,
                              ccc_nombre_cuenta;  
    EXCEPTION
          WHEN OTHERS THEN
            RAISE;
            open p_datos_garantia for SELECT null,null,null,null,null,null,null,null,null FROM dual WHERE 1=0;  
    END;        
   ELSE
     P_TOOLS.CONSULTARCONSTANTE(
       P_CONSTANTE  => 'HCD',  
       P_VALOR      => V_VALOR,
       P_VALOR_DATE => V_VALOR_DATE,
       P_VALOR_CHAR => V_VALOR_CHAR
      );
      V_FECHA_ORDEN := p_fecha_proceso;

      V_FECHA_ORDEN := P_TOOLS.RESTAR_HABILES_A_FECHA(P_FECHA => V_FECHA_ORDEN,
                                                      P_DIAS  => 1);

      V_FECHA_ORDEN :=  TO_DATE(TO_CHAR(V_FECHA_ORDEN,'YYYY-MM-DD')||' '||V_VALOR_CHAR,'YYYY-MM-DD HH24:MI:SS');

      open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              CCC_NUMERO_CUENTA,
                              CCC_NOMBRE_CUENTA,
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGRCR')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)  
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_cheques,
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)     
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_consignaciones_caja,
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)  
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) rc_transferencias_caja,
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)     
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  RCA_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
                                  AND  RCA_CCC_NUMERO_CUENTA  = CCC_NUMERO_CUENTA),0) RC_CAJA,
                               -nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGRCR'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < V_FECHA_ORDEN
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0) odp
                            FROM cuentas_cliente_corredores
                            WHERE  (nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGRCR'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < V_FECHA_ORDEN    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0)-
                                  (
                              NVL((SELECT SUM(cca_monto)
                               FROM   recibos_de_caja,
                                      cheques_caja
                               WHERE    rca_suc_codigo= cca_rca_suc_codigo 
                                 AND    rca_neg_consecutivo = cca_rca_neg_consecutivo 
                                 AND    rca_consecutivo = cca_rca_consecutivo
                                 AND    rca_es_cliente = 'S'
                                 AND    rca_reversado = 'N'
                                 AND    rca_cot_mnemonico in ('DGRCR')     
                                 AND    rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')       
                                 AND    rca_fecha < trunc(p_fecha_proceso + 1)
                                 AND    rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                 AND    rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                 AND    rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(ccj_monto) 
                                FROM   recibos_de_caja,
                                       consignaciones_caja
                                WHERE  rca_suc_codigo= ccj_rca_suc_codigo
                                  AND  rca_neg_consecutivo = ccj_rca_neg_consecutivo
                                  AND  rca_consecutivo = ccj_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR') 
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)    
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(trc_monto) 
                                FROM   recibos_de_caja,
                                       transferencias_caja
                                WHERE  rca_suc_codigo= trc_rca_suc_codigo
                                  AND  rca_neg_consecutivo = trc_rca_neg_consecutivo
                                  AND  rca_consecutivo = trc_rca_consecutivo
                                  AND  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')      
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')                
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1)
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) +
                               NVL((SELECT sum(rca_monto_en_efectivo)
                                FROM   recibos_de_caja
                                WHERE  rca_es_cliente = 'S'
                                  AND  rca_reversado = 'N'
                                  AND  rca_cot_mnemonico in ('DGRCR')          
                                  AND  rca_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND  rca_fecha < trunc(p_fecha_proceso + 1) 
                                  AND  rca_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND  rca_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND  rca_ccc_numero_cuenta  = ccc_numero_cuenta),0) 
                                  )) != 0
                             ;

   END IF;                                                   
END P_VALOR_GARANTIA_CRCC;                              



PROCEDURE PR_GARANTIAS_DER_SCB(P_FECHA_PROCESO   IN  DATE,
                               P_DATOS_GARANTIA  OUT v_datos_refcur3,
                               P_LLAMADO         IN VARCHAR2 DEFAULT NULL,
                               P_TX              IN NUMBER DEFAULT NULL) IS
    V_VALOR_CHAR     VARCHAR2(200);
    V_VALOR          NUMBER;
    V_VALOR_DATE     DATE;
    V_FECHA_ORDEN    DATE;
    N_ID_PROCESO NUMBER;
    N_TX NUMBER;
BEGIN
  --se asigna el consecutivo del proceso(tabla PARAMETRIZACION_PROCESOS)
  N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_GARANTIAS.PR_GARANTIAS_DER_SCB');

  --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
  N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

  --Registra Traza
  P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                  'I',
                                  'Inicio proceso P_GARANTIAS.PR_GARANTIAS_DER_SCB. Fecha Proceso: ' ||
                                  TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                  N_TX);
   IF P_LLAMADO IS NULL THEN
      BEGIN
      open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                            ccc_cli_per_tid_codigo,
                            ccc_numero_cuenta,
                            CCC_NOMBRE_CUENTA,
                            0 rc_cheques,
                            0 rc_consignaciones_caja,
                            0 rc_transferencias_caja,
                            0 rc_caja,
                             nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'DPGD'
                                AND odp_fecha > TO_DATE('01-04-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND ODP_CCC_CLI_PER_NUM_IDEN_TRANS = ccc_cli_per_num_iden
                                AND ODP_CCC_CLI_PER_TID_CODIGO_TRA = ccc_cli_per_tid_codigo
                                AND ODP_CCC_NUMERO_CUENTA_TRANSFIE  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0) odp_scb,
                             -nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'CGDS'
                                AND odp_fecha > TO_DATE('01-04-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0) odp
                          FROM cuentas_cliente_corredores
                          WHERE (nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'CGDS'
                                AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0)-
                                nvl((SELECT sum(odp_monto_orden) 
                              FROM   ordenes_de_pago
                              WHERE odp_estado = 'APR'
                                AND odp_es_cliente = 'S'
                                AND odp_cot_mnemonico = 'DPGD'
                                AND odp_fecha > TO_DATE('01-04-2006','DD-MM-YYYY')  
                                AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)    
                                AND ODP_CCC_CLI_PER_NUM_IDEN_TRANS = ccc_cli_per_num_iden
                                AND ODP_CCC_CLI_PER_TID_CODIGO_TRA = ccc_cli_per_tid_codigo
                                AND ODP_CCC_NUMERO_CUENTA_TRANSFIE  = ccc_numero_cuenta
                                AND (odp_ceg_consecutivo is not null
                                 OR odp_cge_consecutivo is not null
                                 OR odp_tbc_consecutivo is not null
                                 OR odp_tcc_consecutivo is not null)),0)) != 0
                           ORDER BY  ccc_cli_per_num_iden,
                            ccc_cli_per_tid_codigo,
                            ccc_numero_cuenta,
                            ccc_nombre_cuenta;
      EXCEPTION
          WHEN OTHERS THEN
            RAISE;
            open p_datos_garantia for SELECT null,null,null,null,null,null,null,null,null,null FROM dual WHERE 1=0;                                
     END; 
   ELSE
      P_TOOLS.CONSULTARCONSTANTE(
       P_CONSTANTE  => 'HCD',  
       P_VALOR      => V_VALOR,
       P_VALOR_DATE => V_VALOR_DATE,
       P_VALOR_CHAR => V_VALOR_CHAR
      );
      V_FECHA_ORDEN := p_fecha_proceso;

      V_FECHA_ORDEN := P_TOOLS.RESTAR_HABILES_A_FECHA(P_FECHA => V_FECHA_ORDEN,
                                                      P_DIAS  => 1);

      V_FECHA_ORDEN :=  TO_DATE(TO_CHAR(V_FECHA_ORDEN,'YYYY-MM-DD')||' '||V_VALOR_CHAR,'YYYY-MM-DD HH24:MI:SS');


      open p_datos_garantia FOR SELECT ccc_cli_per_num_iden,
                              ccc_cli_per_tid_codigo,
                              ccc_numero_cuenta,
                              ccc_nombre_cuenta,
                              0 rc_cheques,
                              0 rc_consignaciones_caja,
                              0 rc_transferencias_caja,
                              0 rc_caja,
                               nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'DPGD'
                                  AND odp_fecha > TO_DATE('01-04-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)   
                                  AND ODP_CCC_CLI_PER_NUM_IDEN_TRANS = ccc_cli_per_num_iden
                                  AND ODP_CCC_CLI_PER_TID_CODIGO_TRA = ccc_cli_per_tid_codigo
                                  AND ODP_CCC_NUMERO_CUENTA_TRANSFIE  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0) odp_scb,
                               -nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGDS'
                                  AND odp_fecha > TO_DATE('01-04-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < V_FECHA_ORDEN   
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0) odp
                            FROM cuentas_cliente_corredores
                            WHERE (nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'CGDS'
                                  AND odp_fecha > TO_DATE('01-08-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < V_FECHA_ORDEN    
                                  AND odp_ccc_cli_per_num_iden = ccc_cli_per_num_iden
                                  AND odp_ccc_cli_per_tid_codigo = ccc_cli_per_tid_codigo
                                  AND odp_ccc_numero_cuenta  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0)-
                                  nvl((SELECT sum(odp_monto_orden) 
                                FROM   ordenes_de_pago
                                WHERE odp_estado = 'APR'
                                  AND odp_es_cliente = 'S'
                                  AND odp_cot_mnemonico = 'DPGD'
                                  AND odp_fecha > TO_DATE('01-04-2006','DD-MM-YYYY')  
                                  AND odp_fecha_ejecucion < trunc(p_fecha_proceso + 1)   
                                  AND ODP_CCC_CLI_PER_NUM_IDEN_TRANS = ccc_cli_per_num_iden
                                  AND ODP_CCC_CLI_PER_TID_CODIGO_TRA = ccc_cli_per_tid_codigo
                                  AND ODP_CCC_NUMERO_CUENTA_TRANSFIE  = ccc_numero_cuenta
                                  AND (odp_ceg_consecutivo is not null
                                   OR odp_cge_consecutivo is not null
                                   OR odp_tbc_consecutivo is not null
                                   OR odp_tcc_consecutivo is not null)),0)) != 0
                             ;
   END IF;      
    --Registra Traza
   P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                  'F',
                                  'Fin proceso P_GARANTIAS.PR_GARANTIAS_DER_SCB. Fecha Proceso: ' ||
                                  TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                  N_TX);

END PR_GARANTIAS_DER_SCB;

PROCEDURE PR_CLIENTE_GAR_DERIVADOS(P_FECHA_PROCESO IN DATE) IS

  P_DATOS_GARANTIA     v_datos_refcur2;
  P_DATOS_GARANTIA_SCB V_DATOS_REFCUR3;
  P_DATOS_GARANTIA_CRCC V_DATOS_REFCUR5;


  V_UTILIDAD_EFECTIVO      UTILIDADES_GARANTIAS_EFECTIVO%ROWTYPE;
  V_UTILIDAD_EFECTIVO_SCB  UTILIDADES_GARANTIAS_EFECTIVO%ROWTYPE;
  V_VALIDA_PROCESO         NUMBER(5);

BEGIN
   P_DATOS_GARANTIA        := NULL;
   P_DATOS_GARANTIA_SCB    := NULL;
   P_DATOS_GARANTIA_CRCC    := NULL;

   V_UTILIDAD_EFECTIVO     := NULL;
   V_UTILIDAD_EFECTIVO_SCB := NULL;
   V_VALIDA_PROCESO        := 0;


   BEGIN
     SELECT COUNT(*) INTO V_VALIDA_PROCESO
     FROM UTILIDADES_GARANTIAS_EFECTIVO
     WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
     AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
     AND UTGE_ESTADO = 'APR';
   END;
   V_VALIDA_PROCESO := NVL(V_VALIDA_PROCESO,0);



   IF  V_VALIDA_PROCESO = 0  THEN
      DELETE UTILIDADES_GARANTIAS_EFECTIVO
      WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
        AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
        AND UTGE_ESTADO IN ( 'COL','PRO');

      --UTILIDADES_GARANTIAS_EFECTIVO
      --UTGE_ESTADO IN ('COL', 'PRO', 'APR');
      P_GARANTIAS.P_VALOR_GARANTIA_DER(P_FECHA_PROCESO  => P_FECHA_PROCESO,
                                       P_DATOS_GARANTIA => P_DATOS_GARANTIA,
                                       P_LLAMADO        => 'P');

      LOOP
         FETCH P_DATOS_GARANTIA INTO  V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_NUM_IDEN
                                     ,V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_TID_CODIGO
                                     ,V_UTILIDAD_EFECTIVO.UTGE_CCC_NUMERO_CUENTA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_NOMBRE_CUENTA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CHEQUES
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CONSIG_CAJA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_TRANSF_CAJA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_RECIBOS_CAJA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_ORDENES_PAGO;


         EXIT WHEN P_DATOS_GARANTIA%NOTFOUND;
         INSERT INTO UTILIDADES_GARANTIAS_EFECTIVO
          (UTGE_SECUENCIA
          ,UTGE_ESTADO
          ,UTGE_CCC_CLI_PER_NUM_IDEN
          ,UTGE_CCC_CLI_PER_TID_CODIGO
          ,UTGE_CCC_NUMERO_CUENTA
          ,UTGE_NOMBRE_CUENTA
          ,UTGE_VALOR_UTILIDAD
          ,UTGE_VALOR_CHEQUES
          ,UTGE_VALOR_CONSIG_CAJA
          ,UTGE_VALOR_RECIBOS_CAJA
          ,UTGE_VALOR_TRANSF_CAJA
          ,UTGE_VALOR_ORDENES_PAGO_SCB
          ,UTGE_VALOR_ORDENES_PAGO
          ,UTGE_FECHA
          ,UTGE_GARANTIA_SCB
          ,UTGE_FECHA_GEN_PRORRATEO 
          ,UTGE_USUARIO_GEN_PRORRATEO 
          ,UTGE_FECHA_CON_PRORRATEO 
          ,UTGE_USUARIO_CON_PRORRATEO 
          )
          VALUES
          (
           UTGE_SEQ.NEXTVAL                                --UTGE_SECUENCIA
          ,'COL'                                           --UTGE_ESTADO
          ,V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_NUM_IDEN   --UTGE_CCC_CLI_PER_NUM_IDEN
          ,V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_TID_CODIGO --UTGE_CCC_CLI_PER_TID_CODIGO
          ,V_UTILIDAD_EFECTIVO.UTGE_CCC_NUMERO_CUENTA      --UTGE_CCC_NUMERO_CUENTA
          ,V_UTILIDAD_EFECTIVO.UTGE_NOMBRE_CUENTA          --UTGE_NOMBRE_CUENTA
          ,0                                               --UTGE_VALOR_UTILIDAD
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CHEQUES          --UTGE_VALOR_CHEQUES
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CONSIG_CAJA      --UTGE_VALOR_CONSIG_CAJA
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_RECIBOS_CAJA     --UTGE_VALOR_RECIBOS_CAJA
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_TRANSF_CAJA      --UTGE_VALOR_TRANSF_CAJA
          ,0                                               --UTGE_VALOR_ORDENES_PAGO_SCB
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_ORDENES_PAGO     --UTGE_VALOR_ORDENES_PAGO
          ,SYSDATE                                         --UTGE_FECHA
          ,'N'                                             --UTGE_GARANTIA_SCB
          ,NULL                                            --UTGE_FECHA_GEN_PRORRATEO 
          ,NULL                                            --UTGE_USUARIO_GEN_PRORRATEO 
          ,NULL                                            --UTGE_FECHA_CON_PRORRATEO 
          ,NULL                                            --UTGE_USUARIO_CON_PRORRATEO 
          );       
      END LOOP;
      CLOSE P_DATOS_GARANTIA; 




      P_GARANTIAS.P_VALOR_GARANTIA_CRCC(P_FECHA_PROCESO  => P_FECHA_PROCESO,
                                       P_DATOS_GARANTIA => P_DATOS_GARANTIA_CRCC,
                                       P_LLAMADO        => 'P');

      LOOP
         FETCH P_DATOS_GARANTIA_CRCC INTO  V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_NUM_IDEN
                                     ,V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_TID_CODIGO
                                     ,V_UTILIDAD_EFECTIVO.UTGE_CCC_NUMERO_CUENTA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_NOMBRE_CUENTA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CHEQUES
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CONSIG_CAJA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_TRANSF_CAJA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_RECIBOS_CAJA
                                     ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_ORDENES_PAGO;


         EXIT WHEN P_DATOS_GARANTIA_CRCC%NOTFOUND;
         INSERT INTO UTILIDADES_GARANTIAS_EFECTIVO
          (UTGE_SECUENCIA
          ,UTGE_ESTADO
          ,UTGE_CCC_CLI_PER_NUM_IDEN
          ,UTGE_CCC_CLI_PER_TID_CODIGO
          ,UTGE_CCC_NUMERO_CUENTA
          ,UTGE_NOMBRE_CUENTA
          ,UTGE_VALOR_UTILIDAD
          ,UTGE_VALOR_CHEQUES
          ,UTGE_VALOR_CONSIG_CAJA
          ,UTGE_VALOR_RECIBOS_CAJA
          ,UTGE_VALOR_TRANSF_CAJA
          ,UTGE_VALOR_ORDENES_PAGO_SCB
          ,UTGE_VALOR_ORDENES_PAGO
          ,UTGE_FECHA
          ,UTGE_GARANTIA_SCB
          ,UTGE_GARANTIA_CRCC
          ,UTGE_FECHA_GEN_PRORRATEO 
          ,UTGE_USUARIO_GEN_PRORRATEO 
          ,UTGE_FECHA_CON_PRORRATEO 
          ,UTGE_USUARIO_CON_PRORRATEO 
          )
          VALUES
          (
           UTGE_SEQ.NEXTVAL                                --UTGE_SECUENCIA
          ,'COL'                                           --UTGE_ESTADO
          ,V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_NUM_IDEN   --UTGE_CCC_CLI_PER_NUM_IDEN
          ,V_UTILIDAD_EFECTIVO.UTGE_CCC_CLI_PER_TID_CODIGO --UTGE_CCC_CLI_PER_TID_CODIGO
          ,V_UTILIDAD_EFECTIVO.UTGE_CCC_NUMERO_CUENTA      --UTGE_CCC_NUMERO_CUENTA
          ,V_UTILIDAD_EFECTIVO.UTGE_NOMBRE_CUENTA          --UTGE_NOMBRE_CUENTA
          ,0                                               --UTGE_VALOR_UTILIDAD
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CHEQUES          --UTGE_VALOR_CHEQUES
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_CONSIG_CAJA      --UTGE_VALOR_CONSIG_CAJA
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_RECIBOS_CAJA     --UTGE_VALOR_RECIBOS_CAJA
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_TRANSF_CAJA      --UTGE_VALOR_TRANSF_CAJA
          ,0                                               --UTGE_VALOR_ORDENES_PAGO_SCB
          ,V_UTILIDAD_EFECTIVO.UTGE_VALOR_ORDENES_PAGO     --UTGE_VALOR_ORDENES_PAGO
          ,SYSDATE                                         --UTGE_FECHA
          ,'N'                                             --UTGE_GARANTIA_SCB
          ,'S'                                             --UTGE_GARANTIA_CRCC
          ,NULL                                            --UTGE_FECHA_GEN_PRORRATEO 
          ,NULL                                            --UTGE_USUARIO_GEN_PRORRATEO 
          ,NULL                                            --UTGE_FECHA_CON_PRORRATEO 
          ,NULL                                            --UTGE_USUARIO_CON_PRORRATEO 
          );    
      END LOOP;
      CLOSE P_DATOS_GARANTIA_CRCC; 




      P_GARANTIAS.PR_GARANTIAS_DER_SCB(P_FECHA_PROCESO  => P_FECHA_PROCESO,
                                       P_DATOS_GARANTIA => P_DATOS_GARANTIA_SCB,
                                       P_LLAMADO        => 'P');                                   


      LOOP
         FETCH P_DATOS_GARANTIA_SCB INTO V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_NUM_IDEN
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_TID_CODIGO
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_NUMERO_CUENTA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_NOMBRE_CUENTA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CHEQUES
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CONSIG_CAJA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_TRANSF_CAJA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_RECIBOS_CAJA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO_SCB
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO;


         EXIT WHEN P_DATOS_GARANTIA_SCB%NOTFOUND;
         INSERT INTO UTILIDADES_GARANTIAS_EFECTIVO
          (UTGE_SECUENCIA
          ,UTGE_ESTADO
          ,UTGE_CCC_CLI_PER_NUM_IDEN
          ,UTGE_CCC_CLI_PER_TID_CODIGO
          ,UTGE_CCC_NUMERO_CUENTA
          ,UTGE_NOMBRE_CUENTA
          ,UTGE_VALOR_UTILIDAD
          ,UTGE_VALOR_CHEQUES
          ,UTGE_VALOR_CONSIG_CAJA
          ,UTGE_VALOR_RECIBOS_CAJA
          ,UTGE_VALOR_TRANSF_CAJA
          ,UTGE_VALOR_ORDENES_PAGO_SCB
          ,UTGE_VALOR_ORDENES_PAGO
          ,UTGE_FECHA
          ,UTGE_GARANTIA_SCB
          ,UTGE_FECHA_GEN_PRORRATEO 
          ,UTGE_USUARIO_GEN_PRORRATEO 
          ,UTGE_FECHA_CON_PRORRATEO 
          ,UTGE_USUARIO_CON_PRORRATEO 
          )
          VALUES
          (
           UTGE_SEQ.NEXTVAL                                    --UTGE_SECUENCIA
          ,'COL'                                               --UTGE_ESTADO
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_NUM_IDEN   --UTGE_CCC_CLI_PER_NUM_IDEN
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_TID_CODIGO --UTGE_CCC_CLI_PER_TID_CODIGO
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_NUMERO_CUENTA      --UTGE_CCC_NUMERO_CUENTA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_NOMBRE_CUENTA          --UTGE_NOMBRE_CUENTA
          ,0                                                   --UTGE_VALOR_UTILIDAD
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CHEQUES          --UTGE_VALOR_CHEQUES
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CONSIG_CAJA      --UTGE_VALOR_CONSIG_CAJA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_RECIBOS_CAJA     --UTGE_VALOR_RECIBOS_CAJA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_TRANSF_CAJA      --UTGE_VALOR_TRANSF_CAJA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO_SCB  --UTGE_VALOR_ORDENES_PAGO_SCB
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO     --UTGE_VALOR_ORDENES_PAGO
          ,SYSDATE                                             --UTGE_FECHA
          ,'S'                                                 --UTGE_GARANTIA_SCB
          ,NULL                                                --UTGE_FECHA_GEN_PRORRATEO 
          ,NULL                                                --UTGE_USUARIO_GEN_PRORRATEO 
          ,NULL                                                --UTGE_FECHA_CON_PRORRATEO 
          ,NULL                                                --UTGE_USUARIO_CON_PRORRATEO 
          );       
      END LOOP;
      CLOSE P_DATOS_GARANTIA_SCB;    
   ELSE
     RAISE_APPLICATION_ERROR(-20001, 'Para la fecha ya existe proceso de Prorrateo Aprobado');
   END IF;
   COMMIT;

   EXCEPTION WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20002, 'Error en PR_CLIENTE_GAR_DERIVADOS :'||SQLERRM);  
END PR_CLIENTE_GAR_DERIVADOS;

PROCEDURE PR_PRORRATEO_GAR_DERIVADOS( P_FECHA_PROCESO IN DATE
                                    ,P_VALOR_RENDIMIENTOS IN NUMBER) IS
   CURSOR C1 IS 
     SELECT UTGE_SECUENCIA
       ,UTGE_ESTADO
       ,UTGE_CCC_CLI_PER_NUM_IDEN
       ,UTGE_CCC_CLI_PER_TID_CODIGO
       ,UTGE_CCC_NUMERO_CUENTA
       ,UTGE_NOMBRE_CUENTA
       ,UTGE_VALOR_UTILIDAD
       ,UTGE_VALOR_CHEQUES
       ,UTGE_VALOR_CONSIG_CAJA
       ,UTGE_VALOR_RECIBOS_CAJA
       ,UTGE_VALOR_TRANSF_CAJA
       ,UTGE_VALOR_ORDENES_PAGO_SCB
       ,UTGE_VALOR_ORDENES_PAGO
       ,UTGE_FECHA
       ,UTGE_GARANTIA_SCB
       ,UTGE_FECHA_GEN_PRORRATEO 
       ,UTGE_USUARIO_GEN_PRORRATEO 
       ,UTGE_FECHA_CON_PRORRATEO 
       ,UTGE_USUARIO_CON_PRORRATEO 
    FROM UTILIDADES_GARANTIAS_EFECTIVO
    WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
      AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
      AND UTGE_ESTADO = 'COL';

   C_C1 C1%ROWTYPE;      

   V_SALDO_GARANTIA  UTILIDADES_GARANTIAS_EFECTIVO.UTGE_VALOR_UTILIDAD%TYPE;
   V_UTILIDAD        UTILIDADES_GARANTIAS_EFECTIVO.UTGE_VALOR_UTILIDAD%TYPE;
   V_TOTAL_GARANTIAS UTILIDADES_GARANTIAS_EFECTIVO.UTGE_VALOR_UTILIDAD%TYPE;
   V_TOTAL_UTILIDAD  UTILIDADES_GARANTIAS_EFECTIVO.UTGE_VALOR_UTILIDAD%TYPE;
   V_VALIDA_PROCESO  NUMBER(5);

BEGIN

   V_VALIDA_PROCESO        := 0;


   BEGIN
     SELECT COUNT(*) INTO V_VALIDA_PROCESO
     FROM UTILIDADES_GARANTIAS_EFECTIVO
     WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
     AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
     AND UTGE_ESTADO = 'APR';
   END;
   V_VALIDA_PROCESO := NVL(V_VALIDA_PROCESO,0);



   IF  V_VALIDA_PROCESO = 0  THEN
      BEGIN
        V_TOTAL_GARANTIAS := 0;
        SELECT SUM (  UTGE_VALOR_ORDENES_PAGO+(UTGE_VALOR_CHEQUES+
                                               UTGE_VALOR_CONSIG_CAJA+
                                               UTGE_VALOR_RECIBOS_CAJA+
                                               UTGE_VALOR_TRANSF_CAJA+
                                               UTGE_VALOR_ORDENES_PAGO_SCB))
        INTO V_TOTAL_GARANTIAS
        FROM UTILIDADES_GARANTIAS_EFECTIVO
        WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
          AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
          AND UTGE_ESTADO = 'COL';

        V_TOTAL_GARANTIAS := ABS(V_TOTAL_GARANTIAS);  
      END;

      OPEN C1;
      FETCH C1 INTO C_C1;
      WHILE C1%FOUND LOOP
         V_SALDO_GARANTIA := 0;
         V_UTILIDAD := 0;
         V_SALDO_GARANTIA := C_C1.UTGE_VALOR_ORDENES_PAGO+(C_C1.UTGE_VALOR_CHEQUES+
                                                           C_C1.UTGE_VALOR_CONSIG_CAJA+
                                                           C_C1.UTGE_VALOR_RECIBOS_CAJA+
                                                           C_C1.UTGE_VALOR_TRANSF_CAJA+
                                                           C_C1.UTGE_VALOR_ORDENES_PAGO_SCB);
         V_SALDO_GARANTIA  := ABS(V_SALDO_GARANTIA);
         V_UTILIDAD := TRUNC(((P_VALOR_RENDIMIENTOS*V_SALDO_GARANTIA)/V_TOTAL_GARANTIAS),2);

         BEGIN
            UPDATE UTILIDADES_GARANTIAS_EFECTIVO
              SET UTGE_VALOR_UTILIDAD =  V_UTILIDAD
                 ,UTGE_ESTADO = 'PRO'
                 ,UTGE_FECHA_GEN_PRORRATEO = SYSDATE
                 ,UTGE_USUARIO_GEN_PRORRATEO  = USER
            WHERE UTGE_SECUENCIA = C_C1.UTGE_SECUENCIA ;
         END;
         FETCH C1 INTO C_C1;
      END LOOP;
      CLOSE C1;

      /* VALIDACION PARA AJUSTAR PRORATEO*/
      V_TOTAL_UTILIDAD := 0;
      BEGIN
         SELECT SUM(UTGE_VALOR_UTILIDAD) INTO V_TOTAL_UTILIDAD
         FROM UTILIDADES_GARANTIAS_EFECTIVO
         WHERE UTGE_ESTADO = 'PRO'     
           AND UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
           AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1);
      END;    
      V_TOTAL_UTILIDAD := NVL(V_TOTAL_UTILIDAD,0);

      IF P_VALOR_RENDIMIENTOS-V_TOTAL_UTILIDAD != 0 THEN
         UPDATE UTILIDADES_GARANTIAS_EFECTIVO A
           SET A.UTGE_VALOR_UTILIDAD = A.UTGE_VALOR_UTILIDAD+(P_VALOR_RENDIMIENTOS-V_TOTAL_UTILIDAD)
         WHERE A.UTGE_SECUENCIA = (SELECT MAX(B.UTGE_SECUENCIA) FROM UTILIDADES_GARANTIAS_EFECTIVO B
                                   WHERE B.UTGE_ESTADO = 'PRO'
                                     AND B.UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
                                     AND B.UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1));  
      END IF;
   ELSE
      RAISE_APPLICATION_ERROR(-20001, 'Para la fecha ya existe proceso de Prorrateo Aprobado');   
   END IF;
   COMMIT;      

   EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002, 'Error en PR_PRORATEO_GAR_DERIVADOS :'||SQLERRM);       
END PR_PRORRATEO_GAR_DERIVADOS;

PROCEDURE PR_CON_PRORRATEO_DERIVADOS( P_FECHA_PROCESO IN DATE) IS
  CURSOR C1 IS 
     SELECT UTGE_SECUENCIA
       ,UTGE_ESTADO
       ,UTGE_CCC_CLI_PER_NUM_IDEN
       ,UTGE_CCC_CLI_PER_TID_CODIGO
       ,UTGE_CCC_NUMERO_CUENTA
       ,UTGE_NOMBRE_CUENTA
       ,UTGE_VALOR_UTILIDAD
       ,UTGE_VALOR_CHEQUES
       ,UTGE_VALOR_CONSIG_CAJA
       ,UTGE_VALOR_RECIBOS_CAJA
       ,UTGE_VALOR_TRANSF_CAJA
       ,UTGE_VALOR_ORDENES_PAGO_SCB
       ,UTGE_VALOR_ORDENES_PAGO
       ,UTGE_FECHA
       ,UTGE_GARANTIA_SCB
       ,UTGE_GARANTIA_CRCC
       ,UTGE_FECHA_GEN_PRORRATEO 
       ,UTGE_USUARIO_GEN_PRORRATEO 
       ,UTGE_FECHA_CON_PRORRATEO 
       ,UTGE_USUARIO_CON_PRORRATEO 
    FROM UTILIDADES_GARANTIAS_EFECTIVO
    WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
      AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
      --and UTGE_CCC_CLI_PER_NUM_IDEN = '900194153'
      --and UTGE_CCC_CLI_PER_TID_CODIGO = 'NIT'
      AND UTGE_ESTADO = 'PRO';

   C_C1 C1%ROWTYPE;      
   V_VALIDA_PROCESO  NUMBER(5);
   V_SELECT          VARCHAR2(4000);
   V_COBRA_RETE      VARCHAR2(1);
   V_VALOR           CONSTANTES.CON_VALOR%TYPE;
   V_VALOR_DATE      CONSTANTES.CON_VALOR_DATE%TYPE;
   V_VALOR_CHAR      CONSTANTES.CON_VALOR_CHAR%TYPE;
   V_VALOR_RETE      CONSTANTES.CON_VALOR%TYPE;
   V_PER_TIPO        PERSONAS.PER_TIPO%TYPE;
   V_TDD_MNEMONICO   TIPOS_MOV_CUENTAS_DERIVADOS.TDD_MNEMONICO%TYPE;
   V_TMC_MNEMONICO   TIPOS_MOVIMIENTO_CORREDORES.TMC_MNEMONICO%TYPE;
   V_CCC_ROW         CUENTAS_CLIENTE_CORREDORES%ROWTYPE;
   V_CDD_ROW         CUENTAS_CLIENTES_DERIVADOS%ROWTYPE;
   V_CLI_ROW         CLIENTES%ROWTYPE;   
   V_CURSOR          P_GARANTIAS.O_CURSOR;

   -- SORTIZ CUENTAS CRCC
   CURSOR C_CTA_CAMARA ( NID VARCHAR2, TID VARCHAR2) IS
      SELECT (CTCA_NUMERO_CUENTA||CTCA_NUMERO_SUBCUENTA) CTA_CAMARA
        FROM CUENTAS_CAMARA
            ,CUENTAS_DECEVAL
            ,PRODUCTOS_TIPO_OPERACION
            ,PRODUCTOS_CAMARA
       WHERE CTCA_CUD_CUENTA_DECEVAL = CUD_CUENTA_DECEVAL
         AND CTCA_PTOP_CONSECUTIVO = PTOP_CONSECUTIVO
         AND PTOP_PRM_ID = PRM_ID
         AND PTOP_ESTADO = 'A'  
         AND CUD_CLI_PER_NUM_IDEN = NID
         AND CUD_CLI_PER_TID_CODIGO = TID
		 AND PRM_MNEMONICO = 'DER';
   V_CTA  VARCHAR2(12);

BEGIN

   V_VALIDA_PROCESO      := 0;   
   V_VALOR               := NULL;
   V_VALOR_DATE          := NULL;
   V_VALOR_CHAR          := NULL;

   BEGIN
     SELECT COUNT(*) INTO V_VALIDA_PROCESO
     FROM UTILIDADES_GARANTIAS_EFECTIVO
     WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
     AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
     AND UTGE_ESTADO != 'PRO';
   END;
   V_VALIDA_PROCESO := NVL(V_VALIDA_PROCESO,0);

   P_TOOLS.CONSULTARCONSTANTE(
       P_CONSTANTE  => 'CDU',
       P_VALOR      => V_VALOR,
       P_VALOR_DATE => V_VALOR_DATE,
       P_VALOR_CHAR => V_VALOR_CHAR
   );

   IF NVL(V_VALOR,0) = 0 THEN
     RAISE_APPLICATION_ERROR(-20003, 'Cuenta Corredores no valida para proceso derivados (constante CDU)');   
   END IF;


   V_VALOR_RETE := 0;
   V_VALOR_RETE := P_APORTES.FN_VALOR_RETENCION(P_CON_MNEMONICO => 'RGD');


   IF NVL(V_VALOR_RETE,0) = 0 THEN
      RAISE_APPLICATION_ERROR(-20004, 'Valor de retencion Derivados Invalido (Constante RGD');   
   END IF;

   IF  V_VALIDA_PROCESO = 0  THEN
      OPEN C1;
      FETCH C1 INTO C_C1;
      WHILE C1%FOUND LOOP
         /** DETERMINAR CUENTA CRCC DEL CLIENTE*/
         V_SELECT        :=  NULL;
         V_CCC_ROW       :=  NULL;
         V_CURSOR        :=  NULL;
         V_CLI_ROW       :=  NULL;
         V_PER_TIPO      := NULL;



         IF NVL(C_C1.UTGE_GARANTIA_SCB,'N') = 'N' OR NVL(C_C1.UTGE_GARANTIA_CRCC,'N') = 'S' THEN
            V_SELECT  := 'SELECT NVL(CLI_SUJETO_RTEFTE_FONDO,''N'') CLI_SUJETO_RTEFTE_FONDO '||
                      ' ,NVL(CLI_SUJETO_RTEFTE,''N'') CLI_RETENCION_FONDO'||
                      ' ,NVL(CLI_AUTORRETENEDOR,''N'') CLI_AUTORRETENEDOR'||
                      ' ,NVL(CLI_GRAN_CONTRIBUYENTE,''N'') CLI_GRAN_CONTRIBUYENTE'||
					  ' ,NVL(CLI_REG_TRIB_ESP,''N'') CLI_REG_TRIB_ESP'||
                      ' ,PER_TIPO '||
                      ' ,CCC_CLI_PER_NUM_IDEN '||
                      ' ,CCC_CLI_PER_TID_CODIGO '||
                      ' ,CCC_NUMERO_CUENTA '||
                      ' ,CCC_CUENTA_CRCC '||
                      ' FROM PERSONAS
                            ,CLIENTES 
                            ,CUENTAS_CLIENTE_CORREDORES '||
                      ' WHERE PER_NUM_IDEN = CLI_PER_NUM_IDEN '||
                      '  AND PER_TID_CODIGO = CLI_PER_TID_CODIGO '||
                      '  AND CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN '||
                      '  AND CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO '||
                      '  AND CCC_CLI_PER_NUM_IDEN = '||CHR(39)|| C_C1.UTGE_CCC_CLI_PER_NUM_IDEN||CHR(39)||
                      '  AND CCC_CLI_PER_TID_CODIGO = '||CHR(39)|| C_C1.UTGE_CCC_CLI_PER_TID_CODIGO||CHR(39)||
                      '  AND CCC_NUMERO_CUENTA = '||C_C1.UTGE_CCC_NUMERO_CUENTA||
                      '  AND CCC_CUENTA_CRCC IS NOT NULL '||
                      '  AND CCC_CUENTA_ACTIVA = '||CHR(39)||'S'||CHR(39)||
                      ' ORDER BY CCC_NUMERO_CUENTA';

         OPEN C_CTA_CAMARA (C_C1.UTGE_CCC_CLI_PER_NUM_IDEN,C_C1.UTGE_CCC_CLI_PER_TID_CODIGO);
         FETCH C_CTA_CAMARA INTO V_CTA;
         CLOSE C_CTA_CAMARA;

         ELSE
            V_SELECT  := 'SELECT NVL(CLI_SUJETO_RTEFTE_FONDO,''N'') CLI_SUJETO_RTEFTE_FONDO '||
                      ' ,NVL(CLI_SUJETO_RTEFTE,''N'') CLI_RETENCION_FONDO'||
                      ' ,NVL(CLI_AUTORRETENEDOR,''N'') CLI_AUTORRETENEDOR'||
                      ' ,NVL(CLI_GRAN_CONTRIBUYENTE,''N'') CLI_GRAN_CONTRIBUYENTE'||
					  ' ,NVL(CLI_REG_TRIB_ESP,''N'') CLI_REG_TRIB_ESP'||
                      ' ,PER_TIPO '||
                      ' ,CCC_CLI_PER_NUM_IDEN '||
                      ' ,CCC_CLI_PER_TID_CODIGO '||
                      ' ,CCC_NUMERO_CUENTA '||
                      ' ,CCC_CUENTA_CRCC '||
					  ' FROM PERSONAS
                            ,CLIENTES 
                            ,CUENTAS_CLIENTE_CORREDORES '||
                      ' WHERE  PER_NUM_IDEN = CLI_PER_NUM_IDEN '||
                      '  AND PER_TID_CODIGO = CLI_PER_TID_CODIGO '||
                      '  AND CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN '||
                      '  AND CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO '||
                      '  AND CCC_CLI_PER_NUM_IDEN = '||CHR(39)||'860079173'||CHR(39)||
                      '  AND CCC_CLI_PER_TID_CODIGO = '||CHR(39)||'NIT'||CHR(39)||
                      '  AND CCC_NUMERO_CUENTA = '||V_VALOR||
                      '  AND CCC_CUENTA_ACTIVA = '||CHR(39)||'S'||CHR(39)||
                      ' ORDER BY CCC_NUMERO_CUENTA';

         OPEN C_CTA_CAMARA ('860079173','NIT');
         FETCH C_CTA_CAMARA INTO V_CTA;
         CLOSE C_CTA_CAMARA;

         END IF;


         OPEN V_CURSOR   FOR V_SELECT;
         FETCH V_CURSOR INTO V_CLI_ROW.CLI_SUJETO_RTEFTE_FONDO,
                             V_CLI_ROW.CLI_SUJETO_RTEFTE,                             
                             V_CLI_ROW.CLI_AUTORRETENEDOR,
                             V_CLI_ROW.CLI_GRAN_CONTRIBUYENTE,
							 V_CLI_ROW.CLI_REG_TRIB_ESP,
							 V_PER_TIPO,
                             V_CCC_ROW.CCC_CLI_PER_NUM_IDEN,
                             V_CCC_ROW.CCC_CLI_PER_TID_CODIGO,
                             V_CCC_ROW.CCC_NUMERO_CUENTA,
                             V_CCC_ROW.CCC_CUENTA_CRCC
                             ;
         CLOSE V_CURSOR;

         IF NVL(C_C1.UTGE_GARANTIA_SCB,'N') = 'S' THEN
            V_CCC_ROW.CCC_CUENTA_CRCC  :=   V_VALOR_CHAR;
         END IF;   

        -- IF NVL(V_CCC_ROW.CCC_CLI_PER_NUM_IDEN,' ') = ' ' THEN
        --    RAISE_APPLICATION_ERROR(-20004, 'Cuenta CRCC no existe para cliente :'||C_C1.UTGE_CCC_CLI_PER_TID_CODIGO||'-'||C_C1.UTGE_CCC_CLI_PER_NUM_IDEN);
        -- END IF;

         V_CDD_ROW :=  NULL;
         V_CURSOR  :=  NULL;
         V_SELECT  :=  NULL;

         IF NVL(C_C1.UTGE_GARANTIA_SCB,'N') = 'S' THEN
            IF C_C1.UTGE_VALOR_UTILIDAD > 0 THEN
              V_TMC_MNEMONICO := 'URCPS';
            ELSE
              V_TMC_MNEMONICO := 'PRCPS';
            END IF;

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
              ,MCC_MONTO_ADMON_VALORES)
            VALUES
              ( MCC_SEQ.NEXTVAL
              ,V_CCC_ROW.CCC_CLI_PER_NUM_IDEN
              ,V_CCC_ROW.CCC_CLI_PER_TID_CODIGO                            
              ,V_CCC_ROW.CCC_NUMERO_CUENTA
              ,SYSDATE
              ,V_TMC_MNEMONICO
              ,DECODE(V_TMC_MNEMONICO,'URCPS',C_C1.UTGE_VALOR_UTILIDAD
                                     ,'PRCPS',C_C1.UTGE_VALOR_UTILIDAD)
              ,0
              ,0
              ,0);

         ELSIF NVL(C_C1.UTGE_GARANTIA_CRCC,'N') = 'S' THEN
            IF C_C1.UTGE_VALOR_UTILIDAD > 0 THEN
              V_TMC_MNEMONICO := 'URCRC';
            --ELSE
            --  V_TMC_MNEMONICO := 'PRCPS';
            END IF;

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
              ,MCC_MONTO_ADMON_VALORES)
            VALUES
              ( MCC_SEQ.NEXTVAL
              ,V_CCC_ROW.CCC_CLI_PER_NUM_IDEN
              ,V_CCC_ROW.CCC_CLI_PER_TID_CODIGO                            
              ,V_CCC_ROW.CCC_NUMERO_CUENTA
              ,SYSDATE
              ,V_TMC_MNEMONICO
              ,DECODE(V_TMC_MNEMONICO,'URCRC',C_C1.UTGE_VALOR_UTILIDAD)
              ,0
              ,0
              ,0);

         ELSE
           V_SELECT := 'SELECT CDD_CCC_CLI_PER_NUM_IDEN,CDD_CCC_NUMERO_CUENTA,CDD_CCC_NUMERO_CUENTA,CDD_CUENTA_CRCC '||
                          ' FROM CUENTAS_CLIENTES_DERIVADOS '||
                         ' WHERE CDD_CCC_CLI_PER_NUM_IDEN = '||CHR(39)||V_CCC_ROW.CCC_CLI_PER_NUM_IDEN||CHR(39)||
                         '  AND CDD_CCC_CLI_PER_TID_CODIGO = '||CHR(39)||V_CCC_ROW.CCC_CLI_PER_TID_CODIGO||CHR(39)||
                         '  AND CDD_CCC_NUMERO_CUENTA = '||V_CCC_ROW.CCC_NUMERO_CUENTA||
                         '  AND CDD_CUENTA_CRCC ='||CHR(39)||V_CCC_ROW.CCC_CUENTA_CRCC||CHR(39);


           OPEN V_CURSOR   FOR V_SELECT;
           FETCH V_CURSOR INTO V_CDD_ROW.CDD_CCC_CLI_PER_NUM_IDEN,
                               V_CDD_ROW.CDD_CCC_NUMERO_CUENTA, 
                               V_CDD_ROW.CDD_CCC_NUMERO_CUENTA, 
                               V_CDD_ROW.CDD_CUENTA_CRCC ;
           CLOSE V_CURSOR;

           IF NVL(V_CDD_ROW.CDD_CCC_CLI_PER_NUM_IDEN,' ') = ' ' THEN
              /* CREACION DE CUENTA DERIVADOS*/
              INSERT INTO CUENTAS_CLIENTES_DERIVADOS(
                 CDD_CCC_CLI_PER_NUM_IDEN
                ,CDD_CCC_CLI_PER_TID_CODIGO
                ,CDD_CCC_NUMERO_CUENTA
                ,CDD_SALDO
                ,CDD_CUENTA_CRCC)
              VALUES
              (
                 V_CCC_ROW.CCC_CLI_PER_NUM_IDEN      --CDD_CCC_CLI_PER_NUM_IDEN
                ,V_CCC_ROW.CCC_CLI_PER_TID_CODIGO    --CDD_CCC_CLI_PER_TID_CODIGO
                ,V_CCC_ROW.CCC_NUMERO_CUENTA         --CDD_CCC_NUMERO_CUENTA
                ,0                                   --CDD_SALDO
                ,V_CCC_ROW.CCC_CUENTA_CRCC           --CDD_CUENTA_CRCC
              );
           END IF;  


           /* CREACION DE MOVIMIENTO */
           IF C_C1.UTGE_VALOR_UTILIDAD > 0 THEN
              V_TDD_MNEMONICO := 'INUTRE';
           ELSE
              V_TDD_MNEMONICO := 'EGPERE';
           END IF;

           INSERT INTO MOVIMIENTOS_CUENTAS_DERIVADOS(
              MDD_CONSECUTIVO                
             ,MDD_FECHA                      
             ,MDD_CDD_CCC_CLI_PER_NUM_IDEN   
             ,MDD_CDD_CCC_CLI_PER_TID_CODIGO
             ,MDD_CDD_CCC_NUMERO_CUENTA      
             ,MDD_CDD_CUENTA_CRCC
             ,MDD_TDD_MNEMONICO
             ,MDD_MONTO)      
           VALUES (
              MDD_SEQ.NEXTVAL
             ,SYSDATE
             ,V_CCC_ROW.CCC_CLI_PER_NUM_IDEN
             ,V_CCC_ROW.CCC_CLI_PER_TID_CODIGO
             ,V_CCC_ROW.CCC_NUMERO_CUENTA
             ,V_CCC_ROW.CCC_CUENTA_CRCC 
             ,V_TDD_MNEMONICO
             ,DECODE(V_TDD_MNEMONICO,'INUTRE',C_C1.UTGE_VALOR_UTILIDAD
                                    ,'EGPERE',C_C1.UTGE_VALOR_UTILIDAD)
                           );     

           /* CREACION MOVIMIENTO DE RETENCION */ 
           V_COBRA_RETE := NULL;


           IF V_PER_TIPO = 'PNA' THEN
             V_COBRA_RETE := 'S';
           ELSIF V_PER_TIPO = 'PJU' THEN         
             IF NVL(V_CLI_ROW.CLI_GRAN_CONTRIBUYENTE,'N') = 'N' AND
                NVL(V_CLI_ROW.CLI_AUTORRETENEDOR,'N') = 'N' AND
                NVL(V_CLI_ROW.CLI_SUJETO_RTEFTE_FONDO,'N') = 'S' AND
                NVL(V_CLI_ROW.CLI_SUJETO_RTEFTE,'N') = 'S' AND
				NVL(V_CLI_ROW.CLI_REG_TRIB_ESP,'N') = 'N' THEN
                V_COBRA_RETE := 'S';
             ELSIF NVL(V_CLI_ROW.CLI_GRAN_CONTRIBUYENTE,'N') = 'S' AND
                NVL(V_CLI_ROW.CLI_AUTORRETENEDOR,'N') = 'N' AND
                NVL(V_CLI_ROW.CLI_SUJETO_RTEFTE_FONDO,'N') = 'S' AND
                NVL(V_CLI_ROW.CLI_SUJETO_RTEFTE,'N') = 'S' AND
				NVL(V_CLI_ROW.CLI_REG_TRIB_ESP,'N') = 'N' THEN
                V_COBRA_RETE := 'S';   
             ELSE
               V_COBRA_RETE := 'N';  
             END IF;               
           END IF;

           IF V_COBRA_RETE = 'S' THEN
              IF C_C1.UTGE_VALOR_UTILIDAD > 0 THEN 
                 INSERT INTO MOVIMIENTOS_CUENTAS_DERIVADOS(
                     MDD_CONSECUTIVO                
                    ,MDD_FECHA                      
                    ,MDD_CDD_CCC_CLI_PER_NUM_IDEN   
                    ,MDD_CDD_CCC_CLI_PER_TID_CODIGO
                    ,MDD_CDD_CCC_NUMERO_CUENTA      
                    ,MDD_CDD_CUENTA_CRCC
                    ,MDD_TDD_MNEMONICO
                    ,MDD_MONTO)      
                 VALUES (
                 MDD_SEQ.NEXTVAL
                ,SYSDATE
                ,V_CCC_ROW.CCC_CLI_PER_NUM_IDEN
                ,V_CCC_ROW.CCC_CLI_PER_TID_CODIGO
                ,V_CCC_ROW.CCC_NUMERO_CUENTA
                ,V_CCC_ROW.CCC_CUENTA_CRCC 
                ,'REFDER'
                ,-ROUND(C_C1.UTGE_VALOR_UTILIDAD*V_VALOR_RETE,2));     
              END IF;
           END IF;
         END IF;

         UPDATE UTILIDADES_GARANTIAS_EFECTIVO
            SET  UTGE_ESTADO = 'APR'
                ,UTGE_FECHA_CON_PRORRATEO = SYSDATE
                ,UTGE_USUARIO_CON_PRORRATEO  = USER
         WHERE UTGE_SECUENCIA = C_C1.UTGE_SECUENCIA;
         FETCH C1 INTO C_C1;
      END LOOP;
      CLOSE C1;

	  -- GENERACION DE ORDENES DE PAGO PARA LOS FICS
      P_GARANTIAS.PR_ORDENES_UTIREPO_FICS;

   ELSE
      RAISE_APPLICATION_ERROR(-20003, 'Para la fecha ya existe proceso de Confirmacion de Prorrateo');   
   END IF;
   COMMIT;      

   EXCEPTION WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, 'Error en PR_CON_PRORATEO_DERIVADOS ('||C_C1.UTGE_SECUENCIA||'-'||C_C1.UTGE_CCC_CLI_PER_NUM_IDEN||'):'||SQLERRM);
END PR_CON_PRORRATEO_DERIVADOS;


PROCEDURE PR_REV_PRORRATEO_DERIVADOS( P_FECHA_PROCESO IN DATE) IS

  CURSOR C1 IS 
     SELECT DISTINCT MDD_CDD_CCC_CLI_PER_NUM_IDEN   
              ,MDD_CDD_CCC_CLI_PER_TID_CODIGO
              ,MDD_CDD_CCC_NUMERO_CUENTA      
              ,MDD_CDD_CUENTA_CRCC
     FROM MOVIMIENTOS_CUENTAS_DERIVADOS
     WHERE MDD_FECHA           >= TRUNC(P_FECHA_PROCESO)
       AND MDD_FECHA           < TRUNC(P_FECHA_PROCESO+1)
       AND MDD_TDD_MNEMONICO   IN ('INUTRE','EGPERE','REFDER');           
  C_C1 C1%ROWTYPE;

  CURSOR C2 IS
    SELECT DISTINCT MCC_CCC_CLI_PER_NUM_IDEN,MCC_CCC_CLI_PER_TID_CODIGO
    ,MCC_CCC_NUMERO_CUENTA 
    FROM MOVIMIENTOS_CUENTA_CORREDORES
    WHERE MCC_FECHA >= TRUNC(P_FECHA_PROCESO)  
      AND MCC_FECHA < TRUNC(P_FECHA_PROCESO+1)
      AND MCC_TMC_MNEMONICO IN ('URCPS','PRCPS');
    C_C2 C2%ROWTYPE;



  V_MDD_CONSECUTIVO MOVIMIENTOS_CUENTAS_DERIVADOS.MDD_CONSECUTIVO%TYPE;
  V_MCC_CONSECUTIVO MOVIMIENTOS_CUENTA_CORREDORES.MCC_CONSECUTIVO%TYPE;
  V_MDD_SALDO       MOVIMIENTOS_CUENTAS_DERIVADOS.MDD_SALDO%TYPE;
  V_MCC_ROW         MOVIMIENTOS_CUENTA_CORREDORES%ROWTYPE;


BEGIN


   OPEN C1;
   FETCH C1 INTO C_C1;
   WHILE C1%FOUND LOOP
      /* BORRADO MOIVIMIENTOS INUTRE,EGPERE Y  REFDER DEL DIA*/
      DELETE MOVIMIENTOS_CUENTAS_DERIVADOS
      WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN    = C_C1.MDD_CDD_CCC_CLI_PER_NUM_IDEN
        AND MDD_CDD_CCC_CLI_PER_TID_CODIGO  = C_C1.MDD_CDD_CCC_CLI_PER_TID_CODIGO
        AND MDD_CDD_CCC_NUMERO_CUENTA       = C_C1.MDD_CDD_CCC_NUMERO_CUENTA
        AND MDD_CDD_CUENTA_CRCC             = C_C1.MDD_CDD_CUENTA_CRCC
        AND MDD_FECHA                       >= TRUNC(P_FECHA_PROCESO)
        AND MDD_FECHA                         < TRUNC(P_FECHA_PROCESO+1)
        AND MDD_TDD_MNEMONICO               IN ('INUTRE','EGPERE','REFDER');

      /* ACTUALIZAR SALDO EN CUENTAS_CLIENTES_DERIVADOS*/
      V_MDD_CONSECUTIVO := NULL;
      SELECT MAX(MDD_CONSECUTIVO) INTO V_MDD_CONSECUTIVO
      FROM MOVIMIENTOS_CUENTAS_DERIVADOS  
      WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN    = C_C1.MDD_CDD_CCC_CLI_PER_NUM_IDEN
        AND MDD_CDD_CCC_CLI_PER_TID_CODIGO  = C_C1.MDD_CDD_CCC_CLI_PER_TID_CODIGO
        AND MDD_CDD_CCC_NUMERO_CUENTA       = C_C1.MDD_CDD_CCC_NUMERO_CUENTA
        AND MDD_CDD_CUENTA_CRCC             = C_C1.MDD_CDD_CUENTA_CRCC
        AND MDD_FECHA                         < TRUNC(P_FECHA_PROCESO+1);

      V_MDD_SALDO := 0;
      V_MDD_CONSECUTIVO := NVL(V_MDD_CONSECUTIVO,0);
      IF V_MDD_CONSECUTIVO != 0 THEN
         SELECT MDD_SALDO INTO V_MDD_SALDO
         FROM MOVIMIENTOS_CUENTAS_DERIVADOS
         WHERE MDD_CONSECUTIVO = V_MDD_CONSECUTIVO;
      END IF;


      UPDATE CUENTAS_CLIENTES_DERIVADOS
         SET CDD_SALDO = NVL(V_MDD_SALDO,0)
      WHERE CDD_CCC_CLI_PER_NUM_IDEN    = C_C1.MDD_CDD_CCC_CLI_PER_NUM_IDEN
        AND CDD_CCC_CLI_PER_TID_CODIGO  = C_C1.MDD_CDD_CCC_CLI_PER_TID_CODIGO
        AND CDD_CCC_NUMERO_CUENTA       = C_C1.MDD_CDD_CCC_NUMERO_CUENTA
        AND CDD_CUENTA_CRCC             = C_C1.MDD_CDD_CUENTA_CRCC;


      FETCH C1 INTO C_C1; 
   END LOOP;
   CLOSE C1;



   OPEN C2;
   FETCH C2 INTO C_C2;
   WHILE C2%FOUND LOOP
      DELETE MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_CCC_CLI_PER_NUM_IDEN = C_C2.MCC_CCC_CLI_PER_NUM_IDEN
         AND MCC_CCC_CLI_PER_TID_CODIGO = C_C2.MCC_CCC_CLI_PER_TID_CODIGO
         AND MCC_CCC_NUMERO_CUENTA  = C_C2.MCC_CCC_NUMERO_CUENTA
         AND MCC_FECHA >= TRUNC(P_FECHA_PROCESO)  
         AND MCC_FECHA < TRUNC(P_FECHA_PROCESO+1)
         AND MCC_TMC_MNEMONICO IN ('URCPS','PRCPS');

      V_MCC_CONSECUTIVO := 0;
      SELECT MAX(MCC_CONSECUTIVO)
      INTO V_MCC_CONSECUTIVO
      FROM MOVIMIENTOS_CUENTA_CORREDORES
      WHERE MCC_CCC_CLI_PER_NUM_IDEN = C_C2.MCC_CCC_CLI_PER_NUM_IDEN
         AND MCC_CCC_CLI_PER_TID_CODIGO = C_C2.MCC_CCC_CLI_PER_TID_CODIGO
         AND MCC_CCC_NUMERO_CUENTA  = C_C2.MCC_CCC_NUMERO_CUENTA
         AND MCC_FECHA < TRUNC(P_FECHA_PROCESO+1);

      V_MCC_CONSECUTIVO := NVL(V_MCC_CONSECUTIVO,0);
      IF V_MDD_CONSECUTIVO != 0 THEN
         V_MCC_ROW := NULL;

         SELECT MCC_SALDO
              ,MCC_SALDO_A_PLAZO
              ,MCC_SALDO_A_CONTADO
              ,MCC_SALDO_ADMON_VALORES
              ,MCC_SALDO_CANJE
              ,MCC_SALDO_CC
              ,MCC_SALDO_CANJE_CC
              ,MCC_SALDO_BURSATIL
         INTO  V_MCC_ROW.MCC_SALDO
              ,V_MCC_ROW.MCC_SALDO_A_PLAZO
              ,V_MCC_ROW.MCC_SALDO_A_CONTADO
              ,V_MCC_ROW.MCC_SALDO_ADMON_VALORES
              ,V_MCC_ROW.MCC_SALDO_CANJE
              ,V_MCC_ROW.MCC_SALDO_CC
              ,V_MCC_ROW.MCC_SALDO_CANJE_CC
              ,V_MCC_ROW.MCC_SALDO_BURSATIL
         FROM MOVIMIENTOS_CUENTA_CORREDORES
         WHERE MCC_CONSECUTIVO = V_MCC_CONSECUTIVO;
      END IF;

      UPDATE CUENTAS_CLIENTE_CORREDORES
         SET  CCC_SALDO_CAPITAL = NVL(V_MCC_ROW.MCC_SALDO,0)
         ,CCC_SALDO_A_PLAZO = NVL(V_MCC_ROW.MCC_SALDO_A_PLAZO,0)
         ,CCC_SALDO_A_CONTADO = NVL(V_MCC_ROW.MCC_SALDO_A_CONTADO,0)
         ,CCC_SALDO_ADMON_VALORES = NVL(V_MCC_ROW.MCC_SALDO_ADMON_VALORES,0)
         ,CCC_SALDO_CANJE = NVL(V_MCC_ROW.MCC_SALDO_CANJE,0)
         ,CCC_SALDO_CC = NVL(V_MCC_ROW.MCC_SALDO_CC,0)
         ,CCC_SALDO_CANJE_CC = NVL(V_MCC_ROW.MCC_SALDO_CANJE_CC,0)
         ,CCC_SALDO_BURSATIL = NVL(V_MCC_ROW.MCC_SALDO_BURSATIL,0)
      WHERE CCC_CLI_PER_NUM_IDEN = C_C2.MCC_CCC_CLI_PER_NUM_IDEN
        AND CCC_CLI_PER_TID_CODIGO =  C_C2.MCC_CCC_CLI_PER_TID_CODIGO
        AND CCC_NUMERO_CUENTA =  C_C2.MCC_CCC_NUMERO_CUENTA;      
     FETCH C2 INTO C_C2;
   END LOOP;
   CLOSE C2;

   /* BORRADO PRO RRATEO DEL DIA*/
   DELETE UTILIDADES_GARANTIAS_EFECTIVO
   WHERE UTGE_FECHA >= TRUNC(P_FECHA_PROCESO)
      AND UTGE_FECHA < TRUNC(P_FECHA_PROCESO+1)
      AND UTGE_ESTADO = 'APR';

   COMMIT;

   EXCEPTION WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20002, 'Error en PR_REV_PRORRATEO_DERIVADOS ('||C_C1.MDD_CDD_CCC_CLI_PER_NUM_IDEN||'):'||SQLERRM);  
END PR_REV_PRORRATEO_DERIVADOS;

PROCEDURE PR_CON_DERIVADOS_SCB IS
  P_DATOS_GARANTIA_SCB v_datos_refcur3;
  V_UTILIDAD_EFECTIVO_SCB  UTILIDADES_GARANTIAS_EFECTIVO%ROWTYPE;

BEGIN
    P_DATOS_GARANTIA_SCB    := NULL;
    V_UTILIDAD_EFECTIVO_SCB := NULL;

    DELETE DEVOLUCION_GAR_EFECTIVO_SCB
    WHERE DGES_ESTADO = 'COL';


    P_GARANTIAS.PR_GARANTIAS_DER_SCB(P_FECHA_PROCESO  => TRUNC(SYSDATE),
                                     P_DATOS_GARANTIA => P_DATOS_GARANTIA_SCB);                                   


    LOOP
         FETCH P_DATOS_GARANTIA_SCB INTO V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_NUM_IDEN
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_TID_CODIGO
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_NUMERO_CUENTA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_NOMBRE_CUENTA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CHEQUES
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CONSIG_CAJA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_TRANSF_CAJA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_RECIBOS_CAJA
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO_SCB
                                        ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO;


         EXIT WHEN P_DATOS_GARANTIA_SCB%NOTFOUND;
         INSERT INTO DEVOLUCION_GAR_EFECTIVO_SCB
            (DGES_SECUENCIA
            ,DGES_ESTADO
            ,DGES_CCC_CLI_PER_NUM_IDEN
            ,DGES_CCC_CLI_PER_TID_CODIGO
            ,DGES_CCC_NUMERO_CUENTA
            ,DGES_NOMBRE_CUENTA
            ,DGES_VALOR_UTILIDAD
            ,DGES_VALOR_CHEQUES
            ,DGES_VALOR_CONSIG_CAJA
            ,DGES_VALOR_RECIBOS_CAJA
            ,DGES_VALOR_TRANSF_CAJA
            ,DGES_VALOR_ORDENES_PAGO
            ,DGES_VALOR_ORDENES_PAGO_SCB
            ,DGES_VALOR_DEVOLUCION
            ,DGES_FECHA
            ,DGES_USUARIO_DEV_GARANTIA            
           )
         VALUES
          (
           DGES_SEQ.NEXTVAL                                    --DGES_SECUENCIA
          ,'COL'                                               --DGES_ESTADO
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_NUM_IDEN   --DGES_CCC_CLI_PER_NUM_IDEN
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_CLI_PER_TID_CODIGO --DGES_CCC_CLI_PER_TID_CODIGO
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_CCC_NUMERO_CUENTA      --DGES_CCC_NUMERO_CUENTA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_NOMBRE_CUENTA          --DGES_NOMBRE_CUENTA
          ,0                                                   --DGES_VALOR_UTILIDAD
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CHEQUES          --DGES_VALOR_CHEQUES
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_CONSIG_CAJA      --DGES_VALOR_CONSIG_CAJA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_RECIBOS_CAJA     --DGES_VALOR_RECIBOS_CAJA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_TRANSF_CAJA      --DGES_VALOR_TRANSF_CAJA
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO     --DGES_VALOR_ORDENES_PAGO
          ,V_UTILIDAD_EFECTIVO_SCB.UTGE_VALOR_ORDENES_PAGO_SCB --DGES_VALOR_ORDENES_PAGO_SCB
          ,0                                                   --DGES_VALOR_DEVOLUCION
          ,SYSDATE                                             --DGES_FECHA
          ,USER                                                --DGES_USUARIO_DEV_GARANTIA           
          );       
    END LOOP;
    CLOSE P_DATOS_GARANTIA_SCB;

    COMMIT;

    EXCEPTION WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20002, 'Error en PR_CON_DERIVADOS_SCB :'||SQLERRM);  
END PR_CON_DERIVADOS_SCB;

PROCEDURE PR_APR_DERIVADOS_SCB( P_SECUENCIA NUMBER,P_VALOR_DEVOLUCION NUMBER) IS

  CURSOR C1 IS
    SELECT DGES_SECUENCIA
            ,DGES_ESTADO
            ,DGES_CCC_CLI_PER_NUM_IDEN
            ,DGES_CCC_CLI_PER_TID_CODIGO
            ,DGES_CCC_NUMERO_CUENTA
            ,DGES_NOMBRE_CUENTA
            ,DGES_VALOR_UTILIDAD
            ,DGES_VALOR_CHEQUES
            ,DGES_VALOR_CONSIG_CAJA
            ,DGES_VALOR_RECIBOS_CAJA
            ,DGES_VALOR_TRANSF_CAJA
            ,DGES_VALOR_ORDENES_PAGO
            ,DGES_VALOR_ORDENES_PAGO_SCB
            ,DGES_VALOR_DEVOLUCION
            ,DGES_FECHA
            ,DGES_USUARIO_DEV_GARANTIA 
            ,CCC_PER_NUM_IDEN
            ,CCC_PER_TID_CODIGO
            ,PER_NOMBRE
    FROM  FILTRO_PERSONAS
         ,CUENTAS_CLIENTE_CORREDORES
         ,DEVOLUCION_GAR_EFECTIVO_SCB
    WHERE PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
      AND PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
      AND CCC_CLI_PER_NUM_IDEN = DGES_CCC_CLI_PER_NUM_IDEN
      AND CCC_CLI_PER_TID_CODIGO = DGES_CCC_CLI_PER_TID_CODIGO
      AND CCC_NUMERO_CUENTA = DGES_CCC_NUMERO_CUENTA
      AND DGES_SECUENCIA = P_SECUENCIA;
    C_C1 C1%ROWTYPE; 

    CURSOR CONSECUTIVO_ORR(P_NEG_CONSECUTIVO NUMBER, P_SUC_CODIGO NUMBER) IS
      SELECT NVL(MAX(ORR_CONSECUTIVO),0)+1
      FROM   ORDENES_RECAUDO
      WHERE  ORR_NEG_CONSECUTIVO   = P_NEG_CONSECUTIVO
			AND    ORR_SUC_CODIGO        = P_SUC_CODIGO;


    V_VALOR           CONSTANTES.CON_VALOR%TYPE;
    V_VALOR_DATE      CONSTANTES.CON_VALOR_DATE%TYPE;
    V_VALOR_CHAR      CONSTANTES.CON_VALOR_CHAR%TYPE;   
    V_VALOR_CTA       CONSTANTES.CON_VALOR%TYPE;
    V_VALOR_CHAR_CTA  CONSTANTES.CON_VALOR_CHAR%TYPE;
    V_PER_NOMBRE      FILTRO_PERSONAS.PER_NOMBRE%TYPE;
    V_ODP_CONSECUTIVO   ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
    V_ODP_CONSECUTIVO_T ORDENES_DE_PAGO.ODP_CONSECUTIVO%TYPE;
    V_ORR_CONSECUTIVO ORDENES_RECAUDO.ORR_CONSECUTIVO%TYPE;
    V_CCC_ROW         CUENTAS_CLIENTE_CORREDORES%ROWTYPE;
    V_SELECT          VARCHAR2(4000);
    V_CURSOR          P_GARANTIAS.O_CURSOR;


BEGIN
   P_TOOLS.CONSULTARCONSTANTE(
       P_CONSTANTE  => 'CDU',
       P_VALOR      => V_VALOR,
       P_VALOR_DATE => V_VALOR_DATE,
       P_VALOR_CHAR => V_VALOR_CHAR
   );

   P_TOOLS.CONSULTARCONSTANTE(
       P_CONSTANTE  => 'CSC',
       P_VALOR      => V_VALOR_CTA,
       P_VALOR_DATE => V_VALOR_DATE,
       P_VALOR_CHAR => V_VALOR_CHAR_CTA
   );

   V_CCC_ROW         := NULL;
   V_CURSOR          := NULL;
   V_SELECT          := NULL;   
   V_PER_NOMBRE      := NULL;
   V_ODP_CONSECUTIVO   := NULL;
   V_ODP_CONSECUTIVO_T := NULL;

   V_SELECT := 'SELECT CCC_CLI_PER_NUM_IDEN,CCC_CLI_PER_TID_CODIGO,CCC_NUMERO_CUENTA,CCC_NOMBRE_CUENTA,PER_NOMBRE '||
                        ' FROM FILTRO_PERSONAS,CUENTAS_CLIENTE_CORREDORES '||
                       ' WHERE PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN '||
                       '  AND PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO '||
                       '  AND CCC_CLI_PER_NUM_IDEN = '||CHR(39)||'860079173'||CHR(39)||
                       '  AND CCC_CLI_PER_TID_CODIGO = '||CHR(39)||'NIT'||CHR(39)||
                       '  AND CCC_NUMERO_CUENTA = '||V_VALOR;


   OPEN V_CURSOR   FOR V_SELECT;
   FETCH V_CURSOR INTO V_CCC_ROW.CCC_CLI_PER_NUM_IDEN,
                       V_CCC_ROW.CCC_CLI_PER_TID_CODIGO, 
                       V_CCC_ROW.CCC_NUMERO_CUENTA, 
                       V_CCC_ROW.CCC_NOMBRE_CUENTA ,
                       V_PER_NOMBRE;
   CLOSE V_CURSOR;



   OPEN C1;
   FETCH C1 INTO C_C1;
   WHILE C1%FOUND LOOP
      -- GENERAR TRB
      V_ODP_CONSECUTIVO   := NULL;
      V_ODP_CONSECUTIVO_T := NULL;

      P_ORDEN_PAGO.PR_INSERTA_ORDEN_DE_PAGO(		
                  P_ODP_SUC_CODIGO 	                =>	1,
                  P_ODP_NEG_CONSECUTIVO 	          =>	2,
                  P_ODP_FECHA 	                    =>	SYSDATE,
                  P_ODP_COLOCADA_POR 	              =>	USER,
                  P_ODP_TPA_MNEMONICO 	            =>	'TRB',
                  P_ODP_ESTADO 	                    =>	'APR',
                  P_ODP_ES_CLIENTE 	                =>	'S',
                  P_ODP_COT_MNEMONICO 	            =>	'DPGD',
                  P_ODP_A_NOMBRE_DE 	              =>	V_PER_NOMBRE,
                  P_ODP_FECHA_EJECUCION 	          =>	SYSDATE,
                  P_ODP_CONSIGNAR 	                =>	'S',
                  P_ODP_ENTREGAR_RECOGE 	          =>	'R',
                  P_ODP_ENVIA_FAX 	                =>	'N',
                  P_ODP_SOBREGIRO 	                =>	'N',
                  P_ODP_CRUCE_CHEQUE 	              =>	'RP',
                  P_ODP_MONTO_ORDEN 	              =>	P_VALOR_DEVOLUCION,
                  P_ODP_MONTO_IMGF 	                =>	NULL,
                  P_ODP_APROBADA_POR 	              =>	USER,
                  P_ODP_FECHA_APROBACION 	          =>	SYSDATE,
                  P_ODP_FORMA_DE_PAGO 	            =>	NULL,
                  P_ODP_CCC_CLI_PER_NUM_IDEN 	      =>	V_CCC_ROW.CCC_CLI_PER_NUM_IDEN,
                  P_ODP_CCC_CLI_PER_TID_CODIGO 	    =>	V_CCC_ROW.CCC_CLI_PER_TID_CODIGO,
                  P_ODP_CCC_NUMERO_CUENTA 	        =>	V_CCC_ROW.CCC_NUMERO_CUENTA,
                  P_ODP_PAGAR_A 	                  =>	'C',
                  P_ODP_PER_NUM_IDEN 	              =>	NULL,
                  P_ODP_PER_TID_CODIGO 	            =>	NULL,
                  P_ODP_BAN_CODIGO 	                =>	V_VALOR_CTA,
                  P_ODP_NUM_CUENTA_CONSIGNAR 	      =>	V_VALOR_CHAR_CTA,
                  P_ODP_TCB_MNEMONICO 	            =>	'CCO',
                  P_ODP_OCL_CLI_PER_NUM_IDEN_R 	    =>	NULL,
                  P_ODP_OCL_CLI_PER_TID_CODIGO_R 	  =>	NULL,
                  P_ODP_CCC_CLI_PER_NUM_IDEN_T 	    =>	NULL,
                  P_ODP_CCC_CLI_PER_TID_CODIGO_T 	  =>	NULL,
                  P_ODP_CCC_NUMERO_CUENTA_T 	      =>	NULL,
                  P_ODP_CBA_BAN_CODIGO 	            =>	NULL,
                  P_ODP_CBA_NUMERO_CUENTA 	        =>	NULL,
                  P_ODP_MAS_INSTRUCCIONES 	        =>	NULL,
                  P_ODP_NUM_IDEN 	                  =>	NULL,
                  P_ODP_TID_CODIGO 	                =>	NULL,
                  P_ODP_NPR_PRO_MNEMONICO 	        =>	'DERIV',
                  P_ODP_MEDIO_RECEPCION 	          =>	NULL,
                  P_ODP_DETALLE_MEDIO_RECEPCION 	  =>	NULL,
                  P_ODP_HORA_RECEPCION 	            =>	NULL,
                  P_ODP_PER_NUM_IDEN_ES_DUENO 	    =>	'79150142',
                  P_ODP_PER_TID_CODIGO_ES_DUENO 	  =>	'CC',
                  P_ODP_FECHA_VERIFICA 	            =>	NULL,
                  P_ODP_TERMINAL_VERIFICA 	        =>	FN_TERMINAL,
                  P_ODP_VERIFICADO_COMERCIAL      	=>	NULL,
                  P_ODP_DILIGENCIADA_POR 	          =>	NULL,
                  P_DETALLE_ACH 	                  =>	'N',
                  P_ODP_OFO_CONSECUTIVO 	          =>	NULL,
                  P_ODP_OFO_SUC_CODIGO 	            =>	NULL,
                  P_ODP_CONSECUTIVO 	              =>	V_ODP_CONSECUTIVO,
                  P_ODP_TAC_MNEMONICO 	            =>	NULL,
                  P_ODP_FORMA_CARGUE_ACH 	          =>	NULL,
                  P_ODP_CDD_CUENTA_CRCC 	          =>	NULL);

      BEGIN
         UPDATE ORDENES_DE_PAGO
           SET ODP_ORDEN_MANUAL = 'S'
         WHERE ODP_CONSECUTIVO     = V_ODP_CONSECUTIVO
           AND ODP_SUC_CODIGO      = 1
           AND ODP_NEG_CONSECUTIVO = 2;  
      END;

      -- GENERAR RC CON ORDEN DE RECAUDO PENDIENTE DE EJECUTAR
      OPEN CONSECUTIVO_ORR(2,1);
      FETCH CONSECUTIVO_ORR INTO V_ORR_CONSECUTIVO;
      CLOSE CONSECUTIVO_ORR;


      INSERT INTO ORDENES_RECAUDO(
        ORR_CONSECUTIVO
       ,ORR_SUC_CODIGO
       ,ORR_NEG_CONSECUTIVO
       ,ORR_FECHA
       ,ORR_ES_CLIENTE
       ,ORR_ESTADO
       ,ORR_TPA_MNEMONICO
       ,ORR_MONTO
       ,ORR_CCC_CLI_PER_NUM_IDEN
       ,ORR_CCC_CLI_PER_TID_CODIGO
       ,ORR_CCC_NUMERO_CUENTA
       ,ORR_COT_MNEMONICO
       ,ORR_CBA_NUMERO_CUENTA
       ,ORR_CBA_BAN_CODIGO
       ,ORR_TCB_MNEMONICO
       ,ORR_COLOCADA_POR
       ,ORR_NPR_PRO_MNEMONICO
       ,ORR_OTRAS_INSTRUCCIONES)
      VALUES(
        V_ORR_CONSECUTIVO 							 --ORR_CONSECUTIVO
       ,1																 --ORR_SUC_CODIGO
       ,2																 --ORR_NEG_CONSECUTIVO
       ,SYSDATE													 --ORR_FECHA
        ,'S'														 --ORR_ES_CLIENTE
       ,'APR'														 --ORR_ESTADO
       ,'TRB'														 --ORR_TPA_MNEMONICO
       ,P_VALOR_DEVOLUCION      			   --ORR_MONTO
       ,V_CCC_ROW.CCC_CLI_PER_NUM_IDEN   --ORR_CCC_CLI_PER_NUM_IDEN
       ,V_CCC_ROW.CCC_CLI_PER_TID_CODIGO --ORR_CCC_CLI_PER_TID_CODIGO
       ,V_CCC_ROW.CCC_NUMERO_CUENTA			 --ORR_CCC_NUMERO_CUENTA
       ,'DPGC'													 --ORR_COT_MNEMONICO
       ,V_VALOR_CHAR_CTA								 --ORR_CBA_NUMERO_CUENTA
       ,V_VALOR_CTA											 --ORR_CBA_BAN_CODIGO
       ,'CCO'														 --ORR_TCB_MNEMONICO
       ,USER														 --ORR_COLOCADA_POR
       ,'DERIV'													 --ORR_NPR_PRO_MNEMONICO	
       ,'DEVOLUCION GARANTIA POR SCB:'||C_C1.DGES_CCC_CLI_PER_NUM_IDEN||'-'||C_C1.DGES_CCC_CLI_PER_NUM_IDEN--ORR_OTRAS_INSTRUCCIONES
      );

      -- GENERAR TCC
      P_ORDEN_PAGO.PR_INSERTA_ORDEN_DE_PAGO(		
                  P_ODP_SUC_CODIGO 	                =>	1,
                  P_ODP_NEG_CONSECUTIVO 	          =>	2,
                  P_ODP_FECHA 	                    =>	SYSDATE,
                  P_ODP_COLOCADA_POR 	              =>	USER,
                  P_ODP_TPA_MNEMONICO 	            =>	'TCC',
                  P_ODP_ESTADO 	                    =>	'APR',
                  P_ODP_ES_CLIENTE 	                =>	'S',
                  P_ODP_COT_MNEMONICO 	            =>	'DPGD',
                  P_ODP_A_NOMBRE_DE 	              =>	C_C1.DGES_NOMBRE_CUENTA,
                  P_ODP_FECHA_EJECUCION 	          =>	SYSDATE,
                  P_ODP_CONSIGNAR 	                =>	'N',
                  P_ODP_ENTREGAR_RECOGE 	          =>	'R',
                  P_ODP_ENVIA_FAX 	                =>	'N',
                  P_ODP_SOBREGIRO 	                =>	'N',
                  P_ODP_CRUCE_CHEQUE 	              =>	'RP',
                  P_ODP_MONTO_ORDEN 	              =>	P_VALOR_DEVOLUCION,
                  P_ODP_MONTO_IMGF 	                =>	NULL,
                  P_ODP_APROBADA_POR 	              =>	USER,
                  P_ODP_FECHA_APROBACION 	          =>	SYSDATE,
                  P_ODP_FORMA_DE_PAGO 	            =>	NULL,
                  P_ODP_CCC_CLI_PER_NUM_IDEN 	      =>	V_CCC_ROW.CCC_CLI_PER_NUM_IDEN,
                  P_ODP_CCC_CLI_PER_TID_CODIGO 	    =>	V_CCC_ROW.CCC_CLI_PER_TID_CODIGO,
                  P_ODP_CCC_NUMERO_CUENTA 	        =>	V_CCC_ROW.CCC_NUMERO_CUENTA,
                  P_ODP_PAGAR_A 	                  =>	'C',
                  P_ODP_PER_NUM_IDEN 	              =>	NULL,
                  P_ODP_PER_TID_CODIGO 	            =>	NULL,
                  P_ODP_BAN_CODIGO 	                =>	NULL,
                  P_ODP_NUM_CUENTA_CONSIGNAR 	      =>	NULL,
                  P_ODP_TCB_MNEMONICO 	            =>	NULL,
                  P_ODP_OCL_CLI_PER_NUM_IDEN_R 	    =>	NULL,
                  P_ODP_OCL_CLI_PER_TID_CODIGO_R 	  =>	NULL,
                  P_ODP_CCC_CLI_PER_NUM_IDEN_T 	    =>	C_C1.DGES_CCC_CLI_PER_NUM_IDEN,
                  P_ODP_CCC_CLI_PER_TID_CODIGO_T 	  =>	C_C1.DGES_CCC_CLI_PER_TID_CODIGO,
                  P_ODP_CCC_NUMERO_CUENTA_T 	      =>	C_C1.DGES_CCC_NUMERO_CUENTA,
                  P_ODP_CBA_BAN_CODIGO 	            =>	NULL,
                  P_ODP_CBA_NUMERO_CUENTA 	        =>	NULL,
                  P_ODP_MAS_INSTRUCCIONES 	        =>	NULL,
                  P_ODP_NUM_IDEN 	                  =>	NULL,
                  P_ODP_TID_CODIGO 	                =>	NULL,
                  P_ODP_NPR_PRO_MNEMONICO 	        =>	'DERIV',
                  P_ODP_MEDIO_RECEPCION 	          =>	NULL,
                  P_ODP_DETALLE_MEDIO_RECEPCION 	  =>	NULL,
                  P_ODP_HORA_RECEPCION 	            =>	NULL,
                  P_ODP_PER_NUM_IDEN_ES_DUENO 	    =>	'79150142',
                  P_ODP_PER_TID_CODIGO_ES_DUENO 	  =>	'CC',
                  P_ODP_FECHA_VERIFICA 	            =>	NULL,
                  P_ODP_TERMINAL_VERIFICA 	        =>	FN_TERMINAL,
                  P_ODP_VERIFICADO_COMERCIAL      	=>	NULL,
                  P_ODP_DILIGENCIADA_POR 	          =>	NULL,
                  P_DETALLE_ACH 	                  =>	'N',
                  P_ODP_OFO_CONSECUTIVO 	          =>	NULL,
                  P_ODP_OFO_SUC_CODIGO 	            =>	NULL,
                  P_ODP_CONSECUTIVO 	              =>	V_ODP_CONSECUTIVO_T,
                  P_ODP_TAC_MNEMONICO 	            =>	NULL,
                  P_ODP_FORMA_CARGUE_ACH 	          =>	NULL,
                  P_ODP_CDD_CUENTA_CRCC 	          =>	NULL);

      BEGIN
         UPDATE ORDENES_DE_PAGO
           SET ODP_ORDEN_MANUAL = 'S'
         WHERE ODP_CONSECUTIVO     = V_ODP_CONSECUTIVO_T
           AND ODP_SUC_CODIGO      = 1
           AND ODP_NEG_CONSECUTIVO = 2;  
      END;

      BEGIN
        UPDATE  DEVOLUCION_GAR_EFECTIVO_SCB
          SET DGES_USUARIO_DEV_GARANTIA = USER
             ,DGES_ESTADO = 'APR'
             ,DGES_VALOR_DEVOLUCION = P_VALOR_DEVOLUCION
        WHERE DGES_SECUENCIA = P_SECUENCIA;     
      END;

      FETCH C1 INTO C_C1;
   END LOOP;
   CLOSE C1;

   COMMIT;

   EXCEPTION WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20002, 'Error en PR_APR_DERIVADOS_SCB :'||SQLERRM); 
END PR_APR_DERIVADOS_SCB;


-- SORTIZ GARANTIAS CRCC
PROCEDURE PR_ENVIO_MAIL_GARANTIAS(P_CORREO VARCHAR2) IS

    CONN                    UTL_SMTP.CONNECTION;
    REQ                     UTL_HTTP.REQ;  
    RESP                    UTL_HTTP.RESP;
    DATA                    RAW(200);
    V_NOMBRE_MAIL           VARCHAR2(200);
    TEXTO_CUERPO            VARCHAR2(4000);
    V_ARCHIVO_DETALLE       VARCHAR2(500);
    CONT                    NUMBER(3);

BEGIN 

   V_NOMBRE_MAIL := P_CORREO||';candrade@corredores.com'; --'comercll72@corredores.com';
   TEXTO_CUERPO := 'Existen Garantias por constituir, favor entrar al modulo y constituir la garantia.';

   CONN := P_MAIL.BEGIN_MAIL(
   SENDER     => 'garantias@corredores.com',
   RECIPIENTS => V_NOMBRE_MAIL,
   SUBJECT    => 'PENDIENTES GARANTIAS A CONSTITUIR',
   MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);
   P_MAIL.ATTACH_TEXT(CONN      => CONN,
                      DATA      => TEXTO_CUERPO,
                      MIME_TYPE => 'TEXT/HTML');
                      p_mail.end_mail( conn => conn );   
END PR_ENVIO_MAIL_GARANTIAS;


PROCEDURE  PR_ENVIO_MAIL_GARANTIAS_TER (P_TID_TERCERO IN VARCHAR2, P_NID_TERCERO IN VARCHAR2) IS

    CONN                    UTL_SMTP.CONNECTION;
    REQ                     UTL_HTTP.REQ;  
    RESP                    UTL_HTTP.RESP;
    DATA                    RAW(200);
    V_NOMBRE_MAIL           VARCHAR2(200);
    TEXTO_CUERPO            VARCHAR2(4000);
    V_ARCHIVO_DETALLE       VARCHAR2(500);
    CONT                    NUMBER(3);

   CURSOR COMERCIAL_TER IS
      SELECT PER_MAIL_CORREDOR
        FROM CUENTAS_CLIENTE_CORREDORES
           , PERSONAS
       WHERE CCC_CLI_PER_NUM_IDEN = P_NID_TERCERO
         AND CCC_CLI_PER_TID_CODIGO = P_TID_TERCERO
         AND CCC_PER_NUM_IDEN = PER_NUM_IDEN
         AND CCC_PER_TID_CODIGO = PER_TID_CODIGO; 
   COMERCIAL VARCHAR2(100);       

BEGIN 
   OPEN COMERCIAL_TER;
   FETCH COMERCIAL_TER INTO COMERCIAL;
   CLOSE COMERCIAL_TER;

   V_NOMBRE_MAIL := COMERCIAL;
   TEXTO_CUERPO := 'Existen Garantias por constituir, favor entrar al modulo y constituir la garantia.';

   CONN := P_MAIL.BEGIN_MAIL(
   SENDER     => 'garantias@corredores.com',
   RECIPIENTS => V_NOMBRE_MAIL,
   SUBJECT    => 'PENDIENTES GARANTIAS A CONSTITUIR',
   MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);
   P_MAIL.ATTACH_TEXT(CONN      => CONN,
                      DATA      => TEXTO_CUERPO,
                      MIME_TYPE => 'TEXT/HTML');
                      P_MAIL.END_MAIL( CONN => CONN );   
END PR_ENVIO_MAIL_GARANTIAS_TER;

PROCEDURE PR_ORDENES_UTIREPO_FICS IS

   -- TRAE LOS FONDOS QUE ESTAN EN EL MODULO CONDER Y QUE TENGAN VALOR DE UTILIDAD REPO (INUTRE)
   CURSOR C_FONDOS IS
      SELECT DISTINCT FONDOS_F_A.FON_CODIGO DEF_FON_CODIGO, MDD_CDD_CUENTA_CRCC DEF_CUENTA_CRCC
        FROM (SELECT FON_CODIGO
                FROM FONDOS 
               WHERE FON_TIPO != 'O' 
                 AND EXISTS (SELECT 'X' 
                               FROM PERSONAS_FONDOS 
                               WHERE PFN_FON_CODIGO = FON_CODIGO 
                               ) 
                 AND FON_ESTADO = 'A'
                 AND NOT EXISTS (SELECT 'X'
                                   FROM PARAMETROS_FONDOS 
                                  WHERE PFO_FON_CODIGO = FONDOS.FON_CODIGO 
                                    AND PFO_PAR_CODIGO in (70) 
                                    AND NVL(PFO_RANGO_MIN_CHAR,'N') = 'S')
                                    AND FONDOS.FON_CAPITAL_PRIVADO = 'N'
                                    AND FONDOS.FON_TIPO_ADMINISTRACION = 'A'
                                    AND FONDOS.FON_ESTADO = 'A'--89
                  UNION
                   SELECT FON_CODIGO
                   FROM FONDOS AA
                  WHERE FON_CODIGO != '860079174'									-- NO INCLUYE POSICION PROPIA
                    AND FON_TIPO_ADMINISTRACION = 'F'							-- SOLO APLICA PARA FICS
                    AND NVL(FON_CAPITAL_PRIVADO,'N') = 'N'				-- NO APLICA PARA FONDOS DE CAPITAL PRIVADO
                    AND FON_TIPO = 'A'
                    AND NOT EXISTS (SELECT 'X'
                                      FROM FONDOS FF
                                          ,PARAMETROS_FONDOS PF 
                                     WHERE PF.PFO_FON_CODIGO = FF.FON_CODIGO
                                       AND PF.PFO_FON_CODIGO = AA.FON_CODIGO
                                       AND PF.PFO_PAR_CODIGO IN (70, 101)
                                       AND NVL(PF.PFO_RANGO_MIN_CHAR,'N') = 'S'
                                       AND FF.FON_CODIGO = FON_CODIGO)) FONDOS_F_A,--24
          MOVIMIENTOS_CUENTAS_DERIVADOS
     WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = FONDOS_F_A.FON_CODIGO
       AND TRUNC(MDD_FECHA) >= TRUNC(SYSDATE)
       AND TRUNC(MDD_FECHA) < TRUNC(SYSDATE + 1)
       AND MDD_TDD_MNEMONICO IN ('INUTRE','REFDER') 
	   AND MDD_CDD_CCC_CLI_PER_NUM_IDEN <> '900328518';         
   R_FONDO C_FONDOS%ROWTYPE;
   V_FONDO VARCHAR2(15);

   CURSOR C_FON IS
      SELECT FON_NEG_CONSECUTIVO
            ,FON_NPR_PRO_MNEMONICO
        FROM FONDOS
       WHERE FON_CODIGO = V_FONDO;
   FON C_FON%ROWTYPE;

   CURSOR C_MDD(V_CTA_CRCC VARCHAR2) IS
      SELECT MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA, SUM(MDD_MONTO) VALOR_INGRESO
        FROM MOVIMIENTOS_CUENTAS_DERIVADOS
       WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = V_FONDO
         AND TRUNC(MDD_FECHA) >= TRUNC(SYSDATE)
         AND TRUNC(MDD_FECHA) < TRUNC(SYSDATE + 1)
         AND MDD_TDD_MNEMONICO = 'INUTRE'
         AND MDD_CDD_CUENTA_CRCC = V_CTA_CRCC
       GROUP BY MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA;
   MDD C_MDD%ROWTYPE;

     CURSOR C_MDD_RET(V_CTA_CRCC VARCHAR2) IS
      SELECT MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA, SUM(MDD_MONTO) VALOR_INGRESO
        FROM MOVIMIENTOS_CUENTAS_DERIVADOS
       WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = V_FONDO
         AND TRUNC(MDD_FECHA) >= TRUNC(SYSDATE)
         AND TRUNC(MDD_FECHA) < TRUNC(SYSDATE + 1)
         AND MDD_TDD_MNEMONICO = 'REFDER'
         AND MDD_CDD_CUENTA_CRCC = V_CTA_CRCC
       GROUP BY MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA;
   MDD_RET C_MDD_RET%ROWTYPE;

   -- TRAE LA CUENTA CRCC
   CURSOR C_CCC IS
      SELECT CCC_PER_NUM_IDEN
            ,CCC_PER_TID_CODIGO
            ,CCC_CUENTA_CRCC
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = MDD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = MDD.MDD_CDD_CCC_CLI_PER_TID_CODIGO
         AND CCC_NUMERO_CUENTA = MDD.MDD_CDD_CCC_NUMERO_CUENTA;
   V_PER_NID VARCHAR2(15);
   V_PER_TID VARCHAR2(3);
   V_CTA_CRCC VARCHAR2(12);

    -- TRAE LA CUENTA CRCC APT
   CURSOR C_CRCC_APT IS
      SELECT CCC_CUENTA_CRCC
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = MDD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = MDD.MDD_CDD_CCC_CLI_PER_TID_CODIGO
         AND CCC_NUMERO_CUENTA = MDD.MDD_CDD_CCC_NUMERO_CUENTA
         AND CCC_CUENTA_APT = 'S';

    --VALIDA SI ES UN APT
   CURSOR C_APT(P_FONDO VARCHAR2) IS
      SELECT FON_CODIGO 
        FROM FONDOS 
       WHERE FON_TIPO != 'O' 
         AND EXISTS (SELECT 'X' 
			                 FROM PERSONAS_FONDOS 
							        WHERE PFN_FON_CODIGO = FON_CODIGO 
							          ) 
                 AND FON_ESTADO = 'A'
                 AND NOT EXISTS (SELECT 'X'
								                   FROM PARAMETROS_FONDOS 
								                  WHERE PFO_FON_CODIGO = FONDOS.FON_CODIGO 
								                    AND PFO_PAR_CODIGO in (70) 
								                    AND NVL(PFO_RANGO_MIN_CHAR,'N') = 'S')
     AND FONDOS.FON_CAPITAL_PRIVADO = 'N'
     AND FONDOS.FON_TIPO_ADMINISTRACION = 'A'
	   AND FONDOS.FON_ESTADO = 'A'
     AND FON_CODIGO = P_FONDO;
   R_APT VARCHAR2(15);


   CURSOR C_PER IS
      SELECT DECODE(PER_RAZON_SOCIAL,NULL,PER_NOMBRE||' '||PER_PRIMER_APELLIDO ||' '|| PER_SEGUNDO_APELLIDO,PER_RAZON_SOCIAL) PER_RAZON_SOCIAL
        FROM PERSONAS
       WHERE PER_NUM_IDEN = MDD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
         AND PER_TID_CODIGO = MDD.MDD_CDD_CCC_CLI_PER_TID_CODIGO;
   V_A_NOMBRE_DE PERSONAS.PER_RAZON_SOCIAL%TYPE;

   CURSOR C_PER_USER IS
      SELECT PER_NUM_IDEN, PER_TID_CODIGO
        FROM PERSONAS
       WHERE PER_NOMBRE_USUARIO = USER;
   PER_USER C_PER_USER%ROWTYPE;

   CURSOR C_CBL IS
      SELECT CBL_CBF_NUMERO_CUENTA, CBL_CBF_BAN_CODIGO, CBL_TIPO_CUENTA
        FROM CUENTAS_BANCARIAS_LIQUIDEZ_FON
       WHERE CBL_FON_CODIGO = V_FONDO
         AND CBL_TIPO_INSTRUCCION = 'URE';
   CBL C_CBL%ROWTYPE;

   CURSOR C_ULT_MTF (P_BAN_CODIGO VARCHAR2, P_NUMERO_CUENTA VARCHAR2, P_FON_CODIGO VARCHAR2) IS
      SELECT MTF_SALDO
            ,MTF_SALDO_INTERESES
            ,MTF_FECHA
        FROM MOVIMIENTOS_TESORERIA_FONDOS
       WHERE MTF_CBF_BAN_CODIGO = P_BAN_CODIGO
         AND MTF_CBF_NUMERO_CUENTA = P_NUMERO_CUENTA
         AND MTF_CBF_FON_CODIGO = P_FON_CODIGO
          ORDER BY MTF_CONSECUTIVO DESC;
   R_ULTIMO_MTF C_ULT_MTF%ROWTYPE;

   V_DIFERENCIAS VARCHAR2(1);
   V_FECHA DATE;	-- FECHA DEL PAGO

   NO_CBL    EXCEPTION;				-- NO DATOS EN LA TABLA CUENTAS_BANCARIAS_LIQUIDEZ_FON

   V_TIPO_CUENTA VARCHAR2(3);
   V_ODP_CONSECUTIVO NUMBER;
   V_OIE_CONSECUTIVO NUMBER;
   V_NID_DUENO VARCHAR2(15);
   V_TID_DUENO VARCHAR2(3);
   V_ODP_MAS VARCHAR2(500);
   MENSAJE VARCHAR2(1000);
   V_APT VARCHAR2(2);
   V_RETENCION NUMBER;

BEGIN
   OPEN C_FONDOS;
   FETCH C_FONDOS INTO R_FONDO;
   WHILE C_FONDOS%FOUND LOOP
   V_FONDO := R_FONDO.DEF_FON_CODIGO; 
   V_RETENCION := 0;

      OPEN C_CBL;
      FETCH C_CBL INTO CBL;
      IF C_CBL%NOTFOUND THEN
         RAISE NO_CBL;
      END IF;

      IF CBL.CBL_TIPO_CUENTA = 'A' THEN
         V_TIPO_CUENTA := 'CAH';
      ELSIF CBL.CBL_TIPO_CUENTA = 'C' THEN
         V_TIPO_CUENTA := 'CCO';
      END IF;
      CLOSE C_CBL;

      OPEN C_MDD(R_FONDO.DEF_CUENTA_CRCC);
      FETCH C_MDD INTO MDD;
      WHILE C_MDD%FOUND LOOP
         V_A_NOMBRE_DE := NULL;
         V_RETENCION := 0;
         OPEN C_PER;
         FETCH C_PER INTO V_A_NOMBRE_DE;
         CLOSE C_PER;

         -- SE GENERA LA ORDEN DE PAGO
         V_PER_NID := NULL;
         V_PER_TID := NULL;
         V_CTA_CRCC :=NULL;

         OPEN C_CCC;
         FETCH C_CCC INTO V_PER_NID, V_PER_TID, V_CTA_CRCC;
         CLOSE C_CCC;
         V_FECHA := SYSDATE;
         V_ODP_CONSECUTIVO := NULL;
         V_RETENCION := 0;

         --SS 
          OPEN C_APT(V_FONDO);
         FETCH C_APT INTO R_APT;
             IF C_APT%FOUND THEN
               V_APT := 'S';
               OPEN  C_CRCC_APT;
               FETCH C_CRCC_APT INTO V_CTA_CRCC;
                 IF C_CRCC_APT%FOUND THEN
                     OPEN C_MDD_RET(R_FONDO.DEF_CUENTA_CRCC);
                     FETCH C_MDD_RET INTO MDD_RET;
                        IF C_MDD_RET%FOUND THEN
                           V_RETENCION := NVL(MDD_RET.VALOR_INGRESO,0);
                        ELSE
                          V_RETENCION := 0;
                        END IF; 
                     CLOSE C_MDD_RET;
                 ELSE
                   V_CTA_CRCC :=NULL;
                 END IF;
               CLOSE C_CRCC_APT;
             END IF;
         CLOSE C_APT;
         --SS


         -- REGISTRO DE LA ODP
         IF  V_CTA_CRCC IS NOT NULL THEN

               P_ORDEN_PAGO.PR_INSERTA_ORDEN_DE_PAGO(P_ODP_SUC_CODIGO 			 	=> 1	-- SUCURSAL BOGOTA PRINCIPAL
                              ,P_ODP_NEG_CONSECUTIVO  			=> 2									  -- NEGOCIO 2 CLIENTES
                              ,P_ODP_FECHA 						      => V_FECHA
                              ,P_ODP_COLOCADA_POR 				=> USER
                              ,P_ODP_TPA_MNEMONICO 				=> 'TRB'							    -- TRANSFERENCIA BANCARIA
                              ,P_ODP_ESTADO 					    => 'APR'							    -- APROBADA
                              ,P_ODP_ES_CLIENTE 				  => 'S'								    -- ES_CLIENTE 'SI'
                              ,P_ODP_COT_MNEMONICO 				=> 'GUDER'						    -- CONCEPTO GIRO UTILIDADES DERIVADOS            
                              ,P_ODP_A_NOMBRE_DE  				=> V_A_NOMBRE_DE			    -- NOMBRE DE LA FIC
                              ,P_ODP_FECHA_EJECUCION 			=> V_FECHA
                              ,P_ODP_CONSIGNAR 					  => 'S'        
                              ,P_ODP_ENTREGAR_RECOGE 			=> 'R'
                              ,P_ODP_ENVIA_FAX 					  => 'N'
                              ,P_ODP_SOBREGIRO  				  => 'N'
                              ,P_ODP_CRUCE_CHEQUE 				=> 'RP'
                              ,P_ODP_MONTO_ORDEN 				  => MDD.VALOR_INGRESO+NVL(V_RETENCION,0)
                              ,P_ODP_MONTO_IMGF 				  => 0								    -- 0 IMPUESTOS
                              ,P_ODP_APROBADA_POR 				=> USER
                              ,P_ODP_FECHA_APROBACION 		=> V_FECHA
                              ,P_ODP_FORMA_DE_PAGO 				=> NULL 
                              ,P_ODP_CCC_CLI_PER_NUM_IDEN  		=> MDD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
                              ,P_ODP_CCC_CLI_PER_TID_CODIGO     => MDD.MDD_CDD_CCC_CLI_PER_TID_CODIGO
                              ,P_ODP_CCC_NUMERO_CUENTA 			=> MDD.MDD_CDD_CCC_NUMERO_CUENTA
                              ,P_ODP_PAGAR_A 					=> 'C'    						        --V_ODP_PAGAR_A CLIENTE
                              ,P_ODP_PER_NUM_IDEN 				=> NULL
                              ,P_ODP_PER_TID_CODIGO 			=> NULL
                              ,P_ODP_BAN_CODIGO 				=> CBL.CBL_CBF_BAN_CODIGO
                              ,P_ODP_NUM_CUENTA_CONSIGNAR 	    => CBL.CBL_CBF_NUMERO_CUENTA
                              ,P_ODP_TCB_MNEMONICO				=> V_TIPO_CUENTA
                              ,P_ODP_OCL_CLI_PER_NUM_IDEN_R     => NULL
                              ,P_ODP_OCL_CLI_PER_TID_CODIGO_R   => NULL
                              ,P_ODP_CCC_CLI_PER_NUM_IDEN_T     => NULL
                              ,P_ODP_CCC_CLI_PER_TID_CODIGO_T   => NULL
                              ,P_ODP_CCC_NUMERO_CUENTA_T  	    => NULL
                              ,P_ODP_CBA_BAN_CODIGO 			=> NULL
                              ,P_ODP_CBA_NUMERO_CUENTA 			=> NULL
                              ,P_ODP_MAS_INSTRUCCIONES  		=> ''
                              ,P_ODP_NUM_IDEN    				=> NULL
                              ,P_ODP_TID_CODIGO  				=> NULL
                              ,P_ODP_NPR_PRO_MNEMONICO 			=> 'DERIV'						
                              ,P_ODP_MEDIO_RECEPCION   			=> NULL
                              ,P_ODP_DETALLE_MEDIO_RECEPCION    => NULL
                              ,P_ODP_HORA_RECEPCION 			=> NULL
                              ,P_ODP_PER_NUM_IDEN_ES_DUENO 		=> V_PER_NID					        -- CCC_PER_NUM_IDEM DE LA CUENTA EN CCC
                              ,P_ODP_PER_TID_CODIGO_ES_DUENO    => V_PER_TID					        -- CCC_PER_TID_CODIGO DE LA CUENTA EN CCC
                              ,P_ODP_FECHA_VERIFICA  			=> V_FECHA  
                              ,P_ODP_TERMINAL_VERIFICA  		=> SUBSTR(FN_TERMINAL,1,20)
                              ,P_ODP_VERIFICADO_COMERCIAL 		=> 'S'
                              ,P_ODP_DILIGENCIADA_POR   		=> USER
                              ,P_ODP_CONSECUTIVO 				=> V_ODP_CONSECUTIVO
                              ,P_DETALLE_ACH 					=> 'N'
                              ,P_ODP_OFO_CONSECUTIVO 			=> NULL
                              ,P_ODP_OFO_SUC_CODIGO 			=> NULL
                              ,P_ODP_FORMA_CARGUE_ACH 			=> NULL
                              ,P_ODP_CDD_CUENTA_CRCC 			=> V_CTA_CRCC
                              );

               OPEN C_ULT_MTF (CBL.CBL_CBF_BAN_CODIGO, CBL.CBL_CBF_NUMERO_CUENTA, V_FONDO);
               FETCH C_ULT_MTF INTO R_ULTIMO_MTF;
               CLOSE C_ULT_MTF;

               -- REGISTRO DEL MOVIMIENTO EN TESORERIA - TRASLADO DEL INGRESO DEL NEGOCIO 2 AL FONDO
               INSERT INTO MOVIMIENTOS_TESORERIA_FONDOS
                          (MTF_CBF_BAN_CODIGO
                          ,MTF_CBF_NUMERO_CUENTA
                          ,MTF_CBF_FON_CODIGO
                          ,MTF_FECHA
                          ,MTF_TTE_MNEMONICO
                          ,MTF_DEBITO
                          ,MTF_CREDITO
                          ,MTF_SALDO
                          ,MTF_SALDO_INTERESES
                          ,MTF_DESCRIPCION
                          ,MTF_ODP_SUC_CODIGO
                          ,MTF_ODP_NEG_CONSECUTIVO
                          ,MTF_ODP_CONSECUTIVO)
                    VALUES
                          (CBL.CBL_CBF_BAN_CODIGO
                          ,CBL.CBL_CBF_NUMERO_CUENTA
                          ,V_FONDO
                          ,V_FECHA
                          ,'TRA'
                          ,MDD.VALOR_INGRESO+NVL(V_RETENCION,0) 					-- DEBITO
                          ,0																							-- CREDITO
                          ,R_ULTIMO_MTF.MTF_SALDO + MDD.VALOR_INGRESO+NVL(V_RETENCION,0)
                          ,R_ULTIMO_MTF.MTF_SALDO_INTERESES
                          ,'TRASLADO DE FONDOS INTERESES REPO '
                          ,1
                          ,2
                          ,V_ODP_CONSECUTIVO);


               -- REGISTRO DEL INGRESO
               SELECT OIE_SEQ.NEXTVAL
                 INTO V_OIE_CONSECUTIVO
                 FROM DUAL;

               INSERT INTO OTROS_INGRESOS_EGRESOS
                     (OIE_CONSECUTIVO
                     ,OIE_CIE_MNEMONICO
                     ,OIE_PYG_FECHA
                     ,OIE_PYG_FON_CODIGO
                     ,OIE_MONTO
                     ,OIE_USUARIO
                     ,OIE_TERMINAL)
              VALUES (V_OIE_CONSECUTIVO
                     ,'881'
                     ,V_FECHA
                     ,V_FONDO
                     ,MDD.VALOR_INGRESO
                     ,USER
                     ,SUBSTR(FN_TERMINAL,1,40)
                     );
            END IF;    
         FETCH C_MDD INTO MDD;
      END LOOP;
      CLOSE C_MDD;

      FETCH C_FONDOS INTO R_FONDO;
   END LOOP;
   CLOSE C_FONDOS;

   EXCEPTION
      WHEN NO_CBL THEN
         CLOSE C_CBL;
         RAISE_APPLICATION_ERROR(-20012, 'P_GARANTIAS.PR_ORDENES_UTIREPO_FICS :'
                                      || 'Cuenta Bancaria de Liquidez no parametrizada. '
                                      || 'Debe contactar el Front de Inversiones'|| SQLERRM);
      WHEN OTHERS THEN    
         RAISE_APPLICATION_ERROR(-20014, 'Error en P_GARANTIAS.PR_ORDENES_UTIREPO_FICS :'||SQLERRM);  

END PR_ORDENES_UTIREPO_FICS;

-- -----------------------------------------------------------------------------
PROCEDURE PR_REVERSA_UTIREPO_FICS (P_FECHA_PROCESO IN DATE) IS

   CURSOR C_FONDOS IS
    SELECT DISTINCT FONDOS_F_A.FON_CODIGO DEF_FON_CODIGO, MDD_CDD_CUENTA_CRCC DEF_CUENTA_CRCC
        FROM (SELECT FON_CODIGO
                FROM FONDOS 
               WHERE FON_TIPO != 'O' 
                 AND EXISTS (SELECT 'X' 
                               FROM PERSONAS_FONDOS 
                               WHERE PFN_FON_CODIGO = FON_CODIGO 
                               ) 
                 AND FON_ESTADO = 'A'
                 AND NOT EXISTS (SELECT 'X'
                                   FROM PARAMETROS_FONDOS 
                                  WHERE PFO_FON_CODIGO = FONDOS.FON_CODIGO 
                                    AND PFO_PAR_CODIGO in (70) 
                                    AND NVL(PFO_RANGO_MIN_CHAR,'N') = 'S')
                                    AND FONDOS.FON_CAPITAL_PRIVADO = 'N'
                                    AND FONDOS.FON_TIPO_ADMINISTRACION = 'A'
                                    AND FONDOS.FON_ESTADO = 'A'--89
                  UNION
                   SELECT FON_CODIGO
                   FROM FONDOS AA
                  WHERE FON_CODIGO != '860079174'									-- NO INCLUYE POSICION PROPIA
                    AND FON_TIPO_ADMINISTRACION = 'F'							-- SOLO APLICA PARA FICS
                    AND NVL(FON_CAPITAL_PRIVADO,'N') = 'N'				-- NO APLICA PARA FONDOS DE CAPITAL PRIVADO
                    AND FON_TIPO = 'A'
                    AND NOT EXISTS (SELECT 'X'
                                      FROM FONDOS FF
                                          ,PARAMETROS_FONDOS PF 
                                     WHERE PF.PFO_FON_CODIGO = FF.FON_CODIGO
                                       AND PF.PFO_FON_CODIGO = AA.FON_CODIGO
                                       AND PF.PFO_PAR_CODIGO IN (70, 101)
                                       AND NVL(PF.PFO_RANGO_MIN_CHAR,'N') = 'S'
                                       AND FF.FON_CODIGO = FON_CODIGO)) FONDOS_F_A,--24
          MOVIMIENTOS_CUENTAS_DERIVADOS
    WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = FONDOS_F_A.FON_CODIGO
      AND TRUNC(MDD_FECHA) >= TRUNC(P_FECHA_PROCESO)
                AND TRUNC(MDD_FECHA) < TRUNC(P_FECHA_PROCESO+1)
      AND MDD_TDD_MNEMONICO IN ('INUTRE','REFDER')
      ;                         
   R_FONDO C_FONDOS%ROWTYPE;            
   V_FONDO VARCHAR2(15);

   CURSOR C_MDD(V_CTA_CRCC VARCHAR2) IS
      SELECT MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA, SUM(MDD_MONTO) VALOR_INGRESO
        FROM MOVIMIENTOS_CUENTAS_DERIVADOS
       WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = V_FONDO
         AND TRUNC(MDD_FECHA) >= TRUNC(P_FECHA_PROCESO)
         AND TRUNC(MDD_FECHA) < TRUNC(P_FECHA_PROCESO+1)
         AND MDD_TDD_MNEMONICO = 'INUTRE'
         AND MDD_CDD_CUENTA_CRCC = V_CTA_CRCC
       GROUP BY MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA;
   MDD C_MDD%ROWTYPE;

   --TRAE LA RETENCION SS
    CURSOR C_MDD_RET(V_CTA_CRCC VARCHAR2) IS
      SELECT MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA, SUM(MDD_MONTO) VALOR_INGRESO
        FROM MOVIMIENTOS_CUENTAS_DERIVADOS
       WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = V_FONDO
         AND TRUNC(MDD_FECHA) >= TRUNC(SYSDATE)
         AND TRUNC(MDD_FECHA) < TRUNC(SYSDATE + 1)
         AND MDD_TDD_MNEMONICO = 'REFDER'
         AND MDD_CDD_CUENTA_CRCC = V_CTA_CRCC
       GROUP BY MDD_CDD_CCC_CLI_PER_NUM_IDEN, MDD_CDD_CCC_CLI_PER_TID_CODIGO, MDD_CDD_CCC_NUMERO_CUENTA;
   MDD_RET C_MDD_RET%ROWTYPE;

    --VALIDA SI ES UN APT SS
   CURSOR C_APT(P_FONDO VARCHAR2) IS
      SELECT FON_CODIGO 
        FROM FONDOS 
       WHERE FON_TIPO != 'O' 
         AND EXISTS (SELECT 'X' 
			                 FROM PERSONAS_FONDOS 
							        WHERE PFN_FON_CODIGO = FON_CODIGO 
							          ) 
                 AND FON_ESTADO = 'A'
                 AND NOT EXISTS (SELECT 'X'
								                   FROM PARAMETROS_FONDOS 
								                  WHERE PFO_FON_CODIGO = FONDOS.FON_CODIGO 
								                    AND PFO_PAR_CODIGO in (70) 
								                    AND NVL(PFO_RANGO_MIN_CHAR,'N') = 'S')
      AND FONDOS.FON_CAPITAL_PRIVADO = 'N'
      AND FONDOS.FON_TIPO_ADMINISTRACION = 'A'
	  	AND FONDOS.FON_ESTADO = 'A'
      AND FON_CODIGO = P_FONDO;
   R_APT VARCHAR2(15);

     -- TRAE LA CUENTA CRCC APT SS
   CURSOR C_CRCC_APT IS
      SELECT CCC_CUENTA_CRCC
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = MDD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = MDD.MDD_CDD_CCC_CLI_PER_TID_CODIGO
         AND CCC_NUMERO_CUENTA = MDD.MDD_CDD_CCC_NUMERO_CUENTA
         AND CCC_CUENTA_APT = 'S';


   CURSOR C_ODP(VLR_TOTAL NUMBER) IS
      SELECT ODP_CONSECUTIVO
            ,ODP_SUC_CODIGO
            ,ODP_NEG_CONSECUTIVO
            ,ODP_BAN_CODIGO
            ,ODP_NUM_CUENTA_CONSIGNAR
            ,ODP_TCB_MNEMONICO
            ,ODP_CEG_CONSECUTIVO
            ,ODP_TBC_CONSECUTIVO
            ,ODP_TCC_CONSECUTIVO
            ,ODP_CGE_CONSECUTIVO
        FROM ORDENES_DE_PAGO
       WHERE ODP_SUC_CODIGO = 1
         AND ODP_NEG_CONSECUTIVO = 2
         AND ODP_TPA_MNEMONICO = 'TRB'
         AND ODP_COT_MNEMONICO = 'GUDER'
         AND ODP_ESTADO = 'APR'
         AND ODP_CCC_CLI_PER_NUM_IDEN = MDD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
         AND ODP_CCC_CLI_PER_TID_CODIGO = MDD.MDD_CDD_CCC_CLI_PER_TID_CODIGO
         AND ODP_CCC_NUMERO_CUENTA = MDD.MDD_CDD_CCC_NUMERO_CUENTA
         AND ODP_MONTO_ORDEN = VLR_TOTAL--MDD.VALOR_INGRESO
         AND ODP_FECHA >= TRUNC(P_FECHA_PROCESO)
         AND ODP_FECHA < TRUNC(P_FECHA_PROCESO + 1)
         AND ODP_NPR_PRO_MNEMONICO = 'DERIV';
   ODP C_ODP%ROWTYPE;

   CURSOR C_ULT_MTF (P_BAN_CODIGO VARCHAR2, P_NUMERO_CUENTA VARCHAR2, P_FON_CODIGO VARCHAR2) IS
      SELECT MTF_SALDO
            ,MTF_SALDO_INTERESES
            ,MTF_FECHA
        FROM MOVIMIENTOS_TESORERIA_FONDOS
       WHERE MTF_CBF_BAN_CODIGO = P_BAN_CODIGO
         AND MTF_CBF_NUMERO_CUENTA = P_NUMERO_CUENTA
         AND MTF_CBF_FON_CODIGO = P_FON_CODIGO
          ORDER BY MTF_CONSECUTIVO DESC;
   R_ULTIMO_MTF C_ULT_MTF%ROWTYPE;

   V_OIE_CONSECUTIVO NUMBER; 

   ODP_EJECUTADA EXCEPTION;
   V_RETENCION NUMBER;
   V_CTA_CRCC VARCHAR2(10);
   V_TOTAL NUMBER;
BEGIN

   OPEN C_FONDOS;
   FETCH C_FONDOS INTO R_FONDO;
   WHILE C_FONDOS%FOUND LOOP
       V_FONDO := R_FONDO.DEF_FON_CODIGO;
      OPEN C_MDD(R_FONDO.DEF_CUENTA_CRCC);
      FETCH C_MDD INTO MDD;
      WHILE C_MDD%FOUND LOOP
      V_RETENCION := 0;
      V_TOTAL := 0;

         --SS 
            OPEN C_APT(V_FONDO);
           FETCH C_APT INTO R_APT;
              IF C_APT%FOUND THEN
                 OPEN  C_CRCC_APT;
                 FETCH C_CRCC_APT INTO V_CTA_CRCC;
                     IF C_CRCC_APT%FOUND THEN 
                         OPEN C_MDD_RET(R_FONDO.DEF_CUENTA_CRCC);
                         FETCH C_MDD_RET INTO MDD_RET;
                            IF C_MDD_RET%FOUND THEN
                               V_RETENCION := NVL(MDD_RET.VALOR_INGRESO,0);
                            ELSE
                               V_RETENCION := 0;
                            END IF; 
                         CLOSE C_MDD_RET;

                     ELSE
                      V_CTA_CRCC :=NULL;
                     END IF;
                 CLOSE C_CRCC_APT;   
              END IF;     
           CLOSE C_APT;
         --SS
         V_TOTAL := V_RETENCION + MDD.VALOR_INGRESO;

         OPEN C_ODP(V_TOTAL);
         FETCH C_ODP INTO ODP;
         IF C_ODP%FOUND THEN
            IF ODP.ODP_CEG_CONSECUTIVO IS NOT NULL OR
               ODP.ODP_TBC_CONSECUTIVO IS NOT NULL OR
               ODP.ODP_TCC_CONSECUTIVO IS NOT NULL OR
               ODP.ODP_CGE_CONSECUTIVO IS NOT NULL THEN
               RAISE ODP_EJECUTADA;
            END IF;

            -- DEJA LA ODP EN ESTADO ANULADO
            UPDATE ORDENES_DE_PAGO
               SET ODP_ESTADO = 'ANU'
                  ,ODP_FECHA_ANULACION = SYSDATE
                  ,ODP_ANULADA_POR = USER
                  ,ODP_RAZON_ANULACION = 'REVERSION PRORRATEO UTI DERIVADOS'
             WHERE ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
               AND ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
               AND ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO;

            OPEN C_ULT_MTF (ODP.ODP_BAN_CODIGO, ODP.ODP_NUM_CUENTA_CONSIGNAR, V_FONDO);
            FETCH C_ULT_MTF INTO R_ULTIMO_MTF;
            CLOSE C_ULT_MTF;

            -- REGISTRO DEL MOVIMIENTO EN TESORERIA - PARA REVERSAR EL TRASLADO
            INSERT INTO MOVIMIENTOS_TESORERIA_FONDOS
                    (MTF_CBF_BAN_CODIGO
                    ,MTF_CBF_NUMERO_CUENTA
                    ,MTF_CBF_FON_CODIGO
                    ,MTF_FECHA
                    ,MTF_TTE_MNEMONICO
                    ,MTF_DEBITO
                    ,MTF_CREDITO
                    ,MTF_SALDO
                    ,MTF_SALDO_INTERESES
                    ,MTF_DESCRIPCION
                    ,MTF_ODP_SUC_CODIGO
                    ,MTF_ODP_NEG_CONSECUTIVO
                    ,MTF_ODP_CONSECUTIVO)
              VALUES
                    (ODP.ODP_BAN_CODIGO
                    ,ODP.ODP_NUM_CUENTA_CONSIGNAR
                    ,V_FONDO
                    ,SYSDATE
                    ,'RET'
                    ,0															-- DEBITO
                    ,ABS(MDD.VALOR_INGRESO)	+NVL(V_RETENCION,0) 					-- CREDITO
                    ,R_ULTIMO_MTF.MTF_SALDO - ABS(MDD.VALOR_INGRESO)+ NVL(V_RETENCION,0) --SS
                    ,R_ULTIMO_MTF.MTF_SALDO_INTERESES
                    ,'REVERSION UTILIDAD REPO'
                    ,1
                    ,2
                    ,ODP.ODP_CONSECUTIVO);

            -- REVERSION DEL INGRESO
            SELECT OIE_SEQ.NEXTVAL
              INTO V_OIE_CONSECUTIVO
              FROM DUAL;

            INSERT INTO OTROS_INGRESOS_EGRESOS
                  (OIE_CONSECUTIVO
                  ,OIE_CIE_MNEMONICO
                  ,OIE_PYG_FECHA
                  ,OIE_PYG_FON_CODIGO
                  ,OIE_MONTO
                  ,OIE_USUARIO
                  ,OIE_TERMINAL)
           VALUES (V_OIE_CONSECUTIVO
                  ,'882'
                  ,SYSDATE
                  ,V_FONDO
                  ,ABS(MDD.VALOR_INGRESO)
                  ,USER
                  ,SUBSTR(FN_TERMINAL,1,40)
                  );

         END IF;
         CLOSE C_ODP;
         FETCH C_MDD INTO MDD;
      END LOOP;
      CLOSE C_MDD;
      FETCH C_FONDOS INTO R_FONDO;
   END LOOP;
   CLOSE C_FONDOS;

   EXCEPTION
   WHEN ODP_EJECUTADA THEN
      CLOSE C_ODP;
      RAISE_APPLICATION_ERROR(-20012, 'P_GARANTIAS.PR_REVERSA_UTIREPO_FICS :'
                                      || 'La orden '|| ODP.ODP_CONSECUTIVO || ' del Cliente ' 
                                      || V_FONDO || ' - Ya fue ejecutada. '
                                      || ' No es posible anularla'|| SQLERRM);
   WHEN OTHERS THEN    
      RAISE_APPLICATION_ERROR(-20014, 'Error en P_GARANTIAS.PR_REVERSA_UTIREPO_FICS :'||SQLERRM);  

END PR_REVERSA_UTIREPO_FICS; 

END;

/

  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "OSAJQUINONES";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "LREYESM";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JEMORENO";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "CSVELASQUEZ";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JALDANA";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "OSJBOHORQUEZ";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "EQUINONES";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "OSJURIBE";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "HRODRIGUEZ";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "CHERRERA";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "EPATINO";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "RBERMUDEZ";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JGASTELBONDO";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JVILLALBA";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JCALDERON";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "WCAMPOS";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "FHERMIDA";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "SORTIZ";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "AMRODRIGUEZG";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JOSPINA";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JACASLAR";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "OSLSOTELO";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "JARONCAN";
  GRANT EXECUTE ON "PROD"."P_GARANTIAS" TO "MRSANCHE";
