--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_MAIL_EXTRACTO_CLIENTE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_MAIL_EXTRACTO_CLIENTE" IS
PROCEDURE MAIL_PROCESO_CLIENTE 
   (P_FECHA_INICIAL    DATE DEFAULT NULL
   ,P_FECHA_FINAL      DATE DEFAULT NULL) IS

   DIRECCION  VARCHAR2(1000);
   PRIMERO    VARCHAR2(1);
   CONN       utl_smtp.connection;   
   CODIGO     EXTRACTO_FONDO_PLANO.EXT_CODIGO_GRUPO%TYPE;

   CURSOR C_EXT1 IS
      SELECT DISTINCT EXT_CFO_CCC_CLI_PER_NUM_IDEN,
             EXT_CFO_CCC_CLI_PER_TID_CODIGO,
             EXT_CFO_CCC_NUMERO_CUENTA,
             FON_PDR EXT_CFO_FON_CODIGO,
             EXT_CFO_CODIGO,
             EXT_CODIGO_GRUPO,
             NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) FON_MNEMONICO
        FROM EXTRACTO_FONDO_PLANO
            ,FONDOS
            -- VAGTUD991
            ,(SELECT PFO_FON_CODIGO, PFO_RANGO_MIN_CHAR FON_PDR
                FROM PARAMETROS_FONDOS
               WHERE PFO_PAR_CODIGO = 71
               UNION
              SELECT PFO_FON_CODIGO, PFO_FON_CODIGO FON_PDR
                FROM PARAMETROS_FONDOS
               WHERE PFO_PAR_CODIGO = 73) PF
       WHERE EXT_TIPO_INFORME NOT IN ('SAP','SA1','S26')
         AND EXT_CFO_FON_CODIGO = PFO_FON_CODIGO
         AND FON_PDR = FON_CODIGO
         AND NOT EXISTS (
             SELECT 'S'
               FROM PARAMETROS_FONDOS PF2
              WHERE PFO_FON_CODIGO = EXT_CFO_FON_CODIGO
                AND PFO_PAR_CODIGO = 115
                AND PFO_RANGO_MIN_CHAR = 'S')
       ORDER BY EXT_CODIGO_GRUPO, EXT_CFO_CCC_CLI_PER_NUM_IDEN;
   EXT1 C_EXT1%ROWTYPE;

   CURSOR C_EXT IS
      SELECT DISTINCT CRMF_CORREO EXT_DIRECCION
        FROM EXTRACTO_FONDO_PLANO
            ,CORREOS_MULTICASH_FONDOS
            ,(SELECT PFO_FON_CODIGO, PFO_RANGO_MIN_CHAR FON_PDR
                FROM PARAMETROS_FONDOS
               WHERE PFO_PAR_CODIGO = 71
               UNION
              SELECT PFO_FON_CODIGO, PFO_FON_CODIGO FON_PDR
                FROM PARAMETROS_FONDOS
               WHERE PFO_PAR_CODIGO = 73) PF
       WHERE EXT_CONSECUTIVO = CRMF_EXT_CONSECUTIVO
         AND EXT_CFO_CCC_CLI_PER_NUM_IDEN   = EXT1.EXT_CFO_CCC_CLI_PER_NUM_IDEN
         AND EXT_CFO_CCC_CLI_PER_TID_CODIGO = EXT1.EXT_CFO_CCC_CLI_PER_TID_CODIGO
         AND EXT_CFO_CCC_NUMERO_CUENTA      = EXT1.EXT_CFO_CCC_NUMERO_CUENTA
         -- AND EXT_CFO_FON_CODIGO             = EXT1.EXT_CFO_FON_CODIGO
         AND EXT_CFO_FON_CODIGO             =  PFO_FON_CODIGO
         AND FON_PDR = EXT1.EXT_CFO_FON_CODIGO
         AND EXT_TIPO_INFORME NOT IN ('SAP','SA1','S26');
         --AND EXT_CFO_CODIGO                 = EXT1.EXT_CFO_CODIGO;
   EXT C_EXT%ROWTYPE;

   CURSOR C_EXT_GRUPO IS
      SELECT DISTINCT EXT_CFO_CCC_CLI_PER_NUM_IDEN,
             EXT_CFO_CCC_CLI_PER_TID_CODIGO,
             EXT_CFO_CCC_NUMERO_CUENTA,
             FON_PDR EXT_CFO_FON_CODIGO,
             EXT_CFO_CODIGO,
             EXT_CODIGO_GRUPO,
             NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) FON_MNEMONICO
        FROM EXTRACTO_FONDO_PLANO
            ,FONDOS
            -- VAGTUD991
            ,(SELECT PFO_FON_CODIGO, PFO_RANGO_MIN_CHAR FON_PDR
                FROM PARAMETROS_FONDOS
               WHERE PFO_PAR_CODIGO = 71
               UNION
              SELECT PFO_FON_CODIGO, PFO_FON_CODIGO FON_PDR
                FROM PARAMETROS_FONDOS
               WHERE PFO_PAR_CODIGO = 73) PF
       WHERE EXT_TIPO_INFORME NOT IN ('SAP','SA1','S26')
       AND   EXT_CODIGO_GRUPO = CODIGO
       --AND   EXT_CFO_FON_CODIGO = FON_CODIGO
       AND  EXT_CFO_FON_CODIGO = PFO_FON_CODIGO
       AND  FON_PDR = FON_CODIGO
       ORDER BY EXT_CODIGO_GRUPO, EXT_CFO_CCC_CLI_PER_NUM_IDEN;
   EXT2 C_EXT_GRUPO%ROWTYPE;

   EXTRACTO_ARCHIVO   UTL_FILE.FILE_TYPE;
   ARCHIVO_ORI        UTL_FILE.FILE_TYPE;
   ARCHIVO_DES        UTL_FILE.FILE_TYPE;
   NOMBRE_ARCHIVO_ORI VARCHAR2(100);
   LINEA              VARCHAR2(1000);

BEGIN
   OPEN C_EXT1;
   FETCH C_EXT1 INTO EXT1;
   WHILE C_EXT1%FOUND LOOP
   	  DIRECCION := NULL;
      DIRECCION := 'aangel@corredores.com;dsilva@corredores.com';
      OPEN C_EXT;
      FETCH C_EXT INTO EXT;
      WHILE C_EXT%FOUND LOOP
         IF DIRECCION IS NULL THEN
            DIRECCION := EXT.EXT_DIRECCION;
         ELSE
            DIRECCION := DIRECCION||','||EXT.EXT_DIRECCION;
         END IF;
      FETCH C_EXT INTO EXT;
      END LOOP;
      CLOSE C_EXT;

      IF NVL(CODIGO,' ') != NVL(EXT1.EXT_CODIGO_GRUPO,'-1') THEN
         /* En caso de que no sea el primer registro y halla un cambio de codigo se cierra el mail anterior y
            se habre uno nuevo para la nueva cuenta. Los NVL estan diferentes porque nulo es un valor que genera
            diferenciación de grupo. Es decir, no hay grupo de clientes nulo */

         IF NVL(PRIMERO,'S') = 'S' THEN         
            PRIMERO := 'N';
         ELSE
            p_mail.end_attachment( conn => conn );
            p_mail.end_mail( conn => conn );
            UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);  

            OPEN C_EXT_GRUPO;
            FETCH C_EXT_GRUPO INTO EXT2;
            NOMBRE_ARCHIVO_ORI := EXT2.EXT_CFO_CCC_CLI_PER_NUM_IDEN 
                        || '-' || EXT2.EXT_CFO_CCC_CLI_PER_TID_CODIGO
                        || '-' || EXT2.FON_MNEMONICO
                        || '-' || EXT2.EXT_CFO_CCC_NUMERO_CUENTA
                        || '-' || EXT2.EXT_CFO_CODIGO
                        || '-' || TO_CHAR(P_FECHA_FINAL,'DDMMYYYY')
                        || '-' || 'DC'
                        || '.txt';
            FETCH C_EXT_GRUPO INTO EXT2; -- Se hacen dos FETCH porque el primero es el archivo origen y el segundo es para el destino
            WHILE C_EXT_GRUPO%FOUND LOOP
               ARCHIVO_ORI := UTL_FILE.FOPEN('LOG_DIR',NOMBRE_ARCHIVO_ORI,'R');
               ARCHIVO_DES := UTL_FILE.FOPEN('LOG_DIR',
                           EXT2.EXT_CFO_CCC_CLI_PER_NUM_IDEN 
                           || '-' || EXT2.EXT_CFO_CCC_CLI_PER_TID_CODIGO
                           || '-' || EXT2.FON_MNEMONICO
                           || '-' || EXT2.EXT_CFO_CCC_NUMERO_CUENTA
                           || '-' || EXT2.EXT_CFO_CODIGO
                           || '-' || TO_CHAR(P_FECHA_FINAL,'DDMMYYYY')
                           || '-' || 'DC'
                           || '.txt','W');
               BEGIN
                  WHILE TRUE LOOP
                     UTL_FILE.GET_LINE(ARCHIVO_ORI,LINEA);
                     UTL_FILE.PUT_LINE(ARCHIVO_DES,LINEA);
                  END LOOP;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     UTL_FILE.FCLOSE(ARCHIVO_ORI);
                     UTL_FILE.FCLOSE(ARCHIVO_DES);
               END;
               FETCH C_EXT_GRUPO INTO EXT2;
            END LOOP;
            CLOSE C_EXT_GRUPO;
         END IF;

         CODIGO := EXT1.EXT_CODIGO_GRUPO;

         IF EXT1.EXT_CODIGO_GRUPO IS NULL THEN
            conn := p_mail.begin_mail(sender     => 'MULTICASH@CORREDORES.COM',
                                      recipients =>  DIRECCION,
                                      subject    => 'Movimiento Diario NIT '||EXT1.EXT_CFO_CCC_CLI_PER_NUM_IDEN,
                                      mime_type  => p_mail.MULTIPART_MIME_TYPE);
         ELSE
            conn := p_mail.begin_mail(sender     => 'MULTICASH@CORREDORES.COM',
                                      recipients =>  DIRECCION,
                                      subject    => 'Movimiento Diario '|| EXT1.EXT_CODIGO_GRUPO,
                                      mime_type  => p_mail.MULTIPART_MIME_TYPE);
         END IF;  

         EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR',
                          EXT1.EXT_CFO_CCC_CLI_PER_NUM_IDEN 
                          || '-' || EXT1.EXT_CFO_CCC_CLI_PER_TID_CODIGO
                          || '-' || EXT1.FON_MNEMONICO
                          || '-' || EXT1.EXT_CFO_CCC_NUMERO_CUENTA
                          || '-' || EXT1.EXT_CFO_CODIGO
                          || '-' || TO_CHAR(P_FECHA_FINAL,'DDMMYYYY')
                          || '-' || 'DC'
                          || '.txt','W');

         IF TRUNC(P_FECHA_INICIAL) = TRUNC(P_FECHA_FINAL) THEN
             p_mail.begin_attachment(conn         => conn,
                                     mime_type    => RTRIM(TO_CHAR(P_FECHA_FINAL,'DD/MM/YYYY'),' ')||'/txt',
                                     inline       => TRUE,
                                     filename     => RTRIM(TO_CHAR(P_FECHA_FINAL,'DD/MM/YYYY'),' ')||'.txt',
                                     transfer_enc => 'text');   
         ELSE
            p_mail.begin_attachment(conn         => conn,
                                    mime_type    => RTRIM(TO_CHAR(P_FECHA_INICIAL,'DD/MM/YYYY') || '-' || TO_CHAR(P_FECHA_FINAL,'DD/MM/YYYY'),' ')||'/txt',
                                    inline       => TRUE,
                                    filename     => RTRIM(TO_CHAR(P_FECHA_INICIAL,'DD/MM/YYYY') || '-' || TO_CHAR(P_FECHA_FINAL,'DD/MM/YYYY'),' ')||'.txt',
                                    transfer_enc => 'text');   
         END IF;   
      END IF;

      P_MAIL_EXTRACTO_CLIENTE.MAIL_EXTRACTO_CLIENTE(EXT1.EXT_CFO_CCC_CLI_PER_NUM_IDEN 
                                                   ,EXT1.EXT_CFO_CCC_CLI_PER_TID_CODIGO
                                                   ,EXT1.EXT_CFO_CCC_NUMERO_CUENTA
                                                   ,EXT1.EXT_CFO_FON_CODIGO
                                                   ,EXT1.EXT_CFO_CODIGO
                                                   ,DIRECCION
                                                   ,P_FECHA_INICIAL
                                                   ,P_FECHA_FINAL
                                                   ,CONN
                                                   ,EXTRACTO_ARCHIVO);
      FETCH C_EXT1 INTO EXT1;
   END LOOP;
   CLOSE C_EXT1;
   /* Aqui se cierra el mail de la ultima cuenta o grupo generado*/
   p_mail.end_attachment( conn => conn );
   p_mail.end_mail( conn => conn );
   UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);   
