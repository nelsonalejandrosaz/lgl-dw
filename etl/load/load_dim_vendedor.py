"""
ETL: Carga de dim_vendedor con SCD Type 2
Maneja cambios históricos en los datos del vendedor
"""
import sys
from pathlib import Path
from datetime import datetime
import argparse

# Agregar el directorio raíz al path
sys.path.append(str(Path(__file__).parent.parent.parent))

from etl.utils.database import SourceDatabase, TargetDatabase
from etl.utils.logger import get_logger, log_etl_start, log_etl_end, log_step, log_error, log_success
from etl.utils.helpers import clean_string


def load_dim_vendedor_full() -> bool:
    """
    Carga completa de dim_vendedor con SCD Type 2
    """
    log = get_logger("dim_vendedor")
    log_etl_start("Carga FULL de dim_vendedor")
    
    try:
        # PASO 1: Extraer datos de MariaDB (vendedores de la tabla users)
        log_step("Extrayendo datos de vendedores (MariaDB)")
        
        source_db = SourceDatabase()
        source_conn = source_db.get_connection()
        source_cursor = source_conn.cursor()
        
        # En la tabla clientes hay un campo vendedor_id que referencia a users
        # Extraemos los vendedores únicos que tienen clientes asignados
        query = """
            SELECT DISTINCT
                u.id as vendedor_id,
                u.nombre,
                u.apellido,
                u.email,
                u.username
            FROM users u
            INNER JOIN clientes c ON c.vendedor_id = u.id
            ORDER BY u.id
        """
        
        source_cursor.execute(query)
        rows = source_cursor.fetchall()
        source_cursor.close()
        source_conn.close()
        
        log_success(f"Extraídos {len(rows)} registros de MariaDB")
        
        # PASO 2: Cargar a SQL Server
        log_step("Cerrando registros actuales en SQL Server")
        
        target_db = TargetDatabase()
        target_conn = target_db.get_connection()
        target_cursor = target_conn.cursor()
        
        # Cerrar todos los registros actuales
        target_cursor.execute("""
            UPDATE dbo.dim_vendedor 
            SET es_actual = 0, 
                fecha_fin = CAST(GETDATE() AS DATE)
            WHERE es_actual = 1
        """)
        target_conn.commit()
        
        log_step(f"Insertando {len(rows)} registros nuevos")
        
        insert_count = 0
        for row in rows:
            target_cursor.execute("""
                INSERT INTO dbo.dim_vendedor (
                    vendedor_id, nombre, apellido, email, username,
                    fecha_inicio, fecha_fin, version, es_actual
                ) VALUES (?, ?, ?, ?, ?, CAST(GETDATE() AS DATE), NULL, 1, 1)
            """, (
                row['vendedor_id'],
                clean_string(row['nombre']),
                clean_string(row.get('apellido')),
                clean_string(row.get('email')),
                clean_string(row.get('username'))
            ))
            insert_count += 1
        
        target_conn.commit()
        target_cursor.close()
        target_conn.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga FULL de dim_vendedor", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_vendedor", e)
        log_etl_end("Carga FULL de dim_vendedor", success=False)
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Carga de dim_vendedor con SCD Type 2')
    parser.add_argument('--mode', choices=['full', 'incremental'], default='full',
                        help='Modo de carga: full o incremental')
    
    args = parser.parse_args()
    
    if args.mode == 'full':
        success = load_dim_vendedor_full()
    else:
        print("Modo incremental no implementado aún")
        success = False
    
    sys.exit(0 if success else 1)
