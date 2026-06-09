# Medidas DAX — Portafolio Retail BI

## KPIs Principales

```dax
Ventas Netas =
SUMX(fact_venta,
    fact_venta[unidades] * fact_venta[precio_unitario] * (1 - fact_venta[descuento_pct]/100))

Margen Bruto =
SUMX(fact_venta,
    fact_venta[unidades] *
    (fact_venta[precio_unitario] * (1 - fact_venta[descuento_pct]/100)
     - fact_venta[costo_unitario]))

Margen % =
DIVIDE([Margen Bruto], [Ventas Netas], 0)

Unidades Vendidas = SUM(fact_venta[unidades])

Ticket Promedio =
DIVIDE([Ventas Netas], DISTINCTCOUNT(fact_venta[venta_id]), 0)
```

## Comparativas de Tiempo

```dax
Ventas MesAnterior =
CALCULATE([Ventas Netas], PREVIOUSMONTH(dim_tiempo[fecha]))

Variacion MoM % =
DIVIDE([Ventas Netas] - [Ventas MesAnterior], [Ventas MesAnterior], 0)

Ventas YTD =
CALCULATE([Ventas Netas], DATESYTD(dim_tiempo[fecha]))

Ventas LYTD =
CALCULATE([Ventas Netas],
    DATESYTD(SAMEPERIODLASTYEAR(dim_tiempo[fecha])))

Variacion YoY % =
DIVIDE([Ventas YTD] - [Ventas LYTD], [Ventas LYTD], 0)

Ventas Rolling 3M =
CALCULATE([Ventas Netas],
    DATESINPERIOD(dim_tiempo[fecha], LASTDATE(dim_tiempo[fecha]), -3, MONTH))
```

## Rankings

```dax
Ranking Producto =
RANKX(ALL(dim_producto[producto]), [Ventas Netas], , DESC, Dense)

Ranking Vendedor =
RANKX(ALL(dim_vendedor[nombre]), [Ventas Netas], , DESC, Dense)

Top 10 Productos =
IF([Ranking Producto] <= 10, [Ventas Netas], BLANK())
```

## Metas y Semaforo

```dax
Meta Ventas = [Ventas Netas] * 1.10   -- 10% sobre periodo anterior

Cumplimiento Meta % =
DIVIDE([Ventas Netas], [Meta Ventas], 0)

Semaforo Margen =
SWITCH(TRUE(),
    [Margen %] >= 0.40, "🟢 Verde",
    [Margen %] >= 0.25, "🟡 Amarillo",
    "🔴 Rojo")
```

## Mezcla de Canal

```dax
Mix Online % =
DIVIDE(
    CALCULATE([Ventas Netas], dim_canal[canal] = "Online"),
    [Ventas Netas], 0)

Mix Tienda % =
DIVIDE(
    CALCULATE([Ventas Netas], dim_canal[canal] = "Tienda"),
    [Ventas Netas], 0)
```
