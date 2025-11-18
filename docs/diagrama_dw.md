# Diagrama del Data Warehouse - LGL

## Esquema Completo (Star Schema)

```mermaid
erDiagram
    %% TABLA DE HECHOS
    fact_ventas {
        BIGINT venta_key PK
        INT tiempo_key FK
        INT cliente_key FK
        INT producto_key FK
        INT vendedor_key FK
        INT tipo_documento_key FK
        INT condicion_pago_key FK
        INT estado_venta_key FK
        INT venta_id
        INT orden_pedido_id
        NVARCHAR numero_venta
        DECIMAL cantidad
        DECIMAL precio_unitario
        DECIMAL venta_exenta
        DECIMAL venta_gravada
        DECIMAL venta_total
        DECIMAL iva
        DECIMAL venta_total_con_impuestos
        BIT es_venta_credito
        BIT esta_liquidado
        BIT esta_anulado
        DATE fecha_venta
        DATE fecha_liquidacion
        DATE fecha_anulacion
        DATETIME2 fecha_carga
        DATETIME2 fecha_actualizacion
    }

    %% DIMENSIONES
    dim_tiempo {
        INT tiempo_key PK
        DATE fecha
        INT anio
        INT trimestre
        INT mes
        VARCHAR mes_nombre
        INT semana_anio
        INT dia_mes
        INT dia_semana
        VARCHAR dia_semana_nombre
        BIT es_fin_semana
        BIT es_festivo
        VARCHAR periodo_fiscal
        DATETIME2 created_at
    }

    dim_cliente {
        INT cliente_key PK
        INT cliente_id
        NVARCHAR nombre
        NVARCHAR nombre_alternativo
        VARCHAR nit
        VARCHAR nrc
        BIT retencion
        NVARCHAR municipio
        NVARCHAR departamento
        DATETIME2 fecha_inicio
        DATETIME2 fecha_fin
        INT version
        BIT es_actual
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    dim_producto {
        INT producto_key PK
        INT producto_id
        NVARCHAR nombre
        NVARCHAR nombre_alternativo
        VARCHAR codigo
        VARCHAR categoria_codigo
        VARCHAR categoria_nombre
        VARCHAR tipo_producto_codigo
        VARCHAR tipo_producto_nombre
        VARCHAR unidad_medida_nombre
        VARCHAR unidad_medida_abreviatura
        BIT producto_activo
        DATETIME2 fecha_inicio
        DATETIME2 fecha_fin
        INT version
        BIT es_actual
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    dim_vendedor {
        INT vendedor_key PK
        INT vendedor_id
        NVARCHAR nombre
        NVARCHAR apellido
        VARCHAR email
        VARCHAR username
        DATETIME2 fecha_inicio
        DATETIME2 fecha_fin
        INT version
        BIT es_actual
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    dim_tipo_documento {
        INT tipo_documento_key PK
        INT tipo_documento_id
        VARCHAR codigo
        VARCHAR nombre
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    dim_condicion_pago {
        INT condicion_pago_key PK
        INT condicion_pago_id
        VARCHAR codigo
        VARCHAR nombre
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    dim_estado_venta {
        INT estado_venta_key PK
        INT estado_venta_id
        VARCHAR codigo
        VARCHAR nombre
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    dim_ubicacion {
        INT ubicacion_key PK
        INT municipio_id
        NVARCHAR municipio_nombre
        INT departamento_id
        NVARCHAR departamento_nombre
        VARCHAR departamento_isocode
        INT zonesv_id
        DATETIME2 created_at
        DATETIME2 updated_at
    }

    %% RELACIONES (Star Schema)
    fact_ventas ||--o{ dim_tiempo : "tiempo_key"
    fact_ventas ||--o{ dim_cliente : "cliente_key"
    fact_ventas ||--o{ dim_producto : "producto_key"
    fact_ventas ||--o{ dim_vendedor : "vendedor_key"
    fact_ventas ||--o{ dim_tipo_documento : "tipo_documento_key"
    fact_ventas ||--o{ dim_condicion_pago : "condicion_pago_key"
    fact_ventas ||--o{ dim_estado_venta : "estado_venta_key"
```

