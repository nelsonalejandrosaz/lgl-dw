-- ============================================================================
-- ETL - CARGA TABLA DE HECHOS VENTAS
-- Data Warehouse - Proceso de Ventas
-- ============================================================================

-- ============================================================================
-- PROCEDIMIENTO: Carga Incremental de Fact_Ventas
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_cargar_fact_ventas(
  IN p_fecha_inicio DATE,
  IN p_fecha_fin DATE
)
BEGIN
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error al cargar tabla de hechos' AS mensaje;
  END;
  
  START TRANSACTION;
  
  -- Insertar detalle de ventas desde salidas (productos)
  INSERT INTO fact_ventas (
    tiempo_key,
    cliente_key,
    producto_key,
    vendedor_key,
    tipo_documento_key,
    condicion_pago_key,
    estado_venta_key,
    venta_id,
    orden_pedido_id,
    numero_venta,
    cantidad,
    precio_unitario,
    venta_exenta,
    venta_gravada,
    venta_total,
    iva,
    venta_total_con_impuestos,
    flete,
    saldo,
    costo_venta,
    margen_bruto,
    porcentaje_margen,
    es_venta_credito,
    tiene_comision,
    esta_liquidado,
    esta_anulado,
    fecha_venta,
    fecha_liquidacion,
    fecha_anulacion
  )
  SELECT 
    -- Llaves dimensionales
    dt.tiempo_key,
    dc.cliente_key,
    dp.producto_key,
    dv.vendedor_key,
    dtd.tipo_documento_key,
    dcp.condicion_pago_key,
    dev.estado_venta_key,
    
    -- Dimensiones degeneradas
    v.id AS venta_id,
    v.orden_pedido_id,
    v.numero AS numero_venta,
    
    -- Métricas desde salidas
    s.cantidad,
    s.precio_unitario,
    s.venta_exenta,
    s.venta_gravada,
    (s.venta_exenta + s.venta_gravada) AS venta_total,
    
    -- Cálculo de IVA (asumiendo 13%)
    s.venta_gravada * 0.13 AS iva,
    
    -- Total con impuestos
    (s.venta_exenta + s.venta_gravada + (s.venta_gravada * 0.13)) AS venta_total_con_impuestos,
    
    -- Flete prorrateado (distribuir flete proporcionalmente)
    COALESCE(v.flete, 0) * 
      ((s.venta_exenta + s.venta_gravada) / NULLIF(v.venta_total, 0)) AS flete,
    
    -- Saldo prorrateado
    COALESCE(v.saldo, 0) * 
      ((s.venta_exenta + s.venta_gravada) / NULLIF(v.venta_total, 0)) AS saldo,
    
    -- Costo de venta (obtener del último movimiento)
    COALESCE(
      (SELECT m.costo_unitario * s.cantidad
       FROM movimientos m
       WHERE m.producto_id = p.id
         AND m.tipo_movimiento_id = 2 -- Salida
         AND m.salida_id = s.id
       ORDER BY m.fecha DESC, m.id DESC
       LIMIT 1),
      0
    ) AS costo_venta,
    
    -- Margen bruto
    (s.venta_exenta + s.venta_gravada) - COALESCE(
      (SELECT m.costo_total
       FROM movimientos m
       WHERE m.producto_id = p.id
         AND m.tipo_movimiento_id = 2
         AND m.salida_id = s.id
       ORDER BY m.fecha DESC, m.id DESC
       LIMIT 1),
      0
    ) AS margen_bruto,
    
    -- Porcentaje de margen
    CASE 
      WHEN (s.venta_exenta + s.venta_gravada) > 0 THEN
        ((s.venta_exenta + s.venta_gravada) - COALESCE(
          (SELECT m.costo_total
           FROM movimientos m
           WHERE m.producto_id = p.id
             AND m.tipo_movimiento_id = 2
             AND m.salida_id = s.id
           ORDER BY m.fecha DESC, m.id DESC
           LIMIT 1),
          0
        )) / (s.venta_exenta + s.venta_gravada) * 100
      ELSE 0
    END AS porcentaje_margen,
    
    -- Indicadores
    IF(cp.codigo = 'CRE', TRUE, FALSE) AS es_venta_credito,
    v.comision AS tiene_comision,
    IF(v.fecha_liquidado IS NOT NULL, TRUE, FALSE) AS esta_liquidado,
    IF(v.fecha_anulado IS NOT NULL, TRUE, FALSE) AS esta_anulado,
    
    -- Fechas
    v.fecha AS fecha_venta,
    v.fecha_liquidado,
    v.fecha_anulado
    
  FROM ventas v
  
  -- Join con orden_pedidos y salidas para obtener detalle de productos
  INNER JOIN orden_pedidos op ON v.orden_pedido_id = op.id
  INNER JOIN salidas s ON op.id = s.orden_pedido_id
  
  -- Obtener información del producto
  INNER JOIN productos p ON s.unidad_medida_id IN (
    SELECT pr.unidad_medida_id 
    FROM precios pr 
    WHERE pr.id = s.precio_id
  )
  INNER JOIN precios pr ON s.precio_id = pr.id AND pr.producto_id = p.id
  
  -- Joins con dimensiones
  INNER JOIN dim_tiempo dt ON v.fecha = dt.fecha
  LEFT JOIN dim_cliente dc ON v.cliente_id = dc.cliente_id AND dc.es_actual = TRUE
  INNER JOIN dim_producto dp ON p.id = dp.producto_id AND dp.es_actual = TRUE
  LEFT JOIN dim_vendedor dv ON v.vendedor_id = dv.vendedor_id AND dv.es_actual = TRUE
  INNER JOIN dim_tipo_documento dtd ON v.tipo_documento_id = dtd.tipo_documento_id
  LEFT JOIN dim_condicion_pago dcp ON v.condicion_pago_id = dcp.condicion_pago_id
  INNER JOIN dim_estado_venta dev ON v.estado_venta_id = dev.estado_venta_id
  LEFT JOIN condiciones_pago cp ON v.condicion_pago_id = cp.id
  
  -- Filtros de fecha
  WHERE v.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
    AND NOT EXISTS (
      SELECT 1 
      FROM fact_ventas fv 
      WHERE fv.venta_id = v.id 
        AND fv.producto_key = dp.producto_key
    );
  
  
  -- Insertar ventas de "otras ventas" (productos no inventariados)
  INSERT INTO fact_ventas (
    tiempo_key,
    cliente_key,
    producto_key,
    vendedor_key,
    tipo_documento_key,
    condicion_pago_key,
    estado_venta_key,
    venta_id,
    orden_pedido_id,
    numero_venta,
    cantidad,
    precio_unitario,
    venta_exenta,
    venta_gravada,
    venta_total,
    iva,
    venta_total_con_impuestos,
    flete,
    saldo,
    es_venta_credito,
    tiene_comision,
    esta_liquidado,
    esta_anulado,
    fecha_venta,
    fecha_liquidacion,
    fecha_anulacion
  )
  SELECT 
    dt.tiempo_key,
    dc.cliente_key,
    -1 AS producto_key, -- Producto genérico para "otras ventas"
    dv.vendedor_key,
    dtd.tipo_documento_key,
    dcp.condicion_pago_key,
    dev.estado_venta_key,
    v.id AS venta_id,
    v.orden_pedido_id,
    v.numero AS numero_venta,
    dov.cantidad,
    dov.precio_unitario,
    dov.venta_exenta,
    dov.venta_gravada,
    dov.venta_total,
    dov.venta_gravada * 0.13 AS iva,
    dov.venta_total + (dov.venta_gravada * 0.13) AS venta_total_con_impuestos,
    COALESCE(v.flete, 0) * 
      (dov.venta_total / NULLIF(v.venta_total, 0)) AS flete,
    COALESCE(v.saldo, 0) * 
      (dov.venta_total / NULLIF(v.venta_total, 0)) AS saldo,
    IF(cp.codigo = 'CRE', TRUE, FALSE) AS es_venta_credito,
    v.comision AS tiene_comision,
    IF(v.fecha_liquidado IS NOT NULL, TRUE, FALSE) AS esta_liquidado,
    IF(v.fecha_anulado IS NOT NULL, TRUE, FALSE) AS esta_anulado,
    v.fecha AS fecha_venta,
    v.fecha_liquidado,
    v.fecha_anulado
    
  FROM ventas v
  INNER JOIN detalle_otras_ventas dov ON v.id = dov.venta_id
  INNER JOIN dim_tiempo dt ON v.fecha = dt.fecha
  LEFT JOIN dim_cliente dc ON v.cliente_id = dc.cliente_id AND dc.es_actual = TRUE
  LEFT JOIN dim_vendedor dv ON v.vendedor_id = dv.vendedor_id AND dv.es_actual = TRUE
  INNER JOIN dim_tipo_documento dtd ON v.tipo_documento_id = dtd.tipo_documento_id
  LEFT JOIN dim_condicion_pago dcp ON v.condicion_pago_id = dcp.condicion_pago_id
  INNER JOIN dim_estado_venta dev ON v.estado_venta_id = dev.estado_venta_id
  LEFT JOIN condiciones_pago cp ON v.condicion_pago_id = cp.id
  
  WHERE v.fecha BETWEEN p_fecha_inicio AND p_fecha_fin
    AND NOT EXISTS (
      SELECT 1 
      FROM fact_ventas fv 
      WHERE fv.venta_id = v.id 
        AND fv.producto_key = -1
    );
  
  COMMIT;
  
  SELECT CONCAT('Ventas cargadas exitosamente para el período: ', 
                p_fecha_inicio, ' - ', p_fecha_fin) AS mensaje;
  
