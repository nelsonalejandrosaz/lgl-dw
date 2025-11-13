"""
Ver registros en fact_ventas
"""
import pyodbc

conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost;'
    'DATABASE=LGL_DW;'
    'UID=etl_dw_user;'
    'PWD=ETL_DW_P@ssw0rd2024!;'
    'TrustServerCertificate=yes;'
)

cursor = conn.cursor()

# Total registros
cursor.execute('SELECT COUNT(*) FROM dbo.fact_ventas')
total = cursor.fetchone()[0]
print(f'\nTotal registros en fact_ventas: {total:,}')

if total > 0:
    # Estadísticas
    cursor.execute("""
        SELECT 
            COUNT(*) as total_registros,
            COUNT(DISTINCT venta_id) as total_ventas,
            COUNT(DISTINCT cliente_key) as total_clientes,
            COUNT(DISTINCT producto_key) as total_productos,
            MIN(fecha_venta) as fecha_min,
            MAX(fecha_venta) as fecha_max,
            SUM(venta_total_con_impuestos) as venta_total
        FROM dbo.fact_ventas
    """)
    row = cursor.fetchone()
    
    print(f'\nEstadísticas:')
    print(f'  - Lineas de venta: {row[0]:,}')
    print(f'  - Ventas únicas: {row[1]:,}')
    print(f'  - Clientes: {row[2]:,}')
    print(f'  - Productos: {row[3]:,}')
    print(f'  - Período: {row[4]} a {row[5]}')
    print(f'  - Venta total: ${row[6]:,.2f}')
    
    # Primeras 3 líneas
    print(f'\nPrimeras 3 líneas:')
    cursor.execute("""
        SELECT TOP 3
            venta_id, numero_venta, fecha_venta,
            cantidad, precio_unitario, venta_total_con_impuestos
        FROM dbo.fact_ventas
        ORDER BY fecha_venta, venta_id
    """)
    for row in cursor.fetchall():
        print(f'  Venta {row[0]} ({row[1]}): {row[2]} - Cant: {row[3]} x ${row[4]:,.2f} = ${row[5]:,.2f}')

cursor.close()
conn.close()
