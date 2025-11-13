#!/usr/bin/env python3
"""
Otorgar permiso ALTER a etl_dw_user
"""
import pyodbc

# Usar autenticación de Windows
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=LGL_DW;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # Otorgar permiso ALTER en schema dbo
    cursor.execute("GRANT ALTER ON SCHEMA::dbo TO etl_dw_user")
    conn.commit()
    
    print("✓ Permiso ALTER otorgado exitosamente a etl_dw_user")
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"✗ ERROR: {e}")
