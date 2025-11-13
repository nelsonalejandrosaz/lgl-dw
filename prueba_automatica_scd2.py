#!/usr/bin/env python3
"""
Script de prueba automatizada de SCD Type 2
Modifica un registro, ejecuta carga incremental y muestra resultados
"""
import sys
from pathlib import Path
import subprocess

sys.path.append(str(Path(__file__).parent))

from etl.utils.database import SourceDatabase, TargetDatabase


def prueba_scd2_cliente():
    """Prueba completa de SCD Type 2 para clientes"""
    print("\n" + "=" * 80)
    print("PRUEBA AUTOMATIZADA SCD TYPE 2 - CLIENTE")
    print("=" * 80)
    
    # PASO 1: Seleccionar un cliente y ver estado inicial
    print("\n[PASO 1] Estado inicial en DW")
    print("-" * 80)
    
    target_db = TargetDatabase()
    target_conn = target_db.get_connection()
    target_cursor = target_conn.cursor()
    
    target_cursor.execute("""
        SELECT TOP 1 
            cliente_key, cliente_id, nombre, nit, version, es_actual
        FROM dbo.dim_cliente
        WHERE es_actual = 1
        ORDER BY cliente_id
    """)
    row = target_cursor.fetchone()
    cliente_id = row[1]
    nombre_original = row[2]
    nit_original = row[3]
    
    print(f"Cliente seleccionado: ID={cliente_id}")
    print(f"  Nombre actual DW: {nombre_original}")
    print(f"  NIT actual DW:    {nit_original or 'NULL'}")
    print(f"  Versión:          {row[4]}")
    print(f"  Es actual:        {row[5]}")
    
    # PASO 2: Modificar en MariaDB
    print("\n[PASO 2] Modificando datos en MariaDB")
    print("-" * 80)
    
    source_db = SourceDatabase()
    source_conn = source_db.get_connection()
    source_cursor = source_conn.cursor()
    
    nuevo_nombre = "CLIENTE MODIFICADO PRUEBA SCD2"
    nuevo_nit = "9999-999999-999-9"
    
    source_cursor.execute("""
        UPDATE clientes 
        SET nombre = %s,
            nit = %s
        WHERE id = %s
    """, (nuevo_nombre, nuevo_nit, cliente_id))
    source_conn.commit()
    
    print(f"✓ Registro modificado en MariaDB:")
    print(f"  Nuevo nombre: {nuevo_nombre}")
    print(f"  Nuevo NIT:    {nuevo_nit}")
    
    source_cursor.close()
    source_conn.close()
    
    # PASO 3: Ejecutar carga incremental
    print("\n[PASO 3] Ejecutando carga incremental")
    print("-" * 80)
    
    result = subprocess.run(
        ["python", "etl/load/load_dim_cliente.py", "--mode", "incremental"],
        capture_output=True,
        text=True
    )
    
    # Mostrar solo líneas relevantes del log
    for line in result.stdout.split('\n'):
        if 'Nuevos:' in line or 'Modificados:' in line or 'Procesados' in line or 'EXITOSO' in line or 'FALLIDO' in line:
            print(line)
    
    # PASO 4: Verificar historial en DW
    print("\n[PASO 4] Verificando historial en DW")
    print("-" * 80)
    
    target_cursor.execute("""
        SELECT 
            cliente_key, version, nombre, nit, 
            fecha_inicio, fecha_fin, es_actual
        FROM dbo.dim_cliente
        WHERE cliente_id = ?
        ORDER BY version
    """, (cliente_id,))
    
    rows = target_cursor.fetchall()
    
    print(f"\nTotal de versiones: {len(rows)}")
    print(f"\n{'Ver':<5} {'Nombre':<35} {'NIT':<20} {'Inicio':<12} {'Fin':<12} {'Actual':<7}")
    print('-' * 100)
    
    for row in rows:
        print(f"{row[1]:<5} {row[2]:<35} {row[3] or 'NULL':<20} {str(row[4]):<12} {str(row[5] or 'NULL'):<12} {'SÍ' if row[6] else 'NO':<7}")
    
    target_cursor.close()
    target_conn.close()
    
    # PASO 5: Restaurar valor original
    print("\n[PASO 5] Restaurando valor original")
    print("-" * 80)
    
    source_db = SourceDatabase()
    source_conn = source_db.get_connection()
    source_cursor = source_conn.cursor()
    
    source_cursor.execute("""
        UPDATE clientes 
        SET nombre = %s,
            nit = %s
        WHERE id = %s
    """, (nombre_original, nit_original, cliente_id))
    source_conn.commit()
    
    print(f"✓ Valor restaurado en MariaDB")
    
    source_cursor.close()
    source_conn.close()
    
    print("\n" + "=" * 80)
    print("PRUEBA COMPLETADA")
    print("=" * 80)
    print("\nPara ver todas las versiones ejecuta:")
    print(f"  python test_scd2.py --dimension cliente --id {cliente_id}")
    print()


