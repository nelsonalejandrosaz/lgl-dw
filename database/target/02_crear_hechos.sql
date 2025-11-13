-- ============================================================================
-- DATA WAREHOUSE - PROCESO DE VENTAS
-- SQL SERVER - TABLA DE HECHOS
-- Fecha: 2025-11-12
-- ============================================================================

USE [LGL_DW];
GO

-- ============================================================================
-- TABLA DE HECHOS PRINCIPAL
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Fact Table: Ventas
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.fact_ventas', 'U') IS NOT NULL
    DROP TABLE dbo.fact_ventas;
GO

CREATE TABLE dbo.fact_ventas (
    venta_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign Keys a Dimensiones
    tiempo_key INT NOT NULL,
    cliente_key INT NOT NULL,
    producto_key INT NOT NULL,
    vendedor_key INT NULL,
    tipo_documento_key INT NOT NULL,
    condicion_pago_key INT NULL,
    estado_venta_key INT NOT NULL,
    
    -- Degenerate Dimensions (Dimensiones Degeneradas)
    venta_id INT NOT NULL,
    orden_pedido_id INT NULL,
    numero_venta NVARCHAR(191) NULL,
    
    -- Métricas Aditivas (Measures)
    cantidad DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    precio_unitario DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    venta_exenta DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    venta_gravada DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    venta_total DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    iva DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    venta_total_con_impuestos DECIMAL(12,4) NOT NULL DEFAULT 0.0,
    
    -- Métricas Derivadas (calculadas)
    costo_venta DECIMAL(12,4) DEFAULT 0.0,
    margen_bruto DECIMAL(12,4) DEFAULT 0.0,
    porcentaje_margen DECIMAL(8,2) DEFAULT 0.0,
    
    -- Indicadores de Estado (se actualizan cuando cambian en el sistema origen)
    es_venta_credito BIT DEFAULT 0,
    esta_liquidado BIT DEFAULT 0,              -- Se actualiza cuando la venta se liquida
    esta_anulado BIT DEFAULT 0,                -- Se actualiza cuando la venta se anula
    
    -- Fechas Relevantes
    fecha_venta DATE NOT NULL,
    fecha_liquidacion DATE NULL,               -- Fecha en que se completó el pago
    fecha_anulacion DATE NULL,                 -- Fecha en que se anuló la venta
    
    -- Metadatos de Auditoría
    fecha_carga DATETIME2 DEFAULT GETDATE(),
    fecha_actualizacion DATETIME2 DEFAULT GETDATE(),
    
    -- Constraints
    CONSTRAINT fk_fact_ventas_tiempo FOREIGN KEY (tiempo_key) 
        REFERENCES dbo.dim_tiempo(tiempo_key),
    CONSTRAINT fk_fact_ventas_cliente FOREIGN KEY (cliente_key) 
        REFERENCES dbo.dim_cliente(cliente_key),
    CONSTRAINT fk_fact_ventas_producto FOREIGN KEY (producto_key) 
        REFERENCES dbo.dim_producto(producto_key),
    CONSTRAINT fk_fact_ventas_vendedor FOREIGN KEY (vendedor_key) 
        REFERENCES dbo.dim_vendedor(vendedor_key),
    CONSTRAINT fk_fact_ventas_tipo_doc FOREIGN KEY (tipo_documento_key) 
        REFERENCES dbo.dim_tipo_documento(tipo_documento_key),
    CONSTRAINT fk_fact_ventas_condicion FOREIGN KEY (condicion_pago_key) 
        REFERENCES dbo.dim_condicion_pago(condicion_pago_key),
    CONSTRAINT fk_fact_ventas_estado FOREIGN KEY (estado_venta_key) 
        REFERENCES dbo.dim_estado_venta(estado_venta_key)
);
GO

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX idx_fact_ventas_tiempo ON dbo.fact_ventas(tiempo_key);
CREATE NONCLUSTERED INDEX idx_fact_ventas_cliente ON dbo.fact_ventas(cliente_key);
CREATE NONCLUSTERED INDEX idx_fact_ventas_producto ON dbo.fact_ventas(producto_key);
CREATE NONCLUSTERED INDEX idx_fact_ventas_vendedor ON dbo.fact_ventas(vendedor_key);
CREATE NONCLUSTERED INDEX idx_fact_ventas_fecha ON dbo.fact_ventas(fecha_venta);
CREATE NONCLUSTERED INDEX idx_fact_ventas_venta_id ON dbo.fact_ventas(venta_id);
CREATE NONCLUSTERED INDEX idx_fact_ventas_estado ON dbo.fact_ventas(estado_venta_key);

-- Índices compuestos para queries comunes
CREATE NONCLUSTERED INDEX idx_fact_ventas_tiempo_cliente 
    ON dbo.fact_ventas(tiempo_key, cliente_key);
CREATE NONCLUSTERED INDEX idx_fact_ventas_tiempo_producto 
    ON dbo.fact_ventas(tiempo_key, producto_key);
CREATE NONCLUSTERED INDEX idx_fact_ventas_tiempo_vendedor 
    ON dbo.fact_ventas(tiempo_key, vendedor_key);

-- Índice columnar para mejor performance analítico (SQL Server Enterprise/Standard 2016+)
-- Descomentar si se tiene la edición apropiada
-- CREATE COLUMNSTORE INDEX idx_fact_ventas_columnstore ON dbo.fact_ventas;
GO

PRINT 'Tabla de hechos creada exitosamente';
GO