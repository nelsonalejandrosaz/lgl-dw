"""
ETL: Carga de dim_cliente con SCD Type 2
Maneja cambios históricos en los datos del cliente
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


def load_dim_cliente_full() -> bool:
    """
    Carga completa de dim_cliente con SCD Type 2
    Cierra todos los registros actuales e inserta versiones nuevas
    """
    log = get_logger("dim_cliente")
    log_etl_start("Carga FULL de dim_cliente")
    
    try:
        # PASO 1: Extraer datos de MariaDB
        log_step("Extrayendo datos de clientes (MariaDB)")
        
        source_db = SourceDatabase()
        source_conn = source_db.get_connection()
        source_cursor = source_conn.cursor()
        
        query = """
            SELECT 
                c.id as cliente_id,
                c.nombre,
                c.nombre_alternativo,
                c.nit,
                c.nrc,
                c.retencion,
                m.nombre as municipio,
                d.nombre as departamento,
                MIN(v.fecha) as fecha_primera_compra
            FROM clientes c
            LEFT JOIN municipios m ON c.municipio_id = m.id
            LEFT JOIN departamentos d ON m.departamento_id = d.id
            LEFT JOIN ventas v ON c.id = v.cliente_id
            GROUP BY c.id, c.nombre, c.nombre_alternativo, c.nit, c.nrc, 
                     c.retencion, m.nombre, d.nombre
            ORDER BY c.id
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
            UPDATE dbo.dim_cliente 
            SET es_actual = 0, 
                fecha_fin = CAST(GETDATE() AS DATE)
            WHERE es_actual = 1
        """)
        target_conn.commit()
        
        log_step(f"Insertando {len(rows)} registros nuevos")
        
        insert_count = 0
        for row in rows:
            target_cursor.execute("""
                INSERT INTO dbo.dim_cliente (
                    cliente_id, nombre, nombre_alternativo, nit, nrc, retencion,
                    municipio, departamento, fecha_primera_compra,
                    fecha_inicio, fecha_fin, version, es_actual
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CAST(GETDATE() AS DATE), NULL, 1, 1)
            """, (
                row['cliente_id'],
                clean_string(row['nombre']),
                clean_string(row.get('nombre_alternativo')),
                clean_string(row.get('nit')),
                clean_string(row.get('nrc')),
                row.get('retencion', 0),
                clean_string(row.get('municipio')),
                clean_string(row.get('departamento')),
                row.get('fecha_primera_compra')
            ))
            insert_count += 1
        
        target_conn.commit()
        target_cursor.close()
        target_conn.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga FULL de dim_cliente", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_cliente", e)
        log_etl_end("Carga FULL de dim_cliente", success=False)
        return False


def load_dim_cliente_incremental() -> bool:
    """
    Carga incremental de dim_cliente con SCD Type 2
    Detecta cambios y crea nuevas versiones solo para registros modificados
    """
    log = get_logger("dim_cliente")
    log_etl_start("Carga INCREMENTAL de dim_cliente")
    
    try:
        # PASO 1: Extraer datos actuales de MariaDB
        log_step("Extrayendo datos actuales de clientes (MariaDB)")
        
        source_db = SourceDatabase()
        source_conn = source_db.get_connection()
        source_cursor = source_conn.cursor()
        
        query = """
            SELECT 
                c.id as cliente_id,
                c.nombre,
                c.nombre_alternativo,
                c.nit,
                c.nrc,
                c.retencion,
                m.nombre as municipio,
                d.nombre as departamento,
                MIN(v.fecha) as fecha_primera_compra
            FROM clientes c
            LEFT JOIN municipios m ON c.municipio_id = m.id
            LEFT JOIN departamentos d ON m.departamento_id = d.id
            LEFT JOIN ventas v ON c.id = v.cliente_id
            GROUP BY c.id, c.nombre, c.nombre_alternativo, c.nit, c.nrc, 
                     c.retencion, m.nombre, d.nombre
            ORDER BY c.id
        """
        
        source_cursor.execute(query)
        source_data = {row['cliente_id']: row for row in source_cursor.fetchall()}
        source_cursor.close()
        source_conn.close()
        
        log_success(f"Extraídos {len(source_data)} registros de MariaDB")
        
        # PASO 2: Extraer registros actuales de SQL Server
        log_step("Extrayendo registros actuales de SQL Server")
        
        target_db = TargetDatabase()
        target_conn = target_db.get_connection()
        target_cursor = target_conn.cursor()
        
        target_cursor.execute("""
            SELECT 
                cliente_id, nombre, nombre_alternativo, nit, nrc, retencion,
                municipio, departamento, fecha_primera_compra, version
            FROM dbo.dim_cliente
            WHERE es_actual = 1
        """)
        
        target_data = {}
        for row in target_cursor.fetchall():
            target_data[row[0]] = {
                'nombre': row[1],
                'nombre_alternativo': row[2],
                'nit': row[3],
                'nrc': row[4],
                'retencion': row[5],
                'municipio': row[6],
                'departamento': row[7],
                'fecha_primera_compra': row[8],
                'version': row[9]
            }
        
        log_success(f"Encontrados {len(target_data)} registros actuales en DW")
        
        # PASO 3: Detectar cambios
        log_step("Detectando cambios")
        
        nuevos = []
        modificados = []
        
        for cliente_id, source_row in source_data.items():
            if cliente_id not in target_data:
                # Cliente nuevo
                nuevos.append(source_row)
            else:
                # Verificar si cambió algún atributo
                target_row = target_data[cliente_id]
                source_vals = (
                    clean_string(source_row.get('nombre')),
                    clean_string(source_row.get('nombre_alternativo')),
                    clean_string(source_row.get('nit')),
                    clean_string(source_row.get('nrc')),
                    source_row.get('retencion', 0),
                    clean_string(source_row.get('municipio')),
                    clean_string(source_row.get('departamento')),
                    source_row.get('fecha_primera_compra')
                )
                target_vals = (
                    target_row['nombre'],
                    target_row['nombre_alternativo'],
                    target_row['nit'],
                    target_row['nrc'],
                    target_row['retencion'],
                    target_row['municipio'],
                    target_row['departamento'],
                    target_row['fecha_primera_compra']
                )
                
                if source_vals != target_vals:
                    modificados.append((source_row, target_row['version']))
        
        log_success(f"Nuevos: {len(nuevos)}, Modificados: {len(modificados)}")
        
        # PASO 4: Aplicar cambios
        if len(nuevos) > 0:
            log_step(f"Insertando {len(nuevos)} clientes nuevos")
            for row in nuevos:
                target_cursor.execute("""
                    INSERT INTO dbo.dim_cliente (
                        cliente_id, nombre, nombre_alternativo, nit, nrc, retencion,
                        municipio, departamento, fecha_primera_compra,
                        fecha_inicio, fecha_fin, version, es_actual
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CAST(GETDATE() AS DATE), NULL, 1, 1)
                """, (
                    row['cliente_id'],
                    clean_string(row['nombre']),
                    clean_string(row.get('nombre_alternativo')),
                    clean_string(row.get('nit')),
                    clean_string(row.get('nrc')),
                    row.get('retencion', 0),
                    clean_string(row.get('municipio')),
                    clean_string(row.get('departamento')),
                    row.get('fecha_primera_compra')
                ))
            target_conn.commit()
        
        if len(modificados) > 0:
            log_step(f"Actualizando {len(modificados)} clientes modificados (SCD Type 2)")
            for source_row, current_version in modificados:
                # Cerrar versión actual
                target_cursor.execute("""
                    UPDATE dbo.dim_cliente 
                    SET es_actual = 0, 
                        fecha_fin = CAST(GETDATE() AS DATE)
                    WHERE cliente_id = ? AND es_actual = 1
                """, (source_row['cliente_id'],))
                
                # Insertar nueva versión
                target_cursor.execute("""
                    INSERT INTO dbo.dim_cliente (
                        cliente_id, nombre, nombre_alternativo, nit, nrc, retencion,
                        municipio, departamento, fecha_primera_compra,
                        fecha_inicio, fecha_fin, version, es_actual
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CAST(GETDATE() AS DATE), NULL, ?, 1)
                """, (
                    source_row['cliente_id'],
                    clean_string(source_row['nombre']),
                    clean_string(source_row.get('nombre_alternativo')),
                    clean_string(source_row.get('nit')),
                    clean_string(source_row.get('nrc')),
                    source_row.get('retencion', 0),
                    clean_string(source_row.get('municipio')),
                    clean_string(source_row.get('departamento')),
                    source_row.get('fecha_primera_compra'),
                    current_version + 1
                ))
            target_conn.commit()
        
        target_cursor.close()
        target_conn.close()
        
        total_procesados = len(nuevos) + len(modificados)
        log_success(f"Procesados {total_procesados} cambios")
        log_etl_end("Carga INCREMENTAL de dim_cliente", success=True, records=total_procesados)
        return True
        
    except Exception as e:
        log_error("Error en la carga incremental de dim_cliente", e)
        log_etl_end("Carga INCREMENTAL de dim_cliente", success=False)
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Carga de dim_cliente con SCD Type 2')
    parser.add_argument('--mode', choices=['full', 'incremental'], default='full',
                        help='Modo de carga: full o incremental')
    
    args = parser.parse_args()
    
    if args.mode == 'full':
        success = load_dim_cliente_full()
    else:
        success = load_dim_cliente_incremental()
    
    sys.exit(0 if success else 1)
