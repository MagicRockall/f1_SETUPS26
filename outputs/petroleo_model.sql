-- ============================================================
-- EMPRESA PETROLERA - Modelo de Datos DDL
-- Dominio: Oil & Gas / Upstream + Downstream + Comercial
-- BD Destino: SQL Server 2019
-- Generado: 2026-06-09
-- ============================================================

-- ============================================================
-- DIMENSION: PAISES / REGIONES
-- ============================================================
CREATE TABLE dim_pais (
    pais_id         INT             NOT NULL IDENTITY(1,1),
    codigo_iso      CHAR(3)         NOT NULL,
    nombre          VARCHAR(80)     NOT NULL,
    region          VARCHAR(50)     NOT NULL,   -- 'America','Medio Oriente','Africa','Europa'
    CONSTRAINT pk_dim_pais PRIMARY KEY (pais_id),
    CONSTRAINT uq_dim_pais_iso UNIQUE (codigo_iso)
);

-- ============================================================
-- DIMENSION: CUENCAS SEDIMENTARIAS
-- ============================================================
CREATE TABLE dim_cuenca (
    cuenca_id       INT             NOT NULL IDENTITY(1,1),
    pais_id         INT             NOT NULL,
    nombre_cuenca   VARCHAR(100)    NOT NULL,
    tipo_cuenca     VARCHAR(30)     NOT NULL,   -- 'Offshore','Onshore','Deepwater'
    area_km2        DECIMAL(12,2)   NULL,
    CONSTRAINT pk_dim_cuenca PRIMARY KEY (cuenca_id),
    CONSTRAINT fk_cuenca_pais FOREIGN KEY (pais_id) REFERENCES dim_pais(pais_id),
    CONSTRAINT ck_tipo_cuenca CHECK (tipo_cuenca IN ('Offshore','Onshore','Deepwater'))
);

-- ============================================================
-- DIMENSION: CAMPOS PETROLIFEROS
-- ============================================================
CREATE TABLE dim_campo (
    campo_id            INT             NOT NULL IDENTITY(1,1),
    cuenca_id           INT             NOT NULL,
    codigo_campo        VARCHAR(20)     NOT NULL,
    nombre_campo        VARCHAR(100)    NOT NULL,
    fecha_descubrimiento DATE           NULL,
    fecha_inicio_prod    DATE           NULL,
    estado              VARCHAR(20)     NOT NULL,   -- 'Exploracion','Desarrollo','Produccion','Abandono'
    tipo_yacimiento     VARCHAR(20)     NOT NULL,   -- 'Convencional','Shale','TarSands','Deepwater'
    profundidad_m       INT             NULL,
    reservas_mmbbl      DECIMAL(15,3)   NULL,       -- millones de barriles
    CONSTRAINT pk_dim_campo PRIMARY KEY (campo_id),
    CONSTRAINT uq_dim_campo_codigo UNIQUE (codigo_campo),
    CONSTRAINT fk_campo_cuenca FOREIGN KEY (cuenca_id) REFERENCES dim_cuenca(cuenca_id),
    CONSTRAINT ck_estado_campo CHECK (estado IN ('Exploracion','Desarrollo','Produccion','Abandono'))
);

-- ============================================================
-- DIMENSION: POZOS
-- ============================================================
CREATE TABLE dim_pozo (
    pozo_id             INT             NOT NULL IDENTITY(1,1),
    campo_id            INT             NOT NULL,
    codigo_pozo         VARCHAR(30)     NOT NULL,
    nombre_pozo         VARCHAR(100)    NOT NULL,
    tipo_pozo           VARCHAR(20)     NOT NULL,   -- 'Productor','Inyector','Exploratorio','Desviado'
    fecha_perforacion   DATE            NULL,
    profundidad_total_m INT             NULL,
    latitud             DECIMAL(10,7)   NULL,
    longitud            DECIMAL(10,7)   NULL,
    estado_pozo         VARCHAR(20)     NOT NULL,   -- 'Activo','Cerrado','Abandonado','Suspendido'
    CONSTRAINT pk_dim_pozo PRIMARY KEY (pozo_id),
    CONSTRAINT uq_dim_pozo_codigo UNIQUE (codigo_pozo),
    CONSTRAINT fk_pozo_campo FOREIGN KEY (campo_id) REFERENCES dim_campo(campo_id),
    CONSTRAINT ck_tipo_pozo CHECK (tipo_pozo IN ('Productor','Inyector','Exploratorio','Desviado')),
    CONSTRAINT ck_estado_pozo CHECK (estado_pozo IN ('Activo','Cerrado','Abandonado','Suspendido'))
);

