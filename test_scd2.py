#!/usr/bin/env python3
"""
Script de prueba para validar SCD Type 2
Muestra registros actuales y permite verificar cambios históricos
"""
import sys
from pathlib import Path
import argparse

sys.path.append(str(Path(__file__).parent))

from etl.utils.database import TargetDatabase


def ver_cliente_historico(cliente_id: int = None):
    """Ver historial de un cliente o todos los clientes"""
    target_db = TargetDatabase()
    target_conn = target_db.get_connection()
    target_cursor = target_conn.cursor()
    
    if cliente_id:
        query = """
            SELECT 
                cliente_key,
                cliente_id,
                nombre,
                nombre_alternativo,
                nit,
                nrc,
                municipio,
                departamento,
                fecha_inicio,
                fecha_fin,
                version,
                es_actual
            FROM dbo.dim_cliente
            WHERE cliente_id = ?
            ORDER BY version
        """
        target_cursor.execute(query, (cliente_id,))
        print(f"\n{'=' * 120}")
        print(f"HISTORIAL DE CLIENTE ID: {cliente_id}")
        print('=' * 120)
    else:
        query = """
            SELECT 
                cliente_key,
                cliente_id,
                nombre,
                LEFT(nit, 15) as nit,
                fecha_inicio,
                fecha_fin,
                version,
                es_actual
            FROM dbo.dim_cliente
            WHERE es_actual = 1
            ORDER BY cliente_id
        """
        target_cursor.execute(query)
        print(f"\n{'=' * 100}")
        print(f"CLIENTES ACTUALES (es_actual = 1)")
        print('=' * 100)
    
    print(f"{'Key':<8} {'ID':<6} {'Nombre':<30} {'NIT':<17} {'Inicio':<12} {'Fin':<12} {'Ver':<5} {'Actual':<7}")
    print('-' * 100)
    
    for row in target_cursor.fetchall():
        if cliente_id:
            print(f"{row[0]:<8} {row[1]:<6} {row[2]:<30} {row[4] or 'N/A':<17} {str(row[8]):<12} {str(row[9] or 'NULL'):<12} {row[10]:<5} {'SÍ' if row[11] else 'NO':<7}")
        else:
            print(f"{row[0]:<8} {row[1]:<6} {row[2]:<30} {row[3] or 'N/A':<17} {str(row[4]):<12} {str(row[5] or 'NULL'):<12} {row[6]:<5} {'SÍ' if row[7] else 'NO':<7}")
    
    target_cursor.close()
    target_conn.close()


def ver_producto_historico(producto_id: int = None):
    """Ver historial de un producto o todos los productos"""
    target_db = TargetDatabase()
    target_conn = target_db.get_connection()
    target_cursor = target_conn.cursor()
    
    if producto_id:
        query = """
            SELECT 
                producto_key,
                producto_id,
                nombre,
                codigo,
                categoria_nombre,
                tipo_producto_nombre,
                producto_activo,
                fecha_inicio,
                fecha_fin,
                version,
                es_actual
            FROM dbo.dim_producto
            WHERE producto_id = ?
            ORDER BY version
        """
        target_cursor.execute(query, (producto_id,))
        print(f"\n{'=' * 130}")
        print(f"HISTORIAL DE PRODUCTO ID: {producto_id}")
        print('=' * 130)
    else:
        query = """
            SELECT 
                producto_key,
                producto_id,
                LEFT(nombre, 30) as nombre,
                codigo,
                categoria_nombre,
                producto_activo,
                fecha_inicio,
                fecha_fin,
                version,
                es_actual
            FROM dbo.dim_producto
            WHERE es_actual = 1
            ORDER BY producto_id
        """
        target_cursor.execute(query)
        print(f"\n{'=' * 120}")
        print(f"PRODUCTOS ACTUALES (es_actual = 1)")
        print('=' * 120)
    
    print(f"{'Key':<8} {'ID':<6} {'Nombre':<32} {'Código':<12} {'Categoría':<15} {'Activo':<8} {'Inicio':<12} {'Fin':<12} {'Ver':<5} {'Actual':<7}")
    print('-' * 120)
    
    for row in target_cursor.fetchall():
        if producto_id:
            print(f"{row[0]:<8} {row[1]:<6} {row[2]:<32} {row[3] or 'N/A':<12} {row[4] or 'N/A':<15} {'SÍ' if row[6] else 'NO':<8} {str(row[7]):<12} {str(row[8] or 'NULL'):<12} {row[9]:<5} {'SÍ' if row[10] else 'NO':<7}")
        else:
            print(f"{row[0]:<8} {row[1]:<6} {row[2]:<32} {row[3] or 'N/A':<12} {row[4] or 'N/A':<15} {'SÍ' if row[5] else 'NO':<8} {str(row[6]):<12} {str(row[7] or 'NULL'):<12} {row[8]:<5} {'SÍ' if row[9] else 'NO':<7}")
    
    target_cursor.close()
    target_conn.close()


