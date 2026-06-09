-- ============================================================
-- PORTAFOLIO BI — RETAIL SALES ANALYTICS
-- SQL Server 2019 | Star Schema
-- ============================================================

-- ============================================================
-- DDL — MODELO DIMENSIONAL
-- ============================================================

CREATE TABLE dim_tiempo (
    tiempo_id   INT         NOT NULL,   -- YYYYMMDD
    fecha       DATE        NOT NULL,
    anio        SMALLINT    NOT NULL,
    trimestre   TINYINT     NOT NULL,
    mes_num     TINYINT     NOT NULL,
    mes_nombre  VARCHAR(15) NOT NULL,
    semana      TINYINT     NOT NULL,
    dia_semana  VARCHAR(10) NOT NULL,
    es_finde    BIT         NOT NULL DEFAULT 0,
    CONSTRAINT pk_dt PRIMARY KEY (tiempo_id)
);

CREATE TABLE dim_geografia (
    geo_id      INT         NOT NULL IDENTITY(1,1),
    region      VARCHAR(30) NOT NULL,
    ciudad      VARCHAR(60) NOT NULL,
    tienda      CHAR(7)     NOT NULL,
    CONSTRAINT pk_dg PRIMARY KEY (geo_id),
    CONSTRAINT uq_dg UNIQUE (tienda)
);

CREATE TABLE dim_producto (
    producto_id     INT             NOT NULL IDENTITY(1,1),
    categoria       VARCHAR(30)     NOT NULL,
    subcategoria    VARCHAR(30)     NOT NULL,
    producto        VARCHAR(100)    NOT NULL,
    precio_lista    DECIMAL(10,2)   NOT NULL,
    costo_std       DECIMAL(10,2)   NOT NULL,
    CONSTRAINT pk_dp PRIMARY KEY (producto_id)
);

CREATE TABLE dim_vendedor (
    vendedor_id     INT         NOT NULL IDENTITY(1,1),
    nombre          VARCHAR(80) NOT NULL,
    region          VARCHAR(30) NOT NULL,
    activo          BIT         NOT NULL DEFAULT 1,
    CONSTRAINT pk_dv PRIMARY KEY (vendedor_id)
);

CREATE TABLE dim_canal (
    canal_id    INT         NOT NULL IDENTITY(1,1),
    canal       VARCHAR(20) NOT NULL,   -- 'Online','Tienda'
    CONSTRAINT pk_dc PRIMARY KEY (canal_id),
    CONSTRAINT uq_dc UNIQUE (canal)
);

CREATE TABLE fact_venta (
    venta_id        INT             NOT NULL IDENTITY(1,1),
    tiempo_id       INT             NOT NULL,
    geo_id          INT             NOT NULL,
    producto_id     INT             NOT NULL,
    vendedor_id     INT             NOT NULL,
    canal_id        INT             NOT NULL,
    unidades        INT             NOT NULL,
    precio_unitario DECIMAL(10,2)   NOT NULL,
    descuento_pct   DECIMAL(5,2)    NOT NULL DEFAULT 0,
    costo_unitario  DECIMAL(10,2)   NOT NULL,
    -- Medidas calculadas
    importe_bruto   AS CAST(unidades * precio_unitario AS DECIMAL(14,2)),
    descuento_monto AS CAST(unidades * precio_unitario * descuento_pct / 100 AS DECIMAL(14,2)),
    importe_neto    AS CAST(unidades * precio_unitario * (1 - descuento_pct/100) AS DECIMAL(14,2)),
    costo_total     AS CAST(unidades * costo_unitario AS DECIMAL(14,2)),
    margen_bruto    AS CAST(unidades * (precio_unitario * (1-descuento_pct/100) - costo_unitario) AS DECIMAL(14,2)),
    CONSTRAINT pk_fv PRIMARY KEY (venta_id),
    CONSTRAINT fk_fv_t FOREIGN KEY (tiempo_id)   REFERENCES dim_tiempo(tiempo_id),
    CONSTRAINT fk_fv_g FOREIGN KEY (geo_id)      REFERENCES dim_geografia(geo_id),
    CONSTRAINT fk_fv_p FOREIGN KEY (producto_id) REFERENCES dim_producto(producto_id),
    CONSTRAINT fk_fv_v FOREIGN KEY (vendedor_id) REFERENCES dim_vendedor(vendedor_id),
    CONSTRAINT fk_fv_c FOREIGN KEY (canal_id)    REFERENCES dim_canal(canal_id)
);

CREATE INDEX ix_fv_tiempo    ON fact_venta(tiempo_id);
CREATE INDEX ix_fv_geo       ON fact_venta(geo_id);
CREATE INDEX ix_fv_producto  ON fact_venta(producto_id);
CREATE INDEX ix_fv_vendedor  ON fact_venta(vendedor_id);


-- ============================================================
-- QUERY 1: KPIs EJECUTIVOS — Ventas por mes con variacion YoY
-- ============================================================
SELECT
    t.anio,
    t.mes_num,
    t.mes_nombre,
    SUM(f.importe_neto)                         AS ventas_netas,
    SUM(f.margen_bruto)                         AS margen_bruto,
    ROUND(SUM(f.margen_bruto) * 100.0
          / NULLIF(SUM(f.importe_neto),0), 2)   AS margen_pct,
    SUM(f.unidades)                             AS unidades_vendidas,
    COUNT(DISTINCT f.venta_id)                  AS num_transacciones,
    SUM(f.importe_neto)
        / NULLIF(COUNT(DISTINCT f.venta_id),0)  AS ticket_promedio,
    LAG(SUM(f.importe_neto), 12) OVER (
        ORDER BY t.anio, t.mes_num)             AS ventas_anio_anterior,
    ROUND((SUM(f.importe_neto) - LAG(SUM(f.importe_neto),12)
           OVER (ORDER BY t.anio, t.mes_num))
          * 100.0
          / NULLIF(LAG(SUM(f.importe_neto),12)
           OVER (ORDER BY t.anio, t.mes_num),0), 2) AS variacion_yoy_pct