-- ============================================================
-- DIMENSION: INSTALACIONES / FACILIDADES
-- ============================================================
CREATE TABLE dim_instalacion (
    instalacion_id      INT             NOT NULL IDENTITY(1,1),
    campo_id            INT             NOT NULL,
    nombre              VARCHAR(100)    NOT NULL,
    tipo                VARCHAR(30)     NOT NULL,   -- 'Plataforma','FPSO','Refineria','Terminal','Planta_Gas'
    capacidad_bpd       INT             NULL,       -- barriles por dia
    fecha_comisionado   DATE            NULL,
    CONSTRAINT pk_dim_instalacion PRIMARY KEY (instalacion_id),
    CONSTRAINT fk_inst_campo FOREIGN KEY (campo_id) REFERENCES dim_campo(campo_id),
    CONSTRAINT ck_tipo_inst CHECK (tipo IN ('Plataforma','FPSO','Refineria','Terminal','Planta_Gas'))
);

-- ============================================================
-- DIMENSION: PRODUCTOS
-- ============================================================
CREATE TABLE dim_producto (
    producto_id     INT             NOT NULL IDENTITY(1,1),
    codigo          VARCHAR(20)     NOT NULL,
    nombre          VARCHAR(80)     NOT NULL,
    categoria       VARCHAR(30)     NOT NULL,   -- 'CrudoPesado','CrudoLiviano','Gas','GLP','Gasolina','Diesel','Jet'
    api_gravity     DECIMAL(5,2)    NULL,
    azufre_pct      DECIMAL(5,3)    NULL,
    CONSTRAINT pk_dim_producto PRIMARY KEY (producto_id),
    CONSTRAINT uq_dim_producto_cod UNIQUE (codigo),
    CONSTRAINT ck_cat_producto CHECK (categoria IN ('CrudoPesado','CrudoLiviano','Gas','GLP','Gasolina','Diesel','Jet'))
);

-- ============================================================
-- DIMENSION: CLIENTES / CONTRAPARTES
-- ============================================================
CREATE TABLE dim_cliente (
    cliente_id      INT             NOT NULL IDENTITY(1,1),
    pais_id         INT             NOT NULL,
    razon_social    VARCHAR(150)    NOT NULL,
    tipo_cliente    VARCHAR(30)     NOT NULL,   -- 'Refineria','Trader','Distribuidor','Industrial','Gobierno'
    rfc_tax_id      VARCHAR(40)     NULL,
    activo_flag     BIT             NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_cliente PRIMARY KEY (cliente_id),
    CONSTRAINT fk_cliente_pais FOREIGN KEY (pais_id) REFERENCES dim_pais(pais_id),
    CONSTRAINT ck_tipo_cliente CHECK (tipo_cliente IN ('Refineria','Trader','Distribuidor','Industrial','Gobierno'))
);

-- ============================================================
-- DIMENSION: TIEMPO (calendario)
-- ============================================================
CREATE TABLE dim_tiempo (
    tiempo_id       INT             NOT NULL,   -- YYYYMMDD
    fecha           DATE            NOT NULL,
    anio            SMALLINT        NOT NULL,
    trimestre       TINYINT         NOT NULL,
    mes             TINYINT         NOT NULL,
    semana          TINYINT         NOT NULL,
    dia_semana      VARCHAR(10)     NOT NULL,
    es_fin_semana   BIT             NOT NULL DEFAULT 0,
    CONSTRAINT pk_dim_tiempo PRIMARY KEY (tiempo_id)
);

