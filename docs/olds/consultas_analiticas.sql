-- ============================================================================
-- CONSULTAS ANALÍTICAS - DATA WAREHOUSE VENTAS
-- Ejemplos de análisis y reportes
-- ============================================================================

-- ============================================================================
-- 1. ANÁLISIS DE VENTAS POR PERÍODO
-- ============================================================================

-- Ventas mensuales del año actual
SELECT 
  dt.anio,
  dt.mes,
  dt.mes_nombre,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.cantidad) AS cantidad_total,
  SUM(fv.venta_total) AS venta_total,
  SUM(fv.venta_total_con_impuestos) AS venta_total_con_impuestos,
  SUM(fv.costo_venta) AS costo_total,
  SUM(fv.margen_bruto) AS margen_bruto_total,
  ROUND(AVG(fv.porcentaje_margen), 2) AS porcentaje_margen_promedio
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dt.anio, dt.mes, dt.mes_nombre
ORDER BY dt.mes;


-- Ventas por trimestre (comparativa año actual vs año anterior)
SELECT 
  dt.anio,
  dt.trimestre,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.margen_bruto) AS margen_bruto
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1)
  AND fv.esta_anulado = FALSE
GROUP BY dt.anio, dt.trimestre
ORDER BY dt.anio, dt.trimestre;


-- ============================================================================
-- 2. ANÁLISIS DE CLIENTES
-- ============================================================================

-- Top 10 clientes por volumen de ventas (año actual)
SELECT 
  dc.cliente_id,
  dc.nombre,
  dc.departamento,
  dc.municipio,
  COUNT(DISTINCT fv.venta_id) AS numero_compras,
  SUM(fv.cantidad) AS cantidad_total,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio,
  SUM(fv.margen_bruto) AS margen_bruto_generado
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.cliente_key = dc.cliente_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dc.cliente_id, dc.nombre, dc.departamento, dc.municipio
ORDER BY venta_total DESC
LIMIT 10;


-- Clientes con ventas a crédito pendientes
SELECT 
  dc.nombre AS cliente,
  dc.telefono_1,
  dc.departamento,
  COUNT(DISTINCT fv.venta_id) AS ventas_pendientes,
  SUM(fv.venta_total_con_impuestos) AS monto_total,
  SUM(fv.saldo) AS saldo_pendiente,
  SUM(fv.venta_total_con_impuestos - fv.saldo) AS monto_pagado,
  ROUND((SUM(fv.saldo) / SUM(fv.venta_total_con_impuestos)) * 100, 2) AS porcentaje_pendiente
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.cliente_key = dc.cliente_key
WHERE fv.es_venta_credito = TRUE
  AND fv.esta_liquidado = FALSE
  AND fv.esta_anulado = FALSE
  AND fv.saldo > 0
GROUP BY dc.cliente_key, dc.nombre, dc.telefono_1, dc.departamento
HAVING saldo_pendiente > 0
ORDER BY saldo_pendiente DESC;


-- ============================================================================
-- 3. ANÁLISIS DE PRODUCTOS
-- ============================================================================

-- Top 20 productos más vendidos (por cantidad)
SELECT 
  dp.producto_id,
  dp.nombre AS producto,
  dp.categoria_nombre,
  dp.tipo_producto_nombre,
  SUM(fv.cantidad) AS cantidad_vendida,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.venta_total) AS venta_total,
  SUM(fv.margen_bruto) AS margen_bruto,
  ROUND(AVG(fv.porcentaje_margen), 2) AS porcentaje_margen_promedio
FROM fact_ventas fv
INNER JOIN dim_producto dp ON fv.producto_key = dp.producto_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
  AND dp.producto_id > 0  -- Excluir producto genérico
GROUP BY dp.producto_id, dp.nombre, dp.categoria_nombre, dp.tipo_producto_nombre
ORDER BY cantidad_vendida DESC
LIMIT 20;


-- Análisis de rentabilidad por producto
SELECT 
  dp.nombre AS producto,
  dp.categoria_nombre,
  SUM(fv.venta_total) AS venta_total,
  SUM(fv.costo_venta) AS costo_total,
  SUM(fv.margen_bruto) AS margen_bruto,
  ROUND((SUM(fv.margen_bruto) / SUM(fv.venta_total)) * 100, 2) AS porcentaje_margen,
  SUM(fv.cantidad) AS cantidad_vendida
FROM fact_ventas fv
INNER JOIN dim_producto dp ON fv.producto_key = dp.producto_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
  AND dp.producto_id > 0
