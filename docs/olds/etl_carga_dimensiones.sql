-- ============================================================================
-- ETL - CARGA DE DIMENSIONES
-- Data Warehouse - Proceso de Ventas
-- ============================================================================

-- ============================================================================
-- 1. CARGA DIMENSIÓN TIEMPO
-- ============================================================================
-- Procedimiento para poblar la dimensión tiempo con un rango de fechas

DELIMITER $$

CREATE PROCEDURE sp_poblar_dim_tiempo(
  IN fecha_inicio DATE,
  IN fecha_fin DATE
)
BEGIN
  DECLARE v_fecha DATE;
  DECLARE v_anio INT;
  DECLARE v_mes INT;
  DECLARE v_dia INT;
  DECLARE v_dia_semana INT;
  
  SET v_fecha = fecha_inicio;
  
  WHILE v_fecha <= fecha_fin DO
    
    SET v_anio = YEAR(v_fecha);
    SET v_mes = MONTH(v_fecha);
    SET v_dia = DAY(v_fecha);
    SET v_dia_semana = DAYOFWEEK(v_fecha);
    
    INSERT INTO dim_tiempo (
      fecha,
      anio,
      trimestre,
      mes,
      mes_nombre,
      semana_anio,
      dia_mes,
      dia_semana,
      dia_semana_nombre,
      es_fin_semana,
      periodo_fiscal
    ) VALUES (
      v_fecha,
      v_anio,
      QUARTER(v_fecha),
      v_mes,
      CASE v_mes
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
      END,
      WEEK(v_fecha, 1),
      v_dia,
      v_dia_semana,
      CASE v_dia_semana
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miércoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sábado'
      END,
      IF(v_dia_semana IN (1, 7), TRUE, FALSE),
      CONCAT(v_anio, '-', LPAD(v_mes, 2, '0'))
    )
    ON DUPLICATE KEY UPDATE tiempo_key = tiempo_key;
    
    SET v_fecha = DATE_ADD(v_fecha, INTERVAL 1 DAY);
    
  END WHILE;
  
END$$

DELIMITER ;

-- Ejemplo de uso: Poblar desde 2020 hasta 2030
-- CALL sp_poblar_dim_tiempo('2020-01-01', '2030-12-31');


-- ============================================================================
-- 2. CARGA DIMENSIÓN TIPO DOCUMENTO
-- ============================================================================

INSERT INTO dim_tipo_documento (tipo_documento_id, codigo, nombre)
SELECT 
  id,
  codigo,
  nombre
FROM tipo_documentos
ON DUPLICATE KEY UPDATE 
  codigo = VALUES(codigo),
  nombre = VALUES(nombre);


-- ============================================================================
-- 3. CARGA DIMENSIÓN CONDICIÓN DE PAGO
-- ============================================================================

INSERT INTO dim_condicion_pago (condicion_pago_id, codigo, nombre)
SELECT 
  id,
  codigo,
  nombre
FROM condiciones_pago
ON DUPLICATE KEY UPDATE 
  codigo = VALUES(codigo),
  nombre = VALUES(nombre);


-- ============================================================================
-- 4. CARGA DIMENSIÓN ESTADO VENTA
-- ============================================================================

INSERT INTO dim_estado_venta (estado_venta_id, codigo, nombre)
SELECT 
  id,
  codigo,
  nombre
FROM estados_ventas
ON DUPLICATE KEY UPDATE 
  codigo = VALUES(codigo),
  nombre = VALUES(nombre);


-- ============================================================================
-- 5. CARGA DIMENSIÓN UBICACIÓN
-- ============================================================================

INSERT INTO dim_ubicacion (
  municipio_id,
  municipio_nombre,
  departamento_id,
  departamento_nombre,
  departamento_isocode,
  zonesv_id
)
SELECT 
  m.id,
  m.nombre,
  d.id,
  d.nombre,
  d.isocode,
  d.zonesv_id
FROM municipios m
INNER JOIN departamentos d ON m.departamento_id = d.id
ON DUPLICATE KEY UPDATE 
  municipio_nombre = VALUES(municipio_nombre),
  departamento_nombre = VALUES(departamento_nombre),
  departamento_isocode = VALUES(departamento_isocode),
  zonesv_id = VALUES(zonesv_id);


