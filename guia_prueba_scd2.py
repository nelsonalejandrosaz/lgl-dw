#!/usr/bin/env python3
"""
Script para probar SCD Type 2 - Modificación de datos en MariaDB
Este script te permite hacer cambios controlados para probar el versionado
"""
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent))

from etl.utils.database import SourceDatabase


def mostrar_instrucciones():
    """Muestra instrucciones para probar SCD Type 2"""
    print("""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    GUÍA DE PRUEBA SCD TYPE 2                                   ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Esta guía te ayudará a probar que el SCD Type 2 funciona correctamente.

PASO 1: Ver estado actual
─────────────────────────
Ejecuta:
  python test_scd2.py --dimension cliente
  python test_scd2.py --dimension producto  
  python test_scd2.py --dimension stats

PASO 2: Modificar datos en MariaDB
──────────────────────────────────
Conéctate a MariaDB y ejecuta UNA de estas opciones:

OPCIÓN A - Modificar un cliente:
  UPDATE clientes 
  SET nombre = 'NOMBRE MODIFICADO PRUEBA SCD2',
      nit = '9999-999999-999-9'
  WHERE id = 1;

OPCIÓN B - Modificar un producto:
  UPDATE productos 
  SET nombre = 'PRODUCTO MODIFICADO PRUEBA SCD2',
      codigo = 'TEST-001'
  WHERE id = 1;

OPCIÓN C - Modificar un vendedor:
  UPDATE users 
  SET nombre = 'VENDEDOR',
      apellido = 'MODIFICADO'
  WHERE id = (SELECT DISTINCT vendedor_id FROM clientes LIMIT 1);

PASO 3: Ver registros antes del cambio en DW
────────────────────────────────────────────
  python test_scd2.py --dimension cliente --id 1
  python test_scd2.py --dimension producto --id 1

Verás 1 sola versión (version = 1, es_actual = 1)

PASO 4: Ejecutar carga incremental
──────────────────────────────────
  python etl/load/load_dim_cliente.py --mode incremental
  python etl/load/load_dim_producto.py --mode incremental
  python etl/load/load_dim_vendedor.py --mode incremental

Deberías ver en el log:
  "Nuevos: 0, Modificados: 1"

PASO 5: Verificar el historial
──────────────────────────────
  python test_scd2.py --dimension cliente --id 1
  python test_scd2.py --dimension producto --id 1
  python test_scd2.py --dimension stats

Ahora verás:
  - 2 versiones para el registro modificado
  - Versión 1: es_actual = 0, fecha_fin = hoy
  - Versión 2: es_actual = 1, fecha_fin = NULL

PASO 6: Consulta SQL directa (opcional)
───────────────────────────────────────
Puedes verificar directamente en SQL Server:

SELECT 
    cliente_key,
    cliente_id,
    nombre,
    nit,
    fecha_inicio,
    fecha_fin,
    version,
    es_actual
FROM dbo.dim_cliente
WHERE cliente_id = 1
ORDER BY version;

╔═══════════════════════════════════════════════════════════════════════════════╗
║  IMPORTANTE: El modo incremental solo funciona con registros ya cargados      ║
║  Si borras los datos del DW, debes hacer primero una carga FULL              ║
╚═══════════════════════════════════════════════════════════════════════════════╝
    """)


def ver_registros_mariadb():
    """Muestra algunos registros de MariaDB para facilitar las pruebas"""
    source_db = SourceDatabase()
    source_conn = source_db.get_connection()
    source_cursor = source_conn.cursor()
    
    print("\n" + "=" * 100)
    print("REGISTROS DISPONIBLES EN MARIADB PARA PRUEBAS")
    print("=" * 100)
    
    # Clientes
    print("\nPRIMEROS 5 CLIENTES:")
    print(f"{'ID':<6} {'Nombre':<40} {'NIT':<20}")
    print('-' * 100)
    source_cursor.execute("""
        SELECT id, nombre, nit 
        FROM clientes 
        ORDER BY id 
        LIMIT 5
    """)
    for row in source_cursor.fetchall():
        print(f"{row['id']:<6} {row['nombre']:<40} {(row.get('nit') or 'N/A'):<20}")
    
    # Productos
    print("\nPRIMEROS 5 PRODUCTOS:")
    print(f"{'ID':<6} {'Nombre':<50} {'Código':<15}")
    print('-' * 100)
    source_cursor.execute("""
        SELECT id, nombre, codigo 
        FROM productos 
        WHERE deleted_at IS NULL
        ORDER BY id 
        LIMIT 5
    """)
    for row in source_cursor.fetchall():
        print(f"{row['id']:<6} {row['nombre']:<50} {(row.get('codigo') or 'N/A'):<15}")
    
    # Vendedores
    print("\nPRIMEROS 5 VENDEDORES:")
    print(f"{'ID':<6} {'Nombre':<25} {'Apellido':<25} {'Email':<30}")
    print('-' * 100)
    source_cursor.execute("""
        SELECT DISTINCT u.id, u.nombre, u.apellido, u.email
        FROM users u
        INNER JOIN clientes c ON c.vendedor_id = u.id
        ORDER BY u.id
        LIMIT 5
    """)
    for row in source_cursor.fetchall():
        print(f"{row['id']:<6} {row['nombre']:<25} {(row.get('apellido') or 'N/A'):<25} {(row.get('email') or 'N/A'):<30}")
    
    source_cursor.close()
    source_conn.close()
    
    print("\n" + "=" * 100)
    print("Usa estos IDs para hacer tus pruebas de modificación")
    print("=" * 100 + "\n")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == '--list':
        ver_registros_mariadb()
    else:
        mostrar_instrucciones()
