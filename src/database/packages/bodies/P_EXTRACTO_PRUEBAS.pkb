--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_EXTRACTO_PRUEBAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_EXTRACTO_PRUEBAS" IS

--VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
FUNCTION FN_VALIDAR_COMP(V_FON_CODIGO IN VARCHAR2) RETURN NUMBER AS
  V_RETURN NUMBER;
BEGIN
  SELECT COUNT(-1) CANTHIJOS
  INTO   V_RETURN
  FROM   PARAMETROS_FONDOS PFO
  WHERE  PFO.PFO_PAR_CODIGO = 71
  AND    PFO.PFO_RANGO_MIN_CHAR = V_FON_CODIGO
  AND    EXISTS (SELECT 'X'
          FROM   PARAMETROS_FONDOS PFO1
          WHERE  PFO1.PFO_PAR_CODIGO = 70
          AND    PFO1.PFO_FON_CODIGO = PFO.PFO_FON_CODIGO);

  RETURN V_RETURN;

EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END FN_VALIDAR_COMP;

PROCEDURE MAIL_EXTRACTO_CLIENTE IS
   DIRECCION VARCHAR2(1000);
   TIPO1     VARCHAR2(100);--(54);
   TIPO2     VARCHAR2(200);--(140);
   TIPO3     VARCHAR2(100);--(52);
   SIGNO     VARCHAR2(1);
   CTA       VARCHAR2(20);
   conn      utl_smtp.connection;
   req       utl_http.req;  
   resp      utl_http.resp;
   CRLF      VARCHAR2(2) :=  CHR(13)||CHR(10);  
   DES       VARCHAR2(40);
   TOTAL     NUMBER(22,2);
   FECHA_ACT DATE;
	P_NUM_INI  NUMBER;
   P_NUM_FIN  NUMBER;

   CURSOR C_EXT1 IS
      SELECT DISTINCT EXT_CFO_CCC_CLI_PER_NUM_IDEN,
             EXT_CFO_CCC_CLI_PER_TID_CODIGO,
             EXT_CFO_CCC_NUMERO_CUENTA,
             EXT_CFO_FON_CODIGO,
             EXT_CONSECUTIVO
        FROM EXTRACTO_FONDO_PLANO
        WHERE EXT_TIPO_INFORME != 'SAP';
   EXT1 C_EXT1%ROWTYPE;


   CURSOR C_EXT IS
      SELECT CRMF_CORREO
        FROM CORREOS_MULTICASH_FONDOS
       WHERE CRMF_EXT_CONSECUTIVO   = EXT1.EXT_CONSECUTIVO;
   EXT C_EXT%ROWTYPE;

   CURSOR CFO IS
      SELECT CFO_CCC_CLI_PER_NUM_IDEN,
             CFO_CCC_CLI_PER_TID_CODIGO,
             CFO_CCC_NUMERO_CUENTA,
             CFO_FON_CODIGO,
             CFO_CODIGO
        FROM CUENTAS_FONDOS
       WHERE CFO_CCC_CLI_PER_NUM_IDEN   = EXT1.EXT_CFO_CCC_CLI_PER_NUM_IDEN
         AND CFO_CCC_CLI_PER_TID_CODIGO = EXT1.EXT_CFO_CCC_CLI_PER_TID_CODIGO
         AND CFO_CCC_NUMERO_CUENTA      = EXT1.EXT_CFO_CCC_NUMERO_CUENTA
         AND CFO_FON_CODIGO             = EXT1.EXT_CFO_FON_CODIGO;
         --AND CFO_CODIGO                 = EXT1.EXT_CFO_CODIGO;
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
         AND MCF_CFO_FON_CODIGO             = CFO1.CFO_FON_CODIGO
         AND MCF_CFO_CODIGO                 = CFO1.CFO_CODIGO
         AND MCF_FECHA                      < P_FECHA
         AND MCF_TMF_MNEMONICO NOT IN ('RSC')
       ORDER BY MCF_CONSECUTIVO DESC;
   MCF1 MCF_SALDO_ANTERIOR%ROWTYPE;

   CURSOR FON IS
      SELECT NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) FON_MNEMONICO
        FROM FONDOS
       WHERE FON_CODIGO = CFO1.CFO_FON_CODIGO;
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
         AND MCF_CFO_FON_CODIGO             = CFO1.CFO_FON_CODIGO
         AND MCF_CFO_CODIGO                 = CFO1.CFO_CODIGO
         AND MCF_TMF_MNEMONICO NOT IN ('RSC')
         AND MCF_FECHA                      >= P_FECHA1
         AND MCF_FECHA                      < P_FECHA2
       ORDER BY MCF_CONSECUTIVO ASC;
   MCF2 MCF_MOVIMIENTOS_MES%ROWTYPE;

   CURSOR OFO IS
      SELECT OFO_TTO_TOF_CODIGO
        FROM ORDENES_FONDOS
       WHERE OFO_CONSECUTIVO = MCF2.MCF_OFO_CONSECUTIVO
         AND OFO_SUC_CODIGO  = MCF2.MCF_OFO_SUC_CODIGO;
   OFO1 OFO%ROWTYPE;

   CURSOR TOF IS
      SELECT TOF_DESCRIPCION
        FROM TIPOS_ORDEN_FONDOS
       WHERE TOF_CODIGO = OFO1.OFO_TTO_TOF_CODIGO;
   TOF1 TOF%ROWTYPE;

   CURSOR TMF(P_MNEMONICO VARCHAR2) IS
      SELECT TMF_DESCRIPCION
        FROM TIPOS_MOVIMIENTO_FONDOS
       WHERE TMF_MNEMONICO = P_MNEMONICO;
   TMF1 TMF%ROWTYPE;

   CURSOR ODP IS
      SELECT ODP_TPA_MNEMONICO,
             ODP_MONTO_ORDEN,
             ODP_NEG_CONSECUTIVO,
             ODP_SUC_CODIGO,
             ODP_CEG_CONSECUTIVO
        FROM ORDENES_DE_PAGO
       WHERE ODP_OFO_SUC_CODIGO  = MCF2.MCF_OFO_SUC_CODIGO
         AND ODP_OFO_CONSECUTIVO = MCF2.MCF_OFO_CONSECUTIVO
         AND ODP_ESTADO != 'ANU';
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

BEGIN

  P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CLIENTE','INI');

  FECHA_ACT := SYSDATE;
  OPEN C_EXT1;
   FETCH C_EXT1 INTO EXT1;
   WHILE C_EXT1%FOUND LOOP
   	  DIRECCION := NULL;
      DIRECCION := 'SMOTTA@CORREDORES.COM'; 
      OPEN C_EXT;
      FETCH C_EXT INTO EXT;
      WHILE C_EXT%FOUND LOOP
         IF DIRECCION IS NULL THEN
            DIRECCION := EXT.CRMF_CORREO;
         ELSE
            DIRECCION := DIRECCION||','||EXT.CRMF_CORREO;
         END IF;
      FETCH C_EXT INTO EXT;
      END LOOP;
      CLOSE C_EXT;
      conn := p_mail.begin_mail(sender     => 'MULTICASH@CORREDORES.COM', 
                                recipients => DIRECCION,
                                subject    => 'Movimiento Diario NIT '||EXT1.EXT_CFO_CCC_CLI_PER_NUM_IDEN,
                                mime_type  => p_mail.MULTIPART_MIME_TYPE);
      IF TO_CHAR(FECHA_ACT,'DD') = '01' THEN
         p_mail.begin_attachment(conn         => conn,
                                 mime_type    => RTRIM(TO_CHAR(ADD_MONTHS(FECHA_ACT,-1),'MONTH'),' ')||'/txt',
                                 inline       => TRUE,
                                 filename     => RTRIM(TO_CHAR(ADD_MONTHS(FECHA_ACT,-1),'MONTH'),' ')||'.txt',
                                 transfer_enc => 'text');      
     	   OPEN CFO;
     	   FETCH CFO INTO CFO1;
  	     WHILE CFO%FOUND LOOP  		      
            OPEN MCF_SALDO_ANTERIOR(ADD_MONTHS(FECHA_ACT,-1));
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
                        || TO_CHAR(ADD_MONTHS(FECHA_ACT,-1),'YYYYMMDD')
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
                        || TO_CHAR(ADD_MONTHS(FECHA_ACT,-1),'YYYYMMDD')
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
            p_mail.write_mb_text(conn,TIPO1||CRLF);
            OPEN MCF_MOVIMIENTOS_MES(ADD_MONTHS(FECHA_ACT,-1), FECHA_ACT);
            FETCH MCF_MOVIMIENTOS_MES INTO MCF2;
            WHILE MCF_MOVIMIENTOS_MES%FOUND LOOP
               IF MCF2.MCF_TMF_MNEMONICO IN ('O','R') THEN
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
                        p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                           p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                     p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                        || RPAD(TMF1.TMF_DESCRIPCION,40,' ')
                        || SIGNO
                        || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MCF_RETEFUENTE_MOVIMIENTO),'9999999999999999990.00')),22,'0')
                        || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                        || RPAD(' ',40,' ');
                  p_mail.write_mb_text(conn,TIPO2||CRLF);
               END IF;
            FETCH MCF_MOVIMIENTOS_MES INTO MCF2;
            END LOOP;
            CLOSE MCF_MOVIMIENTOS_MES;      
            OPEN MCF_SALDO_ANTERIOR(FECHA_ACT - 13);
            FETCH MCF_SALDO_ANTERIOR INTO MCF1;
            IF MCF_SALDO_ANTERIOR%FOUND THEN
               TIPO3 := '03'
                     || CTA
                     || TO_CHAR(FECHA_ACT - 1,'YYYYMMDD')
                     || LPAD(LTRIM(TO_CHAR(ABS(MCF1.SALDO),'9999999999999999990.00')),22,'0');
            END IF;
            CLOSE MCF_SALDO_ANTERIOR;
            p_mail.write_mb_text(conn,TIPO3||CRLF);
         FETCH CFO INTO CFO1;
  	     END LOOP;
  	     CLOSE CFO;
         p_mail.end_attachment( conn => conn );
      END IF;
---------------------------------------
      p_mail.begin_attachment(conn         => conn,
                              mime_type    => RTRIM(TO_CHAR(FECHA_ACT - 1,'DD/MM/YYYY'),' ')||'/txt',
                              inline       => TRUE,
                              filename     => RTRIM(TO_CHAR(FECHA_ACT - 1,'DD/MM/YYYY'),' ')||'.txt',
                              transfer_enc => 'text');      
	    OPEN CFO;
	    FETCH CFO INTO CFO1;
	    WHILE CFO%FOUND LOOP  		    
         OPEN MCF_SALDO_ANTERIOR(FECHA_ACT - 1);
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
                     || TO_CHAR(ADD_MONTHS(FECHA_ACT,-1),'YYYYMMDD')
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
                     || TO_CHAR(ADD_MONTHS(FECHA_ACT,-1),'YYYYMMDD')
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
         p_mail.write_mb_text(conn,TIPO1||CRLF);
         OPEN MCF_MOVIMIENTOS_MES(FECHA_ACT - 1, FECHA_ACT);
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
                     p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                        p_mail.write_mb_text(conn,TIPO2||CRLF);
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
               	     	  	          IF OFO1.OFO_TTO_TOF_CODIGO = 'RP' THEN
               	     	  	 	           DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
               	     	  	          ELSE 
               	     	  	 	           DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
               	     	  	          END IF;               	     	  	 
                                    TIPO2 := '02'
                                          || TO_CHAR(MCF2.MCF_FECHA1)
                                          || TO_CHAR(RPAD(OFO1.OFO_TTO_TOF_CODIGO,5,' '))
                                          || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                                          || SIGNO
                                          || LPAD(LTRIM(TO_CHAR(ABS(ODP1.ODP_MONTO_ORDEN),'9999999999999999990.00')),22,'0')
                                          || TO_CHAR(RPAD(NVL(TO_CHAR(CGE1.CEG_NUMERO_CHEQUE),' '),20,' '))
                                          || RPAD(DES,40,' ');
                                    TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                                    p_mail.write_mb_text(conn,TIPO2||CRLF);
               	     	           END IF;
               	     	           CLOSE CGE;
               	              ELSE
               	     	           IF OFO1.OFO_TTO_TOF_CODIGO = 'RP' THEN
               	     	              DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
               	     	           ELSE 
               	     	  	          DES := TOF1.TOF_DESCRIPCION||' '||MCF2.MCF_OFO_CONSECUTIVO;
               	     	           END IF;
                                 TIPO2 := '02'
                                       || TO_CHAR(MCF2.MCF_FECHA1)
                                       || TO_CHAR(RPAD(OFO1.OFO_TTO_TOF_CODIGO,5,' '))
                                       || RPAD(TPA1.TPA_DESCRIPCION,40,' ')
                                       || SIGNO
                                       || LPAD(LTRIM(TO_CHAR(ABS(ODP1.ODP_MONTO_ORDEN),'9999999999999999990.00')),22,'0')
                                       || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                                       || RPAD(DES,40,' ');
                                 TOTAL := TOTAL + ODP1.ODP_MONTO_ORDEN;
                                 p_mail.write_mb_text(conn,TIPO2||CRLF);
               	              END IF;
              	           END IF;
               	           CLOSE TPA;
                        FETCH ODP INTO ODP1;
                        END LOOP;
                        CLOSE ODP;
        	              IF TOTAL < MCF2.MONTO THEN
         	                 TOTAL := MCF2.MONTO - TOTAL;
                           TIPO2 := '02'
                                 || TO_CHAR(MCF2.MCF_FECHA1)
                                 || TO_CHAR(RPAD('ABO',5,' '))
                                 || RPAD('ABONO CUENTA',40,' ')
                                 || SIGNO
                                 || LPAD(LTRIM(TO_CHAR(ABS(TOTAL),'9999999999999999990.00')),22,'0')
                                 || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                                 || RPAD(' ',40,' ');
                           p_mail.write_mb_text(conn,TIPO2||CRLF);
                        END IF;
                     ELSE
                        TIPO2 := '02'
                              || TO_CHAR(MCF2.MCF_FECHA1)
                              || TO_CHAR(RPAD(OFO1.OFO_TTO_TOF_CODIGO,5,' '))
                              || RPAD(TOF1.TOF_DESCRIPCION,40,' ')
                              || SIGNO
                              || LPAD(LTRIM(TO_CHAR(ABS(MCF2.MONTO),'9999999999999999990.00')),22,'0')
                              || TO_CHAR(RPAD(NVL(TO_CHAR(MCF2.MCF_OFO_CONSECUTIVO),' '),20,' '))
                              || RPAD(' ',40,' ');
                        p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                        p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                  p_mail.write_mb_text(conn,TIPO2||CRLF);    
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
               p_mail.write_mb_text(conn,TIPO2||CRLF);
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
                  p_mail.write_mb_text(conn,TIPO2||CRLF);
               END IF;
               CLOSE TMF;        	
            END IF;
         FETCH MCF_MOVIMIENTOS_MES INTO MCF2;
         END LOOP;
         CLOSE MCF_MOVIMIENTOS_MES;      
         OPEN MCF_SALDO_ANTERIOR(FECHA_ACT);
         FETCH MCF_SALDO_ANTERIOR INTO MCF1;
         IF MCF_SALDO_ANTERIOR%FOUND THEN
            TIPO3 := '03'
                  || CTA
                  || TO_CHAR(FECHA_ACT - 1,'YYYYMMDD')
                  || LPAD(LTRIM(TO_CHAR(ABS(MCF1.SALDO),'9999999999999999990.00')),22,'0');
         END IF;
         CLOSE MCF_SALDO_ANTERIOR;
         p_mail.write_mb_text(conn,TIPO3||CRLF);
      FETCH CFO INTO CFO1;
	    END LOOP;
	    CLOSE CFO;
	    p_mail.end_attachment( conn => conn );
      p_mail.end_mail( conn => conn );
   FETCH C_EXT1 INTO EXT1;
   END LOOP;
   CLOSE C_EXT1;

	P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CLIENTE','FIN');

	COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         p_mail.write_mb_text(conn,'Error en generacion archivo :'||SQLERRM);
         p_mail.end_attachment( conn => conn );
         p_mail.end_mail( conn => conn );  
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
             NVL(MCC_SALDO_ADMON_VALORES,0)VALOR_MOVIMIENTO
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
             NVL(MCC_MONTO_BURSATIL,0) +
             NVL(MCC_MONTO_A_PLAZO,0) +
             NVL(MCC_MONTO_A_CONTADO,0) +
             NVL(MCC_MONTO_ADMON_VALORES,0) VALOR_MOVIMIENTO,
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
         AND MCC_TMC_MNEMONICO          NOT IN ('COPC','CPDV','COPV','CSAV','RCPDV','RCAC','RCAV','RSAV')
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
   DIRECCION := 'SMOTTA@CORREDORES.COM';
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
   P_MAIL.END_MAIL( CONN => CONN );

   EXCEPTION
      WHEN OTHERS THEN
         p_mail.write_mb_text(conn,'Error en generacion archivo :'||SQLERRM);
         p_mail.end_attachment( conn => conn );
         p_mail.end_mail( conn => conn );  
END OPERACIONES;

PROCEDURE MAIL_PROCESO_EXTRACTO_FONDOS (P_TIPO_REPORTE IN VARCHAR2,
                                        P_FECHA_INICIAL IN DATE DEFAULT NULL,
                                        P_FECHA_FINAL   IN DATE DEFAULT NULL) IS
    CURSOR mail_empleado IS
      SELECT  con_valor_char  
      FROM constantes
      WHERE con_mnemonico = 'MEP';

    CURSOR mail_cliente IS
      SELECT DISTINCT 
			 ext_cfo_ccc_cli_per_num_iden,
			 ext_cfo_ccc_cli_per_tid_codigo,
			 ext_cfo_ccc_numero_cuenta,
			 ext_cfo_fon_codigo,
			 ext_cfo_codigo,
			 EXT_CONSECUTIVO
      FROM   EXTRACTO_FONDO_PLANO
      WHERE  EXT_TIPO_INFORME IN ('SA1','S26')
	   AND    EXT_ESTADO='A';
	  C_MAIL_CLIENTE       MAIL_CLIENTE%ROWTYPE;


    CURSOR CLIENTE_FONDO_MAIL IS
      SELECT CRMF_CORREO
        FROM CORREOS_MULTICASH_FONDOS
       WHERE CRMF_EXT_CONSECUTIVO = C_MAIL_CLIENTE.EXT_CONSECUTIVO;

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
        NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) FON_MNEMONICO,
        EXT_SECUENCIAL,
        EXT_EMAIL_DIARIO,
        EXT_FTP_DIARIO,
        EXT_TIPOREP_DIARIO
      FROM fondos,
           extracto_fondo_plano
      WHERE fon_codigo = ext_cfo_fon_codigo
        AND ext_tipo_informe IN ('SA1','S26')
        AND ext_cfo_ccc_cli_per_num_iden = p_cli_per_num_iden
        AND EXT_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
        AND ext_cfo_ccc_numero_cuenta = p_ccc_numero_cuenta
        AND EXT_CFO_FON_CODIGO = P_CFO_FON_CODIGO
        AND EXT_CFO_CODIGO = P_CFO_CODIGO
        AND EXT_ESTADO='A'
        AND (EXT_FTP_DIARIO  = 'S' OR
             EXT_EMAIL_DIARIO = 'S');

  --Cursor clientes envio consolidado mensual
  CURSOR CLIENTE_FONDO_CM (p_cli_per_num_iden VARCHAR2,
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
        NVL(FON_HOMOLOGACION_MNEMONICO,FON_MNEMONICO) FON_MNEMONICO,
        EXT_SECUENCIAL,
        EXT_EMAIL_MENSUAL,
        EXT_FTP_MENSUAL,
        EXT_TIPOREP_MENSUAL
      FROM fondos,
           extracto_fondo_plano
      WHERE fon_codigo = ext_cfo_fon_codigo
        AND ext_tipo_informe IN ('SA1','S26')
        AND ext_cfo_ccc_cli_per_num_iden = p_cli_per_num_iden
        AND EXT_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
        AND ext_cfo_ccc_numero_cuenta = p_ccc_numero_cuenta
        AND EXT_CFO_FON_CODIGO = P_CFO_FON_CODIGO
        AND EXT_CFO_CODIGO = P_CFO_CODIGO
        AND EXT_ESTADO='A'
        AND (EXT_FTP_MENSUAL  = 'S' OR
             EXT_EMAIL_MENSUAL = 'S');

  --VAGTUD861-SP05HU01.ParticipacionesColocacionCanales
  CURSOR CLIENTE_FONDO_PART(P_CLI_PER_NUM_IDEN VARCHAR2,
                            P_CLI_PER_TID_CODIGO VARCHAR2,
                            P_CCC_NUMERO_CUENTA NUMBER,
                            P_CFO_FON_CODIGO VARCHAR2,
                            P_CFO_CODIGO NUMBER) IS
    SELECT CFO.CFO_CCC_CLI_PER_NUM_IDEN
          ,CFO.CFO_CCC_CLI_PER_TID_CODIGO
          ,CFO.CFO_CCC_NUMERO_CUENTA
          ,CFO.CFO_FON_CODIGO
          ,CFO.CFO_CODIGO
          ,FON.FON_MNEMONICO
          ,FON.FON_RAZON_SOCIAL
    FROM   CUENTAS_FONDOS CFO
    INNER  JOIN FONDOS FON
    ON     FON.FON_CODIGO = CFO.CFO_FON_CODIGO
    WHERE  CFO.CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
    AND    CFO.CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND    CFO.CFO_CCC_NUMERO_CUENTA = P_CCC_NUMERO_CUENTA
    AND    CFO.CFO_FON_CODIGO IN (SELECT PFO.PFO_FON_CODIGO
                                  FROM   PARAMETROS_FONDOS PFO
                                  WHERE  PFO.PFO_PAR_CODIGO = 71
                                  AND    PFO_RANGO_MIN_CHAR = P_CFO_FON_CODIGO
                                  MINUS
                                  SELECT PFO.PFO_FON_CODIGO
                                  FROM   PARAMETROS_FONDOS PFO
                                  WHERE  PFO.PFO_PAR_CODIGO = 115
                                  AND    PFO_RANGO_MIN_CHAR = 'S')
    AND    CFO.CFO_CODIGO = P_CFO_CODIGO
    AND    CFO.CFO_ESTADO = 'A';

  v_direccion_mail     VARCHAR2(4000);      
  v_error_mail         VARCHAR2(4000);      
  v_direccion_mail_emp VARCHAR2(4000);      
  v_subject_error      VARCHAR2(4000);
  v_cuerpo_error       VARCHAR2(4000);
  v_msj_error          VARCHAR2(4000);  
  v_fecha_proceso_ini  DATE;
  v_fecha_proceso_fin  DATE;
  v_error              EXCEPTION;
  conn                 utl_smtp.connection;      
  C_CLIENTE_FONDO_MAIL CLIENTE_FONDO_MAIL%ROWTYPE;  
  C_CLIENTE_FONDO      CLIENTE_FONDO%ROWTYPE; 
  C_CLIENTE_FONDO_CM   CLIENTE_FONDO_CM%ROWTYPE;
  C_CLIENTE_FONDO_PART CLIENTE_FONDO_PART%ROWTYPE;
  P_NUM_INI  NUMBER;
  P_NUM_FIN  NUMBER; 

BEGIN

 P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_PROCESO_EXTRACTO_FONDOS','INI');

  v_direccion_mail   := ' ';
  v_direccion_mail_emp := ' ';     
  v_subject_error    := ' ';
  v_cuerpo_error     := ' ';
  v_msj_error        := ' ';

  -- P_TIPO_REPORTE = D = DIARIO R = RANGO

  IF P_TIPO_REPORTE  = 'D' THEN  
    SELECT trunc(SYSDATE-1) INTO v_fecha_proceso_ini FROM DUAL;
    SELECT trunc(SYSDATE) INTO v_fecha_proceso_fin FROM DUAL;    
  ELSIF P_TIPO_REPORTE  = 'R' THEN
    v_fecha_proceso_ini := TRUNC(P_FECHA_INICIAL);
    v_fecha_proceso_fin := TRUNC(P_FECHA_FINAL+1);
  END IF;

  OPEN mail_empleado;
  FETCH mail_empleado INTO v_direccion_mail_emp;
  IF mail_empleado%NOTFOUND THEN
    v_direccion_mail_emp := 'SMOTTA@CORREDORES.COM;STECNICO@CORREDORES.COM;DAVICASH@CORREDORES.COM';
    v_subject_error := 'No existe direcion de correo valida';
    v_cuerpo_error  := 'La constante MEP no definida en el sistema';
    RAISE v_error;
  END IF;
  CLOSE mail_empleado;
  v_error_mail := v_direccion_mail_emp||';DAVICASH@CORREDORES.COM';  

  v_cuerpo_error := NULL;

  OPEN mail_cliente;
  FETCH mail_cliente into c_mail_cliente;
  WHILE mail_cliente%FOUND LOOP
    v_msj_error := NULL;
    v_direccion_mail := v_direccion_mail_emp;

    OPEN cliente_fondo_mail;
    FETCH cliente_fondo_mail INTO c_cliente_fondo_mail;
    WHILE cliente_fondo_mail%FOUND LOOP
      v_direccion_mail := v_direccion_mail||';'||c_cliente_fondo_mail.CRMF_CORREO;
      FETCH cliente_fondo_mail INTO c_cliente_fondo_mail;
    END LOOP;  
    CLOSE cliente_fondo_mail;

    OPEN cliente_fondo(c_mail_cliente.ext_cfo_ccc_cli_per_num_iden,
                       c_mail_cliente.ext_cfo_ccc_cli_per_tid_codigo,
                       c_mail_cliente.ext_cfo_ccc_numero_cuenta,
                       c_mail_cliente.ext_cfo_fon_codigo,
                       c_mail_cliente.ext_cfo_codigo);
    FETCH cliente_fondo INTO c_cliente_fondo;
    WHILE cliente_fondo%FOUND LOOP      
      --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash      
      IF FN_VALIDAR_COMP(C_CLIENTE_FONDO.EXT_CFO_FON_CODIGO) > 0 THEN         
        IF C_CLIENTE_FONDO.EXT_TIPOREP_DIARIO = 'PARTICIPACION' THEN 
          OPEN CLIENTE_FONDO_PART(c_cliente_fondo.ext_cfo_ccc_cli_per_num_iden,
                                  c_cliente_fondo.ext_cfo_ccc_cli_per_tid_codigo,
                                  c_cliente_fondo.ext_cfo_ccc_numero_cuenta,
                                  c_cliente_fondo.ext_cfo_fon_codigo,
                                  c_cliente_fondo.ext_cfo_codigo);
          FETCH CLIENTE_FONDO_PART INTO C_CLIENTE_FONDO_PART;
          WHILE CLIENTE_FONDO_PART%FOUND LOOP 
            p_extracto_pruebas.MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   => C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_NUM_IDEN,
                                                    P_CLI_PER_TID_CODIGO => C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_TID_CODIGO,
                                                    P_NUMERO_CUENTA      => C_CLIENTE_FONDO_PART.CFO_CCC_NUMERO_CUENTA,
                                                    P_FON_CODIGO         => C_CLIENTE_FONDO_PART.CFO_FON_CODIGO,
                                                    P_FON_DESCRIPCION    => C_CLIENTE_FONDO_PART.FON_RAZON_SOCIAL,
                                                    P_CUENTA_FONDO       => C_CLIENTE_FONDO_PART.CFO_CODIGO,
                                                    P_CADENA_ENVIO       => v_direccion_mail,
                                                    P_FECHA_PROCESO_INI  => v_fecha_proceso_ini,
                                                    P_FECHA_PROCESO_FIN  => v_fecha_proceso_fin,
                                                    P_CUENTA             => c_cliente_fondo.ext_cuenta,
                                                    P_EXT_SECUENCIAL     => c_cliente_fondo.ext_secuencial,
                                                    P_ERRORES            => v_msj_error,
                                                    P_FON_MNEMONICO      => C_CLIENTE_FONDO_PART.FON_MNEMONICO,
                                                    P_ENVIO_MAIL         => c_cliente_fondo.ext_email_diario,
                                                    P_ENVIO_FTP          => c_cliente_fondo.ext_ftp_diario,
                                                    P_TIPOREP            => C_CLIENTE_FONDO.EXT_TIPOREP_DIARIO,
                                                    P_RANGREP            => 'D');

            IF nvl(trim(v_msj_error),' ') != ' 'THEN
              /* Definir direccion alterna de envio de correo*/
              v_direccion_mail := v_error_mail;
              v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos';
              v_cuerpo_error  := substr(v_cuerpo_error,1,3800) || ' ' || v_msj_error || ' Secuencia Extracto: ' || 
										c_cliente_fondo.ext_secuencial ||' - Cliente: '|| 
										C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_NUM_IDEN ||'-'||
										C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_TID_CODIGO ||'-'||
										C_CLIENTE_FONDO_PART.CFO_CCC_NUMERO_CUENTA ||'-'||
										C_CLIENTE_FONDO_PART.CFO_CODIGO || chr(10);
              --RAISE v_error;
            END IF;  

            FETCH CLIENTE_FONDO_PART INTO C_CLIENTE_FONDO_PART; 
          END LOOP;
          CLOSE CLIENTE_FONDO_PART;      
        ELSIF C_CLIENTE_FONDO.EXT_TIPOREP_DIARIO = 'APORTE' THEN     
          P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN     => c_cliente_fondo.ext_cfo_ccc_cli_per_num_iden,
                                                  P_CLI_PER_TID_CODIGO   => c_cliente_fondo.ext_cfo_ccc_cli_per_tid_codigo,
                                                  P_NUMERO_CUENTA        => c_cliente_fondo.ext_cfo_ccc_numero_cuenta,
                                                  P_FON_CODIGO           => c_cliente_fondo.ext_cfo_fon_codigo,
                                                  P_FON_DESCRIPCION      => c_cliente_fondo.fon_razon_social,
                                                  P_CUENTA_FONDO         => c_cliente_fondo.ext_cfo_codigo,
                                                  P_CADENA_ENVIO         => v_direccion_mail,
                                                  P_FECHA_PROCESO_INI    => v_fecha_proceso_ini,
                                                  P_FECHA_PROCESO_FIN    => v_fecha_proceso_fin,
                                                  P_CUENTA               => c_cliente_fondo.ext_cuenta,
                                                  P_EXT_SECUENCIAL       => c_cliente_fondo.ext_secuencial,
                                                  P_ERRORES              => v_msj_error,
                                                  P_FON_MNEMONICO        => c_cliente_fondo.fon_mnemonico,
                                                  P_ENVIO_MAIL           => c_cliente_fondo.ext_email_diario,
                                                  P_ENVIO_FTP            => c_cliente_fondo.ext_ftp_diario,
                                                  P_TIPOREP              => C_CLIENTE_FONDO.EXT_TIPOREP_DIARIO,
                                                  P_RANGREP              => 'D');

          IF nvl(trim(v_msj_error),' ') != ' 'THEN
            /* Definir direccion alterna de envio de correo*/
            v_direccion_mail := v_error_mail;
            v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos';
            v_cuerpo_error  := substr(v_cuerpo_error,1,3800) || ' ' || v_msj_error || ' Secuencia Extracto: ' || 
							   c_cliente_fondo.ext_secuencial ||' - Cliente: '|| 
							   c_cliente_fondo.ext_cfo_ccc_cli_per_num_iden ||'-'||
							   c_cliente_fondo.ext_cfo_ccc_cli_per_tid_codigo ||'-'||
							   c_cliente_fondo.ext_cfo_ccc_numero_cuenta ||'-'||
							   c_cliente_fondo.ext_cfo_codigo ||  chr(10);
            --RAISE v_error;
          END IF;  
        END IF;
      ELSE
        P_EXTRACTO_PRUEBAS.mail_extracto_fondos(P_CLI_PER_NUM_IDEN     => c_cliente_fondo.ext_cfo_ccc_cli_per_num_iden,
                                                P_CLI_PER_TID_CODIGO   => c_cliente_fondo.ext_cfo_ccc_cli_per_tid_codigo,
                                                P_NUMERO_CUENTA        => c_cliente_fondo.ext_cfo_ccc_numero_cuenta,
                                                P_FON_CODIGO           => c_cliente_fondo.ext_cfo_fon_codigo,
                                                P_FON_DESCRIPCION      => c_cliente_fondo.fon_razon_social,
                                                P_CUENTA_FONDO         => c_cliente_fondo.ext_cfo_codigo,
                                                P_CADENA_ENVIO         => v_direccion_mail,
                                                P_FECHA_PROCESO_INI    => v_fecha_proceso_ini,
                                                P_FECHA_PROCESO_FIN    => v_fecha_proceso_fin,
                                                P_CUENTA               => c_cliente_fondo.ext_cuenta,
                                                P_EXT_SECUENCIAL       => c_cliente_fondo.ext_secuencial,
                                                P_ERRORES              => v_msj_error,
                                                P_FON_MNEMONICO        => c_cliente_fondo.fon_mnemonico,
                                                P_ENVIO_MAIL           => c_cliente_fondo.ext_email_diario,
                                                P_ENVIO_FTP            => c_cliente_fondo.ext_ftp_diario,
                                                P_TIPOREP              => C_CLIENTE_FONDO.EXT_TIPOREP_DIARIO,
                                                P_RANGREP              => 'D');

        IF nvl(trim(v_msj_error),' ') != ' 'THEN
          /* Definir direccion alterna de envio de correo*/
          v_direccion_mail := v_error_mail;
          v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos';
          v_cuerpo_error  := substr(v_cuerpo_error,1,3800) || ' ' || v_msj_error || ' Secuencia Extracto: ' || 
							 c_cliente_fondo.ext_secuencial ||' - Cliente: '|| 
							 c_cliente_fondo.ext_cfo_ccc_cli_per_num_iden ||'-'||
							 c_cliente_fondo.ext_cfo_ccc_cli_per_tid_codigo ||'-'||
							 c_cliente_fondo.ext_cfo_ccc_numero_cuenta ||'-'||
							 c_cliente_fondo.ext_cfo_codigo ||  chr(10);
          --RAISE v_error;
        END IF;          
      END IF;

      FETCH cliente_fondo INTO c_cliente_fondo;    
    END LOOP;
    CLOSE cliente_fondo;

    IF EXTRACT(DAY FROM v_fecha_proceso_ini + 1) = 1 THEN
      OPEN CLIENTE_FONDO_CM(c_mail_cliente.ext_cfo_ccc_cli_per_num_iden,
                            c_mail_cliente.ext_cfo_ccc_cli_per_tid_codigo,
                            c_mail_cliente.ext_cfo_ccc_numero_cuenta,
                            c_mail_cliente.ext_cfo_fon_codigo,
                            c_mail_cliente.ext_cfo_codigo);
      FETCH CLIENTE_FONDO_CM INTO C_CLIENTE_FONDO_CM;
      WHILE CLIENTE_FONDO_CM%FOUND LOOP
        --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
        IF FN_VALIDAR_COMP(C_CLIENTE_FONDO_CM.EXT_CFO_FON_CODIGO) > 0 THEN         
          IF C_CLIENTE_FONDO_CM.EXT_TIPOREP_MENSUAL = 'PARTICIPACION' THEN 
            OPEN CLIENTE_FONDO_PART(C_CLIENTE_FONDO_CM.EXT_CFO_CCC_CLI_PER_NUM_IDEN,
                                    C_CLIENTE_FONDO_CM.EXT_CFO_CCC_CLI_PER_TID_CODIGO,
                                    C_CLIENTE_FONDO_CM.EXT_CFO_CCC_NUMERO_CUENTA,
                                    C_CLIENTE_FONDO_CM.EXT_CFO_FON_CODIGO,
                                    C_CLIENTE_FONDO_CM.EXT_CFO_CODIGO);
            FETCH CLIENTE_FONDO_PART INTO C_CLIENTE_FONDO_PART;
            WHILE CLIENTE_FONDO_PART%FOUND LOOP  
              P_EXTRACTO_PRUEBAS.mail_extracto_fondos(P_CLI_PER_NUM_IDEN     => C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_NUM_IDEN,
                                                      P_CLI_PER_TID_CODIGO   => C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_TID_CODIGO,
                                                      P_NUMERO_CUENTA        => C_CLIENTE_FONDO_PART.CFO_CCC_NUMERO_CUENTA,
                                                      P_FON_CODIGO           => C_CLIENTE_FONDO_PART.CFO_FON_CODIGO,
                                                      P_FON_DESCRIPCION      => C_CLIENTE_FONDO_PART.FON_RAZON_SOCIAL,
                                                      P_CUENTA_FONDO         => C_CLIENTE_FONDO_PART.CFO_CODIGO,
                                                      P_CADENA_ENVIO         => v_direccion_mail,
                                                      P_FECHA_PROCESO_INI    => ADD_MONTHS(v_fecha_proceso_ini + 1,-1),
                                                      P_FECHA_PROCESO_FIN    => v_fecha_proceso_ini + 1,
                                                      P_CUENTA               => C_CLIENTE_FONDO_CM.ext_cuenta,
                                                      P_EXT_SECUENCIAL       => C_CLIENTE_FONDO_CM.ext_secuencial,
                                                      P_ERRORES              => v_msj_error,
                                                      P_FON_MNEMONICO        => C_CLIENTE_FONDO_PART.FON_MNEMONICO,
                                                      P_ENVIO_MAIL           => C_CLIENTE_FONDO_CM.ext_email_mensual,
                                                      P_ENVIO_FTP            => C_CLIENTE_FONDO_CM.ext_ftp_mensual,
                                                      P_TIPOREP              => C_CLIENTE_FONDO_CM.EXT_TIPOREP_MENSUAL,
                                                      P_RANGREP              => 'R');
              IF nvl(trim(v_msj_error),' ') != ' 'THEN
                /* Definir direccion alterna de envio de correo*/
                v_direccion_mail := v_error_mail;
                v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos';
                v_cuerpo_error  := substr(v_cuerpo_error,1,3800) || ' ' || v_msj_error || ' Secuencia Extracto: ' || 
								   C_CLIENTE_FONDO_CM.ext_secuencial ||' - Cliente: '|| 
								   C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_NUM_IDEN ||'-'||
								   C_CLIENTE_FONDO_PART.CFO_CCC_CLI_PER_TID_CODIGO ||'-'||
								   C_CLIENTE_FONDO_PART.CFO_CCC_NUMERO_CUENTA ||'-'||
								   C_CLIENTE_FONDO_PART.CFO_CODIGO || chr(10);
                --RAISE v_error;
              END IF;                        

              FETCH CLIENTE_FONDO_PART INTO C_CLIENTE_FONDO_PART; 
            END LOOP;
            CLOSE CLIENTE_FONDO_PART;      
          ELSIF C_CLIENTE_FONDO_CM.EXT_TIPOREP_MENSUAL = 'APORTE' THEN 
            P_EXTRACTO_PRUEBAS.mail_extracto_fondos(P_CLI_PER_NUM_IDEN     => C_CLIENTE_FONDO_CM.ext_cfo_ccc_cli_per_num_iden,
                                                    P_CLI_PER_TID_CODIGO   => C_CLIENTE_FONDO_CM.ext_cfo_ccc_cli_per_tid_codigo,                               
                                                    P_NUMERO_CUENTA        => C_CLIENTE_FONDO_CM.ext_cfo_ccc_numero_cuenta,
                                                    P_FON_CODIGO           => C_CLIENTE_FONDO_CM.ext_cfo_fon_codigo,
                                                    P_FON_DESCRIPCION      => C_CLIENTE_FONDO_CM.fon_razon_social,
                                                    P_CUENTA_FONDO         => C_CLIENTE_FONDO_CM.ext_cfo_codigo,
                                                    P_CADENA_ENVIO         => v_direccion_mail,
                                                    P_FECHA_PROCESO_INI    => ADD_MONTHS(v_fecha_proceso_ini + 1,-1),
                                                    P_FECHA_PROCESO_FIN    => v_fecha_proceso_ini + 1,
                                                    P_CUENTA               => C_CLIENTE_FONDO_CM.ext_cuenta,
                                                    P_EXT_SECUENCIAL       => C_CLIENTE_FONDO_CM.ext_secuencial,
                                                    P_ERRORES              => v_msj_error,
                                                    P_FON_MNEMONICO        => C_CLIENTE_FONDO_CM.fon_mnemonico,
                                                    P_ENVIO_MAIL           => C_CLIENTE_FONDO_CM.ext_email_mensual,
                                                    P_ENVIO_FTP            => C_CLIENTE_FONDO_CM.ext_ftp_mensual,
                                                    P_TIPOREP              => C_CLIENTE_FONDO_CM.EXT_TIPOREP_MENSUAL,
                                                    P_RANGREP              => 'R');
            IF nvl(trim(v_msj_error),' ') != ' 'THEN
              /* Definir direccion alterna de envio de correo*/
              v_direccion_mail := v_error_mail;
              v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos';
              v_cuerpo_error  := substr(v_cuerpo_error,1,3800) || ' ' || v_msj_error || ' Secuencia Extracto: ' || 
								 C_CLIENTE_FONDO_CM.ext_secuencial ||' - Cliente: '|| 
								 C_CLIENTE_FONDO_CM.EXT_CFO_CCC_CLI_PER_NUM_IDEN ||'-'||
								 C_CLIENTE_FONDO_CM.EXT_CFO_CCC_CLI_PER_TID_CODIGO ||'-'||
								 C_CLIENTE_FONDO_CM.EXT_CFO_CCC_NUMERO_CUENTA ||'-'||
								 C_CLIENTE_FONDO_CM.EXT_CFO_CODIGO || chr(10);
              --RAISE v_error;
            END IF;  
          END IF;
        ELSE
          P_EXTRACTO_PRUEBAS.mail_extracto_fondos(P_CLI_PER_NUM_IDEN     => C_CLIENTE_FONDO_CM.ext_cfo_ccc_cli_per_num_iden,
                                                  P_CLI_PER_TID_CODIGO   => C_CLIENTE_FONDO_CM.ext_cfo_ccc_cli_per_tid_codigo,                               
                                                  P_NUMERO_CUENTA        => C_CLIENTE_FONDO_CM.ext_cfo_ccc_numero_cuenta,
                                                  P_FON_CODIGO           => C_CLIENTE_FONDO_CM.ext_cfo_fon_codigo,
                                                  P_FON_DESCRIPCION      => C_CLIENTE_FONDO_CM.fon_razon_social,
                                                  P_CUENTA_FONDO         => C_CLIENTE_FONDO_CM.ext_cfo_codigo,
                                                  P_CADENA_ENVIO         => v_direccion_mail,
                                                  P_FECHA_PROCESO_INI    => ADD_MONTHS(v_fecha_proceso_ini + 1,-1),
                                                  P_FECHA_PROCESO_FIN    => v_fecha_proceso_ini + 1,
                                                  P_CUENTA               => C_CLIENTE_FONDO_CM.ext_cuenta,
                                                  P_EXT_SECUENCIAL       => C_CLIENTE_FONDO_CM.ext_secuencial,
                                                  P_ERRORES              => v_msj_error,
                                                  P_FON_MNEMONICO        => C_CLIENTE_FONDO_CM.fon_mnemonico,
                                                  P_ENVIO_MAIL           => C_CLIENTE_FONDO_CM.ext_email_mensual,
                                                  P_ENVIO_FTP            => C_CLIENTE_FONDO_CM.ext_ftp_mensual,
                                                  P_TIPOREP              => C_CLIENTE_FONDO_CM.EXT_TIPOREP_MENSUAL,
                                                  P_RANGREP              => 'R');
          IF nvl(trim(v_msj_error),' ') != ' 'THEN
            /* Definir direccion alterna de envio de correo*/
            v_direccion_mail := v_error_mail;
            v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos';
            v_cuerpo_error  := substr(v_cuerpo_error,1,3800) || ' ' || v_msj_error || ' Secuencia Extracto: ' || 
							   C_CLIENTE_FONDO_CM.ext_secuencial ||' - Cliente: '|| 
							   C_CLIENTE_FONDO_CM.EXT_CFO_CCC_CLI_PER_NUM_IDEN ||'-'||
							   C_CLIENTE_FONDO_CM.EXT_CFO_CCC_CLI_PER_TID_CODIGO ||'-'||
							   C_CLIENTE_FONDO_CM.EXT_CFO_CCC_NUMERO_CUENTA ||'-'||
							   C_CLIENTE_FONDO_CM.EXT_CFO_CODIGO || chr(10);
            --RAISE v_error;
          END IF;  
        END IF;

        FETCH CLIENTE_FONDO_CM INTO C_CLIENTE_FONDO_CM;    
      END LOOP;
      CLOSE CLIENTE_FONDO_CM;      
    END IF;
    FETCH mail_cliente into c_mail_cliente;
  END LOOP;
  CLOSE mail_cliente;

  --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  IF v_cuerpo_error IS NOT NULL THEN 
    conn := p_mail.begin_mail(sender     => 'ADMINISTRADOR@CORREDORES.COM',
                              recipients => v_error_mail,
                              subject    => v_subject_error,
                              mime_type  => p_mail.MULTIPART_MIME_TYPE);
    p_mail.attach_text(conn      => conn,
                       data      => '<h1>'||v_cuerpo_error||'</h1>',
                       mime_type => 'text/html');
    p_mail.end_mail( conn => conn );    
  END IF;

  P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_PROCESO_EXTRACTO_FONDOS','FIN');

  COMMIT;

  EXCEPTION 
    WHEN v_error THEN
      conn := p_mail.begin_mail(sender     => 'ADMINISTRADOR@CORREDORES.COM',
                                recipients => v_error_mail,
                                subject    => v_subject_error,
                                mime_type  => p_mail.MULTIPART_MIME_TYPE);
      p_mail.attach_text(conn      => conn,
                         data      => '<h1>'||v_cuerpo_error||'</h1>',
                         mime_type => 'text/html');
      p_mail.end_mail( conn => conn );     
   WHEN OTHERS THEN   
     v_direccion_mail := v_error_mail;
     v_subject_error := 'Error en proceso P_EXTRACTO_PRUEBAS.mail_extracto_fondos ';
     v_cuerpo_error  := 'Error no determinado :'||SQLERRM;
     conn := p_mail.begin_mail(sender     => 'ADMINISTRADOR@CORREDORES.COM', 
                                recipients => v_direccion_mail,
                                subject    => v_subject_error,
                                mime_type  => p_mail.MULTIPART_MIME_TYPE);
     p_mail.attach_text(conn      => conn,
                         data      => '<h1>'||v_cuerpo_error||'</h1>',
                         mime_type => 'text/html');
     p_mail.end_mail( conn => conn );     