END$$

DELIMITER ;


-- ============================================================================
-- PROCEDIMIENTO: Actualizar Fact_Ventas (para ventas modificadas)
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_actualizar_fact_ventas(
  IN p_venta_id INT
)
BEGIN
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error al actualizar venta' AS mensaje;
  END;
  
  START TRANSACTION;
  
  -- Actualizar estado y saldo de ventas existentes
  UPDATE fact_ventas fv
  INNER JOIN ventas v ON fv.venta_id = v.id
  INNER JOIN dim_estado_venta dev ON v.estado_venta_id = dev.estado_venta_id
  SET 
    fv.estado_venta_key = dev.estado_venta_key,
    fv.saldo = COALESCE(v.saldo, 0) * 
      (fv.venta_total / NULLIF(v.venta_total, 0)),
    fv.esta_liquidado = IF(v.fecha_liquidado IS NOT NULL, TRUE, FALSE),
    fv.esta_anulado = IF(v.fecha_anulado IS NOT NULL, TRUE, FALSE),
    fv.fecha_liquidacion = v.fecha_liquidado,
    fv.fecha_anulacion = v.fecha_anulado,
    fv.fecha_actualizacion = NOW()
  WHERE fv.venta_id = p_venta_id;
  
  COMMIT;
  
  SELECT CONCAT('Venta ', p_venta_id, ' actualizada exitosamente') AS mensaje;
  
