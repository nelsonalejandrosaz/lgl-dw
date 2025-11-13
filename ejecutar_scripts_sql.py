"""
Script para ejecutar archivos SQL en SQL Server
"""
import sys
import os
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from etl.utils.database import get_target_connection

def ejecutar_archivo_sql(archivo_sql: str):
    """Ejecutar un archivo SQL completo"""
    print(f"\n{'='*80}")
    print(f"Ejecutando: {archivo_sql}")
    print(f"{'='*80}\n")
    
    # Leer archivo
    with open(archivo_sql, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    # Dividir por GO
    batches = sql_content.split('GO')
    
    with get_target_connection() as target_db:
        conn = target_db.get_connection()
        cursor = conn.cursor()
        
        for i, batch in enumerate(batches, 1):
            batch = batch.strip()
            if not batch or batch.startswith('--'):
                continue
            
            try:
                print(f"Ejecutando batch {i}/{len(batches)}...", end=' ')
                cursor.execute(batch)
                conn.commit()
                print("✓")
            except Exception as e:
                if 'already exists' in str(e) or 'ya existe' in str(e):
                    print("⚠ (ya existe)")
                else:
                    print(f"\n✗ Error: {e}")
        
        cursor.close()
    
    print(f"\n✓ Archivo ejecutado: {os.path.basename(archivo_sql)}\n")

if __name__ == "__main__":
    base_path = "database/target/"
    
    archivos = [
        "01_crear_dimensiones.sql",
        "02_crear_hechos.sql",
        "03_crear_vistas.sql",
        "04_crear_stored_procedures.sql"
    ]
    
    print("\n" + "="*80)
    print("EJECUTANDO SCRIPTS SQL EN SQL SERVER")
    print("="*80)
    
    for archivo in archivos:
        ruta_completa = os.path.join(base_path, archivo)
        if os.path.exists(ruta_completa):
            ejecutar_archivo_sql(ruta_completa)
        else:
            print(f"✗ Archivo no encontrado: {ruta_completa}")
    
    print("\n" + "="*80)
    print("✓ TODOS LOS SCRIPTS EJECUTADOS")
    print("="*80)