-- ============================================================
-- FACT: PRODUCCION DIARIA POR POZO
-- ============================================================
CREATE TABLE fact_produccion (
    produccion_id       INT             NOT NULL IDENTITY(1,1),
    tiempo_id           INT             NOT NULL,
    pozo_id             INT             NOT NULL,
    producto_id         INT             NOT NULL,
    instalacion_id      INT             NOT NULL,
    volumen_bruto_bpd   DECIMAL(12,3)   NOT NULL DEFAULT 0,  -- barriles/dia
    volumen_neto_bpd    DECIMAL(12,3)   NOT NULL DEFAULT 0,
    gas_asociado_mscfd  DECIMAL(12,3)   NULL,               -- miles pies cubicos/dia
    agua_bpd            DECIMAL(12,3)   NULL,
    bsw_pct             DECIMAL(5,2)    NULL,               -- Basic Sediment & Water %
    gor_scf_bbl         DECIMAL(10,2)   NULL,               -- Gas-Oil Ratio
    presion_cabezal_psi DECIMAL(8,2)    NULL,
    horas_operacion     DECIMAL(5,2)    NULL,
    CONSTRAINT pk_fact_prod PRIMARY KEY (produccion_id),
    CONSTRAINT uq_fact_prod UNIQUE (tiempo_id, pozo_id, producto_id),
    CONSTRAINT fk_fp_tiempo    FOREIGN KEY (tiempo_id)      REFERENCES dim_tiempo(tiempo_id),
    CONSTRAINT fk_fp_pozo      FOREIGN KEY (pozo_id)        REFERENCES dim_pozo(pozo_id),
    CONSTRAINT fk_fp_producto  FOREIGN KEY (producto_id)    REFERENCES dim_producto(producto_id),
    CONSTRAINT fk_fp_inst      FOREIGN KEY (instalacion_id) REFERENCES dim_instalacion(instalacion_id)
);

-- ============================================================
-- FACT: RESERVAS POR CAMPO Y PERIODO
-- ============================================================
CREATE TABLE fact_reservas (
    reserva_id          INT             NOT NULL IDENTITY(1,1),
    tiempo_id           INT             NOT NULL,   -- fecha de corte (31-dic)
    campo_id            INT             NOT NULL,
    producto_id         INT             NOT NULL,
    reservas_1p_mmbbl   DECIMAL(15,3)   NULL,       -- Probadas
    reservas_2p_mmbbl   DECIMAL(15,3)   NULL,       -- Probadas + Probables
    reservas_3p_mmbbl   DECIMAL(15,3)   NULL,       -- + Posibles
    recursos_contingentes_mmbbl DECIMAL(15,3) NULL,
    factor_recuperacion_pct DECIMAL(5,2) NULL,
    CONSTRAINT pk_fact_res PRIMARY KEY (reserva_id),
    CONSTRAINT uq_fact_res UNIQUE (tiempo_id, campo_id, producto_id),
    CONSTRAINT fk_fr_tiempo   FOREIGN KEY (tiempo_id)   REFERENCES dim_tiempo(tiempo_id),
    CONSTRAINT fk_fr_campo    FOREIGN KEY (campo_id)    REFERENCES dim_campo(campo_id),
    CONSTRAINT fk_fr_producto FOREIGN KEY (producto_id) REFERENCES dim_producto(producto_id)
);

-- ============================================================
-- FACT: VENTAS / LIFTING
-- ============================================================
CREATE TABLE fact_venta (
    venta_id            INT             NOT NULL IDENTITY(1,1),
    tiempo_id           INT             NOT NULL,
    cliente_id          INT             NOT NULL,
    producto_id         INT             NOT NULL,
    instalacion_id      INT             NOT NULL,
    campo_id            INT             NOT NULL,
    volumen_bbl         DECIMAL(15,3)   NOT NULL,
    precio_usd_bbl      DECIMAL(10,4)   NOT NULL,
    importe_usd         DECIMAL(18,2)   NOT NULL,
    precio_referencia   VARCHAR(20)     NULL,        -- 'Brent','WTI','Maya','Argus'
    descuento_usd_bbl   DECIMAL(8,4)    NULL,
    incoterm            VARCHAR(10)     NULL,        -- 'FOB','CIF','DES'
    CONSTRAINT pk_fact_venta PRIMARY KEY (venta_id),
    CONSTRAINT fk_fv_tiempo   FOREIGN KEY (tiempo_id)      REFERENCES dim_tiempo(tiempo_id),
    CONSTRAINT fk_fv_cliente  FOREIGN KEY (cliente_id)     REFERENCES dim_cliente(cliente_id),
    CONSTRAINT fk_fv_producto FOREIGN KEY (producto_id)    REFERENCES dim_producto(producto_id),
    CONSTRAINT fk_fv_inst     FOREIGN KEY (instalacion_id) REFERENCES dim_instalacion(instalacion_id),
    CONSTRAINT fk_fv_campo    FOREIGN KEY (campo_id)       REFERENCES dim_campo(campo_id)
);