EXCEPTION
   WHEN OTHERS THEN
      p_mail.write_mb_text(CONN,'Error en generacion archivo :'||SQLERRM);
      p_mail.end_attachment( CONN => CONN );
      p_mail.end_mail( conn => CONN );  
      UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);
END  MAIL_PROCESO_CLIENTE;
PROCEDURE MAIL_EXTRACTO_CLIENTE
   (P_CFO_CCC_CLI_PER_NUM_IDEN   CUENTAS_FONDOS.CFO_CCC_CLI_PER_NUM_IDEN%TYPE
   ,P_CFO_CCC_CLI_PER_TID_CODIGO CUENTAS_FONDOS.CFO_CCC_CLI_PER_TID_CODIGO%TYPE
   ,P_CFO_CCC_NUMERO_CUENTA      CUENTAS_FONDOS.CFO_CCC_NUMERO_CUENTA%TYPE
   ,P_CFO_FON_CODIGO             CUENTAS_FONDOS.CFO_FON_CODIGO%TYPE
   ,P_CFO_CODIGO                 CUENTAS_FONDOS.CFO_CODIGO%TYPE
   ,P_DIRECCION                  VARCHAR2
   ,P_FECHA_INICIAL              DATE
   ,P_FECHA_FINAL                DATE
   ,P_CONN                       IN OUT NOCOPY utl_smtp.connection
   ,P_ARCHIVO                    UTL_FILE.FILE_TYPE) IS

   TOTAL     NUMBER(22,2);
   DES       VARCHAR2(40);
   TIPO1     VARCHAR2(100);
   TIPO2     VARCHAR2(200);
   TIPO3     VARCHAR2(100);
   CTA       VARCHAR2(20);
   CRLF      VARCHAR2(2) :=  CHR(13)||CHR(10);  
   SIGNO     VARCHAR2(1);

   CURSOR CFO IS
      SELECT DISTINCT CFO_CCC_CLI_PER_NUM_IDEN,
             CFO_CCC_CLI_PER_TID_CODIGO,
             CFO_CCC_NUMERO_CUENTA,
             P_CFO_FON_CODIGO FON_CODIGO,       --- VAGTUD991
             CFO_CODIGO
        FROM CUENTAS_FONDOS
       WHERE CFO_CCC_CLI_PER_NUM_IDEN   = P_CFO_CCC_CLI_PER_NUM_IDEN
         AND CFO_CCC_CLI_PER_TID_CODIGO = P_CFO_CCC_CLI_PER_TID_CODIGO
         AND CFO_CCC_NUMERO_CUENTA      = P_CFO_CCC_NUMERO_CUENTA
         --- AND CFO_FON_CODIGO             = P_CFO_FON_CODIGO      ******
         AND CFO_FON_CODIGO             IN (SELECT PFO.PFO_FON_CODIGO
                                              FROM PARAMETROS_FONDOS PFO
                                             WHERE PFO.PFO_PAR_CODIGO = 71
                                               AND PFO_RANGO_MIN_CHAR = P_CFO_FON_CODIGO)
         AND CFO_CODIGO                 = P_CFO_CODIGO
         AND NOT EXISTS (
             SELECT 'S'
             FROM PARAMETROS_FONDOS PF1
             WHERE PFO_FON_CODIGO = CFO_FON_CODIGO
             AND PFO_PAR_CODIGO = 115
             AND PFO_RANGO_MIN_CHAR = 'S')
         AND EXISTS (
             SELECT 'S'
               FROM MOVIMIENTOS_CUENTAS_FONDOS
              WHERE MCF_CFO_CCC_CLI_PER_NUM_IDEN = CFO_CCC_CLI_PER_NUM_IDEN
                AND MCF_CFO_CCC_CLI_PER_TID_CODIGO = CFO_CCC_CLI_PER_TID_CODIGO
                AND MCF_CFO_CCC_NUMERO_CUENTA = CFO_CCC_NUMERO_CUENTA
                AND MCF_CFO_FON_CODIGO = CFO_FON_CODIGO
                AND MCF_CFO_CODIGO = CFO_CODIGO
                AND MCF_FECHA >= P_FECHA_INICIAL
                AND MCF_FECHA < P_FECHA_FINAL + 1
                )
         ;
   CFO1 CFO%ROWTYPE;

   CURSOR MCF_SALDO_ANTERIOR (P_FECHA DATE)IS
      SELECT MCF_SALDO_CAPITAL +
             MCF_SALDO_RENDIMIENTOS_RF +
             MCF_SALDO_RENDIMIENTOS_RV SALDO,
             MCF_CFO_CCC_CLI_PER_NUM_IDEN,
             MCF_CFO_CCC_CLI_PER_TID_CODIGO,
             MCF_CFO_CCC_NUMERO_CUENTA,
             MCF_CFO_CODIGO
        FROM MOVIMIENTOS_CUENTAS_FONDOS
       WHERE MCF_CFO_CCC_CLI_PER_NUM_IDEN   = CFO1.CFO_CCC_CLI_PER_NUM_IDEN
         AND MCF_CFO_CCC_CLI_PER_TID_CODIGO = CFO1.CFO_CCC_CLI_PER_TID_CODIGO
         AND MCF_CFO_CCC_NUMERO_CUENTA      = CFO1.CFO_CCC_NUMERO_CUENTA
         --AND MCF_CFO_FON_CODIGO             = CFO1.CFO_FON_CODIGO
         AND MCF_CFO_FON_CODIGO             LIKE CFO1.FON_CODIGO||'%'
         AND MCF_CFO_CODIGO                 = CFO1.CFO_CODIGO
         AND MCF_FECHA                      >= P_FECHA - 1
         AND MCF_FECHA                      < P_FECHA
       ORDER BY MCF_CONSECUTIVO DESC;
   MCF1 MCF_SALDO_ANTERIOR%ROWTYPE;

   CURSOR FON IS
      SELECT NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) FON_MNEMONICO
        FROM FONDOS
       --WHERE FON_CODIGO = CFO1.CFO_FON_CODIGO
       WHERE FON_CODIGO = CFO1.FON_CODIGO;
   FON1 FON%ROWTYPE;

   CURSOR MCF_MOVIMIENTOS_MES(P_FECHA1 DATE, P_FECHA2 DATE) IS
      SELECT TO_CHAR(MCF_FECHA,'YYYYMMDD') MCF_FECHA1,
             MCF_TMF_MNEMONICO,
             MCF_OFO_CONSECUTIVO,
             MCF_OFO_SUC_CODIGO,
             MCF_RETEFUENTE_MOVIMIENTO,
             MCF_CAPITAL +
             MCF_RENDIMIENTOS_RF +
             MCF_RENDIMIENTOS_RV -
             MCF_RETEFUENTE_MOVIMIENTO MONTO,
             MCF_CAPITAL +
             MCF_RENDIMIENTOS_RF +
             MCF_RENDIMIENTOS_RV MONTO2
        FROM MOVIMIENTOS_CUENTAS_FONDOS
       WHERE MCF_CFO_CCC_CLI_PER_NUM_IDEN   = CFO1.CFO_CCC_CLI_PER_NUM_IDEN
         AND MCF_CFO_CCC_CLI_PER_TID_CODIGO = CFO1.CFO_CCC_CLI_PER_TID_CODIGO
         AND MCF_CFO_CCC_NUMERO_CUENTA      = CFO1.CFO_CCC_NUMERO_CUENTA
         -- AND MCF_CFO_FON_CODIGO             = CFO1.CFO_FON_CODIGO
         AND MCF_CFO_FON_CODIGO             LIKE CFO1.FON_CODIGO||'%'
         AND MCF_CFO_CODIGO                 = CFO1.CFO_CODIGO
         AND MCF_FECHA                      >= P_FECHA1
         AND MCF_FECHA                      < P_FECHA2
       ORDER BY MCF_CONSECUTIVO ASC;
   MCF2 MCF_MOVIMIENTOS_MES%ROWTYPE;

   CURSOR OFO IS
      SELECT OFO_TTO_TOF_CODIGO,
             OFO_CONCEPTO_COBRO_APT,
             OFO_CONCEPTO_INC_APT
        FROM ORDENES_FONDOS
       WHERE OFO_CONSECUTIVO = MCF2.MCF_OFO_CONSECUTIVO
         AND OFO_SUC_CODIGO  = MCF2.MCF_OFO_SUC_CODIGO;
   OFO1 OFO%ROWTYPE;

   CURSOR TOF IS
      SELECT TOF_DESCRIPCION
        FROM TIPOS_ORDEN_FONDOS
       WHERE TOF_CODIGO = OFO1.OFO_TTO_TOF_CODIGO;
   TOF1 TOF%ROWTYPE;

   CURSOR ODP IS
      SELECT ODP_TPA_MNEMONICO,
             ODP_MONTO_ORDEN,
             ODP_NEG_CONSECUTIVO,
             ODP_SUC_CODIGO,
             ODP_CEG_CONSECUTIVO,
             ODP_CCC_CLI_PER_NUM_IDEN,
             ODP_OCL_CLI_PER_NUM_IDEN_RELAC,
             ODP_PER_NUM_IDEN,
             ODP_PAGAR_A,
             ODP_CONSECUTIVO
        FROM ORDENES_DE_PAGO
       WHERE ODP_OFO_SUC_CODIGO     = MCF2.MCF_OFO_SUC_CODIGO
         AND ODP_OFO_CONSECUTIVO    = MCF2.MCF_OFO_CONSECUTIVO
         AND ODP_ESTADO            != 'ANU';
   ODP1 ODP%ROWTYPE;

   CURSOR TPA IS
      SELECT TPA_DESCRIPCION
        FROM TIPOS_PAGO
       WHERE TPA_MNEMONICO = ODP1.ODP_TPA_MNEMONICO;
   TPA1 TPA%ROWTYPE;

   CURSOR CGE IS
      SELECT CEG_NUMERO_CHEQUE
        FROM COMPROBANTES_DE_EGRESO
       WHERE CEG_SUC_CODIGO      = ODP1.ODP_SUC_CODIGO
         AND CEG_NEG_CONSECUTIVO = ODP1.ODP_NEG_CONSECUTIVO
         AND CEG_CONSECUTIVO     = ODP1.ODP_CEG_CONSECUTIVO;
   CGE1 CGE%ROWTYPE;

   CURSOR PAGOS_ACH(P_DPA_ODP_CONSECUTIVO       NUMBER,
                    P_DPA_ODP_SUC_CODIGO        NUMBER,
                    P_DPA_ODP_NEG_CONSECUTIVO   NUMBER) IS
      SELECT DPA_MONTO,
             DPA_NUM_IDEN,
             DPA_TID_CODIGO,
             DPA_NOMBRE
        FROM DETALLES_PAGOS_ACH
       WHERE DPA_ODP_CONSECUTIVO     = P_DPA_ODP_CONSECUTIVO
         AND DPA_ODP_SUC_CODIGO      = P_DPA_ODP_SUC_CODIGO
         AND DPA_ODP_NEG_CONSECUTIVO = P_DPA_ODP_NEG_CONSECUTIVO
       ORDER BY DPA_CONSECUTIVO;  
   C_PAGOS_ACH   PAGOS_ACH%ROWTYPE;

   CURSOR TMF(P_MNEMONICO VARCHAR2) IS
      SELECT TMF_DESCRIPCION
        FROM TIPOS_MOVIMIENTO_FONDOS
       WHERE TMF_MNEMONICO = P_MNEMONICO;
   TMF1 TMF%ROWTYPE;