END MAIL_PROCESO_EXTRACTO_FONDOS;

PROCEDURE MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN     IN VARCHAR2 DEFAULT NULL,
                               P_CLI_PER_TID_CODIGO   IN VARCHAR2 DEFAULT NULL,                               
                               P_NUMERO_CUENTA        IN NUMBER   DEFAULT NULL,
                               P_FON_CODIGO           IN VARCHAR2 DEFAULT NULL,
                               P_FON_DESCRIPCION      IN VARCHAR2 DEFAULT NULL,
                               P_CUENTA_FONDO         IN NUMBER   DEFAULT NULL,
                               P_CADENA_ENVIO         IN VARCHAR2 DEFAULT NULL,
                               P_FECHA_PROCESO_INI    IN DATE     DEFAULT NULL,
                               P_FECHA_PROCESO_FIN    IN DATE     DEFAULT NULL,
                               P_CUENTA               IN VARCHAR2 DEFAULT NULL,
                               P_EXT_SECUENCIAL       IN NUMBER   DEFAULT NULL,
                               P_ERRORES              IN OUT      VARCHAR2,
                               P_FON_MNEMONICO        IN VARCHAR2 DEFAULT NULL,
                               P_ENVIO_MAIL           IN VARCHAR2 DEFAULT 'S',
                               P_ENVIO_FTP            IN VARCHAR2 DEFAULT 'N',
                               P_REPROCESO            IN VARCHAR2 DEFAULT 'N',
                               P_TIPOREP              IN VARCHAR2 DEFAULT 'PARTICIPACION',
                               P_RANGREP              IN VARCHAR2 DEFAULT 'D') IS

/* cursor se reeemplaza por parametro en la base de datos */
   CURSOR CONSECUTIVO(V_FON_CODIGO VARCHAR2) IS
     SELECT CXS_NUMERO_EXTRACTO     
           ,CXS_NUMERO_EXTRACTO_MENSUAL       
           ,CXS_CONSTANTE_CUENTA_SAP           
     FROM   CONTROL_EXTRACTOS_SAP
     WHERE CXS_CFO_CCC_CLI_PER_NUM_IDEN    = P_CLI_PER_NUM_IDEN
       AND CXS_CFO_CCC_CLI_PER_TID_CODIGO  = P_CLI_PER_TID_CODIGO
       AND CXS_CFO_CCC_NUMERO_CUENTA       = P_NUMERO_CUENTA
       AND CXS_CFO_FON_CODIGO              = V_FON_CODIGO
       AND CXS_CFO_CODIGO                  = P_CUENTA_FONDO;

--------------------------------------------------------------------------------       
/* 2016-07-07 Leer la estructura definida para el cliente*/

  CURSOR C_TIPO_INFORME(V_FON_CODIGO VARCHAR2) IS  
    SELECT EXT_TIPO_INFORME FROM EXTRACTO_FONDO_PLANO
    WHERE EXT_CFO_CCC_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
    AND EXT_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND EXT_CFO_CCC_NUMERO_CUENTA      = P_NUMERO_CUENTA
    AND EXT_CFO_FON_CODIGO             = V_FON_CODIGO
    AND EXT_SECUENCIAL                 = P_EXT_SECUENCIAL;


  CURSOR saldo_anterior IS
    SELECT MCF_SALDO_CAPITAL + MCF_SALDO_RENDIMIENTOS_RF + MCF_SALDO_RENDIMIENTOS_RV SALDO
          ,MCF_CFO_CCC_CLI_PER_NUM_IDEN
          ,MCF_CFO_CCC_CLI_PER_TID_CODIGO
          ,MCF_CFO_CCC_NUMERO_CUENTA
          ,MCF_CFO_CODIGO
    FROM   MOVIMIENTOS_CUENTAS_FONDOS
    WHERE  MCF_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
    AND    MCF_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND    MCF_CFO_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
    AND    MCF_CFO_FON_CODIGO = P_FON_CODIGO
    AND    MCF_CFO_CODIGO = P_CUENTA_FONDO
    AND    MCF_FECHA < P_FECHA_PROCESO_INI
    AND    MCF_TMF_MNEMONICO NOT IN ('RSC')
    ORDER  BY MCF_CONSECUTIVO DESC;

  --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash  
  CURSOR extracto(V_FON_CODIGO VARCHAR2)IS
    SELECT EXT.EXT_SECUENCIAL
          ,EXT.EXT_CFO_CCC_CLI_PER_NUM_IDEN
          ,EXT.EXT_CFO_CCC_CLI_PER_TID_CODIGO
          ,EXT.EXT_CFO_CCC_NUMERO_CUENTA
          ,EXT.EXT_CFO_FON_CODIGO
          ,EXT.EXT_CFO_CODIGO
          ,EXT.EXT_TIPO_INFORME
          ,EXT.EXT_CODIGO_GRUPO
          ,EXT.EXT_ESTADO
          ,EXT.EXT_FTP_DIARIO
          ,EXT.EXT_EMAIL_DIARIO
          ,EXT.EXT_FTP_MENSUAL
          ,EXT.EXT_EMAIL_MENSUAL
          ,EXT.EXT_CONSECUTIVO
          ,EXT.EXT_TIPOREP_DIARIO
          ,EXT.EXT_TIPOREP_MENSUAL
    FROM   EXTRACTO_FONDO_PLANO EXT
    WHERE  EXT.EXT_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
    AND    EXT.EXT_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND    EXT.EXT_CFO_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
    AND    EXT.EXT_CFO_FON_CODIGO = V_FON_CODIGO
    AND    EXT.EXT_SECUENCIAL = P_EXT_SECUENCIAL;

  CURSOR C_EXTRACTO_HIST(V_FECHA_EXT DATE, V_FON_CODIGO VARCHAR2, V_CONSECUTIVO NUMBER) IS
    SELECT HCXS.HCXS_FECHA_EXTRACTO
          ,HCXS.HCXS_EXT_CLI_PER_NUM_IDEN
          ,HCXS.HCXS_EXT_CLI_PER_TID_CODIGO
          ,HCXS.HCXS_EXT_NUMERO_CUENTA
          ,HCXS.HCXS_EXT_FON_CODIGO
          ,HCXS.HCXS_EXT_CODIGO
          ,HCXS.HCXS_EXT_CONSECUTIVO
          ,HCXS.HCXS_EXT_SECUENCIAL
          ,HCXS.HCXS_TIPO_GENERACION
          ,HCXS.HCXS_EXT_TIPOREP_DIARIO
          ,HCXS.HCXS_EXT_TIPOREP_MENSUAL
          ,HCXS.HCXS_CXS_NUMERO_EXTRACTO
          ,HCXS.HCXS_CXS_NUMERO_EXTRACTO_MES
          ,HCXS.HCXS_USUARIO_MOD
          ,HCXS.HCXS_FECHA_MOD
    FROM   HIST_CONTROL_EXTRACTOS_SAP HCXS
    WHERE  HCXS.HCXS_FECHA_EXTRACTO = V_FECHA_EXT
    AND    HCXS.HCXS_EXT_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
    AND    HCXS.HCXS_EXT_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND    HCXS.HCXS_EXT_NUMERO_CUENTA = P_NUMERO_CUENTA
    AND    HCXS.HCXS_EXT_FON_CODIGO IN
           (SELECT  V_FON_CODIGO
             FROM   DUAL
             UNION
             SELECT PFO.PFO_FON_CODIGO
             FROM   PARAMETROS_FONDOS PFO
             WHERE  PFO.PFO_PAR_CODIGO = 71
             AND    PFO_RANGO_MIN_CHAR = V_FON_CODIGO
             MINUS
             SELECT PFO.PFO_FON_CODIGO
             FROM   PARAMETROS_FONDOS PFO
             WHERE  PFO.PFO_PAR_CODIGO = 115
             AND    PFO_RANGO_MIN_CHAR = 'S')
    AND    HCXS.HCXS_EXT_CODIGO = P_CUENTA_FONDO
    AND    HCXS.HCXS_EXT_CONSECUTIVO = V_CONSECUTIVO;

  CURSOR saldo_aporte(V_FECHA_PROCESO_INI DATE) IS
    SELECT SUM(NVL(MCF.MCF_SALDO_CAPITAL, 0)) + SUM(NVL(MCF.MCF_SALDO_RENDIMIENTOS_RF, 0)) + SUM(NVL(MCF.MCF_SALDO_RENDIMIENTOS_RV, 0)) SALDO
          ,MCF.MCF_CFO_CCC_CLI_PER_NUM_IDEN
          ,MCF.MCF_CFO_CCC_CLI_PER_TID_CODIGO
          ,MCF.MCF_CFO_CCC_NUMERO_CUENTA
          ,MCF.MCF_CFO_CODIGO
    FROM   MOVIMIENTOS_CUENTAS_FONDOS MCF
    WHERE  1 = 1
    AND    MCF.MCF_CONSECUTIVO IN (SELECT MAX(MCF.MCF_CONSECUTIVO)
                                   FROM   MOVIMIENTOS_CUENTAS_FONDOS MCF
                                   WHERE  MCF.MCF_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
                                   AND    MCF.MCF_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                                   AND    MCF.MCF_CFO_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
                                   AND    MCF.MCF_CFO_FON_CODIGO IN
                                          (SELECT PFO.PFO_FON_CODIGO
                                            FROM   PARAMETROS_FONDOS PFO
                                            WHERE  PFO.PFO_PAR_CODIGO = 71
                                            AND    PFO_RANGO_MIN_CHAR = P_FON_CODIGO
                                            MINUS
                                            SELECT PFO.PFO_FON_CODIGO
                                            FROM   PARAMETROS_FONDOS PFO
                                            WHERE  PFO.PFO_PAR_CODIGO = 115
                                            AND    PFO_RANGO_MIN_CHAR = 'S')
                                   AND    MCF.MCF_CFO_CODIGO = P_CUENTA_FONDO
                                   AND    MCF.MCF_FECHA < V_FECHA_PROCESO_INI
                                   AND    MCF.MCF_TMF_MNEMONICO NOT IN ('RSC')
                                   GROUP  by mcf.mcf_cfo_fon_codigo)
    GROUP  BY MCF.MCF_CFO_CCC_CLI_PER_NUM_IDEN
             ,MCF.MCF_CFO_CCC_CLI_PER_TID_CODIGO
             ,MCF.MCF_CFO_CCC_NUMERO_CUENTA
             ,MCF.MCF_CFO_CODIGO;


-------- Cursor MOVIMIENTO_DIA -------------------------------------------------      
  CURSOR movimiento_dia IS
    SELECT   DISTINCT
             to_char(mcf_fecha,'dd.mm.yy') mcf_fecha1,
             mcf_tmf_mnemonico,
             mcf_ofo_consecutivo,
             mcf_ofo_suc_codigo,
             mcf_retefuente_movimiento,
			 mcf_capital +
             mcf_rendimientos_rf +
             mcf_rendimientos_rv -
             mcf_retefuente_movimiento monto,
			 --inicio VAGTUS036268 separar rendiemientos de capital en las reverciones de incrementos o ingresos.
             mcf_capital -
             mcf_retefuente_movimiento montoNoRend,
			 mcf_rendimientos_rf +
             mcf_rendimientos_rv rendimeintos,
			 --fin VAGTUS036268 separar rendiemientos de capital en las reverciones de incrementos o ingresos.
             mcf_capital +
             mcf_rendimientos_rf +
             mcf_rendimientos_rv monto2,
             mcf_saldo_capital +
             mcf_saldo_rendimientos_rf +
             mcf_saldo_rendimientos_rv saldo_final,
             ofo_tto_tof_codigo,
             ofo_concepto_cobro_apt,
             ofo_concepto_inc_apt,
             to_char(nvl(ofo_fecha_ejecucion,mcf_fecha),'dd.mm.yy')ofo_fecha_ejecucion,
             --VAGTUD861-SP02HU03.ReporteriaOrdenesDavicash
             NULL AS CICLO_ABONO,
             mcf_consecutivo
    FROM ordenes_fondos,
         movimientos_cuentas_fondos,
		 RECIBOS_DE_CAJA
    WHERE ofo_consecutivo(+)             = mcf_ofo_consecutivo
      AND ofo_suc_codigo(+)              = mcf_ofo_suc_codigo
      AND OFO_CONSECUTIVO                = RCA_OFO_CONSECUTIVO(+)
      AND OFO_SUC_CODIGO                 = RCA_OFO_SUC_CODIGO(+)
      AND mcf_cfo_ccc_cli_per_num_iden   = p_cli_per_num_iden
      AND mcf_cfo_ccc_cli_per_tid_codigo = p_cli_per_tid_codigo
      AND mcf_cfo_ccc_numero_cuenta      = p_numero_cuenta
      AND mcf_cfo_fon_codigo             = p_fon_codigo
      AND mcf_cfo_codigo                 = p_cuenta_fondo
      AND mcf_fecha                      >= p_fecha_proceso_ini
      AND mcf_fecha                      <  p_fecha_proceso_fin
      AND mcf_tmf_mnemonico not in ('RSC')      
    ORDER BY mcf_consecutivo ASC;      
-------- Fin Cursor MOVIMIENTO_DIA --------------------------------------------- 

-------- Cursor RCA CICLO ABONO CONSOLIDADO---------------------
  --VAGTUD861-SP02_HU03.ReporteriaOrdenes
  CURSOR C_RCA_CICLO (P_RCA_OFO_CONSECUTIVO NUMBER, P_RCA_OFO_SUC_CODIGO NUMBER) IS
    SELECT MAX(RCA.RCA_CICLO_ABONO) CICLO_ABONO
    FROM   RECIBOS_DE_CAJA RCA
    WHERE  RCA.RCA_OFO_CONSECUTIVO = P_RCA_OFO_CONSECUTIVO
    AND    RCA.RCA_OFO_SUC_CODIGO = P_RCA_OFO_SUC_CODIGO;

  R_RCA_CICLO C_RCA_CICLO%ROWTYPE;
-------- Fin Cursor C_RCA_CICLO ------------------------------------------------

-------- Cursor movimientos reversion consolidados Davicash---------------------
  --VAGTUD861-SP02_HU03.ReporteriaOrdenes
  CURSOR C_MVTOSDAV_REV (P_PIDC_OFO_CONSECUTIVO NUMBER, P_PIDC_OFO_SUC_CODIGO NUMBER, P_PIDC_REV_MCF_CONSECUTIVO NUMBER) IS
    SELECT PIDC_UUID
	     , PIDC_RCA_CONSECUTIVO
		 , PIDC_RCA_NEG_CONSECUTIVO
		 , PIDC_RCA_SUC_CODIGO
		 , PIDC_CCC_CLI_PER_NUM_IDEN
		 , PIDC_CCC_CLI_PER_TID_CODIGO
		 , PIDC_CCC_NUMERO_CUENTA
		 , PIDC_CFO_FON_CODIGO
		 , PIDC_CFO_CODIGO
		 , PIDC_CBA_BAN_CODIGO
		 , PIDC_CBA_NUMERO_CUENTA
		 , PIDC_CCJ_TIPO_CONSIGNACION
		 , PIDC_CCJ_MONTO
		 , PIDC_RCA_FECHA_CONTABLE
		 , PIDC_RCA_FECHA
		 , PIDC_OFO_CONSECUTIVO
		 , PIDC_OFO_SUC_CODIGO
		 , PIDC_REVERSADA
		 , PIDC_REV_MCC_CONSECUTIVO
		 , PIDC_REV_MCF_CONSECUTIVO
		 , PIDC_REV_RENDIMIENTOS
		 , PIDC_REV_UNIDADES
    FROM   PROCESO_INCREMENTO_DAVICASH PIDC
    WHERE  PIDC.PIDC_OFO_CONSECUTIVO = P_PIDC_OFO_CONSECUTIVO
    AND    PIDC.PIDC_OFO_SUC_CODIGO = P_PIDC_OFO_SUC_CODIGO
    AND    PIDC.PIDC_REV_MCF_CONSECUTIVO = P_PIDC_REV_MCF_CONSECUTIVO;
  R_MVTOSDAV_REV C_MVTOSDAV_REV%ROWTYPE;
-------- Fin Cursor C_MVTOSDAV_REV --------------------------------------------- 

-------- Cursor movimientos incremento consolidados Davicash--------------------
  --VAGTUD861-SP02_HU03.ReporteriaOrdenes
  CURSOR C_MVTOSDAV_REC (P_PIDC_RCA_CONSECUTIVO NUMBER, P_PIDC_RCA_NEG_CONSECUTIVO NUMBER, P_PIDC_RCA_SUC_CODIGO NUMBER) IS
    SELECT PIDC_UUID
	     , PIDC_RCA_CONSECUTIVO
		 , PIDC_RCA_NEG_CONSECUTIVO
		 , PIDC_RCA_SUC_CODIGO
		 , PIDC_CCC_CLI_PER_NUM_IDEN
		 , PIDC_CCC_CLI_PER_TID_CODIGO
		 , PIDC_CCC_NUMERO_CUENTA
		 , PIDC_CFO_FON_CODIGO
		 , PIDC_CFO_CODIGO
		 , PIDC_CBA_BAN_CODIGO
		 , PIDC_CBA_NUMERO_CUENTA
		 , PIDC_CCJ_TIPO_CONSIGNACION
		 , PIDC_CCJ_MONTO
		 , PIDC_RCA_FECHA_CONTABLE
		 , PIDC_RCA_FECHA
		 , PIDC_OFO_CONSECUTIVO
		 , PIDC_OFO_SUC_CODIGO
		 , PIDC_REVERSADA
		 , PIDC_REV_MCC_CONSECUTIVO
		 , PIDC_REV_MCF_CONSECUTIVO
		 , PIDC_REV_RENDIMIENTOS
		 , PIDC_REV_UNIDADES
    FROM   PROCESO_INCREMENTO_DAVICASH PIDC
    WHERE  PIDC.PIDC_RCA_CONSECUTIVO = P_PIDC_RCA_CONSECUTIVO
    AND    PIDC.PIDC_RCA_NEG_CONSECUTIVO = P_PIDC_RCA_NEG_CONSECUTIVO
    AND    PIDC.PIDC_RCA_SUC_CODIGO = P_PIDC_RCA_SUC_CODIGO;
  R_MVTOSDAV_REC C_MVTOSDAV_REC%ROWTYPE;
