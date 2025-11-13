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

-- Crear base de datos (SQL Server usará la ubicación por defecto)
CREATE DATABASE LGL_DW
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
-- CREAR USUARIO PARA ETL Y POWER BI
-- ============================================================================

-- Crear login a nivel de servidor (ajustar contraseña)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'etl_dw_user')
BEGIN
    CREATE LOGIN etl_dw_user WITH PASSWORD = 'ETL_DW_P@ssw0rd2024!',
        CHECK_POLICY = OFF,
        CHECK_EXPIRATION = OFF;
    PRINT 'Login etl_dw_user creado exitosamente.';
END
GO

-- Crear usuario en la base de datos
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'etl_dw_user')
BEGIN
    CREATE USER etl_dw_user FOR LOGIN etl_dw_user;
    PRINT 'Usuario etl_dw_user creado en LGL_DW.';
END
GO

-- Otorgar permisos de lectura y escritura
ALTER ROLE db_datareader ADD MEMBER etl_dw_user;
ALTER ROLE db_datawriter ADD MEMBER etl_dw_user;
GO

-- Otorgar permisos para ejecutar stored procedures
GRANT EXECUTE TO etl_dw_user;
GO

-- Otorgar permisos ALTER para permitir TRUNCATE TABLE
GRANT ALTER ON SCHEMA::dbo TO etl_dw_user;
GO

PRINT 'Permisos otorgados a etl_dw_user:';
PRINT '  - Lectura (db_datareader)';
PRINT '  - Escritura (db_datawriter)';
PRINT '  - Ejecución de procedimientos almacenados';
PRINT '  - ALTER en schema dbo (para TRUNCATE)';
PRINT '';
PRINT 'IMPORTANTE: Cambiar la contraseña del usuario etl_dw_user en producción.';
GO

-- ============================================================================
-- INFORMACIÓN DE LA BASE DE DATOS
-- ============================================================================

-- Información de la base de datos
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

-- Verificar usuario creado
SELECT 
    dp.name AS 'Usuario',
    dp.type_desc AS 'Tipo',
    STRING_AGG(r.name, ', ') AS 'Roles'
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
LEFT JOIN sys.database_principals r ON drm.role_principal_id = r.principal_id
WHERE dp.name = 'etl_dw_user'
GROUP BY dp.name, dp.type_desc;
GO
