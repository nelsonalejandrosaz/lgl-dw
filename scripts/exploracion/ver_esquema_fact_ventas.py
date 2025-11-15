#!/usr/bin/env python3
"""
Ver esquema de fact_ventas y tablas fuente
"""
import pyodbc

# SQL Server - fact_ventas
conn_str_target = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=LGL_DW;"
    "UID=etl_dw_user;"
    "PWD=ETL_DW_P@ssw0rd2024!;"
    "TrustServerCertificate=yes"
)

print("=" * 100)
print("ESQUEMA DE fact_ventas EN SQL SERVER")
print("=" * 100)

conn = pyodbc.connect(conn_str_target)
cursor = conn.cursor()

cursor.execute("""
    SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'fact_ventas'
    ORDER BY ORDINAL_POSITION
""")

for row in cursor.fetchall():
    nullable = "NULL" if row[3] == "YES" else "NOT NULL"
    if row[2]:
        print(f"  {row[0]:35} {row[1]}({row[2]}) {nullable}")
    else:
        print(f"  {row[0]:35} {row[1]} {nullable}")

cursor.close()
conn.close()

print("\n" + "=" * 100)
print("ESTRUCTURA DE TABLAS FUENTE EN MARIADB")
print("=" * 100)

import pymysql

conn_str_source = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'f30071109',
    'database': 'lgldb',
    'cursorclass': pymysql.cursors.DictCursor
}

conn = pymysql.connect(**conn_str_source)
cursor = conn.cursor()

# Tabla ventas
print("\nTabla: ventas")
print("-" * 100)
cursor.execute("DESCRIBE ventas")
for row in cursor.fetchall():
    print(f"  {row['Field']:30} {row['Type']:25} {row['Null']:5} {row['Key']:5} {row['Default'] or ''}")

# Tabla orden_pedidos
print("\nTabla: orden_pedidos")
print("-" * 100)
cursor.execute("DESCRIBE orden_pedidos")
for row in cursor.fetchall():
    print(f"  {row['Field']:30} {row['Type']:25} {row['Null']:5} {row['Key']:5} {row['Default'] or ''}")

# Tabla salidas (detalle)
print("\nTabla: salidas")
print("-" * 100)
cursor.execute("DESCRIBE salidas")
for row in cursor.fetchall():
    print(f"  {row['Field']:30} {row['Type']:25} {row['Null']:5} {row['Key']:5} {row['Default'] or ''}")

cursor.close()
conn.close()
