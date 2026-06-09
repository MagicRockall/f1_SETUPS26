-- ============================================================
-- F1 SETUPS - Modelo de Datos DDL
-- Dominio: Motorsport / F1 Racing Analytics
-- BD Destino: SQL Server (compatible PostgreSQL con ajustes menores)
-- Generado: 2026-06-09
-- ============================================================

-- ============================================================
-- DIMENSION: TEMPORADAS
-- ============================================================
CREATE TABLE dim_season (
    season_id       INT             NOT NULL IDENTITY(1,1),
    year            SMALLINT        NOT NULL,
    regulation_era  VARCHAR(50)     NOT NULL,   -- e.g. 'Pre-2022', '2022-25', '2026+'
    max_points      SMALLINT        NOT NULL DEFAULT 26,
    active_flag     BIT             NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_season PRIMARY KEY (season_id),
    CONSTRAINT uq_dim_season_year UNIQUE (year)
);

-- ============================================================
-- DIMENSION: CIRCUITOS
-- ============================================================
CREATE TABLE dim_circuit (
    circuit_id      INT             NOT NULL IDENTITY(1,1),
    circuit_code    CHAR(3)         NOT NULL,   -- e.g. 'MON', 'SPA', 'SIL'
    circuit_name    VARCHAR(100)    NOT NULL,
    country         VARCHAR(60)     NOT NULL,
    city            VARCHAR(60)     NOT NULL,
    circuit_type    VARCHAR(20)     NOT NULL,   -- 'Street', 'Permanent', 'Hybrid'
    lap_length_km   DECIMAL(5,3)    NOT NULL,
    total_laps      SMALLINT        NULL,
    altitude_m      SMALLINT        NULL,
    CONSTRAINT pk_dim_circuit PRIMARY KEY (circuit_id),
    CONSTRAINT uq_dim_circuit_code UNIQUE (circuit_code),
    CONSTRAINT ck_circuit_type CHECK (circuit_type IN ('Street','Permanent','Hybrid'))
);

-- ============================================================
-- DIMENSION: CONSTRUCTORES (EQUIPOS)
-- ============================================================
CREATE TABLE dim_constructor (
    constructor_id      INT             NOT NULL IDENTITY(1,1),
    constructor_code    CHAR(3)         NOT NULL,   -- e.g. 'RBR', 'MER', 'FER'
    full_name           VARCHAR(100)    NOT NULL,
    nationality         VARCHAR(60)     NOT NULL,
    power_unit          VARCHAR(60)     NOT NULL,
    entry_season_year   SMALLINT        NOT NULL,
    active_flag         BIT             NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_constructor PRIMARY KEY (constructor_id),
    CONSTRAINT uq_dim_constructor_code UNIQUE (constructor_code)
);

-- ============================================================
-- DIMENSION: PILOTOS
-- ============================================================
CREATE TABLE dim_driver (
    driver_id           INT             NOT NULL IDENTITY(1,1),
    driver_code         CHAR(3)         NOT NULL,   -- e.g. 'VER', 'HAM', 'LEC'
    permanent_number    SMALLINT        NULL,
    first_name          VARCHAR(60)     NOT NULL,
    last_name           VARCHAR(60)     NOT NULL,
    nationality         VARCHAR(60)     NOT NULL,
    date_of_birth       DATE            NULL,
    active_flag         BIT             NOT NULL DEFAULT 1,
    CONSTRAINT pk_dim_driver PRIMARY KEY (driver_id),
    CONSTRAINT uq_dim_driver_code UNIQUE (driver_code)
);

-- ============================================================
-- BRIDGE: DRIVER <-> CONSTRUCTOR POR TEMPORADA (M:N resuelto)
-- ============================================================
CREATE TABLE bridge_driver_constructor (
    bridge_id           INT             NOT NULL IDENTITY(1,1),
    season_id           INT             NOT NULL,
    driver_id           INT             NOT NULL,
    constructor_id      INT             NOT NULL,
    car_number          TINYINT         NOT NULL,
    seat_role           VARCHAR(20)     NOT NULL DEFAULT 'Race',  -- 'Race','Reserve','Test'
    CONSTRAINT pk_bridge_drvcon PRIMARY KEY (bridge_id),
    CONSTRAINT uq_bridge_drvcon UNIQUE (season_id, driver_id),
    CONSTRAINT fk_bdc_season      FOREIGN KEY (season_id)      REFERENCES dim_season(season_id),
    CONSTRAINT fk_bdc_driver      FOREIGN KEY (driver_id)      REFERENCES dim_driver(driver_id),
    CONSTRAINT fk_bdc_constructor FOREIGN KEY (constructor_id) REFERENCES dim_constructor(constructor_id),
    CONSTRAINT ck_seat_role CHECK (seat_role IN ('Race','Reserve','Test'))
);

