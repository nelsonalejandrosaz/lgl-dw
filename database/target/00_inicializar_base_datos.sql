-- ============================================================================
-- SCRIPT DE INICIALIZACIÓN - SQL SERVER
-- Data Warehouse - Proceso de Ventas
-- ============================================================================
-- Ejecutar este script PRIMERO antes que todos los demás
-- ============================================================================

USE master;
GO

-- ============================================================================
-- CREAR BASE DE DATOS DEL DATA WAREHOUSE
-- ============================================================================

-- Verificar si la base de datos existe
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'LGL_DW')
BEGIN
    PRINT 'La base de datos LGL_DW ya existe. Eliminando...';
    
    -- Cambiar a base de datos master
    USE master;
    
    -- Cerrar conexiones existentes
    ALTER DATABASE LGL_DW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    -- Eliminar base de datos
    DROP DATABASE LGL_DW;
    
    PRINT 'Base de datos eliminada exitosamente.';
END
GO

-- Crear base de datos
CREATE DATABASE LGL_DW
    ON PRIMARY
    (
        NAME = N'LGL_DW_Data',
        FILENAME = N'C:\SQLData\LGL_DW_Data.mdf',  -- Ajustar ruta según tu instalación
        SIZE = 100MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 50MB
    )
    LOG ON
    (
        NAME = N'LGL_DW_Log',
        FILENAME = N'C:\SQLData\LGL_DW_Log.ldf',   -- Ajustar ruta según tu instalación
        SIZE = 50MB,
        MAXSIZE = 2GB,
        FILEGROWTH = 10MB
    )
    COLLATE Modern_Spanish_CI_AS;  -- Collation para español
GO

-- Configurar opciones de la base de datos
ALTER DATABASE LGL_DW SET RECOVERY SIMPLE;  -- Para desarrollo
-- ALTER DATABASE LGL_DW SET RECOVERY FULL;  -- Para producción
GO

ALTER DATABASE LGL_DW SET AUTO_CREATE_STATISTICS ON;
GO

ALTER DATABASE LGL_DW SET AUTO_UPDATE_STATISTICS ON;
GO

ALTER DATABASE LGL_DW SET PAGE_VERIFY CHECKSUM;
GO

-- Usar la base de datos
USE LGL_DW;
GO

PRINT 'Base de datos LGL_DW creada exitosamente.';
PRINT 'Proceda a ejecutar los siguientes scripts en orden:';
PRINT '  1. 01_crear_dimensiones.sql';
PRINT '  2. 02_crear_hechos.sql';
PRINT '  3. 03_crear_vistas.sql';
PRINT '  4. 04_crear_stored_procedures.sql';
GO

-- ============================================================================
-- CREAR ESQUEMA DE STAGING (Opcional - para proceso ETL)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
    PRINT 'Schema staging creado exitosamente.';
END
GO

-- ============================================================================
-- INFORMACIÓN DE LA BASE DE DATOS
-- ============================================================================

SELECT 
    name AS 'Base de Datos',
    database_id AS 'ID',
    create_date AS 'Fecha de Creación',
    collation_name AS 'Collation',
    recovery_model_desc AS 'Modelo de Recuperación',
    compatibility_level AS 'Nivel de Compatibilidad',
    (SELECT SUM(size) * 8 / 1024 FROM sys.master_files WHERE database_id = DB_ID('LGL_DW') AND type = 0) AS 'Tamaño Data (MB)',
    (SELECT SUM(size) * 8 / 1024 FROM sys.master_files WHERE database_id = DB_ID('LGL_DW') AND type = 1) AS 'Tamaño Log (MB)'
FROM sys.databases
WHERE name = 'LGL_DW';
GO