GROUP BY dp.producto_key, dp.nombre, dp.categoria_nombre
HAVING venta_total > 0
ORDER BY margen_bruto DESC;


-- Ventas por categoría de producto
SELECT 
  dp.categoria_nombre,
  COUNT(DISTINCT dp.producto_id) AS numero_productos,
  SUM(fv.cantidad) AS cantidad_total,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  SUM(fv.margen_bruto) AS margen_bruto,
  ROUND(AVG(fv.porcentaje_margen), 2) AS margen_porcentaje_promedio
FROM fact_ventas fv
INNER JOIN dim_producto dp ON fv.producto_key = dp.producto_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dp.categoria_nombre
ORDER BY venta_total DESC;


-- ============================================================================
-- 4. ANÁLISIS DE VENDEDORES
-- ============================================================================

-- Ranking de vendedores por desempeño
SELECT 
  dv.nombre AS vendedor,
  dv.apellido,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  COUNT(DISTINCT fv.cliente_key) AS numero_clientes_atendidos,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio,
  SUM(fv.margen_bruto) AS margen_bruto_generado,
  SUM(CASE WHEN fv.tiene_comision = TRUE THEN fv.venta_total ELSE 0 END) AS ventas_con_comision
FROM fact_ventas fv
INNER JOIN dim_vendedor dv ON fv.vendedor_key = dv.vendedor_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dv.vendedor_key, dv.nombre, dv.apellido
ORDER BY venta_total DESC;


-- Comparativa mensual de vendedores (últimos 6 meses)
SELECT 
  dv.nombre AS vendedor,
  dt.mes_nombre,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas
FROM fact_ventas fv
INNER JOIN dim_vendedor dv ON fv.vendedor_key = dv.vendedor_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.fecha >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
  AND fv.esta_anulado = FALSE
GROUP BY dv.vendedor_key, dv.nombre, dt.anio, dt.mes, dt.mes_nombre
ORDER BY dv.nombre, dt.anio, dt.mes;


-- ============================================================================
-- 5. ANÁLISIS GEOGRÁFICO
-- ============================================================================

-- Ventas por departamento
SELECT 
  dc.departamento,
  COUNT(DISTINCT dc.cliente_id) AS numero_clientes,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.cantidad) AS cantidad_total,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.cliente_key = dc.cliente_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dc.departamento
ORDER BY venta_total DESC;


-- Top municipios por ventas
SELECT 
  dc.municipio,
  dc.departamento,
  COUNT(DISTINCT dc.cliente_id) AS numero_clientes,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  SUM(fv.margen_bruto) AS margen_bruto
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.cliente_key = dc.cliente_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dc.municipio, dc.departamento
ORDER BY venta_total DESC
LIMIT 15;


-- ============================================================================
-- 6. ANÁLISIS DE CONDICIONES COMERCIALES
-- ============================================================================

-- Ventas por condición de pago
SELECT 
  dcp.nombre AS condicion_pago,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  SUM(fv.saldo) AS saldo_pendiente,
  ROUND((SUM(fv.saldo) / SUM(fv.venta_total_con_impuestos)) * 100, 2) AS porcentaje_pendiente,
  ROUND(AVG(DATEDIFF(
    COALESCE(fv.fecha_liquidacion, CURDATE()), 
    fv.fecha_venta
  )), 0) AS dias_promedio_liquidacion
FROM fact_ventas fv
INNER JOIN dim_condicion_pago dcp ON fv.condicion_pago_key = dcp.condicion_pago_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dcp.condicion_pago_key, dcp.nombre
ORDER BY venta_total DESC;


-- Análisis de ventas por tipo de documento
SELECT 
  dtd.nombre AS tipo_documento,
  COUNT(DISTINCT fv.venta_id) AS numero_documentos,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  ROUND(AVG(fv.venta_total_con_impuestos), 2) AS monto_promedio
FROM fact_ventas fv
INNER JOIN dim_tipo_documento dtd ON fv.tipo_documento_key = dtd.tipo_documento_key
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dtd.tipo_documento_key, dtd.nombre
ORDER BY venta_total DESC;


-- ============================================================================
-- 7. ANÁLISIS DE TENDENCIAS Y PATRONES
-- ============================================================================

-- Ventas por día de la semana
SELECT 
  dt.dia_semana_nombre,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dt.dia_semana, dt.dia_semana_nombre
ORDER BY dt.dia_semana;