-- ============================================================
-- FACT: COSTOS OPERATIVOS (OPEX)
-- ============================================================
CREATE TABLE fact_opex (
    opex_id             INT             NOT NULL IDENTITY(1,1),
    tiempo_id           INT             NOT NULL,
    campo_id            INT             NOT NULL,
    instalacion_id      INT             NOT NULL,
    categoria_costo     VARCHAR(40)     NOT NULL,   -- 'Mantenimiento','Personal','Energia','Quimica','Logistica'
    importe_usd         DECIMAL(18,2)   NOT NULL,
    costo_boe_usd       DECIMAL(8,4)    NULL,       -- USD por barril equivalente
    CONSTRAINT pk_fact_opex PRIMARY KEY (opex_id),
    CONSTRAINT fk_fo_tiempo FOREIGN KEY (tiempo_id)      REFERENCES dim_tiempo(tiempo_id),
    CONSTRAINT fk_fo_campo  FOREIGN KEY (campo_id)       REFERENCES dim_campo(campo_id),
    CONSTRAINT fk_fo_inst   FOREIGN KEY (instalacion_id) REFERENCES dim_instalacion(instalacion_id)
);

-- ============================================================
-- FACT: MANTENIMIENTO DE POZOS Y EQUIPOS
-- ============================================================
CREATE TABLE fact_mantenimiento (
    mant_id             INT             NOT NULL IDENTITY(1,1),
    tiempo_id           INT             NOT NULL,
    pozo_id             INT             NULL,
    instalacion_id      INT             NULL,
    tipo_trabajo        VARCHAR(40)     NOT NULL,   -- 'Workover','WellService','Overhaul','Inspeccion'
    duracion_dias       SMALLINT        NOT NULL,
    costo_usd           DECIMAL(18,2)   NOT NULL,
    produccion_diferida_bbl DECIMAL(15,3) NULL,
    resultado           VARCHAR(20)     NOT NULL,   -- 'Exitoso','Parcial','Fallido'
    CONSTRAINT pk_fact_mant PRIMARY KEY (mant_id),
    CONSTRAINT fk_fm_tiempo FOREIGN KEY (tiempo_id)      REFERENCES dim_tiempo(tiempo_id),
    CONSTRAINT fk_fm_pozo   FOREIGN KEY (pozo_id)        REFERENCES dim_pozo(pozo_id),
    CONSTRAINT fk_fm_inst   FOREIGN KEY (instalacion_id) REFERENCES dim_instalacion(instalacion_id)
);

-- ============================================================
-- INDICES
-- ============================================================
CREATE INDEX ix_prod_tiempo    ON fact_produccion(tiempo_id);
CREATE INDEX ix_prod_pozo      ON fact_produccion(pozo_id);
CREATE INDEX ix_prod_campo     ON fact_produccion(pozo_id);
CREATE INDEX ix_venta_cliente  ON fact_venta(cliente_id);
CREATE INDEX ix_venta_tiempo   ON fact_venta(tiempo_id);
CREATE INDEX ix_venta_campo    ON fact_venta(campo_id);
CREATE INDEX ix_opex_campo     ON fact_opex(campo_id);
CREATE INDEX ix_opex_tiempo    ON fact_opex(tiempo_id);
CREATE INDEX ix_mant_pozo      ON fact_mantenimiento(pozo_id);
CREATE INDEX ix_res_campo      ON fact_reservas(campo_id);
