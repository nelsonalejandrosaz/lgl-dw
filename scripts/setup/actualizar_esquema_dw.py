"""
Script para actualizar el esquema del DW existente:
1. Agregar campo antiguedad_cliente a dim_cliente
2. Agregar campo ubicacion_key a fact_ventas con FK a dim_ubicacion

NOTA: Ejecutar con Windows Authentication (no con etl_dw_user)
"""
import sys
from pathlib import Path
import pyodbc
import argparse

sys.path.append(str(Path(__file__).parent.parent.parent))

from etl.utils.logger import get_logger, log_step, log_success, log_error


def get_connection(use_windows_auth: bool = True):
    """Obtener conexión a SQL Server"""
    if use_windows_auth:
        conn_str = (
            "DRIVER={ODBC Driver 17 for SQL Server};"
            "SERVER=localhost;"
            "DATABASE=LGL_DW;"
            "Trusted_Connection=yes;"
        )
        return pyodbc.connect(conn_str)
    else:
        # Importar aquí para evitar error si no se usa
        from etl.utils.database import TargetDatabase
        target_db = TargetDatabase()
        return target_db.get_connection()


def main(use_windows_auth: bool = True):
    log = get_logger("actualizar_esquema")
    
    try:
        log_step("Conectando a SQL Server...")
        conn = get_connection(use_windows_auth)
        cursor = conn.cursor()
        
        # PASO 1: Agregar campo antiguedad_cliente a dim_cliente
        log_step("Agregando campo antiguedad_cliente a dim_cliente...")
        try:
            cursor.execute("""
                ALTER TABLE dbo.dim_cliente 
                ADD antiguedad_cliente INT NULL
            """)
            conn.commit()
            log_success("Campo antiguedad_cliente agregado exitosamente")
        except pyodbc.ProgrammingError as e:
            if "already exists" in str(e) or "Column names in each table must be unique" in str(e):
                log_success("Campo antiguedad_cliente ya existe, omitiendo...")
            else:
                raise
        
        # PASO 2: Calcular antigüedad para clientes existentes
        log_step("Calculando antigüedad de clientes existentes...")
        cursor.execute("""
            UPDATE dc
            SET dc.antiguedad_cliente = YEAR(GETDATE()) - YEAR(min_fecha)
            FROM dbo.dim_cliente dc
            INNER JOIN (
                SELECT 
                    cliente_key,
                    MIN(fecha_venta) as min_fecha
                FROM dbo.fact_ventas
                GROUP BY cliente_key
            ) fv ON dc.cliente_key = fv.cliente_key
            WHERE dc.es_actual = 1
        """)
        rows_updated = cursor.rowcount
        conn.commit()
        log_success(f"Antigüedad calculada para {rows_updated} clientes")
        
        # PASO 3: Agregar campo ubicacion_key a fact_ventas
        log_step("Agregando campo ubicacion_key a fact_ventas...")
        try:
            cursor.execute("""
                ALTER TABLE dbo.fact_ventas 
                ADD ubicacion_key INT NULL
            """)
            conn.commit()
            log_success("Campo ubicacion_key agregado exitosamente")
        except pyodbc.ProgrammingError as e:
            if "already exists" in str(e) or "Column names in each table must be unique" in str(e):
                log_success("Campo ubicacion_key ya existe, omitiendo...")
            else:
                raise
        
        # PASO 4: Poblar ubicacion_key desde dim_cliente
        log_step("Poblando ubicacion_key en fact_ventas desde dim_cliente...")
        cursor.execute("""
            UPDATE fv
            SET fv.ubicacion_key = du.ubicacion_key
            FROM dbo.fact_ventas fv
            INNER JOIN dbo.dim_cliente dc ON fv.cliente_key = dc.cliente_key
            INNER JOIN dbo.dim_ubicacion du ON dc.municipio = du.municipio_nombre
            WHERE fv.ubicacion_key IS NULL
        """)
        rows_updated = cursor.rowcount
        conn.commit()
        log_success(f"ubicacion_key poblado para {rows_updated} registros")
        
        # PASO 5: Crear FK constraint
        log_step("Creando FK constraint para ubicacion_key...")
        try:
            cursor.execute("""
                ALTER TABLE dbo.fact_ventas
                ADD CONSTRAINT fk_fact_ventas_ubicacion 
                    FOREIGN KEY (ubicacion_key) 
                    REFERENCES dbo.dim_ubicacion(ubicacion_key)
            """)
            conn.commit()
            log_success("FK constraint creado exitosamente")
        except pyodbc.ProgrammingError as e:
            if "already exists" in str(e) or "There is already an object" in str(e):
                log_success("FK constraint ya existe, omitiendo...")
            else:
                raise
        
        # PASO 6: Crear índice
        log_step("Creando índice para ubicacion_key...")
        try:
            cursor.execute("""
                CREATE NONCLUSTERED INDEX idx_fact_ventas_ubicacion 
                    ON dbo.fact_ventas(ubicacion_key)
            """)
            conn.commit()
            log_success("Índice creado exitosamente")
        except pyodbc.ProgrammingError as e:
            if "already exists" in str(e) or "There is already an object" in str(e):
                log_success("Índice ya existe, omitiendo...")
            else:
                raise
        
        cursor.close()
        conn.close()
        
        print("\n" + "="*70)
        print("✅ ACTUALIZACIÓN DEL ESQUEMA COMPLETADA")
        print("="*70)
        print("\nCambios aplicados:")
        print("  ✓ Campo antiguedad_cliente agregado a dim_cliente")
        print("  ✓ Antigüedad calculada para clientes existentes")
        print("  ✓ Campo ubicacion_key agregado a fact_ventas")
        print("  ✓ ubicacion_key poblado desde dim_cliente")
        print("  ✓ FK constraint creado")
        print("  ✓ Índice creado")
        print("\nAhora puedes:")
        print("  1. Verificar las relaciones en Power BI")
        print("  2. Usar dim_ubicacion en tus reportes")
        print("  3. Analizar antigüedad de clientes")
        print("="*70)
        
        return True
        
    except Exception as e:
        log_error("Error al actualizar el esquema", e)
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Actualizar esquema del DW')
    parser.add_argument('--etl-user', action='store_true', 
                        help='Usar credenciales ETL (sin Windows Auth)')
    
    args = parser.parse_args()
    
    success = main(use_windows_auth=not args.etl_user)
    sys.exit(0 if success else 1)