-------- Fin Cursor C_MVTOSDAV_REC --------------------------------------------- 

-------- Cursor PAGOS ----------------------------------------------------------    
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
             ceg_numero_cheque,
             odp_consecutivo
        FROM comprobantes_de_egreso,
             ordenes_de_pago
       WHERE ceg_suc_codigo(+)      = odp_suc_codigo
         AND ceg_neg_consecutivo(+) = odp_neg_consecutivo
         AND ceg_consecutivo (+)    = odp_ceg_consecutivo
         AND odp_estado            != 'ANU'
         AND odp_ofo_suc_codigo     = P_MCF_SUC_CODIGO
         AND odp_ofo_consecutivo    = P_MCF_OFO_CONSECUTIVO;
-------- Fin Cursor PAGOS ------------------------------------------------------   

-------- Cursor PAGOS_ACH ------------------------------------------------------ 		 
  CURSOR pagos_ach(P_DPA_ODP_CONSECUTIVO       NUMBER,
                   P_DPA_ODP_SUC_CODIGO        NUMBER,
                   P_DPA_ODP_NEG_CONSECUTIVO   NUMBER) IS
    SELECT dpa_monto,
           dpa_num_iden,
           dpa_tid_codigo,
           dpa_nombre,
		   dpa_tcb_mnemonico
    FROM detalles_pagos_ach
    WHERE dpa_odp_consecutivo     = P_DPA_ODP_CONSECUTIVO
      AND dpa_odp_suc_codigo      = P_DPA_ODP_SUC_CODIGO
      AND dpa_odp_neg_consecutivo = P_DPA_ODP_NEG_CONSECUTIVO
    ORDER BY DPA_CONSECUTIVO;  
-------- Fin Cursor PAGOS_ACH --------------------------------------------------

-------- Cursor RECAUDOS -------------------------------------------------------	 	 
   CURSOR RECAUDOS  (P_MCF_SUC_CODIGO      NUMBER,
                     P_MCF_OFO_CONSECUTIVO NUMBER) IS
       SELECT RCA_SUC_CODIGO,
             RCA_NEG_CONSECUTIVO,
             RCA_CONSECUTIVO,
             RCA_COT_MNEMONICO,
             RCA_FECHA,
             RCA_NUM_IDEN_CONSIGNANTE,
             RCA_TID_CODIGO_CONSIGNANTE,
             RCA_NOMBRE_CONSIGNANTE,
             RCA_CONV_CONSECUTIVO,
             CCJ.CCJ_BAN_CODIGO,             
             DECODE(TO_CHAR(BAN.BAN_NIT),NULL,'/',TO_CHAR(BAN.BAN_NIT)) BAN_NIT,
             CCJ.CCJ_CBA_NUMERO_CUENTA,
             CCJ_NUMERO_CONSIGNACION,
             CCJ_MONTO,
			 (CASE
                WHEN CNA.CNL_CODIGO = 'PSED' THEN '04'
                ELSE DECODE(CCJ_TIPO_CONSIGNACION,'CHE','01','EFE','02','03')                
             END) CCJ_TIPO_CONSIGNACION,       
             RCA_CONV_CONSECUTIVO AS RECO_CODIGO_PRI_8020,
             RCA_CODIGO_CONSIGNANTE AS RECO_CODIGO_SEG_8020,
             NVL(RRDN_RECO_FECHA_RECAUDO,RCA_FECHA) AS FECHA_RECAUDO,
			 RCA.RCA_CICLO_ABONO AS CICLO_ABONO
       FROM  RECIBOS_DE_CAJA RCA,
             CONSIGNACIONES_CAJA CCJ,
             BANCOS BAN,
			 RECAUDOS_RECIBOS_DAVICASH_NEXT RRDN,
			 CANALES CNA,
             PROCESO_INCREMENTO_DAVICASH PIDC
       WHERE RCA.RCA_CONSECUTIVO = CCJ.CCJ_RCA_CONSECUTIVO
         AND RCA.RCA_NEG_CONSECUTIVO = CCJ.CCJ_RCA_NEG_CONSECUTIVO
         AND RCA.RCA_SUC_CODIGO = CCJ.CCJ_RCA_SUC_CODIGO 
         AND RCA.RCA_CONSECUTIVO = RRDN.RRND_RECO_RCA_CONSECUTIVO (+)
         AND RCA.RCA_NEG_CONSECUTIVO = RRDN.RRDN_RECO_RCA_NEG_CONSECUTIVO (+)
         AND RCA.RCA_SUC_CODIGO = RRDN.RRDN_RECO_RCA_SUC_CODIGO (+)
         AND CCJ.CCJ_BAN_CODIGO = BAN.BAN_CODIGO (+)
		 AND RCA.RCA_COT_MNEMONICO = 'AXCB'
         --VAGTUS061820.AjusteMulticashFondosRecibosReversados
         AND pidc.pidc_rca_consecutivo = rca.rca_consecutivo
         AND pidc.pidc_rca_neg_consecutivo = rca.rca_neg_consecutivo
         AND pidc.pidc_rca_suc_codigo = rca.rca_suc_codigo
         AND (nvl(pidc.pidc_reversada, 'NO') = 'NO' OR
              (nvl(pidc.pidc_reversada, 'NO') = 'SI' AND pidc.pidc_rev_mcc_consecutivo IS NOT NULL AND pidc.pidc_rev_mcf_consecutivo IS NOT NULL))
         AND RCA_OFO_SUC_CODIGO = P_MCF_SUC_CODIGO
         AND RCA_OFO_CONSECUTIVO = P_MCF_OFO_CONSECUTIVO
		 AND RCA.RCA_CNL_CONSECUTIVO = CNA.CNL_CONSECUTIVO (+)
      UNION
      SELECT RCA_SUC_CODIGO,
             RCA_NEG_CONSECUTIVO,
             RCA_CONSECUTIVO,
             RCA_COT_MNEMONICO,
             RCA_FECHA,
             RCA_NUM_IDEN_CONSIGNANTE,
             RCA_TID_CODIGO_CONSIGNANTE,
             RCA_NOMBRE_CONSIGNANTE,
             RCA_CONV_CONSECUTIVO,
             TRC.TRC_CBA_BAN_CODIGO CCJ_BAN_CODIGO,             
             DECODE(TO_CHAR(BAN.BAN_NIT),NULL,'/',TO_CHAR(BAN.BAN_NIT)) BAN_NIT,
             NULL CCJ_CBA_NUMERO_CUENTA,
             NULL CCJ_NUMERO_CONSIGNACION,
             TRC.TRC_MONTO CCJ_MONTO,
             (CASE
                WHEN CNA.CNL_CODIGO = 'PSED' THEN '04'
                ELSE '02'                 
             END) CCJ_TIPO_CONSIGNACION,         
             RCA_CONV_CONSECUTIVO AS RECO_CODIGO_PRI_8020,
             RCA_CODIGO_CONSIGNANTE AS RECO_CODIGO_SEG_8020,
             NVL(RRDN_RECO_FECHA_RECAUDO,RCA_FECHA) AS FECHA_RECAUDO,
             RCA.RCA_CICLO_ABONO AS CICLO_ABONO
        FROM RECIBOS_DE_CAJA RCA,
             TRANSFERENCIAS_CAJA TRC,
             BANCOS BAN,
             RECAUDOS_RECIBOS_DAVICASH_NEXT RRDN,
             CANALES CNA,
             PROCESO_INCREMENTO_DAVICASH PIDC
       WHERE RCA.RCA_CONSECUTIVO = TRC.TRC_RCA_CONSECUTIVO
         AND RCA.RCA_NEG_CONSECUTIVO = TRC.TRC_RCA_NEG_CONSECUTIVO
         AND RCA.RCA_SUC_CODIGO = TRC.TRC_RCA_SUC_CODIGO 
         AND RCA.RCA_CONSECUTIVO = RRDN.RRND_RECO_RCA_CONSECUTIVO (+)
         AND RCA.RCA_NEG_CONSECUTIVO = RRDN.RRDN_RECO_RCA_NEG_CONSECUTIVO (+)
         AND RCA.RCA_SUC_CODIGO = RRDN.RRDN_RECO_RCA_SUC_CODIGO (+)
         AND TRC.TRC_CBA_BAN_CODIGO = BAN.BAN_CODIGO
         AND RCA.RCA_COT_MNEMONICO = 'AXCB'
         --VAGTUS061820.AjusteMulticashFondosRecibosReversados
         AND pidc.pidc_rca_consecutivo = rca.rca_consecutivo
         AND pidc.pidc_rca_neg_consecutivo = rca.rca_neg_consecutivo
         AND pidc.pidc_rca_suc_codigo = rca.rca_suc_codigo
         AND (nvl(pidc.pidc_reversada, 'NO') = 'NO' OR
              (nvl(pidc.pidc_reversada, 'NO') = 'SI' AND pidc.pidc_rev_mcc_consecutivo IS NOT NULL AND pidc.pidc_rev_mcf_consecutivo IS NOT NULL))
         AND RCA.RCA_OFO_SUC_CODIGO = P_MCF_SUC_CODIGO
         AND RCA.RCA_OFO_CONSECUTIVO = P_MCF_OFO_CONSECUTIVO
		 AND RCA.RCA_CNL_CONSECUTIVO = CNA.CNL_CONSECUTIVO (+);

-------- Fin Cursor RECAUDOS ---------------------------------------------------

  C_RECAUDOS          RECAUDOS%ROWTYPE;
  SINO_CONV           VARCHAR2(1) := 'N';

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
  V_DESC              VARCHAR2(200) := 'movimiento del fondo ';
  v_numero_extracto   NUMBER;
  c_movimiento_dia    movimiento_dia%ROWTYPE; 
  c_saldo_anterior    saldo_anterior%ROWTYPE; 
  c_pagos             pagos%ROWTYPE;
  c_pagos_ach         pagos_ach%ROWTYPE;
  c_consecutivo       consecutivo%ROWTYPE;
  V_NOMBRE_ARCHIVO    VARCHAR2(100);
  V_PREFIJO_ARCHIVO   VARCHAR2(50);
  ERROR_EXTRACTO      EXCEPTION;
  ERROR_INFORME       EXCEPTION;
  CODIGO_SAP          VARCHAR2(4); 
  V_TIPO_INFORME      VARCHAR2(20);  
  EXTRACTO_ARCHIVO     UTL_FILE.FILE_TYPE; 
  P_NUM_INI  NUMBER;
  P_NUM_FIN  NUMBER; 

  V19_REV_DAVCASH     VARCHAR2(64);
  V25_ORDEN_FONDO     VARCHAR2(32);
  V26_RECIBO_CAJA     VARCHAR2(32);

  --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  V_FLG_COMP          VARCHAR2(8);
  V_FON_COMP          VARCHAR2(64);
  V_FECHA_INI         VARCHAR2(32);
  V_FECHA_FIN         VARCHAR2(32);  

  TYPE MOVDIA_REFCR   IS REF CURSOR;
  movdia              MOVDIA_REFCR;
  v_movdia_select     VARCHAR2(4000);
  v_movdia_cndFon     VARCHAR2(4000);  
  c_saldo_aporte      saldo_aporte%ROWTYPE;
  v_saldo_anterior    NUMBER;
  c_extracto          extracto%ROWTYPE;
  R_EXTRACTO_HIST     C_EXTRACTO_HIST%ROWTYPE;
  v_secuencia_rep     NUMBER;
  V_REPROCESO         VARCHAR2(32);

  --AJUSTES VAGTUD991
  V_CAMPO19_DEF VARCHAR2(10);

