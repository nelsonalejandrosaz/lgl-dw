-- ============================================================================
-- DATA WAREHOUSE - PROCESO DE VENTAS
-- SQL SERVER - DIMENSIONES
-- Fecha: 2025-11-12
-- ============================================================================

USE [LGL_DW];
GO

-- ============================================================================
-- DIMENSIONES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Dimensión Tiempo
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_tiempo', 'U') IS NOT NULL
    DROP TABLE dbo.dim_tiempo;
GO

CREATE TABLE dbo.dim_tiempo (
    tiempo_key INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT NOT NULL,
    trimestre INT NOT NULL,
    mes INT NOT NULL,
    mes_nombre VARCHAR(20) NOT NULL,
    semana_anio INT NOT NULL,
    dia_mes INT NOT NULL,
    dia_semana INT NOT NULL,
    dia_semana_nombre VARCHAR(20) NOT NULL,
    es_fin_semana BIT NOT NULL,
    es_festivo BIT DEFAULT 0,
    periodo_fiscal VARCHAR(10) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE NONCLUSTERED INDEX idx_dim_tiempo_fecha ON dbo.dim_tiempo(fecha);
CREATE NONCLUSTERED INDEX idx_dim_tiempo_anio_mes ON dbo.dim_tiempo(anio, mes);
GO

-- ----------------------------------------------------------------------------
-- Dimensión Cliente
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_cliente', 'U') IS NOT NULL
    DROP TABLE dbo.dim_cliente;
GO

CREATE TABLE dbo.dim_cliente (
    cliente_key INT IDENTITY(1,1) PRIMARY KEY,
    cliente_id INT NOT NULL,
    nombre NVARCHAR(191) NOT NULL,
    nombre_alternativo NVARCHAR(191) NULL,
    telefono_1 VARCHAR(25) NULL,
    telefono_2 VARCHAR(25) NULL,
    direccion NVARCHAR(255) NULL,
    correo VARCHAR(100) NULL,
    nit VARCHAR(191) NULL,
    nrc VARCHAR(191) NULL,
    giro NVARCHAR(191) NULL,
    nombre_contacto NVARCHAR(191) NULL,
    retencion BIT DEFAULT 0,
    municipio NVARCHAR(191) NULL,
    departamento NVARCHAR(191) NULL,
    -- Campos SCD Tipo 2
    fecha_inicio DATETIME2 NOT NULL DEFAULT GETDATE(),
    fecha_fin DATETIME2 NULL,
    version INT DEFAULT 1,
    es_actual BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE NONCLUSTERED INDEX idx_dim_cliente_id ON dbo.dim_cliente(cliente_id);
CREATE NONCLUSTERED INDEX idx_dim_cliente_actual ON dbo.dim_cliente(es_actual) WHERE es_actual = 1;
CREATE NONCLUSTERED INDEX idx_dim_cliente_departamento ON dbo.dim_cliente(departamento);
GO

-- ----------------------------------------------------------------------------
-- Dimensión Producto
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_producto', 'U') IS NOT NULL
    DROP TABLE dbo.dim_producto;
GO

CREATE TABLE dbo.dim_producto (
    producto_key INT IDENTITY(1,1) PRIMARY KEY,
    producto_id INT NOT NULL,
    nombre NVARCHAR(191) NOT NULL,
    nombre_alternativo NVARCHAR(191) NULL,
    codigo VARCHAR(50) NULL,
    categoria_codigo VARCHAR(2) NULL,
    categoria_nombre VARCHAR(50) NULL,
    tipo_producto_codigo VARCHAR(2) NULL,
    tipo_producto_nombre VARCHAR(50) NULL,
    unidad_medida_nombre VARCHAR(50) NULL,
    unidad_medida_abreviatura VARCHAR(10) NULL,
    producto_activo BIT DEFAULT 1,
    -- Campos SCD Tipo 2
    fecha_inicio DATETIME2 NOT NULL DEFAULT GETDATE(),
    fecha_fin DATETIME2 NULL,
    version INT DEFAULT 1,
    es_actual BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE NONCLUSTERED INDEX idx_dim_producto_id ON dbo.dim_producto(producto_id);
CREATE NONCLUSTERED INDEX idx_dim_producto_actual ON dbo.dim_producto(es_actual) WHERE es_actual = 1;
CREATE NONCLUSTERED INDEX idx_dim_producto_categoria ON dbo.dim_producto(categoria_nombre);
CREATE NONCLUSTERED INDEX idx_dim_producto_tipo ON dbo.dim_producto(tipo_producto_nombre);
GO

-- ----------------------------------------------------------------------------
-- Dimensión Vendedor
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_vendedor', 'U') IS NOT NULL
    DROP TABLE dbo.dim_vendedor;
GO

CREATE TABLE dbo.dim_vendedor (
    vendedor_key INT IDENTITY(1,1) PRIMARY KEY,
    vendedor_id INT NOT NULL,
    nombre NVARCHAR(191) NOT NULL,
    apellido NVARCHAR(191) NULL,
    email VARCHAR(191) NULL,
    username VARCHAR(191) NULL,
    telefono VARCHAR(20) NULL,
    rol_id INT NULL,
    rol_nombre VARCHAR(25) NULL,
    -- Campos SCD Tipo 2
    fecha_inicio DATETIME2 NOT NULL DEFAULT GETDATE(),
    fecha_fin DATETIME2 NULL,
    version INT DEFAULT 1,
    es_actual BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE NONCLUSTERED INDEX idx_dim_vendedor_id ON dbo.dim_vendedor(vendedor_id);
CREATE NONCLUSTERED INDEX idx_dim_vendedor_actual ON dbo.dim_vendedor(es_actual) WHERE es_actual = 1;
GO

-- ----------------------------------------------------------------------------
-- Dimensión Tipo Documento
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_tipo_documento', 'U') IS NOT NULL
    DROP TABLE dbo.dim_tipo_documento;
GO

CREATE TABLE dbo.dim_tipo_documento (
    tipo_documento_key INT IDENTITY(1,1) PRIMARY KEY,
    tipo_documento_id INT NOT NULL UNIQUE,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
GO

-- ----------------------------------------------------------------------------
-- Dimensión Condición de Pago
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_condicion_pago', 'U') IS NOT NULL
    DROP TABLE dbo.dim_condicion_pago;
GO

CREATE TABLE dbo.dim_condicion_pago (
    condicion_pago_key INT IDENTITY(1,1) PRIMARY KEY,
    condicion_pago_id INT NOT NULL UNIQUE,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
GO

-- ----------------------------------------------------------------------------
-- Dimensión Estado Venta
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_estado_venta', 'U') IS NOT NULL
    DROP TABLE dbo.dim_estado_venta;
GO

CREATE TABLE dbo.dim_estado_venta (
    estado_venta_key INT IDENTITY(1,1) PRIMARY KEY,
    estado_venta_id INT NOT NULL UNIQUE,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);
GO

-- ----------------------------------------------------------------------------
-- Dimensión Ubicación Geográfica
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.dim_ubicacion', 'U') IS NOT NULL
    DROP TABLE dbo.dim_ubicacion;
GO

CREATE TABLE dbo.dim_ubicacion (
    ubicacion_key INT IDENTITY(1,1) PRIMARY KEY,
    municipio_id INT NOT NULL UNIQUE,
    municipio_nombre NVARCHAR(191) NOT NULL,
    departamento_id INT NOT NULL,
    departamento_nombre NVARCHAR(191) NOT NULL,
    departamento_isocode VARCHAR(6) NULL,
    zonesv_id INT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE NONCLUSTERED INDEX idx_dim_ubicacion_departamento ON dbo.dim_ubicacion(departamento_nombre);
GO

-- ============================================================================
-- REGISTROS POR DEFECTO
-- ============================================================================

-- Producto desconocido para "otras ventas"
SET IDENTITY_INSERT dbo.dim_producto ON;
GO

INSERT INTO dbo.dim_producto (
    producto_key, producto_id, nombre, categoria_nombre, 
    tipo_producto_nombre, producto_activo, es_actual
)
VALUES (
    -1, -1, 'PRODUCTO NO ESPECIFICADO', 'OTRAS VENTAS', 
    'SERVICIO', 0, 1
);
GO

SET IDENTITY_INSERT dbo.dim_producto OFF;
GO

-- Cliente desconocido
SET IDENTITY_INSERT dbo.dim_cliente ON;
GO

INSERT INTO dbo.dim_cliente (
    cliente_key, cliente_id, nombre, departamento, es_actual
)
VALUES (
    -1, -1, 'CLIENTE NO ESPECIFICADO', 'NO ESPECIFICADO', 1
);
GO

SET IDENTITY_INSERT dbo.dim_cliente OFF;
GO

-- Vendedor desconocido
SET IDENTITY_INSERT dbo.dim_vendedor ON;
GO

INSERT INTO dbo.dim_vendedor (
    vendedor_key, vendedor_id, nombre, apellido, es_actual
)
VALUES (
    -1, -1, 'VENDEDOR', 'NO ESPECIFICADO', 1
);
GO

SET IDENTITY_INSERT dbo.dim_vendedor OFF;
GO

PRINT 'Dimensiones creadas exitosamente';
GO