-- ============================================================
-- FACT: GRAN PREMIOS (EVENTOS)
-- ============================================================
CREATE TABLE fact_grand_prix (
    gp_id           INT             NOT NULL IDENTITY(1,1),
    season_id       INT             NOT NULL,
    circuit_id      INT             NOT NULL,
    round_number    TINYINT         NOT NULL,
    gp_name         VARCHAR(100)    NOT NULL,
    race_date       DATE            NOT NULL,
    weather_main    VARCHAR(30)     NULL,   -- 'Dry','Wet','Mixed'
    safety_car_laps TINYINT         NULL,
    vsc_laps        TINYINT         NULL,
    CONSTRAINT pk_fact_gp PRIMARY KEY (gp_id),
    CONSTRAINT uq_fact_gp UNIQUE (season_id, round_number),
    CONSTRAINT fk_fgp_season  FOREIGN KEY (season_id)  REFERENCES dim_season(season_id),
    CONSTRAINT fk_fgp_circuit FOREIGN KEY (circuit_id) REFERENCES dim_circuit(circuit_id)
);

-- ============================================================
-- FACT: CLASIFICACION (QUALIFYING)
-- ============================================================
CREATE TABLE fact_qualifying (
    qual_id             INT             NOT NULL IDENTITY(1,1),
    gp_id               INT             NOT NULL,
    driver_id           INT             NOT NULL,
    constructor_id      INT             NOT NULL,
    q1_time_ms          INT             NULL,
    q2_time_ms          INT             NULL,
    q3_time_ms          INT             NULL,
    best_time_ms        INT             NULL,
    grid_position       TINYINT         NOT NULL,
    eliminated_q1       BIT             NOT NULL DEFAULT 0,
    eliminated_q2       BIT             NOT NULL DEFAULT 0,
    CONSTRAINT pk_fact_qual PRIMARY KEY (qual_id),
    CONSTRAINT uq_fact_qual UNIQUE (gp_id, driver_id),
    CONSTRAINT fk_fq_gp          FOREIGN KEY (gp_id)          REFERENCES fact_grand_prix(gp_id),
    CONSTRAINT fk_fq_driver      FOREIGN KEY (driver_id)      REFERENCES dim_driver(driver_id),
    CONSTRAINT fk_fq_constructor FOREIGN KEY (constructor_id) REFERENCES dim_constructor(constructor_id)
);

-- ============================================================
-- FACT: RESULTADO DE CARRERA
-- ============================================================
CREATE TABLE fact_race_result (
    result_id           INT             NOT NULL IDENTITY(1,1),
    gp_id               INT             NOT NULL,
    driver_id           INT             NOT NULL,
    constructor_id      INT             NOT NULL,
    finish_position     TINYINT         NULL,   -- NULL = DNF/DNS
    grid_position       TINYINT         NOT NULL,
    points_scored       DECIMAL(5,2)    NOT NULL DEFAULT 0,
    laps_completed      SMALLINT        NOT NULL,
    race_time_ms        BIGINT          NULL,
    gap_to_leader_ms    INT             NULL,
    fastest_lap_flag    BIT             NOT NULL DEFAULT 0,
    dnf_reason          VARCHAR(60)     NULL,   -- 'Accident','Engine','Gearbox',etc.
    pit_stop_count      TINYINT         NULL,
    CONSTRAINT pk_fact_rr PRIMARY KEY (result_id),
    CONSTRAINT uq_fact_rr UNIQUE (gp_id, driver_id),
    CONSTRAINT fk_frr_gp          FOREIGN KEY (gp_id)          REFERENCES fact_grand_prix(gp_id),
    CONSTRAINT fk_frr_driver      FOREIGN KEY (driver_id)      REFERENCES dim_driver(driver_id),
    CONSTRAINT fk_frr_constructor FOREIGN KEY (constructor_id) REFERENCES dim_constructor(constructor_id)
);