---

## Esquema Simplificado (Vista General)

```mermaid
graph TD
    %% DIMENSIONES
    DT[dim_tiempo<br/>2,192 registros<br/>Calendario 2020-2025]
    DC[dim_cliente<br/>~1,146 registros<br/>SCD Type 2]
    DP[dim_producto<br/>~594 registros<br/>SCD Type 2]
    DV[dim_vendedor<br/>~16 registros<br/>SCD Type 2]
    DTD[dim_tipo_documento<br/>2 registros]
    DCP[dim_condicion_pago<br/>4 registros]
    DEV[dim_estado_venta<br/>3 registros]
    DU[dim_ubicacion<br/>262 registros]

    %% FACT TABLE
    FV[fact_ventas<br/>~40,884 registros<br/>Detalle línea de venta]

    %% RELACIONES
    DT --> FV
    DC --> FV
    DP --> FV
    DV --> FV
    DTD --> FV
    DCP --> FV
    DEV --> FV

    %% ESTILOS
    style FV fill:#ff9999,stroke:#cc0000,stroke-width:3px
    style DC fill:#99ccff,stroke:#0066cc,stroke-width:2px
    style DP fill:#99ccff,stroke:#0066cc,stroke-width:2px
    style DV fill:#99ccff,stroke:#0066cc,stroke-width:2px
    style DT fill:#99ff99,stroke:#009900,stroke-width:2px
    style DTD fill:#ffff99,stroke:#cccc00,stroke-width:2px
    style DCP fill:#ffff99,stroke:#cccc00,stroke-width:2px
    style DEV fill:#ffff99,stroke:#cccc00,stroke-width:2px
    style DU fill:#ffcc99,stroke:#ff6600,stroke-width:2px
```

**Leyenda:**
- 🔴 Rojo: Tabla de Hechos
- 🔵 Azul: Dimensiones SCD Type 2
- 🟢 Verde: Dimensión Tiempo
- 🟡 Amarillo: Dimensiones Estáticas
- 🟠 Naranja: Dimensión Geográfica

---

## Modelo de Negocio (Vistas Analíticas)

```mermaid
graph LR
    %% FACT TABLE
    FV[fact_ventas]

    %% VISTAS
    VP[v_productos_vendidos<br/>Top productos]
    VCC[v_cartera_clientes<br/>Ventas a crédito]
    VRV[v_ranking_vendedores<br/>Desempeño vendedores]
    VVG[v_ventas_geografia<br/>Análisis territorial]
    VK[v_kpis_ventas<br/>Indicadores clave]

    %% RELACIONES
    FV --> VP
    FV --> VCC
    FV --> VRV
    FV --> VVG
    FV --> VK

    %% CONSUMO
    VP --> PBI[Power BI<br/>Dashboards]
    VCC --> PBI
    VRV --> PBI
    VVG --> PBI
    VK --> PBI

    %% ESTILOS
    style FV fill:#ff9999,stroke:#cc0000,stroke-width:3px
    style VP fill:#e6f3ff,stroke:#0066cc,stroke-width:2px
    style VCC fill:#e6f3ff,stroke:#0066cc,stroke-width:2px
    style VRV fill:#e6f3ff,stroke:#0066cc,stroke-width:2px
    style VVG fill:#e6f3ff,stroke:#0066cc,stroke-width:2px
    style VK fill:#e6f3ff,stroke:#0066cc,stroke-width:2px
    style PBI fill:#ffeb99,stroke:#ff9900,stroke-width:3px
```

---

## Flujo de Datos (ETL)

