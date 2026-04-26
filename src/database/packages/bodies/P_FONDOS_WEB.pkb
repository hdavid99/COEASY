--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_FONDOS_WEB
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_FONDOS_WEB" IS
PROCEDURE HABILITAR_FONDO IS
   FECHA  DATE;

   CURSOR C_FONDOS IS
      SELECT PFO1.PFO_FON_CODIGO
            ,PFO1.PFO_RANGO_MIN_NUMBER
      FROM   PARAMETROS_FONDOS PFO1
      WHERE  PFO1.PFO_PAR_CODIGO = 25
      AND    PFO1.PFO_FECHA = (SELECT MAX(PFO2.PFO_FECHA)
                  FROM   PARAMETROS_FONDOS PFO2
                  WHERE  PFO2.PFO_FON_CODIGO = PFO1.PFO_FON_CODIGO
                  AND    PFO2.PFO_PAR_CODIGO = 25);
   PFO1   C_FONDOS%ROWTYPE;

   CURSOR C_DIAS IS
      SELECT 'X'
      FROM   DIAS_NO_HABILES
      WHERE  TRUNC(DNH_FECHA) = TRUNC(FECHA);
   COND   VARCHAR2(1);

   CURSOR C_CONFIRMACION IS
      SELECT CFD_DISTRIBUCION
            ,CFD_CAPITALIZACION
      FROM   CONFIRMACION_FONDOS_DIA
      WHERE  CFD_FON_CODIGO = PFO1.PFO_FON_CODIGO
      AND    CFD_FECHA >= TRUNC(FECHA - 1)
      AND    CFD_FECHA < TRUNC(FECHA);
   CFD1   C_CONFIRMACION%ROWTYPE;


BEGIN
   SELECT SYSDATE INTO FECHA FROM DUAL;

   OPEN C_FONDOS;
   FETCH C_FONDOS INTO PFO1;

   WHILE C_FONDOS%FOUND LOOP
      COND := NULL;
      IF PFO1.PFO_RANGO_MIN_NUMBER = 2 THEN
         OPEN C_DIAS;
         FETCH C_DIAS INTO COND;
         CLOSE C_DIAS;

         COND := NVL(COND,' ');

         IF TO_CHAR(FECHA,'D') NOT IN ('7','1') AND COND != 'X' THEN
            OPEN C_CONFIRMACION;
            FETCH C_CONFIRMACION INTO CFD1;
            IF C_CONFIRMACION%FOUND THEN
               IF TO_CHAR(FECHA,'MON') != TO_CHAR(FECHA - 1,'MON') THEN
                  IF CFD1.CFD_DISTRIBUCION = 'S' AND
                     CFD1.CFD_CAPITALIZACION = 'S' THEN
                     UPDATE PARAMETROS_FONDOS
                     SET PFO_RANGO_MIN_NUMBER = 0
                        ,PFO_RANGO_MAX_DATE = SYSDATE
                     WHERE PFO_FON_CODIGO = PFO1.PFO_FON_CODIGO
                     AND   PFO_PAR_CODIGO = 25;
                  END IF;
               ELSE
                  IF CFD1.CFD_DISTRIBUCION = 'S' THEN
                     UPDATE PARAMETROS_FONDOS
                     SET PFO_RANGO_MIN_NUMBER = 0
                        ,PFO_RANGO_MAX_DATE = SYSDATE
                     WHERE PFO_FON_CODIGO = PFO1.PFO_FON_CODIGO
                     AND   PFO_PAR_CODIGO = 25;
                  END IF;
               END IF;
            END IF;
            CLOSE C_CONFIRMACION;
         END IF;
      END IF;
      FETCH C_FONDOS INTO PFO1;
   END LOOP;
   CLOSE C_FONDOS;
END;

PROCEDURE FINCOLOCACION
(FONDO VARCHAR
)
IS


cursor C_FONDOS is
select
       FON_CODIGO
      ,FON_JOB
from   FONDOS
WHERE  FON_TIPO = 'A'
;
cursor C_HORA (xFONDO VARCHAR2, xPARAMETRO NUMBER) is
select
       PFO_FON_CODIGO      ,
       PFO_RANGO_MIN_CHAR  ,
       PFO_RANGO_MIN_NUMBER,
       PFO_RANGO_MIN_DATE  ,
       PFO_RANGO_MAX_CHAR
from   PARAMETROS_FONDOS
where  PFO_FON_CODIGO         = xFONDO
and    PFO_PAR_CODIGO         = xPARAMETRO
and    PFO_FECHA  = (select max(PFO_FECHA)
                     from   PARAMETROS_FONDOS
                     where  PFO_FON_CODIGO   = xFONDO
                     and    PFO_PAR_CODIGO   = xPARAMETRO)
;

cursor C_HABIL(DINOHA DATE) IS
select 'x'
from   DIAS_NO_HABILES
where  trunc(DNH_FECHA) = trunc(DINOHA)
;
x            number;
xIndicador   number(1);
xFecha_final date;
xFecha_sigui date;
xaammdd      date;
begin
    select sysdate into XAAMMDD from dual;
    xIndicador := 0;
    /* Actualiza Fondos abiertos */
    For R_FONDOS in C_FONDOS loop
        For R_HORA in C_HORA (R_FONDOS.FON_CODIGO,25) loop
            xIndicador := R_HORA.PFO_RANGO_MIN_NUMBER;
        End loop;
        If xIndicador = 0 then
           xFecha_final := NULL;
           For R_HORA in C_HORA (R_FONDOS.FON_CODIGO,9) loop
               xFecha_final := to_date(to_char(trunc(sysdate),'DD-MON-YYYY')||' '||replace(R_HORA.PFO_RANGO_MAX_CHAR,':',''), 'DD-MM-YYYY HH24:MISS');
           End loop;
           iF xFecha_final is not NULL then
              while to_char(XAAMMDD,'DD-MON-YYYY HH24:MISS') < to_char(xFecha_final,'DD-MON-YYYY HH24:MISS') loop
                    select sysdate into XAAMMDD from dual;
              end loop;
              xFecha_sigui := xFecha_final + 1;
              while TRUE loop
                  For R_HABIL in C_HABIL (xFecha_sigui) loop
                      xFecha_sigui := xFecha_sigui + 1;
                  end loop;
                  If to_char(xFecha_sigui,'D') in ('7','1') then
                      xFecha_sigui := xFecha_sigui + 1;
                  else
                     exit;
                  end if;
              end loop;
              If to_char(xFecha_final,'DD-MON-YYYY HH24:MISS') <=
                 to_char(sysdate,'DD-MON-YYYY HH24:MISS')      then
                 update PARAMETROS_FONDOS
                 set    PFO_RANGO_MIN_NUMBER = 1
                       ,PFO_RANGO_MIN_DATE   = to_date(to_char(trunc(xFecha_sigui),'DD-MON-YYYY')||' '||'00:01','DD-MON-YYYY HH24:MISS')
                 where  PFO_FON_CODIGO       = R_FONDOS.FON_CODIGO
                 and    PFO_PAR_CODIGO       = 25
                 ;
              end if;
           end if;
        End if;
    End loop;
-- Commit;
END FINCOLOCACION;


PROCEDURE CREAJOB
(FONDO VARCHAR
)
IS

cursor C_FONDOS is
select
       FON_CODIGO
      ,FON_JOB
from   FONDOS
WHERE  FON_TIPO = 'A'
AND    FON_CODIGO = FONDO
;
cursor C_HORA (xFONDO VARCHAR2) is
select
       PFO_FON_CODIGO                  ,
       PFO_RANGO_MAX_CHAR
from   PARAMETROS_FONDOS
where  PFO_FON_CODIGO         = xFONDO
and    PFO_PAR_CODIGO         = 9
and    PFO_FECHA  = (select max(PFO_FECHA)
                     from   PARAMETROS_FONDOS
                     where  PFO_FON_CODIGO   = xFONDO
                     and    PFO_PAR_CODIGO   = 9)
;
x            number;
xFecha_start date;
begin
    /* Elimina los Jobs Existentes Fondos */
    For R_FONDOS in C_FONDOS loop
        If R_FONDOS.FON_JOB > 0 then
            DBMS_JOB.REMOVE(R_FONDOS.FON_JOB);
            update FONDOS
            set    FON_JOB = NULL
            where  FON_CODIGO = R_FONDOS.FON_CODIGO
            ;
        End If;
    End loop;
    /* Crea los Jobs xa Fondos abiertos */
    For R_FONDOS in C_FONDOS loop
        For R_HORA in C_HORA (R_FONDOS.FON_CODIGO) loop
            xFecha_start := to_date(to_char(trunc(sysdate))||' '||replace(R_HORA.PFO_RANGO_MAX_CHAR,':',''), 'DD-MM-YYYY HH24:MISS');
            DBMS_JOB.SUBMIT(x,'P_FONDOS_WEB.FINCOLOCACION('||R_FONDOS.FON_CODIGO||');',xFecha_start,'sysdate+1');
            update FONDOS
            set    FON_JOB = x
            where  FON_CODIGO = R_FONDOS.FON_CODIGO
            ;
        End loop;
    End loop;
--Commit;
END CREAJOB;

PROCEDURE RENTABILIDAD_FONDOS
   (P_FECHA   DATE) IS
   CURSOR C_FONDOS IS
      SELECT VFO_FECHA_VALORIZACION
            ,VFO_FON_CODIGO
      FROM   VALORIZACIONES_FONDO
      WHERE  VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
      AND    VFO_FECHA_VALORIZACION < TRUNC(P_FECHA + 1);
   VFO1   C_FONDOS%ROWTYPE;

   R_MES  NUMBER;
   R_ANO  NUMBER;
BEGIN
   OPEN C_FONDOS;
   FETCH C_FONDOS INTO VFO1;
   WHILE C_FONDOS%FOUND LOOP
      R_MES := P_FONDOS_WEB.RENTABILIDAD(VFO1.VFO_FECHA_VALORIZACION,VFO1.VFO_FON_CODIGO,30);
      --R_ANO := P_FONDOS_WEB.RENTABILIDAD(VFO1.VFO_FECHA_VALORIZACION,VFO1.VFO_FON_CODIGO,365);
      -- se modifica el de los ultimos 365 dias por el de 7 dias
      R_ANO := P_FONDOS_WEB.RENTABILIDAD(VFO1.VFO_FECHA_VALORIZACION,VFO1.VFO_FON_CODIGO,7);

      -- Si la rentabilidad del fondo no se puede actualizar a causa de que el valor de las variables
      -- R_ANO, R_MES son superiores a la presición de la tabla valorizaciones fondo se dejara la
      -- rentabilidad en CERO.

      BEGIN
         UPDATE VALORIZACIONES_FONDO
         SET    VFO_RENTABILIDAD_ANUAL = R_ANO
               ,VFO_RENTABILIDAD_MENSUAL = R_MES
         WHERE  VFO_FECHA_VALORIZACION = VFO1.VFO_FECHA_VALORIZACION
         AND    VFO_FON_CODIGO = VFO1.VFO_FON_CODIGO;
      EXCEPTION
         WHEN OTHERS THEN
            UPDATE VALORIZACIONES_FONDO
            SET    VFO_RENTABILIDAD_ANUAL = 0
                  ,VFO_RENTABILIDAD_MENSUAL = 0
            WHERE  VFO_FECHA_VALORIZACION = VFO1.VFO_FECHA_VALORIZACION
            AND    VFO_FON_CODIGO = VFO1.VFO_FON_CODIGO;
      END;
      FETCH C_FONDOS INTO VFO1;
   END LOOP;
   CLOSE C_FONDOS;
   COMMIT;