BEGIN
  P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS','INI');  
  v_archivo_cabecera  := 'CC'||TO_CHAR(P_FECHA_PROCESO_FIN-1,'DDMM')||lpad(TO_CHAR(p_cuenta_fondo),2,'00');
  v_archivo_detalle   := 'CD'||TO_CHAR(P_FECHA_PROCESO_FIN-1,'DDMM')||lpad(TO_CHAR(p_cuenta_fondo),2,'00');
  v_archivo_cabecera  := trim(v_archivo_cabecera);
  v_archivo_detalle   := trim(v_archivo_detalle);
  v_total_debitos     := 0;
  v_total_creditos    := 0;
  v_total_lineas      := 0;
  v_saldo_final       := 0;
  v_saldo_anterior    := 0;

  IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
    V_DESC := 'consolidado mensual de movimientos del fondo ';
  END IF;

  --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  IF P_TIPOREP = 'APORTE' THEN 
    V_FON_COMP := P_FON_CODIGO;
  ELSE    
    P_ORDENES_FONDOS.P_VALIDA_PARAMETROS_COMP(P_FON_CODIGO         => P_FON_CODIGO,
                                              P_PAR_CODIGO         => 70,
                                              P_PFO_RANGO_MIN_CHAR => V_FLG_COMP);
    IF NVL(V_FLG_COMP, 'N') = 'S' THEN 
      P_ORDENES_FONDOS.P_VALIDA_PARAMETROS_COMP(P_FON_CODIGO         => P_FON_CODIGO,
                                                P_PAR_CODIGO         => 71,
                                                P_PFO_RANGO_MIN_CHAR => V_FON_COMP);
    ELSE
      V_FON_COMP := P_FON_CODIGO;
    END IF;
  END IF;

  OPEN CONSECUTIVO(V_FON_COMP);
  FETCH CONSECUTIVO INTO C_CONSECUTIVO;
  IF CONSECUTIVO%NOTFOUND THEN
    RAISE ERROR_EXTRACTO;
  END IF;  
  CLOSE CONSECUTIVO;  

  --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  IF P_RANGREP = 'D' THEN 
    IF C_CONSECUTIVO.CXS_NUMERO_EXTRACTO IS NULL OR
       C_CONSECUTIVO.CXS_CONSTANTE_CUENTA_SAP IS NULL THEN
      RAISE ERROR_EXTRACTO;
    END IF; 
  ELSIF P_RANGREP = 'R' THEN 
    IF C_CONSECUTIVO.CXS_NUMERO_EXTRACTO_MENSUAL IS NULL OR
       C_CONSECUTIVO.CXS_CONSTANTE_CUENTA_SAP IS NULL THEN
      RAISE ERROR_EXTRACTO;
    END IF;
  END IF;

  OPEN C_TIPO_INFORME(V_FON_COMP);
  FETCH C_TIPO_INFORME INTO V_TIPO_INFORME;
  IF C_TIPO_INFORME%NOTFOUND THEN
    RAISE ERROR_INFORME;
  END IF;
  CLOSE C_TIPO_INFORME;

  OPEN extracto(V_FON_COMP);
  FETCH extracto INTO c_extracto;
    IF extracto%FOUND THEN 
      IF P_RANGREP = 'D' AND P_REPROCESO = 'N' THEN
        V_NUMERO_EXTRACTO := NVL(C_CONSECUTIVO.CXS_NUMERO_EXTRACTO,0) + 1;
      ELSIF P_RANGREP = 'R' AND P_REPROCESO = 'N' THEN 
        V_NUMERO_EXTRACTO := NVL(C_CONSECUTIVO.CXS_NUMERO_EXTRACTO_MENSUAL, 0) + 1;
      ELSIF P_RANGREP = 'D' AND P_REPROCESO = 'S' THEN 
        OPEN C_EXTRACTO_HIST(P_FECHA_PROCESO_INI, V_FON_COMP, C_EXTRACTO.EXT_CONSECUTIVO);
        FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
        IF C_EXTRACTO_HIST%FOUND THEN 
          WHILE C_EXTRACTO_HIST%FOUND LOOP
            IF R_EXTRACTO_HIST.HCXS_EXT_FON_CODIGO = P_FON_CODIGO AND R_EXTRACTO_HIST.HCXS_TIPO_GENERACION = P_RANGREP THEN 
              V_NUMERO_EXTRACTO := R_EXTRACTO_HIST.HCXS_CXS_NUMERO_EXTRACTO;          
            END IF;
            FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
          END LOOP;
        ELSE
          V_NUMERO_EXTRACTO := NVL(C_CONSECUTIVO.CXS_NUMERO_EXTRACTO,0);
        END IF; 
        CLOSE C_EXTRACTO_HIST;

      ELSIF P_RANGREP = 'R' AND P_REPROCESO = 'S' THEN 
        OPEN C_EXTRACTO_HIST(LAST_DAY(P_FECHA_PROCESO_INI), V_FON_COMP, C_EXTRACTO.EXT_CONSECUTIVO);
        FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
        IF C_EXTRACTO_HIST%FOUND THEN 
          WHILE C_EXTRACTO_HIST%FOUND LOOP
            IF R_EXTRACTO_HIST.HCXS_EXT_FON_CODIGO = P_FON_CODIGO AND R_EXTRACTO_HIST.HCXS_TIPO_GENERACION = P_RANGREP THEN 
              V_NUMERO_EXTRACTO := R_EXTRACTO_HIST.HCXS_CXS_NUMERO_EXTRACTO_MES;          
            END IF;
            FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
          END LOOP;
        ELSE
          V_NUMERO_EXTRACTO := NVL(C_CONSECUTIVO.CXS_NUMERO_EXTRACTO_MENSUAL, 0);
        END IF;
        CLOSE C_EXTRACTO_HIST;

      ELSE 
        V_NUMERO_EXTRACTO := NVL(C_CONSECUTIVO.CXS_NUMERO_EXTRACTO, 0);
      END IF; 
    ELSE
      RAISE ERROR_EXTRACTO;
    END IF;
  CLOSE extracto;

  IF nvl(P_REPROCESO, 'N') = 'S' THEN 
    V_REPROCESO := ' (Reproceso) ';
  END IF;


  /* Inicio cracion achivo detalle */
  conn := p_mail.begin_mail(sender     => 'MULTICASH@CORREDORES.COM', 
                            recipients   => P_CADENA_ENVIO,
                            subject      => 'Informacion fondo '||P_FON_CODIGO||'-'||P_FON_DESCRIPCION || V_REPROCESO,
                            mime_type    => p_mail.MULTIPART_MIME_TYPE);
  p_mail.attach_text(conn      => conn,
                     data      => '<html>'||
                                     '<head>'||
                                       '<IMG src=https://zonatransaccional.corredores.com/CorredoresEnLinea/App_Themes/Default/images/imagen_header.jpg>'||
                                     '</head>'||
                                     '<body FACE=arial> '||
                                     '<table>'||
                                     '<font size=2 face=Arial Black>'||
                                       '<br/><br/><br/><br/><br/><br/>'||
                                          'Estamos remitiendo informacion del ' || V_DESC ||P_FON_CODIGO||' '||
                                           P_FON_DESCRIPCION||' '||
                                          ' con fecha de corte al: '||to_char(P_FECHA_PROCESO_FIN-1,'dd-mon-yyyy')||
                                         '<br/><br/><br/><br/><br/><br/>'||
                                         ' Atentamente,'||
                                         '<br/><br/><br/><br/>'||
                                         '<B>'||'DAVIVIENDA CORREDORES'||'</B>'||
                                         '<br/><br/><br/><br/><br/><br/>'||
                                       '<br/><br/><br/>'||
                                       '</td>'||
                                       '</font>'||
                                    '<table>'||
                                    '</body>'||                                    
                                  '</html>',
                     mime_type => 'text/html');
  p_mail.begin_attachment(conn         => conn,
                           mime_type    => v_archivo_detalle||'/txt',
                           inline       => TRUE,
                           filename     => v_archivo_detalle||'.txt',
                           transfer_enc => 'text');     

  IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
    V_NOMBRE_ARCHIVO := P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || replace(P_FON_MNEMONICO,'-','_')
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '-' || 'DCM'
                    || '.txt';
  ELSE
    V_NOMBRE_ARCHIVO := P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || replace(P_FON_MNEMONICO,'-','_')
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '-' || 'DC'
                    || '.txt';
  END IF;

  EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR', V_NOMBRE_ARCHIVO ,'W');  


  ------------------------------------------------------------------------------
  --- OBTENER EL CODIGO SAP DE ACUERDO A LA CONFIGURACIÓN DEL CLIENTE
  ------------------------------------------------------------------------------

  IF P_CLI_PER_NUM_IDEN = '860024151' AND P_CLI_PER_TID_CODIGO = 'NIT' THEN
      CODIGO_SAP := 'FV30';
  ELSIF P_CLI_PER_NUM_IDEN = '900422614' AND P_CLI_PER_TID_CODIGO = 'NIT' THEN
      CODIGO_SAP := 'FV31';
  ELSIF P_CLI_PER_NUM_IDEN = '860031606' AND P_CLI_PER_TID_CODIGO = 'NIT' THEN
      CODIGO_SAP := '26';
  ELSIF V_TIPO_INFORME = 'S26' THEN
      CODIGO_SAP := '026'; -- SE LE COLOCA EL 0 YA QUE ANTERIOMENTE SOLO ESTABA 26
  ELSE
      CODIGO_SAP := '026';
  END IF; 
  ------------------------------------------------------------------------------                         

  --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash
  V_FECHA_INI := to_char(P_FECHA_PROCESO_INI, 'dd/mm/yyyy');
  V_FECHA_FIN := to_char(P_FECHA_PROCESO_FIN, 'dd/mm/yyyy');

  --- AJUSTE VAGTUD991
  V_CAMPO19_DEF := '';

  IF P_TIPOREP = 'APORTE' THEN 
    v_movdia_cndFon := 
    'AND   MCF_CFO_FON_CODIGO IN ' ||
    '  (SELECT PFO.PFO_FON_CODIGO ' ||
    '   FROM   PARAMETROS_FONDOS PFO ' ||
    '   WHERE  PFO.PFO_PAR_CODIGO = 71 ' ||
    '   AND    PFO_RANGO_MIN_CHAR = ' || '''' ||P_FON_CODIGO || '''' ||
    '   MINUS ' ||
    '   SELECT PFO.PFO_FON_CODIGO ' ||
    '   FROM   PARAMETROS_FONDOS PFO ' ||
    '   WHERE  PFO.PFO_PAR_CODIGO = 115 ' ||
    '   AND    PFO_RANGO_MIN_CHAR = ''S'') ';
  ELSE 
    v_movdia_cndFon := 
    'AND   MCF_CFO_FON_CODIGO IN ( ' || '''' ||P_FON_CODIGO || '''' || ') ';
  END IF;

  v_movdia_select := 
    'SELECT DISTINCT TO_CHAR(MCF_FECHA, ''dd.mm.yy'') MCF_FECHA1 ' ||
    '               ,MCF_TMF_MNEMONICO ' ||
    '               ,MCF_OFO_CONSECUTIVO ' ||
    '               ,MCF_OFO_SUC_CODIGO ' ||
    '               ,MCF_RETEFUENTE_MOVIMIENTO ' ||
    '               ,MCF_CAPITAL + MCF_RENDIMIENTOS_RF + MCF_RENDIMIENTOS_RV - MCF_RETEFUENTE_MOVIMIENTO MONTO ' ||
    '               ,MCF_CAPITAL - MCF_RETEFUENTE_MOVIMIENTO MONTONOREND ' ||
    '               ,MCF_RENDIMIENTOS_RF + MCF_RENDIMIENTOS_RV RENDIMEINTOS ' ||
    '               ,MCF_CAPITAL + MCF_RENDIMIENTOS_RF + MCF_RENDIMIENTOS_RV MONTO2 ' ||
    '               ,MCF_SALDO_CAPITAL + MCF_SALDO_RENDIMIENTOS_RF + MCF_SALDO_RENDIMIENTOS_RV SALDO_FINAL ' ||
    '               ,OFO_TTO_TOF_CODIGO ' ||
    '               ,OFO_CONCEPTO_COBRO_APT ' ||
    '               ,OFO_CONCEPTO_INC_APT ' ||
    '               ,TO_CHAR(NVL(OFO_FECHA_EJECUCION, MCF_FECHA), ''dd.mm.yy'') OFO_FECHA_EJECUCION ' ||
    '               ,NULL CICLO_ABONO ' ||
    '               ,MCF_CONSECUTIVO ' ||
    'FROM   ORDENES_FONDOS, MOVIMIENTOS_CUENTAS_FONDOS, RECIBOS_DE_CAJA ' ||
    'WHERE  OFO_CONSECUTIVO(+) = MCF_OFO_CONSECUTIVO ' ||
    'AND    OFO_SUC_CODIGO(+) = MCF_OFO_SUC_CODIGO ' ||
    'AND    OFO_CONSECUTIVO = RCA_OFO_CONSECUTIVO(+) ' ||
    'AND    OFO_SUC_CODIGO = RCA_OFO_SUC_CODIGO(+) ' ||
    'AND    MCF_CFO_CCC_CLI_PER_NUM_IDEN = ' || '''' || P_CLI_PER_NUM_IDEN || '''' ||
    'AND    MCF_CFO_CCC_CLI_PER_TID_CODIGO = ' || '''' ||P_CLI_PER_TID_CODIGO || '''' ||
    'AND    MCF_CFO_CCC_NUMERO_CUENTA = ' || P_NUMERO_CUENTA ||
    ' ' || v_movdia_cndFon || ' ' ||
    'AND    MCF_CFO_CODIGO = ' || P_CUENTA_FONDO ||
    'AND    MCF_FECHA >= to_date(' || '''' || V_FECHA_INI || '''' || ', ''dd/mm/yyyy'') ' ||
    'AND    MCF_FECHA < to_date(' || '''' || V_FECHA_FIN || '''' || ', ''dd/mm/yyyy'') ' ||
    'AND    MCF_TMF_MNEMONICO NOT IN (''RSC'') ' ||
    'ORDER  BY MCF_CONSECUTIVO ASC ';

  OPEN movdia FOR v_movdia_select;

  LOOP
    FETCH movdia INTO c_movimiento_dia;
    EXIT WHEN movdia%NOTFOUND;

    --VAGTUD861-SP02HU03.ReporteriaOrdenesDavicash
    OPEN C_RCA_CICLO(C_MOVIMIENTO_DIA.MCF_OFO_CONSECUTIVO, C_MOVIMIENTO_DIA.MCF_OFO_SUC_CODIGO);
    FETCH C_RCA_CICLO INTO C_MOVIMIENTO_DIA.CICLO_ABONO;
    CLOSE C_RCA_CICLO; 

      --VAGTUD861-SP05HU02.ParticipacionesReporteriaDavicash   
      IF P_TIPOREP = 'APORTE' THEN 
        v_saldo_final := 0;
      ELSE 
        v_saldo_final := c_movimiento_dia.saldo_final;
      END IF;

      IF c_movimiento_dia.mcf_tmf_mnemonico = 'R' THEN    
        IF c_movimiento_dia.montoNoRend < 0 THEN
          v_signo := '-';
          v_total_debitos := v_total_debitos + abs(c_movimiento_dia.montoNoRend);
        ELSE
          v_signo := '+';
          v_total_creditos := v_total_creditos + abs(c_movimiento_dia.montoNoRend);
        END IF;

        --VAGTUD861-SP02_HU03.ReporteriaOrdenes
        V19_REV_DAVCASH := '';          -- AJUSTE VAGTUD991
        V25_ORDEN_FONDO := '';
        V26_RECIBO_CAJA := '';
        OPEN C_MVTOSDAV_REV(C_MOVIMIENTO_DIA.MCF_OFO_CONSECUTIVO, C_MOVIMIENTO_DIA.MCF_OFO_SUC_CODIGO, C_MOVIMIENTO_DIA.MCF_CONSECUTIVO);
        FETCH C_MVTOSDAV_REV INTO R_MVTOSDAV_REV;
          IF C_MVTOSDAV_REV%FOUND THEN 
            V25_ORDEN_FONDO := TO_CHAR(R_MVTOSDAV_REV.PIDC_OFO_CONSECUTIVO);
            V26_RECIBO_CAJA := TO_CHAR(R_MVTOSDAV_REV.PIDC_RCA_CONSECUTIVO);
            BEGIN 
              SELECT SUBSTR(TO_CHAR(RRDN.RRDN_RECO_CODIGO_SEG_8020),1,63) RECO_CODIGO_SEG_8020
              INTO   V19_REV_DAVCASH
              FROM   RECAUDOS_RECIBOS_DAVICASH_NEXT RRDN 
              WHERE  RRDN.RRND_RECO_RCA_CONSECUTIVO = V26_RECIBO_CAJA; 
            EXCEPTION WHEN OTHERS THEN 
              V19_REV_DAVCASH := '';        -- VAGTUD991
            END;          
          END IF;
        CLOSE C_MVTOSDAV_REV;
        --

        v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                           -- 1. clave del banco
                   --TRIM(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador||   -- 2. cuenta bancaria
                   TRIM(P_CUENTA)||v_separador||                                                                              -- 2. cuenta bancaria
                   v_numero_extracto||v_separador||                                                                           --3. consecutivo extracto
                   c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                   v_separador||                                                                                              --5. no usado
                   v_separador||                                                                                              --6. no usado
                  'R'||trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                               --7. codigo interno de la transaccion
                   v_separador||                                                                                              --8. no usado
                   v_separador||                                                                                              --9. no usado
                   '/'||v_separador||                                                                                         --10.numero de cheques default  /
                   v_signo||trim(to_char(abs(c_movimiento_dia.montoNoRend),'999999999999999990.00'))||v_separador||                 --11.valor movimiento
                   v_separador||                                                                                              --12. no usado
                   v_separador||                                                                                              --13. no usado
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente 
                   '/'||v_separador||                                                                                         --18. default  /
                   V19_REV_DAVCASH ||v_separador||                                                                            --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
                   V25_ORDEN_FONDO || v_separador||                                                                           --25. VAGTUD861-SP02_HU03.Reporteria Orden fondo reversada
                   V26_RECIBO_CAJA || v_separador||                                                                           --26. VAGTUD861-SP02_HU03.Reporteria Recibo de caja anulado
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
      --inicio VAGTUS036268 separar rendiemientos de capital en las reverciones de incrementos o ingresos.
      IF c_movimiento_dia.rendimeintos < 0 THEN
          v_signo := '-';
          v_total_debitos := v_total_debitos + abs(c_movimiento_dia.rendimeintos);
        ELSE
          v_signo := '+';
          v_total_creditos := v_total_creditos + abs(c_movimiento_dia.rendimeintos);
        END IF;
        v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                           -- 1. clave del banco
                   --TRIM(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador||   -- 2. cuenta bancaria
                   TRIM(P_CUENTA)||v_separador||                                                                              -- 2. cuenta bancaria
                   v_numero_extracto||v_separador||                                                                           --3. consecutivo extracto
                   c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                   v_separador||                                                                                              --5. no usado
                   v_separador||                                                                                              --6. no usado
                  'RR'||v_separador||                                                                                         --7. codigo interno de la transaccion
                   v_separador||                                                                                              --8. no usado
                   v_separador||                                                                                              --9. no usado
                   '/'||v_separador||                                                                                         --10.numero de cheques default  /
                   v_signo||trim(to_char(abs(c_movimiento_dia.rendimeintos),'999999999999999990.00'))||v_separador||                 --11.valor movimiento
                   v_separador||                                                                                              --12. no usado
                   v_separador||                                                                                              --13. no usado
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente 
                   '/'||v_separador||                                                                                         --18. default  /
                   V19_REV_DAVCASH ||v_separador||                                                                            --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
                   V25_ORDEN_FONDO || v_separador||                                                                           --25. VAGTUD861-SP02_HU03.Reporteria Orden fondo reversada
                   V26_RECIBO_CAJA || v_separador||                                                                           --26. VAGTUD861-SP02_HU03.Reporteria Recibo de caja anulado
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
      --fin VAGTUS036268 separar rendiemientos de capital en las reverciones de incrementos o ingresos.



        IF NVL(c_movimiento_dia.mcf_retefuente_movimiento,0) <> 0 THEN
          IF c_movimiento_dia.mcf_retefuente_movimiento < 0 THEN
            v_signo := '-';
            v_total_debitos := v_total_debitos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
          ELSE
            v_signo := '+';
            v_total_creditos := v_total_creditos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
          END IF;
          v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                        --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente 
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
        SINO_CONV := P_BANCOS.FN_ES_CONVENIO (P_OFO_SUC_CODIGO  => C_MOVIMIENTO_DIA.MCF_OFO_SUC_CODIGO,
                                              P_OFO_CONSECUTIVO => C_MOVIMIENTO_DIA.MCF_OFO_CONSECUTIVO);

        IF c_movimiento_dia.ofo_tto_tof_codigo IN ('RP','RT') THEN      
          v_total_pagos       := 0;
          IF c_movimiento_dia.ofo_concepto_cobro_apt IS NOT NULL THEN
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     trim(c_movimiento_dia.ofo_concepto_cobro_apt)||v_separador||                                                             --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador||                                                                                              --9. no usado
                     '/'||v_separador||                                                                                         --10.numero de cheques default  /
                     v_signo||trim(to_char(abs(c_movimiento_dia.monto),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
                v_total_pagos := v_total_pagos+abs(c_movimiento_dia.monto);
                p_mail.write_mb_text(conn,v_linea||CRLF);   
                UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);              
                v_total_lineas := v_total_lineas+1;          
          ELSE
            -- PAGOS
         OPEN pagos(c_movimiento_dia.mcf_ofo_suc_codigo,c_movimiento_dia.mcf_ofo_consecutivo);
            FETCH pagos INTO c_pagos;
            WHILE pagos%FOUND LOOP

         IF c_pagos.odp_tpa_mnemonico IN ('CHE','CHG') THEN

          IF V_TIPO_INFORME = 'S26' THEN -- PARA TERPEL

          v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     --trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                                 --7. codigo interno de la transaccion
                     trim(c_pagos.odp_tpa_mnemonico)||v_separador||                                                             --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador;                                                                                               --9. no usado
                     IF c_pagos.odp_tpa_mnemonico IN ('CHG') THEN
                       v_linea := v_linea||'/'||v_separador;                                                                  --10.numero de cheques default  /
                     ELSE                         
                       v_linea := v_linea||trim(c_pagos.ceg_numero_cheque)||v_separador;                                                            --10.numero de cheques default  /
                     END IF;
                     v_linea := v_linea||v_signo||trim(to_char(abs(c_pagos.odp_monto_orden),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                 --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador;                                                                                               --16. no usado                 
                     v_linea := v_linea||NVL(trim(TO_CHAR(c_pagos.odp_num_iden)), '/')||v_separador;                            --17. nit tercero
                     v_linea := v_linea||'/'||v_separador||                                                                     --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'a') || v_separador||                                      --24. Ciclo del abono
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
          ELSE --PARA OTRAS ESTRUCTURAS
                v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     --trim(c_movimiento_dia.ofo_tto_tof_codigo)||v_separador||                                                 --7. codigo interno de la transaccion
                     trim(c_pagos.odp_tpa_mnemonico)||v_separador||                                                             --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador;                                                                                               --9. no usado
                     IF c_pagos.odp_tpa_mnemonico IN ('CHG') THEN
                       v_linea := v_linea||'/'||v_separador;                                                                  --10.numero de cheques default  /
                     ELSE                         
                       v_linea := v_linea||trim(c_pagos.ceg_numero_cheque)||v_separador;                                                            --10.numero de cheques default  /
                     END IF;
                     v_linea := v_linea||v_signo||trim(to_char(abs(c_pagos.odp_monto_orden),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
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
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
              ELSIF c_pagos.odp_tpa_mnemonico IN ('PSE','TRB') THEN

           IF V_TIPO_INFORME = 'S26' THEN -- PARA TERPEL
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     trim(c_pagos.odp_tpa_mnemonico)||v_separador||                                                             --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador||                                                                                              --9. no usado
                     '/'||v_separador||                                                                                         --10.numero de cheques default  /
                     v_signo||trim(to_char(abs(c_pagos.odp_monto_orden),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     NVL(trim(TO_CHAR(c_pagos.odp_num_iden)), '/')||v_separador||                                               --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
          ELSE -- OTRAS ESTRUCTURAS 
                v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     trim(c_pagos.odp_tpa_mnemonico)||v_separador||                                                             --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador||                                                                                              --9. no usado
                     '/'||v_separador||                                                                                         --10.numero de cheques default  /
                     v_signo||trim(to_char(abs(c_pagos.odp_monto_orden),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                 --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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

              ELSIF   c_pagos.odp_tpa_mnemonico IN ('ACH') THEN
                OPEN   pagos_ach(c_pagos.odp_consecutivo,
                                 c_pagos.odp_suc_codigo,
                                 c_pagos.odp_neg_consecutivo);
                FETCH pagos_ach INTO c_pagos_ach;
                WHILE pagos_ach%FOUND LOOP
             IF V_TIPO_INFORME = 'S26' THEN -- PARA TERPEL
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     trim(case c_pagos_ach.dpa_tcb_mnemonico when 'DP' then c_pagos_ach.dpa_tcb_mnemonico else c_pagos.odp_tpa_mnemonico end)||v_separador||      --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador||                                                                                              --9. no usado
                     '/'||v_separador||                                                                                         --10.numero de cheques default  /
                     v_signo||trim(to_char(abs(c_pagos_ach.dpa_monto),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     NVL(trim(TO_CHAR(c_pagos.odp_num_iden)), '/')/*c_pagos_ach.dpa_num_iden*/||v_separador||                   --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
                  v_total_pagos := v_total_pagos+c_pagos_ach.dpa_monto;
                  p_mail.write_mb_text(conn,v_linea||CRLF);   
                  UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);                
                  v_total_lineas := v_total_lineas+1;
            ELSE -- OTRAS ESTRUCTURAS
                  v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                     TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                     v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                     c_movimiento_dia.mcf_fecha1||v_separador||                                                                 --4. fecha movimiento afecto el saldo
                     v_separador||                                                                                              --5. no usado
                     v_separador||                                                                                              --6. no usado
                     trim(case c_pagos_ach.dpa_tcb_mnemonico when 'DP' then c_pagos_ach.dpa_tcb_mnemonico else c_pagos.odp_tpa_mnemonico end)||v_separador||                                                             --7. codigo interno de la transaccion se tomo el tipo de movimiento
                     v_separador||                                                                                              --8. no usado
                     v_separador||                                                                                              --9. no usado
                     '/'||v_separador||                                                                                         --10.numero de cheques default  /
                     v_signo||trim(to_char(abs(c_pagos_ach.dpa_monto),'999999999999999990.00'))||v_separador||                --11.valor movimiento
                     v_separador||                                                                                              --12. no usado
                     v_separador||                                                                                              --13. no usado
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     c_pagos_ach.dpa_num_iden||v_separador||                                                                          --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
                  v_total_pagos := v_total_pagos+c_pagos_ach.dpa_monto;
                  p_mail.write_mb_text(conn,v_linea||CRLF);   
                  UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);                
                  v_total_lineas := v_total_lineas+1;    
             END IF;
                  FETCH pagos_ach INTO c_pagos_ach;
                END LOOP;
                CLOSE pagos_ach; 

              ELSE
          IF V_TIPO_INFORME = 'S26' THEN -- PARA TERPEL
          v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                 --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     NVL(trim(TO_CHAR(c_pagos.odp_num_iden)), '/')/*P_CLI_PER_NUM_IDEN*/||v_separador||                         --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
          ELSE -- OTRAS ESTRUCTURAS
                v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                     c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                     v_separador||                                                                                              --15. no usado
                     v_separador||                                                                                              --16. no usado                                  
                     P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                     '/'||v_separador||                                                                                         --18. default  /
                     V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                     '/'||v_separador||                                                                                         --20. causal de rechazo default /
                     '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                     '/'||v_separador||                                                                                         --22. default /
                     v_separador||                                                                                              --23. no usado
                     NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
              END IF;
              FETCH pagos INTO c_pagos;
            END LOOP;
            CLOSE pagos;
          END IF;

          IF v_total_pagos < abs(c_movimiento_dia.monto) THEN
            v_total_pagos := c_movimiento_dia.monto - v_total_pagos;          
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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

      -- RECAUDOS  
        ELSIF C_MOVIMIENTO_DIA.OFO_TTO_TOF_CODIGO ='INC' AND NVL(SINO_CONV,'N') = 'S' THEN      
          OPEN RECAUDOS(c_movimiento_dia.mcf_ofo_suc_codigo,c_movimiento_dia.mcf_ofo_consecutivo);
          FETCH RECAUDOS INTO C_RECAUDOS;
          IF RECAUDOS%FOUND THEN
             WHILE RECAUDOS%FOUND LOOP

             --TRAER DE LA PIDC LOS DATOS DE LA OFO PARA QUE APLIQUE A SOLO CONSOLIDADOS
             V25_ORDEN_FONDO := '';
             V26_RECIBO_CAJA := '';
             OPEN C_MVTOSDAV_REC(C_RECAUDOS.RCA_CONSECUTIVO, C_RECAUDOS.RCA_NEG_CONSECUTIVO, C_RECAUDOS.RCA_SUC_CODIGO);
             FETCH C_MVTOSDAV_REC INTO R_MVTOSDAV_REC;
             IF C_MVTOSDAV_REC%FOUND THEN 
               V25_ORDEN_FONDO := TO_CHAR(R_MVTOSDAV_REC.PIDC_OFO_CONSECUTIVO);
               V26_RECIBO_CAJA := TO_CHAR(R_MVTOSDAV_REC.PIDC_RCA_CONSECUTIVO);
             END IF;
             CLOSE C_MVTOSDAV_REC;

             IF V_TIPO_INFORME = 'S26' THEN
                 v_linea := RTRIM(CODIGO_SAP)||V_SEPARADOR||  --Estaba fijo como 026                                                                              -- 1. clave del banco
                      TRIM(P_CUENTA)||V_SEPARADOR||                                                                            -- 2. cuenta bancaria
                      V_NUMERO_EXTRACTO||V_SEPARADOR||                                                                         --3. consecutivo extracto
                      C_MOVIMIENTO_DIA.MCF_FECHA1||V_SEPARADOR||                                                               --4. fecha movimiento afecto el saldo
                      V_SEPARADOR||                                                                                            --5. no usado
                      V_SEPARADOR||                                                                                            --6. no usado
                      'REC'||V_SEPARADOR||                                                                                     --7. codigo interno de la transaccion
                      V_SEPARADOR||                                                                                              --8. no usado
                      V_SEPARADOR||                                                                                              --9. no usado
                      V_SEPARADOR||                                                                                             --10.numero de cheques default  /
                      V_SIGNO||TRIM(TO_CHAR(ABS(C_RECAUDOS.CCJ_MONTO),'999999999999999990.00'))||V_SEPARADOR||                  --11.valor movimiento
                      V_SEPARADOR||                                                                                              --12. no usado
                      V_SEPARADOR||                                                                                              --13. no usado
                      C_MOVIMIENTO_DIA.ofo_fecha_ejecucion ||V_SEPARADOR||                                                                  --14. fecha origen movimiento
                      V_SEPARADOR||                                                                                              --15. no usado
                      V_SEPARADOR||                                                                                              --16. no usado                 
                      NVL(C_RECAUDOS.RCA_NUM_IDEN_CONSIGNANTE,'/' /*C_RECAUDOS.RECO_CODIGO_SEG_8020*/)||V_SEPARADOR||                                                             --17. Segundo 8020 solo para Terpel
                      C_RECAUDOS.CCJ_TIPO_CONSIGNACION||V_SEPARADOR||                                                            --18. 01 cheque  02:efectivo 03 mixto 04 PSED
                      C_RECAUDOS.BAN_NIT||V_SEPARADOR||                                                                          --19. Nit del Banco solo terpel
                      '/'||V_SEPARADOR||                                                                                         --20. causal de rechazo default /
                      '/'||V_SEPARADOR||                                                                                         --21. codigo transacion banco default /
                      '/'||V_SEPARADOR||                                                                                         --22. default /
                      TO_CHAR(C_RECAUDOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                                --23. Fecha original del recaudo solo Terpel
                      NVL(TRIM(TO_CHAR(C_RECAUDOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                            --24. Ciclo del abono
                      V25_ORDEN_FONDO || V_SEPARADOR||                                                                           --25. no usado
                      V26_RECIBO_CAJA || V_SEPARADOR||                                                                           --26. no usado
                      V_SEPARADOR||                                                                                              --27. no usado
                      V_SEPARADOR||                                                                                              --28. no usado
                      V_SEPARADOR||                                                                                              --29. no usado
                      V_SEPARADOR||                                                                                              --30. no usado
                      V_SEPARADOR||                                                                                              --31. no usado
                      V_SEPARADOR||                                                                                              --32. no usado
                      V_SEPARADOR||                                                                                              --33. no usado
                      V_SEPARADOR||                                                                                              --34. no usado
                      V_SEPARADOR||                                                                                              --35. no usado
                      V_SEPARADOR;                                                                                               --36  no usado            
                 p_mail.write_mb_text(conn,v_linea||CRLF);   
                 UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
                 V_TOTAL_LINEAS := V_TOTAL_LINEAS+1;
                 FETCH RECAUDOS INTO C_RECAUDOS;
                 ELSE
                  v_linea := RTRIM(CODIGO_SAP)||V_SEPARADOR||  --Estaba fijo como 026                                                                              -- 1. clave del banco
                      TRIM(P_CUENTA)||V_SEPARADOR||                                                                            -- 2. cuenta bancaria
                      V_NUMERO_EXTRACTO||V_SEPARADOR||                                                                         --3. consecutivo extracto
                      C_MOVIMIENTO_DIA.MCF_FECHA1||V_SEPARADOR||                                                               --4. fecha movimiento afecto el saldo
                      V_SEPARADOR||                                                                                            --5. no usado
                      V_SEPARADOR||                                                                                            --6. no usado
                      'REC'||V_SEPARADOR||                                                                                     --7. codigo interno de la transaccion
                      V_SEPARADOR||                                                                                              --8. no usado
                      V_SEPARADOR||                                                                                              --9. no usado
                      V_SEPARADOR||                                                                                             --10.numero de cheques default  /
                      V_SIGNO||TRIM(TO_CHAR(ABS(C_RECAUDOS.CCJ_MONTO),'999999999999999990.00'))||V_SEPARADOR||                --11.valor movimiento
                      V_SEPARADOR||                                                                                              --12. no usado
                      V_SEPARADOR||                                                                                              --13. no usado
                      C_MOVIMIENTO_DIA.ofo_fecha_ejecucion ||V_SEPARADOR||                                                                  --14. fecha origen movimiento
                      V_SEPARADOR||                                                                                              --15. no usado
                      V_SEPARADOR||                                                                                              --16. no usado                 
                      C_RECAUDOS.BAN_NIT||V_SEPARADOR||                                                                         --17. nit del banco para recaudos
                      C_RECAUDOS.CCJ_TIPO_CONSIGNACION||V_SEPARADOR||                                                            --18. 01 cheque  02:efectivo 03 mixto 04 PSED
                      C_RECAUDOS.RECO_CODIGO_SEG_8020||V_SEPARADOR||                                                             --19. Referencia de quien consigna : referencia 2 convenio
                      '/'||V_SEPARADOR||                                                                                         --20. causal de rechazo default /
                      '/'||V_SEPARADOR||                                                                                         --21. codigo transacion banco default /
                      '/'||V_SEPARADOR||                                                                                         --22. default /
                      V_SEPARADOR||                                                                                              --23. no usado
                      NVL(TRIM(TO_CHAR(C_RECAUDOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                            --24. Ciclo del abono
                      V25_ORDEN_FONDO || V_SEPARADOR||                                                                           --25. no usado
                      V26_RECIBO_CAJA || V_SEPARADOR||                                                                           --26. no usado
                      V_SEPARADOR||                                                                                              --27. no usado
                      V_SEPARADOR||                                                                                              --28. no usado
                      V_SEPARADOR||                                                                                              --29. no usado
                      V_SEPARADOR||                                                                                              --30. no usado
                      V_SEPARADOR||                                                                                              --31. no usado
                      V_SEPARADOR||                                                                                              --32. no usado
                      V_SEPARADOR||                                                                                              --33. no usado
                      V_SEPARADOR||                                                                                              --34. no usado
                      V_SEPARADOR||                                                                                              --35. no usado
                      V_SEPARADOR;                                                                                               --36  no usado            
                 p_mail.write_mb_text(conn,v_linea||CRLF);   
                 UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);            
                 V_TOTAL_LINEAS := V_TOTAL_LINEAS+1;
                 FETCH RECAUDOS INTO C_RECAUDOS;               
                 END IF;
             END LOOP;

          ELSE -- SI NO ENCUENTRA RECIBOS DE CAJA, COLOCA UN MOVIMIENTO POR LA ORDEN
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
          CLOSE RECAUDOS;
        ELSE
          IF c_movimiento_dia.ofo_concepto_inc_apt is not null AND c_movimiento_dia.ofo_tto_tof_codigo = 'INC' THEN
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
                   --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2. cuenta bancaria
                   TRIM(P_CUENTA)||v_separador||                                                                            -- 2. cuenta bancaria
                   v_numero_extracto||v_separador||                                                                                      --3. consecutivo extracto
                   c_movimiento_dia.mcf_fecha1||v_separador||                                                                  --4. fecha movimiento afecto el saldo
                   v_separador||                                                                                              --5. no usado
                   v_separador||                                                                                              --6. no usado
                   trim(c_movimiento_dia.ofo_concepto_inc_apt)||v_separador||                                                                                       --7. codigo interno de la transaccion
                   v_separador||                                                                                              --8. no usado
                   v_separador||                                                                                              --9. no usado
                   '/'||v_separador||                                                                                         --10.numero de cheques default  /
                   v_signo||trim(to_char(abs(c_movimiento_dia.monto),'999999999999999990.00'))||v_separador||                 --11.valor movimiento
                   v_separador||                                                                                              --12. no usado
                   v_separador||                                                                                              --13. no usado
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
            v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
        END IF;
        IF nvl(c_movimiento_dia.mcf_retefuente_movimiento,0) <> 0 THEN
          IF c_movimiento_dia.mcf_retefuente_movimiento < 0 THEN
            v_signo := '-';
            v_total_debitos := v_total_debitos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
          ELSE
            v_signo := '+';
            v_total_creditos := v_total_creditos + abs(c_movimiento_dia.mcf_retefuente_movimiento);
          END IF;
          v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
        v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
        v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
        -- VAGTUD991 - PARA EL TIPO DE REPORTE APORTE LOS MOVIMIENTOS RTC E ITC NO SE TIENEN EN CUENTA PARA EL TOTAL DE DEBITOS Y CREDITOS
        IF c_movimiento_dia.monto2 < 0 THEN
            v_signo := '-';
            IF P_TIPOREP = 'APORTE' AND c_movimiento_dia.mcf_tmf_mnemonico IN ('RTC','ITC') THEN
               NULL;
            ELSE
               v_total_debitos := v_total_debitos + abs(c_movimiento_dia.monto2);
            END IF;
        ELSE
            v_signo := '+';
            IF P_TIPOREP = 'APORTE' AND c_movimiento_dia.mcf_tmf_mnemonico IN ('RTC','ITC') THEN
               NULL;
            ELSE
               v_total_creditos := v_total_creditos + abs(c_movimiento_dia.monto2);
            END IF;
        END IF;
        v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                      -- 1. clave del banco
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
                   c_movimiento_dia.ofo_fecha_ejecucion||v_separador||                                                                  --14. fecha origen movimiento
                   v_separador||                                                                                              --15. no usado
                   v_separador||                                                                                              --16. no usado                                  
                   P_CLI_PER_NUM_IDEN||v_separador||                                                                          --17. nit cliente                  
                   '/'||v_separador||                                                                                         --18. default  /
                   V_CAMPO19_DEF||v_separador||                                                                                --19. Valor por default
                   '/'||v_separador||                                                                                         --20. causal de rechazo default /
                   '/'||v_separador||                                                                                         --21. codigo transacion banco default /
                   '/'||v_separador||                                                                                         --22. default /
                   v_separador||                                                                                              --23. no usado
                   NVL(TRIM(TO_CHAR(c_movimiento_dia.CICLO_ABONO)),'0') || v_separador||                                      --24. Ciclo del abono
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
  END LOOP;
  CLOSE movdia;

  p_mail.end_attachment( conn => conn );
  UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO); 

  ------------------------------------------------------------------------------
  --COPIAR EL ARCHIVO GENERADO AL FTP CUANDO EL CLIENTE LO TENGA CONFIGURADO
  ------------------------------------------------------------------------------

    IF P_ENVIO_FTP = 'S' THEN
      V_PREFIJO_ARCHIVO := V_NOMBRE_ARCHIVO;
      IF (P_CLI_PER_NUM_IDEN IN ('900491889','900433032','830095213')) THEN
        V_PREFIJO_ARCHIVO := 'CD' || TO_CHAR(P_FECHA_PROCESO_INI, 'DDMM') ||P_CLI_PER_NUM_IDEN|| replace(P_FON_MNEMONICO,'-','_');
      ELSIF P_CLI_PER_NUM_IDEN IN ('900072847','830136799') THEN
        V_PREFIJO_ARCHIVO := 'CD'
                    || '-' || P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || replace(P_FON_MNEMONICO,'-','_')
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '.txt';
      END IF;
      UTL_FILE.FCOPY('LOG_DIR', V_NOMBRE_ARCHIVO, 'FTPMULTICASH', V_PREFIJO_ARCHIVO);
    END IF;  

  /* Creacion de archivo cabecero*/  
  IF P_TIPOREP = 'APORTE' THEN
    IF P_RANGREP = 'D' THEN 
      OPEN saldo_aporte(P_FECHA_PROCESO_INI);
      FETCH saldo_aporte INTO c_saldo_aporte;
        IF c_saldo_aporte.saldo IS NOT NULL THEN 
          v_saldo_anterior := c_saldo_aporte.saldo;
        END IF;
      CLOSE saldo_aporte;

      OPEN saldo_aporte(P_FECHA_PROCESO_INI + 1);
      FETCH saldo_aporte INTO c_saldo_aporte;
        IF c_saldo_aporte.saldo IS NOT NULL THEN 
          v_saldo_final := c_saldo_aporte.saldo;
        END IF;
      CLOSE saldo_aporte;

    ELSIF P_RANGREP = 'R' THEN 
      OPEN saldo_aporte(P_FECHA_PROCESO_INI);
      FETCH saldo_aporte INTO c_saldo_aporte;
        IF c_saldo_aporte.saldo IS NOT NULL THEN 
          v_saldo_anterior := c_saldo_aporte.saldo;
        END IF;
      CLOSE saldo_aporte;

      OPEN saldo_aporte(P_FECHA_PROCESO_FIN + 1);
      FETCH saldo_aporte INTO c_saldo_aporte;
        IF c_saldo_aporte.saldo IS NOT NULL THEN 
          v_saldo_final := c_saldo_aporte.saldo;
        END IF;
      CLOSE saldo_aporte;

    END IF;

  ELSE 
    OPEN saldo_anterior;
    FETCH  saldo_anterior INTO c_saldo_anterior;
      IF c_saldo_anterior.saldo IS NOT NULL THEN 
        v_saldo_anterior := c_saldo_anterior.saldo;
      END IF;
    CLOSE saldo_anterior;
  END IF;


  IF v_saldo_anterior < 0 THEN
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
  v_linea := RTRIM(CODIGO_SAP)||v_separador||                                                                                         -- 1.clave del banco
                 --trim(P_CLI_PER_NUM_IDEN)||'-'||trim(P_CLI_PER_TID_CODIGO)||'-'||TO_CHAR(P_CUENTA_FONDO)||v_separador|| -- 2.cuenta bancaria
                 TRIM(P_CUENTA)||v_separador||                                                                            -- 2.cuenta bancaria
                 v_numero_extracto||v_separador||                                                                         -- 3.consecutivo extracto
                 to_char(P_FECHA_PROCESO_FIN-1,'dd.mm.yy')||v_separador||                                                 -- 4.fecha movimiento afecto el saldo
                 'COP'||v_separador||                                                                                     -- 5.Base monetaria
                 v_signo||trim(to_char(abs(v_saldo_anterior),'999999999999999990.00'))||v_separador||               -- 6.saldo inicial cuenta
                 '-'||trim(to_char(abs(v_total_debitos),'999999999999999990.00'))||v_separador||                          -- 7.total debitos
                 '+'||trim(to_char(abs(v_total_creditos),'999999999999999990.00'))||v_separador||                         -- 8.total creditos
                 v_signo_saldo_final||trim(to_char(abs(v_saldo_final),'999999999999999990.00'))||v_separador||            -- 9.saldo final cuennta
                 --'03'||                                                                                                   --10.Codigo tipo cuentaC
                 LPAD(TO_CHAR(C_CONSECUTIVO.CXS_CONSTANTE_CUENTA_SAP),2,'0')||                                              --10.Codigo tipo cuentaC
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

  IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
    V_NOMBRE_ARCHIVO := P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || replace(P_FON_MNEMONICO,'-','_')
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '-' || 'CCM'
                    || '.txt';                           
  ELSE
    V_NOMBRE_ARCHIVO := P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || replace(P_FON_MNEMONICO,'-','_')
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')
                    || '-' || 'CC'
                    || '.txt';                           
  END IF;

  EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR', V_NOMBRE_ARCHIVO, 'W');

  --Otras estructuras

  IF V_TIPO_INFORME NOT IN ('S26','SA1') THEN  
    p_mail.write_mb_text(conn,v_linea||CRLF);                   
    UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);
    p_mail.end_attachment( conn => conn );
    UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);  
    IF P_ENVIO_MAIL = 'S' THEN
      P_MAIL.END_MAIL( CONN => CONN );
    END IF;

  --Estructura de TERPEL

  ELSIF V_TIPO_INFORME IN ('S26','SA1') THEN
    V_LINEA := TRIM(REPLACE(REPLACE(REPLACE(V_LINEA,CHR(10),'  ')  ,CHR(13),'  ')  ,'   ',' '));
    UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);
    UTL_SMTP.WRITE_DATA( CONN, V_LINEA );
    UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);
    IF P_ENVIO_MAIL = 'S' THEN
      P_MAIL.END_MAIL( CONN => CONN );
    END IF;
  END IF;     

  ------------------------------------------------------------------------------
  --COPIAR EL ARCHIVO GENERADO AL FTP CUANDO EL CLIENTE LO TENGA CONFIGURADO
  ------------------------------------------------------------------------------

    IF P_ENVIO_FTP = 'S' THEN
      V_PREFIJO_ARCHIVO := V_NOMBRE_ARCHIVO;
      IF (P_CLI_PER_NUM_IDEN IN ('900491889','900433032','830095213')) THEN
        V_PREFIJO_ARCHIVO := 'CC' || TO_CHAR(P_FECHA_PROCESO_INI, 'DDMM') ||P_CLI_PER_NUM_IDEN|| replace(P_FON_MNEMONICO,'-','_');
      ELSIF P_CLI_PER_NUM_IDEN IN ('900072847','830136799') THEN
        V_PREFIJO_ARCHIVO := 'CC'
                    || '-' || P_CLI_PER_NUM_IDEN
                    || '-' || P_CLI_PER_TID_CODIGO
                    || '-' || replace(P_FON_MNEMONICO,'-','_')
                    || '-' || P_NUMERO_CUENTA
                    || '-' || P_CUENTA_FONDO
                    || '-' || TO_CHAR(P_FECHA_PROCESO_INI,'DDMMYYYY')                    
                    || '.txt';
      END IF;
      UTL_FILE.FCOPY('LOG_DIR', V_NOMBRE_ARCHIVO, 'FTPMULTICASH', V_PREFIJO_ARCHIVO);
    END IF;


  /* Actualizacion del extracto en la tabal extracto_fondo_plano*/
  IF P_REPROCESO = 'N' THEN
    IF P_RANGREP = 'R' THEN 
      UPDATE CONTROL_EXTRACTOS_SAP
      SET    CXS_NUMERO_EXTRACTO_MENSUAL = V_NUMERO_EXTRACTO
      WHERE  CXS_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
      AND    CXS_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
      AND    CXS_CFO_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
      AND    CXS_CFO_FON_CODIGO = V_FON_COMP
      AND    CXS_CFO_CODIGO = P_CUENTA_FONDO;      

    ELSE
      UPDATE CONTROL_EXTRACTOS_SAP
      SET    CXS_NUMERO_EXTRACTO = V_NUMERO_EXTRACTO
      WHERE  CXS_CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
      AND    CXS_CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
      AND    CXS_CFO_CCC_NUMERO_CUENTA = P_NUMERO_CUENTA
      AND    CXS_CFO_FON_CODIGO = V_FON_COMP
      AND    CXS_CFO_CODIGO = P_CUENTA_FONDO;
    END IF;

    OPEN extracto(V_FON_COMP);
    FETCH extracto INTO c_extracto;
      IF extracto%FOUND THEN    
        IF P_RANGREP = 'R' THEN      
          OPEN C_EXTRACTO_HIST(LAST_DAY(P_FECHA_PROCESO_INI), P_FON_CODIGO, C_EXTRACTO.EXT_CONSECUTIVO);
          FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
            IF C_EXTRACTO_HIST%NOTFOUND THEN             
              INSERT INTO HIST_CONTROL_EXTRACTOS_SAP
                (HCXS_FECHA_EXTRACTO
                ,HCXS_EXT_CLI_PER_NUM_IDEN
                ,HCXS_EXT_CLI_PER_TID_CODIGO
                ,HCXS_EXT_NUMERO_CUENTA
                ,HCXS_EXT_FON_CODIGO
                ,HCXS_EXT_CODIGO
                ,HCXS_EXT_CONSECUTIVO
                ,HCXS_EXT_SECUENCIAL
                ,HCXS_TIPO_GENERACION
                ,HCXS_EXT_TIPOREP_DIARIO
                ,HCXS_EXT_TIPOREP_MENSUAL
                ,HCXS_CXS_NUMERO_EXTRACTO
                ,HCXS_CXS_NUMERO_EXTRACTO_MES
                ,HCXS_USUARIO_MOD
                ,HCXS_FECHA_MOD)        
              VALUES
                (LAST_DAY(P_FECHA_PROCESO_INI)
                ,P_CLI_PER_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO
                ,P_NUMERO_CUENTA
                ,P_FON_CODIGO
                ,P_CUENTA_FONDO
                ,C_EXTRACTO.EXT_CONSECUTIVO
                ,C_EXTRACTO.EXT_SECUENCIAL
                ,P_RANGREP
                ,C_EXTRACTO.EXT_TIPOREP_DIARIO
                ,C_EXTRACTO.EXT_TIPOREP_MENSUAL
                ,NULL
                ,V_NUMERO_EXTRACTO
                ,USER
                ,SYSDATE);     
            ELSE
              UPDATE HIST_CONTROL_EXTRACTOS_SAP hcxs
              SET    hcxs.hcxs_ext_secuencial = C_EXTRACTO.EXT_SECUENCIAL,
                     hcxs.hcxs_cxs_numero_extracto_mes = V_NUMERO_EXTRACTO,
                     hcxs.hcxs_usuario_mod = USER,
                     hcxs.hcxs_fecha_mod = SYSDATE
              WHERE  hcxs.hcxs_fecha_extracto = LAST_DAY(P_FECHA_PROCESO_INI)
              AND    hcxs.hcxs_ext_cli_per_num_iden = P_CLI_PER_NUM_IDEN
              AND    hcxs.hcxs_ext_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
              AND    hcxs.hcxs_ext_numero_cuenta = P_NUMERO_CUENTA
              AND    hcxs.hcxs_ext_fon_codigo = P_FON_CODIGO
              AND    hcxs.hcxs_ext_codigo = P_CUENTA_FONDO
              AND    hcxs.hcxs_ext_consecutivo = C_EXTRACTO.EXT_CONSECUTIVO              
              AND    hcxs.hcxs_tipo_generacion = P_RANGREP;
            END IF;
          CLOSE C_EXTRACTO_HIST;
        ELSE 
          OPEN C_EXTRACTO_HIST(P_FECHA_PROCESO_INI, P_FON_CODIGO, C_EXTRACTO.EXT_CONSECUTIVO);
          FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
            IF C_EXTRACTO_HIST%NOTFOUND THEN             
              INSERT INTO HIST_CONTROL_EXTRACTOS_SAP
                (HCXS_FECHA_EXTRACTO
                ,HCXS_EXT_CLI_PER_NUM_IDEN
                ,HCXS_EXT_CLI_PER_TID_CODIGO
                ,HCXS_EXT_NUMERO_CUENTA
                ,HCXS_EXT_FON_CODIGO
                ,HCXS_EXT_CODIGO
                ,HCXS_EXT_CONSECUTIVO
                ,HCXS_EXT_SECUENCIAL
                ,HCXS_TIPO_GENERACION
                ,HCXS_EXT_TIPOREP_DIARIO
                ,HCXS_EXT_TIPOREP_MENSUAL
                ,HCXS_CXS_NUMERO_EXTRACTO
                ,HCXS_CXS_NUMERO_EXTRACTO_MES
                ,HCXS_USUARIO_MOD
                ,HCXS_FECHA_MOD)        
              VALUES
                (P_FECHA_PROCESO_INI
                ,P_CLI_PER_NUM_IDEN
                ,P_CLI_PER_TID_CODIGO
                ,P_NUMERO_CUENTA
                ,P_FON_CODIGO
                ,P_CUENTA_FONDO
                ,C_EXTRACTO.EXT_CONSECUTIVO
                ,C_EXTRACTO.EXT_SECUENCIAL
                ,P_RANGREP
                ,C_EXTRACTO.EXT_TIPOREP_DIARIO
                ,C_EXTRACTO.EXT_TIPOREP_MENSUAL
                ,V_NUMERO_EXTRACTO
                ,NULL
                ,USER
                ,SYSDATE);                      
            ELSE
              UPDATE HIST_CONTROL_EXTRACTOS_SAP hcxs
              SET    hcxs.hcxs_ext_secuencial = C_EXTRACTO.EXT_SECUENCIAL,
                     hcxs.hcxs_cxs_numero_extracto = V_NUMERO_EXTRACTO,
                     hcxs.hcxs_usuario_mod = USER,
                     hcxs.hcxs_fecha_mod = SYSDATE
              WHERE  hcxs.hcxs_fecha_extracto = P_FECHA_PROCESO_INI
              AND    hcxs.hcxs_ext_cli_per_num_iden = P_CLI_PER_NUM_IDEN
              AND    hcxs.hcxs_ext_cli_per_tid_codigo = P_CLI_PER_TID_CODIGO
              AND    hcxs.hcxs_ext_numero_cuenta = P_NUMERO_CUENTA
              AND    hcxs.hcxs_ext_fon_codigo = P_FON_CODIGO
              AND    hcxs.hcxs_ext_codigo = P_CUENTA_FONDO
              AND    hcxs.hcxs_ext_consecutivo = C_EXTRACTO.EXT_CONSECUTIVO              
              AND    hcxs.hcxs_tipo_generacion = P_RANGREP;          
            END IF;
          CLOSE C_EXTRACTO_HIST;
        END IF;        
      END IF; 
    CLOSE extracto;        
  END IF;

  P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS','FIN');

  COMMIT;

  EXCEPTION
      WHEN ERROR_EXTRACTO THEN
        p_errores :='No existe consecutivo o constante de extracto tipo SAP ';
        UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);                   
        RETURN;
      WHEN ERROR_INFORME THEN
        p_errores :='No se ha definido tipo de informe para el cliente/fondo/cuenta';
        UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);                   
        RETURN;  
      WHEN OTHERS THEN
         p_errores :='Error en generacion plano :'||P_CLI_PER_NUM_IDEN|| SQLERRM;
         UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);                    
         RETURN;
END;     

--VAGTUD861-SP05HU01.ParticipacionesColocacionCanales
PROCEDURE REP_MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   IN VARCHAR2 DEFAULT NULL,
                                   P_CLI_PER_TID_CODIGO IN VARCHAR2 DEFAULT NULL,
                                   P_NUMERO_CUENTA      IN NUMBER DEFAULT NULL,
                                   P_FON_CODIGO         IN VARCHAR2 DEFAULT NULL,
                                   P_CUENTA_FONDO       IN NUMBER DEFAULT NULL,
                                   P_FECHA_PROCESO      IN DATE DEFAULT NULL,
                                   P_EXT_SECUENCIAL     IN NUMBER DEFAULT NULL,
                                   P_EXT_CONSECUTIVO    IN NUMBER DEFAULT NULL,
                                   P_ERRORES            IN OUT VARCHAR2) IS

  CURSOR C_CORREOS(V_EXT_CONSECUTIVO NUMBER) IS
    SELECT DISTINCT CRMF_CORREO
    FROM   EXTRACTO_FONDO_PLANO EXT
    INNER  JOIN CORREOS_MULTICASH_FONDOS CRMF
    ON     CRMF.CRMF_EXT_CONSECUTIVO = EXT.EXT_CONSECUTIVO
    WHERE  EXT.EXT_CONSECUTIVO = V_EXT_CONSECUTIVO;
  R_CORREOS C_CORREOS%ROWTYPE;

  CURSOR C_FON_MNEMONICO(EXT_CFO_FON_CODIGO VARCHAR2) IS
    SELECT NVL(FON_HOMOLOGACION_MNEMONICO, FON_MNEMONICO) FON_MNEMONICO, FON_RAZON_SOCIAL
    FROM   FONDOS
    WHERE  FON_CODIGO = EXT_CFO_FON_CODIGO;
  R_FON_MNEMONICO C_FON_MNEMONICO%ROWTYPE;

  CURSOR C_EXTRACTO_HIST IS
    SELECT DISTINCT HCXS.HCXS_FECHA_EXTRACTO
                   ,HCXS.HCXS_EXT_CLI_PER_NUM_IDEN
                   ,HCXS.HCXS_EXT_CLI_PER_TID_CODIGO
                   ,HCXS.HCXS_EXT_NUMERO_CUENTA
                   ,HCXS.HCXS_EXT_FON_CODIGO
                   ,HCXS.HCXS_EXT_CODIGO
                   ,HCXS.HCXS_EXT_TIPOREP_DIARIO
                   ,HCXS.HCXS_EXT_TIPOREP_MENSUAL
                   ,HCXS.HCXS_TIPO_GENERACION
    FROM   HIST_CONTROL_EXTRACTOS_SAP HCXS
    WHERE  HCXS.HCXS_FECHA_EXTRACTO = P_FECHA_PROCESO
    AND    HCXS.HCXS_EXT_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
    AND    HCXS.HCXS_EXT_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
    AND    HCXS.HCXS_EXT_NUMERO_CUENTA = P_NUMERO_CUENTA
    AND    HCXS.HCXS_EXT_FON_CODIGO IN
           (SELECT P_FON_CODIGO
             FROM   DUAL
             UNION
             SELECT PFO.PFO_FON_CODIGO
             FROM   PARAMETROS_FONDOS PFO
             WHERE  PFO.PFO_PAR_CODIGO = 71
             AND    PFO_RANGO_MIN_CHAR = P_FON_CODIGO
             MINUS
             SELECT PFO.PFO_FON_CODIGO
             FROM   PARAMETROS_FONDOS PFO
             WHERE  PFO.PFO_PAR_CODIGO = 115
             AND    PFO_RANGO_MIN_CHAR = 'S')
    AND    HCXS.HCXS_EXT_CODIGO = P_CUENTA_FONDO
    AND    HCXS.HCXS_EXT_CONSECUTIVO = P_EXT_CONSECUTIVO;
  R_EXTRACTO_HIST C_EXTRACTO_HIST%ROWTYPE;

  P_CORREO        VARCHAR2(4000);
  P_FON_MNEMONICO VARCHAR2(16);
  P_RAZON_SOCIAL  VARCHAR2(128);
  V_TIPO_IDEN     VARCHAR2(8);
  V_FECHA_INI     DATE;
  V_FECHA_FIN     DATE;

BEGIN
  P_CORREO := NULL;
  OPEN C_CORREOS(P_EXT_CONSECUTIVO);
  FETCH C_CORREOS INTO R_CORREOS;
  WHILE C_CORREOS%FOUND LOOP
    IF R_CORREOS.CRMF_CORREO IS NOT NULL THEN
      IF P_CORREO IS NULL THEN
        P_CORREO := R_CORREOS.CRMF_CORREO;
      ELSE
        P_CORREO := P_CORREO || ';' || R_CORREOS.CRMF_CORREO;
      END IF;
    END IF;
    FETCH C_CORREOS INTO R_CORREOS;
  END LOOP;
  CLOSE C_CORREOS;

  OPEN C_EXTRACTO_HIST;
  FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
  IF C_EXTRACTO_HIST%FOUND THEN
    WHILE C_EXTRACTO_HIST%FOUND LOOP
      OPEN C_FON_MNEMONICO(R_EXTRACTO_HIST.HCXS_EXT_FON_CODIGO);
      FETCH C_FON_MNEMONICO INTO R_FON_MNEMONICO;
      IF C_FON_MNEMONICO%FOUND THEN
        P_FON_MNEMONICO := R_FON_MNEMONICO.FON_MNEMONICO;
        P_RAZON_SOCIAL  := R_FON_MNEMONICO.FON_RAZON_SOCIAL;
      END IF;
      CLOSE C_FON_MNEMONICO;

      IF R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_TID_CODIGO = 'NIT' THEN 
        V_TIPO_IDEN := '1';
      ELSE 
        V_TIPO_IDEN := '';
      END IF;

      IF R_EXTRACTO_HIST.HCXS_TIPO_GENERACION = 'D' THEN  
        V_FECHA_INI := R_EXTRACTO_HIST.HCXS_FECHA_EXTRACTO;
        V_FECHA_FIN := R_EXTRACTO_HIST.HCXS_FECHA_EXTRACTO + 1;

        P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   => R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_NUM_IDEN,
                                                P_CLI_PER_TID_CODIGO => R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_TID_CODIGO,
                                                P_NUMERO_CUENTA      => R_EXTRACTO_HIST.HCXS_EXT_NUMERO_CUENTA,
                                                P_FON_CODIGO         => R_EXTRACTO_HIST.HCXS_EXT_FON_CODIGO,
                                                P_FON_DESCRIPCION    => P_RAZON_SOCIAL,
                                                P_CUENTA_FONDO       => R_EXTRACTO_HIST.HCXS_EXT_CODIGO,
                                                P_CADENA_ENVIO       => P_CORREO,
                                                P_FECHA_PROCESO_INI  => V_FECHA_INI,
                                                P_FECHA_PROCESO_FIN  => V_FECHA_FIN,
                                                P_CUENTA             => R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_NUM_IDEN || V_TIPO_IDEN || R_EXTRACTO_HIST.HCXS_EXT_NUMERO_CUENTA,
                                                P_EXT_SECUENCIAL     => P_EXT_SECUENCIAL,
                                                P_ERRORES            => P_ERRORES,
                                                P_FON_MNEMONICO      => P_FON_MNEMONICO,
                                                P_REPROCESO          => 'S',
                                                P_TIPOREP            => R_EXTRACTO_HIST.HCXS_EXT_TIPOREP_DIARIO,
                                                P_RANGREP            => R_EXTRACTO_HIST.HCXS_TIPO_GENERACION);

      ELSIF R_EXTRACTO_HIST.HCXS_TIPO_GENERACION = 'R' THEN
        V_FECHA_INI := ADD_MONTHS(R_EXTRACTO_HIST.HCXS_FECHA_EXTRACTO + 1,-1);
        V_FECHA_FIN := R_EXTRACTO_HIST.HCXS_FECHA_EXTRACTO + 1;

        P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   => R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_NUM_IDEN,
                                                P_CLI_PER_TID_CODIGO => R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_TID_CODIGO,
                                                P_NUMERO_CUENTA      => R_EXTRACTO_HIST.HCXS_EXT_NUMERO_CUENTA,
                                                P_FON_CODIGO         => R_EXTRACTO_HIST.HCXS_EXT_FON_CODIGO,
                                                P_FON_DESCRIPCION    => P_RAZON_SOCIAL,
                                                P_CUENTA_FONDO       => R_EXTRACTO_HIST.HCXS_EXT_CODIGO,
                                                P_CADENA_ENVIO       => P_CORREO,
                                                P_FECHA_PROCESO_INI  => V_FECHA_INI,
                                                P_FECHA_PROCESO_FIN  => V_FECHA_FIN,
                                                P_CUENTA             => R_EXTRACTO_HIST.HCXS_EXT_CLI_PER_NUM_IDEN || V_TIPO_IDEN || R_EXTRACTO_HIST.HCXS_EXT_NUMERO_CUENTA,
                                                P_EXT_SECUENCIAL     => P_EXT_SECUENCIAL,
                                                P_ERRORES            => P_ERRORES,
                                                P_FON_MNEMONICO      => P_FON_MNEMONICO,
                                                P_REPROCESO          => 'S',
                                                P_TIPOREP            => R_EXTRACTO_HIST.HCXS_EXT_TIPOREP_MENSUAL,
                                                P_RANGREP            => R_EXTRACTO_HIST.HCXS_TIPO_GENERACION);
      END IF;

      FETCH C_EXTRACTO_HIST INTO R_EXTRACTO_HIST;
    END LOOP;
  ELSE
    IF FN_VALIDAR_COMP(P_FON_CODIGO) > 0 THEN
      OPEN C_FON_MNEMONICO(P_FON_CODIGO);
      FETCH C_FON_MNEMONICO INTO R_FON_MNEMONICO;
      IF C_FON_MNEMONICO%FOUND THEN
        P_FON_MNEMONICO := R_FON_MNEMONICO.FON_MNEMONICO;
        P_RAZON_SOCIAL  := R_FON_MNEMONICO.FON_RAZON_SOCIAL;
      END IF;
      CLOSE C_FON_MNEMONICO;

      IF P_CLI_PER_TID_CODIGO = 'NIT' THEN 
        V_TIPO_IDEN := '1';
      ELSE 
        V_TIPO_IDEN := '';
      END IF;

      P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   => P_CLI_PER_NUM_IDEN,
                                              P_CLI_PER_TID_CODIGO => P_CLI_PER_TID_CODIGO,
                                              P_NUMERO_CUENTA      => P_NUMERO_CUENTA,
                                              P_FON_CODIGO         => P_FON_CODIGO,
                                              P_FON_DESCRIPCION    => P_RAZON_SOCIAL,
                                              P_CUENTA_FONDO       => P_CUENTA_FONDO,
                                              P_CADENA_ENVIO       => P_CORREO,
                                              P_FECHA_PROCESO_INI  => P_FECHA_PROCESO,
                                              P_FECHA_PROCESO_FIN  => P_FECHA_PROCESO + 1,
                                              P_CUENTA             => P_CLI_PER_NUM_IDEN || V_TIPO_IDEN || P_NUMERO_CUENTA,
                                              P_EXT_SECUENCIAL     => P_EXT_SECUENCIAL,
                                              P_ERRORES            => P_ERRORES,
                                              P_FON_MNEMONICO      => P_FON_MNEMONICO,
                                              P_REPROCESO          => 'S',
                                              P_TIPOREP            => 'APORTE');
    ELSE
      OPEN C_FON_MNEMONICO(P_FON_CODIGO);
      FETCH C_FON_MNEMONICO INTO R_FON_MNEMONICO;
      IF C_FON_MNEMONICO%FOUND THEN
        P_FON_MNEMONICO := R_FON_MNEMONICO.FON_MNEMONICO;
        P_RAZON_SOCIAL  := R_FON_MNEMONICO.FON_RAZON_SOCIAL;
      END IF;
      CLOSE C_FON_MNEMONICO;

      IF P_CLI_PER_TID_CODIGO = 'NIT' THEN 
        V_TIPO_IDEN := '1';
      ELSE 
        V_TIPO_IDEN := '';
      END IF;

      P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_FONDOS(P_CLI_PER_NUM_IDEN   => P_CLI_PER_NUM_IDEN,
                                              P_CLI_PER_TID_CODIGO => P_CLI_PER_TID_CODIGO,
                                              P_NUMERO_CUENTA      => P_NUMERO_CUENTA,
                                              P_FON_CODIGO         => P_FON_CODIGO,
                                              P_FON_DESCRIPCION    => P_RAZON_SOCIAL,
                                              P_CUENTA_FONDO       => P_CUENTA_FONDO,
                                              P_CADENA_ENVIO       => P_CORREO,
                                              P_FECHA_PROCESO_INI  => P_FECHA_PROCESO,
                                              P_FECHA_PROCESO_FIN  => P_FECHA_PROCESO + 1,
                                              P_CUENTA             => P_CLI_PER_NUM_IDEN || V_TIPO_IDEN || P_NUMERO_CUENTA,
                                              P_EXT_SECUENCIAL     => P_EXT_SECUENCIAL,
                                              P_ERRORES            => P_ERRORES,
                                              P_FON_MNEMONICO      => P_FON_MNEMONICO,
                                              P_REPROCESO          => 'S',
                                              P_TIPOREP            => 'PARTICIPACION');
    END IF;    
  END IF;
EXCEPTION
  WHEN OTHERS THEN
     p_errores :='Error en reproceso de archivo multicash cliente:'||P_CLI_PER_NUM_IDEN|| SQLERRM;     
END REP_MAIL_EXTRACTO_FONDOS;



--*********************NUEVO MULTICASH SALDOS CARTERA***************************

PROCEDURE MAIL_PROCESO_EXTRACTO_CUENTAS (P_TIPO_REPORTE  IN VARCHAR2,
                                         P_FECHA_INICIAL IN DATE DEFAULT NULL,
                                         P_FECHA_FINAL   IN DATE DEFAULT NULL) IS
  CURSOR C_CLIENTES IS
    SELECT 
    CONV_CONSECUTIVO CONVENIO,
    CONV_CFO_CCC_CLI_PER_NUM_IDEN PER_NUM_IDEN,
    CONV_CFO_CCC_CLI_PER_TID_COD PER_TID_COD,
    CONV_CFO_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA,
    CONV_CFO_FON_CODIGO FON_CODIGO,
    CONV_CFO_CODIGO APORTE,

    ECP_TIPO_INFORME TIPO,
    ECP.ECP_CONSOLIDADO,
    ECP.ECP_FTP_DIARIO,
    ECP.ECP_EMAIL_DIARIO,
    ECP_CONSECUTIVO
    FROM EXTRACTOS_CUENTAS_PLANOS ECP 
    JOIN CONVENIOS CONV ON ECP.ECP_CONV_CONSECUTIVO = CONV.CONV_CONSECUTIVO
    WHERE ECP.ECP_ESTADO='A'
    AND (ECP.ECP_FTP_DIARIO = 'S' OR ECP.ECP_EMAIL_DIARIO = 'S');

  -- Cursor clientes consolidado mensual
  CURSOR C_CLIENTES_CM IS
    SELECT 
    CONV_CONSECUTIVO CONVENIO,
    CONV_CFO_CCC_CLI_PER_NUM_IDEN PER_NUM_IDEN,
    CONV_CFO_CCC_CLI_PER_TID_COD PER_TID_COD,
    CONV_CFO_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA,
    CONV_CFO_FON_CODIGO FON_CODIGO,
    CONV_CFO_CODIGO APORTE,

    ECP_TIPO_INFORME TIPO,
    ECP.ECP_CONSOLIDADO,
    ECP.ECP_FTP_MENSUAL,
    ECP.ECP_EMAIL_MENSUAL,
    ECP_CONSECUTIVO
    FROM EXTRACTOS_CUENTAS_PLANOS ECP 
    JOIN CONVENIOS CONV ON ECP.ECP_CONV_CONSECUTIVO = CONV.CONV_CONSECUTIVO
    WHERE ECP.ECP_ESTADO='A'
    AND (ECP.ECP_FTP_MENSUAL = 'S' OR ECP.ECP_EMAIL_MENSUAL = 'S');


	CURSOR C_CORREOS (ECP_CONSECUTIVO NUMBER) IS
      SELECT CRMC_CORREO
      FROM CORREOS_MULTICASH_CARTERAS
      WHERE CRMC_ECP_CONSECUTIVO = ECP_CONSECUTIVO;

  V_DIRECCION_MAIL     VARCHAR2(4000);      
  V_ERROR_MAIL         VARCHAR2(4000);      
  V_DIRECCION_MAIL_EMP VARCHAR2(4000);      
  V_SUBJECT_ERROR      VARCHAR2(4000);
  V_CUERPO_ERROR       VARCHAR2(4000);
  V_MSJ_ERROR          VARCHAR2(4000);  
  V_FECHA_PROCESO_INI  DATE;
  V_FECHA_PROCESO_FIN  DATE;
  V_ERROR              EXCEPTION;
  V_HORA_ACTUAL        NUMBER;
  V_EJECUTAR           INT;
  CONN                 UTL_SMTP.CONNECTION;      
  R_CLIENTES           C_CLIENTES%ROWTYPE;
  R_CLIENTES_CM        C_CLIENTES_CM%ROWTYPE;
  R_CORREOS            C_CORREOS%ROWTYPE;

  P_NUM_INI  number;
  P_NUM_FIN  NUMBER;  

BEGIN

  V_DIRECCION_MAIL      := ' ';
  V_DIRECCION_MAIL_EMP  := ' ';     
  V_SUBJECT_ERROR       := ' ';
  V_CUERPO_ERROR        := ' ';
  V_MSJ_ERROR           := ' ';
  V_EJECUTAR            := 0;

  P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.MAIL_PROCESO_EXTRACTO_CUENTAS','INI');

  -- P_TIPO_REPORTE (P = PARCIAL C = CONSOLIDADO)

  IF P_TIPO_REPORTE  = 'P' THEN  
    SELECT TRUNC(P_FECHA_INICIAL) INTO V_FECHA_PROCESO_INI FROM DUAL;
    SELECT TRUNC(P_FECHA_FINAL) INTO V_FECHA_PROCESO_FIN FROM DUAL;    
  ELSIF P_TIPO_REPORTE  = 'C' THEN
    SELECT TRUNC(P_FECHA_INICIAL)-1 INTO V_FECHA_PROCESO_INI FROM DUAL;
    SELECT TRUNC(P_FECHA_FINAL)-1 INTO V_FECHA_PROCESO_FIN FROM DUAL;    
  END IF;

  SELECT CON_VALOR_CHAR INTO V_DIRECCION_MAIL_EMP  
  FROM CONSTANTES WHERE CON_MNEMONICO='MEP';  

  IF V_DIRECCION_MAIL_EMP IS NULL  THEN
    V_DIRECCION_MAIL_EMP := 'SMOTTA@CORREDORES.COM; STECNICO@CORREDORES.COM; DAVICASH@CORREDORES.COM';
    V_SUBJECT_ERROR := 'No existe direcion de correo valida';
    V_CUERPO_ERROR  := 'La constante MEP no definida en el sistema';
    RAISE V_ERROR;
  END IF;  

  V_ERROR_MAIL := V_DIRECCION_MAIL_EMP || ';DAVICASH@CORREDORES.COM';    

  SELECT TO_NUMBER(TO_CHAR(SYSDATE,'HH24')) INTO V_HORA_ACTUAL FROM DUAL;

  OPEN C_CLIENTES;
  FETCH C_CLIENTES INTO R_CLIENTES;
  WHILE C_CLIENTES%FOUND LOOP    

    --Validar el horario parametrizado por convenio / tipo de reporte

    IF  P_TIPO_REPORTE='C' AND R_CLIENTES.ECP_CONSOLIDADO = 'S' THEN 
      V_EJECUTAR := 1;
    END IF;      

    IF P_TIPO_REPORTE = 'P' THEN    
      SELECT COUNT(*) INTO V_EJECUTAR
      FROM HORARIOS_MULTICASH_CUENTAS
      WHERE HMC_ECP_CONV_CONSECUTIVO = R_CLIENTES.CONVENIO
      AND HMC_ECP_TIPO_INFORME       = R_CLIENTES.TIPO
      AND (R_CLIENTES.ECP_FTP_DIARIO = 'S'
      OR R_CLIENTES.ECP_EMAIL_DIARIO = 'S')
      AND TO_NUMBER(SUBSTR(HMC_HORA_ENVIO,1,2)) = V_HORA_ACTUAL;    
    END IF;

    V_DIRECCION_MAIL := V_DIRECCION_MAIL_EMP;
    OPEN C_CORREOS(R_CLIENTES.ECP_CONSECUTIVO);
    FETCH C_CORREOS INTO R_CORREOS;
    WHILE C_CORREOS%FOUND LOOP
      IF R_CORREOS.CRMC_CORREO IS NOT NULL THEN
            V_DIRECCION_MAIL := V_DIRECCION_MAIL||';'||R_CORREOS.CRMC_CORREO;

      END IF;
      FETCH C_CORREOS INTO R_CORREOS;
    END LOOP;
    CLOSE C_CORREOS;
    IF V_EJECUTAR > 0 THEN
    P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS(P_CONV_CONSECUTIVO    => R_CLIENTES.CONVENIO,
                                            P_ECP_TIPO_INFORME     => R_CLIENTES.TIPO,
                                            P_CADENA_ENVIO         => V_DIRECCION_MAIL,
                                            P_FECHA_PROCESO_INI    => V_FECHA_PROCESO_INI,
                                            P_FECHA_PROCESO_FIN    => V_FECHA_PROCESO_FIN,
                                            P_TIPO_ENVIO           => P_TIPO_REPORTE, 
                                            P_ERRORES              => V_MSJ_ERROR,
                                            P_ENVIO_MAIL           => R_CLIENTES.ECP_EMAIL_DIARIO,
                                            P_ENVIO_FTP            => R_CLIENTES.ECP_FTP_DIARIO
                                            );                                            
      IF NVL(TRIM(V_MSJ_ERROR),' ') != ' 'THEN        
        V_DIRECCION_MAIL  := V_ERROR_MAIL;
        V_SUBJECT_ERROR   := 'Error en proceso P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS';
        V_CUERPO_ERROR    := V_MSJ_ERROR;
        RAISE V_ERROR;
      END IF; 
    END IF;

    FETCH C_CLIENTES INTO R_CLIENTES;

  END LOOP;
  CLOSE C_CLIENTES;

  IF EXTRACT(DAY FROM V_FECHA_PROCESO_INI + 1) = 1 AND P_TIPO_REPORTE='C' THEN
    OPEN C_CLIENTES_CM;
    FETCH C_CLIENTES_CM INTO R_CLIENTES_CM;
    WHILE C_CLIENTES_CM%FOUND LOOP

      IF  P_TIPO_REPORTE='C' AND R_CLIENTES_CM.ECP_CONSOLIDADO = 'S' THEN 
        V_EJECUTAR := 1;
      END IF;

      V_DIRECCION_MAIL := V_DIRECCION_MAIL_EMP;
      OPEN C_CORREOS(R_CLIENTES_CM.ECP_CONSECUTIVO);
      FETCH C_CORREOS INTO R_CORREOS;
      WHILE C_CORREOS%FOUND LOOP
        IF R_CORREOS.CRMC_CORREO IS NOT NULL THEN
              V_DIRECCION_MAIL := V_DIRECCION_MAIL||';'||R_CORREOS.CRMC_CORREO;

        END IF;
        FETCH C_CORREOS INTO R_CORREOS;
      END LOOP;
      CLOSE C_CORREOS;
      IF V_EJECUTAR > 0 THEN
        P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS(P_CONV_CONSECUTIVO  => R_CLIENTES_CM.CONVENIO,
                                              P_ECP_TIPO_INFORME     => R_CLIENTES_CM.TIPO,
                                              P_CADENA_ENVIO         => V_DIRECCION_MAIL,
                                              P_FECHA_PROCESO_INI    => ADD_MONTHS(V_FECHA_PROCESO_INI + 1,-1),
                                              P_FECHA_PROCESO_FIN    => V_FECHA_PROCESO_INI + 1,
                                              P_TIPO_ENVIO           => P_TIPO_REPORTE, 
                                              P_ERRORES              => V_MSJ_ERROR,
                                              P_ENVIO_MAIL           => R_CLIENTES_CM.ECP_EMAIL_MENSUAL,
                                              P_ENVIO_FTP            => R_CLIENTES_CM.ECP_FTP_MENSUAL
                                              );                                            
        IF NVL(TRIM(V_MSJ_ERROR),' ') != ' 'THEN        
          V_DIRECCION_MAIL  := V_ERROR_MAIL;
          V_SUBJECT_ERROR   := 'Error en proceso P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS';
          V_CUERPO_ERROR    := V_MSJ_ERROR;
          RAISE V_ERROR;
        END IF; 
      END IF;

      FETCH C_CLIENTES_CM INTO R_CLIENTES_CM;

    END LOOP;
    CLOSE C_CLIENTES_CM;    
  END IF;

  P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CLIENTES_TITULOS.MAIL_PROCESO_EXTRACTO_CUENTAS','FIN');

  COMMIT;

  EXCEPTION 
    WHEN V_ERROR THEN
      CONN := P_MAIL.BEGIN_MAIL(SENDER     => 'Administrador@corredores.com',
                                RECIPIENTS => V_ERROR_MAIL,
                                SUBJECT    => V_SUBJECT_ERROR,
                                MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);
      P_MAIL.ATTACH_TEXT(CONN      => CONN,
                         DATA      => '<h1>'||V_CUERPO_ERROR||'</h1>',
                         MIME_TYPE => 'text/html');
      P_MAIL.END_MAIL( CONN => CONN );     

   WHEN OTHERS THEN
     V_DIRECCION_MAIL := V_ERROR_MAIL;
     V_SUBJECT_ERROR := 'Error en proceso P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS ';
     V_CUERPO_ERROR  := 'Error no determinado :'||SQLERRM;
     CONN := P_MAIL.BEGIN_MAIL(SENDER     => 'Administrador@corredores.com', 
                                RECIPIENTS => V_DIRECCION_MAIL,
                                SUBJECT    => V_SUBJECT_ERROR,
                                MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);
     P_MAIL.ATTACH_TEXT(CONN      => CONN,
                        DATA      => '<h1>'||V_CUERPO_ERROR||'</h1>',
                        MIME_TYPE => 'text/html');
     P_MAIL.END_MAIL( CONN => CONN );

END MAIL_PROCESO_EXTRACTO_CUENTAS;

PROCEDURE MAIL_EXTRACTO_CUENTAS(
    P_CONV_CONSECUTIVO  IN NUMBER DEFAULT NULL,
    P_ECP_TIPO_INFORME  IN VARCHAR2 DEFAULT NULL,
    P_CADENA_ENVIO      IN VARCHAR2 DEFAULT NULL,
    P_FECHA_PROCESO_INI IN DATE DEFAULT NULL,
    P_FECHA_PROCESO_FIN IN DATE DEFAULT NULL,
    P_TIPO_ENVIO        IN VARCHAR2 DEFAULT NULL,
    P_ERRORES           IN OUT VARCHAR2,
    P_ENVIO_MAIL        IN VARCHAR2 DEFAULT 'S',
    P_ENVIO_FTP         IN VARCHAR2 DEFAULT 'N',
    P_REPROCESO         IN VARCHAR2 := 'N')
IS

CURSOR C_CONSECUTIVO
IS
  SELECT CXC_CONSECUTIVO
  FROM CONTROL_EXTRACTOS_CUENTAS
  WHERE CXC_CONV_CONSECUTIVO = P_CONV_CONSECUTIVO
  AND CXC_TIPO_INFORME       = P_ECP_TIPO_INFORME;

-----------------------------------------------------------------------------
--RECIBOS DE CAJA ('RCA','RRC')
-----------------------------------------------------------------------------
CURSOR C_RECAUDOS (P_TIPO_ENVIO VARCHAR2) IS 
SELECT DISTINCT
  MCC.MCC_CONSECUTIVO,
  MCC.MCC_FECHA,
  MCC.MCC_CCC_CLI_PER_NUM_IDEN,
  MCC.MCC_CCC_CLI_PER_TID_CODIGO,
  MCC.MCC_CCC_NUMERO_CUENTA,
  MCC.MCC_TMC_MNEMONICO, 
  MCC.MCC_MONTO_CARTERA,
  RCA.RCA_CONV_CONSECUTIVO,
  NVL(RCA.RCA_CODIGO_CONSIGNANTE,'ND') SEGUNDO_8020,
  DECODE(MCC.MCC_TMC_MNEMONICO,'RCA','/', NVL(UPPER(REPLACE(RCA.RCA_RAZON_REVERSION,'/','')),'/')) RAZON_REVERSION,
  NVL(REAS.REAS_SUCURSAL,'0000') REAS_SUCURSAL,
  RCA.RCA_NUM_IDEN_CONSIGNANTE,
  CONV.CONV_CFO_CODIGO APORTE,
  DECODE(CCJ.CCJ_CBA_BAN_CODIGO,NULL,TRC.TRC_CBA_BAN_CODIGO,CCJ.CCJ_CBA_BAN_CODIGO) AS BAN_CODIGO,
  DECODE(BAN_C.BAN_NIT,NULL,BAN_T.BAN_NIT,BAN_C.BAN_NIT) AS BAN_NIT,
  DECODE(TO_DATE(REAS_FECHA_RECAUDO,'yymmdd'),NULL,RCA.RCA_FECHA,TO_DATE(REAS_FECHA_RECAUDO,'yymmdd')) FECHA_RECAUDO,
  (CASE
	WHEN CNA.CNL_CODIGO = 'PSED' THEN '04'
	ELSE DECODE(CCJ.CCJ_TIPO_CONSIGNACION, NULL, '01',
										  'EFE', '01',
										  'CHE', '02','00')                
  END) AS TIPO_RECAUDO,
  MCC.MCC_FECHA_ENVIO_MULTICASH,
  NVL(REAS.REAS_CAUSAL_DEVOLUCION, '000') CAUSAL_DEV,
  RCA.RCA_CICLO_ABONO AS CICLO_ABONO,
  RCA.RCA_CONSECUTIVO AS RECIBOCAJA
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN RECIBOS_DE_CAJA RCA
  ON MCC.MCC_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO
  JOIN CONVENIOS CONV
  ON RCA.RCA_CONV_CONSECUTIVO = CONV.CONV_CONSECUTIVO
  LEFT JOIN CONSIGNACIONES_CAJA CCJ
  ON CCJ.CCJ_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO
  LEFT JOIN TRANSFERENCIAS_CAJA TRC 
  ON TRC.TRC_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO 
  LEFT JOIN BANCOS BAN_C 
  ON CCJ.CCJ_CBA_BAN_CODIGO = BAN_C.BAN_CODIGO
  LEFT JOIN BANCOS BAN_T 
  ON TRC.TRC_CBA_BAN_CODIGO = BAN_T.BAN_CODIGO
  LEFT JOIN RECAUDOS_CONVENIOS RECO
  ON RECO.RECO_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO AND
  RECO.RECO_RCA_SUC_CODIGO = RCA.RCA_SUC_CODIGO AND
  RECO.RECO_RCA_NEG_CONSECUTIVO = RCA.RCA_NEG_CONSECUTIVO
  LEFT JOIN RECAUDOS_ASOBANCARIA_2001 REAS 
  ON RECO.RECO_CONSECUTIVO = REAS.REAS_RECO_CONSECUTIVO  
  LEFT JOIN CANALES CNA
    ON RCA.RCA_CNL_CONSECUTIVO = CNA.CNL_CONSECUTIVO   
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('RCA','RRC')
  AND RCA.RCA_COT_MNEMONICO          = 'AXCB'
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND RCA.RCA_CONV_CONSECUTIVO       = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P',MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL;

-----------------------------------------------------------------------------
--CHEQUES DEVUELTOS ('CDEV')
-----------------------------------------------------------------------------  

CURSOR C_DEVUELTOS (P_TIPO_ENVIO VARCHAR2) IS 
SELECT DISTINCT  
  MCC.MCC_CONSECUTIVO,
  MCC.MCC_FECHA,
  MCC.MCC_CCC_CLI_PER_NUM_IDEN,
  MCC.MCC_CCC_CLI_PER_TID_CODIGO,
  MCC.MCC_CCC_NUMERO_CUENTA,
  MCC.MCC_TMC_MNEMONICO,
  MCC.MCC_MONTO_CARTERA,
  RCA.RCA_CONV_CONSECUTIVO,
  NVL(RCA.RCA_CODIGO_CONSIGNANTE,'ND') SEGUNDO_8020,
  NVL(UPPER(CDE.CDE_RAZON_DEVOLUCION),'CHEQUE DEVUELTO') RAZON_REVERSION,
  NVL(REAS.REAS_SUCURSAL,'0000') REAS_SUCURSAL,
  RCA.RCA_NUM_IDEN_CONSIGNANTE,
  CONV.CONV_CFO_CODIGO APORTE,
  CCJ.CCJ_CBA_BAN_CODIGO AS BAN_CODIGO,
  BAN_NIT,
  DECODE(TO_DATE(REAS_FECHA_RECAUDO,'yymmdd'),NULL,RCA.RCA_FECHA,TO_DATE(REAS_FECHA_RECAUDO,'yymmdd')) FECHA_RECAUDO,
 (CASE
    WHEN CNA.CNL_CODIGO = 'PSED' THEN '04'
    ELSE DECODE(CCJ.CCJ_TIPO_CONSIGNACION, NULL, '01',
                                          'EFE', '01',
                                          'CHE', '02','00')                
  END) AS TIPO_RECAUDO,                                    
  MCC.MCC_FECHA_ENVIO_MULTICASH,
  NVL(REAS.REAS_CAUSAL_DEVOLUCION, '000') CAUSAL_DEV,
  CCA.CCA_NUMERO_CHEQUE,
  RCA.RCA_CICLO_ABONO AS CICLO_ABONO
   FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN CHEQUES_DEVUELTOS CDE ON MCC.MCC_CDE_CONSECUTIVO = CDE.CDE_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = CDE.CDE_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO = CDE.CDE_SUC_CODIGO
  JOIN CHEQUES_CAJA CCA ON CCA.CCA_CONSECUTIVO = CDE.CDE_CCA_CONSECUTIVO
  JOIN CONSIGNACIONES_CAJA CCJ ON CCJ.CCJ_CONSECUTIVO=CCA.CCA_CCJ_CONSECUTIVO
  JOIN RECIBOS_DE_CAJA RCA ON CCJ.CCJ_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO
  JOIN CONVENIOS CONV ON RCA.RCA_CONV_CONSECUTIVO = CONV.CONV_CONSECUTIVO   
  JOIN BANCOS BAN ON CCJ.CCJ_CBA_BAN_CODIGO = BAN.BAN_CODIGO  
  LEFT JOIN RECAUDOS_CONVENIOS RECO ON RECO.RECO_RCA_CONSECUTIVO = RCA.RCA_CONSECUTIVO 
  AND RECO.RECO_RCA_SUC_CODIGO = RCA.RCA_SUC_CODIGO 
  AND RECO.RECO_RCA_NEG_CONSECUTIVO = RCA.RCA_NEG_CONSECUTIVO
  LEFT JOIN RECAUDOS_ASOBANCARIA_2001 REAS ON RECO.RECO_CONSECUTIVO = REAS.REAS_RECO_CONSECUTIVO  
  LEFT JOIN CANALES CNA 
	ON RCA.RCA_CNL_CONSECUTIVO = CNA.CNL_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('CDEV')
  AND RCA.RCA_COT_MNEMONICO          = 'AXCB'
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND RCA.RCA_CONV_CONSECUTIVO       = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P',MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL;  

-----------------------------------------------------------------------------
--PAGOS TRANSFERENCIAS ('PTRB','RPTRB','PSEB','RPSEB','PACH','DPACH')
-----------------------------------------------------------------------------

CURSOR C_PAGOS_TRAN (P_TIPO_ENVIO VARCHAR2) IS 

--Transacciones sin reversión
SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,    
    TBC.TBC_FECHA,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPTRB','RPSEB','DPACH') 
    THEN NVL(UPPER(REPLACE(TBC.TBC_RAZON_REVERSION,'/','')),'/')  ELSE '/' END RAZON_REVERSION, 
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    TBC.TBC_CBA_BAN_CODIGO,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN TRANSFERENCIAS_BANCARIAS TBC
  ON MCC.MCC_TBC_CONSECUTIVO = TBC.TBC_CONSECUTIVO AND
  MCC.MCC_NEG_CONSECUTIVO = TBC.TBC_NEG_CONSECUTIVO
  JOIN BANCOS BAN
  ON TBC.TBC_CBA_BAN_CODIGO  = BAN.BAN_CODIGO
  JOIN ORDENES_DE_PAGO ODP
  ON TBC.TBC_CONSECUTIVO = ODP.ODP_TBC_CONSECUTIVO
  AND ODP.ODP_TBC_CONSECUTIVO = MCC.MCC_TBC_CONSECUTIVO
  AND ODP.ODP_SUC_CODIGO      = TBC.TBC_SUC_CODIGO
  AND ODP.ODP_NEG_CONSECUTIVO = TBC.TBC_NEG_CONSECUTIVO
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO  
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       = '800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PTRB','RPTRB','PSEB','RPSEB','PACH','DPACH')
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL
  UNION 
  --Transacciones reversadas  
  SELECT DISTINCT
   MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,    
    TBC.TBC_FECHA,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPTRB','RPSEB','DPACH') 
    THEN NVL(UPPER(REPLACE(TBC.TBC_RAZON_REVERSION,'/','')),'/')  ELSE '/' END RAZON_REVERSION, 
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    TBC.TBC_CBA_BAN_CODIGO,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC 
  JOIN TRANSFERENCIAS_BANCARIAS  TBC
  ON MCC.MCC_TBC_CONSECUTIVO = TBC.TBC_CONSECUTIVO
  JOIN ORDENES_Y_PAGOS_ANULADOS OPA 
  ON TBC.TBC_CONSECUTIVO = OPA.OPA_TBC_CONSECUTIVO
  AND TBC.TBC_SUC_CODIGO = OPA.OPA_SUC_CODIGO
  AND TBC.TBC_NEG_CONSECUTIVO = OPA.OPA_NEG_CONSECUTIVO
  JOIN ORDENES_DE_PAGO ODP
  ON OPA.OPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND OPA.OPA_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND OPA.OPA_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO  
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       = '800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('RPTRB','RPSEB','DPACH','PTRB','PSEB','PACH')
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL;

-----------------------------------------------------------------------------
--PAGOS Y REVERSIONES CON CHEQUE
-----------------------------------------------------------------------------

CURSOR C_PAGOS_CHE (P_TIPO_ENVIO VARCHAR2) IS
  SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,
    CEG.CEG_CBA_BAN_CODIGO BAN_CODIGO,
    BAN.BAN_NIT,
    CEG.CEG_NUMERO_CHEQUE,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPCHE') 
    THEN NVL(REPLACE(CEG.CEG_RAZON_REVERSION,'/',''),'/') ELSE '/' END RAZON_REVERSION,    
    CEG.CEG_FECHA,
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN COMPROBANTES_DE_EGRESO CEG
  ON MCC.MCC_CEG_CONSECUTIVO  = CEG.CEG_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = CEG.CEG_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO      = CEG.CEG_SUC_CODIGO
  JOIN BANCOS BAN 
  ON CEG.CEG_CBA_BAN_CODIGO   = BAN.BAN_CODIGO
  JOIN ORDENES_DE_PAGO ODP
  ON CEG.CEG_CONSECUTIVO      = ODP.ODP_CEG_CONSECUTIVO
  AND ODP.ODP_NEG_CONSECUTIVO = MCC.MCC_NEG_CONSECUTIVO
  AND ODP.ODP_SUC_CODIGO      = CEG.CEG_SUC_CODIGO
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       = '800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PCHE', 'RPCHE')
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL
  UNION   
  --Transacciones reversadas  
  SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,
    CEG.CEG_CBA_BAN_CODIGO BAN_CODIGO,
    BAN.BAN_NIT,
    CEG.CEG_NUMERO_CHEQUE,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPCHE') 
    THEN NVL(REPLACE(CEG.CEG_RAZON_REVERSION,'/',''),'/') ELSE '/' END RAZON_REVERSION,    
    CEG.CEG_FECHA,
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN COMPROBANTES_DE_EGRESO CEG
  ON MCC.MCC_CEG_CONSECUTIVO  = CEG.CEG_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = CEG.CEG_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO      = CEG.CEG_SUC_CODIGO
  JOIN BANCOS BAN 
  ON CEG.CEG_CBA_BAN_CODIGO   = BAN.BAN_CODIGO
  JOIN ORDENES_Y_PAGOS_ANULADOS OPA 
  ON CEG.CEG_CONSECUTIVO = OPA.OPA_CEG_CONSECUTIVO
  AND CEG.CEG_SUC_CODIGO = OPA.OPA_SUC_CODIGO
  AND CEG.CEG_NEG_CONSECUTIVO = OPA.OPA_NEG_CONSECUTIVO
  JOIN ORDENES_DE_PAGO ODP
  ON OPA.OPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND OPA.OPA_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND OPA.OPA_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO  
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       = '800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PCHE', 'RPCHE')
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL;

-----------------------------------------------------------------------------
--TRANSFERENCIA ENTRE CUENTAS PTCC Y RPTCC
-----------------------------------------------------------------------------

CURSOR C_PAGOS_CUENTAS (P_TIPO_ENVIO VARCHAR2) IS
  SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,
    TCC.TCC_FECHA,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPTCC') THEN NVL(REPLACE(TCC.TCC_RAZON_REVERSION,'/',''),'/') ELSE '/' END RAZON_REVERSION,         
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN TRANSFERENCIAS_CUENTAS_CLIENTE TCC
  ON MCC.MCC_TCC_CONSECUTIVO  = TCC.TCC_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = TCC.TCC_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO      = TCC.TCC_SUC_CODIGO
  JOIN ORDENES_DE_PAGO ODP
  ON TCC.TCC_CONSECUTIVO      = ODP.ODP_TCC_CONSECUTIVO
  AND ODP.ODP_NEG_CONSECUTIVO = MCC.MCC_NEG_CONSECUTIVO
  AND ODP.ODP_SUC_CODIGO      = TCC.TCC_SUC_CODIGO
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       = '800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PTCC', 'RPTCC')
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL
  UNION 
  --Transacciones reversadas
  SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,
    TCC.TCC_FECHA,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPTCC') THEN NVL(REPLACE(TCC.TCC_RAZON_REVERSION,'/',''),'/') ELSE '/' END RAZON_REVERSION,         
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN TRANSFERENCIAS_CUENTAS_CLIENTE TCC
  ON MCC.MCC_TCC_CONSECUTIVO  = TCC.TCC_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = TCC.TCC_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO      = TCC.TCC_SUC_CODIGO
  JOIN ORDENES_Y_PAGOS_ANULADOS OPA 
  ON TCC.TCC_CONSECUTIVO = OPA.OPA_TCC_CONSECUTIVO
  AND TCC.TCC_SUC_CODIGO = OPA.OPA_SUC_CODIGO
  AND TCC.TCC_NEG_CONSECUTIVO = OPA.OPA_NEG_CONSECUTIVO
  JOIN ORDENES_DE_PAGO ODP
  ON OPA.OPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND OPA.OPA_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND OPA.OPA_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO 
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       = '800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PTCC', 'RPTCC')
  AND MCC.MCC_NEG_CONSECUTIVO        = 4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL;

