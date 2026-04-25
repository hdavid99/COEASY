--------------------------------------------------------
--  File created - Saturday-April-25-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body P_CLIENTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "PROD"."P_CLIENTES" IS
  -- Sub-Program Units
  /* Determina si un digito de control es valido para un nit dado */
  -- PL/SQL Block
  -- Sub-Program Units
  FUNCTION PR_DIGITO_CONTROL(NIT IN VARCHAR2, DCHEQUEO IN NUMBER)
    RETURN BOOLEAN IS
    -- PL/SQL Specification
    -- PL/SQL Block
    /* Calcula el digito de Control con base en el siguiente algoritmo:
       Puede ser calculado para cifras cuyo numero maximo de digitos es 15.
       De acuerdo con la posicion que ocupe el digito, se multiplica por
       el numero localizado en el vector correspondiente.
       D= 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01
       P= 71 67 59 53 47 43 41 37 29 23 19 17 13 07 03
       Una vez obtenido el acumulado, se calcula el residuo del acumulado
       modulo 11. Si el residuo = 0 => digito chequeo = 0
             Si el residuo = 1 => digito chequeo = 1
             De lo contrario   => digito chequeo = 11 - residuo;
    */
    digito1  constant NUMBER(2) := 3;
    digito2  constant NUMBER(2) := 7;
    digito3  constant NUMBER(2) := 13;
    digito4  constant NUMBER(2) := 17;
    digito5  constant NUMBER(2) := 19;
    digito6  constant NUMBER(2) := 23;
    digito7  constant NUMBER(2) := 29;
    digito8  constant NUMBER(2) := 37;
    digito9  constant NUMBER(2) := 41;
    digito10 constant NUMBER(2) := 43;
    digito11 constant NUMBER(2) := 47;
    digito12 constant NUMBER(2) := 53;
    digito13 constant NUMBER(2) := 59;
    digito14 constant NUMBER(2) := 67;
    digito15 constant NUMBER(2) := 71;
    longitud  NUMBER(2);
    acumula   NUMBER(8);
    residuo   NUMBER(2);
    Vdchequeo number(2);
    -- PL/SQL Block
  begin
    longitud := length(nit);
    if longitud > 0 then
      acumula := digito1 * substr(nit, longitud, 1);
    end if;
    if longitud > 1 then
      acumula := acumula + digito2 * substr(nit, longitud - 1, 1);
    end if;
    if longitud > 2 then
      acumula := acumula + digito3 * substr(nit, longitud - 2, 1);
    end if;
    if longitud > 3 then
      acumula := acumula + digito4 * substr(nit, longitud - 3, 1);
    end if;
    if longitud > 4 then
      acumula := acumula + digito5 * substr(nit, longitud - 4, 1);
    end if;
    if longitud > 5 then
      acumula := acumula + digito6 * substr(nit, longitud - 5, 1);
    end if;
    if longitud > 6 then
      acumula := acumula + digito7 * substr(nit, longitud - 6, 1);
    end if;
    if longitud > 7 then
      acumula := acumula + digito8 * substr(nit, longitud - 7, 1);
    end if;
    if longitud > 8 then
      acumula := acumula + digito9 * substr(nit, longitud - 8, 1);
    end if;
    if longitud > 9 then
      acumula := acumula + digito10 * substr(nit, longitud - 9, 1);
    end if;
    if longitud > 10 then
      acumula := acumula + digito11 * substr(nit, longitud - 10, 1);
    end if;
    if longitud > 11 then
      acumula := acumula + digito12 * substr(nit, longitud - 11, 1);
    end if;
    if longitud > 12 then
      acumula := acumula + digito13 * substr(nit, longitud - 12, 1);
    end if;
    if longitud > 13 then
      acumula := acumula + digito14 * substr(nit, longitud - 13, 1);
    end if;
    if longitud > 14 then
      acumula := acumula + digito15 * substr(nit, longitud - 14, 1);
    end if;
    residuo := acumula MOD 11;
    if residuo != 0 and residuo != 1 then
      Vdchequeo := 11 - residuo;
    else
      Vdchequeo := residuo;
    end if;
    return(Vdchequeo = dchequeo);
  END PR_DIGITO_CONTROL;
  FUNCTION RT_DIGITO_CONTROL(NIT IN NUMBER) RETURN NUMBER IS
    -- PL/SQL Specification
    -- PL/SQL Block
    /* Calcula el digito de Control con base en el siguiente algoritmo:
       Puede ser calculado para cifras cuyo numero maximo de digitos es 15.
       De acuerdo con la posicion que ocupe el digito, se multiplica por
       el numero localizado en el vector correspondiente.
       D= 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01
       P= 71 67 59 53 47 43 41 37 29 23 19 17 13 07 03
       Una vez obtenido el acumulado, se calcula el residuo del acumulado
       modulo 11. Si el residuo = 0 => digito chequeo = 0
             Si el residuo = 1 => digito chequeo = 1
             De lo contrario   => digito chequeo = 11 - residuo;
    */
    digito1  constant NUMBER(2) := 3;
    digito2  constant NUMBER(2) := 7;
    digito3  constant NUMBER(2) := 13;
    digito4  constant NUMBER(2) := 17;
    digito5  constant NUMBER(2) := 19;
    digito6  constant NUMBER(2) := 23;
    digito7  constant NUMBER(2) := 29;
    digito8  constant NUMBER(2) := 37;
    digito9  constant NUMBER(2) := 41;
    digito10 constant NUMBER(2) := 43;
    digito11 constant NUMBER(2) := 47;
    digito12 constant NUMBER(2) := 53;
    digito13 constant NUMBER(2) := 59;
    digito14 constant NUMBER(2) := 67;
    digito15 constant NUMBER(2) := 71;
    longitud  NUMBER(2);
    acumula   NUMBER(8);
    residuo   NUMBER(2);
    Vdchequeo number(2);
    -- PL/SQL Block
  begin
    longitud := length(to_char(nit));
    if longitud > 0 then
      --    DBMS_OUTPUT.PUT_LINE('VALOR:' || TO_CHAR(DIGITO1));
      --    DBMS_OUTPUT.PUT_LINE('DIGITO:'||substr(to_char(nit),longitud,1));
      acumula := digito1 * substr(to_char(nit), longitud, 1);
    end if;
    if longitud > 1 then
      acumula := acumula + digito2 * substr(to_char(nit), longitud - 1, 1);
    end if;
    if longitud > 2 then
      acumula := acumula + digito3 * substr(to_char(nit), longitud - 2, 1);
    end if;
    if longitud > 3 then
      acumula := acumula + digito4 * substr(to_char(nit), longitud - 3, 1);
    end if;
    if longitud > 4 then
      acumula := acumula + digito5 * substr(to_char(nit), longitud - 4, 1);
    end if;
    if longitud > 5 then
      acumula := acumula + digito6 * substr(to_char(nit), longitud - 5, 1);
    end if;
    if longitud > 6 then
      acumula := acumula + digito7 * substr(to_char(nit), longitud - 6, 1);
    end if;
    if longitud > 7 then
      acumula := acumula + digito8 * substr(to_char(nit), longitud - 7, 1);
    end if;
    if longitud > 8 then
      acumula := acumula + digito9 * substr(to_char(nit), longitud - 8, 1);
    end if;
    if longitud > 9 then
      acumula := acumula + digito10 * substr(nit, longitud - 9, 1);
    end if;
    if longitud > 10 then
      acumula := acumula + digito11 * substr(nit, longitud - 10, 1);
    end if;
    if longitud > 11 then
      acumula := acumula + digito12 * substr(nit, longitud - 11, 1);
    end if;
    if longitud > 12 then
      acumula := acumula + digito13 * substr(nit, longitud - 12, 1);
    end if;
    if longitud > 13 then
      acumula := acumula + digito14 * substr(nit, longitud - 13, 1);
    end if;
    if longitud > 14 then
      acumula := acumula + digito15 * substr(nit, longitud - 14, 1);
    end if;
    residuo := acumula MOD 11;
    if residuo != 0 and residuo != 1 then
      Vdchequeo := 11 - residuo;
    else
      Vdchequeo := residuo;
    end if;
    return(Vdchequeo);
  END RT_DIGITO_CONTROL;
  FUNCTION F_TIPO_PERSONA(NO_ID   IN PERSONAS.PER_NUM_IDEN%TYPE,
                          TIPO_ID IN PERSONAS.PER_TID_CODIGO%TYPE)
    RETURN PERSONAS.PER_TIPO%TYPE IS
    -- PL/SQL Specification
    -- PL/SQL Block
    CURSOR C_TIPO IS
      SELECT PER_TIPO
        FROM PERSONAS
       WHERE PER_NUM_IDEN = no_id
         AND PER_TID_CODIGO = tipo_id;
    V_TIPO PERSONAS.PER_TIPO%TYPE;
    -- PL/SQL Block
  BEGIN
    OPEN C_TIPO;
    FETCH C_TIPO
      INTO V_TIPO;
    IF C_TIPO%NOTFOUND THEN
      CLOSE C_TIPO;
      RAISE_APPLICATION_ERROR(-20501,
                              'Persona con No. Id.: ' || no_id ||
                              ', T. Id.: ' || tipo_id || ' no existe.');
    END IF;
    CLOSE C_TIPO;
    RETURN V_TIPO;
  END F_TIPO_PERSONA;
  PROCEDURE P_DIRECCION_CORRESPONDENCIA(P_NUM_IDEN   IN VARCHAR2,
                                        P_TID_CODIGO IN VARCHAR2,
                                        P_DIRECCION  OUT VARCHAR2,
                                        P_TELEFONO   OUT VARCHAR2,
                                        P_CIUDAD     OUT VARCHAR2) IS
    CURSOR C_CLIENTE IS
      SELECT PER_TIPO,
             CLI_DIRECCION_OFICINA,
             CLI_AGE_CODIGO_TRABAJA,
             AGE1.AGE_CIUDAD          AGE_CIUDAD_TRABAJA,
             CLI_TELEFONO_OFICINA,
             CLI_DIRECCION_RESIDENCIA,
             CLI_AGE_CODIGO_RESIDE,
             AGE2.AGE_CIUDAD          AGE_CIUDAD_RESIDE,
             CLI_TELEFONO_RESIDENCIA,
             CLI_TEC_MNEMONICO
        FROM AREAS_GEOGRAFICAS AGE1,
             AREAS_GEOGRAFICAS AGE2,
             PERSONAS,
             CLIENTES
       WHERE AGE1.AGE_CODIGO(+) = CLI_AGE_CODIGO_TRABAJA
         AND AGE2.AGE_CODIGO(+) = CLI_AGE_CODIGO_RESIDE
         AND CLI_PER_NUM_IDEN = PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = PER_TID_CODIGO
         AND PER_NUM_IDEN = P_NUM_IDEN
         AND PER_TID_CODIGO = P_TID_CODIGO;
    CLI1 C_CLIENTE%ROWTYPE;
  BEGIN
    OPEN C_CLIENTE;
    FETCH C_CLIENTE
      INTO CLI1;
    IF C_CLIENTE%FOUND THEN
      IF CLI1.CLI_TEC_MNEMONICO = 'OFI' THEN
        P_DIRECCION := CLI1.CLI_DIRECCION_OFICINA;
        P_TELEFONO  := CLI1.CLI_TELEFONO_OFICINA;
        P_CIUDAD    := CLI1.AGE_CIUDAD_TRABAJA;
      ELSIF CLI1.CLI_TEC_MNEMONICO = 'RES' THEN
        P_DIRECCION := CLI1.CLI_DIRECCION_RESIDENCIA;
        P_TELEFONO  := CLI1.CLI_TELEFONO_RESIDENCIA;
        P_CIUDAD    := CLI1.AGE_CIUDAD_RESIDE;
      ELSE
        IF CLI1.PER_TIPO = 'PJU' THEN
          P_DIRECCION := CLI1.CLI_DIRECCION_OFICINA;
          P_TELEFONO  := CLI1.CLI_TELEFONO_OFICINA;
          P_CIUDAD    := CLI1.AGE_CIUDAD_TRABAJA;
        ELSE
          P_DIRECCION := CLI1.CLI_DIRECCION_RESIDENCIA;
          P_TELEFONO  := CLI1.CLI_TELEFONO_RESIDENCIA;
          P_CIUDAD    := CLI1.AGE_CIUDAD_RESIDE;
        END IF;
      END IF;
    ELSE
      P_DIRECCION := NULL;
      P_TELEFONO  := NULL;
      P_CIUDAD    := NULL;
    END IF;
  END P_DIRECCION_CORRESPONDENCIA;
  PROCEDURE P_DIRECCION_CORRESPONDENCIA(P_NUM_IDEN             IN VARCHAR2,
                                        P_TID_CODIGO           IN VARCHAR2,
                                        P_DIRECCION            OUT VARCHAR2,
                                        P_TELEFONO             OUT VARCHAR2,
                                        P_CIUDAD               OUT VARCHAR2,
                                        P_CIUDAD_DECEVAL       OUT NUMBER,
                                        P_DEPARTAMENTO_DECEVAL OUT NUMBER,
                                        P_PAIS_DECEVAL         OUT VARCHAR2,
                                        P_PAIS                 OUT VARCHAR2) IS
    CURSOR C_CLIENTE IS
      SELECT PER_TIPO,
             CLI_DIRECCION_OFICINA,
             CLI_AGE_CODIGO_TRABAJA,
             AGE1.AGE_CIUDAD               AGE_CIUDAD_TRABAJA,
             CLI_TELEFONO_OFICINA,
             CLI_DIRECCION_RESIDENCIA,
             CLI_AGE_CODIGO_RESIDE,
             AGE2.AGE_CIUDAD               AGE_CIUDAD_RESIDE,
             CLI_TELEFONO_RESIDENCIA,
             CLI_TEC_MNEMONICO,
             AGE1.AGE_PAIS_DECEVAL         AGE_PAIS_DEC_T,
             AGE1.AGE_DEPARTAMENTO_DECEVAL AGE_DEPARTAMENTO_DEC_T,
             AGE1.AGE_CIUDAD_DECEVAL       AGE_CIUDAD_DEC_T,
             AGE1.AGE_PAIS                 AGE_PAIS_T,
             AGE2.AGE_PAIS_DECEVAL         AGE_PAIS_DEC_R,
             AGE2.AGE_DEPARTAMENTO_DECEVAL AGE_DEPARTAMENTO_DEC_R,
             AGE2.AGE_CIUDAD_DECEVAL       AGE_CIUDAD_DEC_R,
             AGE1.AGE_PAIS                 AGE_PAIS_R
        FROM AREAS_GEOGRAFICAS AGE1,
             AREAS_GEOGRAFICAS AGE2,
             PERSONAS,
             CLIENTES
       WHERE AGE1.AGE_CODIGO(+) = CLI_AGE_CODIGO_TRABAJA
         AND AGE2.AGE_CODIGO(+) = CLI_AGE_CODIGO_RESIDE
         AND CLI_PER_NUM_IDEN = PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = PER_TID_CODIGO
         AND PER_NUM_IDEN = P_NUM_IDEN
         AND PER_TID_CODIGO = P_TID_CODIGO;
    CLI1 C_CLIENTE%ROWTYPE;
  BEGIN
    OPEN C_CLIENTE;
    FETCH C_CLIENTE
      INTO CLI1;
    IF C_CLIENTE%FOUND THEN
      IF CLI1.CLI_TEC_MNEMONICO = 'OFI' THEN
        P_DIRECCION            := CLI1.CLI_DIRECCION_OFICINA;
        P_TELEFONO             := CLI1.CLI_TELEFONO_OFICINA;
        P_CIUDAD               := CLI1.AGE_CIUDAD_TRABAJA;
        P_CIUDAD_DECEVAL       := CLI1.AGE_CIUDAD_DEC_T;
        P_DEPARTAMENTO_DECEVAL := CLI1.AGE_DEPARTAMENTO_DEC_T;
        P_PAIS_DECEVAL         := CLI1.AGE_PAIS_DEC_T;
        P_PAIS                 := CLI1.AGE_PAIS_T;
      ELSIF CLI1.CLI_TEC_MNEMONICO = 'RES' THEN
        P_DIRECCION            := CLI1.CLI_DIRECCION_RESIDENCIA;
        P_TELEFONO             := CLI1.CLI_TELEFONO_RESIDENCIA;
        P_CIUDAD               := CLI1.AGE_CIUDAD_RESIDE;
        P_CIUDAD_DECEVAL       := CLI1.AGE_CIUDAD_DEC_R;
        P_DEPARTAMENTO_DECEVAL := CLI1.AGE_DEPARTAMENTO_DEC_R;
        P_PAIS_DECEVAL         := CLI1.AGE_PAIS_DEC_R;
        P_PAIS                 := CLI1.AGE_PAIS_R;
      ELSE
        IF CLI1.PER_TIPO = 'PJU' THEN
          P_DIRECCION            := CLI1.CLI_DIRECCION_OFICINA;
          P_TELEFONO             := CLI1.CLI_TELEFONO_OFICINA;
          P_CIUDAD               := CLI1.AGE_CIUDAD_TRABAJA;
          P_CIUDAD_DECEVAL       := CLI1.AGE_CIUDAD_DEC_T;
          P_DEPARTAMENTO_DECEVAL := CLI1.AGE_DEPARTAMENTO_DEC_T;
          P_PAIS_DECEVAL         := CLI1.AGE_PAIS_DEC_T;
          P_PAIS                 := CLI1.AGE_PAIS_T;
        ELSE
          P_DIRECCION            := CLI1.CLI_DIRECCION_RESIDENCIA;
          P_TELEFONO             := CLI1.CLI_TELEFONO_RESIDENCIA;
          P_CIUDAD               := CLI1.AGE_CIUDAD_RESIDE;
          P_CIUDAD_DECEVAL       := CLI1.AGE_CIUDAD_DEC_R;
          P_DEPARTAMENTO_DECEVAL := CLI1.AGE_DEPARTAMENTO_DEC_R;
          P_PAIS_DECEVAL         := CLI1.AGE_PAIS_DEC_R;
          P_PAIS                 := CLI1.AGE_PAIS_R;
        END IF;
      END IF;
    ELSE
      P_DIRECCION            := NULL;
      P_TELEFONO             := NULL;
      P_CIUDAD               := NULL;
      P_CIUDAD_DECEVAL       := NULL;
      P_DEPARTAMENTO_DECEVAL := NULL;
      P_PAIS_DECEVAL         := NULL;
      P_PAIS                 := NULL;
    END IF;
  END P_DIRECCION_CORRESPONDENCIA;
  -- PL/SQL Block
  PROCEDURE ENVIO_CORRESPONDENCIA(P_CCC_CLI_PER_NUM_IDEN   CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE,
                                  P_CCC_CLI_PER_TID_CODIGO CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE,
                                  P_CLI_TEC_MNEMONICO      CLIENTES.CLI_TEC_MNEMONICO%TYPE,
                                  P_GRU_NOMBRE             IN OUT GRUPOS.GRU_NOMBRE%TYPE,
                                  P_GRU_PREGUNTAR_POR      IN OUT GRUPOS.GRU_PREGUNTAR_POR%TYPE,
                                  P_GRU_DIRECCION_CORRES   IN OUT GRUPOS.GRU_DIRECCION_CORRESPONDENCIA%TYPE,
                                  P_GRU_CIUDAD             IN OUT AREAS_GEOGRAFICAS.AGE_CIUDAD%TYPE,
                                  P_CIUDAD                 IN OUT AREAS_GEOGRAFICAS.AGE_CIUDAD%TYPE,
                                  P_DIRECCION              IN OUT CLIENTES.CLI_DIRECCION_OFICINA%TYPE) IS
    CURSOR C_CLI IS
      SELECT CLI_DIRECCION_OFICINA,
             CLI_AGE_CODIGO_TRABAJA,
             CLI_DIRECCION_RESIDENCIA,
             CLI_AGE_CODIGO_RESIDE,
             CLI_OTRO_TIPO_ENVIO_CORRES,
             P_CORREOS_COEASY.P_CORREO(CLI_PER_TID_CODIGO,
                                       CLI_PER_NUM_IDEN,
                                       'P') CLI_DIRECCION_EMAIL,
             CLI_APARTADO_AEREO,
             CLI_TEC_MNEMONICO
        FROM CLIENTES
       WHERE CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO;
    CLI1 C_CLI%ROWTYPE;

    CURSOR C_AGE(AGE NUMBER) IS
      SELECT AGE_CIUDAD FROM AREAS_GEOGRAFICAS WHERE AGE_CODIGO = AGE;

    CURSOR C_GRUPO IS
      SELECT GRU.GRU_DIRECCION_CORRESPONDENCIA GRU_DIRECCION_ENVIO_COR,
             AGE1.AGE_CIUDAD                   GRU_CIUDAD_GRUPO,
             GRU.GRU_PREGUNTAR_POR             GRU_PREGUNTAR_POR,
             GRU.GRU_NOMBRE                    GRU_NOMBRE
        FROM GRUPOS                     GRU,
             GRUPOS_CUENTAS             GCU,
             PERSONAS                   PER1,
             AREAS_GEOGRAFICAS          AGE1,
             CUENTAS_CLIENTE_CORREDORES
       WHERE GRU.GRU_CODIGO = GCU.GCU_GRU_CODIGO
         AND GRU.GRU_PER_NUM_IDEN = PER1.PER_NUM_IDEN
         AND GRU.GRU_PER_TID_CODIGO = PER1.PER_TID_CODIGO
         AND GRU.GRU_AGE_CODIGO = AGE1.AGE_CODIGO
         AND CCC_CUENTA_ACTIVA = 'S'
         AND GRU.GRU_ESTADO = 'A'
         AND GCU.GCU_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
         AND GCU.GCU_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
         AND GCU.GCU_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN
         AND GCU.GCU_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
       ORDER BY CCC_NUMERO_CUENTA, GRU_CODIGO;
    GRU1 C_GRUPO%ROWTYPE;

  BEGIN
    OPEN C_GRUPO;
    FETCH C_GRUPO
      INTO GRU1;
    CLOSE C_GRUPO;

    P_GRU_NOMBRE           := GRU1.GRU_NOMBRE;
    P_GRU_PREGUNTAR_POR    := GRU1.GRU_PREGUNTAR_POR;
    P_GRU_DIRECCION_CORRES := GRU1.GRU_DIRECCION_ENVIO_COR;
    P_GRU_CIUDAD           := GRU1.GRU_CIUDAD_GRUPO;

    OPEN C_CLI;
    FETCH C_CLI
      INTO CLI1;
    IF C_CLI%FOUND THEN
      IF CLI1.CLI_TEC_MNEMONICO = 'RES' THEN
        OPEN C_AGE(CLI1.CLI_AGE_CODIGO_RESIDE);
        FETCH C_AGE
          INTO P_CIUDAD;
        CLOSE C_AGE;
        P_CIUDAD    := NVL(P_CIUDAD, ' ');
        P_DIRECCION := NVL(CLI1.CLI_DIRECCION_RESIDENCIA, ' ');
      ELSIF CLI1.CLI_TEC_MNEMONICO = 'OFI' THEN
        OPEN C_AGE(CLI1.CLI_AGE_CODIGO_TRABAJA);
        FETCH C_AGE
          INTO P_CIUDAD;
        CLOSE C_AGE;
        P_CIUDAD    := NVL(P_CIUDAD, ' ');
        P_DIRECCION := NVL(CLI1.CLI_DIRECCION_OFICINA, ' ');
      ELSIF CLI1.CLI_TEC_MNEMONICO = 'OTR' THEN
        OPEN C_AGE(CLI1.CLI_AGE_CODIGO_RESIDE);
        FETCH C_AGE
          INTO P_CIUDAD;
        CLOSE C_AGE;
        P_CIUDAD    := NVL(P_CIUDAD, ' ');
        P_DIRECCION := NVL(CLI1.CLI_OTRO_TIPO_ENVIO_CORRES, ' ');
      ELSIF CLI1.CLI_TEC_MNEMONICO IN ('INT', 'CEL') THEN
        OPEN C_AGE(CLI1.CLI_AGE_CODIGO_RESIDE);
        FETCH C_AGE
          INTO P_CIUDAD;
        CLOSE C_AGE;
        P_CIUDAD    := NVL(P_CIUDAD, ' ');
        P_DIRECCION := NVL(CLI1.CLI_DIRECCION_RESIDENCIA,
                           NVL(CLI1.CLI_DIRECCION_OFICINA, ' '));
      ELSIF CLI1.CLI_TEC_MNEMONICO = 'AA' THEN
        P_CIUDAD    := ' ';
        P_DIRECCION := NVL(CLI1.CLI_APARTADO_AEREO, ' ');
      ELSIF CLI1.CLI_TEC_MNEMONICO IN ('REC', 'RET') THEN
        IF CLI1.CLI_DIRECCION_RESIDENCIA IS NOT NULL THEN
          OPEN C_AGE(CLI1.CLI_AGE_CODIGO_RESIDE);
          FETCH C_AGE
            INTO P_CIUDAD;
          CLOSE C_AGE;
          P_CIUDAD    := NVL(P_CIUDAD, ' ');
          P_DIRECCION := NVL(CLI1.CLI_DIRECCION_RESIDENCIA, ' ');
        ELSIF CLI1.CLI_DIRECCION_OFICINA IS NOT NULL THEN
          OPEN C_AGE(CLI1.CLI_AGE_CODIGO_TRABAJA);
          FETCH C_AGE
            INTO P_CIUDAD;
          CLOSE C_AGE;
          P_CIUDAD    := NVL(P_CIUDAD, ' ');
          P_DIRECCION := NVL(CLI1.CLI_DIRECCION_OFICINA, ' ');
        ELSIF CLI1.CLI_OTRO_TIPO_ENVIO_CORRES IS NOT NULL THEN
          OPEN C_AGE(CLI1.CLI_AGE_CODIGO_RESIDE);
          FETCH C_AGE
            INTO P_CIUDAD;
          CLOSE C_AGE;
          P_CIUDAD    := NVL(P_CIUDAD, ' ');
          P_DIRECCION := NVL(CLI1.CLI_OTRO_TIPO_ENVIO_CORRES, ' ');
        ELSIF CLI1.CLI_DIRECCION_EMAIL IS NOT NULL THEN
          OPEN C_AGE(CLI1.CLI_AGE_CODIGO_RESIDE);
          FETCH C_AGE
            INTO P_CIUDAD;
          CLOSE C_AGE;
          P_CIUDAD    := NVL(P_CIUDAD, ' ');
          P_DIRECCION := NVL(CLI1.CLI_DIRECCION_RESIDENCIA,
                             NVL(CLI1.CLI_DIRECCION_OFICINA, ' '));
        ELSIF CLI1.CLI_APARTADO_AEREO IS NOT NULL THEN
          P_CIUDAD    := ' ';
          P_DIRECCION := nvl(CLI1.CLI_APARTADO_AEREO, ' ');
        ELSE
          P_CIUDAD    := ' ';
          P_DIRECCION := ' ';
        END IF;
      ELSE
        P_CIUDAD    := ' ';
        P_DIRECCION := ' ';
      END IF;
    ELSE
      P_CIUDAD    := ' ';
      P_DIRECCION := ' ';
    END IF;
    CLOSE C_CLI;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,
                              'ENVIO CORRESPONDENCIA - ' || SQLERRM);
  END;
  -------------------------------------------------------------------------------------
  FUNCTION GRUPO(P_CCC_CLI_PER_NUM_IDEN   CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE,
                 P_CCC_CLI_PER_TID_CODIGO CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE)
    RETURN NUMBER IS
    CURSOR C_GRUPOS IS
      SELECT MIN(GRU_CODIGO) GRU_CODIGO
        FROM GRUPOS, GRUPOS_CUENTAS
       WHERE GRU_CODIGO = GCU_GRU_CODIGO
         AND GRU_ESTADO = 'A'
         AND GCU_CLI_PER_TID_CODIGO = P_CCC_CLI_PER_TID_CODIGO
         AND GCU_CLI_PER_NUM_IDEN = P_CCC_CLI_PER_NUM_IDEN;
    GRU1 C_GRUPOS%ROWTYPE;
  BEGIN
    OPEN C_GRUPOS;
    FETCH C_GRUPOS
      INTO GRU1;
    CLOSE C_GRUPOS;
    RETURN GRU1.GRU_CODIGO;
  END GRUPO;
  /***** ****/
  -- Procedimiento que devuelve el perfil del cliente de acuerdo a composicion del portafolio
  PROCEDURE ValidaPerfilPortafolio(P_TID_CODIGO IN VARCHAR2,
                                   P_NUM_IDEN   IN VARCHAR2,
                                   P_FECHA      IN DATE,
                                   P_PERFIL     IN OUT NUMBER) IS
    --CURSORES PARA TITULOS RENTA FIJA
    CURSOR C_TRF IS
      SELECT SUM(HST_VALOR_TM_DISPONIBLE + HST_VALOR_TM_GARANTIA +
                 HST_VALOR_TM_EMBARGO) SALDO_PESOS
        FROM HISTORICOS_SALDOS_TITULOS
       WHERE HST_CCC_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND HST_CCC_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND HST_FECHA >= TRUNC(P_FECHA)
         AND HST_FECHA < TRUNC(P_FECHA + 1)
         AND (EXISTS (SELECT 'X'
                        FROM FUNGIBLES
                       WHERE FUG_ISI_MNEMONICO = HST_CFC_FUG_ISI_MNEMONICO
                         AND FUG_MNEMONICO = HST_CFC_FUG_MNEMONICO
                         AND FUG_TIPO = 'RF') OR EXISTS
              (SELECT 'X'
                 FROM TITULOS
                WHERE TLO_CODIGO = HST_TLO_CODIGO
                  AND TLO_TYPE = 'TFC'));
    SALDO_TRF NUMBER := 0;
    --CURSOR PARA ACCIONES
    CURSOR C_ACC IS
      SELECT SUM(HST_VALOR_TM_DISPONIBLE + HST_VALOR_TM_GARANTIA +
                 HST_VALOR_TM_EMBARGO) SALDO_PESOS
        FROM HISTORICOS_SALDOS_TITULOS
       WHERE HST_CCC_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND HST_CCC_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND HST_FECHA >= TRUNC(P_FECHA)
         AND HST_FECHA < TRUNC(P_FECHA + 1)
         AND (EXISTS (SELECT 'X'
                        FROM FUNGIBLES
                       WHERE FUG_ISI_MNEMONICO = HST_CFC_FUG_ISI_MNEMONICO
                         AND FUG_MNEMONICO = HST_CFC_FUG_MNEMONICO
                         AND FUG_TIPO = 'ACC') OR EXISTS
              (SELECT 'X'
                 FROM TITULOS
                WHERE TLO_CODIGO = HST_TLO_CODIGO
                  AND TLO_TYPE = 'TVC'));
    SALDO_ACC NUMBER := 0;
    -- CURSOR FONDOS QUE SE INCLUYEN EN LA VALIDACION
    CURSOR C_FONDO IS
      SELECT FON_CODIGO, FON_BMO_MNEMONICO
        FROM FONDOS
       WHERE FON_TIPO = 'A'
         AND FON_TIPO_ADMINISTRACION = 'F'
         AND EXISTS
       (SELECT 'X'
                FROM VALORIZACIONES_FONDO
               WHERE VFO_FON_CODIGO = FON_CODIGO
                 AND VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
                 AND VFO_FECHA_VALORIZACION < TRUNC(P_FECHA + 1));
    R_FONDO C_FONDO%ROWTYPE;
    -- CURSOR FONDO
    CURSOR C_UNIDAD(QFDO VARCHAR2) IS
      SELECT SUM(M1.MCF_SALDO_UNIDADES) MCF_SALDO_UNIDADES
        FROM MOVIMIENTOS_CUENTAS_FONDOS M1, CUENTAS_FONDOS C1
       WHERE MCF_CFO_CCC_CLI_PER_NUM_IDEN = CFO_CCC_CLI_PER_NUM_IDEN
         AND M1.MCF_CFO_CCC_CLI_PER_TID_CODIGO = CFO_CCC_CLI_PER_TID_CODIGO
         AND M1.MCF_CFO_CCC_NUMERO_CUENTA = CFO_CCC_NUMERO_CUENTA
         AND M1.MCF_CFO_FON_CODIGO = CFO_FON_CODIGO
         AND M1.MCF_CFO_CODIGO = CFO_CODIGO
         AND M1.MCF_FECHA =
             P_WEB_PORTAFOLIO.MAX_MCF(TRUNC(P_FECHA),
                                      P_NUM_IDEN,
                                      P_TID_CODIGO,
                                      CFO_CCC_NUMERO_CUENTA,
                                      CFO_FON_CODIGO,
                                      CFO_CODIGO)
         AND C1.CFO_CCC_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND C1.CFO_CCC_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND C1.CFO_FON_CODIGO = QFDO;
    NUMERO_UNIDADES NUMBER := 0;
    SALDO_FINT      NUMBER := 0;
    SALDO_FACC      NUMBER := 0;
    SALDO_FRIESGO   NUMBER := 0;
    SALDO_FGLOBAL   NUMBER := 0;
    VALOR_FONDO     NUMBER;
    CURSOR C_VALOR_UND(QFONDO VARCHAR2) IS
      SELECT VFO_VALOR
        FROM VALORIZACIONES_FONDO VFO1
       WHERE VFO_FON_CODIGO = QFONDO
         AND VFO_FECHA_VALORIZACION =
             (SELECT MAX(VFO_FECHA_VALORIZACION)
                FROM VALORIZACIONES_FONDO VFO2
               WHERE VFO2.VFO_FON_CODIGO = QFONDO
                 AND VFO2.VFO_FECHA_VALORIZACION <= TRUNC(P_FECHA + 1));
    VAL_UNIDAD NUMBER;
    NO_VALOR_UNIDAD EXCEPTION;
    CURSOR C_BMO(QBMO VARCHAR2) IS
      SELECT NVL(CBM_VALOR, 0) CBM_VALOR
        FROM COTIZACIONES_BASE_MONETARIAS
       WHERE CBM_BMO_MNEMONICO = QBMO
         AND CBM_FECHA >= TRUNC(P_FECHA)
         AND CBM_FECHA < TRUNC(P_FECHA + 1);
    VALOR_BMO        NUMBER := 0;
    TOTAL_PORTAFOLIO NUMBER := 0;
    TOTAL_B          NUMBER := 0;
    PORCENTAJE_B     NUMBER;
    NO_VALOR_BMO EXCEPTION;
  BEGIN
    -- RENTA FIJA
    OPEN C_TRF;
    FETCH C_TRF
      INTO SALDO_TRF;
    IF C_TRF%NOTFOUND THEN
      SALDO_TRF := 0;
    ELSE
      SALDO_TRF := NVL(SALDO_TRF, 0);
    END IF;
    CLOSE C_TRF;
    TOTAL_PORTAFOLIO := TOTAL_PORTAFOLIO + SALDO_TRF;
    -- RENTA VARIABLE
    OPEN C_ACC;
    FETCH C_ACC
      INTO SALDO_ACC;
    IF C_ACC%NOTFOUND THEN
      SALDO_ACC := 0;
    ELSE
      SALDO_ACC := NVL(SALDO_ACC, 0);
    END IF;
    CLOSE C_ACC;
    TOTAL_PORTAFOLIO := TOTAL_PORTAFOLIO + SALDO_ACC;
    OPEN C_FONDO;
    FETCH C_FONDO
      INTO R_FONDO;
    WHILE C_FONDO%FOUND LOOP
      OPEN C_UNIDAD(R_FONDO.FON_CODIGO);
      FETCH C_UNIDAD
        INTO NUMERO_UNIDADES;
      IF C_UNIDAD%NOTFOUND THEN
        NUMERO_UNIDADES := 0;
      ELSE
        NUMERO_UNIDADES := NVL(NUMERO_UNIDADES, 0);
      END IF;
      CLOSE C_UNIDAD;
      OPEN C_VALOR_UND(R_FONDO.FON_CODIGO);
      FETCH C_VALOR_UND
        INTO VAL_UNIDAD;
      IF C_VALOR_UND%NOTFOUND THEN
        NULL;
        RAISE NO_VALOR_UNIDAD;
      END IF;
      CLOSE C_VALOR_UND;
      VAL_UNIDAD := NVL(VAL_UNIDAD, 0);
      IF R_FONDO.FON_BMO_MNEMONICO != 'PESOS' THEN
        OPEN C_BMO(R_FONDO.FON_BMO_MNEMONICO);
        FETCH C_BMO
          INTO VALOR_BMO;
        IF C_BMO%NOTFOUND THEN
          RAISE NO_VALOR_BMO;
        END IF;
        CLOSE C_BMO;
        VALOR_BMO := NVL(VALOR_BMO, 0);
      ELSE
        VALOR_BMO := 1;
      END IF;
      VALOR_FONDO := NUMERO_UNIDADES * VAL_UNIDAD * VALOR_BMO;
      IF R_FONDO.FON_CODIGO = '800175924' THEN
        -- FONDO ACCION
        SALDO_FACC := VALOR_FONDO;
      ELSIF R_FONDO.FON_CODIGO = '900008438' THEN
        -- FONRIESGO
        SALDO_FRIESGO := VALOR_FONDO;
      ELSIF R_FONDO.FON_CODIGO = '830100023' THEN
        -- FONDO GLOBAL
        SALDO_FGLOBAL := VALOR_FONDO;
      END IF;
      TOTAL_PORTAFOLIO := TOTAL_PORTAFOLIO + VALOR_FONDO;
      FETCH C_FONDO
        INTO R_FONDO;
    END LOOP;
    CLOSE C_FONDO;
    TOTAL_B := SALDO_ACC + SALDO_FACC + SALDO_FRIESGO + SALDO_FGLOBAL;
    IF TOTAL_PORTAFOLIO != 0 THEN
      PORCENTAJE_B := TOTAL_B / TOTAL_PORTAFOLIO * 100;
    ELSE
      PORCENTAJE_B := 0;
    END IF;
    IF PORCENTAJE_B >= 0.01 AND PORCENTAJE_B < 30 THEN
      P_PERFIL := 20; --MODERADO
    ELSIF PORCENTAJE_B >= 30 THEN
      P_PERFIL := 30; --AGRESIVO
    ELSE
      P_PERFIL := 10; --CONSERVADOR
    END IF;
    IF PORCENTAJE_B = 0 AND TOTAL_PORTAFOLIO = 0 THEN
      P_PERFIL := -1; --NO APLICA PARA VALIDACION
    END IF;
    DBMS_OUTPUT.PUT_LINE('TOTAL PORTAFOLIO : ' || TOTAL_PORTAFOLIO);
  EXCEPTION
    WHEN NO_VALOR_UNIDAD THEN
      IF C_VALOR_UND%ISOPEN THEN
        CLOSE C_VALOR_UND;
      END IF;
      RAISE_APPLICATION_ERROR(-20001,
                              'No Existe valor de unidad del Fondo ' ||
                              R_FONDO.FON_CODIGO || ' para la fecha ' ||
                              to_char(P_FECHA, 'DD-MON-YYYY'));
    WHEN NO_VALOR_BMO THEN
      IF C_BMO%ISOPEN THEN
        CLOSE C_BMO;
      END IF;
      RAISE_APPLICATION_ERROR(-20002,
                              'No Existe valor para la moneda ' ||
                              R_FONDO.FON_BMO_MNEMONICO || ' en la fecha ' ||
                              to_char(P_FECHA, 'DD-MON-YYYY'));
  END ValidaPerfilPortafolio;
  -- Retorna S= Autorizado N= No autorizado, F= Falta este tipo de operacion en la Matriz
  -- Procedimiento que devuelve si el cliente esta autorizado para realizar la operacion o no
  FUNCTION AutorizaColocacionOrdenPerfil(P_PRODUCTO     IN VARCHAR2,
                                         P_OPERACION    IN VARCHAR2, -- TIPO DE ORDEN
                                         P_CNE          IN VARCHAR2, -- CONDICION DE NEGOCIACION PARA OP BURSATIL
                                         P_AP           IN VARCHAR2, -- ACTIVO PASIVO PARA REPOS Y SIMULTANEAS (OP BURSATIL)
                                         P_PERFIL       IN VARCHAR2, -- PERFIL DEL CLIENTE
                                         P_CALIFICACION IN VARCHAR2, -- CALIFICACION ESPECIE
                                         P_TIPO_PERSONA IN VARCHAR2) -- TIPO DE PERSONA PNA / PJU
   RETURN VARCHAR2 IS

    -- Selecciona los valores de los campos opcionales
    CURSOR C_MATRIZ IS
      SELECT MRI_CALIFICACION_ESPECIE, MRI_TIPO_PERSONA, MRI_PERMITIDO
        FROM MATRIZ_RIESGOS
       WHERE MRI_PRO_MNEMONICO = P_PRODUCTO
         AND MRI_CONDICION_NEGOCIACION = P_CNE
         AND MRI_ACT_PAS = P_AP
         AND MRI_TIPO_OPERACION = P_OPERACION
         AND MRI_PERFIL = P_PERFIL;
    R_MAT C_MATRIZ%ROWTYPE;

    P_CALIFICACION_HOMOLOGA ESPECIES_NACIONALES.ENA_RIESGO_CORREDORES%TYPE;
    AUTORIZA                VARCHAR2(1);
  BEGIN
    P_CALIFICACION_HOMOLOGA := NULL;
    AUTORIZA                := NULL;

    OPEN C_MATRIZ;
    FETCH C_MATRIZ
      INTO R_MAT;
    WHILE C_MATRIZ%FOUND LOOP
      IF NVL(R_MAT.MRI_CALIFICACION_ESPECIE, 'N') = 'N' THEN
        IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = 'N' THEN
          AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
          EXIT;
        ELSE
          IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = P_TIPO_PERSONA THEN
            AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
            EXIT;
          END IF;
        END IF;
      ELSE
        IF P_CALIFICACION = 'NC' THEN
          P_CALIFICACION_HOMOLOGA := 'N';
        END IF;
        IF NVL(R_MAT.MRI_CALIFICACION_ESPECIE, 'N') =
           NVL(P_CALIFICACION_HOMOLOGA, P_CALIFICACION) THEN
          IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = 'N' THEN
            AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
            EXIT;
          ELSE
            IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = P_TIPO_PERSONA THEN
              AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
              EXIT;
            END IF;
          END IF;
        END IF;
      END IF;

      FETCH C_MATRIZ
        INTO R_MAT;
    END LOOP;
    CLOSE C_MATRIZ;
    IF P_CALIFICACION = 'NC' THEN
      AUTORIZA := 'S';
    END IF;
    RETURN(NVL(AUTORIZA, 'F'));
  END AutorizaColocacionOrdenPerfil;

  /*SMORALES - Funcion que valida si el cliente pertenece a la categoria PROFESIONAL DEL MERCADO
  para permitirle colocar ordenes (Modulo COCUFO) */

  FUNCTION AutorizaColocaOrdenPerfilProf(P_PRODUCTO     IN VARCHAR2,
                                         P_OPERACION    IN VARCHAR2, -- TIPO DE ORDEN
                                         P_CNE          IN VARCHAR2, -- CONDICION DE NEGOCIACION PARA OP BURSATIL
                                         P_AP           IN VARCHAR2, -- ACTIVO PASIVO PARA REPOS Y SIMULTANEAS (OP BURSATIL)
                                         P_PERFIL       IN VARCHAR2, -- PERFIL DEL CLIENTE
                                         P_CALIFICACION IN VARCHAR2, -- CALIFICACION ESPECIE
                                         P_TIPO_PERSONA IN VARCHAR2, -- TIPO DE PERSONA PNA / PJU
                                         P_ID           IN VARCHAR2, -- IDENTIFICACION CLIENTE
                                         P_TIP_ID       IN VARCHAR2) -- TIPO ID
   RETURN VARCHAR2 IS

    -- Selecciona los valores de los campos opcionales
    CURSOR C_MATRIZ IS
      SELECT MRI_CALIFICACION_ESPECIE, MRI_TIPO_PERSONA, MRI_PERMITIDO
        FROM MATRIZ_RIESGOS
       WHERE MRI_PRO_MNEMONICO = P_PRODUCTO
         AND MRI_CONDICION_NEGOCIACION = P_CNE
         AND MRI_ACT_PAS = P_AP
         AND MRI_TIPO_OPERACION = P_OPERACION
         AND MRI_PERFIL = P_PERFIL;
    R_MAT C_MATRIZ%ROWTYPE;

    CURSOR C_CLIENTES IS
      SELECT CLI_PROFESIONAL
        FROM CLIENTES
       WHERE CLI_PROFESIONAL = 'S'
         AND CLI_PER_NUM_IDEN = P_ID
         AND CLI_PER_TID_CODIGO = P_TIP_ID;
    R_CLI C_CLIENTES%ROWTYPE;

    AUTORIZA VARCHAR2(1);
  BEGIN

    AUTORIZA := NULL;

    OPEN C_CLIENTES;
    FETCH C_CLIENTES
      INTO R_CLI;
    CLOSE C_CLIENTES;

    IF R_CLI.CLI_PROFESIONAL = 'S' THEN
      AUTORIZA := 'S';

    ELSE

      OPEN C_MATRIZ;
      FETCH C_MATRIZ
        INTO R_MAT;
      WHILE C_MATRIZ%FOUND LOOP
        IF NVL(R_MAT.MRI_CALIFICACION_ESPECIE, 'N') = 'N' THEN
          IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = 'N' THEN
            AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
            EXIT;
          ELSE
            IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = P_TIPO_PERSONA THEN
              AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
              EXIT;
            END IF;
          END IF;
        ELSE
          IF NVL(R_MAT.MRI_CALIFICACION_ESPECIE, 'N') = P_CALIFICACION THEN
            IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = 'N' THEN
              AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
              EXIT;
            ELSE
              IF NVL(R_MAT.MRI_TIPO_PERSONA, 'N') = P_TIPO_PERSONA THEN
                AUTORIZA := NVL(R_MAT.MRI_PERMITIDO, 'N');
                EXIT;
              END IF;
            END IF;
          END IF;
        END IF;

        FETCH C_MATRIZ
          INTO R_MAT;
      END LOOP;
      CLOSE C_MATRIZ;
    END IF;
    RETURN(NVL(AUTORIZA, 'F'));
  END AutorizaColocaOrdenPerfilProf;

  /***** ****/
  -- Procedimiento que inserta la segmentacion de cliente en la tabla de historicos y actualiza esta informacion en la
  -- tabla correspondiente
  PROCEDURE InsertarClienteSegmentado(P_FECHA            IN DATE,
                                      P_TID_CLIENTE      IN VARCHAR2,
                                      P_NUMID_CLIENTE    IN VARCHAR2,
                                      P_CLASE_CLIENTE    IN VARCHAR2,
                                      P_SEG_CLIENTE      IN VARCHAR2,
                                      P_USER             IN VARCHAR2,
                                      P_VALOR_PORTAFOLIO IN NUMBER) IS
  BEGIN
    INSERT INTO segmentacion_clientes
      (sgc_consecutivo,
       sgc_fecha,
       sgc_cli_per_tid_codigo,
       sgc_cli_per_num_iden,
       sgc_bsc_bcc_mnemonico,
       sgc_bsc_mnemonico,
       sgc_valor_base)
    VALUES
      (sgc_seq.nextval,
       p_fecha,
       p_tid_cliente,
       p_numid_cliente,
       p_clase_cliente,
       p_seg_cliente,
       p_valor_portafolio);
    UPDATE clientes
       SET cli_bsc_bcc_mnemonico          = p_clase_cliente,
           cli_bsc_mnemonico              = p_seg_cliente,
           cli_fecha_ultima_modificacion  = sysdate,
           cli_usuario_ultima_modifica    = P_USER,
           cli_ultima_operacion_ejecutada = 'MO'
     WHERE cli_per_tid_codigo = p_tid_cliente
       and cli_per_num_iden = p_numid_cliente;
  END InsertarClienteSegmentado;
  /***** ****/
  -- Procedimiento para deshabilitar el trigger de clientes
  PROCEDURE DeshabilitarTriggerClientes IS
  BEGIN
    EXECUTE IMMEDIATE ('ALTER TRIGGER CLI_CK DISABLE');
  END DeshabilitarTriggerClientes;
  /***** ****/
  -- Procedimiento para deshabilitar el trigger de clientes
  PROCEDURE HabilitarTriggerClientes IS
  BEGIN
    EXECUTE IMMEDIATE ('ALTER TRIGGER CLI_CK ENABLE');
  END HabilitarTriggerClientes;
  PROCEDURE ConsultarEstadoTriggerClientes(P_ESTADO OUT VARCHAR2) IS
    CURSOR C_TRIGGER_STATUS IS
      SELECT status FROM user_triggers WHERE trigger_name = 'CLI_CK';
    TRI1 C_TRIGGER_STATUS%ROWTYPE;
  BEGIN
    OPEN C_TRIGGER_STATUS;
    FETCH C_TRIGGER_STATUS
      INTO TRI1;
    IF C_TRIGGER_STATUS%FOUND THEN
      P_ESTADO := TRI1.status;
    ELSE
      P_ESTADO := NULL;
    END IF;
  END ConsultarEstadoTriggerClientes;
  PROCEDURE P_CONSULTAR_CLIENTE(P_NUM_IDEN            IN VARCHAR2,
                                P_TID_CODIGO          IN VARCHAR2,
                                P_CLIENTE             OUT CLIENTES%ROWTYPE,
                                P_PERSONA             OUT PERSONAS%ROWTYPE,
                                P_CIUDAD              OUT AREAS_GEOGRAFICAS%ROWTYPE,
                                P_PERSONA_RELACIONADA OUT VARCHAR2) IS
    CURSOR C1 IS
      SELECT *
        FROM CLIENTES
       WHERE CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND CLI_PER_TID_CODIGO = P_TID_CODIGO;
    CURSOR C2 IS
      SELECT *
        FROM PERSONAS
       WHERE PER_NUM_IDEN = P_NUM_IDEN
         AND PER_TID_CODIGO = P_TID_CODIGO;
    CURSOR C3(P_AGE_CODIGO NUMBER) IS
      SELECT * FROM AREAS_GEOGRAFICAS WHERE AGE_CODIGO = P_AGE_CODIGO;
    CURSOR C4 IS
      SELECT PER_NOMBRE
        FROM FILTRO_PERSONAS, PERSONAS_RELACIONADAS
       WHERE PER_NUM_IDEN = RLC_PER_NUM_IDEN
         AND PER_TID_CODIGO = RLC_PER_TID_CODIGO
         AND RLC_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND RLC_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND RLC_ROL_CODIGO = 2
         AND RLC_ESTADO = 'A';
    CURSOR C5 IS
      SELECT PER_NOMBRE
        FROM FILTRO_PERSONAS, PERSONAS_RELACIONADAS
       WHERE PER_NUM_IDEN = RLC_PER_NUM_IDEN
         AND PER_TID_CODIGO = RLC_PER_TID_CODIGO
         AND RLC_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND RLC_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND RLC_ROL_CODIGO = 1
         AND RLC_ESTADO = 'A';
    CURSOR C6 IS
      SELECT PER_NOMBRE
        FROM FILTRO_PERSONAS, PERSONAS_RELACIONADAS
       WHERE PER_NUM_IDEN = RLC_PER_NUM_IDEN
         AND PER_TID_CODIGO = RLC_PER_TID_CODIGO
         AND RLC_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND RLC_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND RLC_ROL_CODIGO = 1
       ORDER BY PERSONAS_RELACIONADAS.ROWID DESC;
  BEGIN
    P_CLIENTE             := NULL;
    P_PERSONA             := NULL;
    P_CIUDAD              := NULL;
    P_PERSONA_RELACIONADA := NULL;
    OPEN C1;
    FETCH C1
      INTO P_CLIENTE;
    IF C1%NOTFOUND THEN
      P_CLIENTE := NULL;
    END IF;
    CLOSE C1;
    OPEN C2;
    FETCH C2
      INTO P_PERSONA;
    IF C2%NOTFOUND THEN
      P_PERSONA := NULL;
    END IF;
    CLOSE C2;
    IF P_PERSONA.PER_NUM_IDEN IS NOT NULL THEN
      IF P_PERSONA.PER_TIPO = 'PJU' THEN
        OPEN C3(P_CLIENTE.CLI_AGE_CODIGO_TRABAJA);
      ELSE
        OPEN C3(P_CLIENTE.CLI_AGE_CODIGO_RESIDE);
      END IF;
      FETCH C3
        INTO P_CIUDAD;
      IF C3%NOTFOUND THEN
        P_CIUDAD := NULL;
      END IF;
      CLOSE C3;
      IF P_PERSONA.PER_TIPO = 'PJU' THEN
        OPEN C4;
        FETCH C4
          INTO P_PERSONA_RELACIONADA;
        IF C4%NOTFOUND THEN
          P_PERSONA_RELACIONADA := NULL;
        END IF;
        CLOSE C4;
        IF P_PERSONA_RELACIONADA IS NULL THEN
          -- buscar primer ordenante activo
          OPEN C5;
          FETCH C5
            INTO P_PERSONA_RELACIONADA;
          IF C5%NOTFOUND THEN
            P_PERSONA_RELACIONADA := NULL;
          END IF;
          CLOSE C5;
        END IF;
        IF P_PERSONA_RELACIONADA IS NULL THEN
          -- buscar primer ordenante activo
          OPEN C6;
          FETCH C6
            INTO P_PERSONA_RELACIONADA;
          IF C6%NOTFOUND THEN
            P_PERSONA_RELACIONADA := NULL;
          END IF;
          CLOSE C6;
        END IF;
      ELSE
        P_PERSONA_RELACIONADA := P_PERSONA.PER_PRIMER_APELLIDO || ' ' ||
                                 P_PERSONA.PER_SEGUNDO_APELLIDO || ' ' ||
                                 P_PERSONA.PER_NOMBRE;
      END IF;
    END IF;
  END P_CONSULTAR_CLIENTE;
  PROCEDURE P_PERSONA_VINCULADA(P_PER_NUM_IDEN   IN VARCHAR2,
                                P_PER_TID_CODIGO IN VARCHAR2,
                                RESPUESTA        IN OUT VARCHAR2) IS

    CURSOR C_PARTE_VINCULADA IS
      SELECT PER_NOMBRE
        FROM PARTES_VINCULADAS, FILTRO_PERSONAS
       WHERE PVI_PER_NUM_IDEN = P_PER_NUM_IDEN
         AND PVI_PER_TID_CODIGO = P_PER_TID_CODIGO
         AND PVI_ESTADO = 'A'
         AND PVI_EMISOR = 'A'
         AND PVI_PER_NUM_IDEN = PER_NUM_IDEN
         AND PVI_PER_TID_CODIGO = PER_TID_CODIGO
      UNION
      SELECT PER_NOMBRE
        FROM PERSONAS_RELACIONADAS,
             PARTES_VINCULADAS,
             CLIENTES,
             FILTRO_PERSONAS,
             ESTADOS_CLIENTE
       WHERE RLC_CLI_PER_NUM_IDEN = P_PER_NUM_IDEN
         AND RLC_CLI_PER_TID_CODIGO = P_PER_TID_CODIGO
         AND RLC_ESTADO = 'A'
         AND RLC_PER_NUM_IDEN = PVI_PER_NUM_IDEN
         AND RLC_PER_TID_CODIGO = PVI_PER_TID_CODIGO
         AND RLC_ROL_CODIGO IN (1, 2, 6)
         AND PVI_ESTADO = 'A'
         AND PVI_PER_NUM_IDEN = PER_NUM_IDEN
         AND PVI_PER_TID_CODIGO = PER_TID_CODIGO
         AND RLC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
         AND RLC_CLI_PER_TID_CODIGO = CLI_PER_TID_CODIGO
         AND CLI_ECL_MNEMONICO = ECL_MNEMONICO
         AND ECL_COLOCAR_ORDEN = 'S';
  BEGIN
    OPEN C_PARTE_VINCULADA;
    FETCH C_PARTE_VINCULADA
      INTO RESPUESTA;
    CLOSE C_PARTE_VINCULADA;
  END P_PERSONA_VINCULADA;

  PROCEDURE P_CTA_DIG_DCV(P_DSP_CUENTA IN VARCHAR2, --NUMBER, MIC DCV BANCO DE LA REPUBLICA
                          P_CUENTA_DCV OUT VARCHAR2, --NUMBER,  MIC DCV BANCO DE LA REPUBLICA
                          P_DIGITO_DCV OUT NUMBER) IS

    CURSOR C_DCV IS
    --SELECT TO_NUMBER(SUBSTR(LPAD(TO_CHAR(P_DSP_CUENTA),8,' '),1,7)) CTA_DCV,
    --       TO_NUMBER(SUBSTR(LPAD(TO_CHAR(P_DSP_CUENTA),8,' '),8,1)) DIGITO_DCV
    --MIC DCV BANCO DE LA REPUBLICA
      SELECT P_DSP_CUENTA CTA_DCV,
             TO_NUMBER(SUBSTR(LPAD(TO_CHAR(P_DSP_CUENTA), 35, ' '), 35, 1)) DIGITO_DCV
        FROM DUAL;
    R_DCV C_DCV%ROWTYPE;

  BEGIN
    OPEN C_DCV;
    FETCH C_DCV
      INTO R_DCV;
    CLOSE C_DCV;
    P_CUENTA_DCV := R_DCV.CTA_DCV;
    P_DIGITO_DCV := R_DCV.DIGITO_DCV;

  END P_CTA_DIG_DCV;

  /* ********************************************************* */
  PROCEDURE PR_INSERTAR_PROSPECTO(P_PER_NUM_IDEN   IN VARCHAR2,
                                  P_PER_TID_CODIGO IN VARCHAR2,
                                  P_FONDO          IN VARCHAR2,
                                  P_RADICACION     IN VARCHAR2) IS

    --CONSULTAR SI EL FONDO ES COMPARTIMENTO
    CURSOR C_COMPARTIMENTOS IS
      SELECT PFO_FON_CODIGO
        FROM PARAMETROS_FONDOS
       WHERE PFO_PAR_CODIGO IN (83, 71)
         AND PFO_FON_CODIGO = P_FONDO;

    --CONSULTA LOS FONDOS HERMANOS
    CURSOR C_COMPARTIMENTOS_HERMANOS IS
      SELECT DISTINCT PFO_FON_CODIGO
        FROM PARAMETROS_FONDOS
       WHERE PFO_PAR_CODIGO IN (83, 71)
         AND PFO_FON_CODIGO LIKE
             SUBSTR(P_FONDO, 0, INSTR(P_FONDO, '-', 1, 1) - 1) || '%';

    V_VALIDO VARCHAR2(1);

    V_ES_COMPARTIMENTO    VARCHAR2(1);
    V_COMPARTIMENTO       VARCHAR2(25);
    V_FONDO_COMPARTIMENTO VARCHAR2(25);

    V_EXONERA      VARCHAR2(1);
    V_RADI_EXONERA VARCHAR2(20);
  BEGIN

    OPEN C_COMPARTIMENTOS;
    FETCH C_COMPARTIMENTOS
      INTO V_COMPARTIMENTO;
    IF C_COMPARTIMENTOS%NOTFOUND THEN
      V_COMPARTIMENTO := 'N';
    ELSE
      V_COMPARTIMENTO := 'S';
    END IF;
    CLOSE C_COMPARTIMENTOS;

    V_EXONERA      := NULL;
    V_RADI_EXONERA := NULL;

    IF V_COMPARTIMENTO = 'N' THEN
      P_FONDOS_WEB.PR_VALIDAR_PERFIL_RIESGO(P_CLI_PER_NUM_IDEN   => P_PER_NUM_IDEN,
                                            P_CLI_PER_TID_CODIGO => P_PER_TID_CODIGO,
                                            P_FON_CODIGO         => P_FONDO,
                                            P_TIPO_OPERACION     => 'ING',
                                            P_VALIDO             => V_VALIDO);

      IF V_VALIDO = 'N' THEN
        V_EXONERA      := 'S';
        V_RADI_EXONERA := P_RADICACION;
      END IF;

      INSERT INTO CUENTAS_CLIENTES_FONDOS
        (CCF_FON_CODIGO,
         CCF_CLI_PER_NUM_IDEN,
         CCF_CLI_PER_TID_CODIGO,
         CCF_RADICACION_ADHESION,
         CCF_FECHA_RADICA_ADHESION,
         CCF_ESTADO,
         CCF_CARTA_EXONERACION,
         CCF_RADICACION_EXONERACION)
      VALUES
        (P_FONDO,
         P_PER_NUM_IDEN,
         P_PER_TID_CODIGO,
         P_RADICACION,
         SYSDATE,
         'A',
         V_EXONERA,
         V_RADI_EXONERA);

    ELSE
      OPEN C_COMPARTIMENTOS_HERMANOS;
      FETCH C_COMPARTIMENTOS_HERMANOS
        INTO V_COMPARTIMENTO;
      WHILE C_COMPARTIMENTOS_HERMANOS%FOUND LOOP
        P_FONDOS_WEB.PR_VALIDAR_PERFIL_RIESGO(P_CLI_PER_NUM_IDEN   => P_PER_NUM_IDEN,
                                              P_CLI_PER_TID_CODIGO => P_PER_TID_CODIGO,
                                              P_FON_CODIGO         => P_FONDO,
                                              P_TIPO_OPERACION     => 'ING',
                                              P_VALIDO             => V_VALIDO);

        IF V_VALIDO = 'N' THEN
          V_EXONERA      := 'S';
          V_RADI_EXONERA := P_RADICACION;
        ELSE
          V_EXONERA      := NULL;
          V_RADI_EXONERA := NULL;
        END IF;

        INSERT INTO CUENTAS_CLIENTES_FONDOS
          (CCF_FON_CODIGO,
           CCF_CLI_PER_NUM_IDEN,
           CCF_CLI_PER_TID_CODIGO,
           CCF_RADICACION_ADHESION,
           CCF_FECHA_RADICA_ADHESION,
           CCF_ESTADO,
           CCF_CARTA_EXONERACION,
           CCF_RADICACION_EXONERACION)
        VALUES
          (V_COMPARTIMENTO,
           P_PER_NUM_IDEN,
           P_PER_TID_CODIGO,
           P_RADICACION,
           SYSDATE,
           'A',
           V_EXONERA,
           V_RADI_EXONERA);

        FETCH C_COMPARTIMENTOS_HERMANOS
          INTO V_COMPARTIMENTO;
      END LOOP;
      CLOSE C_COMPARTIMENTOS_HERMANOS;
    END IF;

  END PR_INSERTAR_PROSPECTO;
  /* ********************************************************* */
  PROCEDURE PR_VALIDAR_PROSPECTO(P_PER_NUM_IDEN         IN VARCHAR2,
                                 P_PER_TID_CODIGO       IN VARCHAR2,
                                 P_FONDO                IN VARCHAR2,
                                 P_TIENE_PROSPECTO      IN OUT VARCHAR2,
                                 P_FONDO_PPAL_PROSPECTO IN OUT VARCHAR2) IS

    CURSOR C_PROSPECTO IS
      SELECT CCF_FON_CODIGO
        FROM CUENTAS_CLIENTES_FONDOS
       WHERE CCF_CLI_PER_NUM_IDEN = P_PER_NUM_IDEN
         AND CCF_CLI_PER_TID_CODIGO = P_PER_TID_CODIGO
         AND CCF_FON_CODIGO = P_FONDO
         AND CCF_RADICACION_ADHESION IS NOT NULL;

    --CONSULTAR SI EL FONDO ES COMPARTIMENTO
    CURSOR C_COMPARTIMENTOS IS
      SELECT PFO_FON_CODIGO
        FROM PARAMETROS_FONDOS
       WHERE PFO_PAR_CODIGO IN (83, 71)
         AND PFO_FON_CODIGO = P_FONDO;

    V_PROSPECTO     VARCHAR2(25);
    V_COMPARTIMENTO VARCHAR2(25);
  BEGIN
    OPEN C_PROSPECTO;
    FETCH C_PROSPECTO
      INTO V_PROSPECTO;
    IF C_PROSPECTO%NOTFOUND THEN
      P_TIENE_PROSPECTO := 'N';
    ELSE
      P_TIENE_PROSPECTO := 'S';
    END IF;
    CLOSE C_PROSPECTO;

    OPEN C_COMPARTIMENTOS;
    FETCH C_COMPARTIMENTOS
      INTO V_COMPARTIMENTO;
    IF C_COMPARTIMENTOS%NOTFOUND THEN
      P_FONDO_PPAL_PROSPECTO := P_FONDO;
    ELSE
      P_FONDO_PPAL_PROSPECTO := SUBSTR(P_FONDO, 0, 9);
    END IF;
    CLOSE C_COMPARTIMENTOS;
  END PR_VALIDAR_PROSPECTO;
  /* ********************************************************* */
  /** FUNCION QUE ELIMINAR LOS CARACTERES DE UN ALFANUMERICO **/
  FUNCTION P_EXTRAE_CARACTER(P_NID IN VARCHAR2) RETURN VARCHAR2 IS

    CURSOR C_NID IS
      SELECT REGEXP_REPLACE(P_NID, '[a-zA-Z'']|[[:space:]]*', '')
        FROM DUAL;
    CADENA2 VARCHAR2(15);

  BEGIN
    OPEN C_NID;
    FETCH C_NID
      INTO CADENA2;
    RETURN(CADENA2);
  END;

  /** FUNCION QUE EXTRAE EL PRIMER CORREO REGISTRADO PARA EL CLIENTE **/
  FUNCTION P_EMAIL(P_NID IN VARCHAR2, P_TID IN VARCHAR2) RETURN VARCHAR2 IS

    CURSOR C_CLIENTE IS
      SELECT P_CORREOS_COEASY.P_CORREO(CLI_PER_TID_CODIGO,
                                       CLI_PER_NUM_IDEN,
                                       'P') CLI_DIRECCION_EMAIL
      --SUBSTR(CLI_DIRECCION_EMAIL,1,INSTR(REPLACE(CLI_DIRECCION_EMAIL,' ', ';'),';')-1) DIR_EMAIL
        FROM CLIENTES
       WHERE CLI_PER_NUM_IDEN = P_NID
         AND CLI_PER_TID_CODIGO = P_TID;

    DIR_EMAIL    VARCHAR2(417);
    POSICION_UNO NUMBER(2);
    EMAIL        VARCHAR2(417);

  BEGIN
    OPEN C_CLIENTE;
    FETCH C_CLIENTE
      INTO DIR_EMAIL;
    POSICION_UNO := INSTR(REPLACE(DIR_EMAIL, ' ', ';'), ';');
    IF POSICION_UNO = 0 THEN
      EMAIL := NVL(DIR_EMAIL, '');
    ELSE
      EMAIL := SUBSTR(DIR_EMAIL, 1, POSICION_UNO - 1);
    END IF;
    EMAIL := SUBSTR(EMAIL, 1, 40);
    RETURN(EMAIL);
  END;

  PROCEDURE P_INSERTAR_LISTA_CAUT_CLI(P_LCC_NUM_IDEN         IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_TID_CODIGO       IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_TIPO             IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_NOMBRE           IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_CODIGO           IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_PAIS             IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_EXPEDICION       IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_EXPIRACION       IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_TIPOLISTA        IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_ESTADO           IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_OBSERVACIONES    IN VARCHAR2 DEFAULT NULL,
                                      P_LCC_FECHA_REGISTRO   IN DATE DEFAULT SYSDATE,
                                      P_LCC_USUARIO_REGISTRO IN VARCHAR2 DEFAULT 'PROD') IS
  BEGIN
    INSERT INTO LISTA_CAUTELA_CLIENTES
      (LCC_NUM_IDEN,
       LCC_TID_CODIGO,
       LCC_TIPO,
       LCC_NOMBRE,
       LCC_CODIGO,
       LCC_PAIS,
       LCC_EXPEDICION,
       LCC_EXPIRACION,
       LCC_TIPO_LISTA,
       LCC_ESTADO,
       LCC_OBSERVACIONES,
       LCC_FECHA_REGISTRO,
       LCC_USUARIO_REGISTRO)
    VALUES
      (P_LCC_NUM_IDEN,
       P_LCC_TID_CODIGO,
       P_LCC_TIPO,
       P_LCC_NOMBRE,
       P_LCC_CODIGO,
       P_LCC_PAIS,
       P_LCC_EXPEDICION,
       P_LCC_EXPIRACION,
       P_LCC_TIPOLISTA,
       P_LCC_ESTADO,
       P_LCC_OBSERVACIONES,
       P_LCC_FECHA_REGISTRO,
       P_LCC_USUARIO_REGISTRO);

  END P_INSERTAR_LISTA_CAUT_CLI;

  PROCEDURE P_VALIDAR_LISTA_CAUT_CLI IS
  BEGIN
    MERGE INTO TMP_LISTA_CAUTELA_CLIENTES TLCC
    USING (
    /*
                                   * 1. APLICACION DE VALIDACIONES A LOS DATOS
                                   */
      WITH VALIDACIONES AS
       (
        -- 1.1 REGISTROS MAS DE UNA VEZ
        SELECT RANK() OVER(PARTITION BY NVL(TLCC_NUM_IDEN, 0), NVL(TLCC_TID_CODIGO, ''), TLCC_NOMBRE ORDER BY TLCC_CODIGO) AS RANK,
                'REGISTRO DUPLICADO EN EL ARCHIVO' AS TLCC_RAZON_RECHAZO,
                TLCC.TLCC_CODIGO
          FROM TMP_LISTA_CAUTELA_CLIENTES TLCC
        UNION ALL
        -- 1.2 REGISTROS SIN NOMBRE
        SELECT 2 AS RANK,
                'REGISRO SIN NOMBRE' AS TLCC_RAZON_RECHAZO,
                TLCC.TLCC_CODIGO
          FROM TMP_LISTA_CAUTELA_CLIENTES TLCC
         WHERE TLCC.TLCC_NOMBRE IS NULL
            OR LENGTH(NVL(TLCC.TLCC_NOMBRE, 0)) = 0
        UNION ALL
        -- 1.3 REGISTROS YA REPORTADOS EN LA TABLA LISTA_CAUTELA_CLIENTES
        SELECT 2 AS RANK,
                'REGISTRO YA ESTA REPORTADO' AS TLCC_RAZON_RECHAZO,
                TLCC.TLCC_CODIGO
          FROM TMP_LISTA_CAUTELA_CLIENTES TLCC
         INNER JOIN LISTA_CAUTELA_CLIENTES LCC
            ON (TLCC.TLCC_TID_CODIGO = LCC.LCC_TID_CODIGO OR
               (TLCC.TLCC_TID_CODIGO IS NULL AND LCC.LCC_TID_CODIGO IS NULL))
           AND (TLCC.TLCC_NUM_IDEN = LCC.LCC_NUM_IDEN OR
               (TLCC.TLCC_NUM_IDEN IS NULL AND LCC.LCC_NUM_IDEN IS NULL))
           AND TLCC.TLCC_TIPO_LISTA = LCC.LCC_TIPO_LISTA
           AND TLCC.TLCC_NOMBRE = LCC.LCC_NOMBRE
        UNION ALL
        -- 1.4 REGISTROS CON TIPOS DE IDENTIFICACION DIFERENTE DE NULL, QUE NO ESTAN
        --     EN LA TABLA DE TIPOS_IDENTIFICACION
        SELECT 2 AS RANK,
                'TIPO DE IDENTIFICACION NO VALIDO - ' || TLCC.TLCC_TID_CODIGO AS TLCC_RAZON_RECHAZO,
                TLCC.TLCC_CODIGO
          FROM TMP_LISTA_CAUTELA_CLIENTES TLCC
          LEFT JOIN TIPOS_IDENTIFICACION TID
            ON TLCC.TLCC_TID_CODIGO = TID.TID_CODIGO
         WHERE TLCC.TLCC_TID_CODIGO IS NOT NULL
           AND TID.TID_CODIGO IS NULL)

      /*
                                               * 2. CONCATENACIÓN DE LOS MENSAJES DE VALIDACIÓN
                                               */
      SELECT TLCC_CODIGO,
             LTRIM(MAX(SYS_CONNECT_BY_PATH(TLCC_RAZON_RECHAZO, ','))
                   KEEP(DENSE_RANK LAST ORDER BY curr),
                   ',') AS TLCC_RAZON_RECHAZO
        FROM (SELECT TLCC_CODIGO,
                     TLCC_RAZON_RECHAZO,
                     ROW_NUMBER() OVER(PARTITION BY TLCC_CODIGO ORDER BY TLCC_RAZON_RECHAZO) AS curr,
                     ROW_NUMBER() OVER(PARTITION BY TLCC_CODIGO ORDER BY TLCC_RAZON_RECHAZO) - 1 AS prev
                FROM VALIDACIONES
               WHERE VALIDACIONES.RANK > 1)
       GROUP BY TLCC_CODIGO
      CONNECT BY prev = PRIOR curr
             AND TLCC_CODIGO = PRIOR TLCC_CODIGO
       START WITH curr = 1) VAL ON (TLCC.TLCC_CODIGO = VAL.TLCC_CODIGO) WHEN MATCHED THEN
      /*
      * 3. ACTUALIZACIÓN DE LOS MENSAJES DE VALIDACIÓN EN LA TABLA DE DATOS
      */
        UPDATE SET TLCC.TLCC_RAZON_RECHAZO = VAL.TLCC_RAZON_RECHAZO;
    COMMIT;
  END P_VALIDAR_LISTA_CAUT_CLI;

  PROCEDURE P_INFO_CLIENTES_CRM_DAVIVIENDA(io_cursor IN OUT O_CURSOR) IS
  BEGIN
    OPEN io_cursor FOR
    --GRUPO 1
      WITH CLIENTES_CRM AS
       (SELECT DISTINCT PCV.IDENTIFICACIONCLIENTE AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV TipoIdentificacion,
                        '0001' AS CodigoProducto,
                        'Portafolio Renta Variable' AS Descripcion
          FROM V_PORTAFOLIO_CLI_RV PCV
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON PCV.TIPOIDENTIFICACIONCLIENTE = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
        UNION ALL
        --GRUPO 2
        SELECT DISTINCT PCF.IDENTIFICACIONCLIENTE AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV AS TipoIdentificacion,
                        '0002' AS CodigoProducto,
                        'Portafolio Renta Fija' AS Descripcion
          FROM V_PORTAFOLIO_CLI_RF PCF
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON PCF.TIPOIDENTIFICACIONCLIENTE = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
        UNION ALL
        -- grupo 3 x fecha dia caido
        SELECT DISTINCT HST.HST_CCC_CLI_PER_NUM_IDEN AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV AS TipoIdentificacion,
                        '0003' AS CodigoProducto,
                        'Administración y custodia de valores' AS Descripcion
          FROM HISTORICOS_SALDOS_TITULOS HST
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON HST.HST_CCC_CLI_PER_TID_CODIGO = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
         WHERE HST_FECHA = TRUNC(SYSDATE - 1)
        UNION
        -- gruipo 4
        SELECT DISTINCT CCC.CCC_CLI_PER_NUM_IDEN AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV AS TipoIdentificacion,
                        '0004' AS CodigoProducto,
                        'Trading Electrónico' AS Descripcion
          FROM CUENTAS_CLIENTE_CORREDORES CCC
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON CCC.CCC_CLI_PER_TID_CODIGO = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
         WHERE CCC_ETRADE = 'S'
        UNION
        -- GRUPO 5
        SELECT DISTINCT SAD.SAD_CCC_CLI_PER_NUM_IDEN AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV AS TipoIdentificacion,
                        '0005' AS CodigoProducto,
                        'Portafolio Fondos de inversión sociedad comisionista' AS Descripcion
          FROM SALDOS_DIARIOS SAD
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON SAD.SAD_CCC_CLI_PER_TID_CODIGO = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
         WHERE TRUNC(SAD_FECHA) = TRUNC(SYSDATE - 1)
        -- GRUPO 6 DIVISAS, DERIVADOS,
        UNION
        SELECT DISTINCT SDV.SDV_SCM_CCC_CLI_PER_NUM_IDEN AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV AS TipoIdentificacion,
                        '0006' AS CodigoProducto,
                        'Otros productos Sociedad Comisionista de Bolsa' AS Descripcion
          FROM SALDOS_CLIENTES_DIVISAS SDV
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON SDV.SDV_SCM_CCC_CLI_PER_TID_CODIGO = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
         WHERE TRUNC(SDV_FECHA_SALDO) = TRUNC(SYSDATE - 1)
        UNION
        SELECT DISTINCT SDD.SDD_CDD_CCC_CLI_PER_NUM_IDEN AS NumeroIdentificacion,
                        TID.TID_CODIGO_DAV AS TipoIdentificacion,
                        '0006' AS CodigoProducto,
                        'Otros productos Sociedad Comisionista de Bolsa' AS Descripcion
          FROM SALDOS_DIARIOS_DERIVADOS SDD
         INNER JOIN TIPOS_IDENTIFICACION TID
            ON SDD.SDD_CDD_CCC_CLI_PER_TID_CODIGO = TID.TID_CODIGO
           AND TID.TID_HABILITADO = 'S'
           AND TID.TID_CODIGO_DAV IS NOT NULL
         WHERE TRUNC(SDD_MDD_FECHA) = TRUNC(SYSDATE - 1))
      SELECT NumeroIdentificacion,
             TipoIdentificacion,
             CodigoProducto,
             Descripcion
        FROM CLIENTES_CRM;
  END P_INFO_CLIENTES_CRM_DAVIVIENDA;

  FUNCTION FN_VALIDACLIENTE(P_TID_CODIGO IN VARCHAR2,
                            P_NUM_IDEN   IN VARCHAR2) RETURN VARCHAR2 IS

    CURSOR C_CLIENTE IS
      SELECT 'X'
        FROM CUENTAS_CLIENTE_CORREDORES, PERSONAS, SUCURSALES, CLIENTES
       WHERE CCC_PER_NUM_IDEN = PER_NUM_IDEN
         AND CCC_PER_TID_CODIGO = PER_TID_CODIGO
         AND PER_SUC_CODIGO = SUC_CODIGO
         AND CCC_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
         AND CCC_CLI_PER_TID_CODIGO = CLI_PER_TID_CODIGO
         AND CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND PER_SUC_CODIGO = 11;

    C_CLI VARCHAR2(1);
    RES   VARCHAR2(1);

  BEGIN

    OPEN C_CLIENTE;
    FETCH C_CLIENTE
      INTO C_CLI;
    IF NVL(C_CLI, '') = 'X' THEN
      RES := 'S';
    ELSE
      RES := 'N';
    END IF;
    CLOSE C_CLIENTE;

    RETURN RES;
  END FN_VALIDACLIENTE;

  PROCEDURE PR_SEGMENTACION_INICIAL(P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                    P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                    P_TIPO               IN VARCHAR2,
                                    P_BANCA_PRIVADA      IN VARCHAR2,
                                    P_INST_EXT           IN VARCHAR2,
                                    P_VIG_SFC            IN VARCHAR2,
                                    P_BCC_CLIENTE        IN OUT VARCHAR2,
                                    P_BSC_CLIENTE        IN OUT VARCHAR2,
                                    P_BCC_ALT            IN OUT VARCHAR2,
                                    P_BSC_ALT            IN OUT VARCHAR2) IS
    ING_OPERACIONAL NUMBER;
    P_CARTERA       VARCHAR2(1) := 'N';

  BEGIN
    P_BCC_CLIENTE := NULL;
    P_BSC_CLIENTE := NULL;
    -- PARA IDENTIFICAR SI ES DE SEGMENTO POSICION PROPIA Y CARTERAS
    IF P_TIPO = 'PJU' THEN
      P_CARTERA := P_CLIENTES.FN_CARTERA(P_CLI_PER_NUM_IDEN);
      IF NVL(P_CARTERA, 'N') = 'S' THEN
        P_BCC_CLIENTE := 'JUR';
        P_BSC_CLIENTE := 'PPC';
      END IF;
    END IF;

    IF P_BCC_CLIENTE IS NULL THEN
      IF NVL(P_BANCA_PRIVADA, 'N') = 'S' THEN
        IF P_TIPO = 'PNA' THEN
          P_BCC_CLIENTE := 'NAT';
          P_BSC_CLIENTE := 'BPR';
        ELSE
          P_BCC_CLIENTE := 'JUR';
          P_BSC_CLIENTE := 'BPJ';
        END IF;
      ELSIF NVL(P_INST_EXT, 'N') = 'S' THEN
        P_BCC_CLIENTE := 'JUR';
        P_BSC_CLIENTE := 'INS';
      ELSIF NVL(P_VIG_SFC, 'N') = 'S' THEN
        P_BCC_CLIENTE := 'JUR';
        P_BSC_CLIENTE := 'INS';
      END IF;
    END IF;

    IF P_BCC_CLIENTE IS NULL THEN
      IF P_TIPO = 'PNA' THEN
        P_BCC_CLIENTE := 'NAT';
        P_BSC_CLIENTE := 'ORO';
      ELSIF P_TIPO = 'PJU' THEN
        ING_OPERACIONAL := P_CLIENTES.FN_INGRESO_OPERACIONAL(P_CLI_PER_NUM_IDEN,
                                                             P_CLI_PER_TID_CODIGO);
        IF ING_OPERACIONAL IS NULL OR ING_OPERACIONAL < 0 THEN
          ING_OPERACIONAL := 0;
        END IF;

        IF ING_OPERACIONAL <= 70000000000 THEN
          P_BCC_CLIENTE := 'JUR';
          P_BSC_CLIENTE := 'EMP';
        ELSE
          P_BCC_CLIENTE := 'JUR';
          PR_TRAE_SEGMENTO_CLI(ING_OPERACIONAL,
                               P_BCC_CLIENTE,
                               P_BSC_CLIENTE);
          IF P_BSC_CLIENTE IS NULL THEN
            RAISE_APPLICATION_ERROR(-20502,
                                    'No se pudo determinar la segmentacion del cliente: ' ||
                                    P_CLI_PER_NUM_IDEN || ', T. Id.: ' ||
                                    P_CLI_PER_TID_CODIGO);
          END IF;
        END IF;
      END IF;
    END IF;

    -- EL SEGMENTO ALTERNO INICIAL ES EL MISMO SEGMENTO DE CLIENTE
    P_BCC_ALT := P_BCC_CLIENTE;
    P_BSC_ALT := P_BSC_CLIENTE;

  END PR_SEGMENTACION_INICIAL;

  FUNCTION FN_INGRESO_OPERACIONAL(P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                  P_CLI_PER_TID_CODIGO IN VARCHAR2)
    RETURN NUMBER IS

    CURSOR C_EEC IS
      SELECT (NVL(EEC_INGRESO_MENSUAL, 0) * 12) EEC_INGRESO_MENSUAL
        FROM ESTADOS_ECONOMICOS
       WHERE EEC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND EEC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       ORDER BY EEC_FECHA DESC;
    P_INGRESOS NUMBER := 0;
  BEGIN
    OPEN C_EEC;
    FETCH C_EEC
      INTO P_INGRESOS;
    CLOSE C_EEC;
    P_INGRESOS := NVL(P_INGRESOS, 0);
    RETURN(P_INGRESOS);
  END FN_INGRESO_OPERACIONAL;

  FUNCTION FN_CARTERA(P_CLI_PER_NUM_IDEN IN VARCHAR2) RETURN VARCHAR2 IS

    CURSOR C_FONDO IS
      SELECT 'S'
        FROM FONDOS
       WHERE FON_ESTADO = 'A'
         AND FON_TIPO = 'A'
         AND FON_TIPO_ADMINISTRACION = 'F'
         AND SUBSTR(FON_CODIGO, 1, 9) = P_CLI_PER_NUM_IDEN;

    SINO VARCHAR2(1);
  BEGIN
    OPEN C_FONDO;
    FETCH C_FONDO
      INTO SINO;
    IF C_FONDO%NOTFOUND THEN
      SINO := 'N';
    END IF;
    CLOSE C_FONDO;
    SINO := NVL(SINO, 'N');
    RETURN(SINO);
  END FN_CARTERA;
  -- ---------------------------------------------------------
  PROCEDURE PR_SEGMENTA_CLIENTE(P_FECHA IN DATE,
                                P_TX    IN NUMBER DEFAULT NULL) IS
    CURSOR C_CLI IS
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             PER_TIPO,
             CLI_INSTITUCIONAL_EXTRANJERO,
             CLI_VIGILADO_SFC,
             CLI_BANCA_PRIVADA,
             CLI_BSC_BCC_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO_ALT,
             CLI_BSC_MNEMONICO_ALT,
             'N' ES_CARTERA
        FROM CLIENTES, PERSONAS
       WHERE CLI_PER_NUM_IDEN = PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = PER_TID_CODIGO
         AND CLI_TIPO_CLIENTE IN ('C', 'A')
         AND CLI_ECL_MNEMONICO != 'INA'
         AND NVL(CLI_BANCA_PRIVADA, 'N') = 'N'
         AND NOT EXISTS
       (SELECT 'X'
                FROM FONDOS
               WHERE FON_ESTADO = 'A'
                 AND FON_TIPO = 'A'
                 AND FON_TIPO_ADMINISTRACION = 'F'
                 AND SUBSTR(FON_CODIGO, 1, 9) = CLI_PER_NUM_IDEN)
      UNION ALL
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             PER_TIPO,
             CLI_INSTITUCIONAL_EXTRANJERO,
             CLI_VIGILADO_SFC,
             CLI_BANCA_PRIVADA,
             CLI_BSC_BCC_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO_ALT,
             CLI_BSC_MNEMONICO_ALT,
             'S' ES_CARTERA
        FROM CLIENTES, PERSONAS
       WHERE CLI_PER_NUM_IDEN = PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = PER_TID_CODIGO
         AND CLI_TIPO_CLIENTE IN ('C', 'A')
         AND CLI_ECL_MNEMONICO != 'INA'
         AND NVL(CLI_BANCA_PRIVADA, 'N') = 'N'
         AND EXISTS
       (SELECT 'X'
                FROM FONDOS
               WHERE FON_ESTADO = 'A'
                 AND FON_TIPO = 'A'
                 AND FON_TIPO_ADMINISTRACION = 'F'
                 AND SUBSTR(FON_CODIGO, 1, 9) = CLI_PER_NUM_IDEN);
    R_CLI C_CLI%ROWTYPE;

    P_DIAS               NUMBER := 0;
    VALOR_AUM            NUMBER := 0;
    ING_OPERACIONAL      NUMBER := 0;
    VALOR_PORT           NUMBER := 0;
    P_CARTERA            VARCHAR2(1) := 'N';
    P_FECHA_DESDE        DATE;
    P_FECHA_HASTA        DATE;
    P_BCC_CLIENTE        CLIENTES.CLI_BSC_BCC_MNEMONICO%TYPE := NULL;
    P_BSC_CLIENTE        CLIENTES.CLI_BSC_MNEMONICO%TYPE := NULL;
    P_BCC_ALT            CLIENTES.CLI_BSC_BCC_MNEMONICO%TYPE := NULL;
    P_BSC_ALT            CLIENTES.CLI_BSC_MNEMONICO%TYPE := NULL;
    V_CLI_PER_NUM_IDEN   CLIENTES.CLI_PER_NUM_IDEN%TYPE := NULL;
    V_CLI_PER_TID_CODIGO CLIENTES.CLI_PER_TID_CODIGO%TYPE := NULL;
    ERRORSQL             VARCHAR2(100);
    NO_SEGMENTO EXCEPTION;
    N_ID_PROCESO NUMBER;
    N_TX         NUMBER;

  BEGIN

    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_CLIENTES.PR_SEGMENTA_CLIENTE');

    --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio proceso P_CLIENTES.PR_SEGMENTA_CLIENTE. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE,
                                            'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
    SELECT CON_VALOR
      INTO P_DIAS
      FROM CONSTANTES
     WHERE CON_MNEMONICO = 'AUM';
    P_DIAS := NVL(P_DIAS, 0);
    IF P_DIAS < 0 THEN
      P_DIAS := 0;
    END IF;
    P_FECHA_DESDE := P_FECHA - P_DIAS;
    P_FECHA_HASTA := P_FECHA;
    OPEN C_CLI;
    FETCH C_CLI
      INTO R_CLI;
    WHILE C_CLI%FOUND LOOP
      BEGIN
        P_BCC_CLIENTE        := NULL;
        P_BSC_CLIENTE        := NULL;
        P_BCC_ALT            := NULL;
        P_BSC_ALT            := NULL;
        VALOR_AUM            := 0;
        ING_OPERACIONAL      := 0;
        VALOR_PORT           := 0;
        V_CLI_PER_NUM_IDEN   := R_CLI.CLI_PER_NUM_IDEN;
        V_CLI_PER_TID_CODIGO := R_CLI.CLI_PER_TID_CODIGO;

        IF R_CLI.ES_CARTERA = 'S' THEN
          P_BCC_CLIENTE := 'JUR';
          P_BSC_CLIENTE := 'PPC';
        END IF;

        -- PARA LOS INDICADORES
        IF P_BCC_CLIENTE IS NULL THEN
          IF NVL(R_CLI.CLI_BANCA_PRIVADA, 'N') = 'S' THEN
            IF R_CLI.PER_TIPO = 'PNA' THEN
              P_BCC_CLIENTE := 'NAT';
              P_BSC_CLIENTE := 'BPR';
            ELSE
              P_BCC_CLIENTE := 'JUR';
              P_BSC_CLIENTE := 'BPJ';
            END IF;
          ELSIF NVL(R_CLI.CLI_INSTITUCIONAL_EXTRANJERO, 'N') = 'S' THEN
            P_BCC_CLIENTE := 'JUR';
            P_BSC_CLIENTE := 'INS';
          ELSIF NVL(R_CLI.CLI_VIGILADO_SFC, 'N') = 'S' THEN
            P_BCC_CLIENTE := 'JUR';
            P_BSC_CLIENTE := 'INS';
          END IF;
        END IF;

        IF P_BCC_CLIENTE IS NULL AND P_BSC_CLIENTE IS NULL THEN
          IF R_CLI.PER_TIPO = 'PNA' THEN
            P_BCC_CLIENTE := 'NAT';
            VALOR_AUM     := P_CLIENTES.FN_AUM_CLIENTE(R_CLI.CLI_PER_NUM_IDEN,
                                                       R_CLI.CLI_PER_TID_CODIGO,
                                                       P_FECHA_DESDE,
                                                       P_FECHA_HASTA);
            IF VALOR_AUM IS NULL OR VALOR_AUM < 0 THEN
              VALOR_AUM := 0;
            END IF;
            VALOR_PORT := VALOR_AUM;
            P_CLIENTES.PR_TRAE_SEGMENTO_CLI(VALOR_AUM,
                                            P_BCC_CLIENTE,
                                            P_BSC_CLIENTE);
            IF P_BSC_CLIENTE IS NULL THEN
              RAISE NO_SEGMENTO;
            END IF;
          ELSIF R_CLI.PER_TIPO = 'PJU' THEN
            P_BCC_CLIENTE   := 'JUR';
            ING_OPERACIONAL := P_CLIENTES.FN_INGRESO_OPERACIONAL(R_CLI.CLI_PER_NUM_IDEN,
                                                                 R_CLI.CLI_PER_TID_CODIGO);
            IF ING_OPERACIONAL IS NULL OR ING_OPERACIONAL <= 0 THEN
              ING_OPERACIONAL := 0;
            END IF;
            VALOR_PORT := ING_OPERACIONAL;
            P_CLIENTES.PR_TRAE_SEGMENTO_CLI(ING_OPERACIONAL,
                                            P_BCC_CLIENTE,
                                            P_BSC_CLIENTE);
            IF P_BSC_CLIENTE IS NULL THEN
              RAISE NO_SEGMENTO;
            END IF;
          END IF;
        END IF;

        IF P_BCC_CLIENTE IS NULL OR P_BSC_CLIENTE IS NULL THEN
          RAISE NO_SEGMENTO;
        END IF;

        P_BCC_ALT := P_BCC_CLIENTE;
        P_BSC_ALT := P_BSC_CLIENTE;

        IF NVL(R_CLI.CLI_BSC_BCC_MNEMONICO, 'X') != NVL(P_BCC_CLIENTE, 'X') OR
           NVL(R_CLI.CLI_BSC_MNEMONICO, 'X') != NVL(P_BSC_CLIENTE, 'X') OR
           NVL(R_CLI.CLI_BSC_BCC_MNEMONICO_ALT, 'X') != NVL(P_BCC_ALT, 'X') OR
           NVL(R_CLI.CLI_BSC_MNEMONICO_ALT, 'X') != NVL(P_BSC_ALT, 'X') THEN

          UPDATE CLIENTES
             SET CLI_BSC_BCC_MNEMONICO          = P_BCC_CLIENTE,
                 CLI_BSC_MNEMONICO              = P_BSC_CLIENTE,
                 CLI_BSC_BCC_MNEMONICO_ALT      = P_BCC_ALT,
                 CLI_BSC_MNEMONICO_ALT          = P_BSC_ALT,
                 CLI_FECHA_ULTIMA_MODIFICACION  = SYSDATE,
                 CLI_USUARIO_ULTIMA_MODIFICA    = USER,
                 CLI_ULTIMA_OPERACION_EJECUTADA = 'MO',
                 CLI_FECHA_ULT_MOD_MASIVA       = SYSDATE
           WHERE CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
             AND CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;

        END IF;
      EXCEPTION
        WHEN NO_SEGMENTO THEN
          ERRORSQL := SUBSTR(SQLERRM, 1, 80);
          ROLLBACK;
          P_CLIENTES.PR_INSERTA_ERROR_SEGMENTA(P_PROCESO => 'PR_SEGMENTA_CLIENTE',
                                               P_ERROR   => 'CLIENTE ' ||
                                                            V_CLI_PER_NUM_IDEN || '-' ||
                                                            V_CLI_PER_TID_CODIGO || '- ' ||
                                                            ERRORSQL);
          P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                          'E',
                                          'P_CLIENTES.PR_SEGMENTA_CLIENTE. Fecha: ' ||
                                          TO_CHAR(SYSDATE,
                                                  'DD-MM-YYYY HH24:mi:ss') || ' ' ||
                                          SUBSTR(SQLERRM, 1, 80),
                                          N_TX);

        WHEN OTHERS THEN
          ERRORSQL := SUBSTR(SQLERRM, 1, 80);
          ROLLBACK;
          P_CLIENTES.PR_INSERTA_ERROR_SEGMENTA(P_PROCESO => 'PR_SEGMENTA_CLIENTE',
                                               P_ERROR   => 'CLIENTE ' ||
                                                            V_CLI_PER_NUM_IDEN || '-' ||
                                                            V_CLI_PER_TID_CODIGO || '- ' ||
                                                            ERRORSQL);
          P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                          'E',
                                          'P_CLIENTES.PR_SEGMENTA_CLIENTE. Fecha: ' ||
                                          TO_CHAR(SYSDATE,
                                                  'DD-MM-YYYY HH24:mi:ss') || ' ' ||
                                          SUBSTR(SQLERRM, 1, 80),
                                          N_TX);

      END;
      COMMIT;
      FETCH C_CLI
        INTO R_CLI;
    END LOOP;
    CLOSE C_CLI;
    COMMIT;
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'F',
                                    'Fin P_CLIENTES.PR_SEGMENTA_CLIENTE. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE,
                                            'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
  EXCEPTION
    WHEN OTHERS THEN
      ERRORSQL := SUBSTR(SQLERRM, 1, 80);
      ROLLBACK;
      P_CLIENTES.PR_INSERTA_ERROR_SEGMENTA(P_PROCESO => 'PR_SEGMENTA_CLIENTE',
                                           P_ERROR   => 'CLIENTE ' ||
                                                        V_CLI_PER_NUM_IDEN || '-' ||
                                                        V_CLI_PER_TID_CODIGO || '- ' ||
                                                        ERRORSQL);
      P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                      'E',
                                      'P_CLIENTES.PR_SEGMENTA_CLIENTE. Fecha: ' ||
                                      TO_CHAR(SYSDATE,
                                              'DD-MM-YYYY HH24:mi:ss') || ' ' ||
                                      SUBSTR(SQLERRM, 1, 80),
                                      N_TX);

      commit;
  END PR_SEGMENTA_CLIENTE;
  -- ---------------------------------------------------------------
  PROCEDURE PR_SEGMENTA_ALTERNO_CLIENTE(P_TX IN NUMBER DEFAULT NULL) IS
    CURSOR C_GRU IS
      SELECT GRU_CODIGO
        FROM GRUPOS
       WHERE GRU_ESTADO = 'A'
       ORDER BY GRU_CODIGO;
    R_GRU C_GRU%ROWTYPE;

    CURSOR C_CLI(P_GRU NUMBER) IS
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             PER_TIPO,
             CLI_INSTITUCIONAL_EXTRANJERO,
             CLI_VIGILADO_SFC,
             CLI_BANCA_PRIVADA,
             CLI_BSC_BCC_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO_ALT,
             CLI_BSC_MNEMONICO_ALT,
             BSC_ORDEN
        FROM CLIENTES, PERSONAS, GRUPOS_CUENTAS, BI_SEGMENTACION_CLIENTES
       WHERE CLI_PER_NUM_IDEN = PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = PER_TID_CODIGO
         AND CLI_PER_NUM_IDEN = GCU_CLI_PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = GCU_CLI_PER_TID_CODIGO
         AND CLI_BSC_BCC_MNEMONICO = BSC_BCC_MNEMONICO
         AND CLI_BSC_MNEMONICO = BSC_MNEMONICO
         AND GCU_GRU_CODIGO = P_GRU
         AND NVL(CLI_BANCA_PRIVADA, 'N') != 'S'
         AND CLI_ECL_MNEMONICO != 'INA'
         AND NVL(CLI_BANCA_PRIVADA, 'N') = 'N'
         AND PER_TIPO = 'PNA'
       ORDER BY BSC_ORDEN DESC;
    R_CLI        C_CLI%ROWTYPE;
    P_BCC        BI_SEGMENTACION_CLIENTES.BSC_BCC_MNEMONICO%TYPE;
    P_BSC        BI_SEGMENTACION_CLIENTES.BSC_MNEMONICO%TYPE;
    N_ID_PROCESO NUMBER;
    N_TX         NUMBER;

  BEGIN
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_CLIENTES.PR_SEGMENTA_ALTERNO_CLIENTE');

    --se Asigna consecutivo para la transaccion, si el proceso es el primero que se llama, reinicia el consecutivo
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Registra Traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio proceso P_CLIENTES.PR_SEGMENTA_ALTERNO_CLIENTE. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE,
                                            'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
    OPEN C_GRU;
    FETCH C_GRU
      INTO R_GRU;
    WHILE C_GRU%FOUND LOOP
      OPEN C_CLI(R_GRU.GRU_CODIGO);
      FETCH C_CLI
        INTO R_CLI;
      IF C_CLI%FOUND THEN
        P_BCC := R_CLI.CLI_BSC_BCC_MNEMONICO;
        P_BSC := R_CLI.CLI_BSC_MNEMONICO;
      END IF;
      CLOSE C_CLI;

      OPEN C_CLI(R_GRU.GRU_CODIGO);
      FETCH C_CLI
        INTO R_CLI;
      WHILE C_CLI%FOUND LOOP
        IF R_CLI.CLI_BSC_BCC_MNEMONICO != P_BCC OR
           R_CLI.CLI_BSC_MNEMONICO != P_BSC THEN
          UPDATE CLIENTES
             SET CLI_BSC_BCC_MNEMONICO_ALT      = P_BCC,
                 CLI_BSC_MNEMONICO_ALT          = P_BSC,
                 CLI_FECHA_ULTIMA_MODIFICACION  = SYSDATE,
                 CLI_USUARIO_ULTIMA_MODIFICA    = USER,
                 CLI_ULTIMA_OPERACION_EJECUTADA = 'MO',
                 CLI_FECHA_ULT_MOD_MASIVA       = SYSDATE
           WHERE CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
             AND CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
        END IF;
        FETCH C_CLI
          INTO R_CLI;
      END LOOP;
      CLOSE C_CLI;
      FETCH C_GRU
        INTO R_GRU;
    END LOOP;
    CLOSE C_GRU;
    COMMIT;

    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'F',
                                    'Fin P_CLIENTES.PR_SEGMENTA_ALTERNO_CLIENTE. Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE,
                                            'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);
  END PR_SEGMENTA_ALTERNO_CLIENTE;
  -- --------------------------------------------------------------------------
  FUNCTION FN_AUM_CLIENTE(P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                          P_CLI_PER_TID_CODIGO IN VARCHAR2,
                          P_FECHA_DESDE        IN DATE,
                          P_FECHA_HASTA        IN DATE) RETURN NUMBER IS

    CURSOR CUR_FONDO IS
      SELECT FON_CODIGO, FON_NPR_PRO_MNEMONICO, FON_BMO_MNEMONICO
        FROM FONDOS
       WHERE FON_TIPO = 'A'
            --AND FON_ESTADO              = 'A'
         AND fon_tipo_administracion = 'F'
         AND FON_CODIGO NOT IN
             ('111111', '999999', '900460112', '900400643-B')
         AND NOT EXISTS (SELECT 'X'
                FROM PARAMETROS_FONDOS
               WHERE PFO_FON_CODIGO = FON_CODIGO
                 AND PFO_PAR_CODIGO = 73
                 AND NVL(PFO_RANGO_MIN_CHAR, 'N') = 'S')
         AND EXISTS
       (SELECT 'X'
                FROM CUENTAS_FONDOS
               WHERE CFO_FON_CODIGO = FON_CODIGO
                 AND CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
                 AND CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO)
       order by FON_CODIGO;

    CURSOR CUR_SALDOS(PRODUCTO        VARCHAR2,
                      BMO             VARCHAR2,
                      P_COMPARTIMENTO VARCHAR2,
                      P_FON_CODIGO    VARCHAR2) is
      SELECT TRUNC(SAD_FECHA) FECHA,
             SUM(SAD_SALDO *
                 DECODE(BMO,
                        'PESOS',
                        1,
                        P_ULTIMOS_MOVIMIENTOS.P_ULTIMA_COTIZACION_MONEDA(BMO,
                                                                         SAD_FECHA))) SALDO,
             SAD_CCC_CLI_PER_NUM_IDEN,
             SAD_CCC_CLI_PER_TID_CODIGO,
             SAD_CCC_NUMERO_CUENTA
        FROM SALDOS_DIARIOS SAD, CUENTAS_CLIENTE_CORREDORES CCC
       WHERE SAD_CCC_CLI_PER_NUM_IDEN = CCC_CLI_PER_NUM_IDEN
         AND SAD_CCC_CLI_PER_TID_CODIGO = CCC_CLI_PER_TID_CODIGO
         AND SAD_CCC_NUMERO_CUENTA = CCC_NUMERO_CUENTA
         AND ((P_COMPARTIMENTO = 'N' AND SAD_PRO_MNEMONICO = PRODUCTO) OR
             (P_COMPARTIMENTO = 'S' AND SAD_PRO_MNEMONICO = PRODUCTO AND
             SAD_FON_CODIGO = P_FON_CODIGO))
         AND SAD_FECHA >= TRUNC(P_FECHA_DESDE)
         AND SAD_FECHA < TRUNC(P_FECHA_HASTA + 1)
         AND SAD_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND SAD_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       GROUP BY TRUNC(SAD_FECHA),
                SAD_CCC_CLI_PER_NUM_IDEN,
                SAD_CCC_CLI_PER_TID_CODIGO,
                SAD_CCC_NUMERO_CUENTA
       ORDER BY 1;

    CURSOR CUR_APT IS
      SELECT FON_CODIGO, FON_NPR_PRO_MNEMONICO, FON_BMO_MNEMONICO
        FROM FONDOS
       WHERE FON_TIPO = 'A'
         AND FON_TIPO_ADMINISTRACION = 'A'
         AND EXISTS
       (SELECT 'X'
                FROM CUENTAS_FONDOS
               WHERE CFO_FON_CODIGO = FON_CODIGO
                 AND CFO_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
                 AND CFO_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO);

    CURSOR CUR_SALDOS_APT(P_FON_CODIGO VARCHAR2) is
      SELECT TRUNC(SAD_FECHA) FECHA,
             SUM(SAD_SALDO) SALDO,
             SAD_CCC_CLI_PER_NUM_IDEN,
             SAD_CCC_CLI_PER_TID_CODIGO,
             SAD_CCC_NUMERO_CUENTA
        FROM SALDOS_DIARIOS SAD
       WHERE SAD_FON_CODIGO = P_FON_CODIGO
         AND SAD_FECHA >= TRUNC(P_FECHA_DESDE)
         AND SAD_FECHA < TRUNC(P_FECHA_HASTA + 1)
         AND SAD_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND SAD_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       GROUP BY TRUNC(SAD_FECHA),
                SAD_CCC_CLI_PER_NUM_IDEN,
                SAD_CCC_CLI_PER_TID_CODIGO,
                SAD_CCC_NUMERO_CUENTA;

    P_COMPARTIMENTO VARCHAR2(1) := 'N';
    FDESDE          DATE;
    PROMEDIO        NUMBER := 0;
    OBSERVACIONES   NUMBER := 0;
    V_REGISTRO      P_WEB_PORTAFOLIO.O_CURSOR;
    P_TIPO          VARCHAR2(12);
    P_GARANTIAS     NUMBER(22, 2);
    TOTAL_GARANTIAS NUMBER := 0;
    P_CUENTA        NUMBER;
  BEGIN
    DELETE FROM GL_AUM_CLIENTE;

    -- portafolio de clientes renta fija
    INSERT INTO GL_AUM_CLIENTE
      (FECHA, ORIGEN, VALOR)
      SELECT HST_FECHA,
             'RF',
             SUM(HST_VALOR_TM_DISPONIBLE + HST_VALOR_TM_GARANTIA +
                 HST_VALOR_TM_EMBARGO + HST_VALOR_TM_GARDER) SALDO_PESOS
        FROM HISTORICOS_SALDOS_TITULOS
       WHERE HST_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND HST_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND HST_FECHA >= TRUNC(P_FECHA_DESDE)
         AND HST_FECHA < TRUNC(P_FECHA_HASTA + 1)
         AND (EXISTS (SELECT 'X'
                        FROM FUNGIBLES
                       WHERE FUG_ISI_MNEMONICO = HST_CFC_FUG_ISI_MNEMONICO
                         AND FUG_MNEMONICO = HST_CFC_FUG_MNEMONICO
                         AND FUG_TIPO = 'RF') OR EXISTS
              (SELECT 'X'
                 FROM TITULOS
                WHERE TLO_CODIGO = HST_TLO_CODIGO
                  AND TLO_TYPE = 'TFC'))
       GROUP BY HST_FECHA, 'RF';

    -- portafolio de clientes renta variable
    INSERT INTO GL_AUM_CLIENTE
      (FECHA, ORIGEN, VALOR)
      SELECT HST_FECHA,
             'ACC',
             SUM(HST_VALOR_TM_DISPONIBLE + HST_VALOR_TM_GARANTIA +
                 HST_VALOR_TM_EMBARGO + HST_VALOR_TM_GARDER) SALDO_PESOS
        FROM HISTORICOS_SALDOS_TITULOS
       WHERE HST_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND HST_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND HST_FECHA >= TRUNC(P_FECHA_DESDE)
         AND HST_FECHA < TRUNC(P_FECHA_HASTA + 1)
         AND (EXISTS (SELECT 'X'
                        FROM FUNGIBLES
                       WHERE FUG_ISI_MNEMONICO = HST_CFC_FUG_ISI_MNEMONICO
                         AND FUG_MNEMONICO = HST_CFC_FUG_MNEMONICO
                         AND FUG_TIPO = 'ACC') OR EXISTS
              (SELECT 'X'
                 FROM TITULOS
                WHERE TLO_CODIGO = HST_TLO_CODIGO
                  AND TLO_TYPE = 'TVC'))
       GROUP BY HST_FECHA, 'ACC';

    -- clientes con carteras colectivas
    FOR REG_FON IN CUR_FONDO LOOP
      P_COMPARTIMENTO := 'N';
      P_ORDENES_FONDOS.P_VALIDA_PARAMETROS_COMP(P_FON_CODIGO         => REG_FON.FON_CODIGO,
                                                P_PAR_CODIGO         => 70,
                                                P_PFO_RANGO_MIN_CHAR => P_COMPARTIMENTO);
      p_compartimento := NVL(p_compartimento, 'N');

      FOR REG_SAL IN CUR_SALDOS(REG_FON.FON_NPR_PRO_MNEMONICO,
                                REG_FON.FON_BMO_MNEMONICO,
                                P_COMPARTIMENTO,
                                REG_FON.FON_CODIGO) LOOP
        INSERT INTO GL_AUM_CLIENTE
          (FECHA, ORIGEN, VALOR)
        VALUES
          (REG_SAL.FECHA, REG_FON.FON_CODIGO, REG_SAL.SALDO);
      END LOOP;
    END LOOP;

    -- clientes con apt's
    FOR REG_APT IN CUR_APT LOOP

      FOR REG_SAL_APT IN CUR_SALDOS_APT(REG_APT.FON_CODIGO) LOOP
        INSERT INTO GL_AUM_CLIENTE
          (FECHA, ORIGEN, VALOR)
        VALUES
          (REG_SAL_APT.FECHA, REG_APT.FON_CODIGO, REG_SAL_APT.SALDO);
      END LOOP;
    END LOOP;

    -- Garantías en efectivo para derivados
    INSERT INTO GL_AUM_CLIENTE
      (FECHA, ORIGEN, VALOR)
      SELECT GAEF_FECHA, GAEF_TIPO, SUM(GAEF_VALOR) GAEF_VALOR
        FROM GARANTIAS_EFECTIVO
       WHERE GAEF_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND GAEF_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND GAEF_FECHA >= TRUNC(P_FECHA_DESDE)
         AND GAEF_FECHA < TRUNC(P_FECHA_HASTA + 1)
       GROUP BY GAEF_FECHA, GAEF_TIPO;

    -- PROMEDIO AUM
    SELECT COUNT(DISTINCT TRUNC(FECHA))
      INTO OBSERVACIONES
      FROM GL_AUM_CLIENTE
     WHERE VALOR != 0;
    IF NVL(OBSERVACIONES, 0) > 0 THEN
      SELECT NVL(SUM(VALOR), 0) INTO PROMEDIO FROM GL_AUM_CLIENTE;
      PROMEDIO := PROMEDIO / OBSERVACIONES;
    ELSE
      PROMEDIO := 0;
    END IF;
    RETURN(PROMEDIO);

  END FN_AUM_CLIENTE;

  PROCEDURE PR_TRAE_SEGMENTO_CLI(P_VALOR IN NUMBER,
                                 P_BCC   IN CLIENTES.CLI_BSC_BCC_MNEMONICO%TYPE DEFAULT NULL,
                                 P_BSC   IN OUT CLIENTES.CLI_BSC_MNEMONICO%TYPE) IS
  BEGIN
    SELECT BSC_MNEMONICO
      INTO P_BSC
      FROM BI_SEGMENTACION_CLIENTES
     WHERE BSC_BCC_MNEMONICO = P_BCC
       AND BSC_CRITERIO IN ('AUM', 'IOP')
       AND P_VALOR >= BSC_RANGO_MINIMO
       AND P_VALOR <= BSC_RANGO_MAXIMO;

  END PR_TRAE_SEGMENTO_CLI;

  /**********************************************************************************
  ***  Procedimiento de Inserta errores en la tabla ERRORES_SEGMENTACION    **
  ******************************************************************************** */
  PROCEDURE PR_INSERTA_ERROR_SEGMENTA(P_PROCESO IN ERRORES_SEGMENTACION.ERSE_PROCESO%TYPE,
                                      P_ERROR   IN ERRORES_SEGMENTACION.ERSE_ERROR%TYPE) IS
  BEGIN
    INSERT INTO ERRORES_SEGMENTACION
      (ERSE_CONSECUTIVO, ERSE_FECHA, ERSE_PROCESO, ERSE_ERROR)
    VALUES
      (ERSE_SEQ.NEXTVAL,
       SYSDATE,
       SUBSTR(P_PROCESO, 1, 200),
       substr(P_ERROR, 1, 500));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001, SQLERRM);
  END PR_INSERTA_ERROR_SEGMENTA;

  /********************************************************************************************
  ***  Procedimiento de Inserta en la tabla GARANTIAS_EFECTIVO las garantias de una fecha    **
  ****************************************************************************************** */

  PROCEDURE PR_GARANTIA_EFECTIVO_DIA(P_FECHA IN DATE,
                                     P_TX    IN NUMBER DEFAULT NULL) IS

    N_TX         NUMBER;
    N_ID_PROCESO NUMBER;

  BEGIN
    --se asigna consecutivo del proceso(tabla PARAMETRIZACION_PROCESOS)
    N_ID_PROCESO := P_TRAZA_CORE.FN_ID_PROCESO('P_CLIENTES.PR_GARANTIA_EFECTIVO_DIA');

    --se Asigna consecutivo para la transaccion
    N_TX := P_TRAZA_CORE.FN_TRAE_TX(P_TX);

    --Se llama proceso para registrar traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'I',
                                    'Inicio P_CLIENTES.PR_GARANTIA_EFECTIVO_DIA . Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE,
                                            'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);

    DELETE FROM GARANTIAS_EFECTIVO
     WHERE GAEF_FECHA >= TRUNC(P_FECHA)
       AND GAEF_FECHA < TRUNC(P_FECHA + 1);

    DELETE FROM GL_GARANTIA_DIA TRUNCATE;

    INSERT INTO GL_GARANTIA_DIA
      (CCC_CLI_PER_NUM_IDEN,
       CCC_CLI_PER_TID_CODIGO,
       CCC_NUMERO_CUENTA,
       FECHA,
       TIPO,
       VALOR)
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CCC_NUMERO_CUENTA,
             TRUNC(P_FECHA),
             TIPO_DET TIPO,
             SUM(VALOR_ODP) - SUM(VALOR_RCA) VALOR
        FROM (SELECT 'BVC' TIPO_DET,
                     NVL(CCA_MONTO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA, CHEQUES_CAJA
               WHERE RCA_SUC_CODIGO = CCA_RCA_SUC_CODIGO
                 AND RCA_NEG_CONSECUTIVO = CCA_RCA_NEG_CONSECUTIVO
                 AND RCA_CONSECUTIVO = CCA_RCA_CONSECUTIVO
                 AND RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO = 'RGCE'
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND CCA_MONTO != 0
              UNION ALL
              SELECT 'BVC' TIPO_DET,
                     NVL(CCJ_MONTO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA, CONSIGNACIONES_CAJA
               WHERE RCA_SUC_CODIGO = CCJ_RCA_SUC_CODIGO
                 AND RCA_NEG_CONSECUTIVO = CCJ_RCA_NEG_CONSECUTIVO
                 AND RCA_CONSECUTIVO = CCJ_RCA_CONSECUTIVO
                 AND RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO = 'RGCE'
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND CCJ_MONTO != 0
              UNION ALL
              SELECT 'BVC' TIPO_DET,
                     NVL(TRC_MONTO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
               WHERE RCA_SUC_CODIGO = TRC_RCA_SUC_CODIGO
                 AND RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO
                 AND RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
                 AND RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO = 'RGCE'
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND TRC_MONTO != 0
              UNION ALL
              SELECT 'BVC' TIPO_DET,
                     NVL(RCA_MONTO_EN_EFECTIVO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA
               WHERE RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO = 'RGCE'
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND RCA_MONTO_EN_EFECTIVO != 0
              UNION ALL
              SELECT 'BVC' TIPO_DET,
                     0 VALOR_RCA,
                     NVL(ODP_MONTO_ORDEN, 0) VALOR_ODP,
                     ODP_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     ODP_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     ODP_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM ORDENES_DE_PAGO
               WHERE ODP_ESTADO = 'APR'
                 AND ODP_ES_CLIENTE = 'S'
                 AND ODP_COT_MNEMONICO = 'GOPCE'
                 AND ODP_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA + 1)
                 AND ODP_MONTO_ORDEN != 0
              ----------------------------DERIVADOS------------------------------
              UNION ALL
              SELECT 'CRCC' TIPO_DET,
                     NVL(CCA_MONTO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA, CHEQUES_CAJA
               WHERE RCA_SUC_CODIGO = CCA_RCA_SUC_CODIGO
                 AND RCA_NEG_CONSECUTIVO = CCA_RCA_NEG_CONSECUTIVO
                 AND RCA_CONSECUTIVO = CCA_RCA_CONSECUTIVO
                 AND RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO IN ('DGDE', 'CGRCR', 'DGRCR')
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND CCA_MONTO != 0
              UNION ALL
              SELECT 'CRCC' TIPO_DET,
                     NVL(CCJ_MONTO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA, CONSIGNACIONES_CAJA
               WHERE RCA_SUC_CODIGO = CCJ_RCA_SUC_CODIGO
                 AND RCA_NEG_CONSECUTIVO = CCJ_RCA_NEG_CONSECUTIVO
                 AND RCA_CONSECUTIVO = CCJ_RCA_CONSECUTIVO
                 AND RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO IN ('DGDE', 'CGRCR', 'DGRCR')
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND CCJ_MONTO != 0
              UNION ALL
              SELECT 'CRCC' TIPO_DET,
                     NVL(TRC_MONTO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA, TRANSFERENCIAS_CAJA
               WHERE RCA_SUC_CODIGO = TRC_RCA_SUC_CODIGO
                 AND RCA_NEG_CONSECUTIVO = TRC_RCA_NEG_CONSECUTIVO
                 AND RCA_CONSECUTIVO = TRC_RCA_CONSECUTIVO
                 AND RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO IN ('DGDE', 'CGRCR', 'DGRCR')
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND TRC_MONTO != 0
              UNION ALL
              SELECT 'CRCC' TIPO_DET,
                     NVL(RCA_MONTO_EN_EFECTIVO, 0) VALOR_RCA,
                     0 VALOR_ODP,
                     RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     RCA_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     RCA_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM RECIBOS_DE_CAJA
               WHERE RCA_ES_CLIENTE = 'S'
                 AND RCA_REVERSADO = 'N'
                 AND RCA_COT_MNEMONICO IN ('DGDE', 'CGRCR', 'DGRCR')
                 AND RCA_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND RCA_FECHA < TRUNC(P_FECHA + 1)
                 AND RCA_MONTO_EN_EFECTIVO != 0
              UNION ALL
              SELECT 'CRCC' TIPO_DET,
                     0 VALOR_RCA,
                     NVL(ODP_MONTO_ORDEN, 0) VALOR_ODP,
                     ODP_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                     ODP_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO,
                     ODP_CCC_NUMERO_CUENTA CCC_NUMERO_CUENTA
                FROM ORDENES_DE_PAGO
               WHERE ODP_ESTADO = 'APR'
                 AND ODP_ES_CLIENTE = 'S'
                 AND ODP_COT_MNEMONICO IN ('CGDE', 'CGRCR', 'DGRCR')
                 AND ODP_FECHA > TO_DATE('01-08-2006', 'DD-MM-YYYY')
                 AND ODP_FECHA_EJECUCION < TRUNC(P_FECHA + 1)
                 AND (ODP_CEG_CONSECUTIVO IS NOT NULL OR
                     ODP_CGE_CONSECUTIVO IS NOT NULL OR
                     ODP_TBC_CONSECUTIVO IS NOT NULL OR
                     ODP_TCC_CONSECUTIVO IS NOT NULL)
                 AND ODP_MONTO_ORDEN != 0)
       GROUP BY CLI_PER_NUM_IDEN,
                CLI_PER_TID_CODIGO,
                CCC_NUMERO_CUENTA,
                TRUNC(P_FECHA),
                TIPO_DET
      HAVING SUM(VALOR_ODP) - SUM(VALOR_RCA) != 0;

    INSERT INTO GARANTIAS_EFECTIVO
      (GAEF_CONSECUTIVO,
       GAEF_CCC_CLI_PER_NUM_IDEN,
       GAEF_CCC_CLI_PER_TID_CODIGO,
       GAEF_CCC_NUMERO_CUENTA,
       GAEF_FECHA,
       GAEF_TIPO,
       GAEF_VALOR)
      SELECT GAEF_SEQ.NEXTVAL,
             CCC_CLI_PER_NUM_IDEN,
             CCC_CLI_PER_TID_CODIGO,
             CCC_NUMERO_CUENTA,
             FECHA,
             TIPO,
             VALOR
        FROM GL_GARANTIA_DIA;
    COMMIT;

    --Se llama proceso para registrar traza
    P_TRAZA_CORE.PR_REGISTRAR_TRAZA(N_ID_PROCESO,
                                    'F',
                                    'Fin P_CLIENTES.PR_GARANTIA_EFECTIVO_DIA . Fecha Proceso: ' ||
                                    TO_CHAR(SYSDATE,
                                            'DD-MM-YYYY HH24:mi:ss'),
                                    N_TX);

  END PR_GARANTIA_EFECTIVO_DIA;

  FUNCTION FN_VALIDA_CON_DERIVADOS(P_TID_CODIGO IN VARCHAR2,
                                   P_NUM_IDEN   IN VARCHAR2) RETURN VARCHAR2 IS

    CURSOR C1 IS
      SELECT 'S'
        FROM CONTRATOS
       WHERE CNT_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND CNT_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND CNT_ESTADO = 'A'
         AND CNT_TIPO_PRODUCTO = 'DER'
         AND NVL(CNT_GARANTIA_EFECTIVO, 'N') = 'N';

    CURSOR C2 IS
      SELECT 'S'
        FROM CONTRATOS
       WHERE CNT_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND CNT_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND CNT_ESTADO = 'A'
         AND CNT_TIPO_PRODUCTO = 'DER'
         AND NVL(CNT_GARANTIA_EFECTIVO, 'N') = 'S';

    V_VALIDA   VARCHAR2(1);
    V_VALIDA_E VARCHAR2(1);
  BEGIN
    V_VALIDA   := NULL;
    V_VALIDA_E := NULL;
    OPEN C1;
    FETCH C1
      INTO V_VALIDA;
    CLOSE C1;

    OPEN C2;
    FETCH C2
      INTO V_VALIDA_E;
    CLOSE C2;

    V_VALIDA   := NVL(V_VALIDA, 'N');
    V_VALIDA_E := NVL(V_VALIDA_E, 'N');

    IF V_VALIDA = 'S' AND V_VALIDA_E = 'S' THEN
      RETURN('S');
    ELSIF V_VALIDA = 'N' AND V_VALIDA_E = 'S' THEN
      RETURN('S');
    ELSE
      RETURN('N');
    END IF;
  END FN_VALIDA_CON_DERIVADOS;

  FUNCTION FN_VALIDA_CON_DERI_TIT(P_TID_CODIGO IN VARCHAR2,
                                  P_NUM_IDEN   IN VARCHAR2) RETURN VARCHAR2 IS
    CURSOR C1 IS
      SELECT 'S'
        FROM CONTRATOS
       WHERE CNT_CLI_PER_TID_CODIGO = P_TID_CODIGO
         AND CNT_CLI_PER_NUM_IDEN = P_NUM_IDEN
         AND CNT_ESTADO = 'A'
         AND CNT_TIPO_PRODUCTO = 'DER'
         AND NVL(CNT_GARANTIA_EFECTIVO, 'N') = 'N';

    V_VALIDA VARCHAR2(1);
  BEGIN
    V_VALIDA := NULL;

    OPEN C1;
    FETCH C1
      INTO V_VALIDA;
    CLOSE C1;

    V_VALIDA := NVL(V_VALIDA, 'N');

    RETURN(V_VALIDA);
  END FN_VALIDA_CON_DERI_TIT;

  PROCEDURE PR_CREACION_CLIENTE_BASICO(P_TIPO_CLIENTE               VARCHAR2,
                                       P_TIPO_IDENTIFICACION        VARCHAR2,
                                       P_NUMERO_IDENTIFICACION      VARCHAR2,
                                       P_PRIMER_APELLIDO            VARCHAR2,
                                       P_SEGUNDO_APELLIDO           VARCHAR2,
                                       P_NOMBRES                    VARCHAR2,
                                       P_TIPOSEXO                   VARCHAR2,
                                       P_RAZONSOCIAL                VARCHAR2,
                                       P_NACIONALIDAD               VARCHAR2,
                                       P_CONTRATO_COMISION          VARCHAR2,
                                       P_RECURSOS_ENTREGAR          VARCHAR2,
                                       P_OTRO_RECURSO_ENTREGA       VARCHAR2,
                                       P_ING_MEN_OPERACIONALES      NUMBER,
                                       P_EGR_MEN_OPERACIONALES      NUMBER,
                                       P_EGR_MEN_NO_OPERACIONA      NUMBER,
                                       P_ING_MEN_NO_OPERACIONA      NUMBER,
                                       P_ACTIVOS                    NUMBER,
                                       P_PASIVOS                    NUMBER,
                                       P_PATRIMONIO                 NUMBER,
                                       P_CODIGOCIIU                 VARCHAR2,
                                       P_CODIGO_ESTADO_CIVIL        VARCHAR2,
                                       P_CLASIFICACION_ENTIDAD      NUMBER,
                                       P_CLASE_SOCIEDAD             VARCHAR2,
                                       P_FECHANACIMIENTO            VARCHAR2,
                                       P_CIUDAD_NACIMIENTO          NUMBER,
                                       P_PROFESION                  VARCHAR2,
                                       P_DIRECCION_RESIDENCIA       VARCHAR2,
                                       P_TELEFONO_RESIDENCIA        VARCHAR2,
                                       P_CIUDAD_RESIDENCIA          NUMBER,
                                       P_DIRECCION_OFICINA          VARCHAR2,
                                       P_CIUDAD_OFICINA             NUMBER,
                                       P_TELEFONO_OFICINA           VARCHAR2,
                                       P_FECHA_CREACION_EMPRESA     VARCHAR2,
                                       P_TIPO_CORRESPONDENCIA       VARCHAR2,
                                       P_ORIGEN_RECURSOS            VARCHAR2,
                                       P_OTRO_ORIGEN_RECURSOS       VARCHAR2,
                                       P_ACTIVIDAD_CLIENTE          VARCHAR2,
                                       P_CARGO_EMPLEADO             VARCHAR2,
                                       P_PERFIL_RIESGO              VARCHAR2,
                                       P_CATEGORIA_CONTRAPARTE      VARCHAR2,
                                       P_CIUDAD_EXP_DOCUMENTO       NUMBER,
                                       P_FECHA_EXP_DOCUMENTO        VARCHAR2,
                                       P_ID_ORDENANTE               VARCHAR2,
                                       P_IDEN_ORDENANTE             VARCHAR2,
                                       P_PRI_APEL_ORDENANTE         VARCHAR2,
                                       P_SEG_APEL_ORDENANTE         VARCHAR2,
                                       P_NOMBRES_ORDENANTE          VARCHAR2,
                                       P_TIPOSEXO_ORDENANTE         VARCHAR2,
                                       P_CARGO_ORD_JURIDICA         VARCHAR2,
                                       P_TIPO_EMPRESA               VARCHAR2,
                                       P_TIPO_CUENTA                VARCHAR2,
                                       P_CODIGO_BANCO               NUMBER,
                                       P_NUMERO_CUENTA              VARCHAR2,
                                       P_NOMBRE_CUENTA              VARCHAR2,
                                       P_CELULAR                    VARCHAR2,
                                       P_DIRECCIONEMAIL             VARCHAR2,
                                       P_ORIGEN                     VARCHAR2,
                                       P_CIUDAD_EMPRESA             NUMBER DEFAULT NULL,
                                       P_EXTRANJERA                 VARCHAR2 DEFAULT NULL,
                                       P_REFERENCIADO               VARCHAR2 DEFAULT NULL,
                                       P_NOMBRE_EMPRESA             VARCHAR2 DEFAULT NULL,
                                       P_ACT_ECONOMICA_PPAL         VARCHAR2 DEFAULT NULL,
                                       P_EXP_SECTOR_PUBLICO         VARCHAR2 DEFAULT NULL,
                                       P_GRAN_CONTRIBUYENTE         VARCHAR2 DEFAULT NULL,
                                       P_DECLARANTE                 VARCHAR2 DEFAULT NULL,
                                       P_SUJETO_RETEFUENTE          VARCHAR2 DEFAULT NULL,
                                       P_CAMPANA_POLITICA           VARCHAR2 DEFAULT NULL,
                                       P_APARTADO_AEREO             VARCHAR2 DEFAULT NULL,
                                       P_FAX                        VARCHAR2 DEFAULT NULL,
                                       P_NUMERO_FORMULARIO_VIN      NUMBER DEFAULT NULL,
                                       P_TIPO_IDE_COMERCIAL         VARCHAR2 DEFAULT NULL,
                                       P_NUM_IDEN_COMERCIAL         VARCHAR2 DEFAULT NULL,
                                       P_COD_USUARIO_COMERCIAL      VARCHAR2 DEFAULT NULL,
                                       P_RECONO_PUBLICA_PEP         VARCHAR2 DEFAULT NULL,
                                       P_RECONO_POLITICA_PEP        VARCHAR2 DEFAULT NULL,
                                       P_CARGO_PEP                  VARCHAR2 DEFAULT NULL,
                                       P_FECHA_CARGO_PEP            VARCHAR2 DEFAULT NULL,
                                       P_FECHA_DESVINCULA_PEP       VARCHAR2 DEFAULT NULL,
                                       P_REP_LEGAL_PEP              VARCHAR2 DEFAULT NULL,
                                       P_GRADO_CONSANGUI_PEP        VARCHAR2 DEFAULT NULL,
                                       P_NOMBRE_FAMILIAR_PEP        VARCHAR2 DEFAULT NULL,
                                       P_PRIMER_APELLIDO_PEP        VARCHAR2 DEFAULT NULL,
                                       P_SEGUNDO_APELLIDO_PEP       VARCHAR2 DEFAULT NULL,
                                       P_PAI_NACIMIENTO_FN          VARCHAR2 DEFAULT NULL,
                                       P_PAI_RESIDENCIA_FN          VARCHAR2 DEFAULT NULL,
                                       P_MOT_CONSECUTIVO_FN         NUMBER DEFAULT NULL,
                                       P_PASAPORTE_AMERICANO_FN     VARCHAR2 DEFAULT NULL,
                                       P_GREEN_CARD_FN              VARCHAR2 DEFAULT NULL,
                                       P_CIUDADANO_AMERICANO_FN     VARCHAR2 DEFAULT NULL,
                                       P_NACIONA_AMERICANA_FN       VARCHAR2 DEFAULT NULL,
                                       P_PERMANENCIA_182_DIAS_FN    VARCHAR2 DEFAULT NULL,
                                       P_PERMANENCIA_122_DIAS_FN    VARCHAR2 DEFAULT NULL,
                                       P_OTRO_MOTIVO_ESTADIA_FN     VARCHAR2 DEFAULT NULL,
                                       P_TIN_FN                     VARCHAR2 DEFAULT NULL,
                                       P_ES_RES_LEG_NO_COL_FN       VARCHAR2 DEFAULT NULL,
                                       P_IMPACTADO_FATCA_FN         VARCHAR2 DEFAULT NULL,
                                       P_AGE_CODIGO_RESIDE_FN       NUMBER DEFAULT NULL,
                                       P_EXENTO_FATCA_FN            VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_EXENCION_FN         VARCHAR2 DEFAULT NULL,
                                       P_INDICIOS_CRS_FN            VARCHAR2 DEFAULT NULL,
                                       P_IMPACTADO_CRS_FN           VARCHAR2 DEFAULT NULL,
                                       P_TIN_CRS1_FN                VARCHAR2 DEFAULT NULL,
                                       P_TIN_CRS2_FN                VARCHAR2 DEFAULT NULL,
                                       P_TIN_CRS3_FN                VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_NO_TIN1_FN          VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_NO_TIN2_FN          VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_NO_TIN3_FN          VARCHAR2 DEFAULT NULL,
                                       P_PAI_FISCAL1_FN             VARCHAR2 DEFAULT NULL,
                                       P_PAI_FISCAL2_FN             VARCHAR2 DEFAULT NULL,
                                       P_PAI_FISCAL3_FN             VARCHAR2 DEFAULT NULL,
                                       P_PAI_CONSTITUCION_FJ        VARCHAR2 DEFAULT NULL,
                                       P_SUCURSAL_SUBSIDIARIA_FJ    VARCHAR2 DEFAULT NULL,
                                       P_DIRECCION_MATRIZ_FJ        VARCHAR2 DEFAULT NULL,
                                       P_COTIZA_BOLSA_FJ            VARCHAR2 DEFAULT NULL,
                                       P_TRIBUTA_EN_USA_FJ          VARCHAR2 DEFAULT NULL,
                                       P_TIN_FJ                     VARCHAR2 DEFAULT NULL,
                                       P_ES_PUBLICA_FJ              VARCHAR2 DEFAULT NULL,
                                       P_VIGILADA_POR_SFC_FJ        VARCHAR2 DEFAULT NULL,
                                       P_GIIN_FJ                    VARCHAR2 DEFAULT NULL,
                                       P_IMPACTADO_FATCA_FJ         VARCHAR2 DEFAULT NULL,
                                       P_AGE_CODIGO_CASA_MTX_FJ     NUMBER DEFAULT NULL,
                                       P_EXENTO_FATCA_FJ            VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_EXENCION_FJ         VARCHAR2 DEFAULT NULL,
                                       P_TIPO_ENTIDAD_FJ            VARCHAR2 DEFAULT NULL,
                                       P_INDICIOS_CRS_FJ            VARCHAR2 DEFAULT NULL,
                                       P_IMPACTADO_CRS_FJ           VARCHAR2 DEFAULT NULL,
                                       P_TIN_CRS1_FJ                VARCHAR2 DEFAULT NULL,
                                       P_TIN_CRS2_FJ                VARCHAR2 DEFAULT NULL,
                                       P_TIN_CRS3_FJ                VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_NO_TIN1_FJ          VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_NO_TIN2_FJ          VARCHAR2 DEFAULT NULL,
                                       P_MOTIVO_NO_TIN3_FJ          VARCHAR2 DEFAULT NULL,
                                       P_PAI_FISCAL1_FJ             VARCHAR2 DEFAULT NULL,
                                       P_PAI_FISCAL2_FJ             VARCHAR2 DEFAULT NULL,
                                       P_PAI_FISCAL3_FJ             VARCHAR2 DEFAULT NULL,
                                       P_TIPO_ENTIDAD_CRS_FJ        VARCHAR2 DEFAULT NULL,
                                       P_RECONOCIMIENTO_PUBLICO     VARCHAR2 DEFAULT NULL,
                                       P_CAMPO_RECONOCIMIENTO       VARCHAR2 DEFAULT NULL,
                                       P_CONTRATO_DCVAL             NUMBER DEFAULT NULL,
                                       P_DIRECCIONEMAIL_ALTERNO     VARCHAR2 DEFAULT NULL,
                                       P_BANCA_PRIVADA              VARCHAR2 DEFAULT NULL,
                                       P_CATEGORIZACION_CLIENTE     VARCHAR2 DEFAULT NULL,
                                       P_USUARIO_APERTURA           VARCHAR2 DEFAULT NULL,
                                       P_OPERACION                  VARCHAR2 DEFAULT NULL, --JLG VINCULACION DIGITAL
                                       P_ESTADO_VINCULACION_DIGITAL VARCHAR2 DEFAULT NULL,
                                       P_CIIU_SECUNDARIO            VARCHAR2 DEFAULT NULL,
                                       P_RECURSOS_PUBLICOS          VARCHAR2 DEFAULT NULL,
                                       P_FECHA_VEN_ID               VARCHAR2 DEFAULT NULL,
                                       P_ORIGEN_OPERACION           VARCHAR2 DEFAULT NULL,
                                       P_CUENTASFINEXTRA            VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_FIDEICOMITENTE             VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_NOMBREFIDEICOMISO          VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_NITFIDEICOMISO             VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_FIDUADMINFIDEICOMISO       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_PROPOSITOCOMISIONISTA      VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_MONTOAPROXINVERSION        NUMBER DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_ORG_INTERNA_PEP            VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_TID_COD_FAMILIAR_PEP       VARCHAR2 DEFAULT NULL,
                                       P_NUM_ID_FAMILIAR_PEP        VARCHAR2 DEFAULT NULL,
                                       P_GRADO_CONSANGUI_PEP2       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_GRADO_CONSANGUI_PEP3       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_NOMBRE_FAMILIAR_PEP2       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_NOMBRE_FAMILIAR_PEP3       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_NUM_ID_FAMILIAR_PEP2       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_NUM_ID_FAMILIAR_PEP3       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_PRIMER_APELLIDO_PEP2       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_PRIMER_APELLIDO_PEP3       VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_SEGUNDO_APELLIDO_PEP2      VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_SEGUNDO_APELLIDO_PEP3      VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_TID_COD_FAMILIAR_PEP2      VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_TID_COD_FAMILIAR_PEP3      VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_ADMIN_REC_PUBLICOS         VARCHAR2 DEFAULT NULL, --JA VINCULACION D. SARLAFT 4.0
                                       P_FORMULARIO_APERTURA        OUT NUMBER,
                                       P_CLOB                       OUT CLOB) IS

    CURSOR C1 IS
      SELECT PER_NUM_IDEN
        FROM PERSONAS
       WHERE PER_NUM_IDEN = P_IDEN_ORDENANTE
         AND PER_TID_CODIGO = P_ID_ORDENANTE;

    CURSOR PER_CLI IS
      SELECT PER_NUM_IDEN
        FROM PERSONAS
       WHERE PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION)
         AND PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION);

    CURSOR PERV_VINCULA(P_NUMERO_FORMULARIO  NUMBER,
                        P_CLI_PER_NUM_IDEN   VARCHAR2,
                        P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT PERV_CONSECUTIVO,
             PERV_NUMERO_FORMULARIO,
             PERV_CLI_PER_NUM_IDEN,
             PERV_CLI_PER_TID_CODIGO,
             PERV_FECHA_APERTURA,
             PERV_ESTADO,
             PERV_PER_NUM_IDEN,
             PERV_PER_TID_CODIGO,
             PERV_PRIMER_APELLIDO,
             PERV_SEGUNDO_APELLIDO,
             PERV_NOMBRE,
             PERV_TIPO_SEXO,
             PERV_ROL_ORDENANTE,
             PERV_FECHA_INGRESO,
             PERV_CARGO,
             PERV_CELULAR,
             PERV_TELEFONO,
             PERV_DIRECCION_OFICINA,
             PERV_CIUDAD_OFICINA,
             PERV_FECHA_EXP_DOCUMENTO,
             PERV_CIUDAD_EXP_DOCUMENTO,
             PERV_CALIDAD,
             PERV_PARENTESCO,
             PERV_DIRECCION_EMAIL,
             PERV_FECHA_VENC_ID
        FROM PERSONAS_RELACIONADAS_VINCULA
       WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND TRIM(PERV_PER_NUM_IDEN) || ' ' || PERV_PER_TID_CODIGO !=
             TRIM(P_CLI_PER_NUM_IDEN) || ' ' || TRIM(P_CLI_PER_TID_CODIGO)
         AND PERV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND PERV_ESTADO = 'POR_PROCESAR'
         AND NOT EXISTS
       (SELECT 'X'
                FROM PERSONAS
               WHERE PER_NUM_IDEN = PERV_PER_NUM_IDEN
                 AND PER_TID_CODIGO = PERV_PER_TID_CODIGO);

    CURSOR PERV_VINCULA_2(P_NUMERO_FORMULARIO  NUMBER,
                          P_CLI_PER_NUM_IDEN   VARCHAR2,
                          P_CLI_PER_TID_CODIGO VARCHAR2) IS /*YA EXISTE REGISTRO EN PERSONAS*/
      SELECT PERV_CONSECUTIVO,
             PERV_NUMERO_FORMULARIO,
             PERV_CLI_PER_NUM_IDEN,
             PERV_CLI_PER_TID_CODIGO,
             PERV_FECHA_APERTURA,
             PERV_ESTADO,
             PERV_PER_NUM_IDEN,
             PERV_PER_TID_CODIGO,
             PERV_PRIMER_APELLIDO,
             PERV_SEGUNDO_APELLIDO,
             PERV_NOMBRE,
             PERV_TIPO_SEXO,
             PERV_ROL_ORDENANTE,
             PERV_FECHA_INGRESO,
             PERV_CARGO,
             PERV_CELULAR,
             PERV_TELEFONO,
             PERV_DIRECCION_OFICINA,
             PERV_CIUDAD_OFICINA,
             PERV_FECHA_EXP_DOCUMENTO,
             PERV_CIUDAD_EXP_DOCUMENTO,
             PERV_CALIDAD,
             PERV_PARENTESCO,
             PERV_DIRECCION_EMAIL,
             PERV_FECHA_VENC_ID
        FROM PERSONAS_RELACIONADAS_VINCULA
       WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND TRIM(PERV_PER_NUM_IDEN) || ' ' || PERV_PER_TID_CODIGO !=
             TRIM(P_CLI_PER_NUM_IDEN) || ' ' || TRIM(P_CLI_PER_TID_CODIGO)
         AND PERV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND PERV_ESTADO = 'POR_PROCESAR'
      /*AND EXISTS(SELECT 'X' FROM PERSONAS --YA EXISTE EL CLIENTE EN PERSONAS
      WHERE PER_NUM_IDEN = PERV_PER_NUM_IDEN
        AND PER_TID_CODIGO = PERV_PER_TID_CODIGO)*/
      ;

    CURSOR PERV_VINCULA_RELA(P_NUMERO_FORMULARIO  NUMBER,
                             P_CLI_PER_NUM_IDEN   VARCHAR2,
                             P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT PERV_CONSECUTIVO,
             PERV_NUMERO_FORMULARIO,
             PERV_CLI_PER_NUM_IDEN,
             PERV_CLI_PER_TID_CODIGO,
             PERV_FECHA_APERTURA,
             PERV_ESTADO,
             PERV_PER_NUM_IDEN,
             PERV_PER_TID_CODIGO,
             PERV_PRIMER_APELLIDO,
             PERV_SEGUNDO_APELLIDO,
             PERV_NOMBRE,
             PERV_TIPO_SEXO,
             PERV_ROL_ORDENANTE,
             PERV_FECHA_INGRESO,
             PERV_CARGO,
             PERV_CELULAR,
             PERV_TELEFONO,
             PERV_DIRECCION_OFICINA,
             PERV_CIUDAD_OFICINA,
             PERV_FECHA_EXP_DOCUMENTO,
             PERV_CIUDAD_EXP_DOCUMENTO,
             PERV_CALIDAD,
             PERV_PARENTESCO,
             PERV_DIRECCION_EMAIL,
             PERV_FECHA_VENC_ID
        FROM PERSONAS_RELACIONADAS_VINCULA
       WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND TRIM(PERV_PER_NUM_IDEN) || ' ' || PERV_PER_TID_CODIGO !=
             TRIM(P_CLI_PER_NUM_IDEN) || ' ' || TRIM(P_CLI_PER_TID_CODIGO)
         AND PERV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND PERV_ESTADO = 'POR_PROCESAR'
         AND EXISTS
       (SELECT 'X'
                FROM PERSONAS
               WHERE PER_NUM_IDEN = PERV_PER_NUM_IDEN
                 AND PER_TID_CODIGO = PERV_PER_TID_CODIGO);

    CURSOR SETV_VINCULA(P_NUMERO_FORMULARIO  NUMBER,
                        P_CLI_PER_NUM_IDEN   VARCHAR2,
                        P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT SETV_CONSECUTIVO,
             SETV_NUMERO_FORMULARIO,
             SETV_CLI_PER_NUM_IDEN,
             SETV_CLI_PER_TID_CODIGO,
             SETV_FECHA_APERTURA,
             SETV_ESTADO,
             SETV_PER_NUM_IDEN,
             SETV_PER_TID_CODIGO,
             SETV_PRIMER_APELLIDO,
             SETV_SEGUNDO_APELLIDO,
             SETV_NOMBRE,
             SETV_CIUDAD_EXP_DOCUMENTO,
             SETV_FECHA_EXP_DOCUMENTO,
             SETV_TIPO_SEXO,
             SETV_NACIONALIDAD,
             SETV_ESTADO_CIVIL,
             SETV_CIUDAD_NACIMIENTO,
             SETV_FECHA_NACIMIENTO,
             SETV_DIRECCION_EMAIL,
             SETV_PROFESION,
             SETV_EMPRESA,
             SETV_CARGO,
             SETV_ACTIVIDAD,
             SETV_ORIGEN_RECURSOS,
             SETV_RECURSOS_ENTREGAR,
             SETV_CODIGO_CIIU,
             SETV_EXPERIENCIA_SECTOR_PU,
             SETV_FECHA_INGRESO,
             SETV_OTRO_ORIGEN_RECURSOS,
             SETV_OTRO_RECURSOS_ENTREGAR,
             SETV_DIRECCION_RESIDENCIA,
             SETV_CIUDAD_RESIDENCIA,
             SETV_TELEFONO_RESIDENCIA,
             SETV_DIRECCION_OFICINA,
             SETV_CIUDAD_OFICINA,
             SETV_TELEFONO_OFICINA,
             SETV_APARTADO_AEREO,
             SETV_FAX,
             SETV_CELULAR,
             SETV_ING_MEN_OPERACIONALES,
             SETV_EGRESOS_MEN_OPERACIONALES,
             SETV_INGRESOS_MEN_NO_OPERA,
             SETV_EGRESOS_MEN_NO_OPERA,
             SETV_ACTIVOS,
             SETV_PASIVOS,
             SETV_PATRIMONIO
        FROM SEGUNDOS_TITULARES_VINCULA
       WHERE SETV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND SETV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND SETV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND SETV_ESTADO = 'POR_PROCESAR';

    CURSOR CBVI_VINCULA(P_NUMERO_FORMULARIO  NUMBER,
                        P_CLI_PER_NUM_IDEN   VARCHAR2,
                        P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT CBVI_CONSECUTIVO,
             CBVI_NUMERO_FORMULARIO,
             CBVI_CLI_PER_NUM_IDEN,
             CBVI_CLI_PER_TID_CODIGO,
             CBVI_FECHA_APERTURA,
             CBVI_ESTADO,
             CBVI_FECHA_INGRESO,
             CBVI_BANCO,
             CBVI_NUMERO_CUENTA,
             CBVI_TIPO,
             CBVI_SUCURSAL,
             CBVI_DIRECCION,
             CBVI_TELEFONO
        FROM CUENTAS_BANCARIAS_VINCULACION
       WHERE CBVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND CBVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND CBVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND CBVI_ESTADO = 'POR_PROCESAR';

    CURSOR CBEV_VINCULA(P_NUMERO_FORMULARIO  NUMBER,
                        P_CLI_PER_NUM_IDEN   VARCHAR2,
                        P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT CBEV_CONSECUTIVO,
             CBEV_NUMERO_FORMULARIO,
             CBEV_CLI_PER_NUM_IDEN,
             CBEV_CLI_PER_TID_CODIGO,
             CBEV_FECHA_APERTURA,
             CBEV_ESTADO,
             CBEV_BANCO,
             CBEV_NUMERO_CUENTA,
             CBEV_CIUDAD,
             CBEV_MONEDA,
             CBEV_COMPENSACION,
             CBEV_TIPO_OPERACION,
             CBEV_FECHA_INGRESO
        FROM CUENTAS_BANCARIAS_EXT_VINCULA
       WHERE CBEV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND CBEV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND CBEV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND CBEV_ESTADO = 'POR_PROCESAR';

    CURSOR IFRV_VINCULA(P_NUMERO_FORMULARIO  NUMBER,
                        P_CLI_PER_NUM_IDEN   VARCHAR2,
                        P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT IFRV_CONSECUTIVO,
             IFRV_NUMERO_FORMULARIO,
             IFRV_CLI_PER_NUM_IDEN,
             IFRV_CLI_PER_TID_CODIGO,
             IFRV_FECHA_APERTURA,
             IFRV_ESTADO,
             IFRV_PER_NUM_IDEN,
             IFRV_PER_TID_CODIGO,
             IFRV_ROL_ORDENANTE,
             IFRV_FECHA_INGRESO,
             IFRV_PARENTESCO
        FROM INFORMACIONES_REVELA_VINCULA
       WHERE IFRV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND IFRV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND IFRV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND IFRV_ESTADO = 'POR_PROCESAR';

    CURSOR CLIENTES_SEGUNDO(P_PER_NUM_IDEN   VARCHAR2,
                            P_PER_TID_CODIGO VARCHAR2) IS
      SELECT COUNT(*)
        FROM PERSONAS_RELACIONADAS
       WHERE RLC_PER_NUM_IDEN = P_PER_NUM_IDEN
         AND RLC_PER_TID_CODIGO = P_PER_TID_CODIGO
         AND RLC_ESTADO = 'A'
         AND RLC_CLI_PER_NUM_IDEN != RLC_PER_NUM_IDEN
         AND RLC_ROL_CODIGO IN (1, 6)
         AND (NOT EXISTS
              (SELECT 'X'
                 FROM CLIENTES
                WHERE CLI_PER_NUM_IDEN = RLC_PER_NUM_IDEN
                  AND CLI_PER_TID_CODIGO = RLC_PER_TID_CODIGO) OR EXISTS
              (SELECT 'X'
                 FROM CLIENTES
                WHERE CLI_PER_NUM_IDEN = RLC_PER_NUM_IDEN
                  AND CLI_PER_TID_CODIGO = RLC_PER_TID_CODIGO
                  AND CLI_TIPO_CLIENTE != 'S'))
         AND NOT EXISTS (SELECT 'X'
                FROM PARENTESCOS
               WHERE PAO_CONSECUTIVO = RLC_PAO_CONSECUTIVO
                 AND PAO_VALIDA_PARTE_REL = 'S');

    CURSOR COMERCIAL_VALIDA(P_PER_NUM_IDEN   VARCHAR2,
                            P_PER_TID_CODIGO VARCHAR2) IS
      SELECT 'S'
        FROM PERSONAS
       WHERE PER_NUM_IDEN = P_PER_NUM_IDEN
         AND PER_TID_CODIGO = P_PER_TID_CODIGO
         AND PER_NOMBRE_USUARIO IS NOT NULL
         AND PER_ESTADO = 'A';

    CURSOR VALIDA_CLIENTE(P_PER_NUM_IDEN   VARCHAR2,
                          P_PER_TID_CODIGO VARCHAR2) IS
      SELECT CLI_ECL_MNEMONICO, CLI_TIPO_CLIENTE
        FROM ESTADOS_CLIENTE, CLIENTES
       WHERE ECL_MNEMONICO = CLI_ECL_MNEMONICO
         AND ECL_COLOCAR_ORDEN = 'S'
         AND CLI_PER_NUM_IDEN = P_PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = P_PER_TID_CODIGO
         AND CLI_TIPO_CLIENTE IN ('C', 'S', 'A');

    CURSOR PER_VINCULA_OCL(P_NUMERO_FORMULARIO  NUMBER,
                           P_CLI_PER_NUM_IDEN   VARCHAR2,
                           P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT PERV_CONSECUTIVO,
             PERV_NUMERO_FORMULARIO,
             PERV_CLI_PER_NUM_IDEN,
             PERV_CLI_PER_TID_CODIGO,
             PERV_FECHA_APERTURA,
             PERV_ESTADO,
             PERV_PER_NUM_IDEN,
             PERV_PER_TID_CODIGO,
             PERV_PRIMER_APELLIDO,
             PERV_SEGUNDO_APELLIDO,
             PERV_NOMBRE,
             PERV_TIPO_SEXO,
             PERV_ROL_ORDENANTE,
             PERV_FECHA_INGRESO,
             PERV_CARGO,
             PERV_CELULAR,
             PERV_TELEFONO,
             PERV_DIRECCION_OFICINA,
             PERV_CIUDAD_OFICINA,
             PERV_FECHA_EXP_DOCUMENTO,
             PERV_CIUDAD_EXP_DOCUMENTO,
             PERV_CALIDAD,
             PERV_PARENTESCO,
             PERV_DIRECCION_EMAIL
        FROM PERSONAS_RELACIONADAS_VINCULA
       WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND PERV_PER_NUM_IDEN != P_NUMERO_IDENTIFICACION
         AND PERV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND PERV_ESTADO = 'POR_PROCESAR';

    CURSOR ACVI_VINCULA(P_NUMERO_FORMULARIO  NUMBER,
                        P_CLI_PER_NUM_IDEN   VARCHAR2,
                        P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT ACVI_CONSECUTIVO,
             ACVI_NUMERO_FORMULARIO,
             ACVI_CLI_PER_NUM_IDEN,
             ACVI_CLI_PER_TID_CODIGO,
             ACVI_FECHA_APERTURA,
             ACVI_ESTADO,
             ACVI_FECHA_INGRESO,
             ACVI_DILIGENCIA_ANEXO_FATCA,
             ACVI_PORCENTAJE_PARTIPACION,
             ACVI_FILIAL_OTRA_COMPANIA,
             ACVI_JUNTA_DIRECT_SUPLE,
             ACVI_PRESIDENTE_GERENTE,
             ACVI_VARIOS_REP_LEGALES,
             ACVI_NOMBRE_RAZON_SOCIAL,
             ACVI_ROL,
             ACVI_PEP,
             ACVI_TIP_IDE_CODIGO,
             ACVI_NUM_IDEN,
             ACVI_POR_PARTICIPACION,
             ACVI_PAI_NACIMIENTO,
             ACVI_FEC_NACIMIENTO,
             ACVI_TRIBUTA_EN_USA,
             ACVI_TIN,
             ACVI_DIRECCION_OTRO_PAIS,
             ACVI_CIUDAD_RESIDENCIA,
             ACVI_IMPACTADO_FATCA,
             ACVI_EXENTO_FATCA,
             ACVI_MOTIVO_EXENCION,
             ACVI_INDICIOS_CRS,
             ACVI_IMPACTADO_CRS,
             ACVI_PAI_FISCAL1,
             ACVI_PAI_FISCAL2,
             ACVI_PAI_FISCAL3,
             ACVI_TIN_CRS1,
             ACVI_TIN_CRS2,
             ACVI_TIN_CRS3,
             ACVI_MOTIVO_NO_TIN1,
             ACVI_MOTIVO_NO_TIN2,
             ACVI_MOTIVO_NO_TIN3,
             ACVI_RECONOCIDO_PUBLICA,
             ACVI_REP_LEGAL_INTERNA,
             ACVI_POLITICA_EXPUESTA,
             ACVI_GRADO_PARANTESCO,
             ACVI_CARGO,
             ACVI_FECHA_CARGO,
             ACVI_FECHA_DESVINCULA,
             ACVI_NOMBRE_FAMILIAR,
             ACVI_PRIMER_APELLIDO,
             ACVI_SEGUNDO_APELLIDO,
             ACVI_FECHA_PROCESAMIENTO,
             (SELECT COUNT(*)
                FROM ACCIONISTAS_VINCULA B
               WHERE A.ACVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
                 AND A.ACVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
                 AND A.ACVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                 AND A.ACVI_ESTADO = 'POR_PROCESAR') TOTAL_ACCIONISTAS
        FROM ACCIONISTAS_VINCULA A
       WHERE A.ACVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
         AND A.ACVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND A.ACVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND A.ACVI_ESTADO = 'POR_PROCESAR';

    CURSOR CLIENTE_VALIDA(P_CLI_PER_NUM_IDEN   VARCHAR2,
                          P_CLI_PER_TID_CODIGO VARCHAR2) IS
      SELECT COUNT(*)
        FROM CLIENTES
       WHERE CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO;

    V_ERRORES              NUMBER;
    V_SECUENCIA_CCC        NUMBER;
    V_CLIENTES_SEGUNDO     NUMBER(5);
    V_PJF_SEQ              NUMBER;
    V_AAC_SEQ              NUMBER;
    V_ACC_SEQ              NUMBER;
    V_NUM_REGISTRO         NUMBER;
    V_VALIDA_CLIENTE       NUMBER(5);
    V_COMERCIAL_VALIDA     VARCHAR2(1);
    V_VALIDA_CTA_EXTERIOR  NUMBER(5);
    V_VALOR                CONSTANTES.CON_VALOR%TYPE;
    V_VALOR_DATE           CONSTANTES.CON_VALOR_DATE%TYPE;
    V_VALOR_CHAR           CONSTANTES.CON_VALOR_CHAR%TYPE;
    V_CONTRATO_COMISION    CLIENTES.CLI_CONTRATO_MARCO_COMISION%TYPE;
    V_BCC_CLIENTE          CLIENTES.CLI_BSC_BCC_MNEMONICO%TYPE;
    V_BSC_CLIENTE          CLIENTES.CLI_BSC_MNEMONICO%TYPE;
    V_BCC_ALT              CLIENTES.CLI_BSC_BCC_MNEMONICO_ALT%TYPE;
    V_BSC_ALT              CLIENTES.CLI_BSC_MNEMONICO_ALT%TYPE;
    V_FORMULARIO_SEGUNDO   CLIENTES.CLI_FORMULARIO_APERTURA%TYPE;
    C_C1                   C1%ROWTYPE;
    C_PERV_VINCULA         PERV_VINCULA%ROWTYPE;
    C_PERV_VINCULA_2       PERV_VINCULA_2%ROWTYPE;
    C_PERV_VINCULA_RELA    PERV_VINCULA_RELA%ROWTYPE;
    C_SETV_VINCULA         SETV_VINCULA%ROWTYPE;
    C_CBVI_VINCULA         CBVI_VINCULA%ROWTYPE;
    C_CBEV_VINCULA         CBEV_VINCULA%ROWTYPE;
    C_IFRV_VINCULA         IFRV_VINCULA%ROWTYPE;
    C_VALIDA_CLIENTE       VALIDA_CLIENTE%ROWTYPE;
    C_ACVI_VINCULA         ACVI_VINCULA%ROWTYPE;
    C_PER_CLI              PER_CLI%ROWTYPE;
    V_CLI_TEN_CODIGO       CLIENTES.CLI_TEN_CODIGO%TYPE;
    V_CLI_CARACTER_ENTIDAD CLIENTES.CLI_CARACTER_ENTIDAD%TYPE;
    V_CLIENTE_FATCA        CLIENTES.CLI_INDICIO_FATCA%TYPE;
    V_TIENE_CONSANGUI_PEP  CLIENTES.CLI_TIENE_CONSANGUI_PEP%TYPE;
    V_CIUDAD_RESIDENCIA    CLIENTES.CLI_AGE_CODIGO_RESIDE%TYPE;
    V_AGE_CODIGO_PPAL      CLIENTES.CLI_AGE_CODIGO_PPAL%TYPE;
    V_CONTRATO_DCVAL       CLIENTES.CLI_NUMERO_CONTRATO_DCVAL%TYPE;

    V_MENSAJE_ERROR CLOB;
    V_ERROR_CREACION EXCEPTION;
    vtest varchar2(1000);
    /****************************
    P_ORIGEN : PLV - Creacion del cliente en sucursales del banco Davivienda Proceso OPAS
               VIN - Creacion del clienhte desde sistema de pre vinculacion drupal
               VID - Creacion del cliente desde sistema vinculacion digital
    ****************/
    P_PP          VARCHAR2(50);
    V_ENVIO_SMS   VARCHAR2(1);
    V_ENVIO_EMAIL VARCHAR2(1);
  BEGIN
    V_ERRORES        := 0;
    V_SECUENCIA_CCC  := 0;
    P_CLOB           := NULL;
    V_VALIDA_CLIENTE := 0;

    IF LENGTH(NVL(P_NOMBRE_EMPRESA, ' ')) > 40 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Nombre de empresa superior a 40 caracteres');
    END IF;

    IF LENGTH(NVL(P_PRIMER_APELLIDO, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Primer Apellido superior a 20 caracteres');
    END IF;
    IF LENGTH(NVL(P_SEGUNDO_APELLIDO, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Segundo Apellido superior a 20 caracteres');
    END IF;

    IF LENGTH(NVL(P_NOMBRES, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Nombres superior a 20 caracteres');
    END IF;

    IF LENGTH(NVL(P_RAZONSOCIAL, ' ')) > 40 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Razon Social superior a 40 caracteres');
    END IF;

    IF LENGTH(NVL(P_DIRECCIONEMAIL, ' ')) > 80 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Direccion Correo superior a 80 caracteres');
    END IF;

    IF LENGTH(NVL(P_DIRECCIONEMAIL_ALTERNO, ' ')) > 80 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CREARERROR('Direccion Correo alterno superior a 80 caracteres');
    END IF;

    IF LENGTH(NVL(P_CARGO_EMPLEADO, ' ')) > 40 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Cargo empleado superior a 40 caracteres');
    END IF;

    IF LENGTH(NVL(P_DIRECCION_RESIDENCIA, ' ')) > 80 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Direccion Residencia superior a 80 caracteres');
    END IF;

    IF LENGTH(NVL(P_TELEFONO_RESIDENCIA, ' ')) > 15 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Telefono Residencia superior a 15 caracteres');
    END IF;

    IF LENGTH(NVL(P_DIRECCION_OFICINA, ' ')) > 80 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Direccion Residencia superior a 80 caracteres');
    END IF;

    IF P_CARGO_PEP IS NOT NULL THEN
      IF LENGTH(NVL(P_CARGO_PEP, ' ')) > 50 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Cargo informado en PEP mayor a 50 caracteres');
      END IF;
    END IF;

    IF P_NOMBRE_FAMILIAR_PEP IS NOT NULL THEN
      IF LENGTH(NVL(P_NOMBRE_FAMILIAR_PEP, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Nombre informado en PEP mayor a 20 caracteres');
      END IF;
    END IF;

    IF P_PRIMER_APELLIDO_PEP IS NOT NULL THEN
      IF LENGTH(NVL(P_PRIMER_APELLIDO_PEP, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Primer Apellido informado en PEP mayor a 20 caracteres');
      END IF;
    END IF;

    IF P_SEGUNDO_APELLIDO_PEP IS NOT NULL THEN
      IF LENGTH(NVL(P_SEGUNDO_APELLIDO_PEP, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Segundo Apellido informado en PEP mayor a 20 caracteres');
      END IF;
    END IF;

    IF P_FECHA_CARGO_PEP IS NOT NULL OR P_FECHA_DESVINCULA_PEP IS NOT NULL THEN
      IF P_FECHA_CARGO_PEP > P_FECHA_DESVINCULA_PEP THEN
        --V_ERRORES   := V_ERRORES   +1;
        --P_CAB.CrearError('Fecha Vinculacion en PEP: '||LENGTH(P_FECHA_CARGO_PEP)||' no puede ser mayor a la de Desvinculacion:'||LENGTH(P_FECHA_DESVINCULA_PEP));
        NULL;
      END IF;

      IF P_FECHA_CARGO_PEP IS NOT NULL THEN
        IF P_FECHA_DESVINCULA_PEP < P_FECHA_CARGO_PEP THEN
          --   V_ERRORES   := V_ERRORES   +1;
          --   P_CAB.CrearError('Fecha  DesVinculacion no puede ser menor a la de Vinculacion');
          null;
        END IF;
      END IF;

      IF P_FECHA_CARGO_PEP IS NULL AND P_FECHA_DESVINCULA_PEP IS NOT NULL THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Debe digitar Fecha Vinculacion');
      END IF;
    END IF;

    IF NVL(P_EXENTO_FATCA_FN, ' ') = 'S' AND P_MOTIVO_EXENCION_FN IS NULL THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Debe indicar un motivo para exento de Fatca');
    END IF;

    IF NVL(P_EXENTO_FATCA_FN, ' ') = 'N' AND
       P_MOTIVO_EXENCION_FN IS NOT NULL THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Debe ser cliente exento Fatca para ingresar un motivo.');
    END IF;

    IF P_OTRO_MOTIVO_ESTADIA_FN IS NOT NULL THEN
      IF LENGTH(NVL(P_OTRO_MOTIVO_ESTADIA_FN, ' ')) > 30 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Otro motivo de estadia mayor a 30 caracteres');
      END IF;
    END IF;

    IF P_MOT_CONSECUTIVO_FN IS NOT NULL THEN
      IF P_MOT_CONSECUTIVO_FN = 4 AND (P_OTRO_MOTIVO_ESTADIA_FN IS NULL OR
         LENGTH(P_OTRO_MOTIVO_ESTADIA_FN) = 0) THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Debe digitar el motivo de estadia en EEUU.');
      END IF;

      IF ((NVL(P_PERMANENCIA_182_DIAS_FN, ' ') = 'S' OR
         NVL(P_PERMANENCIA_122_DIAS_FN, ' ') = 'S') AND
         P_MOT_CONSECUTIVO_FN IS NULL) THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Debe seleccionar el motivo de estadia en EEUU.');
      END IF;
    END IF;

    IF P_EXENTO_FATCA_FJ IS NOT NULL THEN
      IF NVL(P_EXENTO_FATCA_FJ, ' ') = 'S' AND P_MOTIVO_EXENCION_FJ IS NULL THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Debe ingresar un motivo para exento de Fatca');
      END IF;

      IF NVL(P_EXENTO_FATCA_FJ, ' ') = 'N' AND
         P_MOTIVO_EXENCION_FJ IS NOT NULL THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Debe ser cliente exento Fatca para ingresar un motivo.');
      END IF;
    END IF;

    IF P_PAI_CONSTITUCION_FJ IS NOT NULL THEN
      IF ((P_PAI_CONSTITUCION_FJ = 'USA') AND
         (P_TIN_FJ IS NULL OR LENGTH(P_TIN_FJ) = 0)) THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Debe digitar el numero TIN de la empresa');
      END IF;
    END IF;

    IF P_SUCURSAL_SUBSIDIARIA_FJ IS NOT NULL THEN
      IF (P_SUCURSAL_SUBSIDIARIA_FJ = 'S') THEN
        IF (P_AGE_CODIGO_CASA_MTX_FJ IS NULL OR
           P_DIRECCION_MATRIZ_FJ IS NULL) THEN
          V_ERRORES := V_ERRORES + 1;
          P_CAB.CrearError('Los datos de la casa matriz de la empresa estan incompletos.');
        END IF;
      END IF;
    END IF;

    IF (NVL(P_VIGILADA_POR_SFC_FJ, ' ') = 'S' AND
       (P_GIIN_FJ IS NULL OR LENGTH(P_GIIN_FJ) = 0)) THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Debe registrar obligatoriamente el numero GIIN de la empresa.');
    END IF;

    IF (NVL(P_TRIBUTA_EN_USA_FJ, ' ') = 'S' AND
       (P_TIN_FJ IS NULL OR LENGTH(P_TIN_FJ) = 0)) THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Debe registrar obligatoriamente el numero TIN de la empresa.');
    END IF;

    /* VALIDAR SI EXISTE CLENTE NO PERMITE VINCULACION*/
    OPEN CLIENTE_VALIDA(P_CLI_PER_NUM_IDEN   => TRIM(P_NUMERO_IDENTIFICACION),
                        P_CLI_PER_TID_CODIGO => TRIM(P_TIPO_IDENTIFICACION));
    FETCH CLIENTE_VALIDA
      INTO V_VALIDA_CLIENTE;
    CLOSE CLIENTE_VALIDA;

    V_VALIDA_CLIENTE := NVL(V_VALIDA_CLIENTE, 0);
    IF V_VALIDA_CLIENTE >= 1 AND
       (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN ('PRV', 'INU', 'NUE') AND
       P_ORIGEN_OPERACION IS NULL) /*No es modificacion ni Unica Operaicon*/
     THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Cliente ya vinculado P_ORIGEN_OPERACION:' ||
                       P_ORIGEN_OPERACION);
    END IF;

    --RAISE_APPLICATION_ERROR(-20501,'ERROOR CREACION CLIENTE');

    IF P_ORIGEN = 'VIN' THEN
      IF P_NUMERO_FORMULARIO_VIN IS NULL THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Numero de formulario enviado no valido');
      END IF;

      IF P_TIPO_IDE_COMERCIAL IS NULL OR P_NUM_IDEN_COMERCIAL IS NULL OR
         P_COD_USUARIO_COMERCIAL IS NULL THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Tipo,Identificacion o nombre de comercial invalidos');
      END IF;
    END IF;

    IF V_ERRORES = 0 THEN

      /* Crecion persona basico */
      C_PER_CLI := NULL;
      OPEN PER_CLI;
      FETCH PER_CLI
        INTO C_PER_CLI;
      CLOSE PER_CLI;

      IF C_PER_CLI.PER_NUM_IDEN IS NULL THEN
        BEGIN
          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_RAZON_SOCIAL,
             PER_DIGITO_CONTROL,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE,
             PER_SEXO,
             PER_ES_CORREDOR,
             PER_NOMBRE_USUARIO,
             PER_INICIALES_USUARIO,
             PER_SUC_CODIGO,
             PER_CPR_MNEMONICO,
             PER_MAIL_CORREDOR,
             PER_TIPO_COMERCIAL,
             PER_EJECUTA_ORDEN_MESA,
             PER_PER_NUM_IDEN,
             PER_PER_TID_CODIGO,
             PER_CCT_MNEMONICO,
             PER_ESTADO,
             PER_CLF_SECUENCIAL,
             PER_TELEFONO_DIRECTO,
             PER_CODIGO_BOLSA,
             PER_COMERCIAL_ACC_DIRECTO,
             PER_CODIGO_SAE_ACC,
             PER_COMPLEMENTACION,
             PER_COMERCIAL_OPX,
             PER_USUARIO_DECEVAL,
             PER_ID_USUARIO_DECEVAL,
             PER_CODIGO_SIOPEL,
             PER_CODIGO_XSTREAM,
             PER_NOTIFICA_CENLINEA,
             PER_TIP_COMERCIAL_UDF,
             PER_ORIGEN
             --     ,PER_REPRESENTANTE_LEGAL
             --     ,PER_CODIGO_SAE_DER
             --     ,PER_CODIGO_MASTER_RF
             --     ,PER_CODIGO_MASTER_RV
             --     ,PER_COMPLEMENTA_CTA
            ,
             PER_ATIENDE_CLIENTES)
          VALUES
            (TRIM(P_NUMERO_IDENTIFICACION) --PER_NUM_IDEN
            ,
             TRIM(P_TIPO_IDENTIFICACION) --PER_TID_CODIGO
            ,
             P_TIPO_CLIENTE --PER_TIPO
            ,
             UPPER(TRIM(P_RAZONSOCIAL)) --PER_RAZON_SOCIAL
            ,
             DECODE(P_TIPO_CLIENTE,
                    'PJU',
                    P_CLIENTES.RT_DIGITO_CONTROL(TO_NUMBER(TRIM(P_NUMERO_IDENTIFICACION))),
                    NULL) --PER_DIGITO_CONTROL
            ,
             UPPER(TRIM(P_PRIMER_APELLIDO)) --PER_PRIMER_APELLIDO
            ,
             UPPER(TRIM(P_SEGUNDO_APELLIDO)) --PER_SEGUNDO_APELLIDO
            ,
             UPPER(TRIM(P_NOMBRES)) --PER_NOMBRE
            ,
             P_TIPOSEXO --PER_SEXO
            ,
             NULL --PER_ES_CORREDOR
            ,
             NULL --PER_NOMBRE_USUARIO
            ,
             NULL --PER_INICIALES_USUARIO
            ,
             NULL --PER_SUC_CODIGO
            ,
             NULL --PER_CPR_MNEMONICO
            ,
             NULL --PER_MAIL_CORREDOR
            ,
             NULL --PER_TIPO_COMERCIAL
            ,
             NULL --PER_EJECUTA_ORDEN_MESA
            ,
             NULL --PER_PER_NUM_IDEN
            ,
             NULL --PER_PER_TID_CODIGO
            ,
             DECODE(P_TIPO_CLIENTE, 'PJU', 'OTROS', NULL) --PER_CCT_MNEMONICO
            ,
             NULL --PER_ESTADO
            ,
             NULL --PER_CLF_SECUENCIAL
            ,
             NULL --PER_TELEFONO_DIRECTO
            ,
             NULL --PER_CODIGO_BOLSA
            ,
             NULL --PER_COMERCIAL_ACC_DIRECTO
            ,
             NULL --PER_CODIGO_SAE_ACC
            ,
             NULL --PER_COMPLEMENTACION
            ,
             NULL --PER_COMERCIAL_OPX
            ,
             NULL --PER_USUARIO_DECEVAL
            ,
             NULL --PER_ID_USUARIO_DECEVAL
            ,
             NULL --PER_CODIGO_SIOPEL
            ,
             NULL --PER_CODIGO_XSTREAM
            ,
             NULL --PER_NOTIFICA_CENLINEA
            ,
             NULL --PER_TIP_COMERCIAL_UDF
            ,
             DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                    'N',
                    P_ORIGEN,
                    'VID') --PER_ORIGEN
             --    ,NULL                          --PER_REPRESENTANTE_LEGAL
             --    ,NULL                          --PER_CODIGO_SAE_DER
             --    ,NULL                          --PER_CODIGO_MASTER_RF
             --    ,NULL                          --PER_CODIGO_MASTER_RV
             --    ,'N'                           --PER_COMPLEMENTA_CTA
            ,
             NULL --PER_ATIENDE_CLIENTES
             );

          IF SQL%ROWCOUNT = 0 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
          END IF;

        EXCEPTION
          WHEN OTHERS THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('Error creando persona 1.' || SQLERRM);
            RAISE V_ERROR_CREACION;

        END;
      END IF;
      /*JLG VINCULACION , YA EXISTE EL CLIENTE, SE REALIZARÁ ACTUALIZACION ESTADO('PRV','INU','NUE')*/
      IF C_PER_CLI.PER_NUM_IDEN IS NOT NULL AND
         (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN ('PRV', 'INU', 'NUE') OR
         NVL(P_ORIGEN_OPERACION, 'N') != 'N') THEN
        BEGIN
          UPDATE PERSONAS
             SET PER_TIPO                  = NVL(P_TIPO_CLIENTE, NULL) --PER_TIPO
                ,
                 PER_RAZON_SOCIAL          = NVL(UPPER(TRIM(P_RAZONSOCIAL)),
                                                 NULL) --PER_RAZON_SOCIAL
                ,
                 PER_DIGITO_CONTROL        = NVL(DECODE(P_TIPO_CLIENTE,
                                                        'PJU',
                                                        P_CLIENTES.RT_DIGITO_CONTROL(TO_NUMBER(TRIM(P_NUMERO_IDENTIFICACION))),
                                                        NULL),
                                                 NULL) --PER_DIGITO_CONTROL
                ,
                 PER_PRIMER_APELLIDO       = NVL(UPPER(TRIM(P_PRIMER_APELLIDO)),
                                                 NULL) --PER_PRIMER_APELLIDO
                ,
                 PER_SEGUNDO_APELLIDO      = NVL(UPPER(TRIM(P_SEGUNDO_APELLIDO)),
                                                 NULL) --PER_SEGUNDO_APELLIDO
                ,
                 PER_NOMBRE                = NVL(UPPER(TRIM(P_NOMBRES)),
                                                 NULL) --PER_NOMBRE
                ,
                 PER_SEXO                  = NVL(P_TIPOSEXO, NULL) --PER_SEXO
                ,
                 PER_ES_CORREDOR           = NULL --PER_ES_CORREDOR
                ,
                 PER_NOMBRE_USUARIO        = NULL --PER_NOMBRE_USUARIO
                ,
                 PER_INICIALES_USUARIO     = NULL --PER_INICIALES_USUARIO
                ,
                 PER_SUC_CODIGO            = NULL --PER_SUC_CODIGO
                ,
                 PER_CPR_MNEMONICO         = NULL --PER_CPR_MNEMONICO
                ,
                 PER_MAIL_CORREDOR         = NULL --PER_MAIL_CORREDOR
                ,
                 PER_TIPO_COMERCIAL        = NULL --PER_TIPO_COMERCIAL
                ,
                 PER_EJECUTA_ORDEN_MESA    = NULL --PER_EJECUTA_ORDEN_MESA
                ,
                 PER_PER_NUM_IDEN          = NULL --PER_PER_NUM_IDEN
                ,
                 PER_PER_TID_CODIGO        = NULL --PER_PER_TID_CODIGO
                ,
                 PER_CCT_MNEMONICO         = NVL(DECODE(P_TIPO_CLIENTE,
                                                        'PJU',
                                                        'OTROS',
                                                        NULL),
                                                 NULL) --PER_CCT_MNEMONICO
                ,
                 PER_ESTADO                = NULL --PER_ESTADO
                ,
                 PER_CLF_SECUENCIAL        = NULL --PER_CLF_SECUENCIAL
                ,
                 PER_TELEFONO_DIRECTO      = NULL --PER_TELEFONO_DIRECTO
                ,
                 PER_CODIGO_BOLSA          = NULL --PER_CODIGO_BOLSA
                ,
                 PER_COMERCIAL_ACC_DIRECTO = NULL --PER_COMERCIAL_ACC_DIRECTO
                ,
                 PER_CODIGO_SAE_ACC        = NULL --PER_CODIGO_SAE_ACC
                ,
                 PER_COMPLEMENTACION       = NULL --PER_COMPLEMENTACION
                ,
                 PER_COMERCIAL_OPX         = NULL --PER_COMERCIAL_OPX
                ,
                 PER_USUARIO_DECEVAL       = NULL --PER_USUARIO_DECEVAL
                ,
                 PER_ID_USUARIO_DECEVAL    = NULL --PER_ID_USUARIO_DECEVAL
                ,
                 PER_CODIGO_SIOPEL         = NULL --PER_CODIGO_SIOPEL
                ,
                 PER_CODIGO_XSTREAM        = NULL --PER_CODIGO_XSTREAM
                ,
                 PER_NOTIFICA_CENLINEA     = NULL --PER_NOTIFICA_CENLINEA
                ,
                 PER_TIP_COMERCIAL_UDF     = NULL --PER_TIP_COMERCIAL_UDF
                ,
                 PER_ORIGEN                = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL,
                                                        'N'),
                                                    'N',
                                                    P_ORIGEN,
                                                    'VID') --PER_ORIGEN
                 --,PER_REPRESENTANTE_LEGAL    = NULL
                 --,PER_CODIGO_SAE_DER         = NULL
                 --,PER_CODIGO_MASTER_RF       = NULL
                 --,PER_CODIGO_MASTER_RV       = NULL
                 --,PER_COMPLEMENTA_CTA        = 'N'
                ,
                 PER_ATIENDE_CLIENTES = NULL
           WHERE PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION)
             AND PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION);

          IF SQL%ROWCOUNT = 0 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
          END IF;

        EXCEPTION
          WHEN OTHERS THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            --P_CAB.CrearError('Error creando persona 1.'||SQLERRM);
            P_CAB.CrearError('Error actualizando persona 1.');
            RAISE V_ERROR_CREACION;

        END;
      END IF;

      /* CREACION DE ORDENANTES PANTALLA LIVIANA*/
      IF P_ORIGEN = 'PLV' THEN

        V_CIUDAD_RESIDENCIA := P_CIUDAD_RESIDENCIA;
        V_AGE_CODIGO_PPAL   := NULL;

        IF TRIM(P_NUMERO_IDENTIFICACION) != TRIM(P_IDEN_ORDENANTE) THEN
          C_C1 := NULL;
          OPEN C1;
          FETCH C1
            INTO C_C1;
          CLOSE C1;

          C_C1.PER_NUM_IDEN := NVL(C_C1.PER_NUM_IDEN, ' ');

          IF C_C1.PER_NUM_IDEN = ' ' OR C_C1.PER_NUM_IDEN IS NULL THEN
            BEGIN
              INSERT INTO PERSONAS
                (PER_NUM_IDEN,
                 PER_TID_CODIGO,
                 PER_TIPO,
                 PER_RAZON_SOCIAL,
                 PER_DIGITO_CONTROL,
                 PER_PRIMER_APELLIDO,
                 PER_SEGUNDO_APELLIDO,
                 PER_NOMBRE,
                 PER_SEXO,
                 PER_ES_CORREDOR,
                 PER_NOMBRE_USUARIO,
                 PER_INICIALES_USUARIO,
                 PER_SUC_CODIGO,
                 PER_CPR_MNEMONICO,
                 PER_MAIL_CORREDOR,
                 PER_TIPO_COMERCIAL,
                 PER_EJECUTA_ORDEN_MESA,
                 PER_PER_NUM_IDEN,
                 PER_PER_TID_CODIGO,
                 PER_CCT_MNEMONICO,
                 PER_ESTADO,
                 PER_CLF_SECUENCIAL,
                 PER_TELEFONO_DIRECTO,
                 PER_CODIGO_BOLSA,
                 PER_COMERCIAL_ACC_DIRECTO,
                 PER_CODIGO_SAE_ACC,
                 PER_COMPLEMENTACION,
                 PER_COMERCIAL_OPX,
                 PER_USUARIO_DECEVAL,
                 PER_ID_USUARIO_DECEVAL,
                 PER_CODIGO_SIOPEL,
                 PER_CODIGO_XSTREAM,
                 PER_NOTIFICA_CENLINEA,
                 PER_TIP_COMERCIAL_UDF,
                 PER_ORIGEN)
              VALUES
                (TRIM(P_IDEN_ORDENANTE) --PER_NUM_IDEN
                ,
                 TRIM(P_ID_ORDENANTE) --PER_TID_CODIGO
                ,
                 'PNA' --PER_TIPO
                ,
                 NULL --PER_RAZON_SOCIAL
                ,
                 NULL --PER_DIGITO_CONTROL
                ,
                 UPPER(TRIM(P_PRI_APEL_ORDENANTE)) --PER_PRIMER_APELLIDO
                ,
                 UPPER(TRIM(P_SEG_APEL_ORDENANTE)) --PER_SEGUNDO_APELLIDO
                ,
                 UPPER(TRIM(P_NOMBRES_ORDENANTE)) --PER_NOMBRE
                ,
                 P_TIPOSEXO_ORDENANTE --PER_SEXO
                ,
                 NULL --PER_ES_CORREDOR
                ,
                 NULL --PER_NOMBRE_USUARIO
                ,
                 NULL --PER_INICIALES_USUARIO
                ,
                 NULL --PER_SUC_CODIGO
                ,
                 NULL --PER_CPR_MNEMONICO
                ,
                 NULL --PER_MAIL_CORREDOR
                ,
                 NULL --PER_TIPO_COMERCIAL
                ,
                 NULL --PER_EJECUTA_ORDEN_MESA
                ,
                 NULL --PER_PER_NUM_IDEN
                ,
                 NULL --PER_PER_TID_CODIGO
                ,
                 NULL --PER_CCT_MNEMONICO
                ,
                 NULL --PER_ESTADO
                ,
                 NULL --PER_CLF_SECUENCIAL
                ,
                 NULL --PER_TELEFONO_DIRECTO
                ,
                 NULL --PER_CODIGO_BOLSA
                ,
                 NULL --PER_COMERCIAL_ACC_DIRECTO
                ,
                 NULL --PER_CODIGO_SAE_ACC
                ,
                 NULL --PER_COMPLEMENTACION
                ,
                 NULL --PER_COMERCIAL_OPX
                ,
                 NULL --PER_USUARIO_DECEVAL
                ,
                 NULL --PER_ID_USUARIO_DECEVAL
                ,
                 NULL --PER_CODIGO_SIOPEL
                ,
                 NULL --PER_CODIGO_XSTREAM
                ,
                 NULL --PER_NOTIFICA_CENLINEA
                ,
                 NULL --PER_TIP_COMERCIAL_UDF
                ,
                 'PLV' --PER_ORIGEN
                 );
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
              END IF;

            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando persona 2.');
                RAISE V_ERROR_CREACION;
            END;
          END IF;
        END IF;
      END IF;

      IF P_ORIGEN = 'VIN' AND
         (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
         ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL) THEN

        --insert_clob('legó 1 cliente:'||P_NUMERO_IDENTIFICACION);
        UPDATE PERSONAS
           SET PER_ORIGEN = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                                   'N',
                                   P_ORIGEN,
                                   'VID')
         WHERE PER_NUM_IDEN = P_NUMERO_IDENTIFICACION
           AND PER_TID_CODIGO = P_TIPO_IDENTIFICACION;

        /* Para ciudad de residencia*/
        IF P_TIPO_CLIENTE = 'PJU' THEN
          V_AGE_CODIGO_PPAL   := P_CIUDAD_RESIDENCIA;
          V_CIUDAD_RESIDENCIA := NULL;
        ELSE
          V_AGE_CODIGO_PPAL   := NULL;
          V_CIUDAD_RESIDENCIA := P_CIUDAD_RESIDENCIA;
        END IF;

        /* Validar numero de 5 ordenantes maximo por cliente */
        OPEN PERV_VINCULA(P_NUMERO_FORMULARIO_VIN,
                          P_NUMERO_IDENTIFICACION,
                          P_TIPO_IDENTIFICACION);
        FETCH PERV_VINCULA
          INTO C_PERV_VINCULA;
        WHILE PERV_VINCULA%FOUND LOOP

          V_CLIENTES_SEGUNDO := 0;
          OPEN CLIENTES_SEGUNDO(TRIM(C_PERV_VINCULA.PERV_PER_NUM_IDEN),
                                TRIM(C_PERV_VINCULA.PERV_PER_TID_CODIGO));
          FETCH CLIENTES_SEGUNDO
            INTO V_CLIENTES_SEGUNDO;
          CLOSE CLIENTES_SEGUNDO;

          V_COMERCIAL_VALIDA := 'N';
          OPEN COMERCIAL_VALIDA(TRIM(C_PERV_VINCULA.PERV_PER_NUM_IDEN),
                                TRIM(C_PERV_VINCULA.PERV_PER_TID_CODIGO));
          FETCH COMERCIAL_VALIDA
            INTO V_COMERCIAL_VALIDA;
          CLOSE COMERCIAL_VALIDA;

          V_COMERCIAL_VALIDA := NVL(V_COMERCIAL_VALIDA, 'N');

          V_CLIENTES_SEGUNDO := NVL(V_CLIENTES_SEGUNDO, 0);
          IF V_CLIENTES_SEGUNDO > 5 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('Ordenante ' ||
                             TRIM(C_PERV_VINCULA.PERV_PER_TID_CODIGO) || '-' ||
                             TRIM(C_PERV_VINCULA.PERV_PER_NUM_IDEN) ||
                             ' no puede asociarse a mas de cinco clientes');
            RAISE V_ERROR_CREACION;
          END IF;

          IF V_COMERCIAL_VALIDA = 'S' THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('No es posible relacionar la persona como persona relacionada, esta definido como usuario interno');
            RAISE V_ERROR_CREACION;
          END IF;

          IF V_ERRORES = 0 THEN
            BEGIN
              INSERT INTO PERSONAS
                (PER_NUM_IDEN,
                 PER_TID_CODIGO,
                 PER_TIPO,
                 PER_RAZON_SOCIAL,
                 PER_DIGITO_CONTROL,
                 PER_PRIMER_APELLIDO,
                 PER_SEGUNDO_APELLIDO,
                 PER_NOMBRE,
                 PER_SEXO,
                 PER_ES_CORREDOR,
                 PER_NOMBRE_USUARIO,
                 PER_INICIALES_USUARIO,
                 PER_SUC_CODIGO,
                 PER_CPR_MNEMONICO,
                 PER_MAIL_CORREDOR,
                 PER_TIPO_COMERCIAL,
                 PER_EJECUTA_ORDEN_MESA,
                 PER_PER_NUM_IDEN,
                 PER_PER_TID_CODIGO,
                 PER_CCT_MNEMONICO,
                 PER_ESTADO,
                 PER_CLF_SECUENCIAL,
                 PER_TELEFONO_DIRECTO,
                 PER_CODIGO_BOLSA,
                 PER_COMERCIAL_ACC_DIRECTO,
                 PER_CODIGO_SAE_ACC,
                 PER_COMPLEMENTACION,
                 PER_COMERCIAL_OPX,
                 PER_USUARIO_DECEVAL,
                 PER_ID_USUARIO_DECEVAL,
                 PER_CODIGO_SIOPEL,
                 PER_CODIGO_XSTREAM,
                 PER_NOTIFICA_CENLINEA,
                 PER_TIP_COMERCIAL_UDF,
                 PER_ORIGEN
                 -- ,PER_REPRESENTANTE_LEGAL
                 -- ,PER_CODIGO_SAE_DER
                 -- ,PER_CODIGO_MASTER_RF
                 -- ,PER_CODIGO_MASTER_RV
                 -- ,PER_COMPLEMENTA_CTA
                ,
                 PER_ATIENDE_CLIENTES)
              VALUES
                (TRIM(C_PERV_VINCULA.PERV_PER_NUM_IDEN) --PER_NUM_IDEN
                ,
                 TRIM(C_PERV_VINCULA.PERV_PER_TID_CODIGO) --PER_TID_CODIGO
                ,
                 'PNA' --PER_TIPO
                ,
                 NULL --PER_RAZON_SOCIAL
                ,
                 NULL --PER_DIGITO_CONTROL
                ,
                 UPPER(TRIM(C_PERV_VINCULA.PERV_PRIMER_APELLIDO)) --PER_PRIMER_APELLIDO
                ,
                 UPPER(TRIM(C_PERV_VINCULA.PERV_SEGUNDO_APELLIDO)) --PER_SEGUNDO_APELLIDO
                ,
                 UPPER(TRIM(C_PERV_VINCULA.PERV_NOMBRE)) --PER_NOMBRE
                ,
                 C_PERV_VINCULA.PERV_TIPO_SEXO --PER_SEXO
                ,
                 NULL --PER_ES_CORREDOR
                ,
                 NULL --PER_NOMBRE_USUARIO
                ,
                 NULL --PER_INICIALES_USUARIO
                ,
                 NULL --PER_SUC_CODIGO
                ,
                 NULL --PER_CPR_MNEMONICO
                ,
                 NULL --PER_MAIL_CORREDOR
                ,
                 NULL --PER_TIPO_COMERCIAL
                ,
                 NULL --PER_EJECUTA_ORDEN_MESA
                ,
                 NULL --PER_PER_NUM_IDEN
                ,
                 NULL --PER_PER_TID_CODIGO
                ,
                 NULL --PER_CCT_MNEMONICO
                ,
                 NULL --PER_ESTADO
                ,
                 NULL --PER_CLF_SECUENCIAL
                ,
                 NULL --PER_TELEFONO_DIRECTO
                ,
                 NULL --PER_CODIGO_BOLSA
                ,
                 NULL --PER_COMERCIAL_ACC_DIRECTO
                ,
                 NULL --PER_CODIGO_SAE_ACC
                ,
                 NULL --PER_COMPLEMENTACION
                ,
                 NULL --PER_COMERCIAL_OPX
                ,
                 NULL --PER_USUARIO_DECEVAL
                ,
                 NULL --PER_ID_USUARIO_DECEVAL
                ,
                 NULL --PER_CODIGO_SIOPEL
                ,
                 NULL --PER_CODIGO_XSTREAM
                ,
                 NULL --PER_NOTIFICA_CENLINEA
                ,
                 NULL --PER_TIP_COMERCIAL_UDF
                ,
                 DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                        'N',
                        'VIN',
                        'VID') --PER_ORIGEN
                 --  ,NULL                          --PER_REPRESENTANTE_LEGAL
                 --  ,NULL                          --PER_CODIGO_SAE_DER
                 --  ,NULL                          --PER_CODIGO_MASTER_RF
                 --  ,NULL                          --PER_CODIGO_MASTER_RV
                 --  ,'N'                           --PER_COMPLEMENTA_CTA
                ,
                 NULL --PER_ATIENDE_CLIENTES
                 );
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
              END IF;

            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando persona 3. ' ||
                                 TRIM(C_PERV_VINCULA.PERV_PER_NUM_IDEN) || ' ' ||
                                 TRIM(C_PERV_VINCULA.PERV_PER_TID_CODIGO) ||
                                 ' - ' || SQLERRM);
                RAISE V_ERROR_CREACION;
            END;
          END IF;
          FETCH PERV_VINCULA
            INTO C_PERV_VINCULA;
        END LOOP;
        CLOSE PERV_VINCULA;
      END IF;

      /*JLG VINCULACION, EN CASO DE ACTUALIZACION ESTADOS ('PRV','INU','NUE')*/
      IF P_ORIGEN = 'VIN' AND
         (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN ('PRV', 'INU', 'NUE') OR
         NVL(P_ORIGEN_OPERACION, 'N') != 'N') THEN

        /* Para ciudad de residencia*/
        IF P_TIPO_CLIENTE = 'PJU' THEN
          V_AGE_CODIGO_PPAL   := P_CIUDAD_RESIDENCIA;
          V_CIUDAD_RESIDENCIA := NULL;
        ELSE
          V_AGE_CODIGO_PPAL   := NULL;
          V_CIUDAD_RESIDENCIA := P_CIUDAD_RESIDENCIA;
        END IF;

        /* Validar numero de 5 ordenantes maximo por cliente */
        OPEN PERV_VINCULA_2(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
        FETCH PERV_VINCULA_2
          INTO C_PERV_VINCULA_2;
        WHILE PERV_VINCULA_2%FOUND LOOP

          V_CLIENTES_SEGUNDO := 0; /*No se realiza validacion porque desde Data se está validando maximo ordenantes*/
          OPEN CLIENTES_SEGUNDO(TRIM(C_PERV_VINCULA_2.PERV_PER_NUM_IDEN),
                                TRIM(C_PERV_VINCULA_2.PERV_PER_TID_CODIGO));
          FETCH CLIENTES_SEGUNDO
            INTO V_CLIENTES_SEGUNDO;
          CLOSE CLIENTES_SEGUNDO;

          V_COMERCIAL_VALIDA := 'N';
          OPEN COMERCIAL_VALIDA(TRIM(C_PERV_VINCULA_2.PERV_PER_NUM_IDEN),
                                TRIM(C_PERV_VINCULA_2.PERV_PER_TID_CODIGO));
          FETCH COMERCIAL_VALIDA
            INTO V_COMERCIAL_VALIDA;
          CLOSE COMERCIAL_VALIDA;

          V_COMERCIAL_VALIDA := NVL(V_COMERCIAL_VALIDA, 'N');

          V_CLIENTES_SEGUNDO := NVL(V_CLIENTES_SEGUNDO, 0);
          IF V_CLIENTES_SEGUNDO > 5 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('Ordenante ' ||
                             TRIM(C_PERV_VINCULA_2.PERV_PER_TID_CODIGO) || '-' ||
                             TRIM(C_PERV_VINCULA_2.PERV_PER_NUM_IDEN) ||
                             ' no puede asociarse a mas de cinco clientes, Merge');
            RAISE V_ERROR_CREACION;
          END IF;

          IF V_COMERCIAL_VALIDA = 'S' THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('No es posible relacionar la persona como persona relacionada, esta definido como usuario interno, Merge');
            RAISE V_ERROR_CREACION;
          END IF;

          IF V_ERRORES = 0 THEN
            BEGIN
              MERGE INTO PERSONAS P
              USING dual dd
              ON (P.PER_NUM_IDEN = TRIM(C_PERV_VINCULA_2.PERV_PER_NUM_IDEN) AND P.PER_TID_CODIGO = TRIM(C_PERV_VINCULA_2.PERV_PER_TID_CODIGO))
              WHEN MATCHED THEN
                UPDATE
                   SET P.PER_TIPO                  = 'PNA' --PER_TIPO
                      ,
                       P.PER_RAZON_SOCIAL          = NULL --PER_RAZON_SOCIAL
                      ,
                       P.PER_DIGITO_CONTROL        = NULL --PER_DIGITO_CONTROL
                      ,
                       P.PER_PRIMER_APELLIDO       = UPPER(TRIM(C_PERV_VINCULA_2.PERV_PRIMER_APELLIDO)) --PER_PRIMER_APELLIDO
                      ,
                       P.PER_SEGUNDO_APELLIDO      = UPPER(TRIM(C_PERV_VINCULA_2.PERV_SEGUNDO_APELLIDO)) --PER_SEGUNDO_APELLIDO
                      ,
                       P.PER_NOMBRE                = UPPER(TRIM(C_PERV_VINCULA_2.PERV_NOMBRE)) --PER_NOMBRE
                      ,
                       P.PER_SEXO                  = C_PERV_VINCULA_2.PERV_TIPO_SEXO --PER_SEXO
                      ,
                       P.PER_ES_CORREDOR           = NULL --PER_ES_CORREDOR
                      ,
                       P.PER_NOMBRE_USUARIO        = NULL --PER_NOMBRE_USUARIO
                      ,
                       P.PER_INICIALES_USUARIO     = NULL --PER_INICIALES_USUARIO
                      ,
                       P.PER_SUC_CODIGO            = NULL --PER_SUC_CODIGO
                      ,
                       P.PER_CPR_MNEMONICO         = NULL --PER_CPR_MNEMONICO
                      ,
                       P.PER_MAIL_CORREDOR         = NULL --PER_MAIL_CORREDOR
                      ,
                       P.PER_TIPO_COMERCIAL        = NULL --PER_TIPO_COMERCIAL
                      ,
                       P.PER_EJECUTA_ORDEN_MESA    = NULL --PER_EJECUTA_ORDEN_MESA
                      ,
                       P.PER_PER_NUM_IDEN          = NULL --PER_PER_NUM_IDEN
                      ,
                       P.PER_PER_TID_CODIGO        = NULL --PER_PER_TID_CODIGO
                      ,
                       P.PER_CCT_MNEMONICO         = NULL --PER_CCT_MNEMONICO
                      ,
                       P.PER_ESTADO                = NULL --PER_ESTADO
                      ,
                       P.PER_CLF_SECUENCIAL        = NULL --PER_CLF_SECUENCIAL
                      ,
                       P.PER_TELEFONO_DIRECTO      = NULL --PER_TELEFONO_DIRECTO
                      ,
                       P.PER_CODIGO_BOLSA          = NULL --PER_CODIGO_BOLSA
                      ,
                       P.PER_COMERCIAL_ACC_DIRECTO = NULL --PER_COMERCIAL_ACC_DIRECTO
                      ,
                       P.PER_CODIGO_SAE_ACC        = NULL --PER_CODIGO_SAE_ACC
                      ,
                       P.PER_COMPLEMENTACION       = NULL --PER_COMPLEMENTACION
                      ,
                       P.PER_COMERCIAL_OPX         = NULL --PER_COMERCIAL_OPX
                      ,
                       P.PER_USUARIO_DECEVAL       = NULL --PER_USUARIO_DECEVAL
                      ,
                       P.PER_ID_USUARIO_DECEVAL    = NULL --PER_ID_USUARIO_DECEVAL
                      ,
                       P.PER_CODIGO_SIOPEL         = NULL --PER_CODIGO_SIOPEL
                      ,
                       P.PER_CODIGO_XSTREAM        = NULL --PER_CODIGO_XSTREAM
                      ,
                       P.PER_NOTIFICA_CENLINEA     = NULL --PER_NOTIFICA_CENLINEA
                      ,
                       P.PER_TIP_COMERCIAL_UDF     = NULL --PER_TIP_COMERCIAL_UDF
                      ,
                       P.PER_ORIGEN                = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL,
                                                                'N'),
                                                            'N',
                                                            'VIN',
                                                            'VID') --PER_ORIGEN
                       --  ,P.PER_REPRESENTANTE_LEGAL    = NULL
                       -- ,P.PER_CODIGO_SAE_DER         = NULL
                       --  ,P.PER_CODIGO_MASTER_RF       = NULL
                       --  ,P.PER_CODIGO_MASTER_RV       = NULL
                       --  ,P.PER_COMPLEMENTA_CTA        = 'N'
                      ,
                       P.PER_ATIENDE_CLIENTES = NULL
              WHEN NOT MATCHED THEN
                INSERT
                  (P.PER_NUM_IDEN,
                   P.PER_TID_CODIGO,
                   P.PER_TIPO,
                   P.PER_RAZON_SOCIAL,
                   P.PER_DIGITO_CONTROL,
                   P.PER_PRIMER_APELLIDO,
                   P.PER_SEGUNDO_APELLIDO,
                   P.PER_NOMBRE,
                   P.PER_SEXO,
                   P.PER_ES_CORREDOR,
                   P.PER_NOMBRE_USUARIO,
                   P.PER_INICIALES_USUARIO,
                   P.PER_SUC_CODIGO,
                   P.PER_CPR_MNEMONICO,
                   P.PER_MAIL_CORREDOR,
                   P.PER_TIPO_COMERCIAL,
                   P.PER_EJECUTA_ORDEN_MESA,
                   P.PER_PER_NUM_IDEN,
                   P.PER_PER_TID_CODIGO,
                   P.PER_CCT_MNEMONICO,
                   P.PER_ESTADO,
                   P.PER_CLF_SECUENCIAL,
                   P.PER_TELEFONO_DIRECTO,
                   P.PER_CODIGO_BOLSA,
                   P.PER_COMERCIAL_ACC_DIRECTO,
                   P.PER_CODIGO_SAE_ACC,
                   P.PER_COMPLEMENTACION,
                   P.PER_COMERCIAL_OPX,
                   P.PER_USUARIO_DECEVAL,
                   P.PER_ID_USUARIO_DECEVAL,
                   P.PER_CODIGO_SIOPEL,
                   P.PER_CODIGO_XSTREAM,
                   P.PER_NOTIFICA_CENLINEA,
                   P.PER_TIP_COMERCIAL_UDF,
                   P.PER_ORIGEN
                   -- ,P.PER_REPRESENTANTE_LEGAL
                   -- ,P.PER_CODIGO_SAE_DER
                   -- ,P.PER_CODIGO_MASTER_RF
                   -- ,P.PER_CODIGO_MASTER_RV
                   -- ,P.PER_COMPLEMENTA_CTA
                  ,
                   P.PER_ATIENDE_CLIENTES)
                VALUES
                  (TRIM(C_PERV_VINCULA_2.PERV_PER_NUM_IDEN) --PER_NUM_IDEN
                  ,
                   TRIM(C_PERV_VINCULA_2.PERV_PER_TID_CODIGO) --PER_TID_CODIGO
                  ,
                   'PNA' --PER_TIPO
                  ,
                   NULL --PER_RAZON_SOCIAL
                  ,
                   NULL --PER_DIGITO_CONTROL
                  ,
                   UPPER(TRIM(C_PERV_VINCULA_2.PERV_PRIMER_APELLIDO)) --PER_PRIMER_APELLIDO
                  ,
                   UPPER(TRIM(C_PERV_VINCULA_2.PERV_SEGUNDO_APELLIDO)) --PER_SEGUNDO_APELLIDO
                  ,
                   UPPER(TRIM(C_PERV_VINCULA_2.PERV_NOMBRE)) --PER_NOMBRE
                  ,
                   C_PERV_VINCULA_2.PERV_TIPO_SEXO --PER_SEXO
                  ,
                   NULL --PER_ES_CORREDOR
                  ,
                   NULL --PER_NOMBRE_USUARIO
                  ,
                   NULL --PER_INICIALES_USUARIO
                  ,
                   NULL --PER_SUC_CODIGO
                  ,
                   NULL --PER_CPR_MNEMONICO
                  ,
                   NULL --PER_MAIL_CORREDOR
                  ,
                   NULL --PER_TIPO_COMERCIAL
                  ,
                   NULL --PER_EJECUTA_ORDEN_MESA
                  ,
                   NULL --PER_PER_NUM_IDEN
                  ,
                   NULL --PER_PER_TID_CODIGO
                  ,
                   NULL --PER_CCT_MNEMONICO
                  ,
                   NULL --PER_ESTADO
                  ,
                   NULL --PER_CLF_SECUENCIAL
                  ,
                   NULL --PER_TELEFONO_DIRECTO
                  ,
                   NULL --PER_CODIGO_BOLSA
                  ,
                   NULL --PER_COMERCIAL_ACC_DIRECTO
                  ,
                   NULL --PER_CODIGO_SAE_ACC
                  ,
                   NULL --PER_COMPLEMENTACION
                  ,
                   NULL --PER_COMERCIAL_OPX
                  ,
                   NULL --PER_USUARIO_DECEVAL
                  ,
                   NULL --PER_ID_USUARIO_DECEVAL
                  ,
                   NULL --PER_CODIGO_SIOPEL
                  ,
                   NULL --PER_CODIGO_XSTREAM
                  ,
                   NULL --PER_NOTIFICA_CENLINEA
                  ,
                   NULL --PER_TIP_COMERCIAL_UDF
                  ,
                   DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                          'N',
                          'VIN',
                          'VID') --PER_ORIGEN
                   --  ,NULL                          --PER_REPRESENTANTE_LEGAL
                   --  ,NULL                          --PER_CODIGO_SAE_DER
                   --  ,NULL                          --PER_CODIGO_MASTER_RF
                   --  ,NULL                          --PER_CODIGO_MASTER_RV
                   --  ,'N'                           --PER_COMPLEMENTA_CTA
                  ,
                   NULL --PER_ATIENDE_CLIENTES
                   );

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
              END IF;

            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error merge persona 3. ' ||
                                 TRIM(C_PERV_VINCULA_2.PERV_PER_NUM_IDEN) || ' ' ||
                                 TRIM(C_PERV_VINCULA_2.PERV_PER_TID_CODIGO));
                RAISE V_ERROR_CREACION;
            END;
          END IF;
          FETCH PERV_VINCULA_2
            INTO C_PERV_VINCULA_2;
        END LOOP;
        CLOSE PERV_VINCULA_2;
      END IF;

      SELECT OCC_SEQ.NEXTVAL INTO V_SECUENCIA_CCC FROM DUAL;

      IF P_ORIGEN = 'PLV' THEN
        V_CONTRATO_COMISION    := 'OPA-' || TRIM(TO_CHAR(V_SECUENCIA_CCC));
        V_CLI_TEN_CODIGO       := P_CLASIFICACION_ENTIDAD;
        V_CLI_CARACTER_ENTIDAD := P_TIPO_EMPRESA;
        V_CONTRATO_DCVAL       := SUBSTR(TRIM(P_NUMERO_IDENTIFICACION),
                                         1,
                                         10);
      END IF;

      IF P_ORIGEN = 'VIN' THEN
        V_CONTRATO_COMISION := P_CONTRATO_COMISION;
        V_CONTRATO_DCVAL    := P_CONTRATO_DCVAL;

        IF P_TIPO_CLIENTE = 'PNA' THEN
          V_CLI_TEN_CODIGO       := 99;
          V_CLI_CARACTER_ENTIDAD := 4;
        ELSE
          V_CLI_TEN_CODIGO := P_CLASIFICACION_ENTIDAD;
          SELECT DECODE(P_TIPO_EMPRESA,
                        'Publica',
                        1,
                        'Privada',
                        2,
                        'Mixta',
                        3)
            INTO V_CLI_CARACTER_ENTIDAD
            FROM DUAL;
        END IF;
      END IF;

      P_FORMULARIO_APERTURA := P_INTEGRACION.FN_FORMULARIO_APERTURA();

      V_BCC_CLIENTE   := NULL;
      V_BSC_CLIENTE   := NULL;
      V_BCC_ALT       := NULL;
      V_BSC_ALT       := NULL;
      V_CLIENTE_FATCA := 'N';

      P_CLIENTES.PR_SEGMENTACION_INICIAL(TRIM(P_NUMERO_IDENTIFICACION),
                                         TRIM(P_TIPO_IDENTIFICACION),
                                         P_TIPO_CLIENTE,
                                         'N',
                                         NULL,
                                         NULL,
                                         V_BCC_CLIENTE,
                                         V_BSC_CLIENTE,
                                         V_BCC_ALT,
                                         V_BSC_ALT);

      IF NVL(P_GRADO_CONSANGUI_PEP, ' ') IN
         ('COP',
          'PAD',
          'SUE',
          'HIJ',
          'ABU',
          'CUN',
          'HER',
          'NIE',
          'YEN',
          'NIC',
          'ABC',
          'HIC') THEN
        V_TIENE_CONSANGUI_PEP := 'S';
      ELSE
        V_TIENE_CONSANGUI_PEP := 'N';
      END IF;

      /* JLG Vinculacion Digital*/
      IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
         ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL THEN

        BEGIN
          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_ULTIMA_OPERACION_EJECUTADA,
             CLI_CLAVE_INTERNET,
             CLI_NIC,
             CLI_REFERENCIADO,
             CLI_DIRECCION_OFICINA,
             CLI_AGE_CODIGO_TRABAJA,
             CLI_TELEFONO_OFICINA,
             CLI_DIRECCION_RESIDENCIA,
             CLI_AGE_CODIGO_RESIDE,
             CLI_TELEFONO_RESIDENCIA
             --,CLI_DIRECCION_EMAIL
            ,
             CLI_FAX,
             CLI_APARTADO_AEREO,
             CLI_NUMERO_CONTRATO_DCVAL,
             CLI_NUMERO_CONTRATO_DCV,
             CLI_ECI_MNEMONICO,
             CLI_NAC_MNEMONICO,
             CLI_FECHA_NACIMIENTO,
             CLI_AGE_CODIGO,
             CLI_OCUPACION,
             CLI_ORE_MNEMONICO,
             CLI_OTRO_ORIGEN_RECURSOS,
             CLI_TITULO_UNIVER,
             CLI_EMPRESA,
             CLI_CARGO,
             CLI_RIM_CODIGO,
             CLI_RPA_CODIGO,
             CLI_EXTRANJERO,
             CLI_AGE_CODIGO_NACION,
             CLI_GRAN_CONTRIBUYENTE,
             CLI_AUTORRETENEDOR,
             CLI_SUJETO_RTEFTE,
             CLI_TEN_CODIGO,
             CLI_NUMERO_ESCRITURA,
             CLI_FECHA_ESCRITURA,
             CLI_NTR_CODIGO,
             CLI_NTR_AGE_CODIGO,
             CLI_REGISTRO_CAMARA,
             CLI_FECHA_REGCAMARA,
             CLI_ACTIVIDAD_ECONOMICA,
             CLI_DOMICILIO_PRINCIPAL,
             CLI_AGE_CODIGO_PPAL,
             CLI_SEC_MNEMONICO,
             CLI_RECURSOS_ACT_PRINC,
             CLI_NUM_ULT_REF_ESCRITURA,
             CLI_FEC_ULT_REF_ESCRITURA,
             CLI_NTR_CODIGO_ES_MODIFICADA,
             CLI_NTR_AGE_CODIGO_ES_MODIFICA,
             CLI_CAPITAL_AUTORIZADO,
             CLI_CAPITAL_SUSCRITO,
             CLI_CATEGORIA_CLIENTE_INST,
             CLI_CONTACTO_CLIENTE_INST,
             CLI_TELEFONO_CONTACTO_INST,
             CLI_OBSERV_CLIENTE_INST,
             CLI_FEC_EXPEDICION_CAMARA,
             CLI_FEC_EXPEDICION_DOC_ID,
             CLI_AGE_CODIGO_EXP_DOC,
             CLI_CODIGO_SEBRA,
             CLI_CARACTER_ENTIDAD,
             CLI_ACT_MNEMONICO,
             CLI_FORMULARIO_APERTURA,
             CLI_USUARIO_APERTURA,
             CLI_FORMULARIO_ACTUALIZACION,
             CLI_FECHA_ULTIMA_MODIFICACION,
             CLI_USUARIO_ULTIMA_MODIFICA,
             CLI_OTRO_TIPO_EMPRESA,
             CLI_RECURSOS_BIENES_ENTREGAR,
             CLI_OTRO_RECURSOS_BIENES_ENT,
             CLI_OTRO_DETALLE_ACTIVIDAD,
             CLI_OTRO_TIPO_ENVIO_CORRES,
             CLI_PAGINA_WEB,
             CLI_FECHA_CONSTITUCION,
             CLI_MOI_MNEMONICO,
             CLI_RESPUESTA_WEB,
             CLI_PRW_CODIGO,
             CLI_EXCENTO_REPORTE_EFECTIVO,
             CLI_RAZON_EXCEPCION,
             CLI_AUTORIZA_TRANS_ACH,
             CLI_ENVIA_REMISION,
             CLI_ENVIA_FACTURA_DIV,
             CLI_ADM_PORTAFOLIO_DCVAL,
             CLI_ADM_PORTAFOLIO_DCV,
             CLI_GENERAR_CONSTANCIA,
             CLI_EXPERIENCIA_SECTOR_PUBLICO,
             CLI_CAMPANA_POLITICA,
             CLI_MOTIVO_ES_CLIENTE,
             CLI_RETENCION_FONDO,
             CLI_SUJETO_RTEFTE_FONDO,
             CLI_PROFESIONAL,
             CLI_BSC_BCC_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_RADICACION_PROFESIONAL,
             CLI_CELULAR,
             CLI_UNICA_OPERACION,
             CLI_PERFIL_RIESGO,
             CLI_CONTRATO_MARCO_COMISION
             --,CLI_DIRECCION_EMAIL_ALTERNA
            ,
             CLI_DECLARA_RENTA,
             CLI_RECURSOS_PUBLICOS,
             CLI_RECONOCIMIENTO_PUBLICO,
             CLI_CAMPO_RECONOCIMIENTO,
             CLI_INICIO_COBRO_ADMON_VALORES,
             CLI_PAPELETAS_DIARIAS,
             CLI_ADR_PROGRAM,
             CLI_FECHA_ULT_MOD_MASIVA,
             CLI_CNU_MNEMONICO,
             CLI_EXCENTO_REPORTE_DIVISAS,
             CLI_COMPARTIR_INFORMACION,
             CLI_ENVIO_DE_CORREO_MASIVO,
             CLI_OPX,
             CLI_FECHA_OPX,
             CLI_NO_OPX,
             CLI_EN_ACTUALIZACION_LINEA,
             CLI_MONEDA_EXT,
             CLI_CLSO_MNEMONICO,
             CLI_PSC_MNEMONICO,
             CLI_MIGRADO_DAVIVALORES,
             CLI_INSTITUCIONAL_EXTRANJERO,
             CLI_VIGILADO_SFC,
             CLI_BSC_BCC_MNEMONICO_ALT,
             CLI_BSC_MNEMONICO_ALT,
             CLI_RIESGO_LAFT,
             CLI_INDICIO_FATCA,
             CLI_BANCA_PRIVADA,
             CLI_FORMULARIO_VINCULACION,
             CLI_RECONO_PUBLICA_PEP,
             CLI_RECONO_POLITICA_PEP,
             CLI_CARGO_PEP,
             CLI_FECHA_CARGO_PEP,
             CLI_FECHA_DESVINCULA_PEP,
             CLI_REP_LEGAL_PEP,
             CLI_TIENE_CONSANGUI_PEP,
             CLI_GRADO_CONSANGUI_PEP,
             CLI_NOMBRE_FAMILIAR_PEP,
             CLI_PRIMER_APELLIDO_PEP,
             CLI_SEGUNDO_APELLIDO_PEP,
             CLI_ESTADO_VINCULACION,
             CLI_CNU_MNEMONICO_SEC,
             CLI_MAN_REC_PUB,
             CLI_FECHA_VENCIMIENTO,
             CLI_CUENTA_FIN_EXTRA,
             CLI_ES_FIDEICOMI,
             CLI_NOMBRE_FIDEICOMISO,
             CLI_NIT_FIDEICOMISO,
             CLI_FIDU_ADMIN_FIDEICOMISO,
             CLI_ORG_INTERNA_PEP,
             CLI_MONTO_INICIAL_INVERSION --CLI_MONTO_APROX_INVERSION
            ,
             CLI_PROPOSITO_COMISIONISTA,
             CLI_GRADO_CONSANGUI_PEP2,
             CLI_GRADO_CONSANGUI_PEP3,
             CLI_NOMBRE_FAMILIAR_PEP2,
             CLI_NOMBRE_FAMILIAR_PEP3,
             CLI_NUM_ID_FAMILIAR_PEP2,
             CLI_NUM_ID_FAMILIAR_PEP3,
             CLI_PRIMER_APELLIDO_PEP2,
             CLI_PRIMER_APELLIDO_PEP3,
             CLI_SEGUNDO_APELLIDO_PEP2,
             CLI_SEGUNDO_APELLIDO_PEP3,
             CLI_TID_COD_FAMILIAR_PEP2,
             CLI_TID_COD_FAMILIAR_PEP3)
          VALUES
            (TRIM(P_NUMERO_IDENTIFICACION) --*CLI_PER_NUM_IDEN
            ,
             TRIM(P_TIPO_IDENTIFICACION) --*CLI_PER_TID_CODIGO
            ,
             DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                    'N',
                    'ACC',
                    'INA') --CLI_ECL_MNEMONICO
            ,
             P_TIPO_CORRESPONDENCIA --CLI_TEC_MNEMONICO
            ,
             SYSDATE --CLI_FECHA_APERTURA
            ,
             SYSDATE --CLI_FECHA_ULTIMA_ACTUALIZACION
            ,
             DECODE(P_ORIGEN, 'PLV', USER, P_USUARIO_APERTURA) --CLI_USUARIO_ULTIMA_ACTUALIZACI
            ,
             'S' --CLI_AUTORIZA_PLAZO
            ,
             'S' --CLI_AUTORIZA_REPO
            ,
             'S' --CLI_AUTORIZA_SWAP
            ,
             'S' --CLI_AUTORIZA_CARRUSEL
            ,
             'S' --CLI_AUTORIZA_CONTRATO_COMISION
            ,
             'N' --CLI_AUTORIZA_ADMON_VALORES
            ,
             'N' --CLI_EXCENTO_DXM_FONDOS
            ,
             'I' --CLI_HABILITADO_INTERNET
            ,
             'N' --CLI_EXCENTO_IVA
            ,
             'C' --CLI_TIPO_CLIENTE --CLIENTE
            ,
             'AP' --CLI_ULTIMA_OPERACION_EJECUTADA
            ,
             NULL --CLI_CLAVE_INTERNET
            ,
             NULL --CLI_NIC
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_REFERENCIADO) --*CLI_REFERENCIADO
            ,
             P_DIRECCION_OFICINA --*CLI_DIRECCION_OFICINA
            ,
             P_CIUDAD_OFICINA --CLI_AGE_CODIGO_TRABAJA
            ,
             P_TELEFONO_OFICINA --CLI_TELEFONO_OFICINA
            ,
             P_DIRECCION_RESIDENCIA --*CLI_DIRECCION_RESIDENCIA
            ,
             V_CIUDAD_RESIDENCIA --*CLI_AGE_CODIGO_RESIDE P_CIUDAD_RESIDENCIA
            ,
             P_TELEFONO_RESIDENCIA --*CLI_TELEFONO_RESIDENCIA
             --,P_DIRECCIONEMAIL                                 --*CLI_DIRECCION_EMAIL
            ,
             NULL --CLI_FAX
            ,
             NULL --CLI_APARTADO_AEREO
            ,
             V_CONTRATO_DCVAL --CLI_NUMERO_CONTRATO_DCVAL
            ,
             NULL --CLI_NUMERO_CONTRATO_DCV
            ,
             P_CODIGO_ESTADO_CIVIL --*CLI_ECI_MNEMONICO
            ,
             P_NACIONALIDAD --*CLI_NAC_MNEMONICO
            ,
             TO_DATE(TRIM(P_FECHANACIMIENTO), 'DD-MM-YYYY') --*CLI_FECHA_NACIMIENTO
            ,
             P_CIUDAD_NACIMIENTO --*CLI_AGE_CODIGO
            ,
             NULL --CLI_OCUPACION
            ,
             P_ORIGEN_RECURSOS --*CLI_ORE_MNEMONICO
            ,
             P_OTRO_ORIGEN_RECURSOS --*CLI_OTRO_ORIGEN_RECURSOS
            ,
             NULL --CLI_TITULO_UNIVER
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_NOMBRE_EMPRESA) --CLI_EMPRESA
            ,
             P_CARGO_EMPLEADO --*CLI_CARGO
            ,
             NULL --CLI_RIM_CODIGO
            ,
             NULL --CLI_RPA_CODIGO
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_EXTRANJERA) --*CLI_EXTRANJERO
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_CIUDAD_EMPRESA) --*CLI_AGE_CODIGO_NACION
            ,
             DECODE(P_ORIGEN, 'PLV', 'N', P_GRAN_CONTRIBUYENTE) --*CLI_GRAN_CONTRIBUYENTE
            ,
             'N' --CLI_AUTORRETENEDOR
            ,
             DECODE(P_ORIGEN, 'PLV', 'S', P_SUJETO_RETEFUENTE) --*CLI_SUJETO_RTEFTE
            ,
             V_CLI_TEN_CODIGO --*CLI_TEN_CODIGO
            ,
             NULL --CLI_NUMERO_ESCRITURA
            ,
             NULL --CLI_FECHA_ESCRITURA
            ,
             NULL --CLI_NTR_CODIGO
            ,
             NULL --CLI_NTR_AGE_CODIGO
            ,
             NULL --CLI_REGISTRO_CAMARA
            ,
             NULL --CLI_FECHA_REGCAMARA
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_ACT_ECONOMICA_PPAL) --*CLI_ACTIVIDAD_ECONOMICA
            ,
             NULL --CLI_DOMICILIO_PRINCIPAL
            ,
             V_AGE_CODIGO_PPAL --CLI_AGE_CODIGO_PPAL
            ,
             NULL --CLI_SEC_MNEMONICO
            ,
             NULL --CLI_RECURSOS_ACT_PRINC
            ,
             NULL --CLI_NUM_ULT_REF_ESCRITURA
            ,
             NULL --CLI_FEC_ULT_REF_ESCRITURA
            ,
             NULL --CLI_NTR_CODIGO_ES_MODIFICADA
            ,
             NULL --CLI_NTR_AGE_CODIGO_ES_MODIFICA
            ,
             NULL --CLI_CAPITAL_AUTORIZADO
            ,
             NULL --CLI_CAPITAL_SUSCRITO
            ,
             NULL --CLI_CATEGORIA_                                                 --CLIENTE_INST
            ,
             NULL --CLI_CONTACTO_                                                 --CLIENTE_INST
            ,
             NULL --CLI_TELEFONO_CONTACTO_INST
            ,
             NULL --CLI_OBSERV_                                                 --CLIENTE_INST
            ,
             NULL --CLI_FEC_EXPEDICION_CAMARA
            ,
             TO_DATE(TRIM(P_FECHA_EXP_DOCUMENTO), 'DD-MM-YYYY') --*CLI_FEC_EXPEDICION_DOC_ID
            ,
             P_CIUDAD_EXP_DOCUMENTO --*CLI_AGE_CODIGO_EXP_DOC
            ,
             NULL --CLI_CODIGO_SEBRA
            ,
             V_CLI_CARACTER_ENTIDAD --*CLI_CARACTER_ENTIDAD
            ,
             P_ACTIVIDAD_CLIENTE --*CLI_ACT_MNEMONICO
            ,
             P_FORMULARIO_APERTURA --CLI_FORMULARIO_APERTURA
            ,
             DECODE(P_ORIGEN, 'PLV', USER, P_USUARIO_APERTURA) --CLI_USUARIO_APERTURA
            ,
             NULL --CLI_FORMULARIO_ACTUALIZACION
            ,
             NULL --CLI_FECHA_ULTIMA_MODIFICACION
            ,
             NULL --CLI_USUARIO_ULTIMA_MODIFICA
            ,
             NULL --CLI_OTRO_TIPO_EMPRESA
            ,
             DECODE(P_RECURSOS_ENTREGAR, 'Dinero', 'D', 'Otro', 'O') --*CLI_RECURSOS_BIENES_ENTREGAR
            ,
             P_OTRO_RECURSO_ENTREGA --*CLI_OTRO_RECURSOS_BIENES_ENT
            ,
             NULL --CLI_OTRO_DETALLE_ACTIVIDAD
            ,
             NULL --CLI_OTRO_TIPO_ENVIO_CORRES
            ,
             NULL --CLI_PAGINA_WEB
            ,
             DECODE(P_ORIGEN,
                    'PLV',
                    NULL,
                    TO_DATE(TRIM(P_FECHA_CREACION_EMPRESA), 'DD-MM-YYYY')) --*CLI_FECHA_CONSTITUCION
            ,
             DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                    'N',
                    NULL,
                    'PRV') --CLI_MOI_MNEMONICO
            ,
             NULL --CLI_RESPUESTA_WEB
            ,
             NULL --CLI_PRW_CODIGO
            ,
             NULL --CLI_EXCENTO_REPORTE_EFECTIVO
            ,
             NULL --CLI_RAZON_EXCEPCION
            ,
             'S' --CLI_AUTORIZA_TRANS_ACH
            ,
             NULL --CLI_ENVIA_REMISION
            ,
             NULL --CLI_ENVIA_FACTURA_DIV
            ,
             'S' --CLI_ADM_PORTAFOLIO_DCVAL
            ,
             'S' --CLI_ADM_PORTAFOLIO_DCV
            ,
             'N' --*CLI_GENERAR_CONSTANCIA
            ,
             DECODE(P_ORIGEN, 'PLV', 'N', P_EXP_SECTOR_PUBLICO) --CLI_EXPERIENCIA_SECTOR_PUBLICO
            ,
             DECODE(P_ORIGEN, 'PLV', 'N', P_CAMPANA_POLITICA) --CLI_CAMPANA_POLITICA
            ,
             'CP' --CLI_MOTIVO_ES_CLIENTE
            ,
             NULL --CLI_RETENCION_FONDO
            ,
             'S' --CLI_SUJETO_RTEFTE_FONDO
            ,
             DECODE(P_ORIGEN, 'PLV', 'N', P_CATEGORIZACION_CLIENTE) --CLI_PROFESIONAL
            ,
             V_BCC_CLIENTE --CLI_BSC_BCC_MNEMONICO
            ,
             V_BSC_CLIENTE --CLI_BSC_MNEMONICO
            ,
             NULL --CLI_RADICACION_PROFESIONAL
            ,
             P_CELULAR --CLI_CELULAR
            ,
             'N' --CLI_UNICA_OPERACION
            ,
             DECODE(UPPER(P_PERFIL_RIESGO),
                    'CONSERVADOR',
                    10,
                    'MODERADO',
                    20,
                    'ARRIESGADO',
                    30) --CLI_PERFIL_RIESGO Moderado = 20
            ,
             V_CONTRATO_COMISION --CLI_CONTRATO_MARCO_COMISION
             --,DECODE(P_ORIGEN,'PLV',NULL,P_DIRECCIONEMAIL_ALTERNO)  --CLI_DIRECCION_EMAIL_ALTERNA
            ,
             DECODE(P_ORIGEN, 'PLV', 'N', P_DECLARANTE) --*CLI_DECLARA_RENTA
            ,
             P_ADMIN_REC_PUBLICOS --'N'                        --CLI_RECURSOS_PUBLICOS-------------------- aca j.a.
            ,
             NVL(P_RECONOCIMIENTO_PUBLICO, 'N') --CLI_RECONOCIMIENTO_PUBLICO
            ,
             P_CAMPO_RECONOCIMIENTO --CLI_CAMPO_RECONOCIMIENTO
            ,
             NULL --CLI_INICIO_COBRO_ADMON_VALORES
            ,
             NULL --CLI_PAPELETAS_DIARIAS
            ,
             'N' --CLI_ADR_PROGRAM
            ,
             NULL --CLI_FECHA_ULT_MOD_MASIVA
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_CODIGOCIIU) --*CLI_CNU_MNEMONICO
            ,
             NULL --CLI_EXCENTO_REPORTE_DIVISAS
            ,
             NULL --CLI_COMPARTIR_INFORMACION
            ,
             NULL --CLI_ENVIO_DE_CORREO_MASIVO
            ,
             'N' --CLI_OPX
            ,
             NULL --CLI_FECHA_OPX
            ,
             'N' --CLI_NO_OPX
            ,
             NULL --CLI_EN_ACTUALIZACION_LINEA
            ,
             'N' --CLI_MONEDA_EXT
            ,
             DECODE(P_ORIGEN, 'PLV', NULL, P_CLASE_SOCIEDAD) --*CLI_CLSO_MNEMONICO
            ,
             P_PROFESION --*CLI_PSC_MNEMONICO
            ,
             NULL --CLI_MIGRADO_DAVIVALORES
            ,
             NULL --CLI_INSTITUCIONAL_EXTRANJERO
            ,
             NULL --CLI_VIGILADO_SFC
            ,
             V_BCC_ALT --CLI_BSC_BCC_MNEMONICO_ALT
            ,
             V_BSC_ALT --CLI_BSC_MNEMONICO_ALT
            ,
             NULL --CLI_RIESGO_LAFT
            ,
             NVL(P_INDICIOS_CRS_FN, 'N') --CLI_INDICIO_FATCA
            ,
             DECODE(P_ORIGEN, 'PLV', 'N', P_BANCA_PRIVADA) --CLI_BANCA_PRIVADA
            ,
             P_NUMERO_FORMULARIO_VIN --CLI_FORMULARIO_VINCULACION
            ,
             P_RECONO_PUBLICA_PEP --CLI_RECONO_PUBLICA_PEP
            ,
             P_RECONO_POLITICA_PEP --CLI_RECONO_POLITICA_PEP
            ,
             P_CARGO_PEP --CLI_CARGO_PEP
            ,
             TO_DATE(TRIM(P_FECHA_CARGO_PEP), 'DD-MM-YYYY') --CLI_FECHA_CARGO_PEP
            ,
             TO_DATE(TRIM(P_FECHA_DESVINCULA_PEP), 'DD-MM-YYYY') --CLI_FECHA_DESVINCULA_PEP
            ,
             P_REP_LEGAL_PEP --CLI_REP_LEGAL_PEP
            ,
             V_TIENE_CONSANGUI_PEP --CLI_TIENE_CONSANGUI_PEP
            ,
             P_GRADO_CONSANGUI_PEP --CLI_GRADO_CONSANGUI_PEP
            ,
             P_NOMBRE_FAMILIAR_PEP --CLI_NOMBRE_FAMILIAR_PEP
            ,
             P_PRIMER_APELLIDO_PEP --CLI_PRIMER_APELLIDO_PEP
            ,
             P_SEGUNDO_APELLIDO_PEP --CLI_SEGUNDO_APELLIDO_PEP
            ,
             DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                    'N',
                    NULL,
                    'PRV') --CLI_ESTADO_VINCULACION
            ,
             P_CIIU_SECUNDARIO,
             P_RECURSOS_PUBLICOS,
             TO_DATE(TRIM(P_FECHA_VEN_ID), 'DD-MM-YYYY'),
             P_CUENTASFINEXTRA,
             P_FIDEICOMITENTE,
             P_NOMBREFIDEICOMISO,
             P_NITFIDEICOMISO,
             P_FIDUADMINFIDEICOMISO,
             P_ORG_INTERNA_PEP,
             P_MONTOAPROXINVERSION,
             P_PROPOSITOCOMISIONISTA,
             P_GRADO_CONSANGUI_PEP2,
             P_GRADO_CONSANGUI_PEP3,
             P_NOMBRE_FAMILIAR_PEP2,
             P_NOMBRE_FAMILIAR_PEP3,
             P_NUM_ID_FAMILIAR_PEP2,
             P_NUM_ID_FAMILIAR_PEP3,
             P_PRIMER_APELLIDO_PEP2,
             P_PRIMER_APELLIDO_PEP3,
             P_SEGUNDO_APELLIDO_PEP2,
             P_SEGUNDO_APELLIDO_PEP3,
             P_TID_COD_FAMILIAR_PEP2,
             P_TID_COD_FAMILIAR_PEP3);

          IF SQL%ROWCOUNT = 0 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('Error creando cliente:' ||
                             TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                             TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                             SQLERRM);
          END IF;

          IF P_DIRECCIONEMAIL IS NOT NULL OR P_DIRECCIONEMAIL != '' THEN

            BEGIN
              P_CORREOS_COEASY.P_INSERTA_CORREO_CLI(P_ID      => TRIM(P_TIPO_IDENTIFICACION),
                                                    P_NIT     => TRIM(P_NUMERO_IDENTIFICACION),
                                                    P_TIPO    => 'P',
                                                    P_CORREOS => P_DIRECCIONEMAIL);
            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando cliente correo pincipal - ' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
            END;

          END IF;

          IF P_ORIGEN <> 'PLV' AND (P_DIRECCIONEMAIL_ALTERNO IS NOT NULL OR
             P_DIRECCIONEMAIL_ALTERNO != '') THEN

            BEGIN
              P_CORREOS_COEASY.P_INSERTA_CORREO_CLI(P_ID      => TRIM(P_TIPO_IDENTIFICACION),
                                                    P_NIT     => TRIM(P_NUMERO_IDENTIFICACION),
                                                    P_TIPO    => 'S',
                                                    P_CORREOS => P_DIRECCIONEMAIL_ALTERNO);
            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando cliente correo alterno - ' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
            END;

          END IF;

        END;
      END IF;

      IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN ('PRV', 'INU', 'NUE') OR
         NVL(P_ORIGEN_OPERACION, 'N') != 'N' THEN

        BEGIN
          MERGE INTO CLIENTES C
          USING dual dd
          ON (C.CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND C.CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION))
          WHEN MATCHED THEN
            UPDATE
               SET C.CLI_ECL_MNEMONICO              = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL,
                                                                 'N'),
                                                             'N',
                                                             'ACC',
                                                             'INA') --CLI_ECL_MNEMONICO
                  ,
                   C.CLI_TEC_MNEMONICO              = P_TIPO_CORRESPONDENCIA,
                   C.CLI_FECHA_APERTURA             = SYSDATE,
                   C.CLI_FECHA_ULTIMA_ACTUALIZACION = SYSDATE,
                   C.CLI_USUARIO_ULTIMA_ACTUALIZACI = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             USER,
                                                             P_USUARIO_APERTURA),
                   C.CLI_AUTORIZA_PLAZO             = 'S',
                   C.CLI_AUTORIZA_REPO              = 'S',
                   C.CLI_AUTORIZA_SWAP              = 'S',
                   C.CLI_AUTORIZA_CARRUSEL          = 'S',
                   C.CLI_AUTORIZA_CONTRATO_COMISION = 'S',
                   C.CLI_AUTORIZA_ADMON_VALORES     = 'N',
                   C.CLI_EXCENTO_DXM_FONDOS         = 'N',
                   C.CLI_HABILITADO_INTERNET        = 'I',
                   C.CLI_EXCENTO_IVA                = 'N',
                   C.CLI_TIPO_CLIENTE               = 'C',
                   C.CLI_ULTIMA_OPERACION_EJECUTADA = 'AP',
                   C.CLI_CLAVE_INTERNET             = NULL,
                   C.CLI_NIC                        = NULL,
                   C.CLI_REFERENCIADO               = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_REFERENCIADO),
                   C.CLI_DIRECCION_OFICINA          = P_DIRECCION_OFICINA --*CLI_DIRECCION_OFICINA
                  ,
                   C.CLI_AGE_CODIGO_TRABAJA         = P_CIUDAD_OFICINA --CLI_AGE_CODIGO_TRABAJA
                  ,
                   C.CLI_TELEFONO_OFICINA           = P_TELEFONO_OFICINA --CLI_TELEFONO_OFICINA
                  ,
                   C.CLI_DIRECCION_RESIDENCIA       = P_DIRECCION_RESIDENCIA --*CLI_DIRECCION_RESIDENCIA
                  ,
                   C.CLI_AGE_CODIGO_RESIDE          = V_CIUDAD_RESIDENCIA --*CLI_AGE_CODIGO_RESIDE P_CIUDAD_RESIDENCIA
                  ,
                   C.CLI_TELEFONO_RESIDENCIA        = P_TELEFONO_RESIDENCIA --*CLI_TELEFONO_RESIDENCIA
                   --,C.CLI_DIRECCION_EMAIL                    = P_DIRECCIONEMAIL                                 --*CLI_DIRECCION_EMAIL
                  ,
                   C.CLI_FAX                        = NULL --CLI_FAX
                  ,
                   C.CLI_APARTADO_AEREO             = NULL --CLI_APARTADO_AEREO
                  ,
                   C.CLI_NUMERO_CONTRATO_DCVAL      = V_CONTRATO_DCVAL --CLI_NUMERO_CONTRATO_DCVAL
                  ,
                   C.CLI_NUMERO_CONTRATO_DCV        = NULL --CLI_NUMERO_CONTRATO_DCV
                  ,
                   C.CLI_ECI_MNEMONICO              = P_CODIGO_ESTADO_CIVIL --*CLI_ECI_MNEMONICO
                  ,
                   C.CLI_NAC_MNEMONICO              = P_NACIONALIDAD --*CLI_NAC_MNEMONICO
                  ,
                   C.CLI_FECHA_NACIMIENTO           = TO_DATE(TRIM(P_FECHANACIMIENTO),
                                                              'DD-MM-YYYY') --*CLI_FECHA_NACIMIENTO
                  ,
                   C.CLI_AGE_CODIGO                 = P_CIUDAD_NACIMIENTO --*CLI_AGE_CODIGO
                  ,
                   C.CLI_OCUPACION                  = NULL --CLI_OCUPACION
                  ,
                   C.CLI_ORE_MNEMONICO              = P_ORIGEN_RECURSOS --*CLI_ORE_MNEMONICO
                  ,
                   C.CLI_OTRO_ORIGEN_RECURSOS       = P_OTRO_ORIGEN_RECURSOS --*CLI_OTRO_ORIGEN_RECURSOS
                  ,
                   C.CLI_TITULO_UNIVER              = NULL --CLI_TITULO_UNIVER
                  ,
                   C.CLI_EMPRESA                    = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_NOMBRE_EMPRESA) --CLI_EMPRESA
                  ,
                   C.CLI_CARGO                      = P_CARGO_EMPLEADO --*CLI_CARGO
                  ,
                   C.CLI_RIM_CODIGO                 = NULL --CLI_RIM_CODIGO
                  ,
                   C.CLI_RPA_CODIGO                 = NULL --CLI_RPA_CODIGO
                  ,
                   C.CLI_EXTRANJERO                 = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_EXTRANJERA) --*CLI_EXTRANJERO
                  ,
                   C.CLI_AGE_CODIGO_NACION          = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_CIUDAD_EMPRESA) --*CLI_AGE_CODIGO_NACION
                  ,
                   C.CLI_GRAN_CONTRIBUYENTE         = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'N',
                                                             P_GRAN_CONTRIBUYENTE) --*CLI_GRAN_CONTRIBUYENTE
                  ,
                   C.CLI_AUTORRETENEDOR             = 'N' --CLI_AUTORRETENEDOR
                  ,
                   C.CLI_SUJETO_RTEFTE              = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'S',
                                                             P_SUJETO_RETEFUENTE) --*CLI_SUJETO_RTEFTE
                  ,
                   C.CLI_TEN_CODIGO                 = V_CLI_TEN_CODIGO --*CLI_TEN_CODIGO
                  ,
                   C.CLI_NUMERO_ESCRITURA           = NULL --CLI_NUMERO_ESCRITURA
                  ,
                   C.CLI_FECHA_ESCRITURA            = NULL --CLI_FECHA_ESCRITURA
                  ,
                   C.CLI_NTR_CODIGO                 = NULL --CLI_NTR_CODIGO
                  ,
                   C.CLI_NTR_AGE_CODIGO             = NULL --CLI_NTR_AGE_CODIGO
                  ,
                   C.CLI_REGISTRO_CAMARA            = NULL --CLI_REGISTRO_CAMARA
                  ,
                   C.CLI_FECHA_REGCAMARA            = NULL --CLI_FECHA_REGCAMARA
                  ,
                   C.CLI_ACTIVIDAD_ECONOMICA        = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_ACT_ECONOMICA_PPAL) --*CLI_ACTIVIDAD_ECONOMICA
                  ,
                   C.CLI_DOMICILIO_PRINCIPAL        = NULL --CLI_DOMICILIO_PRINCIPAL
                  ,
                   C.CLI_AGE_CODIGO_PPAL            = V_AGE_CODIGO_PPAL --CLI_AGE_CODIGO_PPAL
                  ,
                   C.CLI_SEC_MNEMONICO              = NULL --CLI_SEC_MNEMONICO
                  ,
                   C.CLI_RECURSOS_ACT_PRINC         = NULL --CLI_RECURSOS_ACT_PRINC
                  ,
                   C.CLI_NUM_ULT_REF_ESCRITURA      = NULL --CLI_NUM_ULT_REF_ESCRITURA
                  ,
                   C.CLI_FEC_ULT_REF_ESCRITURA      = NULL --CLI_FEC_ULT_REF_ESCRITURA
                  ,
                   C.CLI_NTR_CODIGO_ES_MODIFICADA   = NULL --CLI_NTR_CODIGO_ES_MODIFICADA
                  ,
                   C.CLI_NTR_AGE_CODIGO_ES_MODIFICA = NULL --CLI_NTR_AGE_CODIGO_ES_MODIFICA
                  ,
                   C.CLI_CAPITAL_AUTORIZADO         = NULL --CLI_CAPITAL_AUTORIZADO
                  ,
                   C.CLI_CAPITAL_SUSCRITO           = NULL --CLI_CAPITAL_SUSCRITO
                  ,
                   C.CLI_CATEGORIA_CLIENTE_INST     = NULL --CLI_CATEGORIA_                                                 --CLIENTE_INST
                  ,
                   C.CLI_CONTACTO_CLIENTE_INST      = NULL --CLI_CONTACTO_                                                 --CLIENTE_INST
                  ,
                   C.CLI_TELEFONO_CONTACTO_INST     = NULL --CLI_TELEFONO_CONTACTO_INST
                  ,
                   C.CLI_OBSERV_CLIENTE_INST        = NULL --CLI_OBSERV_                                                 --CLIENTE_INST
                  ,
                   C.CLI_FEC_EXPEDICION_CAMARA      = NULL --CLI_FEC_EXPEDICION_CAMARA
                  ,
                   C.CLI_FEC_EXPEDICION_DOC_ID      = TO_DATE(TRIM(P_FECHA_EXP_DOCUMENTO),
                                                              'DD-MM-YYYY') --*CLI_FEC_EXPEDICION_DOC_ID
                  ,
                   C.CLI_AGE_CODIGO_EXP_DOC         = P_CIUDAD_EXP_DOCUMENTO --*CLI_AGE_CODIGO_EXP_DOC
                  ,
                   C.CLI_CODIGO_SEBRA               = NULL --CLI_CODIGO_SEBRA
                  ,
                   C.CLI_CARACTER_ENTIDAD           = V_CLI_CARACTER_ENTIDAD --*CLI_CARACTER_ENTIDAD
                  ,
                   C.CLI_ACT_MNEMONICO              = P_ACTIVIDAD_CLIENTE --*CLI_ACT_MNEMONICO
                  ,
                   C.CLI_FORMULARIO_APERTURA        = P_FORMULARIO_APERTURA --CLI_FORMULARIO_APERTURA
                  ,
                   C.CLI_USUARIO_APERTURA           = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             USER,
                                                             P_USUARIO_APERTURA) --CLI_USUARIO_APERTURA
                  ,
                   C.CLI_FORMULARIO_ACTUALIZACION   = NULL --CLI_FORMULARIO_ACTUALIZACION
                  ,
                   C.CLI_FECHA_ULTIMA_MODIFICACION  = NULL --CLI_FECHA_ULTIMA_MODIFICACION
                  ,
                   C.CLI_USUARIO_ULTIMA_MODIFICA    = NULL --CLI_USUARIO_ULTIMA_MODIFICA
                  ,
                   C.CLI_OTRO_TIPO_EMPRESA          = NULL --CLI_OTRO_TIPO_EMPRESA
                  ,
                   C.CLI_RECURSOS_BIENES_ENTREGAR   = DECODE(P_RECURSOS_ENTREGAR,
                                                             'Dinero',
                                                             'D',
                                                             'Otro',
                                                             'O') --*CLI_RECURSOS_BIENES_ENTREGAR
                  ,
                   C.CLI_OTRO_RECURSOS_BIENES_ENT   = P_OTRO_RECURSO_ENTREGA --*CLI_OTRO_RECURSOS_BIENES_ENT
                  ,
                   C.CLI_OTRO_DETALLE_ACTIVIDAD     = NULL --CLI_OTRO_DETALLE_ACTIVIDAD
                  ,
                   C.CLI_OTRO_TIPO_ENVIO_CORRES     = NULL --CLI_OTRO_TIPO_ENVIO_CORRES
                  ,
                   C.CLI_PAGINA_WEB                 = NULL --CLI_PAGINA_WEB
                  ,
                   C.CLI_FECHA_CONSTITUCION         = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             TO_DATE(TRIM(P_FECHA_CREACION_EMPRESA),
                                                                     'DD-MM-YYYY')) --*CLI_FECHA_CONSTITUCION
                  ,
                   C.CLI_MOI_MNEMONICO              = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL,
                                                                 'N'),
                                                             'N',
                                                             NULL,
                                                             'PRV') --CLI_MOI_MNEMONICO
                  ,
                   C.CLI_RESPUESTA_WEB              = NULL --CLI_RESPUESTA_WEB
                  ,
                   C.CLI_PRW_CODIGO                 = NULL --CLI_PRW_CODIGO
                  ,
                   C.CLI_EXCENTO_REPORTE_EFECTIVO   = NULL --CLI_EXCENTO_REPORTE_EFECTIVO
                  ,
                   C.CLI_RAZON_EXCEPCION            = NULL --CLI_RAZON_EXCEPCION
                  ,
                   C.CLI_AUTORIZA_TRANS_ACH         = 'S' --CLI_AUTORIZA_TRANS_ACH
                  ,
                   C.CLI_ENVIA_REMISION             = NULL --CLI_ENVIA_REMISION
                  ,
                   C.CLI_ENVIA_FACTURA_DIV          = NULL --CLI_ENVIA_FACTURA_DIV
                  ,
                   C.CLI_ADM_PORTAFOLIO_DCVAL       = 'S' --CLI_ADM_PORTAFOLIO_DCVAL
                  ,
                   C.CLI_ADM_PORTAFOLIO_DCV         = 'S' --CLI_ADM_PORTAFOLIO_DCV
                  ,
                   C.CLI_GENERAR_CONSTANCIA         = 'N' --*CLI_GENERAR_CONSTANCIA
                  ,
                   C.CLI_EXPERIENCIA_SECTOR_PUBLICO = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'N',
                                                             P_EXP_SECTOR_PUBLICO) --CLI_EXPERIENCIA_SECTOR_PUBLICO
                  ,
                   C.CLI_CAMPANA_POLITICA           = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'N',
                                                             P_CAMPANA_POLITICA) --CLI_CAMPANA_POLITICA
                  ,
                   C.CLI_MOTIVO_ES_CLIENTE          = 'CP' --CLI_MOTIVO_ES_CLIENTE
                  ,
                   C.CLI_RETENCION_FONDO            = NULL --CLI_RETENCION_FONDO
                  ,
                   C.CLI_SUJETO_RTEFTE_FONDO        = 'S' --CLI_SUJETO_RTEFTE_FONDO
                  ,
                   C.CLI_PROFESIONAL                = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'N',
                                                             P_CATEGORIZACION_CLIENTE) --CLI_PROFESIONAL
                  ,
                   C.CLI_BSC_BCC_MNEMONICO          = V_BCC_CLIENTE --CLI_BSC_BCC_MNEMONICO
                  ,
                   C.CLI_BSC_MNEMONICO              = V_BSC_CLIENTE --CLI_BSC_MNEMONICO
                  ,
                   C.CLI_RADICACION_PROFESIONAL     = NULL --CLI_RADICACION_PROFESIONAL
                  ,
                   C.CLI_CELULAR                    = P_CELULAR --CLI_CELULAR
                  ,
                   C.CLI_UNICA_OPERACION            = 'N' --CLI_UNICA_OPERACION
                  ,
                   C.CLI_PERFIL_RIESGO              = DECODE(UPPER(P_PERFIL_RIESGO),
                                                             'CONSERVADOR',
                                                             10,
                                                             'MODERADO',
                                                             20,
                                                             'ARRIESGADO',
                                                             30) --CLI_PERFIL_RIESGO Moderado = 20
                  ,
                   C.CLI_CONTRATO_MARCO_COMISION    = V_CONTRATO_COMISION --CLI_CONTRATO_MARCO_COMISION
                   --,C.CLI_DIRECCION_EMAIL_ALTERNA            = DECODE(P_ORIGEN,'PLV',NULL,P_DIRECCIONEMAIL_ALTERNO)  --CLI_DIRECCION_EMAIL_ALTERNA
                  ,
                   C.CLI_DECLARA_RENTA              = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'N',
                                                             P_DECLARANTE) --*CLI_DECLARA_RENTA
                  ,
                   C.CLI_RECURSOS_PUBLICOS          = P_ADMIN_REC_PUBLICOS --'N'                                              --CLI_RECURSOS_PUBLICOS
                  ,
                   C.CLI_RECONOCIMIENTO_PUBLICO     = NVL(P_RECONOCIMIENTO_PUBLICO,
                                                          'N') --CLI_RECONOCIMIENTO_PUBLICO
                  ,
                   C.CLI_CAMPO_RECONOCIMIENTO       = P_CAMPO_RECONOCIMIENTO --CLI_CAMPO_RECONOCIMIENTO
                  ,
                   C.CLI_INICIO_COBRO_ADMON_VALORES = NULL --CLI_INICIO_COBRO_ADMON_VALORES
                  ,
                   C.CLI_PAPELETAS_DIARIAS          = NULL --CLI_PAPELETAS_DIARIAS
                  ,
                   C.CLI_ADR_PROGRAM                = 'N' --CLI_ADR_PROGRAM
                  ,
                   C.CLI_FECHA_ULT_MOD_MASIVA       = NULL --CLI_FECHA_ULT_MOD_MASIVA
                  ,
                   C.CLI_CNU_MNEMONICO              = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_CODIGOCIIU) --*CLI_CNU_MNEMONICO
                  ,
                   C.CLI_EXCENTO_REPORTE_DIVISAS    = NULL --CLI_EXCENTO_REPORTE_DIVISAS
                  ,
                   C.CLI_COMPARTIR_INFORMACION      = NULL --CLI_COMPARTIR_INFORMACION
                  ,
                   C.CLI_ENVIO_DE_CORREO_MASIVO     = NULL --CLI_ENVIO_DE_CORREO_MASIVO
                  ,
                   C.CLI_OPX                        = 'N' --CLI_OPX
                  ,
                   C.CLI_FECHA_OPX                  = NULL --CLI_FECHA_OPX
                  ,
                   C.CLI_NO_OPX                     = 'N' --CLI_NO_OPX
                  ,
                   C.CLI_EN_ACTUALIZACION_LINEA     = NULL --CLI_EN_ACTUALIZACION_LINEA
                  ,
                   C.CLI_MONEDA_EXT                 = 'N' --CLI_MONEDA_EXT
                  ,
                   C.CLI_CLSO_MNEMONICO             = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             NULL,
                                                             P_CLASE_SOCIEDAD) --*CLI_CLSO_MNEMONICO
                  ,
                   C.CLI_PSC_MNEMONICO              = P_PROFESION --*CLI_PSC_MNEMONICO
                  ,
                   C.CLI_MIGRADO_DAVIVALORES        = NULL --CLI_MIGRADO_DAVIVALORES
                  ,
                   C.CLI_INSTITUCIONAL_EXTRANJERO   = NULL --CLI_INSTITUCIONAL_EXTRANJERO
                  ,
                   C.CLI_VIGILADO_SFC               = NULL --CLI_VIGILADO_SFC
                  ,
                   C.CLI_BSC_BCC_MNEMONICO_ALT      = V_BCC_ALT --CLI_BSC_BCC_MNEMONICO_ALT
                  ,
                   C.CLI_BSC_MNEMONICO_ALT          = V_BSC_ALT --CLI_BSC_MNEMONICO_ALT
                  ,
                   C.CLI_RIESGO_LAFT                = NULL --CLI_RIESGO_LAFT
                  ,
                   C.CLI_INDICIO_FATCA              = NVL(P_INDICIOS_CRS_FN,
                                                          'N') --CLI_INDICIO_FATCA
                  ,
                   C.CLI_BANCA_PRIVADA              = DECODE(P_ORIGEN,
                                                             'PLV',
                                                             'N',
                                                             P_BANCA_PRIVADA) --CLI_BANCA_PRIVADA
                  ,
                   C.CLI_FORMULARIO_VINCULACION     = P_NUMERO_FORMULARIO_VIN --CLI_FORMULARIO_VINCULACION
                  ,
                   C.CLI_RECONO_PUBLICA_PEP         = P_RECONO_PUBLICA_PEP --CLI_RECONO_PUBLICA_PEP
                  ,
                   C.CLI_RECONO_POLITICA_PEP        = P_RECONO_POLITICA_PEP --CLI_RECONO_POLITICA_PEP
                  ,
                   C.CLI_CARGO_PEP                  = P_CARGO_PEP --CLI_CARGO_PEP
                  ,
                   C.CLI_FECHA_CARGO_PEP            = TO_DATE(TRIM(P_FECHA_CARGO_PEP),
                                                              'DD-MM-YYYY') --CLI_FECHA_CARGO_PEP
                  ,
                   C.CLI_FECHA_DESVINCULA_PEP       = TO_DATE(TRIM(P_FECHA_DESVINCULA_PEP),
                                                              'DD-MM-YYYY') --CLI_FECHA_DESVINCULA_PEP
                  ,
                   C.CLI_REP_LEGAL_PEP              = P_REP_LEGAL_PEP --CLI_REP_LEGAL_PEP
                  ,
                   C.CLI_TIENE_CONSANGUI_PEP        = V_TIENE_CONSANGUI_PEP --CLI_TIENE_CONSANGUI_PEP
                  ,
                   C.CLI_GRADO_CONSANGUI_PEP        = P_GRADO_CONSANGUI_PEP --CLI_GRADO_CONSANGUI_PEP
                  ,
                   C.CLI_NOMBRE_FAMILIAR_PEP        = P_NOMBRE_FAMILIAR_PEP --CLI_NOMBRE_FAMILIAR_PEP
                  ,
                   C.CLI_PRIMER_APELLIDO_PEP        = P_PRIMER_APELLIDO_PEP --CLI_PRIMER_APELLIDO_PEP
                  ,
                   C.CLI_SEGUNDO_APELLIDO_PEP       = P_SEGUNDO_APELLIDO_PEP --CLI_SEGUNDO_APELLIDO_PEP
                  ,
                   C.CLI_ESTADO_VINCULACION         = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL,
                                                                 'N'),
                                                             'N',
                                                             NULL,
                                                             'PRV') --CLI_ESTADO_VINCULACION
                  ,
                   C.CLI_CNU_MNEMONICO_SEC          = P_CIIU_SECUNDARIO,
                   C.CLI_MAN_REC_PUB                = P_RECURSOS_PUBLICOS,
                   C.CLI_FECHA_VENCIMIENTO          = TO_DATE(TRIM(P_FECHA_VEN_ID),
                                                              'DD-MM-YYYY'),
                   C.CLI_CUENTA_FIN_EXTRA           = P_CUENTASFINEXTRA,
                   C.CLI_ES_FIDEICOMI               = P_FIDEICOMITENTE,
                   C.CLI_NOMBRE_FIDEICOMISO         = P_NOMBREFIDEICOMISO,
                   C.CLI_NIT_FIDEICOMISO            = P_NITFIDEICOMISO,
                   C.CLI_FIDU_ADMIN_FIDEICOMISO     = P_FIDUADMINFIDEICOMISO,
                   c.CLI_PROPOSITO_COMISIONISTA     = P_PROPOSITOCOMISIONISTA,
                   c.CLI_MONTO_INICIAL_INVERSION    = P_MONTOAPROXINVERSION,
                   C.CLI_ORG_INTERNA_PEP            = P_ORG_INTERNA_PEP,
                   c.CLI_GRADO_CONSANGUI_PEP2       = P_GRADO_CONSANGUI_PEP2,
                   c.CLI_GRADO_CONSANGUI_PEP3       = P_GRADO_CONSANGUI_PEP3,
                   c.CLI_NOMBRE_FAMILIAR_PEP2       = P_NOMBRE_FAMILIAR_PEP2,
                   c.CLI_NOMBRE_FAMILIAR_PEP3       = P_NOMBRE_FAMILIAR_PEP3,
                   c.CLI_NUM_ID_FAMILIAR_PEP2       = P_NUM_ID_FAMILIAR_PEP2,
                   c.CLI_NUM_ID_FAMILIAR_PEP3       = P_NUM_ID_FAMILIAR_PEP3,
                   c.CLI_PRIMER_APELLIDO_PEP2       = P_PRIMER_APELLIDO_PEP2,
                   c.CLI_PRIMER_APELLIDO_PEP3       = P_PRIMER_APELLIDO_PEP3,
                   c.CLI_SEGUNDO_APELLIDO_PEP2      = P_SEGUNDO_APELLIDO_PEP2,
                   c.CLI_SEGUNDO_APELLIDO_PEP3      = P_SEGUNDO_APELLIDO_PEP3,
                   c.CLI_TID_COD_FAMILIAR_PEP2      = P_TID_COD_FAMILIAR_PEP2,
                   c.CLI_TID_COD_FAMILIAR_PEP3      = P_TID_COD_FAMILIAR_PEP3
          WHEN NOT MATCHED THEN
            INSERT
              (C.CLI_PER_NUM_IDEN,
               C.CLI_PER_TID_CODIGO,
               C.CLI_ECL_MNEMONICO,
               C.CLI_TEC_MNEMONICO,
               C.CLI_FECHA_APERTURA,
               C.CLI_FECHA_ULTIMA_ACTUALIZACION,
               C.CLI_USUARIO_ULTIMA_ACTUALIZACI,
               C.CLI_AUTORIZA_PLAZO,
               C.CLI_AUTORIZA_REPO,
               C.CLI_AUTORIZA_SWAP,
               C.CLI_AUTORIZA_CARRUSEL,
               C.CLI_AUTORIZA_CONTRATO_COMISION,
               C.CLI_AUTORIZA_ADMON_VALORES,
               C.CLI_EXCENTO_DXM_FONDOS,
               C.CLI_HABILITADO_INTERNET,
               C.CLI_EXCENTO_IVA,
               C.CLI_TIPO_CLIENTE,
               C.CLI_ULTIMA_OPERACION_EJECUTADA,
               C.CLI_CLAVE_INTERNET,
               C.CLI_NIC,
               C.CLI_REFERENCIADO,
               C.CLI_DIRECCION_OFICINA,
               C.CLI_AGE_CODIGO_TRABAJA,
               C.CLI_TELEFONO_OFICINA,
               C.CLI_DIRECCION_RESIDENCIA,
               C.CLI_AGE_CODIGO_RESIDE,
               C.CLI_TELEFONO_RESIDENCIA
               --,C.CLI_DIRECCION_EMAIL
              ,
               C.CLI_FAX,
               C.CLI_APARTADO_AEREO,
               C.CLI_NUMERO_CONTRATO_DCVAL,
               C.CLI_NUMERO_CONTRATO_DCV,
               C.CLI_ECI_MNEMONICO,
               C.CLI_NAC_MNEMONICO,
               C.CLI_FECHA_NACIMIENTO,
               C.CLI_AGE_CODIGO,
               C.CLI_OCUPACION,
               C.CLI_ORE_MNEMONICO,
               C.CLI_OTRO_ORIGEN_RECURSOS,
               C.CLI_TITULO_UNIVER,
               C.CLI_EMPRESA,
               C.CLI_CARGO,
               C.CLI_RIM_CODIGO,
               C.CLI_RPA_CODIGO,
               C.CLI_EXTRANJERO,
               C.CLI_AGE_CODIGO_NACION,
               C.CLI_GRAN_CONTRIBUYENTE,
               C.CLI_AUTORRETENEDOR,
               C.CLI_SUJETO_RTEFTE,
               C.CLI_TEN_CODIGO,
               C.CLI_NUMERO_ESCRITURA,
               C.CLI_FECHA_ESCRITURA,
               C.CLI_NTR_CODIGO,
               C.CLI_NTR_AGE_CODIGO,
               C.CLI_REGISTRO_CAMARA,
               C.CLI_FECHA_REGCAMARA,
               C.CLI_ACTIVIDAD_ECONOMICA,
               C.CLI_DOMICILIO_PRINCIPAL,
               C.CLI_AGE_CODIGO_PPAL,
               C.CLI_SEC_MNEMONICO,
               C.CLI_RECURSOS_ACT_PRINC,
               C.CLI_NUM_ULT_REF_ESCRITURA,
               C.CLI_FEC_ULT_REF_ESCRITURA,
               C.CLI_NTR_CODIGO_ES_MODIFICADA,
               C.CLI_NTR_AGE_CODIGO_ES_MODIFICA,
               C.CLI_CAPITAL_AUTORIZADO,
               C.CLI_CAPITAL_SUSCRITO,
               C.CLI_CATEGORIA_CLIENTE_INST,
               C.CLI_CONTACTO_CLIENTE_INST,
               C.CLI_TELEFONO_CONTACTO_INST,
               C.CLI_OBSERV_CLIENTE_INST,
               C.CLI_FEC_EXPEDICION_CAMARA,
               C.CLI_FEC_EXPEDICION_DOC_ID,
               C.CLI_AGE_CODIGO_EXP_DOC,
               C.CLI_CODIGO_SEBRA,
               C.CLI_CARACTER_ENTIDAD,
               C.CLI_ACT_MNEMONICO,
               C.CLI_FORMULARIO_APERTURA,
               C.CLI_USUARIO_APERTURA,
               C.CLI_FORMULARIO_ACTUALIZACION,
               C.CLI_FECHA_ULTIMA_MODIFICACION,
               C.CLI_USUARIO_ULTIMA_MODIFICA,
               C.CLI_OTRO_TIPO_EMPRESA,
               C.CLI_RECURSOS_BIENES_ENTREGAR,
               C.CLI_OTRO_RECURSOS_BIENES_ENT,
               C.CLI_OTRO_DETALLE_ACTIVIDAD,
               C.CLI_OTRO_TIPO_ENVIO_CORRES,
               C.CLI_PAGINA_WEB,
               C.CLI_FECHA_CONSTITUCION,
               C.CLI_MOI_MNEMONICO,
               C.CLI_RESPUESTA_WEB,
               C.CLI_PRW_CODIGO,
               C.CLI_EXCENTO_REPORTE_EFECTIVO,
               C.CLI_RAZON_EXCEPCION,
               C.CLI_AUTORIZA_TRANS_ACH,
               C.CLI_ENVIA_REMISION,
               C.CLI_ENVIA_FACTURA_DIV,
               C.CLI_ADM_PORTAFOLIO_DCVAL,
               C.CLI_ADM_PORTAFOLIO_DCV,
               C.CLI_GENERAR_CONSTANCIA,
               C.CLI_EXPERIENCIA_SECTOR_PUBLICO,
               C.CLI_CAMPANA_POLITICA,
               C.CLI_MOTIVO_ES_CLIENTE,
               C.CLI_RETENCION_FONDO,
               C.CLI_SUJETO_RTEFTE_FONDO,
               C.CLI_PROFESIONAL,
               C.CLI_BSC_BCC_MNEMONICO,
               C.CLI_BSC_MNEMONICO,
               C.CLI_RADICACION_PROFESIONAL,
               C.CLI_CELULAR,
               C.CLI_UNICA_OPERACION,
               C.CLI_PERFIL_RIESGO,
               C.CLI_CONTRATO_MARCO_COMISION
               --,C.CLI_DIRECCION_EMAIL_ALTERNA
              ,
               C.CLI_DECLARA_RENTA,
               C.CLI_RECURSOS_PUBLICOS,
               C.CLI_RECONOCIMIENTO_PUBLICO,
               C.CLI_CAMPO_RECONOCIMIENTO,
               C.CLI_INICIO_COBRO_ADMON_VALORES,
               C.CLI_PAPELETAS_DIARIAS,
               C.CLI_ADR_PROGRAM,
               C.CLI_FECHA_ULT_MOD_MASIVA,
               C.CLI_CNU_MNEMONICO,
               C.CLI_EXCENTO_REPORTE_DIVISAS,
               C.CLI_COMPARTIR_INFORMACION,
               C.CLI_ENVIO_DE_CORREO_MASIVO,
               C.CLI_OPX,
               C.CLI_FECHA_OPX,
               C.CLI_NO_OPX,
               C.CLI_EN_ACTUALIZACION_LINEA,
               C.CLI_MONEDA_EXT,
               C.CLI_CLSO_MNEMONICO,
               C.CLI_PSC_MNEMONICO,
               C.CLI_MIGRADO_DAVIVALORES,
               C.CLI_INSTITUCIONAL_EXTRANJERO,
               C.CLI_VIGILADO_SFC,
               C.CLI_BSC_BCC_MNEMONICO_ALT,
               C.CLI_BSC_MNEMONICO_ALT,
               C.CLI_RIESGO_LAFT,
               C.CLI_INDICIO_FATCA,
               C.CLI_BANCA_PRIVADA,
               C.CLI_FORMULARIO_VINCULACION,
               C.CLI_RECONO_PUBLICA_PEP,
               C.CLI_RECONO_POLITICA_PEP,
               C.CLI_CARGO_PEP,
               C.CLI_FECHA_CARGO_PEP,
               C.CLI_FECHA_DESVINCULA_PEP,
               C.CLI_REP_LEGAL_PEP,
               C.CLI_TIENE_CONSANGUI_PEP,
               C.CLI_GRADO_CONSANGUI_PEP,
               C.CLI_NOMBRE_FAMILIAR_PEP,
               C.CLI_PRIMER_APELLIDO_PEP,
               C.CLI_SEGUNDO_APELLIDO_PEP,
               C.CLI_ESTADO_VINCULACION,
               C.CLI_CNU_MNEMONICO_SEC,
               C.CLI_MAN_REC_PUB,
               C.CLI_FECHA_VENCIMIENTO,
               C.CLI_CUENTA_FIN_EXTRA,
               C.CLI_ES_FIDEICOMI,
               C.CLI_NOMBRE_FIDEICOMISO,
               C.CLI_NIT_FIDEICOMISO,
               C.CLI_FIDU_ADMIN_FIDEICOMISO,
               C.CLI_PROPOSITO_COMISIONISTA,
               c.CLI_MONTO_INICIAL_INVERSION --C.CLI_MONTO_APROX_INVERSION
              ,
               C.CLI_ORG_INTERNA_PEP,
               c.CLI_GRADO_CONSANGUI_PEP2,
               c.CLI_GRADO_CONSANGUI_PEP3,
               c.CLI_NOMBRE_FAMILIAR_PEP2,
               c.CLI_NOMBRE_FAMILIAR_PEP3,
               c.CLI_NUM_ID_FAMILIAR_PEP2,
               c.CLI_NUM_ID_FAMILIAR_PEP3,
               c.CLI_PRIMER_APELLIDO_PEP2,
               c.CLI_PRIMER_APELLIDO_PEP3,
               c.CLI_SEGUNDO_APELLIDO_PEP2,
               c.CLI_SEGUNDO_APELLIDO_PEP3,
               c.CLI_TID_COD_FAMILIAR_PEP2,
               c.CLI_TID_COD_FAMILIAR_PEP3)
            VALUES
              (TRIM(P_NUMERO_IDENTIFICACION) --*CLI_PER_NUM_IDEN
              ,
               TRIM(P_TIPO_IDENTIFICACION) --*CLI_PER_TID_CODIGO
              ,
               DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                      'N',
                      'ACC',
                      'INA') --CLI_ECL_MNEMONICO
              ,
               P_TIPO_CORRESPONDENCIA --CLI_TEC_MNEMONICO
              ,
               SYSDATE --CLI_FECHA_APERTURA
              ,
               SYSDATE --CLI_FECHA_ULTIMA_ACTUALIZACION
              ,
               DECODE(P_ORIGEN, 'PLV', USER, P_USUARIO_APERTURA) --CLI_USUARIO_ULTIMA_ACTUALIZACI
              ,
               'S' --CLI_AUTORIZA_PLAZO
              ,
               'S' --CLI_AUTORIZA_REPO
              ,
               'S' --CLI_AUTORIZA_SWAP
              ,
               'S' --CLI_AUTORIZA_CARRUSEL
              ,
               'S' --CLI_AUTORIZA_CONTRATO_COMISION
              ,
               'N' --CLI_AUTORIZA_ADMON_VALORES
              ,
               'N' --CLI_EXCENTO_DXM_FONDOS
              ,
               'I' --CLI_HABILITADO_INTERNET
              ,
               'N' --CLI_EXCENTO_IVA
              ,
               'C' --CLI_TIPO_CLIENTE --CLIENTE
              ,
               'AP' --CLI_ULTIMA_OPERACION_EJECUTADA
              ,
               NULL --CLI_CLAVE_INTERNET
              ,
               NULL --CLI_NIC
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_REFERENCIADO) --*CLI_REFERENCIADO
              ,
               P_DIRECCION_OFICINA --*CLI_DIRECCION_OFICINA
              ,
               P_CIUDAD_OFICINA --CLI_AGE_CODIGO_TRABAJA
              ,
               P_TELEFONO_OFICINA --CLI_TELEFONO_OFICINA
              ,
               P_DIRECCION_RESIDENCIA --*CLI_DIRECCION_RESIDENCIA
              ,
               V_CIUDAD_RESIDENCIA --*CLI_AGE_CODIGO_RESIDE P_CIUDAD_RESIDENCIA
              ,
               P_TELEFONO_RESIDENCIA --*CLI_TELEFONO_RESIDENCIA
               --,P_DIRECCIONEMAIL                                 --*CLI_DIRECCION_EMAIL
              ,
               NULL --CLI_FAX
              ,
               NULL --CLI_APARTADO_AEREO
              ,
               V_CONTRATO_DCVAL --CLI_NUMERO_CONTRATO_DCVAL
              ,
               NULL --CLI_NUMERO_CONTRATO_DCV
              ,
               P_CODIGO_ESTADO_CIVIL --*CLI_ECI_MNEMONICO
              ,
               P_NACIONALIDAD --*CLI_NAC_MNEMONICO
              ,
               TO_DATE(TRIM(P_FECHANACIMIENTO), 'DD-MM-YYYY') --*CLI_FECHA_NACIMIENTO
              ,
               P_CIUDAD_NACIMIENTO --*CLI_AGE_CODIGO
              ,
               NULL --CLI_OCUPACION
              ,
               P_ORIGEN_RECURSOS --*CLI_ORE_MNEMONICO
              ,
               P_OTRO_ORIGEN_RECURSOS --*CLI_OTRO_ORIGEN_RECURSOS
              ,
               NULL --CLI_TITULO_UNIVER
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_NOMBRE_EMPRESA) --CLI_EMPRESA
              ,
               P_CARGO_EMPLEADO --*CLI_CARGO
              ,
               NULL --CLI_RIM_CODIGO
              ,
               NULL --CLI_RPA_CODIGO
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_EXTRANJERA) --*CLI_EXTRANJERO
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_CIUDAD_EMPRESA) --*CLI_AGE_CODIGO_NACION
              ,
               DECODE(P_ORIGEN, 'PLV', 'N', P_GRAN_CONTRIBUYENTE) --*CLI_GRAN_CONTRIBUYENTE
              ,
               'N' --CLI_AUTORRETENEDOR
              ,
               DECODE(P_ORIGEN, 'PLV', 'S', P_SUJETO_RETEFUENTE) --*CLI_SUJETO_RTEFTE
              ,
               V_CLI_TEN_CODIGO --*CLI_TEN_CODIGO
              ,
               NULL --CLI_NUMERO_ESCRITURA
              ,
               NULL --CLI_FECHA_ESCRITURA
              ,
               NULL --CLI_NTR_CODIGO
              ,
               NULL --CLI_NTR_AGE_CODIGO
              ,
               NULL --CLI_REGISTRO_CAMARA
              ,
               NULL --CLI_FECHA_REGCAMARA
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_ACT_ECONOMICA_PPAL) --*CLI_ACTIVIDAD_ECONOMICA
              ,
               NULL --CLI_DOMICILIO_PRINCIPAL
              ,
               V_AGE_CODIGO_PPAL --CLI_AGE_CODIGO_PPAL
              ,
               NULL --CLI_SEC_MNEMONICO
              ,
               NULL --CLI_RECURSOS_ACT_PRINC
              ,
               NULL --CLI_NUM_ULT_REF_ESCRITURA
              ,
               NULL --CLI_FEC_ULT_REF_ESCRITURA
              ,
               NULL --CLI_NTR_CODIGO_ES_MODIFICADA
              ,
               NULL --CLI_NTR_AGE_CODIGO_ES_MODIFICA
              ,
               NULL --CLI_CAPITAL_AUTORIZADO
              ,
               NULL --CLI_CAPITAL_SUSCRITO
              ,
               NULL --CLI_CATEGORIA_                                                 --CLIENTE_INST
              ,
               NULL --CLI_CONTACTO_                                                 --CLIENTE_INST
              ,
               NULL --CLI_TELEFONO_CONTACTO_INST
              ,
               NULL --CLI_OBSERV_                                                 --CLIENTE_INST
              ,
               NULL --CLI_FEC_EXPEDICION_CAMARA
              ,
               TO_DATE(TRIM(P_FECHA_EXP_DOCUMENTO), 'DD-MM-YYYY') --*CLI_FEC_EXPEDICION_DOC_ID
              ,
               P_CIUDAD_EXP_DOCUMENTO --*CLI_AGE_CODIGO_EXP_DOC
              ,
               NULL --CLI_CODIGO_SEBRA
              ,
               V_CLI_CARACTER_ENTIDAD --*CLI_CARACTER_ENTIDAD
              ,
               P_ACTIVIDAD_CLIENTE --*CLI_ACT_MNEMONICO
              ,
               P_FORMULARIO_APERTURA --CLI_FORMULARIO_APERTURA
              ,
               DECODE(P_ORIGEN, 'PLV', USER, P_USUARIO_APERTURA) --CLI_USUARIO_APERTURA
              ,
               NULL --CLI_FORMULARIO_ACTUALIZACION
              ,
               NULL --CLI_FECHA_ULTIMA_MODIFICACION
              ,
               NULL --CLI_USUARIO_ULTIMA_MODIFICA
              ,
               NULL --CLI_OTRO_TIPO_EMPRESA
              ,
               DECODE(P_RECURSOS_ENTREGAR, 'Dinero', 'D', 'Otro', 'O') --*CLI_RECURSOS_BIENES_ENTREGAR
              ,
               P_OTRO_RECURSO_ENTREGA --*CLI_OTRO_RECURSOS_BIENES_ENT
              ,
               NULL --CLI_OTRO_DETALLE_ACTIVIDAD
              ,
               NULL --CLI_OTRO_TIPO_ENVIO_CORRES
              ,
               NULL --CLI_PAGINA_WEB
              ,
               DECODE(P_ORIGEN,
                      'PLV',
                      NULL,
                      TO_DATE(TRIM(P_FECHA_CREACION_EMPRESA), 'DD-MM-YYYY')) --*CLI_FECHA_CONSTITUCION
              ,
               DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                      'N',
                      NULL,
                      'PRV') --CLI_MOI_MNEMONICO
              ,
               NULL --CLI_RESPUESTA_WEB
              ,
               NULL --CLI_PRW_CODIGO
              ,
               NULL --CLI_EXCENTO_REPORTE_EFECTIVO
              ,
               NULL --CLI_RAZON_EXCEPCION
              ,
               'S' --CLI_AUTORIZA_TRANS_ACH
              ,
               NULL --CLI_ENVIA_REMISION
              ,
               NULL --CLI_ENVIA_FACTURA_DIV
              ,
               'S' --CLI_ADM_PORTAFOLIO_DCVAL
              ,
               'S' --CLI_ADM_PORTAFOLIO_DCV
              ,
               'N' --*CLI_GENERAR_CONSTANCIA
              ,
               DECODE(P_ORIGEN, 'PLV', 'N', P_EXP_SECTOR_PUBLICO) --CLI_EXPERIENCIA_SECTOR_PUBLICO
              ,
               DECODE(P_ORIGEN, 'PLV', 'N', P_CAMPANA_POLITICA) --CLI_CAMPANA_POLITICA
              ,
               'CP' --CLI_MOTIVO_ES_CLIENTE
              ,
               NULL --CLI_RETENCION_FONDO
              ,
               'S' --CLI_SUJETO_RTEFTE_FONDO
              ,
               DECODE(P_ORIGEN, 'PLV', 'N', P_CATEGORIZACION_CLIENTE) --CLI_PROFESIONAL
              ,
               V_BCC_CLIENTE --CLI_BSC_BCC_MNEMONICO
              ,
               V_BSC_CLIENTE --CLI_BSC_MNEMONICO
              ,
               NULL --CLI_RADICACION_PROFESIONAL
              ,
               P_CELULAR --CLI_CELULAR
              ,
               'N' --CLI_UNICA_OPERACION
              ,
               DECODE(UPPER(P_PERFIL_RIESGO),
                      'CONSERVADOR',
                      10,
                      'MODERADO',
                      20,
                      'ARRIESGADO',
                      30) --CLI_PERFIL_RIESGO Moderado = 20
              ,
               V_CONTRATO_COMISION --CLI_CONTRATO_MARCO_COMISION
               --,DECODE(P_ORIGEN,'PLV',NULL,P_DIRECCIONEMAIL_ALTERNO)  --CLI_DIRECCION_EMAIL_ALTERNA
              ,
               DECODE(P_ORIGEN, 'PLV', 'N', P_DECLARANTE) --*CLI_DECLARA_RENTA
              ,
               P_ADMIN_REC_PUBLICOS --'N'                                              --CLI_RECURSOS_PUBLICOS
              ,
               NVL(P_RECONOCIMIENTO_PUBLICO, 'N') --CLI_RECONOCIMIENTO_PUBLICO
              ,
               P_CAMPO_RECONOCIMIENTO --CLI_CAMPO_RECONOCIMIENTO
              ,
               NULL --CLI_INICIO_COBRO_ADMON_VALORES
              ,
               NULL --CLI_PAPELETAS_DIARIAS
              ,
               'N' --CLI_ADR_PROGRAM
              ,
               NULL --CLI_FECHA_ULT_MOD_MASIVA
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_CODIGOCIIU) --*CLI_CNU_MNEMONICO
              ,
               NULL --CLI_EXCENTO_REPORTE_DIVISAS
              ,
               NULL --CLI_COMPARTIR_INFORMACION
              ,
               NULL --CLI_ENVIO_DE_CORREO_MASIVO
              ,
               'N' --CLI_OPX
              ,
               NULL --CLI_FECHA_OPX
              ,
               'N' --CLI_NO_OPX
              ,
               NULL --CLI_EN_ACTUALIZACION_LINEA
              ,
               'N' --CLI_MONEDA_EXT
              ,
               DECODE(P_ORIGEN, 'PLV', NULL, P_CLASE_SOCIEDAD) --*CLI_CLSO_MNEMONICO
              ,
               P_PROFESION --*CLI_PSC_MNEMONICO
              ,
               NULL --CLI_MIGRADO_DAVIVALORES
              ,
               NULL --CLI_INSTITUCIONAL_EXTRANJERO
              ,
               NULL --CLI_VIGILADO_SFC
              ,
               V_BCC_ALT --CLI_BSC_BCC_MNEMONICO_ALT
              ,
               V_BSC_ALT --CLI_BSC_MNEMONICO_ALT
              ,
               NULL --CLI_RIESGO_LAFT
              ,
               NVL(P_INDICIOS_CRS_FN, 'N') --CLI_INDICIO_FATCA
              ,
               DECODE(P_ORIGEN, 'PLV', 'N', P_BANCA_PRIVADA) --CLI_BANCA_PRIVADA
              ,
               P_NUMERO_FORMULARIO_VIN --CLI_FORMULARIO_VINCULACION
              ,
               P_RECONO_PUBLICA_PEP --CLI_RECONO_PUBLICA_PEP
              ,
               P_RECONO_POLITICA_PEP --CLI_RECONO_POLITICA_PEP
              ,
               P_CARGO_PEP --CLI_CARGO_PEP
              ,
               TO_DATE(TRIM(P_FECHA_CARGO_PEP), 'DD-MM-YYYY') --CLI_FECHA_CARGO_PEP
              ,
               TO_DATE(TRIM(P_FECHA_DESVINCULA_PEP), 'DD-MM-YYYY') --CLI_FECHA_DESVINCULA_PEP
              ,
               P_REP_LEGAL_PEP --CLI_REP_LEGAL_PEP
              ,
               V_TIENE_CONSANGUI_PEP --CLI_TIENE_CONSANGUI_PEP
              ,
               P_GRADO_CONSANGUI_PEP --CLI_GRADO_CONSANGUI_PEP
              ,
               P_NOMBRE_FAMILIAR_PEP --CLI_NOMBRE_FAMILIAR_PEP
              ,
               P_PRIMER_APELLIDO_PEP --CLI_PRIMER_APELLIDO_PEP
              ,
               P_SEGUNDO_APELLIDO_PEP --CLI_SEGUNDO_APELLIDO_PEP
              ,
               DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                      'N',
                      NULL,
                      'PRV') --CLI_ESTADO_VINCULACION
              ,
               P_CIIU_SECUNDARIO --CLI_CNU_MNEMONICO_SEC
              ,
               P_RECURSOS_PUBLICOS --CLI_MAN_REC_PUB
              ,
               TO_DATE(TRIM(P_FECHA_VEN_ID), 'DD-MM-YYYY') --CLI_FECHA_VENCIMIENTO
              ,
               P_CUENTASFINEXTRA,
               P_FIDEICOMITENTE,
               P_NOMBREFIDEICOMISO,
               P_NITFIDEICOMISO,
               P_FIDUADMINFIDEICOMISO,
               P_PROPOSITOCOMISIONISTA,
               P_MONTOAPROXINVERSION,
               P_ORG_INTERNA_PEP,
               P_GRADO_CONSANGUI_PEP2,
               P_GRADO_CONSANGUI_PEP3,
               P_NOMBRE_FAMILIAR_PEP2,
               P_NOMBRE_FAMILIAR_PEP3,
               P_NUM_ID_FAMILIAR_PEP2,
               P_NUM_ID_FAMILIAR_PEP3,
               P_PRIMER_APELLIDO_PEP2,
               P_PRIMER_APELLIDO_PEP3,
               P_SEGUNDO_APELLIDO_PEP2,
               P_SEGUNDO_APELLIDO_PEP3,
               P_TID_COD_FAMILIAR_PEP2,
               P_TID_COD_FAMILIAR_PEP3);

          IF SQL%ROWCOUNT = 0 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('Error creando merge cliente:' ||
                             TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                             TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                             SQLERRM);

          END IF;

          IF P_DIRECCIONEMAIL IS NOT NULL OR P_DIRECCIONEMAIL != '' THEN

            BEGIN
              P_CORREOS_COEASY.P_INSERTA_CORREO_CLI(P_ID      => TRIM(P_TIPO_IDENTIFICACION),
                                                    P_NIT     => TRIM(P_NUMERO_IDENTIFICACION),
                                                    P_TIPO    => 'P',
                                                    P_CORREOS => P_DIRECCIONEMAIL);
            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando cliente correo pincipal - ' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
            END;

          END IF;

          IF P_ORIGEN <> 'PLV' AND (P_DIRECCIONEMAIL_ALTERNO IS NOT NULL OR
             P_DIRECCIONEMAIL_ALTERNO != '') THEN

            BEGIN
              P_CORREOS_COEASY.P_INSERTA_CORREO_CLI(P_ID      => TRIM(P_TIPO_IDENTIFICACION),
                                                    P_NIT     => TRIM(P_NUMERO_IDENTIFICACION),
                                                    P_TIPO    => 'S',
                                                    P_CORREOS => P_DIRECCIONEMAIL_ALTERNO);
            EXCEPTION
              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando cliente correo alterno - ' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
            END;

          END IF;
        END;
      END IF;
      --- aca ja
      IF P_PROPOSITOCOMISIONISTA IS NOT NULL THEN

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (TRIM(P_NUMERO_IDENTIFICACION) --*CLI_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_IDENTIFICACION),
           5,
           P_PROPOSITOCOMISIONISTA);

      END IF;
      ---

      /* CREACION DE ESTADOS ECONOMICOS*/
      BEGIN
        INSERT INTO ESTADOS_ECONOMICOS
          (EEC_FECHA,
           EEC_CLI_PER_NUM_IDEN,
           EEC_CLI_PER_TID_CODIGO,
           EEC_INGRESO_MENSUAL,
           EEC_RIM_CODIGO,
           EEC_ACTIVOS,
           EEC_PATRIMONIO,
           EEC_UTILIDAD_PROMEDIO,
           EEC_PASIVO,
           EEC_EGRESOS_MENSUALES,
           EEC_EGRESOS_MENSUALES_NO_OPERA,
           EEC_INGRESOS_MENSUALES_NO_OPER,
           EEC_ACT_CORRIENTE,
           EEC_PAS_CORRIENTE,
           EEC_COSTOS_VENTAS,
           EEC_GASTOS_OPERA,
           EEC_MES_EST_FINAN,
           EEC_ANO_EST_FINAN)
        VALUES
          (SYSDATE ---EEC_FECHA
          ,
           TRIM(P_NUMERO_IDENTIFICACION) --EEC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_IDENTIFICACION) --EEC_CLI_PER_TID_CODIGO
          ,
           NVL(P_ING_MEN_OPERACIONALES, 0) --EEC_INGRESO_MENSUAL
          ,
           NULL --EEC_RIM_CODIGO
          ,
           NVL(P_ACTIVOS, 0) --EEC_ACTIVOS
          ,
           (NVL(P_ACTIVOS, 0) - NVL(P_PASIVOS, 0)) --EEC_PATRIMONIO
          ,
           NULL --EEC_UTILIDAD_PROMEDIO
          ,
           NVL(P_PASIVOS, 0) --EEC_PASIVO
          ,
           NVL(P_EGR_MEN_OPERACIONALES, 0) --EEC_EGRESOS_MENSUALES
          ,
           NVL(P_EGR_MEN_NO_OPERACIONA, 0) --EEC_EGRESOS_MENSUALES_NO_OPERA
          ,
           NVL(P_EGR_MEN_NO_OPERACIONA, 0) --EEC_INGRESOS_MENSUALES_NO_OPER
          ,
           NULL --EEC_ACT_CORRIENTE
          ,
           NULL --EEC_PAS_CORRIENTE
          ,
           NULL --EEC_COSTOS_VENTAS
          ,
           NULL --EEC_GASTOS_OPERA
          ,
           NULL --EEC_MES_EST_FINAN
          ,
           NULL --EEC_ANO_EST_FINAN
           );

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRORES             := V_ERRORES + 1;
          P_FORMULARIO_APERTURA := NULL;
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          V_ERRORES             := V_ERRORES + 1;
          P_FORMULARIO_APERTURA := NULL;
          P_CAB.CrearError('Error creando estados economicos.');
          RAISE V_ERROR_CREACION;
      END;

      IF P_ORIGEN = 'PLV' THEN
        /* PERSONAS RELACIONADAS */
        BEGIN
          INSERT INTO PERSONAS_RELACIONADAS
            (RLC_CLI_PER_NUM_IDEN,
             RLC_CLI_PER_TID_CODIGO,
             RLC_PER_NUM_IDEN,
             RLC_PER_TID_CODIGO,
             RLC_ROL_CODIGO,
             RLC_ESTADO,
             RLC_FECHA_CAMBIO_ESTADO,
             RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
             RLC_ETRADE,
             RLC_CELULAR,
             RLC_DIRECCION_EMAIL)
          VALUES
            (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
            ,
             TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
            ,
             TRIM(P_NUMERO_IDENTIFICACION) --RLC_PER_NUM_IDEN
            ,
             TRIM(P_TIPO_IDENTIFICACION) --RLC_PER_TID_CODIGO
            ,
             1 --RLC_ROL_CODIGO: ORDENANTE
            ,
             'A' --R_RLC.RLC_ESTADO
            ,
             SYSDATE --RLC_FECHA_CAMBIO_ESTADO
            ,
             USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
            ,
             'S' --RLC_ETRADE
            ,
             P_CELULAR --RLC_CELULAR
            ,
             P_DIRECCIONEMAIL --RLC_DIRECCION_EMAIL
             );

          IF SQL%ROWCOUNT = 0 THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('Error creando persona relacionada 1.- ' ||
                             TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                             TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                             SQLERRM);
          END IF;
        END;

        IF TRIM(P_NUMERO_IDENTIFICACION) != TRIM(P_IDEN_ORDENANTE) THEN
          /* PERSONAS RELACIONADAS */
          BEGIN
            INSERT INTO PERSONAS_RELACIONADAS
              (RLC_CLI_PER_NUM_IDEN,
               RLC_CLI_PER_TID_CODIGO,
               RLC_PER_NUM_IDEN,
               RLC_PER_TID_CODIGO,
               RLC_ROL_CODIGO,
               RLC_ESTADO,
               RLC_FECHA_CAMBIO_ESTADO,
               RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
               RLC_ETRADE,
               RLC_CELULAR,
               RLC_DIRECCION_EMAIL)
            VALUES
              (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
              ,
               TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
              ,
               TRIM(P_IDEN_ORDENANTE) --RLC_PER_NUM_IDEN
              ,
               TRIM(P_ID_ORDENANTE) --RLC_PER_TID_CODIGO
              ,
               1 --RLC_ROL_CODIGO: ORDENANTE
              ,
               'A' --R_RLC.RLC_ESTADO
              ,
               SYSDATE --RLC_FECHA_CAMBIO_ESTADO
              ,
               USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
              ,
               'S' --RLC_ETRADE
              ,
               P_CELULAR --RLC_CELULAR
              ,
               P_DIRECCIONEMAIL --RLC_DIRECCION_EMAIL
               );

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando persona relacionada 2.- ' ||
                               TRIM(P_ID_ORDENANTE) || '-' ||
                               TRIM(P_IDEN_ORDENANTE) || ' - ' || SQLERRM);
            END IF;
          END;
        END IF;
      END IF;

      IF P_ORIGEN = 'VIN' THEN

        --VAGTUD1004 VALIDA LA CIUDAD DE RESIDENCIA PARA MARCAR EL ESTADO ENVIO DE OTP POR SMS O ENVIO EMAIL

        IF FN_VALIDAD_CIUDAD_RESIDENCIA(V_CIUDAD_RESIDENCIA) = 1 THEN
          V_ENVIO_SMS   := 'S';
          V_ENVIO_EMAIL := 'N';
        ELSE
          V_ENVIO_SMS   := 'N';
          V_ENVIO_EMAIL := 'S';
        END IF;

        IF P_TIPO_CLIENTE = 'PNA' AND
           (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
           ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL) THEN
          /* Creaion o actualización de cliente como ordenante*/
          --VAGTUD1004 ELIMINACION DE ENVIO OTP POR EMAIL
          BEGIN
            INSERT INTO PERSONAS_RELACIONADAS
              (RLC_CLI_PER_NUM_IDEN,
               RLC_CLI_PER_TID_CODIGO,
               RLC_PER_NUM_IDEN,
               RLC_PER_TID_CODIGO,
               RLC_ROL_CODIGO,
               RLC_ESTADO,
               RLC_FECHA_CAMBIO_ESTADO,
               RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
               RLC_CELULAR,
               RLC_DIRECCION_EMAIL,
               RLC_AGE_COD_CIU_DTO_EXP,
               RLC_AGE_CODIGO,
               RLC_ENVIO_SMS,
               RLC_ENVIO_EMAIL)
            VALUES
              (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
              ,
               TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
              ,
               TRIM(P_NUMERO_IDENTIFICACION) --RLC_PER_NUM_IDEN
              ,
               TRIM(P_TIPO_IDENTIFICACION) --RLC_PER_TID_CODIGO
              ,
               1 --RLC_ROL_CODIGO: ORDENANTE
              ,
               'A' --R_RLC.RLC_ESTADO
              ,
               SYSDATE --RLC_FECHA_CAMBIO_ESTADO
              ,
               USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
              ,
               P_CELULAR --RLC_CELULAR
              ,
               P_DIRECCIONEMAIL --RLC_DIRECCION_EMAIL
              ,
               P_CIUDAD_EXP_DOCUMENTO,
               V_CIUDAD_RESIDENCIA,
               V_ENVIO_SMS,
               V_ENVIO_EMAIL);

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando persona relacionada 3.- ' ||
                               TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                               TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                               SQLERRM);
            END IF;
          END;
        ELSIF P_TIPO_CLIENTE = 'PNA' AND
              (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN
              ('PRV', 'INU', 'NUE') OR NVL(P_ORIGEN_OPERACION, 'N') != 'N') THEN
          /* Creaion cliente como ordenante*/
          BEGIN
            MERGE INTO PERSONAS_RELACIONADAS PR
            USING dual dd
            ON (PR.RLC_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND PR.RLC_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION) AND PR.RLC_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND PR.RLC_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION) AND PR.RLC_ROL_CODIGO = 1)
            WHEN MATCHED THEN
              UPDATE
                 SET RLC_ESTADO                     = 'A' --R_RLC.RLC_ESTADO
                    ,
                     RLC_FECHA_CAMBIO_ESTADO        = SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                    ,
                     RLC_USUARIO_ULTIMO_CAMBIO_ESTA = USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                    ,
                     RLC_CELULAR                    = P_CELULAR --RLC_CELULAR
                    ,
                     RLC_DIRECCION_EMAIL            = P_DIRECCIONEMAIL --RLC_DIRECCION_EMAIL
                    ,
                     RLC_AGE_COD_CIU_DTO_EXP        = P_CIUDAD_EXP_DOCUMENTO
            WHEN NOT MATCHED THEN
              INSERT
                (RLC_CLI_PER_NUM_IDEN,
                 RLC_CLI_PER_TID_CODIGO,
                 RLC_PER_NUM_IDEN,
                 RLC_PER_TID_CODIGO,
                 RLC_ROL_CODIGO,
                 RLC_ESTADO,
                 RLC_FECHA_CAMBIO_ESTADO,
                 RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
                 RLC_CELULAR,
                 RLC_DIRECCION_EMAIL,
                 RLC_AGE_COD_CIU_DTO_EXP)
              VALUES
                (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
                ,
                 TRIM(P_NUMERO_IDENTIFICACION) --RLC_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --RLC_PER_TID_CODIGO
                ,
                 1 --RLC_ROL_CODIGO: ORDENANTE
                ,
                 'A' --R_RLC.RLC_ESTADO
                ,
                 SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                ,
                 USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                ,
                 P_CELULAR --RLC_CELULAR
                ,
                 P_DIRECCIONEMAIL --RLC_DIRECCION_EMAIL
                ,
                 P_CIUDAD_EXP_DOCUMENTO --RLC_AGE_COD_CIU_DTO_EXP
                 );
            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando o actualizando persona relacionada 3.- ' ||
                               TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                               TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                               SQLERRM);
            END IF;
          END;
        END IF;
        --VAGTUD1004 SE POBLAN LOS CAMPOS  AL MOMENTO CREAR EL TUTOR DEL CLIENTE MENOR DE EDAD
        --RLC_ENVIO_SMS RLC_ENVIO_EMAIL
        IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
           ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL THEN
          OPEN PERV_VINCULA_RELA(P_NUMERO_FORMULARIO_VIN,
                                 P_NUMERO_IDENTIFICACION,
                                 P_TIPO_IDENTIFICACION);
          FETCH PERV_VINCULA_RELA
            INTO C_PERV_VINCULA_RELA;
          WHILE PERV_VINCULA_RELA%FOUND LOOP
            BEGIN
              INSERT INTO PERSONAS_RELACIONADAS
                (RLC_CLI_PER_NUM_IDEN,
                 RLC_CLI_PER_TID_CODIGO,
                 RLC_PER_NUM_IDEN,
                 RLC_PER_TID_CODIGO,
                 RLC_ROL_CODIGO,
                 RLC_ESTADO,
                 RLC_FECHA_CAMBIO_ESTADO,
                 RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
                 RLC_CALIDAD,
                 RLC_CARGO,
                 RLC_DIRECCION,
                 RLC_AGE_CODIGO,
                 RLC_TELEFONO,
                 RLC_PAO_CONSECUTIVO,
                 RLC_CELULAR,
                 RLC_DIRECCION_OFICINA,
                 RLC_AGE_CODIGO_OFICINA,
                 RLC_DIRECCION_EMAIL,
                 RLC_AGE_COD_CIU_DTO_EXP,
                 RLC_FECHA_VENCIMIENTO,
                 RLC_ENVIO_SMS,
                 RLC_ENVIO_EMAIL)
              VALUES
                (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
                ,
                 TRIM(C_PERV_VINCULA_RELA.PERV_PER_NUM_IDEN) --RLC_PER_NUM_IDEN
                ,
                 TRIM(C_PERV_VINCULA_RELA.PERV_PER_TID_CODIGO) --RLC_PER_TID_CODIGO
                ,
                 C_PERV_VINCULA_RELA.PERV_ROL_ORDENANTE --RLC_ROL_CODIGO
                ,
                 'A' --R_RLC.RLC_ESTADO
                ,
                 SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                ,
                 USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                ,
                 C_PERV_VINCULA_RELA.PERV_CALIDAD --RLC_CALIDAD
                ,
                 C_PERV_VINCULA_RELA.PERV_CARGO --RLC_CARGO
                ,
                 NULL --RLC_DIRECCION
                ,
                 NULL --RLC_AGE_CODIGO
                ,
                 C_PERV_VINCULA_RELA.PERV_TELEFONO --RLC_TELEFONO
                ,
                 DECODE(P_TIPO_CLIENTE,
                        'PNA',
                        C_PERV_VINCULA_RELA.PERV_PARENTESCO,
                        NULL) --RLC_PAO_CONSECUTIVO
                ,
                 C_PERV_VINCULA_RELA.PERV_CELULAR --RLC_CELULAR
                ,
                 C_PERV_VINCULA_RELA.PERV_DIRECCION_OFICINA --RLC_DIRECCION_OFICINA
                ,
                 C_PERV_VINCULA_RELA.PERV_CIUDAD_OFICINA --RLC_AGE_CODIGO_OFICINA
                ,
                 C_PERV_VINCULA_RELA.PERV_DIRECCION_EMAIL --RLC_DIRECCION_EMAIL
                ,
                 C_PERV_VINCULA_RELA.perv_ciudad_exp_documento --RLC_AGE_COD_CIU_DTO_EXP
                ,
                 C_PERV_VINCULA_RELA.PERV_FECHA_VENC_ID --RLC_AGE_COD_CIU_CTO_EXP  --RLC_FECHA_VENCIMIENTO
                ,
                 V_ENVIO_SMS,
                 V_ENVIO_EMAIL);
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando persona relacionada 4.- ' ||
                                 TRIM(C_PERV_VINCULA_RELA.PERV_PER_TID_CODIGO) || '-' ||
                                 TRIM(C_PERV_VINCULA_RELA.PERV_PER_NUM_IDEN) ||
                                 ' - ' || SQLERRM);
              END IF;
            END;
            FETCH PERV_VINCULA_RELA
              INTO C_PERV_VINCULA_RELA;
          END LOOP;
          CLOSE PERV_VINCULA_RELA;

        ELSIF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN
              ('PRV', 'INU', 'NUE') OR NVL(P_ORIGEN_OPERACION, 'N') != 'N' THEN

          OPEN PERV_VINCULA_RELA(P_NUMERO_FORMULARIO_VIN,
                                 P_NUMERO_IDENTIFICACION,
                                 P_TIPO_IDENTIFICACION);
          FETCH PERV_VINCULA_RELA
            INTO C_PERV_VINCULA_RELA;
          WHILE PERV_VINCULA_RELA%FOUND LOOP
            BEGIN
              MERGE INTO PERSONAS_RELACIONADAS PR
              USING dual dd
              ON (PR.RLC_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND PR.RLC_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION) AND PR.RLC_PER_NUM_IDEN = TRIM(C_PERV_VINCULA_RELA.PERV_PER_NUM_IDEN) AND PR.RLC_PER_TID_CODIGO = TRIM(C_PERV_VINCULA_RELA.PERV_PER_TID_CODIGO) AND PR.RLC_ROL_CODIGO = C_PERV_VINCULA_RELA.PERV_ROL_ORDENANTE)
              WHEN MATCHED THEN
                UPDATE
                   SET RLC_ESTADO                     = 'A' --R_RLC.RLC_ESTADO
                      ,
                       RLC_FECHA_CAMBIO_ESTADO        = SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                      ,
                       RLC_USUARIO_ULTIMO_CAMBIO_ESTA = USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                      ,
                       RLC_CALIDAD                    = C_PERV_VINCULA_RELA.PERV_CALIDAD --RLC_CALIDAD
                      ,
                       RLC_CARGO                      = C_PERV_VINCULA_RELA.PERV_CARGO --RLC_CARGO
                      ,
                       RLC_DIRECCION                  = NULL --RLC_DIRECCION
                      ,
                       RLC_AGE_CODIGO                 = NULL --RLC_AGE_CODIGO
                      ,
                       RLC_TELEFONO                   = C_PERV_VINCULA_RELA.PERV_TELEFONO --RLC_TELEFONO
                      ,
                       RLC_PAO_CONSECUTIVO            = DECODE(P_TIPO_CLIENTE,
                                                               'PNA',
                                                               C_PERV_VINCULA_RELA.PERV_PARENTESCO,
                                                               NULL) --RLC_PAO_CONSECUTIVO
                      ,
                       RLC_CELULAR                    = C_PERV_VINCULA_RELA.PERV_CELULAR --RLC_CELULAR
                      ,
                       RLC_DIRECCION_OFICINA          = C_PERV_VINCULA_RELA.PERV_DIRECCION_OFICINA --RLC_DIRECCION_OFICINA
                      ,
                       RLC_AGE_CODIGO_OFICINA         = C_PERV_VINCULA_RELA.PERV_CIUDAD_OFICINA --RLC_AGE_CODIGO_OFICINA
                      ,
                       RLC_DIRECCION_EMAIL            = C_PERV_VINCULA_RELA.PERV_DIRECCION_EMAIL --RLC_DIRECCION_EMAIL
                      ,
                       RLC_AGE_COD_CIU_DTO_EXP        = C_PERV_VINCULA_RELA.PERV_CIUDAD_EXP_DOCUMENTO --RLC_AGE_COD_CIU_DTO_EXP
                      ,
                       RLC_FECHA_VENCIMIENTO          = C_PERV_VINCULA_RELA.PERV_FECHA_VENC_ID --RLC_FECHA_VENCIMIENTO


              WHEN NOT MATCHED THEN
                INSERT
                  (RLC_CLI_PER_NUM_IDEN,
                   RLC_CLI_PER_TID_CODIGO,
                   RLC_PER_NUM_IDEN,
                   RLC_PER_TID_CODIGO,
                   RLC_ROL_CODIGO,
                   RLC_ESTADO,
                   RLC_FECHA_CAMBIO_ESTADO,
                   RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
                   RLC_CALIDAD,
                   RLC_CARGO,
                   RLC_DIRECCION,
                   RLC_AGE_CODIGO,
                   RLC_TELEFONO,
                   RLC_PAO_CONSECUTIVO,
                   RLC_CELULAR,
                   RLC_DIRECCION_OFICINA,
                   RLC_AGE_CODIGO_OFICINA,
                   RLC_DIRECCION_EMAIL,
                   RLC_AGE_COD_CIU_DTO_EXP,
                   RLC_FECHA_VENCIMIENTO)
                VALUES
                  (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
                  ,
                   TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
                  ,
                   TRIM(C_PERV_VINCULA_RELA.PERV_PER_NUM_IDEN) --RLC_PER_NUM_IDEN
                  ,
                   TRIM(C_PERV_VINCULA_RELA.PERV_PER_TID_CODIGO) --RLC_PER_TID_CODIGO
                  ,
                   C_PERV_VINCULA_RELA.PERV_ROL_ORDENANTE --RLC_ROL_CODIGO
                  ,
                   'A' --R_RLC.RLC_ESTADO
                  ,
                   SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                  ,
                   USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                  ,
                   C_PERV_VINCULA_RELA.PERV_CALIDAD --RLC_CALIDAD
                  ,
                   C_PERV_VINCULA_RELA.PERV_CARGO --RLC_CARGO
                  ,
                   NULL --RLC_DIRECCION
                  ,
                   NULL --RLC_AGE_CODIGO
                  ,
                   C_PERV_VINCULA_RELA.PERV_TELEFONO --RLC_TELEFONO
                  ,
                   DECODE(P_TIPO_CLIENTE,
                          'PNA',
                          C_PERV_VINCULA_RELA.PERV_PARENTESCO,
                          NULL) --RLC_PAO_CONSECUTIVO
                  ,
                   C_PERV_VINCULA_RELA.PERV_CELULAR --RLC_CELULAR
                  ,
                   C_PERV_VINCULA_RELA.PERV_DIRECCION_OFICINA --RLC_DIRECCION_OFICINA
                  ,
                   C_PERV_VINCULA_RELA.PERV_CIUDAD_OFICINA --RLC_AGE_CODIGO_OFICINA
                  ,
                   C_PERV_VINCULA_RELA.PERV_DIRECCION_EMAIL --RLC_DIRECCION_EMAIL
                  ,
                   C_PERV_VINCULA_RELA.perv_ciudad_exp_documento --RLC_AGE_COD_CIU_DTO_EXP
                  ,
                   C_PERV_VINCULA_RELA.PERV_FECHA_VENC_ID --RLC_FECHA_VENCIMIENTO
                   );
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando persona relacionada 4.- ' ||
                                 TRIM(C_PERV_VINCULA_RELA.PERV_PER_TID_CODIGO) || '-' ||
                                 TRIM(C_PERV_VINCULA_RELA.PERV_PER_NUM_IDEN) ||
                                 ' - ' || SQLERRM);
              END IF;
            END;
            FETCH PERV_VINCULA_RELA
              INTO C_PERV_VINCULA_RELA;
          END LOOP;
          CLOSE PERV_VINCULA_RELA;
        END IF;

        IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
           ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL THEN
          /* creacion cuentas bancarias nacionales*/
          OPEN CBVI_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH CBVI_VINCULA
            INTO C_CBVI_VINCULA;
          WHILE CBVI_VINCULA%FOUND LOOP
            BEGIN
              INSERT INTO CUENTAS_BANCARIAS_CLIENTES
                (CBC_NUMERO_CUENTA,
                 CBC_BAN_CODIGO,
                 CBC_CLI_PER_NUM_IDEN,
                 CBC_CLI_PER_TID_CODIGO,
                 CBC_TCB_MNEMONICO,
                 CBC_ESTADO,
                 CBC_SUCURSAL,
                 CBC_DIRECCION,
                 CBC_TELEFONO)
              VALUES
                (C_CBVI_VINCULA.CBVI_NUMERO_CUENTA --CBC_NUMERO_CUENTA
                ,
                 C_CBVI_VINCULA.CBVI_BANCO --CBC_BAN_CODIGO
                ,
                 TRIM(P_NUMERO_IDENTIFICACION) --CBC_CLI_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --CBC_CLI_PER_TID_CODIGO
                ,
                 C_CBVI_VINCULA.CBVI_TIPO --CBC_TCB_MNEMONICO
                ,
                 'A' --CBC_ESTADO
                ,
                 C_CBVI_VINCULA.CBVI_SUCURSAL --CBC_SUCURSAL
                ,
                 C_CBVI_VINCULA.CBVI_DIRECCION --CBC_DIRECCION
                ,
                 C_CBVI_VINCULA.CBVI_TELEFONO --CBC_TELEFONO
                 );

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando cuenta bancaria: ' ||
                                 C_CBVI_VINCULA.CBVI_BANCO || '-' ||
                                 C_CBVI_VINCULA.CBVI_NUMERO_CUENTA || '-' ||
                                 P_NUMERO_IDENTIFICACION || ' - ' ||
                                 SQLERRM);
              END IF;
            END;
            FETCH CBVI_VINCULA
              INTO C_CBVI_VINCULA;
          END LOOP;
          CLOSE CBVI_VINCULA;

        ELSIF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN
              ('PRV', 'INU', 'NUE') OR NVL(P_ORIGEN_OPERACION, 'N') != 'N' THEN
          /* creacion cuentas bancarias nacionales*/
          OPEN CBVI_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH CBVI_VINCULA
            INTO C_CBVI_VINCULA;
          WHILE CBVI_VINCULA%FOUND LOOP
            BEGIN

              MERGE INTO CUENTAS_BANCARIAS_CLIENTES CB
              USING dual dd
              ON (CB.CBC_NUMERO_CUENTA = C_CBVI_VINCULA.CBVI_NUMERO_CUENTA AND CB.CBC_BAN_CODIGO = C_CBVI_VINCULA.CBVI_BANCO AND CB.CBC_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND CB.CBC_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION))
              WHEN MATCHED THEN
                UPDATE
                   SET CBC_TCB_MNEMONICO = C_CBVI_VINCULA.CBVI_TIPO --CBC_TCB_MNEMONICO
                      ,
                       CBC_ESTADO        = 'A' --CBC_ESTADO
                      ,
                       CBC_SUCURSAL      = C_CBVI_VINCULA.CBVI_SUCURSAL --CBC_SUCURSAL
                      ,
                       CBC_DIRECCION     = C_CBVI_VINCULA.CBVI_DIRECCION --CBC_DIRECCION
                      ,
                       CBC_TELEFONO      = C_CBVI_VINCULA.CBVI_TELEFONO --CBC_TELEFONO


              WHEN NOT MATCHED THEN
                INSERT
                  (CBC_NUMERO_CUENTA,
                   CBC_BAN_CODIGO,
                   CBC_CLI_PER_NUM_IDEN,
                   CBC_CLI_PER_TID_CODIGO,
                   CBC_TCB_MNEMONICO,
                   CBC_ESTADO,
                   CBC_SUCURSAL,
                   CBC_DIRECCION,
                   CBC_TELEFONO)
                VALUES
                  (C_CBVI_VINCULA.CBVI_NUMERO_CUENTA --CBC_NUMERO_CUENTA
                  ,
                   C_CBVI_VINCULA.CBVI_BANCO --CBC_BAN_CODIGO
                  ,
                   TRIM(P_NUMERO_IDENTIFICACION) --CBC_CLI_PER_NUM_IDEN
                  ,
                   TRIM(P_TIPO_IDENTIFICACION) --CBC_CLI_PER_TID_CODIGO
                  ,
                   C_CBVI_VINCULA.CBVI_TIPO --CBC_TCB_MNEMONICO
                  ,
                   'A' --CBC_ESTADO
                  ,
                   C_CBVI_VINCULA.CBVI_SUCURSAL --CBC_SUCURSAL
                  ,
                   C_CBVI_VINCULA.CBVI_DIRECCION --CBC_DIRECCION
                  ,
                   C_CBVI_VINCULA.CBVI_TELEFONO --CBC_TELEFONO
                   );

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando o actualizando cuenta bancaria: ' ||
                                 C_CBVI_VINCULA.CBVI_BANCO || '-' ||
                                 C_CBVI_VINCULA.CBVI_NUMERO_CUENTA || '-' ||
                                 P_NUMERO_IDENTIFICACION || ' - ' ||
                                 SQLERRM);

              END IF;
            END;
            FETCH CBVI_VINCULA
              INTO C_CBVI_VINCULA;
          END LOOP;
          CLOSE CBVI_VINCULA;
        END IF;

        IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
           ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL THEN
          /* Creacion cuentas bancarias exterior*/
          V_VALIDA_CTA_EXTERIOR := 0;
          OPEN CBEV_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH CBEV_VINCULA
            INTO C_CBEV_VINCULA;
          WHILE CBEV_VINCULA%FOUND LOOP
            BEGIN
              INSERT INTO CUENTAS_BANCARIAS_CLIENTES_EXT
                (CBX_NUMERO_CUENTA,
                 CBX_BEX_MNEMONICO,
                 CBX_CLI_PER_NUM_IDEN,
                 CBX_CLI_PER_TID_CODIGO,
                 CBX_BMO_MNEMONICO,
                 CBX_AGE_CODIGO,
                 CBX_ESTADO,
                 CBX_CUENTA_COMPENSACION,
                 CBX_TIPO_TRANSACCION,
                 CBX_NOMBRE_CUENTA_INTERNA,
                 CBX_PAGO_DIVIDENDOS,
                 CBX_OTRO_TIPO_TRANSACCION,
                 CBX_CONFIRMADA,
                 CBX_FECHA_CONFIRMACION,
                 CBX_MEDIO_CONFIRMACION,
                 CBX_DETALLE_MEDIO_CONFIRMACION,
                 CBX_HORA_CONFIRMACION,
                 CBX_PER_TID_CODIGO,
                 CBX_PER_NUM_IDEN)
              VALUES
                (C_CBEV_VINCULA.CBEV_NUMERO_CUENTA --CBX_NUMERO_CUENTA
                ,
                 C_CBEV_VINCULA.CBEV_BANCO --CBX_BEX_MNEMONICO
                ,
                 TRIM(P_NUMERO_IDENTIFICACION) --CBX_CLI_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --CBX_CLI_PER_TID_CODIGO
                ,
                 C_CBEV_VINCULA.CBEV_MONEDA --CBX_BMO_MNEMONICO
                ,
                 C_CBEV_VINCULA.CBEV_CIUDAD --CBX_AGE_CODIGO
                ,
                 'A' --CBX_ESTADO
                ,
                 C_CBEV_VINCULA.CBEV_COMPENSACION --CBX_CUENTA_COMPENSACION
                ,
                 C_CBEV_VINCULA.CBEV_TIPO_OPERACION --CBX_TIPO_TRANSACCION
                ,
                 'NO APLICA' --CBX_NOMBRE_CUENTA_INTERNA
                ,
                 'N' --CBX_PAGO_DIVIDENDOS
                ,
                 NULL --CBX_OTRO_TIPO_TRANSACCION
                ,
                 NULL --CBX_CONFIRMADA
                ,
                 NULL --CBX_FECHA_CONFIRMACION
                ,
                 NULL --CBX_MEDIO_CONFIRMACION
                ,
                 NULL --CBX_DETALLE_MEDIO_CONFIRMACION
                ,
                 NULL --CBX_HORA_CONFIRMACION
                ,
                 NULL --CBX_PER_TID_CODIGO
                ,
                 NULL --CBX_PER_NUM_IDEN
                 );
              V_VALIDA_CTA_EXTERIOR := V_VALIDA_CTA_EXTERIOR + 1;
              IF SQL%ROWCOUNT = 0 THEN
                V_VALIDA_CTA_EXTERIOR := 0;
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando cuenta bancaria exterior.' ||
                                 C_CBEV_VINCULA.CBEV_BANCO || '-' ||
                                 C_CBEV_VINCULA.CBEV_NUMERO_CUENTA || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
              END IF;
            END;
            FETCH CBEV_VINCULA
              INTO C_CBEV_VINCULA;
          END LOOP;
          CLOSE CBEV_VINCULA;

          IF NVL(V_VALIDA_CTA_EXTERIOR, 0) >= 1 THEN
            -- ACTUALIZAR CLI_MONEDA_EXT EN CLIENTES
            BEGIN
              UPDATE CLIENTES
                 SET CLI_MONEDA_EXT = 'S'
               WHERE CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION)
                 AND CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION);

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CREARERROR('Error creando cliente:' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
              END IF;
            END;
          END IF;

        ELSIF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN
              ('PRV', 'INU', 'NUE') OR NVL(P_ORIGEN_OPERACION, 'N') != 'N' THEN
          /* Creacion cuentas bancarias exterior*/
          V_VALIDA_CTA_EXTERIOR := 0;
          OPEN CBEV_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH CBEV_VINCULA
            INTO C_CBEV_VINCULA;
          WHILE CBEV_VINCULA%FOUND LOOP
            BEGIN

              MERGE INTO CUENTAS_BANCARIAS_CLIENTES_EXT CE
              USING dual dd
              ON (CE.CBX_NUMERO_CUENTA = C_CBEV_VINCULA.CBEV_NUMERO_CUENTA AND CE.CBX_BEX_MNEMONICO = C_CBEV_VINCULA.CBEV_BANCO AND CE.CBX_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND CE.CBX_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION))
              WHEN MATCHED THEN
                UPDATE
                   SET CBX_BMO_MNEMONICO              = C_CBEV_VINCULA.CBEV_MONEDA --CBX_BMO_MNEMONICO
                      ,
                       CBX_AGE_CODIGO                 = C_CBEV_VINCULA.CBEV_CIUDAD --CBX_AGE_CODIGO
                      ,
                       CBX_ESTADO                     = 'A' --CBX_ESTADO
                      ,
                       CBX_CUENTA_COMPENSACION        = C_CBEV_VINCULA.CBEV_COMPENSACION --CBX_CUENTA_COMPENSACION
                      ,
                       CBX_TIPO_TRANSACCION           = C_CBEV_VINCULA.CBEV_TIPO_OPERACION --CBX_TIPO_TRANSACCION
                      ,
                       CBX_NOMBRE_CUENTA_INTERNA      = 'NO APLICA' --CBX_NOMBRE_CUENTA_INTERNA
                      ,
                       CBX_PAGO_DIVIDENDOS            = 'N' --CBX_PAGO_DIVIDENDOS
                      ,
                       CBX_OTRO_TIPO_TRANSACCION      = NULL --CBX_OTRO_TIPO_TRANSACCION
                      ,
                       CBX_CONFIRMADA                 = NULL --CBX_CONFIRMADA
                      ,
                       CBX_FECHA_CONFIRMACION         = NULL --CBX_FECHA_CONFIRMACION
                      ,
                       CBX_MEDIO_CONFIRMACION         = NULL --CBX_MEDIO_CONFIRMACION
                      ,
                       CBX_DETALLE_MEDIO_CONFIRMACION = NULL --CBX_DETALLE_MEDIO_CONFIRMACION
                      ,
                       CBX_HORA_CONFIRMACION          = NULL --CBX_HORA_CONFIRMACION
                      ,
                       CBX_PER_TID_CODIGO             = NULL --CBX_PER_TID_CODIGO
                      ,
                       CBX_PER_NUM_IDEN               = NULL --CBX_PER_NUM_IDEN


              WHEN NOT MATCHED THEN
                INSERT
                  (CBX_NUMERO_CUENTA,
                   CBX_BEX_MNEMONICO,
                   CBX_CLI_PER_NUM_IDEN,
                   CBX_CLI_PER_TID_CODIGO,
                   CBX_BMO_MNEMONICO,
                   CBX_AGE_CODIGO,
                   CBX_ESTADO,
                   CBX_CUENTA_COMPENSACION,
                   CBX_TIPO_TRANSACCION,
                   CBX_NOMBRE_CUENTA_INTERNA,
                   CBX_PAGO_DIVIDENDOS,
                   CBX_OTRO_TIPO_TRANSACCION,
                   CBX_CONFIRMADA,
                   CBX_FECHA_CONFIRMACION,
                   CBX_MEDIO_CONFIRMACION,
                   CBX_DETALLE_MEDIO_CONFIRMACION,
                   CBX_HORA_CONFIRMACION,
                   CBX_PER_TID_CODIGO,
                   CBX_PER_NUM_IDEN)
                VALUES
                  (C_CBEV_VINCULA.CBEV_NUMERO_CUENTA --CBX_NUMERO_CUENTA
                  ,
                   C_CBEV_VINCULA.CBEV_BANCO --CBX_BEX_MNEMONICO
                  ,
                   TRIM(P_NUMERO_IDENTIFICACION) --CBX_CLI_PER_NUM_IDEN
                  ,
                   TRIM(P_TIPO_IDENTIFICACION) --CBX_CLI_PER_TID_CODIGO
                  ,
                   C_CBEV_VINCULA.CBEV_MONEDA --CBX_BMO_MNEMONICO
                  ,
                   C_CBEV_VINCULA.CBEV_CIUDAD --CBX_AGE_CODIGO
                  ,
                   'A' --CBX_ESTADO
                  ,
                   C_CBEV_VINCULA.CBEV_COMPENSACION --CBX_CUENTA_COMPENSACION
                  ,
                   C_CBEV_VINCULA.CBEV_TIPO_OPERACION --CBX_TIPO_TRANSACCION
                  ,
                   'NO APLICA' --CBX_NOMBRE_CUENTA_INTERNA
                  ,
                   'N' --CBX_PAGO_DIVIDENDOS
                  ,
                   NULL --CBX_OTRO_TIPO_TRANSACCION
                  ,
                   NULL --CBX_CONFIRMADA
                  ,
                   NULL --CBX_FECHA_CONFIRMACION
                  ,
                   NULL --CBX_MEDIO_CONFIRMACION
                  ,
                   NULL --CBX_DETALLE_MEDIO_CONFIRMACION
                  ,
                   NULL --CBX_HORA_CONFIRMACION
                  ,
                   NULL --CBX_PER_TID_CODIGO
                  ,
                   NULL --CBX_PER_NUM_IDEN
                   );
              V_VALIDA_CTA_EXTERIOR := V_VALIDA_CTA_EXTERIOR + 1;
              IF SQL%ROWCOUNT = 0 THEN
                V_VALIDA_CTA_EXTERIOR := 0;
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando o actualizando cuenta bancaria exterior.' ||
                                 C_CBEV_VINCULA.CBEV_BANCO || '-' ||
                                 C_CBEV_VINCULA.CBEV_NUMERO_CUENTA || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
              END IF;
            END;
            FETCH CBEV_VINCULA
              INTO C_CBEV_VINCULA;
          END LOOP;
          CLOSE CBEV_VINCULA;

          IF NVL(V_VALIDA_CTA_EXTERIOR, 0) >= 1 THEN
            -- ACTUALIZAR CLI_MONEDA_EXT EN CLIENTES
            BEGIN
              UPDATE CLIENTES
                 SET CLI_MONEDA_EXT = 'S'
               WHERE CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION)
                 AND CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION);

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CREARERROR('Error creando o actualizando cliente:' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
              END IF;
            END;
          END IF;
        END IF;

        IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
           ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL THEN
          /* creacion informacion de revelacion*/
          OPEN IFRV_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH IFRV_VINCULA
            INTO C_IFRV_VINCULA;
          WHILE IFRV_VINCULA%FOUND LOOP
            BEGIN
              INSERT INTO PERSONAS_RELACIONADAS
                (RLC_CLI_PER_NUM_IDEN,
                 RLC_CLI_PER_TID_CODIGO,
                 RLC_PER_NUM_IDEN,
                 RLC_PER_TID_CODIGO,
                 RLC_ROL_CODIGO,
                 RLC_ESTADO,
                 RLC_FECHA_CAMBIO_ESTADO,
                 RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
                 RLC_PAO_CONSECUTIVO,
                 RLC_ES_FUNCIONARIO)
              VALUES
                (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
                ,
                 TRIM(C_IFRV_VINCULA.IFRV_PER_NUM_IDEN) --RLC_PER_NUM_IDEN
                ,
                 TRIM(C_IFRV_VINCULA.IFRV_PER_TID_CODIGO) --RLC_PER_TID_CODIGO
                ,
                 C_IFRV_VINCULA.IFRV_ROL_ORDENANTE --RLC_ROL_CODIGO
                ,
                 'A' --R_RLC.RLC_ESTADO
                ,
                 SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                ,
                 USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                ,
                 C_IFRV_VINCULA.IFRV_PARENTESCO --RLC_PAO_CONSECUTIVO
                ,
                 'S' --RLC_ES_FUNCIONARIO
                 );
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando personas relacionadas- ' ||
                                 TRIM(C_IFRV_VINCULA.IFRV_PER_TID_CODIGO) || '-' ||
                                 TRIM(C_IFRV_VINCULA.IFRV_PER_NUM_IDEN) ||
                                 ' - ' || SQLERRM);
              END IF;
            END;
            FETCH IFRV_VINCULA
              INTO C_IFRV_VINCULA;
          END LOOP;
          CLOSE IFRV_VINCULA;

        ELSIF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN
              ('PRV', 'INU', 'NUE') OR NVL(P_ORIGEN_OPERACION, 'N') != 'N' THEN
          /* creacion informacion de revelacion*/
          OPEN IFRV_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH IFRV_VINCULA
            INTO C_IFRV_VINCULA;
          WHILE IFRV_VINCULA%FOUND LOOP
            BEGIN

              MERGE INTO PERSONAS_RELACIONADAS PR
              USING dual dd
              ON (PR.RLC_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND PR.RLC_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION) AND PR.RLC_PER_NUM_IDEN = TRIM(C_PERV_VINCULA_RELA.PERV_PER_NUM_IDEN) AND PR.RLC_PER_TID_CODIGO = TRIM(C_PERV_VINCULA_RELA.PERV_PER_TID_CODIGO) AND PR.RLC_ROL_CODIGO = C_PERV_VINCULA_RELA.PERV_ROL_ORDENANTE)
              WHEN MATCHED THEN
                UPDATE
                   SET PR.RLC_CLI_PER_NUM_IDEN           = TRIM(P_NUMERO_IDENTIFICACION),
                       PR.RLC_CLI_PER_TID_CODIGO         = TRIM(P_TIPO_IDENTIFICACION),
                       PR.RLC_PER_NUM_IDEN               = TRIM(C_IFRV_VINCULA.IFRV_PER_NUM_IDEN),
                       PR.RLC_PER_TID_CODIGO             = TRIM(C_IFRV_VINCULA.IFRV_PER_TID_CODIGO),
                       PR.RLC_ROL_CODIGO                 = C_IFRV_VINCULA.IFRV_ROL_ORDENANTE,
                       PR.RLC_ESTADO                     = 'A',
                       PR.RLC_FECHA_CAMBIO_ESTADO        = SYSDATE,
                       PR.RLC_USUARIO_ULTIMO_CAMBIO_ESTA = USER,
                       PR.RLC_PAO_CONSECUTIVO            = C_IFRV_VINCULA.IFRV_PARENTESCO,
                       PR.RLC_ES_FUNCIONARIO             = 'S'
              WHEN NOT MATCHED THEN
                INSERT
                  (RLC_CLI_PER_NUM_IDEN,
                   RLC_CLI_PER_TID_CODIGO,
                   RLC_PER_NUM_IDEN,
                   RLC_PER_TID_CODIGO,
                   RLC_ROL_CODIGO,
                   RLC_ESTADO,
                   RLC_FECHA_CAMBIO_ESTADO,
                   RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
                   RLC_PAO_CONSECUTIVO,
                   RLC_ES_FUNCIONARIO)
                VALUES
                  (TRIM(P_NUMERO_IDENTIFICACION) --RLC_CLI_PER_NUM_IDEN
                  ,
                   TRIM(P_TIPO_IDENTIFICACION) --RLC_CLI_PER_TID_CODIGO
                  ,
                   TRIM(C_IFRV_VINCULA.IFRV_PER_NUM_IDEN) --RLC_PER_NUM_IDEN
                  ,
                   TRIM(C_IFRV_VINCULA.IFRV_PER_TID_CODIGO) --RLC_PER_TID_CODIGO
                  ,
                   C_IFRV_VINCULA.IFRV_ROL_ORDENANTE --RLC_ROL_CODIGO
                  ,
                   'A' --R_RLC.RLC_ESTADO
                  ,
                   SYSDATE --RLC_FECHA_CAMBIO_ESTADO
                  ,
                   USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
                  ,
                   C_IFRV_VINCULA.IFRV_PARENTESCO --RLC_PAO_CONSECUTIVO
                  ,
                   'S' --RLC_ES_FUNCIONARIO
                   );
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando o actualizando personas relacionadas- ' ||
                                 TRIM(C_IFRV_VINCULA.IFRV_PER_TID_CODIGO) || '-' ||
                                 TRIM(C_IFRV_VINCULA.IFRV_PER_NUM_IDEN) ||
                                 ' - ' || SQLERRM);
              END IF;
            END;
            FETCH IFRV_VINCULA
              INTO C_IFRV_VINCULA;
          END LOOP;
          CLOSE IFRV_VINCULA;
        END IF;

        /* CREACION INFORMACION FACTA Y CRS PERSONA NATURUAL*/
        IF P_TIPO_CLIENTE = 'PNA' AND
           (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
           ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL) THEN
          BEGIN
            INSERT INTO PERSONA_NATURAL
              (PNF_PAI_NACIMIENTO,
               PNF_PAI_RESIDENCIA,
               PNF_CLI_PER_NUM_IDEN,
               PNF_CLI_PER_TID_CODIGO,
               PNF_SUBD_CONSECUTIVO,
               PNF_MOT_CONSECUTIVO,
               PNF_TIENE_PASAPORTE_AMERICANO,
               PNF_NUM_PASAPORTE_AMERICANO,
               PNF_GREEN_CARD,
               PNF_CIUDADANO_AMERICANO,
               PNF_NACIONALIDAD_AMERICANA,
               PNF_PERMANENCIA_182_DIAS,
               PNF_PERMANENCIA_122_DIAS,
               PNF_OTRO_MOTIVO_ESTADIA,
               PNF_TIN,
               PNF_ES_RES_LEG_NO_COL,
               PNF_DIRECCION_OTRO_PAIS,
               PNF_CIUDAD_MUNICIPIO,
               PNF_IMPACTADO_FATCA,
               PNF_AGE_CODIGO_RESIDE,
               PNF_EXENTO_FATCA,
               PNF_MOTIVO_EXENCION,
               PNF_INDICIOS_CRS,
               PNF_IMPACTADO_CRS,
               PNF_TIN_CRS1,
               PNF_TIN_CRS2,
               PNF_TIN_CRS3,
               PNF_MOTIVO_NO_TIN1,
               PNF_MOTIVO_NO_TIN2,
               PNF_MOTIVO_NO_TIN3,
               PNF_PAI_FISCAL1,
               PNF_PAI_FISCAL2,
               PNF_PAI_FISCAL3)
            VALUES
              (P_PAI_NACIMIENTO_FN, --PNF_PAI_NACIMIENTO,
               NULL, --PNF_PAI_RESIDENCIA
               TRIM(P_NUMERO_IDENTIFICACION), --PNF_CLI_PER_NUM_IDEN,
               TRIM(P_TIPO_IDENTIFICACION), --PNF_CLI_PER_TID_CODIGO,
               NULL, --PNF_SUBD_CONSECUTIVO,
               P_MOT_CONSECUTIVO_FN, --PNF_MOT_CONSECUTIVO,
               P_PASAPORTE_AMERICANO_FN, --PNF_TIENE_PASAPORTE_AMERICANO,
               NULL, --PNF_NUM_PASAPORTE_AMERICANO,
               P_GREEN_CARD_FN, --PNF_GREEN_CARD,
               P_CIUDADANO_AMERICANO_FN, --PNF_CIUDADANO_AMERICANO,
               P_NACIONA_AMERICANA_FN, --PNF_NACIONALIDAD_AMERICANA,
               P_PERMANENCIA_182_DIAS_FN, --PNF_PERMANENCIA_182_DIAS,
               P_PERMANENCIA_122_DIAS_FN, --PNF_PERMANENCIA_122_DIAS
               P_OTRO_MOTIVO_ESTADIA_FN, --PNF_OTRO_MOTIVO_ESTADIA,
               P_TIN_FN, --PNF_TIN,
               NULL, --PNF_ES_RES_LEG_NO_COL,
               NULL, --PNF_DIRECCION_OTRO_PAIS
               NULL, --PNF_CIUDAD_MUNICIPIO,
               P_IMPACTADO_FATCA_FN, --PNF_IMPACTADO_FATCA,
               P_AGE_CODIGO_RESIDE_FN, --PNF_AGE_CODIGO_RESIDE,
               P_EXENTO_FATCA_FN, --PNF_EXENTO_FATCA,
               P_MOTIVO_EXENCION_FN, --PNF_MOTIVO_EXENCION,
               NVL(P_INDICIOS_CRS_FN, 'N'), --PNF_INDICIOS_CRS,
               P_IMPACTADO_CRS_FN, --PNF_IMPACTADO_CRS,
               P_TIN_CRS1_FN, --PNF_TIN_CRS1
               P_TIN_CRS2_FN, --PNF_TIN_CRS2
               P_TIN_CRS3_FN, --PNF_TIN_CRS3
               P_MOTIVO_NO_TIN1_FN, --PNF_MOTIVO_NO_TIN1
               P_MOTIVO_NO_TIN2_FN, --PNF_MOTIVO_NO_TIN2
               P_MOTIVO_NO_TIN3_FN, --PNF_MOTIVO_NO_TIN3
               P_PAI_FISCAL1_FN, --PNF_PAI_FISCAL1
               P_PAI_FISCAL2_FN, --PNF_PAI_FISCAL2
               P_PAI_FISCAL3_FN --PNF_PAI_FISCAL3
               );

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando informacion Fatca-CRS- ' ||
                               TRIM(P_NUMERO_IDENTIFICACION) || '-' ||
                               TRIM(P_TIPO_IDENTIFICACION) || ' - ' ||
                               SQLERRM);
            END IF;
          END;
          /* CREACION INFORMACION FACTA Y CRS PERSONA NATURUAL*/
        ELSIF P_TIPO_CLIENTE = 'PNA' AND
              (NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN
              ('PRV', 'INU', 'NUE') OR P_ORIGEN_OPERACION IS NOT NULL) THEN
          BEGIN

            MERGE INTO PERSONA_NATURAL PN
            USING dual dd
            ON (PN.PNF_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND PN.PNF_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION))
            WHEN MATCHED THEN
              UPDATE
                 SET PNF_PAI_NACIMIENTO            = P_PAI_NACIMIENTO_FN, --PNF_PAI_NACIMIENTO,
                     PNF_PAI_RESIDENCIA            = NULL, --PNF_PAI_RESIDENCIA
                     PNF_SUBD_CONSECUTIVO          = NULL, --PNF_SUBD_CONSECUTIVO,
                     PNF_MOT_CONSECUTIVO           = P_MOT_CONSECUTIVO_FN, --PNF_MOT_CONSECUTIVO,
                     PNF_TIENE_PASAPORTE_AMERICANO = P_PASAPORTE_AMERICANO_FN, --PNF_TIENE_PASAPORTE_AMERICANO,
                     PNF_NUM_PASAPORTE_AMERICANO   = NULL, --PNF_NUM_PASAPORTE_AMERICANO,
                     PNF_GREEN_CARD                = P_GREEN_CARD_FN, --PNF_GREEN_CARD,
                     PNF_CIUDADANO_AMERICANO       = P_CIUDADANO_AMERICANO_FN, --PNF_CIUDADANO_AMERICANO,
                     PNF_NACIONALIDAD_AMERICANA    = P_NACIONA_AMERICANA_FN, --PNF_NACIONALIDAD_AMERICANA,
                     PNF_PERMANENCIA_182_DIAS      = P_PERMANENCIA_182_DIAS_FN, --PNF_PERMANENCIA_182_DIAS,
                     PNF_PERMANENCIA_122_DIAS      = P_PERMANENCIA_122_DIAS_FN, --PNF_PERMANENCIA_122_DIAS
                     PNF_OTRO_MOTIVO_ESTADIA       = P_OTRO_MOTIVO_ESTADIA_FN, --PNF_OTRO_MOTIVO_ESTADIA,
                     PNF_TIN                       = P_TIN_FN, --PNF_TIN,
                     PNF_ES_RES_LEG_NO_COL         = NULL, --PNF_ES_RES_LEG_NO_COL,
                     PNF_DIRECCION_OTRO_PAIS       = NULL, --PNF_DIRECCION_OTRO_PAIS
                     PNF_CIUDAD_MUNICIPIO          = NULL, --PNF_CIUDAD_MUNICIPIO,
                     PNF_IMPACTADO_FATCA           = P_IMPACTADO_FATCA_FN, --PNF_IMPACTADO_FATCA,
                     PNF_AGE_CODIGO_RESIDE         = P_AGE_CODIGO_RESIDE_FN, --PNF_AGE_CODIGO_RESIDE,
                     PNF_EXENTO_FATCA              = P_EXENTO_FATCA_FN, --PNF_EXENTO_FATCA,
                     PNF_MOTIVO_EXENCION           = P_MOTIVO_EXENCION_FN, --PNF_MOTIVO_EXENCION,
                     PNF_INDICIOS_CRS              = NVL(P_INDICIOS_CRS_FN,
                                                         'N'), --PNF_INDICIOS_CRS,
                     PNF_IMPACTADO_CRS             = P_IMPACTADO_CRS_FN, --PNF_IMPACTADO_CRS,
                     PNF_TIN_CRS1                  = P_TIN_CRS1_FN, --PNF_TIN_CRS1
                     PNF_TIN_CRS2                  = P_TIN_CRS2_FN, --PNF_TIN_CRS2
                     PNF_TIN_CRS3                  = P_TIN_CRS3_FN, --PNF_TIN_CRS3
                     PNF_MOTIVO_NO_TIN1            = P_MOTIVO_NO_TIN1_FN, --PNF_MOTIVO_NO_TIN1
                     PNF_MOTIVO_NO_TIN2            = P_MOTIVO_NO_TIN2_FN, --PNF_MOTIVO_NO_TIN2
                     PNF_MOTIVO_NO_TIN3            = P_MOTIVO_NO_TIN3_FN, --PNF_MOTIVO_NO_TIN3
                     PNF_PAI_FISCAL1               = P_PAI_FISCAL1_FN, --PNF_PAI_FISCAL1
                     PNF_PAI_FISCAL2               = P_PAI_FISCAL2_FN, --PNF_PAI_FISCAL2
                     PNF_PAI_FISCAL3               = P_PAI_FISCAL3_FN --PNF_PAI_FISCAL3


            WHEN NOT MATCHED THEN
              INSERT
                (PNF_PAI_NACIMIENTO,
                 PNF_PAI_RESIDENCIA,
                 PNF_CLI_PER_NUM_IDEN,
                 PNF_CLI_PER_TID_CODIGO,
                 PNF_SUBD_CONSECUTIVO,
                 PNF_MOT_CONSECUTIVO,
                 PNF_TIENE_PASAPORTE_AMERICANO,
                 PNF_NUM_PASAPORTE_AMERICANO,
                 PNF_GREEN_CARD,
                 PNF_CIUDADANO_AMERICANO,
                 PNF_NACIONALIDAD_AMERICANA,
                 PNF_PERMANENCIA_182_DIAS,
                 PNF_PERMANENCIA_122_DIAS,
                 PNF_OTRO_MOTIVO_ESTADIA,
                 PNF_TIN,
                 PNF_ES_RES_LEG_NO_COL,
                 PNF_DIRECCION_OTRO_PAIS,
                 PNF_CIUDAD_MUNICIPIO,
                 PNF_IMPACTADO_FATCA,
                 PNF_AGE_CODIGO_RESIDE,
                 PNF_EXENTO_FATCA,
                 PNF_MOTIVO_EXENCION,
                 PNF_INDICIOS_CRS,
                 PNF_IMPACTADO_CRS,
                 PNF_TIN_CRS1,
                 PNF_TIN_CRS2,
                 PNF_TIN_CRS3,
                 PNF_MOTIVO_NO_TIN1,
                 PNF_MOTIVO_NO_TIN2,
                 PNF_MOTIVO_NO_TIN3,
                 PNF_PAI_FISCAL1,
                 PNF_PAI_FISCAL2,
                 PNF_PAI_FISCAL3)
              VALUES
                (P_PAI_NACIMIENTO_FN, --PNF_PAI_NACIMIENTO,
                 NULL, --PNF_PAI_RESIDENCIA
                 TRIM(P_NUMERO_IDENTIFICACION), --PNF_CLI_PER_NUM_IDEN,
                 TRIM(P_TIPO_IDENTIFICACION), --PNF_CLI_PER_TID_CODIGO,
                 NULL, --PNF_SUBD_CONSECUTIVO,
                 P_MOT_CONSECUTIVO_FN, --PNF_MOT_CONSECUTIVO,
                 P_PASAPORTE_AMERICANO_FN, --PNF_TIENE_PASAPORTE_AMERICANO,
                 NULL, --PNF_NUM_PASAPORTE_AMERICANO,
                 P_GREEN_CARD_FN, --PNF_GREEN_CARD,
                 P_CIUDADANO_AMERICANO_FN, --PNF_CIUDADANO_AMERICANO,
                 P_NACIONA_AMERICANA_FN, --PNF_NACIONALIDAD_AMERICANA,
                 P_PERMANENCIA_182_DIAS_FN, --PNF_PERMANENCIA_182_DIAS,
                 P_PERMANENCIA_122_DIAS_FN, --PNF_PERMANENCIA_122_DIAS
                 P_OTRO_MOTIVO_ESTADIA_FN, --PNF_OTRO_MOTIVO_ESTADIA,
                 P_TIN_FN, --PNF_TIN,
                 NULL, --PNF_ES_RES_LEG_NO_COL,
                 NULL, --PNF_DIRECCION_OTRO_PAIS
                 NULL, --PNF_CIUDAD_MUNICIPIO,
                 P_IMPACTADO_FATCA_FN, --PNF_IMPACTADO_FATCA,
                 P_AGE_CODIGO_RESIDE_FN, --PNF_AGE_CODIGO_RESIDE,
                 P_EXENTO_FATCA_FN, --PNF_EXENTO_FATCA,
                 P_MOTIVO_EXENCION_FN, --PNF_MOTIVO_EXENCION,
                 NVL(P_INDICIOS_CRS_FN, 'N'), --PNF_INDICIOS_CRS,
                 P_IMPACTADO_CRS_FN, --PNF_IMPACTADO_CRS,
                 P_TIN_CRS1_FN, --PNF_TIN_CRS1
                 P_TIN_CRS2_FN, --PNF_TIN_CRS2
                 P_TIN_CRS3_FN, --PNF_TIN_CRS3
                 P_MOTIVO_NO_TIN1_FN, --PNF_MOTIVO_NO_TIN1
                 P_MOTIVO_NO_TIN2_FN, --PNF_MOTIVO_NO_TIN2
                 P_MOTIVO_NO_TIN3_FN, --PNF_MOTIVO_NO_TIN3
                 P_PAI_FISCAL1_FN, --PNF_PAI_FISCAL1
                 P_PAI_FISCAL2_FN, --PNF_PAI_FISCAL2
                 P_PAI_FISCAL3_FN --PNF_PAI_FISCAL3
                 );

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando o actualizando informacion Fatca-CRS- ' ||
                               TRIM(P_NUMERO_IDENTIFICACION) || '-' ||
                               TRIM(P_TIPO_IDENTIFICACION) || ' - ' ||
                               SQLERRM);
            END IF;
          END;
        END IF;

        IF P_TIPO_CLIENTE = 'PJU' THEN
          BEGIN
            V_PJF_SEQ := 0;
            SELECT PJF_SEQ.NEXTVAL INTO V_PJF_SEQ FROM DUAL;
            INSERT INTO PERSONA_JURIDICA
              (PJF_CONSECUTIVO,
               PJF_PAI_CONSTITUCION,
               PJF_CLI_PER_NUM_IDEN,
               PJF_CLI_PER_TID_CODIGO,
               PJF_SUBD_CONSECUTIVO,
               PJF_PAI_CASA_MTX,
               PJF_ES_SUCURSAL_SUBSIDIARIA,
               PJF_RAZON_SOCIAL_CASA_MATRIZ,
               PJF_DIRECCION_CASA_MATRIZ,
               PJF_CIUDAD_MUNICIPIO,
               PJF_COTIZA_BOLSA,
               PJF_TRIBUTA_EN_USA,
               PJF_TIN,
               PJF_ES_PUBLICA,
               PJF_VIGILADA_POR_SFC,
               PJF_GIIN,
               PJF_IMPACTADO_FATCA,
               PJF_AGE_CODIGO_CASA_MTX,
               PJF_EXENTO_FATCA,
               PJF_MOTIVO_EXENCION,
               PJF_TIPO_ENTIDAD,
               PJF_INDICIOS_CRS,
               PJF_IMPACTADO_CRS,
               PJF_TIN_CRS1,
               PJF_TIN_CRS2,
               PJF_TIN_CRS3,
               PJF_MOTIVO_NO_TIN1,
               PJF_MOTIVO_NO_TIN2,
               PJF_MOTIVO_NO_TIN3,
               PJF_PAI_FISCAL1,
               PJF_PAI_FISCAL2,
               PJF_PAI_FISCAL3,
               PJF_TIPO_ENTIDAD_CRS)
            VALUES
              (V_PJF_SEQ, --PJF_CONSECUTIVO
               P_PAI_CONSTITUCION_FJ, --PJF_PAI_CONSTITUCION
               TRIM(P_NUMERO_IDENTIFICACION), --PJF_CLI_PER_NUM_IDEN,
               TRIM(P_TIPO_IDENTIFICACION), --PJF_CLI_PER_TID_CODIGO
               NULL, --PJF_SUBD_CONSECUTIVO,
               NULL, --PJF_PAI_CASA_MTX,
               P_SUCURSAL_SUBSIDIARIA_FJ, --PJF_ES_SUCURSAL_SUBSIDIARIA,
               NULL, --PJF_RAZON_SOCIAL_CASA_MATRIZ,
               P_DIRECCION_MATRIZ_FJ, --PJF_DIRECCION_CASA_MATRIZ,
               NULL, --PJF_CIUDAD_MUNICIPIO,
               P_COTIZA_BOLSA_FJ, --PJF_COTIZA_BOLSA,
               P_TRIBUTA_EN_USA_FJ, --PJF_TRIBUTA_EN_USA,
               P_TIN_FJ, --PJF_TIN,
               P_ES_PUBLICA_FJ, --PJF_ES_PUBLICA,
               P_VIGILADA_POR_SFC_FJ, --PJF_VIGILADA_POR_SFC,
               P_GIIN_FJ, --PJF_GIIN,
               P_IMPACTADO_FATCA_FJ, --PJF_IMPACTADO_FATCA,
               P_AGE_CODIGO_CASA_MTX_FJ, --PJF_AGE_CODIGO_CASA_MTX
               P_EXENTO_FATCA_FJ, --PJF_EXENTO_FATCA
               P_MOTIVO_EXENCION_FJ, --PJF_MOTIVO_EXENCION
               P_TIPO_ENTIDAD_FJ, --PJF_TIPO_ENTIDAD
               P_INDICIOS_CRS_FJ, --PJF_INDICIOS_CRS
               P_IMPACTADO_CRS_FJ, --PJF_IMPACTADO_CRS
               P_TIN_CRS1_FJ, --PJF_TIN_CRS1,
               P_TIN_CRS2_FJ, --PJF_TIN_CRS2
               P_TIN_CRS3_FJ, --PJF_TIN_CRS3
               P_MOTIVO_NO_TIN1_FJ, --PJF_MOTIVO_NO_TIN1
               P_MOTIVO_NO_TIN2_FJ, --PJF_MOTIVO_NO_TIN2
               P_MOTIVO_NO_TIN3_FJ, --PJF_MOTIVO_NO_TIN3
               P_PAI_FISCAL1_FJ, --PJF_PAI_FISCAL1
               P_PAI_FISCAL2_FJ, --PJF_PAI_FISCAL2
               P_PAI_FISCAL3_FJ, --PJF_PAI_FISCAL3
               P_TIPO_ENTIDAD_CRS_FJ --PJF_TIPO_ENTIDAD_CRS
               );

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando persona juridica:' ||
                               TRIM(P_NUMERO_IDENTIFICACION) || '-' ||
                               TRIM(P_TIPO_IDENTIFICACION) || ' - ' ||
                               SQLERRM);
            END IF;
          END;

          /* CREACION INFORMACION ACCIONISTAS*/
          C_ACVI_VINCULA := NULL;
          OPEN ACVI_VINCULA(P_NUMERO_FORMULARIO_VIN,
                            P_NUMERO_IDENTIFICACION,
                            P_TIPO_IDENTIFICACION);
          FETCH ACVI_VINCULA
            INTO C_ACVI_VINCULA;
          IF ACVI_VINCULA%FOUND THEN
            BEGIN
              V_AAC_SEQ := 0;
              SELECT AAC_SEQ.NEXTVAL INTO V_AAC_SEQ FROM DUAL;
              INSERT INTO ANEXOS_ACCIONISTA
                (AAC_CONSECUTIVO,
                 AAC_PJF_CONSECUTIVO,
                 AAC_ES_GRUPO_FAM,
                 AAC_POR_PAR_GRU_FAM,
                 AAC_NUM_ACCIONISTAS,
                 AAC_FILIAL_OTRA_COMPANIA,
                 AAC_JUNTA_DIRECT_SUPLE,
                 AAC_PRESIDENTE_GERENTE,
                 AAC_VARIOS_REP_LEGALES)
              VALUES
                (V_AAC_SEQ, --AAC_CONSECUTIVO,
                 V_PJF_SEQ, --AAC_PJF_CONSECUTIVO,
                 C_ACVI_VINCULA.ACVI_DILIGENCIA_ANEXO_FATCA, --AAC_ES_GRUPO_FAM,
                 C_ACVI_VINCULA.ACVI_PORCENTAJE_PARTIPACION, --AAC_POR_PAR_GRU_FAM,
                 C_ACVI_VINCULA.TOTAL_ACCIONISTAS, --AAC_NUM_ACCIONISTAS,
                 C_ACVI_VINCULA.ACVI_FILIAL_OTRA_COMPANIA, --AAC_FILIAL_OTRA_COMPANIA,
                 C_ACVI_VINCULA.ACVI_JUNTA_DIRECT_SUPLE, --AAC_JUNTA_DIRECT_SUPLE,
                 C_ACVI_VINCULA.ACVI_PRESIDENTE_GERENTE, --AAC_PRESIDENTE_GERENTE,
                 C_ACVI_VINCULA.ACVI_VARIOS_REP_LEGALES --AAC_VARIOS_REP_LEGALES
                 );

              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando anexo accionista :' ||
                                 TRIM(P_TIPO_IDENTIFICACION) || '-' ||
                                 TRIM(P_NUMERO_IDENTIFICACION) || ' - ' ||
                                 SQLERRM);
              END IF;
            END;
          END IF;
          CLOSE ACVI_VINCULA;

          C_ACVI_VINCULA := NULL;
          V_NUM_REGISTRO := 0;
          IF V_ERRORES = 0 THEN
            OPEN ACVI_VINCULA(P_NUMERO_FORMULARIO_VIN,
                              P_NUMERO_IDENTIFICACION,
                              P_TIPO_IDENTIFICACION);
            FETCH ACVI_VINCULA
              INTO C_ACVI_VINCULA;
            WHILE ACVI_VINCULA%FOUND LOOP
              BEGIN
                V_ACC_SEQ      := 0;
                V_NUM_REGISTRO := V_NUM_REGISTRO + 1;
                SELECT ACC_SEQ.NEXTVAL INTO V_ACC_SEQ FROM DUAL;
                INSERT INTO ACCIONISTA
                  (ACC_CONSECUTIVO,
                   ACC_AAC_CONSECUTIVO,
                   ACC_PAI_NACIONALIDAD,
                   ACC_FPA_CONSECUTIVO,
                   ACC_PAI_RESIDENCIA,
                   ACC_MOT_CONSECUTIVO,
                   ACC_NOMBRE,
                   ACC_TIP_IDE_CODIGO,
                   ACC_NUM_IDEN,
                   ACC_NUM_REGISTRO,
                   ACC_POR_PARTICIPACION,
                   ACC_TRIBUTA_EN_USA,
                   ACC_TIENE_PASAPORTE_EEUU,
                   ACC_NUM_PASAPORTE_EEUU,
                   ACC_TIENE_GREEN_CARD,
                   ACC_TIENE_CIUD_EEUU,
                   ACC_TIENE_NAC_EEUU,
                   ACC_PERMANENCIA_182_DIAS,
                   ACC_PERMANENCIA_122_DIAS,
                   ACC_OTRO_MOTIVO_ESTADIA,
                   ACC_TIN,
                   ACC_ES_RES_LEG_NO_COLOMBIA,
                   ACC_DIRECCION_OTRO_PAIS,
                   ACC_CIUDAD_MUNICIPIO,
                   ACC_IMPACTADO_FATCA,
                   ACC_PAI_CODIGO,
                   ACC_PAI_NACIMIENTO,
                   ACC_SUBD_CONSECUTIVO,
                   ACC_AGE_CODIGO_DIRECCION,
                   ACC_EXENTO_FATCA,
                   ACC_MOTIVO_EXENCION,
                   ACC_INDICIOS_CRS,
                   ACC_IMPACTADO_CRS,
                   ACC_TIN_CRS1,
                   ACC_TIN_CRS2,
                   ACC_TIN_CRS3,
                   ACC_MOTIVO_NO_TIN1,
                   ACC_MOTIVO_NO_TIN2,
                   ACC_MOTIVO_NO_TIN3,
                   ACC_PAI_FISCAL1,
                   ACC_PAI_FISCAL2,
                   ACC_PAI_FISCAL3,
                   ACC_FEC_NACIMIENTO,
                   ACC_ROL,
                   ACC_PEP,
                   ACC_RECONOCIDO_PUBLICA,
                   ACC_REP_LEGAL_INTERNA,
                   ACC_POLITICA_EXPUESTA,
                   ACC_GRADO_PARANTESCO,
                   ACC_CARGO,
                   ACC_FECHA_CARGO,
                   ACC_FECHA_DESVINCULA,
                   ACC_NOMBRE_FAMILIAR,
                   ACC_PRIMER_APELLIDO,
                   ACC_SEGUNDO_APELLIDO)
                VALUES
                  (V_ACC_SEQ, --ACC_CONSECUTIVO,
                   V_AAC_SEQ, --ACC_AAC_CONSECUTIVO,
                   NULL, --ACC_PAI_NACIONALIDAD,
                   NULL, --ACC_FPA_CONSECUTIVO,
                   NULL, --ACC_PAI_RESIDENCIA,
                   NULL, --ACC_MOT_CONSECUTIVO,
                   C_ACVI_VINCULA.ACVI_NOMBRE_RAZON_SOCIAL, --ACC_NOMBRE,
                   C_ACVI_VINCULA.ACVI_TIP_IDE_CODIGO, --ACC_TIP_IDE_CODIGO,
                   C_ACVI_VINCULA.ACVI_NUM_IDEN, --ACC_NUM_IDEN,
                   V_NUM_REGISTRO, --ACC_NUM_REGISTRO,
                   C_ACVI_VINCULA.ACVI_POR_PARTICIPACION, --ACC_POR_PARTICIPACION,
                   C_ACVI_VINCULA.ACVI_TRIBUTA_EN_USA, --ACC_TRIBUTA_EN_USA,
                   NULL, --ACC_TIENE_PASAPORTE_EEUU,
                   NULL, --ACC_NUM_PASAPORTE_EEUU,
                   NULL, --ACC_TIENE_GREEN_CARD,
                   NULL, --ACC_TIENE_CIUD_EEUU,
                   NULL, --ACC_TIENE_NAC_EEUU,
                   NULL, --ACC_PERMANENCIA_182_DIAS,
                   NULL, --ACC_PERMANENCIA_122_DIAS,
                   NULL, --ACC_OTRO_MOTIVO_ESTADIA,
                   C_ACVI_VINCULA.ACVI_TIN, --ACC_TIN,
                   NULL, --ACC_ES_RES_LEG_NO_COLOMBIA,
                   C_ACVI_VINCULA.ACVI_DIRECCION_OTRO_PAIS, --ACC_DIRECCION_OTRO_PAIS,
                   NULL, --ACC_CIUDAD_MUNICIPIO,
                   C_ACVI_VINCULA.ACVI_IMPACTADO_FATCA, --ACC_IMPACTADO_FATCA,
                   NULL, --ACC_PAI_CODIGO,
                   C_ACVI_VINCULA.ACVI_PAI_NACIMIENTO, --ACC_PAI_NACIMIENTO,
                   NULL, --ACC_SUBD_CONSECUTIVO,
                   C_ACVI_VINCULA.ACVI_CIUDAD_RESIDENCIA, --ACC_AGE_CODIGO_DIRECCION,
                   C_ACVI_VINCULA.ACVI_EXENTO_FATCA, --ACC_EXENTO_FATCA,
                   C_ACVI_VINCULA.ACVI_MOTIVO_EXENCION, --ACC_MOTIVO_EXENCION,
                   C_ACVI_VINCULA.ACVI_INDICIOS_CRS, --ACC_INDICIOS_CRS,
                   C_ACVI_VINCULA.ACVI_IMPACTADO_CRS, --ACC_IMPACTADO_CRS,
                   C_ACVI_VINCULA.ACVI_TIN_CRS1, --ACC_TIN_CRS1,
                   C_ACVI_VINCULA.ACVI_TIN_CRS2, --ACC_TIN_CRS2,
                   C_ACVI_VINCULA.ACVI_TIN_CRS3, --ACC_TIN_CRS3,
                   C_ACVI_VINCULA.ACVI_MOTIVO_NO_TIN1, --ACC_MOTIVO_NO_TIN1,
                   C_ACVI_VINCULA.ACVI_MOTIVO_NO_TIN2, --ACC_MOTIVO_NO_TIN2,
                   C_ACVI_VINCULA.ACVI_MOTIVO_NO_TIN3, --ACC_MOTIVO_NO_TIN3,
                   C_ACVI_VINCULA.ACVI_PAI_FISCAL1, --ACC_PAI_FISCAL1,
                   C_ACVI_VINCULA.ACVI_PAI_FISCAL2, --ACC_PAI_FISCAL2,
                   C_ACVI_VINCULA.ACVI_PAI_FISCAL3, --ACC_PAI_FISCAL3,
                   C_ACVI_VINCULA.ACVI_FEC_NACIMIENTO, --ACC_FEC_NACIMIENTO,
                   C_ACVI_VINCULA.ACVI_ROL, --ACC_ROL,
                   C_ACVI_VINCULA.ACVI_PEP, --ACC_PEP,
                   C_ACVI_VINCULA.ACVI_RECONOCIDO_PUBLICA, --ACC_RECONOCIDO_PUBLICA,
                   C_ACVI_VINCULA.ACVI_REP_LEGAL_INTERNA, --ACC_REP_LEGAL_INTERNA,
                   C_ACVI_VINCULA.ACVI_POLITICA_EXPUESTA, --ACC_POLITICA_EXPUESTA,
                   C_ACVI_VINCULA.ACVI_GRADO_PARANTESCO, --ACC_GRADO_PARANTESCO,
                   C_ACVI_VINCULA.ACVI_CARGO, --ACC_CARGO,
                   C_ACVI_VINCULA.ACVI_FECHA_CARGO, --ACC_FECHA_CARGO,
                   C_ACVI_VINCULA.ACVI_FECHA_DESVINCULA, --ACC_FECHA_DESVINCULA,
                   C_ACVI_VINCULA.ACVI_NOMBRE_FAMILIAR, --ACC_NOMBRE_FAMILIAR,
                   C_ACVI_VINCULA.ACVI_PRIMER_APELLIDO, --ACC_PRIMER_APELLIDO,
                   C_ACVI_VINCULA.ACVI_SEGUNDO_APELLIDO --ACC_SEGUNDO_APELLIDO,
                   );

                IF SQL%ROWCOUNT = 0 THEN
                  V_ERRORES             := V_ERRORES + 1;
                  P_FORMULARIO_APERTURA := NULL;
                  P_CAB.CrearError('Error creando accionista :' ||
                                   TRIM(C_ACVI_VINCULA.ACVI_TIP_IDE_CODIGO) || '-' ||
                                   TRIM(C_ACVI_VINCULA.ACVI_NUM_IDEN) ||
                                   ' - ' || SQLERRM);
                END IF;
              END;
              FETCH ACVI_VINCULA
                INTO C_ACVI_VINCULA;
            END LOOP;
            CLOSE ACVI_VINCULA;
          END IF;
        END IF;

        /* CREACION DE SEGUDOS TITULARES*/
        OPEN SETV_VINCULA(P_NUMERO_FORMULARIO_VIN,
                          P_NUMERO_IDENTIFICACION,
                          P_TIPO_IDENTIFICACION);
        FETCH SETV_VINCULA
          INTO C_SETV_VINCULA;
        WHILE SETV_VINCULA%FOUND LOOP

          V_COMERCIAL_VALIDA := 'N';
          OPEN COMERCIAL_VALIDA(TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN),
                                TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO));
          FETCH COMERCIAL_VALIDA
            INTO V_COMERCIAL_VALIDA;
          CLOSE COMERCIAL_VALIDA;

          V_COMERCIAL_VALIDA := NVL(V_COMERCIAL_VALIDA, 'N');

          IF V_COMERCIAL_VALIDA = 'S' THEN
            V_ERRORES             := V_ERRORES + 1;
            P_FORMULARIO_APERTURA := NULL;
            P_CAB.CrearError('No es posible relacionar persona como posible segundo titular, esta definido como usuario interno');
            RAISE V_ERROR_CREACION;
          END IF;

          C_VALIDA_CLIENTE := NULL;
          OPEN VALIDA_CLIENTE(TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN),
                              TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO));
          FETCH VALIDA_CLIENTE
            INTO C_VALIDA_CLIENTE;
          CLOSE VALIDA_CLIENTE;

          C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE := NVL(C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE,
                                                   'N');

          IF C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE = 'N' THEN
            /* Creacion de segundo como persona*/
            BEGIN
              INSERT INTO PERSONAS
                (PER_NUM_IDEN,
                 PER_TID_CODIGO,
                 PER_TIPO,
                 PER_RAZON_SOCIAL,
                 PER_DIGITO_CONTROL,
                 PER_PRIMER_APELLIDO,
                 PER_SEGUNDO_APELLIDO,
                 PER_NOMBRE,
                 PER_SEXO,
                 PER_ES_CORREDOR,
                 PER_NOMBRE_USUARIO,
                 PER_INICIALES_USUARIO,
                 PER_SUC_CODIGO,
                 PER_CPR_MNEMONICO,
                 PER_MAIL_CORREDOR,
                 PER_TIPO_COMERCIAL,
                 PER_EJECUTA_ORDEN_MESA,
                 PER_PER_NUM_IDEN,
                 PER_PER_TID_CODIGO,
                 PER_CCT_MNEMONICO,
                 PER_ESTADO,
                 PER_CLF_SECUENCIAL,
                 PER_TELEFONO_DIRECTO,
                 PER_CODIGO_BOLSA,
                 PER_COMERCIAL_ACC_DIRECTO,
                 PER_CODIGO_SAE_ACC,
                 PER_COMPLEMENTACION,
                 PER_COMERCIAL_OPX,
                 PER_USUARIO_DECEVAL,
                 PER_ID_USUARIO_DECEVAL,
                 PER_CODIGO_SIOPEL,
                 PER_CODIGO_XSTREAM,
                 PER_NOTIFICA_CENLINEA,
                 PER_TIP_COMERCIAL_UDF,
                 PER_ORIGEN)
              VALUES
                (TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN) --PER_NUM_IDEN
                ,
                 TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO) --PER_TID_CODIGO
                ,
                 'PNA' --PER_TIPO
                ,
                 NULL --PER_RAZON_SOCIAL
                ,
                 NULL --PER_DIGITO_CONTROL
                ,
                 UPPER(TRIM(C_SETV_VINCULA.SETV_PRIMER_APELLIDO)) --PER_PRIMER_APELLIDO
                ,
                 UPPER(TRIM(C_SETV_VINCULA.SETV_SEGUNDO_APELLIDO)) --PER_SEGUNDO_APELLIDO
                ,
                 UPPER(TRIM(C_SETV_VINCULA.SETV_NOMBRE)) --PER_NOMBRE
                ,
                 C_SETV_VINCULA.SETV_TIPO_SEXO --PER_SEXO
                ,
                 NULL --PER_ES_CORREDOR
                ,
                 NULL --PER_NOMBRE_USUARIO
                ,
                 NULL --PER_INICIALES_USUARIO
                ,
                 NULL --PER_SUC_CODIGO
                ,
                 NULL --PER_CPR_MNEMONICO
                ,
                 NULL --PER_MAIL_CORREDOR
                ,
                 NULL --PER_TIPO_COMERCIAL
                ,
                 NULL --PER_EJECUTA_ORDEN_MESA
                ,
                 NULL --PER_PER_NUM_IDEN
                ,
                 NULL --PER_PER_TID_CODIGO
                ,
                 NULL --PER_CCT_MNEMONICO
                ,
                 NULL --PER_ESTADO
                ,
                 NULL --PER_CLF_SECUENCIAL
                ,
                 NULL --PER_TELEFONO_DIRECTO
                ,
                 NULL --PER_CODIGO_BOLSA
                ,
                 NULL --PER_COMERCIAL_ACC_DIRECTO
                ,
                 NULL --PER_CODIGO_SAE_ACC
                ,
                 NULL --PER_COMPLEMENTACION
                ,
                 NULL --PER_COMERCIAL_OPX
                ,
                 NULL --PER_USUARIO_DECEVAL
                ,
                 NULL --PER_ID_USUARIO_DECEVAL
                ,
                 NULL --PER_CODIGO_SIOPEL
                ,
                 NULL --PER_CODIGO_XSTREAM
                ,
                 NULL --PER_NOTIFICA_CENLINEA
                ,
                 NULL --PER_TIP_COMERCIAL_UDF
                ,
                 DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                        'N',
                        'VIN',
                        'VID') --PER_ORIGEN
                 );
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
              END IF;

            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;

              WHEN OTHERS THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
                P_CAB.CrearError('Error creando persona segundo titular.');
                RAISE V_ERROR_CREACION;
            END;

            IF V_ERRORES = 0 THEN
              V_BCC_CLIENTE := NULL;
              V_BSC_CLIENTE := NULL;
              V_BCC_ALT     := NULL;
              V_BSC_ALT     := NULL;

              V_FORMULARIO_SEGUNDO := P_INTEGRACION.FN_FORMULARIO_APERTURA();

              P_CLIENTES.PR_SEGMENTACION_INICIAL(TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN),
                                                 TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO),
                                                 P_TIPO_CLIENTE,
                                                 'N',
                                                 NULL,
                                                 NULL,
                                                 V_BCC_CLIENTE,
                                                 V_BSC_CLIENTE,
                                                 V_BCC_ALT,
                                                 V_BSC_ALT);

              BEGIN
                INSERT INTO CLIENTES
                  (CLI_PER_NUM_IDEN,
                   CLI_PER_TID_CODIGO,
                   CLI_ECL_MNEMONICO,
                   CLI_TEC_MNEMONICO,
                   CLI_FECHA_APERTURA,
                   CLI_FECHA_ULTIMA_ACTUALIZACION,
                   CLI_USUARIO_ULTIMA_ACTUALIZACI,
                   CLI_AUTORIZA_PLAZO,
                   CLI_AUTORIZA_REPO,
                   CLI_AUTORIZA_SWAP,
                   CLI_AUTORIZA_CARRUSEL,
                   CLI_AUTORIZA_CONTRATO_COMISION,
                   CLI_AUTORIZA_ADMON_VALORES,
                   CLI_EXCENTO_DXM_FONDOS,
                   CLI_HABILITADO_INTERNET,
                   CLI_EXCENTO_IVA,
                   CLI_TIPO_CLIENTE,
                   CLI_ULTIMA_OPERACION_EJECUTADA,
                   CLI_CLAVE_INTERNET,
                   CLI_NIC,
                   CLI_REFERENCIADO,
                   CLI_DIRECCION_OFICINA,
                   CLI_AGE_CODIGO_TRABAJA,
                   CLI_TELEFONO_OFICINA,
                   CLI_DIRECCION_RESIDENCIA,
                   CLI_AGE_CODIGO_RESIDE,
                   CLI_TELEFONO_RESIDENCIA
                   --,CLI_DIRECCION_EMAIL
                  ,
                   CLI_FAX,
                   CLI_APARTADO_AEREO,
                   CLI_NUMERO_CONTRATO_DCVAL,
                   CLI_NUMERO_CONTRATO_DCV,
                   CLI_ECI_MNEMONICO,
                   CLI_NAC_MNEMONICO,
                   CLI_FECHA_NACIMIENTO,
                   CLI_AGE_CODIGO,
                   CLI_OCUPACION,
                   CLI_ORE_MNEMONICO,
                   CLI_OTRO_ORIGEN_RECURSOS,
                   CLI_TITULO_UNIVER,
                   CLI_EMPRESA,
                   CLI_CARGO,
                   CLI_RIM_CODIGO,
                   CLI_RPA_CODIGO,
                   CLI_EXTRANJERO,
                   CLI_AGE_CODIGO_NACION,
                   CLI_GRAN_CONTRIBUYENTE,
                   CLI_AUTORRETENEDOR,
                   CLI_SUJETO_RTEFTE,
                   CLI_TEN_CODIGO,
                   CLI_NUMERO_ESCRITURA,
                   CLI_FECHA_ESCRITURA,
                   CLI_NTR_CODIGO,
                   CLI_NTR_AGE_CODIGO,
                   CLI_REGISTRO_CAMARA,
                   CLI_FECHA_REGCAMARA,
                   CLI_ACTIVIDAD_ECONOMICA,
                   CLI_DOMICILIO_PRINCIPAL,
                   CLI_AGE_CODIGO_PPAL,
                   CLI_SEC_MNEMONICO,
                   CLI_RECURSOS_ACT_PRINC,
                   CLI_NUM_ULT_REF_ESCRITURA,
                   CLI_FEC_ULT_REF_ESCRITURA,
                   CLI_NTR_CODIGO_ES_MODIFICADA,
                   CLI_NTR_AGE_CODIGO_ES_MODIFICA,
                   CLI_CAPITAL_AUTORIZADO,
                   CLI_CAPITAL_SUSCRITO,
                   CLI_CATEGORIA_CLIENTE_INST,
                   CLI_CONTACTO_CLIENTE_INST,
                   CLI_TELEFONO_CONTACTO_INST,
                   CLI_OBSERV_CLIENTE_INST,
                   CLI_FEC_EXPEDICION_CAMARA,
                   CLI_FEC_EXPEDICION_DOC_ID,
                   CLI_AGE_CODIGO_EXP_DOC,
                   CLI_CODIGO_SEBRA,
                   CLI_CARACTER_ENTIDAD,
                   CLI_ACT_MNEMONICO,
                   CLI_FORMULARIO_APERTURA,
                   CLI_USUARIO_APERTURA,
                   CLI_FORMULARIO_ACTUALIZACION,
                   CLI_FECHA_ULTIMA_MODIFICACION,
                   CLI_USUARIO_ULTIMA_MODIFICA,
                   CLI_OTRO_TIPO_EMPRESA,
                   CLI_RECURSOS_BIENES_ENTREGAR,
                   CLI_OTRO_RECURSOS_BIENES_ENT,
                   CLI_OTRO_DETALLE_ACTIVIDAD,
                   CLI_OTRO_TIPO_ENVIO_CORRES,
                   CLI_PAGINA_WEB,
                   CLI_FECHA_CONSTITUCION,
                   CLI_MOI_MNEMONICO,
                   CLI_RESPUESTA_WEB,
                   CLI_PRW_CODIGO,
                   CLI_EXCENTO_REPORTE_EFECTIVO,
                   CLI_RAZON_EXCEPCION,
                   CLI_AUTORIZA_TRANS_ACH,
                   CLI_ENVIA_REMISION,
                   CLI_ENVIA_FACTURA_DIV,
                   CLI_ADM_PORTAFOLIO_DCVAL,
                   CLI_ADM_PORTAFOLIO_DCV,
                   CLI_GENERAR_CONSTANCIA,
                   CLI_EXPERIENCIA_SECTOR_PUBLICO,
                   CLI_CAMPANA_POLITICA,
                   CLI_MOTIVO_ES_CLIENTE,
                   CLI_RETENCION_FONDO,
                   CLI_SUJETO_RTEFTE_FONDO,
                   CLI_PROFESIONAL,
                   CLI_BSC_BCC_MNEMONICO,
                   CLI_BSC_MNEMONICO,
                   CLI_RADICACION_PROFESIONAL,
                   CLI_CELULAR,
                   CLI_UNICA_OPERACION,
                   CLI_PERFIL_RIESGO,
                   CLI_CONTRATO_MARCO_COMISION
                   --,CLI_DIRECCION_EMAIL_ALTERNA
                  ,
                   CLI_DECLARA_RENTA,
                   CLI_RECURSOS_PUBLICOS,
                   CLI_RECONOCIMIENTO_PUBLICO,
                   CLI_CAMPO_RECONOCIMIENTO,
                   CLI_INICIO_COBRO_ADMON_VALORES,
                   CLI_PAPELETAS_DIARIAS,
                   CLI_ADR_PROGRAM,
                   CLI_FECHA_ULT_MOD_MASIVA,
                   CLI_CNU_MNEMONICO,
                   CLI_EXCENTO_REPORTE_DIVISAS,
                   CLI_COMPARTIR_INFORMACION,
                   CLI_ENVIO_DE_CORREO_MASIVO,
                   CLI_OPX,
                   CLI_FECHA_OPX,
                   CLI_NO_OPX,
                   CLI_EN_ACTUALIZACION_LINEA,
                   CLI_MONEDA_EXT,
                   CLI_CLSO_MNEMONICO,
                   CLI_PSC_MNEMONICO,
                   CLI_MIGRADO_DAVIVALORES,
                   CLI_INSTITUCIONAL_EXTRANJERO,
                   CLI_VIGILADO_SFC,
                   CLI_BSC_BCC_MNEMONICO_ALT,
                   CLI_BSC_MNEMONICO_ALT,
                   CLI_RIESGO_LAFT,
                   CLI_INDICIO_FATCA,
                   CLI_BANCA_PRIVADA,
                   CLI_FORMULARIO_VINCULACION,
                   CLI_ESTADO_VINCULACION,
                   CLI_CUENTA_FIN_EXTRA,
                   CLI_ES_FIDEICOMI,
                   CLI_NOMBRE_FIDEICOMISO,
                   CLI_NIT_FIDEICOMISO,
                   CLI_FIDU_ADMIN_FIDEICOMISO,
                   CLI_PROPOSITO_COMISIONISTA,
                   CLI_MONTO_INICIAL_INVERSION --CLI_MONTO_APROX_INVERSION
                  ,
                   CLI_ORG_INTERNA_PEP,
                   CLI_GRADO_CONSANGUI_PEP2,
                   CLI_GRADO_CONSANGUI_PEP3,
                   CLI_NOMBRE_FAMILIAR_PEP2,
                   CLI_NOMBRE_FAMILIAR_PEP3,
                   CLI_NUM_ID_FAMILIAR_PEP2,
                   CLI_NUM_ID_FAMILIAR_PEP3,
                   CLI_PRIMER_APELLIDO_PEP2,
                   CLI_PRIMER_APELLIDO_PEP3,
                   CLI_SEGUNDO_APELLIDO_PEP2,
                   CLI_SEGUNDO_APELLIDO_PEP3,
                   CLI_TID_COD_FAMILIAR_PEP2,
                   CLI_TID_COD_FAMILIAR_PEP3)
                VALUES
                  (TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN) --*CLI_PER_NUM_IDEN
                  ,
                   TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO) --*CLI_PER_TID_CODIGO
                  ,
                   DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                          'N',
                          'ACC',
                          'INA') --CLI_ECL_MNEMONICO
                  ,
                   'NN' --CLI_TEC_MNEMONICO
                  ,
                   SYSDATE --CLI_FECHA_APERTURA
                  ,
                   SYSDATE --CLI_FECHA_ULTIMA_ACTUALIZACION
                  ,
                   USER --CLI_USUARIO_ULTIMA_ACTUALIZACI
                  ,
                   'S' --CLI_AUTORIZA_PLAZO
                  ,
                   'S' --CLI_AUTORIZA_REPO
                  ,
                   'S' --CLI_AUTORIZA_SWAP
                  ,
                   'S' --CLI_AUTORIZA_CARRUSEL
                  ,
                   'S' --CLI_AUTORIZA_CONTRATO_COMISION
                  ,
                   'N' --CLI_AUTORIZA_ADMON_VALORES
                  ,
                   'N' --CLI_EXCENTO_DXM_FONDOS
                  ,
                   'I' --CLI_HABILITADO_INTERNET
                  ,
                   'N' --CLI_EXCENTO_IVA
                  ,
                   'S' --CLI_TIPO_CLIENTE                                                 --CLIENTE
                  ,
                   'AP' --CLI_ULTIMA_OPERACION_EJECUTADA
                  ,
                   NULL --CLI_CLAVE_INTERNET
                  ,
                   NULL --CLI_NIC
                  ,
                   NULL --*CLI_REFERENCIADO
                  ,
                   C_SETV_VINCULA.SETV_DIRECCION_OFICINA --*CLI_DIRECCION_OFICINA
                  ,
                   C_SETV_VINCULA.SETV_CIUDAD_OFICINA --CLI_AGE_CODIGO_TRABAJA
                  ,
                   C_SETV_VINCULA.SETV_TELEFONO_OFICINA --CLI_TELEFONO_OFICINA
                  ,
                   C_SETV_VINCULA.SETV_DIRECCION_RESIDENCIA --*CLI_DIRECCION_RESIDENCIA
                  ,
                   C_SETV_VINCULA.SETV_CIUDAD_RESIDENCIA --*CLI_AGE_CODIGO_RESIDE
                  ,
                   C_SETV_VINCULA.SETV_TELEFONO_RESIDENCIA --*CLI_TELEFONO_RESIDENCIA
                   --,C_SETV_VINCULA.SETV_DIRECCION_EMAIL              --*CLI_DIRECCION_EMAIL
                  ,
                   C_SETV_VINCULA.SETV_FAX --CLI_FAX
                  ,
                   NULL --CLI_APARTADO_AEREO
                  ,
                   NULL --CLI_NUMERO_CONTRATO_DCVAL
                  ,
                   NULL --CLI_NUMERO_CONTRATO_DCV
                  ,
                   C_SETV_VINCULA.SETV_ESTADO_CIVIL --*CLI_ECI_MNEMONICO
                  ,
                   C_SETV_VINCULA.SETV_NACIONALIDAD --*CLI_NAC_MNEMONICO
                  ,
                   C_SETV_VINCULA.SETV_FECHA_NACIMIENTO --*CLI_FECHA_NACIMIENTO
                  ,
                   C_SETV_VINCULA.SETV_CIUDAD_NACIMIENTO --*CLI_AGE_CODIGO
                  ,
                   NULL --CLI_OCUPACION
                  ,
                   C_SETV_VINCULA.SETV_ORIGEN_RECURSOS --*CLI_ORE_MNEMONICO
                  ,
                   C_SETV_VINCULA.SETV_OTRO_ORIGEN_RECURSOS --*CLI_OTRO_ORIGEN_RECURSOS
                  ,
                   NULL --CLI_TITULO_UNIVER
                  ,
                   C_SETV_VINCULA.SETV_EMPRESA --CLI_EMPRESA
                  ,
                   C_SETV_VINCULA.SETV_CARGO --*CLI_CARGO
                  ,
                   NULL --CLI_RIM_CODIGO
                  ,
                   NULL --CLI_RPA_CODIGO
                  ,
                   'N' --*CLI_EXTRANJERO
                  ,
                   NULL --*CLI_AGE_CODIGO_NACION
                  ,
                   'N' --*CLI_GRAN_CONTRIBUYENTE
                  ,
                   'N' --CLI_AUTORRETENEDOR
                  ,
                   'S' --*CLI_SUJETO_RTEFTE
                  ,
                   99 --*CLI_TEN_CODIGO
                  ,
                   NULL --CLI_NUMERO_ESCRITURA
                  ,
                   NULL --CLI_FECHA_ESCRITURA
                  ,
                   NULL --CLI_NTR_CODIGO
                  ,
                   NULL --CLI_NTR_AGE_CODIGO
                  ,
                   NULL --CLI_REGISTRO_CAMARA
                  ,
                   NULL --CLI_FECHA_REGCAMARA
                  ,
                   NULL --*CLI_ACTIVIDAD_ECONOMICA
                  ,
                   NULL --CLI_DOMICILIO_PRINCIPAL
                  ,
                   NULL --CLI_AGE_CODIGO_PPAL
                  ,
                   NULL --CLI_SEC_MNEMONICO
                  ,
                   NULL --CLI_RECURSOS_ACT_PRINC
                  ,
                   NULL --CLI_NUM_ULT_REF_ESCRITURA
                  ,
                   NULL --CLI_FEC_ULT_REF_ESCRITURA
                  ,
                   NULL --CLI_NTR_CODIGO_ES_MODIFICADA
                  ,
                   NULL --CLI_NTR_AGE_CODIGO_ES_MODIFICA
                  ,
                   NULL --CLI_CAPITAL_AUTORIZADO
                  ,
                   NULL --CLI_CAPITAL_SUSCRITO
                  ,
                   NULL --CLI_CATEGORIA_                                                 --CLIENTE_INST
                  ,
                   NULL --CLI_CONTACTO_                                                 --CLIENTE_INST
                  ,
                   NULL --CLI_TELEFONO_CONTACTO_INST
                  ,
                   NULL --CLI_OBSERV_                                                 --CLIENTE_INST
                  ,
                   NULL --CLI_FEC_EXPEDICION_CAMARA
                  ,
                   C_SETV_VINCULA.SETV_FECHA_EXP_DOCUMENTO --*CLI_FEC_EXPEDICION_DOC_ID
                  ,
                   C_SETV_VINCULA.SETV_CIUDAD_EXP_DOCUMENTO --*CLI_AGE_CODIGO_EXP_DOC
                  ,
                   NULL --CLI_CODIGO_SEBRA
                  ,
                   4 --*CLI_CARACTER_ENTIDAD
                  ,
                   C_SETV_VINCULA.SETV_ACTIVIDAD --*CLI_ACT_MNEMONICO
                  ,
                   V_FORMULARIO_SEGUNDO --CLI_FORMULARIO_APERTURA
                  ,
                   USER --CLI_USUARIO_APERTURA
                  ,
                   NULL --CLI_FORMULARIO_ACTUALIZACION
                  ,
                   NULL --CLI_FECHA_ULTIMA_MODIFICACION
                  ,
                   NULL --CLI_USUARIO_ULTIMA_MODIFICA
                  ,
                   NULL --CLI_OTRO_TIPO_EMPRESA
                  ,
                   DECODE(C_SETV_VINCULA.SETV_RECURSOS_ENTREGAR,
                          'Dinero',
                          'D',
                          'Otro',
                          'O') --*CLI_RECURSOS_BIENES_ENTREGAR
                  ,
                   C_SETV_VINCULA.SETV_OTRO_RECURSOS_ENTREGAR --*CLI_OTRO_RECURSOS_BIENES_ENT
                  ,
                   NULL --CLI_OTRO_DETALLE_ACTIVIDAD
                  ,
                   NULL --CLI_OTRO_TIPO_ENVIO_CORRES
                  ,
                   NULL --CLI_PAGINA_WEB
                  ,
                   NULL --*CLI_FECHA_CONSTITUCION
                  ,
                   NULL --CLI_MOI_MNEMONICO
                  ,
                   NULL --CLI_RESPUESTA_WEB
                  ,
                   NULL --CLI_PRW_CODIGO
                  ,
                   NULL --CLI_EXCENTO_REPORTE_EFECTIVO
                  ,
                   NULL --CLI_RAZON_EXCEPCION
                  ,
                   'S' --CLI_AUTORIZA_TRANS_ACH
                  ,
                   NULL --CLI_ENVIA_REMISION
                  ,
                   NULL --CLI_ENVIA_FACTURA_DIV
                  ,
                   'N' --CLI_ADM_PORTAFOLIO_DCVAL
                  ,
                   'N' --CLI_ADM_PORTAFOLIO_DCV
                  ,
                   'N' --*CLI_GENERAR_CONSTANCIA
                  ,
                   C_SETV_VINCULA.SETV_EXPERIENCIA_SECTOR_PU --CLI_EXPERIENCIA_SECTOR_PUBLICO
                  ,
                   'N' --CLI_CAMPANA_POLITICA
                  ,
                   'CP' --CLI_MOTIVO_ES_CLIENTE
                  ,
                   NULL --CLI_RETENCION_FONDO
                  ,
                   'S' --CLI_SUJETO_RTEFTE_FONDO
                  ,
                   'N' --CLI_PROFESIONAL
                  ,
                   V_BCC_CLIENTE --CLI_BSC_BCC_MNEMONICO
                  ,
                   V_BSC_CLIENTE --CLI_BSC_MNEMONICO
                  ,
                   NULL --CLI_RADICACION_PROFESIONAL
                  ,
                   C_SETV_VINCULA.SETV_CELULAR --CLI_CELULAR
                  ,
                   'N' --CLI_UNICA_OPERACION
                  ,
                   NULL --CLI_PERFIL_RIESGO Moderado = 20
                  ,
                   NULL --CLI_CONTRATO_MARCO_COMISION
                   --,NULL                                             --CLI_DIRECCION_EMAIL_ALTERNA
                  ,
                   'N' --*CLI_DECLARA_RENTA
                  ,
                   P_ADMIN_REC_PUBLICOS --'N'                                              --CLI_RECURSOS_PUBLICOS
                  ,
                   'N' --CLI_RECONOCIMIENTO_PUBLICO
                  ,
                   NULL --CLI_CAMPO_RECONOCIMIENTO
                  ,
                   NULL --CLI_INICIO_COBRO_ADMON_VALORES
                  ,
                   NULL --CLI_PAPELETAS_DIARIAS
                  ,
                   'N' --CLI_ADR_PROGRAM
                  ,
                   NULL --CLI_FECHA_ULT_MOD_MASIVA
                  ,
                   C_SETV_VINCULA.SETV_CODIGO_CIIU --*CLI_CNU_MNEMONICO
                  ,
                   NULL --CLI_EXCENTO_REPORTE_DIVISAS
                  ,
                   NULL --CLI_COMPARTIR_INFORMACION
                  ,
                   NULL --CLI_ENVIO_DE_CORREO_MASIVO
                  ,
                   'N' --CLI_OPX
                  ,
                   NULL --CLI_FECHA_OPX
                  ,
                   'N' --CLI_NO_OPX
                  ,
                   NULL --CLI_EN_ACTUALIZACION_LINEA
                  ,
                   'N' --CLI_MONEDA_EXT
                  ,
                   NULL --*CLI_CLSO_MNEMONICO
                  ,
                   C_SETV_VINCULA.SETV_PROFESION --*CLI_PSC_MNEMONICO
                  ,
                   NULL --CLI_MIGRADO_DAVIVALORES
                  ,
                   NULL --CLI_INSTITUCIONAL_EXTRANJERO
                  ,
                   NULL --CLI_VIGILADO_SFC
                  ,
                   V_BCC_ALT --CLI_BSC_BCC_MNEMONICO_ALT
                  ,
                   V_BSC_ALT --CLI_BSC_MNEMONICO_ALT
                  ,
                   NULL --CLI_RIESGO_LAFT
                  ,
                   'N' --CLI_INDICIO_FATCA
                  ,
                   'N' --CLI_BANCA_PRIVADA
                  ,
                   P_NUMERO_FORMULARIO_VIN --CLI_FORMULARIO_VINCULACION
                  ,
                   P_ESTADO_VINCULACION_DIGITAL --CLI_ESTADO_VINCULACION
                  ,
                   P_CUENTASFINEXTRA,
                   P_FIDEICOMITENTE,
                   P_NOMBREFIDEICOMISO,
                   P_NITFIDEICOMISO,
                   P_FIDUADMINFIDEICOMISO,
                   P_PROPOSITOCOMISIONISTA,
                   P_MONTOAPROXINVERSION,
                   P_ORG_INTERNA_PEP,
                   P_GRADO_CONSANGUI_PEP2,
                   P_GRADO_CONSANGUI_PEP3,
                   P_NOMBRE_FAMILIAR_PEP2,
                   P_NOMBRE_FAMILIAR_PEP3,
                   P_NUM_ID_FAMILIAR_PEP2,
                   P_NUM_ID_FAMILIAR_PEP3,
                   P_PRIMER_APELLIDO_PEP2,
                   P_PRIMER_APELLIDO_PEP3,
                   P_SEGUNDO_APELLIDO_PEP2,
                   P_SEGUNDO_APELLIDO_PEP3,
                   P_TID_COD_FAMILIAR_PEP2,
                   P_TID_COD_FAMILIAR_PEP3);

                IF C_SETV_VINCULA.SETV_DIRECCION_EMAIL IS NOT NULL OR
                   C_SETV_VINCULA.SETV_DIRECCION_EMAIL != '' THEN

                  BEGIN
                    P_CORREOS_COEASY.P_INSERTA_CORREO_CLI(P_ID      => TRIM(TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO)),
                                                          P_NIT     => TRIM(TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN)),
                                                          P_TIPO    => 'P',
                                                          P_CORREOS => C_SETV_VINCULA.SETV_DIRECCION_EMAIL);
                  EXCEPTION
                    WHEN OTHERS THEN
                      V_ERRORES             := V_ERRORES + 1;
                      P_FORMULARIO_APERTURA := NULL;
                      P_CAB.CrearError('Error creando correo principal de segundo titular cliente - ' ||
                                       TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO) || '-' ||
                                       TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN) ||
                                       ' - ' || SQLERRM);
                  END;

                END IF;

                IF SQL%ROWCOUNT = 0 THEN
                  V_ERRORES             := V_ERRORES + 1;
                  P_FORMULARIO_APERTURA := NULL;
                  P_CAB.CrearError('Error creando segundo titular cliente- ' ||
                                   TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO) || '-' ||
                                   TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN) ||
                                   ' - ' || SQLERRM);
                END IF;
              END;
            END IF;

            IF V_ERRORES = 0 THEN
              BEGIN
                INSERT INTO ESTADOS_ECONOMICOS
                  (EEC_FECHA,
                   EEC_CLI_PER_NUM_IDEN,
                   EEC_CLI_PER_TID_CODIGO,
                   EEC_INGRESO_MENSUAL,
                   EEC_RIM_CODIGO,
                   EEC_ACTIVOS,
                   EEC_PATRIMONIO,
                   EEC_UTILIDAD_PROMEDIO,
                   EEC_PASIVO,
                   EEC_EGRESOS_MENSUALES,
                   EEC_EGRESOS_MENSUALES_NO_OPERA,
                   EEC_INGRESOS_MENSUALES_NO_OPER)
                VALUES
                  (SYSDATE ---EEC_FECHA
                  ,
                   TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN) --EEC_CLI_PER_NUM_IDEN
                  ,
                   TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO) --EEC_CLI_PER_TID_CODIGO
                  ,
                   NVL(C_SETV_VINCULA.SETV_ING_MEN_OPERACIONALES, 0) --EEC_INGRESO_MENSUAL
                  ,
                   NULL --EEC_RIM_CODIGO
                  ,
                   NVL(C_SETV_VINCULA.SETV_ACTIVOS, 0) --EEC_ACTIVOS
                  ,
                   NVL(C_SETV_VINCULA.SETV_PATRIMONIO, 0) --EEC_PATRIMONIO
                  ,
                   0 --EEC_UTILIDAD_PROMEDIO
                  ,
                   NVL(C_SETV_VINCULA.SETV_PASIVOS, 0) --EEC_PASIVO
                  ,
                   NVL(C_SETV_VINCULA.SETV_EGRESOS_MEN_OPERACIONALES, 0) --EEC_EGRESOS_MENSUALES
                  ,
                   NVL(C_SETV_VINCULA.SETV_EGRESOS_MEN_NO_OPERA, 0) --EEC_EGRESOS_MENSUALES_NO_OPERA
                  ,
                   NVL(C_SETV_VINCULA.SETV_INGRESOS_MEN_NO_OPERA, 0) --EEC_INGRESOS_MENSUALES_NO_OPER
                   );

                IF SQL%ROWCOUNT = 0 THEN
                  V_ERRORES             := V_ERRORES + 1;
                  P_FORMULARIO_APERTURA := NULL;
                END IF;

              EXCEPTION
                WHEN OTHERS THEN
                  V_ERRORES             := V_ERRORES + 1;
                  P_FORMULARIO_APERTURA := NULL;
                  P_CAB.CrearError('Error creacion estados econmicos segundo.');
                  RAISE V_ERROR_CREACION;
              END;
            END IF;

            IF V_ERRORES = 0 THEN
              BEGIN
                INSERT INTO OS_CLIENTES
                  (OCL_CLI_PER_NUM_IDEN_RELACIONA,
                   OCL_CLI_PER_TID_CODIGO_RELACIO,
                   OCL_CLI_PER_NUM_IDEN,
                   OCL_CLI_PER_TID_CODIGO,
                   OCL_ESTADO,
                   OCL_FECHA_CAMBIO_ESTADO,
                   OCL_USUARIO_ULTIMO_CAMBIO_ESTA)
                VALUES
                  (TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN) --OCL_CLI_PER_NUM_IDEN_RELACIONA
                  ,
                   TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO) --OCL_CLI_PER_TID_CODIGO_RELACIO
                  ,
                   P_NUMERO_IDENTIFICACION --OCL_CLI_PER_NUM_IDEN
                  ,
                   P_TIPO_IDENTIFICACION --OCL_CLI_PER_TID_CODIGO
                  ,
                   'A' --OCL_ESTADO
                  ,
                   SYSDATE --OCL_FECHA_CAMBIO_ESTADO
                  ,
                   SYSDATE --OCL_USUARIO_ULTIMO_CAMBIO_ESTA
                   );
                IF SQL%ROWCOUNT = 0 THEN
                  V_ERRORES             := V_ERRORES + 1;
                  P_FORMULARIO_APERTURA := NULL;
                END IF;

              EXCEPTION
                WHEN OTHERS THEN
                  V_ERRORES             := V_ERRORES + 1;
                  P_FORMULARIO_APERTURA := NULL;
                  P_CAB.CrearError('Error creando segundos titulares.');
                  RAISE V_ERROR_CREACION;
              END;
            END IF;
          END IF;

          IF C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE = 'C' THEN
            /*para clientes como segundo se dejan tipo cliente como ambos*/
            BEGIN
              UPDATE CLIENTES
                 SET CLI_TIPO_CLIENTE = 'A'
               WHERE CLI_PER_NUM_IDEN =
                     TRIM(C_SETV_VINCULA.SETV_PER_NUM_IDEN)
                 AND CLI_PER_TID_CODIGO =
                     TRIM(C_SETV_VINCULA.SETV_PER_TID_CODIGO);
              IF SQL%ROWCOUNT = 0 THEN
                V_ERRORES             := V_ERRORES + 1;
                P_FORMULARIO_APERTURA := NULL;
              END IF;
            END;
          END IF;
          FETCH SETV_VINCULA
            INTO C_SETV_VINCULA;
        END LOOP;
        CLOSE SETV_VINCULA;
      END IF;

      IF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') NOT IN
         ('PRV', 'INU', 'NUE') AND P_ORIGEN_OPERACION IS NULL THEN
        /* CREACION CUENTA CORREDORES*/
        BEGIN
          P_TOOLS.CONSULTARCONSTANTE(P_CONSTANTE  => 'NCB',
                                     P_VALOR      => V_VALOR,
                                     P_VALOR_DATE => V_VALOR_DATE,
                                     P_VALOR_CHAR => V_VALOR_CHAR);

          BEGIN
            INSERT INTO CUENTAS_CLIENTE_CORREDORES
              (CCC_CLI_PER_NUM_IDEN,
               CCC_CLI_PER_TID_CODIGO,
               CCC_NUMERO_CUENTA,
               CCC_PER_NUM_IDEN,
               CCC_PER_TID_CODIGO,
               CCC_AGE_CODIGO,
               CCC_FECHA_APERTURA,
               CCC_NOMBRE_CUENTA,
               CCC_DIRECCION,
               CCC_SALDO_CAPITAL,
               CCC_SALDO_A_PLAZO,
               CCC_SALDO_A_CONTADO,
               CCC_SALDO_ADMON_VALORES,
               CCC_CUENTA_ACTIVA,
               CCC_CUENTA_ESPECULATIVA,
               CCC_PERIODO_EXTRACTO,
               CCC_ENVIAR_EXTRACTO,
               CCC_SALDO_CANJE,
               CCC_CONTRATO_OPCF,
               CCC_CUENTA_CRCC,
               CCC_CUENTA_APT,
               CCC_SALDO_CC,
               CCC_ETRADE,
               CCC_CTA_COMPARTIMENTO,
               CCC_SALDO_CANJE_CC,
               CCC_FON_CODIGO,
               CCC_SALDO_BURSATIL,
               CCC_LINEAS_PROFUNDIDAD,
               CCC_PANTALLA_LIVIANA)
            VALUES
              (TRIM(P_NUMERO_IDENTIFICACION) --CCC_CLI_PER_NUM_IDEN
              ,
               TRIM(P_TIPO_IDENTIFICACION) --CCC_CLI_PER_TID_CODIGO
              ,
               1 --CCC_NUMERO_CUENTA
              ,
               DECODE(P_ORIGEN,
                      'PLV',
                      SUBSTR(V_VALOR_CHAR, 4, LENGTH(TRIM(V_VALOR_CHAR))),
                      TRIM(P_NUM_IDEN_COMERCIAL)) --CCC_PER_NUM_IDEN
              ,
               DECODE(P_ORIGEN,
                      'PLV',
                      SUBSTR(V_VALOR_CHAR, 1, 2),
                      TRIM(P_TIPO_IDE_COMERCIAL)) --CCC_PER_TID_CODIGO
              ,
               DECODE(P_ORIGEN,
                      'PLV',
                      V_CIUDAD_RESIDENCIA,
                      'VIN',
                      DECODE(P_TIPO_CLIENTE,
                             'PJU',
                             V_AGE_CODIGO_PPAL,
                             V_CIUDAD_RESIDENCIA)) --CCC_AGE_CODIGO
              ,
               SYSDATE --CCC_FECHA_APERTURA
              ,
               UPPER(TRIM(P_PRIMER_APELLIDO)) || ' ' ||
               UPPER(TRIM(P_SEGUNDO_APELLIDO)) || ' ' ||
               UPPER(TRIM(P_NOMBRES)) --CCC_NOMBRE_CUENTA
              ,
               P_DIRECCION_RESIDENCIA --CCC_DIRECCION
              ,
               0 --CCC_SALDO_CAPITAL
              ,
               0 --CCC_SALDO_A_PLAZO
              ,
               0 --CCC_SALDO_A_CONTADO
              ,
               0 --CCC_SALDO_ADMON_VALORES
              ,
               DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'), 'N', 'S', 'N') --'S'                                   --CCC_CUENTA_ACTIVA
              ,
               NULL --CCC_CUENTA_ESPECULATIVA
              ,
               'N' --CCC_PERIODO_EXTRACTO
              ,
               'N' --CCC_ENVIAR_EXTRACTO
              ,
               0 --CCC_SALDO_CANJE
              ,
               NULL --CCC_CONTRATO_OPCF
              ,
               NULL --CCC_CUENTA_CRCC
              ,
               'N' --CCC_CUENTA_APT
              ,
               0 --CCC_SALDO_CC
              ,
               NULL --CCC_ETRADE
              ,
               NULL --CCC_CTA_COMPARTIMENTO
              ,
               0 --CCC_SALDO_CANJE_CC
              ,
               NULL --CCC_FON_CODIGO
              ,
               0 --CCC_SALDO_BURSATIL
              ,
               NULL --CCC_LINEAS_PROFUNDIDAD
              ,
               DECODE(P_ORIGEN, 'PLV', 'S', NULL) --CCC_PANTALLA_LIVIANA
               );

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando cuenta corredores.');
              RAISE V_ERROR_CREACION;
          END;
        END;

      ELSIF NVL(P_ESTADO_VINCULACION_DIGITAL, 'N') IN ('PRV', 'INU', 'NUE') OR
            NVL(P_ORIGEN_OPERACION, 'N') != 'N' THEN
        /* CREACION CUENTA CORREDORES*/
        BEGIN
          P_TOOLS.CONSULTARCONSTANTE(P_CONSTANTE  => 'NCB',
                                     P_VALOR      => V_VALOR,
                                     P_VALOR_DATE => V_VALOR_DATE,
                                     P_VALOR_CHAR => V_VALOR_CHAR);

          BEGIN

            MERGE INTO CUENTAS_CLIENTE_CORREDORES CC
            USING dual dd
            ON (CC.CCC_CLI_PER_NUM_IDEN = TRIM(P_NUMERO_IDENTIFICACION) AND CC.CCC_CLI_PER_TID_CODIGO = TRIM(P_TIPO_IDENTIFICACION) AND CC.CCC_NUMERO_CUENTA = 1)
            WHEN MATCHED THEN
              UPDATE
                 SET CCC_PER_NUM_IDEN        = DECODE(P_ORIGEN,
                                                      'PLV',
                                                      SUBSTR(V_VALOR_CHAR,
                                                             4,
                                                             LENGTH(TRIM(V_VALOR_CHAR))),
                                                      TRIM(P_NUM_IDEN_COMERCIAL)) --CCC_PER_NUM_IDEN
                    ,
                     CCC_PER_TID_CODIGO      = DECODE(P_ORIGEN,
                                                      'PLV',
                                                      SUBSTR(V_VALOR_CHAR,
                                                             1,
                                                             2),
                                                      TRIM(P_TIPO_IDE_COMERCIAL)) --CCC_PER_TID_CODIGO
                    ,
                     CCC_AGE_CODIGO          = DECODE(P_ORIGEN,
                                                      'PLV',
                                                      V_CIUDAD_RESIDENCIA,
                                                      'VIN',
                                                      DECODE(P_TIPO_CLIENTE,
                                                             'PJU',
                                                             V_AGE_CODIGO_PPAL,
                                                             V_CIUDAD_RESIDENCIA)) --CCC_AGE_CODIGO
                    ,
                     CCC_FECHA_APERTURA      = SYSDATE --CCC_FECHA_APERTURA
                    ,
                     CCC_NOMBRE_CUENTA       = UPPER(TRIM(P_PRIMER_APELLIDO)) || ' ' ||
                                               UPPER(TRIM(P_SEGUNDO_APELLIDO)) || ' ' ||
                                               UPPER(TRIM(P_NOMBRES)) --CCC_NOMBRE_CUENTA
                    ,
                     CCC_DIRECCION           = P_DIRECCION_RESIDENCIA --CCC_DIRECCION
                    ,
                     CCC_SALDO_CAPITAL       = 0 --CCC_SALDO_CAPITAL
                    ,
                     CCC_SALDO_A_PLAZO       = 0 --CCC_SALDO_A_PLAZO
                    ,
                     CCC_SALDO_A_CONTADO     = 0 --CCC_SALDO_A_CONTADO
                    ,
                     CCC_SALDO_ADMON_VALORES = 0 --CCC_SALDO_ADMON_VALORES
                    ,
                     CCC_CUENTA_ACTIVA       = DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL,
                                                          'N'),
                                                      'N',
                                                      'S',
                                                      'N') --'S'                                   --CCC_CUENTA_ACTIVA
                    ,
                     CCC_CUENTA_ESPECULATIVA = NULL --CCC_CUENTA_ESPECULATIVA
                    ,
                     CCC_PERIODO_EXTRACTO    = 'N' --CCC_PERIODO_EXTRACTO
                    ,
                     CCC_ENVIAR_EXTRACTO     = 'N' --CCC_ENVIAR_EXTRACTO
                    ,
                     CCC_SALDO_CANJE         = 0 --CCC_SALDO_CANJE
                    ,
                     CCC_CONTRATO_OPCF       = NULL --CCC_CONTRATO_OPCF
                    ,
                     CCC_CUENTA_CRCC         = NULL --CCC_CUENTA_CRCC
                    ,
                     CCC_CUENTA_APT          = 'N' --CCC_CUENTA_APT
                    ,
                     CCC_SALDO_CC            = 0 --CCC_SALDO_CC
                    ,
                     CCC_ETRADE              = NULL --CCC_ETRADE
                    ,
                     CCC_CTA_COMPARTIMENTO   = NULL --CCC_CTA_COMPARTIMENTO
                    ,
                     CCC_SALDO_CANJE_CC      = 0 --CCC_SALDO_CANJE_CC
                    ,
                     CCC_FON_CODIGO          = NULL --CCC_FON_CODIGO
                    ,
                     CCC_SALDO_BURSATIL      = 0 --CCC_SALDO_BURSATIL
                    ,
                     CCC_LINEAS_PROFUNDIDAD  = NULL --CCC_LINEAS_PROFUNDIDAD
                    ,
                     CCC_PANTALLA_LIVIANA    = DECODE(P_ORIGEN,
                                                      'PLV',
                                                      'S',
                                                      NULL) --CCC_PANTALLA_LIVIANA


            WHEN NOT MATCHED THEN
              INSERT
                (CCC_CLI_PER_NUM_IDEN,
                 CCC_CLI_PER_TID_CODIGO,
                 CCC_NUMERO_CUENTA,
                 CCC_PER_NUM_IDEN,
                 CCC_PER_TID_CODIGO,
                 CCC_AGE_CODIGO,
                 CCC_FECHA_APERTURA,
                 CCC_NOMBRE_CUENTA,
                 CCC_DIRECCION,
                 CCC_SALDO_CAPITAL,
                 CCC_SALDO_A_PLAZO,
                 CCC_SALDO_A_CONTADO,
                 CCC_SALDO_ADMON_VALORES,
                 CCC_CUENTA_ACTIVA,
                 CCC_CUENTA_ESPECULATIVA,
                 CCC_PERIODO_EXTRACTO,
                 CCC_ENVIAR_EXTRACTO,
                 CCC_SALDO_CANJE,
                 CCC_CONTRATO_OPCF,
                 CCC_CUENTA_CRCC,
                 CCC_CUENTA_APT,
                 CCC_SALDO_CC,
                 CCC_ETRADE,
                 CCC_CTA_COMPARTIMENTO,
                 CCC_SALDO_CANJE_CC,
                 CCC_FON_CODIGO,
                 CCC_SALDO_BURSATIL,
                 CCC_LINEAS_PROFUNDIDAD,
                 CCC_PANTALLA_LIVIANA)
              VALUES
                (TRIM(P_NUMERO_IDENTIFICACION) --CCC_CLI_PER_NUM_IDEN
                ,
                 TRIM(P_TIPO_IDENTIFICACION) --CCC_CLI_PER_TID_CODIGO
                ,
                 1 --CCC_NUMERO_CUENTA
                ,
                 DECODE(P_ORIGEN,
                        'PLV',
                        SUBSTR(V_VALOR_CHAR, 4, LENGTH(TRIM(V_VALOR_CHAR))),
                        TRIM(P_NUM_IDEN_COMERCIAL)) --CCC_PER_NUM_IDEN
                ,
                 DECODE(P_ORIGEN,
                        'PLV',
                        SUBSTR(V_VALOR_CHAR, 1, 2),
                        TRIM(P_TIPO_IDE_COMERCIAL)) --CCC_PER_TID_CODIGO
                ,
                 DECODE(P_ORIGEN,
                        'PLV',
                        V_CIUDAD_RESIDENCIA,
                        'VIN',
                        DECODE(P_TIPO_CLIENTE,
                               'PJU',
                               V_AGE_CODIGO_PPAL,
                               V_CIUDAD_RESIDENCIA)) --CCC_AGE_CODIGO
                ,
                 SYSDATE --CCC_FECHA_APERTURA
                ,
                 UPPER(TRIM(P_PRIMER_APELLIDO)) || ' ' ||
                 UPPER(TRIM(P_SEGUNDO_APELLIDO)) || ' ' ||
                 UPPER(TRIM(P_NOMBRES)) --CCC_NOMBRE_CUENTA
                ,
                 P_DIRECCION_RESIDENCIA --CCC_DIRECCION
                ,
                 0 --CCC_SALDO_CAPITAL
                ,
                 0 --CCC_SALDO_A_PLAZO
                ,
                 0 --CCC_SALDO_A_CONTADO
                ,
                 0 --CCC_SALDO_ADMON_VALORES
                ,
                 DECODE(NVL(P_ESTADO_VINCULACION_DIGITAL, 'N'),
                        'N',
                        'S',
                        'N') --'S'                                   --CCC_CUENTA_ACTIVA
                ,
                 NULL --CCC_CUENTA_ESPECULATIVA
                ,
                 'N' --CCC_PERIODO_EXTRACTO
                ,
                 'N' --CCC_ENVIAR_EXTRACTO
                ,
                 0 --CCC_SALDO_CANJE
                ,
                 NULL --CCC_CONTRATO_OPCF
                ,
                 NULL --CCC_CUENTA_CRCC
                ,
                 'N' --CCC_CUENTA_APT
                ,
                 0 --CCC_SALDO_CC
                ,
                 NULL --CCC_ETRADE
                ,
                 NULL --CCC_CTA_COMPARTIMENTO
                ,
                 0 --CCC_SALDO_CANJE_CC
                ,
                 NULL --CCC_FON_CODIGO
                ,
                 0 --CCC_SALDO_BURSATIL
                ,
                 NULL --CCC_LINEAS_PROFUNDIDAD
                ,
                 DECODE(P_ORIGEN, 'PLV', 'S', NULL) --CCC_PANTALLA_LIVIANA
                 );

            IF SQL%ROWCOUNT = 0 THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
            END IF;

          EXCEPTION
            WHEN OTHERS THEN
              V_ERRORES             := V_ERRORES + 1;
              P_FORMULARIO_APERTURA := NULL;
              P_CAB.CrearError('Error creando o actualizando cuenta corredores.');
              RAISE V_ERROR_CREACION;
          END;
        END;
      END IF; --CIERRA IF DE VINCULACION DIGITAL
    END IF; --CIERRA IF V_ERRORES=0 INICIAL

    IF V_ERRORES = 0 THEN
      --P_FORMULARIO_APERTURA := P_INTEGRACION.FN_FORMULARIO_APERTURA(); --j.a.
      DBMS_OUTPUT.PUT_LINE('SIN ERRORES');
      IF NVL(P_ORIGEN, ' ') = 'VIN' THEN
        P_CLIENTES.PR_ACTUALIZA_VINCULACION(P_NUMERO_FORMULARIO  => P_NUMERO_FORMULARIO_VIN,
                                            P_CLI_PER_NUM_IDEN   => TRIM(P_NUMERO_IDENTIFICACION),
                                            P_CLI_PER_TID_CODIGO => TRIM(P_TIPO_IDENTIFICACION),
                                            P_CLOB               => P_CLOB);
      END IF;
      COMMIT;
    ELSE
      RAISE V_ERROR_CREACION;
      DBMS_OUTPUT.PUT_LINE('ERRORES');
    END IF;

  EXCEPTION
    WHEN V_ERROR_CREACION THEN
      IF NVL(P_ORIGEN, ' ') = 'PLV' THEN
        P_CLOB := P_CAB.ObtenerCLOB_ERROR('CreacionClienteBasico');
      END IF;

      IF NVL(P_ORIGEN, ' ') = 'VIN' THEN
        P_CLOB := P_CAB.ObtenerCLOB_ERROR('DatosClienteVincula');
      END IF;
  END PR_CREACION_CLIENTE_BASICO;
  PROCEDURE PR_MARCAR_ADMON_VAL IS

    CURSOR C_TMP_DESMARCAR IS
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_AUTORIZA_ADMON_VALORES,
             SEGMENTO,
             IND_APLICA_ADMONVAL,
             IND_DESMARCADO,
             IND_MARCAR
        FROM TMP_ADMVAL_CLIENTES_MARCAR
       WHERE CLI_AUTORIZA_ADMON_VALORES = 'S'
         AND IND_MARCAR = 'N'
       ORDER BY CLI_PER_NUM_IDEN, CLI_PER_TID_CODIGO;
    TMPD C_TMP_DESMARCAR%ROWTYPE;

    CURSOR C_TMP_MARCAR IS
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_AUTORIZA_ADMON_VALORES,
             SEGMENTO,
             IND_APLICA_ADMONVAL,
             IND_DESMARCADO,
             IND_MARCAR
        FROM TMP_ADMVAL_CLIENTES_MARCAR
       WHERE CLI_AUTORIZA_ADMON_VALORES = 'N'
         AND IND_MARCAR = 'S'
       ORDER BY CLI_PER_NUM_IDEN, CLI_PER_TID_CODIGO;
    TMPM C_TMP_MARCAR%ROWTYPE;

    V_PROCESO              VARCHAR2(100);
    V_TABLA_EXISTE         NUMBER(5);
    MOTIVO_EXE_CBR_ADM_VAL VARCHAR2(100);
    AUTORIZA               VARCHAR2(1);

  BEGIN
    V_PROCESO      := 'IDENTIFICANDO LOS CLIENTES DE BANCA PATRIMONIAL';
    V_TABLA_EXISTE := 0;
    SELECT COUNT(*)
      INTO V_TABLA_EXISTE
      FROM ALL_OBJECTS
     WHERE OBJECT_TYPE = 'TABLE'
       AND OBJECT_NAME = 'TMP_ADMVAL_CLIENTES_BANCA_PAT';

    IF V_TABLA_EXISTE = 1 THEN
      EXECUTE IMMEDIATE 'DROP TABLE TMP_ADMVAL_CLIENTES_BANCA_PAT';
    END IF;

    EXECUTE IMMEDIATE '
      CREATE TABLE TMP_ADMVAL_CLIENTES_BANCA_PAT (
             CLI_PER_NUM_IDEN      VARCHAR2(15)
            ,CLI_PER_TID_CODIGO    VARCHAR2(3))
      TABLESPACE DATA_COEASY';

    V_TABLA_EXISTE := 0;
    SELECT COUNT(*)
      INTO V_TABLA_EXISTE
      FROM ALL_OBJECTS
     WHERE OBJECT_TYPE = 'TABLE'
       AND OBJECT_NAME = 'TMP_ADMVAL_CLIENTES_MARCAR';

    IF V_TABLA_EXISTE = 1 THEN
      EXECUTE IMMEDIATE 'DROP TABLE TMP_ADMVAL_CLIENTES_MARCAR';
    END IF;

    EXECUTE IMMEDIATE '
      CREATE TABLE TMP_ADMVAL_CLIENTES_MARCAR (
             CLI_PER_NUM_IDEN               VARCHAR2(15)
            ,CLI_PER_TID_CODIGO             VARCHAR2(3)
            ,CLI_ECL_MNEMONICO              VARCHAR2(3)
            ,CLI_AUTORIZA_ADMON_VALORES     VARCHAR2(1)
            ,SEGMENTO                       VARCHAR2(30)
            ,IND_APLICA_ADMONVAL            VARCHAR2(1)
            ,IND_DESMARCADO                 VARCHAR2(1)
            ,IND_MARCAR                     VARCHAR2(1))
      TABLESPACE DATA_COEASY';

    DELETE FROM TMP_ADMVAL_CLIENTES_BANCA_PAT;

    INSERT INTO TMP_ADMVAL_CLIENTES_BANCA_PAT
      (CLI_PER_NUM_IDEN, CLI_PER_TID_CODIGO)
      SELECT DISTINCT CCC_CLI_PER_NUM_IDEN, CCC_CLI_PER_TID_CODIGO
        FROM CUENTAS_CLIENTE_CORREDORES,
             (SELECT PER_NUM_IDEN, PER_TID_CODIGO
                FROM PERSONAS
               WHERE PER_SUC_CODIGO = 11) PER
       WHERE CCC_PER_NUM_IDEN = PER.PER_NUM_IDEN
         AND CCC_PER_TID_CODIGO = PER.PER_TID_CODIGO
         AND CCC_CUENTA_ACTIVA = 'S';

    V_PROCESO := 'TRAYENDO CLIENTES NO INACTIVOS CON SU SEGMENTO QUE NO SON BP';
    DELETE FROM TMP_ADMVAL_CLIENTES_MARCAR;

    INSERT INTO TMP_ADMVAL_CLIENTES_MARCAR
      (CLI_PER_NUM_IDEN,
       CLI_PER_TID_CODIGO,
       CLI_ECL_MNEMONICO,
       CLI_AUTORIZA_ADMON_VALORES,
       SEGMENTO,
       IND_APLICA_ADMONVAL,
       IND_DESMARCADO,
       IND_MARCAR)
      SELECT CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_AUTORIZA_ADMON_VALORES,
             BSC_DESCRIPCION -- SEGMENTO
            ,
             'N' -- IND_APLICA_ADMONVAL
            ,
             'N' -- IND_DESMARCADO
            ,
             'N' -- IND_MARCAR
        FROM CLIENTES CLI, BI_SEGMENTACION_CLIENTES BI
       WHERE CLI.CLI_ECL_MNEMONICO != 'INA'
         AND CLI.CLI_TIPO_CLIENTE IN ('C', 'A')
         AND CLI.CLI_BSC_MNEMONICO = BI.BSC_MNEMONICO(+)
         AND CLI.CLI_BSC_BCC_MNEMONICO = BI.BSC_BCC_MNEMONICO(+)
         AND NOT EXISTS
       (SELECT 'S'
                FROM TMP_ADMVAL_CLIENTES_BANCA_PAT BP
               WHERE BP.CLI_PER_NUM_IDEN = CLI.CLI_PER_NUM_IDEN
                 AND BP.CLI_PER_TID_CODIGO = CLI.CLI_PER_TID_CODIGO);

    V_PROCESO := 'MARCANDO LOS QUE POR SEGMENTO LES APLICA ADMON VALORES';
    UPDATE TMP_ADMVAL_CLIENTES_MARCAR
       SET IND_APLICA_ADMONVAL = 'S'
     WHERE SEGMENTO LIKE '%PLATA%'
        OR SEGMENTO LIKE '%BRONCE%';
    COMMIT;

    V_PROCESO := 'IDENTIFICANDO LOS QUE HAN SIDO DESMARCADOS';
    UPDATE TMP_ADMVAL_CLIENTES_MARCAR
       SET IND_DESMARCADO = 'S'
     WHERE EXISTS
     (SELECT 'S'
              FROM CLIENTES_DESMARCADOS_ADMON_VAL
             WHERE CDAV_CLI_PER_NUM_IDEN = CLI_PER_NUM_IDEN
               AND CDAV_CLI_PER_TID_CODIGO = CLI_PER_TID_CODIGO);
    COMMIT;

    V_PROCESO := 'IDENTIFICANDO LOS CLIENTES QUE DEBEN SER MARCADOS';
    UPDATE TMP_ADMVAL_CLIENTES_MARCAR
       SET IND_MARCAR = 'S'
     WHERE IND_APLICA_ADMONVAL = 'S'
       AND IND_DESMARCADO = 'N';
    COMMIT;

    UPDATE CONSTANTES SET CON_VALOR_CHAR = 'S' WHERE CON_MNEMONICO = 'PMA';
    COMMIT;

    V_PROCESO := 'DESMARCANDO CLIENTES';
    OPEN C_TMP_DESMARCAR;
    FETCH C_TMP_DESMARCAR
      INTO TMPD;
    WHILE C_TMP_DESMARCAR%FOUND LOOP
      V_PROCESO := 'DESMARCANDO CLIENTES' || TMPD.CLI_PER_NUM_IDEN || '-' ||
                   TMPD.CLI_PER_TID_CODIGO;
      UPDATE CLIENTES
         SET CLI_AUTORIZA_ADMON_VALORES = 'N'
       WHERE CLI_PER_NUM_IDEN = TMPD.CLI_PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = TMPD.CLI_PER_TID_CODIGO;
      COMMIT;

      FETCH C_TMP_DESMARCAR
        INTO TMPD;
    END LOOP;
    CLOSE C_TMP_DESMARCAR;

    UPDATE CONSTANTES SET CON_VALOR_CHAR = 'N' WHERE CON_MNEMONICO = 'PMA';
    COMMIT;

    V_PROCESO := 'SE HA FINALIZADO EL PROCESO';

  END PR_MARCAR_ADMON_VAL;

  PROCEDURE PR_ADMONVAL_SALDOS_FONDOS(P_FECHA_INI DATE, P_FECHA_FIN DATE) IS

    CURSOR C_SALDOMIN IS
      SELECT CON_VALOR FROM CONSTANTES WHERE CON_MNEMONICO = 'SMF';

    V_SALDOMIN NUMBER(22, 2);
    V_NUMDIAS  NUMBER(5);
    NO_SALDOMIN EXCEPTION;
    V_PROCESO      VARCHAR2(100);
    V_TABLA_EXISTE NUMBER(5);

  BEGIN
    V_PROCESO := 'VALDIDANDO PARAMETRO SMF';
    OPEN C_SALDOMIN;
    FETCH C_SALDOMIN
      INTO V_SALDOMIN;
    IF C_SALDOMIN%NOTFOUND THEN
      RAISE NO_SALDOMIN;
    END IF;
    CLOSE C_SALDOMIN;

    DELETE FROM TMP_ADMVAL_SALDOS_DIARIOS;
    DELETE FROM TMP_ADMVAL_SALDOS_FONDOS;
    DELETE FROM TMP_ADMVAL_SALDOS_PROMEDIO;

    V_PROCESO := 'EXTRAYENDO TABLA SALDOS DIARIOS DEL PERIODO REQUERIDO';
    INSERT INTO TMP_ADMVAL_SALDOS_DIARIOS
      (SAD_CONSECUTIVO,
       SAD_FECHA,
       SAD_PRO_MNEMONICO,
       SAD_CCC_CLI_PER_NUM_IDEN,
       SAD_CCC_CLI_PER_TID_CODIGO,
       SAD_CCC_NUMERO_CUENTA,
       SAD_SALDO,
       SAD_FON_CODIGO)
      SELECT SAD_CONSECUTIVO,
             SAD_FECHA,
             SAD_PRO_MNEMONICO,
             SAD_CCC_CLI_PER_NUM_IDEN,
             SAD_CCC_CLI_PER_TID_CODIGO,
             SAD_CCC_NUMERO_CUENTA,
             SAD_SALDO,
             SAD_FON_CODIGO
        FROM SALDOS_DIARIOS
       WHERE TRUNC(SAD_FECHA) >= P_FECHA_INI
         AND TRUNC(SAD_FECHA) <= P_FECHA_FIN;

    V_PROCESO := 'TRAYENDO LOS SALDOS DE LOS CLIENTES EN PROCESO';
    INSERT INTO TMP_ADMVAL_SALDOS_FONDOS
      (SAD_CONSECUTIVO,
       SAD_FECHA,
       SAD_PRO_MNEMONICO,
       SAD_CCC_CLI_PER_NUM_IDEN,
       SAD_CCC_CLI_PER_TID_CODIGO,
       SAD_CCC_NUMERO_CUENTA,
       SAD_SALDO,
       SAD_FON_CODIGO)
      SELECT SAD_CONSECUTIVO,
             SAD_FECHA,
             SAD_PRO_MNEMONICO,
             SAD_CCC_CLI_PER_NUM_IDEN,
             SAD_CCC_CLI_PER_TID_CODIGO,
             SAD_CCC_NUMERO_CUENTA,
             SAD_SALDO,
             SAD_FON_CODIGO
        FROM TMP_ADMVAL_SALDOS_DIARIOS
       WHERE SAD_PRO_MNEMONICO IN
             (SELECT FON_NPR_PRO_MNEMONICO
                FROM FONDOS
               WHERE FON_TIPO_ADMINISTRACION = 'F'
                 AND FON_BMO_MNEMONICO = 'PESOS'
                 AND FON_ESTADO = 'A');

    V_PROCESO := 'CALCULANDO LOS DIAS DEL PERIODO A EVALUAR';
    SELECT P_FECHA_FIN - P_FECHA_INI + 1 DIAS INTO V_NUMDIAS FROM DUAL;

    V_PROCESO := 'CALCULANDO LA SUMA DE LOS SALDOS EN EL PERIODO';
    INSERT INTO TMP_ADMVAL_SALDOS_PROMEDIO
      (SAD_CCC_CLI_PER_NUM_IDEN, SAD_CCC_CLI_PER_TID_CODIGO, SALDO)
      SELECT SAD_CCC_CLI_PER_NUM_IDEN,
             SAD_CCC_CLI_PER_TID_CODIGO,
             SUM(SAD_SALDO) SALDO
        FROM TMP_ADMVAL_SALDOS_FONDOS
       GROUP BY SAD_CCC_CLI_PER_NUM_IDEN, SAD_CCC_CLI_PER_TID_CODIGO;

    V_PROCESO := 'CALCULANDO EL PROMEDIO';
    UPDATE TMP_ADMVAL_SALDOS_PROMEDIO
       SET SALDO_PROMEDIO = SALDO / V_NUMDIAS;

    V_PROCESO := 'MARCANDO LOS QUE ALCANZAN EL PARAMETRO';
    UPDATE TMP_ADMVAL_SALDOS_PROMEDIO
       SET INDICADOR_SALDO = 'S'
     WHERE SALDO_PROMEDIO >= V_SALDOMIN;

  EXCEPTION
    WHEN NO_SALDOMIN THEN
      RAISE_APPLICATION_ERROR(-20001,
                              'NO EXISTE LA CONSTANTE SMF DE SALDO MINIMO EN FONDOS');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,
                              'SE HA PRESENTADO UN ERROR - ' || V_PROCESO || ' -' ||
                              SQLERRM);

  END PR_ADMONVAL_SALDOS_FONDOS;

  PROCEDURE PR_INACTIVAR_CONTRATOS(P_FECHA_PROCESO DATE) IS
    -- Tipos de Condiciones de Negociación
    CURSOR C_CONDICIONES IS
      SELECT CNE_MNEMONICO
        FROM CONDICIONES_DE_NEGOCIACION
       WHERE CNE_CONTRATO = 'S';
    C_COND C_CONDICIONES%ROWTYPE;

    -- Contratos de los clientes
    CURSOR C_CONTRATOS IS
      SELECT CNT_FECHA_VENCIMIENTO, CNT_CONTRATO_FISICO, CNT_TIPO_PRODUCTO
        FROM CONTRATOS
       WHERE CNT_ESTADO = 'A'
         AND CNT_TIPO_PRODUCTO = C_COND.CNE_MNEMONICO
         AND CNT_TIPO_PRODUCTO != 'DER';
    C_CONT C_CONTRATOS%ROWTYPE;

    -- Instrucciones de los Contratos de los clientes
    CURSOR C_INSTRUCCION IS
      SELECT 'X'
        FROM INSTRUCCIONES_CONTRATOS_BOLSA
       WHERE INC_ESTADO = 'A'
         AND INC_CNT_CONTRATO_FISICO = C_CONT.CNT_CONTRATO_FISICO;

    COND VARCHAR2(1);

  BEGIN
    COND := NULL;
    OPEN C_CONDICIONES;
    FETCH C_CONDICIONES
      INTO C_COND;
    WHILE C_CONDICIONES%FOUND LOOP

      OPEN C_CONTRATOS;
      FETCH C_CONTRATOS
        INTO C_CONT;
      WHILE C_CONTRATOS%FOUND LOOP
        IF C_CONT.CNT_FECHA_VENCIMIENTO < P_FECHA_PROCESO THEN
          UPDATE CONTRATOS
             SET CNT_ESTADO = 'I'
           WHERE CNT_CONTRATO_FISICO = C_CONT.CNT_CONTRATO_FISICO
             AND CNT_TIPO_PRODUCTO = C_COND.CNE_MNEMONICO;

          UPDATE INSTRUCCIONES_CONTRATOS_BOLSA
             SET INC_ESTADO = 'I'
           WHERE INC_CNT_CONTRATO_FISICO = C_CONT.CNT_CONTRATO_FISICO
             AND INC_CNT_TIPO_PRODUCTO = C_COND.CNE_MNEMONICO;
        END IF;
        FETCH C_CONTRATOS
          INTO C_CONT;
      END LOOP;
      CLOSE C_CONTRATOS;
      FETCH C_CONDICIONES
        INTO C_COND;
    END LOOP;
    CLOSE C_CONDICIONES;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20001,
                              'Error en proceso PR_INACTIVAR_CONTRATOS NO DERIVADOS- ' ||
                              C_CONT.CNT_CONTRATO_FISICO || ' -' || SQLERRM);
  END PR_INACTIVAR_CONTRATOS;

  PROCEDURE PR_MAIL_LISTAS_CAUTELA(P_FECHA_PROCESO DATE DEFAULT NULL,
                                   P_TIPO_LISTA    VARCHAR2) IS
    V_DIRECCION VARCHAR2(1000);
    V_FECHA_GEN DATE;
    V_LINEA     VARCHAR2(4000);
    CRLF        VARCHAR2(2) := CHR(13) || CHR(10);
    CONN        utl_smtp.connection;

    CURSOR LISTA(P_TIPO_LISTA VARCHAR2) IS
      SELECT REPLACE(REPLACE(LCC_NUM_IDEN, ';', ' '), ',', ' ') LCC_NUM_IDEN,
             LCC_TID_CODIGO,
             LCC_TIPO,
             REPLACE(REPLACE(LCC_NOMBRE, ';', ' '), ',', ' ') LCC_NOMBRE,
             LCC_CODIGO,
             REPLACE(REPLACE(LCC_PAIS, ';', ' '), ',', ' ') LCC_PAIS,
             LCC_EXPEDICION,
             LCC_EXPIRACION,
             LCC_TIPO_LISTA,
             LCC_ESTADO,
             TRIM(REPLACE(REPLACE(LCC_OBSERVACIONES, ';', ' '), ',', ' ')) LCC_OBSERVACIONES
        FROM LISTA_CAUTELA_CLIENTES
       WHERE LCC_TIPO_LISTA = P_TIPO_LISTA
         AND TRUNC(LCC_FECHA_REGISTRO) = TRUNC(V_FECHA_GEN);
    C_LISTA LISTA%ROWTYPE;

  BEGIN
    IF P_FECHA_PROCESO IS NULL THEN
      V_FECHA_GEN := SYSDATE;
    ELSE
      V_FECHA_GEN := P_FECHA_PROCESO;
    END IF;

    V_DIRECCION := NULL;
    --V_DIRECCION := 'mmedina@corredores.com';
    V_DIRECCION := 'wgonzalez@corredores.com;noemia.camanoc@corredorespanama.com.pa;sarah.villarreal@corredorespanama.com.pa;david.bermudez@corredorespanama.com.pa;velkis.moreno@corredorespanama.com.pa';
    -- VAGTUS045346 - Se agrega correo noemia.camanoc@corredorespanama.com.pa
    C_LISTA := NULL;
    IF P_TIPO_LISTA = 'ONU' THEN
      CONN := P_MAIL.BEGIN_MAIL(SENDER     => 'administrador@corredores.com',
                                RECIPIENTS => V_DIRECCION,
                                SUBJECT    => 'Lista Cautela ONU ' ||
                                              V_FECHA_GEN,
                                MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);

      P_MAIL.BEGIN_ATTACHMENT(CONN         => CONN,
                              mime_type    => RTRIM('ListaCautelaONU', ' ') ||
                                              '/csv',
                              INLINE       => TRUE,
                              FILENAME     => RTRIM('ListaCautelaONU', ' ') ||
                                              '.csv',
                              TRANSFER_ENC => 'text');
      OPEN LISTA('ONU');
      FETCH LISTA
        INTO C_LISTA;
      WHILE LISTA%FOUND LOOP
        V_LINEA := C_LISTA.LCC_NOMBRE || ';' || C_LISTA.LCC_TID_CODIGO || ';' ||
                   C_LISTA.LCC_NUM_IDEN || ';' || C_LISTA.LCC_EXPEDICION || ';' ||
                   C_LISTA.LCC_EXPIRACION || ';' || C_LISTA.LCC_CODIGO || ';' ||
                   C_LISTA.LCC_PAIS || ';' || C_LISTA.LCC_OBSERVACIONES;
        V_LINEA := TRIM(REPLACE(REPLACE(REPLACE(V_LINEA, CHR(10), '  '),
                                        CHR(13),
                                        '  '),
                                '   ',
                                ' '));
        P_MAIL.WRITE_MB_TEXT(CONN, V_LINEA || CRLF);
        FETCH LISTA
          INTO C_LISTA;
      END LOOP;
      CLOSE LISTA;
      P_MAIL.END_ATTACHMENT(CONN => CONN);
      P_MAIL.END_MAIL(CONN => CONN);

    ELSIF P_TIPO_LISTA = 'OFAC' THEN
      CONN := P_MAIL.BEGIN_MAIL(SENDER     => 'administrador@corredores.com',
                                RECIPIENTS => V_DIRECCION,
                                SUBJECT    => 'Lista Cautela OFAC ' ||
                                              V_FECHA_GEN,
                                MIME_TYPE  => P_MAIL.MULTIPART_MIME_TYPE);
      P_MAIL.BEGIN_ATTACHMENT(CONN         => CONN,
                              MIME_TYPE    => RTRIM('ListaCautelaOFAC', ' ') ||
                                              '/csv',
                              INLINE       => TRUE,
                              FILENAME     => RTRIM('ListaCautelaOFAC', ' ') ||
                                              '.csv',
                              TRANSFER_ENC => 'text');
      OPEN LISTA('OFAC');
      FETCH LISTA
        INTO C_LISTA;
      WHILE LISTA%FOUND LOOP
        V_LINEA := C_LISTA.LCC_NOMBRE || ';' || C_LISTA.LCC_TID_CODIGO || ';' ||
                   C_LISTA.LCC_NUM_IDEN || ';' || C_LISTA.LCC_EXPEDICION || ';' ||
                   C_LISTA.LCC_EXPIRACION || ';' || C_LISTA.LCC_CODIGO || ';' ||
                   C_LISTA.LCC_PAIS || ';' || C_LISTA.LCC_OBSERVACIONES;
        V_LINEA := TRIM(REPLACE(REPLACE(REPLACE(V_LINEA, CHR(10), '  '),
                                        CHR(13),
                                        '  '),
                                '   ',
                                ' '));
        P_MAIL.WRITE_MB_TEXT(CONN, V_LINEA || CRLF);
        FETCH LISTA
          INTO C_LISTA;
      END LOOP;
      CLOSE LISTA;
      P_MAIL.END_ATTACHMENT(CONN => CONN);
      p_mail.end_mail(conn => conn);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      p_mail.write_mb_text(conn,
                           'Error en generacion archivo :' || SQLERRM);
      p_mail.end_attachment(conn => conn);
      P_MAIL.END_MAIL(CONN => CONN);
  END PR_MAIL_LISTAS_CAUTELA;

  PROCEDURE PR_OBTENER_PERFIL_CLIENTE(P_CODIGO_PERFIL OUT NUMBER,
                                      P_PERFIL        OUT VARCHAR2,
                                      P_CLOB          OUT CLOB) IS
    CURSOR PERFIL_PUNTUACION IS
      SELECT NVL(SUM(REPR_PUNTUACION), 0), NVL(COUNT(REPR_PUNTUACION), 0)
        FROM RESPUESTAS_PERFIL_RIESGO, GL_RESPUESTAS_PERFIL
       WHERE REPR_ESTADO = 'A'
         AND REPR_CONSECUTIVO = GLRE_CODIGO_RESPUESTA;

    CURSOR PERFIL_EXISTE IS
      SELECT COUNT(REPR_PUNTUACION)
        FROM RESPUESTAS_PERFIL_RIESGO, GL_RESPUESTAS_PERFIL
       WHERE REPR_ESTADO = 'A'
         AND REPR_CONSECUTIVO = GLRE_CODIGO_RESPUESTA;

    CURSOR PERFIL_CLIENTE(P_PUNTUACION NUMBER) IS
      SELECT PERI_CONSECUTIVO, PERI_DESCRIPCION
        FROM PERFILES_RIESGO
       WHERE P_PUNTUACION BETWEEN PERI_PUNTAJE_DESDE AND PERI_PUNTAJE_HASTA;

    V_ERRORES    NUMBER;
    V_PUNTUACION RESPUESTAS_PERFIL_RIESGO.REPR_PUNTUACION%TYPE;
    V_CONTADOR   NUMBER;
  BEGIN

    V_ERRORES       := 0;
    V_PUNTUACION    := 0;
    P_CLOB          := NULL;
    P_PERFIL        := NULL;
    P_CODIGO_PERFIL := NULL;
    V_CONTADOR      := 0;

    OPEN PERFIL_PUNTUACION;
    FETCH PERFIL_PUNTUACION
      INTO V_PUNTUACION, V_CONTADOR;
    CLOSE PERFIL_PUNTUACION;

    V_PUNTUACION := NVL(V_PUNTUACION, 0);
    V_CONTADOR   := NVL(V_CONTADOR, 0);

    IF V_CONTADOR != 5 THEN
      V_ERRORES := V_ERRORES + 1;
    END IF;

    OPEN PERFIL_CLIENTE(V_PUNTUACION);
    FETCH PERFIL_CLIENTE
      INTO P_CODIGO_PERFIL, P_PERFIL;
    IF PERFIL_CLIENTE%NOTFOUND THEN
      V_ERRORES := V_ERRORES + 1;
    END IF;
    CLOSE PERFIL_CLIENTE;

    IF V_ERRORES > 0 THEN
      P_CODIGO_PERFIL := 1000;
      P_PERFIL        := 'NO';
      P_CAB.CrearError('Error calculando Perfil del Cliente puntuacion:' ||
                       V_PUNTUACION || ' Cantidad de preguntas: ' ||
                       V_CONTADOR);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('ObtenerPerfilCliente');
    END IF;

    DELETE GL_RESPUESTAS_PERFIL;

  END PR_OBTENER_PERFIL_CLIENTE;

  PROCEDURE PR_PERSONAS_RLC_VINCULA(P_NUMERO_FORMULARIO    IN NUMBER,
                                    P_CLI_PER_NUM_IDEN     IN VARCHAR2,
                                    P_CLI_PER_TID_CODIGO   IN VARCHAR2,
                                    P_FECHA_APERTURA       IN VARCHAR2,
                                    P_ESTADO               IN VARCHAR2,
                                    P_PER_NUM_IDEN         IN VARCHAR2,
                                    P_PER_TID_CODIGO       IN VARCHAR2,
                                    P_PRIMER_APELLIDO      IN VARCHAR2,
                                    P_SEGUNDO_APELLIDO     IN VARCHAR2,
                                    P_NOMBRE               IN VARCHAR2,
                                    P_TIPO_SEXO            IN VARCHAR2,
                                    P_ROL_ORDENANTE        IN NUMBER,
                                    P_CARGO                IN VARCHAR2,
                                    P_CELULAR              IN VARCHAR2,
                                    P_TELEFONO             IN VARCHAR2,
                                    P_DIRECCION_OFICINA    IN VARCHAR2,
                                    P_CIUDAD_OFICINA       IN NUMBER,
                                    P_FECHA_EXP_DOCUMENTO  IN VARCHAR2,
                                    P_CIUDAD_EXP_DOCUMENTO IN NUMBER,
                                    P_CALIDAD              IN VARCHAR2,
                                    P_PARENTESCO           IN NUMBER,
                                    P_DIRECCION_EMAIL      IN VARCHAR2,
                                    P_CLOB                 OUT CLOB) IS

    V_ERRORES NUMBER;
  BEGIN
    P_CLOB    := NULL;
    V_ERRORES := 0;

    IF LENGTH(NVL(P_PRIMER_APELLIDO, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Primer Apellido superior a 20 caracteres');
    END IF;

    IF P_SEGUNDO_APELLIDO IS NOT NULL THEN
      IF LENGTH(NVL(P_SEGUNDO_APELLIDO, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Segundo Apellido superior a 20 caracteres');
      END IF;
    END IF;

    IF LENGTH(NVL(P_NOMBRE, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Nombre superior a 20 caracteres');
    END IF;

    IF LENGTH(NVL(P_CARGO, ' ')) > 40 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Cargo superior a 40 caracteres');
    END IF;

    IF LENGTH(NVL(P_CELULAR, ' ')) > 30 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Celular superior a 30 caracteres');
    END IF;

    IF LENGTH(NVL(P_TELEFONO, ' ')) > 15 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Telefono superior a 30 caracteres');
    END IF;

    IF LENGTH(NVL(P_DIRECCION_OFICINA, ' ')) > 80 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Direccion superior a 80 caracteres');
    END IF;

    IF P_ROL_ORDENANTE IS NULL THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Rol invalido');
    END IF;

    IF V_ERRORES = 0 THEN
      BEGIN
        INSERT INTO PERSONAS_RELACIONADAS_VINCULA
          (PERV_CONSECUTIVO,
           PERV_NUMERO_FORMULARIO,
           PERV_CLI_PER_NUM_IDEN,
           PERV_CLI_PER_TID_CODIGO,
           PERV_FECHA_APERTURA,
           PERV_ESTADO,
           PERV_PER_NUM_IDEN,
           PERV_PER_TID_CODIGO,
           PERV_PRIMER_APELLIDO,
           PERV_SEGUNDO_APELLIDO,
           PERV_NOMBRE,
           PERV_TIPO_SEXO,
           PERV_ROL_ORDENANTE,
           PERV_CARGO,
           PERV_CELULAR,
           PERV_TELEFONO,
           PERV_DIRECCION_OFICINA,
           PERV_CIUDAD_OFICINA,
           PERV_FECHA_EXP_DOCUMENTO,
           PERV_CIUDAD_EXP_DOCUMENTO,
           PERV_CALIDAD,
           PERV_PARENTESCO,
           PERV_DIRECCION_EMAIL,
           PERV_FECHA_INGRESO)
        VALUES
          (PERV_SEQ.NEXTVAL, --PERV_CONSECUTIVO
           P_NUMERO_FORMULARIO, --PERV_NUMERO_FORMULARIO
           P_CLI_PER_NUM_IDEN, --PERV_CLI_PER_NUM_IDEN
           P_CLI_PER_TID_CODIGO, --PERV_CLI_PER_TID_CODIGO
           TO_DATE(P_FECHA_APERTURA, 'DD-MM-YYYY'), --PERV_FECHA_APERTURA,
           P_ESTADO, --PERV_ESTADO,
           P_PER_NUM_IDEN, --PERV_PER_NUM_IDEN,
           P_PER_TID_CODIGO, --PERV_PER_TID_CODIGO,
           UPPER(P_PRIMER_APELLIDO), --PERV_PRIMER_APELLIDO,
           UPPER(P_SEGUNDO_APELLIDO), --PERV_SEGUNDO_APELLIDO,
           UPPER(P_NOMBRE), --PERV_NOMBRE,
           P_TIPO_SEXO, --PERV_TIPO_SEXO,
           P_ROL_ORDENANTE, --PERV_ROL_ORDENANTE,
           P_CARGO, --PERV_CARGO,
           P_CELULAR, --PERV_CELULAR,
           P_TELEFONO, --PERV_TELEFONO,
           P_DIRECCION_OFICINA, --PERV_DIRECCION_OFICINA,
           P_CIUDAD_OFICINA, --PERV_CIUDAD_OFICINA,
           TO_DATE(P_FECHA_EXP_DOCUMENTO, 'DD-MM-YYYY'), --PERV_FECHA_EXP_DOCUMENTO,
           P_CIUDAD_EXP_DOCUMENTO, --PERV_CIUDAD_EXP_DOCUMENTO,
           DECODE(P_CALIDAD,
                  'Ordenante',
                  'OR',
                  'Representante',
                  'RE',
                  'Apoderado',
                  'AP',
                  'Padre Menor de Edad',
                  'PM'), --PERV_CALIDAD,
           P_PARENTESCO, --PERV_PARENTESCO
           P_DIRECCION_EMAIL, --PERV_DIRECCION_EMAIL
           SYSDATE);

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRORES := V_ERRORES + 1;
          P_CAB.CrearError('Error creando persona relacionada:' || SQLERRM);
        END IF;
      END;
    END IF;

    IF V_ERRORES = 0 THEN
      COMMIT;
    ELSE
      UPDATE PERSONAS_RELACIONADAS_VINCULA
         SET PERV_ESTADO              = 'NO_PROCESADO',
             PERV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('PersonasRlcVincula');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      UPDATE PERSONAS_RELACIONADAS_VINCULA
         SET PERV_ESTADO              = 'NO_PROCESADO',
             PERV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CAB.CrearError('Error creando persona relacionada:' || SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('PersonasRlcVincula');

  END PR_PERSONAS_RLC_VINCULA;

  PROCEDURE PR_SEGUNDOS_OCL_VINCULA(P_NUMERO_FORMULARIO          IN NUMBER,
                                    P_CLI_PER_NUM_IDEN           IN VARCHAR2,
                                    P_CLI_PER_TID_CODIGO         IN VARCHAR2,
                                    P_FECHA_APERTURA             IN VARCHAR2,
                                    P_ESTADO                     IN VARCHAR2,
                                    P_PER_NUM_IDEN               IN VARCHAR2,
                                    P_PER_TID_CODIGO             IN VARCHAR2,
                                    P_PRIMER_APELLIDO            IN VARCHAR2,
                                    P_SEGUNDO_APELLIDO           IN VARCHAR2,
                                    P_NOMBRE                     IN VARCHAR2,
                                    P_CIUDAD_EXP_DOCUMENTO       IN NUMBER,
                                    P_FECHA_EXP_DOCUMENTO        IN VARCHAR2,
                                    P_TIPO_SEXO                  IN VARCHAR2,
                                    P_NACIONALIDAD               IN VARCHAR2,
                                    P_ESTADO_CIVIL               IN VARCHAR2,
                                    P_CIUDAD_NACIMIENTO          IN NUMBER,
                                    P_FECHA_NACIMIENTO           IN VARCHAR2,
                                    P_DIRECCION_EMAIL            IN VARCHAR2,
                                    P_PROFESION                  IN VARCHAR2,
                                    P_EMPRESA                    IN VARCHAR2,
                                    P_CARGO                      IN VARCHAR2,
                                    P_ACTIVIDAD                  IN VARCHAR2,
                                    P_ORIGEN_RECURSOS            IN VARCHAR2,
                                    P_RECURSOS_ENTREGAR          IN VARCHAR2,
                                    P_CODIGO_CIIU                IN VARCHAR2,
                                    P_EXPERIENCIA_SECTOR_PU      IN VARCHAR2,
                                    P_OTRO_ORIGEN_RECURSOS       IN VARCHAR2,
                                    P_OTRO_RECURSOS_ENTREGAR     IN VARCHAR2,
                                    P_DIRECCION_RESIDENCIA       IN VARCHAR2,
                                    P_CIUDAD_RESIDENCIA          IN NUMBER,
                                    P_TELEFONO_RESIDENCIA        IN VARCHAR2,
                                    P_DIRECCION_OFICINA          IN VARCHAR2,
                                    P_CIUDAD_OFICINA             IN NUMBER,
                                    P_TELEFONO_OFICINA           IN VARCHAR2,
                                    P_APARTADO_AEREO             IN VARCHAR2,
                                    P_FAX                        IN VARCHAR2,
                                    P_CELULAR                    IN VARCHAR2,
                                    P_INGRESOS_MEN_OPERACIONALES IN NUMBER,
                                    P_EGRESOS_MEN_OPERACIONALES  IN NUMBER,
                                    P_INGRESOS_MEN_NO_OPERA      IN NUMBER,
                                    P_EGRESOS_MEN_NO_OPERA       IN NUMBER,
                                    P_ACTIVOS                    IN NUMBER,
                                    P_PASIVOS                    IN NUMBER,
                                    P_PATRIMONIO                 IN NUMBER,
                                    P_CLOB                       OUT CLOB) IS

    CURSOR VALIDA_CLIENTE(P_PER_NUM_IDEN   VARCHAR2,
                          P_PER_TID_CODIGO VARCHAR2) IS
      SELECT CLI_ECL_MNEMONICO, CLI_TIPO_CLIENTE
        FROM ESTADOS_CLIENTE, CLIENTES
       WHERE ECL_MNEMONICO = CLI_ECL_MNEMONICO
         AND ECL_COLOCAR_ORDEN = 'S'
         AND CLI_PER_NUM_IDEN = P_PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = P_PER_TID_CODIGO
         AND CLI_TIPO_CLIENTE IN ('C', 'S', 'A');

    V_ERRORES        NUMBER;
    C_VALIDA_CLIENTE VALIDA_CLIENTE%ROWTYPE;
  BEGIN
    P_CLOB    := NULL;
    V_ERRORES := 0;

    C_VALIDA_CLIENTE := NULL;
    OPEN VALIDA_CLIENTE(TRIM(P_PER_NUM_IDEN), TRIM(P_PER_TID_CODIGO));
    FETCH VALIDA_CLIENTE
      INTO C_VALIDA_CLIENTE;
    CLOSE VALIDA_CLIENTE;

    C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE := NVL(C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE,
                                             'N');

    IF P_CLI_PER_NUM_IDEN IS NULL OR P_CLI_PER_TID_CODIGO IS NULL THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Tipo o Numero de identifiacion no validos del cliente');
    END IF;

    IF P_PER_NUM_IDEN IS NULL OR P_PER_TID_CODIGO IS NULL THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Tipo o Numero de identifiacion no validos del segundo titular');
    END IF;

    IF C_VALIDA_CLIENTE.CLI_TIPO_CLIENTE = 'N' THEN
      IF LENGTH(NVL(P_PRIMER_APELLIDO, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Primer Apellido superior a 20 caracteres');
      END IF;

      IF LENGTH(NVL(P_SEGUNDO_APELLIDO, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Segundo Apellido superior a 20 caracteres');
      END IF;

      IF LENGTH(NVL(P_NOMBRE, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Nombre superior a 20 caracteres');
      END IF;

      IF LENGTH(NVL(P_DIRECCION_EMAIL, ' ')) > 80 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Direccion correo superior a 80 caracteres');
      END IF;

      IF LENGTH(NVL(P_EMPRESA, ' ')) > 40 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Nombre empresa superior a 40 caracteres');
      END IF;

      IF LENGTH(NVL(P_CARGO, ' ')) > 40 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Cargo superior a 40 caracteres');
      END IF;

      IF LENGTH(NVL(P_CELULAR, ' ')) > 30 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Celular superior a 30 caracteres');
      END IF;

      IF LENGTH(NVL(P_DIRECCION_OFICINA, ' ')) > 80 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Direccion Oficina superior a 80 caracteres');
      END IF;

      IF LENGTH(NVL(P_OTRO_ORIGEN_RECURSOS, ' ')) > 40 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Detalle Otro Origen Recursos superior a 40 caracteres');
      END IF;

      IF LENGTH(NVL(P_OTRO_RECURSOS_ENTREGAR, ' ')) > 40 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Detalle Otro Recursos a entregar superior a 40 caracteres');
      END IF;

      IF LENGTH(NVL(P_DIRECCION_RESIDENCIA, ' ')) > 80 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Direccion residencia superior a 80 caracteres');
      END IF;

      IF LENGTH(NVL(P_TELEFONO_RESIDENCIA, ' ')) > 15 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Telefono residencia superior a 15 caracteres');
      END IF;

      IF LENGTH(NVL(P_TELEFONO_OFICINA, ' ')) > 15 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Telefono oficina superior a 15 caracteres');
      END IF;

      IF LENGTH(NVL(P_APARTADO_AEREO, ' ')) > 20 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Aparatdo Aereo superior a 20 caracteres');
      END IF;

      IF LENGTH(NVL(P_FAX, ' ')) > 15 THEN
        V_ERRORES := V_ERRORES + 1;
        P_CAB.CrearError('Numero Fax superior a 15 caracteres');
      END IF;
    END IF;

    IF V_ERRORES = 0 THEN
      BEGIN
        INSERT INTO SEGUNDOS_TITULARES_VINCULA
          (SETV_CONSECUTIVO,
           SETV_NUMERO_FORMULARIO,
           SETV_CLI_PER_NUM_IDEN,
           SETV_CLI_PER_TID_CODIGO,
           SETV_FECHA_APERTURA,
           SETV_ESTADO,
           SETV_PER_NUM_IDEN,
           SETV_PER_TID_CODIGO,
           SETV_PRIMER_APELLIDO,
           SETV_SEGUNDO_APELLIDO,
           SETV_NOMBRE,
           SETV_CIUDAD_EXP_DOCUMENTO,
           SETV_FECHA_EXP_DOCUMENTO,
           SETV_TIPO_SEXO,
           SETV_NACIONALIDAD,
           SETV_ESTADO_CIVIL,
           SETV_CIUDAD_NACIMIENTO,
           SETV_FECHA_NACIMIENTO,
           SETV_DIRECCION_EMAIL,
           SETV_PROFESION,
           SETV_EMPRESA,
           SETV_CARGO,
           SETV_ACTIVIDAD,
           SETV_ORIGEN_RECURSOS,
           SETV_RECURSOS_ENTREGAR,
           SETV_CODIGO_CIIU,
           SETV_EXPERIENCIA_SECTOR_PU,
           SETV_FECHA_INGRESO,
           SETV_OTRO_ORIGEN_RECURSOS,
           SETV_OTRO_RECURSOS_ENTREGAR,
           SETV_DIRECCION_RESIDENCIA,
           SETV_CIUDAD_RESIDENCIA,
           SETV_TELEFONO_RESIDENCIA,
           SETV_DIRECCION_OFICINA,
           SETV_CIUDAD_OFICINA,
           SETV_TELEFONO_OFICINA,
           SETV_APARTADO_AEREO,
           SETV_FAX,
           SETV_CELULAR,
           SETV_ING_MEN_OPERACIONALES,
           SETV_EGRESOS_MEN_OPERACIONALES,
           SETV_INGRESOS_MEN_NO_OPERA,
           SETV_EGRESOS_MEN_NO_OPERA,
           SETV_ACTIVOS,
           SETV_PASIVOS,
           SETV_PATRIMONIO)
        VALUES
          (SETV_SEQ.NEXTVAL, --  SETV_CONSECUTIVO
           P_NUMERO_FORMULARIO, --  SETV_NUMERO_FORMULARIO
           P_CLI_PER_NUM_IDEN, --  SETV_CLI_PER_NUM_IDEN
           P_CLI_PER_TID_CODIGO, --  SETV_CLI_PER_TID_CODIGO
           TO_DATE(P_FECHA_APERTURA, 'DD-MM-YYYY'), --  SETV_FECHA_APERTURA
           P_ESTADO, --  SETV_ESTADO
           P_PER_NUM_IDEN, --  SETV_PER_NUM_IDEN
           P_PER_TID_CODIGO, --  SETV_PER_TID_CODIGO
           UPPER(P_PRIMER_APELLIDO), --  SETV_PRIMER_APELLIDO
           UPPER(P_SEGUNDO_APELLIDO), --  SETV_SEGUNDO_APELLIDO
           UPPER(P_NOMBRE), --  SETV_NOMBRE
           P_CIUDAD_EXP_DOCUMENTO, --  SETV_CIUDAD_EXP_DOCUMENTO
           TO_DATE(P_FECHA_EXP_DOCUMENTO, 'DD-MM-YYYY'), --  SETV_FECHA_EXP_DOCUMENTO
           P_TIPO_SEXO, --  SETV_TIPO_SEXO
           P_NACIONALIDAD, --  SETV_NACIONALIDAD
           P_ESTADO_CIVIL, --  SETV_ESTADO_CIVIL
           P_CIUDAD_NACIMIENTO, --  SETV_CIUDAD_NACIMIENTO
           TO_DATE(P_FECHA_NACIMIENTO, 'DD-MM-YYYY'), --  SETV_FECHA_NACIMIENTO
           P_DIRECCION_EMAIL, --  SETV_DIRECCION_EMAIL
           P_PROFESION, --  SETV_PROFESION
           UPPER(P_EMPRESA), --  SETV_EMPRESA
           UPPER(P_CARGO), --  SETV_CARGO
           P_ACTIVIDAD, --  SETV_ACTIVIDAD
           P_ORIGEN_RECURSOS, --  SETV_ORIGEN_RECURSOS
           P_RECURSOS_ENTREGAR, --  SETV_RECURSOS_ENTREGAR
           P_CODIGO_CIIU, --  SETV_CODIGO_CIIU
           P_EXPERIENCIA_SECTOR_PU, --  SETV_EXPERIENCIA_SECTOR_PU
           SYSDATE, --  SETV_FECHA_INGRESO
           P_OTRO_ORIGEN_RECURSOS, --  SETV_OTRO_ORIGEN_RECURSOS
           P_OTRO_RECURSOS_ENTREGAR, --  SETV_OTRO_RECURSOS_ENTREGAR
           P_DIRECCION_RESIDENCIA, --  SETV_DIRECCION_RESIDENCIA
           P_CIUDAD_RESIDENCIA, --  SETV_CIUDAD_RESIDENCIA
           P_TELEFONO_RESIDENCIA, --  SETV_TELEFONO_RESIDENCIA
           P_DIRECCION_OFICINA, --  SETV_DIRECCION_OFICINA
           P_CIUDAD_OFICINA, --  SETV_CIUDAD_OFICINA
           P_TELEFONO_OFICINA, --  SETV_TELEFONO_OFICINA
           P_APARTADO_AEREO, --  SETV_APARTADO_AEREO
           P_FAX, --  SETV_FAX
           P_CELULAR, --  SETV_CELULAR
           P_INGRESOS_MEN_OPERACIONALES, --  SETV_ING_MEN_OPERACIONALES
           P_EGRESOS_MEN_OPERACIONALES, --  SETV_EGRESOS_MEN_OPERACIONALES
           P_INGRESOS_MEN_NO_OPERA, --  SETV_INGRESOS_MEN_NO_OPERA
           P_EGRESOS_MEN_NO_OPERA, --  SETV_EGRESOS_MEN_NO_OPERA
           P_ACTIVOS, --  SETV_ACTIVOS
           P_PASIVOS, --  SETV_PASIVOS
           P_PATRIMONIO --  SETV_PATRIMONIO
           );

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRORES := V_ERRORES + 1;
          P_CAB.CrearError('Error creando segundo titular:' || SQLERRM);
        END IF;
      END;
    END IF;

    IF V_ERRORES = 0 THEN
      COMMIT;
    ELSE
      UPDATE SEGUNDOS_TITULARES_VINCULA
         SET SETV_ESTADO              = 'NO_PROCESADO',
             SETV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE SETV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('SegundosOclVincula');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      UPDATE SEGUNDOS_TITULARES_VINCULA
         SET SETV_ESTADO              = 'NO_PROCESADO',
             SETV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE SETV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CAB.CrearError('Error creando segundo titular:' || SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('SegundosOclVincula');

  END PR_SEGUNDOS_OCL_VINCULA;

  PROCEDURE PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO  IN NUMBER,
                                   P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                   P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                   P_FECHA_APERTURA     IN VARCHAR2,
                                   P_ESTADO             IN VARCHAR2,
                                   P_BANCO              IN VARCHAR2,
                                   P_NUMERO_CUENTA      IN VARCHAR2,
                                   P_TIPO               IN VARCHAR2,
                                   P_SUCURSAL           IN VARCHAR2,
                                   P_DIRECCION          IN VARCHAR2,
                                   P_TELEFONO           IN VARCHAR2,
                                   P_CLOB               OUT CLOB) IS
    V_ERRORES NUMBER;
  BEGIN
    P_CLOB    := NULL;
    V_ERRORES := 0;

    IF LENGTH(NVL(P_NUMERO_CUENTA, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Numero de cuenta superior a 20 caracteres');
    END IF;

    IF LENGTH(NVL(P_SUCURSAL, ' ')) > 40 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Nombre Sucursal superior a 40 caracteres');
    END IF;

    IF LENGTH(NVL(P_DIRECCION, ' ')) > 80 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Direccion Sucursal superior a 80 caracteres');
    END IF;

    IF LENGTH(NVL(P_TELEFONO, ' ')) > 15 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Telefono Sucursal superior a 15 caracteres');
    END IF;

    IF V_ERRORES = 0 THEN
      BEGIN
        INSERT INTO CUENTAS_BANCARIAS_VINCULACION
          (CBVI_CONSECUTIVO,
           CBVI_NUMERO_FORMULARIO,
           CBVI_CLI_PER_NUM_IDEN,
           CBVI_CLI_PER_TID_CODIGO,
           CBVI_FECHA_APERTURA,
           CBVI_ESTADO,
           CBVI_FECHA_INGRESO,
           CBVI_BANCO,
           CBVI_NUMERO_CUENTA,
           CBVI_TIPO,
           CBVI_SUCURSAL,
           CBVI_DIRECCION,
           CBVI_TELEFONO)
        VALUES
          (CBVI_SEQ.NEXTVAL, -- CBVI_CONSECUTIVO,
           P_NUMERO_FORMULARIO, --CBVI_NUMERO_FORMULARIO,
           P_CLI_PER_NUM_IDEN, --CBVI_CLI_PER_NUM_IDEN,
           P_CLI_PER_TID_CODIGO, --CBVI_CLI_PER_TID_CODIGO,
           TO_DATE(P_FECHA_APERTURA, 'DD-MM-YYYY'), --CBVI_FECHA_APERTURA,
           P_ESTADO, --CBVI_ESTADO,
           SYSDATE, --CBVI_FECHA_INGRESO,
           P_BANCO, --CBVI_BANCO,
           P_NUMERO_CUENTA, --CBVI_NUMERO_CUENTA,
           P_TIPO, --CBVI_TIPO,
           P_SUCURSAL, --CBVI_SUCURSAL,
           P_DIRECCION, --CBVI_DIRECCION,
           P_TELEFONO --CBVI_TELEFONO,
           );

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRORES := V_ERRORES + 1;
          P_CAB.CrearError('Error creando segundo titular:' || SQLERRM);
        END IF;
      END;
    END IF;

    IF V_ERRORES = 0 THEN
      COMMIT;
    ELSE
      UPDATE CUENTAS_BANCARIAS_VINCULACION
         SET CBVI_ESTADO              = 'NO_PROCESADO',
             CBVI_FECHA_PROCESAMIENTO = SYSDATE
       WHERE CBVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('SegundosOclVincula');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      UPDATE CUENTAS_BANCARIAS_VINCULACION
         SET CBVI_ESTADO              = 'NO_PROCESADO',
             CBVI_FECHA_PROCESAMIENTO = SYSDATE
       WHERE CBVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CAB.CrearError('Error creando cuentas bancarias titular:' ||
                       SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('CuentasBanVincula');

  END PR_CUENTAS_BAN_VINCULA;

  PROCEDURE PR_CUENTAS_BAN_EXT_VINCULA(P_NUMERO_FORMULARIO  IN NUMBER,
                                       P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                       P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                       P_FECHA_APERTURA     IN VARCHAR2,
                                       P_ESTADO             IN VARCHAR2,
                                       P_BANCO              IN VARCHAR2,
                                       P_NUMERO_CUENTA      IN VARCHAR2,
                                       P_CIUDAD             IN NUMBER,
                                       P_MONEDA             IN VARCHAR2,
                                       P_COMPENSACION       IN VARCHAR2,
                                       P_TIPO_OPERACION     IN VARCHAR2,
                                       P_CLOB               OUT CLOB) IS
    V_ERRORES NUMBER;
  BEGIN
    P_CLOB    := NULL;
    V_ERRORES := 0;
    IF LENGTH(NVL(P_NUMERO_CUENTA, ' ')) > 20 THEN
      V_ERRORES := V_ERRORES + 1;
      P_CAB.CrearError('Numero de cuenta superior a 20 caracteres');
    END IF;

    IF V_ERRORES = 0 THEN
      BEGIN
        INSERT INTO CUENTAS_BANCARIAS_EXT_VINCULA
          (CBEV_CONSECUTIVO,
           CBEV_NUMERO_FORMULARIO,
           CBEV_CLI_PER_NUM_IDEN,
           CBEV_CLI_PER_TID_CODIGO,
           CBEV_FECHA_APERTURA,
           CBEV_ESTADO,
           CBEV_BANCO,
           CBEV_NUMERO_CUENTA,
           CBEV_CIUDAD,
           CBEV_MONEDA,
           CBEV_COMPENSACION,
           CBEV_TIPO_OPERACION,
           CBEV_FECHA_INGRESO)
        VALUES
          (CBEV_SEQ.NEXTVAL, --CBEV_CONSECUTIVO,
           P_NUMERO_FORMULARIO, --CBEV_NUMERO_FORMULARIO,
           P_CLI_PER_NUM_IDEN, --CBEV_CLI_PER_NUM_IDEN,
           P_CLI_PER_TID_CODIGO, --CBEV_CLI_PER_TID_CODIGO,
           TO_DATE(P_FECHA_APERTURA, 'DD-MM-YYYY'), --CBEV_FECHA_APERTURA,
           P_ESTADO, --CBEV_ESTADO,
           P_BANCO, --CBEV_BANCO,
           P_NUMERO_CUENTA, --CBEV_NUMERO_CUENTA,
           P_CIUDAD, --CBEV_CIUDAD,
           P_MONEDA, --CBEV_MONEDA,
           P_COMPENSACION, --CBEV_COMPENSACION,
           P_TIPO_OPERACION, --CBEV_TIPO_OPERACION,
           SYSDATE --CBEV_FECHA_INGRESO)
           );

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRORES := V_ERRORES + 1;
          P_CAB.CrearError('Error creando cuentas bancarias exterior titular:' ||
                           SQLERRM);
        END IF;
      END;
    END IF;

    IF V_ERRORES = 0 THEN
      COMMIT;
    ELSE
      UPDATE CUENTAS_BANCARIAS_EXT_VINCULA
         SET CBEV_ESTADO              = 'NO_PROCESADO',
             CBEV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE CBEV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('CuentasBanExtVincula');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      UPDATE CUENTAS_BANCARIAS_EXT_VINCULA
         SET CBEV_ESTADO              = 'NO_PROCESADO',
             CBEV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE CBEV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CAB.CrearError('Error creando cuentas bancarias exterior titular:' ||
                       SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('CuentasBanExtVincula');
  END PR_CUENTAS_BAN_EXT_VINCULA;

  PROCEDURE PR_INFORMACION_REV_VINCULA(P_NUMERO_FORMULARIO  IN NUMBER,
                                       P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                       P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                       P_FECHA_APERTURA     IN VARCHAR2,
                                       P_ESTADO             IN VARCHAR2,
                                       P_PER_NUM_IDEN       IN VARCHAR2,
                                       P_PER_TID_CODIGO     IN VARCHAR2,
                                       P_ROL_ORDENANTE      IN NUMBER,
                                       P_PARENTESCO         IN NUMBER,
                                       P_CLOB               OUT CLOB) IS

    V_ERRORES NUMBER;
  BEGIN
    P_CLOB    := NULL;
    V_ERRORES := 0;

    IF V_ERRORES = 0 THEN
      BEGIN
        INSERT INTO INFORMACIONES_REVELA_VINCULA
          (IFRV_CONSECUTIVO,
           IFRV_NUMERO_FORMULARIO,
           IFRV_CLI_PER_NUM_IDEN,
           IFRV_CLI_PER_TID_CODIGO,
           IFRV_FECHA_APERTURA,
           IFRV_ESTADO,
           IFRV_PER_NUM_IDEN,
           IFRV_PER_TID_CODIGO,
           IFRV_ROL_ORDENANTE,
           IFRV_FECHA_INGRESO,
           IFRV_PARENTESCO)
        VALUES
          (IFRV_SEQ.NEXTVAL, --IFRV_CONSECUTIVO
           P_NUMERO_FORMULARIO, --IFRV_NUMERO_FORMULARIO
           P_CLI_PER_NUM_IDEN, --IFRV_CLI_PER_NUM_IDEN
           P_CLI_PER_TID_CODIGO, --IFRV_CLI_PER_TID_CODIGO
           TO_DATE(P_FECHA_APERTURA, 'DD-MM-YYYY'), --IFRV_FECHA_APERTURA,
           P_ESTADO, --IFRV_ESTADO,
           P_PER_NUM_IDEN, --IFRV_PER_NUM_IDEN,
           P_PER_TID_CODIGO, --IFRV_PER_TID_CODIGO,
           P_ROL_ORDENANTE, --IFRV_ROL_ORDENANTE,
           SYSDATE, --IFRV_FECHA_INGRESO
           P_PARENTESCO --PERV_PARENTESCO
           );

        IF SQL%ROWCOUNT = 0 THEN
          V_ERRORES := V_ERRORES + 1;
          P_CAB.CrearError('Error creando informacion revelacion titular:' ||
                           SQLERRM);
        END IF;
      END;
    END IF;

    IF V_ERRORES = 0 THEN
      COMMIT;
    ELSE
      UPDATE INFORMACIONES_REVELA_VINCULA
         SET IFRV_ESTADO              = 'NO_PROCESADO',
             IFRV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE IFRV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('InformacionRevVincula');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      UPDATE INFORMACIONES_REVELA_VINCULA
         SET IFRV_ESTADO              = 'NO_PROCESADO',
             IFRV_FECHA_PROCESAMIENTO = SYSDATE
       WHERE IFRV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO;
      COMMIT;
      P_CAB.CrearError('Error creando informacion revelacion titular:' ||
                       SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('InformacionRevVincula');
  END PR_INFORMACION_REV_VINCULA;

  PROCEDURE PR_REVERSION_VINCULACION(P_NUMERO_FORMULARIO  IN NUMBER,
                                     P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                     P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                     P_LLAMADO            IN VARCHAR,
                                     P_CLOB               OUT CLOB) IS
  BEGIN

    /* REVERSAR CLIENTE CON INFORMACION PARCIAL CREADA*/
    /* DELETE PERSONAS_RELACIONADAS
        WHERE EXISTS (SELECT 'X' FROM PERSONAS_RELACIONADAS_VINCULA
                      WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
                        AND PERV_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
                        AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                        AND TRIM(PERV_CLI_PER_NUM_IDEN)||' '||PERV_CLI_PER_TID_CODIGO  = TRIM(RLC_CLI_PER_NUM_IDEN)||' '||TRIM(RLC_CLI_PER_TID_CODIGO)
                        AND PERV_ESTADO= 'POR_PROCESAR');

        DELETE SEGMENTACION_CLIENTES
        WHERE SGC_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
          AND SGC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO;

        DELETE SEGMENTACION_CLIENTES
        WHERE EXISTS(SELECT 'X' FROM SEGUNDOS_TITULARES_VINCULA
                     WHERE SETV_NUMERO_FORMULARIO  = P_NUMERO_FORMULARIO
                       AND SETV_CLI_PER_NUM_IDEN   = P_CLI_PER_NUM_IDEN
                       AND SETV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
                       AND TRIM(SETV_CLI_PER_NUM_IDEN)||' '||SETV_CLI_PER_TID_CODIGO  = TRIM(SETV_PER_NUM_IDEN)||' '||TRIM(SETV_PER_TID_CODIGO)
                       AND SETV_ESTADO = 'POR_PROCESAR');


            /*


    DELETE SEGMENTACION_CLIENTES
    WHERE SGC_CLI_PER_NUM_IDEN = '10721072';

    DELETE ESTADOS_ECONOMICOS
    WHERE EEC_CLI_PER_NUM_IDEN = '10721072';


    DELETE CUENTAS_CLIENTE_CORREDORES
    WHERE CCC_CLI_PER_NUM_IDEN = '10721072';

    DELETE OS_CLIENTES


    DELETE CLIENTES
    WHERE CLI_PER_NUM_IDEN = '10721072';

    DELETE CONTROL_ACTUALIZACIONES
    WHERE CAC_CLI_PER_NUM_IDEN IN ('43535','1234567','10721072');



    DELETE PERSONAS WHERE PER_NUM_IDEN IN ('43535','1234567','10721072');




        INSERT INTO CLIENTES
    INSERT INTO PERSONAS
    INSERT INTO PERSONAS_RELACIONADAS
    INSERT INTO ESTADOS_ECONOMICOS
    INSERT INTO CUENTAS_BANCARIAS_CLIENTES
    INSERT INTO CUENTAS_BANCARIAS_CLIENTES_EXT
    INSERT INTO OS_CLIENTES
    CUENTAS_CLIENTE_CORREDORES
    */

    /* P_LLAMADO = Interno retorna error en procesamiento creacion cliente
    = Carga iniicial de borrado */

    /* MARCAR ARCHIVOS COMO NO PROCESADOS*/
    UPDATE PERSONAS_RELACIONADAS_VINCULA
       SET PERV_ESTADO = 'NO_PROCESADO', PERV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND PERV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND PERV_ESTADO = 'POR_PROCESAR';

    UPDATE SEGUNDOS_TITULARES_VINCULA
       SET SETV_ESTADO = 'NO_PROCESADO', SETV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE SETV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND SETV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND SETV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND SETV_ESTADO = 'POR_PROCESAR';

    UPDATE CUENTAS_BANCARIAS_VINCULACION
       SET CBVI_ESTADO = 'NO_PROCESADO', CBVI_FECHA_PROCESAMIENTO = SYSDATE
     WHERE CBVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND CBVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND CBVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND CBVI_ESTADO = 'POR_PROCESAR';

    UPDATE CUENTAS_BANCARIAS_EXT_VINCULA
       SET CBEV_ESTADO = 'NO_PROCESADO', CBEV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE CBEV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND CBEV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND CBEV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND CBEV_ESTADO = 'POR_PROCESAR';

    UPDATE INFORMACIONES_REVELA_VINCULA
       SET IFRV_ESTADO = 'NO_PROCESADO', IFRV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE IFRV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND IFRV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND IFRV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND IFRV_ESTADO = 'POR_PROCESAR';

    UPDATE ACCIONISTAS_VINCULA
       SET ACVI_ESTADO = 'NO_PROCESADO', ACVI_FECHA_PROCESAMIENTO = SYSDATE
     WHERE ACVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND ACVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND ACVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND ACVI_ESTADO = 'POR_PROCESAR';

  EXCEPTION
    WHEN OTHERS THEN
      IF P_LLAMADO = 'Creacion' THEN
        P_CAB.CrearError('Error creando informacion titular:' || SQLERRM);
        P_CLOB := P_CAB.ObtenerCLOB_ERROR('DatosClienteVincula');
      ELSIF P_LLAMADO = 'Cargue' THEN
        P_CAB.CrearError('Error borrando carga inicial del cliente:' ||
                         SQLERRM);
        P_CLOB := P_CAB.ObtenerCLOB_ERROR('CargaInicialBorrado');
      END IF;

  END PR_REVERSION_VINCULACION;

  PROCEDURE PR_ACTUALIZA_VINCULACION(P_NUMERO_FORMULARIO  IN NUMBER,
                                     P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                     P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                     P_CLOB               OUT CLOB) IS
  BEGIN
    /* MARCAR ARCHIVOS COMO NO PROCESADOS*/
    UPDATE PERSONAS_RELACIONADAS_VINCULA
       SET PERV_ESTADO = 'PROCESADO', PERV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE PERV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND PERV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND PERV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND PERV_ESTADO = 'POR_PROCESAR';

    UPDATE SEGUNDOS_TITULARES_VINCULA
       SET SETV_ESTADO = 'PROCESADO', SETV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE SETV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND SETV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND SETV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND SETV_ESTADO = 'POR_PROCESAR';

    UPDATE CUENTAS_BANCARIAS_VINCULACION
       SET CBVI_ESTADO = 'PROCESADO', CBVI_FECHA_PROCESAMIENTO = SYSDATE
     WHERE CBVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND CBVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND CBVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND CBVI_ESTADO = 'POR_PROCESAR';

    UPDATE CUENTAS_BANCARIAS_EXT_VINCULA
       SET CBEV_ESTADO = 'PROCESADO', CBEV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE CBEV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND CBEV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND CBEV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND CBEV_ESTADO = 'POR_PROCESAR';

    UPDATE INFORMACIONES_REVELA_VINCULA
       SET IFRV_ESTADO = 'PROCESADO', IFRV_FECHA_PROCESAMIENTO = SYSDATE
     WHERE IFRV_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND IFRV_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND IFRV_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND IFRV_ESTADO = 'POR_PROCESAR';

    UPDATE ACCIONISTAS_VINCULA
       SET ACVI_ESTADO = 'PROCESADO', ACVI_FECHA_PROCESAMIENTO = SYSDATE
     WHERE ACVI_NUMERO_FORMULARIO = P_NUMERO_FORMULARIO
       AND ACVI_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
       AND ACVI_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
       AND ACVI_ESTADO = 'POR_PROCESAR';

  EXCEPTION
    WHEN OTHERS THEN
      P_CAB.CrearError('Error creando informacion titular:' || SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('DatosClienteVincula');
  END PR_ACTUALIZA_VINCULACION;

  PROCEDURE PR_INGRESOS_CUENTA_CLIENTE(P_MCC_CONSECUTIVO NUMBER,
                                       P_MONTO           IN OUT NUMBER,
                                       P_TIPO_MOV        IN OUT VARCHAR2,
                                       P_NEGOCIO         IN OUT VARCHAR2,
                                       P_APLICA          IN OUT VARCHAR2) IS
    CURSOR C_MVTOS_CORREDORES IS
      SELECT MCC_RCA_CONSECUTIVO, MCC_SUC_CODIGO, MCC_NEG_CONSECUTIVO
        FROM MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_RCA_CONSECUTIVO IS NOT NULL
         AND MCC_CONSECUTIVO = P_MCC_CONSECUTIVO;

    --Se tienen en cuenta solo recibos de caja manuales
    CURSOR C_RECIBO_CAJA(P_RCA_CONSECUTIVO NUMBER,
                         P_RCA_SUC_CODIGO  NUMBER,
                         P_NEG_CONSECUTIVO NUMBER) IS
      SELECT RCA_SUC_CODIGO, RCA_NEG_CONSECUTIVO
        FROM RECIBOS_DE_CAJA
       WHERE RCA_CONSECUTIVO = P_RCA_CONSECUTIVO
         AND RCA_SUC_CODIGO = P_RCA_SUC_CODIGO
         AND RCA_NEG_CONSECUTIVO = P_NEG_CONSECUTIVO
         AND RCA_GENERADO_POR NOT IN ('USR_BARRAS')
         AND RCA_COT_MNEMONICO != 'AXCB';

    CURSOR C_CONSIGNACION(P_RCA_CONSECUTIVO NUMBER,
                          P_RCA_SUC_CODIGO  NUMBER,
                          P_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(CCJ_MONTO) CCJ_MONTO,
             NVL(CCJ_TIPO_CONSIGNACION, 'EFE') CCJ_TIPO_CONSIGNACION
        FROM CONSIGNACIONES_CAJA
       WHERE CCJ_RCA_CONSECUTIVO = P_RCA_CONSECUTIVO
         AND CCJ_RCA_SUC_CODIGO = P_RCA_SUC_CODIGO
         AND CCJ_RCA_NEG_CONSECUTIVO = P_NEG_CONSECUTIVO
       GROUP BY NVL(CCJ_TIPO_CONSIGNACION, 'EFE');

    CURSOR C_CHEQUE(P_RCA_CONSECUTIVO NUMBER,
                    P_RCA_SUC_CODIGO  NUMBER,
                    P_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(CCA_MONTO) CCA_MONTO
        FROM CHEQUES_CAJA
       WHERE CCA_RCA_CONSECUTIVO = P_RCA_CONSECUTIVO
         AND CCA_RCA_SUC_CODIGO = P_RCA_SUC_CODIGO
         AND CCA_RCA_NEG_CONSECUTIVO = P_NEG_CONSECUTIVO;

    CURSOR C_TRANSFERENCIA(P_RCA_CONSECUTIVO NUMBER,
                           P_RCA_SUC_CODIGO  NUMBER,
                           P_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(TRC_MONTO) TRC_MONTO
        FROM TRANSFERENCIAS_CAJA
       WHERE TRC_RCA_CONSECUTIVO = P_RCA_CONSECUTIVO
         AND TRC_RCA_SUC_CODIGO = P_RCA_SUC_CODIGO
         AND TRC_RCA_NEG_CONSECUTIVO = P_NEG_CONSECUTIVO;

    V_RCA_CONSECUTIVO     NUMBER(10);
    V_RCA_SUC_CODIGO      NUMBER(5);
    V_RCA_NEG_CONSECUTIVO NUMBER(5);
    V_VALOR_CHEQUES       NUMBER(22, 2);
    V_VALOR_TRANSFERENCIA NUMBER(22, 2);
    V_MONTO_CHEQUE        NUMBER(22, 2);
    V_MONTO_TRANSFERENCIA NUMBER(22, 2);
    R_CONSIGNACION        C_CONSIGNACION%ROWTYPE;

  BEGIN
    V_MONTO_CHEQUE        := 0;
    V_MONTO_TRANSFERENCIA := 0;
    P_APLICA              := 'N';

    OPEN C_MVTOS_CORREDORES;
    FETCH C_MVTOS_CORREDORES
      INTO V_RCA_CONSECUTIVO, V_RCA_SUC_CODIGO, V_RCA_NEG_CONSECUTIVO;
    CLOSE C_MVTOS_CORREDORES;

    OPEN C_RECIBO_CAJA(V_RCA_CONSECUTIVO,
                       V_RCA_SUC_CODIGO,
                       V_RCA_NEG_CONSECUTIVO);
    FETCH C_RECIBO_CAJA
      INTO V_RCA_SUC_CODIGO, V_RCA_NEG_CONSECUTIVO;
    IF C_RECIBO_CAJA%FOUND THEN
      P_APLICA := 'S';
    END IF;
    CLOSE C_RECIBO_CAJA;

    IF (P_APLICA = 'S') THEN
      OPEN C_CONSIGNACION(V_RCA_CONSECUTIVO,
                          V_RCA_SUC_CODIGO,
                          V_RCA_NEG_CONSECUTIVO);
      FETCH C_CONSIGNACION
        INTO R_CONSIGNACION;

      WHILE C_CONSIGNACION%FOUND LOOP
        IF (R_CONSIGNACION.CCJ_TIPO_CONSIGNACION = 'EFE') THEN
          V_MONTO_TRANSFERENCIA := NVL(V_MONTO_TRANSFERENCIA, 0) +
                                   NVL(R_CONSIGNACION.CCJ_MONTO, 0);
        ELSE
          V_MONTO_CHEQUE := NVL(V_MONTO_CHEQUE, 0) +
                            NVL(R_CONSIGNACION.CCJ_MONTO, 0);
        END IF;
        FETCH C_CONSIGNACION
          INTO R_CONSIGNACION;
      END LOOP;
      CLOSE C_CONSIGNACION;

      OPEN C_CHEQUE(V_RCA_CONSECUTIVO,
                    V_RCA_SUC_CODIGO,
                    V_RCA_NEG_CONSECUTIVO);
      FETCH C_CHEQUE
        INTO V_VALOR_CHEQUES;
      CLOSE C_CHEQUE;

      OPEN C_TRANSFERENCIA(V_RCA_CONSECUTIVO,
                           V_RCA_SUC_CODIGO,
                           V_RCA_NEG_CONSECUTIVO);
      FETCH C_TRANSFERENCIA
        INTO V_VALOR_TRANSFERENCIA;
      CLOSE C_TRANSFERENCIA;

      V_MONTO_TRANSFERENCIA := NVL(V_MONTO_TRANSFERENCIA, 0) +
                               NVL(V_VALOR_TRANSFERENCIA, 0);
      V_MONTO_CHEQUE        := NVL(V_MONTO_CHEQUE, 0) +
                               NVL(V_VALOR_CHEQUES, 0);

      --Asignacion de valores para retorno
      P_MONTO   := V_MONTO_TRANSFERENCIA + V_MONTO_CHEQUE;
      P_NEGOCIO := V_RCA_NEG_CONSECUTIVO;

      IF (V_MONTO_TRANSFERENCIA > 0 AND V_MONTO_CHEQUE > 0) THEN
        P_TIPO_MOV := 'MIX';
      ELSIF (V_MONTO_TRANSFERENCIA > 0 AND V_MONTO_CHEQUE = 0) THEN
        P_TIPO_MOV := 'TRB';
      ELSE
        P_TIPO_MOV := 'CHE';
      END IF;
    END IF;
  END PR_INGRESOS_CUENTA_CLIENTE;

  PROCEDURE PR_RETIROS_CUENTA_CLIENTE(P_MCC_CONSECUTIVO NUMBER,
                                      P_MONTO           IN OUT NUMBER,
                                      P_TIPO_MOV        IN OUT VARCHAR2,
                                      P_NEGOCIO         IN OUT VARCHAR2,
                                      P_ES_CLIENTE      IN OUT VARCHAR2,
                                      P_APLICA          IN OUT VARCHAR2,
                                      P_NOMBRE_DE       IN OUT VARCHAR2,
                                      P_ES_GARANTIA     IN OUT VARCHAR2) IS
    CURSOR C_MVTOS_CORREDORES IS
      SELECT MCC_CCC_CLI_PER_NUM_IDEN,
             MCC_CCC_CLI_PER_TID_CODIGO,
             MCC_FECHA,
             MCC_SUC_CODIGO,
             MCC_NEG_CONSECUTIVO,
             MCC_CEG_CONSECUTIVO,
             MCC_CGE_CONSECUTIVO,
             MCC_TBC_CONSECUTIVO,
             MCC_TCC_CONSECUTIVO
        FROM MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_CONSECUTIVO = P_MCC_CONSECUTIVO;

    CURSOR C_CHEQUES_GERENCIA(P_MCC_CGE_CONSECUTIVO NUMBER,
                              P_MCC_SUC_CODIGO      NUMBER,
                              P_MCC_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(CGE_MONTO) CGE_MONTO
        FROM CHEQUES_GERENCIA
       WHERE CGE_CONSECUTIVO = P_MCC_CGE_CONSECUTIVO
         AND CGE_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND CGE_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO;

    CURSOR C_TRANSFERENCIAS_BANCARIAS(P_MCC_TBC_CONSECUTIVO NUMBER,
                                      P_MCC_SUC_CODIGO      NUMBER,
                                      P_MCC_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(TBC_MONTO) TBC_MONTO
        FROM TRANSFERENCIAS_BANCARIAS
       WHERE TBC_CONSECUTIVO = P_MCC_TBC_CONSECUTIVO
         AND TBC_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND TBC_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO;

    CURSOR C_COMPROBANTES_DE_EGRESO(P_MCC_CEG_CONSECUTIVO NUMBER,
                                    P_MCC_SUC_CODIGO      NUMBER,
                                    P_MCC_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(CEG_MONTO) CEG_MONTO
        FROM COMPROBANTES_DE_EGRESO
       WHERE CEG_CONSECUTIVO = P_MCC_CEG_CONSECUTIVO
         AND CEG_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND CEG_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO;

    CURSOR C_TRANSF_CUENTAS_CLIENTE(P_MCC_TCC_CONSECUTIVO NUMBER,
                                    P_MCC_SUC_CODIGO      NUMBER,
                                    P_MCC_NEG_CONSECUTIVO NUMBER) IS
      SELECT SUM(TCC_MONTO) TCC_MONTO
        FROM TRANSFERENCIAS_CUENTAS_CLIENTE
       WHERE TCC_CONSECUTIVO = P_MCC_TCC_CONSECUTIVO
         AND TCC_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND TCC_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO;

    CURSOR C_ORDEN_PAGO(P_MCC_SUC_CODIGO      NUMBER,
                        P_MCC_NEG_CONSECUTIVO NUMBER,
                        P_CGE_CONSECUTIVO     NUMBER,
                        P_TBC_CONSECUTIVO     NUMBER,
                        P_CEG_CONSECUTIVO     NUMBER,
                        P_TCC_CONSECUTIVO     NUMBER) IS
      SELECT ODP_CONSECUTIVO,
             ODP_TPA_MNEMONICO,
             ODP_ES_CLIENTE,
             ODP_A_NOMBRE_DE,
             ODP_COT_MNEMONICO
        FROM ORDENES_DE_PAGO
       WHERE ODP_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND ODP_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO
         AND (ODP_CGE_CONSECUTIVO = P_CGE_CONSECUTIVO OR
             ODP_TBC_CONSECUTIVO = P_TBC_CONSECUTIVO OR
             ODP_CEG_CONSECUTIVO = P_CEG_CONSECUTIVO OR
             ODP_TCC_CONSECUTIVO = P_TCC_CONSECUTIVO)
         AND (ODP_FORMA_CARGUE_ACH IN ('M', 'P') OR
             ODP_FORMA_CARGUE_ACH IS NULL);

    CURSOR C_ORDEN_PAGO_REVERSADO(P_MCC_SUC_CODIGO      NUMBER,
                                  P_MCC_NEG_CONSECUTIVO NUMBER,
                                  P_CGE_CONSECUTIVO     NUMBER,
                                  P_TBC_CONSECUTIVO     NUMBER,
                                  P_CEG_CONSECUTIVO     NUMBER,
                                  P_TCC_CONSECUTIVO     NUMBER) IS
      SELECT ODP_CONSECUTIVO,
             ODP_TPA_MNEMONICO,
             ODP_ES_CLIENTE,
             ODP_A_NOMBRE_DE,
             ODP_COT_MNEMONICO
        FROM ORDENES_Y_PAGOS_ANULADOS
       INNER JOIN ORDENES_DE_PAGO
          ON OPA_NEG_CONSECUTIVO = ODP_NEG_CONSECUTIVO
         AND OPA_SUC_CODIGO = ODP_SUC_CODIGO
         AND OPA_ODP_CONSECUTIVO = ODP_CONSECUTIVO
       WHERE ODP_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND ODP_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO
         AND (OPA_CGE_CONSECUTIVO = P_CGE_CONSECUTIVO OR
             OPA_TBC_CONSECUTIVO = P_TBC_CONSECUTIVO OR
             OPA_CEG_CONSECUTIVO = P_CEG_CONSECUTIVO OR
             OPA_TCC_CONSECUTIVO = P_TCC_CONSECUTIVO)
         AND (ODP_FORMA_CARGUE_ACH = 'M' OR ODP_FORMA_CARGUE_ACH IS NULL);

    CURSOR C_MVTO_IVA(P_CLI_PER_NUM_IDEN    VARCHAR,
                      P_CLI_PER_TID_CODIGO  VARCHAR,
                      P_FECHA_MVTO          DATE,
                      P_MCC_SUC_CODIGO      NUMBER,
                      P_MCC_NEG_CONSECUTIVO NUMBER,
                      P_CGE_CONSECUTIVO     NUMBER,
                      P_TBC_CONSECUTIVO     NUMBER,
                      P_CEG_CONSECUTIVO     NUMBER,
                      P_TCC_CONSECUTIVO     NUMBER) IS
      SELECT MCC_MONTO
        FROM MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_SUC_CODIGO = P_MCC_SUC_CODIGO
         AND MCC_NEG_CONSECUTIVO = P_MCC_NEG_CONSECUTIVO
         AND (MCC_CGE_CONSECUTIVO = P_CGE_CONSECUTIVO OR
             MCC_TBC_CONSECUTIVO = P_TBC_CONSECUTIVO OR
             MCC_CEG_CONSECUTIVO = P_CEG_CONSECUTIVO OR
             MCC_TCC_CONSECUTIVO = P_TCC_CONSECUTIVO)
         AND MCC_CCC_CLI_PER_NUM_IDEN = P_CLI_PER_NUM_IDEN
         AND MCC_CCC_CLI_PER_TID_CODIGO = P_CLI_PER_TID_CODIGO
         AND MCC_FECHA >= TRUNC(P_FECHA_MVTO)
         AND MCC_FECHA < TRUNC(P_FECHA_MVTO) + 1
         AND MCC_TMC_MNEMONICO = 'IBA';

    CURSOR C_ES_GARANTIA(P_COT_MNEMONICO VARCHAR) IS
      SELECT 'S'
        FROM DUAL
       WHERE P_COT_MNEMONICO IN ('CGRCR', 'CGDE', 'GOPCE', 'CGDS');

    V_MCC_SUC_CODIGO      NUMBER(5);
    V_MCC_NEG_CONSECUTIVO NUMBER(5);
    V_MCC_CEG_CONSECUTIVO NUMBER(6);
    V_MCC_CGE_CONSECUTIVO NUMBER(6);
    V_MCC_TBC_CONSECUTIVO NUMBER(10);
    V_MCC_TCC_CONSECUTIVO NUMBER(6);
    V_ODP_CONSECUTIVO     NUMBER(8);
    V_ODP_TPA_MNEMONICO   VARCHAR2(3);
    V_ODP_A_NOMBRE_DE     VARCHAR2(80);
    V_ODP_COT_MNEMONICO   VARCHAR2(5);
    V_CGE_MONTO           NUMBER(22, 2);
    V_TBC_MONTO           NUMBER(22, 2);
    V_CEG_MONTO           NUMBER(22, 2);
    V_TCC_MONTO           NUMBER(22, 2);
    V_MONTO               NUMBER(22, 2);
    V_ODP_ES_CLIENTE      VARCHAR2(1);
    V_TIPO_MOV            VARCHAR2(3);
    V_MONTO_IVA           NUMBER(22, 2);
    V_FECHA_MVTO          DATE;
    V_CLI_PER_NUM_IDEN    VARCHAR2(15);
    V_CLI_PER_TID_CODIGO  VARCHAR2(3);
    V_REVERSADO           VARCHAR2(1);
    V_ES_GARANTIA         VARCHAR2(1);

  BEGIN

    OPEN C_MVTOS_CORREDORES;
    FETCH C_MVTOS_CORREDORES
      INTO V_CLI_PER_NUM_IDEN,
           V_CLI_PER_TID_CODIGO,
           V_FECHA_MVTO,
           V_MCC_SUC_CODIGO,
           V_MCC_NEG_CONSECUTIVO,
           V_MCC_CEG_CONSECUTIVO,
           V_MCC_CGE_CONSECUTIVO,
           V_MCC_TBC_CONSECUTIVO,
           V_MCC_TCC_CONSECUTIVO;
    CLOSE C_MVTOS_CORREDORES;

    OPEN C_CHEQUES_GERENCIA(V_MCC_CGE_CONSECUTIVO,
                            V_MCC_SUC_CODIGO,
                            V_MCC_NEG_CONSECUTIVO);
    FETCH C_CHEQUES_GERENCIA
      INTO V_CGE_MONTO;
    CLOSE C_CHEQUES_GERENCIA;

    OPEN C_TRANSFERENCIAS_BANCARIAS(V_MCC_TBC_CONSECUTIVO,
                                    V_MCC_SUC_CODIGO,
                                    V_MCC_NEG_CONSECUTIVO);
    FETCH C_TRANSFERENCIAS_BANCARIAS
      INTO V_TBC_MONTO;
    CLOSE C_TRANSFERENCIAS_BANCARIAS;

    OPEN C_COMPROBANTES_DE_EGRESO(V_MCC_CEG_CONSECUTIVO,
                                  V_MCC_SUC_CODIGO,
                                  V_MCC_NEG_CONSECUTIVO);
    FETCH C_COMPROBANTES_DE_EGRESO
      INTO V_CEG_MONTO;
    CLOSE C_COMPROBANTES_DE_EGRESO;

    OPEN C_TRANSF_CUENTAS_CLIENTE(V_MCC_TCC_CONSECUTIVO,
                                  V_MCC_SUC_CODIGO,
                                  V_MCC_NEG_CONSECUTIVO);
    FETCH C_TRANSF_CUENTAS_CLIENTE
      INTO V_TCC_MONTO;
    CLOSE C_TRANSF_CUENTAS_CLIENTE;

    OPEN C_ORDEN_PAGO(V_MCC_SUC_CODIGO,
                      V_MCC_NEG_CONSECUTIVO,
                      V_MCC_CGE_CONSECUTIVO,
                      V_MCC_TBC_CONSECUTIVO,
                      V_MCC_CEG_CONSECUTIVO,
                      V_MCC_TCC_CONSECUTIVO);
    FETCH C_ORDEN_PAGO
      INTO V_ODP_CONSECUTIVO,
           V_ODP_TPA_MNEMONICO,
           V_ODP_ES_CLIENTE,
           V_ODP_A_NOMBRE_DE,
           V_ODP_COT_MNEMONICO;
    IF C_ORDEN_PAGO%FOUND THEN
      P_APLICA := 'S';
    ELSE
      OPEN C_ORDEN_PAGO_REVERSADO(V_MCC_SUC_CODIGO,
                                  V_MCC_NEG_CONSECUTIVO,
                                  V_MCC_CGE_CONSECUTIVO,
                                  V_MCC_TBC_CONSECUTIVO,
                                  V_MCC_CEG_CONSECUTIVO,
                                  V_MCC_TCC_CONSECUTIVO);
      FETCH C_ORDEN_PAGO_REVERSADO
        INTO V_ODP_CONSECUTIVO,
             V_ODP_TPA_MNEMONICO,
             V_ODP_ES_CLIENTE,
             V_ODP_A_NOMBRE_DE,
             V_ODP_COT_MNEMONICO;
      IF C_ORDEN_PAGO_REVERSADO%FOUND THEN
        P_APLICA := 'S';
      ELSE
        P_APLICA := 'N';
      END IF;
      CLOSE C_ORDEN_PAGO_REVERSADO;
    END IF;
    CLOSE C_ORDEN_PAGO;

    OPEN C_MVTO_IVA(V_CLI_PER_NUM_IDEN,
                    V_CLI_PER_TID_CODIGO,
                    V_FECHA_MVTO,
                    V_MCC_SUC_CODIGO,
                    V_MCC_NEG_CONSECUTIVO,
                    V_MCC_CGE_CONSECUTIVO,
                    V_MCC_TBC_CONSECUTIVO,
                    V_MCC_CEG_CONSECUTIVO,
                    V_MCC_TCC_CONSECUTIVO);
    FETCH C_MVTO_IVA
      INTO V_MONTO_IVA;
    CLOSE C_MVTO_IVA;

    OPEN C_ES_GARANTIA(V_ODP_COT_MNEMONICO);
    FETCH C_ES_GARANTIA
      INTO V_ES_GARANTIA;
    CLOSE C_ES_GARANTIA;

    P_TIPO_MOV    := V_ODP_TPA_MNEMONICO;
    V_MONTO       := NVL(V_CGE_MONTO, 0) + NVL(V_TBC_MONTO, 0) +
                     NVL(V_CEG_MONTO, 0) + NVL(V_TCC_MONTO, 0) -
                     NVL(V_MONTO_IVA, 0);
    P_MONTO       := V_MONTO;
    P_NEGOCIO     := V_MCC_NEG_CONSECUTIVO;
    P_ES_CLIENTE  := V_ODP_ES_CLIENTE;
    P_NOMBRE_DE   := V_ODP_A_NOMBRE_DE;
    P_ES_GARANTIA := V_ES_GARANTIA;

  END PR_RETIROS_CUENTA_CLIENTE;

  /* PROCEDIMIENTOS PARA FACTURA ELECTRONICA */
  PROCEDURE PR_DIREC_CORRESPONDENCIA_FAC(P_NUM_IDEN        IN VARCHAR2,
                                         P_TID_CODIGO      IN VARCHAR2,
                                         P_DIRECCION       OUT VARCHAR2,
                                         P_TELEFONO        OUT VARCHAR2,
                                         P_CIUDAD          OUT VARCHAR2,
                                         P_NOMBRE_DEPTO    OUT VARCHAR2,
                                         P_CODIGO_PAIS     OUT VARCHAR,
                                         P_CODIGO_CIUDAD   OUT VARCHAR2,
                                         P_CODIGO_DEPTO    OUT VARCHAR2,
                                         P_NOMBRE_PAIS     OUT VARCHAR2,
                                         P_CODIGO_POSTAL_D OUT VARCHAR2) IS
    CURSOR C_CLIENTE IS
      SELECT PER_TIPO,
             CLI_DIRECCION_OFICINA,
             CLI_AGE_CODIGO_TRABAJA,
             AGE1.AGE_CIUDAD AGE_CIUDAD_TRABAJA,
             AGE1.AGE_DEPARTAMENTO AGE_DEPARTAMENTO_TRA,
             AGE1.AGE_CODIGO_DANE AGE_CODIGO_DANE_TRA,
             CASE NVL(LENGTH(TRIM(AGE1.AGE_CODIGO_DANE)), 0)
               WHEN 5 THEN
                SUBSTR(TRIM(TO_CHAR(AGE1.AGE_CODIGO_DANE)), 1, 2)
               WHEN 4 THEN
                SUBSTR(TRIM(TO_CHAR(AGE1.AGE_CODIGO_DANE)), 1, 1)
               ELSE
                '0'
             END AGE_DEPARTAMENTO_DECEVAL_TRA,
             PAI.PAI_CODIGO2 PAI_CODIGO_TRA,
             PAI.PAI_NOMBRE PAI_NOMBRE_TRA,
             CLI_TELEFONO_OFICINA,
             CLI_DIRECCION_RESIDENCIA,
             CLI_AGE_CODIGO_RESIDE,
             AGE2.AGE_CIUDAD AGE_CIUDAD_RESIDE,
             AGE2.AGE_DEPARTAMENTO AGE_DEPARTAMENTO_RES,
             AGE2.AGE_CODIGO_DANE AGE_CODIGO_DANE_RES

            ,
             CASE NVL(LENGTH(TRIM(AGE2.AGE_CODIGO_DANE)), 0)
               WHEN 5 THEN
                SUBSTR(TRIM(TO_CHAR(AGE2.AGE_CODIGO_DANE)), 1, 2)
               WHEN 4 THEN
                SUBSTR(TRIM(TO_CHAR(AGE2.AGE_CODIGO_DANE)), 1, 1)
               ELSE
                '0'
             END AGE_DEPARTAMENTO_DECEVAL_RES

            ,
             PAI2.PAI_CODIGO2        PAI_CODIGO_RES,
             PAI2.PAI_NOMBRE         PAI_NOMBRE_RES,
             CLI_TELEFONO_RESIDENCIA,
             CLI_TEC_MNEMONICO
        FROM PAISES            PAI2,
             PAISES            PAI,
             AREAS_GEOGRAFICAS AGE1,
             AREAS_GEOGRAFICAS AGE2,
             PERSONAS,
             CLIENTES
       WHERE PAI2.PAI_NOMBRE(+) = AGE2.AGE_PAIS
         AND PAI.PAI_NOMBRE(+) = AGE1.AGE_PAIS
         AND AGE1.AGE_CODIGO(+) = CLI_AGE_CODIGO_TRABAJA
         AND AGE2.AGE_CODIGO(+) = CLI_AGE_CODIGO_RESIDE
         AND CLI_PER_NUM_IDEN = PER_NUM_IDEN
         AND CLI_PER_TID_CODIGO = PER_TID_CODIGO
         AND PER_NUM_IDEN = P_NUM_IDEN
         AND PER_TID_CODIGO = P_TID_CODIGO;
    CLI1 C_CLIENTE%ROWTYPE;

    CURSOR SUCUSAL IS
      SELECT AGE1.AGE_CIUDAD               AGE_CIUDAD,
             AGE1.AGE_DEPARTAMENTO         AGE_DEPARTAMENTO,
             AGE1.AGE_CODIGO_DANE          AGE_CODIGO_DANE,
             AGE1.AGE_DEPARTAMENTO_DECEVAL AGE_DEPARTAMENTO_DECEVAL,
             PAI.PAI_CODIGO2               PAI_CODIGO,
             PAI.PAI_NOMBRE                PAI_NOMBRE,
             SUC.SUC_CODIGO_POSTAL,
             SUC.SUC_DIRECCION,
             SUC.SUC_TELEFONO
        FROM PAISES PAI, AREAS_GEOGRAFICAS AGE1, SUCURSALES SUC
       WHERE PAI.PAI_NOMBRE = AGE1.AGE_PAIS
         AND AGE1.AGE_CODIGO = SUC.SUC_AGE_CODIGO
         AND SUC.SUC_CODIGO = 1;
    SUC1 SUCUSAL%ROWTYPE;

  BEGIN
    OPEN SUCUSAL;
    FETCH SUCUSAL
      INTO SUC1;
    CLOSE SUCUSAL;

    OPEN C_CLIENTE;
    FETCH C_CLIENTE
      INTO CLI1;
    IF C_CLIENTE%FOUND THEN
      IF CLI1.CLI_TEC_MNEMONICO = 'OFI' THEN
        P_DIRECCION    := CLI1.CLI_DIRECCION_OFICINA;
        P_TELEFONO     := CLI1.CLI_TELEFONO_OFICINA;
        P_CIUDAD       := CLI1.AGE_CIUDAD_TRABAJA;
        P_NOMBRE_DEPTO := CLI1.AGE_DEPARTAMENTO_TRA;
        P_CODIGO_PAIS  := CLI1.PAI_CODIGO_TRA;
        IF CLI1.AGE_DEPARTAMENTO_DECEVAL_TRA IN ('5', '8') THEN
          P_CODIGO_CIUDAD := '0' || CLI1.AGE_CODIGO_DANE_TRA;
          P_CODIGO_DEPTO  := '0' || CLI1.AGE_DEPARTAMENTO_DECEVAL_TRA;
        ELSE
          P_CODIGO_CIUDAD := CLI1.AGE_CODIGO_DANE_TRA;
          P_CODIGO_DEPTO  := CLI1.AGE_DEPARTAMENTO_DECEVAL_TRA;
        END IF;
        P_NOMBRE_PAIS     := CLI1.PAI_NOMBRE_TRA;
        P_CODIGO_POSTAL_D := NULL;
      ELSIF CLI1.CLI_TEC_MNEMONICO = 'RES' THEN
        P_DIRECCION    := CLI1.CLI_DIRECCION_RESIDENCIA;
        P_TELEFONO     := CLI1.CLI_TELEFONO_RESIDENCIA;
        P_CIUDAD       := CLI1.AGE_CIUDAD_RESIDE;
        P_NOMBRE_DEPTO := CLI1.AGE_DEPARTAMENTO_RES;
        P_CODIGO_PAIS  := CLI1.PAI_CODIGO_RES;
        IF CLI1.AGE_DEPARTAMENTO_DECEVAL_RES IN ('5', '8') THEN
          P_CODIGO_CIUDAD := '0' || CLI1.AGE_CODIGO_DANE_RES;
          P_CODIGO_DEPTO  := '0' || CLI1.AGE_DEPARTAMENTO_DECEVAL_RES;
        ELSE
          P_CODIGO_CIUDAD := CLI1.AGE_CODIGO_DANE_RES;
          P_CODIGO_DEPTO  := CLI1.AGE_DEPARTAMENTO_DECEVAL_RES;
        END IF;
        P_NOMBRE_PAIS     := CLI1.PAI_NOMBRE_RES;
        P_CODIGO_POSTAL_D := NULL;
      ELSE
        IF CLI1.PER_TIPO = 'PJU' THEN
          P_DIRECCION    := CLI1.CLI_DIRECCION_OFICINA;
          P_TELEFONO     := CLI1.CLI_TELEFONO_OFICINA;
          P_CIUDAD       := CLI1.AGE_CIUDAD_TRABAJA;
          P_NOMBRE_DEPTO := CLI1.AGE_DEPARTAMENTO_TRA;
          P_CODIGO_PAIS  := CLI1.PAI_CODIGO_TRA;
          IF CLI1.AGE_DEPARTAMENTO_DECEVAL_TRA IN ('5', '8') THEN
            P_CODIGO_CIUDAD := '0' || CLI1.AGE_CODIGO_DANE_TRA;
            P_CODIGO_DEPTO  := '0' || CLI1.AGE_DEPARTAMENTO_DECEVAL_TRA;
          ELSE
            P_CODIGO_CIUDAD := CLI1.AGE_CODIGO_DANE_TRA;
            P_CODIGO_DEPTO  := CLI1.AGE_DEPARTAMENTO_DECEVAL_TRA;
          END IF;
          P_NOMBRE_PAIS     := CLI1.PAI_NOMBRE_TRA;
          P_CODIGO_POSTAL_D := NULL;
        ELSE
          P_DIRECCION     := CLI1.CLI_DIRECCION_RESIDENCIA;
          P_TELEFONO      := CLI1.CLI_TELEFONO_RESIDENCIA;
          P_CIUDAD        := CLI1.AGE_CIUDAD_RESIDE;
          P_NOMBRE_DEPTO  := CLI1.AGE_DEPARTAMENTO_RES;
          P_CODIGO_PAIS   := CLI1.PAI_CODIGO_RES;
          P_CODIGO_CIUDAD := CLI1.AGE_CODIGO_DANE_RES;
          IF CLI1.AGE_DEPARTAMENTO_DECEVAL_RES IN ('5', '8') THEN
            P_CODIGO_CIUDAD := '0' || CLI1.AGE_CODIGO_DANE_RES;
            P_CODIGO_DEPTO  := '0' || CLI1.AGE_DEPARTAMENTO_DECEVAL_RES;
          ELSE
            P_CODIGO_CIUDAD := CLI1.AGE_CODIGO_DANE_RES;
            P_CODIGO_DEPTO  := CLI1.AGE_DEPARTAMENTO_DECEVAL_RES;
          END IF;
          P_NOMBRE_PAIS     := CLI1.PAI_NOMBRE_RES;
          P_CODIGO_POSTAL_D := NULL;
        END IF;
      END IF;
    ELSE
      P_DIRECCION       := NULL;
      P_TELEFONO        := NULL;
      P_CIUDAD          := NULL;
      P_NOMBRE_DEPTO    := NULL;
      P_CODIGO_PAIS     := NULL;
      P_CODIGO_CIUDAD   := NULL;
      P_CODIGO_DEPTO    := NULL;
      P_NOMBRE_PAIS     := NULL;
      P_CODIGO_POSTAL_D := NULL;
    END IF;

    IF P_CODIGO_PAIS != 'CO' THEN
      -- ASIGNAR CODIGO POSTAL DE CORREDORES
      P_DIRECCION       := SUC1.SUC_DIRECCION;
      P_TELEFONO        := SUC1.SUC_TELEFONO;
      P_CIUDAD          := SUC1.AGE_CIUDAD;
      P_NOMBRE_DEPTO    := SUC1.AGE_DEPARTAMENTO;
      P_CODIGO_PAIS     := SUC1.PAI_CODIGO;
      P_CODIGO_CIUDAD   := SUC1.AGE_CODIGO_DANE;
      P_CODIGO_DEPTO    := SUC1.AGE_DEPARTAMENTO_DECEVAL;
      P_NOMBRE_PAIS     := SUC1.PAI_NOMBRE;
      P_CODIGO_POSTAL_D := SUC1.SUC_CODIGO_POSTAL;
    ELSE
      IF P_DIRECCION IS NULL OR P_CIUDAD IS NULL OR P_NOMBRE_DEPTO IS NULL THEN
        P_DIRECCION       := SUC1.SUC_DIRECCION;
        P_TELEFONO        := SUC1.SUC_TELEFONO;
        P_CIUDAD          := SUC1.AGE_CIUDAD;
        P_NOMBRE_DEPTO    := SUC1.AGE_DEPARTAMENTO;
        P_CODIGO_PAIS     := SUC1.PAI_CODIGO;
        P_CODIGO_CIUDAD   := SUC1.AGE_CODIGO_DANE;
        P_CODIGO_DEPTO    := SUC1.AGE_DEPARTAMENTO_DECEVAL;
        P_NOMBRE_PAIS     := SUC1.PAI_NOMBRE;
        P_CODIGO_POSTAL_D := SUC1.SUC_CODIGO_POSTAL;
      END IF;
    END IF;

  END PR_DIREC_CORRESPONDENCIA_FAC;

  PROCEDURE PR_INACTIVAR_CLIENTES(P_FECHA   IN DATE,
                                  P_USUARIO IN VARCHAR2,
                                  P_CNTINAC IN OUT NUMBER,
                                  P_ERROR   IN OUT CHAR,
                                  P_MENSAJE IN OUT VARCHAR2) IS
    CURSOR CLI IS
      SELECT C.CLI_PER_NUM_IDEN,
             C.CLI_PER_TID_CODIGO,
             C.CLI_ECL_MNEMONICO,
             C.CLI_TIPO_CLIENTE,
             C.CLI_FECHA_ULTIMA_ACTUALIZACION
        FROM ESTADOS_CLIENTE E, CLIENTES C
       WHERE E.ECL_MNEMONICO = C.CLI_ECL_MNEMONICO
         AND C.CLI_ECL_MNEMONICO NOT IN ('INA', 'BDJ')
         AND C.CLI_TIPO_CLIENTE IN ('C', 'A')
         AND NVL(C.CLI_VIGILADO_SFC, 'N') <> 'S'
         AND C.CLI_FECHA_ULTIMA_ACTUALIZACION < P_FECHA;
    R_CLI CLI%ROWTYPE;

    CURSOR CCC(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = NID
         AND CCC_CLI_PER_TID_CODIGO = TID
         AND (CCC_SALDO_CAPITAL != 0 OR CCC_SALDO_A_PLAZO != 0 OR
             CCC_SALDO_A_CONTADO != 0 OR CCC_SALDO_ADMON_VALORES != 0 OR
             CCC_SALDO_CC != 0 OR CCC_SALDO_BURSATIL != 0);
    R_CCC CCC%ROWTYPE;

    CURSOR CFO(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM FONDOS, CUENTAS_FONDOS
       WHERE FON_CODIGO = CFO_FON_CODIGO
         AND FON_TIPO != 'O'
         AND CFO_CCC_CLI_PER_NUM_IDEN = NID
         AND CFO_CCC_CLI_PER_TID_CODIGO = TID
         AND CFO_SALDO_INVER != 0;

    CURSOR CFO_CORRESPONSAL(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM FONDOS, CUENTAS_FONDOS
       WHERE FON_CODIGO = CFO_FON_CODIGO
         AND FON_TIPO = 'O'
         AND CFO_CCC_CLI_PER_NUM_IDEN = NID
         AND CFO_CCC_CLI_PER_TID_CODIGO = TID
         AND CFO_SALDO_UNIDADES != 0;

    CURSOR MOV(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM MOVIMIENTOS_CUENTA_CORREDORES
       WHERE MCC_CCC_CLI_PER_NUM_IDEN = NID
         AND MCC_CCC_CLI_PER_TID_CODIGO = TID
         AND MCC_FECHA >= TRUNC(ADD_MONTHS(SYSDATE, -12))
         AND MCC_FECHA < TRUNC(SYSDATE + 1);

    CURSOR MCF(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM MOVIMIENTOS_CUENTAS_FONDOS
       WHERE MCF_CFO_CCC_CLI_PER_NUM_IDEN = NID
         AND MCF_CFO_CCC_CLI_PER_TID_CODIGO = TID
         AND MCF_FECHA >= TRUNC(ADD_MONTHS(SYSDATE, -12))
         AND MCF_FECHA < TRUNC(SYSDATE + 1);

    -- TITULOS EN DCV
    CURSOR TIT(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM TITULOS TIT, ESTADOS_TITULO_COMERCIAL ETC
       WHERE ETC.ETC_DESACTIVA_TITULO = 'N'
         AND TIT.TLO_ETC_MNEMONICO = ETC.ETC_MNEMONICO
         AND TIT.TLO_CCC_CLI_PER_NUM_IDEN = NID
         AND TIT.TLO_CCC_CLI_PER_TID_CODIGO = TID
         AND NVL(TIT.TLO_PORTAFOLIO, 'N') = 'S';

    -- FISICOS
    CURSOR FISICOS(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM TITULOS TIT, ESTADOS_TITULO_COMERCIAL ETC
       WHERE ETC.ETC_DESACTIVA_TITULO = 'N'
         AND TIT.TLO_ETC_MNEMONICO = ETC.ETC_MNEMONICO
         AND TIT.TLO_CCC_CLI_PER_NUM_IDEN = NID
         AND TIT.TLO_CCC_CLI_PER_TID_CODIGO = TID
         AND TLO_LTI_MNEMONICO = 'FI';

    CURSOR CFC(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM CUENTAS_FUNGIBLE_CLIENTE
       WHERE CFC_CCC_CLI_PER_NUM_IDEN = NID
         AND CFC_CCC_CLI_PER_TID_CODIGO = TID
         AND (CFC_SALDO_CLIENTE != 0 OR CFC_SALDO_DCVAL_GAR_REPO != 0 OR
             CFC_SALDO_DCVAL_POR_CUMPLIR != 0 OR
             CFC_SALDO_DCVAL_GARANTIA_DER != 0 OR
             CFC_SALDO_DCVAL_DISPONIBLE != 0 OR
             CFC_SALDO_DCVAL_GARANTIA != 0 OR
             CFC_SALDO_DCVAL_EMBARGADO != 0 OR
             CFC_SALDO_DCVAL_TRANSITO_ING != 0 OR
             CFC_SALDO_DCVAL_TRANSITO_RET != 0);

    CURSOR OS(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM OS_CLIENTES
       WHERE OCL_CLI_PER_NUM_IDEN_RELACIONA = NID
         AND OCL_CLI_PER_TID_CODIGO_RELACIO = TID
         AND OCL_ESTADO = 'A';

    CURSOR CDV(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM CUENTAS_CLIENTES_DIVISAS
       WHERE CDV_CCC_CLI_PER_NUM_IDEN = NID
         AND CDV_CCC_CLI_PER_TID_CODIGO = TID
         AND (CDV_SALDO != 0 OR CDV_SALDO_RESTRINGIDO != 0);

    CURSOR C_SCM(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM SALDOS_CLIENTES_MONETIZAR
       WHERE SCM_CCC_CLI_PER_NUM_IDEN = NID
         AND SCM_CCC_CLI_PER_TID_CODIGO = TID
         AND SCM_SALDO_MONETIZAR != 0;

    CURSOR C_ORDENES_DIVISAS(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM ORDENES_DIVISAS
       WHERE ORD_CLI_PER_NUM_IDEN = NID
         AND ORD_CLI_PER_TID_CODIGO = TID
         AND ORD_EOF_CODIGO IN ('APL', 'APR', 'COL')
         AND ORD_FECHA_COLOCACION >= TRUNC(ADD_MONTHS(SYSDATE, -12))
         AND ORD_FECHA_COLOCACION < TRUNC(SYSDATE + 1);

    CURSOR C_CUENTAS_DERIVADOS(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM CUENTAS_CLIENTES_DERIVADOS
       WHERE CDD_CCC_CLI_PER_NUM_IDEN = NID
         AND CDD_CCC_CLI_PER_TID_CODIGO = TID
         AND CDD_SALDO != 0;

    CURSOR C_MOVIMIENTOS_CUENTAS_DERIV(NID VARCHAR2, TID VARCHAR2) IS
      SELECT 'X'
        FROM MOVIMIENTOS_CUENTAS_DERIVADOS
       WHERE MDD_CDD_CCC_CLI_PER_NUM_IDEN = NID
         AND MDD_CDD_CCC_CLI_PER_TID_CODIGO = TID
         AND MDD_FECHA >= TRUNC(ADD_MONTHS(SYSDATE, -12))
         AND MDD_FECHA < TRUNC(SYSDATE + 1);

    CURSOR ESTADO_CLIENTE IS
      SELECT NVL(COUNT(*), 0) CUENTA,
             ECL_DESCRIPCION ECL_DESCRIPCION,
             DECODE(CLI_TIPO_CLIENTE,
                    'C',
                    'CLIENTE',
                    'S',
                    'SEGUNDO TITULAR',
                    'A',
                    'AMBOS') CLI_TIPO_CLIENTE
        FROM ESTADOS_CLIENTE, CLIENTES
       WHERE ECL_MNEMONICO = CLI_ECL_MNEMONICO
         AND ECL_MNEMONICO NOT IN ('INA', 'BDJ')
         AND CLI_TIPO_CLIENTE IN ('C', 'A')
         AND CLI_FECHA_ULTIMA_ACTUALIZACION < P_FECHA
       GROUP BY ECL_DESCRIPCION, CLI_TIPO_CLIENTE
       ORDER BY ECL_DESCRIPCION, CLI_TIPO_CLIENTE;
    R_ESTADO_CLIENTE ESTADO_CLIENTE%ROWTYPE;

    CURSOR C_INACTIVOS_HOY(V_FECHA DATE, V_CIN_USUARIO VARCHAR2) IS
      SELECT C.CLI_PER_NUM_IDEN,
             C.CLI_PER_TID_CODIGO,
             P.PER_NOMBRE,
             E.ECL_DESCRIPCION,
             I.CIN_FECHA
        FROM CLIENTES_INACTIVOS I,
             CLIENTES           C,
             ESTADOS_CLIENTE    E,
             FILTRO_PERSONAS    P
       WHERE I.CIN_CLI_PER_NUM_IDEN = C.CLI_PER_NUM_IDEN
         AND I.CIN_CLI_PER_TID_CODIGO = C.CLI_PER_TID_CODIGO
         AND I.CIN_CLI_PER_NUM_IDEN = P.PER_NUM_IDEN
         AND I.CIN_CLI_PER_TID_CODIGO = P.PER_TID_CODIGO
         AND C.CLI_ECL_MNEMONICO = E.ECL_MNEMONICO
         AND TRUNC(I.CIN_FECHA) = TRUNC(V_FECHA)
         AND I.CIN_USUARIO = V_CIN_USUARIO
       ORDER BY C.CLI_PER_NUM_IDEN;
    R_INACTIVOS C_INACTIVOS_HOY%ROWTYPE;

    CURSOR C_EST_ANT_CLI(V_FECHA DATE, NID VARCHAR2, TID VARCHAR2) IS
      SELECT ECL_DESCRIPCION
        FROM CONTROL_ACTUALIZACIONES, ESTADOS_CLIENTE
       WHERE CAC_VALOR_ANTERIOR = ECL_MNEMONICO
         AND CAC_TABLA = 'CLIENTES'
         AND CAC_COLUMNA = 'CLI_ECL_MNEMONICO'
         AND CAC_CLI_PER_NUM_IDEN = NID
         AND CAC_CLI_PER_TID_CODIGO = TID
         AND TRUNC(CAC_FECHA_ACTUALIZACION) = TRUNC(V_FECHA);
    R_ESTADO_ANT C_EST_ANT_CLI%ROWTYPE;

    CURSOR C_RUTA IS
      SELECT DIRECTORY_NAME RUTA
        FROM DBA_DIRECTORIES
       WHERE DIRECTORY_NAME = C_RUTA_ATTCH;
    R_C_RUTA C_RUTA%ROWTYPE;

    CURSOR C_USERS IS
      SELECT P.PER_TID_CODIGO, P.PER_NUM_IDEN
        FROM PERSONAS P
       WHERE P.PER_NOMBRE_USUARIO = P_USUARIO;
    R_USERS C_USERS%ROWTYPE;

    CURSOR C_EMAIL IS
      SELECT C.CON_VALOR_CHAR
        FROM CONSTANTES C
       WHERE C.CON_MNEMONICO = 'PIC';
    R_EMAIL C_EMAIL%ROWTYPE;
    --VAGTUS053544
    CURSOR C_CLIENTE_FONDO(NID VARCHAR2) IS
      SELECT 'X'
        FROM FONDOS F
       WHERE F.FON_CODIGO LIKE NID || '%'
         and f.fon_estado = 'A';
    R_CLIENTE_FONDO C_CLIENTE_FONDO%ROWTYPE;

    INACTIVAR        VARCHAR2(1);
    CLIENTE_INACTIVO NUMBER(10);
    MOVIMIENTOS      NUMBER(10, 2);
    X                NUMBER(10, 2);
    CONTADOR         NUMBER(5) := 0;
    COND             VARCHAR2(1);
    REGISTRO         NUMBER(10) := 0;
    V_HOY            DATE;
    V_FECHA_VAL      DATE;

    V_CANT_TOTAL   NUMBER;
    V_SERVICIO     VARCHAR2(30);
    V_DIRECCION_DE VARCHAR2(256) := 'notificaciones@corredores.com';
    V_ASUNTO       VARCHAR2(256);
    V_CUERPO       CLOB;
    V_CLOB         CLOB := NULL;

    V_ARCHIVO UTL_FILE.FILE_TYPE;
    V_NMBRARC VARCHAR2(512);
    V_ADJUNTO CLOB;
    V_MAILLST VARCHAR2(4000);

  BEGIN
    CLIENTE_INACTIVO := 0;
    V_HOY            := SYSDATE;
    P_ERROR          := 'N';
    P_MENSAJE        := '';

    SELECT ADD_MONTHS(SYSDATE, -13) INTO V_FECHA_VAL FROM DUAL;

    IF P_FECHA > V_FECHA_VAL THEN
      P_ERROR   := 'S';
      P_MENSAJE := 'La fecha ingresada ' || TO_CHAR(P_FECHA, 'dd/mm/yyyy') ||
                   ' para la ejecucion del proceso es invalida,' ||
                   ' esta debe ser menor a la fecha actual menos 13 meses';
    ELSE
      V_CUERPO := 'Buenos días,' || '<br><br>' ||
                  'Le informamos que el proceso de inactivación de clientes ' ||
                  'ejecutado por el usuario ' || P_USUARIO || ' el día ' ||
                  to_char(V_HOY, 'dd/mm/yyyy hh24:mi:ss') ||
                  ' ha finalizado.' || '<br><br>' ||
                  '<h3>Clientes con fecha de última actualización inferior a: ' ||
                  P_FECHA || '</h3>' || '<br>' ||
                  '<h4>Estado Clientes antes del proceso: </h4>';

      V_CUERPO := V_CUERPO || '<table><tbody><tr> ' ||
                  '  <th width="350px" style="text-align: left;"><b>Estado Cliente</b></th> ' ||
                  '  <th width="100px" style="text-align: left;"><b>Tipo Cliente</b></th> ' ||
                  '  <th width="80px"  style="text-align: left;"><b>Cantidad</b></th> ' ||
                  '</tr> ';

      OPEN ESTADO_CLIENTE;
      FETCH ESTADO_CLIENTE
        INTO R_ESTADO_CLIENTE;
      V_CANT_TOTAL := 0;
      WHILE ESTADO_CLIENTE%FOUND LOOP
        V_CANT_TOTAL := V_CANT_TOTAL + R_ESTADO_CLIENTE.CUENTA;
        V_CUERPO     := V_CUERPO || '<tr>';
        V_CUERPO     := V_CUERPO || '<td width="350px">' ||
                        R_ESTADO_CLIENTE.ECL_DESCRIPCION || '</td>';
        V_CUERPO     := V_CUERPO || '<td width="100px">' ||
                        R_ESTADO_CLIENTE.CLI_TIPO_CLIENTE || '</td>';
        V_CUERPO     := V_CUERPO || '<td width="80px">' ||
                        R_ESTADO_CLIENTE.CUENTA || '</td>';
        V_CUERPO     := V_CUERPO || '</tr>';
        FETCH ESTADO_CLIENTE
          INTO R_ESTADO_CLIENTE;
      END LOOP;
      V_CUERPO := V_CUERPO || '<tr>';
      V_CUERPO := V_CUERPO || '<td width="350px"><p> </p></td>';
      V_CUERPO := V_CUERPO || '<td width="100px"><p> </p></td>';
      V_CUERPO := V_CUERPO || '<td width="80px"><p>' || V_CANT_TOTAL ||
                  '</p></td>';
      V_CUERPO := V_CUERPO || '</tr></tbody></table>';
      CLOSE ESTADO_CLIENTE;

      OPEN CLI;
      FETCH CLI
        INTO R_CLI;
      WHILE CLI%FOUND LOOP
        REGISTRO  := REGISTRO + 1;
        INACTIVAR := 'S';

        --dbms_output.put_line('Verificando Cliente '||R_CLI.CLI_PER_TID_CODIGO||'-'||R_CLI.CLI_PER_NUM_IDEN||'-'||'REGISTRO:'||TO_CHAR(REGISTRO));

        -- VERIFICACION DE SALDOS EN CORREDORES
        COND := NULL;
        OPEN CCC(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
        FETCH CCC
          INTO COND;
        IF CCC%FOUND THEN
          INACTIVAR := 'N';
        ELSE
          INACTIVAR := 'S';
        END IF;
        CLOSE CCC;

        -- VERIFICACION SALDOS EN FONDOS DIFRENTES A CORRESPONSALIA
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN CFO(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH CFO
            INTO COND;
          IF CFO%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE CFO;
        END IF;

        -- VERIFICAR SALDOS DE FONDOS DE CORRESPONSALIAS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN CFO_CORRESPONSAL(R_CLI.CLI_PER_NUM_IDEN,
                                R_CLI.CLI_PER_TID_CODIGO);
          FETCH CFO_CORRESPONSAL
            INTO COND;
          IF CFO_CORRESPONSAL%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE CFO_CORRESPONSAL;
        END IF;

        -- VERIFICACION DE MOVIMIENTO EN CORREDORES
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN MOV(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH MOV
            INTO COND;
          IF MOV%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE MOV;
        END IF;

        -- VERIFICACION DE MOVIMIENTOS DEL FONDO EN CORREDORES
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN MCF(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH MCF
            INTO COND;
          IF MCF%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE MCF;
        END IF;

        -- VERIFICACION DE TITULOS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN TIT(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH TIT
            INTO COND;
          IF TIT%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE TIT;
        END IF;

        -- VERIFICACION DE TITULOS FISICOS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN FISICOS(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH FISICOS
            INTO COND;
          IF FISICOS%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE FISICOS;
        END IF;

        -- VERIFICACION DE SALDOS EN DECEVAL
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN CFC(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH CFC
            INTO COND;
          IF CFC%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE CFC;
        END IF;

        -- VERIFICACION SEGUNDOS TITULARES Y AMBOS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN OS(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH OS
            INTO COND;
          IF OS%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE OS;
        END IF;

        -- VERIFICACION SALDOS DIVISAS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN CDV(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH CDV
            INTO COND;
          IF CDV%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE CDV;
        END IF;

        -- VERIFICACION SALDOS POR MONETIZAR
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN C_SCM(R_CLI.CLI_PER_NUM_IDEN, R_CLI.CLI_PER_TID_CODIGO);
          FETCH C_SCM
            INTO COND;
          IF C_SCM%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE C_SCM;
        END IF;

        -- VERIFICACION ORDENES DIVISAS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN C_ORDENES_DIVISAS(R_CLI.CLI_PER_NUM_IDEN,
                                 R_CLI.CLI_PER_TID_CODIGO);
          FETCH C_ORDENES_DIVISAS
            INTO COND;
          IF C_ORDENES_DIVISAS%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE C_ORDENES_DIVISAS;
        END IF;

        -- VERIFICAR CUENTAS DERIVADOS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN C_CUENTAS_DERIVADOS(R_CLI.CLI_PER_NUM_IDEN,
                                   R_CLI.CLI_PER_TID_CODIGO);
          FETCH C_CUENTAS_DERIVADOS
            INTO COND;
          IF C_CUENTAS_DERIVADOS%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE C_CUENTAS_DERIVADOS;
        END IF;

        -- VERIFICACION MOVIMIENTOS DERIVADOS
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN C_MOVIMIENTOS_CUENTAS_DERIV(R_CLI.CLI_PER_NUM_IDEN,
                                           R_CLI.CLI_PER_TID_CODIGO);
          FETCH C_MOVIMIENTOS_CUENTAS_DERIV
            INTO COND;
          IF C_MOVIMIENTOS_CUENTAS_DERIV%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE C_MOVIMIENTOS_CUENTAS_DERIV;
        END IF;

        -- VERIFICACION CLIENTE COMO FONDO
        IF INACTIVAR = 'S' THEN
          COND := NULL;
          OPEN C_CLIENTE_FONDO(R_CLI.CLI_PER_NUM_IDEN);
          FETCH C_CLIENTE_FONDO
            INTO R_CLIENTE_FONDO;
          IF C_CLIENTE_FONDO%FOUND THEN
            INACTIVAR := 'N';
          ELSE
            INACTIVAR := 'S';
          END IF;
          CLOSE C_CLIENTE_FONDO;
        END IF;

        IF INACTIVAR = 'S' THEN
          BEGIN
            INSERT INTO CLIENTES_INACTIVOS
              (CIN_FECHA,
               CIN_CLI_PER_NUM_IDEN,
               CIN_CLI_PER_TID_CODIGO,
               CIN_USUARIO)
            VALUES
              (V_HOY,
               R_CLI.CLI_PER_NUM_IDEN,
               R_CLI.CLI_PER_TID_CODIGO,
               P_USUARIO);
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := P_MENSAJE ||
                           'Error insertando table CLIENTES_INACTIVOS :' ||
                           SQLCODE;
          END;

          -- INACTIVACION CLIENTE
          BEGIN
            UPDATE CLIENTES
               SET CLI_ECL_MNEMONICO              = 'INA',
                   CLI_FECHA_ULTIMA_MODIFICACION  = SYSDATE,
                   CLI_USUARIO_ULTIMA_MODIFICA    = USER,
                   CLI_FECHA_INACTIVACION         = SYSDATE,
                   CLI_USUARIO_INACTIVACION       = USER,
                   CLI_ULTIMA_OPERACION_EJECUTADA = 'MO',
                   CLI_MOI_MNEMONICO              = 'PRA'
             WHERE CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update clientes :' || SQLERRM;
          END;

          -- INACTIVACION PERSONAS RELACIONADAS
          BEGIN
            UPDATE PERSONAS_RELACIONADAS
               SET RLC_ESTADO = 'I'
             WHERE RLC_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND RLC_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update personas relacionadas :' ||
                           SQLCODE;
          END;

          -- INACTIVACION SEGUNDOS TITULARES
          BEGIN
            UPDATE OS_CLIENTES
               SET OCL_ESTADO = 'I'
             WHERE OCL_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND OCL_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update segundos titulares :' || SQLCODE;
          END;

          -- INACTIVACION CUENTAS_CORREDORES
          BEGIN
            UPDATE CUENTAS_CLIENTE_CORREDORES
               SET CCC_CUENTA_ACTIVA = 'N'
             WHERE CCC_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CCC_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuenta corredores :' || SQLCODE;
          END;

          -- INACTIVACION CUENTAS FONDOS
          BEGIN
            UPDATE CUENTAS_FONDOS
               SET CFO_ESTADO = 'I'
             WHERE CFO_CCC_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CFO_CCC_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuenta fondos :' || SQLCODE;
          END;

          -- INACTIVACION CUENTAS BANCARIAS
          BEGIN
            UPDATE CUENTAS_BANCARIAS_CLIENTES
               SET CBC_ESTADO = 'I'
             WHERE CBC_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CBC_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuenta bancarias :' || SQLCODE;
          END;

          -- INACTIVACION CUENTAS_BANCARIAS EXTERIOR
          BEGIN
            UPDATE CUENTAS_BANCARIAS_CLIENTES_EXT
               SET CBX_ESTADO = 'I'
             WHERE CBX_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CBX_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuenta bancarias :' || SQLCODE;
          END;

          -- SORTIZ - VAGTUS014552-inactivacion masiva de titulares
          -- SE INACTIVA LA CUENTA DECEVAL DE LA QUE ES COMITENTE Y NO TIENE PORTAFOLIO
          BEGIN
            UPDATE CUENTAS_DECEVAL
               SET CUD_ESTADO = 'I'
             WHERE CUD_ESTADO = 'A'
               AND EXISTS
             (SELECT 'X'
                      FROM COMITENTES_DECEVAL
                     WHERE COD_CUD_CUENTA_DECEVAL = CUD_CUENTA_DECEVAL
                       AND COD_OCL_CLI_PER_NUM_IDEN = CUD_CLI_PER_NUM_IDEN
                       AND COD_OCL_CLI_PER_TID_CODIGO =
                           CUD_CLI_PER_TID_CODIGO
                       AND COD_CLI_PER_NUM_IDEN_RELACIONA =
                           R_CLI.CLI_PER_NUM_IDEN
                       AND COD_CLI_PER_TID_CODIGO_RELACIO =
                           R_CLI.CLI_PER_TID_CODIGO);
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuentas deceval- comitente :' ||
                           SQLCODE;
          END;

          -- SE INACTIVA LA CUENTA DECEVAL DE LA QUE ES DUEÑO
          BEGIN
            UPDATE CUENTAS_DECEVAL
               SET CUD_ESTADO = 'I'
             WHERE CUD_ESTADO = 'A'
               AND CUD_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CUD_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuentas deceval :' || SQLCODE;
          END;

          -- SE INACTIVA LA CUENTA DCV DE LA QUE ES COMITENTE - EN ESTA FASE NO SE VALIDA PORTAFOLIO
          BEGIN
            UPDATE CUENTAS_DCV
               SET CDC_ESTADO = 'I'
             WHERE CDC_ESTADO = 'A'
               AND EXISTS
             (SELECT 'X'
                      FROM COMITENTES_DCV
                     WHERE CDCV_CDC_CUENTA_DCV = CDC_CUENTA_DCV
                       AND CDCV_OCL_CLI_PER_NUM_IDEN = CDC_CLI_PER_NUM_IDEN
                       AND CDCV_OCL_CLI_PER_TID_CODIGO =
                           CDC_CLI_PER_TID_CODIGO
                       AND CDCV_CLI_PER_NUM_IDEN_RELACI =
                           R_CLI.CLI_PER_NUM_IDEN
                       AND CDCV_CLI_PER_TID_CODIGO_RELACI =
                           R_CLI.CLI_PER_TID_CODIGO);
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuentas DCV comitente :' ||
                           SQLCODE;
          END;

          -- INACTIVACION CUENTAS_DCV
          BEGIN
            UPDATE CUENTAS_DCV
               SET CDC_ESTADO = 'I'
             WHERE CDC_ESTADO = 'A'
               AND CDC_CLI_PER_NUM_IDEN = R_CLI.CLI_PER_NUM_IDEN
               AND CDC_CLI_PER_TID_CODIGO = R_CLI.CLI_PER_TID_CODIGO;
          EXCEPTION
            WHEN OTHERS THEN
              P_MENSAJE := 'Error update cuenta DCV :' || SQLCODE;
          END;
          ---- FIN SORTIZ

          CLIENTE_INACTIVO := CLIENTE_INACTIVO + 1;

          CONTADOR := CONTADOR + 1;
          IF CONTADOR > 100 THEN
            COMMIT;
            CONTADOR := 0;
          END IF;
        END IF;
        FETCH CLI
          INTO R_CLI;
      END LOOP;
      CLOSE CLI;
      COMMIT;

      P_CNTINAC := CLIENTE_INACTIVO;

      V_CUERPO := V_CUERPO || '</br>' ||
                  '<h4>Estado Clientes después del proceso: </h4>';

      V_CUERPO := V_CUERPO || '<table><tbody><tr> ' ||
                  '  <th width="350px" style="text-align: left;"><b>Estado Cliente</b></th> ' ||
                  '  <th width="100px" style="text-align: left;"><b>Tipo Cliente</b></th> ' ||
                  '  <th width="80px"  style="text-align: left;"><b>Cantidad</b></th> ' ||
                  '</tr> ';

      OPEN ESTADO_CLIENTE;
      FETCH ESTADO_CLIENTE
        INTO R_ESTADO_CLIENTE;
      V_CANT_TOTAL := 0;
      WHILE ESTADO_CLIENTE%FOUND LOOP
        V_CANT_TOTAL := V_CANT_TOTAL + R_ESTADO_CLIENTE.CUENTA;
        V_CUERPO     := V_CUERPO || '<tr>';
        V_CUERPO     := V_CUERPO || '<td width="350px">' ||
                        R_ESTADO_CLIENTE.ECL_DESCRIPCION || '</td>';
        V_CUERPO     := V_CUERPO || '<td width="100px">' ||
                        R_ESTADO_CLIENTE.CLI_TIPO_CLIENTE || '</td>';
        V_CUERPO     := V_CUERPO || '<td width="80px">' ||
                        R_ESTADO_CLIENTE.CUENTA || '</td>';
        V_CUERPO     := V_CUERPO || '</tr>';
        FETCH ESTADO_CLIENTE
          INTO R_ESTADO_CLIENTE;
      END LOOP;
      V_CUERPO := V_CUERPO || '<tr>';
      V_CUERPO := V_CUERPO || '<td width=350px"><p> </p></td>';
      V_CUERPO := V_CUERPO || '<td width=100px"><p> </p></td>';
      V_CUERPO := V_CUERPO || '<td width=80px"><p>' || V_CANT_TOTAL ||
                  '</p></td>';
      V_CUERPO := V_CUERPO || '</tr></tbody></table>';
      CLOSE ESTADO_CLIENTE;

      V_CUERPO := V_CUERPO || '</br>' ||
                  '<h3>Total de clientes Inactivados: <b>' || P_CNTINAC ||
                  '</b></h3>';

      IF P_CNTINAC > 0 THEN
        --Enviar correo proceso al administrador
        OPEN C_USERS;
        FETCH C_USERS
          INTO R_USERS;
        IF C_USERS%NOTFOUND THEN
          R_USERS.PER_TID_CODIGO := 'CC';
          R_USERS.PER_NUM_IDEN   := '0';
        END IF;
        CLOSE C_USERS;

        OPEN C_EMAIL;
        FETCH C_EMAIL
          INTO R_EMAIL;
        IF C_EMAIL%NOTFOUND THEN
          R_EMAIL.CON_VALOR_CHAR := 'osdsilva@corredores.com';
        ELSE
          V_MAILLST := R_EMAIL.CON_VALOR_CHAR;
        END IF;
        CLOSE C_EMAIL;

        OPEN C_RUTA;
        FETCH C_RUTA
          INTO R_C_RUTA;
        IF C_RUTA%NOTFOUND THEN
          R_C_RUTA.RUTA := 'NTFMAILATT';
        END IF;
        CLOSE C_RUTA;

        FOR POS IN (SELECT TRIM(REGEXP_SUBSTR(V_MAILLST, '[^,]+', 1, LEVEL)) MAIL
                      FROM DUAL
                    CONNECT BY LEVEL <= REGEXP_COUNT(V_MAILLST, ',') + 1) LOOP
          V_SERVICIO := 'CLIENTE INACTIVO';
          V_ASUNTO   := 'Proceso para Inactivar Clientes finalizado.';

          --crea el adjunto para cada destinatario
          V_NMBRARC := 'PROINC' ||
                       TO_CHAR(SYSTIMESTAMP, 'YYYYDDMMHH24MISSFF') ||
                       '.csv';
          V_ARCHIVO := UTL_FILE.FOPEN(R_C_RUTA.RUTA, V_NMBRARC, 'W');

          V_ADJUNTO := 'Numero ID;Tipo Id;Cliente;Estado Cliente;Estado Anterior;Fecha Modificacion';
          UTL_FILE.PUT_LINE(V_ARCHIVO,
                            CONVERT(V_ADJUNTO,
                                    SUBSTR(SYS_CONTEXT('userenv', 'language'),
                                           INSTR(SYS_CONTEXT('userenv',
                                                             'language'),
                                                 '.') + 1),
                                    'UTF8'));

          OPEN C_INACTIVOS_HOY(TRUNC(V_HOY), P_USUARIO);
          FETCH C_INACTIVOS_HOY
            INTO R_INACTIVOS;
          WHILE C_INACTIVOS_HOY%FOUND LOOP

            OPEN C_EST_ANT_CLI(TRUNC(V_HOY),
                               R_INACTIVOS.CLI_PER_NUM_IDEN,
                               R_INACTIVOS.CLI_PER_TID_CODIGO);
            FETCH C_EST_ANT_CLI
              INTO R_ESTADO_ANT;
            CLOSE C_EST_ANT_CLI;

            R_ESTADO_ANT.ECL_DESCRIPCION := NVL(R_ESTADO_ANT.ECL_DESCRIPCION,
                                                ' ');

            V_ADJUNTO := R_INACTIVOS.CLI_PER_NUM_IDEN || ';' ||
                         R_INACTIVOS.CLI_PER_TID_CODIGO || ';' ||
                         R_INACTIVOS.PER_NOMBRE || ';' ||
                         R_INACTIVOS.ECL_DESCRIPCION || ';' ||
                         R_ESTADO_ANT.ECL_DESCRIPCION || ';' ||
                         R_INACTIVOS.CIN_FECHA;
            UTL_FILE.PUT_LINE(V_ARCHIVO,
                              CONVERT(V_ADJUNTO,
                                      SUBSTR(SYS_CONTEXT('userenv',
                                                         'language'),
                                             INSTR(SYS_CONTEXT('userenv',
                                                               'language'),
                                                   '.') + 1),
                                      'UTF8'));

            FETCH C_INACTIVOS_HOY
              INTO R_INACTIVOS;
          END LOOP;
          CLOSE C_INACTIVOS_HOY;
          UTL_FILE.FCLOSE(V_ARCHIVO);

          P_NOTIFICACIONES_MAIL.PR_ENVIO_MAIL(P_CLI_PER_TID_CODIGO => R_USERS.PER_TID_CODIGO,
                                              P_CLI_PER_NUM_IDEN   => R_USERS.PER_NUM_IDEN,
                                              P_SERVICIO           => V_SERVICIO,
                                              P_DE                 => V_DIRECCION_DE,
                                              P_PARA               => POS.MAIL,
                                              P_ASUNTO             => V_ASUNTO,
                                              P_MENSAJE            => NULL,
                                              P_CLOB               => V_CLOB,
                                              P_MENSAJE_CLOB       => V_CUERPO,
                                              P_ADJUNTO            => V_NMBRARC);

        END LOOP;

        PR_NOTIFICAR_INACTIVA_CLI(TRUNC(V_HOY), P_USUARIO);
      END IF;

      IF P_ERROR = 'N' THEN
        P_MENSAJE := 'Se completo el proceso de inactivación de clientes';
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_ERROR   := 'S';
      P_MENSAJE := 'Error general en el procedimiento PR_INACTIVAR_CLIENTES: ' ||
                   SQLCODE;
  END PR_INACTIVAR_CLIENTES;

  PROCEDURE PR_NOTIFICAR_INACTIVA_CLI(P_FECHA DATE, P_CIN_USUARIO VARCHAR2) IS
    CURSOR C_INACTIVOS_HOY IS
      SELECT DISTINCT F.PER_MAIL_CORREDOR,
                      C.CLI_PER_NUM_IDEN,
                      C.CLI_PER_TID_CODIGO,
                      P.PER_NOMBRE,
                      E.ECL_DESCRIPCION,
                      I.CIN_FECHA
        FROM CLIENTES_INACTIVOS         I,
             CLIENTES                   C,
             ESTADOS_CLIENTE            E,
             FILTRO_PERSONAS            P,
             CUENTAS_CLIENTE_CORREDORES CC,
             FILTRO_COMERCIALES         F
       WHERE I.CIN_CLI_PER_NUM_IDEN = C.CLI_PER_NUM_IDEN
         AND I.CIN_CLI_PER_TID_CODIGO = C.CLI_PER_TID_CODIGO
         AND I.CIN_CLI_PER_NUM_IDEN = P.PER_NUM_IDEN
         AND I.CIN_CLI_PER_TID_CODIGO = P.PER_TID_CODIGO
         AND C.CLI_ECL_MNEMONICO = E.ECL_MNEMONICO
         AND TRUNC(I.CIN_FECHA) = TRUNC(P_FECHA)
         AND I.CIN_USUARIO = P_CIN_USUARIO
         AND CC.CCC_PER_NUM_IDEN = F.PER_NUM_IDEN
         AND CC.CCC_PER_TID_CODIGO = F.PER_TID_CODIGO
         AND CC.CCC_CLI_PER_NUM_IDEN = C.CLI_PER_NUM_IDEN
         AND CC.CCC_CLI_PER_TID_CODIGO = C.CLI_PER_TID_CODIGO
       ORDER BY F.PER_MAIL_CORREDOR, C.CLI_PER_NUM_IDEN;
    R_INACTIVOS C_INACTIVOS_HOY%ROWTYPE;

    CURSOR C_RUTA IS
      SELECT DIRECTORY_NAME RUTA
        FROM DBA_DIRECTORIES
       WHERE DIRECTORY_NAME = C_RUTA_ATTCH;
    R_C_RUTA C_RUTA%ROWTYPE;

    V_MAIL_ANTERIOR VARCHAR2(60) := NULL;
    V_SERVICIO      VARCHAR2(30 BYTE);
    V_DIRECCION_DE  VARCHAR2(50 BYTE) := 'notificaciones@corredores.com';
    V_ASUNTO        VARCHAR2(100 BYTE);
    V_CUERPO        VARCHAR2(200 BYTE);
    V_CLOB          CLOB := NULL;
    V_ADJUNTO       CLOB := NULL;
    V_ENCABEZADO    VARCHAR2(1000 BYTE);
    V_CIERRE        VARCHAR2(1000 BYTE);

    V_ARCHIVO UTL_FILE.FILE_TYPE;
    V_NMBRARC VARCHAR2(512);

    V_NEWFILE VARCHAR2(2);

  BEGIN
    V_SERVICIO := 'CLIENTE INACTIVO';
    V_ASUNTO   := 'Cliente Inactivado en Proceso Automático';
    V_CUERPO   := 'Buenos dias,' || '<br>' || '<br>' ||
                  'Le informamos que algunos clientes fueron inactivados en proceso automático. Por favor revisar archivo adjunto. ' ||
                  '<br>' || '<br>' || 'Cordial Saludo.' || '<br>';

    OPEN C_RUTA;
    FETCH C_RUTA
      INTO R_C_RUTA;
    CLOSE C_RUTA;

    V_NEWFILE    := 'N';
    V_ENCABEZADO := '<table><tbody><tr> ' ||
                    '  <th width="80px"  style="text-align: left;"><p>Tipo ID</b></p></th> ' ||
                    '  <th width="150px" style="text-align: left;"><p>ID Cliente</b></p></th> ' ||
                    '  <th width="500px" style="text-align: left;"><p>Nombre</b></p></th> ' ||
                    '</tr> ';

    V_CIERRE := '</tbody></table>';

    OPEN C_INACTIVOS_HOY;
    FETCH C_INACTIVOS_HOY
      INTO R_INACTIVOS;
    WHILE C_INACTIVOS_HOY%FOUND LOOP

      IF V_NEWFILE = 'N' THEN
        V_NMBRARC := 'PROINC_IC' ||
                     TO_CHAR(SYSTIMESTAMP, 'YYYYDDMMHH24MISSFF') || '.htm';
        V_ARCHIVO := UTL_FILE.FOPEN(R_C_RUTA.RUTA, V_NMBRARC, 'W');

        UTL_FILE.PUT_LINE(V_ARCHIVO,
                          CONVERT(V_ENCABEZADO,
                                  SUBSTR(SYS_CONTEXT('userenv', 'language'),
                                         INSTR(SYS_CONTEXT('userenv',
                                                           'language'),
                                               '.') + 1),
                                  'UTF8'));
        V_NEWFILE := 'S';
      END IF;

      IF NOT (V_MAIL_ANTERIOR IS NULL) AND
         (V_MAIL_ANTERIOR != R_INACTIVOS.PER_MAIL_CORREDOR) THEN
        UTL_FILE.PUT_LINE(V_ARCHIVO,
                          CONVERT(V_CIERRE,
                                  SUBSTR(SYS_CONTEXT('userenv', 'language'),
                                         INSTR(SYS_CONTEXT('userenv',
                                                           'language'),
                                               '.') + 1),
                                  'UTF8'));

        UTL_FILE.FCLOSE(V_ARCHIVO);
        V_NEWFILE := 'N';

        P_NOTIFICACIONES_MAIL.PR_ENVIO_MAIL(R_INACTIVOS.CLI_PER_TID_CODIGO, --TIPO ID CLIENTE
                                            R_INACTIVOS.CLI_PER_NUM_IDEN, --NUMERO ID CLIENTE
                                            V_SERVICIO, --SERVICIO
                                            V_DIRECCION_DE, --P_DE
                                            V_MAIL_ANTERIOR, --P_PARA
                                            V_ASUNTO, --P_ASUNTO
                                            V_CUERPO, --P_MENSAJE
                                            V_CLOB, --P_CLOB
                                            NULL, --P_CLOB
                                            V_NMBRARC --P_CLOB
                                            );

        V_ADJUNTO := NULL;
      END IF;

      IF V_NEWFILE = 'N' THEN
        V_NMBRARC := 'PROINC_IC' ||
                     TO_CHAR(SYSTIMESTAMP, 'YYYYDDMMHH24MISSFF') || '.htm';
        V_ARCHIVO := UTL_FILE.FOPEN(R_C_RUTA.RUTA, V_NMBRARC, 'W');

        UTL_FILE.PUT_LINE(V_ARCHIVO,
                          CONVERT(V_ENCABEZADO,
                                  SUBSTR(SYS_CONTEXT('userenv', 'language'),
                                         INSTR(SYS_CONTEXT('userenv',
                                                           'language'),
                                               '.') + 1),
                                  'UTF8'));
        V_NEWFILE := 'S';
      END IF;

      V_ADJUNTO := NULL;
      V_ADJUNTO := V_ADJUNTO || '<tr><td width="80px"><p>' ||
                   R_INACTIVOS.CLI_PER_TID_CODIGO || '</p></td>';
      V_ADJUNTO := V_ADJUNTO || '<td width="150px"><p>' ||
                   R_INACTIVOS.CLI_PER_NUM_IDEN || '</p></td>';
      V_ADJUNTO := V_ADJUNTO || '<td width="500px"><p>' ||
                   R_INACTIVOS.PER_NOMBRE || '</p></td></tr>';

      UTL_FILE.PUT_LINE(V_ARCHIVO,
                        CONVERT(V_ADJUNTO,
                                SUBSTR(SYS_CONTEXT('userenv', 'language'),
                                       INSTR(SYS_CONTEXT('userenv',
                                                         'language'),
                                             '.') + 1),
                                'UTF8'));

      V_MAIL_ANTERIOR := R_INACTIVOS.PER_MAIL_CORREDOR;

      FETCH C_INACTIVOS_HOY
        INTO R_INACTIVOS;
    END LOOP;

    IF NOT (V_MAIL_ANTERIOR IS NULL) THEN
      -- ULTIMO
      UTL_FILE.PUT_LINE(V_ARCHIVO,
                        CONVERT(V_CIERRE,
                                SUBSTR(SYS_CONTEXT('userenv', 'language'),
                                       INSTR(SYS_CONTEXT('userenv',
                                                         'language'),
                                             '.') + 1),
                                'UTF8'));

      UTL_FILE.FCLOSE(V_ARCHIVO);
      V_NEWFILE := 'N';

      P_NOTIFICACIONES_MAIL.PR_ENVIO_MAIL(R_INACTIVOS.CLI_PER_TID_CODIGO, --TIPO ID CLIENTE
                                          R_INACTIVOS.CLI_PER_NUM_IDEN, --NUMERO ID CLIENTE
                                          V_SERVICIO, --SERVICIO
                                          V_DIRECCION_DE, --P_DE
                                          V_MAIL_ANTERIOR, --P_PARA
                                          V_ASUNTO, --P_ASUNTO
                                          V_CUERPO, --P_MENSAJE
                                          V_CLOB, --P_CLOB
                                          NULL, --P_CLOB
                                          V_NMBRARC --P_CLOB
                                          );
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      UTL_FILE.FCLOSE(V_ARCHIVO);

  END PR_NOTIFICAR_INACTIVA_CLI;

  PROCEDURE PR_INSERTA_SAL_CLIENTES_FONDOS(P_FECHA     DATE,
                                           P_RESULTADO IN OUT VARCHAR2) IS

    P_FLG NUMBER;

  BEGIN

    P_FLG := 0;
    /*Eliminan registros en caso de reprocesar*/
    BEGIN
      DELETE HIST_SALDOS_CLIENTES_FONDOS
       WHERE HSCF_FECHA >= P_FECHA
         AND HSCF_FECHA < (P_FECHA + 1);
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        --RAISE_APPLICATION_ERROR(-20001,'Se presentó error al eliminar HIST_SALDOS_CLIENTES_FONDOS: '||SQLERRM);
        P_RESULTADO := 'Se presentó error al eliminar HIST_SALDOS_CLIENTES_FONDOS: ' ||
                       SQLERRM;
        P_FLG       := 1;
    END;

    IF P_FLG = 0 THEN

      INSERT INTO HIST_SALDOS_CLIENTES_FONDOS
        (HSCF_FECHA,
         HSCF_CLI_PER_NUM_IDEN,
         HSCF_CLI_PER_TID_CODIGO,
         HSCF_NUMERO_CUENTA,
         HSCF_NUMERO_CARTERA_COLECTIVA,
         HSCF_APORTE,
         HSCF_UNIDADES_DISPONIBLES,
         HSCF_UNIDADES_NO_DISPONIBLES,
         HSCF_VALOR_UNIDAD,
         HSCF_VALOR_RTEFTE_CAUSADO,
         HSCF_VALOR_BASE_MONETARIA,
         HSCF_BMO_MNEMONICO,
         HSCF_FON_CODIGO,
         HSCF_FON_RAZON_SOCIAL,
         HSCF_CLASE_CARTERA_COLECTIVA,
         HSCF_VALOR_PESOS,
         HSCF_VALOR_PESOS_RETIRO,
         HSCF_VALOR_PESOS_NETO,
         HSCF_VALOR_MERCADO, -- SORTIZ FICI FASE 2
         HSCF_VALOR_PRECIO_MERCADO -- SORTIZ FICI FASE 2
         )
        SELECT P_FECHA,
               MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
               MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
               MCF1.MCF_CFO_CCC_NUMERO_CUENTA,
               MCF1.MCF_CFO_CODIGO,
               MCF1.MCF_CFO_CODIGO,
               MCF1.MCF_SALDO_UNIDADES,
               0 HSCF_UNIDADES_NO_DISPONIBLES,
               (SELECT VFO_VALOR
                  FROM VALORIZACIONES_FONDO VFO1
                 WHERE VFO_FON_CODIGO = MCF1.MCF_CFO_FON_CODIGO
                   AND VFO_FECHA_VALORIZACION >= P_FECHA
                   AND VFO_FECHA_VALORIZACION < (P_FECHA + 1)) HSCF_VALOR_UNIDAD,
               (CASE
                 WHEN MCF_TMF_MNEMONICO = 'RTF' THEN
                  NVL(MCF_CAPITAL, 0)
               END) HSCF_VALOR_RTEFTE_CAUSADO,
               (SELECT NVL(CBM_VALOR, -1)
                  FROM COTIZACIONES_BASE_MONETARIAS
                 WHERE CBM_BMO_MNEMONICO = FON_BMO_MNEMONICO
                   AND CBM_FECHA >= TRUNC(P_FECHA)
                   AND CBM_FECHA < TRUNC(P_FECHA + 1)) HSCF_VALOR_BASE_MONETARIA,
               FON_BMO_MNEMONICO,
               MCF1.MCF_CFO_FON_CODIGO,
               FON_RAZON_SOCIAL,
               DECODE((SELECT PFO_PAR_CODIGO
                        FROM PARAMETROS_FONDOS
                       WHERE PFO_FON_CODIGO = FON_CODIGO
                         AND PFO_RANGO_MIN_CHAR = 'S'
                         AND PFO_PAR_CODIGO = 30),
                      30,
                      'ESCALONADO',
                      DECODE(FON_TIPO, 'A', 'ABIERTO', 'C', 'CERRADO')) HSCF_CLASE_CARTERA_COLECTIVA,
               MCF1.MCF_SALDO_INVER HSCF_VALOR_PESOS,
               P_WEB_PORTAFOLIO.MOV_PESOS(MCF_OFO_SUC_CODIGO,
                                          MCF_OFO_CONSECUTIVO,
                                          OFO_TTO_TOF_CODIGO,
                                          MCF_TMF_MNEMONICO,
                                          MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                                          MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                                          MCF_CFO_CCC_NUMERO_CUENTA,
                                          MCF_CFO_FON_CODIGO,
                                          MCF_CFO_CODIGO,
                                          MCF_FECHA,
                                          DECODE(MCF_TMF_MNEMONICO,
                                                 'R',
                                                 DECODE(OFO_TTO_TOF_CODIGO,
                                                        'ING',
                                                        MCF_CAPITAL,
                                                        'INC',
                                                        MCF_CAPITAL,
                                                        'RP',
                                                        MCF_CAPITAL +
                                                        MCF_RENDIMIENTOS_RF +
                                                        MCF_RENDIMIENTOS_RV -
                                                        MCF_RETEFUENTE_MOVIMIENTO,
                                                        'RT',
                                                        MCF_CAPITAL +
                                                        MCF_RENDIMIENTOS_RF +
                                                        MCF_RENDIMIENTOS_RV -
                                                        MCF_RETEFUENTE_MOVIMIENTO),
                                                 MCF_CAPITAL +
                                                 MCF_RENDIMIENTOS_RF +
                                                 MCF_RENDIMIENTOS_RV -
                                                 MCF_RETEFUENTE_MOVIMIENTO)) HSCF_VALOR_PESOS_RETIRO,
               MCF1.MCF_SALDO_INVER HSCF_VALOR_PESOS,
               0 HSCF_VALOR_MERCADO, -- SORTIZ FICI FASE 2
               0 HSCF_VALOR_PRECIO_MERCADO -- SORTIZ FICI FASE 2
          FROM TMP_MCF_DIA MCF1
         INNER JOIN ORDENES_FONDOS
            ON MCF1.MCF_OFO_CONSECUTIVO = OFO_CONSECUTIVO(+)
           AND MCF1.MCF_OFO_SUC_CODIGO = OFO_SUC_CODIGO(+)
         INNER JOIN CUENTAS_FONDOS
            ON MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN = CFO_CCC_CLI_PER_NUM_IDEN
           AND MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO =
               CFO_CCC_CLI_PER_TID_CODIGO
           AND MCF1.MCF_CFO_CCC_NUMERO_CUENTA = CFO_CCC_NUMERO_CUENTA
           AND MCF1.MCF_CFO_FON_CODIGO = CFO_FON_CODIGO
           AND MCF1.MCF_CFO_CODIGO = CFO_CODIGO
         INNER JOIN FONDOS
            ON CFO_FON_CODIGO = FON_CODIGO
         WHERE FON_TIPO = 'A'
           AND FON_TIPO_ADMINISTRACION != 'A'
           AND MCF1.MCF_CONSECUTIVO =
               (SELECT MAX(MCF_CONSECUTIVO)
                  FROM TMP_MCF_DIA MCF2
                 WHERE MCF2.MCF_CFO_CCC_CLI_PER_NUM_IDEN =
                       MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN
                   AND MCF2.MCF_CFO_CCC_CLI_PER_TID_CODIGO =
                       MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO
                   AND MCF2.MCF_CFO_CCC_NUMERO_CUENTA =
                       MCF1.MCF_CFO_CCC_NUMERO_CUENTA
                   AND MCF2.MCF_CFO_FON_CODIGO = MCF1.MCF_CFO_FON_CODIGO
                   AND MCF2.MCF_CFO_CODIGO = MCF1.MCF_CFO_CODIGO)
           AND MCF_FECHA >= P_FECHA
           AND MCF_FECHA < (P_FECHA + 1)
              --. sortiz fici exluir inmobiliario del query actual inicio- FICI FASE 2
           AND MCF_CFO_FON_CODIGO NOT IN
               (SELECT PF.PFO_FON_CODIGO
                  FROM PARAMETROS_FONDOS PF
                 WHERE PF.PFO_PAR_CODIGO = 101
                   AND PF.PFO_FON_CODIGO = MCF_CFO_FON_CODIGO)
        --. sortiz fici exluir inmobiliario del query actual fin- FICI FASE 2

        --SALDOS FONDOS ACTIVOS CON SALDO EN CERO
        UNION ALL

        SELECT P_FECHA,
               CFO_CCC_CLI_PER_NUM_IDEN,
               CFO_CCC_CLI_PER_TID_CODIGO,
               CFO_CCC_NUMERO_CUENTA,
               CFO_CODIGO,
               CFO_CODIGO,
               CFO_SALDO_UNIDADES,
               0 HSCF_UNIDADES_NO_DISPONIBLES,
               (SELECT VFO_VALOR
                  FROM VALORIZACIONES_FONDO VFO1
                 WHERE VFO_FON_CODIGO = CFO_FON_CODIGO
                   AND VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
                   AND VFO_FECHA_VALORIZACION < TRUNC(P_FECHA + 1)) HSCF_VALOR_UNIDAD,
               0 HSCF_VALOR_RTEFTE_CAUSADO,
               (SELECT NVL(CBM_VALOR, -1)
                  FROM COTIZACIONES_BASE_MONETARIAS
                 WHERE CBM_BMO_MNEMONICO = FON_BMO_MNEMONICO
                   AND CBM_FECHA >= TRUNC(P_FECHA)
                   AND CBM_FECHA < TRUNC(P_FECHA + 1)) HSCF_VALOR_BASE_MONETARIA,
               FON_BMO_MNEMONICO,
               CFO_FON_CODIGO,
               FON_RAZON_SOCIAL,
               DECODE((SELECT PFO_PAR_CODIGO
                        FROM PARAMETROS_FONDOS
                       WHERE PFO_FON_CODIGO = FON_CODIGO
                         AND PFO_RANGO_MIN_CHAR = 'S'
                         AND PFO_PAR_CODIGO = 30),
                      30,
                      'ESCALONADO',
                      DECODE(FON_TIPO, 'A', 'ABIERTO', 'C', 'CERRADO')) HSCF_CLASE_CARTERA_COLECTIVA,
               CFO_SALDO_INVER,
               0 HSCF_VALOR_PESOS_RETIRO,
               CFO_SALDO_INVER HSCF_VALOR_PESOS,
               0 HSCF_VALOR_MERCADO, -- SORTIZ FICI FASE 2
               0 HSCF_VALOR_PRECIO_MERCADO -- SORTIZ FICI FASE 2
          FROM CUENTAS_FONDOS
         INNER JOIN FONDOS
            ON CFO_FON_CODIGO = FON_CODIGO
         WHERE FON_TIPO = 'A'
           AND FON_TIPO_ADMINISTRACION != 'A'
           AND CFO_ESTADO = 'A'
           AND CFO_SALDO_CAPITAL = 0
           AND CFO_SALDO_UNIDADES = 0
           AND NOT EXISTS
         (SELECT 1
                  FROM TMP_MCF_DIA MCF2
                 WHERE MCF2.MCF_CFO_CCC_CLI_PER_NUM_IDEN =
                       CFO_CCC_CLI_PER_NUM_IDEN
                   AND MCF2.MCF_CFO_CCC_CLI_PER_TID_CODIGO =
                       CFO_CCC_CLI_PER_TID_CODIGO
                   AND MCF2.MCF_CFO_CCC_NUMERO_CUENTA =
                       CFO_CCC_NUMERO_CUENTA
                   AND MCF2.MCF_CFO_FON_CODIGO = CFO_FON_CODIGO
                   AND MCF2.MCF_CFO_CODIGO = CFO_CODIGO)
           AND CFO_FON_CODIGO NOT IN
               (SELECT PF.PFO_RANGO_MIN_CHAR
                  FROM PARAMETROS_FONDOS PF
                 WHERE PF.PFO_PAR_CODIGO = 71
                   AND PF.PFO_RANGO_MIN_CHAR = CFO_FON_CODIGO)
              --. sortiz fici exluir inmobiliario del query actual inicio - FICI FASE 2
           AND CFO_FON_CODIGO NOT IN
               (SELECT PF.PFO_FON_CODIGO
                  FROM PARAMETROS_FONDOS PF
                 WHERE PF.PFO_PAR_CODIGO = 101
                   AND PF.PFO_FON_CODIGO = CFO_FON_CODIGO)
        --. sortiz fici exluir inmobiliario del query actual fin - FICI FASE 2
        -- INICIO PARA FICI SORTIZ - FICI FASE 2
        UNION ALL
        SELECT P_FECHA,
               MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN,
               MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO,
               MCF1.MCF_CFO_CCC_NUMERO_CUENTA,
               MCF1.MCF_CFO_CODIGO,
               MCF1.MCF_CFO_CODIGO,
               MCF1.MCF_SALDO_UNIDADES,
               0 HSCF_UNIDADES_NO_DISPONIBLES,
               (SELECT VFO_VALOR
                  FROM VALORIZACIONES_FONDO VFO1
                 WHERE VFO_FON_CODIGO = MCF1.MCF_CFO_FON_CODIGO
                   AND VFO_FECHA_VALORIZACION >= P_FECHA
                   AND VFO_FECHA_VALORIZACION < (P_FECHA + 1)) HSCF_VALOR_UNIDAD,
               (CASE
                 WHEN MCF_TMF_MNEMONICO = 'RTF' THEN
                  NVL(MCF_CAPITAL, 0)
               END) HSCF_VALOR_RTEFTE_CAUSADO,
               (SELECT NVL(CBM_VALOR, -1)
                  FROM COTIZACIONES_BASE_MONETARIAS
                 WHERE CBM_BMO_MNEMONICO = FON_BMO_MNEMONICO
                   AND CBM_FECHA >= TRUNC(P_FECHA)
                   AND CBM_FECHA < TRUNC(P_FECHA + 1)) HSCF_VALOR_BASE_MONETARIA,
               FON_BMO_MNEMONICO,
               MCF1.MCF_CFO_FON_CODIGO,
               FON_RAZON_SOCIAL,
               DECODE((SELECT PFO_PAR_CODIGO
                        FROM PARAMETROS_FONDOS
                       WHERE PFO_FON_CODIGO = FON_CODIGO
                         AND PFO_RANGO_MIN_CHAR = 'S'
                         AND PFO_PAR_CODIGO = 30),
                      30,
                      'ESCALONADO',
                      DECODE(FON_TIPO, 'A', 'ABIERTO', 'C', 'CERRADO')) HSCF_CLASE_CARTERA_COLECTIVA,
               MCF1.MCF_SALDO_INVER HSCF_VALOR_PESOS,
               P_WEB_PORTAFOLIO.MOV_PESOS(MCF_OFO_SUC_CODIGO,
                                          MCF_OFO_CONSECUTIVO,
                                          OFO_TTO_TOF_CODIGO,
                                          MCF_TMF_MNEMONICO,
                                          MCF_CFO_CCC_CLI_PER_NUM_IDEN,
                                          MCF_CFO_CCC_CLI_PER_TID_CODIGO,
                                          MCF_CFO_CCC_NUMERO_CUENTA,
                                          MCF_CFO_FON_CODIGO,
                                          MCF_CFO_CODIGO,
                                          MCF_FECHA,
                                          DECODE(MCF_TMF_MNEMONICO,
                                                 'R',
                                                 DECODE(OFO_TTO_TOF_CODIGO,
                                                        'ING',
                                                        MCF_CAPITAL,
                                                        'INC',
                                                        MCF_CAPITAL,
                                                        'RP',
                                                        MCF_CAPITAL +
                                                        MCF_RENDIMIENTOS_RF +
                                                        MCF_RENDIMIENTOS_RV -
                                                        MCF_RETEFUENTE_MOVIMIENTO,
                                                        'RT',
                                                        MCF_CAPITAL +
                                                        MCF_RENDIMIENTOS_RF +
                                                        MCF_RENDIMIENTOS_RV -
                                                        MCF_RETEFUENTE_MOVIMIENTO),
                                                 MCF_CAPITAL +
                                                 MCF_RENDIMIENTOS_RF +
                                                 MCF_RENDIMIENTOS_RV -
                                                 MCF_RETEFUENTE_MOVIMIENTO)) HSCF_VALOR_PESOS_RETIRO,
               MCF1.MCF_SALDO_INVER HSCF_VALOR_PESOS,
               ((SELECT CBM_VALOR
                   FROM COTIZACIONES_BASE_MONETARIAS
                  WHERE CBM_BMO_MNEMONICO = 'RDC'
                    AND CBM_FECHA >= P_FECHA
                    AND CBM_FECHA < (P_FECHA + 1)) *
               MCF1.MCF_SALDO_UNIDADES) HSCF_VALOR_MERCADO,
               /*((SELECT VFO_VALOR
                FROM  VALORIZACIONES_FONDO VFO1
               WHERE VFO_FON_CODIGO = CFO_FON_CODIGO
                 AND VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
                 AND VFO_FECHA_VALORIZACION < TRUNC(P_FECHA + 1)) * MCF1.MCF_SALDO_UNIDADES)*/ -- SORTIZ FICI FASE 2
               (SELECT CBM_VALOR
                  FROM COTIZACIONES_BASE_MONETARIAS
                 WHERE CBM_BMO_MNEMONICO = 'RDC'
                   AND CBM_FECHA >= P_FECHA
                   AND CBM_FECHA < (P_FECHA + 1)) HSCF_VALOR_PRECIO_MERCADO -- SORTIZ FICI FASE 2
          FROM TMP_MCF_DIA MCF1
         INNER JOIN ORDENES_FONDOS
            ON MCF1.MCF_OFO_CONSECUTIVO = OFO_CONSECUTIVO(+)
           AND MCF1.MCF_OFO_SUC_CODIGO = OFO_SUC_CODIGO(+)
         INNER JOIN CUENTAS_FONDOS
            ON MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN = CFO_CCC_CLI_PER_NUM_IDEN
           AND MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO =
               CFO_CCC_CLI_PER_TID_CODIGO
           AND MCF1.MCF_CFO_CCC_NUMERO_CUENTA = CFO_CCC_NUMERO_CUENTA
           AND MCF1.MCF_CFO_FON_CODIGO = CFO_FON_CODIGO
           AND MCF1.MCF_CFO_CODIGO = CFO_CODIGO
         INNER JOIN FONDOS
            ON CFO_FON_CODIGO = FON_CODIGO
         WHERE FON_TIPO = 'A'
           AND FON_TIPO_ADMINISTRACION != 'A'
           AND MCF1.MCF_CONSECUTIVO =
               (SELECT MAX(MCF_CONSECUTIVO)
                  FROM TMP_MCF_DIA MCF2
                 WHERE MCF2.MCF_CFO_CCC_CLI_PER_NUM_IDEN =
                       MCF1.MCF_CFO_CCC_CLI_PER_NUM_IDEN
                   AND MCF2.MCF_CFO_CCC_CLI_PER_TID_CODIGO =
                       MCF1.MCF_CFO_CCC_CLI_PER_TID_CODIGO
                   AND MCF2.MCF_CFO_CCC_NUMERO_CUENTA =
                       MCF1.MCF_CFO_CCC_NUMERO_CUENTA
                   AND MCF2.MCF_CFO_FON_CODIGO = MCF1.MCF_CFO_FON_CODIGO
                   AND MCF2.MCF_CFO_CODIGO = MCF1.MCF_CFO_CODIGO)
           AND MCF_FECHA >= P_FECHA
           AND MCF_FECHA < (P_FECHA + 1)
           AND MCF_CFO_FON_CODIGO IN
               (SELECT PF.PFO_FON_CODIGO
                  FROM PARAMETROS_FONDOS PF
                 WHERE PF.PFO_PAR_CODIGO = 101
                   AND PF.PFO_FON_CODIGO = MCF_CFO_FON_CODIGO)

        --SALDOS FONDOS ACTIVOS CON SALDO EN CERO
        UNION ALL

        SELECT P_FECHA,
               CFO_CCC_CLI_PER_NUM_IDEN,
               CFO_CCC_CLI_PER_TID_CODIGO,
               CFO_CCC_NUMERO_CUENTA,
               CFO_CODIGO,
               CFO_CODIGO,
               CFO_SALDO_UNIDADES,
               0 HSCF_UNIDADES_NO_DISPONIBLES,
               (SELECT VFO_VALOR
                  FROM VALORIZACIONES_FONDO VFO1
                 WHERE VFO_FON_CODIGO = CFO_FON_CODIGO
                   AND VFO_FECHA_VALORIZACION >= P_FECHA
                   AND VFO_FECHA_VALORIZACION < (P_FECHA + 1)) HSCF_VALOR_UNIDAD,
               0 HSCF_VALOR_RTEFTE_CAUSADO,
               (SELECT NVL(CBM_VALOR, -1)
                  FROM COTIZACIONES_BASE_MONETARIAS
                 WHERE CBM_BMO_MNEMONICO = FON_BMO_MNEMONICO
                   AND CBM_FECHA >= TRUNC(P_FECHA)
                   AND CBM_FECHA < TRUNC(P_FECHA + 1)) HSCF_VALOR_BASE_MONETARIA,
               FON_BMO_MNEMONICO,
               CFO_FON_CODIGO,
               FON_RAZON_SOCIAL,
               DECODE((SELECT PFO_PAR_CODIGO
                        FROM PARAMETROS_FONDOS
                       WHERE PFO_FON_CODIGO = FON_CODIGO
                         AND PFO_RANGO_MIN_CHAR = 'S'
                         AND PFO_PAR_CODIGO = 30),
                      30,
                      'ESCALONADO',
                      DECODE(FON_TIPO, 'A', 'ABIERTO', 'C', 'CERRADO')) HSCF_CLASE_CARTERA_COLECTIVA,

               ((SELECT VFO_VALOR
                   FROM VALORIZACIONES_FONDO VFO1
                  WHERE VFO_FON_CODIGO = CFO_FON_CODIGO
                    AND VFO_FECHA_VALORIZACION >= TRUNC(P_FECHA)
                    AND VFO_FECHA_VALORIZACION < TRUNC(P_FECHA + 1)) *
               CFO_SALDO_UNIDADES) HSCF_VALOR_PESOS,

               0 HSCF_VALOR_PESOS_RETIRO,
               CFO_SALDO_INVER HSCF_VALOR_PESOS,
               ((SELECT CBM_VALOR
                   FROM COTIZACIONES_BASE_MONETARIAS
                  WHERE CBM_BMO_MNEMONICO = 'RDC'
                    AND CBM_FECHA >= P_FECHA
                    AND CBM_FECHA < (P_FECHA + 1)) * CFO_SALDO_UNIDADES) HSCF_VALOR_MERCADO, -- SORTIZ FICI FASE 2
               /* ((SELECT VFO_VALOR
                FROM VALORIZACIONES_FONDO VFO1
               WHERE VFO_FON_CODIGO = CFO_FON_CODIGO
                 AND VFO_FECHA_VALORIZACION >=  TRUNC(P_FECHA)
                 AND VFO_FECHA_VALORIZACION <  TRUNC(P_FECHA + 1)) * CFO_SALDO_UNIDADES) HSCF_VALOR_MERCADO,*/ -- SORTIZ FICI FASE 2
               (SELECT CBM_VALOR
                  FROM COTIZACIONES_BASE_MONETARIAS
                 WHERE CBM_BMO_MNEMONICO = 'RDC'
                   AND CBM_FECHA >= P_FECHA
                   AND CBM_FECHA < (P_FECHA + 1)) HSCF_VALOR_PRECIO_MERCADO -- SORTIZ FICI FASE 2
          FROM CUENTAS_FONDOS
         INNER JOIN FONDOS
            ON CFO_FON_CODIGO = FON_CODIGO
         WHERE FON_TIPO = 'A'
           AND FON_TIPO_ADMINISTRACION != 'A'
           AND CFO_ESTADO = 'A'
           AND CFO_SALDO_CAPITAL = 0
           AND CFO_SALDO_UNIDADES = 0
           AND NOT EXISTS
         (SELECT 1
                  FROM TMP_MCF_DIA MCF2
                 WHERE MCF2.MCF_CFO_CCC_CLI_PER_NUM_IDEN =
                       CFO_CCC_CLI_PER_NUM_IDEN
                   AND MCF2.MCF_CFO_CCC_CLI_PER_TID_CODIGO =
                       CFO_CCC_CLI_PER_TID_CODIGO
                   AND MCF2.MCF_CFO_CCC_NUMERO_CUENTA =
                       CFO_CCC_NUMERO_CUENTA
                   AND MCF2.MCF_CFO_FON_CODIGO = CFO_FON_CODIGO
                   AND MCF2.MCF_CFO_CODIGO = CFO_CODIGO)
           AND CFO_FON_CODIGO NOT IN
               (SELECT PF.PFO_RANGO_MIN_CHAR
                  FROM PARAMETROS_FONDOS PF
                 WHERE PF.PFO_PAR_CODIGO = 71
                   AND PF.PFO_RANGO_MIN_CHAR = CFO_FON_CODIGO)
           AND CFO_FON_CODIGO IN
               (SELECT PF.PFO_FON_CODIGO
                  FROM PARAMETROS_FONDOS PF
                 WHERE PF.PFO_PAR_CODIGO = 101
                   AND PF.PFO_FON_CODIGO = CFO_FON_CODIGO);
      -- fin PARA FICI SORTIZ - FICI FASE 2

      COMMIT;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      P_RESULTADO := 'Se presentó error al insertar HIST_SALDOS_CLIENTES_FONDOS: ' ||
                     SQLERRM;
      --RAISE_APPLICATION_ERROR(-20001,'Se presentó error al insertar en HIST_SALDOS_CLIENTES_FONDOS: '||SQLERRM);

  END PR_INSERTA_SAL_CLIENTES_FONDOS;

  PROCEDURE PR_INSERTA_SALDOS_CUENTAS(P_FECHA     DATE,
                                      P_RESULTADO IN OUT VARCHAR2) IS

    P_FLG NUMBER;

  BEGIN

    P_FLG := 0;
    /*Eliminan registros en caso de reprocesar*/
    BEGIN
      DELETE HIST_SALDOS_CUENTAS_CLIENTES
       WHERE HSAC_FECHA >= P_FECHA
         AND HSAC_FECHA < (P_FECHA + 1);
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        --RAISE_APPLICATION_ERROR(-20001,'Se presentó error al eliminar HIST_SALDOS_CUENTAS_CLIENTES: '||SQLERRM);
        P_RESULTADO := 'Se presentó error al eliminar HIST_SALDOS_CUENTAS_CLIENTES: ' ||
                       SQLERRM;
        P_FLG       := 1;
    END;
    IF P_FLG = 0 THEN

      INSERT INTO HIST_SALDOS_CUENTAS_CLIENTES
        (HSAC_CLI_PER_TID_CODIGO,
         HSAC_CLI_PER_NUM_IDEN,
         HSAC_FECHA,
         HSAC_NUMERO_CUENTA,
         HSAC_BMO_MNEMONICO,
         HSAC_SALDO_CTAS_CORREDORES,
         HSAC_SALDO_CTAS_FIC,
         HSAC_OP_BURSATIL,
         HSAC_SALDO_ADMIN_VALORES,
         HSAC_SALDO_DERIVADOS,
         HSAC_SALDO_MONETIZADO,
         HSAC_SALDO_OTRAS_MONEDAS,
         HSAC_SALDO_REMESAS,
         HSAC_SALDO_GARANTIAS,
         HSAC_NOMINAL_OTRAS_MONEDAS)

        SELECT CLI_PER_TID_CODIGO,
               CLI_PER_NUM_IDEN,
               P_FECHA P_FECHA,
               NUMERO_CUENTA,
               BMO_MNEMONICO,
               SUM(SALDO_CTAS_CORREDORES) SALDO_CTAS_CORREDORES,
               SUM(SALDO_CTAS_FIC) SALDO_CTAS_FIC,
               SUM(SALDO_OP_BURSATIL) SALDO_OP_BURSATIL,
               SUM(SALDO_ADMIN_VALORES) SALDO_ADMIN_VALORES,
               SUM(SALDO_DERIVADOS) SALDO_DERIVADOS,
               SUM(SALDO_MONETIZADO) SALDO_MONETIZADO,
               SUM(SALDO_OTRAS_MONEDAS) SALDO_OTRAS_MONEDAS,
               SUM(SALDO_REMESAS) SALDO_REMESAS,
               SUM(SALDO_GARANTIAS) SALDO_GARANTIAS,
               SUM(VALOR_NOMINAL) VALOR_NOMINAL
          FROM (SELECT CLI_PER_NUM_IDEN,
                       CLI_PER_TID_CODIGO,
                       NUMERO_CUENTA,
                       BMO_MNEMONICO,
                       SALDO_CTAS_CORREDORES,
                       SALDO_CTAS_FIC,
                       SALDO_OP_BURSATIL,
                       SALDO_ADMIN_VALORES,
                       SALDO_DERIVADOS,
                       SALDO_MONETIZADO,
                       SALDO_OTRAS_MONEDAS,
                       SALDO_REMESAS,
                       SALDO_GARANTIAS,
                       VALOR_NOMINAL
                  FROM (SELECT CLI_PER_NUM_IDEN,
                               CLI_PER_TID_CODIGO,
                               P_FECHA,
                               NUMERO_CUENTA,
                               BMO_MNEMONICO,
                               DESCRIPCION,
                               SUM(SALDO_PESOS) SALDO_PESOS,
                               SUM(NOMINAL) VALOR_NOMINAL
                          FROM (SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo Ctas Corredores' DESCRIPCION,
                                       SDI_SALDO_CAPITAL NOMINAL,
                                       SDI_SALDO_CAPITAL SALDO_PESOS,
                                       SDI_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       SDI_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       SDI_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM SALDOS_DIARIOS_CLIENTE
                                 WHERE SDI_FECHA_SALDO = P_FECHA
                                UNION ALL
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo Ctas FIC''s' DESCRIPCION,
                                       SDI_SALDO_CC NOMINAL,
                                       SDI_SALDO_CC SALDO_PESOS,
                                       SDI_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       SDI_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       SDI_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM SALDOS_DIARIOS_CLIENTE
                                 WHERE SDI_FECHA_SALDO = P_FECHA
                                UNION ALL
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo Op. Bursátil' DESCRIPCION,
                                       SDI_SALDO_BURSATIL NOMINAL,
                                       SDI_SALDO_BURSATIL SALDO_PESOS,
                                       SDI_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       SDI_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       SDI_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM SALDOS_DIARIOS_CLIENTE
                                 WHERE SDI_FECHA_SALDO = P_FECHA
                                UNION ALL
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo Admon Valores' DESCRIPCION,
                                       SDI_SALDO_ADMON_VALORES NOMINAL,
                                       SDI_SALDO_ADMON_VALORES SALDO_PESOS,
                                       SDI_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       SDI_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       SDI_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM SALDOS_DIARIOS_CLIENTE
                                 WHERE SDI_FECHA_SALDO = P_FECHA
                                UNION ALL
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo Derivados' DESCRIPCION,
                                       NVL(MDD_SALDO, CDD_SALDO) NOMINAL,
                                       NVL(MDD_SALDO, CDD_SALDO) SALDO_PESOS,
                                       CDD_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       CDD_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       CDD_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM CUENTAS_CLIENTES_DERIVADOS
                                 INNER JOIN MOVIMIENTOS_CUENTAS_DERIVADOS MCD
                                    ON CDD_CCC_CLI_PER_NUM_IDEN =
                                       MCD.MDD_CDD_CCC_CLI_PER_NUM_IDEN
                                   AND CDD_CCC_CLI_PER_TID_CODIGO =
                                       MCD.MDD_CDD_CCC_CLI_PER_TID_CODIGO
                                   AND CDD_CCC_NUMERO_CUENTA =
                                       MCD.MDD_CDD_CCC_NUMERO_CUENTA
									AND		cdd_cuenta_crcc = mcd.MDD_CDD_CUENTA_CRCC
                                 WHERE MDD_CONSECUTIVO =
                                       (SELECT MAX(MDD_CONSECUTIVO)
                                          FROM MOVIMIENTOS_CUENTAS_DERIVADOS
                                         WHERE MDD_FECHA < P_FECHA + 1
                                           AND MDD_CDD_CCC_CLI_PER_NUM_IDEN =
                                               CDD_CCC_CLI_PER_NUM_IDEN
                                           AND MDD_CDD_CCC_CLI_PER_TID_CODIGO =
                                               CDD_CCC_CLI_PER_TID_CODIGO
                                           AND MDD_CDD_CCC_NUMERO_CUENTA =
                                               CDD_CCC_NUMERO_CUENTA
										AND		MDD_CDD_CUENTA_CRCC = cdd_cuenta_crcc)
                                UNION ALL
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo Monetizado' DESCRIPCION,
                                       SCM_SALDO_MONETIZAR NOMINAL,
                                       SCM_SALDO_MONETIZAR SALDO_PESOS,
                                       SCM_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       SCM_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       SCM_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM SALDOS_CLIENTES_MONETIZAR
                                UNION ALL
                                SELECT CCOM_BMO_MNEMONICO BMO_MNEMONICO,
                                       'Saldo Otras Monedas' DESCRIPCION,
                                       CCOM_SALDO NOMINAL,
                                       CCOM_SALDO * CBM_VALOR *
                                       PMO_TASA_CONVERSION SALDO_PESOS,
                                       CCOM_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       CCOM_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       CCOM_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM CUENTAS_CLIENTES_OTRAS_MONEDAS,
                                       POSICIONES_MONEDAS,
                                       COTIZACIONES_BASE_MONETARIAS
                                 WHERE CCOM_BMO_MNEMONICO = PMO_BMO_MNEMONICO
                                   AND PMO_FECHA =
                                       (SELECT MAX(PMO_FECHA)
                                          FROM POSICIONES_MONEDAS
                                         WHERE PMO_BMO_MNEMONICO =
                                               PMO_BMO_MNEMONICO)
                                   AND CBM_BMO_MNEMONICO = 'DOLAR'
                                   AND CBM_FECHA =
                                       (SELECT MAX(CBM_FECHA)
                                          FROM COTIZACIONES_BASE_MONETARIAS
                                         WHERE CBM_BMO_MNEMONICO = 'DOLAR')
                                UNION ALL
                                SELECT CDV_BMO_MNEMONICO BMO_MNEMONICO,
                                       'Saldo Otras Monedas' DESCRIPCION,
                                       (NVL(CDV_SALDO_RESTRINGIDO, 0) +
                                       NVL(CDV_SALDO, 0)) NOMINAL,
                                       (NVL(CDV_SALDO_RESTRINGIDO, 0) +
                                       NVL(CDV_SALDO, 0)) * CBM_VALOR SALDO_PESOS,
                                       CDV_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       CDV_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       CDV_CCC_CLI_PER_TID_CODIGO CLI_PER_TID_CODIGO
                                  FROM CUENTAS_CLIENTES_DIVISAS,
                                       COTIZACIONES_BASE_MONETARIAS
                                 WHERE CDV_BMO_MNEMONICO = CBM_BMO_MNEMONICO
                                   AND CBM_FECHA =
                                       (SELECT MAX(CBM_FECHA)
                                          FROM COTIZACIONES_BASE_MONETARIAS
                                         WHERE CBM_BMO_MNEMONICO = 'DOLAR')
                                UNION ALL /*NO DISPONIBLE*/
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Saldo en Remesas' DESCRIPCION,
                                       RECL_CCA_MONTO NOMINAL,
                                       RECL_CCA_MONTO SALDO_PESOS,
                                       RECL_RCA_CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       RECL_RCA_CCC_CLI_PER_NUM_IDEN CLI_PER_NUM_IDEN,
                                       RECL_RCA_CCC_CLI_PER_TID_COD CLI_PER_TID_CODIGO
                                  FROM VW_REMESAS_POR_LEGALIZAR
                                UNION ALL
                                SELECT 'COP' BMO_MNEMONICO,
                                       'Garantias',
                                       VALOR_PESOS NOMINAL,
                                       VALOR_PESOS SALDO_PESOS,
                                       CCC_NUMERO_CUENTA NUMERO_CUENTA,
                                       CLI_PER_NUM_IDEN,
                                       CLI_PER_TID_CODIGO
                                  FROM PROD.VW_WEB_GARANTIAS) TMP
                         WHERE NOMINAL != 0
                         GROUP BY BMO_MNEMONICO,
                                  DESCRIPCION,
                                  NUMERO_CUENTA,
                                  CLI_PER_NUM_IDEN,
                                  CLI_PER_TID_CODIGO
                         ORDER BY CLI_PER_TID_CODIGO, CLI_PER_NUM_IDEN)
                PIVOT(SUM(SALDO_PESOS)
                   FOR DESCRIPCION IN('Saldo Ctas Corredores' AS
                                     SALDO_CTAS_CORREDORES,
                                     'Saldo Ctas FIC''s' AS SALDO_CTAS_FIC,
                                     'Saldo Op. Bursátil' AS
                                     SALDO_OP_BURSATIL,
                                     'Saldo Admon Valores' AS
                                     SALDO_ADMIN_VALORES,
                                     'Saldo Derivados' AS SALDO_DERIVADOS,
                                     'Saldo Monetizado' AS SALDO_MONETIZADO,
                                     'Saldo Otras Monedas'
                                     SALDO_OTRAS_MONEDAS,
                                     'Saldo en Remesas' SALDO_REMESAS,
                                     'Garantias' SALDO_GARANTIAS))) TMP1
         GROUP BY CLI_PER_NUM_IDEN,
                  CLI_PER_TID_CODIGO,
                  NUMERO_CUENTA,
                  BMO_MNEMONICO;
      COMMIT;

    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      --RAISE_APPLICATION_ERROR(-20001,'Se presentó error al insertar en HIST_SALDOS_CUENTAS_CLIENTES: '||SQLERRM);
      P_RESULTADO := 'Se presentó error al insertar HIST_SALDOS_CUENTAS_CLIENTES: ' ||
                     SQLERRM;
  END PR_INSERTA_SALDOS_CUENTAS;

  PROCEDURE PR_INSERTA_SAL_CLIENTES_DRVDOS(P_FECHA     DATE,
                                           P_RESULTADO IN OUT VARCHAR2) IS

    P_FLG NUMBER;

  BEGIN

    P_FLG := 0;
    /*Eliminan registros en caso de reprocesar*/
    BEGIN
      DELETE HIST_SALDOS_DERIVADOS
       WHERE HSD_FECHA >= P_FECHA
         AND HSD_FECHA < (P_FECHA + 1);
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        ROLLBACK;
        --RAISE_APPLICATION_ERROR(-20001,'Se presentó error al eliminar HIST_SALDOS_CLIENTES_FONDOS: '||SQLERRM);
        P_RESULTADO := 'Se presentó error al eliminar HIST_SALDOS_DERIVADOS: ' ||
                       SQLERRM;
        P_FLG       := 1;
    END;

    IF P_FLG = 0 THEN

      INSERT INTO HIST_SALDOS_DERIVADOS
        (HSD_ID,
         HSD_FECHA,
         HSD_LID_CCC_CLI_PER_NUM_IDEN,
         HSD_LID_CCC_CLI_PER_TID_CODIGO,
         HSD_LID_CCC_NUMERO_CUENTA,
         --
         HSD_LID_CCC_NOMBRE_CONTRATO, --Verificar
         HSD_LID_CANTIDAD_CONTRATOS,
         HSD_LID_PRECIO_REFERENCIA,
         HSD_LID_VALORPESOS,
         HSD_LID_PUNTA,
         --
         HSD_LID_ESPECIE_CONTRATO,
         HSD_SYT_DESCRIPCION,
         HSD_LID_RUEDA,
         HSD_SYT_VALOR_CONTRATO,
         HSD_FECHA_VENCIMIENTO,
         HSD_SYT_MNEMONICO)
      -----
        SELECT NVL(LID_CDR_CONSECUTIVO, 0),
               TRUNC(LID_FECHA_OPERACION),
               LID_CCC_CLI_PER_NUM_IDEN,
               LID_CCC_CLI_PER_TID_CODIGO,
               LID_CCC_NUMERO_CUENTA,
               --
               TRIM(SYT_DESCRIPCION) || ' con vencimiento en ' ||
               TRIM(TO_CHAR(LID_FECHA_CUMPLIMIENTO,
                            'MONTH',
                            'NLS_DATE_LANGUAGE=''SPANISH''')) || ' ' ||
               TO_CHAR(LID_FECHA_CUMPLIMIENTO, 'YYYY'),
               LID_CANTIDAD_CONTRATOS,
               LID_PRECIO_REFERENCIA,
               P_VALORA_DERIVADOS.FN_PRECIO_VALORACION(LID_PRECIO_REFERENCIA,
                                                       SYT_TSU_MNEMONICO) *
               SYT_VALOR_CONTRATO * LID_CANTIDAD_CONTRATOS *
               DECODE(LID_PUNTA, 'C', -1, 'V', 1) LID_VALOR_PESOS,
               LID_PUNTA,
               --
               LID_ESPECIE_CONTRATO,
               SYT_DESCRIPCION,
               LID_RUEDA,
               SYT_VALOR_CONTRATO,
               --30 Ago 2019
               LID_FECHA_CUMPLIMIENTO,
               SYT_MNEMONICO
          FROM LIQUIDACIONES_DERIVADOS LD1
         INNER JOIN ESPECIES_CONTRATOS
            ON LID_ESPECIE_CONTRATO = ESC_MNEMONICO
         INNER JOIN SUBYACENTES
            ON ESC_SYT_MNEMONICO = SYT_MNEMONICO
         WHERE TRUNC(LID_FECHA_OPERACION) = TRUNC(P_Fecha)
              --(SELECT MAX(LID_FECHA_OPERACION)
              --  FROM LIQUIDACIONES_DERIVADOS
              --  WHERE LID_FECHA_OPERACION >= TO_DATE(TO_CHAR(SYSDATE,'DD-MM-YYYY'),'DD-MM-YYYY')- 10
              --    AND LID_FECHA_OPERACION <= TO_DATE(TO_CHAR(SYSDATE - 1,'DD-MM-YYYY'),'DD-MM-YYYY'))
           AND LID_RUEDA IS NOT NULL;
      -----
      COMMIT;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      P_RESULTADO := 'Se presentó error al insertar HIST_SALDOS_DERIVADOS: ' ||
                     SQLERRM;
      --RAISE_APPLICATION_ERROR(-20001,'Se presentó error al insertar en HIST_SALDOS_CLIENTES_FONDOS: '||SQLERRM);

  END PR_INSERTA_SAL_CLIENTES_DRVDOS;

  PROCEDURE P_LISTAR_CLIENTES_NUEVOS(io_cursor IN OUT O_CURSOR) AS
  BEGIN

    OPEN io_cursor FOR
      SELECT c.CLI_PER_TID_CODIGO,
             c.CLI_PER_NUM_IDEN,
             PER_NOMBRE,
             P_CORREOS_COEASY.P_CORREO(c.CLI_PER_TID_CODIGO,
                                       c.CLI_PER_NUM_IDEN,
                                       'P') CLI_DIRECCION_EMAIL
        FROM CLIENTES c, FILTRO_CLIENTES fc, BIENVENIDA_CLIENTES bc
       WHERE c.CLI_PER_NUM_IDEN = fc.CLI_PER_NUM_IDEN
         AND c.CLI_PER_TID_CODIGO = fc.CLI_PER_TID_CODIGO
         AND fc.CLI_PER_NUM_IDEN = bc.BIE_CLI_PER_NUM_IDEN
         AND fc.CLI_PER_TID_CODIGO = bc.BIE_CLI_PER_TID_CODIGO
         AND bc.BIE_BANDERA = '0';

    UPDATE BIENVENIDA_CLIENTES
       SET BIE_BANDERA = '1', BIE_FEC_CAMBIO_BANDERA = sysdate
     WHERE BIE_BANDERA = '0';
    commit;

  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20211,
                              'Error P_LISTAR_CLIENTES_NUEVOS:' || sqlerrm);
  END P_LISTAR_CLIENTES_NUEVOS;

  PROCEDURE PR_TRUNC_TABLE(P_TABLE VARCHAR2) AS
    P_FLG NUMBER;
  BEGIN
    SELECT INSTR(P_TABLE, 'TMP') into P_FLG FROM dual;
    IF P_FLG = 1 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || P_TABLE;
    END IF;
    SELECT INSTR(P_TABLE, 'tmp') into P_FLG FROM dual;
    IF P_FLG = 1 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || P_TABLE;
    END IF;
  END PR_TRUNC_TABLE;
  /*********************************************************************************************************
        AUTOR               : Cristhian Javier Fonseca Jimenez
        FECHA               : 2022-10-04
        DESCRIPCIÓN         : Obtener la cantidad de transacciones de coeasy
        PROCESO             : Reporte de vigia para el contador de transacciones
  **********************************************************************************************************/
  PROCEDURE PR_OBTENER_REPORTE_VIGIA(p_fecha          IN VARCHAR2,
                                     p_cRerporteVigia OUT SYS_REFCURSOR) IS
    V_FECHA date;
  BEGIN
    V_FECHA := to_date(p_fecha, 'yyyy-MM-dd');
    OPEN p_cRerporteVigia FOR
      WITH Vigia_trans AS
       (select TIPTRAN_CODIGO, count(1) as cantidad
          from prod.VW_VIGIA_TRANSACCIONES
         where fecha >= TRUNC(V_FECHA)
           and fecha < TRUNC(V_FECHA + 1)
         group by TIPTRAN_CODIGO
         order by TIPTRAN_CODIGO),
      Vigia_drv AS
       (select 'DRV' as TIPTRAN_CODIGO, count(1) as cantidad
          from VW_VIGIA_TRANSACCIONES_DRV
         where fecha >= TRUNC(V_FECHA)
           and fecha < TRUNC(V_FECHA + 1))
      select *
        from Vigia_trans
      union
      select * from Vigia_drv;
  END PR_OBTENER_REPORTE_VIGIA;

  PROCEDURE PR_VINGO(P_RADICADO          VARCHAR2,
                     P_TIPO              VARCHAR2,
                     P_TIPO_PERSONA      VARCHAR2,
                     P_CONTRATO_DECEVAL  VARCHAR2,
                     P_CONTRATO_COMISION VARCHAR2
                     -----------------------------------------
                     --, P_PN_MAYOR
                    ,
                     P_NOMBRES_MAYOR                VARCHAR2,
                     P_PRIMER_APELLIDO_MAYOR        VARCHAR2,
                     P_SEGUNDO_APELLIDO_MAYOR       VARCHAR2,
                     P_TIPO_DE_IDENTIFICACION_MAYOR VARCHAR2,
                     P_SIGLA_MAYOR                  VARCHAR2,
                     P_NUMERO_MAYOR                 VARCHAR2,
                     P_CODIGO_CIIU_MAYOR            VARCHAR2,
                     P_CODIGO_SUB_ACTIVIDAD_MAYOR   VARCHAR2,
                     P_CODIGO_CIIU_SECUNDARIO_MAYOR VARCHAR2,
                     P_CODIGO_SUB_ACTIV_SECUN_MAYOR VARCHAR2,
                     P_DECLARA_RENTA_MAYOR          VARCHAR2,
                     P_DEPENDE_USTD_DE_TERCER_MAYOR VARCHAR2,
                     P_ES_IMPACTADO_POR_FATCA_MAYOR VARCHAR2,
                     P_ES_IMPACTADO_POR_PEP_MAYOR   VARCHAR2,
                     P_ES_IMPACTADO_POR_CRS_MAYOR   VARCHAR2,
                     P_INCLUIR_CO_TITULAR_MAYOR     VARCHAR2,
                     P_INFO_CO_TITUL_ACTUALIZ_MAYOR VARCHAR2,
                     P_ES_CLIENTE_DE_LA_FIRMA_MAYOR VARCHAR2,
                     P_CANAL_VINCULACION_MAYOR      VARCHAR2,
                     P_ASESOR_QUE_SOLICITA          VARCHAR2,
                     P_FECHA_DILIGENCIAMIENTO_MAYOR VARCHAR2,
                     P_NOMBRES_2_MAYOR              VARCHAR2,
                     P_PRIMER_APELLIDO_2_MAYOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_2_MAYOR     VARCHAR2,
                     P_TIPO_SEXO_MAYOR              VARCHAR2,
                     P_NACIONALIDAD_MAYOR           VARCHAR2,
                     P_PROFESION_MAYOR              VARCHAR2,
                     P_TIPO_DE_IDENTIFICACI_2_MAYOR VARCHAR2,
                     P_SIGLA_2_MAYOR                VARCHAR2,
                     P_NUMERO_2_MAYOR               VARCHAR2,
                     P_NUMERO_IDEN_HOMOLOGO_MAYOR   VARCHAR2,
                     P_FECHA_EXPEDICION_MAYOR       VARCHAR2,
                     P_LUGAR_EXPEDICION_MAYOR       VARCHAR2,
                     P_FECHA_VENC_DOCUMENTO_MAYOR   VARCHAR2,
                     P_LUGAR_NACIMIENTO_MAYOR       VARCHAR2,
                     P_FECHA_NACIMIENTO_MAYOR       VARCHAR2,
                     P_CELULAR_MAYOR                VARCHAR2,
                     P_DIRECCION_RESIDENCIA_MAYOR   VARCHAR2,
                     P_LUGAR_RESIDENCIA_MAYOR       VARCHAR2,
                     P_CORREO_ELECTRONICO_MAYOR     VARCHAR2,
                     P_MODALID_INF_ANUAL_COST_MAYOR VARCHAR2,
                     P_PER_NAT_CON_NEGOCIO_MAYOR    VARCHAR2,
                     P_TIPO_ACTIVID_LABORAL_2_MAYOR VARCHAR2,
                     P_NOMBRE_EMPRESA_MAYOR         VARCHAR2,
                     P_CARGO_MAYOR                  VARCHAR2,
                     P_TELEFONO_MAYOR               VARCHAR2,
                     P_DIRECCION_OFICINA_MAYOR      VARCHAR2,
                     P_LUGAR_OFICINA_MAYOR          VARCHAR2,
                     P_TELEFONO_EMPRESA_MAYOR       VARCHAR2,
                     P_DIRECCION_EMPRESA_MAYOR      VARCHAR2,
                     P_LUGAR_EMPRESA_MAYOR          VARCHAR2,
                     P_TOTAL_INGRESO_MENSUAL_MAYOR  VARCHAR2,
                     P_TOTAL_EGRESO_MENSUAL_MAYOR   VARCHAR2,
                     P_TOTAL_ACTIVOS_MAYOR          VARCHAR2,
                     P_TOTAL_PASIVOS_MAYOR          VARCHAR2,
                     P_TOTAL_PATRIMONIO_MAYOR       VARCHAR2,
                     P_OTRA_FUEN_MENSU_INGRES_MAYOR VARCHAR2,
                     P_CUANTO_SUMAN_MAYOR           VARCHAR2,
                     P_DONDE_PROVIENE_INGRESO_MAYOR VARCHAR2,
                     P_REALI_OPER_MONED_EXTRA_MAYOR VARCHAR2,
                     P_TIPO_OPERACI_PRINCIPAL_MAYOR VARCHAR2,
                     P_MONTO_ESTIMADO_MENSUAL_MAYOR VARCHAR2,
                     P_PAIS_DESTIN_ORIG_RECUR_MAYOR VARCHAR2,
                     P_PEP_NAC_O_EXT_MAYOR          VARCHAR2,
                     P_CARGO_POLITI_OTRO_PAIS_MAYOR VARCHAR2,
                     P_DIRE_SUBDIR_JUNT_DIREC_MAYOR VARCHAR2,
                     P_EXPUESTO_POLITICAMENTE_MAYOR VARCHAR2,
                     P_CARGO_2_MAYOR                VARCHAR2,
                     P_FECHA_VINCULACIO_CARGO_MAYOR VARCHAR2,
                     P_FECHA_DESVINCULA_CARGO_MAYOR VARCHAR2,
                     P_ES_CONY_COMP_PERM_PEP_MAYOR  VARCHAR2,
                     P_GRADO_CONSANGUINIDAD_MAYOR   VARCHAR2,
                     P_NOMBRES_3_MAYOR              VARCHAR2,
                     P_APELLIDOS_MAYOR              VARCHAR2,
                     P_APELLIDOS_4_MAYOR            VARCHAR2,
                     P_IMPACTADO_POR_FATCA_2_MAYOR  VARCHAR2,
                     P_NUMERO_TIN_MAYOR             VARCHAR2,
                     P_RESIDEN_FISC_OTRO_PAIS_MAYOR VARCHAR2,
                     P_PAIS_RES_FISC_OTRO_PAI_MAYOR VARCHAR2,
                     P_NUMERO_TIN_OTRO_PAI_MAYOR    VARCHAR2,
                     P_PAIS_RES_FIS_OTR_PAI_2_MAYOR VARCHAR2,
                     P_NUMERO_TIN_OTRO_PAI_2_MAYOR  VARCHAR2,
                     P_ADMINISTRA_RECUR_PUBLI_MAYOR VARCHAR2,
                     P_RECUR_ACT_ECO_OT_ING_MAYOR   VARCHAR2,
                     P_PAISES_ORIGEN_RECURSOS_MAYOR VARCHAR2,
                     P_INVESTIGA_JUDI_O_ADMIN_MAYOR VARCHAR2,
                     P_MOTIVO_INVESTIGACION_MAYOR   VARCHAR2,
                     P_FIRMA_ACEPTACION_MAYOR       VARCHAR2,
                     P_CONCEPTO_VINCULACION_3_MAYOR VARCHAR2,
                     P_COMPROMI_MEDIO_AMBIENT_MAYOR VARCHAR2,
                     P_TIPO_DE_IDENTIFICACI_4_MAYOR VARCHAR2,
                     P_SIGLA_4_MAYOR                VARCHAR2,
                     P_NUMERO_4_MAYOR               VARCHAR2,
                     P_NOMBRE_FUNCIONARIO_MAYOR     VARCHAR2,
                     P_TIPO_DE_IDENT_FUNCIONA_MAYOR VARCHAR2,
                     P_SIGLA_FUNCIONARIO_MAYOR      VARCHAR2,
                     P_NUMERO_FUNCIONARIO_MAYOR     VARCHAR2,
                     P_CARGO_FUNCIONARIO_MAYOR      VARCHAR2,
                     P_CODIGO_AGENTE_VENDEDOR_MAYOR VARCHAR2,
                     P_TELEFONO_EXTEN_FUNCION_MAYOR VARCHAR2,
                     P_DIA_FUNCIONARIO_MAYOR        VARCHAR2,
                     P_CIUDAD_FUNCIONARIO_MAYOR     VARCHAR2,
                     P_CONCEPTO_VINCULACION_MAYOR   VARCHAR2,
                     P_NOMBRES_5_MAYOR              VARCHAR2,
                     P_TIPO_DE_IDENTIFICACI_5_MAYOR VARCHAR2,
                     P_SIGLA_5_MAYOR                VARCHAR2,
                     P_NUMERO_5_MAYOR               VARCHAR2,
                     P_FECHA_VISITA_MAYOR           VARCHAR2,
                     P_PRIMER_APELLIDO_3_MAYOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_3_MAYOR     VARCHAR2,
                     P_NOMBRES_7_MAYOR              VARCHAR2,
                     P_CORREO_ELECTRONICO_2_MAYOR   VARCHAR2,
                     P_DECLARA_RENTA_2_MAYOR        VARCHAR2,
                     P_AUTORI_ENVIO_EXTRACTOS_MAYOR VARCHAR2,
                     P_NOMBRES_12_MAYOR             VARCHAR2,
                     P_PRIMER_APELLIDO_6_MAYOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_6_MAYOR     VARCHAR2,
                     P_TIPO_DE_IDENTIFICACI_7_MAYOR VARCHAR2,
                     P_NUMERO_7_MAYOR               VARCHAR2,
                     P_FECHA_EXPEDICION_2_MAYOR     VARCHAR2,
                     P_LUGAR_EXPEDICION_2_MAYOR     VARCHAR2,
                     P_PART_RELAC_TITUL_CUENT_MAYOR VARCHAR2,
                     P_CUAL_MAYOR                   VARCHAR2,
                     P_ROL_1_MAYOR                  VARCHAR2,
                     P_NOMBRES_ROL_2_MAYOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_2_MAYOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_2_MAYOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_2_MAYOR VARCHAR2,
                     P_NUMERO_ROL_2_MAYOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_2_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_2_MAYOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_2_MAYOR VARCHAR2,
                     P_CUAL_ROL_2_MAYOR             VARCHAR2,
                     P_ROL_2_MAYOR                  VARCHAR2,
                     P_NOMBRES_ROL_3_MAYOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_3_MAYOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_3_MAYOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_3_MAYOR VARCHAR2,
                     P_NUMERO_ROL_3_MAYOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_3_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_3_MAYOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_3_MAYOR VARCHAR2,
                     P_CUAL_ROL_3_MAYOR             VARCHAR2,
                     P_ROL_3_MAYOR                  VARCHAR2,
                     P_NOMBRES_ROL_4_MAYOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_4_MAYOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_4_MAYOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_4_MAYOR VARCHAR2,
                     P_NUMERO_ROL_4_MAYOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_4_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_4_MAYOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_4_MAYOR VARCHAR2,
                     P_CUAL_ROL_4_MAYOR             VARCHAR2,
                     P_ROL_4_MAYOR                  VARCHAR2,
                     P_NOMBRES_ROL_5_MAYOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_5_MAYOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_5_MAYOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_5_MAYOR VARCHAR2,
                     P_NUMERO_ROL_5_MAYOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_5_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_5_MAYOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_5_MAYOR VARCHAR2,
                     P_CUAL_ROL_5_MAYOR             VARCHAR2,
                     P_ROL_5_MAYOR                  VARCHAR2,
                     P_NOMBRES_ROL_6_MAYOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_6_MAYOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_6_MAYOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_6_MAYOR VARCHAR2,
                     P_NUMERO_ROL_6_MAYOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_6_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_6_MAYOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_6_MAYOR VARCHAR2,
                     P_CUAL_ROL_6_MAYOR             VARCHAR2,
                     P_ROL_6_MAYOR                  VARCHAR2,
                     P_POSEE_CUENTA_BANCARIA_MAYOR  VARCHAR2,
                     P_TIPO_CUENTA_BANCARIA_MAYOR   VARCHAR2,
                     P_ENTIDAD_BANCARIA_MAYOR       VARCHAR2,
                     P_NUMERO_CUENTA_BANCARIA_MAYOR VARCHAR2,
                     P_TIPO_CUENTA_BANCARIA_2_MAYOR VARCHAR2,
                     P_ENTIDAD_BANCARIA_2_MAYOR     VARCHAR2,
                     P_NUMERO_CUENTA_BANCAR_2_MAYOR VARCHAR2,
                     P_TIPO_CUENTA_BANCARIA_3_MAYOR VARCHAR2,
                     P_ENTIDAD_BANCARIA_3_MAYOR     VARCHAR2,
                     P_NUMERO_CUENTA_BANCAR_3_MAYOR VARCHAR2,
                     P_NOTA_DOCUMENTO_SOPORTE_MAYOR VARCHAR2,
                     P_SEGMENTO_CLIENTE_MAYOR       VARCHAR2,
                     P_MONTO_INICIAL_INVERSIO_MAYOR VARCHAR2,
                     P_TIPO_MONEDA_INVERSION_MAYOR  VARCHAR2,
                     P_OTRO_MAYOR                   VARCHAR2,
                     P_COMPART_INFORMAC_GRUPO_MAYOR VARCHAR2,
                     P_CONOCIM_PRODUC_INVERSI_MAYOR VARCHAR2,
                     P_EXPERIENCI_INVERSIONES_MAYOR VARCHAR2,
                     P_SITUACION_FINANCIERA_MAYOR   VARCHAR2,
                     P_PORCENTA_INGRESO_INVER_MAYOR VARCHAR2,
                     P_GASTO_IMPREVISTO_MAYOR       VARCHAR2,
                     P_ALTERNATIVAS_INVERSION_MAYOR VARCHAR2,
                     P_PLAZO_INVERSION_MAYOR        VARCHAR2,
                     P_COMPORTAMIENTO_INVERSI_MAYOR VARCHAR2,
                     P_PERDIDA_INVERSION_MAYOR      VARCHAR2,
                     P_PERFIL_MAYOR                 VARCHAR2,
                     P_PUNTAJE_MAYOR                VARCHAR2,
                     P_CALIDAD_ACTUACION_MAYOR      VARCHAR2,
                     P_NOMBRES_8_MAYOR              VARCHAR2,
                     P_NO_ID_CLIENTE_MAYOR          VARCHAR2,
                     P_DEPENDE_ECONOMICA_TERC_MAYOR VARCHAR2,
                     P_NOMBRE_TERCERO_MAYOR         VARCHAR2,
                     P_TIPO_IDENTIFIC_TERCERO_MAYOR VARCHAR2,
                     P_NUMERO_TERCERO_MAYOR         VARCHAR2,
                     P_ANO_2_MAYOR                  VARCHAR2,
                     P_VALOR_INGRESO_TOTA_ANU_MAYOR VARCHAR2,
                     P_VALOR_TOTAL_PATRIMONIO_MAYOR VARCHAR2,
                     P_VALOR_TOTAL_DEUDAS_MAYOR     VARCHAR2,
                     P_GASTOS_TOTAL_ANUAL_MAYOR     VARCHAR2,
                     P_VALOR_TOTAL_PATRI_LIQU_MAYOR VARCHAR2,
                     P_AGREGA_QUITA_COTITULAR_MAYOR VARCHAR2,
                     P_PRIMER_APELLIDO_4_MAYOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_4_MAYOR     VARCHAR2,
                     P_NOMBRES_9_MAYOR              VARCHAR2,
                     P_TIPO_DE_IDENTIFICAC_10_MAYOR VARCHAR2,
                     P_NUMERO_10_MAYOR              VARCHAR2,
                     P_LUGAR_EXPEDICION_3_MAYOR     VARCHAR2,
                     P_FECHA_EXPEDICION_3_MAYOR     VARCHAR2,
                     P_DIRECCION_MAYOR              VARCHAR2,
                     P_CIUDAD_3_MAYOR               VARCHAR2,
                     P_TELEFONO_FIJO_MAYOR          VARCHAR2,
                     P_CORREO_ELECTRONICO_3_MAYOR   VARCHAR2,
                     P_CELULAR_2_MAYOR              VARCHAR2,
                     P_PARTE_RELACIONADA_MAYOR      VARCHAR2,
                     P_CUAL_1_MAYOR                 VARCHAR2,
                     P_PRIMER_APELLIDO_5_MAYOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_5_MAYOR     VARCHAR2,
                     P_NOMBRES_11_MAYOR             VARCHAR2,
                     P_TIPO_DE_IDENTIFICAC_13_MAYOR VARCHAR2,
                     P_NUMERO_13_MAYOR              VARCHAR2,
                     P_LUGAR_EXPEDICION_4_MAYOR     VARCHAR2,
                     P_FECHA_EXPEDICION_4_MAYOR     VARCHAR2,
                     P_DIRECCION_1_MAYOR            VARCHAR2,
                     P_CIUDAD_6_MAYOR               VARCHAR2,
                     P_TELEFONO_FIJO_1_MAYOR        VARCHAR2,
                     P_CORREO_ELECTRONICO_5_MAYOR   VARCHAR2,
                     P_CELULAR_4_MAYOR              VARCHAR2,
                     P_PARTE_RELACIONADA_1_MAYOR    VARCHAR2,
                     P_CUAL_3_MAYOR                 VARCHAR2,
                     P_OBSERVACION_ADICIONAL_MAYOR  VARCHAR2,
                     P_NOMBRES_10_MAYOR             VARCHAR2,
                     P_APELLIDOS_3_MAYOR            VARCHAR2,
                     P_TIPO_DE_IDENTIFICAC_12_MAYOR VARCHAR2,
                     P_NUMERO_12_MAYOR              VARCHAR2,
                     P_CELULAR_3_MAYOR              VARCHAR2,
                     P_CORREO_ELECTRONICO_4_MAYOR   VARCHAR2,
                     P_PEP_NAC_O_EXT_2_MAYOR        VARCHAR2,
                     P_CARGO_POLITI_OTR_PAI_2_MAYOR VARCHAR2,
                     P_DIRE_SUBDIR_JUNT_DIR_2_MAYOR VARCHAR2,
                     P_EXPUESTO_POLITICAMEN_2_MAYOR VARCHAR2,
                     P_CARGO_PUBLICO_MAYOR          VARCHAR2,
                     P_FECHA_VINCULAC_CARGO_2_MAYOR VARCHAR2,
                     P_FECHA_DESVINCU_CARGO_2_MAYOR VARCHAR2,
                     P_ES_CONY_COMP_PER_PEP_2_MAYOR VARCHAR2,
                     P_GRADO_CONSANGUINIDAD_2_MAYOR VARCHAR2,
                     P_RECUR_ACT_ECO_OT_ING_2_MAYOR VARCHAR2,
                     P_PAISES_ORIGEN_RECURS_2_MAYOR VARCHAR2,
                     P_INVESTIGA_JUDI_O_ADM_2_MAYOR VARCHAR2,
                     P_MOTI_INVEST_FECH_AUTOR_MAYOR VARCHAR2,
                     P_DECLARACION_LECTURA_MAYOR    VARCHAR2,
                     P_NOMBRES_ORDENANTE_MAYOR      VARCHAR2,
                     P_PRIMER_APELLIDO_ORDENA_MAYOR VARCHAR2,
                     P_SEGUND_APELLIDO_ORDENA_MAYOR VARCHAR2,
                     P_TIPO_DOCUMENTO_ORDENAN_MAYOR VARCHAR2,
                     P_DOCUMENTO_ORDENANTE_MAYOR    VARCHAR2,
                     P_FECHA_EXPEDICI_ORDENAN_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICI_ORDENAN_MAYOR VARCHAR2,
                     P_PARTE_RELACIONADA_ORDE_MAYOR VARCHAR2,
                     P_PARTE_RELACION_ORDE_MAYOR    VARCHAR2,
                     P_ROL_ORDENANTE_MAYOR          VARCHAR2,
                     P_NOMBRES_1_ORDENANTE_MAYOR    VARCHAR2,
                     P_PRIMER_APELLIDO_1_ORDE_MAYOR VARCHAR2,
                     P_SEGUND_APELLIDO_1_ORDE_MAYOR VARCHAR2,
                     P_TIPO_DOCUMENTO_1_ORDEN_MAYOR VARCHAR2,
                     P_DOCUMENTO_1_ORDENANTE_MAYOR  VARCHAR2,
                     P_FECHA_EXPEDICI_1_ORDEN_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICI_1_ORDEN_MAYOR VARCHAR2,
                     P_PARTE_RELACIONADA_1_OR_MAYOR VARCHAR2,
                     P_PARTE_RELACION_1_ORDE_MAYOR  VARCHAR2,
                     P_ROL_1_ORDENANTE_MAYOR        VARCHAR2,
                     P_NOMBRES_2_ORDENANTE_MAYOR    VARCHAR2,
                     P_PRIMER_APELLIDO_2_ORDE_MAYOR VARCHAR2,
                     P_SEGUND_APELLIDO_2_ORDE_MAYOR VARCHAR2,
                     P_TIPO_DOCUMENTO_2_ORDEN_MAYOR VARCHAR2,
                     P_DOCUMENTO_2_ORDENANTE_MAYOR  VARCHAR2,
                     P_FECHA_EXPEDICI_2_ORDEN_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICI_2_ORDEN_MAYOR VARCHAR2,
                     P_PARTE_RELACIONADA_2_OR_MAYOR VARCHAR2,
                     P_PARTE_RELACION_2_ORDE_MAYOR  VARCHAR2,
                     P_ROL_2_ORDENANTE_MAYOR        VARCHAR2,
                     P_NOMBRES_3_ORDENANTE_MAYOR    VARCHAR2,
                     P_PRIMER_APELLIDO_3_ORDE_MAYOR VARCHAR2,
                     P_SEGUND_APELLIDO_3_ORDE_MAYOR VARCHAR2,
                     P_TIPO_DOCUMENTO_3_ORDEN_MAYOR VARCHAR2,
                     P_DOCUMENTO_3_ORDENANTE_MAYOR  VARCHAR2,
                     P_FECHA_EXPEDICI_3_ORDEN_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICI_3_ORDEN_MAYOR VARCHAR2,
                     P_PARTE_RELACIONADA_3_OR_MAYOR VARCHAR2,
                     P_PARTE_RELACION_3_ORDE_MAYOR  VARCHAR2,
                     P_ROL_3_ORDENANTE_MAYOR        VARCHAR2,
                     P_NOMBRES_4_ORDENANTE_MAYOR    VARCHAR2,
                     P_PRIMER_APELLIDO_4_ORDE_MAYOR VARCHAR2,
                     P_SEGUND_APELLIDO_4_ORDE_MAYOR VARCHAR2,
                     P_TIPO_DOCUMENTO_4_ORDEN_MAYOR VARCHAR2,
                     P_DOCUMENTO_4_ORDENANTE_MAYOR  VARCHAR2,
                     P_FECHA_EXPEDICI_4_ORDEN_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICI_4_ORDEN_MAYOR VARCHAR2,
                     P_PARTE_RELACIONADA_4_OR_MAYOR VARCHAR2,
                     P_PARTE_RELACION_4_ORDE_MAYOR  VARCHAR2,
                     P_ROL_4_ORDENANTE_MAYOR        VARCHAR2,
                     P_NOMBRES_5_ORDENANTE_MAYOR    VARCHAR2,
                     P_PRIMER_APELLIDO_5_ORDE_MAYOR VARCHAR2,
                     P_SEGUND_APELLIDO_5_ORDE_MAYOR VARCHAR2,
                     P_TIPO_DOCUMENTO_5_ORDEN_MAYOR VARCHAR2,
                     P_DOCUMENTO_5_ORDENANTE_MAYOR  VARCHAR2,
                     P_FECHA_EXPEDICI_5_ORDEN_MAYOR VARCHAR2,
                     P_LUGAR_EXPEDICI_5_ORDEN_MAYOR VARCHAR2,
                     P_PARTE_RELACIONADA_5_OR_MAYOR VARCHAR2,
                     P_PARTE_RELACION_5_ORDE_MAYOR  VARCHAR2,
                     P_ROL_5_ORDENANTE_MAYOR        VARCHAR2
                     -----------------------------------------
                     --, P_PN_MENOR
                    ,
                     P_NOMBRES_MENOR                VARCHAR2,
                     P_PRIMER_APELLIDO_MENOR        VARCHAR2,
                     P_SEGUNDO_APELLIDO_MENOR       VARCHAR2,
                     P_TIPO_IDENTIFICACION_MENOR    VARCHAR2,
                     P_NUMERO_DOCUMENTO_MENOR       VARCHAR2,
                     P_CODIGO_CIIU_MENOR            VARCHAR2,
                     P_DECLARA_RENTA_MENOR          VARCHAR2,
                     P_DEPENDE_DE_UN_TERCERO_MENOR  VARCHAR2,
                     P_IMPACTADO_FATCA_MENOR        VARCHAR2,
                     P_IMPACTADO_PEP_MENOR          VARCHAR2,
                     P_IMPACTADO_CRS_MENOR          VARCHAR2,
                     P_INCLUIR_COTITULAR_MENOR      VARCHAR2,
                     P_SON_CLIENT_DE_LA_FIRMA_MENOR VARCHAR2,
                     P_INFO_COTITU_ACTUALIZAD_MENOR VARCHAR2,
                     P_CANAL_VINCULACION_MENOR      VARCHAR2,
                     P_TIENE_PORTAFOL_VIGENTE_MENOR VARCHAR2,
                     P_ASESOR_SOLICITUD_MENOR       VARCHAR2,
                     P_NOMBRES_2_MENOR              VARCHAR2,
                     P_PRIMER_APELLIDO_2_MENOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_2_MENOR     VARCHAR2,
                     P_TIPO_SEXO_MENOR              VARCHAR2,
                     P_NACIONALIDAD_MENOR           VARCHAR2,
                     P_TIPO_IDENTIFICACION_2_MENOR  VARCHAR2,
                     P_SIGLA_2_MENOR                VARCHAR2,
                     P_NUMERO_DOCUMENTO_2_MENOR     VARCHAR2,
                     P_FECHA_EXPEDICION_MENOR       VARCHAR2,
                     P_LUGAR_EXPEDICION_MENOR       VARCHAR2,
                     P_FECHA_NACIMIENTO_MENOR       VARCHAR2,
                     P_LUGAR_NACIMIENTO_MENOR       VARCHAR2,
                     P_DIRECCION_RESIDENCIA_MENOR   VARCHAR2,
                     P_LUGAR_RESIDENCIA_MENOR       VARCHAR2,
                     P_TELEFONO_CELULAR_MENOR       VARCHAR2,
                     P_CORREO_ELECTRONICO_MENOR     VARCHAR2,
                     P_MODAL_INFORM_MANU_COST_MENOR VARCHAR2,
                     P_NOMBRES_3_MENOR              VARCHAR2,
                     P_PRIMER_APELLIDO_3_MENOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_3_MENOR     VARCHAR2,
                     P_PARENTEZCO_MENOR             VARCHAR2,
                     P_PEP_NAC_O_EXT_MENOR          VARCHAR2,
                     P_CARGO_POLITI_OTRO_PAIS_MENOR VARCHAR2,
                     P_DIRE_SUBDIR_JUNT_DIREC_MENOR VARCHAR2,
                     P_EXPUESTO_POLITICAMENTE_MENOR VARCHAR2,
                     P_CARGO_MENOR                  VARCHAR2,
                     P_FECHA_VINCULACIO_CARGO_MENOR VARCHAR2,
                     P_FECHA_DESVINCULA_CARGO_MENOR VARCHAR2,
                     P_ES_CONY_COMP_PERM_PEP_MENOR  VARCHAR2,
                     P_GRADO_CONSANGUINIDAD_MENOR   VARCHAR2,
                     P_NOMBRES_4_MENOR              VARCHAR2,
                     P_APELLIDOS_MENOR              VARCHAR2,
                     P_APELLIDOS_2_MENOR            VARCHAR2,
                     P_IMPACTADO_FATCA_2_MENOR      VARCHAR2,
                     P_NUMERO_TIN_MENOR             VARCHAR2,
                     P_RESIDEN_FISC_OTRO_PAIS_MENOR VARCHAR2,
                     P_PAIS_RES_FISC_OTRO_PAI_MENOR VARCHAR2,
                     P_NUMERO_TIN_OTRO_PAI_MENOR    VARCHAR2,
                     P_PAIS_RES_FIS_OTR_PAI_2_MENOR VARCHAR2,
                     P_NUMERO_TIN_OTRO_PAI_2_MENOR  VARCHAR2,
                     P_RECUR_ACT_ECO_OT_ING_MENOR   VARCHAR2,
                     P_PAISES_ORIGEN_RECURSOS_MENOR VARCHAR2,
                     P_INVESTIGA_JUDI_O_ADMIN_MENOR VARCHAR2,
                     P_MOTIVO_INVESTIGACION_MENOR   VARCHAR2,
                     P_FIRMA_ACEPTACION_MENOR       VARCHAR2,
                     P_CONCEPTO_VINCULACION_2_MENOR VARCHAR2,
                     P_ENVIO_CORRESPONDENCIA_MENOR  VARCHAR2,
                     P_TIPO_IDENTIFICACION_4_MENOR  VARCHAR2,
                     P_SIGLA_4_MENOR                VARCHAR2,
                     P_NUMERO_DOCUMENTO_4_MENOR     VARCHAR2,
                     P_NOMBR_APELLID_FUNCIONA_MENOR VARCHAR2,
                     P_TIPO_DE_IDENT_FUNCIONA_MENOR VARCHAR2,
                     P_SIGLA_FUNCIONARIO_MENOR      VARCHAR2,
                     P_NUMERO_FUNCIONARIO_MENOR     VARCHAR2,
                     P_CARGO_FUNCIONARIO_MENOR      VARCHAR2,
                     P_CODIGO_AGENTE_VENDEDOR_MENOR VARCHAR2,
                     P_TELEFONO_EXTEN_FUNCION_MENOR VARCHAR2,
                     P_CIUDAD_FUNCIONARIO_MENOR     VARCHAR2,
                     P_CONCEPTO_VINCULACION_MENOR   VARCHAR2,
                     P_NOMBRES_APELLIDOS_MENOR      VARCHAR2,
                     P_NOMBRES_9_MENOR              VARCHAR2,
                     P_PRIMER_APELLIDO_5_MENOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_5_MENOR     VARCHAR2,
                     P_TIPO_IDENTIFICACION_10_MENOR VARCHAR2,
                     P_NUMERO_DOCUMENTO_10_MENOR    VARCHAR2,
                     P_TELEFONO_CELULAR_2_MENOR     VARCHAR2,
                     P_CORREO_ELECTRONICO_3_MENOR   VARCHAR2,
                     P_PEP_NAC_O_EXT_2_MENOR        VARCHAR2,
                     P_CARGO_POLITI_OTR_PAI_2_MENOR VARCHAR2,
                     P_DIRE_SUBDIR_JUN_DIRE_2_MENOR VARCHAR2,
                     P_EXPUESTO_POLITICAMEN_2_MENOR VARCHAR2,
                     P_CARGO_4_MENOR                VARCHAR2,
                     P_FECHA_VINCULAC_2_CARGO_MENOR VARCHAR2,
                     P_FECHA_DESVINCU_2_CARGO_MENOR VARCHAR2,
                     P_ES_CONY_COMP_PER_PEP_2_MENOR VARCHAR2,
                     P_GRADO_CONSANGUINIDAD_2_MENOR VARCHAR2,
                     P_NOMBRES_10_MENOR             VARCHAR2,
                     P_PRIMER_APELLIDO_4_MENOR      VARCHAR2,
                     P_SEGUNDO_APELLIDO_4_MENOR     VARCHAR2,
                     P_NOMBRES_7_MENOR              VARCHAR2,
                     P_CORREO_ELECTRONICO_2_MENOR   VARCHAR2,
                     P_DECLARA_RENTA_2_MENOR        VARCHAR2,
                     P_TIPO_IDENTIFICACION_7_MENOR  VARCHAR2,
                     P_NUMERO_DOCUMENTO_7_MENOR     VARCHAR2,
                     P_FECHA_EXPEDICION_2_MENOR     VARCHAR2,
                     P_LUGAR_EXPEDICION_2_MENOR     VARCHAR2,
                     P_PART_RELAC_TITUL_CUENT_MENOR VARCHAR2,
                     P_CUAL_MENOR                   VARCHAR2,
                     P_ROL_MENOR                    VARCHAR2,
                     P_NOMBRES_ROL_1_MENOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_1_MENOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_1_MENOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_1_MENOR VARCHAR2,
                     P_NUMERO_ROL_1_MENOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_1_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_1_MENOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_1_MENOR VARCHAR2,
                     P_CUAL_ROL_1_MENOR             VARCHAR2,
                     P_ROL_1_MENOR                  VARCHAR2,
                     P_NOMBRES_ROL_2_MENOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_2_MENOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_2_MENOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_2_MENOR VARCHAR2,
                     P_NUMERO_ROL_2_MENOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_2_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_2_MENOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_2_MENOR VARCHAR2,
                     P_CUAL_ROL_2_MENOR             VARCHAR2,
                     P_ROL_2_MENOR                  VARCHAR2,
                     P_NOMBRES_ROL_3_MENOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_3_MENOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_3_MENOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_3_MENOR VARCHAR2,
                     P_NUMERO_ROL_3_MENOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_3_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_3_MENOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_3_MENOR VARCHAR2,
                     P_CUAL_ROL_3_MENOR             VARCHAR2,
                     P_ROL_3_MENOR                  VARCHAR2,
                     P_NOMBRES_ROL_4_MENOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_4_MENOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_4_MENOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_4_MENOR VARCHAR2,
                     P_NUMERO_ROL_4_MENOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_4_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_4_MENOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_4_MENOR VARCHAR2,
                     P_CUAL_ROL_4_MENOR             VARCHAR2,
                     P_ROL_4_MENOR                  VARCHAR2,
                     P_NOMBRES_ROL_5_MENOR          VARCHAR2,
                     P_PRIMER_APELLIDO_ROL_5_MENOR  VARCHAR2,
                     P_SEGUNDO_APELLIDO_ROL_5_MENOR VARCHAR2,
                     P_TIPO_IDENTIFICAC_ROL_5_MENOR VARCHAR2,
                     P_NUMERO_ROL_5_MENOR           VARCHAR2,
                     P_FECHA_EXPEDICION_ROL_5_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICION_ROL_5_MENOR VARCHAR2,
                     P_PARTE_RELACIONAD_ROL_5_MENOR VARCHAR2,
                     P_CUAL_ROL_5_MENOR             VARCHAR2,
                     P_ROL_5_MENOR                  VARCHAR2,
                     P_TIENE_CUEN_ENTID_BANCA_MENOR VARCHAR2,
                     P_TIPO_CUENTA_BANCARIA_MENOR   VARCHAR2,
                     P_ENTIDAD_BANCARIA_MENOR       VARCHAR2,
                     P_NUMERO_CUENTA_BANCARIA_MENOR VARCHAR2,
                     P_TIPO_CUENTA_BANCARIA_2_MENOR VARCHAR2,
                     P_ENTIDAD_BANCARIA_2_MENOR     VARCHAR2,
                     P_NUMERO_CUENTA_BANCAR_2_MENOR VARCHAR2,
                     P_TIPO_CUENTA_BANCARIA_3_MENOR VARCHAR2,
                     P_ENTIDAD_BANCARIA_3_MENOR     VARCHAR2,
                     P_NUMERO_CUENTA_BANCAR_3_MENOR VARCHAR2,
                     P_NOTA_DOCUMENTO_SOPORTE_MENOR VARCHAR2,
                     P_SEGMENTACION_CLIENTE_MENOR   VARCHAR2,
                     P_MONTO_INICIAL_INVERSIO_MENOR VARCHAR2,
                     P_TIPO_MONEDA_INVERSION_MENOR  VARCHAR2,
                     P_OTRO_MENOR                   VARCHAR2,
                     P_COMPART_INFORMAC_GRUPO_MENOR VARCHAR2,
                     P_RECUR_ACT_ECO_OT_ING_2_MENOR VARCHAR2,
                     P_PAISES_ORIGEN_RECURS_2_MENOR VARCHAR2,
                     P_INVESTIGA_JUDI_O_ADM_2_MENOR VARCHAR2,
                     P_MOTIVO_INVESTIGACION_2_MENOR VARCHAR2,
                     P_FIRMA_ACEPTACION_2_MENOR     VARCHAR2,
                     P_NOMBRES_APELLIDOS_2_MENOR    VARCHAR2,
                     P_TIPO_IDENTIFICACION_8_MENOR  VARCHAR2,
                     P_NUMERO_DOCUMENTO_8_MENOR     VARCHAR2,
                     P_CONOCIM_PRODUC_INVERSI_MENOR VARCHAR2,
                     P_EXPERIENCI_INVERSIONES_MENOR VARCHAR2,
                     P_SITUACION_FINANCIERA_MENOR   VARCHAR2,
                     P_PORCENTA_INGRESO_INVER_MENOR VARCHAR2,
                     P_GASTO_IMPREVISTO_AFECT_MENOR VARCHAR2,
                     P_OBJETIVO_INVERSION_MENOR     VARCHAR2,
                     P_PLAZO_INVERSION_MENOR        VARCHAR2,
                     P_COMPORTAMIEN_INVERSION_MENOR VARCHAR2,
                     P_PERDIDA_INVERSION_MENOR      VARCHAR2,
                     P_PERFIL_MENOR                 VARCHAR2,
                     P_PUNTAJE_MENOR                VARCHAR2,
                     P_NOMBRE_FUNCIONARIO_MENOR     VARCHAR2,
                     P_CARGO_3_MENOR                VARCHAR2,
                     P_FECHA_MENOR                  VARCHAR2,
                     P_MEDIO_RECEPCIO_ENCUEST_MENOR VARCHAR2,
                     P_NOMBRES_8_MENOR              VARCHAR2,
                     P_NO_ID_CLIENTE_MENOR          VARCHAR2,
                     P_CODIGO_OFICINA_MENOR         VARCHAR2,
                     P_NO_PRODUCTO_MENOR            VARCHAR2,
                     P_DEPENDE_ECONOMIC_TERCE_MENOR VARCHAR2,
                     P_NOMBRES_APELLIDOS_TERC_MENOR VARCHAR2,
                     P_TIPO_IDENTIFICACI_TERC_MENOR VARCHAR2,
                     P_NUMERO_IDENTIFICA_TERC_MENOR VARCHAR2,
                     P_ANO_TERCERO_MENOR            VARCHAR2,
                     P_VALO_INGR_TOT_ANU_RECI_MENOR VARCHAR2,
                     P_VALOR_TOTAL_PATRIMONIO_MENOR VARCHAR2,
                     P_VALOR_TOTAL_DEUDAS_MENOR     VARCHAR2,
                     P_GASTO_TOTAL_ANUAL_MENOR      VARCHAR2,
                     P_VALOR_TOTA_PATRI_LIQUI_MENOR VARCHAR2,
                     P_NOMBRES_ORDENANTE_MENOR      VARCHAR2,
                     P_PRIMER_APELLIDO_ORDENA_MENOR VARCHAR2,
                     P_SEGUND_APELLIDO_ORDENA_MENOR VARCHAR2,
                     P_TIPO_DOCUMENTO_ORDENAN_MENOR VARCHAR2,
                     P_DOCUMENTO_ORDENANTE_MENOR    VARCHAR2,
                     P_FECHA_EXPEDICI_ORDENAN_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICI_ORDENAN_MENOR VARCHAR2,
                     P_PARTE_RELACIONADA_ORDE_MENOR VARCHAR2,
                     P_PARTE_RELACION_ORDE_MENOR    VARCHAR2,
                     P_ROL_ORDENANTE_MENOR          VARCHAR2,
                     P_NOMBRES_1_ORDENANTE_MENOR    VARCHAR2,
                     P_PRIMER_APELLIDO_1_ORDE_MENOR VARCHAR2,
                     P_SEGUND_APELLIDO_1_ORDE_MENOR VARCHAR2,
                     P_TIPO_DOCUMENTO_1_ORDEN_MENOR VARCHAR2,
                     P_DOCUMENTO_1_ORDENANTE_MENOR  VARCHAR2,
                     P_FECHA_EXPEDICI_1_ORDEN_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICI_1_ORDEN_MENOR VARCHAR2,
                     P_PARTE_RELACIONADA_1_OR_MENOR VARCHAR2,
                     P_PARTE_RELACION_1_ORDE_MENOR  VARCHAR2,
                     P_ROL_1_ORDENANTE_MENOR        VARCHAR2,
                     P_NOMBRES_2_ORDENANTE_MENOR    VARCHAR2,
                     P_PRIMER_APELLIDO_2_ORDE_MENOR VARCHAR2,
                     P_SEGUND_APELLIDO_2_ORDE_MENOR VARCHAR2,
                     P_TIPO_DOCUMENTO_2_ORDEN_MENOR VARCHAR2,
                     P_DOCUMENTO_2_ORDENANTE_MENOR  VARCHAR2,
                     P_FECHA_EXPEDICI_2_ORDEN_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICI_2_ORDEN_MENOR VARCHAR2,
                     P_PARTE_RELACIONADA_2_OR_MENOR VARCHAR2,
                     P_PARTE_RELACION_2_ORDE_MENOR  VARCHAR2,
                     P_ROL_2_ORDENANTE_MENOR        VARCHAR2,
                     P_NOMBRES_3_ORDENANTE_MENOR    VARCHAR2,
                     P_PRIMER_APELLIDO_3_ORDE_MENOR VARCHAR2,
                     P_SEGUND_APELLIDO_3_ORDE_MENOR VARCHAR2,
                     P_TIPO_DOCUMENTO_3_ORDEN_MENOR VARCHAR2,
                     P_DOCUMENTO_3_ORDENANTE_MENOR  VARCHAR2,
                     P_FECHA_EXPEDICI_3_ORDEN_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICI_3_ORDEN_MENOR VARCHAR2,
                     P_PARTE_RELACIONADA_3_OR_MENOR VARCHAR2,
                     P_PARTE_RELACION_3_ORDE_MENOR  VARCHAR2,
                     P_ROL_3_ORDENANTE_MENOR        VARCHAR2,
                     P_NOMBRES_4_ORDENANTE_MENOR    VARCHAR2,
                     P_PRIMER_APELLIDO_4_ORDE_MENOR VARCHAR2,
                     P_SEGUND_APELLIDO_4_ORDE_MENOR VARCHAR2,
                     P_TIPO_DOCUMENTO_4_ORDEN_MENOR VARCHAR2,
                     P_DOCUMENTO_4_ORDENANTE_MENOR  VARCHAR2,
                     P_FECHA_EXPEDICI_4_ORDEN_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICI_4_ORDEN_MENOR VARCHAR2,
                     P_PARTE_RELACIONADA_4_OR_MENOR VARCHAR2,
                     P_PARTE_RELACION_4_ORDE_MENOR  VARCHAR2,
                     P_ROL_4_ORDENANTE_MENOR        VARCHAR2,
                     P_NOMBRES_5_ORDENANTE_MENOR    VARCHAR2,
                     P_PRIMER_APELLIDO_5_ORDE_MENOR VARCHAR2,
                     P_SEGUND_APELLIDO_5_ORDE_MENOR VARCHAR2,
                     P_TIPO_DOCUMENTO_5_ORDEN_MENOR VARCHAR2,
                     P_DOCUMENTO_5_ORDENANTE_MENOR  VARCHAR2,
                     P_FECHA_EXPEDICI_5_ORDEN_MENOR VARCHAR2,
                     P_LUGAR_EXPEDICI_5_ORDEN_MENOR VARCHAR2,
                     P_PARTE_RELACIONADA_5_OR_MENOR VARCHAR2,
                     P_PARTE_RELACION_5_ORDE_MENOR  VARCHAR2,
                     P_ROL_5_ORDENANTE_MENOR        VARCHAR2,
                     P_ERROR1                       OUT VARCHAR2,
                     P_ERROR2                       OUT VARCHAR2) IS

    CURSOR C_RES_FISCAL IS
      SELECT *
        FROM PERSONA_NATURAL
       WHERE PNF_CLI_PER_NUM_IDEN = P_NUMERO_2_MAYOR
         AND PNF_CLI_PER_TID_CODIGO = P_SIGLA_2_MAYOR;
    V_RES_FISCAL C_RES_FISCAL%ROWTYPE;

    CURSOR C_CCC IS
      SELECT *
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = P_NUMERO_2_MAYOR
         AND CCC_CLI_PER_TID_CODIGO = P_SIGLA_2_MAYOR;
    V_CCC C_CCC%ROWTYPE;

    CURSOR C_RES_FISCAL_MENOR(TIPO_IDENTIFICAC_MENOR VARCHAR2) IS
      SELECT *
        FROM PERSONA_NATURAL
       WHERE PNF_CLI_PER_NUM_IDEN = P_NUMERO_DOCUMENTO_MENOR
         AND PNF_CLI_PER_TID_CODIGO = TIPO_IDENTIFICAC_MENOR;
    V_RES_FISCAL_MENOR C_RES_FISCAL%ROWTYPE;

    CURSOR C_CCC_MENOR(TIPO_IDENTIFICAC_MENOR VARCHAR2) IS
      SELECT *
        FROM CUENTAS_CLIENTE_CORREDORES
       WHERE CCC_CLI_PER_NUM_IDEN = P_NUMERO_DOCUMENTO_MENOR
         AND CCC_CLI_PER_TID_CODIGO = TIPO_IDENTIFICAC_MENOR;
    V_CCC_MENOR C_CCC%ROWTYPE;

    V_CLOB1                CLOB;
    V_CLOB2                CLOB;
    V_CLOB3                CLOB;
    FORMULARIO_VIN         NUMBER;
    V_FORMULARIO_APERTURA  NUMBER;
    PN_MAYOR               VARCHAR2(1);
    PN_MENOR               VARCHAR2(1);
    NUMERO_FORMULARIO      NUMBER;
    TIPO_SEXO              VARCHAR2(1);
    LUGAR_RESIDENCIA       NUMBER;
    LUGAR_OFICINA          NUMBER;
    LUGAR_EXPEDICION       NUMBER;
    LUGAR_NACIMIENTO       NUMBER;
    ENTIDAD_BANCARIA       NUMBER;
    LUGAR_RESIDENCIA_ORD   NUMBER;
    PROPOSITO_RELACION     NUMBER;
    PROPOSITO_RELACION1    NUMBER;
    PROPOSITO_RELACION2    NUMBER;
    PROPOSITO_RELACION3    NUMBER;
    PROPOSITO_RELACION4    NUMBER;
    TIPO_CUENTA_BANCARIA   VARCHAR2(3);
    NACIONALIDAD           VARCHAR2(3);
    ACTIVIDAD_LABORAL      VARCHAR2(3);
    GRADO_CONSANGUINIDAD   VARCHAR2(3);
    RES_FISC_OTRO_PAI1     VARCHAR2(3);
    RES_FISC_OTRO_PAI2     VARCHAR2(3);
    CORRESPONDENCIA        VARCHAR2(3);
    TIPO_IDENTIFICAC_MENOR VARCHAR2(3);
    EXTRANJERA             VARCHAR2(1);
    FECHA_EXPEDICION       VARCHAR2(20);
    FECHA_EXPEDICION_M     VARCHAR2(20);
    PROFESION              VARCHAR2(5);
    IMPACTADO_POR_PEP      VARCHAR2(1);
    DECLARA_RENTA          VARCHAR2(1);
    IMPACTADO_POR_FATCA    VARCHAR2(1);
    IMPACTADO_POR_CRS      VARCHAR2(1);
    EXP_SECTOR_PUBLICO     VARCHAR2(1);
    EXPUESTO_POLITICAMENTE VARCHAR2(1);
    CARGO_POLITI_OTRO_PAIS VARCHAR2(1);
    EXISTE                 VARCHAR2(1);
    EXISTE_ORD             VARCHAR2(1);
    COMPARTIR_INFORMACION  VARCHAR2(1);
    MONEDA_EXT             VARCHAR2(1);
    BANCA_PRIVADA          VARCHAR2(1);
    ADMINISTRA_RECUR_PUBLI VARCHAR2(1);
    RECONO_POLITICA_PEP    VARCHAR2(1);
    REP_LEGAL_PEP          VARCHAR2(1);
    PAIS                   VARCHAR2(5);
    RESIDENCIA_FISCAL      VARCHAR2(5);
    RIC_OTRO               VARCHAR2(10);
    NOMBRE_USUARIO         VARCHAR2(20);
    TIPO_PROPOSI_RELACION  VARCHAR2(200);
    TIPO_PROPOSI_RELACION1 VARCHAR2(200);
    TIPO_PROPOSI_RELACION2 VARCHAR2(200);
    TIPO_PROPOSI_RELACION3 VARCHAR2(200);
    V_CONSECUTIVO          NUMBER;
    V_CONSECUTIVOP         NUMBER;
    PARENTESCO             NUMBER;
    ERROR1                 VARCHAR2(2000);

  BEGIN

    IF P_NUMERO_2_MAYOR IS NOT NULL THEN
      PN_MAYOR := 'S';
    END IF;

    IF P_NUMERO_DOCUMENTO_MENOR IS NOT NULL THEN
      PN_MENOR := 'S';
    END IF;

    SELECT VINGO_SEQ.NEXTVAL INTO NUMERO_FORMULARIO FROM DUAL;

    V_FORMULARIO_APERTURA := FORMULARIO_VIN;

    IF PN_MAYOR = 'S' THEN

      BEGIN
        IF P_TIPO_SEXO_MAYOR = 'Femenino' THEN
          TIPO_SEXO := 'F';
        ELSIF P_TIPO_SEXO_MAYOR = 'Masculino' THEN
          TIPO_SEXO := 'M';
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000, 'Persona Mayor sin Sexo');

      END;

      IF P_LUGAR_EMPRESA_MAYOR IS NOT NULL THEN

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_OFICINA
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EMPRESA_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con oficina errada: ' ||
                                    P_LUGAR_EMPRESA_MAYOR);
        END;

      END IF;

      IF P_LUGAR_OFICINA_MAYOR IS NOT NULL THEN

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_OFICINA
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_OFICINA_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con oficina errada: ' ||
                                    P_LUGAR_OFICINA_MAYOR);
        END;

      END IF;

      BEGIN
        SELECT AGE_CODIGO
          INTO LUGAR_EXPEDICION
          FROM AREAS_GEOGRAFICAS
         WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
               TRIM(P_LUGAR_EXPEDICION_MAYOR)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con ciudad de expedición del documento errado: ' ||
                                  P_LUGAR_EXPEDICION_MAYOR);
      END;

      BEGIN
        SELECT PER_NOMBRE_USUARIO
          INTO NOMBRE_USUARIO
          FROM PERSONAS
         WHERE PER_NUM_IDEN = TRIM(P_NUMERO_FUNCIONARIO_MAYOR)
           AND PER_TID_CODIGO = TRIM(P_SIGLA_FUNCIONARIO_MAYOR);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con asesor errado y/o no existe en el sistema: ' ||
                                  P_NUMERO_FUNCIONARIO_MAYOR || ' - ' ||
                                  P_SIGLA_FUNCIONARIO_MAYOR);
      END;

      FECHA_EXPEDICION := SUBSTR(P_FECHA_EXPEDICION_MAYOR, 9, 2) || '-' ||
                          SUBSTR(P_FECHA_EXPEDICION_MAYOR, 6, 2) || '-' ||
                          SUBSTR(P_FECHA_EXPEDICION_MAYOR, 1, 4);

      P_CAB.PR_PERSONAS_RLC_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                    P_CLI_PER_NUM_IDEN      => P_NUMERO_2_MAYOR,
                                    P_CLI_PER_TID_CODIGO    => P_SIGLA_2_MAYOR,
                                    P_FECHA_APERTURA        => SYSDATE,
                                    P_ESTADO                => 'POR_PROCESAR',
                                    P_PER_NUM_IDEN          => P_NUMERO_FUNCIONARIO_MAYOR,
                                    P_PER_TID_CODIGO        => P_SIGLA_FUNCIONARIO_MAYOR,
                                    P_PRIMER_APELLIDO       => P_PRIMER_APELLIDO_MAYOR,
                                    P_SEGUNDO_APELLIDO      => P_SEGUNDO_APELLIDO_MAYOR,
                                    P_NOMBRE                => P_NOMBRES_MAYOR,
                                    P_TIPO_SEXO             => TIPO_SEXO,
                                    P_ROL_ORDENANTE         => 1,
                                    P_CARGO                 => P_CARGO_MAYOR,
                                    P_CELULAR               => P_CELULAR_MAYOR,
                                    P_TELEFONO              => P_TELEFONO_MAYOR,
                                    P_DIRECCION_OFICINA     => NVL(P_DIRECCION_EMPRESA_MAYOR,
                                                                   P_DIRECCION_OFICINA_MAYOR),
                                    P_CIUDAD_OFICINA        => LUGAR_OFICINA,
                                    P_FECHA_EXP_DOCUMENTO   => FECHA_EXPEDICION,
                                    P_CIUDAD_EXP_DOCUMENTO  => LUGAR_EXPEDICION,
                                    P_CALIDAD               => 'OR',
                                    P_PARENTESCO            => 37,
                                    P_DIRECCION_EMAIL       => P_CORREO_ELECTRONICO_MAYOR,
                                    P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                    P_CLOB                  => V_CLOB1);

      IF P_POSEE_CUENTA_BANCARIA_MAYOR != 'No' THEN

        -- PRIMERA CUENTA BANCARIA

        IF P_ENTIDAD_BANCARIA_MAYOR IS NOT NULL AND
           P_TIPO_CUENTA_BANCARIA_MAYOR IS NOT NULL THEN

          BEGIN
            SELECT BAN_CODIGO
              INTO ENTIDAD_BANCARIA
              FROM BANCOS
             WHERE BAN_NOMBRE = TRIM(P_ENTIDAD_BANCARIA_MAYOR)
               AND BAN_ESTADO = 'A';
          EXCEPTION
            WHEN OTHERS THEN
              ENTIDAD_BANCARIA := NULL;
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con entidad bancaria 1 errada: ' ||
                                      P_ENTIDAD_BANCARIA_MAYOR);
          END;

          IF TRIM(P_TIPO_CUENTA_BANCARIA_MAYOR) = 'Ahorros' OR
             TRIM(P_TIPO_CUENTA_BANCARIA_MAYOR) = 'Ahorro' THEN
            TIPO_CUENTA_BANCARIA := 'CAH';
          ELSIF TRIM(P_TIPO_CUENTA_BANCARIA_MAYOR) = 'Corriente' THEN
            TIPO_CUENTA_BANCARIA := 'CCO';
          ELSE
            TIPO_CUENTA_BANCARIA := NULL;
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con tipo de cuenta bancaria 1 errada: ' ||
                                    P_TIPO_CUENTA_BANCARIA_MAYOR);
          END IF;

          IF ENTIDAD_BANCARIA IS NOT NULL AND
             TIPO_CUENTA_BANCARIA IS NOT NULL THEN

            P_CAB.PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                         P_CLI_PER_NUM_IDEN      => P_NUMERO_2_MAYOR,
                                         P_CLI_PER_TID_CODIGO    => P_SIGLA_2_MAYOR,
                                         P_FECHA_APERTURA        => SYSDATE,
                                         P_ESTADO                => 'POR_PROCESAR',
                                         P_BANCO                 => ENTIDAD_BANCARIA,
                                         P_NUMERO_CUENTA         => P_NUMERO_CUENTA_BANCARIA_MAYOR,
                                         P_TIPO                  => TIPO_CUENTA_BANCARIA,
                                         P_SUCURSAL              => NULL,
                                         P_DIRECCION             => NULL,
                                         P_TELEFONO              => NULL,
                                         P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                         P_CLOB                  => V_CLOB2);

          END IF;

        END IF;

        -- SEGUNDA CUENTA BANCARIA

        IF P_ENTIDAD_BANCARIA_2_MAYOR IS NOT NULL AND
           P_TIPO_CUENTA_BANCARIA_2_MAYOR IS NOT NULL THEN

          ENTIDAD_BANCARIA     := NULL;
          TIPO_CUENTA_BANCARIA := NULL;

          BEGIN
            SELECT BAN_CODIGO
              INTO ENTIDAD_BANCARIA
              FROM BANCOS
             WHERE BAN_NOMBRE = TRIM(P_ENTIDAD_BANCARIA_2_MAYOR)
               AND BAN_ESTADO = 'A';
          EXCEPTION
            WHEN OTHERS THEN
              ENTIDAD_BANCARIA := NULL;
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con entidad bancaria 2 errada: ' ||
                                      P_ENTIDAD_BANCARIA_2_MAYOR);
          END;

          IF TRIM(P_TIPO_CUENTA_BANCARIA_2_MAYOR) = 'Ahorros' OR
             TRIM(P_TIPO_CUENTA_BANCARIA_2_MAYOR) = 'Ahorro' THEN
            TIPO_CUENTA_BANCARIA := 'CAH';
          ELSIF TRIM(P_TIPO_CUENTA_BANCARIA_2_MAYOR) = 'Corriente' THEN
            TIPO_CUENTA_BANCARIA := 'CCO';
          ELSE
            TIPO_CUENTA_BANCARIA := NULL;
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con tipo de cuenta bancaria 2 errada: ' ||
                                    P_TIPO_CUENTA_BANCARIA_2_MAYOR);
          END IF;

          IF ENTIDAD_BANCARIA IS NOT NULL AND
             TIPO_CUENTA_BANCARIA IS NOT NULL THEN

            P_CAB.PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                         P_CLI_PER_NUM_IDEN      => P_NUMERO_2_MAYOR,
                                         P_CLI_PER_TID_CODIGO    => P_SIGLA_2_MAYOR,
                                         P_FECHA_APERTURA        => SYSDATE,
                                         P_ESTADO                => 'POR_PROCESAR',
                                         P_BANCO                 => ENTIDAD_BANCARIA,
                                         P_NUMERO_CUENTA         => P_NUMERO_CUENTA_BANCAR_2_MAYOR,
                                         P_TIPO                  => TIPO_CUENTA_BANCARIA,
                                         P_SUCURSAL              => NULL,
                                         P_DIRECCION             => NULL,
                                         P_TELEFONO              => NULL,
                                         P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                         P_CLOB                  => V_CLOB2);

          END IF;

        END IF;

        -- TERCERA CUENTA BANCARIA

        IF P_ENTIDAD_BANCARIA_3_MAYOR IS NOT NULL AND
           P_TIPO_CUENTA_BANCARIA_3_MAYOR IS NOT NULL THEN

          ENTIDAD_BANCARIA     := NULL;
          TIPO_CUENTA_BANCARIA := NULL;

          BEGIN
            SELECT BAN_CODIGO
              INTO ENTIDAD_BANCARIA
              FROM BANCOS
             WHERE BAN_NOMBRE = TRIM(P_ENTIDAD_BANCARIA_3_MAYOR)
               AND BAN_ESTADO = 'A';
          EXCEPTION
            WHEN OTHERS THEN
              ENTIDAD_BANCARIA := NULL;
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con entidad bancaria 3 errada: ' ||
                                      P_ENTIDAD_BANCARIA_3_MAYOR);
          END;

          IF TRIM(P_TIPO_CUENTA_BANCARIA_3_MAYOR) = 'Ahorros' OR
             TRIM(P_TIPO_CUENTA_BANCARIA_3_MAYOR) = 'Ahorro' THEN
            TIPO_CUENTA_BANCARIA := 'CAH';
          ELSIF TRIM(P_TIPO_CUENTA_BANCARIA_3_MAYOR) = 'Corriente' THEN
            TIPO_CUENTA_BANCARIA := 'CCO';
          ELSE
            TIPO_CUENTA_BANCARIA := NULL;
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con tipo de cuenta bancaria 3 errada: ' ||
                                    P_TIPO_CUENTA_BANCARIA_3_MAYOR);
          END IF;

          IF ENTIDAD_BANCARIA IS NOT NULL AND
             TIPO_CUENTA_BANCARIA IS NOT NULL THEN

            P_CAB.PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                         P_CLI_PER_NUM_IDEN      => P_NUMERO_2_MAYOR,
                                         P_CLI_PER_TID_CODIGO    => P_SIGLA_2_MAYOR,
                                         P_FECHA_APERTURA        => SYSDATE,
                                         P_ESTADO                => 'POR_PROCESAR',
                                         P_BANCO                 => ENTIDAD_BANCARIA,
                                         P_NUMERO_CUENTA         => P_NUMERO_CUENTA_BANCAR_3_MAYOR,
                                         P_TIPO                  => TIPO_CUENTA_BANCARIA,
                                         P_SUCURSAL              => NULL,
                                         P_DIRECCION             => NULL,
                                         P_TELEFONO              => NULL,
                                         P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                         P_CLOB                  => V_CLOB2);

          END IF;

        END IF;

      END IF;

      BEGIN
        SELECT PAI_CODIGO
          INTO PAIS
          FROM PAISES
         WHERE PAI_NOMBRE = TRIM(P_NACIONALIDAD_MAYOR);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con Pais errado: ' ||
                                  P_NACIONALIDAD_MAYOR);
      END;

      IF PAIS != 'COL' THEN
        NACIONALIDAD := 'ERE';
      ELSE
        NACIONALIDAD := 'COL';
      END IF;

      IF NACIONALIDAD NOT IN ('COL', 'COM') THEN
        EXTRANJERA := 'S';
      ELSE
        EXTRANJERA := 'N';
      END IF;

      BEGIN
        SELECT AGE_CODIGO
          INTO LUGAR_NACIMIENTO
          FROM AREAS_GEOGRAFICAS
         WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
               TRIM(P_LUGAR_NACIMIENTO_MAYOR)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con lugar de nacimiento errado: ' ||
                                  P_LUGAR_NACIMIENTO_MAYOR);
      END;

      BEGIN
        SELECT PSC_MNEMONICO
          INTO PROFESION
          FROM PROFESIONES_CLIENTES
         WHERE PSC_DESCRIPCION = TRIM(P_PROFESION_MAYOR);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con profesión errada: ' ||
                                  P_PROFESION_MAYOR);
      END;

      IF P_PEP_NAC_O_EXT_MAYOR = 'No' THEN
        IMPACTADO_POR_PEP := 'N';
      ELSIF P_PEP_NAC_O_EXT_MAYOR = 'Si' THEN
        IMPACTADO_POR_PEP := 'S';
      ELSE
        IMPACTADO_POR_PEP := 'N';
      END IF;

      IF P_PEP_NAC_O_EXT_MAYOR = 'Si' THEN
        EXPUESTO_POLITICAMENTE := 'S';
      ELSE
        EXPUESTO_POLITICAMENTE := 'N';
      END IF;

      IF P_DECLARA_RENTA_MAYOR = 'No' THEN
        DECLARA_RENTA := 'N';
      ELSIF P_DECLARA_RENTA_MAYOR = 'Si' THEN
        DECLARA_RENTA := 'S';
      ELSE
        DECLARA_RENTA := 'N';
      END IF;

      BEGIN
        SELECT AGE_CODIGO
          INTO LUGAR_RESIDENCIA
          FROM AREAS_GEOGRAFICAS
         WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
               TRIM(P_LUGAR_RESIDENCIA_MAYOR)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con ciudad de residencia errada: ' ||
                                  P_LUGAR_RESIDENCIA_MAYOR);
      END;

      IF P_IMPACTADO_POR_FATCA_2_MAYOR = 'No' THEN
        IMPACTADO_POR_FATCA := 'N';
      ELSIF P_IMPACTADO_POR_FATCA_2_MAYOR = 'Si' THEN
        IMPACTADO_POR_FATCA := 'S';
      ELSE
        IMPACTADO_POR_FATCA := 'N';
      END IF;

      IF P_RESIDEN_FISC_OTRO_PAIS_MAYOR = 'No' THEN
        IMPACTADO_POR_CRS := 'N';
      ELSIF P_RESIDEN_FISC_OTRO_PAIS_MAYOR = 'Si' THEN
        IMPACTADO_POR_CRS := 'S';
      ELSE
        IMPACTADO_POR_CRS := 'N';
      END IF;

      IF P_CARGO_PUBLICO_MAYOR = 'Si' THEN
        EXP_SECTOR_PUBLICO := 'S';
      ELSE
        EXP_SECTOR_PUBLICO := 'N';
      END IF;

      IF P_PERFIL_MAYOR IS NULL THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Mayor sin perfil de riesgo: ' ||
                                P_PERFIL_MAYOR);
      END IF;

      BEGIN
        SELECT 'X'
          INTO EXISTE
          FROM CIIUS_NUEVOS
         WHERE CNU_MNEMONICO = P_CODIGO_CIIU_MAYOR;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor con código CIIU errado o inexistente: ' ||
                                  P_CODIGO_CIIU_MAYOR);
      END;

      IF EXISTE != 'X' THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Mayor con código CIIU errado o inexistente: ' ||
                                P_CODIGO_CIIU_MAYOR);
      END IF;

      IF P_TIPO_MONEDA_INVERSION_MAYOR IS NOT NULL THEN

        IF NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR), ','), 0) = 0 THEN

          IF TRIM(P_TIPO_MONEDA_INVERSION_MAYOR) = 'Pesos' THEN
            PROPOSITO_RELACION := 1;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MAYOR) = 'Dólares' THEN
            PROPOSITO_RELACION := 2;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MAYOR) =
                'Compra y venta de divisas con fines diferentes a inversión' THEN
            PROPOSITO_RELACION := 3;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MAYOR) =
                'Transaccional (Descuento de títulos)' THEN
            PROPOSITO_RELACION := 4;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MAYOR) = 'Otro' THEN
            PROPOSITO_RELACION := 5;
          ELSE
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                    P_TIPO_MONEDA_INVERSION_MAYOR);
          END IF;

        ELSE

          IF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                    1,
                    NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR), ','), 0) - 1) =
             'Pesos' THEN
            PROPOSITO_RELACION := 1;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR), ','),
                           0) - 1) = 'Dólares' THEN
            PROPOSITO_RELACION := 2;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR), ','),
                           0) - 1) =
                'Compra y venta de divisas con fines diferentes a inversión' THEN
            PROPOSITO_RELACION := 3;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR), ','),
                           0) - 1) = 'Transaccional (Descuento de títulos)' THEN
            PROPOSITO_RELACION := 4;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR), ','),
                           0) - 1) = 'Otro' THEN
            PROPOSITO_RELACION := 5;
          ELSE
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                    P_TIPO_MONEDA_INVERSION_MAYOR);
          END IF;

          TIPO_PROPOSI_RELACION := SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                                          NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                                                    ','),
                                              0) + 1,
                                          LENGTH(P_TIPO_MONEDA_INVERSION_MAYOR) -
                                          NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MAYOR),
                                                    ','),
                                              0));

          IF NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) = 0 THEN

            IF TRIM(TIPO_PROPOSI_RELACION) = 'Pesos' THEN
              PROPOSITO_RELACION1 := 1;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) = 'Dólares' THEN
              PROPOSITO_RELACION1 := 2;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) =
                  'Compra y venta de divisas con fines diferentes a inversión' THEN
              PROPOSITO_RELACION1 := 3;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) =
                  'Transaccional (Descuento de títulos)' THEN
              PROPOSITO_RELACION1 := 4;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) = 'Otro' THEN
              PROPOSITO_RELACION1 := 5;
            ELSE
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                      P_TIPO_MONEDA_INVERSION_MAYOR);
            END IF;

          ELSE

            IF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                      1,
                      NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
               'Pesos' THEN
              PROPOSITO_RELACION1 := 1;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Dólares' THEN
              PROPOSITO_RELACION1 := 2;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Compra y venta de divisas con fines diferentes a inversión' THEN
              PROPOSITO_RELACION1 := 3;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Transaccional (Descuento de títulos)' THEN
              PROPOSITO_RELACION1 := 4;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Otro' THEN
              PROPOSITO_RELACION1 := 5;
            ELSE
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                      P_TIPO_MONEDA_INVERSION_MAYOR);
            END IF;

            TIPO_PROPOSI_RELACION1 := SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION),
                                                       ','),
                                                 0) + 1,
                                             LENGTH(TIPO_PROPOSI_RELACION) -
                                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION),
                                                       ','),
                                                 0));

            IF NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) = 0 THEN

              IF TRIM(TIPO_PROPOSI_RELACION1) = 'Pesos' THEN
                PROPOSITO_RELACION2 := 1;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) = 'Dólares' THEN
                PROPOSITO_RELACION2 := 2;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) =
                    'Compra y venta de divisas con fines diferentes a inversión' THEN
                PROPOSITO_RELACION2 := 3;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) =
                    'Transaccional (Descuento de títulos)' THEN
                PROPOSITO_RELACION2 := 4;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) = 'Otro' THEN
                PROPOSITO_RELACION2 := 5;
              ELSE
                RAISE_APPLICATION_ERROR(-20000,
                                        'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                        P_TIPO_MONEDA_INVERSION_MAYOR);
              END IF;

            ELSE

              IF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                        1,
                        NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                 'Pesos' THEN
                PROPOSITO_RELACION2 := 1;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Dólares' THEN
                PROPOSITO_RELACION2 := 2;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Compra y venta de divisas con fines diferentes a inversión' THEN
                PROPOSITO_RELACION2 := 3;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Transaccional (Descuento de títulos)' THEN
                PROPOSITO_RELACION2 := 4;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Otro' THEN
                PROPOSITO_RELACION2 := 5;
              ELSE
                RAISE_APPLICATION_ERROR(-20000,
                                        'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                        P_TIPO_MONEDA_INVERSION_MAYOR);
              END IF;

              TIPO_PROPOSI_RELACION2 := SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                                               NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1),
                                                         ','),
                                                   0) + 1,
                                               LENGTH(TIPO_PROPOSI_RELACION1) -
                                               NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1),
                                                         ','),
                                                   0));

              IF NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) = 0 THEN

                IF TRIM(TIPO_PROPOSI_RELACION2) = 'Pesos' THEN
                  PROPOSITO_RELACION3 := 1;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) = 'Dólares' THEN
                  PROPOSITO_RELACION3 := 2;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) =
                      'Compra y venta de divisas con fines diferentes a inversión' THEN
                  PROPOSITO_RELACION3 := 3;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) =
                      'Transaccional (Descuento de títulos)' THEN
                  PROPOSITO_RELACION3 := 4;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) = 'Otro' THEN
                  PROPOSITO_RELACION3 := 5;
                ELSE
                  RAISE_APPLICATION_ERROR(-20000,
                                          'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                          P_TIPO_MONEDA_INVERSION_MAYOR);
                END IF;

              ELSE

                IF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                          1,
                          NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                   'Pesos' THEN
                  PROPOSITO_RELACION3 := 1;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Dólares' THEN
                  PROPOSITO_RELACION3 := 2;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Compra y venta de divisas con fines diferentes a inversión' THEN
                  PROPOSITO_RELACION3 := 3;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Transaccional (Descuento de títulos)' THEN
                  PROPOSITO_RELACION3 := 4;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Otro' THEN
                  PROPOSITO_RELACION3 := 5;
                ELSE
                  RAISE_APPLICATION_ERROR(-20000,
                                          'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                          P_TIPO_MONEDA_INVERSION_MAYOR);
                END IF;

                TIPO_PROPOSI_RELACION3 := SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                                                 NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2),
                                                           ','),
                                                     0) + 1,
                                                 LENGTH(TIPO_PROPOSI_RELACION2) -
                                                 NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2),
                                                           ','),
                                                     0));

                IF TRIM(TIPO_PROPOSI_RELACION3) = 'Pesos' THEN
                  PROPOSITO_RELACION4 := 1;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) = 'Dólares' THEN
                  PROPOSITO_RELACION4 := 2;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) =
                      'Compra y venta de divisas con fines diferentes a inversión' THEN
                  PROPOSITO_RELACION4 := 3;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) =
                      'Transaccional (Descuento de títulos)' THEN
                  PROPOSITO_RELACION4 := 4;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) = 'Otro' THEN
                  PROPOSITO_RELACION4 := 5;
                ELSE
                  RAISE_APPLICATION_ERROR(-20000,
                                          'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                          P_TIPO_MONEDA_INVERSION_MAYOR);
                END IF;

              END IF;

            END IF;

          END IF;

        END IF;

      ELSE
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                P_TIPO_MONEDA_INVERSION_MAYOR);
      END IF;

      IF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Empleado' THEN
        ACTIVIDAD_LABORAL := 'EMP';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Pensionado o Jubilado' THEN
        ACTIVIDAD_LABORAL := 'PEN';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Independiente' THEN
        ACTIVIDAD_LABORAL := 'IND';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Rentista de capital' THEN
        ACTIVIDAD_LABORAL := 'RDC';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Religioso' THEN
        ACTIVIDAD_LABORAL := 'REL';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Socio' THEN
        ACTIVIDAD_LABORAL := 'SOC';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Servidor público' THEN
        ACTIVIDAD_LABORAL := 'SPU';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Ama de casa' THEN
        ACTIVIDAD_LABORAL := 'ADC';
      ELSIF TRIM(P_TIPO_ACTIVID_LABORAL_2_MAYOR) = 'Estudiante' THEN
        ACTIVIDAD_LABORAL := 'EST';
      ELSE
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Mayor con actividad laboral errada o inexistente: ' ||
                                P_TIPO_ACTIVID_LABORAL_2_MAYOR);
      END IF;

      IF P_ES_CONY_COMP_PERM_PEP_MAYOR = 'Si' THEN
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Abuelo(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'ABC';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Yerno(Nuera)' THEN
          GRADO_CONSANGUINIDAD := 'YEN';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Abuelo(a)' THEN
          GRADO_CONSANGUINIDAD := 'ABU';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Cuñado(a)' THEN
          GRADO_CONSANGUINIDAD := 'CUN';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR =
           'Conyugue / Compañero(a) Permanente' THEN
          GRADO_CONSANGUINIDAD := 'COP';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Conyugue' THEN
          GRADO_CONSANGUINIDAD := 'COP';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'COP';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Nieto(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'NIC';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Nieto(a)' THEN
          GRADO_CONSANGUINIDAD := 'NIE';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Hermano(a)' THEN
          GRADO_CONSANGUINIDAD := 'HER';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Hermano(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'HCO';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Hijo(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'HIC';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Hijo(a)' THEN
          GRADO_CONSANGUINIDAD := 'HIJ';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Suegro(a)' THEN
          GRADO_CONSANGUINIDAD := 'SUE';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Padre/Madre' THEN
          GRADO_CONSANGUINIDAD := 'PAD';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Padre' THEN
          GRADO_CONSANGUINIDAD := 'PAD';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR = 'Madre' THEN
          GRADO_CONSANGUINIDAD := 'PAD';
        END IF;
        IF P_GRADO_CONSANGUINIDAD_MAYOR IS NULL OR
           P_GRADO_CONSANGUINIDAD_MAYOR NOT IN
           ('Abuelo(a) Conyuge',
            'Yerno(Nuera)',
            'Abuelo(a)',
            'Cuñado(a)',
            'Conyugue / Compañero(a) Permanente',
            'Conyugue',
            'Conyuge',
            'Nieto(a) Conyuge',
            'Nieto(a)',
            'Hermano(a)',
            'Hermano(a) Conyuge',
            'Hijo(a) Conyuge',
            'Hijo(a)',
            'Suegro(a)',
            'Padre/Madre',
            'Padre',
            'Madre') THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor Expuesta Políticamente sin grado de consaguinidad y/o consaguinidad errada: ' ||
                                  P_GRADO_CONSANGUINIDAD_MAYOR);
        END IF;
      END IF;

      IF P_NUMERO_TIN_OTRO_PAI_MAYOR IS NOT NULL THEN

        IF TRIM(P_PAIS_RES_FISC_OTRO_PAI_MAYOR) = 'SUDAFRICA' THEN
          RES_FISC_OTRO_PAI1 := 'ZAF';
        ELSE
          BEGIN
            SELECT PAI_CODIGO
              INTO RES_FISC_OTRO_PAI1
              FROM PAISES
             WHERE PAI_NOMBRE = TRIM(P_PAIS_RES_FISC_OTRO_PAI_MAYOR);
          EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con 1 Residencia Fiscal en otro Pais errada: ' ||
                                      P_PAIS_RES_FISC_OTRO_PAI_MAYOR);
          END;
        END IF;

      END IF;

      IF P_NUMERO_TIN_OTRO_PAI_2_MAYOR IS NOT NULL THEN

        IF TRIM(P_PAIS_RES_FIS_OTR_PAI_2_MAYOR) = 'SUDAFRICA' THEN
          RES_FISC_OTRO_PAI2 := 'ZAF';
        ELSE
          BEGIN
            SELECT PAI_CODIGO
              INTO RES_FISC_OTRO_PAI2
              FROM PAISES
             WHERE PAI_NOMBRE = TRIM(P_PAIS_RES_FIS_OTR_PAI_2_MAYOR);
          EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con 2 Residencia Fiscal en otro Pais errada: ' ||
                                      P_PAIS_RES_FIS_OTR_PAI_2_MAYOR);
          END;
        END IF;

      END IF;

      IF TRIM(P_COMPROMI_MEDIO_AMBIENT_MAYOR) =
         'Recibirlo en fisico en la oficina' THEN
        CORRESPONDENCIA := 'OFI';
      END IF;
      IF TRIM(P_COMPROMI_MEDIO_AMBIENT_MAYOR) =
         'Recibirlo en fisico en la residencia' THEN
        CORRESPONDENCIA := 'RES';
      END IF;
      IF TRIM(P_COMPROMI_MEDIO_AMBIENT_MAYOR) =
         'Consultarlo en la zona transaccional (Internet)' THEN
        CORRESPONDENCIA := 'INT';
      END IF;
      IF TRIM(P_COMPROMI_MEDIO_AMBIENT_MAYOR) =
         'Recibirlo al correo electrónico' THEN
        CORRESPONDENCIA := 'CEL';
      END IF;
      IF P_COMPROMI_MEDIO_AMBIENT_MAYOR IS NULL OR
         TRIM(P_COMPROMI_MEDIO_AMBIENT_MAYOR) NOT IN
         ('Consultarlo en la zona transaccional (Internet)',
          'Recibirlo al correo electrónico',
          'Recibirlo en fisico en la residencia',
          'Recibirlo en fisico en la oficina') THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Mayor sin tipo de envío de correspondencia');
      END IF;

      IF P_DIRE_SUBDIR_JUNT_DIREC_MAYOR IS NOT NULL THEN

        IF P_DIRE_SUBDIR_JUNT_DIREC_MAYOR = 'Si' THEN
          RECONO_POLITICA_PEP := 'N';
          REP_LEGAL_PEP       := 'S';
        ELSE
          IF P_EXPUESTO_POLITICAMENTE_MAYOR = 'Si' OR
             P_CARGO_POLITI_OTRO_PAIS_MAYOR = 'Si' THEN
            RECONO_POLITICA_PEP := 'S';
            REP_LEGAL_PEP       := 'N';
          ELSE
            RECONO_POLITICA_PEP := 'N';
            REP_LEGAL_PEP       := 'N';
          END IF;
        END IF;

      END IF;

      P_CAB.PR_DATOS_CLIENTE_VINCULA(P_TIPO_CLIENTE               => 'PNA',
                                     P_NOMBRES                    => P_NOMBRES_MAYOR,
                                     P_PRIMER_APELLIDO            => P_PRIMER_APELLIDO_MAYOR,
                                     P_SEGUNDO_APELLIDO           => P_SEGUNDO_APELLIDO_MAYOR,
                                     P_TIPO_IDENTIFICACION        => P_SIGLA_2_MAYOR,
                                     P_NUMERO_IDENTIFICACION      => P_NUMERO_2_MAYOR,
                                     P_FECHA_EXP_DOCUMENTO        => TO_CHAR(TRUNC(TO_DATE(P_FECHA_EXPEDICION_MAYOR,
                                                                                           'YYYY-MM-DD')),
                                                                             'DD-MM-YYYY'),
                                     P_CIUDAD_EXP_DOCUMENTO       => LUGAR_EXPEDICION,
                                     P_TIPOSEXO                   => TIPO_SEXO,
                                     P_RAZONSOCIAL                => NULL,
                                     P_CIUDAD_EMPRESA             => NULL,
                                     P_EXTRANJERA                 => EXTRANJERA,
                                     P_NACIONALIDAD               => NACIONALIDAD,
                                     P_CODIGO_ESTADO_CIVIL        => 'SOL',
                                     P_CIUDAD_NACIMIENTO          => LUGAR_NACIMIENTO,
                                     P_FECHA_NACIMIENTO           => TO_CHAR(TRUNC(TO_DATE(P_FECHA_NACIMIENTO_MAYOR,
                                                                                           'YYYY-MM-DD')),
                                                                             'DD-MM-YYYY'),
                                     P_DIRECCION_EMAIL            => P_CORREO_ELECTRONICO_MAYOR,
                                     P_REFERENCIADO               => NULL,
                                     P_PROFESION                  => PROFESION,
                                     P_NOMBRE_EMPRESA             => SUBSTR(P_NOMBRE_EMPRESA_MAYOR,
                                                                            1,
                                                                            40),
                                     P_CARGO_EMPLEADO             => P_CARGO_MAYOR,
                                     P_ACTIVIDAD_CLIENTE          => ACTIVIDAD_LABORAL,
                                     P_ORIGEN_RECURSOS            => 'AHO',
                                     P_OTRO_ORIGEN_RECURSOS       => NULL,
                                     P_RECURSOS_ENTREGAR          => 'Dinero',
                                     P_OTRO_RECURSO_ENTREGA       => NULL,
                                     P_CODIGOCIIU                 => P_CODIGO_CIIU_MAYOR,
                                     P_CIIU_SECUNDARIO            => P_CODIGO_CIIU_SECUNDARIO_MAYOR,
                                     P_ACT_ECONOMICA_PPAL         => NULL,
                                     P_EXP_SECTOR_PUBLICO         => EXP_SECTOR_PUBLICO,
                                     P_TIPO_EMPRESA               => 2,
                                     P_CLASIFICACION_ENTIDAD      => 99,
                                     P_GRAN_CONTRIBUYENTE         => NULL,
                                     P_DECLARANTE                 => DECLARA_RENTA,
                                     P_SUJETO_RETEFUENTE          => NULL,
                                     P_FECHA_CREACION_EMPRESA     => NULL,
                                     P_CAMPANA_POLITICA           => NULL,
                                     P_CLASE_SOCIEDAD             => NULL,
                                     P_DIRECCION_RESIDENCIA       => P_DIRECCION_RESIDENCIA_MAYOR,
                                     P_CIUDAD_RESIDENCIA          => LUGAR_RESIDENCIA,
                                     P_TELEFONO_RESIDENCIA        => P_TELEFONO_MAYOR,
                                     P_DIRECCION_OFICINA          => NVL(P_DIRECCION_EMPRESA_MAYOR,
                                                                         P_DIRECCION_OFICINA_MAYOR),
                                     P_CIUDAD_OFICINA             => LUGAR_OFICINA,
                                     P_TELEFONO_OFICINA           => NVL(P_TELEFONO_EMPRESA_MAYOR,
                                                                         P_TELEFONO_MAYOR),
                                     P_APARTADO_AEREO             => NULL,
                                     P_FAX                        => NULL,
                                     P_TIPO_CORRESPONDENCIA       => CORRESPONDENCIA,
                                     P_CELULAR                    => P_CELULAR_MAYOR,
                                     P_PERFIL_RIESGO              => P_PERFIL_MAYOR,
                                     P_ING_MEN_OPERACIONALES      => TO_NUMBER(REPLACE(REPLACE(P_TOTAL_INGRESO_MENSUAL_MAYOR,
                                                                                               '.',
                                                                                               ''),
                                                                                       ',',
                                                                                       '.')),
                                     P_EGR_MEN_OPERACIONALES      => TO_NUMBER(REPLACE(REPLACE(P_TOTAL_EGRESO_MENSUAL_MAYOR,
                                                                                               '.',
                                                                                               ''),
                                                                                       ',',
                                                                                       '.')),
                                     P_EGR_MEN_NO_OPERACIONA      => 0,
                                     P_ING_MEN_NO_OPERACIONA      => 0,
                                     P_ACTIVOS                    => TO_NUMBER(REPLACE(REPLACE(P_TOTAL_ACTIVOS_MAYOR,
                                                                                               '.',
                                                                                               ''),
                                                                                       ',',
                                                                                       '.')),
                                     P_PASIVOS                    => TO_NUMBER(REPLACE(REPLACE(P_TOTAL_PASIVOS_MAYOR,
                                                                                               '.',
                                                                                               ''),
                                                                                       ',',
                                                                                       '.')),
                                     P_PATRIMONIO                 => TO_NUMBER(REPLACE(REPLACE(P_TOTAL_ACTIVOS_MAYOR,
                                                                                               '.',
                                                                                               ''),
                                                                                       ',',
                                                                                       '.')) -
                                                                     TO_NUMBER(REPLACE(REPLACE(P_TOTAL_PASIVOS_MAYOR,
                                                                                               '.',
                                                                                               ''),
                                                                                       ',',
                                                                                       '.')),
                                     P_CONTRATO_COMISION          => P_CONTRATO_COMISION,
                                     P_CONTRATO_DCVAL             => SUBSTR(P_CONTRATO_DECEVAL,
                                                                            4,
                                                                            3),
                                     P_CATEGORIA_CONTRAPARTE      => NULL,
                                     P_NUMERO_FORMULARIO_VIN      => FORMULARIO_VIN,
                                     P_TIPO_IDE_COMERCIAL         => P_SIGLA_FUNCIONARIO_MAYOR,
                                     P_NUM_IDEN_COMERCIAL         => P_NUMERO_FUNCIONARIO_MAYOR,
                                     P_COD_USUARIO_COMERCIAL      => NOMBRE_USUARIO,
                                     P_ORIGEN_OPERACION           => NULL,
                                     P_CATEGORIZACION_CLIENTE     => 'N',
                                     P_RECONO_PUBLICA_PEP         => IMPACTADO_POR_PEP,
                                     P_RECONO_POLITICA_PEP        => RECONO_POLITICA_PEP,
                                     P_RECONOCIMIENTO_PUBLICO     => EXPUESTO_POLITICAMENTE,
                                     P_REP_LEGAL_PEP              => REP_LEGAL_PEP,
                                     P_CARGO_PEP                  => P_CARGO_2_MAYOR,
                                     P_FECHA_CARGO_PEP            => TO_CHAR(TRUNC(TO_DATE(P_FECHA_VINCULACIO_CARGO_MAYOR,
                                                                                           'YYYY-MM-DD')),
                                                                             'DD-MM-YYYY'),
                                     P_FECHA_DESVINCULA_PEP       => TO_CHAR(TRUNC(TO_DATE(P_FECHA_DESVINCULA_CARGO_MAYOR,
                                                                                           'YYYY-MM-DD')),
                                                                             'DD-MM-YYYY'),
                                     P_GRADO_CONSANGUI_PEP        => GRADO_CONSANGUINIDAD,
                                     P_NOMBRE_FAMILIAR_PEP        => P_NOMBRES_3_MAYOR,
                                     P_PRIMER_APELLIDO_PEP        => P_APELLIDOS_MAYOR,
                                     P_SEGUNDO_APELLIDO_PEP       => P_APELLIDOS_4_MAYOR,
                                     P_IMPACTADO_FATCA_FN         => IMPACTADO_POR_FATCA,
                                     P_IMPACTADO_CRS_FN           => IMPACTADO_POR_CRS,
                                     P_TIN_FN                     => P_NUMERO_TIN_MAYOR,
                                     P_PAI_FISCAL1_FN             => RES_FISC_OTRO_PAI1,
                                     P_PAI_FISCAL2_FN             => RES_FISC_OTRO_PAI2,
                                     P_TIN_CRS1_FN                => P_NUMERO_TIN_OTRO_PAI_MAYOR,
                                     P_TIN_CRS2_FN                => P_NUMERO_TIN_OTRO_PAI_2_MAYOR,
                                     P_PAI_NACIMIENTO_FN          => PAIS,
                                     P_AGE_CODIGO_RESIDE_FN       => LUGAR_RESIDENCIA,
                                     P_ESTADO_VINCULACION_DIGITAL => 'N',
                                     P_USUARIO_APERTURA           => USER,
                                     P_FORMULARIO_APERTURA        => V_FORMULARIO_APERTURA,
                                     P_CLOB                       => V_CLOB3);

      IF PROPOSITO_RELACION = 5 THEN
        RIC_OTRO := 'OTRO';
      ELSE
        RIC_OTRO := NULL;
      END IF;

      DELETE FROM PERSONAS_RELACIONADAS
       WHERE RLC_PER_NUM_IDEN = P_NUMERO_FUNCIONARIO_MAYOR
         AND RLC_PER_TID_CODIGO = P_SIGLA_FUNCIONARIO_MAYOR
         AND RLC_CLI_PER_NUM_IDEN = P_NUMERO_2_MAYOR
         AND RLC_CLI_PER_TID_CODIGO = P_SIGLA_2_MAYOR;

      INSERT INTO CLIENTE_PROPOSITO_RELACION
        (CRI_CLI_PER_NUM_IDEN,
         CRI_CLI_PER_TID_CODIGO,
         CRI_RIC_CONSECUTIVO,
         CRI_RIC_OTRO)
      VALUES
        (P_NUMERO_2_MAYOR,
         P_SIGLA_2_MAYOR,
         NVL(PROPOSITO_RELACION, 5),
         RIC_OTRO);

      IF PROPOSITO_RELACION1 IS NOT NULL THEN

        IF PROPOSITO_RELACION1 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_2_MAYOR,
           P_SIGLA_2_MAYOR,
           NVL(PROPOSITO_RELACION1, 5),
           RIC_OTRO);

      END IF;

      IF PROPOSITO_RELACION2 IS NOT NULL THEN

        IF PROPOSITO_RELACION2 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_2_MAYOR,
           P_SIGLA_2_MAYOR,
           NVL(PROPOSITO_RELACION2, 5),
           RIC_OTRO);

      END IF;

      IF PROPOSITO_RELACION3 IS NOT NULL THEN

        IF PROPOSITO_RELACION3 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_2_MAYOR,
           P_SIGLA_2_MAYOR,
           NVL(PROPOSITO_RELACION3, 5),
           RIC_OTRO);

      END IF;

      IF PROPOSITO_RELACION4 IS NOT NULL THEN

        IF PROPOSITO_RELACION4 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_2_MAYOR,
           P_SIGLA_2_MAYOR,
           NVL(PROPOSITO_RELACION4, 5),
           RIC_OTRO);

      END IF;

      IF P_COMPART_INFORMAC_GRUPO_MAYOR = 'Autorizo' THEN
        COMPARTIR_INFORMACION := 'S';
      ELSE
        COMPARTIR_INFORMACION := 'N';
      END IF;

      IF P_REALI_OPER_MONED_EXTRA_MAYOR = 'Si' THEN
        MONEDA_EXT := 'S';
      ELSE
        MONEDA_EXT := 'N';
      END IF;

      IF P_ADMINISTRA_RECUR_PUBLI_MAYOR = 'Si' THEN
        ADMINISTRA_RECUR_PUBLI := 'S';
      ELSE
        ADMINISTRA_RECUR_PUBLI := 'N';
      END IF;

      IF P_SEGMENTO_CLIENTE_MAYOR = 'Banca Privada' THEN
        BANCA_PRIVADA := 'S';
      ELSE
        BANCA_PRIVADA := 'N';
      END IF;

      UPDATE CLIENTES
         SET CLI_MONTO_INICIAL_INVERSION  = TO_NUMBER(REPLACE(REPLACE(P_MONTO_INICIAL_INVERSIO_MAYOR,
                                                                      '.',
                                                                      ''),
                                                              ',',
                                                              '.')),
             CLI_REG_SIMPLE               = 'N',
             CLI_REG_TRIB_ESP             = 'N',
             CLI_MIGRADO                  = 'N',
             CLI_COMPARTIR_INFORMACION    = COMPARTIR_INFORMACION,
             CLI_MONEDA_EXT               = MONEDA_EXT,
             CLI_RECURSOS_BIENES_ENTREGAR = 'D',
             CLI_RECURSOS_PUBLICOS        = ADMINISTRA_RECUR_PUBLI,
             CLI_BANCA_PRIVADA            = BANCA_PRIVADA
       WHERE CLI_PER_NUM_IDEN = P_NUMERO_2_MAYOR
         AND CLI_PER_TID_CODIGO = P_SIGLA_2_MAYOR;

      OPEN C_RES_FISCAL;
      FETCH C_RES_FISCAL
        INTO V_RES_FISCAL;
      CLOSE C_RES_FISCAL;

      IF P_PAIS_DESTIN_ORIG_RECUR_MAYOR IS NULL THEN
        RESIDENCIA_FISCAL := 'COL';
      ELSE
        BEGIN
          SELECT AGE_PAI_CODIGO
            INTO RESIDENCIA_FISCAL
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_PAIS = TRIM(P_PAIS_DESTIN_ORIG_RECUR_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor residencia fiscal errada: ' ||
                                    RESIDENCIA_FISCAL);
        END;

        IF V_RES_FISCAL.PNF_RESIDENCIA_FISCAL IS NULL OR
           V_RES_FISCAL.PNF_RESIDENCIA_FISCAL = '' THEN
          IF NACIONALIDAD = 'COM' THEN
            RESIDENCIA_FISCAL := 'COL';
          ELSIF NACIONALIDAD != 'COL' THEN
            RESIDENCIA_FISCAL := RESIDENCIA_FISCAL;
          END IF;
          UPDATE PERSONA_NATURAL
             SET PNF_RESIDENCIA_FISCAL   = RESIDENCIA_FISCAL,
                 PNF_MOT_CONSECUTIVO     = NULL,
                 PNF_OTRO_MOTIVO_ESTADIA = NULL
           WHERE PNF_CLI_PER_NUM_IDEN = P_NUMERO_2_MAYOR
             AND PNF_CLI_PER_TID_CODIGO = P_SIGLA_2_MAYOR;
        END IF;
      END IF;

      OPEN C_CCC;
      FETCH C_CCC
        INTO V_CCC;
      IF C_CCC%NOTFOUND THEN
        INSERT INTO CUENTAS_CLIENTE_CORREDORES
          (CCC_CLI_PER_NUM_IDEN,
           CCC_CLI_PER_TID_CODIGO,
           CCC_NUMERO_CUENTA,
           CCC_PER_NUM_IDEN,
           CCC_PER_TID_CODIGO,
           CCC_AGE_CODIGO,
           CCC_FECHA_APERTURA,
           CCC_NOMBRE_CUENTA,
           CCC_DIRECCION,
           CCC_SALDO_CAPITAL,
           CCC_SALDO_A_PLAZO,
           CCC_SALDO_A_CONTADO,
           CCC_SALDO_ADMON_VALORES,
           CCC_CUENTA_ACTIVA,
           CCC_CUENTA_ESPECULATIVA,
           CCC_PERIODO_EXTRACTO,
           CCC_ENVIAR_EXTRACTO,
           CCC_SALDO_CANJE,
           CCC_CONTRATO_OPCF,
           CCC_CUENTA_CRCC,
           CCC_CUENTA_APT,
           CCC_SALDO_CC,
           CCC_ETRADE,
           CCC_CTA_COMPARTIMENTO,
           CCC_SALDO_CANJE_CC,
           CCC_FON_CODIGO,
           CCC_SALDO_BURSATIL,
           CCC_LINEAS_PROFUNDIDAD,
           CCC_PANTALLA_LIVIANA)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --CCC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --CCC_CLI_PER_TID_CODIGO
          ,
           1 --CCC_NUMERO_CUENTA
          ,
           '52068623' --CCC_PER_NUM_IDEN
          ,
           'CC' --CCC_PER_TID_CODIGO
          ,
           LUGAR_OFICINA --CCC_AGE_CODIGO
          ,
           SYSDATE --CCC_FECHA_APERTURA
          ,
           UPPER(TRIM(P_PRIMER_APELLIDO_MAYOR)) || ' ' ||
           UPPER(TRIM(P_SEGUNDO_APELLIDO_MAYOR)) || ' ' ||
           UPPER(TRIM(P_NOMBRES_MAYOR)) --CCC_NOMBRE_CUENTA
          ,
           P_DIRECCION_RESIDENCIA_MAYOR --CCC_DIRECCION
          ,
           0 --CCC_SALDO_CAPITAL
          ,
           0 --CCC_SALDO_A_PLAZO
          ,
           0 --CCC_SALDO_A_CONTADO
          ,
           0 --CCC_SALDO_ADMON_VALORES
          ,
           'N' --CCC_CUENTA_ACTIVA
          ,
           NULL --CCC_CUENTA_ESPECULATIVA
          ,
           'N' --CCC_PERIODO_EXTRACTO
          ,
           'N' --CCC_ENVIAR_EXTRACTO
          ,
           0 --CCC_SALDO_CANJE
          ,
           NULL --CCC_CONTRATO_OPCF
          ,
           NULL --CCC_CUENTA_CRCC
          ,
           'N' --CCC_CUENTA_APT
          ,
           0 --CCC_SALDO_CC
          ,
           NULL --CCC_ETRADE
          ,
           NULL --CCC_CTA_COMPARTIMENTO
          ,
           0 --CCC_SALDO_CANJE_CC
          ,
           NULL --CCC_FON_CODIGO
          ,
           0 --CCC_SALDO_BURSATIL
          ,
           NULL --CCC_LINEAS_PROFUNDIDAD
          ,
           'N' --CCC_PANTALLA_LIVIANA
           );
      END IF;

      CLOSE C_CCC;

      UPDATE PERSONAS
         SET PER_ORIGEN = 'VGO'
       WHERE PER_NUM_IDEN = TRIM(P_NUMERO_2_MAYOR)
         AND PER_TID_CODIGO = TRIM(P_SIGLA_2_MAYOR);

      EXECUTE IMMEDIATE ('ALTER TRIGGER CLI_BIU_TRG DISABLE');

      IF P_DOCUMENTO_ORDENANTE_MAYOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_ORDENAN_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 1 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_ORDENAN_MAYOR);
        END IF;

        IF P_PRIMER_APELLIDO_ORDENA_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 1 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_ORDENA_MAYOR);
        END IF;

        IF P_NOMBRES_ORDENANTE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 1 sin nombre: ' ||
                                  P_NOMBRES_ORDENANTE_MAYOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_ORDENAN_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor Ordenante 1 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_ORDENAN_MAYOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_ORDENANTE_MAYOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_ORDENAN_MAYOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_ORDENAN_MAYOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_ORDENA_MAYOR),
             UPPER(P_SEGUND_APELLIDO_ORDENA_MAYOR),
             UPPER(P_NOMBRES_ORDENANTE_MAYOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_ORDENAN_MAYOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_ORDE_MAYOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_ORDE_MAYOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_ORDE_MAYOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_ORDE_MAYOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_ORDENANTE_MAYOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_ORDENAN_MAYOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           TRIM(P_CELULAR_3_MAYOR) --RLC_CELULAR
          ,
           TRIM(P_CORREO_ELECTRONICO_4_MAYOR) --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_1_ORDENANTE_MAYOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_1_ORDEN_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 2 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_1_ORDEN_MAYOR);
        END IF;

        IF P_PRIMER_APELLIDO_1_ORDE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 2 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_1_ORDE_MAYOR);
        END IF;

        IF P_NOMBRES_1_ORDENANTE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 2 sin nombre: ' ||
                                  P_NOMBRES_1_ORDENANTE_MAYOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_1_ORDEN_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor Ordenante 2 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_1_ORDEN_MAYOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_1_ORDENANTE_MAYOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_1_ORDEN_MAYOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_1_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_1_ORDEN_MAYOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_1_ORDE_MAYOR),
             UPPER(P_SEGUND_APELLIDO_1_ORDE_MAYOR),
             UPPER(P_NOMBRES_1_ORDENANTE_MAYOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_1_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_1_ORDEN_MAYOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_1_ORDE_MAYOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_1_ORDE_MAYOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_1_ORDE_MAYOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_1_ORDE_MAYOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_1_ORDENANTE_MAYOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_1_ORDEN_MAYOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_2_ORDENANTE_MAYOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_2_ORDEN_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 3 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_2_ORDEN_MAYOR);
        END IF;

        IF P_PRIMER_APELLIDO_2_ORDE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 3 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_2_ORDE_MAYOR);
        END IF;

        IF P_NOMBRES_2_ORDENANTE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 3 sin nombre: ' ||
                                  P_NOMBRES_2_ORDENANTE_MAYOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_2_ORDEN_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor Ordenante 3 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_2_ORDEN_MAYOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_2_ORDENANTE_MAYOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_2_ORDEN_MAYOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_2_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_2_ORDEN_MAYOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_2_ORDE_MAYOR),
             UPPER(P_SEGUND_APELLIDO_2_ORDE_MAYOR),
             UPPER(P_NOMBRES_2_ORDENANTE_MAYOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_2_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_2_ORDEN_MAYOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_2_ORDE_MAYOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_2_ORDE_MAYOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_2_ORDE_MAYOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_2_ORDE_MAYOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_2_ORDENANTE_MAYOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_2_ORDEN_MAYOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_3_ORDENANTE_MAYOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_3_ORDEN_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 4 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_3_ORDEN_MAYOR);
        END IF;

        IF P_PRIMER_APELLIDO_3_ORDE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 4 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_3_ORDE_MAYOR);
        END IF;

        IF P_NOMBRES_3_ORDENANTE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 4 sin nombre: ' ||
                                  P_NOMBRES_3_ORDENANTE_MAYOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_3_ORDEN_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor Ordenante 4 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_3_ORDEN_MAYOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_3_ORDENANTE_MAYOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_3_ORDEN_MAYOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_3_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_3_ORDEN_MAYOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_3_ORDE_MAYOR),
             UPPER(P_SEGUND_APELLIDO_3_ORDE_MAYOR),
             UPPER(P_NOMBRES_3_ORDENANTE_MAYOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_3_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_3_ORDEN_MAYOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_3_ORDE_MAYOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_3_ORDE_MAYOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_3_ORDE_MAYOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_3_ORDE_MAYOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_3_ORDENANTE_MAYOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_3_ORDEN_MAYOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_4_ORDENANTE_MAYOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_4_ORDEN_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 5 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_4_ORDEN_MAYOR);
        END IF;

        IF P_PRIMER_APELLIDO_4_ORDE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 5 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_4_ORDE_MAYOR);
        END IF;

        IF P_NOMBRES_4_ORDENANTE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 5 sin nombre: ' ||
                                  P_NOMBRES_4_ORDENANTE_MAYOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_4_ORDEN_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor Ordenante 5 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_4_ORDEN_MAYOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_4_ORDENANTE_MAYOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_4_ORDEN_MAYOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_4_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_4_ORDEN_MAYOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_4_ORDE_MAYOR),
             UPPER(P_SEGUND_APELLIDO_4_ORDE_MAYOR),
             UPPER(P_NOMBRES_4_ORDENANTE_MAYOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_4_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_4_ORDEN_MAYOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_4_ORDE_MAYOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_4_ORDE_MAYOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_4_ORDE_MAYOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_4_ORDE_MAYOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_4_ORDENANTE_MAYOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_4_ORDEN_MAYOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_5_ORDENANTE_MAYOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_5_ORDEN_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 6 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_5_ORDEN_MAYOR);
        END IF;

        IF P_PRIMER_APELLIDO_5_ORDE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 6 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_5_ORDE_MAYOR);
        END IF;

        IF P_NOMBRES_5_ORDENANTE_MAYOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Mayor ordenante 6 sin nombre: ' ||
                                  P_NOMBRES_5_ORDENANTE_MAYOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_5_ORDEN_MAYOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor Ordenante 6 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_5_ORDEN_MAYOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_5_ORDENANTE_MAYOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_5_ORDEN_MAYOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_5_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_5_ORDEN_MAYOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_5_ORDE_MAYOR),
             UPPER(P_SEGUND_APELLIDO_5_ORDE_MAYOR),
             UPPER(P_NOMBRES_5_ORDENANTE_MAYOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_5_ORDENANTE_MAYOR,
             P_TIPO_DOCUMENTO_5_ORDEN_MAYOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_5_ORDE_MAYOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_5_ORDE_MAYOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_5_ORDE_MAYOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_5_ORDE_MAYOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_2_MAYOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(P_SIGLA_2_MAYOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_5_ORDENANTE_MAYOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_5_ORDEN_MAYOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      EXECUTE IMMEDIATE ('ALTER TRIGGER CLI_BIU_TRG ENABLE');

      COMMIT;

    END IF;

    IF PN_MENOR = 'S' THEN

      BEGIN
        IF P_TIPO_SEXO_MENOR = 'Femenino' THEN
          TIPO_SEXO := 'F';
        ELSIF P_TIPO_SEXO_MENOR = 'Masculino' THEN
          TIPO_SEXO := 'M';
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000, 'Persona Menor sin Sexo');

      END;

      BEGIN
        SELECT AGE_CODIGO
          INTO LUGAR_EXPEDICION
          FROM AREAS_GEOGRAFICAS
         WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
               TRIM(P_LUGAR_EXPEDICION_MENOR)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor con ciudad de expedición del documento errado: ' ||
                                  P_LUGAR_EXPEDICION_MENOR);
      END;

      BEGIN
        SELECT PER_NOMBRE_USUARIO
          INTO NOMBRE_USUARIO
          FROM PERSONAS
         WHERE PER_NUM_IDEN = TRIM(P_NUMERO_FUNCIONARIO_MENOR)
           AND PER_TID_CODIGO = TRIM(P_SIGLA_FUNCIONARIO_MENOR);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor con asesor errado y/o no existe en el sistema: ' ||
                                  P_NUMERO_FUNCIONARIO_MENOR || ' - ' ||
                                  P_SIGLA_FUNCIONARIO_MENOR);
      END;

      IF P_TIPO_IDENTIFICACION_MENOR = 'RC' THEN
        TIPO_IDENTIFICAC_MENOR := 'NIP';
      ELSE
        TIPO_IDENTIFICAC_MENOR := P_TIPO_IDENTIFICACION_MENOR;
      END IF;

      FECHA_EXPEDICION_M := SUBSTR(P_FECHA_EXPEDICION_MENOR, 9, 2) || '-' ||
                            SUBSTR(P_FECHA_EXPEDICION_MENOR, 6, 2) || '-' ||
                            SUBSTR(P_FECHA_EXPEDICION_MENOR, 1, 4);

      P_CAB.PR_PERSONAS_RLC_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                    P_CLI_PER_NUM_IDEN      => P_NUMERO_DOCUMENTO_MENOR,
                                    P_CLI_PER_TID_CODIGO    => TIPO_IDENTIFICAC_MENOR,
                                    P_FECHA_APERTURA        => SYSDATE,
                                    P_ESTADO                => 'POR_PROCESAR',
                                    P_PER_NUM_IDEN          => P_NUMERO_FUNCIONARIO_MENOR,
                                    P_PER_TID_CODIGO        => P_SIGLA_FUNCIONARIO_MENOR,
                                    P_PRIMER_APELLIDO       => P_PRIMER_APELLIDO_MENOR,
                                    P_SEGUNDO_APELLIDO      => P_SEGUNDO_APELLIDO_MENOR,
                                    P_NOMBRE                => P_NOMBRES_MENOR,
                                    P_TIPO_SEXO             => TIPO_SEXO,
                                    P_ROL_ORDENANTE         => 1,
                                    P_CARGO                 => P_CARGO_MENOR,
                                    P_CELULAR               => P_TELEFONO_CELULAR_MENOR,
                                    P_TELEFONO              => P_TELEFONO_CELULAR_MENOR,
                                    P_DIRECCION_OFICINA     => NULL,
                                    P_CIUDAD_OFICINA        => NULL,
                                    P_FECHA_EXP_DOCUMENTO   => FECHA_EXPEDICION_M,
                                    P_CIUDAD_EXP_DOCUMENTO  => LUGAR_EXPEDICION,
                                    P_CALIDAD               => 'OR',
                                    P_PARENTESCO            => 37,
                                    P_DIRECCION_EMAIL       => P_CORREO_ELECTRONICO_MENOR,
                                    P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                    P_CLOB                  => V_CLOB1);

      IF P_TIENE_CUEN_ENTID_BANCA_MENOR = 'Si' THEN

        -- PRIMERA CUENTA BANCARIA

        IF P_ENTIDAD_BANCARIA_MENOR IS NOT NULL AND
           P_TIPO_CUENTA_BANCARIA_MENOR IS NOT NULL THEN

          BEGIN
            SELECT BAN_CODIGO
              INTO ENTIDAD_BANCARIA
              FROM BANCOS
             WHERE BAN_NOMBRE = TRIM(P_ENTIDAD_BANCARIA_MENOR)
               AND BAN_ESTADO = 'A';
          EXCEPTION
            WHEN OTHERS THEN
              ENTIDAD_BANCARIA := NULL;
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Menor con entidad bancaria 1 errada: ' ||
                                      P_ENTIDAD_BANCARIA_MENOR);
          END;

          IF TRIM(P_TIPO_CUENTA_BANCARIA_MENOR) = 'Ahorros' OR
             TRIM(P_TIPO_CUENTA_BANCARIA_MENOR) = 'Ahorro' THEN
            TIPO_CUENTA_BANCARIA := 'CAH';
          ELSIF TRIM(P_TIPO_CUENTA_BANCARIA_MENOR) = 'Corriente' THEN
            TIPO_CUENTA_BANCARIA := 'CCO';
          ELSE
            TIPO_CUENTA_BANCARIA := NULL;
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor con tipo de cuenta bancaria 1 errada: ' ||
                                    P_TIPO_CUENTA_BANCARIA_MENOR);
          END IF;

          IF ENTIDAD_BANCARIA IS NOT NULL AND
             TIPO_CUENTA_BANCARIA IS NOT NULL THEN

            P_CAB.PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                         P_CLI_PER_NUM_IDEN      => P_NUMERO_DOCUMENTO_MENOR,
                                         P_CLI_PER_TID_CODIGO    => TIPO_IDENTIFICAC_MENOR,
                                         P_FECHA_APERTURA        => SYSDATE,
                                         P_ESTADO                => 'POR_PROCESAR',
                                         P_BANCO                 => ENTIDAD_BANCARIA,
                                         P_NUMERO_CUENTA         => P_NUMERO_CUENTA_BANCARIA_MENOR,
                                         P_TIPO                  => TIPO_CUENTA_BANCARIA,
                                         P_SUCURSAL              => NULL,
                                         P_DIRECCION             => NULL,
                                         P_TELEFONO              => NULL,
                                         P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                         P_CLOB                  => V_CLOB2);

          END IF;

        END IF;

        -- SEGUNDA CUENTA BANCARIA

        IF P_ENTIDAD_BANCARIA_2_MENOR IS NOT NULL AND
           P_TIPO_CUENTA_BANCARIA_2_MENOR IS NOT NULL THEN

          ENTIDAD_BANCARIA     := NULL;
          TIPO_CUENTA_BANCARIA := NULL;

          BEGIN
            SELECT BAN_CODIGO
              INTO ENTIDAD_BANCARIA
              FROM BANCOS
             WHERE BAN_NOMBRE = TRIM(P_ENTIDAD_BANCARIA_2_MENOR)
               AND BAN_ESTADO = 'A';
          EXCEPTION
            WHEN OTHERS THEN
              ENTIDAD_BANCARIA := NULL;
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Menor con entidad bancaria 2 errada: ' ||
                                      P_ENTIDAD_BANCARIA_2_MENOR);
          END;

          IF TRIM(P_TIPO_CUENTA_BANCARIA_2_MENOR) = 'Ahorros' OR
             TRIM(P_TIPO_CUENTA_BANCARIA_2_MENOR) = 'Ahorro' THEN
            TIPO_CUENTA_BANCARIA := 'CAH';
          ELSIF TRIM(P_TIPO_CUENTA_BANCARIA_2_MENOR) = 'Corriente' THEN
            TIPO_CUENTA_BANCARIA := 'CCO';
          ELSE
            TIPO_CUENTA_BANCARIA := NULL;
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor con tipo de cuenta bancaria 2 errada: ' ||
                                    P_TIPO_CUENTA_BANCARIA_2_MENOR);
          END IF;

          IF ENTIDAD_BANCARIA IS NOT NULL AND
             TIPO_CUENTA_BANCARIA IS NOT NULL THEN

            P_CAB.PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                         P_CLI_PER_NUM_IDEN      => P_NUMERO_DOCUMENTO_MENOR,
                                         P_CLI_PER_TID_CODIGO    => TIPO_IDENTIFICAC_MENOR,
                                         P_FECHA_APERTURA        => SYSDATE,
                                         P_ESTADO                => 'POR_PROCESAR',
                                         P_BANCO                 => ENTIDAD_BANCARIA,
                                         P_NUMERO_CUENTA         => P_NUMERO_CUENTA_BANCAR_2_MENOR,
                                         P_TIPO                  => TIPO_CUENTA_BANCARIA,
                                         P_SUCURSAL              => NULL,
                                         P_DIRECCION             => NULL,
                                         P_TELEFONO              => NULL,
                                         P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                         P_CLOB                  => V_CLOB2);

          END IF;

        END IF;

        -- TERCERA CUENTA BANCARIA

        IF P_ENTIDAD_BANCARIA_3_MENOR IS NOT NULL AND
           P_TIPO_CUENTA_BANCARIA_3_MENOR IS NOT NULL THEN

          ENTIDAD_BANCARIA     := NULL;
          TIPO_CUENTA_BANCARIA := NULL;

          BEGIN
            SELECT BAN_CODIGO
              INTO ENTIDAD_BANCARIA
              FROM BANCOS
             WHERE BAN_NOMBRE = TRIM(P_ENTIDAD_BANCARIA_3_MENOR)
               AND BAN_ESTADO = 'A';
          EXCEPTION
            WHEN OTHERS THEN
              ENTIDAD_BANCARIA := NULL;
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Menor con entidad bancaria 3 errada: ' ||
                                      P_ENTIDAD_BANCARIA_3_MENOR);
          END;

          IF TRIM(P_TIPO_CUENTA_BANCARIA_3_MENOR) = 'Ahorros' OR
             TRIM(P_TIPO_CUENTA_BANCARIA_3_MENOR) = 'Ahorro' THEN
            TIPO_CUENTA_BANCARIA := 'CAH';
          ELSIF TRIM(P_TIPO_CUENTA_BANCARIA_3_MENOR) = 'Corriente' THEN
            TIPO_CUENTA_BANCARIA := 'CCO';
          ELSE
            TIPO_CUENTA_BANCARIA := NULL;
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor con tipo de cuenta bancaria 3 errada: ' ||
                                    P_TIPO_CUENTA_BANCARIA_3_MENOR);
          END IF;

          IF ENTIDAD_BANCARIA IS NOT NULL AND
             TIPO_CUENTA_BANCARIA IS NOT NULL THEN

            P_CAB.PR_CUENTAS_BAN_VINCULA(P_NUMERO_FORMULARIO     => NUMERO_FORMULARIO,
                                         P_CLI_PER_NUM_IDEN      => P_NUMERO_DOCUMENTO_MENOR,
                                         P_CLI_PER_TID_CODIGO    => TIPO_IDENTIFICAC_MENOR,
                                         P_FECHA_APERTURA        => SYSDATE,
                                         P_ESTADO                => 'POR_PROCESAR',
                                         P_BANCO                 => ENTIDAD_BANCARIA,
                                         P_NUMERO_CUENTA         => P_NUMERO_CUENTA_BANCAR_3_MENOR,
                                         P_TIPO                  => TIPO_CUENTA_BANCARIA,
                                         P_SUCURSAL              => NULL,
                                         P_DIRECCION             => NULL,
                                         P_TELEFONO              => NULL,
                                         P_NUMERO_FORMULARIO_VIN => FORMULARIO_VIN,
                                         P_CLOB                  => V_CLOB2);

          END IF;

        END IF;

      END IF;

      BEGIN
        SELECT PAI_CODIGO
          INTO PAIS
          FROM PAISES
         WHERE PAI_NOMBRE = TRIM(P_NACIONALIDAD_MENOR);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor con Pais errado: ' ||
                                  P_NACIONALIDAD_MENOR);
      END;

      IF PAIS != 'COL' THEN
        NACIONALIDAD := 'ERE';
      ELSE
        NACIONALIDAD := 'COM';
      END IF;

      IF NACIONALIDAD NOT IN ('COL', 'COM') THEN
        EXTRANJERA := 'S';
      ELSE
        EXTRANJERA := 'N';
      END IF;

      BEGIN
        SELECT AGE_CODIGO
          INTO LUGAR_NACIMIENTO
          FROM AREAS_GEOGRAFICAS
         WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
               TRIM(P_LUGAR_NACIMIENTO_MENOR)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor con lugar de nacimiento errado: ' ||
                                  P_LUGAR_NACIMIENTO_MENOR);
      END;

      PROFESION := 'N000';

      IF P_PEP_NAC_O_EXT_MENOR = 'Si' THEN
        IMPACTADO_POR_PEP      := 'S';
        EXPUESTO_POLITICAMENTE := 'S';
      ELSE
        IMPACTADO_POR_PEP      := 'N';
        EXPUESTO_POLITICAMENTE := 'N';
      END IF;

      IF P_DIRE_SUBDIR_JUNT_DIREC_MENOR IS NOT NULL THEN

        IF P_DIRE_SUBDIR_JUNT_DIREC_MENOR = 'Si' THEN
          RECONO_POLITICA_PEP := 'N';
          REP_LEGAL_PEP       := 'S';
        ELSE
          IF P_EXPUESTO_POLITICAMENTE_MENOR = 'Si' OR
             P_CARGO_POLITI_OTRO_PAIS_MENOR = 'Si' THEN
            RECONO_POLITICA_PEP := 'S';
            REP_LEGAL_PEP       := 'N';
          ELSE
            RECONO_POLITICA_PEP := 'N';
            REP_LEGAL_PEP       := 'N';
          END IF;
        END IF;

      END IF;

      IF P_DECLARA_RENTA_MENOR = 'No' THEN
        DECLARA_RENTA := 'N';
      ELSIF P_DECLARA_RENTA_MENOR = 'Si' THEN
        DECLARA_RENTA := 'S';
      ELSE
        DECLARA_RENTA := 'N';
      END IF;

      BEGIN
        SELECT AGE_CODIGO
          INTO LUGAR_RESIDENCIA
          FROM AREAS_GEOGRAFICAS
         WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
               TRIM(P_LUGAR_RESIDENCIA_MENOR)
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor con ciudad de residencia errada: ' ||
                                  P_LUGAR_RESIDENCIA_MENOR);
      END;

      IF P_IMPACTADO_FATCA_2_MENOR = 'No' THEN
        IMPACTADO_POR_FATCA := 'N';
      ELSIF P_IMPACTADO_FATCA_2_MENOR = 'Si' THEN
        IMPACTADO_POR_FATCA := 'S';
      ELSE
        IMPACTADO_POR_FATCA := 'N';
      END IF;

      IF P_RESIDEN_FISC_OTRO_PAIS_MENOR = 'No' THEN
        IMPACTADO_POR_CRS := 'N';
      ELSIF P_RESIDEN_FISC_OTRO_PAIS_MENOR = 'Si' THEN
        IMPACTADO_POR_CRS := 'S';
      ELSE
        IMPACTADO_POR_CRS := 'N';
      END IF;

      IF P_CARGO_POLITI_OTRO_PAIS_MENOR = 'No' THEN
        CARGO_POLITI_OTRO_PAIS := 'N';
      ELSIF P_CARGO_POLITI_OTRO_PAIS_MENOR = 'Si' THEN
        CARGO_POLITI_OTRO_PAIS := 'S';
      ELSE
        CARGO_POLITI_OTRO_PAIS := 'N';
      END IF;

      EXP_SECTOR_PUBLICO := 'N';

      IF P_PERFIL_MENOR IS NULL THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Menor sin perfil de riesgo: ' ||
                                P_PERFIL_MENOR);
      END IF;

      BEGIN
        SELECT 'X'
          INTO EXISTE
          FROM CIIUS_NUEVOS
         WHERE CNU_MNEMONICO = P_CODIGO_CIIU_MENOR;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor con código CIIU errado o inexistente: ' ||
                                  P_CODIGO_CIIU_MENOR);
      END;

      IF EXISTE != 'X' THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Menor con código CIIU errado o inexistente: ' ||
                                P_CODIGO_CIIU_MENOR);
      END IF;

      IF P_TIPO_MONEDA_INVERSION_MENOR IS NOT NULL THEN

        IF NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR), ','), 0) = 0 THEN

          IF TRIM(P_TIPO_MONEDA_INVERSION_MENOR) = 'Pesos' THEN
            PROPOSITO_RELACION := 1;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MENOR) = 'Dólares' THEN
            PROPOSITO_RELACION := 2;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MENOR) =
                'Compra y venta de divisas con fines diferentes a inversión' THEN
            PROPOSITO_RELACION := 3;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MENOR) =
                'Transaccional (Descuento de títulos)' THEN
            PROPOSITO_RELACION := 4;
          ELSIF TRIM(P_TIPO_MONEDA_INVERSION_MENOR) = 'Otro' THEN
            PROPOSITO_RELACION := 5;
          ELSE
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                    P_TIPO_MONEDA_INVERSION_MENOR);
          END IF;

        ELSE

          IF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                    1,
                    NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR), ','), 0) - 1) =
             'Pesos' THEN
            PROPOSITO_RELACION := 1;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR), ','),
                           0) - 1) = 'Dólares' THEN
            PROPOSITO_RELACION := 2;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR), ','),
                           0) - 1) =
                'Compra y venta de divisas con fines diferentes a inversión' THEN
            PROPOSITO_RELACION := 3;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR), ','),
                           0) - 1) = 'Transaccional (Descuento de títulos)' THEN
            PROPOSITO_RELACION := 4;
          ELSIF SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                       1,
                       NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR), ','),
                           0) - 1) = 'Otro' THEN
            PROPOSITO_RELACION := 5;
          ELSE
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                    P_TIPO_MONEDA_INVERSION_MENOR);
          END IF;

          TIPO_PROPOSI_RELACION := SUBSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                                          NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                                                    ','),
                                              0) + 1,
                                          LENGTH(P_TIPO_MONEDA_INVERSION_MENOR) -
                                          NVL(INSTR(TRIM(P_TIPO_MONEDA_INVERSION_MENOR),
                                                    ','),
                                              0));

          IF NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) = 0 THEN

            IF TRIM(TIPO_PROPOSI_RELACION) = 'Pesos' THEN
              PROPOSITO_RELACION1 := 1;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) = 'Dólares' THEN
              PROPOSITO_RELACION1 := 2;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) =
                  'Compra y venta de divisas con fines diferentes a inversión' THEN
              PROPOSITO_RELACION1 := 3;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) =
                  'Transaccional (Descuento de títulos)' THEN
              PROPOSITO_RELACION1 := 4;
            ELSIF TRIM(TIPO_PROPOSI_RELACION) = 'Otro' THEN
              PROPOSITO_RELACION1 := 5;
            ELSE
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                      P_TIPO_MONEDA_INVERSION_MENOR);
            END IF;

          ELSE

            IF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                      1,
                      NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
               'Pesos' THEN
              PROPOSITO_RELACION1 := 1;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Dólares' THEN
              PROPOSITO_RELACION1 := 2;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Compra y venta de divisas con fines diferentes a inversión' THEN
              PROPOSITO_RELACION1 := 3;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Transaccional (Descuento de títulos)' THEN
              PROPOSITO_RELACION1 := 4;
            ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                         1,
                         NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION), ','), 0) - 1) =
                  'Otro' THEN
              PROPOSITO_RELACION1 := 5;
            ELSE
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                      P_TIPO_MONEDA_INVERSION_MENOR);
            END IF;

            TIPO_PROPOSI_RELACION1 := SUBSTR(TRIM(TIPO_PROPOSI_RELACION),
                                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION),
                                                       ','),
                                                 0) + 1,
                                             LENGTH(TIPO_PROPOSI_RELACION) -
                                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION),
                                                       ','),
                                                 0));

            IF NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) = 0 THEN

              IF TRIM(TIPO_PROPOSI_RELACION1) = 'Pesos' THEN
                PROPOSITO_RELACION2 := 1;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) = 'Dólares' THEN
                PROPOSITO_RELACION2 := 2;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) =
                    'Compra y venta de divisas con fines diferentes a inversión' THEN
                PROPOSITO_RELACION2 := 3;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) =
                    'Transaccional (Descuento de títulos)' THEN
                PROPOSITO_RELACION2 := 4;
              ELSIF TRIM(TIPO_PROPOSI_RELACION1) = 'Otro' THEN
                PROPOSITO_RELACION2 := 5;
              ELSE
                RAISE_APPLICATION_ERROR(-20000,
                                        'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                        P_TIPO_MONEDA_INVERSION_MENOR);
              END IF;

            ELSE

              IF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                        1,
                        NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                 'Pesos' THEN
                PROPOSITO_RELACION2 := 1;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Dólares' THEN
                PROPOSITO_RELACION2 := 2;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Compra y venta de divisas con fines diferentes a inversión' THEN
                PROPOSITO_RELACION2 := 3;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Transaccional (Descuento de títulos)' THEN
                PROPOSITO_RELACION2 := 4;
              ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                           1,
                           NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1), ','), 0) - 1) =
                    'Otro' THEN
                PROPOSITO_RELACION2 := 5;
              ELSE
                RAISE_APPLICATION_ERROR(-20000,
                                        'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                        P_TIPO_MONEDA_INVERSION_MENOR);
              END IF;

              TIPO_PROPOSI_RELACION2 := SUBSTR(TRIM(TIPO_PROPOSI_RELACION1),
                                               NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1),
                                                         ','),
                                                   0) + 1,
                                               LENGTH(TIPO_PROPOSI_RELACION1) -
                                               NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION1),
                                                         ','),
                                                   0));

              IF NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) = 0 THEN

                IF TRIM(TIPO_PROPOSI_RELACION2) = 'Pesos' THEN
                  PROPOSITO_RELACION3 := 1;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) = 'Dólares' THEN
                  PROPOSITO_RELACION3 := 2;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) =
                      'Compra y venta de divisas con fines diferentes a inversión' THEN
                  PROPOSITO_RELACION3 := 3;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) =
                      'Transaccional (Descuento de títulos)' THEN
                  PROPOSITO_RELACION3 := 4;
                ELSIF TRIM(TIPO_PROPOSI_RELACION2) = 'Otro' THEN
                  PROPOSITO_RELACION3 := 5;
                ELSE
                  RAISE_APPLICATION_ERROR(-20000,
                                          'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                          P_TIPO_MONEDA_INVERSION_MENOR);
                END IF;

              ELSE

                IF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                          1,
                          NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                   'Pesos' THEN
                  PROPOSITO_RELACION3 := 1;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Dólares' THEN
                  PROPOSITO_RELACION3 := 2;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Compra y venta de divisas con fines diferentes a inversión' THEN
                  PROPOSITO_RELACION3 := 3;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Transaccional (Descuento de títulos)' THEN
                  PROPOSITO_RELACION3 := 4;
                ELSIF SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                             1,
                             NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2), ','), 0) - 1) =
                      'Otro' THEN
                  PROPOSITO_RELACION3 := 5;
                ELSE
                  RAISE_APPLICATION_ERROR(-20000,
                                          'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                          P_TIPO_MONEDA_INVERSION_MENOR);
                END IF;

                TIPO_PROPOSI_RELACION3 := SUBSTR(TRIM(TIPO_PROPOSI_RELACION2),
                                                 NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2),
                                                           ','),
                                                     0) + 1,
                                                 LENGTH(TIPO_PROPOSI_RELACION2) -
                                                 NVL(INSTR(TRIM(TIPO_PROPOSI_RELACION2),
                                                           ','),
                                                     0));

                IF TRIM(TIPO_PROPOSI_RELACION3) = 'Pesos' THEN
                  PROPOSITO_RELACION4 := 1;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) = 'Dólares' THEN
                  PROPOSITO_RELACION4 := 2;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) =
                      'Compra y venta de divisas con fines diferentes a inversión' THEN
                  PROPOSITO_RELACION4 := 3;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) =
                      'Transaccional (Descuento de títulos)' THEN
                  PROPOSITO_RELACION4 := 4;
                ELSIF TRIM(TIPO_PROPOSI_RELACION3) = 'Otro' THEN
                  PROPOSITO_RELACION4 := 5;
                ELSE
                  RAISE_APPLICATION_ERROR(-20000,
                                          'Persona Mayor con propósito de inversión errado o inexistente: ' ||
                                          P_TIPO_MONEDA_INVERSION_MENOR);
                END IF;

              END IF;

            END IF;

          END IF;

        END IF;

      ELSE
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Menor con propósito de inversión errado o inexistente: ' ||
                                P_TIPO_MONEDA_INVERSION_MENOR);
      END IF;

      IF P_ES_CONY_COMP_PERM_PEP_MENOR = 'Si' THEN
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Abuelo(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'ABC';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Yerno(Nuera)' THEN
          GRADO_CONSANGUINIDAD := 'YEN';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Abuelo(a)' THEN
          GRADO_CONSANGUINIDAD := 'ABU';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Cuñado(a)' THEN
          GRADO_CONSANGUINIDAD := 'CUN';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) =
           'Conyugue / Compañero(a) Permanente' THEN
          GRADO_CONSANGUINIDAD := 'COP';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Conyugue' THEN
          GRADO_CONSANGUINIDAD := 'COP';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'COP';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Nieto(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'NIC';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Nieto(a)' THEN
          GRADO_CONSANGUINIDAD := 'NIE';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Hermano(a)' THEN
          GRADO_CONSANGUINIDAD := 'HER';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Hermano(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'HCO';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Hijo(a) Conyuge' THEN
          GRADO_CONSANGUINIDAD := 'HIC';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Hijo(a)' THEN
          GRADO_CONSANGUINIDAD := 'HIJ';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Suegro(a)' THEN
          GRADO_CONSANGUINIDAD := 'SUE';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Padre/Madre' THEN
          GRADO_CONSANGUINIDAD := 'PAD';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Padre' THEN
          GRADO_CONSANGUINIDAD := 'PAD';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) = 'Madre' THEN
          GRADO_CONSANGUINIDAD := 'PAD';
        END IF;
        IF TRIM(P_GRADO_CONSANGUINIDAD_MENOR) IS NULL OR
           TRIM(P_GRADO_CONSANGUINIDAD_MENOR) NOT IN
           ('Abuelo(a) Conyuge',
            'Yerno(Nuera)',
            'Abuelo(a)',
            'Cuñado(a)',
            'Conyugue / Compañero(a) Permanente',
            'Conyugue',
            'Conyuge',
            'Nieto(a) Conyuge',
            'Nieto(a)',
            'Hermano(a)',
            'Hermano(a) Conyuge',
            'Hijo(a) Conyuge',
            'Hijo(a)',
            'Suegro(a)',
            'Padre/Madre',
            'Padre',
            'Madre') THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor Expuesta Políticamente sin grado de consaguinidad y/o consaguinidad errada: ' ||
                                  P_GRADO_CONSANGUINIDAD_MENOR);
        END IF;
      END IF;

      IF P_NUMERO_TIN_OTRO_PAI_MENOR IS NOT NULL THEN

        IF TRIM(P_PAIS_RES_FISC_OTRO_PAI_MENOR) = 'SUDAFRICA' THEN
          RES_FISC_OTRO_PAI1 := 'ZAF';
        ELSE
          BEGIN
            SELECT PAI_CODIGO
              INTO RES_FISC_OTRO_PAI1
              FROM PAISES
             WHERE PAI_NOMBRE = TRIM(P_PAIS_RES_FISC_OTRO_PAI_MENOR);
          EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Menor con Residencia Fiscal 1 en otro Pais errada: ' ||
                                      P_PAIS_RES_FISC_OTRO_PAI_MENOR);
          END;
        END IF;

      END IF;

      IF P_NUMERO_TIN_OTRO_PAI_2_MENOR IS NOT NULL THEN

        IF TRIM(P_PAIS_RES_FIS_OTR_PAI_2_MENOR) = 'SUDAFRICA' THEN
          RES_FISC_OTRO_PAI2 := 'ZAF';
        ELSE
          BEGIN
            SELECT PAI_CODIGO
              INTO RES_FISC_OTRO_PAI2
              FROM PAISES
             WHERE PAI_NOMBRE = TRIM(P_PAIS_RES_FIS_OTR_PAI_2_MENOR);
          EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20000,
                                      'Persona Menor con Residencia Fiscal 2 en otro Pais errada: ' ||
                                      P_PAIS_RES_FIS_OTR_PAI_2_MENOR);
          END;
        END IF;

      END IF;

      IF TRIM(P_ENVIO_CORRESPONDENCIA_MENOR) =
         'Recibirlo en fisico en la oficina' THEN
        CORRESPONDENCIA := 'OFI';
      END IF;
      IF TRIM(P_ENVIO_CORRESPONDENCIA_MENOR) =
         'Recibirlo en fisico en la residencia' THEN
        CORRESPONDENCIA := 'RES';
      END IF;
      IF TRIM(P_ENVIO_CORRESPONDENCIA_MENOR) =
         'Consultarlo en la zona transaccional (Internet)' THEN
        CORRESPONDENCIA := 'INT';
      END IF;
      IF TRIM(P_ENVIO_CORRESPONDENCIA_MENOR) =
         'Recibirlo al correo electrónico' THEN
        CORRESPONDENCIA := 'CEL';
      END IF;
      IF P_ENVIO_CORRESPONDENCIA_MENOR IS NULL OR
         TRIM(P_ENVIO_CORRESPONDENCIA_MENOR) NOT IN
         ('Recibirlo en fisico en la residencia',
          'Recibirlo en fisico en la oficina',
          'Consultarlo en la zona transaccional (Internet)',
          'Recibirlo al correo electrónico') THEN
        RAISE_APPLICATION_ERROR(-20000,
                                'Persona Menor sin tipo de envío de correspondencia');
      END IF;

      ------------------------------------------------------------------------------------------------------------
      P_CAB.PR_DATOS_CLIENTE_VINCULA(P_TIPO_CLIENTE               => 'PNA',
                                     P_NOMBRES                    => P_NOMBRES_MENOR,
                                     P_PRIMER_APELLIDO            => P_PRIMER_APELLIDO_MENOR,
                                     P_SEGUNDO_APELLIDO           => P_SEGUNDO_APELLIDO_MENOR,
                                     P_TIPO_IDENTIFICACION        => TIPO_IDENTIFICAC_MENOR,
                                     P_NUMERO_IDENTIFICACION      => P_NUMERO_DOCUMENTO_MENOR,
                                     P_FECHA_EXP_DOCUMENTO        => TO_CHAR(TRUNC(TO_DATE(P_FECHA_EXPEDICION_MENOR,
                                                                                           'YYYY-MM-DD')),
                                                                             'DD-MM-YYYY'),
                                     P_CIUDAD_EXP_DOCUMENTO       => LUGAR_EXPEDICION,
                                     P_TIPOSEXO                   => TIPO_SEXO,
                                     P_RAZONSOCIAL                => NULL,
                                     P_CIUDAD_EMPRESA             => NULL,
                                     P_EXTRANJERA                 => EXTRANJERA,
                                     P_NACIONALIDAD               => NACIONALIDAD,
                                     P_CODIGO_ESTADO_CIVIL        => 'SOL',
                                     P_CIUDAD_NACIMIENTO          => LUGAR_NACIMIENTO,
                                     P_FECHA_NACIMIENTO           => TO_CHAR(TRUNC(TO_DATE(P_FECHA_NACIMIENTO_MENOR,
                                                                                           'YYYY-MM-DD')),
                                                                             'DD-MM-YYYY'),
                                     P_DIRECCION_EMAIL            => P_CORREO_ELECTRONICO_MENOR,
                                     P_REFERENCIADO               => NULL,
                                     P_PROFESION                  => PROFESION,
                                     P_NOMBRE_EMPRESA             => NULL,
                                     P_CARGO_EMPLEADO             => NULL,
                                     P_ACTIVIDAD_CLIENTE          => 'EST',
                                     P_ORIGEN_RECURSOS            => 'AHO',
                                     P_OTRO_ORIGEN_RECURSOS       => NULL,
                                     P_RECURSOS_ENTREGAR          => 'Dinero',
                                     P_OTRO_RECURSO_ENTREGA       => NULL,
                                     P_CODIGOCIIU                 => P_CODIGO_CIIU_MENOR,
                                     P_ACT_ECONOMICA_PPAL         => NULL,
                                     P_EXP_SECTOR_PUBLICO         => EXP_SECTOR_PUBLICO,
                                     P_TIPO_EMPRESA               => 2,
                                     P_CLASIFICACION_ENTIDAD      => 99,
                                     P_GRAN_CONTRIBUYENTE         => NULL,
                                     P_DECLARANTE                 => NULL,
                                     P_SUJETO_RETEFUENTE          => NULL,
                                     P_FECHA_CREACION_EMPRESA     => NULL,
                                     P_CAMPANA_POLITICA           => NULL,
                                     P_CLASE_SOCIEDAD             => NULL,
                                     P_DIRECCION_RESIDENCIA       => P_DIRECCION_RESIDENCIA_MENOR,
                                     P_CIUDAD_RESIDENCIA          => LUGAR_RESIDENCIA,
                                     P_TELEFONO_RESIDENCIA        => P_TELEFONO_CELULAR_MENOR,
                                     P_DIRECCION_OFICINA          => NULL,
                                     P_CIUDAD_OFICINA             => NULL,
                                     P_TELEFONO_OFICINA           => NULL,
                                     P_APARTADO_AEREO             => NULL,
                                     P_FAX                        => NULL,
                                     P_TIPO_CORRESPONDENCIA       => CORRESPONDENCIA,
                                     P_CELULAR                    => P_TELEFONO_CELULAR_MENOR,
                                     P_PERFIL_RIESGO              => P_PERFIL_MENOR,
                                     P_ING_MEN_OPERACIONALES      => 0,
                                     P_EGR_MEN_OPERACIONALES      => 0,
                                     P_EGR_MEN_NO_OPERACIONA      => NULL,
                                     P_ING_MEN_NO_OPERACIONA      => 0,
                                     P_ACTIVOS                    => 0,
                                     P_PASIVOS                    => 0,
                                     P_PATRIMONIO                 => 0,
                                     P_CONTRATO_COMISION          => P_CONTRATO_COMISION,
                                     P_CONTRATO_DCVAL             => TO_NUMBER(SUBSTR(P_CONTRATO_DECEVAL,
                                                                                      4,
                                                                                      (LENGTH(P_CONTRATO_DECEVAL) - 3))),
                                     P_CATEGORIA_CONTRAPARTE      => NULL,
                                     P_NUMERO_FORMULARIO_VIN      => FORMULARIO_VIN,
                                     P_TIPO_IDE_COMERCIAL         => P_SIGLA_FUNCIONARIO_MENOR,
                                     P_NUM_IDEN_COMERCIAL         => P_NUMERO_FUNCIONARIO_MENOR,
                                     P_COD_USUARIO_COMERCIAL      => NOMBRE_USUARIO,
                                     P_ORIGEN_OPERACION           => NULL,
                                     P_CATEGORIZACION_CLIENTE     => 'N',
                                     P_RECONO_PUBLICA_PEP         => IMPACTADO_POR_PEP,
                                     P_RECONOCIMIENTO_PUBLICO     => EXPUESTO_POLITICAMENTE,
                                     P_CARGO_PEP                  => P_CARGO_MENOR,
                                     P_RECONO_POLITICA_PEP        => RECONO_POLITICA_PEP,
                                     P_FECHA_CARGO_PEP            => NULL,
                                     P_FECHA_DESVINCULA_PEP       => NULL,
                                     P_REP_LEGAL_PEP              => REP_LEGAL_PEP,
                                     P_GRADO_CONSANGUI_PEP        => GRADO_CONSANGUINIDAD,
                                     P_NOMBRE_FAMILIAR_PEP        => P_NOMBRES_4_MENOR,
                                     P_PRIMER_APELLIDO_PEP        => P_APELLIDOS_MENOR,
                                     P_SEGUNDO_APELLIDO_PEP       => P_APELLIDOS_2_MENOR,
                                     P_IMPACTADO_FATCA_FN         => IMPACTADO_POR_FATCA,
                                     P_IMPACTADO_CRS_FN           => IMPACTADO_POR_CRS,
                                     P_TIN_FN                     => P_NUMERO_TIN_MENOR,
                                     P_PAI_FISCAL1_FN             => RES_FISC_OTRO_PAI1,
                                     P_PAI_FISCAL2_FN             => RES_FISC_OTRO_PAI2,
                                     P_TIN_CRS1_FN                => P_NUMERO_TIN_OTRO_PAI_MENOR,
                                     P_TIN_CRS2_FN                => P_NUMERO_TIN_OTRO_PAI_2_MENOR,
                                     P_PAI_NACIMIENTO_FN          => PAIS,
                                     P_AGE_CODIGO_RESIDE_FN       => LUGAR_RESIDENCIA,
                                     P_ESTADO_VINCULACION_DIGITAL => 'N',
                                     P_USUARIO_APERTURA           => USER,
                                     P_FORMULARIO_APERTURA        => V_FORMULARIO_APERTURA,
                                     P_CLOB                       => V_CLOB3);

      IF PROPOSITO_RELACION = 5 THEN
        RIC_OTRO := 'OTRO';
      ELSE
        RIC_OTRO := NULL;
      END IF;

      DELETE FROM PERSONAS_RELACIONADAS
       WHERE RLC_PER_NUM_IDEN = P_NUMERO_FUNCIONARIO_MENOR
         AND RLC_PER_TID_CODIGO = P_SIGLA_FUNCIONARIO_MENOR
         AND RLC_CLI_PER_NUM_IDEN = P_NUMERO_DOCUMENTO_MENOR
         AND RLC_CLI_PER_TID_CODIGO = TIPO_IDENTIFICAC_MENOR;

      INSERT INTO CLIENTE_PROPOSITO_RELACION
        (CRI_CLI_PER_NUM_IDEN,
         CRI_CLI_PER_TID_CODIGO,
         CRI_RIC_CONSECUTIVO,
         CRI_RIC_OTRO)
      VALUES
        (P_NUMERO_DOCUMENTO_MENOR,
         TIPO_IDENTIFICAC_MENOR,
         NVL(PROPOSITO_RELACION, 5),
         RIC_OTRO);

      IF PROPOSITO_RELACION1 IS NOT NULL THEN

        IF PROPOSITO_RELACION1 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_DOCUMENTO_MENOR,
           TIPO_IDENTIFICAC_MENOR,
           NVL(PROPOSITO_RELACION1, 5),
           RIC_OTRO);

      END IF;

      IF PROPOSITO_RELACION2 IS NOT NULL THEN

        IF PROPOSITO_RELACION2 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_DOCUMENTO_MENOR,
           TIPO_IDENTIFICAC_MENOR,
           NVL(PROPOSITO_RELACION2, 5),
           RIC_OTRO);

      END IF;

      IF PROPOSITO_RELACION3 IS NOT NULL THEN

        IF PROPOSITO_RELACION3 = 5 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_DOCUMENTO_MENOR,
           TIPO_IDENTIFICAC_MENOR,
           NVL(PROPOSITO_RELACION3, 5),
           RIC_OTRO);

      END IF;

      IF PROPOSITO_RELACION4 IS NOT NULL THEN

        IF PROPOSITO_RELACION1 = 4 THEN
          RIC_OTRO := 'OTRO';
        ELSE
          RIC_OTRO := NULL;
        END IF;

        INSERT INTO CLIENTE_PROPOSITO_RELACION
          (CRI_CLI_PER_NUM_IDEN,
           CRI_CLI_PER_TID_CODIGO,
           CRI_RIC_CONSECUTIVO,
           CRI_RIC_OTRO)
        VALUES
          (P_NUMERO_DOCUMENTO_MENOR,
           TIPO_IDENTIFICAC_MENOR,
           NVL(PROPOSITO_RELACION4, 5),
           RIC_OTRO);

      END IF;

      IF P_COMPART_INFORMAC_GRUPO_MENOR = 'Autorizo' THEN
        COMPARTIR_INFORMACION := 'S';
      ELSE
        COMPARTIR_INFORMACION := 'N';
      END IF;

      IF P_SEGMENTACION_CLIENTE_MENOR = 'Banca Privada' THEN
        BANCA_PRIVADA := 'S';
      ELSE
        BANCA_PRIVADA := 'N';
      END IF;

      UPDATE CLIENTES
         SET CLI_MONTO_INICIAL_INVERSION  = NVL(TO_NUMBER(REPLACE(REPLACE(P_MONTO_INICIAL_INVERSIO_MENOR,
                                                                          '.',
                                                                          ''),
                                                                  ',',
                                                                  '.')),
                                                0),
             CLI_REG_SIMPLE               = 'N',
             CLI_REG_TRIB_ESP             = 'N',
             CLI_CARGO_FAMILIAR_PEP       = P_CARGO_MENOR,
             CLI_MIGRADO                  = 'N',
             CLI_COMPARTIR_INFORMACION    = COMPARTIR_INFORMACION,
             CLI_RECURSOS_BIENES_ENTREGAR = 'D',
             CLI_BANCA_PRIVADA            = BANCA_PRIVADA
       WHERE CLI_PER_NUM_IDEN = P_NUMERO_DOCUMENTO_MENOR
         AND CLI_PER_TID_CODIGO = TIPO_IDENTIFICAC_MENOR;

      OPEN C_RES_FISCAL_MENOR(TIPO_IDENTIFICAC_MENOR);
      FETCH C_RES_FISCAL_MENOR
        INTO V_RES_FISCAL_MENOR;
      CLOSE C_RES_FISCAL_MENOR;

      IF V_RES_FISCAL_MENOR.PNF_RESIDENCIA_FISCAL IS NULL OR
         V_RES_FISCAL_MENOR.PNF_RESIDENCIA_FISCAL = '' THEN
        IF NACIONALIDAD = 'COM' THEN
          NACIONALIDAD := 'COL';
        ELSIF NACIONALIDAD != 'COL' THEN
          NACIONALIDAD := PAIS;
        END IF;
        UPDATE PERSONA_NATURAL
           SET PNF_RESIDENCIA_FISCAL   = NACIONALIDAD,
               PNF_MOT_CONSECUTIVO     = NULL,
               PNF_OTRO_MOTIVO_ESTADIA = NULL
         WHERE PNF_CLI_PER_NUM_IDEN = P_NUMERO_DOCUMENTO_MENOR
           AND PNF_CLI_PER_TID_CODIGO = TIPO_IDENTIFICAC_MENOR;
      END IF;

      OPEN C_CCC_MENOR(TIPO_IDENTIFICAC_MENOR);
      FETCH C_CCC_MENOR
        INTO V_CCC_MENOR;
      IF C_CCC_MENOR%NOTFOUND THEN
        INSERT INTO CUENTAS_CLIENTE_CORREDORES
          (CCC_CLI_PER_NUM_IDEN,
           CCC_CLI_PER_TID_CODIGO,
           CCC_NUMERO_CUENTA,
           CCC_PER_NUM_IDEN,
           CCC_PER_TID_CODIGO,
           CCC_AGE_CODIGO,
           CCC_FECHA_APERTURA,
           CCC_NOMBRE_CUENTA,
           CCC_DIRECCION,
           CCC_SALDO_CAPITAL,
           CCC_SALDO_A_PLAZO,
           CCC_SALDO_A_CONTADO,
           CCC_SALDO_ADMON_VALORES,
           CCC_CUENTA_ACTIVA,
           CCC_CUENTA_ESPECULATIVA,
           CCC_PERIODO_EXTRACTO,
           CCC_ENVIAR_EXTRACTO,
           CCC_SALDO_CANJE,
           CCC_CONTRATO_OPCF,
           CCC_CUENTA_CRCC,
           CCC_CUENTA_APT,
           CCC_SALDO_CC,
           CCC_ETRADE,
           CCC_CTA_COMPARTIMENTO,
           CCC_SALDO_CANJE_CC,
           CCC_FON_CODIGO,
           CCC_SALDO_BURSATIL,
           CCC_LINEAS_PROFUNDIDAD,
           CCC_PANTALLA_LIVIANA)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --CCC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --CCC_CLI_PER_TID_CODIGO
          ,
           1 --CCC_NUMERO_CUENTA
          ,
           P_NUMERO_FUNCIONARIO_MENOR --CCC_PER_NUM_IDEN
          ,
           P_SIGLA_FUNCIONARIO_MENOR --CCC_PER_TID_CODIGO
          ,
           LUGAR_OFICINA --CCC_AGE_CODIGO
          ,
           SYSDATE --CCC_FECHA_APERTURA
          ,
           UPPER(TRIM(P_PRIMER_APELLIDO_MENOR)) || ' ' ||
           UPPER(TRIM(P_SEGUNDO_APELLIDO_MENOR)) || ' ' ||
           UPPER(TRIM(P_NOMBRES_MENOR)) --CCC_NOMBRE_CUENTA
          ,
           P_DIRECCION_RESIDENCIA_MENOR --CCC_DIRECCION
          ,
           0 --CCC_SALDO_CAPITAL
          ,
           0 --CCC_SALDO_A_PLAZO
          ,
           0 --CCC_SALDO_A_CONTADO
          ,
           0 --CCC_SALDO_ADMON_VALORES
          ,
           'N' --CCC_CUENTA_ACTIVA
          ,
           NULL --CCC_CUENTA_ESPECULATIVA
          ,
           'N' --CCC_PERIODO_EXTRACTO
          ,
           'N' --CCC_ENVIAR_EXTRACTO
          ,
           0 --CCC_SALDO_CANJE
          ,
           NULL --CCC_CONTRATO_OPCF
          ,
           NULL --CCC_CUENTA_CRCC
          ,
           'N' --CCC_CUENTA_APT
          ,
           0 --CCC_SALDO_CC
          ,
           NULL --CCC_ETRADE
          ,
           NULL --CCC_CTA_COMPARTIMENTO
          ,
           0 --CCC_SALDO_CANJE_CC
          ,
           NULL --CCC_FON_CODIGO
          ,
           0 --CCC_SALDO_BURSATIL
          ,
           NULL --CCC_LINEAS_PROFUNDIDAD
          ,
           'N' --CCC_PANTALLA_LIVIANA
           );
      END IF;

      CLOSE C_CCC_MENOR;

      UPDATE PERSONAS
         SET PER_ORIGEN = 'VGO'
       WHERE PER_NUM_IDEN = TRIM(P_NUMERO_DOCUMENTO_MENOR)
         AND PER_TID_CODIGO = TRIM(TIPO_IDENTIFICAC_MENOR);

      EXECUTE IMMEDIATE ('ALTER TRIGGER CLI_BIU_TRG DISABLE');

      IF P_DOCUMENTO_ORDENANTE_MENOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_ORDENAN_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 1 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_ORDENAN_MENOR);
        END IF;

        IF P_PRIMER_APELLIDO_ORDENA_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 1 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_ORDENA_MENOR);
        END IF;

        IF P_NOMBRES_ORDENANTE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 1 sin nombre: ' ||
                                  P_NOMBRES_ORDENANTE_MENOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_ORDENAN_MENOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor Ordenante 1 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_ORDENAN_MENOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_ORDENANTE_MENOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_ORDENAN_MENOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_ORDENAN_MENOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_ORDENA_MENOR),
             UPPER(P_SEGUND_APELLIDO_ORDENA_MENOR),
             UPPER(P_NOMBRES_ORDENANTE_MENOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_ORDENAN_MENOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_ORDE_MENOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_ORDE_MENOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_ORDE_MENOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_ORDE_MENOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_CALIDAD,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_ORDENANTE_MENOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_ORDENAN_MENOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           TRIM(P_TELEFONO_CELULAR_2_MENOR) --RLC_CELULAR
          ,
           TRIM(P_CORREO_ELECTRONICO_3_MENOR) --RLC_DIRECCION_EMAIL
          ,
           'PM' --RLC_CALIDAD
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_1_ORDENANTE_MENOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_1_ORDEN_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 2 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_1_ORDEN_MENOR);
        END IF;

        IF P_PRIMER_APELLIDO_1_ORDE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 2 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_1_ORDE_MENOR);
        END IF;

        IF P_NOMBRES_1_ORDENANTE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 2 sin nombre: ' ||
                                  P_NOMBRES_1_ORDENANTE_MENOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_1_ORDEN_MENOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor Ordenante 2 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_1_ORDEN_MENOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_1_ORDENANTE_MENOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_1_ORDEN_MENOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_1_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_1_ORDEN_MENOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_1_ORDE_MENOR),
             UPPER(P_SEGUND_APELLIDO_1_ORDE_MENOR),
             UPPER(P_NOMBRES_1_ORDENANTE_MENOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_1_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_1_ORDEN_MENOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_1_ORDE_MENOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_1_ORDE_MENOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_1_ORDE_MENOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_1_ORDE_MENOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_1_ORDENANTE_MENOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_1_ORDEN_MENOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_2_ORDENANTE_MENOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_2_ORDEN_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 3 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_2_ORDEN_MENOR);
        END IF;

        IF P_PRIMER_APELLIDO_2_ORDE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 3 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_2_ORDE_MENOR);
        END IF;

        IF P_NOMBRES_2_ORDENANTE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 3 sin nombre: ' ||
                                  P_NOMBRES_2_ORDENANTE_MENOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_2_ORDEN_MENOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor Ordenante 3 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_2_ORDEN_MENOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_2_ORDENANTE_MENOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_2_ORDEN_MENOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_2_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_2_ORDEN_MENOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_2_ORDE_MENOR),
             UPPER(P_SEGUND_APELLIDO_2_ORDE_MENOR),
             UPPER(P_NOMBRES_2_ORDENANTE_MENOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_2_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_2_ORDEN_MENOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_2_ORDE_MENOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_2_ORDE_MENOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_2_ORDE_MENOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_2_ORDE_MENOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_2_ORDENANTE_MENOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_2_ORDEN_MENOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_3_ORDENANTE_MENOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_3_ORDEN_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 4 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_3_ORDEN_MENOR);
        END IF;

        IF P_PRIMER_APELLIDO_3_ORDE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 4 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_3_ORDE_MENOR);
        END IF;

        IF P_NOMBRES_3_ORDENANTE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 4 sin nombre: ' ||
                                  P_NOMBRES_3_ORDENANTE_MENOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_3_ORDEN_MENOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor Ordenante 4 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_3_ORDEN_MENOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_3_ORDENANTE_MENOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_3_ORDEN_MENOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_3_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_3_ORDEN_MENOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_3_ORDE_MENOR),
             UPPER(P_SEGUND_APELLIDO_3_ORDE_MENOR),
             UPPER(P_NOMBRES_3_ORDENANTE_MENOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_3_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_3_ORDEN_MENOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_3_ORDE_MENOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_3_ORDE_MENOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_3_ORDE_MENOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_3_ORDE_MENOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_3_ORDENANTE_MENOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_3_ORDEN_MENOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_4_ORDENANTE_MENOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_4_ORDEN_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 5 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_4_ORDEN_MENOR);
        END IF;

        IF P_PRIMER_APELLIDO_4_ORDE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 5 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_4_ORDE_MENOR);
        END IF;

        IF P_NOMBRES_4_ORDENANTE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 5 sin nombre: ' ||
                                  P_NOMBRES_4_ORDENANTE_MENOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_4_ORDEN_MENOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor Ordenante 5 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_4_ORDEN_MENOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_4_ORDENANTE_MENOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_4_ORDEN_MENOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_4_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_4_ORDEN_MENOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_4_ORDE_MENOR),
             UPPER(P_SEGUND_APELLIDO_4_ORDE_MENOR),
             UPPER(P_NOMBRES_4_ORDENANTE_MENOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_4_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_4_ORDEN_MENOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_4_ORDE_MENOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_4_ORDE_MENOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_4_ORDE_MENOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_4_ORDE_MENOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_4_ORDENANTE_MENOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_4_ORDEN_MENOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      IF P_DOCUMENTO_5_ORDENANTE_MENOR IS NOT NULL THEN

        IF P_TIPO_DOCUMENTO_5_ORDEN_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 6 sin tipo tipo de documento: ' ||
                                  P_TIPO_DOCUMENTO_5_ORDEN_MENOR);
        END IF;

        IF P_PRIMER_APELLIDO_5_ORDE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 6 sin primer apellido: ' ||
                                  P_PRIMER_APELLIDO_5_ORDE_MENOR);
        END IF;

        IF P_NOMBRES_5_ORDENANTE_MENOR IS NULL THEN
          RAISE_APPLICATION_ERROR(-20000,
                                  'Persona Menor ordenante 6 sin nombre: ' ||
                                  P_NOMBRES_5_ORDENANTE_MENOR);
        END IF;

        BEGIN
          SELECT AGE_CODIGO
            INTO LUGAR_RESIDENCIA_ORD
            FROM AREAS_GEOGRAFICAS
           WHERE AGE_CIUDAD || ' ' || AGE_DEPARTAMENTO || ' ' || AGE_PAIS =
                 TRIM(P_LUGAR_EXPEDICI_5_ORDEN_MENOR)
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20000,
                                    'Persona Menor Ordenante 6 con ciudad de residencia errada: ' ||
                                    P_LUGAR_EXPEDICI_5_ORDEN_MENOR);
        END;

        BEGIN

          SELECT 'X'
            INTO EXISTE_ORD
            FROM PERSONAS
           WHERE PER_NUM_IDEN = P_DOCUMENTO_5_ORDENANTE_MENOR
             AND PER_TID_CODIGO = P_TIPO_DOCUMENTO_5_ORDEN_MENOR;

        EXCEPTION

          WHEN OTHERS THEN
            EXISTE_ORD := 'Y';

        END;

        IF EXISTE_ORD = 'Y' THEN

          INSERT INTO PERSONAS
            (PER_NUM_IDEN,
             PER_TID_CODIGO,
             PER_TIPO,
             PER_PRIMER_APELLIDO,
             PER_SEGUNDO_APELLIDO,
             PER_NOMBRE)
          VALUES
            (P_DOCUMENTO_5_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_5_ORDEN_MENOR,
             'PNA',
             UPPER(P_PRIMER_APELLIDO_5_ORDE_MENOR),
             UPPER(P_SEGUND_APELLIDO_5_ORDE_MENOR),
             UPPER(P_NOMBRES_5_ORDENANTE_MENOR));

          INSERT INTO CLIENTES
            (CLI_PER_NUM_IDEN,
             CLI_PER_TID_CODIGO,
             CLI_AGE_CODIGO,
             CLI_ECL_MNEMONICO,
             CLI_BSC_MNEMONICO,
             CLI_BSC_BCC_MNEMONICO,
             CLI_TEC_MNEMONICO,
             CLI_FECHA_APERTURA,
             CLI_FECHA_ULTIMA_ACTUALIZACION,
             CLI_USUARIO_ULTIMA_ACTUALIZACI,
             CLI_AUTORIZA_PLAZO,
             CLI_AUTORIZA_REPO,
             CLI_AUTORIZA_SWAP,
             CLI_AUTORIZA_CARRUSEL,
             CLI_AUTORIZA_CONTRATO_COMISION,
             CLI_AUTORIZA_ADMON_VALORES,
             CLI_EXCENTO_DXM_FONDOS,
             CLI_HABILITADO_INTERNET,
             CLI_EXCENTO_IVA,
             CLI_TIPO_CLIENTE,
             CLI_PERFIL_RIESGO,
             CLI_ULTIMA_OPERACION_EJECUTADA)
          VALUES
            (P_DOCUMENTO_5_ORDENANTE_MENOR,
             P_TIPO_DOCUMENTO_5_ORDEN_MENOR,
             LUGAR_RESIDENCIA_ORD,
             'ACC',
             'ORO',
             'NAT',
             'CEL',
             SYSDATE,
             SYSDATE,
             USER,
             'S',
             'S',
             'S',
             'S',
             'S',
             'N',
             'N',
             'I',
             'N',
             'C',
             10,
             'AP');

        END IF;

        IF TRIM(P_PARTE_RELACION_5_ORDE_MENOR) =
           '1. Cónyuge o compañero(a) permanente del Titular de la cuenta' THEN
          PARENTESCO := 10;
        ELSIF TRIM(P_PARTE_RELACION_5_ORDE_MENOR) =
              '2. Familiar del titular de la cuenta hasta segundo grado de consanguinidad: Padre. Madre. Hijo (a). Abuelo (a). Nieto (a). Hermano (a)' THEN
          PARENTESCO := 13;
        ELSIF TRIM(P_PARTE_RELACION_5_ORDE_MENOR) =
              '3. Familiar hasta segundo grado de afinidad: Suegro(a). Hermano(a) del Cónyuge. Hijo (a) del Cónyuge' THEN
          PARENTESCO := 15;
        ELSIF TRIM(P_PARTE_RELACION_5_ORDE_MENOR) =
              '4. Familiar del titular de la cuenta en un único grado civil: Padres adoptantes. Hijos adoptivos' THEN
          PARENTESCO := 8;
        ELSE
          PARENTESCO := NULL;
        END IF;

        INSERT INTO PERSONAS_RELACIONADAS
          (RLC_CLI_PER_NUM_IDEN,
           RLC_CLI_PER_TID_CODIGO,
           RLC_PER_NUM_IDEN,
           RLC_PER_TID_CODIGO,
           RLC_ROL_CODIGO,
           RLC_ESTADO,
           RLC_FECHA_CAMBIO_ESTADO,
           RLC_USUARIO_ULTIMO_CAMBIO_ESTA,
           RLC_ETRADE,
           RLC_CELULAR,
           RLC_DIRECCION_EMAIL,
           RLC_PAO_CONSECUTIVO)
        VALUES
          (TRIM(P_NUMERO_DOCUMENTO_MENOR) --RLC_CLI_PER_NUM_IDEN
          ,
           TRIM(TIPO_IDENTIFICAC_MENOR) --RLC_CLI_PER_TID_CODIGO
          ,
           TRIM(P_DOCUMENTO_5_ORDENANTE_MENOR) --RLC_PER_NUM_IDEN
          ,
           TRIM(P_TIPO_DOCUMENTO_5_ORDEN_MENOR) --RLC_PER_TID_CODIGO
          ,
           1 --RLC_ROL_CODIGO: ORDENANTE
          ,
           'A' --R_RLC.RLC_ESTADO
          ,
           SYSDATE --RLC_FECHA_CAMBIO_ESTADO
          ,
           USER --RLC_USUARIO_ULTIMO_CAMBIO_ESTA
          ,
           'S' --RLC_ETRADE
          ,
           NULL --RLC_CELULAR
          ,
           NULL --RLC_DIRECCION_EMAIL
          ,
           PARENTESCO --RLC_PAO_CONSECUTIVO
           );

      END IF;

      EXECUTE IMMEDIATE ('ALTER TRIGGER CLI_BIU_TRG ENABLE');

      COMMIT;

    END IF;

    P_ERROR1 := 'OK';
    P_ERROR2 := 'OK';

  EXCEPTION

    WHEN OTHERS THEN
      IF PN_MAYOR = 'S' THEN
        P_ERROR1 := 'ERROR AL CREAR EL CLIENTE MAYOR CON ID ' ||
                    P_NUMERO_2_MAYOR || ' ERROR: ' || SQLERRM;
      END IF;
      IF PN_MENOR = 'S' THEN
        P_ERROR2 := 'ERROR AL CREAR EL CLIENTE MENOR CON ID ' ||
                    P_NUMERO_DOCUMENTO_MENOR || ' ERROR: ' || SQLERRM;
      END IF;

  END PR_VINGO;
  ---------------------------------------------------------------------------------------
  PROCEDURE PR_PERSONAS_RLC_VINCULA_PEP(P_NUMERO_FORMULARIO  IN NUMBER,
                                        P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                        P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                        P_PER_NUM_IDEN       IN VARCHAR2,
                                        P_PER_TID_CODIGO     IN VARCHAR2,
                                        P_PRIMER_APELLIDO    IN VARCHAR2,
                                        P_SEGUNDO_APELLIDO   IN VARCHAR2,
                                        P_NOMBRE             IN VARCHAR2,
                                        P_PARENTESCO         IN NUMBER,
                                        P_CLOB               OUT CLOB) IS

  BEGIN
    P_CLOB := NULL;
    INSERT INTO PERSONAS_RELACIONADAS_PEP
      (RLCP_CLI_PER_NUM_IDEN,
       RLCP_CLI_PER_TID_CODIGO,
       RLCP_PER_NUM_IDEN,
       RLCP_PER_TID_CODIGO,
       RLCP_PAO_CONSECUTIVO,
       RLCP_PER_PRIMER_APELLIDO,
       RLCP_PER_SEGUNDO_APELLIDO,
       RLCP_PER_NOMBRE,
       RLCP_NUM_FORMULARIO)
    VALUES
      (P_CLI_PER_NUM_IDEN,
       P_CLI_PER_TID_CODIGO,
       P_PER_NUM_IDEN,
       P_PER_TID_CODIGO,
       P_PARENTESCO,
       P_PRIMER_APELLIDO,
       P_SEGUNDO_APELLIDO,
       P_NOMBRE,
       P_NUMERO_FORMULARIO);
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      P_CAB.CrearError('Error creando persona relacionada pep :' ||
                       SQLERRM);
      P_CLOB := P_CAB.ObtenerCLOB_ERROR('PersonasRlcPep');
  END PR_PERSONAS_RLC_VINCULA_PEP;
  ---------------------------------------------------------------------------------------
  --VAGTUD1004 ELIMINACION ENVIO OTP POR EMAIL 
  FUNCTION FN_VALIDAD_CIUDAD_RESIDENCIA(P_CODIGO_RESIDE IN NUMBER)
    RETURN NUMBER IS
    V_RESULTADO NUMBER;
  BEGIN
    SELECT COUNT(1)
      INTO V_RESULTADO
      FROM AREAS_GEOGRAFICAS T
     WHERE T.AGE_PAIS = 'COLOMBIA'
       AND T.AGE_CODIGO = P_CODIGO_RESIDE;

    RETURN V_RESULTADO;
  EXCEPTION
    WHEN OTHERS THEN
      V_RESULTADO := 1;
      RETURN V_RESULTADO;

  END FN_VALIDAD_CIUDAD_RESIDENCIA;
END P_CLIENTES;

/

  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GESTOR_VINCULACION";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_COORDINACION_VINCULACION";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_ANALISTA_CUA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_VICEPRECI_BANC_INVER_TRADER";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SARLAFT_OFICIAL_CUMPLIMIENTO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SARLAFT_COORDINADORA_PCLATF";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SARLAFT_ANALISTA_LAVADO_ACTI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SARLAFT_ANALISTA_FATCA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_PROFESIONAL_II_TRADING";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_SUPERNUMERARIA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_JEFE_OPERACIONES";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COORD_TESO_PAG_RECAU";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COORD_SERVI_OPERA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COORD_CUMPLIMIENTO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_OPERA_INVERSION_REG";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_LL_INVERS_OTROS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUXI_CUMPLIMIENTO_BURSA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_CUMP_OTROS_DERIVA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_CUMPLIMIENTO_OTROS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_COMPEN_CUA_CIE_TESO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_ANALIS_SERVI_OPERA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_ANALIS_INVER_FICS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_ANALIS_CUA_CIE_TESO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GEREN_CONT_COORD_APT_CCY_FCP";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_TESO_TRADER_REC_PRO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_TESO_TRADER_DIVISAS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_TESORERIA_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_TESORE_ASISTENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RIESGO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENT_VAR_ESTRATEGA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENT_VAR_ASIS_MERCA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENT_VAR_ASESOR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENT_FIJ_ASISTEN_CO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENTA_VARIA_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_PORT_TER_ANALIS_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_PORTA_TERCE_TRADER";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_PORTA_TERCE_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_INTE_NEG_JEFE_PROY";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_TRAIDER_RE_V";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_TRADER_JR_RF";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_GEREN_REN_FI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_GERE_INV_REN";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_COOR_ADM_FIC";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_AUX_ADM_COLE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_DERIVA_ESPECIALISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_DERIVADOS_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_DERIVADOS_ASISTENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_CONTABILI_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_CONTABILID_ANISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_CONTABILIDAD_JEFE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_CONTABILI_AUXIL";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENC_CONT_COORD_IMPUESTOS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_PLA_DIRECTOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_PLA_ASIS_COMER";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_PLA_ASESOR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEGME_COR_SETEADOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEGME_COR_DIRECTOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_IND_DIRECTOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_IND_ASIST_MESA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_IND_ASISTE_COM";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_IND_ASESOR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_COR_ASIST_MESA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_DIRECCION_SEG_COR_ASESOR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CORREDORES_CONSULTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTROL_FINANCIERO_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTROL_FINANCIERO_ESPECIALI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTROL_FINANCIERO_ANALISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTRALORIA_ANALISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_COORDI_CONTROL";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_ANALIST_III_COS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANCA_PRIVADA_ASIST_COMERC";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANCA_PRIVADA_ASESOR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_AUDITORIA_COORDINADOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_AUDITORIA_ANALISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CORRE_CONSULTA_BCA_PATRI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "COE_RECURSOS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "RESOURCE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COMPLEMENTADOR_CUMP";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_CUMPLI_ADMON_VAL";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCI_CONTA_ANALIS_TRANSMI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_JURIDICA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_INVEST_ECONO_ESTRUCTURADOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_VICEPRECIDENT_FINANCIERO_ADM";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SAC_CALIDAD_AUXI_SERV_CLIE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COORD_INVER_FICS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_L_MON_EXTRAN";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_ANALIS_INVER_OTROS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_ANALIS_COOR_MON_EXTRAN";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GEREN_CONT_COORD_CLIEN_COMPA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GEREN_CONT_AUX_TRANSMI_BANCO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENT_FIJ_ASESOR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_RENT_FIJA_GERENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_INTE_NEG_JEFE_PRODU";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_INTE_NEG_AUX_CANALE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_CONTA_ESPECIALISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_ADM_AUXI_CORRESPOND";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_ADM_AUXI_ARCHIVO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_ADM_AUXI_ALISTAMIEN";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTRALORIA_ESPECI_SEGU_INFO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTRALORIA_ESPECIALISTA_BCP";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONT_FIN_ANALI_NEG_GEST_COME";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_ADMINIST_IN_CO_ANALIS_JR_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SAC_CALIDAD_ESPECIALISTA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COORDI_CUMPLIMIENTO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_COMPLEMENTADOR_CUMPLI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_CUMP_ADM_VAL_PATRI";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_CONTRALORIA_COORDINADOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_PROFESION_III";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_PROFE_PQR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_VICEPRES_NEGO_INT_VICEPRECID";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_SARLAFT_AUXILIR_PREVENCION";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_REVISORIA_FISCAL_ASISTENTE";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_LL_OPER_MON_EXTRAN";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_L_CUA_CIE_TESO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_CUMPLIMIENTO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_AUX_CUMPLI_DEPO_DCV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_J_OP_ANALIS_CUMPLI_DEPOSITO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_ESPECI_FICS";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_FONDOS_COOR_SER_COL";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_VINCULA_OPERAC";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_PROFESIONAL_ELEC";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_EJECUTIVO_INVER";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_COORD_OPER_VALOR";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_COORD_COMER_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_ASESOR_TRADING";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_ASESOR_COMER_INV";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_BANC_PATRI_ANALIS_II_OPERA";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_ADMINIST_IN_CO_COOR_FON_CA_P";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_ADMINIST_IN_CO_ANALIS_ADM_CO";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_AUX_OP_TESORERIA_MED";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_TRADER";
  GRANT EXECUTE ON "PROD"."P_CLIENTES" TO "M_GERENCIA_TESORERIA_JEFE";