END RENTABILIDAD_FONDOS;

FUNCTION RENTABILIDAD
 (P_FECHA      DATE
 ,P_FON_CODIGO VARCHAR2
 ,P_DIAS       NUMBER) RETURN NUMBER IS

   CURSOR C_FONDO IS
      SELECT FON_BMO_MNEMONICO
      FROM   FONDOS
      WHERE  FON_CODIGO = P_FON_CODIGO;
   FON1   C_FONDO%ROWTYPE;

   CURSOR C_VALOR(FECHA DATE) IS
      SELECT VFO_VALOR
            ,VFO_NUMERO_UNIDADES
      FROM   VALORIZACIONES_FONDO
      WHERE  TRUNC(VFO_FECHA_VALORIZACION) = TRUNC(FECHA)
      AND    VFO_FON_CODIGO = P_FON_CODIGO;

   CURSOR C_BASE(FECHA  DATE) IS
      SELECT CBM_VALOR
      FROM   COTIZACIONES_BASE_MONETARIAS
      WHERE  CBM_BMO_MNEMONICO = FON1.FON_BMO_MNEMONICO
      AND    CBM_FECHA >= TRUNC(FECHA)
      AND    CBM_FECHA < TRUNC(FECHA + 1);

   FECHA2       DATE;
   BASE         NUMBER;
   EXPO         NUMBER;
   VAL_UNI      NUMBER;
   DATO         NUMBER;
   VAL_FIN      NUMBER;
   COTI_INI     NUMBER;
   COTI_FIN     NUMBER;
   NUM_UNID_FIN NUMBER;
   NUM_UNID_INI NUMBER;
BEGIN
   OPEN C_FONDO;
   FETCH C_FONDO INTO FON1;
   CLOSE C_FONDO;

   FECHA2 := TRUNC(P_FECHA)- P_DIAS;

   OPEN C_VALOR(P_FECHA);
   FETCH C_VALOR INTO VAL_FIN
                     ,NUM_UNID_FIN;
   CLOSE C_VALOR;

   IF FON1.FON_BMO_MNEMONICO = 'PESOS' THEN

      OPEN C_VALOR(FECHA2);
      FETCH C_VALOR INTO VAL_UNI
                        ,NUM_UNID_INI;

      IF NVL(VAL_UNI,0) != 0 THEN
         IF C_VALOR%FOUND THEN
            BASE :=  VAL_FIN / VAL_UNI;
            EXPO :=  365 / P_DIAS;
            SELECT POWER(BASE,EXPO) INTO DATO FROM DUAL;
         ELSE
            RETURN 0;
         END IF;
         CLOSE C_VALOR;
         RETURN((DATO-1)*100);
      ELSE
         RETURN 0;
      END IF;
   ELSE
      OPEN C_BASE(P_FECHA);
      FETCH C_BASE INTO COTI_FIN;
      CLOSE C_BASE;
      IF NVL(COTI_FIN,0) = 0 THEN
         RETURN 0;
      END IF;

      OPEN C_BASE(FECHA2);
      FETCH C_BASE INTO COTI_INI;
      CLOSE C_BASE;
      IF NVL(COTI_FIN,0) = 0 THEN
         RETURN 0;
      END IF;

      VAL_FIN := VAL_FIN * NUM_UNID_FIN * COTI_FIN;

      OPEN C_VALOR(FECHA2);
      FETCH C_VALOR INTO VAL_UNI
                        ,NUM_UNID_INI;
      IF C_VALOR%FOUND THEN
           /* Es correcto que este NUM_UNID_FIN */
           VAL_UNI := VAL_UNI * NUM_UNID_FIN * COTI_INI;
         BASE :=  VAL_FIN / VAL_UNI;
         EXPO  := 365 / P_DIAS;
         SELECT POWER(BASE,EXPO) INTO DATO FROM DUAL;
      ELSE
         RETURN 0;
      END IF;
      CLOSE C_VALOR;
      RETURN ((DATO - 1) * 100);
   END IF;
END RENTABILIDAD;

/*  Funcion que retorna la fecha de cierre de un fondo */
FUNCTION F_OBTENER_FECHA_CIERRE_FONDO(P_FON_CODIGO VARCHAR2) RETURN DATE IS
  FECHA_CIERRE DATE;
BEGIN
  SELECT MAX(vfo_fecha_valorizacion) INTO FECHA_CIERRE
  FROM  valorizaciones_fondo
  WHERE VFO_fon_codigo = P_FON_CODIGO;

  RETURN FECHA_CIERRE;
END F_OBTENER_FECHA_CIERRE_FONDO;

/* Retorna valor del fondo a la fecha*/
FUNCTION F_VALOR_FONDO(P_FONDO FONDOS.FON_CODIGO%TYPE
                      ,P_FECHA DATE) RETURN VALORIZACIONES_FONDO.VFO_VALOR%TYPE IS
  CURSOR VALOR_FONDO IS
    SELECT VFO_VALOR
    FROM  VALORIZACIONES_FONDO VFO1
    WHERE VFO_FON_CODIGO = P_FONDO
    AND VFO_FECHA_VALORIZACION = (SELECT MAX(VFO_FECHA_VALORIZACION)
                                  FROM VALORIZACIONES_FONDO VFO2
                                  WHERE VFO2.VFO_FON_CODIGO = P_FONDO
                                  AND VFO2.VFO_FECHA_VALORIZACION <= TRUNC(P_FECHA - 1));

  V_VALOR VALORIZACIONES_FONDO.VFO_VALOR%TYPE;

BEGIN
  OPEN VALOR_FONDO;
  FETCH VALOR_FONDO INTO V_VALOR;
    IF VALOR_FONDO%FOUND THEN
      RETURN(V_VALOR);
    ELSE
      RETURN(0);
    END IF;
  CLOSE VALOR_FONDO;
END;

PROCEDURE ObtenerCarterasColectivas(P_CODIGO IN VARCHAR2,
                        P_RAZON_SOCIAL IN VARCHAR2,
                        P_TIPO IN VARCHAR2,
                        P_TIPO_ADMINISTRACION IN VARCHAR2,
                        io_cursor OUT O_CURSOR)
IS
    v_select VARCHAR2(4000);
    v_from VARCHAR2(4000);
    v_where VARCHAR2(4000);
	v_cant  NUMBER := 0;