BEGIN
   OPEN CFO;
   FETCH CFO INTO CFO1;
   WHILE CFO%FOUND LOOP  		    
      OPEN MCF_SALDO_ANTERIOR(P_FECHA_INICIAL);
      FETCH MCF_SALDO_ANTERIOR INTO MCF1;
      IF MCF_SALDO_ANTERIOR%FOUND THEN
         OPEN FON;
         FETCH FON INTO FON1;
         IF FON%FOUND THEN
            TIPO1 := '01'
                  || TO_CHAR(RPAD(CFO1.CFO_CCC_CLI_PER_NUM_IDEN
                  || '-'
                  ||CFO1.CFO_CCC_CLI_PER_TID_CODIGO
                  || '-'
                  ||TO_CHAR(CFO1.CFO_CCC_NUMERO_CUENTA)
                  || '-'
                  ||FON1.FON_MNEMONICO
                  || '-'
                  ||TO_CHAR(CFO1.CFO_CODIGO),20,' '))
                  || TO_CHAR(P_FECHA_INICIAL,'YYYYMMDD')
                  || LPAD(LTRIM(TO_CHAR(ABS(MCF1.SALDO),'9999999999999999990.00')),22,'0');
            CTA := RPAD(CFO1.CFO_CCC_CLI_PER_NUM_IDEN
                || '-'
                ||CFO1.CFO_CCC_CLI_PER_TID_CODIGO
                || '-'
                ||TO_CHAR(CFO1.CFO_CCC_NUMERO_CUENTA)
                || '-'
                ||FON1.FON_MNEMONICO
                || '-'
                ||TO_CHAR(CFO1.CFO_CODIGO),20,' ');
 	       END IF;
         CLOSE FON;
      ELSE
         OPEN FON;
         FETCH FON INTO FON1;
         IF FON%FOUND THEN
            TIPO1 := '01'
                  || RPAD(CFO1.CFO_CCC_CLI_PER_NUM_IDEN
                  || '-'
                  ||CFO1.CFO_CCC_CLI_PER_TID_CODIGO
                  || '-'
                  ||TO_CHAR(CFO1.CFO_CCC_NUMERO_CUENTA)
                  || '-'
                  ||FON1.FON_MNEMONICO
                  || '-'
                  ||TO_CHAR(CFO1.CFO_CODIGO),20,' ')
                  || TO_CHAR(P_FECHA_INICIAL,'YYYYMMDD')
                  || LPAD(LTRIM(TO_CHAR(ABS('0'),'9999999999999999990.00')),22,'0');
            CTA := RPAD(CFO1.CFO_CCC_CLI_PER_NUM_IDEN
                || '-'
                ||CFO1.CFO_CCC_CLI_PER_TID_CODIGO
                || '-'
                ||TO_CHAR(CFO1.CFO_CCC_NUMERO_CUENTA)
                || '-'
                ||FON1.FON_MNEMONICO
                || '-'
                ||TO_CHAR(CFO1.CFO_CODIGO),20,' ');
         END IF;
         CLOSE FON;
      END IF;
      CLOSE MCF_SALDO_ANTERIOR;
      p_mail.write_mb_text(P_CONN,TIPO1||CRLF);
      UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO1);

      OPEN MCF_MOVIMIENTOS_MES(P_FECHA_INICIAL,P_FECHA_FINAL + 1);
      FETCH MCF_MOVIMIENTOS_MES INTO MCF2;
      WHILE MCF_MOVIMIENTOS_MES%FOUND LOOP
         IF MCF2.MCF_TMF_MNEMONICO = 'R' THEN
   	        OPEN OFO;
   	        FETCH OFO INTO OFO1;
   	        IF OFO%FOUND THEN
   		         OPEN TOF;
    		       FETCH TOF INTO TOF1;
    		       IF TOF%FOUND THEN
    			        IF MCF2.MONTO < 0 THEN
    			           SIGNO := '-';
   	  		        ELSE
   	 		  	         SIGNO := '+';
                  END IF;
                  TIPO2 := '02'
                        || TO_CHAR(MCF2.MCF_FECHA1)
                        || TO_CHAR(RPAD(OFO1.OFO_TTO_TOF_CODIGO,5,' '))
                        || RPAD(TOF1.TOF_DESCRIPCION,40,' ')
                        || SIGNO
                        || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO),'9999999999999999990.00')),22,'0')
                        || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                        || RPAD(' ',40,' ');
                  p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                  UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);
                  IF MCF2.MCF_RETEFUENTE_MOVIMIENTO IS NOT NULL AND MCF2.MCF_RETEFUENTE_MOVIMIENTO <> 0 THEN
                     IF MCF2.MCF_RETEFUENTE_MOVIMIENTO < 0 THEN
                        SIGNO := '-';
                     ELSE
                        SIGNO := '+';
                     END IF;
                     TIPO2 := '02'
                           || TO_CHAR(MCF2.MCF_FECHA1)
                           || RPAD('RET',5,' ')
                           || RPAD('RETENCION EN LA FUENTE',40,' ')
                           || SIGNO                      
                           || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MCF_RETEFUENTE_MOVIMIENTO),'9999999999999999990.00')),22,'0')
                           || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                           || RPAD(' ',40,' ');                
                     p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                     UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                     
                  END IF;
               END IF;
               CLOSE TOF;
            END IF;
            CLOSE OFO;
         ELSIF MCF2.MCF_TMF_MNEMONICO = 'O' THEN 		
            TOTAL := 0;		
            OPEN OFO;
            FETCH OFO INTO OFO1;
            IF OFO%FOUND THEN
               OPEN TOF;
               FETCH TOF INTO TOF1;
               IF TOF%FOUND THEN
                  IF MCF2.MONTO < 0 THEN
                     SIGNO := '-';
                  ELSE
                     SIGNO := '+';
                  END IF;
                  IF OFO1.OFO_TTO_TOF_CODIGO IN ('RP','RT') THEN
                     IF OFO1.OFO_CONCEPTO_COBRO_APT IS NOT NULL THEN
                        IF OFO1.OFO_CONCEPTO_COBRO_APT = 'CCA' THEN
                           TPA1.TPA_DESCRIPCION := 'COBRO COMISION ADMINISTRACION';
                        ELSIF OFO1.OFO_CONCEPTO_COBRO_APT = 'CCR' THEN
                           TPA1.TPA_DESCRIPCION := 'COBRO CAPITALIZACION RETEFUENTE';
                        ELSIF OFO1.OFO_CONCEPTO_COBRO_APT = 'CIC' THEN
                           TPA1.TPA_DESCRIPCION := 'COBRO IVA COMISION DE ADMINISTRACION';
                        ELSIF OFO1.OFO_CONCEPTO_COBRO_APT = 'CDE' THEN
                           TPA1.TPA_DESCRIPCION := 'COMISION DE EXITO';                              
                        END IF;

                        DES := TOF1.TOF_DESCRIPCION|| ' ' ||MCF2.MCF_OFO_CONSECUTIVO;
                        TIPO2 := '02'
                              || TO_CHAR(MCF2.MCF_FECHA1)
                              || TO_CHAR(RPAD(OFO1.OFO_CONCEPTO_COBRO_APT,5,' '))
                              || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                              || SIGNO
                              || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO),'9999999999999999990.00')),22,'0')
                              || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                              || RPAD(DES,40,' ');
                        TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                        p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                        UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                        
                     ELSE
                        OPEN ODP;
                        FETCH ODP INTO ODP1;
                        WHILE ODP%FOUND LOOP
                           OPEN TPA;
                           FETCH TPA INTO TPA1;
                           IF TPA%FOUND THEN               	  	 
                              IF ODP1.ODP_TPA_MNEMONICO = 'CHE' THEN
                                 OPEN CGE;
                                 FETCH CGE INTO CGE1;
                                 IF CGE%FOUND THEN
                                    DES := TOF1.TOF_DESCRIPCION|| ' ' ||MCF2.MCF_OFO_CONSECUTIVO;
                                    TIPO2 := '02'
                                          || TO_CHAR(MCF2.MCF_FECHA1)
                                          || TO_CHAR(RPAD(ODP1.ODP_TPA_MNEMONICO,5,' '))
                                          || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                                          || SIGNO
                                          || LPAD(LTRIM(TO_CHAR(ABS(ODP1.ODP_MONTO_ORDEN),'9999999999999999990.00')),22,'0')
                                          || TO_CHAR(RPAD(NVL(TO_CHAR(CGE1.CEG_NUMERO_CHEQUE),' '),20,' '))
                                          || RPAD(DES,40,' ');
                                    TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                                    p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                                    UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);
                                 END IF;
                                 CLOSE CGE;
                              ELSIF ODP1.ODP_TPA_MNEMONICO = 'ACH' THEN
                                 OPEN PAGOS_ACH(ODP1.ODP_CONSECUTIVO
                                               ,ODP1.ODP_SUC_CODIGO
                                               ,ODP1.ODP_NEG_CONSECUTIVO);
                                 FETCH PAGOS_ACH INTO C_PAGOS_ACH;
                                 WHILE PAGOS_ACH%FOUND LOOP
                                    DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
                                    TIPO2 := '02'
                                          || TO_CHAR(MCF2.MCF_FECHA1)
                                          || TO_CHAR(RPAD(ODP1.ODP_TPA_MNEMONICO,5,' '))
                                          || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                                          || SIGNO
                                          || LPAD(LTRIM(TO_CHAR(ABS(C_PAGOS_ACH.DPA_MONTO),'9999999999999999990.00')),22,'0')
                                          || TO_CHAR(RPAD(NVL(C_PAGOS_ACH.DPA_NUM_IDEN,' '),20,' '))
                                          || RPAD(DES,40,' ');
                                     TOTAL := TOTAL + C_PAGOS_ACH.DPA_MONTO;
                                     p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                                     UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                                     
                                     FETCH PAGOS_ACH INTO C_PAGOS_ACH;
                                  END LOOP;
                                  CLOSE PAGOS_ACH;   
                               ELSIF ODP1.ODP_TPA_MNEMONICO = 'PSE' THEN
                                  DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
                                  TIPO2 := '02'
                                        || TO_CHAR(MCF2.MCF_FECHA1)
                                        || TO_CHAR(RPAD(ODP1.ODP_TPA_MNEMONICO,5,' '))
                                        || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                                        || SIGNO
                                        || LPAD(LTRIM(TO_CHAR(ABS(ODP1.ODP_MONTO_ORDEN),'9999999999999999990.00')),22,'0')
                                        || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                                        || RPAD(DES,40,' ');
                                  TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                                  p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                                  UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                                  
                               ELSE
                                  DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
                                  TIPO2 := '02'
                                        || TO_CHAR(MCF2.MCF_FECHA1)
                                        || TO_CHAR(RPAD(OFO1.OFO_TTO_TOF_CODIGO,5,' '))
                                        || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                                        || SIGNO
                                        || LPAD(LTRIM(TO_CHAR(ABS(ODP1.ODP_MONTO_ORDEN),'9999999999999999990.00')),22,'0')
                                        || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                                        || RPAD(DES,40,' ');
                                  TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                                  p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                                  UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                                  
                               END IF;
             	              END IF;
                            CLOSE TPA;
                            FETCH ODP INTO ODP1;
                         END LOOP;
                         CLOSE ODP;
                         IF TOTAL < ABS(MCF2.MONTO) THEN
     	                      TOTAL := ABS(MCF2.MONTO) - TOTAL;
                            TIPO2 := '02'
                                  || TO_CHAR(MCF2.MCF_FECHA1)
                                  || TO_CHAR(RPAD('ABO',5,' '))
                                  || RPAD('ABONO CUENTA',40,' ')
                                  || SIGNO
                                  || LPAD(LTRIM(TO_CHAR(ABS(TOTAL),'9999999999999999990.00')),22,'0')
                                  || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                                  || RPAD(' ',40,' ');
                            p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                            UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                            
                         END IF;
                      END IF;
                   ELSE
                      IF OFO1.OFO_TTO_TOF_CODIGO = 'INC' AND
                         OFO1.OFO_CONCEPTO_INC_APT IS NOT NULL THEN
                         IF OFO1.OFO_CONCEPTO_INC_APT = 'IRGA' THEN
                            TPA1.TPA_DESCRIPCION := 'RECHAZO GIRO ACH';
                         ELSIF OFO1.OFO_CONCEPTO_INC_APT = 'IANC' THEN
                            TPA1.TPA_DESCRIPCION := 'ANULACION CHEQUE';
                         ELSIF OFO1.OFO_CONCEPTO_INC_APT = 'IDEC' THEN
                            TPA1.TPA_DESCRIPCION := 'DEVOLUCION COMISION';
                         ELSIF OFO1.OFO_CONCEPTO_INC_APT = 'IDIC' THEN
                            TPA1.TPA_DESCRIPCION := 'DEVOLUCION IVA COMISION';                              
                         END IF;

                         DES := TOF1.TOF_DESCRIPCION|| ' ' ||MCF2.MCF_OFO_CONSECUTIVO;
                         TIPO2 := '02'
                               || TO_CHAR(MCF2.MCF_FECHA1)
                               || TO_CHAR(RPAD(OFO1.OFO_CONCEPTO_INC_APT,5,' '))
                               || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                               || SIGNO
                               || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO),'9999999999999999990.00')),22,'0')
                               || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                               || RPAD(DES,40,' ');
                         TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                         p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                         UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                         
                      ELSE                         
                         TIPO2 := '02'
                               || TO_CHAR(MCF2.MCF_FECHA1)
                               || TO_CHAR(RPAD(OFO1.OFO_TTO_TOF_CODIGO,5,' '))
                               || RPAD(TOF1.TOF_DESCRIPCION,40,' ')
                               || SIGNO
                               || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO),'9999999999999999990.00')),22,'0')
                               || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                               || RPAD(' ',40,' ');
                         p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                         UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                         
                      END IF;
                   END IF;
                   IF MCF2.MCF_RETEFUENTE_MOVIMIENTO IS NOT NULL AND MCF2.MCF_RETEFUENTE_MOVIMIENTO <> 0 THEN
   	  		            IF MCF2.MCF_RETEFUENTE_MOVIMIENTO < 0 THEN
                         SIGNO := '-';
                      ELSE
                         SIGNO := '+';
                      END IF;
                      TIPO2 := '02'
                            || TO_CHAR(MCF2.MCF_FECHA1)
                            || RPAD('RET',5,' ')
                            || RPAD('RETENCION EN LA FUENTE',40,' ')
                            || SIGNO                      
                            || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MCF_RETEFUENTE_MOVIMIENTO),'9999999999999999990.00')),22,'0')
                            || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                            || RPAD(' ',40,' ');                
                      p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
                      UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);                      
                   END IF;
                END IF;
                CLOSE TOF;
             END IF;
             CLOSE OFO;      	
         ELSIF MCF2.MCF_TMF_MNEMONICO = 'D' THEN
            OPEN TMF(MCF2.MCF_TMF_MNEMONICO);
            FETCH TMF INTO TMF1;
            IF TMF%FOUND THEN		
               IF MCF2.MONTO2 < 0 THEN
                  SIGNO := '-';
               ELSE
                  SIGNO := '+';
               END IF;
               TIPO2 := '02'
                     || TO_CHAR(MCF2.MCF_FECHA1)
                     || RPAD(MCF2.MCF_TMF_MNEMONICO,5,' ')
                     || RPAD(TMF1.TMF_DESCRIPCION,40,' ')
                     || SIGNO
                     || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO2),'9999999999999999990.00')),22,'0')
                     || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                     || RPAD(' ',40,' ');
               p_mail.write_mb_text(P_CONN,TIPO2||CRLF);    
               UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);               
            END IF;
            CLOSE TMF;
         ELSIF MCF2.MCF_TMF_MNEMONICO = 'C' THEN
            IF MCF2.MCF_RETEFUENTE_MOVIMIENTO < 0 THEN
               SIGNO := '-';
            ELSE
               SIGNO := '+';
            END IF;
            TIPO2 := '02'
                  || TO_CHAR(MCF2.MCF_FECHA1)
                  || RPAD('RET',5,' ')
                  || RPAD('RETENCION EN LA FUENTE',40,' ')
                  || SIGNO
                  || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MCF_RETEFUENTE_MOVIMIENTO),'9999999999999999990.00')),22,'0')
                  || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                  || RPAD(' ',40,' ');
            p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
            UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);
         ELSE
            OPEN TMF(MCF2.MCF_TMF_MNEMONICO);
            FETCH TMF INTO TMF1;
            IF TMF%FOUND THEN		
               IF MCF2.MONTO2 < 0 THEN
                  SIGNO := '-';
               ELSE
                  SIGNO := '+';
               END IF;
               TIPO2 := '02'
                     || TO_CHAR(MCF2.MCF_FECHA1)
                     || RPAD(MCF2.MCF_TMF_MNEMONICO,5,' ')
                     || RPAD(TMF1.TMF_DESCRIPCION,40,' ')
                     || SIGNO
                     || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO2),'9999999999999999990.00')),22,'0')
                     || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                     || RPAD(' ',40,' ');
               p_mail.write_mb_text(P_CONN,TIPO2||CRLF);
               UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO2);               
            END IF;
            CLOSE TMF;        	
         END IF;
         FETCH MCF_MOVIMIENTOS_MES INTO MCF2;
      END LOOP;
      CLOSE MCF_MOVIMIENTOS_MES;      
      OPEN MCF_SALDO_ANTERIOR(P_FECHA_FINAL + 1);
      FETCH MCF_SALDO_ANTERIOR INTO MCF1;
      IF MCF_SALDO_ANTERIOR%FOUND THEN
         TIPO3 := '03'
               || CTA
               || TO_CHAR(P_FECHA_FINAL,'YYYYMMDD')
               || LPAD(LTRIM(TO_CHAR(ABS(MCF1.SALDO),'9999999999999999990.00')),22,'0');
      ELSE
         TIPO3 := '03'
               || CTA
               || TO_CHAR(P_FECHA_FINAL,'YYYYMMDD')
               || LPAD(LTRIM(TO_CHAR(0,'9999999999999999990.00')),22,'0');
      END IF;
      CLOSE MCF_SALDO_ANTERIOR;
      p_mail.write_mb_text(P_CONN,TIPO3||CRLF);
      UTL_FILE.PUT_LINE(P_ARCHIVO,TIPO3);      
      FETCH CFO INTO CFO1;
   END LOOP;
   CLOSE CFO;
