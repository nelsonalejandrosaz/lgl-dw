"""
ETL: Carga de Dimensiones Estáticas
Carga dimensiones que no requieren SCD Type 2:
- dim_tipo_documento
- dim_condicion_pago
- dim_estado_venta
- dim_ubicacion
"""
import sys
from pathlib import Path

# Agregar el directorio raíz al path
sys.path.append(str(Path(__file__).parent.parent.parent))

from etl.utils.database import get_source_connection, get_target_connection
from etl.utils.logger import get_logger, log_etl_start, log_etl_end, log_step, log_error, log_success
from etl.utils.helpers import clean_string, safe_bool, get_timestamp


def load_dim_tipo_documento() -> bool:
    """Cargar dimensión tipo_documento"""
    log = get_logger("dim_tipo_documento")
    log_etl_start("Carga de dim_tipo_documento")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de tipo_documento (MariaDB)")
        
        with get_source_connection() as source_db:
            conn = source_db.get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT 
                    id,
                    codigo,
                    nombre
                FROM tipo_documentos
                ORDER BY id
            """)
            rows = cursor.fetchall()
            cursor.close()
        
        log_success(f"Extraídos {len(rows)} registros de MariaDB")
        
        # Transformar y cargar a SQL Server
        log_step("Cargando a dim_tipo_documento (SQL Server)")
        
        with get_target_connection() as target_db:
            conn = target_db.get_connection()
            cursor = conn.cursor()
            
            # Limpiar tabla
            cursor.execute("DELETE FROM dbo.dim_tipo_documento")
            conn.commit()
            
            # Insertar datos
            insert_count = 0
            for row in rows:
                cursor.execute("""
                    INSERT INTO dbo.dim_tipo_documento 
                    (tipo_documento_id, codigo, nombre)
                    VALUES (?, ?, ?)
                """, (
                    row['id'],
                    row.get('codigo', str(row['id']).zfill(2)),
                    clean_string(row['nombre'])
                ))
                insert_count += 1
            
            conn.commit()
            cursor.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga de dim_tipo_documento", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_tipo_documento", e)
        log_etl_end("Carga de dim_tipo_documento", success=False)
        return False


def load_dim_condicion_pago() -> bool:
    """Cargar dimensión condicion_pago"""
    log = get_logger("dim_condicion_pago")
    log_etl_start("Carga de dim_condicion_pago")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de condicion_pago (MariaDB)")
        
        with get_source_connection() as source_db:
            conn = source_db.get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT 
                    id,
                    codigo,
                    nombre
                FROM condiciones_pago
                ORDER BY id
            """)
            rows = cursor.fetchall()
            cursor.close()
        
        log_success(f"Extraídos {len(rows)} registros de MariaDB")
        
        # Transformar y cargar
        log_step("Cargando a dim_condicion_pago (SQL Server)")
        
        with get_target_connection() as target_db:
            conn = target_db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute("DELETE FROM dbo.dim_condicion_pago")
            conn.commit()
            
            insert_count = 0
            for row in rows:
                cursor.execute("""
                    INSERT INTO dbo.dim_condicion_pago 
                    (condicion_pago_id, codigo, nombre)
                    VALUES (?, ?, ?)
                """, (
                    row['id'],
                    row.get('codigo', str(row['id']).zfill(2)),
                    clean_string(row['nombre'])
                ))
                insert_count += 1
            
            conn.commit()
            cursor.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga de dim_condicion_pago", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_condicion_pago", e)
        log_etl_end("Carga de dim_condicion_pago", success=False)
        return False