BEGIN
    v_select := 'SELECT FON_CODIGO,FON_RAZON_SOCIAL,FON_BMO_MNEMONICO,FON_MNEMONICO,FON_TIPO,FON_TIPO_ADMINISTRACION,FON_CAPITAL_PRIVADO ';
    v_from := 'FROM FONDOS ';
    v_where := 'WHERE FON_ESTADO = ''A'' ';

    IF LENGTH(P_CODIGO) > 0 THEN
        v_where := v_where || ' AND FON_CODIGO=''' || P_CODIGO || ''' ';
    END IF;

    IF LENGTH(P_RAZON_SOCIAL) > 0 THEN
        v_where := v_where || ' AND FON_RAZON_SOCIAL LIKE ''%' || P_RAZON_SOCIAL || '%'' ';
    END IF;

    IF LENGTH(P_TIPO) > 0 THEN
        v_where := v_where || ' AND FON_TIPO=''' || P_TIPO || ''' ';
    END IF;

    IF LENGTH(P_TIPO_ADMINISTRACION) > 0 THEN
        v_where := v_where || ' AND FON_TIPO_ADMINISTRACION=''' || P_TIPO_ADMINISTRACION || ''' ';
    END IF;

	--
    IF TO_CHAR(TRUNC(SYSDATE), 'DD') = '01' AND (TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) BETWEEN 5 AND 7 ) THEN
      V_WHERE := V_WHERE ||' UNION ';

      V_WHERE := V_WHERE ||'SELECT FON_CODIGO,FON_RAZON_SOCIAL,FON_BMO_MNEMONICO,FON_MNEMONICO,FON_TIPO,FON_TIPO_ADMINISTRACION,FON_CAPITAL_PRIVADO ';

      V_WHERE := V_WHERE ||'FROM FONDOS F ';

      V_WHERE := V_WHERE ||'WHERE F.FON_ESTADO = ''I'' ';

      IF LENGTH(P_CODIGO) > 0 THEN
        V_WHERE := V_WHERE || ' AND F.FON_CODIGO=''' || P_CODIGO || ''' ';
      END IF;

      IF LENGTH(P_RAZON_SOCIAL) > 0 THEN
        V_WHERE := V_WHERE || ' AND F.FON_RAZON_SOCIAL LIKE ''%' || P_RAZON_SOCIAL || '%'' ';
      END IF;

      IF LENGTH(P_TIPO) > 0 THEN
        V_WHERE := V_WHERE || ' AND F.FON_TIPO=''' || P_TIPO || ''' ';
      END IF;

      IF LENGTH(P_TIPO_ADMINISTRACION) > 0 THEN
        V_WHERE := V_WHERE || ' AND F.FON_TIPO_ADMINISTRACION=''' || P_TIPO_ADMINISTRACION || ''' ';
      END IF;

      V_WHERE := V_WHERE ||' AND EXISTS (SELECT ''X''
                                          FROM   VALORIZACIONES_FONDO
                                          WHERE  VFO_FON_CODIGO = F.FON_CODIGO
                                          AND    VFO_FECHA_VALORIZACION >= TRUNC(TRUNC(SYSDATE, ''MM'' )-1, ''MM'')
                                          AND    VFO_FECHA_VALORIZACION < TRUNC(SYSDATE, ''MM'' ))';

      V_WHERE := V_WHERE ||' AND    EXISTS (SELECT ''X''
                                            FROM   RENTABILIDADES_Y_VOLATILIDADES
                                            WHERE  RYV_FON_CODIGO = F.FON_CODIGO
                                            AND    RYV_FECHA >= TRUNC(TRUNC(SYSDATE, ''MM'' )-1, ''MM'')
                                            AND    RYV_FECHA < TRUNC(SYSDATE, ''MM'' )) ';

    END IF;
    --

    v_where := v_where || ' ORDER BY FON_CODIGO ';

	SELECT COUNT(1)
    INTO V_CANT
    FROM EJECUCION_PROCESOS_NOCTURNOS E
    WHERE E.EPN_NOMBRE_PROCESO = 'P_PROCESOS_NOCTURNOS.PR_ACT_RENTAB_VOLATIL'
    AND E.EPN_FECHA_EJECUCION >= TRUNC(SYSDATE)
    AND E.EPN_FECHA_EJECUCION < TRUNC(SYSDATE) + 1;

    IF V_CANT < 2 AND P_CODIGO IS NULL AND (TO_CHAR(TRUNC(SYSDATE), 'DD') = '01' AND (TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) BETWEEN 5 AND 7 )) THEN

      V_SELECT := 'SELECT FON_CODIGO,FON_RAZON_SOCIAL,FON_BMO_MNEMONICO,FON_MNEMONICO,FON_TIPO,FON_TIPO_ADMINISTRACION,FON_CAPITAL_PRIVADO ';
      V_FROM := 'FROM FONDOS ';
      V_WHERE := 'WHERE 1 = 0';

      --
      DECLARE

        V_CLI_PER_TID_CODIGO VARCHAR2(32);
        V_CLI_PER_NUM_IDEN   VARCHAR2(64);
        V_MAILLST            VARCHAR2(4000);

        CURSOR C_USUARIO IS
          SELECT PER_NUM_IDEN
                ,PER_TID_CODIGO
          FROM   PERSONAS
          WHERE  PER_NOMBRE_USUARIO = (SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') FROM DUAL);
        R_USUARIO C_USUARIO%ROWTYPE;

        CURSOR C_EMAIL IS
          SELECT C.CON_VALOR_CHAR
          FROM   CONSTANTES C
          WHERE  C.CON_MNEMONICO = 'NGE';
        R_EMAIL C_EMAIL%ROWTYPE;

        V_ASUNTO VARCHAR2(64) := 'ALERTA: ERROR EN LA GENERACIÓN DE EXTRACTOS';
        V_CUERPO VARCHAR2(2048) := 'Estimados,' || '<br><br>' || '</tr>' ||
                                   TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI')||' No se han podido generar los extractos del mes anterior, debido a la no generación de las rentabilidades del proceso nocturno "P_PROCESOS_NOCTURNOS.PR_ACT_RENTAB_VOLATIL".' ||
                                   '<br><br>' || '</tr>' ||
                                   'Estamos trabajando para agilizar este proceso.' || '<br><br>' ||
                                   '</tr>' || 'Cordialmente,' || '<br><br>' || '</tr>' ||
                                   'TI Davivienda Corredores' || '<br>' || '</tr>';
        SALIDA   VARCHAR2(2048);
      BEGIN

        OPEN C_USUARIO;
        FETCH C_USUARIO
          INTO R_USUARIO;
        IF C_USUARIO%FOUND THEN
          V_CLI_PER_TID_CODIGO := R_USUARIO.PER_TID_CODIGO;
          V_CLI_PER_NUM_IDEN   := R_USUARIO.PER_NUM_IDEN;
        ELSE
          V_CLI_PER_TID_CODIGO := 'CC';
          V_CLI_PER_NUM_IDEN   := '0';
        END IF;
        CLOSE C_USUARIO;

        OPEN C_EMAIL;
        FETCH C_EMAIL
          INTO R_EMAIL;
        IF C_EMAIL%NOTFOUND THEN
          V_MAILLST :=  'canalesalternos@corredores.com,servicioalcliente@corredores.com,stecnico@corredores.com';
        ELSE
          V_MAILLST := R_EMAIL.CON_VALOR_CHAR;
        END IF;
        CLOSE C_EMAIL;

        FOR POS IN (SELECT TRIM(REGEXP_SUBSTR(V_MAILLST, '[^,]+', 1, LEVEL)) MAIL
                    FROM   DUAL
                    CONNECT BY LEVEL <= REGEXP_COUNT(V_MAILLST, ',') + 1) LOOP
          P_NOTIFICACIONES_MAIL.PR_ENVIO_MAIL(P_CLI_PER_TID_CODIGO => V_CLI_PER_TID_CODIGO,
                                              P_CLI_PER_NUM_IDEN   => V_CLI_PER_NUM_IDEN,
                                              P_SERVICIO           => 'ERROR GENERACION DE EXTRACTOS',
                                              P_DE                 => 'procesosnocturnos@corredores.com',
                                              P_PARA               => POS.MAIL,
                                              P_ASUNTO             => V_ASUNTO,
                                              P_MENSAJE            => V_CUERPO,
                                              P_CLOB               => SALIDA,
                                              P_MENSAJE_CLOB       => NULL,
                                              P_ADJUNTO            => NULL);
        END LOOP;
      END;
      --
    END IF;

    OPEN io_cursor FOR (v_select || v_from || v_where);
END ObtenerCarterasColectivas;

PROCEDURE ObtenerCuentasCarteras(P_TID_CODIGO IN VARCHAR2,
                        P_NUM_IDEN IN VARCHAR2,
                        P_NUMERO_CUENTA_CORREDORES IN NUMBER,
                        P_FON_CODIGO IN VARCHAR2,
                        P_ESTADO IN VARCHAR2,
                        P_ENVIAR_EXTRACTO IN VARCHAR2,
                        io_cursor OUT O_CURSOR)
IS
    v_select VARCHAR2(4000);
    v_from VARCHAR2(4000);
    v_where VARCHAR2(4000);
BEGIN
    v_select := 'SELECT CFO_FON_CODIGO, CFO_CCC_CLI_PER_NUM_IDEN, CFO_CCC_CLI_PER_TID_CODIGO,';
    V_SELECT := V_SELECT || ' CFO_CCC_NUMERO_CUENTA, CFO_CODIGO, DECODE(CFO_ESTADO,''A'',1,0) AS CFO_ESTADO, ';
    v_select := v_select || ' FON_RAZON_SOCIAL, FON_MNEMONICO, CFO_ENVIAR_EXTRACTO AS CFO_PERIODO_EXTRACTO ';
    v_from := 'FROM CUENTAS_FONDOS ';
    v_from := v_from || 'INNER JOIN CLIENTES ON (CFO_CCC_CLI_PER_TID_CODIGO = CLI_PER_TID_CODIGO AND CFO_CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN) ';
    v_from := v_from || 'INNER JOIN FONDOS ON CFO_FON_CODIGO = FON_CODIGO ';
    --v_where := 'WHERE CLI_ECL_MNEMONICO=''ACC'' ';
    v_where := 'WHERE 1 = 1 ';

    IF LENGTH(P_TID_CODIGO) > 0 THEN
        v_where := v_where || ' AND CFO_CCC_CLI_PER_TID_CODIGO=''' || P_TID_CODIGO || ''' ';
    END IF;

    IF LENGTH(P_NUM_IDEN) > 0 THEN
        v_where := v_where || ' AND CFO_CCC_CLI_PER_NUM_IDEN=''' || P_NUM_IDEN || ''' ';
    END IF;

    IF LENGTH(P_NUMERO_CUENTA_CORREDORES) > 0 THEN
        v_where := v_where || ' AND CFO_CCC_NUMERO_CUENTA=' || P_NUMERO_CUENTA_CORREDORES || ' ';
    END IF;

    IF LENGTH(P_FON_CODIGO) > 0 THEN
        v_where := v_where || ' AND CFO_FON_CODIGO=''' || P_FON_CODIGO || ''' ';
    END IF;

    IF LENGTH(P_ESTADO) > 0 THEN
        v_where := v_where || ' AND CFO_ESTADO=''' || P_ESTADO || ''' ';
    END IF;

    IF LENGTH(P_ENVIAR_EXTRACTO) > 0 THEN
        v_where := v_where || ' AND CFO_ENVIAR_EXTRACTO=''' || P_ENVIAR_EXTRACTO || ''' ';
    END IF;

    OPEN io_cursor FOR (v_select || v_from || v_where);
END ObtenerCuentasCarteras;

PROCEDURE ObtenerMovCuentasCarteras(P_TID_CODIGO IN VARCHAR2,
                        P_NUM_IDEN IN VARCHAR2,
                        P_NUMERO_CUENTA_CORREDORES IN NUMBER,
                        P_FON_CODIGO IN VARCHAR2,
                        P_CFO_CODIGO IN NUMBER,
                        P_FECHA_INICIAL IN DATE,
                        P_FECHA_FINAL IN DATE,
                        io_cursor OUT O_CURSOR)
IS
    v_select VARCHAR2(4000);
    v_from VARCHAR2(4000);
    v_where VARCHAR2(4000);
BEGIN
    v_select := ' SELECT MCF_CFO_FON_CODIGO, MCF_CFO_CCC_CLI_PER_NUM_IDEN, MCF_CFO_CCC_CLI_PER_TID_CODIGO, MCF_CFO_CCC_NUMERO_CUENTA, MCF_CFO_CODIGO, MCF_TMF_MNEMONICO, ';
    v_select := v_select || ' MCF_SALDO_INVER, MCF_SALDO_CAPITAL,MCF_SALDO_RENDIMIENTOS_RF,MCF_SALDO_RENDIMIENTOS_RV,MCF_SALDO_RETEFUENTE,MCF_SALDO_INTERESES_PAGADOS,MCF_SALDO_UNIDADES,MCF_SALDO_DIVIDENDOS ';
    v_from := ' FROM MOVIMIENTOS_CUENTAS_FONDOS ';
    v_where := ' WHERE 1=1 ';

    IF LENGTH(P_TID_CODIGO) > 0 THEN
        v_where := v_where || ' AND MCF_CFO_CCC_CLI_PER_TID_CODIGO=''' || P_TID_CODIGO || ''' ';
    END IF;

    IF LENGTH(P_NUM_IDEN) > 0 THEN
        v_where := v_where || ' AND MCF_CFO_CCC_CLI_PER_NUM_IDEN=''' || P_NUM_IDEN || ''' ';
    END IF;

    IF P_NUMERO_CUENTA_CORREDORES <> -1 THEN
        v_where := v_where || ' AND MCF_CFO_CCC_NUMERO_CUENTA=' || P_NUMERO_CUENTA_CORREDORES || ' ';
    END IF;

    IF LENGTH(P_FON_CODIGO) > 0 THEN
        v_where := v_where || ' AND MCF_CFO_FON_CODIGO=''' || P_FON_CODIGO || ''' ';
    END IF;

    IF P_CFO_CODIGO <> -1 THEN
        v_where := v_where || ' AND MCF_CFO_CODIGO=' || P_CFO_CODIGO || ' ';
    END IF;

    IF P_FECHA_INICIAL IS NOT NULL THEN
        v_where := v_where || ' AND MCF_FECHA >= TO_DATE(''' || TO_CHAR(P_FECHA_INICIAL,'dd/MM/yyyy HH24:MI:SS') || ''',''dd/MM/yyyy HH24:MI:SS'') ';
    END IF;

    IF P_FECHA_FINAL IS NOT NULL THEN
        v_where := v_where || ' AND MCF_FECHA <= TO_DATE(''' || TO_CHAR(P_FECHA_FINAL,'dd/MM/yyyy HH24:MI:SS') || ''',''dd/MM/yyyy HH24:MI:SS'') ';
    END IF;

    OPEN io_cursor FOR (v_select || v_from || v_where);
END ObtenerMovCuentasCarteras;

PROCEDURE PrepararDatosExtractos(P_FECHA_DESDE IN DATE,
                                 P_FECHA_HASTA IN DATE,
                                 P_RETORNO OUT NUMBER)
IS
BEGIN
    -- ****************** ELIMINAR Y CREAR TABLA TEMPORAL "TMP_Q_TITULOS" ******************
    DECLARE V_VARIABLE NUMBER(10);
    BEGIN
      SELECT COUNT(*) INTO V_VARIABLE FROM ALL_TABLES
      WHERE TABLE_NAME = 'TMP_Q_TITULOS';

      IF V_VARIABLE = 1
      THEN
        EXECUTE IMMEDIATE 'DROP TABLE TMP_Q_TITULOS';
      END IF;

      IF V_VARIABLE >= 0
      THEN
        EXECUTE IMMEDIATE   'CREATE TABLE TMP_Q_TITULOS
                            (
                              FECHA_EXPEDICIÓN                    DATE         ,
                              TCF_TAF_GRP_FON_CODIGO              VARCHAR2(15) ,
                              TCF_TAF_GRP_MNEMONICO               VARCHAR2(5)  ,
                              TCF_TAF_MODALIDAD_TASA              VARCHAR2(1)  ,
                              NUMERO                              NUMBER(5)    ,
                              NÚMERO_DISPLAY                      VARCHAR2(40) ,
                              VALOR_NOMINAL                       NUMBER       ,
                              FECHA_SUSCRIPCIÓN                   DATE         ,
                              FECHA_VENCIMIENTO                   DATE         ,
                              TASA_FACIAL                         VARCHAR2(48) ,
                              MODALIDAD_PAGO_RENDIMIENTOS         VARCHAR2(1)  ,
                              PERIOCIDDA_TASA                     NUMBER(5)    ,
                              VIGENTE                             VARCHAR2(3)  ,
                              TET_CFO_CCC_CLI_PER_NUM_IDEN        VARCHAR2(15) ,
                              TET_CFO_CCC_CLI_PER_TID_CODIGO      VARCHAR2(3)  ,
                              TET_CFO_CCC_NUMERO_CUENTA           NUMBER(2)    ,
                              TET_CFO_FON_CODIGO                  VARCHAR2(15) ,
                              TET_CFO_CODIGO                      NUMBER
                            )';

        EXECUTE IMMEDIATE 'CREATE INDEX IDX_TMP_Q_TITULOS_CODIGO ON TMP_Q_TITULOS
                            (
                              TET_CFO_FON_CODIGO
                            )';
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_TMP_Q_TITULOS_CLI_PER ON TMP_Q_TITULOS
                            (
                              TET_CFO_CCC_CLI_PER_TID_CODIGO,
                              TET_CFO_CCC_CLI_PER_NUM_IDEN
                            )';
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_TMP_Q_TITULOS_FEC_EXP ON TMP_Q_TITULOS
                            (
                              FECHA_EXPEDICIÓN
                            )';

        /*EXECUTE IMMEDIATE 'CREATE PUBLIC SYNONYM tmp_q_titulos FOR tmp_q_titulos';

        EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON tmp_q_titulos TO AUD_AUDITORIA';
        EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON tmp_q_titulos TO VER_F_COMERCIAL';
        EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON tmp_q_titulos TO FON_SUPERUSUARIO';*/

      END IF;


      INSERT INTO TMP_Q_TITULOS (FECHA_EXPEDICIÓN,TCF_TAF_GRP_FON_CODIGO,TCF_TAF_GRP_MNEMONICO,TCF_TAF_MODALIDAD_TASA,NUMERO,NÚMERO_DISPLAY,VALOR_NOMINAL,FECHA_SUSCRIPCIÓN,FECHA_VENCIMIENTO,TASA_FACIAL,MODALIDAD_PAGO_RENDIMIENTOS,PERIOCIDDA_TASA,VIGENTE,TET_CFO_CCC_CLI_PER_NUM_IDEN,TET_CFO_CCC_CLI_PER_TID_CODIGO,TET_CFO_CCC_NUMERO_CUENTA,TET_CFO_FON_CODIGO,TET_CFO_CODIGO)
      SELECT
      TCF_FECHA_EXPEDICION Fecha_Expedición,
      TCF_TAF_GRP_FON_CODIGO,
      TCF_TAF_GRP_MNEMONICO,
      TCF_TAF_MODALIDAD_TASA,
      TCF_NUMERO_TITULO Numero,
      TO_CHAR(TCF_NUMERO_TITULO) Número_display,
      TCF_VALOR_NOMINAL Valor_Nominal,
      GRP_FECHA_SUSCRIPCION Fecha_Suscripción,
      GRP_FECHA_VENCIMIENTO Fecha_vencimiento,
      DECODE(NVL(TAF_TASA_NOMINAL, -1), -1, TAF_TRE_MNEMONICO || DECODE(NVL(TAF_PUNTOS_ADICIONALES, -100), -100, '', ' + ' || TO_CHAR(TAF_PUNTOS_ADICIONALES)), TO_CHAR(TAF_TASA_NOMINAL*100)||'%') Tasa_Facial,
      TAF_MODALIDAD_TASA Modalidad_Pago_Rendimientos,
      TAF_PERIODICIDAD_TASA Periocidda_tasa,
      TCF_ETF_MNEMONICO Vigente,
      TET_CFO_CCC_CLI_PER_NUM_IDEN,
      TET_CFO_CCC_CLI_PER_TID_CODIGO,
      TET_CFO_CCC_NUMERO_CUENTA,
      TET_CFO_FON_CODIGO,
      TET_CFO_CODIGO
      FROM
                      TENEDORES_TITULOS,
        TITULOS_CUENTA_FONDO,
        TITULOS_ACTIVO_FONDO,
        GRUPOS_PLANTILLAS,
        FONDOS
      WHERE
                      TCF_TAF_GRP_FON_CODIGO           = TET_TCF_TAF_GRP_FON_CODIGO
             AND TCF_TAF_GRP_MNEMONICO            =  TET_TCF_TAF_GRP_MNEMONICO
             AND TCF_TAF_MODALIDAD_TASA            = TET_TCF_TAF_MODALIDAD_TASA
            AND  TCF_NUMERO_TITULO                      = TET_TCF_NUMERO_TITULO
              AND TAF_GRP_MNEMONICO                    = GRP_MNEMONICO
             AND TAF_GRP_FON_CODIGO                   = GRP_FON_CODIGO
             AND TCF_TAF_MODALIDAD_TASA          = TAF_MODALIDAD_TASA
             AND TCF_TAF_GRP_MNEMONICO           = TAF_GRP_MNEMONICO
             AND TCF_TAF_GRP_FON_CODIGO          = TAF_GRP_FON_CODIGO
             AND TCF_ETF_MNEMONICO                    = 'VIG'
             AND TRUNC(TCF_FECHA_EXPEDICION) <= TRUNC(P_FECHA_DESDE)
            AND	FON_CODIGO =  GRP_FON_CODIGO
           --
      UNION
      SELECT	MAX(HTF_FECHA_EXPEDICION) Fecha_Expedición,
                      HTF_TCF_TAF_GRP_FON_CODIGO,
        HTF_TCF_TAF_GRP_MNEMONICO,
        HTF_TCF_TAF_MODALIDAD_TASA,
        HTF_TCF_NUMERO_TITULO Numero,
        TO_CHAR(HTF_TCF_NUMERO_TITULO) Número_display,
        HTF_VALOR_NOMINAL Valor_Nominal,
        GRP_FECHA_SUSCRIPCION Fecha_Suscripción,
        GRP_FECHA_VENCIMIENTO Fecha_vencimiento,
      DECODE(NVL(TAF_TASA_NOMINAL, -1), -1, TAF_TRE_MNEMONICO || DECODE(NVL(TAF_PUNTOS_ADICIONALES, -100), -100, '', ' + ' || TO_CHAR(TAF_PUNTOS_ADICIONALES)), TO_CHAR(TAF_TASA_NOMINAL*100)||'%') Tasa_Facial,
        TAF_MODALIDAD_TASA Modalidad_Pago_Rendimientos,
                      TAF_PERIODICIDAD_TASA Periocidda_tasa,
                      HTF_ETF_MNEMONICO Vigente,
                      TET_CFO_CCC_CLI_PER_NUM_IDEN,
                      TET_CFO_CCC_CLI_PER_TID_CODIGO,
                      TET_CFO_CCC_NUMERO_CUENTA,
                      TET_CFO_FON_CODIGO,
                      TET_CFO_CODIGO
      FROM
                      TENEDORES_TITULOS,
        HIS_TITULO_CUENTA_FONDO,
        TITULOS_ACTIVO_FONDO,
                       TITULOS_CUENTA_FONDO,
        GRUPOS_PLANTILLAS,
        FONDOS
      WHERE
            TAF_GRP_MNEMONICO                    = GRP_MNEMONICO
            AND TAF_GRP_FON_CODIGO                   = GRP_FON_CODIGO
            AND HTF_TCF_TAF_MODALIDAD_TASA          = TAF_MODALIDAD_TASA
            AND HTF_TCF_TAF_GRP_MNEMONICO           = TAF_GRP_MNEMONICO
            AND HTF_TCF_TAF_GRP_FON_CODIGO          = TAF_GRP_FON_CODIGO
            AND  HTF_TCF_TAF_GRP_FON_CODIGO           = TCF_TAF_GRP_FON_CODIGO
            AND HTF_TCF_TAF_GRP_MNEMONICO            = TCF_TAF_GRP_MNEMONICO
            AND HTF_TCF_TAF_MODALIDAD_TASA            =TCF_TAF_MODALIDAD_TASA
            AND HTF_TCF_NUMERO_TITULO                      = TCF_NUMERO_TITULO
            AND HTF_ETF_MNEMONICO                            = 'VIG'
            AND  TRUNC(HTF_FECHA_EXPEDICION)      BETWEEN TRUNC(HTF_FECHA_MODIFICACION) AND  TRUNC(P_FECHA_DESDE)
            AND TRUNC(TCF_FECHA_MODIFICACION)  > TRUNC(P_FECHA_DESDE)
            AND TCF_ETF_MNEMONICO                             NOT IN ('VIG')
            AND TCF_TAF_GRP_FON_CODIGO                   = TET_TCF_TAF_GRP_FON_CODIGO
            AND TCF_TAF_GRP_MNEMONICO                    =  TET_TCF_TAF_GRP_MNEMONICO
            AND  TCF_TAF_MODALIDAD_TASA                  = TET_TCF_TAF_MODALIDAD_TASA
            AND TCF_NUMERO_TITULO                             = TET_TCF_NUMERO_TITULO
            AND	FON_CODIGO =  GRP_FON_CODIGO
          --
      GROUP BY       HTF_TCF_TAF_GRP_FON_CODIGO,
        HTF_TCF_TAF_GRP_MNEMONICO,
        HTF_TCF_TAF_MODALIDAD_TASA,
        HTF_TCF_NUMERO_TITULO,
        TO_CHAR(HTF_TCF_NUMERO_TITULO),
        HTF_VALOR_NOMINAL,
        GRP_FECHA_SUSCRIPCION,
        GRP_FECHA_VENCIMIENTO,
        DECODE(NVL(TAF_TASA_NOMINAL, -1), -1, TAF_TRE_MNEMONICO || DECODE(NVL(TAF_PUNTOS_ADICIONALES, -100), -100, '', ' + ' || TO_CHAR(TAF_PUNTOS_ADICIONALES)), TO_CHAR(TAF_TASA_NOMINAL*100)||'%'),
        TAF_MODALIDAD_TASA,
        TAF_PERIODICIDAD_TASA,
        HTF_ETF_MNEMONICO,
        TET_CFO_CCC_CLI_PER_NUM_IDEN,
        TET_CFO_CCC_CLI_PER_TID_CODIGO,
        TET_CFO_CCC_NUMERO_CUENTA,
        TET_CFO_FON_CODIGO,
        TET_CFO_CODIGO;


    -- ****************** FIN ELIMINAR Y CREAR TABLA TEMPORAL "TMP_Q_TITULOS" ******************

    -- ****************** ELIMINAR Y CREAR TABLA TEMPORAL "TMP_Q_REG_OPER_EXT" ******************

      SELECT COUNT(*) INTO V_VARIABLE FROM ALL_TABLES
      WHERE TABLE_NAME = 'TMP_Q_REG_OPER_EXT';

      IF V_VARIABLE = 1
      THEN
        EXECUTE IMMEDIATE 'DROP TABLE TMP_Q_REG_OPER_EXT';
      END IF;

      IF V_VARIABLE >= 0
      THEN
        EXECUTE IMMEDIATE   'CREATE TABLE TMP_Q_REG_OPER_EXT
                            (
                              MCF_CONSECUTIVO                NUMBER NOT NULL ENABLE,
                              ROE_EXT_CFO_CCC_CLI_PER_NUM_ID VARCHAR2(15 BYTE) NOT NULL ENABLE,
                              ROE_EXT_CFO_CCC_CLI_PER_TID_CO VARCHAR2(3 BYTE) NOT NULL ENABLE,
                              ROE_EXT_CFO_CCC_NUMERO_CUENTA  NUMBER(2,0) NOT NULL ENABLE,
                              ROE_EXT_CFO_FON_CODIGO         VARCHAR2(15 BYTE) NOT NULL ENABLE,
                              ROE_EXT_CFO_CODIGO             NUMBER NOT NULL ENABLE,
                              ROE_FECHA DATE NOT NULL ENABLE,
                              MCF_TMF_MNEMONICO       VARCHAR2(3 BYTE) NOT NULL ENABLE,
                              TOF_DESCRIPCION         VARCHAR2(40 BYTE),
                              TMF_DESCRIPCION         VARCHAR2(40 BYTE) NOT NULL ENABLE,
                              OFO_TTO_TOF_CODIGO      VARCHAR2(3 BYTE),
                              OFO_CONCEPTO_COBRO_APT  VARCHAR2(30 BYTE),
                              OFO_CONCEPTO_INC_APT    VARCHAR2(24 BYTE),
                              ROE_DESCRIPCION         VARCHAR2(40 BYTE),
                              ROE_RENDIMIENTOS_NETOS  NUMBER,
                              ROE_RENDIMIENTOS_BRUTOS NUMBER,
                              ROE_RETEFUENTE          NUMBER,
                              ROE_MOVIMIENTO          NUMBER,
                              ROE_UNIDADES            NUMBER(18,8) NOT NULL ENABLE
                            )';

        EXECUTE IMMEDIATE 'CREATE INDEX IDX_TMP_Q_REG_OPER_FON_CODIGO ON TMP_Q_REG_OPER_EXT
                            (
                              ROE_EXT_CFO_FON_CODIGO
                            )';
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_TMP_Q_REG_OPER_PER_NUM_ID ON TMP_Q_REG_OPER_EXT
                            (
                              ROE_EXT_CFO_CCC_CLI_PER_TID_CO,
                              ROE_EXT_CFO_CCC_CLI_PER_NUM_ID
                            )';
        EXECUTE IMMEDIATE 'CREATE INDEX IDX_TMP_Q_REG_OPER_ROE_FECHA ON TMP_Q_REG_OPER_EXT
                            (
                              ROE_FECHA
                            )';

        /*EXECUTE IMMEDIATE 'CREATE PUBLIC SYNONYM tmp_q_reg_oper_ext FOR tmp_q_reg_oper_ext';

        EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON tmp_q_reg_oper_ext TO AUD_AUDITORIA';
        EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON tmp_q_reg_oper_ext TO VER_F_COMERCIAL';
        EXECUTE IMMEDIATE 'GRANT SELECT,INSERT,UPDATE,DELETE ON tmp_q_reg_oper_ext TO FON_SUPERUSUARIO';*/

      END IF;

      INSERT INTO TMP_Q_REG_OPER_EXT (MCF_CONSECUTIVO, ROE_EXT_CFO_CCC_CLI_PER_NUM_ID, ROE_EXT_CFO_CCC_CLI_PER_TID_CO, ROE_EXT_CFO_CCC_NUMERO_CUENTA, ROE_EXT_CFO_FON_CODIGO, ROE_EXT_CFO_CODIGO, ROE_FECHA, MCF_TMF_MNEMONICO, TOF_DESCRIPCION, TMF_DESCRIPCION, OFO_TTO_TOF_CODIGO, OFO_CONCEPTO_COBRO_APT, OFO_CONCEPTO_INC_APT, ROE_DESCRIPCION, ROE_RENDIMIENTOS_NETOS, ROE_RENDIMIENTOS_BRUTOS, ROE_RETEFUENTE, ROE_MOVIMIENTO, ROE_UNIDADES)
      SELECT	MCF2.MCF_CONSECUTIVO MCF_CONSECUTIVO,
        MCF2.MCF_CFO_CCC_CLI_PER_NUM_IDEN ROE_EXT_CFO_CCC_CLI_PER_NUM_ID,
        MCF2.MCF_CFO_CCC_CLI_PER_TID_CODIGO ROE_EXT_CFO_CCC_CLI_PER_TID_CO,
        MCF2.MCF_CFO_CCC_NUMERO_CUENTA ROE_EXT_CFO_CCC_NUMERO_CUENTA,
        MCF2.MCF_CFO_FON_CODIGO ROE_EXT_CFO_FON_CODIGO,
        MCF2.MCF_CFO_CODIGO ROE_EXT_CFO_CODIGO,
        MCF2.MCF_FECHA ROE_FECHA,
        MCF2.MCF_TMF_MNEMONICO,
        TOF2.TOF_DESCRIPCION,
        TMF3.TMF_DESCRIPCION,
        OFO2.OFO_TTO_TOF_CODIGO,
        DECODE(OFO2.OFO_CONCEPTO_COBRO_APT,'CCA',' - COMISION ADMINISTRACION','CCR',' - CAPITALIZACION RETEFUENTE','CIC',' - IVA COMISION ADMINISTRACION','CDE','-COMISION DE EXITO')  OFO_CONCEPTO_COBRO_APT,
        DECODE(OFO2.OFO_CONCEPTO_INC_APT,'IRGA',' RECHAZO GIRO ACH','IANC',' ANULACION CHEQUE','IDEC',' DEVOLUCION COMISION','IDIC',' DEVOLUCION IVA COMISION')  OFO_CONCEPTO_INC_APT,
        DECODE(MCF2.MCF_TMF_MNEMONICO,'O', TOF2.TOF_DESCRIPCION,TMF3.TMF_DESCRIPCION) ROE_DESCRIPCION,
        DECODE(MCF2.MCF_TMF_MNEMONICO,'R',DECODE(OFO2.OFO_TTO_TOF_CODIGO,'ING',0,'INC',0,'RP',MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV -  MCF2.MCF_RETEFUENTE_MOVIMIENTO,'RT',MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV -  MCF2.MCF_RETEFUENTE_MOVIMIENTO) ,MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV -  MCF2.MCF_RETEFUENTE_MOVIMIENTO) ROE_RENDIMIENTOS_NETOS,
        DECODE(MCF2.MCF_TMF_MNEMONICO,'R',DECODE(OFO2.OFO_TTO_TOF_CODIGO,'ING',0,'INC',0,'RP',MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV,'RT',MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV),MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV) ROE_RENDIMIENTOS_BRUTOS,
        DECODE(MCF2.MCF_TMF_MNEMONICO,'R',DECODE(OFO2.OFO_TTO_TOF_CODIGO,'ING',0,'INC',0,'RP',MCF2.MCF_RETEFUENTE_MOVIMIENTO,'RT',MCF2.MCF_RETEFUENTE_MOVIMIENTO),MCF2.MCF_RETEFUENTE_MOVIMIENTO) ROE_RETEFUENTE,
        DECODE(MCF2.MCF_TMF_MNEMONICO,'R',DECODE(OFO2.OFO_TTO_TOF_CODIGO,'ING',MCF2.MCF_CAPITAL,'INC',MCF2.MCF_CAPITAL,'RP',MCF2.MCF_CAPITAL + MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV - MCF2.MCF_RETEFUENTE_MOVIMIENTO,'RT',MCF2.MCF_CAPITAL + MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV - MCF2.MCF_RETEFUENTE_MOVIMIENTO),MCF2.MCF_CAPITAL + MCF2.MCF_RENDIMIENTOS_RF + MCF2.MCF_RENDIMIENTOS_RV - MCF2.MCF_RETEFUENTE_MOVIMIENTO)  ROE_MOVIMIENTO,
        MCF_UNIDADES_MOVIMIENTO ROE_UNIDADES
      FROM	MOVIMIENTOS_CUENTAS_FONDOS MCF2,
            TIPOS_MOVIMIENTO_FONDOS TMF3,
            ORDENES_FONDOS OFO2,
            TIPOS_ORDEN_FONDOS TOF2
      WHERE	MCF2.MCF_FECHA BETWEEN TRUNC(P_FECHA_DESDE)  AND TRUNC(P_FECHA_HASTA+1)
          AND	(MCF2.MCF_TMF_MNEMONICO	IN ('O','RCA','CRC','IBA','IBS','R','IBC','RIA','RIC','SIC','GBA','PEN','RAC')
          OR        MCF2.MCF_TMF_MNEMONICO	IN ('RTC','ITC'))
          AND	MCF2.MCF_TMF_MNEMONICO	= TMF3.TMF_MNEMONICO
          AND	MCF2.MCF_OFO_CONSECUTIVO	= OFO2.OFO_CONSECUTIVO(+)
          AND	MCF2.MCF_OFO_SUC_CODIGO	= OFO2.OFO_SUC_CODIGO(+)
          AND	TOF2.TOF_CODIGO(+)		= OFO2.OFO_TTO_TOF_CODIGO
        ;
        P_RETORNO := 1;
    EXCEPTION
      WHEN OTHERS THEN
      P_RETORNO := 0;
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
    END;
    -- ****************** FIN ELIMINAR Y CREAR TABLA TEMPORAL "TMP_Q_REG_OPER_EXT" ******************
END PrepararDatosExtractos;
/* ********************************************************* */
PROCEDURE PR_OBTENER_INF_DIARIA_FDOS (P_FECHA_CORTE VARCHAR2,
                                IO_CURSOR IN OUT O_CURSOR) IS
V_FECHA_CORTE DATE;

BEGIN
    V_FECHA_CORTE := TO_DATE(P_FECHA_CORTE,'DD-MM-YYYY');
    OPEN io_cursor FOR
    SELECT PIDF_NOMBRE_PRESENTACION,
      PIDF_URL,
      PIDF_ORDEN,
      PIDF_FON_CODIGO,
      P_FECHA_CORTE FECHA_CORTE
    FROM PARAM_INF_DIARIA_FONDOS
          INNER JOIN VALORIZACIONES_FONDO ON PIDF_FON_CODIGO = VFO_FON_CODIGO
          INNER JOIN RENTABILIDADES_Y_VOLATILIDADES ON VFO_FON_CODIGO = RYV_FON_CODIGO
      WHERE VFO_FECHA_VALORIZACION >= TRUNC(V_FECHA_CORTE)
        AND VFO_FECHA_VALORIZACION  < TRUNC(V_FECHA_CORTE + 1)
        AND RYV_FECHA >= TRUNC(V_FECHA_CORTE)
        AND RYV_FECHA  < TRUNC(V_FECHA_CORTE + 1)
        AND NVL(PIDF_ESTADO_NUM_CLIENTES,'N') = 'S' -- VAGTUD735 Oguio
    ORDER BY PIDF_ORDEN ASC;

END PR_OBTENER_INF_DIARIA_FDOS;
/* ********************************************************* */
PROCEDURE PR_OBTENER_DET_INF_DIARIA_FDOS (P_FECHA_CORTE VARCHAR2,
                                P_FON_CODIGO VARCHAR2,
                                IO_CURSOR IN OUT O_CURSOR) IS

V_FECHA_CORTE DATE;
BEGIN
    V_FECHA_CORTE := TO_DATE(P_FECHA_CORTE,'DD-MM-YYYY');

    OPEN io_cursor FOR
    WITH QUERY_COLUMNAS AS (
     SELECT DECODE(PIDF_VALOR_FONDO,'S','Vr Fondo ' || TRIM(TO_CHAR(ROUND(VFO_CAPITAL + VFO_REND_RF + VFO_REND_RV - VFO_RETENCION,3),'999,999,999,999,999,990.00')),NULL) VALOR_FONDO,
            DECODE(PIDF_VALOR_UNIDAD,'S','Vr Unidad ' || TRIM(TO_CHAR(ROUND(VFO_VALOR,3),'999,999,999,999.000')),NULL) VALOR_UNIDAD,
            DECODE(PIDF_RENT_DIARIA,'S','Diaria ' || TRIM(TO_CHAR(ROUND(RYV_RENTAB_DIARIA,3),'999,999,999,990.000') || '% EA'),NULL) AS RENT_DIARIA,
            DECODE(PIDF_RENT_ULT_MES,'S','Mensual ' || TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_MES,3),'999,999,999,999,999,990.000') || '% EA'),NULL) RENT_ULT_MES,
            DECODE(PIDF_RENT_ULT_SEMESTRE,'S','Semestral ' || TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_6MES,3),'999,999,999,990.000')|| '% EA'),NULL) RENT_ULT_SEMESTRE,
            DECODE(PIDF_RENT_ANO_CORRIDO,'S','Año Corrido ' || TRIM(TO_CHAR(ROUND(RYV_RENTAB_ANO_CORRIDO,3),'999,999,999,999,999,990.000')|| '% EA'),NULL) RENT_ANO_CORRIDO,
            DECODE(PIDF_RENT_ULT_ANO,'S','Último Año ' || TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_ANO,3),'999,999,999,990.000')|| '% EA'),NULL) RENT_ULT_ANO,
            DECODE(PIDF_RENT_ULT_2_ANO,'S','Últimos 2 Años ' || TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_2ANO,3),'999,999,999,990.000')|| '% EA'),NULL) RENT_ULT_2_ANO,
            DECODE(PIDF_RENT_ULT_3_ANO,'S','Últimos 3 Años ' || DECODE(RYV_RENTAB_ULT_3ANO,0,'No Aplica',TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_3ANO,3),'999,999,999,990.000')|| '% EA')),NULL) RENT_ULT_3_ANO
      FROM PARAM_INF_DIARIA_FONDOS
          INNER JOIN VALORIZACIONES_FONDO ON PIDF_FON_CODIGO = VFO_FON_CODIGO
          INNER JOIN RENTABILIDADES_Y_VOLATILIDADES ON VFO_FON_CODIGO = RYV_FON_CODIGO
      WHERE VFO_FECHA_VALORIZACION >= TRUNC(V_FECHA_CORTE)
        AND VFO_FECHA_VALORIZACION  < TRUNC(V_FECHA_CORTE + 1)
        AND RYV_FECHA >= TRUNC(V_FECHA_CORTE)
        AND RYV_FECHA  < TRUNC(V_FECHA_CORTE + 1)
        AND VFO_FON_CODIGO = P_FON_CODIGO
    )
    SELECT DETALLE
    FROM (
        SELECT	VALOR_FONDO DETALLE
        FROM QUERY_COLUMNAS
          UNION ALL
        SELECT VALOR_UNIDAD DETALLE
        FROM QUERY_COLUMNAS
          UNION ALL
        SELECT RENT_DIARIA DETALLE
        FROM QUERY_COLUMNAS
          UNION ALL
        SELECT RENT_ULT_MES DETALLE
        FROM QUERY_COLUMNAS
          UNION ALL
        SELECT RENT_ULT_SEMESTRE DETALLE
        FROM QUERY_COLUMNAS
          UNION ALL
        SELECT RENT_ANO_CORRIDO DETALLE
        FROM QUERY_COLUMNAS
         UNION ALL
        SELECT RENT_ULT_ANO DETALLE
        FROM QUERY_COLUMNAS
         UNION ALL
        SELECT RENT_ULT_2_ANO DETALLE
        FROM QUERY_COLUMNAS
         UNION ALL
        SELECT RENT_ULT_3_ANO DETALLE
        FROM QUERY_COLUMNAS
        )
      WHERE DETALLE IS NOT NULL;

END PR_OBTENER_DET_INF_DIARIA_FDOS;
/* ********************************************************* */
PROCEDURE PR_MARCAR_CARTA_EXONERACION(P_CLI_PER_NUM_IDEN VARCHAR2,
                                      P_CLI_PER_TID_CODIGO VARCHAR2,
                                      P_FON_CODIGO VARCHAR2,
                                      P_RADICACION VARCHAR2,
                                      P_EJECUTADO  IN OUT VARCHAR2) IS

  CURSOR C_CUENTAS_CLIENTES_FONDOS IS
	   SELECT CCF_FON_CODIGO
	   FROM CUENTAS_CLIENTES_FONDOS
	   WHERE CCF_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
	   	AND CCF_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
	   	AND CCF_FON_CODIGO = P_FON_CODIGO;

  V_FON_CODIGO VARCHAR2(20);
BEGIN
  P_EJECUTADO := 'N';

  OPEN C_CUENTAS_CLIENTES_FONDOS;
  FETCH C_CUENTAS_CLIENTES_FONDOS INTO V_FON_CODIGO;

 IF C_CUENTAS_CLIENTES_FONDOS%FOUND THEN
      UPDATE CUENTAS_CLIENTES_FONDOS
        SET CCF_CARTA_EXONERACION = 'S',
          CCF_RADICACION_EXONERACION = P_RADICACION
        WHERE CCF_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
          AND P_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
          AND CCF_FON_CODIGO = P_FON_CODIGO;
    ELSE
     INSERT
        INTO CUENTAS_CLIENTES_FONDOS
          (
            CCF_FON_CODIGO,
            CCF_CLI_PER_NUM_IDEN,
            CCF_CLI_PER_TID_CODIGO,
            CCF_RADICACION_ADHESION,
            CCF_FECHA_RADICA_ADHESION,
            CCF_ESTADO,
            CCF_CARTA_EXONERACION,
            CCF_RADICACION_EXONERACION
          )
          VALUES
          (
            P_FON_CODIGO,
            P_CLI_PER_NUM_IDEN,
            P_CLI_PER_TID_CODIGO,
            NULL,
            NULL,
            'A',
            'S',
            P_RADICACION
          );
    END IF;

  CLOSE C_CUENTAS_CLIENTES_FONDOS;

  P_EJECUTADO := 'S';
END PR_MARCAR_CARTA_EXONERACION;
/* ********************************************************* */
PROCEDURE PR_VALIDAR_PERFIL_RIESGO(P_CLI_PER_NUM_IDEN VARCHAR2,
                                      P_CLI_PER_TID_CODIGO VARCHAR2,
                                      P_FON_CODIGO VARCHAR2,
                                      P_TIPO_OPERACION VARCHAR2,
                                      P_VALIDO  IN OUT VARCHAR2) IS

  CURSOR C_CARTA_EXONERACION IS
	   SELECT NVL(CCF_CARTA_EXONERACION,'N')
	   FROM CUENTAS_CLIENTES_FONDOS
	   WHERE CCF_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
	   	AND CCF_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
	   	AND CCF_FON_CODIGO = P_FON_CODIGO
	   	AND CCF_ESTADO = 'A';

   CURSOR C_PRODUCTO IS
	   SELECT FON_NPR_PRO_MNEMONICO,PRO_CLASIFICACION
     FROM FONDOS,PRODUCTOS
     WHERE FON_NPR_PRO_MNEMONICO = PRO_MNEMONICO
	   AND FON_CODIGO = P_FON_CODIGO;


   CURSOR C_PERFIL IS
	   SELECT CLI_PERFIL_RIESGO,CLI_PROFESIONAL
	   FROM CLIENTES
	   WHERE CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
	   	AND CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO;


   V_PRODUCTO VARCHAR2(6);
   V_CARTA_EXONERACION VARCHAR2(1);
   V_AUTORIZADO VARCHAR2(1);
   V_PERFIL NUMBER(5);
   V_PROD_CLASIFICACION VARCHAR2(4);
   V_CLI_CLASIFICACION VARCHAR2(1);

BEGIN

  OPEN C_CARTA_EXONERACION;
  FETCH C_CARTA_EXONERACION INTO V_CARTA_EXONERACION;
	CLOSE C_CARTA_EXONERACION;

  V_CARTA_EXONERACION := NVL(V_CARTA_EXONERACION,'N');

  OPEN C_PRODUCTO;
  FETCH C_PRODUCTO INTO V_PRODUCTO,V_PROD_CLASIFICACION;
	CLOSE C_PRODUCTO;

  OPEN C_PERFIL;
  FETCH C_PERFIL INTO V_PERFIL,V_CLI_CLASIFICACION;
	CLOSE C_PERFIL;

 V_AUTORIZADO  := 	P_CLIENTES.AutorizaColocacionOrdenPerfil(V_PRODUCTO,
                                                              P_TIPO_OPERACION,
                                                              'NA',
                                                              'N',
                                                              V_PERFIL,
                                                              NULL,
                                                              NULL);
  IF V_AUTORIZADO = 'N' AND V_CARTA_EXONERACION = 'N' THEN
    P_VALIDO := 'N';
  ELSE
    P_VALIDO := 'S';
  END IF;
  IF V_PROD_CLASIFICACION = 'SIU' OR V_CLI_CLASIFICACION = 'S' THEN
    P_VALIDO := 'S';
  END IF;

END PR_VALIDAR_PERFIL_RIESGO;
/* ********************************************************* */
PROCEDURE PR_OBTENER_RENT_DIARIA_FDOS (P_FECHA_CORTE   IN DATE,
                                       P_FONDO         IN VARCHAR2,
                                       IO_CURSOR       IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR
   SELECT PIDF_NOMBRE_PRESENTACION,
           PIDF_FON_CODIGO,
           DECODE(PIDF_VALOR_FONDO,'S',ROUND(VFO_CAPITAL + VFO_REND_RF + VFO_REND_RV - VFO_RETENCION,3),NULL) VALOR_FONDO,
           DECODE(PIDF_VALOR_UNIDAD,'S',ROUND(VFO_VALOR,3),NULL) VALOR_UNIDAD
		   --WILLIAM CAMPOS 01/11/2022 Formateo valores
		   --TRIM(TO_CHAR(ROUND(DECODE(PIDF_VALOR_FONDO,'S',ROUND(VFO_CAPITAL + VFO_REND_RF + VFO_REND_RV - VFO_RETENCION,3),NULL),3),'999,999,999,999,999,990.000')) VALOR_FONDO,
           --TRIM(TO_CHAR(ROUND(DECODE(PIDF_VALOR_UNIDAD,'S',ROUND(VFO_VALOR,3),NULL),3),'999,999,999,999,999,990.000')) VALOR_UNIDAD
   FROM PARAM_INF_DIARIA_FONDOS
          INNER JOIN VALORIZACIONES_FONDO ON PIDF_FON_CODIGO = VFO_FON_CODIGO
          INNER JOIN RENTABILIDADES_Y_VOLATILIDADES ON VFO_FON_CODIGO = RYV_FON_CODIGO
      WHERE VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA_CORTE)
        AND VFO_FECHA_VALORIZACION  < TRUNC(P_FECHA_CORTE + 1)
        AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
        AND RYV_FECHA  < TRUNC(P_FECHA_CORTE + 1)
        AND NVL(PIDF_ESTADO_NUM_CLIENTES,'N') = 'S' -- VAGTUD735 Oguio
        AND PIDF_FON_CODIGO = DECODE(P_FONDO,NULL,PIDF_FON_CODIGO,P_FONDO)
   ORDER BY PIDF_ORDEN ASC;
END PR_OBTENER_RENT_DIARIA_FDOS ;


PROCEDURE PR_OBTENER_RET_DET_DIA_FDOS (P_FECHA_CORTE DATE,
                                       P_FON_CODIGO  VARCHAR2,
                                       IO_CURSOR     IN OUT O_CURSOR) IS
BEGIN
   OPEN io_cursor FOR
   SELECT 1 ORDEN
    ,'Diaria' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_DIARIA RENTABILIDAD
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_DIARIA,3),'999,999,999,990.000') || '% EA') RENT_PRESENTACION
    ,'Diaria' Etiqueta
    ,PIDF_FON_CODIGO FONDO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_DIARIA = 'S'
    UNION
    SELECT 2 ORDEN
    ,'Mensual' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_ULT_MES
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_MES,3),'999,999,999,999,999,990.000') || '% EA')
    ,'Mensual' Etiqueta
    ,PIDF_FON_CODIGO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_ULT_MES = 'S'
    UNION
    SELECT 3 ORDEN
    ,'Semestral' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_ULT_6MES
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_6MES,3),'999,999,999,990.000')|| '% EA')
    ,'Semestral' Etiqueta
    ,PIDF_FON_CODIGO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_ULT_SEMESTRE = 'S'
    UNION
    SELECT 4 ORDEN
    ,'Año Corrido' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_ANO_CORRIDO
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_ANO_CORRIDO,3),'999,999,999,999,999,990.000')|| '% EA')
    ,'Año Corrido' Etiqueta
    ,PIDF_FON_CODIGO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_ANO_CORRIDO = 'S'
    UNION
    SELECT 5 ORDEN
    ,'Último Año' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_ULT_ANO
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_ANO,3),'999,999,999,990.000')|| '% EA')
    ,'Último Año' Etiqueta
    ,PIDF_FON_CODIGO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_ULT_ANO = 'S'
    UNION
    SELECT 6 ORDEN
    ,'Últimos 2 Años' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_ULT_2ANO
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_2ANO,3),'999,999,999,990.000')|| '% EA')
    ,'Últimos 2 Años' Etiqueta
    ,PIDF_FON_CODIGO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_ULT_2_ANO = 'S'
    UNION
    SELECT 7 ORDEN
    ,'Últimos 3 Años' NOMBRE_RENTABILIDAD
    ,RYV_RENTAB_ULT_3ANO
    ,TRIM(TO_CHAR(ROUND(RYV_RENTAB_ULT_3ANO,3),'999,999,999,990.000')|| '% EA')
    ,'Últimos 3 Años' Etiqueta
    ,PIDF_FON_CODIGO
    FROM
    PARAM_INF_DIARIA_FONDOS
    , RENTABILIDADES_Y_VOLATILIDADES
    WHERE RYV_FON_CODIGO = PIDF_FON_CODIGO
    AND RYV_FECHA >= TRUNC(P_FECHA_CORTE)
    AND RYV_FECHA < TRUNC(P_FECHA_CORTE + 1)
    AND PIDF_FON_CODIGO = P_FON_CODIGO
    AND PIDF_RENT_ULT_3_ANO = 'S'
    ORDER BY 1;
END PR_OBTENER_RET_DET_DIA_FDOS;

/************************************************************************************************
  Author  : VAGTUD937 Extractos Inteligentes Control Rentabilidades
  Created : 27/06/2023
  Purpose : Este procedimiento contempla la lógica para notificar la generación de los extractos.
  *************************************************************************************************/
  PROCEDURE PR_MAIL_RENTABILIDADES IS

    V_CANT NUMBER := 0;

  BEGIN

    IF TO_CHAR(TRUNC(SYSDATE), 'DD') = '01' AND (TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) >= 8) THEN

      SELECT COUNT(1)
      INTO   V_CANT
      FROM   NOTIFICACIONES_MAIL_CORREDORES M
      WHERE  M.NMC_SERVICIO = 'ERROR GENERACION DE EXTRACTOS'
      AND    M.NMC_DE = 'procesosnocturnos@corredores.com'
      AND    M.NMC_ASUNTO = 'ALERTA: ERROR EN LA GENERACIÓN DE EXTRACTOS'
      AND    M.NMC_CONSECUTIVO >= (SELECT MAX(NMC_CONSECUTIVO)
                                   FROM NOTIFICACIONES_MAIL_CORREDORES
                                   WHERE NMC_FECHA_INGRESO >= TRUNC(SYSDATE)
                                   AND NMC_FECHA_INGRESO < TRUNC(SYSDATE) + 1)
      AND    M.NMC_FECHA_INGRESO >= TRUNC(SYSDATE)
      AND    M.NMC_FECHA_INGRESO < TRUNC(SYSDATE) + 1;

      IF V_CANT > 0 THEN
        --
        DECLARE

          V_CLI_PER_TID_CODIGO VARCHAR2(32);
          V_CLI_PER_NUM_IDEN   VARCHAR2(64);
          V_MAILLST            VARCHAR2(4000);

          CURSOR C_USUARIO IS
            SELECT PER_NUM_IDEN
                  ,PER_TID_CODIGO
            FROM   PERSONAS
            WHERE  PER_NOMBRE_USUARIO = (SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') FROM DUAL);
          R_USUARIO C_USUARIO%ROWTYPE;

          CURSOR C_EMAIL IS
            SELECT C.CON_VALOR_CHAR
            FROM   CONSTANTES C
            WHERE  C.CON_MNEMONICO = 'NGE';
          R_EMAIL C_EMAIL%ROWTYPE;

          V_ASUNTO VARCHAR2(64) := 'SOLUCIÓN: ERROR EN LA GENERACIÓN DE EXTRACTOS';
          V_CUERPO VARCHAR2(2048) := 'Estimados,' || '<br><br>' || '</tr>' ||
                                     'Les informamos que se ha completado satisfactoriamente el proceso de generación de extractos desde ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI')||
                                     '<br><br>' || '</tr>' || '</tr>' || 'Cordialmente,' ||
                                     '<br><br>' || '</tr>' || 'TI Davivienda Corredores' || '<br>' ||
                                     '</tr>';
          SALIDA   VARCHAR2(2048);

        BEGIN

          OPEN C_USUARIO;
          FETCH C_USUARIO
            INTO R_USUARIO;
          IF C_USUARIO%FOUND THEN
            V_CLI_PER_TID_CODIGO := R_USUARIO.PER_TID_CODIGO;
            V_CLI_PER_NUM_IDEN   := R_USUARIO.PER_NUM_IDEN;
          ELSE
            V_CLI_PER_TID_CODIGO := 'CC';
            V_CLI_PER_NUM_IDEN   := '0';
          END IF;
          CLOSE C_USUARIO;

          OPEN C_EMAIL;
          FETCH C_EMAIL
            INTO R_EMAIL;
          IF C_EMAIL%NOTFOUND THEN
            V_MAILLST :=  'canalesalternos@corredores.com,servicioalcliente@corredores.com,stecnico@corredores.com';
          ELSE
            V_MAILLST := R_EMAIL.CON_VALOR_CHAR;
          END IF;
          CLOSE C_EMAIL;

          FOR POS IN (SELECT TRIM(REGEXP_SUBSTR(V_MAILLST, '[^,]+', 1, LEVEL)) MAIL
                      FROM   DUAL
                      CONNECT BY LEVEL <= REGEXP_COUNT(V_MAILLST, ',') + 1) LOOP
            P_NOTIFICACIONES_MAIL.PR_ENVIO_MAIL(P_CLI_PER_TID_CODIGO => V_CLI_PER_TID_CODIGO,
                                                P_CLI_PER_NUM_IDEN   => V_CLI_PER_NUM_IDEN,
                                                P_SERVICIO           => 'SOLUCION GENERACION EXTRACTOS',
                                                P_DE                 => 'procesosnocturnos@corredores.com',
                                                P_PARA               => POS.MAIL,
                                                P_ASUNTO             => V_ASUNTO,
                                                P_MENSAJE            => V_CUERPO,
                                                P_CLOB               => SALIDA,
                                                P_MENSAJE_CLOB       => NULL,
                                                P_ADJUNTO            => NULL);
          END LOOP;
        END;
      END IF;
    END IF;
  END PR_MAIL_RENTABILIDADES;


FUNCTION F_OBTENER_CODIGO_FONDO_PPAL(p_fondo  IN VARCHAR2)
RETURN VARCHAR2 IS
  v_fondo VARCHAR2(1000);
BEGIN
    SELECT DISTINCT pfo.pfo_rango_min_char
      INTO v_fondo
    FROM PARAMETROS_FONDOS PFO
   WHERE pfo.pfo_fon_codigo = p_fondo
     AND pfo.pfo_par_codigo = 71;

  RETURN(NVL(v_fondo, p_fondo));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN p_fondo;
END F_OBTENER_CODIGO_FONDO_PPAL;

FUNCTION F_VALIDA_CODIGO_FONDO(P_CODIGO_FONDO VARCHAR2) RETURN varchar2 IS
  V_CONSULTA NUMBER;
BEGIN
  SELECT COUNT(1)
    INTO V_CONSULTA
    FROM FONDOS F
   WHERE F.FON_CODIGO = P_CODIGO_FONDO;

  IF V_CONSULTA >= 1 THEN
    RETURN(1);
  ELSE
    RETURN(0);
  END IF;
END F_VALIDA_CODIGO_FONDO;
/* ********************************************************* */

PROCEDURE PR_OBTENER_CLIENTE_FONDO(P_TIPO_CORRESPONDENCIA VARCHAR2,
                                   P_ESTADO_CLIENTE       VARCHAR2,
                                   P_PRIORIDAD_ENVIO      NUMBER,
                                   IO_CURSOR              OUT SYS_REFCURSOR) IS

  V_SEMESTRE     NUMBER;
  V_ANIO_ACTUAL  NUMBER;
  V_FECHA_CORTE  VARCHAR2(12);
BEGIN
  --OBTIENE EL AÑO ACTUAL
  SELECT EXTRACT(YEAR FROM SYSDATE) INTO V_ANIO_ACTUAL FROM DUAL;
  SELECT CASE
           WHEN EXTRACT(MONTH FROM SYSDATE) BETWEEN 1 AND 6 THEN
            1
           ELSE
            2
         END AS SEMETRE
    INTO V_SEMESTRE
    FROM DUAL;

  CASE V_SEMESTRE
    WHEN 1 THEN
      V_FECHA_CORTE := '31-12-' || TO_CHAR(V_ANIO_ACTUAL - 1);
    WHEN 2 THEN
      V_FECHA_CORTE := '30-06-' || TO_CHAR(V_ANIO_ACTUAL);
  END CASE;
  DBMS_OUTPUT.put_line(V_FECHA_CORTE);
  --VALIDACIONES DE FECHA
  CASE P_PRIORIDAD_ENVIO

    WHEN -1 THEN

      BEGIN
        OPEN IO_CURSOR FOR

             SELECT PER.PER_TID_CODIGO TIPO_ID,
                    PER.PER_NUM_IDEN NUMERO_ID,
                    P_REPORTES_CLIENTES.FN_CORREO(PER.PER_TID_CODIGO, PER.PER_NUM_IDEN) CORREO,
                    (CASE
                      WHEN INSTR(PER.PER_NOMBRE, ' ') > 0 THEN
                       NVL(SUBSTR(PER.PER_NOMBRE, 1, INSTR(PER.PER_NOMBRE, ' ') - 1),
                           ' ')
                      ELSE
                       PER.PER_NOMBRE
                    END) NOMBRE,
                    PER.PER_RAZON_SOCIAL RAZON_SOCIAL,
                    LISTAGG(P_FONDOS_WEB.F_OBTENER_CODIGO_FONDO_PPAL(MCF_CFO_FON_CODIGO),
                            ',') WITHIN GROUP(ORDER BY MCF_CFO_FON_CODIGO) AS CODIGO_FONDO
               FROM (SELECT DISTINCT MCF.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                                     MCF.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                                     MCF.MCF_CFO_FON_CODIGO
                       FROM MOVIMIENTOS_CUENTAS_FONDOS MCF
                      WHERE MCF.MCF_FECHA >= TO_DATE(V_FECHA_CORTE, 'dd-mm-yyyy')
                        AND MCF.MCF_FECHA < TO_DATE(V_FECHA_CORTE, 'dd-mm-yyyy') + 1
                        AND MCF.MCF_SALDO_INVER > 0) MCF_FILTRO

               JOIN CLIENTES CLI
                 ON CLI.CLI_PER_NUM_IDEN = MCF_FILTRO.MCF_CFO_CCC_CLI_PER_NUM_IDEN
                AND CLI.CLI_PER_TID_CODIGO = MCF_FILTRO.MCF_CFO_CCC_CLI_PER_TID_CODIGO
               JOIN PERSONAS PER
                 ON PER.PER_NUM_IDEN = CLI.CLI_PER_NUM_IDEN
                AND PER.PER_TID_CODIGO = CLI.CLI_PER_TID_CODIGO
              WHERE CLI.CLI_TEC_MNEMONICO = P_TIPO_CORRESPONDENCIA
                AND CLI.CLI_ECL_MNEMONICO = P_ESTADO_CLIENTE

              GROUP BY PER.PER_TID_CODIGO,
                       PER.PER_NUM_IDEN,
                       PER.PER_NOMBRE,
                       PER.PER_RAZON_SOCIAL;

    END;


    WHEN 1 THEN

      BEGIN
        OPEN IO_CURSOR FOR

                SELECT PER.PER_TID_CODIGO TIPO_ID,
                    PER.PER_NUM_IDEN NUMERO_ID,
                    P_REPORTES_CLIENTES.FN_CORREO(PER.PER_TID_CODIGO, PER.PER_NUM_IDEN) CORREO,
                    (CASE
                      WHEN INSTR(PER.PER_NOMBRE, ' ') > 0 THEN
                       NVL(SUBSTR(PER.PER_NOMBRE, 1, INSTR(PER.PER_NOMBRE, ' ') - 1),
                           ' ')
                      ELSE
                       PER.PER_NOMBRE
                    END) NOMBRE,
                    PER.PER_RAZON_SOCIAL RAZON_SOCIAL,
                    LISTAGG(P_FONDOS_WEB.F_OBTENER_CODIGO_FONDO_PPAL(MCF_CFO_FON_CODIGO),
                            ',') WITHIN GROUP(ORDER BY MCF_CFO_FON_CODIGO) AS CODIGO_FONDO
               FROM (SELECT DISTINCT MCF.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                                     MCF.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                                     MCF.MCF_CFO_FON_CODIGO
                       FROM MOVIMIENTOS_CUENTAS_FONDOS MCF
                      WHERE MCF.MCF_FECHA >= TO_DATE(V_FECHA_CORTE, 'dd-mm-yyyy')
                        AND MCF.MCF_FECHA < TO_DATE(V_FECHA_CORTE, 'dd-mm-yyyy') + 1
                        AND MCF.MCF_SALDO_INVER > 0) MCF_FILTRO

               JOIN CLIENTES CLI
                 ON CLI.CLI_PER_NUM_IDEN = MCF_FILTRO.MCF_CFO_CCC_CLI_PER_NUM_IDEN
                AND CLI.CLI_PER_TID_CODIGO = MCF_FILTRO.MCF_CFO_CCC_CLI_PER_TID_CODIGO
               JOIN PERSONAS PER
                 ON PER.PER_NUM_IDEN = CLI.CLI_PER_NUM_IDEN
                AND PER.PER_TID_CODIGO = CLI.CLI_PER_TID_CODIGO
              WHERE CLI.CLI_TEC_MNEMONICO = P_TIPO_CORRESPONDENCIA
                AND CLI.CLI_ECL_MNEMONICO = P_ESTADO_CLIENTE
                 AND CLI.CLI_BSC_MNEMONICO IN ('BPJ', 'COR', 'EMP', 'INS', 'BPR', 'PYM')

              GROUP BY PER.PER_TID_CODIGO,
                       PER.PER_NUM_IDEN,
                       PER.PER_NOMBRE,
                       PER.PER_RAZON_SOCIAL;
      END;

    WHEN 2 THEN
      BEGIN
        OPEN IO_CURSOR FOR

                SELECT PER.PER_TID_CODIGO TIPO_ID,
                    PER.PER_NUM_IDEN NUMERO_ID,
                    P_REPORTES_CLIENTES.FN_CORREO(PER.PER_TID_CODIGO, PER.PER_NUM_IDEN) CORREO,
                    (CASE
                      WHEN INSTR(PER.PER_NOMBRE, ' ') > 0 THEN
                       NVL(SUBSTR(PER.PER_NOMBRE, 1, INSTR(PER.PER_NOMBRE, ' ') - 1),
                           ' ')
                      ELSE
                       PER.PER_NOMBRE
                    END) NOMBRE,
                    PER.PER_RAZON_SOCIAL RAZON_SOCIAL,
                    LISTAGG(P_FONDOS_WEB.F_OBTENER_CODIGO_FONDO_PPAL(MCF_CFO_FON_CODIGO),
                            ',') WITHIN GROUP(ORDER BY MCF_CFO_FON_CODIGO) AS CODIGO_FONDO
               FROM (SELECT DISTINCT MCF.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                                     MCF.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                                     MCF.MCF_CFO_FON_CODIGO
                       FROM MOVIMIENTOS_CUENTAS_FONDOS MCF
                      WHERE MCF.MCF_FECHA >= TO_DATE(V_FECHA_CORTE, 'dd-mm-yyyy')
                        AND MCF.MCF_FECHA < TO_DATE(V_FECHA_CORTE, 'dd-mm-yyyy') + 1
                        AND MCF.MCF_SALDO_INVER > 0) MCF_FILTRO

               JOIN CLIENTES CLI
                 ON CLI.CLI_PER_NUM_IDEN = MCF_FILTRO.MCF_CFO_CCC_CLI_PER_NUM_IDEN
                AND CLI.CLI_PER_TID_CODIGO = MCF_FILTRO.MCF_CFO_CCC_CLI_PER_TID_CODIGO
               JOIN PERSONAS PER
                 ON PER.PER_NUM_IDEN = CLI.CLI_PER_NUM_IDEN
                AND PER.PER_TID_CODIGO = CLI.CLI_PER_TID_CODIGO
              WHERE CLI.CLI_TEC_MNEMONICO = P_TIPO_CORRESPONDENCIA
                AND CLI.CLI_ECL_MNEMONICO = P_ESTADO_CLIENTE
                 AND CLI.CLI_BSC_MNEMONICO IN ('TIN', 'ORO', 'LAT', 'PPC', 'BRC')

              GROUP BY PER.PER_TID_CODIGO,
                       PER.PER_NUM_IDEN,
                       PER.PER_NOMBRE,
                       PER.PER_RAZON_SOCIAL;

      END;

  END CASE;

END PR_OBTENER_CLIENTE_FONDO;


END P_FONDOS_WEB;

/

  GRANT EXECUTE ON "PROD"."P_FONDOS_WEB" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_FONDOS_WEB" TO "RESOURCE";