-- ============================================================================
-- 6. CARGA DIMENSIÓN CLIENTE (SCD Tipo 2)
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_cargar_dim_cliente()
BEGIN
  
  -- Cerrar registros que han cambiado (SCD Tipo 2)
  UPDATE dim_cliente dc
  INNER JOIN clientes c ON dc.cliente_id = c.id
  SET 
    dc.fecha_fin = NOW(),
    dc.es_actual = FALSE
  WHERE 
    dc.es_actual = TRUE
    AND (
      dc.nombre != c.nombre OR
      COALESCE(dc.telefono_1, '') != COALESCE(c.telefono_1, '') OR
      COALESCE(dc.direccion, '') != COALESCE(c.direccion, '') OR
      COALESCE(dc.nit, '') != COALESCE(c.nit, '') OR
      COALESCE(dc.correo, '') != COALESCE(c.correo, '')
    );
  
  -- Insertar nuevos registros o versiones actualizadas
  INSERT INTO dim_cliente (
    cliente_id,
    nombre,
    nombre_alternativo,
    telefono_1,
    telefono_2,
    direccion,
    correo,
    nit,
    nrc,
    giro,
    nombre_contacto,
    retencion,
    municipio,
    departamento,
    fecha_inicio,
    es_actual,
    version
  )
  SELECT 
    c.id,
    c.nombre,
    c.nombre_alternativo,
    c.telefono_1,
    c.telefono_2,
    c.direccion,
    c.correo,
    c.nit,
    c.nrc,
    c.giro,
    c.nombre_contacto,
    c.retencion,
    m.nombre AS municipio,
    d.nombre AS departamento,
    NOW(),
    TRUE,
    COALESCE(
      (SELECT MAX(version) + 1 
       FROM dim_cliente dc2 
       WHERE dc2.cliente_id = c.id), 
      1
    )
  FROM clientes c
  LEFT JOIN municipios m ON c.municipio_id = m.id
  LEFT JOIN departamentos d ON m.departamento_id = d.id
  LEFT JOIN dim_cliente dc ON c.id = dc.cliente_id AND dc.es_actual = TRUE
  WHERE dc.cliente_key IS NULL
     OR dc.fecha_fin IS NOT NULL;
  
END$$

DELIMITER ;


-- ============================================================================
-- 7. CARGA DIMENSIÓN PRODUCTO (SCD Tipo 2)
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_cargar_dim_producto()
BEGIN
  
  -- Cerrar registros que han cambiado (SCD Tipo 2)
  UPDATE dim_producto dp
  INNER JOIN productos p ON dp.producto_id = p.id
  INNER JOIN categorias cat ON p.categoria_id = cat.id
  INNER JOIN tipo_productos tp ON p.tipo_producto_id = tp.id
  INNER JOIN unidad_medidas um ON p.unidad_medida_id = um.id
  SET 
    dp.fecha_fin = NOW(),
    dp.es_actual = FALSE
  WHERE 
    dp.es_actual = TRUE
    AND (
      dp.nombre != p.nombre OR
      COALESCE(dp.codigo, '') != COALESCE(p.codigo, '') OR
      dp.categoria_nombre != cat.nombre OR
      dp.tipo_producto_nombre != tp.nombre OR
      dp.producto_activo != p.producto_activo
    );
  
  -- Insertar nuevos registros o versiones actualizadas
  INSERT INTO dim_producto (
    producto_id,
    nombre,
    nombre_alternativo,
    codigo,
    categoria_codigo,
    categoria_nombre,
    tipo_producto_codigo,
    tipo_producto_nombre,
    unidad_medida_nombre,
    unidad_medida_abreviatura,
    producto_activo,
    fecha_inicio,
    es_actual,
    version
  )
  SELECT 
    p.id,
    p.nombre,
    p.nombre_alternativo,
    p.codigo,
    cat.codigo,
    cat.nombre,
    tp.codigo,
    tp.nombre,
    um.nombre,
    um.abreviatura,
    p.producto_activo,
    NOW(),
    TRUE,
    COALESCE(
      (SELECT MAX(version) + 1 
       FROM dim_producto dp2 
       WHERE dp2.producto_id = p.id), 
      1
    )
  FROM productos p
  INNER JOIN categorias cat ON p.categoria_id = cat.id
  INNER JOIN tipo_productos tp ON p.tipo_producto_id = tp.id
  INNER JOIN unidad_medidas um ON p.unidad_medida_id = um.id
  LEFT JOIN dim_producto dp ON p.id = dp.producto_id AND dp.es_actual = TRUE
  WHERE dp.producto_key IS NULL
     OR dp.fecha_fin IS NOT NULL;
  