def ver_vendedor_historico(vendedor_id: int = None):
    """Ver historial de un vendedor o todos los vendedores"""
    target_db = TargetDatabase()
    target_conn = target_db.get_connection()
    target_cursor = target_conn.cursor()
    
    if vendedor_id:
        query = """
            SELECT 
                vendedor_key,
                vendedor_id,
                nombre,
                apellido,
                email,
                username,
                fecha_inicio,
                fecha_fin,
                version,
                es_actual
            FROM dbo.dim_vendedor
            WHERE vendedor_id = ?
            ORDER BY version
        """
        target_cursor.execute(query, (vendedor_id,))
        print(f"\n{'=' * 120}")
        print(f"HISTORIAL DE VENDEDOR ID: {vendedor_id}")
        print('=' * 120)
    else:
        query = """
            SELECT 
                vendedor_key,
                vendedor_id,
                nombre,
                apellido,
                email,
                username,
                fecha_inicio,
                fecha_fin,
                version,
                es_actual
            FROM dbo.dim_vendedor
            WHERE es_actual = 1
            ORDER BY vendedor_id
        """
        target_cursor.execute(query)
        print(f"\n{'=' * 120}")
        print(f"VENDEDORES ACTUALES (es_actual = 1)")
        print('=' * 120)
    
    print(f"{'Key':<8} {'ID':<6} {'Nombre':<20} {'Apellido':<20} {'Email':<30} {'Inicio':<12} {'Fin':<12} {'Ver':<5} {'Actual':<7}")
    print('-' * 120)
    
    for row in target_cursor.fetchall():
        print(f"{row[0]:<8} {row[1]:<6} {row[2]:<20} {row[3] or 'N/A':<20} {row[4] or 'N/A':<30} {str(row[6]):<12} {str(row[7] or 'NULL'):<12} {row[8]:<5} {'SÍ' if row[9] else 'NO':<7}")
    
    target_cursor.close()
    target_conn.close()


def estadisticas_scd2():
    """Mostrar estadísticas generales de SCD2"""
    target_db = TargetDatabase()
    target_conn = target_db.get_connection()
    target_cursor = target_conn.cursor()
    
    print(f"\n{'=' * 80}")
    print("ESTADÍSTICAS SCD TYPE 2")
    print('=' * 80)
    
    # Clientes
    target_cursor.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) as actuales,
            COUNT(DISTINCT cliente_id) as unicos,
            MAX(version) as max_version
        FROM dbo.dim_cliente
    """)
    row = target_cursor.fetchone()
    print(f"\nCLIENTES:")
    print(f"  Total registros:      {row[0]}")
    print(f"  Registros actuales:   {row[1]}")
    print(f"  Clientes únicos:      {row[2]}")
    print(f"  Máxima versión:       {row[3]}")
    
    # Productos
    target_cursor.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) as actuales,
            COUNT(DISTINCT producto_id) as unicos,
            MAX(version) as max_version
        FROM dbo.dim_producto
    """)
    row = target_cursor.fetchone()
    print(f"\nPRODUCTOS:")
    print(f"  Total registros:      {row[0]}")
    print(f"  Registros actuales:   {row[1]}")
    print(f"  Productos únicos:     {row[2]}")
    print(f"  Máxima versión:       {row[3]}")
    
    # Vendedores
    target_cursor.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN es_actual = 1 THEN 1 ELSE 0 END) as actuales,
            COUNT(DISTINCT vendedor_id) as unicos,
            MAX(version) as max_version
        FROM dbo.dim_vendedor
    """)
    row = target_cursor.fetchone()
    print(f"\nVENDEDORES:")
    print(f"  Total registros:      {row[0]}")
    print(f"  Registros actuales:   {row[1]}")
    print(f"  Vendedores únicos:    {row[2]}")
    print(f"  Máxima versión:       {row[3]}")
    
    # Registros con múltiples versiones
    print(f"\n{'-' * 80}")
    print("REGISTROS CON HISTORIAL (más de 1 versión):")
    print('-' * 80)
    
    target_cursor.execute("""
        SELECT cliente_id, MAX(version) as versiones
        FROM dbo.dim_cliente
        GROUP BY cliente_id
        HAVING MAX(version) > 1
        ORDER BY versiones DESC, cliente_id
    """)
    clientes_con_historial = target_cursor.fetchall()
    if clientes_con_historial:
        print(f"\nClientes con historial: {len(clientes_con_historial)}")
        for row in clientes_con_historial[:5]:
            print(f"  Cliente ID {row[0]}: {row[1]} versiones")
        if len(clientes_con_historial) > 5:
            print(f"  ... y {len(clientes_con_historial) - 5} más")
    else:
        print(f"\nClientes con historial: 0")
    
    target_cursor.execute("""
        SELECT producto_id, MAX(version) as versiones
        FROM dbo.dim_producto
        GROUP BY producto_id
        HAVING MAX(version) > 1
        ORDER BY versiones DESC, producto_id
    """)
    productos_con_historial = target_cursor.fetchall()
    if productos_con_historial:
        print(f"\nProductos con historial: {len(productos_con_historial)}")
        for row in productos_con_historial[:5]:
            print(f"  Producto ID {row[0]}: {row[1]} versiones")
        if len(productos_con_historial) > 5:
            print(f"  ... y {len(productos_con_historial) - 5} más")
    else:
        print(f"\nProductos con historial: 0")
    
    target_cursor.close()
    target_conn.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Prueba y visualización de SCD Type 2')
    parser.add_argument('--dimension', choices=['cliente', 'producto', 'vendedor', 'stats'], 
                        required=True, help='Dimensión a consultar')
    parser.add_argument('--id', type=int, help='ID específico para ver historial completo')
    
    args = parser.parse_args()
    
    if args.dimension == 'stats':
        estadisticas_scd2()
    elif args.dimension == 'cliente':
        ver_cliente_historico(args.id)
    elif args.dimension == 'producto':
        ver_producto_historico(args.id)
    elif args.dimension == 'vendedor':
        ver_vendedor_historico(args.id)
    
    print()