-- ============================================================
-- FACT: SETUPS DE COCHE (core del repositorio)
-- ============================================================
CREATE TABLE fact_car_setup (
    setup_id                INT             NOT NULL IDENTITY(1,1),
    gp_id                   INT             NOT NULL,
    constructor_id          INT             NOT NULL,
    session_type            VARCHAR(20)     NOT NULL,  -- 'FP1','FP2','FP3','Q','R','Sprint'
    -- Aerodynamics
    front_wing_angle        DECIMAL(5,2)    NULL,
    rear_wing_angle         DECIMAL(5,2)    NULL,
    -- Suspension
    front_suspension        TINYINT         NULL,  -- 1-11 stiffness scale
    rear_suspension         TINYINT         NULL,
    front_anti_roll_bar     TINYINT         NULL,
    rear_anti_roll_bar      TINYINT         NULL,
    front_ride_height_mm    DECIMAL(4,1)    NULL,
    rear_ride_height_mm     DECIMAL(4,1)    NULL,
    -- Transmission
    differential_on_throttle    TINYINT     NULL,  -- % 50-100
    differential_off_throttle   TINYINT     NULL,  -- % 50-100
    -- Brakes
    brake_pressure_pct      TINYINT         NULL,  -- % 80-100
    brake_bias_pct          DECIMAL(4,1)    NULL,  -- % front bias
    -- Tyres
    tyre_compound           VARCHAR(10)     NULL,  -- 'Soft','Medium','Hard','Inter','Wet'
    front_camber_deg        DECIMAL(4,2)    NULL,
    rear_camber_deg         DECIMAL(4,2)    NULL,
    front_toe_deg           DECIMAL(4,3)    NULL,
    rear_toe_deg            DECIMAL(4,3)    NULL,
    front_tyre_pressure_psi DECIMAL(4,1)    NULL,
    rear_tyre_pressure_psi  DECIMAL(4,1)    NULL,
    -- Metadata
    source                  VARCHAR(30)     NULL,   -- 'Official','Community','Estimated'
    notes                   NVARCHAR(500)   NULL,
    created_at              DATETIME2       NOT NULL DEFAULT GETDATE(),
    CONSTRAINT pk_fact_setup PRIMARY KEY (setup_id),
    CONSTRAINT fk_fcs_gp          FOREIGN KEY (gp_id)          REFERENCES fact_grand_prix(gp_id),
    CONSTRAINT fk_fcs_constructor FOREIGN KEY (constructor_id) REFERENCES dim_constructor(constructor_id),
    CONSTRAINT ck_session_type    CHECK (session_type IN ('FP1','FP2','FP3','Q','R','Sprint')),
    CONSTRAINT ck_tyre_compound   CHECK (tyre_compound IN ('Soft','Medium','Hard','Inter','Wet'))
);

-- ============================================================
-- FACT: PIT STOPS DETALLE
-- ============================================================
CREATE TABLE fact_pit_stop (
    pit_stop_id         INT             NOT NULL IDENTITY(1,1),
    gp_id               INT             NOT NULL,
    driver_id           INT             NOT NULL,
    stop_number         TINYINT         NOT NULL,
    lap_number          TINYINT         NOT NULL,
    pit_duration_ms     INT             NOT NULL,
    tyre_in             VARCHAR(10)     NOT NULL,
    tyre_out            VARCHAR(10)     NOT NULL,
    CONSTRAINT pk_fact_pit PRIMARY KEY (pit_stop_id),
    CONSTRAINT uq_fact_pit UNIQUE (gp_id, driver_id, stop_number),
    CONSTRAINT fk_fps_gp     FOREIGN KEY (gp_id)     REFERENCES fact_grand_prix(gp_id),
    CONSTRAINT fk_fps_driver FOREIGN KEY (driver_id) REFERENCES dim_driver(driver_id),
    CONSTRAINT ck_tyre_in  CHECK (tyre_in  IN ('Soft','Medium','Hard','Inter','Wet')),
    CONSTRAINT ck_tyre_out CHECK (tyre_out IN ('Soft','Medium','Hard','Inter','Wet'))
);

-- ============================================================
-- FACT: CAMPEONATO (STANDINGS ACUMULADOS)
-- ============================================================
CREATE TABLE fact_championship_standing (
    standing_id         INT             NOT NULL IDENTITY(1,1),
    season_id           INT             NOT NULL,
    after_round         TINYINT         NOT NULL,
    driver_id           INT             NOT NULL,
    constructor_id      INT             NOT NULL,
    driver_points       DECIMAL(7,2)    NOT NULL DEFAULT 0,
    driver_position     TINYINT         NOT NULL,
    constructor_points  DECIMAL(7,2)    NOT NULL DEFAULT 0,
    constructor_position TINYINT        NOT NULL,
    CONSTRAINT pk_fact_cs PRIMARY KEY (standing_id),
    CONSTRAINT uq_fact_cs UNIQUE (season_id, after_round, driver_id),
    CONSTRAINT fk_fcs2_season      FOREIGN KEY (season_id)      REFERENCES dim_season(season_id),
    CONSTRAINT fk_fcs2_driver      FOREIGN KEY (driver_id)      REFERENCES dim_driver(driver_id),
    CONSTRAINT fk_fcs2_constructor FOREIGN KEY (constructor_id) REFERENCES dim_constructor(constructor_id)
);

-- ============================================================
-- INDICES DE RENDIMIENTO
-- ============================================================
CREATE INDEX ix_factgp_season    ON fact_grand_prix(season_id);
CREATE INDEX ix_factgp_circuit   ON fact_grand_prix(circuit_id);
CREATE INDEX ix_factrr_driver    ON fact_race_result(driver_id);
CREATE INDEX ix_factrr_gp        ON fact_race_result(gp_id);
CREATE INDEX ix_factsetup_gp     ON fact_car_setup(gp_id);
CREATE INDEX ix_factsetup_con    ON fact_car_setup(constructor_id);
CREATE INDEX ix_factpit_driver   ON fact_pit_stop(driver_id);
CREATE INDEX ix_factcs_season    ON fact_championship_standing(season_id);
CREATE INDEX ix_bridge_con       ON bridge_driver_constructor(constructor_id);
