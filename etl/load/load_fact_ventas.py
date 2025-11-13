"""
ETL: Carga de fact_ventas
Carga la tabla de hechos con las transacciones de ventas
"""
import sys
from pathlib import Path
from datetime import datetime
import argparse

sys.path.append(str(Path(__file__).parent.parent.parent))

from etl.utils.database import SourceDatabase, TargetDatabase
from etl.utils.logger import get_logger, log_etl_start, log_etl_end, log_step, log_error, log_success


def get_dimension_keys(target_cursor):
    """Obtener mappings de IDs a keys de las dimensiones"""
    
    log_step("Cargando mapeos de dimensiones...")
    
    # dim_tiempo: fecha -> tiempo_key
    target_cursor.execute("SELECT tiempo_key, fecha FROM dbo.dim_tiempo")
    dim_tiempo = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    # dim_cliente: cliente_id -> cliente_key (solo registros actuales)
    target_cursor.execute("SELECT cliente_key, cliente_id FROM dbo.dim_cliente WHERE es_actual = 1")
    dim_cliente = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    # dim_producto: producto_id -> producto_key (solo registros actuales)
    target_cursor.execute("SELECT producto_key, producto_id FROM dbo.dim_producto WHERE es_actual = 1")
    dim_producto = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    # dim_vendedor: vendedor_id -> vendedor_key (solo registros actuales)
    target_cursor.execute("SELECT vendedor_key, vendedor_id FROM dbo.dim_vendedor WHERE es_actual = 1")
    dim_vendedor = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    # dim_tipo_documento: tipo_documento_id -> tipo_documento_key
    target_cursor.execute("SELECT tipo_documento_key, tipo_documento_id FROM dbo.dim_tipo_documento")
    dim_tipo_documento = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    # dim_condicion_pago: condicion_pago_id -> condicion_pago_key
    target_cursor.execute("SELECT condicion_pago_key, condicion_pago_id FROM dbo.dim_condicion_pago")
    dim_condicion_pago = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    # dim_estado_venta: estado_venta_id -> estado_venta_key
    target_cursor.execute("SELECT estado_venta_key, estado_venta_id FROM dbo.dim_estado_venta")
    dim_estado_venta = {row[1]: row[0] for row in target_cursor.fetchall()}
    
    log_success(f"Mapeos cargados: {len(dim_tiempo)} fechas, {len(dim_cliente)} clientes, " +
                f"{len(dim_producto)} productos, {len(dim_vendedor)} vendedores")
    
    return {
        'tiempo': dim_tiempo,
        'cliente': dim_cliente,
        'producto': dim_producto,
        'vendedor': dim_vendedor,
        'tipo_documento': dim_tipo_documento,
        'condicion_pago': dim_condicion_pago,
        'estado_venta': dim_estado_venta
    }