FROM fact_venta f
JOIN dim_tiempo t ON f.tiempo_id = t.tiempo_id
GROUP BY t.anio, t.mes_num, t.mes_nombre
ORDER BY t.anio, t.mes_num;


-- ============================================================
-- QUERY 2: TOP 10 PRODUCTOS — Pareto de ventas
-- ============================================================
WITH ventas_prod AS (
    SELECT
        dp.categoria,
        dp.subcategoria,
        dp.producto,
        SUM(f.importe_neto)     AS ventas_netas,
        SUM(f.margen_bruto)     AS margen_bruto,
        SUM(f.unidades)         AS unidades,
        ROUND(SUM(f.margen_bruto)*100.0
              /NULLIF(SUM(f.importe_neto),0),2) AS margen_pct
    FROM fact_venta f
    JOIN dim_producto dp ON f.producto_id = dp.producto_id
    GROUP BY dp.categoria, dp.subcategoria, dp.producto
),
total AS (SELECT SUM(ventas_netas) AS total_ventas FROM ventas_prod)
SELECT TOP 10
    vp.*,
    ROUND(vp.ventas_netas * 100.0 / t.total_ventas, 2)     AS pct_del_total,
    ROUND(SUM(vp.ventas_netas) OVER (
        ORDER BY vp.ventas_netas DESC
        ROWS UNBOUNDED PRECEDING) * 100.0 / t.total_ventas, 2) AS pct_acumulado
FROM ventas_prod vp
CROSS JOIN total t
ORDER BY vp.ventas_netas DESC;


-- ============================================================
-- QUERY 3: RENDIMIENTO POR VENDEDOR Y REGION
-- ============================================================
SELECT
    dv.nombre                                       AS vendedor,
    dv.region,
    SUM(f.importe_neto)                             AS ventas_netas,
    SUM(f.margen_bruto)                             AS margen_bruto,
    ROUND(SUM(f.margen_bruto)*100.0
          /NULLIF(SUM(f.importe_neto),0),2)         AS margen_pct,
    SUM(f.unidades)                                 AS unidades,
    COUNT(DISTINCT f.venta_id)                      AS transacciones,
    ROUND(SUM(f.importe_neto)
          /NULLIF(COUNT(DISTINCT f.venta_id),0),2)  AS ticket_promedio,
    RANK() OVER (ORDER BY SUM(f.importe_neto) DESC) AS ranking_ventas
FROM fact_venta f
JOIN dim_vendedor dv ON f.vendedor_id = dv.vendedor_id
GROUP BY dv.nombre, dv.region
ORDER BY ventas_netas DESC;


-- ============================================================
-- QUERY 4: ANALISIS CANAL Online vs Tienda
-- ============================================================
SELECT
    dc.canal,
    t.trimestre,
    t.anio,
    SUM(f.importe_neto)                             AS ventas_netas,
    SUM(f.unidades)                                 AS unidades,
    COUNT(DISTINCT f.venta_id)                      AS transacciones,
    ROUND(AVG(f.descuento_pct),2)                   AS descuento_promedio_pct,
    ROUND(SUM(f.importe_neto)*100.0
          /SUM(SUM(f.importe_neto)) OVER (
              PARTITION BY t.trimestre, t.anio),2)  AS mix_canal_pct
FROM fact_venta f
JOIN dim_canal dc  ON f.canal_id   = dc.canal_id
JOIN dim_tiempo t  ON f.tiempo_id  = t.tiempo_id
GROUP BY dc.canal, t.trimestre, t.anio
ORDER BY t.anio, t.trimestre, dc.canal;


-- ============================================================
-- QUERY 5: HEATMAP — Ventas por Region y Categoria
-- ============================================================
SELECT
    dg.region,
    dp.categoria,
    SUM(f.importe_neto)                             AS ventas_netas,
    ROUND(SUM(f.importe_neto)*100.0
          /SUM(SUM(f.importe_neto)) OVER (
              PARTITION BY dg.region),2)            AS pct_en_region
FROM fact_venta f
JOIN dim_geografia dg ON f.geo_id      = dg.geo_id
JOIN dim_producto  dp ON f.producto_id = dp.producto_id
GROUP BY dg.region, dp.categoria
ORDER BY dg.region, ventas_netas DESC;


-- ============================================================
-- QUERY 6: MARGEN POR CATEGORIA — Semaforo de rentabilidad
-- ============================================================
SELECT
    dp.categoria,
    SUM(f.importe_neto)                             AS ventas_netas,
    SUM(f.costo_total)                              AS costo_total,
    SUM(f.margen_bruto)                             AS margen_bruto,
    ROUND(SUM(f.margen_bruto)*100.0
          /NULLIF(SUM(f.importe_neto),0),2)         AS margen_pct,
    CASE
        WHEN SUM(f.margen_bruto)*100.0
             /NULLIF(SUM(f.importe_neto),0) >= 40  THEN 'Verde'
        WHEN SUM(f.margen_bruto)*100.0
             /NULLIF(SUM(f.importe_neto),0) >= 25  THEN 'Amarillo'
        ELSE 'Rojo'
    END                                             AS semaforo
FROM fact_venta f
JOIN dim_producto dp ON f.producto_id = dp.producto_id
GROUP BY dp.categoria
ORDER BY margen_pct DESC;