-- Evolución mensual de ventas (año actual)
SELECT 
  dt.mes,
  dt.mes_nombre,
  SUM(fv.venta_total_con_impuestos) AS venta_mes_actual,
  LAG(SUM(fv.venta_total_con_impuestos)) OVER (ORDER BY dt.mes) AS venta_mes_anterior,
  ROUND(
    ((SUM(fv.venta_total_con_impuestos) - 
      LAG(SUM(fv.venta_total_con_impuestos)) OVER (ORDER BY dt.mes)) / 
      NULLIF(LAG(SUM(fv.venta_total_con_impuestos)) OVER (ORDER BY dt.mes), 0)) * 100, 
    2
  ) AS porcentaje_crecimiento
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dt.mes, dt.mes_nombre
ORDER BY dt.mes;


-- ============================================================================
-- 8. ANÁLISIS DE CARTERA
-- ============================================================================

-- Antigüedad de saldos (aging)
SELECT 
  CASE 
    WHEN DATEDIFF(CURDATE(), fv.fecha_venta) <= 30 THEN '0-30 días'
    WHEN DATEDIFF(CURDATE(), fv.fecha_venta) <= 60 THEN '31-60 días'
    WHEN DATEDIFF(CURDATE(), fv.fecha_venta) <= 90 THEN '61-90 días'
    WHEN DATEDIFF(CURDATE(), fv.fecha_venta) <= 120 THEN '91-120 días'
    ELSE 'Más de 120 días'
  END AS rango_antiguedad,
  COUNT(DISTINCT fv.venta_id) AS numero_ventas,
  SUM(fv.saldo) AS saldo_total,
  ROUND((SUM(fv.saldo) / (SELECT SUM(saldo) FROM fact_ventas WHERE saldo > 0)) * 100, 2) AS porcentaje_cartera
FROM fact_ventas fv
WHERE fv.es_venta_credito = TRUE
  AND fv.esta_liquidado = FALSE
  AND fv.esta_anulado = FALSE
  AND fv.saldo > 0
GROUP BY rango_antiguedad
ORDER BY 
  CASE rango_antiguedad
    WHEN '0-30 días' THEN 1
    WHEN '31-60 días' THEN 2
    WHEN '61-90 días' THEN 3
    WHEN '91-120 días' THEN 4
    ELSE 5
  END;


-- ============================================================================
-- 9. DASHBOARD EJECUTIVO
-- ============================================================================

-- KPIs principales del mes actual
SELECT 
  COUNT(DISTINCT fv.venta_id) AS total_ventas,
  COUNT(DISTINCT fv.cliente_key) AS clientes_activos,
  SUM(fv.venta_total_con_impuestos) AS venta_total,
  SUM(fv.costo_venta) AS costo_total,
  SUM(fv.margen_bruto) AS margen_bruto,
  ROUND((SUM(fv.margen_bruto) / SUM(fv.venta_total)) * 100, 2) AS porcentaje_margen,
  ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio,
  SUM(CASE WHEN fv.es_venta_credito = TRUE THEN fv.venta_total_con_impuestos ELSE 0 END) AS ventas_credito,
  SUM(CASE WHEN fv.es_venta_credito = FALSE THEN fv.venta_total_con_impuestos ELSE 0 END) AS ventas_contado,
  SUM(fv.saldo) AS saldo_pendiente
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
WHERE dt.anio = YEAR(CURDATE())
  AND dt.mes = MONTH(CURDATE())
  AND fv.esta_anulado = FALSE;


-- ============================================================================
-- 10. ANÁLISIS COHORT (Retención de clientes)
-- ============================================================================

-- Primera compra vs compras recurrentes por mes
WITH primera_compra AS (
  SELECT 
    cliente_key,
    MIN(fecha_venta) AS fecha_primera_compra
  FROM fact_ventas
  WHERE esta_anulado = FALSE
  GROUP BY cliente_key
)
SELECT 
  dt.anio,
  dt.mes_nombre,
  COUNT(DISTINCT CASE WHEN fv.fecha_venta = pc.fecha_primera_compra 
        THEN fv.cliente_key END) AS clientes_nuevos,
  COUNT(DISTINCT CASE WHEN fv.fecha_venta > pc.fecha_primera_compra 
        THEN fv.cliente_key END) AS clientes_recurrentes,
  COUNT(DISTINCT fv.cliente_key) AS total_clientes_activos
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
INNER JOIN primera_compra pc ON fv.cliente_key = pc.cliente_key
WHERE dt.anio = YEAR(CURDATE())
  AND fv.esta_anulado = FALSE
GROUP BY dt.anio, dt.mes, dt.mes_nombre
ORDER BY dt.mes;

