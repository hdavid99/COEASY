--------------------------------------------------------
--  File created - Saturday-April-25-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_CALCULO_RENTABILIDAD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_CALCULO_RENTABILIDAD" AS

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL VR DE UN FONDO EN  UNA FECHA DETERMINADA
   --------------------------------------------------------------------------------*/
   FUNCTION F_VALOR_FONDO(P_FECHA IN DATE, P_FONDO IN VARCHAR2) RETURN NUMBER IS

      V_VR_FONDO NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN
      SELECT DISTINCT TRUNC(VFO_VALOR, 8)
        INTO V_VR_FONDO
        FROM VALORIZACIONES_FONDO
       WHERE VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
         AND VFO_FECHA_VALORIZACION < TRUNC(P_FECHA + 1)
         AND VFO_FON_CODIGO = P_FONDO;

      RETURN(V_VR_FONDO);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20001, 'Error' || SQLERRM);

   END;

	/*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD AL INICIO DE UN PERIODO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_INICIO(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_DIA   NUMBER;
      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER;
      NO_PROCESO EXCEPTION;

		CURSOR C_VALORIZACION IS		
			SELECT MIN( VFO_FECHA_VALORIZACION ) + 1 FECHA_ANT
			  FROM VALORIZACIONES_FONDO
			 WHERE VFO_FON_CODIGO = P_FONDO;
		R_VALORIZACION C_VALORIZACION%ROWTYPE;			 

   BEGIN

		OPEN C_VALORIZACION;
		FETCH C_VALORIZACION INTO R_VALORIZACION;
		IF C_VALORIZACION%FOUND THEN
			V_FEC_ANT := R_VALORIZACION.FECHA_ANT;		
		END IF;

      V_FECH_INIC := P_FECHA;

		V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
		V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
		V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
		V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
		V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
		V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
		V_RENT_DIA   := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

		RETURN(V_RENT_DIA);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20003, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;

   END F_RENT_INICIO;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DIARIA DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_DIARIA(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_DIA   NUMBER;
      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER;
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(P_FECHA - 1);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_DIA   := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_DIA);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20003, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD PERIODICA DIARIA DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_PER_DIARIA(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_PER_DIA NUMBER(35, 10);
      V_FEC_ANT      DATE;
      V_FECH_INIC    DATE;
      V_ANTERIOR     NUMBER(35, 10);
      V_ACTUAL       NUMBER(35, 10);
      V_RESUL_UNID   NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(P_FECHA - 1);

      V_ANTERIOR     := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
      V_ACTUAL       := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
      V_RESUL_UNID   := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
      V_RENT_PER_DIA := ROUND(TRUNC((V_RESUL_UNID - 1) * 100, 8), 4);

      RETURN(V_RENT_PER_DIA);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20004, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN 0;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD A¿`O CORRIDO DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ANO_CORRIDO(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS
      V_RENT_ANO_CORR NUMBER(35, 10);

      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(TO_DATE('01' || '/' || '01' || '/' || TO_CHAR(P_FECHA, 'YYYY'), 'DD/MM/YYYY') - 1);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_ANO_CORR := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_ANO_CORR);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20005, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

 /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD MES CORRIDO DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_MES_CORRIDO(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS
      V_RENT_ANO_CORR NUMBER(35, 10);

      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := LAST_DAY(ADD_MONTHS(TO_DATE(P_FECHA,'DD-MM-YYYY'),-1));

         V_NDIAS         :=  TO_DATE(V_FECH_INIC, 'DD-MM-YY') - TO_DATE(V_FEC_ANT, 'DD-MM-YY');
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(TO_DATE(V_FEC_ANT, 'DD-MM-YY'), P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(TO_DATE(V_FECH_INIC, 'DD-MM-YY'), P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC(1/(V_NDIAS / 365), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_ANO_CORR := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_ANO_CORR);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20005, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END F_RENT_MES_CORRIDO;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DEL ULTIMO MES DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_MES(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_MES   NUMBER(35, 10);
      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;
      DIA_OLD NUMBER;
      DIA_NEW NUMBER;

   BEGIN

      DIA_OLD := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE('01/' || TO_CHAR(P_FECHA, 'MM/YYYY'), 'DD/MM/YYYY'), -1)),
                         'DD');
      DIA_NEW := TO_CHAR(P_FECHA, 'DD');

      IF DIA_OLD < DIA_NEW THEN
         V_FEC_ANT := LAST_DAY(ADD_MONTHS(TO_DATE('01/' || TO_CHAR(P_FECHA, 'MM/YYYY'), 'DD/MM/YYYY'), -1));
      ELSE
         V_FEC_ANT := ADD_MONTHS(P_FECHA, -1);
      END IF;

      V_FECH_INIC := P_FECHA;

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN
         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_MES   := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_MES);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20002, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DE LOS ULTIMOS 6 MESES DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_6MES(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS
      V_RENT_6MES NUMBER(35, 10);

      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := ADD_MONTHS(P_FECHA, -6);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_6MES  := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_6MES);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20006, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DEL ULTIMO A¿`O DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_ANO(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_1ANO  NUMBER(35, 10);
      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(ADD_MONTHS(P_FECHA, -12));

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_1ANO  := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_1ANO);
      ELSE
         RETURN NULL;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20007, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DE LOS ULTIMOS 2 A¿`OS DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_2ANO(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_2ANO  NUMBER(35, 10);
      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(ADD_MONTHS(P_FECHA, -24));

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_2ANO  := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_2ANO);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20008, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DE LOS ULTIMOS 3 A¿`OS DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_3ANO(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_3ANO  NUMBER(35, 10);
      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(ADD_MONTHS(P_FECHA, -36));

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_3ANO  := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_3ANO);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20009, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DE LOS ULTIMOS 7 DIAS DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_7DIA(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS
      V_RENT_7DIA NUMBER(35, 10);

      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := P_FECHA - 7;

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_7DIA  := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_7DIA);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20006, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD DE LOS ULTIMOS 3 MESES DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_3MES(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS
      V_RENT_3MES NUMBER(35, 10);

      V_FEC_ANT    DATE;
      V_FECH_INIC  DATE;
      V_ANTERIOR   NUMBER(35, 10);
      V_ACTUAL     NUMBER(35, 10);
      V_NDIAS      NUMBER;
      V_RESUL_UNID NUMBER(35, 10);
      V_PROM_DIAS  NUMBER(35, 10);
      V_EXP        NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := ADD_MONTHS(P_FECHA, -3);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
         V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_3MES  := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);

         RETURN(V_RENT_3MES);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20006, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*----------------------------------------------------------------------------------------------
   -- FUNCION QUE VERIFICA CONTINUIDAD EN EL VALOR DEL PATRIMONIO PARA UN FONDO,
   -- CON EL FIN DE NO REPORTAR RENTABILIDAD CUANDO SE TIENEN "HUECOS" EN EL VALOR DE PATRIMONIO
   -- RETORNA:
      TRUE  - SI NO SE TIENEN HUECOS EN EL VALOR DEL PATRIMONIO DEL FONDO EN EL RANGO DE FECHAS
      FALSE - SI SE TIENE AL MENOS UN VALOR DE PATRIMONIO EN CERO DENTRO DEL RANGO DE FECHAS
   ----------------------------------------------------------------------------------------------*/
   FUNCTION FN_VAL_PATRIMONIO_CONTINUO(P_FON_CODIGO    IN VALORIZACIONES_FONDO.VFO_FON_CODIGO%TYPE
                                      ,P_FECHA_INICIAL IN VALORIZACIONES_FONDO.VFO_FECHA_VALORIZACION%TYPE
                                      ,P_FECHA_FINAL   IN VALORIZACIONES_FONDO.VFO_FECHA_VALORIZACION%TYPE)
      RETURN BOOLEAN IS

      -- CURSOR PARA VERIFICAR SI UN FONDO PRESENTA CONTINUIDAD EN EL VALOR DE PATRIMONIO EN UN RANGO DE FECHAS
      CURSOR C_PATRIMONIO_CONTINUO(P_FON_CODIGO    VALORIZACIONES_FONDO.VFO_FON_CODIGO%TYPE
                                  ,P_FECHA_INICIAL VALORIZACIONES_FONDO.VFO_FECHA_VALORIZACION%TYPE
                                  ,P_FECHA_FINAL   VALORIZACIONES_FONDO.VFO_FECHA_VALORIZACION%TYPE) IS
         SELECT COUNT(1)
           FROM VALORIZACIONES_FONDO V
          WHERE V.VFO_FON_CODIGO = P_FON_CODIGO
            AND V.VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA_INICIAL)
            AND V.VFO_FECHA_VALORIZACION < TRUNC(P_FECHA_FINAL)
            AND NVL(V.VFO_CAPITAL, 0) + NVL(VFO_REND_RF, 0) + NVL(VFO_REND_RV, 0) - NVL(VFO_RETENCION, 0) = 0;
      P_CONTADOR NUMBER;

   BEGIN
      P_CONTADOR := 0;
      OPEN C_PATRIMONIO_CONTINUO(P_FON_CODIGO, P_FECHA_INICIAL, P_FECHA_FINAL);
      FETCH C_PATRIMONIO_CONTINUO
         INTO P_CONTADOR;
      CLOSE C_PATRIMONIO_CONTINUO;

      IF NVL(P_CONTADOR, 0) = 0 THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;

   EXCEPTION
      WHEN OTHERS THEN
         RETURN FALSE;
   END FN_VAL_PATRIMONIO_CONTINUO;

   /*------------------------------------------------------------------------------------------------------/
   ::: PROCEDIMIENTO QUE INSERTA REGISTRO DE RENTABILIDADES EN LA TABLA RENTABILIDADES_Y_VOLATILIDADES
   -------------------------------------------------------------------------------------------------------*/

   PROCEDURE INSERTAR_RENTAB(FEC DATE,P_TX IN NUMBER DEFAULT NULL) IS

      CURSOR C_VFO_FONDO(FEC DATE) IS
         SELECT DISTINCT VFO_FON_CODIGO
                        ,TRUNC(VFO_FECHA_VALORIZACION) VFO_FECHA_VALORIZACION
           FROM VALORIZACIONES_FONDO
          WHERE VFO_FECHA_VALORIZACION >= TRUNC(FEC)
            AND VFO_FECHA_VALORIZACION < TRUNC(FEC) + 1
          ORDER BY VFO_FON_CODIGO
                  ,VFO_FECHA_VALORIZACION;

      V_R_DIA         NUMBER;
      V_R_PER_DIA     NUMBER(35, 10);
      V_R_ANO_CORRIDO NUMBER(35, 10);
      V_R_MENS        NUMBER(35, 10);
      V_R_6MENS       NUMBER(35, 10);
      V_R_1ANO        NUMBER(35, 10);
      V_R_2ANO        NUMBER(35, 10);
      V_R_3ANO        NUMBER(35, 10);
      V_R_7DIA        NUMBER(35, 10);
      V_R_3MES        NUMBER(35, 10);

      V_VALORUNI NUMBER;
      V_ACCION   VARCHAR2(100);
      NO_PROCESO EXCEPTION;
      V_REGISTRO NUMBER;
      --VAGTUD937-13 INICIO - JCALDERON
      CURSOR C_FON (FONDO VARCHAR2) IS
         SELECT FON_NOMBRE_EXTRACTO
           FROM FONDOS
          WHERE FON_CODIGO = FONDO;

      VALIDA_CIE     VARCHAR2(1);
      CONT           NUMBER;
      V_CORREOS      VARCHAR2(4000);
      V_FON          FONDOS.FON_NOMBRE_EXTRACTO%TYPE;

      P_CLI_PER_TID_CODIGO NOTIFICACIONES_MAIL_CORREDORES.NMC_CLI_PER_TID_CODIGO%TYPE;
      P_CLI_PER_NUM_IDEN   NOTIFICACIONES_MAIL_CORREDORES.NMC_CLI_PER_NUM_IDEN%TYPE;
      P_SERVICIO           NOTIFICACIONES_MAIL_CORREDORES.NMC_SERVICIO%TYPE;
      P_DE                 NOTIFICACIONES_MAIL_CORREDORES.NMC_DE%TYPE;
      P_PARA               NOTIFICACIONES_MAIL_CORREDORES.NMC_PARA%TYPE;
      P_ASUNTO             NOTIFICACIONES_MAIL_CORREDORES.NMC_ASUNTO%TYPE;
      P_MENSAJE            NOTIFICACIONES_MAIL_CORREDORES.NMC_CUERPO%TYPE;
      P_CLOB               CLOB;
      P_MENSAJE_CLOB       CLOB;
      --VAGTUD937-13 FIN - JCALDERON
      N_ID_PROCESO NUMBER;
      N_TX NUMBER;

   BEGIN
      N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_CALCULO_RENTABILIDAD.INSERTAR_RENTAB');
      V_REGISTRO   := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CALCULO_RENTABILIDAD.INSERTAR_RENTAB', 'INI');

      --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
      N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

      --Registra Traza
      P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                      'I',
                                      'Inicio proceso P_CALCULO_RENTABILIDAD.INSERTAR_RENTAB. Fecha Proceso: ' ||
                                      TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                      N_TX);

      DELETE RENTABILIDADES_Y_VOLATILIDADES
       WHERE RYV_FECHA >= TRUNC(FEC)
         AND RYV_FECHA < TRUNC(FEC) + 1;

      V_R_DIA         := NULL;
      V_R_PER_DIA     := 0;
      V_R_ANO_CORRIDO := NULL;
      V_R_MENS        := NULL;
      V_R_6MENS       := NULL;
      V_R_1ANO        := NULL;
      V_R_2ANO        := NULL;
      V_R_3ANO        := NULL;
      V_R_7DIA        := NULL;
      V_R_3MES        := NULL;
      CONT            := 0;
      V_CORREOS       := NULL;

      FOR R_VFO IN C_VFO_FONDO(FEC) LOOP
         BEGIN

            --VAGTUD937-13 INICIO - JCALDERON
            VALIDA_CIE := P_REPORTES_CLIENTES.PR_VALIDA_CIERRE(R_VFO.VFO_FON_CODIGO,(SYSDATE-1));

            IF VALIDA_CIE = 'S' THEN
            --VAGTUD937-13 FIN - JCALDERON
               P_ORDENES_FONDOS.P_VALOR_UNIDAD_COMPARTIMIENTO(P_FONDO      => R_VFO.VFO_FON_CODIGO,
                                                              P_FECHA      => R_VFO.VFO_FECHA_VALORIZACION,
                                                              VALOR_UNIDAD => V_VALORUNI,
                                                              ACCION       => V_ACCION);

               IF V_VALORUNI = 10000 AND V_ACCION = 'Se_Activa' AND TRUNC(FEC) >= TRUNC(SYSDATE - 1) THEN
                  UPDATE FONDOS
                     SET FON_FECHA_INICIO_PARTICIPACION = R_VFO.VFO_FECHA_VALORIZACION
                   WHERE FON_CODIGO = R_VFO.VFO_FON_CODIGO;
               END IF;

               V_R_DIA         := TRUNC(F_RENT_DIARIA(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_PER_DIA     := TRUNC(F_RENT_PER_DIARIA(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_ANO_CORRIDO := TRUNC(F_RENT_ANO_CORRIDO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_MENS        := TRUNC(F_RENT_ULT_MES(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_6MENS       := TRUNC(F_RENT_ULT_6MES(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_1ANO        := TRUNC(F_RENT_ULT_ANO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_2ANO        := TRUNC(F_RENT_ULT_2ANO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_3ANO        := TRUNC(F_RENT_ULT_3ANO(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_7DIA        := TRUNC(F_RENT_ULT_7DIA(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);
               V_R_3MES        := TRUNC(F_RENT_ULT_3MES(R_VFO.VFO_FECHA_VALORIZACION, R_VFO.VFO_FON_CODIGO), 8);

               INSERT INTO RENTABILIDADES_Y_VOLATILIDADES
                          (RYV_FECHA,
                           RYV_FON_CODIGO,
                           RYV_RENTAB_DIARIA,
                           RYV_RENTAB_DIARIA_PER,
                           RYV_RENTAB_ANO_CORRIDO,
                           RYV_RENTAB_ULT_MES,
                           RYV_RENTAB_ULT_6MES,
                           RYV_RENTAB_ULT_ANO,
                           RYV_RENTAB_ULT_2ANO,
                           RYV_RENTAB_ULT_3ANO,
                           RYV_VOLAT_ANO_CORRIDO,
                           RYV_VOLAT_ULT_MES,
                           RYV_VOLAT_ULT_6MES,
                           RYV_VOLAT_ULT_ANO,
                           RYV_VOLAT_ULT_2ANO,
                           RYV_VOLAT_ULT_3ANO,
                           RYV_RENTAB_ULT_7DIA,
                           RYV_RENTAB_ULT_3MES)
                    VALUES
                          (R_VFO.VFO_FECHA_VALORIZACION,
                           R_VFO.VFO_FON_CODIGO,
                           V_R_DIA,
                           V_R_PER_DIA,
                           V_R_ANO_CORRIDO,
                           V_R_MENS,
                           V_R_6MENS,
                           V_R_1ANO,
                           V_R_2ANO,
                           V_R_3ANO,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           V_R_7DIA,
                           V_R_3MES);
               --VAGTUD937-13 INICIO - JCALDERON
               UPDATE CONFIRMACION_FONDOS_DIA
		          SET CFD_RENTABILIDAD = 'S'
		        WHERE CFD_FON_CODIGO = R_VFO.VFO_FON_CODIGO
		          AND CFD_FECHA     >= TRUNC(FEC)
		          AND CFD_FECHA     <  TRUNC(FEC) + 1;

               COMMIT;

            END IF;

            IF VALIDA_CIE = 'N' THEN

               UPDATE CONFIRMACION_FONDOS_DIA
		          SET CFD_RENTABILIDAD = 'N'
		        WHERE CFD_FON_CODIGO = R_VFO.VFO_FON_CODIGO
		          AND CFD_FECHA     >= TRUNC(FEC)
		          AND CFD_FECHA     <  TRUNC(FEC) + 1;
               COMMIT;

               CONT      := CONT + 1;
               OPEN  C_FON(R_VFO.VFO_FON_CODIGO);
               FETCH C_FON
                INTO V_FON;
               CLOSE C_FON;
               V_CORREOS := V_CORREOS || R_VFO.VFO_FON_CODIGO||' - '||V_FON||'<br/>';

            END IF;
            --VAGTUD937-13 FIN - JCALDERON
         EXCEPTION
            WHEN NO_PROCESO THEN
               RAISE_APPLICATION_ERROR(-200101, 'Error al insertar valor' || SQLERRM);
         END;
      END LOOP;
      --VAGTUD937-13 INICIO - JCALDERON
      IF CONT > 0 THEN
         P_CLI_PER_TID_CODIGO := '0';
         P_CLI_PER_NUM_IDEN   := '0';
         P_SERVICIO           := 'NO_SE_EJECUTO_CIERRE';
         P_DE                 := 'notificaciones@corredores.com';
         P_PARA               := 'jcalderon@corredores.com;ldoncel@corredores.com;ctirado@corredores.com';
         P_ASUNTO             := 'No se generó rentabilidad, ya que no se ha ejecutado el ultimo proceso del cierre';
         P_MENSAJE            := 'No se generó rentabilidad para el fondo o los fondos <br/><br/>'||V_CORREOS||'<br/>Ya que no se ha ejecutado el último proceso del cierre';

         P_NOTIFICACIONES_MAIL.PR_ENVIO_MAIL(P_CLI_PER_TID_CODIGO,
                                             P_CLI_PER_NUM_IDEN,
                                             P_SERVICIO,
                                             P_DE,
                                             P_PARA,
                                             P_ASUNTO,
                                             P_MENSAJE,
                                             P_CLOB,
                                             P_MENSAJE_CLOB);
      END IF;
      --VAGTUD937-13 FIN - JCALDERON
      --Registra Traza
      P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                      'F',
                                      'Fin proceso P_CALCULO_RENTABILIDAD.INSERTAR_RENTAB. Fecha Proceso: ' ||
                                      TO_CHAR(SYSDATE, 'DD-MM-YYYY HH24:mi:ss'),
                                      N_TX);
      V_REGISTRO := P_TOOLS.FN_REGISTRA_PROCESO_NOCTURNO('P_CALCULO_RENTABILIDAD.INSERTAR_RENTAB', 'FIN');
      COMMIT;
   END INSERTAR_RENTAB;

   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD AL INICIO DE UN PERIODO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_INICIO_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_DIA       NUMBER;
      V_FEC_ANT        DATE;
      V_FECH_INIC      DATE;
      V_ANTERIOR       NUMBER(35, 10);
      V_ACTUAL         NUMBER(35, 10);
      V_NDIAS          NUMBER;
      V_RESUL_UNID     NUMBER(35, 10);
      V_PROM_DIAS      NUMBER(35, 10);
      V_EXP            NUMBER;
      V_TASA_EFE       NUMBER(35, 10);
      V_PROM_DIAS_NOM  NUMBER(35, 10);
      V_EXP_NOM        NUMBER(35, 10);
      V_REN_INI_NOM    NUMBER(35, 10);
      NO_PROCESO EXCEPTION;

		CURSOR C_VALORIZACION IS		
			SELECT MIN( VFO_FECHA_VALORIZACION ) + 1 FECHA_ANT
			  FROM VALORIZACIONES_FONDO
			 WHERE VFO_FON_CODIGO = P_FONDO;
		R_VALORIZACION C_VALORIZACION%ROWTYPE;			 

   BEGIN

		OPEN C_VALORIZACION;
		FETCH C_VALORIZACION INTO R_VALORIZACION;
		IF C_VALORIZACION%FOUND THEN
			V_FEC_ANT := R_VALORIZACION.FECHA_ANT;		
		END IF;

      V_FECH_INIC := P_FECHA;

		V_NDIAS      := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
		V_ANTERIOR   := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
		V_ACTUAL     := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
		V_RESUL_UNID := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
		V_PROM_DIAS  := TRUNC((365 / V_NDIAS), 8);
		V_EXP        := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
		V_RENT_DIA   := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
		V_TASA_EFE      := 1+(V_RENT_DIA/100);
        V_PROM_DIAS_NOM := V_NDIAS / 365;
        V_EXP_NOM       := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
        V_REN_INI_NOM   := ROUND((V_EXP_NOM * 100),2);

        RETURN(V_REN_INI_NOM);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20003, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;

   END F_RENT_INICIO_NOM;
   /*--------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMINAL DIARIA DE UN FONDO
   --------------------------------------------------------------------------------*/
   FUNCTION F_RENT_DIARIA_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_DIA       NUMBER;
      V_FEC_ANT        DATE;
      V_FECH_INIC      DATE;
      V_ANTERIOR       NUMBER(35, 10);
      V_ACTUAL         NUMBER(35, 10);
      V_NDIAS          NUMBER;
      V_RESUL_UNID     NUMBER(35, 10);
      V_PROM_DIAS      NUMBER(35, 10);
      V_EXP            NUMBER;
      V_TASA_EFE       NUMBER(35, 10);
      V_PROM_DIAS_NOM  NUMBER(35, 10);
      V_EXP_NOM        NUMBER(35, 10);
      V_REN_DIA_NOM    NUMBER(35, 10);
      NO_PROCESO       EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(P_FECHA - 1);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_DIA      := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE      := 1+(V_RENT_DIA/100);
         V_PROM_DIAS_NOM := V_NDIAS / 365;
         V_EXP_NOM       := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_DIA_NOM   := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_DIA_NOM);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20010, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMINAL DEL ULTIMO MES DE UN FONDO
   ---------------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_MES_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_MES       NUMBER(35, 10);
      V_FEC_ANT        DATE;
      V_FECH_INIC      DATE;
      V_ANTERIOR       NUMBER(35, 10);
      V_ACTUAL         NUMBER(35, 10);
      V_NDIAS          NUMBER;
      V_RESUL_UNID     NUMBER(35, 10);
      V_PROM_DIAS      NUMBER(35, 10);
      V_EXP            NUMBER(35, 10);
      V_TASA_EFE       NUMBER(35, 10);
      V_PROM_DIAS_NOM  NUMBER(35, 10);
      V_EXP_NOM        NUMBER(35, 10);
      V_REN_MES_NOM    NUMBER(35, 10);
      NO_PROCESO       EXCEPTION;
      DIA_OLD          NUMBER;
      DIA_NEW          NUMBER;

   BEGIN

      DIA_OLD := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE('01/' || TO_CHAR(P_FECHA, 'MM/YYYY'), 'DD/MM/YYYY'), -1)),'DD');
      DIA_NEW := TO_CHAR(P_FECHA, 'DD');

      IF DIA_OLD < DIA_NEW THEN
         V_FEC_ANT := LAST_DAY(ADD_MONTHS(TO_DATE('01/' || TO_CHAR(P_FECHA, 'MM/YYYY'), 'DD/MM/YYYY'), -1));
      ELSE
         V_FEC_ANT := ADD_MONTHS(P_FECHA, -1);
      END IF;

      V_FECH_INIC := P_FECHA;

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN
         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_MES      := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE      := 1+(V_RENT_MES/100);
         V_PROM_DIAS_NOM := V_NDIAS / 365;
         V_EXP_NOM       := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_MES_NOM   := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_MES_NOM);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20011, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*----------------------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMINAL DE LOS ULTIMOS 3 MESES DE UN FONDO
   -----------------------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_3MES_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_3MES       NUMBER(35, 10);
      V_FEC_ANT         DATE;
      V_FECH_INIC       DATE;
      V_ANTERIOR        NUMBER(35, 10);
      V_ACTUAL          NUMBER(35, 10);
      V_NDIAS           NUMBER;
      V_RESUL_UNID      NUMBER(35, 10);
      V_PROM_DIAS       NUMBER(35, 10);
      V_EXP             NUMBER(35, 10);
      V_TASA_EFE        NUMBER(35, 10);
      V_PROM_DIAS_NOM   NUMBER(35, 10);
      V_EXP_NOM         NUMBER(35, 10);
      V_REN_3MES_NOM    NUMBER(35, 10);
      NO_PROCESO        EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := ADD_MONTHS(P_FECHA, -3);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_3MES     := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE      := 1+(V_RENT_3MES/100);
         V_PROM_DIAS_NOM := V_NDIAS / 365;
         V_EXP_NOM       := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_3MES_NOM  := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_3MES_NOM);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20012, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*----------------------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMINAL DE LOS ULTIMOS 6 MESES DE UN FONDO
   -----------------------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_6MES_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_6MES       NUMBER(35, 10);
      V_FEC_ANT         DATE;
      V_FECH_INIC       DATE;
      V_ANTERIOR        NUMBER(35, 10);
      V_ACTUAL          NUMBER(35, 10);
      V_NDIAS           NUMBER;
      V_RESUL_UNID      NUMBER(35, 10);
      V_PROM_DIAS       NUMBER(35, 10);
      V_EXP             NUMBER(35, 10);
      V_TASA_EFE        NUMBER(35, 10);
      V_PROM_DIAS_NOM   NUMBER(35, 10);
      V_EXP_NOM         NUMBER(35, 10);
      V_REN_6MES_NOM    NUMBER(35, 10);
      NO_PROCESO        EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := ADD_MONTHS(P_FECHA, -6);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_6MES     := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE      := 1+(V_RENT_6MES/100);
         V_PROM_DIAS_NOM := V_NDIAS / 365;
         V_EXP_NOM       := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_6MES_NOM  := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_6MES_NOM);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20013, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*--------------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMINAL DEL ULTIMO A¿`O DE UN FONDO
   ----------------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ULT_ANO_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_1ANO       NUMBER(35, 10);
      V_FEC_ANT         DATE;
      V_FECH_INIC       DATE;
      V_ANTERIOR        NUMBER(35, 10);
      V_ACTUAL          NUMBER(35, 10);
      V_NDIAS           NUMBER;
      V_RESUL_UNID      NUMBER(35, 10);
      V_PROM_DIAS       NUMBER(35, 10);
      V_EXP             NUMBER(35, 10);
      V_TASA_EFE        NUMBER(35, 10);
      V_PROM_DIAS_NOM   NUMBER(35, 10);
      V_EXP_NOM         NUMBER(35, 10);
      V_REN_1ANO_NOM    NUMBER(35, 10);
      NO_PROCESO        EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(ADD_MONTHS(P_FECHA, -12));

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_1ANO     := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE      := 1+(V_RENT_1ANO/100);
         V_PROM_DIAS_NOM := V_NDIAS / 365;
         V_EXP_NOM       := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_1ANO_NOM  := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_1ANO_NOM);
      ELSE
         RETURN NULL;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20014, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

   /*-----------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMINAL MES CORRIDO DE UN FONDO
   -------------------------------------------------------------------------------------*/
   FUNCTION F_RENT_MES_CORRIDO_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_MES_CORR       NUMBER(35, 10);
      V_FEC_ANT             DATE;
      V_FECH_INIC           DATE;
      V_ANTERIOR            NUMBER(35, 10);
      V_ACTUAL              NUMBER(35, 10);
      V_NDIAS               NUMBER;
      V_RESUL_UNID          NUMBER(35, 10);
      V_PROM_DIAS           NUMBER(35, 10);
      V_EXP                 NUMBER(35, 10);
      V_TASA_EFE            NUMBER(35, 10);
      V_PROM_DIAS_NOM       NUMBER(35, 10);
      V_EXP_NOM             NUMBER(35, 10);
      V_REN_MES_CORRIDO_NOM NUMBER(35, 10);
      NO_PROCESO            EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := LAST_DAY(ADD_MONTHS(TO_DATE(P_FECHA,'DD-MM-YYYY'),-1));

         V_NDIAS                := TO_DATE(V_FECH_INIC, 'DD-MM-YY') - TO_DATE(V_FEC_ANT, 'DD-MM-YY');
         V_ANTERIOR             := TRUNC(F_VALOR_FONDO(TO_DATE(V_FEC_ANT, 'DD-MM-YY'), P_FONDO), 8);
         V_ACTUAL               := TRUNC(F_VALOR_FONDO(TO_DATE(V_FECH_INIC, 'DD-MM-YY'), P_FONDO), 8);
         V_RESUL_UNID           := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS            := TRUNC(1/(V_NDIAS / 365), 8);
         V_EXP                  := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_MES_CORR        := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE             := 1+(V_RENT_MES_CORR/100);
         V_PROM_DIAS_NOM        := V_NDIAS / 365;
         V_EXP_NOM              := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_MES_CORRIDO_NOM  := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_MES_CORRIDO_NOM);

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20015, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END F_RENT_MES_CORRIDO_NOM;

   /*------------------------------------------------------------------------------------/
   ::: FUNCION QUE RETORNA EL CALCULO DE LA RENTABILIDAD NOMIMAL A¿`O CORRIDO DE UN FONDO
   -------------------------------------------------------------------------------------*/
   FUNCTION F_RENT_ANO_CORRIDO_NOM(P_FECHA DATE, P_FONDO VARCHAR2) RETURN NUMBER IS

      V_RENT_ANO_CORR       NUMBER(35, 10);
      V_FEC_ANT             DATE;
      V_FECH_INIC           DATE;
      V_ANTERIOR            NUMBER(35, 10);
      V_ACTUAL              NUMBER(35, 10);
      V_NDIAS               NUMBER;
      V_RESUL_UNID          NUMBER(35, 10);
      V_PROM_DIAS           NUMBER(35, 10);
      V_EXP                 NUMBER(35, 10);
      V_TASA_EFE            NUMBER(35, 10);
      V_PROM_DIAS_NOM       NUMBER(35, 10);
      V_EXP_NOM             NUMBER(35, 10);
      V_REN_ANO_CORRIDO_NOM NUMBER(35, 10);
      NO_PROCESO            EXCEPTION;

   BEGIN

      V_FECH_INIC := P_FECHA;
      V_FEC_ANT   := TRUNC(TO_DATE('01' || '/' || '01' || '/' || TO_CHAR(P_FECHA, 'YYYY'), 'DD/MM/YYYY') - 1);

      IF FN_VAL_PATRIMONIO_CONTINUO(P_FONDO, V_FEC_ANT, V_FECH_INIC) THEN

         V_NDIAS         := TRUNC(P_FECHA) - TRUNC(V_FEC_ANT);
         V_ANTERIOR      := TRUNC(F_VALOR_FONDO(V_FEC_ANT, P_FONDO), 8);
         V_ACTUAL        := TRUNC(F_VALOR_FONDO(V_FECH_INIC, P_FONDO), 8);
         V_RESUL_UNID    := TRUNC(NVL((V_ACTUAL / V_ANTERIOR), 0), 8);
         V_PROM_DIAS     := TRUNC((365 / V_NDIAS), 8);
         V_EXP           := TRUNC(POWER(V_RESUL_UNID, V_PROM_DIAS), 8);
         V_RENT_ANO_CORR := ROUND(TRUNC((V_EXP - 1) * 100, 8), 4);
         V_TASA_EFE             := 1+(V_RENT_ANO_CORR/100);
         V_PROM_DIAS_NOM        := V_NDIAS / 365;
         V_EXP_NOM              := POWER(V_TASA_EFE,V_PROM_DIAS_NOM)-1;
         V_REN_ANO_CORRIDO_NOM  := ROUND((V_EXP_NOM * 100),2);

         RETURN(V_REN_ANO_CORRIDO_NOM);
      ELSE
         RETURN NULL;
      END IF;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN 0;
      WHEN ZERO_DIVIDE THEN
         RETURN 0;
      WHEN NO_PROCESO THEN
         RAISE_APPLICATION_ERROR(-20016, 'Error' || SQLERRM);
      WHEN OTHERS THEN
         RETURN NULL;
   END;

END P_CALCULO_RENTABILIDAD;

/

  GRANT EXECUTE ON "PROD"."P_CALCULO_RENTABILIDAD" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_CALCULO_RENTABILIDAD" TO "COE_RECURSOS";
