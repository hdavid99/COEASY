--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_GRP_RELACIONADOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_GRP_RELACIONADOS" AS
  /* Descripcion: Paquete para la administracion de Grupos Relacionados
     Modulo Relacionado: GRPREL.fmb
     Fecha Creacion: 08/11/2017*/
 -- 18/01/2018 Actualizacion --    
PROCEDURE PR_CLIENTES AS
 -- ------------------------------------------------------------------------- --
 -- Descripcion: Crea los grupos de los clientes que aun no tienen grupo creado
 -- ------------------------------------------------------------------------- --
 	CONSECUTIVO VARCHAR2(5);
  CLIENTE VARCHAR2(15);
  TID_CLIENTE VARCHAR2(3);

---VALIDA QUE LOS CLIENTES AUN NO TENGAN GRUPO
  CURSOR C_CLIENTES IS
     SELECT CLI_PER_NUM_IDEN, CLI_PER_TID_CODIGO, COUNT(1)
       FROM CLIENTES ,PERSONAS_RELACIONADAS PR
      WHERE RLC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
        AND PR.RLC_CLI_PER_TID_CODIGO = CLIENTES.CLI_PER_TID_CODIGO
        AND RLC_ESTADO = 'A'
        AND CLI_ECL_MNEMONICO <> 'INA'
        AND CLI_PER_NUM_IDEN NOT IN (SELECT GRL_CLI_PER_NUM_IDEN FROM GRUPOS_RELACIONADOS)
      GROUP BY CLI_PER_NUM_IDEN, CLI_PER_TID_CODIGO
     HAVING COUNT(1) > 1;


 
BEGIN

   FOR X IN C_CLIENTES LOOP
      CLIENTE := X.CLI_PER_NUM_IDEN;
      TID_CLIENTE := x.CLI_PER_TID_CODIGO;
      
      PR_CREA_GRUPOS(CLIENTE, TID_CLIENTE);
 
   END LOOP;
  
  EXCEPTION WHEN OTHERS THEN 
    PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS', 'ERROR SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM);
    P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_GRP_RELACIONADOS.P_CREA_GRUPOS'
                                 ,P_ERROR       => 'ERROR  SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                                 ,P_TABLA_ERROR => 'P_CREA_GRUPOS');
  END PR_CLIENTES;


/* ******************************************************** */
 PROCEDURE PR_CREA_GRUPOS(P_CLI_PER_NUM_IDEN VARCHAR2, P_CLI_PER_TID_CODIGO VARCHAR2)
 IS
  CONSECUTIVO VARCHAR2(5);
  CLIENTE VARCHAR2(15);
  TID_CLIENTE VARCHAR2(3);
  
  CURSOR C_DATOS1 IS
  ---1, 
     SELECT RLC_CLI_PER_TID_CODIGO TID_CLI, RLC_CLI_PER_NUM_IDEN CLIENTE,  
            RLC_PER_TID_CODIGO TID_RLC, RLC_PER_NUM_IDEN NUMIDEN_RLC, RLC_ROL_CODIGO ROL_RLC
       FROM PERSONAS_RELACIONADAS PR
      WHERE (RLC_CLI_PER_NUM_IDEN = CLIENTE---cliente
        AND PR.RLC_CLI_PER_TID_CODIGO = TID_CLIENTE
        AND  RLC_PER_NUM_IDEN = CLIENTE)
        AND  NVL(RLC_ES_FUNCIONARIO,'N') = 'N'
        AND  RLC_ESTADO = 'A'       
   ;

  CURSOR C_DATOS2 IS
  ---2, 
    SELECT  RLC_CLI_PER_TID_CODIGO TID_CLI, RLC_CLI_PER_NUM_IDEN CLIENTE,  
            RLC_PER_TID_CODIGO TID_RLC, RLC_PER_NUM_IDEN NUMIDEN_RLC,  RLC_ROL_CODIGO ROL_RLC
      FROM PERSONAS_RELACIONADAS PR
     WHERE (RLC_CLI_PER_NUM_IDEN = CLIENTE---cliente
       AND PR.RLC_CLI_PER_TID_CODIGO = TID_CLIENTE
       AND  RLC_PER_NUM_IDEN <> CLIENTE)
       AND  NVL(RLC_ES_FUNCIONARIO,'N') = 'N'
       AND RLC_ESTADO = 'A'
    ;

