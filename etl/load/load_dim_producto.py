"""
ETL: Carga de dim_producto con SCD Type 2
Maneja cambios históricos en los datos del producto
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


def load_dim_producto_full() -> bool:
    """
    Carga completa de dim_producto con SCD Type 2
    """
    log = get_logger("dim_producto")
    log_etl_start("Carga FULL de dim_producto")
    
    try:
        # PASO 1: Extraer datos de MariaDB
        log_step("Extrayendo datos de productos (MariaDB)")
        
        source_db = SourceDatabase()
        source_conn = source_db.get_connection()
        source_cursor = source_conn.cursor()
        
        query = """
            SELECT 
                p.id as producto_id,
                p.nombre,
                p.nombre_alternativo,
                p.codigo,
                cat.codigo as categoria_codigo,
                cat.nombre as categoria_nombre,
                tp.codigo as tipo_producto_codigo,
                tp.nombre as tipo_producto_nombre,
                um.nombre as unidad_medida_nombre,
                um.abreviatura as unidad_medida_abreviatura,
                p.producto_activo
            FROM productos p
            LEFT JOIN categorias cat ON p.categoria_id = cat.id
            LEFT JOIN tipo_productos tp ON p.tipo_producto_id = tp.id
            LEFT JOIN unidad_medidas um ON p.unidad_medida_id = um.id
            WHERE p.deleted_at IS NULL
            ORDER BY p.id
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
            UPDATE dbo.dim_producto 
            SET es_actual = 0, 
                fecha_fin = CAST(GETDATE() AS DATE)
            WHERE es_actual = 1
        """)
        target_conn.commit()
        
        log_step(f"Insertando {len(rows)} registros nuevos")
        
        insert_count = 0
        for row in rows:
            target_cursor.execute("""
                INSERT INTO dbo.dim_producto (
                    producto_id, nombre, nombre_alternativo, codigo,
                    categoria_codigo, categoria_nombre,
                    tipo_producto_codigo, tipo_producto_nombre,
                    unidad_medida_nombre, unidad_medida_abreviatura,
                    producto_activo, fecha_inicio, fecha_fin, version, es_actual
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CAST(GETDATE() AS DATE), NULL, 1, 1)
            """, (
                row['producto_id'],
                clean_string(row['nombre']),
                clean_string(row.get('nombre_alternativo')),
                clean_string(row.get('codigo')),
                clean_string(row.get('categoria_codigo')),
                clean_string(row.get('categoria_nombre')),
                clean_string(row.get('tipo_producto_codigo')),
                clean_string(row.get('tipo_producto_nombre')),
                clean_string(row.get('unidad_medida_nombre')),
                clean_string(row.get('unidad_medida_abreviatura')),
                row.get('producto_activo', 1),
            ))
            insert_count += 1
        
        target_conn.commit()
        target_cursor.close()
        target_conn.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga FULL de dim_producto", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_producto", e)
        log_etl_end("Carga FULL de dim_producto", success=False)
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Carga de dim_producto con SCD Type 2')
    parser.add_argument('--mode', choices=['full', 'incremental'], default='full',
                        help='Modo de carga: full o incremental')
    
    args = parser.parse_args()
    
    if args.mode == 'full':
        success = load_dim_producto_full()
    else:
        print("Modo incremental no implementado aún")
        success = False
    
    sys.exit(0 if success else 1)