END$$

DELIMITER ;


-- ============================================================================
-- PROCEDIMIENTO: Carga Incremental Diaria
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_etl_diario()
BEGIN
  
  DECLARE v_fecha_proceso DATE;
  
  -- Fecha del proceso (ayer)
  SET v_fecha_proceso = CURDATE() - INTERVAL 1 DAY;
  
  -- Cargar dimensiones (por si hay cambios)
  CALL sp_cargar_dim_cliente();
  CALL sp_cargar_dim_producto();
  CALL sp_cargar_dim_vendedor();
  
  -- Cargar ventas del día
  CALL sp_cargar_fact_ventas(v_fecha_proceso, v_fecha_proceso);
  
  -- Actualizar ventas agregadas
  CALL sp_actualizar_fact_ventas_diarias(v_fecha_proceso);
  
  SELECT CONCAT('ETL diario completado para fecha: ', v_fecha_proceso) AS mensaje;
  
END$$

DELIMITER ;


-- ============================================================================
-- PROCEDIMIENTO: Carga Histórica Completa
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_carga_historica_ventas()
BEGIN
  
  DECLARE v_fecha_minima DATE;
  DECLARE v_fecha_maxima DATE;
  
  -- Obtener rango de fechas
  SELECT MIN(fecha), MAX(fecha) 
  INTO v_fecha_minima, v_fecha_maxima
  FROM ventas;
  
  -- Cargar todas las dimensiones
  CALL sp_cargar_todas_dimensiones();
  
  -- Cargar todas las ventas históricas
  CALL sp_cargar_fact_ventas(v_fecha_minima, v_fecha_maxima);
  
  SELECT CONCAT('Carga histórica completada desde ', 
                v_fecha_minima, ' hasta ', v_fecha_maxima) AS mensaje;
  
END$$

DELIMITER ;


-- ============================================================================
-- PROCEDIMIENTO: Actualizar Fact Ventas Diarias (agregado)
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_actualizar_fact_ventas_diarias(
  IN p_fecha DATE
)
BEGIN
  
  DELETE FROM fact_ventas_diarias 
  WHERE fecha_proceso = p_fecha;
  
  INSERT INTO fact_ventas_diarias (
    tiempo_key,
    cliente_key,
    producto_key,
    vendedor_key,
    cantidad_total,
    numero_transacciones,
    venta_exenta_total,
    venta_gravada_total,
    venta_total,
    venta_total_con_impuestos,
    venta_promedio,
    venta_maxima,
    venta_minima,
    fecha_proceso
  )
  SELECT 
    tiempo_key,
    cliente_key,
    producto_key,
    vendedor_key,
    SUM(cantidad) AS cantidad_total,
    COUNT(*) AS numero_transacciones,
    SUM(venta_exenta) AS venta_exenta_total,
    SUM(venta_gravada) AS venta_gravada_total,
    SUM(venta_total) AS venta_total,
    SUM(venta_total_con_impuestos) AS venta_total_con_impuestos,
    AVG(venta_total) AS venta_promedio,
    MAX(venta_total) AS venta_maxima,
    MIN(venta_total) AS venta_minima,
    p_fecha
  FROM fact_ventas
  WHERE fecha_venta = p_fecha
    AND esta_anulado = FALSE
  GROUP BY 
    tiempo_key,
    cliente_key,
    producto_key,
    vendedor_key;
  
END$$

DELIMITER ;


-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

-- Carga histórica completa (ejecutar una sola vez)
-- CALL sp_carga_historica_ventas();

-- Carga incremental por rango de fechas
-- CALL sp_cargar_fact_ventas('2024-01-01', '2024-12-31');

-- ETL diario (programar en cron o scheduler)
-- CALL sp_etl_diario();

-- Actualizar una venta específica
-- CALL sp_actualizar_fact_ventas(12345);