EXCEPTION
   WHEN OTHERS THEN
      p_mail.write_mb_text(P_CONN,'Error en generacion archivo :'||SQLERRM);
      p_mail.end_attachment( CONN => P_CONN );
      p_mail.end_mail( conn => P_CONN );
END  MAIL_EXTRACTO_CLIENTE;

PROCEDURE OPERACIONES IS
   conn             utl_smtp.connection;
   req              utl_http.req;  
   resp             utl_http.resp;
   CRLF             VARCHAR2(2) :=  CHR(13)||CHR(10);  
   NUMERO_DOCUMENTO NUMBER(20);
   DIRECCION        VARCHAR2(1000);   
   TIPO1            VARCHAR2(400);
   TIPO2            VARCHAR2(200);
   VALOR_MOVIMIENTO NUMBER(22,2);
   SUCURSAL         NUMBER(5);
   SIGNO            VARCHAR2(1);
   LONGITUD         INTEGER;
   SUC              VARCHAR2(3);
   SALDO_INI        NUMBER(22,2);
   SALDO_FIN        NUMBER(22,2);
   CIUDAD           VARCHAR2(3);
   CURSOR C_CUENTAS IS
      SELECT DISTINCT MCC_CCC_CLI_PER_NUM_IDEN,
             MCC_CCC_CLI_PER_TID_CODIGO,
             MCC_CCC_NUMERO_CUENTA
        FROM MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_CCC_CLI_PER_NUM_IDEN   = '890100577'
         AND MCC_CCC_CLI_PER_TID_CODIGO = 'NIT'
         AND MCC_FECHA                  >= TRUNC(SYSDATE - 1)
         AND MCC_FECHA                  < SYSDATE;
   CUENTAS C_CUENTAS%ROWTYPE;
   CURSOR C_SALDOS (P_FECHA DATE)IS
      SELECT NVL(MCC_SALDO,0) +
             NVL(MCC_SALDO_A_PLAZO,0) +
             NVL(MCC_SALDO_A_CONTADO,0) +
             NVL(MCC_SALDO_ADMON_VALORES,0) + 
             NVL(MCC_SALDO_BURSATIL,0) VALOR_MOVIMIENTO
        FROM MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_CCC_CLI_PER_NUM_IDEN   = CUENTAS.MCC_CCC_CLI_PER_NUM_IDEN
         AND MCC_CCC_CLI_PER_TID_CODIGO = CUENTAS.MCC_CCC_CLI_PER_TID_CODIGO
         AND MCC_CCC_NUMERO_CUENTA      = CUENTAS.MCC_CCC_NUMERO_CUENTA         
         AND MCC_FECHA                  < TRUNC(P_FECHA)
       ORDER BY MCC_CONSECUTIVO DESC;
   SALDOS C_SALDOS%ROWTYPE;
   CURSOR C_MCC IS
      SELECT MCC_CCC_CLI_PER_NUM_IDEN,
             MCC_CCC_CLI_PER_TID_CODIGO,
             MCC_TMC_MNEMONICO,
             MCC_CCC_NUMERO_CUENTA,
             MCC_FECHA,
             MCC_RCA_CONSECUTIVO NUMERO_DOCUMENTO1,
             MCC_CEG_CONSECUTIVO NUMERO_DOCUMENTO2,
             MCC_CGE_CONSECUTIVO NUMERO_DOCUMENTO3,
             MCC_TBC_CONSECUTIVO NUMERO_DOCUMENTO4,
             MCC_TCC_CONSECUTIVO NUMERO_DOCUMENTO5,
             MCC_ACL_CONSECUTIVO NUMERO_DOCUMENTO6,
             MCC_CDE_CONSECUTIVO NUMERO_DOCUMENTO7,
             MCC_FAV_CONSECUTIVO NUMERO_DOCUMENTO8,
             MCC_OCR_CONSECUTIVO NUMERO_DOCUMENTO9,
             MCC_ORD_CONSECUTIVO NUMERO_DOCUMENTO10,
             MCC_OFO_CONSECUTIVO NUMERO_DOCUMENTO11,
             MCC_LIC_NUMERO_OPERACION NUMERO_DOCUMENTO12,
             MCC_TLO_CODIGO NUMERO_DOCUMENTO13,
             MCC_LOP_NUMERO_OPERACION NUMERO_DOCUMENTO14,
             MCC_CMP_NUMERO_OPERACION NUMERO_DOCUMENTO15,
             MCC_MTO_PCC_CONSECUTIVO NUMERO_DOCUMENTO16,
             NVL(MCC_MONTO,0) +
             NVL(MCC_MONTO_A_PLAZO,0) +
             NVL(MCC_MONTO_A_CONTADO,0) +
             NVL(MCC_MONTO_ADMON_VALORES,0) +
             NVL(MCC_MONTO_BURSATIL,0) VALOR_MOVIMIENTO,
             TMC_DESCRIPCION,
             MCC_SUC_CODIGO,
             MCC_OCR_SUC_CODIGO,
             MCC_ORD_SUC_CODIGO,
             MCC_OFO_SUC_CODIGO,
             MCC_LIC_BOL_MNEMONICO,
             MCC_LIC_NUMERO_OPERACION,
             MCC_LIC_NUMERO_FRACCION,
             MCC_LIC_TIPO_OPERACION
        FROM MOVIMIENTOS_CUENTA_CORREDORES,
             TIPOS_MOVIMIENTO_CORREDORES
       WHERE MCC_TMC_MNEMONICO          = TMC_MNEMONICO
         AND MCC_CCC_CLI_PER_NUM_IDEN   = CUENTAS.MCC_CCC_CLI_PER_NUM_IDEN
         AND MCC_CCC_CLI_PER_TID_CODIGO = CUENTAS.MCC_CCC_CLI_PER_TID_CODIGO
         AND MCC_CCC_NUMERO_CUENTA      = CUENTAS.MCC_CCC_NUMERO_CUENTA
         AND MCC_FECHA                  >= TRUNC(SYSDATE - 1)
         AND MCC_FECHA                  < SYSDATE
         AND MCC_TMC_MNEMONICO          NOT IN ('COPC','CPDV','COPV','CSAV','RCPDV','RCAC','RCAV','RSAV','COBRF','COBRV','ROBRF','ROBRV')
       ORDER BY MCC_CONSECUTIVO ASC;
   MCC C_MCC%ROWTYPE;
   CURSOR C_CCC IS
      SELECT CCC_CLI_PER_NUM_IDEN,
             CCC_CLI_PER_TID_CODIGO
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN   = MCC.MCC_CCC_CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = MCC.MCC_CCC_CLI_PER_TID_CODIGO
         AND CCC_NUMERO_CUENTA      = MCC.MCC_CCC_NUMERO_CUENTA;
   CCC C_CCC%ROWTYPE;
   CURSOR C_PER IS
      SELECT PER_SUC_CODIGO
        FROM PERSONAS
       WHERE PER_NUM_IDEN   = CCC.CCC_CLI_PER_NUM_IDEN
         AND PER_TID_CODIGO = CCC.CCC_CLI_PER_TID_CODIGO;
   PER C_PER%ROWTYPE;
