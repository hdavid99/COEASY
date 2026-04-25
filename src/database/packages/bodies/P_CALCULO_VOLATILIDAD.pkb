--------------------------------------------------------
--  File created - Saturday-April-25-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_CALCULO_VOLATILIDAD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_CALCULO_VOLATILIDAD" AS

/*--------------------------------------------------------------------------------/
::: FUNCION QUE RETORNA LA VOLATILIDAD MENSUAL PARA UN FONDO
--------------------------------------------------------------------------------*/
FUNCTION F_VOLAT_ULT_MES
   (P_FECHA IN DATE
   ,P_FONDO IN VARCHAR2) RETURN NUMBER IS

   V_V_MES NUMBER(35,10);
   V_FECHA_ANT DATE;

BEGIN
   V_FECHA_ANT := TRUNC((TO_DATE('01'||'/'||TO_CHAR(P_FECHA,'MM')||'/'||TO_CHAR(P_FECHA,'YYYY'),'DD/MM/YYYY')-1)+1);

   SELECT TRUNC(STDDEV(RYV_RENTAB_DIARIA_PER) * SQRT(365),8)
   INTO   V_V_MES
   FROM   RENTABILIDADES_Y_VOLATILIDADES  
   WHERE  RYV_FECHA >= TRUNC(V_FECHA_ANT)
   AND    RYV_FECHA <= TRUNC(P_FECHA)
   AND    RYV_FON_CODIGO =P_FONDO;

   RETURN(V_V_MES);

EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   RETURN 0;
END ;


/*--------------------------------------------------------------------------------/
::: FUNCION QUE RETORNA LA VOLATILIDAD  A 6 MESES PARA UN FONDO
--------------------------------------------------------------------------------*/
FUNCTION F_VOLAT_ULT_6MES
   (P_FECHA IN DATE
   ,P_FONDO IN VARCHAR2) RETURN NUMBER IS

   V_V_6MES NUMBER(35,10);
   V_FECHA_ANT DATE;

BEGIN

   V_FECHA_ANT := TRUNC(LAST_DAY(ADD_MONTHS(P_FECHA,-6))+1);

   SELECT TRUNC(STDDEV(RYV_RENTAB_DIARIA_PER) * SQRT(365),8)
   INTO   V_V_6MES
   FROM   RENTABILIDADES_Y_VOLATILIDADES  
   WHERE  RYV_FECHA >= TRUNC(V_FECHA_ANT)
   AND    RYV_FECHA <= TRUNC(P_FECHA)
   AND    RYV_FON_CODIGO =P_FONDO;

   RETURN(V_V_6MES);

EXCEPTION 
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
END ;

/*--------------------------------------------------------------------------------/
::: FUNCION QUE RETORNA LA VOLATILIDAD  A¿O CORRIDO PARA UN FONDO
--------------------------------------------------------------------------------*/
FUNCTION F_VOLAT_ANO_CORRIDO
   (P_FECHA IN DATE
   ,P_FONDO IN VARCHAR2) RETURN NUMBER IS

   V_V_ANO_CORR NUMBER(35,10);
   V_FECHA_ANT DATE;

BEGIN
   V_FECHA_ANT :=TRUNC((TO_DATE('01'||'/'||'01'||'/'||TO_CHAR(P_FECHA,'YYYY'),'DD/MM/YYYY')-1)+1);

   SELECT TRUNC(STDDEV(RYV_RENTAB_DIARIA_PER) * SQRT(365),8)
   INTO   V_V_ANO_CORR
   FROM   RENTABILIDADES_Y_VOLATILIDADES  
   WHERE  RYV_FECHA >= TRUNC(V_FECHA_ANT)
   AND    RYV_FECHA <= TRUNC(P_FECHA)
   AND    RYV_FON_CODIGO =P_FONDO;

   RETURN(V_V_ANO_CORR);

EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   RETURN 0;
END ;

