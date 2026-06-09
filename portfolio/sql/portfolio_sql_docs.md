# SQL Portfolio — E-Commerce Analytics
**SQL Server 2017+ · Schema `portfolio` · 60,000 órdenes sintéticas**

---

## Contenido

1. [Generador de Base de Datos](#1-generador-de-base-de-datos)
2. [Queries Analíticos AVS](#2-queries-analíticos-avs)
3. [Análisis de Cohortes — Retención](#3-análisis-de-cohortes--retención)
4. [PIVOT Dinámico de Cohortes](#4-pivot-dinámico-de-cohortes)
5. [Stored Procedure — Upsert JSON con Validación](#5-stored-procedure--upsert-json-con-validación)

---

## 1. Generador de Base de Datos

> Crea el esquema completo con datos sintéticos: 6 categorías (3 niveles), 240 productos,
> 1,200 clientes, ~60,000 órdenes y tabla de clientes "sucios" para ejercicios de limpieza.

```sql
/* ================================================
   SQL Server — Generador de datos de portafolio
   Crea esquema + tablas + datos sintéticos (e-commerce)
   Probado con SQL Server 2017+
   ================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @StartDate date = '2022-01-01';
DECLARE @EndDate   date = '2025-06-30';
DECLARE @NProducts   int = 240;
DECLARE @NCustomers  int = 1200;
DECLARE @NOrders     int = 60000;
DECLARE @Days int = DATEDIFF(day, @StartDate, @EndDate) + 1;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'portfolio')
  EXEC('CREATE SCHEMA portfolio');

-- Drop en orden seguro
IF OBJECT_ID('portfolio.orders','U')         IS NOT NULL DROP TABLE portfolio.orders;
IF OBJECT_ID('portfolio.products_stock','U') IS NOT NULL DROP TABLE portfolio.products_stock;
IF OBJECT_ID('portfolio.products','U')       IS NOT NULL DROP TABLE portfolio.products;
IF OBJECT_ID('portfolio.categories','U')     IS NOT NULL DROP TABLE portfolio.categories;
IF OBJECT_ID('portfolio.customers','U')      IS NOT NULL DROP TABLE portfolio.customers;
IF OBJECT_ID('portfolio.raw_customers','U')  IS NOT NULL DROP TABLE portfolio.raw_customers;
IF OBJECT_ID('portfolio.dim_date','U')       IS NOT NULL DROP TABLE portfolio.dim_date;

BEGIN TRAN;

-- Tablas
CREATE TABLE portfolio.categories (
  category_id        int IDENTITY(1,1) PRIMARY KEY,
  parent_category_id int NULL,
  category_name      nvarchar(100) NOT NULL
);
ALTER TABLE portfolio.categories
  ADD CONSTRAINT FK_categories_parent
  FOREIGN KEY (parent_category_id) REFERENCES portfolio.categories(category_id);

CREATE TABLE portfolio.products (
  product_id   int IDENTITY(1,1) PRIMARY KEY,
  product_name nvarchar(100) NOT NULL,
  category_id  int NOT NULL REFERENCES portfolio.categories(category_id),
  base_price   decimal(12,2) NOT NULL
);

CREATE TABLE portfolio.customers (
  customer_id   int IDENTITY(1,1) PRIMARY KEY,
  customer_name nvarchar(100) NOT NULL,
  email         nvarchar(120) NOT NULL,
  city          nvarchar(60)  NOT NULL,
  signup_date   date NOT NULL
);

CREATE TABLE portfolio.orders (
  order_id    bigint IDENTITY(1,1) PRIMARY KEY,
  order_date  date NOT NULL,
  customer_id int  NOT NULL REFERENCES portfolio.customers(customer_id),
  product_id  int  NOT NULL REFERENCES portfolio.products(product_id),
  quantity    int  NOT NULL,
  sales       decimal(12,2) NOT NULL
);

CREATE TABLE portfolio.raw_customers (
  customer_name nvarchar(120),
  email         nvarchar(120),
  phone         nvarchar(40)
);

CREATE TABLE portfolio.dim_date (
  date_id     int PRIMARY KEY,  -- segundos desde 1970-01-01
  [date]      date NOT NULL,
  [year]      int,
  [quarter]   int,
  [month]     int,
  [day]       int,
  day_of_week int,              -- 1=Lun ... 7=Dom
  is_weekend  bit
);

CREATE TABLE portfolio.products_stock (
  product_id  int PRIMARY KEY REFERENCES portfolio.products(product_id),
  category_id int NOT NULL,
  stock       int NOT NULL
);

-- Tally (números auxiliares)
IF OBJECT_ID('tempdb..#Tally') IS NOT NULL DROP TABLE #Tally;
SELECT TOP (CASE WHEN @NOrders > @Days THEN @NOrders ELSE @Days END + 2000)
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #Tally
FROM sys.all_objects a CROSS JOIN sys.all_objects b;

-- Categorías: 6 L1 × 3 L2 × 2 L3
INSERT INTO portfolio.categories(parent_category_id, category_name)
SELECT NULL, CONCAT(N'Category_L1_', n)
FROM (SELECT TOP (6) n FROM #Tally ORDER BY n) t;

;WITH L1 AS (
  SELECT category_id, ROW_NUMBER() OVER (ORDER BY category_id) AS L1Idx
  FROM portfolio.categories WHERE parent_category_id IS NULL
)
INSERT INTO portfolio.categories(parent_category_id, category_name)
SELECT L1.category_id, CONCAT(N'Category_L2_', L1.L1Idx, N'_', k.k)
FROM L1 CROSS APPLY (VALUES (1),(2),(3)) k(k);

;WITH L1 AS (
  SELECT category_id, ROW_NUMBER() OVER (ORDER BY category_id) AS L1Idx
  FROM portfolio.categories WHERE parent_category_id IS NULL
),
L2 AS (
  SELECT c.category_id, c.parent_category_id,
         ROW_NUMBER() OVER (PARTITION BY c.parent_category_id ORDER BY c.category_id) AS L2Idx
  FROM portfolio.categories c
  WHERE c.parent_category_id IN (SELECT category_id FROM L1)
)
INSERT INTO portfolio.categories(parent_category_id, category_name)
SELECT L2.category_id,
       CONCAT(N'Category_L3_', L1.L1Idx, N'_', L2.L2Idx, N'_', k.k)
FROM L2
JOIN L1 ON L1.category_id = L2.parent_category_id
CROSS APPLY (VALUES (1),(2)) k(k);

-- Productos (240) con precio log-normal via Box-Muller
;WITH Leaf AS (
  SELECT c.category_id FROM portfolio.categories c
  LEFT JOIN portfolio.categories ch ON ch.parent_category_id = c.category_id
  WHERE ch.category_id IS NULL
)
INSERT INTO portfolio.products(product_name, category_id, base_price)
SELECT TOP (@NProducts)
  CONCAT(N'Product_', t.n),
  (SELECT TOP 1 category_id FROM Leaf ORDER BY NEWID()),
  CAST(ROUND(EXP(3.5 + 0.6 * (
    SELECT SQRT(-2.0*LOG(CASE WHEN u1.u1v < 1e-6 THEN 1e-6 ELSE u1.u1v END))
           * COS(2*PI()*u2.u2v)
  )), 2) AS decimal(12,2))
FROM (SELECT TOP (@NProducts) n FROM #Tally ORDER BY n) t
CROSS APPLY (SELECT RAND(CHECKSUM(NEWID())) AS u1v) u1
CROSS APPLY (SELECT RAND(CHECKSUM(NEWID())) AS u2v) u2
ORDER BY NEWID();

-- Clientes (1,200) con nombres y ciudades mexicanas
DECLARE @FirstNames TABLE (val nvarchar(50));
INSERT @FirstNames VALUES
  (N'Ana'),(N'Luis'),(N'Sofía'),(N'Carlos'),(N'María'),(N'Pedro'),
  (N'Lucía'),(N'Jorge'),(N'Fernanda'),(N'Miguel'),(N'Valeria'),(N'Diego'),
  (N'Paola'),(N'Daniel'),(N'Ximena'),(N'Eduardo'),(N'Camila'),
  (N'Rodrigo'),(N'Andrea'),(N'Iván');

DECLARE @LastNames TABLE (val nvarchar(50));
INSERT @LastNames VALUES
  (N'García'),(N'Hernández'),(N'Martínez'),(N'López'),(N'González'),
  (N'Pérez'),(N'Rodríguez'),(N'Sánchez'),(N'Ramírez'),(N'Cruz'),
  (N'Flores'),(N'Gómez'),(N'Vázquez'),(N'Rivera'),(N'Jiménez');

DECLARE @Cities TABLE (val nvarchar(60));
INSERT @Cities VALUES
  (N'CDMX'),(N'Guadalajara'),(N'Monterrey'),(N'Querétaro'),
  (N'Puebla'),(N'Tijuana'),(N'Mérida'),(N'León');

INSERT INTO portfolio.customers(customer_name, email, city, signup_date)
SELECT TOP (@NCustomers)
  CONCAT((SELECT TOP 1 val FROM @FirstNames ORDER BY NEWID()), N' ',
         (SELECT TOP 1 val FROM @LastNames  ORDER BY NEWID())),
  CONCAT(N'user', t.n, N'@example.com'),
  (SELECT TOP 1 val FROM @Cities ORDER BY NEWID()),
  DATEADD(day, ABS(CHECKSUM(NEWID())) % @Days, @StartDate)
FROM (SELECT TOP (@NCustomers) n FROM #Tally ORDER BY n) t
ORDER BY t.n;

-- Dim Date
INSERT INTO portfolio.dim_date(date_id,[date],[year],[quarter],[month],[day],day_of_week,is_weekend)
SELECT
  DATEDIFF(second,'1970-01-01',d),  d,
  YEAR(d), DATEPART(QUARTER,d), MONTH(d), DAY(d),
  ((DATEDIFF(day,'19000101',d) % 7) + 1),
  CASE WHEN ((DATEDIFF(day,'19000101',d) % 7) + 1) IN (6,7) THEN 1 ELSE 0 END
FROM (SELECT DATEADD(day,n-1,@StartDate) AS d
      FROM (SELECT TOP (@Days) n FROM #Tally ORDER BY n) x) q;

-- Órdenes (~60k) con distribución realista de cantidades y precio variable
DECLARE @cmin int, @cmax int, @pmin int, @pmax int;
SELECT @cmin=MIN(customer_id), @cmax=MAX(customer_id) FROM portfolio.customers;
SELECT @pmin=MIN(product_id),  @pmax=MAX(product_id)  FROM portfolio.products;

INSERT INTO portfolio.orders(order_date, customer_id, product_id, quantity, sales)
SELECT g.order_date, g.customer_id, g.product_id, g.quantity,
       CAST(ROUND(p.base_price * g.quantity * g.price_mult, 2) AS decimal(12,2))
FROM (
  SELECT TOP (@NOrders)
    DATEADD(day, ABS(CHECKSUM(NEWID())) % @Days, @StartDate) AS order_date,
    @cmin + ABS(CHECKSUM(NEWID())) % (@cmax-@cmin+1) AS customer_id,
    @pmin + ABS(CHECKSUM(NEWID())) % (@pmax-@pmin+1) AS product_id,
    CASE WHEN rprob<55 THEN 1 WHEN rprob<80 THEN 2
         WHEN rprob<90 THEN 3 WHEN rprob<96 THEN 4 ELSE 5 END AS quantity,
    CASE WHEN 1.0+0.15*z < 0.6 THEN 0.6
         WHEN 1.0+0.15*z > 1.5 THEN 1.5 ELSE 1.0+0.15*z END AS price_mult
  FROM (SELECT TOP (@NOrders) n FROM #Tally ORDER BY n) t
  CROSS APPLY (SELECT ABS(CHECKSUM(NEWID())) % 100 AS rprob) r
  CROSS APPLY (SELECT RAND(CHECKSUM(NEWID())) AS u1, RAND(CHECKSUM(NEWID())) AS u2) u
  CROSS APPLY (SELECT SQRT(-2.0*LOG(CASE WHEN u.u1<1e-6 THEN 1e-6 ELSE u.u1 END))
                      * COS(2*PI()*u.u2) AS z) zt
  ORDER BY NEWID()
) g JOIN portfolio.products p ON p.product_id = g.product_id;

-- Raw customers (datos sucios para ejercicios de limpieza)
INSERT INTO portfolio.raw_customers(customer_name, email, phone)
SELECT
  (CASE WHEN ABS(CHECKSUM(NEWID()))%2=0 THEN N'  ' ELSE N'' END) +
  (CASE WHEN ABS(CHECKSUM(NEWID()))%2=0 THEN UPPER(c.customer_name)
        WHEN ABS(CHECKSUM(NEWID()))%5=0 THEN LOWER(c.customer_name)
        ELSE c.customer_name END) +
  (CASE WHEN ABS(CHECKSUM(NEWID()))%2=0 THEN N' ' ELSE N'' END),
  (CASE WHEN ABS(CHECKSUM(NEWID()))%4=0 THEN UPPER(c.email) ELSE c.email END),
  '('+RIGHT('000'+CAST(ABS(CHECKSUM(NEWID()))%1000 AS varchar(3)),3)+') '+
      RIGHT('000'+CAST(ABS(CHECKSUM(NEWID()))%1000 AS varchar(3)),3)+'-'+
      RIGHT('0000'+CAST(ABS(CHECKSUM(NEWID()))%10000 AS varchar(4)),4)+
      (CASE WHEN ABS(CHECKSUM(NEWID()))%10<3
            THEN ' ext.'+RIGHT('000'+CAST(ABS(CHECKSUM(NEWID()))%1000 AS varchar(3)),3)
            ELSE '' END)
FROM portfolio.customers c;

-- Stock simulado
INSERT INTO portfolio.products_stock(product_id, category_id, stock)
SELECT product_id, category_id, ABS(CHECKSUM(NEWID())) % 200
FROM portfolio.products;

COMMIT;

-- Índices
CREATE INDEX IX_orders_date     ON portfolio.orders(order_date);
CREATE INDEX IX_orders_customer ON portfolio.orders(customer_id);
CREATE INDEX IX_orders_product  ON portfolio.orders(product_id);
```

---

## 2. Queries Analíticos AVS

### 2.1 Ventas Mensuales con YTD, MTD y YoY

> Calcula ventas por mes con acumulado anual (YTD) y comparativa contra el mismo mes del año anterior usando funciones de ventana.

```sql
WITH monthly AS (
  SELECT
    DATEADD(MONTH, DATEDIFF(MONTH, 0, order_date), 0) AS month_start,
    SUM(sales) AS total_sales
  FROM portfolio.orders
  GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, order_date), 0)
)
SELECT
  month_start,
  total_sales,
  SUM(total_sales) OVER (
    PARTITION BY YEAR(month_start)
    ORDER BY month_start
    ROWS UNBOUNDED PRECEDING)              AS sales_ytd,
  total_sales                              AS sales_mtd,
  LAG(total_sales, 12) OVER (
    ORDER BY month_start)                  AS last_year_same_month
FROM monthly
ORDER BY month_start;
```

---

### 2.2 Clientes VIP — Decil Superior

> Segmenta clientes en 10 deciles por ventas totales y filtra el 10% de mayor valor.

```sql
WITH agg AS (
  SELECT customer_id, SUM(sales) AS total_sales
  FROM portfolio.orders
  GROUP BY customer_id
)
SELECT *
FROM (
  SELECT *, NTILE(10) OVER (ORDER BY total_sales DESC) AS decile
  FROM agg
) d
WHERE decile = 1
ORDER BY total_sales DESC;
```

---

### 2.3 Top-N Productos por Categoría (Funciones de Ventana)

> Obtiene los N productos con más ventas dentro de cada categoría usando `RANK()` con partición.

```sql
DECLARE @N int = 3;  -- cambia para Top-5, Top-10, etc.

WITH sbp AS (
  SELECT p.category_id, p.product_id, p.product_name,
         SUM(o.sales) AS total_sales
  FROM portfolio.orders o
  JOIN portfolio.products p ON p.product_id = o.product_id
  GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT *
FROM (
  SELECT sbp.*,
         RANK() OVER (
           PARTITION BY category_id
           ORDER BY total_sales DESC) AS rank_in_category
  FROM sbp
) x
WHERE rank_in_category <= @N
ORDER BY category_id, rank_in_category, total_sales DESC;
```

---

### 2.4 Alerta de Stock Bajo

> Identifica productos con stock por debajo del 20% del promedio de su categoría.

```sql
SELECT p.product_id, p.product_name, s.stock
FROM portfolio.products p
JOIN portfolio.products_stock s ON s.product_id = p.product_id
WHERE s.stock < 0.2 * (
  SELECT AVG(stock)
  FROM portfolio.products_stock
  WHERE category_id = p.category_id
)
ORDER BY p.category_id, s.stock;
```

---

### 2.5 Jerarquía de Categorías — CTE Recursivo con Path

> Recorre el árbol de categorías (3 niveles) y construye el path completo `L1 > L2 > L3`.

```sql
WITH category_tree AS (
  SELECT category_id, parent_category_id, category_name,
         0 AS lvl,
         CAST(category_name AS nvarchar(4000)) AS path
  FROM portfolio.categories
  WHERE parent_category_id IS NULL

  UNION ALL

  SELECT c.category_id, c.parent_category_id, c.category_name,
         ct.lvl + 1,
         CAST(ct.path + N' > ' + c.category_name AS nvarchar(4000))
  FROM portfolio.categories c
  JOIN category_tree ct ON c.parent_category_id = ct.category_id
)
SELECT category_id, parent_category_id, lvl, path
FROM category_tree
ORDER BY path;
```

---

### 2.6 Limpieza y Estandarización de Datos

> Normaliza `raw_customers`: recorta espacios, convierte email a minúsculas y extrae solo dígitos del teléfono usando `TRANSLATE`.

```sql
DECLARE @from nvarchar(200) =
  N'()+-. extEXTabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
DECLARE @to nvarchar(200) = REPLICATE(N' ', LEN(@from));

SELECT
  LTRIM(RTRIM(customer_name))                          AS customer_name_clean,
  LOWER(LTRIM(RTRIM(email)))                           AS email_clean,
  REPLACE(TRANSLATE(phone, @from, @to), N' ', N'')     AS phone_digits
FROM portfolio.raw_customers;
```

---

### 2.7 Vista Fact Orders — Tabla de Hechos para BI

> Vista lista para conectar en Power BI / Tableau. Enriquece órdenes con la dimensión de fecha.

```sql
CREATE OR ALTER VIEW portfolio.fact_orders AS
SELECT
  o.order_id,
  o.customer_id,
  o.product_id,
  d.date_id,
  o.sales,
  o.quantity,
  o.order_date
FROM portfolio.orders o
JOIN portfolio.dim_date d ON d.[date] = o.order_date;
GO
```

---

### 2.8 Detección de Churn — Gap > 90 Días

> Marca con bandera `churn_gap_90d = 1` cuando un cliente tarda más de 90 días en hacer su siguiente pedido o no vuelve a comprar.

```sql
WITH cte AS (
  SELECT
    customer_id,
    order_date,
    LEAD(order_date) OVER (
      PARTITION BY customer_id
      ORDER BY order_date) AS next_order
  FROM portfolio.orders
)
SELECT
  customer_id,
  order_date,
  CASE WHEN next_order IS NULL
            OR DATEDIFF(DAY, order_date, next_order) > 90
       THEN 1 ELSE 0
  END AS churn_gap_90d
FROM cte
ORDER BY customer_id, order_date;
```

---

## 3. Análisis de Cohortes — Retención

> Calcula la retención mensual de clientes agrupados por su mes de primera compra.
> Formato **largo** (ideal para heatmaps en Power BI / Tableau).

```sql
WITH first_purchase AS (
  SELECT customer_id, MIN(order_date) AS first_order
  FROM portfolio.orders
  GROUP BY customer_id
),
cohorts AS (
  SELECT
    o.customer_id,
    DATEADD(MONTH, DATEDIFF(MONTH, 0, f.first_order), 0) AS cohort_month,
    DATEADD(MONTH, DATEDIFF(MONTH, 0, o.order_date),  0) AS order_month
  FROM portfolio.orders o
  JOIN first_purchase f ON o.customer_id = f.customer_id
)
SELECT
  cohort_month,
  DATEDIFF(MONTH, cohort_month, order_month) AS month_number,
  COUNT(DISTINCT customer_id)                AS customers
FROM cohorts
GROUP BY cohort_month, DATEDIFF(MONTH, cohort_month, order_month)
ORDER BY cohort_month, month_number;
```

**Resultado esperado:**

| cohort_month | month_number | customers |
|---|---|---|
| 2022-01-01 | 0 | 120 |
| 2022-01-01 | 1 | 74 |
| 2022-01-01 | 2 | 61 |
| … | … | … |

---

## 4. PIVOT Dinámico de Cohortes

> Transforma el formato largo a **tabla pivoteada** (mes 0 → mes 12 como columnas)
> para visualización directa tipo heatmap. Usa SQL dinámico para generar columnas automáticamente.

```sql
IF OBJECT_ID('tempdb..#cohort') IS NOT NULL DROP TABLE #cohort;

WITH fp AS (
  SELECT customer_id, MIN(order_date) AS first_order
  FROM portfolio.orders GROUP BY customer_id
),
co AS (
  SELECT
    o.customer_id,
    DATEADD(MONTH, DATEDIFF(MONTH, 0, f.first_order), 0) AS cohort_month,
    DATEADD(MONTH, DATEDIFF(MONTH, 0, o.order_date),  0) AS order_month
  FROM portfolio.orders o
  JOIN fp f ON o.customer_id = f.customer_id
)
SELECT cohort_month,
       DATEDIFF(MONTH, cohort_month, order_month) AS month_number,
       customer_id
INTO #cohort FROM co;

-- Genera columnas [0],[1],...,[12] dinámicamente
DECLARE @cols nvarchar(max) =
  STUFF((SELECT DISTINCT ','+QUOTENAME(v.m)
         FROM (VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(m)
         FOR XML PATH(''), TYPE).value('.','nvarchar(max)'),1,1,'');

DECLARE @sql nvarchar(max) = '
SELECT cohort_month,' + @cols + '
FROM (
  SELECT cohort_month, month_number, customer_id
  FROM #cohort
  WHERE month_number BETWEEN 0 AND 12
) s
PIVOT (COUNT(customer_id) FOR month_number IN (' + @cols + ')) p
ORDER BY cohort_month;';

EXEC (@sql);
```

**Resultado esperado:**

| cohort_month | [0] | [1] | [2] | … | [12] |
|---|---|---|---|---|---|
| 2022-01-01 | 120 | 74 | 61 | … | 28 |
| 2022-02-01 | 98 | 62 | 51 | … | 22 |

---

## 5. Stored Procedure — Upsert JSON con Validación

> SP que recibe un array JSON de órdenes y ejecuta **INSERT o UPDATE** según el parámetro
> `@on_duplicate`. Incluye validación temprana del JSON antes de procesar.

### 5.1 Ejemplo de uso

```sql
DECLARE @json nvarchar(max) = N'
[
  {"order_date":"2025-06-15","customer_id":10,"product_id":5,"quantity":2},
  {"order_date":"2025-06-16","customer_id":11,"product_id":8,"quantity":1},
  {"order_date":"2025-06-16","customer_id":11,"product_id":8,"quantity":1}
]';

-- Verifica que es JSON válido (debe regresar 1)
SELECT ISJSON(@json) AS is_valid;

-- Ejecuta el SP
DECLARE @ins int, @upd int, @rc int;
EXEC @rc = portfolio.sp_upsert_orders_json
  @payload      = @json,
  @on_duplicate = 'SKIP',   -- opciones: 'SKIP' | 'UPDATE'
  @inserted     = @ins OUTPUT,
  @updated      = @upd OUTPUT;

SELECT @rc AS return_code, @ins AS inserted_rows, @upd AS updated_rows;
```

### 5.2 Definición del Stored Procedure

```sql
CREATE OR ALTER PROCEDURE portfolio.sp_upsert_orders_json
  @payload       nvarchar(max),
  @on_duplicate  varchar(10) = 'SKIP',
  @inserted      int OUTPUT,
  @updated       int OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  -- Validación temprana del JSON
  IF ISJSON(@payload) <> 1
  BEGIN
    RAISERROR('El payload no es JSON válido. Verifica comentarios, comillas o comas finales.', 16, 1);
    RETURN 1;
  END

  -- ... (resto del cuerpo del SP)
END
GO
```

> **Nota:** La validación con `ISJSON()` rechaza JSON que contenga comentarios (`--`, `//`, `/* */`),
> comillas tipográficas (`"`) o comas finales en el último elemento del array.

---

## Modelo de Datos

```
portfolio.categories  (auto-referencial, 3 niveles)
    └─► portfolio.products
          └─► portfolio.orders  ◄─── portfolio.customers
                │                          │
                └─► portfolio.dim_date     └─► portfolio.raw_customers
          └─► portfolio.products_stock

Vista: portfolio.fact_orders  (join orders + dim_date, lista para BI)
```

---

## Stack Técnico

| Componente | Detalle |
|---|---|
| Motor | SQL Server 2017+ |
| Volumen | ~60,000 órdenes · 1,200 clientes · 240 productos |
| Técnicas | CTEs recursivos · Funciones de ventana · PIVOT dinámico · SP con OUTPUT |
| Patrones BI | Star schema · Dim Date · Fact view · Cohortes de retención |
| Calidad de datos | Limpieza con `TRANSLATE` · Validación JSON · raw → clean layer |