BEGIN
   DIRECCION := 'jruiz@corredores.com';--; lchacon@avianca.com';
   conn := p_mail.begin_mail(sender     => 'MULTICASH@CORREDORES.COM',
                             recipients => DIRECCION,
                             subject    => 'Movimiento diario de operaciones '||TO_CHAR(SYSDATE-1,'DD-MON-YYYY'),
                             mime_type  => p_mail.MULTIPART_MIME_TYPE);
   p_mail.begin_attachment(conn         => conn,
                           mime_type    => RTRIM(TO_CHAR(SYSDATE - 1,'DD/MM/YYYY'),' ')||'/txt',
                           inline       => TRUE,
                           filename     => RTRIM(TO_CHAR(SYSDATE - 1,'DD/MM/YYYY'),' ')||'.txt',
                           transfer_enc => 'text');      
   OPEN C_CUENTAS;
   FETCH C_CUENTAS INTO CUENTAS;
   WHILE C_CUENTAS%FOUND LOOP
      SALDO_INI := 0;
      OPEN C_SALDOS(SYSDATE - 1);
      FETCH C_SALDOS INTO SALDOS;
      CLOSE C_SALDOS;      
      SALDO_INI := SALDOS.VALOR_MOVIMIENTO;
      IF SALDOS.VALOR_MOVIMIENTO >= 0 THEN
         SIGNO := 'C';
      ELSE
         SIGNO := 'D';
      END IF;
      TIPO2 := '01'
            || '000001'
            || LPAD(TO_CHAR(CUENTAS.MCC_CCC_NUMERO_CUENTA),9,'0')
            || TO_CHAR(SYSDATE - 1,'YYYYMMDD')
            || '          '
            || SIGNO
            || LPAD(LTRIM(TO_CHAR(ABS(SALDOS.VALOR_MOVIMIENTO),'9999999999990.00')),16,'0')
            || '                                                                                                 '
            || 'S';
      p_mail.write_mb_text(conn,TIPO2||CRLF);      
      OPEN C_MCC;
      FETCH C_MCC INTO MCC;
      WHILE C_MCC%FOUND LOOP
         NUMERO_DOCUMENTO := NULL;
         IF MCC.NUMERO_DOCUMENTO1 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO1;
         ELSIF MCC.NUMERO_DOCUMENTO2 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO2;
         ELSIF MCC.NUMERO_DOCUMENTO3 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO3;
         ELSIF MCC.NUMERO_DOCUMENTO4 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO4;
         ELSIF MCC.NUMERO_DOCUMENTO5 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO5;
         ELSIF MCC.NUMERO_DOCUMENTO6 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO6;
         ELSIF MCC.NUMERO_DOCUMENTO7 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO7;
         ELSIF MCC.NUMERO_DOCUMENTO8 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO8;
         ELSIF MCC.NUMERO_DOCUMENTO9 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO9;
         ELSIF MCC.NUMERO_DOCUMENTO10 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO10;
         ELSIF MCC.NUMERO_DOCUMENTO11 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO11;
         ELSIF MCC.NUMERO_DOCUMENTO12 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO12;
         ELSIF MCC.NUMERO_DOCUMENTO13 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO13;
         ELSIF MCC.NUMERO_DOCUMENTO14 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO14;
         ELSIF MCC.NUMERO_DOCUMENTO15 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO15;
         ELSIF MCC.NUMERO_DOCUMENTO16 IS NOT NULL THEN
            NUMERO_DOCUMENTO := MCC.NUMERO_DOCUMENTO16;
         ELSE
            NUMERO_DOCUMENTO := 0;
         END IF;
         SELECT LENGTH(NUMERO_DOCUMENTO)
           INTO LONGITUD
           FROM DUAL;
         IF MCC.NUMERO_DOCUMENTO12 IS NOT NULL THEN
            NUMERO_DOCUMENTO := SUBSTR(NUMERO_DOCUMENTO,9,LONGITUD);
         END IF;
         VALOR_MOVIMIENTO := NVL(MCC.VALOR_MOVIMIENTO,0);
         SUCURSAL := NULL;
         IF MCC.MCC_SUC_CODIGO IS NOT NULL THEN
            SUCURSAL := MCC.MCC_SUC_CODIGO;
         ELSIF MCC.MCC_OCR_SUC_CODIGO IS NOT NULL THEN
            SUCURSAL := MCC.MCC_OCR_SUC_CODIGO;
         ELSIF MCC.MCC_ORD_SUC_CODIGO IS NOT NULL THEN
            SUCURSAL := MCC.MCC_ORD_SUC_CODIGO;
         ELSIF MCC.MCC_OFO_SUC_CODIGO IS NOT NULL THEN
            SUCURSAL := MCC.MCC_OFO_SUC_CODIGO;
         ELSE
            OPEN C_CCC;
            FETCH C_CCC INTO CCC;
            IF C_CCC%FOUND THEN
               OPEN C_PER;
               FETCH C_PER INTO PER;
               CLOSE C_PER;
            END IF;
            CLOSE C_CCC;
            SUCURSAL := PER.PER_SUC_CODIGO;         
         END IF;
         IF MCC.VALOR_MOVIMIENTO >= 0 THEN
            SIGNO := 'C';
         ELSE
            SIGNO := 'D';
         END IF;
         TIPO1 := NULL;
         IF SUCURSAL IS NULL THEN
            SUC := '   ';
         ELSE
            SUC := LPAD(TO_CHAR(SUCURSAL),3,' ');
         END IF;
         IF SUCURSAL IS NULL THEN
            CIUDAD := '   ';
         ELSE
            IF SUCURSAL IN (1,2) THEN
               CIUDAD := 'BTA';
            ELSIF SUCURSAL = 6 THEN
               CIUDAD := 'BUC';
            ELSIF SUCURSAL = 8 THEN
               CIUDAD := 'MED';
            END IF;
         END IF;
         TIPO1 := '01'
               || LPAD(MCC.MCC_TMC_MNEMONICO,6,'0')
               || LPAD(TO_CHAR(MCC.MCC_CCC_NUMERO_CUENTA),9,'0')
               || TO_CHAR(MCC.MCC_FECHA,'YYYYMMDD')
               || LPAD(TO_CHAR(NUMERO_DOCUMENTO),10,'0')
               || LPAD(LTRIM(TO_CHAR(ABS(VALOR_MOVIMIENTO),'99999999999990.00')),17,'0')
               || SUBSTR(RPAD(MCC.TMC_DESCRIPCION,30,' '),1,30)
               || '                    '
               || '          '
               || SUC
               || CIUDAD
               || '                               '
               || SIGNO;
         p_mail.write_mb_text(conn,TIPO1||CRLF);
      FETCH C_MCC INTO MCC;
      END LOOP;
      CLOSE C_MCC;
      SALDO_FIN := 0;
      OPEN C_SALDOS(SYSDATE);
      FETCH C_SALDOS INTO SALDOS;
      CLOSE C_SALDOS;      
      SALDO_FIN := SALDOS.VALOR_MOVIMIENTO;
      IF SALDOS.VALOR_MOVIMIENTO >= 0 THEN
         SIGNO := 'C';
      ELSE
         SIGNO := 'D';
      END IF;
      TIPO2 := '01'
            || '999999'
            || LPAD(TO_CHAR(CUENTAS.MCC_CCC_NUMERO_CUENTA),9,'0')
            || TO_CHAR(SYSDATE,'YYYYMMDD')
            || '          '
            || SIGNO
            || LPAD(LTRIM(TO_CHAR(ABS(SALDOS.VALOR_MOVIMIENTO),'9999999999990.00')),16,'0')
            || '                                                                                                 '
            || 'S';
      p_mail.write_mb_text(conn,TIPO2||CRLF);
   FETCH C_CUENTAS INTO CUENTAS;
   END LOOP;
   CLOSE C_CUENTAS;
   p_mail.end_attachment( conn => conn );
   p_mail.end_mail( conn => conn );
   EXCEPTION
      WHEN OTHERS THEN
         p_mail.write_mb_text(conn,'Error en generacion archivo :'||SQLERRM);
         p_mail.end_attachment( conn => conn );
         p_mail.end_mail( conn => conn );  