/*--------------------------------------------------------------------------------/
::: FUNCION QUE RETORNA LA VOLATILIDAD  ULTIMO A¿O PARA UN FONDO
--------------------------------------------------------------------------------*/
FUNCTION F_VOLAT_ULT_ANO
   (P_FECHA IN DATE
   ,P_FONDO IN VARCHAR2) RETURN NUMBER IS

   V_V_ULT_ANO NUMBER(35,10);
   V_FECHA_ANT DATE;

BEGIN
   V_FECHA_ANT :=TRUNC(ADD_MONTHS(P_FECHA,-12)+1);

   SELECT TRUNC(STDDEV(RYV_RENTAB_DIARIA_PER) * SQRT(365),8)
   INTO   V_V_ULT_ANO
   FROM   RENTABILIDADES_Y_VOLATILIDADES  
   WHERE  RYV_FECHA >= TRUNC(V_FECHA_ANT)
   AND    RYV_FECHA <= TRUNC(P_FECHA)
   AND    RYV_FON_CODIGO =P_FONDO;

   RETURN(V_V_ULT_ANO);

EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   RETURN 0;
END ;

/*--------------------------------------------------------------------------------/
::: FUNCION QUE RETORNA LA VOLATILIDAD  ULTIMOS 2 A¿OS PARA UN FONDO
--------------------------------------------------------------------------------*/
FUNCTION F_VOLAT_ULT_2ANO
   (P_FECHA IN DATE
   ,P_FONDO IN VARCHAR2) RETURN NUMBER IS

   V_V_ULT_2ANO NUMBER(35,10);
   V_FECHA_ANT DATE;

BEGIN

   V_FECHA_ANT :=TRUNC(ADD_MONTHS(P_FECHA,-24)+1);

   SELECT TRUNC(STDDEV(RYV_RENTAB_DIARIA_PER) * SQRT(365),8)
   INTO   V_V_ULT_2ANO
   FROM   RENTABILIDADES_Y_VOLATILIDADES  
   WHERE  RYV_FECHA >= TRUNC(V_FECHA_ANT)
   AND    RYV_FECHA <= TRUNC(P_FECHA)
   AND    RYV_FON_CODIGO =P_FONDO;

   RETURN(V_V_ULT_2ANO);

EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   RETURN 0;
END ;

/*--------------------------------------------------------------------------------/
::: FUNCION QUE RETORNA LA VOLATILIDAD  ULTIMOS 3 A¿OS PARA UN FONDO
--------------------------------------------------------------------------------*/
FUNCTION F_VOLAT_ULT_3ANO
(P_FECHA IN DATE
,P_FONDO IN VARCHAR2) 

RETURN NUMBER
  IS
  V_V_ULT_3ANO NUMBER(35,10);
  V_FECHA_ANT DATE;

BEGIN

   V_FECHA_ANT :=TRUNC(ADD_MONTHS(P_FECHA,-36)+1);

   SELECT TRUNC(STDDEV(RYV_RENTAB_DIARIA_PER) * SQRT(365),8)
   INTO   V_V_ULT_3ANO
   FROM   RENTABILIDADES_Y_VOLATILIDADES  
   WHERE  RYV_FECHA >= TRUNC(V_FECHA_ANT)
   AND    RYV_FECHA <= TRUNC(P_FECHA)
   AND    RYV_FON_CODIGO =P_FONDO;

  RETURN(V_V_ULT_3ANO);

EXCEPTION 
   WHEN NO_DATA_FOUND THEN
   RETURN 0;
END ;

/*------------------------------------------------------------------------------------------------------/
::: PROCEDIMIENTO QUE INSERTA REGISTRO DE VOLATILIDAD EN LA TABLA RENTABIULIDADES_Y_VOLATILIDADES
-------------------------------------------------------------------------------------------------------*/

