-- ============================================================================
-- DATA WAREHOUSE - PROCESO DE VENTAS
-- SQL SERVER - VISTAS ANALÍTICAS
-- Fecha: 2025-11-12
-- ============================================================================

USE [LGL_DW];
GO

-- ============================================================================
-- VISTAS ANALÍTICAS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Vista principal para análisis de ventas
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.v_analisis_ventas', 'V') IS NOT NULL
    DROP VIEW dbo.v_analisis_ventas;
GO

CREATE VIEW dbo.v_analisis_ventas AS
SELECT 
    fv.venta_key,
    fv.venta_id,
    fv.numero_venta,
    
    -- Dimensión Tiempo
    dt.fecha,
    dt.anio,
    dt.trimestre,
    dt.mes,
    dt.mes_nombre,
    dt.semana_anio,
    dt.dia_semana_nombre,
    dt.es_fin_semana,
    dt.periodo_fiscal,
    
    -- Dimensión Cliente
    dc.nombre AS cliente_nombre,
    dc.municipio,
    dc.departamento,
    dc.nit AS cliente_nit,
    dc.telefono_1 AS cliente_telefono,
    
    -- Dimensión Producto
    dp.nombre AS producto_nombre,
    dp.codigo AS producto_codigo,
    dp.categoria_nombre,
    dp.tipo_producto_nombre,
    dp.unidad_medida_abreviatura,
    
    -- Dimensión Vendedor
    dv.nombre AS vendedor_nombre,
    dv.apellido AS vendedor_apellido,
    CONCAT(dv.nombre, ' ', dv.apellido) AS vendedor_completo,
    
    -- Dimensión Tipo Documento
    dtd.nombre AS tipo_documento,
    
    -- Dimensión Condición Pago
    dcp.nombre AS condicion_pago,
    
    -- Dimensión Estado
    dev.nombre AS estado_venta,
    
    -- Métricas
    fv.cantidad,
    fv.precio_unitario,
    fv.venta_exenta,
    fv.venta_gravada,
    fv.venta_total,
    fv.iva,
    fv.venta_total_con_impuestos,
    fv.flete,
    fv.costo_venta,
    fv.margen_bruto,
    fv.porcentaje_margen,
    fv.saldo,
    
    -- Indicadores
    fv.es_venta_credito,
    fv.tiene_comision,
    fv.esta_liquidado,
    fv.esta_anulado,
    
    -- Fechas
    fv.fecha_venta,
    fv.fecha_liquidacion,
    fv.fecha_anulacion,
    
    -- Métricas calculadas adicionales
    CASE 
        WHEN fv.fecha_liquidacion IS NOT NULL 
        THEN DATEDIFF(DAY, fv.fecha_venta, fv.fecha_liquidacion)
        ELSE DATEDIFF(DAY, fv.fecha_venta, GETDATE())
    END AS dias_desde_venta,
    
    CASE 
        WHEN fv.es_venta_credito = 1 AND fv.esta_liquidado = 0 AND fv.saldo > 0
        THEN 1 
        ELSE 0 
    END AS tiene_saldo_pendiente
    
FROM dbo.fact_ventas fv
INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
INNER JOIN dbo.dim_cliente dc ON fv.cliente_key = dc.cliente_key
INNER JOIN dbo.dim_producto dp ON fv.producto_key = dp.producto_key
LEFT JOIN dbo.dim_vendedor dv ON fv.vendedor_key = dv.vendedor_key
INNER JOIN dbo.dim_tipo_documento dtd ON fv.tipo_documento_key = dtd.tipo_documento_key
LEFT JOIN dbo.dim_condicion_pago dcp ON fv.condicion_pago_key = dcp.condicion_pago_key
INNER JOIN dbo.dim_estado_venta dev ON fv.estado_venta_key = dev.estado_venta_key;
GO

-- ----------------------------------------------------------------------------
-- Vista para análisis de rentabilidad por producto
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.v_rentabilidad_productos', 'V') IS NOT NULL
    DROP VIEW dbo.v_rentabilidad_productos;
