"""
ETL: Carga de Dimensión Tiempo
Ejecuta el stored procedure para poblar la dimensión de tiempo con fechas
"""
import sys
from pathlib import Path

# Agregar el directorio raíz al path
sys.path.append(str(Path(__file__).parent.parent.parent))

from etl.utils.database import get_target_connection
from etl.utils.logger import get_logger, log_etl_start, log_etl_end, log_step, log_error, log_success
from datetime import datetime


def load_dim_tiempo(start_year: int = None, end_year: int = None) -> bool:
    """
    Cargar dimensión de tiempo ejecutando stored procedure
    
    Args:
        start_year: Año inicial (por defecto 2020)
        end_year: Año final (por defecto 2030)
    
    Returns:
        True si es exitoso, False en caso contrario
    """
    log = get_logger("dim_tiempo")
    log_etl_start("Carga de Dimensión Tiempo")
    
    # Valores por defecto
    if start_year is None:
        start_year = 2020
    if end_year is None:
        end_year = 2030
    
    try:
        log_step("Conectando a SQL Server (DW)")
        
        with get_target_connection() as target_db:
            # Verificar conexión
            if not target_db.test_connection():
                log_error("No se pudo conectar a SQL Server")
                return False
            
            log_success("Conexión exitosa a SQL Server")
            
            # Ejecutar stored procedure
            log_step(f"Ejecutando sp_poblar_dim_tiempo ({start_year} - {end_year})")
            
            conn = target_db.get_connection()
            cursor = conn.cursor()
            
            # Primero crear la tabla si no existe (verificar)
            cursor.execute("SELECT OBJECT_ID('dbo.dim_tiempo', 'U')")
            if cursor.fetchone()[0] is None:
                log_error("La tabla dim_tiempo no existe. Ejecuta primero 01_crear_dimensiones.sql")
                return False
            
            # Ejecutar stored procedure con años
            cursor.execute(f"EXEC dbo.sp_poblar_dim_tiempo @anio_inicio = ?, @anio_fin = ?", (start_year, end_year))
            conn.commit()
            cursor.close()
            
            log_success("Stored procedure ejecutado exitosamente")
            
            # Verificar cantidad de registros cargados
            log_step("Verificando registros cargados")
            
            cursor = conn.cursor()
            cursor.execute("SELECT COUNT(*) FROM dbo.dim_tiempo WHERE tiempo_key > 0")
            count = cursor.fetchone()[0]
            cursor.close()
            
            log_success(f"Total de registros en dim_tiempo: {count:,}")
            
            log_etl_end("Carga de Dimensión Tiempo", success=True, records=count)
            return True
            
    except Exception as e:
        log_error("Error en la carga de dim_tiempo", e)
        log_etl_end("Carga de Dimensión Tiempo", success=False)
        return False


if __name__ == "__main__":
    # Ejecutar carga
    import argparse
    
    parser = argparse.ArgumentParser(description='Cargar dimensión de tiempo')
    parser.add_argument('--start-year', type=int, default=2020, help='Año inicial')
    parser.add_argument('--end-year', type=int, default=2030, help='Año final')
    
    args = parser.parse_args()
    
    success = load_dim_tiempo(args.start_year, args.end_year)
    sys.exit(0 if success else 1)