PROCEDURE INSERTAR_VOLATIL(FEC DATE,P_TX IN NUMBER DEFAULT NULL) IS

   CURSOR C_VFO_FONDO (FEC DATE) IS
      SELECT DISTINCT VFO_FON_CODIGO, 
                      trunc(VFO_FECHA_VALORIZACION)VFO_FECHA_VALORIZACION
      FROM    VALORIZACIONES_FONDO
      WHERE   VFO_FECHA_VALORIZACION >= TRUNC(FEC)
      AND     VFO_FECHA_VALORIZACION < TRUNC(FEC) + 1
      --AND     VFO_FON_CODIGO NOT IN ('900406760')
      -- Fondos con alta rentabilidad
      ORDER BY 1,2;

   V_VOLAT_MES NUMBER(35,10); 
   V_VOLAT_6MES NUMBER(35,10); 
   V_VOLAT_ANO_COR NUMBER(35,10);
   V_VOLAT_ULT_ANO NUMBER(35,10); 
   V_VOLAT_ULT_2ANO NUMBER(35,10);
   V_VOLAT_ULT_3ANO NUMBER(35,10);
   NO_PROCESO EXCEPTION;
   --V_REGISTRO NUMBER;
   N_ID_PROCESO NUMBER;
   N_TX NUMBER;

BEGIN 
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_CALCULO_VOLATILIDAD.INSERTAR_VOLATIL');

    --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio proceso P_CALCULO_VOLATILIDAD.INSERTAR_VOLATIL. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);

   V_VOLAT_MES := 0;
   V_VOLAT_6MES := 0;
   V_VOLAT_ANO_COR := 0;
   V_VOLAT_ULT_ANO := 0;
   V_VOLAT_ULT_2ANO := 0;
   V_VOLAT_ULT_3ANO := 0;

   FOR R_VFO in C_VFO_FONDO (FEC)
      LOOP
         BEGIN

            V_VOLAT_MES       := ROUND(TRUNC(F_VOLAT_ULT_MES(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO),8),4);
            V_VOLAT_6MES      := ROUND(TRUNC(F_VOLAT_ULT_6MES(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO),8),4);
            V_VOLAT_ANO_COR   := ROUND(TRUNC(F_VOLAT_ANO_CORRIDO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO),8),4);
            V_VOLAT_ULT_ANO   := ROUND(TRUNC(F_VOLAT_ULT_ANO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO),8),4);
            V_VOLAT_ULT_2ANO  := ROUND(TRUNC(F_VOLAT_ULT_2ANO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO),8),4);
            V_VOLAT_ULT_3ANO  := ROUND(TRUNC(F_VOLAT_ULT_3ANO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO),8),4);

            UPDATE RENTABILIDADES_Y_VOLATILIDADES
            SET RYV_VOLAT_ULT_MES = V_VOLAT_MES,
                RYV_VOLAT_ULT_6MES = V_VOLAT_6MES,
                RYV_VOLAT_ANO_CORRIDO = V_VOLAT_ANO_COR,
                RYV_VOLAT_ULT_ANO = V_VOLAT_ULT_ANO,
                RYV_VOLAT_ULT_2ANO = V_VOLAT_ULT_2ANO, 
                RYV_VOLAT_ULT_3ANO = V_VOLAT_ULT_3ANO 
            WHERE RYV_FECHA = R_VFO.VFO_FECHA_VALORIZACION
            AND RYV_FON_CODIGO = R_VFO.VFO_FON_CODIGO;

            COMMIT; 

         EXCEPTION 
            WHEN NO_PROCESO THEN
               RAISE_APPLICATION_ERROR(-20001,'Error al insertar valor' || SQLERRM);
         END;

      END LOOP;
      --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'F',
                                    'Inicio proceso P_CALCULO_VOLATILIDAD.INSERTAR_VOLATIL. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
      COMMIT;
   END;
END P_CALCULO_VOLATILIDAD;

/

  GRANT EXECUTE ON "PROD"."P_CALCULO_VOLATILIDAD" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_CALCULO_VOLATILIDAD" TO "COE_RECURSOS";