---3,
  CURSOR C_DATOS3 IS
     SELECT DISTINCT RLC_CLI_PER_TID_CODIGO TID_CLI, RLC_CLI_PER_NUM_IDEN CLIENTE,  RLC_PER_TID_CODIGO TID_RLC, 
            RLC_PER_NUM_IDEN NUMIDEN_RLC
       FROM PERSONAS_RELACIONADAS PR
      WHERE (RLC_CLI_PER_NUM_IDEN <> CLIENTE---cliente
        AND RLC_PER_TID_CODIGO = TID_CLIENTE
        AND  RLC_PER_NUM_IDEN = CLIENTE)
        AND  NVL(RLC_ES_FUNCIONARIO,'N') = 'N'
        AND RLC_ESTADO = 'A'
        AND ( RLC_PER_TID_CODIGO, RLC_PER_NUM_IDEN,RLC_CLI_PER_TID_CODIGO, RLC_CLI_PER_NUM_IDEN) NOT IN 
             (SELECT DGRL_GRL_CLI_PER_TID_CODIGO, DGRL_GRL_CLI_PER_NUM_IDEN, DGRL_PER_TID_CODIGO, DGRL_PER_NUM_IDEN
                FROM DETALLE_GRP_RELACIONADOS 
                WHERE DGRL_GRL_CLI_PER_TID_CODIGO = TID_CLIENTE
                  AND  DGRL_GRL_CLI_PER_NUM_IDEN = CLIENTE)
    ;

