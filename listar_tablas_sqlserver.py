#!/usr/bin/env python3
"""
Listar todas las tablas en SQL Server LGL_DW
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
    SELECT TABLE_NAME 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA='dbo' AND TABLE_TYPE='BASE TABLE'
    ORDER BY TABLE_NAME
""")

print("Tablas en LGL_DW:")
print("=" * 50)
for row in cursor.fetchall():
    print(f"  - {row[0]}")

cursor.close()
conn.close()