-----------------------------------------------------------------------------
--PAGOS CON CHEQUE DE GERENCIA PCHG Y RPCHG
-----------------------------------------------------------------------------

CURSOR C_PAGOS_GER (P_TIPO_ENVIO VARCHAR2) IS
  SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,
    CGE.CGE_CBA_BAN_CODIGO BAN_CODIGO,
    BAN.BAN_NIT,
    CGE.CGE_FECHA,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPCHG') THEN NVL(REPLACE(CGE.CGE_RAZON_REVERSION,'/',''),'/') ELSE '/' END RAZON_REVERSION,             
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN CHEQUES_GERENCIA CGE
  ON MCC.MCC_CGE_CONSECUTIVO  = CGE.CGE_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = CGE.CGE_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO      = CGE.CGE_SUC_CODIGO
  JOIN BANCOS BAN
  ON CGE.CGE_CBA_BAN_CODIGO = BAN.BAN_CODIGO
  JOIN ORDENES_DE_PAGO ODP
  ON CGE.CGE_CONSECUTIVO      = ODP.ODP_CGE_CONSECUTIVO
  AND ODP.ODP_NEG_CONSECUTIVO = MCC.MCC_NEG_CONSECUTIVO
  AND ODP.ODP_SUC_CODIGO      = CGE.CGE_SUC_CODIGO
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       ='800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PCHG', 'RPCHG')
  AND MCC.MCC_NEG_CONSECUTIVO        =4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL
  UNION 
  --Transacciones reversadas
  SELECT DISTINCT
    MCC.MCC_CONSECUTIVO,
    MCC.MCC_FECHA,
    MCC.MCC_CCC_CLI_PER_NUM_IDEN,
    MCC.MCC_CCC_CLI_PER_TID_CODIGO,
    MCC.MCC_CCC_NUMERO_CUENTA,
    MCC.MCC_TMC_MNEMONICO,
    MCC.MCC_MONTO_CARTERA,
    CONV.CONV_CONSECUTIVO,
    OFO.OFO_CFO_CODIGO APORTE,
    CGE.CGE_CBA_BAN_CODIGO BAN_CODIGO,
    BAN.BAN_NIT,
    CGE.CGE_FECHA,
    CASE WHEN MCC.MCC_TMC_MNEMONICO IN ('RPCHG') THEN NVL(REPLACE(CGE.CGE_RAZON_REVERSION,'/',''),'/') ELSE '/' END RAZON_REVERSION,             
    DECODE(DPA.DPA_NUM_IDEN,
                       NULL,
                       DECODE(ODP.ODP_PER_NUM_IDEN,
                              NULL,
                              ODP.ODP_CCC_CLI_PER_NUM_IDEN,
                              ODP.ODP_PER_NUM_IDEN),
                       DPA.DPA_NUM_IDEN) BENEFICIARIO,
    MCC.MCC_FECHA_ENVIO_MULTICASH,
    CASE
      WHEN ODP.ODP_ID_ARCHIVO_ACH IS NULL THEN
       (SELECT ODP1.ODP_ID_ARCHIVO_ACH
        FROM   ORDENES_DE_PAGO ODP1
        WHERE  ODP1.ODP_CONSECUTIVO = ODP.ODP_ODP_CONSECUTIVO
        AND    ODP1.ODP_SUC_CODIGO = ODP.ODP_ODP_SUC_CODIGO
        AND    ODP1.ODP_NEG_CONSECUTIVO = ODP.ODP_ODP_NEG_CONSECUTIVO)
      ELSE
       ODP.ODP_ID_ARCHIVO_ACH
    END ODP_ID_ARCHIVO_ACH
  FROM MOVIMIENTOS_CUENTA_CORREDORES MCC
  JOIN CHEQUES_GERENCIA CGE
  ON MCC.MCC_CGE_CONSECUTIVO  = CGE.CGE_CONSECUTIVO
  AND MCC.MCC_NEG_CONSECUTIVO = CGE.CGE_NEG_CONSECUTIVO
  AND MCC.MCC_SUC_CODIGO      = CGE.CGE_SUC_CODIGO
  JOIN BANCOS BAN
  ON CGE.CGE_CBA_BAN_CODIGO = BAN.BAN_CODIGO
  JOIN ORDENES_Y_PAGOS_ANULADOS OPA 
  ON CGE.CGE_CONSECUTIVO = OPA.OPA_CGE_CONSECUTIVO
  AND CGE.CGE_SUC_CODIGO = OPA.OPA_SUC_CODIGO
  AND CGE.CGE_NEG_CONSECUTIVO = OPA.OPA_NEG_CONSECUTIVO
  JOIN ORDENES_DE_PAGO ODP
  ON OPA.OPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND OPA.OPA_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND OPA.OPA_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO 
  JOIN ORDENES_FONDOS OFO
  ON ODP.ODP_OFO_CONSECUTIVO = OFO.OFO_CONSECUTIVO AND
  ODP.ODP_OFO_SUC_CODIGO = OFO.OFO_SUC_CODIGO
  JOIN CONVENIOS CONV
  ON OFO.OFO_CFO_CODIGO              = CONV.CONV_CFO_CODIGO
  AND MCC.MCC_CCC_CLI_PER_NUM_IDEN   = CONV.CONV_CFO_CCC_CLI_PER_NUM_IDEN
  AND MCC.MCC_CCC_CLI_PER_TID_CODIGO = CONV.CONV_CFO_CCC_CLI_PER_TID_COD
  AND MCC.MCC_CCC_NUMERO_CUENTA      = CONV.CONV_CFO_CCC_NUMERO_CUENTA
  AND CONV.CONV_CFO_FON_CODIGO       ='800154697-A'
  --VAGTUS054239.AjusteMulticashCartera
  LEFT JOIN DETALLES_PAGOS_ACH DPA
  ON DPA.DPA_ODP_CONSECUTIVO = ODP.ODP_CONSECUTIVO
  AND DPA.DPA_ODP_NEG_CONSECUTIVO = ODP.ODP_NEG_CONSECUTIVO
  AND DPA.DPA_ODP_SUC_CODIGO = ODP.ODP_SUC_CODIGO
  AND DPA.DPA_CONSECUTIVO = MCC.MCC_DPA_CONSECUTIVO
  WHERE MCC.MCC_TMC_MNEMONICO       IN ('PCHG', 'RPCHG')
  AND MCC.MCC_NEG_CONSECUTIVO        =4
  AND CONV.CONV_CONSECUTIVO          = P_CONV_CONSECUTIVO
  AND MCC.MCC_FECHA                 >= TO_DATE(P_FECHA_PROCESO_INI)
  AND MCC.MCC_FECHA                  < TO_DATE(P_FECHA_PROCESO_FIN) + 1
  AND DECODE(P_TIPO_ENVIO,'P', MCC.MCC_FECHA_ENVIO_MULTICASH, NULL) IS NULL;

  --AJUSTE TERPEL 
  CURSOR C_TERPEL IS
  SELECT CONV_CFO_CCC_CLI_PER_NUM_IDEN PER_NUM_IDEN,
         CONV_CFO_CCC_CLI_PER_TID_COD PER_TID_COD
  FROM EXTRACTOS_CUENTAS_PLANOS ECP 
  JOIN CONVENIOS CONV on ECP.ECP_CONV_CONSECUTIVO = CONV.CONV_CONSECUTIVO
  WHERE ECP.ECP_ESTADO='A'
	AND CONV_CONSECUTIVO = P_CONV_CONSECUTIVO; 
  ----------------------------------------------------------------------------- 

  CONN                UTL_SMTP.CONNECTION;
  CRLF                VARCHAR2(2) :=  CHR(13)||CHR(10);                                
  V_ARCHIVO_CABECERA  VARCHAR2(80);
  V_ARCHIVO_DETALLE   VARCHAR2(80);
  V_ARCHIVO_ASO2001	 VARCHAR2(80);
  V_SIGNO             VARCHAR2(1);
  V_SIGNO_SALDO_FINAL VARCHAR2(1);
  V_LINEA             VARCHAR2(8000);
  V_SEPARADOR         VARCHAR2(1) := ';';
  V_TOTAL_DEBITOS     NUMBER;
  V_TOTAL_CREDITOS    NUMBER;
  V_TOTAL_D_C         NUMBER;
  V_TOTAL_PAGOS       NUMBER;
  V_TOTAL_LINEAS      NUMBER;
  V_TOTAL_LINEASAB    NUMBER;
  V_SALDO_FINAL       NUMBER;
  V_NUMERO_EXTRACTO   NUMBER;
  V_ENVIAR            INTEGER;
  V_HORA_ACTUAL       VARCHAR2(2);
  R_RECAUDOS          C_RECAUDOS%ROWTYPE;
  R_DEVUELTOS		      C_DEVUELTOS%ROWTYPE;
  R_PAGOS_TRAN        C_PAGOS_TRAN%ROWTYPE;
  R_PAGOS_CHE         C_PAGOS_CHE%ROWTYPE;
  R_PAGOS_CUENTAS     C_PAGOS_CUENTAS%ROWTYPE;
  R_PAGOS_GER         C_PAGOS_GER%ROWTYPE;
  R_CONSECUTIVO       C_CONSECUTIVO%ROWTYPE;
  R_TERPEL	       	  C_TERPEL%ROWTYPE;
  ERROR_EXTRACTO      EXCEPTION;
  ERROR_INFORME       EXCEPTION;
  CODIGO_SAP          VARCHAR2(4);   
  V_PER_NUM_IDEN      VARCHAR2(15);
  V_PER_TID_COD       VARCHAR2(3);
  EXTRACTO_ARCHIVO    UTL_FILE.FILE_TYPE; 
  V_NOMBRE_ARCHIVO    VARCHAR2(100);
  V_PREFIJO_ARCHIVO   VARCHAR2(100);
  V_TXT_TIPO          VARCHAR2(100);  
  V_TITULO 				    VARCHAR2(50);
  V_COD_FONDO 			  VARCHAR2(15); 
  V_NUM_CUENTA        NUMBER;
  V_TID_COD           VARCHAR2(3);
  V_VALOR				      VARCHAR2(30);
  V_VALTOTAL			    VARCHAR2(30);
  V_APORTE            NUMBER(3);

  P_NUM_INI           NUMBER;  
  P_NUM_FIN           NUMBER; 

  V_TERPEL            VARCHAR2(1);
  V_NIT_TERPEL        NUMBER;
  V_APORTE_TERPEL     VARCHAR2(100);
  V_DESC              VARCHAR2(200) := '';