END OPERACIONES;
PROCEDURE MAIL_PROCESO_EXTRACTO_FONDOS (P_TIPO_REPORTE  IN VARCHAR2,
                                        P_FECHA_INICIAL IN DATE DEFAULT NULL,
                                        P_FECHA_FINAL   IN DATE DEFAULT NULL,
                                        P_REPROCESO     IN VARCHAR2 := 'N') IS
    CURSOR mail_empleado IS
      SELECT con_valor_char
      FROM constantes
      WHERE con_mnemonico = 'MEP';

    CURSOR mail_cliente IS
      SELECT DISTINCT 
          ext_cfo_ccc_cli_per_num_iden,
          ext_cfo_ccc_cli_per_tid_codigo,
          ext_cfo_ccc_numero_cuenta,
          EXT_CFO_FON_CODIGO,
          ext_cfo_codigo        
      FROM EXTRACTO_FONDO_PLANO
      WHERE EXT_TIPO_INFORME = 'SAP';

    CURSOR cliente_fondo_mail (p_cli_per_num_iden VARCHAR2,
                          p_cli_per_tid_codigo VARCHAR2,
                          p_ccc_numero_cuenta NUMBER,
                          p_cfo_fon_codigo VARCHAR2,
                          p_cfo_codigo NUMBER)IS
      SELECT DISTINCT 
        CRMF_CORREO ext_direccion
      FROM fondos,
           extracto_fondo_plano
           INNER JOIN CORREOS_MULTICASH_FONDOS
           ON EXT_CONSECUTIVO = CRMF_EXT_CONSECUTIVO
      WHERE fon_codigo = ext_cfo_fon_codigo
        AND ext_tipo_informe = 'SAP'
        AND ext_cfo_ccc_cli_per_num_iden = p_cli_per_num_iden
        AND EXT_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
        AND ext_cfo_ccc_numero_cuenta = p_ccc_numero_cuenta
        AND EXT_CFO_FON_CODIGO = P_CFO_FON_CODIGO
        AND EXT_CFO_CODIGO = P_CFO_CODIGO;

    CURSOR cliente_fondo (p_cli_per_num_iden VARCHAR2,
                          p_cli_per_tid_codigo VARCHAR2,
                          p_ccc_numero_cuenta NUMBER,
                          p_cfo_fon_codigo VARCHAR2,
                          p_cfo_codigo NUMBER)IS
      SELECT DISTINCT 
        ext_cfo_ccc_cli_per_num_iden,
        ext_cfo_ccc_cli_per_tid_codigo,
        ext_cfo_ccc_numero_cuenta,
        ext_cfo_fon_codigo,
        ext_cfo_codigo,
        fon_razon_social,
        ext_cfo_ccc_cli_per_num_iden||
        decode(ext_cfo_ccc_cli_per_tid_codigo,'NIT','1')||
        EXT_CFO_CCC_NUMERO_CUENTA EXT_CUENTA,
        NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) fon_mnemonico
      FROM fondos,
           extracto_fondo_plano
      WHERE fon_codigo = ext_cfo_fon_codigo
        AND ext_tipo_informe = 'SAP'
        AND ext_cfo_ccc_cli_per_num_iden = p_cli_per_num_iden
        AND EXT_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
        AND ext_cfo_ccc_numero_cuenta = p_ccc_numero_cuenta
        AND EXT_CFO_FON_CODIGO = P_CFO_FON_CODIGO
        AND EXT_CFO_CODIGO = P_CFO_CODIGO;

  v_direccion_mail     VARCHAR2(4000);      
  v_direccion_mail_emp VARCHAR2(4000);
  v_error_mail         VARCHAR2(4000);      
  v_subject_error      VARCHAR2(4000);
  v_cuerpo_error       VARCHAR2(4000);
  v_msj_error          VARCHAR2(4000);  
  v_fecha_proceso_ini  DATE;
  v_fecha_proceso_fin  DATE;
  v_error              EXCEPTION;
  conn                 utl_smtp.connection;      
  c_cliente_fondo_mail cliente_fondo_mail%ROWTYPE;  
  c_cliente_fondo      cliente_fondo%ROWTYPE; 
  c_mail_cliente       mail_cliente%ROWTYPE;
BEGIN
  v_direccion_mail   := ' ';
  v_subject_error    := ' ';
  v_cuerpo_error     := ' ';
  v_msj_error        := ' ';
  -- P_TIPO_REPORTE = D = DIORA R = RANGO
  IF P_TIPO_REPORTE  = 'D' THEN
    SELECT trunc(SYSDATE-1) INTO v_fecha_proceso_ini FROM DUAL;
    SELECT trunc(SYSDATE) INTO v_fecha_proceso_fin FROM DUAL;
  ELSIF P_TIPO_REPORTE  = 'R' THEN
    v_fecha_proceso_ini := TRUNC(P_FECHA_INICIAL);
    v_fecha_proceso_fin := TRUNC(P_FECHA_FINAL+1);
  END IF;
  OPEN MAIL_EMPLEADO;
  FETCH mail_empleado INTO v_direccion_mail_emp;
  IF mail_empleado%NOTFOUND THEN
    /* Definir direccion alterna de envio de corro*/
    v_direccion_mail_emp := 'aangel@corredores.com';
    v_subject_error := 'No existe direcion de correo valida';
    v_cuerpo_error  := 'La constante MEP no definida en el sistema';
    RAISE v_error;
  END IF;
  CLOSE MAIL_EMPLEADO;
  v_error_mail := v_direccion_mail_emp;
  OPEN mail_cliente;
  FETCH mail_cliente INTO c_mail_cliente;
  WHILE mail_cliente%FOUND  LOOP
    V_DIRECCION_MAIL := v_direccion_mail_emp;
    OPEN cliente_fondo_mail(c_mail_cliente.ext_cfo_ccc_cli_per_num_iden,
                       c_mail_cliente.ext_cfo_ccc_cli_per_tid_codigo,
                       c_mail_cliente.ext_cfo_ccc_numero_cuenta,
                       c_mail_cliente.ext_cfo_fon_codigo,
                       c_mail_cliente.ext_cfo_codigo);
    FETCH cliente_fondo_mail INTO c_cliente_fondo_mail;
    WHILE cliente_fondo_mail%FOUND LOOP
      v_direccion_mail := v_direccion_mail||';'||c_cliente_fondo_mail.ext_direccion;
      FETCH cliente_fondo_mail INTO c_cliente_fondo_mail;
    END LOOP;
    CLOSE cliente_fondo_mail;
--dbms_output.put_line('direcciones :'|| v_direccion_mail);   
    OPEN cliente_fondo(c_mail_cliente.ext_cfo_ccc_cli_per_num_iden,
                       c_mail_cliente.ext_cfo_ccc_cli_per_tid_codigo,
                       c_mail_cliente.ext_cfo_ccc_numero_cuenta,
                       c_mail_cliente.ext_cfo_fon_codigo,
                       c_mail_cliente.ext_cfo_codigo);
    FETCH cliente_fondo INTO c_cliente_fondo;
    WHILE cliente_fondo%FOUND LOOP
      p_mail_extracto_cliente.mail_extracto_fondos(P_CLI_PER_NUM_IDEN   => c_cliente_fondo.ext_cfo_ccc_cli_per_num_iden,
                                                   P_CLI_PER_TID_CODIGO => c_cliente_fondo.ext_cfo_ccc_cli_per_tid_codigo,                               
                                                   P_NUMERO_CUENTA      => c_cliente_fondo.ext_cfo_ccc_numero_cuenta,
                                                   P_FON_CODIGO         => c_cliente_fondo.ext_cfo_fon_codigo,
                                                   P_FON_DESCRIPCION    => c_cliente_fondo.fon_razon_social,
                                                   P_CUENTA_FONDO       => c_cliente_fondo.ext_cfo_codigo,
                                                   P_CADENA_ENVIO       => v_direccion_mail,
                                                   P_FECHA_PROCESO_INI  => v_fecha_proceso_ini,
                                                   P_FECHA_PROCESO_FIN  => v_fecha_proceso_fin,
                                                   P_CUENTA             => c_cliente_fondo.ext_cuenta,
                                                   P_ERRORES            => v_msj_error,
                                                   P_FON_MNEMONICO      => c_cliente_fondo.fon_mnemonico,
                                                   P_REPROCESO          => P_REPROCESO);
      IF nvl(trim(v_msj_error),' ') != ' 'THEN
        /* Definir direccion alterna de envio de corro*/
        v_direccion_mail := v_error_mail;
        v_subject_error := 'Error en proceso p_mail_extracto_cliente.mail_extracto_fondos';
        v_cuerpo_error  := v_msj_error;
        RAISE v_error;
      END IF;  
      FETCH cliente_fondo INTO c_cliente_fondo;    
    END LOOP;
    CLOSE cliente_fondo;
    FETCH mail_cliente INTO c_mail_cliente;
  END LOOP;
  CLOSE mail_cliente ;
  EXCEPTION 
    WHEN v_error THEN
      conn := p_mail.begin_mail(sender     => 'administrador@corredores.com',
                                recipients => v_error_mail,
                                subject    => v_subject_error,
                                mime_type  => p_mail.MULTIPART_MIME_TYPE);
      p_mail.attach_text(conn      => conn,
                         data      => '<h1>'||v_cuerpo_error||'</h1>',
                         mime_type => 'text/html');
      p_mail.end_mail( conn => conn );     
   WHEN OTHERS THEN   
     /* ojo verificar */
     v_direccion_mail := v_error_mail;
     v_subject_error := 'Error en proceso p_mail_extracto_cliente.mail_extracto_fondos ';
     v_cuerpo_error  := 'Error no determinado :'||SQLERRM;
     conn := p_mail.begin_mail(sender     => 'administrador@corredores.com',
                                recipients => v_direccion_mail,
                                subject    => v_subject_error,
                                mime_type  => p_mail.MULTIPART_MIME_TYPE);
     p_mail.attach_text(conn      => conn,
                         data      => '<h1>'||v_cuerpo_error||'</h1>',
                         mime_type => 'text/html');
     p_mail.end_mail( conn => conn );     
