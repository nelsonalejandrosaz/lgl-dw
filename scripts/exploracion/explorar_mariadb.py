"""Script para explorar tablas en MariaDB"""
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from etl.utils.database import get_source_connection

print("="*80)
print("EXPLORANDO BASE DE DATOS MARIADB")
print("="*80)

with get_source_connection() as source_db:
    conn = source_db.get_connection()
    cursor = conn.cursor()
    
    # Obtener todas las tablas
    cursor.execute("SHOW TABLES")
    tables = cursor.fetchall()
    
    print(f"\nTotal de tablas: {len(tables)}\n")
    
    for table in tables:
        table_name = list(table.values())[0]
        print(f"* {table_name}")
        
        # Obtener columnas de cada tabla
        cursor.execute(f"DESCRIBE `{table_name}`")
        columns = cursor.fetchall()
        
        for col in columns:
            print(f"   - {col['Field']} ({col['Type']})")
        print()
    
    cursor.close()

print("="*80)
