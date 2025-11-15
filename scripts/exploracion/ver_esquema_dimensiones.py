#!/usr/bin/env python3
"""
Ver columnas de todas las dimensiones estáticas
"""
import pyodbc

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=LGL_DW;"
    "UID=etl_dw_user;"
    "PWD=ETL_DW_P@ssw0rd2024!;"
    "TrustServerCertificate=yes"
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

tables = ['dim_tipo_documento', 'dim_condicion_pago', 'dim_estado_venta', 'dim_ubicacion']

for table in tables:
    print(f"\n{'=' * 80}")
    print(f"Columnas en {table}:")
    print('=' * 80)
    
    cursor.execute(f"""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = '{table}'
        ORDER BY ORDINAL_POSITION
    """)
    
    for row in cursor.fetchall():
        nullable = "NULL" if row[3] == "YES" else "NOT NULL"
        if row[2]:
            print(f"  {row[0]:30} {row[1]}({row[2]}) {nullable}")
        else:
            print(f"  {row[0]:30} {row[1]} {nullable}")

cursor.close()
conn.close()
