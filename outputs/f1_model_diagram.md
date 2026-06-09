# F1 SETUPS26 — Modelo de Datos Relacional

**Dominio:** Motorsport / F1 Racing Analytics  
**BD Destino:** SQL Server 2019 (compatible PostgreSQL)  
**Patrón:** Star Schema híbrido con bridge table para M:N  

---

## Diagrama de Relaciones (ERD)

```
┌─────────────────┐         ┌──────────────────────────┐         ┌──────────────────┐
│   dim_season    │         │  bridge_driver_constructor│         │  dim_constructor │
│─────────────────│1       N│──────────────────────────│N       1│──────────────────│
│ PK season_id    ├─────────┤ PK bridge_id             ├─────────┤ PK constructor_id│
│    year (UQ)    │         │ FK season_id             │         │    constructor_   │
│    regulation_  │         │ FK driver_id             │         │    code (UQ)      │
│    era          │         │ FK constructor_id        │         │    full_name      │
│    max_points   │         │    car_number            │         │    nationality    │
│    active_flag  │         │    seat_role             │         │    power_unit     │
└────────┬────────┘         └──────────────────────────┘         └────────┬─────────┘
         │                              N │                                │
         │1                               │1                               │
         │                       ┌────────┴────────┐                      │
         │                       │   dim_driver    │                      │
         │                       │─────────────────│                      │
         │                       │ PK driver_id    │                      │
         │                       │    driver_code  │                      │
         │                       │    (UQ)         │                      │
         │                       │    perm_number  │                      │
         │                       │    first_name   │                      │
         │                       │    last_name    │                      │
         │                       │    nationality  │                      │
         │                       └────────┬────────┘                      │
         │                                │                                │
         │1                               │1                               │1
         │         ┌──────────────────────┼──────────────────────────────┤
         │         │                      │                              │
         │N        │N                     │N                             │N
┌────────┴─────────┴──┐      ┌────────────┴───────┐           ┌─────────┴───────────┐
│   fact_grand_prix   │      │  fact_race_result  │           │   fact_qualifying   │
│─────────────────────│1    N│────────────────────│           │─────────────────────│
│ PK gp_id            ├──────┤ PK result_id       │           │ PK qual_id          │
│ FK season_id        │      │ FK gp_id           │           │ FK gp_id            │
│ FK circuit_id       │      │ FK driver_id       │           │ FK driver_id        │
│    round_number     │      │ FK constructor_id  │           │ FK constructor_id   │
│    gp_name          │      │    finish_position │           │    q1/q2/q3_time_ms │
│    race_date        │      │    grid_position   │           │    best_time_ms     │
│    weather_main     │      │    points_scored   │           │    grid_position    │
│    safety_car_laps  │      │    laps_completed  │           │    eliminated_q1/q2 │
│    vsc_laps         │      │    race_time_ms    │           └─────────────────────┘
└────────┬────────────┘      │    gap_leader_ms   │
         │                   │    fastest_lap     │
         │1                  │    dnf_reason      │
         ├──────────────┐    │    pit_stop_count  │
         │              │    └────────────────────┘
         │N             │N
┌────────┴────────┐  ┌──┴──────────────────┐
│  fact_car_setup │  │    fact_pit_stop     │
│─────────────────│  │──────────────────────│
│ PK setup_id     │  │ PK pit_stop_id       │
│ FK gp_id        │  │ FK gp_id             │
│ FK constructor_id│  │ FK driver_id         │
│    session_type  │  │    stop_number       │
│ ── Aerodynamics ─│  │    lap_number        │
│    front/rear_  │  │    pit_duration_ms   │
│    wing_angle   │  │    tyre_in / tyre_out│
│ ── Suspension ──│  └──────────────────────┘
│    front/rear_  │
│    suspension   │       ┌──────────────────────────┐
│    ARB front/   │       │ fact_championship_standing│
│    rear         │       │──────────────────────────│
│    ride_heights │       │ PK standing_id            │
│ ── Transmission │       │ FK season_id              │
│    diff on/off  │       │ FK driver_id              │
│    throttle     │       │ FK constructor_id         │
│ ── Brakes ──────│       │    after_round            │
│    brake_pressure│      │    driver_points          │
│    brake_bias   │       │    driver_position        │
│ ── Tyres ───────│       │    constructor_points     │
│    compound     │       │    constructor_position   │
│    camber/toe   │       └──────────────────────────┘
│    pressures    │
└─────────────────┘

┌──────────────┐
│ dim_circuit  │
│──────────────│
│ PK circuit_id│
│  code (UQ)   │◄──── 1:N ──── fact_grand_prix
│  name        │
│  country     │
│  city        │
│  type        │
│  lap_length  │
│  total_laps  │
│  altitude    │
└──────────────┘
```

---

## Tablas y Cardinalidades

| Tabla | Tipo | Filas estimadas | Propósito |
|---|---|---|---|
| `dim_season` | Dimensión | ~10 | Temporadas F1 |
| `dim_circuit` | Dimensión | ~30 | Trazados / circuitos |
| `dim_constructor` | Dimensión | ~15 | Equipos activos e históricos |
| `dim_driver` | Dimensión | ~30 | Pilotos activos e históricos |
| `bridge_driver_constructor` | Bridge M:N | ~60 | Asignación piloto-equipo por temporada |
| `fact_grand_prix` | Fact | ~250 | Eventos de carrera (Gran Premio) |
| `fact_qualifying` | Fact | ~5,000 | Resultados clasificación |
| `fact_race_result` | Fact | ~5,000 | Resultados carrera |
| `fact_car_setup` | Fact | ~15,000 | **Core: setups técnicos por sesión** |
| `fact_pit_stop` | Fact | ~12,000 | Paradas en boxes detalladas |
| `fact_championship_standing` | Fact acumulada | ~5,000 | Clasificación campeonato por ronda |

---

## Relaciones Clave

| Padre | Hijo | Cardinalidad | Tipo |
|---|---|---|---|
| `dim_season` | `fact_grand_prix` | 1:N | Identificante |
| `dim_circuit` | `fact_grand_prix` | 1:N | No identificante |
| `dim_driver` | `bridge_driver_constructor` | 1:N | Identificante |
| `dim_constructor` | `bridge_driver_constructor` | 1:N | Identificante |
| `dim_season` | `bridge_driver_constructor` | 1:N | Identificante |
| `fact_grand_prix` | `fact_race_result` | 1:N | Identificante |
| `fact_grand_prix` | `fact_qualifying` | 1:N | Identificante |
| `fact_grand_prix` | `fact_car_setup` | 1:N | Identificante |
| `fact_grand_prix` | `fact_pit_stop` | 1:N | Identificante |
| `dim_driver` | `fact_race_result` | 1:N | No identificante |
| `dim_constructor` | `fact_race_result` | 1:N | No identificante |
| `dim_season` | `fact_championship_standing` | 1:N | Identificante |

---

## Notas de Diseño

- **`fact_car_setup`** es la tabla central del repositorio: captura los 22 parámetros técnicos configurables por equipo/sesión/GP.
- **`bridge_driver_constructor`** resuelve la relación M:N entre pilotos y equipos (un piloto puede cambiar de equipo; un equipo tiene múltiples pilotos por temporada).
- Los tiempos se almacenan en **milisegundos (ms)** como `INT`/`BIGINT` para evitar imprecisiones con tipos de tiempo nativos.
- `session_type` en `fact_car_setup` cubre FP1-FP3, Q, Race y Sprint.
- El modelo soporta análisis de **correlación setup → resultado**: `JOIN fact_car_setup → fact_race_result` vía `gp_id + constructor_id`.