BEGIN
  V_ARCHIVO_CABECERA  := TO_CHAR(P_CONV_CONSECUTIVO)||'_'||TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')||'_'||TO_CHAR(SYSDATE,'HH24')||'00'||P_TIPO_ENVIO||'C';
  V_ARCHIVO_DETALLE   := TO_CHAR(P_CONV_CONSECUTIVO)||'_'||TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')||'_'||TO_CHAR(SYSDATE,'HH24')||'00'||P_TIPO_ENVIO||'D';
  V_ARCHIVO_ASO2001   := TO_CHAR(P_CONV_CONSECUTIVO)||'_'||TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')||'_'||TO_CHAR(SYSDATE,'HH24')||'00'||P_TIPO_ENVIO||'AB'; --Especial para asobancaria que solo es un archivo consolidado
  IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
    V_ARCHIVO_CABECERA  := TO_CHAR(P_CONV_CONSECUTIVO)||'_'||TO_CHAR(P_FECHA_PROCESO_FIN - 1,'YYYYMMDD')||'_'||TO_CHAR(SYSDATE,'HH24')||'00'||P_TIPO_ENVIO||'CM';
    V_ARCHIVO_DETALLE   := TO_CHAR(P_CONV_CONSECUTIVO)||'_'||TO_CHAR(P_FECHA_PROCESO_FIN - 1,'YYYYMMDD')||'_'||TO_CHAR(SYSDATE,'HH24')||'00'||P_TIPO_ENVIO||'DM';
    V_ARCHIVO_ASO2001 := TO_CHAR(P_CONV_CONSECUTIVO)||'_'||TO_CHAR(P_FECHA_PROCESO_FIN - 1,'YYYYMMDD')||'_'||TO_CHAR(SYSDATE,'HH24')||'00'||P_TIPO_ENVIO||'ABM'; --Especial para asobancaria que solo es un archivo consolidado
  END IF;
  V_ARCHIVO_CABECERA  := TRIM(V_ARCHIVO_CABECERA);
  V_ARCHIVO_DETALLE   := TRIM(V_ARCHIVO_DETALLE);
  V_ARCHIVO_ASO2001   := TRIM(V_ARCHIVO_ASO2001);
  V_TOTAL_DEBITOS     := 0;
  V_TOTAL_CREDITOS    := 0;
  V_TOTAL_LINEAS      := 0;
  V_TOTAL_LINEASAB    := 0;
  V_SALDO_FINAL       := 0; 
  V_ENVIAR            := 0;

  P_NUM_INI := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS','INI');

  SELECT TO_CHAR(SYSDATE,'HH24') INTO V_HORA_ACTUAL FROM DUAL;

  SELECT CONV_CFO_CCC_CLI_PER_NUM_IDEN 
  INTO V_PER_NUM_IDEN 
  FROM CONVENIOS 
  WHERE CONV_CONSECUTIVO = P_CONV_CONSECUTIVO;  

  SELECT CONV_CFO_FON_CODIGO, CONV_CFO_CCC_NUMERO_CUENTA, CONV_CFO_CCC_CLI_PER_TID_COD , TRIM(CONV_CFO_CODIGO)
  INTO V_COD_FONDO,  V_NUM_CUENTA,  V_TID_COD , V_APORTE        
  FROM CONVENIOS 
  WHERE CONV_CFO_CCC_CLI_PER_NUM_IDEN = V_PER_NUM_IDEN
  AND CONV_CONSECUTIVO = P_CONV_CONSECUTIVO;

  OPEN C_CONSECUTIVO;
  FETCH C_CONSECUTIVO INTO R_CONSECUTIVO;
  IF C_CONSECUTIVO%NOTFOUND THEN
    INSERT INTO CONTROL_EXTRACTOS_CUENTAS (CXC_CONV_CONSECUTIVO, CXC_TIPO_INFORME, CXC_CONSECUTIVO) 
    VALUES (P_CONV_CONSECUTIVO, P_ECP_TIPO_INFORME, 0);     
    V_NUMERO_EXTRACTO := 1;
  ELSE
    IF P_REPROCESO = 'N' THEN    
      V_NUMERO_EXTRACTO := NVL(R_CONSECUTIVO.CXC_CONSECUTIVO,0) + 1;
    ELSE
      V_NUMERO_EXTRACTO := NVL(R_CONSECUTIVO.CXC_CONSECUTIVO,0);
    END IF;
  END IF;  
  CLOSE C_CONSECUTIVO; 

  IF V_NUMERO_EXTRACTO IS NULL THEN
    RAISE ERROR_EXTRACTO;
  END IF;

  CODIGO_SAP := P_ECP_TIPO_INFORME;  

  IF CODIGO_SAP IS NULL THEN
    RAISE ERROR_INFORME;
  END IF;    

  ------------------------------------------------------------------------------
  --Controlar que si hay datos envíe archivo
  ------------------------------------------------------------------------------

  OPEN C_RECAUDOS (P_TIPO_ENVIO);
  FETCH C_RECAUDOS INTO R_RECAUDOS;
    IF C_RECAUDOS%FOUND THEN
      V_ENVIAR := 1;
    END IF;
  CLOSE C_RECAUDOS;

  OPEN C_DEVUELTOS(P_TIPO_ENVIO);
  FETCH C_DEVUELTOS INTO R_DEVUELTOS;
	IF C_DEVUELTOS%FOUND THEN
		V_ENVIAR := 1;
	END IF;	
  CLOSE C_DEVUELTOS;

  OPEN C_PAGOS_TRAN (P_TIPO_ENVIO);
  FETCH C_PAGOS_TRAN INTO R_PAGOS_TRAN;
    IF C_PAGOS_TRAN%FOUND THEN
      V_ENVIAR := 1;
    END IF;
  CLOSE C_PAGOS_TRAN;

  OPEN C_PAGOS_CHE (P_TIPO_ENVIO);
  FETCH C_PAGOS_CHE INTO R_PAGOS_CHE;
    IF C_PAGOS_CHE%FOUND THEN
      V_ENVIAR := 1;
    END IF;
  CLOSE C_PAGOS_CHE;

  OPEN C_PAGOS_CUENTAS (P_TIPO_ENVIO);
  FETCH C_PAGOS_CUENTAS INTO R_PAGOS_CUENTAS;
    IF C_PAGOS_CUENTAS%FOUND THEN
      V_ENVIAR := 1;
    END IF;
  CLOSE C_PAGOS_CUENTAS;

  OPEN C_PAGOS_GER (P_TIPO_ENVIO);
  FETCH C_PAGOS_GER INTO R_PAGOS_GER;
    IF C_PAGOS_GER%FOUND THEN
      V_ENVIAR := 1;
    END IF;
  CLOSE C_PAGOS_GER;

  ------------------------------------------------------------------------------
  --FORMATO DEL CORREO ELECTRÓNICO
  ------------------------------------------------------------------------------

  IF P_ECP_TIPO_INFORME = 'AB01' THEN 
    V_TITULO:= 'Asobancaria';
  ELSE 
    V_TITULO := 'Multicash';
  END IF;

  IF P_TIPO_ENVIO = 'P'  THEN
    V_TXT_TIPO := 'Archivo '||V_TITULO|| ' parcial Corte: '|| V_HORA_ACTUAL ||':00';
  ELSIF P_TIPO_ENVIO = 'C' THEN
    V_TXT_TIPO := 'Archivo '||V_TITULO||' consolidado Fecha: '||TO_CHAR(P_FECHA_PROCESO_INI,'dd-mon-yyyy');
    IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
      V_TXT_TIPO := 'Archivo '||V_TITULO||' consolidado mensual Fecha: '||TO_CHAR(P_FECHA_PROCESO_FIN - 1,'dd-mon-yyyy');
    END IF;  
  END IF;

  IF V_ENVIAR <> 0 THEN
    IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
      V_DESC := 'del consolidado mensual de movimientos';
    END IF;

  CONN := P_MAIL.BEGIN_MAIL(SENDER       => 'MULTICASH@CORREDORES.COM', 
                            RECIPIENTS   => P_CADENA_ENVIO,
                            SUBJECT      => 'Información del Convenio - '|| P_CONV_CONSECUTIVO||' '|| V_TXT_TIPO,
                            MIME_TYPE    => P_MAIL.MULTIPART_MIME_TYPE);
  P_MAIL.ATTACH_TEXT(CONN      => CONN,
                     DATA      => '<html>'||
                                     '<head>'||
                                       '<IMG src=https://zonatransaccional.corredores.com/CorredoresEnLinea/App_Themes/Default/images/imagen_header.jpg>'||
                                     '</head>'||
                                     '<body FACE=arial> '||
                                     '<table>'||
                                     '<font size=2 face=Arial Black>'||
                                       '<br/><br/><br/><br/><br/><br/>'||
                                          'Estamos remitiendo informacion ' || V_DESC || ' del Convenio: '||P_CONV_CONSECUTIVO||' '|| V_TXT_TIPO ||
                                         '<br/><br/><br/><br/><br/><br/>'||
                                         ' Atentamente,'||
                                         '<br/><br/><br/><br/>'||
                                         '<B>'||'DAVIVIENDA CORREDORES'||'</B>'||
                                         '<br/><br/><br/><br/><br/><br/>'||
                                       '<br/><br/><br/>'||
                                       '</td>'||
                                       '</font>'||
                                    '<table>'||
                                    '</body>'||                                    
                                  '</html>',
                     MIME_TYPE => 'text/html');

  IF P_ECP_TIPO_INFORME = 'AB01'THEN   

	 P_MAIL.BEGIN_ATTACHMENT(CONN          => CONN,
	  								 MIME_TYPE    => V_ARCHIVO_ASO2001||'/txt',
									 INLINE       => TRUE,
									 FILENAME     => V_ARCHIVO_ASO2001||'.txt',
									 TRANSFER_ENC => 'text');	

  ELSE 
    P_MAIL.BEGIN_ATTACHMENT(CONN          => CONN,
								    MIME_TYPE    => V_ARCHIVO_DETALLE||'/txt',
									 INLINE       => TRUE,
									 FILENAME     => V_ARCHIVO_DETALLE||'.txt',
									 TRANSFER_ENC => 'text');
  END IF;

   ---------------
   IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
    V_NOMBRE_ARCHIVO := TO_CHAR(P_CONV_CONSECUTIVO)
                       || '_' || TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')
                       || '_' || TO_CHAR(SYSDATE,'HH24')
                       || '00'|| P_TIPO_ENVIO || 'DM.txt';
   ELSE
    V_NOMBRE_ARCHIVO := TO_CHAR(P_CONV_CONSECUTIVO)
                       || '_' || TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')
                       || '_' || TO_CHAR(SYSDATE,'HH24')
                       || '00'|| P_TIPO_ENVIO || 'D.txt';
   END IF;

   EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR', V_NOMBRE_ARCHIVO, 'W');


   IF P_ECP_TIPO_INFORME = 'AB01'THEN
    IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
      V_NOMBRE_ARCHIVO := TO_CHAR(P_CONV_CONSECUTIVO)
                         || '_' || TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')
                         || '_' || TO_CHAR(SYSDATE,'HH24')
                         || '00'|| P_TIPO_ENVIO || 'ABM.txt';
    ELSE
      V_NOMBRE_ARCHIVO := TO_CHAR(P_CONV_CONSECUTIVO)
                         || '_' || TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')
                         || '_' || TO_CHAR(SYSDATE,'HH24')
                         || '00'|| P_TIPO_ENVIO || 'AB.txt';
	END IF;


     EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR', V_NOMBRE_ARCHIVO,'W');

   END IF;

	--END IF;

  IF P_ECP_TIPO_INFORME = 'AB01' THEN
  -- CABECERA
		 V_LINEA := '01'|| 				                                                                               			-- 1. Encabezado
                 LPAD(TRIM(V_PER_NUM_IDEN)|| P_CLIENTES.RT_DIGITO_CONTROL(V_PER_NUM_IDEN), 10, 0)|| 				    			-- 2. Nit del cliente                                                                                            
                 TO_CHAR(R_RECAUDOS.MCC_FECHA,'YYYYMMDD')||                                                        			-- 3. Fecha de operacion de recaudo
					  '026'||																													    			-- 4.	Codigo de la entidad Recaudadora
					  LPAD((V_TID_COD||V_COD_FONDO||V_NUM_CUENTA||'|'||V_APORTE), 17, 0)||		                                 -- 5. Cuenta de la entidad recaudadora
					  TO_CHAR(SYSDATE,'YYYYMMDD')||	                 																    			-- 6. Fecha de generacion del arhivo
					  LPAD(TO_CHAR(SYSDATE, 'HH24MI'), 4, 0)||															   		    			-- 7. Hora de grabacion del archivo en formato militar.
					  'A'||LPAD(TO_CHAR(V_NUMERO_EXTRACTO), 2, 0)||																	    			-- 8. Orden Cronologico generacion de Archivos
					  '00'||																																		-- 9. Tipo de Cuenta '00' para FIC.
					  LPAD(P_CONV_CONSECUTIVO, 6, 0)||CHR(13)||																						-- 10. Numero comvenio
					  ----------------- Registro de encabezado de lote
					  '05'||																																		-- 1. Tipo de registro siempre sera '05'
					  RPAD(0,13, 0)|| 																														-- 2. Codigo IAC (EAN)					  
					  LPAD(V_NUMERO_EXTRACTO, 4, 0)|| 																									-- 4.Consecutivo del archivo
					  LPAD(' ', 143, ' ')||CHR(13);

    V_NUMERO_EXTRACTO := V_NUMERO_EXTRACTO + 1;

	 P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
	 UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);

  END IF;

  -------------------------------------
  -- AJUSTE TERPEL 
 OPEN C_TERPEL;
 FETCH C_TERPEL INTO R_TERPEL;
   IF C_TERPEL%FOUND THEN 
      V_NIT_TERPEL:= R_TERPEL.PER_NUM_IDEN;
      IF V_NIT_TERPEL = '830095213' THEN 
         V_TERPEL := 'S';
      END IF;
   END IF;
 CLOSE C_TERPEL;
 -------------------------------------

  ------------------------------------------------------------------------------
  --1. ARCHIVO DE DETALLE -> RECAUDOS Y DEVOLUCIONES
  ------------------------------------------------------------------------------
  OPEN C_RECAUDOS(P_TIPO_ENVIO);
  FETCH C_RECAUDOS INTO R_RECAUDOS;
  WHILE C_RECAUDOS%FOUND LOOP

    IF R_RECAUDOS.MCC_MONTO_CARTERA < 0 THEN
      V_SIGNO := '-';
      V_TOTAL_DEBITOS := V_TOTAL_DEBITOS + R_RECAUDOS.MCC_MONTO_CARTERA;
    ELSE
      V_SIGNO := '+';
      V_TOTAL_CREDITOS := V_TOTAL_CREDITOS + R_RECAUDOS.MCC_MONTO_CARTERA;
    END IF;

    -- Estructura TERPEL

    IF P_ECP_TIPO_INFORME = 'DC01' THEN

       IF V_TERPEL = 'S' THEN 
          CODIGO_SAP := '026';
          V_APORTE_TERPEL := TRIM(R_RECAUDOS.MCC_CCC_CLI_PER_NUM_IDEN)||R_RECAUDOS.MCC_CCC_NUMERO_CUENTA||R_RECAUDOS.APORTE;
       ELSE
          CODIGO_SAP := P_ECP_TIPO_INFORME;
          V_APORTE_TERPEL := TRIM(R_RECAUDOS.MCC_CCC_CLI_PER_NUM_IDEN);
       END IF;

    V_LINEA := RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                 --1. Tipo de Reporte, para la estructura DC02 codigo DC01 
               V_APORTE_TERPEL||V_SEPARADOR||                                                                   --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_RECAUDOS.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                          --4. Fecha de la operación
               TRIM(TO_CHAR(R_RECAUDOS.BAN_NIT))||V_SEPARADOR||                                                 --5. Nit del Banco
               TRIM(TO_CHAR(R_RECAUDOS.BAN_CODIGO))||V_SEPARADOR||                                              --6. Codigo del Banco               
               TRIM(R_RECAUDOS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               TRIM(TO_CHAR(R_RECAUDOS.RCA_CONV_CONSECUTIVO))||V_SEPARADOR||                                    --8. Convenio
               TRIM(NVL(R_RECAUDOS.REAS_SUCURSAL,'0000'))||V_SEPARADOR||                                        --9. Sucursal del recaudo
               V_SEPARADOR||                                                                                    --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_RECAUDOS.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR|| --11. Monto de la operación
               TRIM(R_RECAUDOS.RCA_NUM_IDEN_CONSIGNANTE)||V_SEPARADOR||                                         --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_RECAUDOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                      --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Causal rechazo pagos
               V_SEPARADOR||                                                                                    --16. Vacía
               TRIM(R_RECAUDOS.SEGUNDO_8020)||V_SEPARADOR||                                                     --17. Segundo 8020
               TRIM(R_RECAUDOS.TIPO_RECAUDO)||V_SEPARADOR||                                                     --18. Tipo de recaudo
               NVL(TRIM(TO_CHAR(R_RECAUDOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                  --19. Ciclo del abono
               R_RECAUDOS.RECIBOCAJA ||V_SEPARADOR||                                                            --20. VAGTUD861-SP02_HU03.Reporteria consecutivo rca
               V_SEPARADOR||                                                                                    --21. Código único de transacción (No se Usa)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;       

      ELSIF P_ECP_TIPO_INFORME = 'DC02' THEN

       --Estructura Industrias HACEB     
		 V_LINEA := 'DC01'||V_SEPARADOR||                                                                         --1. Tipo de Reporte, para la estructura DC02 codigo DC01 
               TRIM(R_RECAUDOS.MCC_CCC_CLI_PER_NUM_IDEN)||V_SEPARADOR||                                         --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_RECAUDOS.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                          --4. Fecha de la operación
               TRIM(TO_CHAR(R_RECAUDOS.BAN_NIT))||V_SEPARADOR||                                                 --5. Nit del Banco
               TRIM(R_RECAUDOS.RAZON_REVERSION)||V_SEPARADOR||                                                  --6. Motivo Reversión Recibos               
               TRIM(R_RECAUDOS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Convenio
               V_SEPARADOR||                                                                                    --9. Sucursal del recaudo
               V_SEPARADOR||                                                                                    --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_RECAUDOS.MCC_MONTO_CARTERA),'999999999990.00'))||V_SEPARADOR|| 		 --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_RECAUDOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                      --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Causal rechazo pagos
               V_SEPARADOR||                                                                                    --16. Vacía
               TRIM(R_RECAUDOS.SEGUNDO_8020)||V_SEPARADOR||                                                     --17. Segundo 8020
               TRIM(R_RECAUDOS.TIPO_RECAUDO)||V_SEPARADOR||                                                     --18. Tipo de recaudo
               NVL(TRIM(TO_CHAR(R_RECAUDOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                  --19. Ciclo del abono
               R_RECAUDOS.RECIBOCAJA ||V_SEPARADOR||                                                            --20. VAGTUD861-SP02_HU03.Reporteria consecutivo rca
               V_SEPARADOR||                                                                                    --21. Código único de transacción (No se Usa)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro

      ELSIF P_ECP_TIPO_INFORME = 'DC03' THEN

       --Estructura Universidad Minuto de Dios
		V_LINEA := '51'||V_SEPARADOR||                                                                            --1. Tipo de Reporte, para la estructura DC03, siempre va a ser 51
               '0550000860079174'||V_SEPARADOR||                                         								 --2. Segun requerimiento se deja el valor fijo 0550000860079174
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_RECAUDOS.MCC_FECHA,'DD.MM.YY')||V_SEPARADOR||                                          --4. Fecha de la operación
               V_SEPARADOR||                                                                                    --5. Uso futuro
					'1' ||V_SEPARADOR||																										 --6. Codigo del Banco por donde se recaudaron los recursos
               TRIM(R_RECAUDOS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Uso futuro
               V_SEPARADOR||                                                                                    --9. Uso futuro
               V_SEPARADOR||                                                                                    --10. Uso futuro
               V_SIGNO||TRIM(TO_CHAR(ABS(R_RECAUDOS.MCC_MONTO_CARTERA),'999999999990'))||V_SEPARADOR|| 		 --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_RECAUDOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                      --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Uso Futuro
               V_SEPARADOR||                                                                                    --16. Uso Futuro
               LPAD(TRIM(R_RECAUDOS.SEGUNDO_8020), 18, 0)||V_SEPARADOR||                                        --17. Segundo 8020
               TRIM(R_RECAUDOS.TIPO_RECAUDO)||V_SEPARADOR||                                                     --18. Tipo de recaudo
               NVL(TRIM(TO_CHAR(R_RECAUDOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                  --19. Ciclo del abono
               R_RECAUDOS.RECIBOCAJA ||V_SEPARADOR||                                                            --20. VAGTUD861-SP02_HU03.Reporteria consecutivo rca
               V_SEPARADOR||                                                                                    --21. Uso Futuro
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro

		ELSIF P_ECP_TIPO_INFORME = 'AB01' THEN  

		V_VALOR := TRIM(TO_CHAR(ABS(R_RECAUDOS.MCC_MONTO_CARTERA),'999999999990.00'));
		--Estructura Asobancaria2001
		V_LINEA := '06'||						                                                   						    -- 1. Tipo de Reporte
						LPAD(TRIM(R_RECAUDOS.SEGUNDO_8020), 48, 0)||														-- 2. Segundo 8020
						LPAD(SUBSTR(LPAD(V_VALOR, 15, 0), 1, 12)||SUBSTR(LPAD(V_VALOR, 15, 0), 14, 2), 14, 0)||				-- 3. Monto de la operación						
						LPAD(TRIM(R_RECAUDOS.TIPO_RECAUDO), 2, 0)||			  												-- 4. procedencia del pago
						LPAD(TRIM(R_RECAUDOS.TIPO_RECAUDO), 2, 0)||															-- 5. Medio de pago
						'000000'||																							-- 6. Numero de cheque 
						'000000'||																							-- 7. Numero autorizacion
						LPAD(NVL(TRIM(TO_CHAR(R_RECAUDOS.BAN_CODIGO)), 000), 3, 0)||                       					-- 8. Código del Banco de recaudo
						LPAD(NVL(TRIM(R_RECAUDOS.REAS_SUCURSAL), '0000'), 4, 0)||                                      		-- 9. Sucursal del recaudo
						LPAD(TO_CHAR(V_NUMERO_EXTRACTO), 7,0)||   															-- 10. Consecutivo del envío siempre empieza en 02
						LPAD(REPLACE(R_RECAUDOS.CAUSAL_DEV, '   ', '000'), 3, 0)||			 								-- 11. Causal de devolucion
						RPAD(R_RECAUDOS.MCC_TMC_MNEMONICO, 5, 0)||															-- 12. Tipo de movimiento
						LPAD(NVL(TRIM(TO_CHAR(R_RECAUDOS.CICLO_ABONO)),'00'),2,0);		     								-- 13. Ciclo del abono ACH							-- 13. Reservado

		  V_NUMERO_EXTRACTO := V_NUMERO_EXTRACTO + 1;

		END IF;

      P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 
      V_TOTAL_LINEAS := V_TOTAL_LINEAS + 1;
		V_TOTAL_LINEASAB := V_TOTAL_LINEASAB + 1;

      UPDATE MOVIMIENTOS_CUENTA_CORREDORES 
      SET MCC_FECHA_ENVIO_MULTICASH = TRUNC(SYSDATE)
      WHERE MCC_CONSECUTIVO = R_RECAUDOS.MCC_CONSECUTIVO;

      FETCH C_RECAUDOS INTO R_RECAUDOS;
		V_LINEA:= '';
  END LOOP;

  CLOSE C_RECAUDOS;

  -----------------------------------------------------------------------------
  --1.1 ARCHIVO DE DETALLE -> CHEQUES DEVUELTOS CDEV
  -----------------------------------------------------------------------------

  OPEN C_DEVUELTOS(P_TIPO_ENVIO);
  FETCH C_DEVUELTOS INTO R_DEVUELTOS;
  WHILE C_DEVUELTOS%FOUND LOOP

    IF R_DEVUELTOS.MCC_MONTO_CARTERA < 0 THEN
      V_SIGNO := '-';
      V_TOTAL_DEBITOS := V_TOTAL_DEBITOS + R_DEVUELTOS.MCC_MONTO_CARTERA;
    ELSE
      V_SIGNO := '+';
      V_TOTAL_CREDITOS := V_TOTAL_CREDITOS + R_DEVUELTOS.MCC_MONTO_CARTERA;
    END IF;

    --Estructura TERPEL

    IF P_ECP_TIPO_INFORME = 'DC01' THEN
        IF V_TERPEL = 'S' THEN 
           CODIGO_SAP := '026';
           V_APORTE_TERPEL := TRIM(R_DEVUELTOS.MCC_CCC_CLI_PER_NUM_IDEN)||R_DEVUELTOS.MCC_CCC_NUMERO_CUENTA||R_DEVUELTOS.APORTE;
        ELSE 
           V_APORTE_TERPEL := TRIM(R_DEVUELTOS.MCC_CCC_CLI_PER_NUM_IDEN);
        END IF;



    V_LINEA := RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                 --1. Tipo de Reporte 
               V_APORTE_TERPEL||V_SEPARADOR||                                                                   --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_DEVUELTOS.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                         --4. Fecha de la operación
               TRIM(TO_CHAR(R_DEVUELTOS.BAN_NIT))||V_SEPARADOR||                                                --5. Nit del Banco
               TRIM(TO_CHAR(R_DEVUELTOS.BAN_CODIGO))||V_SEPARADOR||                                             --6. Código del Banco
               TRIM(R_RECAUDOS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               TRIM(P_CONV_CONSECUTIVO)||V_SEPARADOR||                                                          --8. Convenio
               TRIM(R_DEVUELTOS.REAS_SUCURSAL)||V_SEPARADOR||                                                   --9. Sucursal del recaudo
               TRIM(R_DEVUELTOS.CCA_NUMERO_CHEQUE)||V_SEPARADOR||                                               --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_DEVUELTOS.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||--11. Monto de la operación
               TRIM(R_DEVUELTOS.RCA_NUM_IDEN_CONSIGNANTE)||V_SEPARADOR||                                        --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_DEVUELTOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                     --14. Fecha del recaudo
               '/'||V_SEPARADOR||                                                                               --15. Causal rechazo pagos
               TRIM(R_DEVUELTOS.RAZON_REVERSION)||V_SEPARADOR||                                                 --16. Motivo Reversión Recibos
               TRIM(R_DEVUELTOS.SEGUNDO_8020)||V_SEPARADOR||                                                    --17. Segundo 8020
               TRIM(R_DEVUELTOS.TIPO_RECAUDO)||V_SEPARADOR||                                                    --18. Tipo de recaudo
               NVL(TRIM(TO_CHAR(R_DEVUELTOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                 --19. Ciclo del abono
               V_SEPARADOR||                                                                                    --20. Causal de rechazo (Uso futuro)
               V_SEPARADOR||                                                                                    --21. Código único de transacción (No se Usa)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;	                                                                                     --36. Uso futuro

       ELSIF P_ECP_TIPO_INFORME = 'DC02' THEN

       --Estructura Industrias HACEB

               V_LINEA := 'DC01'||V_SEPARADOR||                                                                 --1. Tipo de Reporte DC01 HACEB
               TRIM(R_DEVUELTOS.MCC_CCC_CLI_PER_NUM_IDEN)||V_SEPARADOR||                                        --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_DEVUELTOS.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                         --4. Fecha de la operación
               TRIM(TO_CHAR(R_DEVUELTOS.BAN_NIT))||V_SEPARADOR||                                                --5. Nit del Banco
               TRIM(R_DEVUELTOS.RAZON_REVERSION)||V_SEPARADOR||                                                 --6. Motivo Reversión Recibos
               TRIM(R_RECAUDOS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Convenio
               V_SEPARADOR||                                                                                    --9. Sucursal del recaudo
               V_SEPARADOR||                                                                                    --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_DEVUELTOS.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||--11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_DEVUELTOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                     --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Causal rechazo pagos
               V_SEPARADOR||                                                                                    --16. Vacía
               TRIM(R_DEVUELTOS.SEGUNDO_8020)||V_SEPARADOR||                                                    --17. Segundo 8020
               TRIM(R_DEVUELTOS.TIPO_RECAUDO)||V_SEPARADOR||                                                    --18. Tipo de recaudo
               NVL(TRIM(TO_CHAR(R_DEVUELTOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                 --19. Ciclo del abono
               V_SEPARADOR||                                                                                    --20. Causal de rechazo (Uso futuro)
               V_SEPARADOR||                                                                                    --21. Código único de transacción (No se Usa)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro

      ELSIF P_ECP_TIPO_INFORME = 'DC03' THEN

       --Estructura Universidad Minuto de Dios
		V_LINEA := '51'||V_SEPARADOR||                                                                            --1. Tipo de Reporte, para la estructura DC03, siempre va a ser 51
               '0550000860079174'||V_SEPARADOR||                                         								 --2. Segun requerimiento se deja el valor fijo 0550000860079174
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_DEVUELTOS.MCC_FECHA,'DD.MM.YY')||V_SEPARADOR||                                         --4. Fecha de la operación
               V_SEPARADOR||                                                                                    --5. Uso futuro
					'1' ||V_SEPARADOR||																										 --6. Codigo del Banco por donde se recaudaron los recursos
               TRIM(R_DEVUELTOS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                               --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Uso futuro
               V_SEPARADOR||                                                                                    --9. Uso futuro
               V_SEPARADOR||                                                                                    --10. Uso futuro
               V_SIGNO||TRIM(TO_CHAR(ABS(R_DEVUELTOS.MCC_MONTO_CARTERA),'999999999990'))||V_SEPARADOR|| 		 --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_DEVUELTOS.FECHA_RECAUDO,'dd.mm.yy')||V_SEPARADOR||                                     --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Uso Futuro
               V_SEPARADOR||                                                                                    --16. Uso Futuro
               LPAD(TRIM(R_DEVUELTOS.SEGUNDO_8020), 18, 0)||V_SEPARADOR||                                       --17. Segundo 8020
               TRIM(R_DEVUELTOS.TIPO_RECAUDO)||V_SEPARADOR||                                                    --18. Tipo de recaudo
               NVL(TRIM(TO_CHAR(R_DEVUELTOS.CICLO_ABONO)),'0') || V_SEPARADOR||                                 --19. Ciclo del abono
               V_SEPARADOR||                                                                                    --20. Uso Futuro
               V_SEPARADOR||                                                                                    --21. Uso Futuro
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro							

		ELSIF P_ECP_TIPO_INFORME = 'AB01' THEN  		

		V_VALOR := TRIM(TO_CHAR(ABS(R_DEVUELTOS.MCC_MONTO_CARTERA),'999999999990.00'));	

		--Estructura Asobncaria2001
		V_LINEA := '06'||						                                                   								   -- 1. Tipo de Reporte
						LPAD(TRIM(R_DEVUELTOS.SEGUNDO_8020), 48, 0)||																		-- 2. Segundo 8020
						LPAD(SUBSTR(LPAD(V_VALOR, 15, 0), 1, 12)||SUBSTR(LPAD(V_VALOR, 15, 0), 14, 2), 14, 0)||				-- 3. Monto de la operación						
						LPAD(TRIM(R_DEVUELTOS.TIPO_RECAUDO), 2, 0)||			  															   -- 4. procedencia del pago
						LPAD(TRIM(R_DEVUELTOS.TIPO_RECAUDO), 2, 0)||																			-- 5. Medio de pago
						'000000'||																														-- 6. Numero de cheque 
						'000000'||																														-- 7. Numero autorizacion
						LPAD(NVL(TRIM(TO_CHAR(R_DEVUELTOS.BAN_CODIGO)), 000), 3, 0)||                       					-- 8. Código del Banco de recaudo
						LPAD(NVL(TRIM(R_DEVUELTOS.REAS_SUCURSAL), '0000'), 4, 0)||                                      	-- 9. Sucursal del recaudo
						LPAD(TO_CHAR(V_NUMERO_EXTRACTO), 7,0)||   																			-- 10. Consecutivo del envío siempre empieza en 02
						LPAD(REPLACE(R_DEVUELTOS.CAUSAL_DEV, '   ', '000'), 3, 0)||														-- 11. Causal de devolucion
						RPAD(R_DEVUELTOS.MCC_TMC_MNEMONICO, 5, 0)||																			-- 12. Tipo de movimiento
						LPAD(' ',60,' ');																												-- 13. Reservado

		  V_NUMERO_EXTRACTO := V_NUMERO_EXTRACTO + 1;

		END IF;

      P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 
      V_TOTAL_LINEAS := V_TOTAL_LINEAS + 1;
		V_TOTAL_LINEASAB := V_TOTAL_LINEASAB + 1;

      UPDATE MOVIMIENTOS_CUENTA_CORREDORES 
      SET MCC_FECHA_ENVIO_MULTICASH = TRUNC(SYSDATE)
      WHERE MCC_CONSECUTIVO = R_DEVUELTOS.MCC_CONSECUTIVO;

      FETCH C_DEVUELTOS INTO R_DEVUELTOS;
		V_LINEA:= '';

  END LOOP;
  CLOSE C_DEVUELTOS;

  -----------------------------------------------------------------------------
  --2. PAGOS Y REVERSIONES TRANSFERENCIAS BANCARIAS
  -----------------------------------------------------------------------------

  OPEN C_PAGOS_TRAN(P_TIPO_ENVIO);
  FETCH C_PAGOS_TRAN INTO R_PAGOS_TRAN;
  WHILE C_PAGOS_TRAN%FOUND LOOP

  IF P_ECP_TIPO_INFORME <> 'AB01' THEN

    IF R_PAGOS_TRAN.MCC_MONTO_CARTERA < 0 THEN
      V_SIGNO := '-';
      V_TOTAL_DEBITOS := V_TOTAL_DEBITOS + R_PAGOS_TRAN.MCC_MONTO_CARTERA;
    ELSE
      V_SIGNO := '+';
      V_TOTAL_CREDITOS := V_TOTAL_CREDITOS + R_PAGOS_TRAN.MCC_MONTO_CARTERA;
    END IF;

    --Estructura TERPEL

    IF P_ECP_TIPO_INFORME = 'DC01' THEN
        IF V_TERPEL = 'S' THEN 
          CODIGO_SAP := '026';
          V_APORTE_TERPEL := TRIM(R_PAGOS_TRAN.MCC_CCC_CLI_PER_NUM_IDEN)||R_PAGOS_TRAN.MCC_CCC_NUMERO_CUENTA||R_PAGOS_TRAN.APORTE;
        ELSE 
          V_APORTE_TERPEL := TRIM(R_PAGOS_TRAN.MCC_CCC_CLI_PER_NUM_IDEN);
        END IF;

    V_LINEA := RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               V_APORTE_TERPEL||V_SEPARADOR||                                         --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_TRAN.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                          --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (n/a en pagos)
               V_SEPARADOR||                                                                                      --6. Código del Banco (n/a en pagos)
               TRIM(R_PAGOS_TRAN.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               TRIM(P_CONV_CONSECUTIVO)||V_SEPARADOR||                                                            --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               V_SEPARADOR||                                                                                      --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_TRAN.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR|| --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               TRIM(R_PAGOS_TRAN.BENEFICIARIO)||V_SEPARADOR||                                                     --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_TRAN.TBC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                          --14. Fecha de la transferencia
               TRIM(R_PAGOS_TRAN.RAZON_REVERSION)||V_SEPARADOR||                                                  --15. Causal rechazo pagos
               '/'||V_SEPARADOR||                                                                                 --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_TRAN.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                               --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro               

     --Estructura Industrias HACEB
     ELSIF P_ECP_TIPO_INFORME = 'DC02' THEN
               V_LINEA := 'DC01'||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               TRIM(R_PAGOS_TRAN.MCC_CCC_CLI_PER_NUM_IDEN)||V_SEPARADOR||                                         --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_TRAN.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                          --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (n/a en pagos)               
               TRIM(R_PAGOS_TRAN.RAZON_REVERSION)||V_SEPARADOR||                                                  --6. Motivo rechazo (pagos)
               TRIM(R_PAGOS_TRAN.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                      --8. No se usa
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               V_SEPARADOR||                                                                                      --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_TRAN.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR|| --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               V_SEPARADOR||                                                                                      --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_TRAN.TBC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                          --14. Fecha de la transferencia
               V_SEPARADOR||                                                                                      --15. Causal rechazo pagos - Reportada en campo 6
               V_SEPARADOR||                                                                                      --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_TRAN.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                               --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro

		ELSIF P_ECP_TIPO_INFORME = 'DC03' THEN

       --Estructura Universidad Minuto de Dios
		V_LINEA := '51'||V_SEPARADOR||                                                                            --1. Tipo de Reporte, para la estructura DC03, siempre va a ser 51
               '0550000860079174'||V_SEPARADOR||                                         								 --2. Segun requerimiento se deja el valor fijo 0550000860079174
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_PAGOS_TRAN.MCC_FECHA,'DD.MM.YY')||V_SEPARADOR||                                        --4. Fecha de la operación
               V_SEPARADOR||                                                                                    --5. Uso futuro
					'1' ||V_SEPARADOR||																										 --6. Codigo del Banco por donde se recaudaron los recursos
               TRIM(R_PAGOS_TRAN.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                              --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Uso futuro
               V_SEPARADOR||                                                                                    --9. Uso futuro
               V_SEPARADOR||                                                                                    --10. Uso futuro
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_TRAN.MCC_MONTO_CARTERA),'999999999990'))||V_SEPARADOR|| 	 --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_TRAN.TBC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                    --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Uso Futuro
               V_SEPARADOR||                                                                                    --16. Uso Futuro
               V_SEPARADOR||                                        															 --17. Segundo 8020
               V_SEPARADOR||                                                     										 --18. Tipo de recaudo
               V_SEPARADOR||                                                                                    --19. Uso Futuro
               V_SEPARADOR||                                                                                    --20. Uso Futuro
               TRIM(R_PAGOS_TRAN.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                             --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro

      END IF;

      P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 
      V_TOTAL_LINEAS := V_TOTAL_LINEAS + 1;

		END IF;

      UPDATE MOVIMIENTOS_CUENTA_CORREDORES 
      SET MCC_FECHA_ENVIO_MULTICASH = TRUNC(SYSDATE)
      WHERE MCC_CONSECUTIVO = R_PAGOS_TRAN.MCC_CONSECUTIVO;

      FETCH C_PAGOS_TRAN INTO R_PAGOS_TRAN;

  END LOOP;
  CLOSE C_PAGOS_TRAN;  

  -----------------------------------------------------------------------------
  --3. PAGOS Y REVERSIONES CON CHEQUES
  -----------------------------------------------------------------------------

  OPEN C_PAGOS_CHE(P_TIPO_ENVIO);
  FETCH C_PAGOS_CHE INTO R_PAGOS_CHE;
  WHILE C_PAGOS_CHE%FOUND LOOP

  IF P_ECP_TIPO_INFORME <> 'AB01' THEN

    IF R_PAGOS_CHE.MCC_MONTO_CARTERA < 0 THEN
      V_SIGNO := '-';
      V_TOTAL_DEBITOS := V_TOTAL_DEBITOS + R_PAGOS_CHE.MCC_MONTO_CARTERA;
    ELSE
      V_SIGNO := '+';
      V_TOTAL_CREDITOS := V_TOTAL_CREDITOS + R_PAGOS_CHE.MCC_MONTO_CARTERA;
    END IF;


    --Estructura TERPEL

    IF P_ECP_TIPO_INFORME = 'DC01' THEN
        IF V_TERPEL = 'S' THEN 
          CODIGO_SAP := '026';
          V_APORTE_TERPEL := TRIM(R_PAGOS_CHE.MCC_CCC_CLI_PER_NUM_IDEN)||R_PAGOS_CHE.MCC_CCC_NUMERO_CUENTA||R_PAGOS_CHE.APORTE;
        ELSE 
          V_APORTE_TERPEL := TRIM(R_PAGOS_CHE.MCC_CCC_CLI_PER_NUM_IDEN);
        END IF;

    V_LINEA := RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               V_APORTE_TERPEL||V_SEPARADOR||                                          --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_CHE.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (recaudos)
               V_SEPARADOR||                                                                                      --6. Código del Banco
               TRIM(R_PAGOS_CHE.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                 --7. Tipo de Movimiento
               TRIM(P_CONV_CONSECUTIVO)||V_SEPARADOR||                                                            --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               TO_CHAR(R_PAGOS_CHE.CEG_NUMERO_CHEQUE)||V_SEPARADOR||                                              --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_CHE.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||  --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               TRIM(R_PAGOS_CHE.BENEFICIARIO)||V_SEPARADOR||                                                      --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_CHE.CEG_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --14. Fecha de la operación
               TRIM(R_PAGOS_CHE.RAZON_REVERSION)||V_SEPARADOR||                                                   --15. Causal rechazo pagos
               '/'||V_SEPARADOR||                                                                                 --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_CHE.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                                --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro

		--Formato Industrias HACEB			
      ELSIF  P_ECP_TIPO_INFORME = 'DC02' THEN

               V_LINEA := 'DC01'||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               TRIM(R_PAGOS_CHE.MCC_CCC_CLI_PER_NUM_IDEN)||V_SEPARADOR||                                          --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_CHE.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (recaudos)
               TRIM(R_PAGOS_CHE.RAZON_REVERSION)||V_SEPARADOR||                                                   --6. Causal rechazo pagos               
               TRIM(R_PAGOS_CHE.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                 --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                      --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               TO_CHAR(R_PAGOS_CHE.CEG_NUMERO_CHEQUE)||V_SEPARADOR||                                              --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_CHE.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||  --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               V_SEPARADOR||                                                                                      --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_CHE.CEG_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --14. Fecha de la operación
               V_SEPARADOR||                                                                                      --15. Causal rechazo pagos
               V_SEPARADOR||                                                                                      --16. Motivo Reversión Recibos (Reportado en Campo 6)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_CHE.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                                --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro

	  ELSIF P_ECP_TIPO_INFORME = 'DC03' THEN

       --Estructura Universidad Minuto de Dios
		V_LINEA := '51'||V_SEPARADOR||                                                                            --1. Tipo de Reporte, para la estructura DC03, siempre va a ser 51
               '0550000860079174'||V_SEPARADOR||                                         								 --2. Segun requerimiento se deja el valor fijo 0550000860079174
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_PAGOS_CHE.MCC_FECHA,'DD.MM.YY')||V_SEPARADOR||                                         --4. Fecha de la operación
               V_SEPARADOR||                                                                                    --5. Uso futuro
					'1' ||V_SEPARADOR||																										 --6. Codigo del Banco por donde se recaudaron los recursos
               TRIM(R_PAGOS_CHE.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                               --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Uso futuro
               V_SEPARADOR||                                                                                    --9. Uso futuro
               V_SEPARADOR||                                                                                    --10. Uso futuro
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_CHE.MCC_MONTO_CARTERA),'999999999990'))||V_SEPARADOR|| 		 --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_CHE.CEG_FECHA,'dd.mm.yy')||V_SEPARADOR||                                         --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Uso Futuro
               V_SEPARADOR||                                                                                    --16. Uso Futuro
               V_SEPARADOR||                                        															 --17. Segundo 8020
               V_SEPARADOR||                                                                                    --18. Tipo de recaudo
               V_SEPARADOR||                                                                                    --19. Uso Futuro
               V_SEPARADOR||                                                                                    --20. Uso Futuro
               TRIM(R_PAGOS_CHE.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                              --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro
      END IF;

      P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 
      V_TOTAL_LINEAS := V_TOTAL_LINEAS + 1;

		END IF;

      UPDATE MOVIMIENTOS_CUENTA_CORREDORES 
      SET MCC_FECHA_ENVIO_MULTICASH = TRUNC(SYSDATE)
      WHERE MCC_CONSECUTIVO = R_PAGOS_CHE.MCC_CONSECUTIVO;

      FETCH C_PAGOS_CHE INTO R_PAGOS_CHE;

  END LOOP;
  CLOSE C_PAGOS_CHE;  

  -----------------------------------------------------------------------------
  --4. PAGOS Y REVERSIONES TRANSFERENCIA ENTRE CUENTAS
  -----------------------------------------------------------------------------

  OPEN C_PAGOS_CUENTAS (P_TIPO_ENVIO);
  FETCH C_PAGOS_CUENTAS INTO R_PAGOS_CUENTAS;
  WHILE C_PAGOS_CUENTAS%FOUND LOOP

  IF P_ECP_TIPO_INFORME <> 'AB01' THEN
    IF R_PAGOS_CUENTAS.MCC_MONTO_CARTERA < 0 THEN
      V_SIGNO := '-';
      V_TOTAL_DEBITOS := V_TOTAL_DEBITOS + R_PAGOS_CUENTAS.MCC_MONTO_CARTERA;
    ELSE
      V_SIGNO := '+';
      V_TOTAL_CREDITOS := V_TOTAL_CREDITOS + R_PAGOS_CUENTAS.MCC_MONTO_CARTERA;
    END IF;

    --Estructura TERPEL

    IF P_ECP_TIPO_INFORME = 'DC01' THEN

        IF V_TERPEL = 'S' THEN 
          CODIGO_SAP := '026';
          V_APORTE_TERPEL := TRIM(R_PAGOS_CUENTAS.MCC_CCC_CLI_PER_NUM_IDEN)||R_PAGOS_CUENTAS.MCC_CCC_NUMERO_CUENTA||R_PAGOS_CUENTAS.APORTE;
        ELSE 
          V_APORTE_TERPEL := TRIM(R_PAGOS_CUENTAS.MCC_CCC_CLI_PER_NUM_IDEN);
        END IF;

    V_LINEA := RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               V_APORTE_TERPEL||V_SEPARADOR||                                                                     --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_CUENTAS.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                       --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (recaudos)
               V_SEPARADOR||                                                                                      --6. Código del Banco
               TRIM(R_PAGOS_CUENTAS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                             --7. Tipo de Movimiento
               TRIM(P_CONV_CONSECUTIVO)||V_SEPARADOR||                                                            --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               V_SEPARADOR||                                                                                      --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_CUENTAS.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR|| --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               TRIM(R_PAGOS_CUENTAS.BENEFICIARIO)||V_SEPARADOR||                                                  --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_CUENTAS.TCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                       --14. Fecha de la operación
               TRIM(R_PAGOS_CUENTAS.RAZON_REVERSION)||V_SEPARADOR||                                               --15. Causal rechazo pagos
               '/'||V_SEPARADOR||                                                                                 --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_CUENTAS.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                                --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro               

      --Estructura Industrias HACEB
      ELSIF P_ECP_TIPO_INFORME = 'DC02' THEN

               V_LINEA := 'DC01'||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               TRIM(R_PAGOS_CUENTAS.MCC_CCC_CLI_PER_NUM_IDEN)||V_SEPARADOR||                                      --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_CUENTAS.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                       --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (recaudos)
               TRIM(R_PAGOS_CUENTAS.RAZON_REVERSION)||V_SEPARADOR||                                               --6. Causal rechazo pagos
               TRIM(R_PAGOS_CUENTAS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                             --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                      --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               V_SEPARADOR||                                                                                      --10. Número de Cheque (Pagos)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_CUENTAS.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||--11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               V_SEPARADOR||                                                                                      --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_CUENTAS.TCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                       --14. Fecha de la operación
               V_SEPARADOR||                                                                                      --15. Causal rechazo pagos
               V_SEPARADOR||                                                                                      --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_CUENTAS.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                            --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;

		ELSIF P_ECP_TIPO_INFORME = 'DC03' THEN

       --Estructura Universidad Minuto de Dios
		V_LINEA := '51'||V_SEPARADOR||                                                                            --1. Tipo de Reporte, para la estructura DC03, siempre va a ser 51
               '0550000860079174'||V_SEPARADOR||                                         								 --2. Segun requerimiento se deja el valor fijo 0550000860079174
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_PAGOS_CUENTAS.MCC_FECHA,'DD.MM.YY')||V_SEPARADOR||                                     --4. Fecha de la operación
               V_SEPARADOR||                                                                                    --5. Uso futuro
					'1' ||V_SEPARADOR||																										 --6. Codigo del Banco por donde se recaudaron los recursos
               TRIM(R_PAGOS_CUENTAS.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                           --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Uso futuro
               V_SEPARADOR||                                                                                    --9. Uso futuro
               V_SEPARADOR||                                                                                    --10. Uso futuro
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_CUENTAS.MCC_MONTO_CARTERA),'999999999990'))||V_SEPARADOR||  --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_CUENTAS.TCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                     --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Uso Futuro
               V_SEPARADOR||                                                                                    --16. Uso Futuro
               V_SEPARADOR||                                        															 --17. Segundo 8020
               V_SEPARADOR||                                                                                    --18. Tipo de recaudo
               V_SEPARADOR||                                                                                    --19. Uso Futuro
               V_SEPARADOR||                                                                                    --20. Uso Futuro
               TRIM(R_PAGOS_CUENTAS.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                          --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro

      END IF;

      P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 
      V_TOTAL_LINEAS := V_TOTAL_LINEAS + 1;

		END IF;

      UPDATE MOVIMIENTOS_CUENTA_CORREDORES 
      SET MCC_FECHA_ENVIO_MULTICASH = TRUNC(SYSDATE)
      WHERE MCC_CONSECUTIVO = R_PAGOS_CUENTAS.MCC_CONSECUTIVO;

      FETCH C_PAGOS_CUENTAS INTO R_PAGOS_CUENTAS;

  END LOOP;
  CLOSE C_PAGOS_CUENTAS;

  -----------------------------------------------------------------------------
  --5. PAGOS Y REVERSIONES CON CHEQUES DE GERENCIA
  -----------------------------------------------------------------------------

  OPEN C_PAGOS_GER(P_TIPO_ENVIO);
  FETCH C_PAGOS_GER INTO R_PAGOS_GER;
  WHILE C_PAGOS_GER%FOUND LOOP

  IF P_ECP_TIPO_INFORME <> 'AB01' THEN
    IF R_PAGOS_GER.MCC_MONTO_CARTERA < 0 THEN
      V_SIGNO := '-';
      V_TOTAL_DEBITOS := V_TOTAL_DEBITOS + R_PAGOS_GER.MCC_MONTO_CARTERA;
    ELSE
      V_SIGNO := '+';
      V_TOTAL_CREDITOS := V_TOTAL_CREDITOS + R_PAGOS_GER.MCC_MONTO_CARTERA;
    END IF;

    --Estructura TERPEL

    IF P_ECP_TIPO_INFORME = 'DC01' THEN
         IF V_TERPEL = 'S' THEN 
          CODIGO_SAP := '026';
          V_APORTE_TERPEL := TRIM(R_PAGOS_GER.MCC_CCC_CLI_PER_NUM_IDEN)||R_PAGOS_GER.MCC_CCC_NUMERO_CUENTA||R_PAGOS_GER.APORTE;
        ELSE 
          V_APORTE_TERPEL := TRIM(R_PAGOS_GER.MCC_CCC_CLI_PER_NUM_IDEN);
        END IF;


    V_LINEA := RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               V_APORTE_TERPEL||V_SEPARADOR||                                          --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_GER.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (recaudos)
               V_SEPARADOR||                                                                                      --6. Código del Banco
               TRIM(R_PAGOS_GER.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                 --7. Tipo de Movimiento
               TRIM(P_CONV_CONSECUTIVO)||V_SEPARADOR||                                                            --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               V_SEPARADOR||                                                                                      --10. Número de Cheque (n/a cheques gerencia)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_GER.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||  --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               TRIM(R_PAGOS_GER.BENEFICIARIO)||V_SEPARADOR||                                                      --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_GER.CGE_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --14. Fecha de la operación
               TRIM(R_PAGOS_GER.RAZON_REVERSION)||V_SEPARADOR||                                                   --15. Causal rechazo pagos
               '/'||V_SEPARADOR||                                                                                 --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_GER.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                                --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro                

      --Formato Industrias HACEB
      ELSIF P_ECP_TIPO_INFORME = 'DC02' THEN

               V_LINEA := 'DC01'||V_SEPARADOR||                                                                   --1. Tipo de Reporte 
               TRIM(R_PAGOS_GER.MCC_CCC_CLI_PER_NUM_IDEN)||V_SEPARADOR||                                          --2. Nit del cliente (del convenio)
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                          --3. Consecutivo del extracto
               TO_CHAR(R_PAGOS_GER.MCC_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --4. Fecha de la operación
               V_SEPARADOR||                                                                                      --5. Nit del Banco (recaudos)
               V_SEPARADOR||                                                                                      --6. Código del Banco
               TRIM(R_PAGOS_GER.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                                 --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                      --8. Convenio
               V_SEPARADOR||                                                                                      --9. Sucursal del recaudo (n/a en pagos)
               V_SEPARADOR||                                                                                      --10. Número de Cheque (n/a cheques gerencia)
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_GER.MCC_MONTO_CARTERA),'999999999999999990.00'))||V_SEPARADOR||  --11. Monto de la operación
               V_SEPARADOR||                                                                                      --12. Identificación del consignante (n/a en pagos)
               V_SEPARADOR||                                                                                      --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_GER.CGE_FECHA,'dd.mm.yy')||V_SEPARADOR||                                           --14. Fecha de la operación
               V_SEPARADOR||                                                                                      --15. Causal rechazo pagos
               V_SEPARADOR||                                                                                      --16. Motivo Reversión Recibos (n/a en pagos)
               V_SEPARADOR||                                                                                      --17. Referencia del consignante
               V_SEPARADOR||                                                                                      --18. Tipo de recaudo (no aplica en pagos)
               V_SEPARADOR||                                                                                      --19. Uso futuro
               V_SEPARADOR||                                                                                      --20. Uso futuro
               TRIM(R_PAGOS_GER.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                                --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                      --22. No se usa
               V_SEPARADOR||                                                                                      --23. Uso futuro
               V_SEPARADOR||                                                                                      --24. Uso futuro
               V_SEPARADOR||                                                                                      --25. Uso futuro
               V_SEPARADOR||                                                                                      --26. Uso futuro               
               V_SEPARADOR||                                                                                      --27. Uso futuro               
               V_SEPARADOR||                                                                                      --28. Uso futuro               
               V_SEPARADOR||                                                                                      --29. Uso futuro               
               V_SEPARADOR||                                                                                      --30. Uso futuro               
               V_SEPARADOR||                                                                                      --31. Uso futuro               
               V_SEPARADOR||                                                                                      --32. Uso futuro               
               V_SEPARADOR||                                                                                      --33. Uso futuro               
               V_SEPARADOR||                                                                                      --34. Uso futuro               
               V_SEPARADOR||                                                                                      --35. Uso futuro               
               V_SEPARADOR;                                                                                       --36. Uso futuro

	   ELSIF P_ECP_TIPO_INFORME = 'DC03' THEN
		--Estructura Universidad Minuto de Dios

		V_LINEA := '51'||V_SEPARADOR||                                                                            --1. Tipo de Reporte, para la estructura DC03, siempre va a ser 51
               '0550000860079174'||V_SEPARADOR||                                         								 --2. Segun requerimiento se deja el valor fijo 0550000860079174
               TO_CHAR(V_NUMERO_EXTRACTO)||V_SEPARADOR||                                                        --3. Consecutivo del envío
               TO_CHAR(R_PAGOS_GER.MCC_FECHA,'DD.MM.YY')||V_SEPARADOR||                                         --4. Fecha de la operación
               V_SEPARADOR||                                                                                    --5. Uso futuro
					'1' ||V_SEPARADOR||																										 --6. Codigo del Banco por donde se recaudaron los recursos
               TRIM(R_PAGOS_GER.MCC_TMC_MNEMONICO)||V_SEPARADOR||                                               --7. Tipo de Movimiento
               V_SEPARADOR||                                                                                    --8. Uso futuro
               V_SEPARADOR||                                                                                    --9. Uso futuro
               V_SEPARADOR||                                                                                    --10. Uso futuro
               V_SIGNO||TRIM(TO_CHAR(ABS(R_PAGOS_GER.MCC_MONTO_CARTERA),'999999999990'))||V_SEPARADOR|| 		 --11. Monto de la operación
               V_SEPARADOR||                                                                                    --12. Identificación del consignante
               V_SEPARADOR||                                                                                    --13. Identificación tercero pago
               TO_CHAR(R_PAGOS_GER.CGE_FECHA,'dd.mm.yy')||V_SEPARADOR||                                         --14. Fecha del recaudo
               V_SEPARADOR||                                                                                    --15. Uso Futuro
               V_SEPARADOR||                                                                                    --16. Uso Futuro
               V_SEPARADOR||                                        															 --17. Segundo 8020
               V_SEPARADOR||                                                     										 --18. Tipo de recaudo
               V_SEPARADOR||                                                                                    --19. Uso Futuro
               V_SEPARADOR||                                                                                    --20. Uso Futuro
               TRIM(R_PAGOS_GER.ODP_ID_ARCHIVO_ACH)||V_SEPARADOR||                                              --21. VAGTUS054239. Id cargue Archivo Corline (CorredoresWT Pago.Id)
               V_SEPARADOR||                                                                                    --22. No se usa
               V_SEPARADOR||                                                                                    --23. Uso futuro
               V_SEPARADOR||                                                                                    --24. Uso futuro
               V_SEPARADOR||                                                                                    --25. Uso futuro
               V_SEPARADOR||                                                                                    --26. Uso futuro               
               V_SEPARADOR||                                                                                    --27. Uso futuro               
               V_SEPARADOR||                                                                                    --28. Uso futuro               
               V_SEPARADOR||                                                                                    --29. Uso futuro               
               V_SEPARADOR||                                                                                    --30. Uso futuro               
               V_SEPARADOR||                                                                                    --31. Uso futuro               
               V_SEPARADOR||                                                                                    --32. Uso futuro               
               V_SEPARADOR||                                                                                    --33. Uso futuro               
               V_SEPARADOR||                                                                                    --34. Uso futuro               
               V_SEPARADOR||                                                                                    --35. Uso futuro               
               V_SEPARADOR;                                                                                     --36. Uso futuro
      END IF;

      P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 
      V_TOTAL_LINEAS := V_TOTAL_LINEAS + 1;

		END IF;		

      UPDATE MOVIMIENTOS_CUENTA_CORREDORES 
      SET MCC_FECHA_ENVIO_MULTICASH = TRUNC(SYSDATE)
      WHERE MCC_CONSECUTIVO = R_PAGOS_GER.MCC_CONSECUTIVO;  

      FETCH C_PAGOS_GER INTO R_PAGOS_GER;

  END LOOP;
  CLOSE C_PAGOS_GER;

  ---FIN GENERACIÓN DETALLE

    ------------------------------------------------------------------------------
  -- LINEAS FINALES ASOBANCARIA
  ------------------------------------------------------------------------------

   IF P_ECP_TIPO_INFORME = 'AB01' THEN

	V_VALTOTAL := TRIM(TO_CHAR(ABS(V_TOTAL_DEBITOS+V_TOTAL_CREDITOS),'9999999999999990.00'));

			V_LINEA:= CHR(13)||'08'||																										         -- 1. Tipo de registro, siempre sera '08'
						 LPAD(V_TOTAL_LINEASAB, 9, 0)||					 																		   -- 2. Numero de registros totales en el lote.
						 LPAD(SUBSTR(LPAD(V_VALTOTAL, 19, 0), 1, 16)||SUBSTR(LPAD(V_VALTOTAL, 19, 0), 18, 2), 18, 0)||			-- 3. Suma total						 
						 '    '||																															-- 4. Consecutivo del lote
						 RPAD(' ', 129, ' ')||CHR(13)||																								-- 5. Reservado
						 ----------------
						 '09'||																																-- 1. Tipo de registro
						 LPAD(V_TOTAL_LINEASAB, 9, 0)||																								-- 2. Numero de registros
						 LPAD(SUBSTR(LPAD(V_VALTOTAL, 19, 0), 1, 16)||SUBSTR(LPAD(V_VALTOTAL, 19, 0), 18, 2), 18, 0)||  		-- 3. Suma total
						 '    ';																																-- 4. Reservado

		P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA||CRLF);      
      UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA); 

	END IF;

  P_MAIL.END_ATTACHMENT( CONN => CONN);  
  UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);

  ------------------------------------------------------------------------------
  --COPIAR EL ARCHIVO GENERADO AL FTP CUANDO EL CLIENTE LO TENGA CONFIGURADO
  ------------------------------------------------------------------------------
  IF P_ENVIO_FTP = 'S' THEN
    V_PREFIJO_ARCHIVO := V_NOMBRE_ARCHIVO;
    IF (P_CONV_CONSECUTIVO = 100012) THEN
      V_PREFIJO_ARCHIVO := 'KD' || TO_CHAR(P_FECHA_PROCESO_INI, 'DDMM') ||V_PER_NUM_IDEN;
    END IF;
    UTL_FILE.FCOPY('LOG_DIR',V_NOMBRE_ARCHIVO,'FTPMULTICASH',V_PREFIJO_ARCHIVO);
  END IF;

  ------------------------------------------------------------------------------
  --ARCHIVO CABECERA
  ------------------------------------------------------------------------------
  IF P_ECP_TIPO_INFORME <> 'AB01' THEN

	  V_SALDO_FINAL := ABS(V_TOTAL_DEBITOS) - ABS(V_TOTAL_CREDITOS); 

	  IF V_SALDO_FINAL < 0 THEN
		 V_SIGNO_SALDO_FINAL := '+';
	  ELSE
		 V_SIGNO_SALDO_FINAL := '-';
	  END IF; 

	  IF P_ECP_TIPO_INFORME = 'DC02' THEN
		 CODIGO_SAP := 'DC01';
	  END IF;

	  IF P_ECP_TIPO_INFORME = 'DC03' THEN 

       V_TOTAL_D_C := V_TOTAL_DEBITOS + V_TOTAL_CREDITOS; 

       IF V_TOTAL_D_C < 0 THEN 
          V_SIGNO := '-';
       ELSE 
          V_SIGNO := '+';
       END IF; 

	     V_LINEA :=  '51'||V_SEPARADOR||                                                                                         -- 1.Código SAP Siempre 51
                    '0550000860079174'||V_SEPARADOR||                                                                          -- 2.Codigo especial siempre '0550000860079174'                 
                    V_NUMERO_EXTRACTO||V_SEPARADOR||                                                                           -- 3.Consecutivo del envío
                    TO_CHAR(P_FECHA_PROCESO_INI,'dd.mm.yy')||V_SEPARADOR||                                                     -- 4.Fecha del envío
                    'COP'||V_SEPARADOR||                                                                                       -- 5.Moneda
                    '+'||TRIM(TO_CHAR(0,'999999999999999990'))||V_SEPARADOR||                                                  -- 6.Saldo inicial siempre 0
						        '-'||TRIM(TO_CHAR(0,'999999999999999990'))||V_SEPARADOR||                                                  -- 7.Total debitos
						        V_SIGNO||TRIM(TO_CHAR(ABS(V_TOTAL_D_C),'999999999999999990'))||V_SEPARADOR||                               -- 8.Total creditos
						        V_SIGNO||TRIM(TO_CHAR(ABS(V_TOTAL_D_C),'999999999999999990'))||V_SEPARADOR||                               -- 9. Valor duplicado de punto 8 -- Anterior --Total creditos--'+0.00'||V_SEPARADOR|| -- 9.Saldo final TD-TC
						        TRIM(TO_CHAR(V_TOTAL_LINEAS,'99999'))||V_SEPARADOR||																		                  -- 10. Movimientos del detalle	             
                    V_SEPARADOR||                                                                                              -- 11. no usado
                    V_SEPARADOR||                                                                                              -- 12. no usado
                    V_SEPARADOR||                                                                                              -- 13. no usado
                    V_SEPARADOR||                                                                                              -- 14. no usado
                    V_SEPARADOR||                                                                                              -- 15. no usado
                    V_SEPARADOR||                                                                                              -- 16. no usado
                    V_SEPARADOR                                                                                                -- 17. no usado
                    ;  				  
	  ELSE 

        IF V_TERPEL = 'S' THEN 
          CODIGO_SAP := '026';
          V_APORTE_TERPEL := TRIM(V_PER_NUM_IDEN)||V_NUM_CUENTA||V_APORTE;
        ELSE 
          V_APORTE_TERPEL := TRIM(V_PER_NUM_IDEN);
        END IF;



        V_LINEA :=     RTRIM(CODIGO_SAP)||V_SEPARADOR||                                                                           -- 1.Código SAP DC01
                  V_APORTE_TERPEL||V_SEPARADOR||                                                                             -- 2.Nit del cliente                 
                  V_NUMERO_EXTRACTO||V_SEPARADOR||                                                                           -- 3.Consecutivo del envío
                  TO_CHAR(P_FECHA_PROCESO_INI,'dd.mm.yy')||V_SEPARADOR||                                                     -- 4.Fecha del envío
                  'COP'||V_SEPARADOR||                                                                                       -- 5.Moneda
                  '+'||TRIM(TO_CHAR(0,'999999999999999990.00'))||V_SEPARADOR||                                               -- 6.Saldo inicial siempre 0
                  '-'||TRIM(TO_CHAR(ABS(V_TOTAL_DEBITOS),'999999999999999990.00'))||V_SEPARADOR||                            -- 7.Total debitos
                  '+'||TRIM(TO_CHAR(ABS(V_TOTAL_CREDITOS),'999999999999999990.00'))||V_SEPARADOR||                           -- 8.Total creditos
                  '+0.00'||V_SEPARADOR||                                                                                     -- 9.Saldo final TD-TC
                  '01'||V_SEPARADOR||                                                                                        -- 10.Codigo tipo cuentaC                 
                  V_SEPARADOR||                                                                                              -- 11. no usado
                  V_SEPARADOR||                                                                                              -- 12. no usado
                  V_SEPARADOR||                                                                                              -- 13. no usado
                  V_SEPARADOR||                                                                                              -- 14. no usado
                  V_SEPARADOR||                                                                                              -- 15. no usado
                  V_SEPARADOR||                                                                                              -- 16. no usado
                  V_SEPARADOR||                                                                                              -- 17. no usado
                  TRIM(TO_CHAR(V_TOTAL_LINEAS,'99999'));                                                                     -- 18. Saldo inicial cuenta

	  END IF;

	  P_MAIL.BEGIN_ATTACHMENT( CONN         => CONN,
										MIME_TYPE    => V_ARCHIVO_CABECERA||'/txt',
										INLINE       => true,
										FILENAME     => V_ARCHIVO_CABECERA||'.txt',
										TRANSFER_ENC => 'text');

    IF (P_FECHA_PROCESO_FIN - P_FECHA_PROCESO_INI) > 10 THEN
      V_NOMBRE_ARCHIVO := TO_CHAR(P_CONV_CONSECUTIVO)
								 || '_' || TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')
								 || '_' || TO_CHAR(SYSDATE,'HH24')
								 || '00'|| P_TIPO_ENVIO || 'CM.txt';
    ELSE
      V_NOMBRE_ARCHIVO := TO_CHAR(P_CONV_CONSECUTIVO)
								 || '_' || TO_CHAR(P_FECHA_PROCESO_INI,'YYYYMMDD')
								 || '_' || TO_CHAR(SYSDATE,'HH24')
								 || '00'|| P_TIPO_ENVIO || 'C.txt';  
    END IF;                    


    EXTRACTO_ARCHIVO := UTL_FILE.FOPEN('LOG_DIR', V_NOMBRE_ARCHIVO, 'W');	  

	  V_LINEA := TRIM(REPLACE(REPLACE(REPLACE(V_LINEA,CHR(10),'  ')  ,CHR(13),'  ')  ,'   ',' '));


	  --P_MAIL.WRITE_MB_TEXT(CONN,V_LINEA);                   
	  UTL_FILE.PUT_LINE(EXTRACTO_ARCHIVO,V_LINEA);

	  --P_MAIL.END_ATTACHMENT( CONN => CONN );
	  UTL_SMTP.WRITE_DATA( CONN, V_LINEA ); 

	  UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);  

    ------------------------------------------------------------------------------
    --COPIAR EL ARCHIVO GENERADO AL FTP CUANDO EL CLIENTE LO TENGA CONFIGURADO
    ------------------------------------------------------------------------------

    IF P_ENVIO_FTP = 'S' THEN
      V_PREFIJO_ARCHIVO := V_NOMBRE_ARCHIVO;
      IF (P_CONV_CONSECUTIVO = 100012) THEN
        V_PREFIJO_ARCHIVO := 'KC' || TO_CHAR(P_FECHA_PROCESO_INI, 'DDMM') ||V_PER_NUM_IDEN;
      END IF;
      UTL_FILE.FCOPY('LOG_DIR',V_NOMBRE_ARCHIVO,'FTPMULTICASH',V_PREFIJO_ARCHIVO);
    END IF;


  END IF;

    IF P_ENVIO_MAIL = 'S' THEN
      P_MAIL.END_MAIL( CONN => CONN );
    END IF;
  ----------------------------------------------
  --Actualizar el consecutivo del convenio/tipo
  ----------------------------------------------
  IF P_REPROCESO = 'N' THEN
      IF P_ECP_TIPO_INFORME = 'AB01' THEN  

        UPDATE CONTROL_EXTRACTOS_CUENTAS
         SET CXC_CONSECUTIVO      = 0
         WHERE CXC_CONV_CONSECUTIVO = P_CONV_CONSECUTIVO
           AND CXC_TIPO_INFORME     = P_ECP_TIPO_INFORME;        

      COMMIT;


      ELSE  
        UPDATE CONTROL_EXTRACTOS_CUENTAS
         SET CXC_CONSECUTIVO      = V_NUMERO_EXTRACTO
         WHERE CXC_CONV_CONSECUTIVO = P_CONV_CONSECUTIVO
         AND CXC_TIPO_INFORME     = P_ECP_TIPO_INFORME;  

      COMMIT;  



      END IF;
    END IF;  
  END IF;

  P_NUM_FIN := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_EXTRACTO_PRUEBAS.MAIL_EXTRACTO_CUENTAS','FIN');

  COMMIT;

  ----------------------------------------------
  --Control de errores
  ----------------------------------------------

  EXCEPTION
      WHEN ERROR_EXTRACTO THEN
        p_errores :='No existe consecutivo del envío';
        UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);                   
        ROLLBACK;
        RETURN;
      WHEN ERROR_INFORME THEN
        p_errores :='No se ha definido tipo de informe para el convenio';
        UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);                   
        ROLLBACK;
        RETURN;       
      WHEN OTHERS THEN
         p_errores :='Error en generacion plano Convenio: '||P_CONV_CONSECUTIVO||' '||SQLERRM;
         UTL_FILE.FCLOSE(EXTRACTO_ARCHIVO);                    
         ROLLBACK;
         RETURN;

END MAIL_EXTRACTO_CUENTAS;


END P_EXTRACTO_PRUEBAS;

/

  GRANT EXECUTE ON "PROD"."P_EXTRACTO_PRUEBAS" TO "COE_RECURSOS";
