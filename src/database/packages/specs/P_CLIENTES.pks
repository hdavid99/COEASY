--------------------------------------------------------
--  File created - Sunday-April-26-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package P_CLIENTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "PROD"."P_CLIENTES" IS
  -- Sub-Program Unit Declarations
  TYPE O_CURSOR IS REF CURSOR;
  C_RUTA_ATTCH VARCHAR2(256) := 'NTFMAILATT';

  FUNCTION PR_DIGITO_CONTROL(NIT IN VARCHAR2, DCHEQUEO IN NUMBER)
    RETURN BOOLEAN;
  FUNCTION RT_DIGITO_CONTROL(NIT IN NUMBER) RETURN NUMBER;
  FUNCTION F_TIPO_PERSONA(NO_ID   IN PERSONAS.PER_NUM_IDEN%TYPE,
                          TIPO_ID IN PERSONAS.PER_TID_CODIGO%TYPE)
    RETURN PERSONAS.PER_TIPO%TYPE;
  PROCEDURE P_DIRECCION_CORRESPONDENCIA(P_NUM_IDEN   IN VARCHAR2,
                                        P_TID_CODIGO IN VARCHAR2,
                                        P_DIRECCION  OUT VARCHAR2,
                                        P_TELEFONO   OUT VARCHAR2,
                                        P_CIUDAD     OUT VARCHAR2);
  PROCEDURE P_DIRECCION_CORRESPONDENCIA(P_NUM_IDEN             IN VARCHAR2,
                                        P_TID_CODIGO           IN VARCHAR2,
                                        P_DIRECCION            OUT VARCHAR2,
                                        P_TELEFONO             OUT VARCHAR2,
                                        P_CIUDAD               OUT VARCHAR2,
                                        P_CIUDAD_DECEVAL       OUT NUMBER,
                                        P_DEPARTAMENTO_DECEVAL OUT NUMBER,
                                        P_PAIS_DECEVAL         OUT VARCHAR2,
                                        P_PAIS                 OUT VARCHAR2);
  PROCEDURE ENVIO_CORRESPONDENCIA(P_CCC_CLI_PER_NUM_IDEN   CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE,
                                  P_CCC_CLI_PER_TID_CODIGO CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE,
                                  P_CLI_TEC_MNEMONICO      CLIENTES.CLI_TEC_MNEMONICO%TYPE,
                                  P_GRU_NOMBRE             IN OUT GRUPOS.GRU_NOMBRE%TYPE,
                                  P_GRU_PREGUNTAR_POR      IN OUT GRUPOS.GRU_PREGUNTAR_POR%TYPE,
                                  P_GRU_DIRECCION_CORRES   IN OUT GRUPOS.GRU_DIRECCION_CORRESPONDENCIA%TYPE,
                                  P_GRU_CIUDAD             IN OUT AREAS_GEOGRAFICAS.AGE_CIUDAD%TYPE,
                                  P_CIUDAD                 IN OUT AREAS_GEOGRAFICAS.AGE_CIUDAD%TYPE,
                                  P_DIRECCION              IN OUT CLIENTES.CLI_DIRECCION_OFICINA%TYPE);
  FUNCTION GRUPO(P_CCC_CLI_PER_NUM_IDEN   CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_NUM_IDEN%TYPE,
                 P_CCC_CLI_PER_TID_CODIGO CUENTAS_CLIENTE_CORREDORES.CCC_CLI_PER_TID_CODIGO%TYPE)
    RETURN NUMBER;
  PROCEDURE ValidaPerfilPortafolio(P_TID_CODIGO IN VARCHAR2,
                                   P_NUM_IDEN   IN VARCHAR2,
                                   P_FECHA      IN DATE,
                                   P_PERFIL     IN OUT NUMBER);
  FUNCTION AutorizaColocacionOrdenPerfil(P_PRODUCTO     IN VARCHAR2,
                                         P_OPERACION    IN VARCHAR2, -- TIPO DE ORDEN
                                         P_CNE          IN VARCHAR2, -- CONDICION DE NEGOCIACION PARA OP BURSATIL
                                         P_AP           IN VARCHAR2, -- ACTIVO PASIVO PARA REPOS Y SIMULTANEAS (OP BURSATIL)
                                         P_PERFIL       IN VARCHAR2, -- PERFIL DE RIESGO DEL CLIENTE
                                         P_CALIFICACION IN VARCHAR2, -- CALIFICACION DE RIESGO DE LA ESPECIE
                                         P_TIPO_PERSONA IN VARCHAR2) -- PNA / PJU)
   RETURN VARCHAR2;
  FUNCTION AutorizaColocaOrdenPerfilProf(P_PRODUCTO     IN VARCHAR2,
                                         P_OPERACION    IN VARCHAR2, -- TIPO DE ORDEN
                                         P_CNE          IN VARCHAR2, -- CONDICION DE NEGOCIACION PARA OP BURSATIL
                                         P_AP           IN VARCHAR2, -- ACTIVO PASIVO PARA REPOS Y SIMULTANEAS (OP BURSATIL)
                                         P_PERFIL       IN VARCHAR2, -- PERFIL DE RIESGO DEL CLIENTE
                                         P_CALIFICACION IN VARCHAR2, -- CALIFICACION DE RIESGO DE LA ESPECIE
                                         P_TIPO_PERSONA IN VARCHAR2, -- PNA / PJU
                                         P_ID           IN VARCHAR2, -- DOCUMENTO DE IDENTIDAD
                                         P_TIP_ID       IN VARCHAR2 -- TIPO DE DOCUMENTO
                                         ) RETURN VARCHAR2;
  PROCEDURE InsertarClienteSegmentado(P_FECHA            IN DATE,
                                      P_TID_CLIENTE      IN VARCHAR2,
                                      P_NUMID_CLIENTE    IN VARCHAR2,
                                      P_CLASE_CLIENTE    IN VARCHAR2,
                                      P_SEG_CLIENTE      IN VARCHAR2,
                                      P_USER             IN VARCHAR2,
                                      P_VALOR_PORTAFOLIO IN NUMBER);
  PROCEDURE DeshabilitarTriggerClientes;
  PROCEDURE HabilitarTriggerClientes;
  PROCEDURE ConsultarEstadoTriggerClientes(P_ESTADO OUT VARCHAR2);
  PROCEDURE P_CONSULTAR_CLIENTE(P_NUM_IDEN            IN VARCHAR2,
                                P_TID_CODIGO          IN VARCHAR2,
                                P_CLIENTE             OUT CLIENTES%ROWTYPE,
                                P_PERSONA             OUT PERSONAS%ROWTYPE,
                                P_CIUDAD              OUT AREAS_GEOGRAFICAS%ROWTYPE,
                                P_PERSONA_RELACIONADA OUT VARCHAR2);
  PROCEDURE P_PERSONA_VINCULADA(P_PER_NUM_IDEN   IN VARCHAR2,
                                P_PER_TID_CODIGO IN VARCHAR2,
                                RESPUESTA        IN OUT VARCHAR2);

  PROCEDURE P_CTA_DIG_DCV(P_DSP_CUENTA IN VARCHAR2, --NUMBER, MIC DCV BANCO DE LA REPUBLICA 
                          P_CUENTA_DCV OUT VARCHAR2, --NUMBER, MIC DCV BANCO DE LA REPUBLICA 
                          P_DIGITO_DCV OUT NUMBER);

  /* ********************************************************* */
  PROCEDURE PR_INSERTAR_PROSPECTO(P_PER_NUM_IDEN   IN VARCHAR2,
                                  P_PER_TID_CODIGO IN VARCHAR2,
                                  P_FONDO          IN VARCHAR2,
                                  P_RADICACION     IN VARCHAR2);

  /* ********************************************************* */
  PROCEDURE PR_VALIDAR_PROSPECTO(P_PER_NUM_IDEN         IN VARCHAR2,
                                 P_PER_TID_CODIGO       IN VARCHAR2,
                                 P_FONDO                IN VARCHAR2,
                                 P_TIENE_PROSPECTO      IN OUT VARCHAR2,
                                 P_FONDO_PPAL_PROSPECTO IN OUT VARCHAR2);
  /* ********************************************************* */
  FUNCTION P_EXTRAE_CARACTER(P_NID IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION P_EMAIL(P_NID IN VARCHAR2, P_TID IN VARCHAR2) RETURN VARCHAR2;

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
                                      P_LCC_USUARIO_REGISTRO IN VARCHAR2 DEFAULT 'PROD');

  PROCEDURE P_VALIDAR_LISTA_CAUT_CLI;

  PROCEDURE P_INFO_CLIENTES_CRM_DAVIVIENDA(io_cursor IN OUT O_CURSOR);

  FUNCTION FN_VALIDACLIENTE(P_TID_CODIGO IN VARCHAR2,
                            P_NUM_IDEN   IN VARCHAR2) RETURN VARCHAR2;
  PROCEDURE PR_SEGMENTACION_INICIAL(P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                    P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                    P_TIPO               IN VARCHAR2,
                                    P_BANCA_PRIVADA      IN VARCHAR2,
                                    P_INST_EXT           IN VARCHAR2,
                                    P_VIG_SFC            IN VARCHAR2,
                                    P_BCC_CLIENTE        IN OUT VARCHAR2,
                                    P_BSC_CLIENTE        IN OUT VARCHAR2,
                                    P_BCC_ALT            IN OUT VARCHAR2,
                                    P_BSC_ALT            IN OUT VARCHAR2);

  FUNCTION FN_INGRESO_OPERACIONAL(P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                  P_CLI_PER_TID_CODIGO IN VARCHAR2)
    RETURN NUMBER;

  FUNCTION FN_CARTERA(P_CLI_PER_NUM_IDEN IN VARCHAR2) RETURN VARCHAR2;
  PROCEDURE PR_SEGMENTA_CLIENTE(P_FECHA IN DATE,
                                P_TX    IN NUMBER DEFAULT NULL);
  FUNCTION FN_AUM_CLIENTE(P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                          P_CLI_PER_TID_CODIGO IN VARCHAR2,
                          P_FECHA_DESDE        IN DATE,
                          P_FECHA_HASTA        IN DATE) RETURN NUMBER;

  PROCEDURE PR_TRAE_SEGMENTO_CLI(P_VALOR IN NUMBER,
                                 P_BCC   IN CLIENTES.CLI_BSC_BCC_MNEMONICO%TYPE DEFAULT NULL,
                                 P_BSC   IN OUT CLIENTES.CLI_BSC_MNEMONICO%TYPE);

  PROCEDURE PR_SEGMENTA_ALTERNO_CLIENTE(P_TX IN NUMBER DEFAULT NULL);

  PROCEDURE PR_INSERTA_ERROR_SEGMENTA(P_PROCESO IN ERRORES_SEGMENTACION.ERSE_PROCESO%TYPE,
                                      P_ERROR   IN ERRORES_SEGMENTACION.ERSE_ERROR%TYPE);

  PROCEDURE PR_GARANTIA_EFECTIVO_DIA(P_FECHA IN DATE,
                                     P_TX    IN NUMBER DEFAULT NULL);

  FUNCTION FN_VALIDA_CON_DERIVADOS(P_TID_CODIGO IN VARCHAR2,
                                   P_NUM_IDEN   IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION FN_VALIDA_CON_DERI_TIT(P_TID_CODIGO IN VARCHAR2,
                                  P_NUM_IDEN   IN VARCHAR2) RETURN VARCHAR2;
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
                                       P_CLOB                       OUT CLOB);
  PROCEDURE PR_MARCAR_ADMON_VAL;

  PROCEDURE PR_ADMONVAL_SALDOS_FONDOS(P_FECHA_INI DATE, P_FECHA_FIN DATE);

  PROCEDURE PR_INACTIVAR_CONTRATOS(P_FECHA_PROCESO DATE);

  PROCEDURE PR_MAIL_LISTAS_CAUTELA(P_FECHA_PROCESO DATE DEFAULT NULL,
                                   P_TIPO_LISTA    VARCHAR2);

  PROCEDURE PR_OBTENER_PERFIL_CLIENTE(P_CODIGO_PERFIL OUT NUMBER,
                                      P_PERFIL        OUT VARCHAR2,
                                      P_CLOB          OUT CLOB);

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
                                    P_CLOB                 OUT CLOB);

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
                                    P_CLOB                       OUT CLOB);

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
                                   P_CLOB               OUT CLOB);

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
                                       P_CLOB               OUT CLOB);

  PROCEDURE PR_INFORMACION_REV_VINCULA(P_NUMERO_FORMULARIO  IN NUMBER,
                                       P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                       P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                       P_FECHA_APERTURA     IN VARCHAR2,
                                       P_ESTADO             IN VARCHAR2,
                                       P_PER_NUM_IDEN       IN VARCHAR2,
                                       P_PER_TID_CODIGO     IN VARCHAR2,
                                       P_ROL_ORDENANTE      IN NUMBER,
                                       P_PARENTESCO         IN NUMBER,
                                       P_CLOB               OUT CLOB);

  PROCEDURE PR_REVERSION_VINCULACION(P_NUMERO_FORMULARIO  IN NUMBER,
                                     P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                     P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                     P_LLAMADO            IN VARCHAR,
                                     P_CLOB               OUT CLOB);

  PROCEDURE PR_ACTUALIZA_VINCULACION(P_NUMERO_FORMULARIO  IN NUMBER,
                                     P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                     P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                     P_CLOB               OUT CLOB);

  PROCEDURE PR_INGRESOS_CUENTA_CLIENTE(P_MCC_CONSECUTIVO NUMBER,
                                       P_MONTO           IN OUT NUMBER,
                                       P_TIPO_MOV        IN OUT VARCHAR2,
                                       P_NEGOCIO         IN OUT VARCHAR2,
                                       P_APLICA          IN OUT VARCHAR2);

  PROCEDURE PR_RETIROS_CUENTA_CLIENTE(P_MCC_CONSECUTIVO NUMBER,
                                      P_MONTO           IN OUT NUMBER,
                                      P_TIPO_MOV        IN OUT VARCHAR2,
                                      P_NEGOCIO         IN OUT VARCHAR2,
                                      P_ES_CLIENTE      IN OUT VARCHAR2,
                                      P_APLICA          IN OUT VARCHAR2,
                                      P_NOMBRE_DE       IN OUT VARCHAR2,
                                      P_ES_GARANTIA     IN OUT VARCHAR2);

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
                                         P_CODIGO_POSTAL_D OUT VARCHAR2);

  /*********************************************************************************************
    Name    : PR_INACTIVAR_CLIENTES
    Author  : OSDSILVA
    Created : 03/09/2019 10:36:41 a.m.
    Purpose : VAGTUS048046.AutomatizacionProcesoInactivacionClientes
  **********************************************************************************************/
  PROCEDURE PR_INACTIVAR_CLIENTES(P_FECHA   IN DATE,
                                  P_USUARIO IN VARCHAR2,
                                  P_CNTINAC IN OUT NUMBER,
                                  P_ERROR   IN OUT CHAR,
                                  P_MENSAJE IN OUT VARCHAR2);

  PROCEDURE PR_NOTIFICAR_INACTIVA_CLI(P_FECHA DATE, P_CIN_USUARIO VARCHAR2);

  PROCEDURE PR_INSERTA_SAL_CLIENTES_FONDOS(P_FECHA     DATE,
                                           P_RESULTADO IN OUT VARCHAR2);

  PROCEDURE PR_INSERTA_SALDOS_CUENTAS(P_FECHA     DATE,
                                      P_RESULTADO IN OUT VARCHAR2);

  PROCEDURE PR_INSERTA_SAL_CLIENTES_DRVDOS(P_FECHA     DATE,
                                           P_RESULTADO IN OUT VARCHAR2);

  PROCEDURE P_LISTAR_CLIENTES_NUEVOS(io_cursor IN OUT O_CURSOR);

  PROCEDURE PR_TRUNC_TABLE(P_TABLE VARCHAR2);
  /*********************************************************************************************************
        AUTOR               : Cristhian Javier Fonseca Jimenez
        FECHA               : 2022-10-04
        DESCRIPCI¿N         : Obtener la cantidad de transacciones de coeasy
        PROCESO             : Reporte de vigia para el contador de transacciones
  **********************************************************************************************************/
  PROCEDURE PR_OBTENER_REPORTE_VIGIA(p_fecha          IN VARCHAR2,
                                     p_cRerporteVigia OUT SYS_REFCURSOR);

  /************************************************************************************************
  Purpose : Procedimiento utilizado para crear el cliente a traves de VinGo.
  Author  : VAGTUD885-3 Vinculacion VinGo - Julian Alberto Calderon Rodriguez
  Created : 17/01/2024 11:00:00 a.m.
  ************************************************************************************************/
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
                     P_ERROR2                       OUT VARCHAR2);
  ------------------------------------------------------------------------------
  PROCEDURE PR_PERSONAS_RLC_VINCULA_PEP(P_NUMERO_FORMULARIO  IN NUMBER,
                                        P_CLI_PER_NUM_IDEN   IN VARCHAR2,
                                        P_CLI_PER_TID_CODIGO IN VARCHAR2,
                                        P_PER_NUM_IDEN       IN VARCHAR2,
                                        P_PER_TID_CODIGO     IN VARCHAR2,
                                        P_PRIMER_APELLIDO    IN VARCHAR2,
                                        P_SEGUNDO_APELLIDO   IN VARCHAR2,
                                        P_NOMBRE             IN VARCHAR2,
                                        P_PARENTESCO         IN NUMBER,
                                        P_CLOB               OUT CLOB);
  ------------------------------------------------------------------------------

  --VAGTUD1004 ELIMINACION ENVIO OTP POR EMAIL
  FUNCTION FN_VALIDAD_CIUDAD_RESIDENCIA(P_CODIGO_RESIDE IN NUMBER)
    RETURN NUMBER;
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