```mermaid
flowchart LR
    %% ORIGEN
    MB[(MariaDB<br/>lgldb<br/>40 tablas)]

    %% ETL DIMENSIONES
    EDT[ETL<br/>dim_tiempo<br/>SP]
    EDS[ETL<br/>dim_static<br/>4 dims]
    EDC[ETL<br/>dim_cliente<br/>SCD2]
    EDP[ETL<br/>dim_producto<br/>SCD2]
    EDV[ETL<br/>dim_vendedor<br/>SCD2]

    %% ETL HECHOS
    EFV[ETL<br/>fact_ventas<br/>JOIN complejo]

    %% DESTINO
    DW[(SQL Server<br/>LGL_DW)]

    %% VISUALIZACIÓN
    PBI[Power BI]

    %% FLUJO
    MB --> EDT
    MB --> EDS
    MB --> EDC
    MB --> EDP
    MB --> EDV
    MB --> EFV

    EDT --> DW
    EDS --> DW
    EDC --> DW
    EDP --> DW
    EDV --> DW
    EFV --> DW

    DW --> PBI

    %% ESTILOS
    style MB fill:#4d94ff,stroke:#0066cc,stroke-width:2px
    style DW fill:#ff6666,stroke:#cc0000,stroke-width:3px
    style PBI fill:#ffeb99,stroke:#ff9900,stroke-width:2px
    style EDT fill:#99ff99,stroke:#009900
    style EDS fill:#ffff99,stroke:#cccc00
    style EDC fill:#99ccff,stroke:#0066cc
    style EDP fill:#99ccff,stroke:#0066cc
    style EDV fill:#99ccff,stroke:#0066cc
    style EFV fill:#ff9999,stroke:#cc0000
```

---

## SCD Type 2 - Versionamiento

```mermaid
stateDiagram-v2
    [*] --> VersionActual: Primer INSERT

    VersionActual: es_actual = 1
    VersionActual: fecha_fin = NULL
    VersionActual: version = 1

    VersionActual --> DetectaCambio: Carga Incremental

    DetectaCambio --> CierraVersion: Hay cambios
    DetectaCambio --> VersionActual: Sin cambios

    CierraVersion: UPDATE registro anterior
    CierraVersion: es_actual = 0
    CierraVersion: fecha_fin = HOY

    CierraVersion --> NuevaVersion: INSERT nuevo registro

    NuevaVersion: es_actual = 1
    NuevaVersion: fecha_fin = NULL
    NuevaVersion: version = version + 1

    NuevaVersion --> VersionActual

    note right of VersionActual
        Solo 1 versión actual
        por cliente/producto
    end note

    note right of CierraVersion
        Se mantiene historial
        completo de cambios
    end note
```

---

## Métricas y Cardinalidad

| Componente | Tipo | Registros | Crecimiento |
|------------|------|-----------|-------------|
| dim_tiempo | Dimensión | 2,192 | Anual (+365) |
| dim_tipo_documento | Dimensión | 2 | Estático |
| dim_condicion_pago | Dimensión | 4 | Estático |
| dim_estado_venta | Dimensión | 3 | Estático |
| dim_ubicacion | Dimensión | 262 | Estático |
| dim_cliente | Dimensión SCD2 | ~1,146 | Incremental |
| dim_producto | Dimensión SCD2 | ~594 | Incremental |
| dim_vendedor | Dimensión SCD2 | ~16 | Incremental |
| **fact_ventas** | **Hecho** | **~40,884** | **Diario** |

**Período actual:** 2018-02-01 a 2023-07-01 (5.4 años)  
**Venta total:** $1,471,206.11  
**Ventas únicas:** 17,317  
**Clientes activos:** 971  
**Productos vendidos:** 344

---

## Uso en Documentos

Puedes copiar cualquiera de estos diagramas en:
- README.md
- Documentación técnica
- Presentaciones (GitHub/GitLab renderiza Mermaid)
- Confluence, Notion, etc.

**Renderizado:** La mayoría de plataformas modernas renderizan Mermaid automáticamente.
