-- ============================================================================
-- DATA WAREHOUSE - PROCESO DE VENTAS
-- Modelo Dimensional - Star Schema
-- Fecha: 2025-11-12
-- ============================================================================

-- ============================================================================
-- DIMENSIONES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Dimensión Tiempo
-- ----------------------------------------------------------------------------
CREATE TABLE dim_tiempo (
  tiempo_key INT PRIMARY KEY AUTO_INCREMENT,
  fecha DATE NOT NULL UNIQUE,
  anio INT NOT NULL,
  trimestre INT NOT NULL,
  mes INT NOT NULL,
  mes_nombre VARCHAR(20) NOT NULL,
  semana_anio INT NOT NULL,
  dia_mes INT NOT NULL,
  dia_semana INT NOT NULL,
  dia_semana_nombre VARCHAR(20) NOT NULL,
  es_fin_semana BOOLEAN NOT NULL,
  es_festivo BOOLEAN DEFAULT FALSE,
  periodo_fiscal VARCHAR(10) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dim_tiempo_fecha ON dim_tiempo(fecha);
CREATE INDEX idx_dim_tiempo_anio_mes ON dim_tiempo(anio, mes);

-- ----------------------------------------------------------------------------
-- Dimensión Cliente
-- ----------------------------------------------------------------------------
CREATE TABLE dim_cliente (
  cliente_key INT PRIMARY KEY AUTO_INCREMENT,
  cliente_id INT NOT NULL,
  nombre VARCHAR(191) NOT NULL,
  nombre_alternativo VARCHAR(191),
  telefono_1 VARCHAR(25),
  telefono_2 VARCHAR(25),
  direccion VARCHAR(255),
  correo VARCHAR(100),
  nit VARCHAR(191),
  nrc VARCHAR(191),
  giro VARCHAR(191),
  nombre_contacto VARCHAR(191),
  retencion BOOLEAN DEFAULT FALSE,
  municipio VARCHAR(191),
  departamento VARCHAR(191),
  -- Campos SCD Tipo 2
  fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin DATETIME DEFAULT NULL,
  version INT DEFAULT 1,
  es_actual BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dim_cliente_id ON dim_cliente(cliente_id);
CREATE INDEX idx_dim_cliente_actual ON dim_cliente(es_actual);
CREATE INDEX idx_dim_cliente_departamento ON dim_cliente(departamento);

-- ----------------------------------------------------------------------------
-- Dimensión Producto
-- ----------------------------------------------------------------------------
CREATE TABLE dim_producto (
  producto_key INT PRIMARY KEY AUTO_INCREMENT,
  producto_id INT NOT NULL,
  nombre VARCHAR(191) NOT NULL,
  nombre_alternativo VARCHAR(191),
  codigo VARCHAR(50),
  categoria_codigo VARCHAR(2),
  categoria_nombre VARCHAR(50),
  tipo_producto_codigo VARCHAR(2),
  tipo_producto_nombre VARCHAR(50),
  unidad_medida_nombre VARCHAR(50),
  unidad_medida_abreviatura VARCHAR(10),
  producto_activo BOOLEAN DEFAULT TRUE,
  -- Campos SCD Tipo 2
  fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin DATETIME DEFAULT NULL,
  version INT DEFAULT 1,
  es_actual BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dim_producto_id ON dim_producto(producto_id);
CREATE INDEX idx_dim_producto_actual ON dim_producto(es_actual);
CREATE INDEX idx_dim_producto_categoria ON dim_producto(categoria_nombre);
CREATE INDEX idx_dim_producto_tipo ON dim_producto(tipo_producto_nombre);

-- ----------------------------------------------------------------------------
-- Dimensión Vendedor
-- ----------------------------------------------------------------------------
CREATE TABLE dim_vendedor (
  vendedor_key INT PRIMARY KEY AUTO_INCREMENT,
  vendedor_id INT NOT NULL,
  nombre VARCHAR(191) NOT NULL,
  apellido VARCHAR(191),
  email VARCHAR(191),
  username VARCHAR(191),
  telefono VARCHAR(20),
  rol_id INT,
  rol_nombre VARCHAR(25),
  -- Campos SCD Tipo 2
  fecha_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin DATETIME DEFAULT NULL,
  version INT DEFAULT 1,
  es_actual BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dim_vendedor_id ON dim_vendedor(vendedor_id);
CREATE INDEX idx_dim_vendedor_actual ON dim_vendedor(es_actual);

-- ----------------------------------------------------------------------------
-- Dimensión Tipo Documento
-- ----------------------------------------------------------------------------
CREATE TABLE dim_tipo_documento (
  tipo_documento_key INT PRIMARY KEY AUTO_INCREMENT,
  tipo_documento_id INT NOT NULL UNIQUE,
  codigo VARCHAR(10) NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Dimensión Condición de Pago
-- ----------------------------------------------------------------------------
CREATE TABLE dim_condicion_pago (
  condicion_pago_key INT PRIMARY KEY AUTO_INCREMENT,
  condicion_pago_id INT NOT NULL UNIQUE,
  codigo VARCHAR(10) NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Dimensión Estado Venta
-- ----------------------------------------------------------------------------
CREATE TABLE dim_estado_venta (
  estado_venta_key INT PRIMARY KEY AUTO_INCREMENT,
  estado_venta_id INT NOT NULL UNIQUE,
  codigo VARCHAR(10) NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Dimensión Ubicación Geográfica
-- ----------------------------------------------------------------------------
CREATE TABLE dim_ubicacion (
  ubicacion_key INT PRIMARY KEY AUTO_INCREMENT,
  municipio_id INT NOT NULL UNIQUE,
  municipio_nombre VARCHAR(191) NOT NULL,
  departamento_id INT NOT NULL,
  departamento_nombre VARCHAR(191) NOT NULL,
  departamento_isocode VARCHAR(6),
  zonesv_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_dim_ubicacion_departamento ON dim_ubicacion(departamento_nombre);


-- ============================================================================
-- TABLA DE HECHOS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Fact Table: Ventas
-- ----------------------------------------------------------------------------
CREATE TABLE fact_ventas (
  venta_key BIGINT PRIMARY KEY AUTO_INCREMENT,
  
  -- Foreign Keys a Dimensiones
  tiempo_key INT NOT NULL,
  cliente_key INT NOT NULL,
  producto_key INT NOT NULL,
  vendedor_key INT,
  tipo_documento_key INT NOT NULL,
  condicion_pago_key INT,
  estado_venta_key INT NOT NULL,
  
  -- Degenerate Dimensions (Dimensiones Degeneradas)
  venta_id INT NOT NULL,
  orden_pedido_id INT,
  numero_venta VARCHAR(191),
  
  -- Métricas Aditivas (Measures)
  cantidad DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  precio_unitario DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_exenta DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_gravada DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_total DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  iva DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_total_con_impuestos DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  flete DECIMAL(12,4) DEFAULT 0.0000,
  
  -- Métricas Semi-Aditivas
  saldo DECIMAL(12,4) DEFAULT 0.0000,
  
  -- Métricas Derivadas (calculadas)
  costo_venta DECIMAL(12,4) DEFAULT 0.0000,
  margen_bruto DECIMAL(12,4) DEFAULT 0.0000,
  porcentaje_margen DECIMAL(8,2) DEFAULT 0.00,
  
  -- Indicadores
  es_venta_credito BOOLEAN DEFAULT FALSE,
  tiene_comision BOOLEAN DEFAULT FALSE,
  esta_liquidado BOOLEAN DEFAULT FALSE,
  esta_anulado BOOLEAN DEFAULT FALSE,
  
  -- Fechas relevantes
  fecha_venta DATE NOT NULL,
  fecha_liquidacion DATE,
  fecha_anulacion DATE,
  
  -- Metadatos
  fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Constraints
  CONSTRAINT fk_fact_ventas_tiempo FOREIGN KEY (tiempo_key) 
    REFERENCES dim_tiempo(tiempo_key),
  CONSTRAINT fk_fact_ventas_cliente FOREIGN KEY (cliente_key) 
    REFERENCES dim_cliente(cliente_key),
  CONSTRAINT fk_fact_ventas_producto FOREIGN KEY (producto_key) 
    REFERENCES dim_producto(producto_key),
  CONSTRAINT fk_fact_ventas_vendedor FOREIGN KEY (vendedor_key) 
    REFERENCES dim_vendedor(vendedor_key),
  CONSTRAINT fk_fact_ventas_tipo_doc FOREIGN KEY (tipo_documento_key) 
    REFERENCES dim_tipo_documento(tipo_documento_key),
  CONSTRAINT fk_fact_ventas_condicion FOREIGN KEY (condicion_pago_key) 
    REFERENCES dim_condicion_pago(condicion_pago_key),
  CONSTRAINT fk_fact_ventas_estado FOREIGN KEY (estado_venta_key) 
    REFERENCES dim_estado_venta(estado_venta_key)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índices para optimizar consultas
CREATE INDEX idx_fact_ventas_tiempo ON fact_ventas(tiempo_key);
CREATE INDEX idx_fact_ventas_cliente ON fact_ventas(cliente_key);
CREATE INDEX idx_fact_ventas_producto ON fact_ventas(producto_key);
CREATE INDEX idx_fact_ventas_vendedor ON fact_ventas(vendedor_key);
CREATE INDEX idx_fact_ventas_fecha ON fact_ventas(fecha_venta);
CREATE INDEX idx_fact_ventas_venta_id ON fact_ventas(venta_id);
CREATE INDEX idx_fact_ventas_estado ON fact_ventas(estado_venta_key);

-- Índices compuestos para queries comunes
CREATE INDEX idx_fact_ventas_tiempo_cliente ON fact_ventas(tiempo_key, cliente_key);
CREATE INDEX idx_fact_ventas_tiempo_producto ON fact_ventas(tiempo_key, producto_key);
CREATE INDEX idx_fact_ventas_tiempo_vendedor ON fact_ventas(tiempo_key, vendedor_key);


-- ============================================================================
-- TABLA DE HECHOS AGREGADA (Opcional - para mejor performance)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Fact Table Agregada: Ventas por Día
-- ----------------------------------------------------------------------------
CREATE TABLE fact_ventas_diarias (
  ventas_diarias_key BIGINT PRIMARY KEY AUTO_INCREMENT,
  tiempo_key INT NOT NULL,
  cliente_key INT NOT NULL,
  producto_key INT NOT NULL,
  vendedor_key INT,
  
  -- Métricas Agregadas
  cantidad_total DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  numero_transacciones INT NOT NULL DEFAULT 0,
  venta_exenta_total DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_gravada_total DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_total DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  venta_total_con_impuestos DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  
  -- Métricas Estadísticas
  venta_promedio DECIMAL(12,4) DEFAULT 0.0000,
  venta_maxima DECIMAL(12,4) DEFAULT 0.0000,
  venta_minima DECIMAL(12,4) DEFAULT 0.0000,
  
  fecha_proceso DATE NOT NULL,
  fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT fk_fact_ventas_dia_tiempo FOREIGN KEY (tiempo_key) 
    REFERENCES dim_tiempo(tiempo_key),
  CONSTRAINT fk_fact_ventas_dia_cliente FOREIGN KEY (cliente_key) 
    REFERENCES dim_cliente(cliente_key),
  CONSTRAINT fk_fact_ventas_dia_producto FOREIGN KEY (producto_key) 
    REFERENCES dim_producto(producto_key),
  CONSTRAINT fk_fact_ventas_dia_vendedor FOREIGN KEY (vendedor_key) 
    REFERENCES dim_vendedor(vendedor_key),
    
  UNIQUE KEY uk_ventas_diarias (tiempo_key, cliente_key, producto_key, vendedor_key)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- VISTAS ANALÍTICAS
-- ============================================================================

-- Vista para análisis de ventas completo
CREATE OR REPLACE VIEW v_analisis_ventas AS
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
  
  -- Dimensión Cliente
  dc.nombre AS cliente_nombre,
  dc.municipio,
  dc.departamento,
  dc.nit AS cliente_nit,
  
  -- Dimensión Producto
  dp.nombre AS producto_nombre,
  dp.codigo AS producto_codigo,
  dp.categoria_nombre,
  dp.tipo_producto_nombre,
  
  -- Dimensión Vendedor
  dv.nombre AS vendedor_nombre,
  dv.apellido AS vendedor_apellido,
  
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
  fv.esta_anulado
  
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
INNER JOIN dim_cliente dc ON fv.cliente_key = dc.cliente_key
INNER JOIN dim_producto dp ON fv.producto_key = dp.producto_key
LEFT JOIN dim_vendedor dv ON fv.vendedor_key = dv.vendedor_key
INNER JOIN dim_tipo_documento dtd ON fv.tipo_documento_key = dtd.tipo_documento_key
LEFT JOIN dim_condicion_pago dcp ON fv.condicion_pago_key = dcp.condicion_pago_key
INNER JOIN dim_estado_venta dev ON fv.estado_venta_key = dev.estado_venta_key;

-- ============================================================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================================================

-- Tabla fact_ventas: Contiene el detalle granular de cada línea de venta
-- Granularidad: Una fila por cada producto vendido en cada transacción
-- Actualización: Carga incremental diaria con actualización de dimensiones SCD

