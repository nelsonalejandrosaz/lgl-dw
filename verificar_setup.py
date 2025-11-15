"""
Script de Verificación del Entorno
Valida que todo esté configurado correctamente
"""
import sys
from pathlib import Path

def verificar_entorno():
    print("\n" + "="*60)
    print("VERIFICACIÓN DEL ENTORNO - LGL DATA WAREHOUSE")
    print("="*60)
    
    errores = []
    advertencias = []
    
    # 1. Python
    print("\n1. Python")
    version = sys.version_info
    if version.major >= 3 and version.minor >= 10:
        print(f"   ✓ Python {version.major}.{version.minor}.{version.micro}")
    else:
        errores.append(f"Python {version.major}.{version.minor} es muy antiguo. Se requiere 3.10+")
        print(f"   ✗ Python {version.major}.{version.minor}.{version.micro}")
    
    # 2. Virtual Environment
    print("\n2. Virtual Environment")
    if hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix):
        print("   ✓ Virtual environment activo")
    else:
        advertencias.append("No estás en un virtual environment. Recomendado: source venv/Scripts/activate")
        print("   ! No se detectó venv activo")
    
    # 3. Dependencias
    print("\n3. Dependencias Python")
    paquetes = {
        'pymysql': '1.1.0',
        'pyodbc': '5.0.1',
        'pandas': '2.1.3',
        'loguru': '0.7.2',
        'pyyaml': '6.0.1'
    }
    
    for paquete, version_requerida in paquetes.items():
        try:
            modulo = __import__(paquete)
            version_instalada = getattr(modulo, '__version__', 'unknown')
            print(f"   ✓ {paquete} {version_instalada}")
        except ImportError:
            errores.append(f"Falta {paquete}. Ejecuta: pip install -r requirements.txt")
            print(f"   ✗ {paquete} NO INSTALADO")
    
    # 4. Archivos de configuración
    print("\n4. Archivos de Configuración")
    config_path = Path('etl/config/config.yaml')
    if config_path.exists():
        print(f"   ✓ {config_path}")
    else:
        errores.append("Falta etl/config/config.yaml. Copia config.yaml.example y configúralo")
        print(f"   ✗ {config_path} NO ENCONTRADO")
    
    # 5. Estructura de directorios
    print("\n5. Estructura de Directorios")
    directorios = [
        'etl/load',
        'etl/utils',
        'database/target',
        'logs',
        'docs'
    ]
    
    for directorio in directorios:
        dir_path = Path(directorio)
        if dir_path.exists():
            print(f"   ✓ {directorio}/")
        else:
            advertencias.append(f"Falta directorio: {directorio}")
            print(f"   ! {directorio}/ NO ENCONTRADO")
    
    # 6. Scripts ETL
    print("\n6. Scripts ETL")
    scripts = [
        'etl/load/load_dim_tiempo.py',
        'etl/load/load_dim_static.py',
        'etl/load/load_dim_cliente.py',
        'etl/load/load_dim_producto.py',
        'etl/load/load_dim_vendedor.py',
        'etl/load/load_fact_ventas.py'
    ]
    
    for script in scripts:
        script_path = Path(script)
        if script_path.exists():
            print(f"   ✓ {script}")
        else:
            errores.append(f"Falta script: {script}")
            print(f"   ✗ {script} NO ENCONTRADO")
    
    # 7. Conexión a Bases de Datos
    print("\n7. Conexión a Bases de Datos")
    
    try:
        from etl.utils.database import SourceDatabase, TargetDatabase
        
        # MariaDB
        try:
            source_db = SourceDatabase()
            if source_db.test_connection():
                print("   ✓ MariaDB (lgldb)")
            else:
                errores.append("No se puede conectar a MariaDB")
                print("   ✗ MariaDB - Error de conexión")
        except Exception as e:
            errores.append(f"Error MariaDB: {str(e)[:50]}")
            print(f"   ✗ MariaDB - {str(e)[:50]}...")
        
        # SQL Server
        try:
            target_db = TargetDatabase()
            if target_db.test_connection():
                print("   ✓ SQL Server (LGL_DW)")
            else:
                errores.append("No se puede conectar a SQL Server")
                print("   ✗ SQL Server - Error de conexión")
        except Exception as e:
            errores.append(f"Error SQL Server: {str(e)[:50]}")
            print(f"   ✗ SQL Server - {str(e)[:50]}...")
            
    except ImportError as e:
        errores.append("No se pueden importar módulos de conexión")
        print(f"   ✗ Error importando módulos: {e}")
    
    # Resumen
    print("\n" + "="*60)
    print("RESUMEN")
    print("="*60)
    
    if not errores and not advertencias:
        print("\n✓ TODO CORRECTO - El entorno está listo para usar")
        return True
    
    if advertencias:
        print(f"\n! {len(advertencias)} ADVERTENCIA(S):")
        for i, adv in enumerate(advertencias, 1):
            print(f"  {i}. {adv}")
    
    if errores:
        print(f"\n✗ {len(errores)} ERROR(ES) ENCONTRADO(S):")
        for i, error in enumerate(errores, 1):
            print(f"  {i}. {error}")
        print("\nRevisá la documentación: docs/guia_setup_colaboradores.md")
        return False
    
    return True


if __name__ == "__main__":
    exito = verificar_entorno()
    sys.exit(0 if exito else 1)