END MAIL_PROCESO_EXTRACTO_FONDOS;
PROCEDURE MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   IN VARCHAR2 DEFAULT NULL,
                               P_CLI_PER_TID_CODIGO IN VARCHAR2 DEFAULT NULL,                               
                               P_NUMERO_CUENTA      IN NUMBER   DEFAULT NULL,
                               P_FON_CODIGO         IN VARCHAR2 DEFAULT NULL,
                               P_FON_DESCRIPCION    IN VARCHAR2 DEFAULT NULL,
                               P_CUENTA_FONDO       IN NUMBER   DEFAULT NULL,
                               P_CADENA_ENVIO       IN VARCHAR2 DEFAULT NULL,
                               P_FECHA_PROCESO_INI  IN DATE     DEFAULT NULL,
                               P_FECHA_PROCESO_FIN  IN DATE     DEFAULT NULL,
                               P_CUENTA             IN VARCHAR2 DEFAULT NULL,
                               P_ERRORES            IN OUT VARCHAR2,
                               P_FON_MNEMONICO      IN VARCHAR2 DEFAULT NULL,
                               P_REPROCESO          IN VARCHAR2 := 'N') IS

  CURSOR C_CONSECUTIVO IS
     SELECT CON_VALOR
     FROM   CONSTANTES
     WHERE  CON_MNEMONICO = 'CET';

  CURSOR saldo_anterior IS
    SELECT   mcf_saldo_capital +
             mcf_saldo_rendimientos_rf +
             mcf_saldo_rendimientos_rv saldo,
             mcf_cfo_ccc_cli_per_num_iden,
             mcf_cfo_ccc_cli_per_tid_codigo,
             mcf_cfo_ccc_numero_cuenta,
             mcf_cfo_codigo
    FROM  movimientos_cuentas_fondos
    WHERE mcf_cfo_ccc_cli_per_num_iden   = p_cli_per_num_iden
      AND mcf_cfo_ccc_cli_per_tid_codigo = p_cli_per_tid_codigo
      AND mcf_cfo_ccc_numero_cuenta      = p_numero_cuenta
      AND mcf_cfo_fon_codigo             = p_fon_codigo
      AND mcf_cfo_codigo                 = p_cuenta_fondo
      AND mcf_fecha                      < p_fecha_proceso_ini
    ORDER BY  mcf_consecutivo DESC;
  CURSOR movimiento_dia IS
    SELECT to_char(mcf_fecha,'dd.mm.yy') mcf_fecha1,
             mcf_tmf_mnemonico,
             mcf_ofo_consecutivo,
             mcf_ofo_suc_codigo,
             mcf_retefuente_movimiento,
             mcf_capital +
             mcf_rendimientos_rf +
             mcf_rendimientos_rv -
             mcf_retefuente_movimiento monto,      
             mcf_capital +
             mcf_rendimientos_rf +
             mcf_rendimientos_rv monto2,
             mcf_saldo_capital +
             mcf_saldo_rendimientos_rf +
             mcf_saldo_rendimientos_rv saldo_final,
             ofo_tto_tof_codigo
    FROM ordenes_fondos,
         movimientos_cuentas_fondos
    WHERE ofo_consecutivo(+)             = mcf_ofo_consecutivo
      AND ofo_suc_codigo(+)              = mcf_ofo_suc_codigo
      AND mcf_cfo_ccc_cli_per_num_iden   = p_cli_per_num_iden
      AND mcf_cfo_ccc_cli_per_tid_codigo = p_cli_per_tid_codigo
      AND mcf_cfo_ccc_numero_cuenta      = p_numero_cuenta
      AND mcf_cfo_fon_codigo             = p_fon_codigo
      AND mcf_cfo_codigo                 = p_cuenta_fondo
      AND mcf_fecha                      >= p_fecha_proceso_ini
      AND mcf_fecha                      <  p_fecha_proceso_fin
    ORDER BY  mcf_consecutivo ASC;       
  CURSOR pagos (P_MCF_SUC_CODIGO      NUMBER,
                P_MCF_OFO_CONSECUTIVO NUMBER)IS
      SELECT odp_tpa_mnemonico,
             odp_monto_orden,
             odp_neg_consecutivo,
             odp_suc_codigo,
             odp_ceg_consecutivo,
             odp_ccc_cli_per_num_iden,
             odp_ocl_cli_per_num_iden_relac,
             odp_num_iden,
             odp_pagar_a,
             ceg_numero_cheque
        FROM comprobantes_de_egreso,
             ordenes_de_pago
       WHERE ceg_suc_codigo(+)      = odp_suc_codigo
         AND ceg_neg_consecutivo(+) = odp_neg_consecutivo
         AND ceg_consecutivo (+)    = odp_ceg_consecutivo
         AND odp_estado            != 'ANU'
         AND odp_ofo_suc_codigo     = P_MCF_SUC_CODIGO
         AND odp_ofo_consecutivo    = P_MCF_OFO_CONSECUTIVO;
  conn                utl_smtp.connection;
  CRLF                VARCHAR2(2) :=  CHR(13)||CHR(10);                                
  v_archivo_cabecera  VARCHAR2(10);
  v_archivo_detalle   VARCHAR(10);
  v_signo             VARCHAR2(1);
  v_signo_saldo_final VARCHAR2(1);
  v_linea             VARCHAR2(4000);
  v_separador         VARCHAR2(1) := ';';
  v_total_debitos     NUMBER;
  v_total_creditos    NUMBER;
  v_total_pagos       NUMBER;
  v_total_lineas      NUMBER;
  v_saldo_final       NUMBER;
  v_numero_extracto   NUMBER;
  c_movimiento_dia    movimiento_dia%ROWTYPE; 
  c_saldo_anterior    saldo_anterior%ROWTYPE; 
  c_pagos             pagos%ROWTYPE;
  EXTRACTO_ARCHIVO     UTL_FILE.FILE_TYPE;  
BEGIN  
  v_archivo_cabecera  := 'CC'||TO_CHAR(P_FECHA_PROCESO_FIN-1,'DDMM')||lpad(TO_CHAR(p_cuenta_fondo),2,'00');
  v_archivo_detalle   := 'CD'||TO_CHAR(P_FECHA_PROCESO_FIN-1,'DDMM')||lpad(TO_CHAR(p_cuenta_fondo),2,'00');
  v_archivo_cabecera  := trim(v_archivo_cabecera);
  v_archivo_detalle   := trim(v_archivo_detalle);
  v_total_debitos     := 0;
  v_total_creditos    := 0;
  v_total_lineas      := 0;
  v_saldo_final       := 0;

  /* Obtener numero de extracto */

  OPEN C_CONSECUTIVO;
  FETCH C_CONSECUTIVO INTO V_NUMERO_EXTRACTO;
  CLOSE C_CONSECUTIVO;

  IF P_REPROCESO = 'N' THEN
    V_NUMERO_EXTRACTO := NVL(V_NUMERO_EXTRACTO,0) + 1;
  ELSE
    V_NUMERO_EXTRACTO := NVL(V_NUMERO_EXTRACTO,0);
  END IF; 