def prueba_scd2_producto():
    """Prueba completa de SCD Type 2 para productos"""
    print("\n" + "=" * 80)
    print("PRUEBA AUTOMATIZADA SCD TYPE 2 - PRODUCTO")
    print("=" * 80)
    
    # PASO 1: Seleccionar un producto y ver estado inicial
    print("\n[PASO 1] Estado inicial en DW")
    print("-" * 80)
    
    target_db = TargetDatabase()
    target_conn = target_db.get_connection()
    target_cursor = target_conn.cursor()
    
    target_cursor.execute("""
        SELECT TOP 1 
            producto_key, producto_id, nombre, codigo, version, es_actual
        FROM dbo.dim_producto
        WHERE es_actual = 1
        ORDER BY producto_id
    """)
    row = target_cursor.fetchone()
    producto_id = row[1]
    nombre_original = row[2]
    codigo_original = row[3]
    
    print(f"Producto seleccionado: ID={producto_id}")
    print(f"  Nombre actual DW: {nombre_original}")
    print(f"  Código actual DW: {codigo_original or 'NULL'}")
    print(f"  Versión:          {row[4]}")
    print(f"  Es actual:        {row[5]}")
    
    # PASO 2: Modificar en MariaDB
    print("\n[PASO 2] Modificando datos en MariaDB")
    print("-" * 80)
    
    source_db = SourceDatabase()
    source_conn = source_db.get_connection()
    source_cursor = source_conn.cursor()
    
    nuevo_nombre = "PRODUCTO MODIFICADO PRUEBA SCD2"
    nuevo_codigo = "TEST-SCD2-001"
    
    source_cursor.execute("""
        UPDATE productos 
        SET nombre = %s,
            codigo = %s
        WHERE id = %s
    """, (nuevo_nombre, nuevo_codigo, producto_id))
    source_conn.commit()
    
    print(f"✓ Registro modificado en MariaDB:")
    print(f"  Nuevo nombre: {nuevo_nombre}")
    print(f"  Nuevo código: {nuevo_codigo}")
    
    source_cursor.close()
    source_conn.close()
    
    # PASO 3: Ejecutar carga incremental
    print("\n[PASO 3] Ejecutando carga incremental")
    print("-" * 80)
    
    result = subprocess.run(
        ["python", "etl/load/load_dim_producto.py", "--mode", "incremental"],
        capture_output=True,
        text=True
    )
    
    # Mostrar solo líneas relevantes del log
    for line in result.stdout.split('\n'):
        if 'Nuevos:' in line or 'Modificados:' in line or 'Procesados' in line or 'EXITOSO' in line or 'FALLIDO' in line:
            print(line)
    
    if result.returncode != 0:
        print("\n⚠ El modo incremental no está implementado aún")
        print("Puedes ejecutar:")
        print("  python etl/load/load_dim_producto.py --mode full")
        
    # PASO 4: Restaurar valor original
    print("\n[PASO 4] Restaurando valor original")
    print("-" * 80)
    
    source_db = SourceDatabase()
    source_conn = source_db.get_connection()
    source_cursor = source_conn.cursor()
    
    source_cursor.execute("""
        UPDATE productos 
        SET nombre = %s,
            codigo = %s
        WHERE id = %s
    """, (nombre_original, codigo_original, producto_id))
    source_conn.commit()
    
    print(f"✓ Valor restaurado en MariaDB")
    
    source_cursor.close()
    source_conn.close()
    
    target_cursor.close()
    target_conn.close()
    
    print("\n" + "=" * 80)
    print("PRUEBA COMPLETADA")
    print("=" * 80)
    print()


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Prueba automatizada de SCD Type 2')
    parser.add_argument('--dimension', choices=['cliente', 'producto'], 
                        default='cliente', help='Dimensión a probar')
    
    args = parser.parse_args()
    
    if args.dimension == 'cliente':
        prueba_scd2_cliente()
    elif args.dimension == 'producto':
        prueba_scd2_producto()