GO

CREATE VIEW dbo.v_rentabilidad_productos AS
SELECT 
    dp.producto_id,
    dp.nombre AS producto,
    dp.categoria_nombre,
    dp.tipo_producto_nombre,
    dt.anio,
    dt.mes,
    dt.mes_nombre,
    COUNT(DISTINCT fv.venta_id) AS numero_ventas,
    SUM(fv.cantidad) AS cantidad_vendida,
    SUM(fv.venta_total) AS venta_total,
    SUM(fv.costo_venta) AS costo_total,
    SUM(fv.margen_bruto) AS margen_bruto,
    CASE 
        WHEN SUM(fv.venta_total) > 0 
        THEN (SUM(fv.margen_bruto) / SUM(fv.venta_total)) * 100 
        ELSE 0 
    END AS porcentaje_margen
FROM dbo.fact_ventas fv
INNER JOIN dbo.dim_producto dp ON fv.producto_key = dp.producto_key
INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE fv.esta_anulado = 0
    AND dp.producto_id > 0  -- Excluir producto genérico
GROUP BY 
    dp.producto_id,
    dp.nombre,
    dp.categoria_nombre,
    dp.tipo_producto_nombre,
    dt.anio,
    dt.mes,
    dt.mes_nombre;
GO

-- ----------------------------------------------------------------------------
-- Vista para análisis de cartera por cliente
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.v_cartera_clientes', 'V') IS NOT NULL
    DROP VIEW dbo.v_cartera_clientes;
GO

CREATE VIEW dbo.v_cartera_clientes AS
SELECT 
    dc.cliente_id,
    dc.nombre AS cliente,
    dc.departamento,
    dc.municipio,
    dc.telefono_1,
    dc.correo,
    COUNT(DISTINCT fv.venta_id) AS ventas_pendientes,
    SUM(fv.venta_total_con_impuestos) AS monto_total_credito,
    SUM(fv.saldo) AS saldo_pendiente,
    SUM(fv.venta_total_con_impuestos - fv.saldo) AS monto_pagado,
    CASE 
        WHEN SUM(fv.venta_total_con_impuestos) > 0 
        THEN (SUM(fv.saldo) / SUM(fv.venta_total_con_impuestos)) * 100 
        ELSE 0 
    END AS porcentaje_pendiente,
    MIN(fv.fecha_venta) AS fecha_venta_mas_antigua,
    MAX(fv.fecha_venta) AS fecha_venta_mas_reciente,
    AVG(DATEDIFF(DAY, fv.fecha_venta, GETDATE())) AS dias_promedio_pendiente
FROM dbo.fact_ventas fv
INNER JOIN dbo.dim_cliente dc ON fv.cliente_key = dc.cliente_key
WHERE fv.es_venta_credito = 1
    AND fv.esta_liquidado = 0
    AND fv.esta_anulado = 0
    AND fv.saldo > 0
GROUP BY 
    dc.cliente_id,
    dc.nombre,
    dc.departamento,
    dc.municipio,
    dc.telefono_1,
    dc.correo;
GO

-- ----------------------------------------------------------------------------
-- Vista para ranking de vendedores
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.v_ranking_vendedores', 'V') IS NOT NULL
    DROP VIEW dbo.v_ranking_vendedores;
GO

CREATE VIEW dbo.v_ranking_vendedores AS
SELECT 
    dv.vendedor_id,
    dv.nombre,
    dv.apellido,
    CONCAT(dv.nombre, ' ', dv.apellido) AS vendedor_completo,
    dt.anio,
    dt.mes,
    dt.mes_nombre,
    COUNT(DISTINCT fv.venta_id) AS numero_ventas,
    COUNT(DISTINCT fv.cliente_key) AS clientes_atendidos,
    SUM(fv.venta_total_con_impuestos) AS venta_total,
    AVG(fv.venta_total_con_impuestos) AS ticket_promedio,
    SUM(fv.margen_bruto) AS margen_bruto_generado,
    SUM(CASE WHEN fv.tiene_comision = 1 THEN fv.venta_total ELSE 0 END) AS ventas_con_comision