def load_dim_estado_venta() -> bool:
    """Cargar dimensión estado_venta"""
    log = get_logger("dim_estado_venta")
    log_etl_start("Carga de dim_estado_venta")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de estado_venta (MariaDB)")
        
        with get_source_connection() as source_db:
            conn = source_db.get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT 
                    id,
                    codigo,
                    nombre
                FROM estados_ventas
                ORDER BY id
            """)
            rows = cursor.fetchall()
            cursor.close()
        
        log_success(f"Extraídos {len(rows)} registros de MariaDB")
        
        # Transformar y cargar
        log_step("Cargando a dim_estado_venta (SQL Server)")
        
        with get_target_connection() as target_db:
            conn = target_db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute("DELETE FROM dbo.dim_estado_venta")
            conn.commit()
            
            insert_count = 0
            for row in rows:
                cursor.execute("""
                    INSERT INTO dbo.dim_estado_venta 
                    (estado_venta_id, codigo, nombre)
                    VALUES (?, ?, ?)
                """, (
                    row['id'],
                    row.get('codigo', str(row['id']).zfill(2)),
                    clean_string(row['nombre'])
                ))
                insert_count += 1
            
            conn.commit()
            cursor.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga de dim_estado_venta", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_estado_venta", e)
        log_etl_end("Carga de dim_estado_venta", success=False)
        return False


def load_dim_ubicacion() -> bool:
    """Cargar dimensión ubicacion"""
    log = get_logger("dim_ubicacion")
    log_etl_start("Carga de dim_ubicacion")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de ubicacion (MariaDB)")
        
        with get_source_connection() as source_db:
            conn = source_db.get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT 
                    m.id as municipio_id,
                    m.nombre as municipio_nombre,
                    d.id as departamento_id,
                    d.nombre as departamento_nombre,
                    d.isocode as departamento_isocode,
                    d.zonesv_id
                FROM municipios m
                INNER JOIN departamentos d ON m.departamento_id = d.id
                ORDER BY m.id
            """)
            rows = cursor.fetchall()
            cursor.close()
        
        log_success(f"Extraídos {len(rows)} registros de MariaDB")
        
        # Transformar y cargar
        log_step("Cargando a dim_ubicacion (SQL Server)")
        
        with get_target_connection() as target_db:
            conn = target_db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute("DELETE FROM dbo.dim_ubicacion")
            conn.commit()
            
            insert_count = 0
            for row in rows:
                cursor.execute("""
                    INSERT INTO dbo.dim_ubicacion 
                    (municipio_id, municipio_nombre, departamento_id, departamento_nombre, departamento_isocode, zonesv_id)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    row['municipio_id'],
                    clean_string(row['municipio_nombre']),
                    row['departamento_id'],
                    clean_string(row['departamento_nombre']),
                    row.get('departamento_isocode'),
                    row.get('zonesv_id')
                ))
                insert_count += 1
            
            conn.commit()
            cursor.close()
        
        log_success(f"Cargados {insert_count} registros a SQL Server")
        log_etl_end("Carga de dim_ubicacion", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_ubicacion", e)
        log_etl_end("Carga de dim_ubicacion", success=False)
        return False


def load_all_static_dimensions() -> bool:
    """Cargar todas las dimensiones estáticas"""
    log = get_logger("dimensiones_estaticas")
    log_etl_start("Carga de Dimensiones Estáticas")
    
    results = {
        'dim_tipo_documento': load_dim_tipo_documento(),
        'dim_condicion_pago': load_dim_condicion_pago(),
        'dim_estado_venta': load_dim_estado_venta(),
        'dim_ubicacion': load_dim_ubicacion()
    }
    
    success_count = sum(results.values())
    total_count = len(results)
    
    log_step(f"Resultados: {success_count}/{total_count} dimensiones cargadas exitosamente")
    
    for dim_name, success in results.items():
        status = "✓" if success else "✗"
        log_step(f"{status} {dim_name}")
    
    all_success = all(results.values())
    log_etl_end("Carga de Dimensiones Estáticas", success=all_success)
    
    return all_success


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Cargar dimensiones estáticas')
    parser.add_argument('--dimension', type=str, choices=['tipo_documento', 'condicion_pago', 'estado_venta', 'ubicacion', 'all'],
                        default='all', help='Dimensión a cargar')
    
    args = parser.parse_args()
    
    if args.dimension == 'all':
        success = load_all_static_dimensions()
    elif args.dimension == 'tipo_documento':
        success = load_dim_tipo_documento()
    elif args.dimension == 'condicion_pago':
        success = load_dim_condicion_pago()
    elif args.dimension == 'estado_venta':
        success = load_dim_estado_venta()
    elif args.dimension == 'ubicacion':
        success = load_dim_ubicacion()
    
    sys.exit(0 if success else 1)


def load_dim_tipo_documento() -> bool:
    """Cargar dimensión tipo_documento"""
    log = get_logger("dim_tipo_documento")
    log_etl_start("Carga de dim_tipo_documento")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de tipo_documento (MariaDB)")
        
        with get_source_connection() as source_db:
            query = """
                SELECT 
                    tipo_documento_id,
                    tipo_documento,
                    activo
                FROM tipo_documento
                WHERE activo = 1
                ORDER BY tipo_documento_id
            """
            df_source = pd.read_sql(query, source_db.get_engine())
        
        log_success(f"Extraídos {len(df_source)} registros de MariaDB")
        
        # Transformar
        log_step("Transformando datos")
        
        df_source['tipo_documento'] = df_source['tipo_documento'].apply(clean_string)
        df_source['es_activo'] = df_source['activo'].apply(safe_bool)
        df_source['fecha_carga'] = get_timestamp()
        
        df_transformed = df_source[[
            'tipo_documento_id',
            'tipo_documento',
            'es_activo',
            'fecha_carga'
        ]]
        
        # Cargar a SQL Server
        log_step("Cargando a dim_tipo_documento (SQL Server)")
        
        with get_target_connection() as target_db:
            engine = target_db.get_engine()
            
            # Truncar tabla (para recarga completa)
            with engine.connect() as conn:
                conn.execute("TRUNCATE TABLE dbo.dim_tipo_documento")
                conn.commit()
            
            # Insertar datos
            df_transformed.to_sql(
                'dim_tipo_documento',
                engine,
                schema='dbo',
                if_exists='append',
                index=False,
                method='multi',
                chunksize=1000
            )
        
        log_success(f"Cargados {len(df_transformed)} registros a SQL Server")
        log_etl_end("Carga de dim_tipo_documento", success=True, records=len(df_transformed))
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_tipo_documento", e)
        log_etl_end("Carga de dim_tipo_documento", success=False)
        return False


def load_dim_condicion_pago() -> bool:
    """Cargar dimensión condicion_pago"""
    log = get_logger("dim_condicion_pago")
    log_etl_start("Carga de dim_condicion_pago")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de condicion_pago (MariaDB)")
        
        with get_source_connection() as source_db:
            query = """
                SELECT 
                    condicion_pago_id,
                    condicion_pago,
                    dias_credito,
                    activo
                FROM condicion_pago
                WHERE activo = 1
                ORDER BY condicion_pago_id
            """
            df_source = pd.read_sql(query, source_db.get_engine())
        
        log_success(f"Extraídos {len(df_source)} registros de MariaDB")
        
        # Transformar
        log_step("Transformando datos")
        
        df_source['condicion_pago'] = df_source['condicion_pago'].apply(clean_string)
        df_source['es_activo'] = df_source['activo'].apply(safe_bool)
        df_source['fecha_carga'] = get_timestamp()
        
        df_transformed = df_source[[
            'condicion_pago_id',
            'condicion_pago',
            'dias_credito',
            'es_activo',
            'fecha_carga'
        ]]
        
        # Cargar a SQL Server
        log_step("Cargando a dim_condicion_pago (SQL Server)")
        
        with get_target_connection() as target_db:
            engine = target_db.get_engine()
            
            # Truncar tabla
            with engine.connect() as conn:
                conn.execute("TRUNCATE TABLE dbo.dim_condicion_pago")
                conn.commit()
            
            # Insertar datos
            df_transformed.to_sql(
                'dim_condicion_pago',
                engine,
                schema='dbo',
                if_exists='append',
                index=False,
                method='multi',
                chunksize=1000
            )
        
        log_success(f"Cargados {len(df_transformed)} registros a SQL Server")
        log_etl_end("Carga de dim_condicion_pago", success=True, records=len(df_transformed))
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_condicion_pago", e)
        log_etl_end("Carga de dim_condicion_pago", success=False)
        return False


def load_dim_estado_venta() -> bool:
    """Cargar dimensión estado_venta"""
    log = get_logger("dim_estado_venta")
    log_etl_start("Carga de dim_estado_venta")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de estado_venta (MariaDB)")
        
        with get_source_connection() as source_db:
            query = """
                SELECT 
                    estado_venta_id,
                    estado_venta,
                    activo
                FROM estado_venta
                WHERE activo = 1
                ORDER BY estado_venta_id
            """
            df_source = pd.read_sql(query, source_db.get_engine())
        
        log_success(f"Extraídos {len(df_source)} registros de MariaDB")
        
        # Transformar
        log_step("Transformando datos")
        
        df_source['estado_venta'] = df_source['estado_venta'].apply(clean_string)
        df_source['es_activo'] = df_source['activo'].apply(safe_bool)
        df_source['fecha_carga'] = get_timestamp()
        
        df_transformed = df_source[[
            'estado_venta_id',
            'estado_venta',
            'es_activo',
            'fecha_carga'
        ]]
        
        # Cargar a SQL Server
        log_step("Cargando a dim_estado_venta (SQL Server)")
        
        with get_target_connection() as target_db:
            engine = target_db.get_engine()
            
            # Truncar tabla
            with engine.connect() as conn:
                conn.execute("TRUNCATE TABLE dbo.dim_estado_venta")
                conn.commit()
            
            # Insertar datos
            df_transformed.to_sql(
                'dim_estado_venta',
                engine,
                schema='dbo',
                if_exists='append',
                index=False,
                method='multi',
                chunksize=1000
            )
        
        log_success(f"Cargados {len(df_transformed)} registros a SQL Server")
        log_etl_end("Carga de dim_estado_venta", success=True, records=len(df_transformed))
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_estado_venta", e)
        log_etl_end("Carga de dim_estado_venta", success=False)
        return False


def load_dim_ubicacion() -> bool:
    """Cargar dimensión ubicacion"""
    log = get_logger("dim_ubicacion")
    log_etl_start("Carga de dim_ubicacion")
    
    try:
        # Extraer de MariaDB
        log_step("Extrayendo datos de ubicacion (MariaDB)")
        
        with get_source_connection() as source_db:
            query = """
                SELECT 
                    ubicacion_id,
                    pais,
                    departamento,
                    municipio,
                    activo
                FROM ubicacion
                WHERE activo = 1
                ORDER BY ubicacion_id
            """
            df_source = pd.read_sql(query, source_db.get_engine())
        
        log_success(f"Extraídos {len(df_source)} registros de MariaDB")
        
        # Transformar
        log_step("Transformando datos")
        
        df_source['pais'] = df_source['pais'].apply(clean_string)
        df_source['departamento'] = df_source['departamento'].apply(clean_string)
        df_source['municipio'] = df_source['municipio'].apply(clean_string)
        df_source['es_activo'] = df_source['activo'].apply(safe_bool)
        df_source['fecha_carga'] = get_timestamp()
        
        df_transformed = df_source[[
            'ubicacion_id',
            'pais',
            'departamento',
            'municipio',
            'es_activo',
            'fecha_carga'
        ]]
        
        # Cargar a SQL Server
        log_step("Cargando a dim_ubicacion (SQL Server)")
        
        with get_target_connection() as target_db:
            engine = target_db.get_engine()
            
            # Truncar tabla
            with engine.connect() as conn:
                conn.execute("TRUNCATE TABLE dbo.dim_ubicacion")
                conn.commit()
            
            # Insertar datos
            df_transformed.to_sql(
                'dim_ubicacion',
                engine,
                schema='dbo',
                if_exists='append',
                index=False,
                method='multi',
                chunksize=1000
            )
        
        log_success(f"Cargados {len(df_transformed)} registros a SQL Server")
        log_etl_end("Carga de dim_ubicacion", success=True, records=len(df_transformed))
        return True
        
    except Exception as e:
        log_error("Error en la carga de dim_ubicacion", e)
        log_etl_end("Carga de dim_ubicacion", success=False)
        return False


def load_all_static_dimensions() -> bool:
    """Cargar todas las dimensiones estáticas"""
    log = get_logger("dimensiones_estaticas")
    log_etl_start("Carga de Dimensiones Estáticas")
    
    results = {
        'dim_tipo_documento': load_dim_tipo_documento(),
        'dim_condicion_pago': load_dim_condicion_pago(),
        'dim_estado_venta': load_dim_estado_venta(),
        'dim_ubicacion': load_dim_ubicacion()
    }
    
    success_count = sum(results.values())
    total_count = len(results)
    
    log_step(f"Resultados: {success_count}/{total_count} dimensiones cargadas exitosamente")
    
    for dim_name, success in results.items():
        status = "✓" if success else "✗"
        log_step(f"{status} {dim_name}")
    
    all_success = all(results.values())
    log_etl_end("Carga de Dimensiones Estáticas", success=all_success)
    
    return all_success


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Cargar dimensiones estáticas')
    parser.add_argument('--dimension', type=str, choices=['tipo_documento', 'condicion_pago', 'estado_venta', 'ubicacion', 'all'],
                        default='all', help='Dimensión a cargar')
    
    args = parser.parse_args()
    
    if args.dimension == 'all':
        success = load_all_static_dimensions()
    elif args.dimension == 'tipo_documento':
        success = load_dim_tipo_documento()
    elif args.dimension == 'condicion_pago':
        success = load_dim_condicion_pago()
    elif args.dimension == 'estado_venta':
        success = load_dim_estado_venta()
    elif args.dimension == 'ubicacion':
        success = load_dim_ubicacion()
    
    sys.exit(0 if success else 1)
