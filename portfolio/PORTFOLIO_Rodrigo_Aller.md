# Portfolio Data Analytics
## Jose Rodrigo Pérez Aller

> Business Intelligence with more than **16 years of experience**, focused on identifying the risks in the sales area, creating smart reports to define strategies that allow us optimize the results of it.

---

## Contenido

1. [Tableau Desktop](#1-tableau-desktop)
2. [Tableau Prep](#2-tableau-prep)
3. [Qlik Sense](#3-qlik-sense)
4. [Power BI](#4-power-bi)
5. [SQL Server](#5-sql-server)
6. [Stack Técnico](#6-stack-técnico)

---

## 1. Tableau Desktop

### 1.1 Profit Map — Rentabilidad por Estado (EE.UU.)

Mapa de calor geográfico que muestra la utilidad por estado utilizando una escala de color divergente (rojo = pérdida, azul = ganancia).

**Hallazgos clave:**
- Estado con mayor pérdida: **-$19,428** (zona este)
- Estado con mayor ganancia: **$37,422** (California)
- Texas destaca con **$28,079** de utilidad

**Técnicas aplicadas:**
- Mapas de símbolo con escala divergente
- Tooltips personalizados por estado
- Filtros de año y categoría

---

### 1.2 Sales Dashboard — Ventas por Región y Métricas

Dashboard comparativo de ventas 2015 por región (Central, East, South, West) con múltiples métricas en un solo view.

| Región | Ventas | Profit | Discount |
|--------|--------|--------|----------|
| Central | $448,285 | $77,385 | $52,015 |
| East | $592,171 | $85,291 | $47,843 |
| South | $357,105 | -$14,424 | $5,045 |
| West | $526,777 | $75,845 | $66,178 |

**Métricas visualizadas:** Sales · Profit · Discount · Product Base Margin · Quantity ordered new · Unit Price · Shipping Cost · Número de registros

**Pestañas del workbook:** Profit · Sales · Forecast · Tendencia · DS 1 · Map Sales · Sales Demo · BIT · Sales Lineal · Sales Final · Dashboard 5

---

### 1.3 Boston Police — Employee Earnings Dashboard

Análisis de nómina del Boston Police Department (BPD) vs Fire Department.

**KPI Principal:** `$416M` total en earnings (-0.2% vs año anterior)

**Análisis incluidos:**
- **BPD CAGR 3.75%** — Tasa de crecimiento anual compuesta de salarios 2010–2020
- Comparativa BPD vs Fire Dept: $153K vs $132K mediana 2020
- Police Cohort Median Earnings — evolución por cohorte de contratación (2011–2019)
- Líneas de tendencia por grupo de antigüedad

**Forecast trimestral:**

| | T1 | T2 | T3 | T4 |
|-|-|-|-|-|
| Actual | $972,585 | $1,051,773 | — | — |
| Estimación | — | — | $946,798 | $946,798 |

---

### 1.4 Análisis de Pasajeros — Vuelos Nacionales México

Comparativa de pasajeros transportados 2019 vs 2020 por aerolínea.

| Empresa | 2019 | 2020 | Variación | Participación |
|---------|------|------|-----------|---------------|
| Volaris | 15,310,298 | 8,580,707 | -47.42% | 38.14% |
| Vivaaerobus | 9,791,244 | 5,993,580 | -38.80% | 33.60% |
| Interjet | 9,611,310 | 2,469,919 | -74.32% | 8.89% |
| Aeroméxico Connect | 4,900,645 | 2,884,894 | -41.13% | 11.48% |
| Magnicharters | 863,063 | 279,979 | -67.56% | 1.11% |
| Aeromar | 720,836 | 296,551 | -58.84% | 1.28% |
| TAR | 510,637 | 169,174 | -66.83% | 0.63% |
| Aéreo Calafia | 242,592 | 62,027 | -74.43% | 0.25% |

---

## 2. Tableau Prep

### 2.1 Pipeline de Limpieza — Datos Educativos

Flow de transformación de datos sobre rendimiento estudiantil por distrito escolar.

**Transformaciones aplicadas (7 cambios):**

| # | Transformación | Campo afectado |
|---|---------------|----------------|
| 1 | Filter Wildcard Match | District Name — excluye "Tennghel" |
| 2 | Make Uppercase | District Name |
| 3 | Trim Spaces | District Name — elimina espacios en todos los valores |
| 4 | Group Values | District Name — reemplaza nulos por `$1 values` |
| 5 | Remove Field | — |
| 6 | Rename Field | Year: `[File Paths]` → `[Year]` |
| 7 | Rename Field | — |

**Campos de salida:** District Name · District Code · Grade 11/12 Students · % Students Completing Advanced · % ELA · % Math · % Science and Technology · % History

---

## 3. Qlik Sense

### 3.1 Output de Tableau Prep → Qlik Sense

Integración del flujo de datos limpio como fuente en Qlik Sense con opción de crear tabla o actualizar existente.

**Configuración de salida:**
- Output type: `Tableau Data Extract (.hyper)`
- Destination: `C:\Users\[user]\Documents\My Tableau Prep`
- Repository: `Tableau Data Sources`

---

### 3.2 Análisis de Clientes — Dashboard Ejecutivo

**KPIs Principales:**

| Métrica | Valor |
|---------|-------|
| Total Registros | 507,882 |
| Métrica 2 | 208,432 |
| Tasa | 41.0% |
| Segmento | 16,960 |
| Clientes activos | 5,916 |
| Registros adicionales | 299 |

**Visualizaciones:**
- Top 25 clientes por ventas (scatter plot)
- Diagrama de Pareto — concentración de ventas por cliente
- Ventas por número de clientes (barras agrupadas Online vs Tienda)

---

### 3.3 Temporada de Nieve por País

Análisis de caída de nieve por ciudad y periodo.

**KPIs:**
- Caída de Nieve total: **10.84K**
- % Caída de Nieve: **5.9%**
- Índice: **149.9**

**Ciudades analizadas:** Detroit · Chicago · Minneapolis · Philadelphia · New York, NY · Cincinnati

---

## 4. Power BI

### 4.1 Indicadores Mundiales — Vida y Población

Dashboard con datos demográficos globales.

**Páginas del reporte:** Población por Área · Indicadores mundiales · Vida

**Países con menor esperanza de vida (ranking):**
1. Central African Republic — 52.3
2. Somalia — 52.4
3. Zambia — 52.5
4. Lesotho — 53
5. Mozambique — 53.5
6. Nigeria — 53.4
7. Botswana — 54.5
8. Uganda — 55.4

**KPI Mortalidad Infantil:** 7.36K

**Distribución población por continente:**

| Continente | Población |
|-----------|-----------|
| Oceanía | 40,125,451 |
| Europa | 618,395,817 |
| Asia | 4,530,589,877 |
| América | 997,195,845 |
| África | 1,216,361,943 |
| **Total** | **7,413,672,933** |

---

### 4.2 Reporte de Utilidad por Producto

Reporte conectado a SQL Server con análisis de utilidad y margen por tipo de producto y región.

**KPIs del reporte:**
- Utilidad total: **$497,778**
- Margen global: **43%**

**Regiones:** Argentina · Chile · México · Canada · Colombia · Peru

**Desglose por producto:**

| Tipo de Producto | Utilidad | Margen |
|-----------------|----------|--------|
| LAX | $89,663 | 49% |
| MOC | $77,465 | 57% |
| DONANY | $73,472 | 59% |
| CHOTUS | $71,329 | 44% |
| SALF | $60,001 | 61% |
| GAMBO | $44,476 | 39% |
| DAWNE | $42,945 | 44% |
| QUOKAR | $38,428 | 17% |

**Series temporales:**
- Total Utilidad by DateKey (2007–2010) — Average line: $1,741,222
- Total Utilidad by End of Week — Average line: $26,117,099

---

### 4.3 Ventas Comparativo YoY — Dashboard Global

**Vista:** Apr 2018 vs Apr 2017

**Filtros disponibles:** Año (2016–2019) · Mes (Ene–Dic)

**KPIs:**

| Métrica | Valor | vs Año Previo |
|---------|-------|---------------|
| Ventas totales | $5,478,805 | +$1,011,797 (+22.65%) |
| Contribución | $2,775,637 | +$497,863 (+21.86%) |

**Mercados principales:** Estados Unidos $1,717,816 · España $1,037,354 · México, Centroamérica

**Top 10 Vendedores vs Año Previo:**

| Vendedor | Ventas | Variación |
|----------|--------|-----------|
| Kaslyn | $685.07K | -17% |
| Mohamed | $674.16K | +47% |
| Colt | $421.17K | -10% |
| Jacinto | $409.17K | -15% |
| Domingo | $363.25K | -59% |
| Glen | $335.42K | +9% |
| Maribel | $330.89K | +12% |
| Brent | $338.65K | -11% |
| Ivy | $297.3K | +5% |
| Paula | $264.81K | +12% |

**Ventas por Marca vs Año Previo:**
- Conexión TI: $2.72M (+17%)
- Veluz: $1.32M (+16%)
- Zoofarm: $0.76M (+6%)
- Empaca Todo: $0.35M (-13%)
- Northsend: $0.32M (-19%)

---

### 4.4 Análisis Temporal — Total Ingresos YoY (2009)

Comparativa mensual de ingresos 2009 vs año anterior.

**Total 2009:** $2,342,356,903 | **Total LY:** $2,418,115,901 | **Variación:** -$75,758,998 (-3.04%)

| Mes | Ingresos | Ingresos LY | Tendencia |
|-----|----------|-------------|-----------|
| Mayo | — | $222,777,274 | ▼ |
| Junio | $219,371,477 | $207,079,792 | ▲ |
| Julio | $213,418,051 | $229,906,366 | ▼ |
| Agosto | $205,615,939 | $213,168,678 | ▼ |
| Septiembre | $199,171,552 | $210,186,489 | ▼ |
| Octubre | $212,431,610 | $202,461,253 | ▲ |
| Noviembre | $183,719,485 | $205,399,887 | ▼ |
| Diciembre | $189,245,597 | $216,296,247 | ▼ |

---

## 5. SQL Server

Trabajo con SQL Server Management Studio (SSMS) visible en capturas del portfolio.

**Actividades documentadas:**
- Diseño y creación de tablas (`CREATE TABLE`) con constraints y PKs
- Stored Procedures para carga y transformación de datos
- Conexión directa a Power BI vía DirectQuery
- Optimización con `SET NOCOUNT ON` / `SET XACT_ABORT ON`
- Gestión de índices para rendimiento en reportes BI

**Ejemplo de objeto SQL visible en portfolio:**
```sql
CREATE TABLE [dbo].[MedicinaEspecialidad](
  [idMedico] INT,
  [idEspecialidad] INT,
  [Sector] NCHAR(40),
  CONSTRAINT PRIMARY KEY CLUSTERED [idMedico]
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF,
      ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
```

---

## 6. Stack Técnico

| Herramienta | Nivel | Casos de uso en portfolio |
|-------------|-------|--------------------------|
| **Tableau Desktop** | Avanzado | Mapas, dashboards ejecutivos, forecasting, análisis cohortes |
| **Tableau Prep** | Avanzado | ETL, limpieza, normalización, pipelines de datos |
| **Qlik Sense** | Avanzado | Análisis de clientes, integración con Tableau Prep |
| **Power BI** | Avanzado | Reportes YoY, utilidad por producto, indicadores globales |
| **SQL Server** | Avanzado | DDL, SPs, optimización, fuente de datos para BI |
| **DAX** | Avanzado | Medidas calculadas, time intelligence, rankings |

**Dominios de negocio:** Ventas · Finanzas · Aviación · Sector público · Demografía · Healthcare

**Experiencia:** +16 años en Business Intelligence

---

*Jose Rodrigo Pérez Aller — Portfolio Data Analytics*