BEGIN

   CLIENTE := P_CLI_PER_NUM_IDEN;
   TID_CLIENTE := P_CLI_PER_TID_CODIGO;
    
    --INSERTA GRUPO Y TITULAR
      BEGIN
        SELECT NVL(TO_NUMBER(MAX(GRL_CODIGO_GRUPO)),0)+1
          INTO CONSECUTIVO
          FROM GRUPOS_RELACIONADOS;
      
      EXCEPTION WHEN NO_DATA_FOUND THEN
        CONSECUTIVO := '1';
        P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_GRP_RELACIONADOS.CREACION'
                                     ,P_ERROR       => 'CONSECUTIVO SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                                     ,P_TABLA_ERROR => 'GRUPOS_RELACIONADOS');
      END;
       
      INSERT INTO  GRUPOS_RELACIONADOS
      VALUES(CLIENTE,TID_CLIENTE, LPAD(TO_CHAR(CONSECUTIVO),5,0));
      COMMIT;
      
      --INSERTA DETALLE DE GRUPO DEL TITULAR
      FOR A IN C_DATOS1 LOOP
         BEGIN
            INSERT INTO DETALLE_GRP_RELACIONADOS
            VALUES(CLIENTE,TID_CLIENTE,LPAD(TO_CHAR(CONSECUTIVO),5,0),1,A.NUMIDEN_RLC,A.TID_RLC);
            COMMIT;
         EXCEPTION WHEN OTHERS THEN
            P_OPERACIONES.INSERTA_ERROR ( P_PROCESO   => 'P_GRP_RELACIONADOS.CREACION'
                                       ,P_ERROR       => 'INSERT 1 SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                                       ,P_TABLA_ERROR => 'DETALLE_GRP_RELACIONADOS');
          END;
       END LOOP;
       COMMIT;
     
      --INSERTA DETALLE DE GRUPO DE PERSONA RELACIONADA
       FOR X IN C_DATOS2 LOOP
           BEGIN
             INSERT INTO DETALLE_GRP_RELACIONADOS
             VALUES(X.CLIENTE,X.TID_CLI,LPAD(TO_CHAR(CONSECUTIVO),5,0),2, X.NUMIDEN_RLC,X.TID_RLC);
         
           COMMIT;
           
           EXCEPTION WHEN OTHERS THEN
             P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_GRP_RELACIONADOS.CREACION'
                         ,P_ERROR       => 'INSERT 2 SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                         ,P_TABLA_ERROR => 'DETALLE_GRP_RELACIONADOS');
           END;
          END LOOP; 
       
        --INSERTA DETALLE DE GRUPO DE TITULAR-ORDENANTE  
       FOR Z IN C_DATOS3 LOOP--SE GRABA AL REVES  
           BEGIN
             INSERT INTO DETALLE_GRP_RELACIONADOS
             VALUES(CLIENTE,TID_CLIENTE,LPAD(TO_CHAR(CONSECUTIVO),5,0),3,Z.CLIENTE,Z.TID_CLI);
             COMMIT;
           
           EXCEPTION WHEN OTHERS THEN
           PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('DETALLE_GRP_RELACION', 'INSERT 3 SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM);
              P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_GRP_RELACIONADOS.CREACION'
                                           ,P_ERROR       => 'INSERT 3 SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                                           ,P_TABLA_ERROR => 'DETALLE_GRP_RELACIONADOS');
           END;
       END LOOP;
       COMMIT;
   
  
  EXCEPTION WHEN OTHERS THEN 
    PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS', 'ERROR  SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM);
    P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_GRP_RELACIONADOS.P_CREA_GRUPOS_NUEVOS'
                                 ,P_ERROR       => 'ERROR  SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                                 ,P_TABLA_ERROR => 'P_CREA_GRUPOS_NUEVOS');
 
 END PR_CREA_GRUPOS;

/* ********************************************************* */

PROCEDURE PR_ACTUALIZA_GRUPOS(P_FECHA DATE) AS
 -- ------------------------------------------------------------------------- --
 -- Descripcion: Actualiza los grupos de los clientes que cambian de estado
 -- ------------------------------------------------------------------------- --
V_FECHA DATE;
CONT NUMBER;
V_GRUPO VARCHAR2(5);

--CLIENTES INACTIVADOS
  CURSOR C_INACTIVA(FECHA DATE)IS
      SELECT CAC_CLI_PER_NUM_IDEN NUM_IDEN, CAC_CLI_PER_TID_CODIGO TID_CODIGO
        FROM CONTROL_ACTUALIZACIONES
       WHERE CAC_TABLA = 'CLIENTES'
         AND CAC_COLUMNA = 'CLI_ECL_MNEMONICO'
         AND CAC_FECHA_ACTUALIZACION >= TRUNC(FECHA)
         AND CAC_FECHA_ACTUALIZACION < TRUNC(FECHA)+1
         AND CAC_VALOR_ACTUAL = 'INA';
         
    ---CLIENTES DE INACTIVO A ACTIVOS     
    CURSOR C_ACTIVA(FECHA DATE)IS
      SELECT CAC_CLI_PER_NUM_IDEN NUM_IDEN, CAC_CLI_PER_TID_CODIGO TID_CODIGO
        FROM CONTROL_ACTUALIZACIONES
       WHERE CAC_TABLA = 'CLIENTES'
         AND CAC_COLUMNA = 'CLI_ECL_MNEMONICO'
         AND CAC_FECHA_ACTUALIZACION >= TRUNC(FECHA)
         AND CAC_FECHA_ACTUALIZACION < TRUNC(FECHA)+1
         AND CAC_VALOR_ACTUAL = 'ACC'
         AND CAC_VALOR_ANTERIOR = 'INA';          

  CURSOR C_REGISTROS(NUM_IDEN VARCHAR2,TID_CODIGO VARCHAR2) IS
      SELECT DGRL_TPRG_CODIGO_TIPO_RELACION,DGRL_GRL_CODIGO_GRUPO
        FROM  DETALLE_GRP_RELACIONADOS
       WHERE DGRL_PER_NUM_IDEN = NUM_IDEN
         AND DGRL_PER_TID_CODIGO = TID_CODIGO 
       ;
       
    ---CLIENTES      
     CURSOR C_RELACIONADOS(PER_NUM_IDEN VARCHAR2,PER_TID_CODIGO VARCHAR2) IS
        SELECT  RLC_CLI_PER_TID_CODIGO TID_CLI, RLC_CLI_PER_NUM_IDEN CLIENTE,  
                RLC_PER_TID_CODIGO TID, RLC_PER_NUM_IDEN NUMIDEN,RLC_ROL_CODIGO ROL_RLC
          FROM PERSONAS_RELACIONADAS PR
         WHERE RLC_PER_NUM_IDEN = PER_NUM_IDEN--persona relacionada
           AND RLC_PER_TID_CODIGO = PER_TID_CODIGO
           AND NVL(RLC_ES_FUNCIONARIO,'N') = 'N'
           AND RLC_ESTADO = 'A'
           AND RLC_CLI_PER_NUM_IDEN <>  RLC_PER_NUM_IDEN
           AND (RLC_CLI_PER_NUM_IDEN, RLC_PER_NUM_IDEN) NOT IN (SELECT DGRL_GRL_CLI_PER_NUM_IDEN,DGRL_PER_NUM_IDEN 
                                                                  FROM DETALLE_GRP_RELACIONADOS)
          ; 

     CURSOR C_ORDENANTES IS
        SELECT DISTINCT RLC_CLI_PER_TID_CODIGO TID_CLI, RLC_CLI_PER_NUM_IDEN CLIENTE,  
                RLC_PER_TID_CODIGO TID_REL, RLC_PER_NUM_IDEN NUMIDEN_REL,RLC_ROL_CODIGO ROL_RLC
          FROM PERSONAS_RELACIONADAS PR
         WHERE  NVL(RLC_ES_FUNCIONARIO,'N') = 'N'
           AND RLC_ESTADO = 'A'
           AND RLC_FECHA_CAMBIO_ESTADO >= TRUNC(V_FECHA)
           AND RLC_FECHA_CAMBIO_ESTADO < TRUNC(V_FECHA) +1
           AND RLC_CLI_PER_NUM_IDEN IN (SELECT DGRL_GRL_CLI_PER_NUM_IDEN FROM DETALLE_GRP_RELACIONADOS)
           AND (RLC_CLI_PER_NUM_IDEN, RLC_PER_NUM_IDEN) NOT IN (SELECT DGRL_GRL_CLI_PER_NUM_IDEN,DGRL_PER_NUM_IDEN 
                                                                FROM DETALLE_GRP_RELACIONADOS)
          ;

BEGIN
--  a.	Inactivación de un ordenante: El ordenante que se inactive debe ser eliminado del grupo.   
--b.	Inactivar el Cliente: Si el cliente es un titular  de un grupo relacionado,  el Grupo no deberá salir en las búsquedas de grupos relacionados. 
V_FECHA := P_FECHA;

      FOR X IN C_INACTIVA(V_FECHA) LOOP
          FOR Z IN  C_REGISTROS(X.NUM_IDEN ,X.TID_CODIGO) LOOP
          --VEMOS LA CANTIDAD DE INTEGRANTES DEL GRUPO
              SELECT COUNT(1) INTO CONT
                FROM DETALLE_GRP_RELACIONADOS
               WHERE DGRL_GRL_CODIGO_GRUPO = Z.DGRL_GRL_CODIGO_GRUPO
                ;
            
            IF CONT >= 3 AND Z.DGRL_TPRG_CODIGO_TIPO_RELACION <> 1 THEN
            --TIENE MAS DE 3 INTEGRANTES Y EL CLIENTE INACTIVADO NO ES EL TITULAR
                PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS','INGRESO A LOOP1:'||X.NUM_IDEN||' REGISTROS: '||CONT||' grupo:'||Z.DGRL_GRL_CODIGO_GRUPO);
                  DELETE FROM DETALLE_GRP_RELACIONADOS
                  WHERE DGRL_PER_NUM_IDEN = X.NUM_IDEN
                    AND DGRL_PER_TID_CODIGO = X.TID_CODIGO 
                    AND DGRL_GRL_CODIGO_GRUPO = Z.DGRL_GRL_CODIGO_GRUPO
                    AND DGRL_TPRG_CODIGO_TIPO_RELACION <> 1;
                     PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS-DEL',X.NUM_IDEN);
           ELSE            
              IF CONT <= 2 OR Z.DGRL_TPRG_CODIGO_TIPO_RELACION = 1 THEN
              ---VALIDA QUE SI TIENE 2 INTEGRANTES, AL QUEDAR CON 1, SE ELIMINA EL GRUPO
              ---EL CLIENTE INACTIVADO ES EL TITULAR, SE ELIMINA EL GRUPO
               PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS','INGRESO A LOOP2:'||X.NUM_IDEN||' REGISTROS: '||CONT||' grupo:'||Z.DGRL_GRL_CODIGO_GRUPO);
                 ---SE BORRA EL DETALLE
                    DELETE FROM DETALLE_GRP_RELACIONADOS
                    WHERE DGRL_GRL_CODIGO_GRUPO = Z.DGRL_GRL_CODIGO_GRUPO
                      ;
                   
                 ---SE BORRA EL GRUPO
                   DELETE FROM GRUPOS_RELACIONADOS
                    WHERE GRL_CODIGO_GRUPO = Z.DGRL_GRL_CODIGO_GRUPO
                      ;   
                      PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS-DEL',X.NUM_IDEN);
              END IF; 
          END IF; 
          COMMIT;
        END LOOP; 
      END LOOP;    
   COMMIT;

--   c.	Activación de un cliente en estado inactivo: El sistema debe crear el grupo. 
--   d.	Activación de un Ordenante en estado inactivo: Actualizar el grupo del Cliente. 
      FOR T IN C_ACTIVA(V_FECHA) LOOP
          PR_CREA_GRUPOS(T.NUM_IDEN, T.TID_CODIGO);
          FOR CR IN C_RELACIONADOS(T.NUM_IDEN, T.TID_CODIGO) LOOP
          
              BEGIN
                 SELECT GRL_CODIGO_GRUPO
                   INTO V_GRUPO
                   FROM GRUPOS_RELACIONADOS 
                  WHERE GRL_CLI_PER_NUM_IDEN = CR.CLIENTE 
                    AND GRL_CLI_PER_TID_CODIGO = CR.TID_CLI;
             
                  INSERT INTO DETALLE_GRP_RELACIONADOS
                  VALUES(T.NUM_IDEN, T.TID_CODIGO,V_GRUPO,2,CR.CLIENTE,CR.TID_CLI);
             
              EXCEPTION WHEN NO_DATA_FOUND THEN
                 NULL;
                WHEN OTHERS THEN
                  PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS','INSERT 1:'||V_GRUPO);
               END;        
            END LOOP;
      
      END LOOP;

--f.	Se cree un nuevo ordenante: Si el titular de un grupo registra un nuevo ordenante, el sistema deberá  incluir el ordenante dentro del grupo relacionado del titular.  
         FOR CLI_R IN C_ORDENANTES LOOP
              BEGIN
                 SELECT GRL_CODIGO_GRUPO
                   INTO V_GRUPO
                   FROM GRUPOS_RELACIONADOS 
                  WHERE GRL_CLI_PER_NUM_IDEN = CLI_R.CLIENTE 
                    AND GRL_CLI_PER_TID_CODIGO = CLI_R.TID_CLI;
             
                  INSERT INTO DETALLE_GRP_RELACIONADOS
                  VALUES(CLI_R.CLIENTE,CLI_R.TID_CLI,V_GRUPO,2,CLI_R.NUMIDEN_REL,CLI_R.TID_REL);
             
              EXCEPTION WHEN NO_DATA_FOUND THEN
                  NULL;
               WHEN OTHERS THEN
                  PROD.P_SEGUIMIENTO.PR_SEGUIMIENTO('GRP_RELACIONADOS','INSERT 2: '||V_GRUPO);
               END;        
      
      END LOOP;

--g.	Clientes nuevos: el sistema debe crear el grupo (si aplica) cuando se cree el cliente. Cuando no aplica??? Se entenderá creado el grupo cuando el cliente tenga al menos un ordenante de lo contrario no aplica. 
--> Los clientes nuevos se crean con el proceso de Creacion de grupos


 EXCEPTION WHEN OTHERS THEN
     P_OPERACIONES.INSERTA_ERROR ( P_PROCESO     => 'P_GRP_RELACIONADOS.P_ACTUALIZA_GRUPOS'
                                 ,P_ERROR       => 'ERROR SQLCODE: '||SQLCODE||', SQLERRM: '||SQLERRM
                                 ,P_TABLA_ERROR => 'P_ACTUALIZA_GRUPOS');
END PR_ACTUALIZA_GRUPOS;

END P_GRP_RELACIONADOS;

/

  GRANT EXECUTE ON "PROD"."P_GRP_RELACIONADOS" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_GRP_RELACIONADOS" TO "SIS_SISTEMAS";