--  SELECT EXT_SEQ_MAIL.NEXTVAL INTO v_numero_extracto FROM DUAL;

  /* Inicio cracion achivo detalle */
  conn := p_mail.begin_mail(sender     => 'MULTICASH@CORREDORES.COM',
                            recipients   => P_CADENA_ENVIO,
                            subject      => 'Informacion fondo '||P_FON_CODIGO||'-'||P_FON_DESCRIPCION,
                            mime_type    => p_mail.MULTIPART_MIME_TYPE);
  p_mail.attach_text(conn      => conn,
                     data      => '<html>'||
                                     '<head>'||
                                       '<IMG src=http://www.corredores.com/portal/eContent/images/Banners/BannerNo1.jpg>'||
                                     '</head>'||
                                     '<body FACE=arial> '||
                                       '<br><br><br><br><br><br>'||
                                       '<table>'||
                                         '<font size=2 face=Arial Black>'||
                                         '<tr>'||
                                          'Estamos remitiendo informacion del movimiento del fondo '||P_FON_CODIGO||' '||
                                           P_FON_DESCRIPCION||' '||
                                          ' con fecha de corte al :'||to_char(P_FECHA_PROCESO_FIN-1,'dd-mon-yyyy')||'</tr>'||
                                         '<tr></tr>'||
                                         '<br><br><br><br><br><br>'||
                                         '<tr>'||' Atentamente, '||'</tr>'||
                                         '<br><br><br><br>'||
                                         '<tr><B>'||'DAVIVIENDA CORREDORES. '||'</B></tr>'||
                                          '</font>'||
                                         '<br><br><br><br><br><br>'||
                                       '</table>'||
                                       '<br><br><br>'||
                                    '</body>'||
                                  '</html>',
                     mime_type => 'text/html');
  p_mail.begin_attachment(conn         => conn,
                           mime_type    => v_archivo_detalle||'/txt',
                           inline       => TRUE,
                           filename     => v_archivo_detalle||'.txt',
                           transfer_enc => 'text'); 

  EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR',
                      P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || P_FON_MNEMONICO
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '-' || 'DC'
                    || '.txt','W');

  /* reporte de movimientos del dia */
  OPEN movimiento_dia;
  FETCH movimiento_dia INTO c_movimiento_dia;
  WHILE movimiento_dia%FOUND LOOP    
    v_saldo_final := c_movimiento_dia.saldo_final;
    IF c_movimiento_dia.mcf_tmf_mnemonico = 'R' THEN    
      IF c_movimiento_dia.monto < 0 THEN
        v_signo := '-';
        v_total_debitos := v_total_debitos + abs(c_movimiento_dia.monto);
      ELSE
        v_signo := '+';
        v_total_creditos := v_total_creditos + abs(c_movimiento_dia.monto);
      END IF;
      v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --TRIM(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                              -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                'R'||trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                              --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.monto),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente 
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado
      p_mail.write_mb_text(conn,v_linea||CRLF);
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);
      v_total_lineas := v_total_lineas+1;
      IF NVL(c_movimiento_dia.mcf_retefuente_movimiento,0) <> 0 THEN
        IF c_movimiento_dia.mcf_retefuente_movimiento < 0 THEN
          v_signo := '-';
          v_total_debitos := v_total_debitos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
        ELSE
          v_signo := '+';
          v_total_creditos := v_total_creditos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
        END IF;
        v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 'RRET'||v_separador||                                                                                        --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.mcf_retefuente_movimiento),'999999999999999990.00'))||v_separador||        --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente 
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado
        p_mail.write_mb_text(conn,v_linea||CRLF);
        UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);        
        v_total_lineas := v_total_lineas+1;
      END IF;
    ELSIF c_movimiento_dia.mcf_tmf_mnemonico = 'O' THEN    
      IF c_movimiento_dia.monto < 0 THEN
        v_signo := '-';
        v_total_debitos := v_total_debitos + abs(c_movimiento_dia.monto);
      ELSE
        v_signo := '+';
        v_total_creditos := v_total_creditos + abs(c_movimiento_dia.monto);
      END IF;
      IF c_movimiento_dia.ofo_tto_tof_codigo IN ('RP','RT') THEN      
        v_total_pagos       := 0;
        OPEN pagos(c_movimiento_dia.mcf_ofo_suc_codigo,c_movimiento_dia.mcf_ofo_consecutivo);
        FETCH pagos INTO c_pagos;
        WHILE pagos%FOUND LOOP
          IF c_pagos.odp_tpa_mnemonico = 'CHE' THEN
            v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                              --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 trim(c_pagos.ceg_numero_cheque)||v_separador||                                                            --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_pagos.odp_monto_orden),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador;                                                                                              --16. no usado                 
                 IF c_pagos.odp_pagar_a = 'C' THEN
                   v_linea := v_linea||c_pagos.odp_ccc_cli_per_num_iden||v_separador;                                                         --17. nit cliente 
                 ELSIF c_pagos.odp_pagar_a = 'O' THEN
                   v_linea := v_linea||c_pagos.odp_ocl_cli_per_num_iden_relac||v_separador;                                                   --17. nit o cliente
                 ELSIF c_pagos.odp_pagar_a = 'T' THEN
                   v_linea := v_linea||trim(TO_CHAR(c_pagos.odp_num_iden))||v_separador;                                                      --17. nit tercero
                 END IF;
                 v_linea := v_linea||'/'||v_separador||                                                                     --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado            
            v_total_pagos := v_total_pagos+c_pagos.odp_monto_orden;
            p_mail.write_mb_text(conn,v_linea||CRLF);   
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
          ELSE
            v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                                  --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_pagos.odp_monto_orden),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado            
            v_total_pagos := v_total_pagos+c_pagos.odp_monto_orden;
            p_mail.write_mb_text(conn,v_linea||CRLF);   
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
          END IF;
          FETCH pagos INTO c_pagos;
        END LOOP;
        CLOSE pagos;
        IF v_total_pagos < abs(c_movimiento_dia.monto) THEN
          v_total_pagos := c_movimiento_dia.monto - v_total_pagos;          
          v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 'ABO'||v_separador||                                                                                       --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(v_total_pagos),'999999999999999990.00'))||v_separador||                               --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado            
            p_mail.write_mb_text(conn,v_linea||CRLF);   
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
        END IF;
      ELSE
        v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                                                                       --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.monto),'999999999999999990.00'))||v_separador||                 --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado            
            p_mail.write_mb_text(conn,v_linea||CRLF);
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
      END IF;
      IF nvl(c_movimiento_dia.mcf_retefuente_movimiento,0) <> 0 THEN
        IF c_movimiento_dia.mcf_retefuente_movimiento < 0 THEN
          v_signo := '-';
          v_total_debitos := v_total_debitos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
        ELSE
          v_signo := '+';
          v_total_creditos := v_total_creditos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
        END IF;
        v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 'RET'||v_separador||                                                                                       --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.mcf_retefuente_movimiento),'999999999999999990.00'))||v_separador||         --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado
            p_mail.write_mb_text(conn,v_linea||CRLF); 
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
      END IF;
    ELSIF c_movimiento_dia.mcf_tmf_mnemonico= 'D' THEN
      IF c_movimiento_dia.monto2 < 0 THEN
        v_signo := '-';
        v_total_debitos := v_total_debitos + abs(c_movimiento_dia.monto2);
      ELSE
        v_signo := '+';
        v_total_creditos := v_total_creditos + abs(c_movimiento_dia.monto2);
      END IF;
      v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria                 
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 c_movimiento_dia.mcf_tmf_mnemonico||v_separador||                                                          --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.monto2),'999999999999999990.00'))||v_separador||                             --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado
            p_mail.write_mb_text(conn,v_linea||CRLF);    
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
    ELSIF c_movimiento_dia.mcf_tmf_mnemonico = 'C' THEN    
      IF c_movimiento_dia.mcf_retefuente_movimiento < 0 THEN
        v_signo := '-';
        v_total_debitos := v_total_debitos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
      ELSE
        v_signo := '+';
        v_total_creditos := v_total_creditos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
      END IF;
      v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 'RET'||v_separador||                                                                                       --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.mcf_retefuente_movimiento),'999999999999999990.00'))||v_separador||         --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado
            p_mail.write_mb_text(conn,v_linea||CRLF);   
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
            v_total_lineas := v_total_lineas+1;
    ELSE
      IF c_movimiento_dia.monto2 < 0 THEN
        v_signo := '-';
        v_total_debitos := v_total_debitos + abs(c_movimiento_dia.monto2);
      ELSE
        v_signo := '+';
        v_total_creditos := v_total_creditos + abs(c_movimiento_dia.monto2);
      END IF;
      v_linea := '026'||v_separador||                                                                                      -- 1. clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                 v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                 v_separador||                                                                                              --5. no usado
                 v_separador||                                                                                              --6. no usado
                 c_movimiento_dia.mcf_tmf_mnemonico||v_separador||                                                          --7. codigo interno de la transaccion
                 v_separador||                                                                                              --8. no usado
                 v_separador||                                                                                              --9. no usado
                 '/'||v_separador||                                                                                         --10.numero de cheques default  /
                 v_signo||trim(to_char(abs(c_movimiento_dia.monto2),'999999999999999990.00'))||v_separador||                             --11.valor movimiento
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --14. fecha origen movimiento
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado                                  
                 P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                 '/'||v_separador||                                                                                         --18. default  /
                 'NO INFORMA'||v_separador||                                                                                --19. Valor por default
                 '/'||v_separador||                                                                                         --20. causal de rechazo default /
                 '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                 '/'||v_separador||                                                                                         --22. default /
                 v_separador||                                                                                              --23. no usado
                 v_separador||                                                                                              --24. no usado
                 v_separador||                                                                                              --25. no usado
                 v_separador||                                                                                              --26. no usado
                 v_separador||                                                                                              --27. no usado
                 v_separador||                                                                                              --28. no usado
                 v_separador||                                                                                              --29. no usado
                 v_separador||                                                                                              --30. no usado
                 v_separador||                                                                                              --31. no usado
                 v_separador||                                                                                              --32. no usado
                 v_separador||                                                                                              --33. no usado
                 v_separador||                                                                                              --34. no usado
                 v_separador||                                                                                              --35. no usado
                 v_separador;                                                                                               --36  no usado
            p_mail.write_mb_text(conn,v_linea||CRLF);        
            UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);
            v_total_lineas := v_total_lineas+1;
    END IF;
    FETCH movimiento_dia INTO c_movimiento_dia;
  END LOOP;
  CLOSE movimiento_dia;
  p_mail.end_attachment( conn => conn );
  UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);

  /* Creacion de archivo cabecero*/
  OPEN saldo_anterior;
  FETCH  saldo_anterior INTO c_saldo_anterior;
  CLOSE saldo_anterior;
  IF c_saldo_anterior.saldo < 0 THEN
    v_signo := '-';
  ELSE
    v_signo := '+';
  END IF;
  IF v_saldo_final < 0 THEN
    v_signo_saldo_final := '-';
  ELSE
    v_signo_saldo_final := '+';
  END IF;

  --v_total_debitos := v_total_debitos + abs(c_movimiento_dia.monto2);
  --v_total_creditos := v_total_creditos + abs(c_movimiento_dia.monto2);

  v_linea := '026'||v_separador||                                                                                         -- 1.clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2.cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2.cuenta bancaria
                 v_numero_extracto||v_separador||                                                                         -- 3.consecutivo extracto
                 to_char(P_FECHA_PROCESO_FIN-1,'dd.mm.yy')||v_separador||                                                 -- 4.fecha movimiento afecto el saldo
                 'COP'||v_separador||                                                                                     -- 5.Base monetaria
                 v_signo||trim(to_char(abs(c_saldo_anterior.saldo),'999999999999999990.00'))||v_separador||               -- 6.saldo inicial cuenta
                 '-'||trim(to_char(abs(v_total_debitos),'999999999999999990.00'))||v_separador||                          -- 7.total debitos
                 '+'||trim(to_char(abs(v_total_creditos),'999999999999999990.00'))||v_separador||                         -- 8.total creditos
                 v_signo_saldo_final||trim(to_char(abs(v_saldo_final),'999999999999999990.00'))||v_separador||            -- 9.saldo final cuennta
                 '03'||                                                                                                   --10.Codigo tipo cuenta
                 v_separador||                                                                                              --11. no usado
                 v_separador||                                                                                              --12. no usado
                 v_separador||                                                                                              --13. no usado
                 v_separador||                                                                                              --14. no usado
                 v_separador||                                                                                              --15. no usado
                 v_separador||                                                                                              --16. no usado
                 v_separador||                                                                                              --17. no usado
                 trim(to_char(abs(v_total_lineas),'99999'));                                                                --18.saldo inicial cuenta
  p_mail.begin_attachment(conn         => conn,
                           mime_type    => v_archivo_cabecera||'/txt',
                           inline       => TRUE,
                           filename     => v_archivo_cabecera||'.txt',
                           transfer_enc => 'text');      
  EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR',
                      P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || P_FON_MNEMONICO
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '-' || 'CC'
                    || '.txt','W');
  p_mail.write_mb_text(conn,v_linea||CRLF);                   
  UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);
  p_mail.end_attachment( conn => conn );
  UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);  
  p_mail.end_mail( conn => conn );        

  IF P_REPROCESO = 'N' THEN
    UPDATE CONSTANTES
    SET    CON_VALOR = V_NUMERO_EXTRACTO
    WHERE  CON_MNEMONICO = 'CET';
    COMMIT;
  END IF;

  EXCEPTION
      WHEN OTHERS THEN
         p_errores :='Error en generacion plano :'||P_CLI_PER_NUM_IDEN||' con fecha de corte al :'||to_char(p_fecha_proceso_fin,'dd-mon-yyyy');
         UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);           
         RETURN;
END MAIL_EXTRACTO_FONDOS;  
END;

/

  GRANT EXECUTE ON "PROD"."P_MAIL_EXTRACTO_CLIENTE" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_MAIL_EXTRACTO_CLIENTE" TO "RESOURCE";
