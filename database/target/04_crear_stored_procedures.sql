-- ============================================================================
-- DATA WAREHOUSE - PROCESO DE VENTAS
-- SQL SERVER - STORED PROCEDURES
-- Fecha: 2025-11-12
-- ============================================================================

USE [LGL_DW];
GO

-- ============================================================================
-- PROCEDIMIENTO: Poblar Dimensión Tiempo
-- ============================================================================

IF OBJECT_ID('dbo.sp_poblar_dim_tiempo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_poblar_dim_tiempo;
GO

CREATE PROCEDURE dbo.sp_poblar_dim_tiempo
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @v_fecha DATE = @fecha_inicio;
    DECLARE @v_anio INT;
    DECLARE @v_mes INT;
    DECLARE @v_dia INT;
    DECLARE @v_dia_semana INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        WHILE @v_fecha <= @fecha_fin
        BEGIN
            SET @v_anio = YEAR(@v_fecha);
            SET @v_mes = MONTH(@v_fecha);
            SET @v_dia = DAY(@v_fecha);
            SET @v_dia_semana = DATEPART(WEEKDAY, @v_fecha);
            
            IF NOT EXISTS (SELECT 1 FROM dbo.dim_tiempo WHERE fecha = @v_fecha)
            BEGIN
                INSERT INTO dbo.dim_tiempo (
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
                    @v_fecha,
                    @v_anio,
                    DATEPART(QUARTER, @v_fecha),
                    @v_mes,
                    CASE @v_mes
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
                    DATEPART(WEEK, @v_fecha),
                    @v_dia,
                    @v_dia_semana,
                    CASE @v_dia_semana
                        WHEN 1 THEN 'Domingo'
                        WHEN 2 THEN 'Lunes'
                        WHEN 3 THEN 'Martes'
                        WHEN 4 THEN 'Miércoles'
                        WHEN 5 THEN 'Jueves'
                        WHEN 6 THEN 'Viernes'
                        WHEN 7 THEN 'Sábado'
                    END,
                    CASE WHEN @v_dia_semana IN (1, 7) THEN 1 ELSE 0 END,
                    FORMAT(@v_fecha, 'yyyy-MM')
                );
            END
            
            SET @v_fecha = DATEADD(DAY, 1, @v_fecha);
        END
        
        COMMIT TRANSACTION;
        PRINT 'Dimensión tiempo poblada exitosamente';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- ============================================================================
-- PROCEDIMIENTO: Actualizar Fact Ventas Diarias
-- ============================================================================

IF OBJECT_ID('dbo.sp_actualizar_fact_ventas_diarias', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_actualizar_fact_ventas_diarias;
GO

CREATE PROCEDURE dbo.sp_actualizar_fact_ventas_diarias
    @fecha_proceso DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Eliminar registros existentes de la fecha
        DELETE FROM dbo.fact_ventas_diarias 
        WHERE fecha_proceso = @fecha_proceso;
        
        -- Insertar datos agregados
        INSERT INTO dbo.fact_ventas_diarias (
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
            @fecha_proceso
        FROM dbo.fact_ventas
        WHERE fecha_venta = @fecha_proceso
            AND esta_anulado = 0
        GROUP BY 
            tiempo_key,
            cliente_key,
            producto_key,
            vendedor_key;
        
        COMMIT TRANSACTION;
        PRINT 'Fact ventas diarias actualizada para: ' + CAST(@fecha_proceso AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO

-- ============================================================================
-- PROCEDIMIENTO: Obtener KPIs del Mes Actual
-- ============================================================================

IF OBJECT_ID('dbo.sp_obtener_kpis_mes_actual', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_obtener_kpis_mes_actual;
GO

CREATE PROCEDURE dbo.sp_obtener_kpis_mes_actual
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dt.anio,
        dt.mes,
        dt.mes_nombre,
        COUNT(DISTINCT fv.venta_id) AS total_ventas,
        COUNT(DISTINCT fv.cliente_key) AS clientes_activos,
        SUM(fv.venta_total_con_impuestos) AS venta_total,
        SUM(fv.costo_venta) AS costo_total,
        SUM(fv.margen_bruto) AS margen_bruto,
        CASE 
            WHEN SUM(fv.venta_total) > 0 
            THEN ROUND((SUM(fv.margen_bruto) / SUM(fv.venta_total)) * 100, 2)
            ELSE 0 
        END AS porcentaje_margen,
        ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio,
        SUM(CASE WHEN fv.es_venta_credito = 1 THEN fv.venta_total_con_impuestos ELSE 0 END) AS ventas_credito,
        SUM(CASE WHEN fv.es_venta_credito = 0 THEN fv.venta_total_con_impuestos ELSE 0 END) AS ventas_contado,
        SUM(fv.saldo) AS saldo_pendiente
    FROM dbo.fact_ventas fv
    INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
    WHERE dt.anio = YEAR(GETDATE())
        AND dt.mes = MONTH(GETDATE())
        AND fv.esta_anulado = 0
    GROUP BY dt.anio, dt.mes, dt.mes_nombre;
END
GO

-- ============================================================================
-- PROCEDIMIENTO: Obtener Top Clientes
-- ============================================================================

IF OBJECT_ID('dbo.sp_obtener_top_clientes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_obtener_top_clientes;
GO

CREATE PROCEDURE dbo.sp_obtener_top_clientes
    @anio INT = NULL,
    @top_n INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @anio IS NULL
        SET @anio = YEAR(GETDATE());
    
    SELECT TOP (@top_n)
        dc.cliente_id,
        dc.nombre AS cliente,
        dc.departamento,
        dc.municipio,
        COUNT(DISTINCT fv.venta_id) AS numero_compras,
        SUM(fv.cantidad) AS cantidad_total,
        SUM(fv.venta_total_con_impuestos) AS venta_total,
        ROUND(AVG(fv.venta_total_con_impuestos), 2) AS ticket_promedio,
        SUM(fv.margen_bruto) AS margen_bruto_generado
    FROM dbo.fact_ventas fv
    INNER JOIN dbo.dim_cliente dc ON fv.cliente_key = dc.cliente_key
    INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
    WHERE dt.anio = @anio
        AND fv.esta_anulado = 0
        AND dc.cliente_id > 0
    GROUP BY 
        dc.cliente_id,
        dc.nombre,
        dc.departamento,
        dc.municipio
    ORDER BY venta_total DESC;
END
GO

-- ============================================================================
-- PROCEDIMIENTO: Obtener Top Productos
-- ============================================================================

IF OBJECT_ID('dbo.sp_obtener_top_productos', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_obtener_top_productos;
GO

CREATE PROCEDURE dbo.sp_obtener_top_productos
    @anio INT = NULL,
    @top_n INT = 20,
    @orden_por VARCHAR(20) = 'cantidad' -- 'cantidad', 'venta', 'margen'
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @anio IS NULL
        SET @anio = YEAR(GETDATE());
    
    ;WITH ProductosRanked AS (
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
        FROM dbo.fact_ventas fv
        INNER JOIN dbo.dim_producto dp ON fv.producto_key = dp.producto_key
        INNER JOIN dbo.dim_tiempo dt ON fv.tiempo_key = dt.tiempo_key
        WHERE dt.anio = @anio
            AND fv.esta_anulado = 0
            AND dp.producto_id > 0
        GROUP BY 
            dp.producto_id,
            dp.nombre,
            dp.categoria_nombre,
            dp.tipo_producto_nombre
    )
    SELECT TOP (@top_n) *
    FROM ProductosRanked
    ORDER BY 
        CASE 
            WHEN @orden_por = 'cantidad' THEN cantidad_vendida
            WHEN @orden_por = 'venta' THEN venta_total
            WHEN @orden_por = 'margen' THEN margen_bruto
            ELSE cantidad_vendida
        END DESC;
END
GO

-- ============================================================================
-- PROCEDIMIENTO: Obtener Cartera Vencida
-- ============================================================================

IF OBJECT_ID('dbo.sp_obtener_cartera_vencida', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_obtener_cartera_vencida;
GO

CREATE PROCEDURE dbo.sp_obtener_cartera_vencida
    @dias_vencimiento INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dc.cliente_id,
        dc.nombre AS cliente,
        dc.departamento,
        dc.telefono_1,
        COUNT(DISTINCT fv.venta_id) AS ventas_pendientes,
        SUM(fv.saldo) AS saldo_total,
        MIN(fv.fecha_venta) AS fecha_venta_mas_antigua,
        DATEDIFF(DAY, MIN(fv.fecha_venta), GETDATE()) AS dias_vencido,
        CASE 
            WHEN DATEDIFF(DAY, MIN(fv.fecha_venta), GETDATE()) <= 30 THEN '0-30 días'
            WHEN DATEDIFF(DAY, MIN(fv.fecha_venta), GETDATE()) <= 60 THEN '31-60 días'
            WHEN DATEDIFF(DAY, MIN(fv.fecha_venta), GETDATE()) <= 90 THEN '61-90 días'
            WHEN DATEDIFF(DAY, MIN(fv.fecha_venta), GETDATE()) <= 120 THEN '91-120 días'
            ELSE 'Más de 120 días'
        END AS rango_antiguedad
    FROM dbo.fact_ventas fv
    INNER JOIN dbo.dim_cliente dc ON fv.cliente_key = dc.cliente_key
    WHERE fv.es_venta_credito = 1
        AND fv.esta_liquidado = 0
        AND fv.esta_anulado = 0
        AND fv.saldo > 0
        AND DATEDIFF(DAY, fv.fecha_venta, GETDATE()) >= @dias_vencimiento
    GROUP BY 
        dc.cliente_id,
        dc.nombre,
        dc.departamento,
        dc.telefono_1
    ORDER BY saldo_total DESC;
END
GO

PRINT 'Stored Procedures creados exitosamente';
GO

-- ============================================================================
-- EJEMPLOS DE USO
-- ============================================================================

-- Poblar dimensión tiempo (2020-2030)
-- EXEC dbo.sp_poblar_dim_tiempo '2020-01-01', '2030-12-31';

-- Actualizar ventas diarias
-- EXEC dbo.sp_actualizar_fact_ventas_diarias '2025-11-11';

-- Obtener KPIs del mes actual
-- EXEC dbo.sp_obtener_kpis_mes_actual;

-- Obtener top 10 clientes del año
-- EXEC dbo.sp_obtener_top_clientes @anio = 2025, @top_n = 10;

-- Obtener top 20 productos por cantidad
-- EXEC dbo.sp_obtener_top_productos @anio = 2025, @top_n = 20, @orden_por = 'cantidad';

-- Obtener cartera vencida (más de 30 días)
-- EXEC dbo.sp_obtener_cartera_vencida @dias_vencimiento = 30;
