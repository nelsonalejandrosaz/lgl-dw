#!/usr/bin/env python3
"""
Ver columnas de dim_ubicacion
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

cursor.execute("""
    SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'dim_ubicacion'
    ORDER BY ORDINAL_POSITION
""")

print("Columnas en dim_ubicacion:")
print("=" * 80)
for row in cursor.fetchall():
    nullable = "NULL" if row[3] == "YES" else "NOT NULL"
    if row[2]:
        print(f"  {row[0]:25} {row[1]}({row[2]}) {nullable}")
    else:
        print(f"  {row[0]:25} {row[1]} {nullable}")

cursor.close()
conn.close()
