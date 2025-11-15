"""Script de diagnóstico para SQL Server"""
import os
import socket
from dotenv import load_dotenv

load_dotenv()

print("=" * 80)
print("DIAGNÓSTICO DE CONEXIÓN SQL SERVER")
print("=" * 80)

host = os.getenv('TARGET_DB_HOST', 'localhost')
port = int(os.getenv('TARGET_DB_PORT', '1433'))

print(f"\nConfiguracion desde .env:")
print(f"  Host: {host}")
print(f"  Port: {port}")

# Test 1: Verificar si el puerto está abierto
print(f"\n{'='*80}")
print("TEST 1: Verificar si el puerto está escuchando")
print(f"{'='*80}")

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    result = sock.connect_ex((host, port))
    sock.close()
    
    if result == 0:
        print(f"✓ Puerto {port} está ABIERTO y escuchando")
    else:
        print(f"✗ Puerto {port} está CERRADO o bloqueado")
        print(f"\nPosibles causas:")
        print(f"  1. SQL Server no está ejecutándose")
        print(f"  2. SQL Server no está escuchando en el puerto {port}")
        print(f"  3. Firewall bloqueando el puerto")
        print(f"\nSoluciones:")
        print(f"  - Abrir SQL Server Configuration Manager")
        print(f"  - Ir a SQL Server Network Configuration > Protocols")
        print(f"  - Habilitar TCP/IP")
        print(f"  - Verificar que el puerto sea {port}")
        print(f"  - Reiniciar el servicio SQL Server")
except Exception as e:
    print(f"✗ Error al probar puerto: {e}")

# Test 2: Verificar instancias de SQL Server
print(f"\n{'='*80}")
print("TEST 2: Detectar instancias de SQL Server")
print(f"{'='*80}")

print("\nBuscando instancias SQL Server en la red...")
print("(Esto puede tardar unos segundos...)\n")

try:
    import subprocess
    result = subprocess.run(['sqlcmd', '-L'], capture_output=True, text=True, timeout=10)
    if result.returncode == 0:
        servers = result.stdout.strip()
        if servers:
            print("Instancias encontradas:")
            print(servers)
        else:
            print("No se encontraron instancias SQL Server")
    else:
        print("No se pudo ejecutar sqlcmd (puede que no esté instalado)")
except subprocess.TimeoutExpired:
    print("Timeout al buscar instancias")
except FileNotFoundError:
    print("sqlcmd no está instalado o no está en PATH")
except Exception as e:
    print(f"Error: {e}")

# Test 3: Sugerencias de configuración
print(f"\n{'='*80}")
print("SUGERENCIAS DE CONFIGURACIÓN")
print(f"{'='*80}")

print("""
1. Si usas SQL Server Express, el nombre suele ser:
   - localhost\\SQLEXPRESS
   - .\\SQLEXPRESS
   
2. Para SQL Server Express, actualiza tu .env:
   TARGET_DB_HOST=localhost\\SQLEXPRESS
   TARGET_DB_PORT=
   
3. Verificar que SQL Server esté ejecutándose:
   - Abrir "Servicios" (services.msc)
   - Buscar "SQL Server (MSSQLSERVER)" o "SQL Server (SQLEXPRESS)"
   - Debe estar en estado "Ejecutándose"
   
4. Habilitar TCP/IP:
   - Abrir "SQL Server Configuration Manager"
   - SQL Server Network Configuration > Protocols for [INSTANCIA]
   - Hacer click derecho en TCP/IP > Enable
   - Reiniciar el servicio SQL Server
   
5. Verificar puerto dinámico (para SQL Server Express):
   - En SQL Server Configuration Manager
   - TCP/IP > Properties > IP Addresses > IPAll
   - Anotar el "TCP Dynamic Port"
   - O configurar "TCP Port" en 1433 y borrar "TCP Dynamic Port"
""")

print("=" * 80)
print("\n¿SQL Server está instalado en este equipo?")
print("¿Es una instancia nombrada (ej: SQLEXPRESS)?")
print("¿O es una instancia por defecto?")
print("\n" + "=" * 80)
