"""Script de prueba para conexión SQL Server"""
import os
from dotenv import load_dotenv
import pyodbc

load_dotenv()

print("=" * 60)
print("PRUEBA DE CONEXIÓN A SQL SERVER")
print("=" * 60)

# Leer variables
host = os.getenv('TARGET_DB_HOST', 'localhost')
port = os.getenv('TARGET_DB_PORT', '1433')
database = os.getenv('TARGET_DB_NAME', 'LGL_DW')
user = os.getenv('TARGET_DB_USER', '')
password = os.getenv('TARGET_DB_PASSWORD', '')

print(f"\nConfiguracion:")
print(f"  Host: {host}")
print(f"  Port: {port}")
print(f"  Database: {database}")
print(f"  User: {user}")
print(f"  Password: {'***' if password else '(vacío)'}")

# Drivers disponibles
print(f"\nDrivers ODBC disponibles:")
for driver in pyodbc.drivers():
    print(f"  - {driver}")

# Intentar conexión
print(f"\n{'='*60}")
print("INTENTANDO CONEXIÓN...")
print(f"{'='*60}\n")

try:
    # Construir connection string
    if user and password:
        connection_string = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={host},{port};"
            f"DATABASE={database};"
            f"UID={user};"
            f"PWD={password};"
            f"TrustServerCertificate=yes;"
        )
        print("Usando autenticación SQL Server")
    else:
        connection_string = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={host},{port};"
            f"DATABASE={database};"
            f"Trusted_Connection=yes;"
        )
        print("Usando autenticación Windows")
    
    print(f"\nConnection String (sin password):")
    print(connection_string.replace(password, "***") if password else connection_string)
    
    print("\nConectando...")
    conn = pyodbc.connect(connection_string, timeout=10)
    
    print("✓ Conexión exitosa!")
    
    # Probar query
    cursor = conn.cursor()
    cursor.execute("SELECT @@VERSION")
    version = cursor.fetchone()[0]
    
    print(f"\nVersión SQL Server:")
    print(version[:100] + "...")
    
    cursor.execute("SELECT DB_NAME()")
    db = cursor.fetchone()[0]
    print(f"\nBase de datos actual: {db}")
    
    cursor.close()
    conn.close()
    
    print("\n" + "="*60)
    print("✓ PRUEBA EXITOSA")
    print("="*60)

except pyodbc.Error as e:
    print(f"\n✗ ERROR DE CONEXIÓN:")
    print(f"  Código: {e.args[0] if e.args else 'N/A'}")
    print(f"  Mensaje: {e.args[1] if len(e.args) > 1 else str(e)}")
    
    print("\nPosibles soluciones:")
    print("  1. Verificar que SQL Server esté ejecutándose")
    print("  2. Verificar que el puerto 1433 esté abierto")
    print("  3. Verificar credenciales en .env")
    print("  4. Verificar que la base de datos LGL_DW exista")
    print("  5. Verificar que el usuario tenga permisos")
    print("  6. Si usas instancia nombrada: SERVER=localhost\\SQLEXPRESS")

except Exception as e:
    print(f"\n✗ ERROR INESPERADO:")
    print(f"  {type(e).__name__}: {str(e)}")