FROM dbo.fact_ventas fv
INNER JOIN dbo.dim_vendedor dv ON fv.vendedor_key = dv.vendedor_key
INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE fv.esta_anulado = 0
    AND dv.vendedor_id > 0  -- Excluir vendedor desconocido
GROUP BY 
    dv.vendedor_id,
    dv.nombre,
    dv.apellido,
    dt.anio,
    dt.mes,
    dt.mes_nombre;
GO

-- ----------------------------------------------------------------------------
-- Vista para ventas por geografía
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.v_ventas_geografia', 'V') IS NOT NULL
    DROP VIEW dbo.v_ventas_geografia;
GO

CREATE VIEW dbo.v_ventas_geografia AS
SELECT 
    dc.departamento,
    dc.municipio,
    dt.anio,
    dt.trimestre,
    dt.mes,
    dt.mes_nombre,
    COUNT(DISTINCT dc.cliente_id) AS numero_clientes,
    COUNT(DISTINCT fv.venta_id) AS numero_ventas,
    SUM(fv.cantidad) AS cantidad_total,
    SUM(fv.venta_total_con_impuestos) AS venta_total,
    AVG(fv.venta_total_con_impuestos) AS ticket_promedio,
    SUM(fv.margen_bruto) AS margen_bruto
FROM dbo.fact_ventas fv
INNER JOIN dbo.dim_cliente dc ON fv.cliente_key = dc.cliente_key
INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE fv.esta_anulado = 0
GROUP BY 
    dc.departamento,
    dc.municipio,
    dt.anio,
    dt.trimestre,
    dt.mes,
    dt.mes_nombre;
GO

-- ----------------------------------------------------------------------------
-- Vista para KPIs principales
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.v_kpis_ventas', 'V') IS NOT NULL
    DROP VIEW dbo.v_kpis_ventas;
GO

CREATE VIEW dbo.v_kpis_ventas AS
SELECT 
    dt.anio,
    dt.mes,
    dt.mes_nombre,
    dt.periodo_fiscal,
    
    -- Métricas de ventas
    COUNT(DISTINCT fv.venta_id) AS total_ventas,
    COUNT(DISTINCT fv.cliente_key) AS clientes_activos,
    SUM(fv.venta_total_con_impuestos) AS venta_total,
    AVG(fv.venta_total_con_impuestos) AS ticket_promedio,
    
    -- Métricas de rentabilidad
    SUM(fv.costo_venta) AS costo_total,
    SUM(fv.margen_bruto) AS margen_bruto,
    CASE 
        WHEN SUM(fv.venta_total) > 0 
        THEN (SUM(fv.margen_bruto) / SUM(fv.venta_total)) * 100 
        ELSE 0 
    END AS porcentaje_margen,
    
    -- Métricas por tipo de pago
    SUM(CASE WHEN fv.es_venta_credito = 1 THEN fv.venta_total_con_impuestos ELSE 0 END) AS ventas_credito,
    SUM(CASE WHEN fv.es_venta_credito = 0 THEN fv.venta_total_con_impuestos ELSE 0 END) AS ventas_contado,
    
    -- Métricas de cartera
    SUM(fv.saldo) AS saldo_pendiente,
    COUNT(DISTINCT CASE WHEN fv.saldo > 0 THEN fv.cliente_key END) AS clientes_con_saldo,
    
    -- Indicadores de estado
    SUM(CASE WHEN fv.esta_anulado = 1 THEN 1 ELSE 0 END) AS ventas_anuladas,
    SUM(CASE WHEN fv.esta_liquidado = 1 THEN 1 ELSE 0 END) AS ventas_liquidadas
    
FROM dbo.fact_ventas fv
INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
GROUP BY 
    dt.anio,
    dt.mes,
    dt.mes_nombre,
    dt.periodo_fiscal;
GO

PRINT 'Vistas analíticas creadas exitosamente';
GO