END$$

DELIMITER ;


-- ============================================================================
-- 8. CARGA DIMENSIÓN VENDEDOR (SCD Tipo 2)
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_cargar_dim_vendedor()
BEGIN
  
  -- Cerrar registros que han cambiado (SCD Tipo 2)
  UPDATE dim_vendedor dv
  INNER JOIN users u ON dv.vendedor_id = u.id
  INNER JOIN roles r ON u.rol_id = r.id
  SET 
    dv.fecha_fin = NOW(),
    dv.es_actual = FALSE
  WHERE 
    dv.es_actual = TRUE
    AND (
      dv.nombre != u.nombre OR
      COALESCE(dv.apellido, '') != COALESCE(u.apellido, '') OR
      COALESCE(dv.email, '') != COALESCE(u.email, '') OR
      COALESCE(dv.telefono, '') != COALESCE(u.telefono, '') OR
      dv.rol_id != u.rol_id
    );
  
  -- Insertar nuevos registros o versiones actualizadas
  INSERT INTO dim_vendedor (
    vendedor_id,
    nombre,
    apellido,
    email,
    username,
    telefono,
    rol_id,
    rol_nombre,
    fecha_inicio,
    es_actual,
    version
  )
  SELECT 
    u.id,
    u.nombre,
    u.apellido,
    u.email,
    u.username,
    u.telefono,
    u.rol_id,
    r.nombre,
    NOW(),
    TRUE,
    COALESCE(
      (SELECT MAX(version) + 1 
       FROM dim_vendedor dv2 
       WHERE dv2.vendedor_id = u.id), 
      1
    )
  FROM users u
  INNER JOIN roles r ON u.rol_id = r.id
  LEFT JOIN dim_vendedor dv ON u.id = dv.vendedor_id AND dv.es_actual = TRUE
  WHERE dv.vendedor_key IS NULL
     OR dv.fecha_fin IS NOT NULL;
  
END$$

DELIMITER ;


-- ============================================================================
-- 9. PROCEDIMIENTO MAESTRO - CARGAR TODAS LAS DIMENSIONES
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_cargar_todas_dimensiones()
BEGIN
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SELECT 'Error al cargar dimensiones' AS mensaje;
  END;
  
  START TRANSACTION;
  
  -- Cargar dimensiones estáticas
  CALL sp_poblar_dim_tiempo('2020-01-01', '2030-12-31');
  
  -- Cargar catálogos
  INSERT INTO dim_tipo_documento (tipo_documento_id, codigo, nombre)
  SELECT id, codigo, nombre FROM tipo_documentos
  ON DUPLICATE KEY UPDATE codigo = VALUES(codigo), nombre = VALUES(nombre);
  
  INSERT INTO dim_condicion_pago (condicion_pago_id, codigo, nombre)
  SELECT id, codigo, nombre FROM condiciones_pago
  ON DUPLICATE KEY UPDATE codigo = VALUES(codigo), nombre = VALUES(nombre);
  
  INSERT INTO dim_estado_venta (estado_venta_id, codigo, nombre)
  SELECT id, codigo, nombre FROM estados_ventas
  ON DUPLICATE KEY UPDATE codigo = VALUES(codigo), nombre = VALUES(nombre);
  
  INSERT INTO dim_ubicacion (municipio_id, municipio_nombre, departamento_id, departamento_nombre, departamento_isocode, zonesv_id)
  SELECT m.id, m.nombre, d.id, d.nombre, d.isocode, d.zonesv_id
  FROM municipios m
  INNER JOIN departamentos d ON m.departamento_id = d.id
  ON DUPLICATE KEY UPDATE 
    municipio_nombre = VALUES(municipio_nombre),
    departamento_nombre = VALUES(departamento_nombre);
  
  -- Cargar dimensiones SCD Tipo 2
  CALL sp_cargar_dim_cliente();
  CALL sp_cargar_dim_producto();
  CALL sp_cargar_dim_vendedor();
  
  COMMIT;
  
  SELECT 'Dimensiones cargadas exitosamente' AS mensaje;
  
END$$

DELIMITER ;

-- ============================================================================
-- EJECUCIÓN INICIAL
-- ============================================================================

-- Para ejecutar la carga completa:
-- CALL sp_cargar_todas_dimensiones();