def load_fact_ventas(fecha_inicio: str = None, fecha_fin: str = None, truncate: bool = False) -> bool:
    """
    Carga fact_ventas desde MariaDB
    
    Args:
        fecha_inicio: Fecha inicial (YYYY-MM-DD), si es None carga todo
        fecha_fin: Fecha final (YYYY-MM-DD), si es None usa fecha actual
        truncate: Si True, limpia la tabla antes de cargar
    """
    log = get_logger("fact_ventas")
    
    if fecha_inicio:
        log_etl_start(f"Carga de fact_ventas (desde {fecha_inicio} hasta {fecha_fin or 'hoy'})")
    else:
        log_etl_start("Carga COMPLETA de fact_ventas")
    
    try:
        # PASO 1: Obtener mapeos de dimensiones
        target_db = TargetDatabase()
        target_conn = target_db.get_connection()
        target_cursor = target_conn.cursor()
        
        dim_keys = get_dimension_keys(target_cursor)
        
        # PASO 2: Limpiar tabla si se solicita
        if truncate:
            log_step("Limpiando fact_ventas...")
            target_cursor.execute("DELETE FROM dbo.fact_ventas")
            target_conn.commit()
            log_success("Tabla limpiada")
        
        # PASO 3: Extraer ventas de MariaDB
        log_step("Extrayendo ventas de MariaDB...")
        
        source_db = SourceDatabase()
        source_conn = source_db.get_connection()
        source_cursor = source_conn.cursor()
        
        # Query principal: ventas -> orden_pedidos -> salidas
        # Según tu análisis: salidas tiene el detalle por producto
        query = """
            SELECT 
                v.id as venta_id,
                v.tipo_documento_id,
                v.orden_pedido_id,
                v.estado_venta_id,
                v.cliente_id,
                v.vendedor_id,
                v.condicion_pago_id,
                v.numero as numero_venta,
                v.fecha as fecha_venta,
                v.saldo,
                v.fecha_anulado,
                v.fecha_liquidado,
                -- Desde orden_pedidos
                op.vendedor_id as op_vendedor_id,
                -- Desde salidas (detalle por producto)
                s.id as salida_id,
                s.cantidad,
                s.precio_unitario,
                s.venta_exenta,
                s.venta_gravada,
                -- Producto: desde precios o producciones
                COALESCE(pr.producto_id, prod.producto_id) as producto_id
            FROM ventas v
            LEFT JOIN orden_pedidos op ON v.orden_pedido_id = op.id
            LEFT JOIN salidas s ON s.orden_pedido_id = op.id
            LEFT JOIN precios pr ON s.precio_id = pr.id
            LEFT JOIN producciones prod ON s.produccion_id = prod.id
            WHERE s.id IS NOT NULL  -- Solo ventas con detalle
        """
        
        # Filtro por fechas si se proporciona
        if fecha_inicio:
            query += f" AND v.fecha >= '{fecha_inicio}'"
        if fecha_fin:
            query += f" AND v.fecha <= '{fecha_fin}'"
        
        query += " ORDER BY v.fecha, v.id, s.id"
        
        source_cursor.execute(query)
        rows = source_cursor.fetchall()
        source_cursor.close()
        source_conn.close()
        
        log_success(f"Extraídos {len(rows)} registros de ventas")
        
        if len(rows) == 0:
            log_success("No hay datos para cargar")
            target_cursor.close()
            target_conn.close()
            log_etl_end("Carga de fact_ventas", success=True, records=0)
            return True
        
        # PASO 4: Transformar y cargar
        log_step(f"Transformando y cargando {len(rows)} registros...")
        
        insert_count = 0
        skip_count = 0
        errors = []
        
        for row in rows:
            try:
                # Obtener keys de dimensiones
                fecha_venta = row['fecha_venta']
                tiempo_key = dim_keys['tiempo'].get(fecha_venta)
                cliente_key = dim_keys['cliente'].get(row['cliente_id'])
                producto_key = dim_keys['producto'].get(row['producto_id'])
                
                # Vendedor: primero de orden_pedido, luego de venta
                vendedor_id = row.get('op_vendedor_id') or row.get('vendedor_id')
                vendedor_key = dim_keys['vendedor'].get(vendedor_id) if vendedor_id else None
                
                tipo_documento_key = dim_keys['tipo_documento'].get(row['tipo_documento_id'])
                condicion_pago_key = dim_keys['condicion_pago'].get(row['condicion_pago_id'])
                estado_venta_key = dim_keys['estado_venta'].get(row['estado_venta_id'])
                
                # Validar keys obligatorias
                if not all([tiempo_key, cliente_key, producto_key, tipo_documento_key, estado_venta_key]):
                    skip_count += 1
                    if skip_count <= 5:
                        errors.append(f"Venta {row['venta_id']}, Salida {row['salida_id']}: Falta key de dimensión")
                    continue
                
                # Calcular métricas según tu análisis
                cantidad = float(row['cantidad'] or 0)
                precio_unitario = float(row['precio_unitario'] or 0)
                venta_exenta = float(row['venta_exenta'] or 0)
                venta_gravada = float(row['venta_gravada'] or 0)
                
                # Según tu documentación:
                # venta_total = venta_gravada * 1.13
                # iva = venta_gravada * 0.13
                venta_total = venta_gravada * 1.13
                iva = venta_gravada * 0.13
                venta_total_con_impuestos = venta_gravada * 1.13
                
                # Estados de la venta
                esta_liquidado = 1 if row['fecha_liquidado'] else 0
                esta_anulado = 1 if row['fecha_anulado'] else 0
                es_venta_credito = 1 if row['condicion_pago_id'] and row['condicion_pago_id'] != 1 else 0
                
                # Insertar en fact_ventas
                target_cursor.execute("""
                    INSERT INTO dbo.fact_ventas (
                        tiempo_key, cliente_key, producto_key, vendedor_key,
                        tipo_documento_key, condicion_pago_key, estado_venta_key,
                        venta_id, orden_pedido_id, numero_venta,
                        cantidad, precio_unitario, venta_exenta, venta_gravada,
                        venta_total, iva, venta_total_con_impuestos,
                        es_venta_credito, esta_liquidado, esta_anulado,
                        fecha_venta, fecha_liquidacion, fecha_anulacion, fecha_carga
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
                """, (
                    tiempo_key, cliente_key, producto_key, vendedor_key,
                    tipo_documento_key, condicion_pago_key, estado_venta_key,
                    row['venta_id'], row['orden_pedido_id'], row['numero_venta'],
                    cantidad, precio_unitario, venta_exenta, venta_gravada,
                    venta_total, iva, venta_total_con_impuestos,
                    es_venta_credito, esta_liquidado, esta_anulado,
                    fecha_venta, row['fecha_liquidado'], row['fecha_anulado']
                ))
                
                insert_count += 1
                
                # Commit cada 1000 registros
                if insert_count % 1000 == 0:
                    target_conn.commit()
                    log_step(f"Progreso: {insert_count} registros insertados...")
                    
            except Exception as e:
                skip_count += 1
                if skip_count <= 5:
                    errors.append(f"Venta {row['venta_id']}: {str(e)}")
        
        # Commit final
        target_conn.commit()
        target_cursor.close()
        target_conn.close()
        
        log_success(f"Insertados: {insert_count} registros")
        
        if skip_count > 0:
            log_step(f"Omitidos: {skip_count} registros (sin keys o errores)")
            if errors:
                for error in errors[:5]:
                    log_step(f"  - {error}")
                if len(errors) > 5:
                    log_step(f"  ... y {len(errors)-5} errores más")
        
        log_etl_end("Carga de fact_ventas", success=True, records=insert_count)
        return True
        
    except Exception as e:
        log_error("Error en la carga de fact_ventas", e)
        log_etl_end("Carga de fact_ventas", success=False)
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Carga de fact_ventas')
    parser.add_argument('--fecha-inicio', help='Fecha inicial (YYYY-MM-DD)')
    parser.add_argument('--fecha-fin', help='Fecha final (YYYY-MM-DD)')
    parser.add_argument('--truncate', action='store_true', 
                        help='Limpiar tabla antes de cargar')
    
    args = parser.parse_args()
    
    success = load_fact_ventas(
        fecha_inicio=args.fecha_inicio,
        fecha_fin=args.fecha_fin,
        truncate=args.truncate
    )
    
    sys.exit(0 if success else 1)
