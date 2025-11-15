"""
Actualizar estructura de fact_ventas
Elimina campos de costo y margen
"""
import pyodbc

print("\nActualizando estructura de fact_ventas...")
print("=" * 60)

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=LGL_DW;'
    'Trusted_Connection=yes;'
    'TrustServerCertificate=yes;'
)

cursor = conn.cursor()

try:
    # Eliminar columnas de costo y margen
    print("\n1. Eliminando columnas de costo y margen...")
    
    columnas = ['costo_venta', 'margen_bruto', 'porcentaje_margen']
    
    for columna in columnas:
        try:
            # Primero eliminar constraint DEFAULT si existe
            cursor.execute(f"""
                DECLARE @ConstraintName nvarchar(200)
                SELECT @ConstraintName = dc.name
                FROM sys.default_constraints dc
                JOIN sys.columns c ON dc.parent_column_id = c.column_id
                WHERE dc.parent_object_id = OBJECT_ID('dbo.fact_ventas')
                AND c.name = '{columna}'
                
                IF @ConstraintName IS NOT NULL
                    EXEC('ALTER TABLE dbo.fact_ventas DROP CONSTRAINT ' + @ConstraintName)
            """)
            conn.commit()
            
            # Luego eliminar la columna
            cursor.execute(f"""
                IF EXISTS (
                    SELECT 1 FROM sys.columns 
                    WHERE object_id = OBJECT_ID('dbo.fact_ventas') 
                    AND name = '{columna}'
                )
                BEGIN
                    ALTER TABLE dbo.fact_ventas DROP COLUMN {columna}
                END
            """)
            conn.commit()
            print(f"   [OK] {columna}")
        except Exception as e:
            print(f"   [ERROR] {columna}: {e}")
    
    conn.commit()
    
    # Verificar estructura actualizada
    print("\n2. Verificando estructura actualizada...")
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'fact_ventas'
        ORDER BY ORDINAL_POSITION
    """)
    
    print("\n   Columnas actuales en fact_ventas:")
    for row in cursor.fetchall():
        print(f"   - {row[0]:30} {row[1]:15} {'NULL' if row[2]=='YES' else 'NOT NULL'}")
    
    # Recrear vistas
    print("\n3. Ejecutando script de vistas...")
    
    with open(r'c:\Users\nsaz\proyectos\lgl-dw\database\target\03_crear_vistas.sql', 'r', encoding='utf-8') as f:
        sql_script = f.read()
    
    # Ejecutar por lotes (separados por GO)
    batches = sql_script.split('GO')
    for i, batch in enumerate(batches, 1):
        batch = batch.strip()
        if batch and not batch.startswith('--') and batch != '':
            try:
                cursor.execute(batch)
                conn.commit()
            except Exception as e:
                if 'PRINT' not in batch:
                    print(f"   [ADVERTENCIA] Lote {i}: {str(e)[:80]}")
    
    print("   [OK] Vistas recreadas")
    
    # Verificar vistas
    print("\n4. Verificando vistas...")
    cursor.execute("""
        SELECT name 
        FROM sys.views 
        WHERE schema_id = SCHEMA_ID('dbo')
        ORDER BY name
    """)
    
    vistas = [row[0] for row in cursor.fetchall()]
    print(f"\n   Total vistas: {len(vistas)}")
    for vista in vistas:
        print(f"   - {vista}")
    
    print("\n" + "=" * 60)
    print("[OK] Estructura actualizada exitosamente")
    print("=" * 60)
    
except Exception as e:
    print(f"\n[ERROR] {e}")
    conn.rollback()
    
finally:
    cursor.close()
    conn.close()
